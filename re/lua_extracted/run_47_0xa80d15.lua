 stata importata la chiave privata
        if self.cns_info.pub_key_handle then
            log.output('create_object_pubkey(): CNS Public Key already exists, returning existing key HANDLE', 
                        self.cns_info.pub_key_handle)
            return CKR.OK, self.cns_info.pub_key_handle
        else
            log.output('create_object_pubkey(): CNS Public Key cannot be imported before private key')
            return CKR.DEVICE_MEMORY
        end       
    end
    
    if not self.p11_info then
        log.output('create_object_pubkey(): no P11 FS available')
        return CKR.FUNCTION_FAILED
    end
    obj = objP11Tmpl.GetP11PubKeyTemplate(t.mt.get_pubkey_p11)
    local freeSlots = self:look_for_free_slots(1)
    
    if not freeSlots or table.getn(freeSlots) == 0 then
        return CKR.DEVICE_MEMORY
    end
    freeSlot = freeSlots[1]
    obj.num = freeSlot
    fid_val = self:buildP11Fid(obj.num, objTypes.ePubKey, attrTypes.ePubKeyModExp)
    fid_main = self:buildP11Fid(obj.num, objTypes.ePubKey, attrTypes.eMain)
    table.insert(fids_to_del, self:buildP11Fid(obj.num, objTypes.ePrivKey, attrTypes.eMain))
    table.insert(fids_to_del, self:buildP11Fid(obj.num, objTypes.eCert, attrTypes.eMain))
    table.insert(fids_to_del, self:buildP11Fid(obj.num, objTypes.eData, attrTypes.eMain))
    
    obj.parent_path = self.p11_info.path_root
    obj.path = hex.hexify(hexf(obj.parent_path .. '%H', fid_val ))
    obj.isp11 = true

    obj.private = false
    obj.key_bits = modulus_bits
    
    local pTemplate_copy = utility.clone_table(pTemplate)
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if not pTemplate_copy[k] and obj[k] and type(obj[k]) == 'string' then
            pTemplate_copy[k] = obj[k]
        end
    end
    pTemplate_copy[CKA.LOCAL] = eCK.BBOOL(as_local)
        
    -- crea il file TLV per gli oggetti non CNS

                        
    if modulus_bits == 1024 then
        self:create_file( { size=string.len(pTemplate_copy[CKA.MODULUS]) + string.len(pTemplate_copy[CKA.PUBLIC_EXPONENT]) + 32,
                            filetype=CnsSmartcard.fileTypes.RecordTLV,
                            parent=hexf(obj.parent_path),
                            fid=fid_val, 
                            asm={},
                            }, true, true )
        -- aggiorna o aggiunge i record TLV
        local pubExpLen = string.len(pTemplate_copy[CKA.PUBLIC_EXPONENT])
        local modulusLen = string.len(pTemplate_copy[CKA.MODULUS])
        self:update_append_record(obj.path, 1, 
                                  hex.hexf('10%B%B00', modulusLen+2, modulusLen+1) .. pTemplate_copy[CKA.MODULUS] )
        self:update_append_record(obj.path, 2,
                                  hex.hexf('11%B%B00', pubExpLen+2, pubExpLen+1) .. pTemplate_copy[CKA.PUBLIC_EXPONENT])
    else
        local rv, pubexpPadded = self:_pad_bignum(pTemplate_copy[CKA.PUBLIC_EXPONENT], 8)
        if rv~=CKR.OK then
            return rv
        end
        local modulus = pTemplate_copy[CKA.MODULUS]

        self:create_file( { size=256+8,
                            filetype=CnsSmartcard.fileTypes.Binary,
                            parent=hexf(obj.parent_path),
                            fid=fid_val,
                            asm={},
                            }, true, true )
        self.cns_hcard:select(hexf(obj.path))
        self.cns_hcard:mupdate_binary(0, modulus .. pubexpPadded)
    end
    
    -- crea tutti gli attributi PKCS#11 della chiave pubblica
    if self.p11_info.version_major >= 2 then
        local pubk_mainfile = t.serialize_attr_p11v2_pubkey(pTemplate_copy, obj.num, obj.key_bits)
        self:create_p11_file(pubk_mainfile, fid_main, true)
    else
        self:set_p11_attribute(obj.num, objTypes.ePubKey, attrTypes.eLabel, pTemplate_copy[CKA.LABEL], true)
        self:set_p11_attribute(obj.num, objTypes.ePubKey, attrTypes.eID, pTemplate_copy[CKA.ID], true)
        local pubk_mainfile = self:pubkey_serialize_mainfile(pTemplate_copy, obj.num, obj.key_bits)
        self:create_p11_file(pubk_mainfile, fid_main, true)
    end
    for i, v in fids_to_del do
        pcall(function()
            self.cns_hcard:delete_file(v, true)
        end)
    end
    self.p11_info.obj_table[obj.num] = true
    self:write_p11_indexes()
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] and not t._is_private_attribute(k) then
            obj[k] = pTemplate[k]
        end
    end
    
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    
    return CKR.OK, self.attributes.max_index
