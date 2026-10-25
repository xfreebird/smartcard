 per i buffer 2048 bit ci sono problemi!
        resp = self:TXchain(hex.hexf("002a8086"), hex.hexf("81") .. data)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end
        
        break
    until true
    
    if sw ~= hexf('9000') then
        error(EIDASmartcard.EIDASmartcardError.new(sw, 'pso_decrypt error' ), 2)
    end
    return string.sub(resp, 1, -3)
end

--[[
function EIDASmartcard.mt:generate_key_pair(id, use_sm)
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
        error(EIDASmartcard.EIDASmartcardError.new(sw, 'generate_key_pair error' ), 2)
    end
end

function EIDASmartcard.mt:update_binary(offset, data, use_sm)
    local apdu = hex.hexf('00D6%H%P', offset, data)
    local recv, sw
    recv =  self:sm_transmit(apdu, use_sm)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(EIDASmartcard.EIDASmartcardError.new(sw, 'update_binary Error'), 2)
    end
end


function EIDASmartcard.mt:mupdate_binary(offset, data, use_sm)
    local buffer_size = EIDASmartcard.MAX_TRANSMIT_BUFFER_SIZE
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


local function trim_pad_bn(data, padto)
    data = string.sub(data, -padto)
    data = string.rep("\000", padto - string.len(data)) .. data
    return data
end

function EIDASmartcard.mt:import_private_key(id, m, e, p, q, iq, dp, dq)
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
--]]

--[[
-- function test_apdus()
    local ctx, err = pcsc.establishcontext()
    local readers = ctx:listreaders()
    local card
    for i, reader_name in readers do
        print ("slot:", reader_name)
        local new_hcard, err = ctx:connect(reader_name, pcsc.SHARE_SHARED, pcsc.PROTOCOL_Tx)  
        print ("slot connect:", reader_name, new_hcard, err)
        if new_hcard
           and new_hcard:status()
           and new_hcard:status().atr == hex.hexf("3B7D96000080318065B0831100C883009000")
           then
            print ("found at slot:", reader_name)
            card = EIDASmartcard.new(new_hcard)
            break
        elseif new_hcard then
            print ("disconnecting from:", reader_name)
            new_hcard:disconnect()
        end
    end
    print ( util.repr(getmetatable(card)))
    local res
    card:begin_transaction()
    
    card:auto_perform_mutual_authenticate()
    
    res = card:verify_pin_main("123456", false, true, false)
    print("verify_pin_main result check:", res)
    
    res = card:verify_pin_main("123456", false, false, false)
    print("verify_pin_main result:", res)

    --~ res = card:verify_pin_main("123456", false, true, false)
    --~ print("verify_pin_main result check:", res)
    
    --~ res = card:verify_pin_main("123456", false, false, true)
    --~ print("verify_pin_main result SM:", res)

    --~ res = card:verify_pin_main("123456", true, true, true)
    --~ print("verify_pin_main PUK result SM check:", res)

    --~ res = card:verify_pin_main("123456", true, false, true)
    --~ print("verify_pin_main PUK result SM:", res)
    
    --~ res = card:verify_pin_main("123456", true, true, true)
    --~ print("verify_pin_main PUK result SM check:", res)

    --~ res = card:change_pin_main("123456", "123456", false, false)
    --~ print("change_pin_main PIN result:", res)

    --~ res = card:change_pin_main("123456", "123456", true, false)
    --~ print("change_pin_main PUK result:", res)

    --~ res = card:change_pin_main("123456", "123456", false, true)
    --~ print("change_pin_main PIN result SM:", res)

    --~ res = card:change_pin_main("123456", "123456", true, true)
    --~ print("change_pin_main PUK result SM:", res)

    --~ res = card:reset_pin_main("123456", "123456", true)
    --~ print("reset_pin_main result SM:", res)
    
    card:auto_perform_mutual_authenticate()
    
    card:generate_key_pair(3, true)
   
    local module, exponent = card:read_public_key(3, true)
   
    local signature = card:pso_cds("12345678901234567890", 3, nil, true)
    print("pso_cds result SM:", hex.hexify(signature))

    res = card:verify_pin_main("123456", false, false, false)
    print("verify_pin_main result:", res)
    
    local modulus = "e371f30170020c43f7f714bd0c73e1fb9f998d9c7bf53e9936029a585d24df93abcc1fe8ac8b3c830a2436e2ef6f9f8bd8d3510c5b81ec7f7d2b0391985a9f9ba8aae4eb32a7979b7d46dc28cb630376f8ac8638c0c8bf75fa33f44f2b9c0a08a9b7de86df96ca839f7a13f31d5acc4a1427f8387452e055b0367839f8cc5bf369f27d198ac8274ed2b2b041f524d30ef0d3ffb211f5acef67d1d02dbc75d189a29adde3c90b3b1cebaa1470f2123e01b5b5ee30ae69e0c7e45519459b0873976d9c441071788e34c5a3def887b36ff602ad6fd66ec002f7d378e226105fcaab23dc2915f96e4c6dcb8909f36af8d9b2f9052c73af1425f7f0ad7c68d38465cf"
    local pubExp = "010001"
    local prime1 = "fab02315e0e81562e3fa565700b3ca8313b22ccbca8b02f71a36f1d1207ee0f8fe24f3b072aebd400cdd49ad3f50571d7c0a016d7b9dc6adcedcb6844c5f36117d4cff6b233fc08dcfb2157bf341e2a831c6806bb3f105f9104b47313244a1bd6c0a4a0901ea4c8456053fb44129e1ab21e43e0e1050150b9feff8e3ce585b67"
    local prime2 = "e843bafdb7b5233a8b86dcdad84b3eb5ea2dc1cf3e5b279e0dad7e8c09a72033af378177b06c9f3faccc911402fc9a84e0dcf8fc237ecc393974ab10f2a5e212bd6ed88b9f41bd95dd42e2b57ffcf90349a99e819a36a2ffb7449e74f70a30acc4e8edd71aed169f654a0156f7b119e62ee5dff18424476a4ad4736bdffa0959"
    local coefficient = "dc38bf7ad4e835af27de639117cadc39503d7635bcfd56377bd3dcecd949164f9eed85fbc8ce604cc7628c211577a8121d7d8fbc155256cad01727ffbe90b4b09c07b5fa540fabd069041211e25f614c019fc5da7f80d4cd2314442f1d5ffbeb7243214544e441e765a8882c43467795dfc29caf2b58f80f905519bcf15073f0"
    local exponent1 = "7bd3cd40dd5b465516af6d3e84864a9dfc78a24ff7b83ababc242fc650fadb3da2abb6038e6269f0dd69e11ec68b74bc87ac998feee3bc63d62e87a949e02de0edb7bee2b902a0a66bd5576f667540f43bc205652df8fc2e4eb22074589436204ee1b63844cdeb05e347ac73e94c3ac04179707d99e934bc0d4087fc5ecc9e39"
    local exponent2 = "1abe41b79901784ef365d1e438e7610f1d29ab992b3adfb2e92c42d7e8fc9f4e942c35f20c1455b9c531c0baa72562bd4e0ee37454b9f2d5dbf1bd08b487b9222341b219517b06534d28b865e198c52b45be0c0c2c2f8251234ef957ca6217fcaca78d4b294487484f275844253cf51875e9ee01270fee5124d09581a4466bf1"

    card:import_private_key(3, hexf(modulus), 
            hexf(pubExp), 
            hexf(prime1),
            hexf(prime2),
            hexf(coefficient),
            hexf(exponent1),
            hexf(exponent2) )
    
    local module, exponent = card:read_public_key(3, true)
   
    local signature = card:pso_cds("12345678901234567890", 3, nil, true)
    print("pso_cds result SM:", hex.hexify(signature))
    
    
    local dec = rsa.decrypt(signature, hex.hexify(module), hex.hexify(exponent))
    print("dec signature:", hex.hexify(dec))

    local ACTUAL_DATA = hex.hexf("010f00000000")
    local encrypted_data = rsa.encrypt(ACTUAL_DATA, hex.hexify(module), hex.hexify(exponent))
    print("encrypted_data:", hex.hexify(encrypted_data))
    
    res = card:verify_pin_main("123456", false, false, false)
    print("verify_pin_main result:", res)
    
    local decrypted = card:pso_decrypt(encrypted_data, 3, true)
    print("decrypted:", hex.hexify(decrypted))
    card:end_transaction()
end
test_apdus()
]]--

