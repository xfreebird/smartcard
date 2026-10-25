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
    
    obj.parent_path = '3F004FFF'
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
    pTemplate_copy[CKA.LOCAL] = eCK.BBOOL(false)
        
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
    self:set_p11_attribute(obj.num, objTypes.ePubKey, attrTypes.eLabel, pTemplate_copy[CKA.LABEL], true)
    self:set_p11_attribute(obj.num, objTypes.ePubKey, attrTypes.eID, pTemplate_copy[CKA.ID], true)
    local pubk_mainfile = self:pubkey_serialize_mainfile(pTemplate_copy, obj.num, obj.key_bits)
    self:create_p11_file(pubk_mainfile, fid_main, true)
    for i, v in fids_to_del do
        pcall(function()
            self.cns_hcard:delete_file_athena(v, true)
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
    local p, q, pubExp, exp1, exp2, ctx, rv
    local privExp
    
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
        _ac_padto=8,
        key_bits=key_bits,
        kid=kid,
        pso_dec=true,
        aac = {use=self.cns_hcard.BSO_CNS_PIN, change=self.cns_hcard.BSO_CNS_PIN, 
               delete=self.cns_hcard.BSO_CNS_PIN, generate=self.cns_hcard.BSO_CNS_PIN,
               ac8=self.cns_hcard.BSO_CNS_PIN
               },
    }
    
    if pTemplate and key_bits == 1024 then
        rv, privExp = self:_pad_bignum(pTemplate[CKA.PRIVATE_EXPONENT], 128)
        assert(rv == CKR.OK)
    elseif pTemplate and key_bits == 2048 then
        rv, privExp = self:_pad_bignum(pTemplate[CKA.PRIVATE_EXPONENT], 256)
        assert(rv == CKR.OK)
    end

    if pTemplate then
        bso_info.exponent = privExp
        bso_info.modulus = pTemplate[CKA.MODULUS]
    end
    if create_bso then
        local bRes = pcall (function()
            log.output('create_rsa_bso(): erasing bso MOD...')
            self.cns_hcard:delete_bso_athena(hexf('20%B', kid))
        end)
        local last_sw = self.cns_hcard.last_sw
        if bRes then 
            pcall (function()
                log.output('create_rsa_bso(): erasing bso EXP...')
                self.cns_hcard:delete_bso_athena(hexf('21%B', kid))
            end)
            last_sw = self.cns_hcard.last_sw
        end
        self.cns_hcard:create_rsa_bso_athena(bso_info)
    elseif pTemplate then
        self.cns_hcard:change_rsa_bso(kid, pTemplate[CKA.MODULUS], privExp)
    end
end


