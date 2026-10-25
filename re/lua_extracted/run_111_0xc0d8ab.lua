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



local function GetDataObjectTemplate(populateKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.DATA),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(true),
        [ CKA.LABEL ] = populateKeyFunc,
        -- Data
        [ CKA.VALUE ] = populateKeyFunc,
        [ CKA.APPLICATION ] = populateKeyFunc,
        -- [ CKA.OBJECT_ID ] = populateKeyFunc,
    }
end

local function GetCertTemplate(populateCertFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.CERTIFICATE),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(false),
        [ CKA.LABEL ] = '',
        -- Certificate
        [ CKA.CERTIFICATE_TYPE ] = eCK.CERTIFICATE_TYPE(CKC.X_509),
        [ CKA.TRUSTED ] = eCK.BBOOL(true),
        [ CKA.CERTIFICATE_CATEGORY ] = eCK.ULONG(1), -- user
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        -- Certificate X.509
        [ CKA.SUBJECT ] = populateCertFunc,
        [ CKA.ID ] = '',
        [ CKA.ISSUER ] = populateCertFunc,
        [ CKA.SERIAL_NUMBER ] = populateCertFunc,
        [ CKA.VALUE ] = populateCertFunc,
        [ CKA.URL ] = '',
        [ CKA.HASH_OF_SUBJECT_PUBLIC_KEY ] = '',
        [ CKA.HASH_OF_ISSUER_PUBLIC_KEY ] = '',
        [ CKA.JAVA_MIDP_SECURITY_DOMAIN ] = eCK.ULONG(0),
    }
end

local function GetPubKeyTemplate(populatePubKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PUBLIC_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(false),
        [ CKA.LABEL ] = '',
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = '',
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = eCK.BBOOL(false),
        [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.RSA_PKCS_KEY_PAIR_GEN),
        -- [ CKA.ALLOWED_MECHANISMS ] = '',
        -- Public Key
        [ CKA.SUBJECT ] = '',
        [ CKA.ENCRYPT ] = eCK.BBOOL(true),
        [ CKA.VERIFY ] = eCK.BBOOL(true),
        [ CKA.VERIFY_RECOVER ] = eCK.BBOOL(false),
        [ CKA.WRAP ] = eCK.BBOOL(false),
        [ CKA.TRUSTED ] = eCK.BBOOL(true),
        -- [ CKA.WRAP_TEMPLATE ] = '',
        -- RSA Public Key
        [ CKA.MODULUS ] = populatePubKeyFunc,
        [ CKA.MODULUS_BITS ] = populatePubKeyFunc,
        [ CKA.PUBLIC_EXPONENT ] = populatePubKeyFunc,
    }
end

local function GetPrivKeyTemplate(populatePubKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PRIVATE_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(false),
        [ CKA.LABEL ] = '',
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = '',
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = eCK.BBOOL(true),
        [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.RSA_PKCS_KEY_PAIR_GEN),
        -- [ CKA.ALLOWED_MECHANISMS ] = '',
        -- Private Key
        [ CKA.SUBJECT ] = '',
        [ CKA.SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.DECRYPT ] = eCK.BBOOL(false),
        [ CKA.SIGN ] = eCK.BBOOL(true),
        [ CKA.SIGN_RECOVER ] = eCK.BBOOL(false),
        [ CKA.UNWRAP ] = eCK.BBOOL(false),
        [ CKA.EXTRACTABLE ] = eCK.BBOOL(false),
        [ CKA.ALWAYS_SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.NEVER_EXTRACTABLE ] = eCK.BBOOL(true),
        [ CKA.WRAP_WITH_TRUSTED ] = eCK.BBOOL(false),
        -- [ CKA.UNWRAP_TEMPLATE ] = '',
        [ CKA.ALWAYS_AUTHENTICATE ] = eCK.BBOOL(true),
        -- RSA Private Key
        [ CKA.MODULUS ] = populatePubKeyFunc,
        [ CKA.PUBLIC_EXPONENT ] = populatePubKeyFunc,
        [ CKA.PRIVATE_EXPONENT ] = -1,
        [ CKA.PRIME_1 ] = -1,
        [ CKA.PRIME_2 ] = -1,
        [ CKA.EXPONENT_1 ] = -1,
        [ CKA.EXPONENT_2 ] = -1,
        [ CKA.COEFFICIENT ] = -1,
    }
