 Public portion        '22'           'A2'
-- Security environment                       '7B'           'FB'


CosmoXIASSmartCard.object_classes = {
    RSA_PUB_KEY=tonumber("A0", 16),
    RSA_PRIV_KEY=tonumber("90", 16),
    
    ECC_PUB_KEY=tonumber("A2", 16),
    ECC_PRIV_KEY=tonumber("92", 16),
    
    PIN=tonumber("81", 16),
    AES_KEY=tonumber("8B", 16),
    DF=tonumber("38", 16),
    EF=1,
}
CosmoXIASSmartCard.mt.object_classes = CosmoXIASSmartCard.object_classes

CosmoXIASSmartCard.object_classes_acs = {
    [CosmoXIASSmartCard.object_classes.RSA_PUB_KEY] = { -- RSA PUB KEY
        [7] = "SDO",
        [6] = "PSO_VERIFY_CERTIFICATE",
        [5] = "EXTERNAL_AUTHENTICATE",
        [4] = "RFU_4",
        [3] = "GENERATE_ASYMMETRIC_KEY_PAIR",
        [2] = "RFU_2",
        [1] = "PUT_DATA",
        [0] = "GET_DATA",
        tag=tonumber("7F49", 16),
    },
    [CosmoXIASSmartCard.object_classes.RSA_PRIV_KEY] = { -- RSA PRIV KEY
        [7] = "SDO",
        [6] = "PSO_COMPUTE_DIGITAL_SIGNATURE",
        [5] = "INTERNAL_AUTHENTICATE",
        [4] = "PSO_DECIPHER",
        [3] = "GENERATE_ASYMMETRIC_KEY_PAIR",
        [2] = "RFU_2",
        [1] = "PUT_DATA",
        [0] = "GET_DATA",
        tag=tonumber("7F48", 16),
    },
    [CosmoXIASSmartCard.object_classes.PIN] = { -- PIN
        [7] = "SDO",
        [6] = "CHANGE_REFERENCE_DATA",
        [5] = "VERIFY",
        [4] = "RESET_RETRY_COUNTER",
        [3] = "RFU_3",
        [2] = "RFU_2",
        [1] = "PUT_DATA",
        [0] = "GET_DATA",
        tag=tonumber("7F41", 16),
    },
    
    [CosmoXIASSmartCard.object_classes.AES_KEY] = { -- AES_KEY
        [7] = "SDO",
        [6] = "PSO_ENCIPHER",
        [5] = "EXTERNAL_AUTHENTICATE",
        [4] = "PSO_DECIPHER",
        [3] = "MUTUAL_AUTHENTICATE",
        [2] = "RFU_2",
        [1] = "PUT_DATA",
        [0] = "GET_DATA",
        tag=tonumber("A2", 16),
    },
    [CosmoXIASSmartCard.object_classes.DF] = { -- DF
        [7] = "FILE",
        [6] = "DELETE",
        [5] = "TERMINATE",
        [4] = "ACTIVATE",
        [3] = "DEACTIVATE",
        [2] = "CREATE_DF",
        [1] = "CREATE_EF",
        [0] = "PUT_DATA",
        tag=1,
    },
    [CosmoXIASSmartCard.object_classes.EF] = { -- EF
        [7] = "FILE",
        [6] = "DELETE",
        [5] = "TERMINATE",
        [4] = "ACTIVATE",
        [3] = "DEACTIVATE",
        [2] = "RFU_2",
        [1] = "UPDATE",
        [0] = "READ",
        tag=2,
    },
}

CosmoXIASSmartCard.object_classes_acs[CosmoXIASSmartCard.object_classes.ECC_PUB_KEY] = CosmoXIASSmartCard.object_classes_acs[CosmoXIASSmartCard.object_classes.RSA_PUB_KEY]
CosmoXIASSmartCard.object_classes_acs[CosmoXIASSmartCard.object_classes.ECC_PRIV_KEY] = CosmoXIASSmartCard.object_classes_acs[CosmoXIASSmartCard.object_classes.RSA_PRIV_KEY]

function CosmoXIASSmartCard.map_ambs(objClass, ambs)
    local mapped_ambs = {}

    local mapping = CosmoXIASSmartCard.object_classes_acs[objClass]
    
    if not mapping then
        return mapped_ambs
    end
    
    for i=0,7 do
        local v = ambs[i]
        if type(v) == "table" then
            v = util.clone_table(v)
        end
        mapped_ambs[mapping[i]] = v
    end
    return mapped_ambs
end

function CosmoXIASSmartCard.unmap_ambs(objClass, mapped_ambs)
    local unmapped_ambs = {}

    local mapping = CosmoXIASSmartCard.object_classes_acs[objClass]
    
    if not mapping then
        return
    end
    
    for i=0,7 do
        local v = mapped_ambs[mapping[i]]
        if type(v) == "table" then
            v = util.clone_table(v)
        end
        unmapped_ambs[i] = v
    end
    return unmapped_ambs
end

-- local acContactAMBs2 = {[1]={[1]=255}, [4]={[1]=215, [2]=211}, [5]={[1]=0}, [6]={[1]=215, [2]=211}, [7]=true, [0]={[1]=0}}
-- local mapped = CosmoXIASSmartCard.map_ambs(CosmoXIASSmartCard.object_classes.PIN, acContactAMBs2)
-- local unmapped = CosmoXIASSmartCard.unmap_ambs(CosmoXIASSmartCard.object_classes.PIN, mapped)

-- print (util.repr(mapped))
-- print (util.repr(unmapped))
-- print (util.repr(acContactAMBs2))

-- local acContactAMBs1 = {[5]={[1]=19}, [7]=true, [0]={[1]=0}, [3]={[1]=19}}
-- local mapped = CosmoXIASSmartCard.map_ambs(CosmoXIASSmartCard.object_classes.PIN, acContactAMBs1)
-- local unmapped = CosmoXIASSmartCard.unmap_ambs(CosmoXIASSmartCard.object_classes.PIN, mapped)

-- print (util.repr(mapped))
-- print (util.repr(unmapped))
-- print (util.repr(acContactAMBs1))

function CosmoXIASSmartCard.mt:get_DOCP(objClass, kid)
    log.output('CosmoXIASSmartCard:get_DOCP():', objClass, kid)
    local DOCP = {}
    
    if type(kid) == 'number' then 
        kid = hex.hexf('%B', kid)
    elseif string.len(kid) == 2 then 
        kid = hex.hexf(kid)
    end
    
    if type(objClass) == 'number' then 
        objClass = hex.hexf('%B', objClass)
    elseif string.len(objClass) == 2 then 
        objClass = hex.hexf(objClass)
    end
    
    local tag_70 = tonumber('70', 16) -- response TAG
    local tag_BFA0_X =  tonumber('BF' .. hex.hexify(objClass) .. hex.hexify(kid), 16) -- object TAG: BF CLASS ID
    local tag_A0 =  tonumber('A0', 16) -- DOCP
    
    local tag_80 =  tonumber('80', 16) -- obj len, 2 bytes
    local tag_9A =  tonumber('9A', 16) -- Maximum number of tries, 1 byte
    local tag_9B =  tonumber('9B', 16) -- Remaining tries counter, 1 byte
    local tag_9C =  tonumber('9C', 16) -- Maximum Usage counter, 1 byte
    local tag_9D =  tonumber('9D', 16) -- Remaining usage counter, 1 byte
    local tag_9E =  tonumber('9E', 16) -- Non-repudiation flag, 1 byte
    
    local tag_A5 =  tonumber('A5', 16) -- Issuer discretionary data in BER TLV format
    local tag_85 =  tonumber('85', 16) -- Issuer discretionary data in non BER TLV format
    
    
    local tag_A1 =  tonumber('A1', 16) -- access conditions
    local tag_A1_8C =  tonumber('8C', 16) -- contat access conditions
    local tag_A1_9C  =  tonumber('9C', 16) -- contatless access conditions
    

    -- local tag_4D = hex.hexf("4D097007bf%S%S037f4980", objClass, kid)
    -- local getDOCP = hex.hexf("00CB3FFF0000%P0000", tag_4D)
    
    local getDOCP = hex.hexf("00CB3FFF0A4D087006BF%S%S02A08000", objClass, kid)
    local recv = self:sm_transmit(getDOCP, self.ActiveSM)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hex.hexf("9000") then
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'get_doup Error' ))
    end
    
    local d = parse_tlv_ber(string.sub(recv, 1, -3))
    local d0 = parse_tlv_ber( d[tag_70] )
    local d1 = parse_tlv_ber( d0[tag_BFA0_X] )
    
    local d2 = parse_tlv_ber( d1[tag_A0] )
    
    local objLen = d2[tag_80] and bin.unpack("%>%H", d2[tag_80])
    log.output("CosmoXIASSmartCard:get_DOCP(): objLen:", objLen)
    
    local maxTries = d2[tag_9A] and string.byte( d2[tag_9A])
    log.output("CosmoXIASSmartCard:get_DOCP(): maxTries:", maxTries)
    
    local tries = d2[tag_9B] and string.byte( d2[tag_9B])
    log.output("CosmoXIASSmartCard:get_DOCP(): tries:", tries)
    
    local maxUsageCount = d2[tag_9C] and string.byte( d2[tag_9C])
    log.output("CosmoXIASSmartCard:get_DOCP(): maxUsageCount:", maxUsageCount)
    
    local usageCount = d2[tag_9D] and string.byte( d2[tag_9D])
    log.output("CosmoXIASSmartCard:get_DOCP(): usageCount:", usageCount)
    
    local nonRepudiation = d2[tag_9E] and string.byte( d2[tag_9E])
    log.output("CosmoXIASSmartCard:get_DOCP(): nonRepudiation:", nonRepudiation)
    
    local acs = parse_tlv_ber(d2[tag_A1])
    log.output("CosmoXIASSmartCard:get_DOCP(): acs:", util.repr(acs))
    local acContact = acs[tag_A1_8C]
    local acContactless = acs[tag_A1_9C]
    
    log.output("CosmoXIASSmartCard:get_DOCP(): acContact:", hex.hexify(acContact))
    log.output("CosmoXIASSmartCard:get_DOCP(): acContactless:", hex.hexify(acContactless))
    
    local acContactAMBs = CosmoXIASSmartCard.parse_ambs(acContact)
    local acContactlessAMBs = CosmoXIASSmartCard.parse_ambs(acContactless)

    log.output("CosmoXIASSmartCard:get_DOCP(): acContactAMBs:", util.repr(acContactAMBs))
    log.output("CosmoXIASSmartCard:get_DOCP(): acContactlessAMBs:", util.repr(acContactlessAMBs))
    local acContactMappedAMBs = CosmoXIASSmartCard.map_ambs(string.byte(objClass), acContactAMBs)
    local acContactlessMappedAMBs  = CosmoXIASSmartCard.map_ambs(string.byte(objClass), acContactlessAMBs)
    
    log.output("CosmoXIASSmartCard:get_DOCP(): acContactMappedAMBs:", util.repr(acContactMappedAMBs))
    log.output("CosmoXIASSmartCard:get_DOCP(): acContactlessMappedAMBs:", util.repr(acContactlessMappedAMBs))
    
    DOCP = {objLen = objLen,
            maxTries=maxTries,
            tries=tries,
            maxUsageCount=maxUsageCount,
            usageCount=usageCount,
            nonRepudiation=nonRepudiation,
            acs = {acContact=acContact,
                   acContactAMBs=acContactAMBs,
                   acContactMappedAMBs=acContactMappedAMBs,
                   acContactless=acContactless,
                   acContactlessAMBs=acContactlessAMBs,
                   acContactlessMappedAMBs=acContactlessMappedAMBs,
                },
            }
    log.output("CosmoXIASSmartCard:get_DOCP(): DOCP: ", util.repr(DOCP))
    
    return DOCP
end


function CosmoXIASSmartCard.mt:read_binary_sfi(sfi, offset, size, use_sm)
    log.output('CosmoXIASSmartCard:read_binary_sfi():', sfi, offset, size)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    
    local tag_53 = tonumber("53", 16)
    offset = offset or 0
    if size ~= 0 then
        size = size and (size+2) or 231 -- size+2: tag_53 + LEN + EXPECTED_LEN
    end
    local apdu = hex.hexf("00b100%B045402%>%H%B", sfi, offset, size)    
    local recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hex.hexf("9000") and sw ~= hex.hexf("6282") then
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'read_binary_sfi Error' ))
    end
    local res = parse_tlv_ber(string.sub(recv, 1, -3) )
    if res[tag_53] then
        return res[tag_53]
    else
        error('read_binary_sfi Error: invalid response format:' .. (recv and hex.hexify(recv) or "nil"))
    end
end

function CosmoXIASSmartCard.mt:verify_pin_main(pin, ispuk, use_sm)
    log.output('CosmoXIASSmartCard:verify_pin_main(): pin:', pin)
    log.output('CosmoXIASSmartCard:verify_pin_main(): ispuk:', ispuk)
    log.output('CosmoXIASSmartCard:verify_pin_main(): use_sm(1):', use_sm)
    
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output('CosmoXIASSmartCard:verify_pin_main(): use_sm(2):', use_sm)
    local bso = self.ID_PIN
    self:get_pin_puk_docp()
    local padding = self.pinDOCP.objLen
    
    if ispuk then
        bso = self.ID_PUK
        padding = self.pukDOCP.objLen
    end
    
    if string.len(pin)< padding then
        pin = pin .. string.rep(self.PADDING_CHAR, padding - string.len(pin))
    end

    return self:verify(bso, pin, false, use_sm)
end

function CosmoXIASSmartCard.mt:change_pin_main(oldPin, newPin, ispuk)
    log.output('CosmoXIASSmartCard:change_pin_main():', oldPin, newPin, ispuk )
    local bso = self.ID_PIN
    self:get_pin_puk_docp(true)
    local padding = self.pinDOCP.objLen
    
    if ispuk then
        bso = self.ID_PUK
        padding = self.pukDOCP.objLen
    end
    
    if string.len(oldPin) < padding then
        log.output('CosmoXIASSmartCard:change_pin_main(): using padding on old pin:', padding)
        oldPin = oldPin .. string.rep(self.PADDING_CHAR, padding - string.len(oldPin))
    end
    

    if string.len(newPin) < padding then
        log.output('CosmoXIASSmartCard:change_pin_main(): using padding on new pin:', padding)
        newPin = newPin .. string.rep(self.PADDING_CHAR, padding - string.len(newPin))
    end

    
    local res = self:change(bso, oldPin, newPin, true)
    if res == 0 then
        self:get_pin_puk_docp(true)
        log.output('change_pin_main(): calling verify_pin_main():...' )
        res = self:verify_pin_main(newPin, ispuk)
    end
    return res
end


function CosmoXIASSmartCard.mt:reset_pin_main(Puk, newPin)
    local res
    log.output('CosmoXIASSmartCard:reset_pin_main():', Puk, newPin)
    
    self:get_pin_puk_docp(true)
    local puk_padding = self.pukDOCP.objLen
    local pin_padding = self.pinDOCP.objLen
    
    if string.len(Puk) < puk_padding then
        log.output('CosmoXIASSmartCard:reset_pin_main(): using padding on puk:', puk_padding)
        Puk = Puk .. string.rep(self.PADDING_CHAR, puk_padding - string.len(Puk))
    end
    

    if string.len(newPin) < pin_padding then
        log.output('CosmoXIASSmartCard:reset_pin_main(): using padding on new pin:', pin_padding)
        newPin = newPin .. string.rep(self.PADDING_CHAR, pin_padding - string.len(newPin))
    end

    
    res = self:verify_pin_main(Puk, true)
    if res ~= 0 then return res end
    res =  self:reset_retry_counter(self.ID_PIN, newPin, true)
    if res == 0 then
        self:get_pin_puk_docp(true)
    end
    return res
end


function CosmoXIASSmartCard.mt:verify_pin_ds(pin)
    log.output('CosmoXIASSmartCard:verify_pin_ds(): pin:', pin)
    log.output('CosmoXIASSmartCard:verify_pin_ds(): use_sm(1):', use_sm)
    
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output('CosmoXIASSmartCard:verify_pin_ds(): use_sm(2):', use_sm)
    local bso = self.ID_PIN_DS
    self:get_pin_puk_docp()
    local padding = self.pinDOCP.objLen
    
    if string.len(pin)< padding then
        pin = pin .. string.rep(self.PADDING_CHAR, padding - string.len(pin))
    end

    return self:verify(bso, pin, true, use_sm)
