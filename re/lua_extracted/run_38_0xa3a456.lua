 oggetti ritorna 0
function t.mt:get_item(search_state, showprivate, template)
    if log.canlog() then
        log.output('get_item(): search_state', repr(search_state), 'showprivate', showprivate)
        log.output('get_item(): template', repr(template))
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    if search_state.lastobj==nil then 
        search_state.lastobj=self.attributes.min_index 
    end
    for i=search_state.lastobj, self.attributes.max_index do
        local attr = self.attributes[i]
        if attr ~= nil then
            if type(attr[CKA.PRIVATE]) == 'function' then
                attr[CKA.PRIVATE](self, i, CKA.PRIVATE, false)
            end
            local visible = attr[CKA.PRIVATE] == eCK.BBOOL(false) or 
                            (attr[CKA.PRIVATE] == eCK.BBOOL(true) and showprivate)
            if not visible then
                log.output('get_item(): handle', i, 'not visible')
            end
            if visible and self:verify_template(i, template) then
                search_state.lastobj = i +1
                return i
            end
        end
    end
    search_state.lastobj = self.attributes.max_index +1 -- next search returns no object
    return 0
end

function t.mt:verify_template(hobj, template)
    if log.canlog() then
        log.output('>>>verify_template: hobj', hobj)
    end
    for attr_type, value in template do
        
        local rv, real_value
        rv, real_value = self:get_attribute_value(hobj, attr_type)
        if attr_type == CKA.SERIAL_NUMBER
                and real_value ~= nil 
                and type(real_value) == 'string' 
                and value ~= nil then
            real_value = string.gsub(real_value, '%z*(.*)', '%1')
            value = string.gsub(value, '%z*(.*)', '%1')
        end
        if log.canlog() then
            log.output('>>>template: ', hex.tohex8(attr_type),
                      repr(value), repr(real_value), rv)
        end
        if rv~=CKR.OK or real_value ~= value then
            log.output('>>>not match')
            log.output('>>>false')
            return false
        else
            log.output('>>>match')
        end
    end
    log.output('>>>true')
    return true
end


function t.mt:add_ds_objects(objects)
    -- oggetti DS; l'applicazione puo' non esistere;  gli oggetti possono non essere presenti
    local info = self:get_info() -- carica le info sul filesystem in cache
    local p, i
    if (self.ds_info == nil or self.ds_info.ds_publist == nil or self.ds_info.ds_prilist == nil) then
        log.output('token-inside:add_ds_objects(): DS FS not found...')
        return
    end
    local lists = {[1] = self.ds_info.ds_publist, [2] = self.ds_info.ds_prilist}
    
    log.output('token-inside:add_ds_objects(): adding DS objects...')
    
    for p=0,1 do
        log.output('token-inside:add_ds_objects(): evaluating table:', p)
        local list = lists[p+1];
        local objects_path = "/"
        for i=1,table.getn(list) do
            local ffid = bin.flags(list[i].id_numeric)
            local oType = (ffid* util.objFIDS.eMASK)
            local oNum = (ffid * util.objFIDS.eNumMASK).asnumber
            if list[i].usage == 255 then
                log.output('token-inside:add_ds_objects(): evaluating DS object:', i)
                objects.max_index = objects.max_index +1
                if oType == util.objFIDS.ePrivKey then
                    local infos = bin.flags(list[i].infos)
                    local obj = util.GetDSPrivKeyTemplate(t.mt.get_privkey_ds, i)
                    obj.private = (p==1)
                    obj.num = oNum
                    obj.slot = i
                    obj.ds_parent_path = objects_path   
                    obj.ds_id = hex.hexify(list[i].id)  -- fid DS (fittizio per le chiavi priv)
                    obj.path = obj.ds_parent_path -- path in cui si trova il BSO
                    obj.group = 0
                    obj.index = oNum
                    obj.key_bits = (infos * bin.flags("0x7FFF")).asnumber
                    obj.imported = infos[bin.flags("0x8000")]
                    
                    objects[ objects.max_index] = obj
                    log.output('token-inside:add_ds_objects(): added private key:', 
                        'handle:', objects.max_index, 'path:', obj.path,
                        "imported:", obj.imported,
                        'CKA_CLASS:', hex.hexify(objects[ objects.max_index ][CKA.CLASS]))
                    
                elseif oType == util.objFIDS.ePubKey then
                    local obj = util.GetDSPubKeyTemplate(t.mt.get_pubkey_ds, i)
                    obj.private = (p==1)
                    obj.group = 0
                    obj.index = oNum
                    obj.num = oNum
                    obj.slot = i
                    obj.ds_parent_path = objects_path
                    obj.ds_id = hex.hexify(list[i].id)  -- fid DS (fittizio per le chiavi pub)
                    obj.key_bits = list[i].infos
                    obj.path = obj.ds_parent_path .. list[i].id
                    objects[ objects.max_index] = obj
                    log.output('token-inside:add_ds_objects(): added public key;', 
                        'handle:', objects.max_index, 'path:', obj.path,
                        'CKA_CLASS:', hex.hexify(objects[ objects.max_index ][CKA.CLASS]))
                        
                elseif oType == util.objFIDS.eCert then
                    local obj = util.GetDSCertTemplate(t.mt.get_certificate_ds, i)
                    obj.private = (p==1)
                    obj.num = oNum
                    obj.slot = i
                    obj.ds_parent_path = objects_path
                    obj.ds_id = hex.hexify(list[i].id)  -- fid DS (file binario del certificato)
                    obj.size = list[i].infos
                    
                    obj.path = obj.ds_parent_path .. list[i].id
                    
                    objects[ objects.max_index] = obj
                    log.output('token-inside:add_ds_objects(): added certificate:', 
                        'handle:', objects.max_index, 'path:', obj.path,
                        'CKA_CLASS:', hex.hexify(objects[ objects.max_index ][CKA.CLASS]))
                
                elseif oType == util.objFIDS.eData or oType == util.objFIDS.eDataP then 
                    local obj = util.GetDSDataTemplate(t.mt.get_data_ds, i)
                    obj.private = (p==1)
                    obj.num = oNum
                    obj.slot = i
                    obj.ds_parent_path = objects_path
                    obj.ds_id = hex.hexify(list[i].id)
                    obj.size = list[i].infos
                    obj.path = obj.ds_parent_path .. list[i].id
                    objects[ objects.max_index] = obj
                    log.output('token-inside:add_ds_objects(): added DATA object:', 
                        'handle:', objects.max_index, 'path:', obj.path,
                        'CKA_CLASS:', hex.hexify(objects[ objects.max_index ][CKA.CLASS]))
                else
                    log.output('token-inside:add_ds_objects(): UNSUPPORTED object type found:', hex.hexify(list[i].id))
                end
            end
        
        end -- end ciclo su tabella oggetti
    end -- end ciclo su tabelle pub/priv
end


function t.mt:get_objects()

    log.output('token-inside:get_objects()')
    local info = self:get_info() -- carica le info sul filesystem in cache
    
    local objects = {
            min_index = 11001, -- primo indice disponibile
            max_index = 11000, -- valore dell'indice massimo (i valori intermedi possono anche essere nil)
        }

    self:add_ds_objects(objects)

    return objects
end

function t.mt:get_attribute_value(hobj, attr, onlysize)
    if onlysize==nil then onlysize = false end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj == nil then return CKR.OBJECT_HANDLE_INVALID end
    local result = obj[attr]
    if result == nil then
        log.output('get_attribute_value(): object', hobj, 'doesn\'t define sepcified attribute', attr)
        return CKR.ATTRIBUTE_TYPE_INVALID 
    end
    if type(result)=='function' then
        local rv
        rv, result = result(self, hobj, attr, onlysize)
        if rv ~= CKR.OK then return rv end
    elseif type(result)=='number' then
        return CKR.ATTRIBUTE_SENSITIVE
    end
    if onlysize and type(result)=='string' then
        return CKR.OK, string.len(result)
    else
        return CKR.OK, result
    end
end

-- ****************

function t.mt:create_file(name, size, is_public)
    local owner = VaultICSmartCard.ID_PIN
    local access = is_public and VaultICSmartCard.ACCESS_PUBLIC or VaultICSmartCard.ACCESS_PIN
    local finfo1 = {
        name=name,
        size=size,
        bmReadList=access,
        bmWriteCreate=access,    
        bmDelete=access,
        bmExecute=bin.flags("0xFF"),
        bmAttributes=bin.flags(0),
    }
    self.inside_hcard:select()
    self.inside_hcard:delete_file(finfo1.name)
    self.inside_hcard:select()
    self.inside_hcard:create_file(owner, finfo1)
end

function t.mt:write_file(offset, value)
    return self.inside_hcard:mupdate_binary(offset, value)
end

function t.mt:create_object_pubkey(pTemplate)
    log.output('create_object_pubkey()', pTemplate)
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
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
    local freeId, freeSlot
    local ds_publist = self.ds_info.ds_publist
    local attr = util.serialize_attr_pubkey(pTemplate)
    local fid_val, fid_attr
    local attr_file_size = 0
    local tlv_use_sm=false
    
    obj = util.GetDSPubKeyTemplate(t.mt.get_pubkey_ds)
    obj.private = false
    obj.ds_parent_path = '/'
    obj.key_bits = modulus_bits

    
    local freeSlots = util.look_for_free_slots(ds_publist, 1, 1)
    log.output('create_object_pubkey(): freeSlots:', repr(freeSlots))
    if table.getn(freeSlots) == 0 then
        log.output('create_object_pubkey(): no more slots available')
        return CKR.DEVICE_MEMORY
    end
    freeSlot = freeSlots[1]
    freeId = freeSlot
    fid_val = util.objFIDS.ePubKey + bin.flags(freeId)
    fid_attr = fid_val + bin.flags('0x100')
    obj.ds_id = string.format('%04X', fid_val.asnumber )  -- fid oggetto DS
    obj.path = obj.ds_parent_path .. hexf('%>%H', fid_val.asnumber )
    tlv_use_sm=true
    obj.num = freeId
    obj.slot = freeSlot

    local rsaInfos = {
        n = pTemplate[CKA.MODULUS],
        e = pTemplate[CKA.PUBLIC_EXPONENT],
        bmDelete = VaultICSmartCard.ACCESS_PUBLIC,
        bmExecute = VaultICSmartCard.ACCESS_PUBLIC,
    }
    
    
    local pcRes, theErrorT = pcall(function()
        -- crea gli attributi della chiave pubblica
        attr_file_size =string.len(attr)
        self:create_file( hexf("%>%H", fid_attr.asnumber), attr_file_size, true)
        self:write_file(0, attr)
    end)
    if not pcRes then
        log.output('create_object_pubkey(): error:', theErrorT)
        if self.inside_hcard.last_sw == hexf("6A84") then
            log.output('create_object_pubkey(): no more memory available')
            return CKR.DEVICE_MEMORY
        else
            return CKR.FUNCTION_FAILED
        end
    end
    
    -- update objects list
    ds_publist[freeSlot].usage = 255
    ds_publist[freeSlot].id = hexf(obj.ds_id)
    ds_publist[freeSlot].id_numeric = tonumber(obj.ds_id, 16)
    ds_publist[freeSlot].infos = obj.key_bits
    
    self:write_objlist(true) -- write public list
    
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    return CKR.OK, self.attributes.max_index
end

