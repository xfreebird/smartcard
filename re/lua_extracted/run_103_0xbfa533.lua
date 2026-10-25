 per i buffer 2048 bit ci sono problemi!
        resp = self:TXchain(hex.hexf("002a8086"), hex.hexf("81") .. data)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end
        
        break
    until true
    
    if sw ~= hexf('9000') then
        error(IasEccSmartcard.IasEccSmartcardError.new(sw, 'pso_decrypt error' ), 2)
    end
    return string.sub(resp, 1, -3)
end

function IasEccSmartcard.mt:generate_key_pair(id, use_sm)
    -- TODO
    local sw, resp
    if id == nil then id = '3'
    elseif type(id) == 'number' then 
        id = hex.hexify(hex.hexf('%B', id))
    elseif string.len(id) == 1 then 
        id = hex.hexify(id)
    end
    local generate = "004602" .. id .. "087f49058203010001"
    generate = hex.hexf(generate)
    resp = self:sm_transmit(generate, use_sm)
    sw = string.sub(resp, -2, -1)
    if sw ~= hexf('9000') then
        error(IasEccSmartcard.IasEccSmartcardError.new(sw, 'generate_key_pair error' ), 2)
    end
end


function IasEccSmartcard.mt:update_binary(offset, data, use_sm)
-- TODO: check
    local apdu = hex.hexf('00D6%H%P', offset, data)
    local recv, sw
    recv =  self:sm_transmit(apdu, use_sm)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(IasEccSmartcard.IasEccSmartcardError.new(sw, 'update_binary Error'), 2)
    end
end


function IasEccSmartcard.mt:mupdate_binary(offset, data, use_sm)
-- TODO: check
    local buffer_size = IasEccSmartcard.MAX_TRANSMIT_BUFFER_SIZE
    local left = string.len(data)
    local curOffset = offset
    local chunk
    while left > 0 do
        chunk = string.sub(data, curOffset-offset+1, curOffset-offset + buffer_size)
        if chunk == 0 then
            log.output("mupdate_binary(): WARNING: specified data len is not enough?")
            break
        end
        self:update_binary(curOffset, chunk, use_sm)
        left = left - string.len(chunk)
        curOffset = curOffset + string.len(chunk)
    end
end



function IasEccSmartcard.mt:import_private_key(id, m, e, p, q, iq, dp, dq)
    -- TODO: check
    local resp, padto
    if id == nil then id = '3'
    elseif type(id) == 'number' then 
        id = hex.hexify(hex.hexf('%B', id))
    elseif string.len(id) == 1 then 
        id = hex.hexify(id)
    end
    id = tonumber(id, 16)
    
    if type(m) == "number" then
        padto = m -- specifica solo la lunghezza del modulo
        m = nil
    elseif type(m) == "string" then
    
        if string.len(m) < 256 then
            m = trim_pad_bn(m, 128) -- taglia a 1024 bit
        else
            m = trim_pad_bn(m, 256) -- taglia a 2048 bit
        end
        padto = string.len(m) / 2        
    end
    assert(e == nil or string.len(e) < 8)

    local headerUpdate = hexf("00db00ffff")
    if m then
        local updateModulus = hexf2("b6038301 %B 7f49 82%H 81 82%H",
                                    id, 4 + string.len(m), string.len(m)) .. m
        resp = self:sm_transmit(headerUpdate .. updateModulus, true)
        self.last_sw = string.sub(resp, -2, -1)
        assert(self.last_sw == hexf("9000") )
    end
    if e then
        local updateExponent = hexf2("b6038301 %B 7f49 82%H 82 82%H", 
                                    id, 4 + string.len(e), string.len(e)) .. e
        resp = self:sm_transmit(headerUpdate .. updateExponent, true)
        self.last_sw = string.sub(resp, -2, -1)
        assert(self.last_sw == hexf("9000") )    
    end
    
    if p then
        p = trim_pad_bn(p, padto)
        local updateP = hexf2("B6038401 %B 7F 48 82%H 92 82%H ",
                                    id, 4 + string.len(p), string.len(p)) .. p
        resp = self:sm_transmit(headerUpdate .. updateP, true)
        self.last_sw = string.sub(resp, -2, -1)
        assert(self.last_sw == hexf("9000") )
    end
    
    if q then
        q = trim_pad_bn(q, padto)
        local updateQ  = hexf2("b6038401 %B 7F48 82%H 93 82%H ",
                                    id, 4 + string.len(q), string.len(q)) .. q
        resp = self:sm_transmit(headerUpdate .. updateQ, true)
        self.last_sw = string.sub(resp, -2, -1)
        assert(self.last_sw == hexf("9000") )
    end
    
    if iq then
        iq = trim_pad_bn(iq, padto)
        local updateIQ = hexf2("B6038401 %B 7F48 82%H 94 82%H ",
                                    id, 4 + string.len(iq), string.len(iq)) .. iq
        resp = self:sm_transmit(headerUpdate .. updateIQ, true)
        self.last_sw = string.sub(resp, -2, -1)
        assert(self.last_sw == hexf("9000") )
    end
    
    if dp then
        dp = trim_pad_bn(dp, padto)
        local updateDP = hexf2("B6038401 %B 7F48 82%H 95 82%H ",
                                    id, 4 + string.len(dp), string.len(dp)) .. dp
        resp = self:sm_transmit(headerUpdate .. updateDP, true)
        self.last_sw = string.sub(resp, -2, -1)
        assert(self.last_sw == hexf("9000") )
    end
    
    if dq then
        dq = trim_pad_bn(dq, padto)
        local updateDQ = hexf2("B6038401 %B 7F48 82%H 96 82%H ",
                                    id, 4 + string.len(dq), string.len(dq)) .. dq
        resp = self:sm_transmit(headerUpdate .. updateDQ, true)
        self.last_sw = string.sub(resp, -2, -1)
        assert(self.last_sw == hexf("9000") )
    end
    
