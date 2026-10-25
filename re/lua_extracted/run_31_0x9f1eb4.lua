 collegato ad una chiave protetta da pin secondario
        [ CKA.ALWAYS_AUTHENTICATE ] = eCK.BBOOL(true),

    }
end

function t.GetDSPrivKeyTemplate(populatePubKeyFunc, i)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PRIVATE_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(false),
        [ CKA.LABEL ] = 'DS User Private Key ' .. i,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = 'DS' .. i,
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = eCK.BBOOL(true),
        [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.RSA_PKCS_KEY_PAIR_GEN),
        -- [ CKA.ALLOWED_MECHANISMS ] = '',
        -- Private Key
        [ CKA.SUBJECT ] = '',
        [ CKA.SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.DECRYPT ] = eCK.BBOOL(false),
        [ CKA.SIGN ] = eCK.BBOOL(true),
        [ CKA.SIGN_RECOVER ] = eCK.BBOOL(false),
        [ CKA.UNWRAP ] = eCK.BBOOL(false),
        [ CKA.EXTRACTABLE ] = eCK.BBOOL(false),
        [ CKA.ALWAYS_SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.NEVER_EXTRACTABLE ] = eCK.BBOOL(true),
        [ CKA.WRAP_WITH_TRUSTED ] = eCK.BBOOL(false),
        -- [ CKA.UNWRAP_TEMPLATE ] = '',
        [ CKA.ALWAYS_AUTHENTICATE ] = eCK.BBOOL(true),
        -- RSA Private Key
        [ CKA.MODULUS ] = populatePubKeyFunc,
        [ CKA.PUBLIC_EXPONENT ] = populatePubKeyFunc,
        [ CKA.PRIVATE_EXPONENT ] = -1,
        [ CKA.PRIME_1 ] = -1,
        [ CKA.PRIME_2 ] = -1,
        [ CKA.EXPONENT_1 ] = -1,
        [ CKA.EXPONENT_2 ] = -1,
        [ CKA.COEFFICIENT ] = -1,
    }
end

return t

--===========================================================================
end
}
_LOADED['token-cie3'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- token-cie3.lua
local CIE3Smartcard = require 'CIE3Smartcard'
local hex = require 'hex'
local zlib = require "zlib"
local hexf = hex.hexf
local der = require 'der'
local utility = require 'utility'
local repr = utility.repr

local MinKSize, MaxKSize = 1024, 2048
local t = {
    name = 'cie3',
    mt = { },
    mechanisms = {
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.SIGN},
    },
    cie3_hcard = nil,
    -- le chiavi CIE 3.0 sono protette da un singolo PIN
    capabilities = { private_attributes_readable=false, always_authenticate_on_cert=false, },
    CIE3Smartcard=CIE3Smartcard,
}
t.mt.__index = t.mt


function t.mt:initialize(cfg)
    log.output('token-cie3:initialize():')
    local files = {}
    self.files = files

    self.capabilities = utility.clone_table(t.capabilities)
    self.cie3_hcard = CIE3Smartcard.new(self.hcard)
    self.mechanisms = utility.clone_table(t.mechanisms)

    
    self.puk_not_modifiable = true
    self.slow_card = false
    self.userPinInitialized = true
    self.cfg = cfg or utility.parse_cfg()

    local mKey = sm.sm_ask_keys(10)  -- richiede la chiave #10, master key per cifratura chiavi
    local default_master_key

    self.cfg["xproc"] = self.cfg["xproc"] or self.cfg["c3xproc"]
    
    
    if self.cfg["xproc"] then self.cfg["xproc"]=string.lower(self.cfg["xproc"])
    else self.cfg["xproc"]='true' end
    
    log.output('CIE3 Token initialize(): use_cpr_mode:', self.use_cpr_mode)
    
    self.check_box_visible = 0
    if self.cfg["hidecachedspincheck"] == 'true' then
        self.check_box_visible = nil
    end
    if self._cache_id == nil then
        self:flush_cache()
    end
end

function t.mt:begin_transaction()
    self.cie3_hcard:begin_transaction()
end

function t.mt:end_transaction()
    self.cie3_hcard:end_transaction()
end

