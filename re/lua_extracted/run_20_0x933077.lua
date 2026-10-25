 PIN OR Bio, 0x05 - PIN AND Bio
    -- maxAttempts INTEGER (0..255),
    -- maxUnblock INTEGER (0..255),
    -- complexity CiaPINComplexity OPTIONAL // valid only if type is regular PIN
-- }
-- CiaBioPINInfo::= SEQUENCE { imageQuality INTEGER (0..255), // [0..100]
    -- enrollmentPurpose INTEGER,
    -- maxBioFingers INTEGER (0..255),
    -- defaultFinger INTEGER (0..255) OPTIONAL
-- }
-- CiaDSPINInfo::= SEQUENCE {
    -- max1024DSKeys [0] INTEGER (0..255),
    -- max2048DSKeys [1] INTEGER (0..255),
    -- dsPinInfo [2] CiaGeneralPINInfo,
    -- dsPukInfo [3] CiaGeneralPINInfo,
    -- syncOption [4] INTEGER (0..255), // 0 - unsynchronized User PIN and DS PIN, 1 - synchronized
    -- verificationPolicy [5] INTEGER (0..255), // 0 - non-cached, 1 - cached but prompted, 2 -cached
    -- activationPIN [6] OCTET STRING SIZE (0..16) OPTIONAL,
    -- deactivationPIN [7] OCTET STRING SIZE (0..16) OPTIONAL,
    -- DPPIN [8] OCTET STRING SIZE (0..16) OPTIONAL,
    -- DSPUK [9] OCTET STRING SIZE (0..16) OPTIONAL,
    -- adminPIN [10] OCTET STRING SIZE (0..16) OPTIONAL,
    -- adminPINPerso [11] OCTET STRING SIZE (0..16) OPTIONAL
-- }


function t.parse_CiaPINsComplexityStruct(data)

    local CiaPINsComplexityStruct = {}
    local s1 = der.parse(data)
    if s1 and s1[1] and s1[1].tag == der.SEQUENCE then
        local s2 = der.parse(s1[1].value)
        local i = 1
        log.output('token-nxp-chipdoc:parse_CiaPINsComplexityStruct(): parsing:', util.repr(s2))
        
        if not s2[i] or s2[i].tag ~= der.CONTEXT_SPECIFIC(0) then
            log.output('token-nxp-chipdoc:parse_CiaPINsComplexityStruct(): invalid field allowCardWipe')
            return CiaPINsComplexityStruct
        end
        -- log.output('token-nxp-chipdoc:parse_CiaPINsComplexityStruct(): field allowCardWipe')
        CiaPINsComplexityStruct.allowCardWipe = tonumber(hex.hexify(s2[i].value), 16)
        i = i+1
        
        if s2[i] and s2[i].tag == der.CONTEXT_SPECIFIC(1) then
            -- log.output('token-nxp-chipdoc:parse_CiaPINsComplexityStruct(): field eccBasedSM')
            CiaPINsComplexityStruct.eccBasedSM = s2[i].value=="\255"
            i = i+1
        end
        
        if s2[i] and s2[i].tag == der.CONTEXT_SPECIFIC(2) then
            -- log.output('token-nxp-chipdoc:parse_CiaPINsComplexityStruct(): field pkcsDirSize')
            CiaPINsComplexityStruct.pkcsDirSize = tonumber(hex.hexify(s2[i].value), 16)
            i = i+1
        end
        
        if s2[i] and s2[i].tag == der.CONTEXT(4) then
            -- log.output('token-nxp-chipdoc:parse_CiaPINsComplexityStruct(): field userPinInfo')
            CiaPINsComplexityStruct.userPinInfo = t.parse_CiaUserPINInfo(der.build(der.SEQUENCE, s2[i].value))
            i = i+1
        end
        
        if s2[i] and s2[i].tag == der.CONTEXT(5) then
            -- log.output('token-nxp-chipdoc:parse_CiaPINsComplexityStruct(): field adminInfo')
            CiaPINsComplexityStruct.adminInfo = t.parse_CiaGeneralPINInfo(der.build(der.SEQUENCE, s2[i].value))
            i = i+1
        end
        
        if s2[i] and s2[i].tag == der.CONTEXT(6) then
            -- log.output('token-nxp-chipdoc:parse_CiaPINsComplexityStruct(): field bioPinInfo')
            CiaPINsComplexityStruct.bioPinInfo = s2[i].value
            i = i+1
        end
        
        if s2[i] and s2[i].tag == der.CONTEXT(7) then
            -- log.output('token-nxp-chipdoc:parse_CiaPINsComplexityStruct(): field bioInfo')
            CiaPINsComplexityStruct.bioInfo = s2[i].value
            i = i+1
        end
        
        if s2[i] and s2[i].tag == der.CONTEXT(8) then
            -- log.output('token-nxp-chipdoc:parse_CiaPINsComplexityStruct(): field dsInfo')
            CiaPINsComplexityStruct.dsInfo = t.parse_CiaDSPINInfo(der.build(der.SEQUENCE, s2[i].value))
            i = i+1
        end
        
        
    end
    
    return CiaPINsComplexityStruct
end


function t.parse_CiaUserPINInfo(data)
    local int_fields = {
        "type",
        "maxAttempts",
        "maxUnblock",
        "mustChange",
        "mustChangeAfterUnlock",
        "deltaInSeconds",
        "deltaInDays",
        "pinAlways",
    }

    local CiaUserPINInfo = {}
    local s1 = der.parse(data)
    if s1 and s1[1] and s1[1].tag == der.SEQUENCE then
        local s2 = der.parse(s1[1].value)
        local i = 1
        log.output('token-nxp-chipdoc:parse_CiaUserPINInfo(): parsing:', util.repr(s2))
        
        for i=1,table.getn(int_fields) do
        
            if s2[i].tag ~= der.INTEGER then
                log.output('token-nxp-chipdoc:parse_CiaUserPINInfo(): invalid field type')
                return CiaUserPINInfo
            end
            -- log.output('token-nxp-chipdoc:parse_CiaUserPINInfo(): field:', int_fields[i])
            CiaUserPINInfo[int_fields[i]] = tonumber(hex.hexify(s2[i].value), 16)
        end
        
        if s2[9] and s2[9].tag == der.SEQUENCE then
            -- log.output('token-nxp-chipdoc:parse_CiaUserPINInfo(): field CiaPINComplexity')
            CiaUserPINInfo.complexity = t.parse_CiaPINComplexity(der.build(der.SEQUENCE, s2[9].value))
        end        
    end
    return CiaUserPINInfo
end


function t.parse_CiaGeneralPINInfo(data)
    local int_fields = {
        "type",
        "maxAttempts",
        "maxUnblock",
    }

    local CiaGeneralPINInfo = {}
    local s1 = der.parse(data)
    if s1 and s1[1] and s1[1].tag == der.SEQUENCE then
        local s2 = der.parse(s1[1].value)
        local i = 1
        log.output('token-nxp-chipdoc:parse_CiaGeneralPINInfo(): parsing:', util.repr(s2))
        
        for i=1,table.getn(int_fields) do
        
            if s2[i].tag ~= der.INTEGER then
                log.output('token-nxp-chipdoc:parse_CiaGeneralPINInfo(): invalid field type')
                return CiaGeneralPINInfo
            end
            -- log.output('token-nxp-chipdoc:parse_CiaGeneralPINInfo(): field:', int_fields[i])
            CiaGeneralPINInfo[int_fields[i]] = tonumber(hex.hexify(s2[i].value), 16)
        end
        
        if s2[4] and s2[4].tag == der.SEQUENCE then
            CiaGeneralPINInfo.complexity = t.parse_CiaPINComplexity(der.build(der.SEQUENCE, s2[4].value))
        end        
    end
    return CiaGeneralPINInfo
end

function t.parse_CiaPINComplexity(data)
    local int_fields = {
        "maxChars",
        "minChars",
        "minNum",
        "minAlphaNumeric",
        "minNonAlphaNumeric",
        "minLower",
        "minUpper",
        "minAlphaBetic",
        "maxOccurrence",
        "maxSequence",
        "historyCount",
    }
    local CiaPINComplexity = {}
    local s1 = der.parse(data)
    if s1 and s1[1] and s1[1].tag == der.SEQUENCE then
        local s2 = der.parse(s1[1].value)
        local i
        log.output('token-nxp-chipdoc:parse_CiaPINComplexity(): parsing:', util.repr(s2))
        
        for i=1,table.getn(int_fields) do
        
            if s2[i].tag ~= der.INTEGER then
                log.output('token-nxp-chipdoc:parse_CiaPINComplexity(): invalid field type')
                return CiaPINComplexity
            end
            -- log.output('token-nxp-chipdoc:parse_CiaPINComplexity(): field:', int_fields[i])
            CiaPINComplexity[int_fields[i]] = tonumber(hex.hexify(s2[i].value), 16)
        end  
    end
    return CiaPINComplexity
end



