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
        log.output('token-cryptoid:add_ds_objects(): DS FS not found...')
        return
    end
    local lists = {[1] = self.ds_info.ds_publist, [2] = self.ds_info.ds_prilist}
    
    log.output('token-cryptoid:add_ds_objects(): adding DS objects...')
    
    for p=0,1 do
        log.output('token-cryptoid:add_ds_objects(): evaluating table:', p)
        local list = lists[p+1];
        local objects_path = self.ds_info.ds_path
        for i=1,table.getn(list) do
            local ffid = bin.flags(list[i].id_numeric)
            local oType = (ffid* util.objFIDS.eMASK)
            local oNum = (ffid * util.objFIDS.eNumMASK).asnumber
            if list[i].usage == 255 then
                log.output('token-cryptoid:add_ds_objects(): evaluating DS object:', i)
                objects.max_index = objects.max_index +1
                if oType == util.objFIDS.ePrivKey then
                    local infos = bin.flags(list[i].infos)
                    local obj = util.GetDSPrivKeyTemplate(t.mt.get_privkey_ds, i)
                    obj.private = (p==1)
                    obj.num = oNum
                    obj.slot = i
                    obj.ds_parent_path = objects_path   
                    obj.ds_id = hex.hexify(list[i].id)  -- fid DS KEY EF
                    obj.path = obj.ds_parent_path -- path in cui si trova il BSO
                    obj.key_bits = (infos * bin.flags("0x7FFF")).asnumber
                    obj.imported = infos[bin.flags("0x8000")]
                    
                    objects[ objects.max_index] = obj
                    log.output('token-cryptoid:add_ds_objects(): added private key:', 
                        'handle:', objects.max_index, 'path:', hex.hexify(obj.path))
                    log.output("token-cryptoid:add_ds_objects(): key_bits=", obj.key_bits, "imported=", obj.imported, "ds_id=", obj.ds_id)
                    
                elseif oType == util.objFIDS.ePubKey then
                    local obj = util.GetDSPubKeyTemplate(t.mt.get_pubkey_ds, i)
                    obj.private = (p==1)
                    obj.num = oNum
                    obj.slot = i
                    obj.ds_parent_path = objects_path
                    obj.ds_id = hex.hexify(list[i].id)  -- fid DS (fittizio per le chiavi pub)
                    obj.key_bits = list[i].infos
                    obj.path = obj.ds_parent_path .. list[i].id
                    objects[ objects.max_index] = obj
                    log.output('token-cryptoid:add_ds_objects(): added public key;', 
                        'handle:', objects.max_index, 'path:', hex.hexify(obj.path))
                        
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
                    log.output('token-cryptoid:add_ds_objects(): added certificate:', 
                        'handle:', objects.max_index, 'path:', hex.hexify(obj.path))
                
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
                    log.output('token-cryptoid:add_ds_objects(): added DATA object:', 
                        'handle:', objects.max_index, 'path:', hex.hexify(obj.path))
                else
                    log.output('token-cryptoid:add_ds_objects(): UNSUPPORTED object type found:', hex.hexify(list[i].id))
                end
            end
        
        end -- end ciclo su tabella oggetti
    end -- end ciclo su tabelle pub/priv
end


function t.mt:get_objects()

    log.output('token-cryptoid:get_objects()')
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

function t.mt:create_file(fid, size, is_public)
    local access = is_public and CryptoIDSmartCard.ROLE_EVERYONE or CryptoIDSmartCard.ROLE_USER0
    local finfos = {
        bStructure = 0, 
        readAC = access, 
        writeAC = access, 
        useAC = access,
        bSMFlag = 0, 
        name="",
        fid=fid,
        sfi = 0,
        size=size
    }
    self.cryptoid_hcard:select_df_path(self.ds_info.ds_path)
    local pcRes, theErrorT = pcall(function()
        self.cryptoid_hcard:delete_file(finfos.fid)
    end)
    if not pcRes then
        log.output('delete_file(): error:', theErrorT)
    end
    self.cryptoid_hcard:select_df_path(self.ds_info.ds_path)
    self.cryptoid_hcard:create_file(finfos)
end

