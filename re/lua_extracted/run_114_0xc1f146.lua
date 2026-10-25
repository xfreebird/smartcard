 valorizzato
    -- i PIN sono considerati uguali
    if not self.cfg["dspiniscnspin"] and not self.request_plugin_valid then
        log.output('Incard TS token initialize(): no plugin and dspiniscnspin unset: forcing dspiniscnspin=true')
        self.cfg["dspiniscnspin"] = 'true'
    end
    
    if self.cfg["dspinusegui"] then self.cfg["dspinusegui"]=string.lower(self.cfg["dspinusegui"])
    else self.cfg["dspinusegui"]='true' end
    
    if self.cfg["dspiniscnspin"] then self.cfg["dspiniscnspin"]=string.lower(self.cfg["dspiniscnspin"])
    else self.cfg["dspiniscnspin"]='false' end

    if self.cfg["hidecachedspincheck"] then self.cfg["hidecachedspincheck"]=string.lower(self.cfg["hidecachedspincheck"])
    else self.cfg["hidecachedspincheck"]='false' end
    
    self.check_box_visible = 0
    if self.cfg["hidecachedspincheck"] == 'true' then
        self.check_box_visible = nil
    end
    self.default_container_data_obj = "CSPSmartLogon"
    self.mechanisms = utility.clone_table(t.mechanisms)
    
    if self.cfg["dsmode"] == "dsonly" then
        self.dsmode = "dsonly"
    elseif self.cfg["dsmode"] == "authonly" then
        self.dsmode = "authonly"
    end
    if self._cache_id == nil then
        self:flush_cache()
    end
end

function t.mt:finalize()
    log.output("token-ts:finalize():", self.session, self.userType)
end
    
function t.mt:gui_show_pin_message(result, ispuk)
    local msgid = 0
    if result==2 and ispuk then msgid = emt.PukLocked
    elseif result==2 and not ispuk then msgid = emt.PinLocked
    elseif result==1 and ispuk then msgid = emt.PukIncorrect
    elseif result==1 and not ispuk then msgid = emt.PinIncorrect
    else
        return -1
    end
    
    local transactionDisabled = self.hcard:transactionsdisabled()
    self.hcard:disabletransactions(false)
    if transactionDisabled then
        self.hcard:endtransaction()
    else
        self.cmd_hcard:end_transaction()
    end
    local res = w32.show_message(msgid)
    self.hcard:status() -- in caso di reset effettua una reconnect
    if transactionDisabled then
        self.hcard:begintransaction()
    else
        self.cmd_hcard:begin_transaction()
    end
    self.hcard:disabletransactions(transactionDisabled)
    return res
end

function t.mt:gui_change_pin_ds(ispuk)
    local transactionDisabled = self.hcard:transactionsdisabled()
    self.hcard:disabletransactions(false)
    if transactionDisabled then
        self.hcard:endtransaction()
    else
        self.cmd_hcard:end_transaction()
    end
    local res, pinDs, newpinDs = w32.change_pin_ds(ispuk)
    self.hcard:status() -- in caso di reset effettua una reconnect
    if transactionDisabled then
        self.hcard:begintransaction()
    else
        self.cmd_hcard:begin_transaction()
    end
    self.hcard:disabletransactions(transactionDisabled)
    
    return res, pinDs, newpinDs
end

function t.mt:gui_unlock_pin_ds()
    local transactionDisabled = self.hcard:transactionsdisabled()
    self.hcard:disabletransactions(false)
    if transactionDisabled then
        self.hcard:endtransaction()
    else
        self.cmd_hcard:end_transaction()
    end
    local res, pukDs, newpinDs = w32.unlock_pin_ds()
    self.hcard:status() -- in caso di reset effettua una reconnect
    if transactionDisabled then
        self.hcard:begintransaction()
    else
        self.cmd_hcard:begin_transaction()
    end
    self.hcard:disabletransactions(transactionDisabled)
    return res, pukDs, newpinDs
end
                
function t.mt:gui_request_pin_ds()
    local transactionDisabled = self.hcard:transactionsdisabled()
    self.hcard:disabletransactions(false)
    if transactionDisabled then
        self.hcard:endtransaction()
    else
        self.cmd_hcard:end_transaction()
    end
    local res, contextual_pin, cache_ds_pin = w32.request_pin_ds(self.check_box_visible)
    self.hcard:status() -- in caso di reset effettua una reconnect
    if transactionDisabled then
        self.hcard:begintransaction()
    else
        self.cmd_hcard:begin_transaction()
    end
    self.hcard:disabletransactions(transactionDisabled)
    return res, contextual_pin, cache_ds_pin