function t.mt:_call_on_end_transaction()
    log.output('token-cie3:_call_on_end_transaction()...')
    self.cie3_hcard:on_end_transaction()
end


function t.mt:finalize()
    log.output("token-cie3:finalize():", self.userType)
    utility.forget_token_changed(self, "cache")
end

function t.mt:_update_retry_counters()

    log.output("_update_retry_counters...");
    -- if (self.info) then
        -- pcall (function()
            -- self.info.flags = self.info.flags - CKF.USER_PIN_LOCKED
            -- self.info.flags = self.info.flags - CKF.USER_PIN_FINAL_TRY
            -- self.info.flags = self.info.flags - CKF.USER_PIN_COUNT_LOW
            -- self.info.flags = self.info.flags - CKF.SO_PIN_LOCKED
            -- self.info.flags = self.info.flags - CKF.SO_PIN_FINAL_TRY
            -- self.info.flags = self.info.flags - CKF.SO_PIN_COUNT_LOW
            -- local pinRetry, pinRetryMax, pukRetry, pukRetryMax = self.cie3_hcard:get_pin_puk_status()
            -- log.output("get_pin_puk_status, PIN cur/max", pinRetry, pinRetryMax, "PUK cur/max:", pukRetry, pukRetryMax);
            -- if pinRetry == 0 then
                -- self.info.flags = self.info.flags + CKF.USER_PIN_LOCKED
            -- elseif pinRetry == 1 then
                -- self.info.flags = self.info.flags + CKF.USER_PIN_FINAL_TRY
            -- elseif pinRetry < pinRetryMax then
                -- self.info.flags = self.info.flags + CKF.USER_PIN_COUNT_LOW
            -- end
            
            -- if pukRetry == 0 then
                -- self.info.flags = self.info.flags + CKF.SO_PIN_LOCKED
            -- elseif pukRetry == 1 then
                -- self.info.flags = self.info.flags + CKF.SO_PIN_FINAL_TRY 
            -- elseif pukRetry < pukRetryMax then
                -- self.info.flags = self.info.flags + CKF.SO_PIN_COUNT_LOW
            -- end
        -- end)
    -- end
    
end


function t.mt:add_info()
    log.output('add_info(): performing mutual authenticate...')
    local CSN = string.upper(self.cie3_hcard:read_serial_number())
    
    self.info.serialNumber = string.rep("0", 16 - string.len(CSN)) .. CSN
    self.info.label = "CIE " .. CSN
end


