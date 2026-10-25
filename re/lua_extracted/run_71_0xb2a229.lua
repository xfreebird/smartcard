 scrivibile
                local finfo = self.cns_hcard:select(hexf('3f003f01'), true)
                step1_ok = (finfo and finfo.ac and string.sub(finfo.ac, 2, 2) ~= '\255')
            end)
        else
            self.cns_hcard:select(hexf(obj.ds_parent_path))
            
            local erase_bso
            if obj.ecc then
                log.output('destroy_object(): erasing ECC BSO:', obj.kid)
                erase_bso = hex.hexf('80E4016E0238%B', obj.kid)
            else
                erase_bso = hex.hexf('80E4016E0221%B', obj.kid)
                log.output('destroy_object(): erasing RSA BSO:', obj.kid)
            end
            pcall( function() self.cns_hcard:transmit(erase_bso) end)
            --local erase_mod = hex.hexf('80E4016E0220%B', obj.kid)
            --log.output('destroy_object(): erasing RSA BSO mod:', obj.kid)
            --pcall( function() self.cns_hcard:transmit(erase_mod) end)
        end
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        if obj.num == 1 then
            step1_ok = false
            log.output('destroy_object(): overwriting CNS PDATA: ', obj.path)
            pcall(function()
                self.cns_hcard:select(hexf(obj.path))
                self.cns_hcard:mupdate_binary(0, string.rep('\000', 400) ) -- azzera l'intero contenuto
                step1_ok=true
            end)
        end
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.SECRET_KEY) then
        log.output('destroy_object(): SECET KEY')
        step1_ok = true

    else
        log.output('destroy_object(): WARNING! Unsupported object class!')
        return CKR.FUNCTION_FAILED
    end

    if not step1_ok then
        log.output('destroy_object(): step1 FAILED')
        if self._cns_read_only then
            log.output('destroy_object(): read only FS?')
            return CKR.TOKEN_WRITE_PROTECTED
        end
        return CKR.FUNCTION_FAILED
    end
    
    log.output('destroy_object(): deleting DS attributes file:', obj.ds_parent_path .. hex.hexify(fid_attr))
    pcRes, theErrorT = pcall(function()
            self.cns_hcard:select(hexf(obj.ds_parent_path))
            self.cns_hcard:delete_file(fid_attr)
          end)
    if not pcRes and self.cns_hcard.last_sw == hex.hexf("6982") then
        log.output('destroy_object(): deleting attributes error, file read only:', debug.traceback(theErrorT))
        return CKR.FUNCTION_FAILED
    end
    
    if obj.num > 1 then
        log.output('destroy_object(): deleting DS value file:', obj.ds_parent_path .. hex.hexify(fid_val))
        pcRes, theErrorT = pcall(function()
                self.cns_hcard:select(hexf(obj.ds_parent_path))
                self.cns_hcard:delete_file(fid_val)
            end)
        if not pcRes and self.cns_hcard.last_sw == hex.hexf("6982") then
            log.output('destroy_object(): deleting value error, file read only:', debug.traceback(theErrorT))
            return CKR.FUNCTION_FAILED
        end
    end
    
    self.attributes[hObject] = nil
    ds_objlist[obj.slot].usage = 0
    ds_objlist[obj.slot].id = hexf('FAFE')
    ds_objlist[obj.slot].id_numeric = 0
    ds_objlist[obj.slot].infos = 0
    self:write_objlist(not obj.private)
    
    self:update_cache_id()
    self:update_free_mem(self.info)
    return CKR.OK
end

