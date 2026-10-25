 una metatable fittizia usata per un token non
-- ancora identificato. Appena usato il token viene identificato
-- e la metatable sostituita con quella vera.
function s.dummytoken_mt:__index(index)
    local fsname
    local isP11wrapper = false
    local status, err = self.hcard:status()
    log.output('--LUA: s.dummytoken_mt:__index():', index)
    if self.initialized then
        log.output('--LUA: s.dummytoken_mt:__index(): already initialized')
        return
    end
    local token_found = false
    local _etokensf = s._active_tokens_mask
    
    local cfg = util.parse_cfg()
    
    if _etokensf[bin.flags(token_class_cns_only)] then
        log.output("--LUA: CNS ONLY mode...")
        fsname = s._detect_fs(self.hcard, cfg)
        log.output("fsname:", fsname)
        
        if (_etokensf[bin.flags(token_class_gemalto)] and 'cns_gemalto' == fsname)
            or (_etokensf[bin.flags(token_class_oberthur)] and 'cns_oberthur' == fsname)
            or (_etokensf[bin.flags(token_class_oberthur)] and 'cns_oberthur_postecom' == fsname)
            or (_etokensf[bin.flags(token_class_cns_incard)] and 'cns_incard' == fsname) 
            or (_etokensf[bin.flags(token_class_cns_full)] and 'cns_incard' == fsname) 
            or (_etokensf[bin.flags(token_class_athena)] and 'cns_athena' == fsname) 
            then
            log.output("--LUA: CNS ONLY mode: specific CNS tokens are enabled, skipping...")
            
        elseif string.sub(fsname, 1, 3) == "cns" then -- generic cns* tokens
            
            log.output("--LUA: CNS ONLY mode: s.dummytoken_mt:__index(): recognized CNS generic token")
            setmetatable(self, s.token_types[token_class_cns_only].mt)
            self.cns_only = true
            
            if index == "begin_transaction" then
                log.output("--LUA: s.dummytoken_mt:__index(): special case, calling 'begintransaction' before token:initialize()")
                self.hcard:begintransaction()
            end
            local pcRes, theErrorT = pcall(function()
                self:initialize()
                self.initialized = true
            end)
            if index == "begin_transaction" then
                log.output("--LUA: s.dummytoken_mt:__index(): special case, calling 'endtransaction' after token:initialize()")
                self.hcard:endtransaction()
            end
            if not pcRes then
                log.output("--LUA: s.dummytoken_mt:__index(): ERROR: ", theErrorT)
                error(theErrorT)
            end
            return self[index]
        else
            log.output('--LUA: CNS ONLY mode: s.dummytoken_mt:__index(): CNS ONLY mode: unsupported token')
        end
        
    end
    
    if _etokensf[bin.flags(token_class_p11wrap)] then
        log.output("--LUA: trying P11 tokens...")
        local p, slotBase = s.p11wrap_util.get_p11(self.hcard)
        if p then
            setmetatable(self, s.token_types[token_class_p11wrap].mt)
            self.p11_lib = p
            self.slotBase = slotBase
            token_found = true
            isP11wrapper=true
        end
    end
    
    if not token_found then
        fsname = fsname or s._detect_fs_cached(self.hcard, cfg)
        log.output("fsname:", fsname)
        if fsname == "cns_oberthur_postecom" then
            fsname = "cns_oberthur"
            log.output("NEW fsname:", fsname)
        end
        if _etokensf[bin.flags(token_class_cns_incard_pinpad)]
            and ('cns_incard' == fsname or 'ds_incard' == fsname 
            or ('cns' == fsname and status and string.len(status.atr or "") == 25 and string.byte(status.atr, 13) == 9)
            )then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized PINPAD INCARD token")
            setmetatable(self, s.token_types[token_class_cns_incard_pinpad].mt)
        elseif _etokensf[bin.flags(token_class_cns_full)] 
            and ('cns_incard' == fsname or 'ds_incard' == fsname or 'cns' == fsname) then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized CNS FULL token")
            setmetatable(self, s.token_types[token_class_cns_full].mt)
            self.cns_only = 'cns' == fsname
            log.output("--LUA: s.dummytoken_mt:__index(): cns_only=", self.cns_only)
        elseif _etokensf[bin.flags(token_class_cns_incard)]
            and ('cns_incard' == fsname or 'ds_incard' == fsname 
            or ('cns' == fsname and status and string.len(status.atr or "") == 25 and string.byte(status.atr, 13) == 9)
            )then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized CNS INCARD token")
            setmetatable(self, s.token_types[token_class_cns_incard].mt)
        elseif (_etokensf[bin.flags(token_class_piv)])
                and 'piv' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized PIV token. token_class_piv:",
                    s.token_types[token_class_piv])
            setmetatable(self, (s.token_types[token_class_piv]).mt)
        elseif (_etokensf[bin.flags(token_class_cryptoid)])
                and 'cryptoid' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized CryptoID token. token_class_cryptoid:",
                    s.token_types[token_class_cryptoid])
            setmetatable(self, (s.token_types[token_class_cryptoid]).mt)
        elseif (_etokensf[bin.flags(token_class_arjo)])
                and 'arjo' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized CryptoID token. token_class_arjo:",
                    s.token_types[token_class_arjo])
            setmetatable(self, (s.token_types[token_class_arjo]).mt)
        elseif (_etokensf[bin.flags(token_class_oberthur)])
                and 'cns_oberthur' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized CNS-oberthur token. token_class_oberthur:",
                    s.token_types[token_class_oberthur])
            setmetatable(self, (s.token_types[token_class_oberthur]).mt)
        elseif _etokensf[bin.flags(token_class_iasecc)] and 'iasecc' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized iasecc token")
            setmetatable(self, s.token_types[token_class_iasecc].mt)
        elseif _etokensf[bin.flags(token_class_inside)] and 'inside' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized inside token")
            setmetatable(self, s.token_types[token_class_inside].mt)
        elseif (_etokensf[bin.flags(token_class_gemalto)]) and 'cns_gemalto' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized CNS-gemalto token. token_class_gemalto:",
                    s.token_types[token_class_gemalto])
            setmetatable(self, (s.token_types[token_class_gemalto]).mt)
        elseif (_etokensf[bin.flags(token_class_athena)]) and 'cns_athena' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized CNS-athena token. token_class_athena:",
                    s.token_types[token_class_athena])
            setmetatable(self, (s.token_types[token_class_athena]).mt)
        elseif _etokensf[bin.flags(token_class_gemalto_classic)] and 'gemalto_classic' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized gemalto_classic token")
            setmetatable(self, s.token_types[token_class_gemalto_classic].mt)
        elseif _etokensf[bin.flags(token_class_eida)] and 'eida' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized eida token")
            setmetatable(self, s.token_types[token_class_eida].mt)
        elseif _etokensf[bin.flags(token_class_aet_startcos)] and 'aet_startcos' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized aet_startcos token")
            setmetatable(self, s.token_types[token_class_aet_startcos].mt)
        elseif _etokensf[bin.flags(token_class_cmd)] and 'cmd_milcard' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized cmd_milcard token")
            setmetatable(self, s.token_types[token_class_cmd].mt)
        elseif _etokensf[bin.flags(token_class_it_telecom)] and 'it_telecom' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized it_telecom token")
            setmetatable(self, s.token_types[token_class_it_telecom].mt)
        elseif _etokensf[bin.flags(token_class_cardos44)] and 'cardos44' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized cardos44 token")
            setmetatable(self, s.token_types[token_class_cardos44].mt)
        elseif _etokensf[bin.flags(token_class_cmg)] and 'cmg' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized cmg token")
            setmetatable(self, s.token_types[token_class_cmg].mt)
        elseif _etokensf[bin.flags(token_class_dni_peru)] and 'dni_peru' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized dni_peru token")
            setmetatable(self, s.token_types[token_class_dni_peru].mt)
        elseif _etokensf[bin.flags(token_class_cie3)] and 'cie3' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized cie3 token")
            setmetatable(self, s.token_types[token_class_cie3].mt)
        elseif _etokensf[bin.flags(token_class_siae)] and 'siae' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized siae token")
            setmetatable(self, s.token_types[token_class_siae].mt)
        elseif _etokensf[bin.flags(token_class_nxpias)] and 'nxpias' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized NXP IASS/ECC token")
            setmetatable(self, s.token_types[token_class_nxpias].mt)
        elseif _etokensf[bin.flags(token_class_nxpcdlite)] and 'nxpcdlite' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized NXP Chipdoc Lite token")
            setmetatable(self, s.token_types[token_class_nxpcdlite].mt)
        elseif _etokensf[bin.flags(token_class_idacosmox)] and 'idacosmox' == fsname then
            log.output("--LUA: s.dummytoken_mt:__index(): recognized ID-A cosmox token")
            setmetatable(self, s.token_types[token_class_idacosmox].mt)
        else
            log.output("--LUA: s.dummytoken_mt:__index(): unsupported token")
            log.output("--LUA: s.dummytoken_mt:__index(): forcing already initialized to avoid polling the card")
            self.initialized = true
            error('unsupported token')
        end
    end

    
    if cfg and self._token_cfg then
        log.output("--LUA: s.dummytoken_mt:__index(): initializing token specific cfg")
        for i,v in self._token_cfg do
            cfg[i] = self._token_cfg[i]
        end
    end
    if index == "begin_transaction" and not isP11wrapper then
        log.output("--LUA: s.dummytoken_mt:__index(): special case, calling 'begintransaction' before token:initialize()")
        self.hcard:begintransaction()
    end
    local pcRes, theErrorT = pcall(function()
        self:initialize(cfg)
        self.initialized = true
    end)
    if index == "begin_transaction" and not isP11wrapper then
        log.output("--LUA: s.dummytoken_mt:__index(): special case, calling 'endtransaction' after token:initialize()")
        self.hcard:endtransaction()
        if self._call_on_end_transaction then
            self:_call_on_end_transaction() -- since card:end_transaction() was not called, when present we call card:_call_on_end_transaction() 
        end
    end
    if not pcRes then
        log.output("--LUA: s.dummytoken_mt:__index(): ERROR: ", theErrorT)
        error(theErrorT)
    end
    return self[index]