function t.mt:get_info()
    if not self.info then
        self.info = {
            label = 'CIE',
            manufacturerID = 'IPZS',
            model = 'CIE 3.0',
            serialNumber = '0000000000000000',
            flags = CKF.RNG + CKF.LOGIN_REQUIRED +
                    CKF.USER_PIN_INITIALIZED + CKF.TOKEN_INITIALIZED,
            ulMaxSessionCount = CK.EFFECTIVELY_INFINITE,
            ulSessionCount = 0,
            ulMaxRwSessionCount = CK.EFFECTIVELY_INFINITE,
            ulRwSessionCount = CK.UNAVAILABLE_INFORMATION,
            ulMaxPinLen = 8,
            ulMinPinLen = 6,
            ulTotalPublicMemory = 65535,
            ulFreePublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulTotalPrivateMemory = 65535,
            ulFreePrivateMemory = CK.UNAVAILABLE_INFORMATION,
            hardwareVersion = { major=3, minor=0},
            firmwareVersion = { major=3, minor=0},
            utcTime = '0000000000000000'
        }
        
        self:add_info()
        if self.cfg["c3defaultlabel"] then
            self.info.label = self.cfg["c3defaultlabel"]
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
    
    self.cie3_hcard:auto_perform_mutual_authenticate()

    
    result = self.cie3_hcard:verify_pin_main(pin, ispuk) -- pin, ispuk
    log.output("verify_pin_main(): result=", result)
    if result == 0 then
        self.cached_main_pin = pin
        self.userType = userType
        
        if self.attributes == nil then
            self.attributes = self:get_objects()
        end
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
    local ispuk = false
    if self.userType == CKU.SO then ispuk = true end
    local pcRes, result
    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-cie3 change_pin(): oldPin:' .. oldPin, 'newPin:' .. newPin)

    if newPin and (string.len(newPin) < info.ulMinPinLen or string.len(newPin) > info.ulMaxPinLen) then
        log.output('token-cie3 change_pin(): value not in range:', info.ulMinPinLen, info.ulMaxPinLen)
        return CKR.PIN_LEN_RANGE   
    end
    if ispuk and self.puk_not_modifiable then
        log.output('token-cie3 change_pin(): PUK not modifiable!')
        return CKR.PIN_LEN_RANGE
    end
    local rv
    log.output('token-cie3 change_pin(): cambio pin MAIN...')

    self._schedule_update_retry_counters = true
    
    self.cie3_hcard:auto_perform_mutual_authenticate()
    pcRes, result = pcall(function() 
            return self.cie3_hcard:change_pin_main(oldPin, newPin, ispuk, true) -- oldPin, newPin, ispuk, use_sm
        end)

    if result == 0 then
        -- la carta potrebbe dimenticare lo stato di logged in quando si effettua una change pin
        self.cached_main_pin = newPin
        pcRes, result = pcall(function()    
                return self.cie3_hcard:verify_pin_main(newPin, ispuk, false, true)  -- pin, ispuk, check, use_sm
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
    log.output('token-cie3 reset_pin(): newPin:', newPin)
    log.output('token-cie3 reset_pin(): reset pin MAIN...')
    if self.userType ~= CKU.SO then
        log.output('token-cie3 reset_pin(): user not SO!')
        return CKR.USER_TYPE_INVALID
    end
    
    local rv

    self._schedule_update_retry_counters = true
    
    if newPin and (string.len(newPin) < info.ulMinPinLen or string.len(newPin) > info.ulMaxPinLen) then
        log.output('token-cie3 reset_pin(): value not in range:', info.ulMinPinLen, info.ulMaxPinLen)
        return CKR.PIN_LEN_RANGE   
    end
    
    self.cie3_hcard:auto_perform_mutual_authenticate()
    pcRes, result = pcall(function()
        return self.cie3_hcard:reset_pin_main(self.cached_main_pin, newPin, true) -- Puk, newPin, use_sm
        end)
    if pcRes and result == 0 then
        pcRes, result = pcall(function()
            return self.cie3_hcard:verify_pin_main(newPin, false, false, true) -- pin, ispuk, check, use_sm
        end)
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
        self.cie3_hcard:auto_perform_mutual_authenticate()
        log.output('sign_buffer(): using RSA INTERNAL AUTH mode on kid:', obj.kid)

        if self.cached_main_pin then 
            self.cie3_hcard:verify_pin_main(self.cached_main_pin, false) -- pin, ispuk
        end
        pcRes, result = pcall(function()
                        return self.cie3_hcard:pso_internal_auth(
                            pData,
                            obj.kid
                            )
                        end )
        if pcRes then
            return CKR.OK, result
        end

    end
    log.output('sign_buffer(): unexpected!')
    return CKR.FUNCTION_FAILED
end

function t.mt:decrypt_buffer(hKey, pMechanism, pData, allocated_space)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('decrypt_buffer(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('decrypt_buffer(): ERROR: not a private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end

    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    if dataLen ~= keyBytes then
        log.output('decrypt_buffer(): specified data len invalid: ', dataLen, ', expected:', keyBytes)
        return CKR.ENCRYPTED_DATA_LEN_RANGE
    end
    
    self.cie3_hcard:auto_perform_mutual_authenticate()
    pcall(function()
        log.output('decrypt_buffer(): verify_pin_main() with:', self.cached_main_pin, self.userType)
        if self.cached_main_pin and self.userType == CKU.USER then
            self.cie3_hcard:verify_pin_main(self.cached_main_pin, false, false, true) -- pin, ispuk, check, use_sm
        end
    end)
    local pDataPadded
    pDataDecrypted = self.cie3_hcard:pso_decrypt(pData, obj.kid, true) -- data, id, use_sm
    
    return CKR.OK, pDataDecrypted
end


-- se search_state.lastobj==nil si richiede l'handle del primo oggetto che risponda
-- al template. Altrimenti restituisce il primo oggetto che sia
-- compatibile con il template e abbia handle>search_state.lastobj.
-- quando non ci sono pi