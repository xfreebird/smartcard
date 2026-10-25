 collegato ad una chiave protetta da pin secondario
        [ CKA.ALWAYS_AUTHENTICATE ] = populatePubKeyFunc,
        [ CKA.DESTROYABLE ] = populatePubKeyFunc,
        dsx=true,
    }
end

function t.GetDSXECDSAPrivKeyTemplate(populatePubKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PRIVATE_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = populatePubKeyFunc,
        [ CKA.LABEL ] = populatePubKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.ECDSA),
        [ CKA.ID ] = populatePubKeyFunc,
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        [ CKA.DERIVE ] = populatePubKeyFunc,
        [ CKA.LOCAL ] = populatePubKeyFunc,
        [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.EC_KEY_PAIR_GEN),
        -- [ CKA.ALLOWED_MECHANISMS ] = '',
        -- Private Key
        [ CKA.SUBJECT ] = '',
        [ CKA.SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.DECRYPT ] = eCK.BBOOL(false),
        [ CKA.SIGN ] = populatePubKeyFunc,
        [ CKA.SIGN_RECOVER ] = eCK.BBOOL(false),
        [ CKA.UNWRAP ] = eCK.BBOOL(false),
        [ CKA.EXTRACTABLE ] = eCK.BBOOL(false),
        [ CKA.ALWAYS_SENSITIVE ] =  eCK.BBOOL(true),
        [ CKA.NEVER_EXTRACTABLE ] = eCK.BBOOL(true),
        [ CKA.WRAP_WITH_TRUSTED ] = eCK.BBOOL(false),
        -- [ CKA.UNWRAP_TEMPLATE ] = '',
        [ CKA.ALWAYS_AUTHENTICATE ] = populatePubKeyFunc,
        -- RSA Private Key
        [ CKA.EC_POINT ] = populatePubKeyFunc,
        [ CKA.EC_PARAMS ] = populatePubKeyFunc,
        [ CKA.VALUE ] = -1,
        dsx=true,
    }
end


function t.mt:check_ask_ds_pin(obj, sm_enc, sm_sig)
    log.output('check_ask_ds_pin()...')
    local contextual_pin
    local result
    if obj[CKA.ALWAYS_AUTHENTICATE] == eCK.BBOOL(true) and not self.contextual_pin_verified then
        log.output('check_ask_ds_pin(): is DS obj and no contextual_pin_verified...')
        log.output("CFG:", utility.repr(self.cfg))
        if self.request_plugin_valid
           and (self.cfg["dspinusegui"] == 'true' or self.cfg["dspinusegui"] == 'sign')
            then
            log.output('check_ask_ds_pin(): GUI mode...')
            if self.cached_ds_pin then
                log.output('check_ask_ds_pin(): GUI cache mode...')
                contextual_pin = self.cached_ds_pin
            else
                local res, cache_ds_pin
                log.output('check_ask_ds_pin(): GUI: try asking DS pin...')
                while true do
                    res, contextual_pin, cache_ds_pin = self:gui_request_pin_ds(self.check_box_visible)
                    if res ~= 1 then
                        log.output('check_ask_ds_pin(): CKR.FUNCTION_FAILED: cancelled by plugin with code:', res)
                        return CKR.FUNCTION_FAILED
                    end
                    self.cns_hcard:select(hex.hexf(obj.path))
                    result = self.cns_hcard:verify_pin_ds(contextual_pin, sm_enc, sm_sig)
                    if result == 0 and cache_ds_pin then self.cached_ds_pin = contextual_pin end
                    contextual_pin = nil
                    if self:gui_show_pin_message(result, false) ~= 1 then
                        break
                    end
                end
            end
        elseif self.cfg["dspiniscnspin"]=='true' and self.cached_main_pin then
            log.output('check_ask_ds_pin(): using main pin as contextual pin...')
            contextual_pin = self.cached_main_pin
        else
            log.output('check_ask_ds_pin(): CKR.USER_NOT_LOGGED_IN: requesting contextual login since ALWAYS_AUTHENTICATE is set...')
            return CKR.USER_NOT_LOGGED_IN
        end
    end
    log.output('check_ask_ds_pin(): OK: returning contextual_pin=', contextual_pin)
    return CKR.OK, contextual_pin
end

function t.mt:sign_buffer_dsx(hKey, pMechanism, pData, allocated_space)
    log.output('sign_buffer_dsx():', hKey)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('sign_buffer_dsx(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('sign_buffer_dsx(): ERROR: non private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
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

    if keyBytes > 128 and not self._license_valid then
        log.output('sign_buffer_dsx(): ERROR: invalid license for this key size: ', keyBytes)
        return CKR.KEY_FUNCTION_NOT_PERMITTED
    end
    
    local dataLen = string.len(pData)
    local pcRes, result
    
    if dataLen > keyBytes or (dataLen > (keyBytes -4) and dataLen <  keyBytes) then
        -- nota: il padding pkcs1 richiede almeno 8 byte di oxFF prima dei dati da firmare
        log.output('sign_buffer_dsx(): specified data len invalid: ', dataLen)
        return CKR.DATA_LEN_RANGE
    end
    if allocated_space==nil then
        return CKR.OK, keyBytes
    else
        if type(obj.kid) == 'function' then
            local rv = obj.kid(self, hKey, CKA.CLASS, false)
            if rv ~= CKR.OK then return rv end
        end
        pcall(function() 
            self:auto_verify_pin_main()
        end)
        if obj.dsx then -- usa la modalit