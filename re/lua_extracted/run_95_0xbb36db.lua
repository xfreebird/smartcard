 oggetti ritorna 0
function t.mt:get_item(search_state, showprivate, template)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    if search_state.lastobj==nil then 
        search_state.lastobj=self.attributes.min_index 
    end
    for i=search_state.lastobj, self.attributes.max_index do
        local attr = self.attributes[i]
        if attr ~= nil then
            if type(attr[CKA.PRIVATE]) == 'function' then
                attr[CKA.PRIVATE](self, i, CKA.PRIVATE, false)
            end
            local visible = attr[CKA.PRIVATE] == eCK.BBOOL(false) or 
                            (attr[CKA.PRIVATE] == eCK.BBOOL(true) and showprivate)
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
        -- [ CKA.OBJECT_ID ] = populateKeyFunc,
    }
end

local function GetCertTemplate(populateCertFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.CERTIFICATE),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(false),
        [ CKA.LABEL ] = '',
        -- Certificate
        [ CKA.CERTIFICATE_TYPE ] = eCK.CERTIFICATE_TYPE(CKC.X_509),
        [ CKA.TRUSTED ] = eCK.BBOOL(true),
        [ CKA.CERTIFICATE_CATEGORY ] = eCK.ULONG(1), -- user
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        -- Certificate X.509
        [ CKA.SUBJECT ] = populateCertFunc,
        [ CKA.ID ] = '',
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
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(false),
        [ CKA.LABEL ] = '',
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = '',
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = eCK.BBOOL(false),
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
        [ CKA.MODIFIABLE ] = eCK.BBOOL(false),
        [ CKA.LABEL ] = '',
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = '',
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
        [ CKA.ALWAYS_AUTHENTICATE ] = eCK.BBOOL(false),
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

