 (p^-1 mod q) invece di (q^-1 mod p)
            -- formato chiave: p .. q .. dp .. dq .. ip
            abPrivKey = hexf("%B00%>%H%S%S%S%S%S%B%B",
                            to_sign and h2i("91") or h2i("93"),
                            string.len(rsaInfos.p),
                            rsaInfos.q,
                            rsaInfos.p,
                            rsaInfos.dq,
                            rsaInfos.dp,
                            rsaInfos.ip,
                            pubGroup or 255,
                            pubIndex or 255
                            )
        elseif rsaInfos.d and rsaInfos.n then
            rsaInfos.n = string.rep("\0", math.mod(string.len(rsaInfos.n), 4)) .. rsaInfos.n
            rsaInfos.d = string.rep("\0", string.len(rsaInfos.n) - string.len(rsaInfos.d)) .. rsaInfos.d
            abPrivKey = hexf("%B00%>%H%S%H%S%B%B",
                            to_sign and h2i("90") or h2i("92"),
                            string.len(rsaInfos.n),
                            rsaInfos.n,
                            string.len(rsaInfos.d),
                            rsaInfos.d,
                            pubGroup or 255,
                            pubIndex or 255
                            )
        end
        privData = hexf("00FF%B%B%>%H%S%H",
                        rsaInfos.bmDelete.asnumber, rsaInfos.bmExecute.asnumber,
                        string.len(abPrivKey),
                        abPrivKey,
                        Crc16_CCITT_1189(abPrivKey, 0)
                        )
    end
    local apdu, apdu1, apdu2
    
    if pubData then
    
        if string.len(pubData) > 255 then
            apdu = hexf("9047%B%B%P", pubGroup, pubIndex, string.sub(pubData,1, 255) )
            apdu1 = hexf("8047%B%B%P", pubGroup, pubIndex, string.sub(pubData,256, -1))
        else
            apdu = hexf("8047%B%B%P", pubGroup, pubIndex, pubData )
        end
        local recv = self:transmit(apdu)
        sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') and sw ~= hexf('6200') then
            error(SmartcardError.new(sw, 'put_rsa_key PUBLIC error' ), 2)
        end
        if apdu1 then
            recv = self:transmit(apdu1)
            sw = string.sub(recv, -2, -1)
            if sw ~= hexf('9000') then
                error(SmartcardError.new(sw, 'put_rsa_key PUBLIC1 error' ), 2)
            end
        end
    end
    
    if privData then
        if string.len(privData) > 255 then
            apdu  = hexf("9047%B%B%P", privGroup, privIndex, string.sub(privData,1, 255) )
            if string.len(privData) > 510 then
                apdu1 = hexf("9047%B%B%P", privGroup, privIndex, string.sub(privData,256, 510))
                apdu2 = hexf("8047%B%B%P", privGroup, privIndex, string.sub(privData,511, -1))
            else
                apdu1 = hexf("8047%B%B%P", privGroup, privIndex, string.sub(privData,256, 510))
            end
        else
            apdu = hexf("8047%B%B%P", privGroup, privIndex, privData )
        end
        local recv = self:transmit(apdu)
        sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') and sw ~= hexf('6200') then
            error(SmartcardError.new(sw, 'put_rsa_key PRIVATE error' ), 2)
        end
        if apdu1 then
            recv = self:transmit(apdu1)
            sw = string.sub(recv, -2, -1)
            if sw ~= hexf('9000') and sw ~= hexf('6200') then
                error(SmartcardError.new(sw, 'put_rsa_key PRIVATE1 error' ), 2)
            end
            if apdu2 then
                recv = self:transmit(apdu2)
                sw = string.sub(recv, -2, -1)
                if sw ~= hexf('9000') then
                    error(SmartcardError.new(sw, 'put_rsa_key PRIVATE2 error' ), 2)
                end
            end
        end
    end
end


return Smartcard

