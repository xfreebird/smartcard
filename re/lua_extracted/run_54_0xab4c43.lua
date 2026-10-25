 sembra "strano"!
    if not self.ds_info or self.ds_info.pin_initialized then
        self.info.flags = self.info.flags + CKF.USER_PIN_INITIALIZED
    else
        self.info.flags = self.info.flags - CKF.USER_PIN_INITIALIZED
    end
    
    if self._schedule_update_retry_counters then
        self._schedule_update_retry_counters = false
        self:_update_retry_counters()
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

function t.mt:verify_pin_dsmode(pin, userType, contextual_obj)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk = false
    local result
    local sm_enc, sm_sig
    local sm_enc_verif, sm_sig_verif

    if self.ds_info and self.ds_info.use_sm then
        sm_enc, sm_sig = self.ds_info.sm_enc, self.ds_info.sm_sig
        sm_enc_verif, sm_sig_verif = sm_enc, sm_sig
    end
    
    if userType == CKU.SO then 
        ispuk = true
    end
    
    log.output("verify_pin()", pin, userType, ispuk, contextual_obj)
    if not self.ds_info then return CKR.USER_TYPE_INVALID end
    result = self.cns_hcard:select(hex.hexf(self.ds_info.ds_sig_path))
    
    if pin == nil then
        local pin_id = ispuk and self.cns_hcard.BSO_DS_PUK or self.cns_hcard.BSO_DS_PIN
        local ctl_id = ispuk and PINPAD_CTL_DSPUK or PINPAD_CTL_DSPIN
        result = pcsc.pinpad_ctl(
                PINPAD_CTL_VERIFY + ctl_id, 
                self.cns_hcard.card,
                self.reader_name,
                128 + pin_id)
        log.output("pinpad_verify(DS): result=", result)
    else
        if self.ds_info.pin_pad_no_sm_on_pin then
            sm_enc_verif, sm_sig_verifg = nil, nil
        end
        result = self.cns_hcard:verify_pin_ds(pin, sm_enc_verif, sm_sig_verif, ispuk)
        log.output("verify_pin_ds(): result=", result)
    end
    
    if self.ds_info.pin_pad_no_sm_on_pin then
        pcall( function()
            local result1 = self.cns_hcard:sm_verify(tonumber("1D", 16), "87654321", true, sm_enc, sm_sig)
            log.output("verify pin2 ds: result1=", result1)
        end)
    end
    if result == 0 then
        if userType ~= CKU.CONTEXT_SPECIFIC then
            self.userType = userType
        end
        self.contextual_pin_verified = true
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