function t.mt:write_file(offset, value)
    return self.cryptoid_hcard:mupdate_binary(offset, value)
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
    
    obj = util.GetDSPubKeyTemplate(t.mt.get_pubkey_ds)
    obj.private = false
    obj.ds_parent_path = self.ds_info.ds_path
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
    obj.num = freeId
    obj.slot = freeSlot
    
    local pcRes, theErrorT = pcall(function()
        -- crea gli attributi della chiave pubblica
        self.cryptoid_hcard:select_df_path(self.ds_info.ds_path)
        attr_file_size =string.len(attr)
        self:create_file( hexf("%>%H", fid_attr.asnumber), attr_file_size, true)
        self:write_file(0, attr)
    end)
    if not pcRes then
        log.output('create_object_pubkey(): error:', theErrorT)
        if self.cryptoid_hcard.last_sw == hexf("6A84") then
            log.output('create_object_pubkey(): no more memory available')
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
        objListPath = self.ds_info.ds_pub
        objList = self.ds_info.ds_publist
    else
        objListPath = self.ds_info.ds_priv
        objList = self.ds_info.ds_prilist
    end
    self.cryptoid_hcard:select_df_path(self.ds_info.ds_path)
    self.cryptoid_hcard:select_ef(objListPath)
    self.cryptoid_hcard:mupdate_binary(0, util.serialize_ds_objlist(objList))
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
    obj.ds_parent_path = self.ds_info.ds_path
    obj.key_bits = modulus_bits
    local freeSlots = util.look_for_free_slots(ds_prilist, 1, 1)
    log.output('create_object_privkey(): freeSlots:', repr(freeSlots))
    
    if table.getn(freeSlots) == 0 then
        log.output('create_object_privkey(): no more slots available')
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
    obj.imported = true
    
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
        attr_file_size =string.len(obj.eExponent)
        self:create_file( hexf("%>%H", fid_val.asnumber), attr_file_size, true)
        self:write_file(0, obj.eExponent)
        
        -- crea gli attributi della chiave privata
        attr_file_size =string.len(attr)
        self:create_file( hexf("%>%H", fid_attr.asnumber), attr_file_size, true)
        self:write_file(0, attr)
    end)
    if not pcRes then
        log.output('create_object_privkey(): error:', theErrorT)
        if self.cryptoid_hcard.last_sw == hexf("6A84") then
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
    obj.ds_parent_path = self.ds_info.ds_path
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
        self.cryptoid_hcard:select_df_path(self.ds_info.ds_path)
    
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
        if self.cryptoid_hcard.last_sw == hexf("6A84") then
            log.output('create_object_certificate(): no more memory available')
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
    local parsed_cer
    pcall(function()
        parsed_cer = der.parse_x509cer(pTemplate[CKA.VALUE])
    end)
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
    
    local modulus_bits
    local cka_modulus_bits = templatePub1[CKA.MODULUS_BITS] or templatePriv1[CKA.MODULUS_BITS] or eCK.ULONG(1024)
    if not cka_modulus_bits or cka_modulus_bits == eCK.ULONG(1024) then
        modulus_bits = 1024
    elseif cka_modulus_bits == eCK.ULONG(2048) then
        modulus_bits = 2048
    else
        log.output('generate_key_pair(): key size invalid:', hex.hexify(cka_modulus_bits) )
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
        
    local freeId, freeSlot
    local ds_prilist = self.ds_info.ds_prilist
    local attr
    local sm_enc, sm_sig
    objPriv = util.GetDSPrivKeyTemplate(t.mt.get_privkey_ds)
    objPriv.private = true
    objPriv.ds_parent_path = self.ds_info.ds_path
    objPriv.key_bits = modulus_bits
    
    local freeSlotsPub = util.look_for_free_slots(self.ds_info.ds_publist, 1, 1)
    local freeSlots = util.look_for_free_slots(ds_prilist, 1, 1)
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
    local pub_fid_val = util.objFIDS.ePubKeyP + bin.flags(freeId)
    fid_val = util.objFIDS.ePrivKey + bin.flags(freeId)
    fid_attr = fid_val + bin.flags('0x100')
    objPriv.ds_id = hex.hexify(hex.hexf("%H",  fid_val.asnumber) ) -- fid DS
    objPriv.path = objPriv.ds_parent_path -- path in cui si trova il BSO
    objPriv.num = freeId
    objPriv.slot = freeSlot
    
    self:verify_loggedon_user()
    log.output('GENERATING KEY PAIR:', objPriv.num)

    
    self:invalidate_xproc_cache()
    
    self.cryptoid_hcard:select_df_path(self.ds_info.ds_path)
    local pcRes, theErrorT = pcall(function()
        self.cryptoid_hcard:delete_file(objPriv.ds_id)
    end)
    if not pcRes then
        log.output('delete_file(): error:', theErrorT)
    end
    local pcRes, theErrorT = pcall(function()
        self.cryptoid_hcard:delete_file(pub_fid_val)
    end)
    if not pcRes then
        log.output('delete_file(): error:', theErrorT)
    end

    modulus, pubexp = self.cryptoid_hcard:generate_key_pair(pub_fid_val, objPriv.ds_id, modulus_bits)
    
    
    templatePub1[CKA.MODULUS] = modulus
    templatePub1[CKA.PUBLIC_EXPONENT] = pubexp
    templatePriv1[CKA.MODULUS] = modulus
    templatePriv1[CKA.PUBLIC_EXPONENT] = pubexp
    templatePriv1[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
    
    templatePub1[CKA.CLASS] = eCK.ULONG(CKO.PUBLIC_KEY)
    templatePub1[CKA.KEY_TYPE] = eCK.ULONG(CKK.RSA)
    attr = util.serialize_attr_privkey(templatePriv1)
    
    -- crea gli attributi della chiave privata
    local attr_file_len = string.len(attr)
    self:create_file( hexf("%>%H", fid_attr.asnumber), attr_file_len, true)
    self:write_file(0, attr)
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if templatePriv1[k] and not t._is_private_attribute(k) then
            objPriv[k] = templatePriv1[k]
        end
    end
    
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
        obj.ds_parent_path = self.ds_info.ds_path
        objectType = util.objFIDS.eDataP
        ds_objlist = self.ds_info.ds_prilist
    else
        obj.ds_parent_path = self.ds_info.ds_path
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
    
    self.cryptoid_hcard:select_df_path(self.ds_info.ds_path)
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
    local pub_fid_val = hexf('%H', (util.objFIDS.ePubKeyP + bin.flags(obj.num)).asnumber)
    local fid_attr = hexf('%H', (bin.flags( tonumber(obj.ds_id, 16)) + bin.flags('0x100')).asnumber )
    
    self.cryptoid_hcard:select_df_path(obj.ds_parent_path)
    log.output('destroy_object(): deleting DS attributes file:', obj.ds_parent_path .. hex.hexify(fid_attr))
    pcall(function()
            self.cryptoid_hcard:delete_file(fid_attr)
          end)
    log.output('destroy_object(): deleting DS value file:', obj.ds_parent_path .. hex.hexify(fid_val))
    pcall(function()
            self.cryptoid_hcard:delete_file(fid_val)
        end)
    
    log.output('destroy_object(): deleting pub_fid_val file:', obj.ds_parent_path .. hex.hexify(pub_fid_val))
    pcall(function()
            self.cryptoid_hcard:delete_file(pub_fid_val)
        end)
        
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
        local fInfo = self.cryptoid_hcard:select_df_path(self.ds_info.ds_path)
        fInfo = self.cryptoid_hcard:select_ef(self.ds_info.ds_infos)
                    
        local value = label .. string.rep(" ", 32 - string.len(label))
        log.output("cryptoid: set_label value:", hex.hexify(value))
        value = string.sub(value, 1, 32)
        self.cryptoid_hcard:mupdate_binary(0, value)
        self.info.label = value
        if self.ds_info and self.ds_info.token_info then 
            self.ds_info.token_info.label = value
        end
        log.output('set_label(): update HW Label', hex.hexify(value))
        local recv = self.cryptoid_hcard:transmit(hex.hexf("00DA0101%P", value))
        log.output('set_label(): update HW Label:', hex.hexify(recv or ''))
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
        log.output("token-cryptoid:flush_cache(): initializing _cache_id")
        changed, self._cache_id = utility.has_token_changed(self, "cache", 0)
        log.output("token-cryptoid:flush_cache(): initialize: _cache_id:", self._cache_id)
    end
    changed, cache_id = utility.has_token_changed(self, "cache", self._cache_id)
    if changed then
        log.output("token-cryptoid:flush_cache(): token has changed!")
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
    return self.cryptoid_hcard:valid()
end

return t

--===========================================================================
end
}
_LOADED['CryptoIDSmartCard'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
local hex = require 'hex'
local aes = require 'aes'
local ecdhlib = require "ecdhlib"
local h2i, hexf, hexify = hex.h2i, hex.hexf, hex.hexify
local rsa
local zlib = require 'zlib'
local util = require "utility"
local repr = util.repr

pcall(function() rsa = require("rsa"); end)

-- Smartcard

local Smartcard = {}

Smartcard.DEFAULT_KEY_EA= "12345678123456781234567812345678"
Smartcard.DEFAULT_KEY_MC= "12345678123456781234567812345678"

Smartcard.ID_KEY_MC = tonumber("01", 16)        -- ID oggetto KEY_MC (usare in AES external authenticate)
Smartcard.ID_KEY_EA = tonumber("03", 16)        -- ID oggetto KEY_EA (usare in AES external authenticate)

Smartcard.ID_PIN = tonumber("02", 16)        -- ID oggetto PIN USER (usare in verify pin)

Smartcard.ROLE_USER0 = tonumber("01", 16)    -- ROLE ID del PIN USER (usare in create file)
Smartcard.ID_PUK = tonumber("01", 16)        -- ID oggetto PIN SO (usare in verify pin)
Smartcard.ROLE_ADMIN0 = tonumber("10", 16)   -- ROLE ID del PIN SO (usare in create file)

Smartcard.ROLE_EVERYONE = tonumber("FF", 16)    -- ROLE ID "ALWAYS" (usare in create file)
Smartcard.ROLE_NEVER = tonumber("00", 16)       -- ROLE ID "NEVER"(usare in create file)

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
                    ID_PIN=Smartcard.ID_PIN,
                    ID_PUK=Smartcard.ID_PUK,
                    ID_KEY_MC=Smartcard.ID_KEY_MC,
                    ID_KEY_EA=Smartcard.ID_KEY_EA,
                    KEY_MC=Smartcard.DEFAULT_KEY_MC,
                    KEY_EA=Smartcard.DEFAULT_KEY_EA,
                  }
    self.card = card
    setmetatable(self, Smartcard.mt)
    return self
