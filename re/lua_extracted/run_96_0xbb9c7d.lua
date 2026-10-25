
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

    
    self:invalidate_xproc_cache()

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

            log.output('create_object_privkey(): allocating a keyReference for private key')
            keyReference = self:_look_for_free_kid()
            if not keyReference then
                log.output('create_object_pubkey(): no more key id left!')
                return CKR.DEVICE_MEMORY
            end
            if string.len(usBin) ~= string.len(self._indexes._unused_space_bin) then
                log.output('create_object_privkey(): no more space left in unused space file!')
                return CKR.DEVICE_MEMORY
            end

            log.output('create_object_pubkey(): importing key components...')
            self.aet_hcard:import_private_key(
                    keyReference,
                    self.files.IPF,
                    pTemplate[CKA.MODULUS],
                    pTemplate[CKA.PUBLIC_EXPONENT]
                    )
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

    
    local usBin, keyReference, KAuthId
    
    self:invalidate_xproc_cache()
    
    log.output('create_object_privkey(): searching if a public key sharing same modulus exists...')
    local hObj = self:_search_related_key_object(
        pTemplate[CKA.MODULUS],
        pTemplate[CKA.PUBLIC_EXPONENT],
        eCK.ULONG(CKO.PUBLIC_KEY) )
    if hObj then
        objPriv = self.attributes[hObj]
        keyReference = objPriv.kid
        KAuthId = hex.hexf("%B", self.aet_hcard.BSO_PIN)
    else
        log.output('create_object_privkey(): allocating a keyReference for private key')
        keyReference = self:_look_for_free_kid()
        if not keyReference then
            log.output('create_object_privkey(): no more key id left!')
            return CKR.DEVICE_MEMORY
        end
    end
    
    KAuthId = hex.hexf("%B", self.aet_hcard.BSO_PIN)
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
    self.aet_hcard:import_private_key(
            keyReference,
            self.files.IPF,
            pTemplate[CKA.MODULUS],
            pTemplate[CKA.PUBLIC_EXPONENT],
            pTemplate[CKA.PRIVATE_EXPONENT]
            )
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] and not t._is_private_attribute(k) then
            obj[k] = pTemplate[k]
        end
    end

    obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)

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
    log.output(string.format("create_object_certificate(): new obj num:%d", 
        obj.num) )
        
    self:invalidate_xproc_cache()

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

    log.output('create_object_certificate(): finished. New Handle:', self.attributes.max_index)
    return CKR.OK, self.attributes.max_index
end