end

return IasEccSmartcard

--===========================================================================
end
}
_LOADED['token-cmg'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- token-cmg.lua
local CnsSmartcard = require 'CnsSmartcard'
local hex = require 'hex'
local hexf = hex.hexf
local der = require 'der'
local utility = require 'utility'
local rsa = require 'rsa'
local zlib = require 'zlib'

local objCnsTmpl = require 'token-cns-objects'

local OBJ_IDS = {
    CMG0_LABEL = 'CNS0',
    CMG0_ID = 'CNS0',
    CMG1_LABEL = 'CMG1',
    CMG1_ID = 'CMG1',
    DS0_LABEL = 'DS0',
    DS0_ID = 'DS0',
}

local emt = {
	OperationOk = 0, -- Report "operation success", generic, return 0
	OperationFailed = 1, -- Report "operation failed", generic, return 0

	PinIncorrect = 8, -- Report "PIN incorrect, retry?", return 1 if YES, 0 if NO
	PinLocked = 9,    -- Report "Smartcard locked", return 0
	PinDeactivated = 10, -- Report "Smartcard not yet activated", return 0

	PukIncorrect = 16, -- Report "PUK incorrect, retry?", return 1 if YES, 0 if NO
	PukLocked = 17, -- Report "PUK locked", return 0

    }
local MinKSize, MaxKSize = 1024, 1024

local t = {
    name = 'cmg',
    mt = { },
    mechanisms = {
--        [ CKM.RSA_PKCS_KEY_PAIR_GEN ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.GENERATE_KEY_PAIR},
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_X_509 ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
    },
    cmg_hcard = nil,
    capabilities = { private_attributes_readable=true, always_authenticate_on_cert=true, },
}
t.mt.__index = t.mt


function t.mt:initialize(cfg)
    self.capabilities = utility.clone_table(t.capabilities)
    self.cmg_hcard = CnsSmartcard.new(self.hcard)
    self.cmg_hcard._mse_seid = "30"
    self.cmg_hcard.BSO_DS_PIN = 1
    self.cmg_hcard.BSO_DS_PUK = 10
   
    self.request_plugin_valid = w32.request_plugin_valid()
    self.cfg = cfg or utility.parse_cfg()
    
    self.cfg["dspiniscnspin"] = self.cfg["cmgdspiniscnspin"] or self.cfg["dspiniscnspin"]
    self.cfg["dspinusegui"] = self.cfg["cmgdspinusegui"] or self.cfg["dspinusegui"]
    self.cfg["dspinusepinpad"] = self.cfg["cmgdspinusepinpad"] or self.cfg["dspinusepinpad"]
    
    self.cfg["hidecachedspincheck"] = self.cfg["cmghidecachedspincheck"] or self.cfg["hidecachedspincheck"]
    
    if self.cfg["cmgmk"] then
        -- todo: decrypt
    else
        self.cfg["cmgmk"] =  "112233445566778888" .. "776655443322" .. "111122334455667788"
        self.cfg["mkdemo"] = "true"
    end
    
    pcall(function()
        local mk = hex.hexf(self.cfg["cmgmk"])
        self.cmg_mk1 = string.sub(mk, 1, 14)
        self.cmg_mk2 = string.sub(mk, 15, -1)
    end)
    
    -- se il plugin del PIN non 