end



local function parseCertificate(binary)
    local cert_object_id_1 = 0;
    local cert_object_id_2 = 0;
    local sign_cert = ""
    local auth_cert = ""
    local index = 3;
    local indexPre
    local element_length = 0;
    local tag = 0;

    -- ----/ parsing fixed part
    log.output("parseCertificate():", hex.hexify(binary))
    while true do
        tag = string.byte(binary, index)
        indexPre = index
        log.output( "parseCertificate(): TAG:", tag)
        if tag == 0 then
            -- end of the fixed part
            if (cert_object_id_1 == 0 or cert_object_id_2 == 0) then
                log.output("parseCertificate(): Cannot localize certificates, cert object ids are not found");
            end
            break
        elseif tag == 5 then -- it is a certificate
            if cert_object_id_1 == 0 then
                cert_object_id_1 = string.byte(binary, index + 3);
            else
                cert_object_id_2 = string.byte(binary, index + 3);
            end
        end
        -- get next tag.
        if tag == 5 or tag == 3 or tag == 1 then
            index = index + 5;
        else
            index = index + 4;
        end
        log.output("parseCertificate(): VAL:", string.sub(binary, indexPre,index))
    end
    
    log.output("parseCertificate(): cert_object_id_1:", cert_object_id_1)
    log.output("parseCertificate(): cert_object_id_2:", cert_object_id_2)
    -- the fixed part ends by 00 00 00
    index = index + 3;

    -- ----/ parsing variable part every element is in this format
    -- {element_data_length, , element_data}
    -- ----/ if the element_data_length is > than 0x80, the length will be
    -- on two bytes 8X XX

    while true do
        if index >= string.len(binary) then
            return
        end
        
        local tmp = (bin.flags(string.byte(binary, index)) * bin.flags("0xFF")).asnumber
        local tmp1 = (bin.flags(string.byte(binary, index +1)) * bin.flags("0xFF")).asnumber
        if tmp > 128 then -- the length is on two bytes
            -- element_length = (binary[index]&0x0F)*16*16 + binary[index +
            -- 1];
            element_length = (bin.flags(tmp) * bin.flags("0x0F")).asnumber * 16 * 16 + tmp1;
            index = index +1;
        else
            element_length = tmp;
        end
        index = index +1;

        -- check the object id
        log.output("parseCertificate(): obj ID:", string.byte(binary, index) )
        log.output("parseCertificate(): obj VAL:", hex.hexify(string.sub(binary, index + 1, index + 1 + element_length)))
        
        if string.byte(binary, index) == cert_object_id_1 and element_length > 128 then
            auth_cert = string.sub(binary, index + 1, index + 1 + element_length)
        end
        if string.byte(binary, index) == cert_object_id_2 and element_length > 128 then
            sign_cert = string.sub(binary, index + 1, index + 1+ element_length)
           break
        end
        index = index + element_length + 1
    end
    
    return auth_cert, sign_cert
end


function t.mt:_read_token_info_indexes()
    local info
    if not self.main_index then
        info = self.eida_hcard:select(self.files.CERTIFICATES, true, false)  -- fid, relative, sm
        self.main_index = self.eida_hcard:mread_binary(0, info.size, false)
        self.authCert, self.signCert = parseCertificate(self.main_index)
        
        pcall(function() self.authCertP = der.parse_x509cer(self.authCert) end )
        pcall(function() self.signCertP = der.parse_x509cer(self.signCert) end )
        
    end
end

function t.mt:_read_indexes()
    self:_read_token_info_indexes()
end


function t.mt:is_user_consent_key(kid)
    if kid == 3 then
        return true
    end
    return false
end


