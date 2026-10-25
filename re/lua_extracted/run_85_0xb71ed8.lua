 libera la reference
        -- if not self:_related_key_exists(obj.kid, obj.num) then
            -- -- libera la kery allocata
            -- usBin = self:virtual_release_kid(
                                -- self._indexes._unused_space_bin,
                                -- obj.kid,
                                -- obj.key_bits,
                                -- hex.hexf("%B", self.arjo_hcard.BSO_PIN)
                                -- )
            -- if string.len(usBin) ~= string.len(self._indexes._unused_space_bin) then
                -- log.output(
                    -- 'destroy_object(): CRITICAL WARNING: no more space left in the unused space file. following KID is lost:',
                        -- obj.kid)
                -- usBin = self._indexes._unused_space_bin
            -- else
                -- -- scrive unused space
                -- self:_write_file(usBin, self.files.US)
                -- self._indexes._unused_space_bin = usBin
            -- end
        -- end
        if pkBin then
            -- scrive private key directory file
            self:_write_file(pkBin, self.files.PrivKD)
            self._indexes._private_keys_bin = pkBin
        end
        
        -- elimina l'oggetto dalla lista
        self.attributes[hObject] = nil
        
        -- rinumera tutti gli oggetti private key con num > obj.num
        self:_renumber_objects(obj)
        
    else
        log.output('destroy_object(): WARNING! Unsupported object class!')
        return CKR.FUNCTION_FAILED
    end
    
    self.attributes[hObject] = nil
    
    self:update_free_mem(self.info)
    return CKR.OK
end