end

return s

--===========================================================================
end
}
_LOADED['token-cosmox-ida'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- token-cosmox-ida.lua
local CosmoXIASSmartCard = require 'CosmoXIASSmartCard'
local hex = require 'hex'
local zlib = require "zlib"
local hexf = hex.hexf
local der = require 'der'
local utility = require 'utility'
local repr = utility.repr
local p15 = require("p15util")
local util = utility
local json = require("json")
local rsa = require("rsa")
local ecdhlib = require "ecdhlib"
local aes = require "aes"

local PIN_POLICY_HISTORY_HASH_LEN = 20
local CKO_PIN_POLICY = tonumber("80001000", 16)

local PINPAD_CTL_VERIFY=1
local PINPAD_CTL_CHANGE=2
local PINPAD_CTL_RESET=3

local PINPAD_CTL_PIN=256
local PINPAD_CTL_PUK=512
local PINPAD_CTL_DSPIN=768
local PINPAD_CTL_DSPUK=1024

local MinKSize, MaxKSize = 1024, 4096
local t = {
    name = 'idacosmox',
    mt = { },
    mechanisms = {
        [ CKM.RSA_PKCS_KEY_PAIR_GEN ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.GENERATE_KEY_PAIR},
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_PKCS_PSS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.SIGN+CKF.EXTENSION}, --- EXTENSION=PSS solo HW
        [ CKM.RSA_X_509 ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_PKCS_OAEP ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT},
        
        [ CKM.EC_KEY_PAIR_GEN ] = {ulMinKeySize=256, ulMaxKeySize=521, flags=CKF.HW+CKF.GENERATE_KEY_PAIR+CKF.EC_OID+CKF.EC_F_P+CKF.EC_UNCOMPRESS},
        [ CKM.ECDSA ] = {ulMinKeySize=256, ulMaxKeySize=521, flags=CKF.HW+CKF.SIGN+CKF.EC_OID+CKF.EC_F_P+CKF.EC_UNCOMPRESS},
    
        [ CKM.AES_KEY_GEN ] = {ulMinKeySize=16, ulMaxKeySize=32, flags=CKF.HW+CKF.GENERATE},
        [ CKM.AES_CBC ] = {ulMinKeySize=16, ulMaxKeySize=32, flags=CKF.HW+CKF.DECRYPT+CKF.ENCRYPT},
        [ CKM.AES_CBC_PAD ] = {ulMinKeySize=16, ulMaxKeySize=32, flags=CKF.HW+CKF.DECRYPT+CKF.ENCRYPT},
    },
    ida_hcard = nil,
    capabilities = { private_attributes_readable=true, always_authenticate_on_cert=false, },
    CosmoXIASSmartCard=CosmoXIASSmartCard,
    card_cache = "card_cache",
    MK=hex.hexf("539".."423A6A".."F9F".."3228AFE".."8ABCFB8D".."298ADB6EBD".."D942A184EEE50".."E2A3D6CD2".."254".."7F"),
}
t.mt.__index = t.mt

function t.mt:initialize(cfg)
    log.output('token-cosmox-ida:initialize():')
    local files = {}
    
    self._supports_3072 = true
    self._supports_4096 = true
    
    self.authID_Card_PIN = 'PIN'
    self.authID_Card_PUK = 'PUK'
    
    self.authID_Sig_PIN = 'QSCD'

    
    
    self.DF_PKI = hex.hexf("adf1")
    self.DF_DS = hex.hexf("adf2")
    
    files.SN = hexf("D003")
    
    -- GENERIC ADF
    files.OD = hexf("5031")
    files.tokenInfo = hexf("5032")
    files.AODF = hexf("7001")
    files.PrivKD = hexf("7002")
    files.secretKD = hexf("7003")
    files.PubKD = hexf("7004")
    files.CDF = hexf("7005")
    files.dataDF = hexf("7006")
    -- files.CiaPINsComplexity = hexf("DC00")
    -- files.UPDATE_INFO = hexf("ABDE")
    files.PIN_POLICY = hexf("FFF0")
    files.PIN_POLICY_HISTORY = hexf("FFF1")
    -- files.tokenInfo_lastModified_offset = 70
    -- files.tokenInfo_lastModified_size = 14

    self.files = files

    self.capabilities = utility.clone_table(t.capabilities)
    self.MK = t.MK
    self.ida_hcard = CosmoXIASSmartCard.new(self.hcard)
    self.mechanisms = utility.clone_table(t.mechanisms)
    self.request_plugin_valid = w32.request_plugin_valid()
    
    self.puk_not_modifiable = false
    self.slow_card = false
    self.userPinInitialized = true
    self.cfg = cfg or utility.parse_cfg()
    
    self.cfg["fcpr"] = self.cfg["fcpr"] or self.cfg["idafcpr"]
    self.cfg["xproc"] = self.cfg["xproc"] or self.cfg["idaxproc"]
    
    self.cfg["dspinusegui"] = self.cfg["idadspinusegui"] or self.cfg["dspinusegui"]
    if self.cfg["dspinusegui"] then self.cfg["dspinusegui"]=string.lower(self.cfg["dspinusegui"])
    else self.cfg["dspinusegui"]='false' end
    
    self.cfg["usepinpadding"] = string.lower(self.cfg["idausepinpadding"] or self.cfg["usepinpadding"] or "false")
    
    self.cfg["hidecachedspincheck"] = self.cfg["idahidecachedspincheck"] or self.cfg["hidecachedspincheck"]
    if self.cfg["hidecachedspincheck"] then self.cfg["hidecachedspincheck"]=string.lower(self.cfg["hidecachedspincheck"])
    else self.cfg["hidecachedspincheck"]='true' end
    
    self.check_box_visible = 0
    if self.cfg["hidecachedspincheck"] == 'true' then
        self.check_box_visible = nil
    end
    
    if self.cfg["idamobile"] then
        self.cfg["mobile"] = self.cfg["idamobile"]
    end
    if self.cfg["mobile"] then self.cfg["mobile"]=string.lower(self.cfg["mobile"])
    else self.cfg["mobile"]='false' end
    
    self._mobile_enabled = self.cfg["mobile"] == "true"
    log.output('token-cosmox-ida token initialize(): _mobile_enabled:', self._mobile_enabled)
    
    if self.cfg["idaavoiduselastupdate"] then
        self.cfg["avoiduselastupdate"] = self.cfg["idaavoiduselastupdate"]
    end
    if self.cfg["avoiduselastupdate"] then self.cfg["avoiduselastupdate"]=string.lower(self.cfg["avoiduselastupdate"])
    else self.cfg["avoiduselastupdate"]='false' end
    
    
    if self.cfg["idaumcachepath"] then
        self.cfg["umcachepath"] = self.cfg["idaumcachepath"]
    end
    if self.cfg["umcachepath"] then
        self._umcachepath = self.cfg["umcachepath"]
        log.output('token-cosmox-ida token initialize(): using _umcachepath=', self._umcachepath)
    end

    
    if self.cfg["fcpr"] then
        self.cfg["fcpr"]=string.lower(self.cfg["fcpr"])
        self.use_cpr_mode = self.cfg["fcpr"] ~= "false"
        -- se non specificato non si attiva mai
    end
    
    if self.cfg["xproc"] then self.cfg["xproc"]=string.lower(self.cfg["xproc"])
    else self.cfg["xproc"]='true' end
    
    if self.cfg["idacaching"] then
        self.cfg["caching"] = self.cfg["idacaching"]
    end
    if self.cfg["caching"] then self.cfg["caching"]=string.lower(self.cfg["caching"])
    else self.cfg["caching"]='false' end
    

    if self.cfg["caching"] ~= "false" then
        log.output('token-cosmox-ida token initialize(): activating general caching...')

        log.output('token-cosmox-ida token initialize(): forcing avoiduselastupdate and fastread')
        self.cfg["avoiduselastupdate"] = "true"
        self.cfg["fastread"] = "true"
  
    end
    
    log.output('token-cosmox-ida token initialize(): use_cpr_mode:', self.use_cpr_mode)
    
    self._AvoidUseLastUpdate = self.cfg["avoiduselastupdate"] == "true"
    log.output('token-cosmox-ida token initialize(): using _AvoidUseLastUpdate=', self._AvoidUseLastUpdate)
    
    
    
    if os.getenv("IS_BIT4ID_AUTOIMPORTER") == "true" then
        self._clear_cache = true
        log.output('token-cosmox-ida token initialize(): IS_BIT4ID_AUTOIMPORTER is set, forcing _clear_cache=true')
    end
    
    
    local info = self:get_info() -- BES BUGFIX: FORCE detect of the card FS - raise error
    

    if self._cache_id == nil then
        self:flush_cache()
    end