function t.mt:get_privkey(hobj, att_type, onlysize, force_all)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('get_privkey(): ERROR! not a private key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    local MOD, EXP = self.aet_hcard:read_public_key(obj.kid)
    obj[CKA.MODULUS] = MOD
    obj[CKA.PUBLIC_EXPONENT] = EXP
    obj[CKA.MODULUS_BITS] = eCK.ULONG(string.len(MOD) * 8)
    
    obj.populated = true
    return CKR.OK, obj[att_type]
end

function t.mt:get_pubkey(hobj, att_type, onlysize, force_all)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PUBLIC_KEY) then
        log.output('get_pubkey(): ERROR! not a public key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    
    local MOD, EXP = self.aet_hcard:read_public_key(obj.kid)
    obj[CKA.MODULUS] = MOD
    obj[CKA.PUBLIC_EXPONENT] = EXP
    obj[CKA.MODULUS_BITS] = eCK.ULONG(string.len(MOD) * 8)
    
    obj.populated = true
    return CKR.OK, obj[att_type]
end

function t.mt:get_certificate(hobj, att_type, onlysize, force_all)

    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
        
    local parsed_cer
    local cert_value
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.CERTIFICATE) then
        log.output('get_certificate(): ERROR! not a certificate object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end

    self.aet_hcard:select(obj.path.efidOrPath, true)  -- fid, relative
    local cert_value = self.aet_hcard:mread_binary(obj.path.index, obj.path.length)
    
    if string.sub(cert_value, 1, 2) == hexf('5a82') then -- Z\x82 + sizeBE + compressed data
        local decompr = zlib.decompress(string.sub(cert_value, 5, -1), true, nil, nil)
        cert_value = decompr
    end
    pcall(function() parsed_cer = der.parse_x509cer(cert_value) end )

    obj[CKA.VALUE] = cert_value or obj[CKA.VALUE]
    obj[CKA.SUBJECT] = (parsed_cer and parsed_cer.subject) or ''
    obj[CKA.ISSUER] = (parsed_cer and parsed_cer.issuer) or ''
    obj[CKA.SERIAL_NUMBER] = (parsed_cer and parsed_cer.serialNumber) or ''
    
    obj.populated = true
    return CKR.OK, obj[att_type]
end

function t.mt:get_data_object(hobj, att_type, onlysize, force_all)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local obj = self.attributes[hobj]
    local value = ''
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.DATA) then
        log.output('get_data_ds(): ERROR! not a DATA object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    
    self.aet_hcard:select(obj.path.efidOrPath, true)  -- fid, relative
    local value = self.aet_hcard:mread_binary(obj.path.index, obj.path.length)
    
    obj[CKA.VALUE] = value
    obj.populated = true
    return CKR.OK, obj[att_type]
end


function t.mt:_parse_key_references()
    -- dovrebbe leggere tutte le key dal file IPF e ricavare i kid
    
    local keys_1024 = {132, 133, 134, 135, 136, 137,}
    self._keys_1024 = keys_1024
end

function t.mt:_read_token_info_indexes()
    local info
    if not self._indexes then
        self._indexes = {}
    end
    if not self._indexes._auth_objects_bin then
        info = self.aet_hcard:select(self.files.AODF, true, false)  -- fid, relative, sm
        self._indexes._auth_objects_bin = self.aet_hcard:mread_binary(0, info.size, false)
        log.output("self._indexes._auth_objects_bin:", hex.hexify(self._indexes._auth_objects_bin))
        local ao = p15.parseAuthObjects(self._indexes._auth_objects_bin)
        local soPin, userPin
        local soPinMinLen, userPinMinLen
        local soPinPadding, userPinPadding
        local userPinInitialized
        for i, a in ao do
            if a.classAttributes and a.classAttributes.authId 
                and a.typeAttributes and a.typeAttributes.pwdFlags then
                local pinFlags = p15.decode_PinFlags(a.typeAttributes.pwdFlags)
                if pinFlags.soPin or (pinFlags.unblockingPin and not soPin) then
                    soPin = a.classAttributes.authId
                    soPinMinLen = a.typeAttributes.minLength
                    soPinPadding = a.typeAttributes.storedLength
                elseif not pinFlags.soPin and not pinFlags.unblockingPin then
                    userPin = a.classAttributes.authId
                    userPinMinLen = a.typeAttributes.minLength
                    userPinPadding = a.typeAttributes.storedLength
                    userPinInitialized = pinFlags.initialized
                end
            end
        end
        if soPin then
            self.aet_hcard.BSO_PUK = string.byte(soPin, 1)
            log.output("BSO_PUK:", hex.hexify(soPin))
        end
        if userPin then
            self.aet_hcard.BSO_PIN = string.byte(userPin, 1)
            log.output("BSO_PIN:", hex.hexify(userPin))
        end
        if soPinPadding then
            self.aet_hcard.PUK_PADDING = soPinPadding
            log.output("PUK_PADDING:", soPinPadding)
        end
        if userPinPadding then
            self.aet_hcard.PIN_PADDING = userPinPadding
            log.output("PIN_PADDING:", userPinPadding)
        end
        log.output("userPinInitialized:", userPinInitialized)
        self.userPinInitialized = userPinInitialized
    end
    -- if not self._indexes._token_infos_bin then
        -- info = self.aet_hcard:select(self.files.CDF, true, false)  -- fid, relative, sm
        -- self._indexes._token_infos_bin = self.aet_hcard:mread_binary(0, info.size, false)
        -- log.output("self._indexes._token_infos_bin:", hex.hexify(self._indexes._token_infos_bin))
    -- end
    
    self:_parse_key_references()
end

function t.mt:_read_indexes()
    
    -- legge tutti gi indici non in cache
    
    if not self._indexes then
        self._indexes = {}
    end
    self:_read_token_info_indexes()
    local info
    if not self._indexes._private_keys_bin then
        info = self.aet_hcard:select(self.files.PrivKD, true)  -- fid, relative
        self._indexes._private_keys_bin = self.aet_hcard:mread_binary(0, info.size)
        log.output("self._indexes._private_keys_bin:", hex.hexify(self._indexes._private_keys_bin))
    end

    if not self._indexes._unused_space_bin then
        info = self.aet_hcard:select(self.files.US, true)  -- fid, relative
        self._indexes._unused_space_bin = self.aet_hcard:mread_binary(0, info.size)
        log.output("self._indexes._unused_space_bin:", hex.hexify(self._indexes._unused_space_bin))
    end
   
    if not self._indexes._public_keys_bin then
        info = self.aet_hcard:select(self.files.PubKD, true)  -- fid, relative
        self._indexes._public_keys_bin = self.aet_hcard:mread_binary(0, info.size)
        log.output("self._indexes._public_keys_bin:", hex.hexify(self._indexes._public_keys_bin))
    end

    if not self._indexes._certificates_bin then
        info = self.aet_hcard:select(self.files.CDF, true)  -- fid, relative
        self._indexes._certificates_bin = self.aet_hcard:mread_binary(0, info.size)
        log.output("self._indexes._certificates_bin:", hex.hexify(self._indexes._certificates_bin))
    end
    
    if not self._indexes._data_objects_bin then
        info = self.aet_hcard:select(self.files.DCODF_Pub, true)  -- fid, relative
        self._indexes._data_objects_bin = self.aet_hcard:mread_binary(0, info.size)
        log.output("self._indexes._data_objects_bin:", hex.hexify(self._indexes._data_objects_bin))
    end
   
end

local function decode_bool_attributes(classAttributes, obj)
    if classAttributes.usage then
        p15.decode_KeyUsageFlags(classAttributes.usage, obj)
    end
    if classAttributes.accessFlags then
        p15.decode_KeyAccessFlags(classAttributes.accessFlags, obj)
    end
end

function t.mt:_add_private_objects(objects)
    if self._private_objects_added then
        return
    end
    self:_read_indexes()
    
    if self._indexes._private_keys_bin then
        local d = p15.parsePubPrivKD(self._indexes._private_keys_bin)
        for i, v in d do
            local obj = GetPrivKeyTemplate(t.mt.get_privkey)
            obj.private = true
            obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
            obj[CKA.LABEL] = v.commonObjectAttributes.label
            obj[CKA.ID] = v.classAttributes.iD
            obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
            obj.kid = v.classAttributes.keyReference
            obj.key_bits = v.typeAttributes.modulusLength
            obj.num = i
            decode_bool_attributes(v.classAttributes, obj)
            objects.max_index = objects.max_index +1
            objects[ objects.max_index] = obj
            log.output(
                string.format("_add_private_objects(): added private key: num:%d kid:%d bits:%d handle:%d", 
                    obj.num, obj.kid, obj.key_bits, objects.max_index)
                )
        end
    end
    self._private_objects_added = self._indexes._private_keys_bin
end

function t.mt:_add_objects(objects)
    self:_read_indexes()
    self:_add_private_objects(objects)
    
    if self._indexes._public_keys_bin then
        local d = p15.parsePubPrivKD(self._indexes._public_keys_bin)
        for i, v in d do
            local obj = GetPubKeyTemplate(t.mt.get_pubkey)
            obj.private = false
            obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
            obj[CKA.LABEL] = v.commonObjectAttributes.label
            obj[CKA.ID] = v.classAttributes.iD
            obj.kid = v.classAttributes.keyReference
            obj.key_bits = v.typeAttributes.modulusLength
            obj.num = i
            decode_bool_attributes(v.classAttributes, obj)
            objects.max_index = objects.max_index +1
            objects[ objects.max_index] = obj
            
            --~ print("obj.kid type:", type(obj.kid), "value:", obj.kid)
            --~ print("obj.num type:", type(obj.num), "value:", obj.num)
            --~ print("obj.key_bits type:", type(obj.kid), "value:", obj.key_bits)
            --~ print("objects.max_index type:", type(objects.max_index), "value:", objects.max_index)
            log.output(
                string.format("_add_objects(): added public key: num:%d kid:%d bits:%d handle:%d", 
                    obj.num, obj.kid, obj.key_bits, objects.max_index)
                )

        end
    end

    if self._indexes._certificates_bin then
        local d = p15.parseCertDF(self._indexes._certificates_bin)
        for i, v in d do
            local obj = GetCertTemplate(t.mt.get_certificate)
            obj.private = false
            obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
            obj[CKA.LABEL] = v.commonObjectAttributes.label
            obj[CKA.ID] = v.classAttributes.iD
            
            obj.path = v.typeAttributes.path
            obj.num = i
            decode_bool_attributes(v.classAttributes, obj)
            objects.max_index = objects.max_index +1
            objects[ objects.max_index] = obj
            log.output(
                string.format("_add_objects(): added certificate: num:%d handle:%d", 
                    obj.num, objects.max_index)
                )
        end
    end
    
    if self._indexes._data_objects_bin then
        local d = p15.parsePubPrivDataD(self._indexes._data_objects_bin)
        for i, v in d do
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

            obj.path = v.typeAttributes.path
            obj.num = i
            decode_bool_attributes(v.classAttributes, obj)
            objects.max_index = objects.max_index +1
            objects[ objects.max_index] = obj
            log.output(
                string.format("_add_objects(): added public data object: num:%d handle:%d", 
                    obj.num, objects.max_index)
                )
        end
    end
       
end


function t.mt:get_objects()
    log.output('token-aet:get_objects()')
    
    
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
        rv, result = result(self, hobj, attr, onlysize)
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


function t.mt:_write_file(data, file, index)
    local relative = string.len(file) == 2
    index = index or 0
    self.aet_hcard:select(file, relative)  -- fid, relative
    log.output("WOULD WRITE to file:", hex.hexify(file), "@", index)
    log.output("DATA:", hex.hexify(data or ''))
    if not self._readonly_test then
        self.aet_hcard:mupdate_binary(index, data)
    end
end


function t.mt:virtual_alloc_space(data, file, length)
    local fs = p15.parseUnusedSpace(data)
    local index, authId
    fs, index, authId = p15.alloc_space(fs, file, length)
    local fsB = p15.buildUnusedSpace(fs)
    fsB = fsB .. string.rep("\000", string.len(data) - string.len(fsB))
    return fsB, index, authId
end

function t.mt:virtual_release_space(data, file, index, length, authId)
    local fs = p15.parseUnusedSpace(data)
    fs = p15.release_space(fs, file, index, length, authId)
    local fsB = p15.buildUnusedSpace(fs)
    fsB = fsB .. string.rep("\000", string.len(data) - string.len(fsB))
    return fsB
end

function t.mt:virtual_add_private_key_object(
    data, label, id, authId, keyReference, modulusLength,
        objTemplate
    )
    local usage = objTemplate and p15.encode_KeyUsageFlags(objTemplate) or "\002\116" -- unused:2, 0x74: decipher, sign, signRecover, keyDecipher
    local accessFlags = objTemplate and p15.encode_KeyAccessFlags(objTemplate) or "\004\176" -- 04 B0: unused bits: 06, value: 40 (sconosciuto)
    local fs = p15.parsePubPrivKD(data)
    local v = {
        commonObjectAttributes={
            label=label,
            flags="\006\192", -- unused bits:6, 0xC0: private + modifiable
            authId=authId
            },
        classAttributes={
            iD=id,
            usage = usage,
            accessFlags = accessFlags,
            keyReference = keyReference,
        },
        typeAttributes={
            path={efidOrPath=""},
            modulusLength=modulusLength
        }
    }
    table.insert(fs, v)
    local fsB = p15.buildPubPrivKD(fs)
    fsB = fsB .. string.rep("\000", string.len(data) - string.len(fsB))
    return fsB, table.getn(fs)
end

function t.mt:virtual_add_public_key_object(data, label, id, keyReference, modulusLength, objTemplate)
    local fs = p15.parsePubPrivKD(data)
    local usage = objTemplate and p15.encode_KeyUsageFlags(objTemplate) or "\000\139" -- unused 0, 0x8B: encipher, keyEncipher, verify, verifyRecover
    local accessFlags = objTemplate and p15.encode_KeyAccessFlags(objTemplate) or "\006\064" -- unused: 06, 0x40: extractable
    
    local v = {
        commonObjectAttributes={
            label=label,
            flags="\006\064", -- unused: 06, 0x40: modifiable
            },
        classAttributes={
            iD=id,
            usage = usage,
            accessFlags = accessFlags,
            keyReference = keyReference,
        },
        typeAttributes={
            path={efidOrPath=""},
            modulusLength=modulusLength
        }
    }
    table.insert(fs, v)
    local fsB = p15.buildPubPrivKD(fs)
    fsB = fsB .. string.rep("\000", string.len(data) - string.len(fsB))
    return fsB, table.getn(fs)
end

function t.mt:virtual_add_cert_object(data, label, id, file, index, length)
    local fs = p15.parseCertDF(data)
    local v = {
        commonObjectAttributes={
            label=label,
            flags="\006\064", -- unused: 06, 0x40: modifiable
            },
        classAttributes={
            iD=id,
        },
        typeAttributes={
            path={efidOrPath=file, index=index, length=length},
        }
    }
    table.insert(fs, v)
    local fsB = p15.buildCertDF(fs)
    fsB = fsB .. string.rep("\000", string.len(data) - string.len(fsB))
    return fsB, table.getn(fs)
end


function t.mt:virtual_add_data_object(data, label, application, file, index, length, objTemplate)
    local flags = p15.encode_CommonFlags(objTemplate)
    local fs = p15.parsePubPrivDataD(data)
    local v = {
        commonObjectAttributes={
            label=label,
            flags=flags,
            },
        classAttributes={
            applicationName=application,
        },
        typeAttributes={
            path={efidOrPath=file, index=index, length=length},
        }
    }
    table.insert(fs, v)
    local fsB = p15.buildPubPrivDataD(fs)
    fsB = fsB .. string.rep("\000", string.len(data) - string.len(fsB))
    return fsB, table.getn(fs)
end



function t.mt:_search_related_key_object(modulus, pubExp, class)
    -- verifica se un oggetto simile esiste gi