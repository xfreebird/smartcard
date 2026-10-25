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
    if log.canlog() then
        log.output('verify_template: full template: ',hobj, repr(template))
    end
    local static_attributes = {CKA.CLASS, CKA.TOKEN }
    for i, attr_type in static_attributes do
        if template[attr_type] then
            local rv, real_value = self:get_attribute_value(hobj, attr_type)
            if log.canlog() then
                log.output('>>>template: ', hex.tohex8(attr_type),
                      repr(template[attr_type]), repr(real_value), rv)
            end
            if rv~=CKR.OK or real_value ~= template[attr_type] then
                log.output('>>>S: not match')
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
        if log.canlog() then
            log.output('>>>template: ', hex.tohex8(attr_type),
                  repr(value), repr(real_value), rv)
        end
        if rv~=CKR.OK or real_value ~=value then
            log.output('>>>D: not match')
            return false
        else
            log.output('>>>D: match')
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

function t.mt:get_privkey(hobj, att_type, onlysize, force_all)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('get_privkey(): ERROR! not a private key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    self.arjo_hcard:auto_perform_mutual_authenticate()
    local MOD, EXP = self.arjo_hcard:read_public_key(obj.kid)
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
    
    self.arjo_hcard:auto_perform_mutual_authenticate()
    local MOD, EXP = self.arjo_hcard:read_public_key(obj.kid)
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

    self.arjo_hcard:auto_perform_mutual_authenticate()
    self.arjo_hcard:select(obj.path.efidOrPath, true, true)  -- fid, relative, sm
    local cert_value = self.arjo_hcard:mread_binary(obj.path.index, obj.path.length, true)
    
    if string.sub(cert_value, 1, 2) == hexf('5a82') then -- Z\x82 + sizeBE + compressed data
        local decompr = zlib.decompress(string.sub(cert_value, 5, -1), true, nil, nil)
        cert_value = decompr
    end
    pcall(function() parsed_cer = der.parse_x509cer(cert_value) end )

    obj[CKA.VALUE] = cert_value or obj[CKA.VALUE]
    obj[CKA.SUBJECT] = (parsed_cer and parsed_cer.subject) or ''
    obj[CKA.ISSUER] = (parsed_cer and parsed_cer.issuer) or ''
    obj[CKA.SERIAL_NUMBER] = (parsed_cer and parsed_cer.serialNumber) or ''
    --~ obj[CKA.MODIFIABLE] = eCK.BBOOL((bin.flags('0x0001') * obj_attributes.flags).asbool)
    --~ obj[CKA.TRUSTED]      = eCK.BBOOL((bin.flags('0x0002') * obj_attributes.flags).asbool)
    
    obj.populated = true
    return CKR.OK, obj[att_type]
end



function t.mt:_read_token_info_indexes()
    local info
    if not self._indexes then
        self._indexes = {}
    end
    if not self._indexes._auth_objects_bin then
        info = self.arjo_hcard:select(self.files.AODF, true, true)  -- fid, relative, sm
        self._indexes._auth_objects_bin = self.arjo_hcard:mread_binary(0, info.size, true)
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
                if pinFlags.unblockingPin and not soPin then
                    soPin = a.classAttributes.authId
                    soPinMinLen = a.typeAttributes.minLength
                    soPinPadding = a.typeAttributes.storedLength
                elseif not pinFlags.soPin and not pinFlags.unblockingPin then
                    userPin = a.classAttributes.authId
                    userPinMinLen = a.typeAttributes.minLength
                    userPinPadding = a.typeAttributes.storedLength
                    userPinInitialized = pinFlags.initialized
                    self._userPinMinLen = a.typeAttributes.minLength
                    self._userPinMaxLen = a.typeAttributes.maxLength
                end
            end
        end
        if soPin then
            self.arjo_hcard.ID_PUK = string.byte(soPin, 1)
            log.output("ID_PUK:", hex.hexify(soPin))
        end
        if userPin then
            self.arjo_hcard.ID_PIN = string.byte(userPin, 1)
            log.output("ID_PIN:", hex.hexify(userPin))
        end
        if soPinPadding then
            self.arjo_hcard.PUK_PADDING = soPinPadding
            log.output("PUK_PADDING:", soPinPadding)
        end
        if userPinPadding then
            self.arjo_hcard.PIN_PADDING = userPinPadding
            log.output("PIN_PADDING:", userPinPadding)
        end
        log.output("userPinInitialized:", userPinInitialized)
        self.userPinInitialized = userPinInitialized
        
    end

end

function t.mt:_read_indexes()
    
    -- legge tutti gi indici non in cache
    
    if not self._indexes then
        self._indexes = {}
    end
    local info
    self:_read_token_info_indexes()
    -- if self.userType == CKU.USER then
        if not self._indexes._private_keys_bin then
            info = self.arjo_hcard:select(self.files.PrivKD, true, true)  -- fid, relative, sm
            self._indexes._private_keys_bin = self.arjo_hcard:mread_binary(0, info.size, true)
            log.output("self._indexes._private_keys_bin:", hex.hexify(self._indexes._private_keys_bin))
        end
    -- end
    
    if not self._indexes._unused_space_bin then
        info = self.arjo_hcard:select(self.files.US, true, true)  -- fid, relative, sm
        self._indexes._unused_space_bin = self.arjo_hcard:mread_binary(0, info.size, true)
        log.output("self._indexes._unused_space_bin:", hex.hexify(self._indexes._unused_space_bin))
    end
    
    if not self._indexes._public_keys_bin then
        info = self.arjo_hcard:select(self.files.PubKD, true, true)  -- fid, relative, sm
        self._indexes._public_keys_bin = self.arjo_hcard:mread_binary(0, info.size, true)
        log.output("self._indexes._public_keys_bin:", hex.hexify(self._indexes._public_keys_bin))
    end

    if not self._indexes._certificates_bin then
        info = self.arjo_hcard:select(self.files.CDF, true, true)  -- fid, relative, sm
        self._indexes._certificates_bin = self.arjo_hcard:mread_binary(0, info.size, true)
        log.output("self._indexes._certificates_bin:", hex.hexify(self._indexes._certificates_bin))
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
            obj.userConsent = v.commonObjectAttributes.userConsent
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

end


function t.mt:get_objects()
    log.output('token-arjo:get_objects()')
    
    self.arjo_hcard:auto_perform_mutual_authenticate()
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
    self.arjo_hcard:select(file, relative, true)  -- fid, relative, sm
    log.output("WOULD WRITE to file:", hex.hexify(file), "@", index)
    log.output("DATA:", hex.hexify(data or ''))
    if not self._readonly_test then
        self.arjo_hcard:mupdate_binary(index, data, true)
    end
end

function t.mt:is_ds(pTemplate)
    return string.sub(pTemplate[CKA.ID] or '', 1, 5) ~= "DS_CS" 
        and string.sub(pTemplate[CKA.LABEL] or '', 1, 5) ~= "DS_CS"

end

function t.mt:virtual_alloc_kid(data, bits, isDS)
    log.output("virtual_alloc_kid: bits/isDS", bits, isDS)

    local dsObj, authObj
    local fs = p15.parseUnusedSpace(data)
    local index, kObj
    for i, v in fs do
        if string.len(v.path.efidOrPath) == 1 and (v.path.length* 8 == bits) then
            log.output("virtual_alloc_kid: found object of requested size:",
                bits, "index", v.path.index, "length", v.path.length)

            if isDS then
                if (bin.flags(v.path.index or 0) * t.dsMask).asbool then
                    dsObj = dsObj or i
                    if not (bin.flags(v.path.index or 0) * t.authMask).asbool then
                        dsObj = i
                        log.output("virtual_alloc_kid: found specific DS only slot:", i)
                        break
                    end
                end
            else
                if (bin.flags(v.path.index or 0) * t.authMask).asbool then
                    authObj = authObj or i
                
                    if not (bin.flags(v.path.index or 0) * t.dsMask).asbool then
                        authObj = i
                        log.output("virtual_alloc_kid: found specific AUTH only slot:", i)
                        break
                    end
                end
            end
        end
    end
    log.output("virtual_alloc_kid: dsObj:", dsObj)
    log.output("virtual_alloc_kid: authObj:", authObj)
    index = isDS and dsObj or authObj
    if not index then
        return data, nil
    else
        log.output("virtual_alloc_kid: found slot:", index)
        kObj = fs[index]
        table.remove(fs, index)
    end
    local fsB = p15.buildUnusedSpace(fs)
    fsB = fsB .. string.rep("\000", string.len(data) - string.len(fsB))
    return fsB, kObj
end

-- function t.mt:virtual_release_kid(data, keyReference, bits, authId)
    -- local fs = p15.parseUnusedSpace(data)
    -- if type(authId) == "number" then
        -- authId = hex.hexf("%B", authId)
    -- else
        -- assert(string.len(authId) == 1)
    -- end
    -- local id = keyReference
    -- if type(id) == "number" then
        -- id = hex.hexf("%B", id)
    -- elseif string.len(id) == 2 then
        -- id = hex.hexf(id)
    -- end
    -- local v = {
        -- path={
            -- efidOrPath = id,
            -- length = bits/8,
            -- index=0,
        -- },
        -- authId=authId,
    -- }
    -- table.insert(fs, v)
    -- local fsB = p15.buildUnusedSpace(fs)
    -- fsB = fsB .. string.rep("\000", string.len(data) - string.len(fsB))
    -- return fsB
-- end

function t.mt:virtual_alloc_cert(data, size, hint)
    log.output("virtual_alloc_cert: looking for a file of size:", size, "with hint:", hint)
    local index
    local fs = p15.parseUnusedSpace(data)
    local usObj
    for i, v in fs do
        -- print(repr(v))
        if v.path and v.path.efidOrPath and string.len(v.path.efidOrPath) == 2 and v.path.length and v.path.length >= size then
            if not hint then
                if string.byte(v.path.efidOrPath, 1) == tonumber("CA", 16) then
                    index = i
                    log.output("virtual_alloc_cert: found CA cert free slot:", index)
                    break
                end
            elseif string.byte(v.path.efidOrPath, 1) ~= tonumber("CA", 16)
                    and string.byte(v.path.efidOrPath, 2) == hint then
                index = i
                log.output("virtual_alloc_cert: found normal cert free slot:", index)
                break
            end
        end
    end
    if index then
        usObj = fs[index]
        table.remove(fs, index)
    end
    local fsB = p15.buildUnusedSpace(fs)
    fsB = fsB .. string.rep("\000", string.len(data) - string.len(fsB))
    return fsB, usObj
end

function t.mt:virtual_release_cert(data, file, index, length, authId)
    local fs = p15.parseUnusedSpace(data)
    local v = {
        path={
        efidOrPath = file,
        index = index,
        length=length,
        },
        authId = authId,
    }
    table.insert(fs, v)
    local fsB = p15.buildUnusedSpace(fs)
    fsB = fsB .. string.rep("\000", string.len(data) - string.len(fsB))
    return fsB
end

function t.mt:virtual_add_private_key_object(
    data, label, id, authId, keyReference, modulusLength,
        isDS,
        objTemplate
    )
    local usage = objTemplate and p15.encode_KeyUsageFlags(objTemplate) or "\002\116" -- unused:2, 0x74: decipher, sign, signRecover, keyDecipher
    local accessFlags = objTemplate and p15.encode_KeyAccessFlags(objTemplate) or "\004\176" -- 04 B0: unused bits: 06, value: 40 (sconosciuto)
    local fs = p15.parsePubPrivKD(data)
    local v = {
        commonObjectAttributes={
            label=label,
            flags="\006\192", -- unused bits:6, 0xC0: private + modifiable
            authId=authId,
            userConsent=isDS and 1 or nil,
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


function t.mt:create_object_pubkey(pTemplateOrig, keyReference, as_local)
    log.output('create_object_pubkey():', pTemplateOrig, "as_local:", as_local, "keyReference:", keyReference)
    
    -- keyReference: quando specificato crea una chiave pubblica associata ad una chiave privata
    local pTemplate = utility.clone_table(pTemplateOrig)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    if not pTemplate[CKA.MODULUS] or not pTemplate[CKA.PUBLIC_EXPONENT] then
        log.output('create_object_pubkey(): MODULUS or PUBLIC_EXPONENT not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local modulus_bits = string.len(pTemplate[CKA.MODULUS]) * 8
    if modulus_bits ~= 1024 and modulus_bits ~= 2048 and modulus_bits ~= 3072 then
        log.output('create_object_pubkey(): MODULUS size not 1024, 2048, 3072!')
        return CKR.ATTRIBUTE_VALUE_INVALID
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


    self:invalidate_xproc_cache()
    self.arjo_hcard:auto_perform_mutual_authenticate()

    local usBin
    
    local label = pTemplate[CKA.LABEL] or ''
    local id = pTemplate[CKA.ID] or ''
    local modulusLength = modulus_bits
    local pubKDBin, objNum = self:virtual_add_public_key_object(
                                self._indexes._public_keys_bin,
                                label,
                                id,
                                keyReference,
                                obj.key_bits)
    if string.len(pubKDBin) ~= string.len(self._indexes._public_keys_bin) then
        log.output('create_object_pubkey(): no more space left in Public KD file!')
        return CKR.DEVICE_MEMORY
    end
    obj.num = objNum
    obj.kid = keyReference
    log.output(string.format("create_object_pubkey(): new obj num:%d kid:%d bits:%d", 
        obj.num, obj.kid, obj.key_bits) )

    if usBin then
        log.output('create_object_pubkey(): writing unused space...')
        self:_write_file(usBin, self.files.US)
        self._indexes._unused_space_bin = usBin
    end
    
    log.output('create_object_pubkey(): writing public key objects directory...')
    self:_write_file(pubKDBin, self.files.PubKD)
    self._indexes._public_keys_bin = pubKDBin
    
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    
    
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

function t.mt:create_object_certificate(pTemplate)
    local usBin, usObj, FAuthId
    log.output('create_object_certificate()', pTemplate)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    if not pTemplate[CKA.VALUE] then
        log.output('create_object_certificate(): VALUE not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    local actual_cert_data = pTemplate[CKA.VALUE]
    if self.use_cpr_mode then
        local cpr = zlib.compresscer( pTemplate[CKA.VALUE])
        local decpr = cpr and zlib.decompresscer(cpr)
        if decpr == actual_cert_data then
            actual_cert_data = cpr
            pcall(function()
            log.output('create_object_certificate(): cpr ratio:', 
                string.len(cpr)/string.len(pTemplate[CKA.VALUE]))
            end)
        else
            log.output('create_object_certificate(): compression failed!')
        end
    end

    obj = GetCertTemplate(t.mt.get_certificate)
    obj.private = false
    local parsed_cer
    local hint
    
    pcall(function() parsed_cer = der.parse_x509cer( pTemplate[CKA.VALUE]) end )
    
    if not parsed_cer or not parsed_cer.modulus then
        log.output('create_object_certificate(): parse certificate failed!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    local find_template = {
        [CKA.CLASS]=eCK.ULONG(CKO.PRIVATE_KEY),
        [CKA.MODULUS]=parsed_cer.modulus,
    }
    local hKey = self:get_item({}, true, find_template)
    if not hKey or hKey == 0 then
        log.output('create_object_certificate(): unable to find related privte key, importing as CA or single certificate')
    else
        local objPriv = self.attributes[hKey]
        if not objPriv then
            log.output('create_object_certificate(): internal error, null reference')
            return CKR.FUNCTION_FAILED
        end
        hint = objPriv.kid
    end

    usBin, usObj = self:virtual_alloc_cert(self._indexes._unused_space_bin, string.len(actual_cert_data), hint)
    if string.len(usBin) ~= string.len(self._indexes._unused_space_bin) then
        log.output('create_object_certificate(): no more space left in unused space file!')
        return CKR.DEVICE_MEMORY
    end
    if not usObj then
        log.output('create_object_certificate(): no more public space available!')
        return CKR.DEVICE_MEMORY
    end
    log.output("create_object_certificate(): using FID:", hex.hexify(usObj.path.efidOrPath))
    obj.path = {
            efidOrPath = usObj.path.efidOrPath,
            length = string.len(actual_cert_data),
            index=0,
    }
    obj.file = usObj.path.efidOrPath
    
    local HolderCD, objNum = self:virtual_add_cert_object(
        self._indexes._certificates_bin,
        pTemplate[CKA.LABEL] or '',
        pTemplate[CKA.ID] or '',
        obj.path.efidOrPath,
        obj.path.index, obj.path.length)
    
    if string.len(HolderCD) ~= string.len(self._indexes._certificates_bin) then
        log.output('create_object_certificate(): no more space left in Certificate Holder Directory file!')
        return CKR.DEVICE_MEMORY
    end
    
    obj.num = objNum
    log.output(string.format("create_object_certificate(): new obj num: %d", 
        obj.num) )
        
    self:invalidate_xproc_cache()
    self.arjo_hcard:auto_perform_mutual_authenticate()


    -- scrive il certificato
    self:_write_file(actual_cert_data, obj.file, obj.path.index)
    
    -- scrive unused space
    if usBin then
        self:_write_file(usBin, self.files.US)
        self._indexes._unused_space_bin = usBin
    end
    if HolderCD then
        -- scrive certificate directory file
        self:_write_file(HolderCD, self.files.CDF)
        self._indexes._certificates_bin = HolderCD
    end
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] then
            obj[k] = pTemplate[k]
        end
    end


    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj

    return CKR.OK, self.attributes.max_index
end


function t.mt:generate_key_pair(pMechanism, templatePub, templatePriv)
    local usBin, keyReference, KAuthId
    log.output('generate_key_pair()', templatePub, templatePriv)
    if self.userType ~= CKU.USER then
        log.output('generate_key_pair(): not loggen in, userType', self.userType)
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local templatePub1 = utility.clone_table(templatePub)
    local templatePriv1 = utility.clone_table(templatePriv)
    
    if templatePub1[CKA.ID] then
        templatePriv1[CKA.ID] = templatePub1[CKA.ID]
    elseif templatePriv1[CKA.ID] then
        templatePub1[CKA.ID] = templatePriv1[CKA.ID]
    end
    
    templatePub1[CKA.LOCAL] = eCK.BBOOL(true)
    templatePriv1[CKA.LOCAL] = eCK.BBOOL(true)
    
    templatePriv1[CKA.SIGN] = templatePriv1[CKA.SIGN] or eCK.BBOOL(true)
    templatePriv1[CKA.DECRYPT] = templatePriv1[CKA.DECRYPT] or eCK.BBOOL(true)
    
    templatePriv1[CKA.CLASS] = eCK.ULONG(CKO.PRIVATE_KEY)
    templatePriv1[CKA.KEY_TYPE] = eCK.ULONG(CKK.RSA)
    
    local cka_modulus_bits = templatePub1[CKA.MODULUS_BITS] or templatePriv1[CKA.MODULUS_BITS] or eCK.ULONG(1024)
    local modulus_bits = 1024    
    if not cka_modulus_bits or cka_modulus_bits == eCK.ULONG(1024) then
        modulus_bits = 1024
    elseif cka_modulus_bits == eCK.ULONG(2048) then
        modulus_bits = 2048
    elseif cka_modulus_bits == eCK.ULONG(3072) then
        modulus_bits = 3072
    else
        log.output('generate_key_pair(): key size invalid for selected filesystem:', hex.hexify(cka_modulus_bits or '') )
        return CKR.ATTRIBUTE_VALUE_INVALID    
    end
   
    objPriv = GetPrivKeyTemplate(t.mt.get_privkey)
    objPriv.private = true
    objPriv.key_bits = modulus_bits
    
    self:invalidate_xproc_cache()
    self.arjo_hcard:auto_perform_mutual_authenticate()

    local isDS = self:is_ds(templatePriv1)
    log.output('generate_key_pair(): isDS:', isDS)
    usBin, kObj = self:virtual_alloc_kid(
        self._indexes._unused_space_bin, modulus_bits, isDS)
    if string.len(usBin) ~= string.len(self._indexes._unused_space_bin) then
        log.output('generate_key_pair(): no more space left in unused space file!')
        return CKR.DEVICE_MEMORY
    end
    
    if not kObj then
        log.output('generate_key_pair(): no more space available for this type of object!')
        return CKR.DEVICE_MEMORY
    end
    
    local keyReference = string.byte(kObj.path.efidOrPath, 1)
    
    local kdPriv, objNum = self:virtual_add_private_key_object(
        self._indexes._private_keys_bin,
        templatePriv1[CKA.LABEL] or '',
        templatePriv1[CKA.ID] or '',
        kObj.authId, keyReference, modulus_bits, isDS)
    
    if string.len(kdPriv) ~= string.len(self._indexes._private_keys_bin) then
        log.output('generate_key_pair(): no more space left in Private KD file!')
        return CKR.DEVICE_MEMORY
    end
    
    objPriv.kid = keyReference
    objPriv.num = objNum
    objPriv.userConsent = isDS and 1 or nil
    log.output(string.format("generate_key_pair(): new obj num:%d kid:%d bits:%d", 
        objPriv.num, objPriv.kid, objPriv.key_bits) )
    
    self.arjo_hcard:auto_perform_mutual_authenticate()
    log.output('generate_key_pair(): verify_pin_main() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.arjo_hcard:verify_pin_main(self.cached_main_pin, false)  -- pin, ispuk
    end
    
    log.output('generate_key_pair(): generating key pair...')
    self.arjo_hcard:generate_key_pair(kObj.path.efidOrPath)
    local modulus, pubExp = self.arjo_hcard:read_public_key(kObj.path.efidOrPath)
    templatePub1[CKA.MODULUS] = modulus
    templatePub1[CKA.PUBLIC_EXPONENT] = pubExp
    templatePub1[CKA.CLASS] = eCK.ULONG(CKO.PUBLIC_KEY)
    templatePub1[CKA.KEY_TYPE] = eCK.ULONG(CKK.RSA)
    templatePub1[CKA.TOKEN] = eCK.BBOOL(true)



    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if templatePriv1[k] and not t._is_private_attribute(k) then
            objPriv[k] = templatePriv1[k]
        end
    end
    
    objPriv[CKA.MODULUS] = modulus        -- cache preventiva
    objPriv[CKA.PUBLIC_EXPONENT] = pubExp
    objPriv[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
    
    if usBin then
        log.output('generate_key_pair(): writing unused space...')
        self._indexes._unused_space_bin = usBin
        self:_write_file(usBin, self.files.US)
    end

    if kdPriv then
        log.output('generate_key_pair(): writin private key objects directory...')
        self:_write_file(kdPriv, self.files.PrivKD)
        self._indexes._private_keys_bin = kdPriv
    end
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPriv
    local hPrivk = self.attributes.max_index
    
    local rv, hPubk = self:create_object_pubkey(templatePub1, keyReference, true)
    log.output('create_object(pubkey): result:', rv, 'handle:', hPubk)
    log.output('generate_key_pair(): success, returning', hPubk, hPrivk)
    
    
    self:update_free_mem(self.info)
    return CKR.OK, hPubk, hPrivk
end


function t.mt:create_object(pTemplate)
    log.output('create_object(): verify_pin_main() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.arjo_hcard:verify_pin_main(self.cached_main_pin, false)  -- pin, ispuk, check, use_sm
    end
    
    if pTemplate[CKA.PRIVATE]
        and pTemplate[CKA.PRIVATE] ~= eCK.BBOOL(false)
        and self.userType ~= CKU.USER then
        log.output('create_object(): not logged in: login required to create private objects')
    end

    local rv, hObj
    
    self:invalidate_xproc_cache()
    
    if pTemplate[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        rv, hObj = self:create_object_certificate(pTemplate)
    else
        log.output('create_object(): unsupported object class:', hex.hexify(pTemplate[CKA.CLASS] or ''))
        rv = CKR.ATTRIBUTE_VALUE_INVALID
    end
    if rv == CRK_OK then
        self:update_free_mem(self.info)
    end
    return rv, hObj
end

function t.mt:_renumber_objects(objRef)
    local obj
    for i=self.attributes.min_index, self.attributes.max_index do
        obj = self.attributes[i]
        if type(obj) == "table" 
            and obj[CKA.CLASS] == objRef[CKA.CLASS]
            and obj.private == objRef.private 
            and obj.num and objRef.num 
            and obj.num > objRef.num then
            obj.num = obj.num -1
        end
    end
end

function t.mt:_related_key_exists(kid, excludeNum)
    local obj
    for i=self.attributes.min_index, self.attributes.max_index do
        obj = self.attributes[i]
        if type(obj) == "table" and obj.kid == kid and obj.num ~= excludeNum then
            return true
        end
    end
    return false
end

function t.mt:destroy_object(hObject)
    log.output('destroy_object(): ', hObject)
    
    
    log.output('destroy_object(): verify_pin_main() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.arjo_hcard:verify_pin_main(self.cached_main_pin, false)  -- pin, ispuk, check, use_sm
    end
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hObject]
    
    if obj == nil then return CKR.OBJECT_HANDLE_INVALID end
    
    if obj.private then
        if self.userType ~= CKU.USER then
            return CKR.USER_NOT_LOGGED_IN
        end    
    end
    
    self:invalidate_xproc_cache()
    self.arjo_hcard:auto_perform_mutual_authenticate()
        
    if obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        local usBin
        log.output('destroy_object(): destroyng a certificate')
        -- rimuove la entry indicata da "obj.num" dall'index
        local d = p15.parseCertDF(self._indexes._certificates_bin)
        if obj.num > table.getn(d) then
            log.output('destroy_object(): obj.num invalid:', obj.num)
            return CKR.FUNCTION_FAILED
        end
        table.remove(d, obj.num)
        local HolderCD = p15.buildCertDF(d)
        HolderCD = HolderCD .. string.rep("\000", string.len(self._indexes._certificates_bin) - string.len(HolderCD))
        
        -- libera lo spazio allocato
        usBin = self:virtual_release_cert(
                            self._indexes._unused_space_bin,
                            obj.path.efidOrPath,
                            obj.path.index,
                            obj.path.length)
                                            
        -- riscrive gli indici:
        
        if string.len(usBin) ~= string.len(self._indexes._unused_space_bin) then
            log.output(
                'destroy_object(): CRITICAL WARNING: no more space left in the unused space file. following Space is lost:',
                    hex.hexify(obj.path.efidOrPath),
                    obj.path.index,
                    obj.path.length)
            usBin = self._indexes._unused_space_bin
        else
            -- scrive unused space
            self:_write_file(usBin, self.files.US)
        end
        -- azzera lo spazio occupato
        -- self:_write_file(string.rep("\000", obj.path.length), obj.file, obj.path.index)
        
        -- scrive certificate directory file
        self:_write_file(HolderCD, self.files.CDF)

        self._indexes._certificates_bin = HolderCD
        self._indexes._unused_space_bin = usBin
        
        -- elimina l'oggetto dalla lista
        self.attributes[hObject] = nil
        
        -- rinumera tutti gli oggetti certificate con num > obj.num
        self:_renumber_objects(obj)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        log.output('destroy_object(): destroyng a public key')
        -- rimuove la entry indicata da "obj.num" dall'index
        local usBin, pkBin
        local d = p15.parsePubPrivKD(self._indexes._public_keys_bin)
        if obj.num > table.getn(d) then
            log.output('destroy_object(): obj.num invalid:', obj.num)
            return CKR.FUNCTION_FAILED
        end
        table.remove(d, obj.num)
        pkBin = p15.buildPubPrivKD(d)
        pkBin = pkBin .. string.rep("\000", string.len(self._indexes._public_keys_bin) - string.len(pkBin))

        -- -- cerca la chiave privata associata tramite la key reference: se non c'