function t.mt:_add_objects(objects)
    if self._objects_added then
        return
    end
    self:_read_indexes()
    if self.authCertP then
        local obj = GetCertTemplate(function() end)
        obj.private = false
        obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
        obj[CKA.LABEL] = "AUTH CERT"
        obj[CKA.ID] = "AUTH"
        obj[CKA.VALUE] = self.authCert or obj[CKA.VALUE]
        obj[CKA.SUBJECT] = (self.authCertP.subject) or ''
        obj[CKA.ISSUER] = (self.authCertP.issuer) or ''
        obj[CKA.SERIAL_NUMBER] = (self.authCertP.serialNumber) or ''
        obj.path = ""
        obj.num = 3
        objects.max_index = objects.max_index +1
        objects[ objects.max_index] = obj
        log.output(
            string.format("_add_objects(): added certificate: num:%d handle:%d", 
                obj.num, objects.max_index)
            )
            
        local obj = GetPrivKeyTemplate(function() end)
        obj.private = true
        obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
        obj[CKA.LABEL] = "AUTH Priv KEY"
        obj[CKA.ID] = "AUTH"
        obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(self:is_user_consent_key(obj.kid))
        obj[CKA.MODULUS] = self.authCertP.modulus
        obj[CKA.PUBLIC_EXPONENT] = self.authCertP.pubexp
        obj[CKA.MODULUS_BITS] = eCK.ULONG(string.len(obj[CKA.MODULUS]) * 8)
        obj.kid = 3
        obj.key_bits = string.len(obj[CKA.MODULUS]) * 8
        obj.num = 3
        objects.max_index = objects.max_index +1
        objects[ objects.max_index] = obj
        log.output(
            string.format("_add_objects(): added private key: num:%d kid:%d bits:%d handle:%d", 
                obj.num, obj.kid, obj.key_bits, objects.max_index)
            )
            
        local obj = GetPubKeyTemplate(function() end)
        obj.private = false
        obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
        obj[CKA.LABEL] = "AUTH Pub Key"
        obj[CKA.ID] = "AUTH"
        obj[CKA.MODULUS] = self.authCertP.modulus
        obj[CKA.PUBLIC_EXPONENT] = self.authCertP.pubexp
        obj[CKA.MODULUS_BITS] = eCK.ULONG(string.len(obj[CKA.MODULUS]) * 8)
        obj.kid = 3
        obj.key_bits = string.len(obj[CKA.MODULUS]) * 8
        obj.num = 3
        objects.max_index = objects.max_index +1
        objects[ objects.max_index] = obj
        log.output(
            string.format("_add_objects(): added public key: num:%d kid:%d bits:%d handle:%d", 
                obj.num, obj.kid, obj.key_bits, objects.max_index)
            )
    end
    
    if self.signCertP then
        local obj = GetCertTemplate(function() end)
        obj.private = false
        obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
        obj[CKA.LABEL] = "SIGN CERT"
        obj[CKA.ID] = "SIGN"
        obj[CKA.VALUE] = self.signCert or obj[CKA.VALUE]
        obj[CKA.SUBJECT] = (self.signCertP.subject) or ''
        obj[CKA.ISSUER] = (self.signCertP.issuer) or ''
        obj[CKA.SERIAL_NUMBER] = (self.signCertP.serialNumber) or ''
        obj.path = ""
        obj.num = 4
        objects.max_index = objects.max_index +1
        objects[ objects.max_index] = obj
        log.output(
            string.format("_add_objects(): added certificate: num:%d handle:%d", 
                obj.num, objects.max_index)
            )
            
        local obj = GetPrivKeyTemplate(t.mt.get_privkey)
        obj.private = true
        obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
        obj[CKA.LABEL] = "SIGN Priv KEY"
        obj[CKA.ID] = "SIGN"
        obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(self:is_user_consent_key(obj.kid))
        obj[CKA.MODULUS] = self.signCertP.modulus
        obj[CKA.PUBLIC_EXPONENT] = self.signCertP.pubexp
        obj[CKA.MODULUS_BITS] = eCK.ULONG(string.len(obj[CKA.MODULUS]) * 8)
        obj.kid = 4
        obj.key_bits = string.len(obj[CKA.MODULUS]) * 8
        obj.num = 4
        objects.max_index = objects.max_index +1
        objects[ objects.max_index] = obj
        log.output(
            string.format("_add_objects(): added private key: num:%d kid:%d bits:%d handle:%d", 
                obj.num, obj.kid, obj.key_bits, objects.max_index)
            )
            
        local obj = GetPubKeyTemplate(function() end)
        obj.private = false
        obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
        obj[CKA.LABEL] = "SIGN Pub Key"
        obj[CKA.ID] = "SIGN"
        obj[CKA.MODULUS] = self.signCertP.modulus
        obj[CKA.PUBLIC_EXPONENT] = self.signCertP.pubexp
        obj[CKA.MODULUS_BITS] = eCK.ULONG(string.len(obj[CKA.MODULUS]) * 8)
        obj.kid = 4
        obj.key_bits = string.len(obj[CKA.MODULUS]) * 8
        obj.num = 4
        objects.max_index = objects.max_index +1
        objects[ objects.max_index] = obj
        log.output(
            string.format("_add_objects(): added public key: num:%d kid:%d bits:%d handle:%d", 
                obj.num, obj.kid, obj.key_bits, objects.max_index)
            )
    end
    
    local obj = GetDataObjectTemplate(function() end)
    obj.private = true
    obj[CKA.PRIVATE] = eCK.BBOOL(true)
    obj[CKA.LABEL] = "EFS_LABEL"
    obj[CKA.APPLICATION] = "EFS_LABEL"
    local EFS_KEY = md.sha256()
    EFS_KEY:update(self.eida_hcard.default_master_key2 .. self.info.serialNumber .. self.eida_hcard.default_master_key1)
    obj[CKA.VALUE] = EFS_KEY:final()
    obj.path = ""
    obj.num = 0
    objects.max_index = objects.max_index +1
    objects[ objects.max_index] = obj
    log.output(
        string.format("_add_objects(): added private data object: num:%d handle:%d", 
        obj.num, objects.max_index))
            
    local obj = GetDataObjectTemplate(function() end)
    obj.private = false
    obj[CKA.PRIVATE] = eCK.BBOOL(false)
    obj[CKA.LABEL] = "HOLDERSIGNATUREIMAGE"
    obj[CKA.APPLICATION] = "HOLDERSIGNATUREIMAGE"
    obj[CKA.VALUE] = self.eida_hcard:getSignatureImage()
    obj.path = ""
    obj.num = 0
    objects.max_index = objects.max_index +1
    objects[ objects.max_index] = obj
    log.output(
        string.format("_add_objects(): added public data object HOLDERSIGNATUREIMAGE: num:%d handle:%d", 
        obj.num, objects.max_index))
    self._objects_added = true