function t.mt:_look_for_free_kid()
    log.output('_look_for_free_kid()')
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local free_ids = {}
    for j, k in self._keys_1024 do
        free_ids[k] = true
    end
    for i=self.attributes.min_index, self.attributes.max_index do
        local obj = self.attributes[i]
        if type(obj) == "table" and type(obj.kid) == "number" then
            log.output('_look_for_free_kid(): kid ', obj.kid, "in use by handle:", i)
            free_ids[obj.kid] = nil -- key id occupato
        end
    end
    log.output('_look_for_free_kid(): available KIDs:', repr(free_ids) )
    for j, k in self._keys_1024 do
        if free_ids[k] then
            log.output('_look_for_free_kid(): returning:', k)
            return k
        end
    end
    return nil
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

    local cka_modulus_bits = templatePub1[CKA.MODULUS_BITS] or templatePriv1[CKA.MODULUS_BITS] or eCK.ULONG(1024)
    local modulus_bits
    if not cka_modulus_bits or cka_modulus_bits == eCK.ULONG(1024) then
        modulus_bits = 1024
    else
        log.output('generate_key_pair(): key size invalid for selected filesystem:', hex.hexify(cka_modulus_bits or '') )
        return CKR.ATTRIBUTE_VALUE_INVALID    
    end
   
    objPriv = GetPrivKeyTemplate(t.mt.get_privkey)
    objPriv.private = true
    objPriv.key_bits = modulus_bits
    
    self:invalidate_xproc_cache()
    
    KAuthId = hex.hexf("%B", self.aet_hcard.BSO_PIN)
    keyReference = self:_look_for_free_kid()

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
    
    log.output('generate_key_pair(): verify_pin_main() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.aet_hcard:verify_pin_main(self.cached_main_pin, false, false)  -- pin, ispuk, check
    end
    
    log.output('generate_key_pair(): generating key pair...')
    self.aet_hcard:generate_key_pair(keyReference, self.files.IPF)
    local modulus, pubExp = self.aet_hcard:read_public_key(keyReference)
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

    objPriv[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
    
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
    obj.file = self.files.PubValues
    target_dir_file = self.files.DCODF_Pub
    obj.path.efidOrPath = self.files.PubValues_path
    
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

    FAuthId = hex.hexf("%B", self.aet_hcard.BSO_PIN)
    data_bin, objNum = self:virtual_add_data_object(
        self._indexes._data_objects_bin,
        pTemplate[CKA.LABEL] or '',
        pTemplate[CKA.APPLICATION] or '',
        obj.path.efidOrPath,
        index, obj.path.length,
        pTemplate
        )
    if string.len(data_bin) ~= string.len(self._indexes._data_objects_bin) then
        log.output('create_object_data(): no more space left in Public Data Directory file!')
        return CKR.DEVICE_MEMORY
    end

    obj.num = objNum
    log.output(string.format("create_object_data(): new obj num:%d", 
        obj.num) )
    self:invalidate_xproc_cache()
    

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
        self._indexes._data_objects_bin = data_bin
    end
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] then
            obj[k] = pTemplate[k]
        end
    end
    
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj

    log.output('create_object_data(): new handle:', self.attributes.max_index)
    log.output('')
    return CKR.OK, self.attributes.max_index
end


function t.mt:create_object(pTemplate)
    log.output('create_object(): verify_pin_main() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.aet_hcard:verify_pin_main(self.cached_main_pin, false, false, true)  -- pin, ispuk, check, use_sm
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
    log.output('_renumber_objects(): objRef.num', objRef.num)
    for i=self.attributes.min_index, self.attributes.max_index do
        obj = self.attributes[i]
        if type(obj) == "table" 
            and obj[CKA.CLASS] == objRef[CKA.CLASS]
            and (obj.private == objRef.private or obj[CKA.CLASS] == eCK.ULONG(CKO.DATA))
            and obj.num and objRef.num 
            and obj.num > objRef.num then
            
            log.output('_renumber_objects(): obj.num will be decremented', obj.num)
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
        self.aet_hcard:verify_pin_main(self.cached_main_pin, false, false, true)  -- pin, ispuk, check, use_sm
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
    
        
    if obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        local usBin
        log.output('destroy_object(): destroyng a certificate')
        -- rimuove la entry indicata da "obj.num" dall'index
        local d = p15.parseCertDF(self._indexes._certificates_bin)
        if obj.num > table.getn(d) then
            log.output('destroy_object(): obj.num invalid:', obj.num, "max:", table.getn(d))
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
            log.output('destroy_object(): obj.num invalid:', obj.num, "max:", table.getn(d))
            return CKR.FUNCTION_FAILED
        end
        table.remove(d, obj.num)
        pkBin = p15.buildPubPrivKD(d)
        pkBin = pkBin .. string.rep("\000", string.len(self._indexes._public_keys_bin) - string.len(pkBin))

        if pkBin then
            -- scrive public key directory file
            self:_write_file(pkBin, self.files.PubKD)
            self._indexes._public_keys_bin = pkBin
        end
        
        -- elimina l'oggetto dalla lista
        self.attributes[hObject] = nil
        
        -- rinumera tutti gli oggetti public key con num > obj.num
        self:_renumber_objects(obj)

    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        log.output('destroy_object(): destroyng a private key')
        -- rimuove la entry indicata da "obj.num" dall'index
        local usBin, pkBin
        local d = p15.parsePubPrivKD(self._indexes._private_keys_bin)
        if obj.num > table.getn(d) then
            log.output('destroy_object(): obj.num invalid:', obj.num, "max:", table.getn(d))
            return CKR.FUNCTION_FAILED
        end
        table.remove(d, obj.num)
        pkBin = p15.buildPubPrivKD(d)
        pkBin = pkBin .. string.rep("\000", string.len(self._indexes._private_keys_bin) - string.len(pkBin))

        if pkBin then
            -- scrive private key directory file
            self:_write_file(pkBin, self.files.PrivKD)
            self._indexes._private_keys_bin = pkBin
        end
        
        -- elimina l'oggetto dalla lista
        self.attributes[hObject] = nil
        
        -- rinumera tutti gli oggetti private key con num > obj.num
        self:_renumber_objects(obj)

        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        log.output('destroy_object(): destroyng a data object')
        local index_bin, index_file, authId
        local dataBin
        local usBin
        index_bin = self._indexes._data_objects_bin
        index_file = self.files.DCODF_Pub
        
        -- rimuove la entry indicata da "obj.num" dall'index
        local d = p15.parsePubPrivDataD(index_bin)
        if obj.num > table.getn(d) then
            log.output('destroy_object(): obj.num invalid:', obj.num, "max:", table.getn(d))
            return CKR.FUNCTION_FAILED
        end
        table.remove(d, obj.num)
        dataBin = p15.buildPubPrivDataD(d)
        dataBin = dataBin .. string.rep("\000", string.len(index_bin) - string.len(dataBin))
        
        -- libera lo spazio allocato
        usBin = self:virtual_release_space(
                                self._indexes._unused_space_bin,
                                obj.path.efidOrPath,
                                obj.path.index,
                                obj.path.length,
                                authId)
                                            
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
            self._indexes._unused_space_bin = usBin
        end
        -- azzera lo spazio occupato
        -- self:_write_file(string.rep("\000", obj.path.length), obj.file, obj.path.index)
        
        
        if dataBin then
            -- scrive data object directory file
            self:_write_file(dataBin, index_file)

            self._indexes._data_objects_bin = dataBin
        end
        
        -- elimina l'oggetto dalla lista
        self.attributes[hObject] = nil
        
        -- rinumera tutti gli oggetti data con num > obj.num
        self:_renumber_objects(obj)
            
    else
        log.output('destroy_object(): WARNING! Unsupported object class!')
        return CKR.FUNCTION_FAILED
    end
    
    self.attributes[hObject] = nil
    
    self:update_free_mem(self.info)
    return CKR.OK
end

function t.mt:set_attribute_value(hObject, pTemplate)
    log.output('set_attribute_value():', hObject)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local rv
    local obj = self.attributes[hObject]
    if obj == nil then
        log.output('set_attribute_value(): specified handle invalid: ', hObject)
        return CKR.OBJECT_HANDLE_INVALID
    end

    log.output('set_attribute_value(): verify_pin_main() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.aet_hcard:verify_pin_main(self.cached_main_pin, false, false, true)  -- pin, ispuk, check, use_sm
    end
    
    self:invalidate_xproc_cache()
    
    if obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        if not obj.populated then self:get_pubkey(hObject, CKA.CLASS, false, true) end
        rv = self:set_attribute_value_pubkey(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        if not obj.populated then self:get_privkey(hObject, CKA.CLASS) end
        rv = self:set_attribute_value_privkey(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        if not obj.populated then self:get_certificate(hObject, CKA.CLASS, false, true) end
        rv = self:set_attribute_value_certificate(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        if not obj.populated then self:get_data_object(hObject, CKA.CLASS) end
        rv = self:set_attribute_value_data(hObject, pTemplate)        
        
    else
        log.output('set_attribute_value(): unsupported object class:', hex.hexify(obj[CKA.CLASS]))
        rv = CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    if rv == CRK_OK then
        self:update_free_mem(self.info)
    end
    return rv
    
end

function t.mt:set_attribute_value_privkey(hObj, pTemplate)
    log.output('set_attribute_value_privkey()')
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
        log.output('set_attribute_value_privkey(): error: invalid obj.num:', obj.num)
        return CKR.FUNCTION_FAILED
    end
    if pTemplate[CKA.LABEL] or pTemplate[CKA.ID] then
        local v = fs[obj.num]
        v.commonObjectAttributes.label = pTemplate[CKA.LABEL] or v.commonObjectAttributes.label
        v.classAttributes.iD = pTemplate[CKA.ID] or v.classAttributes.iD
        local privKDBin = p15.buildPubPrivKD(fs)
        privKDBin = privKDBin .. string.rep("\000", string.len(self._indexes._private_keys_bin) - string.len(privKDBin))
        if string.len(privKDBin) ~= string.len(self._indexes._private_keys_bin) then
            log.output('set_attribute_value_privkey(): no more space left in Private KD file!')
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
    log.output('set_attribute_value_certificate()')
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

    local rv = self:destroy_object(hObj)
    if rv ~= CKR.OK then
        log.output("set_attribute_value_certificate(): error deleting the old object!")
        return rv
    end
    local rv, hNewObj = self:create_object_certificate(templateNew)
    
    local newObj = self.attributes[hNewObj]
    self.attributes[hObj] = newObj
    self.attributes[hNewObj] = nil
    
    return CKR.OK
end


function t.mt:set_attribute_value_pubkey(hObj, pTemplate)
    log.output('set_attribute_value_pubkey()')
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
        log.output('set_attribute_value_pubkey(): error: invalid obj.num:', obj.num)
        return CKR.FUNCTION_FAILED
    end
    if pTemplate[CKA.LABEL] or pTemplate[CKA.ID] then
        local v = fs[obj.num]
        v.commonObjectAttributes.label = pTemplate[CKA.LABEL] or v.commonObjectAttributes.label
        v.classAttributes.iD = pTemplate[CKA.ID] or v.classAttributes.iD
        local pubKDBin = p15.buildPubPrivKD(fs)
        pubKDBin = pubKDBin .. string.rep("\000", string.len(self._indexes._public_keys_bin) - string.len(pubKDBin))
        if string.len(pubKDBin) ~= string.len(self._indexes._public_keys_bin) then
            log.output('set_attribute_value_pubkey(): no more space left in Public KD file!')
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



function t.mt:set_attribute_value_data(hObj, pTemplate)
    log.output('set_attribute_value_data()')
    local obj = self.attributes[hObj]
    
    -- implementato come re-create: cancella il vecchio oggetto e lo ricrea coi nuovi attributi
    
    if obj.private and self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    
    for k, v in pTemplate do
        if k ~= CKA.OBJECT_ID and k ~= CKA.LABEL and k ~= CKA.APPLICATION
            and k ~= CKA.VALUE
            and k ~= CKA.MODIFIABLE then
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
    
    local rv = self:destroy_object(hObj)
    if rv ~= CKR.OK then
        log.output("set_attribute_value_data(): error deleting the old object!")
        return rv
    end
    local rv, hNewObj = self:create_object_data(templateNew)
    
    local newObj = self.attributes[hNewObj]
    self.attributes[hObj] = newObj
    self.attributes[hNewObj] = nil
    
    return CKR.OK
    
end


function t.mt:get_object_size(hobj)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj == nil then return CKR.OBJECT_HANDLE_INVALID end
    local oSize = -1
    
    if obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        oSize = (obj.path and obj.path.length) or -1
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        oSize = 130*4
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        oSize = 130*4
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        oSize = (obj.path and obj.path.length) or -1
    end
    
    return CKR.OK, oSize
end


function t.mt:get_special_ids(id_class)
    if id_class == 'DS' then
        local ids = {}
        return ids
    end
end


function t.mt:valid()
    local rv = self.aet_hcard:valid()
    if not rv then
        utility.forget_token_changed(self, "cache")
    end
    return rv
end


function t.mt:flush_cache()
    if self.cfg["xproc"] ~= "true" then
        return false
    end
    local changed, cache_id
    if self._cache_id == nil then
        changed, self._cache_id = utility.has_token_changed(self, "cache", 0)
        log.output("token-aet:flush_cache(): initialize: _cache_id:", self._cache_id)
    end
    changed, cache_id = utility.has_token_changed(self, "cache", self._cache_id)
    if changed then
        log.output("token-aet:flush_cache(): token has changed!")
        self._cache_id = cache_id
        self.info = nil -- rimuove cache oggetti
        self._indexes = nil
        self._private_objects_added = false
        self.attributes = nil
        
        log.output("token-aet:flush_cache(): rebuilding object's cache")
        self.attributes = self:get_objects()  -- riscostruisce cache oggetti
    end
    return changed, self._cache_id
end

function t.mt:invalidate_xproc_cache()
    if self.cfg["xproc"] ~= "true" then
        return
    end
    self._cache_id = utility.set_token_changed(self, "cache")
end


return t


--===========================================================================
end
}
_LOADED['token-piv'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- token-piv.lua
local hex = require 'hex'
local hexf = hex.hexf
local der = require 'der'
local utility = require 'utility'
local repr = utility.repr
local rsa = require 'rsa'
local zlib = require 'zlib'
local rsa = require 'rsa'
local aes = require 'aes'

local licensing = require 'licensing'

local Smartcard = {}
Smartcard.mt = {}
Smartcard.mt.__index = Smartcard.mt

local SmartcardError = {}
SmartcardError.mt = {}
SmartcardError.mt.__index = SmartcardError.mt

function SmartcardError.mt.__tostring(e)
    return "SmartcardError: " .. (e.msg or '') .. ' ;SW=' .. hex.hexify(e.sw or '') 
end

function SmartcardError.new(sw, msg)
    local e = msg .. ' ;sw=' .. hex.hexify(sw or '')
    return e
end

local tag_53 = tonumber("53", 16)
local tag_70 = tonumber("70", 16)
local tag_71 = tonumber("71", 16)
local tag_72 = tonumber("72", 16)
local tag_73 = tonumber("73", 16)
local tag_C0 = tonumber("C0", 16)
local tag_C1 = tonumber("C1", 16)
local tag_C2 = tonumber("C2", 16)
local tag_CF = tonumber("CF", 16)

function Smartcard.new(card)
    local self = {
            kmc = hex.hexf("101112131415161718191A1B1C1D1E1F"),
            piv_admin_key_des3 = hex.hexf("101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f"), -- key test, kosovo PIVs
            piv_admin_key_prod = hex.hexf("915" .. "75C" .. "B26A" .. "E24" .. "3A2" .. "47C" .. "D0" .. "812" .. "087D9" .. "0D16" .. "600" .. "CAF" .. "677" .. "E6A" .. "0CC" .. "A0DC" .. "BB5" .. "DC" .. "B2B" .. "B6" .. "87"),
            piv_admin_key_test = hex.hexf("101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f"),
            select_aid_PIV = hex.hexf("00A404000BA00000030800001000010000"),
            GP_Initialize_for_Update = hex.hexf("8050000008"),  -- ( key version 0, key identifier 0, host challenge= 00 00 00 00 00 00 00 00 )
            Get_Data_Admin_diversify = hex.hexf("00CB3FFF035C01CF00"),
            host_challenge = hex.hexf('0000000000000000'),
            partial_external_auth = hex.hexf('8482010010'),
            select_aid_GP_Issuer_Security_Domain = hex.hexf("00a4040007a000000151000000"),
            XOR_MASK_1 = hex.hexf('0182' .. string.rep('00', 14)),
            XOR_MASK_2 = hex.hexf('0101' .. string.rep('00', 14)),
          }
    self.card = card
    self.piv_admin_key = self.piv_admin_key_prod
    setmetatable(self, Smartcard.mt)
    return self
end


local function xor_strings(a, b)
    assert(string.len(a) == string.len(b))
    local res = {}
    for i=1,string.len(a) do
        table.insert(res, (bin.flags(string.byte(a, i)) ^ bin.flags(string.byte(b, i))).asnumber )
    end
    return string.char(unpack(res))
end

function Smartcard.mt:valid()
    local status, err = self.card:status()
    if not status then
        log.output('Smartcard:valid(): status() error', hex.tohex8(err or 0))
        return false
    elseif status.protocol == 0 or string.len(status.atr or '') == 0 then
        log.output('Smartcard:valid(): card removed?')
        return false
    end
    return true
end


function Smartcard.mt:encrypt(nonce)
    log.output("encrypt(): nonce:", hex.hexify(nonce))
    local nonce_enc = sm.des3_enc(string.sub(self.piv_admin_key_des3, 1, 24), nonce)
    log.output("encrypt(): nonce_enc:", hex.hexify(nonce_enc))
    return string.sub(nonce_enc, 1, 8)
end


function Smartcard.mt:transmit(apdu)
    log.output("Smartcard:transmit: ", hex.hexify(apdu or ''))
    if self._soft_transacted then
        self:real_begin_transaction()
    end
    if self.on_transmit then
        self:on_transmit(apdu)
    end
    
    local result, scarderr = self.card:transmit(apdu)
    if not result then
        error(SmartcardError.new('', string.format('transmit error: 0x%x', scarderr) ))
    end
    return result
end

function Smartcard.mt:verify_sm_valid()
    if self._sm_active then
        log.output("Smartcard:verify_sm_valid(): verifying SM status...")
        local sw = self:SMTX(hex.hexf("0020008000"))
        if sw == hex.hexf("6982") or sw == hex.hexf("6e00") then
            log.output("Smartcard:verify_sm_valid(): restarting SM session...")
            self:select_aid()
            self:create_secure_channel()
        else
            log.output("Smartcard:verify_sm_valid(): SM session VALID...")
        end
    else
        self:select_aid()
    end
end

function Smartcard.mt:real_begin_transaction()
    log.output("Smartcard:real_begin_transaction...")
    self.card:begintransaction()
    self._in_transaction = true
    self._soft_transacted = false
    self:verify_sm_valid()

    
end

function Smartcard.mt:real_end_transaction()
    log.output("Smartcard:real_end_transaction...")
    self.card:endtransaction()
end

function Smartcard.mt:begin_transaction()
    if self._in_transaction then
        log.output("Smartcard:begin_transaction: already transacted!")
        return
    end
    self._soft_transacted = true
    log.output("Smartcard:begin_transaction: soft transacted...")
end

function Smartcard.mt:end_transaction()
    log.output("Smartcard:end_transaction...")
    if self._in_transaction then
        self:real_end_transaction()
    else
        log.output("Smartcard:end_transaction: NOT in real transaction!")
    end
    self._soft_transacted = false
    self._in_transaction = false
end

function Smartcard.mt:on_end_transaction()
    log.output('Smartcard:on_end_transaction()...')
    self:real_end_transaction()

end

function Smartcard.mt:on_begin_transaction()
    log.output('Smartcard:on_begin_transaction()...')
    self:real_begin_transaction()
end


function Smartcard.mt:cypher(text, key, IV)
    local curIV = IV or string.rep("\0", 16)
    local C = ""
    for i=1, string.len(text) / 16 do
        local block = string.sub(text, 1 + (i-1)*16, i*16)
        local curBlock = xor_strings(curIV, block)
        local L = sm.aes_enc_block(key, curBlock)
        curIV = L
        C = C .. L
    end
    return C
end

function Smartcard.mt:DervieSessionKeys(data)

    local keyDerivationData = string.sub(data, 1, 10)
    local ddIU = string.sub(data, 5, 10)
    local key_version = string.sub(data, 11, 11)
    local scp_identifier = string.sub(data, 12, 12)
    local card_challenge = string.sub(data, 13, 20)
    local card_cryptogram = string.sub(data, 21, -1)

    log.output ("keyDerivationData: ", hex.hexify(keyDerivationData))
    log.output ("key_version: ", hex.hexify(key_version))
    log.output ("scp_identifier: ", hex.hexify(scp_identifier))
    log.output ("card_challenge: ", hex.hexify(card_challenge))
    log.output ("card_cryptogram: ", hex.hexify(card_cryptogram))
    log.output ("ddIU: ", hex.hexify(ddIU))

    log.output("Derivation  Data....")
    dEnc = ddIU .. hex.hexf("F001") .. ddIU .. hex.hexf("0F01")
    dMac = ddIU .. hex.hexf("F002") .. ddIU .. hex.hexf("0F02")
    dDek = ddIU .. hex.hexf("F003") .. ddIU .. hex.hexf("0F03")
    log.output ("dEnc -> ", hex.hexify(dEnc) )
    log.output ("dMac -> ", hex.hexify(dMac) )
    log.output ("dDek -> ", hex.hexify(dDek) )

    log.output("Derived AES_128 Keys....")

    enc = self:cypher(dEnc, self.kmc)
    mac = self:cypher(dMac, self.kmc)
    dek = self:cypher(dDek, self.kmc)

    log.output ("enc -> ", hex.hexify(enc)  )
    log.output ("mac -> ", hex.hexify(mac)  )
    log.output ("dek -> ", hex.hexify(dek)  )

    log.output ("Generate AES Session Keys...")

    log.output ("cardChall | hostChall ---> ", hex.hexify(card_challenge .. self.host_challenge))
    local aes_enc_card_host = self:cypher(card_challenge .. self.host_challenge, enc)

    log.output ("Aes( cardChall | hostChall ) ---> ", hex.hexify(aes_enc_card_host))

    local xor_aes_enc_card_host = xor_strings(aes_enc_card_host, self.XOR_MASK_1)

    log.output ("After Xor with 182 ---> ", hex.hexify(xor_aes_enc_card_host))

    local aes_mac_card_host = self:cypher(card_challenge .. self.host_challenge, mac)

    log.output ("Aes( cardChall | hostChall )---> ", hex.hexify(aes_mac_card_host))

    local xor_aes_mac_card_host = xor_strings(aes_mac_card_host, self.XOR_MASK_2)

    log.output ("After Xor with 101 ---> ", hex.hexify(xor_aes_mac_card_host))


    local session_key_enc = self:cypher(xor_aes_enc_card_host, enc)
    local session_key_mac = self:cypher(xor_aes_mac_card_host, mac)
    local session_key_dek = dek

    log.output ("Session AES_KEY keys....")
    log.output ("session_key_enc ---> ", hex.hexify(session_key_enc ))
    log.output ("session_key_mac ---> ", hex.hexify(session_key_mac ))
    log.output ("session_key_dek ---> ", hex.hexify(session_key_dek ))
    return session_key_enc, session_key_mac, session_key_dek, card_challenge, card_cryptogram
end


    
    
function Smartcard.mt:GenerateCardAuthCryptogram(host_challenge, card_challenge, session_key_enc, session_key_mac)
    log.output("Generate Card Authentication Cryptogram...")

    local card_auth_cyptogram = string.sub(self:cypher(host_challenge .. card_challenge, session_key_enc), 1, 8)

    log.output("Card Authentication Cryptogram ---> ", hex.hexify(card_auth_cyptogram))

    log.output("Generate Host Authentication Cryptogram...")

    local host_auth_cyptogram =  string.sub(self:cypher(card_challenge .. host_challenge, session_key_enc), 1, 8)

    log.output("Host Authentication Cryptogram ---> ", hex.hexify(host_auth_cyptogram))

    log.output("Generate First MAC...")
    local data_to_mac = self.partial_external_auth .. host_auth_cyptogram
    log.output("to MAC 1:", hex.hexify(data_to_mac))
    
    if math.mod(string.len(data_to_mac), 16) == 0 then
        
    else
        data_to_mac = data_to_mac ..  hex.hexf('80')
        data_to_mac = data_to_mac .. string.rep('\0', 16-string.len(data_to_mac))
    end
    
    log.output("to MAC 2:", hex.hexify(data_to_mac))
    
    local mac = string.sub(self:cypher(data_to_mac, session_key_mac), 1, 8)

    log.output("First MAC --> ", hex.hexify(mac))
    return host_auth_cyptogram, mac
end

function Smartcard.mt:get_PIV_Version()
    local recv = self:sm_transmit(hex.hexf("00CB3FFF045C023FF004"))
    if recv and string.sub(recv, -2, -1) == hex.hexf('9000') and 
        string.sub(recv, 1, 2) == hex.hexf('5302')
        then
        local t,v, version_major, version_minor = bin.unpack("%B%B%B%B", recv)
        return version_major, version_minor
    end
end

function Smartcard.mt:get_sn_label_license()
    local recv = self:sm_transmit(hex.hexf("00CB3FFF055C035FC10700"))
    if recv and string.sub(recv, -2, -1) == hex.hexf('9000') and 
        string.sub(recv, 1, 1) == hex.hexf('53')
        then
        
        local parsed1 = Smartcard.parse_tlv_ber(recv)
        local parsed2 = Smartcard.parse_tlv_ber(parsed1[tonumber("53", 16)] or "") or {}
        
        return parsed2[tag_C0], parsed2[tag_C1], parsed2[tag_C2], parsed2[tag_CF]
    end
end

function Smartcard.mt:get_CIN()
    local CIN, SN
    log.output("get_CIN")
    local _select = self.select_aid_GP_Issuer_Security_Domain
    local recv = self:transmit(_select)
    if string.sub(recv, -2, -1) == hex.hexf('9000') then
    
        local get_CIN_apdu = hex.hexf("80ca004500")
        local recv = self:transmit(get_CIN_apdu)
        if  (string.sub(recv, -2, -1) == hex.hexf('9000')) then
            CIN = hex.hexify(string.sub(recv, 9, -3))
            
            log.output("get_CIN: CIN", hex.hexify(CIN))
        end
        
        local getIssuerData = hex.hexf("80ca9f7f00")
        local recv = self:transmit(getIssuerData)
        if  (string.sub(recv, -2, -1) == hex.hexf('9000')) then
        
            SN = hex.hexify(string.sub(recv, 20, 21) .. string.sub(recv, 14, 19))
            log.output("get_CIN: SN", hex.hexify(SN))
        end
    end
    self:select_aid()
    return CIN, SN
end

local function pad_iso9797_2(data, padding_length)
    padding_length = padding_length or 8
    local l = string.len(data)
    local m = math.mod(l, padding_length)
    local x = data .. "\128" .. string.rep('\000', padding_length-1-m)
    return x
    
end

local function macAPDU(keySig, apdu, macChaining)

	log.output("macAPDU:keySig:" .. hex.hexify(keySig))
	log.output("macAPDU:apdu:" .. hex.hexify(apdu))
	log.output("macAPDU:macChaining:" .. hex.hexify(macChaining))
    local LE = ""
    local cla_f = bin.flags(string.byte(apdu, 1))
    cla_f = cla_f + bin.flags("0x04" )
    apdu = string.char(cla_f.asnumber) .. string.sub(apdu, 2, -1)
    
	local smHead = string.sub(apdu, 1, 4)
    local newAPDU
    local calcMac
	local datafield = ""
    if string.len(apdu) <= 5 then
        newAPDU = smHead .. "\008"
        calcMac = macChaining .. newAPDU
        log.output("macAPDU:calcMac2 (no data field APDU)" .. hex.hexify(calcMac))
        if string.len(apdu) == 5  then
            LE = string.sub(apdu, -1, -1)
            log.output("macAPDU:LE:" .. hex.hexify(LE))
        end
    elseif (string.byte(apdu, 5) ~= 0 and string.len(apdu) > 5) then
		
		datafield = string.sub(apdu, 6, 5 + string.byte(apdu, 5))
        
        newAPDU = smHead .. hex.hexf("%B", 8 + string.len(datafield)) .. datafield
        
        calcMac = macChaining .. newAPDU
        log.output("macAPDU:calcMac2:" .. hex.hexify(calcMac))
        
        if string.len(apdu) == (string.byte(apdu, 5) + 6) then
            LE = string.sub(apdu, -1, -1)
            log.output("macAPDU:LE:" .. hex.hexify(LE))
        end
    
	elseif (string.byte(apdu, 5) == 0 and string.len(apdu) > 7) then
        -- extended APDU
        local apduLen = (string.byte(apdu, 6) * 256) + string.byte(apdu, 7)
		datafield = string.sub(apdu, 8, 7+ apduLen)
        
        newAPDU = smHead .. hex.hexf("00%H", 8 + string.len(datafield)) .. datafield
        
        calcMac = macChaining .. newAPDU
        log.output("macAPDU:calcMac2 (extended APDU):" .. hex.hexify(calcMac))
        if string.len(apdu) == apduLen + 9 then
            LE = string.sub(apdu, -2, -1)
            log.output("macAPDU: extended LE:" .. hex.hexify(LE))
        end
    
	end
    


    
    log.output("macAPDU:calcMac:" .. hex.hexify(calcMac))
	
    local mac = aes.AES_CMAC(keySig, calcMac)
    
    log.output("macAPDU:new macChaining:" .. hex.hexify(mac))

    newAPDU = newAPDU .. string.sub(mac, 1, 8) .. LE
    log.output("macAPDU:newAPDU:" .. hex.hexify(newAPDU))

	return newAPDU, mac
end

function Smartcard.mt:SMTX(apdu)

    local extAuthAPDU, macChaining = macAPDU(self.s_mac, apdu, self.macChaining )
    local recv = self:transmit(extAuthAPDU)
    local sw = string.sub(recv, -2, -1)
    
    -- if SW == secure channel invalid, then restore secure channel
    -- if sw ~= hex.hexf('9000') then
        -- error(SmartcardError.new(sw, 'SMTX() Initialize Update: error'), 2)
    -- end
    
    self.macChaining = macChaining
    return recv
    
end

function Smartcard.mt:sm_transmit(apdu, nosm)
    log.output("Smartcard:sm_transmit: ", hex.hexify(apdu or ''))
    if self._soft_transacted then
        self:real_begin_transaction()
    end
    if self.on_transmit then
        self:on_transmit(apdu)
    end
    
    local result, scarderr
    if nosm or not self._sm_active then

        result, scarderr = self.card:transmit(apdu)
    else
        scarderr = -1
        result = self:SMTX(apdu)
    end
    if not result then
        error(SmartcardError.new('', string.format('transmit error: 0x%x', scarderr) ))
    end
    return result
end


function Smartcard.mt:create_secure_channel()

    local authError
    log.output('create_secure_channel(): Initialize Update')
    local host_challenge = string.rep("\0", 8)
    
    local apdu = hex.hexf('80500000%P00', host_challenge)
    local recv = self:transmit(apdu)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hex.hexf('9000') then
        error(SmartcardError.new(sw, debug.traceback('create_secure_channel() Initialize Update: error')), 2)
    end
    
    local keys = {self.piv_admin_key, ((self.piv_admin_key == self.piv_admin_key_prod) and self.piv_admin_key_test) or self.piv_admin_key_prod }
    
    log.output('create_secure_channel(): start discovery of SM key')
    for i, v in keys do
        
        self.piv_admin_key = v
        local factory_context = string.sub(recv, 1, 8) -- factory_context = recv[:8]
        local card_challenge = string.sub(recv, 14, 21) -- card_challenge = recv[13:21]
        local card_cryptogram = string.sub(recv, 22, 29) -- card_cryptogram = recv[21:29]
        log.output('factory_context: ', hex.hexify(factory_context))
        log.output('card_challenge: ', hex.hexify(card_challenge))
        log.output('card_cryptogram: ', hex.hexify(card_cryptogram))

        -- factory_dak = compute_cmac('010000000100' + factory_context + "0100", masterkey)
        -- factory_dak += compute_cmac('020000000100' + factory_context + "0100", masterkey)
        local factory_dak = aes.AES_CMAC(self.piv_admin_key, hex.hexf('010000000100') .. factory_context .. hex.hexf('0100'))
            .. aes.AES_CMAC(self.piv_admin_key, hex.hexf('020000000100') .. factory_context .. hex.hexf('0100'))
        log.output('factory_dak = ', hex.hexify(factory_dak))

        
        -- factory_dmk = compute_cmac('010000000200' + factory_context + "0100", masterkey)
        -- factory_dmk += compute_cmac('020000000200' + factory_context + "0100", masterkey)
        local factory_dmk = aes.AES_CMAC(self.piv_admin_key, hex.hexf('010000000200') .. factory_context .. hex.hexf('0100'))
            .. aes.AES_CMAC(self.piv_admin_key, hex.hexf('020000000200') .. factory_context .. hex.hexf('0100'))
        log.output('factory_dmk = ', hex.hexify(factory_dmk))

        -- factory_dek = compute_cmac('010000000300' + factory_context + "0100", masterkey)
        -- factory_dek += compute_cmac('020000000300' + factory_context + "0100", masterkey)
        local factory_dek = aes.AES_CMAC(self.piv_admin_key, hex.hexf('010000000300') .. factory_context .. hex.hexf('0100'))
            .. aes.AES_CMAC(self.piv_admin_key, hex.hexf('020000000300') .. factory_context .. hex.hexf('0100'))
        log.output('factory_dek = ', hex.hexify(factory_dek))

        local context = host_challenge .. card_challenge
        -- s_enc = compute_cmac('00000000000000000000000400010001' + context, factory_dak)
        -- s_enc += compute_cmac('00000000000000000000000400010002' + context, factory_dak)
        
        local s_enc = aes.AES_CMAC(factory_dak, hex.hexf('00000000000000000000000400010001') .. context)
            .. aes.AES_CMAC(factory_dak, hex.hexf('00000000000000000000000400010002') .. context)
        log.output('s_enc = ', hex.hexify(s_enc))

        -- s_mac = compute_cmac('00000000000000000000000600010001' + context, factory_dmk)
        -- s_mac += compute_cmac('00000000000000000000000600010002' + context, factory_dmk)
        local s_mac = aes.AES_CMAC(factory_dmk, hex.hexf('00000000000000000000000600010001') .. context)
            .. aes.AES_CMAC(factory_dmk, hex.hexf('00000000000000000000000600010002') .. context)
        log.output('s_mac = ', hex.hexify(s_mac))
        
        -- s_rmac = compute_cmac('00000000000000000000000700010001' + context, factory_dmk)
        -- s_rmac += compute_cmac('00000000000000000000000700010002' + context, factory_dmk)
        local s_rmac = aes.AES_CMAC(factory_dmk, hex.hexf('00000000000000000000000700010001') .. context)
            .. aes.AES_CMAC(factory_dmk, hex.hexf('00000000000000000000000700010002') .. context)
        log.output('s_rmac = ', hex.hexify(s_rmac))

        -- checking_card_cryptogram = compute_cmac('00000000000000000000000000004001' + context, s_mac)[:16]
        local checking_card_cryptogram = aes.AES_CMAC(s_mac, hex.hexf('00000000000000000000000000004001') .. context)
        checking_card_cryptogram = string.sub(checking_card_cryptogram, 1, 8)
        log.output('checking_card_cryptogram = ', hex.hexify(checking_card_cryptogram))
        
        if card_cryptogram == checking_card_cryptogram then
            log.output('CARD_CRYPTOGRAM CHECK OK')
            -- host_cryptogram = compute_cmac('00000000000000000000000100004001' + context, s_mac)[:16]
            local host_cryptogram = aes.AES_CMAC(s_mac, hex.hexf('00000000000000000000000100004001') .. context)
            host_cryptogram = string.sub(host_cryptogram, 1, 8)
            log.output('host_cryptogram = ', hex.hexify(host_cryptogram))
            
            local extAuthAPDU, macChaining = macAPDU(s_mac, hex.hexf('80820100%P', host_cryptogram), hex.hexf("00000000000000000000000000000000") )
            local recv = self:transmit(extAuthAPDU)
            local sw = string.sub(recv, -2, -1)
            if sw ~= hex.hexf('9000') then
                error(SmartcardError.new(sw, debug.traceback('create_secure_channel() Initialize Update: error')), 2)
            end
            
            self.macChaining = macChaining
            
            self.factory_dek = factory_dek
            self.s_mac = s_mac
            self.s_enc = s_enc

            log.output('get pin status')
            local recv = self:SMTX(hex.hexf("0020008000"))
            log.output('get pin status:', hex.hexify(recv))
            
            log.output('Get_Data_Admin_diversify')
            local recv = self:SMTX(self.Get_Data_Admin_diversify)
            log.output('Get_Data_Admin_diversify:', hex.hexify(recv))
            
            self._sm_active = true
            authError = nil
            break
        else
            log.output('CARD_CRYPTOGRAM CHECK FAILED')
            authError = 'create_secure_channel() error cheching card cryptogram'
            
        end
        

    end
    
    if authError then
        error(SmartcardError.new("", authError), 2)
    end
    
    -- log.output('External authentication')
    -- cmac = compute_cmac('00000000000000000000000000000000' + '8482010010' + host_cryptogram, s_mac)
    -- recv = card.transmit(('8482010010' + host_cryptogram + cmac[:16]).decode('hex'))
    -- log.output(recv.encode('hex'))
    -- assert (recv[-2:] == b'\x90\x00', recv[-2:].encode('hex'))
    
    -- log.output('get pin status')
    
    -- cmac = compute_cmac(cmac + '0420008008', s_mac)
    -- recv = card.transmit(('0420008008' + cmac[:16]).decode('hex'))
    -- log.output(recv.encode('hex'))
    -- assert (recv[-2:] == b'\x90\x00' or (recv[-2] == b'\x63' and (ord(recv[-1]) &0xF0 == 0xC0) ), recv[-2:].encode('hex'))
    
    -- cmac = compute_cmac(cmac + '0420008008', s_mac)
    -- recv = card.transmit(('0420008008' + cmac[:16]).decode('hex'))
    -- log.output(recv.encode('hex'))
    -- assert (recv[-2:] == b'\x90\x00' or recv[-2] == b'\x63', recv[-2:].encode('hex'))

    -- log.output('read container 5FC107')
    -- cmac = compute_cmac(cmac + '04CB3FFF0D5C035FC107', s_mac)
    -- recv = card.transmit(('04CB3FFF0D5C035FC107' + cmac[:16] + "00").decode('hex'))
    -- log.output(recv.encode('hex'))
    -- assert( recv[-2:] == b'\x90\x00' or recv[-2] == b'\x63', recv[-2:].encode('hex'))
    
    -- pin = "12345678"
    -- encpin = compute_cbc(pin.encode("hex") + "8000000000000000", factory_dek)

    -- log.output('verify pin: ', pin, encpin)
    -- apdu = '0420008018' + encpin
    -- cmac = compute_cmac(cmac + apdu, s_mac)
    -- recv = card.transmit((apdu + cmac[:16]).decode('hex'))
    -- log.output(recv.encode('hex'))
    -- assert (recv[-2:] == b'\x90\x00', recv[-2:].encode('hex'))
    
    -- log.output('SIGN')
    -- cmac = compute_cmac(cmac + '04870682907C818582008181800001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF003021300906052B0E03021A05000414AE61DFFA9FCC291C57A4D2811BB74FF6D3AEBD11', s_mac)
    -- recv = card.transmit(('04870682907C818582008181800001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF003021300906052B0E03021A05000414AE61DFFA9FCC291C57A4D2811BB74FF6D3AEBD11' + cmac[:16] + "00").decode('hex'))
    -- log.output(recv.encode('hex'))
    -- assert (recv[-2:] == b'\x90\x00' or recv[-2] == b'\x63', recv[-2:].encode('hex'))
    
    
end
    
function Smartcard.mt:external_auth()
    
    log.output("external_auth(): external_auth_use_aes", self._external_auth_use_aes)
    
    if self._external_auth_use_aes then
    
        log.output("external_auth(): using AES")
        -- Get Data( Admin diversify )
        local recv = self:sm_transmit(self.Get_Data_Admin_diversify)
        assert (string.sub(recv, -2, -1) == hex.hexf('9000'))

        local piv_context = string.sub(recv, 3, 10)
        log.output("external_auth(): PIV CONTEXT =", hex.hexify(piv_context))
        
        local piv_adm_key = aes.AES_CMAC(self.piv_admin_key, hex.hexf('010000000400') .. piv_context .. hex.hexf('0100'))
            .. aes.AES_CMAC(self.piv_admin_key, hex.hexf('020000000400') .. piv_context .. hex.hexf('0100'))
        
        log.output("external_auth(): piv_adm_key:", hex.hexify(piv_adm_key))
        
        local recv = self:sm_transmit(hex.hexf("00870C9B047C02810000"))
        assert (string.sub(recv, -2, -1) == hex.hexf('9000'))

        local nonce = string.sub(recv, 5, -3)
        local nonce_enc = sm.aes_enc_block(piv_adm_key, nonce)
        recv = self:sm_transmit(hex.hexf("00870C9B147C128210%S", nonce_enc))
        log.output("external_auth(): ext auth recv=", hex.hexify(recv))
        assert (string.sub(recv, -2, -1) == hex.hexf('9000'))
        return true
        
    else

        log.output("external_auth(): using DES3")
        -- Gen Auth ext challenge
        --             -- CLA=00
        --             -- INS=87
        --             -- P1=03 (PIV Card Algorithm Identifiers->3 Key Triple DES 