end


 
function Smartcard.mt:get_authentication_info(id)
    if id<1 or id>255 then
        error(SmartcardError.new(nil, 'Smartcard get_authentication_info Error: bad BSO number' ), 2)
    end
    local apdu = hexf("803200%B00", id)
    local recv = self:transmit(apdu)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'get_authentication_info Error'), 2)
    end
    local authraw = { bin.unpack('%>%L%B%B%B%B%B', recv) }
    local authInfo = { uAlgoID=authraw[1], bType=authraw[2], bLeftTryTimes=authraw[3], useAC=authraw[4], modifyAC=authraw[5], bUnblockSecretID=authraw[6],}
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
    self.last_sw = sw
    return result
end

function Smartcard.parse_fci(value)
    local info
    if string.byte(value, 1) == 0 then
        local infoR = {bin.unpack("%>%H%B%B", string.sub(value, 18, 21))}
        local name = string.sub(value, 2, 17)
        info = {
            filetype=string.byte(value, 1),
            fid=infoR[1],
            createAC=infoR[2],
            deleteAC=infoR[3],
            name = name,
        }
    else
        local infoR = {bin.unpack("%>%H%B%B%H%B", string.sub(value, 18, 24))}
        local name = string.sub(value, 2, 17)
        info = {
            filetype=string.byte(value, 1),
            name = name,
            fid=infoR[1],
            bModifyCNT=infoR[2],
            sfi=infoR[3],
            size=infoR[4],
            bStructure=infoR[5],
        }
        if info.bStructure == 0 then -- binary
            info.readAC = string.byte(value, 25)
            info.writeAC = string.byte(value, 26)
            info.bSMFlag = string.byte(value, 27)
        elseif info.bStructure == 16 then --  record
            info.bRecordNums = string.byte(value, 25)
            info.readAC = string.byte(value, 26)
            info.writeAC = string.byte(value, 27)
            info.bSMFlag = string.byte(value, 28)
        elseif info.bStructure == 32 or info.bStructure == 48 then --  pub/priv key
            info.ulAlgID, info.wPairedFileID, info.bDomain, info.bUsage, info.readAC,
            info.writeAC, info.useAC, info.bSMFlag 
                = bin.unpack("%>%L%H%B%B%B%B%B%B", string.sub(value, 25, -1))
        end
        
    end
    return info
