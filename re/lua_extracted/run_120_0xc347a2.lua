 RSA-Decrypt
            log.output('sign_buffer(): using RSA-Decrypt mode on ' .. obj.kid)
            local pDataPadded
            if string.len(pData) == keyBytes then -- firma raw
                pDataPadded = pData
            else
                pDataPadded = '\0\1'..string.rep('\255',(keyBytes-3)-string.len(pData))
                                ..'\0'..pData
            end
            result = self.it_telecom_hcard:rsa_it_telecom(pDataPadded, obj.kid)
            return CKR.OK, result
        end
        
    end
    log.output('sign_buffer(): unexpected!')
    return CKR.FUNCTION_FAILED

end


function t.mt:decrypt_buffer(hKey, pMechanism, pData, allocated_space)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('decrypt_buffer(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('decrypt_buffer(): ERROR: not a private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    if not obj.pso_dec then
        log.output('decrypt_buffer(): ERROR: decrypt not supported!')
        return CKR.KEY_TYPE_INCONSISTENT -- todo: errore non adatto
    end
    if type(obj.kid) == 'function' then
        local rv = obj.kid(self, hKey, CKA.CLASS, false)
        if rv ~= CKR.OK then return rv end
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
    if dataLen ~= keyBytes then
        log.output('decrypt_buffer(): specified data len invalid: ', dataLen, ', expected:', keyBytes)
        return CKR.ENCRYPTED_DATA_LEN_RANGE
    end
    pcall(function() 
        if self.cached_main_pin and self.userType == CKU.USER then
            self.it_telecom_hcard:verify_pin_main(self.cached_main_pin, false, true)
        end
    end)
    local pDataPadded
    
    pDataPadded = self.it_telecom_hcard:rsa_it_telecom(pData, obj.kid)
    
    if pDataPadded == nil or string.len(pDataPadded) ~= keyBytes then
        log.output('decrypt_buffer(): cannot decrypt specified data')
        return CKR.ENCRYPTED_DATA_INVALID
    end
    if string.byte(pDataPadded, 1) ~= 0 or string.byte(pDataPadded, 2) ~= 2 then
        
        log.output('decrypt_buffer(): data decrypted, pkcs1 padding invalid, byte1:',
                    string.byte(pDataPadded, 1),
                    'byte2:', string.byte(pDataPadded, 2))
        return CKR.ENCRYPTED_DATA_INVALID
    end
    local idx = string.find(pDataPadded, '\0', 4, true)
    if idx == nil then
        log.output('decrypt_buffer(): data decrypted, pkcs1 padding invalid, cannot find payload')
        return CKR.ENCRYPTED_DATA_INVALID
    end
    local result = string.sub(pDataPadded, idx+1, -1)
    return CKR.OK, result  
end

t.lunpad = lunpad

-- se search_state.lastobj==nil si richiede l'handle del primo oggetto che risponda
-- al template. Altrimenti restituisce il primo oggetto che sia
-- compatibile con il template e abbia handle>search_state.lastobj.
-- quando non ci sono pi