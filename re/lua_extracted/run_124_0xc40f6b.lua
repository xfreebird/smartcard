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

function t.mt:add_cardos_objects(objects)
    local obj
    log.output('token-cardos44:add_cardos_objects(): adding CARDOS 4.4 objects...')
    if self.cardos_info and type( self.cardos_info.lists ) == "table" then
        
        local keys = self.cardos_info.lists[self.DF_KEYS]
        local certs = self.cardos_info.lists[self.DF_CERTS]
        
        for i=1,table.getn(certs) do
            local o = certs[i]
            log.output('token-cardos44:add_cardos_objects(): adding CARDOS 4.4 Certificate:', i)
            obj = objCnsTmpl.GetCNSCertTemplate(t.mt.get_certificate)
            obj[CKA.LABEL] = ""
            obj[CKA.ID] = ""
            obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
            obj.fid = o.path.value
            obj.path = o.path.value
            
            for k=1,table.getn(o.attributes) do
                local a = o.attributes[k]
                local ckatype = bin.unpack("%<%L", a.ckatype.value)
                obj[ckatype] = a.ckaval.value
                log.output("certificate: decoded ckatype:", ckatype)
                log.output("ckaval:", hexify(a.ckaval.value))
            end
            
            local finfos = self:cardos_root_select(self.DF_CERTS .. obj.path)
            local certval = self.cardos_hcard:mread_binary(0, finfos.size)
            local c = der.parse(certval)
            if c[1] and c[1].tag == der.SEQUENCE then
                local certvaldec = zlib.decompress(c[1].value)
                log.output("\tcertvaldec:", hex.hexify(certvaldec))
                obj.value = certvaldec
            end
            obj.num = i
            objects.max_index = objects.max_index+1
            objects[ objects.max_index ] = obj
            log.output('token-cardos44:add_cardos_objects(): added certificate:',
                objects.max_index,
                hex.hexify(obj[CKA.CLASS]))
        end
        for i=1,table.getn(keys) do
            local o = keys[i]
            log.output('token-cardos44:add_cardos_objects(): adding CARDOS 4.4 Pub and Priv key:', i)
            objects.max_index = objects.max_index+1
            local objPub = objCnsTmpl.GetCNSPubKeyTemplate(t.mt.get_public_key)
            objPub[CKA.LABEL] = ""
            objPub[CKA.ID] = ""
            objPub.num = i
            objPub.kid = o.kid.value
            objPub.fid = "\0" .. o.kid.value
            objPub.path = self.DF_KEYS .. objPub.fid .. objPub.fid
            local finfos = self:cardos_root_select(self.DF_KEYS .. objPub.fid .. objPub.fid)
            local record1 = self.cardos_hcard:read_record(1, 4)
            local record2 = self.cardos_hcard:read_record(2, 4)
            for i, record in {record1, record2} do
                if string.sub(record, 1, 1) == hexf('10') then
                    objPub.modulus = string.sub(record, 5, -1)
                elseif string.sub(record, 1, 1) == hexf('11') then
                    objPub.pubexp = string.sub(record, 5, -1)
                end
            end
            log.output("\tmodulus:", hex.hexify(objPub.modulus))
            log.output("\texponent:", hex.hexify(objPub.pubexp))
            objPub.key_bits = string.len(objPub.modulus) * 8
            
            objects[ objects.max_index ] = objPub
            log.output('token-cardos44:add_cardos_objects(): added pub key:',
                objects.max_index,
                hex.hexify(objPub[CKA.CLASS]))
            self.cardos_info.pub_key_handle = objects.max_index
            
            objects.max_index = objects.max_index+1
            local objPriv = objCnsTmpl.GetCNSPrivKeyTemplate(t.mt.get_public_key)
            objPriv[CKA.LABEL] = ""
            objPriv[CKA.ID] = ""
            objPriv.num = objPub.num
            objPriv.kid = objPub.kid
            objPriv.fid = objPub.fid
            objPriv.path = objPub.path
            objPriv.modulus = objPub.modulus
            objPriv.pubexp = objPub.pubexp
            objPriv[CKA.ALWAYS_AUTHENTICATE] = objPub[CKA.ALWAYS_AUTHENTICATE]
            objPriv.key_bits = objPriv.key_bits           
            objPriv.pso_dec = o.algo.value == hexf("0c")
            objPriv.private=true
            
            objPriv[CKA.PRIVATE] = eCK.BBOOL(objPriv.private)
            objPriv[CKA.DECRYPT] = eCK.BBOOL(true)
            objPriv[CKA.SIGN] = eCK.BBOOL(true)
            
            for k=1,table.getn(o.attributes) do
                local a = o.attributes[k]
                local ckatype = bin.unpack("%<%L", a.ckatype.value)
                objPub[ckatype] = a.ckaval.value
                objPriv[ckatype] = a.ckaval.value
                log.output("private key: decoded ckatype:", ckatype)
                log.output("ckaval:", hexify(a.ckaval.value))
            end
            
            objects[ objects.max_index ] = objPriv
            log.output('token-cardos44:add_cardos_objects(): added priv key:',
                objects.max_index,
                hex.hexify(objPriv[CKA.CLASS]))
        end
    end
