 che determinare la size di questo specifico attributo
-- pesa quanto determinarne il contenuto. Quando viene chiesta solo
-- la size viene quindi ritornato il contenuto al fine fi farlo mettere
-- in cache per una probabile successiva richiesta.
function t.mt:get_certificate(hobj, att_type, onlysize)
-- Setta CKA.VALUE, CKA.SUBJECT, CKA.ISSUER, CKA.SERIAL_NUMBER
    local path = nil
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.CERTIFICATE) then
        log.output('get_certificate(): WARNING: function called on a non certificate object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    if obj.path ~= nil then path=hex.hexf(obj.path) end
    
    local info = self:get_info()
    
    local result
    if self:cache_enabled() then
        result = utility.cache_read(info.serialNumber, path, self._AvoidUseLastUpdate, self._umcachepath)
        
        log.output('get_certificate(): value from cache:', hex.hexify(result or ""))
    end

    if not result then
        local pcRes, theErrorT = pcall(function()
            result = self.cns_hcard:read_x509_certificate(path)
        end)
        if not pcRes then
            log.output('get_certificate(): read_x509_certificate ERROR:', theErrorT)
            return CKR.FUNCTION_FAILED
        end
    
        log.output('get_certificate(): value from card:', hex.hexify(result or ""))
        if result and self:cache_enabled() then
            utility.cache_write(info.serialNumber, path, result, self._umcachepath)
        end
    end

    if not result then
        log.output('get_certificate(): ERROR: no value!')
        return CKR.FUNCTION_FAILED
    end
    
    local clean_result = extract_x509_certificate(result)
    if clean_result ~= result then
        log.output('get_certificate(): clean_result:', hex.hexify(clean_result or ""))
    end
    local parsed_cer = der.parse_x509cer(clean_result)
    obj[CKA.VALUE] = clean_result
    obj[CKA.SUBJECT] = parsed_cer.subject
    obj[CKA.ISSUER] = parsed_cer.issuer
    obj[CKA.SERIAL_NUMBER] = parsed_cer.serialNumber
    obj.populated=true
    return CKR.OK, obj[att_type]
end

function t.mt:get_public_key(hobj, att_type, onlysize)
-- Setta CKA.MODULUS, CKA.PUBLIC_EXPONENT, CKA.MODULUS_BITS
    log.output('get_public_key():', hobj, att_type)
    local path = nil
    local obj = self.attributes[hobj]
    if obj.related_public_key ~= nil then
        path = hex.hexf(obj.related_public_key)
    elseif obj[CKA.CLASS] == eCK.OBJECT_CLASS(CKO.PUBLIC_KEY)
                                        and obj.path ~= nil then
        path = hex.hexf(obj.path)
    end
    if path == nil then
        log.output('get_public_key(): WARNING: public key path not specified!')
        obj[CKA.MODULUS] = -2
        obj[CKA.PUBLIC_EXPONENT] = -2
        obj[CKA.MODULUS_BITS] = -2
        -- risponde dato sensibile o non disponibile
        return CKR.OK, obj[att_type]
    end
    
    local pcRes, modulus, exponent
    local info = self.info
    if self:cache_enabled() and info then
        modulus = utility.cache_read(info.serialNumber, path .. "rmod", self._AvoidUseLastUpdate, self._umcachepath)
        exponent = utility.cache_read(info.serialNumber, path .. "rexp", self._AvoidUseLastUpdate, self._umcachepath)
        
        pcRes = type(modulus) == "string" and string.len(modulus) == (obj.key_bits/8)
            and type(exponent) == "string" and string.len(exponent) >0
    end
    if not pcRes then
        pcRes, modulus, exponent = pcall( function() 
            if obj.key_bits and obj.key_bits > 1024 then
                self.cns_hcard:select(path)
                local modulus = self.cns_hcard:mread_binary(0, 256)
                local pubExp =  self.cns_hcard:mread_binary(256, 8)
                while string.sub(pubExp, 1, 1) == '\000' do pubExp = string.sub(pubExp, 2, -1) end
                return modulus, pubExp
            else
                return self.cns_hcard:read_public_key(path)
           end 
        end)
        if pcRes and modulus and exponent and self:cache_enabled() then
            utility.cache_write(info.serialNumber, path .. "rexp", exponent, self._umcachepath)
            utility.cache_write(info.serialNumber, path .. "rmod", modulus, self._umcachepath)
        end
    end
    if not pcRes then
        log.output('get_public_key(): error reading public key @', hex.hexify(path), ':\n', modulus)
    elseif modulus == nil or exponent == nil then
        log.output('get_public_key(): modulus or exponent are nil!')
        obj[CKA.MODULUS] = -2
        obj[CKA.PUBLIC_EXPONENT] = -2
        obj[CKA.MODULUS_BITS] = -2
    else
        obj[CKA.MODULUS] = modulus
        obj[CKA.PUBLIC_EXPONENT] = exponent
        obj[CKA.MODULUS_BITS] = eCK.ULONG(string.len(modulus) * 8)
    end
    obj.populated=true
    return CKR.OK, obj[att_type]
end


function t.mt:get_public_key_ecc(hobj, att_type, onlysize)
-- Setta CKA.MODULUS, CKA.PUBLIC_EXPONENT, CKA.MODULUS_BITS
    log.output('get_public_key_ecc():', hobj, att_type)
    local path = nil
    local obj = self.attributes[hobj]
    if obj.related_public_key ~= nil then
        path = hex.hexf(obj.related_public_key)
    elseif obj[CKA.CLASS] == eCK.OBJECT_CLASS(CKO.PUBLIC_KEY) and obj.path ~= nil then
        path = hex.hexf(obj.path)
    end
    if path == nil then
        log.output('get_public_key_ecc(): WARNING: public key path not specified!')
        obj[CKA.EC_POINT] = -2
        -- risponde dato sensibile o non disponibile
        return CKR.OK, obj[att_type]
    end
    
    local pcRes, point
    local info = self.info
    if self:cache_enabled() and info then
        point = utility.cache_read(info.serialNumber, path .. "point", self._AvoidUseLastUpdate, self._umcachepath)

        pcRes = type(point) == "string" and string.len(point) > 0
    end
    if not pcRes then
        pcRes, point = pcall(function()
            return self.cns_hcard:jsign_ecdsa_read_public_key(path)
        end)
        if pcRes and point and self:cache_enabled() then
            utility.cache_write(info.serialNumber, path .. "point", point, self._umcachepath)
        end
    end
    if not pcRes then
        log.output('get_public_key_ecc(): error reading public key @', hex.hexify(path), ':\n', point)
    elseif point == nil then
        log.output('get_public_key_ecc(): modulus or exponent are nil!')
        obj[CKA.EC_POINT] = -2
    else
        obj[CKA.EC_POINT] = der.build(der.STRING, point)
    end
    obj.populated=true
    return CKR.OK, obj[att_type]
end

function t.mt:get_pdata(hobj, att_type, onlysize)
-- Setta CKA.VALUE
    local path = nil
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.DATA) then
        log.output('get_pdata(): WARNING: function called on a non DATA object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    if obj.path == nil then
        log.output('get_pdata(): WARNING: function called on a invalid PDATA object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    path=hex.hexf(obj.path)
    
    pDataValue = self:read_cached_file(path, 0, 400, true, true)
    
    obj[CKA.VALUE] = pDataValue
    obj.populated=true
    return CKR.OK, obj[att_type]
end

function t.mt:cache_enabled()
    return utility.cache_can_use() and self.cfg["fastread"]=='true'
end

-- legge il valore da un file di attributi PKCS#11
function t.mt:get_p11_attribute(num, oType, aType)
    local len_s, len_n, val_s, bReadRes
    local path = hexf(self.p11_info.path_root .. '%H', self:buildP11Fid(num, oType, aType) )
    log.output('get_p11_attribute(): reading attribute @ ', hex.hexify(path) )
    local info = self:get_info()
    if self:cache_enabled() then
        val_s = utility.cache_read(info.serialNumber, path, self._AvoidUseLastUpdate, self._umcachepath)
        if val_s then
            if string.len(val_s or '') == 0 then val_s = nil end
            return val_s
        end
    end
    if pcall(function() 
        return self.cns_hcard:select(path) 
        end ) then
        bReadRes, len_s = pcall(function() return self.cns_hcard:read_binary(1, 2) end )
        if not bReadRes then 
            log.output('get_p11_attribute(): read binary to get attr len failed:', len_s)
            return ''
        end
        len_n = string.byte(len_s,1) * 2^8 + string.byte(len_s,2)
        bReadRes, val_s = pcall(function() return self.cns_hcard:mread_binary(5, len_n) end)
        if not bReadRes then 
            log.output('get_p11_attribute(): read binary to get attr value failed:', val_s)
            return ''
        end
    else
        val_s = ''
    end
    if self:cache_enabled() then
        utility.cache_write(info.serialNumber, path, val_s, self._umcachepath)
    end
    if string.len(val_s or '') == 0 then val_s = nil end
    return val_s
end

function id2name(id, d)
    for i, v in d do
        if id == v then
            return i
        end
    end
    return "UNKNOWN"
end

function t.mt:_bit_fields2attr(obj, bit_field, attr_map)
    local ck_true = eCK.BBOOL(true)
    local ck_false = eCK.BBOOL(false)
    for i, v in attr_map do
        if bit_field[v.flag] then
            obj[v.attr_type] = ck_true
        else
            obj[v.attr_type] = ck_false
        end
    end
end

function t.mt:get_privkey_p11(hobj, att_type, onlysize)
-- Setta CKA.LABEL, CKA.ID, CKA.MODULUS, CKA.PUBLIC_EXPONENT
    local id = nil
    local obj = self.attributes[hobj]

    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('get_privkey_p11(): ERROR! not a private key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    pcall(function() 
        self:auto_verify_pin_main()
    end)
    local main_attr_path = hexf(obj.parent_path .. '%H', self:buildP11Fid(obj.num, objTypes.ePrivKey, attrTypes.eMain))
    local bReadRes, obj_info
    local info = self:get_info()
    
    obj_info = self:read_cached_file(main_attr_path, 0, -1, true, true)
    bReadRes = obj_info ~= nil
    
    -- if self:cache_enabled() then
        -- obj_info = utility.cache_read(info.serialNumber, main_attr_path, self._AvoidUseLastUpdate, self._umcachepath)
        -- bReadRes = true
    -- end
    -- local finfo
    
    -- if not obj_info then
        
        
        -- bReadRes = pcall(function()
            -- finfo = self.cns_hcard:select(main_attr_path, true)
            -- if not finfo then finfo = {size=512} end
        -- end)
     
        -- if bReadRes then
            -- bReadRes, obj_info = pcall(function() return self.cns_hcard:mread_binary(0, finfo.size) end )
            -- if bReadRes and obj_info and self:cache_enabled() then
                -- utility.cache_write(info.serialNumber, main_attr_path, obj_info, self._umcachepath)
            -- end
        -- end
    -- end
    
    local try_v1_parse = true
    if self.p11_info.version_major >= 2 then
        try_v1_parse = false
        if bReadRes and string.len(obj_info) > 0 then
            local pcRes, theErrorT = pcall(function()
                t.parse_p11v2_privkey_attribute(obj, obj_info)
            end)
            
            if not pcRes then
                log.output('get_privkey_p11(): error parsing main attributes file:', theErrorT)
                try_v1_parse = string.len(obj_info) == 32
            elseif string.len(obj_info) == 32 and 
                (not obj[CKA.MODULUS] or string.len(obj[CKA.MODULUS]) == 0) then
                log.output('get_privkey_p11(): detected possible v1 object on JSign!')
                try_v1_parse = true
            end
        else
            log.output('get_privkey_p11(): error reading main attributes file, object:', hobj)
            obj.kid = 0
            obj.key_bits = 1024
        end
    end
    if try_v1_parse then
        if bReadRes and string.len(obj_info) >= 32 then
            local bit_fields, start_date, end_date
            bit_fields = bin.flags(bin.unpack("%<%H", string.sub(obj_info, 1, 2) ))
            start_date = string.sub(obj_info, 3, 10)
            end_date = string.sub(obj_info, 11, 18)
            obj.key_bits = bin.unpack("%>%H", string.sub(obj_info, 19, 20) )
            log.output("get_privkey_p11(): obj.key_bits:", obj.key_bits)

            obj.kid = string.byte(obj_info, 25)
            obj[CKA.START_DATE] = start_date
            obj[CKA.END_DATE] = end_date
            local attr_map = {}
            for i, v in privkey_bitfields do
                table.insert(attr_map, {flag=v, attr_type=CKA[i]} )
            end
            self:_bit_fields2attr(obj, bit_fields, attr_map)
            
            obj[CKA.LABEL] = self:get_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.eLabel) or ''
            obj[CKA.ID] = self:get_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.eID) or ''
            obj[CKA.MODULUS] = self:get_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.eModulus) or ''
            obj[CKA.PUBLIC_EXPONENT] = self:get_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.ePubExp) or ''
            if obj.key_bits < 1024 then
                obj.key_bits = math.max(1024, 8 * string.len(obj[CKA.MODULUS]))
                log.output("get_privkey_p11(): WARNING: wrong key_bits, patched to ", obj.key_bits) 
            end
        else
            log.output('get_privkey_p11(): error reading main attributes file, object:', hobj)
            obj.kid = 0
            obj.key_bits = 1024
        end
    end
    
    obj[CKA.MODULUS_BITS] = eCK.ULONG(obj.key_bits)
    obj[CKA.ID] = obj[CKA.ID] or ''
    obj.populated=true
    return CKR.OK, obj[att_type]