function t.mt:verify_pin(pin, userType, contextual_obj)
    if self.dsmode == "dsonly" then
        return self:verify_pin_dsmode(pin, userType, contextual_obj)
    end
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk = false
    local result
    local sm_enc, sm_sig
    local sm_enc_verif, sm_sig_verif

    if self.ds_info and self.ds_info.use_sm then
        sm_enc, sm_sig = self.ds_info.sm_enc, self.ds_info.sm_sig
        sm_enc_verif, sm_sig_verif = sm_enc, sm_sig
    end
    
    if userType == CKU.SO then 
        ispuk = true
    end
    log.output("verify_pin()", pin, userType, ispuk, contextual_obj)
    
    self._schedule_update_retry_counters = true
    
    if userType == CKU.CONTEXT_SPECIFIC then
        if not self.ds_info then return CKR.USER_TYPE_INVALID end
        result = self.cns_hcard:select(hex.hexf(self.ds_info.ds_sig_path))
        
        if pin == nil then
            result = pcsc.pinpad_ctl(
                    PINPAD_CTL_VERIFY + PINPAD_CTL_DSPIN, 
                    self.cns_hcard.card,
                    self.reader_name,
                    128 + self.cns_hcard.BSO_DS_PIN)
            log.output("pinpad_verify(DS): result=", result)
        else
            if self.ds_info.pin_pad_no_sm_on_pin then
                sm_enc_verif, sm_sig_verifg = nil, nil
            end
            result = self.cns_hcard:verify_pin_ds(pin, sm_enc_verif, sm_sig_verif)
            log.output("verify_pin_ds(): result=", result)
        end
        
        if self.ds_info.pin_pad_no_sm_on_pin then
            pcall( function()
                local result1 = self.cns_hcard:sm_verify(tonumber("1D", 16), "87654321", true, sm_enc, sm_sig)
                log.output("verify pin2 ds: result1=", result1)
            end)
        end
        if result == 0 then
            self.contextual_pin_verified = true
            return CKR.OK
        end
    else
        if pin == nil then
            local pin_id = ispuk and self.cns_hcard.BSO_CNS_PUK or self.cns_hcard.BSO_CNS_PIN
            local pin_op = ispuk and PINPAD_CTL_PUK or PINPAD_CTL_PIN
            result = pcsc.pinpad_ctl(
                PINPAD_CTL_VERIFY + pin_op,
                self.cns_hcard.card,
                self.reader_name,
                pin_id)
            log.output("pinpad_verify(CNS): result=", result)
        else
            result = self.cns_hcard:verify_pin_cns(pin, ispuk)
            log.output("verify_pin(): result=", result)
        end
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
    log.output('token-cns change_pin(): oldPin:', oldPin, 'newPin:', newPin)
    log.output('token-cns change_pin(): cambio pin CNS...')
    
    self._schedule_update_retry_counters = true
    if type(newPin) == "string" and (string.len(newPin) > self.info.ulMaxPinLen or string.len(newPin) < self.info.ulMinPinLen) then
        log.output('token-cns change_pin(): invalid pin len')
        return CKR.PIN_LEN_RANGE
    end
    
    local pinpadPUK = "***pinpadPUK"
    pcRes = pcall(function() return self.cns_hcard:select(hexf('3F00')) end )
    if oldPin == nil or oldPin == pinpadPUK then  -- custom behavior to change the PUK
    
        ispuk = oldPin == pinpadPUK or ispuk
        local pin_cns_id = ispuk and self.cns_hcard.BSO_CNS_PUK or self.cns_hcard.BSO_CNS_PIN
        local pin_ds_id = ispuk and self.cns_hcard.BSO_DS_PUK or self.cns_hcard.BSO_DS_PIN
        
        local pin_cns_op = ispuk and PINPAD_CTL_PUK or PINPAD_CTL_PIN
        local pin_ds_op = ispuk and PINPAD_CTL_DSPUK or PINPAD_CTL_DSPIN
        
        if self.dsmode ~= "dsonly" then
            result = pcsc.pinpad_ctl(
                        PINPAD_CTL_CHANGE + pin_cns_op,
                        self.cns_hcard.card,
                        self.reader_name,
                        pin_cns_id)
            log.output("pinpad_change(CNS): result=", result)
        else
            result = 0
        end
        
        if self.dsmode ~= "authonly" then
            if result == 0 then
                pcRes = pcall(function() return self.cns_hcard:select(hexf(self.ds_info.ds_sig_path)) end )
                result = pcsc.pinpad_ctl(
                        PINPAD_CTL_CHANGE + pin_ds_op,
                        self.cns_hcard.card,
                        self.reader_name,
                        128 + pin_ds_id)
                log.output("pinpad_change(DS): result=", result)
            end
        end
    else
        if self.dsmode ~= "dsonly" then
            pcRes, result = pcall(function() return self.cns_hcard:change_pin_cns(oldPin, newPin, ispuk) end)
        else
            pcRes, result = true, 0
        end
        
        local changeDsPin = false

        if self.dsmode ~= "authonly" and self.ds_info ~= nil and pcRes and result == 0 then
            while true do -- simulazione del goto...
                local res, pinDs, newpinDs
                if self.request_plugin_valid and self.cfg["dspinusegui"] == 'true' then
                    log.output('token-cns change_pin(): requesting DS pin using GUI...')
                    res, pinDs, newpinDs = self:gui_change_pin_ds(ispuk)
                    log.output('token-cns change_pin(): self:gui_change_pin_ds DS request result:', res, pinDs, newpinDs)
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
                    if self.ds_info.pin_pad_no_sm_on_pin then
                        sm_enc, sm_sig = nil, nil
                    end
                    log.output('token-cns change_pin(): cambio pin DS...')
                    pcRes = pcall(function() return self.cns_hcard:select(hexf(self.ds_info.ds_sig_path)) end )
                    if self.ds_info.changepin_explicit_test then
                        log.output('token-cns change_pin(): changepin_explicit_test...')
                        result = self.cns_hcard:verify_pin_ds(pinDs, sm_enc, sm_sig, ispuk)
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