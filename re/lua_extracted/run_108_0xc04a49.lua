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

function t.mt:add_cmg_objects(objects)
    local obj
    log.output('token-cmg:add_cmg_objects(): adding CMG objects...')
    if self.cmg_info then
        if self.cmg_info.cert_valid then
            log.output('token-cmg:add_cmg_objects(): adding CMG Sign Certificate...')
            obj = objCnsTmpl.GetCNSCertTemplate(t.mt.get_certificate)
            obj.iscmg=true
            obj.isds=true
            obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(true) 
            obj[CKA.ID] = OBJ_IDS.DS0_ID
            obj[CKA.LABEL] = OBJ_IDS.DS0_LABEL
            obj.path = self.cmg_info.ds_sig_cert_path
            objects.max_index = objects.max_index+1
            objects[ objects.max_index ] = obj
            log.output('token-cmg:add_cmg_objects(): added certificate:',
                objects.max_index,
                hex.hexify(obj[CKA.CLASS]))
        end
        -- if self.cmg_info.ca_cert_valid then
            -- log.output('token-cmg:add_cmg_objects(): adding CMG CA Certificate...')
            -- obj = objCnsTmpl.GetCNSCertTemplate(t.mt.get_certificate)
            -- obj.iscmg=true
            -- obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(true) 
            -- obj[CKA.ID] = OBJ_IDS.CA_ID
            -- obj[CKA.LABEL] = OBJ_IDS.CA_ID
            -- obj.path = self.cmg_info.ds_sig_path .. "C00E"
            -- objects.max_index = objects.max_index+1
            -- objects[ objects.max_index ] = obj
            -- log.output('token-cmg:add_cmg_objects(): added CA certificate:',
                -- objects.max_index,
                -- hex.hexify(obj[CKA.CLASS]))
        -- end
        if self.cmg_info.key_valid then
            log.output('token-cmg:add_cmg_objects(): adding CMG Sign Pub and Priv keys...')
            
            objects.max_index = objects.max_index+1
            local objPub = objCnsTmpl.GetCNSPubKeyTemplate(t.mt.get_public_key)
            objPub.iscmg = true
            objPub.isds = true
            objPub.path = self.cmg_info.ds_sig_path .. "2401"
            objPub.key_bits = 1024
            objPub[CKA.ID] = OBJ_IDS.DS0_ID
            objPub[CKA.LABEL] = OBJ_IDS.DS0_LABEL
            objects[ objects.max_index ] = objPub
            log.output('token-cmg:add_cmg_objects(): added pub key:',
                objects.max_index,
                hex.hexify(objPub[CKA.CLASS]))
            
            objects.max_index = objects.max_index+1
            local objPriv = objCnsTmpl.GetCNSPrivKeyTemplate(t.mt.get_public_key)
            objPriv.iscmg = true
            objPriv.isds = true
			objPriv.related_public_key = objPub.path
            objPriv.path = self.cmg_info.ds_sig_path
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
            log.output('token-cmg:add_cmg_objects(): added priv key:',
                objects.max_index,
                hex.hexify(objPriv[CKA.CLASS]))
        end
        
        
        if self.cmg_info.crypt_cert_valid then
            log.output('token-cmg:add_cmg_objects(): adding CMG Crypt Certificate...')
            obj = objCnsTmpl.GetCNSCertTemplate(t.mt.get_certificate)
            obj.iscmg=true
            obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(true)
            obj[CKA.ID] = OBJ_IDS.CMG1_ID
            obj[CKA.LABEL] = OBJ_IDS.CMG1_LABEL
            obj.path = self.cmg_info.p11_path_cert
            objects.max_index = objects.max_index+1
            objects[ objects.max_index ] = obj
            log.output('token-cmg:add_cmg_objects(): added certificate:',
                objects.max_index,
                hex.hexify(obj[CKA.CLASS]))
            
            objects.max_index = objects.max_index+1
            local objPub = objCnsTmpl.GetCNSPubKeyTemplate(t.mt.get_public_key)
            objPub.iscmg = true
            objPub.path = self.cmg_info.p11_path_keys .. "3f01"
            objPub.key_bits = 1024
            objPub[CKA.ID] = OBJ_IDS.CMG1_ID
            objPub[CKA.LABEL] = OBJ_IDS.CMG1_LABEL
            objects[ objects.max_index ] = objPub
            log.output('token-cmg:add_cmg_objects(): added pub key:',
                objects.max_index,
                hex.hexify(objPub[CKA.CLASS]))
            
            objects.max_index = objects.max_index+1
            local objPriv = objCnsTmpl.GetCNSPrivKeyTemplate(t.mt.get_public_key)
            objPriv.iscmg = true
			objPriv.related_public_key = objPub.path
            objPriv.path = self.cmg_info.p11_path_keys
            objPriv.kid = 1
            objPriv[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(true)
            objPriv.pso_dec = true
            objPriv.private=true
            objPriv.key_bits = 1024
            objPriv[CKA.ID] = OBJ_IDS.CMG1_ID
            objPriv[CKA.LABEL] = OBJ_IDS.CMG1_LABEL
            objPriv[CKA.PRIVATE] = eCK.BBOOL(objPriv.private)
            objPriv[CKA.DECRYPT] = eCK.BBOOL(true)
            objPriv[CKA.SIGN] = eCK.BBOOL(false)
            objects[ objects.max_index ] = objPriv
            log.output('token-cmg:add_cmg_objects(): added priv key:',
                objects.max_index,
                hex.hexify(objPriv[CKA.CLASS]))
        end
    end
end


function t.mt:add_cns_objects(objects)
    local obj
    log.output('token-cmg:add_cns_objects(): adding CNS-Like objects...')
    if self.cns_info then
        if self.cns_info.cert_valid then
            log.output('token-cmg:add_cns_objects(): adding CNS-Like Certificate...')
            obj = objCnsTmpl.GetCNSCertTemplate(t.mt.get_certificate)
            obj.iscns=true
            obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
            obj[CKA.ID] = OBJ_IDS.CMG0_ID
            obj[CKA.LABEL] = OBJ_IDS.CMG0_LABEL
            objects.max_index = objects.max_index+1
            objects[ objects.max_index ] = obj
            log.output('token-cmg:add_cns_objects(): added certificate:',
                objects.max_index,
                hex.hexify(obj[CKA.CLASS]))
        end
        if self.cns_info.key_valid then
            log.output('token-cmg:add_cns_objects(): adding CNS-Like Pub and Priv keys...')
            
            objects.max_index = objects.max_index+1
            local objPub = objCnsTmpl.GetCNSPubKeyTemplate(t.mt.get_public_key)
            objPub.iscns = true
            objPub.key_bits = 1024
            objPub[CKA.ID] = OBJ_IDS.CMG0_ID
            objPub[CKA.LABEL] = OBJ_IDS.CMG0_LABEL
            objects[ objects.max_index ] = objPub
            log.output('token-cmg:add_cns_objects(): added pub key:',
                objects.max_index,
                hex.hexify(objPub[CKA.CLASS]))
            
            objects.max_index = objects.max_index+1
            local objPriv = objCnsTmpl.GetCNSPrivKeyTemplate(t.mt.get_public_key)
            objPriv.iscns = true
            objPriv.pso_dec = true
            objPriv[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
            objPriv.kid = 1
			objPriv.related_public_key = objPub.path
            objPriv.private=true
            objPriv.key_bits = 1024
            objPriv[CKA.PRIVATE] = eCK.BBOOL(objPriv.private)
            objPriv[CKA.ID] = OBJ_IDS.CMG0_ID
            objPriv[CKA.LABEL] = OBJ_IDS.CMG0_LABEL
            objPriv[CKA.DECRYPT] = eCK.BBOOL(true)
            objPriv[CKA.SIGN] = eCK.BBOOL(true)
            objects[ objects.max_index ] = objPriv
            log.output('token-cmg:add_cns_objects(): added priv key:',
                objects.max_index,
                hex.hexify(objPriv[CKA.CLASS]))
        end
    end
end

function t.mt:get_objects()

    log.output('token-cmg:get_objects()')
    local info = self:get_info() -- carica le info sul filesystem in cache
    
    local objects = {
            min_index = 11001, -- primo indice disponibile
            max_index = 11000, -- valore dell'indice massimo (i valori intermedi possono anche essere nil)
        }

    self:add_cns_objects(objects)
    self:add_cmg_objects(objects)

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
    return self.cmg_hcard:valid()
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
        return {OBJ_IDS.CMG0_ID}
    elseif id_class == 'DS' then
        return {OBJ_IDS.DS0_ID}
    end
end

function t.mt:flush_cache()
    if self.cfg["xproc"] ~= "true" then
        return false
    end
    local changed, cache_id
    if self._cache_id == nil then
        log.output("token-cmg:flush_cache(): initializing _cache_id")
        changed, self._cache_id = utility.has_token_changed(self, "cache", 0)
        log.output("token-cmg:flush_cache(): initialize: _cache_id:", self._cache_id)
    end
    changed, cache_id = utility.has_token_changed(self, "cache", self._cache_id)
    if changed then
        log.output("token-cmg:flush_cache(): token has changed!")
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
_LOADED['token-eida'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- token-eida.lua
local EIDASmartcard = require 'EIDASmartcard'
local hex = require 'hex'
local hexf = hex.hexf
local der = require 'der'
local utility = require 'utility'
local repr = utility.repr

local emt = {
	OperationOk = 0, -- Report "operation success", generic, return 0
	OperationFailed = 1, -- Report "operation failed", generic, return 0

	PinIncorrect = 8, -- Report "PIN incorrect, retry?", return 1 if YES, 0 if NO
	PinLocked = 9,    -- Report "Smartcard locked", return 0
	PinDeactivated = 10, -- Report "Smartcard not yet activated", return 0

	PukIncorrect = 16, -- Report "PUK incorrect, retry?", return 1 if YES, 0 if NO
	PukLocked = 17, -- Report "PUK locked", return 0

    }
local MinKSize, MaxKSize = 1024, 2048
local t = {
    name = 'eida',
    mt = { },
    mechanisms = {
        [ CKM.RSA_PKCS_KEY_PAIR_GEN ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.GENERATE_KEY_PAIR},
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_X_509 ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.DECRYPT+CKF.SIGN},
    },
    eida_hcard = nil,
    -- le chiavi DS sono protette da un singolo PIN
    capabilities = { private_attributes_readable=false, always_authenticate_on_cert=false, },
    EIDASmartcard=EIDASmartcard,
}
t.mt.__index = t.mt


function t.mt:gui_show_pin_message(result, ispuk)
    local msgid = 0
    if result==2 and ispuk then msgid = emt.PukLocked
    elseif result==2 and not ispuk then msgid = emt.PinLocked
    elseif result==1 and ispuk then msgid = emt.PukIncorrect
    elseif result==1 and not ispuk then msgid = emt.PinIncorrect
    else
        return -1
    end
    local transactionDisabled = self.hcard:transactionsdisabled()
    self.hcard:disabletransactions(false)
    if transactionDisabled then
        self.hcard:endtransaction()
    else
        self.eida_hcard:end_transaction()
    end

    local res = w32.show_message(msgid)
    self.hcard:status() -- in caso di reset effettua una reconnect
    if transactionDisabled then
        self.hcard:begintransaction()
    else
        self.eida_hcard:begin_transaction()
    end
    self.hcard:disabletransactions(transactionDisabled)
    return res
end

                
function t.mt:gui_request_pin_ds()
    local transactionDisabled = self.hcard:transactionsdisabled()
    self.hcard:disabletransactions(false)

    if transactionDisabled then
        self.hcard:endtransaction()
    else
        self.eida_hcard:end_transaction()
    end
    
    local res, contextual_pin, cache_ds_pin = w32.request_pin_ds(self.check_box_visible)
    self.hcard:status() -- in caso di reset effettua una reconnect
    if transactionDisabled then
        self.hcard:begintransaction()
    else
        self.eida_hcard:begin_transaction()
    end
    self.hcard:disabletransactions(transactionDisabled)
    return res, contextual_pin, cache_ds_pin
end

function t.mt:initialize(cfg)
    log.output('token-eida:initialize():')
    local files = {}
    self.files = files
    files.CERTIFICATES = hexf("0006")

    self.capabilities = utility.clone_table(t.capabilities)
    self.eida_hcard = EIDASmartcard.new(self.hcard)
    self.eida_hcard.allow_6310_chained_responses = true
    self.eida_hcard.BSO_PIN = 1
    self.eida_hcard.BSO_PUK = 3
    self.mechanisms = utility.clone_table(t.mechanisms)

    
    self.slow_card = false
    self.userPinInitialized = true
    self.request_plugin_valid = w32.request_plugin_valid()
    self.cfg = cfg or utility.parse_cfg()
    
    -- master key: 4D49535452414C47454D504C55534D4B
    -- cifrata: 1DDDEDCAA0C3DB6E396C1F863EEF7ACCB41469A546C97420

    local mKey = sm.sm_ask_keys(10)  -- richiede la chiave #10, master key per cifratura chiavi
    local default_master_key
    self.eida_hcard.default_master_key_number = 1
    
    default_master_key = sm.des3_dec(mKey, hex.hexf('1DDDEDCAA0C3DB6E' .. '396C1F863EEF7ACCB41469A546C97420'))
    log.output('token-eida:initialize(): internal gcm decoded')
    self.eida_hcard.default_master_key_number = 1 -- MAIN master key
    log.output('token-eida:initialize(): using G-MK')
    
    self.eida_hcard.default_master_key1 = string.sub(default_master_key, 1, 8)
    self.eida_hcard.default_master_key2 = string.sub(default_master_key, 9, 16)
    log.output('token-eida:initialize(): decrypted key:', 
        hex.hexify(self.eida_hcard.default_master_key1),
        hex.hexify(self.eida_hcard.default_master_key2))
    
    default_master_key = nil
    mKey = nil
    collectgarbage() -- forza liberazione della memoria inutilizzata
    
    self.cfg["dspiniscnspin"] = self.cfg["ddspiniscnspin"] or self.cfg["dspiniscnspin"]
    
    self.cfg["dspinusegui"] = self.cfg["ddspinusegui"] or self.cfg["dspinusegui"]
    self.cfg["hidecachedspincheck"] = self.cfg["dhidecachedspincheck"] or self.cfg["hidecachedspincheck"]
    self.cfg["fcpr"] = self.cfg["fcpr"] or self.cfg["dfcpr"]
    self.cfg["xproc"] = self.cfg["xproc"] or self.cfg["dxproc"]
    
    -- se il plugin del PIN non 