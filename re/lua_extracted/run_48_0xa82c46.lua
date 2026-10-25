 necessario ricrearlo.
        if not bRes2 and self.cns_hcard.last_sw == hexf('6982') then
            log.output(
                string.format('create_rsa_bso(): unable to delete BSO %x, wrong BSO ACs, skipping BSO creation... ', kid)
                )
        else
            self.cns_hcard:create_rsa_bso(bso_info)
        end
    end
    
    if pTemplate then
        if key_bits == 1024 and pTemplate[CKA.MODULUS] and privExp then
            self.cns_hcard:change_rsa_bso(kid, pTemplate[CKA.MODULUS], privExp)
        elseif key_bits == 2048 and pTemplate[CKA.MODULUS] and pubExp and exp1 and exp2 and ctx then
            if self.jsign3plus then
                log.output('create_rsa_bso(): jsign3/4: key imported on creation')
            elseif self.jsign_2048 then
                self.cns_hcard:change_rsa_crt_extended(kid, p, q, ctx, exp1, exp2, pubExp)
            else
                self.cns_hcard:change_rsa_crt(kid, p, q, ctx, exp1, exp2, pubExp)
            end
        end
    end
end


function t.mt:create_object_privkey(pTemplate, as_local)
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
        p11_bso_start_index = self.p11_bso_start_index_1024
    elseif modulus_bits == 2048 then
        p11_bso_start_index = self.p11_bso_start_index_2048
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
        obj.path = self.p11_info.path_root
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
        pTemplate_copy[CKA.LOCAL] = eCK.BBOOL(as_local)
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
        
        if self.p11_info.version_major >= 2 then
            local privk_mainfile = t.serialize_attr_p11v2_privkey(pTemplate_copy, obj.kid, obj.key_bits)
            self:create_p11_file(privk_mainfile, fid_main, true)
        else

            local privk_mainfile = self:privkey_serialize_mainfile(pTemplate_copy, obj.kid, obj.key_bits)
            self:create_p11_file(privk_mainfile, fid_main, false)
            for i, v in fids_to_del do
                pcall(function()
                    self.cns_hcard:delete_file(v, true)
                end)
            end
            self:set_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.eLabel, pTemplate_copy[CKA.LABEL], false )
            self:set_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.eID, pTemplate_copy[CKA.ID], false )
            self:set_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.eModulus, pTemplate_copy[CKA.MODULUS], false )
            self:set_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.ePubExp, pTemplate_copy[CKA.PUBLIC_EXPONENT], false )
            self:set_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.eSubject, pTemplate_copy[CKA.SUBJECT], false )
        end
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
    local ds_index = self.ds_info.path_root .. self.ds_info.ds_index
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
            local cpr, decpr
            if self.use_cpr_mode2 then
                cpr = zlib.compresscer2( pTemplate[CKA.VALUE])
                decpr = cpr and zlib.decompresscer2(cpr)
            else
                cpr = zlib.compresscer( pTemplate[CKA.VALUE])
                decpr = cpr and zlib.decompresscer(cpr)
            end
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
        obj.parent_path = self.p11_info.path_root
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

        local actual_cert_data = pTemplate[CKA.VALUE]
        if self.use_cpr_mode then
            local cpr, decpr
            if self.use_cpr_mode2 then
                cpr = zlib.compresscer2( pTemplate[CKA.VALUE])
                decpr = cpr and zlib.decompresscer2(cpr)
            else
                cpr = zlib.compresscer( pTemplate[CKA.VALUE])
                decpr = cpr and zlib.decompresscer(cpr)
            end
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
        
        if self.p11_info.version_major >= 2 then
            local cert_mainfile = t.serialize_attr_p11v2_cert(pTemplate_copy, obj.num)
            self:create_p11_file(cert_mainfile, fid_main, true)
            self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eValue, actual_cert_data, true )
        else
            local cert_mainfile = self:cert_serialize_mainfile(pTemplate_copy, obj.num)
            self:create_p11_file(cert_mainfile, fid_main, true)
            for i, v in fids_to_del do
                pcall(function()
                    self.cns_hcard:delete_file(v, true)
                end)
            end
            self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eValue, actual_cert_data, true )
            self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eLabel, pTemplate_copy[CKA.LABEL], true )
            self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eID, pTemplate_copy[CKA.ID], true )
            self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eSubject, pTemplate_copy[CKA.SUBJECT], true )
            self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eIssuer, pTemplate_copy[CKA.ISSUER], true )
            self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eSN, pTemplate_copy[CKA.SERIAL_NUMBER], true )
        end
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