function t.mt:write_objlist(public)
    -- serialize an object list and update corresponding file
    log.output('write_objlist(): public:', public)
    local objList, objListPath
    if public then
        objListPath = '/pub'
        objList = self.ds_info.ds_publist
    else
        objListPath = '/priv'
        objList = self.ds_info.ds_prilist
    end
    self.inside_hcard:select(objListPath)
    self.inside_hcard:mupdate_binary(0, util.serialize_ds_objlist(objList))
end


local function _pad_bignum(big_num, pad_to)
    local big_num_orig = big_num
    if not big_num or big_num == "" then
       return big_num_orig
    end
    while string.sub(big_num, 1, 1) == '\000' do big_num = string.sub(big_num, 2, -1) end
    big_num = string.rep('\000', pad_to - string.len(big_num))
                            .. big_num
    if string.len(big_num) ~= pad_to then
        log.output('_pad_bignum(): value len invalid; expected:', pad_to)
        return big_num_orig
    end
    return big_num
end


function t.mt:create_object_privkey_h(pTemplateOrig, as_local)
    log.output('create_object_privkey_h()')
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    local pTemplate = utility.clone_table(pTemplateOrig)
    pTemplate[CKA.LOCAL] = eCK.BBOOL(as_local)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    pTemplate = utility.clone_table(pTemplate)
    pTemplate[CKA.ALWAYS_AUTHENTICATE] = nil
    if not pTemplate[CKA.MODULUS] or not pTemplate[CKA.PUBLIC_EXPONENT] 
        or not pTemplate[CKA.PRIVATE_EXPONENT] then
        log.output('create_object_privkey_h(): MODULUS or PUBLIC_EXPONENT or PRIVATE_EXPONENT not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    local fid_val, fid_attr
    local attr_file_size = 0

    local modulus_bytes = string.len(pTemplate[CKA.MODULUS])
    local modulus_bits = string.len(pTemplate[CKA.MODULUS]) * 8
    if modulus_bits ~= 1024 and modulus_bits ~= 2048 then
        log.output('create_object_privkey_h(): MODULUS size not 1024 or 2048!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    local freeId, freeSlot
    local ds_prilist = self.ds_info.ds_prilist
    local attr = util.serialize_attr_privkey(pTemplate)

    obj = util.GetDSPrivKeyTemplate(t.mt.get_privkey_ds)
    obj.private = true
    obj.ds_parent_path = '/'
    obj.key_bits = modulus_bits
    local freeSlots = util.look_for_free_slots(ds_prilist, 1, 1)
    log.output('create_object_privkey_h(): freeSlots:', repr(freeSlots))
    
    if table.getn(freeSlots) == 0 then
        log.output('create_object_privkey_h(): no more slots available')
        return CKR.DEVICE_MEMORY
    end
    freeSlot = freeSlots[1]
    freeId = freeSlot
    fid_val = util.objFIDS.ePrivKey + bin.flags(freeId)
    fid_attr = fid_val + bin.flags('0x100')
    obj.ds_id = string.format('%04X', fid_val.asnumber )  -- fid oggetto DS
    obj.path = obj.ds_parent_path .. hexf('%>%H', fid_val.asnumber )
    obj.num = freeId
    obj.slot = freeSlot
    obj.group = 0
    obj.index = freeId
    
    
    local rsaInfos = {
        n = pTemplate[CKA.MODULUS],
        e = pTemplate[CKA.PUBLIC_EXPONENT],
        d = _pad_bignum(pTemplate[CKA.PRIVATE_EXPONENT],modulus_bytes),
        p = _pad_bignum(pTemplate[CKA.PRIME_1], modulus_bytes/2),
        q = _pad_bignum(pTemplate[CKA.PRIME_2], modulus_bytes/2),
        dp = _pad_bignum(pTemplate[CKA.EXPONENT_1], modulus_bytes/2),
        dq = _pad_bignum(pTemplate[CKA.EXPONENT_2], modulus_bytes/2),
        ip = _pad_bignum(pTemplate[CKA.COEFFICIENT], modulus_bytes/2),
        bmDelete = VaultICSmartCard.ACCESS_PIN,
        bmExecute = VaultICSmartCard.ACCESS_PIN,
    }
    
    
    local pcRes, theErrorT = pcall(function()
        self.inside_hcard:delete_key(0, freeId)
        self.inside_hcard:put_rsa_key(rsaInfos, nul, nil, 0, freeId)
        -- crea gli attributi della chiave privata
        attr_file_size =string.len(attr)
        self:create_file( hexf("%>%H", fid_attr.asnumber), attr_file_size, true)
        self:write_file(0, attr)
    end)
    if not pcRes then
        log.output('create_object_privkey_h(): error:', theErrorT)
        if self.inside_hcard.last_sw == hexf("6A84") then
            log.output('create_object_privkey_h(): no more memory available')
            return CKR.DEVICE_MEMORY
        else
            return CKR.FUNCTION_FAILED
        end
    end
    -- update objects list
    ds_prilist[freeSlot].usage = 255
    ds_prilist[freeSlot].id = hexf(obj.ds_id)
    ds_prilist[freeSlot].id_numeric = tonumber(obj.ds_id, 16)
    ds_prilist[freeSlot].infos = obj.key_bits
    
    self:write_objlist(false) -- write private list
    
    -- adds new handle to the list
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

function t.mt:create_object_privkey(pTemplateOrig, as_local)
    log.output('create_object_privkey()')
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    local pTemplate = utility.clone_table(pTemplateOrig)
    pTemplate[CKA.LOCAL] = eCK.BBOOL(as_local)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    pTemplate = utility.clone_table(pTemplate)
    pTemplate[CKA.ALWAYS_AUTHENTICATE] = nil
    if not pTemplate[CKA.MODULUS] or not pTemplate[CKA.PUBLIC_EXPONENT] 
        or not pTemplate[CKA.PRIVATE_EXPONENT] then
        log.output('create_object_privkey(): MODULUS or PUBLIC_EXPONENT or PRIVATE_EXPONENT not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    local fid_val, fid_attr
    local attr_file_size = 0

    local modulus_bytes = string.len(pTemplate[CKA.MODULUS])
    local modulus_bits = string.len(pTemplate[CKA.MODULUS]) * 8
    if modulus_bits ~= 1024 and modulus_bits ~= 2048 then
        log.output('create_object_privkey(): MODULUS size not 1024 or 2048!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    local freeId, freeSlot
    local ds_prilist = self.ds_info.ds_prilist
    local attr = util.serialize_attr_privkey(pTemplate)

    obj = util.GetDSPrivKeyTemplate(t.mt.get_privkey_ds)
    obj.private = true
    obj.ds_parent_path = '/'
    obj.key_bits = modulus_bits
    local freeSlots = util.look_for_free_slots(ds_prilist, 1, 1)
    log.output('create_object_privkey(): freeSlots:', repr(freeSlots))
    
    if table.getn(freeSlots) == 0 then
        log.output('create_object_privkey(): no more slots available')
        return CKR.DEVICE_MEMORY
    end
    freeSlot = freeSlots[1]
    freeId = freeSlot
    fid_val = bin.flags(freeId) + util.objFIDS.ePrivKey
    fid_attr =  bin.flags('0x0100') + bin.flags(freeId) + util.objFIDS.ePrivKey
    obj.ds_id = string.format('%04X', fid_val.asnumber )  -- fid oggetto DS
    obj.path = obj.ds_parent_path .. hexf('%>%H', fid_val.asnumber )
    obj.num = freeId
    obj.slot = freeSlot
    obj.imported = true
    obj.group = 0
    obj.index = freeId
    
    
    assert(self.ds_info.aes_key)
    assert(self.ds_info.aes_check)
    assert(pTemplate[CKA.PRIVATE_EXPONENT])
    --print("self.ds_info.aes_key:", hex.hexify(self.ds_info.aes_key))
    --print(hex.hexify(_pad_bignum(pTemplate[CKA.PRIVATE_EXPONENT],modulus_bytes)))
    --print(hex.hexify(self.ds_info.aes_check))
    
                                        
    obj.eExponent = aes.aes_encrypt_check(
                                        self.ds_info.aes_key,
                                        _pad_bignum(pTemplate[CKA.PRIVATE_EXPONENT],modulus_bytes),
                                        self.ds_info.aes_check
                                        )

    local pcRes, theErrorT = pcall(function()
        -- crea gli attributi della chiave privata
        attr_file_size = string.len(obj.eExponent)
        self:create_file( hexf("%>%H", fid_val.asnumber), attr_file_size, true)
        self:write_file(0, obj.eExponent)
        
        -- crea gli attributi della chiave privata
        attr_file_size =string.len(attr)
        self:create_file( hexf("%>%H", fid_attr.asnumber), attr_file_size, true)
        self:write_file(0, attr)
    end)
    if not pcRes then
        log.output('create_object_privkey(): error:', theErrorT)
        if self.inside_hcard.last_sw == hexf("6A84") then
            log.output('create_object_privkey(): no more memory available')
            return CKR.DEVICE_MEMORY
        else
            return CKR.FUNCTION_FAILED
        end
    end
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] and not t._is_private_attribute(k) then
            obj[k] = pTemplate[k]
        end
    end
    
    -- update objects list
    ds_prilist[freeSlot].usage = 255
    ds_prilist[freeSlot].id = hexf(obj.ds_id)
    ds_prilist[freeSlot].id_numeric = tonumber(obj.ds_id, 16)
    ds_prilist[freeSlot].infos = (bin.flags(obj.key_bits) + bin.flags("0x8000")).asnumber
    
    self:write_objlist(false) -- write private list
    
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    return CKR.OK, self.attributes.max_index
end


function t.mt:create_object_certificate(pTemplate)
    log.output('create_object_certificate()', pTemplate)
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    if not pTemplate[CKA.VALUE] then
        log.output('create_object_certificate(): VALUE not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local freeId, freeSlot
    local ds_publist = self.ds_info.ds_publist
    local attr = util.serialize_attr_cert(pTemplate)
    local fid_val, fid_attr
    
    local cert_value = pTemplate[CKA.VALUE]
    local cpr = zlib.compresscer( cert_value )
    local decpr = cpr and zlib.decompresscer(cpr)
    if decpr == cert_value then
        cert_value = cpr
        pcall(function()
        log.output('create_object_certificate(): cpr ratio:', 
            string.len(cpr)/string.len(pTemplate[CKA.VALUE]))
        end)
    else
        log.output('create_object_certificate(): compression failed!')
    end
    
    obj = util.GetDSCertTemplate(t.mt.get_certificate_ds)
    obj.private = false
    obj.ds_parent_path = '/'
    obj.size = string.len(cert_value)
    local freeSlots = util.look_for_free_slots(ds_publist, 1, 1)
    log.output('create_object_certificate(): freeSlots:', repr(freeSlots))
    
    if table.getn(freeSlots) == 0 then
        log.output('create_object_certificate(): no more slots available')
        return CKR.DEVICE_MEMORY
    end
    freeSlot = freeSlots[1]
    freeId = freeSlot
    fid_val = util.objFIDS.eCert + bin.flags(freeId)
    fid_attr = fid_val + bin.flags('0x100')
    obj.ds_id = string.format('%04X', fid_val.asnumber )  -- fid DS
    obj.path = obj.ds_parent_path .. hexf('%>%H', fid_val.asnumber )
    obj.num = freeId
    obj.slot = freeSlot
    
    local pcRes, theErrorT = pcall(function()
        -- crea il file del certificato non CNS
        local cert_file_len = string.len(cert_value )
        self:create_file( hexf("%>%H", fid_val.asnumber), cert_file_len, true)
        self:write_file(0, cert_value)
        
        -- crea gli attributi del certificato
        local attr_file_len = string.len(attr)
        self:create_file( hexf("%>%H", fid_attr.asnumber), attr_file_len, true)
        self:write_file(0, attr)
        
    end)
    if not pcRes then
        log.output('create_object_certificate(): error:', theErrorT)
        if self.inside_hcard.last_sw == hexf("6A84") then
            log.output('create_object_certificate(): no more memory available')
            return CKR.DEVICE_MEMORY
        else
            return CKR.FUNCTION_FAILED
        end
    end
    

    -- update objects list
    ds_publist[freeSlot].usage = 255
    ds_publist[freeSlot].id = hexf(obj.ds_id)
    ds_publist[freeSlot].id_numeric = tonumber(obj.ds_id, 16)
    ds_publist[freeSlot].infos = obj.size
    
    self:write_objlist(true) -- write public list
    
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    
    return CKR.OK, self.attributes.max_index
end

function t.mt:is_ds(pTemplate)
    local res
    if not self.ds_info or not self.ds_info.fips then
        res =  false
    else
        res = string.sub(pTemplate[CKA.ID] or '', 1, 2) == "DS" or string.sub(pTemplate[CKA.LABEL] or '', 1, 2) == "DS"
    end
    log.output('is_ds(): is DS object:', res)
    return res
end

function t.mt:generate_key_pair(pMechanism, templatePub, templatePriv)
    local modulus, pubexp
    log.output('generate_key_pair()', templatePub, templatePriv)
    if self.userType ~= CKU.USER then
        log.output('generate_key_pair(): not loggen in, userType', self.userType)
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local objPriv, fid_attr, fid_val

    local templatePub1 = utility.clone_table(templatePub)
    local templatePriv1 = utility.clone_table(templatePriv)
    
    if templatePub1[CKA.ID] then
        templatePriv1[CKA.ID] = templatePub1[CKA.ID]
    elseif templatePriv1[CKA.ID] then
        templatePub1[CKA.ID] = templatePriv1[CKA.ID]
    end 

    local isds = self:is_ds(templatePub1)
    
    local modulus_bits, try_2048_pregen
    local cka_modulus_bits = templatePub1[CKA.MODULUS_BITS] or templatePriv1[CKA.MODULUS_BITS] or eCK.ULONG(1024)
    if not cka_modulus_bits or cka_modulus_bits == eCK.ULONG(1024) then
        modulus_bits = 1024
    elseif cka_modulus_bits == eCK.ULONG(2048) then
        modulus_bits = 2048
        try_2048_pregen = (not isds)
        log.output('generate_key_pair(): try_2048_pregen:', try_2048_pregen )
    else
        log.output('generate_key_pair(): key size invalid:', hex.hexify(cka_modulus_bits) )
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
        
    if self.ds_info.optimize then
        self:invalidate_xproc_cache()
        log.output('generate_key_pair(): optimize enabled')
        local rsa = require("rsa")
        local r
        local starttime = os.time()
        
        local transactionDisabled = self.hcard:transactionsdisabled()
        self.hcard:disabletransactions(false)
        
        log.output('generate_key_pair(): ending transaction...')
        if transactionDisabled then
            self.hcard:endtransaction()
        else
            self:end_transaction()
        end

        log.output('generate_key_pair(): transaction end')
        
        for k=1,5 do
            r = nil
            local pcRes, theErrorT  =pcall(function()
                r = {rsa.gen_key(modulus_bits, 65537)}
            end)
            if pcRes then
                break
            end
        end
        
        log.output('generate_key_pair(): starting transaction...')
        if transactionDisabled then
            self.hcard:begintransaction()
        else
            self:begin_transaction()
        end
        self.hcard:disabletransactions(transactionDisabled)
        log.output('generate_key_pair(): transaction started')

        if not r then
            log.output('generate_key_pair(): internal error')
            return CKR.FUNCTION_FAILED
        end
        
        self:verify_loggedon_user()
        
        templatePriv1[CKA.CLASS] = eCK.ULONG(CKO.PRIVATE_KEY)
        templatePriv1[CKA.KEY_TYPE] = eCK.ULONG(CKK.RSA)
        templatePriv1[CKA.MODULUS] = hex.hexf(r[1])
        templatePriv1[CKA.PUBLIC_EXPONENT] = hex.hexf(r[2])
        templatePriv1[CKA.PRIVATE_EXPONENT] = hex.hexf(r[3])
        templatePriv1[CKA.PRIME_1] = hex.hexf(r[4])
        templatePriv1[CKA.PRIME_2] = hex.hexf(r[5])
        templatePriv1[CKA.EXPONENT_1] = hex.hexf(r[6])
        templatePriv1[CKA.EXPONENT_2] = hex.hexf(r[7])
        templatePriv1[CKA.COEFFICIENT] = hex.hexf(r[8])
        
        local rv, hPubk, hPrivk
        rv, hPrivk = self:create_object_privkey(templatePriv1, true)
        if rv ~= CKR.OK then
            return rv
        end
       
        local timeElapsed = os.time() - starttime
        local minWait = 0
        local maxWait = 9
        if timeElapsed < 2 then
            minWait = 1
            maxWait = 3
        elseif timeElapsed < 3 then
            minWait = 0
            maxWait = 3
        end
        
        for xx=1,math.random(minWait, maxWait) do
            self.hcard:status() -- in caso di reset effettua una reconnect
            w32.sleep(1000)
        end
        templatePub1[CKA.CLASS] = eCK.ULONG(CKO.PUBLIC_KEY)
        templatePub1[CKA.KEY_TYPE] = eCK.ULONG(CKK.RSA)
        templatePub1[CKA.MODULUS] = templatePriv1[CKA.MODULUS]
        templatePub1[CKA.PUBLIC_EXPONENT] = templatePriv1[CKA.PUBLIC_EXPONENT]
        rv, hPubk = self:create_object_pubkey(templatePub1, true)
        if rv ~= CKR.OK then
            self:destroy_object(hPrivk)
            return rv
        end
        
        return CKR.OK, hPubk, hPrivk
    end
    
    local freeId, freeSlot
    local ds_prilist = self.ds_info.ds_prilist
    local attr
    local sm_enc, sm_sig
    objPriv = util.GetDSPrivKeyTemplate(t.mt.get_privkey_ds)
    objPriv.private = true
    objPriv.ds_parent_path = '/'
    objPriv.key_bits = modulus_bits
    
    local freeSlotsPub = util.look_for_free_slots(self.ds_info.ds_publist, 1, 1)
    local freeSlots = util.look_for_free_slots(ds_prilist, 1, 1, try_2048_pregen)
    log.output('generate_key_pair(): freeSlotsPub:', repr(freeSlotsPub))
    log.output('generate_key_pair(): freeSlots:', repr(freeSlots))
    
    if table.getn(freeSlots) == 0 then
        log.output('generate_key_pair(): no more private slots available, freeSlots:', repr(freeSlots))
        return CKR.DEVICE_MEMORY
    end
    if table.getn(freeSlotsPub) == 0 then
        log.output('generate_key_pair(): no more public slots available, freeSlotsPub:', repr(freeSlotsPub))
        return CKR.DEVICE_MEMORY
    end
    freeSlot = freeSlots[1]
    freeId = freeSlot
    fid_val = util.objFIDS.ePrivKey + bin.flags(freeId)
    fid_attr = fid_val + bin.flags('0x100')
    objPriv.ds_id = hex.hexify(hex.hexf("%H",  fid_val.asnumber) ) -- fid DS
    objPriv.path = objPriv.ds_parent_path -- path in cui si trova il BSO
    objPriv.num = freeId
    objPriv.slot = freeSlot

    self:verify_loggedon_user()
    log.output('GENERATING KEY PAIR:', objPriv.num)
    
    
    local deleteKey = true
    if not isds then
        if ds_prilist[freeSlot].usage == 1 then
            log.output('TRYING PREGENERATED KEY PAIR', objPriv.num)
            local pcRes, theErrorT = pcall(function()
                modulus, pubexp = self.inside_hcard:read_public_key(1, freeId)
            end)
            if not pcRes then
                log.output('ERROR READING PREGENERATED PUBLIC KEY', theErrorT)    
                deleteKey = true
            else
                deleteKey = false
            end
        end
    end
    
    objPriv.group = 0
    objPriv.index = freeId
    
    self:invalidate_xproc_cache()
    
    local pubKeyInfos = {}
    local privKeyInfos = {}
    pubKeyInfos.crt = false
    pubKeyInfos.keybits = modulus_bits
    pubKeyInfos.bAlgoID = tonumber("73", 16)
    pubKeyInfos.group   = 1
    pubKeyInfos.index   = freeId
    pubKeyInfos.bmReadList = VaultICSmartCard.ACCESS_PUBLIC
    pubKeyInfos.bmWriteCreate  = VaultICSmartCard.ACCESS_PUBLIC
    pubKeyInfos.bmDelete  = VaultICSmartCard.ACCESS_PUBLIC
    pubKeyInfos.bmExecute = VaultICSmartCard.ACCESS_PUBLIC
    privKeyInfos.group = 0
    privKeyInfos.index = freeId
    privKeyInfos.bmReadList = bin.flags(0)
    privKeyInfos.bmWriteCreate  = VaultICSmartCard.ACCESS_PIN
    privKeyInfos.bmDelete  = VaultICSmartCard.ACCESS_PIN
    privKeyInfos.bmExecute = VaultICSmartCard.ACCESS_PIN
    self.inside_hcard:select()
    
    if deleteKey then
        log.output('delete as normal user', objPriv.num)
        self.inside_hcard:delete_key(0, freeId)
        self.inside_hcard:delete_key(1, freeId) -- // chiave pubblica associata
    end
    
    if isds then
        if modulus_bits < 2048 then
            log.output('generate_key_pair(): FIPS key size invalid:', modulus_bits )
            return CKR.ATTRIBUTE_VALUE_INVALID
        end
        self:verify_loggedon_user(true)
        pubKeyInfos.bAlgoID = tonumber("70", 16)
        -- pubKeyInfos.crt = false
        privKeyInfos.bmWriteCreate  = VaultICSmartCard.ACCESS_PIN_FIPS
        privKeyInfos.bmDelete  = VaultICSmartCard.ACCESS_PIN + VaultICSmartCard.ACCESS_PIN_FIPS
        privKeyInfos.bmExecute = VaultICSmartCard.ACCESS_PIN_FIPS
        
        if deleteKey then
            log.output('delete as FIPS user', objPriv.num)
            self.inside_hcard:delete_key(0, freeId)
            self.inside_hcard:delete_key(1, freeId) -- // chiave pubblica associata
        end
    end
    
    if deleteKey then
    
        log.output('NORMAL KEY PAIR GENERATION', objPriv.num)
        
        self.inside_hcard:generate_key_pair(pubKeyInfos, privKeyInfos)
        modulus, pubexp =  self.inside_hcard:read_public_key(1, freeId)
        self.inside_hcard:delete_key(1, freeId) -- // chiave pubblica associata, as current user
    
    end
    
  
    templatePub1[CKA.MODULUS] = modulus
    templatePub1[CKA.PUBLIC_EXPONENT] = pubexp
    templatePriv1[CKA.MODULUS] = modulus
    templatePriv1[CKA.PUBLIC_EXPONENT] = pubexp
    templatePriv1[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(isds)
    

    if isds then
        self:verify_loggedon_user()
    end
    
    templatePub1[CKA.CLASS] = eCK.ULONG(CKO.PUBLIC_KEY)
    templatePub1[CKA.KEY_TYPE] = eCK.ULONG(CKK.RSA)
    attr = util.serialize_attr_privkey(templatePriv1)
    
    -- crea gli attributi della chiave privata
    local attr_file_len = string.len(attr)
    self:create_file( hexf("%>%H", fid_attr.asnumber), attr_file_len, true)
    self:write_file(0, attr)
    
    -- update objects list
    ds_prilist[freeSlot].usage = 255
    ds_prilist[freeSlot].id = hexf(objPriv.ds_id)
    ds_prilist[freeSlot].id_numeric = tonumber(objPriv.ds_id, 16)
    ds_prilist[freeSlot].infos = objPriv.key_bits
    self:write_objlist(false) -- write private list

    -- adds new handle to the list
    local hPrivk
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPriv
    hPrivk = self.attributes.max_index
    
    local rv, hPubk = self:create_object_pubkey(templatePub1)
    log.output('create_object(pubkey): result:', rv, 'handle:', hPubk)
    
    log.output('generate_key_pair(): success, returning', hPubk, hPrivk)
    self:update_free_memory()
    return CKR.OK, hPubk, hPrivk
end

function t.mt:create_object_data(pTemplate)
    log.output('create_object_data()', pTemplate)
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    local dataValue = pTemplate[CKA.VALUE] or ''
    
    local freeId, freeSlot
    local attr = util.serialize_attr_data(pTemplate)
    local fid_val, fid_attr
    local objectType = util.objFIDS.eData
    local ds_objlist = self.ds_info.ds_publist
    local startId, startSlot = 2, 4
    obj = util.GetDSDataTemplate(t.mt.get_data_ds)
    obj.private = util.is_ck_true(pTemplate[CKA.PRIVATE])
    if obj.private then
        obj.ds_parent_path = '/'
        objectType = util.objFIDS.eDataP
        ds_objlist = self.ds_info.ds_prilist
    else
        obj.ds_parent_path = '/'
    end
    obj.size = string.len(dataValue)
    local freeSlots = util.look_for_free_slots(ds_objlist, 1, 1)
    log.output('create_object_data(): freeSlots:', repr(freeSlots))
    
    if table.getn(freeSlots) == 0 then
        log.output('create_object_data(): no more space available')
        return CKR.DEVICE_MEMORY
    end
    freeSlot = freeSlots[1]
    freeId = freeSlot
    fid_val = objectType + bin.flags(freeId)
    fid_attr = fid_val + bin.flags('0x100')
    obj.ds_id = string.format('%04X', fid_val.asnumber )  -- fid DS
    obj.path = obj.ds_parent_path .. hexf('%>%H', fid_val.asnumber )
    obj.num = freeId
    obj.slot = freeSlot
    
    local fileLen = math.max(128, string.len(dataValue) )
    self:create_file( hexf("%>%H", fid_val.asnumber), fileLen, not obj.private)
    self:write_file(0, dataValue)

    -- crea gli attributi del data file
    local attr_file_len = math.max(64, string.len(attr))
    self:create_file( hexf("%>%H", fid_attr.asnumber), attr_file_len, true)
    self:write_file(0, attr)
    
    -- update objects list
    ds_objlist[freeSlot].usage = 255
    ds_objlist[freeSlot].id = hexf(obj.ds_id)
    ds_objlist[freeSlot].id_numeric = tonumber(obj.ds_id, 16)
    ds_objlist[freeSlot].infos = obj.size
    
    self:write_objlist(not obj.private) -- write public list
    
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    return CKR.OK, self.attributes.max_index
end


function t.mt:create_object(pTemplate)
    self:verify_loggedon_user()
    local res, hValue
    self:invalidate_xproc_cache()
    
    if pTemplate[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        res, hValue = self:create_object_pubkey(pTemplate)
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        res, hValue = self:create_object_privkey(pTemplate)
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        res, hValue =  self:create_object_certificate(pTemplate)
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        res, hValue =  self:create_object_data(pTemplate)        
        
    else
        log.output('create_object(): unsupported object class:', hex.hexify(pTemplate[CKA.CLASS] or ''))
        res =  CKR.ATTRIBUTE_VALUE_INVALID
    end
    self:update_free_memory()
    log.output('create_object(): res=', res, "handle=", hValue)
    return res, hValue
end

function t.mt:destroy_object(hObject)
    log.output('destroy_object(): ', hObject)

    self:verify_loggedon_user()
    
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hObject]
    local ds_objlist = self.ds_info.ds_publist
    if obj == nil then
        log.output('destroy_object(): specified handle invalid: ' .. hObject)
        return CKR.OBJECT_HANDLE_INVALID
    end

    self:invalidate_xproc_cache()
    
    if obj.private then ds_objlist = self.ds_info.ds_prilist end
    
    local fid_val = hexf(obj.ds_id)
    local fid_attr = hexf('%H', (bin.flags( tonumber(obj.ds_id, 16)) + bin.flags('0x100')).asnumber )
    
    log.output('destroy_object(): deleting DS attributes file:', obj.ds_parent_path .. hex.hexify(fid_attr))
    pcall(function()
            self.inside_hcard:delete_file(obj.ds_parent_path .. fid_attr)
          end)
    log.output('destroy_object(): deleting DS value file:', obj.ds_parent_path .. hex.hexify(fid_val))
    pcall(function()
            self.inside_hcard:delete_file(obj.ds_parent_path .. fid_val)
        end)
    if obj.group and obj.index then
        log.output('destroy_object(): deleting as normal user KEY at group/index:', obj.group, obj.index)
        pcall(function()
                self.inside_hcard:delete_key(obj.group, obj.index)
            end)
            
        if self.ds_info and self.ds_info.fips then
            log.output('destroy_object(): deleting as FIPS user KEY at group/index:', obj.group, obj.index)
            
            pcall(function()
                    self:verify_loggedon_user(true)
                    self.inside_hcard:delete_key(obj.group, obj.index)
                end)
                self:verify_loggedon_user()
        end
    end
    
    local usage = 0
    self.attributes[hObject] = nil
    ds_objlist[obj.slot].usage = usage
    
    self:write_objlist(not obj.private)
    self:update_free_memory()
    
    return CKR.OK
end

function t.mt:set_attribute_value(hObject, pTemplate)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hObject]
    if obj == nil then
        log.output('set_attribute_value(): specified handle invalid: ' .. hObject)
        return CKR.OBJECT_HANDLE_INVALID
    end  

    self:verify_loggedon_user()
    
    self:invalidate_xproc_cache()
    local res
    if obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        if not obj.populated then self:get_pubkey_ds(hObject, CKA.CLASS) end
        res = self:set_attribute_value_pubkey(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        if not obj.populated then self:get_privkey_ds(hObject, CKA.CLASS) end
        res =  self:set_attribute_value_privkey(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        if not obj.populated then self:get_certificate_ds(hObject, CKA.CLASS) end
        res =  self:set_attribute_value_certificate(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        if not obj.populated then self:get_data_ds(hObject, CKA.CLASS) end
        res =  self:set_attribute_value_data(hObject, pTemplate)        
        
    else
        log.output('set_attribute_value(): unsupported object class:', hex.hexify(obj[CKA.CLASS]))
        res =  CKR.ATTRIBUTE_VALUE_INVALID
    end
   
    self:update_free_memory()
    return res
end

function t.mt:set_attribute_value_privkey(hObj, pTemplate)
    log.output('set_attribute_value_privkey()')
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    local obj = self.attributes[hObj]
    
    local fid_attr = bin.flags('0x0100') + bin.flags(obj.num) + util.objFIDS.ePrivKey
    
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
    local attr = util.serialize_attr_privkey(templateNew)
    
    local attr_file_size =string.len(attr)
    self:create_file( hexf("%>%H", fid_attr.asnumber), attr_file_size, false)
    self:write_file(0, attr)
    
    -- aggiorna i valori in cache
    for k, v in pTemplate do
        obj[k] = v
    end
    return CKR.OK
end



function t.mt:set_attribute_value_certificate(hObj, pTemplate)
    log.output('set_attribute_value_certificate()')
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end

    local obj = self.attributes[hObj]
    
    for k, v in pTemplate do
        if k ~= CKA.ID and k ~= CKA.LABEL and k ~= CKA.SUBJECT
            and k ~= CKA.ISSUER and k ~= CKA.SERIAL_NUMBER
            and k ~= CKA.MODIFIABLE and k ~= CKA.TRUESTED  then
            return CKR.ATRIBUTE_TYPE_INVALID
        end
    end
    local fid_attr = bin.flags('0x0100') + bin.flags(obj.num) + util.objFIDS.eCert
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
    local attr = util.serialize_attr_cert(templateNew)
    
    local attr_file_size =string.len(attr)
    self:create_file( hexf("%>%H", fid_attr.asnumber), attr_file_size, true)
    self:write_file(0, attr)

    -- aggiorna i valori in cache
    for k, v in pTemplate do
        obj[k] = v
    end
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
    local fid_attr = bin.flags('0x0100') + bin.flags(obj.num) + util.objFIDS.ePubKey

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
    local attr = util.serialize_attr_pubkey(templateNew)
    
    local attr_file_size =string.len(attr)
    self:create_file( hexf("%>%H", fid_attr.asnumber), attr_file_size, true)
    self:write_file(0, attr)

    -- aggiorna i valori in cache
    for k, v in pTemplate do
        obj[k] = v
    end
    return CKR.OK
end



function t.mt:set_attribute_value_data(hObj, pTemplate)
    log.output('set_attribute_value_data()')
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    local obj = self.attributes[hObj]
    
    for k, v in pTemplate do
        if k ~= CKA.OBJECT_ID and k ~= CKA.LABEL and k ~= CKA.APPLICATION
            and k ~= CKA.VALUE
            and k ~= CKA.MODIFIABLE then
            return CKR.ATRIBUTE_TYPE_INVALID
        end
    end
    local fid_attr = bin.flags('0x0100') + bin.flags(obj.num)
    if obj.private then
        fid_attr = fid_attr + util.objFIDS.eDataP
    else
        fid_attr = fid_attr + util.objFIDS.eData
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
    local attr = util.serialize_attr_data(templateNew)
    
    local attr_file_size =string.len(attr)
    self:create_file( hexf("%>%H", fid_attr.asnumber), attr_file_size, true)
    self:write_file(0, attr)

    -- aggiorna i valori in cache
    for k, v in pTemplate do
        obj[k] = v
    end
    return CKR.OK
end


function t.mt:set_label(Puk, label)
    local rv = CKR.OK
    local info = self:get_info()
    if Puk and string.len(Puk) > 0 then
        rv = self:verify_pin(Puk, CKU.SO)
        if rv ~= CKR.OK then
            return rv
        end
    else
        self:verify_loggedon_user()
    end
    local pcRes, theErrorT = pcall(function()
        local fInfo = self.inside_hcard:select("/status")
        local value = label .. string.rep(" ", 32 - string.len(label))
        value = string.sub(value, 1, 32)
        self.inside_hcard:mupdate_binary(0, value)
        self.info.label = value
        if self.ds_info and self.ds_info.token_info then 
            self.ds_info.token_info.label = value
        end
    end)
    if not pcRes then
        log.output('set_label(): error:', theErrorT)
        rv = CKR.FUNCTION_FAILED
    end
    return rv
end

function t.mt:flush_cache()
    if self.cfg["xproc"] ~= "true" then
        return false
    end
    local changed, cache_id
    if self._cache_id == nil then
        log.output("token-inside:flush_cache(): initializing _cache_id")
        changed, self._cache_id = utility.has_token_changed(self, "cache", 0)
        log.output("token-inside:flush_cache(): initialize: _cache_id:", self._cache_id)
    end
    changed, cache_id = utility.has_token_changed(self, "cache", self._cache_id)
    if changed then
        log.output("token-inside:flush_cache(): token has changed!")
        self._cache_id = cache_id
        self.info = nil -- rimuove cache oggetti
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


function t.mt:get_special_ids(id_class)
    return {}
end


function t.mt:valid()
    return self.inside_hcard:valid()
end

return t

--===========================================================================
end
}
_LOADED['VaultICSmartCard'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
local hex = require 'hex'
local h2i, hexf, hexify = hex.h2i, hex.hexf, hex.hexify
local rsa
local zlib = require 'zlib'
local util = require "utility"
local repr = util.repr

pcall(function() rsa = require("rsa"); end)

-- Smartcard

local Smartcard = {}


Smartcard.PIN_PADDING = 8
Smartcard.PUK_PADDING = 8
Smartcard.ID_PIN = 0
Smartcard.ID_PUK = 1
Smartcard.ID_PUBLIC = 2
Smartcard.ID_PIN_FIPS = 3
Smartcard.ID_PUK_FIPS = 4

Smartcard.ACCESS_PUBLIC = bin.flags(16 + 8 + 4 + 2 +1)
Smartcard.ACCESS_PIN = bin.flags(1)
Smartcard.ACCESS_PIN_FIPS = bin.flags(8)
Smartcard.mt = {}
Smartcard.mt.__index = Smartcard.mt


SmartcardError = {}
SmartcardError.mt = {}
SmartcardError.mt.__index = SmartcardError.mt

Smartcard.MAX_TRANSMIT_BUFFER_SIZE = 120

function SmartcardError.mt.__tostring(e)
    return "SmartcardError: " .. (e.msg or '') .. ' ;SW=' .. hex.hexify(e.sw or '') 
end

function SmartcardError.new(sw, msg)
    local e = msg .. ' ;sw=' .. hexify(sw or '')
    return e
end


function Smartcard.new(card)
    local self = {
                    PIN_PADDING=Smartcard.PIN_PADDING,
                    PUK_PADDING=Smartcard.PUK_PADDING,
                    ID_PIN=Smartcard.ID_PIN,
                    ID_PUK=Smartcard.ID_PUK,
                    ID_PIN_FIPS=Smartcard.ID_PIN_FIPS,
                    ID_PUK_FIPS=Smartcard.ID_PUK_FIPS,
                  }
    self.card = card
    setmetatable(self, Smartcard.mt)
    return self
end

local function xor_string(a, b)
    assert(string.len(a) == string.len(b))
    local res = {}
    for i=1,string.len(a) do
        table.insert(res, (bin.flags(string.byte(a, i)) ^ bin.flags(string.byte(b, i))).asnumber )
    end
    return string.char(unpack(res))
end

local function and_string(a, b)
    assert(string.len(a) == string.len(b))
    local res = {}
    for i=1,string.len(a) do
        table.insert(res, (bin.flags(string.byte(a, i)) * bin.flags(string.byte(b, i))).asnumber )
    end
    return string.char(unpack(res))
end

local function lshift_string(s, v)
    local s1 = hex.hexf(bignum.create(s, true):lshift(v):tostring(16, true))
    return string.sub(s1, -string.len(s), -1)
end

local function rshift_string(s, v)
    local s1 = hex.hexf(bignum.create(s, true):rshift(v):tostring(16, true))
    
    return string.rep("\0", string.len(s) - string.len(s1)) .. s1
end



local function Generate_Subkey(K)
    local nullIV = string.rep("\0", 16)
    local L = sm.aes_enc_block(K, nullIV)
    local Rb = hex.hexf("00000000000000000000000000000087")
    local L1 = lshift_string(L, 1)
    local L2
    local K1, K2
    
    if rshift_string(L, 127) == nullIV then
        K1 = L1
    else
        K1 = xor_string(Rb, L1)
    end
    
    L2 = lshift_string(K1, 1)
    if rshift_string(K1, 127) == nullIV then
        K2 = L2
    else
        K2 = xor_string(Rb, L2)
    end 
    return K1, K2
end



local function PAD(N)
    local padLen = 16-string.len(N)
    N = N .. '\128' .. string.rep('\0', (padLen-1))
    return N
end

local function AES_CMAC(K, M, length)

    local const_Bsize = 16
    local const_Zero  =  string.rep("\0", const_Bsize)

    M      = string.sub(M, 1, length)
    local K1, K2 = Generate_Subkey(K)
    local n      = math.floor(string.len(M) / const_Bsize)
    local flag,M_last, M_n
    
    if n == 0 then
        n = 1
        flag = false
    else
        if math.mod(length , const_Bsize) == 0 then
            flag = true
        else
            n = n +1
            flag = false
        end
    end
    
    M_n = string.sub(M, 1+ (n-1)*const_Bsize, -1)
    if flag then 
        M_last = xor_string(M_n, K1)
    else
        M_last = xor_string(PAD(M_n), K2)
    end
    
    local X = const_Zero
    local Y
    local M_i
    for i=0,n-2 do
        M_i = string.sub(M, 1+ (i*const_Bsize), (i*const_Bsize) + const_Bsize)
        Y   = xor_string(X, M_i)
        X   = sm.aes_enc_block(K, Y)
    end
    Y = xor_string(M_last, X)
    local T = sm.aes_enc_block(K, Y)

    return T
end

local function KDF(k, Label, Context, L)
    -- print("L:", L)
    local buffer1 = Label .. "\0" .. hex.hexf("%H", L) .. "\1" .. Context
    local buffer2 = Label .. "\0" .. hex.hexf("%H", L) .. "\2" .. Context
    -- print("buffer1 ", hex.hexify(buffer1))
    -- print("buffer2 ", hex.hexify(buffer2))

    local D1 = AES_CMAC(k,buffer1, string.len(buffer1))
    local D2 = AES_CMAC(k,buffer2, string.len(buffer2))
    return string.sub(D1 .. D2, 1, math.floor(L/8))
end



function Smartcard.mt:get_authentication_info(id)
    if id<0 or id>7 then
        error(SmartcardError.new(nil, 'Smartcard get_authentication_info Error: bad BSO number' ), 2)
    end
    local apdu = hexf("8025%B0007", id)
    local recv = self:transmit(apdu)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'seek file Error'), 2)
    end
    local authraw = { bin.unpack('%B%B%B%B%B', recv) }
    local authInfo = { bMethod=authraw[1], bRoles=authraw[2], bSecurityLevel=authraw[3], bRemTries=authraw[4], bMaxTries=authraw[5], }
    return authInfo
end


function Smartcard.mt:transmit(apdu)
    if self._soft_transacted then
        self:real_begin_transaction()
    end
    if self.on_transmit then
        self:on_transmit(apdu)
    end
    local sw
    local result, scarderr = self.card:transmit(apdu)
    if not result then
        error(string.format('transmit error: 0x%x', scarderr) )
    end
    sw = string.sub(result, -2, -1)
    while string.sub(sw, 1, 1) == hexf("61") or string.sub(sw, 1, 1) == hexf("6C") do
        apdu = hexf("00C00000") .. string.sub(sw, 2, 2)
        local result1, scarderr = self.card:transmit(apdu)
        if not result1 then
            error(string.format('transmit error: 0x%x', scarderr) )
        end
        sw = string.sub(result1, -2, -1)
        result = string.sub(result, 1, -3) .. result1
    end
    self.last_sw = sw
    return result
end

function Smartcard.parse_fci(value)
    local infoR = {bin.unpack("%>%L%B%B%B%B%B", value)}
    local info = {
                  size = infoR[1], 
                  bmReadList=bin.flags(infoR[2]),
                  bmWriteCreate=bin.flags(infoR[3]),
                  bmDelete=bin.flags(infoR[4]),
                  bmExecute=bin.flags(infoR[5]),
                  bmAttributes=bin.flags(infoR[6]),
                  }
    return info
end


function Smartcard.mt:get_info()
    local sw, recv
    local res = {}
    log.output('get_info()')
    local apdu = hexf('8001000035')
    
    recv = self:transmit(apdu)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'select Error'), 2)
    elseif string.len(recv) > 2 then
        res = {
            sFirmware = string.sub(recv, 1, 32),
            abSerial = string.sub(recv, 33, 40),
            bState = string.byte(recv, 41),
            bSelfTest = string.byte(recv, 42),
            bRole = string.byte(recv, 43),
            bMode = string.byte(recv, 44),
            dwSpace = bin.unpack("%>%L", string.sub(recv, 45, 48)),
            wRFU =string.sub(recv, 49, 50),
            bAttack = string.byte(recv, 51),
            wAttackCounter = string.sub(recv, 52, 53),
        }
    end
    return res
end

function Smartcard.mt:select(path)
    local sw, recv
    local template_p = '80A40000%P'
    log.output('select(): ', hexify(path or ""))
    local apdu
    if path == nil then
        path = '/' -- ROOT
    end
    apdu = hexf(template_p, path .. '\0')
    
    recv = self:transmit(apdu)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'select Error'), 2)
    elseif string.len(recv) > 2 then
        return Smartcard.parse_fci(recv)
    end
end

function Smartcard.mt:read_binary(offset, size)
    local recv
    recv = self:transmit(hexf('80FC000004%>%L', offset))
    local sw = string.sub(recv, -2, -1)
    if sw == hexf('9001') then
        return ""
    end
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'seek file Error'), 2)
    end
    recv = self:transmit(hexf('80F000%B00', math.mod(size, 256)))
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') and sw ~= hexf('9001') then
        error(SmartcardError.new(sw, 'read_binary Error'), 2)
    end
    return string.sub(recv, 1, -3)