end


function CosmoXIASSmartCard.mt:verify_pin_enc(pin)
    log.output('CosmoXIASSmartCard:verify_pin_enc(): pin:', pin)
    log.output('CosmoXIASSmartCard:verify_pin_enc(): use_sm(1):', use_sm)
    
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output('CosmoXIASSmartCard:verify_pin_enc(): use_sm(2):', use_sm)
    local bso = self.ID_PIN_ENC
    self:get_pin_puk_docp()
    local padding = self.pinDOCP.objLen
    
    if string.len(pin)< padding then
        pin = pin .. string.rep(self.PADDING_CHAR, padding - string.len(pin))
    end

    return self:verify(bso, pin, true, use_sm)
end


function CosmoXIASSmartCard.mt:change_pin_ds(oldPin, newPin, ispuk)
    log.output('CosmoXIASSmartCard:change_pin_ds():', oldPin, newPin, ispuk )
    local bso = self.ID_PIN_DS
    if ispuk then
        bso = self.ID_PUK_DS
    end
    local res = self:change(bso, oldPin, newPin, true)
    if res == 0 then
        log.output('CosmoXIASSmartCard:change_pin_ds(): calling verify_pin_ds():...' )
        res = self:verify_pin_ds(newPin, ispuk)
    end
    return res
end

function CosmoXIASSmartCard.mt:reset_pin_ds(Puk, newPin)
    local res
    log.output('CosmoXIASSmartCard:reset_pin_ds():', Puk, newPin )
    res = self:verify_pin_main(Puk, true)
    if res ~= 0 then return res end
    return self:reset_retry_counter(self.ID_PIN_DS, newPin, true)
end



function CosmoXIASSmartCard.mt:change_pin_enc(oldPin, newPin)
    log.output('CosmoXIASSmartCard:change_pin_enc():', oldPin, newPin )
    local bso = self.ID_PIN_ENC
    local res = self:change(bso, oldPin, newPin, true)
    if res == 0 then
        log.output('CosmoXIASSmartCard:change_pin_enc(): calling verify_pin_enc():...' )
        res = self:verify_pin_enc(newPin)
    end
    return res
end

function CosmoXIASSmartCard.mt:reset_pin_enc(Puk, newPin)
    local res
    log.output('CosmoXIASSmartCard:reset_pin_enc():', Puk, newPin )
    res = self:verify_pin_main(Puk, true)
    if res ~= 0 then return res end
    return self:reset_retry_counter(self.ID_PIN_ENC, newPin, true)
end

--- MSE SET CDS
-- '12' or 'FF110100' RSA PKCS#1 v1.5 - SHA-1
-- '32' or 'FF130100' RSA PKCS#1 v1.5 - SHA-224
-- '42' or 'FF140100' RSA PKCS#1 v1.5 - SHA-256
-- '52' or 'FF150100' RSA PKCS#1 v1.5 - SHA-384
-- '62' or 'FF160100' RSA PKCS#1 v1.5 - SHA-512

-- '15' or 'FF110200' RSA PKCS#1 v2.1 - SHA-1
-- '35' or 'FF130200' RSA PKCS#1 v2.1 - SHA-224
-- '45' or 'FF140200' RSA PKCS#1 v2.1 - SHA-256
-- '55' or 'FF150200' RSA PKCS#1 v2.1 - SHA-384
-- '65' or 'FF160200' RSA PKCS#1 v2.1 - SHA-512

-- '14' or 'FF110800' ECDSA - SHA1
-- '34' or 'FF130800' ECDSA - SHA224
-- '44' or 'FF140800' ECDSA - SHA256
-- '54' or 'FF150800' ECDSA - SHA384
-- '64' or 'FF160800' ECDSA - SHA512

local algo_RSAPKCSv1_5        = hex.hexf("02")
local algo_RSAPKCSv1_5_SHA1   = hex.hexf("12")
local algo_RSAPKCSv1_5_SHA224 = hex.hexf("32")
local algo_RSAPKCSv1_5_SHA256 = hex.hexf("42")
local algo_RSAPKCSv1_5_SHA384 = hex.hexf("52")
local algo_RSAPKCSv1_5_SHA512 = hex.hexf("62")

local algo_RSAPKCSv2_1_SHA1   = hex.hexf("15")
local algo_RSAPKCSv2_1_SHA224 = hex.hexf("35")
local algo_RSAPKCSv2_1_SHA256 = hex.hexf("45")
local algo_RSAPKCSv2_1_SHA384 = hex.hexf("55")
local algo_RSAPKCSv2_1_SHA512 = hex.hexf("65")

local algo_CSA_RSAPKCSv2_1_SHA1   = hex.hexf("FF210300")
local algo_CSA_RSAPKCSv2_1_SHA224 = hex.hexf("FF230300")
local algo_CSA_RSAPKCSv2_1_SHA256 = hex.hexf("FF240300")
local algo_CSA_RSAPKCSv2_1_SHA384 = hex.hexf("FF250300")
local algo_CSA_RSAPKCSv2_1_SHA512 = hex.hexf("FF260300")


local algo_ECDSA        = hex.hexf("04")
local algo_ECDSA_SHA1   = hex.hexf("14")
local algo_ECDSA_SHA224 = hex.hexf("34")
local algo_ECDSA_SHA256 = hex.hexf("44")
local algo_ECDSA_SHA384 = hex.hexf("54")
local algo_ECDSA_SHA512 = hex.hexf("64")

local SHA1_DIGEST_OID = hex.hexf("3021300906052b0e03021a05000414")
local SHA256_DIGEST_OID = hex.hexf("3031300d060960864801650304020105000420")
local SHA384_DIGEST_OID = hex.hexf("3041300d060960864801650304020205000430")
local SHA512_DIGEST_OID = hex.hexf("3051300d060960864801650304020305000440")

function CosmoXIASSmartCard.mt:pso_cds(data, kid, backtracking, ecc, pss, use_sm)
    local sw, recv
    local algo
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    kid = kid or '81'
    if type(kid) == 'number' then 
        kid = hex.hexf('%B', kid)
    elseif string.len(kid) == 2 then 
        kid = hex.hexf(kid)
    end

    if backtracking then
        kid = string.char((bin.flags( string.byte(kid, 1)) + bin.flags(128)).asnumber)
    end
    repeat
        if ecc then
            if string.len(data) == 20 then
                algo = algo_ECDSA_SHA1
            elseif string.len(data) == 32 then
                algo = algo_ECDSA_SHA256
            elseif string.len(data) == 48 then
                algo = algo_ECDSA_SHA384
            elseif string.len(data) == 64 then
                algo = algo_ECDSA_SHA512
            end
        else
            if string.sub(data, 1, string.len(SHA1_DIGEST_OID)) == SHA1_DIGEST_OID then
                data = string.sub(data, string.len(SHA1_DIGEST_OID)+1, -1)
                algo = pss and algo_RSAPKCSv2_1_SHA1 or algo_RSAPKCSv1_5_SHA1
            elseif string.len(data) == 20 then
                algo = pss and algo_RSAPKCSv2_1_SHA1 or algo_RSAPKCSv1_5_SHA1
            elseif string.sub(data, 1, string.len(SHA256_DIGEST_OID)) == SHA256_DIGEST_OID then
                data = string.sub(data, string.len(SHA256_DIGEST_OID)+1, -1)
                algo = pss and algo_RSAPKCSv2_1_SHA256 or algo_RSAPKCSv1_5_SHA256
            elseif string.len(data) == 32 then
                algo = pss and algo_RSAPKCSv2_1_SHA256 or algo_RSAPKCSv1_5_SHA256
                
            elseif string.sub(data, 1, string.len(SHA384_DIGEST_OID)) == SHA384_DIGEST_OID then
                data = string.sub(data, string.len(SHA384_DIGEST_OID)+1, -1)
                algo = pss and algo_RSAPKCSv2_1_SHA384 or algo_RSAPKCSv1_5_SHA384
            elseif string.len(data) == 48 then
                algo = pss and algo_RSAPKCSv2_1_SHA384 or algo_RSAPKCSv1_5_SHA384
                
            elseif string.sub(data, 1, string.len(SHA512_DIGEST_OID)) == SHA512_DIGEST_OID then
                data = string.sub(data, string.len(SHA512_DIGEST_OID)+1, -1)
                algo = pss and algo_RSAPKCSv2_1_SHA512 or algo_RSAPKCSv1_5_SHA512
            elseif string.len(data) == 64 then
                algo = pss and algo_RSAPKCSv2_1_SHA512 or algo_RSAPKCSv1_5_SHA512
            end
        end
        local Key = hex.hexf("80%P8401%S", algo, kid)
        local setKey = hex.hexf("002241B6%P", Key)
        recv = self:sm_transmit(setKey, use_sm)
        sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            log.output("CosmoXIASSmartCard:pso_cds: MSE SW", hex.hexify(sw))
            break
        end

        
        local apduSign = hex.hexf("002a9e9a%P", data)
        recv = self:sm_transmit(apduSign, use_sm)
        sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            log.output("CosmoXIASSmartCard:pso_cds: error", hex.hexify(sw))
            break
        end
    
    until true
    if sw ~= hexf('9000') then
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'pso_cds error' ))
    end
    
    return string.sub(recv, 1, -3)
end



function CosmoXIASSmartCard.mt:pso_internal_auth(data, kid, backtracking, ecc, pss, use_sm)
    log.output("CosmoXIASSmartCard:pso_internal_auth: data", hex.hexify(data or ''))
    log.output("CosmoXIASSmartCard:pso_internal_auth: backtracking", backtracking)
    local sw, recv
    local algo
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    kid = kid or '81'
    if type(kid) == 'number' then 
        kid = hex.hexf('%B', kid)
    elseif string.len(kid) == 2 then 
        kid = hex.hexf(kid)
    end

    if backtracking then
        kid = string.char((bin.flags( string.byte(kid, 1)) + bin.flags(128)).asnumber)
    end
    repeat
        if ecc then
            algo = algo_ECDSA
        else
        
            if pss then
                if string.sub(data, 1, string.len(SHA1_DIGEST_OID)) == SHA1_DIGEST_OID then
                    data = string.sub(data, string.len(SHA1_DIGEST_OID)+1, -1)
                    algo = algo_CSA_RSAPKCSv2_1_SHA1
                elseif string.len(data) == 20 then
                    algo = algo_CSA_RSAPKCSv2_1_SHA1
                    
                elseif string.sub(data, 1, string.len(SHA256_DIGEST_OID)) == SHA256_DIGEST_OID then
                    data = string.sub(data, string.len(SHA256_DIGEST_OID)+1, -1)
                    algo = algo_CSA_RSAPKCSv2_1_SHA256
                elseif string.len(data) == 32 then
                    algo = algo_CSA_RSAPKCSv2_1_SHA256
                    
                elseif string.sub(data, 1, string.len(SHA384_DIGEST_OID)) == SHA384_DIGEST_OID then
                    data = string.sub(data, string.len(SHA384_DIGEST_OID)+1, -1)
                    algo = algo_CSA_RSAPKCSv2_1_SHA384
                elseif string.len(data) == 48 then
                    algo = algo_CSA_RSAPKCSv2_1_SHA384
                    
                elseif string.sub(data, 1, string.len(SHA512_DIGEST_OID)) == SHA512_DIGEST_OID then
                    data = string.sub(data, string.len(SHA512_DIGEST_OID)+1, -1)
                    algo = algo_CSA_RSAPKCSv2_1_SHA512
                elseif string.len(data) == 64 then
                    algo = algo_CSA_RSAPKCSv2_1_SHA512
                end
            else
                algo = algo_RSAPKCSv1_5
            end
        end
        local Key = hex.hexf("80%P8401%S", algo, kid)
        local setKey = hex.hexf("002241A4%P", Key)
        recv = self:sm_transmit(setKey, use_sm)
        sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            log.output("CosmoXIASSmartCard:pso_internal_auth: MSE SW", hex.hexify(sw))
            break
        end

        
        local apduSign = hex.hexf("00880000%P", data)
        recv = self:sm_transmit(apduSign, use_sm)
        sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            log.output("CosmoXIASSmartCard:pso_internal_auth: error", hex.hexify(sw))
            break
        end
    
    until true
    if sw ~= hexf('9000') then
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'pso_internal_auth error' ))
    end
    
    return string.sub(recv, 1, -3)
end


function CosmoXIASSmartCard.mt:pso_dec(data, kid, backtracking, oaep, use_sm)
    log.output("CosmoXIASSmartCard:pso_dec(): ")
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local sw, resp
    if type(kid) == 'number' then 
        kid = hex.hexf('%B', kid)
    elseif string.len(kid) == 2 then 
        kid = hex.hexf(kid)
    end
    
    if backtracking then
        kid = string.char((bin.flags( string.byte(kid, 1)) + bin.flags(128)).asnumber)
    end
    local dec_mode = hex.hexf("1A")
    local oaep_mode_sha1 = hex.hexf("FF310200") -- RSA PKCS#1 V2.1 : OAEP with SHA1
    local oaep_mode_sha256 = hex.hexf("FF340200") -- RSA PKCS#1 V2.1 : OAEP with SHA256
    
    local oaep_mode = oaep == 1 and oaep_mode_sha1 or oaep_mode_sha256
    
    repeat

        if pin and string.len(pin) > 0 then
            local res = self:verify_pin_main(pin, false)
            if res ~= 0 then
                error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 
                    'pso_dec error: verify_pin_main failed!' ))
            end
        end
        
        local Key = hex.hexf("80%P8401%S",  oaep and oaep_mode or dec_mode, kid)
        local setKey = hex.hexf("002241B8%P", Key)
        resp = self:sm_transmit(setKey, use_sm)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end

        data = hex.hexf("81") .. data

        resp = self:sm_transmit(hex.hexf("002a8086%P%S", data, (string.len(data)>255) and "\0\0" or "\0" ), use_sm)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end

        
        -- local data_remaining = data
        
        -- while string.len(data_remaining) >0 do
            -- local apdu
            -- local cur_data = string.sub(data_remaining, 1, 231)
            -- data_remaining = string.sub(data_remaining, 232, -1)
            -- if not data_remaining or string.len(data_remaining) == 0 then
                -- apdu = hex.hexf("002a8086%P00", cur_data )
            -- else
                -- apdu = hex.hexf("102a8086%P", cur_data)
            -- end

            -- resp = self:sm_transmit(apdu, use_sm)
            -- sw = string.sub(resp, -2, -1)
            -- if sw ~= hexf('9000') then break end
        -- end
        
        break
    until true
    
    if sw ~= hexf('9000') then
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'pso_dec error' ))
    end
    return string.sub(resp, 1, -3)
end


function CosmoXIASSmartCard.mt:read_public_key(kid, use_sm)
    log.output("CosmoXIASSmartCard:read_public_key(): ")
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    
    if type(kid) == 'number' then 
        kid = hex.hexf('%B', kid)
    elseif string.len(kid) == 2 then 
        kid = hex.hexf(kid)
    end
    local resp
    -- 4D09 70 07 BFA010 03 7F4980
    local tag_4D = hex.hexf("4D097007bfa0%S037f4980", kid) -- bfa0 RSA PUB KEY
    local getKey = hex.hexf("00CB3FFF0000%P0000", tag_4D)
    resp = self:sm_transmit(getKey, use_sm)
    local sw = string.sub(resp, -2, -1)
    if sw ~= hexf('9000') then
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'read_public_key error' ))
    end
    
    local tag_70 = tonumber('70', 16)
    local tag_BFA0_X =  tonumber('BFA0' .. hex.hexify(kid), 16) -- bfa0 RSA PUB KEY
    local tag_7F49 =  tonumber('7F49', 16)
    local d = parse_tlv_ber(string.sub(resp, 1, -3))
    local d0 = parse_tlv_ber( d[tag_70] )
    local d1 = parse_tlv_ber( d0[tag_BFA0_X] )
    
    local d2 = parse_tlv_ber( d1[tag_7F49] )
    local MOD = d2[tonumber("81", 16)]
    local EXP = d2[tonumber("82", 16)]
    if string.len(MOD) < 256 then
        MOD = trim_pad_bn(MOD, 128) -- taglia a 1024 bit
    elseif string.len(MOD) < 384 then
        MOD = trim_pad_bn(MOD, 256) -- taglia a 2048 bit
    elseif string.len(MOD) < 512 then
        MOD = trim_pad_bn(MOD, 384) -- taglia a 3072 bit
    else
        MOD = trim_pad_bn(MOD, 512) -- taglia a 4096 bit
    end
    return MOD, EXP
