 effettuare la firma RAW; inoltre il padding PKCS1 richiede almeno 8 byte di 0xff prima dei dati da firmare
                log.output('sign_buffer(): specified data len invalid (SM active!): ', dataLen)
                return CKR.DATA_LEN_RANGE
            end
            if self.ds_info.use_sm and self.ds_info.sm_enc ~= nil and self.ds_info.sm_sig ~= nil then
                sm_enc = self.ds_info.sm_enc
                sm_sig = self.ds_info.sm_sig
            end
            if obj[CKA.ALWAYS_AUTHENTICATE] == eCK.BBOOL(true) and not self.contextual_pin_verified then
                log.output("CFG:", utility.repr(self.cfg))
                local info = self:get_info()
                if self.cfg["dspinusepinpad"] == 'true' and info.flags[CKF.PROTECTED_AUTHENTICATION_PATH] then
                    self.cns_hcard:select(hex.hexf(obj.path))
                    while true do
                        result = pcsc.pinpad_ctl(
                            PINPAD_CTL_VERIFY + PINPAD_CTL_DSPIN,
                            self.cns_hcard.card,
                            self.reader_name,
                            128 + self.cns_hcard.BSO_DS_PIN)
                        if self:gui_show_pin_message(result, false) ~= 1 then
                            break
                        end
                    end
                elseif self.request_plugin_valid
                   and (self.cfg["dspinusegui"] == 'true' or self.cfg["dspinusegui"] == 'sign')
                    then
                    if self.cached_ds_pin then
                        contextual_pin = self.cached_ds_pin
                    else
                        local res, cache_ds_pin
                        while true do
                            res, contextual_pin, cache_ds_pin = self:gui_request_pin_ds(self.check_box_visible)
                            if res ~= 1 then
                                log.output('sign_buffer(): cancelled by plugin with code:', res)
                                return CKR.FUNCTION_FAILED
                            end
                            local sm_enc_verif, sm_sig_verif = sm_enc, sm_sig
                            if self.ds_info.pin_pad_no_sm_on_pin then
                                sm_enc_verif, sm_sig_verif = nil, nil
                            end
                            self.cns_hcard:select(hex.hexf(obj.path))
                            result = self.cns_hcard:verify_pin_ds(contextual_pin, sm_enc_verif, sm_sig_verif)
                            if result == 0 and cache_ds_pin then self.cached_ds_pin = contextual_pin end
                            contextual_pin = nil
                            if self:gui_show_pin_message(result, false) ~= 1 then
                                break
                            end
                        end
                    end
                elseif self.cfg["dspiniscnspin"]=='true' then
                    log.output('sign_buffer(): using main pin as contextual pin...')
                    contextual_pin = self.cached_main_pin
                else
                    log.output('sign_buffer(): requesting contextual login since ALWAYS_AUTHENTICATE is set...')
                    return CKR.USER_NOT_LOGGED_IN
                end
            end

            if self.ds_info.pin_pad_no_sm_on_pin then
                pcall(function()
                self.cns_hcard:select(hexf(obj.path))
                local result1 = self.cns_hcard:sm_verify(tonumber("1D", 16), "87654321", true, sm_enc, sm_sig)
                log.output("verify pin2 ds: result1=", result1)
                end)
            end
            self.contextual_pin_verified = false
            if keyBytes > 128 then
                if self.jsign_2048 then
                    log.output("jsign_2048: using cds_extended")
                    pcRes, result = pcall(function()
                        return self.cns_hcard:cds_extended(
                            pData,
                            obj.path, obj.kid,
                            sm_enc, sm_sig,
                            contextual_pin,
                            self.ds_info.pin_pad_no_sm_on_pin) -- disable SM for PIN
                        end)
                else
                    local tmp_file = hexf('811f')
                    pcRes, result = pcall(function()
                        log.output("TS_2048: using cds_2048")
                        return self.cns_hcard:cds_2048(
                                    pData,
                                    obj.path, obj.kid,
                                   tmp_file, false,
                                   sm_enc, sm_sig,
                                   contextual_pin,
                                       false, -- no erase data to sign
                                       self.ds_info.pin_pad_no_sm_on_pin) -- disable SM for PIN
                    end)
                end
            else
                pcRes, result = pcall(function()
                            return self.cns_hcard:cds_cns(
                                pData,
                                obj.path, obj.kid,
                                sm_enc, sm_sig,
                                contextual_pin,
                                self.ds_info.pin_pad_no_sm_on_pin) -- disable SM for PIN
                            end)
            end
            local last_sw = self.cns_hcard.last_sw
            local pin_incorrect = string.sub(last_sw, 1, 1) == hexf('63')
            local pin_locked = last_sw == hexf('6983')
            if not pcRes then
                log.output('sign_buffer(): cds_cns error:', result)
                if contextual_pin and (pin_incorrect or pin_locked ) then
                    log.output('sign_buffer(): contextual PIN was incorrect or locked!')
                    self.cached_ds_pin = nil
                    self.contextual_pin_verified = false
                    if pin_incorrect then return CKR.PIN_INCORRECT
                    elseif pin_locked then return CKR.PIN_LOCKED
                    else return CKR.FUNCTION_FAILED
                    end
                end
            end
            if pcRes then
                self.contextual_pin_verified = false
                return CKR.OK, result
            elseif self.cfg["dspiniscnspin"]~='true' and
                    not self.contextual_pin_verified and
                    last_sw == hexf('6982') then
                log.output('sign_buffer(): requesting contextual login...')
                return CKR.USER_NOT_LOGGED_IN
            end
            return CKR.FUNCTION_FAILED
        end
    end
    log.output('sign_buffer(): unexpected: should never reach this part!')
    return CKR.FUNCTION_FAILED

