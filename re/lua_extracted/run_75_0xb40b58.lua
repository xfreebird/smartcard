 ripristinato al valore precedente...')
                    local pcRes1, result1 = pcall(function() return self.cns_hcard:change_pin_cns(newPin, oldPin) end )
                    log.output('token-cns change_pin(): Risultato rispristino pin CNS:', result1)
                    if self.cfg["dspinusegui"] == 'false'
                        or self.cfg["dspinusegui"] == 'sign'
                        or t.show_pin_message(result, ispuk) ~= 1 then
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
        return CKR.OK
    elseif result == 1 then
        return CKR.PIN_INCORRECT
    elseif result == 2 then
        return CKR.PIN_LOCKED
    else
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
    log.output('token-cns reset_pin(): newPin:' .. newPin)
    log.output('token-cns reset_pin(): reset pin CNS...')
    if self.userType ~= CKU.SO then
        log.output('token-cns reset_pin(): user not SO!')
        return CKR.FUNCTION_FAILED
    end
    pcRes = pcall(function() return self.cns_hcard:select(hexf('3F00')) end )
    pcRes, result = pcall(function() return self.cns_hcard:reset_pin_cns(self.cached_main_pin, newPin) end)
    local resetDsPin = false
    if self.ds_info ~= nil and pcRes and result == 0 then
        while true do
            local res, pukDs, newpinDs
            if self.cfg["dspinusegui"] == 'true' and self.request_plugin_valid then
                log.output('token-cns reset_pin(): requesting DS pin/puk using GUI...')
                res, pukDs, newpinDs = selg:gui_unlock_pin_ds()
                log.output('token-cns reset_pin() selg:gui_unlock_pin_ds():', res, pukDs, newpinDs)
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
                    
                    ---------------------------------------
                    -- BUG
                    -- La Reactivate File su carta athena non funziona
                    -- se il BSO AC_REACTIVATE usa il secure messaging
                    -- per il momento la AC_REACTIVATE 