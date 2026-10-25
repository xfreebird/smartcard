 che determinare la size di questo specifico attributo
-- pesa quanto determinarne il contenuto. Quando viene chiesta solo
-- la size viene quindi ritornato il contenuto al fine fi farlo mettere
-- in cache per una probabile successiva richiesta.

function t.mt:get_privkey_ds(hobj, att_type, onlysize)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local id = nil
    local obj = self.attributes[hobj]
    local fid, attr_path
    local obj_attributes
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('get_privkey_ds(): ERROR! not a private key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    fid = bin.flags('0x0100') + bin.flags(obj.num) + oberthur_util.objFIDS.ePrivKey
    log.output('get_privkey_ds(): calculated fid:', fid )
    attr_path = hexf(obj.ds_parent_path .. '%H', fid.asnumber)
    local pcRes, theErrorT
    
    pcRes, theErrorT = pcall(function()
                log.output('get_privkey_ds(): reading attributes for privkey :', hex.hexify(attr_path) )
                obj_attributes = self:read_cached_file(attr_path, 0, -1, true)
                obj_attributes = oberthur_util.parse_ds_privkey_attribute_val(obj_attributes, obj.key_bits / 8)
                obj.kid = obj.num
            end
            )
    
    if not pcRes then
        log.output('get_privkey_ds(): error reading attribute:', debug.traceback(theErrorT) )
        fid = bin.flags('0x0100') + bin.flags(obj.num) + oberthur_util.objFIDS.ePubKey
        log.output('get_privkey_ds(PUB PZ8): calculated fid:', fid )
        attr_path = hexf(self.ds_info.path_root .. self.ds_df_pub .. '%H', fid.asnumber)

        pcRes, theErrorT = pcall(function()
                    log.output('get_privkey_ds(PUB PZ8): reading attributes for related pubKey :', hex.hexify(attr_path) )
                    obj_attributes = self:read_cached_file(attr_path, 0, -1, true)
                    obj_attributes = oberthur_util.parse_ds_pubkey_attribute_val(obj_attributes, obj.key_bits / 8)
                    obj.kid = obj.num
                    obj_attributes.flags = obj_attributes.flags + bin.flags('0x0020')
                    
                end
                )
       if not pcRes and obj.num >= 12 then
            log.output('get_privkey_ds(PUB PZ8): error reading attribute:', debug.traceback(theErrorT) )
            fid = bin.flags('0x0100') + bin.flags(obj.num -9) + oberthur_util.objFIDS.ePubKey
            log.output('get_privkey_ds(PUB12 PZ8): calculated fid:', fid )
            attr_path = hexf(self.ds_info.path_root .. self.ds_df_pub .. '%H', fid.asnumber)

            pcRes, theErrorT = pcall(function()
                        log.output('get_privkey_ds(PUB12 PZ8): reading attributes for related pubKey :', hex.hexify(attr_path) )
                        obj_attributes = self:read_cached_file(attr_path, 0, -1, true)
                        obj_attributes = oberthur_util.parse_ds_pubkey_attribute_val(obj_attributes, obj.key_bits / 8)
                        obj.kid = obj.num
                        obj_attributes.flags = obj_attributes.flags + bin.flags('0x0020')
                        
                    end
                    )
       end
    end
    if pcRes then
        obj[CKA.LABEL] = obj_attributes.label
        obj[CKA.ID] = obj_attributes.id
        obj[CKA.MODULUS] = obj_attributes.modulus
        obj[CKA.PUBLIC_EXPONENT] = obj_attributes.pubexp
        obj[CKA.MODULUS_BITS] = eCK.ULONG(obj.key_bits)
        obj[CKA.START_DATE] = obj_attributes.startdate
        obj[CKA.END_DATE] = obj_attributes.enddate
        obj[CKA.SUBJECT] = obj_attributes.subject
        obj[CKA.MODIFIABLE] = eCK.BBOOL((bin.flags('0x0001') * obj_attributes.flags).asbool)
        obj[CKA.LOCAL]      = eCK.BBOOL((bin.flags('0x0004') * obj_attributes.flags).asbool)
        obj[CKA.DECRYPT]    = eCK.BBOOL((bin.flags('0x0010') * obj_attributes.flags).asbool)
        obj[CKA.SIGN]       = eCK.BBOOL((bin.flags('0x0020') * obj_attributes.flags).asbool)
        obj[CKA.SIGN_RECOVER]= eCK.BBOOL((bin.flags('0x0080') * obj_attributes.flags).asbool)
        obj[CKA.UNWRAP]     = eCK.BBOOL((bin.flags('0x0400') * obj_attributes.flags).asbool)
        
        obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL((bin.flags('0x0800') * obj_attributes.flags).asbool)
        
        obj[CKA.DERIVE] = eCK.BBOOL((bin.flags('0x1000') * obj_attributes.flags).asbool)
        obj[CKA.COPYABLE] = eCK.BBOOL((bin.flags('0x2000') * obj_attributes.flags).asbool)
        obj[CKA.DESTROYABLE] = eCK.BBOOL(not (bin.flags('0x8000') * obj_attributes.flags).asbool)
        
        
        if not obj[CKA.PUBLIC_EXPONENT] or string.len(obj[CKA.PUBLIC_EXPONENT]) == 0 then
            obj[CKA.PUBLIC_EXPONENT] = hex.hexf('010001') -- default exponent
        end
        obj.populated = true
        return CKR.OK, obj[att_type]
    else
        log.output('get_privkey_ds(): error reading attribute:', debug.traceback(theErrorT) )
        return CKR.ATTRIBUTE_TYPE_INVALID
    end
end



function t.mt:get_secret_key_ds(hobj, att_type, onlysize, force_all)

    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local id = nil
    local obj = self.attributes[hobj]
    local fid, attr_path
    local obj_attributes
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.SECRET_KEY) then
        log.output('get_secret_key_ds(): ERROR! not a secret key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    
    if obj[CKA.KEY_TYPE] ~= eCK.ULONG(CKK.AES) then
        log.output('get_secret_key_ds(): ERROR! not an AES secret key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    
    fid = bin.flags('0x0100') + bin.flags(obj.num) + oberthur_util.objFIDS.eAESKey
    log.output('get_secret_key_ds(): calculated fid:', fid )
    attr_path = hexf(obj.ds_parent_path .. '%H', fid.asnumber)
    local pcRes, theErrorT
    
    pcRes, theErrorT = pcall(function()
                log.output('get_secret_key_ds(): reading attributes for privkey :', hex.hexify(attr_path) )
                obj_attributes = self:read_cached_file(attr_path, 0, -1, true)
                obj_attributes = oberthur_util.parse_ds_secretkey_attribute_val(obj_attributes, obj.key_bits / 8)
                obj.kid = obj.num
            end
            )
    if pcRes then
        obj[CKA.KEY_TYPE] = eCK.ULONG(CKK.AES)
        
        obj[CKA.LABEL] = obj_attributes.label
        obj[CKA.ID] = obj_attributes.id
        
        obj.value = aes.aes_decrypt_check(self._mk, obj_attributes.value, "00000001")
        log.output ("get_secret_key_ds(): value:", hex.hexify(obj.value or ""))


        obj[CKA.START_DATE] = obj_attributes.startdate
        obj[CKA.END_DATE] = obj_attributes.enddate
        obj[CKA.SUBJECT] = obj_attributes.subject
        obj[CKA.MODIFIABLE] = eCK.BBOOL((bin.flags('0x0001') * obj_attributes.flags).asbool)
        obj[CKA.LOCAL]      = eCK.BBOOL((bin.flags('0x0004') * obj_attributes.flags).asbool)
        obj[CKA.ENCRYPT]  = eCK.BBOOL((bin.flags('0x0008') * obj_attributes.flags).asbool)
        obj[CKA.DECRYPT]    = eCK.BBOOL((bin.flags('0x0010') * obj_attributes.flags).asbool)

        obj[CKA.DERIVE] = eCK.BBOOL((bin.flags('0x1000') * obj_attributes.flags).asbool)
        obj[CKA.COPYABLE] = eCK.BBOOL((bin.flags('0x2000') * obj_attributes.flags).asbool)
        obj[CKA.DESTROYABLE] = eCK.BBOOL(not (bin.flags('0x8000') * obj_attributes.flags).asbool)

        
        obj[CKA.SIGN] = eCK.BBOOL(false)
        obj[CKA.SIGN_RECOVER] = eCK.BBOOL(false)
        obj[CKA.VERIFY] = eCK.BBOOL(false)
        obj[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
        obj[CKA.UNWRAP] = eCK.BBOOL(false)
        obj[CKA.WRAP] = eCK.BBOOL(false)
        obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
    
        obj.populated = true
        return CKR.OK, obj[att_type]
    else
        log.output('get_secret_key_ds(): error reading attribute:', debug.traceback(theErrorT) )
        return CKR.ATTRIBUTE_TYPE_INVALID
    end
    
end

function t.mt:get_pubkey_fn(hobj, att_type, onlysize, force_all)
    log.output('get_pubkey_fn():' )
    local rv, t = self:get_attribute_value(hobj, CKA.KEY_TYPE)
    if rv == CKR.OK then
        if t == eCK.ULONG(CKK.EC_EDWARDS) or t == eCK.ULONG(CKK.ECDSA) then
            return self:get_ecc_pubkey_ds(hobj, att_type, onlysize, force_all)
        else
            return self:get_pubkey_ds(hobj, att_type, onlysize, force_all)
        end
    end
    return rv
end

function t.mt:get_privkey_fn(hobj, att_type, onlysize, force_all)
    log.output('get_privkey_fn():' )
    local rv, t = self:get_attribute_value(hobj, CKA.KEY_TYPE)
    if rv == CKR.OK then
        if t == eCK.ULONG(CKK.EC_EDWARDS) or t == eCK.ULONG(CKK.ECDSA) then
            return self:get_ecc_privkey_ds(hobj, att_type, onlysize, force_all)
        else
            return self:get_privkey_ds(hobj, att_type, onlysize, force_all)
        end
    end
    return rv
end


function t.mt:get_pubkey_ds(hobj, att_type, onlysize, force_all)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local id = nil
    local obj = self.attributes[hobj]
    local attr_fid, attr_path, val_fid, val_path
    local obj_attributes
    local modulus, exponent
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PUBLIC_KEY) then
        log.output('get_pubkey_ds(): ERROR! not a public key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    attr_fid = bin.flags('0x0100') + bin.flags(obj.num) + oberthur_util.objFIDS.ePubKey
    attr_path = hexf(obj.ds_parent_path .. '%H', attr_fid.asnumber)
    val_path = hexf(obj.path)
    log.output('get_pubkey_ds(): calculated fids:', 'attr_path:', hex.hexify(attr_path), 'val_path:', hex.hexify(val_path) )
    local pcRes, theErrorT = pcall(function() 
                if not obj.obj_attributes then
                    log.output('get_pubkey_ds(): reading attributes for pubkey :', hex.hexify(attr_path) )
                    obj_attributes = self:read_cached_file(attr_path, 0, -1, true)
                    
                    obj_attributes = oberthur_util.parse_ds_pubkey_attribute_val(obj_attributes)
                    obj.obj_attributes = obj_attributes
                else
                    log.output('get_pubkey_ds(): using already cached attributes for pubkey:', hex.hexify(attr_path) )
                    obj_attributes = obj.obj_attributes
                end
                if force_all or (
                           (att_type == CKA.MODULUS and type(obj[CKA.VALUE]) ~= "string")
                        or (att_type == CKA.PUBLIC_EXPONENT and type(obj[CKA.PUBLIC_EXPONENT]) ~= "string")
                        or (att_type == CKA.MODULUS_BITS and type(obj[CKA.MODULUS_BITS]) ~= "string")
                   ) then
                    
                    if obj_attributes.modulus then
                        log.output('get_pubkey_ds(): using new modulus/pubexp modules')
                        modulus = obj_attributes.modulus
                        exponent = obj_attributes.pubexp
                    else
                        log.output('get_pubkey_ds(): reading value for :', hex.hexify(val_path) )
                        local fInfo = self.cns_hcard:select(val_path, true)
                        if obj.key_bits == 2048 then
                            modulus = self.cns_hcard:mread_binary(0, 256)
                            exponent = self.cns_hcard:mread_binary(256, 8)
                            while string.sub(exponent, 1, 1) == '\000' do exponent = string.sub(exponent, 2, -1) end
                        else                       
                            if fInfo.sm and string.sub(fInfo.sm, 1, 2) == '\001\002' then
                                log.output('get_pubkey_ds(): reading value using SM' )
                                modulus, exponent = self.cns_hcard:read_public_key(
                                        val_path, self.ds_info.sm_use_enc, self.ds_info.sm_use_sig)
                            else
                                modulus, exponent = self.cns_hcard:read_public_key(val_path)
                            end
                        end                    
                    end
                end
            end
            )
    if pcRes then
        obj[CKA.LABEL] = obj_attributes.label
        obj[CKA.ID] = obj_attributes.id
        obj[CKA.MODULUS] = modulus or obj[CKA.MODULUS]
        obj[CKA.PUBLIC_EXPONENT] = exponent or obj[CKA.PUBLIC_EXPONENT]
        obj[CKA.MODULUS_BITS] = (modulus and eCK.ULONG(string.len(modulus) * 8)) or obj[CKA.MODULUS_BITS]
        obj[CKA.START_DATE] = obj_attributes.startdate
        obj[CKA.END_DATE] = obj_attributes.enddate
        obj[CKA.SUBJECT] = obj_attributes.subject
        obj[CKA.MODIFIABLE] = eCK.BBOOL((bin.flags('0x0001') * obj_attributes.flags).asbool)
        obj[CKA.TRUSTED]  = eCK.BBOOL((bin.flags('0x0002') * obj_attributes.flags).asbool)
        obj[CKA.LOCAL]    = eCK.BBOOL((bin.flags('0x0004') * obj_attributes.flags).asbool)
        obj[CKA.ENCRYPT]  = eCK.BBOOL((bin.flags('0x0008') * obj_attributes.flags).asbool)
        obj[CKA.VERIFY]   = eCK.BBOOL((bin.flags('0x0040') * obj_attributes.flags).asbool)
        obj[CKA.VERIFY_RECOVER]= eCK.BBOOL((bin.flags('0x0100') * obj_attributes.flags).asbool)
        obj[CKA.WRAP]     = eCK.BBOOL((bin.flags('0x0200') * obj_attributes.flags).asbool)
        
        obj[CKA.DERIVE] = eCK.BBOOL((bin.flags('0x1000') * obj_attributes.flags).asbool)
        obj[CKA.COPYABLE] = eCK.BBOOL((bin.flags('0x2000') * obj_attributes.flags).asbool)
        obj[CKA.DESTROYABLE] = eCK.BBOOL(not (bin.flags('0x8000') * obj_attributes.flags).asbool)
        
        obj.populated = force_all or modulus
        if type(obj[att_type]) == 'function' then
            return CKR.FUNCTION_FAILED
        end
        
        return CKR.OK, obj[att_type]
    else
        log.output('get_pubkey_ds(): error reading attribute:', theErrorT )
        return CKR.ATTRIBUTE_TYPE_INVALID
    end
end



function t.mt:get_ecc_privkey_ds(hobj, att_type, onlysize)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local id = nil
    local obj = self.attributes[hobj]
    local fid, attr_path
    local obj_attributes
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('get_ecc_privkey_ds(): ERROR! not a private key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    local oType = bin.flags("0x" .. obj.ds_id) * oberthur_util.objFIDS.eMASK
    fid = bin.flags('0x0100') + bin.flags(obj.num) + oType
    log.output('get_ecc_privkey_ds(): calculated fid:', fid )
    attr_path = hexf(obj.ds_parent_path .. '%H', fid.asnumber)
    local pcRes, theErrorT
    
    if obj[CKA.KEY_TYPE] == eCK.ULONG(CKK.EC_EDWARDS) then
        log.output('get_ecc_privkey_ds(): reading EC_EDWARDS value...')
        pcRes, theErrorT = pcall(function()
                    local val_fid = bin.flags(obj.num) + oType
                    log.output('get_ecc_privkey_ds(): calculated val_fid:', val_fid )
                    local val_fid_path = hexf(obj.ds_parent_path .. '%H', val_fid.asnumber)
                    log.output('get_ecc_privkey_ds(): reading val for ecc privkey:', hex.hexify(val_fid_path) )

                    local val = self:read_cached_file(val_fid_path, 0, -1, true)
                    obj.sk = val
                end
                )
        if not pcRes then
            log.output('get_ecc_privkey_ds(): error reading reading val for ecc privkey:', debug.traceback(theErrorT) )
        end
    end  
    pcRes, theErrorT = pcall(function()
                log.output('get_ecc_privkey_ds(): reading attributes for ecc privkey:', hex.hexify(attr_path) )
                obj_attributes = self:read_cached_file(attr_path, 0, -1, true)
                obj_attributes = oberthur_util.parse_ecc_ds_priv_pub_key_attribute_val(obj_attributes, obj.key_bits / 8)
                obj.kid = obj.num
            end
            )
    if pcRes then
        obj[CKA.LABEL] = obj_attributes.label
        obj[CKA.ID] = obj_attributes.id
        
        obj[CKA.EC_POINT] = obj_attributes.eccPoint
        obj[CKA.EC_PARAMS] = obj_attributes.ecParams

        obj[CKA.START_DATE] = obj_attributes.startdate
        obj[CKA.END_DATE] = obj_attributes.enddate
        obj[CKA.SUBJECT] = obj_attributes.subject
        obj[CKA.MODIFIABLE] = eCK.BBOOL((bin.flags('0x0001') * obj_attributes.flags).asbool)
        obj[CKA.LOCAL]      = eCK.BBOOL((bin.flags('0x0004') * obj_attributes.flags).asbool)
        obj[CKA.DECRYPT]    = eCK.BBOOL((bin.flags('0x0010') * obj_attributes.flags).asbool)
        obj[CKA.SIGN]       = eCK.BBOOL((bin.flags('0x0020') * obj_attributes.flags).asbool)
        obj[CKA.SIGN_RECOVER]= eCK.BBOOL((bin.flags('0x0080') * obj_attributes.flags).asbool)
        obj[CKA.UNWRAP]     = eCK.BBOOL((bin.flags('0x0400') * obj_attributes.flags).asbool)
        obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL((bin.flags('0x0800') * obj_attributes.flags).asbool)
        
        obj[CKA.DERIVE] = eCK.BBOOL((bin.flags('0x1000') * obj_attributes.flags).asbool)
        obj[CKA.COPYABLE] = eCK.BBOOL((bin.flags('0x2000') * obj_attributes.flags).asbool)
        obj[CKA.DESTROYABLE] = eCK.BBOOL(not (bin.flags('0x8000') * obj_attributes.flags).asbool)
        
        -- obj[CKA.VALUE] = obj_attributes.eccPoint  --- key value is not exportable, always sensitive, TODO
                
        obj.populated = true
        return CKR.OK, obj[att_type]
    else
        log.output('get_ecc_privkey_ds(): error reading attribute:', debug.traceback(theErrorT) )
        return CKR.ATTRIBUTE_TYPE_INVALID
    end
end

function t.mt:get_ecc_pubkey_ds(hobj, att_type, onlysize, force_all)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local id = nil
    local obj = self.attributes[hobj]
    local attr_fid, attr_path, val_fid, val_path
    local obj_attributes
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PUBLIC_KEY) then
        log.output('get_ecc_pubkey_ds(): ERROR! not a public key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    local oType = bin.flags("0x" .. obj.ds_id) * oberthur_util.objFIDS.eMASK
    
    attr_fid = bin.flags('0x0100') + bin.flags(obj.num) + oType
    attr_path = hexf(obj.ds_parent_path .. '%H', attr_fid.asnumber)
    val_path = hexf(obj.path)
    log.output('get_ecc_pubkey_ds(): calculated fids:', 'attr_path:', hex.hexify(attr_path), 'val_path:', hex.hexify(val_path) )
    local pcRes, theErrorT = pcall(function() 
                if not obj.obj_attributes then
                    log.output('get_ecc_pubkey_ds(): reading attributes for pubkey :', hex.hexify(attr_path) )
                    obj_attributes = self:read_cached_file(attr_path, 0, -1, true)
                    
                    obj_attributes = oberthur_util.parse_ecc_ds_priv_pub_key_attribute_val(obj_attributes)
                    obj.obj_attributes = obj_attributes
                else
                    log.output('get_ecc_pubkey_ds(): using already cached attributes for pubkey:', hex.hexify(attr_path) )
                    obj_attributes = obj.obj_attributes
                end
            end
            )
    if pcRes then
        obj[CKA.LABEL] = obj_attributes.label
        obj[CKA.ID] = obj_attributes.id
        
        obj[CKA.EC_POINT] = obj_attributes.eccPoint
        obj[CKA.EC_PARAMS] = obj_attributes.ecParams

        obj[CKA.START_DATE] = obj_attributes.startdate
        obj[CKA.END_DATE] = obj_attributes.enddate
        obj[CKA.SUBJECT] = obj_attributes.subject
        obj[CKA.MODIFIABLE] = eCK.BBOOL((bin.flags('0x0001') * obj_attributes.flags).asbool)
        obj[CKA.TRUSTED]  = eCK.BBOOL((bin.flags('0x0002') * obj_attributes.flags).asbool)
        obj[CKA.LOCAL]    = eCK.BBOOL((bin.flags('0x0004') * obj_attributes.flags).asbool)
        obj[CKA.ENCRYPT]  = eCK.BBOOL((bin.flags('0x0008') * obj_attributes.flags).asbool)
        obj[CKA.VERIFY]   = eCK.BBOOL((bin.flags('0x0040') * obj_attributes.flags).asbool)
        obj[CKA.VERIFY_RECOVER]= eCK.BBOOL((bin.flags('0x0100') * obj_attributes.flags).asbool)
        obj[CKA.WRAP]     = eCK.BBOOL((bin.flags('0x0200') * obj_attributes.flags).asbool)
        
        obj[CKA.DERIVE] = eCK.BBOOL((bin.flags('0x1000') * obj_attributes.flags).asbool)
        obj[CKA.COPYABLE] = eCK.BBOOL((bin.flags('0x2000') * obj_attributes.flags).asbool)
        obj[CKA.DESTROYABLE] = eCK.BBOOL(not (bin.flags('0x8000') * obj_attributes.flags).asbool)
        
        obj.populated = true
        if type(obj[att_type]) == 'function' then
            return CKR.FUNCTION_FAILED
        end
        
        return CKR.OK, obj[att_type]
    else
        log.output('get_ecc_pubkey_ds(): error reading attribute:', theErrorT )
        return CKR.ATTRIBUTE_TYPE_INVALID
    end
end


local function extract_x509_certificate(data)

    log.output('extract_x509_certificate():')

    data = CnsSmartcard.decode_x509_certificate(data)
    
    local der_size = string.sub(data, 1, 4)
    if string.sub(der_size, 1, 2) == hexf('5a82') or string.sub(der_size, 1, 2) == hexf('7a82')  then  -- z|Z\x82 + sizeBE + compressed data
        local size = string.byte(der_size, 3) * 256 + string.byte(der_size, 4)
        log.output('extract_x509_certificate(): PT: using CPR mode: expected size:', size)
        local compr = string.sub(data,5, 4+size)
        local decompr
        if string.sub(der_size, 1, 2) == hexf('7a82') then
            decompr = zlib.decompress2(compr, true, nil, nil)
        else
            decompr = zlib.decompress(compr, true, nil, nil)
        end
        log.output('extract_x509_certificate(): PT: cpr ratio:', 
                (4+string.len(compr))/string.len(decompr or "0"))
                
        decompr = CnsSmartcard.decode_x509_certificate(decompr)
        return decompr
    else
        if string.sub(der_size, 1, 2) ~= hexf('3082') then
            error('extract_x509_certificate Error: bad certificate', 2)
        end
        local size = string.byte(der_size, 3) * 256 + string.byte(der_size, 4)
        return der_size .. string.sub(data,5, 4+size)  
    end

end


function t.mt:get_certificate_ds(hobj, att_type, onlysize, force_all)
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
    attr_fid = bin.flags('0x0100') + bin.flags(obj.num) + oberthur_util.objFIDS.eCert
    attr_path = hexf(obj.ds_parent_path .. '%H', attr_fid.asnumber)
    val_path = hexf(obj.path)
    
    
    
    log.output('get_certificate_ds(): calculated fids:', 'attr_path:', hex.hexify(attr_path), 'val_path:', hex.hexify(val_path) )
    local pcRes, theErrorT = pcall(function() 
                if force_all or att_type == CKA.VALUE and type(obj[CKA.VALUE]) ~= "string" then
                    log.output('get_certificate_ds(): reading value for cert:', hex.hexify(val_path) )
                    cert_value = self:read_cached_file(val_path, 0, -1, true)
                    if  type(cert_value) == "string" and string.len(cert_value) >0 then
                        log.output('get_certificate_ds(): read_cached_file(): got value:', hex.hexify(cert_value) )
                        cert_value = extract_x509_certificate(cert_value)
                        log.output('get_certificate_ds(): reparsed value:', hex.hexify(cert_value) )
                    end
                    if type(cert_value) ~= "string" or string.len(cert_value) < 4 then
                        if not pcall(function()
                            cert_value = self.cns_hcard:read_x509_certificate(val_path)
                        end) then
                            log.output('get_certificate_ds(): retrying reading value for cert:', hex.hexify(val_path) )
                            cert_value = self.cns_hcard:read_x509_certificate(val_path)
                        end
                    end
                end
                if not obj.obj_attributes then
                    log.output('get_certificate_ds(): reading attributes for cert:', hex.hexify(attr_path) )
                    obj_attributes = self:read_cached_file(attr_path, 0, -1, true)
                    
                    obj_attributes = oberthur_util.parse_ds_cert_attribute_val(obj_attributes)
                    obj.obj_attributes = obj_attributes
                else
                    log.output('get_certificate_ds(): using already cached attributes for cert:', hex.hexify(attr_path) )
                    obj_attributes = obj.obj_attributes
                end
            end
            )
    if pcRes then
        pcall(function() parsed_cer = der.parse_x509cer(cert_value) end )
        obj[CKA.LABEL] = obj_attributes.label
        obj[CKA.ID] = obj_attributes.id
        obj[CKA.VALUE] = cert_value or obj[CKA.VALUE]
        obj[CKA.SUBJECT] = obj_attributes.subject or (parsed_cer and parsed_cer.subject) or ''
        obj[CKA.ISSUER] = obj_attributes.issuer or (parsed_cer and parsed_cer.issuer) or ''
        obj[CKA.SERIAL_NUMBER] = obj_attributes.serialnumber or (parsed_cer and parsed_cer.serialNumber) or ''
        obj[CKA.MODIFIABLE] = eCK.BBOOL((bin.flags('0x0001') * obj_attributes.flags).asbool)
        obj[CKA.TRUSTED]      = eCK.BBOOL((bin.flags('0x0002') * obj_attributes.flags).asbool)
        
        obj[CKA.COPYABLE] = eCK.BBOOL((bin.flags('0x2000') * obj_attributes.flags).asbool)
        obj[CKA.DESTROYABLE] = eCK.BBOOL(not (bin.flags('0x8000') * obj_attributes.flags).asbool)
        
        obj.populated = force_all or cert_value
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
        attr_fid = bin.flags('0x0100') + bin.flags(obj.num) + oberthur_util.objFIDS.eDataP
    else
        attr_fid = bin.flags('0x0100') + bin.flags(obj.num) + oberthur_util.objFIDS.eData
    end
    attr_path = hexf(obj.ds_parent_path .. '%H', attr_fid.asnumber)
    val_path = hexf(obj.path)
    log.output('get_data_ds(): calculated fids:', 'attr_path:', hex.hexify(attr_path), 'val_path:', hex.hexify(val_path) )
    local pcRes, theErrorT
    
    pcRes, theErrorT = pcall(function() 
            log.output('get_data_ds(): reading attributes for data obj :', hex.hexify(attr_path) )
            obj_attributes = oberthur_util.parse_ds_data_attribute(self.cns_hcard, attr_path)
            if obj.size > 0 then
                log.output('get_data_ds(): reading value for data obj:', hex.hexify(val_path) )
                local finfo = self.cns_hcard:select(val_path, true)
                value = self.cns_hcard:mread_binary(0, finfo.size)
            end
        end)

    if pcRes then
        obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
        obj[CKA.MODIFIABLE] = eCK.BBOOL((bin.flags('0x0001') * obj_attributes.flags).asbool)
        obj[CKA.LABEL] = obj_attributes.label
        obj[CKA.APPLICATION] = obj_attributes.appId
        obj[CKA.OBJECT_ID] = obj_attributes.objId
        obj[CKA.VALUE] = value
        
        obj[CKA.COPYABLE] = eCK.BBOOL((bin.flags('0x2000') * obj_attributes.flags).asbool)
        obj[CKA.DESTROYABLE] = eCK.BBOOL(not (bin.flags('0x8000') * obj_attributes.flags).asbool)
        
        obj.populated = true
        return CKR.OK, obj[att_type]
    else
        log.output('get_data_ds(): error reading attribute:', theErrorT )
        return CKR.ATTRIBUTE_TYPE_INVALID
    end 
end

--=====================================================================================

function t.mt:sign_buffer(hKey, pMechanism, pData, allocated_space)

    log.output(string.format('sign_buffer(): hKey=%x', hKey ) )
    log.output(string.format('sign_buffer(): pData=%s', pData and hex.hexify(pData) or "<null>" ) )
    log.output(string.format('sign_buffer(): allocated_space=%x', allocated_space or -1 ) )
    if pMechanism and pMechanism.mechanism then
        log.output(string.format('sign_buffer(): mechanism=%x', pMechanism.mechanism ) )
        log.output(string.format('sign_buffer(): parameter=%s', pMechanism.parameter and hex.hexify(pMechanism.parameter) or "<null>"))
    end
    
    if pMechanism and pMechanism.mechanism == CKM.ECDSA then
        log.output('sign_buffer(): CKM.ECDSA...')
        return self:sign_buffer_ecc(hKey, pMechanism, pData, allocated_space)
    elseif pMechanism and pMechanism.mechanism == CKM.EDDSA then
        log.output('sign_buffer(): CKM.EDDSA...')
        return self:sign_buffer_eddsa(hKey, pMechanism, pData, allocated_space)
    else
        log.output('sign_buffer(): RSA...')
        return self:sign_buffer_rsa(hKey, pMechanism, pData, allocated_space)
    end
end

function t.mt:sign_buffer_rsa(hKey, pMechanism, pData, allocated_space)
    local select_done = false
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('sign_buffer_rsa(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('sign_buffer_rsa(): ERROR: non private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    local pcRes, result
    
    
    if not self._license_valid then
        log.output('sign_buffer_rsa(): WARNING: invalid license')
        
        if obj.key_bits > 1024 then
            log.output('sign_buffer_rsa(): ERROR: usupported with not valid license')
            log.output('sign_buffer_rsa(): key_bits:', obj.key_bits )
            return CKR.KEY_FUNCTION_NOT_PERMITTED
        end
    end

    
    if dataLen > keyBytes or (dataLen > (keyBytes -4) and dataLen <  keyBytes) then
        -- nota: il padding pkcs1 richiede almeno 8 byte di oxFF prima dei dati da firmare
        log.output('sign_buffer_rsa(): specified data len invalid: ', dataLen)
        return CKR.DATA_LEN_RANGE
    end
    if allocated_space==nil then
        return CKR.OK, keyBytes
    else
        if type(obj.kid) == 'function' then
            local rv = obj.kid(self, hKey, CKA.CLASS, false)
            if rv ~= CKR.OK then return rv end
        end

        select_done = false
        if obj.pso_dec_sm then -- usa la modalita' PSO-DEC in SM
            local contextual_pin = nil
            log.output('sign_buffer_rsa(): using PSO-DEC-SM mode on ' .. obj.path .. '/' .. obj.kid)
            
            if not self.contextual_pin_verified then
                if self.request_plugin_valid
                   and (self.cfg["dspinusegui"] == 'true' or self.cfg["dspinusegui"] == 'sign')
                    then
                    if self.cached_ds_pin then
                        contextual_pin = self.cached_ds_pin
                    else
                        local res, cache_ds_pin
                        
                        
                        while true do
                            res, contextual_pin, cache_ds_pin = self:gui_request_pin_ds(self.check_box_visible)
                            if res ~= 1 then
                                log.output('sign_buffer_rsa(): cancelled by plugin with code:', res)
                                return CKR.FUNCTION_FAILED
                            end
                            
                            rv, contextual_pin = self:check_pin_value(contextual_pin, false, false)
                            if rv ~= CKR.OK then
                                return rv
                            end
                            
                            pcall(function() 
                                if self.cached_main_pin and self.userType == CKU.USER then
                                    log.output('sign_buffer_rsa(): before verify pin DS: verify_pin_cns() with:', self.cached_main_pin, self.userType)
                                    self.cns_hcard:verify_pin_cns(self.cached_main_pin)
                                end
                            end)
                            self.cns_hcard:select(hex.hexf(obj.path))
                            select_done = true
                            result = self.cns_hcard:verify_pin_ds(contextual_pin, self.ds_info.sm_use_enc, self.ds_info.sm_use_sig)
                            if result == 0 then
                                self.cns_hcard:des3_ext_auth(self.cns_hcard.BSO_DSX_AUTH, self.DSX_DERIVED_KEY_AUTH, true, 8)
                            end
                            if result == 0 and cache_ds_pin then
                                self.cached_ds_pin = contextual_pin
                                contextual_pin = nil
                            end
                            if self:gui_show_pin_message(result, false) ~= 1 then
                                break
                            end
                        end
                    end
                elseif self.cfg["dspiniscnspin"]=='true' then
                    log.output('sign_buffer_rsa(): using main pin as contextual pin...')
                    contextual_pin = self.cached_main_pin
                elseif obj[CKA.ALWAYS_AUTHENTICATE] == eCK.BBOOL(true) and not self.contextual_pin_verified then
                    log.output('sign_buffer_rsa(): requesting contextual login since ALWAYS_AUTHENTICATE is set...')
                    return CKR.USER_NOT_LOGGED_IN
                end
            end
            
            self.contextual_pin_verified = false
            local obj_path = obj.path
            if not select_done then
                self.cns_hcard:select(hex.hexf(obj.path))
            end
            
            if not contextual_pin and self.contextual_pin_verified_cache then
                contextual_pin=self.contextual_pin_verified_cache
                self.contextual_pin_verified_cache = nil
            end
            
            if contextual_pin then
                pcall(function() 
                    log.output('sign_buffer_rsa(): verify_pin_cns() with:', self.cached_main_pin, self.userType)
                    if self.cached_main_pin and self.userType == CKU.USER then
                        self.cns_hcard:verify_pin_cns(self.cached_main_pin)
                    end
                end)
                
                pcall(function()
                    log.output('sign_buffer_rsa(): verify_pin_ds() with:', contextual_pin)
                    if self.cached_main_pin and self.userType == CKU.USER then
                        result = self.cns_hcard:verify_pin_ds(contextual_pin, self.ds_info.sm_use_enc, self.ds_info.sm_use_sig)
                        if result == 0 then
                            self.cns_hcard:des3_ext_auth(self.cns_hcard.BSO_DSX_AUTH, self.DSX_DERIVED_KEY_AUTH, true, 8)
                        end
                    end
                end)
            end
            -- if dataLen == keyBytes then
                -- log.output('sign_buffer_rsa(): trying PKCS#1 v1.5 unpad...')
                -- local unpadded = rsa.pkcs1_unpad(pData)
                -- if unpadded then
                    -- pData = unpadded
                    -- log.output('sign_buffer_rsa(): unpaded:', hex.hexify(pData))
                -- else
                    -- log.output('sign_buffer_rsa(): unable to unpad, specified data len invalid: ', dataLen)
                    -- return CKR.DATA_LEN_RANGE
                -- end
            -- end
            -- pcRes, result = pcall(function()
                            -- return self.cns_hcard:cds_cns(
                                -- pData,
                                -- obj_path, obj.kid,
                                -- self.ds_info.sm_use_enc, self.ds_info.sm_use_sig,
                                -- contextual_pin)
                            -- end )
            local pDataPadded
            if string.len(pData) == keyBytes then -- firma raw
                pDataPadded = pData
            else
                pDataPadded = '\0\1'..string.rep('\255',(keyBytes-3)-string.len(pData))
                                ..'\0'..pData
            end
            local pcRes, result = pcall(function()
                return self.cns_hcard:rsa_oberthur_sm(pDataPadded, obj_path, obj.kid, self.ds_info.sm_use_enc, self.ds_info.sm_use_sig)
            end)
            if pcRes then
                return CKR.OK, result
            end
            if self.cns_hcard.last_sw == hexf('6982') and contextual_pin then
                pcall(function()
                    log.output('sign_buffer_rsa(): verify_pin_ds() with:', contextual_pin)
                    if self.cached_main_pin and self.userType == CKU.USER then
                        result = self.cns_hcard:verify_pin_ds(contextual_pin, self.ds_info.sm_use_enc, self.ds_info.sm_use_sig)
                        if result == 0 then
                            self.cns_hcard:des3_ext_auth(self.cns_hcard.BSO_DSX_AUTH, self.DSX_DERIVED_KEY_AUTH, true, 8)
                        end
                    end
                end)
                local pcRes, result = pcall(function()
                    return self.cns_hcard:rsa_oberthur_sm(pDataPadded, obj_path, obj.kid, self.ds_info.sm_use_enc, self.ds_info.sm_use_sig)
                end)
                if pcRes then
                    return CKR.OK, result
                end
            end

            if self.cns_hcard.last_sw == hexf('6982') then
                return CKR.LOGIN_REQUIRED
            end
            
            local last_sw = self.cns_hcard.last_sw
            local pin_incorrect = string.sub(last_sw, 1, 1) == hexf('63')
            local pin_locked = last_sw == hexf('6983')
            if pcRes then
                self.contextual_pin_verified = false
                return CKR.OK, result
            elseif contextual_pin and (pin_incorrect or pin_locked ) then
                log.output('sign_buffer_rsa(): contextual PIN was incorrect or locked!')
                self.cached_ds_pin = nil
                self.contextual_pin_verified = false
                if pin_incorrect then return CKR.PIN_INCORRECT
                elseif pin_locked then return CKR.PIN_LOCKED
                else return CKR.FUNCTION_FAILED
                end
            elseif self.cfg["dspiniscnspin"]~='true' and 
                    not self.contextual_pin_verified and
                    last_sw == hexf('6982') then
                log.output('sign_buffer_rsa(): requesting contextual login and forcing ALWAYS_AUTHENTICATE for next operations...')
                obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(true)
                return CKR.USER_NOT_LOGGED_IN
            else
                log.output('sign_buffer_rsa(): FUNCTION_FAILED...')
                return CKR.FUNCTION_FAILED
            end
        end

        if obj.pso_dec or
            (obj[CKA.ALWAYS_AUTHENTICATE] and obj[CKA.ALWAYS_AUTHENTICATE] ~= eCK.BBOOL(true)) then -- usa la modalita' PSO-DEC
            log.output('sign_buffer_rsa(): using RSA-Decrypt mode on ' .. obj.path .. '/' .. obj.kid)
            local pDataPadded
            if string.len(pData) == keyBytes then -- firma raw
                pDataPadded = pData
            else
                pDataPadded = '\0\1'..string.rep('\255',(keyBytes-3)-string.len(pData))
                                ..'\0'..pData
            end
            local pcRes, result = pcall(function()
                return self.cns_hcard:rsa_oberthur(pDataPadded, obj.path, obj.kid)
            end)
            if pcRes then
                obj.pso_dec = true -- forcing PSO-DEC for next operations
                return CKR.OK, result
            end
            if self.cns_hcard.last_sw == hexf('6982') then
                pcall(function() 
                    log.output('sign_buffer_rsa(): verify_pin_cns() with:', self.cached_main_pin, self.userType)
                    if self.cached_main_pin and self.userType == CKU.USER then
                        self.cns_hcard:verify_pin_cns(self.cached_main_pin)
                    end
                end)
                local pcRes, result = pcall(function()
                    return self.cns_hcard:rsa_oberthur(pDataPadded, obj.path, obj.kid)
                end)
                if pcRes then
                    obj.pso_dec = true -- forcing PSO-DEC for next operations
                    return CKR.OK, result
                end
            end

            if self.cns_hcard.last_sw == hexf('6982') then
                return CKR.LOGIN_REQUIRED
            end
        end
        
        select_done = false
        if not obj.pso_dec or not pcRes then -- usa la modalita' PSO-CDS
            local contextual_pin = nil
            log.output('sign_buffer_rsa(): using RSA-CDS mode on ' .. obj.path .. '/' .. obj.kid)
            
            if not self.contextual_pin_verified then
                if self.request_plugin_valid
                   and (self.cfg["dspinusegui"] == 'true' or self.cfg["dspinusegui"] == 'sign')
                    then
                    if self.cached_ds_pin then
                        contextual_pin = self.cached_ds_pin
                    else
                        local res, cache_ds_pin
                        
                        while true do
                            res, contextual_pin, cache_ds_pin = self:gui_request_pin_ds(self.check_box_visible)
                            if res ~= 1 then
                                log.output('sign_buffer_rsa(): cancelled by plugin with code:', res)
                                return CKR.FUNCTION_FAILED
                            end
                            
                            rv, contextual_pin = self:check_pin_value(contextual_pin, false, false)
                            if rv ~= CKR.OK then
                                return rv
                            end
                            
                            pcall(function() 
                                if self.cached_main_pin and self.userType == CKU.USER then
                                    log.output('sign_buffer_rsa(): before verify pin DS: verify_pin_cns() with:', self.cached_main_pin, self.userType)
                                    self.cns_hcard:verify_pin_cns(self.cached_main_pin)
                                end
                            end)
                            self.cns_hcard:select(hex.hexf(obj.path))
                            select_done = true
                            result = self.cns_hcard:verify_pin_ds(contextual_pin, self.ds_info.sm_use_enc, self.ds_info.sm_use_sig)
                            if result == 0 and cache_ds_pin then
                                self.cached_ds_pin = contextual_pin
                                contextual_pin = nil
                            end
                            if self:gui_show_pin_message(result, false) ~= 1 then
                                break
                            end
                        end
                    end
                elseif self.cfg["dspiniscnspin"]=='true' then
                    log.output('sign_buffer_rsa(): using main pin as contextual pin...')
                    contextual_pin = self.cached_main_pin
                elseif obj[CKA.ALWAYS_AUTHENTICATE] == eCK.BBOOL(true) and not self.contextual_pin_verified then
                    log.output('sign_buffer_rsa(): requesting contextual login since ALWAYS_AUTHENTICATE is set...')
                    return CKR.USER_NOT_LOGGED_IN
                end
            end
            
            self.contextual_pin_verified = false
            local obj_path
            if not select_done then
                obj_path = obj.path
            end
            
            if not contextual_pin and self.contextual_pin_verified_cache then
                contextual_pin=self.contextual_pin_verified_cache
                self.contextual_pin_verified_cache = nil
            end
            
            if contextual_pin then
                pcall(function() 
                    log.output('sign_buffer_rsa(): verify_pin_cns() with:', self.cached_main_pin, self.userType)
                    if self.cached_main_pin and self.userType == CKU.USER then
                        self.cns_hcard:verify_pin_cns(self.cached_main_pin)
                    end
                end)
            end
            if dataLen == keyBytes then
                log.output('sign_buffer_rsa(): trying PKCS#1 v1.5 unpad...')
                local unpadded = rsa.pkcs1_unpad(pData)
                if unpadded then
                    pData = unpadded
                    log.output('sign_buffer_rsa(): unpaded:', hex.hexify(pData))
                else
                    log.output('sign_buffer_rsa(): unable to unpad, specified data len invalid: ', dataLen)
                    return CKR.DATA_LEN_RANGE
                end
            end
            pcRes, result = pcall(function()
                            return self.cns_hcard:cds_cns(
                                pData,
                                obj_path, obj.kid,
                                self.ds_info.sm_use_enc, self.ds_info.sm_use_sig,
                                contextual_pin)
                            end )
            local last_sw = self.cns_hcard.last_sw
            local pin_incorrect = string.sub(last_sw, 1, 1) == hexf('63')
            local pin_locked = last_sw == hexf('6983')
            if pcRes then
                self.contextual_pin_verified = false
                obj.pso_dec = false -- forcing PSO-CDS for next operations
                return CKR.OK, result
            elseif contextual_pin and (pin_incorrect or pin_locked ) then
                log.output('sign_buffer_rsa(): contextual PIN was incorrect or locked!')
                self.cached_ds_pin = nil
                self.contextual_pin_verified = false
                if pin_incorrect then return CKR.PIN_INCORRECT
                elseif pin_locked then return CKR.PIN_LOCKED
                else return CKR.FUNCTION_FAILED
                end
            elseif self.cfg["dspiniscnspin"]~='true' and 
                    not self.contextual_pin_verified and
                    last_sw == hexf('6982') then
                log.output('sign_buffer_rsa(): requesting contextual login and forcing ALWAYS_AUTHENTICATE for next operations...')
                obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(true)
                return CKR.USER_NOT_LOGGED_IN
            end
        end
    end
    log.output('sign_buffer_rsa(): unexpected!')
    return CKR.FUNCTION_FAILED

end



function t.mt:sign_buffer_ecc(hKey, pMechanism, pData, allocated_space)
    log.output('sign_buffer_ecc(): hKey: ', hKey)
    local select_done = false
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('sign_buffer_ecc(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('sign_buffer_ecc(): ERROR: non private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    local sigLen = ((obj.key_bits/8) * 2)
    
    local rv, cka_ec_params = self:get_attribute_value(hKey, CKA.EC_PARAMS)
    local curve = ecdhlib.get_curve_by_deroid(cka_ec_params)
    
    if not curve then
        log.output('sign_buffer_ecc(): unsupported curve type!')
        return CKR.KEY_FUNCTION_NOT_PERMITTED
    end
    log.output('sign_buffer_ecc(): using curve: ', curve.name)
    pData = ecdhlib.trunk_to_curve_order(curve, pData)


    local dataLen = string.len(pData)
    local pcRes, result
    
    if not self._ecc_license_valid then
        log.output('sign_buffer_ecc(): WARNING: not _ecc_license_valid')
        return CKR.KEY_FUNCTION_NOT_PERMITTED
    end

    if allocated_space==nil then
        return CKR.OK, sigLen
    else
        local isds
        if type(obj.kid) == 'function' then
            local rv = obj.kid(self, hKey, CKA.CLASS, false)
            if rv ~= CKR.OK then return rv end
        end
       
        if type(obj[CKA.ALWAYS_AUTHENTICATE]) == 'function' then
            local rv = obj[CKA.ALWAYS_AUTHENTICATE](self, hKey, CKA.ALWAYS_AUTHENTICATE, false)
        end
        
        isds = obj[CKA.ALWAYS_AUTHENTICATE] == eCK.BBOOL(true)
        local sm_enc, sm_sig
        log.output('sign_buffer_ecc(): isds: ', isds)
        if isds then
            sm_enc, sm_sig = self.ds_info.sm_use_enc, self.ds_info.sm_use_sig
            
            if not self.contextual_pin_verified then
                if self.request_plugin_valid
                   and (self.cfg["dspinusegui"] == 'true' or self.cfg["dspinusegui"] == 'sign')
                    then
                    if self.cached_ds_pin then
                        contextual_pin = self.cached_ds_pin
                    else
                        local res, cache_ds_pin
                        
                        select_done = true
                        while true do
                            res, contextual_pin, cache_ds_pin = self:gui_request_pin_ds(self.check_box_visible)
                            if res ~= 1 then
                                log.output('sign_buffer_ecc(): cancelled by plugin with code:', res)
                                return CKR.FUNCTION_FAILED
                            end
                            
                            rv, contextual_pin = self:check_pin_value(contextual_pin, false, false)
                            if rv ~= CKR.OK then
                                return rv
                            end
                            
                            pcall(function() 
                                if self.cached_main_pin and self.userType == CKU.USER then
                                    log.output('sign_buffer_rsa(): before verify pin DS: verify_pin_cns() with:', self.cached_main_pin, self.userType)
                                    self.cns_hcard:verify_pin_cns(self.cached_main_pin)
                                end
                            end)
                            self.cns_hcard:select(hex.hexf(obj.path))
                            result = self.cns_hcard:verify_pin_ds(contextual_pin, self.ds_info.sm_use_enc, self.ds_info.sm_use_sig)
                            if result == 0 and cache_ds_pin then
                                self.cached_ds_pin = contextual_pin
                                contextual_pin = nil
                            end
                            if self:gui_show_pin_message(result, false) ~= 1 then
                                break
                            end
                        end
                    end
                elseif self.cfg["dspiniscnspin"]=='true' then
                    log.output('sign_buffer_ecc(): using main pin as contextual pin...')
                    contextual_pin = self.cached_main_pin
                elseif obj[CKA.ALWAYS_AUTHENTICATE] == eCK.BBOOL(true) and not self.contextual_pin_verified then
                    log.output('sign_buffer_ecc(): requesting contextual login since ALWAYS_AUTHENTICATE is set...')
                    return CKR.USER_NOT_LOGGED_IN
                end
            end
        end
        
        if isds and not contextual_pin and self.contextual_pin_verified_cache then
            contextual_pin=self.contextual_pin_verified_cache
            self.contextual_pin_verified_cache = nil
        end
            
        local pcRes, result = pcall(function()
            return self.cns_hcard:ecdsa_oberthur(pData, obj.path, obj.kid, sm_enc, sm_sig)
        end)
        if pcRes then
            return CKR.OK, result
        end
        if self.cns_hcard.last_sw == hexf('6982') then
            pcall(function() 
                log.output('sign_buffer_ecc(): verify_pin_cns() with:', self.cached_main_pin, self.userType)
                if self.cached_main_pin and self.userType == CKU.USER then
                    self.cns_hcard:verify_pin_cns(self.cached_main_pin)
                end
                
                if isds and contextual_pin then
                    self.cns_hcard:select(hex.hexf(obj.path))
                    self.cns_hcard:verify_pin_ds(contextual_pin, self.ds_info.sm_use_enc, self.ds_info.sm_use_sig)
                end
            end)


            local pcRes, result = pcall(function()
                return self.cns_hcard:ecdsa_oberthur(pData, obj.path, obj.kid, sm_enc, sm_sig)
            end)
            if pcRes then
                return CKR.OK, result
            end
        end

        if self.cns_hcard.last_sw == hexf('6982') then
            return CKR.LOGIN_REQUIRED
        end
    end
    
    log.output('sign_buffer_ecc(): unexpected!')
    return CKR.FUNCTION_FAILED

end


function t.mt:sign_buffer_eddsa(hKey, pMechanism, pData, allocated_space)
    local select_done = false
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('sign_buffer_eddsa(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('sign_buffer_eddsa(): ERROR: non private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    local sigLen = (obj.key_bits/8) * 2
    local dataLen = string.len(pData)
    local pcRes, result
    
    if not self._ecc_license_valid then
        log.output('sign_buffer_eddsa(): WARNING: not _ecc_license_valid')
        return CKR.KEY_FUNCTION_NOT_PERMITTED
    end

    
    if allocated_space==nil then
        return CKR.OK, sigLen
    else
        local sk = t._enc_dec_sensitive_data(obj.sk, self.info.serialNumber, false)
        local result = sm.crypto_sign_ed25519_detached(pData, sk)
        sk = nil; collectgarbage()
        return CKR.OK, result
    end
    
    log.output('sign_buffer_eddsa(): unexpected!')
    return CKR.FUNCTION_FAILED

end


function t.mt:decrypt_buffer(hKey, pMechanism, pData, allocated_space)

    log.output(string.format('decrypt_buffer(): hKey=%x', hKey ) )
    log.output(string.format('decrypt_buffer(): pData=%s', pData and hex.hexify(pData) or "<null>" ) )
    log.output(string.format('decrypt_buffer(): allocated_space=%x', allocated_space or -1 ) )
    if pMechanism and pMechanism.mechanism then
        log.output(string.format('decrypt_buffer(): mechanism=%x', pMechanism.mechanism ) )
        log.output(string.format('decrypt_buffer(): parameter=%s', pMechanism.parameter and hex.hexify(pMechanism.parameter) or "<null>"))
    end
    
    if pMechanism and pMechanism.mechanism == CKM.AES_CBC or pMechanism.mechanism == CKM.AES_CBC_PAD then
        log.output('decrypt_buffer(): AES mechanism...')
        return self:decrypt_buffer_aes(hKey, pMechanism, pData, allocated_space)
        
    elseif pMechanism and pMechanism.mechanism == CKM.CURVE25519_CRYPTO_BOX then
        log.output('decrypt_buffer(): CURVE25519_CRYPTO_BOX...')
        return self:decrypt_buffer_cryptobox(hKey, pMechanism, pData, allocated_space)
    else
        log.output('decrypt_buffer(): RSA...')
        return self:decrypt_buffer_rsa(hKey, pMechanism, pData, allocated_space)
    end

end

function t.mt:decrypt_buffer_rsa(hKey, pMechanism, pData, allocated_space)

    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('decrypt_buffer_rsa(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) 
        or obj[CKA.KEY_TYPE]  ~= eCK.OBJECT_CLASS(CKK.RSA) then
        log.output('decrypt_buffer_rsa(): ERROR: not an RSA private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    --if not obj.pso_dec then
    --    log.output('decrypt_buffer_rsa(): ERROR: decrypt not supported!')
    --    return CKR.KEY_TYPE_INCONSISTENT -- todo: errore non adatto
    --end
    if type(obj.kid) == 'function' then
        local rv = obj.kid(self, hKey, CKA.CLASS, false)
        if rv ~= CKR.OK then return rv end
    end

    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    if dataLen ~= keyBytes then
        log.output('decrypt_buffer_rsa(): specified data len invalid: ', dataLen, ', expected:', keyBytes)
        return CKR.ENCRYPTED_DATA_LEN_RANGE
    end
    
    pcall(function()
        log.output('decrypt_buffer_rsa(): verify_pin_cns() with:', self.cached_main_pin, self.userType)
        if self.cached_main_pin and self.userType == CKU.USER then
            self.cns_hcard:verify_pin_cns(self.cached_main_pin, false, false, self.ds_info.sm_use2_enc, self.ds_info.sm_use2_sig)
        end
    end)
    local pDataPadded
    pcall( function()
        pDataPadded = self.cns_hcard:rsa_oberthur(pData, obj.path, obj.kid)
    end)
    if self.cns_hcard.last_sw == hexf('6982') then
        local pcRes = pcall(function() 
            log.output('decrypt_buffer_rsa(): verify_pin_cns() with:', self.cached_main_pin, self.userType)
            if self.cached_main_pin and self.userType == CKU.USER then
                self.cns_hcard:verify_pin_cns(self.cached_main_pin)
            end
        end)
        if pcRes then
            pcall( function()
                pDataPadded = self.cns_hcard:rsa_oberthur(pData, obj.path, obj.kid)
            end)
        end
    end

    if pDataPadded == nil or string.len(pDataPadded) ~= keyBytes then
        log.output('decrypt_buffer_rsa(): cannot decrypt specified data')
        return CKR.ENCRYPTED_DATA_INVALID
    end
    if not pMechanism or not pMechanism.mechanism or pMechanism.mechanism == CKM.RSA_PKCS then
        if string.byte(pDataPadded, 1) ~= 0 or string.byte(pDataPadded, 2) ~= 2 then
            
            log.output('decrypt_buffer_rsa(): data decrypted, pkcs1 padding invalid, byte1:',
                        string.byte(pDataPadded, 1),
                        'byte2:', string.byte(pDataPadded, 2))
            return CKR.ENCRYPTED_DATA_INVALID
        end
        local idx = string.find(pDataPadded, '\0', 4, true)
        if idx == nil then
            log.output('decrypt_buffer_rsa(): data decrypted, pkcs1 padding invalid, cannot find payload')
            return CKR.ENCRYPTED_DATA_INVALID
        end
        local result = string.sub(pDataPadded, idx+1, -1)
        return CKR.OK, result
    else
        return CKR.OK, pDataPadded
    end
end


function t.mt:encrypt_buffer(hKey, pMechanism, pData, allocated_space)
    log.output(string.format('encrypt_buffer(): hKey=%x', hKey ) )
    log.output(string.format('encrypt_buffer(): pData=%s', pData and hex.hexify(pData) or "<null>" ) )
    log.output(string.format('encrypt_buffer(): allocated_space=%x', allocated_space or -1 ) )
    if pMechanism and pMechanism.mechanism then
        log.output(string.format('encrypt_buffer(): mechanism=%x', pMechanism.mechanism ) )
        log.output(string.format('encrypt_buffer(): parameter=%s', pMechanism.parameter and hex.hexify(pMechanism.parameter) or "<null>"))
    end
    log.output('encrypt_buffer(): pData=', pData and hex.hexify(pData ) or "<null>")
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('encrypt_buffer(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('encrypt_buffer(): ERROR: not a private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    if obj[CKA.KEY_TYPE] ~= eCK.ULONG(CKK.EC_EDWARDS) then
        log.output('encrypt_buffer(): ERROR: not a EC_EDWARDS key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    if type(obj.kid) == 'function' then
        local rv = obj.kid(self, hKey, CKA.CLASS, false)
        if rv ~= CKR.OK then return rv end
    end

    if not pMechanism or pMechanism.mechanism ~= CKM.CURVE25519_CRYPTO_BOX then
        log.output('encrypt_buffer(): MECHANISM_INVALID:', pMechanism and pMechanism.mechanism )
        return CKR.MECHANISM_INVALID
    end
        
    local crypto_box_NONCEBYTES  = 24
    -- local crypto_box_SECRETKEYBYTES  = 32
    local crypto_box_PUBLICKEYBYTES  = 32
    local nonce
    
    local pk = pMechanism.parameter
    if not pk or string.len(pk) < crypto_box_PUBLICKEYBYTES then
        log.output('encrypt_buffer(): MECHANISM_PARAM_INVALID:', hex.hexify(pMechanism.parameter or ""), "expected len:", crypto_box_PUBLICKEYBYTES )
        return CKR.MECHANISM_PARAM_INVALID
    end
    if string.len(pk) >= (crypto_box_PUBLICKEYBYTES + crypto_box_NONCEBYTES) then
        nonce = string.sub(pk, crypto_box_PUBLICKEYBYTES+1, crypto_box_PUBLICKEYBYTES + crypto_box_NONCEBYTES)
        log.output('encrypt_buffer(): using nonce passed in parameter:', hex.hexify(nonce) )
    else
        nonce = sm.gen_random(crypto_box_NONCEBYTES)
        log.output('encrypt_buffer(): using randomly generated nonce:', hex.hexify(nonce) )
    end
    
    local vk = sm.crypto_sign_ed25519_pk_to_curve25519(string.sub(pk, 1, crypto_box_PUBLICKEYBYTES))
    local dec_sk = t._enc_dec_sensitive_data(obj.sk, self.info.serialNumber, false)
    
    local sk = sm.crypto_sign_ed25519_sk_to_curve25519(dec_sk)
    dec_sk = nil
    collectgarbage()

    local result = sm.crypto_box_easy(pData, nonce, vk, sk)
    sk = nil
    collectgarbage()
    return CKR.OK, nonce .. result


end


function t.mt:decrypt_buffer_cryptobox(hKey, pMechanism, pData, allocated_space)
    log.output(string.format('decrypt_buffer_cryptobox(): hKey=%x', hKey ) )
    log.output(string.format('decrypt_buffer_cryptobox(): pData=%s', pData and hex.hexify(pData) or "<null>" ) )
    log.output(string.format('decrypt_buffer_cryptobox(): allocated_space=%x', allocated_space or -1 ) )
    if pMechanism and pMechanism.mechanism then
        log.output(string.format('decrypt_buffer_cryptobox(): mechanism=%x', pMechanism.mechanism ) )
        log.output(string.format('decrypt_buffer_cryptobox(): parameter=%s', pMechanism.parameter and hex.hexify(pMechanism.parameter) or "<null>"))
    end
    log.output('decrypt_buffer_cryptobox(): pData=', pData and hex.hexify(pData ) or "<null>")
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('decrypt_buffer_cryptobox(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('decrypt_buffer_cryptobox(): ERROR: not a private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    if obj[CKA.KEY_TYPE] ~= eCK.ULONG(CKK.EC_EDWARDS) then
        log.output('decrypt_buffer_cryptobox(): ERROR: not a EC_EDWARDS key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    if type(obj.kid) == 'function' then
        local rv = obj.kid(self, hKey, CKA.CLASS, false)
        if rv ~= CKR.OK then return rv end
    end

    if not pMechanism or pMechanism.mechanism ~= CKM.CURVE25519_CRYPTO_BOX then
        log.output('decrypt_buffer_cryptobox(): MECHANISM_INVALID:', pMechanism and pMechanism.mechanism )
        return CKR.MECHANISM_INVALID
    end
        
    local crypto_box_NONCEBYTES  = 24
    --local crypto_box_SECRETKEYBYTES  = 32
    local crypto_box_PUBLICKEYBYTES  = 32
    local nonce
    
    local pk = pMechanism.parameter
    if not pk or string.len(pk) < crypto_box_PUBLICKEYBYTES then
        log.output('decrypt_buffer_cryptobox(): MECHANISM_PARAM_INVALID:', hex.hexify(pMechanism.parameter or ""), "expected len:", crypto_box_PUBLICKEYBYTES )
        return CKR.MECHANISM_PARAM_INVALID
    end
    if string.len(pk) >= (crypto_box_PUBLICKEYBYTES + crypto_box_NONCEBYTES) then
        nonce = string.sub(pk, crypto_box_PUBLICKEYBYTES+1, crypto_box_PUBLICKEYBYTES+crypto_box_NONCEBYTES)
        log.output('decrypt_buffer_cryptobox(): using nonce passed in parameter:', hex.hexify(nonce) )
    else
        nonce = string.sub(pData, 1, crypto_box_NONCEBYTES)
        pData = string.sub(pData, crypto_box_NONCEBYTES + 1, -1)
        log.output('decrypt_buffer_cryptobox(): using nonce prefixed to pData:', hex.hexify(nonce) )
        log.output('decrypt_buffer_cryptobox(): new pData to decrypt:', hex.hexify(pData) )
    end
    
    local vk = sm.crypto_sign_ed25519_pk_to_curve25519(string.sub(pk, 1, crypto_box_PUBLICKEYBYTES))
    local dec_sk = t._enc_dec_sensitive_data(obj.sk, self.info.serialNumber, false)
    local sk = sm.crypto_sign_ed25519_sk_to_curve25519(dec_sk)
    dec_sk = nil
    collectgarbage()
    local result = sm.crypto_box_open_easy(pData, nonce, vk, sk)
    sk = nil
    collectgarbage()
    return CKR.OK, result


end

-- se search_state.lastobj==nil si richiede l'handle del primo oggetto che risponda
-- al template. Altrimenti restituisce il primo oggetto che sia
-- compatibile con il template e abbia handle>search_state.lastobj.
-- quando non ci sono pi