end

function t.mt:_pad_bignum(big_num, pad_to)
    if not big_num or big_num == "" then
       return CKR.ATTRIBUTE_VALUE_INVALID, nil 
    end
    while string.sub(big_num, 1, 1) == '\000' do big_num = string.sub(big_num, 2, -1) end
    big_num = string.rep('\000', pad_to - string.len(big_num))
                            .. big_num
    if string.len(big_num) ~= pad_to then
        log.output('_pad_bignum(): value len invalid; expected:', pad_to)
        return CKR.ATTRIBUTE_VALUE_INVALID, nil
    end
    return CKR.OK, big_num
end

function t.mt:create_rsa_bso(kid, pTemplate, key_bits, create_bso)
    log.output('create_rsa_bso():', kid, key_bits, create_bso)
    local p, q, privExp, pubExp, exp1, exp2, ctx, rv
    
    if not key_bits then
        if not pTemplate then
            error("create_rsa_bso(): invalid params: Template or key_bits required!")
        end
        key_bits = string.len(pTemplate[CKA.MODULUS]) * 8
    end
    if key_bits ~= 1024 and key_bits ~= 2048 then
        error("create_rsa_bso(): invalid key len: " .. key_bits)
    end
    
    -- creates a BSO using correct ACs and algo
    local bso_info = {
        jsign=self.jsign_2048 or self.jsign3plus,
        jsign3=self.jsign3plus,
        key_bits=key_bits,
        kid=kid,
        pso_dec=true,
        aac = {use=self.cns_hcard.BSO_CNS_PIN, change=self.cns_hcard.BSO_CNS_PIN, 
               delete=self.cns_hcard.BSO_CNS_PIN, generate=self.cns_hcard.BSO_CNS_PIN},
    }
    
    if pTemplate and key_bits == 1024 then
        rv, privExp = self:_pad_bignum(pTemplate[CKA.PRIVATE_EXPONENT], 128)
        assert(rv == CKR.OK)
    elseif pTemplate and key_bits == 2048 then
        rv, p = self:_pad_bignum(pTemplate[CKA.PRIME_1], 128)
        assert(rv == CKR.OK)
        rv, q = self:_pad_bignum(pTemplate[CKA.PRIME_2], 128)
        assert(rv == CKR.OK)
        rv, pubExp = self:_pad_bignum(pTemplate[CKA.PUBLIC_EXPONENT], 8)
        assert(rv == CKR.OK)
        rv, exp1 = self:_pad_bignum(pTemplate[CKA.EXPONENT_1], 128)
        assert(rv == CKR.OK)
        rv, exp2 = self:_pad_bignum(pTemplate[CKA.EXPONENT_2], 128)
        assert(rv == CKR.OK)
        rv, ctx = self:_pad_bignum(pTemplate[CKA.COEFFICIENT], 128)
        assert(rv == CKR.OK)
    end
    
    if create_bso then
        if pTemplate and self.jsign3plus then
            bso_info.p=p
            bso_info.q=q
            bso_info.qmodp=ctx
            bso_info.dmodp1=exp1
            bso_info.dmodq1=exp2
            bso_info.modulus=pTemplate[CKA.MODULUS]
            bso_info.pubexp=pubExp
        end
        
        local bRes1, bRes2
        bRes1 = pcall (function()
            log.output('create_rsa_bso(): erasing bso EXP...')
            self.cns_hcard:delete_file(hexf('21%B', kid), true)
        end)
        bRes2 = pcall (function()
            log.output('create_rsa_bso(): erasing bso MOD...')
            self.cns_hcard:delete_file(hexf('20%B', kid), true)
        end)
    
        -- PATCH: le carte gi