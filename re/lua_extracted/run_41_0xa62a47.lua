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


function t.mt:init_pin_policy(pinPolicy)
    log.output("init_pin_policy()")

    if self._mobile_enabled and not self._forcepinpolicy then
        log.output('init_pin_policy(): pinpolicy disabled by default on mobile: use iforcepinpolicy=true in config to enable')
        return
    end
    
    if not self.p11_info or not self.p11_info.path_root then
        log.output('init_pin_policy(): Invalid FS: full p11 fs not present!')
        return
    end
    
    local pcRes, theErrorT = pcall(function()
        local pcRes, theErrorT
        self.pinRetry = 3 -- default
        local pinPolicyPath = hex.hexf(self.p11_info.path_root .. 'FFF0')
        local curPinLen = string.len(pin or "")
        local pcRes, theErrorT
        if type(pinPolicy) ~= "string" then
            pcRes, theErrorT = pcall( function()
                pinPolicy = self:read_cached_file(pinPolicyPath, 0, -1, true, true)
                if  type(pinPolicy) ~= "string" or string.len(pinPolicy) == 0 then
                    log.output("init_pin_policy(): not exists?")
                    error("init_pin_policy(): not exists?")
                end
            end) 
        else
            pcRes=true
        end
        if pcRes then
        
            -- struct format
            -- minLen: 1 byte
            -- maxLen: 1 byte
            -- complexityLevel: 1 byte, 0=disable, 1=only digits, 2=only digits and alpha, 2=
            -- pinHistory: 1 byte, 0=disable
            -- pinRetry: 1 byte
            
            -- adjacent   1 byte  allwoed repet|max appear
            -- allow numeric       0x80 | min
            -- allow alpha         0x80 | min
            -- allow symbols       0x80 | min
            -- allow extraascii    0x80 | min


            local pin_policy = string.sub(pinPolicy, 1, 10)
            pin_policy = pin_policy .. string.rep("\0", 10- string.len(pin_policy))
            local minLen, maxLen, complexityLevel, pinHistory, pinRetry = bin.unpack("%B%B%B%B%B", pin_policy)

            log.output("init_pin_policy(): minLen, maxLen, complexityLevel, pinHistory, pinRetry:", minLen, maxLen, complexityLevel, pinHistory, pinRetry)
            
            if minLen > 0 and curPinLen then
                self.info.ulMinPinLen=minLen
            end
            if maxLen > 0 then
                self.info.ulMaxPinLen=maxLen
            end
            local complexityLevel_f = bin.flags(complexityLevel)
            self.complexityLevel = (complexityLevel_f - bin.flags(128+64)).asnumber
            if self.complexityLevel > 3 and string.len(pinPolicy) >= 10 then
                local extPinPolicy = string.sub(pinPolicy, 6, -1)
                local adjacent, numeric, alpha, symbols, nonascii = bin.unpack("%B%B%B%B%B", extPinPolicy)
                self.max_repeat_same_char = (bin.flags(adjacent) * bin.flags(240)).asnumber / 16 -- hi nibble
                self.max_same_char = (bin.flags(adjacent) * bin.flags(15)).asnumber -- low nibble
                self.enable_numeric = numeric
                self.enable_alpha = alpha
                self.enable_symbols = symbols
                self.enable_nonascii = nonascii
                log.output(string.format(
                    "init_pin_policy() extended: max_repeat_same_char=%d, max_same_char=%d, enable_numeric=0x%02X, enable_alpha=0x%02X, enable_symbols=0x%02X, enable_nonascii=0x%02X", 
                    self.max_repeat_same_char, self.max_same_char, self.enable_numeric, self.enable_alpha, self.enable_symbols, self.enable_nonascii)
                )
            end
            self.pinUnchangable = complexityLevel_f[bin.flags(128)]
            self.pinNotUnlockable = complexityLevel_f[bin.flags(64)]
            self.pinHistory = pinHistory
            self.pinRetry = pinRetry
            self.pin_policy_value = pin_policy
            if self.pinRetry == 0 then
                self.pinRetry = 3
            end 

        else
            log.output("init_pin_policy(): read error=", debug.traceback( theErrorT))
        end
    end)
    if not pcRes then
        log.output("init_pin_policy(): generic error=", debug.traceback( theErrorT))
    end
end

