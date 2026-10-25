 necessario cancellare la chiave privata
        elseif obj.isp11 then
            log.output('destroy_object(): P11 PUBLIC_KEY')
            local the_attributes = {attrTypes.eMain, attrTypes.ePubKeyModExp, attrTypes.eLabel, attrTypes.eID, attrTypes.eSubject}
            for i, k in the_attributes do
                table.insert(files_delete, {path=hexf(self.p11_info.path_root), fid=hexf('%H', self:buildP11Fid(obj.num, objTypes.ePubKey, k) ) } )
            end
            self.p11_info.obj_table[obj.num] = false
            self:write_p11_indexes()
        else
            log.output('destroy_object(): DS PUBLIC_KEY')
            local oGroup = self.ds_info.ds_objects.o1024
            local index_base = 0
            if obj.num >= table.getn(self.ds_info.ds_objects.o1024) then
                oGroup = self.ds_info.ds_objects.o2048
                index_base = table.getn(self.ds_info.ds_objects.o1024)
            end
            oGroup[obj.num - index_base+1][2] = 0
            self:update_ds_index()
        end
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        log.output('destroy_object(): PRIVATE_KEY')
        if obj.iscns then
            log.output('destroy_object(): CNS PRIVATE_KEY')
            local pcRes, theErrorT = pcall(function()
                self:update_append_record(obj.related_public_key, 1, hex.hexf('1082') .. string.rep('\255', 130) )
                self:update_append_record(obj.related_public_key, 2, hex.hexf('1105') .. string.rep('\255', 5) )
                self.cns_info.key_valid=false
            end)
        elseif obj.isp11 then
            log.output('destroy_object(): P11 PRIVATE_KEY')
            local the_attributes = {attrTypes.eMain, attrTypes.eLabel, attrTypes.eID, attrTypes.eSubject, attrTypes.eModulus, attrTypes.ePubExp, }
            for i, k in the_attributes do
                table.insert(files_delete, {path=hexf(self.p11_info.path_root), fid=hexf('%H', self:buildP11Fid(obj.num, objTypes.ePrivKey, k) ) } )
            end
            table.insert(files_delete, {path=hexf(self.p11_info.path_root), fid=hexf('21%B', obj.kid) } )
            table.insert(files_delete, {path=hexf(self.p11_info.path_root), fid=hexf('20%B', obj.kid) } )
            self.p11_info.obj_table[obj.num] = false
            if obj.key_bits > 1024 then
                self.p11_info.bso2048_table[obj.kid - tonumber('41', 16)] = false
            else
                self.p11_info.bso_table[obj.kid - tonumber('21', 16)] = false
            end
            self:write_p11_indexes()
        else
            log.output('destroy_object(): DS PRIVATE_KEY')
            local oGroup = self.ds_info.ds_objects.o1024
            local index_base = 0
            if obj.num >= table.getn(self.ds_info.ds_objects.o1024) then
                oGroup = self.ds_info.ds_objects.o2048
                index_base = table.getn(self.ds_info.ds_objects.o1024)
            end
            oGroup[obj.num - index_base+1][1] = 0
            self:update_ds_index()
        end
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        log.output('destroy_object(): DATA')
        if obj.iscns then
            log.output('destroy_object(): CNS DATA')
            local pcRes, theErrorT = pcall(function()
                self.cns_hcard:select(hexf(obj.path) )
                self.cns_hcard:update_binary(0, '\000')
                self.cns_info.pdata_valid = false
            end)
        elseif obj.isp11 then
            log.output('destroy_object(): P11 DATA')
            local the_attributes = {attrTypes.eMain, attrTypes.eLabel, attrTypes.eObjectId, attrTypes.eApplication, }
            for i, k in the_attributes do
                table.insert(files_delete, {path=hexf(self.p11_info.path_root), fid=hexf('%H', self:buildP11Fid(obj.num, objTypes.eData, k) ) } )
            end
            self.p11_info.obj_table[obj.num] = false
            self:write_p11_indexes()
        else
            log.output('destroy_object(): WARNING: unknown DATA object type...')
        end
    else
        log.output('destroy_object(): WARNING! Unsupported object class!')
        return CKR.FUNCTION_FAILED
    end
    
    for i, v in files_delete do
        pcall(function()
            self.cns_hcard:select(v.path)
            self.cns_hcard:delete_file(v.fid, true)
        end)
    end
    self.attributes[hObject] = nil
    self:update_free_mem(self.info)
    return CKR.OK
