 oggetti ritorna 0
function t.mt:get_item(search_state, showprivate, template)
    log.output('get_item(): showprivate', showprivate)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    log.output('get_item(): approx available objects:', 1+ self.attributes.max_index - self.attributes.min_index )
    if search_state.lastobj==nil then 
        search_state.lastobj=self.attributes.min_index 
    end
    
    if template[CKA.CLASS] == eCK.ULONG(CKO_PIN_POLICY) then
    
        log.output('get_item(): SPECIAL SEARCH: PIN POLICY, lastobj, min_index, max_index:', search_state.lastobj,
            self.attributes.min_index, self.attributes.max_index)
    
        if search_state.lastobj ~= self.attributes.min_index then
            log.output('get_item(): SPECIAL SEARCH: PIN POLICY: end of search')
            return 0
        end
        
        log.output('get_item(): SPECIAL SEARCH: PIN POLICY: populating data')
        search_state.lastobj = math.max(self.attributes.min_index, self.attributes.max_index)+1
        obj = {[CKA.CLASS]=eCK.ULONG(CKO_PIN_POLICY), [CKA.TOKEN]=eCK.BBOOL(true), [CKA.VALUE]=self.pin_policy_value}
        self.attributes[1] = obj
        return 1 -- special handle value
    end
    
    for i=search_state.lastobj, self.attributes.max_index do
        local attr = self.attributes[i]
        log.output('get_item(): eval object:', i)
        if attr ~= nil then
            if type(attr[CKA.PRIVATE]) == 'function' then
                attr[CKA.PRIVATE](self, i, CKA.PRIVATE, false)
            end
            local private = attr.private or attr[CKA.PRIVATE] ~= eCK.BBOOL(false)
            log.output('get_item(): private:', private)
            local visible = not private or 
                            (private and showprivate)
            if not visible then
                log.output('get_item(): handle', i, 'not visible')
            end
            if visible and self:verify_template(i, template) then
                search_state.lastobj = i +1
                return i
            end
        end
    end
    search_state.lastobj = self.attributes.max_index +1 -- next search returns no object
    return 0
end

function t.mt:verify_template(hobj, template)
    -- contolla prima tutti gli attributi statici
    local static_attributes = {CKA.CLASS, CKA.TOKEN }
    for i, attr_type in static_attributes do
        if template[attr_type] then
            local rv, real_value = self:get_attribute_value(hobj, attr_type)
            if rv~=CKR.OK or real_value ~= template[attr_type] then
                -- log.output('>>>not match')
                -- log.output('>>>false')
                return false
            end
        end
    end

    for attr_type, value in template do
        
        local rv, real_value
        rv, real_value = self:get_attribute_value(hobj, attr_type)
        if attr_type == CKA.SERIAL_NUMBER
                and real_value ~= nil 
                and type(real_value) == 'string' 
                and value ~= nil then
            real_value = string.gsub(real_value, '%z*(.*)', '%1')
            value = string.gsub(value, '%z*(.*)', '%1')
        end
        --log.output('>>>template: ', hex.tohex8(attr_type),
        --           repr(value), repr(real_value), rv)
        if rv~=CKR.OK or real_value ~=value then
            -- log.output('>>>not match')
            -- log.output('>>>false')
            return false
        else
            -- log.output('>>>match')
        end
    end
    -- log.output('>>>true')
    return true
end


local function GetCertTemplate(populateCertFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.CERTIFICATE),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(true),
        [ CKA.LABEL ] = populateCertFunc,
        -- Certificate
        [ CKA.CERTIFICATE_TYPE ] = eCK.CERTIFICATE_TYPE(CKC.X_509),
        [ CKA.TRUSTED ] = eCK.BBOOL(true),
        [ CKA.CERTIFICATE_CATEGORY ] = eCK.ULONG(1), -- user
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        -- Certificate X.509
        [ CKA.SUBJECT ] = populateCertFunc,
        [ CKA.ID ] = populateCertFunc,
        [ CKA.ISSUER ] = populateCertFunc,
        [ CKA.SERIAL_NUMBER ] = populateCertFunc,
        [ CKA.VALUE ] = populateCertFunc,
        [ CKA.URL ] = '',
        [ CKA.HASH_OF_SUBJECT_PUBLIC_KEY ] = '',
        [ CKA.HASH_OF_ISSUER_PUBLIC_KEY ] = '',
        [ CKA.JAVA_MIDP_SECURITY_DOMAIN ] = eCK.ULONG(0),
    }
end

local function GetPubKeyTemplate(populatePubKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PUBLIC_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(true),
        [ CKA.LABEL ] = populatePubKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = populatePubKeyFunc,
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = eCK.BBOOL(true),
        [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.RSA_PKCS_KEY_PAIR_GEN),
        -- [ CKA.ALLOWED_MECHANISMS ] = '',
        -- Public Key
        [ CKA.SUBJECT ] = '',
        [ CKA.ENCRYPT ] = eCK.BBOOL(true),
        [ CKA.VERIFY ] = eCK.BBOOL(true),
        [ CKA.VERIFY_RECOVER ] = eCK.BBOOL(false),
        [ CKA.WRAP ] = eCK.BBOOL(false),
        [ CKA.TRUSTED ] = eCK.BBOOL(true),
        -- [ CKA.WRAP_TEMPLATE ] = '',
        -- RSA Public Key
        [ CKA.MODULUS ] = populatePubKeyFunc,
        [ CKA.MODULUS_BITS ] = populatePubKeyFunc,
        [ CKA.PUBLIC_EXPONENT ] = populatePubKeyFunc,
    }
end

local function GetPrivKeyTemplate(populatePubKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PRIVATE_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(true),
        [ CKA.LABEL ] = populatePubKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = populatePubKeyFunc,
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
        [ CKA.ALWAYS_AUTHENTICATE ] = populatePubKeyFunc,
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

local function GetECCPrivKeyTemplate(populateKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PRIVATE_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(true),
        [ CKA.LABEL ] = populatePubKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.ECDSA),
        [ CKA.ID ] = populatePubKeyFunc,
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = eCK.BBOOL(true),
        [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.EC_KEY_PAIR_GEN),
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
        [ CKA.ALWAYS_AUTHENTICATE ] = populatePubKeyFunc,
        -- ECC Private Key
        [ CKA.EC_PARAMS ] = populateKeyFunc,
        [ CKA.EC_POINT ] = populateKeyFunc,
        [ CKA.VALUE ] = -1,
    }
end

local function GetECCPubKeyTemplate(populateKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PUBLIC_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(true),
        [ CKA.LABEL ] = populateKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.ECDSA),
        [ CKA.ID ] = populateKeyFunc,
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = eCK.BBOOL(true),
        [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.EC_KEY_PAIR_GEN),
        -- [ CKA.ALLOWED_MECHANISMS ] = '',
        -- Public Key
        [ CKA.SUBJECT ] = '',
        [ CKA.ENCRYPT ] = eCK.BBOOL(true),
        [ CKA.VERIFY ] = eCK.BBOOL(true),
        [ CKA.VERIFY_RECOVER ] = eCK.BBOOL(false),
        [ CKA.WRAP ] = eCK.BBOOL(false),
        [ CKA.TRUSTED ] = eCK.BBOOL(true),
        -- [ CKA.WRAP_TEMPLATE ] = '',
        -- ECC Public Key
        [ CKA.EC_PARAMS ] = populateKeyFunc,
        [ CKA.EC_POINT ] = populateKeyFunc,
    }
end


local function GetDataObjectTemplate(populateKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.DATA),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(true),
        [ CKA.LABEL ] = populateKeyFunc,
        -- Data
        [ CKA.VALUE ] = populateKeyFunc,
        [ CKA.APPLICATION ] = populateKeyFunc,
        [ CKA.OBJECT_ID ] = populateKeyFunc,
    }
end

local function GetSecretKeyTemplate(populatePubKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.SECRET_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(true),
        [ CKA.LABEL ] = populatePubKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.AES),
        [ CKA.ID ] = populatePubKeyFunc,
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = eCK.BBOOL(true),
        [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.AES_KEY_GEN),
        -- [ CKA.ALLOWED_MECHANISMS ] = '',
        -- Private Key
        [ CKA.SUBJECT ] = '',
        [ CKA.SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.DECRYPT ] = eCK.BBOOL(false),
        [ CKA.SIGN ] = eCK.BBOOL(false),
        [ CKA.SIGN_RECOVER ] = eCK.BBOOL(false),
        [ CKA.UNWRAP ] = eCK.BBOOL(false),
        [ CKA.EXTRACTABLE ] = eCK.BBOOL(false),
        [ CKA.ALWAYS_SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.NEVER_EXTRACTABLE ] = eCK.BBOOL(true),
        [ CKA.WRAP_WITH_TRUSTED ] = eCK.BBOOL(false),
        -- [ CKA.UNWRAP_TEMPLATE ] = '',
        [ CKA.ALWAYS_AUTHENTICATE ] = eCK.BBOOL(false),
        --  Private Key
        [ CKA.VALUE ] = -1,
    }
end