end

function Smartcard.mt:mread_binary(offset, size)
    local buffer_size = Smartcard.MAX_TRANSMIT_BUFFER_SIZE
    local content = ''
    while size>0 do
        if size<buffer_size then buffer_size = size end
        local recv = self:read_binary(offset, buffer_size)
        offset = offset  + buffer_size
        size = size - buffer_size
        content = content .. recv
    end
    return content
end

function Smartcard.mt:verify_pin_fips(pin)
    return self:verify_role_scp3(self.ID_PIN_FIPS, 1, pin)
end

function Smartcard.mt:verify_puk_fips(puk)
    return self:verify_role_scp3(self.ID_PUK_FIPS, 8, puk)
end


function Smartcard.mt:verify_public()
    return self:verify_role(Smartcard.ID_PUBLIC, 2, "\0\0\0\000" )
end

function Smartcard.mt:verify_pin(pin)
    return self:verify_role(self.ID_PIN, 2, pin)
end

function Smartcard.mt:verify_puk(pin)
    return self:verify_role(self.ID_PUK, 16, pin)
end

function Smartcard.mt:change_pin(oldPin, newPin)
    local res = self:verify_pin(oldPin)
    if res ~=0 then
        return res
    end
    return self:change(self.ID_PIN, newPin)
end

