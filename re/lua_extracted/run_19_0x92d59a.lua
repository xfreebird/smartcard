 "0"
    
    local f1 = {}
    local unused = string.byte(kuf, 1)
    local kufdata = string.sub(kuf, 2)
    local count = string.len(kufdata)
    local numbits = count*8 - unused
    local numbitsMAX = count*8
    local kufdataPadded = string.sub(string.rep("\000", 4-count) .. kufdata, -4, -1)
    local f = bin.unpack("%>%L", kufdataPadded)
    local ff = bin.flags(f)
    local n = bin.flags(2^(numbitsMAX-1))
    -- print (count, numbits, numbitsMAX, f, ff, n)
    
    for i=1,numbits do
        if type(pin_flags[i]) == "string" then
            f1[pin_flags[i]] = ff[n]
        end
        ff = bin.flags(ff.asnumber * 2) -- esegue << 1
    end
    return f1
end


--[[
function t.reduce_bit_string(bs, max_bit)
    local unused = 0
    local ff = bin.flags(bs)
    for i=0,max_bit do
        if not ff[bin.flags(2^i)] then
            unused = unused+1
        else
            break
        end
    end
    print (ff)
    print("unused:", unused)
    local result
    
    if unused < 8 then
        result = ff.asnumber * (2^(max_bit-)
        print("result2:", result)
        result= hex.hexf("%B%H", unused, result)
    else
        
        result = ff.asnumber * (2^unused)
        print("result1:", result)
        result= hex.hexf("%B%B", unused, result)
    end
    print("result:", hex.hexify(result))
    return result
end
]]--

--[[
function testme()
    function str_cka(id)

        for i, v in CKA do
        
            if v == id then
                return i
            end
        end
        return "unknown" .. id
    end


    for i, v in t.decode_KeyUsageFlags(hex.hexf("0274")) do
        if v == eCK.BBOOL(true) then 
            print (str_cka(i), hex.hexify(v))
        end
    end
    print("")

    for i, v in t.decode_KeyUsageFlags(t.encode_KeyUsageFlags(t.decode_KeyUsageFlags(hex.hexf("0274")))) do
        if v == eCK.BBOOL(true) then 
            print (str_cka(i), hex.hexify(v))
        end
    end
    print("")

    for i, v in t.decode_KeyAccessFlags(hex.hexf("04B0")) do
        if v == eCK.BBOOL(true) then 
            print (str_cka(i), hex.hexify(v))
        end
    end
    print("")

    for i, v in t.decode_KeyAccessFlags(t.encode_KeyAccessFlags(t.decode_KeyAccessFlags(hex.hexf("04B0")))) do
        if v == eCK.BBOOL(true) then 
            print (str_cka(i), hex.hexify(v))
        end
    end
    
    print("")
    
    for i, v in t.decode_PinFlags(hex.hexf("048C10")) do
        if v then print (i, v) end
    end
    print("")

    for i, v in t.decode_PinFlags(t.encode_PinFlags(t.decode_PinFlags(hex.hexf("048C10")))) do
        if v then print (i, v) end
    end
    
    print("")
    
    
    for i, v in t.decode_CommonFlags(hex.hexf("0640")) do
        if v == eCK.BBOOL(true) then 
            print (str_cka(i), hex.hexify(v))
        end
    end
    print("")

    for i, v in t.decode_CommonFlags(t.encode_CommonFlags(t.decode_CommonFlags(hex.hexf("0640")))) do
        if v == eCK.BBOOL(true) then 
            print (str_cka(i), hex.hexify(v))
        end
    end
    

    local pf = t.decode_PinFlags(hex.hexf("048C10")) 
    pf.initialized = false
    print("")
    
    print("reencoded", hex.hexify(t.encode_PinFlags(pf)))
    for i, v in t.decode_PinFlags(t.encode_PinFlags(pf)) do
        if v then print (i, v) end
    end
    print("")
    
end
-- testme()


function test2()

    -- JCOP3 IAS ECC sample, public KD 
    local value = hex.hexf("A15730220C1947656E6572696320446F6D61696E20506172616D6574657273030205000201013027041947656E6572696320446F6D61696E20506172616D657465727303030600000302030002010EA108300630040402000E3081AE307A0C09415554482D31303234030205403069300703030580000500300E0303051000300703020420020103300E0303054000300703020420020103300E0303052000300703020420020103300E0303050200300703020420020103300E0303050040300703020420020103300E030305008030070302042002010330170409415554482D313032340303068A0003020308020101A0093007A0050303070000A10C300A300404020001020204003081BC30770C03445333030205400201013069300703030580000500300E0303051000300703020420020103300E0303054000300703020420020103300E0303052000300703020420020103300E0303050200300703020420020103300E0303050040300703020420020103300E0303050080300703020420020103301104034453330303068A4003020308020111A0093007A0050303070000A1233021301BA2194F0EE828BD080FD2504543432D6549440401110404DF01001102020800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")
    local pubKD = t.parsePubPrivKD(value)
    for i, v in pubKD do
        for x, y in v do
            print(x, util.repr(y))
        end
        print ("")
    end

    local value2 = t.buildPubPrivKD(pubKD, {subClassAttributes={}})
    print("value:", hex.hexify(value))
    print("value2:", hex.hexify(value2))
    local expected = hex.hexf("A15730220C1947656E6572696320446F6D61696E20506172616D6574657273030205000201013027041947656E6572696320446F6D61696E20506172616D657465727303030600000302030002010EA108300630040402000E3081AE307A0C09415554482D31303234030205403069300703030580000500300E0303051000300703020420020103300E0303054000300703020420020103300E0303052000300703020420020103300E0303050200300703020420020103300E0303050040300703020420020103300E030305008030070302042002010330170409415554482D313032340303068A0003020308020101A0093007A0050303070000A10C300A300404020001020204003081BC30770C03445333030205400201013069300703030580000500300E0303051000300703020420020103300E0303054000300703020420020103300E0303052000300703020420020103300E0303050200300703020420020103300E0303050040300703020420020103300E0303050080300703020420020103301104034453330303068A4003020308020111A0093007A0050303070000A1233021301BA2194F0EE828BD080FD2504543432D6549440401110404DF01001102020800")
    assert(expected == value2)


    -- JCOP3 IAS ECC sample, Private KD
    local value = hex.hexf("3081AE3081840C09415554482D31303234030205C00408436172642050494E3069300703030580000500300E03030540003007030204A0020103300E0303051000300703020420020103300E0303052000300703020420020103300E0303050400300703020420020103300E0303050040300703020420020103300E030305010030070302042002010330170409415554482D313032340303062400030203E8020101A10C300A300404020001020204003081BB3081800C03445333030205C004075369672050494E0201013069300703030580000500300E03030540003007030204A0020103300E0303051000300703020420020103300E0303052000300703020420020103300E0303050400300703020420020103300E0303050040300703020420020103300E0303050100300703020420020103301104034453330303062440030203E8020111A1233021301BA2194F0EE828BD080FD2504543432D6549440401110404DF01001102020800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")
    local pubKD = t.parsePubPrivKD(value)
    for i, v in pubKD do
        for x, y in v do
            print(x, util.repr(y))
        end
        print ("")
    end

    local value2 = t.buildPubPrivKD(pubKD, {subClassAttributes={}})
    print("value:", hex.hexify(value))
    print("value2:", hex.hexify(value2))
    local expected = hex.hexf("3081AE3081840C09415554482D31303234030205C00408436172642050494E3069300703030580000500300E03030540003007030204A0020103300E0303051000300703020420020103300E0303052000300703020420020103300E0303050400300703020420020103300E0303050040300703020420020103300E030305010030070302042002010330170409415554482D313032340303062400030203E8020101A10C300A300404020001020204003081BB3081800C03445333030205C004075369672050494E0201013069300703030580000500300E03030540003007030204A0020103300E0303051000300703020420020103300E0303052000300703020420020103300E0303050400300703020420020103300E0303050040300703020420020103300E0303050100300703020420020103301104034453330303062440030203E8020111A1233021301BA2194F0EE828BD080FD2504543432D6549440401110404DF01001102020800")
    assert(expected == value2)

    -- JCOP3 IAS ECC sample
    local value = hex.hexf("30820114303A0C09415554482D31303234030205403029300703030580000500300E0303054000300703020420020103300E0303051000300703020420020103300E0409415554482D31303234010100A0020500A181C13081BE30040402001D304B312A30280603550403132141757468656E7469636174696F6E204365727469666963617465202D20434E5330311D301B06092A864886F70D010901160E7465737440656D61696C2E636F6DA0533051310B3009060355040613024954310F300D060355040813064E61706F6C69310F300D060355040713064E61706F6C69310F300D060355040A1306426974346964310F300D06035504031306426974346964021400E68A57C353F6E2EAB97DC38E8A25160F4D25FB3082010830340C03445333030205403029300703030580000500300E0303054000300703020420020103300E030305100030070302042002010330080403445333010100A0020500A181C13081BE30040402001C304C312B3029060355040313224469676974616C5369676E6174757265204365727469666963617465202D20445333311D301B06092A864886F70D010901160E7465737440656D61696C2E636F6DA0533051310B3009060355040613024954310F300D060355040813064E61706F6C69310F300D060355040713064E61706F6C69310F300D060355040A1306426974346964310F300D060355040313064269743469640213531895F5583C682AE5F282034608C6C3924168")
    local pubKD = t.parseCertDF(value)
    for i, v in pubKD do
        for x, y in v do
            print(x, util.repr(y))
        end
        print ("")
    end

    local value2 = t.buildCertDF(pubKD)
    print("value:", hex.hexify(value))
    print("value2:", hex.hexify(value2))
    assert(value == value2)

end
test2()
]]--



function t.parse_tokenInfo(infos)
-- TokenInfo ::= SEQUENCE {
    -- version		INTEGER {v1(0)} (v1,...),
    -- serialNumber	OCTET STRING,
    -- manufacturerID 	Label OPTIONAL,
    -- label 		[0] Label OPTIONAL,
    -- tokenflags 		TokenFlags,
    -- seInfo 		SEQUENCE OF SecurityEnvironmentInfo OPTIONAL,
    -- recordInfo 		[1] RecordInfo OPTIONAL,
    -- supportedAlgorithms	[2] SEQUENCE OF AlgorithmInfo OPTIONAL,
    -- ...,
    -- issuerId		[3] Label OPTIONAL,
    -- holderId		[4] Label OPTIONAL,
    -- lastUpdate		[5] LastUpdate OPTIONAL,
    -- preferredLanguage	PrintableString OPTIONAL -- In accordance with
    -- -- IETF RFC 1766 
-- } (CONSTRAINED BY { -- Each AlgorithmInfo.reference value must be unique --})

-- TokenFlags ::= BIT STRING {
    -- readonly		(0),
    -- loginRequired 	(1),
    -- prnGeneration 	(2),
    -- eidCompliant  	(3)
-- }
    
    local tiStruct = {}
    local ti = der.parse(infos)
    if ti[1].tag == der.SEQUENCE then
        local ti1 = der.parse(ti[1].value)
        
        if ti1[1].tag == der.INTEGER then
            tiStruct.version = ti1[1].value
            tiStruct.version_tag = ti1[1].tag
            
            tiStruct.serialNumber = ti1[2].value
            tiStruct.serialNumber_tag = ti1[2].tag
            
            if tiStruct.serialNumber and not string.find(tiStruct.serialNumber, "[^%a%d ]") then
                log.output(string.format("p15util.parse_tokenInfo(): serialNumber(ASCII)='%s'", tiStruct.serialNumber))
            end
            log.output(string.format("p15util.parse_tokenInfo(): serialNumber(HEX)=%s", hex.hexify(tiStruct.serialNumber or '')))
            local i = 3
            
            if ti1[i] and ti1[i].tag == der.UTF8STRING or ti1[i].tag == der.STRING then
                tiStruct.manufacturerID = ti1[i].value
                tiStruct.manufacturerID_tag = ti1[i].tag
                log.output(string.format("p15util.parse_tokenInfo(): manufacturerID='%s'", tiStruct.manufacturerID or ''))
                i = i +1
            end
            if ti1[i] and ti1[i].tag == der.CONTEXT_SPECIFIC(0) then
                tiStruct.label = ti1[i].value
                tiStruct.label_tag = ti1[i].tag
                log.output(string.format("p15util.parse_tokenInfo(): label='%s'", tiStruct.label or ''))
                i = i +1
            end
            
            if ti1[i] and ti1[i].tag == der.BIT_STRING then
                tiStruct.tokenflags = ti1[i].value
                tiStruct.tokenflags_tag = ti1[i].tag
                log.output("p15util.parse_tokenInfo(): tokenflags=", hex.hexify(tiStruct.tokenflags or ''))
                i = i +1
            end
            
            if ti1[i] and ti1[i].tag == der.SEQUENCE then
                tiStruct.seInfo = ti1[i].value
                tiStruct.seInfo_tag = ti1[i].tag
                log.output("p15util.parse_tokenInfo(): seInfo=", hex.hexify(tiStruct.seInfo or ''))
                i = i +1
            end
            
            if ti1[i] and (ti1[i].tag == der.CONTEXT(1) or ti1[i].tag == der.CONTEXT_SPECIFIC(1) ) then
                tiStruct.recordInfo = ti1[i].value
                tiStruct.recordInfo_tag = ti1[i].tag
                log.output("p15util.parse_tokenInfo(): recordInfo=", hex.hexify(tiStruct.recordInfo or ''))
                i = i +1
            end
            if ti1[i] and (ti1[i].tag == der.CONTEXT(2) or ti1[i].tag == der.CONTEXT_SPECIFIC(2) ) then
                tiStruct.supportedAlgorithms = ti1[i].value
                tiStruct.supportedAlgorithms_tag = ti1[i].tag
                log.output("p15util.parse_tokenInfo(): supportedAlgorithms=", hex.hexify(tiStruct.supportedAlgorithms or ''))
                i = i +1
            end
            if ti1[i] and ti1[i].tag == der.CONTEXT_SPECIFIC(3) then
                tiStruct.issuerId = ti1[i].value
                tiStruct.issuerId_tag = ti1[i].tag
                log.output("p15util.parse_tokenInfo(): issuerId=", tiStruct.issuerId)
                i = i +1
            end
            if ti1[i] and ti1[i].tag == der.CONTEXT_SPECIFIC(4) then
                tiStruct.holderId = ti1[i].value
                tiStruct.holderId_tag = ti1[i].tag
                log.output("p15util.parse_tokenInfo(): holderId=", tiStruct.holderId)
                i = i +1
            end
            if ti1[i] and (ti1[i].tag == der.CONTEXT(5) or ti1[i].tag == der.CONTEXT_SPECIFIC(5) ) then
                if ti1[i].tag == der.CONTEXT(5) then
                    local gt = der.parse(ti1[i].value)
                    tiStruct.lastUpdate = gt[1].value
                else
                    tiStruct.lastUpdate = ti1[i].value
                end
                tiStruct.lastUpdate_tag = ti1[i].tag
                log.output("p15util.parse_tokenInfo(): lastUpdate(ASCII)=", tiStruct.lastUpdate)
                log.output("p15util.parse_tokenInfo(): lastUpdate(HEX)=", hex.hexify(tiStruct.lastUpdate or ''))
                i = i +1
            end
            if ti1[i] and ti1[i].tag == der.PRINTABLESTRING then
                tiStruct.preferredLanguage = ti1[i].value
                tiStruct.preferredLanguage_tag = ti1[i].tag
                log.output("p15util.parse_tokenInfo(): preferredLanguage=", tiStruct.preferredLanguage)
                i = i +1
            end

            
        end
        
    end
    return tiStruct
end



function t.build_tokenInfo(tiStruct)
    local res = ""
    local versionD = der.build(tiStruct.version_tag or der.INTEGER, tiStruct.version or "\1")
    local serialNumberD = der.build(tiStruct.serialNumber_tag or der.STRING, tiStruct.serialNumber or string.rep("0", 16))
    local manufacturerIDD = tiStruct.manufacturerID and der.build(tiStruct.manufacturerID_tag or der.STRING, tiStruct.manufacturerID) or ""
    local labelD =  tiStruct.label and der.build(tiStruct.label_tag or der.CONTEXT_SPECIFIC(0), tiStruct.label) or ""
    local tokenflagsD =  der.build(tiStruct.tokenflags_tag or der.BIT_STRING, tiStruct.tokenflags or "\004\096")
    local seInfoD = tiStruct.seInfo and der.build(tiStruct.seInfo_tag or der.BIT_STRING, tiStruct.seInfo ) or ""
    local recordInfoD = tiStruct.recordInfo and der.build(tiStruct.recordInfo_tag or der.CONTEXT(1), tiStruct.recordInfo ) or ""
    local supportedAlgorithmsD = tiStruct.supportedAlgorithms and der.build(tiStruct.supportedAlgorithms_tag or der.CONTEXT(2), tiStruct.supportedAlgorithms ) or ""
    local issuerIdD = tiStruct.issuerId and der.build(tiStruct.issuerId_tag or der.CONTEXT(3), tiStruct.issuerId ) or ""
    local holderIdD = tiStruct.holderId and der.build(tiStruct.holderId_tag or der.CONTEXT(4), tiStruct.holderId ) or ""
    local lastUpdateD = ""
    
    if tiStruct.lastUpdate then
        tiStruct.lastUpdate_tag = tiStruct.lastUpdate_tag or der.CONTEXT(5)
        
        if tiStruct.lastUpdate_tag == der.CONTEXT(5) then
            local lastUpdateGTD = der.build(der.GENERALIZEDTIME, tiStruct.lastUpdate )
            lastUpdateD = der.build(tiStruct.lastUpdate_tag, lastUpdateGTD )
        else
            lastUpdateD = der.build(tiStruct.lastUpdate_tag, tiStruct.lastUpdate )
        end
    end
    local preferredLanguageD = tiStruct.preferredLanguage and der.build(tiStruct.preferredLanguage_tag or der.PRINTABLESTRING, tiStruct.preferredLanguage ) or ""

    res = der.build(der.SEQUENCE, versionD..serialNumberD..manufacturerIDD..labelD..tokenflagsD..seInfoD..recordInfoD..supportedAlgorithmsD..issuerIdD..holderIdD..lastUpdateD)
    return res
end




return t
--===========================================================================
end
}
_LOADED['token-nxp-chipdoc'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- token-nxp-chipdoc.lua
local NXPIASSmartCard = require 'NXPIASSmartCard'
local hex = require 'hex'
local zlib = require "zlib"
local hexf = hex.hexf
local der = require 'der'
local utility = require 'utility'
local repr = utility.repr
local p15 = require("p15util")
local util = utility
local json = require("json")
local rsa = require("rsa")
local ecdhlib = require "ecdhlib"
local aes = require "aes"

local PIN_POLICY_HISTORY_HASH_LEN = 20
local CKO_PIN_POLICY = tonumber("80001000", 16)

local PINPAD_CTL_VERIFY=1
local PINPAD_CTL_CHANGE=2
local PINPAD_CTL_RESET=3

local PINPAD_CTL_PIN=256
local PINPAD_CTL_PUK=512
local PINPAD_CTL_DSPIN=768
local PINPAD_CTL_DSPUK=1024

local MinKSize, MaxKSize = 1024, 2048
local t = {
    name = 'nxpias',
    mt = { },
    mechanisms = {
        [ CKM.RSA_PKCS_KEY_PAIR_GEN ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.GENERATE_KEY_PAIR},
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_PKCS_PSS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.SIGN},
        [ CKM.RSA_X_509 ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_PKCS_OAEP ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT},
        
        [ CKM.EC_KEY_PAIR_GEN ] = {ulMinKeySize=256, ulMaxKeySize=521, flags=CKF.HW+CKF.GENERATE_KEY_PAIR+CKF.EC_OID+CKF.EC_F_P+CKF.EC_UNCOMPRESS},
        [ CKM.ECDSA ] = {ulMinKeySize=256, ulMaxKeySize=521, flags=CKF.HW+CKF.SIGN+CKF.EC_OID+CKF.EC_F_P+CKF.EC_UNCOMPRESS},
    
        [ CKM.AES_KEY_GEN ] = {ulMinKeySize=16, ulMaxKeySize=32, flags=CKF.HW+CKF.GENERATE},
        [ CKM.AES_CBC ] = {ulMinKeySize=16, ulMaxKeySize=32, flags=CKF.HW+CKF.DECRYPT+CKF.ENCRYPT},
        [ CKM.AES_CBC_PAD ] = {ulMinKeySize=16, ulMaxKeySize=32, flags=CKF.HW+CKF.DECRYPT+CKF.ENCRYPT},
    },
    nxp_hcard = nil,
    capabilities = { private_attributes_readable=true, always_authenticate_on_cert=false, },
    NXPIASSmartCard=NXPIASSmartCard,
    card_cache = "card_cache",
}
t.mt.__index = t.mt

