 oggetti ritorna 0
function t.mt:get_item(search_state, showprivate, template)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    if search_state.lastobj==nil then 
        search_state.lastobj=self.attributes.min_index 
    end
    if template[CKA.CLASS] == eCK.ULONG(CKO_PIN_POLICY) then
    
        log.output('get_item(): SPECIAL SEARCH: PIN POLICY, lastobj, min_index, max_index:', search_state.lastobj,
            self.attributes.min_index, self.attributes.max_index)
    
        if search_state.lastobj ~= self.attributes.min_index then
            log.output('get_item(): SPECIAL SEARCH: PIN POLICY: end of search')
            return 0
        end
        
        log.output('get_item(): SPECIAL SEARCH: PIN POLICY: populating data')
        search_state.lastobj = math.max(self.attributes.min_index, self.attributes.max_index)+1
        self:init_pin_policy()
        obj = {[CKA.CLASS]=eCK.ULONG(CKO_PIN_POLICY), [CKA.TOKEN]=eCK.BBOOL(true), [CKA.VALUE]=self.pin_policy_value}
        self.attributes[1] = obj
        return 1 -- special handle value
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
    -- contolla prima tutti gli attributi statici
    local static_attributes = {CKA.CLASS, CKA.TOKEN }
    for i, attr_type in static_attributes do
        if template[attr_type] then
            local rv, real_value = self:get_attribute_value(hobj, attr_type)
            if rv~=CKR.OK or real_value ~= template[attr_type] then
                -- log.output('>>>not match')
                -- log.output('>>>false')
                return false
            end
        end
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
        --log.output('>>>template: ', hex.tohex8(attr_type),
        --           repr(value), repr(real_value), rv)
        if rv~=CKR.OK or real_value ~=value then
            -- log.output('>>>not match')
            -- log.output('>>>false')
            return false
        else
            -- log.output('>>>match')
        end
    end
    -- log.output('>>>true')
    return true
end


function t.mt:add_ds_objects(objects)
    -- oggetti DS; l'applicazione puo' non esistere;  gli oggetti possono non essere presenti
    local info = self:get_info() -- carica le info sul filesystem in cache
    local p, i
    if (self.ds_info == nil or self.ds_info.ds_publist == nil or self.ds_info.ds_prilist == nil) then
        log.output('token-cns-oberthur:add_ds_objects(): DS FS not found...')
        return
    end
    local lists = {[1] = self.ds_info.ds_publist, [2] = self.ds_info.ds_prilist}
    
    log.output('token-cns-oberthur:add_ds_objects(): adding DS objects...')
    
    for p=0,1 do
        log.output('token-cns-oberthur:add_ds_objects(): evaluating table:', p)
        local list = lists[p+1];
        local objects_path = self.ds_info.path_root .. self.ds_df_pub
        local ecc_objects_path = self.ds_info.path_root .. self.ds_df_ecc
        if p==1 then objects_path = self.ds_info.path_root .. self.ds_df_priv end
        for i=1,table.getn(list) do
            local ffid = bin.flags(list[i].id_numeric)
            local oType = (ffid* oberthur_util.objFIDS.eMASK)
            local oNum = (ffid * oberthur_util.objFIDS.eNumMASK).asnumber
            if list[i].usage == IDEMIA_USAGE_USED or list[i].usage == IDEMIA_USAGE_USED2 then
                log.output('token-cns-oberthur:add_ds_objects(): evaluating DS object:', i, "oType=", oType, "oNum=", oNum, "ffid=", ffid)
                objects.max_index = objects.max_index +1
                if oType == oberthur_util.objFIDS.ePrivKey then
                    local obj = objOberthurTmpl.GetDSPrivKeyTemplate(t.mt.get_privkey_ds, i)
                    obj.private = (p==1)
                    obj.num = oNum
                    obj.slot = i
                    obj.ds_parent_path = objects_path   
                    obj.ds_id = hex.hexify(list[i].id)  -- fid DS (fittizio per le chiavi priv)
                    if oNum == 1 then
                        obj.pso_dec = true
                        obj.path = '3F00'
                        obj.kid = 1
                        obj.key_bits = 1024
                    else                    
                        obj.pso_dec = false
                        if oNum >= 12 then obj.pso_dec = true end
                        obj.path = obj.ds_parent_path -- path in cui si trova il BSO
                        obj.kid = obj.num
                        obj.key_bits = list[i].infos
                    end
                    obj.pso_dec_sm = list[i].usage == IDEMIA_USAGE_USED2
                    
                    objects[ objects.max_index] = obj
                    log.output('token-cns-oberthur:add_ds_objects(): added private key:', 
                        'handle:', objects.max_index, 'path:', obj.path,
                        'CKA_CLASS:', hex.hexify(objects[ objects.max_index ][CKA.CLASS]))
                elseif oType == oberthur_util.objFIDS.eAESKey then
                    local obj = GetSecretKeyTemplate(t.mt.get_secret_key_ds)
                    obj.private = (p==1)
                    obj.num = oNum
                    obj.slot = i
                    obj.ds_parent_path = objects_path   
                    obj.ds_id = hex.hexify(list[i].id)  -- fid DS (fittizio per le chiavi secret)
                    obj.path = obj.ds_parent_path -- path in cui si trova il BSO
                    obj.kid = obj.num
                    obj.key_bits = list[i].infos

                    objects[ objects.max_index] = obj
                    log.output('token-cns-oberthur:add_ds_objects(): added AES secret key:', 
                        'handle:', objects.max_index, 'path:', obj.path,
                        'CKA_CLASS:', hex.hexify(objects[ objects.max_index ][CKA.CLASS]))
                        
                        
                elseif oType == oberthur_util.objFIDS.ePubKey then
                    local obj = objOberthurTmpl.GetDSPubKeyTemplate(t.mt.get_pubkey_ds, i)
                    obj.private = (p==1)
                    obj.num = oNum
                    obj.slot = i
                    obj.ds_parent_path = objects_path
                    obj.ds_id = hex.hexify(list[i].id)  -- fid DS (file TLV della chiave pubblica)
                    if oNum == 1 then
                        obj.key_bits = 1024
                        obj.path = '3F003F01'       -- path reale del file TLV
                    else
                        obj.key_bits = list[i].infos
                        obj.path = obj.ds_parent_path .. obj.ds_id -- path reale del file TLV
                    end
                    objects[ objects.max_index] = obj
                    log.output('token-cns-oberthur:add_ds_objects(): added public key;', 
                        'handle:', objects.max_index, 'path:', obj.path,
                        'CKA_CLASS:', hex.hexify(objects[ objects.max_index ][CKA.CLASS]))
                        
                elseif oType == oberthur_util.objFIDS.eCert then
                    local obj = objOberthurTmpl.GetDSCertTemplate(t.mt.get_certificate_ds, i)
                    obj.private = (p==1)
                    obj.num = oNum
                    obj.slot = i
                    obj.ds_parent_path = objects_path
                    obj.ds_id = hex.hexify(list[i].id)  -- fid DS (file binario del certificato)
                    if oNum == 1 then
                        obj.size = 2048
                        obj.path = '3f0011001101'   --path reale del file del certificato
                    else
                        obj.size = list[i].infos
                        obj.path = obj.ds_parent_path .. obj.ds_id --path reale del file del certificato
                    end
                    objects[ objects.max_index] = obj
                    log.output('token-cns-oberthur:add_ds_objects(): added certificate:', 
                        'handle:', objects.max_index, 'path:', obj.path,
                        'CKA_CLASS:', hex.hexify(objects[ objects.max_index ][CKA.CLASS]))
                
                elseif oType == oberthur_util.objFIDS.eData or oType == oberthur_util.objFIDS.eDataP then 
                    local obj = objOberthurTmpl.GetDSDataTemplate(t.mt.get_data_ds, i)
                    obj.private = (p==1)
                    obj.num = oNum
                    obj.slot = i
                    obj.ds_parent_path = objects_path
                    obj.ds_id = hex.hexify(list[i].id)
                    if oNum == 1 then
                        obj.size = 400
                        obj.path = '3f0011001102'     --path reale del file dei dati
                    else
                        obj.size = list[i].infos
                        obj.path = obj.ds_parent_path .. obj.ds_id --path reale del file dei dati
                    end
                    objects[ objects.max_index] = obj
                    log.output('token-cns-oberthur:add_ds_objects(): added DATA object:', 
                        'handle:', objects.max_index, 'path:', obj.path,
                        'CKA_CLASS:', hex.hexify(objects[ objects.max_index ][CKA.CLASS]))
                        
                else
                
                    if self._ecc_license_valid and ( self.mechanisms[CKM.EC_KEY_PAIR_GEN] or self.mechanisms[CKM.EC_EDWARDS_KEY_PAIR_GEN]) then
                    
                        if oType == oberthur_util.objFIDS.ePrivECC or 
                                oType == oberthur_util.objFIDS.ePrivEdDSA then
                            
                            local cka_key_type = (oType == oberthur_util.objFIDS.ePrivECC) and CKK.ECDSA or CKK.EC_EDWARDS
                            
                            local obj = objOberthurTmpl.GetECCPrivKeyTemplate(t.mt.get_ecc_privkey_ds, cka_key_type)
                            obj.private = (p==1)
                            obj.num = oNum
                            obj.slot = i
                            obj.ds_parent_path = ecc_objects_path 
                            obj.ds_id = hex.hexify(list[i].id)  -- fid DS (fittizio per le chiavi priv ECC)

                            obj.path = obj.ds_parent_path -- path in cui si trova il BSO
                            obj.kid = obj.num
                            local infos_f = bin.flags(list[i].infos)
                            if infos_f[ECC_QUALIFIED_KEYBITS_FLAG] then
                                obj.ds_parent_path = objects_path
                                obj.path = obj.ds_parent_path
                                obj.key_bits = list[i].infos - ECC_QUALIFIED_KEYBITS_FLAG.asnumber
                                obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(true)
                            else
                                obj.key_bits = list[i].infos
                                obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
                            end
                            obj.ecc = true
                            obj.sk = t.mt.get_ecc_privkey_ds
                            
                            objects[ objects.max_index] = obj
                            log.output('token-cns-oberthur:add_ds_objects(): added pECC rivate key:', 
                                'handle:', objects.max_index, 'path:', obj.path,
                                'CKA_CLASS:', hex.hexify(objects[ objects.max_index ][CKA.CLASS]))
                            
                        elseif oType == oberthur_util.objFIDS.ePubECC or 
                                 oType == oberthur_util.objFIDS.ePubEdDSA then
                        
                            local cka_key_type = (oType == oberthur_util.objFIDS.ePubECC) and CKK.ECDSA or CKK.EC_EDWARDS
                        
                            local obj = objOberthurTmpl.GetECCPubKeyTemplate(t.mt.get_ecc_pubkey_ds, cka_key_type)
                            obj.private = (p==1)
                            obj.num = oNum
                            obj.slot = i
                            obj.ds_parent_path = objects_path
                            obj.ds_id = hex.hexify(list[i].id)  -- fid DS (file TLV della chiave pubblica)
          
                            obj.key_bits = list[i].infos
                            obj.path = obj.ds_parent_path .. obj.ds_id -- path reale del file TLV
                            obj.ecc = true
                            
                            objects[ objects.max_index] = obj
                            log.output('token-cns-oberthur:add_ds_objects(): added ECC public key;', 
                                'handle:', objects.max_index, 'path:', obj.path,
                                'CKA_CLASS:', hex.hexify(objects[ objects.max_index ][CKA.CLASS]))
                        else
                            log.output('token-cns-oberthur:add_ds_objects(ECC): UNSUPPORTED object type found:', hex.hexify(list[i].id))
                        end
                        
                    else
                        log.output('token-cns-oberthur:add_ds_objects(NO ECC): UNSUPPORTED object type found:', hex.hexify(list[i].id))
                    
                    end
                end
            end
        
        end -- end ciclo su tabella oggetti
    end -- end ciclo su tabelle pub/priv