end


function t.mt:begin_transaction()
    self.cmd_hcard:begin_transaction()
end

function t.mt:end_transaction()
    self.cmd_hcard:end_transaction()
end


function t.mt:add_info_cmd()
    
    -- cmd_info contiene le info sul FS di firma specifico della CMD
    self.cmd_info = {}
    self.cmd_info.ds_sig_path = "12001400"
    self.cmd_info.p11_path_certs = "120030006000"
    self.cmd_info.p11_path_keys = "1200300040000001"
    if not pcall(function() return self.cmd_hcard:select(hexf('3F0010001003')) end ) then
        log.output('add_info_cmd(): error reading CMD Serial Number file...')
    else
        self.info.serialNumber = self.cmd_hcard:read_binary(0,16)
    end 
    pcall (function()
        self.cmd_hcard:select(hexf(self.cmd_info.ds_sig_path .. "c000"))
        local certVal = self.cmd_hcard:read_binary(0, 1)
        self.cmd_info.cert_valid = (string.byte(certVal, 1) == 48) -- hex 30
        self.cmd_info.key_valid = self.cmd_info.cert_valid
    end)
    -- pcall (function()
        -- self.cmd_hcard:select(hexf(self.cmd_info.ds_sig_path .. "c00e"))
        -- local certVal = self.cmd_hcard:read_binary(0, 1)
        -- self.cmd_info.ca_cert_valid = (string.byte(certVal, 1) == 48) -- hex 30
    -- end)
    pcall (function()
        self.cmd_hcard:select(hexf(self.cmd_info.p11_path_certs .. "0000"))
        local certVal = self.cmd_hcard:read_binary(0, 1)
        self.cmd_info.crypt_cert_valid = (string.byte(certVal, 1) == 48) -- hex 30
    end)
    log.output('add_info_cmd(): cmd_info.cert_valid:', self.cmd_info.cert_valid)

    
    self.cns_info = {} -- cns_info contiene le info sul FS simil CNS di autenticazione
    pcall (function()
        self.cmd_hcard:select(hexf(objCnsTmpl.GetCNSCertTemplate().path))
        local certVal = self.cmd_hcard:read_binary(0, 1)
        self.cns_info.cert_valid = (string.byte(certVal, 1) == 48) -- hex 30
    end)
    log.output('add_info_cmd(): certificate valid:', self.cns_info.cert_valid)
    pcall (function()
        self.cmd_hcard:select(hexf(objCnsTmpl.GetCNSPubKeyTemplate().path))
        local pubKeyVal = self.cmd_hcard:read_record(1, 4, 3)
        self.cns_info.key_valid = ( 
                        (string.byte(pubKeyVal, 1) == 16 or string.byte(pubKeyVal, 1) == 17) -- hex 10, 11
                        and string.byte(pubKeyVal, 3) ~= 255 -- hex FF
                        )
    end)
    log.output('add_info_cmd(): key valid:', self.cns_info.key_valid)

end

function t.mt:get_info()
    if not self.info then
        self.info = {
            label = 'CMD',
            manufacturerID = '',
            model = 'AUTH DS',
            serialNumber = nil,
            flags = CKF.RNG + CKF.LOGIN_REQUIRED + CKF.TOKEN_INITIALIZED,
            ulMaxSessionCount = CK.EFFECTIVELY_INFINITE,
            ulSessionCount = 0,
            ulMaxRwSessionCount = CK.EFFECTIVELY_INFINITE,
            ulRwSessionCount = CK.UNAVAILABLE_INFORMATION,
            ulMaxPinLen = self.cmd_hcard.PUK_PADDING or 8,
            ulMinPinLen = 1,
            ulTotalPublicMemory = 31988,
            ulFreePublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulTotalPrivateMemory = 780,
            ulFreePrivateMemory = CK.UNAVAILABLE_INFORMATION,
            hardwareVersion = { major=0, minor=0},
            firmwareVersion = { major=0, minor=0},
            utcTime = '0000000000000000'
        }
        
        self:add_info_cmd()
        
        if self.dsmode == "dsonly" then
            self.info.flags = self.info.flags - CKF.LOGIN_REQUIRED
            self.info.model = "DS"
        elseif self.dsmode == "authonly" then
            self.info.model = "AUTH"
        end
        self.info.flags = self.info.flags + CKF.USER_PIN_INITIALIZED
    
    end 

    return self.info