function t.mt:set_attribute_value(hObject, pTemplate)
    log.output('set_attribute_value():', hObject)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local rv
    local obj = self.attributes[hObject]
    if obj == nil then
        log.output('set_attribute_value(): specified handle invalid: ', hObject)
        return CKR.OBJECT_HANDLE_INVALID
    end

    log.output('set_attribute_value(): verify_pin_main() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.arjo_hcard:verify_pin_main(self.cached_main_pin, false)  -- pin, ispuk, check, use_sm
    end
    
    self:invalidate_xproc_cache()
    self.arjo_hcard:auto_perform_mutual_authenticate()
    
    if obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        if not obj.populated then self:get_pubkey(hObject, CKA.CLASS, false, true) end
        rv = self:set_attribute_value_pubkey(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        if not obj.populated then self:get_privkey(hObject, CKA.CLASS) end
        rv = self:set_attribute_value_privkey(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        if not obj.populated then self:get_certificate(hObject, CKA.CLASS, false, true) end
        rv = self:set_attribute_value_certificate(hObject, pTemplate)
        
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
    local fs = p15.parsePubPrivKD(self._indexes._private_keys_bin)
    if type(obj.num) ~= "number" or obj.num > table.getn(fs) then
        log.output('set_attribute_value_privkey(): error: invalid obj.num:', obj.num)
        return CKR.FUNCTION_FAILED
    end
    if pTemplate[CKA.LABEL] or pTemplate[CKA.ID] then
        local v = fs[obj.num]
        v.commonObjectAttributes.label = pTemplate[CKA.LABEL] or v.commonObjectAttributes.label
        v.classAttributes.iD = pTemplate[CKA.ID] or v.classAttributes.iD
        local privKDBin = p15.buildPubPrivKD(fs)
        privKDBin = privKDBin .. string.rep("\000", string.len(self._indexes._private_keys_bin) - string.len(privKDBin))
        if string.len(privKDBin) ~= string.len(self._indexes._private_keys_bin) then
            log.output('set_attribute_value_privkey(): no more space left in Private KD file!')
            return CKR.DEVICE_MEMORY
        end
        self:_write_file(privKDBin, self.files.PrivKD)
        self._indexes._private_keys_bin = privKDBin
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
    
    -- implementato come re-create: cancella il vecchio oggetto e lo ricrea coi nuovi attributi
    
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
    local fs = p15.parseCertDF(self._indexes._certificates_bin)
    if type(obj.num) ~= "number" or obj.num > table.getn(fs) then
        log.output('set_attribute_value_certificate(): error: invalid obj.num:', obj.num)
        return CKR.FUNCTION_FAILED
    end
    if pTemplate[CKA.LABEL] or pTemplate[CKA.ID] then
        local v = fs[obj.num]
        v.commonObjectAttributes.label = pTemplate[CKA.LABEL] or v.commonObjectAttributes.label
        v.classAttributes.iD = pTemplate[CKA.ID] or v.classAttributes.iD
        local certDF = p15.buildCertDF(fs)
        certDF = certDF .. string.rep("\000", string.len(self._indexes._certificates_bin) - string.len(certDF))
        if string.len(certDF) ~= string.len(self._indexes._certificates_bin) then
            log.output('set_attribute_value_certificate(): no more space left in certDF file!')
            return CKR.DEVICE_MEMORY
        end
        self:_write_file(certDF, self.files.CDF)
        self._indexes._certificates_bin = certDF
    end
    
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
            and k ~= CKA.START_DATE and k ~= CKA.END_DATE  then
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
    local fs = p15.parsePubPrivKD(self._indexes._public_keys_bin)
    if type(obj.num) ~= "number" or obj.num > table.getn(fs) then
        log.output('set_attribute_value_pubkey(): error: invalid obj.num:', obj.num)
        return CKR.FUNCTION_FAILED
    end
    if pTemplate[CKA.LABEL] or pTemplate[CKA.ID] then
        local v = fs[obj.num]
        v.commonObjectAttributes.label = pTemplate[CKA.LABEL] or v.commonObjectAttributes.label
        v.classAttributes.iD = pTemplate[CKA.ID] or v.classAttributes.iD
        local pubKDBin = p15.buildPubPrivKD(fs)
        pubKDBin = pubKDBin .. string.rep("\000", string.len(self._indexes._public_keys_bin) - string.len(pubKDBin))
        if string.len(pubKDBin) ~= string.len(self._indexes._public_keys_bin) then
            log.output('set_attribute_value_pubkey(): no more space left in Public KD file!')
            return CKR.DEVICE_MEMORY
        end
        self:_write_file(pubKDBin, self.files.PubKD)
        self._indexes._public_keys_bin = pubKDBin
    end
    
    -- aggiorna i valori in cache
    for k, v in pTemplate do
        obj[k] = v
    end
    return CKR.OK
end



function t.mt:get_object_size(hobj)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj == nil then return CKR.OBJECT_HANDLE_INVALID end
    local oSize = -1

    if obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        oSize = (obj.path and obj.path.length) or -1
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        oSize = 130*4
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        oSize = 130*4
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        oSize = (obj.path and obj.path.length) or -1
    end

    return CKR.OK, oSize
end


function t.mt:get_special_ids(id_class)
    if id_class == 'DS' then
        local ids = {}
        for i=0,11 do
            table.insert(ids, string.format('DS%d', i))
        end
        return ids
    end
end


function t.mt:valid()
    local rv = self.arjo_hcard:valid()
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
        log.output("token-arjo:flush_cache(): initialize: _cache_id:", self._cache_id)
    end
    changed, cache_id = utility.has_token_changed(self, "cache", self._cache_id)
    if changed then
        log.output("token-arjo:flush_cache(): token has changed!")
        self._cache_id = cache_id
        self.info = nil -- rimuove cache oggetti
        self._indexes = nil
        self._private_objects_added = false
        self.attributes = nil
        
        log.output("token-arjo:flush_cache(): rebuilding object's cache")
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
_LOADED['ArjoSmartCard'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
local aes = require 'aes'
local ecdhlib = require "ecdhlib"
local hex = require 'hex'
local util = require 'utility'
local repr = util.repr
local h2i, hexf, hexify = hex.h2i, hex.hexf, hex.hexify
local rsa
local zlib = require 'zlib'
local der = require("der")

local function hexf2(data, ...)
    data = string.gsub(data, "%s", "")
    return hex.hexf(data, unpack(arg))
end

pcall(function() rsa = require("rsa"); end)

-- ArjoSmartcard

local tr_dl

local ArjoSmartcard = {}
ArjoSmartcard.mt = {}
ArjoSmartcard.mt.__index = ArjoSmartcard.mt


ArjoSmartcard.SSCD_APP_SECRET = '30304635374336314637354531333637'
ArjoSmartcard.User_CAN    = '555345525343414e'  --  "USERSCAN"
ArjoSmartcard.User_EXCAN = ArjoSmartcard.User_CAN .. ArjoSmartcard.SSCD_APP_SECRET -- PSEUDO MRZ


ArjoSmartcard.MAX_TRANSMIT_BUFFER_SIZE = 100
ArjoSmartcard.ID_PIN = 2
ArjoSmartcard.ID_PUK = 3

ArjoSmartcard.ArjoSmartcardError = {}
ArjoSmartcard.ArjoSmartcardError.mt = {}
ArjoSmartcard.ArjoSmartcardError.mt.__index = ArjoSmartcard.ArjoSmartcardError.mt

function ArjoSmartcard.ArjoSmartcardError.mt.__tostring(e)
    return "ArjoSmartcardError: " .. (e.msg or '') .. ' ;SW=' .. hex.hexify(e.sw or '') 
end

function ArjoSmartcard.ArjoSmartcardError.new(sw, msg)
    local e = msg .. ' ;sw=' .. hexify(sw or '')
    return e
end


function ArjoSmartcard.new(card)
    local self = {
                    ID_PIN=ArjoSmartcard.ID_PIN,
                    ID_PUK=ArjoSmartcard.ID_PUK,
                    User_EXCAN=hex.hexf(ArjoSmartcard.User_EXCAN),
                    mw_mk="MI".."D" .. "WRC" .. "AN" .. "FF".."2A".."6D9".."159".."9D5".."6D4",
                    }
    self.card = card
    setmetatable(self, ArjoSmartcard.mt)
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
        if tag == 127 then -- 0x7F
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

local function sha256(data)
    local s = md.sha256()
    s:update(data)
    return s:final()
end


local function compute_cmac(plaintext, key, IV)
    IV = IVS or string.rep('\0', 16)
    local ciphertext = aes.AES_CMAC(key, plaintext, string.len(plaintext))
    return string.sub(ciphertext, 1, 8)
end

local function trim_pad_bn(data, padto)
    data = string.sub(data, -padto)
    data = string.rep("\000", padto - string.len(data)) .. data
    return data
end

-- local function pad_iso9797(data, padding_length)
    -- local l = string.len(data)
    -- local m = math.mod(l, padding_length)
    -- if l == 0 or m == 0 then
        -- return data
    -- end
    -- return data .. string.rep('\000', padding_length-m)
-- end

local function pad_iso9797_2(data, padding_length)
    local l = string.len(data)
    local m = math.mod(l, padding_length)
    local x = data .. "\128" .. string.rep('\000', padding_length-1-m)
    return x
    
end

local function unpad_iso9797_2(data, padding_length)
    local l = string.len(data)
    for i=1,padding_length do
        if string.byte(data, l-i) == 128 then
            return string.sub(data, 1, l-i-1)
        end
    end
end



local function inc_ssc(ssc1)
    local ssc1_low = string.sub(ssc1, -3, -1)
    local ssc1_hi = string.sub(ssc1, 1, -4)
    local ssc1_low_num = bin.unpack("%>%L", "\000" .. ssc1_low)
    ssc1_low_num = ssc1_low_num +1
    ssc1_low = hex.hexf("%>%L", ssc1_low_num)
    
    local ssc = ssc1_hi .. string.sub(ssc1_low, -3, -1)
    log.output("SSC:+1", hex.hexify(ssc))
    return ssc
end


local function cypher(key, text, _IV)
    return aes.AES_CBC(key, text, true, _IV)
end

local function decypher(key, text, _IV)
    return aes.AES_CBC(key, text, false, _IV)
end

local function protectAPDU(ssc1, KSenc, KSmac, header, data_field, le, extended)
        
        -- 9303 parte 11  (9863 des  9873  aes (9862 des) (9872 aes))
        log.output ('header: ', hex.hexify(header))
        log.output ('data_field: ', hex.hexify(data_field))
        log.output ('le: ', hex.hexify(le))
        
        local cla_f = bin.flags(string.byte(header, 1))
        local ins = string.byte(header, 2)
        local EvenIns = math.mod(ins, 2) == 0
        local tag_97 = ""
        
        cla_f = cla_f * bin.flags("0xF0" )
        cla_f = cla_f + bin.flags("0x0C" )
        local padding_length = 16

        --   a) Increment SSC
        local extended_ssc = inc_ssc(ssc1)

        -- Mask Class and Pad command Header
        local UnpaddedCmdHeader = string.char(cla_f.asnumber) .. string.sub(header, 2, 4)
        log.output ('UnpaddedCmdHeader: ', hex.hexify(UnpaddedCmdHeader))

        -- Pad Data
        local Data = data_field
        log.output('Data: ', hex.hexify(Data))

        local CmdHeader = pad_iso9797_2(UnpaddedCmdHeader, padding_length)
        log.output ('CmdHeader: ', hex.hexify(CmdHeader))
        local iv, EncryptedData_bin, EncryptedData
        
        if string.len(Data) > 0 then
            local Pad_Data = pad_iso9797_2(Data, padding_length)
            log.output ('Pad_Data: ', hex.hexify(Pad_Data))
            log.output ('cypher ssc with KSenc: ', hex.hexify(extended_ssc), hex.hexify(KSenc))

            -- Encrypt with KSenc
            iv = string.sub(cypher(KSenc, extended_ssc), 1, 16)
            EncryptedData = cypher(KSenc, Pad_Data, iv)
            log.output ('EncryptedData: ', hex.hexify(EncryptedData))
        else
            EncryptedData = ''
        end
        if type(le) == "string" and string.len(le) >0 then  -- Commands with response (Le field not empty) have a protected Le-field (Tag 97) in the command data.
            if extended and string.len(le) <= 1 then
                le = string.rep("\0", 2 - string.len(le)) .. le
            end
            tag_97 = hex.hexf('97%P', le)
        end
        
        local M
        local DO87_85
        if string.len(Data) > 0 then
            local tagID = "85"  --  # For a command with odd INS, any command data is encrypted and capsulated in a Tag 85 without padding indicator
            local EncryptedDataE = EncryptedData
                if EvenIns then  -- For a command with even INS, any command data is encrypted and capsulated in a Tag 87 with padding indicator (01)
                -- Build 87 Tag
                tagID = "87"
                EncryptedDataE = '\001' .. EncryptedData
            end
            if string.len(EncryptedDataE) >= 256 then
                DO87_85 = hex.hexf(tagID..'82%>%H%S', string.len(EncryptedDataE), EncryptedDataE ) .. tag_97
            elseif string.len(EncryptedDataE) >= 128 then
                DO87_85 = hex.hexf(tagID..'81%P', EncryptedDataE ) .. tag_97
            else
                DO87_85 = hex.hexf(tagID..'%P', EncryptedDataE ) .. tag_97
            end
        else
            DO87_85 = tag_97
        end
        
        log.output ('DO87_85: ', hex.hexify(DO87_85))
        M = CmdHeader .. DO87_85
        log.output ('M: ', hex.hexify(M))
        
        local extended_ssc_M = extended_ssc .. M

        
        log.output ('extended_ssc_M: ', hex.hexify(extended_ssc_M))

        -- Compute MAC of M:
        --   1) Concatenate SSC and M and add padding:
        local N = pad_iso9797_2(extended_ssc_M, padding_length)
        log.output ('N: ', hex.hexify(N))

        --  2) Compute MAC over N with KSMAC:
        local CC = compute_cmac(N, KSmac)

        -- Build 8E Tag
        local DO8E = hex.hexf('8E%P', CC)

        log.output ('DO8E: ', hex.hexify(DO8E))

        --  Build ProtectedAPDU
        local protected_apdu_data = DO87_85 .. DO8E

        local _ext_len = string.len(protected_apdu_data)
        local ext_len
        if extended or _ext_len > 255 then
            extended=true
            ext_len = hex.hexf('00%H', _ext_len)
        else
            ext_len = hex.hexf('%B', _ext_len)
        end

        -- if extended then
            -- ext_len = '\0\0' .. ext_len
        -- end
        local ProtectedAPDU = UnpaddedCmdHeader .. ext_len .. protected_apdu_data .. (extended and "\0\0" or '\0')
        log.output ("ProtectedAPDU: ", hex.hexify(ProtectedAPDU))
        return ProtectedAPDU, extended_ssc, EvenIns

end


local function unprotectAPDUResponse(ssc1, keyEnc, keyMac, response)
    log.output("unprotectAPDUResponse():")
    if string.len(response) == 2 then
        log.output("unprotectAPDUResponse(): SW only response:", hex.hexify(response))
        return response, true, ssc1
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
        if tag == 135 or tag == 133 then -- 0x87 or 0x85
            -- decrypt
            if ssc == ssc1 then
                ssc = inc_ssc(ssc)
            end
            local TODEC = string.sub(data, i+3, i+2+le)
            log.output("TAG 87 ENC:", hex.hexify(TODEC))
            
            if tag == 135 then
                TODEC = string.sub(TODEC, 2, -1)
            end
            local IV = string.sub(cypher(keyEnc, ssc), 1, 16)
            local dec = decypher(keyEnc, TODEC, IV)
            log.output("TAG 87 dec:", hex.hexify(dec))
            responsedec = responsedec .. unpad_iso9797_2(dec, 16)
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
            if ssc == ssc1 then
                ssc = inc_ssc(ssc)
            end
            local MAC = string.sub(data, i+3, i+2+le)
            log.output("TAG 8E MAC:", hex.hexify(MAC))
            local toMAC = pad_iso9797_2(ssc .. DATATOMAC, 16)
            local MAC2 = compute_cmac(toMAC, keyMac)
            log.output("TAG 8E MAC2:", hex.hexify(MAC2))
            valid = (MAC2 == MAC)
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

function ArjoSmartcard.mt:SMTX(ssc, KskEnc, KskSig, apdu, forceExtended)
    local extended
    local header, lc, data, LE = parse_apdu(apdu)

    extended = forceExtended or string.len(LE) > 1 or lc > 255
    local encApdu, ssc = protectAPDU(ssc, KskEnc, KskSig, header, data, LE, extended)
    log.output( "SMTX: plainApdu: ", hex.hexify(apdu))
    log.output ("SMTX: encApdu SM:", hex.hexify(encApdu))
    log.output("ssc:", hex.hexify(ssc))
     local resp, valid
    resp = self:transmit(encApdu)
    log.output ("SMTX: resp:", hex.hexify(resp))
    resp, valid, ssc = unprotectAPDUResponse(ssc, KskEnc, KskSig, resp)
    log.output("resp:", hex.hexify(resp))

    return resp, valid, ssc
end


function ArjoSmartcard.mt:set_card_ca_certs(cacerts)
    self._cacerts = cacerts
end

function ArjoSmartcard.mt:auto_perform_mutual_authenticate()
    -- funzione fondamentale per per il corretto uso del secure messaging
    -- ha lo scopi di:
    -- 1) individuare una mutua autenticazione valida gi