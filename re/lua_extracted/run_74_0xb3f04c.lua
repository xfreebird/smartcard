 sembra "strano"!
    if not self.ds_info or self.ds_info.pin_initialized then
        self.info.flags = self.info.flags + CKF.USER_PIN_INITIALIZED
    else
        self.info.flags = self.info.flags - CKF.USER_PIN_INITIALIZED
    end

    return self.info
end

function t.mt:get_mechanisms()
    local info = self:get_info()
    if self.cns_only then
        self.mechanisms[CKM.RSA_PKCS_KEY_PAIR_GEN] = nil
    end
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
    if userType == CKU.CONTEXT_SPECIFIC then
        if not self.ds_info then return CKR.USER_TYPE_INVALID end
        result = self.cns_hcard:select(hex.hexf(self.ds_info.ds_sig_path))
        result = self.cns_hcard:verify_pin_ds(pin, self.ds_info.sm_enc, self.ds_info.sm_sig)
        log.output("verify_pin_ds(): result=", result)
        if result == 0 then
            self.contextual_pin_verified = true
            return CKR.OK
        end
    else
        result = self.cns_hcard:verify_pin_cns(pin, ispuk)
        log.output("verify_pin(): result=", result)
        if result == 0 then
            self.cached_main_pin = pin
            self.userType = userType
            self.cached_ds_pin = nil
            return CKR.OK
        end
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

function t.mt:change_pin1(oldPin, newPin)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk = false
    if self.userType == CKU.SO then ispuk = true end
    local pcRes, result
    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-cns change_pin1(): oldPin:' .. oldPin, 'newPin:' .. newPin)
    pcRes = pcall(function() return self.cns_hcard:select(hexf('3F00')) end )
    pcRes, result = pcall(function() return self.cns_hcard:change_pin_cns(oldPin, newPin, ispuk) end)
    if pcRes then
        return result
    else
        return -1
    end
end


function t.mt:change_pin2(oldPin, newPin)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk = false
    if self.userType == CKU.SO then ispuk = true end
    local pcRes, result
    local sm_enc, sm_sig = nil, nil
    local info = self:get_info() -- carica le info sul filesystem in cache
    if self.ds_info ~= nil and self.ds_info.use_sm then
        sm_enc = self.ds_info.sm_enc
        sm_sig = self.ds_info.sm_sig
    end
    log.output('token-cns change_pin2(): oldPin:' .. oldPin, 'newPin:' .. newPin)

    if self.ds_info == nil then
        log.output('token-cns change_pin2(): DS app not found!')
        return 0
    end

    log.output('token-cns change_pin2(): cambio pin DS...')
    pcRes = pcall(function() return self.cns_hcard:select(hexf(self.ds_info.ds_sig_path)) end )
    if self.ds_info.changepin_explicit_test then
        result = self.cns_hcard:verify_pin_ds(oldPin, self.ds_info.sm_enc, self.ds_info.sm_sig, ispuk)
        oldPin = nil
        pcRes = true
    else
        result=0
    end
    if result==0 then
        pcRes, result =  pcall(
                function() return self.cns_hcard:change_pin_ds(pinDs, newpinDs, sm_enc, sm_sig, ispuk) end
                )
    end
    if pcRes then
        return result
    else
        return -1
    end   
end


function t.mt:change_pin(oldPin, newPin)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk
    ispuk = false
    if self.userType == CKU.SO then ispuk = true end
    local pcRes, result
    local sm_enc, sm_sig = nil, nil
    local info = self:get_info() -- carica le info sul filesystem in cache
    if self.ds_info ~= nil and self.ds_info.use_sm then
        sm_enc = self.ds_info.sm_enc
        sm_sig = self.ds_info.sm_sig
    end
    log.output('token-cns change_pin(): oldPin:' .. oldPin, 'newPin:' .. newPin)
    log.output('token-cns change_pin(): cambio pin CNS...')
    pcRes = pcall(function() return self.cns_hcard:select(hexf('3F00')) end )
    pcRes, result = pcall(function() return self.cns_hcard:change_pin_cns(oldPin, newPin, ispuk) end)
    local changeDsPin = false

    if self.ds_info ~= nil and pcRes and result == 0 then
        while true do -- simulazione del goto...
            local res, pinDs, newpinDs
            if self.cfg["dspinusegui"] == 'true' and self.request_plugin_valid then
                log.output('token-cns change_pin(): requesting DS pin using GUI...')
                res, pinDs, newpinDs = selg:gui_change_pin_ds(ispuk)
                log.output('token-cns change_pin(): DS request result:', res, pinDs, newpinDs)
                if res ~= 1 then
                    log.output('change_pin(): cancelled by plugin with code:', res)
                    return CKR.FUNCTION_FAILED
                else
                    changeDsPin = true
                end
            elseif self.cfg["dspiniscnspin"] == 'true' or self.cfg["dspinusegui"] == 'sign' then
                log.output('token-cns change_pin(): main PIN is DS PIN...')
                changeDsPin = true
                pinDs, newpinDs = oldPin, newPin
            end
            if changeDsPin then
                log.output('token-cns change_pin(): cambio pin DS...')
                pcRes = pcall(function() return self.cns_hcard:select(hexf(self.ds_info.ds_sig_path)) end )
                if self.ds_info.changepin_explicit_test then
                    log.output('token-cns change_pin(): changepin_explicit_test...')
                    result = self.cns_hcard:verify_pin_ds(pinDs, self.ds_info.sm_enc, self.ds_info.sm_sig, ispuk)
                    pinDs = nil
                    pcRes = true
                else
                    result=0
                end
                if result==0 then
                    pcRes, result =  pcall(
                            function() return self.cns_hcard:change_pin_ds(pinDs, newpinDs, sm_enc, sm_sig, ispuk) end
                            )
                end
                if result ~= 0 then
                    -- ripristina il vecchio pin principale
                    log.output('token-cns change_pin(): errore ',
                                result,
                                ' cambiando il pin DS!', 
                                'Il pin CNS verr