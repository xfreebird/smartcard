_LOADED['token-p11wrap'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- pcsc-token-cns.lua
local hex = require 'hex'
local hexf = hex.hexf
local p11_util = {}
local utility = require 'utility'
local repr = utility.repr
local CnsSmartcard = require "CnsSmartcard"

local StarCosSKP23SmartcardLite = {}
StarCosSKP23SmartcardLite.mt = {}
StarCosSKP23SmartcardLite.mt.__index = StarCosSKP23SmartcardLite.mt

function StarCosSKP23SmartcardLite.new(card)
    local self = {}
    self.card = card
    setmetatable(self, StarCosSKP23SmartcardLite.mt)
    return self
end

function StarCosSKP23SmartcardLite.mt:transmit(apdu)
    local header, data = string.sub(apdu, 1, 4), string.sub(apdu, 6)
    if string.len(apdu) <= 5 then -- APDU con il solo LE
        header, data = apdu, nil
    end
    local result, scarderr = self.card:transmit(apdu)
    if not result then
        error(string.format('transmit error: 0x%x', scarderr))
    end
    self.last_sw = string.sub(result, -2, -1)
    return result
end

function StarCosSKP23SmartcardLite.mt:select(path, relative)
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
            error('select Error')
        end
    end
end

local MinKSize, MaxKSize = 1024, 4096

local t = {
    name = 'p11wrap',
    mt = { },
    mechanisms = {
        [ CKM.RSA_PKCS_KEY_PAIR_GEN ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.GENERATE_KEY_PAIR},
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_PKCS_PSS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.SIGN},
        [ CKM.RSA_PKCS_OAEP ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT},
        
        [ CKM.EC_KEY_PAIR_GEN ] = {ulMinKeySize=256, ulMaxKeySize=521, flags=CKF.HW+CKF.GENERATE_KEY_PAIR+CKF.EC_OID+CKF.EC_F_P+CKF.EC_UNCOMPRESS},
        [ CKM.ECDSA ] = {ulMinKeySize=256, ulMaxKeySize=521, flags=CKF.HW+CKF.SIGN+CKF.EC_OID+CKF.EC_F_P+CKF.EC_UNCOMPRESS},
    
        [ CKM.SHA1_RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.SIGN },
        p11wrap=true,
    },
    p11wrap_util=p11_util,
}
t.mt.__index = t.mt

-- nota: ogni libreria possiede una lista di possibili nomi
-- con cui 