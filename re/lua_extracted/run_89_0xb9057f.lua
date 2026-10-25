 valorizzato
    -- i PIN sono considerati uguali
    if not self.cfg["dspiniscnspin"] and not self.request_plugin_valid then
        log.output('Gemalto classic token initialize(): no plugin and dspiniscnspin unset: forcing dspiniscnspin=true')
        self.cfg["dspiniscnspin"] = 'true'
    end
    
    if self.cfg["dspinusegui"] then self.cfg["dspinusegui"]=string.lower(self.cfg["dspinusegui"])
    else self.cfg["dspinusegui"]='true' end
    
    if self.cfg["dspiniscnspin"] then self.cfg["dspiniscnspin"]=string.lower(self.cfg["dspiniscnspin"])
    else self.cfg["dspiniscnspin"]='false' end
    
    if self.cfg["hidecachedspincheck"] then self.cfg["hidecachedspincheck"]=string.lower(self.cfg["hidecachedspincheck"])
    else self.cfg["hidecachedspincheck"]='false' end
    
    if self.cfg["fcpr"] then
        self.cfg["fcpr"]=string.lower(self.cfg["fcpr"])
        self.use_cpr_mode = self.cfg["fcpr"] == "true"
        -- se non specificato non si attiva mai
    end
    
    if self.cfg["xproc"] then self.cfg["xproc"]=string.lower(self.cfg["xproc"])
    else self.cfg["xproc"]='true' end
    
    log.output('Gemalto token initialize(): use_cpr_mode:', self.use_cpr_mode)
    
    self.check_box_visible = 0
    if self.cfg["hidecachedspincheck"] == 'true' then
        self.check_box_visible = nil
    end
    if self._cache_id == nil then
        self:flush_cache()
    end
end

function t.mt:begin_transaction()
    self.gemalto_hcard:begin_transaction()
end

function t.mt:end_transaction()
    self.gemalto_hcard:end_transaction()
end

function t.mt:_call_on_end_transaction()
    log.output('token-gemalto-classic:_call_on_end_transaction()...')
    self.gemalto_hcard:on_end_transaction()
end


function t.mt:finalize()
    log.output("token-gemalto-classic:finalize():", self.userType)
    utility.forget_token_changed(self, "cache")
end

function t.mt:_update_retry_counters()

    log.output("get_pin_puk_status...");
    if (self.info) then
        pcall (function()
            self.info.flags = self.info.flags - CKF.USER_PIN_LOCKED
            self.info.flags = self.info.flags - CKF.USER_PIN_FINAL_TRY
            self.info.flags = self.info.flags - CKF.USER_PIN_COUNT_LOW
            self.info.flags = self.info.flags - CKF.SO_PIN_LOCKED
            self.info.flags = self.info.flags - CKF.SO_PIN_FINAL_TRY
            self.info.flags = self.info.flags - CKF.SO_PIN_COUNT_LOW
            local pinRetry, pinRetryMax, pukRetry, pukRetryMax = self.gemalto_hcard:get_pin_puk_status()
            log.output("get_pin_puk_status, PIN cur/max", pinRetry, pinRetryMax, "PUK cur/max:", pukRetry, pukRetryMax);
            if pinRetry == 0 then
                self.info.flags = self.info.flags + CKF.USER_PIN_LOCKED
            elseif pinRetry == 1 then
                self.info.flags = self.info.flags + CKF.USER_PIN_FINAL_TRY
            elseif pinRetry < pinRetryMax then
                self.info.flags = self.info.flags + CKF.USER_PIN_COUNT_LOW
            end
            
            if pukRetry == 0 then
                self.info.flags = self.info.flags + CKF.SO_PIN_LOCKED
            elseif pukRetry == 1 then
                self.info.flags = self.info.flags + CKF.SO_PIN_FINAL_TRY 
            elseif pukRetry < pukRetryMax then
                self.info.flags = self.info.flags + CKF.SO_PIN_COUNT_LOW
            end
            
            self.info.pinRetry    = pinRetry
            self.info.pinRetryMax = pinRetryMax
            self.info.pukRetry    = pukRetry
            self.info.pukRetryMax = pukRetryMax
        end)
    end
    
end


