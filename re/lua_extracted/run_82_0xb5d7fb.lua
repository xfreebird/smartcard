 necessario cancellare la chiave privata
        elseif obj.isp11 then
            log.output('destroy_object(): P11 PUBLIC_KEY')
            local the_attributes = {attrTypes.eMain, attrTypes.ePubKeyModExp, attrTypes.eLabel, attrTypes.eID, attrTypes.eSubject}
            for i, k in the_attributes do
                table.insert(files_delete, {path=hexf('4fff'), fid=hexf('%H', self:buildP11Fid(obj.num, objTypes.ePubKey, k) ) } )
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
                table.insert(files_delete, {path=hexf('4fff'), fid=hexf('%H', self:buildP11Fid(obj.num, objTypes.ePrivKey, k) ) } )
            end
            table.insert(bso_delete, {path=hexf('4fff'), fid=hexf('21%B', obj.kid) } )
            table.insert(bso_delete, {path=hexf('4fff'), fid=hexf('20%B', obj.kid) } )
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
                table.insert(files_delete, {path=hexf('4fff'), fid=hexf('%H', self:buildP11Fid(obj.num, objTypes.eData, k) ) } )
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
            self.cns_hcard:delete_file_athena(v.fid, true)
        end)
    end
    for i, v in bso_delete do
        pcall(function()
            self.cns_hcard:select(v.path)
            self.cns_hcard:delete_bso_athena(v.fid)
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
    local rv
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hObject]
    if obj == nil then
        log.output('set_attribute_value(): specified handle invalid: ' .. hObject)
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
    
    log.output('set_attribute_value(): verify_pin_cns() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.cns_hcard:verify_pin_cns(self.cached_main_pin, false, true)
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
        self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eSubject, pTemplate[CKA.ISSUER], true )
    end
    
    if (pTemplate[CKA.SERIAL_NUMBER]) then
        self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eSubject, pTemplate[CKA.SERIAL_NUMBER], true )
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
    local data_mainfile = self:pubkey_serialize_mainfile(templateNew, obj.num, obj.key_bits)
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
        [1] = self.ds_info and (self.ds_info.path_root .. "11ce") or '4fff0001'
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

function t.mt:flush_cache()
    if self.cfg["xproc"] ~= "true" then
        return false
    end
    local changed, cache_id
    if self._cache_id == nil then
        changed, self._cache_id = utility.has_token_changed(self, "cache", 0)
        log.output("token-athena:flush_cache(): initialize: _cache_id:", self._cache_id)
    end
    changed, cache_id = utility.has_token_changed(self, "cache", self._cache_id)
    if changed then
        log.output("token-athena:flush_cache(): token has changed!")
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
_LOADED['token-arjo'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- token-arjo.lua
local ArjoSmartCard = require 'ArjoSmartCard'
local hex = require 'hex'
local zlib = require "zlib"
local hexf = hex.hexf
local der = require 'der'
local p15 = require 'p15util'
local utility = require 'utility'
local repr = utility.repr
local rsa = require("rsa")
local aes = require("aes")

local licensing = require  'licensing'

local MinKSize, MaxKSize = 1024, 3072
local t = {
    name = 'arjo',
    mt = { },
    mechanisms = {
        [ CKM.RSA_PKCS_KEY_PAIR_GEN ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.GENERATE_KEY_PAIR},
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_X_509 ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.DECRYPT+CKF.SIGN},
    },
    arjo_hcard = nil,
    -- le chiavi DS Arjo sono protette da un singolo PIN
    capabilities = { private_attributes_readable=false, always_authenticate_on_cert=false, },
    ArjoSmartCard=ArjoSmartCard,
    dsMask = bin.flags("0x50"),
    authMask = bin.flags("0x20"),
}
t.mt.__index = t.mt


