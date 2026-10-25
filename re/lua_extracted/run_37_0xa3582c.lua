 ripristinato al valore precedente...')
                local pcRes1, result1 = pcall(function() 
                    if ispuk then
                        return self.inside_hcard:change_puk(newPin, oldPin) 
                    else
                        return self.inside_hcard:change_pin(newPin, oldPin) 
                    end
                end)
            end
        end
    end
    
    
    if result == 0 then
        self.cached_main_pin = newPin
        self:verify_loggedon_user()
        return CKR.OK
    elseif result == 1 then
        return CKR.PIN_INCORRECT
    elseif result == 2 then
        return CKR.PIN_LOCKED
    else
        return CKR.FUNCTION_FAILED
    end
end

function t.mt:reset_pin(newPin)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local pcRes, theErrorT, result
    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-cns reset_pin(): newPin:' .. newPin)
    log.output('token-cns reset_pin(): reset pin...')
    if self.userType ~= CKU.SO then
        log.output('token-cns reset_pin(): user not SO!')
        return CRK.FUNCTION_FAILED
    end
    
    self._schedule_update_retry_counters = true
    
    if not newPin or string.len(newPin) > info.ulMaxPinLen or string.len(newPin) < info.ulMinPinLen then
        return CKR.PIN_LEN_RANGE
    end

    pcRes, theErrorT = pcall(function() result = self.inside_hcard:reset_pin(self.cached_main_pin, newPin) end)
    if not pcRes then
        log.output("reset_pin(): error", theErrorT)
        return CKR.FUNCTION_FAILED
    end
    if self.ds_info and self.ds_info.fips then
        if result == 0 then
            pcRes, theErrorT = pcall(function() result = self.inside_hcard:reset_pin_fips(self.cached_main_pin, newPin) end)
            if not pcRes then
                log.output("reset_pin(): error", theErrorT)
                return CKR.FUNCTION_FAILED
            end

        end
    end
    
    if result == 0 then
        self:verify_loggedon_user()
        return CKR.OK
    elseif result == 1 then
        return CKR.PIN_INCORRECT
    elseif result == 2 then
        return CKR.PIN_LOCKED
    else
        return CKR.FUNCTION_FAILED
    end
end

--=====================================================================================
-- Funzioni per il recupero degli attributi
--=====================================================================================


