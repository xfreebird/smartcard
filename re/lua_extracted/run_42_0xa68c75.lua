 ripristinato al valore precedente...')
                    local pcRes1, result1 = pcall(function() return self.cns_hcard:change_pin_cns(newPin, oldPin) end )
                    log.output('token-cns change_pin(): Risultato rispristino pin CNS:', result1)
                    if self.cfg["dspinusegui"] == 'false'
                        or self.cfg["dspinusegui"] == 'sign'
                        or self:gui_show_pin_message(result, ispuk) ~= 1 then
                        break
                    end
                else
                    break
                end
            end
            break
        end -- while true
    end
    if result == 0 then
        self.cached_main_pin = newPin
        
        if not ispuk then
            pcRes, result = pcall(function()    
                    return self.cns_hcard:verify_pin_cns(newPin, ispuk, false)
                end)
            pcall(function()   
                self:update_pin_history(oldPinOrig, newPinOrig)
            end)
        end
        return CKR.OK
    elseif result == 1 then
        return CKR.PIN_INCORRECT
    elseif result == 2 then
        return CKR.PIN_LOCKED
    else
        if ispuk and self.cns_only then
            log.output('token-cns change_pin(): generic error on CNS ONLY: returning TOKEN_WRITE_PROTECTED')
            return CKR.TOKEN_WRITE_PROTECTED
        end
        return CKR.FUNCTION_FAILED
    end
end


function t.mt:reset_pin(newPin)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local pcRes, result
    local sm_enc, sm_sig = nil, nil
    local info = self:get_info() -- carica le info sul filesystem in cache
    if self.ds_info ~= nil and self.ds_info.use_sm then
        sm_enc = self.ds_info.sm_enc
        sm_sig = self.ds_info.sm_sig
    end
    log.output('token-cns reset_pin(): newPin:', newPin)
    log.output('token-cns reset_pin(): reset pin CNS...')
    if self.userType ~= CKU.SO then
        log.output('token-cns reset_pin(): user not SO!')
        return CKR.FUNCTION_FAILED
    end
    
    pcall(function()
        self:init_pin_policy()
    end)
    
    if self.pinNotUnlockable then
        log.output('token-cns reset_pin(): PIN unlock disabled by policy!')
        return CKR.TOKEN_WRITE_PROTECTED
    end
    
    self._schedule_update_retry_counters = true
    if type(newPin) == "string" and (string.len(newPin) > self.info.ulMaxPinLen or string.len(newPin) < self.info.ulMinPinLen) then
        log.output('token-cns reset_pin(): invalid pin len')
        return CKR.PIN_LEN_RANGE
    end
    
    self._schedule_update_retry_counters = true
    
    pcRes = pcall(function() return self.cns_hcard:select(hexf('3F00')) end )
    pcRes, result = pcall(function() return self.cns_hcard:reset_pin_cns(self.cached_main_pin, newPin) end)
    local resetDsPin = false
    if self.ds_info ~= nil and pcRes and result == 0 then
        while true do
            local res, pukDs, newpinDs
            if self.request_plugin_valid and self.cfg["dspinusegui"] == 'true' then
                log.output('token-cns reset_pin(): requesting DS pin/puk using GUI...')
                res, pukDs, newpinDs = self:gui_unlock_pin_ds()
                log.output('token-cns reset_pin() self:gui_unlock_pin_ds():', res, pukDs, newpinDs)
                if res ~= 1 then
                    log.output('reset_pin(): cancelled by plugin with code:', res)
                    return CKR.FUNCTION_FAILED
                else
                    resetDsPin = true
                end
            elseif self.cfg["dspiniscnspin"] == 'true' or self.cfg["dspinusegui"] == 'sign' then
                log.output('token-cns reset_pin(): main PUK is DS PUK...')
                resetDsPin = true
                pukDs, newpinDs = self.cached_main_pin, newPin
            end
            if resetDsPin then
                log.output('token-cns reset_pin(): reset DS pin...')
                if not self.ds_info.pin_initialized then
                    local ReactivateRadSigPIN = hexf('0044000002001a')
                    log.output('token-cns reset_pin(): reactivating DS PIN...')
                    pcRes = pcall(function() return self.cns_hcard:select(hexf(self.ds_info.path_root )) end )
                    pcRes, result =  pcall(
                            function() return self.cns_hcard:verify_pin_ds(pukDs, sm_enc, sm_sig, true) end
                            )
                    if result ~= 0 then
                        log.output('token-cns reset_pin(): verify PUK error:', result)
                        break
                    end
                    pcRes = pcall(function() return self.cns_hcard:select(hexf(self.ds_info.path_root )) end )
                    recv = self.cns_hcard:transmit(ReactivateRadSigPIN)
                    if recv ~= hexf('9000') then
                        log.output('token-cns reset_pin(): ReactivateRadSigPIN error')
                        return CKR.DEVICE_ERROR
                    end
                    self.ds_info.pin_initialized = true
                    self:invalidate_xproc_cache()
                end

                pcRes = pcall(function() return self.cns_hcard:select(hexf(self.ds_info.ds_sig_path )) end )
                pcRes, result =  pcall(
                        function() return self.cns_hcard:reset_pin_ds(pukDs, newpinDs, sm_enc, sm_sig) end
                        )
                if result ~= 0 then
                    log.output('token-cns reset_pin(): errore ',
                                result, ' resettando il pin DS!')
                    if self.cfg["dspinusegui"] == 'false'
                        or self.cfg["dspinusegui"] == 'sign'
                        or self:gui_show_pin_message(result, true) ~= 1 then
                        break
                    end
                else
                    break
                end
            end
            break
        end -- while true
    end
    if result == 0 then
        return CKR.OK
    elseif result == 1 then
        return CKR.PIN_INCORRECT
    elseif result == 2 then
        return CKR.PIN_LOCKED
    else
        return CKR.FUNCTION_FAILED
    end