function t.mt:create_object_privkey(pTemplate)
    log.output('create_object_privkey()', pTemplate)
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj, objPub
    if not pTemplate[CKA.MODULUS] or not pTemplate[CKA.PUBLIC_EXPONENT] 
        or not pTemplate[CKA.PRIVATE_EXPONENT] then
        log.output('create_object_privkey(): MODULUS or PUBLIC_EXPONENT or PRIVATE_EXPONENT not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    local iscns = self:is_cns(pTemplate)
    local is_ds = self:is_ds(pTemplate)
    local fid_val, fid_attr
    local freeSlots, freeBso
    local pTemplate_copy = utility.clone_table(pTemplate)
    local modulus_bits = string.len(pTemplate[CKA.MODULUS]) * 8

    if is_ds then
        log.output('create_object_privkey(): cannot import DS private keys!')
        return CKR.TEMPLATE_INCONSISTENT
    end
    local p11_bso_start_index
    
    if modulus_bits == 1024 then
        p11_bso_start_index = tonumber('21', 16)
    elseif modulus_bits == 2048 then
        p11_bso_start_index = tonumber('41', 16)
        if iscns then
            log.output('create_object_privkey(): key size invalid for CNS filesystem:', modulus_bits )
            return CKR.ATTRIBUTE_VALUE_INVALID
        end
    else
        log.output('create_object_privkey(): key size invalid:', modulus_bits )
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    if modulus_bits > 1024 and (not self.p11_info or not self.support2048new) then
        log.output('create_object_privkey(): no P11 2048 FS available')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
   
    local freeId, freeSlot
    
    if iscns then
        if self.cns_info.key_valid then
            log.output('create_object_privkey(): CNS Private Key already exists')
            return CKR.DEVICE_MEMORY
        end
        obj = objCnsTmpl.GetCNSPrivKeyTemplate(t.mt.get_public_key)
        obj.private = true
        obj.pso_dec = true
        obj.iscns = true
        obj.key_bits = modulus_bits
        obj.path = self.cns_info.cns_key_prefix .. obj.path
        obj.kid = 1
        
        objPub = objCnsTmpl.GetCNSPubKeyTemplate(t.mt.get_public_key)
        objPub.path = self.cns_info.cns_key_prefix .. objPub.path
        objPub.iscns = true
        objPub[CKA.MODULUS] = pTemplate[CKA.MODULUS]
        objPub[CKA.PUBLIC_EXPONENT] = pTemplate[CKA.PUBLIC_EXPONENT]
        objPub[CKA.ID] = pTemplate[CKA.ID] or objPub[CKA.ID]
        
    else
        if not self.p11_info then
            log.output('create_object_privkey(): no P11 FS available')
            return CKR.FUNCTION_FAILED
        end

        freeSlots = self:look_for_free_slots(1)
        freeBso = self:look_for_free_bso(modulus_bits>1024)
        if not freeSlots or table.getn(freeSlots) == 0 then
            log.output('create_object_privkey(): no more objects id available')
            return CKR.DEVICE_MEMORY
        end
        if not freeBso then
            log.output('create_object_privkey(): no more BSO ids available')
            return CKR.DEVICE_MEMORY
        end
        
        obj = objP11Tmpl.GetP11PrivKeyTemplate(t.mt.get_privkey_p11)
        obj.path = '3F004FFF'
        obj.parent_path = obj.path
        obj.num = freeSlots[1]
        obj.kid = freeBso + p11_bso_start_index
        obj.private = true
        obj.pso_dec = true
        obj.isp11 = true
        obj.key_bits = modulus_bits
        
        for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
            if not pTemplate_copy[k] and obj[k] and type(obj[k]) == 'string' then
                pTemplate_copy[k] = obj[k]
            end
        end
        pTemplate_copy[CKA.LOCAL] = eCK.BBOOL(false)
    end
    
    -- crea / aggiorna il BSO
    self.cns_hcard:select(hexf(obj.path)) -- seleziona il parent del BSO
    self:create_rsa_bso(obj.kid, pTemplate, modulus_bits, not iscns)
    
    if iscns then
        -- aggiorna o aggiunge i record TLV
        local pubExpLen = string.len(pTemplate[CKA.PUBLIC_EXPONENT])
        local modulusLen = string.len(pTemplate[CKA.MODULUS])
        self:update_append_record(objPub.path, 1, 
                                  hex.hexf('10%B%B00', modulusLen+2, modulusLen+1) .. pTemplate[CKA.MODULUS] )
        self:update_append_record(objPub.path, 2,
                                  hex.hexf('11%B%B00', pubExpLen+2, pubExpLen+1) .. pTemplate[CKA.PUBLIC_EXPONENT])
        self.cns_info.key_valid = true
    else
        -- crea tutti gli attributi PKCS#11
        local fid_main = self:buildP11Fid(obj.num, objTypes.ePrivKey, attrTypes.eMain)
        local fids_to_del = {}
        table.insert(fids_to_del, self:buildP11Fid(obj.num, objTypes.ePubKey, attrTypes.eMain))
        table.insert(fids_to_del, self:buildP11Fid(obj.num, objTypes.eCert, attrTypes.eMain))
        table.insert(fids_to_del, self:buildP11Fid(obj.num, objTypes.eData, attrTypes.eMain))
        
        local privk_mainfile = self:privkey_serialize_mainfile(pTemplate_copy, obj.kid, obj.key_bits)
        self:create_p11_file(privk_mainfile, fid_main, false)
        for i, v in fids_to_del do
            pcall(function()
                self.cns_hcard:delete_file_athena(v, true)
            end)
        end
        self:set_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.eLabel, pTemplate_copy[CKA.LABEL], false )
        self:set_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.eID, pTemplate_copy[CKA.ID], false )
        self:set_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.eModulus, pTemplate_copy[CKA.MODULUS], false )
        self:set_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.ePubExp, pTemplate_copy[CKA.PUBLIC_EXPONENT], false )
        self:set_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.eSubject, pTemplate_copy[CKA.SUBJECT], false )
        
        -- update objects list
        self.p11_info.obj_table[obj.num] = true
        if modulus_bits>1024 then
            self.p11_info.bso2048_table[freeBso] = true
        else
            self.p11_info.bso_table[freeBso] = true
        end
        self:write_p11_indexes()
    end
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] and not t._is_private_attribute(k) then
            obj[k] = pTemplate[k]
        end
    end

    if iscns then
        if objPub then
            self.attributes.max_index = self.attributes.max_index +1
            self.attributes[self.attributes.max_index] = objPub       
        end
        self.cns_info.key_valid = true
        self.cns_info.pub_key_handle = self.attributes.max_index
    end
    -- adds new handle to the list

    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    
    log.output('create_object_privkey(): object created, handle: ' .. self.attributes.max_index)
    return CKR.OK, self.attributes.max_index
end

function t.mt:_delete_by_id(cka_id, cka_class, cka_label, cka_application)
    if not cka_id and not cka_class and not cka_label and not cka_application then
        error("_delete_by_id: invalid parameters!")
    end
    local find_template = {
        [CKA.ID] = cka_id,
        [CKA.CLASS] = cka_class and eCK.ULONG(cka_class),
        [CKA.APPLICATION] = cka_application,
        [CKA.LABEL] = cka_label,
        }
    local items = {}
    local find_state = {}
    local hObj, rv
    while true do
        hObj = self:get_item(find_state, true, find_template) -- can return private objects
        if hObj == 0 then
            break
        end
        table.insert(items, hObj)
    end
    for i, v in items do
        rv = self:destroy_object(v)
    end
end