function Smartcard.mt:change_puk(oldPin, newPin)
    local res = self:verify_puk(oldPin)
    if res ~=0 then
        return res
    end
    return self:change(self.ID_PUK, newPin)
end


function Smartcard.mt:reset_pin(Puk, newPin)
    local res = self:verify_puk(Puk)
    if res ~=0 then
        return res
    end
    self:reset_retry_counter(self.ID_PIN)
    return self:change(self.ID_PIN, newPin)
end


function Smartcard.mt:encrypt_apdu(data)
    if not data or string.len(data) == 0 then
        return ""
    else
        return sm.aes_enc_cbc(self.CENCKey, data)
    end
end

function Smartcard.mt:sign_apdu(header, data)
    local toMac = self.CMAChaining .. header .. string.char(string.len(data) + 8) .. data
    local mac = AES_CMAC(self.CMACKey, toMac, string.len(toMac))
    local apdu = header .. string.char(string.len(data) + 8) .. data .. string.sub(mac, 1, 8)
    self.CMAChaining = mac
    return apdu
end

function Smartcard.mt:sm_transmit(apdu)
    local recv
    local LE = ""
    local len = string.byte(apdu, 5)
    local data = string.sub(apdu, 6, -1)
    local encData = data
    local header = string.sub(apdu, 1, 4)
    local SEC_LEVEL_ENC  = bin.flags(1)
    local SEC_LEVEL_SIG  = bin.flags(2)
    local encSignApdu
    if len == string.len(data) +1 then
        LE = string.sub(data, -1, -1)
        log.output("LE:", LE)
        data = string.sub(data, 1, -2)
    end
    
    if self.secLevel.asnumber == 0 then
        log.output("sm_transmit(): sending plain text apdu:", hex.hexify(apdu))
        encSignApdu = apdu
    else
        local newCla = string.char((bin.flags(string.byte(apdu, 1)) + bin.flags("0x04")).asnumber)
        header = newCla .. string.sub(apdu, 2, 4)
        log.output("sm_transmit(): orig plain text apdu:", hex.hexify(apdu))
        if self.secLevel[SEC_LEVEL_ENC] then
            if string.len(data) > 0 then
                encData = self:encrypt_apdu(data)
                log.output("PT Data:", hex.hexify(data or ""))
                log.output("encData:", hex.hexify(encData or ""))
            else
                log.output("no data")
                log.output("encData:", hex.hexify(encData or ""))
            end
        end
        if self.secLevel[SEC_LEVEL_SIG] then
            encSignApdu  = self:sign_apdu(header, encData)
            log.output("sm_transmit(): signed APDU: ", hex.hexify(encSignApdu))
        else
            encSignApdu = header .. hex.hexf("%P", encData)
            log.output("sm_transmit(): no sign enabled?: ", hex.hexify(encSignApdu))
        end
    end    
    
    recv = self:transmit(encSignApdu)
    return recv
