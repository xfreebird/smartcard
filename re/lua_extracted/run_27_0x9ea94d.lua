 sembra "strano"!

    if self._schedule_update_retry_counters then
        self._schedule_update_retry_counters = false
        self:_update_retry_counters()
    end
    
    return self.info
end

function t.mt:get_mechanisms()
    local info = self:get_info()
    return self.mechanisms
end

function t.mt:verify_pin(pin, userType, contextual_obj)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk = false
    local result
    if userType == CKU.SO then 
        ispuk = true
    end
    log.output("verify_pin()", pin, userType, ispuk, contextual_obj)
    
    self._schedule_update_retry_counters = true
    local bso = self.siae_hcard.BSO_CNS_PIN
    local padding = self.siae_hcard.PIN_PADDING
    if ispuk then
        bso = self.siae_hcard.BSO_CNS_PUK
        padding = self.siae_hcard.PUK_PADDING
    end
    if string.len(pin)> padding then
        pin = string.sub(pin, 1, padding)
    end

    pin = pin .. string.rep("\255", padding - string.len(pin))
    
    self.siae_hcard:select(self.root_path)
    result = self.siae_hcard:sm_verify(bso, pin, true)
    log.output("verify_pin(): result=", result)
    if result == 0 then
        self.cached_main_pin = pin
        self.userType = userType
        self.cached_ds_pin = nil
        return CKR.OK
    end

    
    if result == 1 then
        return CKR.PIN_INCORRECT
    elseif result == 2 then
        return CKR.PIN_LOCKED
    else
        return CKR.FUNCTION_FAILED
    end
end

function t.mt:unverify_pin()
    -- per il momento non fa niente, potrebbe essere configurata per il reset della carta, se necessario
    self.cached_main_pin = nil
    self.userType = nil
    self.cached_ds_pin = nil
end


function t.mt:change_pin(oldPin, newPin)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk
    ispuk = false
    if self.userType == CKU.SO then ispuk = true end
    local pcRes, result
    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-siae change_pin(): oldPin:' .. oldPin, 'newPin:' .. newPin)
    log.output('token-siae change_pin(): cambio pin...')
    
    self._schedule_update_retry_counters = true
    if type(newPin) == "string" and (string.len(newPin) > self.info.ulMaxPinLen or string.len(newPin) < self.info.ulMinPinLen) then
        log.output('token-siae change_pin(): invalid pin len')
        return CKR.PIN_LEN_RANGE
    end
    
    local bso = self.siae_hcard.BSO_CNS_PIN
    local padding = self.siae_hcard.PIN_PADDING
    if ispuk then
        bso = self.siae_hcard.BSO_CNS_PUK
        padding = self.siae_hcard.PUK_PADDING
    end
    if string.len(oldPin or '') > padding then
        oldPin = string.sub(oldPin, 1, padding)
    end
    if string.len(newPin) > padding then
        error('CnsSmartcard change_pin_cns Error: wrong PIN size', 2)
    end
    if oldPin then
        oldPin = oldPin .. string.rep("\255", padding - string.len(oldPin))
    end
    newPin = newPin .. string.rep("\255", padding - string.len(newPin))
    pcRes = pcall(function() return self.siae_hcard:select(self.root_path) end )
    if ispuk then
        oldPin=nil
    end
    result = self.siae_hcard:sm_change(bso, oldPin, newPin, true)

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

    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-siae reset_pin(): newPin:' .. newPin)
    log.output('token-siae reset_pin(): reset pin...')
    if self.userType ~= CKU.SO then
        log.output('token-siae reset_pin(): user not SO!')
        return CKR.FUNCTION_FAILED
    end
    
    if type(newPin) == "string" and (string.len(newPin) > self.info.ulMaxPinLen or string.len(newPin) < self.info.ulMinPinLen) then
        log.output('token-siae reset_pin(): invalid pin len')
        return CKR.PIN_LEN_RANGE
    end
    
    self._schedule_update_retry_counters = true

    
    local Puk = self.cached_main_pin
    if string.len(Puk or '' ) > self.siae_hcard.PUK_PADDING then
        Puk = string.sub(Puk, 1, self.siae_hcard.PUK_PADDING)
    end
    if string.len(newPin) > self.siae_hcard.PIN_PADDING then
        error('CnsSmartcard reset_pin_cns Error: wrong PIN size', 2)
    end
    Puk = Puk .. string.rep("\255", self.siae_hcard.PUK_PADDING - string.len(Puk))
    newPin = newPin .. string.rep("\255", self.siae_hcard.PIN_PADDING - string.len(newPin))
    
    pcRes = pcall(function() return self.siae_hcard:select(self.root_path) end )
    
    result = self.siae_hcard:sm_reset_retry_counter(self.siae_hcard.BSO_CNS_PIN, Puk, newPin, true)
    
    
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