end


function t.mt:decrypt_buffer(hKey, pMechanism, pData, allocated_space)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('decrypt_buffer(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('decrypt_buffer(): ERROR: not a private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    if not obj.pso_dec then
        log.output('decrypt_buffer(): ERROR: decrypt not supported!')
        return CKR.KEY_TYPE_INCONSISTENT -- todo: errore non adatto
    end
    if type(obj.kid) == 'function' then
        local rv = obj.kid(self, hKey, CKA.CLASS, false)
        if rv ~= CKR.OK then return rv end
    end
    
    local keyBytes
    if type(obj.key_bits) == 'function' then    
        obj.key_bits(self, hKey, CKA.CLASS)
        keyBytes = obj.key_bits/8
    elseif type(obj.key_bits) == 'number' then
        keyBytes = obj.key_bits/8
    else
        keyBytes = 128
    end
    
    local dataLen = string.len(pData)
    if dataLen ~= keyBytes then
        log.output('decrypt_buffer(): specified data len invalid: ', dataLen, ', expected:', keyBytes)
        return CKR.ENCRYPTED_DATA_LEN_RANGE
    end
    pcall(function() 
        if self.cached_main_pin and self.userType == CKU.USER then
            log.output('decrypt_buffer(): verify_pin_cns() cached pin, with:', self.cached_main_pin, self.userType)
            local res = -1
            if self.check_pin_status then
                res = self.cns_hcard:verify_pin_cns("", false, true)
            end
            if res ~= 0 then
                self.cns_hcard:verify_pin_cns(self.cached_main_pin, false, false)
            end
        end
    end)
    local pDataPadded
    
    if keyBytes > 128 then
        if self.jsign_2048 then
            pDataPadded = self.cns_hcard:rsa_extended(pData, obj.path, obj.kid)
        else
        
        local tmp_file = hexf('7f0f')
        pDataPadded = self.cns_hcard:rsa_2048(pData, obj.path, obj.kid, tmp_file, true)
        end
    else
        pDataPadded = self.cns_hcard:rsa_cns(pData, obj.path, obj.kid)
    end
    
    if pDataPadded == nil or string.len(pDataPadded) ~= keyBytes then
        log.output('decrypt_buffer(): cannot decrypt specified data')
        return CKR.ENCRYPTED_DATA_INVALID
    end
    if not pMechanism or not pMechanism.mechanism or pMechanism.mechanism == CKM.RSA_PKCS then
        if string.byte(pDataPadded, 1) ~= 0 or string.byte(pDataPadded, 2) ~= 2 then
            
            log.output('decrypt_buffer(): data decrypted, pkcs1 padding invalid, byte1:',
                        string.byte(pDataPadded, 1),
                        'byte2:', string.byte(pDataPadded, 2))
            return CKR.ENCRYPTED_DATA_INVALID
        end
        local idx = string.find(pDataPadded, '\0', 4, true)
        if idx == nil then
            log.output('decrypt_buffer(): data decrypted, pkcs1 padding invalid, cannot find payload')
            return CKR.ENCRYPTED_DATA_INVALID
        end
        local result = string.sub(pDataPadded, idx+1, -1)
        return CKR.OK, result  
    else
        return CKR.OK, pDataPadded
    end
end


-- se search_state.lastobj==nil si richiede l'handle del primo oggetto che risponda
-- al template. Altrimenti restituisce il primo oggetto che sia
-- compatibile con il template e abbia handle>search_state.lastobj.
-- quando non ci sono pi