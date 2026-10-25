 oggetti ritorna 0
function t.mt:get_item(search_state, showprivate, template)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    if search_state.lastobj==nil then 
        search_state.lastobj=self.attributes.min_index 
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


function t.mt:add_siae_objects(objects)
    log.output('token-siae:add_siae_objects():...')
    for i=1,table.getn( self._5f02) do
        local v = self._5f02[i]
        local status = string.byte(v, 1)
        
        if status == 1 or status == 2 then
            local fields = utility.LV_get(v, 1, 5, {1,1,1,1,1})
            
            local objPrivKey = objCnsTmpl.GetCNSPrivKeyTemplate(t.mt.get_privkey)
            objPrivKey.num = i
            objPrivKey.kid = i
            objPrivKey.cka_id = fields[1]
            objPrivKey.pubkey_fid = fields[2]
            objPrivKey.cert_fid = fields[3]
            objPrivKey.pub_key_attributes_fid = fields[4]
            objPrivKey.priv_key_attributes_fid = fields[5]
            objPrivKey.cert_attributes_fid = fields[6]
            objPrivKey[CKA.LABEL] = "KEY_" .. i
            objPrivKey[CKA.ID] = objPrivKey.cka_id
            objPrivKey.path = hex.hexify(self.root_path)
            
            objects.max_index = objects.max_index+1
            objects[ objects.max_index ] = objPrivKey
            log.output('token-siae:add_siae_objects(): added priv key:',
                objects.max_index, "kid=", objPrivKey.kid)
                
            local objCert = objCnsTmpl.GetCNSCertTemplate(t.mt.get_certificate)
            objCert.num = i
            objCert.cka_id = fields[1]
            objCert.pubkey_fid = fields[2]
            objCert.cert_fid = fields[3]
            objCert.pub_key_attributes_fid = fields[4]
            objCert.priv_key_attributes_fid = fields[5]
            objCert.cert_attributes_fid = fields[6]
            
            objCert.path = hex.hexify(self.root_path .. objCert.cert_fid)
            
            objCert[CKA.LABEL] = "CERT_" .. i
            objCert[CKA.ID] = objCert.cka_id
            objects.max_index = objects.max_index+1
            objects[ objects.max_index ] = objCert
            log.output('token-siae:add_siae_objects(): added cert:',
                objects.max_index, "fid=", hex.hexify(objCert.cert_fid))
        end
    end

end

function t.mt:get_objects()
    log.output('token-siae:get_objects()')
    local info = self:get_info() -- carica le info sul filesystem in cache
    
    local objects = {
            min_index = 11001, -- primo indice disponibile
            max_index = 11000, -- valore dell'indice massimo (i valori intermedi possono anche essere nil)
        }

    self:add_siae_objects(objects)
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
    if onlysize and type(result)=='string' then
        return CKR.OK, string.len(result)
    else
        return CKR.OK, result
    end
end


function t.mt:valid()
    local rv = self.siae_hcard:valid()
    if not rv then
        utility.forget_token_changed(self, "cache")
    end
    return rv
end


function t.mt:get_object_size(hobj)
    return CKR.OK, 1
end


function t.mt:flush_cache()
    if self.cfg["xproc"] ~= "true" then
        return false
    end
    local changed, cache_id
    if self._cache_id == nil then
        log.output("token-siae:flush_cache(): initializing _cache_id")
        changed, self._cache_id = utility.has_token_changed(self, "cache", 0)
        log.output("token-siae:flush_cache(): initialize: _cache_id:", self._cache_id)
    end
    changed, cache_id = utility.has_token_changed(self, "cache", self._cache_id)
    if changed then
        log.output("token-siae:flush_cache(): token has changed!")
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


return t

--===========================================================================
end
}
_LOADED['token-cns-objects'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- questo file deve essere incluso solo in 'token.-cns.lua'

local t = {}

function t.GetCNSCertTemplate(populateCertFunc)
    return {
        path = '11001101',
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.CERTIFICATE),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(false),
        [ CKA.LABEL ] = 'CNS0',
        -- Certificate
        [ CKA.CERTIFICATE_TYPE ] = eCK.CERTIFICATE_TYPE(CKC.X_509),
        [ CKA.TRUSTED ] = eCK.BBOOL(true),
        [ CKA.CERTIFICATE_CATEGORY ] = eCK.ULONG(1), -- user
        -- [ CKA.CHECK_VALUE ] = '',
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        -- Certificate X.509
        [ CKA.SUBJECT ] = populateCertFunc,
        [ CKA.ID ] = 'CNS0',
        [ CKA.ISSUER ] = populateCertFunc,
        [ CKA.SERIAL_NUMBER ] = populateCertFunc,
        [ CKA.VALUE ] = populateCertFunc,
        [ CKA.URL ] = '',
        [ CKA.HASH_OF_SUBJECT_PUBLIC_KEY ] = '',
        [ CKA.HASH_OF_ISSUER_PUBLIC_KEY ] = '',
        [ CKA.JAVA_MIDP_SECURITY_DOMAIN ] = eCK.ULONG(0),
        
        -- attributo non standard: usato per stabilire
        -- se un certificato 