end

function Smartcard.mt:generate_random(length)
    local recv = self:transmit(hexf('802d00%B00', math.mod(length, 256)))
    local sw = string.sub(recv, -2, -1)
    if sw == hexf('9000') then
        return string.sub(recv, 1, -3)
    end
end

function Smartcard.mt:verify_role_scp3(id, role, pin, enc)
    log.output("verify_role_scp3():", id, role, pin, enc)
    local Ch = sm.gen_random(8)
    local recv = self:transmit(hexf('8028000000'))
    local apduInitializeUpdate = hex.hexf("8088%B%B%P", id, role, Ch)
    local recv = self:transmit(apduInitializeUpdate)
    local sw = string.sub(recv, -2, -1)
    local secLevel = enc and tonumber("03", 16) or 0
    local CMACKey, RMACKey, CENCKey, ACdCalc, AChCalc, CMAC1Calc
    if sw == hexf('9000') then
        -- local D = string.sub(recv, 1, 10)
        -- local Ki = string.sub(recv, 11, 11)
        -- local bSCP = string.sub(recv, 12, 12)
        local Cd = string.sub(recv, 13, 20)
        local ACd = string.sub(recv, 21, 28)
        local SMACKey = md.pkcs5_pbkdf2(pin, "000001", 32, 1000)
        local SENCKey = md.pkcs5_pbkdf2(pin, "000002", 32, 1000)
        log.output("verify_role_scp3() SMACKey: ", hex.hexify(SMACKey))
        log.output("verify_role_scp3() SENCKey:", hex.hexify(SENCKey))

        CMACKey = KDF(SMACKey, hex.hexf("000000000000000000000006"), Ch .. Cd, 256)
        RMACKey = KDF(SMACKey, hex.hexf("000000000000000000000007"), Ch .. Cd, 256)
        CENCKey = KDF(SENCKey, hex.hexf("000000000000000000000004"), Ch .. Cd, 256)
        ACdCalc = KDF(CMACKey, hex.hexf("000000000000000000000000"), Ch .. Cd, 64)
        AChCalc = KDF(CMACKey, hex.hexf("000000000000000000000001"), Ch .. Cd, 64)
        SMACKey = nil
        SENCKey = nil
        collectgarbage() -- forza liberazione della memoria inutilizzata
        assert (ACdCalc == ACd)
        
        local apduExternalAuthenticate = hex.hexf("8482%B0010", secLevel) .. string.sub(AChCalc, 1, 8)
        log.output("verify_role_scp3(): apduExternalAuthenticate(1):", hex.hexify(apduExternalAuthenticate))
        
        local CHAINING=string.rep("\0", 16)
        local toMac = CHAINING .. apduExternalAuthenticate
        CMAC1Calc = AES_CMAC(CMACKey,toMac, string.len(toMac))
        log.output("verify_role_scp3(): CMAC1Calc:", hex.hexify(CMAC1Calc))
        apduExternalAuthenticate = apduExternalAuthenticate .. string.sub(CMAC1Calc, 1, 8)
        log.output("verify_role_scp3(): apduExternalAuthenticate(2):", hex.hexify(apduExternalAuthenticate))
        local recv = self:transmit(apduExternalAuthenticate)
        sw = string.sub(recv, -2, -1)
    end
    if sw == hexf('6986') then
        return 2, 'Authentication blocked'
    elseif string.sub(hexify(sw), 1, 2) == '63' or sw == hexf("6700") then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        self.CMAChaining = CMAC1Calc
        self.CMACKey = CMACKey
        self.RMACKey = RMACKey
        self.CENCKey = CENCKey
        self.secLevel = bin.flags(secLevel)
        return 0, 'Authentication succeeded'
        
    else
        log.output('verify_role(): Error ' .. hexify(sw) )
        error(SmartcardError.new(sw, 'verify_role Error' ), 2)
    end