function t.mt:check_pin_policy(newPin)
    log.output('check_pin_policy()', newPin, isPuk)
    local curPinLen = string.len(newPin or "")
    
    if curPinLen > self.info.ulMaxPinLen then
        log.output('check_pin_policy(): newPin too long')
        return CKR.PIN_LEN_RANGE
    end
    if curPinLen < self.info.ulMinPinLen then
        log.output('check_pin_policy(): newPin too short')
        return CKR.PIN_LEN_RANGE
    end

    if self.complexityLevel then
        if self.complexityLevel == 4 then
            if not utility.check_ext_policy(newPin, 
                self.max_same_char, 
                self.max_repeat_same_char,
                self.enable_numeric,
                self.enable_alpha,
                self.enable_symbols,
                self.enable_nonascii) then
                log.output('check_pin_policy(): newPin extended policy do not match!')
                return CKR.PIN_INVALID
            end
        elseif self.complexityLevel == 3 then
            -- upper & lower & numeric & symbols
            local level = 0
            if string.find(newPin, "[%d]") then level = level +1 end
            if string.find(newPin, "[%u]") then level = level +1 end
            if string.find(newPin, "[%l]") then level = level +1 end
            if string.find(newPin, "[%p]") then level = level +1 end
            if level < 3 then
                log.output('check_pin_policy(): newPin must contain at least 3 of: upper , lower , numeric , symbols');
                return CKR.PIN_INVALID
            end
        elseif self.complexityLevel == 2 then
            if not string.find(newPin, "[%d]") or not string.find(newPin, "[%a]") then
                log.output('check_pin_policy(): newPin must contain alpha + numeric');
                return CKR.PIN_INVALID
            end
        elseif self.complexityLevel == 1 then
            -- at least alpha + numeric
            if string.find(newPin, "[^%d]") then
                log.output('check_pin_policy(): newPin must contain only digits');
                return CKR.PIN_INVALID
            end           
        else
            -- any value is ok
        end
    end
    
    local historyList = self:manage_pin_history()
    
    if historyList and table.getn(historyList) > 0 then
        local sha = md.sha1()
        sha:update(newPin)
        local hNewPin = sha:final()
        
        for i=1,table.getn(historyList) do
            log.output('check_pin_policy(): history entry:', i, hex.hexify(historyList[i]));
            if historyList[i] == hNewPin then
                log.output('check_pin_policy(): pin value in history');
                return CKR.PIN_INVALID
            end
        end
    end
    return CKR.OK
end

function t.mt:manage_pin_history(newHistoryList)
    log.output('manage_pin_history():', repr(newHistoryList))
    
    if not self.p11_info or not self.p11_info.path_root then
        log.output('manage_pin_history(): Invalid FS: full p11 fs not present!')
        return
    end
    
    local valueHistoryPath
    local historyLen
    local historyValue
    local historyList
    local newHistory
    if self.pinHistory and self.pinHistory >0 then
        valueHistoryPath = hex.hexf(self.p11_info.path_root .. 'FFF1')
        historyLen = self.pinHistory
    end
    
    if valueHistoryPath then
        if newHistoryList then
            newHistory = table.concat(newHistoryList, "")
            newHistory = newHistory .. string.rep("\0", (historyLen * 20) - string.len(newHistory))
            newHistory = string.sub(newHistory, 1, historyLen * 20)
            log.output('manage_pin_history(): newHistory:',  hex.hexify(newHistory))
        end
        -- read/update value history
        local pcRes, theErrorT = pcall(function()
            log.output('manage_pin_history(): -- read/update value history')
            local fInfo = self.cns_hcard:select(valueHistoryPath, true)
            if newHistory then
                newHistory = string.sub(newHistory, 1, math.min(fInfo.size, string.len(newHistory)))
                log.output('manage_pin_history(): updating actual newHistory:',  hex.hexify(newHistory))
                self.cns_hcard:mupdate_binary(0, newHistory)
                log.output('manage_pin_history(): update done')
                historyValue = newHistory
            else
                historyValue = self.cns_hcard:mread_binary(0, math.min(fInfo.size, historyLen * 20))
            end
        end)
        if not pcRes then
            log.output('manage_pin_history() error:', theErrorT)
        end
        if pcRes and historyValue then
            historyList = {}
            for i=1,string.len(historyValue),20 do
                table.insert(historyList, string.sub(historyValue, i, i-1+20))
            end
        end
    end
    return historyList
end

local function table_insert_unique(t, value)
    for i=1,table.getn(t) do
        if t[i] == value then
            return
        end
    end
    table.insert(t, 1, value)
end