end


function t.mt:set_attribute_value(hObject, pTemplate)

    if self.cns_only then
        log.output('set_attribute_value(): CNS only Token, cannot modify objects')
        return CKR.TOKEN_WRITE_PROTECTED
    end

    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hObject]
    if obj == nil then
        log.output('set_attribute_value(): specified handle invalid: ', hObject)
        return CKR.OBJECT_HANDLE_INVALID
    end  

    if obj.private and self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end

    if utility.cache_can_use() and self.cfg["fastread"]=='true' then
        log.output('removing cache...')
        -- elimina tutta la cache statica del token
        local info = self:get_info()
        log.output('removing cache for serial', info.serialNumber)
        utility.cache_write(info.serialNumber)
    end
    
    if obj.iscns or not obj.isp11 then
        log.output('set_attribute_value(): CNS/DS object: copying new values in memory')
        for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
            if pTemplate[k] then
                obj[k] = pTemplate[k]
            end
        end
        return CKR.OK
    end

    if not obj.isp11 then
        log.output('set_attribute_value(): Object not in P11 FS')
        return CKR.FUNCTION_FAILED
    end
    
    log.output('set_attribute_value(): verify_pin_cns() cached pin, with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        local res = -1
        if self.check_pin_status then
            res = self.cns_hcard:verify_pin_cns("", false, true)
        end
        if res ~= 0 then
            self.cns_hcard:verify_pin_cns(self.cached_main_pin, false, false)
        end
    end
    
    if not obj.populated then
        self:get_attribute_value(hObject, -1)
    end
    
    self:invalidate_xproc_cache()
    
    if obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        rv = self:set_attribute_value_pubkey(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        rv = self:set_attribute_value_privkey(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        rv = self:set_attribute_value_certificate(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
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
    local fid_main = self:buildP11Fid(obj.num, objTypes.ePrivKey, attrTypes.eMain)
    
    if self.p11_info.version_major >= 2 then
        local privk_mainfile = t.serialize_attr_p11v2_privkey(templateNew, obj.kid, obj.key_bits)
        self:create_p11_file(privk_mainfile, fid_main, true)
    else

        local privk_mainfile = self:privkey_serialize_mainfile(templateNew, obj.kid, obj.key_bits)
        self:create_p11_file(privk_mainfile, fid_main, false)
        
        if (pTemplate[CKA.LABEL]) then
            self:set_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.eLabel, pTemplate[CKA.LABEL], false )
        end
        
        if (pTemplate[CKA.ID]) then
        self:set_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.eID, pTemplate[CKA.ID], false )
        end
        
        if (pTemplate[CKA.SUBJECT]) then
        self:set_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.eSubject, pTemplate[CKA.SUBJECT], false )
        end
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
    
    local fid_main = self:buildP11Fid(obj.num, objTypes.eCert, attrTypes.eMain)
    
    if self.p11_info.version_major >= 2 then
        local cert_mainfile = t.serialize_attr_p11v2_cert(templateNew, obj.num)
        self:create_p11_file(cert_mainfile, fid_main, true)
    else
        local cert_mainfile = self:cert_serialize_mainfile(templateNew, obj.num)
        self:create_p11_file(cert_mainfile, fid_main, true)

        if (pTemplate[CKA.LABEL]) then
            self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eLabel, pTemplate[CKA.LABEL], true )
        end
        
        if (pTemplate[CKA.ID]) then
            self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eID, pTemplate[CKA.ID], true )
        end
        
        if (pTemplate[CKA.SUBJECT]) then
            self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eSubject, pTemplate[CKA.SUBJECT], true )
        end
        
        if (pTemplate[CKA.ISSUER]) then
            self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eIssuer, pTemplate[CKA.ISSUER], true )
        end
        
        if (pTemplate[CKA.SERIAL_NUMBER]) then
            self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eSN, pTemplate[CKA.SERIAL_NUMBER], true )
        end
    end
    
    -- aggiorna i valori in cache
    for k, v in pTemplate do
        obj[k] = v
    end
    return CKR.OK