end


function Smartcard.mt:get_info()
    local function remove_zeros(val)
        while string.len(val) >0 and string.sub(val, -1) == "\0" do
            val = string.sub(val, 1, -2)
        end
        return val
    end    
    local sw, recv
    local res = {}
    log.output('get_info()')
    local apdu = hexf('00ca010100') -- 0101: device base information
    recv = self:transmit(apdu)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'get data: device base information Error'), 2)
    end
    if string.len(recv) > 128 then
        res.bManu = remove_zeros(string.sub(recv, 1, 32))
        res.bIssuer = remove_zeros(string.sub(recv, 33, 64))
        res.bLabel = remove_zeros(string.sub(recv, 65, 96))
        res.bSerial = remove_zeros(string.sub(recv, 97, 128))
    end
    local apdu = hexf('00ca010200') -- 0102: device version information
    recv = self:transmit(apdu)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'get data: device base information Error'), 2)
    end
    if string.len(recv) > 4 then
        res.hwVersionMajor, res.hwVersionMinor, res.fwVersionMajor, res.fwVersionMinor = bin.unpack("%B%B%B%B", recv)
    end

    local apdu = hexf('00ca010300') -- 0103: device memory information
    recv = self:transmit(apdu)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'get data: device base information Error'), 2)
    end
    if string.len(recv) > 10 then
        res.ulTotalSpace, res.ulFreeSpace, res.wMaxApduDataLen = bin.unpack("%>%L%L%H", recv)
    end
    
    local apdu = hexf('00ca010A00') -- 010A: filesystem modify CNT
    recv = self:transmit(apdu)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'get data: device base information Error'), 2)
    end
    if string.len(recv) > 1 then
        res.fsModifyCNT = bin.unpack("%B", recv)
    end

    local apdu = hexf('8003000000')
    recv = self:transmit(apdu)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'get data: device base information Error'), 2)
    end
    if string.len(recv) > 8 then
        res.bChipSerial = string.sub(bignum.create(string.sub(recv, 1, 8), true):tostring(10, true), -16, -1)
        res.bChipSerialRaw = string.sub(recv, 1, -3)
         
        local sha2 = md.sha256()
        sha2:update(res.bChipSerialRaw .. res.bSerial)
        
        res.bChipSerial2 = string.sub(bignum.create(sha2:final(), true):tostring(10, true), -16, -1)
        log.output('get_info(): bChipSerial', res.bChipSerial)
        log.output('get_info(): bChipSerial2', res.bChipSerial2)
    end
    
    return res