end


function t.mt:get_objects()

    log.output('token-cns-oberthur:get_objects()')
    local info = self:get_info() -- carica le info sul filesystem in cache
    
    local objects = {
            min_index = 11001, -- primo indice disponibile
            max_index = 11000, -- valore dell'indice massimo (i valori intermedi possono anche essere nil)
        }

    self:add_ds_objects(objects)
    -- self:update_free_mem(self.info)
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

function t.mt:is_cns(pTemplate)
    return pTemplate[CKA.CLASS] ~= eCK.ULONG(CKO.DATA) 
            and (pTemplate[CKA.ID] == 'CNS0' or pTemplate[CKA.LABEL] == 'CNS0')
end

function t.mt:is_pdata(pTemplate)
    return pTemplate[CKA.CLASS] == eCK.ULONG(CKO.DATA) and pTemplate[CKA.LABEL] == 'PDATA'
end


function t.mt:is_ds(pTemplate)
    return (not self.ds_info._ignore_ds_pin and not self.ds_info._ignore_ds_opt) and ( string.sub(pTemplate[CKA.ID] or '', 1, 2) == "DS"
        or string.sub(pTemplate[CKA.LABEL] or '', 1, 2) == "DS"
        or string.sub(pTemplate[CKA.ID] or '', 1, 5) == "Firma"
        or string.sub(pTemplate[CKA.LABEL] or '', 1, 5) == "Firma")
end


function t.mt:is_dsx(pTemplate)
    
    local isdsx = string.sub(pTemplate[CKA.ID] or '', 1, 3) == "DX#" 
        or string.sub(pTemplate[CKA.LABEL] or '', 1, 3) == "DX#"
    return isdsx
    
end

function t.mt:is_dsx_licensed()
    return self._license_valid and type(self._license_valid.dsx) == "number" and self._license_valid.dsx > 0
end

function t.mt:create_file(finfo, is_public, delete)
    local finfo1 = utility.clone_table(finfo)
    if delete == nil then delete = true end
    if not finfo1.aac then finfo1.aac = {} end
    if not finfo1.aac.read then 
        finfo1.aac.read=0
        if not is_public then finfo1.aac.read = self.cns_hcard.BSO_CNS_PIN end
    end
    if not finfo1.aac.update then finfo1.aac.update=self.cns_hcard.BSO_CNS_PIN end
    if not finfo1.aac.append then finfo1.aac.append=self.cns_hcard.BSO_CNS_PIN end
    if not finfo1.aac.delete then finfo1.aac.delete=self.cns_hcard.BSO_CNS_PIN end
    if not is_public and self.ds_info.sm_create then
        self.cns_hcard:create_file(finfo1, delete, self.ds_info.sm_admin_enc, self.ds_info.sm_admin_sig)
    else
        self.cns_hcard:create_file(finfo1, delete)
    end
end

function t.mt:update_append_record(path, num, val)
    -- checks if a record already exists and if so uses update instead of append
    self.cns_hcard:select(hex.hexf(path) )
    local rec
    local res, theErrorT = pcall(function()
        rec = self.cns_hcard:read_record(num, 4, 3)
    end
    )
    if res and rec then
        self.cns_hcard:update_record(num, 4, val)
    else
        self.cns_hcard:append_record(val)
    end
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

