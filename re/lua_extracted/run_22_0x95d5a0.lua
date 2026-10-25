
    log.output('_search_related_key_object(): looking for existing related object...')
    local hObj
    local find_state = {}
    local pTemplateSearchRSA = {
        [CKA.MODULUS]=modulus,
        [CKA.PUBLIC_EXPONENT]=pubExp,
        [CKA.CLASS]=class,
    }
    local pTemplateSearchECC = {
        [CKA.EC_POINT]=modulus,
        [CKA.CLASS]=class,
    }
    local pTemplateSearch = pTemplateSearchRSA
    if modulus and not pubExp then
        pTemplateSearch = pTemplateSearchECC
    end
    hObj = self:get_item(find_state, true, pTemplateSearch) -- can return private objects
    if hObj ~= 0 then
        log.output('_search_related_key_object(): existing related object found:', hObj)
        return hObj
    end
    return nil
end

function t.mt:create_object_privkey(pTemplateOrig)
    log.output('token-nxp-chipdoc:create_object_privkey()', pTemplateOrig)
    
    local pTemplate = utility.clone_table(pTemplateOrig)
    pTemplate[CKA.LOCAL] = eCK.BBOOL(false)
    
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    if not pTemplate[CKA.MODULUS]
        or not pTemplate[CKA.PUBLIC_EXPONENT] 
        -- or not pTemplate[CKA.PRIVATE_EXPONENT] -- non usato
        or not pTemplate[CKA.PRIME_1]
        or not pTemplate[CKA.PRIME_2]
        or not pTemplate[CKA.EXPONENT_1]
        or not pTemplate[CKA.EXPONENT_2]
        or not pTemplate[CKA.COEFFICIENT]
        then
            log.output('token-nxp-chipdoc:create_object_privkey(): all Private Key components must be specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local modulus_bits = string.len(pTemplate[CKA.MODULUS]) * 8
    if not (modulus_bits == 1024 or modulus_bits == 2048 
            or (self._supports_4096 and modulus_bits == 4096) 
            or (self._supports_3072 and modulus_bits == 3072)) then
        log.output('token-nxp-chipdoc:create_object_privkey(): MODULUS size invalid:', modulus_bits)
        return CKR.ATTRIBUTE_VALUE_INVALID
    end

    local keyReference
    
    self:invalidate_xproc_cache()
    self.nxp_hcard:auto_perform_mutual_authenticate()
    
    local isDS = self:is_ds(pTemplate) 
    if isDS then
        log.output('token-nxp-chipdoc:create_object_privkey(): cannot import DS private keys!')
        return CKR.TEMPLATE_INCONSISTENT
    end
    
    -- access control
    pTemplate[CKA.LOCAL] = eCK.BBOOL(false)
    pTemplate[CKA.SENSITIVE] = eCK.BBOOL(true)
    pTemplate[CKA.ALWAYS_SENSITIVE] = eCK.BBOOL(true)
    pTemplate[CKA.NEVER_EXTRACTABLE] = eCK.BBOOL(true)
    pTemplate[CKA.EXTRACTABLE] = eCK.BBOOL(false)
    
    -- key usage
    pTemplate[CKA.SIGN] = eCK.BBOOL(true) -- overrides, the key can at least sign
    pTemplate[CKA.DECRYPT] = pTemplate[CKA.DECRYPT] or eCK.BBOOL(true)
    
    pTemplate[CKA.CLASS] = eCK.ULONG(CKO.PRIVATE_KEY)
    pTemplate[CKA.KEY_TYPE] = eCK.ULONG(CKK.RSA)
    
    pTemplate[CKA.VERIFY] = eCK.BBOOL(false)
    pTemplate[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    pTemplate[CKA.WRAP] = eCK.BBOOL(false)
    pTemplate[CKA.ENCRYPT] = eCK.BBOOL(false)
    pTemplate[CKA.DERIVE] = eCK.BBOOL(false)
    
    pTemplate[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)

    log.output('token-nxp-chipdoc:create_object_privkey(): searching if a public key sharing same modulus exists...')
    local hObj = self:_search_related_key_object(
        pTemplate[CKA.MODULUS],
        pTemplate[CKA.PUBLIC_EXPONENT],
        eCK.ULONG(CKO.PUBLIC_KEY) )
    if hObj then
        local objPub = self.attributes[hObj]
        if objPub.aid == NXPIASSmartCard.Generic_AID then
            keyReference = objPub.kid
            log.output('token-nxp-chipdoc:create_object_privkey(): found related key keyReference:', keyReference)
        end
    end
    
    if not keyReference then
        log.output('token-nxp-chipdoc:create_object_privkey(): allocating a keyReference for private key')
        keyReference = self:virtual_alloc_kid(self._indexes._private_keys_bin, self._indexes._public_keys_bin, false)
        if not keyReference  then
            log.output('token-nxp-chipdoc:create_object_privkey(): no more keyReference left')
            return CKR.DEVICE_MEMORY
        end
    end
    
    local authId = self.authID_Card_PIN
    local kdPriv, objNum = self:virtual_add_private_key_object(
        self._indexes._private_keys_bin,
        pTemplate[CKA.LABEL] or '',
        pTemplate[CKA.ID] or '',
        authId, keyReference, modulus_bits, false,
        pTemplate
        )
        
    if string.len(kdPriv) ~= string.len(self._indexes._private_keys_bin) then
        log.output('token-nxp-chipdoc:create_object_privkey(): no more space left in Private KD file!')
        return CKR.DEVICE_MEMORY
    end

    obj = GetPrivKeyTemplate(t.mt.get_privkey)
    obj.private = true
    obj.key_bits = modulus_bits
    obj.kid = keyReference
    obj.num = objNum
    log.output(string.format("token-nxp-chipdoc:create_object_privkey(): new obj num:%d kid:%d bits:%d", 
        obj.num, obj.kid, obj.key_bits) )

    self.nxp_hcard:select_MF()
    local info = self:get_info()
    self.nxp_hcard:select_Generic()
    
    log.output('token-nxp-chipdoc:create_object_privkey(): AUTH OBJ: erasing SDOs...')
    self.nxp_hcard:delete_SDO(NXPIASSmartCard.object_classes.RSA_PUB_KEY, keyReference, true)
    self.nxp_hcard:delete_SDO(NXPIASSmartCard.object_classes.RSA_PRIV_KEY, keyReference, true)
    
    local acsPubk, acsPrivk = self:get_keys_acs(true)
    log.output('token-nxp-chipdoc:create_object_privkey(): AUTH OBJ: creating SDOs...')
    self.nxp_hcard:create_RSA_SDO_for_keygen(NXPIASSmartCard.object_classes.RSA_PRIV_KEY, keyReference, obj.key_bits, acsPrivk, true)
    self.nxp_hcard:create_RSA_SDO_for_keygen(NXPIASSmartCard.object_classes.RSA_PUB_KEY, keyReference, obj.key_bits, acsPubk, true)
    
    log.output('token-nxp-chipdoc:create_object_privkey(): importing key components...')
    self.nxp_hcard:import_private_key(keyReference,
            pTemplate[CKA.MODULUS],
            pTemplate[CKA.PUBLIC_EXPONENT], 
            pTemplate[CKA.PRIME_1],
            pTemplate[CKA.PRIME_2],
            pTemplate[CKA.COEFFICIENT],
            pTemplate[CKA.EXPONENT_1],
            pTemplate[CKA.EXPONENT_2]
            )
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] and not t._is_private_attribute(k) then
            obj[k] = pTemplate[k]
        end
    end

    log.output('token-nxp-chipdoc:create_object_privkey(): writing private key objects directory...')
    self:_write_file(kdPriv, self.files.PrivKD)
    self._indexes._private_keys_bin = kdPriv

    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    local hPriv = self.attributes.max_index
    -- crea l'oggetto chiave pubblica associato
    local pTemplatePub = GetPubKeyTemplate()
    pTemplatePub[CKA.MODULUS] = pTemplate[CKA.MODULUS]
    pTemplatePub[CKA.MODULUS_BITS] = eCK.ULONG(modulus_bits)
    pTemplatePub[CKA.PUBLIC_EXPONENT] = pTemplate[CKA.PUBLIC_EXPONENT]
    pTemplatePub[CKA.ID]=pTemplate[CKA.ID]
    pTemplatePub[CKA.LABEL]=pTemplate[CKA.LABEL]
    pTemplatePub[CKA.MODIFIABLE]=pTemplate[CKA.MODIFIABLE]
    -- local rv, hPubk =  self:create_object_pubkey(pTemplatePub, keyReference, false, true)
    -- log.output('token-nxp-chipdoc:create_object_privkey(): create_object_pubkey() result:', rv, hPubk)
    
    log.output('token-nxp-chipdoc:create_object_privkey(): CKR.OK, hPriv:', hPriv)
    return CKR.OK, hPriv
end



function t.mt:create_object_ecc_pubkey(pTemplateOrig, keyReference, as_local)
    log.output('token-nxp-chipdoc:create_object_ecc_pubkey():', pTemplateOrig, "as_local:", as_local, "keyReference:", keyReference)
    
    if not pTemplateOrig[CKA.EC_PARAMS] or not pTemplateOrig[CKA.EC_POINT] then
        log.output('token-nxp-chipdoc:create_object_ecc_pubkey(): EC_PARAMS or EC_POINT not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local curve = ecdhlib.get_curve_by_deroid(pTemplateOrig[CKA.EC_PARAMS])
    
    if not curve then
        log.output('token-nxp-chipdoc:create_object_ecc_pubkey(): specified EC_PARAMS not supported:', hex.hexify(pTemplateOrig[CKA.EC_PARAMS] or ""))
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    -- keyReference: quando specificato crea una chiave pubblica associata ad una chiave privata
    local pTemplate = utility.clone_table(pTemplateOrig)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local do_import_sdo
    local obj

    obj = GetECCPubKeyTemplate(t.mt.get_ecc_pubkey)
    obj.private = false
    
    -- access control
    pTemplate[CKA.LOCAL] = eCK.BBOOL(as_local)

    -- key usage
    pTemplate[CKA.VERIFY] = pTemplate[CKA.VERIFY] or eCK.BBOOL(true)
    pTemplate[CKA.MODIFIABLE] = eCK.BBOOL(true)
    
    pTemplate[CKA.ENCRYPT] = eCK.BBOOL(false)
    pTemplate[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    pTemplate[CKA.UNWRAP] = eCK.BBOOL(false)
    pTemplate[CKA.WRAP] = eCK.BBOOL(false)
    pTemplate[CKA.DECRYPT] = eCK.BBOOL(false)
    pTemplate[CKA.DERIVE] = eCK.BBOOL(false)
    
    pTemplate[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
    
    pTemplate[CKA.CLASS] = eCK.ULONG(CKO.PUBLIC_KEY)
    pTemplate[CKA.KEY_TYPE] = eCK.ULONG(CKK.ECDSA)
    pTemplate[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)

    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] and type(pTemplate[k]) == 'string' then
            obj[k] = pTemplate[k]
        end
    end
    obj[CKA.LOCAL] = eCK.BBOOL(as_local)

    if not keyReference then
        local hObj
        if self.userType == CKU.USER then
            log.output('token-nxp-chipdoc:create_object_ecc_pubkey(): user logged in: searching if a private key sharing same EC_POINT...')
            hObj = self:_search_related_key_object(
                pTemplate[CKA.EC_POINT],
                nil,
                eCK.ULONG(CKO.PRIVATE_KEY) )
        else
            log.output('token-nxp-chipdoc:create_object_ecc_pubkey(): user NOT logged in: unable to search a private key sharing same EC_POINT...')
        end
        if hObj then
            local objPriv = self.attributes[hObj]
            if objPriv.aid == NXPIASSmartCard.Generic_AID then
                keyReference = objPriv.kid
                log.output('token-nxp-chipdoc:create_object_ecc_pubkey(): found related key keyReference:', keyReference)
            end
        end
         
        if not keyReference then
            log.output('token-nxp-chipdoc:create_object_ecc_pubkey(): allocating a keyReference for public key')
            keyReference = self:virtual_alloc_kid(self._indexes._private_keys_bin, self._indexes._public_keys_bin, false)
            if not keyReference then
                log.output('token-nxp-chipdoc:create_object_ecc_pubkey(): no more keys left in unused space file!')
                return CKR.DEVICE_MEMORY
            end
            do_import_sdo = true
        end
    end
    
    self:invalidate_xproc_cache()
    self.nxp_hcard:auto_perform_mutual_authenticate()
    self.nxp_hcard:select_MF()
    local info = self:get_info()
    self.nxp_hcard:select_Generic()

    local label = pTemplate[CKA.LABEL] or ''
    local id = pTemplate[CKA.ID] or ''
    local pubKDBin, objNum = self:virtual_add_public_key_object(
                                self._indexes._public_keys_bin,
                                label,
                                id,
                                keyReference,
                                nil,
                                false,
                                pTemplate
                                )
    if string.len(pubKDBin) ~= string.len(self._indexes._public_keys_bin) then
        log.output('token-nxp-chipdoc:create_object_ecc_pubkey(): no more space left in Public KD file!')
        return CKR.DEVICE_MEMORY
    end
    obj.num = objNum
    obj.kid = keyReference
    obj.aid = NXPIASSmartCard.Generic_AID
    obj.parameters = pTemplate[CKA.EC_PARAMS]
    
    log.output(string.format("token-nxp-chipdoc:create_object_ecc_pubkey(): new obj num:%d kid:%d EC_PARAMS:%s (%s)", 
        obj.num or -1, obj.kid, hex.hexify(obj.parameters), der.der_oid_to_ascii_oid(obj.parameters)) )

    if do_import_sdo then
        log.output('token-nxp-chipdoc:create_object_ecc_pubkey(): AUTH OBJ: erasing SDOs...')
        self.nxp_hcard:delete_SDO(NXPIASSmartCard.object_classes.ECC_PUB_KEY, keyReference, true)
        self.nxp_hcard:delete_SDO(NXPIASSmartCard.object_classes.ECC_PRIV_KEY, keyReference, true)
        
        local acsPubk, acsPrivk = self:get_keys_acs(true)
        log.output('token-nxp-chipdoc:create_object_ecc_pubkey(): AUTH OBJ: creating SDOs...')
        self.nxp_hcard:create_ECDSA_SDO_for_keygen(NXPIASSmartCard.object_classes.ECC_PRIV_KEY, keyReference, curve.keysize*8, acsPrivk, true)
        self.nxp_hcard:create_ECDSA_SDO_for_keygen(NXPIASSmartCard.object_classes.ECC_PUB_KEY, keyReference, curve.keysize*8, acsPubk, true)
        
        local ecPointDer = der.parse(pTemplate[CKA.EC_POINT])
        if not ecPointDer[1] or ecPointDer[1].tag ~= der.STRING  then
            log.output('create_object_eddsa_pubkey(): EC_POINT not DER encoded or DER tag incorrect', hex.hexify(pTemplate[CKA.EC_POINT]))
        end
    
        self.nxp_hcard:import_ecc_private_key(keyReference,
            ecPointDer[1].value
            )
    end
    
    log.output('token-nxp-chipdoc:create_object_ecc_pubkey(): writing public key objects directory...')
    self:_write_file(pubKDBin, self.files.PubKD)
    self._indexes._public_keys_bin = pubKDBin
    
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    
    log.output('token-nxp-chipdoc:create_object_ecc_pubkey(): CKR.OK, hPub=', self.attributes.max_index)
    return CKR.OK, self.attributes.max_index
end


function t.mt:create_object_ecc_privkey(pTemplateOrig)
    log.output('token-nxp-chipdoc:create_object_ecc_privkey()', pTemplateOrig)
    
    if not pTemplateOrig[CKA.EC_PARAMS] then
        log.output('token-nxp-chipdoc:create_object_ecc_privkey(): EC_PARAMS not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local curve = ecdhlib.get_curve_by_deroid(pTemplateOrig[CKA.EC_PARAMS])
    if not curve then
        log.output('token-nxp-chipdoc:create_object_ecc_privkey(): specified EC_PARAMS not supported:', hex.hexify(pTemplateOrig[CKA.EC_PARAMS] or ""))
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    local pTemplate = utility.clone_table(pTemplateOrig)
    pTemplate[CKA.LOCAL] = eCK.BBOOL(false)
    
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    if not pTemplate[CKA.VALUE] then
            log.output('token-nxp-chipdoc:create_object_ecc_privkey(): no key value specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end

    local keyReference
    
    self:invalidate_xproc_cache()
    self.nxp_hcard:auto_perform_mutual_authenticate()

    -- access control
    pTemplate[CKA.LOCAL] = eCK.BBOOL(false)
    pTemplate[CKA.SENSITIVE] = eCK.BBOOL(true)
    pTemplate[CKA.ALWAYS_SENSITIVE] = eCK.BBOOL(true)
    pTemplate[CKA.NEVER_EXTRACTABLE] = eCK.BBOOL(true)
    pTemplate[CKA.EXTRACTABLE] = eCK.BBOOL(false)
    
    -- key usage
    pTemplate[CKA.SIGN] = eCK.BBOOL(true) -- overrides, the key can at least sign
    pTemplate[CKA.DECRYPT] = eCK.BBOOL(false)
    
    
    pTemplate[CKA.VERIFY] = eCK.BBOOL(false)
    pTemplate[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    pTemplate[CKA.WRAP] = eCK.BBOOL(false)
    pTemplate[CKA.ENCRYPT] = eCK.BBOOL(false)
    pTemplate[CKA.DERIVE] = eCK.BBOOL(false)
    
    pTemplate[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)

    pTemplate[CKA.CLASS] = eCK.ULONG(CKO.PRIVATE_KEY)
    pTemplate[CKA.KEY_TYPE] = eCK.ULONG(CKK.ECDSA)
    
    local privKey, pubKey = curve.g:make_keypair(bignum.create("0x" .. hex.hexify(pTemplate[CKA.VALUE])))
    local point = pubKey:encode_point(true)
    log.output('create_object_ecc_privkey(): EC_POINT (calculated)', hex.hexify(point))
    pTemplate[CKA.EC_POINT] = der.build(der.STRING, point)
    
    log.output('token-nxp-chipdoc:create_object_ecc_privkey(): searching if a public key sharing same modulus exists...')
    local hObj = self:_search_related_key_object(
                pTemplate[CKA.EC_POINT],
                nil,
                eCK.ULONG(CKO.PUBLIC_KEY) )
    if hObj then
        local objPub = self.attributes[hObj]
        if objPub.aid == NXPIASSmartCard.Generic_AID then
            keyReference = objPub.kid
            log.output('token-nxp-chipdoc:create_object_ecc_privkey(): found related key keyReference:', keyReference)
        end
    end
    
    if not keyReference then
        log.output('token-nxp-chipdoc:create_object_ecc_privkey(): allocating a keyReference for private key')
        keyReference = self:virtual_alloc_kid(self._indexes._private_keys_bin, self._indexes._public_keys_bin, false)
        if not keyReference  then
            log.output('token-nxp-chipdoc:create_object_ecc_privkey(): no more keyReference left')
            return CKR.DEVICE_MEMORY
        end
    end
    
    local authId = self.authID_Card_PIN
    local kdPriv, objNum = self:virtual_add_private_key_object(
        self._indexes._private_keys_bin,
        pTemplate[CKA.LABEL] or '',
        pTemplate[CKA.ID] or '',
        authId, keyReference, nil, false,
        pTemplate
        )
        
    if string.len(kdPriv) ~= string.len(self._indexes._private_keys_bin) then
        log.output('token-nxp-chipdoc:create_object_ecc_privkey(): no more space left in Private KD file!')
        return CKR.DEVICE_MEMORY
    end

    obj = GetPrivKeyTemplate(t.mt.get_privkey)
    obj.private = true
    obj.num = objNum
    obj.kid = keyReference
    obj.aid = NXPIASSmartCard.Generic_AID
    obj.parameters = pTemplate[CKA.EC_PARAMS]
    log.output(string.format("token-nxp-chipdoc:create_object_ecc_privkey(): new obj num:%d kid:%d EC_PARAMS:%s (%s)", 
        obj.num or -1, obj.kid, hex.hexify(obj.parameters), der.der_oid_to_ascii_oid(obj.parameters)) )

    self.nxp_hcard:select_MF()
    local info = self:get_info()
    self.nxp_hcard:select_Generic()
    
    log.output('token-nxp-chipdoc:create_object_ecc_privkey(): AUTH OBJ: erasing SDOs...')
    self.nxp_hcard:delete_SDO(NXPIASSmartCard.object_classes.ECC_PRIV_KEY, keyReference, true)
    self.nxp_hcard:delete_SDO(NXPIASSmartCard.object_classes.ECC_PUB_KEY, keyReference, true)
    
    local acsPubk, acsPrivk = self:get_keys_acs(true)
    log.output('token-nxp-chipdoc:create_object_ecc_privkey(): AUTH OBJ: creating SDOs...')
    self.nxp_hcard:create_ECDSA_SDO_for_keygen(NXPIASSmartCard.object_classes.ECC_PRIV_KEY, keyReference, curve.keysize*8, acsPrivk, true)
    self.nxp_hcard:create_ECDSA_SDO_for_keygen(NXPIASSmartCard.object_classes.ECC_PUB_KEY, keyReference, curve.keysize*8, acsPubk, true)
    
    log.output('token-nxp-chipdoc:create_object_ecc_privkey(): importing key components...')
    self.nxp_hcard:import_ecc_private_key(keyReference,
            point,
            ecdhlib.trim_pad_bn(pTemplate[CKA.VALUE], curve.keysize)
            )
    
    pTemplate[CKA.VALUE] = nil -- avoids keep key value in obj
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] and not t._is_private_attribute(k) then
            obj[k] = pTemplate[k]
        end
    end

    log.output('token-nxp-chipdoc:create_object_ecc_privkey(): writing private key objects directory...')
    self:_write_file(kdPriv, self.files.PrivKD)
    self._indexes._private_keys_bin = kdPriv

    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    local hPriv = self.attributes.max_index
    -- crea l'oggetto chiave pubblica associato
    local pTemplatePub = GetPubKeyTemplate()
    pTemplatePub[CKA.EC_POINT] = pTemplate[CKA.EC_POINT]
    pTemplatePub[CKA.EC_PARAMS] = pTemplate[CKA.EC_PARAMS]
    pTemplatePub[CKA.ID]=pTemplate[CKA.ID]
    pTemplatePub[CKA.LABEL]=pTemplate[CKA.LABEL]
    pTemplatePub[CKA.MODIFIABLE]=pTemplate[CKA.MODIFIABLE]
    -- local rv, hPubk =  self:create_object_pubkey(pTemplatePub, keyReference, false, true)
    -- log.output('token-nxp-chipdoc:create_object_ecc_privkey(): create_object_pubkey() result:', rv, hPubk)
    
    log.output('token-nxp-chipdoc:create_object_ecc_privkey(): CKR.OK, hPriv:', hPriv)
    return CKR.OK, hPriv
end



function t.mt:generate_key_pair_ecc(pMechanism, templatePub, templatePriv)
    local keyReference
    log.output('token-nxp-chipdoc:generate_key_pair_ecc()', templatePub, templatePriv)
    if self.userType ~= CKU.USER then
        log.output('token-nxp-chipdoc:generate_key_pair_ecc(): not loggen in, userType', self.userType)
        return CKR.USER_NOT_LOGGED_IN
    end
    
    log.output('token-nxp-chipdoc:generate_key_pair_ecc()', pTemplateOrig)
    
    if not self.mechanisms[CKM.EC_KEY_PAIR_GEN] then
        log.output('token-nxp-chipdoc:generate_key_pair_ecc(): ECDSA curves not supported by the card!')
        return CKR.MECHANISM_INVALID
    end
    
    local ec_params = templatePub[CKA.EC_PARAMS]  or templatePriv[CKA.EC_PARAMS]
    if not ec_params then
        log.output('token-nxp-chipdoc:generate_key_pair_ecc(): EC_PARAMS not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local curve = ecdhlib.get_curve_by_deroid(ec_params)
    if not curve then
        log.output('token-nxp-chipdoc:generate_key_pair_ecc(): specified EC_PARAMS not supported:', ec_params or "")
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    
    self:check_clear_cache(true)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local templatePub1 = utility.clone_table(templatePub)
    local templatePriv1 = utility.clone_table(templatePriv)
    
    if templatePub1[CKA.ID] then
        templatePriv1[CKA.ID] = templatePub1[CKA.ID]
    elseif templatePriv1[CKA.ID] then
        templatePub1[CKA.ID] = templatePriv1[CKA.ID]
    end
    
    local isDS = self:is_ds(templatePriv1)
    log.output('token-nxp-chipdoc:generate_key_pair_ecc(): isDS:', isDS)
    
    templatePriv1[CKA.EC_PARAMS] = ec_params
    templatePub1[CKA.EC_PARAMS] = ec_params
    
    -- access control
    templatePub1[CKA.LOCAL] = eCK.BBOOL(true)
    templatePriv1[CKA.LOCAL] = eCK.BBOOL(true)
    templatePriv1[CKA.SENSITIVE] = eCK.BBOOL(true)
    templatePriv1[CKA.ALWAYS_SENSITIVE] = eCK.BBOOL(true)
    templatePriv1[CKA.NEVER_EXTRACTABLE] = eCK.BBOOL(true)
    templatePriv1[CKA.EXTRACTABLE] = eCK.BBOOL(false)
    
    -- key usage
    templatePriv1[CKA.SIGN] = eCK.BBOOL(true) -- overrides, the key can at least sign
    templatePriv1[CKA.DECRYPT] = eCK.BBOOL(false)
    
    templatePriv1[CKA.CLASS] = eCK.ULONG(CKO.PRIVATE_KEY)
    templatePriv1[CKA.KEY_TYPE] = eCK.ULONG(CKK.ECDSA)
    
    templatePriv1[CKA.VERIFY] = eCK.BBOOL(false)
    templatePriv1[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    templatePriv1[CKA.WRAP] = eCK.BBOOL(false)
    templatePriv1[CKA.ENCRYPT] = eCK.BBOOL(false)
    templatePriv1[CKA.DERIVE] = eCK.BBOOL(false)
    
   
    objPriv = GetECCPrivKeyTemplate(t.mt.get_privkey)
    objPriv.private = true
    objPriv.parameters = ec_params
    objPriv.aid = NXPIASSmartCard.Generic_AID
    
    self:invalidate_xproc_cache()
    self:cache_clear()
   

    local keyReference = self:virtual_alloc_kid(self._indexes._private_keys_bin, self._indexes._public_keys_bin, isDS)
    
    if not keyReference then
        log.output('token-nxp-chipdoc:generate_key_pair_ecc(): no more space available for this type of object!')
        return CKR.DEVICE_MEMORY
    end
    
    local authId = self.authID_Card_PIN
    
    local kdPriv, objNum = self:virtual_add_private_key_object(
        self._indexes._private_keys_bin,
        templatePriv1[CKA.LABEL] or '',
        templatePriv1[CKA.ID] or '',
        authId, keyReference, nil, isDS, -- DS ECC is authID_Card_PIN protected
        templatePriv1
        )
    
    if string.len(kdPriv) ~= string.len(self._indexes._private_keys_bin) then
        log.output('token-nxp-chipdoc:generate_key_pair_ecc(): no more space left in Private KD file!')
        return CKR.DEVICE_MEMORY
    end
    
    objPriv.kid = keyReference
    objPriv.num = objNum
    objPriv.userConsent = isDS and 1 or nil
    log.output(string.format("token-nxp-chipdoc:generate_key_pair_ecc(): new obj num:%d kid:%d EC_PARAMS:%s (%s)", 
        objPriv.num or -1, objPriv.kid, hex.hexify(objPriv.parameters), der.der_oid_to_ascii_oid(objPriv.parameters)) )
        
    self.nxp_hcard:auto_perform_mutual_authenticate()
    local info = self:get_info()
    
    
    log.output('token-nxp-chipdoc:generate_key_pair_ecc(): verify_pin_main() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.nxp_hcard:select_MF()
        self.nxp_hcard:verify_pin_main(self.cached_main_pin, false)  -- pin, ispuk
    end


    self.nxp_hcard:select_MF()
    self.nxp_hcard:select_Generic()
    
    log.output('token-nxp-chipdoc:generate_key_pair_ecc(): AUTH OBJ: erasing SDOs...')
    
    self.nxp_hcard:delete_SDO(NXPIASSmartCard.object_classes.ECC_PUB_KEY, keyReference, true)
    self.nxp_hcard:delete_SDO(NXPIASSmartCard.object_classes.ECC_PRIV_KEY, keyReference, true)
    
    local acsPubk, acsPrivk  = self:get_keys_acs()
    
    log.output('token-nxp-chipdoc:generate_key_pair_ecc(): AUTH OBJ: creating SDOs...')
    self.nxp_hcard:create_ECDSA_SDO_for_keygen(NXPIASSmartCard.object_classes.ECC_PRIV_KEY, keyReference, curve.keysize*8, acsPrivk, true)
    self.nxp_hcard:create_ECDSA_SDO_for_keygen(NXPIASSmartCard.object_classes.ECC_PUB_KEY, keyReference, curve.keysize*8, acsPubk, true)
    
    log.output('token-nxp-chipdoc:generate_key_pair_ecc(): AUTH OBJ: generating key pair...')
    self.nxp_hcard:generate_ECC(keyReference)
    
    -- GAM: BUG FIX ECDSA 521 key read: close SM channel on error
    local pubKey = self.nxp_hcard:read_public_key_ECC(keyReference, nil, true)
        
    templatePriv1[CKA.EC_PARAMS] = ec_params
    templatePriv1[CKA.EC_POINT] = der.build(der.STRING, pubKey)
    

    templatePub1[CKA.EC_PARAMS] = ec_params
    templatePub1[CKA.EC_POINT] = der.build(der.STRING, pubKey)
    templatePub1[CKA.CLASS] = eCK.ULONG(CKO.PUBLIC_KEY)
    templatePub1[CKA.KEY_TYPE] = eCK.ULONG(CKK.ECDSA)
    templatePub1[CKA.TOKEN] = eCK.BBOOL(true)

    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if templatePriv1[k] and not t._is_private_attribute(k) then
            objPriv[k] = templatePriv1[k]
        end
    end
    
    objPriv[CKA.EC_PARAMS] = ec_params
    objPriv[CKA.EC_POINT] = templatePub1[CKA.EC_POINT]
    objPriv[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
    
    if kdPriv then
        log.output('token-nxp-chipdoc:generate_key_pair_ecc(): writing private key objects directory...')
        self:_write_file(kdPriv, self.files.PrivKD)
        self._indexes._private_keys_bin = kdPriv
    end
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPriv
    local hPrivk = self.attributes.max_index
    
    local rv, hPubk  = self:create_object_ecc_pubkey(templatePub1, keyReference, true)

    log.output('token-nxp-chipdoc:generate_key_pair_ecc(): create_object_ecc_pubkey(): result:', rv, 'handle:', hPubk)
    
    self:update_free_mem(self.info)
    log.output("token-nxp-chipdoc:generate_key_pair_ecc():calling update_cache_id()...")
    self:update_cache_id()
    log.output(string.format("token-nxp-chipdoc:generate_key_pair_ecc(): rv=CKR.OK, hPubk=%d, hPrivk=%d",  hPubk, hPrivk) )
    return CKR.OK, hPubk, hPrivk
end

function t.mt:create_object_certificate(pTemplate)
    local usObj, FAuthId
    log.output('token-nxp-chipdoc:create_object_certificate()', pTemplate)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    if not pTemplate[CKA.VALUE] then
        log.output('token-nxp-chipdoc:create_object_certificate(): VALUE not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    local actual_cert_data = pTemplate[CKA.VALUE]
    if self.use_cpr_mode then
        local cpr = zlib.compresscer( pTemplate[CKA.VALUE])
        local decpr = cpr and zlib.decompresscer(cpr)
        if decpr == actual_cert_data then
            actual_cert_data = cpr
            pcall(function()
            log.output('token-nxp-chipdoc:create_object_certificate(): cpr ratio:', 
                string.len(cpr)/string.len(pTemplate[CKA.VALUE]))
            end)
        else
            log.output('token-nxp-chipdoc:create_object_certificate(): compression failed!')
        end
    end

    obj = GetCertTemplate(t.mt.get_certificate)
    obj.private = false
    local parsed_cer
    
    pcall(function() parsed_cer = der.parse_x509cer( pTemplate[CKA.VALUE]) end )
    
    if not parsed_cer then
        log.output('token-nxp-chipdoc:create_object_certificate(): parse certificate failed!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    -- local hint
    -- if not parsed_cer.modulus and not parsed_cer.eccPoint then
        -- log.output('token-nxp-chipdoc:create_object_certificate(): certificate has invalid modulus/eccPoint!')
        -- return CKR.ATTRIBUTE_VALUE_INVALID
    -- end
    
    -- local find_template_ecc = {
        -- [CKA.CLASS]=eCK.ULONG(CKO.PRIVATE_KEY),
        -- [CKA.EC_POINT]=parsed_cer.eccPoint,
    -- }
    -- local find_template_rsa = {
        -- [CKA.CLASS]=eCK.ULONG(CKO.PRIVATE_KEY),
        -- [CKA.MODULUS]=parsed_cer.modulus,
    -- }
    -- local find_template = parsed_cer.eccPoint and find_template_ecc or find_template_rsa
    
    -- log.output('token-nxp-chipdoc:create_object_certificate(): looking for a private key with same key...')
    -- local hKey = self:get_item({}, true, find_template)
    -- if not hKey or hKey == 0 then
        -- log.output('token-nxp-chipdoc:create_object_certificate(): unable to find related privte key, importing as CA or single certificate')
    -- else
        -- local objPriv = self.attributes[hKey]
        -- if not objPriv then
            -- log.output('token-nxp-chipdoc:create_object_certificate(): internal error, null reference')
            -- return CKR.FUNCTION_FAILED
        -- end
        -- hint = objPriv.kid
    -- end

    local fid = self:virtual_alloc_cert_file(self._indexes._certificates_bin)

    log.output("token-nxp-chipdoc:create_object_certificate(): using FID:", hex.hexify(fid))
    obj.path = fid

    local HolderCD, objNum = self:virtual_add_cert_object(
        self._indexes._certificates_bin,
        pTemplate[CKA.LABEL] or '',
        pTemplate[CKA.ID] or '',
        obj.path,
        parsed_cer)
    
    if string.len(HolderCD) ~= string.len(self._indexes._certificates_bin) then
        log.output('token-nxp-chipdoc:create_object_certificate(): no more space left in Certificate Holder Directory file!')
        return CKR.DEVICE_MEMORY
    end
    
    obj.num = objNum
    log.output(string.format("token-nxp-chipdoc:create_object_certificate(): new obj num: %d", 
        obj.num) )
        
    self:invalidate_xproc_cache()

    self.nxp_hcard:auto_perform_mutual_authenticate()
    self.nxp_hcard:select_MF()
    local info = self:get_info()
    self.nxp_hcard:select_Generic()
    -- scrive il certificato
    self.nxp_hcard:delete_file(obj.path, true, true)
    
    self.nxp_hcard:create_binary_file(fid, 
        string.len(actual_cert_data), 
        true,
        NXPIASSmartCard.ID_SE_ALWAYS,
        NXPIASSmartCard.ID_SE_ALWAYS,
        NXPIASSmartCard.ID_SE_ALWAYS
    )
    
    self:_write_file(actual_cert_data, obj.path)
    
    if HolderCD then
        -- scrive certificate directory file
        self:_write_file(HolderCD, self.files.CDF)
        self._indexes._certificates_bin = HolderCD
    end
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] then
            obj[k] = pTemplate[k]
        end
    end

    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj

    log.output(string.format("token-nxp-chipdoc:create_object_certificate(): rv=CKR.OK, hObj=%d",  self.attributes.max_index) )
        
    return CKR.OK, self.attributes.max_index
end


function t.mt:create_object_data(pTemplateOrig)
    local usObj, FAuthId
    log.output('token-nxp-chipdoc:create_object_data()', pTemplateOrig)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    
    local pTemplate = utility.clone_table(pTemplateOrig)
    
    if not pTemplate[CKA.VALUE] then
        log.output('token-nxp-chipdoc:create_object_data(): VALUE not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    local actual_data = pTemplate[CKA.VALUE]
    
    obj = GetDataObjectTemplate(t.mt.get_data_object)
    obj.private = pTemplate[CKA.PRIVATE] and pTemplate[CKA.PRIVATE] ~= eCK.BBOOL(false)
    local SE_ID = obj.private and (self.nxp_hcard.ID_SE_MAIN + NXPIASSmartCard.ID_SBC_PIN)  or NXPIASSmartCard.ID_SE_ALWAYS
    -- local SE_ID = NXPIASSmartCard.ID_SE_ALWAYS
    
    local fid = self:virtual_alloc_data_file(self._indexes._data_objects_bin)

    log.output("token-nxp-chipdoc:create_object_data(): using FID:", hex.hexify(fid))
    obj.path = fid

    pTemplate[CKA.LABEL] = pTemplate[CKA.LABEL] or ''
    pTemplate[CKA.APPLICATION] = pTemplate[CKA.APPLICATION] or ''
    pTemplate[CKA.OBJECT_ID] = pTemplate[CKA.OBJECT_ID] or ''
    
    local dataD, objNum = self:virtual_add_data_object(
        self._indexes._data_objects_bin,
        pTemplate,
        pTemplate[CKA.LABEL],
        pTemplate[CKA.APPLICATION],
        pTemplate[CKA.OBJECT_ID],
        obj.path)
    
    if string.len(dataD) ~= string.len(self._indexes._data_objects_bin) then
        log.output('token-nxp-chipdoc:create_object_data(): no more space left in data Directory file!')
        return CKR.DEVICE_MEMORY
    end
    
    obj.num = objNum
    log.output(string.format("token-nxp-chipdoc:create_object_data(): new obj num: %d", 
        obj.num) )
        
    self:invalidate_xproc_cache()

    self.nxp_hcard:auto_perform_mutual_authenticate()
    self.nxp_hcard:select_MF()
    local info = self:get_info()
    self.nxp_hcard:select_Generic()
    -- scrive il certificato
    self.nxp_hcard:delete_file(obj.path, true, true)
    
    self.nxp_hcard:create_binary_file(fid, 
        string.len(actual_data), 
        true,
        SE_ID,
        SE_ID,
        SE_ID
    )
    
    self:_write_file(actual_data, obj.path)
    
    if dataD then
        -- scrive certificate directory file
        self:_write_file(dataD, self.files.dataDF)
        self._indexes._data_objects_bin = dataD
    end
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] then
            obj[k] = pTemplate[k]
        end
    end

    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj

    log.output(string.format("token-nxp-chipdoc:create_object_data(): rv=CKR.OK, hObj=%d",  self.attributes.max_index) )
        
    return CKR.OK, self.attributes.max_index
end



function t.mt:get_keys_acs(for_import)
    local seID = self.nxp_hcard.ID_SE_MAIN + NXPIASSmartCard.ID_SBC_PIN
    local acsPubk = {SDO=true, GENERATE_ASYMMETRIC_KEY_PAIR={[1]=seID},
                                PUT_DATA={[1]=seID},
                                GET_DATA={[1]=NXPIASSmartCard.ID_SE_ALWAYS}, }
    
    local acsPrivk = {SDO=true, PSO_COMPUTE_DIGITAL_SIGNATURE={[1]=seID}, 
                                PSO_DECIPHER={[1]=seID}, 
                                INTERNAL_AUTHENTICATE={[1]=seID}, 
                                GENERATE_ASYMMETRIC_KEY_PAIR={[1]=seID},
                                GET_DATA={[1]=NXPIASSmartCard.ID_SE_ALWAYS}, }
    if for_import then
        acsPrivk.PUT_DATA={[1]=seID}
    end
    return acsPubk, acsPrivk
end


function t.mt:generate_key_pair(pMechanism, templatePubOrig, templatePrivOrig)
    log.output('generate_key_pair()', templatePub, templatePriv)
    if pMechanism and pMechanism.mechanism then
        log.output(string.format('generate_key_pair(): mechanism=%x', pMechanism.mechanism ) )
        log.output(string.format('generate_key_pair(): parameter=%s', pMechanism.parameter and hex.hexify(pMechanism.parameter) or "<null>"))
    end
    
    if pMechanism and pMechanism.mechanism then
        if not self.mechanisms[pMechanism.mechanism] then
            log.output('generate_key_pair(): unsupported mechanism!', pMechanism.mechanism)
            return CKR.MECHANISM_INVALID
        end
    end
   
   
    local templatePub = utility.clone_table(templatePubOrig)
    local templatePriv = utility.clone_table(templatePrivOrig)
    templatePub[CKA.DESTROYABLE] = templatePub[CKA.DESTROYABLE] or eCK.BBOOL(true)
    templatePriv[CKA.DESTROYABLE] = templatePriv[CKA.DESTROYABLE] or eCK.BBOOL(true)

    if not pMechanism or not pMechanism.mechanism or pMechanism.mechanism == CKM.RSA_PKCS_KEY_PAIR_GEN then
        log.output('generate_key_pair(): generating RSA...')
        return self:generate_key_pair_rsa(pMechanism, templatePub, templatePriv)
        
    elseif pMechanism.mechanism == CKM.EC_KEY_PAIR_GEN then
        log.output('generate_key_pair(): generating ECC...')
        return self:generate_key_pair_ecc(pMechanism, templatePub, templatePriv)
        
    else
        log.output('generate_key_pair(): MECHANISM_INVALID!')
        return CKR.MECHANISM_INVALID
    end
end

function t.mt:generate_key_pair_rsa(pMechanism, templatePub, templatePriv)
    local keyReference
    log.output('token-nxp-chipdoc:generate_key_pair_rsa()', templatePub, templatePriv)
    if self.userType ~= CKU.USER then
        log.output('token-nxp-chipdoc:generate_key_pair_rsa(): not loggen in, userType', self.userType)
        return CKR.USER_NOT_LOGGED_IN
    end
    
    self:check_clear_cache(true)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local templatePub1 = utility.clone_table(templatePub)
    local templatePriv1 = utility.clone_table(templatePriv)
    
    if templatePub1[CKA.ID] then
        templatePriv1[CKA.ID] = templatePub1[CKA.ID]
    elseif templatePriv1[CKA.ID] then
        templatePub1[CKA.ID] = templatePriv1[CKA.ID]
    end
    
    -- access control
    templatePub1[CKA.LOCAL] = eCK.BBOOL(true)
    templatePriv1[CKA.LOCAL] = eCK.BBOOL(true)
    templatePriv1[CKA.SENSITIVE] = eCK.BBOOL(true)
    templatePriv1[CKA.ALWAYS_SENSITIVE] = eCK.BBOOL(true)
    templatePriv1[CKA.NEVER_EXTRACTABLE] = eCK.BBOOL(true)
    templatePriv1[CKA.EXTRACTABLE] = eCK.BBOOL(false)
    
    -- key usage
    templatePriv1[CKA.SIGN] = eCK.BBOOL(true) -- overrides, the key can at least sign
    templatePriv1[CKA.DECRYPT] = templatePriv1[CKA.DECRYPT] or eCK.BBOOL(true)
    
    templatePriv1[CKA.CLASS] = eCK.ULONG(CKO.PRIVATE_KEY)
    templatePriv1[CKA.KEY_TYPE] = eCK.ULONG(CKK.RSA)
    
    templatePriv1[CKA.VERIFY] = eCK.BBOOL(false)
    templatePriv1[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    templatePriv1[CKA.WRAP] = eCK.BBOOL(false)
    templatePriv1[CKA.ENCRYPT] = eCK.BBOOL(false)
    templatePriv1[CKA.DERIVE] = eCK.BBOOL(false)
    

    
    local cka_modulus_bits = templatePub1[CKA.MODULUS_BITS] or templatePriv1[CKA.MODULUS_BITS] or eCK.ULONG(2048)
    local modulus_bits = 1024    
    if not cka_modulus_bits or cka_modulus_bits == eCK.ULONG(1024) then
        modulus_bits = 1024
    elseif cka_modulus_bits == eCK.ULONG(2048) then
        modulus_bits = 2048
    elseif self._supports_3072 and cka_modulus_bits == eCK.ULONG(3072) then
        modulus_bits = 3072
    elseif self._supports_4096 and cka_modulus_bits == eCK.ULONG(4096) then
        modulus_bits = 4096
    else
        log.output('token-nxp-chipdoc:generate_key_pair_rsa(): key size invalid for selected filesystem:', hex.hexify(cka_modulus_bits or '') )
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
   
    objPriv = GetPrivKeyTemplate(t.mt.get_privkey)
    objPriv.private = true
    objPriv.key_bits = modulus_bits
    
    self:invalidate_xproc_cache()
    self:cache_clear()
    
    local isDS = self:is_ds(templatePriv1)
    local isSSCD = isDS and self.nxp_hcard.has_sscd and modulus_bits == 2048
    log.output('token-nxp-chipdoc:generate_key_pair_rsa(): isDS:', isDS)
    log.output('token-nxp-chipdoc:generate_key_pair_rsa(): isSSCD:', isSSCD)
    
    local keyReference = self:virtual_alloc_kid(self._indexes._private_keys_bin, self._indexes._public_keys_bin, isDS)
    
    if not keyReference then
        log.output('token-nxp-chipdoc:generate_key_pair_rsa(): no more space available for this type of object!')
        return CKR.DEVICE_MEMORY
    end
    
    local authId = self.authID_Card_PIN
    local authIdDS = self.authID_Sig_PIN
    
    if isDS then
        templatePriv1[CKA.DECRYPT] = eCK.BBOOL(false)
        templatePriv1[CKA.UNWRAP] = eCK.BBOOL(false)
        templatePriv1[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(true)
        
        templatePub1[CKA.WRAP] = eCK.BBOOL(false)
        templatePub1[CKA.ENCRYPT] = eCK.BBOOL(false)
    end
    
    local kdPriv, objNum = self:virtual_add_private_key_object(
        self._indexes._private_keys_bin,
        templatePriv1[CKA.LABEL] or '',
        templatePriv1[CKA.ID] or '',
        isSSCD and authIdDS or authId, keyReference, modulus_bits, isDS,
        templatePriv1
        )
    
    if string.len(kdPriv) ~= string.len(self._indexes._private_keys_bin) then
        log.output('token-nxp-chipdoc:generate_key_pair_rsa(): no more space left in Private KD file!')
        return CKR.DEVICE_MEMORY
    end
    
    objPriv.kid = keyReference
    objPriv.num = objNum
    objPriv.userConsent = isDS and 1 or nil
    log.output(string.format("token-nxp-chipdoc:generate_key_pair_rsa(): new obj num:%d kid:%d bits:%d", 
        objPriv.num, objPriv.kid, objPriv.key_bits) )
    
    self.nxp_hcard:auto_perform_mutual_authenticate()
    local info = self:get_info()
    
    
    log.output('token-nxp-chipdoc:generate_key_pair_rsa(): verify_pin_main() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.nxp_hcard:select_MF()
        self.nxp_hcard:verify_pin_main(self.cached_main_pin, false)  -- pin, ispuk
    end
    
    local modulus, pubExp
    
    if not isSSCD then
        self.nxp_hcard:select_MF()
        self.nxp_hcard:select_Generic()
        
        log.output('token-nxp-chipdoc:generate_key_pair_rsa(): AUTH OBJ: erasing SDOs...')
        
        self.nxp_hcard:delete_SDO(NXPIASSmartCard.object_classes.RSA_PUB_KEY, keyReference, true)
        self.nxp_hcard:delete_SDO(NXPIASSmartCard.object_classes.RSA_PRIV_KEY, keyReference, true)
        
        local acsPubk, acsPrivk  = self:get_keys_acs()
        
        log.output('token-nxp-chipdoc:generate_key_pair_rsa(): AUTH OBJ: creating SDOs...')
        self.nxp_hcard:create_RSA_SDO_for_keygen(NXPIASSmartCard.object_classes.RSA_PRIV_KEY, keyReference, objPriv.key_bits, acsPrivk, true)
        self.nxp_hcard:create_RSA_SDO_for_keygen(NXPIASSmartCard.object_classes.RSA_PUB_KEY, keyReference, objPriv.key_bits, acsPubk, true)
        
        log.output('token-nxp-chipdoc:generate_key_pair_rsa(): AUTH OBJ: generating key pair...')
        self.nxp_hcard:generate_RSA(keyReference)
        modulus, pubExp = self.nxp_hcard:read_public_key(keyReference)
        objPriv.aid = NXPIASSmartCard.Generic_AID
        
    else
        log.output('token-nxp-chipdoc:generate_key_pair_rsa(): DS OBJ...')
        
        log.output('token-nxp-chipdoc:generate_key_pair_rsa(): DS OBJ: activating SSCD SM...')
        
        local pcRes, theErrorT = pcall(function()
            self.nxp_hcard:perform_mutual_authenticate(NXPIASSmartCard.SSCD_AID)
            self.nxp_hcard:select_SSCD()
            self.nxp_hcard:select(self.DF_DS, 1) -- 1 -> select DF mode
        end)
        if not pcRes then
            log.output('token-nxp-chipdoc:generate_key_pair_rsa(): DS OBJ: error activating SSCD SM:', debug.traceback(theErrorT) )
            return CKR.FUNCTION_FAILED
        end

        if self.userType == CKU.USER and self.cached_main_pin then
            self.nxp_hcard:verify_pin_ds(self.cached_main_pin, false) -- pin, ispuk
        end
    
        local docp
        pcRes, theErrorT = pcall(function()
            self.nxp_hcard:select_SSCD()
            self.nxp_hcard:select(self.DF_DS, 1) -- 1 -> select DF mode
            docp = self.nxp_hcard:get_DOCP(NXPIASSmartCard.object_classes.RSA_PUB_KEY, objPriv.kid)
        end)
        if not pcRes then
            log.output('token-nxp-chipdoc:generate_key_pair_rsa(): DS OBJ: error getting SDO infos:', debug.traceback(theErrorT) )
            return CKR.DEVICE_MEMORY
        end
        log.output('token-nxp-chipdoc:generate_key_pair_rsa(): AUTH OBJ: generating key pair...')
        self.nxp_hcard:generate_RSA(keyReference)
        modulus, pubExp = self.nxp_hcard:read_public_key(keyReference)
        
        objPriv.aid = NXPIASSmartCard.SSCD_AID
        objPriv.path = self.DF_DS
        log.output('token-nxp-chipdoc:generate_key_pair_rsa(): DS OBJ: restoring Generic SM...')
        self.nxp_hcard:perform_mutual_authenticate()
        self.nxp_hcard:select_MF()
        self.nxp_hcard:select_Generic()
    end
    

    templatePub1[CKA.MODULUS] = modulus
    templatePub1[CKA.PUBLIC_EXPONENT] = pubExp
    templatePub1[CKA.CLASS] = eCK.ULONG(CKO.PUBLIC_KEY)
    templatePub1[CKA.KEY_TYPE] = eCK.ULONG(CKK.RSA)
    templatePub1[CKA.TOKEN] = eCK.BBOOL(true)

    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if templatePriv1[k] and not t._is_private_attribute(k) then
            objPriv[k] = templatePriv1[k]
        end
    end
    
    objPriv[CKA.MODULUS] = modulus        -- cache preventiva
    objPriv[CKA.PUBLIC_EXPONENT] = pubExp
    objPriv[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)

    if kdPriv then
        log.output('token-nxp-chipdoc:generate_key_pair_rsa(): writing private key objects directory...')
        self:_write_file(kdPriv, self.files.PrivKD)
        self._indexes._private_keys_bin = kdPriv
    end
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPriv
    local hPrivk = self.attributes.max_index
    
    local rv, hPubk  = self:create_object_pubkey(templatePub1, keyReference, true, isDS)

    log.output('token-nxp-chipdoc:generate_key_pair_rsa(): create_object_pubkey(): result:', rv, 'handle:', hPubk)
    
    self:update_free_mem(self.info)
    log.output("token-nxp-chipdoc:generate_key_pair_rsa():calling update_cache_id()...")
    self:update_cache_id()
    log.output(string.format("token-nxp-chipdoc:generate_key_pair_rsa(): rv=CKR.OK, hPubk=%d, hPrivk=%d",  hPubk, hPrivk) )
    return CKR.OK, hPubk, hPrivk
end

function t.mt:generate_key(pMechanism, pTemplate)
    log.output('token-nxp-chipdoc:generate_key(): pMechanism', pMechanism and pMechanism.mechanism)
    log.output('token-nxp-chipdoc:generate_key(): verify_pin_main() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.nxp_hcard:select_MF()
        self.nxp_hcard:verify_pin_main(self.cached_main_pin, false)  -- pin, ispuk
    end

    -- self.nxp_hcard:select_MF()
    -- self.nxp_hcard:select_Generic()
    
    if pTemplate[CKA.PRIVATE]
        and pTemplate[CKA.PRIVATE] ~= eCK.BBOOL(false)
        and self.userType ~= CKU.USER then
        log.output('token-nxp-chipdoc:generate_key(): not logged in: login required to create private objects')
        return CKR.USER_NOT_LOGGED_IN
    end
    
    if not pTemplate[CKA.VALUE_LEN] then
        log.output('token-nxp-chipdoc:generate_key(): no key len specified')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local rv, hObj
    
    self:check_clear_cache(true)
    self:invalidate_xproc_cache()
    self:cache_clear()
    
    if pMechanism.mechanism == CKM.AES_KEY_GEN then
        local pTemplate2 = utility.clone_table(pTemplate)
        local value_len
        
        if pTemplate2[CKA.VALUE_LEN] == eCK.ULONG(16) then
            value_len = 16
        elseif pTemplate2[CKA.VALUE_LEN] == eCK.ULONG(24) then
            value_len = 24
        elseif pTemplate2[CKA.VALUE_LEN] == eCK.ULONG(32) then
            value_len = 32
        else
            log.output('token-nxp-chipdoc:generate_key(): key len not supported:', hex.hexify(pTemplate2[CKA.VALUE_LEN] or ""))
            return CKR.ATTRIBUTE_VALUE_INVALID
        end
        
        pTemplate2[CKA.VALUE] = sm.gen_random(value_len)
        pTemplate2[CKA.CLASS] = eCK.ULONG(CKO.SECRET_KEY)
        pTemplate2[CKA.KEY_TYPE] = eCK.ULONG(CKK.AES)
        pTemplate2[CKA.ENCRYPT] = eCK.BBOOL(true)
        pTemplate2[CKA.DECRYPT] = eCK.BBOOL(true)
        
        rv, hObj = self:create_object_secret_key(pTemplate2)

    else
    
        log.output('token-nxp-chipdoc:generate_key(): unsupported mechanism:', pMechanism.mechanism)
        rv = CKR.MECHANISM_INVALID
    end
    if rv == CKR.OK then
        self:update_free_mem(self.info)
        log.output("token-nxp-chipdoc:generate_key(): calling update_cache_id()...")
        self:update_cache_id()
    end
    log.output(string.format("token-nxp-chipdoc:generate_key(): returning rv=0x%08X, hobj=%d", rv or -1, hObj or -1))
    return rv, hObj
end

function t.mt:create_object_secret_key(pTemplate)

    log.output('token-nxp-chipdoc:create_object_secret_key()', pTemplate)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    if not pTemplate[CKA.VALUE] then
        log.output('token-nxp-chipdoc:create_object_secret_key(): VALUE not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    local value = pTemplate[CKA.VALUE]
    local value_len = string.len(value)
    
    if value_len ~= 16 and value_len ~= 24 and value_len ~= 32  then
        log.output('token-nxp-chipdoc:create_object_secret_key(): VALUE len invalid!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end

    obj = GetSecretKeyTemplate(t.mt.get_secret_key)
    obj.private = true
    obj.value = value
    
    local keyReference = self:virtual_alloc_kid_secret_key(self._indexes._secret_keys_bin)
    local fid = hex.hexf("DA%B", tonumber("EF", 16) +  keyReference) -- secret key files: DCF0 - DCFF
    log.output("token-nxp-chipdoc:create_object_secret_key(): using FID:", hex.hexify(fid))
    obj.path = fid

    local authId = self.authID_Card_PIN
    local kdSecret, objNum = self:virtual_add_private_key_object(
        self._indexes._secret_keys_bin,
        pTemplate[CKA.LABEL] or '',
        pTemplate[CKA.ID] or '',
        authId, keyReference, value_len, false,
        pTemplate
        )
    
    if string.len(kdSecret) ~= string.len(self._indexes._secret_keys_bin) then
        log.output('token-nxp-chipdoc:create_object_secret_key(): no more space left in secret keys Directory file!')
        return CKR.DEVICE_MEMORY
    end
    
    obj.num = objNum
    log.output(string.format("token-nxp-chipdoc:create_object_secret_key(): new obj num: %d", 
        obj.num) )
        
    self:invalidate_xproc_cache()

    self.nxp_hcard:auto_perform_mutual_authenticate()
    self.nxp_hcard:select_MF()
    local info = self:get_info()
    self.nxp_hcard:select_Generic()
    -- scrive value
    self.nxp_hcard:delete_file(obj.path, true, true)
    
    local e_value = aes.aes_encrypt_check(self._mk, value, "00000001")
    log.output("token-nxp-chipdoc:create_object_secret_key(): value:", hex.hexify(value))
    log.output("token-nxp-chipdoc:create_object_secret_key(): e_value:", hex.hexify(e_value))
    
    self.nxp_hcard:create_binary_file(fid, 
        string.len(e_value), 
        true,
        NXPIASSmartCard.ID_SE_ALWAYS,
        NXPIASSmartCard.ID_SE_ALWAYS,
        NXPIASSmartCard.ID_SE_ALWAYS
    )
    
    self:_write_file(e_value, obj.path)
    
    if kdSecret then
        -- scrive secret keys directory file
        self:_write_file(kdSecret, self.files.secretKD)
        self._indexes._secret_keys_bin = kdSecret
    end
    
    pTemplate[CKA.VALUE] = nil
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] then
            obj[k] = pTemplate[k]
        end
    end

    
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj

    log.output(string.format("token-nxp-chipdoc:create_object_secret_key(): rv=CKR.OK, hObj=%d",  self.attributes.max_index) )
    
    return CKR.OK, self.attributes.max_index
end


function t.mt:create_object(pTemplate)
    log.output('token-nxp-chipdoc:create_object(): verify_pin_main() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.nxp_hcard:select_MF()
        self.nxp_hcard:verify_pin_main(self.cached_main_pin, false)  -- pin, ispuk
    end

    -- self.nxp_hcard:select_MF()
    -- self.nxp_hcard:select_Generic()
    
    if pTemplate[CKA.PRIVATE]
        and pTemplate[CKA.PRIVATE] ~= eCK.BBOOL(false)
        and self.userType ~= CKU.USER then
        log.output('token-nxp-chipdoc:create_object(): not logged in: login required to create private objects')
        return CKR.USER_NOT_LOGGED_IN
    end

    local rv, hObj
    
    self:check_clear_cache(true)
    self:invalidate_xproc_cache()
    self:cache_clear()
    
    if pTemplate[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        rv, hObj = self:create_object_certificate(pTemplate)
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
    
        rv, hObj = self:create_object_data(pTemplate)

    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.SECRET_KEY) then
        if pTemplate[CKA.KEY_TYPE] == eCK.ULONG(CKK.AES) then
    
            if not self.mechanisms[CKM.AES_KEY_GEN] then
                log.output('create_object(): AES obejct not supported')
                return CKR.ATTRIBUTE_VALUE_INVALID
            end
            
            rv, hObj = self:create_object_secret_key(pTemplate)
        else
            log.output('token-nxp-chipdoc:create_object(): unsupported secret key type:', hex.hexify(pTemplate[CKA.KEY_TYPE] or ''))
            return CKR.ATTRIBUTE_VALUE_INVALID
        end
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        if pTemplate[CKA.KEY_TYPE] == eCK.ULONG(CKK.ECDSA) then

            if not self.mechanisms[CKM.EC_KEY_PAIR_GEN] then
                log.output('create_object(): ECDSA obejct not supported')
                return CKR.ATTRIBUTE_VALUE_INVALID
            end
            
            rv, hObj = self:create_object_ecc_privkey(pTemplate)
        else
            rv, hObj = self:create_object_privkey(pTemplate)
        end
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
    
        if pTemplate[CKA.KEY_TYPE] == eCK.ULONG(CKK.ECDSA) then

            if not self.mechanisms[CKM.EC_KEY_PAIR_GEN] then
                log.output('create_object(): ECDSA obejct not supported')
                return CKR.ATTRIBUTE_VALUE_INVALID
            end

            rv, hObj = self:create_object_ecc_pubkey(pTemplate)
        else
            rv, hObj = self:create_object_pubkey(pTemplate)
        end
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO_PIN_POLICY) then
        rv, hObj = self:create_object_pin_policy(pTemplate)
    else
        log.output('token-nxp-chipdoc:create_object(): unsupported object class:', hex.hexify(pTemplate[CKA.CLASS] or ''))
        rv = CKR.ATTRIBUTE_VALUE_INVALID
    end
    if rv == CKR.OK then
        self:update_free_mem(self.info)
        log.output("token-nxp-chipdoc:create_object(): calling update_cache_id()...")
        self:update_cache_id()
    end
    log.output(string.format("token-nxp-chipdoc:create_object(): returning rv=0x%08X, hobj=%d", rv or -1, hObj or -1))
    return rv, hObj
end


function t.mt:_renumber_objects(objRef)
    local obj
    for i=self.attributes.min_index, self.attributes.max_index do
        obj = self.attributes[i]
        if type(obj) == "table" 
            and obj[CKA.CLASS] == objRef[CKA.CLASS]
            and obj.num and objRef.num 
            and obj.num > objRef.num then
            obj.num = obj.num -1
        end
    end
end

function t.mt:_related_key_exists(kid, excludeNum)
    local obj
    for i=self.attributes.min_index, self.attributes.max_index do
        obj = self.attributes[i]
        if type(obj) == "table" and obj.kid == kid and obj.num ~= excludeNum then
            return true
        end
    end
    return false
end

function t.mt:destroy_object(hObject)
    log.output('token-nxp-chipdoc:destroy_object(): ', hObject)
    
    
    log.output('token-nxp-chipdoc:destroy_object(): verify_pin_main() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.nxp_hcard:select_Generic()
        self.nxp_hcard:select_MF()
        self.nxp_hcard:verify_pin_main(self.cached_main_pin, false)  -- pin, ispuk
    end
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hObject]
    
    if obj == nil then return CKR.OBJECT_HANDLE_INVALID end
    
    local login_required = obj.private or obj[CKA.CLASS] ~= eCK.ULONG(CKO.DATA)
    
    if login_required then
        if self.userType ~= CKU.USER then
            log.output('token-nxp-chipdoc:destroy_object(): USER login required to destroy privte or NON-DATA objects')
            return CKR.USER_NOT_LOGGED_IN
        end
    end
    
    self:check_clear_cache(true)
    
    self:invalidate_xproc_cache()
    self.nxp_hcard:auto_perform_mutual_authenticate()
    self:cache_clear()
    
    self.nxp_hcard:select_Generic()
    
    if obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        log.output('token-nxp-chipdoc:destroy_object(): destroyng a certificate')
        -- rimuove la entry indicata da "obj.num" dall'index
        local d = p15.parseCertDF(self._indexes._certificates_bin)
        if obj.num > table.getn(d) then
            log.output('token-nxp-chipdoc:destroy_object(): obj.num invalid:', obj.num)
            return CKR.FUNCTION_FAILED
        end
        table.remove(d, obj.num)
        local HolderCD = p15.buildCertDF(d)
        HolderCD = HolderCD .. string.rep("\000", string.len(self._indexes._certificates_bin) - string.len(HolderCD))
        
        -- delete cert file:
        self.nxp_hcard:delete_file(obj.path, true, true)

        -- scrive certificate directory file
        self:_write_file(HolderCD, self.files.CDF)

        self._indexes._certificates_bin = HolderCD
        
        -- elimina l'oggetto dalla lista
        self.attributes[hObject] = nil
        
        -- rinumera tutti gli oggetti certificate con num > obj.num
        self:_renumber_objects(obj)
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        log.output('token-nxp-chipdoc:destroy_object(): destroyng a data object')
        -- rimuove la entry indicata da "obj.num" dall'index
        local d = p15.parsePubPrivDataD(self._indexes._data_objects_bin)
        if obj.num > table.getn(d) then
            log.output('token-nxp-chipdoc:destroy_object(): obj.num invalid:', obj.num)
            return CKR.FUNCTION_FAILED
        end
        table.remove(d, obj.num)
        local dataD = p15.buildPubPrivDataD(d)
        dataD = dataD .. string.rep("\000", string.len(self._indexes._data_objects_bin) - string.len(dataD))
        
        -- delete cert file:
        self.nxp_hcard:delete_file(obj.path, true, true)

        -- scrive data object directory file
        self:_write_file(dataD, self.files.dataDF)

        self._indexes._data_objects_bin = dataD
        
        -- elimina l'oggetto dalla lista
        self.attributes[hObject] = nil
        
        -- rinumera tutti gli oggetti data con num > obj.num
        self:_renumber_objects(obj)
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.SECRET_KEY) then
        log.output('token-nxp-chipdoc:destroy_object(): destroyng a certificate')
        -- rimuove la entry indicata da "obj.num" dall'index
        local d = p15.parsePubPrivKD(self._indexes._secret_keys_bin)
        if obj.num > table.getn(d) then
            log.output('token-nxp-chipdoc:destroy_object(): obj.num invalid:', obj.num)
            return CKR.FUNCTION_FAILED
        end
        table.remove(d, obj.num)
        local secretKD = p15.buildPubPrivKD(d)
        secretKD = secretKD .. string.rep("\000", string.len(self._indexes._secret_keys_bin) - string.len(secretKD))
        
        -- delete key file:
        self.nxp_hcard:delete_file(obj.path, true, true)

        -- scrive secret keys directory file
        self:_write_file(secretKD, self.files.secretKD)

        self._indexes._secret_keys_bin = secretKD
        
        -- elimina l'oggetto dalla lista
        self.attributes[hObject] = nil
        
        -- rinumera tutti gli oggetti secret key con num > obj.num
        self:_renumber_objects(obj)
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        log.output('token-nxp-chipdoc:destroy_object(): destroyng a public key')
        -- rimuove la entry indicata da "obj.num" dall'index
        local pkBin
        local d = p15.parsePubPrivKD(self._indexes._public_keys_bin)
        if obj.num > table.getn(d) then
            log.output('token-nxp-chipdoc:destroy_object(): obj.num invalid:', obj.num)
            return CKR.FUNCTION_FAILED
        end
        table.remove(d, obj.num)
        pkBin = p15.buildPubPrivKD(d, {subClassAttributes={}})
        pkBin = pkBin .. string.rep("\000", string.len(self._indexes._public_keys_bin) - string.len(pkBin))


        if pkBin then
            -- scrive public key directory file
            self:_write_file(pkBin, self.files.PubKD)
            self._indexes._public_keys_bin = pkBin
        end

        if obj.aid == NXPIASSmartCard.Generic_AID 
                and not self:is_kid_in_use(self._indexes._private_keys_bin, obj.kid ) then
                
            self.nxp_hcard:delete_SDO(NXPIASSmartCard.object_classes.RSA_PUB_KEY, obj.kid, true)
            self.nxp_hcard:delete_SDO(NXPIASSmartCard.object_classes.RSA_PRIV_KEY, obj.kid, true)
        end
        
        -- elimina l'oggetto dalla lista
        self.attributes[hObject] = nil
        
        -- rinumera tutti gli oggetti public key con num > obj.num
        self:_renumber_objects(obj)

    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        log.output('token-nxp-chipdoc:destroy_object(): destroyng a private key')
        -- rimuove la entry indicata da "obj.num" dall'index
        local pkBin
        local d = p15.parsePubPrivKD(self._indexes._private_keys_bin)
        if obj.num > table.getn(d) then
            log.output('token-nxp-chipdoc:destroy_object(): obj.num invalid:', obj.num)
            return CKR.FUNCTION_FAILED
        end
        table.remove(d, obj.num)
        pkBin = p15.buildPubPrivKD(d, {subClassAttributes={}})
        pkBin = pkBin .. string.rep("\000", string.len(self._indexes._public_keys_bin) - string.len(pkBin))


        if pkBin then
            -- scrive private key directory file
            self:_write_file(pkBin, self.files.PrivKD)
            self._indexes._private_keys_bin = pkBin
        end
        
        if obj.aid == NXPIASSmartCard.Generic_AID
            and not self:is_kid_in_use(self._indexes._public_keys_bin, obj.kid ) then
            
            self.nxp_hcard:delete_SDO(NXPIASSmartCard.object_classes.RSA_PUB_KEY, obj.kid, true)
            self.nxp_hcard:delete_SDO(NXPIASSmartCard.object_classes.RSA_PRIV_KEY, obj.kid, true)
        end
        
        -- elimina l'oggetto dalla lista
        self.attributes[hObject] = nil
        
        -- rinumera tutti gli oggetti private key con num > obj.num
        self:_renumber_objects(obj)
        
    else
        log.output('token-nxp-chipdoc:destroy_object(): WARNING! Unsupported object class!')
        return CKR.FUNCTION_FAILED
    end
    
    self.attributes[hObject] = nil
    
    self:update_free_mem(self.info)
    log.output("token-nxp-chipdoc:destroy_object(): calling update_cache_id()...")
    self:update_cache_id()
    log.output("token-nxp-chipdoc:destroy_object(): returning CKR.OK")
    return CKR.OK
end

function t.mt:set_attribute_value(hObject, pTemplate)
    log.output('token-nxp-chipdoc:set_attribute_value():', hObject)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local rv
    local obj = self.attributes[hObject]
    if obj == nil then
        log.output('token-nxp-chipdoc:set_attribute_value(): specified handle invalid: ', hObject)
        return CKR.OBJECT_HANDLE_INVALID
    end

    log.output('token-nxp-chipdoc:set_attribute_value(): verify_pin_main() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.nxp_hcard:select_MF()
        self.nxp_hcard:verify_pin_main(self.cached_main_pin, false)  -- pin, ispuk
    end
    
    self:invalidate_xproc_cache()
    self.nxp_hcard:auto_perform_mutual_authenticate()
    
    if obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        if not obj.populated then self:get_pubkey(hObject, CKA.CLASS, false, true) end
        rv = self:set_attribute_value_pubkey(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        if not obj.populated then self:get_privkey(hObject, CKA.CLASS) end
        rv = self:set_attribute_value_privkey(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        if not obj.populated then self:get_certificate(hObject, CKA.CLASS, false, true) end
        rv = self:set_attribute_value_certificate(hObject, pTemplate)
        
    else
        log.output('token-nxp-chipdoc:set_attribute_value(): unsupported object class:', hex.hexify(obj[CKA.CLASS]))
        rv = CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    if rv == CKR.OK then
        self:update_free_mem(self.info)
        log.output("token-nxp-chipdoc:set_attribute_value(): calling update_cache_id()...")
        self:update_cache_id()
    end
    log.output("token-nxp-chipdoc:set_attribute_value(): rv:", rv)
    return rv
    
end

function t.mt:set_attribute_value_privkey(hObj, pTemplate)
    log.output('token-nxp-chipdoc:set_attribute_value_privkey()')
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    local obj = self.attributes[hObj]
    
    for k, v in pTemplate do
        if k ~= CKA.ID and k ~= CKA.LABEL and k ~= CKA.SUBJECT
            and k ~= CKA.START_DATE and k ~= CKA.END_DATE 
            and k ~= CKA.MODIFIABLE
            and k ~= CKA.DECRYPT and k ~= CKA.SIGN then
            return CKR.ATRIBUTE_TYPE_INVALID
        end
    end
    
    local templateNew = {}
    -- copia tutti gli attributi CKA_*
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if obj[k] then
            templateNew[k] = obj[k]
        end
    end
    for k, v in pTemplate do
        templateNew[k] = v
    end
    local fs = p15.parsePubPrivKD(self._indexes._private_keys_bin)
    if type(obj.num) ~= "number" or obj.num > table.getn(fs) then
        log.output('token-nxp-chipdoc:set_attribute_value_privkey(): error: invalid obj.num:', obj.num)
        return CKR.FUNCTION_FAILED
    end
    if pTemplate[CKA.LABEL] or pTemplate[CKA.ID] then
        self.nxp_hcard:select_Generic()
        local v = fs[obj.num]
        v.commonObjectAttributes.label = pTemplate[CKA.LABEL] or v.commonObjectAttributes.label
        v.classAttributes.iD = pTemplate[CKA.ID] or v.classAttributes.iD
        local privKDBin = p15.buildPubPrivKD(fs, {subClassAttributes={}})
        privKDBin = privKDBin .. string.rep("\000", string.len(self._indexes._private_keys_bin) - string.len(privKDBin))
        if string.len(privKDBin) ~= string.len(self._indexes._private_keys_bin) then
            log.output('token-nxp-chipdoc:set_attribute_value_privkey(): no more space left in Private KD file!')
            return CKR.DEVICE_MEMORY
        end
        self:_write_file(privKDBin, self.files.PrivKD)
        self._indexes._private_keys_bin = privKDBin
    end
    
    -- aggiorna i valori in cache
    for k, v in pTemplate do
        obj[k] = v
    end
    return CKR.OK
end



function t.mt:set_attribute_value_certificate(hObj, pTemplate)
    log.output('token-nxp-chipdoc:set_attribute_value_certificate()')
    local obj = self.attributes[hObj]
    
    -- implementato come re-create: cancella il vecchio oggetto e lo ricrea coi nuovi attributi
    
    for k, v in pTemplate do
        if k ~= CKA.ID and k ~= CKA.LABEL and k ~= CKA.SUBJECT
            and k ~= CKA.ISSUER and k ~= CKA.SERIAL_NUMBER
            and k ~= CKA.MODIFIABLE and k ~= CKA.TRUESTED  then
            return CKR.ATRIBUTE_TYPE_INVALID
        end
    end

    local templateNew = {}
    -- copia tutti gli attributi CKA_*
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if obj[k] then
            templateNew[k] = obj[k]
        end
    end
    for k, v in pTemplate do
        templateNew[k] = v
    end
    local fs = p15.parseCertDF(self._indexes._certificates_bin)
    if type(obj.num) ~= "number" or obj.num > table.getn(fs) then
        log.output('token-nxp-chipdoc:set_attribute_value_certificate(): error: invalid obj.num:', obj.num)
        return CKR.FUNCTION_FAILED
    end
    if pTemplate[CKA.LABEL] or pTemplate[CKA.ID] then
        self.nxp_hcard:select_Generic()
        local v = fs[obj.num]
        v.commonObjectAttributes.label = pTemplate[CKA.LABEL] or v.commonObjectAttributes.label
        v.classAttributes.iD = pTemplate[CKA.ID] or v.classAttributes.iD
        local certDF = p15.buildCertDF(fs)
        certDF = certDF .. string.rep("\000", string.len(self._indexes._certificates_bin) - string.len(certDF))
        if string.len(certDF) ~= string.len(self._indexes._certificates_bin) then
            log.output('token-nxp-chipdoc:set_attribute_value_certificate(): no more space left in certDF file!')
            return CKR.DEVICE_MEMORY
        end
        self:_write_file(certDF, self.files.CDF)
        self._indexes._certificates_bin = certDF
    end
    
    -- aggiorna i valori in cache
    for k, v in pTemplate do
        obj[k] = v
    end
    return CKR.OK
end


function t.mt:set_attribute_value_pubkey(hObj, pTemplate)
    log.output('token-nxp-chipdoc:set_attribute_value_pubkey()')
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    local obj = self.attributes[hObj]
    
    for k, v in pTemplate do
        if k ~= CKA.ID and k ~= CKA.LABEL and k ~= CKA.SUBJECT            
            and k ~= CKA.MODIFIABLE
            and k ~= CKA.START_DATE and k ~= CKA.END_DATE  then
            return CKR.ATRIBUTE_TYPE_INVALID
        end
    end

    local templateNew = {}
    -- copia tutti gli attributi CKA_*
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if obj[k] then
            templateNew[k] = obj[k]
        end
    end
    for k, v in pTemplate do
        templateNew[k] = v
    end
    local fs = p15.parsePubPrivKD(self._indexes._public_keys_bin)
    if type(obj.num) ~= "number" or obj.num > table.getn(fs) then
        log.output('token-nxp-chipdoc:set_attribute_value_pubkey(): error: invalid obj.num:', obj.num)
        return CKR.FUNCTION_FAILED
    end
    if pTemplate[CKA.LABEL] or pTemplate[CKA.ID] then
        self.nxp_hcard:select_Generic()
        local v = fs[obj.num]
        v.commonObjectAttributes.label = pTemplate[CKA.LABEL] or v.commonObjectAttributes.label
        v.classAttributes.iD = pTemplate[CKA.ID] or v.classAttributes.iD
        local pubKDBin = p15.buildPubPrivKD(fs, {subClassAttributes={}})
        pubKDBin = pubKDBin .. string.rep("\000", string.len(self._indexes._public_keys_bin) - string.len(pubKDBin))
        if string.len(pubKDBin) ~= string.len(self._indexes._public_keys_bin) then
            log.output('token-nxp-chipdoc:set_attribute_value_pubkey(): no more space left in Public KD file!')
            return CKR.DEVICE_MEMORY
        end
        self:_write_file(pubKDBin, self.files.PubKD)
        self._indexes._public_keys_bin = pubKDBin
    end
    
    -- aggiorna i valori in cache
    for k, v in pTemplate do
        obj[k] = v
    end
    return CKR.OK
end

function t.mt:get_special_ids(id_class)
    if id_class == 'DS' then
        local ids = {}
        for i=0,9 do
            table.insert(ids, string.format('DS%d', i))
        end
        return ids
    end
end


function t.mt:set_label(Puk, label)
    local rv = CKR.OK
    local info = self:get_info()
    log.output('token-nxp-chipdoc:set_label():', Puk, label)
    local pcRes, theErrorT = pcall(function()
        
        self.nxp_hcard:select_Generic()
        local cia_infoD = self:read_cached_file(self.files.tokenInfo, 0, -1, true)
        local cia_info = p15.parse_tokenInfo(cia_infoD)
        if cia_info.label then
            label = string.sub(label, 1, string.len(cia_info.label))
            
            cia_info.label = label .. string.rep(" ", string.len(cia_info.label) - string.len(label))
            
            cia_infoD = p15.build_tokenInfo(cia_info)
            self:_write_file(cia_infoD, self.files.tokenInfo, 0)
            self:update_cache_id()
            
            info.label = cia_info.label
            log.output (string.format("token-nxp-chipdoc:set_label(): label set to: '%s'", cia_info.label))
            
        end
  
    
    end)
    if not pcRes then
        log.output('token-nxp-chipdoc:set_label(): error:', theErrorT)
        rv = CKR.FUNCTION_FAILED
    end
    return rv
end


local emt = {
	OperationOk = 0, -- Report "operation success", generic, return 0
	OperationFailed = 1, -- Report "operation failed", generic, return 0

	PinIncorrect = 8, -- Report "PIN incorrect, retry?", return 1 if YES, 0 if NO
	PinLocked = 9,    -- Report "Smartcard locked", return 0
	PinDeactivated = 10, -- Report "Smartcard not yet activated", return 0

	PukIncorrect = 16, -- Report "PUK incorrect, retry?", return 1 if YES, 0 if NO
	PukLocked = 17, -- Report "PUK locked", return 0

    }
    
    
function t.mt:gui_show_pin_message(result, ispuk)
    local msgid = 0
    if result==2 and ispuk then msgid = emt.PukLocked
    elseif result==2 and not ispuk then msgid = emt.PinLocked
    elseif result==1 and ispuk then msgid = emt.PukIncorrect
    elseif result==1 and not ispuk then msgid = emt.PinIncorrect
    else
        return -1
    end
    
    local transactionDisabled = self.hcard:transactionsdisabled()
    self.hcard:disabletransactions(false)
    if transactionDisabled then
        self.hcard:endtransaction()
    else
        self.nxp_hcard:end_transaction()
    end
    local res = w32.show_message(msgid)
    self.hcard:status() -- in caso di reset effettua una reconnect
    if transactionDisabled then
        self.hcard:begintransaction()
    else
        self.nxp_hcard:begin_transaction()
    end
    self.hcard:disabletransactions(transactionDisabled)
    return res
end

               
function t.mt:gui_request_pin_ds()
    local transactionDisabled = self.hcard:transactionsdisabled()
    self.hcard:disabletransactions(false)
    if transactionDisabled then
        self.hcard:endtransaction()
    else
        self.nxp_hcard:end_transaction()
    end
    local res, contextual_pin, cache_ds_pin = w32.request_pin_ds(self.check_box_visible)
    self.hcard:status() -- in caso di reset effettua una reconnect
    if transactionDisabled then
        self.hcard:begintransaction()
    else
        self.nxp_hcard:begin_transaction()
    end
    self.hcard:disabletransactions(transactionDisabled)
    return res, contextual_pin, cache_ds_pin
end



function t.mt:try_verify_pin(isdsObject, isSSCDObject)
    log.output('try_verify_pin(): isdsObject', isdsObject)
    log.output('try_verify_pin(): isSSCDObject', isSSCDObject)
    local result, contextual_pin
    
    local cached_pin_valid = self.cached_main_pin and self.userType == CKU.USER
    local ds_object_can_use_cached_pin = (isdsObject and not (self.cfg["dspinusegui"] == 'true' or self.cfg["dspinusegui"] == 'sign'))
    local try_cached = cached_pin_valid and (not isdsObject or ds_object_can_use_cached_pin)
    
    log.output("try_verify_pin(): CFG:", utility.repr(self.cfg))
    local info = self:get_info()
    if isSSCDObject then
        self.nxp_hcard:perform_mutual_authenticate(NXPIASSmartCard.SSCD_AID)  -- switch to SSCD SM session
    else
        self.nxp_hcard:select_MF()
    end    
    if try_cached then
        log.output('try_verify_pin(): re-verifying cached main pin...')
        contextual_pin = self.cached_main_pin

        
        if isSSCDObject then
            log.output('try_verify_pin(): verify DS cached...')
            self.nxp_hcard:select_SSCD()
            self.nxp_hcard:select(self.DF_DS, 1) -- 1 -> select DF mode

            result = self.nxp_hcard:verify_pin_ds(contextual_pin, false) -- pin, ispuk
        else
            log.output('try_verify_pin(): verify main cached...')
            result = self.nxp_hcard:verify_pin_main(contextual_pin)
        end
        if result ~= 0 then
            log.output('try_verify_pin(): verify cached: failed:', result)
            return CKR.FUNCTION_FAILED
        end
    elseif self._pinpad_hw then
    
        log.output('try_verify_pin(): not cached, using pinpad (main pin only)...')
        local pin_id =  self.nxp_hcard.ID_PIN
        local pin_op = PINPAD_CTL_PIN
        local padding = self.nxp_hcard.pinDOCP.objLen
        local apdu = hex.hexf("002000%B%P", pin_id, string.rep("\255", padding) )
        
        local cmd = {min_length=4, max_length=padding, stored_length=padding, apdu=apdu}
        
        local wasSMActive = self.nxp_hcard.ActiveSM
        self.nxp_hcard:close_secure_channel()
        while true do
            result = pcsc.pinpad_ctl_ex(
                PINPAD_CTL_VERIFY + pin_op,
                self.nxp_hcard.card,
                self.reader_name,
                cmd)
            if self:gui_show_pin_message(result, false) ~= 1 then
                break
            end
        end
        if wasSMActive then
            log.output("try_verify_pin(): reactivaitng Generic SM...")
            self.nxp_hcard:perform_mutual_authenticate()
        end
        
    elseif self.request_plugin_valid
       and (self.cfg["dspinusegui"] == 'true' or self.cfg["dspinusegui"] == 'sign')
        then
        
        -- self.nxp_hcard:auto_perform_mutual_authenticate() -- check/restore Generic SM session
        
        if self.cached_ds_pin then
            contextual_pin = self.cached_ds_pin
            if isSSCDObject then
                log.output('try_verify_pin(): verify DS cached...')
                self.nxp_hcard:select_SSCD()
                self.nxp_hcard:select(self.DF_DS, 1) -- 1 -> select DF mode
                result = self.nxp_hcard:verify_pin_ds(contextual_pin, false) -- pin, ispuk
            else
                log.output('try_verify_pin(): verify main cached...')
                result = self.nxp_hcard:verify_pin_main(contextual_pin)
            end
            if result ~= 0 then
                log.output('try_verify_pin(): verify cached: failed:', result)
                return CKR.FUNCTION_FAILED
            end
        else
            local res, cache_ds_pin
            while true do
                res, contextual_pin, cache_ds_pin = self:gui_request_pin_ds()
                if res ~= 1 then
                    log.output('try_verify_pin(): cancelled by plugin with code:', res)
                    return CKR.FUNCTION_FAILED
                end

                if isSSCDObject then
                    self.nxp_hcard:auto_perform_mutual_authenticate() -- check/restore current SM session
                    self.nxp_hcard:select_SSCD()
                    self.nxp_hcard:select(self.DF_DS, 1) -- 1 -> select DF mode
                    result = self.nxp_hcard:verify_pin_ds(contextual_pin, false) -- pin, ispuk
                else
                    self.nxp_hcard:auto_perform_mutual_authenticate() -- check/restore current SM session
                    self.nxp_hcard:select_MF()
                    result = self.nxp_hcard:verify_pin_main(contextual_pin)
                end
                if result == 0 and cache_ds_pin then self.cached_ds_pin = contextual_pin end
                contextual_pin = nil
                if self:gui_show_pin_message(result, false) ~= 1 then
                    break
                end
            end
        end
    else
        log.output('try_verify_pin(): requesting contextual login since ALWAYS_AUTHENTICATE is set...')
        return CKR.USER_NOT_LOGGED_IN
    end
    
    return CKR.OK
end


return t



--===========================================================================
end
}
_LOADED['NXPIASSmartCard'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
local rsa = require("rsa")
local hex = require 'hex'
local util = require 'utility'
local repr = util.repr
local h2i, hexf, hexify = hex.h2i, hex.hexf, hex.hexify
local zlib = require 'zlib'
local der = require("der")
local ecdhlib = require("ecdhlib")

local function hexf2(data, ...)
    data = string.gsub(data, "%s", "")
    return hex.hexf(data, unpack(arg))
end

-- NXPIASSmartCard

local tr_dl


local NXPIASSmartCard = {}
NXPIASSmartCard.mt = {}
NXPIASSmartCard.mt.__index = NXPIASSmartCard.mt


local SSCD_AID    = hex.hexf("e828bd080fd2504543432d654944")
local Generic_AID = hex.hexf("e828bd080fd25047656e65726963")
local SELECT_MAIN_APPLET_MF_AID = hex.hexf("00a4040c0bf0496173456363526f6f74")
NXPIASSmartCard.SSCD_AID = SSCD_AID
NXPIASSmartCard.Generic_AID = Generic_AID
NXPIASSmartCard.SELECT_MAIN_APPLET_MF_AID = SELECT_MAIN_APPLET_MF_AID

NXPIASSmartCard.MAX_TRANSMIT_BUFFER_SIZE = 128
NXPIASSmartCard.ID_PIN = tonumber("01", 16)
NXPIASSmartCard.ID_PUK = tonumber("02", 16)

NXPIASSmartCard.ID_PIN_DS = tonumber("02", 16)
NXPIASSmartCard.ID_PUK_DS = tonumber("03", 16)


NXPIASSmartCard.ID_SE_MAIN = tonumber("03", 16)
NXPIASSmartCard.ID_SE_DS = tonumber("02", 16)

NXPIASSmartCard.ID_SBC_PIN = tonumber("10", 16)

NXPIASSmartCard.ID_SE_ALWAYS = 0


NXPIASSmartCard.NXPIASSmartCardError = {}
NXPIASSmartCard.NXPIASSmartCardError.mt = {}
NXPIASSmartCard.NXPIASSmartCardError.mt.__index = NXPIASSmartCard.NXPIASSmartCardError.mt

function NXPIASSmartCard.NXPIASSmartCardError.mt.__tostring(e)
    return "NXPIASSmartCardError: " .. (e.msg or '') .. ' ;SW=' .. hex.hexify(e.sw or '') 
end

function NXPIASSmartCard.NXPIASSmartCardError.new(sw, msg)
    local e = msg .. ' ;sw=' .. hexify(sw or '')
    return e
end


function NXPIASSmartCard.new(card)
    local self = {
                    ID_PIN=NXPIASSmartCard.ID_PIN,
                    ID_PUK=NXPIASSmartCard.ID_PUK,
                    ID_PIN_DS=NXPIASSmartCard.ID_PIN_DS,
                    ID_PUK_DS=NXPIASSmartCard.ID_PUK_DS,
                    ID_SE_MAIN=NXPIASSmartCard.ID_SE_MAIN,
                    ID_SE_DS=NXPIASSmartCard.ID_SE_DS,
                    PADDING_CHAR="\255",
                    smSig = hex.hexf("54B72278CC20D435" .. "6256147477F598A0" .. "54B72278CC20D435"),
                    smEnc = hex.hexf("A3DD45191CB82959" .. "EBB344091F69E426" .. "A3DD45191CB82959"),
                    _active_aid_sm = nil, -- no SM valid
                    }
    self.card = card
    setmetatable(self, NXPIASSmartCard.mt)
    return self
end


local function append_chained_apdus(header_last, header, data, block_len, apdus)
    log.output(string.format("NXPIASSmartCard:append_chained_apdus(): header_last=%s", header_last))
    log.output(string.format("NXPIASSmartCard:append_chained_apdus(): header=%s", header))
    log.output(string.format("NXPIASSmartCard:append_chained_apdus(): block_len=%d", block_len))
    
    while true do 
        local block = string.sub(data, 1, block_len)
        log.output(string.format("NXPIASSmartCard:append_chained_apdus(): block=%s", hex.hexify(block)))
        
        if string.len(block) < block_len then
            log.output(string.format("NXPIASSmartCard:append_chained_apdus(): not multiple, last block=%s", hex.hexify(block)))
            local apdu = hex.hexf(header_last, block)
            log.output(string.format("NXPIASSmartCard:append_chained_apdus():append apdu=%s", hex.hexify(apdu)))
            table.insert(apdus, apdu) -- this is last block, data len is NOT multiple of block_len
            break
        end
        
        data = string.sub(data, string.len(block)+1, -1) -- remaining data
        if string.len(data) == 0 then
            log.output(string.format("NXPIASSmartCard:append_chained_apdus(): multiple, last block=%s", hex.hexify(block)))
            local apdu = hex.hexf(header_last, block)
            log.output(string.format("NXPIASSmartCard:append_chained_apdus(): append apdu=%s", hex.hexify(apdu)))
            table.insert(apdus, apdu) -- no more data remaining, this is last block and data len is multiple of block_len
            break
        else
            log.output(string.format("NXPIASSmartCard:append_chained_apdus(): NOT last block=%s", hex.hexify(block)))
            local apdu = hex.hexf(header, block)
            log.output(string.format("NXPIASSmartCard:append_chained_apdus(): append apdu=%s", hex.hexify(apdu)))
            table.insert(apdus, apdu) -- not last block
        end
    end
    return apdus
end

local function parse_tlv_ber(data)
    local d = {}
    local i = 0
    local offset, le, tag
    local log_array = {}
    log.output("parse_tlv_ber():", hex.hexify(data or ""))
    while 1 do
        tag = string.byte(data, i+1)
        if tag == 191 then -- 0xBF
            i = i+2
            tag = (tag * 65536) + (string.byte(data, i)*256) + (string.byte(data, i+1)) 
        elseif tag == 127 then -- 0x7F
            i = i+1
            tag = (tag * 256) + string.byte(data, i+1)
        elseif tag == 95 then -- 0x5F
            i = i+1
            tag = (tag * 256) + string.byte(data, i+1)
        end
        le = string.byte(data, i+2)
        offset = 0
        if le > 127 then
           offset = (bin.flags(le) * bin.flags("0x0F")).asnumber
           local leS = string.sub(data, i+3, i+2+offset)
           leS = string.rep("\000", 4 - string.len(leS)) .. leS
           le = bin.unpack("%>%L", leS)
           i = i + offset
        end
        table.insert(log_array, string.format("\tTAG: %02x LEN:%d", tag, le))
        d[tag] = string.sub(data, i+3, i+2+le)
        
        i = i + le + 2
        if i >= string.len(data) then
            break
        end
    end
    log.output(table.concat(log_array, "; "))
    return d
end


local function BUILD_TLV_BER(tagID, data)
    local DO87_85
    if string.len(data) >= 256 then
        DO87_85 = hex.hexf(tagID..'82%>%H%S', string.len(data), data )
    elseif string.len(data) >= 128 then
        DO87_85 = hex.hexf(tagID..'81%P', data )
    else
        DO87_85 = hex.hexf(tagID..'%P', data )
    end
    
    return DO87_85
end
       
       
local function sha256(data)
    local s = md.sha256()
    s:update(data)
    return s:final()
end

local function build_des3_key(key)
    local keyLen = string.len(key)
    if keyLen == 8 then
        key = key .. key .. key
    elseif keyLen == 16 then
        key = key .. string.sub(key, 1, 8)
    elseif keyLen == 24 then
        key = key
    else
        error("invalid key len:" .. keyLen)
    end
    return key
end

local function compute_des3_mac(plaintext, key, IV)

    keySig = build_des3_key(key)
    local mac_my = sm.des3_mac(keySig, plaintext)
    
    return mac_my

end

local function trim_pad_bn(data, padto)
    data = string.sub(data, -padto)
    data = string.rep("\000", padto - string.len(data)) .. data
    return data
end

local function trim_leding_zero(data)
    while (string.len(data) >0 and string.byte(data, 1) == 0) do
        data = string.sub(data, 2, -1)
    end
    return data
end


local function inc_ssc(ssc1)
    log.output("inc_ssc():")
    log.output("\tSSC:", hex.hexify(ssc1))
    local sscBN1 = bignum.create(ssc1, true) + bignum.create(1)
    local ssc = hex.hexf(sscBN1:tostring(16, true))
    ssc = trim_pad_bn(ssc, 8)
    log.output("\tSSC+1:", hex.hexify(ssc))
    return ssc
end

-- inc_ssc(hex.hexf("FFFFFFFFFFFFFFFF"))
-- inc_ssc(hex.hexf("0FFFFFFFFFFFFFFF"))
-- inc_ssc(hex.hexf("00FFFFFFFFFFFFFF"))
-- inc_ssc(hex.hexf("000FFFFFFFFFFFFF"))
-- inc_ssc(hex.hexf("0000FFFFFFFFFFFF"))
-- inc_ssc(hex.hexf("00000FFFFFFFFFFF"))
-- inc_ssc(hex.hexf("000000FFFFFFFFFF"))
-- inc_ssc(hex.hexf("0000000FFFFFFFFF"))
-- inc_ssc(hex.hexf("FFFFFFFFFFFFFFFF"))
-- inc_ssc(hex.hexf("FFFFFFFFFFFFFFFE"))
-- inc_ssc(hex.hexf("FFFFFFFFFFFFFFF0"))
-- inc_ssc(hex.hexf("0000000000000001"))
-- inc_ssc(hex.hexf("F000000000000001"))
-- inc_ssc(hex.hexf("F0000000000000F1"))


-- local function pad_iso9797(data, padding_length)
    -- local l = string.len(data)
    -- local m = math.mod(l, padding_length)
    -- if l == 0 or m == 0 then
        -- return data
    -- end
    -- return data .. string.rep('\000', padding_length-m)
-- end

local function pad_iso9797_2(data, padding_length)
    padding_length = padding_length or 8
    local l = string.len(data)
    local m = math.mod(l, padding_length)
    local x = data .. "\128" .. string.rep('\000', padding_length-1-m)
    return x
    
end

local function unpad_iso9797_2(data, padding_length)
    padding_length = padding_length or 8
    local l = string.len(data)
    for i=1,padding_length do
        if string.byte(data, l-i) == 128 then
            return string.sub(data, 1, l-i-1)
        end
    end
end


local function SM(keyEnc, keySig, apdu, seq)

	log.output("\tSM:keyEnc:" .. hex.hexify(keyEnc))
	log.output("\tSM:keySig:" .. hex.hexify(keySig))
	log.output("\tSM:apdu:" .. hex.hexify(apdu))
	log.output("\tSM:seq:" .. hex.hexify(seq))
    
	local seq1 = inc_ssc(seq)
	log.output("\tSM:seq1:" .. hex.hexify(seq1))
    
    local cla_f = bin.flags(string.byte(apdu, 1))
    cla_f = cla_f * bin.flags("0xF0" )
    cla_f = cla_f + bin.flags("0x0C" )
    apdu = string.char(cla_f.asnumber) .. string.sub(apdu, 2, -1)
    
	local smHead = string.sub(apdu, 1, 4)
    
	local head_seq = seq1 .. smHead
	log.output("\tSM:head_seq:" .. hex.hexify(head_seq))
    
    keyEnc = keyEnc .. string.sub(keyEnc, 1, 8)
    keySig = keySig .. string.sub(keySig, 1, 8)

    log.output("\tSM:keyEnc:" .. hex.hexify(keyEnc))
    log.output("\tSM:keySig:" .. hex.hexify(keySig))
    
    local calcMac = pad_iso9797_2(head_seq)
    log.output("\tSM:calcMac1:".. hex.hexify(calcMac))
    
	local datafield, doob = "", ""
	if (string.byte(apdu, 5) ~= 0 and string.len(apdu) > 5) then
		
		local toEnc = string.sub(apdu, 6, 5 + string.byte(apdu, 5))
		local toEncPadded = pad_iso9797_2(toEnc)
        log.output("\tSM:toEnc:" .. hex.hexify(toEnc))
        log.output("\tSM:toEncPadded:" .. hex.hexify(toEncPadded))

		local enc = sm.des3_enc(keyEnc, toEncPadded, true)
        log.output("\tSM:enc:" .. hex.hexify(enc))

        -- check INS: odd ins is 85, even ins is 87 + 0x01
		if (math.mod(string.byte(apdu, 1), 2) == 0) then
			doob = BUILD_TLV_BER("87", "\001" .. enc)
		else
			doob =  BUILD_TLV_BER("85", enc)
        end
        
		calcMac = calcMac .. doob
        datafield = datafield .. doob

        log.output("\tSM:calcMac2:" .. hex.hexify(calcMac))
	end
	if (string.byte(apdu, 5) == 0 and string.len(apdu) > 7) then
        -- extended APDU
        local apduLen = (string.byte(apdu, 6) * 256) + string.byte(apdu, 7)
		local toEnc = string.sub(apdu, 8, 7+ apduLen)
		local toEncPadded = pad_iso9797_2(toEnc);
        log.output("\tSM:toEncPadded:" .. hex.hexify(toEncPadded))
        
		local enc = sm.des3_enc(keyEnc, toEncPadded, true)
        log.output("\tSM:enc:" .. hex.hexify(enc))
        
        -- check INS: odd ins is 85, even ins is 87 + 0x01
		if (math.mod(string.byte(apdu, 1), 2) == 0) then
			doob = BUILD_TLV_BER("87", "\001" .. enc)
		else
			doob =  BUILD_TLV_BER("85", enc)
        end
		calcMac = calcMac .. doob
        datafield = datafield .. doob
        log.output("\tSM:calcMac3:" .. hex.hexify(calcMac))
	end
    
	if (string.len(apdu) == 5 or string.len(apdu) == (string.byte(apdu, 5) + 6)) then
        doob = BUILD_TLV_BER("97", string.sub(apdu, -1, -1) )

		calcMac = calcMac .. doob
        datafield = datafield .. doob
		log.output("\tSM:calcMac4:" .. hex.hexify(calcMac))
	end

    log.output("\tSM:calcMac:" .. hex.hexify(calcMac))
	
    local toMac = pad_iso9797_2(calcMac)
    log.output("\tSM:toMac:" .. hex.hexify(toMac))
    
    local mac = sm.des3_mac(keySig, toMac)
    log.output("\tSM:mac:" .. hex.hexify(mac))

    datafield = datafield .. BUILD_TLV_BER("8e", mac)

	local elabResp
    local dataLen = string.len(datafield)
	if (dataLen < 256) then
		elabResp = smHead .. hex.hexf("%P00", datafield)
	else
        elabResp = smHead .. hex.hexf("00%>%H%S0000", dataLen, datafield)
	end
    log.output("\tSM:elabResp:" .. hex.hexify(elabResp))

	return elabResp, seq1
end



local function respSM(keyEnc, keySig, resp, seq)
	log.output("\trespSM:keyEnc:" .. hex.hexify(keyEnc))
	log.output("\trespSM:keySig:" .. hex.hexify(keySig))
	log.output("\trespSM:resp:" .. hex.hexify(resp))
	log.output("\trespSM:seq:" .. hex.hexify(seq))
    
	local seq1 = inc_ssc(seq)
	log.output("\trespSM:seq1:" .. hex.hexify(seq1))
    
    
    keyEnc = keyEnc .. string.sub(keyEnc, 1, 8)
    keySig = keySig .. string.sub(keySig, 1, 8)
    
    local elabResp = ""
	local index, llen, lgn
	local sw = string.sub(resp, -2, -1)
	local encData;
	local respMac, calcMac

    resp = string.sub(resp, 1, -3)
    
	calcMac = seq1
	index = 0
	log.output("\trespSM:calcMac:" .. hex.hexify(calcMac))
    
    local TAG_99 = tonumber("99", 16)
    local TAG_8E = tonumber("8e", 16)
    local TAG_85 = tonumber("85", 16)
    local TAG_87 = tonumber("87", 16)
    
	repeat
        local TAG = string.byte(resp, index+1)
        log.output (string.format("\tTAG: %02X", TAG))
    
		if (TAG == TAG_99) then
        
            local swData = string.sub(resp, index+1, index + string.byte(resp, index + 2) + 2)
			calcMac = calcMac .. swData
			sw = string.sub(resp, index + 3, index + 4)
			index = index+ 4
            log.output ("\tSW:", hex.hexify(sw))
            log.output ("\tswData:", hex.hexify(swData))
		elseif (TAG == TAG_8E) then
            
        
			if (string.byte(resp, index + 2) ~= 8) then
				error( "Lunghezza del MAC non valida")
            end
			respMac = string.sub(resp, index+1 + 2, index + 2 + 8)
			index = index + 10
		
		elseif (TAG == TAG_85) then
        
			if (string.byte(resp, index + 2) > 128) then
				llen = string.byte(resp, index + 2) - 128
				if (llen == 1) then
					lgn = string.byte(resp, index + 3)
				else
                    if (llen == 2) then
						lgn = (string.byte(resp, index + 3)*256) +  string.byte(resp, index + 4)
					else 
						error(string.format("Lunghezza ASN1 non valida: %d", llen))
                    end
                end
				encData = string.sub(resp, index+1 + llen + 2, index + llen + 2 + lgn)
				calcMac = calcMac .. string.sub(resp, index+1, index+lgn + llen + 2)
				index = index + llen + lgn + 2
			
			else 
				encData = string.sub(resp, index+1 + 2, index + 2 + string.byte(resp, index + 2))
				calcMac = calcMac .. string.sub(resp, index+1, index+string.byte(resp, index + 2) + 2)
				index = index + string.byte( resp, index + 2) + 2
			end
		elseif (TAG == TAG_87) then
            
			if (string.byte(resp, index + 2) > 128) then
				llen = string.byte(resp, index + 2) - 128;
				if (llen == 1) then
					lgn = string.byte(resp, index + 3)
				else 
					if (llen == 2) then
						lgn = (string.byte(resp, index + 3)*256 ) + string.byte(resp, index + 4);
					else
						error (string.format("Lunghezza ASN1 non valida: %d", llen));
                    end
                end
				encData = string.sub(resp, index+1 + llen + 3, index + llen + 3 + lgn - 1);
				calcMac = calcMac .. string.sub(resp, index+1, index+lgn + llen + 2)
				index = index + llen + lgn + 2;

			else
				encData = string.sub(resp, index +1 + 3, index + 3 + string.byte(resp, index + 2) - 1)
				calcMac = calcMac .. (string.sub(resp, index+1, string.byte(resp, index + 2) + 2))
				index = index + string.byte(resp, index + 2) + 2
			end
		
		else
			error ("Tag non riconosciuto nella risposta in Secure Messaging");
        end
		-- log.output("\trespSM: calcMac N", hex.hexify(calcMac));
        log.output ("\tindex:" .. index)
	until (index >= string.len(resp))

	log.output("\trespSM: calcMac", hex.hexify(calcMac))
    local toMac = pad_iso9797_2(calcMac)
    local smMac = sm.des3_mac(keySig, toMac)
	log.output("\trespSM: smMac", hex.hexify(smMac) )
	log.output("\trespSM: respMac", hex.hexify(respMac) )

	assert(smMac == respMac)

	if (encData and string.len(encData) >0) then
		log.output("\trespSM: encData", hex.hexify(encData));

        elabResp = sm.des3_dec(keyEnc, encData)

		log.output("\trespSM: elabResp", hex.hexify(elabResp));
	
	else
		elabResp = ""
    end
	log.output("\trespSM: smMac", hex.hexify(elabResp));

	return sw, elabResp, seq1
end

local function parse_apdu(apdu)
    local header
    local LE = ""
    local data = ""
    local header = string.sub(apdu, 1, 4)
    local lc = string.byte(apdu, 5) or 0
    local data = string.sub(apdu, 6, -1)
    if string.len(apdu) == 4 then
        log.output("parse_apdu(): no data no LC")
        data=""
    elseif string.len(apdu) == 5 then
        LE = string.sub(apdu, -1, -1)
        log.output("parse_apdu(): no data, specified LE:", hex.hexify(LE))
        data=""
    elseif string.len(apdu) == 7 and lc == 0 then
        LE = string.sub(apdu, -2, -1)
        log.output("parse_apdu(): no data, specified extLE:", hex.hexify(LE))
        data=""
    else
        if lc == 0 and string.len(data) > 0 then
            lc = bin.unpack("%>%H", data)
            log.output("\tparse_apdu: data=", hex.hexify(data))
            log.output("\tparse_apdu: new LC=", lc)
            log.output("\tparse_apdu: len data=", string.len(data))
            assert(string.len(data) <= lc +4)
            if string.len(data) >= lc + 3 then
                LE = string.sub(data, lc+2-string.len(data), -1)
                log.output("\tparse_apdu: new LE=", hex.hexify(LE))
            end
            data = string.sub(data, 3, 3+lc-1)
            log.output("parse_apdu(): with extData, specified extLE:", hex.hexify(LE))
        elseif lc +1 == string.len(data) then
            LE = string.sub(data, -1, -1)
            log.output("parse_apdu(): with data, specified LE:", hex.hexify(LE))
            data = string.sub(data, 1, -2)
        end
    end
    return header, lc, data, LE
end

-- print(repr({parse_apdu(hex.hexf("00a40000"))}))
-- print(repr({parse_apdu(hex.hexf("00a4000000"))}))
-- print(repr({parse_apdu(hex.hexf("00a40000000000"))}))
-- print(repr({parse_apdu(hex.hexf("00a4000000FFFF"))}))
-- print(repr({parse_apdu(hex.hexf("00a4000000000201020000"))}))
-- print(repr({parse_apdu(hex.hexf("00a40000000100%SFFFF", string.rep("\3", 256) ))}))
-- print(repr({parse_apdu(hex.hexf("00a40000000200%SFFFF", string.rep("\3", 512) ))}))
-- print(repr({parse_apdu(hex.hexf("00a40000000200%SFF", string.rep("\3", 512) ))}))
-- os.exit(1)

function NXPIASSmartCard.mt:SMTX(ssc, KskEnc, KskSig, apdu, forceExtended)
    local extended
    local header, lc, data, LE = parse_apdu(apdu)

    extended = forceExtended or string.len(LE) > 1 or lc > 255
    local valid = true
    
    local encApdu, ssc = SM(KskEnc, KskSig, apdu, ssc)
    log.output( "\tSMTX: plainApdu: ", hex.hexify(apdu))
    log.output ("\tSMTX: encApdu SM:", hex.hexify(encApdu))
    log.output("\tssc:", hex.hexify(ssc))
     local resp, sw
    resp = self:transmit(encApdu)
    log.output ("\tSMTX: resp:", hex.hexify(resp))
    if string.len(resp) > 2 then
        sw, resp, ssc = respSM(KskEnc, KskSig, resp, ssc)
    else
        log.output("\tSMTX: got only SW...")
        sw = resp
        resp = ""
        valid = false
    end
    log.output("\tresp:", hex.hexify(resp))

    return resp .. sw, valid, ssc
end


function NXPIASSmartCard.mt:close_secure_channel()
    self.ActiveSM = false
    self._performed_mutual_auth = false
    self.ssc = nil
    self.sessENC = nil
    self.sessMAC = nil
    self._current_selected_aid = nil
end

function NXPIASSmartCard.mt:auto_perform_mutual_authenticate(checkOnActiveSMOnly)
    -- funzione fondamentale per per il corretto uso del secure messaging
    -- ha lo scopi di:
    -- 1) individuare una mutua autenticazione valida gi