function t.mt:initialize(cfg)
    log.output('token-arjo:initialize():')
    local files = {}
    self.files = files
    files.OD = hexf("5031")
    files.US = hexf("5033")
    files.PrivKD = hexf("5130")
    files.PubKD = hexf("5135")
    files.CDF = hexf("5137")
    files.AODF = hexf("5134")
    files.tokenInfo = hexf("5032")
    files.License = hexf("023A") -- was 11CE
    -- files.VarPass = hexf("0039")
    
    local arjoCfgPath = modules.modulepath().. ".aconf"
    
    -- Cleartext MK: D63806F4C71860209F28ED0550EEBFFA203D656A2A2C68FA79685228BBA65C1F
    local mKey = sm.sm_ask_keys(10)  -- richiede la chiave #10, master key per cifratura chiavi
    -- decodifica MK arjo per decifrare MK MW
    local MK = sm.des3_dec(mKey, hex.hexf('3742936FF16AFD89B34DF0F9A69' .. '9D45B979516F71263FA114211CA96AF26196539A1165298FE8C73'))
    
    local s = md.sha256()
    s:update(MK .. "00000001")
    local MKSha2 = s:final()
    
    local arjocfg = utility.parse_cfg(arjoCfgPath)
    local cacerts = {}

    for i=1,100 do
        local ca = arjocfg[string.format("ca%d", i)]
        if not ca then
            break
        end
        local pcRes, theErrorT= pcall(function()
            ca = hex.hexf(ca)
            ca = sm.aes_dec_cbc(MKSha2, ca)
            table.insert(cacerts, ca)
            log.output("added card ca cert:", hex.hexify(ca))
        end)
        if not pcRes then
            log.output("CA cert error:", theErrorT)
        end
    end


    self.capabilities = utility.clone_table(t.capabilities)
    self.arjo_hcard = ArjoSmartCard.new(self.hcard)
    self.arjo_hcard.allow_6310_chained_responses = true
    self.arjo_hcard.BSO_PIN = hex.h2i('81')
    self.arjo_hcard.BSO_PUK = hex.h2i('82')
    if table.getn(cacerts) > 0 then
        self.arjo_hcard:set_card_ca_certs(cacerts)
    end
    
    if arjocfg["seed"] then
        local pcRes, theErrorT = pcall(function()

            -- decifra e decodifica MK MW
            local seed = hex.hexf(arjocfg["seed"])
            seed = string.sub(seed, 3, -1)
            -- log.output('Arjo token initialize(): MK=', hex.hexify(MK))
            -- log.output('Arjo token initialize(): seed=', hex.hexify(seed))
            
            local d = aes.AES_CBC(MK, seed)
            if string.byte(d, 1) == 4 then
                -- imposta MK MW
                self.arjo_hcard.mw_mk = string.sub(d, 3, 2+string.byte(d, 2))
                log.output('Arjo token initialize(): mw_mk', hex.hexify(self.arjo_hcard.mw_mk))
            end
        end)
        if not pcRes then
            log.output('Arjo token initialize(): error reading seed', theErrorT)
        end
    end
    MK=nil
    MKSha2=nil
    mKey=nil
    collectgarbage()
    self.mechanisms = utility.clone_table(t.mechanisms)
    
    self.slow_card = false
    self.userPinInitialized = true
    self.request_plugin_valid = w32.request_plugin_valid()
    self.cfg = cfg or utility.parse_cfg()
    
    self.cfg["fcpr"] = self.cfg["fcpr"] or self.cfg["ajfcpr"]
    self.cfg["xproc"] = self.cfg["xproc"] or self.cfg["ajxproc"]
    
    if self.cfg["fcpr"] then
        self.cfg["fcpr"]=string.lower(self.cfg["fcpr"])
        self.use_cpr_mode = self.cfg["fcpr"] == "true"
        -- se non specificato non si attiva mai
    end
    
    if self.cfg["xproc"] then self.cfg["xproc"]=string.lower(self.cfg["xproc"])
    else self.cfg["xproc"]='true' end
    
    log.output('Arjo token initialize(): use_cpr_mode:', self.use_cpr_mode)
    
    if self._cache_id == nil then
        self:flush_cache()
    end

end

function t.mt:begin_transaction()
    self.arjo_hcard:begin_transaction()
end

function t.mt:end_transaction()
    self.arjo_hcard:end_transaction()
end

function t.mt:_call_on_end_transaction()
    log.output('token-arjo:_call_on_end_transaction()...')
    self.arjo_hcard:on_end_transaction()
end


function t.mt:finalize()
    log.output("token-arjo:finalize():", self.userType)
    utility.forget_token_changed(self, "cache")
end

function t.mt:_update_retry_counters()

end