end


function t.mt:reset_pin2(Puk, newPin)
    log.output('token-cns reset_pin2(): Puk:', Puk)
    log.output('token-cns reset_pin2(): newPin:', newPin)

    -- result == 0 (ok), 1 (failed), 2(blocked)
    local pcRes, result
    local sm_enc, sm_sig = nil, nil
    local info = self:get_info() -- carica le info sul filesystem in cache
    if self.ds_info ~= nil and self.ds_info.use_sm then
        sm_enc = self.ds_info.sm_enc
        sm_sig = self.ds_info.sm_sig
    end

    pcall(function()
        self:init_pin_policy()
    end)
    
    if self.pinNotUnlockable then
        log.output('token-cns reset_pin(): PIN unlock disabled by policy!')
        return CKR.TOKEN_WRITE_PROTECTED
    end
    
    self._schedule_update_retry_counters = true
    if type(newPin) == "string" and (string.len(newPin) > self.info.ulMaxPinLen or string.len(newPin) < self.info.ulMinPinLen) then
        log.output('token-cns reset_pin(): invalid pin len')
        return CKR.PIN_LEN_RANGE
    end
    

    if self.ds_info ~= nil then
        local pukDs, newpinDs = Puk, newPin
        log.output('token-cns reset_pin2(): reset DS pin...')

        pcRes = pcall(function() return self.cns_hcard:select(hexf(self.ds_info.ds_sig_path )) end )
        pcRes, result =  pcall(
                function() return self.cns_hcard:reset_pin_ds(pukDs, newpinDs, sm_enc, sm_sig) end
                )
                
        if not pcRes then
            log.output('token-cns reset_pin2 error:', result)
        end
    end
    if result == 0 then
        return CKR.OK
    elseif result == 1 then
        return CKR.PIN_INCORRECT
    elseif result == 2 then
        return CKR.PIN_LOCKED
    else
        return CKR.FUNCTION_FAILED
    end
end

local function extract_x509_certificate(data)

    log.output('extract_x509_certificate():')

    local der_size = string.sub(data, 1, 4)
    if string.sub(der_size, 1, 2) == hexf('5a82') or string.sub(der_size, 1, 2) == hexf('7a82')  then  -- z|Z\x82 + sizeBE + compressed data
        local size = string.byte(der_size, 3) * 256 + string.byte(der_size, 4)
        log.output('extract_x509_certificate(): PT: using CPR mode: expected size:', size)
        local compr = string.sub(data,5, 4+size)
        local decompr
        if string.sub(der_size, 1, 2) == hexf('7a82') then
            decompr = zlib.decompress2(compr, true, nil, nil)
        else
            decompr = zlib.decompress(compr, true, nil, nil)
        end
        log.output('extract_x509_certificate(): PT: cpr ratio:', 
                (4+string.len(compr))/string.len(decompr or "0"))
        return decompr
    else
        if string.sub(der_size, 1, 2) ~= hexf('3082') then
            error('extract_x509_certificate Error: bad certificate', 2)
        end
        local size = string.byte(der_size, 3) * 256 + string.byte(der_size, 4)
        return der_size .. string.sub(data,5, 4+size)  
    end

end

--=====================================================================================
-- Funzioni per il recupero degli attributi
--=====================================================================================
-- Nella funzione seguente il parametro viene "onlysize" trascurato.
-- Il motivo 