 ripristinato al valore precedente...')
                    local pcRes1, result1 = pcall(function()
                        return self.cns_hcard:change_pin_cns(newPin, oldPin, ispuk, self.ds_info.sm_use2_enc, self.ds_info.sm_use2_sig)
                    end )
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
        -- la carta oberthur sembra dimenticare lo stato di logged in quando si effettua una change pin
        self.cached_main_pin = newPin
        if not ispuk then
            pcRes, result = pcall(function()
                    return self.cns_hcard:verify_pin_cns(newPin, ispuk, false, self.ds_info.sm_use2_enc, self.ds_info.sm_use2_sig)
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
        if ispuk and self._cns_read_only then
            log.output('token-cns change_pin(): generic error on _cns_read_only: returning TOKEN_WRITE_PROTECTED')
            return CKR.TOKEN_WRITE_PROTECTED
        end
        return CKR.FUNCTION_FAILED
    end
end

function t.mt:change_pin2(oldPin, newPin)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk = false
    if self.userType == CKU.SO then ispuk = true end
    local pcRes, result
    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-cns change_pin(): oldPin:', oldPin, 'newPin:', newPin)
    
    if ispuk and self.puk_not_modifiable then
        log.output('token-cns change_pin(): PUK not modifiable!')
        return CKR.PIN_LEN_RANGE
    end
    local rv
    
    if not ispuk and self.pinUnchangable then
        log.output('token-cns change_pin(): PIN not modifiable by policy!')
        return CKR.TOKEN_WRITE_PROTECTED
    end

    if self.ds_info ~= nil then
        local pinDs, newpinDs = oldPin, newPin
        
        log.output('token-cns change_pin(): cambio pin DS...')
        pcRes = pcall(function() return self.cns_hcard:select(hexf(self.ds_info.path_root .. self.ds_df_priv )) end )
        pcRes, result = pcall(
            function()
                return self.cns_hcard:change_pin_ds(pinDs, newpinDs,
                    self.ds_info.sm_admin_enc, self.ds_info.sm_admin_sig,
                    ispuk)
            end)
    end
    
    if result == 0 then
        return CKR.OK
    elseif result == 1 then
        return CKR.PIN_INCORRECT
    elseif result == 2 then
        return CKR.PIN_LOCKED
    else
        if ispuk and self._cns_read_only then
            log.output('token-cns change_pin(): generic error on _cns_read_only: returning TOKEN_WRITE_PROTECTED')
            return CKR.TOKEN_WRITE_PROTECTED
        end
        return CKR.FUNCTION_FAILED
    end
end

function t.mt:reset_pin(newPin)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local pcRes, result
    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-cns reset_pin(): newPin:', newPin)
    log.output('token-cns reset_pin(): reset pin CNS...') 
    
    if self.userType ~= CKU.SO and newPin ~= nil then -- PINPAD custom behavior to reset the PIN: no need to be logged as SO with PUK, PUK is asked by the PINPAD
        log.output('token-cns reset_pin(): user not SO!')
        return CKR.USER_TYPE_INVALID
    end
    
    if self.pinNotUnlockable then
        log.output('token-cns reset_pin(): PIN unlock disabled by policy!')
        return CKR.TOKEN_WRITE_PROTECTED
    end

    local rv
    
    if self._pinpad_hw and newPin == nil then
        local pin_cns_id = self.cns_hcard.BSO_CNS_PIN
        pcRes = pcall(function() return self.cns_hcard:select(hexf('3F00')) end )
        result = pcsc.pinpad_ctl(
                    PINPAD_CTL_RESET + PINPAD_CTL_PIN,
                    self.cns_hcard.card,
                    self.reader_name,
                    pin_cns_id)
        log.output("reset_pin(): pinpad_reset(CNS): result=", result)

    else
        pcall(function()
            self:init_pin_policy()
        end)
        local newPinOrig = newPin
        rv, newPin = self:check_pin_value(newPin, true, false)
        if rv ~= CKR.OK then
            return rv
        end
        
        
        self._schedule_update_retry_counters = true
        
        pcRes = pcall(function() return self.cns_hcard:select(hexf('3F00')) end )
        pcRes, result = pcall(function()
            return self.cns_hcard:reset_pin_cns(self.cached_main_pin, newPin, self.ds_info.sm_use2_enc, self.ds_info.sm_use2_sig)
            end)
    end
    
    if self.ds_info ~= nil and not self.ds_info._ignore_ds_pin and pcRes and result == 0 then
        local resetDsPin = false
        while true do
            local res, pukDs, newpinDs
            if self.cfg["dspinusegui"] == 'true' and self.request_plugin_valid then
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
                pcRes = pcall(function() return self.cns_hcard:select(hexf(self.ds_info.path_root .. self.ds_df_priv )) end )
                pcRes, result =  pcall(
                    function()
                        return self.cns_hcard:reset_pin_ds(pukDs, newpinDs, 
                            self.ds_info.sm_admin_enc, self.ds_info.sm_admin_sig, 
                            self.ds_info.sm_use_enc, self.ds_info.sm_use_sig)
                    end)
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
    
        if self.ds_info and self.ds_info.path_root and self.ds_info.flags and not self.ds_info.flags[CKF.USER_PIN_INITIALIZED] then
            log.output('token-cns reset_pin(): setting CKF.USER_PIN_INITIALIZED...')

            local pcRes, theErrorT = pcall(function()
                local path = hex.hexf(self.ds_info.path_root .. '1000')
                self.cns_hcard:select(path)
                local value = hex.hexf("%>%L", (self.ds_info.flags + CKF.USER_PIN_INITIALIZED).asnumber)
                
                log.output('token-cns reset_pin(): new HW flags value:', hex.hexify(value))
                
                self.cns_hcard:mupdate_binary(32, value)
                
                log.output('token-cns reset_pin(): updating flags with CKF.USER_PIN_INITIALIZED...')
                
                self.ds_info.flags = self.ds_info.flags + CKF.USER_PIN_INITIALIZED
                self.info.flags = self.info.flags + CKF.USER_PIN_INITIALIZED
                self.filtered_token_flags = self.filtered_token_flags + CKF.USER_PIN_INITIALIZED
                self:update_cache_id()
                self:invalidate_xproc_cache()
                
            end)
            if not pcRes then
                log.output('token-cns reset_pin(): error setting CKF.USER_PIN_INITIALIZED:', theErrorT)
                return CKR.FUNCTION_FAILED
            end

        end

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
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local pcRes, result
    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-cns reset_pin2(): Puk:', Puk)
    log.output('token-cns reset_pin2(): newPin:', newPin)
    log.output('token-cns reset_pin2(): reset pin DS...') 

    if self.pinNotUnlockable then
        log.output('token-cns reset_pin2(): PIN unlock disabled by policy!')
        return CKR.TOKEN_WRITE_PROTECTED
    end

    local rv
    if self.ds_info ~= nil then
        local pukDs, newpinDs = Puk, newPin
        
        log.output('token-cns reset_pin2(): reset DS pin...')
        pcRes = pcall(function() return self.cns_hcard:select(hexf(self.ds_info.path_root .. self.ds_df_priv )) end )
        pcRes, result =  pcall(
            function()
                return self.cns_hcard:reset_pin_ds(pukDs, newpinDs, 
                    self.ds_info.sm_admin_enc, self.ds_info.sm_admin_sig, 
                    self.ds_info.sm_use_enc, self.ds_info.sm_use_sig)
            end)
            
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

--=====================================================================================
-- Funzioni per il recupero degli attributi
--=====================================================================================
-- Nella funzione seguente il parametro "onlysize" viene trascurato.
-- Il motivo 