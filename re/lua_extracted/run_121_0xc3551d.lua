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

function t.mt:add_it_telecom_objects(objects)
    local obj
    log.output('token-it-telecom:add_it_telecom_objects(): adding IT TELECOM objects...')
    if self.it_telecom_info then
        for i, v in self.it_telecom_info.certificates do
            log.output('token-it-telecom:add_it_telecom_objects(): adding IT TELECOM Certificate:', i)
            obj = objCnsTmpl.GetCNSCertTemplate(t.mt.get_certificate)
            obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false) 
            obj[CKA.ID] = "OBJECT" .. i
            obj[CKA.LABEL] = "CERTIFICATE" .. i
            obj.value = v.val
            obj.num = i
            objects.max_index = objects.max_index+1
            objects[ objects.max_index ] = obj
            log.output('token-it-telecom:add_it_telecom_objects(): added certificate:',
                objects.max_index,
                hex.hexify(obj[CKA.CLASS]))
        end
        for i, v in self.it_telecom_info.public_keys do
            if v.modulus and string.len(v.modulus) > 0 and v.pubexp and string.len(v.pubexp) > 0 then
            
                log.output('token-it-telecom:add_it_telecom_objects(): adding IT TELECOM Pub and Priv key:', i)
                objects.max_index = objects.max_index+1
                local objPub = objCnsTmpl.GetCNSPubKeyTemplate(t.mt.get_public_key)
                objPub.num = i
                objPub.key_bits = string.len(v.modulus) * 8
                objPub.modulus = v.modulus
                objPub.pubexp = v.pubexp

                objPub[CKA.ID] = "OBJECT" .. i
                objPub[CKA.LABEL] = "PUBLIC" .. i
                objects[ objects.max_index ] = objPub
                log.output('token-it-telecom:add_it_telecom_objects(): added pub key:',
                    objects.max_index,
                    hex.hexify(objPub[CKA.CLASS]))
                self.it_telecom_info.pub_key_handle = objects.max_index
                
                objects.max_index = objects.max_index+1
                local objPriv = objCnsTmpl.GetCNSPrivKeyTemplate(t.mt.get_public_key)
                objPriv.kid = i
                objPriv.num = i
                objPriv[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
                objPriv.pso_dec = true
                objPriv.private=true
                objPriv.key_bits = string.len(v.modulus) * 8
                objPriv.modulus = v.modulus
                objPriv.pubexp = v.pubexp
                
                objPriv[CKA.ID] = "OBJECT" .. i
                objPriv[CKA.LABEL] =  "PRIVATE" .. i
                objPriv[CKA.PRIVATE] = eCK.BBOOL(objPriv.private)
                objPriv[CKA.DECRYPT] = eCK.BBOOL(true)
                objPriv[CKA.SIGN] = eCK.BBOOL(true)
                objects[ objects.max_index ] = objPriv
                log.output('token-it-telecom:add_it_telecom_objects(): added priv key:',
                    objects.max_index,
                    hex.hexify(objPriv[CKA.CLASS]))
            else
                log.output('token-it-telecom:add_it_telecom_objects(): key invalid:', i)
            end
        end
    end
end


function t.mt:get_objects()

    log.output('token-it-telecom:get_objects()')
    local info = self:get_info() -- carica le info sul filesystem in cache
    
    local objects = {
            min_index = 11001, -- primo indice disponibile
            max_index = 11000, -- valore dell'indice massimo (i valori intermedi possono anche essere nil)
        }

    self:add_it_telecom_objects(objects)

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
    return self.it_telecom_hcard:valid()
end

function t._is_private_attribute(attr_type)
    local private_attributes = {
        CKA.PRIVATE_EXPONENT,
        CKA.PRIME_1,
        CKA.PRIME_2,
        CKA.EXPONENT_1,
        CKA.EXPONENT_2,
        CKA.COEFFICIENT,
        CKA.PRIME,
        CKA.SUBPRIME,
        CKA.BASE,
    }
    for i, v in private_attributes do
        if attr_type == v then
            return true
        end
    end
    return false
end



function t.mt:get_object_size(hobj)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj == nil then return CKR.OBJECT_HANDLE_INVALID end
    local oSize = -1
    
        if obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
            oSize = type(obj[CKA.VALUE]) == string and string.len(obj[CKA.VALUE]) or nil
        elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
            oSize = 130*2
        elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
            oSize = 300
        elseif obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
            oSize = type(obj[CKA.VALUE]) == string and string.len(obj[CKA.VALUE]) or nil
        end       
    return CKR.OK, oSize
end

function t.mt:get_special_ids(id_class)

end

function t.mt:rebuild_certificates_file(actual_cert_data, obj)
    local new_certificates = utility.clone_table(self.it_telecom_info.certificates)
    if actual_cert_data then
        local compressed_cert_data = zlib.compress(actual_cert_data)
        assert(type(compressed_cert_data) == 'string')

        local cert = {val=actual_cert_data, val_compressed = compressed_cert_data}
        table.insert(new_certificates, cert)
        log.output('rebuild_certificates_file(): adding a new cert as last item...')
    end
    
    local count = table.getn(new_certificates) + 1
    if obj then
        obj.num = count -1
        obj.value = actual_cert_data
        log.output('rebuild_certificates_file(): assigned obj num:', obj.num)
    end
    local header = hex.hexf("%H", 2+ count*2)
    assert(string.len(header) == 2)
    local cur_offset = 101
    local data_part = "\123"
    log.output('rebuild_certificates_file(): rebuiding data from certificates table...')
    
    for i, v in new_certificates do
        -- ricostruisce il contenuto dell'indice
        header = header .. hex.hexf("%H", cur_offset)
        cur_offset = cur_offset + string.len(v.val_compressed)
        data_part = data_part .. v.val_compressed
    end

    data_part = data_part .. "\000" -- giusto per pulizia
   
    log.output('rebuild_certificates_file(): closing header...')
    header = header .. hex.hexf("%H", cur_offset)
    header = header .. string.rep("\000", 100 - string.len(header))
    assert(string.len(header) == 100)
    
    local new_certificates_contents = header .. data_part
    -- reparse del nuovo file: ricostruisce self.it_telecom_info.certificates, lasciando inalterato l'ordine dei certificati
    return new_certificates_contents
end

function t.mt:create_object_certificate(pTemplate)
    log.output('create_object_certificate()', pTemplate)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    if not pTemplate[CKA.VALUE] then
        log.output('create_object_certificate(): VALUE not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local parsed_cer
    
    pcall(function()
        parsed_cer = der.parse_x509cer(pTemplate[CKA.VALUE])
        log.output('create_object_certificate(): certificate parsed:', parsed_cer)
    end)

    obj = objCnsTmpl.GetCNSCertTemplate(t.mt.get_certificate)
    
    local pTemplate_copy = utility.clone_table(pTemplate)
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if not pTemplate_copy[k] and obj[k] and type(obj[k]) == 'string' then
            pTemplate_copy[k] = obj[k]
        end
    end
    
    if parsed_cer then
        pTemplate_copy[CKA.SUBJECT] = pTemplate_copy[CKA.SUBJECT] or parsed_cer.subject
        pTemplate_copy[CKA.ISSUER] = pTemplate_copy[CKA.ISSUER] or parsed_cer.issuer
        pTemplate_copy[CKA.SERIAL_NUMBER] = pTemplate_copy[CKA.SERIAL_NUMBER] or parsed_cer.serialNumber
    end
    
    local actual_cert_data = pTemplate[CKA.VALUE]
    
    
    
    local new_certificates_contents = self:rebuild_certificates_file(actual_cert_data, obj)
    self:add_info_it_telecom_certs(string.sub(new_certificates_contents, 1, 100), string.sub(new_certificates_contents, 101, -1))
    
    self.it_telecom_hcard:select_aid()
    pcall(function() 
        if self.cached_main_pin and self.userType == CKU.USER then
            self.it_telecom_hcard:verify_pin_main(self.cached_main_pin, false, true)
        end
    end)
    self.it_telecom_hcard:select(hexf("1f11"))
    
    log.output('create_object_certificate(): new_certificates_contents:', hex.hexify(new_certificates_contents))
    
    self.it_telecom_hcard:mupdate_binary(0, new_certificates_contents)
    
    -- todo: update persistent PKCS#11 attributes

    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] and not t._is_private_attribute(k) then
            obj[k] = pTemplate[k]
        end
    end
    if parsed_cer then
        if not pTemplate[CKA.SUBJECT] then
            obj[CKA.SUBJECT] = parsed_cer.subject
        end
        if not pTemplate[CKA.ISSUER] then
            obj[CKA.ISSUER] = parsed_cer.issuer
        end
        if not pTemplate[CKA.SERIAL_NUMBER] then
            obj[CKA.SERIAL_NUMBER] = parsed_cer.serialNumber
        end
    end

    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj

    return CKR.OK, self.attributes.max_index
end




function t.mt:generate_key_pair(pMechanism, templatePub, templatePriv)

    log.output('generate_key_pair()', templatePub, templatePriv)
    if self.userType ~= CKU.USER then
        log.output('generate_key_pair(): not loggen in, userType', self.userType)
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local objPriv, objPub

    local templatePub1 = utility.clone_table(templatePub)
    local templatePriv1 = utility.clone_table(templatePriv)
    
    templatePriv1[CKA.SIGN] = templatePriv1[CKA.SIGN] or eCK.BBOOL(true)
    templatePriv1[CKA.DECRYPT] = templatePriv1[CKA.DECRYPT] or eCK.BBOOL(true)
    
    if templatePub1[CKA.ID] then
        templatePriv1[CKA.ID] = templatePub1[CKA.ID]
    elseif templatePriv1[CKA.ID] then
        templatePub1[CKA.ID] = templatePriv1[CKA.ID]
    end
    local free_kid_index
    local cka_modulus_bits = templatePub1[CKA.MODULUS_BITS] or templatePriv1[CKA.MODULUS_BITS] or eCK.ULONG(1024)
    
    local modulus_bits
    if not cka_modulus_bits or cka_modulus_bits == eCK.ULONG(1024) then
        modulus_bits = 1024
    elseif cka_modulus_bits == eCK.ULONG(2048) then
        modulus_bits = 2048
    else
        log.output('generate_key_pair(): key size invalid:', hex.hexify(cka_modulus_bits) )
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    local freeId
    local modulus, pubexp
    
    self:invalidate_xproc_cache()
    
    free_kid_index = self.it_telecom_hcard:get_free_kid()
    
    local i = free_kid_index
    objPub = objCnsTmpl.GetCNSPubKeyTemplate(t.mt.get_public_key)
    objPub.num = i
    objPub.key_bits = modulus_bits
    objPub[CKA.ID] = "OBJECT" .. i
    objPub[CKA.LABEL] = "PUBLIC" .. i
        
    objPriv = objCnsTmpl.GetCNSPrivKeyTemplate(t.mt.get_public_key)
    objPriv.kid = i
    objPriv.num = i
    objPriv[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
    objPriv.pso_dec = true
    objPriv.private=true
    objPriv.key_bits = modulus_bits
    
    objPriv[CKA.ID] = "OBJECT" .. i
    objPriv[CKA.LABEL] =  "PRIVATE" .. i
    objPriv[CKA.PRIVATE] = eCK.BBOOL(objPriv.private)
    objPriv[CKA.DECRYPT] = eCK.BBOOL(true)
    objPriv[CKA.SIGN] = eCK.BBOOL(true)
    
    self.it_telecom_hcard:generate_key_pair(modulus_bits)
    modulus, pubexp =  self.it_telecom_hcard:read_public_key(objPriv.kid)

    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if templatePub1[k] and not t._is_private_attribute(k) then
            objPub[k] = templatePub1[k]
        end
        if templatePriv1[k] and not t._is_private_attribute(k) then
            objPriv[k] = templatePriv1[k]
        end
    end
    
    objPub[CKA.MODULUS_BITS] = eCK.ULONG(modulus_bits)
    objPub[CKA.MODULUS] = modulus
    objPub[CKA.PUBLIC_EXPONENT] = pubexp
    objPub.modulus = modulus
    objPub.pubexp = pubexp

    objPriv[CKA.MODULUS_BITS] = eCK.ULONG(modulus_bits)
    objPriv[CKA.MODULUS] = modulus
    objPriv[CKA.PUBLIC_EXPONENT] = pubexp
    objPriv.modulus = modulus
    objPriv.pubexp = pubexp
    
    -- todo: update PKCS#11 attributes
    
    -- adds new handles to the list
    local hPrivk, hPubk
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPriv
    hPrivk = self.attributes.max_index
    
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPub
    hPubk = self.attributes.max_index
    
    log.output('generate_key_pair(): success, returning', hPubk, hPrivk)
    return CKR.OK, hPubk, hPrivk
end


function t.mt:create_object(pTemplate)

    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    
    log.output('create_object(): verify_pin_main() cached pin, with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        log.output('create_object(): verifying cached pin...')
        self.it_telecom_hcard:verify_pin_main(self.cached_main_pin, false)
    end
    self:invalidate_xproc_cache()
    
    if pTemplate[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        return self:create_object_certificate(pTemplate)
    else
        log.output('create_object(): unsupported object class:', hex.hexify(pTemplate[CKA.CLASS] or ''))
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
end

function t.mt:destroy_object(hObject)
    if self.cns_only then
        log.output('destroy_object(): CNS only Token, cannot destroy objects')
        return CKR.TOKEN_WRITE_PROTECTED
    end

    log.output('destroy_object(): ', hObject)

    log.output('destroy_object(): verify_pin_main() cached pin, with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.it_telecom_hcard:verify_pin_main(self.cached_main_pin, false)
    end

    if self.userType ~= CKU.USER then
        log.output('destroy_object(): WARNING: user not logged in!')
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hObject]

    if not obj then
        log.output('destroy_object(): invalid handle!')
        return CKR.OBJECT_HANDLE_INVALID
    end
    
    self:get_attribute_value(hObject, CKA.LABEL)
    
    self:invalidate_xproc_cache()
    self.it_telecom_hcard:select_aid()
    pcall(function() 
        if self.cached_main_pin and self.userType == CKU.USER then
            self.it_telecom_hcard:verify_pin_main(self.cached_main_pin, false, true)
        end
    end)

    if obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        log.output('destroy_object(): CERTIFICATE')
        
        table.remove(self.it_telecom_info.certificates, obj.num)
        local new_certificates_contents =  self:rebuild_certificates_file()

        self:add_info_it_telecom_certs(string.sub(new_certificates_contents, 1, 100), string.sub(new_certificates_contents, 101, -1))
        self.it_telecom_hcard:select(hexf("1f11"))
        log.output('destroy_object(): new_certificates_contents:', hex.hexify(new_certificates_contents))
        self.it_telecom_hcard:mupdate_binary(0, new_certificates_contents)
        log.output('destroy_object(): complete')
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        log.output('destroy_object(): PUBLIC_KEY: doing nothing!')
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        log.output('destroy_object(): PRIVATE_KEY')
        
        self.it_telecom_hcard:select(hexf("1f12"))
        self.it_telecom_hcard:delete_key_pair(obj.kid)
        self.it_telecom_info.public_keys[obj.kid] = {modulus="", pubexp=""}

        log.output('destroy_object(): complete')
        
    else
        log.output('destroy_object(): WARNING! Unsupported object class!')
        return CKR.FUNCTION_FAILED
    end
    
    self.attributes[hObject] = nil

    return CKR.OK
end


function t.mt:set_attribute_value(hObject, pTemplate)

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
    
    log.output('set_attribute_value(): copying new values in memory')
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] then
            obj[k] = pTemplate[k]
        end
    end
    return CKR.OK    
end


function t.mt:flush_cache()
    if self.cfg["xproc"] ~= "true" then
        return false
    end
    local changed, cache_id
    if self._cache_id == nil then
        log.output("token-it-telecom:flush_cache(): initializing _cache_id")
        changed, self._cache_id = utility.has_token_changed(self, "cache", 0)
        log.output("token-it-telecom:flush_cache(): initialize: _cache_id:", self._cache_id)
    end
    changed, cache_id = utility.has_token_changed(self, "cache", self._cache_id)
    if changed then
        log.output("token-it-telecom:flush_cache(): token has changed!")
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


-- log.output("token-it-telecom: setting token read only")
-- t.mt.create_object = nil
-- t.mt.generate_key_pair = nil
-- t.mt.destroy_object = nil

return t
--===========================================================================
end
}
_LOADED['token-cardos44'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- token-cardos44.lua
local hex = require 'hex'
local hexf = hex.hexf
local hexify = hex.hexify
local der = require 'der'
local utility = require 'utility'
local repr = utility.repr
local rsa = require 'rsa'
local zlib = require 'zlib'
local CnsSmartcard = require 'CnsSmartcard'
local CnsSmartcardError = CnsSmartcard.CnsSmartcardError

local CARDOSSmartcard = { mt={}}
for i, v in CnsSmartcard.mt do
    if type(v) == "function" then
        CARDOSSmartcard.mt[i] = CnsSmartcard.mt[i]
    end
end
CARDOSSmartcard.mt.__index = CARDOSSmartcard.mt

function CARDOSSmartcard.new(card)
    local self = {
                    PIN_PADDING=CnsSmartcard.PIN_PADDING,
                    PUK_PADDING=CnsSmartcard.PUK_PADDING,
                    BSO_CNS_PIN=CnsSmartcard.BSO_CNS_PIN, BSO_DS_PIN=CnsSmartcard.BSO_DS_PIN,
                    BSO_CNS_PUK=CnsSmartcard.BSO_CNS_PUK, BSO_DS_PUK=CnsSmartcard.BSO_DS_PUK,
                  }
    self.card = card
    setmetatable(self, CARDOSSmartcard.mt)
    return self

end

function CARDOSSmartcard.mt:select_ex(rpath, mode, getinfos)
    local template_p = '00A4%B%B%P'
    recv = self:transmit(hexf(template_p, mode, getinfos and 0 or 12, rpath) .. (getinfos and "\0" or "") )
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CnsSmartcardError.new(sw, 'select Error'), 2)
    elseif getinfos and string.len(recv) > 2 then
        return CnsSmartcard.parse_fci(recv)
    end
end

function CARDOSSmartcard.mt:verify_pin_main(pin, ispuk)
    log.output('verify_pin_cns():', pin, ispuk)
    local bso = self.BSO_CNS_PIN
    local padding = self.PIN_PADDING
    if ispuk then
        bso = self.BSO_CNS_PUK
        padding = self.PUK_PADDING
    end
    if string.len(pin)> padding then
        pin = string.sub(pin, 1, padding)
    end
    return self:sm_verify(bso, pin, true)
end


function CARDOSSmartcard.mt:change_pin_main(oldPin, newPin, ispuk)
    local bso = self.BSO_CNS_PIN
    local padding = self.PIN_PADDING
    if ispuk then
        bso = self.BSO_CNS_PUK
        padding = self.PUK_PADDING
    end
    if string.len(oldPin or '') > padding then
        oldPin = string.sub(oldPin, 1, padding)
    end
    if string.len(newPin) > padding then
        error('CnsSmartcard change_pin_main Error: wrong PIN size', 2)
    end
    local res = self:verify_pin_main(oldPin, ispuk)
    if res == 0 then
        res = self:sm_change(bso, nil, newPin, true)
    end
    return res
end



function CARDOSSmartcard.mt:reset_pin_main(Puk, newPin)
    if string.len(Puk or '' ) > self.PUK_PADDING then
        Puk = string.sub(Puk, 1, self.PUK_PADDING)
    end
    if string.len(newPin) > self.PIN_PADDING then
        error('CnsSmartcard reset_pin_main Error: wrong PIN size', 2)
    end
    local res
    
    res = self:verify_pin_main(Puk, true, true)
    if res ~= 0 then return res end
    
    res = self:sm_change(self.BSO_CNS_PIN, nil, newPin, true)
    return res
end

local objCnsTmpl = require 'token-cns-objects'


local MinKSize, MaxKSize = 1024, 2048

local t = {
    name = 'cardos44',
    mt = { },
    mechanisms = {
--        [ CKM.RSA_PKCS_KEY_PAIR_GEN ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.GENERATE_KEY_PAIR},
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_X_509 ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
    },
    cardos_hcard = nil,
    capabilities = { private_attributes_readable=true, always_authenticate_on_cert=true, },
}
t.mt.__index = t.mt

t.CARDOSSmartcard = CARDOSSmartcard

function t.mt:initialize(cfg)
    self.capabilities = utility.clone_table(t.capabilities)
    self.cardos_hcard = CARDOSSmartcard.new(self.hcard)
    self.cardos_hcard._mse_seid = "40"
    self.cfg = cfg or utility.parse_cfg()
    
    self.default_container_data_obj = "CSPSmartLogon"
    self.mechanisms = utility.clone_table(t.mechanisms)
    self.DF_CERTS = hexf("6000")
    self.DF_KEYS = hexf("4000")

  
end

function t.mt:finalize()
    log.output("token-ts:finalize():", self.session, self.userType)
end
    

function t.mt:begin_transaction()
    self.cardos_hcard:begin_transaction()
end

function t.mt:end_transaction()
    self.cardos_hcard:end_transaction()
end



function t.parse_object(d)
    local o = {}
    local obj1 = der.parse(d)
    local index
    if type(obj1[1]) == "table" and obj1[1].tag == der.INTEGER then
        if obj1[1].value == "\4" then
            log.output("Object type: PRIVATE KEY")
            o.type = utility.clone_table(obj1[1])
            o.algo = utility.clone_table(obj1[2])
            o.unk3 = utility.clone_table(obj1[3])
            o.kid = utility.clone_table(obj1[4])
            index=5
        elseif obj1[1].value == "\3" then
            log.output("Object type: CERTIFICATE")
            o.type = utility.clone_table(obj1[1])
            o.path = utility.clone_table(obj1[2])
            index=3
        end
        if index and obj1[index] and obj1[index].tag == der.SET then
            local attrs = der.parse(obj1[index].value)
            log.output("\tOBJECT ATTRIBUTES count:", table.getn(attrs))
            o.attributes = {}
            o.attributes_tag = obj1[index].tag
            for i=1,table.getn(attrs) do
                local v = attrs[i]
                if v.tag == der.SEQUENCE then
                    local attr = der.parse(v.value)
                    log.output("\tOBJECT ATTRIBUTE:", i, repr(attr))
                    if attr[1] and attr[1].tag == der.OID and attr[2] and attr[2].tag == der.STRING then
                        log.output("\tOBJECT ATTRIBUTE added:", i)
                        local a = {
                            ckatype = utility.clone_table(attr[1]),
                            ckaval = utility.clone_table(attr[2]),
                        }
                        table.insert(o.attributes, a)
                    end
                end
            end
            
        end
    end
    return o
end

function t.parse_card_infos(d)
-- SEQUENCE {
    -- INTEGER = 2 -- version?
    -- PRINTABLE STRING = "05040200 " -- AID
    -- PRINTABLE STRING -- SERIAL
    -- SEQUENCE{ -- creds infos
        -- SET{
            -- SEQUENCE{
                -- NUMERIC STRING = 'PIN'
                -- OCTET STRING = '01'
                -- INTEGER = 4 -- min len
                -- INTEGER = 8 -- max len
                -- NUMERIC STRING = 'PUK' -- unblocking object
            -- }
            -- SEQUENCE{
                -- NUMERIC STRING = 'PUK'
                -- OCTET STRING = '02'
                -- INTEGER = 1 -- min len
                -- INTEGER = 10 -- max len
            -- }
        -- }
    -- }
    -- SEQUENCE{
        -- OCTET STRING '4000'|'6000'|'7000'|'8000' -- RSA KEYS, CERTIFICATES, DATA OBJECT?, DATA OBJECTS?
        -- SET{
            -- SEQUENCE{ -- generic object structure
                -- INTEGER = 3 | 4
                -- OCTET STRING OPTIONAL = "0C" -- algo: 0x0C = RSA PURE
                -- INTEGER OPTIONAL = 3 -- ?
                -- OCTET STRING -- KID
                -- SET{ -- attributes
                    -- SEQUENCE {
                        -- OID -- CKA_*
                        -- OCTET STRING -- ATTR VALUE
                    -- } [0 .. N]
                -- }
                -- OCTET STRING OPTIONAL -- PATH OF ?
            -- }
        -- }
    -- }
-- }

    log.output("parse_card_infos", hex.hexify(d))
    local s = {}
    local level1 = der.parse(d)
    log.output("level1", repr(level1))
    assert (level1[1].tag == der.SEQUENCE)
    local level2 = der.parse(level1[1].value)
    log.output("level2", repr(level2))

    assert (level2[1].tag == der.INTEGER and level2[1].value == "\2")
    assert (level2[2].tag == der.PRINTABLESTRING and level2[2].value == hex.hexf("05040200"))
    assert (level2[3].tag == der.PRINTABLESTRING)
    assert (level2[4].tag == der.SEQUENCE)

    for i=1,table.getn(level2) do
        local v = level2[i]
        s.version = utility.clone_table(level2[1])
        s.aid = utility.clone_table(level2[2])
        s.serial = utility.clone_table(level2[3])
        s.creds = {}
        s.lists = {}
    end
    local level24 = der.parse(level2[4].value)
    log.output("level24", repr(level24))
    assert (level24[1].tag == der.SET)

    local level241 = der.parse(level24[1].value)
    log.output("level241", repr(level241))
    assert (level241[1].tag == der.SEQUENCE)
    assert (level241[2].tag == der.SEQUENCE)
    for i=1,table.getn(level241) do
        local v = level241[i]
        local level241x = der.parse(v.value)
        local cred
        if level241x[1].tag == der.NUMERICSTRING and level241x[1].value == "PIN" then
            cred = {}
            s.creds.pin = cred
        elseif level241x[1].tag == der.NUMERICSTRING and level241x[1].value == "PUK" then
            cred = {}
            s.creds.puk = cred
        end
        if cred then
            cred.id = level241x[2].value
            cred.min = string.byte(level241x[3].value, 1)
            cred.max = string.byte(level241x[4].value, 1)
        end
        if level241x[5] and level241x[5].tag == der.NUMERICSTRING then
            cred.unblock = level241x[5].value
        end
    end
    
    for i=5,table.getn(level2) do
        local v = level2[i]
        if v.tag == der.SEQUENCE then
            local objList = der.parse(v.value)
            if type(objList[1]) == "table"
                    and objList[1].tag == der.STRING then
                local curlist = {}
                s.lists[objList[1].value] = curlist
                
                if type(objList[2]) == "table" and objList[2].tag == der.SET then
                
                    log.output ("enum of list:", hex.hexify(objList[1].value))
                    local objSet = der.parse(objList[2].value)
                    for k=1,table.getn(objSet) do
                        local vo = objSet[k]
                        if vo.tag == der.SEQUENCE then
                            local obj = t.parse_object(vo.value)
                            table.insert(curlist, obj)
                        else
                            log.output("invalid object: not a sequence")
                        end
                    end
                end
            else
                log.output("invalid object list contents: not a table")
            end
        else
            log.output("invalid object list: not a sequence")
        end
    end
    return s
end

function t.mt:cardos_root_select(rpath)
    self.cardos_hcard:select_ex(hex.hexf("05040200"), 4)
    return self.cardos_hcard:select_ex(rpath, 9, true)
end

function t.mt:add_info_cardos()
    local max_objects = 1
    log.output("reading cardos informations...")
    -- cardos_info contiene le info sul FS di firma specifico della CARDOS 4.4
    self.info.serialNumber = "0000000000000001"
    
    log.output("selecting main file...")
    local finfos = self:cardos_root_select(hexf("0001"))
    local cardos_data_str = self.cardos_hcard:mread_binary(0, finfos.size)
    log.output("parsing main file...")
    self.cardos_info = t.parse_card_infos(cardos_data_str)
    print("parsing main file:", repr(self.cardos_info.lists))
    print("parsing main file:", repr(self.cardos_info.lists[self.DF_CERTS]))
    print("parsing main file:", repr(self.cardos_info.lists[self.DF_KEYS]))
    self.info.serialNumber = string.sub(self.cardos_info.serial.value, 1, 16)
    self.info.ulMinPinLen = self.cardos_info.creds.pin.min
    self.info.ulMaxPinLen = self.cardos_info.creds.pin.max
    log.output(string.format("TOKEN SN: '%s'", self.info.serialNumber or ""))
    
    self.cardos_hcard.PIN_PADDING = self.cardos_info.creds.pin.max
    self.cardos_hcard.PUK_PADDING = self.cardos_info.creds.puk.max
    self.cardos_hcard.BSO_CNS_PIN = string.byte(self.cardos_info.creds.pin.id, 1)
    self.cardos_hcard.BSO_CNS_PUK = string.byte(self.cardos_info.creds.puk.id, 1)

end

function t.mt:get_info()
    if not self.info then
        self.info = {
            label = 'Firma Sicura Telecom Italia',
            manufacturerID = 'Siemens',
            model = 'CardOS 4.4',
            serialNumber = nil,
            flags = CKF.RNG + CKF.LOGIN_REQUIRED + CKF.TOKEN_INITIALIZED,
            ulMaxSessionCount = CK.EFFECTIVELY_INFINITE,
            ulSessionCount = 0,
            ulMaxRwSessionCount = CK.EFFECTIVELY_INFINITE,
            ulRwSessionCount = CK.UNAVAILABLE_INFORMATION,
            ulMaxPinLen = self.cardos_hcard.PUK_PADDING or 8,
            ulMinPinLen = 1,
            ulTotalPublicMemory = 31988,
            ulFreePublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulTotalPrivateMemory = 780,
            ulFreePrivateMemory = CK.UNAVAILABLE_INFORMATION,
            hardwareVersion = { major=0, minor=0},
            firmwareVersion = { major=0, minor=0},
            utcTime = '0000000000000000'
        }
        
        self:add_info_cardos()
        self.info.flags = self.info.flags + CKF.USER_PIN_INITIALIZED
    
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
        result = self.cardos_hcard:verify_pin_main(pin, ispuk)
        log.output("verify_pin(): result=", result)
        if result == 0 then
            self.cached_main_pin = pin
            self.userType = userType
            self.cached_ds_pin = nil
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


function t.mt:unverify_pin()
    -- per il momento non fa niente, potrebbe essere configurata per il reset della carta, se necessario
    self.cached_main_pin = nil
    self.userType = nil
    self.cached_ds_pin = nil
end


function t.mt:change_pin(oldPin, newPin)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk
    ispuk = false
    local maxLen = self.cardos_info.creds.pin.max
    local minLen = self.cardos_info.creds.pin.min
    
    if self.userType == CKU.SO then
        ispuk = true
        maxLen = self.cardos_info.creds.puk.max
        minLen = self.cardos_info.creds.puk.min
    end
    local pcRes, result
    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-cardos44 change_pin(): oldPin:' .. oldPin, 'newPin:' .. newPin)
    log.output('token-cardos44 change_pin(): cambio pin MAIN...')
    
    if type(newPin) == "string" 
            and (string.len(newPin) > maxLen or string.len(newPin) < minLen)  then
        log.output('token-cardos44 change_pin(): len Invalid')
        return CKR.PIN_LEN_RANGE
    end
    
    self:cardos_root_select(self.DF_KEYS)
    pcRes, result = pcall(function() return self.cardos_hcard:change_pin_main(oldPin, newPin, ispuk) end)
    if result == 0 then
        self.cached_main_pin = newPin
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
    log.output('token-cardos44 reset_pin(): newPin:' .. newPin)
    log.output('token-cardos44 reset_pin(): reset pin MAIN...')
    if self.userType ~= CKU.SO then
        log.output('token-cardos44 reset_pin(): user not SO!')
        return CKR.FUNCTION_FAILED
    end
    local maxLen = self.cardos_info.creds.pin.max
    local minLen = self.cardos_info.creds.pin.min

    if type(newPin) == "string" 
            and (string.len(newPin) > maxLen or string.len(newPin) < minLen)  then
        log.output('token-cardos44 reset_pin(): len Invalid')
        return CKR.PIN_LEN_RANGE
    end
   
    self:cardos_root_select(self.DF_KEYS)
    pcRes, result = pcall(function() return self.cardos_hcard:reset_pin_main(self.cached_main_pin, newPin) end)
    
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
-- Funzioni per il recupero degli attributi
--=====================================================================================
-- Nella funzione seguente il parametro viene "onlysize" trascurato.
-- Il motivo 