function t.mt:add_info()
    log.output('add_info(): performing mutual authenticate...')
    self.gemalto_hcard:auto_perform_mutual_authenticate()
    self.info.serialNumber = string.upper(hex.hexify(self.gemalto_hcard:read_serial_number()))
    self:_read_token_info_indexes()
    local infos
    pcall(function()
        infos = self.gemalto_hcard:select(hex.hexf("5040"), true)
        self.info.ulTotalPublicMemory = infos.size
    end)
    pcall(function()
        infos = self.gemalto_hcard:select(hex.hexf("5050"), true)
        self.info.ulTotalPrivateMemory = infos.size
    end)
    if self.userPinInitialized then
        self.info.flags = self.info.flags + CKF.USER_PIN_INITIALIZED
    else
        self.info.flags = self.info.flags - CKF.USER_PIN_INITIALIZED
    end
    
    self:_update_retry_counters()
end

function t.mt:update_free_mem(info)

    self:_read_indexes()
    local fs = p15.parseUnusedSpace(self._indexes._unused_space_bin)
    local pub = p15.get_free_space(fs, self.files.PubValues_path)
    local priv = p15.get_free_space(fs, self.files.PrivValues_path)
    if priv then
        info.ulFreePrivateMemory = priv
    end
    if pub then
        info.ulFreePublicMemory = pub
    end
end

function t.mt:get_info()
    if not self.info then
        self.info = {
            label = 'Bit4id Gemalto Classic',
            manufacturerID = 'Gemalto',
            model = 'Gemalto Classic',
            serialNumber = '0000000000000000',
            flags = CKF.RNG + CKF.LOGIN_REQUIRED +
                    CKF.USER_PIN_INITIALIZED + CKF.TOKEN_INITIALIZED,
            ulMaxSessionCount = CK.EFFECTIVELY_INFINITE,
            ulSessionCount = 0,
            ulMaxRwSessionCount = CK.EFFECTIVELY_INFINITE,
            ulRwSessionCount = CK.UNAVAILABLE_INFORMATION,
            ulMaxPinLen = 16,
            ulMinPinLen = 5,
            ulTotalPublicMemory = 30000,
            ulFreePublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulTotalPrivateMemory = 768,
            ulFreePrivateMemory = CK.UNAVAILABLE_INFORMATION,
            hardwareVersion = { major=3, minor=0},
            firmwareVersion = { major=3, minor=0},
            utcTime = '0000000000000000'
        }
        
        self:add_info()
        self:update_free_mem(self.info)      
        if self.cfg["gdefaultlabel"] then
            self.info.label = self.cfg["gdefaultlabel"]
        end

    end
    
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
    
    self.gemalto_hcard:auto_perform_mutual_authenticate()
    self._schedule_update_retry_counters = true
    
    if userType == CKU.CONTEXT_SPECIFIC then
        result = self.gemalto_hcard:verify_pin_main(pin, false, false, true) -- pin, ispuk, check, use_sm
        log.output("verify_pin_main(): result=", result)
        if result == 0 then
            self.contextual_pin_verified = true
            return CKR.OK
        end
    else
        result = self.gemalto_hcard:verify_pin_main(pin, ispuk, false, true) -- pin, ispuk, check, use_sm
        log.output("verify_pin_main(): result=", result)
        if result == 0 then
            self.cached_main_pin = pin
            self.userType = userType
            self.cached_ds_pin = nil
            
            if self.attributes == nil then
                self.attributes = self:get_objects()
            else
                self:_add_private_objects(self.attributes)
            end
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
    local ispuk = false
    if self.userType == CKU.SO then ispuk = true end
    local pcRes, result
    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-gemalto-classic change_pin(): oldPin:' .. oldPin, 'newPin:' .. newPin)

    if newPin and (string.len(newPin) < info.ulMinPinLen or string.len(newPin) > info.ulMaxPinLen) then
        log.output('token-gemalto-classic change_pin(): value not in range:', info.ulMinPinLen, info.ulMaxPinLen)
        return CKR.PIN_LEN_RANGE   
    end
    if ispuk and self.puk_not_modifiable then
        log.output('token-gemalto-classic change_pin(): PUK not modifiable!')
        return CKR.PIN_LEN_RANGE
    end
    local rv
    log.output('token-gemalto-classic change_pin(): cambio pin MAIN...')

    self._schedule_update_retry_counters = true
    
    self.gemalto_hcard:auto_perform_mutual_authenticate()
    pcRes, result = pcall(function() 
            return self.gemalto_hcard:change_pin_main(oldPin, newPin, ispuk, true) -- oldPin, newPin, ispuk, use_sm
        end)

    if result == 0 then
        -- la carta potrebbe dimenticare lo stato di logged in quando si effettua una change pin
        self.cached_main_pin = newPin
        pcRes, result = pcall(function()    
                return self.gemalto_hcard:verify_pin_main(newPin, ispuk, false, true)  -- pin, ispuk, check, use_sm
            end)
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
    log.output('token-gemalto-classic reset_pin(): newPin:', newPin)
    log.output('token-gemalto-classic reset_pin(): reset pin MAIN...')
    if self.userType ~= CKU.SO then
        log.output('token-gemalto-classic reset_pin(): user not SO!')
        return CKR.USER_TYPE_INVALID
    end
    
    local rv

    self._schedule_update_retry_counters = true
    
    if newPin and (string.len(newPin) < info.ulMinPinLen or string.len(newPin) > info.ulMaxPinLen) then
        log.output('token-gemalto-classic reset_pin(): value not in range:', info.ulMinPinLen, info.ulMaxPinLen)
        return CKR.PIN_LEN_RANGE   
    end
    
    self.gemalto_hcard:auto_perform_mutual_authenticate()
    pcRes, result = pcall(function()
        return self.gemalto_hcard:reset_pin_main(self.cached_main_pin, newPin, true) -- Puk, newPin, use_sm
        end)
    if pcRes and result == 0 then
        pcRes, result = pcall(function()
            return self.gemalto_hcard:verify_pin_main(newPin, false, false, true) -- pin, ispuk, check, use_sm
        end)
    end
    if result == 0 then
        if not self.userPinInitialized then
            local ao = p15.parseAuthObjects(self._indexes._auth_objects_bin)
            local pinFlags, pinObj
            for i, a in ao do
                if a.classAttributes and a.classAttributes.authId 
                    and a.typeAttributes and a.typeAttributes.pwdFlags then
                    pinFlags = p15.decode_PinFlags(a.typeAttributes.pwdFlags)
                    if not pinFlags.soPin and not pinFlags.unblockingPin then
                        pinFlags.initialized = true
                        pinObj = a
                        break
                    end
                end
            end
            if pinObj and pinFlags then
                pinObj.typeAttributes.pwdFlags = p15.encode_PinFlags(pinFlags)
                local aoD = p15.buildAuthObjects(ao)
                aoD = aoD .. string.rep("\000", string.len(self._indexes._auth_objects_bin) - string.len(aoD))
                self:_write_file(aoD, self.files.AODF)
                
                -- self._indexes._auth_objects_bin = nil
                -- self:_read_token_info_indexes()
                self._indexes._auth_objects_bin = aoD
                self.userPinInitialized = true
                self.info.flags = self.info.flags + CKF.USER_PIN_INITIALIZED
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



