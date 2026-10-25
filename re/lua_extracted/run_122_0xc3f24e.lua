 che determinare la size di questo specifico attributo
-- pesa quanto determinarne il contenuto. Quando viene chiesta solo
-- la size viene quindi ritornato il contenuto al fine fi farlo mettere
-- in cache per una probabile successiva richiesta.
function t.mt:get_certificate(hobj, att_type, onlysize)
-- Setta CKA.VALUE, CKA.SUBJECT, CKA.ISSUER, CKA.SERIAL_NUMBER
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.CERTIFICATE) then
        log.output('get_certificate(): WARNING: function called on a non certificate object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    local parsed_cer
    
    local pcRes = pcall(function()
        parsed_cer = der.parse_x509cer(obj.value)
    end)
    obj[CKA.VALUE] = obj.value
    obj[CKA.SUBJECT] = parsed_cer.subject
    obj[CKA.ISSUER] = parsed_cer.issuer
    obj[CKA.SERIAL_NUMBER] = parsed_cer.serialNumber
    obj.populated=true
    return CKR.OK, obj[att_type]
end

function t.mt:get_public_key(hobj, att_type, onlysize)
-- Setta CKA.MODULUS, CKA.PUBLIC_EXPONENT, CKA.MODULUS_BITS
    log.output('get_public_key():', hobj, att_type)
    local obj = self.attributes[hobj]
    local modulus, exponent = obj.modulus, obj.pubexp
    if modulus == nil or exponent == nil then
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
                self.cardos_hcard:verify_pin_main(self.cached_main_pin, false, true)
            end
        end)
        if obj.pso_dec then -- usa la modalit