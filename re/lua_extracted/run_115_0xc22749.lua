 ripristinato al valore precedente...')
                    -- local pcRes1, result1 = pcall(function() return self.cmd_hcard:change_pin_cns(newPin, oldPin) end )
                    -- log.output('token-cmd change_pin(): Risultato rispristino pin CNS:', result1)
                    -- if self.cfg["dspinusegui"] == 'false' or t.show_pin_message(result, ispuk) ~= 1 then
                        -- break
                    -- end
                -- else
                    -- break
                -- end
            -- end
            -- break
        -- end -- while true
    -- end
    
    if result == 0 then
        if self.dsmode ~= "dsonly" then
            self.cached_main_pin = newPin
        end
        if not self.userType then
            self.userType = CKU.USER
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


function t.mt:reset_pin(newPin)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local pcRes, result
    local info = self:get_info() -- carica le info sul filesystem in cache
    
    log.output('token-cmd reset_pin(): newPin:', newPin)
    log.output('token-cmd reset_pin(): reset pin CNS...')

    pcRes = pcall(function() return self.cmd_hcard:select(hexf('3F00')) end )

    if self.userType ~= CKU.SO then
        log.output('token-cmd reset_pin(): user not SO!')
        return CKR.FUNCTION_FAILED
    end
    if self.dsmode ~= "dsonly" then
        pcRes, result = pcall(function() return self.cmd_hcard:reset_pin_cns(self.cached_main_pin, newPin) end)
    else
        pcRes, result = true, 0
    end
    
    log.output('token-cmd reset_pin(): reset pin DS soppresso...')
    
    
    -- local resetDsPin = false
    -- if self.dsmode ~= "authonly" and self.cmd_info ~= nil and pcRes and result == 0 then
        -- while true do
            -- local res, pukDs, newpinDs
            -- if self.cfg["dspinusegui"] ~= 'false' and self.request_plugin_valid then
                -- log.output('token-cmd reset_pin(): requesting DS pin/puk using GUI...')
                -- res, pukDs, newpinDs = w32.unlock_pin_ds()
                -- log.output('token-cmd reset_pin() w32.unlock_pin_ds():', res, pukDs, newpinDs)
                -- if res ~= 1 then
                    -- log.output('reset_pin(): cancelled by plugin with code:', res)
                    -- return CKR.FUNCTION_FAILED
                -- else
                    -- resetDsPin = true
                -- end
            -- elseif self.cfg["dspiniscnspin"] == 'true' then
                -- log.output('token-cmd reset_pin(): main PUK is DS PUK...')
                -- resetDsPin = true
                -- pukDs, newpinDs = self.cached_main_pin, newPin
            -- end
            -- if resetDsPin then
                -- log.output('token-cmd reset_pin(): reset DS pin...')
                
                -- pcRes = pcall(function() return self.cmd_hcard:select(hexf(self.cmd_info.ds_sig_path )) end )
                -- pcRes, result =  pcall(
                        -- function() return self.cmd_hcard:reset_pin_ds(pukDs, newpinDs, nil, nil) end
                        -- )
                -- if result ~= 0 then
                    -- log.output('token-cmd reset_pin(): errore ',
                                -- result, ' resettando il pin DS!')
                    -- if self.cfg["dspinusegui"] == 'false' or t.show_pin_message(result, true) ~= 1 then
                        -- break
                    -- end
                -- else
                    -- break
                -- end
            -- end
            -- break
        -- end -- while true
    -- end

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