--=====================================================================================

function t.mt:sign_buffer(hKey, pMechanism, pData, allocated_space)
    
    log.output('sign_buffer():', hKey, pMechanism, hex.hexify(pData or ''), allocated_space)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('sign_buffer(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('sign_buffer(): ERROR: non private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    local pcRes, result

    if dataLen > keyBytes or (dataLen > (keyBytes -4) and dataLen <  keyBytes) then
        -- nota: il padding pkcs1 richiede almeno 8 byte di oxFF prima dei dati da firmare
        log.output('sign_buffer(): specified data len invalid: ', dataLen)
        return CKR.DATA_LEN_RANGE
    end
    if allocated_space==nil then
        log.output('sign_buffer(): returning signature length:', keyBytes)
        return CKR.OK, keyBytes
    else
        self.gemalto_hcard:auto_perform_mutual_authenticate()
        local contextual_pin = nil
        local check_pin_status = 0
        local userConsent = self:is_user_consent_key(obj.kid)
        log.output('sign_buffer(): using RSA-CDS mode on kid:', obj.kid, "userConsent:", userConsent)
        
        if userConsent and not self.contextual_pin_verified then
            if self.cfg["dspiniscnspin"] == "true" and self.cached_main_pin then
                local rv = self:verify_pin(self.cached_main_pin, CKU.CONTEXT_SPECIFIC, hKey)
                if rv ~= CKR.OK then
                    log.output('sign_buffer(): verify of main pin as CONTEXT_SPECIFIC failed:', rv)
                    return rv
                end
            elseif self.cfg["dspinusegui"] ~= 'false' and self.request_plugin_valid then
                if self.cached_ds_pin then
                    contextual_pin = self.cached_ds_pin
                else
                    local res, cache_ds_pin
                    while true do
                        res, contextual_pin, cache_ds_pin = self:gui_request_pin_ds(self.check_box_visible)
                        if res ~= 1 then
                            log.output('sign_buffer(): cancelled by plugin with code:', res)
                            return CKR.FUNCTION_FAILED
                        end
                        -- forza la mutua autenticazione perch