function t.mt:update_ds_index()
    log.output('update_ds_index()')
    local ds_index = self.ds_info.path_root .. '7100'
    local ds_index_contents = ''
    
    local oGroups = {self.ds_info.ds_objects.o1024, self.ds_info.ds_objects.o2048}
    for k, oGroup in oGroups do
        for i=1, table.getn(oGroup) do
            ds_index_contents = ds_index_contents 
                            .. string.char(oGroup[i][1])
                            .. string.char(oGroup[i][2])
                            .. string.char(oGroup[i][3])
        end
    end
    self.cns_hcard:select(hexf(ds_index))
    self.cns_hcard:update_binary(3, ds_index_contents)
end

function t.mt:create_object_certificate(pTemplate)
    log.output('create_object_certificate()', pTemplate)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    if not pTemplate[CKA.VALUE] then
        log.output('create_object_certificate(): VALUE not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    local iscns = self:is_cns(pTemplate)
    local is_ds, ds_slot = self:is_ds(pTemplate, nil, true)
    
    if (iscns or is_ds) and self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    
    if is_ds and ds_slot == -1 then
        log.output('create_object_certificate(): no DS slots available')
        return CKR.DEVICE_MEMORY
    end
    
    local freeSlots
    local fid_val, fid_attr
    local parsed_cer
    
    pcall(function()
        parsed_cer = der.parse_x509cer(pTemplate[CKA.VALUE])
    end)
    
    if iscns then
        obj = objCnsTmpl.GetCNSCertTemplate(t.mt.get_certificate)
        obj.iscns=true
        -- scrive il certificato
        self.cns_hcard:select(hex.hexf(obj.path))
        self.cns_hcard:mupdate_binary(0, pTemplate[CKA.VALUE])
        self.cns_info.cert_valid = true
    elseif is_ds then
        
        
        obj = objCnsTmpl.GetDSCertTemplate(t.mt.get_certificate, ds_slot)
        local cert_fid = hex.hexify(hex.hexf('90%B', 16 + ds_slot))
        obj.path = self.ds_info.path_root .. cert_fid
        obj.num = ds_slot
        
        log.output('create_object_certificate(): ds certificate slot:', ds_slot, cert_fid)
        
        -- il FS DS potrebbe avere i certificati precreati e non cancellabili.
        local pcRes, finfo = pcall(function()
            log.output('create_object_certificate(): selecting:', obj.path)
            return self.cns_hcard:select(hexf(obj.path), true)
        end)
        if not pcRes or not (finfo and finfo.ac and string.byte(finfo.ac, 6) == 255) then
            -- crea il file del certificato
            log.output('create_object_certificate(): creating:', cert_fid)
            local pcRes, theErrorT = pcall(function()
                self:create_file( {
                size=string.len(pTemplate[CKA.VALUE]), 
                filetype=CnsSmartcard.fileTypes.Binary,
                parent=hexf(self.ds_info.path_root),
                fid=hexf(cert_fid), 
                aac={read=0, update=self.cns_hcard.BSO_CNS_PIN, delete=self.cns_hcard.BSO_CNS_PIN,},
                }, true, true)
                end)
            local _last_sw = self.cns_hcard.last_sw 
            if not pcRes and _last_sw ~= hexf('6982') and _last_sw ~= hexf('6a89')then
                error(theErrorT)
            end
        end
        
        local actual_cert_data = pTemplate[CKA.VALUE]
        if self.use_cpr_mode then
            local cpr = zlib.compresscer( pTemplate[CKA.VALUE])
            local decpr = cpr and zlib.decompresscer(cpr)
            if decpr == actual_cert_data then
                actual_cert_data = cpr
                pcall(function()
                log.output('create_object_certificate(): cpr ratio:', 
                    string.len(cpr)/string.len(pTemplate[CKA.VALUE]))
                end)
            else
                log.output('create_object_certificate(): compression failed!')
            end
        end
        self.cns_hcard:mupdate_binary(0, actual_cert_data)
        
        -- update index
        local oGroup = self.ds_info.ds_objects.o1024
        local index_base = 0
        if ds_slot >= table.getn(self.ds_info.ds_objects.o1024) then
            oGroup = self.ds_info.ds_objects.o2048
            index_base = table.getn(self.ds_info.ds_objects.o1024)
        end
        oGroup[ds_slot - index_base+1][3] = 1
        self:update_ds_index()
    else
        obj = objP11Tmpl.GetP11CertTemplate(t.mt.get_certificate_p11)
        local freeSlots = self:look_for_free_slots(1)
        if table.getn(freeSlots) == 0 then
            log.output('create_object_certificate(): no more space available')
            return CKR.DEVICE_MEMORY
        end
        obj.num = freeSlots[1]
        local cert_fid = self:buildP11Fid(obj.num, objTypes.eCert, attrTypes.eValue)
        obj.parent_path = '3F004FFF'
        obj.path = hex.hexify(hexf(obj.parent_path .. '%H',  cert_fid) )
        obj.isp11 = true
        
        local pTemplate_copy = utility.clone_table(pTemplate)
        for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
            if not pTemplate_copy[k] and obj[k] and type(obj[k]) == 'string' then
                pTemplate_copy[k] = obj[k]
            end
        end
        
        if parsed_cer then
            pTemplate_copy[CKA.SUBJECT] = pTemplate_copy[CKA.SUBJECT] or parsed_cer.subject
            pTemplate_copy[CKA.ISSUER] = pTemplate_copy[CKA.ISSUER] or parsed_cer.issuer
            pTemplate_copy[CKA.SERIAL_NUMBER] = pTemplate_copy[CKA.SERIAL_NUMBER] or parsed_cer.serialNumber
        end
        
        -- crea tutti gli attributi PKCS#11
        local fid_main = self:buildP11Fid(obj.num, objTypes.eCert, attrTypes.eMain)
        local fids_to_del = {}
        table.insert(fids_to_del, self:buildP11Fid(obj.num, objTypes.ePubKey, attrTypes.eMain))
        table.insert(fids_to_del, self:buildP11Fid(obj.num, objTypes.ePrivKey, attrTypes.eMain))
        table.insert(fids_to_del, self:buildP11Fid(obj.num, objTypes.eData, attrTypes.eMain))

        local cert_mainfile = self:cert_serialize_mainfile(pTemplate_copy, obj.num)
        self:create_p11_file(cert_mainfile, fid_main, false)
        for i, v in fids_to_del do
            pcall(function()
                self.cns_hcard:delete_file_athena(v, true)
            end)
        end
        local actual_cert_data = pTemplate[CKA.VALUE]
        if self.use_cpr_mode then
            local cpr = zlib.compresscer( pTemplate[CKA.VALUE])
            local decpr = cpr and zlib.decompresscer(cpr)
            if decpr == actual_cert_data then
                actual_cert_data = cpr
                pcall(function()
                log.output('create_object_certificate(): cpr ratio:', 
                    string.len(cpr)/string.len(pTemplate[CKA.VALUE]))
                end)
            else
                log.output('create_object_certificate(): compression failed!')
            end
        end
        self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eValue, actual_cert_data, true )
        self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eLabel, pTemplate_copy[CKA.LABEL], true )
        self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eID, pTemplate_copy[CKA.ID], true )
        self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eSubject, pTemplate_copy[CKA.SUBJECT], true )
        self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eIssuer, pTemplate_copy[CKA.ISSUER], true )
        self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eSN, pTemplate_copy[CKA.SERIAL_NUMBER], true )
        
        -- update objects list
        self.p11_info.obj_table[obj.num] = true
        self:write_p11_indexes()
        
    end

    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] and not t._is_private_attribute(k) then
            obj[k] = pTemplate[k]
        end
    end
    if parsed_cer then
        if not pTemplate[CKA.SUBJECT] then
            obj[CKA.SUBJECT] = parsed_cer.subject
        end
        if not pTemplate[CKA.ISSUER] then
            obj[CKA.ISSUER] = parsed_cer.issuer
        end
        if not pTemplate[CKA.SERIAL_NUMBER] then
            obj[CKA.SERIAL_NUMBER] = parsed_cer.serialNumber
        end
    end

    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    
    return CKR.OK, self.attributes.max_index