function t.mt:auto_verify_pin_main(pMechanism, templatePub, templatePriv)
    log.output('auto_verify_pin_main(): verify_pin_cns() cached pin, with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        log.output('auto_verify_pin_main(): verifying cached pin...')
        local res = -1
        if self.check_pin_status then
            res = self.cns_hcard:verify_pin_cns("", false, true)
        end
        if res ~= 0 then
            self.cns_hcard:verify_pin_cns(self.cached_main_pin, false, false)
        end
    end
end

function t.mt:generate_key_pair(pMechanism, templatePub, templatePriv)

    local keygenmaxtryonlow = self.keygenmaxtryonlow1024
    if self.cns_only then
        log.output('generate_key_pair(): CNS only Token, cannot create objects')
        return CKR.TOKEN_WRITE_PROTECTED
    end
    
    log.output('generate_key_pair()', templatePub, templatePriv)
    if self.userType ~= CKU.USER then
        log.output('generate_key_pair(): not loggen in, userType', self.userType)
        return CKR.USER_NOT_LOGGED_IN
    end
    
    self:check_clear_cache(nil, true, true)
    
    -- if self:cache_enabled() then
        -- log.output('removing cache...')
        -- elimina tutta la cache statica del token
        -- local info = self:get_info()
        -- log.output('removing cache for serial', info.serialNumber)
        -- utility.cache_write(info.serialNumber, nil, nil, self._umcachepath)
    -- end

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
    
    if pMechanism and pMechanism.mechanism == CKM.EC_KEY_PAIR_GEN then
        
        if not self.mechanisms[CKM.EC_KEY_PAIR_GEN] then
            log.output('generate_key_pair(): ECDSA curves not supported by the card!')
            return CKR.MECHANISM_INVALID
        end
        
        self:auto_verify_pin_main()
        return self:generate_dsx_ecdsa_key_pair(pMechanism, templatePub, templatePriv)
    end
    
    if self:is_dsx(templatePub1) then
        self:auto_verify_pin_main()
        return self:generate_dsx_rsa_key_pair(pMechanism, templatePub, templatePriv)
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
    
    self:auto_verify_pin_main()
    
    local modulus_bits
    if not cka_modulus_bits or cka_modulus_bits == eCK.ULONG(1024) then
        modulus_bits = 1024
        p11_bso_start_index = self.p11_bso_start_index_1024
    elseif cka_modulus_bits == eCK.ULONG(2048) then
        modulus_bits = 2048
        keygenmaxtryonlow = self.keygenmaxtryonlow2048
        p11_bso_start_index = self.p11_bso_start_index_2048
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
    local freeSlots
    local freeBso

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
        
        for retry=1,keygenmaxtryonlow do
            
            log.output('generate_key_pair(): CNS: retry=', retry, "/", keygenmaxtryonlow)
            
            self.cns_hcard:select(hexf(objPub.path))
            self.cns_hcard:generate_key_pair(objPriv.kid, hexf(pubTlv), 0 )
            
            modulus, pubexp =  self.cns_hcard:read_public_key(hexf(objPub.path))
            log.output('generate_key_pair(): CNS: modulus[0]=', string.byte(modulus, 1))
            
            if string.byte(modulus, 1) > 128 then
                break
            else
                log.output('generate_key_pair(): CNS: key pair low!')
            end
        end
        if string.byte(modulus, 1) < 128 and self.keygenerroronlow then
            log.output('generate_key_pair(): CNS: key pair low, returning error')
            return CKR.FUNCTION_FAILED
        end


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
                    contextual_pin = self.cached_ds_pin
                else
                    while true do
                        res, contextual_pin, cache_ds_pin = self:gui_request_pin_ds(self.check_box_visible)
                        if res ~= 1 then
                            log.output('generate_key_pair(): cancelled by plugin with code:', res)
                            return CKR.FUNCTION_FAILED
                        end
                        self.cns_hcard:select(hexf(self.ds_info.ds_sig_path))
                        result = self.cns_hcard:verify_pin_ds(contextual_pin, self.ds_info.sm_enc, self.ds_info.sm_sig)
                        if result == 0 and cache_ds_pin then self.cached_ds_pin = contextual_pin end
                        contextual_pin = nil
                        if self:gui_show_pin_message(result, false) ~= 1 then
                            break
                        end
                    end
                    
                end
            elseif self.cfg["dspiniscnspin"]=='true' or self.cfg["dspiniscnspin"]=='sign' then
                log.output('generate_key_pair(): using main pin as contextual pin...')
                contextual_pin = self.cached_main_pin
            else
                log.output('generate_key_pair(): requesting contextual login since ALWAYS_AUTHENTICATE is set...')
                return CKR.USER_NOT_LOGGED_IN
            end
        end
        
        local oGroup
        local index_base
        for retry=1,keygenmaxtryonlow do
        
            log.output('generate_key_pair(): DS: retry=', retry, "/", keygenmaxtryonlow)
            

            self.cns_hcard.is_incard = true

            if contextual_pin then
                self.cns_hcard:select(hexf(self.ds_info.ds_sig_path))
                result = self.cns_hcard:verify_pin_ds(contextual_pin, self.ds_info.sm_enc, self.ds_info.sm_sig)
                if result ~= 0 then
                    log.output('generate_key_pair(): cached DS PIN verify failed:', result)
                    return CKR.FUNCTION_FAILED
                end
            end
            self.cns_hcard:generate_key_pair(objPriv.kid, hexf(pubTlv), 0 )

            
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
            
            log.output('generate_key_pair(): DS: modulus[0]=', string.byte(modulus, 1))
            
            if string.byte(modulus, 1) > 128 then
                break
            else
                log.output('generate_key_pair(): DS: key pair low, retry=', retry)
            end
        end
        if string.byte(modulus, 1) < 128 and self.keygenerroronlow then
            log.output('generate_key_pair(): DS: key pair low, returning error')
            return CKR.FUNCTION_FAILED
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
        objPriv.path = self.p11_info.path_root
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
        objPub.parent_path = self.p11_info.path_root
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
            self:create_file( { size=256+8 + (self.jsign_2048 and 8 or 0),
                                filetype=CnsSmartcard.fileTypes.Binary,
                                parent=hexf(objPub.parent_path),
                                fid=tlv_fid,
                                asm={},
                                }, true, true )
        end
        
        self.cns_hcard:select(hexf(objPriv.path)) -- seleziona il parent del BSO
        self:create_rsa_bso(objPriv.kid, nil, modulus_bits, true)
        
        for retry=1,keygenmaxtryonlow do
            log.output('generate_key_pair(): P11: retry=', retry, "/", keygenmaxtryonlow)
            
            self.cns_hcard:generate_key_pair(objPriv.kid, hexf(pubTlv), 0)
            
            if modulus_bits == 1024 then
                modulus, pubexp = self.cns_hcard:read_public_key(hexf(objPub.path))
            else
                self.cns_hcard:select(hexf(objPub.path))
                modulus = self.cns_hcard:mread_binary(0, 256)
                pubexp = self.cns_hcard:mread_binary(256, 8)
                while string.sub(pubexp, 1, 1) == '\000' do pubexp = string.sub(pubexp, 2, -1) end
            end
            
            log.output('generate_key_pair(): P11: modulus[0]=', string.byte(modulus, 1))
            
            if string.byte(modulus, 1) > 128 then
                break
            else
                log.output('generate_key_pair(): P11: key pair low, retry=', retry)
            end
        end
        if string.byte(modulus, 1) < 128 and self.keygenerroronlow then
            log.output('generate_key_pair(): P11: key pair low, returning error')
            return CKR.FUNCTION_FAILED
        end
        
        templatePub1[CKA.MODULUS] = modulus
        templatePub1[CKA.PUBLIC_EXPONENT] = pubexp
        templatePriv1[CKA.MODULUS] = modulus
        templatePriv1[CKA.PUBLIC_EXPONENT] = pubexp
        
        local fid_main_priv = self:buildP11Fid(objPriv.num, objTypes.ePrivKey, attrTypes.eMain)
        local fid_main_pub = self:buildP11Fid(objPub.num, objTypes.ePubKey, attrTypes.eMain)
        local fids_to_del = {}
        table.insert(fids_to_del, self:buildP11Fid(objPriv.num, objTypes.ePubKey, attrTypes.eMain))
        table.insert(fids_to_del, self:buildP11Fid(objPriv.num, objTypes.eCert, attrTypes.eMain))
        table.insert(fids_to_del, self:buildP11Fid(objPriv.num, objTypes.eData, attrTypes.eMain))
        table.insert(fids_to_del, self:buildP11Fid(objPub.num, objTypes.ePrivKey, attrTypes.eMain))
        table.insert(fids_to_del, self:buildP11Fid(objPub.num, objTypes.eCert, attrTypes.eMain))
        table.insert(fids_to_del, self:buildP11Fid(objPub.num, objTypes.eData, attrTypes.eMain))        
        
        
        if self.p11_info.version_major >= 2 then
            local privk_mainfile = t.serialize_attr_p11v2_privkey(templatePriv1, objPriv.kid, objPriv.key_bits)
            self:create_p11_file(privk_mainfile, fid_main_priv, true)
            local pubk_mainfile = t.serialize_attr_p11v2_pubkey(templatePub1, objPub.num, objPub.key_bits)
            self:create_p11_file(pubk_mainfile, fid_main_pub, true)
        else
            local privk_mainfile = self:privkey_serialize_mainfile(templatePriv1, objPriv.kid, objPriv.key_bits)
            local pubk_mainfile = self:pubkey_serialize_mainfile(templatePub1, objPub.num, objPub.key_bits)

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
        end
        
        for i, v in fids_to_del do
            pcall(function()
                self.cns_hcard:delete_file(v, true)
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
    self:update_free_mem(self.info, true)
    self:update_cache_id()
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
    
    -- self:check_clear_cache(nil, true, true)

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
        obj.parent_path = self.p11_info.path_root
        
        local fid_main = self:buildP11Fid(obj.num, objTypes.eData, attrTypes.eMain)
        local fids_to_del = {}
        table.insert(fids_to_del, self:buildP11Fid(obj.num, objTypes.ePubKey, attrTypes.eMain))
        table.insert(fids_to_del, self:buildP11Fid(obj.num, objTypes.eCert, attrTypes.eMain))
        table.insert(fids_to_del, self:buildP11Fid(obj.num, objTypes.ePrivKey, attrTypes.eMain))
        
        if self.p11_info.version_major >= 2 then
            local data_mainfile = t.serialize_attr_p11v2_data(pTemplate_copy)
            self:create_p11_file(data_mainfile, fid_main, true)        
            self:set_p11_attribute(obj.num, objTypes.eData, attrTypes.eValue, pTemplate_copy[CKA.VALUE], not obj.private, obj.private )
        else
            local data_mainfile = self:data_serialize_mainfile(pTemplate_copy)
            for i, v in fids_to_del do
                pcall(function()
                    self.cns_hcard:delete_file(v, true)
                end)
            end
            self:create_p11_file(data_mainfile, fid_main, not obj.private)
            self:set_p11_attribute(obj.num, objTypes.eData, attrTypes.eLabel, pTemplate_copy[CKA.LABEL], not obj.private )
            self:set_p11_attribute(obj.num, objTypes.eData, attrTypes.eApplication, pTemplate_copy[CKA.APPLICATION], not obj.private )
            self:set_p11_attribute(obj.num, objTypes.eData, attrTypes.eObjectId, pTemplate_copy[CKA.OBJECT_ID], not obj.private )
            self:set_p11_attribute(obj.num, objTypes.eData, attrTypes.eValue, pTemplate_copy[CKA.VALUE], not obj.private, obj.private )
        end
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

    if self.cns_only then
        log.output('create_object(): CNS only Token, cannot create objects')
        return CKR.TOKEN_WRITE_PROTECTED
    end

    self:check_clear_cache(nil, true, true)

    -- if self:cache_enabled() then
        -- log.output('removing cache...')
        -- elimina tutta la cache statica del token
        -- local info = self:get_info()
        -- log.output('removing cache for serial', info.serialNumber)
        -- utility.cache_write(info.serialNumber, nil, nil, self._umcachepath)
    -- end
    
    self:auto_verify_pin_main()

    local iscns = self:is_cns(pTemplate)
    local is_ds = self:is_ds(pTemplate)
    if not (iscns or is_ds) and not self.p11_info then
        log.output('create_object(): unable to find a writable filesystem!')
        return CKR.FUNCTION_FAILED
    end
    
    local rv, hObj
    
    self:invalidate_xproc_cache()
    
    if pTemplate[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
    
        if pTemplate[CKA.KEY_TYPE] == eCK.ULONG(CKK.ECDSA) then
            rv, hObj = self:create_object_dsx_ecdsa_public_key(pTemplate)
        else
            if self:is_dsx(pTemplate) then
                log.output('create_object(): cannot create DSX PUBLIC_KEY!')
                return CKR.ATTRIBUTE_VALUE_INVALID
            end
        
            rv, hObj = self:create_object_pubkey(pTemplate)
        end
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        
        if pTemplate[CKA.KEY_TYPE] == eCK.ULONG(CKK.ECDSA) then
            if not self.mechanisms[CKM.EC_KEY_PAIR_GEN] then
                log.output('create_object(): ECDSA not supported!')
                return CKR.ATTRIBUTE_VALUE_INVALID
            end
            rv, hObj = self:create_object_dsx_ecdsa_private_key(pTemplate)
        else
            if self:is_dsx(pTemplate) then
                log.output('create_object(): cannot create RSA DSX PRIVATE_KEY!')
                return CKR.ATTRIBUTE_VALUE_INVALID
            end
            
            rv, hObj = self:create_object_privkey(pTemplate)
        end
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        
        local parsed_cer
        pcall(function()
            parsed_cer = der.parse_x509cer(pTemplate[CKA.VALUE])
        end)
        
        local is_ecc = not not( parsed_cer and parsed_cer.eccPoint)
        log.output('create_object(): is_ecc CERTIFICATE:', is_ecc)
        
        if is_ecc or self:is_dsx(pTemplate) then
            rv, hObj = self:create_object_dsx_certificate(pTemplate)
        else
            rv, hObj = self:create_object_certificate(pTemplate)
        end
    
        
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        rv, hObj = self:create_object_data(pTemplate)
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO_PIN_POLICY) then
        rv, hObj = self:create_object_pin_policy(pTemplate)
        
    else
        log.output('create_object(): unsupported object class:', hex.hexify(pTemplate[CKA.CLASS] or ''))
        rv = CKR.ATTRIBUTE_VALUE_INVALID
    end
    if rv == CKR.OK then
        self:update_cache_id()
        self:update_free_mem(self.info, true)
    end
    return rv, hObj

end

function t.mt:destroy_object(hObject)
    if self.cns_only then
        log.output('destroy_object(): CNS only Token, cannot destroy objects')
        return CKR.TOKEN_WRITE_PROTECTED
    end

    log.output('destroy_object(): ', hObject)

    self:auto_verify_pin_main()
    
    if self.userType ~= CKU.USER then
        --return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        log.output('destroy_object(): WARNING: user not logged in!')
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hObject]

    self:check_clear_cache(nil, true, true)
    -- if self:cache_enabled() then
        -- log.output('removing cache...')
        -- elimina tutta la cache statica del token
        -- local info = self:get_info()
        -- log.output('removing cache for serial', info.serialNumber)
        -- utility.cache_write(info.serialNumber, nil, nil, self._umcachepath)
    -- end   
    
    if not obj then
        log.output('destroy_object(): invalid handle!')
        return CKR.OBJECT_HANDLE_INVALID
    end
    local files_delete={}
    
    if obj.dsx then
        return self:destroy_object_dsx(hObject)
    end
    
    self:get_attribute_value(hObject, CKA.LABEL)
    
    if self.cfg["dsdisabledestroy"] == "true" and not obj.isp11 and not obj.iscns then
        log.output('destroy_object(): DS object destroy disabled')
        return CKR.TOKEN_WRITE_PROTECTED
    end
    
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
                table.insert(files_delete, {path=hexf(self.p11_info.path_root), fid=hexf('%H', self:buildP11Fid(obj.num, objTypes.eCert, k) ) } )
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