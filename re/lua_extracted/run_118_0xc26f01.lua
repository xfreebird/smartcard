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

function t.mt:add_cmd_objects(objects)
    local obj
    log.output('token-cmd:add_cmd_objects(): adding CMD objects...')
    if self.cmd_info then
    
        if not self.dsmode or self.dsmode == "dsonly" then
            if self.cmd_info.cert_valid then
                log.output('token-cmd:add_cmd_objects(): adding CMD Sign Certificate...')
                obj = objCnsTmpl.GetCNSCertTemplate(t.mt.get_certificate)
                obj.iscmd=true
                obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(true) 
                obj[CKA.ID] = OBJ_IDS.DS0_ID
                obj[CKA.LABEL] = OBJ_IDS.DS0_LABEL
                obj.path = self.cmd_info.ds_sig_path .. "C000"
                objects.max_index = objects.max_index+1
                objects[ objects.max_index ] = obj
                log.output('token-cmd:add_cmd_objects(): added certificate:',
                    objects.max_index,
                    hex.hexify(obj[CKA.CLASS]))
                self.cmd_info.cert_handle = objects.max_index
            end
            -- if self.cmd_info.ca_cert_valid then
                -- log.output('token-cmd:add_cmd_objects(): adding CMD CA Certificate...')
                -- obj = objCnsTmpl.GetCNSCertTemplate(t.mt.get_certificate)
                -- obj.iscmd=true
                -- obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(true) 
                -- obj[CKA.ID] = OBJ_IDS.CA_ID
                -- obj[CKA.LABEL] = OBJ_IDS.CA_ID
                -- obj.path = self.cmd_info.ds_sig_path .. "C00E"
                -- objects.max_index = objects.max_index+1
                -- objects[ objects.max_index ] = obj
                -- log.output('token-cmd:add_cmd_objects(): added CA certificate:',
                    -- objects.max_index,
                    -- hex.hexify(obj[CKA.CLASS]))
                -- self.cmd_info.cert_handle = objects.max_index
            -- end
            if self.cmd_info.key_valid then
                log.output('token-cmd:add_cmd_objects(): adding CMD Sign Pub and Priv keys...')
                
                objects.max_index = objects.max_index+1
                local objPub = objCnsTmpl.GetCNSPubKeyTemplate(t.mt.get_public_key)
                objPub.iscmd = true
                objPub.path = self.cmd_info.ds_sig_path .. "C100"
                objPub.key_bits = 1024
                objPub[CKA.ID] = OBJ_IDS.DS0_ID
                objPub[CKA.LABEL] = OBJ_IDS.DS0_LABEL
                objects[ objects.max_index ] = objPub
                log.output('token-cmd:add_cmd_objects(): added pub key:',
                    objects.max_index,
                    hex.hexify(objPub[CKA.CLASS]))
                self.cmd_info.pub_key_handle = objects.max_index
                
                objects.max_index = objects.max_index+1
                local objPriv = objCnsTmpl.GetCNSPrivKeyTemplate(t.mt.get_public_key)
                objPriv.iscmd = true
                objPriv.related_public_key = objPub.path
                objPriv.path = self.cmd_info.ds_sig_path
                objPriv.kid = 2
                objPriv[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(true)
                objPriv.pso_dec = false
                objPriv.private=true
                objPriv.key_bits = 1024
                objPriv[CKA.ID] = OBJ_IDS.DS0_ID
                objPriv[CKA.LABEL] = OBJ_IDS.DS0_LABEL
                objPriv[CKA.PRIVATE] = eCK.BBOOL(objPriv.private)
                objPriv[CKA.DECRYPT] = eCK.BBOOL(false)
                objPriv[CKA.SIGN] = eCK.BBOOL(true)
                objects[ objects.max_index ] = objPriv
                log.output('token-cmd:add_cmd_objects(): added priv key:',
                    objects.max_index,
                    hex.hexify(objPriv[CKA.CLASS]))
                self.cmd_info.priv_key_handle = objects.max_index
            end
            
        end
    
        if not self.dsmode or self.dsmode ~= "dsonly" then
            if self.cmd_info.crypt_cert_valid then
                log.output('token-cmd:add_cmd_objects(): adding CMD Crypt Certificate...')
                obj = objCnsTmpl.GetCNSCertTemplate(t.mt.get_certificate)
                obj.iscmd=true
                obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(true)
                obj[CKA.ID] = OBJ_IDS.CMD1_ID
                obj[CKA.LABEL] = OBJ_IDS.CMD1_LABEL
                obj.path = self.cmd_info.p11_path_certs .. "0000"
                objects.max_index = objects.max_index+1
                objects[ objects.max_index ] = obj
                log.output('token-cmd:add_cmd_objects(): added certificate:',
                    objects.max_index,
                    hex.hexify(obj[CKA.CLASS]))
                
                objects.max_index = objects.max_index+1
                local objPub = objCnsTmpl.GetCNSPubKeyTemplate(t.mt.get_public_key)
                objPub.iscmd = true
                objPub.path = self.cmd_info.p11_path_keys .. "0001"
                objPub.key_bits = 1024
                objPub[CKA.ID] = OBJ_IDS.CMD1_ID
                objPub[CKA.LABEL] = OBJ_IDS.CMD1_LABEL
                objects[ objects.max_index ] = objPub
                log.output('token-cmd:add_cmd_objects(): added pub key:',
                    objects.max_index,
                    hex.hexify(objPub[CKA.CLASS]))
                self.cmd_info.pub_key_handle = objects.max_index
                
                objects.max_index = objects.max_index+1
                local objPriv = objCnsTmpl.GetCNSPrivKeyTemplate(t.mt.get_public_key)
                objPriv.iscmd = true
                objPriv.related_public_key = objPub.path
                objPriv.path = self.cmd_info.p11_path_keys
                objPriv.kid = 1
                objPriv[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(true)
                objPriv.pso_dec = true
                objPriv.private=true
                objPriv.key_bits = 1024
                objPriv[CKA.ID] = OBJ_IDS.CMD1_ID
                objPriv[CKA.LABEL] = OBJ_IDS.CMD1_LABEL
                objPriv[CKA.PRIVATE] = eCK.BBOOL(objPriv.private)
                objPriv[CKA.DECRYPT] = eCK.BBOOL(true)
                objPriv[CKA.SIGN] = eCK.BBOOL(false)
                objects[ objects.max_index ] = objPriv
                log.output('token-cmd:add_cmd_objects(): added priv key:',
                    objects.max_index,
                    hex.hexify(objPriv[CKA.CLASS]))
                self.cmd_info.priv_key_handle = objects.max_index
                
            end
        end
    end
end


function t.mt:add_cns_objects(objects)
    local obj
    log.output('token-cmd:add_cns_objects(): adding CNS-Like objects...')
    
    if not self.dsmode or self.dsmode ~= "dsonly" then
        if self.cns_info then
            if self.cns_info.cert_valid then
                log.output('token-cmd:add_cns_objects(): adding CNS-Like Certificate...')
                obj = objCnsTmpl.GetCNSCertTemplate(t.mt.get_certificate)
                obj.iscns=true
                obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
                obj[CKA.ID] = OBJ_IDS.CMD0_ID
                obj[CKA.LABEL] = OBJ_IDS.CMD0_LABEL
                objects.max_index = objects.max_index+1
                objects[ objects.max_index ] = obj
                log.output('token-cmd:add_cns_objects(): added certificate:',
                    objects.max_index,
                    hex.hexify(obj[CKA.CLASS]))
                self.cns_info.cert_handle = objects.max_index
            end
            if self.cns_info.key_valid then
                log.output('token-cmd:add_cns_objects(): adding CNS-Like Pub and Priv keys...')
                
                objects.max_index = objects.max_index+1
                local objPub = objCnsTmpl.GetCNSPubKeyTemplate(t.mt.get_public_key)
                objPub.iscns = true
                objPub.key_bits = 1024
                objPub[CKA.ID] = OBJ_IDS.CMD0_ID
                objPub[CKA.LABEL] = OBJ_IDS.CMD0_LABEL
                objects[ objects.max_index ] = objPub
                log.output('token-cmd:add_cns_objects(): added pub key:',
                    objects.max_index,
                    hex.hexify(objPub[CKA.CLASS]))
                self.cns_info.pub_key_handle = objects.max_index
                
                objects.max_index = objects.max_index+1
                local objPriv = objCnsTmpl.GetCNSPrivKeyTemplate(t.mt.get_public_key)
                objPriv.iscns = true
                objPriv.pso_dec = true
                objPriv[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
                objPriv.kid = tonumber("31", 16)
                objPriv.related_public_key = objPub.path
                objPriv.private=true
                objPriv.key_bits = 1024
                objPriv[CKA.PRIVATE] = eCK.BBOOL(objPriv.private)
                objPriv[CKA.ID] = OBJ_IDS.CMD0_ID
                objPriv[CKA.LABEL] = OBJ_IDS.CMD0_LABEL
                objPriv[CKA.DECRYPT] = eCK.BBOOL(true)
                objPriv[CKA.SIGN] = eCK.BBOOL(true)
                objects[ objects.max_index ] = objPriv
                log.output('token-cmd:add_cns_objects(): added priv key:',
                    objects.max_index,
                    hex.hexify(objPriv[CKA.CLASS]))
                self.cns_info.priv_key_handle = objects.max_index
            end
        end
    end
end

function t.mt:get_objects()

    log.output('token-cmd:get_objects()')
    local info = self:get_info() -- carica le info sul filesystem in cache
    
    local objects = {
            min_index = 11001, -- primo indice disponibile
            max_index = 11000, -- valore dell'indice massimo (i valori intermedi possono anche essere nil)
        }
    
    self:add_cns_objects(objects)
    self:add_cmd_objects(objects)
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
    return self.cmd_hcard:valid()
end


function t.mt:get_object_size(hobj)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj == nil then return CKR.OBJECT_HANDLE_INVALID end
    local oSize = -1
    
        if obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
            oSize = 400
        elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
            oSize = 130*2
        elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
            oSize = 300
        elseif obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
            oSize = 2048
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
        log.output("token-cmd:flush_cache(): initializing _cache_id")
        changed, self._cache_id = utility.has_token_changed(self, "cache", 0)
        log.output("token-cmd:flush_cache(): initialize: _cache_id:", self._cache_id)
    end
    changed, cache_id = utility.has_token_changed(self, "cache", self._cache_id)
    if changed then
        log.output("token-cmd:flush_cache(): token has changed!")
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
_LOADED['token-it-telecom'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- token-it-telecom.lua
local hex = require 'hex'
local hexf = hex.hexf
local hexify = hex.hexify
local der = require 'der'
local utility = require 'utility'
local rsa = require 'rsa'
local zlib = require 'zlib'

local objCnsTmpl = require 'token-cns-objects'

local ITTelecomSmartcardError = { mt = {}, }
ITTelecomSmartcardError.mt.__index = ITTelecomSmartcardError.mt

function ITTelecomSmartcardError.mt.__tostring(e)
    return "ITTelecomSmartcardError: " .. (e.msg or '') .. ' ;SW=' .. hex.hexify(e.sw or '') 
end

function ITTelecomSmartcardError.new(sw, msg)
    local e = msg .. ' ;sw=' .. hexify(sw or '')
    return e
end

-- function t.runpad(value, char)
    -- while string.sub(value, -1, -1) == char do
        -- value = string.sub(value, 1, -2)
    -- end
    -- return value
-- end

local function lunpad(value, char)
    while string.sub(value, 1, 1) == char do
        value = string.sub(value, 2, -1)
    end
    return value
end


local ITTelecomSmartcard = {}
ITTelecomSmartcard.MAX_TRANSMIT_BUFFER_SIZE = 128
ITTelecomSmartcard.mt = {}
ITTelecomSmartcard.mt.__index = ITTelecomSmartcard.mt

function ITTelecomSmartcard.new(card)
    local self = {
                    PIN_PADDING=8,
                    PUK_PADDING=8,
                    BSO_MAIN_PIN=1,
                    BSO_MAIN_PUK=2,
                    PIN_MAX_RETRY_COUNTER=3,
                    _pin_status = bin.flags(0),
                  }
    self.card = card
    setmetatable(self, ITTelecomSmartcard.mt)
    return self
end

function ITTelecomSmartcard.mt:transmit(apdu)
    if self.on_transmit then
        self:on_transmit(apdu)
    end
    local sw
    local result, scarderr
    
    while true do
        result, scarderr = self.card:transmit(apdu)
        if not result then
            error(ITTelecomSmartcardError.new('', string.format('transmit error: 0x%x', scarderr) ))
        end
        
        sw = string.sub(result, -2, -1)
        if sw == hex.hexf("9201") then
            log.output('ITTelecomSmartcard.mt:transmit(): async APDU started...')
        elseif sw == hex.hexf("9202") then
            log.output('ITTelecomSmartcard.mt:transmit(): async APDU continuing...')
        elseif sw == hex.hexf("9810") then
            log.output('ITTelecomSmartcard.mt:transmit(): async APDU ERROR!')
            break
        else
            break
        end
        w32.sleep(10 * 1000)
        log.output('ITTelecomSmartcard.mt:transmit(): async APDU: retransmit...')
    end
    
    self.last_sw = sw
    return result
end


function ITTelecomSmartcard.mt:delete_key_pair(kid)
    local recv
    log.output('delete_key_pair():', kid)

    recv = self:transmit(hexf('008004%B01', kid))
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(ITTelecomSmartcardError.new(sw, 'set delete_key_pair kid Error'), 2)
    end
    recv = self:transmit(hexf('0030000000'))
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(ITTelecomSmartcardError.new(sw, 'delete_key_pair Error'), 2)
    end
end

function ITTelecomSmartcard.mt:get_free_kid()
    local recv
    log.output('get_free_kid():')

    recv = self:transmit(hexf('0080010001'))
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(ITTelecomSmartcardError.new(sw, 'get_free_kid Error'), 2)
    end
    return string.byte(recv, 1)
end


function ITTelecomSmartcard.mt:generate_key_pair(key_bits)
    local recv
    log.output('ITTelecomSmartcard:generate_key_pair():')

    if key_bits == 1024 then
        recv = self:transmit(hexf('0046000200'))
    else
        recv = self:transmit(hexf('0046000400'))
    end
    
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(ITTelecomSmartcardError.new(sw, 'generate_key_pair Error'), 2)
    end
    return string.byte(recv, 1)
end

function ITTelecomSmartcard.mt:read_public_key(kid)
    local value
    log.output('ITTelecomSmartcard:read_public_key():', kid)

    self:select(hexf("1f12"))
    local value = self:mread_binary(512 * (kid-1), 512)

    local modulus = string.sub(value, 1, 256)
    local pubexp  = string.sub(value, 257, -1)
    
    -- log.output('ITTelecomSmartcard:read_public_key(): modulus a ', hex.hexify(modulus))
    -- log.output('ITTelecomSmartcard:read_public_key(): pubexp a ', hex.hexify(pubexp))
    
    if string.sub(modulus, 129, -1) == string.rep("\255", 128) then
        modulus = string.sub(modulus, 1, 128)
        pubexp = string.sub(pubexp, 1, 128)
    end
    -- log.output('ITTelecomSmartcard:read_public_key(): modulus b ', hex.hexify(modulus))
    -- log.output('ITTelecomSmartcard:read_public_key(): pubexp b ', hex.hexify(pubexp))
    modulus = lunpad(modulus, '\0')
    pubexp = lunpad(pubexp, '\0')
    log.output('ITTelecomSmartcard:read_public_key(): modulus c ', hex.hexify(modulus))
    log.output('ITTelecomSmartcard:read_public_key(): pubexp c ', hex.hexify(pubexp))
    return modulus, pubexp
end




function ITTelecomSmartcard.mt:select_aid(force)
    log.output('ITTelecomSmartcard:select_aid():')
    local AID = {
                "F000005449FFF0FF3959480400202501",
                "F006C000240100000100005959440101",
                "F000005449FFF0FF3959480500202601",
                "F000005449FFF0FF3959480600202701",
                "F000005449FFF0FF3959480700202801",
                "F000005449FFF0FF3959480800202901",
                }
    local apdu2 = hex.hexf("00A40000027f30")
    local apdu3 = hex.hexf("00A40000025FFF")
    
    local f1 = function ()
        local sw
        for aid=1,table.getn(AID) do
            log.output('ITTelecomSmartcard:select_aid(): aid:', AID[aid])
            local apdu1 = hex.hexf("00A40400%P", hex.hexf(AID[aid]))
            local recv = self:transmit(apdu1)
            sw = string.sub(recv, -2, -1)
            if sw == hexf('9000') then
                recv = self:transmit(apdu2)
                sw = string.sub(recv, -2, -1)
                break
            end
        end
        return sw
    end
    local f2 = function()
        local recv = self:transmit(apdu3)
        local sw = string.sub(recv, -2, -1)
        return sw
    end
    local sw
    if not force then
        sw = f2()
    end
    if sw ~= hexf('9000') then
        sw = f1()
        if sw ~= hexf('9000') then
            error(ITTelecomSmartcardError.new(sw, 'select AID/7f30 Error'), 2)
        end
        sw = f2()
        if sw ~= hexf('9000') then
            error(ITTelecomSmartcardError.new(sw, 'select 5FFF Error'), 2)
        end
    end
end


function ITTelecomSmartcard.mt:select(fid)
    local recv
    local template_h = '00A4000002%H'
    log.output('select(): ', fid and hexify(fid))
    local fid1 = fid
    if fid1 == nil then
        fid1 = tonumber('3f00', 16)
    end

    if type(fid1)~='number' then
        fid1 = tonumber(hex.hexify(fid1 or ''), 16)
    end
    recv = self:transmit(hexf(template_h, fid1))
    local sw1 = string.sub(recv, -2, -2)
    if sw1 ~= hexf('90') then
        error(ITTelecomSmartcardError.new(sw, 'select Error'), 2)
    end
end

function ITTelecomSmartcard.mt:read_binary(offset, size)
    local recv
    recv = self:transmit(hexf('00B0%H%B', offset, size))
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') and sw ~= hexf('6282') then
        error(ITTelecomSmartcardError.new(sw, 'read_binary Error'), 2)
    end
    return string.sub(recv, 1, -3)
end


function ITTelecomSmartcard.mt:mread_binary(offset, size, sm_enc, sm_sig, sig_enc_input)
    local buffer_size = ITTelecomSmartcard.MAX_TRANSMIT_BUFFER_SIZE
    local content = ''
    while size>0 do
        if size<buffer_size then buffer_size = size end
        local recv = self:read_binary(offset, buffer_size, sm_enc, sm_sig, sig_enc_input)
        offset = offset  + buffer_size
        size = size - buffer_size
        content = content .. recv
    end
    return content
end


function ITTelecomSmartcard.mt:read_record(rec, mode, size)
    local read_mode = mode or 4
    local expected_size = size or 0
    -- log.output('read_record(): reading rec:', rec, 'mode:', read_mode, 'size:', expected_size)
    local apdu = hexf('00B2%B%B%B', rec, read_mode, expected_size)
    local recv
    recv = self:transmit(apdu)
    
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') and sw ~= hexf('6282') then
        log.output('read_record(): error:', hexify(sw))
        error(ITTelecomSmartcardError.new(sw, 'read_record Error'), 2)
    end
    return string.sub(recv, 1, -3)
end




function ITTelecomSmartcard.mt:update_binary(offset, data)
    local apdu = hex.hexf('00D6%H%P', offset, data)
    local recv, sw
    --print (hex.hexify(apdu))
    recv =  self:transmit(apdu)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(ITTelecomSmartcardError.new(sw, 'update_binary Error'), 2)
    end
end


function ITTelecomSmartcard.mt:mupdate_binary(offset, data)
    local buffer_size = ITTelecomSmartcard.MAX_TRANSMIT_BUFFER_SIZE
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

function ITTelecomSmartcard.mt:verify(bso, pin, backtracking)
    if bso<0 or bso>127 then
        error(ITTelecomSmartcardError.new(nil, 'ITTelecomSmartcard verify Error: bad BSO number' ), 2)
    end
    if string.len(pin) == 0 then
        log.output('verify(): checking pin status...')
    end
    if backtracking then
        bso = (bin.flags(bso) + bin.flags(128)).asnumber
    end
    
    local sw;
    local f1 = function()
        sw = self:transmit(hexf('002100%B%P', bso, pin))
    end
    f1()
    if sw == hexf("6a86") or sw == hexf("6d00") or sw == hexf("6e00") then
        self:select_aid()
        f1()
    end
    if sw == hexf('6f06') then
        return 3, 'pin invalid'
    elseif sw == hexf('6983') then
        self:_update_retry_counter_info(bso, 0)
        return 2, 'Authentication blocked'
    elseif bin.mask_compare(sw, hexf('6300'), hexf('FF00')) then
        if bin.mask_compare(sw, hexf('63C0'), hexf('FFF0')) then
            local retryCounter = string.byte(sw, 2) - 192
            self:_update_retry_counter_info(bso, retryCounter)
        end
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        self:_update_retry_counter_info(bso, 3)
        return 0, 'Authentication succeeded'

    else
        log.output('verify(): Error ' .. hexify(sw) )
        error(ITTelecomSmartcardError.new(sw, 'verify Error' ), 2)
    end
end


function ITTelecomSmartcard.mt:change_pin(bso, oldPin, newPin, backtracking)
    log.output('change_pin():',  bso, oldPin, newPin, backtracking)
    if bso<0 or bso>127 then
        error(ITTelecomSmartcardError.new(nil, 'ITTelecomSmartcard change_pin Error: bad BSO number' ), 2)
    end
    if backtracking then
        bso = (bin.flags(bso) + bin.flags(128)).asnumber
    end
	local mode = 0
	if not oldPin then
		mode = 1
		oldPin = ''
	end
    local sw = self:transmit(hexf('0024%B%B%P', mode, bso, oldPin .. newPin))
    local sw_n = tonumber(hex.hexify(sw), 16)
    if sw == hexf('6f06') then
        return 3, 'pin invalid'
    elseif sw == hexf('6983') then
        self:_update_retry_counter_info(bso, 0)
        return 2, 'Authentication blocked'
    elseif bin.mask_compare(sw, hexf('6300'), hexf('FF00')) then
        if bin.mask_compare(sw, hexf('63C0'), hexf('FFF0')) then
            local retryCounter = string.byte(sw, 2) - 192
            self:_update_retry_counter_info(bso, retryCounter)
        end
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        self:_update_retry_counter_info(bso, 3)
        return 0, 'Authentication succeeded'

    else
        log.output('change_pin(): Error ' .. hexify(sw) )
        error(ITTelecomSmartcardError.new(sw, 'change_pin Error' ), 2)
    end
end

function ITTelecomSmartcard.mt:_update_retry_counter_info(bso, retryCounter)
    log.output('_update_retry_counter_info(): : ',bso, retryCounter)
    bso = (bin.flags(bso) - bin.flags(128)).asnumber
    log.output('_update_retry_counter_info(): : ',bso, retryCounter)
    if bso ~= self.BSO_MAIN_PIN then
        log.output('_update_retry_counter_info(): not PIN')
        return
    end
    log.output('_update_retry_counter_info(): clearing pin state')
    self._pin_status = self._pin_status - CKF.USER_PIN_LOCKED
    self._pin_status = self._pin_status - CKF.USER_PIN_FINAL_TRY
    self._pin_status = self._pin_status - CKF.USER_PIN_COUNT_LOW

    if retryCounter == 0 then
        self._pin_status = self._pin_status + CKF.USER_PIN_LOCKED
        log.output('_update_retry_counter_info(): USER_PIN_LOCKED')
    elseif retryCounter == 1 then
        self._pin_status = self._pin_status + CKF.USER_PIN_FINAL_TRY
        log.output('_update_retry_counter_info(): USER_PIN_FINAL_TRY')
    elseif retryCounter < self.PIN_MAX_RETRY_COUNTER then
        self._pin_status = self._pin_status + CKF.USER_PIN_COUNT_LOW
        log.output('_update_retry_counter_info(): USER_PIN_COUNT_LOW')
    end
end
function ITTelecomSmartcard.mt:reset_retry_counter(bso, Puk, newPin, backtracking)
    if bso<0 or bso>127 then
        error(ITTelecomSmartcardError.new(nil, 'ITTelecomSmartcard sm_reset_retry_counter Error: bad BSO number' ), 2)
    end
    if backtracking then
        bso = (bin.flags(bso) + bin.flags(128)).asnumber
    end
    local mode = 0
    if not Puk and not newPin then
        mode = 3
    elseif not newPin then
        mode = 1
    end
    local sw = self:transmit(hexf('002C%B%B%P', mode, bso, (Puk or '') .. (newPin or '')))
    if sw == hexf('6f06') then
        return 3, 'pin invalid'
    elseif sw == hexf('6983') then
        self:_update_retry_counter_info(bso, 0)
        return 2, 'Authentication blocked'
    elseif bin.mask_compare(sw, hexf('6300'), hexf('FF00')) then
        if bin.mask_compare(sw, hexf('63C0'), hexf('FFF0')) then
            local retryCounter = string.byte(sw, 2) - 192
            self:_update_retry_counter_info(bso, retryCounter)
        end
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        self:_update_retry_counter_info(bso, 3)
        return 0, 'Authentication succeeded'
    else
        log.output('sm_reset_retry_counter(): Error ' .. hexify(sw) )
        error(ITTelecomSmartcardError.new(sw, 'sm_reset_retry_counter Error' ), 2)
    end
end


function ITTelecomSmartcard.mt:verify_pin_main(pin, ispuk, check)
    log.output('verify_pin_main():', pin, ispuk, check)
    local bso = self.BSO_MAIN_PIN
    local padding = self.PIN_PADDING
    if ispuk then
        log.output('verify_pin_main(): ignoring PUK verification')
        -- bso = self.BSO_MAIN_PUK
        -- padding = self.PUK_PADDING
        return 0, 'Authentication succeeded'
    end
    if string.len(pin)> padding then
        pin = string.sub(pin, 1, padding)
    end
    pin = pin .. string.rep("\255", padding - string.len(pin))
    return self:verify(bso, pin, false)
end


function ITTelecomSmartcard.mt:change_pin_main(oldPin, newPin, ispuk)
    log.output('change_pin_main(): old pin', oldPin, "new pin:", newPin, "ispuk:",  ispuk)
    local bso = self.BSO_MAIN_PIN
    local padding = self.PIN_PADDING
    if ispuk then
        bso = self.BSO_MAIN_PUK
        padding = self.PUK_PADDING
    end
    if string.len(oldPin)> padding then
        oldPin = string.sub(oldPin, 1, padding)
    end
    oldPin = oldPin .. string.rep("\255", padding - string.len(oldPin))
    if string.len(newPin)> padding then
        newPin = string.sub(newPin, 1, padding)
    end
    newPin = newPin .. string.rep("\255", padding - string.len(newPin))
    return self:change_pin(bso, oldPin, newPin, false)
end


function ITTelecomSmartcard.mt:reset_pin_main(Puk, newPin)
    if string.len(Puk or '' ) > self.PUK_PADDING then
        Puk = string.sub(Puk, 1, self.PUK_PADDING)
    end
    if string.len(newPin) > self.PIN_PADDING then
        error('ITTelecomSmartcard reset_pin_cns Error: wrong PIN size', 2)
    end
    Puk = Puk .. string.rep("\255", self.PUK_PADDING - string.len(Puk))
    newPin = newPin .. string.rep("\255", self.PIN_PADDING - string.len(newPin))
    -- local res
    -- res = self:verify_pin_main(Puk, true, false)
    -- if res ~= 0 then return res end
    return self:reset_retry_counter(self.BSO_MAIN_PIN, Puk, newPin, false)
end


function ITTelecomSmartcard.mt:begin_transaction()
    self.card:begintransaction()
    log.output("self.on_begin_transaction", self.on_begin_transaction)
    if self.on_begin_transaction then
        self:on_begin_transaction()
    end
end

function ITTelecomSmartcard.mt:end_transaction()
    if self.on_end_transaction then
        self:on_end_transaction()
    end
    self.card:endtransaction()
end


function ITTelecomSmartcard.mt:valid()
    local status, err = self.card:status()
    if not status then
        log.output('ITTelecomSmartcard:valid(): status() error', hex.tohex8(err or 0))
        return false
    elseif status.protocol == 0 or string.len(status.atr or '') == 0 then
        log.output('ITTelecomSmartcard:valid(): card removed?')
        return false
    end
    return true
end


function ITTelecomSmartcard.handle_error(err_obj)
    print(debug.traceback(err_obj))
    return err_obj
end



-- data: binary string, id: hex ascii strings
function ITTelecomSmartcard.mt:rsa_it_telecom(data, id)
    local sw
    if id == nil then id = '01'
    elseif type(id) == 'number' then 
        -- ok
    elseif string.len(id) == 1 then 
        id = string.byte(id, 1)
    end
    -- MANAGE SECURITY ENVIRONMENT SET
    sw = self:transmit(hexf('008003%B01', id))
    sw = string.sub(sw, -2, -1)
    if sw ~= hexf('9000') then
        error(ITTelecomSmartcardError.new(sw, 'MSE set Error' ), 2)
    end
    local recv
    if string.len(data) > 128 then
        recv = self:transmit(hexf('003A0001%P', string.sub(data, 1, 128)))
        sw = string.sub(recv, -2, -1)
        if sw == hexf("9000") then
            recv = self:transmit(hexf('003A0002%P', string.sub(data, 129, -1) ) )
            sw = string.sub(recv, -2, -1)
            if sw == hexf("9000") then
                recv = self:transmit(hexf('0028000200') )
            end
        end
    else
        recv = self:transmit(hexf('003A0000%P', data))
        sw = string.sub(recv, -2, -1)
        if sw == hexf("9000") then
            recv = self:transmit(hexf('0028000280') )
            sw = string.sub(recv, -2, -1)
        end
    end
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(ITTelecomSmartcardError.new(sw, 'rsa_it_telecom error' ), 2)
    end
    return string.sub(recv, 1, -3)
end



local MinKSize, MaxKSize = 1024, 2048

local t = {
    name = 'it_telecom',
    mt = { },
    mechanisms = {
        [ CKM.RSA_PKCS_KEY_PAIR_GEN ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.GENERATE_KEY_PAIR},
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_X_509 ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
    },
    it_telecom_hcard = nil,
    capabilities = { private_attributes_readable=true, always_authenticate_on_cert=true, },
    ITTelecomSmartcard=ITTelecomSmartcard,
    
}
t.mt.__index = t.mt


function t.mt:initialize(cfg)
    self.capabilities = utility.clone_table(t.capabilities)
    self.it_telecom_hcard = ITTelecomSmartcard.new(self.hcard)
    self.it_telecom_hcard._mse_seid = "30"
   
    self.cfg = cfg or utility.parse_cfg()
    
    self.cfg["xproc"] = self.cfg["xproc"] or self.cfg["exproc"]
    if self.cfg["xproc"] then self.cfg["xproc"]=string.lower(self.cfg["xproc"])
    else self.cfg["xproc"]='true' end

    self.default_container_data_obj = "CSPSmartLogon"
    self.mechanisms = utility.clone_table(t.mechanisms)

    if not self.create_object then
        self.cfg["fastread"] = 'true'
    end
    if self._cache_id == nil then
        self:flush_cache()
    end
end

function t.mt:finalize()
    log.output("token-it-telecom:finalize():", self.session, self.userType)
end
    

function t.mt:begin_transaction()
    self.it_telecom_hcard:begin_transaction()
end

function t.mt:end_transaction()
    self.it_telecom_hcard:end_transaction()
end


function t.mt:add_info_it_telecom_certs(cert_index_str, cert_data_str)
    log.output(string.format("add_info_it_telecom_certs():"))
    local sha = md.sha1()

    local fspace = bin.unpack("%>%H", cert_index_str)
    log.output(string.format("add_info_it_telecom_certs(): fspace: %d", fspace))
    self.it_telecom_info.certificates = {}
    if fspace == 65535 then
        fspace = 0
        log.output(string.format("add_info_it_telecom_certs(): blank card!"))
    end
    for i=2,fspace-4,2 do
        local start =bin.unpack("%>%H", string.sub(cert_index_str, i+1, i+2))
        local start1 = bin.unpack("%>%H", string.sub(cert_index_str, i+3, i+4))
        local len = start1 - (start)
        log.output(string.format("add_info_it_telecom_certs(): start: %d, start next: %d, len: %d", start, start1, len))
        
        local cert = {start=start, len=len}
        
        if cert_data_str then
            local start_rel = cert.start+1  - string.len(cert_index_str)
            log.output(string.format("add_info_it_telecom_certs(): start_rel: %d", start_rel))
            cert.val_compressed = string.sub(cert_data_str, start_rel, start_rel + cert.len-1)
        else
        
        
            local cert_id = self.it_telecom_hcard:mread_binary(cert.start+cert.len-16, 16)
            local cert_dummy_path = hex.hexify(cert_id)
            log.output("fastreadcache=", self.cfg["fastreadcache"], "fastread=", self.cfg["fastread"])
            if self.info.serialNumber and utility.cache_can_use() and self.cfg["fastread"]=='true' then
                local val_s = utility.cache_read(self.info.serialNumber, cert_dummy_path, nil, self.cfg["fastreadcache"])
                if val_s then
                    if string.len(val_s or '') == 0 then val_s = nil end
                    cert.val_compressed = val_s
                    log.output("add_info_it_telecom_certs(): using cached value!")
                end
            end
            if not cert.val_compressed then
                log.output("add_info_it_telecom_certs(): reading from card...")
                cert.val_compressed = self.it_telecom_hcard:mread_binary(cert.start, cert.len)
                if self.info.serialNumber and utility.cache_can_use() and self.cfg["fastread"]=='true' then
                    log.output("add_info_it_telecom_certs(): caching value:", hex.hexify(cert_dummy_path), hex.hexify(cert.val_compressed))
                    utility.cache_write(self.info.serialNumber, cert_dummy_path, cert.val_compressed, self.cfg["fastreadcache"])
                end
            end
        end
        log.output("add_info_it_telecom_certs(): cert.val_compressed", hex.hexify(cert.val_compressed))
        cert.val = zlib.decompress(cert.val_compressed)
        sha:update(cert.val_compressed)
        if not cert.val then
            cert.val = zlib.decompresscer(cert.val_compressed)
        end
        if not cert.val then
            log.output(string.format("add_info_it_telecom_certs(): certificate starting @ %d invalid", start))
        else
            log.output("add_info_it_telecom_certs(): cert.val", hex.hexify(cert.val))
        end
        
        
        table.insert(self.it_telecom_info.certificates, cert)
    end
    if self.cfg["fastread"]=='true' then
        log.output("add_info_it_telecom_certs(): read only token detected")
        if table.getn(self.it_telecom_info.certificates) == 0 then
        log.output("add_info_it_telecom_certs(): empty token: setting uninitialized")
            self.info.flags = self.info.flags - CKF.TOKEN_INITIALIZED
        else
            self.info.flags = self.info.flags + CKF.TOKEN_INITIALIZED
        end
    end
    if not self.info.serialNumber then
        self.info.serialNumber = hex.hexify(string.sub(sha:final(), 1, 8))
    end
end

function t.mt:add_info_it_telecom_keys(value, max_objects)
    self.it_telecom_info.public_keys = {}
    for i=1,max_objects*2,2 do
        local modulus = string.sub(value, 1+(256 * (i-1)), 256 * (i))
        local pubexp  = string.sub(value, 1+(256 * i), 256 * (i+1))
        
        log.output(i, "add_info_it_telecom_keys(): raw modulus", hex.hexify(modulus))
        log.output(i, "add_info_it_telecom_keys(): raw pubexp", hex.hexify(pubexp))

        -- print(i, "modulus trimmed", hex.hexify(string.sub(modulus, 129, -1)))
        -- print(i, "pubexp trimmed", hex.hexify(string.sub(pubexp, 129, -1)))
        
        if string.sub(modulus, 129, -1) == string.rep("\255", 128) then
            modulus = string.sub(modulus, 1, 128)
            pubexp = string.sub(pubexp, 1, 128)
        end
        local key = {
                    modulus = t.lunpad(modulus, '\0'), 
                    pubexp = t.lunpad(pubexp, '\0')
                    }
        if string.len(key.modulus) == 0 or key.modulus == string.rep("\255", 128) or key.modulus == string.rep("\255", 256) then
            log.output("add_info_it_telecom_keys(): FOUND A Blank key slot")
            key = { modulus = "", pubexp = "" }
        end
        table.insert(self.it_telecom_info.public_keys, key)
    end
end

local function parse_tlv(tlv_struct)
    local len1 = string.len(tlv_struct)
    local i, tag, len
    local parsed_tlvs = {}
    --print ('len1:', len1)
    local pcRes, theErrorT = pcall(function()
        for i=1, len1 do
            tag = string.byte(tlv_struct, i)
            len = string.byte(tlv_struct, i+1)
            --print('parser:', i, tag, len)
            parsed_tlvs[tag] = string.sub(tlv_struct, i+2, i+2+len-1)
            i = i+2+len-1
            --print("new i:", i)
        end
    end)
    if not pcRes then
        log.output("parse_tlv error:", theErrorT)
        log.output("parse_tlv struct:", hex.hexify(tlv_struct or ''))
    end
    return parsed_tlvs
end

local function un_utf16(utf16_le_string)
    local l = string.len(utf16_le_string)
    local outstr = ""
    for i=1,l,2 do
        local c = string.byte(utf16_le_string, i+1)
        outstr = outstr .. string.char(c)
    end
    return outstr
end

function t.mt:add_info_it_telecom()
    local max_objects = 5
    -- it_telecom_info contiene le info sul FS di firma specifico della IT TELECOM
    self.it_telecom_info = {}
    self.info.serialNumber = nil
    
    local select_1f11 = function()
            self.it_telecom_hcard:select(hexf("1f11"))
        end
    if not pcall(select_1f11) then
        self.it_telecom_hcard:select_aid()
        select_1f11()
    end

    pcall(function()
        self.it_telecom_hcard:select(hexf("1f15"))
        local size = self.it_telecom_hcard:mread_binary(0, 4)
        local index = 3
        if string.sub(size, 1, 2) == hex.hexf("7F1F") then
            local tagLen = 0
            local tagLen1 = string.byte(size, 3)
            local tagLen2 = string.byte(size, 4)
            if tagLen1 > 127 then
                tagLen = tagLen2
                index = index+1
            else
                tagLen = tagLen1
            end
            local tlvData = self.it_telecom_hcard:mread_binary(index, tagLen)
            local tlv = parse_tlv(tlvData)
            
            if type(tlv[135]) == "string" then
                self.info.label = un_utf16(tlv[135])
                log.output("Found Label:", self.info.label)
            end
            if type(tlv[136]) == "string" then
                self.info.manufacturerID = un_utf16(tlv[136])
                log.output("Found manufacturerID:", self.info.manufacturerID)
            end
            if type(tlv[137]) == "string" then
                self.info.model = un_utf16(tlv[137])
                log.output("Found Model:", self.info.model)
            end            
            if type(tlv[138]) == "string" then
                self.info.serialNumber = hex.hexify(tlv[138])
                log.output("Found serialNumber:", self.info.serialNumber)
            end
        end
    end)
    
    self.it_telecom_hcard:select(hexf("1f11"))
    local header_len = 100
    local cert_index_str = self.it_telecom_hcard:mread_binary(0, header_len)
    -- aggiunge eventuale padding
    cert_index_str = cert_index_str .. string.rep('\0', 100 - string.len(cert_index_str))
    
    self:add_info_it_telecom_certs(cert_index_str)
    
    
    
    local value = ""

    if self.cfg["fastread"]=='true' then
        log.output("Assuming keys exists: reading public key value from each certificate")
        self.it_telecom_info.public_keys = {}
        for i, v in self.it_telecom_info.certificates do
            local cert = self.it_telecom_info.certificates[i]
            local parsed_cer = der.parse_x509cer(cert.val) or {}
            local key = {modulus=parsed_cer.modulus or "", pubexp=parsed_cer.pubexp or ""}
            table.insert(self.it_telecom_info.public_keys, key)
        end
    else
        self.it_telecom_hcard:select(hexf("1f12"))
        for i=0,max_objects-1 do
            local value1 = self.it_telecom_hcard:mread_binary(i*512, 8)
            if value1 == string.rep("\255", 8) then
                log.output("R/W: detected empty key:", i+1)
                value1 = string.rep("\255", 512)
            else
                local value2 = self.it_telecom_hcard:mread_binary(i*512 + 128, 8)
                if value2 == string.rep("\255", 8) then
                    log.output("R/W: detected 1024 bit key:", i+1)
                    value1 = value1 .. self.it_telecom_hcard:mread_binary(i*512+8, 128-8) .. string.rep("\255", 128)
                    value1 = value1 .. self.it_telecom_hcard:mread_binary(i*512 + 256, 128) .. string.rep("\255", 128)
                else
                    value1 = value1 .. self.it_telecom_hcard:mread_binary(i*512 + 8, 512 - 8)
                end
            end
            value = value .. value1
        end
        self:add_info_it_telecom_keys(value, max_objects)
    end
    
end

function t.mt:get_info()
    if not self.info then
        self.info = {
            label = 'TI SecureSIM',
            manufacturerID = 'Telecom Italia',
            model = 'SecureSIM',
            serialNumber = nil,
            flags = CKF.RNG + CKF.LOGIN_REQUIRED + CKF.TOKEN_INITIALIZED,
            ulMaxSessionCount = CK.EFFECTIVELY_INFINITE,
            ulSessionCount = 0,
            ulMaxRwSessionCount = CK.EFFECTIVELY_INFINITE,
            ulRwSessionCount = CK.UNAVAILABLE_INFORMATION,
            ulMaxPinLen = self.it_telecom_hcard.PUK_PADDING or 8,
            ulMinPinLen = 1,
            ulTotalPublicMemory = 31988,
            ulFreePublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulTotalPrivateMemory = 780,
            ulFreePrivateMemory = CK.UNAVAILABLE_INFORMATION,
            hardwareVersion = { major=0, minor=0},
            firmwareVersion = { major=0, minor=0},
            utcTime = '0000000000000000'
        }
        
        self:add_info_it_telecom()
        if self.info.flags[CKF.TOKEN_INITIALIZED] then
            self.info.flags = self.info.flags + CKF.USER_PIN_INITIALIZED
        end
    
    end 

    return self.info
end

function t.mt:get_mechanisms()
    local info = self:get_info()
    return self.mechanisms
end

function t.mt:verify_pin(pin, userType, contextual_obj)
    local ispuk = false
    local result

    if userType == CKU.SO then 
        ispuk = true
    end
    log.output("verify_pin()", pin, userType, ispuk, contextual_obj)
    if userType == CKU.USER or userType == CKU.SO then
        result = self.it_telecom_hcard:verify_pin_main(pin, ispuk)
        self:update_pin_status()
        log.output("verify_pin(): result=", result)
        if result == 0 then
            self.cached_main_pin = pin
            self.userType = userType
            return CKR.OK
        end
    else
        return CKR.USER_TYPE_INVALID
    end
    
    if result == 1 then
        return CKR.PIN_INCORRECT
    elseif result == 2 then
        return CKR.PIN_LOCKED
    else
        return CKR.FUNCTION_FAILED
    end
end

function t.mt:change_pin(oldPin, newPin)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk = false
    if self.userType == CKU.SO then ispuk = true end
    local pcRes, result
    local info = self:get_info() -- carica le info sul filesystem in cache
    self._schedule_update_retry_counters = true
    log.output('token-it-telecom change_pin1(): oldPin:' .. oldPin, 'newPin:' .. newPin)

    self.it_telecom_hcard:select_aid()
    result = self.it_telecom_hcard:change_pin_main(oldPin, newPin, ispuk)
    self:update_pin_status()
    
    if result == 0 then
        self.cached_main_pin = newPin
        if not self.userType then 
            self.userType = userType
        end
        return CKR.OK
    elseif result == 1 then
        return CKR.PIN_INCORRECT
    elseif result == 2 then
        return CKR.PIN_LOCKED
    elseif result == 3 then
        return CKR.PIN_LEN_RANGE
    else
        return CKR.FUNCTION_FAILED
    end
end

function t.mt:update_pin_status()
    log.output('update_pin_status(): using _pin_status:', self.it_telecom_hcard._pin_status)
    if self.info then
        log.output('update_pin_status(): clearing pin state')
        self.info.flags = self.info.flags - CKF.USER_PIN_LOCKED
        self.info.flags = self.info.flags - CKF.USER_PIN_FINAL_TRY
        self.info.flags = self.info.flags - CKF.USER_PIN_COUNT_LOW
        self.info.flags = self.info.flags + self.it_telecom_hcard._pin_status
    end
end

function t.mt:reset_pin(newPin)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local pcRes, result
    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-it-telecom reset_pin(): newPin:' .. newPin)
    if self.userType ~= CKU.SO then
        log.output('token-it-telecom reset_pin(): user not SO!')
        return CKR.FUNCTION_FAILED
    end
    
    self._schedule_update_retry_counters = true
    
    self.it_telecom_hcard:select_aid()
    result = self.it_telecom_hcard:reset_pin_main(self.cached_main_pin, newPin)
    self:update_pin_status()
    if result == 0 then
        return CKR.OK
    elseif result == 1 then
        return CKR.PIN_INCORRECT
    elseif result == 2 then
        return CKR.PIN_LOCKED
    elseif result == 3 then
        return CKR.PIN_LEN_RANGE
    else
        return CKR.FUNCTION_FAILED
    end
end

function t.mt:unverify_pin()
    -- per il momento non fa niente, potrebbe essere configurata per il reset della carta, se necessario
    self.cached_main_pin = nil
    self.userType = nil
end


--=====================================================================================
-- Funzioni per il recupero degli attributi
--=====================================================================================
-- Nella funzione seguente il parametro viene "onlysize" trascurato.
-- Il motivo 