end

function t.mt:get_pubkey_p11(hobj, att_type, onlysize)
-- Setta CKA.LABEL, CKA.ID, CKA.MODULUS, CKA.PUBLIC_EXPONENT
    local id = nil
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PUBLIC_KEY) then
        log.output('get_pubkey_p11(): ERROR! not a public key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end

    local main_attr_path = hexf(obj.parent_path .. '%H', self:buildP11Fid(obj.num, objTypes.ePubKey, attrTypes.eMain))
    local bReadRes, obj_info
    local pcRes, theErrorT
    local info = self:get_info()
    
    obj_info = self:read_cached_file(main_attr_path, 0, -1, true, true)
    bReadRes = obj_info ~= nil
    
    
    -- if self:cache_enabled() then
        -- obj_info = utility.cache_read(info.serialNumber, main_attr_path, self._AvoidUseLastUpdate, self._umcachepath)
        -- bReadRes = true
    -- end
    
    -- local finfo

    
    -- if not obj_info then
        -- pcRes, theErrorT = pcall(function()
                    -- finfo = self.cns_hcard:select(main_attr_path, true)
                    -- if not finfo then 
                        -- finfo = {size=512}
                    -- end
                -- end)
        -- if not pcRes then
            -- log.output('get_pubkey_p11(): select error', theErrorT)
        -- else
            -- bReadRes, obj_info = pcall(function() return self.cns_hcard:mread_binary(0, finfo.size) end )
            -- if not bReadRes then
                -- log.output('get_pubkey_p11(): error', obj_info)
            -- elseif bReadRes and obj_info and self:cache_enabled() then
                -- utility.cache_write(info.serialNumber, main_attr_path, obj_info, self._umcachepath)
            -- end
        -- end
    -- end
       
    local try_v1_parse = true
    if self.p11_info.version_major >= 2 then
        try_v1_parse = false
        if bReadRes and string.len(obj_info) > 0 then
            local pcRes, theErrorT = pcall(function()
                t.parse_p11v2_pubkey_attribute(obj, obj_info)
            end)
            if not pcRes then
                log.output('get_pubkey_p11(): error parsing main attributes file:', theErrorT)
                try_v1_parse = string.len(obj_info) == 32
            elseif string.len(obj_info) == 32 and 
                    (not obj[CKA.ID] or string.len(obj[CKA.ID]) == 0) and
                    (not obj[CKA.LABEL] or string.len(obj[CKA.LABEL]) == 0) then
                log.output('get_pubkey_p11(): detected possible v1 object on JSign!')
                try_v1_parse = true
            end
        else
            log.output('get_pubkey_p11(): error reading main attributes file, object:', hobj)
            obj.kid = 0
            obj.key_bits = 1024
        end
    end
    
    if try_v1_parse then
        log.output('get_pubkey_p11(): v1 FS')
        
        if bReadRes and string.len(obj_info) >= 32 then
            local bit_fields, start_date, end_date
            bit_fields = bin.flags(bin.unpack("%<%H", string.sub(obj_info, 1, 2) ))
            start_date = string.sub(obj_info, 3, 10)
            end_date = string.sub(obj_info, 11, 18)
            obj.key_bits = bin.unpack("%>%H", string.sub(obj_info, 19, 20) )
            log.output("get_pubkey_p11(): obj.key_bits:", obj.key_bits)
            if obj.key_bits < 1024 then
                log.output("get_pubkey_p11(): WARNING: wrong key_bits, patched to 1024")
                obj.key_bits = 1024
            end
            obj[CKA.START_DATE] = start_date
            obj[CKA.END_DATE] = end_date
            local attr_map = {}
            for i, v in pubkey_bitfields do
                table.insert(attr_map, {flag=v, attr_type=CKA[i]} )
            end
            self:_bit_fields2attr(obj, bit_fields, attr_map)

            obj[CKA.LABEL] = self:get_p11_attribute(obj.num, objTypes.ePubKey, attrTypes.eLabel) or ''
            obj[CKA.ID] = self:get_p11_attribute(obj.num, objTypes.ePubKey, attrTypes.eID) or ''

        else
            log.output('get_pubkey_p11(): error reading main attributes file, object:', hobj)
            obj.key_bits = 1024
        end
    end

    
    obj[CKA.MODULUS_BITS] = eCK.ULONG(obj.key_bits)
    
    log.output('get_pubkey_p11(): obj.key_bits:', obj.key_bits)
    if obj.key_bits > 1024 then
            local bReadRes, theErrorT
            local modulus, pubExp
            log.output('get_pubkey_p11(): reading 2048 bit key type')
            local pubkfid = hexf(obj.parent_path .. '%H', self:buildP11Fid(obj.num, objTypes.ePubKey, attrTypes.ePubKeyModExp))
            if self:cache_enabled() then
                local pubkey = utility.cache_read(info.serialNumber, pubkfid, self._AvoidUseLastUpdate, self._umcachepath)
                if pubkey then
                    modulus = string.sub(pubkey, 1, 256)
                    pubExp = string.sub(pubkey, 257, -1)
                    bReadRes=true
                end
            end
            if not modulus or not pubExp then
                bReadRes, theErrorT = pcall(function()
                    self.cns_hcard:select(pubkfid)
                    modulus = self.cns_hcard:mread_binary(0, 256)
                    pubExp =  self.cns_hcard:mread_binary(256, 8)
                    
                    if self:cache_enabled() then
                        utility.cache_write(info.serialNumber, pubkfid, modulus .. pubExp, self._umcachepath)
                    end
                end)
            end
            if not bReadRes then
                log.output("get_pubkey_p11(): 2048, error:", theErrorT)
                return CKR.ATTRIBUTE_TYPE_INVALID, nil
            end
            

            while string.sub(pubExp, 1, 1) == '\000' do pubExp = string.sub(pubExp, 2, -1) end
            obj[CKA.MODULUS] = modulus
            obj[CKA.PUBLIC_EXPONENT] = pubExp
    else
        log.output('get_pubkey_p11(): reading 1024 bit key type')
        self:get_public_key(hobj, att_type, onlysize)
    end
    obj.populated=true
    log.output('get_pubkey_p11(): finished')
    return CKR.OK, obj[att_type]
end


function t.mt:get_certificate_p11(hobj, att_type, onlysize)
-- Setta CKA.VALUE, CKA.SUBJECT, CKA.ISSUER, CKA.SERIAL_NUMBER, CKA.ID, CKA.LABEL
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    local path = nil
    if obj == nil then 
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.CERTIFICATE) then
        log.output('get_certificate_p11(): ERROR! not a certificate object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    if obj.path ~= nil then path=hex.hexf(obj.path) end
    
    local info = self:get_info()
    
    local result
    if self:cache_enabled() then
        result = utility.cache_read(info.serialNumber, path, self._AvoidUseLastUpdate, self._umcachepath)
    end

    if not result then
        local pcRes, theErrorT = pcall(function()
            result = self.cns_hcard:read_x509_certificate(path, 5)
        end)
        if not pcRes then
            log.output('get_certificate_p11(): read_x509_certificate ERROR:', theErrorT)
            return CKR.FUNCTION_FAILED
        end
        if result and self:cache_enabled() then
            utility.cache_write(info.serialNumber, path, result, self._umcachepath)
        end
    end
    
    if not result then
        log.output('get_certificate(): ERROR: no value!')
        return CKR.FUNCTION_FAILED
    end
    
    local parsed_cer = der.parse_x509cer(result) or {}
    obj[CKA.VALUE] = result
    obj[CKA.SUBJECT] = parsed_cer.subject or ''
    obj[CKA.ISSUER] = parsed_cer.issuer or ''
    obj[CKA.SERIAL_NUMBER] = parsed_cer.serialNumber or ''

    local main_attr_path = hexf(obj.parent_path .. '%H', self:buildP11Fid(obj.num, objTypes.eCert, attrTypes.eMain))
    local bReadRes, obj_info
    if self:cache_enabled() then
        obj_info = utility.cache_read(info.serialNumber, main_attr_path, self._AvoidUseLastUpdate, self._umcachepath)
        bReadRes = true
    end
    
    local finfo
    if obj_info or pcall(function()
            finfo = self.cns_hcard:select(main_attr_path, true)
            if not finfo then finfo = {size=512} end
            end 
            ) then
        if not obj_info then
            bReadRes, obj_info = pcall(function() return self.cns_hcard:mread_binary(0, finfo.size) end )
            if bReadRes and obj_info and self:cache_enabled() then
                utility.cache_write(info.serialNumber, main_attr_path, obj_info, self._umcachepath)
            end
        end
        local try_v1_parse = true
        if self.p11_info.version_major >= 2 then
            try_v1_parse = false
            if bReadRes and string.len(obj_info) > 0 then
                local pcRes, theErrorT = pcall(function()
                    t.parse_p11v2_cert_attribute(obj, obj_info)
                end)  
                if not pcRes then
                    log.output('get_certificate_p11(): error parsing main attributes file:', theErrorT)
                    try_v1_parse = string.len(obj_info) == 32
                elseif string.len(obj_info) == 32 and 
                    (not obj[CKA.ID] or string.len(obj[CKA.ID]) == 0) and
                    (not obj[CKA.LABEL] or string.len(obj[CKA.LABEL]) == 0) then
                    log.output('get_certificate_p11(): detected possible v1 object on JSign!')
                    try_v1_parse = true
                end
            else
                log.output('get_certificate_p11(): error reading main attributes file, object:', hobj)
            end
        end
        if try_v1_parse then
            if bReadRes and string.len(obj_info) >= 32 then
                local bit_fields, start_date, end_date
                bit_fields = bin.flags(bin.unpack("%<%H", string.sub(obj_info, 1, 2) ))
                local attr_map = {}
                for i, v in cert_data_bitfields do
                    table.insert(attr_map, {flag=v, attr_type=CKA[i]} )
                end
                self:_bit_fields2attr(obj, bit_fields, attr_map)
            else
                log.output('get_certificate_p11(): error reading main attributes file, object:', hobj)
            end
            obj[CKA.LABEL] = self:get_p11_attribute(obj.num, objTypes.eCert, attrTypes.eLabel) or ''
            obj[CKA.ID] = self:get_p11_attribute(obj.num, objTypes.eCert, attrTypes.eID) or ''
        end
    end
    
    obj.populated=true
    return CKR.OK, obj[att_type]
end

function t.mt:get_data_p11(hobj, att_type, onlysize)
-- Setta CKA.LABEL, CKA.ID, CKA.APPLICATION, SKA.VALUE
    local id = nil
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.DATA) then
        log.output('get_data_p11(): ERROR! not a data object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end

    obj[CKA.VALUE] = self:get_p11_attribute(obj.num, objTypes.eData, attrTypes.eValue) or ''
    
    local main_attr_path = hexf(obj.parent_path .. '%H', self:buildP11Fid(obj.num, objTypes.eData, attrTypes.eMain))
    local bReadRes, obj_info
    local info = self:get_info()
    
    obj_info = self:read_cached_file(main_attr_path, 0, -1, true, true)
    bReadRes = obj_info ~= nil
    
    
    -- if self:cache_enabled() then
        -- obj_info = utility.cache_read(info.serialNumber, main_attr_path, self._AvoidUseLastUpdate, self._umcachepath)
        -- bReadRes = true
    -- end
    
    -- local finfo
    -- if obj_info or pcall(function()
            -- finfo = self.cns_hcard:select(main_attr_path, true)
            -- if not finfo then finfo = {size=512} end
            -- end 
            -- ) then
        -- if not obj_info then
            -- bReadRes, obj_info = pcall(function() return self.cns_hcard:mread_binary(0, finfo.size) end )
            -- if bReadRes and obj_info and self:cache_enabled() then
                -- utility.cache_write(info.serialNumber, main_attr_path, obj_info, self._umcachepath)
            -- end
        -- end
        
        if self.p11_info.version_major >= 2 then
            if bReadRes and string.len(obj_info) > 0 then
                t.parse_p11v2_data_attribute(obj, obj_info)
            else
                log.output('get_data_p11(): error reading main attributes file, object:', hobj)
            end
        else
            if bReadRes and string.len(obj_info) >= 32 then
                local bit_fields, start_date, end_date
                bit_fields = bin.flags(bin.unpack("%<%H", string.sub(obj_info, 1, 2) ))
                local attr_map = {}
                for i, v in cert_data_bitfields do
                    table.insert(attr_map, {flag=v, attr_type=CKA[i]} )
                end
                self:_bit_fields2attr(obj, bit_fields, attr_map)
            else
                log.output('get_data_p11(): error reading main attributes file, object:', hobj)
            end
            obj[CKA.LABEL] = self:get_p11_attribute(obj.num, objTypes.eData, attrTypes.eLabel) or ''
            obj[CKA.APPLICATION] = self:get_p11_attribute(obj.num, objTypes.eData, attrTypes.eApplication)
            obj[CKA.OBJECT_ID] = self:get_p11_attribute(obj.num, objTypes.eData, attrTypes.eObjectId)
        end
    -- end
    
    obj.populated=true
    return CKR.OK, obj[att_type]
end


--=====================================================================================

                      
function t.mt:sign_buffer(hKey, pMechanism, pData, allocated_space)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('sign_buffer(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('sign_buffer(): ERROR: non private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    if obj.dsx then
        if obj.curve then
            return self:sign_buffer_ecdsa_dsx(hKey, pMechanism, pData, allocated_space)
        else
            return self:sign_buffer_dsx(hKey, pMechanism, pData, allocated_space)
        end
    end
    local keyBytes
    
    if type(obj.key_bits) == 'function' then    
        obj.key_bits(self, hKey, CKA.CLASS)
        keyBytes = obj.key_bits/8
    elseif type(obj.key_bits) == 'number' then
        keyBytes = obj.key_bits/8
    else
        keyBytes = 128
    end

    if keyBytes > 128 and not self._license_valid then
        log.output('sign_buffer(): ERROR: invalid license for this key size: ', keyBytes)
        return CKR.KEY_FUNCTION_NOT_PERMITTED
    end
    
    local dataLen = string.len(pData)
    local pcRes, result
    
    if dataLen > keyBytes or (dataLen > (keyBytes -4) and dataLen <  keyBytes) then
        -- nota: il padding pkcs1 richiede almeno 8 byte di oxFF prima dei dati da firmare
        log.output('sign_buffer(): specified data len invalid: ', dataLen)
        return CKR.DATA_LEN_RANGE
    end
    if allocated_space==nil then
        return CKR.OK, keyBytes
    else
        if type(obj.kid) == 'function' then
            local rv = obj.kid(self, hKey, CKA.CLASS, false)
            if rv ~= CKR.OK then return rv end
        end
        pcall(function()
            self:auto_verify_pin_main()
        end)
        if obj.pso_dec then -- usa la modalit