function t.mt:update_pin_history(oldPin, newPin)
    log.output('update_pin_history(oldPin, newPin): ', oldPin, newPin);
    local historyList = self:manage_pin_history()
    if historyList then
        local sha = md.sha1()
        sha:update(newPin)
        local hnewPin = sha:final()
        local sha = md.sha1()
        sha:update(oldPin)
        local holdPin = sha:final()
        
        table_insert_unique(historyList, holdPin)
        table_insert_unique(historyList, hnewPin)
        self:manage_pin_history(historyList)
    end
end



function t.mt:check_pin_value(newPin, check_value, isPuk)
    log.output('check_pin_value():', newPin, check_value, isPuk);
    local rv = CKR.OK
    local info = self:get_info()
    local pcRes, theErrorT = pcall(function()
        if type(newPin) == "string" then
            if check_value then
                if (string.len(newPin) < info.ulMinPinLen or string.len(newPin) > info.ulMaxPinLen) then
                    log.output('token-cns check_pin_value(): invalid newPin len:', string.len(newPin),
                        "ulMinPinLen:", info.ulMinPinLen, "ulMaxPinLen:", info.ulMaxPinLen)
                    rv = CKR.PIN_LEN_RANGE
                    return
                end
            end
            
            if string.find(newPin, "[^%d]") or string.len(newPin) > self.ulMaxPinLen_HW then
                sha = md.sha1()
                sha:update(newPin)
                d = sha:final()
                pinNum = bin.unpack("%>%L", string.sub(d, 1, 4))
                newPin = string.sub(tostring(math.mod(pinNum, 99999999)), 1, info.ulMaxPinLen_HW )
                log.output('token-cns check_pin_value(): non numeric pin patched: pinNum: ', pinNum, 'patched newPin:', newPin)
            end
        end
    end)
    if not pcRes then
        log.output('token-cns check_pin_value error:', theErrorT)
        rv = CKR.FUNCTION_FAILED
    end
    return rv, newPin
end