end


function CosmoXIASSmartCard.mt:read_public_key_ECC(kid, use_sm, retry_no_sm_on_error)
    log.output("CosmoXIASSmartCard:read_public_key_ECC(): ", kid, use_sm, retry_no_sm_on_error)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    
    if type(kid) == 'number' then 
        kid = hex.hexf('%B', kid)
    elseif string.len(kid) == 2 then 
        kid = hex.hexf(kid)
    end
    local resp
    -- 4D09 70 07 BFA010 03 7F4980
    local tag_4D = hex.hexf("4D097007bfa2%S037f4980", kid) -- bfa2 ECC PUB KEY
    local getKey = hex.hexf("00CB3FFF0000%P0000", tag_4D)
    resp = self:sm_transmit(getKey, use_sm)
    local sw = string.sub(resp, -2, -1)
    if sw ~= hexf('9000') then
        if use_sm and sw == hexf('6985') and retry_no_sm_on_error then
            log.output("CosmoXIASSmartCard:read_public_key_ECC(): SM ERROR: closing SM channel and retry...")
            self:close_secure_channel()
            resp = self:sm_transmit(getKey, false)
            sw = string.sub(resp, -2, -1)
        end
        if sw ~= hexf('9000') then
            error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'read_public_key_ECC error' ))
        end
    end
    
    
    local tag_70 = tonumber('70', 16)
    local tag_BFA2_X =  tonumber('BFA2' .. hex.hexify(kid), 16) -- bfa2 ECC PUB KEY
    local tag_7F49 =  tonumber('7F49', 16)
    local d = parse_tlv_ber(string.sub(resp, 1, -3))
    local d0 = parse_tlv_ber( d[tag_70] )
    local d1 = parse_tlv_ber( d0[tag_BFA2_X] )
    
    local d2 = parse_tlv_ber( d1[tag_7F49] )
    local p = d2[tonumber("81", 16)]
    local a = d2[tonumber("82", 16)]
    local b = d2[tonumber("83", 16)]
    local g = d2[tonumber("84", 16)]
    local n = d2[tonumber("85", 16)]
    local pubkey = d2[tonumber("86", 16)]
    local order = d2[tonumber("87", 16)]
    
    return pubkey, p, a, b, g, n, order
end

function CosmoXIASSmartCard.mt:select_AID(aid, use_sm)
    log.output("CosmoXIASSmartCard:select_AID():", hex.hexify(aid), use_sm)
    log.output("CosmoXIASSmartCard:select_AID(): self.ActiveSM", self.ActiveSM)
    use_sm = use_sm == nil and self.ActiveSM or use_sm

    self._current_selected_aid = nil
    local apdu = hex.hexf("00a40404%P00", aid)
    
    local recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw == hexf('6D00') or sw == hexf('6a86') or sw == hexf('6A82')  then
        log.output("CosmoXIASSmartCard:select_AID(): try reselecting main CosmoX APPLET...")
        
        --recv = self:sm_transmit(CosmoXIASSmartCard.SELECT_MAIN_APPLET_MF_AID, false)
        self:select_Applet()
        
        if not use_sm then
            log.output("CosmoXIASSmartCard:select_AID(): retransmit PLAIN select AID...")
            recv = self:sm_transmit(apdu, false)
            sw = string.sub(recv, -2, -1)
        else
            log.output("CosmoXIASSmartCard:select_AID(): force retransmit select AID after rebuild SM session...")
            sw = hexf('6988')
        end
    end
    if sw == hexf('6988') and use_sm then
        log.output("CosmoXIASSmartCard:select_AID(): SM session invalid?")
        if self:perform_mutual_authenticate(aid) then
            log.output("CosmoXIASSmartCard:select_AID(): retry sending APDU...")
            recv = self:sm_transmit(apdu, use_sm)
            sw = string.sub(recv, -2, -1)
        end
    end
    if sw ~= hexf('9000') then
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'select_AID error' ))
    end
    self._current_selected_aid = aid
end

function CosmoXIASSmartCard.mt:select_Applet(use_sm)
    log.output("CosmoXIASSmartCard:select_Applet():", use_sm)
    log.output("CosmoXIASSmartCard:select_Applet(): self.ActiveSM", self.ActiveSM)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local recv = self:sm_transmit(CosmoXIASSmartCard.SELECT_MAIN_APPLET_MF_AID, use_sm)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'select_Applet error' ))
    end
end

function CosmoXIASSmartCard.mt:select_MF(use_sm)
    log.output("CosmoXIASSmartCard:select_MF():", use_sm)
    log.output("CosmoXIASSmartCard:select_MF(): self.ActiveSM", self.ActiveSM)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local recv = self:sm_transmit(hex.hexf("00a4000C023f0000"), use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw == hexf('6D00') or sw == hexf('6a86') then
        log.output("CosmoXIASSmartCard:select_MF(): try reselecting main CD APPLET...")
        
        self:select_Applet()
        
        recv = self:sm_transmit(hex.hexf("00a4000C023f0000"), use_sm)
        sw = string.sub(recv, -2, -1)
    end
    if sw ~= hexf('9000') then
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'select_MF error' ))
    end

end


function CosmoXIASSmartCard.mt:select_SSCD(use_sm)
    log.output("CosmoXIASSmartCard:select_SSCD():", use_sm)
    self.has_sscd = false
    self:select_AID(SSCD_AID, use_sm)
    log.output("CosmoXIASSmartCard:select_SSCD(): OK!")
    self.has_sscd = true
end

function CosmoXIASSmartCard.mt:select_Generic(use_sm)
    log.output("CosmoXIASSmartCard:select_Generic():", use_sm)
    self:select_AID(Generic_AID, use_sm)
end


function CosmoXIASSmartCard.mt:read_serial_number(force)
    log.output("CosmoXIASSmartCard:read_serial_number(): force=", force)
    if not self.CSN or force then
        log.output("CosmoXIASSmartCard:read_serial_number(): reading..." )
        
        self:select_MF()
        
        self:select(hex.hexf("d003"))
        local ICC_SN_FULL = self:read_binary(0, 0)
        log.output("ICC_SN_FULL: (1)", hex.hexify(ICC_SN_FULL))
        ICC_SN_FULL = string.sub(ICC_SN_FULL, 3, -1)
        log.output("ICC_SN_FULL (2):", ICC_SN_FULL)
        
        self.CSN = ICC_SN_FULL
    else
        log.output("CosmoXIASSmartCard:read_serial_number(): cached!" )
    end
    log.output("CosmoXIASSmartCard:read_serial_number():", hex.hexify(self.CSN) )
    return self.CSN
end


function CosmoXIASSmartCard.mt:verify(bso, pin, backtracking, use_sm)
    log.output("CosmoXIASSmartCard:verify():" )
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    if backtracking then
        bso = (bin.flags(bso) + bin.flags(128)).asnumber
    end
    local apdu = hex.hexf("002000%B%P", bso, pin)
    local recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw == hexf('6983') then
        return 2, 'Authentication blocked'
    elseif sw == hexf('6700') or string.sub(hexify(sw), 1, 2) == '63' then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        return 0, 'Authentication succeeded'
    else
        log.output('CosmoXIASSmartCard:verify(): Error ' .. hexify(sw) )
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'verify Error' ))
    end
end


function CosmoXIASSmartCard.mt:read_cert(fid, use_sm)

    log.output('CosmoXIASSmartCard:read_cert():', hex.hexify(fid), use_sm)
    
    use_sm = use_sm == nil and self.ActiveSM or use_sm

    self:select(fid, false, use_sm)
    local offset = 0
    local der_size = self:read_binary(offset, 4, use_sm)

    if string.sub(der_size, 1, 2) ~= hexf('3082') then
        error('CosmoXIASSmartCard read_cert Error: bad certificate')
    end
    local size = string.byte(der_size, 3) * 256 + string.byte(der_size, 4)
    local cert =  der_size .. self:mread_binary(offset+4, size, use_sm)        

    return cert
end

local cachable_attributes = {
    "RANDOM_SEED",
}

function CosmoXIASSmartCard.mt:get_cachable_dict()
    local cache = {}
    
    for i=1,table.getn(cachable_attributes) do
        local attr = cachable_attributes[i]
        if type(self[attr]) == "string" then
            cache[attr] = hex.hexify( self[attr])
        else
            cache[attr] = self[attr]
        end
    end
    return cache
end

function CosmoXIASSmartCard.mt:set_cachable_dict(cache)

    for i=1,table.getn(cachable_attributes) do
        local attr = cachable_attributes[i]
        if type(cache[attr]) == "string" then
            self[attr] = hex.hexf(cache[attr])
            log.output(string.format('CosmoXIASSmartCard:set_cachable_dict(): restored "%s" -> "%s"', attr, hex.hexify(self[attr] or "") ))
        elseif cache[attr] ~= nil then
            self[attr] = cache[attr]
            log.output(string.format('CosmoXIASSmartCard:set_cachable_dict(): restored "%s" -> "%s"', attr, tostring(self[attr]) or ""))
        end
    end
    
end

function CosmoXIASSmartCard.mt:delete_SDO(objClass, kid, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output('CosmoXIASSmartCard:delete_SDO()')

    if type(kid) == 'number' then 
        kid = hex.hexf('%B', kid)
    elseif string.len(kid) == 2 then 
        kid = hex.hexf(kid)
    end

    if type(objClass) == 'number' then 
        objClass = hex.hexf('%B', objClass)
    elseif string.len(objClass) == 2 then 
        objClass = hex.hexf(objClass)
    end
    
    local delete_apdu = hex.hexf("00db3fff067004bf%S%S00", objClass, kid)
    
    local recv = self:sm_transmit(delete_apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    return sw == hexf('9000')
end

function CosmoXIASSmartCard.mt:create_RSA_SDO_for_keygen(objClass, kid, bits, mapped_acs, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output('CosmoXIASSmartCard:create_RSA_SDO_for_keygen()', objClass, kid, bits)

    if type(kid) == 'number' then 
        kid = hex.hexf('%B', kid)
    elseif string.len(kid) == 2 then 
        kid = hex.hexf(kid)
    end
    
    if type(objClass) == 'number' then 
        objClass = hex.hexf('%B', objClass)
    elseif string.len(objClass) == 2 then 
        objClass = hex.hexf(objClass)
    end
    
    mapped_acs = util.clone_table(mapped_acs)
    mapped_acs.SDO = true
    
    local unmapped_acs = CosmoXIASSmartCard.unmap_ambs(string.byte(objClass), mapped_acs)
    local acs = CosmoXIASSmartCard.build_ambs(unmapped_acs)
    
    log.output("CosmoXIASSmartCard:create_RSA_SDO_for_keygen(): acs:", hex.hexify(acs))
    
    local acContact = hex.hexf("8C%P", acs)
    local acContactless = hex.hexf("9C%P", acs)
    
    local acsTLV = hex.hexf("A1%P", acContact .. acContactless)
    
    local privClass = string.byte(objClass) == CosmoXIASSmartCard.object_classes.RSA_PRIV_KEY or 
        string.byte(objClass) == CosmoXIASSmartCard.object_classes.ECC_PRIV_KEY
    
    local non_repudiation_counter =  privClass and hex.hexf("9E01%B", mapped_acs.non_repudiation_counter or 0) or ""
    local value = non_repudiation_counter .. hex.hexf("8002%>%H", bits/8) .. acsTLV

    local docp = hex.hexf("A0%P", value)
   
   
    local doup_tag = hex.hexify(hex.hexf("%>%H",  CosmoXIASSmartCard.object_classes_acs[string.byte(objClass)].tag))

    local doup = BUILD_TLV_BER(doup_tag, hex.hexf("800100")) -- DOUP only algo "00"
    
    local BFXXYY = BUILD_TLV_BER("BF" .. hex.hexify(objClass .. kid), docp .. doup)
    
    local tag_70 = hex.hexf("70%P", BFXXYY)
    local create_apdu = hex.hexf("00DB3FFF%P", tag_70)

    local recv = self:sm_transmit(create_apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'create RSA SDO Error'))
    end
end

function CosmoXIASSmartCard.mt:create_ECDSA_SDO_for_keygen(objClass, kid, bits, mapped_acs, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output('CosmoXIASSmartCard:create_ECDSA_SDO_for_keygen()', objClass, kid, bits)

    local curve = ecdhlib.get_curve("secp256r1")
    if bits == 256 then
        curve = ecdhlib.get_curve("secp256r1")
    elseif bits == 384 then
        curve = ecdhlib.get_curve("secp384r1")
    elseif bits == 521 or bits == 528 then
        curve = ecdhlib.get_curve("secp521r1")
    else
        error("CosmoXIASSmartCard::create_ECDSA_SDO_for_keygen(): unsupported curve")
    end
    
    if type(kid) == 'number' then 
        kid = hex.hexf('%B', kid)
    elseif string.len(kid) == 2 then 
        kid = hex.hexf(kid)
    end
    
    if type(objClass) == 'number' then 
        objClass = hex.hexf('%B', objClass)
    elseif string.len(objClass) == 2 then 
        objClass = hex.hexf(objClass)
    end
    
    mapped_acs = util.clone_table(mapped_acs)
    mapped_acs.SDO = true
    
    local unmapped_acs = CosmoXIASSmartCard.unmap_ambs(string.byte(objClass), mapped_acs)
    local acs = CosmoXIASSmartCard.build_ambs(unmapped_acs)
    
    log.output("CosmoXIASSmartCard:create_ECDSA_SDO_for_keygen(): acs:", hex.hexify(acs))
    
    local acContact = hex.hexf("8C%P", acs)
    local acContactless = hex.hexf("9C%P", acs)
    
    local key_bytes = curve.keysize
    local acsTLV = hex.hexf("A1%P", acContact .. acContactless)

    local privClass = string.byte(objClass) == CosmoXIASSmartCard.object_classes.RSA_PRIV_KEY or 
        string.byte(objClass) == CosmoXIASSmartCard.object_classes.ECC_PRIV_KEY 
    
    local non_repudiation_counter =  privClass and hex.hexf("9E01%B", mapped_acs.non_repudiation_counter or 0) or ""
    local value = non_repudiation_counter .. hex.hexf("8002%>%H", curve.keybits) .. acsTLV
    
    local docp = hex.hexf("A0%P", value)
   
    -- DOUP: create ECDSA curve components
    local doup_tag = string.format("%04X",  CosmoXIASSmartCard.object_classes_acs[string.byte(objClass)].tag)
    

    local p = trim_pad_bn(hex.hexf(curve.p:tostring(16, true)), key_bytes)
    local a = trim_pad_bn(hex.hexf(curve.a:tostring(16, true)), key_bytes)
    local b = trim_pad_bn(hex.hexf(curve.b:tostring(16, true)), key_bytes)
    local Gx = trim_pad_bn(hex.hexf(curve.g.x:tostring(16, true)), key_bytes) -- coordinates x in F defining a curve point G
    local Gy = trim_pad_bn(hex.hexf(curve.g.y:tostring(16, true)), key_bytes) -- coordinates y in F defining a curve point G
    local n = trim_pad_bn(hex.hexf(curve.n:tostring(16, true)), key_bytes)
    local doup_data = hex.hexf("800100") -- "Algorithm to compulsorily use"
                    .. BUILD_TLV_BER("81", p)  -- prime modulus
                    .. BUILD_TLV_BER("82", a) .. BUILD_TLV_BER("83", b)  -- a & b coefficients of the curve
                    .. BUILD_TLV_BER("84", "\4" .. Gx .. Gy) -- coordinates x and y in uncompressed form
                    .. BUILD_TLV_BER("85", n) -- order of the base point (positive prime integer)
                    .. hex.hexf("870101") -- h - curve Cofactor
    
    
    local doup = BUILD_TLV_BER(doup_tag, doup_data)
    
    -- local tag_70 = BUILD_TLV_BER("70", docp .. doup)
    -- print("tag_70:", hex.hexify(tag_70))
    -- assert(string.len(tag_70) < 256)
    
    local BFXXYY = BUILD_TLV_BER("BF" .. hex.hexify(objClass .. kid), docp .. doup)
    
    local tag_70 = BUILD_TLV_BER("70", BFXXYY)
    local create_apdu = hex.hexf("00DB3FFF%P", tag_70)

    local recv = self:sm_transmit(create_apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'create ECC SDO Error'))
    end
    
end


function CosmoXIASSmartCard.mt:generate_RSA(kid, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output('CosmoXIASSmartCard:generate_RSA()', kid, use_sm)

    if type(kid) == 'number' then 
        kid = hex.hexf('%B', kid)
    elseif string.len(kid) == 2 then 
        kid = hex.hexf(kid)
    end

    local set_pub_exp_apdu = hex.hexf("00DB3FFF0E700CBFA0%S087F49058203010001", kid)
    local recv = self:sm_transmit(set_pub_exp_apdu, use_sm)
    
    local start = os.time()
    local genrate_key_pair = hex.hexf("00470000057003bf90%S", kid)
    recv = self:sm_transmit(genrate_key_pair, use_sm)
    log.output ("CosmoXIASSmartCard:generate_RSA(): recv:", hex.hexify(recv))
    log.output ("CosmoXIASSmartCard:generate_RSA(): elapsed:", os.time() - start)
    
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'generate_RSA Error'))
    end
end

function CosmoXIASSmartCard.mt:generate_ECC(kid, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output('CosmoXIASSmartCard:generate_ECC()', kid, use_sm)

    if type(kid) == 'number' then 
        kid = hex.hexf('%B', kid)
    elseif string.len(kid) == 2 then 
        kid = hex.hexf(kid)
    end

    local recv
    
    local start = os.time()
    local genrate_key_pair = hex.hexf("00470000057003bf92%S", kid)
    recv = self:sm_transmit(genrate_key_pair, use_sm)
    log.output ("CosmoXIASSmartCard:generate_ECC(): recv:", hex.hexify(recv))
    log.output ("CosmoXIASSmartCard:generate_ECC(): elapsed:", os.time() - start)
    
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'generate_ECC Error'))
    end