end

function Smartcard.mt:select(path)
    local df = string.sub(path, 1, -3)
    local ef = string.sub(path, -2, -1)
    self:select_df_path(df)
    return self:select_ef(ef)
end

function Smartcard.mt:select_df_path(df_path)
    local sw, recv
    local template_p = '00A40800%P00'
    log.output('select_df_path(): ', hexify(df_path or ""))
    local apdu
    if df_path == nil then
        df_path = '3f00' -- ROOT
    end
    apdu = hexf(template_p, df_path)
    
    recv = self:transmit(apdu)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'select_df_path Error'), 2)
    end
    if string.len(recv) > 2 then
        return Smartcard.parse_fci(recv)
    end
end

function Smartcard.mt:select_ef(ef)
    local sw, recv
    local template_ef = '00A40200%P00'
    log.output('select_ef(): ', hexify(ef or "") )
    local apdu
    apdu = hexf(template_ef, ef)
    recv = self:transmit(apdu)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'select_ef Error'), 2)
    end
    if string.len(recv) > 2 then
        return Smartcard.parse_fci(recv)
    end
end

function Smartcard.mt:read_binary(offset, size)
    local recv
    recv = self:transmit(hexf('8044000002%>%H%B', offset, size))
    local sw = string.sub(recv, -2, -1)
    if sw == hexf('6b00') then
        return ""
    end
    return string.sub(recv, 1, -3)
end

function Smartcard.mt:mread_binary(offset, size)
    local buffer_size = Smartcard.MAX_TRANSMIT_BUFFER_SIZE
    local content = ''
    while size>0 do
        if size<buffer_size then buffer_size = size end
        local recv = self:read_binary(offset, buffer_size)
        if string.len(recv) == 0 then
            break
        end
        offset = offset  + string.len(recv)
        size = size - string.len(recv)
        content = content .. recv
    end
    return content
end


function Smartcard.mt:verify_pin(pin)
    return self:verify(self.ID_PIN, pin)
end

function Smartcard.mt:verify_puk(pin)
    return self:verify(self.ID_PUK, pin)
end

function Smartcard.mt:change_pin(pin, newPin)
    return self:change(self.ID_PIN, pin, newPin)
end

function Smartcard.mt:change_puk(pin, newPin)
    return self:change(self.ID_PUK, pin, newPin)
end

function Smartcard.mt:reset_pin(puk, newPin)
    return self:reset_retry_counter(self.ID_PIN, puk, newPin)
end

function Smartcard.mt:encrypt_apdu(data)
    local paddedData = aes.pkcs5_padding(16, data)
    log.output("padded data:", hex.hexify(paddedData))
    return sm.aes_enc_cbc(self.sm_enc, paddedData, nil, true) -- nota: non usa il padding AES CBC iso 9797
end

function Smartcard.mt:decrypt_response(recv)
    local encData = string.sub(recv, 1, -3-16)
    --log.output("encData:", hex.hexify(encData))
    local resp = aes.pkcs5_unpad(sm.aes_dec_cbc(self.sm_enc, encData, nil, true)) -- nota: ignora il padding AES CBC iso 9797
    return resp .. string.sub(recv, -2, -1)
    
end
function Smartcard.mt:sign_apdu(header, data)

    local newLC = string.char(string.len(data) + 16)
    local toMac = header .. newLC .. data
    local mac = aes.AES_CMAC(self.sm_mac, toMac, string.len(toMac))
    local apdu = header .. newLC .. data .. string.sub(mac, 1, 16)
    return apdu
end

function Smartcard.mt:enc_sign_apdu(apdu)
    --local encAPDU = apdu
    local recv
    local LE = ""
    local apdulen = string.byte(apdu, 5)
    local data = string.sub(apdu, 6, -1)
    local encData
    local header = string.sub(apdu, 1, 4)
    local encSignApdu
    log.output("apdulen:", apdulen)
    log.output("string.len(data):", string.len(data))
    
    if apdulen +1 == string.len(data) then
        LE = string.sub(data, -1, -1)
        log.output("enc_sign_apdu(): specified LE:", hex.hexify(LE))
        data = string.sub(data, 1, -2)
        --encAPDU = string.sub(apdu, 1, -2)
    end
    --encData = data
    
    log.output("enc_sign_apdu(): orig plain text apdu:", hex.hexify(apdu))

    local newCla = string.char((bin.flags(string.byte(apdu, 1)) + bin.flags("0x04")).asnumber)
    header = newCla .. string.sub(apdu, 2, 4)
    encData = self:encrypt_apdu(data)
    log.output("enc_sign_apdu(): PT Data:", hex.hexify(data or ""))
    log.output("enc_sign_apdu:() encData:", hex.hexify(encData or ""))
    --encAPDU = header .. string.char(string.len(encData)) .. encData

    encSignApdu  = self:sign_apdu(header, encData)
    log.output("enc_sign_apdu(): encSignApdu:", hex.hexify(encSignApdu or ""))
    return encSignApdu .. LE