function t.mt:get_privkey(hobj, att_type, onlysize, force_all)
    log.output('token-nxp-chipdoc:get_privkey()')
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('token-nxp-chipdoc:get_privkey(): ERROR! not a private key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadere
    end

    log.output('token-nxp-chipdoc:get_privkey(): obj.aid:', hex.hexify(obj.aid or ""))
    if att_type == CKA.MODULUS or att_type == CKA.PUBLIC_EXPONENT then
    
    
        local modulus, pubexp
        local info = self:get_info()
        local mod_label = "modulus_" .. obj.aid .. obj.kid
        local exp_label = "pubexp_" .. obj.aid .. obj.kid
        
        if info and self:cache_enabled() then
            log.output('token-nxp-chipdoc:get_privkey(): trying cache...')
            modulus = utility.cache_read(info.serialNumber, mod_label, self._AvoidUseLastUpdate, self._umcachepath)
            pubexp = utility.cache_read(info.serialNumber, exp_label, self._AvoidUseLastUpdate, self._umcachepath)
        end
        if not modulus and not pubexp then
            log.output('token-nxp-chipdoc:get_privkey(): reading from card...')
            if obj.aid == NXPIASSmartCard.SSCD_AID then
                self.nxp_hcard:perform_mutual_authenticate(obj.aid)
                self.nxp_hcard:select_SSCD()
                self.nxp_hcard:select(obj.path, 1) -- 1 -> select MODE -> DF
                
                local pcRes, theErrorT = pcall(function()
                    modulus, pubexp = self.nxp_hcard:read_public_key(obj.kid)
                end)
                if not pcRes then
                    log.output("token-nxp-chipdoc:get_privkey():read_public_key: error:", debug.traceback(theErrorT) )
                end
            
                self.nxp_hcard:perform_mutual_authenticate()
                self.nxp_hcard:select_Generic()
            else
                
                self.nxp_hcard:select_Generic()
                local pcRes, theErrorT = pcall(function()
                    modulus, pubexp = self.nxp_hcard:read_public_key(obj.kid)
                end)
                if not pcRes then
                    log.output("token-nxp-chipdoc:get_privkey():read_public_key: error:", debug.traceback(theErrorT) )
                end

            end
            if modulus and pubexp and info and self:cache_enabled() then
                log.output("token-nxp-chipdoc:get_privkey():read_public_key: updating cache...")
                utility.cache_write(info.serialNumber, mod_label, modulus, self._umcachepath)
                utility.cache_write(info.serialNumber, exp_label, pubexp, self._umcachepath)
            end
        end
        obj[CKA.MODULUS] = modulus
        obj[CKA.PUBLIC_EXPONENT] = pubexp or hex.hexf('010001')
    end
    
    obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
    obj[CKA.SIGN] = eCK.BBOOL(true)
    
    obj[CKA.SIGN_RECOVER] = eCK.BBOOL(false)
    obj[CKA.VERIFY] = eCK.BBOOL(false)
    obj[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    obj[CKA.UNWRAP] = eCK.BBOOL(false)
    
    obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
    obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(obj.userConsent)
    obj[CKA.DECRYPT] = eCK.BBOOL(not obj.userConsent)
    
    obj.populated = true
    return CKR.OK, obj[att_type]
end


function t.mt:get_secret_key(hobj, att_type, onlysize, force_all)
    log.output('token-nxp-chipdoc:get_secret_key()')
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.SECRET_KEY) then
        log.output('token-nxp-chipdoc:get_secret_key(): ERROR! not a secret key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadere
    end

    local value = obj.value or ""

    obj[CKA.KEY_TYPE] = eCK.ULONG(CKK.AES)

    obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
    
    obj[CKA.SIGN] = eCK.BBOOL(false)
    obj[CKA.SIGN_RECOVER] = eCK.BBOOL(false)
    obj[CKA.VERIFY] = eCK.BBOOL(false)
    obj[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    obj[CKA.UNWRAP] = eCK.BBOOL(false)
    obj[CKA.WRAP] = eCK.BBOOL(false)
    
    obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
    obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
    obj[CKA.DECRYPT] = eCK.BBOOL(true)
    obj[CKA.ENCRYPT] = eCK.BBOOL(true)
    
    obj.populated = true
    return CKR.OK, obj[att_type]
end


function t.mt:get_pubkey(hobj, att_type, onlysize, force_all)
    log.output('token-nxp-chipdoc:get_pubkey()')
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PUBLIC_KEY) then
        log.output('token-nxp-chipdoc:get_pubkey(): ERROR! not a public key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadere
    end
    
    log.output('token-nxp-chipdoc:get_pubkey(): obj.aid:', hex.hexify(obj.aid or ""))
    if att_type == CKA.MODULUS or att_type == CKA.PUBLIC_EXPONENT then
    
        local modulus, pubexp
        local info = self:get_info()
        local mod_label = "modulus_" .. obj.aid .. obj.kid
        local exp_label = "pubexp_" .. obj.aid .. obj.kid
        
        if info and self:cache_enabled() then
            log.output('token-nxp-chipdoc:get_pubkey(): trying cache...')
            modulus = utility.cache_read(info.serialNumber, mod_label, self._AvoidUseLastUpdate, self._umcachepath)
            pubexp = utility.cache_read(info.serialNumber, exp_label, self._AvoidUseLastUpdate, self._umcachepath)
        end
        if not modulus and not pubexp then
            log.output('token-nxp-chipdoc:get_pubkey(): reading from card...')
            if obj.aid == NXPIASSmartCard.SSCD_AID then
                self.nxp_hcard:perform_mutual_authenticate(obj.aid)
                self.nxp_hcard:select_SSCD()
                self.nxp_hcard:select(obj.path, 1) -- 1 -> select MODE -> DF
                
                local pcRes, theErrorT = pcall(function()
                    modulus, pubexp = self.nxp_hcard:read_public_key(obj.kid)
                end)
                if not pcRes then
                    log.output("token-nxp-chipdoc:get_pubkey():read_public_key: error:", debug.traceback(theErrorT) )
                end
            
                self.nxp_hcard:perform_mutual_authenticate()
                self.nxp_hcard:select_Generic()
            else
                
                self.nxp_hcard:select_Generic()
                local pcRes, theErrorT = pcall(function()
                    modulus, pubexp = self.nxp_hcard:read_public_key(obj.kid)
                end)
                if not pcRes then
                    log.output("token-nxp-chipdoc:get_pubkey():read_public_key: error:", debug.traceback(theErrorT) )
                end

            end
            if modulus and pubexp and info and self:cache_enabled() then
                log.output("token-nxp-chipdoc:get_pubkey():read_public_key: updating cache...")
                utility.cache_write(info.serialNumber, mod_label, modulus, self._umcachepath)
                utility.cache_write(info.serialNumber, exp_label, pubexp, self._umcachepath)
            end
        end
        obj[CKA.MODULUS] = modulus
        obj[CKA.PUBLIC_EXPONENT] = pubexp or hex.hexf('010001')
    end
    
    obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
    obj[CKA.VERIFY] = eCK.BBOOL(true)
    obj[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    obj[CKA.ENCRYPT] = eCK.BBOOL(not obj.userConsent)
    obj[CKA.WRAP] = eCK.BBOOL(false)

    obj.populated = true
    return CKR.OK, obj[att_type]
    
end


function t.mt:get_ecc_privkey(hobj, att_type, onlysize, force_all)
    log.output('token-nxp-chipdoc:get_ecc_privkey()')
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('token-nxp-chipdoc:get_ecc_privkey(): ERROR! not a private key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadere
    end

    if att_type == CKA.EC_POINT then
    
        local ec_point
        local info = self:get_info()
        local ec_point_label = "ec_point_" .. obj.aid .. obj.kid
        
        if info and self:cache_enabled() then
            log.output('token-nxp-chipdoc:get_ecc_privkey(): trying cache...')
            ec_point = utility.cache_read(info.serialNumber, ec_point_label, self._AvoidUseLastUpdate, self._umcachepath)
        end
        if not ec_point then
            log.output('token-nxp-chipdoc:get_ecc_privkey(): reading from card...')
            if obj.aid == NXPIASSmartCard.SSCD_AID then
                self.nxp_hcard:perform_mutual_authenticate(obj.aid)
                self.nxp_hcard:select_SSCD()
                self.nxp_hcard:select(obj.path, 1) -- 1 -> select MODE -> DF
                
                local pcRes, theErrorT = pcall(function()
                    ec_point = self.nxp_hcard:read_public_key_ECC(obj.kid)
                end)
                if not pcRes then
                    log.output("token-nxp-chipdoc:get_ecc_privkey():read_public_key_ECC: error:", debug.traceback(theErrorT) )
                end
            
                self.nxp_hcard:perform_mutual_authenticate()
                self.nxp_hcard:select_Generic()
            else
                
                self.nxp_hcard:select_Generic()
                local pcRes, theErrorT = pcall(function()
                    ec_point = self.nxp_hcard:read_public_key_ECC(obj.kid, nil, true)
                end)
                if not pcRes then
                    log.output("token-nxp-chipdoc:get_ecc_privkey():read_public_key_ECC: error:", debug.traceback(theErrorT) )
                end

            end
            if ec_point and info and self:cache_enabled() then
                log.output("token-nxp-chipdoc:get_ecc_privkey():read_public_key_ECC: updating cache...")
                utility.cache_write(info.serialNumber, ec_point_label, ec_point, self._umcachepath)
            end
        end
        obj[CKA.EC_POINT] = der.build(der.STRING, ec_point)
    end
    
    obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
    obj[CKA.SIGN] = eCK.BBOOL(true)
    
    obj[CKA.SIGN_RECOVER] = eCK.BBOOL(false)
    obj[CKA.VERIFY] = eCK.BBOOL(false)
    obj[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    obj[CKA.UNWRAP] = eCK.BBOOL(false)
    
    obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
    obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
    obj[CKA.DECRYPT] = eCK.BBOOL(false)
    
    obj.populated = true
    return CKR.OK, obj[att_type]
end


function t.mt:get_ecc_pubkey(hobj, att_type, onlysize, force_all)
    log.output('token-nxp-chipdoc:get_ecc_pubkey()')
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PUBLIC_KEY) then
        log.output('token-nxp-chipdoc:get_ecc_pubkey(): ERROR! not a public key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadere
    end
    
    if att_type == CKA.EC_POINT then
    
        local ec_point
        local info = self:get_info()
        local ec_point_label = "ec_point_" .. obj.aid .. obj.kid
        
        if info and self:cache_enabled() then
            log.output('token-nxp-chipdoc:get_ecc_pubkey(): trying cache...')
            ec_point = utility.cache_read(info.serialNumber, ec_point_label, self._AvoidUseLastUpdate, self._umcachepath)
        end
        if not ec_point then
            log.output('token-nxp-chipdoc:get_ecc_pubkey(): reading from card...')
            if obj.aid == NXPIASSmartCard.SSCD_AID then
                self.nxp_hcard:perform_mutual_authenticate(obj.aid)
                self.nxp_hcard:select_SSCD()
                self.nxp_hcard:select(obj.path, 1) -- 1 -> select MODE -> DF
                
                local pcRes, theErrorT = pcall(function()
                    ec_point = self.nxp_hcard:read_public_key_ECC(obj.kid)
                end)
                if not pcRes then
                    log.output("token-nxp-chipdoc:get_ecc_pubkey():read_public_key_ECC: error:", debug.traceback(theErrorT) )
                end
            
                self.nxp_hcard:perform_mutual_authenticate()
                self.nxp_hcard:select_Generic()
            else
                
                self.nxp_hcard:select_Generic()
                local pcRes, theErrorT = pcall(function()
                    ec_point = self.nxp_hcard:read_public_key_ECC(obj.kid, nil, true)
                end)
                if not pcRes then
                    log.output("token-nxp-chipdoc:get_ecc_pubkey():read_public_key_ECC: error:", debug.traceback(theErrorT) )
                end

            end
            if modulus and pubexp and info and self:cache_enabled() then
                log.output("token-nxp-chipdoc:get_ecc_pubkey():read_public_key_ECC: updating cache...")
                utility.cache_write(info.serialNumber, ec_point_label, ec_point, self._umcachepath)
            end
        end
        obj[CKA.EC_POINT] = der.build(der.STRING, ec_point)
    end
    
    obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
    obj[CKA.VERIFY] = eCK.BBOOL(true)
    obj[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    obj[CKA.ENCRYPT] = eCK.BBOOL(false)
    obj[CKA.WRAP] = eCK.BBOOL(false)

    obj.populated = true
    return CKR.OK, obj[att_type]
    
end

function t.mt:get_certificate(hobj, att_type, onlysize, force_all)
    log.output('token-nxp-chipdoc:get_certificate()')
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.CERTIFICATE) then
        log.output('get_certificate(): ERROR! not a certificate object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadere
    end

    local info = self:get_info()

    
    local cert_value
    
    if info and self:cache_enabled() then
        log.output('token-nxp-chipdoc:get_certificate(): trying cache...')
        cert_value = utility.cache_read(info.serialNumber, obj.path, self._AvoidUseLastUpdate, self._umcachepath)

    end
    if not cert_value then
        log.output('token-nxp-chipdoc:get_certificate(): reading fresh value frpm card...')
        self.nxp_hcard:select_Generic()
        cert_value = self.nxp_hcard:read_cert(obj.path)
        if info and self:cache_enabled() then
            utility.cache_write(info.serialNumber, obj.path, cert_value, self._umcachepath)
        end
    end
    log.output("token-nxp-chipdoc:get_certificate(): cert value:", hex.hexify(cert_value))
    
    local parsed_cer = der.parse_x509cer(cert_value)
    obj[CKA.VALUE] = cert_value or obj[CKA.VALUE]
    obj[CKA.SUBJECT] = (parsed_cer and parsed_cer.subject) or ''
    obj[CKA.ISSUER] = (parsed_cer and parsed_cer.issuer) or ''
    obj[CKA.SERIAL_NUMBER] = (parsed_cer and parsed_cer.serialNumber) or ''
    obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
    obj[CKA.TRUSTED]    = eCK.BBOOL(false)
    
    obj.populated = true
    return CKR.OK, obj[att_type]
end

function t.mt:get_data_object(hobj, att_type, onlysize, force_all)
    log.output('token-nxp-chipdoc:get_data_object(): att_type', att_type)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local obj = self.attributes[hobj]
    local value = ''
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.DATA) then
        log.output('get_data_object(): ERROR! not a DATA object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadere
    end
    
    local pcRes, theErrorT = pcall(function()
        -- self.aet_hcard:select(obj.path, true)  -- fid, relative
        self.nxp_hcard:select_Generic() -- TODO: not always required
        local value = self:read_cached_file(obj.path, 0, -1, true)
        
        obj[CKA.VALUE] = value
        obj.populated = true
    end)
    if not pcRes then
        log.output('token-nxp-chipdoc:get_data_object(): error:', debug.traceback(theErrorT))
        if att_type == CKA.VALUE then
            return CKR.FUNCTION_FAILED
        end
    end
    return CKR.OK, obj[att_type]
end


function t.mt:cache_enabled()
    return utility.cache_can_use() and self.cfg["fastread"]=='true' or self.cfg["ofastread"]=='true'
end

function t.mt:cache_clear()
    if self:cache_enabled() then
        log.output('token-nxp-chipdoc:cache_clear(): removing whole cache...')
        -- elimina tutta la cache statica del token
        local info = self:get_info()
        log.output('removing cache for serial', info.serialNumber)
        utility.cache_write(info.serialNumber, nil, nil, self._umcachepath)
    end
end

function  t.mt:read_cached_file(fid, offset, count, update_cache)
    local val
    log.output(string.format("token-nxp-chipdoc:read_cached_file: fid=%s, offset=%d, count=%d, update_cache=%s", hex.hexify(fid), offset, count, tostring(update_cache)) )
    local info = self.info
    if self:cache_enabled() and info then
        log.output("token-nxp-chipdoc:read_cached_file: trying cache...")
        local val_full = utility.cache_read(info.serialNumber, fid, self._AvoidUseLastUpdate, self._umcachepath)
        log.output(string.format("token-nxp-chipdoc:read_cached_file: full cached value=%s", hex.hexify(val_full or "")) )
        if val_full and (  (count<0 and string.len(val_full) >= (offset)) 
                        or (count>=0 and string.len(val_full) >= (offset+count)) )then
            local stop = offset+count
            if count < 0 then
                stop = -1
            end
            val = string.sub(val_full, offset+1, stop)
            log.output(string.format("token-nxp-chipdoc:read_cached_file: returning cached value=%s from offset=%d to %d", hex.hexify(val), offset+1, stop) )
            return val
        end
    end
    
    log.output("token-nxp-chipdoc:read_cached_file: reading from card")
    local finfo = self.nxp_hcard:select(fid, true)
    if not finfo then
        finfo = {size=255}
    end
    if count < 0 then
        count = finfo.size
    end
    log.output(string.format("token-nxp-chipdoc:read_cached_file: reading from card: count=%d", count))
    val = self.nxp_hcard:mread_binary_smart(offset, count)
    if string.len(val) < count then
        val = val .. string.rep("\0", count - string.len(val) )
    end
    log.output(string.format("token-nxp-chipdoc:read_cached_file: got fresh value=%s", hex.hexify(val)) )
    if info and update_cache and self:cache_enabled() then
        log.output("token-nxp-chipdoc:read_cached_file: updating cache")
        log.output("token-nxp-chipdoc:read_cached_file: serialNumber: ", info.serialNumber)
        utility.cache_write(info.serialNumber, fid, val, self._umcachepath)
    end
    return val  
end

function t.mt:read_cache_version()
    return self:read_cache_version_file()
end

function t.mt:read_cache_version_file()

    local pcRes, contents = pcall(function()
        self.nxp_hcard:select_Generic()
        local cia_infoD = self.nxp_hcard:read_binary_sfi( self.files.tokenInfo_sfi, 0, 128)
        local cia_info = p15.parse_tokenInfo(cia_infoD)
        local offset = string.find(cia_infoD, cia_info.lastUpdate, 1, false)
        if offset then
            log.output("token-nxp-chipdoc:read_cache_version_file() old tokenInfo_lastModified_offset:", self.files.tokenInfo_lastModified_offset)
            self.files.tokenInfo_lastModified_offset = offset-1
            log.output("token-nxp-chipdoc:read_cache_version_file() new tokenInfo_lastModified_offset:", self.files.tokenInfo_lastModified_offset)
        end
        log.output("token-nxp-chipdoc:read_cache_version_file() old tokenInfo_lastModified_size:", self.files.tokenInfo_lastModified_size)
        self.files.tokenInfo_lastModified_size = string.len(cia_info.lastUpdate)
        log.output("token-nxp-chipdoc:read_cache_version_file() new tokenInfo_lastModified_size:", self.files.tokenInfo_lastModified_size)

        self.cia_info = cia_info
        return cia_info.lastUpdate
    end)
    if not pcRes then
        log.output("token-nxp-chipdoc:read_cache_version_file() error:", debug.traceback(contents))
    end
    return contents
end

function t.mt:write_cache_version_file(value)
    
    log.output('token-nxp-chipdoc:write_cache_version_file():')
    
    if not value then
        local curTime = os.date ("!*t")
        value = string.format("%04d%02d%02d%02d%02d%02d", curTime.year, curTime.month, curTime.day, curTime.hour, curTime.min, curTime.sec)
        log.output('token-nxp-chipdoc:write_cache_version_file(): using cur time:', value)
    elseif string.len(value) ~= self.files.tokenInfo_lastModified_size then
        log.output('token-nxp-chipdoc:write_cache_version_file(): invalid value len')
        error("token-nxp-chipdoc:write_cache_version_file(): value len invalid, EXPECTED: " .. self.files.tokenInfo_lastModified_size)
    end
    
    local pcRes, theErrorT = pcall(function()
        self.nxp_hcard:select_Generic()
        return self.nxp_hcard:mupdate_binary(
                self.files.tokenInfo_lastModified_offset,
                value,
                nil,
                self.files.tokenInfo_sfi)
    end)
    if not pcRes then
        log.output('token-nxp-chipdoc:write_cache_version_file(): error:', debug.traceback(theErrorT))
    else
        log.output('token-nxp-chipdoc:write_cache_version_file(): successfully wrote value:', value)
    end
   return value
end


function t.mt:check_clear_cache(clear_memory_cache)
    log.output('token-nxp-chipdoc:check_clear_cache():', clear_memory_cache)
    
    local info = self.info
    if info and self:cache_enabled() then
    
        if self._clear_cache then
            log.output('token-nxp-chipdoc:check_clear_cache(): self._clear_cache is set, flushing whole cache...')
            utility.cache_write(info.serialNumber, nil, nil, self._umcachepath)
            self._clear_cache = false
        end
        
        local cache_name = "CACHE_ID"
        local val_cached = utility.cache_read(info.serialNumber, cache_name, true, self._umcachepath)
        
        local val_fresh = self:read_cache_version_file()
        
        log.output(string.format('token-nxp-chipdoc:check_clear_cache(): val_cached=%s, val_fresh=%s, ', hex.hexify(val_cached or ""), hex.hexify(val_fresh or "")))
        
        if not val_fresh then
            log.output('token-nxp-chipdoc:check_clear_cache(): unable to read fresh cache version file')
            return
        end
        
        if val_fresh ~= val_cached then
            log.output('token-nxp-chipdoc:check_clear_cache(): cache changed, clearing permament cache for serialNumber:', info.serialNumber)
            utility.cache_write(info.serialNumber, nil, nil, self._umcachepath)
            utility.cache_write(info.serialNumber, cache_name, val_fresh, self._umcachepath)

        end
        if clear_memory_cache and self.cache_id_val and self.cache_id_val ~= val_fresh then
            log.output('token-nxp-chipdoc:check_clear_cache(): clearing internal memory cache')
            self.info = nil -- rimuove cache oggetti
            self._indexes = nil
            self.attributes = self:get_objects()  -- riscostruisce cache oggetti
        end
        self.cache_id_val = val_fresh
    else
        log.output('token-nxp-chipdoc:check_clear_cache(): cache enabled:', self:cache_enabled())
    end
end

function t.mt:update_cache_id()

    log.output("token-nxp-chipdoc:update_cache_id():")
    local val_fresh_new

    local info = self.info
    if info then       
        val_fresh_new = self:write_cache_version_file()
        log.output('token-nxp-chipdoc:update_cache_id(): wrote new cache id to card:', hex.hexify(val_fresh_new or ""))
        log.output('token-nxp-chipdoc:update_cache_id(): clearing permament cache for serialNumber:', info.serialNumber)
        utility.cache_write(info.serialNumber, nil, nil, self._umcachepath)
        self.cache_id_val = val_fresh_new or self.cache_id_val
    end
    return val_fresh_new
end

local function decode_bool_attributes(classAttributes, obj)
    if classAttributes.usage then
        p15.decode_KeyUsageFlags(classAttributes.usage, obj)
    end
    if classAttributes.accessFlags then
        p15.decode_KeyAccessFlags(classAttributes.accessFlags, obj)
    end
end

function t.mt:_add_objects(objects)
    log.output("token-nxp-chipdoc:_add_objects()")

    self.nxp_hcard:select_Generic()

    
    -- local ef_od = self.nxp_hcard:read_binary_sfi(tonumber("11", 16), 0, 0)
    -- log.output ("ef_od:", hex.hexify(ef_od))
    
    -- local cia_info = self.nxp_hcard:read_binary_sfi(tonumber("12", 16), 0, 0)
    -- log.output ("cia_info:", hex.hexify(cia_info))
    
    -- local finfos = self.nxp_hcard:select(tonumber("7001", 16), true, true)
    -- log.output ("finfos 7001 AOD:", util.repr(finfos))

    -- local AOD = self.nxp_hcard:mread_binary_smart(0, finfos.size, true)
    -- local AODInfo = p15.parseAuthObjects(AOD)
    -- for i, v in AODInfo do
        -- for x, y in v do
            -- log.output("\t", x, utility.repr(y))
        -- end
    -- end
    

    -- local finfos = self.nxp_hcard:select(tonumber("7004", 16), true, true)
    -- log.output ("finfos 7004 PubKD:", util.repr(finfos))

    -- local PrKD = self.nxp_hcard:mread_binary_smart(0, finfos.size, true)
    -- local PrKDInfo = p15.parsePubPrivKD(PrKD)
    -- for i, v in PrKDInfo do
        -- for x, y in v do
            -- log.output ("\t", x, utility.repr(y))
        -- end
    -- end
    
    -- local finfos = self.nxp_hcard:select(tonumber("7002", 16), true)
    -- log.output ("finfos 7002 PrKD:", util.repr(finfos))

    -- local PrKD = self.nxp_hcard:mread_binary_smart(0, finfos.size)

    -- local cia_info = self:read_cached_file(self.files.tokenInfo, 0, -1, true)
    

    local PubKD = self:read_cached_file(self.files.PubKD, 0, -1, true)
    local PrKD = self:read_cached_file(self.files.PrivKD, 0, -1, true)
    local secretKD = self:read_cached_file(self.files.secretKD, 0, -1, true)
    local certD = self:read_cached_file(self.files.CDF, 0, -1, true)
    local dataD = self:read_cached_file(self.files.dataDF, 0, -1, true)
    
    
    self._indexes = {}
    self._indexes._public_keys_bin = PubKD
    self._indexes._private_keys_bin = PrKD
    self._indexes._certificates_bin = certD
    self._indexes._secret_keys_bin = secretKD
    self._indexes._data_objects_bin = dataD

    local secretKDInfo = p15.parsePubPrivKD(secretKD)
    for i, v in secretKDInfo do
        local proceed = true
        for x, y in v do
            log.output ("\t", x, utility.repr(y))
        end
        log.output ("evaluating secret key:", i)
        log.output ("efidOrPath:", v.typeAttributes.path.efidOrPath_tag, hex.hexify(v.typeAttributes.path.efidOrPath) )
        -- print ("efidOrPath:", hex.hexify(v.typeAttributes.path.efidOrPath), v.typeAttributes.path.efidOrPath_tag)
        -- print ("modulusLength:", v.typeAttributes.modulusLength)
        -- print ("userConsent:", v.commonObjectAttributes.userConsent)
        -- print ("keyReference:", v.classAttributes.keyReference)
        -- print ("label:", v.commonObjectAttributes.label)
        -- print ("iD:", v.classAttributes.iD)
        
        local obj
  
        if v.typeAttributes.path.efidOrPath_tag == der.STRING then
            log.output ("obj EF ID (not used):", hex.hexify(v.typeAttributes.path.efidOrPath))
        else
            log.output ("unknown efidOrPath_tag:", v.typeAttributes.path.efidOrPath_tag, hex.hexify(v.typeAttributes.path.efidOrPath))
            proceed = false
        end
        if proceed and v.typeAttributes.modulusLength then
            obj = GetSecretKeyTemplate(t.mt.get_secret_key)
            obj.aid = NXPIASSmartCard.Generic_AID
            log.output ("SECRET key label:", v.commonObjectAttributes.label)
            log.output ("SECRET key iD:", v.classAttributes.iD)
            log.output ("SECRET obj AID:", hex.hexify(obj.aid))
            obj.userConsent = v.commonObjectAttributes.userConsent
            obj.asn1 = v
            obj.kid = v.classAttributes.keyReference
            obj.key_bits = v.typeAttributes.modulusLength
            
            local fid = hex.hexf("DA%B", tonumber("EF", 16) +  obj.kid) -- secret key files: DA01 - DA10
            obj.path = fid
            
            log.output("parsing key fid:", hex.hexify(obj.path))
            local pcRes, theErrorT pcall(function()
                local e_value = self:read_cached_file(obj.path, 0, -1, true)
                log.output ("e_value:", hex.hexify(e_value or ""))
                
                obj.value = aes.aes_decrypt_check(self._mk, e_value, "00000001")
                log.output ("value:", hex.hexify(obj.value or ""))
                
            end)
            
            if not pcRes then
                log.output ("parse secret key error:", debug.traceback(theErrorT))
            end
  
                
            obj.num = i
            objects.max_index = objects.max_index +1
            objects[ objects.max_index] = obj
            log.output(
                string.format("_add_objects(): added secret key: num:%d kid:%d bits:%d handle:%d", 
                    obj.num, obj.kid, obj.key_bits, objects.max_index)
                )

        else
            log.output ("secret key object discarded!")
        end
        
        if obj then
            decode_bool_attributes(v.classAttributes, obj)
            obj.private = true
            obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
            obj[CKA.LABEL] = v.commonObjectAttributes.label
            obj[CKA.ID] = v.classAttributes.iD
        end
    end
    
    
    local PrKDInfo = p15.parsePubPrivKD(PrKD)
    for i, v in PrKDInfo do
        local proceed = true
        for x, y in v do
            log.output ("\t", x, utility.repr(y))
        end
        log.output ("evaluating private key:", i)
        log.output ("efidOrPath:", v.typeAttributes.path.efidOrPath_tag, hex.hexify(v.typeAttributes.path.efidOrPath) )
        -- print ("efidOrPath:", hex.hexify(v.typeAttributes.path.efidOrPath), v.typeAttributes.path.efidOrPath_tag)
        -- print ("modulusLength:", v.typeAttributes.modulusLength)
        -- print ("userConsent:", v.commonObjectAttributes.userConsent)
        -- print ("keyReference:", v.classAttributes.keyReference)
        -- print ("label:", v.commonObjectAttributes.label)
        -- print ("iD:", v.classAttributes.iD)
        
        local obj
        local aid = NXPIASSmartCard.Generic_AID
        local path
        if v.typeAttributes.path.efidOrPath_tag == der.CONTEXT(2) then
            aid = NXPIASSmartCard.SSCD_AID
            local seqPath = der.parse(v.typeAttributes.path.efidOrPath)
            if seqPath[1].tag == der.APPLICATION(15) and seqPath[2].tag == der.STRING and  seqPath[3].tag == der.STRING then
                local ef_id = string.sub(seqPath[3].value, -2, -1)
                path = string.sub(seqPath[3].value, 1, -3)
                
                log.output ("SSCD obj ID (not used):", hex.hexify(seqPath[2].value))
                log.output ("SSCD obj EF ID (not used):", hex.hexify(ef_id))
                log.output ("SSCD obj path:", hex.hexify(path))
            else
                log.output ("SSCD invalid obj efidOrPath:", hex.hexify(v.typeAttributes.path.efidOrPath))
            
            end
        elseif v.typeAttributes.path.efidOrPath_tag == der.STRING then
            log.output ("obj EF ID (not used):", hex.hexify(v.typeAttributes.path.efidOrPath))
        else
            log.output ("unknown efidOrPath_tag:", v.typeAttributes.path.efidOrPath_tag, hex.hexify(v.typeAttributes.path.efidOrPath))
            proceed = false
        end
        if proceed and v.typeAttributes.modulusLength then
            obj = GetPrivKeyTemplate(t.mt.get_privkey)
            obj.path = path
            obj.aid = aid
            log.output ("RSA key label:", v.commonObjectAttributes.label)
            log.output ("RSA key iD:", v.classAttributes.iD)
            log.output ("RSA obj AID:", hex.hexify(obj.aid))
            obj.userConsent = v.commonObjectAttributes.userConsent
            obj.asn1 = v
            obj.kid = v.classAttributes.keyReference
            obj.key_bits = v.typeAttributes.modulusLength
            obj[CKA.MODULUS_BITS] = obj.key_bits
            obj.num = i
            objects.max_index = objects.max_index +1
            objects[ objects.max_index] = obj
            log.output(
                string.format("_add_objects(): added private key: num:%d kid:%d bits:%d handle:%d", 
                    obj.num, obj.kid, obj.key_bits, objects.max_index)
                )
        elseif proceed and v.typeAttributes.parameters then
            obj = GetECCPrivKeyTemplate(t.mt.get_ecc_privkey)
            obj.path = path
            obj.aid = aid
            log.output ("ECC key label:", v.commonObjectAttributes.label)
            log.output ("ECC key iD:", v.classAttributes.iD)
            log.output ("ECC obj AID:", hex.hexify(obj.aid))
            obj.userConsent = v.commonObjectAttributes.userConsent
            obj.asn1 = v
            obj.kid = v.classAttributes.keyReference
            obj.parameters = v.typeAttributes.parameters
            obj[CKA.EC_PARAMS] = obj.parameters
            obj.num = i
            objects.max_index = objects.max_index +1
            objects[ objects.max_index] = obj
            log.output(
                string.format("_add_objects(): added ECC private key: num:%d kid:%d EC_PARAMS:%s (%s) handle:%d", 
                    obj.num, obj.kid, hex.hexify(obj.parameters), der.der_oid_to_ascii_oid(obj.parameters), objects.max_index)
                )
        else
            log.output ("private key object discarded!")
        end
        
        if obj then
            decode_bool_attributes(v.classAttributes, obj)
            obj.private = true
            obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
            obj[CKA.LABEL] = v.commonObjectAttributes.label
            obj[CKA.ID] = v.classAttributes.iD
        end
    end
    
    local PubKDInfo = p15.parsePubPrivKD(PubKD)
    for i, v in PubKDInfo do
        local proceed = true
        for x, y in v do
            log.output ("\t", x, utility.repr(y))
        end
        log.output ("evaluating public key:", i)
        log.output ("efidOrPath:", v.typeAttributes.path.efidOrPath_tag, hex.hexify(v.typeAttributes.path.efidOrPath) )
        -- print ("efidOrPath:", hex.hexify(v.typeAttributes.path.efidOrPath), v.typeAttributes.path.efidOrPath_tag)
        -- print ("modulusLength:", v.typeAttributes.modulusLength)
        -- print ("userConsent:", v.commonObjectAttributes.userConsent)
        -- print ("keyReference:", v.classAttributes.keyReference)
        -- print ("label:", v.commonObjectAttributes.label)
        -- print ("iD:", v.classAttributes.iD)
        
        local obj
        local aid = NXPIASSmartCard.Generic_AID
        local path
        if v.typeAttributes.path.efidOrPath_tag == der.CONTEXT(2) then
            aid = NXPIASSmartCard.SSCD_AID
            local seqPath = der.parse(v.typeAttributes.path.efidOrPath)
            if seqPath[1].tag == der.APPLICATION(15) and seqPath[2].tag == der.STRING and  seqPath[3].tag == der.STRING then
                local ef_id = string.sub(seqPath[3].value, -2, -1)
                path = string.sub(seqPath[3].value, 1, -3)
                
                log.output ("SSCD obj ID (not used):", hex.hexify(seqPath[2].value))
                log.output ("SSCD obj EF ID (not used):", hex.hexify(ef_id))
                log.output ("SSCD obj path:", hex.hexify(path))
            else
                log.output ("SSCD invalid obj efidOrPath:", hex.hexify(v.typeAttributes.path.efidOrPath))
            
            end
        elseif v.typeAttributes.path.efidOrPath_tag == der.STRING then
            log.output ("obj EF ID (not used):", hex.hexify(v.typeAttributes.path.efidOrPath))
        else
            log.output ("unknown efidOrPath_tag:", v.typeAttributes.path.efidOrPath_tag, hex.hexify(v.typeAttributes.path.efidOrPath))
            proceed = false
        end
        if proceed and v.typeAttributes.modulusLength then
            obj = GetPubKeyTemplate(t.mt.get_pubkey)
            obj.path = path
            obj.aid = aid
            log.output ("RSA key label:", v.commonObjectAttributes.label)
            log.output ("RSA key iD:", v.classAttributes.iD)
            log.output ("RSA obj AID:", hex.hexify(obj.aid))
            
            obj.asn1 = v
            obj.kid = v.classAttributes.keyReference
            obj.key_bits = v.typeAttributes.modulusLength
            obj[CKA.MODULUS_BITS] = obj.key_bits
            obj.num = i
            objects.max_index = objects.max_index +1
            objects[ objects.max_index] = obj
            log.output(
                string.format("_add_objects(): added RSA public key: num:%d kid:%d bits:%d handle:%d", 
                    obj.num, obj.kid, obj.key_bits, objects.max_index)
                )
        elseif proceed and v.typeAttributes.parameters then
            obj = GetECCPubKeyTemplate(t.mt.get_ecc_pubkey)
            obj.path = path
            obj.aid = aid
            log.output ("ECC key label:", v.commonObjectAttributes.label)
            log.output ("ECC key iD:", v.classAttributes.iD)
            log.output ("ECC obj AID:", hex.hexify(obj.aid))
            
            obj.asn1 = v
            obj.kid = v.classAttributes.keyReference
            obj.parameters = v.typeAttributes.parameters
            obj[CKA.EC_PARAMS] = obj.parameters
            obj.num = i
            objects.max_index = objects.max_index +1
            objects[ objects.max_index] = obj
            log.output(
                string.format("_add_objects(): added ECC public key: num:%d kid:%d EC_PARAMS:%s (%s) handle:%d", 
                    obj.num, obj.kid, hex.hexify(obj.parameters), der.der_oid_to_ascii_oid(obj.parameters), objects.max_index)
                )
        else
            log.output ("public key object discarded: ", v.commonObjectAttributes.label)
        end
        if obj then
            decode_bool_attributes(v.classAttributes, obj)
            obj.private = false
            obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
            obj[CKA.LABEL] = v.commonObjectAttributes.label
            obj[CKA.ID] = v.classAttributes.iD
        end
    end
    
    -- local finfos = self.nxp_hcard:select(tonumber("7005", 16), true)
    -- log.output ("finfos 7005 certD:", util.repr(finfos))
    
    -- local certD = self.nxp_hcard:mread_binary_smart(0, finfos.size)
    
    
    
    local certDInfo = p15.parseCertDF(certD)
    
    for i, v in certDInfo do
        log.output ("evaluating cert:", i)
    
        log.output(string.format("cert %d path:", i), hex.hexify(certDInfo[i].typeAttributes.path.efidOrPath))

        for x, y in v do
            log.output ("\t", x, utility.repr(y))
        end
        
        local obj = GetCertTemplate(t.mt.get_certificate)
        obj.private = false
        obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
        
        log.output ("cert label:", v.commonObjectAttributes.label)
        log.output ("cert iD:", v.classAttributes.iD)
        
        obj[CKA.LABEL] = v.commonObjectAttributes.label
        obj[CKA.ID] = v.classAttributes.iD
        obj.aid = NXPIASSmartCard.Generic_AID
        obj.path = certDInfo[i].typeAttributes.path.efidOrPath
        obj.num = i
        objects.max_index = objects.max_index +1
        objects[ objects.max_index] = obj
        log.output(
            string.format("_add_objects(): added certificate: num:%d , path=%s, handle:%d", 
                obj.num, hex.hexify(obj.path), objects.max_index)
            )
    end


    if self._indexes._data_objects_bin then
        log.output("adding data objects...")
        local d = p15.parsePubPrivDataD(self._indexes._data_objects_bin)
        for i, v in d do
            
            log.output(string.format("data object %d:", i))
            
            for x, y in v do
                log.output ("\t", x, utility.repr(y))
            end
            
            if not v.typeAttributes.path or type(v.typeAttributes.path.efidOrPath) ~= "string"
                or string.len(v.typeAttributes.path.efidOrPath) < 2 then
                
                log.output ("_add_objects(): jumping data object with invalid path!")
            else
                
                local fid =  string.sub(v.typeAttributes.path.efidOrPath, -2, -1)
                if fid == hex.hexf("DC00") or fid == hex.hexf("DC01") or fid == hex.hexf("DC02") then
                     log.output ("_add_objects(): jumping reserved FID:", hex.hexify(v.typeAttributes.path.efidOrPath))
                else
                    local obj = GetDataObjectTemplate(t.mt.get_data_object)

                    if v.commonObjectAttributes.flags then
                        p15.decode_CommonFlags(v.commonObjectAttributes.flags, obj)
                    else
                        log.output("_add_objects(): forcing data object as private")
                        obj[CKA.PRIVATE] = eCK.BBOOL(true)
                        obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
                    end
                    
                    obj.private = obj[CKA.PRIVATE] and obj[CKA.PRIVATE] ~= eCK.BBOOL(false)
                    log.output("_add_objects():data object is private:", obj.private)
                    
                    obj[CKA.LABEL] = v.commonObjectAttributes.label
                    obj[CKA.APPLICATION] = v.classAttributes.applicationName
                    obj[CKA.OBJECT_ID] = v.classAttributes.applicationOID

                    obj.path = v.typeAttributes.path.efidOrPath
                    obj.num = i
                    
                    objects.max_index = objects.max_index +1
                    objects[ objects.max_index] = obj
                    log.output(
                        string.format("_add_objects(): added data object: num:%d handle:%d", 
                            obj.num, objects.max_index)
                        )
               end
            end
        end
    end
    
end


function t.mt:get_objects()
    log.output('token-nxp-chipdoc:get_objects()')
    
    self.nxp_hcard:auto_perform_mutual_authenticate(true) -- check/restore Generic SM session, checkOnActiveSMOnly
    local info = self:get_info() -- carica le info sul filesystem in cache
    
    local objects = {
            min_index = 11001, -- primo indice disponibile
            max_index = 11000, -- valore dell'indice massimo (i valori intermedi possono anche essere nil)
        }

    self:_add_objects(objects)

    return objects
end

function t.mt:get_attribute_value(hobj, attr, onlysize)
    if onlysize==nil then onlysize = false end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj == nil then return CKR.OBJECT_HANDLE_INVALID end
    local result = obj[attr]
    if result == nil then
        log.output('get_attribute_value(): object', hobj, 'doesn\'t define sepcified attribute', attr)
        return CKR.ATTRIBUTE_TYPE_INVALID 
    end
    if type(result)=='function' then
        local rv
        log.output('get_attribute_value(): attr value is a "function", calling...')
        rv, result = result(self, hobj, attr, onlysize)
        if type(result)=='function' then
            log.output('get_attribute_value(): WARNING: specified attr value still "function", was not populated! Returning empty value...')
            result = "" 
        end
        if rv ~= CKR.OK then return rv end
    elseif type(result)=='number' then
        return CKR.ATTRIBUTE_SENSITIVE
    end
    if onlysize and type(result)=='string' then
        return CKR.OK, string.len(result)
    else
        return CKR.OK, result
    end
end


function t.mt:get_object_size(hobj)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj == nil then return CKR.OBJECT_HANDLE_INVALID end
    local oSize = -1

    if obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        if type(obj[CKA.VALUE]) == "function" then
            obj[CKA.VALUE](self, hobj, CKA.VALUE, false)
        end
        oSize = (obj[CKA.VALUE] and string.len(obj[CKA.VALUE])) or -1
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        oSize = 130*4
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        oSize = 130*4
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        if type(obj[CKA.VALUE]) == "function" then
            obj[CKA.VALUE](self, hobj, CKA.VALUE, false)
        end
        oSize = (obj[CKA.VALUE] and string.len(obj[CKA.VALUE])) or -1
    end

    return CKR.OK, oSize
end



function t.mt:valid()
    local rv = self.nxp_hcard:valid()
    if not rv then
        utility.forget_token_changed(self, "cache")
    end
    return rv
end


function t.mt:flush_cache()
    if self.cfg["xproc"] ~= "true" then
        return false
    end
    local changed, cache_id
    if self._cache_id == nil then
        changed, self._cache_id = utility.has_token_changed(self, "cache", 0)
        log.output("token-nxp-chipdoc:flush_cache(): initialize: _cache_id:", self._cache_id)
    end
    changed, cache_id = utility.has_token_changed(self, "cache", self._cache_id)
    if changed then
        log.output("token-nxp-chipdoc:flush_cache(): token has changed!")
        self._cache_id = cache_id
        self.info = nil -- rimuove cache oggetti
        self._indexes = nil
        self.attributes = nil
        
        log.output("token-nxp-chipdoc:flush_cache(): rebuilding object's cache")
        self.attributes = self:get_objects()  -- riscostruisce cache oggetti
    end
    return changed, self._cache_id
end

function t.mt:invalidate_xproc_cache()
    if self.cfg["xproc"] ~= "true" then
        return
    end
    self._cache_id = utility.set_token_changed(self, "cache")
end





---------------------------------------------
---- write FS
---------------------------------------------



function t.mt:_write_file(data, file, index)
    local relative = string.len(file) == 2
    index = index or 0
    self.nxp_hcard:select(file, relative, true)  -- fid, relative, sm
    log.output("WOULD WRITE to file:", hex.hexify(file), "@", index)
    log.output("DATA:", hex.hexify(data or ''))
    if not self._readonly_test then
        local pcRes, theErrorT = pcall(function()
            self.nxp_hcard:mupdate_binary(index, data, true)
        end)
        
        if not pcRes then
            log.output('token-nxp-chipdoc:_write_file(): ERROR:', debug.traceback(theErrorT) )
            
            if self.nxp_hcard.last_sw == hex.hexf("6982")  and self.userType == CKU.USER 
                        and self.cached_main_pin then

                log.output('token-nxp-chipdoc:_write_file(): restoring secure channel and verifying pin...')
                self.nxp_hcard:perform_mutual_authenticate()
                self.nxp_hcard:select_MF()
                if self.cached_main_pin then
                    self.nxp_hcard:verify_pin_main(self.cached_main_pin, false) -- pin, ispuk
                end
                self.nxp_hcard:select_Generic()
                
                log.output('token-nxp-chipdoc:_write_file(): retry write...')
                self.nxp_hcard:select(file, relative, true)  -- fid, relative, sm
                self.nxp_hcard:mupdate_binary(index, data, true)
            else
                error(theErrorT)
            end
        end
        
    end
end

function t.mt:is_ds(pTemplate)
    if self._cfg_use_pinpad then
        return false
    end
    return string.sub(pTemplate[CKA.ID] or '', 1, 2) == "DS"
        or string.sub(pTemplate[CKA.LABEL] or '', 1, 2) == "DS"
        or string.sub(pTemplate[CKA.ID] or '', 1, 3) == "DX#"
        or string.sub(pTemplate[CKA.LABEL] or '', 1, 3) == "DX#"
        or string.sub(pTemplate[CKA.ID] or '', 1, 5) == "Firma"
        or string.sub(pTemplate[CKA.LABEL] or '', 1, 5) == "Firma"
end


function t.mt:virtual_alloc_kid(dataPriv, dataPub, isDS)
    log.output("token-nxp-chipdoc:virtual_alloc_kid: isDS", isDS)
    log.output("token-nxp-chipdoc:virtual_alloc_kid: has_sscd", self.nxp_hcard.has_sscd)
    
    local max1 = 15
    local min2 = 17
    local isSSCD = isDS and self.nxp_hcard.has_sscd
    if isSSCD then
        max1 = 0
        min2 = 16
    end
    local usedIds = {}
    local kdPriv = dataPriv and p15.parsePubPrivKD(dataPriv) or {}
    local kdPub = dataPub and p15.parsePubPrivKD(dataPub) or {}
    for i=1,max1 do
        usedIds[i] = true
    end
    for i=min2,31 do
        usedIds[i] = true
    end
    for i, v in kdPriv do
        local cur = v.classAttributes.keyReference
        if not self.nxp_hcard.has_sscd
            or (isDS and v.commonObjectAttributes.userConsent)
            or (not isDS and not v.commonObjectAttributes.userConsent) then
            log.output("token-nxp-chipdoc:virtual_alloc_kid: kdPriv already used keyReference:", cur)
            usedIds[cur] = nil
        end
    end
    
    for i, v in kdPub do
        local cur = v.classAttributes.keyReference
        if not self.nxp_hcard.has_sscd 
            or (isDS and v.commonObjectAttributes.userConsent)
            or (not isDS and not v.commonObjectAttributes.userConsent) then
            log.output("token-nxp-chipdoc:virtual_alloc_kid: kdPub already used keyReference:", cur)
            usedIds[cur] = nil
        end
    end
    
    for i=1,31 do
        if usedIds[i] then
            log.output("token-nxp-chipdoc:virtual_alloc_kid: found free keyReference:", i)
            return i
        end
    end
    
    return nil
end

function t.mt:virtual_alloc_kid_secret_key(kd)
    log.output("token-nxp-chipdoc:virtual_alloc_kid_secret_key")
    
    local min1 = 1
    local max1 = 16
    
    local usedIds = {}
    local kdPriv = p15.parsePubPrivKD(kd)
    for i=min1,max1 do
        usedIds[i] = true
    end
    
    for i, v in kdPriv do
        local cur = v.classAttributes.keyReference
        usedIds[cur] = nil
    end
    
    
    for i=min1,max1 do
        if usedIds[i] then
            log.output("token-nxp-chipdoc:virtual_alloc_kid_secret_key: found free keyReference:", i)
            return i
        end
    end
    
    return nil
end

function t.mt:is_kid_in_use(data, kid, isDS)
    log.output("token-nxp-chipdoc:is_kid_in_use: kid/isDS", kid, isDS)
    log.output("token-nxp-chipdoc:is_kid_in_use: has_sscd", self.nxp_hcard.has_sscd)
    local kd = p15.parsePubPrivKD(data)
    local inUse = false
    
    for i, v in kd do
        local cur = v.classAttributes.keyReference
        if cur == kid and ( 
            not self.nxp_hcard.has_sscd
            or (isDS and v.commonObjectAttributes.userConsent) 
            or (not isDS and not v.commonObjectAttributes.userConsent)) then
            log.output("token-nxp-chipdoc:is_kid_in_use: in use keyReference:", cur)
            inUse=true
            break
        end
    end    
    return inUse
end



function t.mt:virtual_alloc_cert_file(data)
    log.output("token-nxp-chipdoc:virtual_alloc_cert_file()")
    
    local min1 = 1
    local max1 = tonumber("1E", 16)

    local certIds = {}
    local kd = p15.parseCertDF(data)
    local id
    for i=min1,max1 do
        id = hex.hexf("%>%H", i)
        certIds[id] = true
    end

    for i, v in kd do
        local cur = v.typeAttributes.path and v.typeAttributes.path.efidOrPath
        log.output("token-nxp-chipdoc:virtual_alloc_cert_file(): file alreay in use:", hex.hexify(cur or ""))
        if cur and certIds[cur] then
            log.output("token-nxp-chipdoc:virtual_alloc_cert_file(): file removed from available list:", hex.hexify(cur))
            certIds[cur] =  nil
        end
        
    end
    
    for i=min1,max1 do
        id = hex.hexf("%>%H", i)
        if certIds[id] then
            log.output("token-nxp-chipdoc:virtual_alloc_cert_file: found free cert file:", hex.hexify(id))
            return id
        end
    end
    
    return nil
end

function t.mt:virtual_alloc_data_file(data)
    log.output("token-nxp-chipdoc:virtual_alloc_data_file()")
    
    local min1 = 4
    local max1 = tonumber("7F", 16)

    local dataIds = {}
    local kd = p15.parsePubPrivDataD(data)
    local id
    for i=min1,max1 do
        id = hex.hexf("DC%B", i)
        dataIds[id] = true
    end

    for i, v in kd do
        local cur = v.typeAttributes.path and v.typeAttributes.path.efidOrPath
        log.output("token-nxp-chipdoc:virtual_alloc_data_file(): file alreay in use:", hex.hexify(cur or ""))
        if cur and dataIds[cur] then
            log.output("token-nxp-chipdoc:virtual_alloc_data_file(): file removed from available list:", hex.hexify(cur))
            dataIds[cur] =  nil
        end
        
    end
    
    for i=min1,max1 do
        id = hex.hexf("DC%B", i)
        if dataIds[id] then
            log.output("token-nxp-chipdoc:virtual_alloc_data_file: found free data file:", hex.hexify(id))
            return id
        end
    end
    
    return nil
end


local function make_accessControlRules_key(SE_ID) -- SE_ID: number, Security Environment ID (?)
    local sdo_rule1 = hex.hexf("030204200201%B", SE_ID)
    local sdo_rule2 = hex.hexf("030204A00201%B", SE_ID)
    local accessControlRules = 
    {
        {
            accessMode=hex.hexf("058000"),  -- READ (bit 0) 30 07 03 03 05 80 00 05 00 -> 10000000000
            accessMode_tag=der.BIT_STRING,
            securityCondition="",
            securityCondition_tag=der.NULL
        },
        {
            accessMode=hex.hexf("054000"),  -- UPDATE (bit 1) 30 0E 03 03 05 40 00 30 07 03 02 04 A0 02 01 03 -> 01000000000
            accessMode_tag=der.BIT_STRING,
            securityCondition=sdo_rule2,
            securityCondition_tag=der.SEQUENCE
        },
        {
            accessMode=hex.hexf("051000"),  -- DELETE (bit 3) 30 0E 03 03 05 10 00 30 07 03 02 04 20 02 01 03 -> 00010000000
            accessMode_tag=der.BIT_STRING,
            securityCondition=sdo_rule1,
            securityCondition_tag=der.SEQUENCE
        },
        {
            accessMode=hex.hexf("052000"), -- EXECUTE (bit 2) 30 0E 03 03 05 20 00 30 07 03 02 04 20 02 01 03 -> 00100000000
            accessMode_tag=der.BIT_STRING,
            securityCondition=sdo_rule1,
            securityCondition_tag=der.SEQUENCE
        },
        {
            accessMode=hex.hexf("050400"),  -- UNKNOWN (bit 5) 30 0E 03 03 05 04 00 30 07 03 02 04 20 02 01 03 -> 00000100000
            accessMode_tag=der.BIT_STRING,
            securityCondition=sdo_rule1,
            securityCondition_tag=der.SEQUENCE
        },
        {
            accessMode=hex.hexf("050040"), -- UNKNOWN (bit 9) 30 0E 03 03 05 00 40 30 07 03 02 04 20 02 01 03  -> 00000000010
            accessMode_tag=der.BIT_STRING,
            securityCondition=sdo_rule1,
            securityCondition_tag=der.SEQUENCE
        },
        {
            accessMode=hex.hexf("050100"), -- UNKNOWN (bit 7) 30 0E 03 03 05 01 00 30 07 03 02 04 20 02 01 03 -> 00000001000
            accessMode_tag=der.BIT_STRING,
            securityCondition=sdo_rule1,
            securityCondition_tag=der.SEQUENCE
        },
    }
    return accessControlRules
end

 
local function make_accessControlRules_cert(SE_ID) -- SE_ID: number, Security Environment ID (?)
    local sdo_rule1 = hex.hexf("030204200201%B", SE_ID)
    local accessControlRules = 
    {
        {
            accessMode=hex.hexf("058000"),  -- READ (bit 0) 30 07 03 03 05 80 00 05 00 -> 10000000000
            accessMode_tag=der.BIT_STRING,
            securityCondition="",
            securityCondition_tag=der.NULL
        },
        {
            accessMode=hex.hexf("054000"),  -- UPDATE (bit 1) 30 0E 03 03 05 40 00 30 07 03 02 04 20 02 01 03 -> 01000000000
            accessMode_tag=der.BIT_STRING,
            securityCondition=sdo_rule1,
            securityCondition_tag=der.SEQUENCE
        },
        {
            accessMode=hex.hexf("051000"),  -- DELETE (bit 3) 30 0E 03 03 05 10 00 30 07 03 02 04 20 02 01 03 -> 00010000000
            accessMode_tag=der.BIT_STRING,
            securityCondition=sdo_rule1,
            securityCondition_tag=der.SEQUENCE
        },
    }
    return accessControlRules
end


function t.mt:virtual_add_private_key_object(
    data, label, id, authId, keyReference, modulusLength,
        isDS,
        objTemplate
    )
    local usage = objTemplate and p15.encode_KeyUsageFlags(objTemplate) or "\002\116" -- unused:2, 0x74: decipher, sign, signRecover, keyDecipher
    local accessFlags = objTemplate and p15.encode_KeyAccessFlags(objTemplate) or "\004\176" -- 04 B0: unused bits: 06, value: 40 (sconosciuto)
    local fs = p15.parsePubPrivKD(data)
    local isECC = objTemplate[CKA.KEY_TYPE] == eCK.ULONG(CKK.ECDSA)
    
    local v = {
        commonObjectAttributes={
            label=label,
            flags="\006\192", -- unused bits:6, 0xC0: private + modifiable
            authId=authId,
            userConsent=isDS and 1 or nil,
            accessControlRules=make_accessControlRules_key(self.nxp_hcard.ID_SE_MAIN)
            },
        classAttributes={
            iD=id,
            usage = usage,
            accessFlags = accessFlags,
            keyReference = keyReference,
        },
        typeAttributes={
            path={efidOrPath=hex.hexf("%>%H", keyReference) },
        }
    }
    if isECC then
        v.typeAttributes.parameters=objTemplate[CKA.EC_PARAMS]
    else
        v.typeAttributes.modulusLength=modulusLength
    end
    local isSSCD = isDS and self.nxp_hcard.has_sscd
    if isSSCD then
        log.output("token-nxp-chipdoc:virtual_add_private_key_object: SSCD AID object...")
        local efidOrPath = der.build(der.APPLICATION(15), NXPIASSmartCard.SSCD_AID) ..
            der.build(der.STRING, hex.hexf("%B", keyReference)) ..
            der.build(der.STRING, hex.hexf("%S%>%H", self.DF_DS, keyReference))
            
        v.typeAttributes.path={efidOrPath_tag=der.CONTEXT(2), efidOrPath=efidOrPath, }
    
    end
    table.insert(fs, v)
    local fsB = p15.buildPubPrivKD(fs, {subClassAttributes={}})
    fsB = fsB .. string.rep("\000", string.len(data) - string.len(fsB))
    return fsB, table.getn(fs)
end

function t.mt:virtual_add_public_key_object(data, label, id, keyReference, modulusLength, isDS, objTemplate)
    local fs = p15.parsePubPrivKD(data)
    local usage = objTemplate and p15.encode_KeyUsageFlags(objTemplate) or "\000\139" -- unused 0, 0x8B: encipher, keyEncipher, verify, verifyRecover
    local accessFlags = objTemplate and p15.encode_KeyAccessFlags(objTemplate) or "\006\064" -- unused: 06, 0x40: extractable
    local isECC = objTemplate[CKA.KEY_TYPE] == eCK.ULONG(CKK.ECDSA)
    
    local v = {
        commonObjectAttributes={
            label=label,
            flags="\006\064", -- unused: 06, 0x40: modifiable
            userConsent=isDS and 1 or nil,
            accessControlRules=make_accessControlRules_key(self.nxp_hcard.ID_SE_MAIN)
            },
        classAttributes={
            iD=id,
            usage = usage,
            accessFlags = accessFlags,
            keyReference = keyReference,
        },
        subClassAttributes={
            tag=der.CONTEXT(0),
            value=hex.hexf("3007A0050303070000"), -- [0]subClassAttributes -> [0]trustedUsage=0
        },
        typeAttributes={
            path={efidOrPath=hex.hexf("%>%H", keyReference) },
        }
    }
    if isECC then
        v.typeAttributes.parameters=objTemplate[CKA.EC_PARAMS]
    else
        v.typeAttributes.modulusLength=modulusLength
    end
    local isSSCD = isDS and self.nxp_hcard.has_sscd
    if isSSCD then
        log.output("token-nxp-chipdoc:virtual_add_public_key_object: SSCD AID object...")
        local efidOrPath = der.build(der.APPLICATION(15), NXPIASSmartCard.SSCD_AID) ..
            der.build(der.STRING, hex.hexf("%B", keyReference)) ..
            der.build(der.STRING, hex.hexf("%S%>%H", self.DF_DS, keyReference))
        
        v.typeAttributes.path={efidOrPath_tag=der.CONTEXT(2), efidOrPath=efidOrPath, }
    end
    
    table.insert(fs, v)
    local fsB = p15.buildPubPrivKD(fs, {subClassAttributes={}}) 
    fsB = fsB .. string.rep("\000", string.len(data) - string.len(fsB))
    return fsB, table.getn(fs)
end


function t.mt:virtual_add_cert_object(data, label, id, file, parsed_cer)
    local cert_is_ca = parsed_cer and (parsed_cer.basicConstraints and parsed_cer.basicConstraints.ca)
    local subject = parsed_cer and parsed_cer.subject
    local subject_tag
    local issuer = parsed_cer and parsed_cer.issuer
    local serialNumber = parsed_cer and parsed_cer.serialNumber
    
    -- print ("subject:", hex.hexify(subject or ""))
    -- print ("issuer:", hex.hexify(issuer or ""))
    -- print ("serialNumber:", hex.hexify(serialNumber or ""))
    
    if subject then
        local subjectD = der.parse(subject)
        if subjectD and subjectD[1] and subjectD[1].value then
            subject = subjectD[1].value
            subject_tag = subjectD[1].tag
        end
    end
    
    local fs = p15.parseCertDF(data)
    local v = {
        commonObjectAttributes={
            label=label,
            flags="\006\064", -- unused: 06, 0x40: modifiable
            accessControlRules=make_accessControlRules_cert(self.nxp_hcard.ID_SE_MAIN),
            },
        classAttributes={
            iD=id,
            authority = cert_is_ca and "\255" or "\0",
            authority_tag = der.BOOLEAN,
        },
        typeAttributes={
            path={efidOrPath=file},
            subject=subject,
            subject_tag=subject_tag,    -- subject is included "as is", so we shall pass as tag&value (default tag should be der.SEQUENCE)
            issuer=issuer,              -- issuer is encapsulated in CONTEXT(0)
            serialNumber=serialNumber,  -- serialNumber will be included inside a der.INTEGER, so we just pass value
        }
    }
    table.insert(fs, v)
    local fsB = p15.buildCertDF(fs)
    fsB = fsB .. string.rep("\000", string.len(data) - string.len(fsB))
    return fsB, table.getn(fs)
end


function t.mt:virtual_add_data_object(data, template, label, applicationName, applicationOID, file)

    local fs = p15.parsePubPrivDataD(data)
    local v = {
        commonObjectAttributes={
            label=label,
            flags=p15.encode_CommonFlags(template), -- unused: 06, 0x40: modifiable
            accessControlRules=make_accessControlRules_cert(self.nxp_hcard.ID_SE_MAIN),
            },
        classAttributes={
            applicationName=applicationName,
            applicationOID=applicationOID,
        },
        typeAttributes={
            path={efidOrPath=file},
        }
    }
    table.insert(fs, v)
    local fsB = p15.buildPubPrivDataD(fs)
    fsB = fsB .. string.rep("\000", string.len(data) - string.len(fsB))
    return fsB, table.getn(fs)
end



function t.mt:create_object_pubkey(pTemplateOrig, keyReference, as_local, isDS)
    log.output('token-nxp-chipdoc:create_object_pubkey():', pTemplateOrig, "as_local:", as_local, "keyReference:", keyReference)
    
    -- keyReference: quando specificato crea una chiave pubblica associata ad una chiave privata
    local pTemplate = utility.clone_table(pTemplateOrig)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local do_import_sdo
    local obj
    if not pTemplate[CKA.MODULUS] or not pTemplate[CKA.PUBLIC_EXPONENT] then
        log.output('token-nxp-chipdoc:create_object_pubkey(): MODULUS or PUBLIC_EXPONENT not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local modulus_bits = string.len(pTemplate[CKA.MODULUS]) * 8
    if not (modulus_bits == 1024 or modulus_bits == 2048 
            or (self._supports_4096 and modulus_bits == 4096) 
            or (self._supports_3072 and modulus_bits == 3072)) then
        log.output('token-nxp-chipdoc:create_object_pubkey(): MODULUS size invalid:', modulus_bits)
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    if isDS == nil then
        isDS = self:is_ds(pTemplate) 
    end
    local isSSCD = isDS and self.nxp_hcard.has_sscd
    log.output('token-nxp-chipdoc:create_object_pubkey(): isDS:', isDS)
    log.output('token-nxp-chipdoc:create_object_pubkey(): isSSCD:', isSSCD)
    
    if not keyReference and isDS then
        log.output('token-nxp-chipdoc:create_object_pubkey(): not allowed import FULL pub key in DS area')
        return CKR.TEMPLATE_INCONSISTENT
    end

    obj = GetPubKeyTemplate(t.mt.get_pubkey)
    obj.private = false
    obj.key_bits = modulus_bits
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] and type(pTemplate[k]) == 'string' then
            obj[k] = pTemplate[k]
        end
    end
    obj[CKA.LOCAL] = eCK.BBOOL(as_local)

    if not keyReference then
        local hObj
        if self.userType == CKU.USER then
            log.output('token-nxp-chipdoc:create_object_pubkey(): user logged in: searching if a private key sharing same modulus exists...')
            hObj = self:_search_related_key_object(
                pTemplate[CKA.MODULUS],
                pTemplate[CKA.PUBLIC_EXPONENT],
                eCK.ULONG(CKO.PRIVATE_KEY) )
        else
            log.output('token-nxp-chipdoc:create_object_pubkey(): user NOT logged in: unable to search a private key sharing same modulus...')
        end
        if hObj then
            local objPriv = self.attributes[hObj]
            if objPriv.aid == NXPIASSmartCard.Generic_AID then
                keyReference = objPriv.kid
                log.output('token-nxp-chipdoc:create_object_pubkey(): found related key keyReference:', keyReference)
            end
        end
         
        if not keyReference then
            log.output('token-nxp-chipdoc:create_object_pubkey(): allocating a keyReference for public key')
            keyReference = self:virtual_alloc_kid(self._indexes._private_keys_bin, self._indexes._public_keys_bin, false)
            if not keyReference then
                log.output('token-nxp-chipdoc:create_object_pubkey(): no more keys left in unused space file!')
                return CKR.DEVICE_MEMORY
            end
            do_import_sdo = true
        end
    end
    
    self:invalidate_xproc_cache()
    self.nxp_hcard:auto_perform_mutual_authenticate()
    self.nxp_hcard:select_MF()
    local info = self:get_info()
    self.nxp_hcard:select_Generic()

    local label = pTemplate[CKA.LABEL] or ''
    local id = pTemplate[CKA.ID] or ''
    local modulusLength = modulus_bits
    local pubKDBin, objNum = self:virtual_add_public_key_object(
                                self._indexes._public_keys_bin,
                                label,
                                id,
                                keyReference,
                                obj.key_bits,
                                isDS,
                                pTemplateOrig
                                )
    if string.len(pubKDBin) ~= string.len(self._indexes._public_keys_bin) then
        log.output('token-nxp-chipdoc:create_object_pubkey(): no more space left in Public KD file!')
        return CKR.DEVICE_MEMORY
    end
    obj.num = objNum
    obj.kid = keyReference
    obj.aid = isSSCD and NXPIASSmartCard.SSCD_AID or NXPIASSmartCard.Generic_AID
    
    log.output(string.format("token-nxp-chipdoc:create_object_pubkey(): new obj num:%d kid:%d bits:%d", 
        obj.num, obj.kid, obj.key_bits) )

    if do_import_sdo then
        log.output('token-nxp-chipdoc:create_object_pubkey(): AUTH OBJ: erasing SDOs...')
        self.nxp_hcard:delete_SDO(NXPIASSmartCard.object_classes.RSA_PUB_KEY, keyReference, true)
        self.nxp_hcard:delete_SDO(NXPIASSmartCard.object_classes.RSA_PRIV_KEY, keyReference, true)
        
        local acsPubk, acsPrivk = self:get_keys_acs(true)
        log.output('token-nxp-chipdoc:create_object_pubkey(): AUTH OBJ: creating SDOs...')
        self.nxp_hcard:create_RSA_SDO_for_keygen(NXPIASSmartCard.object_classes.RSA_PRIV_KEY, keyReference, obj.key_bits, acsPrivk, true)
        self.nxp_hcard:create_RSA_SDO_for_keygen(NXPIASSmartCard.object_classes.RSA_PUB_KEY, keyReference, obj.key_bits, acsPubk, true)
        
        self.nxp_hcard:import_private_key(keyReference,
            pTemplate[CKA.MODULUS],
            pTemplate[CKA.PUBLIC_EXPONENT])
    end
    
    log.output('token-nxp-chipdoc:create_object_pubkey(): writing public key objects directory...')
    self:_write_file(pubKDBin, self.files.PubKD)
    self._indexes._public_keys_bin = pubKDBin
    
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    
    log.output('token-nxp-chipdoc:create_object_pubkey(): CKR.OK, hPub=', self.attributes.max_index)
    return CKR.OK, self.attributes.max_index
end


function t._is_private_attribute(attr_type)
    local private_attributes = {
        CKA.PRIVATE_EXPONENT,
        CKA.PRIME_1,
        CKA.PRIME_2,
        CKA.EXPONENT_1,
        CKA.EXPONENT_2,
        CKA.COEFFICIENT,
        CKA.PRIME,
        CKA.SUBPRIME,
        CKA.BASE,
    }
    for i, v in private_attributes do
        if attr_type == v then
            return true
        end
    end
    return false
end

function t.mt:_search_related_key_object(modulus, pubExp, class)
    -- verifica se un oggetto simile esiste gi