-- CiaPINsComplexityStruct ::= SEQUENCE {
    -- allowCardWipe [0] INTEGER,
    -- eccBasedSM [1] BOOLEAN,
    -- pkcsDirSize [2] INTEGER OPTIONAL, // 0 - no limitation
    -- userPinInfo [4] CiaUserPINInfo,
    -- adminInfo [5] CiaGeneralPINInfo,
    -- bioPinInfo [6] CiaGeneralPINInfo OPTIONAL, // relevant if bio is used
    -- bioInfo [7] CiaBioInfo OPTIONAL, // relevant if bio is used
    -- dsInfo [8] CiaDSInfo OPTIONAL, // relevant if SSCD is used
-- }
-- CiaUserPINInfo::= SEQUENCE {
    -- type INTEGER (0..255),
    -- maxAttempts INTEGER (0..255),
    -- maxUnblock INTEGER (0..255),
    -- mustChange INTEGER (0..255),
    -- mustChangeAfterUnlock INTEGER (0..255), deltaInSeconds INTEGER, // 0..2^24 deltaInDays INTEGER, // 0 - no limitation
    -- pinAlways INTEGER (0..255),
    -- complexity CiaPINComplexity OPTIONAL
-- }
-- CiaPINComplexity::= SEQUENCE {
    -- maxChars INTEGER (0..255),
    -- minChars INTEGER (0..255),
    -- minNum INTEGER (0..255),
    -- minAlphaNumeric INTEGER (0..255),
    -- minNonAlphaNumeric INTEGER (0..255),
    -- minLower INTEGER (0..255),
    -- minUpper INTEGER (0..255),
    -- minAlphaBetic INTEGER (0..255),
    -- maxOccurrence INTEGER (0..255),
    -- maxSequence INTEGER (0..255),
    -- historyCount INTEGER (0..255)
-- }
-- CiaGeneralPINInfo::= SEQUENCE {
    -- type INTEGER (0..255), // 0x01 - PIN, 0x02 