end

function Smartcard.mt:sm_transmit(apdu)
    local encSignApdu = self:enc_sign_apdu(apdu)
    local recv = self:transmit(encSignApdu)
    if string.len(recv) >2 then
        recv = self:decrypt_response(recv)
    end
    return recv
end


local function SSKDF_SHA512_Derivation(Zi, OtherInfo, nKSize)
	local i, n, m
    local h = 512 / 8;
	local t, j
	local hash;
    local Ko = ""
	local sha512 = md.sha512()

	n = (nKSize + h - 1) / h;
    t = ""
    log.output("establish_sm(): Zi=", hex.hexify(Zi))
    log.output("establish_sm(): OtherInfo=", hex.hexify(OtherInfo))
    log.output("establish_sm(): nKSize=", nKSize)
	for i=1,n do
    
        for j=0,3 do
			t = string.char(i / (2^(j * 8))) .. t
		end
        log.output("establish_sm(): using t=", hex.hexify(t))
		sha512:update(t)
		sha512:update(Zi)
		sha512:update(OtherInfo)
		hash = sha512:final()

		m = (nKSize < h) and nKSize or h

		Ko = Ko .. string.sub(hash, 1, m)

		nKSize = nKSize - m
	end

	return Ko
end


function Smartcard.mt:establish_sm()
    self:aes_external_auth(self.ID_KEY_EA, self.KEY_EA)
    local apdu = hex.hexf("8011000005400010110000")
    
    local recv = self:transmit(apdu)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'establish_sm: get ECDH card key error' ), 2)
    end
    
    local publicKey = string.sub(recv, 5, -3)
    log.output('establish_sm(): card publicKey', hex.hexify(publicKey) )
    local cardPointBits = bin.unpack("%>%L", publicKey)
    log.output('establish_sm(): cardPointBits', cardPointBits )
    local cardPont = string.sub(publicKey, 5, -5)
    log.output('establish_sm(): cardPont', hex.hexify(cardPont) )
    
    
    local curve = ecdhlib.get_curve("secp521k")
    local cardPubKey = curve.g:decode_point(cardPont)
    
    local termPrivKey, termPubKey = curve.g:make_keypair(bignum.create("0x010001"))
    log.output('establish_sm(): termPrivKey', termPrivKey )
    log.output('establish_sm(): termPubKey', hex.hexify(termPubKey:encode_point(false, 66)) )
    
    local sharedSecretPoint = cardPubKey:scalar_mult(termPrivKey)
    local sharedSecret = sharedSecretPoint:encode_point(false, 66)
    sharedSecret = string.sub(sharedSecret, 1, 66)
    log.output('establish_sm(): sharedSecret', hex.hexify(sharedSecret) )
    
    local termPoint = termPubKey:encode_point(false, 68)
    local ulAlgID = hex.hexf("40001011")
    local ulHashAlgID = hex.hexf("40000015")
    local OtherInfo = hex.hexf("0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")
    local bitlen = hex.hexf("09020000")
    local rfu = hex.hexf("00000000")
    local apdu = hex.hexf("80110100%P00", ulAlgID .. ulHashAlgID .. OtherInfo .. bitlen .. termPoint .. rfu)
    
    log.output('establish_sm(): establish sm APDU', hex.hexify(apdu) )
    
    local recv = self:transmit(apdu)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'establish_sm: get send ECDH terminal key error' ), 2)
    end
    
    local smKeys = SSKDF_SHA512_Derivation(string.sub(sharedSecret, 1, 66), OtherInfo, 64);
    self.sm_mac = string.sub(smKeys, 1, 32)
    self.sm_enc = string.sub(smKeys, 33, 64)
    assert(string.len(self.sm_mac) == 32)
    assert(string.len(self.sm_enc) == 32)
    
    log.output('establish_sm(): self.sm_mac', hex.hexify(self.sm_mac) )
    log.output('establish_sm(): self.sm_enc', hex.hexify(self.sm_enc) )
    
end

function Smartcard.mt:aes_external_auth(id, key)
    log.output('verify():', id, pin )
    if id<1 or id>255 then
        error(SmartcardError.new(nil, 'Smartcard verify_role Error: bad number' ), 2)
    end
    
    local recv = self:transmit(hexf('0084000020'))
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'verify: get challenge' ), 2)
    end
    
    
    local challenge = string.sub(recv, 1, -3)
    log.output('verify(): challenge', hex.hexify(challenge) )
    local response = sm.aes_enc_block(key, string.sub(challenge, 1, 16)) .. sm.aes_enc_block(key, string.sub(challenge, 17, -1))
    
    local recv = self:transmit(hexf('008200%B%P', id, response))
    local sw = string.sub(recv, -2, -1)
    if sw == hexf('6983') then
        return 2, 'Authentication blocked'
    elseif string.sub(sw, 1, 1) == hex.hexf('63') then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        return 0, 'Authentication succeeded'
    else
        log.output('verify(): Error ' .. hexify(sw) )
        error(SmartcardError.new(sw, 'verify Error' ), 2)
    end