end


function t.mt:set_attribute_value_pubkey(hObj, pTemplate)
    log.output('set_attribute_value_pubkey()')
    local obj = self.attributes[hObj]
    
    for k, v in pTemplate do
        if k ~= CKA.ID and k ~= CKA.LABEL and k ~= CKA.SUBJECT            
            and k ~= CKA.MODIFIABLE
            and k ~= CKA.START_DATE and k ~= CKA.END_DATE then
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
    
    local fid_main = self:buildP11Fid(obj.num, objTypes.ePubKey, attrTypes.eMain)
    
    
    if self.p11_info.version_major >= 2 then
        local pubk_mainfile = t.serialize_attr_p11v2_pubkey(templateNew, obj.num, obj.key_bits)
        self:create_p11_file(pubk_mainfile, fid_main, true)
        
    else
        local pubk_mainfile = self:pubkey_serialize_mainfile(templateNew, obj.num, obj.key_bits)
        self:create_p11_file(pubk_mainfile, fid_main, true)

        if (pTemplate[CKA.LABEL]) then
            self:set_p11_attribute(obj.num, objTypes.ePubKey, attrTypes.eLabel, pTemplate[CKA.LABEL], true )
        end
        
        if (pTemplate[CKA.ID]) then
            self:set_p11_attribute(obj.num, objTypes.ePubKey, attrTypes.eID, pTemplate[CKA.ID], true )
        end
        
        if (pTemplate[CKA.SUBJECT]) then
            self:set_p11_attribute(obj.num, objTypes.ePubKey, attrTypes.eSubject, pTemplate[CKA.SUBJECT], true )
        end
    end
    
    -- aggiorna i valori in cache
    for k, v in pTemplate do
        obj[k] = v
    end
    return CKR.OK
end



function t.mt:set_attribute_value_data(hObj, pTemplate)
    local obj = self.attributes[hObj]
    log.output('set_attribute_value_data()')
    local obj = self.attributes[hObj]
    
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
    
    local fid_main = self:buildP11Fid(obj.num, objTypes.eData, attrTypes.eMain)
        
    if self.p11_info.version_major >= 2 then
        local data_mainfile = t.serialize_attr_p11v2_data(templateNew)
        self:create_p11_file(data_mainfile, fid_main, true)
    else
        local data_mainfile = self:data_serialize_mainfile(templateNew)
        self:create_p11_file(data_mainfile, fid_main, not obj.private)

        if (pTemplate[CKA.LABEL]) then
            self:set_p11_attribute(obj.num, objTypes.eData, attrTypes.eLabel, pTemplate[CKA.LABEL], not obj.private )
        end
        
        if (pTemplate[CKA.OBJECT_ID]) then
            self:set_p11_attribute(obj.num, objTypes.eData, attrTypes.eObjectId, pTemplate[CKA.OBJECT_ID], not obj.private )
        end
        
        if (pTemplate[CKA.APPLICATION]) then
            self:set_p11_attribute(obj.num, objTypes.eData, attrTypes.eapplication, pTemplate[CKA.APPLICATION], not obj.private )
        end
    end
    
    if (pTemplate[CKA.VALUE]) then
        self:set_p11_attribute(obj.num, objTypes.eData, attrTypes.eValue, pTemplate[CKA.VALUE], not obj.private, obj.private )
    end
    
    -- aggiorna i valori in cache
    for k, v in pTemplate do
        obj[k] = v
    end
    return CKR.OK
end

function t.mt:get_special_ids(id_class)
    if id_class == 'CNS' then
        return {OBJ_IDS.CNS0_ID}
    elseif id_class == 'DS' then
        local ids = {}
        for i=0,self.ds_info.ds_objects.DS_MAX_INDEX do
            table.insert(ids, OBJ_IDS.DS_ID .. string.format('%d', i))
        end
        return ids
    end
