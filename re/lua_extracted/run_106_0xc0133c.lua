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
    local result = self.cmg_hcard:read_x509_certificate(path)
    local parsed_cer
    
    local pcRes = pcall(function()
        parsed_cer = der.parse_x509cer(result)
    end)
    if not pcRes then
        result = zlib.decompress(string.sub(result, 5, -1))
        parsed_cer = der.parse_x509cer(result)
    end
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
                local sm_key
                if obj.isds then
                    sm_key = self.cmg_info.ds_smkey
                end
                return self.cmg_hcard:read_public_key(path, sm_key, sm_key, sm_key ~= nil)
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


-- legge il valore da un file di attributi PKCS#11
function t.mt:get_p11_attribute(num, oType, aType)
    local len_s, len_n, val_s, bReadRes
    local path = hexf('3F002FFF%H', self:buildP11Fid(num, oType, aType) )
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
        return self.cmg_hcard:select(path) 
        end ) then
        bReadRes, len_s = pcall(function() return self.cmg_hcard:read_binary(1, 2) end )
        if not bReadRes then 
            log.output('get_p11_attribute(): read binary to get attr len failed:', len_s)
            return ''
        end
        len_n = string.byte(len_s,1) * 2^8 + string.byte(len_s,2)
        bReadRes, val_s = pcall(function() return self.cmg_hcard:mread_binary(5, len_n) end)
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


function t.mt:sign_buffer(hKey, pMechanism, pData, allocated_space)
    log.output('sign_buffer(): hKey:' , hKey)
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
    
    local keyBytes
    
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
                self.cmg_hcard:verify_pin_cns(self.cached_main_pin, false, false)
            end
        end)
        if obj.pso_dec then -- usa la modalit