end



function CosmoXIASSmartCard.mt:update_binary(offset, data, use_sm, sfi)
    local recv
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    sfi = sfi or 0
    local size = string.len(data)
    log.output("CosmoXIASSmartCard:update_binary(): writing to:", offset, "size:", size, "sfi:", sfi)
    
    local payload = hex.hexf("5402%>%H5381%P", offset, data)
    local apdu = hex.hexf("00d7%>%H%P", sfi, payload)

    recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'update_binary Error'))
    end
end

function CosmoXIASSmartCard.mt:mupdate_binary(offset, data, use_sm, sfi, padding_blocks)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output("CosmoXIASSmartCard:mupdate_binary(): offset=", offset, "sfi=", sfi)
    local buffer_size = CosmoXIASSmartCard.MAX_TRANSMIT_BUFFER_SIZE
    padding_blocks = padding_blocks or 0
    local padding_max_len = padding_blocks * buffer_size
    if padding_max_len > 0 then
        local padding_len = padding_max_len - math.mod(string.len(data), buffer_size)
        if padding_len > 0 then
            data = data .. string.rep("\0", padding_len)
            log.output("CosmoXIASSmartCard:mupdate_binary(): added padding_len:", padding_len)
        end
    end
    local left = string.len(data)
    log.output("CosmoXIASSmartCard:mupdate_binary():multi update from:", offset, "size:", left, "chunks:", buffer_size)
    local curOffset = offset
    local chunk
    while left > 0 do
        chunk = string.sub(data, curOffset-offset+1, curOffset-offset + buffer_size)
        if chunk == 0 then
            log.output("CosmoXIASSmartCard:mupdate_binary(): WARNING: specified data len is not enough?")
            break
        end
        self:update_binary(curOffset, chunk, use_sm, sfi)
        left = left - string.len(chunk)
        curOffset = curOffset + string.len(chunk)
    end
end

function CosmoXIASSmartCard.mt:mupdate_binary_smart(offset, data, use_sm, sfi)
    log.output("CosmoXIASSmartCard:mupdate_binary_smart():")
    return self:mupdate_binary(offset, data, use_sm, sfi, 2)
end



function CosmoXIASSmartCard.mt:delete_file(path, select_df, use_sm)
    local recv
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    sfi = sfi or 0
    log.output("CosmoXIASSmartCard:delete_file():")
    local pcRes = true
    
    if path then
        pcRes = pcall(function()
            self:select(path, select_df, use_sm)
        end)
    end
    if pcRes then
        local apdu = hex.hexf("00e4000000")
        recv = self:sm_transmit(apdu, use_sm)
        local sw = string.sub(recv, -2, -1)
        return sw == hexf('9000')
    else
        return false
    end
end


function CosmoXIASSmartCard.mt:create_binary_file(fid, size, use_sm, sdo_write, sdo_read, sdo_delete)
    local recv
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    sfi = sfi or 0
    log.output("CosmoXIASSmartCard:create_binary_file(): size:", size)
    
    sdo_write = sdo_write or (self.ID_SE_MAIN + CosmoXIASSmartCard.ID_SBC_PIN )
    sdo_read = sdo_read or CosmoXIASSmartCard.ID_SE_ALWAYS
    sdo_delete = sdo_delete or sdo_write
    
    if type(fid) == "number" then
        fid = hex.hexf("%>%H", fid)
    elseif string.len(fid) > 2 then
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new("", 'create_binary_file: invalid fid'))
    end
    
    log.output(string.format("CosmoXIASSmartCard:create_binary_file(): fid:%s, sdo_write:%02X, sdo_read:%02X, sdo_delete:%02X",
        hex.hexify(fid), sdo_write, sdo_read, sdo_delete) )
   
    local acs = hex.hexf("40%B02%B01%B", sdo_delete, sdo_write, sdo_read)
    local allAcs = hex.hexf("8c%P9c%P", acs, acs)
    local FDO =  hex.hexf("8002%>%H82010183%P88008a0105a1%P", size, fid, allAcs)
    local payload = hex.hexf("62%P", FDO)
    local apdu = hex.hexf("00e00000%P", payload)

    recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'create_binary_file Error'))
    end
end



function CosmoXIASSmartCard.mt:import_private_key(id, m, e, p, q, iq, dp, dq)
    local resp, padto
    local block_len = 220
    
    if type(id) == 'string' then
        if string.len(id) == 1 then 
            id = hex.hexify(id)
        end
    elseif type(id) == 'number' then
        id = hex.hexify(hex.hexf("%B", id))
    end
    
    if type(m) == "number" then
        padto = m/2 -- specifica solo la lunghezza del modulo
        m = nil
    elseif type(m) == "string" then
        if string.len(m) < 256 then
            m = trim_pad_bn(m, 128) -- taglia a 1024 bit
        elseif string.len(m) < 384 then
            m = trim_pad_bn(m, 256) -- taglia a 2048 bit
        elseif string.len(m) < 512 then
            m = trim_pad_bn(m, 384) -- taglia a 3072 bit
        else
            m = trim_pad_bn(m, 512) -- taglia a 4096 bit
        end
    
        padto = string.len(m) / 2        
    end
    assert(e == nil or string.len(e) < 8)

    local apdus = {}
    local set_pub_exp_mod_data_1, set_pub_exp_mod_data_2
    local set_priv
    local put_data_header = "00DB3FFF%P"
    local put_data_header10 = "10DB3FFF%P"
    
    if e and m then
        local pub_mod = BUILD_TLV_BER("81", m)
        local pub_exp = BUILD_TLV_BER("82", e)
        
        local set_pub_exp_mod_data = BUILD_TLV_BER("70", BUILD_TLV_BER("BFA0" .. id, BUILD_TLV_BER("7f49",  pub_mod .. pub_exp) ) )
        log.output(string.format("CosmoXIASSmartCard:import_private_key(): set_pub_exp_mod_data: %s", hex.hexify(set_pub_exp_mod_data)))
        
        append_chained_apdus(put_data_header, put_data_header10, set_pub_exp_mod_data, block_len, apdus)

        
    end


    if p and q and iq and dp and dq then
        p = trim_pad_bn(p, padto)
        q = trim_pad_bn(q, padto)
        iq = trim_pad_bn(iq, padto)
        dp = trim_pad_bn(dp, padto)
        dq = trim_pad_bn(dq, padto)
        local priv_p = BUILD_TLV_BER("92", p)
        local priv_q = BUILD_TLV_BER("93", q)
        local priv_iq = BUILD_TLV_BER("94", iq)
        local priv_dp = BUILD_TLV_BER("95", dp)
        local priv_dq = BUILD_TLV_BER("96", dq)
        
        local components = {
            priv_p, priv_q, priv_iq, priv_dp, priv_dq
        }
        for i=1,table.getn(components) do
            local component = components[i]
            -- set_priv = BUILD_TLV_BER("70", BUILD_TLV_BER("BF90" .. id, BUILD_TLV_BER("7f48",  priv_p ..  priv_q .. priv_iq .. priv_dp .. priv_dq ) ) )
            set_priv = BUILD_TLV_BER("70", BUILD_TLV_BER("BF90" .. id, BUILD_TLV_BER("7f48",  component ) ) )
            log.output(string.format("CosmoXIASSmartCard:import_private_key(): set_priv component: %s", hex.hexify(set_priv)))

            append_chained_apdus(put_data_header, put_data_header10, set_priv, block_len, apdus)
        end

    end
    
    
    for i=1,table.getn(apdus) do
        recv = self:sm_transmit(apdus[i], true)
        local sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'import_private_key Error'))
        end
        -- log.output(string.format("CosmoXIASSmartCard:import_private_key(): APDU: %s", hex.hexify(apdus[i])))
    end
    
end

function CosmoXIASSmartCard.mt:import_ecc_private_key(id, ec_point, value)
    local block_len = 220
    
    if type(id) == 'string' then
        if string.len(id) == 1 then 
            id = hex.hexify(id)
        end
    elseif type(id) == 'number' then
        id = hex.hexify(hex.hexf("%B", id))
    end
    


    local apdus = {}
    local set_priv
    local put_data_header = "00DB3FFF%P"
    local put_data_header10 = "10DB3FFF%P"

    local ec_point = ec_point and BUILD_TLV_BER("86", ec_point) -- pub key component in uncompressed format
    local value_doup = value and BUILD_TLV_BER("90", value) -- private key padded to curve keysize
    
                    
    if ec_point then
        local set_pub_data =
         BUILD_TLV_BER("70", BUILD_TLV_BER("BFA2" .. id, BUILD_TLV_BER("7f49",  ec_point) ) )
        
        log.output(string.format("CosmoXIASSmartCard:import_ecc_private_key(): set_pub_data: %s", hex.hexify(set_pub_data)))
        append_chained_apdus(put_data_header, put_data_header10, set_pub_data, block_len, apdus)
    end


    if value_doup then -- no ec_point (ec_point = G * value)
        local set_priv_data =
         BUILD_TLV_BER("70", BUILD_TLV_BER("BF92" .. id, BUILD_TLV_BER("7f48", value_doup) ) )
        
        log.output(string.format("CosmoXIASSmartCard:import_ecc_private_key(): set_priv_data: %s", hex.hexify(set_priv_data)))
        append_chained_apdus(put_data_header, put_data_header10, set_priv_data, block_len, apdus)

    end
    
    
    for i=1,table.getn(apdus) do
        recv = self:sm_transmit(apdus[i], true)
        local sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'import_ecc_private_key Error'))
        end
        -- log.output(string.format("CosmoXIASSmartCard:import_ecc_private_key(): APDU: %s", hex.hexify(apdus[i])))
    end
    
end

-- print(util.repr(CosmoXIASSmartCard.parse_ambs(hex.hexf("F3D700D7FF00D0D3D3"))))

return CosmoXIASSmartCard