function t.mt:set_attribute_value(hObject, pTemplate)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local rv
    local obj = self.attributes[hObject]
    if obj == nil then
        log.output('set_attribute_value(): specified handle invalid: ', hObject)
        return CKR.OBJECT_HANDLE_INVALID
    end  

    log.output('set_attribute_value(): verify_pin_cns() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.cns_hcard:verify_pin_cns(self.cached_main_pin, false, false, self.ds_info.sm_use2_enc, self.ds_info.sm_use2_sig)
    end
    
    self:invalidate_xproc_cache()
    self:cache_clear()
    
    if obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        if not obj.populated then
            self:get_pubkey_fn(hObject, CKA.CLASS, false, true)
        end
        rv = self:set_attribute_value_pubkey(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        if not obj.populated then
            self:get_privkey_fn(hObject, CKA.CLASS)
        end
        rv = self:set_attribute_value_privkey(hObject, pTemplate)
       
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.SECRET_KEY) then
        if not obj.populated then
            self:get_secret_key_ds(hObject, CKA.CLASS)
        end
        rv = self:set_attribute_value_secretkey(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        if not obj.populated then
            self:get_certificate_ds(hObject, CKA.CLASS, false, true)
        end
        rv = self:set_attribute_value_certificate(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        if not obj.populated then
            self:get_data_ds(hObject, CKA.CLASS)
        end
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
    
    local fid_attr
    
    for k, v in pTemplate do
        if k ~= CKA.ID and k ~= CKA.LABEL and k ~= CKA.SUBJECT
            and k ~= CKA.START_DATE and k ~= CKA.END_DATE 
            and k ~= CKA.MODIFIABLE
            and k ~= CKA.DESTROYABLE
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
    
    local attr
    if obj[CKA.KEY_TYPE] == eCK.ULONG(CKK.RSA) then
        attr = oberthur_util.serialize_attr_privkey(templateNew)
        fid_attr = bin.flags('0x0100') + bin.flags(obj.num) + oberthur_util.objFIDS.ePrivKey
    elseif obj[CKA.KEY_TYPE] == eCK.ULONG(CKK.EC_EDWARDS) then
        attr = oberthur_util.serialize_attr_ecc_priv_pub_key(templateNew)
        fid_attr = bin.flags('0x0100') + bin.flags(obj.num) + oberthur_util.objFIDS.ePrivEdDSA
    elseif obj[CKA.KEY_TYPE] == eCK.ULONG(CKK.ECDSA) then
        attr = oberthur_util.serialize_attr_ecc_priv_pub_key(templateNew)
        fid_attr = bin.flags('0x0100') + bin.flags(obj.num) + oberthur_util.objFIDS.ePrivECC
    end
    
    
    -- crea gli attributi della chiave privata
    self:create_file( {
                    size=string.len(attr), 
                    filetype=CnsSmartcard.fileTypes.Binary,
                    parent=hexf(obj.ds_parent_path),
                    fid=fid_attr.asnumber, }, false)
    self.cns_hcard:mupdate_binary(0, attr)
    
    -- aggiorna i valori in cache
    for k, v in pTemplate do
        obj[k] = v
    end
    return CKR.OK
end


function t.mt:set_attribute_value_secretkey(hObj, pTemplate)
    log.output('set_attribute_value_secretkey()')
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    local obj = self.attributes[hObj]
    
    local fid_attr
    
    for k, v in pTemplate do
        if k ~= CKA.ID and k ~= CKA.LABEL and k ~= CKA.SUBJECT
            and k ~= CKA.START_DATE and k ~= CKA.END_DATE 
            and k ~= CKA.MODIFIABLE
            and k ~= CKA.DESTROYABLE
            and k ~= CKA.DECRYPT and k ~= CKA.ENCRYPT then
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
    
    if not obj.value then
        log.output('set_attribute_value_secretkey(): obj value not set!')
        return CKR.FUNCTION_FAILED
    end
    
    templateNew[CKA.VALUE] = aes.aes_encrypt_check(self._mk, obj.value, "00000001")
    
    local attr
    if obj[CKA.KEY_TYPE] == eCK.ULONG(CKK.AES) then
        attr = oberthur_util.serialize_attr_secretkey(templateNew)
        fid_attr = bin.flags('0x0100') + bin.flags(obj.num) + oberthur_util.objFIDS.eAESKey
    else
        log.output('set_attribute_value_secretkey(): invalid key type')
        return CKR.FUNCTION_FAILED
    end
    
    
    -- crea gli attributi della chiave privata
    self:create_file( {
                    size=string.len(attr), 
                    filetype=CnsSmartcard.fileTypes.Binary,
                    parent=hexf(obj.ds_parent_path),
                    fid=fid_attr.asnumber, }, false, true)
    self.cns_hcard:mupdate_binary(0, attr)
    
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
            and k ~= CKA.MODIFIABLE
            and k ~= CKA.DESTROYABLE
            and k ~= CKA.TRUESTED  then
            return CKR.ATRIBUTE_TYPE_INVALID
        end
    end
    local fid_attr = bin.flags('0x0100') + bin.flags(obj.num) + oberthur_util.objFIDS.eCert
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
    local attr = oberthur_util.serialize_attr_cert(templateNew)
    
    -- crea gli attributi del certificato
    self:create_file( {
                    size=string.len(attr), 
                    filetype=CnsSmartcard.fileTypes.Binary,
                    parent=hexf(obj.ds_parent_path),
                    fid=fid_attr.asnumber, }, true )
    self.cns_hcard:mupdate_binary(0, attr)

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
            and k ~= CKA.DESTROYABLE
            and k ~= CKA.START_DATE and k ~= CKA.END_DATE  then
            return CKR.ATRIBUTE_TYPE_INVALID
        end
    end
    local fid_attr

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
    local attr
    if obj[CKA.KEY_TYPE] == eCK.ULONG(CKK.RSA) then
        attr = oberthur_util.serialize_attr_pubkey(templateNew)
        fid_attr = bin.flags('0x0100') + bin.flags(obj.num) + oberthur_util.objFIDS.ePubKey
    elseif obj[CKA.KEY_TYPE] == eCK.ULONG(CKK.EC_EDWARDS) then
        attr = oberthur_util.serialize_attr_ecc_priv_pub_key(templateNew)
        fid_attr = bin.flags('0x0100') + bin.flags(obj.num) + oberthur_util.objFIDS.ePubEdDSA
    elseif obj[CKA.KEY_TYPE] == eCK.ULONG(CKK.ECDSA) then
        attr = oberthur_util.serialize_attr_ecc_priv_pub_key(templateNew)
        fid_attr = bin.flags('0x0100') + bin.flags(obj.num) + oberthur_util.objFIDS.ePubECC
    end

    
    -- crea gli attributi della chiave pubblica
    self:create_file( {
                    size=string.len(attr), 
                    filetype=CnsSmartcard.fileTypes.Binary,
                    parent=hexf(obj.ds_parent_path),
                    fid=fid_attr.asnumber, }, true)
    self.cns_hcard:mupdate_binary(0, attr)

    -- aggiorna i valori in cache
    for k, v in pTemplate do
        obj[k] = v
    end
    return CKR.OK
end



function t.mt:set_attribute_value_data(hObj, pTemplate)
    local obj = self.attributes[hObj]
    log.output('set_attribute_value_data(): unimplemented, remember values just for session')
    for k, v in pTemplate do
        obj[k] = v
    end

    return CKR.OK
end

function t.mt:get_special_ids(id_class)
    if id_class == 'CNS' then
        return {'CNS0'}
    elseif id_class == 'DS' then
        local ids = {}
        for i=0,9 do
            table.insert(ids, string.format('DS%d', i))
        end
        return ids
    end
end


function t.mt:valid()
    local rv = self.cns_hcard:valid()
    if not rv then
        utility.forget_token_changed(self, "cache")
    end
    return rv
end

function t.mt:set_label(Puk, label)
    local rv = CKR.OK
    local info = self:get_info()
    log.output('set_label():', Puk, label)
    if self.ds_info and self.ds_info.path_root then
        local pcRes, theErrorT = pcall(function()
            local path = hex.hexf(self.ds_info.path_root .. '1000')
            self.cns_hcard:select(path)
            local value = label .. string.rep(" ", 32 - string.len(label))
            value = string.sub(value, 1, 32)
            self.cns_hcard:mupdate_binary(0, value)
            self.info.label = value
            self:update_cache_id()
            
        end)
        if not pcRes then
            log.output('set_label(): error:', theErrorT)
            rv = CKR.FUNCTION_FAILED
        end
    end
    return rv
end
function t.mt:_get_license()
   
    local info = self.info or self:get_info()
    local pcRes
    local fInfos
    local licenseContents = ""
    
    local files = {
        [1] = '100011ce', -- default location when no DS app exists (deprecated)
        }
    if self.ds_info then
        files = {
            [1] = self.ds_info.path_root .. self.ds_df_pub .. "11ce", -- default location
            [2] = self.ds_info.path_root .. "11ce", -- alternative location (deprecated)
        }
    end
    for i=1,table.getn(files) do
        local lice_path = hexf(files[i])
        pcall(function()
            licenseContents = self:read_cached_file(lice_path, 0, -1, true)
        end)
        if type(licenseContents) == "string" and string.len(licenseContents) >= 2 then
            break
        end
    end
    
    if type(licenseContents) ~= "string" or string.len(licenseContents) < 2 then
        licenseContents = ""
        pcRes = pcall(function()
            fInfos = self.cns_hcard:select(hexf(self.ds_info.path_root .. "3000"), true) -- alternative location in unused 3000 file (deprecated)
        end)
        
        if pcRes then
            local recNum = 1
            local value
            while pcall(function()
                    value = self.cns_hcard:read_record(recNum, 4, 51)
                end) do
                recNum = recNum +1
                licenseContents = licenseContents .. value
            end
        end
    end
    if string.len(licenseContents) < 2 then
        return
    end
    local license_len = bin.unpack('%H', string.sub(licenseContents, 1, 2))
    return string.sub(licenseContents, 3, license_len+2)
end


function t.mt:flush_cache()
    if self.cfg["xproc"] ~= "true" then
        return false
    end
    local changed, cache_id
    if self._cache_id == nil then
        changed, self._cache_id = utility.has_token_changed(self, "cache", 0)
        log.output("token-cns-oberthur:flush_cache(): initialize: _cache_id:", self._cache_id)
    end
    changed, cache_id = utility.has_token_changed(self, "cache", self._cache_id)
    if changed then
        log.output("token-cns-oberthur:flush_cache(): token has changed!")
        self._cache_id = cache_id
        self:cache_clear()
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


function t.mt:set_param(name, value)

    if not name or string.len(name) == 0 then
        log.output('set_param(): name is required')
        return CKR.ATTRIBUTE_TYPE_INVALID
    end
    
    log.output('set_param(): value:', value)
    
    if name == "dspinusegui" then
        self.cfg[name] = value
    elseif name == "dspiniscnspin" then
        self.cfg[name] = value
    elseif name == "hidecachedspincheck" then
        self.cfg[name] = value
    else
        log.output('set_param(): unknown param name')
        return CKR.ATTRIBUTE_TYPE_INVALID
    end
    
    log.output('set_param(): OK!')
    return CKR.OK
end

function t.mt:get_param(name)

    local rv, value = CKR.ATTRIBUTE_TYPE_INVALID, ""
    
    if not name or string.len(name) == 0 then
        log.output('get_param(): name is required')
        return CKR.ATTRIBUTE_TYPE_INVALID
    end
    
    log.output('get_param(): name:', name)
    
    name = string.lower(name)
    if name == "dspinusegui" then
        rv, value = CKR.OK, self.cfg[name]
    elseif name == "dspiniscnspin" then
        rv, value = CKR.OK, self.cfg[name]
     elseif name == "hidecachedspincheck" then
        rv, value = CKR.OK, self.cfg[name]
    end

    log.output('get_param(): rv:', rv)
    log.output('get_param(): value:', value)
    return rv, value
end





function t.mt:generate_key(pMechanism, pTemplate)
    log.output('generate_key(): pMechanism', pMechanism and pMechanism.mechanism)

    log.output('generate_key(): verify_pin_cns() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.cns_hcard:verify_pin_cns(self.cached_main_pin, false, false, self.ds_info.sm_use2_enc, self.ds_info.sm_use2_sig)
    end

    if pTemplate[CKA.PRIVATE]
        and pTemplate[CKA.PRIVATE] ~= eCK.BBOOL(false)
        and self.userType ~= CKU.USER then
        log.output('generate_key(): not logged in: login required to create private objects')
        return CKR.USER_NOT_LOGGED_IN
    end
    
    if not pTemplate[CKA.VALUE_LEN] then
        log.output('generate_key(): no key len specified')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local rv, hObj
    
    self:check_clear_cache(nil, true, true)
    self:invalidate_xproc_cache()
    self:cache_clear()
    
    if pMechanism.mechanism == CKM.AES_KEY_GEN then
        local pTemplate2 = utility.clone_table(pTemplate)
        local value_len
        
        if pTemplate2[CKA.VALUE_LEN] == eCK.ULONG(16) then
            value_len = 16
        elseif pTemplate2[CKA.VALUE_LEN] == eCK.ULONG(24) then
            value_len = 24
        elseif pTemplate2[CKA.VALUE_LEN] == eCK.ULONG(32) then
            value_len = 32
        else
            log.output('generate_key(): key len not supported:', hex.hexify(pTemplate2[CKA.VALUE_LEN] or ""))
            return CKR.ATTRIBUTE_VALUE_INVALID
        end
        
        pTemplate2[CKA.VALUE] = sm.gen_random(value_len)
        pTemplate2[CKA.CLASS] = eCK.ULONG(CKO.SECRET_KEY)
        pTemplate2[CKA.KEY_TYPE] = eCK.ULONG(CKK.AES)
        pTemplate2[CKA.ENCRYPT] = eCK.BBOOL(true)
        pTemplate2[CKA.DECRYPT] = eCK.BBOOL(true)
        
        rv, hObj = self:create_object_secret_key(pTemplate2, true)

    else
    
        log.output('generate_key(): unsupported mechanism:', pMechanism.mechanism)
        rv = CKR.MECHANISM_INVALID
    end
    if rv == CKR.OK then
        self:update_free_mem(self.info)
        log.output("generate_key(): calling update_cache_id()...")
        self:update_cache_id()
    end
    log.output(string.format("generate_key(): returning rv=0x%08X, hobj=%d", rv or -1, hObj or -1))
    return rv, hObj
end

function t.mt:create_object_secret_key(pTemplateOrig, as_local)

    local pTemplate = utility.clone_table(pTemplateOrig)
    log.output('create_object_secret_key()', pTemplate)

    if self.userType ~= CKU.USER then
        log.output('create_object_secret_key(): USER_NOT_LOGGED_IN')
        return CKR.USER_NOT_LOGGED_IN
    end
    
    if pTemplate[CKA.KEY_TYPE] ~= eCK.ULONG(CKK.AES) then
        log.output('create_object_secret_key(): KEY TYPE invalid!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    if not pTemplate[CKA.VALUE] then
        log.output('create_object_secret_key(): VALUE not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    local value = pTemplate[CKA.VALUE]
    local value_len = string.len(value)
    
    if value_len ~= 16 and value_len ~= 24 and value_len ~= 32  then
        log.output('create_object_secret_key(): VALUE len invalid!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end


    obj = GetSecretKeyTemplate(t.mt.get_secret_key_ds)
    obj.private = true
    obj.value = value
    obj.ds_parent_path = self.ds_info.path_root .. self.ds_df_priv
    
    pTemplate[CKA.LOCAL] = eCK.BBOOL(as_local)
    pTemplate[CKA.MODIFIABLE] = pTemplate[CKA.MODIFIABLE] or eCK.BBOOL(true)
    pTemplate[CKA.DESTROYABLE] = pTemplate[CKA.DESTROYABLE] or eCK.BBOOL(true)
    pTemplate[CKA.ENCRYPT] = pTemplate[CKA.ENCRYPT] or eCK.BBOOL(true)
    pTemplate[CKA.DECRYPT] =  pTemplate[CKA.DECRYPT] or eCK.BBOOL(true)

    -- copy all template attribute to object
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] then
            obj[k] = pTemplate[k]
        end
    end
    obj[CKA.VALUE] = nil -- removes sensistive data
    
    local freeId, freeSlot
    
    local ds_prilist = self.ds_info.ds_prilist
    
    pTemplate[CKA.VALUE] = aes.aes_encrypt_check(self._mk, value, "00000001")
    
    local attr = oberthur_util.serialize_attr_secretkey(pTemplate)
    local fid_val, fid_attr
    
    obj.key_bits = value_len

    -- cerca a partire da id 2 e slot 4
    freeId = oberthur_util.look_for_free_id(oberthur_util.objFIDS.eAESKey, ds_prilist, 2, 1)
    local freeSlots = oberthur_util.look_for_free_slots(ds_prilist, 1, 4)
    
    if freeId == nil or table.getn(freeSlots) == 0 then
        return CKR.DEVICE_MEMORY
    end
    freeSlot = freeSlots[1]
    fid_val = oberthur_util.objFIDS.eAESKey + bin.flags(freeId)
    fid_attr = fid_val + bin.flags('0x100')
    obj.ds_id = string.format('%04X', fid_val.asnumber )  -- fid oggetto DS
    obj.path = obj.ds_parent_path .. string.format('%04X', fid_val.asnumber ) -- path reale del file della chiave

    obj.num = freeId
    obj.slot = freeSlot
    
    -- crea gli attributi della chiave
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
    
    self:write_objlist(false) -- write public list
    
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    return CKR.OK, self.attributes.max_index
    
end


function t.mt:decrypt_buffer_aes(hKey, pMechanism, pEncryptedData, allocated_space)
    log.output(string.format('decrypt_buffer_aes(): hKey=%x', hKey ) )
    log.output(string.format('decrypt_buffer_aes(): pEncryptedData=%s', pEncryptedData and hex.hexify(pEncryptedData) or "<null>" ) )
    log.output(string.format('decrypt_buffer_aes(): allocated_space=%x', allocated_space or -1 ) )
    if pMechanism and pMechanism.mechanism then
        log.output(string.format('decrypt_buffer_aes(): mechanism=%x', pMechanism.mechanism ) )
        log.output(string.format('decrypt_buffer_aes(): parameter=%s', pMechanism.parameter and hex.hexify(pMechanism.parameter) or "<null>"))
    end
    log.output('decrypt_buffer_aes(): pEncryptedData=', pEncryptedData and hex.hexify(pEncryptedData ) or "<null>")
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('decrypt_buffer_aes(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.SECRET_KEY) then
        log.output('decrypt_buffer_aes(): ERROR: not SECRET_KEY object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    if obj[CKA.KEY_TYPE] ~= eCK.ULONG(CKK.AES) then
        log.output('decrypt_buffer_aes(): ERROR: not a AES key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    

    if not obj.value then
        local rv  = self:get_secret_key_ds(hKey, CKA.CLASS)
        if not obj.value then
            log.output('decrypt_buffer_aes(): UNABLE TO READ KEY VALUE!')
            return CKR.FUNCTION_FAILED
        end
    end

    if not pMechanism or (pMechanism.mechanism ~= CKM.AES_CBC and pMechanism.mechanism ~= CKM.AES_CBC_PAD) then
        log.output('decrypt_buffer_aes(): MECHANISM_INVALID:', pMechanism and pMechanism.mechanism )
        return CKR.MECHANISM_INVALID
    end

    if allocated_space==nil then
        local enc_len = math.floor((string.len(pEncryptedData) + (aes.BLOCK_LEN*2) -1) / aes.BLOCK_LEN) * aes.BLOCK_LEN
        log.output('decrypt_buffer_aes(): returning (guessed) encrypted data length:', enc_len)
        return CKR.OK, enc_len
    end
    
    pcall(function()
        log.output('decrypt_buffer_aes(): verify_pin_cns() with:', self.cached_main_pin, self.userType)
        if self.userType == CKU.USER and self.cached_main_pin then
            self.cns_hcard:verify_pin_cns(self.cached_main_pin, false, false, self.ds_info.sm_use2_enc, self.ds_info.sm_use2_sig)
        end
    end)
    self:update_free_mem(self.info)
    
    local iv = pMechanism.parameter and string.sub(pMechanism.parameter, 1, aes.BLOCK_LEN)
    
    if iv and string.len(iv) < aes.BLOCK_LEN then
        log.output('decrypt_buffer_aes(): invalid IV specified, ignoring...')
        iv = nil
    end
    
    local pDataUnpadded, iv = aes.AES_CBC2(obj.value, pEncryptedData, false, iv)
    
    log.output('decrypt_buffer_aes(): pDataUnpadded:', hex.hexify(pDataUnpadded or ""))
    log.output('encrypt_buffer_aes(): iv:', hex.hexify(iv or ""))
    
    if pMechanism.mechanism  == CKM.AES_CBC_PAD then
        log.output('decrypt_buffer_aes(): unpadding:', hex.hexify(pDataUnpadded or ''))
        pDataUnpadded = aes.pkcs5_unpad(pDataUnpadded)
        log.output('decrypt_buffer_aes(): pDataUnpadded unpadded:', hex.hexify(pDataUnpadded or ""))
    end

    collectgarbage()
    return CKR.OK, pDataUnpadded, iv
end


function t.mt:encrypt_buffer(hKey, pMechanism, pData, allocated_space)
    return self:encrypt_buffer_aes(hKey, pMechanism, pData, allocated_space)
end

function t.mt:encrypt_buffer_aes(hKey, pMechanism, pData, allocated_space)
    log.output(string.format('encrypt_buffer_aes(): hKey=%x', hKey ) )
    log.output(string.format('encrypt_buffer_aes(): pData=%s', pData and hex.hexify(pData) or "<null>" ) )
    log.output(string.format('encrypt_buffer_aes(): allocated_space=%x', allocated_space or -1 ) )
    if pMechanism and pMechanism.mechanism then
        log.output(string.format('encrypt_buffer_aes(): mechanism=%x', pMechanism.mechanism ) )
        log.output(string.format('encrypt_buffer_aes(): parameter=%s', pMechanism.parameter and hex.hexify(pMechanism.parameter) or "<null>"))
    end
    log.output('encrypt_buffer_aes(): pData=', pData and hex.hexify(pData ) or "<null>")
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('encrypt_buffer_aes(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.SECRET_KEY) then
        log.output('encrypt_buffer_aes(): ERROR: not SECRET_KEY object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    if obj[CKA.KEY_TYPE] ~= eCK.ULONG(CKK.AES) then
        log.output('encrypt_buffer_aes(): ERROR: not a AES key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end

    if not pMechanism or (pMechanism.mechanism ~= CKM.AES_CBC and pMechanism.mechanism ~= CKM.AES_CBC_PAD) then
        log.output('encrypt_buffer_aes(): MECHANISM_INVALID:', pMechanism and pMechanism.mechanism )
        return CKR.MECHANISM_INVALID
    end

    if not obj.value then
        local rv  = self:get_secret_key_ds(hKey, CKA.CLASS)
        if not obj.value then
            log.output('encrypt_buffer_aes(): UNABLE TO READ KEY VALUE!')
            return CKR.FUNCTION_FAILED
        end
    end
    
    if allocated_space==nil then
        local enc_len = math.floor((string.len(pData) + (aes.BLOCK_LEN*2) -1) / aes.BLOCK_LEN) * aes.BLOCK_LEN
        log.output('encrypt_buffer_aes(): returning (guessed) encrypted data length:', enc_len)
        return CKR.OK, enc_len
    end
    
    local pDataToEnc = pData
    
    if pMechanism.mechanism  == CKM.AES_CBC_PAD then
        pDataToEnc = aes.pkcs5_padding(aes.BLOCK_LEN, pData)
    end
    local iv = pMechanism.parameter and string.sub(pMechanism.parameter, 1, aes.BLOCK_LEN)
    
    if iv and string.len(iv) < aes.BLOCK_LEN then
        log.output('encrypt_buffer_aes(): invalid IV specified, ignoring...')
        iv = nil
    end

    pcall(function()
        log.output('encrypt_buffer_aes(): verify_pin_cns() with:', self.cached_main_pin, self.userType)
        if self.userType == CKU.USER and self.cached_main_pin then
            self.cns_hcard:verify_pin_cns(self.cached_main_pin, false, false, self.ds_info.sm_use2_enc, self.ds_info.sm_use2_sig)
        end
    end)
    self:update_free_mem(self.info)
    
    local result, iv = aes.AES_CBC2(obj.value, pDataToEnc, true, iv)

    log.output('encrypt_buffer_aes(): result:', hex.hexify(result or ""))
    log.output('encrypt_buffer_aes(): iv:', hex.hexify(iv or ""))

    collectgarbage()
    return CKR.OK, result, iv
end



return t


--===========================================================================
end
}
_LOADED['oberthur_util'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
local hex = require 'hex'
local utility = require 'utility'

local t = {}

local ck_false = eCK.BBOOL(false)
function t.is_ck_true(val)
    return type(val) == "string" and string.len(val) > 0 and val ~= ck_false
end


t.objFIDS = {
	eData = bin.flags('0x5000'),
    eDataP = bin.flags('0x6000'),
    
    eCert = bin.flags('0x2000'),
    
    ePubKey = bin.flags('0x1000'),
	ePrivKey = bin.flags('0x3000'),
    
	eDESKey = bin.flags('0x4000'),
	
    ePrivECC = bin.flags('0x7000'),
	ePubECC = bin.flags('0x8000'),
	ePrivEdDSA = bin.flags('0x9000'),
	ePubEdDSA = bin.flags('0xa000'),
	ePrivMONTGOMERY = bin.flags('0xb000'),
	ePubMONTGOMERY = bin.flags('0xc000'),
    
    eAESKey = bin.flags('0xd000'),
    
    eMASK =  bin.flags('0xF000'),
    eNumMASK =  bin.flags('0x00FF'),
}

-- funzioni per la deserializzazione

function t.parse_ds_token_info(token_info)

    -- mandatory:
    --  1-32: 32: LABEL
    --- 33-36: 4:  FLAGS (BIG ENDIAN)
    -- optional:
    -- 37-68: 32: manufacturerID
    -- 69-84: 16: model
    -- 85-88: 4: eccFlags (BIG ENDIAN)
    -- 89-128: 40: RFU
    
    local token_infos = {
                label=string.sub(token_info, 1, 32),
                flags = bin.flags(bin.unpack('%>%L', string.sub(token_info, 33, 36)))
               }
    if string.len(token_info) >= 84 then
        token_infos.manufacturerID = string.sub(token_info, 37, 68)
        token_infos.model = string.sub(token_info, 69, 84)
        log.output("token_infos.manufacturerID 1:", token_infos.manufacturerID )
        log.output("token_infos.model 1:", token_infos.model )
        while string.byte(token_infos.manufacturerID, -1) == 0 do
            token_infos.manufacturerID = string.sub(token_infos.manufacturerID, 1, -2)
        end
        while string.byte(token_infos.model, -1) == 0 do
            token_infos.model = string.sub(token_infos.model, 1, -2)
        end
        if string.len(token_infos.manufacturerID) == 0 then
            token_infos.manufacturerID = nil
        end
        if string.len(token_infos.model) == 0 then
            token_infos.model = nil
        end
        
        log.output("token_infos.manufacturerID 2:", token_infos.manufacturerID )
        log.output("token_infos.model 2:", token_infos.model )
    end
    if string.len(token_info) >= 88 then
        token_infos.eccFlags = bin.flags(bin.unpack('%>%L', string.sub(token_info, 85, 88)))
    end
    if string.len(token_info) >= 89 then
        token_infos.rfu = string.sub(token_info, 89, -1)
    end
    return token_infos
end

function t.parse_ds_objlist(ds_objlist)
    local i
    local infos = {}
    
    for i=0, (string.len(ds_objlist)/5)-1 do
        local item = {
                        index = i+1,
                        usage=string.byte(ds_objlist, i*5 +1), 
                        id = string.sub(ds_objlist, i*5 +2, i*5 +3), 
                        id_numeric = string.byte(ds_objlist, i*5 +2)*2^8 + string.byte(ds_objlist,i*5 +3), 
                        infos = string.byte(ds_objlist, i*5 +4)*2^8 + string.byte(ds_objlist, i*5 +5),
                      }
        --print (utility.repr(item))
        if (item.usage == 255) then
            -- log.output(item.index, item.usage, hex.hexify(item.id),item.id_numeric, item.infos)
            -- log.output(bin.flags(item.id_numeric) * t.objFIDS.eMASK)
        end
        infos[i+1] = item
    end
    return infos
end



function t.parse_ds_data_attribute(card, file_path)
    local obj = {}
    local infos = card:select(file_path, true)
    if not infos then infos = {size=240} end
    
    local buf
    if infos.size == 48 then
        buf = card:mread_binary(0, 32) .. card:mread_binary(32, 16)
    else
        buf = card:mread_binary(0, infos.size)
    end
    
    local flags = string.sub(buf, 1, 2)
    --print('flags:', hex.hexify(flags))
    obj.flags = bin.flags(bin.unpack("%H", flags ))
    local fields = utility.LV_get(buf, 2, 3)
    obj.label = fields[1]
    obj.appId = fields[2]
    obj.objId = fields[3]
    return obj
end

function t.parse_ds_cert_attribute(card, file_path)
    local obj = {}
    local infos = card:select(file_path, true)
    if not infos then infos = {size=240} end
    local buf
    if infos.size == 48 then
        buf = card:mread_binary(0, 32) .. card:mread_binary(32, 16)
    else
        buf = card:mread_binary(0, infos.size)
    end
    
    return t.parse_ds_cert_attribute_val(buf), buf
end

function t.parse_ds_cert_attribute_val(buf)
    local obj = {}

    local flags = string.sub(buf, 1, 2)
    --print('flags:', hex.hexify(flags))
    obj.flags = bin.flags(bin.unpack("%H", flags ))
    local fields = utility.LV_get(buf, 2, 5)
    obj.label = fields[1]
    obj.id = fields[2]
    obj.subject = fields[3]
    obj.issuer = fields[4]
    obj.serialnumber = fields[5]
    if string.len(obj.subject) == 0 then
        obj.subject = nil
        log.output('parse_ds_cert_attribute(): forcing subject unset')
    end
    if string.len(obj.issuer) == 0 then
        obj.issuer = nil
        log.output('parse_ds_cert_attribute(): forcing issuer unset')
    end
    if string.len(obj.serialnumber) == 0 then
        obj.serialnumber = nil
        log.output('parse_ds_cert_attribute(): forcing serialnumber unset')
    end
    return obj
end

function t.parse_ds_pubkey_attribute(card, file_path)
    local obj = {}
    local infos = card:select(file_path, true)
    if not infos then infos = {size=240} end
    local buf

    if infos.size == 48 then
        buf = card:mread_binary(0, 32) .. card:mread_binary(32, 16)
    else
        buf = card:mread_binary(0, infos.size)
    end
    return t.parse_ds_pubkey_attribute_val(buf), buf
    
end
    
function t.parse_ds_pubkey_attribute_val(buf)
    local obj = {}
    
    local flags = string.sub(buf, 1, 2)
    --print('flags:', hex.hexify(flags))
    obj.flags = bin.flags(bin.unpack("%H", flags ))
    local fields = utility.LV_get(buf, 2, 2)
    local newOffset = 2 + string.len(fields[1])+2 + string.len(fields[2]) +2
    obj.label = fields[1]
    obj.id = fields[2]
    obj.startdate = string.sub(buf, newOffset+1, newOffset+8)
    --print("startdate:", obj.startdate)
    obj.enddate = string.sub(buf, newOffset+9, newOffset+16)
    --print("enddate:", obj.enddate)
    newOffset = newOffset +16
    obj.subject = utility.LV_get(buf, newOffset, 1 )[1]
    newOffset = newOffset + 2 + string.len(obj.subject)
    if string.len(buf) > newOffset then
        obj.modulus = utility.LV_get(buf, newOffset, 1 )[1]
        newOffset = newOffset + 2 + string.len(obj.modulus)
        obj.pubexp = utility.LV_get(buf, newOffset, 1 )[1]
        newOffset = newOffset + 2 + string.len(obj.modulus)
    end
    
    return obj
end

function t.parse_ds_privkey_attribute(card, file_path, modulus_size)
    local obj = {}
    local infos = card:select(file_path, true)
    if not infos then infos = {size=240} end
    local buf
    if infos.size == 48 then
        buf = card:mread_binary(0, 32) .. card:mread_binary(32, 16)
    else
        buf = card:mread_binary(0, infos.size)
    end
    return t.parse_ds_privkey_attribute_val(buf, modulus_size), buf
end

function t.parse_ds_privkey_attribute_val(buf, modulus_size)
    local obj = {}

    
    local flags = string.sub(buf, 1, 2)
    --print('flags:', hex.hexify(flags))
    obj.flags = bin.flags(bin.unpack("%H", flags ))
    local fields = utility.LV_get(buf, 2, 2)
    local newOffset = 2 + string.len(fields[1])+2 + string.len(fields[2]) +2
    obj.label = fields[1]
    obj.id = fields[2]
    obj.startdate = string.sub(buf, newOffset+1, newOffset+8)
    --print("startdate:", obj.startdate)
    obj.enddate = string.sub(buf, newOffset+9, newOffset+16)
    --print("enddate:", obj.enddate)
    newOffset = newOffset +16
    obj.subject = utility.LV_get(buf, newOffset, 1)[1]
    newOffset = newOffset + 2 + string.len(obj.subject)
    obj.modulus = string.sub(buf, newOffset+1, newOffset+modulus_size)
    newOffset = newOffset + modulus_size
    -- nota: nel public exponent la lunghezza del campo 