end


function t.mt:generate_key_pair(pMechanism, templatePub, templatePriv)

    if self.cns_only then
        log.output('generate_key_pair(): CNS only Token, cannot create objects')
        return CKR.TOKEN_WRITE_PROTECTED
    end
    
    log.output('generate_key_pair()', templatePub, templatePriv)
    if self.userType ~= CKU.USER then
        log.output('generate_key_pair(): not loggen in, userType', self.userType)
        return CKR.USER_NOT_LOGGED_IN
    end
    if utility.cache_can_use() and self.cfg["fastread"]=='true' then
        log.output('removing cache...')
        -- elimina tutta la cache statica del token
        local info = self:get_info()
        log.output('removing cache for serial', info.serialNumber)
        utility.cache_write(info.serialNumber)
    end

    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local objPriv, objPub

    local templatePub1 = utility.clone_table(templatePub)
    local templatePriv1 = utility.clone_table(templatePriv)
    
    templatePriv1[CKA.SIGN] = templatePriv1[CKA.SIGN] or eCK.BBOOL(true)
    templatePriv1[CKA.DECRYPT] = templatePriv1[CKA.DECRYPT] or eCK.BBOOL(true)
    
    if templatePub1[CKA.ID] then
        templatePriv1[CKA.ID] = templatePub1[CKA.ID]
    elseif templatePriv1[CKA.ID] then
        templatePub1[CKA.ID] = templatePriv1[CKA.ID]
    end
    local p11_bso_start_index
    local cka_modulus_bits = templatePub1[CKA.MODULUS_BITS] or templatePriv1[CKA.MODULUS_BITS] or eCK.ULONG(1024)
    local iscns = self:is_cns(templatePub1)
    local isds, ds_slot = self:is_ds(templatePub1, cka_modulus_bits, true)
    if isds and (not ds_slot or ds_slot == -1) then
        isds, ds_slot = self:is_ds(templatePriv1, cka_modulus_bits, true)
    end
    log.output(string.format('generate_key_pair(): isds:%s ds_slot:%s', tostring(isds), tostring(ds_slot)))
    
    if isds and (not ds_slot or ds_slot < 0) then
        log.output('generate_key_pair(): no DS slots available!')
        return CKR.DEVICE_MEMORY
    end
    
    local modulus_bits
    if not cka_modulus_bits or cka_modulus_bits == eCK.ULONG(1024) then
        modulus_bits = 1024
        p11_bso_start_index = tonumber('21', 16)
    elseif cka_modulus_bits == eCK.ULONG(2048) then
        modulus_bits = 2048
        p11_bso_start_index = tonumber('41', 16)
        if iscns then
            log.output('generate_key_pair(): key size invalid for selected filesystem:', hex.hexify(cka_modulus_bits) )
            return CKR.ATTRIBUTE_VALUE_INVALID
        end
        
        if not isds and (not self.p11_info or not self.support2048new) then
            log.output('generate_key_pair(): no P11 2048 FS available')
            return CKR.ATTRIBUTE_VALUE_INVALID
        end
    else
        log.output('generate_key_pair(): key size invalid:', hex.hexify(cka_modulus_bits) )
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    local freeId, freeSlot
    local pubTlv, pubTlvPath
    local modulus, pubexp
    
    if not (iscns or isds) and not self.p11_info then
        log.output('generate_key_pair(): unable to find a writable filesystem!')
        return CKR.FUNCTION_FAILED
    end
    
    self:invalidate_xproc_cache()
    
    if iscns then
        if self.cns_info.key_valid then
            log.output('generate_key_pair(): CNS Private Key already exists')
            return CKR.DEVICE_MEMORY
        end

        objPriv = objCnsTmpl.GetCNSPrivKeyTemplate(t.mt.get_public_key)
        objPriv.private = true
        objPriv.pso_dec = true
        objPriv.iscns = true
        objPriv.key_bits = modulus_bits
        objPriv.path = self.cns_info.cns_key_prefix .. objPriv.path
        objPriv.kid = 1
        
        objPub = objCnsTmpl.GetCNSPubKeyTemplate(t.mt.get_public_key)
        objPub.path = self.cns_info.cns_key_prefix .. objPub.path
        objPub.iscns = true
        objPub.key_bits = modulus_bits
        
        pubTlv = '3f01'
        self.cns_hcard:select(hexf(objPub.path))
        self.cns_hcard:generate_key_pair(objPriv.kid, hexf(pubTlv), 0 )
        
        modulus, pubexp =  self.cns_hcard:read_public_key(hexf(objPub.path))
        
    elseif isds then
        templatePriv1[CKA.DECRYPT] = eCK.BBOOL(false)
        
        objPriv = objCnsTmpl.GetDSPrivKeyTemplate(t.mt.get_public_key, ds_slot)
        objPriv.num = ds_slot
        objPriv.path = self.ds_info.ds_sig_path
        objPriv.kid = '1' .. ds_slot
        pubTlv = '801' .. ds_slot
        objPriv.pso_dec = false -- usa PSO_CDS per la firma e non supporta la decifra
        objPriv.related_public_key = self.ds_info.ds_sig_path .. pubTlv
        objPriv.key_bits = modulus_bits
        
        objPub = objCnsTmpl.GetDSPubKeyTemplate(t.mt.get_public_key, ds_slot)
        objPub.path = objPriv.related_public_key
        objPub.num = ds_slot
        objPub.key_bits = modulus_bits
        
        self.cns_hcard:select(hexf(objPub.path))

        -- ask PIN
        local contextual_pin = nil
        local res, cache_ds_pin
        log.output('generate_key_pair(): use_sm:', self.ds_info.use_sm)
        if self.ds_info.alw_verify_pin then
            if self.cfg["dspinusegui"] == 'true' and self.request_plugin_valid then
                if self.cached_ds_pin then
                    contextual_pin = self.cached_main_pin
                else
                    while true do
                        res, contextual_pin, cache_ds_pin = selg:gui_request_pin_ds(self.check_box_visible)
                        if res ~= 1 then
                            log.output('generate_key_pair(): cancelled by plugin with code:', res)
                            return CKR.FUNCTION_FAILED
                        end
                        result = self.cns_hcard:verify_pin_ds(contextual_pin, self.ds_info.sm_enc, self.ds_info.sm_sig)
                        if result == 0 and cache_ds_pin then self.cached_ds_pin = contextual_pin end
                        contextual_pin = nil
                        if t.show_pin_message(result, false) ~= 1 then
                            break
                        end
                    end
                    
                end
            elseif self.cfg["dspiniscnspin"]=='true' or self.cfg["dspinusegui"] == 'sign' then
                log.output('generate_key_pair(): using main pin as contextual pin...')
                contextual_pin = self.cached_main_pin
            else
                log.output('generate_key_pair(): requesting contextual login since ALWAYS_AUTHENTICATE is set...')
                return CKR.USER_NOT_LOGGED_IN
            end
        end
        
        if contextual_pin then
            result = self.cns_hcard:verify_pin_ds(contextual_pin, self.ds_info.sm_enc, self.ds_info.sm_sig)
            if result ~= 0 then
                log.output('generate_key_pair(): cached DS PIN verify failed:', result)
                return CKR.FUNCTION_FAILED
            end
        end
        
        -- self.cns_hcard.is_incard = true
        self:generate_key_pair_athena(objPriv.kid, objPriv.related_public_key, 0, self.ds_info.sm_enc, self.ds_info.sm_sig)
        
        local oGroup
        local index_base
        if modulus_bits == 1024 then
            oGroup = self.ds_info.ds_objects.o1024
            index_base=0
            
            modulus, pubexp = self.cns_hcard:read_public_key(hexf(objPub.path))
        else
            oGroup = self.ds_info.ds_objects.o2048
            index_base = table.getn(self.ds_info.ds_objects.o1024)
            
            self.cns_hcard:select(hexf(objPub.path))
            modulus = self.cns_hcard:mread_binary(0, 256)
            pubexp = self.cns_hcard:mread_binary(256, 8)
            while string.sub(pubexp, 1, 1) == '\000' do pubexp = string.sub(pubexp, 2, -1) end
        end
        
        -- update index
        oGroup[ds_slot - index_base+1][1] = 1
        oGroup[ds_slot - index_base+1][2] = 1
        self:update_ds_index()
    else
        if not self.p11_info then
            log.output('generate_key_pair(): no P11 FS available')
            return CKR.FUNCTION_FAILED
        end
        
        freeSlots = self:look_for_free_slots(2)
        freeBso = self:look_for_free_bso(modulus_bits>1024)
        if not freeSlots or table.getn(freeSlots) < 2 then
            log.output('generate_key_pair(): not enough objects id available')
            return CKR.DEVICE_MEMORY
        end
        if not freeBso then
            log.output('generate_key_pair(): no more BSO ids available')
            return CKR.DEVICE_MEMORY
        end

        objPriv = objP11Tmpl.GetP11PrivKeyTemplate(t.mt.get_privkey_p11)
        objPriv.path = '3F004FFF'
        objPriv.parent_path = objPriv.path
        objPriv.num = freeSlots[1]
        objPriv.kid = freeBso + p11_bso_start_index
        objPriv.private = true
        objPriv.pso_dec = true
        objPriv.isp11 = true
        objPriv.key_bits = modulus_bits
        
        objPub = objP11Tmpl.GetP11PubKeyTemplate(t.mt.get_pubkey_p11)
        objPub.num = freeSlots[2]
        local tlv_fid = self:buildP11Fid(objPub.num, objTypes.ePubKey, attrTypes.ePubKeyModExp)
        pubTlv = hex.hexify(hexf("%H", tlv_fid))
        objPub.parent_path = '3F004FFF'
        objPub.path = objPub.parent_path .. pubTlv
        objPub.isp11 = true
        objPub.key_bits = objPriv.key_bits
        
        for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
            if not templatePub1[k] and objPub[k] and type(objPub[k]) == 'string' then
                templatePub1[k] = objPub[k]
            end
            if not templatePub1[k] and objPriv[k] and type(objPriv[k]) == 'string' then
                templatePriv1[k] = objPriv[k]
            end
        end
        
        templatePriv1[CKA.LOCAL] = eCK.BBOOL(true)
        templatePub1[CKA.LOCAL] = eCK.BBOOL(true)
        
        if modulus_bits == 1024 then
            self:create_file( { size=128*2 + 32,
                                filetype=CnsSmartcard.fileTypes.RecordTLV,
                                parent=hexf(objPub.parent_path),
                                fid=tlv_fid,
                                asm={},
                                }, true, true )
        else
            self:create_file( { size=256+8,
                                filetype=CnsSmartcard.fileTypes.Binary,
                                parent=hexf(objPub.parent_path),
                                fid=tlv_fid,
                                asm={},
                                }, true, true )
        end
        
        self.cns_hcard:select(hexf(objPriv.path)) -- seleziona il parent del BSO
        self:create_rsa_bso(objPriv.kid, nil, modulus_bits, true)
        
        self:generate_key_pair_athena(objPriv.kid, objPub.path, 0)
        
        if modulus_bits == 1024 then
            modulus, pubexp = self.cns_hcard:read_public_key(hexf(objPub.path))
        else
            self.cns_hcard:select(hexf(objPub.path))
            modulus = self.cns_hcard:mread_binary(0, 256)
            pubexp = self.cns_hcard:mread_binary(256, 8)
            while string.sub(pubexp, 1, 1) == '\000' do pubexp = string.sub(pubexp, 2, -1) end
        end
        
        templatePub1[CKA.MODULUS] = modulus
        templatePub1[CKA.PUBLIC_EXPONENT] = pubexp
        templatePriv1[CKA.MODULUS] = modulus
        templatePriv1[CKA.PUBLIC_EXPONENT] = pubexp
        
        local fid_main_priv = self:buildP11Fid(objPriv.num, objTypes.ePrivKey, attrTypes.eMain)
        local fid_main_pub = self:buildP11Fid(objPub.num, objTypes.ePubKey, attrTypes.eMain)
        local privk_mainfile = self:privkey_serialize_mainfile(templatePriv1, objPriv.kid, objPriv.key_bits)
        local pubk_mainfile = self:pubkey_serialize_mainfile(templatePub1, objPub.num, objPub.key_bits)
        
        local fids_to_del = {}
        table.insert(fids_to_del, self:buildP11Fid(objPriv.num, objTypes.ePubKey, attrTypes.eMain))
        table.insert(fids_to_del, self:buildP11Fid(objPriv.num, objTypes.eCert, attrTypes.eMain))
        table.insert(fids_to_del, self:buildP11Fid(objPriv.num, objTypes.eData, attrTypes.eMain))
        table.insert(fids_to_del, self:buildP11Fid(objPub.num, objTypes.ePrivKey, attrTypes.eMain))
        table.insert(fids_to_del, self:buildP11Fid(objPub.num, objTypes.eCert, attrTypes.eMain))
        table.insert(fids_to_del, self:buildP11Fid(objPub.num, objTypes.eData, attrTypes.eMain))        

        self:create_p11_file(privk_mainfile, fid_main_priv, false)
        self:set_p11_attribute(objPriv.num, objTypes.ePrivKey, attrTypes.eLabel, templatePriv1[CKA.LABEL], false )
        self:set_p11_attribute(objPriv.num, objTypes.ePrivKey, attrTypes.eID, templatePriv1[CKA.ID], false )
        self:set_p11_attribute(objPriv.num, objTypes.ePrivKey, attrTypes.eModulus, modulus, false )
        self:set_p11_attribute(objPriv.num, objTypes.ePrivKey, attrTypes.ePubExp, pubexp, false )
        self:set_p11_attribute(objPriv.num, objTypes.ePrivKey, attrTypes.eSubject, templatePriv1[CKA.SUBJECT], false )
        
        self:create_p11_file(pubk_mainfile, fid_main_pub, true)
        self:set_p11_attribute(objPub.num, objTypes.ePubKey, attrTypes.eLabel, templatePub1[CKA.LABEL], true)
        self:set_p11_attribute(objPub.num, objTypes.ePubKey, attrTypes.eID, templatePub1[CKA.ID], true)
        self:set_p11_attribute(objPub.num, objTypes.ePubKey, attrTypes.eSubject, templatePriv1[CKA.SUBJECT], true )

        for i, v in fids_to_del do
            pcall(function()
                self.cns_hcard:delete_file_athena(v, true)
            end)
        end
        
        self.p11_info.obj_table[objPriv.num] = true
        self.p11_info.obj_table[objPub.num] = true
        if modulus_bits>1024 then
            self.p11_info.bso2048_table[freeBso] = true
        else
            self.p11_info.bso_table[freeBso] = true
        end
        self:write_p11_indexes()
    end

    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if templatePub1[k] and not t._is_private_attribute(k) then
            objPub[k] = templatePub1[k]
        end
        if templatePriv1[k] and not t._is_private_attribute(k) then
            objPriv[k] = templatePriv1[k]
        end
    end
    
    objPub[CKA.MODULUS_BITS] = eCK.ULONG(modulus_bits)
    objPub[CKA.MODULUS] = modulus
    objPub[CKA.PUBLIC_EXPONENT] = pubexp
    objPriv[CKA.MODULUS] = modulus
    objPriv[CKA.PUBLIC_EXPONENT] = pubexp
    objPriv[CKA.MODULUS_BITS] = eCK.ULONG(modulus_bits)
    
    -- adds new handles to the list
    local hPrivk, hPubk
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPriv
    hPrivk = self.attributes.max_index
    
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPub
    hPubk = self.attributes.max_index
    
    log.output('generate_key_pair(): success, returning', hPubk, hPrivk)
    self:update_free_mem(self.info)
    return CKR.OK, hPubk, hPrivk
