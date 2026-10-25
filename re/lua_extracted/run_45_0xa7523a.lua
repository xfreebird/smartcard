 oggetti ritorna 0
function t.mt:get_item(search_state, showprivate, template)

    log.output('get_item():...', self.attributes)

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
        local visible = attr ~= nil and (
                        attr[CKA.PRIVATE] == eCK.BBOOL(false) or 
                        (attr[CKA.PRIVATE] == eCK.BBOOL(true) and showprivate) 
                        )
        if visible and self:verify_template(i, template) then
            search_state.lastobj = i +1
            return i
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
        local repr = utility.repr
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

function t.mt:buildP11Fid(objNum, objType, attrType)
    return 32768 + objNum*2^8 + objType*2^4 +attrType
end

function t.mt:select_with_cache(path)
    local info = self.info
    local sw
    if info and self:cache_enabled() then
        sw = utility.cache_read(info.serialNumber, "SELECT" .. path, self._AvoidUseLastUpdate, self._umcachepath)
        log.output("select_with_cache(): sw from cache=", hex.hexify(sw or "<nil>")) 
    end
    if type(sw) ~= "string" or string.len(sw) == 0 then
        pcall( function()
            self.cns_hcard:select(path)
        end)
        sw = self.cns_hcard.last_sw
        log.output("select_with_cache(): sw from card=", hex.hexify(sw or "<nil>")) 
        if sw and info and self:cache_enabled() then
            utility.cache_write(info.serialNumber, "SELECT" .. path, sw, self._umcachepath)
        end
    end
    
    if sw ~= hexf("9000") then
        error("select_with_cache(): file not found, sw=" .. hex.hexify(sw or "<nil>"))
    end
    return {}
end

function t.mt:add_p11_objects(objects)
    log.output('add_p11_objects()...')
    if self.p11_info == nil or self.p11_info.obj_table == nil then
        log.output('add_p11_objects(): invalid FS!')
        return
    end

    -- if not pcall(function() return self.cns_hcard:select(hexf(self.p11_info.path_root)) end ) then
        -- log.output('add_p11_objects(): error selecting Full P11 DF!')
        -- return
    -- end
    local use_0c_flag = self.cns_hcard.use_0c_flag
    self.cns_hcard.use_0c_flag=true
    for k=0,63 do
        if self.p11_info.obj_table[k] then
            log.output('add_p11_objects: found object at position', k)
            if pcall(function() 
                    return self:select_with_cache(
                        hexf(self.p11_info.path_root..'%H',self:buildP11Fid(k, objTypes.eCert, attrTypes.eMain)) 
                        ) end
                    ) then
                -- certificato
                local obj = objP11Tmpl.GetP11CertTemplate(t.mt.get_certificate_p11)
                obj.isp11 = true
                obj.num = k
                obj.parent_path = self.p11_info.path_root
                obj.path = hex.hexify(hexf(obj.parent_path .. '%H', self:buildP11Fid(k, objTypes.eCert, attrTypes.eValue) ) )
                objects.max_index = objects.max_index+1
                objects[objects.max_index] = obj
                log.output('add_p11_objects(): added certificate on position', k, 
                            'handle', objects.max_index, 
                            'path:', obj.path)
            elseif pcall(function() 
                            return self:select_with_cache(
                                hexf(self.p11_info.path_root..'%H',self:buildP11Fid(k, objTypes.ePrivKey, attrTypes.eMain)) 
                                ) end 
                            ) then
                -- chiave privata
                -- viene aggiunta senza leggere gli attributi, la cui lettura 