function t.mt:add_info()
    log.output('add_info(): performing mutual authenticate...')
    self.arjo_hcard:auto_perform_mutual_authenticate()
    local sn = string.upper(hex.hexify(self.arjo_hcard:read_serial_number()))
    
    local model;
    local pcRes, theErrorT = pcall(function()
        model = self.arjo_hcard:read_model()
        self.info.model = model or self.info.model
        self.info.model = string.sub(self.info.model, 1, 16)
    end)
    if not pcRes then
        log.output("add_info(): read_model error", theErrorT)
    end
    self.info.serialNumber = string.sub(sn, -16, -1)

    local finfos = self.arjo_hcard:select(self.files.OD, true, true)  -- fid, relative, sm
    local odf = self.arjo_hcard:mread_binary(0, finfos.size, true)
    local odfParsed = der.parse(odf)
    
    for i=1,table.getn(odfParsed) do
        if odfParsed[i].tag == 160 then
            self.files.PrivKD = string.sub(odfParsed[i].value, 3, 4)
            log.output("add_info(): PrivKD FID", hex.hexify(self.files.PrivKD))
        elseif odfParsed[i].tag == 161 then
            self.files.PubKD = string.sub(odfParsed[i].value, 3, 4)
            log.output("add_info(): PubKD FID", hex.hexify(self.files.PubKD))
        elseif odfParsed[i].tag == 164 then
            self.files.CDF = string.sub(odfParsed[i].value, 3, 4)
            log.output("add_info(): CDF FID", hex.hexify(self.files.CDF))
        elseif odfParsed[i].tag == 168 then
            self.files.AODF = string.sub(odfParsed[i].value, 3, 4)
            log.output("add_info(): AODF FID", hex.hexify(self.files.AODF))
        end
    end
    local finfos = self.arjo_hcard:select(self.files.tokenInfo, true, true)  -- fid, relative, sm
    local tib = self.arjo_hcard:mread_binary(0, finfos.size, true)
    local tokenInfos = p15.parse_tokenInfo(tib)
    
    if type(tokenInfos.serialNumber) == "string" then
        if string.len(tokenInfos.serialNumber) < 16 then
            self.info.serialNumber = hex.hexify(tiStruct.serialNumber)
        end
        self.info.serialNumber = string.sub(tokenInfos.serialNumber, -16, -1)
        log.output("parse_tokenInfo(): serialNumber=", self.info.serialNumber)
    end
    
    self.info.manufacturerID = tokenInfos.manufacturerID or self.info.manufacturerID
    self.info.label = tokenInfos.label or self.info.label
    
    self:_read_token_info_indexes()
    if self.userPinInitialized then
        self.info.flags = self.info.flags + CKF.USER_PIN_INITIALIZED
    else
        self.info.flags = self.info.flags - CKF.USER_PIN_INITIALIZED
    end
    
    local licValid, license
    licValid, license = licensing.is_licensed(self, self.info.serialNumber)
    if licValid then
        self.license = license
    end
        
    self:_update_retry_counters()
end

function t.mt:_get_license()
    log.output("_get_license()...")
    local finfos = self.arjo_hcard:select(self.files.License, true, true)  -- fid, relative, sm
    
    local licenseContents = self.arjo_hcard:mread_binary(0, finfos.size, true)
    local license_len = bin.unpack('%H', string.sub(licenseContents, 1, 2))
    local res = string.sub(licenseContents, 3, license_len+2)
    log.output("_get_license(): done!: ", hex.hexify(res))
    return res
end

function t.mt:update_free_mem(info)

end

function t.mt:get_info()
    if not self.info then
        self.info = {
            label = 'Arjosystems SSCD',
            manufacturerID = 'Arjosystems S.p.a.',
            model = 'SSCD',
            serialNumber = '0000000000000000',
            flags = CKF.RNG + CKF.LOGIN_REQUIRED +
                    CKF.USER_PIN_INITIALIZED + CKF.TOKEN_INITIALIZED,
            ulMaxSessionCount = CK.EFFECTIVELY_INFINITE,
            ulSessionCount = 0,
            ulMaxRwSessionCount = CK.EFFECTIVELY_INFINITE,
            ulRwSessionCount = CK.UNAVAILABLE_INFORMATION,
            ulMaxPinLen = 8,
            ulMinPinLen = 6,
            ulTotalPublicMemory = 65536,
            ulFreePublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulTotalPrivateMemory = 65536,
            ulFreePrivateMemory = CK.UNAVAILABLE_INFORMATION,
            hardwareVersion = { major=3, minor=0},
            firmwareVersion = { major=3, minor=0},
            utcTime = '0000000000000000'
        }
        
        self:add_info()
        self:update_free_mem(self.info)      
        if self.cfg["ajdefaultlabel"] then
            self.info.label = self.cfg["ajdefaultlabel"]
        end
        self.info.ulMaxPinLen = self._userPinMaxLen or self.info.ulMaxPinLen
        self.info.ulMinPinLen = self._userPinMinLen or self.info.ulMinPinLen

    end
    
    if self._schedule_update_retry_counters then
        self._schedule_update_retry_counters = false
        self:_update_retry_counters()
    end
    return self.info