end

function t.mt:begin_transaction()
    self.ida_hcard:begin_transaction()
end

function t.mt:end_transaction()
    self.ida_hcard:end_transaction()
end

function t.mt:_call_on_end_transaction()
    log.output('token-cosmox-ida:_call_on_end_transaction()...')
    if self.ida_hcard.on_end_transaction then
        self.ida_hcard:on_end_transaction()
    end
end

function t.mt:_call_on_begin_transaction()
    log.output('token-cosmox-ida:_call_on_begin_transaction()...')
    if self.ida_hcard.on_begin_transaction then
        self.ida_hcard:on_begin_transaction()
    end
end

function t.mt:finalize()
    log.output("token-cosmox-ida:finalize():", self.userType)
    utility.forget_token_changed(self, "cache")
end

function t.mt:_update_retry_counters()

    log.output("token-cosmox-ida:_update_retry_counters():")
    if (self.info) then
        pcall (function()
            self.info.flags = self.info.flags - CKF.USER_PIN_LOCKED
            self.info.flags = self.info.flags - CKF.USER_PIN_FINAL_TRY
            self.info.flags = self.info.flags - CKF.USER_PIN_COUNT_LOW
            self.info.flags = self.info.flags - CKF.SO_PIN_LOCKED
            self.info.flags = self.info.flags - CKF.SO_PIN_FINAL_TRY
            self.info.flags = self.info.flags - CKF.SO_PIN_COUNT_LOW
            self.ida_hcard:select_Generic()
            self.ida_hcard:select_MF()
            local pinRetry, pinRetryMax, pukRetry, pukRetryMax = self.ida_hcard:get_pin_puk_status()
            log.output("token-cosmox-ida:_update_retry_counters(): get_pin_puk_status, PIN cur/max", pinRetry, pinRetryMax, "PUK cur/max:", pukRetry, pukRetryMax);
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

function t.mt:_set_pin_flags_ok(setPIN_OK, setPUK_OK)


    log.output("token-cosmox-ida:_set_pin_flags_ok(): setPIN_OK", setPIN_OK)
    log.output("token-cosmox-ida:_set_pin_flags_ok(): setPUK_OK", setPUK_OK)
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

function t.mt:update_free_mem(info)
    log.output("token-cosmox-ida:update_free_mem():")
    if info then
            pcall(function()

            info.ulFreePublicMemory = self.ida_hcard:get_free_mem()
            info.ulFreePrivateMemory = self.info.ulFreePublicMemory
            log.output("token free space:", info.ulFreePublicMemory);
        end)
    end
end


function t.mt:send_cached_apdu(apdu, update_cache, force_refresh, use_sm)
    local val, err
    local name = "APDU_" .. hex.hexify(apdu)
    log.output(string.format("send_cached_apdu: apdu=%s, update_cache=%s, force_refresh=%s", hex.hexify(apdu), tostring(update_cache), tostring(force_refresh)) )
    local info = self.info
    if self:cache_enabled() and info and not force_refresh then
        log.output("send_cached_apdu: trying cache...")
        val = utility.cache_read(info.serialNumber, name, self._AvoidUseLastUpdate, self._umcachepath)
        log.output(string.format("send_cached_apdu: full cached value=%s", hex.hexify(val or "")) )
        if val then
            return val
        end
    end
    log.output("send_cached_apdu: trying sending to card...")
    val, err = self.ida_hcard:sm_transmit(apdu, use_sm)
    
    if val then
        log.output(string.format("send_cached_apdu: got fresh value=%s", hex.hexify(val)) )
        if update_cache and self:cache_enabled() then
            log.output("send_cached_apdu: updating cache")
            utility.cache_write(info.serialNumber, name, val, self._umcachepath)
        end
    else
        log.output("send_cached_apdu: sm_transmit error:", err )
    end
    return val, err
end


function t.mt:read_card_cache_dict()
    if self:cache_enabled() then
        log.output("token-cosmox-ida:read_card_cache_dict(): try reading card_cache...")
        local pcRes, theErrorT = pcall(function()
            local json_cache =  utility.cache_read(self.info.serialNumber, t.card_cache, self._AvoidUseLastUpdate, self._umcachepath)
            if json_cache then
                log.output("token-cosmox-ida:read_card_cache_dict(): json_cache:", json_cache)
                local card_cache = json.decode(json_cache)
                log.output("token-cosmox-ida:read_card_cache_dict(): restoring card_cache:", utility.repr(card_cache))
                
                if type(card_cache) == "table" then
                    log.output("token-cosmox-ida:read_card_cache_dict(): restoring card_cache...")
                    self.ida_hcard:set_cachable_dict(card_cache)
                end
            end
        end)
        if not pcRes then
            log.output("token-cosmox-ida:read_card_cache_dict(): error applying card_cache:", debug.traceback(theErrorT))
        end
    end
end


function t.mt:init_pin_policy(pinPolicy)
    log.output("init_pin_policy()")

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
    
    if minLen > 0 then
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
    self.pin_policy_value = pin_policy
    -- self.pinRetry = pinRetry
    -- if self.pinRetry == 0 then
        -- self.pinRetry = 3
    -- end 

end


function t.mt:check_pin_policy_bit4id(newPin, isPuk)
    log.output('check_pin_policy_bit4id()', newPin, isPuk)
    local curPinLen = string.len(newPin or "")
    
    if curPinLen > self.info.ulMaxPinLen then
        log.output('check_pin_policy_bit4id(): newPin too long')
        return CKR.PIN_LEN_RANGE
    end
    if curPinLen < self.info.ulMinPinLen then
        log.output('check_pin_policy_bit4id(): newPin too short')
        return CKR.PIN_LEN_RANGE
    end

    if isPuk then
        log.output('check_pin_policy_bit4id(): PUK: OK: no more checks')
        return CKR.OK
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
                log.output('check_pin_policy_bit4id(): newPin extended policy do not match!')
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
                log.output('check_pin_policy_bit4id(): newPin must contain at least 3 of: upper , lower , numeric , symbols');
                return CKR.PIN_INVALID
            end
        elseif self.complexityLevel == 2 then
            if not string.find(newPin, "[%d]") or not string.find(newPin, "[%a]") then
                log.output('check_pin_policy_bit4id(): newPin must contain alpha + numeric');
                return CKR.PIN_INVALID
            end
        elseif self.complexityLevel == 1 then
            -- at least alpha + numeric
            if string.find(newPin, "[^%d]") then
                log.output('check_pin_policy_bit4id(): newPin must contain only digits');
                return CKR.PIN_INVALID
            end           
        else
            -- any value is ok
        end
    end
    
    local historyList = self:manage_pin_history()
    
    if historyList and table.getn(historyList) > 0 then
        local hNewPin = self:hash_pin(newPin)
        log.output('check_pin_policy_bit4id(): pin history: looking for hNewPin:', hex.hexify(hNewPin));        
        for i=1,table.getn(historyList) do
            log.output('check_pin_policy_bit4id(): history entry:', i, hex.hexify(historyList[i]));
            if historyList[i] == hNewPin then
                log.output('check_pin_policy_bit4id(): pin value found in history');
                return CKR.PIN_INVALID
            end
        end
    end
    return CKR.OK
end

function t.mt:manage_pin_history(newHistoryList)
    log.output('manage_pin_history():', repr(newHistoryList))
    local valueHistoryFid
    local historyLen
    local historyValue
    local historyList
    local newHistory
    if self.pinHistory and self.pinHistory >0 then
        valueHistoryFid = self.files.PIN_POLICY_HISTORY
        historyLen = self.pinHistory
    end
    
    if valueHistoryFid then
        if newHistoryList then
            newHistory = table.concat(newHistoryList, "")
            newHistory = newHistory .. string.rep("\0", (historyLen * PIN_POLICY_HISTORY_HASH_LEN) - string.len(newHistory))
            newHistory = string.sub(newHistory, 1, historyLen * PIN_POLICY_HISTORY_HASH_LEN)
            log.output('manage_pin_history(): newHistory:',  hex.hexify(newHistory))
        end
        -- read/update value history
        local pcRes, theErrorT = pcall(function()
            log.output('manage_pin_history(): selecting file')
            self.ida_hcard:select_Generic()
            local fInfo = self.ida_hcard:select(valueHistoryFid)
            if newHistory then
                newHistory = string.sub(newHistory, 1, math.min(fInfo.size, string.len(newHistory)))
                log.output('manage_pin_history(): updating actual newHistory:',  hex.hexify(newHistory))
                self.ida_hcard:mupdate_binary(0, newHistory)
                log.output('manage_pin_history(): update done')
                historyValue = newHistory
            else
                log.output('manage_pin_history(): reading history')
                historyValue = self.ida_hcard:mread_binary(0, math.min(fInfo.size, historyLen * PIN_POLICY_HISTORY_HASH_LEN))
            end
        end)
        if not pcRes then
            log.output('manage_pin_history() error:', theErrorT)
        end
        if pcRes and historyValue then
            historyList = {}
            for i=1,string.len(historyValue),PIN_POLICY_HISTORY_HASH_LEN do
                table.insert(historyList, string.sub(historyValue, i, i-1+PIN_POLICY_HISTORY_HASH_LEN))
            end
        end
    end
    log.output('manage_pin_history(): historyList:', repr(historyList))
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

function t.mt:hash_pin(pin)
    local info = self:get_info()
    local hpin = md.pkcs5_pbkdf2(pin, info.serialNumber, PIN_POLICY_HISTORY_HASH_LEN, 1000)
    return hpin
end

function t.mt:update_pin_history(oldPin, newPin)
    log.output('update_pin_history(oldPin, newPin): ', oldPin, newPin);
    local historyList = self:manage_pin_history()
    if historyList then
        local hnewPin = self:hash_pin(newPin)
        local holdPin = self:hash_pin(oldPin)
        
        table_insert_unique(historyList, holdPin)
        table_insert_unique(historyList, hnewPin)
        self:manage_pin_history(historyList)
    end
end


function t.mt:create_object_pin_policy(pTemplate)

    if self.userType ~= CKU.SO then
        log.output('create_object_pin_policy(): user type not SO')
        return CKR.USER_TYPE_INVALID
    end
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local fid_main = self.files.PIN_POLICY
    local fid_pin = self.files.PIN_POLICY_HISTORY
    local all_fids = {fid_main, fid_pin}
    
    log.output('create_object_pin_policy(): erasing PIN policy')
    for i=1,table.getn(all_fids) do
        pcall(function()
            self.ida_hcard:select_Generic()
            self.ida_hcard:delete_file(all_fids[i], false, true)
        end)
    end
    
    if not pTemplate[CKA.VALUE] or string.sub(pTemplate[CKA.VALUE], 1, 5) == string.rep("\0", 5) then
        self.attributes[1] = nil
        return CKR.OK, 0
    end
    
    local attr = string.sub(pTemplate[CKA.VALUE], 1, 10)
    attr = attr .. string.rep("\0", 10- string.len(attr))
    log.output('create_object_pin_policy(): setting new pin policy:', hex.hexify(attr) )
    
    self.ida_hcard:select_Generic()
    
    self.ida_hcard:create_binary_file(fid_main, 
        string.len(attr), 
        true,
        CosmoXIASSmartCard.ID_SE_ALWAYS,
        CosmoXIASSmartCard.ID_SE_ALWAYS,
        CosmoXIASSmartCard.ID_SE_ALWAYS
    )
    
    
    self.ida_hcard:mupdate_binary(0, attr)
    
    self:init_pin_policy(attr)
    
    if self.pinHistory and self.pinHistory > 0 then
        local SE_ID = (self.ida_hcard.ID_SE_MAIN + CosmoXIASSmartCard.ID_SBC_PIN)
        self.ida_hcard:create_binary_file(fid_pin, 
            PIN_POLICY_HISTORY_HASH_LEN * self.pinHistory,
            true,
            SE_ID,
            SE_ID,
            CosmoXIASSmartCard.ID_SE_ALWAYS
        )
    else
        pcall(function()
            self.ida_hcard:select_Generic()
            self.ida_hcard:delete_file(fid_pin, false, true)
        end)
    end
    obj = {[CKA.CLASS]=eCK.ULONG(CKO_PIN_POLICY), [CKA.TOKEN]=eCK.BBOOL(true), [CKA.VALUE]=self.pin_policy_value}
    self.attributes[1] = obj
    return CKR.OK, 1
end


function t.mt:add_info()
    log.output("token-cosmox-ida:add_info()")
    local CSN = string.upper(self.ida_hcard:read_serial_number())
    
    local s = md.sha256()
    s:update(CSN .. self.MK)
    self._mk = s:final()
    
    log.output("token-cosmox-ida:add_info(): mk:", hex.hexify(self._mk))
    
    self.info.serialNumber = string.rep("0", 16 - string.len(CSN)) .. CSN
    self.info.label = "SecID " .. self.info.serialNumber
    

    self:check_clear_cache(false)

    self.ida_hcard:select_Generic()


    local pcRes, theErrorT = pcall(function()
        local cia_info = self.cia_info
        
        if not cia_info then
            local cia_infoD = self:read_cached_file(self.files.tokenInfo, 0, -1, true)
            cia_info = p15.parse_tokenInfo(cia_infoD)
        end 
        if cia_info.serialNumber and string.len(cia_info.serialNumber ) >= 16 and 
            not string.find(cia_info.serialNumber, "[^%x%u ]")
            then
            local doswitch = self.info.serialNumber ~= cia_info.serialNumber
            
            if doswitch then
                -- serialNumber = string.rep("0", 16 - string.len(serialNumber)) .. serialNumber
                local serialNumber = string.sub(cia_info.serialNumber, 1, 16)
                log.output ("token-cosmox-ida:add_info(): switch serialNumber to :", serialNumber)
                self.info.serialNumber = serialNumber
                self.info.label = "CosmoX " .. self.info.serialNumber
                
                log.output ("token-cosmox-ida:add_info(): re-check clear cache...")
                self:check_clear_cache(false)
                
                -- log.output ("token-cosmox-ida:add_info(): retry read card cache dict...")
                -- self:read_card_cache_dict()
            end
        end
        
        if cia_info.label then
            self.info.label = cia_info.label
            log.output ("token-cosmox-ida:add_info(): label set to:", cia_info.label)
        end
        
    end)
    if not pcRes then
        log.output("token-cosmox-ida:add_info(): error reading tokenInfo:", debug.traceback(theErrorT))
    end
    
    self:read_card_cache_dict()
    if self.ida_hcard.has_sscd == nil then
        log.output("token-cosmox-ida:add_info(): detecting SSCD DF...")
        local pcRes, theErrorT = pcall(function()
            self.ida_hcard:select_SSCD()
        end)
        self.ida_hcard:select_Generic()
    end
    log.output("token-cosmox-ida:add_info(): SSCD DF:", self.ida_hcard.has_sscd)

    self.info.has_sscd = self.ida_hcard.has_sscd


    local AOD = self:read_cached_file(self.files.AODF, 0, -1, true)
    
    log.output ("token-cosmox-ida:add_info(): p15.parseAuthObjects()...")
    local AODInfo = p15.parseAuthObjects(AOD)
    for i, v in AODInfo do
        -- log.output ("token-cosmox-ida:add_info(): dumping Auth Obj:", i)
        -- for x, y in v do
            -- log.output("token-cosmox-ida:add_info():\t", x, utility.repr(y))
        -- end
        
        if v and v.classAttributes and v.classAttributes.authId == self.authID_Card_PIN then
            log.output("token-cosmox-ida:add_info(): found main pin entry:", self.authID_Card_PIN)
            
            self.info.ulMinPinLen = (v.typeAttributes and v.typeAttributes.minLength) or self.info.ulMinPinLen
            log.output("token-cosmox-ida:add_info(): ulMinPinLen set to:", self.info.ulMinPinLen)
            self.info.ulMaxPinLen = (v.typeAttributes and (v.typeAttributes.maxLength  or typeAttributes.storedLength)) or self.info.ulMaxPinLen
            log.output("token-cosmox-ida:add_info(): ulMaxPinLen set to:", self.info.ulMaxPinLen)
        end
    end
    
    local pcRes, theErrorT = pcall(function()
        log.output('token-cosmox-ida:add_info(): reading bit4id Pin policy file...')
        local pin_policy_value = self:read_cached_file(self.files.PIN_POLICY, 0, -1, true)
        if pin_policy_value and string.len(pin_policy_value) >0 then
            self:init_pin_policy(pin_policy_value)
        end
    end)
    if not pcRes then
        log.output('token-cosmox-ida:add_info(): reading bit4id Pin policy file error:', theErrorT )
    end
    
    self:update_free_mem(self.info)
    self:_update_retry_counters() -- NOTE: Following command selects MF


end

function t.mt:check_pin_policy(newPin, isPuk)
    log.output('token-cosmox-ida:check_pin_policy()', newPin, isPuk)
    
    if self.complexityLevel then
        log.output('token-cosmox-ida:check_pin_policy(): bit4id pinpolicy enabled')
        return self:check_pin_policy_bit4id(newPin, isPuk)
    end
    
    return CKR.OK
end

function t.mt:get_info()
    if not self.info then
        log.output("token-cosmox-ida:get_info()")
        self.info = {
            label = 'ID-A',
            manufacturerID = 'IDEMIA',
            model = 'CosmoX ID-A',
            serialNumber = '0000000000000000',
            flags = CKF.RNG + CKF.LOGIN_REQUIRED +
                    CKF.USER_PIN_INITIALIZED + CKF.TOKEN_INITIALIZED,
            ulMaxSessionCount = CK.EFFECTIVELY_INFINITE,
            ulSessionCount = 0,
            ulMaxRwSessionCount = CK.EFFECTIVELY_INFINITE,
            ulRwSessionCount = CK.UNAVAILABLE_INFORMATION,
            ulMaxPinLen = 8,
            ulMinPinLen = 6,
            ulTotalPublicMemory = 144000,
            ulFreePublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulTotalPrivateMemory = 144000,
            ulFreePrivateMemory = CK.UNAVAILABLE_INFORMATION,
            hardwareVersion = { major=3, minor=0},
            firmwareVersion = { major=3, minor=0},
            utcTime = '0000000000000000',
            supportsPinpolicy=true,
        }
        

        self:add_info()
        if self.cfg["idadefaultlabel"] then
            self.info.label = self.cfg["idadefaultlabel"]
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
    log.output("token-cosmox-ida:verify_pin()", pin, userType, ispuk, contextual_obj)
    
    self.ida_hcard:auto_perform_mutual_authenticate()
    
    self:check_clear_cache(true)
    
    self.ida_hcard:select_Generic()
    self.ida_hcard:select_MF()
    local info = self:get_info()
    
    if info and self:cache_enabled() then
        local card_cache = self.ida_hcard:get_cachable_dict()
        
        if card_cache then
            local json_cache = json.encode(card_cache)
            log.output("token-cosmox-ida:verify_pin(): updating card_cache:", json_cache)
            utility.cache_write(info.serialNumber, t.card_cache, json_cache, self._umcachepath)
        end
    end
    
    
    self.ida_hcard:get_pin_puk_docp(true)
    

    result = self.ida_hcard:verify_pin_main(pin, ispuk) -- pin, ispuk
    log.output("verify_pin_main(): result=", result)
    if result == 0 then
        self.cached_main_pin = pin
        self.userType = userType
        
        -- if self.attributes == nil then
            -- self.attributes = self:get_objects()
        -- end
        self:_set_pin_flags_ok(not ispuk, ispuk)
        
        self.userConsent_pin_consumed = false
        return CKR.OK
    end
    
    self._schedule_update_retry_counters = true
    
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
    local newPinOrig = newPin
    local oldPinOrig = oldPin
    local ispuk = false
    if self.userType == CKU.SO then ispuk = true end
    local pcRes, result, theErrorT
    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-cosmox-ida:change_pin(): oldPin:', oldPin, 'newPin:', newPin)

    -- if newPin and (string.len(newPin) < info.ulMinPinLen or string.len(newPin) > info.ulMaxPinLen) then
        -- log.output('token-cosmox-ida:change_pin(): value not in range:', info.ulMinPinLen, info.ulMaxPinLen)
        -- return CKR.PIN_LEN_RANGE   
    -- end
    if ispuk and self.puk_not_modifiable then
        log.output('token-cosmox-ida:change_pin(): PUK not modifiable!')
        return CKR.PIN_LEN_RANGE
    end
    local rv
    log.output('token-cosmox-ida:change_pin(): change pin MAIN...')


    self._schedule_update_retry_counters = true
 
    self.ida_hcard:get_pin_puk_docp(true)

    if string.sub(newPin, 1, 5) == "****:" then
        log.output('token-cosmox-ida:change_pin(): override pin policy check')
        newPin = string.sub(newPin, 6, -1)
    else
        rv = self:check_pin_policy(newPin, ispuk)
        if rv ~= CKR.OK then
            log.output('token-cosmox-ida:change_pin(): newPin rejected');
            return rv
        end
    end
    
    


    if not ispuk then
        pcRes, theErrorT = pcall(function()
            self.ida_hcard:select_SSCD()
            result = self.ida_hcard:change_pin_ds(oldPin, newPin, ispuk) -- oldPin, newPin, ispuk
        end)
        if not pcRes then
            log.output('token-cosmox-ida:change_pin(): change_pin_ds() error:', debug.traceback(theErrorT) )
        end
        
        if pcRes and result == 0 then
            pcRes, theErrorT = pcall(function()
                self.ida_hcard:select_Generic()
                result = self.ida_hcard:change_pin_enc(oldPin, newPin) -- oldPin, newPin
            end)
            if not pcRes then
                log.output('token-cosmox-ida:change_pin(): change_pin_enc() error:', debug.traceback(theErrorT) )
            end
       end
    else
        pcRes, result = true, 0
    end
    
    if pcRes and result == 0 then
        pcRes, result = pcall(function() 
                return self.ida_hcard:change_pin_main(oldPin, newPin, ispuk) -- oldPin, newPin, ispuk
            end)
    end
    
    if result == 0 then
        self.cached_main_pin = newPin
        -- la carta potrebbe dimenticare lo stato di logged in quando si effettua una change pin
        -- pcRes, result = pcall(function()    
                -- return self.ida_hcard:verify_pin_main(newPin, ispuk)  -- pin, ispuk
            -- end)
            pcall(function()
                self:update_pin_history(oldPinOrig, newPinOrig)
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
    log.output('token-cosmox-ida:reset_pin(): newPin:', newPin)
    log.output('token-cosmox-ida:reset_pin(): reset pin MAIN...')
    if self.userType ~= CKU.SO then
        log.output('token-cosmox-ida:reset_pin(): user not SO!')
        return CKR.USER_TYPE_INVALID
    end
    
    local rv

    self._schedule_update_retry_counters = true
   
    
    self.ida_hcard:get_pin_puk_docp(true)

    if string.sub(newPin, 1, 5) == "****:" then
        log.output('token-cosmox-ida:reset_pin(): override pin policy check')
        newPin = string.sub(newPin, 6, -1)
    else
        rv = self:check_pin_policy(newPin)
        if rv ~= CKR.OK then
            log.output('token-cosmox-ida:reset_pin(): newPin rejected');
            return rv
        end
    end
    

    pcRes, theErrorT = pcall(function()
        self.ida_hcard:select_SSCD()
    end)
    if not pcRes then
        log.output('token-cosmox-ida:reset_pin(): error activating SSCD SM:', debug.traceback(theErrorT) )
        pcRes = true
        result = 0
    else
        pcRes, theErrorT = pcall(function()
            result = self.ida_hcard:reset_pin_ds(self.cached_main_pin, newPin) -- Puk, newPin
        end)
        if not pcRes then
            log.output('token-cosmox-ida:reset_pin(): reset_pin_ds() error:', debug.traceback(theErrorT) )
        end
    end
    if pcRes and result == 0 then
        self.ida_hcard:select_Generic()
        pcRes, result = pcall(function() 
                return self.ida_hcard:reset_pin_enc(self.cached_main_pin, newPin) -- Puk, newPin
            end)
        if not pcRes then
            log.output('token-cosmox-ida:reset_pin(): reset_pin_enc() error:', debug.traceback(result) )
        end
    end
    if pcRes and result == 0 then
        self.ida_hcard:select_Generic()
        pcRes, result = pcall(function() 
                return self.ida_hcard:reset_pin_main(self.cached_main_pin, newPin) -- Puk, newPin
            end)
        if not pcRes then
            log.output('token-cosmox-ida:reset_pin(): reset_pin_main() error:', debug.traceback(result) )
        end
        if pcRes and result == 0 then
            pcRes, result = pcall(function()
                return self.ida_hcard:verify_pin_main(newPin, false) -- pin, ispuk
            end)
            if not pcRes then
                log.output('token-cosmox-ida:reset_pin(): verify_pin_main() error:', debug.traceback(result) )
            end
        end
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

function t.mt:rsa_auto(pData, keyBytes, kid, backtraking, pss)
    -- if string.len(pData) == keyBytes then
        -- log.output('token-cosmox-ida:rsa_auto(): len of data to RSA is same as key len, trying to unpad...')
        -- local unpadded = rsa.pkcs1_unpad(pData)
        -- if unpadded then
            -- log.output('token-cosmox-ida:rsa_auto(): signing unpadded data:', hex.hexify(unpadded))
            -- pData = unpadded
        -- end
        -- log.output('token-cosmox-ida:rsa_auto(): len of data to RSA is same as key len, trying RSA RAW...')
        -- return self.ida_hcard:pso_dec(pData, kid, true, true) -- data, id, backtraking, raw mode
        
    -- else
        return self.ida_hcard:pso_internal_auth(
            pData,
            kid,
            backtraking,
            false, -- ecc
            pss
            )
    -- end

end


function t.mt:sign_buffer(hKey, pMechanism, pData, allocated_space)

    local rv, signature
    log.output(string.format('sign_buffer(): hKey=%x', hKey ) )
    log.output(string.format('sign_buffer(): pData=%s', pData and hex.hexify(pData) or "<null>" ) )
    log.output(string.format('sign_buffer(): allocated_space=%x', allocated_space or -1 ) )
    if pMechanism and pMechanism.mechanism then
        log.output(string.format('sign_buffer(): mechanism=%x', pMechanism.mechanism ) )
        log.output(string.format('sign_buffer(): parameter=%s', pMechanism.parameter and hex.hexify(pMechanism.parameter) or "<null>"))
    end
    
    if pMechanism and pMechanism.mechanism == CKM.ECDSA then
        log.output('sign_buffer(): CKM.ECDSA...')
        rv, signature = self:sign_buffer_ecc(hKey, pMechanism, pData, allocated_space)
    else
        log.output('sign_buffer(): RSA...')
        rv, signature = self:sign_buffer_rsa(hKey, pMechanism, pData, allocated_space)
    end
    
    if rv == CKR.OK and type(signature) == "string" and string.len(signature) > 0 then
        log.output("sign_buffer(): try calling token_log_mw_activity()...")
        local pcRes, theErrorT = pcall(function()
            utility.token_log_mw_activity(self, hKey, self.cfg, "sign")
        end)
        if not pcRes then
            log.output("sign_buffer(): token_log_mw_activity():", theErrorT)
        end
    end
    return rv, signature
end


function t.mt:sign_buffer_ecc(hKey, pMechanism, pData, allocated_space)
    
    log.output('token-cosmox-ida:sign_buffer_ecc():', hKey, pMechanism, hex.hexify(pData or ''), allocated_space)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('token-cosmox-ida:sign_buffer_ecc(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('token-cosmox-ida:sign_buffer_ecc(): ERROR: non private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    local curve = ecdhlib.get_curve_by_deroid(obj.parameters)
    
    if not curve then
        log.output('token-cosmox-ida:sign_buffer_ecc(): unsupported curve type!')
        return CKR.KEY_FUNCTION_NOT_PERMITTED
    end
    
    local keyBytes = curve.keysize * 2
    local pcRes, result
    log.output('sign_buffer_ecc(): using curve: ', curve.name)
    pData = ecdhlib.trunk_to_curve_order(curve, pData)
    
    if allocated_space==nil then
        log.output('token-cosmox-ida:sign_buffer_ecc(): returning signature length:', keyBytes)
        return CKR.OK, keyBytes
    end
    
    log.output('token-cosmox-ida:sign_buffer_ecc(): using ECDSA PSO_CDS mode on kid:', obj.kid)


    self.ida_hcard:auto_perform_mutual_authenticate(true) -- check/restore Generic SM session, checkOnActiveSMOnly
    
    if obj.aid == CosmoXIASSmartCard.SSCD_AID then
        log.output('token-cosmox-ida:sign_buffer_rsa(): verifying SSCD PIN..')
        local rv = self:try_verify_pin(obj.userConsent, self.ida_hcard.has_sscd and obj.userConsent)
        if rv ~= CKR.OK then
            log.output('token-cosmox-ida:try_verify_pin(): error:', rv)
            return rv
        end
    else
        self.ida_hcard:select_Generic()
    end
    pcRes, result = pcall(function()
                    return self.ida_hcard:pso_cds(
                        pData, 
                        obj.kid,
                        true, -- backtraking
                        true -- ECC
                        )
                    end )
    if pcRes then
        local r, s = ecdhlib.decode_der_ecdsa_signature(result, curve.keysize)
        
        return CKR.OK, r .. s
    else
        log.output('token-cosmox-ida:sign_buffer_ecc(1): error', debug.traceback(result))
    end
    if not pcRes and self.ida_hcard.last_sw == hex.hexf("6982") then
        log.output('token-cosmox-ida:sign_buffer_ecc(): restoring secure channel and verifying pin...')
        -- self.ida_hcard:perform_mutual_authenticate()

        log.output('token-cosmox-ida:sign_buffer_ecc(): verifying SSCD PIN..')
        local rv = self:try_verify_pin(obj.userConsent, self.ida_hcard.has_sscd and obj.userConsent)
        if rv ~= CKR.OK then
            log.output('token-cosmox-ida:try_verify_pin(): error:', rv)
            return rv
        end
        pcRes, result = pcall(function()
                        return self.ida_hcard:pso_cds(
                            pData, 
                            obj.kid,
                            true, -- backtraking
                            true -- ECC
                            )
                        end )
        if pcRes then
            log.output('token-cosmox-ida:sign_buffer_ecc(): AUTH: OK with kid:', obj.kid)
            
            local r, s = ecdhlib.decode_der_ecdsa_signature(result, curve.keysize)
            
            return CKR.OK, r .. s
        end
    end
    if not pcRes then
        log.output('token-cosmox-ida:sign_buffer_ecc(2): error', debug.traceback(result))
        return CKR.FUNCTION_FAILED
    end
    
    log.output('token-cosmox-ida:sign_buffer_ecc(): unexpected!')
    return CKR.FUNCTION_FAILED
    
end

function t.mt:sign_buffer_rsa(hKey, pMechanism, pData, allocated_space)
    
    log.output('token-cosmox-ida:sign_buffer_rsa():', hKey, pMechanism, hex.hexify(pData or ''), allocated_space)
    
    local is_pss = pMechanism.mechanism == CKM.RSA_PKCS_PSS and pMechanism.parameter_decoded
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('token-cosmox-ida:sign_buffer_rsa(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('token-cosmox-ida:sign_buffer_rsa(): ERROR: non private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    local pcRes, result

    log.output('token-cosmox-ida:sign_buffer_rsa(): keyBytes:', keyBytes)
    log.output('token-cosmox-ida:sign_buffer_rsa(): dataLen:', dataLen)
    if allocated_space==nil then
        log.output('token-cosmox-ida:sign_buffer_rsa(): returning signature length:', keyBytes)
        return CKR.OK, keyBytes
    end
    
    if obj.aid == CosmoXIASSmartCard.SSCD_AID then
        log.output('token-cosmox-ida:sign_buffer_rsa(): using RSA CDS  mode on kid:', obj.kid)
        log.output('token-cosmox-ida:sign_buffer_rsa(): creating SSCD secure channel...')
        
        if dataLen > (keyBytes * 0.40) then -- absolute minimum BT01 padding: 00 01 FF 00 ...
            log.output('token-cosmox-ida:sign_buffer_rsa(): specified data len invalid: ', dataLen)
            return CKR.DATA_LEN_RANGE
        end
        
        log.output('token-cosmox-ida:sign_buffer_rsa(): verifying SSCD PIN..')
        local rv = self:try_verify_pin(obj.userConsent, self.ida_hcard.has_sscd and obj.userConsent)
        if rv ~= CKR.OK then
            log.output('token-cosmox-ida:try_verify_pin(): error:', rv)
            return rv
        end
        -- if obj.userConsent and self.cached_main_pin then
            -- verify SSCD PIN
            -- self.ida_hcard:verify_pin_ds(self.cached_main_pin, false) -- pin, ispuk
        -- end
        
        log.output('token-cosmox-ida:sign_buffer_rsa(): selecting SSCD DF..')
        self.ida_hcard:select_SSCD()
        
        pcRes, result = pcall(function()
                        return self.ida_hcard:pso_cds(
                            pData,
                            obj.kid,
                            true, -- backtraking
                            false, -- ecc
                            is_pss
                            )
                        end )
        
        if pcRes then
            log.output('token-cosmox-ida:sign_buffer_rsa(): SSCD: OK with kid:', obj.kid)
            return CKR.OK, result
        end
  
    else
    
        log.output('token-cosmox-ida:sign_buffer_rsa(): using RSA INTERNAL AUTH/PSO_DEC RAW mode on kid:', obj.kid)

        if dataLen > keyBytes then
            -- nota: il padding pkcs1 richiede almeno 8 byte di oxFF prima dei dati da firmare
            log.output('token-cosmox-ida:sign_buffer_rsa(): specified data len invalid: ', dataLen)
            return CKR.DATA_LEN_RANGE
        end

        self.ida_hcard:auto_perform_mutual_authenticate(true) -- check/restore Generic SM session, checkOnActiveSMOnly
        
        -- if keyBytes > 256 and dataLen < keyBytes then
            -- pData = rsa.pkcs1_bt01_pad(pData, keyBytes)
            -- log.output('token-cosmox-ida:sign_buffer_rsa(): padded pData:', hex.hexify(pData or ''))
        -- end
        
        if obj.userConsent and self.userConsent_pin_consumed then
            log.output('token-cosmox-ida:sign_buffer_rsa(): verifying main PIN..')
            local rv = self:try_verify_pin(obj.userConsent, false)
            if rv ~= CKR.OK then
                log.output('token-cosmox-ida:try_verify_pin(): error:', rv)
                return rv
            end
            self.userConsent_pin_consumed = false
        end
            
        self.ida_hcard:select_Generic()
        pcRes, result = pcall(function()
                        return self:rsa_auto(
                            pData,
                            keyBytes,
                            obj.kid,
                            true, -- backtraking
                            is_pss
                            )
                        end )
        if pcRes then
            self.userConsent_pin_consumed = true
            return CKR.OK, result
        end

        
        if not pcRes and self.ida_hcard.last_sw == hex.hexf("6982") then
            log.output('token-cosmox-ida:sign_buffer_rsa(): restoring secure channel and verifying pin...')
            self.ida_hcard:perform_mutual_authenticate()
            self.ida_hcard:select_MF()
            -- if self.cached_main_pin then
                -- self.ida_hcard:verify_pin_main(self.cached_main_pin, false) -- pin, ispuk
            -- end
        
            log.output('token-cosmox-ida:sign_buffer_rsa(): verifying main PIN..')
            local rv = self:try_verify_pin(obj.userConsent, false)
            if rv ~= CKR.OK then
                log.output('token-cosmox-ida:try_verify_pin(): error:', rv)
                return rv
            end
            self.ida_hcard:select_Generic()

            pcRes, result = pcall(function()
                            return self:rsa_auto(
                                pData,
                                keyBytes,
                                obj.kid,
                                true, -- backtraking
                                is_pss
                                )
                            end )
            if pcRes then
                self.userConsent_pin_consumed = true
                log.output('token-cosmox-ida:sign_buffer_rsa(): AUTH: OK with kid:', obj.kid)
                return CKR.OK, result
            end
        end
        if not pcRes then
            log.output('token-cosmox-ida:sign_buffer_rsa(): error', debug.traceback(result))
            return CKR.FUNCTION_FAILED
        end
    end
    log.output('token-cosmox-ida:sign_buffer_rsa(): unexpected!')
    return CKR.FUNCTION_FAILED
end


function t.mt:decrypt_buffer(hKey, pMechanism, pData, allocated_space)

    log.output('token-cosmox-ida:decrypt_buffer(): ')
    if pMechanism.mechanism == CKM.AES_CBC or pMechanism.mechanism == CKM.AES_CBC_PAD then
        return self:decrypt_buffer_aes(hKey, pMechanism, pData, allocated_space)
    else
        return self:decrypt_buffer_rsa(hKey, pMechanism, pData, allocated_space)
    end
end


function t.mt:decrypt_buffer_rsa(hKey, pMechanism, pData, allocated_space)
    log.output('token-cosmox-ida:decrypt_buffer_rsa(): ')
    local pDataDecrypted, pcRes, result
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('token-cosmox-ida:decrypt_buffer_rsa(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('token-cosmox-ida:decrypt_buffer_rsa(): ERROR: not a private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end

    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    if dataLen ~= keyBytes then
        log.output('token-cosmox-ida:decrypt_buffer_rsa(): specified data len invalid: ', dataLen, ', expected:', keyBytes)
        return CKR.ENCRYPTED_DATA_LEN_RANGE
    end
    
    if obj.userConsent then
        log.output('token-cosmox-ida:decrypt_buffer_rsa(): decrypt not allowed with userConsent kid:', obj.kid)
        return CKR.KEY_FUNCTION_NOT_PERMITTED
    else
        local raw = pMechanism.mechanism ~= CKM.RSA_PKCS
        
        self.ida_hcard:auto_perform_mutual_authenticate(true) -- check/restore Generic SM session, checkOnActiveSMOnly
        self.ida_hcard:select_Generic()
        pcRes, result = pcall(function()
                        pDataDecrypted = self.ida_hcard:pso_dec(pData, obj.kid, true, raw) -- data, id, backtraking
                        log.output('decrypt_buffer_rsa(1): decrypt OK with kid:', obj.kid)
                        end )
        if pcRes then
            return CKR.OK, pDataDecrypted
        end
        
        if not pcRes and self.ida_hcard.last_sw == hex.hexf("6982") then
            log.output('token-cosmox-ida:decrypt_buffer_rsa(): restoring secure channel and verifying pin...')
            self.ida_hcard:perform_mutual_authenticate()
            self.ida_hcard:select_MF()
            if self.cached_main_pin then
                log.output('token-cosmox-ida:decrypt_buffer_rsa(): verify_pin_main() with:', self.cached_main_pin, self.userType)
                self.ida_hcard:verify_pin_main(self.cached_main_pin, false) -- pin, ispuk
            end
            self.ida_hcard:select_Generic()

            pcRes, result = pcall(function()
                            pDataDecrypted = self.ida_hcard:pso_dec(pData, obj.kid, true) -- data, id, backtraking
                            log.output('token-cosmox-ida:decrypt_buffer_rsa(2): decrypt OK with kid:', obj.kid)
                            end )
            if pcRes then
                return CKR.OK, pDataDecrypted
            end
        end
        if not pcRes then
            log.output('token-cosmox-ida:decrypt_buffer_rsa(): error', debug.traceback(result))
            return CKR.FUNCTION_FAILED
        end
        
        pcall(function()
            log.output('token-cosmox-ida:decrypt_buffer_rsa(): verify_pin_main() with:', self.cached_main_pin, self.userType)
            self.ida_hcard:select_MF()
            if self.cached_main_pin and self.userType == CKU.USER then
                self.ida_hcard:verify_pin_main(self.cached_main_pin, false) -- pin, ispuk
            end
        end)
        self.ida_hcard:select_Generic()
        pDataDecrypted = self.ida_hcard:pso_dec(pData, obj.kid, true) -- data, id, backtraking
        log.output('token-cosmox-ida:decrypt_buffer_rsa(): decrypt OK with kid:', obj.kid)
        return CKR.OK, pDataDecrypted
    end
    
    log.output('token-cosmox-ida:decrypt_buffer_rsa(): unexpected!')
    return CKR.FUNCTION_FAILED
end


function t.mt:encrypt_buffer(hKey, pMechanism, pData, allocated_space)
    return self:encrypt_buffer_aes(hKey, pMechanism, pData, allocated_space)
end

function t.mt:encrypt_buffer_aes(hKey, pMechanism, pData, allocated_space)
    log.output(string.format('token-cosmox-ida:encrypt_buffer_aes(): hKey=%x', hKey ) )
    log.output(string.format('token-cosmox-ida:encrypt_buffer_aes(): pData=%s', pData and hex.hexify(pData) or "<null>" ) )
    log.output(string.format('token-cosmox-ida:encrypt_buffer_aes(): allocated_space=%x', allocated_space or -1 ) )
    if pMechanism and pMechanism.mechanism then
        log.output(string.format('token-cosmox-ida:encrypt_buffer_aes(): mechanism=%x', pMechanism.mechanism ) )
        log.output(string.format('token-cosmox-ida:encrypt_buffer_aes(): parameter=%s', pMechanism.parameter and hex.hexify(pMechanism.parameter) or "<null>"))
    end
    log.output('token-cosmox-ida:encrypt_buffer_aes(): pData=', pData and hex.hexify(pData ) or "<null>")
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('token-cosmox-ida:encrypt_buffer_aes(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.SECRET_KEY) then
        log.output('token-cosmox-ida:encrypt_buffer_aes(): ERROR: not SECRET_KEY object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    if obj[CKA.KEY_TYPE] ~= eCK.ULONG(CKK.AES) then
        log.output('token-cosmox-ida:encrypt_buffer_aes(): ERROR: not a AES key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end

    if not pMechanism or (pMechanism.mechanism ~= CKM.AES_CBC and pMechanism.mechanism ~= CKM.AES_CBC_PAD) then
        log.output('token-cosmox-ida:encrypt_buffer_aes(): MECHANISM_INVALID:', pMechanism and pMechanism.mechanism )
        return CKR.MECHANISM_INVALID
    end

    if allocated_space==nil then
        local enc_len = math.floor((string.len(pData) + (aes.BLOCK_LEN*2) -1) / aes.BLOCK_LEN) * aes.BLOCK_LEN
        log.output('token-cosmox-ida:encrypt_buffer_aes(): returning (guessed) encrypted data length:', enc_len)
        return CKR.OK, enc_len
    end
    
    local pDataToEnc = pData
    
    if pMechanism.mechanism  == CKM.AES_CBC_PAD then
        pDataToEnc = aes.pkcs5_padding(aes.BLOCK_LEN, pData)
    end
    local iv = pMechanism.parameter and string.sub(pMechanism.parameter, 1, aes.BLOCK_LEN)
    
    if iv and string.len(iv) < aes.BLOCK_LEN then
        log.output('token-cosmox-ida:encrypt_buffer_aes(): invalid IV specified, ignoring...')
        iv = nil
    end
    pcall(function()
        log.output('token-cosmox-ida:encrypt_buffer_aes(): verify_pin_main() with:', self.cached_main_pin, self.userType)
        self.ida_hcard:select_MF()
        if self.cached_main_pin and self.userType == CKU.USER then
            self.ida_hcard:verify_pin_main(self.cached_main_pin, false) -- pin, ispuk
        end
    end)
    -- self.ida_hcard:get_free_mem()
    
    local result, iv = aes.AES_CBC2(obj.value, pDataToEnc, true, iv)

    log.output('token-cosmox-ida:encrypt_buffer_aes(): result:', hex.hexify(result or ""))
    log.output('token-cosmox-ida:encrypt_buffer_aes(): iv:', hex.hexify(iv or ""))

    collectgarbage()
    return CKR.OK, result, iv
end



function t.mt:decrypt_buffer_aes(hKey, pMechanism, pEncryptedData, allocated_space)
    log.output(string.format('token-cosmox-ida:decrypt_buffer_aes(): hKey=%x', hKey ) )
    log.output(string.format('token-cosmox-ida:decrypt_buffer_aes(): pEncryptedData=%s', pEncryptedData and hex.hexify(pEncryptedData) or "<null>" ) )
    log.output(string.format('token-cosmox-ida:decrypt_buffer_aes(): allocated_space=%x', allocated_space or -1 ) )
    if pMechanism and pMechanism.mechanism then
        log.output(string.format('token-cosmox-ida:decrypt_buffer_aes(): mechanism=%x', pMechanism.mechanism ) )
        log.output(string.format('token-cosmox-ida:decrypt_buffer_aes(): parameter=%s', pMechanism.parameter and hex.hexify(pMechanism.parameter) or "<null>"))
    end
    log.output('token-cosmox-ida:decrypt_buffer_aes(): pEncryptedData=', pEncryptedData and hex.hexify(pEncryptedData ) or "<null>")
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('token-cosmox-ida:decrypt_buffer_aes(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.SECRET_KEY) then
        log.output('token-cosmox-ida:decrypt_buffer_aes(): ERROR: not SECRET_KEY object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    if obj[CKA.KEY_TYPE] ~= eCK.ULONG(CKK.AES) then
        log.output('token-cosmox-ida:decrypt_buffer_aes(): ERROR: not a AES key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    

    if not pMechanism or (pMechanism.mechanism ~= CKM.AES_CBC and pMechanism.mechanism ~= CKM.AES_CBC_PAD) then
        log.output('token-cosmox-ida:decrypt_buffer_aes(): MECHANISM_INVALID:', pMechanism and pMechanism.mechanism )
        return CKR.MECHANISM_INVALID
    end

    if allocated_space==nil then
        local enc_len = math.floor((string.len(pEncryptedData) + (aes.BLOCK_LEN*2) -1) / aes.BLOCK_LEN) * aes.BLOCK_LEN
        log.output('token-cosmox-ida:decrypt_buffer_aes(): returning (guessed) encrypted data length:', enc_len)
        return CKR.OK, enc_len
    end
    
    pcall(function()
        log.output('token-cosmox-ida:decrypt_buffer_aes(): verify_pin_main() with:', self.cached_main_pin, self.userType)
        self.ida_hcard:select_MF()
        if self.cached_main_pin and self.userType == CKU.USER then
            self.ida_hcard:verify_pin_main(self.cached_main_pin, false) -- pin, ispuk
        end
    end)
    -- self.ida_hcard:get_free_mem()
    
    local iv = pMechanism.parameter and string.sub(pMechanism.parameter, 1, aes.BLOCK_LEN)
    
    if iv and string.len(iv) < aes.BLOCK_LEN then
        log.output('token-cosmox-ida:decrypt_buffer_aes(): invalid IV specified, ignoring...')
        iv = nil
    end
    
    local pDataUnpadded, iv = aes.AES_CBC2(obj.value, pEncryptedData, false, iv)
    
    log.output('token-cosmox-ida:decrypt_buffer_aes(): pDataUnpadded:', hex.hexify(pDataUnpadded or ""))
    log.output('token-cosmox-ida:encrypt_buffer_aes(): iv:', hex.hexify(iv or ""))
    
    if pMechanism.mechanism  == CKM.AES_CBC_PAD then
        log.output('token-cosmox-ida:decrypt_buffer_aes(): unpadding:', hex.hexify(pDataUnpadded or ''))
        pDataUnpadded = aes.pkcs5_unpad(pDataUnpadded)
        log.output('token-cosmox-ida:decrypt_buffer_aes(): pDataUnpadded unpadded:', hex.hexify(pDataUnpadded or ""))
    end

    collectgarbage()
    return CKR.OK, pDataUnpadded, iv
end



-- se search_state.lastobj==nil si richiede l'handle del primo oggetto che risponda
-- al template. Altrimenti restituisce il primo oggetto che sia
-- compatibile con il template e abbia handle>search_state.lastobj.
-- quando non ci sono pi