end


function t.mt:get_objects()

    log.output('token-cardos44:get_objects()')
    local info = self:get_info() -- carica le info sul filesystem in cache
    
    local objects = {
            min_index = 11001, -- primo indice disponibile
            max_index = 11000, -- valore dell'indice massimo (i valori intermedi possono anche essere nil)
        }

    self:add_cardos_objects(objects)

    return objects
end

function t.mt:get_attribute_value(hobj, attr, onlysize)
    log.output('get_attribute_value(): object', hobj, attr, onlysize)
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
    return self.cardos_hcard:valid()
end


function t.mt:get_object_size(hobj)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj == nil then return CKR.OBJECT_HANDLE_INVALID end
    local oSize = -1
    if obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        oSize = type(obj.value) == "string" and string.len(obj.value) or oSize
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        oSize = type(obj.modulus) == "string" and (string.len(obj.modulus)*2) or oSize
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        oSize = type(obj.modulus) == "string" and (string.len(obj.modulus)*2) or oSize
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        oSize = type(obj.value) == "string" and string.len(obj.value) or oSize
    end       
    return CKR.OK, oSize
end

function t.mt:get_special_ids(id_class)
    if id_class == 'CNS' then
        return {OBJ_IDS.CNS0_ID}
    end
end

function t.mt:flush_cache()
    if self.cfg["xproc"] ~= "true" then
        return false
    end
    local changed, cache_id
    if self._cache_id == nil then
        log.output("token-cardos44:flush_cache(): initializing _cache_id")
        changed, self._cache_id = utility.has_token_changed(self, "cache", 0)
        log.output("token-cardos44:flush_cache(): initialize: _cache_id:", self._cache_id)
    end
    changed, cache_id = utility.has_token_changed(self, "cache", self._cache_id)
    if changed then
        log.output("token-cardos44:flush_cache(): token has changed!")
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
_LOADED['token-dni-peru'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- token-dni-peru.lua
local DniSmartcard = require 'DniSmartcard'
local hex = require 'hex'
local hexf, hexify = hex.hexf, hex.hexify
local der = require 'der'
local utility = require 'utility'
-- local log = {}
-- function log.output(...)
    -- print(unpack(arg))
-- end

local OBJ_IDS = {
    SIGN_PUBKEY_LABEL = '',
    SIGN_PRIVKEY_LABEL = 'Clave Privada de Firma Digital',
    SIGN_ID = hexf('02'),
    CA_ID = hexf('55'),
    INTERMEDIATE_CA_ID = hexf('56'),
}

local MinKSize, MaxKSize = 1024, 2048

local function GetCertTemplate(populateCertFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.CERTIFICATE),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(false),
        [ CKA.LABEL ] = populateCertFunc,
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
        -- [ CKA.ALWAYS_AUTHENTICATE ] = eCK.BBOOL(true),
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

local function getCN(value)
    value = der.parse(value)
    if table.getn(value) ~= 1 or value[1].tag ~= der.SEQUENCE then
        error('X500 distinguished name parse error', 2)
    end
    value = der.parse(value[1].value)
    for i, v in value do
        if v.tag ~= der.SET then
            error('X500 distinguished name parse error', 2)
        end
        v = der.parse(v.value)
        if table.getn(v) ~= 1 or v[1].tag ~= der.SEQUENCE then
            error('X500 distinguished name parse error', 2)
        end
        v = der.parse(v[1].value)
        if table.getn(v) ~= 2 then
            error('X500 distinguished name parse error', 2)
        end
        if v[1].value == hex.hexf('550403') then
            return v[2].value
        end
    end
end

local t = {
    name = 'dni_peru',
    mt = { },
    mechanisms = {
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.SIGN},
    },
    dni_hcard = nil,
    smartcard = DniSmartcard,
}
t.mt.__index = t.mt


