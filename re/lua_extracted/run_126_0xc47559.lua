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

function t.mt:add_dni_objects(objects)
    local obj
    log.output('token-dni:add_dni_objects(): adding DNI objects...')
    if self.dni_info then
        if self.dni_info.sign_cert_valid then
            log.output('token-dni-peru:add_dni_objects(): adding DNI Sign Certificate...')
            obj = GetCertTemplate(t.mt.get_certificate)
            obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(true) 
            obj[CKA.ID] = OBJ_IDS.SIGN_ID
            obj.path = self.dni_info.pki_path .. '3402'
            objects.max_index = objects.max_index+1
            objects[ objects.max_index ] = obj
            log.output('token-dni-peru:add_dni_objects(): added sign certificate:',
                objects.max_index,
                hex.hexify(obj[CKA.CLASS]))
            self.dni_info.sign_cert_handle = objects.max_index
        end
        if self.dni_info.ca_cert_valid then
            log.output('token-dni-peru:add_dni_objects(): adding DNI CA Certificate...')
            obj = GetCertTemplate(t.mt.get_certificate)
            obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(true) 
            obj[CKA.ID] = OBJ_IDS.CA_ID
            obj.path = self.dni_info.pki_path..'3407'
            objects.max_index = objects.max_index+1
            objects[ objects.max_index ] = obj
            log.output('token-dni-peru:add_dni_objects(): added CA certificate:',
                objects.max_index,
                hex.hexify(obj[CKA.CLASS]))
            self.dni_info.ca_cert_handle = objects.max_index
        end
        if self.dni_info.intermediate_ca_cert_valid then
            log.output('token-dni-peru:add_dni_objects(): adding DNI intermediate CA Certificate...')
            obj = GetCertTemplate(t.mt.get_certificate)
            obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(true) 
            obj[CKA.ID] = OBJ_IDS.INTERMEDIATE_CA_ID
            obj.path = self.dni_info.pki_path..'3408'
            objects.max_index = objects.max_index+1
            objects[ objects.max_index ] = obj
            log.output('token-dni-peru:add_dni_objects(): added intermediate CA certificate:',
                objects.max_index,
                hex.hexify(obj[CKA.CLASS]))
            self.dni_info.intermediate_ca_cert_handle = objects.max_index
        end
        if self.dni_info.sign_key_valid then
            log.output('token-dni-peru:add_dni_objects(): adding DNI Sign Pub and Priv keys...')
            
            objects.max_index = objects.max_index+1
            local objPub = GetPubKeyTemplate(t.mt.get_public_key)
            objPub.related_cert_handle = self.dni_info.sign_cert_handle
            objPub[CKA.ID] = OBJ_IDS.SIGN_ID
            objPub[CKA.LABEL] = OBJ_IDS.SIGN_PUBKEY_LABEL
            objects[ objects.max_index ] = objPub
            log.output('token-dni-peru:add_dni_objects(): added pub key:',
                objects.max_index,
                hex.hexify(objPub[CKA.CLASS]))
            self.dni_info.sign_pub_key_handle = objects.max_index
            
            objects.max_index = objects.max_index+1
            local objPriv = GetPrivKeyTemplate(t.mt.get_public_key)
            objPriv.related_cert_handle = self.dni_info.sign_cert_handle
			-- objPriv.related_public_key = objPub.path
            -- objPriv.path = self.cmd_info.ds_sig_path
            objPriv.kid = 2
            -- objPriv[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(true)
            -- objPriv.pso_dec = false
            objPriv.private=true
            -- objPriv.key_bits = 1024
            objPriv[CKA.ID] = OBJ_IDS.SIGN_ID
            objPriv[CKA.LABEL] = OBJ_IDS.SIGN_PRIVKEY_LABEL
            objPriv[CKA.PRIVATE] = eCK.BBOOL(objPriv.private)
            -- objPriv[CKA.DECRYPT] = eCK.BBOOL(false)
            objPriv[CKA.SIGN] = eCK.BBOOL(true)
            objects[ objects.max_index ] = objPriv
            log.output('token-dni-peru:add_dni_objects(): added priv key:',
                objects.max_index,
                hex.hexify(objPriv[CKA.CLASS]))
            self.dni_info.sign_priv_key_handle = objects.max_index
        end        
    end
end

function t.mt:get_objects()

    log.output('token-dni-peru:get_objects()')
    local info = self:get_info() -- carica le info sul filesystem in cache
    
    local objects = {
            min_index = 11001, -- primo indice disponibile
            max_index = 11000, -- valore dell'indice massimo (i valori intermedi possono anche essere nil)
        }

    self:add_dni_objects(objects)

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
    if attr == -1 then
        return CKR.ATTRIBUTE_TYPE_INVALID 
    end
    local result = obj[attr]
    if result == nil then
        log.output('get_attribute_value(): object', hobj, 'doesn\'t define specified attribute', attr)
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
    return self.dni_hcard:valid()
end

return t
--===========================================================================
end
}
_LOADED['DniSmartcard'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
local hex = require 'hex'
local hexf, hexify = hex.hexf, hex.hexify

local DniSmartcard = {}
DniSmartcard.mt = {}
DniSmartcard.mt.__index = DniSmartcard.mt

DniSmartcard.PIN_PADDING = 8
DniSmartcard.MAX_TRANSMIT_BUFFER_SIZE = 120

DniSmartcard.DniSmartcardError = {}
DniSmartcard.DniSmartcardError.mt = {}
DniSmartcard.DniSmartcardError.mt.__index = DniSmartcard.DniSmartcardError.mt

function DniSmartcard.DniSmartcardError.mt.__tostring(e)
    return "DniSmartcardError: " .. (e.msg or '') .. ' ;SW=' .. hex.hexify(e.sw or '') 
end

function DniSmartcard.DniSmartcardError.new(sw, msg)
    local e = msg .. ' ;sw=' .. hexify(sw or '')
    return e
end

function DniSmartcard.new(card)
    local self = {
                    PIN_PADDING=DniSmartcard.PIN_PADDING,
                  }
    self.card = card
    setmetatable(self, DniSmartcard.mt)
    return self
end

function DniSmartcard.mt:begin_transaction()
    self.card:begintransaction()
    if self.on_begin_transaction then
        self:on_begin_transaction()
    end
end

function DniSmartcard.mt:end_transaction()
    self.card:endtransaction()
end

function DniSmartcard.mt:transmit(apdu)
    if self.on_transmit then
        self:on_transmit(apdu)
    end
    local result, scarderr = self.card:transmit(apdu)
    if not result then
        error(DniSmartcard.DniSmartcardError.new('', string.format('transmit error: 0x%x', scarderr) ))
    end
    self.last_sw = string.sub(result, -2, -1)
    return result
end

function DniSmartcard.mt:read_binary(offset, size)
    local template = '00B0%H%B'
    local recv = self:transmit(hexf(template, offset, size))
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(DniSmartcard.DniSmartcardError.new(sw, 'read_binary Error'), 2)
    end
    local data = string.sub(recv, 1, -3)
    return data
end

function DniSmartcard.mt:mread_binary(offset, size)
    -- TO DO: record bounded (P2=0x00)
    local buffer_size = DniSmartcard.MAX_TRANSMIT_BUFFER_SIZE
    local content = ''
    while size>0 do
        if size<buffer_size then buffer_size = size end
        local recv = self:read_binary(offset, buffer_size)
        offset = offset  + buffer_size
        size = size - buffer_size
        content = content .. recv
    end
    return content
end

function DniSmartcard.mt:select(path)
    local template_h, template_p = '00A4000002%H', '00A40000%P'
    local recv
    if type(path) == 'number' then
        recv = self:transmit(hexf(template_h, path))
    else
        local pathlen = string.len(path)
        assert(math.mod(pathlen, 2) == 0, 'invalid selection path')
        for i = 1, pathlen, 2 do
            local id = string.sub(path, i, i + 1)
            recv = self:transmit(hexf(template_p, id))
        end
    end
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(DniSmartcard.DniSmartcardError.new(sw, 'select Error'), 2)
    end
end

-- path_cert: ascii hex string
function DniSmartcard.mt:read_x509_certificate(path_cert, offset)
    local path = path_cert
    if offset == nil then offset=0 end

    log.output('read_x509_certificate():')
    self:select(path)
    log.output('read_x509_certificate(): using plain text')
    local der_size = self:read_binary(offset, 4)
    if string.sub(der_size, 1, 2) == hexf('5a82') then  -- Z\x82 + sizeBE + compressed data
        local size = string.byte(der_size, 3) * 256 + string.byte(der_size, 4)
        log.output('read_x509_certificate(): PT: using CPR mode: expected size:', size)
        local compr = self:mread_binary(offset+4, size)
        local decompr = zlib.decompress(compr, true, nil, nil)
        log.output('read_x509_certificate(): PT: cpr ratio:', 
                (4+string.len(compr))/string.len(decompr or "0"))
        return decompr
    else
        if string.sub(der_size, 1, 2) ~= hexf('3082') then
            error('CnsSmartcard read_x509_certificate Error: bad certificate', 2)
        end
        local size = string.byte(der_size, 3) * 256 + string.byte(der_size, 4)
        return der_size .. self:mread_binary(offset+4, size)        
    end
end

function DniSmartcard.mt:valid()
    local status, err = self.card:status()
    if not status then
        log.output('DniSmartcard:valid(): status() error', hex.tohex8(err or 0))
        return false
    elseif status.protocol == 0 or string.len(status.atr or '') == 0 then
        log.output('DniSmartcard:valid(): card removed?')
        return false
    end
    return true
end

function DniSmartcard.mt:verify_pin(type_, pin)
    local padding = string.rep(string.char(255), DniSmartcard.PIN_PADDING)
    local padded_pin = string.sub(pin..padding, 1,  DniSmartcard.PIN_PADDING)
    local apdu = hexf('002000%B%P', type_, padded_pin)
    local recv = self:transmit(apdu)
    local sw = string.sub(recv, -2, -1)
    if sw == hexf('9000') then
        return 0
    elseif (bin.flags(bin.unpack('%H', sw)) * bin.flags('0xFFF0')).asnumber == hex.h2i('63C0') then
        return 1
    elseif sw == hexf('6983') then
        return 2
    else
        log.output('DniSmartcard:verify_pin(): Error ' .. hexify(sw) )
        error(DniSmartcard.DniSmartcardError.new(sw, 'verify_pin Error' ), 2)
    end
end

function DniSmartcard.mt:verify_auth_pin(pin)
    return self:verify_pin(1, pin)
end

function DniSmartcard.mt:verify_sign_pin(pin)
    return self:verify_pin(4, pin)
end

function DniSmartcard.mt:mse_pso(data, kid)
    local apdu, recv, sw

    apdu = hexf('002241B6068001118301%B', kid)
    recv = self:transmit(apdu)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        log.output('DniSmartcard:mse_pso(): MSE Error ' .. hexify(sw) )
        error(DniSmartcard.DniSmartcardError.new(sw, 'mse_pso MSE Error' ), 2)
    end
    
    apdu = hexf('002A9E9A%P', data)
    recv = self:transmit(apdu)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        log.output('DniSmartcard:mse_pso(): PSO Error ' .. hexify(sw) )
        error(DniSmartcard.DniSmartcardError.new(sw, 'mse_pso PSO Error' ), 2)
    end
    return string.sub(recv, 1, -3)
end

return DniSmartcard

--===========================================================================
end
}
_LOADED['tokens_table'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================

-- ALWAYS GENERATED FILE: DON'T EDIT!

local tokens_table = {}
local active_tokens = {
[1280]=require("token-p11wrap"),
[134218752]=require("token-cosmox-ida"),
[33555456]=require("token-nxp-chipdoc"),
[67109888]=require("token-nxp-chipdoc-lite"),
[16778240]=require("token-siae"),
[8389632]=require("token-cie3"),
[2098176]=require("token-cryptoid"),
[33792]=require("token-inside"),
[1152]=require("token-ts"),
[66560]=require("token-ts"),
[1025]=require("token-ts-pinpad"),
[1026]=require("token-cns-oberthur"),
[1032]=require("token-athena"),
[4195328]=require("token-arjo"),
[1040]=require("token-gemalto-classic"),
[1056]=require("token-aet"),
[1049600]=require("token-piv"),
[17408]=require("token-iasecc"),
[9216]=require("token-cmg"),
[263168]=require("token-eida"),
[1088]=require("token-cmd"),
[3072]=require("token-it-telecom"),
[5120]=require("token-cardos44"),
[525312]=require("token-dni-peru"),

}
local compiled_tokens = {}
for i, v in active_tokens do
    compiled_tokens[i] = v
end
local build_id = 'bit4id pki:  TOKENS= p11wrap,  idacosmox,  nxpias,  nxpcdlite,  siae,  cie3,  cryptoid,  bit4id_me,  cns-only,  incardtsfull,  incardtspinpad,  oberthur,  athena,  arjo,  gemalto_classic,  aet_starcos,  piv,  iasecc,  cmg,  eida,  cmd_milcard,  it_telecom,  cardos44,  dni_peru,  (BUILD-licensing)'
tokens_table.active_tokens = active_tokens;
tokens_table.compiled_tokens = compiled_tokens;
tokens_table.active_tokens_mask = bin.flags(268303867);
tokens_table.compiled_tokens_mask = bin.flags(268303867);

log.output("checking token licenses...")
local pcRes, theErrorT = pcall( function()
    local licensing = require "licensing"
    local utility = require "utility"
    if licensing.check_token_license then
        local cfg = utility.parse_cfg()
        local nomadic = cfg["nomadic"] ~= "false"
        log.output("nomadic (portable) mode=", nomadic, cfg["nomadic"])
        local disabled = {}
        local always_enabled={["idacosmox"]=true, ["nxpias"]=true, ["nxpcdlite"]=true, ["cryptoid"]=true, ["bit4id_me"]=true, ["incardts"]=true, ["incardtsfull"]=true, ["oberthur"]=true, ["p11wrap"]=true}
        for i,v in active_tokens do
            if v.name then
                local valid, cfg
                valid, cfg = licensing.check_token_license(v.name, i)
                if not valid then
                    if nomadic and always_enabled[v.name] then
                        valid = true
                        cfg = cfg or {}
                        log.output(string.rep("*", 40))
                        log.output("token always enabled:", v.name)
                        log.output(string.rep("*", 40))
                    else
                        log.output(string.format("disabling token: '%s' (ID=%08x)",v.name, i))
                        table.insert(disabled, i)
                        tokens_table.active_tokens_mask = 
                            tokens_table.active_tokens_mask - (bin.flags(i)-bin.flags(1024)-bin.flags(512))
                        log.output("tokens_table.active_tokens_mask:", tokens_table.active_tokens_mask)
                    end
                else
                    v.mt._token_cfg = cfg
                end
            end
        end
        for i=1,table.getn(disabled) do
            active_tokens[disabled[i]] = nil
        end
    end
end)
if not pcRes then
    log.output("check_licenses error:", theErrorT )
end

log.output("build_id:", build_id)
return tokens_table

--===========================================================================
end
}

