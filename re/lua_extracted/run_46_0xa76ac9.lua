 stato effettuato il login
                local obj = objP11Tmpl.GetP11PrivKeyTemplate(t.mt.get_privkey_p11)
                obj.isp11 = true
                obj.private = true
                obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
                obj.num = k
                obj.path = self.p11_info.path_root
                obj.parent_path = obj.path
                obj.kid = t.mt.get_privkey_p11
                obj.key_bits = t.mt.get_privkey_p11
                obj.pso_dec = true -- usa la modalita' enc_dec per effettuare la firma; supporta la decifra
                objects.max_index = objects.max_index+1
                objects[objects.max_index] = obj
                log.output('add_p11_objects(): added  private key on position', k,
                            'handle', objects.max_index, 
                            'path:', obj.path)
            elseif pcall(function() 
                            return self:select_with_cache(
                                hexf(self.p11_info.path_root..'%H',self:buildP11Fid(k, objTypes.ePubKey, attrTypes.eMain)) 
                                ) end
                            ) then
                -- chiave pubblica
                local obj = objP11Tmpl.GetP11PubKeyTemplate(t.mt.get_pubkey_p11)
                obj.isp11 = true
                obj.num = k
                obj.parent_path = self.p11_info.path_root
                obj.path = hex.hexify(hexf(obj.parent_path .. '%H', self:buildP11Fid(k, objTypes.ePubKey, attrTypes.ePubKeyModExp) ) )
                obj.key_bits = t.mt.get_pubkey_p11
                objects.max_index = objects.max_index+1
                objects[objects.max_index] = obj
                log.output('add_p11_objects(): added public key on position', k, 
                            'handle', objects.max_index, 
                            'path:', obj.path)
            elseif pcall(function() 
                            return self:select_with_cache(
                                hexf(self.p11_info.path_root..'%H',self:buildP11Fid(k, objTypes.eData, attrTypes.eMain)) 
                                ) end
                            ) then
                -- data object
                local obj = objP11Tmpl.GetP11DataTemplate(t.mt.get_data_p11)
                obj.isp11 = true
                obj.num = k
                obj.parent_path = self.p11_info.path_root
                obj.path = hex.hexify(hexf(obj.parent_path .. '%H', self:buildP11Fid(k, objTypes.eData, attrTypes.eValue) ) )
                objects.max_index = objects.max_index+1
                objects[objects.max_index] = obj
                obj.private = false
                pcall(function()
                    log.output("detecting data object private flag...")
                    local info = self.cns_hcard:select(
                            hexf(self.p11_info.path_root..'%H',self:buildP11Fid(k, objTypes.eData, attrTypes.eValue) ),
                            true )
                    obj.private = string.byte(info.ac, 1) ~= 0
                    log.output("data object is private: ", tostring(obj.private) )
                end)
                obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
                log.output('add_p11_objects(): added data object on position', k, 
                            'handle', objects.max_index, 
                            'path:', obj.path)
            else
                log.output('add_p11_objects(): main file not found, object type not supported! Index:', k)
            end -- serie di select per verificate  tipo di oggetto
        end -- oggetto corrente attivo
    end -- for, ciclo sulla object table
    
    self.cns_hcard.use_0c_flag=use_0c_flag
end

function t.mt:add_ds_objects(objects)
    -- oggetti DS; l'applicazione puo' non esistere;  gli oggetti possono non essere presenti
    local info = self:get_info() -- carica le info sul filesystem in cache
    if (self.ds_info ~= nil and self.ds_info.ds_objects ~= nil) then
    
        log.output('token-cns:add_ds_objects(): adding DS objects!...')
        local ds_first_handle = objects.max_index+1
        
        local objectGroups = {
            {key_bits=1024, objects = self.ds_info.ds_objects.o1024},
            {key_bits=2048, objects = self.ds_info.ds_objects.o2048},
        }
        local cur_object_idx = 0
        local cur_object_id_hex = ""
        for k, oGroup in objectGroups do
            for i, objState in oGroup.objects do
                cur_object_id_hex = hex.hexify(hex.hexf("%B", 16 + cur_object_idx))
                if objState[3] == 1 then
                    objects.max_index = ds_first_handle + (cur_object_idx*3)
                    local obj = objCnsTmpl.GetDSCertTemplate(t.mt.get_certificate, cur_object_idx)
                    obj.num = cur_object_idx
                    obj.path = self.ds_info.path_root .. '90' .. cur_object_id_hex
                    objects[ objects.max_index ] = obj
                    log.output('token-cns:add_ds_objects(): added certificate:', 
                        objects.max_index, 
                        hex.hexify(objects[ objects.max_index ][CKA.CLASS]))
                end
                if objState[1] == 1 then
                    objects.max_index = ds_first_handle + (cur_object_idx*3) +1
                    local obj = objCnsTmpl.GetDSPrivKeyTemplate(t.mt.get_public_key, cur_object_idx)
                    obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(self.ds_info.alw_verify_pin)
                    obj.num = cur_object_idx
                    obj.path = self.ds_info.ds_sig_path
                    obj.kid = '1' .. cur_object_idx
                    obj.pso_dec = false -- usa PSO_CDS per la firma e non supporta la decifra
                    obj.related_public_key = self.ds_info.ds_sig_path .. '80' .. cur_object_id_hex
                    obj.key_bits = oGroup.key_bits
                    obj.private=true
                    obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
                    objects[ objects.max_index] = obj
                    log.output('token-cns:add_ds_objects(): added private key:', 
                        objects.max_index, 
                        hex.hexify(objects[ objects.max_index ][CKA.CLASS]))
                end
                
                if objState[2] == 1 then
                    objects.max_index = ds_first_handle + (cur_object_idx*3) +2
                    local obj = objCnsTmpl.GetDSPubKeyTemplate(t.mt.get_public_key, cur_object_idx)
                    obj.num = cur_object_idx
                    obj.path = self.ds_info.ds_sig_path .. '80' .. cur_object_id_hex
                    obj.key_bits = oGroup.key_bits
                    objects[ objects.max_index] = obj
                    log.output('token-cns:add_ds_objects(): added public key:', 
                        objects.max_index, 
                        hex.hexify(objects[ objects.max_index ][CKA.CLASS]))
                end
                cur_object_idx = cur_object_idx+1
            end
        end
    else
        log.output('add_ds_objects(): invalid FS!')
    end -- end raccolta degli oggetti DS