function t.mt:initialize(cfg)
    self.dni_hcard = DniSmartcard.new(self.hcard)
    
    self.dni_hcard.on_transmit = function(self, apdu)
        if not self._pki_applet_selected then
            log.output("(re)selecting PKI applet...")
            self.card:transmit(hexf("00A4040010A0000000770100700A1000F100000100"))
            self._pki_applet_selected = true
        end
    end

    self.dni_hcard.on_begin_transaction = function(self)
        self._pki_applet_selected = false
    end
    
    self.mechanisms = utility.clone_table(t.mechanisms)
    self.dni_info = nil
    self.attributes = nil
end

function t.mt:finalize()
    log.output("token-dni-peru:finalize():", self.session, self.userType)
end
    
function t.mt:begin_transaction()
    self.dni_hcard:begin_transaction()
end

function t.mt:end_transaction()
    self.dni_hcard:end_transaction()
end


function t.mt:add_info_dni()
    -- dni_info contiene le info sul FS di firma specifico della DNI
    self.dni_info = {}    
    self.dni_info.pki_path = '3F005015'
    pcall (function()
        self.dni_hcard:select(hexf(self.dni_info.pki_path .. '3402'))
        local certVal = self.dni_hcard:read_binary(0, 1)
        self.dni_info.sign_cert_valid = (string.byte(certVal, 1) == 48) -- hex 30
        self.dni_info.sign_key_valid = self.dni_info.sign_cert_valid
    end)    
    pcall (function()
        self.dni_hcard:select(hexf(self.dni_info.pki_path .. '3407'))
        local certVal = self.dni_hcard:read_binary(0, 1)
        self.dni_info.ca_cert_valid = (string.byte(certVal, 1) == 48) -- hex 30
    end)
    pcall (function()
        self.dni_hcard:select(hexf(self.dni_info.pki_path .. '3408'))
        local certVal = self.dni_hcard:read_binary(0, 1)
        self.dni_info.intermediate_ca_cert_valid = (string.byte(certVal, 1) == 48) -- hex 30
    end)
end

function t.mt:get_info()
    if not self.info then
        self.info = {
            label = 'OT AWP',
            manufacturerID = '',
            model = '',
            serialNumber = '0000000000000000',
            flags = CKF.RNG + CKF.LOGIN_REQUIRED + CKF.USER_PIN_INITIALIZED + CKF.TOKEN_INITIALIZED,
            ulMaxSessionCount = CK.EFFECTIVELY_INFINITE,
            ulSessionCount = 0,
            ulMaxRwSessionCount = CK.EFFECTIVELY_INFINITE,
            ulRwSessionCount = CK.UNAVAILABLE_INFORMATION,
            ulMaxPinLen = self.dni_hcard.PIN_PADDING or 8,
            ulMinPinLen = 1,
            ulTotalPublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulFreePublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulTotalPrivateMemory = CK.UNAVAILABLE_INFORMATION,
            ulFreePrivateMemory = CK.UNAVAILABLE_INFORMATION,
            hardwareVersion = { major=0, minor=0},
            firmwareVersion = { major=0, minor=0},
            utcTime = '0000000000000000'
        }
        
        self:add_info_dni()
    end 

    return self.info
end

function t.mt:get_mechanisms()
    local info = self:get_info()
    return self.mechanisms
end

function t.mt:verify_pin(pin, userType, contextual_obj)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local result

    if userType == CKU.SO then 
        return CKR.ARGUMENTS_BAD
    end
    log.output("verify_pin()", pin, userType, contextual_obj)
    if userType == CKU.CONTEXT_SPECIFIC then
        result = self.dni_hcard:verify_sign_pin(pin)
        log.output("verify_pin_auth(): result=", result)
        if result == 0 then
            -- self.contextual_pin_verified = true
            return CKR.OK
        end
    else
        result = self.dni_hcard:verify_sign_pin(pin)
        log.output("verify_pin_auth(): result=", result)
        if result == 0 then
            self.cached_sign_pin = pin
            self.userType = userType
            return CKR.OK
        end
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
    self.cached_sign_pin = nil
    self.userType = nil
    -- self.cached_ds_pin = nil
end

function t.mt:change_pin(oldPin, newPin)
    return CKR.FUNCTION_NOT_SUPPORTED
end


function t.mt:reset_pin(newPin)
    return CKR.FUNCTION_NOT_SUPPORTED
end

--=====================================================================================
-- Funzioni per il recupero degli attributi
--=====================================================================================
-- Nella funzione seguente il parametro "onlysize" viene trascurato.
-- Il motivo 