function t.parse_CiaDSPINInfo(data)
    local int_fields = {
        "max1024DSKeys",
        "max2048DSKeys",
    }
    local int_fields1 = {
        "syncOption",
        "verificationPolicy",
    }
    -- log.output = print
    local CiaDSPINInfo = {}
    local s1 = der.parse(data)
    if s1 and s1[1] and s1[1].tag == der.SEQUENCE then
        local s2 = der.parse(s1[1].value)
        local index=1
        log.output('token-nxp-chipdoc:parse_CiaDSPINInfo(): parsing:', util.repr(s2))
        
        for i=index,table.getn(int_fields) do
            -- log.output('token-nxp-chipdoc:parse_CiaDSPINInfo(): parsing field:', int_fields[i], util.repr(s2[i]))
            if not s2[i] or s2[i].tag ~= der.CONTEXT_SPECIFIC(i-1) then
                log.output('token-nxp-chipdoc:parse_CiaDSPINInfo(): invalid field type:', s2[i] and s2[i].tag, int_fields[i])
                return CiaDSPINInfo
            end
            -- log.output('token-nxp-chipdoc:parse_CiaDSPINInfo(): field:', int_fields[i])
            CiaDSPINInfo[int_fields[i]] = tonumber(hex.hexify(s2[i].value), 16)
        end
        
        index=3
        if not s2[index] or s2[index].tag ~= der.CONTEXT(index-1) then
            log.output('token-nxp-chipdoc:parse_CiaDSPINInfo(): invalid field dsPinInfo:', s2[index] and s2[index].tag )
            return CiaDSPINInfo
        end
        CiaDSPINInfo.dsPinInfo = t.parse_CiaGeneralPINInfo(der.build(der.SEQUENCE, s2[index].value))

        index=4
        if not s2[index] or s2[index].tag ~= der.CONTEXT(index-1) then
            log.output('token-nxp-chipdoc:parse_CiaDSPINInfo(): invalid field dsPukInfo:', s2[index] and s2[index].tag)
            return CiaDSPINInfo
        end
        CiaDSPINInfo.dsPukInfo = t.parse_CiaGeneralPINInfo(der.build(der.SEQUENCE, s2[index].value))
        
        index=5

        for i=index,index+table.getn(int_fields1)-1 do
            -- log.output('token-nxp-chipdoc:parse_CiaDSPINInfo(): parsing field:', int_fields1[1+i-index], util.repr(s2[i]))
            if not s2[i] or s2[i].tag ~= der.CONTEXT_SPECIFIC(i-1) then
                log.output('token-nxp-chipdoc:parse_CiaDSPINInfo(): invalid field type:', s2[i] and s2[i].tag, int_fields1[1+i-index])
                return CiaDSPINInfo
            end
            -- log.output('token-nxp-chipdoc:parse_CiaDSPINInfo(): field:', int_fields1[i])
            CiaDSPINInfo[int_fields1[1+i-index]] = tonumber(hex.hexify(s2[i].value), 16)
        end
    end
    return CiaDSPINInfo
end

-- local v = hex.hexf("3081E1800100810100820100A43E02010102010A020100020100020100020480000000020100020100302102010A020104020100020100020100020100020100020100020110020110020100A52C020101020103020100302102010A020104020100020100020100020100020100020100020110020110020100A868800100810104A22C02010102010A0201003021020110020104020100020100020100020100020100020100020110020110020100A32C0201010201030201043021020110020104020100020100020100020100020100020100020110020110020100840100850100")
-- local p = t.parse_CiaPINsComplexityStruct(v)
-- for i, x in p do
    -- print(i, repr(x))
-- end

function t.mt:initialize(cfg)
    log.output('token-nxp-chipdoc:initialize():')
    local files = {}
    
    self.authID_Card_PIN = 'Card PIN'
    self.authID_Card_PUK = 'Card PUK'
    
    self.authID_Sig_PIN = 'Sig PIN'
    self.authID_Sig_PUK = 'Sig PUK'
    
    
    self.DF_DS = hex.hexf("DF01")
    
    files.SN = hexf("D003")
    
    -- GENERIC ADF
    files.OD = hexf("5031")
    files.PrivKD = hexf("7002")
    files.secretKD = hexf("7003")
    files.PubKD = hexf("7004")
    files.CDF = hexf("7005")
    files.dataDF = hexf("7006")
    files.AODF = hexf("7001")
    files.CiaPINsComplexity = hexf("DC00")
    files.tokenInfo = hexf("5032") -- ?
    files.UPDATE_INFO = hexf("ABDE")
    files.PIN_POLICY = hexf("FFF0")
    files.PIN_POLICY_HISTORY = hexf("FFF1")
    files.tokenInfo_sfi = tonumber("12", 16)
    files.tokenInfo_lastModified_offset = 70
    files.tokenInfo_lastModified_size = 14

    self.files = files

    self.capabilities = utility.clone_table(t.capabilities)
    self.nxp_hcard = NXPIASSmartCard.new(self.hcard)
    self.mechanisms = utility.clone_table(t.mechanisms)
    self.request_plugin_valid = w32.request_plugin_valid()
    
    self.puk_not_modifiable = false
    self.slow_card = false
    self.userPinInitialized = true
    self.cfg = cfg or utility.parse_cfg()

    -- local select_aid_default = hex.hexf("00a4040c0bf0496173456363526f6f74")
    -- local self_parent = self
    -- self.nxp_hcard.on_transmit = function(self, apdu)
        -- if not self_parent._applet_selected then
            -- if not self_parent._mobile_enabled then
                -- log.output("nxp_hcard.on_transmit:(re)selecting CD applet...")
                -- local recv, sw
                -- self.card:transmit(select_aid_default)
            -- end
            -- self_parent._applet_selected = true
        -- end
    -- end

    -- self.nxp_hcard.on_begin_transaction = function(self)
        -- log.output("nxp_hcard:on_begin_transaction():")
        -- self_parent._applet_selected = false
    -- end
    
    
    self.cfg["fcpr"] = self.cfg["fcpr"] or self.cfg["ncdfcpr"]
    self.cfg["xproc"] = self.cfg["xproc"] or self.cfg["ncdxproc"]
    
    self.cfg["dspinusegui"] = self.cfg["ncddspinusegui"] or self.cfg["dspinusegui"]
    if self.cfg["dspinusegui"] then self.cfg["dspinusegui"]=string.lower(self.cfg["dspinusegui"])
    else self.cfg["dspinusegui"]='false' end
    
    self.cfg["usepinpadding"] = string.lower(self.cfg["ncdusepinpadding"] or self.cfg["usepinpadding"] or "false")
    self.cfg["pinpad"] = string.lower(self.cfg["ncdpinpad"] or self.cfg["pinpad"] or "false")
    
    self.cfg["hidecachedspincheck"] = self.cfg["ncdhidecachedspincheck"] or self.cfg["hidecachedspincheck"]
    if self.cfg["hidecachedspincheck"] then self.cfg["hidecachedspincheck"]=string.lower(self.cfg["hidecachedspincheck"])
    else self.cfg["hidecachedspincheck"]='true' end
    
    self.check_box_visible = 0
    if self.cfg["hidecachedspincheck"] == 'true' then
        self.check_box_visible = nil
    end
    
    self._cfg_use_pin_padding = false

    if self.cfg["usepinpadding"] == "true" then
        self._cfg_use_pin_padding = true
    end
    
    if self.cfg["pinpad"] == "true" then
        self._cfg_use_pinpad = true
        self._cfg_use_pin_padding = true
        
        if pcsc.pinpad_ctl_ex and pcsc.pinpad_reader(self.reader_name, self.nxp_hcard.card) then
            log.output('nxp-chipdoc token initialize(): PINPAD: current HW is a supported pinpad reader, setting self._pinpad_hw_reader = true ')
            self._pinpad_hw_reader = true
        end
    end
    
    log.output('nxp-chipdoc token initialize(): _cfg_use_pin_padding:', _cfg_use_pin_padding)
    
    if self.cfg["ncdmobile"] then
        self.cfg["mobile"] = self.cfg["ncdmobile"]
    end
    if self.cfg["mobile"] then self.cfg["mobile"]=string.lower(self.cfg["mobile"])
    else self.cfg["mobile"]='false' end
    
    self._mobile_enabled = self.cfg["mobile"] == "true"
    log.output('nxp-chipdoc token initialize(): _mobile_enabled:', self._mobile_enabled)
    
    if self.cfg["ncdavoiduselastupdate"] then
        self.cfg["avoiduselastupdate"] = self.cfg["ncdavoiduselastupdate"]
    end
    if self.cfg["avoiduselastupdate"] then self.cfg["avoiduselastupdate"]=string.lower(self.cfg["avoiduselastupdate"])
    else self.cfg["avoiduselastupdate"]='false' end
    
    
    if self.cfg["ncdumcachepath"] then
        self.cfg["umcachepath"] = self.cfg["ncdumcachepath"]
    end
    if self.cfg["umcachepath"] then
        self._umcachepath = self.cfg["umcachepath"]
        log.output('nxp-chipdoc token initialize(): using _umcachepath=', self._umcachepath)
    end

    
    if self.cfg["fcpr"] then
        self.cfg["fcpr"]=string.lower(self.cfg["fcpr"])
        self.use_cpr_mode = self.cfg["fcpr"] ~= "false"
        -- se non specificato non si attiva mai
    end
    
    if self.cfg["xproc"] then self.cfg["xproc"]=string.lower(self.cfg["xproc"])
    else self.cfg["xproc"]='true' end
    
    if self.cfg["ncdcaching"] then
        self.cfg["caching"] = self.cfg["ncdcaching"]
    end
    if self.cfg["caching"] then self.cfg["caching"]=string.lower(self.cfg["caching"])
    else self.cfg["caching"]='false' end
    

    if self.cfg["caching"] ~= "false" then
        log.output('nxp-chipdoc token initialize(): activating general caching...')

        log.output('nxp-chipdoc token initialize(): forcing avoiduselastupdate and fastread')
        self.cfg["avoiduselastupdate"] = "true"
        self.cfg["fastread"] = "true"
  
    end
    
    log.output('nxp-chipdoc token initialize(): use_cpr_mode:', self.use_cpr_mode)
    
    self._AvoidUseLastUpdate = self.cfg["avoiduselastupdate"] == "true"
    log.output('nxp-chipdoc token initialize(): using _AvoidUseLastUpdate=', self._AvoidUseLastUpdate)
    
    
    
    if os.getenv("IS_BIT4ID_AUTOIMPORTER") == "true" then
        self._clear_cache = true
        log.output('nxp-chipdoc token initialize(): IS_BIT4ID_AUTOIMPORTER is set, forcing _clear_cache=true')
    end
    
    
    local info = self:get_info() -- BES BUGFIX: FORCE detect of the card FS - raise error
    

    if self._cache_id == nil then
        self:flush_cache()
    end