end

local function pad_pin(pin)
    if string.len(pin) < 6 then
        pin = pin .. string.rep("\255", 6 - string.len(pin))
        log.output('pad_pin(): short pin padded with 0xFF: ' .. hexify(pin) )
    end
    return pin
end

function Smartcard.mt:verify(id, pin)
    log.output('verify():', id, pin )
    if id<1 or id>255 then
        error(SmartcardError.new(nil, 'Smartcard verify_role Error: bad number' ), 2)
    end

    pin = pad_pin(pin)
    
    local sha2 = md.sha256()
    sha2:update(pin)
    local key = sha2:final()
    key = string.sub(key, 1, 16)
    
    local recv = self:transmit(hexf('0084000010'))
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'verify: get challenge' ), 2)
    end
    
    
    local challenge = string.sub(recv, 1, -3)
    log.output('verify(): challenge', hex.hexify(challenge) )
    local response = sm.aes_enc_block(key, challenge)
    
    local recv = self:transmit(hexf('002000%B%P', id, response))
    local sw = string.sub(recv, -2, -1)
    if sw == hexf('6983') then
        return 2, 'Authentication blocked'
    elseif string.sub(sw, 1, 1) == hex.hexf('63') then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        return 0, 'Authentication succeeded'
    else
        log.output('verify(): Error ' .. hexify(sw) )
        error(SmartcardError.new(sw, 'verify Error' ), 2)
    end
end


function Smartcard.mt:change(id, pin, newPin)
    log.output('change():', id, pin, newPin )
    if id<1 or id>255 then
        error(SmartcardError.new(nil, 'Smartcard verify_role Error: bad number' ), 2)
    end
    pin = pad_pin(pin)
    newPin = pad_pin(newPin)
    
    self:establish_sm()
    local sha2 = md.sha256()
    sha2:update(pin)
    local key = sha2:final()
    key = string.sub(key, 1, 16)
    
    local recv = self:transmit(hexf('0084000010'))
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'change: get challenge' ), 2)
    end
    
    
    local challenge = string.sub(recv, 1, -3)
    log.output('change(): challenge', hex.hexify(challenge) )
    local response = sm.aes_enc_block(key, challenge)
    
    
    local recv = self:sm_transmit(hexf('803300%B%P', id, response .. newPin))
    local sw = string.sub(recv, -2, -1)
    if sw == hexf('6983') then
        return 2, 'Authentication blocked'
    elseif string.sub(sw, 1, 1) == hex.hexf('63') then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        return 0, 'Authentication succeeded'
    else
        log.output('change(): Error ' .. hexify(sw) )
        error(SmartcardError.new(sw, 'change Error' ), 2)
    end
end


function Smartcard.mt:reset_retry_counter(id, puk, newPin)
    log.output('reset_retry_counter():', id, puk, newPin )
    if id<1 or id>255 then
        error(SmartcardError.new(nil, 'Smartcard reset_retry_counter Error: bad number' ), 2)
    end
    
    puk = pad_pin(puk)
    newPin = pad_pin(newPin)
    
    self:establish_sm()
    local sha2 = md.sha256()
    sha2:update(puk)
    local key = sha2:final()
    key = string.sub(key, 1, 16)
    
    local recv = self:transmit(hexf('0084000010'))
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'reset_retry_counter: get challenge' ), 2)
    end
    
    
    local challenge = string.sub(recv, 1, -3)
    log.output('reset_retry_counter(): challenge', hex.hexify(challenge) )
    local response = sm.aes_enc_block(key, challenge)
    
    local recv = self:sm_transmit(hexf('803400%B%P', id, response .. newPin))
    local sw = string.sub(recv, -2, -1)
    if sw == hexf('6983') then
        return 2, 'Authentication blocked'
    elseif string.sub(sw, 1, 1) == hex.hexf('63') then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        return 0, 'Authentication succeeded'
    else
        log.output('reset_retry_counter(): Error ' .. hexify(sw) )
        error(SmartcardError.new(sw, 'reset_retry_counter Error' ), 2)
    end
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


function Smartcard.mt:read_x509_certificate(path)
    local offset = 0
    log.output('read_x509_certificate():')
    self:select(path)
    
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


function Smartcard.mt:rsa_dec(data, fid)
    local apdu
    local datalen = string.len(data) + 2
    fid = self:get_fid(fid)
    
    if datalen > 255 then
        apdu = hex.hexf("8088000000%>%H%H", datalen, fid) .. data
    else
        apdu = hex.hexf("80880000%B%>%H", datalen, fid) .. data
    end
    
    local recv = self:transmit(apdu)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'rsa_dec Error' ), 2)
    end

    local res = string.sub(recv, 5, -3)
    return res