end


function t.mt:create_object_data(pTemplate)
    log.output('create_object_data()', pTemplate)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    local ispdata = self:is_pdata(pTemplate)

    if ispdata and self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    
    if ispdata then
        if self.cns_info.pdata_valid then
            log.output('create_object_data(): CNS PDATA already exists')
            return CKR.DEVICE_MEMORY
        end
        local dataValue = pTemplate[CKA.VALUE] or '0\000'
        obj = objCnsTmpl.GetCNSPDATATemplate(t.mt.get_pdata)
        obj.iscns = true
        self.cns_hcard:select(hex.hexf(obj.path))
        self.cns_hcard:mupdate_binary(0, dataValue)
        obj[CKA.VALUE] = pTemplate[CKA.VALUE]
        self.cns_info.pdata_valid = true
    else
        local freeSlots = self:look_for_free_slots(1)
        if not freeSlots or table.getn(freeSlots) == 0 then
            log.output('create_object_data(): not enough objects id available')
            return CKR.DEVICE_MEMORY
        end

        obj = objP11Tmpl.GetP11DataTemplate(t.mt.get_data_p11)
        local pTemplate_copy = utility.clone_table(pTemplate)
        for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
            if not pTemplate_copy[k] and obj[k] and type(obj[k]) == 'string' then
                pTemplate_copy[k] = obj[k]
            end
        end
        obj.num = freeSlots[1]
        obj.private = (pTemplate_copy[CKA.PRIVATE] == eCK.BBOOL(true))
        obj.isp11=true
        obj.parent_path = '3F004FFF'
        
        local fid_main = self:buildP11Fid(obj.num, objTypes.eData, attrTypes.eMain)
        local fids_to_del = {}
        table.insert(fids_to_del, self:buildP11Fid(obj.num, objTypes.ePubKey, attrTypes.eMain))
        table.insert(fids_to_del, self:buildP11Fid(obj.num, objTypes.eCert, attrTypes.eMain))
        table.insert(fids_to_del, self:buildP11Fid(obj.num, objTypes.ePrivKey, attrTypes.eMain))
        local data_mainfile = self:data_serialize_mainfile(pTemplate_copy, obj.kid)
        for i, v in fids_to_del do
            pcall(function()
                self.cns_hcard:delete_file_athena(v, true)
            end)
        end               
        self:create_p11_file(data_mainfile, fid_main, not obj.private)
        self:set_p11_attribute(obj.num, objTypes.eData, attrTypes.eLabel, pTemplate_copy[CKA.LABEL], not obj.private )
        self:set_p11_attribute(obj.num, objTypes.eData, attrTypes.eApplication, pTemplate_copy[CKA.APPLICATION], not obj.private )
        self:set_p11_attribute(obj.num, objTypes.eData, attrTypes.eObjectId, pTemplate_copy[CKA.OBJECT_ID], not obj.private )
        self:set_p11_attribute(obj.num, objTypes.eData, attrTypes.eValue, pTemplate_copy[CKA.VALUE], not obj.private, obj.private )
        
        self.p11_info.obj_table[obj.num] = true
        self:write_p11_indexes()

    end
    
        for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
            if pTemplate[k] and not t._is_private_attribute(k) then
                obj[k] = pTemplate[k]
            end
        end
        
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    return CKR.OK, self.attributes.max_index
end