end

function t.mt:alloc_object_handle()
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    self.attributes.max_index = self.attributes.max_index + 1
    return self.attributes.max_index
end

function t.mt:_get_license()
    
    local info = self.info or self:get_info()
    local pcRes
    local fInfos
    local licenseContents
    
    local files = {
        [1] = (self.ds_info and (self.ds_info.path_root .. "11ce")) or (self.p11_info and (self.p11_info.path_root..'0001'))
    }
    for i=1,table.getn(files) do
        pcRes = pcall(function()
            fInfos = self.cns_hcard:select(hexf(files[i]), true)
        end)
        if pcRes then
            licenseContents = self.cns_hcard:mread_binary(0, fInfos.size)
            break
        end
    end
    if not licenseContents or string.len(licenseContents) < 2 then
        return
    end
    local license_len = bin.unpack('%H', string.sub(licenseContents, 1, 2))
    return string.sub(licenseContents, 3, license_len+2)
end


function t.mt:set_label(Puk, label)
    local rv = CKR.OK
    local info = self:get_info()
    -- if Puk and string.len(Puk) > 0 then
        -- rv = self:verify_pin(Puk, CKU.SO)
        -- if rv ~= CKR.OK then
            -- return rv
        -- end
    -- end
    if self.p11_info then
        local pcRes, theErrorT = pcall(function()
            local p11infopath = self.p11_info.path_root..'0000'
            self.cns_hcard:select(hex.hexf(p11infopath))
            local value = label .. string.rep(" ", 32 - string.len(label))
            value = string.sub(value, 1, 32)
            self.cns_hcard:mupdate_binary(14, value)
            self.info.label = value
            self.p11_info.label = value
        end)
        if not pcRes then
            log.output('set_label(): error:', theErrorT)
            rv = CKR.FUNCTION_FAILED
        end
    end
    return rv
end

function t.mt:update_free_mem(info)
    log.output("update_free_mem():")
    if not info or not self.jsign_2048 then
        return
    end
    pcall(function()
        local recv, err = self.cns_hcard:transmit(hex.hexf("00ca018a03"))
        -- ans: <spazio residuo su 3 bytes>
        local sw = string.sub(recv, -2, -1)
        if recv and sw == hexf('9000') then
            info.ulFreePublicMemory = bin.unpack("%>%L", "\0" .. string.sub(recv, 1, 3))
            info.ulFreePrivateMemory = self.info.ulFreePublicMemory
            log.output("token free space:", info.ulFreePublicMemory);
        end
    end)
end



function t.mt:flush_cache()
    if self.cfg["xproc"] ~= "true" then
        return false
    end
    local changed, cache_id
    if self._cache_id == nil then
        log.output("token-ts:flush_cache(): initializing _cache_id")
        changed, self._cache_id = utility.has_token_changed(self, "cache", 0)
        log.output("token-ts:flush_cache(): initialize: _cache_id:", self._cache_id)
    end
    changed, cache_id = utility.has_token_changed(self, "cache", self._cache_id)
    if changed then
        log.output("token-ts:flush_cache(): token has changed!")
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
_LOADED['token-oberthur-objects'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- questo file deve essere incluso solo in 'token.-cns.lua'
local hex = require 'hex'
local t = {}

function t.GetDSCertTemplate(populateCertFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.CERTIFICATE),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = populateCertFunc,
        [ CKA.DESTROYABLE ] = populateCertFunc,
        [ CKA.LABEL ] = populateCertFunc,
        -- Certificate
        [ CKA.CERTIFICATE_TYPE ] = eCK.CERTIFICATE_TYPE(CKC.X_509),
        [ CKA.TRUSTED ] = populateCertFunc,
        [ CKA.CERTIFICATE_CATEGORY ] = eCK.ULONG(1), -- user
        -- [ CKA.CHECK_VALUE ] = '',
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        -- Certificate X.509
        [ CKA.SUBJECT ] = populateCertFunc,
        [ CKA.ID ] = populateCertFunc,
        [ CKA.ISSUER ] = populateCertFunc,
        [ CKA.SERIAL_NUMBER ] = populateCertFunc,
        [ CKA.VALUE ] = populateCertFunc,
        [ CKA.URL ] = '',
        [ CKA.HASH_OF_SUBJECT_PUBLIC_KEY ] = '',
        [ CKA.HASH_OF_ISSUER_PUBLIC_KEY ] = '',
        [ CKA.JAVA_MIDP_SECURITY_DOMAIN ] = eCK.ULONG(0),
    }