return EIDASmartcard

--===========================================================================
end
}
_LOADED['token-cmd'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- token-cmd.lua
local CnsSmartcard = require 'CnsSmartcard'
local hex = require 'hex'
local hexf = hex.hexf
local der = require 'der'
local utility = require 'utility'
local rsa = require 'rsa'
local zlib = require 'zlib'

local objCnsTmpl = require 'token-cns-objects'

local OBJ_IDS = {
    CMD0_LABEL = 'CMD0',
    CMD0_ID = 'CMD0',
    CMD1_LABEL = 'CMD1',
    CMD1_ID = 'CMD1',
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
    name = 'cmd_milcard',
    mt = { },
    mechanisms = {
--        [ CKM.RSA_PKCS_KEY_PAIR_GEN ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.GENERATE_KEY_PAIR},
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_X_509 ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
    },
    cmd_hcard = nil,
    capabilities = { private_attributes_readable=true, always_authenticate_on_cert=true, },
}
t.mt.__index = t.mt


function t.mt:initialize(cfg)
    self.capabilities = utility.clone_table(t.capabilities)
    self.cmd_hcard = CnsSmartcard.new(self.hcard)
    self.cmd_hcard._mse_seid = "30"
    self.cmd_hcard.BSO_DS_PIN = 1
    self.cmd_hcard.BSO_DS_PUK = 10
   
    self.request_plugin_valid = w32.request_plugin_valid()
    self.cfg = cfg or utility.parse_cfg()
    self.cfg["dspiniscnspin"] = self.cfg["idspiniscnspin"] or self.cfg["dspiniscnspin"]
    self.cfg["dspinusegui"] = self.cfg["idspinusegui"] or self.cfg["dspinusegui"]
    self.cfg["dspinusepinpad"] = self.cfg["idspinusepinpad"] or self.cfg["dspinusepinpad"]
    
    self.cfg["hidecachedspincheck"] = self.cfg["ihidecachedspincheck"] or self.cfg["hidecachedspincheck"]
    
    -- se il plugin del PIN non 