end

function t.mt:get_mechanisms()
    local info = self:get_info()
    return self.mechanisms
end

function t.mt:verify_pin(pin, userType, contextual_obj)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk = false
    local result
    if userType == CKU.SO then 
        ispuk = true
    end
    log.output("verify_pin()", pin, userType, ispuk, contextual_obj)
    
    self.arjo_hcard:auto_perform_mutual_authenticate()
    self._schedule_update_retry_counters = true
    
    result = self.arjo_hcard:verify_pin_main(pin, ispuk) -- pin, ispuk
    log.output("verify_pin_main(): result=", result)
    if result == 0 then
        self.cached_main_pin = pin
        self.userType = userType
        self.cached_ds_pin = nil
        
        if self.attributes == nil then
            self.attributes = self:get_objects()
        else
            self:_add_private_objects(self.attributes)
        end
        return CKR.OK
    end
    
    if result == 1 then
        return CKR.PIN_INCORRECT
    elseif result == 2 then
        return CKR.PIN_LOCKED
    else
        return CKR.FUNCTION_FAILED
    end
end

function t.mt:unverify_pin()
    -- per il momento non fa niente, potrebbe essere configurata per il reset della carta, se necessario
    self.cached_main_pin = nil
    self.userType = nil
    self.cached_ds_pin = nil
end

function t.mt:change_pin(oldPin, newPin)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk = false
    if self.userType == CKU.SO then ispuk = true end
    local pcRes, result
    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-arjo change_pin(): oldPin:' .. oldPin, 'newPin:' .. newPin)

    if newPin and (string.len(newPin) < info.ulMinPinLen or string.len(newPin) > info.ulMaxPinLen) then
        log.output('token-arjo change_pin(): value not in range:', info.ulMinPinLen, info.ulMaxPinLen)
        return CKR.PIN_LEN_RANGE   
    end
    if ispuk and self.puk_not_modifiable then
        log.output('token-arjo change_pin(): PUK not modifiable!')
        return CKR.PIN_LEN_RANGE
    end
    local rv
    log.output('token-arjo change_pin(): cambio pin MAIN...')

    self._schedule_update_retry_counters = true
    
    self.arjo_hcard:auto_perform_mutual_authenticate()
    pcRes, result = pcall(function() 
            return self.arjo_hcard:change_pin_main(oldPin, newPin, ispuk) -- oldPin, newPin, ispuk, use_sm
        end)

    if result == 0 then
        -- la carta potrebbe dimenticare lo stato di logged in quando si effettua una change pin
        self.cached_main_pin = newPin
        pcRes, result = pcall(function()    
                return self.arjo_hcard:verify_pin_main(newPin, ispuk)  -- pin, ispuk, check, use_sm
            end)
        return CKR.OK
    elseif result == 1 then
        return CKR.PIN_INCORRECT
    elseif result == 2 then
        return CKR.PIN_LOCKED
    else
        return CKR.FUNCTION_FAILED
    end
end

function t.mt:reset_pin(newPin)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local pcRes, result
    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-arjo reset_pin(): newPin:', newPin)
    log.output('token-arjo reset_pin(): reset pin MAIN...')
    if self.userType ~= CKU.SO then
        log.output('token-arjo reset_pin(): user not SO!')
        return CKR.USER_TYPE_INVALID
    end
    
    local rv

    self._schedule_update_retry_counters = true
    
    if newPin and (string.len(newPin) < info.ulMinPinLen or string.len(newPin) > info.ulMaxPinLen) then
        log.output('token-arjo reset_pin(): value not in range:', info.ulMinPinLen, info.ulMaxPinLen)
        return CKR.PIN_LEN_RANGE   
    end
    
    self.arjo_hcard:auto_perform_mutual_authenticate()
    pcRes, result = pcall(function()
        return self.arjo_hcard:reset_pin_main(self.cached_main_pin, newPin) -- Puk, newPin
        end)
    if pcRes and result == 0 then
        pcRes, result = pcall(function()
            return self.arjo_hcard:verify_pin_main(newPin, false) -- pin, ispuk
        end)
    end

    if result == 0 then
        return CKR.OK
    elseif result == 1 then
        return CKR.PIN_INCORRECT
    elseif result == 2 then
        return CKR.PIN_LOCKED
    else
        return CKR.FUNCTION_FAILED
    end