end


function Smartcard.mt:get_fid(fid)
    if type(fid) == "string" and string.len(fid) == 4 then
        fid = tonumber(fid, 16)
    elseif type(fid) == "string" and string.len(fid) == 2 then
        fid = bin.unpack("%>%H", fid)
    elseif type(fid) == "string" and string.len(fid) == 1 then
        fid = bin.unpack("%B", fid)
    elseif type(fid) == "userdata" then
        fid = fid.asnumber
    elseif type(fid) ~= "number" then
        fid = tonumber(fid)
    end
    return fid
end

function Smartcard.mt:create_file(finfos)
    local sw
    local apdu
    local name = string.sub(finfos.name or "", 1, 16)
    name = name .. string.rep("\0", 16 - string.len(name))
    local fid = self:get_fid(finfos.fid)
    local cfData = hexf("01%B%B%B%B%B%S%>%H%B%H", 
        finfos.bStructure or 0, 
        finfos.readAC or 255, 
        finfos.writeAC or 255, 
        finfos.useAC or 255,
        finfos.bSMFlag or 0, 
        name,
        fid,
        finfos.sfi or 0,
        finfos.size)
    
    sw = self:transmit(hexf('80420000%P', cfData))
    sw = string.sub(sw, -2, -1)
    if sw ~= hexf('9000') then
        error(SmartcardError.new(sw, 'create_file Error' ), 2)
    end
    if type(finfos.fillchar) == "string" then
        self:select(finfos.name)
        self:mupdate_binary(0, string.rep(string.sub(finfos.fillchar,1,1), finfos.size))
    end
end


function Smartcard.mt:delete_file(fid)
    local fid = self:get_fid(fid)
    
    local apdu = hexf("8043020002%H", fid)
    local recv = self:transmit(apdu)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        log.output('delete_file(): error:', hexify(sw))
        error(SmartcardError.new(sw, 'delete_file Error'), 2)
    end

end


function Smartcard.mt:generate_key_pair(fidPub, fidPriv, bits)
    local fidPub = self:get_fid(fidPub)
    local fidPriv = self:get_fid(fidPriv)
    local pubKeyInfos = {
        bStructure = 32, -- pubkey
        readAC = Smartcard.ROLE_EVERYONE, 
        writeAC = Smartcard.ROLE_EVERYONE, 
        useAC = Smartcard.ROLE_EVERYONE,
        bSMFlag = 0, 
        name=string.format("PUB%04X", fidPub),
        fid=fidPub,
        sfi = 0,
        size=0
    }
    local privKeyInfos = {
        bStructure = 48, -- privkey
        readAC = Smartcard.ROLE_EVERYONE,
        writeAC = Smartcard.ROLE_EVERYONE,
        useAC = Smartcard.ROLE_USER0,
        bSMFlag = 0,
        name=string.format("PRIV%04X", fidPriv),
        fid=fidPriv,
        sfi = 0,
        size=0
    }
    
    local algo = tonumber("40001000", 16)
    if bits > 1024 then
        algo = algo+1
    end

    local pcRes, theErrorT = pcall(function()
        self:delete_file(pubKeyInfos.fid)
    end)
    
    local pcRes, theErrorT = pcall(function()
        self:delete_file(privKeyInfos.fid)
    end)

    
    local mode = 3 -- digtal signature and decrypt
    

    
    local apdu = hex.hexf("808100000A%>%H%H%L00%B", fidPub, fidPriv, algo, mode)

    self:create_file(pubKeyInfos)
    self:create_file(privKeyInfos)
    
    local recv = self:transmit(apdu)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        log.output('generate_key_pair(): error:', hexify(sw))
        error(SmartcardError.new(sw, 'generate_key_pair Error'), 2)
    end
       
    return self:read_public_key(fidPub)
    
end

function Smartcard.mt:read_public_key(fid)
    fid = self:get_fid(fid)
    local apdu = hex.hexf("8084010002%>%H", fid)
    local recv = self:transmit(apdu)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        log.output('read_public_key(): error:', hexify(sw))
        error(SmartcardError.new(sw, 'read_public_key Error'), 2)
    end
    
    local pubKey = string.sub(recv, 7, -3)
    local bitlen = bin.unpack("%>%L", pubKey)
    log.output('read_public_key(): pubKey:', hexify(pubKey))
    log.output('read_public_key(): bitlen:', bitlen)
    local modulus = string.sub(pubKey, 5+256 - (bitlen/8), 256+4)
    local exponent = string.sub(pubKey, 5+256, -1)
    log.output('read_public_key(): modulus:', hexify(modulus))
    log.output('read_public_key(): exponent:', hexify(exponent))
    
    return modulus, exponent
    
end

function Smartcard.mt:update_binary(offset, data, isFinal)
    -- isFinal non 