function t.mt:create_object_pubkey(pTemplateOrig, as_local)
    log.output('create_object_pubkey()', pTemplateOrig, as_local)
    
    local pTemplate = utility.clone_table(pTemplateOrig)
    
    if self.userType ~= CKU.USER then
        log.output('create_object_pubkey(): USER_NOT_LOGGED_IN')
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
    local iscns = self:is_cns(pTemplate)
    local is_ds = self:is_ds(pTemplate)
    
    local modulus_bits = string.len(pTemplate[CKA.MODULUS]) * 8
    if iscns and modulus_bits ~= 1024 then
        log.output('create_object_pubkey(): MODULUS size not 1024!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    if modulus_bits ~= 1024 and modulus_bits ~= 2048 then
        log.output('create_object_pubkey(): MODULUS size not 1024 or 2048!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    pTemplate[CKA.LOCAL] = eCK.BBOOL(as_local)

    local freeId, freeSlot
    local ds_publist = self.ds_info.ds_publist
    local attr = oberthur_util.serialize_attr_pubkey(pTemplate)
    local fid_val, fid_attr
    
    obj = objOberthurTmpl.GetDSPubKeyTemplate(t.mt.get_pubkey_ds)
    obj.private = false
    obj.ds_parent_path = self.ds_info.path_root .. self.ds_df_pub
    obj.key_bits = modulus_bits
    if iscns then
        if 0 ~= ds_publist[2].usage then
            log.output('create_object_pubkey(): CNS Public Key already exists')
            return CKR.DEVICE_MEMORY
        end
        freeId, freeSlot = 1, 2 -- todo: free slot dovrebbe essere cercato da 1 a 3
        obj.ds_id = '1001'     -- fid degli attributi P11
        obj.path = '3F003F01'  -- path reale del file TLV della chiave pubblica
        fid_attr = bin.flags('0x1101')
    else
        -- cerca a partire da id 2 e slot 4
        freeId = oberthur_util.look_for_free_id(oberthur_util.objFIDS.ePubKey, ds_publist, 2, 1)
        local freeSlots = oberthur_util.look_for_free_slots(ds_publist, 1, 4)
        
        if freeId == nil or table.getn(freeSlots) == 0 then
            return CKR.DEVICE_MEMORY
        end
        freeSlot = freeSlots[1]
        fid_val = oberthur_util.objFIDS.ePubKey + bin.flags(freeId)
        fid_attr = fid_val + bin.flags('0x100')
        obj.ds_id = string.format('%04X', fid_val.asnumber )  -- fid oggetto DS
        obj.path = obj.ds_parent_path .. string.format('%04X', fid_val.asnumber ) -- path reale del file TLV della chiave pubblica
    end
    obj.num = freeId
    obj.slot = freeSlot
    
    -- if not iscns then
        -- local asm
        -- if is_ds and self.ds_info.sm_use_enc and self.ds_info.sm_use_sig then 
            -- asm = {read_out_enc=self.ds_info.sm_use_enc_id, read_out_sig=self.ds_info.sm_use_sig_id}
        -- end
        -- crea il file TLV o binario per gli oggetti non CNS
        -- local filetype = CnsSmartcard.fileTypes.RecordTLV
        -- local pad_size = 10
        -- if obj.key_bits == 2048 then
            -- filetype = CnsSmartcard.fileTypes.Binary
            -- asm = nil
            -- pad_size= 8 - string.len(pTemplate[CKA.PUBLIC_EXPONENT])
            -- if pad_size < 0 then pad_size=0; end
        -- end
        -- self:create_file( { size=string.len(pTemplate[CKA.MODULUS]) + string.len(pTemplate[CKA.PUBLIC_EXPONENT]) + pad_size,
                            -- filetype=filetype,
                            -- parent=hexf(obj.ds_parent_path),
                            -- fid=fid_val.asnumber, 
                            -- asm=asm,
                            -- }, true )
    -- end
    -- aggiorna o aggiunge i record TLV
    -- local pubExpLen = string.len(pTemplate[CKA.PUBLIC_EXPONENT])
    -- local modulusLen = string.len(pTemplate[CKA.MODULUS])
    
    -- if obj.key_bits == 2048 then
        -- local rv, modulus = self:_pad_bignum(pTemplate[CKA.MODULUS], 256)
        -- local rv, pubExp = self:_pad_bignum( pTemplate[CKA.PUBLIC_EXPONENT], 8)
        -- self.cns_hcard:select(hex.hexf(obj.path))
        -- self.cns_hcard:mupdate_binary(0, modulus)
        -- self.cns_hcard:mupdate_binary(256, pubExp)
    -- else
        -- self:update_append_record(obj.path, 1, 
                                  -- hex.hexf('10%B%B00', modulusLen+2, modulusLen+1) .. pTemplate[CKA.MODULUS] )
        -- self:update_append_record(obj.path, 2,
                                  -- hex.hexf('11%B%B00', pubExpLen+2, pubExpLen+1) .. pTemplate[CKA.PUBLIC_EXPONENT])
    -- end
    if iscns and not as_local then
        local pubExpLen = string.len(pTemplate[CKA.PUBLIC_EXPONENT])
        local modulusLen = string.len(pTemplate[CKA.MODULUS])
        self:update_append_record(obj.path, 1, 
                                  hex.hexf('10%B%B00', modulusLen+2, modulusLen+1) .. pTemplate[CKA.MODULUS] )
        self:update_append_record(obj.path, 2,
                                  hex.hexf('11%B%B00', pubExpLen+2, pubExpLen+1) .. pTemplate[CKA.PUBLIC_EXPONENT])
    end
    
    -- crea gli attributi della chiave pubblica
    self:create_file( {
                    size=string.len(attr), 
                    filetype=CnsSmartcard.fileTypes.Binary,
                    parent=hexf(obj.ds_parent_path),
                    fid=fid_attr.asnumber, }, true)
    self.cns_hcard:mupdate_binary(0, attr)
    
    -- update objects list
    ds_publist[freeSlot].usage = IDEMIA_USAGE_USED
    ds_publist[freeSlot].id = hexf(obj.ds_id)
    ds_publist[freeSlot].id_numeric = tonumber(obj.ds_id, 16)
    ds_publist[freeSlot].infos = obj.key_bits
    
    self:write_objlist(true) -- write public list
    
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    return CKR.OK, self.attributes.max_index
end

function t.mt:parse_ec_parameters_get_dp(ecParams, check_supported)
    log.output('parse_ec_parameters_get_dp(): ecParams:', hex.hexify(ecParams or ""), "check_supported:", check_supported)
    local asciiOid, dp
    local pcRes, theErrorT pcall(function()
        local oid = der.parse(ecParams)
        if oid[1] and oid[1].value and oid[1].tag == der.OID then
            asciiOid = der.decodeOID(oid[1].value)
            log.output('parse_ec_parameters_get_dp(): decoded asciiOid:', asciiOid)
            dp = asciiOid and self.cns_hcard.get_domain_parameter_by_ascii_oid_oberthur(asciiOid)
        else
            log.output('parse_ec_parameters_get_dp(): ecParams format invalid?')
        end
        
        if dp and check_supported and self.ds_info.supported_ecc_dp_oids then
            log.output('parse_ec_parameters_get_dp(): checking if selected DP is supported by card...')
            dp = self.ds_info.supported_ecc_dp_oids[asciiOid]
            log.output('parse_ec_parameters_get_dp(): selected DP is supported: ', dp and "true" or "false")
        end
    end)
    if not pcRes then
        log.output('parse_ec_parameters_get_dp(): error:', debug.traceback(theErrorT))
    end
    return asciiOid, dp
end

function t.mt:create_object_eddsa_pubkey(pTemplateOrig, as_local)
    log.output('create_object_eddsa_pubkey()', pTemplateOrig, as_local)
    
    local pTemplate = utility.clone_table(pTemplateOrig)
    
    if self.userType ~= CKU.USER then
        log.output('create_object_eddsa_pubkey(): USER_NOT_LOGGED_IN')
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    log.output('create_object_eddsa_pubkey(): EC_POINT', hex.hexify(pTemplate[CKA.EC_POINT] or ""))
    log.output('create_object_eddsa_pubkey(): EC_PARAMS', hex.hexify(pTemplate[CKA.EC_PARAMS] or ""))
    if not pTemplate[CKA.EC_POINT] or not pTemplate[CKA.EC_PARAMS] then
        log.output('create_object_eddsa_pubkey(): EC_POINT or EC_PARAMS not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    if not self.mechanisms[CKM.EDDSA] then
        log.output('create_object_eddsa_pubkey(): EDDSA curves not supported by the card!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    local asciiOid = der.der_oid_to_ascii_oid(pTemplate[CKA.EC_PARAMS])
    
    if not Ed25519_curves_oids[asciiOid] then
        log.output('create_object_eddsa_pubkey(): specified EC_PARAMS not supported:', asciiOid)
        return CKR.ATTRIBUTE_VALUE_INVALID
    end


    log.output('create_object_eddsa_pubkey(): selected curve', asciiOid, Ed25519_curves_oids[asciiOid])

    local ecPointDer = der.parse(pTemplate[CKA.EC_POINT])
    if not ecPointDer[1] or ecPointDer[1].tag ~= der.STRING  then
        log.output('create_object_eddsa_pubkey(): EC_POINT not DER encoded or DER tag incorrect', hex.hexify(pTemplate[CKA.EC_POINT]))
    end
    local modulus_bits = string.len(ecPointDer[1].value) * 8
    
    pTemplate[CKA.LOCAL] = eCK.BBOOL(as_local)

    local freeId, freeSlot
    local ds_publist = self.ds_info.ds_publist
    local attr = oberthur_util.serialize_attr_ecc_priv_pub_key(pTemplate)
    local fid_val, fid_attr
    
    obj = objOberthurTmpl.GetECCPubKeyTemplate(t.mt.get_ecc_pubkey_ds, CKK.EC_EDWARDS)
    obj.private = false
    obj.ecc = true
    obj.ds_parent_path = self.ds_info.path_root .. self.ds_df_pub
    obj.key_bits = modulus_bits

    -- cerca a partire da id 2 e slot 4
    freeId = oberthur_util.look_for_free_id(oberthur_util.objFIDS.ePubEdDSA, ds_publist, 2, 1)
    local freeSlots = oberthur_util.look_for_free_slots(ds_publist, 1, 4)
    
    if freeId == nil or table.getn(freeSlots) == 0 then
        return CKR.DEVICE_MEMORY
    end
    freeSlot = freeSlots[1]
    fid_val = oberthur_util.objFIDS.ePubEdDSA + bin.flags(freeId)
    fid_attr = fid_val + bin.flags('0x100')
    obj.ds_id = string.format('%04X', fid_val.asnumber )  -- fid oggetto DS
    obj.path = obj.ds_parent_path .. string.format('%04X', fid_val.asnumber ) -- path reale del file TLV della chiave pubblica

    obj.num = freeId
    obj.slot = freeSlot

    
    -- crea gli attributi della chiave pubblica
    self:create_file( {
                    size=string.len(attr), 
                    filetype=CnsSmartcard.fileTypes.Binary,
                    parent=hexf(obj.ds_parent_path),
                    fid=fid_attr.asnumber, }, true)
    self.cns_hcard:mupdate_binary(0, attr)
    
    -- update objects list
    ds_publist[freeSlot].usage = IDEMIA_USAGE_USED
    ds_publist[freeSlot].id = hexf(obj.ds_id)
    ds_publist[freeSlot].id_numeric = tonumber(obj.ds_id, 16)
    ds_publist[freeSlot].infos = obj.key_bits
    
    self:write_objlist(true) -- write public list
    
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    return CKR.OK, self.attributes.max_index
end

function t.mt:create_object_ecc_pubkey(pTemplateOrig, as_local)
    log.output('create_object_ecc_pubkey()', pTemplateOrig, as_local)
    
    local pTemplate = utility.clone_table(pTemplateOrig)
    
    if self.userType ~= CKU.USER then
        log.output('create_object_ecc_pubkey(): USER_NOT_LOGGED_IN')
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    if not self.mechanisms[CKM.ECDSA] then
        log.output('create_object_ecc_pubkey(): ECDSA curves not supported by the card!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    local obj
    log.output('create_object_ecc_pubkey(): EC_POINT', hex.hexify(pTemplate[CKA.EC_POINT] or ""))
    log.output('create_object_ecc_pubkey(): EC_PARAMS', hex.hexify(pTemplate[CKA.EC_PARAMS] or ""))
    if not pTemplate[CKA.EC_POINT] or not pTemplate[CKA.EC_PARAMS] then
        log.output('create_object_ecc_pubkey(): EC_POINT or EC_PARAMS not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    


    local asciiOid, dp = self:parse_ec_parameters_get_dp(pTemplate[CKA.EC_PARAMS], true)

    if not dp then
        log.output('create_object_ecc_pubkey(): specified EC_PARAMS not supported:', asciiOid)
        return CKR.ATTRIBUTE_VALUE_INVALID
    end

    log.output('create_object_ecc_pubkey(): selected curve', dp.name, asciiOid)


    local ecPointDer = der.parse(pTemplate[CKA.EC_POINT])
    if not ecPointDer[1] or ecPointDer[1].tag ~= der.STRING  then
        log.output('create_object_eddsa_pubkey(): EC_POINT not DER encoded or DER tag incorrect', hex.hexify(pTemplate[CKA.EC_POINT]))
    end
    
    if string.byte(ecPointDer[1].value) ~= 4 then
        log.output("create_object_ecc_pubkey(): EC_POINT decoded DER VALUE: value invalid, doesn't starts with 0x04!")
    end
    local modulus_bits = (string.len(ecPointDer[1].value) -1) * 4

    pTemplate[CKA.LOCAL] = eCK.BBOOL(as_local)

    local freeId, freeSlot
    local ds_publist = self.ds_info.ds_publist
    local attr = oberthur_util.serialize_attr_ecc_priv_pub_key(pTemplate)
    local fid_val, fid_attr
    
    obj = objOberthurTmpl.GetECCPubKeyTemplate(t.mt.get_ecc_pubkey_ds)
    obj.private = false
    obj.ecc = true
    obj.ds_parent_path = self.ds_info.path_root .. self.ds_df_pub
    obj.key_bits = modulus_bits

    -- cerca a partire da id 2 e slot 4
    freeId = oberthur_util.look_for_free_id(oberthur_util.objFIDS.ePubECC, ds_publist, 2, 1)
    local freeSlots = oberthur_util.look_for_free_slots(ds_publist, 1, 4)
    
    if freeId == nil or table.getn(freeSlots) == 0 then
        return CKR.DEVICE_MEMORY
    end
    freeSlot = freeSlots[1]
    fid_val = oberthur_util.objFIDS.ePubECC + bin.flags(freeId)
    fid_attr = fid_val + bin.flags('0x100')
    obj.ds_id = string.format('%04X', fid_val.asnumber )  -- fid oggetto DS
    obj.path = obj.ds_parent_path .. string.format('%04X', fid_val.asnumber ) -- path reale del file TLV della chiave pubblica

    obj.num = freeId
    obj.slot = freeSlot
    
    -- crea gli attributi della chiave pubblica
    self:create_file( {
                    size=string.len(attr), 
                    filetype=CnsSmartcard.fileTypes.Binary,
                    parent=hexf(obj.ds_parent_path),
                    fid=fid_attr.asnumber, }, true)
    self.cns_hcard:mupdate_binary(0, attr)
    
    -- update objects list
    ds_publist[freeSlot].usage = IDEMIA_USAGE_USED
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
        objListPath = self.ds_info.path_root .. '4000'
        objList = self.ds_info.ds_publist
    else
        objListPath = self.ds_info.path_root .. '5000'
        objList = self.ds_info.ds_prilist
    end
    self.cns_hcard:select(hex.hexf(objListPath))
    self.cns_hcard:mupdate_binary(0, oberthur_util.serialize_ds_objlist(objList))
end


function t.mt:create_rsa_bso(kid, modulus, exponent, key_bits, is_ds, create_bso, isdsx)
    log.output('create_rsa_bso():', kid, key_bits, is_ds, create_bso, isdsx)
    local create_des3_BSO_DSX_AUTH
    local dsi = self.ds_info
    local sm_enc, sm_sig
    local privExp
    local pso_dec = not is_ds
    if isdsx then
        pso_dec = true
        is_ds = true
    end
    log.output('create_rsa_bso(): pso_dec', pso_dec)
    log.output('create_rsa_bso(): is_ds', is_ds)
    -- creates a BSO using correct ACs and algo
    local bso_info = {key_bits=key_bits,
        kid=kid,
        pso_dec=pso_dec,
        aac = {use=self.cns_hcard.BSO_CNS_PIN, change=self.cns_hcard.BSO_CNS_PIN, 
               delete=self.cns_hcard.BSO_CNS_PIN, generate=self.cns_hcard.BSO_CNS_PIN},
    }
    if is_ds then
        bso_info.aac.use = self.cns_hcard.BSO_DS_PIN
        bso_info.aac.change = nil
        if dsi.sm_admin_enc and dsi.sm_admin_sig and dsi.sm_use_enc and dsi.sm_use_sig then
            bso_info.asm = {
            use_in_enc=dsi.sm_use_enc_id, use_in_sig=dsi.sm_use_sig_id,
            use_out_enc=dsi.sm_use_enc_id, use_out_sig=dsi.sm_use_sig_id,
            change_enc=dsi.sm_admin_enc_id, change_sig=dsi.sm_admin_sig_id }
        end
    end
    
    if isdsx then
        bso_info.aac.use = self.cns_hcard.BSO_DSX_AUTH
        
        create_des3_BSO_DSX_AUTH =
            hex.hexf(
                string.gsub("00da016e 43 8302 00%B 8508 83 03 82 03 ffff 02 08 86 07 1d1d1dffff10ff cb10ffffffffffffffffffffffffffffffff 8f 18 %S 00", '%s', ''), 
                self.cns_hcard.BSO_DSX_AUTH,
                self.DSX_DERIVED_KEY_AUTH)
        
    end
    
    if modulus and exponent then
        if key_bits == 1024 then
            rv, privExp = self:_pad_bignum(exponent, 128)
            assert(rv == CKR.OK)
        elseif key_bits == 2048 then
            rv, privExp = self:_pad_bignum(exponent, 256)
            assert(rv == CKR.OK)
        end
        bso_info.exponent = privExp
        bso_info.modulus = modulus
    end
    
    if dsi.sm_admin_enc and dsi.sm_admin_sig then
        sm_enc = dsi.sm_admin_enc
        sm_sig = dsi.sm_admin_sig
    end
    
    if not (create_bso or (not is_ds and modulus and exponent)) then
        error('create_rsa_bso(): NOTHING TO DO! Check parameters!')
    end
    
    if create_bso then
        pcall (function()
            --log.output('create_rsa_bso(): erasing bso MOD...')
            --local erase_mod = hex.hexf('80E4016E0220%B', kid)
            --self.cns_hcard:transmit(erase_mod)
            log.output('create_rsa_bso(): erasing bso by EXP...')
            local erase_exp = hex.hexf('80E4016E0221%B', kid)
            self.cns_hcard:transmit(erase_exp)
        end)
        if create_des3_BSO_DSX_AUTH then
            local recv = self.cns_hcard:sm_transmit(create_des3_BSO_DSX_AUTH, sm_enc, sm_sig)
            
            local sw = string.sub(recv, -2, -1)
            if sw ~= hexf('9000') then
                log.output('create_rsa_bso(): error creating BSO AUTH obj')
            end
        end
        self.cns_hcard:create_rsa_bso_oberthur(bso_info, sm_enc, sm_sig)

    elseif not is_ds and modulus and exponent then
        self.cns_hcard:change_rsa_bso(kid, modulus, privExp)
    end
end


function t.mt:create_object_privkey(pTemplateOrig, as_local)
    log.output('create_object_privkey()', pTemplateOrig)
    
    local pTemplate = utility.clone_table(pTemplateOrig)
    pTemplate[CKA.LOCAL] = eCK.BBOOL(as_local)
    
    if self.userType ~= CKU.USER then
        log.output('create_object_privkey(): USER_NOT_LOGGED_IN')
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    if not pTemplate[CKA.MODULUS] or not pTemplate[CKA.PUBLIC_EXPONENT] 
        or not pTemplate[CKA.PRIVATE_EXPONENT] then
        log.output('create_object_privkey(): MODULUS or PUBLIC_EXPONENT or PRIVATE_EXPONENT not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    local iscns = self:is_cns(pTemplate)
    local isds = self:is_ds(pTemplate) or self:is_dsx(pTemplate)
    local isdsx = self:is_dsx(pTemplate)
    local fid_val, fid_attr
    log.output('create_object_privkey(): isds:', isds, "isdsx:", isdsx)
    
    if isdsx and not self:is_dsx_licensed() then
        log.output('create_object_privkey(): DSX objects are not licensed on this card!')
        return CKR.ACTION_PROHIBITED
    end
    
    if isds then
        log.output('create_object_privkey(): importing a DS private keys...')
    end
    
    
    -- if isds then
        -- log.output('create_object_privkey(): cannot import DS private keys!')
        -- return CKR.TEMPLATE_INCONSISTENT
    -- end
    
    local modulus_bits = string.len(pTemplate[CKA.MODULUS]) * 8
    local privateExponent = string.rep('\000', string.len(pTemplate[CKA.MODULUS]) - string.len(pTemplate[CKA.PRIVATE_EXPONENT]))
                            .. pTemplate[CKA.PRIVATE_EXPONENT]
    if iscns and modulus_bits ~= 1024 then
        log.output('create_object_privkey(): MODULUS size not 1024!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    if modulus_bits ~= 1024 and modulus_bits ~= 2048 then
        log.output('create_object_privkey(): MODULUS size not 1024 or 2048!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end

    local freeId, freeSlot
    local ds_prilist = self.ds_info.ds_prilist
    local attr = oberthur_util.serialize_attr_privkey(pTemplate)

    obj = objOberthurTmpl.GetDSPrivKeyTemplate(t.mt.get_privkey_ds)
    obj.private = true
    obj.ds_parent_path = self.ds_info.path_root .. self.ds_df_priv
    obj.key_bits = modulus_bits
    if iscns then
        if 0 ~= ds_prilist[1].usage then
            log.output('create_object_privkey(): CNS Private Key already exists')
            return CKR.DEVICE_MEMORY
        end
        freeId, freeSlot = 1, 1 -- todo: free slot dovrebbe essere cercato da 1 a 3
        obj.ds_id = '3001'  -- fid DS
        obj.path = '3F00'   -- path in cui si trova il BSO
        obj.pso_dec = true
        obj.kid = 1
        fid_attr = bin.flags('0x3101')
    else
    
        if isds then
            freeId = oberthur_util.look_for_free_id2(oberthur_util.objFIDS.ePrivKey, oberthur_util.objFIDS.ePrivECC, ds_prilist, 2, 1)
            obj.pso_dec = isdsx
            obj.pso_dec_sm = isdsx
            if freeId > 11 then
                log.output('create_object_privkey(): no more DS space available, freeId:', freeId)
                freeId = nil
            end
            pTemplate[CKA.DECRYPT] = eCK.BBOOL(false)
        else
            -- cerca a partire da id 12 e slot 2
            freeId = oberthur_util.look_for_free_id(oberthur_util.objFIDS.ePrivKey, ds_prilist, 12, 1)
            obj.pso_dec = true
        end


        local freeSlots = oberthur_util.look_for_free_slots(ds_prilist, 1, 2)
        
        if freeId == nil or freeId > 27 or table.getn(freeSlots) == 0 then
            log.output('create_object_privkey(): no more space available, freeId:', freeId, 'freeSlots:', repr(freeSlots))
            return CKR.DEVICE_MEMORY
        end
        freeSlot = freeSlots[1]
        fid_val = oberthur_util.objFIDS.ePrivKey + bin.flags(freeId)
        fid_attr = fid_val + bin.flags('0x100')
        obj.ds_id = hex.hexify(hex.hexf("%H",  fid_val.asnumber) ) -- fid DS
        obj.path = obj.ds_parent_path -- path in cui si trova il BSO della chiave
        obj.kid = freeId
    end
    obj.num = freeId
    obj.slot = freeSlot
    
    -- crea / aggiorna il BSO
    self.cns_hcard:select(hexf(obj.path)) -- seleziona il parent del BSO
    
    self:create_rsa_bso(obj.kid, pTemplate[CKA.MODULUS], privateExponent, modulus_bits, isds, not iscns, isdsx)
    
    -- crea gli attributi della chiave privata
    self:create_file( {
                    size=string.len(attr), 
                    filetype=CnsSmartcard.fileTypes.Binary,
                    parent=hexf(obj.ds_parent_path),
                    fid=fid_attr.asnumber, }, false)
    self.cns_hcard:mupdate_binary(0, attr)
    
    -- update objects list
    ds_prilist[freeSlot].usage = obj.pso_dec_sm and IDEMIA_USAGE_USED2 or IDEMIA_USAGE_USED
    ds_prilist[freeSlot].id = hexf(obj.ds_id)
    ds_prilist[freeSlot].id_numeric = tonumber(obj.ds_id, 16)
    ds_prilist[freeSlot].infos = obj.key_bits
    
    self:write_objlist(false) -- write private list
    
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    return CKR.OK, self.attributes.max_index
end

function t._enc_dec_sensitive_data(data, seed, enc)
    local mKey = sm.sm_ask_keys(10)  -- richiede la chiave #10, chiave master Oberthur
    local sha = md.sha256()
    sha:update(mKey .. seed)
    local k = sha:final()
    
    local check = "\0\0\0\0\0\0\0\1"
    local result
    if enc then
        result = aes.aes_encrypt_check(k, data, check)
    else
        result = aes.aes_decrypt_check(k, data, check)
    end
    mKey = nil
    key = nil
    collectgarbage() -- force clear unused memory
    return result
end



function t.mt:create_object_eddsa_privkey(pTemplateOrig, as_local)
    log.output('create_object_eddsa_privkey()', pTemplateOrig)
    
    local pTemplate = utility.clone_table(pTemplateOrig)
    pTemplate[CKA.LOCAL] = eCK.BBOOL(as_local)
    
    if self.userType ~= CKU.USER then
        log.output('create_object_eddsa_privkey(): USER_NOT_LOGGED_IN')
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    if not self.mechanisms[CKM.EDDSA] then
        log.output('create_object_eddsa_privkey(): EDDSA curves not supported by the card!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    local obj
    log.output('create_object_eddsa_privkey(): VALUE:', hex.hexify(pTemplate[CKA.VALUE] or ""))
    log.output('create_object_eddsa_privkey(): EC_PARAMS:', hex.hexify(pTemplate[CKA.EC_PARAMS] or ""))
    if not pTemplate[CKA.EC_PARAMS] 
        or not pTemplate[CKA.VALUE] then
        log.output('create_object_eddsa_privkey(): EC_PARAMS or VALUE not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end  

    local asciiOid = der.der_oid_to_ascii_oid(pTemplate[CKA.EC_PARAMS])
    
    if not Ed25519_curves_oids[asciiOid] then
        log.output('create_object_eddsa_privkey(): specified EC_PARAMS not supported:', asciiOid)
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    log.output('create_object_eddsa_privkey(): selected curve', asciiOid, Ed25519_curves_oids[asciiOid])

    local valueKey = pTemplate[CKA.VALUE]
    local privateKeyValue, point
    if string.len(valueKey) == 64 then
        privateKeyValue = valueKey
        point = string.sub(valueKey, 33, -1)
    elseif string.len(valueKey) == 32 then
        point, privateKeyValue = sm.crypto_sign_ed25519_seed_keypair(valueKey)
    else
        log.output('create_object_eddsa_privkey(): invalid key VALUE', hex.hexify(valueKey))
    end
    log.output('create_object_eddsa_privkey(): EC_POINT', hex.hexify(point))
    log.output('create_object_eddsa_privkey(): privateKeyValue', hex.hexify(privateKeyValue))
    
    pTemplate[CKA.EC_POINT] = der.build(der.STRING, point)

    local fid_val, fid_attr                   
    local modulus_bits = string.len(privateKeyValue) * 8

    local freeId, freeSlot
    local ds_prilist = self.ds_info.ds_prilist
    local attr = oberthur_util.serialize_attr_ecc_priv_pub_key(pTemplate)

    obj = objOberthurTmpl.GetECCPrivKeyTemplate(t.mt.get_ecc_privkey_ds, CKK.EC_EDWARDS)
    obj.private = true
    obj.ecc = true
    obj.ds_parent_path = self.ds_info.path_root .. self.ds_df_ecc
    obj.key_bits = modulus_bits

    -- cerca a partire da id 2 e slot 2
    freeId = oberthur_util.look_for_free_id(oberthur_util.objFIDS.ePrivEdDSA, ds_prilist, 2, 1)
    local freeSlots = oberthur_util.look_for_free_slots(ds_prilist, 1, 2)
    
    if freeId == nil or freeId > 27 or table.getn(freeSlots) == 0 then
        log.output('create_object_eddsa_privkey(): no more space available, freeId:', freeId, 'freeSlots:', repr(freeSlots))
        return CKR.DEVICE_MEMORY
    end
    freeSlot = freeSlots[1]
    fid_val = oberthur_util.objFIDS.ePrivEdDSA + bin.flags(freeId)
    fid_attr = fid_val + bin.flags('0x100')
    obj.ds_id = hex.hexify(hex.hexf("%H",  fid_val.asnumber) ) -- fid DS
    obj.path = obj.ds_parent_path -- path in cui si trova il BSO della chiave
    obj.kid = freeId

    obj.num = freeId
    obj.slot = freeSlot
    -- crea il value
    local enc_privateKeyValue = t._enc_dec_sensitive_data(privateKeyValue, self.info.serialNumber, true)

    obj.sk = enc_privateKeyValue
    self:create_file( {
                    size=string.len(enc_privateKeyValue), 
                    filetype=CnsSmartcard.fileTypes.Binary,
                    parent=hexf(obj.ds_parent_path),
                    fid=fid_val.asnumber, }, true)
    -- scrive il value
    self.cns_hcard:mupdate_binary(0, enc_privateKeyValue)
    
    
    -- crea gli attributi della chiave privata
    self:create_file( {
                    size=string.len(attr), 
                    filetype=CnsSmartcard.fileTypes.Binary,
                    parent=hexf(obj.ds_parent_path),
                    fid=fid_attr.asnumber, }, false)
    self.cns_hcard:mupdate_binary(0, attr)
    
    -- update objects list
    ds_prilist[freeSlot].usage = IDEMIA_USAGE_USED
    ds_prilist[freeSlot].id = hexf(obj.ds_id)
    ds_prilist[freeSlot].id_numeric = tonumber(obj.ds_id, 16)
    ds_prilist[freeSlot].infos = obj.key_bits
    
    self:write_objlist(false) -- write private list
    
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    return CKR.OK, self.attributes.max_index
end




function t.mt:create_object_ecc_privkey(pTemplateOrig, as_local)
    log.output('create_object_ecc_privkey()', pTemplateOrig)
    
    local pTemplate = utility.clone_table(pTemplateOrig)
    pTemplate[CKA.LOCAL] = eCK.BBOOL(as_local)
    
    if self.userType ~= CKU.USER then
        log.output('create_object_ecc_privkey(): USER_NOT_LOGGED_IN')
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    if not self.mechanisms[CKM.ECDSA] then
        log.output('create_object_ecc_privkey(): ECDSA curves not supported by the card!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    local obj
    log.output('create_object_ecc_privkey(): VALUE:', hex.hexify(pTemplate[CKA.VALUE] or ""))
    log.output('create_object_ecc_privkey(): EC_PARAMS:', hex.hexify(pTemplate[CKA.EC_PARAMS] or ""))
    if not pTemplate[CKA.EC_PARAMS] 
        or not pTemplate[CKA.VALUE] then
        log.output('create_object_ecc_privkey(): EC_PARAMS or VALUE not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end

    

    local asciiOid, dp = self:parse_ec_parameters_get_dp(pTemplate[CKA.EC_PARAMS], true)
    
    if not dp then
        log.output('create_object_ecc_privkey(): specified EC_PARAMS not supported:', asciiOid)
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    log.output('create_object_ecc_privkey(): selected curve', dp.name, asciiOid)

    local isds = self:is_ds(pTemplate) or pTemplate[CKA.ALWAYS_AUTHENTICATE] == eCK.BBOOL(true)
                    or self:is_dsx(pTemplate)
    log.output('create_object_ecc_privkey(): isds', isds)

    pTemplate[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(isds)
    
    -- calculates EC_POINT and save it in the private key attributes (PKCS#11 don't define EC_POINT attribute for ECC private keys)
    local curve = ecdhlib.get_curve(dp.name)
    local privKey, pubKey = curve.g:make_keypair(bignum.create("0x" .. hex.hexify(pTemplate[CKA.VALUE])))
    local point = pubKey:encode_point(true)
    log.output('create_object_ecc_privkey(): EC_POINT (calculated)', hex.hexify(point))
    pTemplate[CKA.EC_POINT] = der.build(der.STRING, point)

    local fid_val, fid_attr
    local modulus_bits = (string.len(point) -1) * 4
    local valueKey = pTemplate[CKA.VALUE]

    local freeId, freeSlot
    local ds_prilist = self.ds_info.ds_prilist
    local attr = oberthur_util.serialize_attr_ecc_priv_pub_key(pTemplate)

    obj = objOberthurTmpl.GetECCPrivKeyTemplate(t.mt.get_ecc_privkey_ds)
    obj.private = true
    obj.ecc = true
    if isds then
        obj.ds_parent_path = self.ds_info.path_root .. self.ds_df_priv
    else
        obj.ds_parent_path = self.ds_info.path_root .. self.ds_df_ecc
    end
    obj.key_bits = modulus_bits

    if isds then
        -- cerca a partire da id 2 e slot 2
        freeId = oberthur_util.look_for_free_id2(oberthur_util.objFIDS.ePrivECC, oberthur_util.objFIDS.ePrivKey, ds_prilist, 2, 1)
    else
        freeId = oberthur_util.look_for_free_id(oberthur_util.objFIDS.ePrivECC, ds_prilist, 2, 1)
    end
    local freeSlots = oberthur_util.look_for_free_slots(ds_prilist, 1, 2)
    
    if freeId == nil or freeId > 27 or table.getn(freeSlots) == 0 then
        log.output('create_object_ecc_privkey(): no more space available, freeId:', freeId, 'freeSlots:', repr(freeSlots))
        return CKR.DEVICE_MEMORY
    end
    freeSlot = freeSlots[1]
    fid_val = oberthur_util.objFIDS.ePrivECC + bin.flags(freeId)
    fid_attr = fid_val + bin.flags('0x100')
    obj.ds_id = hex.hexify(hex.hexf("%H",  fid_val.asnumber) ) -- fid DS
    obj.path = obj.ds_parent_path -- path in cui si trova il BSO della chiave
    obj.kid = freeId

    obj.num = freeId
    obj.slot = freeSlot
    
    local bso_info = {
        private_component = valueKey,
        kid = obj.kid,
        asciiOid=dp.asciiOid,
        -- aac= nil,
        path = hex.hexf(obj.path),
        }
    -- crea / aggiorna il BSO
    self.cns_hcard:select(hexf(obj.path), true) -- seleziona il parent del BSO
    self.cns_hcard:create_ecc_bso_oberthur(bso_info, self.ds_info.sm_admin_enc, self.ds_info.sm_admin_sig, isds, self.ds_info)
    
    -- crea gli attributi della chiave privata
    self:create_file( {
                    size=string.len(attr), 
                    filetype=CnsSmartcard.fileTypes.Binary,
                    parent=hexf(obj.ds_parent_path),
                    fid=fid_attr.asnumber, }, false)
    self.cns_hcard:mupdate_binary(0, attr)
    
    -- update objects list
    ds_prilist[freeSlot].usage = IDEMIA_USAGE_USED
    ds_prilist[freeSlot].id = hexf(obj.ds_id)
    ds_prilist[freeSlot].id_numeric = tonumber(obj.ds_id, 16)
    ds_prilist[freeSlot].infos = obj.key_bits + (isds and ECC_QUALIFIED_KEYBITS_FLAG.asnumber or 0)
    
    self:write_objlist(false) -- write private list
    
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    return CKR.OK, self.attributes.max_index
end


function t.mt:generate_key_pair_ecc(pMechanism, templatePub, templatePriv)
    log.output('generate_key_pair_ecc():', pMechanism, templatePub, templatePriv)
    
    local info = self:get_info()
    if not self.mechanisms[CKM.EC_KEY_PAIR_GEN] then
        log.output('generate_key_pair_ecc(): ECDSA curves not supported by the card!')
        return CKR.MECHANISM_INVALID
    end
    
    local pTemplatePub = utility.clone_table(templatePub)
    local pTemplatePriv = utility.clone_table(templatePriv)
    pTemplatePub[CKA.LOCAL] = eCK.BBOOL(true)
    pTemplatePriv[CKA.LOCAL] = eCK.BBOOL(true)
    
    pTemplatePriv[CKA.SIGN] =  eCK.BBOOL(true)
    pTemplatePriv[CKA.DECRYPT] = eCK.BBOOL(false)
    pTemplatePub[CKA.VERIFY] = pTemplatePub[CKA.VERIFY] or eCK.BBOOL(true)
    pTemplatePub[CKA.ENCRYPT] = eCK.BBOOL(false)
    
    if self.userType ~= CKU.USER then
        log.output('generate_key_pair_ecc(): USER_NOT_LOGGED_IN')
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    log.output('generate_key_pair_ecc(): EC_PARAMS:', hex.hexify(pTemplatePub[CKA.EC_PARAMS] or ""))
    if not pTemplatePub[CKA.EC_PARAMS] then
        log.output('generate_key_pair_ecc(): EC_PARAMS not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local asciiOid, dp = self:parse_ec_parameters_get_dp(pTemplatePub[CKA.EC_PARAMS], true)
    
    if not dp then
        log.output('generate_key_pair_ecc(): specified EC_PARAMS not supported:', asciiOid)
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    log.output('generate_key_pair_ecc(): selected curve', dp.name, asciiOid)

    local isds = self:is_ds(pTemplatePub) or self:is_ds(pTemplatePriv) 
                or self:is_dsx(pTemplatePub) or self:is_dsx(pTemplatePriv) 
                or pTemplatePub[CKA.ALWAYS_AUTHENTICATE] == eCK.BBOOL(true)
                or pTemplatePriv[CKA.ALWAYS_AUTHENTICATE] == eCK.BBOOL(true)

    pTemplatePub[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(isds)
    pTemplatePriv[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(isds)
    
    local fid_val, fid_attr
    local modulus_bits = dp.keysize*8

    local freeId, freeSlot
    local ds_prilist = self.ds_info.ds_prilist
    local attr

    obj = objOberthurTmpl.GetECCPrivKeyTemplate(t.mt.get_ecc_privkey_ds)
    obj.private = true
    obj.ecc = true
    if isds then
        obj.ds_parent_path = self.ds_info.path_root .. self.ds_df_priv
    else
        obj.ds_parent_path = self.ds_info.path_root .. self.ds_df_ecc
    end
    obj.key_bits = modulus_bits

    -- cerca a partire da id 2 e slot 2
    if isds then
        -- cerca a partire da id 2 e slot 2
        freeId = oberthur_util.look_for_free_id2(oberthur_util.objFIDS.ePrivECC, oberthur_util.objFIDS.ePrivKey, ds_prilist, 2, 1)
    else
        freeId = oberthur_util.look_for_free_id(oberthur_util.objFIDS.ePrivECC, ds_prilist, 2, 1)
    end
    
    local freeSlots = oberthur_util.look_for_free_slots(ds_prilist, 1, 2)
    
    if freeId == nil or freeId > 27 or table.getn(freeSlots) == 0 then
        log.output('generate_key_pair_ecc(): no more space available, freeId:', freeId, 'freeSlots:', repr(freeSlots))
        return CKR.DEVICE_MEMORY
    end
    freeSlot = freeSlots[1]
    fid_val = oberthur_util.objFIDS.ePrivECC + bin.flags(freeId)
    fid_attr = fid_val + bin.flags('0x100')
    obj.ds_id = hex.hexify(hex.hexf("%H",  fid_val.asnumber) ) -- fid DS
    obj.path = obj.ds_parent_path -- path in cui si trova il BSO della chiave
    obj.kid = freeId

    obj.num = freeId
    obj.slot = freeSlot
    
    local bso_info = {
        kid = obj.kid,
        asciiOid=dp.asciiOid,
        -- aac= nil,
        path = hex.hexf(obj.path),
        }
    -- crea / aggiorna il BSO
    self.cns_hcard:select(hexf(obj.path), true) -- seleziona il parent del BSO
    self.cns_hcard:create_ecc_bso_oberthur(bso_info, self.ds_info.sm_admin_enc, self.ds_info.sm_admin_sig, isds, self.ds_info)
    local pubTlv = hex.hexf("3200")
    
    self:create_file( {
                size=dp.pubkeysize,
                filetype=CnsSmartcard.fileTypes.RecordTLV,
                parent=hex.hexf(obj.ds_parent_path),
                aac={read=0, update=0, delete=0, append=0, admin=0, ac8=0, ac9=0, ac4=0, ac5=0},
                fid=pubTlv, }, true, true)

    local pubKey = self.cns_hcard:generate_ecc_bso_oberthur(obj.kid, pubTlv)
    log.output("generate_key_pair_ecc(): generated pubKey:", hex.hexify(pubKey))

    --pcall(function()
        self.cns_hcard:select(hex.hexf(obj.ds_parent_path))
        self.cns_hcard:delete_file(pubTlv)
    --end)
    
    if pTemplatePub[CKA.ID] then
        pTemplatePriv[CKA.ID] = pTemplatePub[CKA.ID]
    elseif pTemplatePriv[CKA.ID] then
        pTemplatePub[CKA.ID] = pTemplatePriv[CKA.ID]
    end
    
    pTemplatePriv[CKA.EC_POINT] = der.build(der.STRING, pubKey)
    pTemplatePriv[CKA.EC_PARAMS] = pTemplatePub[CKA.EC_PARAMS]
    
    pTemplatePub[CKA.KEY_TYPE] = pTemplatePriv[CKA.KEY_TYPE]
    pTemplatePub[CKA.EC_POINT] = pTemplatePriv[CKA.EC_POINT]
    
    attr = oberthur_util.serialize_attr_ecc_priv_pub_key(pTemplatePriv)
    
    -- crea gli attributi della chiave privata
    self:create_file( {
                    size=string.len(attr), 
                    filetype=CnsSmartcard.fileTypes.Binary,
                    parent=hexf(obj.ds_parent_path),
                    fid=fid_attr.asnumber, }, false)
    self.cns_hcard:mupdate_binary(0, attr)
    
    -- update objects list
    ds_prilist[freeSlot].usage = IDEMIA_USAGE_USED
    ds_prilist[freeSlot].id = hexf(obj.ds_id)
    ds_prilist[freeSlot].id_numeric = tonumber(obj.ds_id, 16)
    ds_prilist[freeSlot].infos = obj.key_bits + (isds and ECC_QUALIFIED_KEYBITS_FLAG.asnumber or 0)
    
    self:write_objlist(false) -- write private list
    
    -- adds new handle to the list
    local hPrivk
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    hPrivk = self.attributes.max_index
    
    local rv, hPubk = self:create_object_ecc_pubkey(pTemplatePub, true)
    log.output('generate_key_pair_ecc() create_object_ecc_pubkey(pubkey): result:', rv, 'handle:', hPubk)
    
    log.output('generate_key_pair_ecc(): success, returning', hPubk, hPrivk)
    if rv == CRK_OK then
        self:update_free_mem(self.info)
    end
    self:update_cache_id()
    return CKR.OK, hPubk, hPrivk
end


function t.mt:generate_key_pair_eddsa(pMechanism, templatePub, templatePriv)
    log.output('generate_key_pair_eddsa()')
    
    if not self.mechanisms[CKM.EC_EDWARDS_KEY_PAIR_GEN] then
        log.output('generate_key_pair_eddsa(): EDDSA curves not supported by the card!')
        return CKR.MECHANISM_INVALID
    end
    
    local pTemplatePub = utility.clone_table(templatePub)
    local pTemplatePriv = utility.clone_table(templatePriv)
    pTemplatePub[CKA.LOCAL] = eCK.BBOOL(true)
    pTemplatePriv[CKA.LOCAL] = eCK.BBOOL(true)
    
    pTemplatePriv[CKA.SIGN] =  eCK.BBOOL(true)
    pTemplatePriv[CKA.DECRYPT] = eCK.BBOOL(false)
    pTemplatePub[CKA.VERIFY] = pTemplatePub[CKA.VERIFY] or eCK.BBOOL(true)
    pTemplatePub[CKA.ENCRYPT] = eCK.BBOOL(false)
    
    if self.userType ~= CKU.USER then
        log.output('generate_key_pair_eddsa(): USER_NOT_LOGGED_IN')
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    log.output('generate_key_pair_eddsa(): EC_PARAMS:', hex.hexify(pTemplatePub[CKA.EC_PARAMS] or ""))
    if not pTemplatePub[CKA.EC_PARAMS] then
        log.output('generate_key_pair_eddsa(): EC_PARAMS not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local asciiOid = der.der_oid_to_ascii_oid(pTemplatePub[CKA.EC_PARAMS])
    
    if not Ed25519_curves_oids[asciiOid] then
        log.output('generate_key_pair_eddsa(): specified EC_PARAMS not supported:', asciiOid)
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    log.output('generate_key_pair_eddsa(): selected curve', asciiOid, Ed25519_curves_oids[asciiOid])

    local fid_val, fid_attr

    local freeId, freeSlot
    local ds_prilist = self.ds_info.ds_prilist
    local attr

    obj = objOberthurTmpl.GetECCPrivKeyTemplate(t.mt.get_ecc_privkey_ds, CKK.EC_EDWARDS)
    obj.private = true
    obj.ecc = true
    obj.ds_parent_path = self.ds_info.path_root .. self.ds_df_ecc
    
    obj.key_bits = 256

    -- cerca a partire da id 2 e slot 2
    freeId = oberthur_util.look_for_free_id(oberthur_util.objFIDS.ePrivEdDSA, ds_prilist, 2, 1)
    local freeSlots = oberthur_util.look_for_free_slots(ds_prilist, 1, 2)
    
    if freeId == nil or freeId > 27 or table.getn(freeSlots) == 0 then
        log.output('generate_key_pair_eddsa(): no more space available, freeId:', freeId, 'freeSlots:', repr(freeSlots))
        return CKR.DEVICE_MEMORY
    end
    freeSlot = freeSlots[1]
    fid_val = oberthur_util.objFIDS.ePrivEdDSA + bin.flags(freeId)
    fid_attr = fid_val + bin.flags('0x100')
    obj.ds_id = hex.hexify(hex.hexf("%H",  fid_val.asnumber) ) -- fid DS
    obj.path = obj.ds_parent_path -- path in cui si trova il BSO della chiave
    obj.kid = freeId

    obj.num = freeId
    obj.slot = freeSlot
    

    self.cns_hcard:select(hexf(obj.path), true) -- seleziona il parent del BSO

    
    -- crea file della chiave privata
    -- TODO: cifrare
    local eddsaPubK, eddsaPrivK = sm.crypto_sign_ed25519_keypair()
    
    local enc_eddsaPrivK = t._enc_dec_sensitive_data(eddsaPrivK, self.info.serialNumber, true)
    obj.sk = enc_eddsaPrivK
    
    self:create_file( {
                    size=string.len(enc_eddsaPrivK), 
                    filetype=CnsSmartcard.fileTypes.Binary,
                    parent=hexf(obj.ds_parent_path),
                    fid=fid_val.asnumber, }, false)
    self.cns_hcard:mupdate_binary(0, enc_eddsaPrivK)
    eddsaPrivK = nil
    collectgarbage() -- forza liberazione della memoria inutilizzata
    
    if pTemplatePub[CKA.ID] then
        pTemplatePriv[CKA.ID] = pTemplatePub[CKA.ID]
    elseif pTemplatePriv[CKA.ID] then
        pTemplatePub[CKA.ID] = pTemplatePriv[CKA.ID]
    end
    
    pTemplatePriv[CKA.EC_POINT] = der.build(der.STRING, eddsaPubK)
    pTemplatePriv[CKA.EC_PARAMS] = pTemplatePub[CKA.EC_PARAMS]
    
    pTemplatePub[CKA.KEY_TYPE] = pTemplatePriv[CKA.KEY_TYPE]
    pTemplatePub[CKA.EC_POINT] = pTemplatePriv[CKA.EC_POINT]
    
    attr = oberthur_util.serialize_attr_ecc_priv_pub_key(pTemplatePriv)
    
    -- crea gli attributi della chiave privata
    self:create_file( {
                    size=string.len(attr), 
                    filetype=CnsSmartcard.fileTypes.Binary,
                    parent=hexf(obj.ds_parent_path),
                    fid=fid_attr.asnumber, }, false)
    self.cns_hcard:mupdate_binary(0, attr)
    
    -- update objects list
    ds_prilist[freeSlot].usage = IDEMIA_USAGE_USED
    ds_prilist[freeSlot].id = hexf(obj.ds_id)
    ds_prilist[freeSlot].id_numeric = tonumber(obj.ds_id, 16)
    ds_prilist[freeSlot].infos = obj.key_bits
    
    self:write_objlist(false) -- write private list
    
    -- adds new handle to the list
    local hPrivk
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    hPrivk = self.attributes.max_index
    
    local rv, hPubk = self:create_object_eddsa_pubkey(pTemplatePub, true)
    log.output('generate_key_pair_eddsa() create_object_eddsa_pubkey(pubkey): result:', rv, 'handle:', hPubk)
    
    log.output('generate_key_pair_eddsa(): success, returning', hPubk, hPrivk)
    if rv == CRK_OK then
        self:update_free_mem(self.info)
    end
    self:update_cache_id()
    return CKR.OK, hPubk, hPrivk
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

function t.mt:create_object_certificate(pTemplate)
    log.output('create_object_certificate()', pTemplate)
    
    if self.userType ~= CKU.USER then
        log.output('create_object_certificate(): USER_NOT_LOGGED_IN')
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
    local iscns = self:is_cns(pTemplate)
    
    local freeId, freeSlot
    local ds_publist = self.ds_info.ds_publist
    local pTemplate1 = utility.clone_table(pTemplate)
    pTemplate1[CKA.SUBJECT] = ""
    pTemplate1[CKA.ISSUER] = ""
    local attr = oberthur_util.serialize_attr_cert(pTemplate1)
    local fid_val, fid_attr
    
    obj = objOberthurTmpl.GetDSCertTemplate(t.mt.get_certificate_ds)
    obj.private = false
    obj.ds_parent_path = self.ds_info.path_root .. self.ds_df_pub
    obj.size = string.len(pTemplate[CKA.VALUE])
    if iscns then
        if 0 ~= ds_publist[3].usage then
            log.output('create_object_certificate(): CNS Certificate already exists')
            return CKR.DEVICE_MEMORY
        end
        freeId, freeSlot = 1, 3 -- todo: free slot dovrebbe essere cercato da 1 a 3
        obj.ds_id = '2001'         -- fid DS
        obj.path = '3f0011001101'  -- path reale del file del certificato
        fid_attr = bin.flags('0x2101')
    else
        -- cerca a partire da id 2 e slot 4
        freeId = oberthur_util.look_for_free_id(oberthur_util.objFIDS.eCert, ds_publist, 2, 1)
        local freeSlots = oberthur_util.look_for_free_slots(ds_publist, 1, 4)
        
        if freeId == nil or table.getn(freeSlots) == 0 then
            log.output('create_object_certificate(): no more space available')
            return CKR.DEVICE_MEMORY
        end
        freeSlot = freeSlots[1]
        fid_val = oberthur_util.objFIDS.eCert + bin.flags(freeId)
        fid_attr = fid_val + bin.flags('0x100')
        obj.ds_id = string.format('%04X', fid_val.asnumber )  -- fid DS
        obj.path = obj.ds_parent_path .. string.format('%04X', fid_val.asnumber ) -- path reale del file binario del certificato
    end
    obj.num = freeId
    obj.slot = freeSlot
    
    if not iscns then
        -- crea il file del certificato non CNS
        self:create_file( {
                        size=string.len(pTemplate[CKA.VALUE]), 
                        filetype=CnsSmartcard.fileTypes.Binary,
                        parent=hexf(obj.ds_parent_path),
                        fid=fid_val.asnumber, }, true)
    else
        self.cns_hcard:select(hex.hexf(obj.path))
    end
    
    local actual_cert_data = pTemplate[CKA.VALUE]
    
    actual_cert_data = CnsSmartcard.encode_x509_certificate(actual_cert_data)
    
    if not iscns and self.use_cpr_mode then
    
        local cpr, decpr
        if self.use_cpr_mode2 then
            cpr = zlib.compresscer2( actual_cert_data)
            decpr = cpr and zlib.decompresscer2(cpr)
        else
            cpr = zlib.compresscer( actual_cert_data)
            decpr = cpr and zlib.decompresscer(cpr)
        end
        if decpr == actual_cert_data then
            pcall(function()
                log.output('create_object_certificate(): cpr ratio:', 
                    string.len(cpr)/string.len(decpr))
            end)
            actual_cert_data = cpr
        else
            log.output('create_object_certificate(): compression failed!')
        end
    end

    -- scrive il certificato
    self.cns_hcard:mupdate_binary(0, actual_cert_data)

    -- crea gli attributi del certificato
    self:create_file( {
                    size=string.len(attr), 
                    filetype=CnsSmartcard.fileTypes.Binary,
                    parent=hexf(obj.ds_parent_path),
                    fid=fid_attr.asnumber, }, true )
    self.cns_hcard:mupdate_binary(0, attr)
    
    -- update objects list
    ds_publist[freeSlot].usage = IDEMIA_USAGE_USED
    ds_publist[freeSlot].id = hexf(obj.ds_id)
    ds_publist[freeSlot].id_numeric = tonumber(obj.ds_id, 16)
    ds_publist[freeSlot].infos = obj.size
    
    self:write_objlist(true) -- write public list
    
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    
--    if w32.is_smartlogon_cert(Data) then
--        local data_template = {
--            [CKA.TOKEN] = eCK.BBOOL(true),
--            [CKA.CLASS] = eCK.ULONG(CKO.DATA),
--            [CKA.LABEL] = utility.default_container_data_obj,
--            [CKA.APPLICATION] = utility.default_container_data_obj,
--            [CKA.VALUE] = container.id,
--            }
--        self:_delete_by_id(token, nil, CKO.DATA, utility.default_container_data_obj)
--        local ckrv, hDataObj = self:create_object(data_template)
--        log.output("create_object_certificate(): default_container creation result:", ckrv)
--    end

    return CKR.OK, self.attributes.max_index
end


function t.mt:generate_key_pair(pMechanism, templatePubOrig, templatePrivOrig)
    log.output('generate_key_pair()', pMechanism, templatePubOrig, templatePrivOrig)
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
        
    elseif pMechanism.mechanism == CKM.EC_EDWARDS_KEY_PAIR_GEN then
        log.output('generate_key_pair(): generating ECC EDWARDS...')
        return self:generate_key_pair_eddsa(pMechanism, templatePub, templatePriv)
        
    elseif pMechanism.mechanism == CKM.EC_KEY_PAIR_GEN then
        log.output('generate_key_pair(): generating ECC...')
        return self:generate_key_pair_ecc(pMechanism, templatePub, templatePriv)
        
    else
        log.output('generate_key_pair(): MECHANISM_INVALID!')
        return CKR.MECHANISM_INVALID
    end
end

function t.mt:generate_key_pair_rsa(pMechanism, templatePub, templatePriv)

    log.output('generate_key_pair_rsa()', templatePub, templatePriv)
    if self.userType ~= CKU.USER then
        log.output('generate_key_pair_rsa(): not loggen in, userType', self.userType)
        return CKR.USER_NOT_LOGGED_IN
    end

    self:check_clear_cache(nil, true, true)
    
    log.output('generate_key_pair_rsa(): verify_pin_cns() with:', self.cached_main_pin, self.userType)
    if self.cached_main_pin then
        self.cns_hcard:verify_pin_cns(self.cached_main_pin, false, false, self.ds_info.sm_use2_enc, self.ds_info.sm_use2_sig)
    end
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    self:cache_clear()
    
    local objPriv, fid_attr, fid_val

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

    local iscns = self:is_cns(templatePub1)
    local isds = self:is_ds(templatePub1) or self:is_dsx(templatePub1)
    local isdsx = self:is_dsx(templatePub1)
    log.output('generate_key_pair_rsa(): isds:', isds, "isdsx:", isdsx)
    
    if isdsx and not self:is_dsx_licensed() then
        log.output('generate_key_pair_rsa(): DSX objects are not licensed on this card!')
        return CKR.ACTION_PROHIBITED
    end
    
    local cka_modulus_bits = templatePub1[CKA.MODULUS_BITS] or templatePriv1[CKA.MODULUS_BITS] or eCK.ULONG(1024)
    local modulus_bits = 1024    
    if not cka_modulus_bits or cka_modulus_bits == eCK.ULONG(1024) then
        modulus_bits = 1024
    elseif cka_modulus_bits == eCK.ULONG(2048) then
        modulus_bits = 2048
        if iscns then
            log.output('generate_key_pair_rsa(): key size invalid for selected filesystem:', hex.hexify(cka_modulus_bits) )
            return CKR.ATTRIBUTE_VALUE_INVALID
        end
    else
        log.output('generate_key_pair_rsa(): key size invalid for selected filesystem:', hex.hexify(cka_modulus_bits or '') )
        return CKR.ATTRIBUTE_VALUE_INVALID    
    end
 
    if self.ds_info._ignore_ds_opt and modulus_bits > 1024 then
        self:invalidate_xproc_cache()
        log.output('generate_key_pair_rsa(): optimize enabled')
        local rsa = require("rsa")
        local r
        local starttime = os.time()
        
        local transactionDisabled = self.hcard:transactionsdisabled()
        self.hcard:disabletransactions(false)
        if transactionDisabled then
            self.hcard:endtransaction()
        else
            self.cns_hcard:end_transaction()
        end

        for k=1,5 do
            r = nil
            local pcRes, theErrorT  =pcall(function()
                r = {rsa.gen_key(modulus_bits, 65537)}
            end)
            if pcRes then
                break
            end
        end
        
        if transactionDisabled then
            self.hcard:begintransaction()
        else
            self.cns_hcard:begin_transaction()
        end
        self.hcard:disabletransactions(transactionDisabled)

        if not r then
            log.output('generate_key_pair_rsa(): internal error')
            return CKR.FUNCTION_FAILED
        end
        
        log.output('generate_key_pair_rsa(): verify_pin_cns() with:', self.cached_main_pin, self.userType)
        if self.cached_main_pin then
            self.cns_hcard:verify_pin_cns(self.cached_main_pin, false, false, self.ds_info.sm_use2_enc, self.ds_info.sm_use2_sig)
        end
        
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
       
        if os.time() - starttime  < 8 then
            for xx=1,5 do
                self.hcard:status() -- in caso di reset effettua una reconnect
                w32.sleep(1000)
            end
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
    local pubTlv, pubTlvPath
    
    objPriv = objOberthurTmpl.GetDSPrivKeyTemplate(t.mt.get_privkey_ds)
    objPriv.private = true
    objPriv.ds_parent_path = self.ds_info.path_root .. self.ds_df_priv
    objPriv.key_bits = modulus_bits
    
    self:invalidate_xproc_cache()
    
    if iscns then
        if 0 ~= ds_prilist[1].usage then
            log.output('generate_key_pair_rsa(): CNS Private Key already exists')
            return CKR.DEVICE_MEMORY
        end
        freeId, freeSlot = 1, 1 -- todo: free slot dovrebbe essere cercato da 1 a 3
        objPriv.ds_id = '3001'  -- fid DS
        objPriv.path = '3F00'   --path in cui si trova il BSO
        objPriv.pso_dec = true
        objPriv.kid = 1
        fid_attr = bin.flags('0x3101')
        pubTlv = hex.hexf('3f01')
        pubTlvPath = hex.hexf('3f003f01')
    else
        if isds then
            freeId = oberthur_util.look_for_free_id2(oberthur_util.objFIDS.ePrivKey, oberthur_util.objFIDS.ePrivECC, ds_prilist, 2, 1)
            objPriv.pso_dec = isdsx
            objPriv.pso_dec_sm = isdsx
            
            if freeId > 11 then
                log.output('generate_key_pair_rsa(): no more DS space available, freeId:', freeId)
                freeId = nil
            end
            templatePriv1[CKA.DECRYPT] = eCK.BBOOL(false)
        else
            freeId = oberthur_util.look_for_free_id(oberthur_util.objFIDS.ePrivKey, ds_prilist, 12, 1)
            objPriv.pso_dec = true
        end

        local freeSlots = oberthur_util.look_for_free_slots(ds_prilist, 1, 2)
        
        if freeId == nil or freeId > 27 or table.getn(freeSlots) == 0 then
            log.output('generate_key_pair_rsa(): no more space available, freeId:', freeId, 'freeSlots:', repr(freeSlots))
            return CKR.DEVICE_MEMORY
        end
        freeSlot = freeSlots[1]
        fid_val = oberthur_util.objFIDS.ePrivKey + bin.flags(freeId)
        fid_attr = fid_val + bin.flags('0x100')
        objPriv.ds_id = hex.hexify(hex.hexf("%H",  fid_val.asnumber) ) -- fid DS
        objPriv.path = objPriv.ds_parent_path -- path in cui si trova il BSO
        objPriv.kid = freeId
        
        pubTlv = hex.hexf('3200')
        pubTlvPath = hex.hexf(objPriv.ds_parent_path .. '3200')
    end
    objPriv.num = freeId
    objPriv.slot = freeSlot

    if not iscns then
        -- crea / aggiorna il BSO
        self.cns_hcard:select(hexf(objPriv.ds_parent_path))
        
        if isds and self.cfg["dspiniscnspin"]=='true' and not self.ds_info._ignore_ds_pin then
            log.output('generate_key_pair_rsa(): using main pin as DS pin...')
            self.cns_hcard:verify_pin_ds(self.cached_main_pin, self.ds_info.sm_use_enc, self.ds_info.sm_use_sig)
        end
        
        log.output('updating RSA bso:', objPriv.kid)
        self:create_rsa_bso(objPriv.kid, nil, nil, modulus_bits, isds, true, isdsx)
        -- crea il file temporaneo TLV per la generazione della coppia di chiavi
        log.output('creating file:', hex.hexify(pubTlv))
        self:create_file( { size=280,
                            filetype=CnsSmartcard.fileTypes.RecordTLV,
                            parent=hexf(objPriv.ds_parent_path),
                            fid=pubTlv, 
                            aac={read=0, update=0, delete=0, append=0, admin=0, ac8=0, ac9=0, ac4=0, ac5=0},
                           }, true )
    else
        self.cns_hcard:select(nil) -- select MF
    end

    self.cns_hcard:generate_key_pair(objPriv.kid, pubTlv, 0 )
    local modulus, pubexp =  self.cns_hcard:read_public_key(pubTlvPath)
    templatePub1[CKA.MODULUS] = modulus
    templatePub1[CKA.PUBLIC_EXPONENT] = pubexp
    templatePriv1[CKA.MODULUS] = modulus
    templatePriv1[CKA.PUBLIC_EXPONENT] = pubexp
    templatePriv1[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(isds)
    
    if not iscns then
        --pcall(function()
            self.cns_hcard:select(hexf(objPriv.ds_parent_path))
            self.cns_hcard:delete_file(pubTlv)
        --end)
    end
    
    templatePub1[CKA.CLASS] = eCK.ULONG(CKO.PUBLIC_KEY)
    templatePub1[CKA.KEY_TYPE] = eCK.ULONG(CKK.RSA)
    attr = oberthur_util.serialize_attr_privkey(templatePriv1)
    
    -- crea gli attributi della chiave privata
    self:create_file( {
                    size=string.len(attr), 
                    filetype=CnsSmartcard.fileTypes.Binary,
                    parent=hexf(objPriv.ds_parent_path),
                    fid=fid_attr.asnumber, }, false)
    self.cns_hcard:mupdate_binary(0, attr)
    
    -- update objects list
    ds_prilist[freeSlot].usage = objPriv.pso_dec_sm and IDEMIA_USAGE_USED2 or IDEMIA_USAGE_USED
    ds_prilist[freeSlot].id = hexf(objPriv.ds_id)
    ds_prilist[freeSlot].id_numeric = tonumber(objPriv.ds_id, 16)
    ds_prilist[freeSlot].infos = objPriv.key_bits
    
    self:write_objlist(false) -- write private list

    -- adds new handle to the list
    local hPrivk
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPriv
    hPrivk = self.attributes.max_index
    
    local rv, hPubk = self:create_object_pubkey(templatePub1, true)
    log.output('create_object(pubkey): result:', rv, 'handle:', hPubk)
    
    log.output('generate_key_pair_rsa(): success, returning', hPubk, hPrivk)
    if rv == CRK_OK then
        self:update_free_mem(self.info)
    end
    self:update_cache_id()
    return CKR.OK, hPubk, hPrivk
end


function t.mt:create_object_data(pTemplate)
    log.output('create_object_data()', pTemplate)
    if self.userType ~= CKU.USER then
        log.output('create_object_data(): USER_NOT_LOGGED_IN')
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    local dataValue = pTemplate[CKA.VALUE] or ''
    local fileLen = (pTemplate[CKA.VALUE] and string.len(dataValue)) or 1
    local ispdata = self:is_pdata(pTemplate)
    
    local freeId, freeSlot
    local attr = oberthur_util.serialize_attr_data(pTemplate)
    local fid_val, fid_attr
    local objectType = oberthur_util.objFIDS.eData
    local ds_objlist = self.ds_info.ds_publist
    local startId, startSlot = 2, 4
    obj = objOberthurTmpl.GetDSDataTemplate(t.mt.get_data_ds)
    obj.private = (not ispdata and oberthur_util.is_ck_true(pTemplate[CKA.PRIVATE]))
    if obj.private then
        obj.ds_parent_path = self.ds_info.path_root .. self.ds_df_priv
        objectType = oberthur_util.objFIDS.eDataP
        ds_objlist = self.ds_info.ds_prilist
        startId, startSlot = 2, 2
    else
        obj.ds_parent_path = self.ds_info.path_root .. self.ds_df_pub
    end
    obj.size = string.len(dataValue)
    if ispdata then
        if 0 ~= ds_objlist[1].usage then
            log.output('create_object_data(): CNS PDATA already exists')
            return CKR.FUNCTION_FAILED
        end
        freeId, freeSlot = 1, 1 -- todo: free slot dovrebbe essere cercato da 1 a 3
        obj.ds_id = '5001'         -- fid DS
        obj.path = '3f0011001102'  -- path reale del file PDATA
        fid_attr = bin.flags('0x5101')
    else
        -- cerca a partire da id 2 e slot 4
        freeId = oberthur_util.look_for_free_id(objectType, ds_objlist, startId, 1)
        local freeSlots = oberthur_util.look_for_free_slots(ds_objlist, 1, startSlot)
        
        if freeId == nil or table.getn(freeSlots) == 0 then
            log.output('create_object_data(): no more space available')
            return CKR.DEVICE_MEMORY
        end
        freeSlot = freeSlots[1]
        fid_val = objectType + bin.flags(freeId)
        fid_attr = fid_val + bin.flags('0x100')
        obj.ds_id = string.format('%04X', fid_val.asnumber )  -- fid DS
        obj.path = obj.ds_parent_path .. string.format('%04X', fid_val.asnumber ) -- path reale del file binario del data object
    end
    obj.num = freeId
    obj.slot = freeSlot
    
    if not ispdata then
        -- crea il file del data object non CNS
        self:create_file( {
                        size=fileLen, 
                        filetype=CnsSmartcard.fileTypes.Binary,
                        parent=hexf(obj.ds_parent_path),
                        fid=fid_val.asnumber, }, not obj.private)
    else
        self.cns_hcard:select(hex.hexf(obj.path))
    end
    
    -- scrive il certificato
    if dataValue == '' and fileLen == 1 then
        self.cns_hcard:update_binary(0, '\255') -- empty data object, fill with dummy 1 byte
    else
        self.cns_hcard:mupdate_binary(0, dataValue)
    end

    -- crea gli attributi del data file
    self:create_file( {
                    size=string.len(attr), 
                    filetype=CnsSmartcard.fileTypes.Binary,
                    parent=hexf(obj.ds_parent_path),
                    fid=fid_attr.asnumber, }, true )
    self.cns_hcard:mupdate_binary(0, attr)
    
    -- update objects list
    ds_objlist[freeSlot].usage = IDEMIA_USAGE_USED
    ds_objlist[freeSlot].id = hexf(obj.ds_id)
    ds_objlist[freeSlot].id_numeric = tonumber(obj.ds_id, 16)
    if obj.size >0 then
        ds_objlist[freeSlot].infos = tonumber('ffff', 16)  -- ffff indica che ci sono dati
    else
        ds_objlist[freeSlot].infos = 0
    end
    
    self:write_objlist(not obj.private) -- write public list
    
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    return CKR.OK, self.attributes.max_index
end


function t.mt:create_object_pin_policy(pTemplate)
    if self.userType ~= CKU.SO then
        log.output('create_object_pin_policy(): user type not SO')
        return CKR.USER_TYPE_INVALID
    end
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local fids_parent = hexf(self.ds_info.path_root .. self.ds_df_pub)
    local fid_main = tonumber("FFF0", 16)
    local fid_pin = tonumber("FFF1", 16)
    local all_fids = {fid_main, fid_pin}
    
    if not pTemplate[CKA.VALUE] or string.sub(pTemplate[CKA.VALUE], 1, 5) == string.rep("\0", 5) then
        log.output('create_object_pin_policy(): erasing PIN policy')
        for i=1,table.getn(all_fids) do
            pcall(function()
                self.cns_hcard:select(fids_parent)
                self.cns_hcard:delete_file(all_fids[i])
            end)
        end
        self.attributes[1] = nil
        return CKR.OK, 0
    end
    
    local attr = string.sub(pTemplate[CKA.VALUE], 1, 10)
    attr = attr .. string.rep("\0", 10- string.len(attr))
    log.output('create_object_pin_policy(): setting new pin policy:', hex.hexify(attr) )
    
    self:create_file ({
        fid = fid_main,
        size=string.len(attr),
        filetype=CnsSmartcard.fileTypes.Binary,
        parent=fids_parent,
        aac={read = 0,
            update = self.cns_hcard.BSO_CNS_PUK,
            append = self.cns_hcard.BSO_CNS_PUK,
            delete = 0,
        },
    }, true, true);
    
    self.cns_hcard:mupdate_binary(0, attr)
    
    self:init_pin_policy(attr)
    
    if self.pinHistory and self.pinHistory > 0 then
        self:create_file ({
            fid = fid_pin,
            size=20 * self.pinHistory,
            filetype=CnsSmartcard.fileTypes.Binary,
            parent=fids_parent,
            aac={read = self.cns_hcard.BSO_CNS_PIN,
                update = self.cns_hcard.BSO_CNS_PIN,
                append = self.cns_hcard.BSO_CNS_PIN,
                delete = 0,
            },
        }, true, true);
    else
        pcall(function()
            self.cns_hcard:select(fids_parent)
            self.cns_hcard:delete_file(fid_pin)
        end)
    end
    
    if self.pinRetry > 0 then
        log.output('create_object_pin_policy(): recreating PIN')
        self.cns_hcard:select(hexf('3F00'))
        local apdu = hex.hexf("00da016e17830200%B850802%B87%Bffff0008860700%B%B%B%B%B00", 
            self.cns_hcard.BSO_CNS_PIN,
            self.pinRetry, self.pinRetry,
            self.cns_hcard.BSO_CNS_PIN, self.cns_hcard.BSO_CNS_PUK, self.cns_hcard.BSO_CNS_PUK, self.cns_hcard.BSO_CNS_PUK, self.cns_hcard.BSO_CNS_PUK)
        local recv = self.cns_hcard:transmit(apdu)
        sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            log.output('create_object(): error changing PIN retry counter')
        end
    end
    
    obj = {[CKA.CLASS]=eCK.ULONG(CKO_PIN_POLICY), [CKA.TOKEN]=eCK.BBOOL(true), [CKA.VALUE]=self.pin_policy_value}
    self.attributes[1] = obj
    return CKR.OK, 1
end

function t.mt:create_object(pTemplateOrig)
    log.output('create_object(): verify_pin_cns() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.cns_hcard:verify_pin_cns(self.cached_main_pin, false, false, self.ds_info.sm_use2_enc, self.ds_info.sm_use2_sig)
    end
    local rv, hObj
    
    local pTemplate = utility.clone_table(pTemplateOrig)
    
    
    pTemplate[CKA.DESTROYABLE] = pTemplate[CKA.DESTROYABLE] or eCK.BBOOL(true) -- defaults to true
    
    self:check_clear_cache(nil, true, true)
    
    self:invalidate_xproc_cache()
    self:cache_clear()
    
    if pTemplate[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
    
        if pTemplate[CKA.KEY_TYPE] == eCK.ULONG(CKK.ECDSA) then

            if not self.mechanisms[CKM.EC_KEY_PAIR_GEN] then
                log.output('create_object(): ECDSA obejct not supported')
                return CKR.ATTRIBUTE_VALUE_INVALID
            end

            rv, hObj = self:create_object_ecc_pubkey(pTemplate)
        elseif pTemplate[CKA.KEY_TYPE] == eCK.ULONG(CKK.EC_EDWARDS) then
        
            if not self.mechanisms[CKM.EC_EDWARDS_KEY_PAIR_GEN] then
                log.output('create_object(): EDDSA obejct not supported')
                return CKR.ATTRIBUTE_VALUE_INVALID
            end
            
            rv, hObj = self:create_object_eddsa_pubkey(pTemplate)
        else
            rv, hObj = self:create_object_pubkey(pTemplate)
        end
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
    
        if pTemplate[CKA.KEY_TYPE] == eCK.ULONG(CKK.ECDSA) then

            if not self.mechanisms[CKM.EC_KEY_PAIR_GEN] then
                log.output('create_object(): ECDSA obejct not supported')
                return CKR.ATTRIBUTE_VALUE_INVALID
            end
            
            rv, hObj = self:create_object_ecc_privkey(pTemplate)
        elseif pTemplate[CKA.KEY_TYPE] == eCK.ULONG(CKK.EC_EDWARDS) then
        
            if not self.mechanisms[CKM.EC_EDWARDS_KEY_PAIR_GEN] then
                log.output('create_object(): EDDSA obejct not supported')
                return CKR.ATTRIBUTE_VALUE_INVALID
            end
            
            rv, hObj = self:create_object_eddsa_privkey(pTemplate)
        else
            rv, hObj = self:create_object_privkey(pTemplate)
        end
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.SECRET_KEY) then
        if pTemplate[CKA.KEY_TYPE] == eCK.ULONG(CKK.AES) then
    
            if not self.mechanisms[CKM.AES_KEY_GEN] then
                log.output('create_object(): AES obejct not supported')
                return CKR.ATTRIBUTE_VALUE_INVALID
            end
            
            rv, hObj = self:create_object_secret_key(pTemplate)
        else
            log.output('create_object(): unsupported secret key type:', hex.hexify(pTemplate[CKA.KEY_TYPE] or ''))
            return CKR.ATTRIBUTE_VALUE_INVALID
        end
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        rv, hObj = self:create_object_certificate(pTemplate)
        
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
        self:update_free_mem(self.info)
    end
    return rv, hObj
end

function t.mt:destroy_object(hObject)
    log.output('destroy_object(): ', hObject)
    local pcRes, theErrorT
    log.output('destroy_object(): verify_pin_cns() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.cns_hcard:verify_pin_cns(self.cached_main_pin, false, false, self.ds_info.sm_use2_enc, self.ds_info.sm_use2_sig)
    end

    self:check_clear_cache(nil, true, true)
    
    if self.userType ~= CKU.USER then
        log.output('destroy_object(): USER_NOT_LOGGED_IN')
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local obj = self.attributes[hObject]
    local ds_objlist = self.ds_info.ds_publist
    if obj == nil then
        log.output('destroy_object(): specified handle invalid: ', hObject)
        return CKR.OBJECT_HANDLE_INVALID
    end

    if obj.private then ds_objlist = self.ds_info.ds_prilist end
    
    local fid_val = hexf(obj.ds_id)
    local fid_attr = hexf('%H', (bin.flags( tonumber(obj.ds_id, 16)) + bin.flags('0x100')).asnumber )
    
    local step1_ok = true -- default e' true, per gli oggetti che non necessitano di step1
    
    self:invalidate_xproc_cache()
    self:cache_clear()
    
    if type(obj[CKA.DESTROYABLE]) == "function" then
        obj[CKA.DESTROYABLE](self, hObject, CKA.DESTROYABLE, false)
    end
    local destroyable = type(obj[CKA.DESTROYABLE]) == "string" and hex.hexify(obj[CKA.DESTROYABLE]) or obj[CKA.DESTROYABLE]
    
    log.output('destroy_object(): CKA.DESTROYABLE:', destroyable)
    if type(obj[CKA.DESTROYABLE]) ~= "function" and obj[CKA.DESTROYABLE] ~= nil and not oberthur_util.is_ck_true(obj[CKA.DESTROYABLE]) then
        log.output('destroy_object(): ERROR: object is read only?')
        return CKR.TOKEN_WRITE_PROTECTED
    end
    
    if obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        if obj.num == 1 then
            if self._cns_read_only then
                log.output('destroy_object(): CNS certificate read only!')
                return CKR.TOKEN_WRITE_PROTECTED
            end
            step1_ok = false
            log.output('destroy_object(): overwriting CNS certificate: ', obj.path)
            pcall(function()
                self.cns_hcard:select(hexf(obj.path))
                self.cns_hcard:update_binary(0, string.rep('\000', 16) )
                step1_ok = true
            end)
        end
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        if obj.num == 1 then
            if self._cns_read_only then
                log.output('destroy_object(): CNS pub key read only!')
                return CKR.TOKEN_WRITE_PROTECTED
            end
            step1_ok = false
            log.output('destroy_object(): overwriting CNS PubKey: ', obj.path)
            pcall(function()
                self.cns_hcard:select(hexf(obj.path))
                self.cns_hcard:update_record(1, 4, hexf('1000'))
                self.cns_hcard:update_record(2, 4, hexf('1100'))
                step1_ok=true
            end)
        end
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        if obj.num == 1 then
            if self._cns_read_only then
                log.output('destroy_object(): CNS priv key read only!')
                return CKR.TOKEN_WRITE_PROTECTED
            end
            step1_ok = false
            pcall(function()
                -- solamente se la chiave pubblica 