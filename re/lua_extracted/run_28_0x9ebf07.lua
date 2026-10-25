 che determinare la size di questo specifico attributo
-- pesa quanto determinarne il contenuto. Quando viene chiesta solo
-- la size viene quindi ritornato il contenuto al fine fi farlo mettere
-- in cache per una probabile successiva richiesta.
function t.mt:get_certificate(hobj, att_type, onlysize)
-- Setta CKA.VALUE, CKA.SUBJECT, CKA.ISSUER, CKA.SERIAL_NUMBER
    log.output('get_certificate():', hobj, att_type)
    local path = nil
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.CERTIFICATE) then
        log.output('get_certificate(): WARNING: function called on a non certificate object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    if obj.path ~= nil then path=hex.hexf(obj.path) end
    
    local info = self:get_info()
    
    local result

    result = self.siae_hcard:read_x509_certificate(path, 2)

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
    local obj = self.attributes[hobj]
    local info = self:get_info()

    local pubkey_fid_path = self.root_path .. obj.pubkey_fid
    local pcRes, modulus, pubexp = pcall( function()
         return self.siae_hcard:read_public_key(pubkey_fid_path)
    end)


    if not pcRes then
        log.output('get_public_key(): error reading public key @', hex.hexify(pubkey_fid_path), ':\n', modulus)
    elseif modulus == nil or pubexp == nil then
        log.output('get_public_key(): modulus or pubexp are nil!')
        obj[CKA.MODULUS] = -2
        obj[CKA.PUBLIC_EXPONENT] = -2
        obj[CKA.MODULUS_BITS] = -2
    else
        obj[CKA.MODULUS] = modulus
        obj[CKA.PUBLIC_EXPONENT] = pubexp
        obj[CKA.MODULUS_BITS] = eCK.ULONG(string.len(modulus) * 8)
    end
    obj.populated=true
    return CKR.OK, obj[att_type]
end


function t.mt:get_privkey(hobj, att_type, onlysize)
-- Setta CKA.LABEL, CKA.ID, CKA.MODULUS, CKA.PUBLIC_EXPONENT
    log.output('get_privkey():', hobj, att_type)
    local obj = self.attributes[hobj]

    
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('get_privkey(): ERROR! not a private key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end

    local info = self:get_info()
    
    -- local fields = {}
    -- local attrib_path = self.root_path .. obj.priv_key_attributes_fid
    -- local bReadRes = pcall(function()
        -- self.siae_hcard:select(attrib_path, true)
        -- local nRec = 1
        -- while true do
            
            -- local record = ''
            -- local pcRes, theErrorT = pcall( function()
                -- record = self.siae_hcard:read_record(nRec)
                -- table.insert(fields, record);
            -- end )
            -- if not pcRes then
                -- log.output('reading priv key attribute file:', hex.hexify(attrib_path), 'error:', theErrorT)
                -- break
            -- end
            -- nRec = nRec+1
        -- end
    -- end)
    -- field 1: index 8: CKA_PRIVATE, index 10: CKA_MODIFIABLE?
    -- field 2/3: Label ?
    -- field 4: key type?
    
    -- lettura chiave pubblica
    local pubkey_fid_path = self.root_path .. obj.pubkey_fid
    local pcRes, modulus, pubexp = pcall( function()
         return self.siae_hcard:read_public_key(pubkey_fid_path)
    end)

    -- todo_ populate data
    -- obj[CKA.LABEL] = obj[CKA.LABEL] or ''
    -- obj[CKA.ID] = obj[CKA.ID] or ''
    obj[CKA.MODULUS] = modulus or ''
    obj[CKA.PUBLIC_EXPONENT] = pubexp or hex.hexf("010001")
    obj[CKA.MODULUS_BITS] = 1024
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
        log.output('sign_buffer(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('sign_buffer(): ERROR: non private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    local keyBytes = 128
    

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

        log.output('sign_buffer(): using RSA-Decrypt mode on ' .. obj.path .. '/' .. obj.kid)
        local pDataPadded
        if string.len(pData) == keyBytes then -- firma raw
            pDataPadded = pData
        else
            pDataPadded = '\0\1'..string.rep('\255',(keyBytes-3)-string.len(pData))
                            ..'\0'..pData
        end

        local pcRes, theErrorT = pcall(function()
            result = self.siae_hcard:rsa_cns(pDataPadded, obj.path, obj.kid)
        end)
        if not pcRes and self.siae_hcard.last_sw == hex.hexf("6982") then
            self:verify_pin(self.cached_main_pin, CKU.USER)
            result = self.siae_hcard:rsa_cns(pDataPadded, obj.path, obj.kid)
        elseif not pcRes then
            log.output('sign_buffer(): rsa_cns error:', theErrorT)
            return CKR.FUNCTION_FAILED
        end
        return CKR.OK, result
    end
    log.output('sign_buffer(): unexpected: should never reach this part!')
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

    if type(obj.kid) == 'function' then
        local rv = obj.kid(self, hKey, CKA.CLASS, false)
        if rv ~= CKR.OK then return rv end
    end
    
    local keyBytes = 128
    
    local dataLen = string.len(pData)
    if dataLen ~= keyBytes then
        log.output('decrypt_buffer(): specified data len invalid: ', dataLen, ', expected:', keyBytes)
        return CKR.ENCRYPTED_DATA_LEN_RANGE
    end
    
    local pDataPadded

        local pcRes, theErrorT = pcall(function()
            pDataPadded = self.siae_hcard:rsa_cns(pData, obj.path, obj.kid)
        end)
        if not pcRes and self.siae_hcard.last_sw == hex.hexf("6982") then
            self:verify_pin(self.cached_main_pin, CKU.USER)
            pDataPadded = self.siae_hcard:rsa_cns(pData, obj.path, obj.kid)
        elseif not pcRes then
            log.output('decrypt_buffer(): rsa_cns error:', theErrorT)
            return CKR.FUNCTION_FAILED
        end

        
    if pDataPadded == nil or string.len(pDataPadded) ~= keyBytes then
        log.output('decrypt_buffer(): cannot decrypt specified data')
        return CKR.ENCRYPTED_DATA_INVALID
    end    
    if not pMechanism or not pMechanism.mechanism or pMechanism.mechanism == CKM.RSA_PKCS then
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
    else
        return CKR.OK, pDataPadded
    end
end


-- se search_state.lastobj==nil si richiede l'handle del primo oggetto che risponda
-- al template. Altrimenti restituisce il primo oggetto che sia
-- compatibile con il template e abbia handle>search_state.lastobj.
-- quando non ci sono pi