end

function t.mt:add_cns_objects(objects)
    local obj
    log.output('token-cns:add_cns_objects(): adding CNS objects...')
    if self.cns_info ~= nil then
        if self.cns_info.cert_valid then
            log.output('token-cns:add_cns_objects(): adding CNS Certificate...')
            obj = objCnsTmpl.GetCNSCertTemplate(t.mt.get_certificate)
            obj.iscns=true
            objects.max_index = objects.max_index+1
            objects[ objects.max_index ] = obj
            log.output('token-cns:add_cns_objects(): added certificate:',
                objects.max_index,
                hex.hexify(obj[CKA.CLASS]))
            self.cns_info.cert_handle = objects.max_index
        end
        if self.cns_info.pdata_valid then
            log.output('token-cns:add_cns_objects(): adding PDATA')
            obj = objCnsTmpl.GetCNSPDATATemplate(t.mt.get_pdata)
            obj.iscns=true
            objects.max_index = objects.max_index+1
            objects[ objects.max_index ] = obj
            log.output('token-cns:add_cns_objects(): added PDATA:',
                objects.max_index,
                hex.hexify(obj[CKA.CLASS]))
            self.cns_info.cert_handle = objects.max_index
        end
        if self.cns_info.key_valid then
            log.output('token-cns:add_cns_objects(): adding CNS Pub and Priv keys...')
            
            objects.max_index = objects.max_index+1
            local objPub = objCnsTmpl.GetCNSPubKeyTemplate(t.mt.get_public_key)
            objPub.iscns = true
            objPub.path = self.cns_info.cns_key_prefix .. objPub.path
            objPub.key_bits = self.cns_info.modulus and (string.len(self.cns_info.modulus)*8) or 1024
            objects[ objects.max_index ] = objPub
            log.output('token-cns:add_cns_objects(): added pub key:',
                objects.max_index,
                hex.hexify(objPub[CKA.CLASS]))
            self.cns_info.pub_key_handle = objects.max_index
            
            objects.max_index = objects.max_index+1
            local objPriv = objCnsTmpl.GetCNSPrivKeyTemplate(t.mt.get_public_key)
            objPriv.iscns = true
			objPriv.related_public_key = objPub.path
            objPriv.path = self.cns_info.cns_key_prefix ..objPriv.path
            objPriv.private=true
            objPriv.key_bits = objPub.key_bits
            objPriv[CKA.PRIVATE] = eCK.BBOOL(objPriv.private)
            objects[ objects.max_index ] = objPriv
            log.output('token-cns:add_cns_objects(): added priv key:',
                objects.max_index,
                hex.hexify(objPriv[CKA.CLASS]))
            self.cns_info.priv_key_handle = objects.max_index
            
            if self.cns_info.modulus and self.cns_info.pubexp then
                objPub[CKA.MODULUS] = self.cns_info.modulus
                objPub[CKA.PUBLIC_EXPONENT] = self.cns_info.pubexp
                objPriv[CKA.MODULUS] = objPub[CKA.MODULUS]
                objPriv[CKA.PUBLIC_EXPONENT] = objPub[CKA.PUBLIC_EXPONENT]
            end
        end
    else
        log.output('add_cns_objects(): invalid FS!')
    end
end

function t.mt:get_objects()

    log.output('token-cns:get_objects()')
    local info = self:get_info() -- carica le info sul filesystem in cache
    
    local objects = {
            min_index = 11001, -- primo indice disponibile
            max_index = 11000, -- valore dell'indice massimo (i valori intermedi possono anche essere nil)
        }

    self:add_cns_objects(objects)
    self:add_ds_objects(objects)
    self:add_dsx_objects(objects)
    self:add_p11_objects(objects)

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
    
    if not obj.populated and attr == -1 then
        for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
            local result = obj[k]
            if type(result)=='function' then
                result(self, hobj, attr, onlysize)
                break
            end
        end
    end
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
    
    if type(result) ~= 'string' then
        log.output("get_attribute_value(): ERROR: attr still not valid:", type(result), hobj, utility.CKA_NAMES[attr or -1], attr)
        return CKR.ATTRIBUTE_TYPE_INVALID
    end    
    if onlysize and type(result)=='string' then
        return CKR.OK, string.len(result)
    else
        return CKR.OK, result
    end