--===========================================================================
end
}
_LOADED['token-p11-objects'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- questo file deve essere incluso solo in 'token.-cns.lua'

local t = {}

function t.GetP11CertTemplate(populateCertFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.CERTIFICATE),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(true),
        [ CKA.LABEL ] = populateCertFunc,
        -- Certificate
        [ CKA.CERTIFICATE_TYPE ] = eCK.CERTIFICATE_TYPE(CKC.X_509),
        [ CKA.TRUSTED ] = eCK.BBOOL(true),
        [ CKA.CERTIFICATE_CATEGORY ] = eCK.ULONG(1), -- user
        -- [ CKA.CHECK_VALUE ] = '',
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        -- Certificate X.509
        [ CKA.SUBJECT ] = populateCertFunc,
        [ CKA.ID ] = populateCertFunc,
        [ CKA.ISSUER ] = populateCertFunc,
        [ CKA.SERIAL_NUMBER ] = populateCertFunc,
        [ CKA.VALUE ] = populateCertFunc,
        [ CKA.URL ] = '',
        [ CKA.HASH_OF_SUBJECT_PUBLIC_KEY ] = '',
        [ CKA.HASH_OF_ISSUER_PUBLIC_KEY ] = '',
        [ CKA.JAVA_MIDP_SECURITY_DOMAIN ] = eCK.ULONG(0),
    }
end

function t.GetP11PubKeyTemplate(populateKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PUBLIC_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(true),
        [ CKA.LABEL ] = populateKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = populateKeyFunc,
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = eCK.BBOOL(false),
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
        [ CKA.MODULUS ] = populateKeyFunc,
        [ CKA.MODULUS_BITS ] = populateKeyFunc,
        [ CKA.PUBLIC_EXPONENT ] = populateKeyFunc,
    }
end

function t.GetP11PrivKeyTemplate(populateKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PRIVATE_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(true),
        [ CKA.LABEL ] = populateKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = populateKeyFunc,
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = eCK.BBOOL(true),
        [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.RSA_PKCS_KEY_PAIR_GEN),
        -- [ CKA.ALLOWED_MECHANISMS ] = '',
        -- Private Key
        [ CKA.SUBJECT ] = '',
        [ CKA.SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.DECRYPT ] = eCK.BBOOL(true),
        [ CKA.SIGN ] = eCK.BBOOL(true),
        [ CKA.SIGN_RECOVER ] = eCK.BBOOL(false),
        [ CKA.UNWRAP ] = eCK.BBOOL(false),
        [ CKA.EXTRACTABLE ] = eCK.BBOOL(false),
        [ CKA.ALWAYS_SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.NEVER_EXTRACTABLE ] = eCK.BBOOL(true),
        [ CKA.WRAP_WITH_TRUSTED ] = eCK.BBOOL(false),
        -- [ CKA.UNWRAP_TEMPLATE ] = '',
        [ CKA.ALWAYS_AUTHENTICATE ] = eCK.BBOOL(false),
        -- RSA Private Key
        [ CKA.MODULUS ] = populateKeyFunc,
        [ CKA.MODULUS_BITS ] = populateKeyFunc,
        [ CKA.PUBLIC_EXPONENT ] = populateKeyFunc,
        [ CKA.PRIVATE_EXPONENT ] = -1,
        [ CKA.PRIME_1 ] = -1,
        [ CKA.PRIME_2 ] = -1,
        [ CKA.EXPONENT_1 ] = -1,
        [ CKA.EXPONENT_2 ] = -1,
        [ CKA.COEFFICIENT ] = -1,
    }
end

function t.GetP11DataTemplate(populateKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.DATA),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(true),
        [ CKA.LABEL ] = populateKeyFunc,
        -- Data
        [ CKA.VALUE ] = populateKeyFunc,
        [ CKA.APPLICATION ] = populateKeyFunc,
        [ CKA.OBJECT_ID ] = populateKeyFunc,
    }
end

return t