end

function Smartcard.mt:verify_role(id, role, pin)
    log.output('verify_role():', id, role, pin )
    if id<0 or id>7 then
        error(SmartcardError.new(nil, 'Smartcard verify_role Error: bad BSO number' ), 2)
    end
    local recv = self:transmit(hexf('8028000000'))
    local recv = self:transmit(hexf('8020%B%B%P', id, role, pin))
    local sw = string.sub(recv, -2, -1)
    if sw == hexf('6986') then
        return 2, 'Authentication blocked'
    elseif string.sub(hexify(sw), 1, 2) == '63' or sw == hexf("6700") then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        return 0, 'Authentication succeeded'
    else
        log.output('verify_role(): Error ' .. hexify(sw) )
        error(SmartcardError.new(sw, 'verify_role Error' ), 2)
    end
end


function Smartcard.mt:change_pin_fips(oldPin, newPin)
    return self:change_fips(self.ID_PIN_FIPS, 1, oldPin, newPin)
end

function Smartcard.mt:change_puk_fips(oldPin, newPin)
    return self:change_fips(self.ID_PUK_FIPS, 8, oldPin, newPin)
end

function Smartcard.mt:change_fips(id, role, oldPin, newPin)
    log.output('change_fips():', id, role, oldPin, newPin)
    if id<0 or id>7 then
        error(SmartcardError.new(nil, 'Smartcard FIPS change Error: bad BSO number' ), 2)
    end
    local infos = self:get_authentication_info(id)
    local SMACKey = md.pkcs5_pbkdf2(newPin, "000001", 32, 1000)
    local SENCKey = md.pkcs5_pbkdf2(newPin, "000002", 32, 1000)
    local newKeys = hex.hexf("870000%P", SMACKey) .. hex.hexf("870000%P", SENCKey)
    local authData = hexf("%B%B%B00%B%>%H", infos.bMethod, infos.bRoles, infos.bSecurityLevel, infos.bMaxTries, string.len(newKeys)) .. newKeys
    
    -- apre canale cifrato
    local authRes = self:verify_role_scp3(id, role, oldPin, true)
    if authRes ~=0 then
        return authRes
    end    
    local recv = self:sm_transmit(hexf('8024%B04%P', id, authData))
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        log.output('change_fips(): Error ' .. hexify(sw) )
        error(SmartcardError.new(sw, 'change Error' ), 2)
    end
    
    -- chiude canale cifrato
    authRes = self:verify_role_scp3(id, role, newPin, false)
    return authRes