end

function t.mt:valid()
    local rv = self.cns_hcard:valid()
    if not rv then
        utility.forget_token_changed(self, "cache")
    end
    return rv
end


function t.mt:get_object_size(hobj)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj == nil then return CKR.OBJECT_HANDLE_INVALID end
    local oSize = -1
    
    if obj.iscns then
        if obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
            oSize = 400
        elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
            oSize = 130*2
        elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
            oSize = 300
        elseif obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
            oSize = 2048
        end       
    elseif obj.isp11 then
        self:get_attribute_value(hobj, -1)
        if obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
            -- approssimativa
            local rv, value = self:get_attribute_value(hobj, CKA.VALUE)
            local rv, application = self:get_attribute_value(hobj, CKA.OBJECT_ID)
            local rv, object_id = self:get_attribute_value(hobj, CKA.APPLICATION)
            oSize = 32 + string.len(value or '') + string.len(application or '') + string.len(object_id or '')
        elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
            -- approssimativa
            local pubSize = (obj.key_bits/8)*2 + 10
            local privSize = (obj.key_bits/8)*2
            if obj.key_bits > 1024 then
                pubSize = 256 +8
                privSize = (obj.key_bits/8) + (obj.key_bits/16)*3 + 8
            end
            oSize = 32 + pubSize + privSize + 64
        elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
            -- approssimativa
            local pubSize = (obj.key_bits/8)*2 + 32
            if obj.key_bits > 1024 then
                pubSize = 256 +8
            end
            oSize = 32 + pubSize + 64
        elseif obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
            -- approssimativa
            local rv, value = self:get_attribute_value(hobj, CKA.VALUE)
            local rv, subject = self:get_attribute_value(hobj, CKA.SUBJECT)
            local rv, issuer = self:get_attribute_value(hobj, CKA.ISSUER)
            local rv, serial_number = self:get_attribute_value(hobj, CKA.SERIAL_NUMBER)
            oSize = 32 + string.len(value or '') + string.len(subject or '') + string.len(issuer or '') + string.len(serial_number or '')
        end
    end
    
    return CKR.OK, oSize
end




------------------------------------------------------------------------
--- R/W code -----------------------------------------------------------
------------------------------------------------------------------------










function t.mt:is_cns(pTemplate)
    return self.cns_info
            and pTemplate[CKA.CLASS] ~= eCK.ULONG(CKO.DATA) 
            and (pTemplate[CKA.ID] == OBJ_IDS.CNS0_ID or pTemplate[CKA.LABEL] == OBJ_IDS.CNS0_LABEL)
end

function t.mt:is_pdata(pTemplate)
    return self.cns_info
            and pTemplate[CKA.CLASS] == eCK.ULONG(CKO.DATA)
            and (pTemplate[CKA.LABEL] == OBJ_IDS.PDATA_LABEL or pTemplate[CKA.APPLICATION] == OBJ_IDS.PDATA_LABEL)
end

function t.mt:is_dsx_licensed()
    return (self._license_valid and type(self._license_valid.dsx) == "number" and self._license_valid.dsx > 0)
            or (self.ds_info and self.ds_info.dsx)
end


function t.mt:is_dsx(pTemplate)
    if not self.jsign_2048 or not self.ds_info then
        return false
    end
    
    local DSX_ID_len = string.len(OBJ_IDS.DSX_ID)
    local DSX_LABEL_len = string.len(OBJ_IDS.DSX_LABEL)
    if string.sub(pTemplate[CKA.ID] or '', 1, DSX_ID_len) == OBJ_IDS.DSX_ID then
        return true
    elseif string.sub(pTemplate[CKA.LABEL] or '', 1, DSX_LABEL_len) == OBJ_IDS.DSX_LABEL then
        return true
    end
    return false
end