function t.mt:create_object(pTemplate)

    local rv, hObj
    if self.cns_only then
        log.output('create_object(): CNS only Token, cannot create objects')
        return CKR.TOKEN_WRITE_PROTECTED
    end

    if utility.cache_can_use() and self.cfg["fastread"]=='true' then
        log.output('removing cache...')
        -- elimina tutta la cache statica del token
        local info = self:get_info()
        log.output('removing cache for serial', info.serialNumber)
        utility.cache_write(info.serialNumber)
    end
    
    log.output('create_object(): verify_pin_cns() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.cns_hcard:verify_pin_cns(self.cached_main_pin, false, true)
    end
    local info = self:get_info()
    local iscns = self:is_cns(pTemplate)
    local is_ds = self:is_ds(pTemplate)
    if not (iscns or is_ds) and not self.p11_info then
        log.output('create_object(): unable to find a writable filesystem!')
        return CKR.FUNCTION_FAILED
    end
    
    self:invalidate_xproc_cache()
    
    if pTemplate[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        rv, hObj = self:create_object_pubkey(pTemplate)
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        rv, hObj =  self:create_object_privkey(pTemplate)
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        rv, hObj =  self:create_object_certificate(pTemplate)
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        rv, hObj =  self:create_object_data(pTemplate)        
        
    else
        log.output('create_object(): unsupported object class:', hex.hexify(pTemplate[CKA.CLASS] or ''))
        rv =  CKR.ATTRIBUTE_VALUE_INVALID
    end
    if rv == CRK_OK then
        self:update_free_mem(self.info)
    end
    return rv, hObj
end

function t.mt:destroy_object(hObject)
    if self.cns_only then
        log.output('destroy_object(): CNS only Token, cannot destroy objects')
        return CKR.TOKEN_WRITE_PROTECTED
    end

    log.output('destroy_object(): ', hObject)

    log.output('destroy_object(): verify_pin_cns() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.cns_hcard:verify_pin_cns(self.cached_main_pin, false, true)
    end

    if self.userType ~= CKU.USER then
        --return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        log.output('destroy_object(): WARNING: user not logged in!')
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hObject]

    if utility.cache_can_use() and self.cfg["fastread"]=='true' then
        log.output('removing cache...')
        -- elimina tutta la cache statica del token
        local info = self:get_info()
        log.output('removing cache for serial', info.serialNumber)
        utility.cache_write(info.serialNumber)
    end   
    
    if not obj then
        log.output('destroy_object(): invalid handle!')
        return CKR.OBJECT_HANDLE_INVALID
    end
    local files_delete={}
    local bso_delete={}
    
    self:get_attribute_value(hObject, CKA.LABEL)
    
    self:invalidate_xproc_cache()
        
    if obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        log.output('destroy_object(): CERTIFICATE')
        if obj.iscns then
            log.output('destroy_object(): CNS CERTIFICATE')
            local pcRes, theErrorT = pcall(function()
                self.cns_hcard:select(hexf(obj.path) )
                self.cns_hcard:update_binary(0, string.rep('\000', 16) )
                self.cns_info.cert_valid=false
            end)
            
        elseif obj.isp11 then
            log.output('destroy_object(): P11 CERTIFICATE')
            local the_attributes = {attrTypes.eMain, attrTypes.eValue, attrTypes.eLabel, attrTypes.eID, attrTypes.eSubject, attrTypes.eIssuer, attrTypes.eSN, }
            for i, k in the_attributes do
                table.insert(files_delete, {path=hexf('4fff'), fid=hexf('%H', self:buildP11Fid(obj.num, objTypes.eCert, k) ) } )
            end
            self.p11_info.obj_table[obj.num] = false
            self:write_p11_indexes()
        else
            log.output('destroy_object(): DS CERTIFICATE')
            table.insert(files_delete, {path=hexf(obj.path), fid=string.sub(hexf(obj.path), -2, -1) } )
            local oGroup = self.ds_info.ds_objects.o1024
            local index_base = 0
            if obj.num >= table.getn(self.ds_info.ds_objects.o1024) then
                oGroup = self.ds_info.ds_objects.o2048
                index_base = table.getn(self.ds_info.ds_objects.o1024)
            end
            oGroup[obj.num - index_base+1][3] = 0
            self:update_ds_index()

        end
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        log.output('destroy_object(): PUBLIC_KEY')
        if obj.iscns then
            log.output('destroy_object(): CNS PUBLIC_KEY: nothing to do')
            -- 