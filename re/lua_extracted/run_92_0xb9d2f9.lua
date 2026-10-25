
    log.output('_search_related_key_object(): looking for existing related object...')
    local hObj
    local find_state = {}
    local pTemplateSearch = {
        [CKA.MODULUS]=modulus,
        [CKA.PUBLIC_EXPONENT]=pubExp,
        [CKA.CLASS]=class,
    }
    hObj = self:get_item(find_state, true, pTemplateSearch) -- can return private objects
    if hObj ~= 0 then
        log.output('_search_related_key_object(): existing related object found:', hObj)
        return hObj
    end
    return nil
end

function t.mt:create_object_pubkey(pTemplateOrig, keyReference, as_local)
    log.output('create_object_pubkey():', pTemplateOrig, "as_local:", as_local, "keyReference:", keyReference)
    
    -- keyReference: quando specificato crea una chiave pubblica associata ad una chiave privata
    local pTemplate = utility.clone_table(pTemplateOrig)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    if not pTemplate[CKA.MODULUS] or not pTemplate[CKA.PUBLIC_EXPONENT] then
        log.output('create_object_pubkey(): MODULUS or PUBLIC_EXPONENT not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    local is_ds = self:is_ds(pTemplate)
    
    local modulus_bits = string.len(pTemplate[CKA.MODULUS]) * 8
    if modulus_bits ~= 1024 and modulus_bits ~= 2048 then
        log.output('create_object_pubkey(): MODULUS size not 1024 or 2048!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    obj = GetPubKeyTemplate(t.mt.get_pubkey)
    obj.private = false
    obj.key_bits = modulus_bits
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if not pTemplate[k] and obj[k] and type(pTemplate[k]) == 'string' then
            obj[k] = pTemplate[k]
        end
    end
    obj[CKA.LOCAL] = eCK.BBOOL(as_local)

    local target = self:_get_key_target(is_ds, modulus_bits)
    if not target then
        log.output('create_object_pubkey(): unexpectred error detecting the key type and size!')
        return CKR.FUNCTION_FAILED
    end

    self:invalidate_xproc_cache()
    self.gemalto_hcard:auto_perform_mutual_authenticate()

    local usBin, KAuthId
    if not keyReference then
        local hObj
        if self.userType == CKU.USER then
            log.output('create_object_pubkey(): user logged in: searching if a private key sharing same modulus exists...')
            hObj = self:_search_related_key_object(
                pTemplate[CKA.MODULUS],
                pTemplate[CKA.PUBLIC_EXPONENT],
                eCK.ULONG(CKO.PRIVATE_KEY) )
        else
            log.output('create_object_pubkey(): user NOT logged in: unable to search a private key sharing same modulus...')
        end
        if hObj then
            objPriv = self.attributes[hObj]
            keyReference = objPriv.kid
        else
            log.output('create_object_pubkey(): allocating a keyReference for public key')
            usBin, keyReference, KAuthId = self:virtual_alloc_kid(
                    self._indexes._unused_space_bin,
                    target)
            if string.len(usBin) ~= string.len(self._indexes._unused_space_bin) then
                log.output('create_object_pubkey(): no more space left in unused space file!')
                return CKR.DEVICE_MEMORY
            end
            if not keyReference then
                log.output('create_object_pubkey(): no more keys left in unused space file!')
                return CKR.DEVICE_MEMORY
            end
            self.gemalto_hcard:import_private_key(keyReference,
                pTemplate[CKA.MODULUS],
                pTemplate[CKA.PUBLIC_EXPONENT])
        end
    end
    
    local label = pTemplate[CKA.LABEL] or ''
    local id = pTemplate[CKA.ID] or ''
    local modulusLength = modulus_bits
    local pubKDBin, objNum = self:virtual_add_public_key_object(
                                self._indexes._public_keys_bin,
                                label,
                                id,
                                keyReference,
                                obj.key_bits)
    if string.len(pubKDBin) ~= string.len(self._indexes._public_keys_bin) then
        log.output('create_object_pubkey(): no more space left in Public KD file!')
        return CKR.DEVICE_MEMORY
    end
    obj.num = objNum
    obj.kid = keyReference
    log.output(string.format("create_object_pubkey(): new obj num:%d kid:%d bits:%d", 
        obj.num, obj.kid, obj.key_bits) )

    if usBin then
        log.output('create_object_pubkey(): writing unused space...')
        self:_write_file(usBin, self.files.US)
        self._indexes._unused_space_bin = usBin
    end
    
    log.output('create_object_pubkey(): writing public key objects directory...')
    self:_write_file(pubKDBin, self.files.PubKD)
    self._indexes._public_keys_bin = pubKDBin
    
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    return CKR.OK, self.attributes.max_index
end

function t.mt:_get_key_target(is_ds, modulus_bits)
    local target
    if is_ds then
        if modulus_bits == 1024 then
            log.output('_get_key_target(): 1024 userConsent')
            target = self._keys_1024_uc
        else
            log.output('_get_key_target(): 2048 userConsent')
            target = self._keys_2048_uc
        end
    else
        if modulus_bits == 1024 then
            log.output('_get_key_target(): 1024 normal')
            target = self._keys_1024
        else
            log.output('_get_key_target(): 2048 normal')
            target = self._keys_2048
        end
    end
    return target
end

function t._is_private_attribute(attr_type)
    local private_attributes = {
        CKA.PRIVATE_EXPONENT,
        CKA.PRIME_1,
        CKA.PRIME_2,
        CKA.EXPONENT_1,
        CKA.EXPONENT_2,
        CKA.COEFFICIENT,
        CKA.PRIME,
        CKA.SUBPRIME,
        CKA.BASE,
    }
    for i, v in private_attributes do
        if attr_type == v then
            return true
        end
    end
    return false
end

function t.mt:create_object_privkey(pTemplateOrig)
    log.output('create_object_privkey()', pTemplateOrig)
    
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
            log.output('create_object_privkey(): all Private Key components must be specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local modulus_bits = string.len(pTemplate[CKA.MODULUS]) * 8
    if modulus_bits ~= 1024 and modulus_bits ~= 2048 then
        log.output('create_object_privkey(): MODULUS size not 1024 or 2048!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end

    local is_ds = self:is_ds(pTemplate)
    
    local target = self:_get_key_target(is_ds, modulus_bits)
    if not target then
        log.output('create_object_privkey(): unexpectred error detecting the key type and size!')
        return CKR.FUNCTION_FAILED
    end
    
    local usBin, keyReference, KAuthId
    
    self:invalidate_xproc_cache()
    self.gemalto_hcard:auto_perform_mutual_authenticate()

    
    log.output('create_object_privkey(): searching if a public key sharing same modulus exists...')
    local hObj = self:_search_related_key_object(
        pTemplate[CKA.MODULUS],
        pTemplate[CKA.PUBLIC_EXPONENT],
        eCK.ULONG(CKO.PUBLIC_KEY) )
    if hObj then
        objPriv = self.attributes[hObj]
        keyReference = objPriv.kid
        KAuthId = hex.hexf("%B", self.gemalto_hcard.BSO_PIN)
    else
        log.output('create_object_privkey(): allocating a keyReference for private key')
        usBin, keyReference, KAuthId = self:virtual_alloc_kid(
            self._indexes._unused_space_bin,
            target)
        if string.len(usBin) ~= string.len(self._indexes._unused_space_bin) then
            log.output('create_object_privkey(): no more space left in unused space file!')
            return CKR.DEVICE_MEMORY
        end
    end
    
    KAuthId = hex.hexf("%B", self.gemalto_hcard.BSO_PIN)
    local kdPriv, objNum = self:virtual_add_private_key_object(
                                self._indexes._private_keys_bin,
                                pTemplate[CKA.LABEL] or '',
                                pTemplate[CKA.ID] or '',
                                KAuthId,
                                keyReference,
                                modulus_bits)
    
    if string.len(kdPriv) ~= string.len(self._indexes._private_keys_bin) then
        log.output('create_object_privkey(): no more space left in Private KD file!')
        return CKR.DEVICE_MEMORY
    end
    
    if not keyReference then
        log.output('create_object_privkey(): no more space available for this type of object!')
        return CKR.DEVICE_MEMORY
    end
    
    obj = GetPrivKeyTemplate(t.mt.get_privkey)
    obj.private = true
    obj.key_bits = modulus_bits
    obj.kid = keyReference
    obj.num = objNum
    log.output(string.format("create_object_privkey(): new obj num:%d kid:%d bits:%d", 
        obj.num, obj.kid, obj.key_bits) )

    
    log.output('create_object_privkey(): importing key components...')
    self.gemalto_hcard:import_private_key(keyReference,
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

    obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(self:is_user_consent_key(obj.kid))

    if usBin then
        log.output('create_object_privkey(): writing unused space...')
        self:_write_file(usBin, self.files.US)
        self._indexes._unused_space_bin = usBin
    end
    
    
    log.output('create_object_privkey(): writin private key objects directory...')
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
    local rv, hPubk =  self:create_object_pubkey(pTemplatePub, keyReference, false)
    log.output('create_object_privkey(): create_object_pubkey() result:', rv, hPubk)
    
    
    return CKR.OK, hPriv
end

function t.mt:create_object_certificate(pTemplate)
    local usBin, index, FAuthId
    log.output('create_object_certificate()', pTemplate)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    if not pTemplate[CKA.VALUE] then
        log.output('create_object_certificate(): VALUE not specified!')
        return CKR.TEMPLATE_INCOMPLETE
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

    obj = GetCertTemplate(t.mt.get_certificate)
    obj.private = false
    obj.file = self.files.PubValues
    obj.path = {
            efidOrPath = self.files.PubValues_path,
            length = string.len(actual_cert_data)
    }
    usBin, index, FAuthId = self:virtual_alloc_space(
                            self._indexes._unused_space_bin,
                            obj.path.efidOrPath,
                            obj.path.length
                            )
    if string.len(usBin) ~= string.len(self._indexes._unused_space_bin) then
        log.output('create_object_certificate(): no more space left in unused space file!')
        return CKR.DEVICE_MEMORY
    end
    if not index then
        log.output('create_object_certificate(): no more public space available!')
        return CKR.DEVICE_MEMORY
    end
    obj.path.index = index
    
    local HolderCD, objNum = self:virtual_add_cert_object(
        self._indexes._certificates_bin,
        pTemplate[CKA.LABEL] or '',
        pTemplate[CKA.ID] or '',
        obj.path.efidOrPath,
        index, obj.path.length)
    
    if string.len(HolderCD) ~= string.len(self._indexes._certificates_bin) then
        log.output('create_object_certificate(): no more space left in Certificate Holder Directory file!')
        return CKR.DEVICE_MEMORY
    end
    
    obj.num = objNum
    log.output(string.format("create_object_pubkey(): new obj num:%d", 
        obj.num) )
        
    self:invalidate_xproc_cache()
    self.gemalto_hcard:auto_perform_mutual_authenticate()


    -- scrive il certificato
    self:_write_file(actual_cert_data, obj.file, index)
    
    -- scrive unused space
    if usBin then
        self:_write_file(usBin, self.files.US)
        self._indexes._unused_space_bin = usBin
    end
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

    return CKR.OK, self.attributes.max_index
end


function t.mt:generate_key_pair(pMechanism, templatePub, templatePriv)
    local usBin, keyReference, KAuthId
    log.output('generate_key_pair()', templatePub, templatePriv)
    if self.userType ~= CKU.USER then
        log.output('generate_key_pair(): not loggen in, userType', self.userType)
        return CKR.USER_NOT_LOGGED_IN
    end
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
    
    templatePub1[CKA.LOCAL] = eCK.BBOOL(true)
    templatePriv1[CKA.LOCAL] = eCK.BBOOL(true)
    
    templatePriv1[CKA.SIGN] = templatePriv1[CKA.SIGN] or eCK.BBOOL(true)
    templatePriv1[CKA.DECRYPT] = templatePriv1[CKA.DECRYPT] or eCK.BBOOL(true)
    
    templatePriv1[CKA.CLASS] = eCK.ULONG(CKO.PRIVATE_KEY)
    templatePriv1[CKA.KEY_TYPE] = eCK.ULONG(CKK.RSA)

    local isds, ds_slot = self:is_ds(templatePub1)
    
    local cka_modulus_bits = templatePub1[CKA.MODULUS_BITS] or templatePriv1[CKA.MODULUS_BITS] or eCK.ULONG(1024)
    local modulus_bits = 1024    
    if not cka_modulus_bits or cka_modulus_bits == eCK.ULONG(1024) then
        modulus_bits = 1024
    elseif cka_modulus_bits == eCK.ULONG(2048) then
        modulus_bits = 2048
        if iscns then
            log.output('generate_key_pair(): key size invalid for selected filesystem:', hex.hexify(cka_modulus_bits) )
            return CKR.ATTRIBUTE_VALUE_INVALID
        end
    else
        log.output('generate_key_pair(): key size invalid for selected filesystem:', hex.hexify(cka_modulus_bits or '') )
        return CKR.ATTRIBUTE_VALUE_INVALID    
    end
   
    objPriv = GetPrivKeyTemplate(t.mt.get_privkey)
    objPriv.private = true
    objPriv.key_bits = modulus_bits
    
    self:invalidate_xproc_cache()
    self.gemalto_hcard:auto_perform_mutual_authenticate()
    local target = self:_get_key_target(isds, modulus_bits)
  
    if not target then
        log.output('generate_key_pair(): unexpectred error detecting the key type and size!')
        return CKR.FUNCTION_FAILED
    end
    usBin, keyReference, KAuthId = self:virtual_alloc_kid(
        self._indexes._unused_space_bin,
        target)
    if string.len(usBin) ~= string.len(self._indexes._unused_space_bin) then
        log.output('generate_key_pair(): no more space left in unused space file!')
        return CKR.DEVICE_MEMORY
    end

    local kdPriv, objNum = self:virtual_add_private_key_object(
        self._indexes._private_keys_bin,
        templatePriv1[CKA.LABEL] or '',
        templatePriv1[CKA.ID] or '',
        KAuthId, keyReference, modulus_bits)
    
    if string.len(kdPriv) ~= string.len(self._indexes._private_keys_bin) then
        log.output('generate_key_pair(): no more space left in Private KD file!')
        return CKR.DEVICE_MEMORY
    end
    
    if not keyReference then
        log.output('generate_key_pair(): no more space available for this type of object!')
        return CKR.DEVICE_MEMORY
    end

    objPriv.kid = keyReference
    objPriv.num = objNum
    log.output(string.format("generate_key_pair(): new obj num:%d kid:%d bits:%d", 
        objPriv.num, objPriv.kid, objPriv.key_bits) )
    
    self.gemalto_hcard:auto_perform_mutual_authenticate()
    log.output('generate_key_pair(): verify_pin_main() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.gemalto_hcard:verify_pin_main(self.cached_main_pin, false, false, true)  -- pin, ispuk, check, use_sm
    end
    
    log.output('generate_key_pair(): generating key pair...')
    self.gemalto_hcard:generate_key_pair(keyReference, true)
    local modulus, pubExp = self.gemalto_hcard:read_public_key(keyReference, true)
    templatePub1[CKA.MODULUS] = modulus
    templatePub1[CKA.PUBLIC_EXPONENT] = pubExp
    templatePub1[CKA.CLASS] = eCK.ULONG(CKO.PUBLIC_KEY)
    templatePub1[CKA.KEY_TYPE] = eCK.ULONG(CKK.RSA)
    templatePub1[CKA.TOKEN] = eCK.BBOOL(true)

    templatePriv1[CKA.MODULUS] = modulus        -- cache preventiva
    templatePriv1[CKA.PUBLIC_EXPONENT] = pubExp
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if templatePriv1[k] and not t._is_private_attribute(k) then
            objPriv[k] = templatePriv1[k]
        end
    end

    objPriv[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(self:is_user_consent_key(objPriv.kid))
    
    
    
    
    if usBin then
        log.output('generate_key_pair(): writing unused space...')
        self._indexes._unused_space_bin = usBin
        self:_write_file(usBin, self.files.US)
    end

    if kdPriv then
        log.output('generate_key_pair(): writin private key objects directory...')
        self:_write_file(kdPriv, self.files.PrivKD)
        self._indexes._private_keys_bin = kdPriv
    end
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPriv
    local hPrivk = self.attributes.max_index
    
    local rv, hPubk = self:create_object_pubkey(templatePub1, keyReference, true)
    log.output('create_object(pubkey): result:', rv, 'handle:', hPubk)
    
    log.output('generate_key_pair(): success, returning', hPubk, hPrivk)
    
    self:update_free_mem(self.info)
    return CKR.OK, hPubk, hPrivk
end

function t.mt:create_object_data(pTemplate)
    local usBin, index, FAuthId
    log.output('create_object_data()', pTemplate)
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    local dataValue = pTemplate[CKA.VALUE] or '\000'

    obj = GetDataObjectTemplate(t.mt.get_data_object)
    obj.private = pTemplate[CKA.PRIVATE] and pTemplate[CKA.PRIVATE] ~= eCK.BBOOL(false)
    obj.path = {length=string.len(dataValue)}
    local target_data_file
    local target_dir_file
    if obj.private then
      
        obj.file = self.files.PrivValues
        target_dir_file = self.files.DCODF_Priv
        obj.path.efidOrPath = self.files.PrivValues_path
    else
        obj.file = self.files.PubValues
        target_dir_file = self.files.DCODF_Pub
        obj.path.efidOrPath = self.files.PubValues_path
    end
    
    usBin, index, FAuthId = self:virtual_alloc_space(
                            self._indexes._unused_space_bin,
                            obj.path.efidOrPath,
                            obj.path.length
                            )
    if string.len(usBin) ~= string.len(self._indexes._unused_space_bin) then
        log.output('create_object_data(): no more space left in unused space file!')
        return CKR.DEVICE_MEMORY
    end
    if not index then
        log.output('create_object_data(): no more space available!')
        return CKR.DEVICE_MEMORY
    end
    obj.path.index = index
    
    local data_bin, objNum

    FAuthId = hex.hexf("%B", self.gemalto_hcard.BSO_PIN)
    if obj.private then
        data_bin, objNum = self:virtual_add_private_data_object(
                self._indexes._private_data_objects_bin,
                pTemplate[CKA.LABEL] or '',
                pTemplate[CKA.APPLICATION] or '',
                FAuthId or hex.hexf("%B", self.gemalto_hcard.BSO_PIN),
                obj.path.efidOrPath,
                index, obj.path.length)
        if string.len(data_bin) ~= string.len(self._indexes._private_data_objects_bin) then
            log.output('create_object_data(): no more space left in Private Data Directory file!')
            return CKR.DEVICE_MEMORY
        end

    else
        data_bin, objNum = self:virtual_add_data_object(
            self._indexes._data_objects_bin,
            pTemplate[CKA.LABEL] or '',
            pTemplate[CKA.APPLICATION] or '',
            obj.path.efidOrPath,
            index, obj.path.length)
        if string.len(data_bin) ~= string.len(self._indexes._data_objects_bin) then
            log.output('create_object_data(): no more space left in Public Data Directory file!')
            return CKR.DEVICE_MEMORY
        end
    end

    obj.num = objNum
    log.output(string.format("create_object_data(): new obj num:%d", 
        obj.num) )
    self:invalidate_xproc_cache()
    self.gemalto_hcard:auto_perform_mutual_authenticate()

    -- scrive il data object
    self:_write_file(dataValue, obj.file, index)

    if usBin then
        -- scrive unused space
        self:_write_file(usBin, self.files.US)
        self._indexes._unused_space_bin = usBin
    end
    
    if data_bin then
        -- scrive certificate directory file
        self:_write_file(data_bin, target_dir_file)
        if obj.private then
            self._indexes._private_data_objects_bin = data_bin
        else
            self._indexes._data_objects_bin = data_bin
        end
    end
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] then
            obj[k] = pTemplate[k]
        end
    end
    
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj

    return CKR.OK, self.attributes.max_index
end


function t.mt:create_object(pTemplate)
    log.output('create_object(): verify_pin_main() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.gemalto_hcard:verify_pin_main(self.cached_main_pin, false, false, true)  -- pin, ispuk, check, use_sm
    end
    
    if pTemplate[CKA.PRIVATE]
        and pTemplate[CKA.PRIVATE] ~= eCK.BBOOL(false)
        and self.userType ~= CKU.USER then
        log.output('create_object(): not logged in: login required to create private objects')
    end

    local rv, hObj
    
    self:invalidate_xproc_cache()
    
    if pTemplate[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        rv, hObj = self:create_object_pubkey(pTemplate)
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        rv, hObj = self:create_object_privkey(pTemplate)
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        rv, hObj = self:create_object_certificate(pTemplate)
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        rv, hObj = self:create_object_data(pTemplate)        
        
    else
        log.output('create_object(): unsupported object class:', hex.hexify(pTemplate[CKA.CLASS] or ''))
        rv = CKR.ATTRIBUTE_VALUE_INVALID
    end
    if rv == CRK_OK then
        self:update_free_mem(self.info)
    end
    return rv, hObj
end

function t.mt:_renumber_objects(objRef)
    local obj
    for i=self.attributes.min_index, self.attributes.max_index do
        obj = self.attributes[i]
        if type(obj) == "table" 
            and obj[CKA.CLASS] == objRef[CKA.CLASS]
            and obj.private == objRef.private 
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
    log.output('destroy_object(): ', hObject)
    
    
    log.output('destroy_object(): verify_pin_main() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.gemalto_hcard:verify_pin_main(self.cached_main_pin, false, false, true)  -- pin, ispuk, check, use_sm
    end
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hObject]
    
    if obj == nil then return CKR.OBJECT_HANDLE_INVALID end
    
    if obj.private then
        if self.userType ~= CKU.USER then
            return CKR.USER_NOT_LOGGED_IN
        end    
    end
    
    self:invalidate_xproc_cache()
    self.gemalto_hcard:auto_perform_mutual_authenticate()
        
    if obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        local usBin
        log.output('destroy_object(): destroyng a certificate')
        -- rimuove la entry indicata da "obj.num" dall'index
        local d = p15.parseCertDF(self._indexes._certificates_bin)
        if obj.num > table.getn(d) then
            log.output('destroy_object(): obj.num invalid:', obj.num)
            return CKR.FUNCTION_FAILED
        end
        table.remove(d, obj.num)
        local HolderCD = p15.buildCertDF(d)
        HolderCD = HolderCD .. string.rep("\000", string.len(self._indexes._certificates_bin) - string.len(HolderCD))
        
        -- libera lo spazio allocato
        usBin = self:virtual_release_space(
                            self._indexes._unused_space_bin,
                            obj.path.efidOrPath,
                            obj.path.index,
                            obj.path.length)
                                            
        -- riscrive gli indici:
        
        if string.len(usBin) ~= string.len(self._indexes._unused_space_bin) then
            log.output(
                'destroy_object(): CRITICAL WARNING: no more space left in the unused space file. following Space is lost:',
                    hex.hexify(obj.path.efidOrPath),
                    obj.path.index,
                    obj.path.length)
            usBin = self._indexes._unused_space_bin
        else
            -- scrive unused space
            self:_write_file(usBin, self.files.US)
        end
        -- azzera lo spazio occupato
        -- self:_write_file(string.rep("\000", obj.path.length), obj.file, obj.path.index)
        
        -- scrive certificate directory file
        self:_write_file(HolderCD, self.files.CDF)

        self._indexes._certificates_bin = HolderCD
        self._indexes._unused_space_bin = usBin
        
        -- elimina l'oggetto dalla lista
        self.attributes[hObject] = nil
        
        -- rinumera tutti gli oggetti certificate con num > obj.num
        self:_renumber_objects(obj)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        log.output('destroy_object(): destroyng a public key')
        -- rimuove la entry indicata da "obj.num" dall'index
        local usBin, pkBin
        local d = p15.parsePubPrivKD(self._indexes._public_keys_bin)
        if obj.num > table.getn(d) then
            log.output('destroy_object(): obj.num invalid:', obj.num)
            return CKR.FUNCTION_FAILED
        end
        table.remove(d, obj.num)
        pkBin = p15.buildPubPrivKD(d)
        pkBin = pkBin .. string.rep("\000", string.len(self._indexes._public_keys_bin) - string.len(pkBin))

        -- cerca la chiave privata associata tramite la key reference: se non c'