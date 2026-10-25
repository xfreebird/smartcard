 libera la reference
        if not self:_related_key_exists(obj.kid, obj.num) then
            -- libera la kery allocata
            usBin = self:virtual_release_kid(
                                self._indexes._unused_space_bin,
                                obj.kid,
                                hex.hexf("%B", self.gemalto_hcard.BSO_PIN)
                                )
            if string.len(usBin) ~= string.len(self._indexes._unused_space_bin) then
                log.output(
                    'destroy_object(): CRITICAL WARNING: no more space left in the unused space file. following KID is lost:',
                        obj.kid)
                usBin = self._indexes._unused_space_bin
            else
                -- scrive unused space
                self:_write_file(usBin, self.files.US)
                self._indexes._unused_space_bin = usBin
            end
        end
        if pkBin then
            -- scrive private key directory file
            self:_write_file(pkBin, self.files.PrivKD)
            self._indexes._private_keys_bin = pkBin
        end
        
        -- elimina l'oggetto dalla lista
        self.attributes[hObject] = nil
        
        -- rinumera tutti gli oggetti private key con num > obj.num
        self:_renumber_objects(obj)

        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        log.output('destroy_object(): destroyng a data object')
        local index_bin, index_file, authId
        local dataBin
        local usBin
        if obj.private then
            index_bin = self._indexes._private_data_objects_bin
            index_file = self.files.DCODF_Priv
            authId = hex.hexf("%B", self.gemalto_hcard.BSO_PIN)
        else
            index_bin = self._indexes._data_objects_bin
            index_file = self.files.DCODF_Pub
        end
        
        -- rimuove la entry indicata da "obj.num" dall'index
        local d = p15.parsePubPrivDataD(index_bin)
        if obj.num > table.getn(d) then
            log.output('destroy_object(): obj.num invalid:', obj.num)
            return CKR.FUNCTION_FAILED
        end
        table.remove(d, obj.num)
        dataBin = p15.buildPubPrivDataD(d)
        dataBin = dataBin .. string.rep("\000", string.len(index_bin) - string.len(dataBin))
        
        -- libera lo spazio allocato
        usBin = self:virtual_release_space(
                                self._indexes._unused_space_bin,
                                obj.path.efidOrPath,
                                obj.path.index,
                                obj.path.length,
                                authId)
                                            
        -- riscrive gli indici:
        
        if string.len(usBin) ~= string.len(self._indexes._unused_space_bin) then
            log.output(
                'destroy_object(): CRITICAL WARNING: no more space left in the unused space file. following Space is lost:',
                    hex.hexify(obj.path.efidOrPath),
                    obj.path.index,
                    obj.path.length)
            usBin = self._indexes._unused_space_bin
        else
            -- scrive unused space
            self:_write_file(usBin, self.files.US)
            self._indexes._unused_space_bin = usBin
        end
        -- azzera lo spazio occupato
        -- self:_write_file(string.rep("\000", obj.path.length), obj.file, obj.path.index)
        
        
        if dataBin then
            -- scrive data object directory file
            self:_write_file(dataBin, index_file)

            if obj.private then
                self._indexes._private_data_objects_bin = dataBin
            else
                self._indexes._data_objects_bin = dataBin
            end
        end
        
        -- elimina l'oggetto dalla lista
        self.attributes[hObject] = nil
        
        -- rinumera tutti gli oggetti data con num > obj.num
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
        self.gemalto_hcard:verify_pin_main(self.cached_main_pin, false, false, true)  -- pin, ispuk, check, use_sm
    end
    
    self:invalidate_xproc_cache()
    self.gemalto_hcard:auto_perform_mutual_authenticate()
    
    if obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        if not obj.populated then self:get_pubkey(hObject, CKA.CLASS, false, true) end
        rv = self:set_attribute_value_pubkey(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        if not obj.populated then self:get_privkey(hObject, CKA.CLASS) end
        rv = self:set_attribute_value_privkey(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        if not obj.populated then self:get_certificate(hObject, CKA.CLASS, false, true) end
        rv = self:set_attribute_value_certificate(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        if not obj.populated then self:get_data_object(hObject, CKA.CLASS) end
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

    local rv = self:destroy_object(hObj)
    if rv ~= CKR.OK then
        log.output("set_attribute_value_certificate(): error deleting the old object!")
        return rv
    end
    local rv, hNewObj = self:create_object_data(templateNew)
    
    local newObj = self.attributes[hNewObj]
    self.attributes[hObj] = newObj
    self.attributes[hNewObj] = nil
    
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



function t.mt:set_attribute_value_data(hObj, pTemplate)
    log.output('set_attribute_value_data()')
    local obj = self.attributes[hObj]
    
    -- implementato come re-create: cancella il vecchio oggetto e lo ricrea coi nuovi attributi
    
    if obj.private and self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    
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
    
    local rv = self:destroy_object(hObj)
    if rv ~= CKR.OK then
        log.output("set_attribute_value_data(): error deleting the old object!")
        return rv
    end
    local rv, hNewObj = self:create_object_data(templateNew)
    
    local newObj = self.attributes[hNewObj]
    self.attributes[hObj] = newObj
    self.attributes[hNewObj] = nil
    
    return CKR.OK
    
end


function t.mt:get_object_size(hobj)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj == nil then return CKR.OBJECT_HANDLE_INVALID end
    local oSize = -1
    
    if self:is_user_consent_key(obj.kid) then
        if obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
            oSize = 130*4
        elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
            oSize = 130*4
        end       
    else
        
        if obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
            oSize = (obj.path and obj.path.length) or -1
        elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
            oSize = 130*4
        elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
            oSize = 130*4
        elseif obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
            oSize = (obj.path and obj.path.length) or -1
        end
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
    local rv = self.gemalto_hcard:valid()
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
        log.output("token-gemalto-classic:flush_cache(): initialize: _cache_id:", self._cache_id)
    end
    changed, cache_id = utility.has_token_changed(self, "cache", self._cache_id)
    if changed then
        log.output("token-gemalto-classic:flush_cache(): token has changed!")
        self._cache_id = cache_id
        self.info = nil -- rimuove cache oggetti
        self._indexes = nil
        self._private_objects_added = false
        self.attributes = nil
        
        log.output("token-gemalto-classic:flush_cache(): rebuilding object's cache")
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
_LOADED['StarCosSKP23Smartcard'] = { magic = '__TOBELOADED__', loadfn = function()
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

-- StarCosSKP23Smartcard

local tr_dl

local StarCosSKP23Smartcard = {}
StarCosSKP23Smartcard.mt = {}
StarCosSKP23Smartcard.mt.__index = StarCosSKP23Smartcard.mt


StarCosSKP23Smartcard.PIN_PADDING = 8
StarCosSKP23Smartcard.PUK_PADDING = 8
StarCosSKP23Smartcard.PADDING_CHAR = "\000"
StarCosSKP23Smartcard.BSO_PIN = h2i('82')
StarCosSKP23Smartcard.BSO_PUK = h2i('83')
StarCosSKP23Smartcard.ID_FIRST_KID = 4

StarCosSKP23Smartcard.MAX_TRANSMIT_BUFFER_SIZE = 120

StarCosSKP23Smartcard.StarCosSKP23SmartcardError = {}
StarCosSKP23Smartcard.StarCosSKP23SmartcardError.mt = {}
StarCosSKP23Smartcard.StarCosSKP23SmartcardError.mt.__index = StarCosSKP23Smartcard.StarCosSKP23SmartcardError.mt

function StarCosSKP23Smartcard.StarCosSKP23SmartcardError.mt.__tostring(e)
    return "StarCosSKP23SmartcardError: " .. (e.msg or '') .. ' ;SW=' .. hex.hexify(e.sw or '') 
end

function StarCosSKP23Smartcard.StarCosSKP23SmartcardError.new(sw, msg)
    local e = msg .. ' ;sw=' .. hexify(sw or '')
    return e
end


function StarCosSKP23Smartcard.new(card)
    local self = {
                    PIN_PADDING=StarCosSKP23Smartcard.PIN_PADDING,
                    PUK_PADDING=StarCosSKP23Smartcard.PUK_PADDING,
                    PADDING_CHAR=StarCosSKP23Smartcard.PADDING_CHAR,
                    BSO_PIN=StarCosSKP23Smartcard.BSO_PIN, BSO_DS_PIN=StarCosSKP23Smartcard.BSO_DS_PIN,
                    BSO_PUK=StarCosSKP23Smartcard.BSO_PUK, BSO_DS_PUK=StarCosSKP23Smartcard.BSO_DS_PUK,
                    ID_FIRST_KID = StarCosSKP23Smartcard.ID_FIRST_KID,
                  }
    self.card = card
    setmetatable(self, StarCosSKP23Smartcard.mt)
    return self
end


function StarCosSKP23Smartcard.mt:select_p15()
    log.output("direct transmit: select_p15()")
    local res = self.card:transmit(hex.hexf("00a4040c0cA000000063504B43532D3135"))
    assert (string.sub(res, -2, -1) == hex.hexf("9000") )
    self._p15_aid_selected = true
end

function StarCosSKP23Smartcard.mt:get_pin_puk_status()
    local pinstatus = hex.hexf("80F200%B01", self.BSO_PIN);
    local pukstatus = hex.hexf("80F200%B01", self.BSO_PUK);
    local resPin = self:transmit(pinstatus)
    local resPuk = self:transmit(pukstatus)
    assert (string.sub(resPin, -2, -1) == hex.hexf("9000") )
    assert (string.sub(resPuk, -2, -1) == hex.hexf("9000") )
    local pinRetry = (bin.flags(string.byte(resPin, 1)) * bin.flags(h2i("0F"))).asnumber
    local pinRetryMax = (bin.flags(string.byte(resPin, 1)) * bin.flags(h2i("F0"))).asnumber / 16
    local pukRetry = (bin.flags(string.byte(resPuk, 1)) * bin.flags(h2i("0F"))).asnumber
    local pukRetryMax = (bin.flags(string.byte(resPuk, 1)) * bin.flags(h2i("F0"))).asnumber / 16
    return pinRetry, pinRetryMax, pukRetry, pukRetryMax
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
-------------------------------------------------------

function StarCosSKP23Smartcard.parse_fci(fci)
    local fci1 = parse_tlv_ber(fci)
    local fci2 = parse_tlv_ber(fci1[98] or fci1[111]) -- 0x62 or 0x6F
    local infos = {size=(fci2[128] or fci2[129]) and bin.unpack("%H", fci2[128] or fci2[129]),
                      filetype = fci2[130] and string.byte(fci2[130], 1),
                      options=fci2[130],
                      fid_n=fci2[131] and bin.unpack("%H", fci2[131]),
                      fid =fci2[131],
                      sc = fci2[140],
                      }
    return infos
end

function StarCosSKP23Smartcard.mt:transmit(apdu)

    if not self._p15_aid_selected then
        log.output("StarCosSKP23Smartcard.mt:transmit(): checking P15 select status...")
        local pinstatus = hex.hexf("80F200%B01", self.BSO_PIN);
        local resPin = self.card:transmit(pinstatus)
        if string.sub(resPin, -2, -1) ~= hex.hexf("9000") then
            self:select_p15()
        end
    end

    local header, data = string.sub(apdu, 1, 4), string.sub(apdu, 6)
    if string.len(apdu) <= 5 then -- APDU con il solo LE
        header, data = apdu, nil
    end
    local result, scarderr = self.card:transmit(apdu)
    if not result then
        error(StarCosSKP23Smartcard.StarCosSKP23SmartcardError.new('', string.format('transmit error: 0x%x', scarderr) ))
    end
    self.last_sw = string.sub(result, -2, -1)
    return result
end


function StarCosSKP23Smartcard.mt:sm_transmit(apdu)
    return self:transmit(apdu)
end

function StarCosSKP23Smartcard.mt:select(path, relative)
    local sw, recv
    local select_path = {}
    if not relative then
        if string.sub(path, 1, 2) ~= hexf('3f00') then
            table.insert(select_path, hexf("3f00") )    
        end
        for i=1,string.len(path),2 do
            table.insert(select_path, string.sub(path, (i-1)*2+1, (i-1)*2+2))
        end
    else
        table.insert(select_path, path)
    end
    
    for i, v in select_path do
        recv = self:transmit(hexf('00A40000%P', v))
        local sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') and sw ~= hexf('6284') then
            error(StarCosSKP23Smartcard.StarCosSKP23SmartcardError.new(sw, 'select Error'), 2)
        end
    end
    if string.len(recv) > 2 then
        return StarCosSKP23Smartcard.parse_fci(recv)
    end
end

function StarCosSKP23Smartcard.mt:read_binary(offset, size)
    local recv
    log.output("reading from:", offset, "size:", size)
    local apdu = hexf('00B0%H%B', offset, size)
    log.output("read_binary apdu:", hex.hexify(apdu))
    recv = self:sm_transmit(apdu)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') and sw ~= hexf('6282') then
        error(StarCosSKP23Smartcard.StarCosSKP23SmartcardError.new(sw, 'read_binary Error'), 2)
    end
    return string.sub(recv, 1, -3)
end

function StarCosSKP23Smartcard.mt:mread_binary(offset, size)
    local buffer_size = StarCosSKP23Smartcard.MAX_TRANSMIT_BUFFER_SIZE
    log.output("multi reading from:", offset, "size:", size, "chunks:", buffer_size)
    local content = ''
    while size>0 do
        if size<buffer_size then buffer_size = size end
        local recv = self:read_binary(offset, buffer_size)
        offset = offset  + buffer_size
        size = size - buffer_size
        content = content .. string.sub(recv, 1, buffer_size)
    end
    return content
end


function StarCosSKP23Smartcard.mt:verify(bso, pin, backtracking)
    return self:sm_verify(bso, pin, backtracking)
end

function StarCosSKP23Smartcard.mt:sm_verify(bso, pin, backtracking)
    if string.len(pin) == 0 then
        log.output('sm_verify(): checking pin status...')
    end
    if backtracking then
        bso = (bin.flags(bso) + bin.flags(128)).asnumber
    end
    local sw = self:sm_transmit(hexf('002000%B%P', bso, pin))
    if sw == hexf('6983') then
        return 2, 'Authentication blocked'
    elseif string.sub(hexify(sw), 1, 2) == '63' then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        return 0, 'Authentication succeeded'
    else
        log.output('sm_verify(): Error ' .. hexify(sw) )
        error(StarCosSKP23Smartcard.StarCosSKP23SmartcardError.new(sw, 'sm_verify Error' ), 2)
    end
end


function StarCosSKP23Smartcard.mt:sm_change(bso, oldPin, newPin, backtracking)
    if backtracking then
        bso = (bin.flags(bso) + bin.flags(128)).asnumber
    end
    local apdu = hex.hexf('802420%B%P', bso, oldPin .. newPin)
    local sw = self:sm_transmit(apdu)
    if sw == hexf('6983') then
        return 2, 'Authentication blocked'
    elseif bin.mask_compare(sw, hexf('6300'), hexf('FF00')) then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        return 0, 'Authentication succeeded'
    else
        log.output('sm_change(): Error ' .. hexify(sw) )
        error(StarCosSKP23Smartcard.StarCosSKP23SmartcardError.new(sw, 'sm_change Error' ), 2)
    end
end


function StarCosSKP23Smartcard.mt:begin_transaction()
    self.card:begintransaction()
end

function StarCosSKP23Smartcard.mt:end_transaction()
    self._p15_aid_selected = false
    self.card:endtransaction()
end


function StarCosSKP23Smartcard.mt:on_end_transaction()
    log.output('StarCosSKP23Smartcard:on_end_transaction()...')
    self._p15_aid_selected = false
end


function StarCosSKP23Smartcard.mt:sm_reset_retry_counter(bso, Puk, newPin, backtracking)
    if backtracking then
        bso = (bin.flags(bso) + bin.flags(128)).asnumber
    end
    
    
    local sw = self:sm_transmit(hexf2("80F401000D C2 0B %B 0000", bso) .. newPin)
    if sw == hexf('6983') then
        return 2, 'Authentication blocked'
    elseif bin.mask_compare(sw, hexf('6300'), hexf('FF00')) then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        return 0, 'Authentication succeeded'
    else
        log.output('sm_reset_retry_counter(): Error ' .. hexify(sw) )
        error(StarCosSKP23Smartcard.StarCosSKP23SmartcardError.new(sw, 'sm_reset_retry_counter Error' ), 2)
    end
end

function StarCosSKP23Smartcard.mt:valid()
    local status, err = self.card:status()
    if not status then
        log.output('StarCosSKP23Smartcard:valid(): status() error', hex.tohex8(err or 0))
        return false
    elseif status.protocol == 0 or string.len(status.atr or '') == 0 then
        log.output('StarCosSKP23Smartcard:valid(): card removed?')
        return false
    end
    return true
end

---------------------------------------------------
function StarCosSKP23Smartcard.handle_error(err_obj)
    print(debug.traceback(err_obj))
    return err_obj
end

local function invert_string(s)
    local inv_s = ""
    for i=1,string.len(s) do
            inv_s = string.sub(s, i, i) .. inv_s
    end
    return inv_s
end
local function extract_mod_exp(resp)
    local kfl_len = string.byte(resp, 11)
    local modIndex, expIndex = 0, 0
    local MOD, EXP, from
    for i=1,kfl_len,2 do
        local tag = string.byte(resp, 11+i)
        local len = string.byte(resp, 11+i+1)
        if tag == 16 then
            from = 11+kfl_len+1+modIndex
            MOD = string.sub(resp, from, from+len-1)
            expIndex = expIndex + len
        elseif tag == 19 then
            from = 11+kfl_len+1+expIndex
            EXP = string.sub(resp, from, from+len-1)
            modIndex = modIndex + len
        else
            expIndex = expIndex + len
            modIndex = modIndex + len
        end
    end
    while string.byte(EXP, -1) == 0 do
        EXP = string.sub(EXP, 1, -2)
    end
    return invert_string(MOD), invert_string(EXP)
end

-- path_key: ascii hex string, returns modulis,exponent as binary string
function StarCosSKP23Smartcard.mt:read_public_key(kid)

    if kid == nil then kid = '3'
    elseif type(kid) == 'number' then 
        kid = hex.hexify(hex.hexf('%B', kid))
    elseif string.len(kid) == 1 then 
        kid = hex.hexify(kid)
    end
    local resp
    local getPubKey = "80F09C0001" .. kid .. "00"
    getPubKey = hex.hexf(getPubKey)
    resp = self:sm_transmit(getPubKey)
    local sw = string.sub(resp, -2, -1)
    
    local MOD, EXP = extract_mod_exp(resp)


    return MOD, EXP
end


-- pin binary string;
function StarCosSKP23Smartcard.mt:verify_pin_main(pin, ispuk)
    log.output('verify_pin_main():', pin, ispuk)
    local bso = self.BSO_PIN
    local padding = self.PIN_PADDING
    if ispuk then
        bso = self.BSO_PUK
        padding = self.PUK_PADDING
    end
    if string.len(pin)> padding then
        pin = string.sub(pin, 1, padding)
    end
    pin = pin .. string.rep(self.PADDING_CHAR, padding - string.len(pin))
    return self:sm_verify(bso, pin, false)
end

function StarCosSKP23Smartcard.mt:change_pin_main(oldPin, newPin, ispuk)
    local bso = self.BSO_PIN
    local padding = self.PIN_PADDING
    if ispuk then
        bso = self.BSO_PUK
        padding = self.PUK_PADDING
    end
    if string.len(oldPin or '') > padding then
        oldPin = string.sub(oldPin, 1, padding)
    end
    if string.len(newPin) > padding then
        error('StarCosSKP23Smartcard change_pin_main Error: wrong PIN size', 2)
    end
    if oldPin then
        oldPin = oldPin .. string.rep(self.PADDING_CHAR, padding - string.len(oldPin))
    end
    newPin = newPin .. string.rep(self.PADDING_CHAR, padding - string.len(newPin))
    log.output('StarCosSKP23Smartcard:valid(): changing from:', hex.hexify(oldPin), "to:", hex.hexify(newPin))

    return self:sm_change(bso, oldPin, newPin, false)
end


function StarCosSKP23Smartcard.mt:reset_pin_main(Puk, newPin)
    if string.len(Puk or '' ) > self.PUK_PADDING then
        Puk = string.sub(Puk, 1, self.PUK_PADDING)
    end
    if string.len(newPin) > self.PIN_PADDING then
        error('StarCosSKP23Smartcard reset_pin_main Error: wrong PIN size', 2)
    end
    Puk = Puk .. string.rep(self.PADDING_CHAR, self.PUK_PADDING - string.len(Puk))
    newPin = newPin .. string.rep(self.PADDING_CHAR, self.PIN_PADDING - string.len(newPin))
    local res
    
    res = self:verify_pin_main(Puk, true, false)
    if res ~= 0 then return res end
    return self:sm_reset_retry_counter(self.BSO_PIN, Puk, newPin, false)
end


function StarCosSKP23Smartcard.mt:pso_rsa_internal_authenticate(data, id, pin)
    local sw, resp
    if type(id) == 'number' then 
        id = hex.hexify(hex.hexf('%B', id))
    elseif string.len(id) == 1 then 
        id = hex.hexify(id)
    end
    repeat 
        -- A4: AT autneticazione
        -- 84 01 KID
        -- 80 01 ALGO = 02
        local seSet = hex.hexf("002241A4068401" .. id .. "800102")
        resp = self:sm_transmit(seSet)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end
        
        if pin and string.len(pin) > 0 then
            local res = self:verify_pin_main(pin, false, false)
            if res ~= 0 then
                error(StarCosSKP23Smartcard.StarCosSKP23SmartcardError.new(sw, 
                    'pso_cds error: verify_pin_main failed!' ), 2)
            end
        end
        local pso_apdu = hex.hexf("00881000%P", data)
        resp = self:sm_transmit(pso_apdu)
        sw = string.sub(resp, -2, -1)

        break
    until true
    
    if sw ~= hexf('9000') then
        error(StarCosSKP23Smartcard.StarCosSKP23SmartcardError.new(sw, 'pso_cds error' ), 2)
    end
    return string.sub(resp, 1, -3)
end


function StarCosSKP23Smartcard.mt:pso_decrypt(data, id)

    local sw, resp
    if type(id) == 'number' then 
        id = hex.hexify(hex.hexf('%B', id))
    elseif string.len(id) == 1 then 
        id = hex.hexify(id)
    end
    repeat
        seSetCT = hex.hexf("002241b8068401" .. id .. "800102")
        resp = self:sm_transmit(seSetCT)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end
        
        local pso_dec = hex.hexf("002a8086%P00", "\000" .. data)
        resp = self:sm_transmit(pso_dec)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end
        
        break
    until true
    
    if sw ~= hexf('9000') then
        error(StarCosSKP23Smartcard.StarCosSKP23SmartcardError.new(sw, 'pso_decrypt error' ), 2)
    end
    return string.sub(resp, 1, -3)
end

function StarCosSKP23Smartcard.mt:import_pub_key(id, ipf_fid, MOD, EXP)
    if type(id) == 'number' then 
        id = hex.hexify(hex.hexf('%B', id))
    elseif string.len(id) == 1 then 
        id = hex.hexify(id)
    end
    local idn = tonumber(id, 16)

    local index = (idn - 128 - self.ID_FIRST_KID )
    local offset = index * tonumber("9b", 16) + 1
    ipf_fid = ipf_fid or hex.hexf("4601")
    local pEXP = string.rep("\000", 4 - string.len(EXP)) .. EXP
    self:select(ipf_fid, true)
    local iMOD = hex.hexify(invert_string(MOD))
    local iEXP = hex.hexify(invert_string(pEXP))
    -- HEADER(10) + KFL + CHA=KID + MOD(80) + EXP(4) + CHR=00 + CPI=03 + CHA=00
    local record = id .. "008F9F0F00094A808F080101108013040001" .. id .. iMOD .. iEXP .. "000300"
    record = hex.hexf(record)
    self:mupdate_binary(offset, record)
    
end

function StarCosSKP23Smartcard.mt:generate_key_pair(id, ipf_fid)
    
    local sw, resp
    if type(id) == 'number' then 
        id = hex.hexify(hex.hexf('%B', id))
    elseif string.len(id) == 1 then 
        id = hex.hexify(id)
    end
    local idn = tonumber(id, 16)
    log.output("attempting to generate id:", id)
    
    ipf_fid = ipf_fid or hex.hexf("4601")
    self:select(ipf_fid, true)
    
    local index = (idn - 128 - self.ID_FIRST_KID )
    local offset = index * tonumber("9b", 16) + 1
    local record = hex.hexf(id .. "008C9F0F00094A808C06010110801304" .. id)
    self:mupdate_binary(offset, record)
    local generate = "004600" .. id .. "020400"
    generate = hex.hexf(generate)
    resp = self:sm_transmit(generate)
    sw = string.sub(resp, -2, -1)
    if sw ~= hexf('9000') then
        error(StarCosSKP23Smartcard.StarCosSKP23SmartcardError.new(sw, 'generate_key_pair error' ), 2)
    end
    
    local MOD, EXP = self:read_public_key(id)
    self:import_pub_key(id, ipf_fid, MOD, EXP)
    return MOD, EXP
end

function StarCosSKP23Smartcard.mt:read_serial_number()
    if not self.CSN then
        self:select_p15()
        self.CSN = self:transmit(hexf("80F6000008"))
        self.CSN = string.sub(self.CSN, 1, 8)
        self.CSN = hex.hexify(self.CSN)
    end
    return self.CSN
end

function StarCosSKP23Smartcard.mt:update_binary(offset, data)
    local apdu = hex.hexf('00D6%H%P', offset, data)
    local recv, sw
    recv =  self:sm_transmit(apdu)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(StarCosSKP23Smartcard.StarCosSKP23SmartcardError.new(sw, 'update_binary Error'), 2)
    end
end


function StarCosSKP23Smartcard.mt:mupdate_binary(offset, data)
    local buffer_size = StarCosSKP23Smartcard.MAX_TRANSMIT_BUFFER_SIZE
    local left = string.len(data)
    local curOffset = offset
    local chunk
    while left > 0 do
        chunk = string.sub(data, curOffset-offset+1, curOffset-offset + buffer_size)
        if chunk == 0 then
            log.output("mupdate_binary(): WARNING: specified data len is not enough?")
            break
        end
        self:update_binary(curOffset, chunk)
        left = left - string.len(chunk)
        curOffset = curOffset + string.len(chunk)
    end
end


local function trim_pad_bn(data, padto)
    data = string.sub(data, -padto)
    data = string.rep("\000", padto - string.len(data)) .. data
    return data
end

function StarCosSKP23Smartcard.mt:import_private_key(id, ipf_fid, m, e, d)
    ipf_fid = ipf_fid or hex.hexf("4601")
    local resp
    local iD, iM
    local import, data
    if type(id) == 'number' then 
        id = hex.hexify(hex.hexf('%B', id))
    elseif string.len(id) == 1 then 
        id = hex.hexify(id)
    end

    m = trim_pad_bn(m, 128) -- taglia a 1024 bit
    iM = invert_string(m)
    if d then
        d = trim_pad_bn(d, 128) -- taglia a 1024 bit
        iD = invert_string(d)
        iD = string.rep("\000", tonumber("90", 16) - string.len(iD)) .. iD
    end
    assert(e == nil or string.len(e) <= 4)
    
    self:import_pub_key(id, ipf_fid, m, e)
    
    if d then
        data = hex.hexf("06908093900057") .. iM .. iD .. string.rep("\000", 87)
        
        import = hex.hexf(("80F4010080C27E" .. id .. "0000")) .. string.sub(data, 1, 123)
        resp = self:sm_transmit(import)
        self.last_sw = string.sub(resp, -2, -1)
        assert(self.last_sw == hexf("9000") )
        
        import = hex.hexf(("80F4010080C27E" .. id .. "007B")) .. string.sub(data, 124, 246)
        resp = self:sm_transmit(import)
        self.last_sw = string.sub(resp, -2, -1)
        assert(self.last_sw == hexf("9000") )
        
        import = hex.hexf(("80F401007DC27B" .. id .. "00F6")) .. string.sub(data, 247)
        resp = self:sm_transmit(import)
        self.last_sw = string.sub(resp, -2, -1)
        assert(self.last_sw == hexf("9000") )
   end
end


-- function test_apdus()
    -- local ctx, err = pcsc.establishcontext()
    -- local readers = ctx:listreaders() or {}
    -- local card
    -- for i, reader_name in readers do
        -- print ("slot:", reader_name)
        -- local new_hcard, err = ctx:connect(reader_name, pcsc.SHARE_SHARED, pcsc.PROTOCOL_Tx)  
        -- print ("slot connect:", reader_name, new_hcard, err)
        -- if new_hcard
           -- and new_hcard:status()
           -- and new_hcard:status().atr == hex.hexf("3BB794008131FE6553504B32339000D1")
           -- then
            -- print ("found at slot:", reader_name)
            -- card = StarCosSKP23Smartcard.new(new_hcard)
            -- break
        -- elseif new_hcard then
            -- print ("disconnecting from:", reader_name)
            -- new_hcard:disconnect()
        -- end
    -- end
    -- print ( util.repr(getmetatable(card)))
    -- local res
    -- if not card then
        -- print ("No readers or cards")
        -- return
    -- end
    -- card:begin_transaction()
    
    
    -- res = card:select_p15()
    -- card:select(hex.hexf("4601"), true)
    -- card:read_binary(0, 1)
    -- print ("SN:", card:read_serial_number())
    
    -- res = card:verify_pin_main("1111", false)
    -- print("verify_pin_main result check:", res)

    
    -- res = card:change_pin_main("1111", "1111")
    -- print("change_pin_main PIN result:", res)
    -- res = card:reset_pin_main("11111111", "1111")
    -- print("reset_pin_main result SM:", res)
    -- res = card:verify_pin_main("1111", false)
    -- print("verify_pin_main result check:", res)
    -- card:generate_key_pair("84", hex.hexf("4601"))
    
    -- local module, exponent = card:read_public_key("84")
    -- print ("module:", hex.hexify(module))
    -- print ("exponent:", hex.hexify(exponent))
    

    -- local toSign = "123"
    -- local signature = card:pso_rsa_internal_authenticate(toSign, "84")
    -- print("pso_rsa_internal_authenticate result:", hex.hexify(signature))
    
    -- local dec = rsa.decrypt(signature, hex.hexify(module), hex.hexify(exponent))
    -- print("dec signature:", hex.hexify(dec))
    -- assert (toSign == dec)
    
    
    -- local modulus = "c94d8e4413465dbc2bac312b9a4da891eb5063be6e739af584112a2748a62250e1eaa0346a9a2d991a1bc4664b0949480316e6decf37fb883b3f57fa4b294d5dd9438c93699d0f9b0bc67666b289c492be86335371bd27532dadf4e316d6f3cde40f5733f022ccfd7c9f3653b5edade4acb67f2f4e198891882d2b72239bce77"
    -- local pubExp = "010001"
    -- local privExp = "180b5f76da268983b463b8ebd05e7e480fa766829486d27788f2d3ea254f52c1fe7a1bf0a6db0b9f41f3171e70d00724c6d9b171e3a67830e982c36b6e16dcdaa67f05d56e1ac154fc7360346d525814b9f313d994ff64cc2303a97c1723edd2fa0902f489f79fc5c6c98bed52948f2ed350dad0c7a5a66b59db5884b04b9f81"

    -- card:import_private_key("84",
            -- hex.hexf("4601"),
            -- hexf(modulus), 
            -- hexf(pubExp), 
            -- hexf(privExp))
    
    -- local module, exponent = card:read_public_key("84")
    -- print ("module:", hex.hexify(module))
    -- print ("exponent:", hex.hexify(exponent))
    
    -- local toSign = "123"
    -- local signature = card:pso_rsa_internal_authenticate(toSign, "84")
    -- print("pso_rsa_internal_authenticate result:", hex.hexify(signature))
    
    -- local dec = rsa.decrypt(signature, hex.hexify(module), hex.hexify(exponent))
    -- print("dec signature:", hex.hexify(dec))
    -- assert (toSign == dec)
    
    
   
    -- local dec = rsa.decrypt(signature, hex.hexify(module), hex.hexify(exponent))
    -- print("dec signature:", hex.hexify(dec))

    -- local ACTUAL_DATA = hex.hexf("010f00000000")
    -- local encrypted_data = rsa.encrypt(ACTUAL_DATA, hex.hexify(module), hex.hexify(exponent))
    -- print("encrypted_data:", hex.hexify(encrypted_data))
    
    -- res = card:verify_pin_main("123456", false, false, false)
    -- print("verify_pin_main result:", res)
    
    -- local decrypted = card:pso_decrypt(encrypted_data, "84")
    -- print("decrypted:", hex.hexify(decrypted))
    -- card:end_transaction()
-- end
-- test_apdus()

return StarCosSKP23Smartcard

--===========================================================================
end
}
_LOADED['token-aet'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- token-aet.lua
local StarCosSKP23Smartcard = require 'StarCosSKP23Smartcard'
local hex = require 'hex'
local zlib = require "zlib"
local hexf = hex.hexf
local der = require 'der'
local p15 = require 'p15util'
local utility = require 'utility'
local repr = utility.repr

local MinKSize, MaxKSize = 1024, 1024
local t = {
    name = 'aet_starcos',
    mt = { },
    mechanisms = {
        [ CKM.RSA_PKCS_KEY_PAIR_GEN ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.GENERATE_KEY_PAIR},
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_X_509 ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.DECRYPT+CKF.SIGN},
    },
    aet_hcard = nil,
    capabilities = { private_attributes_readable=false, always_authenticate_on_cert=false, },
    StarCosSKP23Smartcard=StarCosSKP23Smartcard,
}
t.mt.__index = t.mt


function t.mt:initialize(cfg)
    log.output('token-aet:initialize():')
    local files = {}
    self.files = files
    files.OD = hexf("5031")
    files.OD_path = hexf("5031")
    files.CIA = hexf("5032")
    files.CIA_path = hexf("5032")
    files.US = hexf("5033")
    files.US_path = hexf("5033")

    files.PrivKD = hexf("4400")
    files.PrivKD_path = hexf("4400")
    files.PubKD = hexf("4401")
    files.PubKD_path = hexf("4401")
    files.CDF = hexf("4404")
    files.CDF_path = hexf("4404")
    files.DCODF_Pub = hexf("4407")
    files.DCODF_Pub_path = hexf("4407")
    files.AODF = hexf("4408")
    files.AODF_path = hexf("4408")
    files.PubValues = hexf("4300")
    files.PubValues_path = hexf("4300")
    files.PrivValues = hexf("4301")
    files.PrivValues_path = hexf("4301")

    files.IPF = hexf("4601")
    files.IPF_path = hexf("4601")
    
    self.capabilities = utility.clone_table(t.capabilities)
    self.aet_hcard = StarCosSKP23Smartcard.new(self.hcard)
    self.aet_hcard.BSO_PIN = hex.h2i('82')
    self.aet_hcard.BSO_PUK = hex.h2i('83')
    self.mechanisms = utility.clone_table(t.mechanisms)
    
    self.slow_card = false
    self.userPinInitialized = true
    
    self.request_plugin_valid = w32.request_plugin_valid()
    self.cfg = cfg or utility.parse_cfg()

    self.cfg["fcpr"] = self.cfg["fcpr"] or self.cfg["gcfcpr"]
    self.cfg["xproc"] = self.cfg["xproc"] or self.cfg["gcxproc"]
    
    
    if self.cfg["fcpr"] then
        self.cfg["fcpr"]=string.lower(self.cfg["fcpr"])
        self.use_cpr_mode = self.cfg["fcpr"] == "true"
        -- se non specificato non si attiva mai
    end
    
    if self.cfg["xproc"] then self.cfg["xproc"]=string.lower(self.cfg["xproc"])
    else self.cfg["xproc"]='true' end
    
    log.output('aet token initialize(): use_cpr_mode:', self.use_cpr_mode)
    
    self.check_box_visible = 0
    if self.cfg["hidecachedspincheck"] == 'true' then
        self.check_box_visible = nil
    end
    if self._cache_id == nil then
        self:flush_cache()
    end
end

function t.mt:begin_transaction()
    self.aet_hcard:begin_transaction()
end

function t.mt:end_transaction()
    self.aet_hcard:end_transaction()
end

function t.mt:_call_on_end_transaction()
    log.output('token-aet:_call_on_end_transaction()...')
    self.aet_hcard:on_end_transaction()
end



function t.mt:finalize()
    log.output("token-aet:finalize():", self.userType)
    utility.forget_token_changed(self, "cache")
end

function t.mt:add_info()
    log.output("add_info() reading SN")
    self.info.serialNumber = string.upper(self.aet_hcard:read_serial_number())
    log.output("add_info() reading indexes")
    self:_read_token_info_indexes()
    local infos, pcRes, theErrorT
    log.output("add_info() reading total space")
    pcRes, theErrorT = pcall(function()
        infos = self.aet_hcard:select(self.files.PubValues, true)
        self.info.ulTotalPublicMemory = infos.size
        log.output("add_info() total pub space:", self.info.ulTotalPublicMemory)
    end)
    if not pcRes then
        log.output("add_info() read total pub mem error:", theErrorT)
    end
    pcRes, theErrorT = pcall(function()
        infos = self.aet_hcard:select(self.files.PrivValues, true)
        self.info.ulTotalPrivateMemory = infos.size
        log.output("add_info() total priv space:", self.info.ulTotalPrivateMemory)
    end)
    if not pcRes then
        log.output("add_info() read total priv mem error:", theErrorT)
    end

    if self.userPinInitialized then
        self.info.flags = self.info.flags + CKF.USER_PIN_INITIALIZED
    else
        self.info.flags = self.info.flags - CKF.USER_PIN_INITIALIZED
    end
    
    self:_update_retry_counters()
end

function t.mt:_update_retry_counters()

    if (self.info) then
        pcall (function()
        
            self.info.flags = self.info.flags - CKF.USER_PIN_LOCKED
            self.info.flags = self.info.flags - CKF.USER_PIN_FINAL_TRY
            self.info.flags = self.info.flags - CKF.USER_PIN_COUNT_LOW
            self.info.flags = self.info.flags - CKF.SO_PIN_LOCKED
            self.info.flags = self.info.flags - CKF.SO_PIN_FINAL_TRY
            self.info.flags = self.info.flags - CKF.SO_PIN_COUNT_LOW
            
            local pinRetry, pinRetryMax, pukRetry, pukRetryMax = self.aet_hcard:get_pin_puk_status()
            log.output("get_pin_puk_status, PIN cur/max", pinRetry, pinRetryMax, "PUK cur/max:", pukRetry, pukRetryMax);
            if pinRetry == 0 then
                self.info.flags = self.info.flags + CKF.USER_PIN_LOCKED
            elseif pinRetry == 1 then
                self.info.flags = self.info.flags + CKF.USER_PIN_FINAL_TRY
            elseif pinRetry < pinRetryMax then
                self.info.flags = self.info.flags + CKF.USER_PIN_COUNT_LOW
            end
            
            if pukRetry == 0 then
                self.info.flags = self.info.flags + CKF.SO_PIN_LOCKED
            elseif pukRetry == 1 then
                self.info.flags = self.info.flags + CKF.SO_PIN_FINAL_TRY 
            elseif pukRetry < pukRetryMax then
                self.info.flags = self.info.flags + CKF.SO_PIN_COUNT_LOW
            end
            
            self.info.pinRetry    = pinRetry
            self.info.pinRetryMax = pinRetryMax
            self.info.pukRetry    = pukRetry
            self.info.pukRetryMax = pukRetryMax
        end)
    end
    
end

function t.mt:update_free_mem(info)

    self:_read_indexes()
    local fs = p15.parseUnusedSpace(self._indexes._unused_space_bin)
    local pub = p15.get_free_space(fs, self.files.PubValues_path)
    local priv = p15.get_free_space(fs, self.files.PrivValues_path)
    if priv then
        info.ulFreePrivateMemory = priv
    end
    if pub then
        info.ulFreePublicMemory = pub
    end
end

function t.mt:get_info()
    if not self.info then
        self.info = {
            label = 'Bit4id AET',
            manufacturerID = 'G&D',
            model = 'Starcos',
            serialNumber = '0000000000000000',
            flags = CKF.RNG + CKF.LOGIN_REQUIRED +
                    CKF.USER_PIN_INITIALIZED + CKF.TOKEN_INITIALIZED,
            ulMaxSessionCount = CK.EFFECTIVELY_INFINITE,
            ulSessionCount = 0,
            ulMaxRwSessionCount = CK.EFFECTIVELY_INFINITE,
            ulRwSessionCount = CK.UNAVAILABLE_INFORMATION,
            ulMaxPinLen = 8,
            ulMinPinLen = 4,
            ulTotalPublicMemory = 30000,
            ulFreePublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulTotalPrivateMemory = 768,
            ulFreePrivateMemory = CK.UNAVAILABLE_INFORMATION,
            hardwareVersion = { major=3, minor=0},
            firmwareVersion = { major=3, minor=0},
            utcTime = '0000000000000000'
        }
        
        self:add_info()
        self:update_free_mem(self.info)      
        if self.cfg["gdefaultlabel"] then
            self.info.label = self.cfg["gdefaultlabel"]
        end

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
    self._schedule_update_retry_counters = true
    
    result = self.aet_hcard:verify_pin_main(pin, ispuk, false) -- pin, ispuk, check
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
    log.output('token-aet change_pin(): oldPin:' .. oldPin, 'newPin:' .. newPin)

    self._schedule_update_retry_counters = true
    
    if newPin and (string.len(newPin) < info.ulMinPinLen or string.len(newPin) > info.ulMaxPinLen) then
        log.output('token-aet change_pin(): value not in range:', info.ulMinPinLen, info.ulMaxPinLen)
        return CKR.PIN_LEN_RANGE   
    end
    if ispuk and self.puk_not_modifiable then
        log.output('token-aet change_pin(): PUK not modifiable!')
        return CKR.PIN_LEN_RANGE
    end
    local rv
    log.output('token-aet change_pin(): cambio pin MAIN...')

    pcRes, result = pcall(function() 
            return self.aet_hcard:change_pin_main(oldPin, newPin, ispuk) -- oldPin, newPin, ispuk
        end)

    if result == 0 then
        -- la carta potrebbe dimenticare lo stato di logged in quando si effettua una change pin
        self.cached_main_pin = newPin
        pcRes, result = pcall(function()    
                return self.aet_hcard:verify_pin_main(newPin, ispuk, false)  -- pin, ispuk, check
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
    log.output('token-aet reset_pin(): newPin:', newPin)
    log.output('token-aet reset_pin(): reset pin MAIN...')
    if self.userType ~= CKU.SO then
        log.output('token-aet reset_pin(): user not SO!')
        return CKR.USER_TYPE_INVALID
    end
    
    local rv

    self._schedule_update_retry_counters = true
    
    if newPin and (string.len(newPin) < info.ulMinPinLen or string.len(newPin) > info.ulMaxPinLen) then
        log.output('token-aet reset_pin(): value not in range:', info.ulMinPinLen, info.ulMaxPinLen)
        return CKR.PIN_LEN_RANGE   
    end
    
    pcRes, result = pcall(function()
        return self.aet_hcard:reset_pin_main(self.cached_main_pin, newPin) -- Puk, newPin
        end)
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

    if dataLen > keyBytes or (dataLen > (keyBytes -4) and dataLen <  keyBytes) then
        -- nota: il padding pkcs1 richiede almeno 8 byte di oxFF prima dei dati da firmare
        log.output('sign_buffer(): specified data len invalid: ', dataLen)
        return CKR.DATA_LEN_RANGE
    end
    if allocated_space==nil then
        log.output('sign_buffer(): returning signature length:', keyBytes)
        return CKR.OK, keyBytes
    else
    
    local contextual_pin = nil
    local check_pin_status = 0
    log.output('sign_buffer(): using RSA-CDS mode on kid:', obj.kid)
        
    
    pcall(function()
        log.output('sign_buffer(): verify_pin_main() with:', self.cached_main_pin, self.userType)
        if self.cached_main_pin and self.userType == CKU.USER then
            self.aet_hcard:verify_pin_main(self.cached_main_pin, false, false, true) -- pin, ispuk, check, use_sm
        end
    end)
        
        pcRes, result = pcall(function()
                        return self.aet_hcard:pso_rsa_internal_authenticate(
                            pData,
                            obj.kid,
                            contextual_pin)
                        end )
        local last_sw = self.aet_hcard.last_sw
        local pin_incorrect = string.sub(last_sw, 1, 1) == hexf('63')
        local pin_locked = last_sw == hexf('6983')
        if pcRes then
            return CKR.OK, result
        elseif contextual_pin and (pin_incorrect or pin_locked ) then
            log.output('sign_buffer(): contextual PIN was incorrect or locked!')
            if pin_incorrect then return CKR.PIN_INCORRECT
            elseif pin_locked then return CKR.PIN_LOCKED
            else return CKR.FUNCTION_FAILED
            end
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

    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    if dataLen ~= keyBytes then
        log.output('decrypt_buffer(): specified data len invalid: ', dataLen, ', expected:', keyBytes)
        return CKR.ENCRYPTED_DATA_LEN_RANGE
    end
    
    pcall(function()
        log.output('decrypt_buffer(): verify_pin_main() with:', self.cached_main_pin, self.userType)
        if self.cached_main_pin and self.userType == CKU.USER then
            self.aet_hcard:verify_pin_main(self.cached_main_pin, false, false, true) -- pin, ispuk, check, use_sm
        end
    end)
    local pDataPadded
    pDataDecrypted = self.aet_hcard:pso_decrypt(pData, obj.kid) -- data, id
    
    return CKR.OK, pDataDecrypted
end


-- se search_state.lastobj==nil si richiede l'handle del primo oggetto che risponda
-- al template. Altrimenti restituisce il primo oggetto che sia
-- compatibile con il template e abbia handle>search_state.lastobj.
-- quando non ci sono pi