--===========================================================================
end
}
_LOADED['json'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-----------------------------------------------------------------------------
-- JSON4Lua: JSON encoding / decoding support for the Lua language.
-- json Module.
-- Author: Craig Mason-Jones
-- Homepage: http://json.luaforge.net/
-- Version: 0.9.20
--
-- USAGE:
-- This module exposes two functions:
--   encode(o)
--     Returns the table / string / boolean / number / nil / json.null value as a JSON-encoded string.
--   decode(json_string)
--     Returns a Lua object populated with the data encoded in the JSON string json_string.
--
--
-- CHANGELOG
--   0.9.20 Introduction of local Lua functions for private functions (removed _ function prefix). 
--          Fixed Lua 5.1 compatibility issues.
--   		Introduced json.null to have null values in associative arrays.
--          encode() performance improvement (more than 50%) through table.concat rather than ..
--          Introduced decode ability to ignore /**/ comments in the JSON string.
--   0.9.10 Fix to array encoding / decoding to correctly manage nil/null values in arrays.
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Imports and dependencies
-----------------------------------------------------------------------------
local base = _G

-----------------------------------------------------------------------------
-- Module declaration
-----------------------------------------------------------------------------
local json = {}
local encode
local null
local decode

-- Private functions
local decode_scanArray
local decode_scanComment
local decode_scanConstant
local decode_scanNumber
local decode_scanObject
local decode_scanString
local decode_scanWhitespace
local encodeString
local isArray
local isEncodable

-----------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-----------------------------------------------------------------------------
--- Encodes an arbitrary Lua object / variable.
-- @param v The Lua object / variable to be JSON encoded.
-- @return String containing the JSON encoding in internal Lua string format (i.e. not unicode)
function encode (v)
  -- Handle nil values
  if v==nil then
    return "null"
  end
  
  local vtype = base.type(v)  

  -- Handle strings
  if vtype=='string' then    
    return '"' .. encodeString(v) .. '"'	    -- Need to handle encoding in string
  end
  
  -- Handle booleans
  if vtype=='number' or vtype=='boolean' then
    return base.tostring(v)
  end
  
  -- Handle tables
  if vtype=='table' then
    local rval = {}
    -- Consider arrays separately
    local bArray, maxCount = isArray(v)
    if bArray then
      for i = 1,maxCount do
        table.insert(rval, encode(v[i]))
      end
    else	-- An object, not an array
      for i,j in base.pairs(v) do
        if isEncodable(i) and isEncodable(j) then
          table.insert(rval, '"' .. encodeString(i) .. '":' .. encode(j))
        end
      end
    end
    if bArray then
      return '[' .. table.concat(rval,',') ..']'
    else
      return '{' .. table.concat(rval,',') .. '}'
    end
  end
  
  -- Handle null values
  if vtype=='function' and v==null then
    return 'null'
  end
  
  base.assert(false,'encode attempt to encode unsupported type ' .. vtype .. ':' .. base.tostring(v))
end


--- Decodes a JSON string and returns the decoded value as a Lua data structure / value.
-- @param s The string to scan.
-- @param [startPos] Optional starting position where the JSON string is located. Defaults to 1.
-- @param Lua object, number The object that was scanned, as a Lua table / string / number / boolean or nil,
-- and the position of the first character after
-- the scanned JSON object.
function decode(s, startPos)
  startPos = startPos and startPos or 1
  startPos = decode_scanWhitespace(s,startPos)
  base.assert(startPos<=string.len(s), 'Unterminated JSON encoded object found at position in [' .. s .. ']')
  local curChar = string.sub(s,startPos,startPos)
  -- Object
  if curChar=='{' then
    return decode_scanObject(s,startPos)
  end
  -- Array
  if curChar=='[' then
    return decode_scanArray(s,startPos)
  end
  -- Number
  if string.find("+-0123456789.e", curChar, 1, true) then
    return decode_scanNumber(s,startPos)
  end
  -- String
  if curChar==[["]] or curChar==[[']] then
    return decode_scanString(s,startPos)
  end
  if string.sub(s,startPos,startPos+1)=='/*' then
    return decode(s, decode_scanComment(s,startPos))
  end
  -- Otherwise, it must be a constant
  return decode_scanConstant(s,startPos)
end

--- The null function allows one to specify a null value in an associative array (which is otherwise
-- discarded if you set the value with 'nil' in Lua. Simply set t = { first=json.null }
function null()
  return null -- so json.null() will also return null ;-)
end



-----------------------------------------------------------------------------
-- Internal, PRIVATE functions.
-- Following a Python-like convention, I have prefixed all these 'PRIVATE'
-- functions with an underscore.
-----------------------------------------------------------------------------

--- Scans an array from JSON into a Lua object
-- startPos begins at the start of the array.
-- Returns the array and the next starting position
-- @param s The string being scanned.
-- @param startPos The starting position for the scan.
-- @return table, int The scanned array as a table, and the position of the next character to scan.
function decode_scanArray(s,startPos)
  local array = {}	-- The return value
  local stringLen = string.len(s)
  local object
  base.assert(string.sub(s,startPos,startPos)=='[','decode_scanArray called but array does not start at position ' .. startPos .. ' in string:\n'..s )
  startPos = startPos + 1
  -- Infinite loop for array elements
  repeat
    startPos = decode_scanWhitespace(s,startPos)
    base.assert(startPos<=stringLen,'JSON String ended unexpectedly scanning array.')
    local curChar = string.sub(s,startPos,startPos)
    if (curChar==']') then
      return array, startPos+1
    end
    if (curChar==',') then
      startPos = decode_scanWhitespace(s,startPos+1)
    end
    base.assert(startPos<=stringLen, 'JSON String ended unexpectedly scanning array.')
    object, startPos = decode(s,startPos)
    table.insert(array,object)
  until false
end

--- Scans a comment and discards the comment.
-- Returns the position of the next character following the comment.
-- @param string s The JSON string to scan.
-- @param int startPos The starting position of the comment
function decode_scanComment(s, startPos)
  base.assert( string.sub(s,startPos,startPos+1)=='/*', "decode_scanComment called but comment does not start at position " .. startPos)
  local endPos = string.find(s,'*/',startPos+2)
  base.assert(endPos~=nil, "Unterminated comment in string at " .. startPos)
  return endPos+2  
end

--- Scans for given constants: true, false or null
-- Returns the appropriate Lua type, and the position of the next character to read.
-- @param s The string being scanned.
-- @param startPos The position in the string at which to start scanning.
-- @return object, int The object (true, false or nil) and the position at which the next character should be 
-- scanned.
function decode_scanConstant(s, startPos)
  local consts = { ["true"] = true, ["false"] = false, ["null"] = nil }
  local constNames = {"true","false","null"}

  for i,k in base.pairs(constNames) do
    --print ("[" .. string.sub(s,startPos, startPos + string.len(k) -1) .."]", k)
    if string.sub(s,startPos, startPos + string.len(k) -1 )==k then
      return consts[k], startPos + string.len(k)
    end
  end
  base.assert(nil, 'Failed to scan constant from string ' .. s .. ' at starting position ' .. startPos)
end

--- Scans a number from the JSON encoded string.
-- (in fact, also is able to scan numeric +- eqns, which is not
-- in the JSON spec.)
-- Returns the number, and the position of the next character
-- after the number.
-- @param s The string being scanned.
-- @param startPos The position at which to start scanning.
-- @return number, int The extracted number and the position of the next character to scan.
function decode_scanNumber(s,startPos)
  local endPos = startPos+1
  local stringLen = string.len(s)
  local acceptableChars = "+-0123456789.e"
  while (string.find(acceptableChars, string.sub(s,endPos,endPos), 1, true)
	and endPos<=stringLen
	) do
    endPos = endPos + 1
  end
  local stringValue = 'return ' .. string.sub(s,startPos, endPos-1)
  local stringEval = base.loadstring(stringValue)
  base.assert(stringEval, 'Failed to scan number [ ' .. stringValue .. '] in JSON string at position ' .. startPos .. ' : ' .. endPos)
  return stringEval(), endPos
end

--- Scans a JSON object into a Lua object.
-- startPos begins at the start of the object.
-- Returns the object and the next starting position.
-- @param s The string being scanned.
-- @param startPos The starting position of the scan.
-- @return table, int The scanned object as a table and the position of the next character to scan.
function decode_scanObject(s,startPos)
  local object = {}
  local stringLen = string.len(s)
  local key, value
  base.assert(string.sub(s,startPos,startPos)=='{','decode_scanObject called but object does not start at position ' .. startPos .. ' in string:\n' .. s)
  startPos = startPos + 1
  repeat
    startPos = decode_scanWhitespace(s,startPos)
    base.assert(startPos<=stringLen, 'JSON string ended unexpectedly while scanning object.')
    local curChar = string.sub(s,startPos,startPos)
    if (curChar=='}') then
      return object,startPos+1
    end
    if (curChar==',') then
      startPos = decode_scanWhitespace(s,startPos+1)
    end
    base.assert(startPos<=stringLen, 'JSON string ended unexpectedly scanning object.')
    -- Scan the key
    key, startPos = decode(s,startPos)
    base.assert(startPos<=stringLen, 'JSON string ended unexpectedly searching for value of key ' .. key)
    startPos = decode_scanWhitespace(s,startPos)
    base.assert(startPos<=stringLen, 'JSON string ended unexpectedly searching for value of key ' .. key)
    base.assert(string.sub(s,startPos,startPos)==':','JSON object key-value assignment mal-formed at ' .. startPos)
    startPos = decode_scanWhitespace(s,startPos+1)
    base.assert(startPos<=stringLen, 'JSON string ended unexpectedly searching for value of key ' .. key)
    value, startPos = decode(s,startPos)
    object[key]=value
  until false	-- infinite loop while key-value pairs are found
end

--- Scans a JSON string from the opening inverted comma or single quote to the
-- end of the string.
-- Returns the string extracted as a Lua string,
-- and the position of the next non-string character
-- (after the closing inverted comma or single quote).
-- @param s The string being scanned.
-- @param startPos The starting position of the scan.
-- @return string, int The extracted string as a Lua string, and the next character to parse.
function decode_scanString(s,startPos)
  base.assert(startPos, 'decode_scanString(..) called without start position')
  local startChar = string.sub(s,startPos,startPos)
  base.assert(startChar==[[']] or startChar==[["]],'decode_scanString called for a non-string')
  local escaped = false
  local endPos = startPos + 1
  local bEnded = false
  local stringLen = string.len(s)
  repeat
    local curChar = string.sub(s,endPos,endPos)
    if not escaped then	
      if curChar==[[\]] then
        escaped = true
      else
        bEnded = curChar==startChar
      end
    else
      -- If we're escaped, we accept the current character come what may
      escaped = false
    end
    endPos = endPos + 1
    base.assert(endPos <= stringLen+1, "String decoding failed: unterminated string at position " .. endPos)
  until bEnded
  
  local mString = string.sub(s, startPos, endPos-1)
	local fromunicode = function(m)
		return string.char(tonumber(m, 16))
	end
	local mStringU = string.gsub(
		mString, 
		"\\u%x%x(%x%x)", 
		fromunicode)
        
  local stringValue = 'return ' .. mStringU
  local stringEval = base.loadstring(stringValue)
  base.assert(stringEval, 'Failed to load string [ ' .. stringValue .. '] in JSON4Lua.decode_scanString at position ' .. startPos .. ' : ' .. endPos)
  return stringEval(), endPos  
end

--- Scans a JSON string skipping all whitespace from the current start position.
-- Returns the position of the first non-whitespace character, or nil if the whole end of string is reached.
-- @param s The string being scanned
-- @param startPos The starting position where we should begin removing whitespace.
-- @return int The first position where non-whitespace was encountered, or string.len(s)+1 if the end of string
-- was reached.
function decode_scanWhitespace(s,startPos)
  local whitespace=" \n\r\t"
  local stringLen = string.len(s)
  while ( string.find(whitespace, string.sub(s,startPos,startPos), 1, true)  and startPos <= stringLen) do
    startPos = startPos + 1
  end
  return startPos
end

--- Encodes a string to be JSON-compatible.
-- This just involves back-quoting inverted commas, back-quotes and newlines, I think ;-)
-- @param s The string to return as a JSON encoded (i.e. backquoted string)
-- @return The string appropriately escaped.
function encodeString(s)
  s = string.gsub(s,'\\','\\\\')
  s = string.gsub(s,'"','\\"')
  s = string.gsub(s,"'","\\'")
  s = string.gsub(s,'\n','\\n')
  s = string.gsub(s,'\r','\\r')
  s = string.gsub(s,'\b','\\b')
  s = string.gsub(s,'\f','\\f')
  s = string.gsub(s,'\t','\\t')
  return s 
end

-- Determines whether the given Lua type is an array or a table / dictionary.
-- We consider any table an array if it has indexes 1..n for its n items, and no
-- other data in the table.
-- I think this method is currently a little 'flaky', but can't think of a good way around it yet...
-- @param t The table to evaluate as an array
-- @return boolean, number True if the table can be represented as an array, false otherwise. If true,
-- the second returned value is the maximum
-- number of indexed elements in the array. 
function isArray(t)
  -- Next we count all the elements, ensuring that any non-indexed elements are not-encodable 
  -- (with the possible exception of 'n')
  local maxIndex = 0
  for k,v in base.pairs(t) do
    if (base.type(k)=='number' and math.floor(k)==k and 1<=k) then	-- k,v is an indexed pair
      if (not isEncodable(v)) then return false end	-- All array elements must be encodable
      maxIndex = math.max(maxIndex,k)
    else
      if (k=='n') then
        if v ~= table.getn(t) then return false end  -- False if n does not hold the number of elements
      else -- Else of (k=='n')
        if isEncodable(v) then return false end
      end  -- End of (k~='n')
    end -- End of k,v not an indexed pair
  end  -- End of loop across all pairs
  return true, maxIndex
end

--- Determines whether the given Lua object / table / variable can be JSON encoded. The only
-- types that are JSON encodable are: string, boolean, number, nil, table and json.null.
-- In this implementation, all other types are ignored.
-- @param o The object to examine.
-- @return boolean True if the object should be JSON encoded, false if it should be ignored.
function isEncodable(o)
  local t = base.type(o)
  return (t=='string' or t=='boolean' or t=='number' or t=='nil' or t=='table') or (t=='function' and o==null) 
end


-- public interface:
json.null = null
json.encode = encode
json.decode = decode
return json

--===========================================================================
end
}
_LOADED['p15util'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
local hex = require "hex"
local util = require "utility"
local repr = util.repr
local t = {}
require "der"

function t.parse_der_integer(value)
    if not value then
        return value
    end
   value = string.sub(string.rep("\000", 4 - string.len(value)) .. value, -4, -1)
   return bin.unpack("%>%L", value)
end

function t.build_der_integer(value)
    if not value then
        return ""
    end
    local pad = ""
    if value < 256 then
        if value > 127 then pad ="\000" end
        return pad .. string.char(value)
    end
    if value < 65536 then
        if value > 32767 then pad ="\000" end
        return pad .. hex.hexf("%>%H", value)
    end
    if value < 16777216 then
        if value > 8388607 then pad ="\000" end
        return pad .. string.sub(hex.hexf("%>%L", value), -3, -1)
    end
    if value > 2147483647 then pad ="\000" end
    return pad .. hex.hexf("%>%L", value)
end

function t.parseUnusedSpace(value)
--  SEQUENCE {   UnusedSpace
    --  SEQUENCE { path
        --  OCTET STRING { 3F 00 50 00 50 50 } efidOrPath
        --  INTEGER { 0 }  index
        --  [CONTEXT-SPECIFIC 0] { 03 00 } length
    --  }
    --  OCTET STRING { 81 }  authId
    --  INTEGER { 3 } keyReference
--  }
    local UnusedSpace
    local res = {}
    local seq1, seq2, s
    local seq1 = der.parse(value)
    for i=1,table.getn(seq1) do
        if seq1[i].tag == 0 then
            break
        end
        UnusedSpace = {}
        s = der.parse(seq1[i].value)
        seq2 = der.parse(s[1].value)
        UnusedSpace.path = {}
        UnusedSpace.path_tag = s[1].tag
        UnusedSpace.path.efidOrPath = seq2[1] and seq2[1].value
        UnusedSpace.path.efidOrPath_tag = seq2[1] and seq2[1].tag
        UnusedSpace.path.index = seq2[2] and t.parse_der_integer(seq2[2].value)
        UnusedSpace.path.index_tag = seq2[2] and seq2[2].tag
        
        UnusedSpace.path.length = seq2[3] and t.parse_der_integer(seq2[3].value)
        UnusedSpace.path.length_tag = seq2[3] and seq2[3].tag
        
        UnusedSpace.authId = s[2] and s[2].value
        UnusedSpace.authId_tag = s[2] and s[2].tag
        UnusedSpace.keyReference = s[3] and t.parse_der_integer(s[3].value)
        UnusedSpace.keyReference_tag = s[3] and s[3].tag
        
        res[i] = UnusedSpace
    end
    return res
end


function t.buildUnusedSpace(UnusedSpaces)
    local res = ""
    for i=1,table.getn(UnusedSpaces) do
        local UnusedSpace = UnusedSpaces[i]
        local path = UnusedSpace.path
        
        path.index_tag = path.index_tag or der.INTEGER
        path.efidOrPath_tag = path.efidOrPath_tag or der.STRING
        path.length_tag = path.length_tag or der.CONTEXT_SPECIFIC(0)
        UnusedSpace.authId_tag = UnusedSpace.authId_tag or der.STRING
        UnusedSpace.path_tag = UnusedSpace.path_tag or der.SEQUENCE
        UnusedSpace.keyReference_tag = UnusedSpace.keyReference_tag or der.INTEGER
        
        local efidOrPathD = der.build(path.efidOrPath_tag, path.efidOrPath) or ""
        local indexD = path.index and der.build(path.index_tag, t.build_der_integer(path.index)) or ""
        local lengthD = path.length and der.build(path.length_tag, t.build_der_integer(path.length)) or ""
        local pathD = der.build(UnusedSpace.path_tag, efidOrPathD .. indexD .. lengthD)
        
        local authId = UnusedSpace.authId and der.build(UnusedSpace.authId_tag, UnusedSpace.authId) or ""
        local keyReference = UnusedSpace.keyReference and der.build(UnusedSpace.keyReference_tag, t.build_der_integer(UnusedSpace.keyReference))  or ""
        local UnusedSpaceD = der.build(der.SEQUENCE, pathD .. authId .. keyReference)

        res = res .. UnusedSpaceD
    end

    return res
end


function t.parseKeyContainers(value)
--  SEQUENCE {
    --  SEQUENCE { commonObjectAttributes
        --  UTF8STRING { "RSA Private 1-2048-Dec-Sig" } label
        --  BIT STRING { 06 C0 } flags
        --  OCTET STRING { 81 } authId
        --  INTEGER { 1 }   userConsent opzionale
    --  }
    --  SEQUENCE { classAttributes
        --  OCTET STRING { 52 53 41 20 70 72 6B 20 31 } iD
        --  BIT STRING { 02 74 } usage
        --  BIT STRING { 04 B0 } accessFlags
        --  INTEGER { 3 } keyReference
    --  }
    --  [CONTEXT-SPECIFIC 0] { }
    --  [CONTEXT-SPECIFIC 1] { typeAttributes
        --  SEQUENCE { 
            --  SEQUENCE { path
                --  OCTET STRING { } efidOrPath
            --  }
            --  INTEGER { 2048 } modulusLength
        --  }
    --  }
--  }
    local KeyContainer
    local res = {}
    local seq1, seq2, s, seq3, seq4
    local seq1 = der.parse(value) -- decode PrivateKeyChoice sequence
    for i=1,table.getn(seq1) do
        KeyContainer = {}
        if seq1[i].tag == 0 then
            break
        end
        s = der.parse(seq1[i].value)
        
        seq2 = der.parse(s[1].value)
        local commonObjectAttributes = {}
        KeyContainer.commonObjectAttributes_tag = s[1].tag
        commonObjectAttributes.label = seq2[1] and seq2[1].value
        commonObjectAttributes.label_tag = seq2[1] and seq2[1].tag
        commonObjectAttributes.flags = seq2[2] and seq2[2].value
        commonObjectAttributes.flags_tag = seq2[2] and seq2[2].tag
        commonObjectAttributes.authId = seq2[3] and seq2[3].value
        commonObjectAttributes.authId_tag = seq2[3] and seq2[3].tag
        commonObjectAttributes.userConsent = seq2[4] and t.parse_der_integer(seq2[4].value)
        commonObjectAttributes.userConsent_tag = seq2[4] and seq2[4].tag

        KeyContainer.commonObjectAttributes = commonObjectAttributes
        
        seq2 = der.parse(s[2].value)
        local classAttributes = {}
        KeyContainer.classAttributes_tag = s[2].tag
        classAttributes.iD = seq2[1] and seq2[1].value
        classAttributes.iD_tag = seq2[1] and seq2[1].tag
        classAttributes.usage = seq2[2] and seq2[2].value
        classAttributes.usage_tag = seq2[2] and seq2[2].tag
        classAttributes.accessFlags = seq2[3] and seq2[3].value
        classAttributes.accessFlags_tag = seq2[3] and seq2[3].tag
        classAttributes.keyReference = seq2[4] and t.parse_der_integer(seq2[4].value)
        classAttributes.keyReference_tag = seq2[4] and seq2[4].tag
        
        
        KeyContainer.classAttributes = classAttributes
       
        local i = 3
        -- s[3] contiene "[CONTEXT-SPECIFIC 0] { }"
        if (s[i].tag == tonumber("a0", 16)) then
            i = 4
        end
        
        seq2 = der.parse(s[i].value)
        local typeAttributes = {}
        KeyContainer.typeAttributes_tag = s[i].tag
        
        seq3 = der.parse(seq2[1].value)
        typeAttributes.path = {}
        typeAttributes.path_tag = seq3[1].tag
        
        seq4 = der.parse(seq3[1].value)
        
        typeAttributes.path.efidOrPath = seq4[1] and seq4[1].value
        typeAttributes.path.efidOrPath_tag = seq4[1] and seq4[1].tag

        typeAttributes.modulusLength = seq3[2] and t.parse_der_integer(seq3[2].value)
        typeAttributes.modulusLength_tag = seq3[2] and seq3[2].tag
        KeyContainer.typeAttributes = typeAttributes
        
        res[i] = KeyContainer
    end
    return res
end

function t.parseAuthObjects(value)
--  SEQUENCE {
    --  SEQUENCE {
        --  UTF8STRING { "User PIN" }   label
        --  BIT STRING { 06 C0 }        flags
        --  OCTET STRING { 82 }         authId
    --  }
    --  SEQUENCE {
        --  OCTET STRING { 81 }         authId
    --  }
    --  [CONTEXT-SPECIFIC 1] {
        --  SEQUENCE {
            --  BIT STRING { 04 8C 10 }  pwdFlags
            --  ENUMERATED { 02 }        pwdType
            --  INTEGER { 6 }            minLength
            --  INTEGER { 16 }           storedLength
            -- INTEGER OPTIONAL         maxLength,
            --  [CONTEXT-SPECIFIC 0] OPTIONAL { 00 81 }   pwdReference
            --  OCTET STRING { 00 } OPTIONAL             padChar
        --  }
    --  }
--  }

    local authObj
    local res = {}
    local seq1, seq2, s, seq3
    local seq1 = der.parse(value) -- decode PrivateKeyChoice sequence
    -- print (repr(seq1))
    for i=1,table.getn(seq1) do
        authObj = {}
        if seq1[i].tag == 0 then
            break
        end
        
        if seq1[i].tag ~= der.SEQUENCE then
            authObj._raw_der = der.build(seq1[i].tag, seq1[i].value)
            res[i] = authObj
        else
        
            s = der.parse(seq1[i].value)
            -- print (repr(s))
            
            seq2 = der.parse(s[1].value)
            local commonObjectAttributes = {}
            authObj.commonObjectAttributes_tag = s[1].tag
            -- commonObjectAttributes.label = seq2[1] and seq2[1].value
            -- commonObjectAttributes.label_tag = seq2[1] and seq2[1].tag
            -- commonObjectAttributes.flags = seq2[2] and seq2[2].value
            -- commonObjectAttributes.flags_tag = seq2[2] and seq2[2].tag
            -- commonObjectAttributes.authId = seq2[3] and seq2[3].value
            -- commonObjectAttributes.authId_tag = seq2[3] and seq2[3].tag
            
            t.parseCommonObjectAttributes(seq2, commonObjectAttributes)
            authObj.commonObjectAttributes = commonObjectAttributes
            
            seq2 = der.parse(s[2].value)
            local classAttributes = {}
            authObj.classAttributes_tag = s[2].tag
            classAttributes.authId = seq2[1] and seq2[1].value
            classAttributes.authId_tag = seq2[1] and seq2[1].tag
            authObj.classAttributes = classAttributes
           
            -- s[3] contiene "[CONTEXT-SPECIFIC 0] { }"
            if s[3] and not s[4] then
                s[4] = s[3]
            end
            if s[4] then
                local c
                seq2 = der.parse(s[4].value)
                local typeAttributes = {}
                authObj.typeAttributes_tag = s[4].tag
                
                seq3 = der.parse(seq2[1].value)
                typeAttributes = {}
                
                typeAttributes.pwdFlags = seq3[1] and seq3[1].value
                typeAttributes.pwdFlags_tag = seq3[1] and seq3[1].tag

                typeAttributes.pwdType = seq3[2] and t.parse_der_integer(seq3[2].value)
                typeAttributes.pwdType_tag = seq3[2] and seq3[2].tag

                typeAttributes.minLength = seq3[3] and t.parse_der_integer(seq3[3].value)
                typeAttributes.minLength_tag = seq3[3] and seq3[3].tag
                
                typeAttributes.storedLength = seq3[4] and t.parse_der_integer(seq3[4].value)
                typeAttributes.storedLength_tag = seq3[4] and seq3[4].tag
                
                -- valori opzionali
                c = 5
                if seq3[c] and seq3[c].tag == der.INTEGER then
                    typeAttributes.maxLength = seq3[c] and t.parse_der_integer(seq3[c].value)
                    typeAttributes.maxLength_tag = seq3[c] and seq3[c].tag
                    c = c+1
                end
                if seq3[c] and seq3[c].tag == der.CONTEXT_SPECIFIC(0) then
                    typeAttributes.pwdReference = seq3[c] and t.parse_der_integer(seq3[c].value)
                    typeAttributes.pwdReference_tag = seq3[c] and seq3[c].tag
                    c = c+1
                end
                if seq3[c] and seq3[c].tag == der.STRING then
                    typeAttributes.padChar = seq3[c] and seq3[c].value
                    typeAttributes.padChar_tag = seq3[c] and seq3[c].tag
                    c = c+1
                end
                
                authObj.typeAttributes = typeAttributes
            end
            res[i] = authObj
        end
    end
    return res
end


function t.buildAuthObjects(KeyContainers)
--  SEQUENCE {
    --  SEQUENCE {
        --  UTF8STRING { "User PIN" }   label
        --  BIT STRING { 06 C0 }        flags
        --  OCTET STRING { 82 }         authId
    --  }
    --  SEQUENCE {
        --  OCTET STRING { 81 }         authId
    --  }
    --  [CONTEXT-SPECIFIC 1] {
        --  SEQUENCE {
            --  BIT STRING { 04 8C 10 }  pwdFlags
            --  ENUMERATED { 02 }        pwdType
            --  INTEGER { 6 }            minLength
            --  INTEGER { 16 }           storedLength
            --  [CONTEXT-SPECIFIC 0] { 00 81 }   pwdReference
            --  OCTET STRING { 00 }              padChar
        --  }
    --  }
--  }
    local res = ""
    for i=1,table.getn(KeyContainers) do
        local KeyContainer = KeyContainers[i]
        local commonObjectAttributes = KeyContainer.commonObjectAttributes
        local classAttributes = KeyContainer.classAttributes
        local typeAttributes = KeyContainer.typeAttributes

        if type(KeyContainer._raw_der) == "string" then
            res = res .. KeyContainer._raw_der
        else
            
            KeyContainer.commonObjectAttributes_tag = KeyContainer.commonObjectAttributes_tag or der.SEQUENCE
            KeyContainer.classAttributes_tag = KeyContainer.classAttributes_tag or der.SEQUENCE
            KeyContainer.typeAttributes_tag = KeyContainer.typeAttributes_tag or der.CONTEXT(1)
            
            commonObjectAttributes.label_tag = commonObjectAttributes.label_tag or der.UTF8STRING
            commonObjectAttributes.flags_tag = commonObjectAttributes.flags_tag or der.BIT_STRING
            commonObjectAttributes.authId_tag = commonObjectAttributes.authId_tag or der.STRING
            
            classAttributes.authId_tag = classAttributes.authId_tag or der.INTEGER
            
            typeAttributes.pwdFlags_tag = typeAttributes.pwdFlags_tag or der.BIT_STRING
            typeAttributes.pwdType_tag = commonObjectAttributes.pwdType_tag or der.ENUMERATED
            typeAttributes.minLength_tag = commonObjectAttributes.minLength_tag or der.INTEGER
            typeAttributes.storedLength_tag = commonObjectAttributes.storedLength_tag or der.INTEGER
            typeAttributes.maxLength_tag = commonObjectAttributes.maxLength_tag or der.INTEGER
            typeAttributes.pwdReference_tag = commonObjectAttributes.pwdReference_tag or der.CONTEXT_SPECIFIC(0)
            typeAttributes.padChar_tag = commonObjectAttributes.padChar_tag or der.STRING
            
            local labelD = commonObjectAttributes.label and der.build(commonObjectAttributes.label_tag, commonObjectAttributes.label) or ""
            local flagsD = commonObjectAttributes.flags and der.build(commonObjectAttributes.flags_tag, commonObjectAttributes.flags) or ""
            local authIdD = commonObjectAttributes.authId and der.build(commonObjectAttributes.authId_tag, commonObjectAttributes.authId) or ""
            
            local commonObjectAttributesD = der.build(KeyContainer.commonObjectAttributes_tag,
                    labelD .. flagsD .. authIdD)
            
            local authIdD = classAttributes.authId and der.build(classAttributes.authId_tag, classAttributes.authId) or ""
            
            local classAttributesD = der.build(KeyContainer.classAttributes_tag,
                    authIdD)
            
            local pwdFlagsD = typeAttributes.pwdFlags and der.build(typeAttributes.pwdFlags_tag, typeAttributes.pwdFlags) or ""
            local pwdTypeD = typeAttributes.pwdType and der.build(typeAttributes.pwdType_tag, t.build_der_integer(typeAttributes.pwdType)) or ""
            local minLengthD = typeAttributes.minLength and der.build(typeAttributes.minLength_tag, t.build_der_integer(typeAttributes.minLength)) or ""
            local storedLengthD = typeAttributes.storedLength and der.build(typeAttributes.storedLength_tag, t.build_der_integer(typeAttributes.storedLength)) or ""
            local maxLengthD = typeAttributes.maxLength and der.build(typeAttributes.maxLength_tag, t.build_der_integer(typeAttributes.maxLength)) or ""
            local pwdReferenceD = typeAttributes.pwdReference and der.build(typeAttributes.pwdReference_tag, t.build_der_integer(typeAttributes.pwdReference)) or ""
            local padCharD = typeAttributes.padChar and der.build(typeAttributes.padChar_tag, typeAttributes.padChar) or ""
            
            local typeAttributesDseq = der.build(der.SEQUENCE, 
                        pwdFlagsD .. pwdTypeD .. minLengthD .. storedLengthD .. maxLengthD .. pwdReferenceD .. padCharD)
            -- log.output ("typeAttributesDseq", hex.hexify(typeAttributesDseq))
            
            local typeAttributesD = der.build(KeyContainer.typeAttributes_tag, typeAttributesDseq)
            -- log.output ("typeAttributesD", hex.hexify(typeAttributesD))

            local KeyContainerD = der.build(der.SEQUENCE, commonObjectAttributesD .. classAttributesD .. typeAttributesD)
            res = res .. KeyContainerD
        end
        
    end

    return res
end

function t.parseCommonObjectAttributes(seq2, commonObjectAttributes)
    local j=1
    local seq3, seq4, acr
    if seq2[j] and seq2[j].tag == der.UTF8STRING then
        commonObjectAttributes.label = seq2[j].value
        commonObjectAttributes.label_tag = seq2[j].tag
        j = j+1
    end
    
    if seq2[j] and seq2[j].tag == der.BIT_STRING then
        commonObjectAttributes.flags = seq2[j].value
        commonObjectAttributes.flags_tag = seq2[j].tag
        j = j+1
    end
    
    if seq2[j] and seq2[j].tag == der.STRING then
        commonObjectAttributes.authId = seq2[j].value
        commonObjectAttributes.authId_tag = seq2[j].tag
        j = j+1
    end

    if seq2[j] and seq2[j].tag == der.INTEGER then
        commonObjectAttributes.userConsent = t.parse_der_integer(seq2[j].value)
        commonObjectAttributes.userConsent_tag = seq2[j].tag
        j = j+1
    end

    if seq2[j] and seq2[j].tag == der.SEQUENCE then
        commonObjectAttributes.accessControlRules_der = seq2[j].value
        commonObjectAttributes.accessControlRules_tag = seq2[j].tag
        seq3 = der.parse(seq2[j].value)
        commonObjectAttributes.accessControlRules = {}
        for n=1,table.getn(seq3) do
            if seq3[n] and seq3[n].tag == der.SEQUENCE then
                seq4 = der.parse(seq3[n].value)
                if seq4[1].tag == der.BIT_STRING and (seq4  [2].tag == der.SEQUENCE or seq4[2].tag == der.STRING or seq4[2].tag == der.NULL) then
                    acr = {accessMode=seq4[1].value,
                                accessMode_tag=seq4[1].tag,
                                securityCondition=seq4[2].value,
                                securityCondition_tag=seq4[2].tag,}
                    table.insert(commonObjectAttributes.accessControlRules, acr)
                end
            end
        end
        j = j+1
    end
end

function t.parsePubPrivKD(value)
--  SEQUENCE { privateRSAKey oppure publicRSAKey
    --  SEQUENCE { commonObjectAttributes
        --  UTF8STRING { "Nicolas BATAILLE's gemsafe2003ca ID" } label
        --  BIT STRING { 06 C0 } flags
        --  OCTET STRING { 81 } authId opzionale per le pubKey
        -- userConsent INTEGER (1..cia-ub-userConsent) OPTIONAL,
        -- accessControlRules SEQUENCE SIZE (1..MAX) OF AccessControlRule OPTIONAL,
    --  }
    --  SEQUENCE { classAttributes
        --  OCTET STRING { 5F 7A 2F 11 BB A3 97 43 4D ED A3 14 7C A1 E6 3D 87
            --  1C 3C 6D } iD
        --  BIT STRING { 02 74 } usage
        -- BOOLEAN native
        --  BIT STRING { 04 B0 } accessFlags
        --  INTEGER { 12 } keyReference
    --  }
    --  [CONTEXT-SPECIFIC 0] { } subClassAttributes OPTIONAL
    --  [CONTEXT-SPECIFIC 1] { typeAttributes
        --  SEQUENCE {
            --  SEQUENCE { path
                --  OCTET STRING { } efidOrPath
            --  }
            -- CHOICE { -- GAM: JCOP ECC support (experimental)
            --  INTEGER { 1024 } modulusLength
            --  SEQUENCE { OID parameters, ... }
            -- }
        --  }
    --  }
--  }
    local KeyContainer
    local res = {}
    local seq1, seq2, s, seq3, seq4
    local seq1 = der.parse(value) -- decode PrivateKeyChoice sequence
    log.output ("parsePubPrivKD")
    log.output ("seq1:", repr(seq1))
    for i=1,table.getn(seq1) do
        KeyContainer = {}
        if seq1[i].tag == 0 then
            break
        end
        s = der.parse(seq1[i].value)
        log.output ("s:", repr(s))
        seq2 = der.parse(s[1].value)
        log.output ("seq2-1:", repr(seq2))
        local commonObjectAttributes = {}
        
        KeyContainer.commonObjectAttributes_tag = s[1].tag
        KeyContainer.tag = seq1[i].tag
        
        t.parseCommonObjectAttributes(seq2, commonObjectAttributes)
        
        KeyContainer.commonObjectAttributes = commonObjectAttributes
        
        seq2 = der.parse(s[2].value)
        log.output ("seq2-2:", repr(seq2))
        local classAttributes = {}
        local j=1
        KeyContainer.classAttributes_tag = s[2].tag
        if seq2[j] and seq2[j].tag == der.STRING then
            classAttributes.iD = seq2[j].value
            classAttributes.iD_tag = seq2[j].tag
            j = j+1
        end
        classAttributes.iD = classAttributes.iD or ""
        
        if seq2[j] and seq2[j].tag == der.BIT_STRING then
            classAttributes.usage = seq2[j].value
            classAttributes.usage_tag = seq2[j].tag
            j = j+1
        end
        
        if seq2[j] and seq2[j].tag == der.BOOLEAN then
            classAttributes.native = seq2[j].value
            classAttributes.native_tag = seq2[j].tag
            j = j+1
        end
        
        if seq2[j] and seq2[j].tag == der.BIT_STRING then
            classAttributes.accessFlags = seq2[j].value
            classAttributes.accessFlags_tag = seq2[j].tag
            j = j+1
        end
        if seq2[j] and seq2[j].tag == der.INTEGER then
            classAttributes.keyReference = t.parse_der_integer(seq2[j].value)
            classAttributes.keyReference_tag = seq2[j].tag
            j = j+1
        end
        if seq2[j] and seq2[j].tag == der.GENERALIZEDTIME then
            classAttributes.startDate = seq2[j].value
            classAttributes.startDate_tag = seq2[j].tag
            j = j+1
        end
        if seq2[j] and seq2[j].tag == der.CONTEXT_SPECIFIC(0) then
            classAttributes.endDate = seq2[j].value
            classAttributes.endDate_tag = seq2[j].tag
            j = j+1
        end
        if seq2[j] and seq2[j].tag == der.CONTEXT(1) then
            classAttributes.algReference_der = seq2[j].value
            classAttributes.algReference_tag = seq2[j].tag
            j = j+1
        end
        
        KeyContainer.classAttributes = classAttributes
       
        -- s[3] contiene "[CONTEXT-SPECIFIC 0] { }"
        if s[3] and not s[4] then
            s[4] = s[3]
        else
            KeyContainer.subClassAttributes = s[3]
        end
        seq2 = der.parse(s[4].value)
        log.output ("seq2-4:", repr(seq2))
        local typeAttributes = {}
        KeyContainer.typeAttributes_tag = s[4].tag
        
        seq3 = der.parse(seq2[1].value)
        typeAttributes.path = {}
        typeAttributes.path_tag = seq3[1].tag
        
        seq4 = der.parse(seq3[1].value)
        
        typeAttributes.path.efidOrPath = seq4[1] and seq4[1].value
        typeAttributes.path.efidOrPath_tag = seq4[1] and seq4[1].tag

        if seq3[2] and seq3[2].tag == der.SEQUENCE then
            -- -- GAM: JCOP3 ECC SUPPORT: ECC parameters (DER ENCODED OID, such as "06082A8648CE3D030107" -> "1.2.840.10045.3.1.7" )
            typeAttributes.parameters = seq3[2] and seq3[2].value
            typeAttributes.parameters_tag = seq3[2] and seq3[2].tag
        else
            typeAttributes.modulusLength = seq3[2] and t.parse_der_integer(seq3[2].value)
            typeAttributes.modulusLength_tag = seq3[2] and seq3[2].tag
        end
        KeyContainer.typeAttributes = typeAttributes
        
        res[i] = KeyContainer
        
        -- print("KeyContainer", i, repr(KeyContainer))
    end
    --print ("original key container:", hex.hexify(value))
    --print ("rebuilt key container:", hex.hexify(t.buildPubPrivKD(res)))
    return res
end


function t.buildPubPrivKD(KeyContainers, defaults)
--  SEQUENCE { privateRSAKey oppure publicRSAKey
    --  SEQUENCE { commonObjectAttributes
        --  UTF8STRING { "Nicolas BATAILLE's gemsafe2003ca ID" } label
        --  BIT STRING { 06 C0 } flags
        --  OCTET STRING { 81 } authId opzionale per le pubKey
        -- userConsent INTEGER (1..cia-ub-userConsent) OPTIONAL,
        -- accessControlRules SEQUENCE SIZE (1..MAX) OF AccessControlRule OPTIONAL,

    --  }
    --  SEQUENCE { classAttributes
        --  OCTET STRING { 5F 7A 2F 11 BB A3 97 43 4D ED A3 14 7C A1 E6 3D 87
            --  1C 3C 6D } iD
        --  BIT STRING { 02 74 } usage
        -- BOOLEAN native
        --  BIT STRING { 04 B0 } accessFlags
        --  INTEGER { 12 } keyReference
    --  }
    --  [CONTEXT-SPECIFIC 0] { } subClassAttributes OPTIONAL
    --  [CONTEXT-SPECIFIC 1] { typeAttributes
        --  SEQUENCE {
            --  SEQUENCE { path
                --  OCTET STRING { } efidOrPath
            --  }
            -- CHOICE { -- GAM: JCOP ECC support (experimental)
            --  INTEGER { 1024 } modulusLength
            --  SEQUENCE { OID parameters, ... }
            -- }
        --  }
    --  }
--  }
    defaults = defaults or {}
    local res = ""
    for i=1,table.getn(KeyContainers) do
        local KeyContainer = KeyContainers[i]
        local commonObjectAttributes = KeyContainer.commonObjectAttributes
        local classAttributes = KeyContainer.classAttributes
        local typeAttributes = KeyContainer.typeAttributes
        local path = typeAttributes.path
        
        
        
        KeyContainer.commonObjectAttributes_tag = KeyContainer.commonObjectAttributes_tag or der.SEQUENCE
        KeyContainer.classAttributes_tag = KeyContainer.classAttributes_tag or der.SEQUENCE
        KeyContainer.typeAttributes_tag = KeyContainer.typeAttributes_tag or der.CONTEXT(1)
        
        commonObjectAttributes.label_tag = commonObjectAttributes.label_tag or der.UTF8STRING
        commonObjectAttributes.flags_tag = commonObjectAttributes.flags_tag or der.BIT_STRING
        commonObjectAttributes.authId_tag = commonObjectAttributes.authId_tag or der.STRING
        commonObjectAttributes.userConsent_tag = commonObjectAttributes.userConsent_tag or der.INTEGER
        commonObjectAttributes.accessControlRules_tag = commonObjectAttributes.accessControlRules_tag or der.SEQUENCE
        
        classAttributes.iD_tag = classAttributes.iD_tag or der.STRING
        classAttributes.usage_tag = classAttributes.usage_tag or der.BIT_STRING
        classAttributes.accessFlags_tag = classAttributes.accessFlags_tag or der.BIT_STRING
        classAttributes.keyReference_tag = classAttributes.keyReference_tag or der.INTEGER
        
        typeAttributes.path_tag = typeAttributes.path_tag or der.SEQUENCE
        path.efidOrPath_tag = path.efidOrPath_tag or der.STRING
        typeAttributes.modulusLength_tag = typeAttributes.modulusLength_tag or der.INTEGER

        commonObjectAttributes.label = commonObjectAttributes.label or ""
        commonObjectAttributes.flags = commonObjectAttributes.flags or "\000\000"

        local labelD = commonObjectAttributes.label and der.build(commonObjectAttributes.label_tag, commonObjectAttributes.label) or ""
        local flagsD = commonObjectAttributes.flags and der.build(commonObjectAttributes.flags_tag, commonObjectAttributes.flags) or ""
        local authIdD = commonObjectAttributes.authId and der.build(commonObjectAttributes.authId_tag, commonObjectAttributes.authId) or ""
        local userConsentD = commonObjectAttributes.userConsent and der.build(commonObjectAttributes.userConsent_tag, t.build_der_integer(commonObjectAttributes.userConsent)) or ""

        local accessControlRulesD = ""
        if commonObjectAttributes.accessControlRules then
            local acrs = {}
            for k=1,table.getn(commonObjectAttributes.accessControlRules) do
                local acr = commonObjectAttributes.accessControlRules[k]
                local acrD = der.build(acr.accessMode_tag, acr.accessMode)
                             .. der.build(acr.securityCondition_tag, acr.securityCondition)
                table.insert(acrs, der.build(der.SEQUENCE, acrD))
            end
            accessControlRulesD = der.build(commonObjectAttributes.accessControlRules_tag, table.concat(acrs, ""))
            commonObjectAttributes.accessControlRules_der = accessControlRulesD
        end
        
        local commonObjectAttributesD = der.build(KeyContainer.commonObjectAttributes_tag,
                labelD .. flagsD .. authIdD .. userConsentD .. accessControlRulesD)

        classAttributes.iD = classAttributes.iD or ""
        classAttributes.usage = classAttributes.usage or hex.hexf("0000")
        classAttributes.accessFlags = classAttributes.accessFlags or hex.hexf("0000")
        
        local iDD = der.build(classAttributes.iD_tag, classAttributes.iD) or ""
        
        local usageD = der.build(classAttributes.usage_tag, classAttributes.usage) or ""
        local accessFlagsD = der.build(classAttributes.accessFlags_tag, classAttributes.accessFlags) or ""
        local keyReferenceD = classAttributes.keyReference and der.build(classAttributes.keyReference_tag, t.build_der_integer(classAttributes.keyReference)) or ""
        
        local nativeD = ""
        if classAttributes.native_tag then
            nativeD = der.build(classAttributes.native_tag, classAttributes.native) or ""
        end
        local classAttributesD = der.build(KeyContainer.classAttributes_tag,
                iDD .. usageD ..  nativeD .. accessFlagsD .. keyReferenceD)
        
        
        
        local efidOrPathD = der.build(path.efidOrPath_tag, path.efidOrPath) or ""
        local pathD = der.build(typeAttributes.path_tag, efidOrPathD)

        -- log.output ("pathD", hex.hexify(pathD))
        local modulusLengthOrParamsD = ""
        
        if typeAttributes.parameters then
            -- GAM: JCOP3 ECC SUPPORT: ECC parameters (DER ENCODED OID, such as "06082A8648CE3D030107" -> "1.2.840.10045.3.1.7" )
            modulusLengthOrParamsD = der.build(typeAttributes.parameters_tag or der.SEQUENCE, typeAttributes.parameters)
        else
            modulusLengthOrParamsD = typeAttributes.modulusLength and der.build(typeAttributes.modulusLength_tag, t.build_der_integer(typeAttributes.modulusLength)) or ""
        end
        -- log.output ("modulusLengthOrParamsD", hex.hexify(modulusLengthOrParamsD))
        
        local typeAttributesDseq = der.build(der.SEQUENCE, pathD .. modulusLengthOrParamsD)
        -- log.output ("typeAttributesDseq", hex.hexify(typeAttributesDseq))
        
        local typeAttributesD = der.build(KeyContainer.typeAttributes_tag, typeAttributesDseq)
        -- log.output ("typeAttributesD", hex.hexify(typeAttributesD))

        -- [CONTEXT-SPECIFIC 0] { }
        local cs0 = ""
        local subClassAttributes = KeyContainer.subClassAttributes or defaults.subClassAttributes
        if subClassAttributes then
            cs0 = subClassAttributes.value and der.build(subClassAttributes.tag, subClassAttributes.value) or ""
        else
            cs0 = hex.hexf("a000")
        end
        local KeyContainerD = der.build(KeyContainer.tag or der.SEQUENCE, commonObjectAttributesD .. classAttributesD .. cs0 .. typeAttributesD)
        res = res .. KeyContainerD
    end

    return res
end



function t.parseCertDF(value)
-- SEQUENCE { x509Certificate
    --  SEQUENCE { commonObjectAttributes
        --  UTF8STRING { "Nicolas BATAILLE's gemsafe2003ca ID" } label
        --  BIT STRING { 06 40 } flags
        --  OCTET STRING { 81 } authId opzionale
    --  }
    --  SEQUENCE { classAttributes -- CommonCertificateAttributes
        --  OCTET STRING { 5F 7A 2F 11 BB A3 97 43 4D ED A3 14 7C A1 E6 3D 87
        --      1C 3C 6D } iD
        -- authority BOOLEAN DEFAULT FALSE
    --  }
    --  [CONTEXT-SPECIFIC 0] { subClassAttributes OPTIONAL - NULL/NONE
    -- }
    --  [CONTEXT-SPECIFIC 1] { typeAttributes -- X509CertificateAttributes
        --  SEQUENCE {
            --  SEQUENCE { path
                --  OCTET STRING { 3F 00 50 00 50 40 } efidOrPath
                --  INTEGER { 0 } index
                --  [CONTEXT-SPECIFIC 0] { 07 06 } length
            --  }
            -- subject  		Name OPTIONAL, // SEQUENCE{...}
            -- issuer 		[0] Name OPTIONAL,  // SEQUENCE{...}
            -- serialNumber 	CertificateSerialNumber OPTIONAL,  // INTEGER
        --  }
    --  }
--  }
    
    local KeyContainer
    local res = {}
    local seq1, seq2, s, seq3, seq4
    local seq1 = der.parse(value) -- decode PrivateKeyChoice sequence
    for i=1,table.getn(seq1) do
        
        KeyContainer = {}
        if seq1[i].tag == 0 then
            break
        end
        s = der.parse(seq1[i].value)
        
        seq2 = der.parse(s[1].value)
        local commonObjectAttributes = {}
        -- KeyContainer.commonObjectAttributes_tag = s[1].tag
        -- commonObjectAttributes.label = seq2[1] and seq2[1].value
        -- commonObjectAttributes.label_tag = seq2[1] and seq2[1].tag
        -- commonObjectAttributes.flags = seq2[2] and seq2[2].value
        -- commonObjectAttributes.flags_tag = seq2[2] and seq2[2].tag
        -- commonObjectAttributes.authId = seq2[3] and seq2[3].value
        -- commonObjectAttributes.authId_tag = seq2[3] and seq2[3].tag
        -- KeyContainer.commonObjectAttributes = commonObjectAttributes
        
        t.parseCommonObjectAttributes(seq2, commonObjectAttributes)
        
        KeyContainer.commonObjectAttributes = commonObjectAttributes
        
        seq2 = der.parse(s[2].value)
        local classAttributes = {}
        KeyContainer.classAttributes_tag = s[2].tag
        classAttributes.iD = seq2[1] and seq2[1].value
        classAttributes.iD_tag = seq2[1] and seq2[1].tag

        classAttributes.iD = classAttributes.iD or ""
        
        if seq2[2] and seq2[2].tag == der.BOOLEAN then
            classAttributes.authority = seq2[2].value
            classAttributes.authority_tag = seq2[2].tag
        end
        KeyContainer.classAttributes = classAttributes
       
        
        
        local index = 3
        
        if s[index].tag == der.CONTEXT(0) then
            KeyContainer.subClassAttributes = s[index].value
            KeyContainer.subClassAttributes_tag = s[index].tag
            index = index + 1
        end
       
        seq2 = der.parse(s[index].value)
        local typeAttributes = {}
        KeyContainer.typeAttributes_tag = s[index].tag
        
        seq3 = der.parse(seq2[1].value)
        typeAttributes.path = {}
        typeAttributes.path_tag = seq3[1].tag
        
        seq4 = der.parse(seq3[1].value)
        
        typeAttributes.path.efidOrPath = seq4[1] and seq4[1].value
        typeAttributes.path.efidOrPath_tag = seq4[1] and seq4[1].tag
        typeAttributes.path.index = seq4[2] and t.parse_der_integer(seq4[2].value)
        typeAttributes.path.index_tag = seq4[2] and seq4[2].tag
        typeAttributes.path.length = seq4[3] and t.parse_der_integer(seq4[3].value)
        typeAttributes.path.length_tag = seq4[3] and seq4[3].tag

        index = 2
        if seq3[index] and seq3[index].tag == der.SEQUENCE then
            typeAttributes.subject = seq3[index].value
            typeAttributes.subject_tag = seq3[index].tag
            index = index+1
        end
        if seq3[index] and seq3[index].tag == der.CONTEXT(0) then
            typeAttributes.issuer = seq3[index].value
            typeAttributes.issuer_tag = seq3[index].tag
            index = index+1
        end
        if seq3[index] and seq3[index].tag == der.INTEGER then
            typeAttributes.serialNumber = seq3[index].value
            typeAttributes.serialNumber_tag = seq3[index].tag
            index = index+1
        end
        
        KeyContainer.typeAttributes = typeAttributes
        
        res[i] = KeyContainer
    end
    return res
end


function t.buildCertDF(KeyContainers)
-- SEQUENCE { x509Certificate
    --  SEQUENCE { commonObjectAttributes
        --  UTF8STRING { "Nicolas BATAILLE's gemsafe2003ca ID" } label
        --  BIT STRING { 06 40 } flags
        --  OCTET STRING { 81 } authId opzionale
    --  }
    --  SEQUENCE { classAttributes
        --  OCTET STRING { 5F 7A 2F 11 BB A3 97 43 4D ED A3 14 7C A1 E6 3D 87
        --      1C 3C 6D } iD
        -- authority BOOLEAN DEFAULT FALSE
    --  }
    --  [CONTEXT-SPECIFIC 1] { typeAttributes
        --  SEQUENCE {
            --  SEQUENCE { path
                --  OCTET STRING { 3F 00 50 00 50 40 } efidOrPath
                --  INTEGER { 0 } index
                --  [CONTEXT-SPECIFIC 0] { 07 06 } length
            --  }
            -- subject  		Name OPTIONAL, // SEQUENCE{...}
            -- issuer 		[0] Name OPTIONAL,  // SEQUENCE{...}
            -- serialNumber 	CertificateSerialNumber OPTIONAL,  // INTEGER
        --  }
    --  }
--  }
    local res = ""
    for i=1,table.getn(KeyContainers) do
        local KeyContainer = KeyContainers[i]
        local commonObjectAttributes = KeyContainer.commonObjectAttributes
        local classAttributes = KeyContainer.classAttributes
        local typeAttributes = KeyContainer.typeAttributes
        local path = typeAttributes.path
        
        KeyContainer.commonObjectAttributes_tag = KeyContainer.commonObjectAttributes_tag or der.SEQUENCE
        KeyContainer.classAttributes_tag = KeyContainer.classAttributes_tag or der.SEQUENCE
        KeyContainer.typeAttributes_tag = KeyContainer.typeAttributes_tag or der.CONTEXT(1)
        
        commonObjectAttributes.label_tag = commonObjectAttributes.label_tag or der.UTF8STRING
        commonObjectAttributes.flags_tag = commonObjectAttributes.flags_tag or der.BIT_STRING
        commonObjectAttributes.authId_tag = commonObjectAttributes.authId_tag or der.STRING

        commonObjectAttributes.label =commonObjectAttributes.label or ""
        commonObjectAttributes.flags =commonObjectAttributes.flags or "\000\000"

        commonObjectAttributes.accessControlRules_tag = commonObjectAttributes.accessControlRules_tag or der.SEQUENCE

        classAttributes.iD_tag = classAttributes.iD_tag or der.STRING
        classAttributes.iD = classAttributes.iD or ""
        
        typeAttributes.path_tag = typeAttributes.path_tag or der.SEQUENCE
        path.efidOrPath_tag = path.efidOrPath_tag or der.STRING
        path.index_tag = path.index_tag or der.INTEGER
        path.length_tag = path.length_tag or der.CONTEXT_SPECIFIC(0)
        
        local labelD = commonObjectAttributes.label and der.build(commonObjectAttributes.label_tag, commonObjectAttributes.label) or ""
        local flagsD = commonObjectAttributes.flags and der.build(commonObjectAttributes.flags_tag, commonObjectAttributes.flags) or ""
        local authIdD = commonObjectAttributes.authId and der.build(commonObjectAttributes.authId_tag, commonObjectAttributes.authId) or ""
        
        local accessControlRulesD = ""
        if commonObjectAttributes.accessControlRules then
            local acrs = {}
            for k=1,table.getn(commonObjectAttributes.accessControlRules) do
                local acr = commonObjectAttributes.accessControlRules[k]
                local acrD = der.build(acr.accessMode_tag, acr.accessMode)
                             .. der.build(acr.securityCondition_tag, acr.securityCondition)
                table.insert(acrs, der.build(der.SEQUENCE, acrD))
            end
            accessControlRulesD = der.build(commonObjectAttributes.accessControlRules_tag, table.concat(acrs, ""))
            commonObjectAttributes.accessControlRules_der = accessControlRulesD
        end
        
        local commonObjectAttributesD = der.build(KeyContainer.commonObjectAttributes_tag,
                labelD .. flagsD .. authIdD .. accessControlRulesD)
        
        local iDD = classAttributes.iD and der.build(classAttributes.iD_tag, classAttributes.iD) or ""
        local authorityD = classAttributes.authority and der.build(classAttributes.authority_tag or der.BOOLEAN, classAttributes.authority) or ""
       
        local classAttributesD = der.build(KeyContainer.classAttributes_tag, iDD .. authorityD)
        
        local efidOrPathD = der.build(path.efidOrPath_tag, path.efidOrPath) or ""
        local indexD = path.index and der.build(path.index_tag, t.build_der_integer(path.index)) or ""
        local lengthD = path.length and der.build(path.length_tag, t.build_der_integer(path.length)) or ""
        local pathD = der.build(typeAttributes.path_tag, efidOrPathD .. indexD .. lengthD)
        
        local subjectD = typeAttributes.subject and der.build(typeAttributes.subject_tag or der.SEQUENCE, typeAttributes.subject) or ""
        local issuerD = typeAttributes.issuer and der.build(typeAttributes.issuer_tag or der.CONTEXT(0), typeAttributes.issuer) or ""
        local serialNumberD = typeAttributes.serialNumber and der.build(typeAttributes.serialNumber_tag or der.INTEGER, typeAttributes.serialNumber) or ""

        -- log.output ("pathD", hex.hexify(pathD))
        
        local typeAttributesDseq = der.build(der.SEQUENCE, pathD .. subjectD .. issuerD .. serialNumberD)
        -- log.output ("typeAttributesDseq", hex.hexify(typeAttributesDseq))
        
        local typeAttributesD = der.build(KeyContainer.typeAttributes_tag, typeAttributesDseq)
        -- log.output ("typeAttributesD", hex.hexify(typeAttributesD))

        -- [CONTEXT-SPECIFIC 0] { }
        local cs0 = hex.hexf("A0020500")
        local KeyContainerD = der.build(der.SEQUENCE, commonObjectAttributesD .. classAttributesD .. cs0 .. typeAttributesD)
        res = res .. KeyContainerD
    end

    return res
end




function t.parsePubPrivDataD(value)
--  SEQUENCE {
    --  SEQUENCE {
        --  UTF8STRING { "92d72b19-25b1-c081-fe49-d68631b32aa9" } label
        --  BIT STRING { 06 40 } flags
        --  OCTET STRING { 81 } authId opzionale
    --  }
    --  SEQUENCE {
        --  UTF8STRING { "CSP" } applicationName OPTIONAL
        --  OBJECT IDENTIFIER { } applicationOID OPTIONAL
    --  }
    --  [CONTEXT-SPECIFIC 0] { } subClassAttributes OPTIONAL
    --  [CONTEXT-SPECIFIC 1] {
        --  SEQUENCE { path
            --  OCTET STRING { 3F 00 50 00 50 40 } efidOrPath
            --  INTEGER { 3718 } index
            --  [CONTEXT-SPECIFIC 0] { 19 } length
        --  }
    --  }
--  }
    local KeyContainer
    local res = {}
    local seq1, seq2, s, seq3
    local seq1 = der.parse(value) -- decode PrivateKeyChoice sequence
    for i=1,table.getn(seq1) do
        KeyContainer = {}
        if seq1[i].tag == 0 then
            break
        end
        s = der.parse(seq1[i].value)
        
        seq2 = der.parse(s[1].value)
        local commonObjectAttributes = {}
        -- KeyContainer.commonObjectAttributes_tag = s[1].tag
        -- commonObjectAttributes.label = seq2[1] and seq2[1].value
        -- commonObjectAttributes.label_tag = seq2[1] and seq2[1].tag
        -- commonObjectAttributes.flags = seq2[2] and seq2[2].value
        -- commonObjectAttributes.flags_tag = seq2[2] and seq2[2].tag
        -- commonObjectAttributes.authId = seq2[3] and seq2[3].value
        -- commonObjectAttributes.authId_tag = seq2[3] and seq2[3].tag
        -- KeyContainer.commonObjectAttributes = commonObjectAttributes
        t.parseCommonObjectAttributes(seq2, commonObjectAttributes)
        
        KeyContainer.commonObjectAttributes = commonObjectAttributes
        
        seq2 = der.parse(s[2].value)
        local classAttributes = {}
        KeyContainer.classAttributes_tag = s[2].tag
        local index = 1
        
        if seq2[index] and (seq2[index].tag == der.STRING or seq2[index].tag == der.UTF8STRING) then
            classAttributes.applicationName = seq2[index].value
            classAttributes.applicationName_tag = seq2[index].tag
            index = index+1
        end
        
        if seq2[index] and seq2[index].tag == der.OID then
            classAttributes.applicationOID = seq2[index].value
            classAttributes.applicationOID_tag = seq2[index].tag
            index = index+1
        end
        
        KeyContainer.classAttributes = classAttributes
       
        -- s[3] contiene "[CONTEXT-SPECIFIC 0] { }"
        if s[3] and not s[4] then
            s[4] = s[3]
        else
            KeyContainer.subClassAttributes = s[3]
        end
        
        seq2 = der.parse(s[4].value)
        local typeAttributes = {}
        KeyContainer.typeAttributes_tag = s[4].tag
        
        seq3 = der.parse(seq2[1].value)
        typeAttributes.path = {}
        typeAttributes.path_tag = seq2[1].tag
        
        typeAttributes.path.efidOrPath = seq3[1] and seq3[1].value
        typeAttributes.path.efidOrPath_tag = seq3[1] and seq3[1].tag
        typeAttributes.path.index = seq3[2] and t.parse_der_integer(seq3[2].value)
        typeAttributes.path.index_tag = seq3[2] and seq3[2].tag
        typeAttributes.path.length = seq3[3] and t.parse_der_integer(seq3[3].value)
        typeAttributes.path.length_tag = seq3[3] and seq3[3].tag

        KeyContainer.typeAttributes = typeAttributes
        
        res[i] = KeyContainer
        
    end
    return res
end


function t.buildPubPrivDataD(KeyContainers, defaults)
--  SEQUENCE {
    --  SEQUENCE {
        --  UTF8STRING { "92d72b19-25b1-c081-fe49-d68631b32aa9" } label
        --  BIT STRING { 06 40 } flags
        --  OCTET STRING { 81 } authId opzionale
    --  }
    --  SEQUENCE {
        --  UTF8STRING { "CSP" } applicationName OPTIONAL
        --  OBJECT IDENTIFIER { } applicationOID OPTIONAL
    --  }
    --  [CONTEXT-SPECIFIC 0] { } subClassAttributes OPTIONAL
    --  [CONTEXT-SPECIFIC 1] {
        --  SEQUENCE { path
            --  OCTET STRING { 3F 00 50 00 50 40 } efidOrPath
            --  INTEGER { 3718 } index
            --  [CONTEXT-SPECIFIC 0] { 19 } length
        --  }
    --  }
--  }
    defaults = defaults or {}
    local res = ""
    for i=1,table.getn(KeyContainers) do
        local KeyContainer = KeyContainers[i]
        local commonObjectAttributes = KeyContainer.commonObjectAttributes
        local classAttributes = KeyContainer.classAttributes
        local typeAttributes = KeyContainer.typeAttributes
        
        local path = typeAttributes.path
        
        KeyContainer.commonObjectAttributes_tag = KeyContainer.commonObjectAttributes_tag or der.SEQUENCE
        KeyContainer.classAttributes_tag = KeyContainer.classAttributes_tag or der.SEQUENCE
        KeyContainer.typeAttributes_tag = KeyContainer.typeAttributes_tag or der.CONTEXT(1)
        
        commonObjectAttributes.label_tag = commonObjectAttributes.label_tag or der.UTF8STRING
        commonObjectAttributes.flags_tag = commonObjectAttributes.flags_tag or der.BIT_STRING
        commonObjectAttributes.authId_tag = commonObjectAttributes.authId_tag or der.STRING
        
        commonObjectAttributes.label =commonObjectAttributes.label or defaults.label
        commonObjectAttributes.flags =commonObjectAttributes.flags or "\000\000"
        
        commonObjectAttributes.accessControlRules_tag = commonObjectAttributes.accessControlRules_tag or der.SEQUENCE
        
        classAttributes.applicationName_tag = classAttributes.applicationName_tag or der.UTF8STRING
        classAttributes.applicationOID_tag = classAttributes.applicationOID_tag or der.OID
        
        classAttributes.applicationName = classAttributes.applicationName or defaults.applicationName
        classAttributes.applicationOID = classAttributes.applicationOID or defaults.applicationOID
        
        typeAttributes.path_tag = typeAttributes.path_tag or der.SEQUENCE
        path.efidOrPath_tag = path.efidOrPath_tag or der.STRING
        path.index_tag = path.index_tag or der.INTEGER
        path.length_tag = path.length_tag or der.CONTEXT_SPECIFIC(0)

        
        local labelD = commonObjectAttributes.label and der.build(commonObjectAttributes.label_tag, commonObjectAttributes.label) or ""
        local flagsD = commonObjectAttributes.flags and der.build(commonObjectAttributes.flags_tag, commonObjectAttributes.flags) or ""
        local authIdD = commonObjectAttributes.authId and der.build(commonObjectAttributes.authId_tag, commonObjectAttributes.authId) or ""

        local accessControlRulesD = ""
        if commonObjectAttributes.accessControlRules then
            local acrs = {}
            for k=1,table.getn(commonObjectAttributes.accessControlRules) do
                local acr = commonObjectAttributes.accessControlRules[k]
                local acrD = der.build(acr.accessMode_tag, acr.accessMode)
                             .. der.build(acr.securityCondition_tag, acr.securityCondition)
                table.insert(acrs, der.build(der.SEQUENCE, acrD))
            end
            accessControlRulesD = der.build(commonObjectAttributes.accessControlRules_tag, table.concat(acrs, ""))
            commonObjectAttributes.accessControlRules_der = accessControlRulesD
        end
        
        local commonObjectAttributesD = der.build(KeyContainer.commonObjectAttributes_tag,
                labelD .. flagsD .. authIdD .. accessControlRulesD)
        
        local applicationNameD = classAttributes.applicationName and der.build(classAttributes.applicationName_tag, classAttributes.applicationName) or ""
        local applicationOIDD = classAttributes.applicationOID and der.build(classAttributes.applicationOID_tag, classAttributes.applicationOID) or ""
       
        local classAttributesD = der.build(KeyContainer.classAttributes_tag, applicationNameD .. applicationOIDD)

        
        local efidOrPathD = der.build(path.efidOrPath_tag, path.efidOrPath) or ""
        local indexD = path.index and der.build(path.index_tag, t.build_der_integer(path.index)) or ""
        local lengthD = path.length and der.build(path.length_tag, t.build_der_integer(path.length)) or ""
        local pathD = der.build(typeAttributes.path_tag, efidOrPathD .. indexD .. lengthD)

        -- log.output ("pathD", hex.hexify(pathD))
        
        local typeAttributesD = der.build(KeyContainer.typeAttributes_tag, pathD)
        -- log.output ("typeAttributesD", hex.hexify(typeAttributesD))
        
        -- [CONTEXT-SPECIFIC 0] { }
        local cs0 = ""
        local subClassAttributes = KeyContainer.subClassAttributes or defaults.subClassAttributes
        if subClassAttributes then
            cs0 = subClassAttributes.value and der.build(subClassAttributes.tag, subClassAttributes.value) or ""
        else
            cs0 = hex.hexf("A0020500") -- NULL
        end
        local KeyContainerD = der.build(KeyContainer.tag or der.SEQUENCE, commonObjectAttributesD .. classAttributesD .. cs0 .. typeAttributesD)
        res = res .. KeyContainerD
    end

    return res
end


-- cerca il blocco libero pi