end

function t.mt:get_mechanisms()
    local info = self:get_info()
    return self.mechanisms
end

function t.mt:verify_pin(pin, userType, contextual_obj)
    if self.dsmode == "dsonly" then
        return self:verify_pin_dsmode(pin, userType, contextual_obj)
    end
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk = false
    local result

    if userType == CKU.SO then 
        ispuk = true
    end
    log.output("verify_pin()", pin, userType, ispuk, contextual_obj)
    if userType == CKU.CONTEXT_SPECIFIC then
        result = self.cmd_hcard:select(hex.hexf(self.cmd_info.ds_sig_path))
        result = self.cmd_hcard:verify_pin_ds(pin)
        log.output("verify_pin_ds(): result=", result)
        if result == 0 then
            self.contextual_pin_verified = true
            return CKR.OK
        end
    else
        result = self.cmd_hcard:verify_pin_cns(pin, ispuk)
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

function t.mt:verify_pin_dsmode(pin, userType, contextual_obj)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk = false
    local result
    
    if userType == CKU.SO then 
        ispuk = true
    end
    
    log.output("verify_pin()", pin, userType, ispuk, contextual_obj)
    result = self.cmd_hcard:select(hex.hexf(self.cmd_info.ds_sig_path))
    
    result = self.cmd_hcard:verify_pin_ds(pin, nil, nil, ispuk)
    log.output("verify_pin_ds(): result=", result)
    
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
    log.output('token-cmd change_pin(): oldPin:', oldPin, 'newPin:', newPin)
    log.output('token-cmd change_pin(): cambio pin CNS...')
    
    if ispuk then
        log.output('token-cmd change_pin(): cambio PUK non supportato')
        return CKR.FUNCTION_FAILED
    end
    pcRes = pcall(function() return self.cmd_hcard:select(hexf('3F00')) end )
    
    if self.dsmode ~= "dsonly" then
        pcRes, result = pcall(function() 
            return self.cmd_hcard:change_pin_cns(oldPin, newPin, ispuk) 
        end)
    else
        pcRes, result = true, 0
    end
    
    -- local changeDsPin = false

    -- if self.dsmode ~= "authonly" and self.cmd_info ~= nil and pcRes and result == 0 then
        -- while true do -- simulazione del goto...
            -- local res, pinDs, newpinDs
            -- if self.cfg["dspinusegui"] ~= 'false' and self.request_plugin_valid then
                -- log.output('token-cmd change_pin(): requesting DS pin using GUI...')
                -- res, pinDs, newpinDs = w32.change_pin_ds(ispuk)
                -- log.output('token-cmd change_pin(): DS request result:', res, pinDs, newpinDs)
                -- if res ~= 1 then
                    -- log.output('change_pin(): cancelled by plugin with code:', res)
                    -- return CKR.FUNCTION_FAILED
                -- else
                    -- changeDsPin = true
                -- end
            -- elseif self.cfg["dspiniscnspin"] == 'true' then
                -- log.output('token-cmd change_pin(): main PIN is DS PIN...')
                -- changeDsPin = true
                -- pinDs, newpinDs = oldPin, newPin
            -- end
            -- if changeDsPin then
                -- log.output('token-cmd change_pin(): cambio pin DS...')
                -- pcRes = pcall(function() return self.cmd_hcard:select(hexf(self.cmd_info.ds_sig_path)) end )
                -- if self.cmd_info.changepin_explicit_test then
                    -- log.output('token-cmd change_pin(): changepin_explicit_test...')
                    -- result = self.cmd_hcard:verify_pin_ds(pinDs, nil, nil, ispuk)
                    -- pinDs = nil
                    -- pcRes = true
                -- else
                    -- result=0
                -- end
                -- if result==0 then
                    -- pcRes, result =  pcall(
                            -- function() return self.cmd_hcard:change_pin_ds(pinDs, newpinDs, nil, nil, ispuk) end
                            -- )
                -- end
                -- if result ~= 0 then
                    -- -- ripristina il vecchio pin principale
                    -- log.output('token-cmd change_pin(): errore ',
                                -- result,
                                -- ' cambiando il pin DS!', 
                                -- 'Il pin CNS verr