function t.mt:create_object_pin_policy(pTemplate)

    if not self.p11_info or not self.p11_info.path_root then
        log.output('create_object_pin_policy(): Invalid FS: full p11 fs not present!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    if self.userType ~= CKU.SO then
        log.output('create_object_pin_policy(): user type not SO')
        return CKR.USER_TYPE_INVALID
    end

    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local fids_parent = hexf(self.p11_info.path_root)
    local fid_main = tonumber("FFF0", 16)
    local fid_pin = tonumber("FFF1", 16)
    local all_fids = {fid_main, fid_pin}
    
    if not pTemplate[CKA.VALUE] or string.sub(pTemplate[CKA.VALUE], 1, 5) == string.rep("\0", 5) then
        log.output('create_object_pin_policy(): erasing PIN policy')
        for i=1,table.getn(all_fids) do
            pcall(function()
                self.cns_hcard:select(fids_parent)
                self.cns_hcard:delete_file(all_fids[i])
            end)
        end
        self.attributes[1] = nil
        return CKR.OK, 0
    end
    
    local attr = string.sub(pTemplate[CKA.VALUE], 1, 10)
    attr = attr .. string.rep("\0", 10- string.len(attr))
    log.output('create_object_pin_policy(): setting new pin policy:', hex.hexify(attr) )
    
    self:create_file ({
        fid = fid_main,
        size=string.len(attr),
        filetype=CnsSmartcard.fileTypes.Binary,
        parent=fids_parent,
        aac={read = 0,
            update = self.cns_hcard.BSO_CNS_PUK,
            append = self.cns_hcard.BSO_CNS_PUK,
            delete = 0,
        },
    }, true, true);
    
    self.cns_hcard:mupdate_binary(0, attr)
    
    self:init_pin_policy(attr)
    
    if self.pinHistory and self.pinHistory > 0 then
        self:create_file ({
            fid = fid_pin,
            size=20 * self.pinHistory,
            filetype=CnsSmartcard.fileTypes.Binary,
            parent=fids_parent,
            aac={read = self.cns_hcard.BSO_CNS_PIN,
                update = self.cns_hcard.BSO_CNS_PIN,
                append = self.cns_hcard.BSO_CNS_PIN,
                delete = 0,
            },
        }, true, true);
    else
        pcall(function()
            self.cns_hcard:select(fids_parent)
            self.cns_hcard:delete_file(fid_pin)
        end)
    end
    
    if self.pinRetry > 0 then
        log.output('create_object_pin_policy(): recreating PIN')
        self.cns_hcard:select(hexf('3F00'))
        local apdu = hex.hexf("00da016e17830200%B850802%B87%Bffff0008860700%B%B%B%B%B00", 
            self.cns_hcard.BSO_CNS_PIN,
            self.pinRetry, self.pinRetry,
            self.cns_hcard.BSO_CNS_PIN, self.cns_hcard.BSO_CNS_PUK, self.cns_hcard.BSO_CNS_PUK, self.cns_hcard.BSO_CNS_PUK, self.cns_hcard.BSO_CNS_PUK)
        local recv = self.cns_hcard:transmit(apdu)
        sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            log.output('create_object(): error changing PIN retry counter')
        end
    end
    
    obj = {[CKA.CLASS]=eCK.ULONG(CKO_PIN_POLICY), [CKA.TOKEN]=eCK.BBOOL(true), [CKA.VALUE]=self.pin_policy_value}
    self.attributes[1] = obj
    return CKR.OK, 1
end


function t.mt:_set_pin_flags_ok(setPIN_OK, setPUK_OK)


    log.output("_set_pin_flags_ok(): setPIN_OK", setPIN_OK)
    log.output("_set_pin_flags_ok(): setPUK_OK", setPUK_OK)
    if setPIN_OK then
        self.info.flags = self.info.flags - CKF.USER_PIN_LOCKED
        self.info.flags = self.info.flags - CKF.USER_PIN_FINAL_TRY
        self.info.flags = self.info.flags - CKF.USER_PIN_COUNT_LOW
    end
    if setPUK_OK then
        self.info.flags = self.info.flags - CKF.SO_PIN_LOCKED
        self.info.flags = self.info.flags - CKF.SO_PIN_FINAL_TRY
        self.info.flags = self.info.flags - CKF.SO_PIN_COUNT_LOW
    end
    
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
            self:_set_pin_flags_ok(not ispuk, ispuk)
            return CKR.OK
        end
    end
    
    -- update only on verify failure
    self._schedule_update_retry_counters = true
    if not self._mobile_enabled then
        -- on mobile avoids checking cache at each login
        self:check_clear_cache(nil, true, true)
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
    self._schedule_update_retry_counters = true
    log.output('token-cns change_pin1(): oldPin:', oldPin, 'newPin:', newPin)
    
    if type(newPin) == "string" and (string.len(newPin) > self.info.ulMaxPinLen or string.len(newPin) < self.info.ulMinPinLen) then
        log.output('token-cns change_pin1(): invalid pin len')
        return CKR.PIN_LEN_RANGE
    end
    
    pcRes = pcall(function() return self.cns_hcard:select(hexf('3F00')) end )
    pcRes, result = pcall(function() return self.cns_hcard:change_pin_cns(oldPin, newPin, ispuk) end)
    if not pcRes then
        log.output('token-cns change_pin1 error:', result)
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
    log.output('token-cns change_pin2(): oldPin:', oldPin, 'newPin:', newPin)

    if type(newPin) == "string" and (string.len(newPin) > self.info.ulMaxPinLen or string.len(newPin) < self.info.ulMinPinLen) then
        log.output('token-cns change_pin2(): invalid pin len')
        return CKR.PIN_LEN_RANGE
    end
    
    if self.ds_info == nil then
        log.output('token-cns change_pin2(): DS app not found!')
        return CKR.OK
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
        pcRes, result =  pcall(function()
                local pinDs, newpinDs = oldPin, newPin
                return self.cns_hcard:change_pin_ds(pinDs, newpinDs, sm_enc, sm_sig, ispuk) end
                )
    end
    if not pcRes then
        log.output('token-cns change_pin2 error:', result)
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


function t.mt:change_pin(oldPin, newPin)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local newPinOrig = newPin
    local oldPinOrig = oldPin
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
    
    pcall(function()
        self:init_pin_policy()
    end)
    
    if not ispuk and self.pinUnchangable then
        log.output('token-cns change_pin(): PIN not modifiable by policy!')
        return CKR.TOKEN_WRITE_PROTECTED
    end
    
    self._schedule_update_retry_counters = true
    if type(newPin) == "string" and (string.len(newPin) > self.info.ulMaxPinLen or string.len(newPin) < self.info.ulMinPinLen) then
        log.output('token-cns change_pin(): invalid pin len')
        return CKR.PIN_LEN_RANGE
    end

    if not ispuk then
        rv = self:check_pin_policy(newPinOrig)
        if rv ~= CKR.OK then
            log.output('check_pin_value(): newPin rejected');
            return rv
        end
    end
    
    pcRes = pcall(function() return self.cns_hcard:select(hexf('3F00')) end )
    pcRes, result = pcall(function() return self.cns_hcard:change_pin_cns(oldPin, newPin, ispuk) end)
    local changeDsPin = false

    if self.ds_info ~= nil and pcRes and result == 0 then
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