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


local function GetCertTemplate(populateCertFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.CERTIFICATE),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(false),
        [ CKA.LABEL ] = 'CIE0',
        -- Certificate
        [ CKA.CERTIFICATE_TYPE ] = eCK.CERTIFICATE_TYPE(CKC.X_509),
        [ CKA.TRUSTED ] = eCK.BBOOL(true),
        [ CKA.CERTIFICATE_CATEGORY ] = eCK.ULONG(1), -- user
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        -- Certificate X.509
        [ CKA.SUBJECT ] = populateCertFunc,
        [ CKA.ID ] = 'CIE0',
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
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(false),
        [ CKA.LABEL ] = 'CIE0',
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = 'CIE0',
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = eCK.BBOOL(true),
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
        [ CKA.LABEL ] = 'CIE0',
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = 'CIE0',
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

function t.mt:load_cie_certificate()
    pcall(function()
        self.cie_cert_value = self.cie3_hcard:read_cie_cert()
        self.cie_cert_parsed = der.parse_x509cer(self.cie_cert_value)
    end)
end

function t.mt:get_privkey(hobj, att_type, onlysize, force_all)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('get_privkey(): ERROR! not a private key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end

    self:load_cie_certificate()
    
    obj[CKA.MODULUS] = self.cie_cert_parsed.modulus
    obj[CKA.PUBLIC_EXPONENT] = pubexp or hex.hexf('010001')
    obj[CKA.MODULUS_BITS] = eCK.ULONG(string.len(self.cie_cert_parsed.modulus) * 8)
    
    obj.populated = true
    return CKR.OK, obj[att_type]
end

function t.mt:get_pubkey(hobj, att_type, onlysize, force_all)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PUBLIC_KEY) then
        log.output('get_pubkey(): ERROR! not a public key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    
    self:load_cie_certificate()
    
    obj[CKA.MODULUS] = self.cie_cert_parsed.modulus
    obj[CKA.PUBLIC_EXPONENT] = pubexp or hex.hexf('010001')
    obj[CKA.MODULUS_BITS] = eCK.ULONG(string.len(self.cie_cert_parsed.modulus) * 8)
    
    obj.populated = true
    return CKR.OK, obj[att_type]
end

function t.mt:get_certificate(hobj, att_type, onlysize, force_all)

    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local parsed_cer = self.cie_cert_parsed
    local cert_value = self.cie_cert_value
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.CERTIFICATE) then
        log.output('get_certificate(): ERROR! not a certificate object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end

    self:load_cie_certificate()
    
    obj[CKA.VALUE] = cert_value or obj[CKA.VALUE]
    obj[CKA.SUBJECT] = (parsed_cer and parsed_cer.subject) or ''
    obj[CKA.ISSUER] = (parsed_cer and parsed_cer.issuer) or ''
    obj[CKA.SERIAL_NUMBER] = (parsed_cer and parsed_cer.serialNumber) or ''
    --~ obj[CKA.MODIFIABLE] = eCK.BBOOL((bin.flags('0x0001') * obj_attributes.flags).asbool)
    --~ obj[CKA.TRUSTED]      = eCK.BBOOL((bin.flags('0x0002') * obj_attributes.flags).asbool)
    
    obj.populated = true
    return CKR.OK, obj[att_type]
end


function t.mt:_add_objects(objects)

    if self._objects_added then
        return
    end

    self:load_cie_certificate()
    
    if self.cie_cert_value and self.cie_cert_parsed then
        local key_bits = string.len(self.cie_cert_parsed.modulus) * 8
        local obj = GetPrivKeyTemplate(t.mt.get_privkey)
        obj.private = true
        obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
        -- obj[CKA.LABEL] = "CIE0"
        -- obj[CKA.ID] = "CIE0"
        obj.kid = "81"
        obj.key_bits = key_bits
        obj.num = 0
        objects.max_index = objects.max_index +1
        objects[ objects.max_index] = obj
        log.output(
            string.format("_add_objects(): added private key: num:%d kid:%d bits:%d handle:%d", 
                obj.num, obj.kid, obj.key_bits, objects.max_index)
            )

        self._private_objects_added = true
    
        local obj = GetPubKeyTemplate(t.mt.get_pubkey)
        obj.private = true
        obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
        -- obj[CKA.LABEL] = "CIE0"
        -- obj[CKA.ID] = "CIE0"
        obj.kid = "81"
        obj.key_bits = key_bits
        obj.num = 0
        objects.max_index = objects.max_index +1
        objects[ objects.max_index] = obj
        
        log.output(
            string.format("_add_objects(): added public key: num:%d kid:%d bits:%d handle:%d", 
                obj.num, obj.kid, obj.key_bits, objects.max_index)
            )

        local obj = GetCertTemplate(t.mt.get_certificate)
        obj.private = true
        obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
        -- obj[CKA.LABEL] = "CIE0"
        -- obj[CKA.ID] = "CIE0"
        obj.num = 0
        objects.max_index = objects.max_index +1
        objects[ objects.max_index] = obj
        log.output(
            string.format("_add_objects(): added certificate: num:%d handle:%d", 
                obj.num, objects.max_index)
            )
        self._objects_added = true
    end
end


function t.mt:get_objects()
    log.output('token-cie3:get_objects()')
    
    self.cie3_hcard:auto_perform_mutual_authenticate()
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


function t.mt:get_object_size(hobj)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj == nil then return CKR.OBJECT_HANDLE_INVALID end
    local oSize = 1024
    
    return CKR.OK, oSize
end


function t.mt:valid()
    local rv = self.cie3_hcard:valid()
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
        log.output("token-cie3:flush_cache(): initialize: _cache_id:", self._cache_id)
    end
    changed, cache_id = utility.has_token_changed(self, "cache", self._cache_id)
    if changed then
        log.output("token-cie3:flush_cache(): token has changed!")
        self._cache_id = cache_id
        self.info = nil -- rimuove cache oggetti
        self._indexes = nil
        self._private_objects_added = false
        self.attributes = nil
        
        log.output("token-cie3:flush_cache(): rebuilding object's cache")
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
_LOADED['CIE3Smartcard'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
local rsa = require("rsa")
local hex = require 'hex'
local util = require 'utility'
local repr = util.repr
local h2i, hexf, hexify = hex.h2i, hex.hexf, hex.hexify
local zlib = require 'zlib'
local der = require("der")

local function hexf2(data, ...)
    data = string.gsub(data, "%s", "")
    return hex.hexf(data, unpack(arg))
end

-- CIE3Smartcard

local tr_dl

local CIE3Smartcard = {}
CIE3Smartcard.mt = {}
CIE3Smartcard.mt.__index = CIE3Smartcard.mt


CIE3Smartcard.SSCD_APP_SECRET = '30304635374336314637354531333637'
CIE3Smartcard.User_CAN    = '555345525343414e'  --  "USERSCAN"
CIE3Smartcard.User_EXCAN = CIE3Smartcard.User_CAN .. CIE3Smartcard.SSCD_APP_SECRET -- PSEUDO MRZ


CIE3Smartcard.MAX_TRANSMIT_BUFFER_SIZE = 128
CIE3Smartcard.ID_PIN = tonumber("81", 16)
CIE3Smartcard.ID_PUK = tonumber("82", 16)

CIE3Smartcard.CIE3SmartcardError = {}
CIE3Smartcard.CIE3SmartcardError.mt = {}
CIE3Smartcard.CIE3SmartcardError.mt.__index = CIE3Smartcard.CIE3SmartcardError.mt

function CIE3Smartcard.CIE3SmartcardError.mt.__tostring(e)
    return "CIE3SmartcardError: " .. (e.msg or '') .. ' ;SW=' .. hex.hexify(e.sw or '') 
end

function CIE3Smartcard.CIE3SmartcardError.new(sw, msg)
    local e = msg .. ' ;sw=' .. hexify(sw or '')
    return e
end


function CIE3Smartcard.new(card)
    local self = {
                    ID_PIN=CIE3Smartcard.ID_PIN,
                    ID_PUK=CIE3Smartcard.ID_PUK,
                    User_EXCAN=hex.hexf(CIE3Smartcard.User_EXCAN),
                    mw_mk="MI".."D" .. "WRC" .. "AN" .. "FF".."2A".."6D9".."159".."9D5".."6D4",
                    }
    self.card = card
    setmetatable(self, CIE3Smartcard.mt)
    return self
end


local function parse_tlv_ber(data)
    local d = {}
    local i = 0
    local offset, le, tag
    local log_array = {}
    log.output("parse_tlv_ber():", hex.hexify(data or ""))
    while 1 do
        tag = string.byte(data, i+1)
        if tag == 191 then -- 0xBF
            i = i+2
            tag = (tag * 65536) + (string.byte(data, i)*256) + (string.byte(data, i+1)) 
        elseif tag == 127 then -- 0x7F
            i = i+1
            tag = (tag * 256) + string.byte(data, i+1)
        elseif tag == 95 then -- 0x5F
            i = i+1
            tag = (tag * 256) + string.byte(data, i+1)
        end
        le = string.byte(data, i+2)
        offset = 0
        if le > 127 then
           offset = (bin.flags(le) * bin.flags("0x0F")).asnumber
           local leS = string.sub(data, i+3, i+2+offset)
           leS = string.rep("\000", 4 - string.len(leS)) .. leS
           le = bin.unpack("%>%L", leS)
           i = i + offset
        end
        table.insert(log_array, string.format("TAG: %02x LEN:%d", tag, le))
        d[tag] = string.sub(data, i+3, i+2+le)
        
        i = i + le + 2
        if i >= string.len(data) then
            break
        end
    end
    log.output(table.concat(log_array, "; "))
    return d
end


local function BUILD_TLV_BER(tagID, data)
    local DO87_85
    if string.len(data) >= 256 then
        DO87_85 = hex.hexf(tagID..'82%>%H%S', string.len(data), data )
    elseif string.len(data) >= 128 then
        DO87_85 = hex.hexf(tagID..'81%P', data )
    else
        DO87_85 = hex.hexf(tagID..'%P', data )
    end
    
    return DO87_85
end
       
       
local function sha256(data)
    local s = md.sha256()
    s:update(data)
    return s:final()
end

local function build_des3_key(key)
    local keyLen = string.len(key)
    if keyLen == 8 then
        key = key .. key .. key
    elseif keyLen == 16 then
        key = key .. string.sub(key, 1, 8)
    elseif keyLen == 24 then
        key = key
    else
        error("invalid key len:" .. keyLen)
    end
    return key
end

local function compute_des3_mac(plaintext, key, IV)

    keySig = build_des3_key(key)
    local mac_my = sm.des3_mac(keySig, plaintext)
    
    return mac_my

end

local function trim_pad_bn(data, padto)
    data = string.sub(data, -padto)
    data = string.rep("\000", padto - string.len(data)) .. data
    return data
end

local function trim_leding_zero(data)
    while (string.len(data) >0 and string.byte(data, 1) == 0) do
        data = string.sub(data, 2, -1)
    end
    return data
end


local function inc_ssc(ssc1)
    log.output("inc_ssc():")
    log.output("SSC:", hex.hexify(ssc1))
    local sscBN1 = bignum.create(ssc1, true) + bignum.create(1)
    local ssc = hex.hexf(sscBN1:tostring(16, true))
    ssc = trim_pad_bn(ssc, 8)
    log.output("SSC+1:", hex.hexify(ssc))
    return ssc
end

-- inc_ssc(hex.hexf("FFFFFFFFFFFFFFFF"))
-- inc_ssc(hex.hexf("0FFFFFFFFFFFFFFF"))
-- inc_ssc(hex.hexf("00FFFFFFFFFFFFFF"))
-- inc_ssc(hex.hexf("000FFFFFFFFFFFFF"))
-- inc_ssc(hex.hexf("0000FFFFFFFFFFFF"))
-- inc_ssc(hex.hexf("00000FFFFFFFFFFF"))
-- inc_ssc(hex.hexf("000000FFFFFFFFFF"))
-- inc_ssc(hex.hexf("0000000FFFFFFFFF"))
-- inc_ssc(hex.hexf("FFFFFFFFFFFFFFFF"))
-- inc_ssc(hex.hexf("FFFFFFFFFFFFFFFE"))
-- inc_ssc(hex.hexf("FFFFFFFFFFFFFFF0"))
-- inc_ssc(hex.hexf("0000000000000001"))
-- inc_ssc(hex.hexf("F000000000000001"))
-- inc_ssc(hex.hexf("F0000000000000F1"))


-- local function pad_iso9797(data, padding_length)
    -- local l = string.len(data)
    -- local m = math.mod(l, padding_length)
    -- if l == 0 or m == 0 then
        -- return data
    -- end
    -- return data .. string.rep('\000', padding_length-m)
-- end

local function pad_iso9797_2(data, padding_length)
    padding_length = padding_length or 8
    local l = string.len(data)
    local m = math.mod(l, padding_length)
    local x = data .. "\128" .. string.rep('\000', padding_length-1-m)
    return x
    
end

local function unpad_iso9797_2(data, padding_length)
    padding_length = padding_length or 8
    local l = string.len(data)
    for i=1,padding_length do
        if string.byte(data, l-i) == 128 then
            return string.sub(data, 1, l-i-1)
        end
    end
end


local function SM(keyEnc, keySig, apdu, seq)

	log.output("SM:keyEnc:" .. hex.hexify(keyEnc))
	log.output("SM:keySig:" .. hex.hexify(keySig))
	log.output("SM:apdu:" .. hex.hexify(apdu))
	log.output("SM:seq:" .. hex.hexify(seq))
    
	local seq1 = inc_ssc(seq)
	log.output("SM:seq1:" .. hex.hexify(seq1))
    
    local cla_f = bin.flags(string.byte(apdu, 1))
    cla_f = cla_f * bin.flags("0xF0" )
    cla_f = cla_f + bin.flags("0x0C" )
    apdu = string.char(cla_f.asnumber) .. string.sub(apdu, 2, -1)
    
	local smHead = string.sub(apdu, 1, 4)
    
	local head_seq = seq1 .. smHead
	log.output("SM:head_seq:" .. hex.hexify(head_seq))
    
    keyEnc = keyEnc .. string.sub(keyEnc, 1, 8)
    keySig = keySig .. string.sub(keySig, 1, 8)

    log.output("SM:keyEnc:" .. hex.hexify(keyEnc))
    log.output("SM:keySig:" .. hex.hexify(keySig))
    
    local calcMac = pad_iso9797_2(head_seq)
    log.output("SM:calcMac1:".. hex.hexify(calcMac))
    
	local datafield, doob = "", ""
	if (string.byte(apdu, 5) ~= 0 and string.len(apdu) > 5) then
		
		local toEnc = string.sub(apdu, 6, 5 + string.byte(apdu, 5))
		local toEncPadded = pad_iso9797_2(toEnc)
        log.output("SM:toEnc:" .. hex.hexify(toEnc))
        log.output("SM:toEncPadded:" .. hex.hexify(toEncPadded))

		local enc = sm.des3_enc(keyEnc, toEncPadded, true)
        log.output("SM:enc:" .. hex.hexify(enc))

        -- check INS: odd ins is 85, even ins is 87 + 0x01
		if (math.mod(string.byte(apdu, 1), 2) == 0) then
			doob = BUILD_TLV_BER("87", "\001" .. enc)
		else
			doob =  BUILD_TLV_BER("85", enc)
        end
        
		calcMac = calcMac .. doob
        datafield = datafield .. doob

        log.output("SM:calcMac2:" .. hex.hexify(calcMac))
	end
	if (string.byte(apdu, 5) == 0 and string.len(apdu) > 7) then
        -- extended APDU
        local apduLen = (string.byte(apdu, 6) * 256) + string.byte(apdu, 7)
		local toEnc = string.sub(apdu, 8, 7+ apduLen)
		local toEncPadded = pad_iso9797_2(toEnc);
        log.output("SM:toEncPadded:" .. hex.hexify(toEncPadded))
        
		local enc = sm.des3_enc(keyEnc, toEncPadded, true)
        log.output("SM:enc:" .. hex.hexify(enc))
        
        -- check INS: odd ins is 85, even ins is 87 + 0x01
		if (math.mod(string.byte(apdu, 1), 2) == 0) then
			doob = BUILD_TLV_BER("87", "\001" .. enc)
		else
			doob =  BUILD_TLV_BER("85", enc)
        end
		calcMac = calcMac .. doob
        datafield = datafield .. doob
        log.output("SM:calcMac3:" .. hex.hexify(calcMac))
	end
    
	if (string.len(apdu) == 5 or string.len(apdu) == (string.byte(apdu, 5) + 6)) then
        doob = BUILD_TLV_BER("97", string.sub(apdu, -1, -1) )

		calcMac = calcMac .. doob
        datafield = datafield .. doob
		log.output("SM:calcMac4:" .. hex.hexify(calcMac))
	end

    log.output("SM:calcMac:" .. hex.hexify(calcMac))
	
    local toMac = pad_iso9797_2(calcMac)
    log.output("SM:toMac:" .. hex.hexify(toMac))
    
    local mac = sm.des3_mac(keySig, toMac)
    log.output("SM:mac:" .. hex.hexify(mac))

    datafield = datafield .. BUILD_TLV_BER("8e", mac)

	local elabResp
    local dataLen = string.len(datafield)
	if (dataLen < 256) then
		elabResp = smHead .. hex.hexf("%P00", datafield)
	else
        elabResp = smHead .. hex.hexf("00%>%H%S0000", dataLen, datafield)
	end
    log.output("SM:elabResp:" .. hex.hexify(elabResp))

	return elabResp, seq1
end



local function respSM(keyEnc, keySig, resp, seq)
	log.output("respSM:keyEnc:" .. hex.hexify(keyEnc))
	log.output("respSM:keySig:" .. hex.hexify(keySig))
	log.output("respSM:resp:" .. hex.hexify(resp))
	log.output("respSM:seq:" .. hex.hexify(seq))
    
	local seq1 = inc_ssc(seq)
	log.output("respSM:seq1:" .. hex.hexify(seq1))
    
    
    keyEnc = keyEnc .. string.sub(keyEnc, 1, 8)
    keySig = keySig .. string.sub(keySig, 1, 8)
    
    local elabResp = ""
	local index, llen, lgn
	local sw = string.sub(resp, -2, -1)
	local encData;
	local respMac, calcMac

    resp = string.sub(resp, 1, -3)
    
	calcMac = seq1
	index = 0
	log.output("respSM:calcMac:" .. hex.hexify(calcMac))
    
    local TAG_99 = tonumber("99", 16)
    local TAG_8E = tonumber("8e", 16)
    local TAG_85 = tonumber("85", 16)
    local TAG_87 = tonumber("87", 16)
    
	repeat
        local TAG = string.byte(resp, index+1)
        log.output (string.format("TAG: %02X", TAG))
    
		if (TAG == TAG_99) then
        
            local swData = string.sub(resp, index+1, index + string.byte(resp, index + 2) + 2)
			calcMac = calcMac .. swData
			sw = string.sub(resp, index + 3, index + 4)
			index = index+ 4
            log.output ("SW:", hex.hexify(sw))
            log.output ("swData:", hex.hexify(swData))
		elseif (TAG == TAG_8E) then
            
        
			if (string.byte(resp, index + 2) ~= 8) then
				error( "Lunghezza del MAC non valida")
            end
			respMac = string.sub(resp, index+1 + 2, index + 2 + 8)
			index = index + 10
		
		elseif (TAG == TAG_85) then
        
			if (string.byte(resp, index + 2) > 128) then
				llen = string.byte(resp, index + 2) - 128
				if (llen == 1) then
					lgn = string.byte(resp, index + 3)
				else
                    if (llen == 2) then
						lgn = (string.byte(resp, index + 3)*256) +  string.byte(resp, index + 4)
					else 
						error(string.format("Lunghezza ASN1 non valida: %d", llen))
                    end
                end
				encData = string.sub(resp, index+1 + llen + 2, index + llen + 2 + lgn)
				calcMac = calcMac .. string.sub(resp, index+1, index+lgn + llen + 2)
				index = index + llen + lgn + 2
			
			else 
				encData = string.sub(resp, index+1 + 2, index+1 + 2 + string.byte(resp, index + 2))
				calcMac = calcMac .. (string.sub(resp, index+1, index+string.byte(resp, index + 2) + 2))
				index = index + string.byte( resp, index + 2) + 2
			end
		elseif (TAG == TAG_87) then
            
			if (string.byte(resp, index + 2) > 128) then
				llen = string.byte(resp, index + 2) - 128;
				if (llen == 1) then
					lgn = string.byte(resp, index + 3)
				else 
					if (llen == 2) then
						lgn = (string.byte(resp, index + 3)*256 ) + string.byte(resp, index + 4);
					else
						error (string.format("Lunghezza ASN1 non valida: %d", llen));
                    end
                end
				encData = string.sub(resp, index+1 + llen + 3, index + llen + 3 + lgn - 1);
				calcMac = calcMac .. string.sub(resp, index+1, index+lgn + llen + 2)
				index = index + llen + lgn + 2;

			else
				encData = string.sub(resp, index +1 + 3, index + 3 + string.byte(resp, index + 2) - 1)
				calcMac = calcMac .. (string.sub(resp, index+1, string.byte(resp, index + 2) + 2))
				index = index + string.byte(resp, index + 2) + 2
			end
		
		else
			error ("Tag non riconosciuto nella risposta in Secure Messaging");
        end
		-- log.output("respSM: calcMac N", hex.hexify(calcMac));
        log.output ("index:" .. index)
	until (index >= string.len(resp))

	log.output("respSM: calcMac", hex.hexify(calcMac))
    local toMac = pad_iso9797_2(calcMac)
    local smMac = sm.des3_mac(keySig, toMac)
	log.output("respSM: smMac", hex.hexify(smMac) )
	log.output("respSM: respMac", hex.hexify(respMac) )

	assert(smMac == respMac)

	if (encData and string.len(encData) >0) then
		log.output("respSM: encData", hex.hexify(encData));

        elabResp = sm.des3_dec(keyEnc, encData)

		log.output("respSM: elabResp", hex.hexify(elabResp));
	
	else
		elabResp = ""
    end
	log.output("respSM: smMac", hex.hexify(elabResp));

	return sw, elabResp, seq1
end

local function parse_apdu(apdu)
    local header
    local LE = ""
    local data = ""
    local header = string.sub(apdu, 1, 4)
    local lc = string.byte(apdu, 5) or 0
    local data = string.sub(apdu, 6, -1)
    if string.len(apdu) == 4 then
        log.output("parse_apdu(): no data no LC")
        data=""
    elseif string.len(apdu) == 5 then
        LE = string.sub(apdu, -1, -1)
        log.output("parse_apdu(): no data, specified LE:", hex.hexify(LE))
        data=""
    elseif string.len(apdu) == 7 and lc == 0 then
        LE = string.sub(apdu, -2, -1)
        log.output("parse_apdu(): no data, specified extLE:", hex.hexify(LE))
        data=""
    else
        if lc == 0 and string.len(data) > 0 then
            lc = bin.unpack("%>%H", data)
            log.output("parse_apdu: data=", hex.hexify(data))
            log.output("parse_apdu: new LC=", lc)
            log.output("parse_apdu: len data=", string.len(data))
            assert(string.len(data) <= lc +4)
            if string.len(data) >= lc + 3 then
                LE = string.sub(data, lc+2-string.len(data), -1)
                log.output("parse_apdu: new LE=", hex.hexify(LE))
            end
            data = string.sub(data, 3, 3+lc-1)
            log.output("parse_apdu(): with extData, specified extLE:", hex.hexify(LE))
        elseif lc +1 == string.len(data) then
            LE = string.sub(data, -1, -1)
            log.output("parse_apdu(): with data, specified LE:", hex.hexify(LE))
            data = string.sub(data, 1, -2)
        end
    end
    return header, lc, data, LE
end

-- print(repr({parse_apdu(hex.hexf("00a40000"))}))
-- print(repr({parse_apdu(hex.hexf("00a4000000"))}))
-- print(repr({parse_apdu(hex.hexf("00a40000000000"))}))
-- print(repr({parse_apdu(hex.hexf("00a4000000FFFF"))}))
-- print(repr({parse_apdu(hex.hexf("00a4000000000201020000"))}))
-- print(repr({parse_apdu(hex.hexf("00a40000000100%SFFFF", string.rep("\3", 256) ))}))
-- print(repr({parse_apdu(hex.hexf("00a40000000200%SFFFF", string.rep("\3", 512) ))}))
-- print(repr({parse_apdu(hex.hexf("00a40000000200%SFF", string.rep("\3", 512) ))}))
-- os.exit(1)

function CIE3Smartcard.mt:SMTX(ssc, KskEnc, KskSig, apdu, forceExtended)
    local extended
    local header, lc, data, LE = parse_apdu(apdu)

    extended = forceExtended or string.len(LE) > 1 or lc > 255
    local valid = true
    
    local encApdu, ssc = SM(KskEnc, KskSig, apdu, ssc)
    log.output( "SMTX: plainApdu: ", hex.hexify(apdu))
    log.output ("SMTX: encApdu SM:", hex.hexify(encApdu))
    log.output("ssc:", hex.hexify(ssc))
     local resp, sw
    resp = self:transmit(encApdu)
    log.output ("SMTX: resp:", hex.hexify(resp))
    sw, resp, ssc = respSM(KskEnc, KskSig, resp, ssc)
    log.output("resp:", hex.hexify(resp))

    return resp .. sw, valid, ssc
end


function CIE3Smartcard.mt:auto_perform_mutual_authenticate()
    -- funzione fondamentale per per il corretto uso del secure messaging
    -- ha lo scopi di:
    -- 1) individuare una mutua autenticazione valida gi