end

function Smartcard.mt:reset_pin_fips(Puk, newPin)

    log.output('reset_pin_fips():', Puk, newPin)
    local infos = self:get_authentication_info(self.ID_PIN_FIPS)
    local SMACKey = md.pkcs5_pbkdf2(newPin, "000001", 32, 1000)
    local SENCKey = md.pkcs5_pbkdf2(newPin, "000002", 32, 1000)
    local newKeys = hex.hexf("870000%P", SMACKey) .. hex.hexf("870000%P", SENCKey)
    local authData = hexf("%B%B%B00%B%>%H", infos.bMethod, infos.bRoles, infos.bSecurityLevel, infos.bMaxTries, string.len(newKeys)) .. newKeys
    
    -- Verifica PUK
    local authRes = self:verify_role_scp3(self.ID_PUK_FIPS, 8, Puk)
    if authRes ~=0 then
        return authRes
    end
    self:reset_retry_counter(self.ID_PIN_FIPS)
    
    -- apre canale cifrato col PUK
    authRes = self:verify_role_scp3(self.ID_PUK_FIPS, 8, Puk, true)
    if authRes ~=0 then
        return authRes
    end
    
    local recv = self:sm_transmit(hexf('8024%B04%P', self.ID_PIN_FIPS, authData))
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        log.output('change_fips(): Error ' .. hexify(sw) )
        error(SmartcardError.new(sw, 'change Error' ), 2)
    end
    
    -- chiude canale cifrato
    authRes = self:verify_role_scp3(self.ID_PUK_FIPS, 8, Puk)
    return authRes
end


function Smartcard.mt:change(id, newPin)
    if id<0 or id>7 then
        error(SmartcardError.new(nil, 'Smartcard change Error: bad BSO number' ), 2)
    end
    local infos = self:get_authentication_info(id)
    local authData = hexf("%B%B%B00%B%>%H", infos.bMethod, infos.bRoles, infos.bSecurityLevel, infos.bMaxTries, string.len(newPin)) .. newPin
    local recv = self:transmit(hexf('8024%B04%P', id, authData))
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        log.output('change(): Error ' .. hexify(sw) )
        error(SmartcardError.new(sw, 'change Error' ), 2)
    end
    return 0, 'Authentication succeeded'
end


function Smartcard.mt:real_begin_transaction()
    self.card:begintransaction()
    self._in_transaction = true
    self._soft_transacted = false
    log.output("self.on_begin_transaction", self.on_begin_transaction)
    if self.on_begin_transaction then
        self:on_begin_transaction()
    end
end

function Smartcard.mt:real_end_transaction()
    if self.on_end_transaction then
        self:on_end_transaction()
    end
    self.card:endtransaction()
end

function Smartcard.mt:begin_transaction()
    if self._in_transaction then
        return
    end
    self._soft_transacted = true
end

function Smartcard.mt:end_transaction()
    if self._in_transaction then
        self:real_end_transaction()
    end
    self._soft_transacted = false
    self._in_transaction = false
end

function Smartcard.mt:reset_retry_counter(id)
    if id<0 or id>8 then
        error(SmartcardError.new(nil, 'Smartcard reset_retry_counter Error: bad BSO number' ), 2)
    end
    local sw = self:transmit(hexf('8024%B2000', id))
    if sw ~= hexf('9000') then
        log.output('reset_retry_counter(): Error ' .. hexify(sw) )
        error(SmartcardError.new(sw, 'reset_retry_counter Error' ), 2)
    end
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

function Smartcard.mt:read_public_key(group, index)
    local apdu = hexf("8048%B%B00", group, index)
    local modulus, exponent
    local recv = self:transmit(apdu)
    local sw = string.sub(recv, -2, -1)
    while sw == hexf("6301") do
        -- retrasmit same case#2 APDU until end of data
        local recv1 = self:transmit(apdu)
        sw = string.sub(recv1, -2, -1)
        recv = string.sub(recv, 1, -3) .. recv1
    end
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'read_public_key Error' ), 2)
    end
    local mode, nLen = bin.unpack("%B%>%H", string.sub(recv, 1, 3))
    modulus = string.sub(recv, 4, 4 + nLen -1)
    local eLen = bin.unpack("%>%H", string.sub(recv, 4+nLen, 5+nLen))
    exponent = string.sub(recv, 6 + nLen, 6 + nLen + eLen-1)
    while string.byte(exponent, 1) == 0 do
        exponent = string.sub(exponent, 2, -1)
    end
    return modulus, exponent
end

function Smartcard.mt:read_x509_certificate(path)
    local offset = 0
    log.output('read_x509_certificate():')
    local fInfo = self:select(path)
    
    log.output('read_x509_certificate(): using plain text')
    local der_size = self:read_binary(offset, 4)
    if string.sub(der_size, 1, 2) == hexf('5a82') then  -- Z\x82 + sizeBE + compressed data
        local size = string.byte(der_size, 3) * 256 + string.byte(der_size, 4)
        log.output('read_x509_certificate(): PT: using CPR mode: expected size:', size)
        local compr = self:mread_binary(offset+4, size)
        local decompr = zlib.decompress(compr, true, nil, nil)
        log.output('read_x509_certificate(): PT: cpr ratio:', 
                (4+string.len(compr))/string.len(decompr or "0"))
        return decompr
    else
        if string.sub(der_size, 1, 2) ~= hexf('3082') then
            error('Smartcard read_x509_certificate Error: bad certificate', 2)
        end
        local size = string.byte(der_size, 3) * 256 + string.byte(der_size, 4)
        return der_size .. self:mread_binary(offset+4, size)        
    end
end


function Smartcard.mt:rsa_dec(data, group, index)
    local sw
    local apdu, apdu1
    sw = self:transmit(hexf('8023%B%B020244', group, index))
    sw = string.sub(sw, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'initialize algorithm Error' ), 2)
    end

    if string.len(data) > 128 then
        apdu =  hexf('902A0000%P', string.sub(data,1, 127))
        apdu1 = hexf('802A0000%P', string.sub(data,128, -1))
    else
        apdu = hexf('802A0000%P', data)
    end
    local recv = self:transmit(apdu)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') and sw ~= hexf('6200') then
        error(SmartcardError.new(sw, 'rsa_dec error' ), 2)
    end
    if apdu1 then
        recv = self:transmit(apdu1)
        sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            error(SmartcardError.new(sw, 'rsa_dec error' ), 2)
        end
    end
    -- padding alla dimensione dell'input (che dovrebbe rispecchiare la dimensione del modulo)
    local res = string.sub(recv, 1, -3)
    res = string.rep('\0', string.len(data) - string.len(res)) .. res
    return res
end


local OIDs =  {
    {oid=hexf("3021300906052b0e03021a05000414"),         algo=128+48, len=20}, -- sha1
    {oid=hexf("302d300d06096086480165030402040500041c"), algo=128+49, len=28}, -- sha224
    {oid=hexf("3031300d060960864801650304020105000420"), algo=128+50, len=32}, -- sha256
    {oid=hexf("3041300d060960864801650304020205000430"), algo=128+51, len=48}, -- sha384
    {oid=hexf("3051300d060960864801650304020305000440"), algo=128+52, len=64}, -- sha512
}

function Smartcard.mt:rsa_sign(data, group, index)

    local hashAlgoID = 0
    log.output('rsa_sign(): detecting hash algo...')
    for i=1,table.getn(OIDs) do
        local oid = OIDs[i].oid
        if string.sub(data, 1, string.len(oid)) == oid then
            hashAlgoID = OIDs[i].algo
            data = string.sub(data, string.len(oid)+1, -1)
            break
        elseif string.len(data) == OIDs[i].len then
            hashAlgoID = OIDs[i].algo
            break
        end
    end
    
    local sw
    local apdu, apdu1
    sw = self:transmit(hexf('8023%B%B034017%B', group, index, hashAlgoID))
    sw = string.sub(sw, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'initialize algorithm Error' ), 2)
    end

    if string.len(data) > 128 then
        apdu =  hexf('902C0000%P', string.sub(data,1, 127))
        apdu1 = hexf('802C0000%P', string.sub(data,128, -1))
    else
        apdu = hexf('802C0000%P', data)
    end
    local recv = self:transmit(apdu)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') and sw ~= hexf('6200') then
        error(SmartcardError.new(sw, 'rsa_dec error' ), 2)
    end
    if apdu1 then
        recv = self:transmit(apdu1)
        sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            error(SmartcardError.new(sw, 'rsa_dec error' ), 2)
        end
    end
    -- padding alla dimensione dell'input (che dovrebbe rispecchiare la dimensione del modulo)
    local res = string.sub(recv, 1, -3)
    return res
end


function Smartcard.mt:create_file(owner, finfos)
    local sw
    local apdu
    
    local cfData = hexf("%>%L%B%B%B%B%B%>%H", finfos.size,
        finfos.bmReadList.asnumber, finfos.bmWriteCreate.asnumber, finfos.bmDelete.asnumber, finfos.bmExecute.asnumber,
        finfos.bmAttributes.asnumber, string.len(finfos.name)+1) .. finfos.name .. "\0"
    
    sw = self:transmit(hexf('80CF00%B%P', owner, cfData))
    sw = string.sub(sw, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'create_file Error' ), 2)
    end
    if type(finfos.fillchar) == "string" then
        self:select(finfos.name)
        self:mupdate_binary(0, string.rep(string.sub(finfos.fillchar,1,1), finfos.size))
    end
end


function Smartcard.mt:create_folder(owner, finfos)
    local sw
    local apdu
    
    local cfData = hexf("%B%B%B%B%B%>%H",
        finfos.bmReadList.asnumber, finfos.bmWriteCreate.asnumber, finfos.bmDelete.asnumber, finfos.bmExecute.asnumber,
        finfos.bmAttributes.asnumber, string.len(finfos.name)+1) .. finfos.name .. "\0"
        
    sw = self:transmit(hexf('80CD00%B%P', owner, cfData))
    sw = string.sub(sw, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'create_file Error' ), 2)
    end
end



function Smartcard.mt:delete_file(path)
    if pcall( function() self:select(path) end ) then
    
        local apdu = hexf("80DF000000")
        local recv = self:transmit(apdu)
        local sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            log.output('delete_file(): error:', hexify(sw))
            error(SmartcardError.new(sw, 'delete_file Error'), 2)
        end
    end
end