function t.mt:is_ds(pTemplate, cka_modulus_bits, check_availability)
    if not self.ds_info then
        return false
    end
    
    local res, slot_id = false, -1
    local DS_ID_len = string.len(OBJ_IDS.DS_ID)
    local DS_LABEL_len = string.len(OBJ_IDS.DS_LABEL)
    if string.sub(pTemplate[CKA.ID] or '', 1, DS_ID_len) == OBJ_IDS.DS_ID then
        slot_id = tonumber(string.sub(pTemplate[CKA.ID], DS_ID_len+1, -1))
        res = type(slot_id) == 'number' or pTemplate[CKA.ID] == OBJ_IDS.DS_ID
    elseif string.sub(pTemplate[CKA.LABEL] or '', 1, DS_LABEL_len) == OBJ_IDS.DS_LABEL then
        slot_id = tonumber(string.sub(pTemplate[CKA.LABEL], DS_ID_len+1, -1))
        res = type(slot_id) == 'number' or pTemplate[CKA.LABEL] == OBJ_IDS.DS_LABEL
    end
    
    log.output('is_ds(): parsing result: res:', res, 'slot_id:', slot_id)
    if res and slot_id and slot_id > self.ds_info.ds_objects.DS_MAX_INDEX then
        log.output(string.format(
                        'is_ds(): parsed slot index overflow: max:%d, got:%d', 
                        self.ds_info.ds_objects.DS_MAX_INDEX, slot_id) )
        log.output('is_ds(): returning: true, -1')
        return true, -1
    end
    
    if pTemplate[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) 
            and not cka_modulus_bits and pTemplate[CKA.VALUE] then
        local cert_parsed
        pcall(function() cert_parsed = der.parse_x509cer(pTemplate[CKA.VALUE]) end)
        if cert_parsed and type(cert_parsed.modulus) == "string" then
            cka_modulus_bits = eCK.ULONG(string.len(cert_parsed.modulus) * 8)
            log.output('is_ds(): certificate bits:', string.len(cert_parsed.modulus) * 8)
        end
    end
    
    local subindex = 1
    if pTemplate[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        subindex = 3
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        subindex = 2
    end
    local oGroup = self.ds_info.ds_objects.o1024
    local index_base = 0
    if cka_modulus_bits == eCK.ULONG(2048) then
        oGroup = self.ds_info.ds_objects.o2048
        index_base = table.getn(self.ds_info.ds_objects.o1024)
    end
    
    if res and slot_id then
        local max_1024_slot_id = table.getn(self.ds_info.ds_objects.o1024)
        if cka_modulus_bits == eCK.ULONG(1024) then
            if slot_id >= max_1024_slot_id then
                log.output(string.format('is_ds(): 1024 bit parsed slot index overflow: max:%d, got:%d', max_1024_slot_id, slot_id))
                return true, -1
            end
            if check_availability and self.ds_info.ds_objects.o1024[slot_id+1][subindex] ~= 0 then
                log.output('is_ds(): 1024 bit parsed slot index not available!')
                return true, -1
            end
        elseif cka_modulus_bits == eCK.ULONG(2048) then
            if slot_id < max_1024_slot_id then
                log.output(string.format('is_ds(): 2048 bit parsed slot index underflow: min:%d, got:%d', max_1024_slot_id+1, slot_id))
                return true, -1
            end
            if check_availability and self.ds_info.ds_objects.o2048[slot_id-max_1024_slot_id+1][subindex] ~= 0 then
                log.output('is_ds(): 2048 bit parsed slot index not available!')
                return true, -1
            end
        end
        log.output('is_ds(): returning: true,', slot_id)
        return true, slot_id
    end
    
    if res then
        log.output('is_ds(): looking for a free slot...')
        
        for i=1, table.getn(oGroup) do
            if oGroup[i][subindex] == 0 then
                slot_id = index_base + i -1
                log.output('is_ds(): found available slot id: ', slot_id)
                break
            end
        end
    end
    if not slot_id then
        slot_id = -1
    end
    log.output('is_ds(): DS slot search result: res:', res, 'slot_id:', slot_id)
    return res, slot_id
end

function t.mt:create_file(finfo, is_public, delete)
    local finfo1 = utility.clone_table(finfo)
    if delete == nil then delete = true end
    if not finfo1.aac then finfo1.aac = {} end
    if is_public then
        if not finfo1.aac.read then finfo1.aac.read=0 end
        if not finfo1.aac.update then finfo1.aac.update=0 end
        if not finfo1.aac.append then finfo1.aac.append=0 end
        if not finfo1.aac.delete then finfo1.aac.delete=0 end
    else
        if not finfo1.aac.read then finfo1.aac.read=0 end
        if not finfo1.aac.update then finfo1.aac.update=self.cns_hcard.BSO_CNS_PIN end
        if not finfo1.aac.append then finfo1.aac.append=self.cns_hcard.BSO_CNS_PIN end
        if not finfo1.aac.delete then finfo1.aac.delete=self.cns_hcard.BSO_CNS_PIN end       
    end
    self.cns_hcard:create_file(finfo1, delete)
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

function t.mt:look_for_free_slots(num)
    local rlist = {}
    local obj_table = self.p11_info.obj_table
    for i=0,63 do
        if not obj_table[i] then
            table.insert(rlist, i)
            if (table.getn(rlist) >= num) then
                break
            end
        end
    end
    if table.getn(rlist) < num then
        return nil
    end
    return rlist
end

function t.mt:look_for_free_bso(is2048)
    local bso_t, count
    if is2048 then
        bso_t = self.p11_info.bso2048_table
        count = 8
    else
        bso_t = self.p11_info.bso_table
        count = 16
    end
    for i=0,(count-1) do
        if not bso_t[i] then
            return i
        end
    end
    return nil
end

local ck_false = eCK.BBOOL(false)
function t.is_ck_true(val)
    return val ~= nil and val ~= ck_false
end


function t.parse_p11v2_bool_attributes(obj, bools, items)
    local parsed_bools = {
    [CKA.MODIFIABLE] = eCK.BBOOL(bools[bin.flags(1)]),
    [CKA.TRUSTED] = eCK.BBOOL(bools[bin.flags(2)]),
    [CKA.LOCAL] = eCK.BBOOL(bools[bin.flags(4)]),
    [CKA.ENCRYPT] = eCK.BBOOL(bools[bin.flags(8)]),
    [CKA.DECRYPT] = eCK.BBOOL(bools[bin.flags(16)]),
    [CKA.SIGN] = eCK.BBOOL(bools[bin.flags(32)]),
    [CKA.VERIFY] = eCK.BBOOL(bools[bin.flags(64)]),
    [CKA.SIGN_RECOVER] = eCK.BBOOL(bools[bin.flags(128)]),
    [CKA.VERIFY_RECOVER] = eCK.BBOOL(bools[bin.flags(256)]),
    [CKA.WRAP] = eCK.BBOOL(bools[bin.flags(512)]),
    [CKA.UNWRAP] = eCK.BBOOL(bools[bin.flags(1024)]),
    [CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(bools[bin.flags(2048)]),
    [CKA.DERIVE] = eCK.BBOOL(bools[bin.flags(4096)]),
    [CKA.COPYABLE] = eCK.BBOOL(bools[bin.flags(8192)]),
    [CKA.DESTROYABLE] = eCK.BBOOL(not bools[bin.flags(32768)]), -- inverse logic (so defaults true)

    }
    for v=1,table.getn(items) do
        obj[items[v]] = parsed_bools[items[v]]
    end
end

function t.parse_p11v2_data_attribute(obj, buf)
    local flags = string.sub(buf, 1, 2)
    --print('flags:', hex.hexify(flags))
    local flags = bin.flags(bin.unpack("%H", flags ))
    local fields = utility.LV_get(buf, 2, 3)
    t.parse_p11v2_bool_attributes(obj, flags, {CKA.MODIFIABLE, })
    obj[CKA.LABEL] = fields[1]
    obj[CKA.APPLICATION] = fields[2]
    obj[CKA.OBJECT_ID] = fields[3]
end

function t.parse_p11v2_cert_attribute(obj, buf)
    local flags = string.sub(buf, 1, 2)
    --print('flags:', hex.hexify(flags))
    local flags = bin.flags(bin.unpack("%H", flags ))
    local fields = utility.LV_get(buf, 2, 2)
    t.parse_p11v2_bool_attributes(obj, flags, {CKA.MODIFIABLE, CKA.TRUSTED, CKA.ALWAYS_AUTHENTICATE})
    obj[CKA.LABEL]=fields[1]
    obj[CKA.ID]=fields[2]
    return obj
end


function t.parse_p11v2_pubkey_attribute(obj, buf)
    log.output("parse_p11v2_pubkey_attribute:", hex.hexify(buf))
    
    local flags = string.sub(buf, 1, 2)
    --print('flags:', hex.hexify(flags))
    local flags = bin.flags(bin.unpack("%H", flags ))
    local fields = utility.LV_get(buf, 2, 6)
    t.parse_p11v2_bool_attributes(obj, flags,
                                       {CKA.MODIFIABLE, CKA.LOCAL, 
                                        CKA.ENCRYPT, CKA.DECRYPT, 
                                        CKA.VERIFY, 
                                        CKA.VERIFY_RECOVER, 
                                        CKA.WRAP,
                                        CKA.ALWAYS_AUTHENTICATE, }
                                   )
    obj[CKA.LABEL] = fields[1]
    obj[CKA.ID] = fields[2]
    obj[CKA.SUBJECT] = fields[3]
    obj[CKA.START_DATE] = fields[4]
    obj[CKA.END_DATE] = fields[5]
    
    if type(fields[6]) == "string" then
        obj.key_bits = bin.unpack("%>%H", fields[6])
        log.output("parse_p11v2_pubkey_attribute: FS V2: key_bits", obj.key_bits)
    else
        obj.key_bits = 1024
        log.output("parse_p11v2_pubkey_attribute: FS V1: key_bits", obj.key_bits)
    end
end


function t.parse_p11v2_privkey_attribute(obj, buf)
    local flags = string.sub(buf, 1, 2)
    --print('flags:', hex.hexify(flags))
    local flags = bin.flags(bin.unpack("%H", flags ))
    local fields = utility.LV_get(buf, 2, 8)
    
    t.parse_p11v2_bool_attributes(obj, flags,
                                       {CKA.MODIFIABLE, CKA.LOCAL,
                                        CKA.ENCRYPT, CKA.DECRYPT, 
                                        CKA.SIGN,
                                        CKA.SIGN_RECOVER, 
                                        CKA.UNWRAP, 
                                        CKA.ALWAYS_AUTHENTICATE, }
                                   )
    
    obj.kid = string.byte(fields[1] or "\0")
    obj[CKA.LABEL] =           fields[2]
    obj[CKA.ID] =              fields[3]
    obj[CKA.SUBJECT] =         fields[4]
    obj[CKA.START_DATE] =      fields[5]
    obj[CKA.END_DATE] =        fields[6]
    obj[CKA.MODULUS] =         fields[7]
    obj[CKA.PUBLIC_EXPONENT] = fields[8]
    
    
    if type(obj[CKA.MODULUS]) == "string" then
        obj.key_bits = string.len(obj[CKA.MODULUS]) * 8
    else
        obj.key_bits = 1024
    end

end



-- funzioni per la serializzazione

function t.serialize_p11v2_bools(obj)
    local bools = bin.flags(0)
    if t.is_ck_true(obj[CKA.MODIFIABLE]) then bools = bools + bin.flags(1) end
    if t.is_ck_true(obj[CKA.TRUSTED])    then bools = bools + bin.flags(2) end
    if t.is_ck_true(obj[CKA.LOCAL])      then bools = bools + bin.flags(4) end
    if t.is_ck_true(obj[CKA.ENCRYPT])    then bools = bools + bin.flags(8) end
    if t.is_ck_true(obj[CKA.DECRYPT])    then bools = bools + bin.flags(16) end
    if t.is_ck_true(obj[CKA.SIGN])       then bools = bools + bin.flags(32) end
    if t.is_ck_true(obj[CKA.VERIFY])     then bools = bools + bin.flags(64) end
    if t.is_ck_true(obj[CKA.SIGN_RECOVER])   then bools = bools + bin.flags(128) end
    if t.is_ck_true(obj[CKA.VERIFY_RECOVER]) then bools = bools + bin.flags(256) end
    if t.is_ck_true(obj[CKA.WRAP])           then bools = bools + bin.flags(512) end
    if t.is_ck_true(obj[CKA.UNWRAP])         then bools = bools + bin.flags(1024) end
    if t.is_ck_true(obj[CKA.ALWAYS_AUTHENTICATE]) then bools = bools + bin.flags(2048) end
    log.output('serialize_p11v2_bools():', bools)
    return hex.hexf('%H', bools.asnumber)
end

function t.serialize_attr_p11v2(obj, template)
    local bools = t.serialize_p11v2_bools(obj)
    local attr = bools
    for i, v in template do
        local value = obj[v.type] or v.default or ''
        local t1 = '%H' -- default: double byte len
        if v.fixed then
            attr = attr .. value
        else
            if v.single then t1 = '%B' end -- single byte len
            attr = attr .. hex.hexf(t1, string.len(value)) .. value
        end
    end
    log.output('serialize_attr_p11v2():', hex.hexify(attr))
    return attr
end

function t.serialize_attr_p11v2_pubkey(obj, num, key_bits)
    local null_date = string.rep('\000', 8)
    local template ={ [1]={type=CKA.LABEL},
                      [2]={type=CKA.ID},
                      [3]={type=CKA.SUBJECT},
                      [4]={type=CKA.START_DATE, default=null_date},
                      [5]={type=CKA.END_DATE, default=null_date},
                      [6]={type="key_bits: invalid attribute name", default=hex.hexf("%>%H", key_bits or 1024)},
                    }
    return t.serialize_attr_p11v2(obj, template)
end


function t.serialize_attr_p11v2_cert(obj, num)

    local template ={ [1]={type=CKA.LABEL},
                      [2]={type=CKA.ID},
                    }
    return t.serialize_attr_p11v2(obj, template)
end


function t.serialize_attr_p11v2_privkey(obj, kid, key_bits)
    local null_date = string.rep('\000', 8)
    local template ={ [1]={type="kid: invalid attribute name", default=hex.hexf("%B", kid or 0)},
                      [2]={type=CKA.LABEL},
                      [3]={type=CKA.ID},
                      [4]={type=CKA.SUBJECT},
                      [5]={type=CKA.START_DATE, default=null_date},
                      [6]={type=CKA.END_DATE, default=null_date},
                      [7]={type=CKA.MODULUS},
                      [8]={type=CKA.PUBLIC_EXPONENT},
                    }
    return t.serialize_attr_p11v2(obj, template)
end

function t.serialize_attr_p11v2_data(obj)
    local template ={ [1]={type=CKA.LABEL},
                      [2]={type=CKA.APPLICATION },
                      [3]={type=CKA.OBJECT_ID},
                    }
    return t.serialize_attr_p11v2(obj, template)
end


function t._set_bit(value_f, bit_num, set)
    local mask_f = bin.flags(2^bit_num)
    local new_value_f = bin.flags(value_f.asnumber)
    --log.output("_set_bit before:", value_f, bit_num, set, mask_f)
    if set then
        new_value_f = new_value_f + mask_f
    else
        new_value_f = new_value_f - mask_f
    end
    --log.output("_set_bit after:", value_f)
    if (new_value_f.asnumber ~= value_f.asnumber) then
        log.output("_set_bit before:", value_f, "after:", new_value_f)
    end
    return new_value_f
end

function t.mt:write_p11_indexes()
    -- serialize the object list and update corresponding file
    local obj_table = self.p11_info.obj_table
    local bso_table = self.p11_info.bso_table
    local bso2048_table = self.p11_info.bso2048_table
    for i=0,31 do
        self.p11_info.oat_t = t._set_bit(self.p11_info.oat_t, i, obj_table[i])
    end
    for i=32,63 do
        self.p11_info.oat2_t = t._set_bit(self.p11_info.oat2_t, i-32, obj_table[i])
    end
    for i=0,15 do
        self.p11_info.bat_t = t._set_bit(self.p11_info.bat_t, i, bso_table[i])
    end
    for i=0,7 do
        self.p11_info.bat2048_t = t._set_bit(self.p11_info.bat2048_t, i, bso2048_table[i])
    end
    log.output(
        string.format('write_p11_indexes(): oat:0x%x, bat:0x%x, oat2:0x%x, bat2048:0x%x',
        self.p11_info.oat_t.asnumber,
        self.p11_info.bat_t.asnumber,
        self.p11_info.oat2_t.asnumber,
        self.p11_info.bat2048_t.asnumber)
    )
    local objList = hexf('%<%L%<%H', self.p11_info.oat_t.asnumber, self.p11_info.bat_t.asnumber)
    local bso2048List = hexf('%B', self.p11_info.bat2048_t.asnumber)
    local objList2 = hexf('%<%L', self.p11_info.oat2_t.asnumber)
    local p11infopath = self.p11_info.path_root..'0000'
    self.cns_hcard:select(hex.hexf(p11infopath))
    self.cns_hcard:mupdate_binary(2, objList)       -- 6 byte
    self.cns_hcard:mupdate_binary(10, bso2048List)  -- 1 byte
    self.cns_hcard:mupdate_binary(11, string.sub(objList2, 1, -2)) -- 3 byte
    self.cns_hcard:mupdate_binary(63, string.sub(objList2, -1, -1)) -- 1 byte
end

function t._trimpadto(value, trim_len, fill_char)
    local outvalue = string.sub(value, 1, trim_len)
    outvalue = outvalue .. string.rep(fill_char, trim_len - string.len(outvalue))
    return outvalue
end

function t.mt:pubkey_serialize_mainfile(obj, num, key_bits)
    local serialized_attr
    local bit_fields = bin.flags(0)
    local start_date = obj[CKA.START_DATE] or string.rep('\000', 8)
    local end_date = obj[CKA.END_DATE] or string.rep('\000', 8)
    local main_fid = self:buildP11Fid(num, objTypes.ePubKey, attrTypes.ePubKeyModExp)
    start_date = t._trimpadto(start_date, 8, '\000')
    end_date = t._trimpadto(end_date, 8, '\000')
    assert(string.len(start_date) == 8)
    assert(string.len(end_date) == 8)
    local ck_true = eCK.BBOOL(true)
    
    
    log.output("pubkey_serialize_mainfile(): key_bits:", key_bits, "num:", num)
    
    if obj[CKA.MODIFIABLE] == ck_true  then bit_fields = bit_fields + pubkey_bitfields.MODIFIABLE end
    if obj[CKA.PRIVATE] == ck_true  then bit_fields = bit_fields + pubkey_bitfields.PRIVATE end
    if obj[CKA.DERIVE] == ck_true  then bit_fields = bit_fields + pubkey_bitfields.DERIVE end
    if obj[CKA.LOCAL] == ck_true  then bit_fields = bit_fields + pubkey_bitfields.LOCAL end
    if obj[CKA.TRUSTED] == ck_true  then bit_fields = bit_fields + pubkey_bitfields.TRUSTED end
    if obj[CKA.ENCRYPT] == ck_true  then bit_fields = bit_fields + pubkey_bitfields.ENCRYPT end
    if obj[CKA.VERIFY] == ck_true  then bit_fields = bit_fields + pubkey_bitfields.VERIFY end
    if obj[CKA.VERIFY_RECOVER] == ck_true  then bit_fields = bit_fields + pubkey_bitfields.VERIFY_RECOVER end
    if obj[CKA.WRAP] == ck_true  then bit_fields = bit_fields + pubkey_bitfields.WRAP end
    serialized_attr = hexf("%<%H%S%S%>%H00"..self.p11_info.path_root.."%>%H00000000000000",
                        bit_fields.asnumber,
                        start_date,
                        end_date, 
                        key_bits,
                        main_fid)
    assert(string.len(serialized_attr) == 32)
    return serialized_attr
end

function t.mt:privkey_serialize_mainfile(obj, kid, key_bits)
    local serialized_attr
    local bit_fields = bin.flags(0)
    local start_date = obj[CKA.START_DATE] or string.rep('\000', 8)
    local end_date = obj[CKA.END_DATE] or string.rep('\000', 8)
    start_date = t._trimpadto(start_date, 8, '\000')
    end_date = t._trimpadto(end_date, 8, '\000')
    assert(string.len(start_date) == 8)
    assert(string.len(end_date) == 8)
    local ck_true = eCK.BBOOL(true)
    
    log.output("privkey_serialize_mainfile(): key_bits:", key_bits, "kid:", kid)
    
    if obj[CKA.MODIFIABLE] == ck_true then bit_fields = bit_fields + privkey_bitfields.MODIFIABLE end
    if obj[CKA.PRIVATE] == ck_true  then bit_fields = bit_fields + privkey_bitfields.PRIVATE end
    if obj[CKA.DERIVE] == ck_true  then bit_fields = bit_fields + privkey_bitfields.DERIVE end
    if obj[CKA.LOCAL] == ck_true  then bit_fields = bit_fields + privkey_bitfields.LOCAL end
    if obj[CKA.DECRYPT] == ck_true  then bit_fields = bit_fields + privkey_bitfields.DECRYPT end
    if obj[CKA.SIGN] == ck_true  then bit_fields = bit_fields + privkey_bitfields.SIGN end
    if obj[CKA.SIGN_RECOVER] == ck_true  then bit_fields = bit_fields + privkey_bitfields.SIGN_RECOVER end
    if obj[CKA.UNWRAP] == ck_true  then bit_fields = bit_fields + privkey_bitfields.UNWRAP end
            
    serialized_attr = hexf("%<%H%S%S%>%H03"..self.p11_info.path_root.."%>%H00000000000000",
                        bit_fields.asnumber,
                        start_date,
                        end_date,
                        key_bits,
                        kid)
    assert(string.len(serialized_attr) == 32)
    return serialized_attr
end

function t.mt:cert_serialize_mainfile(obj, num)
    local serialized_attr
    local bit_fields = bin.flags(0)
    local start_date = string.rep('\000', 8)
    local end_date = string.rep('\000', 8)
    local main_fid = self:buildP11Fid(num, objTypes.eCert, attrTypes.eMain)
    local ck_true = eCK.BBOOL(true)
    
    if obj[CKA.MODIFIABLE] == ck_true then bit_fields = bit_fields + cert_data_bitfields.MODIFIABLE end
    if obj[CKA.PRIVATE] == ck_true then bit_fields = bit_fields + cert_data_bitfields.PRIVATE end
    if obj[CKA.TRUSTED] == ck_true then bit_fields = bit_fields + cert_data_bitfields.TRUSTED end

    serialized_attr = hexf("%<%H%S%S000000"..self.p11_info.path_root.."%>%H00000000000000",
                            bit_fields.asnumber,
                            start_date,
                            end_date,
                            main_fid)
    assert(string.len(serialized_attr) == 32)
    return serialized_attr

end

function t.mt:data_serialize_mainfile(obj)
    local serialized_attr
    local bit_fields = bin.flags(0)
    
    local ck_true = eCK.BBOOL(true)
    if obj[CKA.MODIFIABLE] == ck_true then bit_fields = bit_fields + cert_data_bitfields.MODIFIABLE end
    if obj[CKA.PRIVATE] == ck_true then bit_fields = bit_fields + cert_data_bitfields.PRIVATE end
    if obj[CKA.TRUSTED] == ck_true then bit_fields = bit_fields + cert_data_bitfields.TRUSTED end

    serialized_attr = hexf("%<%H", bit_fields.asnumber) .. string.rep('\000', 30)
    assert(string.len(serialized_attr) == 32)
    return serialized_attr

end

function t.mt:create_p11_file(value, fid, is_public, pin_only_readable)
    -- is_public=true: crea un file scrivibile senza PIN
    -- is_public=false: crea un file scrivibile col PIN
    -- pin_only_readable=true: crea un file leggibile solo col PIN
    assert( value and string.len(value))
    local finfo = { size=string.len(value),
                        filetype=CnsSmartcard.fileTypes.Binary,
                        parent=hexf(self.p11_info.path_root),
                        fid=fid,
                        asm={},
                        }
    if pin_only_readable then
        log.output("create_p11_file(): creating PIN only readable file")
        finfo.aac = {read=self.cns_hcard.BSO_CNS_PIN}
    end
    self:create_file(finfo , is_public, true)
    self.cns_hcard:mupdate_binary(0, value)
end

function t.mt:set_p11_attribute(num, oType, aType, value, is_public, pin_only_readable)
    local fid = self:buildP11Fid(num, oType, aType)
    if not value or string.len(value) == 0 then
        pcall(function() self.cns_hcard:delete_file(hexf("%H",fid), true) end)
        return
    end
    local header = hexf("00%H%H", string.len(value), bin.crc16(value) )
    assert(string.len(header) == 5)
    self:create_p11_file(header .. value, fid, is_public, pin_only_readable)
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


function t.mt:create_object_pubkey(pTemplate, as_local)
    log.output('create_object_pubkey()', pTemplate)

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
    
    if iscns and self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
        
    if is_ds then
        log.output('create_object_pubkey(): unable to import on the DS filesystem!')
        return CKR.TEMPLATE_INCONSISTENT
    end
    local modulus_bits = string.len(pTemplate[CKA.MODULUS]) * 8
    if modulus_bits > 1024 and iscns then
        log.output('create_object_pubkey(): key size invalid for selected filesystem:', modulus_bits )
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    if modulus_bits ~= 1024 and modulus_bits ~= 2048 then
        log.output('create_object_pubkey(): key size invalid:', modulus_bits )
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    if modulus_bits > 1024 and (not self.p11_info or not self.support2048new) then
        log.output('create_object_pubkey(): no 2048 FS available')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    local freeId, freeSlot
    local fid_val, fid_attr, fid_main
    local fids_to_del = {}
    
    if iscns then
        -- self.cns_info.pub_key_handle 