function t.mt:get_privkey_ds(hobj, att_type, onlysize)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local id = nil
    local obj = self.attributes[hobj]
    local fid, fid_val, attr_path, val_path
    local obj_attributes
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('get_privkey_ds(): ERROR! not a private key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    fid = bin.flags('0x0100') + bin.flags(obj.num) + util.objFIDS.ePrivKey
    fid_val = bin.flags(obj.num) + util.objFIDS.ePrivKey
    log.output('get_privkey_ds(): calculated fid:', fid )
    attr_path = obj.ds_parent_path .. hexf('%H', fid.asnumber)
    val_path = obj.ds_parent_path .. hexf('%H', fid_val.asnumber)
    local pcRes, theErrorT
    
    self:verify_loggedon_user()
    
            
    if obj.imported then
        pcRes, theErrorT = pcall(function()
                    log.output('get_privkey_ds(): reading attributes for privkeyX :', hex.hexify(val_path) )
                    local fInfo = self.inside_hcard:select(val_path)
                    obj.eExponent = self.inside_hcard:mread_binary(0, fInfo.size)
                end
                )
        if not pcRes then
            log.output('get_privkey_ds(): error reading val_path:', theErrorT )
        end
    end
    
    pcRes, theErrorT = pcall(function()
                log.output('get_privkey_ds(): reading attributes for privkey :', hex.hexify(attr_path) )
                obj_attributes = util.parse_ds_privkey_attribute(
                    self.inside_hcard, attr_path, obj.key_bits / 8
                    )
            end
            )

            
    if pcRes then
        obj[CKA.LABEL] = obj_attributes.label
        obj[CKA.ID] = obj_attributes.id
        obj[CKA.MODULUS] = obj_attributes.modulus
        obj[CKA.PUBLIC_EXPONENT] = obj_attributes.pubexp
        obj[CKA.MODULUS_BITS] = eCK.ULONG(obj.key_bits)
        obj[CKA.START_DATE] = obj_attributes.startdate
        obj[CKA.END_DATE] = obj_attributes.enddate
        obj[CKA.SUBJECT] = obj_attributes.subject
        
        util.decode_bool_attributes(
            obj_attributes.flags, 
            {CKA.MODIFIABLE, CKA.LOCAL, CKA.DECRYPT, CKA.SIGN, CKA.SIGN_RECOVER,CKA.UNWRAP,CKA.ALWAYS_AUTHENTICATE},
            obj
        )
        if not obj[CKA.PUBLIC_EXPONENT] or string.len(obj[CKA.PUBLIC_EXPONENT]) == 0 then
            obj[CKA.PUBLIC_EXPONENT] = hex.hexf('010001') -- default exponent
        end
        obj.populated = true
        return CKR.OK, obj[att_type]
    else
        log.output('get_privkey_ds(): error reading attribute:', theErrorT )
        return CKR.ATTRIBUTE_TYPE_INVALID
    end
end

function t.mt:get_pubkey_ds(hobj, att_type, onlysize)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local sm_enc, sm_sig
    local id = nil
    local obj = self.attributes[hobj]
    local attr_fid, attr_path, val_fid, val_path
    local obj_attributes
    local modulus, exponent
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PUBLIC_KEY) then
        log.output('get_pubkey_ds(): ERROR! not a public key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    
    self:verify_loggedon_user()
    
    attr_fid = bin.flags('0x0100') + bin.flags(obj.num) + util.objFIDS.ePubKey
    attr_path = obj.ds_parent_path .. hexf('%H', attr_fid.asnumber)
    log.output('get_pubkey_ds(): calculated fids:', 'attr_path:', hex.hexify(attr_path), 'group/index:', obj.group, obj.index )
    local pcRes, theErrorT = pcall(function() 
                log.output('get_pubkey_ds(): reading attributes for pubkey :', hex.hexify(attr_path) )
                obj_attributes = util.parse_ds_pubkey_attribute(
                    self.inside_hcard, attr_path
                    )
            end
            )
    if pcRes then
        obj[CKA.LABEL] = obj_attributes.label
        obj[CKA.ID] = obj_attributes.id
        obj[CKA.MODULUS] = obj_attributes.modulus
        obj[CKA.PUBLIC_EXPONENT] = obj_attributes.pubexp
        obj[CKA.MODULUS_BITS] = (obj_attributes.modulus and eCK.ULONG(string.len(obj_attributes.modulus) * 8)) or obj[CKA.MODULUS_BITS]
        obj[CKA.START_DATE] = obj_attributes.startdate
        obj[CKA.END_DATE] = obj_attributes.enddate
        obj[CKA.SUBJECT] = obj_attributes.subject
        
        util.decode_bool_attributes(
            obj_attributes.flags, 
            {CKA.MODIFIABLE, CKA.TRUSTED, CKA.LOCAL, CKA.ENCRYPT, CKA.VERIFY,CKA.VERIFY_RECOVER,CKA.WRAP},
            obj
        )
        obj.populated = true
        if type(obj[att_type]) == 'function' then
            return CKR.FUNCTION_FAILED
        end
        
        return CKR.OK, obj[att_type]
    else
        log.output('get_pubkey_ds(): error reading attribute:', theErrorT )
        return CKR.ATTRIBUTE_TYPE_INVALID
    end
end

function t.mt:get_certificate_ds(hobj, att_type, onlysize)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end

    local parsed_cer
    local cert_value
    local id = nil
    local obj = self.attributes[hobj]
    local attr_fid, attr_path, val_fid, val_path
    local obj_attributes
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.CERTIFICATE) then
        log.output('get_certificate_ds(): ERROR! not a certificate object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    self:verify_loggedon_user()
    
    attr_fid = bin.flags('0x0100') + bin.flags(obj.num) + util.objFIDS.eCert
    attr_path = obj.ds_parent_path .. hexf('%H', attr_fid.asnumber)
    val_path = obj.path
    log.output('get_certificate_ds(): calculated fids:', 'attr_path:', hex.hexify(attr_path), 'val_path:', hex.hexify(val_path) )
    local pcRes, theErrorT = pcall(function() 
                log.output('get_certificate_ds(): reading value for cert:', hex.hexify(val_path) )
                cert_value = self.inside_hcard:read_x509_certificate(val_path)
                log.output('get_certificate_ds(): reading attributes for cert:', hex.hexify(attr_path) )
                obj_attributes = util.parse_ds_cert_attribute(
                    self.inside_hcard, attr_path
                    )
            end
            )
    if pcRes then
        pcall(function() parsed_cer = der.parse_x509cer(cert_value) end )
        obj[CKA.LABEL] = obj_attributes.label
        obj[CKA.ID] = obj_attributes.id
        obj[CKA.VALUE] = cert_value
        obj[CKA.SUBJECT] = obj_attributes.subject or (parsed_cer and parsed_cer.subject)
        obj[CKA.ISSUER] = obj_attributes.issuer or (parsed_cer and parsed_cer.issuer)
        obj[CKA.SERIAL_NUMBER] = obj_attributes.serialnumber or (parsed_cer and parsed_cer.serialNumber)
        
        util.decode_bool_attributes(
            obj_attributes.flags, 
            {CKA.MODIFIABLE, CKA.TRUSTED},
            obj
        )
        obj.populated = true
        return CKR.OK, obj[att_type]
    else
        log.output('get_certificate_ds(): error reading attribute:', theErrorT )
        return CKR.ATTRIBUTE_TYPE_INVALID
    end
end

function t.mt:get_data_ds(hobj, att_type, onlysize)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local id = nil
    local obj = self.attributes[hobj]
    local attr_fid, attr_path, val_fid, val_path
    local obj_attributes
    local value = ''
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.DATA) then
        log.output('get_data_ds(): ERROR! not a DATA object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    if obj.private then
        attr_fid = bin.flags('0x0100') + bin.flags(obj.num) + util.objFIDS.eDataP
    else
        attr_fid = bin.flags('0x0100') + bin.flags(obj.num) + util.objFIDS.eData
    end
    attr_path = obj.ds_parent_path .. hexf('%H', attr_fid.asnumber)
    val_path = obj.path
    log.output('get_data_ds(): calculated fids:', 'attr_path:', hex.hexify(attr_path), 'val_path:', hex.hexify(val_path) )
    local pcRes, theErrorT
    
    self:verify_loggedon_user()
    
    if obj.size > 0 then
        pcRes, theErrorT = pcall(function() 
                log.output('get_data_ds(): reading value for data obj:', hex.hexify(val_path) )
                self.inside_hcard:select(val_path)
                value = self.inside_hcard:mread_binary(0, obj.size)

                log.output('get_data_ds(): reading attributes for data obj :', hex.hexify(attr_path) )
                obj_attributes = util.parse_ds_data_attribute(self.inside_hcard, attr_path)
            end)
    else
        pcRes = true
    end
    if pcRes then
        obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
        obj[CKA.MODIFIABLE] = eCK.BBOOL((bin.flags('0x0001') * obj_attributes.flags).asbool)
        obj[CKA.LABEL] = obj_attributes.label
        obj[CKA.APPLICATION] = obj_attributes.appId
        obj[CKA.OBJECT_ID] = obj_attributes.objId
        obj[CKA.VALUE] = value
        obj.populated = true
        return CKR.OK, obj[att_type]
    else
        log.output('get_pubkey_ds(): error reading attribute:', theErrorT )
        return CKR.ATTRIBUTE_TYPE_INVALID
    end 
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
    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    local pcRes, result
    
    if dataLen > keyBytes or (dataLen > (keyBytes -4) and dataLen <  keyBytes) then
        -- nota: il padding pkcs1 richiede almeno 8 byte di 0xFF prima dei dati da firmare
        log.output('sign_buffer(): specified data len invalid: ', dataLen)
        return CKR.DATA_LEN_RANGE
    end
    if allocated_space==nil then
        return CKR.OK, keyBytes
    else
    
        if obj.imported then
            log.output('sign_buffer(): using RSA ENC mode', obj.ds_id)
            -- forza polulate dell'oggetto:
            self:get_attribute_value(hKey, CKA.ID)
            if not obj.eExponent then
                log.output('sign_buffer(): FUNCTION_FAILED: eExponent not found!')
                return CKR.FUNCTION_FAILED
            end
            local pExp = aes.aes_decrypt_check(
                                        self.ds_info.aes_key,
                                        obj.eExponent,
                                        self.ds_info.aes_check
                                        )
            if not pExp then
                log.output('sign_buffer(): FUNCTION_FAILED: eExponent invalid')
                return CKR.FUNCTION_FAILED
            end
            -- already PADs correctly data internally:
            result = rsa.encrypt(pData, hex.hexify(obj[CKA.MODULUS]), nil, hex.hexify(pExp))
            
            pExp=nil
            collectgarbage() -- forza liberazione della memoria inutilizzata
            
            
            for i=1,keyBytes/128 do
                w32.sleep(100)
                self.inside_hcard:generate_random(128)
            end
            return CKR.OK, result
            
        elseif self.ds_info and self.ds_info.fips and obj[CKA.ALWAYS_AUTHENTICATE] == eCK.BBOOL(true) then
            self:verify_loggedon_user(true) -- verify FIPS user
            local pcRes, result = pcall(function()
                return self.inside_hcard:rsa_sign(pData, obj.group, obj.index)
            end)
            if pcRes then
                return CKR.OK, result
            else
                if self.inside_hcard.last_sw == hex.hexf("6985") then
                    -- si sta firmando un hash di tipo sconosciuto
                    return CKR.KEY_TYPE_INCONSISTENT
                end
            end
            -- self:verify_loggedon_user() -- verify normal user
        else
            self:verify_loggedon_user() -- verify normal user
            
            log.output('sign_buffer(): using RSA-Decrypt mode on ', obj.group, obj.index)
            local pDataPadded
            if string.len(pData) == keyBytes then -- firma raw
                pDataPadded = pData
            else
                pDataPadded = '\0\1'..string.rep('\255',(keyBytes-3)-string.len(pData))
                                ..'\0'..pData
            end
            local pcRes, result = pcall(function()
                return self.inside_hcard:rsa_dec(pDataPadded, obj.group, obj.index)
            end)
            if pcRes then
                return CKR.OK, result
            end

        end
    end
    log.output('sign_buffer(): function failed!')
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
    --if not obj.pso_dec then
    --    log.output('decrypt_buffer(): ERROR: decrypt not supported!')
    --    return CKR.KEY_TYPE_INCONSISTENT -- todo: errore non adatto
    --end

    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    if dataLen ~= keyBytes then
        log.output('decrypt_buffer(): specified data len invalid: ', dataLen, ', expected:', keyBytes)
        return CKR.ENCRYPTED_DATA_LEN_RANGE
    end
    
    self:verify_loggedon_user()
    
    local pDataPadded
    
    if obj.imported then
        log.output('decrypt_buffer(): using RSA ENC mode', obj.ds_id)
        -- forza polulate dell'oggetto:
        self:get_attribute_value(hKey, CKA.ID)
        if not obj.eExponent then
            log.output('decrypt_buffer(): FUNCTION_FAILED: eExponent not found!')
            return CKR.FUNCTION_FAILED
        end
        local pExp = aes.aes_decrypt_check(
                                    self.ds_info.aes_key,
                                    obj.eExponent,
                                    self.ds_info.aes_check
                                    )
        if not pExp then
            log.output('decrypt_buffer(): FUNCTION_FAILED: eExponent invalid')
            return CKR.FUNCTION_FAILED
        end
        
        pDataPadded = rsa.encrypt(pData, hex.hexify(obj[CKA.MODULUS]), nil, hex.hexify(pExp))
        
        pExp=nil
        collectgarbage() -- forza liberazione della memoria inutilizzata
    else
        log.output('decrypt_buffer(): using RSA-Decrypt mode on ', obj.ds_id)
        pDataPadded = self.inside_hcard:rsa_dec(pData, obj.group, obj.index)
        if pDataPadded == nil or string.len(pDataPadded) ~= keyBytes then
            log.output('decrypt_buffer(): cannot decrypt specified data')
            return CKR.ENCRYPTED_DATA_INVALID
        end
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