end


function t.mt:get_objects()
    log.output('token-eida:get_objects()')
    
    self.eida_hcard:auto_perform_mutual_authenticate()
    local info = self:get_info() -- carica le info sul filesystem in cache
    
    local objects = {
            min_index = 11001, -- primo indice disponibile
            max_index = 11000, -- valore dell'indice massimo (i valori intermedi possono anche essere nil)
        }
    self:_add_objects(objects)
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


function t.mt:get_object_size(hobj)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj == nil then return CKR.OBJECT_HANDLE_INVALID end
    local oSize = -1
    
    if obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) or obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        oSize = (type(obj[CKA.VALUE]) == "string" and string.len(obj[CKA.VALUE]) ) or -1
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        oSize = 130*4
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        oSize = 130*4
    end
    
    return CKR.OK, oSize
end


function t.mt:get_special_ids(id_class)
end


function t.mt:valid()
    local rv = self.eida_hcard:valid()
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
        log.output("token-eida:flush_cache(): initialize: _cache_id:", self._cache_id)
    end
    changed, cache_id = utility.has_token_changed(self, "cache", self._cache_id)
    if changed then
        log.output("token-eida:flush_cache(): token has changed!")
        self._cache_id = cache_id
        self.info = nil -- rimuove cache oggetti
        self._indexes = nil
        self._objects_added = false
        self.attributes = nil
        
        log.output("token-eida:flush_cache(): rebuilding object's cache")
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
_LOADED['EIDASmartcard'] = { magic = '__TOBELOADED__', loadfn = function()
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

-- EIDASmartcard

local tr_dl

local EIDASmartcard = {}
EIDASmartcard.mt = {}
EIDASmartcard.mt.__index = EIDASmartcard.mt


EIDASmartcard.PIN_PADDING = 16
EIDASmartcard.PUK_PADDING = 16
EIDASmartcard.PADDING_CHAR = "F"
EIDASmartcard.BSO_PIN = 1
EIDASmartcard.BSO_PUK = 3

EIDASmartcard.MAX_TRANSMIT_BUFFER_SIZE = 200

EIDASmartcard.EIDASmartcardError = {}
EIDASmartcard.EIDASmartcardError.mt = {}
EIDASmartcard.EIDASmartcardError.mt.__index = EIDASmartcard.EIDASmartcardError.mt

function EIDASmartcard.EIDASmartcardError.mt.__tostring(e)
    return "EIDASmartcardError: " .. (e.msg or '') .. ' ;SW=' .. hex.hexify(e.sw or '') 
end

function EIDASmartcard.EIDASmartcardError.new(sw, msg)
    local e = msg .. ' ;sw=' .. hexify(sw or '')
    return e
end


function EIDASmartcard.new(card)
    local self = {
                    default_master_key_number=1,
                    CardVersion=0,
                    PIN_PADDING=EIDASmartcard.PIN_PADDING,
                    PUK_PADDING=EIDASmartcard.PUK_PADDING,
                    PADDING_CHAR=EIDASmartcard.PADDING_CHAR,
                    BSO_PIN=EIDASmartcard.BSO_PIN, BSO_DS_PIN=EIDASmartcard.BSO_DS_PIN,
                    BSO_PUK=EIDASmartcard.BSO_PUK, BSO_DS_PUK=EIDASmartcard.BSO_DS_PUK,
                  }
    self.card = card
    local mKey = sm.sm_ask_keys(10)  -- richiede la chiave #10, master key per cifratura chiavi
    local default_master_key = sm.des3_dec(mKey, hex.hexf('1DDDEDCAA0C3DB6E' .. '396C1F863EEF7ACCB41469A546C97420'))
    self.default_master_key1 = string.sub(default_master_key, 1, 8)
    self.default_master_key2 = string.sub(default_master_key, 9, 16)

    setmetatable(self, EIDASmartcard.mt)
    return self
end


function EIDASmartcard.mt:get_pin_puk_status()
    self:verify_pin_main("", false, true, false)
    local resPin = self.last_sw

    self:verify_pin_main("", true, true, false)
    local resPuk = self.last_sw
    
    local pinRetryMax = 5
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


local function pad_iso9797(data)
    local l = string.len(data)
    local m = math.mod(l, 8)
    if l == 0 or m == 0 then
        return data
    end
    return data .. string.rep('\000', 8-m)
end

local function pad_iso9797_2(data)
    local l = string.len(data)
    local m = math.mod(l, 8)
    local x = data .. "\128" .. string.rep('\000', 7-m)
    return x
    
end

local function unpad_iso9797_2(data)
    local l = string.len(data)
    for i=1,8 do
        if string.byte(data, l-i) == 128 then
            return string.sub(data, 1, l-i-1)
        end
    end
end

local function Retail_MAC(key, data, ssc)
    if not ssc then
        ssc=hex.hexf("0000000000000000")
    end
    S1TOMAC = pad_iso9797_2(ssc .. data)
    return sm.des3_mac(key, S1TOMAC)
end

local function calc_diversified_keys(CSN, MK1)
    --~ KENC = 3DES [CSN] <MK> || 3DES [CSN] <MK_inv>
    --~ KMAC = 3DES [inv_CSN] <MK> || 3DES [inv_CSN] <MK_inv>
    --~ MK: MK_Part1 || MK_Part2
    --~ CSN: aabbccddeeffgghh
    --~ MK_inv: MK_Part2 || MK_Part1
    --~ inv_CSN: hhggffeeddccbbaa
    --~ Example:
    --~ MK = 01 02 03 04 05 06 07 08 01 02 03 04 05 06 07 08h
    --~ CSN = 0F 80 00 1A D7 68 3C 6Dh
    --~ KENC = A7 AA 10 E9 BE DC 5A EF A7 AA 10 E9 BE DC 5A EFh
    --~ KMAC = B3 D4 AF 9B 29 FD F6 E3 B3 D4 AF 9B 29 FD F6 E3h
    log.output("calc_diversified_keys():")
    local MK_Part1 = string.sub(MK1, 1, 8)
    local MK_Part2 = string.sub(MK1, 9, 16)
    local MK = MK_Part1 .. MK_Part2 .. MK_Part1
    local MK_inv = MK_Part2 .. MK_Part1 .. MK_Part2
    local inv_CSN = ""
    for i=1,string.len(CSN) do
        inv_CSN = string.sub(CSN, i, i) .. inv_CSN
    end
    local KENC = sm.des3_enc(MK, CSN, true) .. sm.des3_enc(MK_inv, CSN, true)
    local KMAC = sm.des3_enc(MK, inv_CSN, true) .. sm.des3_enc(MK_inv, inv_CSN, true)
    return KENC, KMAC
end


local function calc_mutial_authenticate(key, CSN, CRnd, ICC_SN, TRnd, IFD_SN, Kifd)
    log.output("calc_mutial_authenticate():")
    local KENC, KMAC = calc_diversified_keys(string.sub(CSN, 1, 8), string.sub(key, 1, 16))
    KENC = KENC .. string.sub(KENC, 1, 8)
    KMAC = KMAC .. string.sub(KMAC, 1, 8)
    local S = TRnd .. IFD_SN .. CRnd .. ICC_SN .. Kifd
    local S1 = sm.des3_enc(KENC, S, true)
    local SSC_NULL=hex.hexf("0000000000000000")
    local S1TOMAC = pad_iso9797_2(SSC_NULL .. S1)
    local MAC = sm.des3_mac(KMAC, S1TOMAC)
    return KENC, KMAC, S1, MAC
end

local function L(value)
    return string.char(string.len(value)) .. value
end

function EIDASmartcard.mt:TXchain(value, data)
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
    

function EIDASmartcard.mt:TX(value, data)
    local resp = ""
    if data then
        value = value .. L(data)
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
    
local function enc_msg(key, apdu)
    log.output("enc_msg():")
    local edfb
    local lc = string.byte(apdu, 5)
    log.output('enc_msg: lc: ', lc )
    if lc > 0 then
        data = string.sub(apdu, 6)
    else
        data = ""
    end
    log.output("data:", hex.hexify(data))
    local pbData = pad_iso9797_2(data)
    log.output("pbData:", hex.hexify(pbData))
    local eData = "\001" .. sm.des3_enc(key, pbData, true)
    log.output("eData:", hex.hexify(eData))
    if string.len(eData) > 127 then
        edfb = hex.hexf("8782%H", string.len(eData) ) .. eData
    else
        edfb = hex.hexf("87%B", string.len(eData) ) .. eData
    end
    log.output("edfb:", hex.hexify(edfb))
    return edfb
end

local function inc_ssc(ssc1)
    log.output("inc_ssc():")
    log.output("SSC:", hex.hexify(ssc1))
    local ssc1_low = string.sub(ssc1, -3, -1)
    local ssc1_hi = string.sub(ssc1, 1, -4)
    local ssc1_low_num = bin.unpack("%>%L", "\000" .. ssc1_low)
    ssc1_low_num = ssc1_low_num +1
    ssc1_low = hex.hexf("%>%L", ssc1_low_num)
    
    local ssc = ssc1_hi .. string.sub(ssc1_low, -3, -1)
    log.output("SSC:+1", hex.hexify(ssc))
    return ssc
end


local function enc_mac_msg(ssc1, keyEnc, keyMac, apdu)
    log.output("enc_mac_msg():")
    log.output("ORIGINAL APDU:", hex.hexify(apdu))
    local cla_f = bin.flags(string.byte(apdu, 1))
    local edfb
    cla_f = cla_f * bin.flags("0xF0" )
    cla_f = cla_f + bin.flags("0x0C" )
    apdu = string.char(cla_f.asnumber) .. string.sub(apdu, 2, -1)
    local ssc = inc_ssc(ssc1)
    local lc = string.byte(apdu, 5)
    if lc > 0 and string.len(string.sub(apdu, 6)) == 0 then
        local le = lc
        log.output("using LE:", le)
        lc = 0
        edfb = hex.hexf("9701") .. string.char(le)
    else
        edfb = enc_msg(keyEnc, apdu)
        log.output("using LC:", lc)
    end
    local ch = string.sub(apdu, 1, 4)
    log.output("ch:", hex.hexify(ch))
    
    local chPB = ch .. hex.hexf("80000000")
    log.output("ch||PB:", hex.hexify(chPB))
    local chPBedfbPB = pad_iso9797_2(chPB .. edfb)
    log.output("ch||PB||edfb||PB:", hex.hexify(chPBedfbPB))
    local sscchPBedfbPB = ssc .. chPBedfbPB
    log.output("ssc||ch||PB||edfb||PB:", hex.hexify(sscchPBedfbPB))
    local mac1 = Retail_MAC(keyMac, chPB .. edfb, ssc)
    local mac2 = sm.des3_mac(keyMac, sscchPBedfbPB)
    assert(mac1 == mac2)
    mac = mac1
    log.output("mac:", hex.hexify(mac))
    local ccfb = hex.hexf("8e%B", string.len(mac) ) .. mac
    log.output("ccfb:", hex.hexify(ccfb))
    local edfb_ccfb = edfb .. ccfb
    log.output("edfb||ccfb:", hex.hexify(edfb_ccfb))
    local lenAPDU = string.len(edfb_ccfb)
    if lenAPDU > 255 then
        lenAPDU = 255
    end
    local apduENCMAC = string.sub(apdu, 1, 4) .. string.char(lenAPDU) ..  edfb_ccfb
    log.output("ENC MAC APDU:", hex.hexify(apduENCMAC))
    return apduENCMAC, ssc
end



local function dec_mac_msg(ssc1, keyEnc, keyMac, response)
    log.output("dec_mac_msg():")
    if string.len(response) == 2 then
        log.output("dec_mac_msg(): SW only response:", hex.hexify(response))
        return response
    end
    local ssc = ssc1
    local data = string.sub(response, 1, -2)
    local SW1 = string.sub(response, -2, -1)
    log.output("SW1:", hex.hexify(SW1))
    local SW
    local DATATOMAC = ""
    local dec = ""
    local valid = false
    local responsedec = ""
    local i = 0
    log.output("data:", hex.hexify(data))
    while true do
        local tag = string.byte(data, i+1)
        local le = string.byte(data, i+2)
        local offset = 0
        if le > 127 then
           offset = (bin.flags(le) * bin.flags("0x0F")).asnumber
           local leS = string.sub(data, i+3, i+2+offset)
           leS = string.rep("\000", 4 - string.len(leS)) .. leS
           le = bin.unpack("%>%L", leS)
           i =  i + offset
        end
        log.output(string.format("TAG: %02x LEN:%d", tag, le) )
        if tag == 135 then -- 0x87
            -- decrypt
            local TODEC = string.sub(data, i+3, i+2+le)
            log.output("TAG 87 ENC:", hex.hexify(TODEC))
            assert (string.byte(TODEC, 1) == 1) -- pading indicator
            local dec = sm.des3_dec(keyEnc, string.sub(TODEC, 2, -1), true)
            log.output("TAG 87 dec:", hex.hexify(dec))
            responsedec = responsedec .. unpad_iso9797_2(dec)
            DATATOMAC = DATATOMAC .. string.sub(data, i-offset+1, i+2+le)
            log.output("DATATOMAC:", hex.hexify(DATATOMAC))
        elseif tag == 129 then -- 0x81
            -- plain text
            local PT = string.sub(data, i+3, i+2+le)
            log.output("TAG 81 PT:", hex.hexify(PT))
            responsedec = responsedec .. PT
            DATATOMAC = DATATOMAC .. string.sub(data, i-offset+1, i+2+le)
            log.output("DATATOMAC:", hex.hexify(DATATOMAC))
        elseif tag == 153 then -- 0x99
            -- SW
            assert (le == 2)
            SW = string.sub(data, i+3, i+2+le)
            log.output("TAG 99 SW:", hex.hexify(SW))
            DATATOMAC = DATATOMAC .. string.sub(data, i+1, i+2+le)
            log.output("DATATOMAC:", hex.hexify(DATATOMAC))
        elseif tag == 142 then -- 0x8e
            assert (le == 8)
            -- MAC
            ssc = inc_ssc(ssc)
            local MAC = string.sub(data, i+3, i+2+le)
            log.output("TAG 8E MAC:", hex.hexify(MAC))
            local MAC2 = Retail_MAC(keyMac, DATATOMAC, ssc)
            log.output("TAG 8E MAC2:", hex.hexify(MAC2))
            valid = MAC2 == MAC
            log.output("VALID:", valid)
            break
        else
            log.output("unknown TAG:", tag)
        end
        i = i + le+2
        if i >= string.len(data) then
            break
        end
    end
    if SW then
        responsedec = responsedec .. SW
    else
        responsedec = responsedec .. SW1
    end
    return responsedec, valid, ssc
end

function EIDASmartcard.mt:SMTX(ssc, KskEnc, KskSig, apdu)
    local encApdu, ssc = enc_mac_msg(ssc, KskEnc, KskSig, apdu)
    --~ print ("SMTX: apdu:", hex.hexify(apdu))
    --~ print ("SMTX: encApdu SM:", hex.hexify(encApdu))
    local resp, valid
    resp = self:TXchain(string.sub(encApdu, 1, 4), string.sub(encApdu, 6))
    --~ print ("SMTX: resp:", hex.hexify(resp))
    resp, valid, ssc = dec_mac_msg(ssc, KskEnc, KskSig, resp)
    return resp, valid, ssc
end


function EIDASmartcard.mt:read_serial_number()
    if not self.CSN then
        self:select_classic_applet()
    end
    return self.CSN
end

function EIDASmartcard.mt:getSignatureImage()
    local signatureImage = ""
    local res = self:TX(hex.hexf("00A404000CA000000243001300000001FF"))
    assert (string.sub(res, -2, -1) == hex.hexf("9000") )
    
    local res = self:TX(hex.hexf("00a404000cA00000024300130000000101"))
    assert (string.sub(res, -2, -1) == hex.hexf("9000") )
    
    log.output("getSignatureImage(): selecting ID Applet")
    local res = self:TX(hex.hexf("00A404000DA0000002430013000000010101"))
    if string.sub(res, -2, -1) == hex.hexf("9000") then
        local res = self:TX(hex.hexf("00A40000020207"))
        if string.sub(res, -2, -1) == hex.hexf("9000") then
            local h = self:mread_binary(0, 8)
            if string.sub(h, 1, 2) == hex.hexf("7007") and string.sub(h, 5, 6) == hex.hexf("6732") then
                local tag1, tagLen, tiffTag, tiffLen = bin.unpack("%>%H%H%H%H", h)
                signatureImage = self:mread_binary(8, tiffLen)
                log.output("getSignatureImage(): TIFF IMAGE signatureImage:", hex.hexify(signatureImage))
            end
        end
    end
    self:select_classic_applet()
    return signatureImage
end

function EIDASmartcard.mt:select_classic_applet()
    log.output("select_classic_applet()")

    local res = self:TX(hex.hexf("00A404000CA000000243001300000001FF"))
    assert (string.sub(res, -2, -1) == hex.hexf("9000") )
    
    local res
    res = self:TX(hex.hexf("00A404000CA00000024300130000000101"))
    -- assert (string.sub(res, -2, -1) == hex.hexf("9000") )
    res = self:TX(hex.hexf("80C002A008"))
    assert (string.sub(res, -2, -1) == hex.hexf("9000") )
    self.ICC_SN = string.sub(res, 1, 8)

    res = self:TX(hex.hexf("80C002A108"))
    assert (string.sub(res, -2, -1) == hex.hexf("9000") )
    self.CSN = string.sub(res, 1, 8)
    
    log.output("select_classic_applet(): ICC_SN:", hex.hexify(self.ICC_SN))
    log.output("select_classic_applet(): CSN:", hex.hexify(self.CSN))
    
    local res = self:TX(hex.hexf("00A404000CA000000243001300000001FF"))
    assert (string.sub(res, -2, -1) == hex.hexf("9000") )
    
    local res = self:TX(hex.hexf("80ca010113"))
    assert (string.sub(res, -2, -1) == hex.hexf("9000") )
    
    if string.byte(res, 13) == 0 and string.byte(res, 14) == 48 then
        res = self:TX(hex.hexf("00A404000CA00000024300130000000102"))
        assert (string.sub(res, -2, -1) == hex.hexf("9000") )
        self.CardVersion = 1
    elseif string.byte(res, 13) == 0 and string.byte(res, 14) == 49 then
        res = self:TX(hex.hexf("00A404000CA00000024300130000000104"))
        assert (string.sub(res, -2, -1) == hex.hexf("9000") )
        self.CardVersion = 2
        self.CSN = self.ICC_SN
    else
        self.CardVersion = 0
    end
    
    log.output("select_classic_applet(): ICC_SN:", hex.hexify(self.ICC_SN))
    log.output("select_classic_applet(): CSN:", hex.hexify(self.CSN))
    log.output("select_classic_applet(): CardVersion:", self.CardVersion)
end


function EIDASmartcard.mt:select_p15()

    log.output("select_p15()")
    self:select_classic_applet()
end

function EIDASmartcard.mt:auto_perform_mutual_authenticate()
    -- funzione fondamentale per per il corretto uso del secure messaging
    -- ha lo scopi di:
    -- 1) individuare una mutua autenticazione valida gi