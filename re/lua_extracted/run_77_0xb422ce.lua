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
    local result = self.cns_hcard:read_x509_certificate(path)
    local parsed_cer = der.parse_x509cer(result)
    obj[CKA.VALUE] = result
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
    local pcRes, modulus, exponent = pcall( function() 
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
    local result = self.cns_hcard:select(path)
    local pDataValue = self.cns_hcard:mread_binary(0, 400)
    obj[CKA.VALUE] = pDataValue
    obj.populated=true
    return CKR.OK, obj[att_type]
end

-- legge il valore da un file di attributi PKCS#11
function t.mt:get_p11_attribute(num, oType, aType)
    local len_s, len_n, val_s, bReadRes
    local path = hexf('3F004FFF%H', self:buildP11Fid(num, oType, aType) )
    log.output('get_p11_attribute(): reading attribute @ ', hex.hexify(path) )
    local info = self:get_info()
    if utility.cache_can_use() and self.cfg["fastread"]=='true' then
        val_s = utility.cache_read(info.serialNumber, path)
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
    if utility.cache_can_use() and self.cfg["fastread"]=='true' then
        utility.cache_write(info.serialNumber, path, val_s)
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
        if self.cached_main_pin and self.userType == CKU.USER then
            self.cns_hcard:verify_pin_cns(self.cached_main_pin, false, true)
        end
    end)
    local main_attr_path = hexf(obj.parent_path .. '%H', self:buildP11Fid(obj.num, objTypes.ePrivKey, attrTypes.eMain))
    local bReadRes, obj_info
    local info = self:get_info()
    if utility.cache_can_use() and self.cfg["fastread"]=='true' then
        obj_info = utility.cache_read(info.serialNumber, main_attr_path)
        bReadRes = true
    end
    if pcall(function()
            return self.cns_hcard:select(main_attr_path)
            end 
            ) then
        if not obj_info then
            bReadRes, obj_info = pcall(function() return self.cns_hcard:read_binary(0, 32) end )
            if bReadRes and obj_info and utility.cache_can_use() and self.cfg["fastread"]=='true' then
                utility.cache_write(info.serialNumber, main_attr_path, obj_info)
            end
        end
        if bReadRes and string.len(obj_info) >= 32 then
            local bit_fields, start_date, end_date
            bit_fields = bin.flags(bin.unpack("%<%H", string.sub(obj_info, 1, 2) ))
            start_date = string.sub(obj_info, 3, 10)
            end_date = string.sub(obj_info, 11, 18)
            obj.key_bits = bin.unpack("%>%H", string.sub(obj_info, 19, 20) )
            log.output("get_privkey_p11(): obj.key_bits:", obj.key_bits)
            if obj.key_bits < 1024 then
                log.output("get_privkey_p11(): WARNING: wrong key_bits, patched to 1024")
                obj.key_bits = 1024
            end
            obj.kid = string.byte(obj_info, 25)
            obj[CKA.START_DATE] = start_date
            obj[CKA.END_DATE] = end_date
            local attr_map = {}
            for i, v in privkey_bitfields do
                table.insert(attr_map, {flag=v, attr_type=CKA[i]} )
            end
            self:_bit_fields2attr(obj, bit_fields, attr_map)
        else
            log.output('get_privkey_p11(): error reading main attributes file, object:', hobj)
            obj.kid = 0
            obj.key_bits = 1024
        end
    end
    obj[CKA.MODULUS_BITS] = eCK.ULONG(obj.key_bits)
    obj[CKA.LABEL] = self:get_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.eLabel) or ''
    obj[CKA.ID] = self:get_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.eID) or ''
    obj[CKA.MODULUS] = self:get_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.eModulus) or ''
    obj[CKA.PUBLIC_EXPONENT] = self:get_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.ePubExp) or ''
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
    local info = self:get_info()
    if utility.cache_can_use() and self.cfg["fastread"]=='true' then
        obj_info = utility.cache_read(info.serialNumber, main_attr_path)
        bReadRes = true
    end
    
    if pcall(function() 
            return self.cns_hcard:select(main_attr_path)
            end 
            ) then
        if not obj_info then
            bReadRes, obj_info = pcall(function() return self.cns_hcard:read_binary(0, 32) end )
            if bReadRes and obj_info and utility.cache_can_use() and self.cfg["fastread"]=='true' then
                utility.cache_write(info.serialNumber, main_attr_path, obj_info)
            end
        end
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
        else
            log.output('get_pubkey_p11(): error reading main attributes file, object:', hobj)
            obj.key_bits = 1024
        end
    end
    
    obj[CKA.MODULUS_BITS] = eCK.ULONG(obj.key_bits)
    obj[CKA.LABEL] = self:get_p11_attribute(obj.num, objTypes.ePubKey, attrTypes.eLabel) or ''
    obj[CKA.ID] = self:get_p11_attribute(obj.num, objTypes.ePubKey, attrTypes.eID) or ''
    if obj.key_bits > 1024 then
            local bReadRes, theErrorT = pcall(function()
                self.cns_hcard:select(hexf(obj.parent_path .. '%H', self:buildP11Fid(obj.num, objTypes.ePubKey, attrTypes.ePubKeyModExp)))
                local modulus = self.cns_hcard:mread_binary(0, 256)
                local pubExp =  self.cns_hcard:mread_binary(256, 8)
                while string.sub(pubExp, 1, 1) == '\000' do pubExp = string.sub(pubExp, 2, -1) end
                obj[CKA.MODULUS] = modulus
                obj[CKA.PUBLIC_EXPONENT] = pubExp
            end)
            if not bReadRes then
                log.output("get_pubkey_p11(): 2048, error:", theErrorT)
                return CKR.ATTRIBUTE_TYPE_INVALID, nil
            end
    else
        self:get_public_key(hobj, att_type, onlysize)
    end
    obj.populated=true
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
        log.output('get_certificate(): ERROR! not a certificate object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    if obj.path ~= nil then path=hex.hexf(obj.path) end
    
    local info = self:get_info()
    
    local result
    if utility.cache_can_use() and self.cfg["fastread"]=='true' then
        result = utility.cache_read(info.serialNumber, path)
    end

    if not result then
        result = self.cns_hcard:read_x509_certificate(path, 5)
        if result and utility.cache_can_use() and self.cfg["fastread"]=='true' then
            utility.cache_write(info.serialNumber, path, result)
        end
    end
    local parsed_cer = der.parse_x509cer(result) or {}
    obj[CKA.VALUE] = result
    obj[CKA.SUBJECT] = self:get_p11_attribute(obj.num, objTypes.eCert, attrTypes.eSubject) or parsed_cer.subject or ''
    obj[CKA.ISSUER] = self:get_p11_attribute(obj.num, objTypes.eCert, attrTypes.eIssuer) or parsed_cer.issuer or ''
    obj[CKA.SERIAL_NUMBER] = self:get_p11_attribute(obj.num, objTypes.eCert, attrTypes.eSN) or parsed_cer.serialNumber or ''
    obj[CKA.LABEL] = self:get_p11_attribute(obj.num, objTypes.eCert, attrTypes.eLabel) or ''
    obj[CKA.ID] = self:get_p11_attribute(obj.num, objTypes.eCert, attrTypes.eID) or ''

    local main_attr_path = hexf(obj.parent_path .. '%H', self:buildP11Fid(obj.num, objTypes.eCert, attrTypes.eMain))
    local bReadRes, obj_info
    if utility.cache_can_use() and self.cfg["fastread"]=='true' then
        obj_info = utility.cache_read(info.serialNumber, main_attr_path)
        bReadRes = true
    end
    
    if obj_info or pcall(function() 
            return self.cns_hcard:select(main_attr_path)
            end
            ) then
        if not obj_info then
            bReadRes, obj_info = pcall(function() return self.cns_hcard:read_binary(0, 32) end )
            if bReadRes and obj_info and utility.cache_can_use() and self.cfg["fastread"]=='true' then
                utility.cache_write(info.serialNumber, main_attr_path, obj_info)
            end
        end
        if bReadRes and string.len(obj_info) >= 32 then
            local bit_fields, start_date, end_date
            bit_fields = bin.flags(bin.unpack("%<%H", string.sub(obj_info, 1, 2) ))
            local attr_map = {}
            for i, v in cert_data_bitfields do
                table.insert(attr_map, {flag=v, attr_type=CKA[i]} )
            end
            self:_bit_fields2attr(obj, bit_fields, attr_map)
        else
            log.output('get_pubkey_p11(): error reading main attributes file, object:', hobj)
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
    obj[CKA.LABEL] = self:get_p11_attribute(obj.num, objTypes.eData, attrTypes.eLabel) or ''
    obj[CKA.APPLICATION] = self:get_p11_attribute(obj.num, objTypes.eData, attrTypes.eApplication)
    obj[CKA.OBJECT_ID] = self:get_p11_attribute(obj.num, objTypes.eData, attrTypes.eObjectId)
    
    local main_attr_path = hexf(obj.parent_path .. '%H', self:buildP11Fid(obj.num, objTypes.eData, attrTypes.eMain))
    local bReadRes, obj_info
    local info = self:get_info()
    if utility.cache_can_use() and self.cfg["fastread"]=='true' then
        obj_info = utility.cache_read(info.serialNumber, main_attr_path)
        bReadRes = true
    end
    
    if obj_info or pcall(function() 
            return self.cns_hcard:select(main_attr_path)
            end
            ) then
        if not obj_info then
            bReadRes, obj_info = pcall(function() return self.cns_hcard:read_binary(0, 32) end )
            if bReadRes and obj_info and utility.cache_can_use() and self.cfg["fastread"]=='true' then
                utility.cache_write(info.serialNumber, main_attr_path, obj_info)
            end
        end
        if bReadRes and string.len(obj_info) >= 32 then
            local bit_fields, start_date, end_date
            bit_fields = bin.flags(bin.unpack("%<%H", string.sub(obj_info, 1, 2) ))
            local attr_map = {}
            for i, v in cert_data_bitfields do
                table.insert(attr_map, {flag=v, attr_type=CKA[i]} )
            end
            self:_bit_fields2attr(obj, bit_fields, attr_map)
        else
            log.output('get_pubkey_p11(): error reading main attributes file, object:', hobj)
        end
    end
    
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
    
    local keyBytes
    
    if not self._license_valid then
        log.output('sign_buffer(): ERROR: invalid license!')
        return CKR.KEY_FUNCTION_NOT_PERMITTED
    end
    
    if type(obj.key_bits) == 'function' then    
        obj.key_bits(hKey, CKA.CLASS)
        keyBytes = obj.key_bits/8
    elseif type(obj.key_bits) == 'number' then
        keyBytes = obj.key_bits/8
    else
        keyBytes = 128
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
            if self.cached_main_pin and self.userType == CKU.USER then
                self.cns_hcard:verify_pin_cns(self.cached_main_pin, false, true)
            end
        end)
        if obj.pso_dec then -- usa la modalit