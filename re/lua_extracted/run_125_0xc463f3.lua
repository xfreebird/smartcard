 che determinare la size di questo specifico attributo
-- pesa quanto determinarne il contenuto. Quando viene chiesta solo
-- la size viene quindi ritornato il contenuto al fine di farlo mettere
-- in cache per una probabile successiva richiesta.
function t.mt:get_certificate(hobj, att_type, onlysize)
-- Setta CKA.VALUE, CKA.SUBJECT, CKA.ISSUER, CKA.SERIAL_NUMBER
    log.output('get_certificate()')
    local path = nil
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.CERTIFICATE) then
        log.output('get_certificate(): WARNING: function called on a non certificate object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    if obj.path ~= nil then path=hex.hexf(obj.path) end
    local result = self.dni_hcard:read_x509_certificate(path)
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
    obj[CKA.LABEL] = getCN(parsed_cer.subject)
    obj.populated=true
    obj.modulus=parsed_cer.modulus
    obj.pubexp=parsed_cer.pubexp
    return CKR.OK, obj[att_type]
end

function t.mt:get_public_key(hobj, att_type, onlysize)
-- Setta CKA.MODULUS, CKA.PUBLIC_EXPONENT, CKA.MODULUS_BITS
    log.output('get_public_key():', hobj, att_type)
    -- local path = nil
    local obj = self.attributes[hobj]
    local hcert = obj.related_cert_handle
    self:get_attribute_value(hcert, -1)
    local cert = self.attributes[hcert]
    obj[CKA.MODULUS] = cert.modulus
    obj[CKA.PUBLIC_EXPONENT] = self.pubexp
    obj.key_bits = string.len(obj[CKA.MODULUS]) * 8
    obj[CKA.MODULUS_BITS] = eCK.ULONG(obj.key_bits)
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
    self:get_attribute_value(hKey, -1)
    
    local keyBytes
    
    if type(obj.key_bits) == 'function' then    
        obj.key_bits(hKey, CKA.CLASS)
        keyBytes = obj.key_bits/8
    elseif type(obj.key_bits) == 'number' then
        keyBytes = obj.key_bits/8
    else
        keyBytes = 256
    end
    
    local dataLen = string.len(pData)
    local pcRes, result
    
    if allocated_space==nil then
        return CKR.OK, keyBytes
    else
        if type(obj.kid) == 'function' then
            local rv = obj.kid(self, hKey, CKA.CLASS, false)
            if rv ~= CKR.OK then return rv end
        end
        local pcRes, result = pcall(function()
            return self.dni_hcard:mse_pso(pData, obj.kid)
        end)
        if self.dni_hcard.last_sw == hexf('6982') then
            pcall(function()
                log.output('sign_buffer(): verify_pin() with:', self.cached_sign_pin, self.userType)
                if self.cached_sign_pin and self.userType == CKU.USER then
                    self.dni_hcard:verify_sign_pin(self.cached_sign_pin)
                end
            end)
        end
        local pcRes, result = pcall(function()
            return self.dni_hcard:mse_pso(pData, obj.kid)
        end)
        if pcRes then
            return CKR.OK, result
        end
        
    end
    log.output('sign_buffer(): unexpected!')
    return CKR.FUNCTION_FAILED

end


function t.mt:decrypt_buffer(hKey, pMechanism, pData, allocated_space)
    return CKR.FUNCTION_NOT_SUPPORTED
end


-- se search_state.lastobj==nil si richiede l'handle del primo oggetto che risponda
-- al template. Altrimenti restituisce il primo oggetto che sia
-- compatibile con il template e abbia handle>search_state.lastobj.
-- quando non ci sono pi