function Smartcard.mt:delete_folder(path)
    if pcall( function() self:select(path) end ) then
        local apdu = hexf("80DD010000")
        local recv = self:transmit(apdu)
        local sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            log.output('delete_file(): error:', hexify(sw))
            error(SmartcardError.new(sw, 'delete_folder Error'), 2)
        end
    end
end

function Smartcard.mt:delete_key(group, index)
    local apdu = hexf("8049%B%B00", group, index)
    local recv = self:transmit(apdu)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') and  sw ~= hexf('6a82') then
        log.output('delete_key(): error:', hexify(sw))
        error(SmartcardError.new(sw, 'delete_key Error'), 2)
    end
end

function Smartcard.mt:_poll_win32(group, index)
    local apdu = hexf("8048%B%B00", group, index)
    local recv
    log.output('_poll_win32(): sleep start at:', os.time())
    w32.sleep(13 * 1000)
    log.output('_poll_win32(): sleep stop at:', os.time())
    for i=1,5 do
        local status
        status, recv = pcall(function() return self:transmit(apdu) end)
        if status then 
            if recv ~= apdu then
                break
            end
        else 
            local errNo = string.sub(recv, -8, -1)
            if errNo ~= '000000aa' and errNo ~= '8010002f' and errNo ~= '80100016' and errNo ~= '80100017' then
                error(recv)
            end
        end
        if i == 5 then
            error('polling timeout')
        end
    end
    local sw = string.sub(recv, -2, -1)
    while sw == hexf("6301") do
        -- retrasmit same case#2 APDU until end of data
        recv = self:transmit(apdu)
        sw = string.sub(recv, -2, -1)
    end
    return sw
end


local SCARD_E_8010002f = "0x8010002f"
local SCARD_E_80100016 = "0x80100016"
local SCARD_E_80100017 = "0x80100017"
local SCARD_E_8010000f = "0x8010000f"

local function _readkey(card, group, index)
    local apdu = hexf("8048%B%B00", group, index)
    local data = ''
    local status, _recv, scarderr
    log.output(string.format('_readkey() ... '))
    for i=1,1000 do
        _recv, scarderr = card:transmit(apdu)
        if scarderr and scarderr ~= 0 then
            log.output(string.format('_readkey(): scard error: 0x%08X', scarderr))
            return scarderr
        end
        if _recv ~= apdu then
            status = string.sub(_recv, -2, -1)
            _recv =  string.sub(_recv, 1, -3)
            data = data ..  _recv
            if status ~= hex.hexf('6301') then
                log.output('_readkey(): return OK')
                return 0, status, data
            end
        end
    end
    log.output('_readkey(): return 0 (?!?)')
    return 0
end

local function _arripigliati(reader, group, index)
    log.output(string.format('_arripigliati() ... '))
    
    local status = hex.hexf("9000")
    for i=1,50 do
        local ctx, card, scarderr
        ctx, scarderr = pcsc.establishcontext()
        scarderr = scarderr or 0
        log.output(string.format('_arripigliati(): establishcontext(): 0x%08X', scarderr))
        if scarderr == 0 then
            card, scarderr = ctx:connect(reader, nil, pcsc.PROTOCOL_Tx)
            scarderr = scarderr or 0
            log.output(string.format('_arripigliati(): connect(): 0x%08X', scarderr))
        end
        if scarderr == 0 then
            scarderr = -1
            pcall( function()
                scarderr, status = _readkey(card, group, index) or 0
            end)
            StrScarderr = string.format("0x%08x", scarderr)
            log.output(string.format('_arripigliati(): _readkey(): %s', StrScarderr))
            if StrScarderr == "0x00000000" then
                log.output(string.format('_arripigliati(): finished'))
                break
            elseif StrScarderr == SCARD_E_8010002f or StrScarderr == SCARD_E_80100016 or StrScarderr == SCARD_E_80100017 
            or StrScarderr == SCARD_E_8010000f then
                
                log.output('_arripigliati(): sleep start at:', os.time())
                log.output(string.format('_arripigliati(): sleep for error %s', StrScarderr))
                w32.sleep(5 * 1000)
                log.output('_arripigliati(): sleep stop at:', os.time())
            else
                if StrScarderr == "0x00000000" then
                    log.output(string.format('_arripigliati(): finished'))
                    break
                end
                -- card:disconnect()
                ctx:release()
                log.output(string.format('_arripigliati(): unexpected error: %s', StrScarderr))
                error(string.format('_arripigliati(): unexpected error: %s', StrScarderr))
            end
        else
            w32.sleep(5 * 1000)
        end
        --if card then card:disconnect() end
        if ctx then ctx:release() end
    end
    return status
end


function Smartcard.mt:generate_key_pair(pubKeyInfos, privKeyInfos)
    local data = hexf("%B%B%B%B%B%B%B%B%B%B%B%B%B%B%>%H000400010001",
                    pubKeyInfos.bAlgoID,
                    pubKeyInfos.group, pubKeyInfos.index,
                    pubKeyInfos.bmReadList.asnumber, pubKeyInfos.bmWriteCreate.asnumber, pubKeyInfos.bmDelete.asnumber, pubKeyInfos.bmExecute.asnumber,
                    privKeyInfos.group, privKeyInfos.index,
                    privKeyInfos.bmReadList.asnumber, privKeyInfos.bmWriteCreate.asnumber, privKeyInfos.bmDelete.asnumber, privKeyInfos.bmExecute.asnumber,
                    pubKeyInfos.crt and 1 or 0,
                    pubKeyInfos.keybits / 8
                 )
    local cardstate, scarderr = self.card:status()
    log.output('############# generate_key_pair - UN FATTO QUALSIASI')
    apdu = hexf("80460000%P", data)
    local osname = p11wrap.osname()
    if osname ~= "windows" then
        self:end_transaction()
    end
    local status, recv = pcall( function() return self:transmit(apdu) end )
    if not status then
        log.output('############# transmit error - recv:', recv)
        local errNo = string.sub(recv, -8, -1)
        if errNo ~= '8010002f' and errNo ~= '80100016' and errNo ~= '80100017' then
            if osname ~= "windows" then
                self:begin_transaction()
            end
            error(recv)
        else
            if osname == "windows" then
                recv = self:_poll_win32(pubKeyInfos.group, pubKeyInfos.index)
            else
                 log.output('generate_key_pair(): long sleep start at:', os.time())
                 local seconds = 5
                 if pubKeyInfos.keybits < 2048 then seconds = 5 end
                 log.output('generate_key_pair(): sleep', seconds, 'for error', errNo)
                 w32.sleep(seconds * 1000)
                 log.output('generate_key_pair(): long sleep start at:', os.time())
                _arripigliati(cardstate.reader, pubKeyInfos.group, pubKeyInfos.index)
                recv = hex.hexf("9000")
            end
        end
    end
    if osname ~= "windows" then
        self:begin_transaction()
    end
    local sw = string.sub(recv, -2, -1)
    log.output('############# sw:', hexify(sw))
    if sw ~= hexf('9000') then
        log.output('generate_key_pair(): error:', hexify(sw))
        error(SmartcardError.new(sw, 'generate_key_pair Error'), 2)
    end
end


function Smartcard.mt:update_binary(offset, data)
    recv = self:transmit(hexf('80FC000004%>%L', offset))
    local sw = string.sub(recv, -2, -1)
    if sw == hexf('9000') or sw == hexf('9001') then
        local apdu = hex.hexf("80F10000%P", data)
        local recv
        recv =  self:transmit(apdu)
        sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            error(CnsSmartcardError.new(sw, 'update_binary Error'), 2)
        end
    end
end
function Smartcard.mt:mupdate_binary(offset, data)
    local buffer_size = Smartcard.MAX_TRANSMIT_BUFFER_SIZE
    local left = string.len(data)
    local curOffset = offset
    local chunk
    while left > 0 do
        chunk = string.sub(data, curOffset-offset+1, curOffset-offset + buffer_size)
        if chunk == 0 then
            log.output("mupdate_binary(): WARNING: specified data len is not enough?")
            break
        end
        self:update_binary(curOffset, chunk, sm_enc, sm_sig)
        left = left - string.len(chunk)
        curOffset = curOffset + string.len(chunk)
    end
end

local function UpdateCrc( ch, crc )
    local ch = (bin.flags(ch) ^ ( ( bin.flags(crc) ) * bin.flags("0x00FF" ) )).asnumber;
    local ch = ((bin.flags(ch) ^ bin.flags(ch*16)) * bin.flags("0x00FF" )).asnumber

    local cr1 = bin.flags( crc / 256 ) * bin.flags("0xffFF" )
    local cr2 = bin.flags( ch *256 ) * bin.flags("0xffFF" )
    local cr3 = bin.flags( ch *8 ) * bin.flags("0xffFF" )
    local cr4 = bin.flags( ch /16 ) * bin.flags("0xffFF" )
    crc = cr1 ^ cr2 ^ cr3 ^ cr4;
    return crc.asnumber
end

local function Crc16_CCITT_1189(data, start)
	crc=start;
    size=string.len(data)
    for i=1,size do
        crc = UpdateCrc(string.byte(data, i), crc);
    end
	return (bin.flags(crc) * bin.flags("0xffff")).asnumber
end


function Smartcard.mt:put_rsa_key(rsaInfos, pubGroup, pubIndex, privGroup, privIndex, to_sign)
    
    if rsaInfos.e then
        rsaInfos.e = string.rep("\0", math.mod(string.len(rsaInfos.e), 4)) .. rsaInfos.e
    end
    
    local abPubKey
    local abPrivKey
    local pubData
    local privData
    if pubGroup and pubIndex then
        if rsaInfos.n and rsaInfos.e then
            abPubKey = hexf("%B%>%H%S%H%S00",
                            to_sign and 2 or 3,
                            string.len(rsaInfos.n),
                            rsaInfos.n,
                            string.len(rsaInfos.e),
                            rsaInfos.e
                            )
            
            pubData = hexf("FFFFFFFF%>%H%S%H",
                            string.len(abPubKey),
                            abPubKey,
                            Crc16_CCITT_1189(abPubKey, 0)
                         )
        end
    end
    
    if privGroup and privIndex then
        
         
        if rsaInfos.p and rsaInfos.q and rsaInfos.dp and rsaInfos.dq and rsaInfos.ip then
            rsaInfos.p = string.rep("\0", math.mod(string.len(rsaInfos.p), 4)) .. rsaInfos.p
            rsaInfos.q = string.rep("\0", string.len(rsaInfos.p) - string.len(rsaInfos.q)) .. rsaInfos.q
            rsaInfos.dp = string.rep("\0", string.len(rsaInfos.p) - string.len(rsaInfos.dp)) .. rsaInfos.dp
            rsaInfos.dq = string.rep("\0", string.len(rsaInfos.p) - string.len(rsaInfos.dq)) .. rsaInfos.dq
            rsaInfos.ip = string.rep("\0", string.len(rsaInfos.p) - string.len(rsaInfos.ip)) .. rsaInfos.ip
            
            -- Q e P sono invertiti in questo hardware, dato che il coefficiente del resto cinese 