end



--=====================================================================================

function t.mt:sign_buffer(hKey, pMechanism, pData, allocated_space)
    
    log.output('sign_buffer():', hKey, pMechanism, hex.hexify(pData or ''), allocated_space)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('sign_buffer(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('sign_buffer(): ERROR: non private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    local pcRes, result
    local rawSign = false
    if dataLen == keyBytes then
        log.output('sign_buffer(): special case: RAW SIGNATURE, dataLen==keyBytes, unpadding PKCS#1 padded data')
        pData = rsa.pkcs1_unpad(pData) or pData
        dataLen = string.len(pData)
        rawSign=true
    end
    if dataLen > keyBytes or (dataLen > (keyBytes -4) and dataLen <  keyBytes) then
        -- nota: il padding pkcs1 richiede almeno 8 byte di oxFF prima dei dati da firmare
        log.output('sign_buffer(): specified data len invalid: ', dataLen)
        return CKR.DATA_LEN_RANGE
    end
    
    if not self.license then
        log.output('sign_buffer(): not licensed!')
        return CKR.GENERAL_ERROR
    end
    if allocated_space==nil then
        log.output('sign_buffer(): returning signature length:', keyBytes)
        return CKR.OK, keyBytes
    else
        self.arjo_hcard:auto_perform_mutual_authenticate()
        
        if self.cached_main_pin then 
            self.arjo_hcard:verify_pin_main(self.cached_main_pin, false) -- pin, ispuk
        end
        
        
        log.output('sign_buffer(): try RSA-INTERNAL-AUTH mode on kid:', obj.kid, "userConsent:", obj.userConsent)        
        pcRes, result = pcall(function()
                    return self.arjo_hcard:pso_internal_auth(
                        pData, obj.kid)
                    end )
        if pcRes then
            return CKR.OK, result
        else
            log.output("sign_buffer: pso_internal_auth error:", result)
        end
        
        log.output('sign_buffer(): fallback to RSA-CDS mode on kid:', obj.kid, "userConsent:", obj.userConsent)        

        pcRes, result = pcall(function()
                        return self.arjo_hcard:pso_cds(
                            pData,
                            obj.kid
                            )
                        end )
        if pcRes then
            return CKR.OK, result
        end
        
    end
    log.output('sign_buffer(): unexpected!')
    return CKR.FUNCTION_FAILED
end


function t.mt:decrypt_buffer(hKey, pMechanism, pData, allocated_space)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('decrypt_buffer(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('decrypt_buffer(): ERROR: not a private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    -- if not obj.pso_dec then
        -- log.output('decrypt_buffer(): ERROR: decrypt not supported!')
        -- return CKR.KEY_TYPE_INCONSISTENT -- todo: errore non adatto
    -- end
    if type(obj.kid) == 'function' then
        local rv = obj.kid(self, hKey, CKA.CLASS, false)
        if rv ~= CKR.OK then return rv end
    end
    
    local keyBytes
    if type(obj.key_bits) == 'function' then    
        obj.key_bits(self, hKey, CKA.CLASS)
        keyBytes = obj.key_bits/8
    elseif type(obj.key_bits) == 'number' then
        keyBytes = obj.key_bits/8
    else
        keyBytes = 128
    end
    
    local dataLen = string.len(pData)
    if dataLen ~= keyBytes then
        log.output('decrypt_buffer(): specified data len invalid: ', dataLen, ', expected:', keyBytes)
        return CKR.ENCRYPTED_DATA_LEN_RANGE
    end

    self.arjo_hcard:auto_perform_mutual_authenticate()
    log.output('sign_buffer(): using RSA-CDS mode on kid:', obj.kid, "userConsent:", userConsent)        
    
    if self.cached_main_pin then 
        self.arjo_hcard:verify_pin_main(self.cached_main_pin, false) -- pin, ispuk
    end
    
    local pcRes, result = pcall(function()
                        return self.arjo_hcard:pso_dec(pData, obj.kid)
                        end )
        local last_sw = self.arjo_hcard.last_sw
        if pcRes then
            return CKR.OK, result
        end

    return CKR.FUNCTION_FAILED
end


-- se search_state.lastobj==nil si richiede l'handle del primo oggetto che risponda
-- al template. Altrimenti restituisce il primo oggetto che sia
-- compatibile con il template e abbia handle>search_state.lastobj.
-- quando non ci sono pi