--===========================================================================
end
}
_LOADED['token-ts'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- pcsc-token-cns.lua
local CnsSmartcard = require 'CnsSmartcard'
local hex = require 'hex'
local hexf = hex.hexf
local der = require 'der'
local utility = require 'utility'
local rsa = require 'rsa'
local zlib = require 'zlib'
local rsa = require 'rsa'
local hmac = require 'hmac'
local ecdhlib = require 'ecdhlib'
local repr = utility.repr
local CnsSmartcardCommon = require 'CnsSmartcardCommon'
local CnsSmartcardError = CnsSmartcardCommon.CnsSmartcardError

local licensing = require 'licensing'

local objCnsTmpl = require 'token-cns-objects'
local objP11Tmpl = require 'token-p11-objects'

local CKO_PIN_POLICY = tonumber("80001000", 16)

local OBJ_IDS = {
    PDATA_LABEL = 'PDATA',
    CNS0_LABEL = 'CNS0',
    CNS0_ID = 'CNS0',
    DS_LABEL = 'DS',
    DS_ID = 'DS',
    DSX_ID = 'DX#',
    DSX_LABEL = 'DX#',
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

local objTypes = {
	ePubKey = 0,
	ePrivKey = 1,
	eCert = 2,
	eSymKey = 3,
	eData = 4,
	ePrivECC =6,
	ePubECC = 7,
	-- ePrivEdDSA =8,
	-- ePubEdDSA = 9,
	-- ePrivMONTGOMERY = 10,
	-- ePubMONTGOMERY = 11,
    -- eAES = 12,
    -- eDES = 13
    -- eRFU1=14,
    -- eMAX=15,
}
local attrTypes = {
	eMain = 0,
	eLabel = 1,
	eID = 2,
	eSubject = 3,
	eIssuer = 4,
	eSN = 5,
	eModulus = 6,
	ePubExp = 7,
	eValue = 8,
	ePubKeyModExp = 8,
	eApplication = 9,
	eObjectId = 10,
    -- eMAx=15,
}

local pubkey_bitfields = {
    MODIFIABLE = bin.flags(1),
	PRIVATE = bin.flags(2),
	DERIVE = bin.flags(4),
	LOCAL = bin.flags(8),
	TRUSTED = bin.flags(16),
	ENCRYPT = bin.flags(32),
	VERIFY = bin.flags(64),
	VERIFY_RECOVER = bin.flags(128),
    WRAP = bin.flags(256),
}

local privkey_bitfields = {
    MODIFIABLE = bin.flags(1),
	PRIVATE = bin.flags(2),
	DERIVE = bin.flags(4),
	LOCAL = bin.flags(8),
	DECRYPT = bin.flags(16),
	SIGN = bin.flags(32),
	SIGN_RECOVER = bin.flags(64),
	UNWRAP = bin.flags(128),
}

local cert_data_bitfields = {
    MODIFIABLE = bin.flags(1),
	PRIVATE = bin.flags(2),
	TRUSTED = bin.flags(4),
}

local MinKSize, MaxKSize = 1024, 1024
local DS_FS_VERSION_2_0 = tonumber('20', 16)

local t = {
    name = 'incardts',
    mt = { },
    mechanisms = {
        [ CKM.RSA_PKCS_KEY_PAIR_GEN ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.GENERATE_KEY_PAIR},
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_PKCS_PSS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.SIGN},
        [ CKM.RSA_X_509 ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_PKCS_OAEP ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT},
    },
    cns_hcard = nil,
    capabilities = { private_attributes_readable=false, always_authenticate_on_cert=true, },
}
t.mt.__index = t.mt

function t.mt:initialize(cfg)

    self.p11_bso_start_index_1024 = tonumber('21', 16)
    self.p11_bso_start_index_2048 = tonumber('41', 16)



    self.keygenmaxtryonlow1024 = 20
    self.keygenmaxtryonlow2048 = 20
    self.keygenerroronlow = true
    self.capabilities = utility.clone_table(t.capabilities)
    self.cns_hcard = CnsSmartcard.new(self.hcard)
    self.request_plugin_valid = w32.request_plugin_valid()
    self.use_cpr_mode = true
    self.cfg = cfg or utility.parse_cfg()
    self.cfg["dspiniscnspin"] = self.cfg["idspiniscnspin"] or self.cfg["dspiniscnspin"]
    self.cfg["dspinusegui"] = self.cfg["idspinusegui"] or self.cfg["dspinusegui"]
    self.cfg["hidecachedspincheck"] = self.cfg["ihidecachedspincheck"] or self.cfg["hidecachedspincheck"]
    self.cfg["fcpr"] = self.cfg["fcpr"] or self.cfg["ifcpr"]
    self.cfg["fcpr2"] = self.cfg["fcpr2"] or self.cfg["ifcpr2"]
    
    self.cfg["xproc"] = self.cfg["xproc"] or self.cfg["ixproc"]
    
    -- se il plugin del PIN non 