end

function t.GetDSPubKeyTemplate(populateKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PUBLIC_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = populateKeyFunc,
        [ CKA.DESTROYABLE ] = populateKeyFunc,
        [ CKA.LABEL ] = populateKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = populateKeyFunc,
        [ CKA.START_DATE ] = populateKeyFunc,
        [ CKA.END_DATE ] = populateKeyFunc,
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = populateKeyFunc,
        [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.RSA_PKCS_KEY_PAIR_GEN),
        -- [ CKA.ALLOWED_MECHANISMS ] = '',
        -- Public Key
        [ CKA.SUBJECT ] = populateKeyFunc,
        [ CKA.ENCRYPT ] = populateKeyFunc,
        [ CKA.VERIFY ] = populateKeyFunc,
        [ CKA.VERIFY_RECOVER ] = populateKeyFunc,
        [ CKA.WRAP ] = populateKeyFunc,
        [ CKA.TRUSTED ] = populateKeyFunc,
        -- [ CKA.WRAP_TEMPLATE ] = '',
        -- RSA Public Key
        [ CKA.MODULUS ] = populateKeyFunc,
        [ CKA.MODULUS_BITS ] = populateKeyFunc,
        [ CKA.PUBLIC_EXPONENT ] = populateKeyFunc,
    }
end

function t.GetDSPrivKeyTemplate(populateKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PRIVATE_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = populateKeyFunc,
        [ CKA.DESTROYABLE ] = populateKeyFunc,
        [ CKA.LABEL ] = populateKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = populateKeyFunc,
        [ CKA.START_DATE ] = populateKeyFunc,
        [ CKA.END_DATE ] = populateKeyFunc,
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = populateKeyFunc,
        [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.RSA_PKCS_KEY_PAIR_GEN),
        -- [ CKA.ALLOWED_MECHANISMS ] = '',
        -- Private Key
        [ CKA.SUBJECT ] = populateKeyFunc,
        [ CKA.SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.DECRYPT ] = populateKeyFunc,
        [ CKA.SIGN ] = populateKeyFunc,
        [ CKA.SIGN_RECOVER ] = populateKeyFunc,
        [ CKA.UNWRAP ] = populateKeyFunc,
        [ CKA.EXTRACTABLE ] = eCK.BBOOL(false),
        [ CKA.ALWAYS_SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.NEVER_EXTRACTABLE ] = eCK.BBOOL(true),
        [ CKA.WRAP_WITH_TRUSTED ] = eCK.BBOOL(false),
        -- [ CKA.UNWRAP_TEMPLATE ] = '',
        [ CKA.ALWAYS_AUTHENTICATE ] = eCK.BBOOL(false),
        -- RSA Private Key
        [ CKA.MODULUS ] = populateKeyFunc,
        [ CKA.PUBLIC_EXPONENT ] = populateKeyFunc,
        [ CKA.PRIVATE_EXPONENT ] = -1,
        [ CKA.PRIME_1 ] = -1,
        [ CKA.PRIME_2 ] = -1,
        [ CKA.EXPONENT_1 ] = -1,
        [ CKA.EXPONENT_2 ] = -1,
        [ CKA.COEFFICIENT ] = -1,
    }
end

