
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

--[[
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
            self.iasecc_hcard:import_private_key(
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
        KAuthId = hex.hexf("%B", self.iasecc_hcard.BSO_PIN)
    else
        log.output('create_object_privkey(): allocating a keyReference for private key')
        keyReference = self:_look_for_free_kid()
        if not keyReference then
            log.output('create_object_privkey(): no more key id left!')
            return CKR.DEVICE_MEMORY
        end
    end
    
    KAuthId = hex.hexf("%B", self.iasecc_hcard.BSO_PIN)
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
    self.iasecc_hcard:import_private_key(
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
    
    KAuthId = hex.hexf("%B", self.iasecc_hcard.BSO_PIN)
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
        self.iasecc_hcard:verify_pin_main(self.cached_main_pin, false, false)  -- pin, ispuk, check
    end
    
    log.output('generate_key_pair(): generating key pair...')
    self.iasecc_hcard:generate_key_pair(keyReference, self.files.IPF)
    local modulus, pubExp = self.iasecc_hcard:read_public_key(keyReference)
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

    FAuthId = hex.hexf("%B", self.iasecc_hcard.BSO_PIN)
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
        self.iasecc_hcard:verify_pin_main(self.cached_main_pin, false, false, true)  -- pin, ispuk, check, use_sm
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
        self.iasecc_hcard:verify_pin_main(self.cached_main_pin, false, false, true)  -- pin, ispuk, check, use_sm
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
        self.iasecc_hcard:verify_pin_main(self.cached_main_pin, false, false, true)  -- pin, ispuk, check, use_sm
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

--]]

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
    local rv = self.iasecc_hcard:valid()
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
        log.output("token-iasecc:flush_cache(): initialize: _cache_id:", self._cache_id)
    end
    changed, cache_id = utility.has_token_changed(self, "cache", self._cache_id)
    if changed then
        log.output("token-iasecc:flush_cache(): token has changed!")
        self._cache_id = cache_id
        self.info = nil -- rimuove cache oggetti
        self._indexes = nil
        self._private_objects_added = false
        self.attributes = nil
        
        log.output("token-iasecc:flush_cache(): rebuilding object's cache")
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
_LOADED['IasEccSmartcard'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
local hex = require 'hex'
local util = require 'utility'
local h2i, hexf, hexify = hex.h2i, hex.hexf, hex.hexify
local rsa
local zlib = require 'zlib'

local function hexf2(data, ...)
    data = string.gsub(data, "%s", "")
    return hex.hexf(data, unpack(arg))
end

pcall(function() rsa = require("rsa"); end)

-- IasEccSmartcard

local tr_dl

local IasEccSmartcard = {}
IasEccSmartcard.mt = {}
IasEccSmartcard.mt.__index = IasEccSmartcard.mt


IasEccSmartcard.PIN_PADDING = 16
IasEccSmartcard.PUK_PADDING = 16
IasEccSmartcard.PIN_PADDING_CHAR = "\255"
IasEccSmartcard.PUK_PADDING_CHAR = "\255"
IasEccSmartcard.BSO_PIN = h2i('01')
IasEccSmartcard.BSO_PUK = h2i('02')

IasEccSmartcard.MAX_TRANSMIT_BUFFER_SIZE = 200

IasEccSmartcard.IasEccSmartcardError = {}
IasEccSmartcard.IasEccSmartcardError.mt = {}
IasEccSmartcard.IasEccSmartcardError.mt.__index = IasEccSmartcard.IasEccSmartcardError.mt

function IasEccSmartcard.IasEccSmartcardError.mt.__tostring(e)
    return "IasEccSmartcardError: " .. (e.msg or '') .. ' ;SW=' .. hex.hexify(e.sw or '') 
end

function IasEccSmartcard.IasEccSmartcardError.new(sw, msg)
    local e = msg .. ' ;sw=' .. hexify(sw or '')
    return e
end

local function parse_tlv_ber(data)
    local d = {}
    local i = 0
    local offset, le, tag
    local log_array = {}
    log.output("parse_tlv_ber():", hex.hexify(data or ""))
    while 1 do
        tag = string.byte(data, i+1)
        if tag == 0 or tag == 255 then
            break
        end
        if tag == 127 then -- 0x7F
            i = i+1
            tag = (tag * 256) + string.byte(data, i+1)
        elseif tag == 191 then -- 0xBF: tag speciale
            i = i+1
            tag = (tag * 256*256) + (string.byte(data, i+1) * 256)  + string.byte(data, i+2)
            i = i+1
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
        table.insert(log_array, string.format("TAG: %02x LEN:%d", tag, le))
        d[tag] = string.sub(data, i+3, i+2+le)
        
        i = i + le + 2
        if i >= string.len(data) then
            break
        end
    end
    log.output(table.concat(log_array, "; "))
    return d
end

IasEccSmartcard.parse_tlv_ber = parse_tlv_ber

local function L(value)
    return string.char(string.len(value)) .. value
end

local function trim_pad_bn(data, padto)
    data = string.sub(data, -padto)
    data = string.rep("\000", padto - string.len(data)) .. data
    return data
end


function IasEccSmartcard.new(card)
    local self = {
                    PIN_PADDING=IasEccSmartcard.PIN_PADDING,
                    PUK_PADDING=IasEccSmartcard.PUK_PADDING,
                    PIN_PADDING_CHAR=IasEccSmartcard.PIN_PADDING_CHAR,
                    PUK_PADDING_CHAR=IasEccSmartcard.PUK_PADDING_CHAR,
                    BSO_PIN=IasEccSmartcard.BSO_PIN, BSO_DS_PIN=IasEccSmartcard.BSO_DS_PIN,
                    BSO_PUK=IasEccSmartcard.BSO_PUK, BSO_DS_PUK=IasEccSmartcard.BSO_DS_PUK,
                  }
    self.card = card
    setmetatable(self, IasEccSmartcard.mt)
    return self
end


function IasEccSmartcard.mt:get_pin_puk_status()
    self:verify_pin_main("", false, true, false)
    local resPin = self.last_sw

    self:verify_pin_main("", true, true, false)
    local resPuk = self.last_sw
    
    local pinRetryMax = 3
    local pinRetry
    if resPin == hexf("9000") then
        pinRetry = pinRetryMax
    else
        pinRetry = (bin.flags(string.byte(resPin, -1)) * bin.flags(h2i("F"))).asnumber
    end
    
    local pukRetryMax = 3
    local pukRetry
    if resPuk == hexf("9000") then
        pukRetry = pukRetryMax
    else
        pukRetry = (bin.flags(string.byte(resPuk, -1)) * bin.flags(h2i("F"))).asnumber
    end
    
    if pinRetry > pinRetryMax then 
        pinRetryMax = pinRetry
    end
    if pukRetry > pukRetryMax then 
        pukRetryMax = pukRetry
    end
    
    return pinRetry, pinRetryMax, pukRetry, pukRetryMax
end



function IasEccSmartcard.mt:TXchain(value, data)
    log.output("TXchain():")
    local resp = ""
    local value2
    local data2
    local data1 = data
    local value1 = value
    if data then
        if string.len(data) > 254 then
            data1 = string.sub(data, 1, 220)
            data2 = string.sub(data, 221)
            value1 = string.char(string.byte(value, 1) + 16) .. string.sub(value, 2, 4)
            value2 = string.sub(value, 1, 4)
            log.output("TXchain: value1", hex.hexify(value1))
            log.output("TXchain: data1", hex.hexify(data1))
            log.output("TXchain: value2", hex.hexify(value2))
            log.output("TXchain: data2", hex.hexify(data2))
        end
    end
    resp = self:TX(value1, data1)
    if value2 then
        resp = self:TX(value2, data2)
    end
    return resp
end
    

function IasEccSmartcard.mt:TX(value, data, LE)
    local resp = ""
    if data then
        value = value .. L(data)
    end
    if LE then
        value = value .. LE
    end
    log.output('<<', hex.hexify(value))
    local stop
    while true do
        local r = self.card:transmit(value)
        if string.sub(r, -2, -2) == hexf("61") then -- more data
            log.output('*>>', hex.hexify(r))
            local r1 = string.byte(r, -1)
            -- if r1 == 0 then
                -- r1 = 128
            -- end
            value = hex.hexf('00C00000%B', r1)
            log.output('<<*', hex.hexify(value))
            resp = resp .. string.sub(r, 1, -3)          
        elseif string.sub(r, -2, -2) == hexf("6c") and string.len(value)==5 then -- wrong length
            log.output('*>>', hex.hexify(r))
            value = string.sub(value, 1, 4) .. string.sub(r, -1)
            log.output('<<*', hex.hexify(value))
            resp = resp .. string.sub(r, 1, -3)
        else
            resp = resp .. r
            break
        end
    end
    log.output('>>', hex.hexify(resp) )
    return resp
end



function IasEccSmartcard.mt:read_serial_number()
    if not self.CSN then
        self:select_p15()
    end
    local sn = hex.hexify(self.CSN)
    return string.sub(string.rep(16 - string.len(sn), "0") .. sn, -16, -1)
end

function IasEccSmartcard.mt:select_p15()
    -- usa SOLO la funzione low level TX
    -- riselezionare l'applet o l'AID PKCS#15 non ammulla lo stato interno di verifica del PIN
    log.output("IasEccSmartcard:select_p15()")
    
    if type(self.aid) == "string" then
        log.output("selecting predetermined P15-AID...")
        local res = self:TX(hex.hexf("00a40404"), self.aid)
        if string.sub(res, -2, -1) == hex.hexf("9000") then
            return
        end
    end
    
    log.output("select applet:")
    local res = self:TX(hex.hexf("00a4040c"), hex.hexf("A000000077010800070000FE00000100"))
    assert (string.sub(res, -2, -1) == hex.hexf("9000") )
    
    if not self.CSN then
        log.output("select SN file:")
        local res = self:TX(hexf("00a40004"), hexf("D003"))
        assert (string.sub(res, -2, -1) == hex.hexf("9000") )
        local res = self:TX(hexf("00B0000000"))
        assert (string.sub(res, -2, -1) == hex.hexf("9000") )
        self.CSN = string.sub(res, 1, -3)
    end
    
    if not self.aid then
        log.output("read EF.DIR (EFID = '2F00' and SFI = '1E'):")
        local res = self:TX(hex.hexf("00b09e00"), "") -- EFID = '2F00' and SFI = '1E': EF.DIR
        assert (string.sub(res, -2, -1) == hex.hexf("9000") )
        
        local tlv = parse_tlv_ber(res)
        local tlv1 = parse_tlv_ber(tlv[tonumber('61', 16)])
        local aid = tlv1[tonumber('4F', 16)]
        assert (type(aid) == "string")
        self.aid = aid
    end
    local res = self:TX(hex.hexf("00a40404"), self.aid)
    assert (string.sub(res, -2, -1) == hex.hexf("9000") )
end

function IasEccSmartcard.mt:auto_select_p15()
    -- usa SOLO la funzione low level TX
    local pcRes
    if not self._performed_mutual_auth then
        self:select_p15()
        self._performed_mutual_auth = true
        return true
    else
        log.output("IasEccSmartcard:auto_select_p15(): not needed: inside same transaction!")
        return false
    end
end


-------------------------------------------------------

function IasEccSmartcard.parse_fci(fci)
    local fci1 = parse_tlv_ber(fci)
    local fci2 = parse_tlv_ber(fci1[98] or fci1[111]) -- 0x62 or 0x6F
    local infos = {size=(fci2[128] or fci2[129]) and bin.unpack("%H", fci2[128] or fci2[129]),
                      filetype = fci2[130] and string.byte(fci2[130], 1),
                      options=fci2[130],
                      fid_n=fci2[131] and bin.unpack("%H", fci2[131]),
                      fid =fci2[131],
                      sc = fci2[140] or fci2[156],
                      amb = fci2[161], 
                      }
    return infos
end

function IasEccSmartcard.mt:transmit(apdu)
    local header, data = string.sub(apdu, 1, 4), string.sub(apdu, 6, -1)
    local LE
    if string.len(apdu) <= 5 then -- APDU con il solo LE
        header, data = apdu, nil
    
    elseif string.byte(apdu, 5)+6 == string.len(apdu) then -- APDU con DATA ed LE
        header, data = string.sub(apdu, 1, 4), string.sub(apdu, 6, -2)
        LE = string.sub(apdu, -1, -1)
    end
    -- auto_select_p15 usa la funzione low level TX, dunque non si pu