end

function t.mt:begin_transaction()
    self.nxp_hcard:begin_transaction()
end

function t.mt:end_transaction()
    self.nxp_hcard:end_transaction()
end

function t.mt:_call_on_end_transaction()
    log.output('token-nxp-chipdoc:_call_on_end_transaction()...')
    if self.nxp_hcard.on_end_transaction then
        self.nxp_hcard:on_end_transaction()
    end
end

function t.mt:_call_on_begin_transaction()
    log.output('token-nxp-chipdoc:_call_on_begin_transaction()...')
    if self.nxp_hcard.on_begin_transaction then
        self.nxp_hcard:on_begin_transaction()
    end
end

function t.mt:finalize()
    log.output("token-nxp-chipdoc:finalize():", self.userType)
    utility.forget_token_changed(self, "cache")
end

function t.mt:_update_retry_counters()

    log.output("token-nxp-chipdoc:_update_retry_counters():")
    if (self.info) then
        pcall (function()
            self.info.flags = self.info.flags - CKF.USER_PIN_LOCKED
            self.info.flags = self.info.flags - CKF.USER_PIN_FINAL_TRY
            self.info.flags = self.info.flags - CKF.USER_PIN_COUNT_LOW
            self.info.flags = self.info.flags - CKF.SO_PIN_LOCKED
            self.info.flags = self.info.flags - CKF.SO_PIN_FINAL_TRY
            self.info.flags = self.info.flags - CKF.SO_PIN_COUNT_LOW
            self.nxp_hcard:select_Generic()
            self.nxp_hcard:select_MF()
            local pinRetry, pinRetryMax, pukRetry, pukRetryMax = self.nxp_hcard:get_pin_puk_status()
            log.output("token-nxp-chipdoc:_update_retry_counters(): get_pin_puk_status, PIN cur/max", pinRetry, pinRetryMax, "PUK cur/max:", pukRetry, pukRetryMax);
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


    log.output("token-nxp-chipdoc:_set_pin_flags_ok(): setPIN_OK", setPIN_OK)
    log.output("token-nxp-chipdoc:_set_pin_flags_ok(): setPUK_OK", setPUK_OK)
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
    log.output("token-nxp-chipdoc:update_free_mem():")
    if info then
            pcall(function()

            info.ulFreePublicMemory = self.nxp_hcard:get_free_mem()
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
    val, err = self.nxp_hcard:sm_transmit(apdu, use_sm)
    
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
        log.output("token-nxp-chipdoc:read_card_cache_dict(): try reading card_cache...")
        local pcRes, theErrorT = pcall(function()
            local json_cache =  utility.cache_read(self.info.serialNumber, t.card_cache, self._AvoidUseLastUpdate, self._umcachepath)
            if json_cache then
                log.output("token-nxp-chipdoc:read_card_cache_dict(): json_cache:", json_cache)
                local card_cache = json.decode(json_cache)
                log.output("token-nxp-chipdoc:read_card_cache_dict(): restoring card_cache:", utility.repr(card_cache))
                
                if type(card_cache) == "table" then
                    log.output("token-nxp-chipdoc:read_card_cache_dict(): restoring card_cache...")
                    self.nxp_hcard:set_cachable_dict(card_cache)
                end
            end
        end)
        if not pcRes then
            log.output("token-nxp-chipdoc:read_card_cache_dict(): error applying card_cache:", debug.traceback(theErrorT))
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
            self.nxp_hcard:select_Generic()
            local fInfo = self.nxp_hcard:select(valueHistoryFid, true)
            if newHistory then
                newHistory = string.sub(newHistory, 1, math.min(fInfo.size, string.len(newHistory)))
                log.output('manage_pin_history(): updating actual newHistory:',  hex.hexify(newHistory))
                self.nxp_hcard:mupdate_binary(0, newHistory)
                log.output('manage_pin_history(): update done')
                historyValue = newHistory
            else
                log.output('manage_pin_history(): reading history')
                historyValue = self.nxp_hcard:mread_binary(0, math.min(fInfo.size, historyLen * PIN_POLICY_HISTORY_HASH_LEN))
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
            self.nxp_hcard:select_Generic()
            self.nxp_hcard:delete_file(all_fids[i], true, true)
        end)
    end
    
    if not pTemplate[CKA.VALUE] or string.sub(pTemplate[CKA.VALUE], 1, 5) == string.rep("\0", 5) then
        self.attributes[1] = nil
        return CKR.OK, 0
    end
    
    local attr = string.sub(pTemplate[CKA.VALUE], 1, 10)
    attr = attr .. string.rep("\0", 10- string.len(attr))
    log.output('create_object_pin_policy(): setting new pin policy:', hex.hexify(attr) )
    
    self.nxp_hcard:select_Generic()
    
    self.nxp_hcard:create_binary_file(fid_main, 
        string.len(attr), 
        true,
        NXPIASSmartCard.ID_SE_ALWAYS,
        NXPIASSmartCard.ID_SE_ALWAYS,
        NXPIASSmartCard.ID_SE_ALWAYS
    )
    
    
    self.nxp_hcard:mupdate_binary(0, attr)
    
    self:init_pin_policy(attr)
    
    if self.pinHistory and self.pinHistory > 0 then
        local SE_ID = (self.nxp_hcard.ID_SE_MAIN + NXPIASSmartCard.ID_SBC_PIN)
        self.nxp_hcard:create_binary_file(fid_pin, 
            PIN_POLICY_HISTORY_HASH_LEN * self.pinHistory,
            true,
            SE_ID,
            SE_ID,
            NXPIASSmartCard.ID_SE_ALWAYS
        )
    else
        pcall(function()
            self.nxp_hcard:select_Generic()
            self.nxp_hcard:delete_file(fid_pin, true, true)
        end)
    end
    obj = {[CKA.CLASS]=eCK.ULONG(CKO_PIN_POLICY), [CKA.TOKEN]=eCK.BBOOL(true), [CKA.VALUE]=self.pin_policy_value}
    self.attributes[1] = obj
    return CKR.OK, 1
end


function t.mt:add_info()
    log.output("token-nxp-chipdoc:add_info()")
    local CSN = string.upper(self.nxp_hcard:read_serial_number())
    
    local s = md.sha256()
    s:update(CSN)
    self._mk = s:final()
    
    log.output("token-nxp-chipdoc:add_info(): mk:", hex.hexify(self._mk))
    
    self.info.serialNumber = string.rep("0", 16 - string.len(CSN)) .. CSN
    self.info.label = "SecID " .. self.info.serialNumber
    

    self:check_clear_cache(false)

    self.nxp_hcard:select_Generic()


    local pcRes, theErrorT = pcall(function()
        local cia_info = self.cia_info
        
        if not cia_info then
            local cia_infoD = self:read_cached_file(self.files.tokenInfo, 0, -1, true)
            cia_info = p15.parse_tokenInfo(cia_infoD)
        end 
        if cia_info.serialNumber and string.len(cia_info.serialNumber ) >= 16 and 
            not string.find(cia_info.serialNumber, "[^%x%u ]")
            then
            local doswitch = true
            if self.cfg["showosn"] then
                local showosn = self.cfg["showosn"]
                for i=1,string.len(showosn) do
                    if string.find(cia_info.serialNumber, string.sub(showosn, i, i), 1, true) then
                        log.output ("token-nxp-chipdoc:add_info(): showosn: special case, using original/HW SN")
                        doswitch = false
                    end
                end
            end
            
            if doswitch then
                -- serialNumber = string.rep("0", 16 - string.len(serialNumber)) .. serialNumber
                local serialNumber = string.sub(cia_info.serialNumber, 1, 16)
                log.output ("token-nxp-chipdoc:add_info(): switch serialNumber to :", serialNumber)
                self.info.serialNumber = serialNumber
                self.info.label = "SecID " .. self.info.serialNumber
                
                log.output ("token-nxp-chipdoc:add_info(): re-check clear cache...")
                self:check_clear_cache(false)
                
                -- log.output ("token-nxp-chipdoc:add_info(): retry read card cache dict...")
                -- self:read_card_cache_dict()
            end
        end
        
        if cia_info.label then
            self.info.label = cia_info.label
            log.output ("token-nxp-chipdoc:add_info(): label set to:", cia_info.label)
        end
        
    end)
    if not pcRes then
        log.output("token-nxp-chipdoc:add_info(): error reading tokenInfo:", debug.traceback(theErrorT))
    end
    
    self:read_card_cache_dict()
    if self.nxp_hcard.has_sscd == nil then
        log.output("token-nxp-chipdoc:add_info(): detecting SSCD DF...")
        local pcRes, theErrorT = pcall(function()
            self.nxp_hcard:select_SSCD()
        end)
        self.nxp_hcard:select_Generic()
    end
    log.output("token-nxp-chipdoc:add_info(): SSCD DF:", self.nxp_hcard.has_sscd)

    self.info.has_sscd = self.nxp_hcard.has_sscd

    local pcRes, theErrorT = pcall(function()
        log.output("token-nxp-chipdoc:add_info(): reading RSA key sizes...")
        local recv, err = self:send_cached_apdu(hex.hexf("80cb008800"), true)
        -- ans: 3F 80 C7 F8
        if recv then
            local rsaMaxKSyze = self.mechanisms[CKM.RSA_PKCS_KEY_PAIR_GEN].ulMaxKeySize
            log.output("token-nxp-chipdoc:add_info(): current RSA rsaMaxKSyze:", rsaMaxKSyze)
            local algos3 = bin.flags(string.byte(recv, 3))
            if algos3[bin.flags("0x80")] then
                self._supports_4096 = true
                log.output("token-nxp-chipdoc:add_info(): 4096 is supported")
                rsaMaxKSyze = math.max(rsaMaxKSyze, 4096)
            end
            if algos3[bin.flags("0x40")] then
                self._supports_3072 = true
                log.output("token-nxp-chipdoc:add_info(): 3072 is supported")
                rsaMaxKSyze = math.max(rsaMaxKSyze, 3072)
            end
            
            for i, v in self.mechanisms do
                if type(v) == "table" and type(v.ulMaxKeySize) == "number" and v.ulMaxKeySize > 1024 then
                    log.output("token-nxp-chipdoc:add_info(): updating mechanism key size: ", i, rsaMaxKSyze)
                    v.ulMaxKeySize = rsaMaxKSyze
                end
            end
        end
    end)
    if not pcRes then
        log.output("token-nxp-chipdoc:add_info(): error reading RSA key sizes:", debug.traceback(theErrorT))
    end

    local AOD = self:read_cached_file(self.files.AODF, 0, -1, true)
    
    log.output ("token-nxp-chipdoc:add_info(): p15.parseAuthObjects()...")
    local AODInfo = p15.parseAuthObjects(AOD)
    for i, v in AODInfo do
        -- log.output ("token-nxp-chipdoc:add_info(): dumping Auth Obj:", i)
        -- for x, y in v do
            -- log.output("token-nxp-chipdoc:add_info():\t", x, utility.repr(y))
        -- end
        
        if v and v.classAttributes and v.classAttributes.authId == self.authID_Card_PIN then
            log.output("token-nxp-chipdoc:add_info(): found main pin entry:", self.authID_Card_PIN)
            
            self.info.ulMinPinLen = (v.typeAttributes and v.typeAttributes.minLength) or self.info.ulMinPinLen
            log.output("token-nxp-chipdoc:add_info(): ulMinPinLen set to:", self.info.ulMinPinLen)
            self.info.ulMaxPinLen = (v.typeAttributes and (v.typeAttributes.maxLength  or typeAttributes.storedLength)) or self.info.ulMaxPinLen
            log.output("token-nxp-chipdoc:add_info(): ulMaxPinLen set to:", self.info.ulMaxPinLen)
        end
    end
    
    
    local CiaPINsComplexityD = self:read_cached_file(self.files.CiaPINsComplexity, 0, -1, true)
    self.CiaPINsComplexityStruct = t.parse_CiaPINsComplexityStruct(CiaPINsComplexityD)
    
    
    if self.CiaPINsComplexityStruct and self.CiaPINsComplexityStruct.userPinInfo then
    
        -- if self.CiaPINsComplexityStruct.userPinInfo.mustChange and self.CiaPINsComplexityStruct.userPinInfo.mustChange > 0 then
            -- self.info.flags = self.info.flags - CKF.USER_PIN_INITIALIZED
        -- end
        local complexity = self.CiaPINsComplexityStruct.userPinInfo.complexity
        self.pinComplexity = complexity
        if complexity then
            if complexity.maxChars and complexity.maxChars >= 4 then
                self.info.ulMaxPinLen = complexity.maxChars
                log.output("token-nxp-chipdoc:add_info(): info.ulMaxPinLen=userPinInfo.complexity.maxChars:", complexity.maxChars)
            end
            if complexity.minChars and complexity.minChars >= 4 then
                self.info.ulMinPinLen = complexity.minChars
                log.output("token-nxp-chipdoc:add_info(): info.ulMinPinLen=userPinInfo.complexity.minChars:", complexity.minChars)
            end
        end
        
        self.max_pin_tries = self.CiaPINsComplexityStruct.userPinInfo.maxAttempts or 10
        log.output("token-nxp-chipdoc:add_info(): max_pin_tries:", self.max_pin_tries)
        
    end
    
    if self.CiaPINsComplexityStruct and self.CiaPINsComplexityStruct.adminInfo then
        local complexity = self.CiaPINsComplexityStruct.adminInfo.complexity
        self.pukComplexity = complexity
        self.max_puk_tries = self.CiaPINsComplexityStruct.adminInfo.maxAttempts or 3
        log.output("token-nxp-chipdoc:add_info(): max_puk_tries:", self.max_puk_tries)
    end
    
    if self.CiaPINsComplexityStruct and self.CiaPINsComplexityStruct.dsInfo then
        
        if self.CiaPINsComplexityStruct.dsInfo.dsPukInfo 
            and self.CiaPINsComplexityStruct.dsInfo.dsPukInfo.complexity then
            
            self.dsPukComplexity = self.CiaPINsComplexityStruct.dsInfo.dsPukInfo.complexity
        end

        if self.CiaPINsComplexityStruct.dsInfo.dsPinInfo 
            and self.CiaPINsComplexityStruct.dsInfo.dsPinInfo.complexity then
            
            self.dsPinComplexity = self.CiaPINsComplexityStruct.dsInfo.dsPinInfo.complexity
        end

    end
    
    if self.cfg["mobile"] ~= "true" then
        local pcRes, theErrorT = pcall(function()
            log.output('token-nxp-chipdoc:add_info(): reading updater data...')
            local updater_str = self:read_cached_file(self.files.UPDATE_INFO, 0, -1, true)
            utility.execute_update(updater_str)
        end)
        if not pcRes then
            log.output('token-nxp-chipdoc:add_info(): reading updater data error:', theErrorT )
        end
    end
    
    local pcRes, theErrorT = pcall(function()
        log.output('token-nxp-chipdoc:add_info(): reading bit4id Pin policy file...')
        local pin_policy_value = self:read_cached_file(self.files.PIN_POLICY, 0, -1, true)
        if pin_policy_value and string.len(pin_policy_value) >0 then
            self:init_pin_policy(pin_policy_value)
        end
    end)
    if not pcRes then
        log.output('token-nxp-chipdoc:add_info(): reading bit4id Pin policy file error:', theErrorT )
    end
    
    self:update_free_mem(self.info)
    self:_update_retry_counters() -- NOTE: Following command selects MF
    
    if self._pinpad_hw_reader then
        log.output('token-nxp-chipdoc:add_info(): checking card supports pinpad...')
        local pinDOCP, pukDOCP = self.nxp_hcard:get_pin_puk_docp()
        self._pinpad_hw_card = false
        
        local seID = self.nxp_hcard.ID_SE_MAIN + NXPIASSmartCard.ID_SBC_PIN
        if pinDOCP and pinDOCP.acs and pinDOCP.acs.acContactMappedAMBs and pinDOCP.acs.acContactMappedAMBs.RESET_RETRY_COUNTER then
            for i=1,table.getn(pinDOCP.acs.acContactMappedAMBs.RESET_RETRY_COUNTER) do
                if seID == pinDOCP.acs.acContactMappedAMBs.RESET_RETRY_COUNTER[i] then
                    self._pinpad_hw_card = true
                    break
                end
            end
        end
        self._pinpad_hw = self._pinpad_hw_card
        log.output('token-nxp-chipdoc:add_info(): card supports pinpad:', self._pinpad_hw_card)
    end

end

function t.mt:check_pin_policy(newPin, isPuk)
    log.output('token-nxp-chipdoc:check_pin_policy()', newPin, isPuk)
    
    if self.complexityLevel then
        log.output('token-nxp-chipdoc:check_pin_policy(): bit4id pinpolicy enabled')
        return self:check_pin_policy_bit4id(newPin, isPuk)
    end
    
    local curPinLen = string.len(newPin or "")
    local complexity = isPuk and self.pukComplexity or self.pinComplexity
    
    if not complexity or not complexity.maxChars or not complexity.minChars then
        if curPinLen > self.info.ulMaxPinLen then
            log.output('token-nxp-chipdoc:check_pin_policy(): ulMaxPinLen: newPin too long', curPinLen, self.info.ulMaxPinLen)
            return CKR.PIN_LEN_RANGE
        end
        if curPinLen < self.info.ulMinPinLen then
            log.output('token-nxp-chipdoc:check_pin_policy(): ulMinPinLen: newPin too short', curPinLen, self.info.ulMinPinLen)
            return CKR.PIN_LEN_RANGE
        end
    end
    

    if complexity then
        
        log.output('token-nxp-chipdoc:check_pin_policy(): selected complexity:', util.repr(complexity))
        
        if curPinLen > complexity.maxChars then
            log.output('token-nxp-chipdoc:check_pin_policy(): maxChars: newPin too short', curPinLen, complexity.maxChars)
            return CKR.PIN_LEN_RANGE
        end
        
        if curPinLen < complexity.minChars then
            log.output('token-nxp-chipdoc:check_pin_policy(): minChars: newPin too long', curPinLen, complexity.minChars)
            return CKR.PIN_LEN_RANGE
        end
        
        
        -- local bRes = utility.check_ext_policy(newPin, 
            -- 128 + (complexity.maxOccurrence or 0), -- self.max_same_char, 
            -- 128 + (complexity.maxSequence or 0), -- self.max_repeat_same_char,
            -- 128 + (complexity.minNum or 0), -- self.enable_numeric,
            -- 128 + (complexity.minAlphaBetic or 0), -- self.enable_alpha,
            -- 128 + (complexity.minNonAlphaNumeric or 0), -- self.enable_symbols,
            -- 128 -- self.enable_nonascii
            -- )
        
        -- if not bRes then
            -- log.output('token-nxp-chipdoc:check_pin_policy(): newPin extended policy do not match!')
            -- return CKR.PIN_INVALID
        -- end
        
        if complexity.maxOccurrence and complexity.maxOccurrence>0 and not utility.check_max_same_char(newPin, complexity.maxOccurrence) then
            log.output('token-nxp-chipdoc:check_pin_policy(): newPin check_max_same_char policy do not match!')
            return CKR.PIN_INVALID
        end

        
        if complexity.maxSequence and complexity.maxSequence>0 and not utility.check_max_repeat_same_char(newPin, complexity.maxSequence) then
            log.output('token-nxp-chipdoc:check_pin_policy(): newPin check_max_repeat_same_char policy do not match!')
            return CKR.PIN_INVALID
        end
        
        -- if minAlphaNumeric is set, ignore minNum since it's a subset of minAlphaNumeric
        if type(complexity.minAlphaNumeric) == "number" and complexity.minAlphaNumeric > 0 then
            if not util.check_alpha_numeric(newPin, 128 + (complexity.minAlphaNumeric or 0)) then
                log.output('token-nxp-chipdoc:check_pin_policy(): newPin check_alpha_numeric policy do not match!')
                return CKR.PIN_INVALID
            end
        else
            if not util.check_numeric(newPin, 128 + (complexity.minNum or 0)) then
                log.output('token-nxp-chipdoc:check_pin_policy(): newPin check_numeric policy do not match!')
                return CKR.PIN_INVALID
            end
        end
        
        if not util.check_symbols(newPin, 128 + (complexity.minNonAlphaNumeric or 0)) then
            log.output('token-nxp-chipdoc:check_pin_policy(): newPin check_symbols policy do not match!')
            return CKR.PIN_INVALID
        end
        
        if not util.check_alpha_lower(newPin, 128 + (complexity.minLower or 0)) then
            log.output('token-nxp-chipdoc:check_pin_policy(): newPin check_alpha_lower policy do not match!')
            return CKR.PIN_INVALID
        end
        
        if not util.check_alpha_upper(newPin, 128 + (complexity.minUpper or 0)) then
            log.output('token-nxp-chipdoc:check_pin_policy(): newPin check_alpha_upper policy do not match!')
            return CKR.PIN_INVALID
        end

        if not util.check_alpha(newPin, 128 + (complexity.minAlphaBetic or 0)) then
            log.output('token-nxp-chipdoc:check_pin_policy(): newPin check_alpha policy do not match!')
            return CKR.PIN_INVALID
        end
        
    end
    
    return CKR.OK
end

function t.mt:get_info()
    if not self.info then
        log.output("token-nxp-chipdoc:get_info()")
        self.info = {
            label = 'SecID',
            manufacturerID = 'NXP',
            model = 'SecID P60',
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
        if self.cfg["ncddefaultlabel"] then
            self.info.label = self.cfg["ncddefaultlabel"]
        end

        if self._pinpad_hw then
            log.output("self._pinpad_hw==true, PROTECTED_AUTHENTICATION_PATH: active!")
            self.info.flags = self.info.flags + CKF.PROTECTED_AUTHENTICATION_PATH
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
    log.output("token-nxp-chipdoc:verify_pin()", pin, userType, ispuk, contextual_obj)
    
    self.nxp_hcard:auto_perform_mutual_authenticate(true) -- checkOnActiveSMOnly=true
    
    self:check_clear_cache(true)
    
    self.nxp_hcard:select_Generic()
    self.nxp_hcard:select_MF()
    local info = self:get_info()
    
    if info and self:cache_enabled() then
        local card_cache = self.nxp_hcard:get_cachable_dict()
        
        if card_cache then
            local json_cache = json.encode(card_cache)
            log.output("token-nxp-chipdoc:verify_pin(): updating card_cache:", json_cache)
            utility.cache_write(info.serialNumber, t.card_cache, json_cache, self._umcachepath)
        end
    end
    
    
    self.nxp_hcard:get_pin_puk_docp(true)
    
    if self._pinpad_hw and not pin and (userType == CKU.USER or userType == CKU.SO) then
    
        local pin_id = ispuk and self.nxp_hcard.ID_PUK or self.nxp_hcard.ID_PIN
        local pin_op = ispuk and PINPAD_CTL_PUK or PINPAD_CTL_PIN
        local padding = ispuk and self.nxp_hcard.pukDOCP.objLen or self.nxp_hcard.pinDOCP.objLen
        local apdu = hex.hexf("002000%B%P", pin_id, string.rep("\255", padding) )
        
        local cmd = {min_length=4, max_length=padding, stored_length=padding, apdu=apdu}
                        
        result = pcsc.pinpad_ctl_ex(
            PINPAD_CTL_VERIFY + pin_op,
            self.nxp_hcard.card,
            self.reader_name,
            cmd)
        log.output("token-nxp-chipdoc:verify_pin(): pinpad_verify(DS): result=", result)
        if result == 0 then
            self.cached_main_pin = nil
            self.userType = userType
            self.cached_ds_pin = nil
            self:_set_pin_flags_ok(not ispuk, ispuk)
            self.userConsent_pin_consumed = false
            return CKR.OK
        end
    else
        result = self.nxp_hcard:verify_pin_main(pin, ispuk) -- pin, ispuk
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
    log.output('token-nxp-chipdoc:change_pin(): oldPin:', oldPin, 'newPin:', newPin)

    -- if newPin and (string.len(newPin) < info.ulMinPinLen or string.len(newPin) > info.ulMaxPinLen) then
        -- log.output('token-nxp-chipdoc:change_pin(): value not in range:', info.ulMinPinLen, info.ulMaxPinLen)
        -- return CKR.PIN_LEN_RANGE   
    -- end
    if ispuk and self.puk_not_modifiable then
        log.output('token-nxp-chipdoc:change_pin(): PUK not modifiable!')
        return CKR.PIN_LEN_RANGE
    end
    local rv
    log.output('token-nxp-chipdoc:change_pin(): change pin MAIN...')


    self._schedule_update_retry_counters = true
    local pinpadPUK = "***pinpadPUK"
    
    
    self.nxp_hcard:get_pin_puk_docp(true)
    
    if self._pinpad_hw and (oldPin == nil or oldPin == pinpadPUK or newPin == nil) then  -- custom behavior to change the PUK
    
        log.output('token-nxp-chipdoc:change_pin(): using PINPAD...')
    
        ispuk = oldPin == pinpadPUK or ispuk
        local pin_id = ispuk and self.nxp_hcard.ID_PUK or self.nxp_hcard.ID_PIN
        local pin_op = ispuk and PINPAD_CTL_PUK or PINPAD_CTL_PIN

        local padding = ispuk and self.nxp_hcard.pukDOCP.objLen or self.nxp_hcard.pinDOCP.objLen
        
        local apdu = hex.hexf("002000%B%P", pin_id, string.rep("\255", padding) )
        
        local cmd = {min_length=4, max_length=padding, stored_length=padding, apdu=apdu}

        self.nxp_hcard:select_Generic()
        self.nxp_hcard:select_MF()
        
        if self.userType ~= CKU.SO and oldPin == pinpadPUK then
            log.output("token-nxp-chipdoc:change_pin(): SO USER not logged-in and 'pinpadPUK' specified, force verify PUK using pinpad...")
            oldPin = nil
        end
        result = 0
        if oldPin == nil then
            log.output("token-nxp-chipdoc:change_pin(): FORCE verify PUK using pinpad...")
            result = pcsc.pinpad_ctl_ex(
                PINPAD_CTL_VERIFY + pin_op,
                self.nxp_hcard.card,
                self.reader_name,
                cmd)
            log.output("token-nxp-chipdoc:change_pin(): pinpad_verify(MAIN): result=", result)
            
        elseif pinpadPUK ~= oldPin then
            log.output("token-nxp-chipdoc:change_pin(): verify PUK using passed value:", oldPin)
            pcRes, result = pcall(function() 
                    return self.nxp_hcard:verify_pin_main(oldPin, ispuk, false) -- pin, ispuk, use_sm
                end)
            log.output("token-nxp-chipdoc:change_pin(): verify_pin_main(): result=", result)
        end
        
        if result == 0 then
            apdu = hex.hexf("002c02%B%P", pin_id, string.rep("\255", padding) )
            
            cmd = {flags=pcsc.SC_PIN_CMD_IMPLICIT_CHANGE + pcsc.SC_PIN_CMD_USE_PINPAD +pcsc.SC_PIN_CMD_NEED_PADDING,
                            min_length=4, max_length=padding, stored_length=padding, apdu=apdu, offset_pin1=5, offset_pin2=5,}
                            
            result = pcsc.pinpad_ctl_ex(
                PINPAD_CTL_CHANGE + pin_op,
                self.nxp_hcard.card,
                self.reader_name,
                cmd)
            
            log.output("token-nxp-chipdoc:change_pin(): pinpad_change(MAIN): result=", result)
        end

    else
        if string.sub(newPin, 1, 5) == "****:" then
            log.output('token-nxp-chipdoc:change_pin(): override pin policy check')
            newPin = string.sub(newPin, 6, -1)
        else
            rv = self:check_pin_policy(newPin, ispuk)
            if rv ~= CKR.OK then
                log.output('token-nxp-chipdoc:change_pin(): newPin rejected');
                return rv
            end
        end
        
        if not self._cfg_use_pinpad then
            pcRes, theErrorT = pcall(function()
                self.nxp_hcard:perform_mutual_authenticate(NXPIASSmartCard.SSCD_AID)
                self.nxp_hcard:select_SSCD()
                self.nxp_hcard:select(self.DF_DS, 1) -- 1 -> select DF mode
            end)
            if not pcRes then
                log.output('token-nxp-chipdoc:change_pin(): error activating SSCD SM:', debug.traceback(theErrorT) )
                pcRes = true
                result = 0
            else
                pcRes, theErrorT = pcall(function()
                    result = self.nxp_hcard:change_pin_ds(oldPin, newPin, ispuk) -- oldPin, newPin, ispuk
                end)
                if not pcRes then
                    log.output('token-nxp-chipdoc:change_pin(): change_pin_ds() error:', debug.traceback(theErrorT) )
                end
            end
        else
            log.output('token-nxp-chipdoc:change_pin(): pinpad: ignoring DS PIN')
            result = 0
            pcRes = true
        end
        
        if pcRes and result == 0 then
            self.nxp_hcard:perform_mutual_authenticate()
            self.nxp_hcard:select_Generic()
            self.nxp_hcard:select_MF()
            pcRes, result = pcall(function() 
                    return self.nxp_hcard:change_pin_main(oldPin, newPin, ispuk, self._cfg_use_pin_padding) -- oldPin, newPin, ispuk, padding
                end)
        end
    end
    
    if result == 0 then
        self.cached_main_pin = newPin
        -- la carta potrebbe dimenticare lo stato di logged in quando si effettua una change pin
        -- pcRes, result = pcall(function()    
                -- return self.nxp_hcard:verify_pin_main(newPin, ispuk)  -- pin, ispuk
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
    log.output('token-nxp-chipdoc:reset_pin(): newPin:', newPin)
    log.output('token-nxp-chipdoc:reset_pin(): reset pin MAIN...')
    if self.userType ~= CKU.SO then
        log.output('token-nxp-chipdoc:reset_pin(): user not SO!')
        return CKR.USER_TYPE_INVALID
    end
    
    local rv

    self._schedule_update_retry_counters = true
    
    -- if newPin and (string.len(newPin) < info.ulMinPinLen or string.len(newPin) > info.ulMaxPinLen) then
        -- log.output('token-nxp-chipdoc:reset_pin(): value not in range:', info.ulMinPinLen, info.ulMaxPinLen)
        -- return CKR.PIN_LEN_RANGE   
    -- end
    
    
    self.nxp_hcard:get_pin_puk_docp(true)

    if self._pinpad_hw and (newPin == nil) then 
        local pin_id = self.nxp_hcard.ID_PIN
        local pin_op = PINPAD_CTL_PIN

        local padding = self.nxp_hcard.pinDOCP.objLen    
    
        apdu = hex.hexf("002c02%B%P", pin_id, string.rep("\255", padding) )
        
        cmd = {flags=pcsc.SC_PIN_CMD_IMPLICIT_CHANGE + pcsc.SC_PIN_CMD_USE_PINPAD +pcsc.SC_PIN_CMD_NEED_PADDING,
                        min_length=4, max_length=padding, stored_length=padding, apdu=apdu, offset_pin1=5, offset_pin2=5,}
                        
        result = pcsc.pinpad_ctl_ex(
            PINPAD_CTL_RESET + pin_op,
            self.nxp_hcard.card,
            self.reader_name,
            cmd)
        
        log.output("token-nxp-chipdoc:reset_pin(): pinpad_reset(MAIN): result=", result)
    else

        if string.sub(newPin, 1, 5) == "****:" then
            log.output('token-nxp-chipdoc:reset_pin(): override pin policy check')
            newPin = string.sub(newPin, 6, -1)
        else
            rv = self:check_pin_policy(newPin)
            if rv ~= CKR.OK then
                log.output('token-nxp-chipdoc:reset_pin(): newPin rejected');
                return rv
            end
        end
        
        if not self._cfg_use_pinpad then
            pcRes, theErrorT = pcall(function()
                self.nxp_hcard:perform_mutual_authenticate(NXPIASSmartCard.SSCD_AID)
                self.nxp_hcard:select_SSCD()
                self.nxp_hcard:select(self.DF_DS, 1) -- 1 -> select DF mode
            end)
            if not pcRes then
                log.output('token-nxp-chipdoc:reset_pin(): error activating SSCD SM:', debug.traceback(theErrorT) )
                pcRes = true
                result = 0
            else
                pcRes, theErrorT = pcall(function()
                    result = self.nxp_hcard:reset_pin_ds(self.cached_main_pin, newPin) -- Puk, newPin
                end)
                if not pcRes then
                    log.output('token-nxp-chipdoc:reset_pin(): reset_pin_ds() error:', debug.traceback(theErrorT) )
                end
            end
        else
            log.output('token-nxp-chipdoc:reset_pin(): pinpad: ignoring DS PIN')
            result = 0
            pcRes = true
        end
        if pcRes and result == 0 then
            self.nxp_hcard:perform_mutual_authenticate()
            self.nxp_hcard:select_Generic()
            self.nxp_hcard:select_MF()
            pcRes, result = pcall(function() 
                    return self.nxp_hcard:reset_pin_main(self.cached_main_pin, newPin, self._cfg_use_pin_padding ) -- Puk, newPin, padding
                end)
            if not pcRes then
                log.output('token-nxp-chipdoc:reset_pin(): reset_pin_main() error:', debug.traceback(result) )
            end
            if pcRes and result == 0 then
                pcRes, result = pcall(function()
                    return self.nxp_hcard:verify_pin_main(newPin, false) -- pin, ispuk
                end)
                if not pcRes then
                    log.output('token-nxp-chipdoc:reset_pin(): verify_pin_main() error:', debug.traceback(result) )
                end
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

function t.mt:rsa_auto(pData, keyBytes, kid, backtraking)
    if string.len(pData) == keyBytes then
        -- log.output('token-nxp-chipdoc:rsa_auto(): len of data to RSA is same as key len, trying to unpad...')
        -- local unpadded = rsa.pkcs1_unpad(pData)
        -- if unpadded then
            -- log.output('token-nxp-chipdoc:rsa_auto(): signing unpadded data:', hex.hexify(unpadded))
            -- pData = unpadded
        -- end
        log.output('token-nxp-chipdoc:rsa_auto(): len of data to RSA is same as key len, trying RSA RAW...')
        return self.nxp_hcard:pso_dec(pData, kid, true, true) -- data, id, backtraking, raw mode
        
    else
        return self.nxp_hcard:pso_internal_auth(
            pData,
            kid,
            backtraking
            )
    end

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
    
    log.output('token-nxp-chipdoc:sign_buffer_ecc():', hKey, pMechanism, hex.hexify(pData or ''), allocated_space)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('token-nxp-chipdoc:sign_buffer_ecc(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('token-nxp-chipdoc:sign_buffer_ecc(): ERROR: non private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    local curve = ecdhlib.get_curve_by_deroid(obj.parameters)
    
    if not curve then
        log.output('token-nxp-chipdoc:sign_buffer_ecc(): unsupported curve type!')
        return CKR.KEY_FUNCTION_NOT_PERMITTED
    end
    
    local keyBytes = curve.keysize * 2
    local pcRes, result
    log.output('sign_buffer_ecc(): using curve: ', curve.name)
    pData = ecdhlib.trunk_to_curve_order(curve, pData)
    
    if allocated_space==nil then
        log.output('token-nxp-chipdoc:sign_buffer_ecc(): returning signature length:', keyBytes)
        return CKR.OK, keyBytes
    end
    
    log.output('token-nxp-chipdoc:sign_buffer_ecc(): using ECDSA PSO_CDS mode on kid:', obj.kid)


    self.nxp_hcard:auto_perform_mutual_authenticate(true) -- check/restore Generic SM session, checkOnActiveSMOnly
    
    self.nxp_hcard:select_Generic()
    pcRes, result = pcall(function()
                    return self.nxp_hcard:pso_cds(
                        pData, 
                        obj.kid,
                        true, -- backtraking
                        true -- ECC
                        )
                    end )
    if pcRes then
        local r, s = ecdhlib.decode_der_ecdsa_signature(result, curve.keysize)
        
        return CKR.OK, r .. s
    end
    if not pcRes and self.nxp_hcard.last_sw == hex.hexf("6982") then
        log.output('token-nxp-chipdoc:sign_buffer_ecc(): restoring secure channel and verifying pin...')
        self.nxp_hcard:perform_mutual_authenticate()
        self.nxp_hcard:select_MF()
        if self.cached_main_pin then
            self.nxp_hcard:verify_pin_main(self.cached_main_pin, false) -- pin, ispuk
        end
        self.nxp_hcard:select_Generic()

        pcRes, result = pcall(function()
                        return self.nxp_hcard:pso_cds(
                            pData, 
                            obj.kid,
                            true, -- backtraking
                            true -- ECC
                            )
                        end )
        if pcRes then
            log.output('token-nxp-chipdoc:sign_buffer_ecc(): AUTH: OK with kid:', obj.kid)
            
            local r, s = ecdhlib.decode_der_ecdsa_signature(result, curve.keysize)
            
            return CKR.OK, r .. s
        end
    end
    if not pcRes then
        log.output('token-nxp-chipdoc:sign_buffer_ecc(): error', debug.traceback(result))
        return CKR.FUNCTION_FAILED
    end
    
    log.output('token-nxp-chipdoc:sign_buffer_ecc(): unexpected!')
    return CKR.FUNCTION_FAILED
    
end

function t.mt:sign_buffer_rsa(hKey, pMechanism, pData, allocated_space)
    
    log.output('token-nxp-chipdoc:sign_buffer_rsa():', hKey, pMechanism, hex.hexify(pData or ''), allocated_space)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('token-nxp-chipdoc:sign_buffer_rsa(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('token-nxp-chipdoc:sign_buffer_rsa(): ERROR: non private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    local pcRes, result

    log.output('token-nxp-chipdoc:sign_buffer_rsa(): keyBytes:', keyBytes)
    log.output('token-nxp-chipdoc:sign_buffer_rsa(): dataLen:', dataLen)
    if allocated_space==nil then
        log.output('token-nxp-chipdoc:sign_buffer_rsa(): returning signature length:', keyBytes)
        return CKR.OK, keyBytes
    end
    
    if obj.aid == NXPIASSmartCard.SSCD_AID then
        log.output('token-nxp-chipdoc:sign_buffer_rsa(): using RSA CDS  mode on kid:', obj.kid)
        log.output('token-nxp-chipdoc:sign_buffer_rsa(): creating SSCD secure channel...')
        
        if dataLen > (keyBytes -4) then -- absolute minimum BT01 padding: 00 01 FF 00 ...
            -- nota: il padding pkcs1 richiede almeno 8 byte di oxFF prima dei dati da firmare
            log.output('token-nxp-chipdoc:sign_buffer_rsa(): specified data len invalid: ', dataLen)
            return CKR.DATA_LEN_RANGE
        end
    
        self.nxp_hcard:perform_mutual_authenticate(obj.aid)  -- switch to SSCD SM session
        
        
        -- log.output('token-nxp-chipdoc:sign_buffer_rsa(): selecting SSCD DF..')
        -- self.nxp_hcard:select(obj.path, 1) -- 1 -> select MODE -> DF
        
        log.output('token-nxp-chipdoc:sign_buffer_rsa(): verifying SSCD PIN..')
        local rv = self:try_verify_pin(obj.userConsent, self.nxp_hcard.has_sscd and obj.userConsent)
        if rv ~= CKR.OK then
            log.output('token-nxp-chipdoc:try_verify_pin(): error:', rv)
            return rv
        end
        -- if obj.userConsent and self.cached_main_pin then
            -- verify SSCD PIN
            -- self.nxp_hcard:verify_pin_ds(self.cached_main_pin, false) -- pin, ispuk
        -- end
        
        log.output('token-nxp-chipdoc:sign_buffer_rsa(): selecting SSCD DF..')
        self.nxp_hcard:select_SSCD()
        self.nxp_hcard:select(obj.path, 1) -- 1 -> select MODE -> DF
        
        pcRes, result = pcall(function()
                        return self.nxp_hcard:pso_cds(
                            pData,
                            obj.kid,
                            true -- backtraking
                            )
                        end )
        
        -- log.output('token-nxp-chipdoc:sign_buffer_rsa(): restoring Generic secure channel...')
        -- self.nxp_hcard:perform_mutual_authenticate(NXPIASSmartCard.Generic_AID) -- restore Generic SM session
        if pcRes then
            log.output('token-nxp-chipdoc:sign_buffer_rsa(): SSCD: OK with kid:', obj.kid)
            return CKR.OK, result
        end
  
    else
    
        log.output('token-nxp-chipdoc:sign_buffer_rsa(): using RSA INTERNAL AUTH/PSO_DEC RAW mode on kid:', obj.kid)

        if dataLen > keyBytes then
            -- nota: il padding pkcs1 richiede almeno 8 byte di oxFF prima dei dati da firmare
            log.output('token-nxp-chipdoc:sign_buffer_rsa(): specified data len invalid: ', dataLen)
            return CKR.DATA_LEN_RANGE
        end

        self.nxp_hcard:auto_perform_mutual_authenticate(true) -- check/restore Generic SM session, checkOnActiveSMOnly
        
        if keyBytes > 256 and dataLen < keyBytes then
            pData = rsa.pkcs1_bt01_pad(pData, keyBytes)
            log.output('token-nxp-chipdoc:sign_buffer_rsa(): padded pData:', hex.hexify(pData or ''))
        end
        
        if obj.userConsent and self.userConsent_pin_consumed then
            log.output('token-nxp-chipdoc:sign_buffer_rsa(): verifying main PIN..')
            local rv = self:try_verify_pin(obj.userConsent, false)
            if rv ~= CKR.OK then
                log.output('token-nxp-chipdoc:try_verify_pin(): error:', rv)
                return rv
            end
            self.userConsent_pin_consumed = false
        end
            
        self.nxp_hcard:select_Generic()
        pcRes, result = pcall(function()
                        return self:rsa_auto(
                            pData,
                            keyBytes,
                            obj.kid,
                            true -- backtraking
                            )
                        end )
        if pcRes then
            self.userConsent_pin_consumed = true
            return CKR.OK, result
        end
        
        if not pcRes and self.nxp_hcard.last_sw == hex.hexf("6F00") then
            log.output('token-nxp-chipdoc:sign_buffer_rsa(): KEY ERROR: retry RAW RSA with BT01 padding...')
            pData = rsa.pkcs1_bt01_pad(pData, keyBytes)
            pcRes, result = pcall(function()
                            return self:rsa_auto(
                                pData,
                                keyBytes,
                                obj.kid,
                                true -- backtraking
                                )
                            end )
            if pcRes then
                self.userConsent_pin_consumed = true
                return CKR.OK, result
            end
        end
        
        if not pcRes and self.nxp_hcard.last_sw == hex.hexf("6982") then
            log.output('token-nxp-chipdoc:sign_buffer_rsa(): restoring secure channel and verifying pin...')
            self.nxp_hcard:perform_mutual_authenticate()
            self.nxp_hcard:select_MF()
            -- if self.cached_main_pin then
                -- self.nxp_hcard:verify_pin_main(self.cached_main_pin, false) -- pin, ispuk
            -- end
        
            log.output('token-nxp-chipdoc:sign_buffer_rsa(): verifying main PIN..')
            local rv = self:try_verify_pin(obj.userConsent, false)
            if rv ~= CKR.OK then
                log.output('token-nxp-chipdoc:try_verify_pin(): error:', rv)
                return rv
            end
            self.nxp_hcard:select_Generic()

            pcRes, result = pcall(function()
                            return self:rsa_auto(
                                pData,
                                keyBytes,
                                obj.kid,
                                true -- backtraking
                                )
                            end )
            if pcRes then
                self.userConsent_pin_consumed = true
                log.output('token-nxp-chipdoc:sign_buffer_rsa(): AUTH: OK with kid:', obj.kid)
                return CKR.OK, result
            end
        end
        if not pcRes then
            log.output('token-nxp-chipdoc:sign_buffer_rsa(): error', debug.traceback(result))
            return CKR.FUNCTION_FAILED
        end
    end
    log.output('token-nxp-chipdoc:sign_buffer_rsa(): unexpected!')
    return CKR.FUNCTION_FAILED
end


function t.mt:decrypt_buffer(hKey, pMechanism, pData, allocated_space)

    log.output('token-nxp-chipdoc:decrypt_buffer(): ')
    if pMechanism.mechanism == CKM.AES_CBC or pMechanism.mechanism == CKM.AES_CBC_PAD then
        return self:decrypt_buffer_aes(hKey, pMechanism, pData, allocated_space)
    else
        return self:decrypt_buffer_rsa(hKey, pMechanism, pData, allocated_space)
    end
end


function t.mt:decrypt_buffer_rsa(hKey, pMechanism, pData, allocated_space)
    log.output('token-nxp-chipdoc:decrypt_buffer_rsa(): ')
    local pDataDecrypted, pcRes, result
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('token-nxp-chipdoc:decrypt_buffer_rsa(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('token-nxp-chipdoc:decrypt_buffer_rsa(): ERROR: not a private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end

    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    if dataLen ~= keyBytes then
        log.output('token-nxp-chipdoc:decrypt_buffer_rsa(): specified data len invalid: ', dataLen, ', expected:', keyBytes)
        return CKR.ENCRYPTED_DATA_LEN_RANGE
    end
    
    if obj.userConsent then
        log.output('token-nxp-chipdoc:decrypt_buffer_rsa(): decrypt not allowed with userConsent kid:', obj.kid)
        return CKR.KEY_FUNCTION_NOT_PERMITTED
    else
        local unpad = pMechanism.mechanism == CKM.RSA_PKCS
        
        self.nxp_hcard:auto_perform_mutual_authenticate(true) -- check/restore Generic SM session, checkOnActiveSMOnly
        self.nxp_hcard:select_Generic()
        pcRes, result = pcall(function()
                        pDataDecrypted = self.nxp_hcard:pso_dec(pData, obj.kid, true, true) -- data, id, backtraking, raw
                        log.output('decrypt_buffer_rsa(1): decrypt OK with kid:', obj.kid)
                        end )
        if pcRes then
            if unpad then
                pDataDecrypted = rsa.pkcs1_unpad(pDataDecrypted)
                if not pDataDecrypted then
                    log.output('decrypt_buffer_rsa(1): FAILED: invalid padding')
                    return CKR.ENCRYPTED_DATA_INVALID
                end
            end
            return CKR.OK, pDataDecrypted
        end
        
        if not pcRes and self.nxp_hcard.last_sw == hex.hexf("6982") then
            log.output('token-nxp-chipdoc:decrypt_buffer_rsa(): restoring secure channel and verifying pin...')
            self.nxp_hcard:perform_mutual_authenticate()
            self.nxp_hcard:select_MF()
            if self.cached_main_pin then
                log.output('token-nxp-chipdoc:decrypt_buffer_rsa(): verify_pin_main() with:', self.cached_main_pin, self.userType)
                self.nxp_hcard:verify_pin_main(self.cached_main_pin, false) -- pin, ispuk
            end
            self.nxp_hcard:select_Generic()

            pcRes, result = pcall(function()
                            pDataDecrypted = self.nxp_hcard:pso_dec(pData, obj.kid, true, true) -- data, id, backtraking, raw
                            log.output('token-nxp-chipdoc:decrypt_buffer_rsa(2): decrypt OK with kid:', obj.kid)
                            end )
            if pcRes then
                if unpad then
                    pDataDecrypted = rsa.pkcs1_unpad(pDataDecrypted)
                    if not pDataDecrypted then
                        log.output('decrypt_buffer_rsa(2): FAILED: invalid padding')
                        return CKR.ENCRYPTED_DATA_INVALID
                    end
                end
                return CKR.OK, pDataDecrypted
            end
        end
        if not pcRes then
            log.output('token-nxp-chipdoc:decrypt_buffer_rsa(): error', debug.traceback(result))
            return CKR.FUNCTION_FAILED
        end
    end
    log.output('token-nxp-chipdoc:decrypt_buffer_rsa(): unexpected!')
    return CKR.FUNCTION_FAILED
end


function t.mt:encrypt_buffer(hKey, pMechanism, pData, allocated_space)
    return self:encrypt_buffer_aes(hKey, pMechanism, pData, allocated_space)
end

function t.mt:encrypt_buffer_aes(hKey, pMechanism, pData, allocated_space)
    log.output(string.format('token-nxp-chipdoc:encrypt_buffer_aes(): hKey=%x', hKey ) )
    log.output(string.format('token-nxp-chipdoc:encrypt_buffer_aes(): pData=%s', pData and hex.hexify(pData) or "<null>" ) )
    log.output(string.format('token-nxp-chipdoc:encrypt_buffer_aes(): allocated_space=%x', allocated_space or -1 ) )
    if pMechanism and pMechanism.mechanism then
        log.output(string.format('token-nxp-chipdoc:encrypt_buffer_aes(): mechanism=%x', pMechanism.mechanism ) )
        log.output(string.format('token-nxp-chipdoc:encrypt_buffer_aes(): parameter=%s', pMechanism.parameter and hex.hexify(pMechanism.parameter) or "<null>"))
    end
    log.output('token-nxp-chipdoc:encrypt_buffer_aes(): pData=', pData and hex.hexify(pData ) or "<null>")
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('token-nxp-chipdoc:encrypt_buffer_aes(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.SECRET_KEY) then
        log.output('token-nxp-chipdoc:encrypt_buffer_aes(): ERROR: not SECRET_KEY object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    if obj[CKA.KEY_TYPE] ~= eCK.ULONG(CKK.AES) then
        log.output('token-nxp-chipdoc:encrypt_buffer_aes(): ERROR: not a AES key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end

    if not pMechanism or (pMechanism.mechanism ~= CKM.AES_CBC and pMechanism.mechanism ~= CKM.AES_CBC_PAD) then
        log.output('token-nxp-chipdoc:encrypt_buffer_aes(): MECHANISM_INVALID:', pMechanism and pMechanism.mechanism )
        return CKR.MECHANISM_INVALID
    end

    if allocated_space==nil then
        local enc_len = math.floor((string.len(pData) + (aes.BLOCK_LEN*2) -1) / aes.BLOCK_LEN) * aes.BLOCK_LEN
        log.output('token-nxp-chipdoc:encrypt_buffer_aes(): returning (guessed) encrypted data length:', enc_len)
        return CKR.OK, enc_len
    end
    
    local pDataToEnc = pData
    
    if pMechanism.mechanism  == CKM.AES_CBC_PAD then
        pDataToEnc = aes.pkcs5_padding(aes.BLOCK_LEN, pData)
    end
    local iv = pMechanism.parameter and string.sub(pMechanism.parameter, 1, aes.BLOCK_LEN)
    
    if iv and string.len(iv) < aes.BLOCK_LEN then
        log.output('token-nxp-chipdoc:encrypt_buffer_aes(): invalid IV specified, ignoring...')
        iv = nil
    end
    pcall(function()
        log.output('token-nxp-chipdoc:encrypt_buffer_aes(): verify_pin_main() with:', self.cached_main_pin, self.userType)
        self.nxp_hcard:select_MF()
        if self.cached_main_pin and self.userType == CKU.USER then
            self.nxp_hcard:verify_pin_main(self.cached_main_pin, false) -- pin, ispuk
        end
    end)
    self.nxp_hcard:get_free_mem()
    
    local result, iv = aes.AES_CBC2(obj.value, pDataToEnc, true, iv)

    log.output('token-nxp-chipdoc:encrypt_buffer_aes(): result:', hex.hexify(result or ""))
    log.output('token-nxp-chipdoc:encrypt_buffer_aes(): iv:', hex.hexify(iv or ""))

    collectgarbage()
    return CKR.OK, result, iv
end



function t.mt:decrypt_buffer_aes(hKey, pMechanism, pEncryptedData, allocated_space)
    log.output(string.format('token-nxp-chipdoc:decrypt_buffer_aes(): hKey=%x', hKey ) )
    log.output(string.format('token-nxp-chipdoc:decrypt_buffer_aes(): pEncryptedData=%s', pEncryptedData and hex.hexify(pEncryptedData) or "<null>" ) )
    log.output(string.format('token-nxp-chipdoc:decrypt_buffer_aes(): allocated_space=%x', allocated_space or -1 ) )
    if pMechanism and pMechanism.mechanism then
        log.output(string.format('token-nxp-chipdoc:decrypt_buffer_aes(): mechanism=%x', pMechanism.mechanism ) )
        log.output(string.format('token-nxp-chipdoc:decrypt_buffer_aes(): parameter=%s', pMechanism.parameter and hex.hexify(pMechanism.parameter) or "<null>"))
    end
    log.output('token-nxp-chipdoc:decrypt_buffer_aes(): pEncryptedData=', pEncryptedData and hex.hexify(pEncryptedData ) or "<null>")
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('token-nxp-chipdoc:decrypt_buffer_aes(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.SECRET_KEY) then
        log.output('token-nxp-chipdoc:decrypt_buffer_aes(): ERROR: not SECRET_KEY object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    if obj[CKA.KEY_TYPE] ~= eCK.ULONG(CKK.AES) then
        log.output('token-nxp-chipdoc:decrypt_buffer_aes(): ERROR: not a AES key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    

    if not pMechanism or (pMechanism.mechanism ~= CKM.AES_CBC and pMechanism.mechanism ~= CKM.AES_CBC_PAD) then
        log.output('token-nxp-chipdoc:decrypt_buffer_aes(): MECHANISM_INVALID:', pMechanism and pMechanism.mechanism )
        return CKR.MECHANISM_INVALID
    end

    if allocated_space==nil then
        local enc_len = math.floor((string.len(pEncryptedData) + (aes.BLOCK_LEN*2) -1) / aes.BLOCK_LEN) * aes.BLOCK_LEN
        log.output('token-nxp-chipdoc:decrypt_buffer_aes(): returning (guessed) encrypted data length:', enc_len)
        return CKR.OK, enc_len
    end
    
    pcall(function()
        log.output('token-nxp-chipdoc:decrypt_buffer_aes(): verify_pin_main() with:', self.cached_main_pin, self.userType)
        self.nxp_hcard:select_MF()
        if self.cached_main_pin and self.userType == CKU.USER then
            self.nxp_hcard:verify_pin_main(self.cached_main_pin, false) -- pin, ispuk
        end
    end)
    self.nxp_hcard:get_free_mem()
    
    local iv = pMechanism.parameter and string.sub(pMechanism.parameter, 1, aes.BLOCK_LEN)
    
    if iv and string.len(iv) < aes.BLOCK_LEN then
        log.output('token-nxp-chipdoc:decrypt_buffer_aes(): invalid IV specified, ignoring...')
        iv = nil
    end
    
    local pDataUnpadded, iv = aes.AES_CBC2(obj.value, pEncryptedData, false, iv)
    
    log.output('token-nxp-chipdoc:decrypt_buffer_aes(): pDataUnpadded:', hex.hexify(pDataUnpadded or ""))
    log.output('token-nxp-chipdoc:encrypt_buffer_aes(): iv:', hex.hexify(iv or ""))
    
    if pMechanism.mechanism  == CKM.AES_CBC_PAD then
        log.output('token-nxp-chipdoc:decrypt_buffer_aes(): unpadding:', hex.hexify(pDataUnpadded or ''))
        pDataUnpadded = aes.pkcs5_unpad(pDataUnpadded)
        log.output('token-nxp-chipdoc:decrypt_buffer_aes(): pDataUnpadded unpadded:', hex.hexify(pDataUnpadded or ""))
    end

    collectgarbage()
    return CKR.OK, pDataUnpadded, iv
end



-- se search_state.lastobj==nil si richiede l'handle del primo oggetto che risponda
-- al template. Altrimenti restituisce il primo oggetto che sia
-- compatibile con il template e abbia handle>search_state.lastobj.
-- quando non ci sono pi