 effettuata resettare il PIN ?!?
            pcRes = pcall(function() return self.cns_hcard:select(hexf(self.ds_info.path_root )) end )
            result = pcsc.pinpad_ctl(
                    PINPAD_CTL_RESET + PINPAD_CTL_DSPIN,
                    self.cns_hcard.card,
                    self.reader_name,
                    128 + pin_ds_id)
            log.output("pinpad_reset(DS): result=", result)
        end
        
    else
        
        if self.userType ~= CKU.SO then
            log.output('token-cns reset_pin(): user not SO!')
            return CKR.FUNCTION_FAILED
        end
        if self.dsmode ~= "dsonly" then
            pcRes, result = pcall(function() return self.cns_hcard:reset_pin_cns(self.cached_main_pin, newPin) end)
        else
            pcRes, result = true, 0
        end
        
        local resetDsPin = false
        if self.dsmode ~= "authonly" and self.ds_info ~= nil and pcRes and result == 0 then
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
                        end
                        self.ds_info.pin_initialized = true
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
-- Nella funzione seguente il parametro viene "onlysize" trascurato.
-- Il motivo 