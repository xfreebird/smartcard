 dunque superflua
                    -- ma viene volutamente lasciata.
                    ---------------------------------------
                    
                    local ReactivateDSArea = hexf('00440000')
                    log.output('token-cns reset_pin(): reactivating DS AREA...')
                    pcRes = pcall(function() return self.cns_hcard:select(hexf(self.ds_info.path_root )) end )
                    pcRes, result =  pcall(
                            function() return self.cns_hcard:verify_pin_ds(pukDs, sm_enc, sm_sig, true) end
                            )
                    if result ~= 0 then
                        log.output('token-cns reset_pin(): verify PUK error:', result)
                        break
                    end
                    pcRes = pcall(function() return self.cns_hcard:select(hexf(self.ds_info.ds_sig_path )) end )
                    recv = self.cns_hcard:transmit(ReactivateDSArea)
                    if recv ~= hexf('9000') then
                        log.output('token-cns reset_pin(): ReactivateDSArea error')
                        return CKR.DEVICE_ERROR
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
                        or t.show_pin_message(result, true) ~= 1 then
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

--=====================================================================================
-- Funzioni per il recupero degli attributi
--=====================================================================================
-- Nella funzione seguente il parametro viene "onlysize" trascurato.
-- Il motivo 