function t.GetDSDataTemplate(populateDataFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.DATA),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = populateDataFunc,
        [ CKA.MODIFIABLE ] = populateDataFunc,
        [ CKA.DESTROYABLE ] = populateCertFunc,
        [ CKA.LABEL ] = populateDataFunc,
        -- DATA
        [ CKA.APPLICATION ] = populateDataFunc,
        [ CKA.OBJECT_ID ] = populateDataFunc,
        [ CKA.VALUE ] = populateDataFunc,
    }
end


return t

--===========================================================================
end
}
_LOADED['token-cns-oberthur'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- pcsc-token-cns.lua
local rsa = require 'rsa'
local aes = require 'aes'
local hmac = require 'hmac'
local ecdhlib = require 'ecdhlib'
local json = require 'json'
local CnsSmartcard = require 'CnsSmartcard'
local CnsSmartcard_w = require 'CnsSmartcard_w'
local CnsSmartcardCommon = require 'CnsSmartcardCommon'
local CnsSmartcardError = CnsSmartcardCommon.CnsSmartcardError

CnsSmartcardCommon.MAX_TRANSMIT_BUFFER_SIZE = 100
CnsSmartcard.MAX_TRANSMIT_BUFFER_SIZE = CnsSmartcardCommon.MAX_TRANSMIT_BUFFER_SIZE

local hex = require 'hex'
local zlib = require "zlib"
local hexf = hex.hexf
local der = require 'der'
local oberthur_util = require 'oberthur_util'
local objCnsTmpl = require 'token-cns-objects'
local objOberthurTmpl = require 'token-oberthur-objects'
local utility = require 'utility'
local repr = utility.repr

local licensing = require 'licensing'
local aes = require "aes"

local CKO_PIN_POLICY = tonumber("80001000", 16)

local PINPAD_CTL_VERIFY=1
local PINPAD_CTL_CHANGE=2
local PINPAD_CTL_RESET=3

local PINPAD_CTL_PIN=256
local PINPAD_CTL_PUK=512
local PINPAD_CTL_DSPIN=768
local PINPAD_CTL_DSPUK=1024

local ECC_QUALIFIED_KEYBITS_FLAG = bin.flags("0x8000")
local IDEMIA_USAGE_USED = 255
local IDEMIA_USAGE_USED2 = 254
local IDEMIA_USAGE_FREE = 0

-- add custom mechanism correspondng to crypto_box_easy
CKM.CURVE25519_CRYPTO_BOX = CKM.CURVE25519_CRYPTO_BOX or (CKM.VENDOR_DEFINED + CKM.ECDH1_DERIVE + CKM.HKDF_DERIVE)

    
local emt = {
	OperationOk = 0, -- Report "operation success", generic, return 0
	OperationFailed = 1, -- Report "operation failed", generic, return 0

	PinIncorrect = 8, -- Report "PIN incorrect, retry?", return 1 if YES, 0 if NO
	PinLocked = 9,    -- Report "Smartcard locked", return 0
	PinDeactivated = 10, -- Report "Smartcard not yet activated", return 0

	PukIncorrect = 16, -- Report "PUK incorrect, retry?", return 1 if YES, 0 if NO
	PukLocked = 17, -- Report "PUK locked", return 0

    }
local MinKSize, MaxKSize = 1024, 1024
local t = {
    name = 'oberthur',
    mt = { },
    mechanisms = {
        [ CKM.RSA_PKCS_KEY_PAIR_GEN ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.GENERATE_KEY_PAIR},
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_PKCS_PSS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.SIGN},
        [ CKM.RSA_X_509 ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_PKCS_OAEP ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT},
        
        [ CKM.AES_KEY_GEN ] = {ulMinKeySize=16, ulMaxKeySize=32, flags=CKF.HW+CKF.GENERATE},
        [ CKM.AES_CBC ] = {ulMinKeySize=16, ulMaxKeySize=32, flags=CKF.HW+CKF.DECRYPT+CKF.ENCRYPT},
        [ CKM.AES_CBC_PAD ] = {ulMinKeySize=16, ulMaxKeySize=32, flags=CKF.HW+CKF.DECRYPT+CKF.ENCRYPT},
    },
    cns_hcard = nil,
    -- le chiavi DS oberthur sono protette da entrambe i PIN
    -- non 