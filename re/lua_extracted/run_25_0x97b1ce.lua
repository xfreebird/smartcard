 Public portion        '22'           'A2'
-- Security environment                       '7B'           'FB'


NXPIASSmartCard.object_classes = {
    RSA_PUB_KEY=tonumber("A0", 16),
    RSA_PRIV_KEY=tonumber("90", 16),
    
    ECC_PUB_KEY=tonumber("A2", 16),
    ECC_PRIV_KEY=tonumber("92", 16),
    
    PIN=tonumber("81", 16),
}
NXPIASSmartCard.mt.object_classes = NXPIASSmartCard.object_classes

NXPIASSmartCard.object_classes_acs = {
    [NXPIASSmartCard.object_classes.RSA_PUB_KEY] = { -- RSA PUB KEY
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
    [NXPIASSmartCard.object_classes.RSA_PRIV_KEY] = { -- RSA PRIV KEY
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
    [NXPIASSmartCard.object_classes.PIN] = { -- PIN
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
}

NXPIASSmartCard.object_classes_acs[NXPIASSmartCard.object_classes.ECC_PUB_KEY] = NXPIASSmartCard.object_classes_acs[NXPIASSmartCard.object_classes.RSA_PUB_KEY]
NXPIASSmartCard.object_classes_acs[NXPIASSmartCard.object_classes.ECC_PRIV_KEY] = NXPIASSmartCard.object_classes_acs[NXPIASSmartCard.object_classes.RSA_PRIV_KEY]

function NXPIASSmartCard.map_ambs(objClass, ambs)
    local mapped_ambs = {}

    local mapping = NXPIASSmartCard.object_classes_acs[objClass]
    
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

function NXPIASSmartCard.unmap_ambs(objClass, mapped_ambs)
    local unmapped_ambs = {}

    local mapping = NXPIASSmartCard.object_classes_acs[objClass]
    
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
-- local mapped = NXPIASSmartCard.map_ambs(NXPIASSmartCard.object_classes.PIN, acContactAMBs2)
-- local unmapped = NXPIASSmartCard.unmap_ambs(NXPIASSmartCard.object_classes.PIN, mapped)

-- print (util.repr(mapped))
-- print (util.repr(unmapped))
-- print (util.repr(acContactAMBs2))

-- local acContactAMBs1 = {[5]={[1]=19}, [7]=true, [0]={[1]=0}, [3]={[1]=19}}
-- local mapped = NXPIASSmartCard.map_ambs(NXPIASSmartCard.object_classes.PIN, acContactAMBs1)
-- local unmapped = NXPIASSmartCard.unmap_ambs(NXPIASSmartCard.object_classes.PIN, mapped)

-- print (util.repr(mapped))
-- print (util.repr(unmapped))
-- print (util.repr(acContactAMBs1))

function NXPIASSmartCard.mt:get_DOCP(objClass, kid)
    log.output('NXPIASSmartCard:get_DOCP():', objClass, kid)
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
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'get_doup Error' ))
    end
    
    local d = parse_tlv_ber(string.sub(recv, 1, -3))
    local d0 = parse_tlv_ber( d[tag_70] )
    local d1 = parse_tlv_ber( d0[tag_BFA0_X] )
    
    local d2 = parse_tlv_ber( d1[tag_A0] )
    
    local objLen = d2[tag_80] and bin.unpack("%>%H", d2[tag_80])
    log.output("NXPIASSmartCard:get_DOCP(): objLen:", objLen)
    
    local maxTries = d2[tag_9A] and string.byte( d2[tag_9A])
    log.output("NXPIASSmartCard:get_DOCP(): maxTries:", maxTries)
    
    local tries = d2[tag_9B] and string.byte( d2[tag_9B])
    log.output("NXPIASSmartCard:get_DOCP(): tries:", tries)
    
    local maxUsageCount = d2[tag_9C] and string.byte( d2[tag_9C])
    log.output("NXPIASSmartCard:get_DOCP(): maxUsageCount:", maxUsageCount)
    
    local usageCount = d2[tag_9D] and string.byte( d2[tag_9D])
    log.output("NXPIASSmartCard:get_DOCP(): usageCount:", usageCount)
    
    local nonRepudiation = d2[tag_9E] and string.byte( d2[tag_9E])
    log.output("NXPIASSmartCard:get_DOCP(): nonRepudiation:", nonRepudiation)
    
    local acs = parse_tlv_ber(d2[tag_A1])
    log.output("NXPIASSmartCard:get_DOCP(): acs:", util.repr(acs))
    local acContact = acs[tag_A1_8C]
    local acContactless = acs[tag_A1_9C]
    
    log.output("NXPIASSmartCard:get_DOCP(): acContact:", hex.hexify(acContact))
    log.output("NXPIASSmartCard:get_DOCP(): acContactless:", hex.hexify(acContactless))
    
    local acContactAMBs = NXPIASSmartCard.parse_ambs(acContact)
    local acContactlessAMBs = NXPIASSmartCard.parse_ambs(acContactless)

    log.output("NXPIASSmartCard:get_DOCP(): acContactAMBs:", util.repr(acContactAMBs))
    log.output("NXPIASSmartCard:get_DOCP(): acContactlessAMBs:", util.repr(acContactlessAMBs))
    local acContactMappedAMBs = NXPIASSmartCard.map_ambs(string.byte(objClass), acContactAMBs)
    local acContactlessMappedAMBs  = NXPIASSmartCard.map_ambs(string.byte(objClass), acContactlessAMBs)
    
    log.output("NXPIASSmartCard:get_DOCP(): acContactMappedAMBs:", util.repr(acContactMappedAMBs))
    log.output("NXPIASSmartCard:get_DOCP(): acContactlessMappedAMBs:", util.repr(acContactlessMappedAMBs))
    
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
    log.output("NXPIASSmartCard:get_DOCP(): DOCP: ", util.repr(DOCP))
    
    return DOCP
end


function NXPIASSmartCard.mt:read_binary_sfi(sfi, offset, size, use_sm)
    log.output('NXPIASSmartCard:read_binary_sfi():', sfi, offset, size)
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
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'read_binary_sfi Error' ))
    end
    local res = parse_tlv_ber(string.sub(recv, 1, -3) )
    if res[tag_53] then
        return res[tag_53]
    else
        error('read_binary_sfi Error: invalid response format:' .. (recv and hex.hexify(recv) or "nil"))
    end
end

function NXPIASSmartCard.mt:verify_pin_main(pin, ispuk, use_sm)
    log.output('NXPIASSmartCard:verify_pin_main(): pin:', pin)
    log.output('NXPIASSmartCard:verify_pin_main(): ispuk:', ispuk)
    log.output('NXPIASSmartCard:verify_pin_main(): use_sm(1):', use_sm)
    
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output('NXPIASSmartCard:verify_pin_main(): use_sm(2):', use_sm)
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

    return self:verify(bso, pin, true, use_sm)
end

function NXPIASSmartCard.mt:change_pin_main(oldPin, newPin, ispuk, use_padding)
    log.output('NXPIASSmartCard:change_pin_main():', oldPin, newPin, ispuk, use_padding )
    local bso = self.ID_PIN
    self:get_pin_puk_docp(true)
    local padding = self.pinDOCP.objLen
    
    if ispuk then
        bso = self.ID_PUK
        padding = self.pukDOCP.objLen
    end
    
    if string.len(oldPin) < padding then
        log.output('NXPIASSmartCard:change_pin_main(): using padding on old pin:', padding)
        oldPin = oldPin .. string.rep(self.PADDING_CHAR, padding - string.len(oldPin))
    end
    
    if use_padding then
        if string.len(newPin) < padding then
            log.output('NXPIASSmartCard:change_pin_main(): using padding on new pin:', padding)
            newPin = newPin .. string.rep(self.PADDING_CHAR, padding - string.len(newPin))
        end
    end 
    
    local res = self:change(bso, oldPin, newPin, true)
    if res == 0 then
        self:get_pin_puk_docp(true)
        log.output('change_pin_main(): calling verify_pin_main():...' )
        res = self:verify_pin_main(newPin, ispuk)
    end
    return res
end


function NXPIASSmartCard.mt:reset_pin_main(Puk, newPin, use_padding)
    local res
    log.output('NXPIASSmartCard:reset_pin_main():', Puk, newPin, use_padding)
    
    self:get_pin_puk_docp(true)
    local puk_padding = self.pukDOCP.objLen
    local pin_padding = self.pinDOCP.objLen
    
    if string.len(Puk) < puk_padding then
        log.output('NXPIASSmartCard:reset_pin_main(): using padding on puk:', puk_padding)
        Puk = Puk .. string.rep(self.PADDING_CHAR, puk_padding - string.len(Puk))
    end
    
    if use_padding then
        if string.len(newPin) < pin_padding then
            log.output('NXPIASSmartCard:reset_pin_main(): using padding on new pin:', pin_padding)
            newPin = newPin .. string.rep(self.PADDING_CHAR, pin_padding - string.len(newPin))
        end
    end
    
    res = self:verify_pin_main(Puk, true)
    if res ~= 0 then return res end
    res =  self:reset_retry_counter(self.ID_PIN, newPin, true)
    if res == 0 then
        self:get_pin_puk_docp(true)
    end
    return res
end


function NXPIASSmartCard.mt:verify_pin_ds(pin, ispuk)
    log.output('NXPIASSmartCard:verify_pin_main():', pin, ispuk )
    local bso = self.ID_PIN_DS
    -- local padding = self.PIN_PADDING
    if ispuk then
        bso = self.ID_PUK_DS
        -- padding = self.PUK_PADDING
    end
    -- if string.len(pin)> padding then
        -- pin = string.sub(pin, 1, padding)
    -- end
    -- pin = pin .. string.rep(self.PADDING_CHAR, padding - string.len(pin))
    return self:verify(bso, pin, true, true)
end

function NXPIASSmartCard.mt:change_pin_ds(oldPin, newPin, ispuk)
    log.output('NXPIASSmartCard:change_pin_ds():', oldPin, newPin, ispuk )
    local bso = self.ID_PIN_DS
    if ispuk then
        bso = self.ID_PUK_DS
    end
    local res = self:change(bso, oldPin, newPin, true)
    if res == 0 then
        log.output('NXPIASSmartCard:change_pin_ds(): calling verify_pin_ds():...' )
        res = self:verify_pin_ds(newPin, ispuk)
    end
    return res
end

function NXPIASSmartCard.mt:reset_pin_ds(Puk, newPin)
    local res
    log.output('NXPIASSmartCard:reset_pin_ds():', Puk, newPin )
    res = self:verify_pin_ds(Puk, true)
    if res ~= 0 then return res end
    return self:reset_retry_counter(self.ID_PIN_DS, newPin, true)
end

function NXPIASSmartCard.mt:pso_cds(data, kid, backtracking, ecc, use_sm)
    local sw, recv
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
    
        local Key = ecc and hex.hexf("8001cc8401%S", kid) or hex.hexf("80018a8401%S", kid)
        local setKey = hex.hexf("002241B6%P", Key)
        recv = self:sm_transmit(setKey, use_sm)
        sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            log.output("NXPIASSmartCard:pso_cds: MSE SW", hex.hexify(sw))
            break
        end

        
        local apduSign = hex.hexf("002a9e9a%P", data)
        recv = self:sm_transmit(apduSign, use_sm)
        sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            log.output("NXPIASSmartCard:pso_cds: error", hex.hexify(sw))
            break
        end
    
    until true
    if sw ~= hexf('9000') then
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'pso_cds error' ))
    end
    
    return string.sub(recv, 1, -3)
end



function NXPIASSmartCard.mt:pso_internal_auth(data, kid, backtracking, use_sm)
    log.output("NXPIASSmartCard:pso_internal_auth: data", hex.hexify(data or ''))
    log.output("NXPIASSmartCard:pso_internal_auth: backtracking", backtracking)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local sw, resp
    kid = kid or '81'
    if type(kid) == 'number' then 
        kid = hex.hexf('%B', kid)
    elseif string.len(kid) == 2 then 
        kid = hex.hexf(kid)
    end
    log.output("NXPIASSmartCard:pso_internal_auth: kid", hex.hexify(kid))
    if backtracking then
        kid = string.char((bin.flags( string.byte(kid, 1)) + bin.flags(128)).asnumber)
    end
    repeat

        -- if pin and string.len(pin) > 0 then
            -- local res = self:verify_pin_main(pin, false)
            -- if res ~= 0 then
                -- error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 
                    -- 'pso_internal_auth error: verify_pin_main failed!' ))
            -- end
        -- end
        
        local Key = hex.hexf("8001028401%S", kid)
        local setKey = hex.hexf("002241A4%P", Key)
        resp = self:sm_transmit(setKey, use_sm)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then
            log.output("NXPIASSmartCard:pso_internal_auth: MSE SW", hex.hexify(sw))
            break
        end

        local pso_internal_auth = hex.hexf("008800000000%P0000", data)
        resp = self:sm_transmit(pso_internal_auth, use_sm)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then
            log.output("NXPIASSmartCard:pso_internal_auth: INTERNAL AUTH SW", hex.hexify(sw))
            break
        end
        
        break
    until true
    
    if sw ~= hexf('9000') then
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'pso_internal_auth error' ))
    end
    return string.sub(resp, 1, -3)
end


function NXPIASSmartCard.mt:pso_dec(data, kid, backtracking, raw, use_sm)
    log.output("NXPIASSmartCard:pso_dec(): ")
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
    local dec_mode = tonumber("1A", 16)
    local raw_mode = tonumber("8c", 16)
    
    repeat

        if pin and string.len(pin) > 0 then
            local res = self:verify_pin_main(pin, false)
            if res ~= 0 then
                error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 
                    'pso_dec error: verify_pin_main failed!' ))
            end
        end
        
        local Key = hex.hexf("8001%B8401%S",  raw and raw_mode or dec_mode, kid)
        local setKey = hex.hexf("002241B8%P", Key)
        resp = self:sm_transmit(setKey, use_sm)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end

        data = hex.hexf("81") .. data
        local data_remaining = data
        
        while string.len(data_remaining) >0 do
            local apdu
            local cur_data = string.sub(data_remaining, 1, 231)
            data_remaining = string.sub(data_remaining, 232, -1)
            if not data_remaining or string.len(data_remaining) == 0 then
                apdu = hex.hexf("002a8086%P00", cur_data )
            else
                apdu = hex.hexf("102a8086%P", cur_data)
            end

            resp = self:sm_transmit(apdu, use_sm)
            sw = string.sub(resp, -2, -1)
            if sw ~= hexf('9000') then break end
        end
        
        break
    until true
    
    if sw ~= hexf('9000') then
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'pso_dec error' ))
    end
    return string.sub(resp, 1, -3)
end


function NXPIASSmartCard.mt:read_public_key(kid, use_sm)
    log.output("NXPIASSmartCard:read_public_key(): ")
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
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'read_public_key error' ))
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


function NXPIASSmartCard.mt:read_public_key_ECC(kid, use_sm, retry_no_sm_on_error)
    log.output("NXPIASSmartCard:read_public_key_ECC(): ", kid, use_sm, retry_no_sm_on_error)
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
            log.output("NXPIASSmartCard:read_public_key_ECC(): SM ERROR: closing SM channel and retry...")
            self:close_secure_channel()
            resp = self:sm_transmit(getKey, false)
            sw = string.sub(resp, -2, -1)
        end
        if sw ~= hexf('9000') then
            error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'read_public_key_ECC error' ))
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

function NXPIASSmartCard.mt:select_Applet(use_sm)
    log.output("NXPIASSmartCard:select_Applet(): selecting main CD APPLET...")
    local recv = self:sm_transmit(NXPIASSmartCard.SELECT_MAIN_APPLET_MF_AID, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'select_Applet error' ))
    end
end

function NXPIASSmartCard.mt:select_AID(aid, use_sm)
    log.output("NXPIASSmartCard:select_AID():", hex.hexify(aid), use_sm)
    log.output("NXPIASSmartCard:select_AID(): self.ActiveSM", self.ActiveSM)
    use_sm = use_sm == nil and self.ActiveSM or use_sm

    self._current_selected_aid = nil
    local apdu = hex.hexf("00a40404%P00", aid)
    
    local recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw == hexf('6D00') or sw == hexf('6a86') then
        log.output("NXPIASSmartCard:select_AID(): try reselecting main CD APPLET...")
        
        recv = self:sm_transmit(NXPIASSmartCard.SELECT_MAIN_APPLET_MF_AID, false)
        
        if not use_sm then
            log.output("NXPIASSmartCard:select_AID(): retransmit PLAIN select AID...")
            recv = self:sm_transmit(apdu, false)
            sw = string.sub(recv, -2, -1)
        else
            log.output("NXPIASSmartCard:select_AID(): force retransmit select AID after rebuild SM session...")
            sw = hexf('6988')
        end
    end
    if sw == hexf('6988') and use_sm then
        log.output("NXPIASSmartCard:select_AID(): SM session invalid?")
        if self:perform_mutual_authenticate(aid) then
            log.output("NXPIASSmartCard:select_AID(): retry sending APDU...")
            recv = self:sm_transmit(apdu, use_sm)
            sw = string.sub(recv, -2, -1)
        end
    end
    if sw ~= hexf('9000') then
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'select_AID error' ))
    end
    self._current_selected_aid = aid
end

function NXPIASSmartCard.mt:select_MF(use_sm)
    log.output("NXPIASSmartCard:select_MF():", use_sm)
    log.output("NXPIASSmartCard:select_MF(): self.ActiveSM", self.ActiveSM)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local recv = self:sm_transmit(hex.hexf("00a40000023f00"), use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'select_MF error' ))
    end

end


function NXPIASSmartCard.mt:select_SSCD(use_sm)
    log.output("NXPIASSmartCard:select_SSCD():", use_sm)
    self.has_sscd = false
    self:select_AID(SSCD_AID, use_sm)
    log.output("NXPIASSmartCard:select_SSCD(): OK!")
    self.has_sscd = true
end

function NXPIASSmartCard.mt:select_Generic(use_sm)
    log.output("NXPIASSmartCard:select_Generic():", use_sm)
    self:select_AID(Generic_AID, use_sm)
end


function NXPIASSmartCard.mt:InitDHParam()
    
-- 00 a4 04 04 0e e8 28 bd 08 0f d2 50 47 65 6e 65 72 69 63 00                                    
-- 00 a4 02 04 02 70 04
-- 00 b0 00 00 00
-- 00 cb 3f ff 0c 4D 0A 70 08 BF A1 0e 04 A3 02 97 00
-- 00 cb 3f ff 0c 4D 0A 70 08 BF A1 0e 04 A3 02 98 00
-- 00 cb 3f ff 0c 4D 0A 70 08 BF A1 0e 04 A3 02 99 00

    log.output ("NXPIASSmartCard:InitDHParam():")
    if not self.dh_g or not self.dh_p or not self.dh_q then
        local dh_sdo_id_0e = tonumber("0E", 16)
        local tag_70 = tonumber("70", 16)
        local tag_BFA10E = tonumber("BFA10E", 16)
        local tag_A3 = tonumber("A3", 16)
        local tag_97 = tonumber("97", 16)
        local tag_98 = tonumber("98", 16)
        local tag_99 = tonumber("99", 16)
        
        local tags = {{tag=tag_97, name="dh_g"}, {tag=tag_98, name="dh_p"}, {tag=tag_99, name="dh_q"}, }
        log.output ("NXPIASSmartCard:InitDHParam(): reading...")
        
        for i, tag in tags do
            local readTemplate = "00cb3fff0c4D0A7008BFA1%B04A302%B00"
            local apdu = hex.hexf(readTemplate, dh_sdo_id_0e, tag.tag)
 
            local recv = self:sm_transmit(apdu, false)
            local sw = string.sub(recv, -2, -1)
            if sw ~= hexf('9000') then
                error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'ReadDappPubKey error' ))
            end

            local x = parse_tlv_ber(string.sub(recv, 1, -3))


            local y = parse_tlv_ber(x[tag_70])
            log.output ("\ttag_BFA10E:", hex.hexify((y[tag_BFA10E])))

            local k = parse_tlv_ber(y[tag_BFA10E])
            log.output("\ttag_A3:", hex.hexify((k[tag_A3])))

            local h = parse_tlv_ber(k[tag_A3])
            self[tag.name] = h[tag.tag]
        end
        
    else
        log.output ("NXPIASSmartCard:InitDHParam(): cached!")
    end
    log.output("NXPIASSmartCard:InitDHParam:dh_g", hex.hexify(self.dh_g))
    log.output("NXPIASSmartCard:InitDHParam:dh_p", hex.hexify(self.dh_p))
    log.output("NXPIASSmartCard:InitDHParam:dh_q", hex.hexify(self.dh_q))
    return self.dh_g, self.dh_p, self.dh_q
end


function NXPIASSmartCard.mt:SetupSM(secret, rndCard, rndIFD)

    log.output("NXPIASSmartCard:SetupSM(): shared secret:", hex.hexify(secret));
    
    local s;
    if rndCard and rndIFD then
        log.output("NXPIASSmartCard:SetupSM(): rndCard:", hex.hexify(rndCard));
        log.output("NXPIASSmartCard:SetupSM(): rndIFD:", hex.hexify(rndIFD));
        s = md.sha1()
        self.ssc = string.sub(rndCard, 5, 8) .. string.sub(rndIFD, 5, 8)
    else
        s = md.sha256()
        self.ssc = hex.hexf("0000000000000001")
    end
    log.output("NXPIASSmartCard:SetupSM:ssc:", hex.hexify(self.ssc))

    s:update(secret .. hex.hexf("00000001"))
    self.sessENC = s:final()
    self.sessENC = string.sub(self.sessENC, 1, 16)
    log.output("NXPIASSmartCard:SetupSM:sessENC:", hex.hexify(self.sessENC))

    s:reset()
    s:update(secret .. hex.hexf("00000002"))

    self.sessMAC = s:final()
    self.sessMAC = string.sub(self.sessMAC, 1, 16)
    log.output("NXPIASSmartCard:SetupSM:sessMAC:", hex.hexify(self.sessMAC))

    

	self.ActiveSM = true;

    return self.sessENC, self.sessMAC, self.ssc
    
end



function NXPIASSmartCard.mt:StartSM_Generic_FS()
	local dh_prKey

    
	log.output("NXPIASSmartCard:StartSM_Generic_FS:");
    self:read_serial_number()
    self:select_Generic(false)
    self:InitDHParam()
	repeat
    
        dh_prKey = sm.gen_random(string.len(self.dh_q))

	until string.byte(self.dh_q, 1) > string.byte(dh_prKey, 1)

    -- bin.flags(string.byte(dh_prKey, -1))
	-- dh_prKey.right(1)[0] |= 1;
    dh_prKey = hex.hexf("DBFF1FCBC75C4F3BB37C838735404A1445D5D0AB0DE21581827895CDB45A7D39") -- todo: using static value

	log.output("NXPIASSmartCard:StartSM_Generic_FS:dh_prKey", hex.hexify(dh_prKey));
	log.output("NXPIASSmartCard:StartSM_Generic_FS:dh_g", hex.hexify(self.dh_g));
	log.output("NXPIASSmartCard:StartSM_Generic_FS:dh_p", hex.hexify(self.dh_p));

    local dh_pubKey = bignum.powmod(self.dh_g, dh_prKey, self.dh_p, true)
   
   
    log.output("NXPIASSmartCard:StartSM_Generic_FS:dh_pubKey", hex.hexify(dh_pubKey));

    -- algo: 9b, key id: 8e, 
    local d1 = hex.hexf("80019B") .. hex.hexf("83018e") .. BUILD_TLV_BER("91", dh_pubKey)
    
    log.output("NXPIASSmartCard:StartSM_Generic_FS:d1", hex.hexify(d1));
    
    local MSE_SET_1 = hex.hexf("002241a6%P", string.sub(d1, 1, 255) )
    
    log.output("NXPIASSmartCard:StartSM_Generic_FS:MSE_SET_1", hex.hexify(MSE_SET_1));
    
    
    
    local recv = self:transmit(MSE_SET_1)
    
    if string.sub(recv, -2, -1) ~= hex.hexf("9000") then
        error("NXPIASSmartCard:StartSM_Generic_FS: MSE_SET");
    end
    

    local GET_DATA = hex.hexf("00CB3FFF064D04A6029100")
    local recv = self:transmit(GET_DATA)
    if string.sub(recv, -2, -1) ~= hex.hexf("9000") then
        error("NXPIASSmartCard:StartSM_Generic_FS: GET_DATA");
    end
    
    local x = parse_tlv_ber(string.sub(recv, 1, -3))


    local tag_A6 = tonumber("A6", 16)
    local tag_91 = tonumber("91", 16)

    local y = parse_tlv_ber(x[tag_A6])
    log.output ("tag_91:", hex.hexify((y[tag_91])))

	local dh_ICCpubKey = y[tag_91];

    log.output("NXPIASSmartCard:StartSM_Generic_FS:dh_ICCpubKey", hex.hexify(dh_ICCpubKey));
    
    
    local secret = bignum.powmod(dh_ICCpubKey, dh_prKey, self.dh_p, true)

    log.output("NXPIASSmartCard:StartSM_Generic_FS:secret", hex.hexify(secret));
    self.sessENC, self.sessMAC, self.ssc = self:SetupSM(secret)
    
	-- self.ActiveSM = true;

    self.dh_pubKey = dh_pubKey
    self.dh_prKey = dh_prKey
    self.dh_ICCpubKey = dh_ICCpubKey
    
    return self.sessENC, self.sessMAC, self.ssc
end

local function Retail_MAC(key, data, ssc)
    if not ssc then
        ssc=hex.hexf("0000000000000000")
    end
    S1TOMAC = pad_iso9797_2(data)
    return sm.des3_mac(key, S1TOMAC)
end

function NXPIASSmartCard.mt:StartSM_SSCD_FS()


	log.output("NXPIASSmartCard:StartSM_SSCD_FS:")
    self:read_serial_number()
    self:select_SSCD(false)
    
    local ifdKey = sm.gen_random(32)
    local ifdRND = sm.gen_random(8)
    local ifdID = "\1\2\3\4\5\6\7\8"
    local cardID = hex.hexf(self:read_serial_number())
    
    log.output("\tifdKey:", hex.hexify(ifdKey))
    log.output("\tifdRND:", hex.hexify(ifdRND))
    log.output("\tifdID:", hex.hexify(ifdID))
    log.output("\tcardID:", hex.hexify(cardID))

    local MSE_SET = hex.hexf("0022c1a40680010c830184") -- MSE_SET with sm key 0x04 (-> 0x84 with backtraking)
    local recv = self:transmit(MSE_SET)
    if string.sub(recv, -2, -1) ~= hex.hexf("9000") then
        error("StartSM_SSCD_FS: MSE SET");
    end
    
    local get_random = hex.hexf("0084000008")
    local recv = self:transmit(get_random)
    if string.sub(recv, -2, -1) ~= hex.hexf("9000") then
        error("StartSM_SSCD_FS: get_random");
    end
    
    local cardRND = string.sub(recv, 1, 8)
    log.output("\tcardRND:", hex.hexify(cardRND))
    
    local cmdData = ifdRND .. ifdID .. cardRND .. cardID .. ifdKey
    local cmdDataEnc = sm.des3_enc(self.smEnc, cmdData, true)
    local cmdDataEncMAC = Retail_MAC(self.smSig, cmdDataEnc)
    
    local cmd = hex.hexf("00820000%P00", cmdDataEnc .. cmdDataEncMAC)
    

    local recv = self:transmit(cmd)
    
    if string.sub(recv, -2, -1) ~= hex.hexf("9000") then
        error("StartSM_SSCD_FS: external authentication");
    end
    
    local recvDataEnc = string.sub(recv, 1, 64)
    local recvMAC = string.sub(recv, 65, 72)
    log.output("\trecvDataEnc:", hex.hexify(recvDataEnc))
    log.output("\trecvMAC:", hex.hexify(recvMAC))
    
    
    local recvMACComputed = Retail_MAC(self.smSig, recvDataEnc)
    
    local recvDataDec = sm.des3_dec(self.smEnc, recvDataEnc, true)
    log.output("\trecvDataDec:", hex.hexify(recvDataDec))
    
    
    local cardRNDDec = string.sub(recvDataDec, 1, 8)
    local cardIDDec  = string.sub(recvDataDec, 9, 16)
    local ifdRNDDec = string.sub(recvDataDec, 17, 24)
    local ifdIDDec = string.sub(recvDataDec, 25, 32)
    local cardKey = string.sub(recvDataDec, 33, 64)

    log.output("cardKey:", hex.hexify(cardKey))
    
    log.output("recvMACComputed:", hex.hexify(recvMACComputed))
    
    log.output("\tcardRNDDec:", hex.hexify(cardRNDDec))
    log.output("\tcardRND:", hex.hexify(cardRND))
    log.output("\tcardIDDec:", hex.hexify(cardIDDec))
    log.output("\tcardID:", hex.hexify(cardID))
    log.output("\tifdRNDDec:", hex.hexify(ifdRNDDec))
    log.output("\tifdRND:", hex.hexify(ifdRND))
    log.output("\tifdIDDec:", hex.hexify(ifdIDDec))
    log.output("\tifdID:", hex.hexify(ifdID))
    
    assert(recvMACComputed == recvMAC)
    assert(cardRNDDec == cardRND)
    assert(cardIDDec == cardID)
    assert(ifdRNDDec == ifdRND)
    assert(ifdIDDec == ifdID)
    
    local secret = util.xor_string(cardKey, ifdKey)
    
    self.sessENC, self.sessMAC, self.ssc = self:SetupSM(secret, cardRND, ifdRND)
    
	-- self.ActiveSM = true;
    
    self._performed_mutual_auth = true
    return self.sessENC, self.sessMAC, self.ssc
end

function NXPIASSmartCard.mt:read_serial_number(force)
    log.output("NXPIASSmartCard:read_serial_number(): force=", force)
    if not self.CSN or force then
        log.output("NXPIASSmartCard:read_serial_number(): reading..." )
        
        local read_csn = hexf2("00 cb 7f ff 08")
        local resp = self:sm_transmit(read_csn, false)
        local sw = string.sub(resp, -2, -1)
        
        if sw == hexf('6D00') or sw == hexf('6a86') then
            log.output("NXPIASSmartCard:read_serial_number(): try reselecting main CD APPLET...")
            self:sm_transmit(NXPIASSmartCard.SELECT_MAIN_APPLET_MF_AID, false)
            resp = self:sm_transmit(read_csn, false)
            sw = string.sub(resp, -2, -1)
        end
         
        if sw ~= hexf('9000') and sw ~= hexf('6282') then
            error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'read_serial_number error' ))
        end
        self.CSN = hex.hexify(string.sub(resp, 1, 8))
    else
        log.output("NXPIASSmartCard:read_serial_number(): cached!" )
    end
    log.output("NXPIASSmartCard:read_serial_number():", hex.hexify(self.CSN) )
    return self.CSN
end


function NXPIASSmartCard.mt:verify(bso, pin, backtracking, use_sm)
    log.output("NXPIASSmartCard:verify():" )
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
        log.output('NXPIASSmartCard:verify(): Error ' .. hexify(sw) )
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'verify Error' ))
    end
end


function NXPIASSmartCard.mt:read_cert(fid, use_sm)

    log.output('NXPIASSmartCard:read_cert():', hex.hexify(fid), use_sm)
    
    use_sm = use_sm == nil and self.ActiveSM or use_sm

    self:select(fid, true, use_sm)
    local offset = 0
    local der_size = self:read_binary(offset, 4, use_sm)

    if string.sub(der_size, 1, 2) ~= hexf('3082') then
        error('NXPIASSmartCard read_cert Error: bad certificate')
    end
    local size = string.byte(der_size, 3) * 256 + string.byte(der_size, 4)
    local cert =  der_size .. self:mread_binary(offset+4, size, use_sm)        

    return cert
end

local cachable_attributes = {
"dh_g",
"dh_p",
"dh_q",
"has_sscd",
}

function NXPIASSmartCard.mt:get_cachable_dict()
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

function NXPIASSmartCard.mt:set_cachable_dict(cache)

    for i=1,table.getn(cachable_attributes) do
        local attr = cachable_attributes[i]
        if type(cache[attr]) == "string" then
            self[attr] = hex.hexf(cache[attr])
            log.output(string.format('NXPIASSmartCard:set_cachable_dict(): restored "%s" -> "%s"', attr, hex.hexify(self[attr] or "") ))
        elseif cache[attr] ~= nil then
            self[attr] = cache[attr]
            log.output(string.format('NXPIASSmartCard:set_cachable_dict(): restored "%s" -> "%s"', attr, tostring(self[attr]) or ""))
        end
    end
    
end

function NXPIASSmartCard.mt:delete_SDO(objClass, kid, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output('NXPIASSmartCard:delete_SDO()')

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
    
    local delete_apdu = hex.hexf("80e5%S%S00", objClass, kid)
    
    local recv = self:sm_transmit(delete_apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    return sw == hexf('9000')
end

function NXPIASSmartCard.mt:create_RSA_SDO_for_keygen(objClass, kid, bits, mapped_acs, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output('NXPIASSmartCard:create_RSA_SDO_for_keygen()', objClass, kid, bits)

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
    
    local unmapped_acs = NXPIASSmartCard.unmap_ambs(string.byte(objClass), mapped_acs)
    local acs = NXPIASSmartCard.build_ambs(unmapped_acs)
    
    log.output("NXPIASSmartCard:create_RSA_SDO_for_keygen(): acs:", hex.hexify(acs))
    
    local acContact = hex.hexf("8C%P", acs)
    local acContactless = hex.hexf("9C%P", acs)
    
    local acsTLV = hex.hexf("A1%P", acContact .. acContactless)
    local value = hex.hexf("8002%>%H", bits/8) .. acsTLV

    local docp = hex.hexf("A0%P", value)
   
    local doup = hex.hexf("%>%H00",  NXPIASSmartCard.object_classes_acs[string.byte(objClass)].tag)

    local tag_70 = hex.hexf("70%P", docp .. doup)
    local create_apdu = hex.hexf("80E1%S%S%P", objClass, kid, tag_70)

    local recv = self:sm_transmit(create_apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'create SDO Error'))
    end
end

function NXPIASSmartCard.mt:create_ECDSA_SDO_for_keygen(objClass, kid, bits, mapped_acs, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output('NXPIASSmartCard:create_ECDSA_SDO_for_keygen()', objClass, kid, bits)

    local curve = ecdhlib.get_curve("secp256r1")
    if bits == 256 then
        curve = ecdhlib.get_curve("secp256r1")
    elseif bits == 384 then
        curve = ecdhlib.get_curve("secp384r1")
    elseif bits == 521 or bits == 528 then
        curve = ecdhlib.get_curve("secp521r1")
    else
        error("NXPIASSmartCard::create_ECDSA_SDO_for_keygen(): unsupported curve")
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
    
    local unmapped_acs = NXPIASSmartCard.unmap_ambs(string.byte(objClass), mapped_acs)
    local acs = NXPIASSmartCard.build_ambs(unmapped_acs)
    
    log.output("NXPIASSmartCard:create_ECDSA_SDO_for_keygen(): acs:", hex.hexify(acs))
    
    local acContact = hex.hexf("8C%P", acs)
    local acContactless = hex.hexf("9C%P", acs)
    
    local key_bytes = curve.keysize
    local acsTLV = hex.hexf("A1%P", acContact .. acContactless)
    local value = hex.hexf("8002%>%H", key_bytes) .. acsTLV

    local docp = hex.hexf("A0%P", value)
   
    -- DOUP: create ECDSA curve components
    local doup_tag = string.format("%04X",  NXPIASSmartCard.object_classes_acs[string.byte(objClass)].tag)
    

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
    
    local tag_70 = BUILD_TLV_BER("70", docp .. doup)
    -- print("tag_70:", hex.hexify(tag_70))
    -- assert(string.len(tag_70) < 256)
    
    local create_apdu_header = hex.hexify(hex.hexf("80E1%S%S", objClass, kid)) .. "%P"
    local create_apdu_header10 = hex.hexify(hex.hexf("90E1%S%S", objClass, kid)) .. "%P"
    local block_len = 220
    local apdus = {}
    append_chained_apdus(create_apdu_header, create_apdu_header10, tag_70, block_len, apdus)
    
    local recv
    for i=1,table.getn(apdus) do
        recv = self:sm_transmit(apdus[i], true)
        local sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'create_ECDSA_SDO_for_keygen Error'))
        end
        
    end
    
    -- local recv = self:sm_transmit(create_apdu, use_sm)
    -- sw = string.sub(recv, -2, -1)
    -- if sw ~= hexf('9000') then
        -- error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'create_ECDSA_SDO_for_keygen create SDO Error'))
    -- end
end


function NXPIASSmartCard.mt:generate_RSA(kid, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output('NXPIASSmartCard:generate_RSA()', kid, use_sm)

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
    log.output ("NXPIASSmartCard:generate_RSA(): recv:", hex.hexify(recv))
    log.output ("NXPIASSmartCard:generate_RSA(): elapsed:", os.time() - start)
    
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'generate_RSA Error'))
    end
end

function NXPIASSmartCard.mt:generate_ECC(kid, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output('NXPIASSmartCard:generate_ECC()', kid, use_sm)

    if type(kid) == 'number' then 
        kid = hex.hexf('%B', kid)
    elseif string.len(kid) == 2 then 
        kid = hex.hexf(kid)
    end

    local recv
    
    local start = os.time()
    local genrate_key_pair = hex.hexf("00470000057003bf92%S", kid)
    recv = self:sm_transmit(genrate_key_pair, use_sm)
    log.output ("NXPIASSmartCard:generate_ECC(): recv:", hex.hexify(recv))
    log.output ("NXPIASSmartCard:generate_ECC(): elapsed:", os.time() - start)
    
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'generate_ECC Error'))
    end
end



function NXPIASSmartCard.mt:update_binary(offset, data, use_sm, sfi)
    local recv
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    sfi = sfi or 0
    local size = string.len(data)
    log.output("NXPIASSmartCard:update_binary(): writing to:", offset, "size:", size, "sfi:", sfi)
    
    local payload = hex.hexf("5402%>%H5381%P", offset, data)
    local apdu = hex.hexf("00d7%>%H%P", sfi, payload)

    recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'update_binary Error'))
    end
end

function NXPIASSmartCard.mt:mupdate_binary(offset, data, use_sm, sfi, padding_blocks)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output("NXPIASSmartCard:mupdate_binary(): offset=", offset, "sfi=", sfi)
    local buffer_size = NXPIASSmartCard.MAX_TRANSMIT_BUFFER_SIZE
    padding_blocks = padding_blocks or 0
    local padding_max_len = padding_blocks * buffer_size
    if padding_max_len > 0 then
        local padding_len = padding_max_len - math.mod(string.len(data), buffer_size)
        if padding_len > 0 then
            data = data .. string.rep("\0", padding_len)
            log.output("NXPIASSmartCard:mupdate_binary(): added padding_len:", padding_len)
        end
    end
    local left = string.len(data)
    log.output("NXPIASSmartCard:mupdate_binary():multi update from:", offset, "size:", left, "chunks:", buffer_size)
    local curOffset = offset
    local chunk
    while left > 0 do
        chunk = string.sub(data, curOffset-offset+1, curOffset-offset + buffer_size)
        if chunk == 0 then
            log.output("NXPIASSmartCard:mupdate_binary(): WARNING: specified data len is not enough?")
            break
        end
        self:update_binary(curOffset, chunk, use_sm, sfi)
        left = left - string.len(chunk)
        curOffset = curOffset + string.len(chunk)
    end
end

function NXPIASSmartCard.mt:mupdate_binary_smart(offset, data, use_sm, sfi)
    log.output("NXPIASSmartCard:mupdate_binary_smart():")
    return self:mupdate_binary(offset, data, use_sm, sfi, 2)
end



function NXPIASSmartCard.mt:delete_file(path, relative, use_sm)
    local recv
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    sfi = sfi or 0
    log.output("NXPIASSmartCard:delete_file():")
    local pcRes = true
    
    if path then
        pcRes = pcall(function()
            self:select(path, relative, use_sm)
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


function NXPIASSmartCard.mt:create_binary_file(fid, size, use_sm, sdo_write, sdo_read, sdo_delete)
    local recv
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    sfi = sfi or 0
    log.output("NXPIASSmartCard:create_binary_file(): size:", size)
    
    sdo_write = sdo_write or (self.ID_SE_MAIN + NXPIASSmartCard.ID_SBC_PIN )
    sdo_read = sdo_read or NXPIASSmartCard.ID_SE_ALWAYS
    sdo_delete = sdo_delete or sdo_write
    
    if type(fid) == "number" then
        fid = hex.hexf("%>%H", fid)
    elseif string.len(fid) > 2 then
        error(NXPIASSmartCard.NXPIASSmartCardError.new("", 'create_binary_file: invalid fid'))
    end
    
    log.output(string.format("NXPIASSmartCard:create_binary_file(): fid:%s, sdo_write:%02X, sdo_read:%02X, sdo_delete:%02X",
        hex.hexify(fid), sdo_write, sdo_read, sdo_delete) )
   
    local acs = hex.hexf("40%B02%B01%B", sdo_delete, sdo_write, sdo_read)
    local allAcs = hex.hexf("8c%P9c%P", acs, acs)
    local FDO =  hex.hexf("8002%>%H82010183%P88008a0105a1%P", size, fid, allAcs)
    local payload = hex.hexf("62%P", FDO)
    local apdu = hex.hexf("00e00000%P", payload)

    recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'create_binary_file Error'))
    end
end



function NXPIASSmartCard.mt:import_private_key(id, m, e, p, q, iq, dp, dq)
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
        log.output(string.format("NXPIASSmartCard:import_private_key(): set_pub_exp_mod_data: %s", hex.hexify(set_pub_exp_mod_data)))
        
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
            log.output(string.format("NXPIASSmartCard:import_private_key(): set_priv component: %s", hex.hexify(set_priv)))

            append_chained_apdus(put_data_header, put_data_header10, set_priv, block_len, apdus)
        end

    end
    
    
    for i=1,table.getn(apdus) do
        recv = self:sm_transmit(apdus[i], true)
        local sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'import_private_key Error'))
        end
        -- log.output(string.format("NXPIASSmartCard:import_private_key(): APDU: %s", hex.hexify(apdus[i])))
    end
    
end

function NXPIASSmartCard.mt:import_ecc_private_key(id, ec_point, value)
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
        
        log.output(string.format("NXPIASSmartCard:import_ecc_private_key(): set_pub_data: %s", hex.hexify(set_pub_data)))
        append_chained_apdus(put_data_header, put_data_header10, set_pub_data, block_len, apdus)
    end


    if value_doup then -- no ec_point (ec_point = G * value)
        local set_priv_data =
         BUILD_TLV_BER("70", BUILD_TLV_BER("BF92" .. id, BUILD_TLV_BER("7f48", value_doup) ) )
        
        log.output(string.format("NXPIASSmartCard:import_ecc_private_key(): set_priv_data: %s", hex.hexify(set_priv_data)))
        append_chained_apdus(put_data_header, put_data_header10, set_priv_data, block_len, apdus)

    end
    
    
    for i=1,table.getn(apdus) do
        recv = self:sm_transmit(apdus[i], true)
        local sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'import_ecc_private_key Error'))
        end
        -- log.output(string.format("NXPIASSmartCard:import_ecc_private_key(): APDU: %s", hex.hexify(apdus[i])))
    end
    
end

-- print(util.repr(NXPIASSmartCard.parse_ambs(hex.hexf("F3D700D7FF00D0D3D3"))))

return NXPIASSmartCard


--===========================================================================
end
}
_LOADED['token-nxp-chipdoc-lite'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- token-nxp-chipdoc-lite.lua
local NXPChipDocLite = require 'NXPChipDocLite'
local CnsSmartcard = require 'CnsSmartcard'
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
local licensing = require "licensing"

local Ed25519_curves_oids = ecdhlib.Ed25519_curves_oids

local PIN_POLICY_HISTORY_HASH_LEN = 20
local CKO_PIN_POLICY = tonumber("80001000", 16)
local CKO_FINGERPRINT = tonumber("80002001", 16)

local PINPAD_CTL_VERIFY=1
local PINPAD_CTL_CHANGE=2
local PINPAD_CTL_RESET=3

local PINPAD_CTL_PIN=256
local PINPAD_CTL_PUK=512
local PINPAD_CTL_DSPIN=768
local PINPAD_CTL_DSPUK=1024

-- add custom mechanism correspondng to crypto_box_easy
CKM.CURVE25519_CRYPTO_BOX = CKM.CURVE25519_CRYPTO_BOX or (CKM.VENDOR_DEFINED + CKM.ECDH1_DERIVE + CKM.HKDF_DERIVE)


local emt = {
	OperationOk = 0, -- Report "operation success", generic, return 0
	OperationFailed = 1, -- Report "operation failed", generic, return 0

	PinIncorrect = 8, -- Report "PIN incorrect, retry?", return 1 if YES, 0 if NO
	PinLocked = 9,    -- Report "Smartcard locked", return 0
	PinDeactivated = 10, -- Report "Smartcard not yet activated", return 0

	PukIncorrect = 16, -- Report "PUK incorrect, retry?", return 1 if YES, 0 if NO
	PukLocked = 17, -- Report "PUK locked", return 0

    }

local CNS0_ID = "CNS0"
local CNS0_CERT_PATH = hex.hexf("11001101")
local CNS0_PDATA_PATH = hex.hexf("11001102")
local CNS0_KEY_PATH = hex.hexf("3f01")


local function GetCertTemplate(populateCertFunc)
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

local function GetPubKeyTemplate(populatePubKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PUBLIC_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(true),
        [ CKA.LABEL ] = populatePubKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = populatePubKeyFunc,
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = eCK.BBOOL(true),
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
        [ CKA.MODULUS ] = populatePubKeyFunc,
        [ CKA.MODULUS_BITS ] = populatePubKeyFunc,
        [ CKA.PUBLIC_EXPONENT ] = populatePubKeyFunc,
    }
end

local function GetPrivKeyTemplate(populatePubKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PRIVATE_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(true),
        [ CKA.LABEL ] = populatePubKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = populatePubKeyFunc,
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = eCK.BBOOL(true),
        [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.RSA_PKCS_KEY_PAIR_GEN),
        -- [ CKA.ALLOWED_MECHANISMS ] = '',
        -- Private Key
        [ CKA.SUBJECT ] = '',
        [ CKA.SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.DECRYPT ] = eCK.BBOOL(false),
        [ CKA.SIGN ] = eCK.BBOOL(true),
        [ CKA.SIGN_RECOVER ] = eCK.BBOOL(false),
        [ CKA.UNWRAP ] = eCK.BBOOL(false),
        [ CKA.EXTRACTABLE ] = eCK.BBOOL(false),
        [ CKA.ALWAYS_SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.NEVER_EXTRACTABLE ] = eCK.BBOOL(true),
        [ CKA.WRAP_WITH_TRUSTED ] = eCK.BBOOL(false),
        -- [ CKA.UNWRAP_TEMPLATE ] = '',
        [ CKA.ALWAYS_AUTHENTICATE ] = populatePubKeyFunc,
        -- RSA Private Key
        [ CKA.MODULUS ] = populatePubKeyFunc,
        [ CKA.PUBLIC_EXPONENT ] = populatePubKeyFunc,
        [ CKA.PRIVATE_EXPONENT ] = -1,
        [ CKA.PRIME_1 ] = -1,
        [ CKA.PRIME_2 ] = -1,
        [ CKA.EXPONENT_1 ] = -1,
        [ CKA.EXPONENT_2 ] = -1,
        [ CKA.COEFFICIENT ] = -1,
    }
end

local function GetECCPrivKeyTemplate(populateKeyFunc, cka_key_type)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PRIVATE_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(true),
        [ CKA.LABEL ] = populatePubKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(cka_key_type or CKK.ECDSA),
        [ CKA.ID ] = populatePubKeyFunc,
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = eCK.BBOOL(true),
        [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.EC_KEY_PAIR_GEN),
        -- [ CKA.ALLOWED_MECHANISMS ] = '',
        -- Private Key
        [ CKA.SUBJECT ] = '',
        [ CKA.SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.DECRYPT ] = eCK.BBOOL(false),
        [ CKA.SIGN ] = eCK.BBOOL(true),
        [ CKA.SIGN_RECOVER ] = eCK.BBOOL(false),
        [ CKA.UNWRAP ] = eCK.BBOOL(false),
        [ CKA.EXTRACTABLE ] = eCK.BBOOL(false),
        [ CKA.ALWAYS_SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.NEVER_EXTRACTABLE ] = eCK.BBOOL(true),
        [ CKA.WRAP_WITH_TRUSTED ] = eCK.BBOOL(false),
        -- [ CKA.UNWRAP_TEMPLATE ] = '',
        [ CKA.ALWAYS_AUTHENTICATE ] = populatePubKeyFunc,
        -- ECC Private Key
        [ CKA.EC_PARAMS ] = populateKeyFunc,
        [ CKA.EC_POINT ] = populateKeyFunc,
        [ CKA.VALUE ] = -1,
    }
end

local function GetECCPubKeyTemplate(populateKeyFunc, cka_key_type)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PUBLIC_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(true),
        [ CKA.LABEL ] = populateKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(cka_key_type or CKK.ECDSA),
        [ CKA.ID ] = populateKeyFunc,
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = eCK.BBOOL(true),
        [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.EC_KEY_PAIR_GEN),
        -- [ CKA.ALLOWED_MECHANISMS ] = '',
        -- Public Key
        [ CKA.SUBJECT ] = '',
        [ CKA.ENCRYPT ] = eCK.BBOOL(true),
        [ CKA.VERIFY ] = eCK.BBOOL(true),
        [ CKA.VERIFY_RECOVER ] = eCK.BBOOL(false),
        [ CKA.WRAP ] = eCK.BBOOL(false),
        [ CKA.TRUSTED ] = eCK.BBOOL(true),
        -- [ CKA.WRAP_TEMPLATE ] = '',
        -- ECC Public Key
        [ CKA.EC_PARAMS ] = populateKeyFunc,
        [ CKA.EC_POINT ] = populateKeyFunc,
    }
end


local function GetDataObjectTemplate(populateKeyFunc)
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

local function GetFingerprintObjectTemplate(populateKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO_FINGERPRINT),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(false),
        [ CKA.LABEL ] = populateKeyFunc,
        -- Data
        [ CKA.ID ] = populateKeyFunc,
    }
end

local function GetSecretKeyTemplate(populatePubKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.SECRET_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(true),
        [ CKA.LABEL ] = populatePubKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.AES),
        [ CKA.ID ] = populatePubKeyFunc,
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = eCK.BBOOL(true),
        [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.AES_KEY_GEN),
        -- [ CKA.ALLOWED_MECHANISMS ] = '',
        -- Private Key
        [ CKA.SUBJECT ] = '',
        [ CKA.SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.DECRYPT ] = eCK.BBOOL(false),
        [ CKA.SIGN ] = eCK.BBOOL(false),
        [ CKA.SIGN_RECOVER ] = eCK.BBOOL(false),
        [ CKA.UNWRAP ] = eCK.BBOOL(false),
        [ CKA.EXTRACTABLE ] = eCK.BBOOL(false),
        [ CKA.ALWAYS_SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.NEVER_EXTRACTABLE ] = eCK.BBOOL(true),
        [ CKA.WRAP_WITH_TRUSTED ] = eCK.BBOOL(false),
        -- [ CKA.UNWRAP_TEMPLATE ] = '',
        [ CKA.ALWAYS_AUTHENTICATE ] = eCK.BBOOL(false),
        --  Private Key
        [ CKA.VALUE ] = -1,
    }
end


local MinKSize, MaxKSize = 1024, 4096
local t = {
    name = 'nxpcdlite',
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
        
        [ CKM.EC_EDWARDS_KEY_PAIR_GEN ] = {ulMinKeySize=ecdhlib.ulMinKeySizeEd25519, ulMaxKeySize=ecdhlib.ulMaxKeySizeEd25519, flags=CKF.HW+CKF.GENERATE_KEY_PAIR+CKF.EC_OID+CKF.EC_F_P+CKF.EC_UNCOMPRESS},
        [ CKM.EDDSA ] = {ulMinKeySize=ecdhlib.ulMinKeySizeEd25519, ulMaxKeySize=ecdhlib.ulMaxKeySizeEd25519, flags=CKF.HW+CKF.SIGN+CKF.EC_OID+CKF.EC_F_P+CKF.EC_UNCOMPRESS},
        [ CKM.CURVE25519_CRYPTO_BOX ] = {ulMinKeySize=ecdhlib.ulMinKeySizeX25519, ulMaxKeySize=ecdhlib.ulMaxKeySizeX25519, flags=CKF.HW+CKF.SIGN+CKF.DERIVE+CKF.EC_OID+CKF.EC_F_P+CKF.EC_UNCOMPRESS},
        
    },
    nxp_hcard = nil,
    capabilities = { private_attributes_readable=true, always_authenticate_on_cert=false, },
    NXPChipDocLite=NXPChipDocLite,
    card_cache = "card_cache",
}
t.mt.__index = t.mt


local fpctl_exe_path = utility.getparentpath(modules.modulepath()) .. "/fpctl2.exe"
local osname, platform = p11wrap.osname()
local function fp_reader_query()

    if platform ~= "win32" then
        return false
    end
    local cmd = string.format('"%s" query 500', fpctl_exe_path)
    
    log.output('fp_reader_query(): cmd:', cmd)


    -- print(cmd)
    local res = w32.create_process(cmd, nil, true)
    -- print(res)
    
    log.output('fp_reader_query(): res:', res)
    return res == 0
end

local function fp_reader_get_minutia(timeout)

    if platform ~= "win32" then
        return
    end
    
    timeout = timeout or 30000
    local rootPath = os.getenv("TMP") or os.getenv("TEMP") or os.getenv("LocalAppData") or os.getenv("AppData")


    local minutia_file_name = rootPath .. "/tmp_" .. hex.hexify(sm.gen_random(4))


    local cmd = string.format('"%s" getfinger %d "%s"', fpctl_exe_path, timeout, minutia_file_name)

    log.output('fp_reader_get_minutia(): minutia_file_name:', minutia_file_name)
    log.output('fp_reader_get_minutia(): cmd:', cmd)

    -- print(cmd)
    local res = w32.create_process(cmd, nil, true)
    -- print(res)
    log.output('fp_reader_get_minutia(): res:', res)

    if res == 0 then
        log.output('fp_reader_get_minutia(): readig minutia from file:', minutia_file_name)
        local f = io.open(minutia_file_name, "r")
        local minutia = f:read("*a")
        f:close()
        os.remove(minutia_file_name)
        
        -- print(minutia)
        while string.sub(minutia, -1) == "\n" or string.sub(minutia, -1) == "\r" do
            minutia = string.sub(minutia, 1, -2)
        end
        -- print(minutia);
        log.output('fp_reader_get_minutia(): minutia:', minutia)
        return minutia
    end
end

function t.mt:initialize(cfg)
    log.output('token-nxp-chipdoc-lite:initialize():')
    local files = {}
    
    -- FILE prefixes:
    -- DAF0 - DAFF: secret keys
    -- DBXX: NOT USED
    -- DCXX: DATA Objects
    -- DEXX: PRIVATE KEYS
    -- DFXX: PUBLIC KEYS
    
    self.authID_Card_PIN = 'PIN'
    self.authID_Card_PUK = 'PUK'
    self.authID_Card_FINGERPRINT = 'FINGERPRINT'
    
    files.GENERIC = hexf("5100")
    files.SSCD = hexf("5200")
    
    -- GENERIC ADF
    files.OD = hexf("5031")
    files.FPOD = hexf("5039")
    files.PrivKD = hexf("7002")
    files.secretKD = hexf("7003")
    files.PubKD = hexf("7004")
    files.CDF = hexf("7005")
    files.dataDF = hexf("7006")
    files.AODF = hexf("7001")

    files.tokenInfo = hexf("5032") -- ?
    -- files.UPDATE_INFO = hexf("ABDE")
    files.LICENSE = hexf("11CE")
    files.PIN_POLICY = hexf("FFF0")
    files.PIN_POLICY_HISTORY = hexf("FFF1")
    files.tokenInfo_sfi = tonumber("12", 16)
    files.tokenInfo_lastModified_offset = 70
    files.tokenInfo_lastModified_size = 14

    self.files = files

    self.capabilities = utility.clone_table(t.capabilities)
    self.nxp_hcard = NXPChipDocLite.new(self.hcard)
    
    local status, err = self.hcard:status()
    if status and type(status.atr) == "string" and string.find(status.atr, "CNS", 1, false) then
        self.is_cns = true
    end
    log.output('nxp-chipdoc-lite token initialize(): is_cns:', self.is_cns)
    self.mechanisms = utility.clone_table(t.mechanisms)
    self.request_plugin_valid = w32.request_plugin_valid()

    self.pinRetryMax = 3
    self.pukRetryMax = 3
    self.puk_not_modifiable = false
    self.slow_card = false
    self.userPinInitialized = true
    self.cfg = cfg or utility.parse_cfg()


    self.cfg["fcpr"] = self.cfg["fcpr"] or self.cfg["ncdlfcpr"]
    self.cfg["xproc"] = self.cfg["xproc"] or self.cfg["ncdlxproc"]
    
    self.cfg["dspinusegui"] = self.cfg["ncdldspinusegui"] or self.cfg["dspinusegui"]
    if self.cfg["dspinusegui"] then self.cfg["dspinusegui"]=string.lower(self.cfg["dspinusegui"])
    else self.cfg["dspinusegui"]='false' end

    
    self.cfg["pinpad"] = string.lower(self.cfg["ncdlpinpad"] or self.cfg["pinpad"] or "false")
    
    self.cfg["hidecachedspincheck"] = self.cfg["ncdlhidecachedspincheck"] or self.cfg["hidecachedspincheck"]
    if self.cfg["hidecachedspincheck"] then self.cfg["hidecachedspincheck"]=string.lower(self.cfg["hidecachedspincheck"])
    else self.cfg["hidecachedspincheck"]='true' end
    
    self.check_box_visible = 0
    if self.cfg["hidecachedspincheck"] == 'true' then
        self.check_box_visible = nil
    end
    
    self._cfg_use_pin_padding = true -- always use padding
    
    if self.cfg["pinpad"] == "true" then
        self._cfg_use_pinpad = true
        
        if pcsc.pinpad_ctl_ex and pcsc.pinpad_reader(self.reader_name, self.nxp_hcard.card) then
            log.output('nxp-chipdoc-lite token initialize(): PINPAD: current HW is a supported pinpad reader, setting self._pinpad_hw_reader = true ')
            self._pinpad_hw_reader = true
        end
    end
    
    log.output('nxp-chipdoc-lite token initialize(): _cfg_use_pin_padding:', _cfg_use_pin_padding)
    
    if self.cfg["ncdlmobile"] then
        self.cfg["mobile"] = self.cfg["ncdlmobile"]
    end
    if self.cfg["mobile"] then self.cfg["mobile"]=string.lower(self.cfg["mobile"])
    else self.cfg["mobile"]='false' end
    
    self._mobile_enabled = self.cfg["mobile"] == "true"
    log.output('nxp-chipdoc-lite token initialize(): _mobile_enabled:', self._mobile_enabled)
    
    if self.cfg["ncdlavoiduselastupdate"] then
        self.cfg["avoiduselastupdate"] = self.cfg["ncdlavoiduselastupdate"]
    end
    if self.cfg["avoiduselastupdate"] then self.cfg["avoiduselastupdate"]=string.lower(self.cfg["avoiduselastupdate"])
    else self.cfg["avoiduselastupdate"]='false' end
    
    
    if self.cfg["ncdlumcachepath"] then
        self.cfg["umcachepath"] = self.cfg["ncdlumcachepath"]
    end
    if self.cfg["umcachepath"] then
        self._umcachepath = self.cfg["umcachepath"]
        log.output('nxp-chipdoc-lite token initialize(): using _umcachepath=', self._umcachepath)
    end

    
    self.use_cpr_mode = true -- default active
    if self.cfg["fcpr"] then
        self.cfg["fcpr"]=string.lower(self.cfg["fcpr"])
        self.use_cpr_mode = self.cfg["fcpr"] ~= "false"
    end
    
    if self.cfg["xproc"] then self.cfg["xproc"]=string.lower(self.cfg["xproc"])
    else self.cfg["xproc"]='true' end
    
    if self.cfg["ncdlcaching"] then
        self.cfg["caching"] = self.cfg["ncdlcaching"]
    end
    if self.cfg["caching"] then self.cfg["caching"]=string.lower(self.cfg["caching"])
    else self.cfg["caching"]='false' end
    

    if self.cfg["caching"] ~= "false" then
        log.output('nxp-chipdoc-lite token initialize(): activating general caching...')

        log.output('nxp-chipdoc-lite token initialize(): forcing avoiduselastupdate and fastread')
        self.cfg["avoiduselastupdate"] = "true"
        self.cfg["fastread"] = "true"
  
    end
    
    log.output('nxp-chipdoc-lite token initialize(): use_cpr_mode:', self.use_cpr_mode)
    
    self._AvoidUseLastUpdate = self.cfg["avoiduselastupdate"] == "true"
    log.output('nxp-chipdoc-lite token initialize(): using _AvoidUseLastUpdate=', self._AvoidUseLastUpdate)
    
    
    if os.getenv("IS_BIT4ID_AUTOIMPORTER") == "true" then
        self._clear_cache = true
        log.output('nxp-chipdoc-lite token initialize(): IS_BIT4ID_AUTOIMPORTER is set, forcing _clear_cache=true')
    end
    

    if self._cache_id == nil then
        self:flush_cache()
    end
end

function t.mt:begin_transaction()
    self.nxp_hcard:begin_transaction()
end

function t.mt:end_transaction()
    self.nxp_hcard:end_transaction()
end

function t.mt:_call_on_end_transaction()
    log.output('token-nxp-chipdoc-lite:_call_on_end_transaction()...')
    if self.nxp_hcard.on_end_transaction then
        self.nxp_hcard:on_end_transaction()
    end
end

function t.mt:_call_on_begin_transaction()
    log.output('token-nxp-chipdoc-lite:_call_on_begin_transaction()...')
    if self.nxp_hcard.on_begin_transaction then
        self.nxp_hcard:on_begin_transaction()
    end
end

function t.mt:finalize()
    log.output("token-nxp-chipdoc-lite:finalize():", self.userType)
    utility.forget_token_changed(self, "cache")
end


local jcop_versions = {
    ["J3R6000373181200"]={
        platform_id="J3R6000373181200", platform_name="JCOP4.5 P71", platform_version="4.5",
        app_id="ChipDoc4", app_name="ChipDoc4", app_version="4",
    },
    ["J3R35101FA9E0400"]={
        platform_id="J3R35101FA9E0400", platform_name="JCOP4 P71", platform_version="4",
        app_id="ChipDoc3", app_name="ChipDoc3", app_version="3",
    },
    ["J3R3510236310400"]={
        platform_id="J3R3510236310400", platform_name="JCOP4 P71", platform_version="4",
        app_id="ChipDoc3", app_name="ChipDoc3", app_version="3",
    },
    ["J3R35103B01B0400"]={
        platform_id="J3R35103B01B0400", platform_name="JCOP4 P71", platform_version="4",
        app_id="ChipDoc3", app_name="ChipDoc3", app_version="3",
    },
    ["J3R351021EEE0400"]={
        platform_id="J3R351021EEE0400", platform_name="JCOP4 P71", platform_version="4",
        app_id="ChipDoc3", app_name="ChipDoc3", app_version="3",
    },
    ["J3R3510264571100"]={
        platform_id="J3R3510264571100", platform_name="JCOP4 P71", platform_version="4",
        app_id="ChipDoc3", app_name="ChipDoc3", app_version="3",
    },
    ["J3R3510265451100"]={
        platform_id="J3R3510265451100", platform_name="JCOP4 P71", platform_version="4",
        app_id="ChipDoc3", app_name="ChipDoc3", app_version="3",
    },
    
}
function t.mt:get_product_infos()
    log.output("get_product_infos()...")

    local infos = {
        platform_id="", platform_name="JCOP4 P71", platform_version="4",
        app_id="ChipDoc3", app_name="ChipDoc3", app_version="3",
    }
    local info = self.info
    if info then
        local infos_cached = utility.cache_read(info.serialNumber, "product_infos", self._AvoidUseLastUpdate, self._umcachepath)
        if infos_cached then
            local infos_cached_decoded = json.decode(infos_cached)
            if infos_cached_decoded then
                return infos_cached_decoded
            end
        end
    end
    local recv, sw
    recv = self.nxp_hcard.card:transmit(hex.hexf("00a4040006A00000015100")) -- select GP
    sw = string.sub(recv, -2, -1)
    if sw == hex.hexf("9000") then
        recv = self.nxp_hcard.card:transmit(hex.hexf("80CA00FE02DF28")) -- GET DATA - IDENTIFY
        sw = string.sub(recv, -2, -1)
        if sw == hex.hexf("9000") then
        
            local ber = der.parse_tlv_ber(recv)
            -- print (util.repr(ber))

            if ber[tonumber("FE", 16)] then
                local ber1 = der.parse_tlv_ber(ber[tonumber("FE", 16)])
                -- print (util.repr(ber1))

                if ber1[tonumber("DF28", 16)] then
                    local ber2 = der.parse_tlv_ber(ber1[tonumber("DF28", 16)])
                    -- print (util.repr(ber2))
                    if ber2[3] then
                        local platform_id = string.sub(ber2[3], 1, 16) 
                        infos = utility.clone_table(jcop_versions[platform_id])
                        if not infos then
                            if string.sub(ber2[3], 1, 4) == "J3R3" then
                                infos = {
                                    platform_id=platform_id, platform_name="JCOP4", platform_version="4",
                                    app_id="ChipDoc3", app_name="ChipDoc3", app_version="3",
                                }
                            elseif string.sub(ber2[3], 1, 4) == "J3R6" then
                                infos = {
                                    platform_id=platform_id, platform_name="JCOP4.5", platform_version="4.5",
                                    app_id="ChipDoc4", app_name="ChipDoc4", app_version="4",
                                }
                            end
                        end
                    end
                end
            end
        end
        self.nxp_hcard:select_applet()
        recv = self.nxp_hcard.card:transmit(hex.hexf("00CA011600")) -- GET DATA - APPLET VERSION
        sw = string.sub(recv, -2, -1)
        if sw == hex.hexf("9000") then
            infos.app_id = string.format("ChipDoc%d", string.byte(recv, 1))
            infos.app_name = infos.app_id
            infos.app_version = string.format("%d.%d.%d.%d", string.byte(recv, 1), string.byte(recv, 2), string.byte(recv, 3), string.byte(recv, 4))
        end
        
    end
    infos.manufacturer = "NXP"
    
    if info then
        local json_cache = json.encode(infos)
        log.output("get_product_infos(): updating cache:", json_cache)
        utility.cache_write(info.serialNumber, "product_infos", json_cache, self._umcachepath)
    end
    return infos
end


function t.mt:_update_retry_counters()

    log.output("token-nxp-chipdoc-lite:_update_retry_counters():")
    if (self.info) then
        pcall (function()
            self.info.flags = self.info.flags - CKF.USER_PIN_LOCKED
            self.info.flags = self.info.flags - CKF.USER_PIN_FINAL_TRY
            self.info.flags = self.info.flags - CKF.USER_PIN_COUNT_LOW
            self.info.flags = self.info.flags - CKF.SO_PIN_LOCKED
            self.info.flags = self.info.flags - CKF.SO_PIN_FINAL_TRY
            self.info.flags = self.info.flags - CKF.SO_PIN_COUNT_LOW
            local pinRetry, pukRetry = self.nxp_hcard:get_pin_puk_status()
            local pinRetryMax = self.pinRetryMax
            local pukRetryMax = self.pukRetryMax
            log.output("token-nxp-chipdoc-lite:_update_retry_counters(): get_pin_puk_status, PIN cur/max", pinRetry, pinRetryMax, "PUK cur/max:", pukRetry, pukRetryMax);
            if pinRetry == 0 then
                self.info.flags = self.info.flags + CKF.USER_PIN_LOCKED
            elseif pinRetry == 1 then
                self.info.flags = self.info.flags + CKF.USER_PIN_FINAL_TRY
            elseif pinRetry < pinRetryMax then
                self.info.flags = self.info.flags + CKF.USER_PIN_COUNT_LOW
            end
            
            if pukRetry == 0 then
                self.info.flags = self.info.flags + CKF.SO_PIN_LOCKED
            elseif pukRetry == 1 then
                self.info.flags = self.info.flags + CKF.SO_PIN_FINAL_TRY 
            elseif pukRetry < pukRetryMax then
                self.info.flags = self.info.flags + CKF.SO_PIN_COUNT_LOW
            end
            
            self.info.pinRetry    = pinRetry
            self.info.pinRetryMax = pinRetryMax
            self.info.pukRetry    = pukRetry
            self.info.pukRetryMax = pukRetryMax
        end)
    end
    
end

function t.mt:_set_pin_flags_ok(setPIN_OK, setPUK_OK)


    log.output("token-nxp-chipdoc-lite:_set_pin_flags_ok(): setPIN_OK", setPIN_OK)
    log.output("token-nxp-chipdoc-lite:_set_pin_flags_ok(): setPUK_OK", setPUK_OK)
    if setPIN_OK then
        self.info.flags = self.info.flags - CKF.USER_PIN_LOCKED
        self.info.flags = self.info.flags - CKF.USER_PIN_FINAL_TRY
        self.info.flags = self.info.flags - CKF.USER_PIN_COUNT_LOW
    end
    if setPUK_OK then
        self.info.flags = self.info.flags - CKF.SO_PIN_LOCKED
        self.info.flags = self.info.flags - CKF.SO_PIN_FINAL_TRY
        self.info.flags = self.info.flags - CKF.SO_PIN_COUNT_LOW
    end
    
end

function t.mt:update_free_mem(info)
    log.output("token-nxp-chipdoc-lite:update_free_mem():")
    if info then
            pcall(function()

            info.ulFreePublicMemory = self.nxp_hcard:get_free_mem()
            info.ulFreePrivateMemory = self.info.ulFreePublicMemory
            log.output("token free space:", info.ulFreePublicMemory);
        end)
    end
end


function t.mt:send_cached_apdu(apdu, update_cache, force_refresh, use_sm)
    local val, err
    local name = "APDU_" .. hex.hexify(apdu)
    log.output(string.format("send_cached_apdu: apdu=%s, update_cache=%s, force_refresh=%s", hex.hexify(apdu), tostring(update_cache), tostring(force_refresh)) )
    local info = self.info
    if self:cache_enabled() and info and not force_refresh then
        log.output("send_cached_apdu: trying cache...")
        val = utility.cache_read(info.serialNumber, name, self._AvoidUseLastUpdate, self._umcachepath)
        log.output(string.format("send_cached_apdu: full cached value=%s", hex.hexify(val or "")) )
        if val then
            return val
        end
    end
    log.output("send_cached_apdu: trying sending to card...")
    val, err = self.nxp_hcard:sm_transmit(apdu, use_sm)
    
    if val then
        log.output(string.format("send_cached_apdu: got fresh value=%s", hex.hexify(val)) )
        if update_cache and self:cache_enabled() and info then
            log.output("send_cached_apdu: updating cache")
            utility.cache_write(info.serialNumber, name, val, self._umcachepath)
        end
    else
        log.output("send_cached_apdu: sm_transmit error:", err )
    end
    return val, err
end


function t.mt:read_card_cache_dict()
    if self:cache_enabled() then
        log.output("token-nxp-chipdoc-lite:read_card_cache_dict(): try reading card_cache...")
        local pcRes, theErrorT = pcall(function()
            local json_cache =  utility.cache_read(self.info.serialNumber, t.card_cache, self._AvoidUseLastUpdate, self._umcachepath)
            if json_cache then
                log.output("token-nxp-chipdoc-lite:read_card_cache_dict(): json_cache:", json_cache)
                local card_cache = json.decode(json_cache)
                log.output("token-nxp-chipdoc-lite:read_card_cache_dict(): restoring card_cache:", utility.repr(card_cache))
                
                if type(card_cache) == "table" then
                    log.output("token-nxp-chipdoc-lite:read_card_cache_dict(): restoring card_cache...")
                    self.nxp_hcard:set_cachable_dict(card_cache)
                end
            end
        end)
        if not pcRes then
            log.output("token-nxp-chipdoc-lite:read_card_cache_dict(): error applying card_cache:", debug.traceback(theErrorT))
        end
    end
end


function t.mt:init_pin_policy(pinPolicy)
    log.output("init_pin_policy()")

    -- struct format
    -- minLen: 1 byte
    -- maxLen: 1 byte
    -- complexityLevel: 1 byte, 0=disable, 1=only digits, 2=only digits and alpha, 2=
    -- pinHistory: 1 byte, 0=disable
    -- pinRetry: 1 byte
    
    -- adjacent   1 byte  allwoed repet|max appear
    -- allow numeric       0x80 | min
    -- allow alpha         0x80 | min
    -- allow symbols       0x80 | min
    -- allow extraascii    0x80 | min


    local pin_policy = string.sub(pinPolicy, 1, 10)
    pin_policy = pin_policy .. string.rep("\0", 10- string.len(pin_policy))
    local minLen, maxLen, complexityLevel, pinHistory, pinRetry = bin.unpack("%B%B%B%B%B", pin_policy)

    log.output("init_pin_policy(): minLen, maxLen, complexityLevel, pinHistory, pinRetry:", minLen, maxLen, complexityLevel, pinHistory, pinRetry)
    
    if minLen > 0 then
        self.info.ulMinPinLen=minLen
    end
    if maxLen > 0 then
        self.info.ulMaxPinLen=maxLen
    end
    local complexityLevel_f = bin.flags(complexityLevel)
    self.complexityLevel = (complexityLevel_f - bin.flags(128+64)).asnumber
    if self.complexityLevel > 3 and string.len(pinPolicy) >= 10 then
        local extPinPolicy = string.sub(pinPolicy, 6, -1)
        local adjacent, numeric, alpha, symbols, nonascii = bin.unpack("%B%B%B%B%B", extPinPolicy)
        self.max_repeat_same_char = (bin.flags(adjacent) * bin.flags(240)).asnumber / 16 -- hi nibble
        self.max_same_char = (bin.flags(adjacent) * bin.flags(15)).asnumber -- low nibble
        self.enable_numeric = numeric
        self.enable_alpha = alpha
        self.enable_symbols = symbols
        self.enable_nonascii = nonascii
        log.output(string.format(
            "init_pin_policy() extended: max_repeat_same_char=%d, max_same_char=%d, enable_numeric=0x%02X, enable_alpha=0x%02X, enable_symbols=0x%02X, enable_nonascii=0x%02X", 
            self.max_repeat_same_char, self.max_same_char, self.enable_numeric, self.enable_alpha, self.enable_symbols, self.enable_nonascii)
        )
    end
    self.pinUnchangable = complexityLevel_f[bin.flags(128)]
    self.pinNotUnlockable = complexityLevel_f[bin.flags(64)]
    self.pinHistory = pinHistory
    self.pin_policy_value = pin_policy
    -- self.pinRetry = pinRetry
    -- if self.pinRetry == 0 then
        -- self.pinRetry = 3
    -- end 

end


function t.mt:check_pin_policy_bit4id(newPin, isPuk)
    log.output('check_pin_policy_bit4id()', newPin, isPuk)
    local curPinLen = string.len(newPin or "")
    
    if curPinLen > self.info.ulMaxPinLen then
        log.output('check_pin_policy_bit4id(): newPin too long')
        return CKR.PIN_LEN_RANGE
    end
    if curPinLen < self.info.ulMinPinLen then
        log.output('check_pin_policy_bit4id(): newPin too short')
        return CKR.PIN_LEN_RANGE
    end

    if isPuk then
        log.output('check_pin_policy_bit4id(): PUK: OK: no more checks')
        return CKR.OK
    end
    if self.complexityLevel then
        if self.complexityLevel == 4 then
            if not utility.check_ext_policy(newPin, 
                self.max_same_char, 
                self.max_repeat_same_char,
                self.enable_numeric,
                self.enable_alpha,
                self.enable_symbols,
                self.enable_nonascii) then
                log.output('check_pin_policy_bit4id(): newPin extended policy do not match!')
                return CKR.PIN_INVALID
            end
        elseif self.complexityLevel == 3 then
            -- upper & lower & numeric & symbols
            local level = 0
            if string.find(newPin, "[%d]") then level = level +1 end
            if string.find(newPin, "[%u]") then level = level +1 end
            if string.find(newPin, "[%l]") then level = level +1 end
            if string.find(newPin, "[%p]") then level = level +1 end
            if level < 3 then
                log.output('check_pin_policy_bit4id(): newPin must contain at least 3 of: upper , lower , numeric , symbols');
                return CKR.PIN_INVALID
            end
        elseif self.complexityLevel == 2 then
            if not string.find(newPin, "[%d]") or not string.find(newPin, "[%a]") then
                log.output('check_pin_policy_bit4id(): newPin must contain alpha + numeric');
                return CKR.PIN_INVALID
            end
        elseif self.complexityLevel == 1 then
            -- at least alpha + numeric
            if string.find(newPin, "[^%d]") then
                log.output('check_pin_policy_bit4id(): newPin must contain only digits');
                return CKR.PIN_INVALID
            end           
        else
            -- any value is ok
        end
    end
    
    local historyList = self:manage_pin_history()
    
    if historyList and table.getn(historyList) > 0 then
        local hNewPin = self:hash_pin(newPin)
        log.output('check_pin_policy_bit4id(): pin history: looking for hNewPin:', hex.hexify(hNewPin));        
        for i=1,table.getn(historyList) do
            log.output('check_pin_policy_bit4id(): history entry:', i, hex.hexify(historyList[i]));
            if historyList[i] == hNewPin then
                log.output('check_pin_policy_bit4id(): pin value found in history');
                return CKR.PIN_INVALID
            end
        end
    end
    return CKR.OK
end

function t.mt:manage_pin_history(newHistoryList)
    log.output('manage_pin_history():', repr(newHistoryList))
    local valueHistoryFid
    local historyLen
    local historyValue
    local historyList
    local newHistory
    if self.pinHistory and self.pinHistory >0 then
        valueHistoryFid = self.files.PIN_POLICY_HISTORY
        historyLen = self.pinHistory
    end
    
    if valueHistoryFid then
        if newHistoryList then
            newHistory = table.concat(newHistoryList, "")
            newHistory = newHistory .. string.rep("\0", (historyLen * PIN_POLICY_HISTORY_HASH_LEN) - string.len(newHistory))
            newHistory = string.sub(newHistory, 1, historyLen * PIN_POLICY_HISTORY_HASH_LEN)
            log.output('manage_pin_history(): newHistory:',  hex.hexify(newHistory))
        end
        -- read/update value history
        local pcRes, theErrorT = pcall(function()
            log.output('manage_pin_history(): selecting file')
            self.nxp_hcard:select_MF()
            self.nxp_hcard:select_Generic()
            local fInfo = self.nxp_hcard:select(valueHistoryFid, true)
            if newHistory then
                newHistory = string.sub(newHistory, 1, math.min(fInfo.size, string.len(newHistory)))
                log.output('manage_pin_history(): updating actual newHistory:',  hex.hexify(newHistory))
                self.nxp_hcard:mupdate_binary(0, newHistory)
                log.output('manage_pin_history(): update done')
                historyValue = newHistory
            else
                log.output('manage_pin_history(): reading history')
                historyValue = self.nxp_hcard:mread_binary(0, math.min(fInfo.size, historyLen * PIN_POLICY_HISTORY_HASH_LEN))
            end
        end)
        if not pcRes then
            log.output('manage_pin_history() error:', theErrorT)
        end
        if pcRes and historyValue then
            historyList = {}
            for i=1,string.len(historyValue),PIN_POLICY_HISTORY_HASH_LEN do
                table.insert(historyList, string.sub(historyValue, i, i-1+PIN_POLICY_HISTORY_HASH_LEN))
            end
        end
    end
    log.output('manage_pin_history(): historyList:', repr(historyList))
    return historyList
end

local function table_insert_unique(t, value)
    for i=1,table.getn(t) do
        if t[i] == value then
            return
        end
    end
    table.insert(t, 1, value)
end

function t.mt:hash_pin(pin)
    local info = self:get_info()
    local hpin = md.pkcs5_pbkdf2(pin, info.serialNumber, PIN_POLICY_HISTORY_HASH_LEN, 1000)
    return hpin
end

function t.mt:update_pin_history(oldPin, newPin)
    log.output('update_pin_history(oldPin, newPin): ', oldPin, newPin);
    local historyList = self:manage_pin_history()
    if historyList then
        local hnewPin = self:hash_pin(newPin)
        local holdPin = self:hash_pin(oldPin)
        
        table_insert_unique(historyList, holdPin)
        table_insert_unique(historyList, hnewPin)
        self:manage_pin_history(historyList)
    end
end


function t.mt:create_object_pin_policy(pTemplate)

    if self.userType ~= CKU.SO then
        log.output('create_object_pin_policy(): user type not SO')
        return CKR.USER_TYPE_INVALID
    end
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local fid_main = self.files.PIN_POLICY
    local fid_pin = self.files.PIN_POLICY_HISTORY
    local all_fids = {fid_main, fid_pin}
    
    log.output('create_object_pin_policy(): erasing PIN policy')
    for i=1,table.getn(all_fids) do
        pcall(function()
            self.nxp_hcard:select_MF()
            self.nxp_hcard:select_Generic()
            self.nxp_hcard:delete_file(all_fids[i])
        end)
    end
    
    if not pTemplate[CKA.VALUE] or string.sub(pTemplate[CKA.VALUE], 1, 5) == string.rep("\0", 5) then
        self.attributes[1] = nil
        return CKR.OK, 0
    end
    
    local attr = string.sub(pTemplate[CKA.VALUE], 1, 10)
    attr = attr .. string.rep("\0", 10- string.len(attr))
    local pinRetryMax = 0
    if type(self.pinRetryMax) == "number" then
        -- overrides pinRetry field (index 5) with self.pinRetryMax
        pinRetryMax = self.pinRetryMax
    end
    attr = string.sub(attr, 1, 4) .. string.char(self.pinRetryMax) .. string.sub(attr, 6, -1)
    
    log.output('create_object_pin_policy(): setting new pin policy:', hex.hexify(attr) )
    
    self.nxp_hcard:select_MF()
    self.nxp_hcard:select_Generic()
    
    self.nxp_hcard:create_binary_file(fid_main, 
        string.len(attr),
        NXPChipDocLite.AC_ALWAYS,
        NXPChipDocLite.AC_ALWAYS,
        NXPChipDocLite.AC_ALWAYS
    )

    self.nxp_hcard:mupdate_binary(0, attr)
    
    self:init_pin_policy(attr)
    
    if self.pinHistory and self.pinHistory > 0 then
        local SE_ID = (self.nxp_hcard.ID_SE_MAIN + NXPChipDocLite.ID_SBC_PIN)
        self.nxp_hcard:create_binary_file(fid_pin, 
            PIN_POLICY_HISTORY_HASH_LEN * self.pinHistory,
            SE_ID,
            SE_ID,
            NXPChipDocLite.AC_ALWAYS
        )
    else
        pcall(function()
            self.nxp_hcard:select_MF()
            self.nxp_hcard:select_Generic()
            self.nxp_hcard:delete_file(fid_pin)
        end)
    end
    obj = {[CKA.CLASS]=eCK.ULONG(CKO_PIN_POLICY), [CKA.TOKEN]=eCK.BBOOL(true), [CKA.VALUE]=self.pin_policy_value}
    self.attributes[1] = obj
    return CKR.OK, 1
end



function t.mt:create_object_fingerprint(pTemplate)

    if self.userType ~= CKU.SO then
        log.output('create_object_fingerprint(): user type not SO')
        return CKR.USER_TYPE_INVALID
    end
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    if not self._indexes._fingerprints_bin or not self.maxFingerprints then
        log.output('create_object_fingerprint(): no fingerprint support!')
        return CKR.FUNCTION_NOT_SUPPORTED
    end

    local bdt_1 = pTemplate[CKA.VALUE]
    if bdt_1 and string.sub(bdt_1, 1, 8) == "MINUTIA:" then
        bdt_1 = hex.hexf(string.sub(bdt_1, 9, -1))
        
    end
    if not bdt_1 or string.sub(bdt_1, 1, 2) ~= hex.hexf("7F2E") then
        log.output('create_object_fingerprint(): invalid VALUE')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end

    if not pTemplate[CKA.ID] or string.len(pTemplate[CKA.ID]) ~= 1 then
        log.output('create_object_fingerprint(): invalid ID')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    local finger_id =  string.byte(pTemplate[CKA.ID])
    
    if finger_id >= self.maxFingerprints then
        log.output('create_object_fingerprint(): invalid ID value:', finger_id, ", maxFingerprints:", self.maxFingerprints)
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    self:invalidate_xproc_cache()
    
    self.nxp_hcard:select_MF()
    self.nxp_hcard:select_Generic()
    
    local d = t._parse_fingerprint_objects(self._indexes._fingerprints_bin)
    
    local search_state = {}
    local search_template = {
        [CKA.CLASS]=pTemplate[CKA.CLASS], 
        [CKA.ID]=pTemplate[CKA.ID], 
    }
    -- print("search_template:", repr(search_template))
    local hObj = self:get_item(search_state, true, search_template)
    local obj
    local add_object = false
    
    log.output('create_object_fingerprint(): found existing hObj:', hObj)
    
    if hObj then
        obj = self.attributes[hObj]
    end
    
    
    if obj then
        -- overwrite existing finger
        log.output('create_object_fingerprint(): overwrite existing finger:', obj.num)
    else
        -- create new finger
        local new_index = table.getn(d)+1
        obj = GetFingerprintObjectTemplate()
        obj.private = false
        obj.num = new_index
        add_object = true
        
        log.output('create_object_fingerprint(): create new finger:', obj.num)
        
    end        
    
    obj[CKA.LABEL] = pTemplate[CKA.LABEL] or ""
    obj[CKA.ID] = pTemplate[CKA.ID]
    
    
    
    log.output('create_object_fingerprint(): calling import_fingerprint():', finger_id, ", maxFingerprints:", self.maxFingerprints)

    local pcRes, theErrorT = pcall(function()
        self.nxp_hcard:import_fingerprint(finger_id, bdt_1)
    end)
    
    if not pcRes then
        log.output("token-nxp-chipdoc-lite:add_info(): error reading tokenInfo:",
            debug.traceback(theErrorT))
        return CKR.FUNCTION_FAILED
    end   
   

    d[obj.num] = {label=obj[CKA.LABEL], id=obj[CKA.ID]}
    
    local new_fingerprints_bin = t._build_fingerprint_objects(d)
    new_fingerprints_bin = new_fingerprints_bin .. string.rep("\0", string.len(self._indexes._fingerprints_bin)- string.len(new_fingerprints_bin))
    
    self:_write_file(new_fingerprints_bin, self.files.FPOD)
    
    self._indexes._fingerprints_bin = new_fingerprints_bin
    
    if add_object then
        self.attributes.max_index = self.attributes.max_index +1
        self.attributes[ self.attributes.max_index] = obj
        log.output(
            string.format("create_object_fingerprint(): created fingerprint object: num:%d handle:%d", 
                obj.num, self.attributes.max_index)
            )
        hObj = self.attributes.max_index
    end
    
    
    return CKR.OK, hObj
end

function t.mt:add_info()
    log.output("token-nxp-chipdoc-lite:add_info()")
    local CSN = string.upper(self.nxp_hcard:read_serial_number())
    local license
    local s = md.sha256()
    s:update(CSN)
    self._mk = s:final()
    
    log.output("token-nxp-chipdoc-lite:add_info(): mk:", hex.hexify(self._mk))
    
    self.info.serialNumber = string.rep("0", 16 - string.len(CSN)) .. CSN
    self.info.label = "SecID " .. self.info.serialNumber
    

    self:check_clear_cache(false)

    local pcRes, theErrorT = pcall(function()
        self.nxp_hcard:select_SSCD()
    end)
    
    if not pcRes and self.nxp_hcard.last_sw == hex.hexf("6283") then
        log.output("token-nxp-chipdoc-lite:add_info(): SSCD ADS in not active, clearing CKF.USER_PIN_INITIALIZED!")
        self._sscd_inactive = true
        self.info.flags = self.info.flags - CKF.USER_PIN_INITIALIZED
    end
    self.nxp_hcard:select_Generic()


    local pcRes, theErrorT = pcall(function()
        local cia_info = self.cia_info
        
        if not cia_info then
            local cia_infoD = self:read_cached_file(self.files.tokenInfo, 0, -1, true)
            cia_info = p15.parse_tokenInfo(cia_infoD)
        end 
        if cia_info.serialNumber and string.len(cia_info.serialNumber ) >= 16 and 
            not string.find(cia_info.serialNumber, "[^%x%u ]")
            then
            local doswitch = true
            if self.cfg["showosn"] then
                local showosn = self.cfg["showosn"]
                for i=1,string.len(showosn) do
                    if string.find(cia_info.serialNumber, string.sub(showosn, i, i), 1, true) then
                        log.output ("token-nxp-chipdoc-lite:add_info(): showosn: special case, using original/HW SN")
                        doswitch = false
                    end
                end
            end
            
            if doswitch then
                -- serialNumber = string.rep("0", 16 - string.len(serialNumber)) .. serialNumber
                local serialNumber = string.sub(cia_info.serialNumber, 1, 16)
                log.output ("token-nxp-chipdoc-lite:add_info(): switch serialNumber to :", serialNumber)
                self.info.serialNumber = serialNumber
                self.info.label = "SecID " .. self.info.serialNumber
                
                log.output ("token-nxp-chipdoc-lite:add_info(): re-check clear cache...")
                self:check_clear_cache(false, true) -- use_cached_cia_info=true
                
                -- log.output ("token-nxp-chipdoc-lite:add_info(): retry read card cache dict...")
                -- self:read_card_cache_dict()
            end
        end
        
        if cia_info.label then
            self.info.label = cia_info.label
            log.output ("token-nxp-chipdoc-lite:add_info(): label set to:", cia_info.label)
        end
        
        if type(cia_info.manufacturerID) == "string" then
            if string.sub(cia_info.manufacturerID, 1, 5) == "json:" then
                local j = json.decode(string.sub(cia_info.manufacturerID, 6, -1))
                if j.manu then
                    self.info.manufacturerID = j.manu
                    log.output ("token-nxp-chipdoc-lite:add_info(): json: manufacturerID set to:", j.manu)
                end
                if j.model then
                    self.info.model = j.model
                    log.output ("token-nxp-chipdoc-lite:add_info(): json: model set to:", j.m)
                end
            else
                self.info.manufacturerID = cia_info.manufacturerID
                log.output ("token-nxp-chipdoc-lite:add_info(): manufacturerID set to:", cia_info.manufacturerID)
            end
        end
        
    end)
    if not pcRes then
        log.output("token-nxp-chipdoc-lite:add_info(): error reading tokenInfo:", debug.traceback(theErrorT))
    end
    
    local pcRes, theErrorT = pcall(function()
        -- read license container file, cache read failure
        local licenseD = self:read_cached_file(self.files.LICENSE, 0, -1, true, true)
        if type(licenseD) == "string" and string.len(licenseD) > 0 then
            local valid
            local license_len = bin.unpack('%H', string.sub(licenseD, 1, 2))
            licenseD = string.sub(licenseD, 3, license_len+2)
            valid, license = licensing.validate(licenseD, self.info.serialNumber)
            if license and license.label then
                log.output("add_info(): license label override:", license.label)
                self.info.label = license.label
            end
            if license and license.serial then
                log.output("add_info(): license serialNumber override:", license.serial)
                if self.info.serialNumber ~= license.serial then
                    log.output ("token-nxp-chipdoc-lite:add_info(): serialNumber override, re-check clear cache...")
                    self:check_clear_cache(false, true) -- use_cached_cia_info=true
                    self.info.serialNumber = license.serial
                end
            end
            if license and license.model then
                log.output("add_info(): license model override:", license.model)
                self.info.model = license.model
            end
            if license and license.manufacturerID then
                log.output("add_info(): license manufacturerID override:", license.manufacturerID)
                self.info.manufacturerID = license.manufacturerID
            end
        end
    end)
    if not pcRes then
        log.output("token-nxp-chipdoc-lite:add_info(): error reading LICENSE:", debug.traceback(theErrorT))
    end
    
    self:read_card_cache_dict()

    self._supports_3072 = true
    self._supports_4096 = true
    -- local pcRes, theErrorT = pcall(function()
        -- log.output("token-nxp-chipdoc-lite:add_info(): reading RSA key sizes...")
        -- local recv, err = self:send_cached_apdu(hex.hexf("80cb008800"), true)
        -- ans: 3F 80 C7 F8
        -- if recv then
            -- local rsaMaxKSyze = self.mechanisms[CKM.RSA_PKCS_KEY_PAIR_GEN].ulMaxKeySize
            -- log.output("token-nxp-chipdoc-lite:add_info(): current RSA rsaMaxKSyze:", rsaMaxKSyze)
            -- local algos3 = bin.flags(string.byte(recv, 3))
            -- if algos3[bin.flags("0x80")] then
                -- self._supports_4096 = true
                -- log.output("token-nxp-chipdoc-lite:add_info(): 4096 is supported")
                -- rsaMaxKSyze = math.max(rsaMaxKSyze, 4096)
            -- end
            -- if algos3[bin.flags("0x40")] then
                -- self._supports_3072 = true
                -- log.output("token-nxp-chipdoc-lite:add_info(): 3072 is supported")
                -- rsaMaxKSyze = math.max(rsaMaxKSyze, 3072)
            -- end
            
            -- for i, v in self.mechanisms do
                -- if type(v) == "table" and type(v.ulMaxKeySize) == "number" and v.ulMaxKeySize > 1024 then
                    -- log.output("token-nxp-chipdoc-lite:add_info(): updating mechanism key size: ", i, rsaMaxKSyze)
                    -- v.ulMaxKeySize = rsaMaxKSyze
                -- end
            -- end
        -- end
    -- end)
    -- if not pcRes then
        -- log.output("token-nxp-chipdoc-lite:add_info(): error reading RSA key sizes:", debug.traceback(theErrorT))
    -- end
    
    local AOD = self:read_cached_file(self.files.AODF, 0, -1, true)
    
    log.output ("token-nxp-chipdoc-lite:add_info(): p15.parseAuthObjects()...")
    local AODInfo = p15.parseAuthObjects(AOD)
    for i, v in AODInfo do
        -- log.output ("token-nxp-chipdoc-lite:add_info(): dumping Auth Obj:", i)
        -- for x, y in v do
            -- log.output("token-nxp-chipdoc-lite:add_info():\t", x, utility.repr(y))
        -- end
        
        if v and v.classAttributes and v.classAttributes.authId == self.authID_Card_PIN then
            log.output("token-nxp-chipdoc-lite:add_info(): found main PIN entry:", self.authID_Card_PIN)
            
            self.info.ulMinPinLen = (v.typeAttributes and v.typeAttributes.minLength) or self.info.ulMinPinLen
            self.info.pinMinLen = self.info.ulMinPinLen -- records physical absolute min len
            log.output("token-nxp-chipdoc-lite:add_info(): ulMinPinLen set to:", self.info.ulMinPinLen)
            
            self.info.ulMaxPinLen = (v.typeAttributes and (v.typeAttributes.maxLength  or v.typeAttributes.storedLength)) or self.info.ulMaxPinLen
            self.info.pinMaxLen = self.info.ulMaxPinLen -- records physical absolute max len
            log.output("token-nxp-chipdoc-lite:add_info(): ulMaxPinLen set to:", self.info.ulMaxPinLen)
            
            
            self.pinRetryMax = v.commonObjectAttributes and v.commonObjectAttributes.flags and bin.unpack("%>%H", v.commonObjectAttributes.flags) or 3
            log.output("token-nxp-chipdoc-lite:add_info(): pinRetryMax set to:", self.pinRetryMax)
            if type(v.typeAttributes.storedLength) == "number" and v.typeAttributes.storedLength > 0 then
                self.nxp_hcard.PIN_PADDING = v.typeAttributes.storedLength
                log.output("token-nxp-chipdoc-lite:add_info(): PIN_PADDING set to:", self.nxp_hcard.PIN_PADDING)
            end
            
            if type(v.typeAttributes.padChar) == "string" and string.len(v.typeAttributes.padChar) == 1 then
                self.nxp_hcard.PADDING_CHAR = v.typeAttributes.padChar
                log.output("token-nxp-chipdoc-lite:add_info(): PADDING_CHAR set to:", hex.hexify(self.nxp_hcard.PADDING_CHAR))
            end
            
        elseif v and v.classAttributes and v.classAttributes.authId == self.authID_Card_PUK then
            log.output("token-nxp-chipdoc-lite:add_info(): found main PUK entry:", self.authID_Card_PUK)
            self.pukRetryMax = v.commonObjectAttributes and v.commonObjectAttributes.flags and bin.unpack("%>%H", v.commonObjectAttributes.flags) or 3
            log.output("token-nxp-chipdoc-lite:add_info(): pukRetryMax set to:", self.pukRetryMax)
            
            if type(v.typeAttributes.storedLength) == "number" and v.typeAttributes.storedLength > 0 then
                self.nxp_hcard.PUK_PADDING = v.typeAttributes.storedLength
                log.output("token-nxp-chipdoc-lite:add_info(): PUK_PADDING set to:", self.nxp_hcard.PUK_PADDING)
            end
            
        elseif v and v.classAttributes and v.classAttributes.authId == self.authID_Card_FINGERPRINT then
            
            self.hasFingerprint = true
           
            self._fp_hardware = fp_reader_query()
            log.output('nxp-chipdoc-lite token add_info(): _fp_hardware=', self._fp_hardware)
    
            log.output("token-nxp-chipdoc-lite:add_info(): found FINGERPRINT entry:", self.authID_Card_FINGERPRINT)
            self.fingerprintRetryMax = v.commonObjectAttributes and v.commonObjectAttributes.flags and bin.unpack("%>%H", v.commonObjectAttributes.flags) or 3
            log.output("token-nxp-chipdoc-lite:add_info(): fingerprintRetryMax set to:", self.fpRetryMax)
            self.info.fingerprintRetryMax = self.fingerprintRetryMax
            if type(v.typeAttributes.storedLength) == "number" and v.typeAttributes.storedLength > 0 then
                self.maxFingerprints = v.typeAttributes.storedLength
                log.output("token-nxp-chipdoc-lite:add_info(): maxFingerprints set to:", self.maxFingerprints)
                self.info.maxFingerprints = self.maxFingerprints
                if self._fp_hardware then
                    self.info.has_fp_hardware = self._fp_hardware
                end
            end
        end
    end
    
    
    -- local CiaPINsComplexityD = self:read_cached_file(self.files.CiaPINsComplexity, 0, -1, true)
    -- self.CiaPINsComplexityStruct = t.parse_CiaPINsComplexityStruct(CiaPINsComplexityD)
    
    self:update_free_mem(self.info)
    
    -- if self.CiaPINsComplexityStruct and self.CiaPINsComplexityStruct.userPinInfo then
    
        -- if self.CiaPINsComplexityStruct.userPinInfo.mustChange and self.CiaPINsComplexityStruct.userPinInfo.mustChange > 0 then
            -- self.info.flags = self.info.flags - CKF.USER_PIN_INITIALIZED
        -- end
        -- local complexity = self.CiaPINsComplexityStruct.userPinInfo.complexity
        -- self.pinComplexity = complexity
        -- if complexity then
            -- if complexity.maxChars and complexity.maxChars >= 4 then
                -- self.info.ulMaxPinLen = complexity.maxChars
                -- log.output("token-nxp-chipdoc-lite:add_info(): info.ulMaxPinLen=userPinInfo.complexity.maxChars:", complexity.maxChars)
            -- end
            -- if complexity.minChars and complexity.minChars >= 4 then
                -- self.info.ulMinPinLen = complexity.minChars
                -- log.output("token-nxp-chipdoc-lite:add_info(): info.ulMinPinLen=userPinInfo.complexity.minChars:", complexity.minChars)
            -- end
        -- end
        
        -- self.max_pin_tries = self.CiaPINsComplexityStruct.userPinInfo.maxAttempts or 10
        -- log.output("token-nxp-chipdoc-lite:add_info(): max_pin_tries:", self.max_pin_tries)
        
    -- end
    
    -- if self.CiaPINsComplexityStruct and self.CiaPINsComplexityStruct.adminInfo then
        -- local complexity = self.CiaPINsComplexityStruct.adminInfo.complexity
        -- self.pukComplexity = complexity
        -- self.max_puk_tries = self.CiaPINsComplexityStruct.adminInfo.maxAttempts or 3
        -- log.output("token-nxp-chipdoc-lite:add_info(): max_puk_tries:", self.max_puk_tries)
    -- end
    
    -- if self.CiaPINsComplexityStruct and self.CiaPINsComplexityStruct.dsInfo then
        
        -- if self.CiaPINsComplexityStruct.dsInfo.dsPukInfo 
            -- and self.CiaPINsComplexityStruct.dsInfo.dsPukInfo.complexity then
            
            -- self.dsPukComplexity = self.CiaPINsComplexityStruct.dsInfo.dsPukInfo.complexity
        -- end

        -- if self.CiaPINsComplexityStruct.dsInfo.dsPinInfo 
            -- and self.CiaPINsComplexityStruct.dsInfo.dsPinInfo.complexity then
            
            -- self.dsPinComplexity = self.CiaPINsComplexityStruct.dsInfo.dsPinInfo.complexity
        -- end

    -- end
    
    self:_update_retry_counters()
    
    if self._pinpad_hw_reader then
        log.output('token-nxp-chipdoc-lite:add_info(): checking card supports pinpad...')
        self._pinpad_hw_card = true
        self._pinpad_hw = self._pinpad_hw_card
        log.output('token-nxp-chipdoc-lite:add_info(): card supports pinpad:', self._pinpad_hw_card)
    end
    
    if self.cfg["mobile"] ~= "true" then
        -- include mobile-optional files here
    end
    
    local pcRes, theErrorT = pcall(function()
        log.output('token-nxp-chipdoc-lite:add_info(): reading bit4id Pin policy file...')
        local pin_policy_value = self:read_cached_file(self.files.PIN_POLICY, 0, -1, true, true) -- update cache on fail
        if pin_policy_value and string.len(pin_policy_value) >0 then
            self:init_pin_policy(pin_policy_value)
        end
    end)
    if not pcRes then
        log.output('token-nxp-chipdoc-lite:add_info(): reading bit4id Pin policy file error:', theErrorT )
        
    end
    
    if self.is_cns then
        local is_cns = utility.cache_read(self.info.serialNumber, "is_cns", self._AvoidUseLastUpdate, self._umcachepath)
        if type(is_cns) == "string" and string.len(is_cns) > 0 then
            log.output('token-nxp-chipdoc-lite:add_info(): is_cns: cached CNS applet!')
            self.cns_hcard = CnsSmartcard.new(self.hcard)
        else
            log.output('token-nxp-chipdoc-lite:add_info(): is_cns: try select CNS applet...')
            local pcRes = pcall(function()
                self.nxp_hcard:select_applet_cns()
                self.cns_hcard = CnsSmartcard.new(self.hcard)
                utility.cache_write(self.info.serialNumber, "is_cns", "\1", self._umcachepath)
            end)
            self.nxp_hcard:select_applet()
            if pcRes then
                log.output('token-nxp-chipdoc-lite:add_info(): is_cns: select CNS applet: OK')
                if not license and not license.model then -- only if not already overridden by license
                    self.info.model = self.info.model .. " CNS"
                end
            else
                log.output('token-nxp-chipdoc-lite:add_info(): is_cns: select CNS applet: FAILED')
                self.is_cns = false
            end
        end
    end
end

function t.mt:check_pin_policy(newPin, isPuk)
    log.output('token-nxp-chipdoc-lite:check_pin_policy()', newPin, isPuk)
    
    if self.complexityLevel then
        log.output('token-nxp-chipdoc-lite:check_pin_policy(): bit4id pinpolicy enabled')
        return self:check_pin_policy_bit4id(newPin, isPuk)
    end
    
    local curPinLen = string.len(newPin or "")
    local complexity = isPuk and self.pukComplexity or self.pinComplexity
    
    if not complexity or not complexity.maxChars or not complexity.minChars then
        if curPinLen > self.info.ulMaxPinLen then
            log.output('token-nxp-chipdoc-lite:check_pin_policy(): ulMaxPinLen: newPin too long', curPinLen, self.info.ulMaxPinLen)
            return CKR.PIN_LEN_RANGE
        end
        if curPinLen < self.info.ulMinPinLen then
            log.output('token-nxp-chipdoc-lite:check_pin_policy(): ulMinPinLen: newPin too short', curPinLen, self.info.ulMinPinLen)
            return CKR.PIN_LEN_RANGE
        end
    end
    

    if complexity then
        
        log.output('token-nxp-chipdoc-lite:check_pin_policy(): selected complexity:', util.repr(complexity))
        
        if curPinLen > complexity.maxChars then
            log.output('token-nxp-chipdoc-lite:check_pin_policy(): maxChars: newPin too short', curPinLen, complexity.maxChars)
            return CKR.PIN_LEN_RANGE
        end
        
        if curPinLen < complexity.minChars then
            log.output('token-nxp-chipdoc-lite:check_pin_policy(): minChars: newPin too long', curPinLen, complexity.minChars)
            return CKR.PIN_LEN_RANGE
        end
        
        
        -- local bRes = utility.check_ext_policy(newPin, 
            -- 128 + (complexity.maxOccurrence or 0), -- self.max_same_char, 
            -- 128 + (complexity.maxSequence or 0), -- self.max_repeat_same_char,
            -- 128 + (complexity.minNum or 0), -- self.enable_numeric,
            -- 128 + (complexity.minAlphaBetic or 0), -- self.enable_alpha,
            -- 128 + (complexity.minNonAlphaNumeric or 0), -- self.enable_symbols,
            -- 128 -- self.enable_nonascii
            -- )
        
        -- if not bRes then
            -- log.output('token-nxp-chipdoc-lite:check_pin_policy(): newPin extended policy do not match!')
            -- return CKR.PIN_INVALID
        -- end
        
        if complexity.maxOccurrence and complexity.maxOccurrence>0 and not utility.check_max_same_char(newPin, complexity.maxOccurrence) then
            log.output('token-nxp-chipdoc-lite:check_pin_policy(): newPin check_max_same_char policy do not match!')
            return CKR.PIN_INVALID
        end

        
        if complexity.maxSequence and complexity.maxSequence>0 and not utility.check_max_repeat_same_char(newPin, complexity.maxSequence) then
            log.output('token-nxp-chipdoc-lite:check_pin_policy(): newPin check_max_repeat_same_char policy do not match!')
            return CKR.PIN_INVALID
        end
        
        if not util.check_numeric(newPin, 128 + (complexity.minNum or 0)) then
            log.output('token-nxp-chipdoc-lite:check_pin_policy(): newPin check_numeric policy do not match!')
            return CKR.PIN_INVALID
        end
        

        if not util.check_alpha_numeric(newPin, 128 + (complexity.minAlphaNumeric or 0)) then
            log.output('token-nxp-chipdoc-lite:check_pin_policy(): newPin check_alpha_numeric policy do not match!')
            return CKR.PIN_INVALID
        end
        
        if not util.check_symbols(newPin, 128 + (complexity.minNonAlphaNumeric or 0)) then
            log.output('token-nxp-chipdoc-lite:check_pin_policy(): newPin check_symbols policy do not match!')
            return CKR.PIN_INVALID
        end
        
        if not util.check_alpha_lower(newPin, 128 + (complexity.minLower or 0)) then
            log.output('token-nxp-chipdoc-lite:check_pin_policy(): newPin check_alpha_lower policy do not match!')
            return CKR.PIN_INVALID
        end
        
        if not util.check_alpha_upper(newPin, 128 + (complexity.minUpper or 0)) then
            log.output('token-nxp-chipdoc-lite:check_pin_policy(): newPin check_alpha_upper policy do not match!')
            return CKR.PIN_INVALID
        end

        if not util.check_alpha(newPin, 128 + (complexity.minAlphaBetic or 0)) then
            log.output('token-nxp-chipdoc-lite:check_pin_policy(): newPin check_alpha policy do not match!')
            return CKR.PIN_INVALID
        end
        
    end
    
    log.output('token-nxp-chipdoc-lite:check_pin_policy(): OK!')
    return CKR.OK
end

function t.mt:get_info()
    if not self.info then
        log.output("token-nxp-chipdoc-lite:get_info()")
        self.info = {
            label = 'SecID',
            manufacturerID = 'NXP',
            model = 'SecID P71',
            serialNumber = '0000000000000000',
            flags = CKF.RNG + CKF.LOGIN_REQUIRED +
                    CKF.USER_PIN_INITIALIZED + CKF.TOKEN_INITIALIZED,
            ulMaxSessionCount = CK.EFFECTIVELY_INFINITE,
            ulSessionCount = 0,
            ulMaxRwSessionCount = CK.EFFECTIVELY_INFINITE,
            ulRwSessionCount = CK.UNAVAILABLE_INFORMATION,
            ulMaxPinLen = 8,
            ulMinPinLen = 6,
            ulTotalPublicMemory = 256000,
            ulFreePublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulTotalPrivateMemory = 256000,
            ulFreePrivateMemory = CK.UNAVAILABLE_INFORMATION,
            hardwareVersion = { major=3, minor=0},
            firmwareVersion = { major=3, minor=0},
            utcTime = '0000000000000000',
            supportsPinpolicy=true,
            has_pss_qscd=true,
        }
        

        self:add_info()
        if self.cfg["ncdldefaultlabel"] then
            self.info.label = self.cfg["ncdldefaultlabel"]
        end

        if self._pinpad_hw then
            log.output("self._pinpad_hw==true, PROTECTED_AUTHENTICATION_PATH: active!")
            self.info.flags = self.info.flags + CKF.PROTECTED_AUTHENTICATION_PATH
        end
        
        if self._fp_hardware and type(self.maxFingerprints) == "number" and self.maxFingerprints > 0 then
            log.output("self.maxFingerprints, PROTECTED_AUTHENTICATION_PATH: active!")
            self.info.flags = self.info.flags + CKF.PROTECTED_AUTHENTICATION_PATH
        end
        
    end
    
    if self._schedule_update_retry_counters then
        self._schedule_update_retry_counters = false
        self:_update_retry_counters()
    end
    return self.info
end

function t.mt:get_mechanisms()
    local info = self:get_info()
    return self.mechanisms
end

function t.mt:verify_pin(pin, userType, contextual_obj)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk = false
    local result
    if userType == CKU.SO then 
        ispuk = true
    end
    log.output("token-nxp-chipdoc-lite:verify_pin()", pin, userType, ispuk, contextual_obj)
    
    self.nxp_hcard:auto_perform_mutual_authenticate(true) -- checkOnActiveSMOnly=true
    
    self:check_clear_cache(true)
    
    self.nxp_hcard:select_MF()
    local info = self:get_info()
    
    if self._sscd_inactive and not ispuk then
        log.output("token-nxp-chipdoc-lite:verify_pin(): USER_PIN_NOT_INITIALIZED")
        return CKR.USER_PIN_NOT_INITIALIZED
    end
    
    if info and self:cache_enabled() then
        local card_cache = self.nxp_hcard:get_cachable_dict()
        
        if card_cache then
            local json_cache = json.encode(card_cache)
            log.output("token-nxp-chipdoc-lite:verify_pin(): updating card_cache:", json_cache)
            utility.cache_write(info.serialNumber, t.card_cache, json_cache, self._umcachepath)
        end
    end
    
    
    if self._fp_hardware and not pin and (userType == CKU.USER) then
        local minutia = fp_reader_get_minutia()
        if minutia then
            pin = minutia
        else
            log.output("token-nxp-chipdoc-lite:verify_pin(): FP: CANCEL")
            return CKR.CANCEL
        end
    end
    
    if pin and userType == CKU.USER 
        and string.sub(pin, 1, 8) == "MINUTIA:" then
        if type(self.maxFingerprints) == "number" then
            log.output("token-nxp-chipdoc-lite:verify_pin(): verify MINUTIA")
        
            if self.attributes == nil then
                self.attributes = self:get_objects()
            end
            local bdt = hex.hexf(string.sub(pin, 9, -1))
            result = self.nxp_hcard:verify_fingerprint(bdt)

            if result == 0 then
                self.cached_main_pin = pin
                self.cached_minutia = bdt
                self.userType = userType
                self.cached_ds_pin = nil
                return CKR.OK
            end
            
            if result == 1 then
                return CKR.PIN_INCORRECT
            elseif result == 2 then
                return CKR.PIN_LOCKED
            else
                return CKR.FUNCTION_FAILED
            end
        
        else
            log.output("token-nxp-chipdoc-lite:verify_pin(): NO FINGERPRINTS")
            return CKR.FUNCTION_FAILED
        end
        
    end
    
    if self._pinpad_hw and not pin and (userType == CKU.USER or userType == CKU.SO) then
    
        local pin_id = ispuk and self.nxp_hcard.ID_PUK or self.nxp_hcard.ID_PIN
        local pin_op = ispuk and PINPAD_CTL_PUK or PINPAD_CTL_PIN
        local padding = ispuk and self.nxp_hcard.PUK_PADDING or self.nxp_hcard.PIN_PADDING
        local apdu = hex.hexf("002000%B%P", pin_id, string.rep("\255", padding) )
        
        local cmd = {min_length=4, max_length=padding, stored_length=padding, apdu=apdu}
        
        local wasSMActive = self.nxp_hcard.ActiveSM
        self.nxp_hcard:close_secure_channel()
        result = pcsc.pinpad_ctl_ex(
            PINPAD_CTL_VERIFY + pin_op,
            self.nxp_hcard.card,
            self.reader_name,
            cmd)
        log.output("token-nxp-chipdoc-lite:verify_pin(): pinpad_verify(): result=", result)
        
        if wasSMActive then
            log.output("token-nxp-chipdoc-lite:verify_pin(): pinpad_verify(): reactivaitng SM...")
            self.nxp_hcard:perform_mutual_authenticate()
        end
        if result == 0 then
            self.cached_main_pin = nil
            self.userType = userType
            self.cached_ds_pin = nil
            self:_set_pin_flags_ok(not ispuk, ispuk)
            return CKR.OK
        end
    else
    
        self.nxp_hcard:auto_perform_mutual_authenticate()
    
        result = self.nxp_hcard:verify_pin_main(pin, ispuk) -- pin, ispuk
        log.output("verify_pin_main(): result=", result)
        if result == 0 then
            self.cached_main_pin = pin
            self.userType = userType
            
            -- if self.attributes == nil then
                -- self.attributes = self:get_objects()
            -- end
            self:_set_pin_flags_ok(not ispuk, ispuk)
            
            return CKR.OK
        end
    end
    self._schedule_update_retry_counters = true
    
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
    self.cached_minutia = nil
end

function t.mt:change_pin(oldPin, newPin)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local newPinOrig = newPin
    local oldPinOrig = oldPin
    local ispuk = false
    if self.userType == CKU.SO then ispuk = true end
    local pcRes, result, theErrorT
    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-nxp-chipdoc-lite:change_pin(): oldPin:', oldPin, 'newPin:', newPin)

    -- if newPin and (string.len(newPin) < info.ulMinPinLen or string.len(newPin) > info.ulMaxPinLen) then
        -- log.output('token-nxp-chipdoc-lite:change_pin(): value not in range:', info.ulMinPinLen, info.ulMaxPinLen)
        -- return CKR.PIN_LEN_RANGE   
    -- end
    if ispuk and self.puk_not_modifiable then
        log.output('token-nxp-chipdoc-lite:change_pin(): PUK not modifiable!')
        return CKR.PIN_LEN_RANGE
    end
    local rv
    log.output('token-nxp-chipdoc-lite:change_pin(): change pin MAIN...')


    self._schedule_update_retry_counters = true
    local pinpadPUK = "***pinpadPUK"
    
    
    if self._pinpad_hw and (oldPin == nil or oldPin == pinpadPUK or newPin == nil) then  -- custom behavior to change the PUK
        
        local wasSMActive = self.nxp_hcard.ActiveSM
        self.nxp_hcard:close_secure_channel()
        log.output('token-nxp-chipdoc-lite:change_pin(): using PINPAD...')
    
        ispuk = oldPin == pinpadPUK or ispuk
        local pin_id = ispuk and self.nxp_hcard.ID_PUK or self.nxp_hcard.ID_PIN
        local pin_op = ispuk and PINPAD_CTL_PUK or PINPAD_CTL_PIN

        local padding = ispuk and self.nxp_hcard.PUK_PADDING or self.nxp_hcard.PUK_PADDING
        
        local apdu = hex.hexf("002000%B%P", pin_id, string.rep("\255", padding) )
        
        local cmd = {min_length=4, max_length=padding, stored_length=padding, apdu=apdu}

        self.nxp_hcard:select_MF()
        
        if self.userType ~= CKU.SO and oldPin == pinpadPUK then
            log.output("token-nxp-chipdoc-lite:change_pin(): SO USER not logged-in and 'pinpadPUK' specified, force verify PUK using pinpad...")
            oldPin = nil
        end
        result = 0
        if oldPin == nil then
            log.output("token-nxp-chipdoc-lite:change_pin(): FORCE verify PUK using pinpad...")
            result = pcsc.pinpad_ctl_ex(
                PINPAD_CTL_VERIFY + pin_op,
                self.nxp_hcard.card,
                self.reader_name,
                cmd)
            log.output("token-nxp-chipdoc-lite:change_pin(): pinpad_verify(MAIN): result=", result)
            
        elseif pinpadPUK ~= oldPin then
            log.output("token-nxp-chipdoc-lite:change_pin(): verify PUK using passed value:", oldPin)
            pcRes, result = pcall(function() 
                    return self.nxp_hcard:verify_pin_main(oldPin, ispuk, false) -- pin, ispuk, use_sm=false
                end)
            log.output("token-nxp-chipdoc-lite:change_pin(): verify_pin_main(): result=", result)
        end
        
        if result == 0 then
        
            apdu = hex.hexf("002401%B%P", pin_id, string.rep("\255", padding) )
            
            cmd = {flags=pcsc.SC_PIN_CMD_IMPLICIT_CHANGE + pcsc.SC_PIN_CMD_USE_PINPAD +pcsc.SC_PIN_CMD_NEED_PADDING,
                            min_length=4, max_length=padding, stored_length=padding, apdu=apdu, offset_pin1=5, offset_pin2=5,}
                            
            result = pcsc.pinpad_ctl_ex(
                PINPAD_CTL_CHANGE + pin_op,
                self.nxp_hcard.card,
                self.reader_name,
                cmd)
            
            log.output("token-nxp-chipdoc-lite:change_pin(): pinpad_change(MAIN): result=", result)
        end
        
        if wasSMActive then
            log.output("token-nxp-chipdoc-lite:change_pin(): pinpad_change(MAIN): reactivaitng SM...")
            self.nxp_hcard:perform_mutual_authenticate()
        end
    else
    
        if string.sub(newPin, 1, 5) == "****:" then
            log.output('token-nxp-chipdoc-lite:change_pin(): override pin policy check')
            newPin = string.sub(newPin, 6, -1)
        else
            rv = self:check_pin_policy(newPin, ispuk)
            if rv ~= CKR.OK then
                log.output('token-nxp-chipdoc-lite:change_pin(): newPin rejected');
                return rv
            end
        end
        
        result = 0
        if self.is_cns then
            log.output('token-nxp-chipdoc-lite:change_pin(): changing CNS pin...')
            local wasSMActive = self.nxp_hcard.ActiveSM
            self.nxp_hcard:select_applet_cns(false)

            pcRes, result = pcall(function() return self.cns_hcard:change_pin_cns(oldPin, newPin, ispuk) end)
            log.output('token-nxp-chipdoc-lite:change_pin(): change_pin_cns():', result)

            self.nxp_hcard:select_applet(false)
            if wasSMActive then
                self.nxp_hcard:perform_mutual_authenticate()
            end
        end
        
        if result == 0 then
            self.nxp_hcard:select_MF()
            local use_sm = nil
            pcRes, result = pcall(function() return self.nxp_hcard:change_pin_main(oldPin, newPin, ispuk, self._cfg_use_pin_padding, use_sm) end)
            
            if result ~= 0 then
                local pcRes1, result1 = pcall(function() return self.cns_hcard:change_pin_cns(newPin, oldPin) end )
                log.output('token-cns change_pin(): restore CNS pin result:', result1)
            end
        end
    end
    
    if result == 0 then
        self.cached_main_pin = newPin
        -- la carta potrebbe dimenticare lo stato di logged in quando si effettua una change pin
        -- pcRes, result = pcall(function()    
                -- return self.nxp_hcard:verify_pin_main(newPin, ispuk)  -- pin, ispuk
            -- end)
            pcall(function()
                self:update_pin_history(oldPinOrig, newPinOrig)
            end)
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
    log.output('token-nxp-chipdoc-lite:reset_pin(): newPin:', newPin)
    log.output('token-nxp-chipdoc-lite:reset_pin(): reset pin MAIN...')
    if self.userType ~= CKU.SO then
        log.output('token-nxp-chipdoc-lite:reset_pin(): user not SO!')
        return CKR.USER_TYPE_INVALID
    end
    
    local rv

    self._schedule_update_retry_counters = true
    
    -- if newPin and (string.len(newPin) < info.ulMinPinLen or string.len(newPin) > info.ulMaxPinLen) then
        -- log.output('token-nxp-chipdoc-lite:reset_pin(): value not in range:', info.ulMinPinLen, info.ulMaxPinLen)
        -- return CKR.PIN_LEN_RANGE   
    -- end
    
    if self._sscd_inactive then
        log.output('token-nxp-chipdoc-lite:reset_pin(): inactive SSCD ADF, trying to reactivate...')
        self.nxp_hcard:select_MF()
        local recv = self.nxp_hcard:sm_transmit(hex.hexf("00440000%P", self.files.SSCD), self.nxp_hcard.ActiveSM)
        log.output('token-nxp-chipdoc-lite:reset_pin(): reactivation result: ', hex.hexify(recv))
        if recv == hex.hexf("9000") then
            log.output('token-nxp-chipdoc-lite:reset_pin(): reactivation OK, resetting  self._sscd_inactive...')
            self._sscd_inactive = false
            self.info.flags = self.info.flags + CKF.USER_PIN_INITIALIZED
            -- self:update_cache_id()
            self:invalidate_xproc_cache()
        end
    end
    -- TODO: PINPAD
    if self._pinpad_hw and (newPin == nil) then 
        local wasSMActive = self.nxp_hcard.ActiveSM
        local pin_id = self.nxp_hcard.ID_PIN
        local pin_op = PINPAD_CTL_PIN

        local padding = self.nxp_hcard.PIN_PADDING    
    
        res =  self.nxp_hcard:reset_retry_counter(pin_id, true, false) -- bso, backtracking, use_sm=false
    
        apdu = hex.hexf("002401%B%P", pin_id, string.rep("\255", padding) )
        
        cmd = {flags=pcsc.SC_PIN_CMD_IMPLICIT_CHANGE + pcsc.SC_PIN_CMD_USE_PINPAD +pcsc.SC_PIN_CMD_NEED_PADDING,
                        min_length=4, max_length=padding, stored_length=padding, apdu=apdu, offset_pin1=5, offset_pin2=5,}
                        
        self.nxp_hcard:close_secure_channel()
        result = pcsc.pinpad_ctl_ex(
            PINPAD_CTL_RESET + pin_op,
            self.nxp_hcard.card,
            self.reader_name,
            cmd)
        
        log.output("token-nxp-chipdoc-lite:reset_pin(): pinpad_reset(MAIN): result=", result)
        
        if wasSMActive then
            log.output("token-nxp-chipdoc-lite:change_pin(): pinpad_change(MAIN): reactivaitng SM...")
            self.nxp_hcard:perform_mutual_authenticate()
        end
    else

        if string.sub(newPin, 1, 5) == "****:" then
            log.output('token-nxp-chipdoc-lite:reset_pin(): override pin policy check')
            newPin = string.sub(newPin, 6, -1)
        else
            rv = self:check_pin_policy(newPin)
            if rv ~= CKR.OK then
                log.output('token-nxp-chipdoc-lite:reset_pin(): newPin rejected');
                return rv
            end
        end
        
        result = 0
        if self.is_cns then
            log.output('token-nxp-chipdoc-lite:reset_pin(): resetting CNS pin...')
            local wasSMActive = self.nxp_hcard.ActiveSM
            self.nxp_hcard:select_applet_cns(false)

            pcRes, result = pcall(function() return self.cns_hcard:reset_pin_cns(self.cached_main_pin, newPin) end)
            log.output('token-nxp-chipdoc-lite:change_pin(): reset_pin_cns():', result)

            self.nxp_hcard:select_applet(false)
            if wasSMActive then
                self.nxp_hcard:perform_mutual_authenticate()
            end
        end
        
        if result == 0 then
            self.nxp_hcard:select_MF()
            pcRes, result = pcall(function() 
                    local use_sm = nil
                    return self.nxp_hcard:reset_pin_main(self.cached_main_pin, newPin, self._cfg_use_pin_padding, use_sm) -- Puk, newPin, padding, use_sm
                end)
            if not pcRes then
                log.output('token-nxp-chipdoc-lite:reset_pin(): reset_pin_main() error:', debug.traceback(result) )
            end
        end
        
        -- todo: verify is required?
        if pcRes and result == 0 then
            pcRes, result = pcall(function()
                local use_sm = nil -- TODO: SM?
                return self.nxp_hcard:verify_pin_main(newPin, false, use_sm) -- pin, ispuk, use_sm
            end)
            if not pcRes then
                log.output('token-nxp-chipdoc-lite:reset_pin(): verify_pin_main() error:', debug.traceback(result) )
            end
        end
        
    end
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

function t.mt:rsa_auto(pData, keyBytes, kid)
    -- if string.len(pData) == keyBytes then
        -- log.output('token-nxp-chipdoc-lite:rsa_auto(): len of data to RSA is same as key len, trying to unpad...')
        -- local unpadded = rsa.pkcs1_unpad(pData)
        -- if unpadded then
            -- log.output('token-nxp-chipdoc-lite:rsa_auto(): signing unpadded data:', hex.hexify(unpadded))
            -- pData = unpadded
        -- end
        if string.len(pData) == keyBytes then
            log.output('token-nxp-chipdoc-lite:rsa_auto(): len of data to RSA is same as key len, trying RSA RAW...')
        else
            log.output('token-nxp-chipdoc-lite:rsa_auto(): padding with BT01...')
            pData = rsa.pkcs1_bt01_pad(pData, keyBytes)
        end
        return self.nxp_hcard:pso_dec_rsa(pData, kid) -- data, id
        
    -- else
        -- return self.nxp_hcard:pso_internal_auth(
            -- pData,
            -- kid,
            -- backtraking
            -- )
    -- end

end


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
        self.nxp_hcard:end_transaction()
    end
    local res = w32.show_message(msgid)
    self.hcard:status() -- in caso di reset effettua una reconnect
    if transactionDisabled then
        self.hcard:begintransaction()
    else
        self.nxp_hcard:begin_transaction()
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
        self.nxp_hcard:end_transaction()
    end
    local res, contextual_pin, cache_ds_pin = w32.request_pin_ds(self.check_box_visible)
    self.hcard:status() -- in caso di reset effettua una reconnect
    if transactionDisabled then
        self.hcard:begintransaction()
    else
        self.nxp_hcard:begin_transaction()
    end
    self.hcard:disabletransactions(transactionDisabled)
    return res, contextual_pin, cache_ds_pin
end

function t.mt:verify_cached_pin_or_finger()
    log.output('token-nxp-chipdoc-lite:verify_cached_pin_or_finger(): with', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.nxp_hcard:select_MF()
        if string.sub(self.cached_main_pin, 1, 8) == "MINUTIA:" then
            local bdt = hex.hexf(string.sub(self.cached_main_pin, 9, -1))
            
            log.output('verify_cached_pin_or_finger(): verify cached fingerprint...')
            result = self.nxp_hcard:verify_fingerprint(bdt)
            
        else
            log.output('verify_cached_pin_or_finger(): verify cached...')
            result = self.nxp_hcard:verify_pin_main(self.cached_main_pin)

        end
    end
    log.output('token-nxp-chipdoc-lite:verify_cached_pin_or_finger(): result:', result)
    return result
end

function t.mt:try_verify_pin(isdsObject)
    log.output('try_verify_pin(): isdsObject', isdsObject)
    local result, contextual_pin
    
    if not self.nxp_hcard:is_pin_verified() then
    
        local cached_pin_valid = self.cached_main_pin and self.userType == CKU.USER
        local ds_object_can_use_cached_pin = (isdsObject and not (self.cfg["dspinusegui"] == 'true' or self.cfg["dspinusegui"] == 'sign'))
        local try_cached = cached_pin_valid and (not isdsObject or ds_object_can_use_cached_pin)
        
        self.nxp_hcard:select_Generic()
        log.output("try_verify_pin(): CFG:", utility.repr(self.cfg))
        local info = self:get_info()
        if try_cached then
            log.output('try_verify_pin(): re-verifying cached main pin...')
            contextual_pin = self.cached_main_pin

            self.nxp_hcard:auto_perform_mutual_authenticate() -- check/restore Generic SM session
            if string.sub(contextual_pin, 1, 8) == "MINUTIA:" then
                local bdt = hex.hexf(string.sub(contextual_pin, 9, -1))
                
                log.output('try_verify_pin(): verify cached fingerprint...')
                result = self.nxp_hcard:verify_fingerprint(bdt)
                
            else
                log.output('try_verify_pin(): verify cached...')
                result = self.nxp_hcard:verify_pin_main(contextual_pin)

            end

        elseif self._pinpad_hw then
        
            log.output('try_verify_pin(): not cached, using pinpad...')
            local pin_id =  self.nxp_hcard.ID_PIN
            local pin_op = PINPAD_CTL_PIN
            local padding = self.nxp_hcard.PIN_PADDING
            local apdu = hex.hexf("002000%B%P", pin_id+128, string.rep("\255", padding) )
            
            local cmd = {min_length=4, max_length=padding, stored_length=padding, apdu=apdu}
            
            local wasSMActive = self.nxp_hcard.ActiveSM
            self.nxp_hcard:close_secure_channel()
            while true do
                result = pcsc.pinpad_ctl_ex(
                    PINPAD_CTL_VERIFY + pin_op,
                    self.nxp_hcard.card,
                    self.reader_name,
                    cmd)
                if self:gui_show_pin_message(result, false) ~= 1 then
                    break
                end
            end
            if wasSMActive then
                log.output("token-nxp-chipdoc-lite:try_verify_pin(): reactivaitng SM...")
                self.nxp_hcard:perform_mutual_authenticate()
            end
            
        elseif self.request_plugin_valid
           and (self.cfg["dspinusegui"] == 'true' or self.cfg["dspinusegui"] == 'sign')
            then
            
            self.nxp_hcard:auto_perform_mutual_authenticate() -- check/restore Generic SM session
            
            if self.cached_ds_pin then
                contextual_pin = self.cached_ds_pin
                log.output('try_verify_pin(): DS: verify cached...')
                result = self.nxp_hcard:verify_pin_main(contextual_pin)
                if result ~= 0 then
                    log.output('try_verify_pin(): DS: verify cached: failed:', result)
                    return CKR.FUNCTION_FAILED
                end
            else
                local res, cache_ds_pin
                while true do
                    res, contextual_pin, cache_ds_pin = self:gui_request_pin_ds(self.check_box_visible)
                    if res ~= 1 then
                        log.output('try_verify_pin(): cancelled by plugin with code:', res)
                        return CKR.FUNCTION_FAILED
                    end
                    -- reselect generic just in case...
                    self.nxp_hcard:select_Generic()
                    result = self.nxp_hcard:verify_pin_main(contextual_pin)
                    if result == 0 and cache_ds_pin then self.cached_ds_pin = contextual_pin end
                    contextual_pin = nil
                    if self:gui_show_pin_message(result, false) ~= 1 then
                        break
                    end
                end
            end
        else
            log.output('try_verify_pin(): requesting contextual login since ALWAYS_AUTHENTICATE is set...')
            return CKR.USER_NOT_LOGGED_IN
        end
    end
    return CKR.OK
end
function t.mt:sign_buffer(hKey, pMechanism, pData, allocated_space)

    local rv, signature
    log.output(string.format('sign_buffer(): hKey=%x', hKey ) )
    log.output(string.format('sign_buffer(): pData=%s', pData and hex.hexify(pData) or "<null>" ) )
    log.output(string.format('sign_buffer(): allocated_space=%x', allocated_space or -1 ) )
    if pMechanism and pMechanism.mechanism then
        log.output(string.format('sign_buffer(): mechanism=%x', pMechanism.mechanism ) )
        log.output(string.format('sign_buffer(): parameter=%s', pMechanism.parameter and hex.hexify(pMechanism.parameter) or "<null>"))
    end
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('token-nxp-chipdoc-lite:sign_buffer(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    
    if obj.iscns then
        rv, signature = self:sign_buffer_rsa_cns(hKey, pMechanism, pData, allocated_space)
        return rv, signature
    end
    
    if type(allocated_space) == "number" and allocated_space  > 0 then
        rv = self:try_verify_pin(obj.userConsent)
        if rv ~= CKR.OK then
            log.output('token-nxp-chipdoc-lite:sign_buffer(): try_verify_pin() error: ', rv)
            return rv
        end
    end
    
    
    if pMechanism and pMechanism.mechanism == CKM.EDDSA then
        log.output('sign_buffer(): CKM.EDDSA...')
        rv, signature = self:sign_buffer_eddsa(hKey, pMechanism, pData, allocated_space) 
    elseif pMechanism and pMechanism.mechanism == CKM.ECDSA then
        log.output('sign_buffer(): CKM.ECDSA...')
        rv, signature = self:sign_buffer_ecc(hKey, pMechanism, pData, allocated_space)
    else
        log.output('sign_buffer(): RSA...')
        rv, signature = self:sign_buffer_rsa(hKey, pMechanism, pData, allocated_space)
    end
    
    if rv == CKR.OK and type(signature) == "string" and string.len(signature) > 0 then
        log.output("sign_buffer(): try calling token_log_mw_activity()...")
        local pcRes, theErrorT = pcall(function()
            utility.token_log_mw_activity(self, hKey, self.cfg, "sign")
        end)
        if not pcRes then
            log.output("sign_buffer(): token_log_mw_activity():", theErrorT)
        end
    end
    
    if rv == CKR.OK and type(signature) == "string" and obj.userConsent then
        log.output("sign_buffer(): userConsent: unverify pin...")
        self.nxp_hcard:unverify_pin()
    end
    return rv, signature
end


function t.mt:sign_buffer_eddsa(hKey, pMechanism, pData, allocated_space)
    local select_done = false
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('sign_buffer_eddsa(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('sign_buffer_eddsa(): ERROR: non private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    local sigLen = 32 * 2
    local dataLen = string.len(pData)
    local pcRes, result
    
    -- if not self._ecc_license_valid then
        -- log.output('sign_buffer_eddsa(): WARNING: not _ecc_license_valid')
        -- return CKR.KEY_FUNCTION_NOT_PERMITTED
    -- end

    
    if allocated_space==nil then
        return CKR.OK, sigLen
    else
        if type(obj.sk) == "function" then
            obj.sk(self, hKey, CKA.VALUE, false)
        end
        local sk = t._enc_dec_sensitive_data(obj.sk, self.info.serialNumber, false)
        local result = sm.crypto_sign_ed25519_detached(pData, sk)
        sk = nil; collectgarbage()
        return CKR.OK, result
    end
    
    log.output('sign_buffer_eddsa(): unexpected!')
    return CKR.FUNCTION_FAILED

end


function t.mt:sign_buffer_ecc(hKey, pMechanism, pData, allocated_space)
    
    log.output('token-nxp-chipdoc-lite:sign_buffer_ecc():', hKey, pMechanism, hex.hexify(pData or ''), allocated_space)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('token-nxp-chipdoc-lite:sign_buffer_ecc(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('token-nxp-chipdoc-lite:sign_buffer_ecc(): ERROR: non private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    local curve = ecdhlib.get_curve_by_deroid(obj.parameters)
    
    if not curve then
        log.output('token-nxp-chipdoc-lite:sign_buffer_ecc(): unsupported curve type!')
        return CKR.KEY_FUNCTION_NOT_PERMITTED
    end
    
    local keyBytes = curve.keysize * 2
    local pcRes, result
    log.output('sign_buffer_ecc(): using curve: ', curve.name)
    pData = ecdhlib.trunk_to_curve_order(curve, pData)
    
    local pad_to = curve.keysize 
    if pad_to > 64 then
        pad_to = 64 -- max hash size if 512 bit
    end
    
    pData = string.rep("\0", pad_to - string.len(pData)) .. pData
    
    if allocated_space==nil then
        log.output('token-nxp-chipdoc-lite:sign_buffer_ecc(): returning signature length:', keyBytes)
        return CKR.OK, keyBytes
    end
    
    log.output('token-nxp-chipdoc-lite:sign_buffer_ecc(): using ECDSA PSO_CDS mode on kid:', obj.kid)


    self.nxp_hcard:auto_perform_mutual_authenticate(true) -- check/restore Generic SM session, checkOnActiveSMOnly
    
    -- self.nxp_hcard:select_Generic()
    self.nxp_hcard:select_SSCD()
    pcRes, result = pcall(function()
                    return self.nxp_hcard:pso_cds_ecdsa(
                        pData, 
                        obj.kid
                        )
                    end )
    if pcRes then
        return CKR.OK, result
    end
    if not pcRes and self.nxp_hcard.last_sw == hex.hexf("6982") then
        log.output('token-nxp-chipdoc-lite:sign_buffer_ecc(): restoring secure channel and verifying pin...')
        self.nxp_hcard:auto_perform_mutual_authenticate(true)
        self.nxp_hcard:select_MF()
        if self.cached_main_pin then
            self.nxp_hcard:verify_pin_main(self.cached_main_pin, false) -- pin, ispuk
        end
        -- self.nxp_hcard:select_Generic()
        self.nxp_hcard:select_SSCD()

        pcRes, result = pcall(function()
                        return self.nxp_hcard:pso_cds_ecdsa(
                            pData, 
                            obj.kid
                            )
                        end )
        if pcRes then
            log.output('token-nxp-chipdoc-lite:sign_buffer_ecc(): AUTH: OK with kid:', obj.kid)
            return CKR.OK, result
        end
    end
    if not pcRes then
        log.output('token-nxp-chipdoc-lite:sign_buffer_ecc(): error', debug.traceback(result))
        return CKR.FUNCTION_FAILED
    end
    
    log.output('token-nxp-chipdoc-lite:sign_buffer_ecc(): unexpected!')
    return CKR.FUNCTION_FAILED
    
end

function t.mt:sign_buffer_rsa(hKey, pMechanism, pData, allocated_space)
    
    log.output('token-nxp-chipdoc-lite:sign_buffer_rsa():', hKey, pMechanism, hex.hexify(pData or ''), allocated_space)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('token-nxp-chipdoc-lite:sign_buffer_rsa(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('token-nxp-chipdoc-lite:sign_buffer_rsa(): ERROR: non private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    local pcRes, result

    log.output('token-nxp-chipdoc-lite:sign_buffer_rsa(): keyBytes:', keyBytes)
    log.output('token-nxp-chipdoc-lite:sign_buffer_rsa(): dataLen:', dataLen)
    if allocated_space==nil then
        log.output('token-nxp-chipdoc-lite:sign_buffer_rsa(): returning signature length:', keyBytes)
        return CKR.OK, keyBytes
    end
    

    log.output('token-nxp-chipdoc-lite:sign_buffer_rsa(): using RSA INTERNAL AUTH/PSO_DEC RAW mode on kid:', obj.kid)

    if dataLen > keyBytes then
        -- nota: il padding pkcs1 richiede almeno 8 byte di oxFF prima dei dati da firmare
        log.output('token-nxp-chipdoc-lite:sign_buffer_rsa(): specified data len invalid: ', dataLen)
        return CKR.DATA_LEN_RANGE
    end

    self.nxp_hcard:auto_perform_mutual_authenticate(true) -- check/restore Generic SM session, checkOnActiveSMOnly
    
    if keyBytes > 256 and dataLen < keyBytes then
        pData = "\0\1" .. string.rep("\255", keyBytes-3 - dataLen ) .. "\0" .. pData
        log.output('token-nxp-chipdoc-lite:sign_buffer_rsa(): padded pData:', hex.hexify(pData or ''))
    end
    
    local selectGeneric = false
    
    local function try_rsa()
        if selectGeneric then
            log.output('token-nxp-chipdoc-lite:sign_buffer_rsa():try_rsa(): GENERIC AID');
            self.nxp_hcard:select_Generic()
        else
            log.output('token-nxp-chipdoc-lite:sign_buffer_rsa():try_rsa(): SSCD AID');
            self.nxp_hcard:select_SSCD()
        end
        pcRes, result = pcall(function()
                        return self:rsa_auto(
                            pData,
                            keyBytes,
                            obj.kid
                            )
                        end )
    end

    try_rsa()
    if pcRes then
        return CKR.OK, result
    end
    log.output('token-nxp-chipdoc-lite:sign_buffer_rsa(): self.nxp_hcard.last_sw:', hex.hexify(self.nxp_hcard.last_sw))
    
    -- BUG FIX: JCOP4 cards made with old MW do not use SSCD filesystem AID!
    if not pcRes and self.nxp_hcard.last_sw == hex.hexf("6A82") then
        log.output('token-nxp-chipdoc-lite:sign_buffer_rsa(): try select GENERCIC AID...')
        selectGeneric = true
        try_rsa()
        if pcRes then
            log.output('token-nxp-chipdoc-lite:sign_buffer_rsa(): AUTH: OK with kid:', obj.kid)
            return CKR.OK, result
        end
    end
    
    log.output('token-nxp-chipdoc-lite:sign_buffer_rsa(): self.nxp_hcard.last_sw:', hex.hexify(self.nxp_hcard.last_sw))
    if not pcRes and self.nxp_hcard.last_sw == hex.hexf("6982") then
        log.output('token-nxp-chipdoc-lite:sign_buffer_rsa(): restoring secure channel and verifying pin...')
        self.nxp_hcard:auto_perform_mutual_authenticate(true)
        self.nxp_hcard:select_MF()
        if self.cached_main_pin then
            self.nxp_hcard:verify_pin_main(self.cached_main_pin, false) -- pin, ispuk
        end
        try_rsa()
        if pcRes then
            log.output('token-nxp-chipdoc-lite:sign_buffer_rsa(): AUTH: OK with kid:', obj.kid)
            return CKR.OK, result
        end
    end
    if not pcRes then
        log.output('token-nxp-chipdoc-lite:sign_buffer_rsa(): error', debug.traceback(result))
        return CKR.FUNCTION_FAILED
    end
    
    log.output('token-nxp-chipdoc-lite:sign_buffer_rsa(): unexpected!')
    return CKR.FUNCTION_FAILED
end


function t.mt:sign_buffer_rsa_cns(hKey, pMechanism, pData, allocated_space)
    
    log.output('token-nxp-chipdoc-lite:sign_buffer_rsa_cns():', hKey, pMechanism, hex.hexify(pData or ''), allocated_space)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('token-nxp-chipdoc-lite:sign_buffer_rsa_cns(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('token-nxp-chipdoc-lite:sign_buffer_rsa_cns(): ERROR: non private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    local pcRes, result

    log.output('token-nxp-chipdoc-lite:sign_buffer_rsa_cns(): keyBytes:', keyBytes)
    log.output('token-nxp-chipdoc-lite:sign_buffer_rsa_cns(): dataLen:', dataLen)
    if allocated_space==nil then
        log.output('token-nxp-chipdoc-lite:sign_buffer_rsa_cns(): returning signature length:', keyBytes)
        return CKR.OK, keyBytes
    end
    

    log.output('token-nxp-chipdoc-lite:sign_buffer_rsa_cns(): using RSA INTERNAL AUTH/PSO_DEC RAW mode on kid:', obj.kid)

    if dataLen > keyBytes then
        -- nota: il padding pkcs1 richiede almeno 8 byte di oxFF prima dei dati da firmare
        log.output('token-nxp-chipdoc-lite:sign_buffer_rsa_cns(): specified data len invalid: ', dataLen)
        return CKR.DATA_LEN_RANGE
    end


    if dataLen < (keyBytes - 3) then
        pData = "\0\1" .. string.rep("\255", keyBytes-3 - dataLen ) .. "\0" .. pData
        log.output('token-nxp-chipdoc-lite:sign_buffer_rsa_cns(): padded pData:', hex.hexify(pData or ''))
    end

    local wasSMActive = self.nxp_hcard.ActiveSM
    self.nxp_hcard:select_applet_cns(false)
    if self.cached_main_pin then
        self.cns_hcard:verify_pin_cns(self.cached_main_pin)
    end
    
    pcRes, result = pcall(function()
                        return self.cns_hcard:rsa_cns(
                            pData,
                            hex.hexify(obj.path),
                            obj.kid
                            )
                    end )
    log.output('token-nxp-chipdoc-lite:sign_buffer_rsa_cns(): self.nxp_hcard.last_sw:', hex.hexify(self.nxp_hcard.last_sw))
                    
    self.nxp_hcard:select_applet(false)
    if wasSMActive then
        self.nxp_hcard:perform_mutual_authenticate()
    end

    if pcRes then
        return CKR.OK, result
    end
    if not pcRes then
        log.output('token-nxp-chipdoc-lite:sign_buffer_rsa_cns(): error', debug.traceback(result))
        return CKR.FUNCTION_FAILED
    end
    
    log.output('token-nxp-chipdoc-lite:sign_buffer_rsa_cns(): unexpected!')
    return CKR.FUNCTION_FAILED
end


function t.mt:decrypt_buffer(hKey, pMechanism, pData, allocated_space)

    log.output('token-nxp-chipdoc-lite:decrypt_buffer(): ')

    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('token-nxp-chipdoc-lite:decrypt_buffer(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end

    if obj.iscns then
        rv, signature = self:decrypt_buffer_rsa_cns(hKey, pMechanism, pData, allocated_space)
        return rv, signature
    end
    
    if type(allocated_space) == "number" and allocated_space  > 0 then
        local rv = self:try_verify_pin()
        if rv ~= CKR.OK then
            log.output('token-nxp-chipdoc-lite:decrypt_buffer(): try_verify_pin() error: ', rv)
            return rv
        end
    end
    if pMechanism and pMechanism.mechanism == CKM.CURVE25519_CRYPTO_BOX then
        return self:decrypt_buffer_cryptobox(hKey, pMechanism, pData, allocated_space)
    elseif pMechanism and (pMechanism.mechanism == CKM.AES_CBC or pMechanism.mechanism == CKM.AES_CBC_PAD) then
        return self:decrypt_buffer_aes(hKey, pMechanism, pData, allocated_space)
    else
        return self:decrypt_buffer_rsa(hKey, pMechanism, pData, allocated_space)
    end
end


function t.mt:decrypt_buffer_cryptobox(hKey, pMechanism, pData, allocated_space)
    log.output(string.format('decrypt_buffer_cryptobox(): hKey=%x', hKey ) )
    log.output(string.format('decrypt_buffer_cryptobox(): pData=%s', pData and hex.hexify(pData) or "<null>" ) )
    log.output(string.format('decrypt_buffer_cryptobox(): allocated_space=%x', allocated_space or -1 ) )
    if pMechanism and pMechanism.mechanism then
        log.output(string.format('decrypt_buffer_cryptobox(): mechanism=%x', pMechanism.mechanism ) )
        log.output(string.format('decrypt_buffer_cryptobox(): parameter=%s', pMechanism.parameter and hex.hexify(pMechanism.parameter) or "<null>"))
    end
    log.output('decrypt_buffer_cryptobox(): pData=', pData and hex.hexify(pData ) or "<null>")
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('decrypt_buffer_cryptobox(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('decrypt_buffer_cryptobox(): ERROR: not a private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    if obj[CKA.KEY_TYPE] ~= eCK.ULONG(CKK.EC_EDWARDS) then
        log.output('decrypt_buffer_cryptobox(): ERROR: not a EC_EDWARDS key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end

    if not pMechanism or pMechanism.mechanism ~= CKM.CURVE25519_CRYPTO_BOX then
        log.output('decrypt_buffer_cryptobox(): MECHANISM_INVALID:', pMechanism and pMechanism.mechanism )
        return CKR.MECHANISM_INVALID
    end
    if type(obj.kid) == 'function' then
        local rv = obj.kid(self, hKey, CKA.CLASS, false)
        if rv ~= CKR.OK then return rv end
    end
    if type(obj.sk) == 'function' then
        local rv = obj.sk(self, hKey, CKA.CLASS, false)
        if rv ~= CKR.OK then return rv end
    end
    
    local crypto_box_NONCEBYTES  = 24
    --local crypto_box_SECRETKEYBYTES  = 32
    local crypto_box_PUBLICKEYBYTES  = 32
    local nonce
    
    local pk = pMechanism.parameter
    if not pk or string.len(pk) < crypto_box_PUBLICKEYBYTES then
        log.output('decrypt_buffer_cryptobox(): MECHANISM_PARAM_INVALID:', hex.hexify(pMechanism.parameter or ""), "expected len:", crypto_box_PUBLICKEYBYTES )
        return CKR.MECHANISM_PARAM_INVALID
    end
    if string.len(pk) >= (crypto_box_PUBLICKEYBYTES + crypto_box_NONCEBYTES) then
        nonce = string.sub(pk, crypto_box_PUBLICKEYBYTES+1, crypto_box_PUBLICKEYBYTES+crypto_box_NONCEBYTES)
        log.output('decrypt_buffer_cryptobox(): using nonce passed in parameter:', hex.hexify(nonce) )
    else
        nonce = string.sub(pData, 1, crypto_box_NONCEBYTES)
        pData = string.sub(pData, crypto_box_NONCEBYTES + 1, -1)
        log.output('decrypt_buffer_cryptobox(): using nonce prefixed to pData:', hex.hexify(nonce) )
        log.output('decrypt_buffer_cryptobox(): new pData to decrypt:', hex.hexify(pData) )
    end
    
    local vk = sm.crypto_sign_ed25519_pk_to_curve25519(string.sub(pk, 1, crypto_box_PUBLICKEYBYTES))
    local dec_sk = t._enc_dec_sensitive_data(obj.sk, self.info.serialNumber, false)
    local sk = sm.crypto_sign_ed25519_sk_to_curve25519(dec_sk)
    dec_sk = nil
    collectgarbage()
    local result = sm.crypto_box_open_easy(pData, nonce, vk, sk)
    sk = nil
    collectgarbage()
    return CKR.OK, result


end


function t.mt:decrypt_buffer_rsa(hKey, pMechanism, pData, allocated_space)
    log.output('token-nxp-chipdoc-lite:decrypt_buffer_rsa(): ')
    local pDataDecrypted, pcRes, result
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('token-nxp-chipdoc-lite:decrypt_buffer_rsa(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('token-nxp-chipdoc-lite:decrypt_buffer_rsa(): ERROR: not a private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end

    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    if dataLen ~= keyBytes then
        log.output('token-nxp-chipdoc-lite:decrypt_buffer_rsa(): specified data len invalid: ', dataLen, ', expected:', keyBytes)
        return CKR.ENCRYPTED_DATA_LEN_RANGE
    end
    
    if obj.userConsent then
        log.output('token-nxp-chipdoc-lite:decrypt_buffer_rsa(): decrypt not allowed with userConsent kid:', obj.kid)
        return CKR.KEY_FUNCTION_NOT_PERMITTED
    else
        local raw = pMechanism.mechanism ~= CKM.RSA_PKCS
        
        self.nxp_hcard:auto_perform_mutual_authenticate(true) -- check/restore Generic SM session, checkOnActiveSMOnly
        -- self.nxp_hcard:select_Generic()
        self.nxp_hcard:select_SSCD()
        pcRes, result = pcall(function()
                        pDataDecrypted = self.nxp_hcard:pso_dec_rsa(pData, obj.kid) -- data, id
                        log.output('decrypt_buffer_rsa(1): decrypt OK with kid:', obj.kid)
                        end )
        if pcRes then
            if not raw then
                pDataDecrypted = rsa.pkcs1_unpad(pDataDecrypted)
            end
            return CKR.OK, pDataDecrypted
        end
        
        if not pcRes and self.nxp_hcard.last_sw == hex.hexf("6982") then
            log.output('token-nxp-chipdoc-lite:decrypt_buffer_rsa(): restoring secure channel and verifying pin...')
            self.nxp_hcard:auto_perform_mutual_authenticate(true)
            self:verify_cached_pin_or_finger()

            -- self.nxp_hcard:select_Generic()
            self.nxp_hcard:select_SSCD()

            pcRes, result = pcall(function()
                            pDataDecrypted = self.nxp_hcard:pso_dec_rsa(pData, obj.kid) -- data, id
                            log.output('token-nxp-chipdoc-lite:decrypt_buffer_rsa(2): decrypt OK with kid:', obj.kid)
                            end )
            if pcRes then
                if not raw then
                    pDataDecrypted = rsa.pkcs1_unpad(pDataDecrypted)
                end
                return CKR.OK, pDataDecrypted
            end
        end
        if not pcRes then
            log.output('token-nxp-chipdoc-lite:decrypt_buffer_rsa(): error', debug.traceback(result))
            return CKR.FUNCTION_FAILED
        end
        
        pcall(function()
            self:verify_cached_pin_or_finger()
        end)
        -- self.nxp_hcard:select_Generic()
        self.nxp_hcard:select_SSCD()
        pDataDecrypted = self.nxp_hcard:pso_dec_rsa(pData, obj.kid) -- data, id
        log.output('token-nxp-chipdoc-lite:decrypt_buffer_rsa(): decrypt OK with kid:', obj.kid)
        return CKR.OK, pDataDecrypted
    end
    
    log.output('token-nxp-chipdoc-lite:decrypt_buffer_rsa(): unexpected!')
    return CKR.FUNCTION_FAILED
end




function t.mt:decrypt_buffer_rsa_cns(hKey, pMechanism, pData, allocated_space)
    log.output('token-nxp-chipdoc-lite:decrypt_buffer_rsa_cns(): ')
    local pDataDecrypted, pcRes, result
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('token-nxp-chipdoc-lite:decrypt_buffer_rsa_cns(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('token-nxp-chipdoc-lite:decrypt_buffer_rsa_cns(): ERROR: not a private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end

    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    if dataLen ~= keyBytes then
        log.output('token-nxp-chipdoc-lite:decrypt_buffer_rsa_cns(): specified data len invalid: ', dataLen, ', expected:', keyBytes)
        return CKR.ENCRYPTED_DATA_LEN_RANGE
    end
    

    local raw = pMechanism.mechanism ~= CKM.RSA_PKCS

    local wasSMActive = self.nxp_hcard.ActiveSM
    self.nxp_hcard:select_applet_cns(false)
    if self.cached_main_pin then
        self.cns_hcard:verify_pin_cns(self.cached_main_pin)
    end
    
    pcRes, result = pcall(function()
                    pDataDecrypted = self.cns_hcard:rsa_cns(pData, hex.hexify(obj.path), obj.kid)
                    log.output('decrypt_buffer_rsa_cns(1): decrypt OK with kid:', obj.kid)
                    end )
                    
    self.nxp_hcard:select_applet(false)
    if wasSMActive then
        self.nxp_hcard:perform_mutual_authenticate()
    end
    
    if pcRes then
        if not raw then
            pDataDecrypted = rsa.pkcs1_unpad(pDataDecrypted)
        end
        return CKR.OK, pDataDecrypted
    end
    


    
    log.output('token-nxp-chipdoc-lite:decrypt_buffer_rsa(): unexpected!')
    return CKR.FUNCTION_FAILED
end



function t.mt:encrypt_buffer(hKey, pMechanism, pData, allocated_space)
    if pMechanism and pMechanism.mechanism == CKM.CURVE25519_CRYPTO_BOX then
        return self:encrypt_buffer_cryptobox(hKey, pMechanism, pData, allocated_space)
    end
    return self:encrypt_buffer_aes(hKey, pMechanism, pData, allocated_space)
end


function t.mt:encrypt_buffer_cryptobox(hKey, pMechanism, pData, allocated_space)
    log.output(string.format('encrypt_buffer_cryptobox(): hKey=%x', hKey ) )
    log.output(string.format('encrypt_buffer_cryptobox(): pData=%s', pData and hex.hexify(pData) or "<null>" ) )
    log.output(string.format('encrypt_buffer_cryptobox(): allocated_space=%x', allocated_space or -1 ) )
    if pMechanism and pMechanism.mechanism then
        log.output(string.format('encrypt_buffer_cryptobox(): mechanism=%x', pMechanism.mechanism ) )
        log.output(string.format('encrypt_buffer_cryptobox(): parameter=%s', pMechanism.parameter and hex.hexify(pMechanism.parameter) or "<null>"))
    end
    log.output('encrypt_buffer_cryptobox(): pData=', pData and hex.hexify(pData ) or "<null>")
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('encrypt_buffer_cryptobox(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('encrypt_buffer_cryptobox(): ERROR: not a private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    if obj[CKA.KEY_TYPE] ~= eCK.ULONG(CKK.EC_EDWARDS) then
        log.output('encrypt_buffer_cryptobox(): ERROR: not a EC_EDWARDS key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    if not pMechanism or pMechanism.mechanism ~= CKM.CURVE25519_CRYPTO_BOX then
        log.output('encrypt_buffer_cryptobox(): MECHANISM_INVALID:', pMechanism and pMechanism.mechanism )
        return CKR.MECHANISM_INVALID
    end
    
    if type(obj.kid) == 'function' then
        local rv = obj.kid(self, hKey, CKA.CLASS, false)
        if rv ~= CKR.OK then return rv end
    end
    if type(obj.sk) == 'function' then
        local rv = obj.sk(self, hKey, CKA.CLASS, false)
        if rv ~= CKR.OK then return rv end
    end
    
    local crypto_box_NONCEBYTES  = 24
    -- local crypto_box_SECRETKEYBYTES  = 32
    local crypto_box_PUBLICKEYBYTES  = 32
    local nonce
    
    local pk = pMechanism.parameter
    if not pk or string.len(pk) < crypto_box_PUBLICKEYBYTES then
        log.output('encrypt_buffer_cryptobox(): MECHANISM_PARAM_INVALID:', hex.hexify(pMechanism.parameter or ""), "expected len:", crypto_box_PUBLICKEYBYTES )
        return CKR.MECHANISM_PARAM_INVALID
    end
    if string.len(pk) >= (crypto_box_PUBLICKEYBYTES + crypto_box_NONCEBYTES) then
        nonce = string.sub(pk, crypto_box_PUBLICKEYBYTES+1, crypto_box_PUBLICKEYBYTES + crypto_box_NONCEBYTES)
        log.output('encrypt_buffer_cryptobox(): using nonce passed in parameter:', hex.hexify(nonce) )
    else
        nonce = sm.gen_random(crypto_box_NONCEBYTES)
        log.output('encrypt_buffer_cryptobox(): using randomly generated nonce:', hex.hexify(nonce) )
    end
    
    local vk = sm.crypto_sign_ed25519_pk_to_curve25519(string.sub(pk, 1, crypto_box_PUBLICKEYBYTES))
    local dec_sk = t._enc_dec_sensitive_data(obj.sk, self.info.serialNumber, false)
    
    local sk = sm.crypto_sign_ed25519_sk_to_curve25519(dec_sk)
    dec_sk = nil
    collectgarbage()

    local result = sm.crypto_box_easy(pData, nonce, vk, sk)
    sk = nil
    collectgarbage()
    return CKR.OK, nonce .. result


end


function t.mt:encrypt_buffer_aes(hKey, pMechanism, pData, allocated_space)
    log.output(string.format('token-nxp-chipdoc-lite:encrypt_buffer_aes(): hKey=%x', hKey ) )
    log.output(string.format('token-nxp-chipdoc-lite:encrypt_buffer_aes(): pData=%s', pData and hex.hexify(pData) or "<null>" ) )
    log.output(string.format('token-nxp-chipdoc-lite:encrypt_buffer_aes(): allocated_space=%x', allocated_space or -1 ) )
    if pMechanism and pMechanism.mechanism then
        log.output(string.format('token-nxp-chipdoc-lite:encrypt_buffer_aes(): mechanism=%x', pMechanism.mechanism ) )
        log.output(string.format('token-nxp-chipdoc-lite:encrypt_buffer_aes(): parameter=%s', pMechanism.parameter and hex.hexify(pMechanism.parameter) or "<null>"))
    end
    log.output('token-nxp-chipdoc-lite:encrypt_buffer_aes(): pData=', pData and hex.hexify(pData ) or "<null>")
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('token-nxp-chipdoc-lite:encrypt_buffer_aes(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.SECRET_KEY) then
        log.output('token-nxp-chipdoc-lite:encrypt_buffer_aes(): ERROR: not SECRET_KEY object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    if obj[CKA.KEY_TYPE] ~= eCK.ULONG(CKK.AES) then
        log.output('token-nxp-chipdoc-lite:encrypt_buffer_aes(): ERROR: not a AES key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end

    if not pMechanism or (pMechanism.mechanism ~= CKM.AES_CBC and pMechanism.mechanism ~= CKM.AES_CBC_PAD) then
        log.output('token-nxp-chipdoc-lite:encrypt_buffer_aes(): MECHANISM_INVALID:', pMechanism and pMechanism.mechanism )
        return CKR.MECHANISM_INVALID
    end

    if allocated_space==nil then
        local enc_len = math.floor((string.len(pData) + (aes.BLOCK_LEN*2) -1) / aes.BLOCK_LEN) * aes.BLOCK_LEN
        log.output('token-nxp-chipdoc-lite:encrypt_buffer_aes(): returning (guessed) encrypted data length:', enc_len)
        return CKR.OK, enc_len
    end
    
    local pDataToEnc = pData
    
    if pMechanism.mechanism  == CKM.AES_CBC_PAD then
        pDataToEnc = aes.pkcs5_padding(aes.BLOCK_LEN, pData)
    end
    local iv = pMechanism.parameter and string.sub(pMechanism.parameter, 1, aes.BLOCK_LEN)
    
    if iv and string.len(iv) < aes.BLOCK_LEN then
        log.output('token-nxp-chipdoc-lite:encrypt_buffer_aes(): invalid IV specified, ignoring...')
        iv = nil
    end
    pcall(function()
        self:verify_cached_pin_or_finger()
    end)
    self.nxp_hcard:get_free_mem()
    
    local result, iv = aes.AES_CBC2(obj.value, pDataToEnc, true, iv)

    log.output('token-nxp-chipdoc-lite:encrypt_buffer_aes(): result:', hex.hexify(result or ""))
    log.output('token-nxp-chipdoc-lite:encrypt_buffer_aes(): iv:', hex.hexify(iv or ""))

    collectgarbage()
    return CKR.OK, result, iv
end



function t.mt:decrypt_buffer_aes(hKey, pMechanism, pEncryptedData, allocated_space)
    log.output(string.format('token-nxp-chipdoc-lite:decrypt_buffer_aes(): hKey=%x', hKey ) )
    log.output(string.format('token-nxp-chipdoc-lite:decrypt_buffer_aes(): pEncryptedData=%s', pEncryptedData and hex.hexify(pEncryptedData) or "<null>" ) )
    log.output(string.format('token-nxp-chipdoc-lite:decrypt_buffer_aes(): allocated_space=%x', allocated_space or -1 ) )
    if pMechanism and pMechanism.mechanism then
        log.output(string.format('token-nxp-chipdoc-lite:decrypt_buffer_aes(): mechanism=%x', pMechanism.mechanism ) )
        log.output(string.format('token-nxp-chipdoc-lite:decrypt_buffer_aes(): parameter=%s', pMechanism.parameter and hex.hexify(pMechanism.parameter) or "<null>"))
    end
    log.output('token-nxp-chipdoc-lite:decrypt_buffer_aes(): pEncryptedData=', pEncryptedData and hex.hexify(pEncryptedData ) or "<null>")
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('token-nxp-chipdoc-lite:decrypt_buffer_aes(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.SECRET_KEY) then
        log.output('token-nxp-chipdoc-lite:decrypt_buffer_aes(): ERROR: not SECRET_KEY object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    if obj[CKA.KEY_TYPE] ~= eCK.ULONG(CKK.AES) then
        log.output('token-nxp-chipdoc-lite:decrypt_buffer_aes(): ERROR: not a AES key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    

    if not pMechanism or (pMechanism.mechanism ~= CKM.AES_CBC and pMechanism.mechanism ~= CKM.AES_CBC_PAD) then
        log.output('token-nxp-chipdoc-lite:decrypt_buffer_aes(): MECHANISM_INVALID:', pMechanism and pMechanism.mechanism )
        return CKR.MECHANISM_INVALID
    end

    if allocated_space==nil then
        local enc_len = math.floor((string.len(pEncryptedData) + (aes.BLOCK_LEN*2) -1) / aes.BLOCK_LEN) * aes.BLOCK_LEN
        log.output('token-nxp-chipdoc-lite:decrypt_buffer_aes(): returning (guessed) encrypted data length:', enc_len)
        return CKR.OK, enc_len
    end
    
    pcall(function()
        self:verify_cached_pin_or_finger()
    end)
    self.nxp_hcard:get_free_mem()
    
    local iv = pMechanism.parameter and string.sub(pMechanism.parameter, 1, aes.BLOCK_LEN)
    
    if iv and string.len(iv) < aes.BLOCK_LEN then
        log.output('token-nxp-chipdoc-lite:decrypt_buffer_aes(): invalid IV specified, ignoring...')
        iv = nil
    end
    
    local pDataUnpadded, iv = aes.AES_CBC2(obj.value, pEncryptedData, false, iv)
    
    log.output('token-nxp-chipdoc-lite:decrypt_buffer_aes(): pDataUnpadded:', hex.hexify(pDataUnpadded or ""))
    log.output('token-nxp-chipdoc-lite:encrypt_buffer_aes(): iv:', hex.hexify(iv or ""))
    
    if pMechanism.mechanism  == CKM.AES_CBC_PAD then
        log.output('token-nxp-chipdoc-lite:decrypt_buffer_aes(): unpadding:', hex.hexify(pDataUnpadded or ''))
        pDataUnpadded = aes.pkcs5_unpad(pDataUnpadded)
        log.output('token-nxp-chipdoc-lite:decrypt_buffer_aes(): pDataUnpadded unpadded:', hex.hexify(pDataUnpadded or ""))
    end

    collectgarbage()
    return CKR.OK, pDataUnpadded, iv
end



-- se search_state.lastobj==nil si richiede l'handle del primo oggetto che risponda
-- al template. Altrimenti restituisce il primo oggetto che sia
-- compatibile con il template e abbia handle>search_state.lastobj.
-- quando non ci sono piu' oggetti ritorna 0
function t.mt:get_item(search_state, showprivate, template)
    log.output('get_item(): showprivate', showprivate)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    log.output('get_item(): approx available objects:', 1+ self.attributes.max_index - self.attributes.min_index )
    if search_state.lastobj==nil then 
        search_state.lastobj=self.attributes.min_index 
    end
    
    if template[CKA.CLASS] == eCK.ULONG(CKO_PIN_POLICY) then
    
        log.output('get_item(): SPECIAL SEARCH: PIN POLICY, lastobj, min_index, max_index:', search_state.lastobj,
            self.attributes.min_index, self.attributes.max_index)
    
        if search_state.lastobj ~= self.attributes.min_index then
            log.output('get_item(): SPECIAL SEARCH: PIN POLICY: end of search')
            return 0
        end
        
        log.output('get_item(): SPECIAL SEARCH: PIN POLICY: populating data')
        search_state.lastobj = math.max(self.attributes.min_index, self.attributes.max_index)+1
        obj = {[CKA.CLASS]=eCK.ULONG(CKO_PIN_POLICY), [CKA.TOKEN]=eCK.BBOOL(true), [CKA.VALUE]=self.pin_policy_value}
        self.attributes[1] = obj
        return 1 -- special handle value
    end
    
    for i=search_state.lastobj, self.attributes.max_index do
        local attr = self.attributes[i]
        log.output('get_item(): eval object:', i)
        if attr ~= nil then
            if type(attr[CKA.PRIVATE]) == 'function' then
                attr[CKA.PRIVATE](self, i, CKA.PRIVATE, false)
            end
            local private = attr.private or attr[CKA.PRIVATE] ~= eCK.BBOOL(false)
            log.output('get_item(): private:', private)
            local visible = not private or 
                            (private and showprivate)
            if not visible then
                log.output('get_item(): handle', i, 'not visible')
            end
            if visible and self:verify_template(i, template) then
                search_state.lastobj = i +1
                return i
            end
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

function t.mt:get_privkey(hobj, att_type, onlysize, force_all)
    log.output('token-nxp-chipdoc-lite:get_privkey()')
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('token-nxp-chipdoc-lite:get_privkey(): ERROR! not a private key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadere
    end

    log.output('token-nxp-chipdoc-lite:get_privkey():', obj.kid)
    if att_type == CKA.MODULUS or att_type == CKA.PUBLIC_EXPONENT then
    
        local hexkeyReference_pubkey = hex.hexify(obj.keyReference_pubkey)
        local modulus, pubexp
        local info = self:get_info()
        local mod_label = "modulus_" .. hexkeyReference_pubkey
        local exp_label = "pubexp_" .. hexkeyReference_pubkey
        
        if info and self:cache_enabled() then
            log.output('token-nxp-chipdoc-lite:get_privkey(): trying cache...')
            modulus = utility.cache_read(info.serialNumber, mod_label, self._AvoidUseLastUpdate, self._umcachepath)
            pubexp = utility.cache_read(info.serialNumber, exp_label, self._AvoidUseLastUpdate, self._umcachepath)
        end
        if not modulus and not pubexp then
            log.output('token-nxp-chipdoc-lite:get_privkey(): reading from card...')
            local pcRes, theErrorT = pcall(function()
                self.nxp_hcard:select_Generic()
                local finfo = self.nxp_hcard:select(obj.keyReference_pubkey, true)
                local data =  self.nxp_hcard:mread_binary(0, finfo.size)
                pubexp = util.ltrim( string.sub(data, 1, 4), "\0")
                modulus = string.sub(data, 5, -1)
            end)
            if not pcRes then
                log.output("token-nxp-chipdoc-lite:get_privkey():read_public_key RSA: error:", debug.traceback(theErrorT) )
            end
            if modulus and pubexp and info and self:cache_enabled() then
                log.output("token-nxp-chipdoc-lite:get_privkey():read_public_key: updating cache...")
                utility.cache_write(info.serialNumber, mod_label, modulus, self._umcachepath)
                utility.cache_write(info.serialNumber, exp_label, pubexp, self._umcachepath)
            end
        end
        obj[CKA.MODULUS] = modulus
        obj[CKA.PUBLIC_EXPONENT] = pubexp or hex.hexf('010001')
    end
    
    obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
    obj[CKA.SIGN] = eCK.BBOOL(true)
    
    obj[CKA.SIGN_RECOVER] = eCK.BBOOL(false)
    obj[CKA.VERIFY] = eCK.BBOOL(false)
    obj[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    obj[CKA.UNWRAP] = eCK.BBOOL(false)
    
    obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
    obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(obj.userConsent)
    -- obj[CKA.DECRYPT] = eCK.BBOOL(not obj.userConsent)
    
    obj.populated = true
    return CKR.OK, obj[att_type]
end


function t.mt:get_secret_key(hobj, att_type, onlysize, force_all)
    log.output('token-nxp-chipdoc-lite:get_secret_key()')
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.SECRET_KEY) then
        log.output('token-nxp-chipdoc-lite:get_secret_key(): ERROR! not a secret key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadere
    end

    local value = obj.value or ""

    obj[CKA.KEY_TYPE] = eCK.ULONG(CKK.AES)

    obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
    
    obj[CKA.SIGN] = eCK.BBOOL(false)
    obj[CKA.SIGN_RECOVER] = eCK.BBOOL(false)
    obj[CKA.VERIFY] = eCK.BBOOL(false)
    obj[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    obj[CKA.UNWRAP] = eCK.BBOOL(false)
    obj[CKA.WRAP] = eCK.BBOOL(false)
    
    obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
    obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
    obj[CKA.DECRYPT] = eCK.BBOOL(true)
    obj[CKA.ENCRYPT] = eCK.BBOOL(true)
    
    obj.populated = true
    return CKR.OK, obj[att_type]
end


function t.mt:get_pubkey(hobj, att_type, onlysize, force_all)
    log.output('token-nxp-chipdoc-lite:get_pubkey()')
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PUBLIC_KEY) then
        log.output('token-nxp-chipdoc-lite:get_pubkey(): ERROR! not a public key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadere
    end
    
    log.output('token-nxp-chipdoc-lite:get_pubkey():', hex.hexify(obj.keyReference_pubkey or ""))
    if att_type == CKA.MODULUS or att_type == CKA.PUBLIC_EXPONENT then
    
        local hexkeyReference_pubkey = hex.hexify(obj.keyReference_pubkey)
        local modulus, pubexp
        local info = self:get_info()
        local mod_label = "modulus_" .. hexkeyReference_pubkey
        local exp_label = "pubexp_" .. hexkeyReference_pubkey
        
        if info and self:cache_enabled() then
            log.output('token-nxp-chipdoc-lite:get_pubkey(): trying cache...')
            modulus = utility.cache_read(info.serialNumber, mod_label, self._AvoidUseLastUpdate, self._umcachepath)
            pubexp = utility.cache_read(info.serialNumber, exp_label, self._AvoidUseLastUpdate, self._umcachepath)
        end
        if not modulus and not pubexp then
            log.output('token-nxp-chipdoc-lite:get_pubkey(): reading from card...')
            
            local pcRes, theErrorT = pcall(function()
                self.nxp_hcard:select_Generic()
                local finfo = self.nxp_hcard:select(obj.keyReference_pubkey, true)
                local data =  self.nxp_hcard:mread_binary(0, finfo.size)
                pubexp = util.ltrim( string.sub(data, 1, 4), "\0")
                modulus = string.sub(data, 5, -1)
            end)
            if not pcRes then
                log.output("token-nxp-chipdoc-lite:get_pubkey():read_public_key RSA: error:", debug.traceback(theErrorT) )
            end
            if modulus and pubexp and info and self:cache_enabled() then
                log.output("token-nxp-chipdoc-lite:get_pubkey():read_public_key: updating cache...")
                utility.cache_write(info.serialNumber, mod_label, modulus, self._umcachepath)
                utility.cache_write(info.serialNumber, exp_label, pubexp, self._umcachepath)
            end
        end
        obj[CKA.MODULUS] = modulus
        obj[CKA.PUBLIC_EXPONENT] = pubexp or hex.hexf('010001')
    end
    
    obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
    obj[CKA.VERIFY] = eCK.BBOOL(true)
    obj[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    --obj[CKA.ENCRYPT] = eCK.BBOOL(not obj.userConsent)
    obj[CKA.WRAP] = eCK.BBOOL(false)

    obj.populated = true
    return CKR.OK, obj[att_type]
    
end


function t.mt:get_ecc_privkey(hobj, att_type, onlysize, force_all)
    log.output('token-nxp-chipdoc-lite:get_ecc_privkey()')
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('token-nxp-chipdoc-lite:get_ecc_privkey(): ERROR! not a private key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadere
    end

    if obj[CKA.KEY_TYPE] == eCK.ULONG(CKK.EC_EDWARDS) then
        log.output('get_ecc_privkey(): reading EC_EDWARDS value...')
        pcRes, theErrorT = pcall(function()
                    local keyReference_privkey = hex.hexf("DE%B", obj.kid )
                    log.output('get_ecc_privkey(): calculated keyReference_privkey:', hex.hexify(keyReference_privkey) )
                    self.nxp_hcard:select_MF()
                    self.nxp_hcard:select_SSCD()
                    local val = self:read_cached_file(keyReference_privkey, 0, -1, true)
                    obj.sk = val
                end
                )
        if not pcRes then
            log.output('get_ecc_privkey_ds(): error reading reading val for ecc privkey:', debug.traceback(theErrorT) )
        end
    end
    
    if att_type == CKA.EC_POINT then
    
        local hexkeyReference_pubkey = hex.hexify(obj.keyReference_pubkey)
        local ec_point
        local info = self:get_info()
        local ec_point_label = "ec_point_" .. hexkeyReference_pubkey
        
        if info and self:cache_enabled() then
            log.output('token-nxp-chipdoc-lite:get_ecc_privkey(): trying cache...')
            ec_point = utility.cache_read(info.serialNumber, ec_point_label, self._AvoidUseLastUpdate, self._umcachepath)
        end
        if not ec_point then
            log.output('token-nxp-chipdoc-lite:get_ecc_privkey(): reading from card...')

            self.nxp_hcard:select_Generic()
            

            local pcRes, theErrorT = pcall(function()
                local finfo = self.nxp_hcard:select(obj.keyReference_pubkey, true)
                ec_point = self.nxp_hcard:mread_binary(0, finfo.size)
            end)
            if not pcRes then
                log.output("token-nxp-chipdoc-lite:get_ecc_privkey():read_public_key_ECC: error:", debug.traceback(theErrorT) )
            end

            if ec_point and info and self:cache_enabled() then
                log.output("token-nxp-chipdoc-lite:get_ecc_privkey():read_public_key_ECC: updating cache...")
                utility.cache_write(info.serialNumber, ec_point_label, ec_point, self._umcachepath)
            end
        end
        obj[CKA.EC_POINT] = ec_point
    end
    
    obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
    obj[CKA.SIGN] = eCK.BBOOL(true)
    
    obj[CKA.SIGN_RECOVER] = eCK.BBOOL(false)
    obj[CKA.VERIFY] = eCK.BBOOL(false)
    obj[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    obj[CKA.UNWRAP] = eCK.BBOOL(false)
    
    obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
    obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(obj.userConsent)
    obj[CKA.DECRYPT] = eCK.BBOOL(false)
    
    obj.populated = true
    return CKR.OK, obj[att_type]
end


function t.mt:get_ecc_pubkey(hobj, att_type, onlysize, force_all)
    log.output('token-nxp-chipdoc-lite:get_ecc_pubkey()')
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PUBLIC_KEY) then
        log.output('token-nxp-chipdoc-lite:get_ecc_pubkey(): ERROR! not a public key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadere
    end
    
    if att_type == CKA.EC_POINT then
    
        local hexkeyReference_pubkey = hex.hexify(obj.keyReference_pubkey)
        local ec_point
        local info = self:get_info()
        local ec_point_label = "ec_point_" .. hexkeyReference_pubkey
        
        if info and self:cache_enabled() then
            log.output('token-nxp-chipdoc-lite:get_ecc_pubkey(): trying cache...')
            ec_point = utility.cache_read(info.serialNumber, ec_point_label, self._AvoidUseLastUpdate, self._umcachepath)
        end
        if not ec_point then
            log.output('token-nxp-chipdoc-lite:get_ecc_pubkey(): reading from card...')

            self.nxp_hcard:select_Generic()
            

            local pcRes, theErrorT = pcall(function()
                local finfo = self.nxp_hcard:select(obj.keyReference_pubkey, true)
                ec_point = self.nxp_hcard:mread_binary(0, finfo.size)
            end)
            if not pcRes then
                log.output("token-nxp-chipdoc-lite:get_ecc_pubkey():read_public_key_ECC: error:", debug.traceback(theErrorT) )
            end

            if ec_point and info and self:cache_enabled() then
                log.output("token-nxp-chipdoc-lite:get_ecc_pubkey():read_public_key_ECC: updating cache...")
                utility.cache_write(info.serialNumber, ec_point_label, ec_point, self._umcachepath)
            end
        end
        obj[CKA.EC_POINT] = ec_point
    end
    
    obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
    obj[CKA.VERIFY] = eCK.BBOOL(true)
    obj[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    obj[CKA.ENCRYPT] = eCK.BBOOL(false)
    obj[CKA.WRAP] = eCK.BBOOL(false)

    obj.populated = true
    return CKR.OK, obj[att_type]
    
end

function t.mt:get_certificate(hobj, att_type, onlysize, force_all)
    log.output('token-nxp-chipdoc-lite:get_certificate()')
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local obj = self.attributes[hobj]
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.CERTIFICATE) then
        log.output('get_certificate(): ERROR! not a certificate object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadere
    end

    local info = self:get_info()

    
    local cert_value
    
    if info and self:cache_enabled() then
        log.output('token-nxp-chipdoc-lite:get_certificate(): trying cache...')
        cert_value = utility.cache_read(info.serialNumber, obj.path, self._AvoidUseLastUpdate, self._umcachepath)

    end
    if not cert_value then
        log.output('token-nxp-chipdoc-lite:get_certificate(): reading fresh value frpm card...')
        self.nxp_hcard:select_Generic()
        cert_value = self.nxp_hcard:read_cert(obj.path)
        if info and self:cache_enabled() then
            utility.cache_write(info.serialNumber, obj.path, cert_value, self._umcachepath)
        end
    end
    log.output("token-nxp-chipdoc-lite:get_certificate(): cert value:", hex.hexify(cert_value))
    
    local parsed_cer = der.parse_x509cer(cert_value)
    obj[CKA.VALUE] = cert_value or obj[CKA.VALUE]
    obj[CKA.SUBJECT] = (parsed_cer and parsed_cer.subject) or ''
    obj[CKA.ISSUER] = (parsed_cer and parsed_cer.issuer) or ''
    obj[CKA.SERIAL_NUMBER] = (parsed_cer and parsed_cer.serialNumber) or ''
    obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
    obj[CKA.TRUSTED]    = eCK.BBOOL(false)
    
    obj.populated = true
    return CKR.OK, obj[att_type]
end

function t.mt:get_data_object(hobj, att_type, onlysize, force_all)
    log.output('token-nxp-chipdoc-lite:get_data_object(): att_type', att_type)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local obj = self.attributes[hobj]
    local value = ''
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.DATA) then
        log.output('get_data_object(): ERROR! not a DATA object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadere
    end
    
    local pcRes, theErrorT = pcall(function()
        -- self.aet_hcard:select(obj.path, true)  -- fid, relative
        self.nxp_hcard:select_Generic() -- TODO: not always required
        local value = self:read_cached_file(obj.path, 0, -1, true)
        
        obj[CKA.VALUE] = value
        obj.populated = true
    end)
    if not pcRes then
        log.output('token-nxp-chipdoc-lite:get_data_object(): error:', debug.traceback(theErrorT))
        if att_type == CKA.VALUE then
            return CKR.FUNCTION_FAILED
        end
    end
    return CKR.OK, obj[att_type]
end


function t.mt:cache_enabled()
    return utility.cache_can_use() and self.cfg["fastread"]=='true' or self.cfg["ofastread"]=='true'
end

function t.mt:cache_clear()
    if self:cache_enabled() then
        log.output('token-nxp-chipdoc-lite:cache_clear(): removing whole cache...')
        -- elimina tutta la cache statica del token
        local info = self:get_info()
        log.output('removing cache for serial', info.serialNumber)
        utility.cache_write(info.serialNumber, nil, nil, self._umcachepath)
    end
end

function  t.mt:read_cached_file(fid, offset, count, update_cache, update_on_read_failure)
    local val
    log.output(string.format("token-nxp-chipdoc-lite:read_cached_file: fid=%s, offset=%d, count=%d, update_cache=%s", hex.hexify(fid), offset, count, tostring(update_cache)) )
    local info = self.info
    if self:cache_enabled() and info then
        log.output("token-nxp-chipdoc-lite:read_cached_file: trying cache...")
        local val_full = utility.cache_read(info.serialNumber, fid, self._AvoidUseLastUpdate, self._umcachepath)
        log.output(string.format("token-nxp-chipdoc-lite:read_cached_file: full cached value=%s", hex.hexify(val_full or "")) )
        if val_full and (  (count<0 and string.len(val_full) >= (offset)) 
                        or (count>=0 and string.len(val_full) >= (offset+count)) )then
            local stop = offset+count
            if count < 0 then
                stop = -1
            end
            val = string.sub(val_full, offset+1, stop)
            log.output(string.format("token-nxp-chipdoc-lite:read_cached_file: returning cached value=%s from offset=%d to %d", hex.hexify(val), offset+1, stop) )
            return val
        end
    end
    
    log.output("token-nxp-chipdoc-lite:read_cached_file: reading from card")
    local pcRes, theErrorT = pcall(function()
        local finfo = self.nxp_hcard:select(fid, true)
        if not finfo then
            finfo = {size=255}
        end
        if count < 0 then
            count = finfo.size
        end
    end)
    
    if not pcRes then
        log.output('token-nxp-chipdoc-lite:read_cached_file(): select() error:', debug.traceback( theErrorT))
        if update_cache and self:cache_enabled() and update_on_read_failure then
            log.output('token-nxp-chipdoc-lite:read_cached_file(): update_on_read_failure is true, caching empty value...')
            val = ""
        else
            error(theErrorT)
        end
    else
        log.output(string.format("token-nxp-chipdoc-lite:read_cached_file: reading from card: count=%d", count))
        val = self.nxp_hcard:mread_binary_smart(offset, count)
        if string.len(val) < count then
            val = val .. string.rep("\0", count - string.len(val) )
        end
        log.output(string.format("token-nxp-chipdoc-lite:read_cached_file: got fresh value=%s", hex.hexify(val)) )
    end
    if info and update_cache and self:cache_enabled() then
        log.output("token-nxp-chipdoc-lite:read_cached_file: updating cache")
        log.output("token-nxp-chipdoc-lite:read_cached_file: serialNumber: ", info.serialNumber)
        utility.cache_write(info.serialNumber, fid, val, self._umcachepath)
    end
    return val  
end

function t.mt:read_cache_version()
    return self:read_cache_version_file()
end

function t.mt:read_cache_version_file(use_cached_cia_info)

    local pcRes, contents
    if use_cached_cia_info and self.cia_info and self.cia_info.lastUpdate then
        contents = self.cia_info.lastUpdate
        pcRes = true
    else
        pcRes, contents = pcall(function()
            self.nxp_hcard:select_Generic()
            local cia_infoD = self.nxp_hcard:read_binary_sfi( self.files.tokenInfo_sfi, 0, 0)
            local cia_info = p15.parse_tokenInfo(cia_infoD)
            local offset = string.find(cia_infoD, cia_info.lastUpdate, 1, false)
            if offset then
                log.output("token-nxp-chipdoc-lite:read_cache_version_file() old tokenInfo_lastModified_offset:", self.files.tokenInfo_lastModified_offset)
                self.files.tokenInfo_lastModified_offset = offset-1
                log.output("token-nxp-chipdoc-lite:read_cache_version_file() new tokenInfo_lastModified_offset:", self.files.tokenInfo_lastModified_offset)
            end
            log.output("token-nxp-chipdoc-lite:read_cache_version_file() old tokenInfo_lastModified_size:", self.files.tokenInfo_lastModified_size)
            self.files.tokenInfo_lastModified_size = string.len(cia_info.lastUpdate)
            log.output("token-nxp-chipdoc-lite:read_cache_version_file() new tokenInfo_lastModified_size:", self.files.tokenInfo_lastModified_size)

            self.cia_info = cia_info
            return cia_info.lastUpdate
        end)
    end
    if not pcRes then
        log.output("token-nxp-chipdoc-lite:read_cache_version_file() error:", debug.traceback(contents))
    end
    return contents
end

function t.mt:write_cache_version_file(value)
    
    log.output('token-nxp-chipdoc-lite:write_cache_version_file():')
    
    if not value then
        local curTime = os.date ("!*t")
        value = string.format("%04d%02d%02d%02d%02d%02d", curTime.year, curTime.month, curTime.day, curTime.hour, curTime.min, curTime.sec)
        log.output('token-nxp-chipdoc-lite:write_cache_version_file(): using cur time:', value)
    elseif string.len(value) ~= self.files.tokenInfo_lastModified_size then
        log.output('token-nxp-chipdoc-lite:write_cache_version_file(): invalid value len')
        error("token-nxp-chipdoc-lite:write_cache_version_file(): value len invalid, EXPECTED: " .. self.files.tokenInfo_lastModified_size)
    end
    
    local pcRes, theErrorT = pcall(function()
        self.nxp_hcard:select_Generic()
        return self.nxp_hcard:mupdate_binary(
                self.files.tokenInfo_lastModified_offset,
                value,
                nil,
                self.files.tokenInfo_sfi)
    end)
    if not pcRes then
        log.output('token-nxp-chipdoc-lite:write_cache_version_file(): error:', debug.traceback(theErrorT))
    else
        log.output('token-nxp-chipdoc-lite:write_cache_version_file(): successfully wrote value:', value)
    end
   return value
end


function t.mt:check_clear_cache(clear_memory_cache, use_cached_cia_info)
    log.output('token-nxp-chipdoc-lite:check_clear_cache():', clear_memory_cache, use_cached_cia_info)
    
    local info = self.info
    if info and self:cache_enabled() then
    
        if self._clear_cache then
            log.output('token-nxp-chipdoc-lite:check_clear_cache(): self._clear_cache is set, flushing whole cache...')
            utility.cache_write(info.serialNumber, nil, nil, self._umcachepath)
            self._clear_cache = false
        end
        
        local cache_name = "CACHE_ID"
        local val_cached = utility.cache_read(info.serialNumber, cache_name, true, self._umcachepath)
        
        local val_fresh = self:read_cache_version_file(use_cached_cia_info)
        
        log.output(string.format('token-nxp-chipdoc-lite:check_clear_cache(): val_cached=%s, val_fresh=%s', hex.hexify(val_cached or ""), hex.hexify(val_fresh or "")))
        
        if not val_fresh then
            log.output('token-nxp-chipdoc-lite:check_clear_cache(): unable to read fresh cache version file')
            return
        end
        
        if val_fresh ~= val_cached then
            log.output('token-nxp-chipdoc-lite:check_clear_cache(): cache changed, clearing permament cache for serialNumber:', info.serialNumber)
            utility.cache_write(info.serialNumber, nil, nil, self._umcachepath)
            utility.cache_write(info.serialNumber, cache_name, val_fresh, self._umcachepath)

        end
        if clear_memory_cache and self.cache_id_val and self.cache_id_val ~= val_fresh then
            log.output('token-nxp-chipdoc-lite:check_clear_cache(): clearing internal memory cache')
            self.info = nil -- rimuove cache oggetti
            self._indexes = nil
            self.attributes = self:get_objects()  -- riscostruisce cache oggetti
        end
        self.cache_id_val = val_fresh
    else
        log.output('token-nxp-chipdoc-lite:check_clear_cache(): cache enabled:', self:cache_enabled())
    end
end

function t.mt:update_cache_id()

    log.output("token-nxp-chipdoc-lite:update_cache_id():")
    local val_fresh_new

    local info = self.info
    if info then       
        val_fresh_new = self:write_cache_version_file()
        log.output('token-nxp-chipdoc-lite:update_cache_id(): wrote new cache id to card:', hex.hexify(val_fresh_new or ""))
        log.output('token-nxp-chipdoc-lite:update_cache_id(): clearing permament cache for serialNumber:', info.serialNumber)
        utility.cache_write(info.serialNumber, nil, nil, self._umcachepath)
        self.cache_id_val = val_fresh_new or self.cache_id_val
    end
    return val_fresh_new
end

local function decode_bool_attributes(classAttributes, obj)
    if classAttributes.usage then
        p15.decode_KeyUsageFlags(classAttributes.usage, obj)
    end
    if classAttributes.accessFlags then
        p15.decode_KeyAccessFlags(classAttributes.accessFlags, obj)
    end
end

function t._parse_fingerprint_objects(value)
    local fingerprint
    local res = {}
    local seq1 = der.parse(value) -- decode fingerprints objects
    
    for i=1,table.getn(seq1) do
        fingerprint = {}
        if seq1[i].tag == 0 then
            break
        end
        
        local seq2 = der.parse(seq1[i].value) -- decode fingerprints objects
        
        local j=1
        if seq2[j] and seq2[j].tag == der.UTF8STRING then
            fingerprint.label = seq2[j].value
            fingerprint.label_tag = seq2[j].tag
            j = j+1
        end
        
        if seq2[j] and seq2[j].tag == der.STRING then
            fingerprint.id = seq2[j].value
            fingerprint.id_tag = seq2[j].tag
            j = j+1
        end
        
        res[i] = fingerprint
    end
    
    return res
end

function t._build_fingerprint_objects(fingerprints)
    local res = ""
    for i=1,table.getn(fingerprints) do
        local fingerprint = fingerprints[i]

        local label_tag = fingerprint.label_tag or der.UTF8STRING
        local id_tag = fingerprint.id_tag or der.STRING
        local labelD = fingerprint.label and der.build(label_tag, fingerprint.label) or ""
        local idD = fingerprint.id and der.build(id_tag, fingerprint.id) or ""
        
        local fingerprintD = der.build(der.SEQUENCE, labelD .. idD)
        
        res = res .. fingerprintD
        
    end
    return res
end

-- local finerprints = {
    -- {label="ciao 0!", id="\0",},
    -- {label="ciao 1", id="\1",},
-- }

-- local finerprintsD = t._build_fingerprint_objects(finerprints)
-- print("finerprintsD:", hex.hexify(finerprintsD))

-- local finerprintsD_parsed = t._parse_fingerprint_objects(finerprintsD)
-- print("finerprintsD_parsed:", util.repr(finerprintsD_parsed))
-- print("finerprints:", util.repr(finerprintsD_parsed))

function t.mt:_add_objects(objects)
    log.output("token-nxp-chipdoc-lite:_add_objects()")

    self.nxp_hcard:select_Generic()

    
    -- local ef_od = self.nxp_hcard:read_binary_sfi(tonumber("11", 16), 0, 0)
    -- log.output ("ef_od:", hex.hexify(ef_od))
    
    -- local cia_info = self.nxp_hcard:read_binary_sfi(tonumber("12", 16), 0, 0)
    -- log.output ("cia_info:", hex.hexify(cia_info))
    
    -- local finfos = self.nxp_hcard:select(tonumber("7001", 16), true, true)
    -- log.output ("finfos 7001 AOD:", util.repr(finfos))

    -- local AOD = self.nxp_hcard:mread_binary_smart(0, finfos.size, true)
    -- local AODInfo = p15.parseAuthObjects(AOD)
    -- for i, v in AODInfo do
        -- for x, y in v do
            -- log.output("\t", x, utility.repr(y))
        -- end
    -- end
    

    -- local finfos = self.nxp_hcard:select(tonumber("7004", 16), true, true)
    -- log.output ("finfos 7004 PubKD:", util.repr(finfos))

    -- local PrKD = self.nxp_hcard:mread_binary_smart(0, finfos.size, true)
    -- local PrKDInfo = p15.parsePubPrivKD(PrKD)
    -- for i, v in PrKDInfo do
        -- for x, y in v do
            -- log.output ("\t", x, utility.repr(y))
        -- end
    -- end
    
    -- local finfos = self.nxp_hcard:select(tonumber("7002", 16), true)
    -- log.output ("finfos 7002 PrKD:", util.repr(finfos))

    -- local PrKD = self.nxp_hcard:mread_binary_smart(0, finfos.size)

    -- local cia_info = self:read_cached_file(self.files.tokenInfo, 0, -1, true)
    

    local PubKD = self:read_cached_file(self.files.PubKD, 0, -1, true)
    local PrKD = self:read_cached_file(self.files.PrivKD, 0, -1, true)
    local secretKD = self:read_cached_file(self.files.secretKD, 0, -1, true)
    local certD = self:read_cached_file(self.files.CDF, 0, -1, true)
    local dataD = self:read_cached_file(self.files.dataDF, 0, -1, true)
    
    

    self._indexes = {}
    self._indexes._public_keys_bin = PubKD
    self._indexes._private_keys_bin = PrKD
    self._indexes._certificates_bin = certD
    self._indexes._secret_keys_bin = secretKD
    self._indexes._data_objects_bin = dataD
    
    if type(self.maxFingerprints) == "number" then
        local FPOD = self:read_cached_file(self.files.FPOD, 0, -1, true)
        self._indexes._fingerprints_bin = FPOD
        if self._indexes._fingerprints_bin then
            log.output("adding FINGERPRINT objects...")
            local d = t._parse_fingerprint_objects(self._indexes._fingerprints_bin)
            for i, v in d do
                
                log.output(string.format("fingerprint object %d:", i))
                for x, y in v do
                    log.output ("\t", x, utility.repr(y))
                end
                local obj = GetFingerprintObjectTemplate()
        
                obj.private = false
                obj[CKA.LABEL] = v.label
                obj[CKA.ID] = v.id
                
                obj.num = i
                
                objects.max_index = objects.max_index +1
                objects[ objects.max_index] = obj
                log.output(
                    string.format("_add_objects(): added fingerprint object: num:%d handle:%d", 
                        obj.num, objects.max_index)
                    )
            end
        end
    end

    local secretKDInfo = p15.parsePubPrivKD(secretKD)
    log.output ("adding secret keys...")
    for i, v in secretKDInfo do
        local proceed = true
        for x, y in v do
            log.output ("\t", x, utility.repr(y))
        end
        log.output ("evaluating secret key:", i)
        log.output ("efidOrPath:", v.typeAttributes.path.efidOrPath_tag, hex.hexify(v.typeAttributes.path.efidOrPath) )
        -- print ("efidOrPath:", hex.hexify(v.typeAttributes.path.efidOrPath), v.typeAttributes.path.efidOrPath_tag)
        -- print ("modulusLength:", v.typeAttributes.modulusLength)
        -- print ("userConsent:", v.commonObjectAttributes.userConsent)
        -- print ("keyReference:", v.classAttributes.keyReference)
        -- print ("label:", v.commonObjectAttributes.label)
        -- print ("iD:", v.classAttributes.iD)
        
        local obj
  
        if v.typeAttributes.path.efidOrPath_tag == der.STRING then
            log.output ("obj EF ID:", hex.hexify(v.typeAttributes.path.efidOrPath))
        else
            log.output ("unknown efidOrPath_tag:", v.typeAttributes.path.efidOrPath_tag, hex.hexify(v.typeAttributes.path.efidOrPath))
            proceed = false
        end
        if proceed and v.typeAttributes.modulusLength then
            obj = GetSecretKeyTemplate(t.mt.get_secret_key)
            log.output ("SECRET key label:", v.commonObjectAttributes.label)
            log.output ("SECRET key iD:", v.classAttributes.iD)
            obj.userConsent = v.commonObjectAttributes.userConsent
            obj.asn1 = v
            obj.kid = v.classAttributes.keyReference
            obj.key_bits = v.typeAttributes.modulusLength
            
            local fid = hex.hexf("DA%B", tonumber("EF", 16) +  obj.kid) -- secret key files: DAF0 - DAFF
            obj.path = fid
            
            log.output("parsing key fid:", hex.hexify(obj.path))
            local pcRes, theErrorT pcall(function()
                local e_value = self:read_cached_file(obj.path, 0, -1, true)
                log.output ("e_value:", hex.hexify(e_value or ""))
                
                obj.value = aes.aes_decrypt_check(self._mk, e_value, "00000001")
                log.output ("value:", hex.hexify(obj.value or ""))
                
            end)
            
            if not pcRes then
                log.output ("parse secret key error:", debug.traceback(theErrorT))
            end
  
                
            obj.num = i
            objects.max_index = objects.max_index +1
            objects[ objects.max_index] = obj
            log.output(
                string.format("_add_objects(): added secret key: num:%d kid:%d bits:%d handle:%d, userConsent:%s", 
                    obj.num, obj.kid, obj.key_bits, objects.max_index, tostring(obj.userConsent))
                )

        else
            log.output ("secret key object discarded!")
        end
        
        if obj then
            decode_bool_attributes(v.classAttributes, obj)
            obj.private = true
            obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
            obj[CKA.LABEL] = v.commonObjectAttributes.label
            obj[CKA.ID] = v.classAttributes.iD
        end
    end
    
    
    local PrKDInfo = p15.parsePubPrivKD(PrKD)
    log.output ("adding private keys...")
    for i, v in PrKDInfo do
        local proceed = true
        for x, y in v do
            log.output ("\t", x, utility.repr(y))
        end
        log.output ("evaluating private key:", i)
        log.output ("efidOrPath:", v.typeAttributes.path.efidOrPath_tag, hex.hexify(v.typeAttributes.path.efidOrPath) )
        -- print ("efidOrPath:", hex.hexify(v.typeAttributes.path.efidOrPath), v.typeAttributes.path.efidOrPath_tag)
        -- print ("modulusLength:", v.typeAttributes.modulusLength)
        -- print ("userConsent:", v.commonObjectAttributes.userConsent)
        -- print ("keyReference:", v.classAttributes.keyReference)
        -- print ("label:", v.commonObjectAttributes.label)
        -- print ("iD:", v.classAttributes.iD)
        
        local obj
        local path
        if v.typeAttributes.path.efidOrPath_tag == der.STRING then
            log.output ("obj EF ID:", hex.hexify(v.typeAttributes.path.efidOrPath))
        else
            log.output ("unknown efidOrPath_tag:", v.typeAttributes.path.efidOrPath_tag, hex.hexify(v.typeAttributes.path.efidOrPath))
            proceed = false
        end
        if proceed and v.typeAttributes.modulusLength then
            obj = GetPrivKeyTemplate(t.mt.get_privkey)
            obj.path = path
            log.output ("RSA key label:", v.commonObjectAttributes.label)
            log.output ("RSA key iD:", v.classAttributes.iD)
            obj.userConsent = v.commonObjectAttributes.userConsent
            obj.asn1 = v
            obj.kid = v.classAttributes.keyReference
            obj.keyReference_pubkey = v.typeAttributes.path.efidOrPath
            obj.key_bits = v.typeAttributes.modulusLength
            obj[CKA.MODULUS_BITS] = obj.key_bits
            obj.num = i
            objects.max_index = objects.max_index +1
            objects[ objects.max_index] = obj
            log.output(
                string.format("_add_objects(): added private key: num:%d kid:%d bits:%d handle:%d, userConsent:%s", 
                    obj.num, obj.kid, obj.key_bits, objects.max_index, tostring(obj.userConsent))
                )
        elseif proceed and v.typeAttributes.parameters then
        
            local asciiOid = der.der_oid_to_ascii_oid(v.typeAttributes.parameters)
            log.output('_add_objects(): priv key: evaluating ECC oid:', asciiOid)
            local cka_key_type = CKK.ECDSA
            if Ed25519_curves_oids[asciiOid] then
                log.output('_add_objects(): priv key: found CKK.EC_EDWARDS:', asciiOid)
                cka_key_type = CKK.EC_EDWARDS
            end
        
            obj = GetECCPrivKeyTemplate(t.mt.get_ecc_privkey, cka_key_type)
            obj.path = path
            log.output ("ECC key label:", v.commonObjectAttributes.label)
            log.output ("ECC key iD:", v.classAttributes.iD)
            obj.userConsent = v.commonObjectAttributes.userConsent
            obj.asn1 = v
            obj.kid = v.classAttributes.keyReference
            obj.keyReference_pubkey = v.typeAttributes.path.efidOrPath
            obj.parameters = v.typeAttributes.parameters
            obj[CKA.EC_PARAMS] = obj.parameters
            obj.num = i
            obj.sk = t.mt.get_ecc_privkey
            objects.max_index = objects.max_index +1
            objects[ objects.max_index] = obj
            log.output(
                string.format("_add_objects(): added ECC private key: num:%d kid:%d EC_PARAMS:%s (%s) handle:%d, userConsent:%s", 
                    obj.num, obj.kid, hex.hexify(obj.parameters), der.der_oid_to_ascii_oid(obj.parameters), objects.max_index, tostring(obj.userConsent))
                )
        else
            log.output ("private key object discarded!")
        end
        
        if obj then
            decode_bool_attributes(v.classAttributes, obj)
            obj.private = true
            obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
            obj[CKA.LABEL] = v.commonObjectAttributes.label
            obj[CKA.ID] = v.classAttributes.iD
        end
    end
    
    local PubKDInfo = p15.parsePubPrivKD(PubKD)
    log.output ("adding public keys...")
    for i, v in PubKDInfo do
        local proceed = true
        for x, y in v do
            log.output ("\t", x, utility.repr(y))
        end
        log.output ("evaluating public key:", i)
        log.output ("efidOrPath:", v.typeAttributes.path.efidOrPath_tag, hex.hexify(v.typeAttributes.path.efidOrPath) )
        -- print ("efidOrPath:", hex.hexify(v.typeAttributes.path.efidOrPath), v.typeAttributes.path.efidOrPath_tag)
        -- print ("modulusLength:", v.typeAttributes.modulusLength)
        -- print ("userConsent:", v.commonObjectAttributes.userConsent)
        -- print ("keyReference:", v.classAttributes.keyReference)
        -- print ("label:", v.commonObjectAttributes.label)
        -- print ("iD:", v.classAttributes.iD)
        
        local obj
        local path
        if v.typeAttributes.path.efidOrPath_tag == der.STRING then
            log.output ("obj EF ID:", hex.hexify(v.typeAttributes.path.efidOrPath))
        else
            log.output ("unknown efidOrPath_tag:", v.typeAttributes.path.efidOrPath_tag, hex.hexify(v.typeAttributes.path.efidOrPath))
            proceed = false
        end
        if proceed and v.typeAttributes.modulusLength then
            obj = GetPubKeyTemplate(t.mt.get_pubkey)
            obj.path = path
            log.output ("RSA key label:", v.commonObjectAttributes.label)
            log.output ("RSA key iD:", v.classAttributes.iD)
            
            obj.asn1 = v
            obj.kid = v.classAttributes.keyReference
            obj.keyReference_pubkey = v.typeAttributes.path.efidOrPath
            obj.key_bits = v.typeAttributes.modulusLength
            obj[CKA.MODULUS_BITS] = obj.key_bits
            obj.num = i
            objects.max_index = objects.max_index +1
            objects[ objects.max_index] = obj
            log.output(
                string.format("_add_objects(): added RSA public key: num:%d kid:%d bits:%d handle:%d", 
                    obj.num, obj.kid, obj.key_bits, objects.max_index)
                )
        elseif proceed and v.typeAttributes.parameters then
        
            local asciiOid = der.der_oid_to_ascii_oid(v.typeAttributes.parameters)
            log.output('_add_objects(): pub key: evaluating ECC oid:', asciiOid)
            local cka_key_type = CKK.ECDSA
            if Ed25519_curves_oids[asciiOid] then
                log.output('_add_objects(): pub key: found CKK.EC_EDWARDS:', asciiOid)
                cka_key_type = CKK.EC_EDWARDS
            end
            
            obj = GetECCPubKeyTemplate(t.mt.get_ecc_pubkey, cka_key_type)
            obj.path = path
            log.output ("ECC key label:", v.commonObjectAttributes.label)
            log.output ("ECC key iD:", v.classAttributes.iD)
            
            obj.asn1 = v
            obj.kid = v.classAttributes.keyReference
            obj.parameters = v.typeAttributes.parameters
            obj.keyReference_pubkey = v.typeAttributes.path.efidOrPath
            obj[CKA.EC_PARAMS] = obj.parameters
            obj.num = i
            objects.max_index = objects.max_index +1
            objects[ objects.max_index] = obj
            log.output(
                string.format("_add_objects(): added ECC public key: num:%d kid:%d EC_PARAMS:%s (%s) handle:%d", 
                    obj.num, obj.kid, hex.hexify(obj.parameters), der.der_oid_to_ascii_oid(obj.parameters), objects.max_index)
                )
        else
            log.output ("public key object discarded: ", v.commonObjectAttributes.label)
        end
        if obj then
            decode_bool_attributes(v.classAttributes, obj)
            obj.private = false
            obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
            obj[CKA.LABEL] = v.commonObjectAttributes.label
            obj[CKA.ID] = v.classAttributes.iD
        end
    end
    
    -- local finfos = self.nxp_hcard:select(tonumber("7005", 16), true)
    -- log.output ("finfos 7005 certD:", util.repr(finfos))
    
    -- local certD = self.nxp_hcard:mread_binary_smart(0, finfos.size)
    
    
    
    local certDInfo = p15.parseCertDF(certD)
    log.output ("adding certificates...")
    for i, v in certDInfo do
        log.output ("evaluating cert:", i)
    
        log.output(string.format("cert %d path:", i), hex.hexify(certDInfo[i].typeAttributes.path.efidOrPath))

        for x, y in v do
            log.output ("\t", x, utility.repr(y))
        end
        
        local obj = GetCertTemplate(t.mt.get_certificate)
        obj.private = false
        obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
        
        log.output ("cert label:", v.commonObjectAttributes.label)
        log.output ("cert iD:", v.classAttributes.iD)
        
        obj[CKA.LABEL] = v.commonObjectAttributes.label
        obj[CKA.ID] = v.classAttributes.iD
        obj.path = certDInfo[i].typeAttributes.path.efidOrPath
        obj.num = i
        objects.max_index = objects.max_index +1
        objects[ objects.max_index] = obj
        log.output(
            string.format("_add_objects(): added certificate: num:%d , path=%s, handle:%d", 
                obj.num, hex.hexify(obj.path), objects.max_index)
            )
    end


    if self._indexes._data_objects_bin then
        log.output("adding data objects...")
        local d = p15.parsePubPrivDataD(self._indexes._data_objects_bin)
        for i, v in d do
            
            log.output(string.format("data object %d:", i))
            
            for x, y in v do
                log.output ("\t", x, utility.repr(y))
            end
            
            if not v.typeAttributes.path or type(v.typeAttributes.path.efidOrPath) ~= "string"
                or string.len(v.typeAttributes.path.efidOrPath) < 2 then
                
                log.output ("_add_objects(): jumping data object with invalid path!")
            else
                
                local fid =  string.sub(v.typeAttributes.path.efidOrPath, -2, -1)
                if fid == hex.hexf("DC00") or fid == hex.hexf("DC01") or fid == hex.hexf("DC02") then
                     log.output ("_add_objects(): jumping reserved FID:", hex.hexify(v.typeAttributes.path.efidOrPath))
                else
                    local obj = GetDataObjectTemplate(t.mt.get_data_object)

                    if v.commonObjectAttributes.flags then
                        p15.decode_CommonFlags(v.commonObjectAttributes.flags, obj)
                    else
                        log.output("_add_objects(): forcing data object as private")
                        obj[CKA.PRIVATE] = eCK.BBOOL(true)
                        obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
                    end
                    
                    obj.private = obj[CKA.PRIVATE] and obj[CKA.PRIVATE] ~= eCK.BBOOL(false)
                    log.output("_add_objects():data object is private:", obj.private)
                    
                    obj[CKA.LABEL] = v.commonObjectAttributes.label
                    obj[CKA.APPLICATION] = v.classAttributes.applicationName
                    obj[CKA.OBJECT_ID] = v.classAttributes.applicationOID

                    obj.path = v.typeAttributes.path.efidOrPath
                    obj.num = i
                    
                    objects.max_index = objects.max_index +1
                    objects[ objects.max_index] = obj
                    log.output(
                        string.format("_add_objects(): added data object: num:%d handle:%d", 
                            obj.num, objects.max_index)
                        )
               end
            end
        end
    end
    
    
    if self.is_cns then
        local info = self.info
        local wasSMActive = self.nxp_hcard.ActiveSM
        self.nxp_hcard:select_applet_cns(false)
        
        self.cns_info = {
            cert_valid      = false,
            key_valid       = false,
        }
        local path = CNS0_KEY_PATH
        local modulus = utility.cache_read(info.serialNumber, path .. "rmod", self._AvoidUseLastUpdate, self._umcachepath)
        local pubexp = utility.cache_read(info.serialNumber, path .. "rexp", self._AvoidUseLastUpdate, self._umcachepath)

        
        if type(modulus) == "string" and string.len(modulus) >= 128 and string.byte(modulus, 1) ~= 255 and string.byte(modulus, 1) ~= 0 then
 
            self.cns_info.modulus = modulus
            self.cns_info.pubexp = pubexp
            self.cns_info.key_valid = true
            
        end
        log.output('add_info_cns(): cache_read: VALUE: modulus=', hex.hexify(modulus or ""))
            
        if type(modulus) ~= "string" then
            log.output('add_info_cns(): no cache, reading pub key from card...')
            local pcRes, theErrorT = pcall (function()
                modulus, pubexp = self.cns_hcard:read_public_key(path)
            end)
            if not pcRes then
                log.output('add_info_cns(): read_public_key() error:', theErrorT)
            end
            self.cns_info.key_valid = type(modulus) == "string" and string.len(modulus) > 0 
                                        and string.byte(modulus, 1) ~= 255 and string.byte(modulus, 1) ~= 0
            
            
            if self.cns_info.key_valid then
                self.cns_info.modulus = modulus
                self.cns_info.pubexp = pubexp
                log.output('add_info_cns(): fresh: VALUE (FULL): modulus=', hex.hexify(modulus or ""))
            end
            if self:cache_enabled() and info then
                utility.cache_write(info.serialNumber, path .. "rmod", modulus or "", self._umcachepath)
                utility.cache_write(info.serialNumber, path .. "rexp", pubexp or "", self._umcachepath)
                
            end
        end
        
        if self.cns_info.key_valid then
        
            local obj = GetPrivKeyTemplate()
            
            obj.iscns = true
            obj.path = path
            obj.kid = 1
            obj.private = true
            obj.key_bits = 1024
            obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
            obj[CKA.ID] = CNS0_ID
            obj[CKA.LABEL] = obj[CKA.ID]
            obj[CKA.MODULUS] = self.cns_info.modulus
            obj[CKA.MODULUS_BITS] = 1024
            obj[CKA.PUBLIC_EXPONENT] = self.cns_info.pubexp
            obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
            obj[CKA.SIGN] = eCK.BBOOL(true)
            obj[CKA.SIGN_RECOVER] = eCK.BBOOL(false)
            obj[CKA.VERIFY] = eCK.BBOOL(false)
            obj[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
            obj[CKA.UNWRAP] = eCK.BBOOL(false)
            obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)

            
            objects.max_index = objects.max_index +1
            objects[ objects.max_index] = obj
            log.output(
                string.format("_add_objects(): added CNS private key: path=%s, handle:%d", 
                    hex.hexify(obj.path), objects.max_index)
                )
                
            obj = GetPubKeyTemplate()
            obj.iscns = true
            obj.path = path
            obj.private = false
            obj.key_bits = 1024
            obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
            obj[CKA.ID] = CNS0_ID
            obj[CKA.LABEL] = obj[CKA.ID]
            obj[CKA.MODULUS] = self.cns_info.modulus
            obj[CKA.PUBLIC_EXPONENT] = self.cns_info.pubexp
            obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
            obj[CKA.VERIFY] = eCK.BBOOL(true)
            obj[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
            obj[CKA.ENCRYPT] = eCK.BBOOL(true)
            obj[CKA.WRAP] = eCK.BBOOL(false)
            obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
            
            objects.max_index = objects.max_index +1
            objects[ objects.max_index] = obj
            log.output(
                string.format("_add_objects(): added CNS pub key: path=%s, handle:%d", 
                    hex.hexify(obj.path), objects.max_index)
                )
            self.cns_info.pub_key_handle = objects.max_index
        end
            
        local path = CNS0_CERT_PATH
        pcall (function()
            local certVal
            if self:cache_enabled() then
                log.output("CNS certificate: trying cache...")
                certVal = utility.cache_read(info.serialNumber, path, self._AvoidUseLastUpdate, self._umcachepath)
                
            end
            
            if not certVal then
                log.output("CNS certificate: read from card...")
                pcall(function()
                    certVal = self.cns_hcard:read_x509_certificate(path)
                end)
                utility.cache_write(info.serialNumber, path, certVal or "", self._umcachepath)
            end
            
            self.cns_info.cert_valid = type(certVal) == "string" and string.len(certVal) > 0 and (string.byte(certVal, 1) == 48) -- hex 30
            self.cns_info.certVal = certVal
            
            if self.cns_info.cert_valid then
            
                local parsed_cer = der.parse_x509cer(certVal)
                local obj = GetCertTemplate()
                obj.iscns = true
                obj.path = path
                obj.private = false
                obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
                obj[CKA.ID] = CNS0_ID
                obj[CKA.LABEL] = obj[CKA.ID]
                obj[CKA.VALUE] = certVal
                obj[CKA.SUBJECT] = (parsed_cer and parsed_cer.subject) or ''
                obj[CKA.ISSUER] = (parsed_cer and parsed_cer.issuer) or ''
                obj[CKA.SERIAL_NUMBER] = (parsed_cer and parsed_cer.serialNumber) or ''
                obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
                obj[CKA.TRUSTED]    = eCK.BBOOL(false)
                
                objects.max_index = objects.max_index +1
                objects[ objects.max_index] = obj
                log.output(
                    string.format("_add_objects(): added CNS certificate: path=%s, handle:%d", 
                        hex.hexify(obj.path), objects.max_index)
                    )
            end
        end)
            
        pcall (function()
        
            local dataVal
            local path = CNS0_PDATA_PATH
            if self:cache_enabled() then
                log.output("CNS PDATA: trying cache...")
                dataVal = utility.cache_read(info.serialNumber, path, self._AvoidUseLastUpdate, self._umcachepath)
                
            end
            
            if not dataVal then
                log.output("CNS PDATA: read from card...")
                -- pcall(function()
                    local finfo = self.cns_hcard:select(path, true)
                    dataVal = self.cns_hcard:mread_binary(0, fInfo and fInfo.size or 400)
                -- end)
                utility.cache_write(info.serialNumber, path, dataVal or "", self._umcachepath)
            end
            
            local dataValB = string.byte(dataVal, 1)
            self.cns_info.pdata_valid = (dataValB ~= 255 and dataValB ~= 0)
            
            if self.cns_info.pdata_valid then
                    local obj = GetDataObjectTemplate()

                    log.output("_add_objects(): adding CNS PDATA")
                    obj[CKA.PRIVATE] = eCK.BBOOL(false)
                    obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
                    obj.private = false

                    obj[CKA.LABEL] = "PDATA"
                    obj[CKA.APPLICATION] = "PDATA"
                    obj[CKA.OBJECT_ID] = "PDATA"
                    obj[CKA.VALUE] = dataVal

                    obj.path = CNS0_PDATA_PATH
                    obj.iscns = true
                    
                    objects.max_index = objects.max_index +1
                    objects[ objects.max_index] = obj
                    log.output(
                        string.format("_add_objects(): added data object: num:%d handle:%d", 
                            obj.num, objects.max_index)
                        )
            end
        end)
        
        log.output('add_info_cns(): certificate valid:', self.cns_info.cert_valid)
        log.output('add_info_cns(): pdata valid:', self.cns_info.pdata_valid)

        
        
        self.nxp_hcard:select_applet(false)
        if wasSMActive then
            self.nxp_hcard:perform_mutual_authenticate()
        end
    end
end

function t.mt:get_objects()
    log.output('token-nxp-chipdoc-lite:get_objects()')
    
    self.nxp_hcard:auto_perform_mutual_authenticate(true) -- check/restore Generic SM session, checkOnActiveSMOnly
    local info = self:get_info() -- carica le info sul filesystem in cache
    
    local objects = {
            min_index = 11001, -- primo indice disponibile
            max_index = 11000, -- valore dell'indice massimo (i valori intermedi possono anche essere nil)
        }

    self:_add_objects(objects)

    return objects
end

function t.mt:get_attribute_value(hobj, attr, onlysize)
    if onlysize==nil then onlysize = false end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj == nil then return CKR.OBJECT_HANDLE_INVALID end
    local result = obj[attr]
    if result == nil then
        log.output('get_attribute_value(): object', hobj, 'doesn\'t define sepcified attribute', attr)
        return CKR.ATTRIBUTE_TYPE_INVALID 
    end
    if type(result)=='function' then
        local rv
            log.output('get_attribute_value(): attr value is a "function", calling...')
        rv, result = result(self, hobj, attr, onlysize)
        if type(result)=='function' then
            log.output('get_attribute_value(): WARNING: specified attr value still "function", was not populated! Returning empty value...')
            result = "" 
        end
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


function t.mt:get_object_size(hobj)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj == nil then return CKR.OBJECT_HANDLE_INVALID end
    local oSize = -1

    if obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        if type(obj[CKA.VALUE]) == "function" then
            obj[CKA.VALUE](self, hobj, CKA.VALUE, false)
        end
        oSize = (obj[CKA.VALUE] and string.len(obj[CKA.VALUE])) or -1
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        oSize = 130*4
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        oSize = 130*4
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        if type(obj[CKA.VALUE]) == "function" then
            obj[CKA.VALUE](self, hobj, CKA.VALUE, false)
        end
        oSize = (obj[CKA.VALUE] and string.len(obj[CKA.VALUE])) or -1
    end

    return CKR.OK, oSize
end



function t.mt:valid()
    local rv = self.nxp_hcard:valid()
    if not rv then
        utility.forget_token_changed(self, "cache")
    end
    return rv
end


function t.mt:flush_cache()
    if self.cfg["xproc"] ~= "true" then
        return false
    end
    local changed, cache_id
    if self._cache_id == nil then
        changed, self._cache_id = utility.has_token_changed(self, "cache", 0)
        log.output("token-nxp-chipdoc-lite:flush_cache(): initialize: _cache_id:", self._cache_id)
    end
    changed, cache_id = utility.has_token_changed(self, "cache", self._cache_id)
    if changed then
        log.output("token-nxp-chipdoc-lite:flush_cache(): token has changed!")
        self._cache_id = cache_id
        self.info = nil -- rimuove cache oggetti
        self._indexes = nil
        self.attributes = nil
        
        log.output("token-nxp-chipdoc-lite:flush_cache(): rebuilding object's cache")
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





---------------------------------------------
---- write FS
---------------------------------------------



function t.mt:_write_file(data, file, index)
    local relative = string.len(file) == 2
    index = index or 0
    self.nxp_hcard:select(file, relative)  -- fid, relative, sm
    log.output("WOULD WRITE to file:", hex.hexify(file), "@", index)
    log.output("DATA:", hex.hexify(data or ''))
    if not self._readonly_test then
        local pcRes, theErrorT = pcall(function()
            self.nxp_hcard:mupdate_binary(index, data)
        end)
        
        if not pcRes then
            log.output('token-nxp-chipdoc-lite:_write_file(): ERROR:', debug.traceback(theErrorT) )
            
            if self.nxp_hcard.last_sw == hex.hexf("6982")  and self.userType == CKU.USER 
                        and self.cached_main_pin then

                log.output('token-nxp-chipdoc-lite:_write_file(): restoring secure channel and verifying pin...')
                self.nxp_hcard:auto_perform_mutual_authenticate(true)
                self.nxp_hcard:select_MF()
                if self.cached_main_pin then
                    self.nxp_hcard:verify_pin_main(self.cached_main_pin, false) -- pin, ispuk
                end
                self.nxp_hcard:select_Generic()
                
                log.output('token-nxp-chipdoc-lite:_write_file(): retry write...')
                self.nxp_hcard:select(file, relative)  -- fid, relative, sm
                self.nxp_hcard:mupdate_binary(index, data)
            else
                error(theErrorT)
            end
        end
        
    end
end

function t.mt:is_ds(pTemplate)
    return string.sub(pTemplate[CKA.ID] or '', 1, 2) == "DS"
        or string.sub(pTemplate[CKA.LABEL] or '', 1, 2) == "DS"
        or string.sub(pTemplate[CKA.ID] or '', 1, 3) == "DX#"
        or string.sub(pTemplate[CKA.LABEL] or '', 1, 3) == "DX#"
        or string.sub(pTemplate[CKA.ID] or '', 1, 5) == "Firma"
        or string.sub(pTemplate[CKA.LABEL] or '', 1, 5) == "Firma"
end


function t.mt:virtual_alloc_kid(dataPriv)
    log.output("token-nxp-chipdoc-lite:virtual_alloc_kid:")
    
    local minId = 16
    local maxId = 63
    
    local usedIds = {}
    local kdPriv = dataPriv and p15.parsePubPrivKD(dataPriv) or {}
    for i=minId,maxId do
        usedIds[i] = true
    end
    
    for i, v in kdPriv do
        local cur = v.classAttributes.keyReference
        log.output("token-nxp-chipdoc-lite:virtual_alloc_kid: kdPriv already used keyReference:", cur)
        usedIds[cur] = nil
    end
    
    for i=minId,maxId do
        if usedIds[i] then
            log.output("token-nxp-chipdoc-lite:virtual_alloc_kid: found free keyReference:", i)
            return i
        end
    end
    
    return nil
end


function t.mt:virtual_alloc_pubkey_file(data)
    log.output("token-nxp-chipdoc-lite:virtual_alloc_pubkey_file()")
    
    local min1 = tonumber("DF81", 16)
    local max1 = tonumber("DFAF", 16)

    local certIds = {}
    local kd = data and p15.parsePubPrivKD(data) or {}
    local id
    for i=min1,max1 do
        id = hex.hexf("%>%H", i)
        certIds[id] = true
    end

    for i, v in kd do
        local cur = v.typeAttributes.path and v.typeAttributes.path.efidOrPath
        log.output("token-nxp-chipdoc-lite:virtual_alloc_pubkey_file(): file alreay in use:", hex.hexify(cur or ""))
        if cur and certIds[cur] then
            log.output("token-nxp-chipdoc-lite:virtual_alloc_pubkey_file(): file removed from available list:", hex.hexify(cur))
            certIds[cur] =  nil
        end
        
    end
    
    for i=min1,max1 do
        id = hex.hexf("%>%H", i)
        if certIds[id] then
            log.output("token-nxp-chipdoc-lite:virtual_alloc_pubkey_file: found free pub key file:", hex.hexify(id))
            return id
        end
    end
    
    return nil
end


function t.mt:virtual_alloc_kid_secret_key(kd)
    log.output("token-nxp-chipdoc-lite:virtual_alloc_kid_secret_key")
    
    local min1 = 1
    local max1 = 16
    
    local usedIds = {}
    local kdPriv = p15.parsePubPrivKD(kd)
    for i=min1,max1 do
        usedIds[i] = true
    end
    
    for i, v in kdPriv do
        local cur = v.classAttributes.keyReference
        usedIds[cur] = nil
    end
    
    
    for i=min1,max1 do
        if usedIds[i] then
            log.output("token-nxp-chipdoc-lite:virtual_alloc_kid_secret_key: found free keyReference:", i)
            return i
        end
    end
    
    return nil
end

function t.mt:is_keyReference_pubkey_in_use(data, keyReference_pubkey)
    log.output("token-nxp-chipdoc-lite:is_keyReference_pubkey_in_use: keyReference_pubkey", hex.hexify(keyReference_pubkey))
    local kd = p15.parsePubPrivKD(data)
    local inUse = false
    
    for i, v in kd do
        local cur = v.typeAttributes.path.efidOrPath
        if cur == keyReference_pubkey then
            log.output("token-nxp-chipdoc-lite:is_keyReference_pubkey_in_use: in use keyReference_pubkey:", hex.hexify(keyReference_pubkey))
            inUse=true
            break
        end
    end    
    return inUse
end



function t.mt:virtual_alloc_cert_file(data)
    log.output("token-nxp-chipdoc-lite:virtual_alloc_cert_file()")
    
    local min1 = 1
    local max1 = tonumber("1E", 16)

    local certIds = {}
    local kd = p15.parseCertDF(data)
    local id
    for i=min1,max1 do
        id = hex.hexf("%>%H", i)
        certIds[id] = true
    end

    for i, v in kd do
        local cur = v.typeAttributes.path and v.typeAttributes.path.efidOrPath
        log.output("token-nxp-chipdoc-lite:virtual_alloc_cert_file(): file alreay in use:", hex.hexify(cur or ""))
        if cur and certIds[cur] then
            log.output("token-nxp-chipdoc-lite:virtual_alloc_cert_file(): file removed from available list:", hex.hexify(cur))
            certIds[cur] =  nil
        end
        
    end
    
    for i=min1,max1 do
        id = hex.hexf("%>%H", i)
        if certIds[id] then
            log.output("token-nxp-chipdoc-lite:virtual_alloc_cert_file: found free cert file:", hex.hexify(id))
            return id
        end
    end
    
    return nil
end

function t.mt:virtual_alloc_data_file(data)
    log.output("token-nxp-chipdoc-lite:virtual_alloc_data_file()")
    
    local min1 = 4
    local max1 = tonumber("7F", 16)

    local dataIds = {}
    local kd = p15.parsePubPrivDataD(data)
    local id
    for i=min1,max1 do
        id = hex.hexf("DC%B", i)
        dataIds[id] = true
    end

    for i, v in kd do
        local cur = v.typeAttributes.path and v.typeAttributes.path.efidOrPath
        log.output("token-nxp-chipdoc-lite:virtual_alloc_data_file(): file alreay in use:", hex.hexify(cur or ""))
        if cur and dataIds[cur] then
            log.output("token-nxp-chipdoc-lite:virtual_alloc_data_file(): file removed from available list:", hex.hexify(cur))
            dataIds[cur] =  nil
        end
        
    end
    
    for i=min1,max1 do
        id = hex.hexf("DC%B", i)
        if dataIds[id] then
            log.output("token-nxp-chipdoc-lite:virtual_alloc_data_file: found free data file:", hex.hexify(id))
            return id
        end
    end
    
    return nil
end


-- local function make_accessControlRules_key(SE_ID) -- SE_ID: number, Security Environment ID (?)
    -- local sdo_rule1 = hex.hexf("030204200201%B", SE_ID)
    -- local sdo_rule2 = hex.hexf("030204A00201%B", SE_ID)
    -- local accessControlRules = 
    -- {
        -- {
            -- accessMode=hex.hexf("058000"),  -- READ (bit 0) 30 07 03 03 05 80 00 05 00 -> 10000000000
            -- accessMode_tag=der.BIT_STRING,
            -- securityCondition="",
            -- securityCondition_tag=der.NULL
        -- },
        -- {
            -- accessMode=hex.hexf("054000"),  -- UPDATE (bit 1) 30 0E 03 03 05 40 00 30 07 03 02 04 A0 02 01 03 -> 01000000000
            -- accessMode_tag=der.BIT_STRING,
            -- securityCondition=sdo_rule2,
            -- securityCondition_tag=der.SEQUENCE
        -- },
        -- {
            -- accessMode=hex.hexf("051000"),  -- DELETE (bit 3) 30 0E 03 03 05 10 00 30 07 03 02 04 20 02 01 03 -> 00010000000
            -- accessMode_tag=der.BIT_STRING,
            -- securityCondition=sdo_rule1,
            -- securityCondition_tag=der.SEQUENCE
        -- },
        -- {
            -- accessMode=hex.hexf("052000"), -- EXECUTE (bit 2) 30 0E 03 03 05 20 00 30 07 03 02 04 20 02 01 03 -> 00100000000
            -- accessMode_tag=der.BIT_STRING,
            -- securityCondition=sdo_rule1,
            -- securityCondition_tag=der.SEQUENCE
        -- },
        -- {
            -- accessMode=hex.hexf("050400"),  -- UNKNOWN (bit 5) 30 0E 03 03 05 04 00 30 07 03 02 04 20 02 01 03 -> 00000100000
            -- accessMode_tag=der.BIT_STRING,
            -- securityCondition=sdo_rule1,
            -- securityCondition_tag=der.SEQUENCE
        -- },
        -- {
            -- accessMode=hex.hexf("050040"), -- UNKNOWN (bit 9) 30 0E 03 03 05 00 40 30 07 03 02 04 20 02 01 03  -> 00000000010
            -- accessMode_tag=der.BIT_STRING,
            -- securityCondition=sdo_rule1,
            -- securityCondition_tag=der.SEQUENCE
        -- },
        -- {
            -- accessMode=hex.hexf("050100"), -- UNKNOWN (bit 7) 30 0E 03 03 05 01 00 30 07 03 02 04 20 02 01 03 -> 00000001000
            -- accessMode_tag=der.BIT_STRING,
            -- securityCondition=sdo_rule1,
            -- securityCondition_tag=der.SEQUENCE
        -- },
    -- }
    -- return accessControlRules
-- end

 
-- local function make_accessControlRules_cert(SE_ID) -- SE_ID: number, Security Environment ID (?)
    -- local sdo_rule1 = hex.hexf("030204200201%B", SE_ID)
    -- local accessControlRules = 
    -- {
        -- {
            -- accessMode=hex.hexf("058000"),  -- READ (bit 0) 30 07 03 03 05 80 00 05 00 -> 10000000000
            -- accessMode_tag=der.BIT_STRING,
            -- securityCondition="",
            -- securityCondition_tag=der.NULL
        -- },
        -- {
            -- accessMode=hex.hexf("054000"),  -- UPDATE (bit 1) 30 0E 03 03 05 40 00 30 07 03 02 04 20 02 01 03 -> 01000000000
            -- accessMode_tag=der.BIT_STRING,
            -- securityCondition=sdo_rule1,
            -- securityCondition_tag=der.SEQUENCE
        -- },
        -- {
            -- accessMode=hex.hexf("051000"),  -- DELETE (bit 3) 30 0E 03 03 05 10 00 30 07 03 02 04 20 02 01 03 -> 00010000000
            -- accessMode_tag=der.BIT_STRING,
            -- securityCondition=sdo_rule1,
            -- securityCondition_tag=der.SEQUENCE
        -- },
    -- }
    -- return accessControlRules
-- end


function t.mt:virtual_add_private_key_object(
    data, label, id, authId, keyReference, modulusLength,
        isDS,
        efidOrPath,
        objTemplate
    )
    local usage = objTemplate and p15.encode_KeyUsageFlags(objTemplate) or "\002\116" -- unused:2, 0x74: decipher, sign, signRecover, keyDecipher
    local accessFlags = objTemplate and p15.encode_KeyAccessFlags(objTemplate) or "\004\176" -- 04 B0: unused bits: 06, value: 40 (sconosciuto)
    local fs = p15.parsePubPrivKD(data)
    local isECC = objTemplate[CKA.KEY_TYPE] == eCK.ULONG(CKK.ECDSA)
        or objTemplate[CKA.KEY_TYPE] == eCK.ULONG(CKK.EC_EDWARDS)
    
    local v = {
        commonObjectAttributes={
            label=label,
            flags="\006\192", -- unused bits:6, 0xC0: private + modifiable
            authId=authId,
            userConsent=isDS and 1 or nil,
            --accessControlRules=make_accessControlRules_key(self.nxp_hcard.ID_PIN)
            },
        classAttributes={
            iD=id,
            usage = usage,
            accessFlags = accessFlags,
            keyReference = keyReference,
        },
        typeAttributes={
            path={efidOrPath=efidOrPath or hex.hexf("%>%H", keyReference) },
        }
    }
    if isECC then
        v.typeAttributes.parameters=objTemplate[CKA.EC_PARAMS]
    else
        v.typeAttributes.modulusLength=modulusLength
    end

    table.insert(fs, v)
    local fsB = p15.buildPubPrivKD(fs, {subClassAttributes={}})
    fsB = fsB .. string.rep("\000", string.len(data) - string.len(fsB))
    return fsB, table.getn(fs)
end

function t.mt:virtual_add_public_key_object(data, label, id, keyReference, modulusLength, isDS, efidOrPath, objTemplate)
    local fs = p15.parsePubPrivKD(data)
    local usage = objTemplate and p15.encode_KeyUsageFlags(objTemplate) or "\000\139" -- unused 0, 0x8B: encipher, keyEncipher, verify, verifyRecover
    local accessFlags = objTemplate and p15.encode_KeyAccessFlags(objTemplate) or "\006\064" -- unused: 06, 0x40: extractable
    local isECC = objTemplate[CKA.KEY_TYPE] == eCK.ULONG(CKK.ECDSA)
        or objTemplate[CKA.KEY_TYPE] == eCK.ULONG(CKK.EC_EDWARDS)
        
    local v = {
        commonObjectAttributes={
            label=label,
            flags="\006\064", -- unused: 06, 0x40: modifiable
            userConsent=isDS and 1 or nil,
            --accessControlRules=make_accessControlRules_key(self.nxp_hcard.ID_PIN)
            },
        classAttributes={
            iD=id,
            usage = usage,
            accessFlags = accessFlags,
            keyReference = keyReference,
        },
        subClassAttributes={
            tag=der.CONTEXT(0),
            value=hex.hexf("3007A0050303070000"), -- [0]subClassAttributes -> [0]trustedUsage=0
        },
        typeAttributes={
            path={efidOrPath=efidOrPath or hex.hexf("%>%H", keyReference) },
        }
    }
    if isECC then
        v.typeAttributes.parameters=objTemplate[CKA.EC_PARAMS]
    else
        v.typeAttributes.modulusLength=modulusLength
    end
    
    
    table.insert(fs, v)
    local fsB = p15.buildPubPrivKD(fs, {subClassAttributes={}}) 
    fsB = fsB .. string.rep("\000", string.len(data) - string.len(fsB))
    return fsB, table.getn(fs)
end


function t.mt:virtual_add_cert_object(data, label, id, file, parsed_cer)
    local cert_is_ca = parsed_cer and (parsed_cer.basicConstraints and parsed_cer.basicConstraints.ca)
    local subject = parsed_cer and parsed_cer.subject
    local subject_tag
    local issuer = parsed_cer and parsed_cer.issuer
    local serialNumber = parsed_cer and parsed_cer.serialNumber
    
    -- print ("subject:", hex.hexify(subject or ""))
    -- print ("issuer:", hex.hexify(issuer or ""))
    -- print ("serialNumber:", hex.hexify(serialNumber or ""))
    
    if subject then
        local subjectD = der.parse(subject)
        if subjectD and subjectD[1] and subjectD[1].value then
            subject = subjectD[1].value
            subject_tag = subjectD[1].tag
        end
    end
    
    local fs = p15.parseCertDF(data)
    local v = {
        commonObjectAttributes={
            label=label,
            flags="\006\064", -- unused: 06, 0x40: modifiable
            -- accessControlRules=make_accessControlRules_cert(self.nxp_hcard.ID_PIN),
            },
        classAttributes={
            iD=id,
            authority = cert_is_ca and "\255" or "\0",
            authority_tag = der.BOOLEAN,
        },
        typeAttributes={
            path={efidOrPath=file},
            -- subject=subject,
            -- subject_tag=subject_tag,    -- subject is included "as is", so we shall pass as tag&value (default tag should be der.SEQUENCE)
            -- issuer=issuer,              -- issuer is encapsulated in CONTEXT(0)
            -- serialNumber=serialNumber,  -- serialNumber will be included inside a der.INTEGER, so we just pass value
        }
    }
    table.insert(fs, v)
    local fsB = p15.buildCertDF(fs)
    fsB = fsB .. string.rep("\000", string.len(data) - string.len(fsB))
    return fsB, table.getn(fs)
end


function t.mt:virtual_add_data_object(data, template, label, applicationName, applicationOID, file)

    local fs = p15.parsePubPrivDataD(data)
    local v = {
        commonObjectAttributes={
            label=label,
            flags=p15.encode_CommonFlags(template), -- unused: 06, 0x40: modifiable
            -- accessControlRules=make_accessControlRules_cert(self.nxp_hcard.ID_PIN),
            },
        classAttributes={
            applicationName=applicationName,
            applicationOID=applicationOID,
        },
        typeAttributes={
            path={efidOrPath=file},
        }
    }
    table.insert(fs, v)
    local fsB = p15.buildPubPrivDataD(fs)
    fsB = fsB .. string.rep("\000", string.len(data) - string.len(fsB))
    return fsB, table.getn(fs)
end



function t.mt:create_object_pubkey(pTemplateOrig, keyReference_pubkey, as_local, isDS)
    log.output('token-nxp-chipdoc-lite:create_object_pubkey():', pTemplateOrig, "as_local:", as_local, "keyReference_pubkey:", hex.hexify(keyReference_pubkey or ""))
    
    -- keyReference_pubkey: quando specificato crea una chiave pubblica associata ad una chiave privata
    local pTemplate = utility.clone_table(pTemplateOrig)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local do_import_pubkey
    local obj
    if not pTemplate[CKA.MODULUS] then
        log.output('token-nxp-chipdoc-lite:create_object_pubkey(): MODULUS or PUBLIC_EXPONENT not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    pTemplate[CKA.PUBLIC_EXPONENT] = pTemplate[CKA.PUBLIC_EXPONENT] or hex.hexf("010001")
    
    if string.len(pTemplate[CKA.PUBLIC_EXPONENT]) > 4 then
        log.output('token-nxp-chipdoc-lite:create_object_pubkey(): PUBLIC_EXPONENT too long!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    local modulus_bits = string.len(pTemplate[CKA.MODULUS]) * 8
    if not (modulus_bits == 1024 or modulus_bits == 2048 
            or (self._supports_4096 and modulus_bits == 4096) 
            or (self._supports_3072 and modulus_bits == 3072)) then
        log.output('token-nxp-chipdoc-lite:create_object_pubkey(): MODULUS size invalid:', modulus_bits)
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    if isDS == nil then
        isDS = self:is_ds(pTemplate) 
    end
    log.output('token-nxp-chipdoc-lite:create_object_pubkey(): isDS:', isDS)
     
        
    if self.is_cns and (pTemplate[CKA.ID] == CNS0_ID or pTemplate[CKA.LABEL] == CNS0_ID) 
            and modulus_bits == 1024 then
        -- self.cns_info.pub_key_handle e' impostato quando e' stata importata la chiave privata
        if self.cns_info.pub_key_handle then
            log.output('create_object_pubkey(): CNS Public Key already exists, returning existing key HANDLE', 
                        self.cns_info.pub_key_handle)
            return CKR.OK, self.cns_info.pub_key_handle
        else
            log.output('create_object_pubkey(): CNS Public Key cannot be imported before private key')
            return CKR.DEVICE_MEMORY
        end   
    end
    
    obj = GetPubKeyTemplate(t.mt.get_pubkey)
    obj.private = false
    obj.key_bits = modulus_bits
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] and type(pTemplate[k]) == 'string' then
            obj[k] = pTemplate[k]
        end
    end
    obj[CKA.LOCAL] = eCK.BBOOL(as_local)

    if not keyReference_pubkey then
        local hObj
        if self.userType == CKU.USER then
            log.output('token-nxp-chipdoc-lite:create_object_pubkey(): user logged in: searching if a private key sharing same modulus exists...')
            hObj = self:_search_related_key_object(
                pTemplate[CKA.MODULUS],
                pTemplate[CKA.PUBLIC_EXPONENT],
                eCK.ULONG(CKO.PRIVATE_KEY) )
        else
            log.output('token-nxp-chipdoc-lite:create_object_pubkey(): user NOT logged in: unable to search a private key sharing same modulus...')
        end
        if hObj then
            local objPriv = self.attributes[hObj]

            keyReference_pubkey = objPriv.keyReference_pubkey
            log.output('token-nxp-chipdoc-lite:create_object_pubkey(): found related key keyReference_pubkey:', hex.hexify(keyReference_pubkey or ""))

        end
         
        if not keyReference_pubkey then
            log.output('token-nxp-chipdoc-lite:create_object_pubkey(): allocating a keyReference_pubkey for public key')
            keyReference_pubkey = self:virtual_alloc_pubkey_file(self._indexes._private_keys_bin)
            if not keyReference_pubkey then
                log.output('token-nxp-chipdoc-lite:create_object_pubkey(): no more keys left in unused space file!')
                return CKR.DEVICE_MEMORY
            end
            do_import_pubkey = true
        end
    end
    
    self:invalidate_xproc_cache()
    -- self.nxp_hcard:auto_perform_mutual_authenticate()
    self.nxp_hcard:select_MF()
    local info = self:get_info()
    self.nxp_hcard:select_Generic()

    local label = pTemplate[CKA.LABEL] or ''
    local id = pTemplate[CKA.ID] or ''
    local modulusLength = modulus_bits
    local keyReference_pubkey_num = bin.unpack("%>%H", keyReference_pubkey)
    
    local pubKDBin, objNum = self:virtual_add_public_key_object(
                                self._indexes._public_keys_bin,
                                label,
                                id,
                                keyReference_pubkey_num,
                                obj.key_bits,
                                isDS,
                                keyReference_pubkey,
                                pTemplateOrig
                                )
    if string.len(pubKDBin) ~= string.len(self._indexes._public_keys_bin) then
        log.output('token-nxp-chipdoc-lite:create_object_pubkey(): no more space left in Public KD file!')
        return CKR.DEVICE_MEMORY
    end
    obj.num = objNum
    obj.keyReference_pubkey = keyReference_pubkey

    log.output(string.format("token-nxp-chipdoc-lite:create_object_pubkey(): new obj num:%d bits:%d", 
        obj.num, obj.key_bits) )

    if do_import_pubkey then
        -- self.nxp_hcard:select_Generic()
        local pubExp = pTemplate[CKA.PUBLIC_EXPONENT]
        
        pubExp = string.rep("\0", 4 - string.len(pubExp)) .. pubExp
        
        self.nxp_hcard:delete_file(keyReference_pubkey)
        
        self.nxp_hcard:create_binary_file(keyReference_pubkey, 
                string.len(pubExp .. pTemplate[CKA.MODULUS]),
                NXPChipDocLite.AC_ALWAYS,
                NXPChipDocLite.AC_ALWAYS,
                NXPChipDocLite.AC_ALWAYS
            )
        self.nxp_hcard:mupdate_binary(0, pubExp .. pTemplate[CKA.MODULUS])
    end
    
    log.output('token-nxp-chipdoc-lite:create_object_pubkey(): writing public key objects directory...')
    self:_write_file(pubKDBin, self.files.PubKD)
    self._indexes._public_keys_bin = pubKDBin
    
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    
    log.output('token-nxp-chipdoc-lite:create_object_pubkey(): CKR.OK, hPub=', self.attributes.max_index)
    return CKR.OK, self.attributes.max_index
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

function t.mt:_search_related_key_object(modulus, pubExp, class)
    -- verifica se un oggetto simile esiste gia'
    log.output('_search_related_key_object(): looking for existing related object...')
    local hObj
    local find_state = {}
    local pTemplateSearchRSA = {
        [CKA.MODULUS]=modulus,
        [CKA.PUBLIC_EXPONENT]=pubExp,
        [CKA.CLASS]=class,
    }
    local pTemplateSearchECC = {
        [CKA.EC_POINT]=modulus,
        [CKA.CLASS]=class,
    }
    local pTemplateSearch = pTemplateSearchRSA
    if modulus and not pubExp then
        pTemplateSearch = pTemplateSearchECC
    end
    hObj = self:get_item(find_state, true, pTemplateSearch) -- can return private objects
    if hObj ~= 0 then
        log.output('_search_related_key_object(): existing related object found:', hObj)
        return hObj
    end
    return nil
end

function t.mt:update_append_record_cns(path, num, val)
    -- checks if a record already exists and if so uses update instead of append
    self.cns_hcard:select(path)
    local rec
    local res, theErrorT = pcall(function()
        rec = self.cns_hcard:read_record(num, 4, 3)
    end
    )
    if res and rec then
        self.cns_hcard:update_record(num, 4, val)
    else
        self.cns_hcard:append_record(val)
    end
end

function t.mt:create_object_privkey(pTemplateOrig)
    log.output('token-nxp-chipdoc-lite:create_object_privkey()', pTemplateOrig)
    
    local pTemplate = utility.clone_table(pTemplateOrig)
    pTemplate[CKA.LOCAL] = eCK.BBOOL(false)
    
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    if not pTemplate[CKA.MODULUS]
        or not pTemplate[CKA.PUBLIC_EXPONENT] 
        -- or not pTemplate[CKA.PRIVATE_EXPONENT] -- non usato
        or not pTemplate[CKA.PRIME_1]
        or not pTemplate[CKA.PRIME_2]
        or not pTemplate[CKA.EXPONENT_1]
        or not pTemplate[CKA.EXPONENT_2]
        or not pTemplate[CKA.COEFFICIENT]
        then
            log.output('token-nxp-chipdoc-lite:create_object_privkey(): all Private Key components must be specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    if string.len(pTemplate[CKA.PUBLIC_EXPONENT]) > 4 then
        log.output('token-nxp-chipdoc-lite:create_object_privkey(): PUBLIC_EXPONENT too long!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    local modulus_bits = string.len(pTemplate[CKA.MODULUS]) * 8
    if not (modulus_bits == 1024 or modulus_bits == 2048 
            or (self._supports_4096 and modulus_bits == 4096) 
            or (self._supports_3072 and modulus_bits == 3072)) then
        log.output('token-nxp-chipdoc-lite:create_object_privkey(): MODULUS size invalid:', modulus_bits)
        return CKR.ATTRIBUTE_VALUE_INVALID
    end

    local keyReference
    
    self:invalidate_xproc_cache()
    -- self.nxp_hcard:auto_perform_mutual_authenticate()
    
    local isDS = self:is_ds(pTemplate) 
    
    -- access control
    pTemplate[CKA.LOCAL] = eCK.BBOOL(false)
    pTemplate[CKA.SENSITIVE] = eCK.BBOOL(true)
    pTemplate[CKA.ALWAYS_SENSITIVE] = eCK.BBOOL(true)
    pTemplate[CKA.NEVER_EXTRACTABLE] = eCK.BBOOL(true)
    pTemplate[CKA.EXTRACTABLE] = eCK.BBOOL(false)
    
    -- key usage
    pTemplate[CKA.SIGN] = eCK.BBOOL(true) -- overrides, the key can at least sign
    pTemplate[CKA.DECRYPT] = pTemplate[CKA.DECRYPT] or eCK.BBOOL(true)
    
    pTemplate[CKA.CLASS] = eCK.ULONG(CKO.PRIVATE_KEY)
    pTemplate[CKA.KEY_TYPE] = eCK.ULONG(CKK.RSA)
    
    pTemplate[CKA.VERIFY] = eCK.BBOOL(false)
    pTemplate[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    pTemplate[CKA.WRAP] = eCK.BBOOL(false)
    pTemplate[CKA.ENCRYPT] = eCK.BBOOL(false)
    pTemplate[CKA.DERIVE] = eCK.BBOOL(false)
    
    pTemplate[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(isDS)
    
    
    if self.is_cns and (pTemplate[CKA.ID] == CNS0_ID or pTemplate[CKA.LABEL] == CNS0_ID) 
            and modulus_bits == 1024
        then
        log.output('token-nxp-chipdoc-lite:create_object_privkey(): CNS key type...')
        if self.userType ~= CKU.USER then
            return CKR.USER_NOT_LOGGED_IN
        end
        
        if self.cns_info.key_valid then
            log.output('token-nxp-chipdoc-lite:create_object_privkey(): CNS key already here!')
            return CKR.DEVICE_MEMORY
        end

        -- if modulus_bits ~= 1024 then
            -- log.output('create_object_privkey(): key size invalid for CNS filesystem:', modulus_bits )
            -- return CKR.ATTRIBUTE_VALUE_INVALID
        -- end
        
        self.cns_info.modulus = pTemplate[CKA.MODULUS]
        self.cns_info.pubexp = pTemplate[CKA.PUBLIC_EXPONENT]
        local path = CNS0_KEY_PATH
        local obj = GetPrivKeyTemplate()
        
        obj.key_bits = 1024
        obj.iscns = true
        obj.path = path
        obj.kid = 1
        obj.private = true
        obj[CKA.MODULUS] = pTemplate[CKA.MODULUS]
        obj[CKA.PUBLIC_EXPONENT] = pTemplate[CKA.PUBLIC_EXPONENT]
        obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
        obj[CKA.ID] = pTemplate[CKA.ID]
        obj[CKA.LABEL] = pTemplate[CKA.LABEL]
        
        obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
        obj[CKA.SIGN] = eCK.BBOOL(true)
        obj[CKA.SIGN_RECOVER] = eCK.BBOOL(false)
        obj[CKA.VERIFY] = eCK.BBOOL(false)
        obj[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
        obj[CKA.UNWRAP] = eCK.BBOOL(false)
        obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)

        objPub = GetPubKeyTemplate()
        objPub.key_bits = obj.key_bits
        objPub.path = obj.path
        objPub.iscns = true
        objPub.private = false
        objPub.kid = obj.kid
        objPub[CKA.MODULUS] = obj[CKA.MODULUS]
        objPub[CKA.PUBLIC_EXPONENT] = obj[CKA.PUBLIC_EXPONENT]

        
        objPub[CKA.PRIVATE] = eCK.BBOOL(obj.private)
        objPub[CKA.ID] = obj[CKA.ID]
        objPub[CKA.LABEL] = obj[CKA.ID]
        objPub[CKA.MODIFIABLE] = eCK.BBOOL(true)
        objPub[CKA.VERIFY] = eCK.BBOOL(true)
        objPub[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
        objPub[CKA.ENCRYPT] = eCK.BBOOL(true)
        objPub[CKA.WRAP] = eCK.BBOOL(false)
        objPub[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
        
        -- scrive la chiave
        local wasSMActive = self.nxp_hcard.ActiveSM
        self.nxp_hcard:select_applet_cns(false)
        if self.cached_main_pin then
            self.cns_hcard:verify_pin_cns(self.cached_main_pin)
        end
        
        -- crea / aggiorna il BSO
    
        self.cns_hcard:select(obj.path)
        
        local privExp = pTemplate[CKA.PRIVATE_EXPONENT]
        local pad_to = 128
        while string.sub(privExp, 1, 1) == '\000' do privExp = string.sub(privExp, 2, -1) end
        privExp = string.rep('\000', pad_to - string.len(privExp))
                                .. privExp
        
        self.cns_hcard:change_rsa_bso(obj.kid, pTemplate[CKA.MODULUS], privExp)
        
        
        -- aggiorna o aggiunge i record TLV
        local pubExpLen = string.len(pTemplate[CKA.PUBLIC_EXPONENT])
        local modulusLen = string.len(pTemplate[CKA.MODULUS])
        self:update_append_record_cns(obj.path, 1, 
                                  hex.hexf('10%B%B00', modulusLen+2, modulusLen+1) .. pTemplate[CKA.MODULUS] )
        self:update_append_record_cns(obj.path, 2,
                                  hex.hexf('11%B%B00', pubExpLen+2, pubExpLen+1) .. pTemplate[CKA.PUBLIC_EXPONENT])
        self.cns_info.key_valid = true


        self.nxp_hcard:select_applet(false)
        if wasSMActive then
            self.nxp_hcard:perform_mutual_authenticate()
        end
        -- adds new handle to the list
        self.attributes.max_index = self.attributes.max_index +1
        self.attributes[self.attributes.max_index] = obj
        log.output(
            string.format("token-nxp-chipdoc-lite:create_object_privkey(): added CNS priv key: path=%s, handle:%d", 
                hex.hexify(obj.path), self.attributes.max_index)
            )
            

        self.attributes.max_index = self.attributes.max_index +1
        self.attributes[self.attributes.max_index] = objPub       
        self.cns_info.pub_key_handle = self.attributes.max_index
        
        return CKR.OK, self.attributes.max_index
        
    end
    
    log.output('token-nxp-chipdoc-lite:create_object_privkey(): allocating a keyReference for private key')
    keyReference = self:virtual_alloc_kid(self._indexes._private_keys_bin, self._indexes._public_keys_bin, false)
    if not keyReference  then
        log.output('token-nxp-chipdoc-lite:create_object_privkey(): no more keyReference left')
        return CKR.DEVICE_MEMORY
    end

    
    local authId = self.authID_Card_PIN
    local keyReference_pubkey = hex.hexf("DF%B", keyReference )
    local kdPriv, objNum = self:virtual_add_private_key_object(
        self._indexes._private_keys_bin,
        pTemplate[CKA.LABEL] or '',
        pTemplate[CKA.ID] or '',
        authId, keyReference, modulus_bits, isDS,
        keyReference_pubkey,
        pTemplate
        )
    if string.len(kdPriv) ~= string.len(self._indexes._private_keys_bin) then
        log.output('token-nxp-chipdoc-lite:create_object_privkey(): no more space left in Private KD file!')
        return CKR.DEVICE_MEMORY
    end

    obj = GetPrivKeyTemplate(t.mt.get_privkey)
    obj.private = true
    obj.key_bits = modulus_bits
    obj.kid = keyReference
    obj.keyReference_pubkey = keyReference_pubkey
    obj.num = objNum
    obj.userConsent = isDS and 1 or nil
    log.output(string.format("token-nxp-chipdoc-lite:create_object_privkey(): new obj num:%d kid:%d bits:%d", 
        obj.num, obj.kid, obj.key_bits) )

    self.nxp_hcard:select_MF()
    local info = self:get_info()
    
    self.nxp_hcard:select_SSCD()
    log.output('token-nxp-chipdoc-lite:create_object_privkey(): AUTH OBJ: erasing BSO...')
    self.nxp_hcard:delete_key(keyReference)
    
    local acPrivk = self.nxp_hcard.SE_ID_WRITE
    log.output('token-nxp-chipdoc-lite:create_object_privkey(): AUTH OBJ: creating BSO...')
    self.nxp_hcard:create_rsa_key(false, keyReference, obj.key_bits, acPrivk, acPrivk, acPrivk, isDS)

    log.output('token-nxp-chipdoc-lite:create_object_privkey(): importing key components...')
    local pad_components = (obj.key_bits / 8) / 2
    self.nxp_hcard:import_key_rsa(
        keyReference,
        pTemplate[CKA.PRIME_1],
        pTemplate[CKA.PRIME_2],
        ecdhlib.trim_pad_bn(pTemplate[CKA.COEFFICIENT], pad_components),
        ecdhlib.trim_pad_bn(pTemplate[CKA.EXPONENT_1], pad_components),
        ecdhlib.trim_pad_bn(pTemplate[CKA.EXPONENT_2], pad_components))


    local pubExp = pTemplate[CKA.PUBLIC_EXPONENT]
    pubExp = string.rep("\0", 4 - string.len(pubExp)) .. pubExp
    
    self.nxp_hcard:select_Generic()
    self.nxp_hcard:delete_file(keyReference_pubkey)
    
    self.nxp_hcard:create_binary_file(keyReference_pubkey, 
            string.len(pubExp .. pTemplate[CKA.MODULUS]),
            NXPChipDocLite.AC_ALWAYS,
            NXPChipDocLite.AC_ALWAYS,
            NXPChipDocLite.AC_ALWAYS
        )
    self.nxp_hcard:mupdate_binary(0, pubExp .. pTemplate[CKA.MODULUS])


    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] and not t._is_private_attribute(k) then
            obj[k] = pTemplate[k]
        end
    end

    log.output('token-nxp-chipdoc-lite:create_object_privkey(): writing private key objects directory...')
    self:_write_file(kdPriv, self.files.PrivKD)
    self._indexes._private_keys_bin = kdPriv

    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    local hPriv = self.attributes.max_index
    -- crea l'oggetto chiave pubblica associato
    -- local pTemplatePub = GetPubKeyTemplate()
    -- pTemplatePub[CKA.MODULUS] = pTemplate[CKA.MODULUS]
    -- pTemplatePub[CKA.MODULUS_BITS] = eCK.ULONG(modulus_bits)
    -- pTemplatePub[CKA.PUBLIC_EXPONENT] = pTemplate[CKA.PUBLIC_EXPONENT]
    -- pTemplatePub[CKA.ID]=pTemplate[CKA.ID]
    -- pTemplatePub[CKA.LABEL]=pTemplate[CKA.LABEL]
    -- pTemplatePub[CKA.MODIFIABLE]=pTemplate[CKA.MODIFIABLE]
    -- local rv, hPubk =  self:create_object_pubkey(pTemplatePub, keyReference, false, true)
    -- log.output('token-nxp-chipdoc-lite:create_object_privkey(): create_object_pubkey() result:', rv, hPubk)
    
    log.output('token-nxp-chipdoc-lite:create_object_privkey(): CKR.OK, hPriv:', hPriv)
    return CKR.OK, hPriv
end



function t.mt:create_object_ecc_pubkey(pTemplateOrig, keyReference_pubkey, as_local, isDS)
    log.output('token-nxp-chipdoc-lite:create_object_ecc_pubkey():', pTemplateOrig, "as_local:", as_local, "keyReference_pubkey:", hex.hexify(keyReference_pubkey or ""))
    
    if not pTemplateOrig[CKA.EC_PARAMS] or not pTemplateOrig[CKA.EC_POINT] then
        log.output('token-nxp-chipdoc-lite:create_object_ecc_pubkey(): EC_PARAMS or EC_POINT not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local curve = ecdhlib.get_curve_by_deroid(pTemplateOrig[CKA.EC_PARAMS])
    
    if not curve then
        log.output('token-nxp-chipdoc-lite:create_object_ecc_pubkey(): specified EC_PARAMS not supported:', hex.hexify(pTemplateOrig[CKA.EC_PARAMS] or ""))
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    -- keyReference_pubkey: quando specificato crea una chiave pubblica associata ad una chiave privata
    local pTemplate = utility.clone_table(pTemplateOrig)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local do_import_pubkey
    local obj

    obj = GetECCPubKeyTemplate(t.mt.get_ecc_pubkey)
    obj.private = false
    
    -- access control
    pTemplate[CKA.LOCAL] = eCK.BBOOL(as_local)

    -- key usage
    pTemplate[CKA.VERIFY] = pTemplate[CKA.VERIFY] or eCK.BBOOL(true)
    pTemplate[CKA.MODIFIABLE] = eCK.BBOOL(true)
    
    pTemplate[CKA.ENCRYPT] = eCK.BBOOL(false)
    pTemplate[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    pTemplate[CKA.UNWRAP] = eCK.BBOOL(false)
    pTemplate[CKA.WRAP] = eCK.BBOOL(false)
    pTemplate[CKA.DECRYPT] = eCK.BBOOL(false)
    pTemplate[CKA.DERIVE] = eCK.BBOOL(false)
    
    pTemplate[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
    
    pTemplate[CKA.CLASS] = eCK.ULONG(CKO.PUBLIC_KEY)
    pTemplate[CKA.KEY_TYPE] = eCK.ULONG(CKK.ECDSA)
    pTemplate[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
    
    if isDS == nil then
        isDS = self:is_ds(pTemplate)
    end
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] and type(pTemplate[k]) == 'string' then
            obj[k] = pTemplate[k]
        end
    end
    obj[CKA.LOCAL] = eCK.BBOOL(as_local)

    if not keyReference_pubkey then
        local hObj
        if self.userType == CKU.USER then
            log.output('token-nxp-chipdoc-lite:create_object_ecc_pubkey(): user logged in: searching if a private key sharing same EC_POINT...')
            hObj = self:_search_related_key_object(
                pTemplate[CKA.EC_POINT],
                nil,
                eCK.ULONG(CKO.PRIVATE_KEY) )
        else
            log.output('token-nxp-chipdoc-lite:create_object_ecc_pubkey(): user NOT logged in: unable to search a private key sharing same EC_POINT...')
        end
        if hObj then
            local objPriv = self.attributes[hObj]
            keyReference_pubkey = objPriv.keyReference_pubkey
            log.output('token-nxp-chipdoc-lite:create_object_ecc_pubkey(): found related key keyReference_pubkey:', keyReference_pubkey)
        end
         
        if not keyReference_pubkey then
            log.output('token-nxp-chipdoc-lite:create_object_ecc_pubkey(): allocating a keyReference_pubkey for public key')
            keyReference_pubkey = self:virtual_alloc_pubkey_file(self._indexes._public_keys_bin)
            if not keyReference_pubkey then
                log.output('token-nxp-chipdoc-lite:create_object_ecc_pubkey(): no more keys left in unused space file!')
                return CKR.DEVICE_MEMORY
            end
            do_import_pubkey = true
        end
    end
    
    self:invalidate_xproc_cache()
    -- self.nxp_hcard:auto_perform_mutual_authenticate()
    self.nxp_hcard:select_MF()
    local info = self:get_info()
    self.nxp_hcard:select_Generic()

    local label = pTemplate[CKA.LABEL] or ''
    local id = pTemplate[CKA.ID] or ''
    local keyReference_pubkey_num = bin.unpack("%>%H", keyReference_pubkey)
    
    local pubKDBin, objNum = self:virtual_add_public_key_object(
                                self._indexes._public_keys_bin,
                                label,
                                id,
                                keyReference_pubkey_num,
                                nil,
                                isDS,
                                keyReference_pubkey,
                                pTemplate
                                )
    if string.len(pubKDBin) ~= string.len(self._indexes._public_keys_bin) then
        log.output('token-nxp-chipdoc-lite:create_object_ecc_pubkey(): no more space left in Public KD file!')
        return CKR.DEVICE_MEMORY
    end
    obj.num = objNum
    obj.keyReference_pubkey = keyReference_pubkey
    obj.parameters = pTemplate[CKA.EC_PARAMS]
    
    log.output(string.format("token-nxp-chipdoc-lite:create_object_ecc_pubkey(): new obj num:%d EC_PARAMS:%s (%s)", 
        obj.num or -1, hex.hexify(obj.parameters), der.der_oid_to_ascii_oid(obj.parameters)) )

    if do_import_pubkey then
        -- self.nxp_hcard:select_Generic()
        self.nxp_hcard:delete_file(keyReference_pubkey)
        
        self.nxp_hcard:create_binary_file(keyReference_pubkey, 
                string.len(pTemplate[CKA.EC_POINT]),
                NXPChipDocLite.AC_ALWAYS,
                NXPChipDocLite.AC_ALWAYS,
                NXPChipDocLite.AC_ALWAYS
            )
    
        self.nxp_hcard:mupdate_binary(0, pTemplate[CKA.EC_POINT])
            
    end
    
    log.output('token-nxp-chipdoc-lite:create_object_ecc_pubkey(): writing public key objects directory...')
    self:_write_file(pubKDBin, self.files.PubKD)
    self._indexes._public_keys_bin = pubKDBin
    
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    
    log.output('token-nxp-chipdoc-lite:create_object_ecc_pubkey(): CKR.OK, hPub=', self.attributes.max_index)
    return CKR.OK, self.attributes.max_index
end



function t.mt:create_object_eddsa_pubkey(pTemplateOrig, keyReference_pubkey, as_local, isDS)
    log.output('token-nxp-chipdoc-lite:create_object_eddsa_pubkey():', pTemplateOrig, "as_local:", as_local, "keyReference_pubkey:", hex.hexify(keyReference_pubkey or ""))
    
    if not pTemplateOrig[CKA.EC_PARAMS] or not pTemplateOrig[CKA.EC_POINT] then
        log.output('token-nxp-chipdoc-lite:create_object_eddsa_pubkey(): EC_PARAMS or EC_POINT not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local asciiOid = der.der_oid_to_ascii_oid(pTemplateOrig[CKA.EC_PARAMS])
    if not Ed25519_curves_oids[asciiOid] then
        log.output('token-nxp-chipdoc-lite:create_object_eddsa_pubkey(): specified EC_PARAMS not supported:', asciiOid)
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    log.output('token-nxp-chipdoc-lite:create_object_eddsa_pubkey(): selected curve', asciiOid, Ed25519_curves_oids[asciiOid])
    
    -- keyReference_pubkey: quando specificato crea una chiave pubblica associata ad una chiave privata
    local pTemplate = utility.clone_table(pTemplateOrig)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local do_import_pubkey
    local obj

    obj = GetECCPubKeyTemplate(t.mt.get_ecc_pubkey, CKK.EC_EDWARDS)
    obj.private = false
    
    -- access control
    pTemplate[CKA.LOCAL] = eCK.BBOOL(as_local)

    -- key usage
    pTemplate[CKA.VERIFY] = pTemplate[CKA.VERIFY] or eCK.BBOOL(true)
    pTemplate[CKA.MODIFIABLE] = eCK.BBOOL(true)
    
    pTemplate[CKA.ENCRYPT] = eCK.BBOOL(false)
    pTemplate[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    pTemplate[CKA.UNWRAP] = eCK.BBOOL(false)
    pTemplate[CKA.WRAP] = eCK.BBOOL(false)
    pTemplate[CKA.DECRYPT] = eCK.BBOOL(false)
    pTemplate[CKA.DERIVE] = eCK.BBOOL(false)
    
    pTemplate[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
    
    pTemplate[CKA.CLASS] = eCK.ULONG(CKO.PUBLIC_KEY)
    pTemplate[CKA.KEY_TYPE] = eCK.ULONG(CKK.EC_EDWARDS)
    pTemplate[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
    
    if isDS == nil then
        isDS = self:is_ds(pTemplate)
    end
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] and type(pTemplate[k]) == 'string' then
            obj[k] = pTemplate[k]
        end
    end
    obj[CKA.LOCAL] = eCK.BBOOL(as_local)

    if not keyReference_pubkey then
        local hObj
        if self.userType == CKU.USER then
            log.output('token-nxp-chipdoc-lite:create_object_eddsa_pubkey(): user logged in: searching if a private key sharing same EC_POINT...')
            hObj = self:_search_related_key_object(
                pTemplate[CKA.EC_POINT],
                nil,
                eCK.ULONG(CKO.PRIVATE_KEY) )
        else
            log.output('token-nxp-chipdoc-lite:create_object_eddsa_pubkey(): user NOT logged in: unable to search a private key sharing same EC_POINT...')
        end
        if hObj then
            local objPriv = self.attributes[hObj]
            keyReference_pubkey = objPriv.keyReference_pubkey
            log.output('token-nxp-chipdoc-lite:create_object_eddsa_pubkey(): found related key keyReference_pubkey:', keyReference_pubkey)
        end
         
        if not keyReference_pubkey then
            log.output('token-nxp-chipdoc-lite:create_object_eddsa_pubkey(): allocating a keyReference_pubkey for public key')
            keyReference_pubkey = self:virtual_alloc_pubkey_file(self._indexes._public_keys_bin)
            if not keyReference_pubkey then
                log.output('token-nxp-chipdoc-lite:create_object_eddsa_pubkey(): no more keys left in unused space file!')
                return CKR.DEVICE_MEMORY
            end
            do_import_pubkey = true
        end
    end
    
    self:invalidate_xproc_cache()
    -- self.nxp_hcard:auto_perform_mutual_authenticate()
    self.nxp_hcard:select_MF()
    local info = self:get_info()
    self.nxp_hcard:select_Generic()

    local label = pTemplate[CKA.LABEL] or ''
    local id = pTemplate[CKA.ID] or ''
    local keyReference_pubkey_num = bin.unpack("%>%H", keyReference_pubkey)
    
    local pubKDBin, objNum = self:virtual_add_public_key_object(
                                self._indexes._public_keys_bin,
                                label,
                                id,
                                keyReference_pubkey_num,
                                nil,
                                isDS,
                                keyReference_pubkey,
                                pTemplate
                                )
    if string.len(pubKDBin) ~= string.len(self._indexes._public_keys_bin) then
        log.output('token-nxp-chipdoc-lite:create_object_eddsa_pubkey(): no more space left in Public KD file!')
        return CKR.DEVICE_MEMORY
    end
    obj.num = objNum
    obj.keyReference_pubkey = keyReference_pubkey
    obj.parameters = pTemplate[CKA.EC_PARAMS]
    
    log.output(string.format("token-nxp-chipdoc-lite:create_object_eddsa_pubkey(): new obj num:%d EC_PARAMS:%s (%s)", 
        obj.num or -1, hex.hexify(obj.parameters), der.der_oid_to_ascii_oid(obj.parameters)) )

    if do_import_pubkey then
        -- self.nxp_hcard:select_Generic()
        self.nxp_hcard:delete_file(keyReference_pubkey)
        
        self.nxp_hcard:create_binary_file(keyReference_pubkey, 
                string.len(pTemplate[CKA.EC_POINT]),
                NXPChipDocLite.AC_ALWAYS,
                NXPChipDocLite.AC_ALWAYS,
                NXPChipDocLite.AC_ALWAYS
            )
    
        self.nxp_hcard:mupdate_binary(0, pTemplate[CKA.EC_POINT])
            
    end
    
    log.output('token-nxp-chipdoc-lite:create_object_eddsa_pubkey(): writing public key objects directory...')
    self:_write_file(pubKDBin, self.files.PubKD)
    self._indexes._public_keys_bin = pubKDBin
    
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    
    log.output('token-nxp-chipdoc-lite:create_object_eddsa_pubkey(): CKR.OK, hPub=', self.attributes.max_index)
    return CKR.OK, self.attributes.max_index
end


function t.mt:create_object_ecc_privkey(pTemplateOrig)
    log.output('token-nxp-chipdoc-lite:create_object_ecc_privkey()', pTemplateOrig)
    
    if not pTemplateOrig[CKA.EC_PARAMS] then
        log.output('token-nxp-chipdoc-lite:create_object_ecc_privkey(): EC_PARAMS not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local curve = ecdhlib.get_curve_by_deroid(pTemplateOrig[CKA.EC_PARAMS])
    if not curve then
        log.output('token-nxp-chipdoc-lite:create_object_ecc_privkey(): specified EC_PARAMS not supported:', hex.hexify(pTemplateOrig[CKA.EC_PARAMS] or ""))
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    local pTemplate = utility.clone_table(pTemplateOrig)
    pTemplate[CKA.LOCAL] = eCK.BBOOL(false)
    
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    if not pTemplate[CKA.VALUE] then
            log.output('token-nxp-chipdoc-lite:create_object_ecc_privkey(): no key value specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end

    local keyReference
    
    self:invalidate_xproc_cache()
    -- self.nxp_hcard:auto_perform_mutual_authenticate()

    -- access control
    pTemplate[CKA.LOCAL] = eCK.BBOOL(false)
    pTemplate[CKA.SENSITIVE] = eCK.BBOOL(true)
    pTemplate[CKA.ALWAYS_SENSITIVE] = eCK.BBOOL(true)
    pTemplate[CKA.NEVER_EXTRACTABLE] = eCK.BBOOL(true)
    pTemplate[CKA.EXTRACTABLE] = eCK.BBOOL(false)
    
    -- key usage
    pTemplate[CKA.SIGN] = eCK.BBOOL(true) -- overrides, the key can at least sign
    pTemplate[CKA.DECRYPT] = eCK.BBOOL(false)
    
    
    pTemplate[CKA.VERIFY] = eCK.BBOOL(false)
    pTemplate[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    pTemplate[CKA.WRAP] = eCK.BBOOL(false)
    pTemplate[CKA.ENCRYPT] = eCK.BBOOL(false)
    pTemplate[CKA.DERIVE] = eCK.BBOOL(false)
    
    pTemplate[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)

    pTemplate[CKA.CLASS] = eCK.ULONG(CKO.PRIVATE_KEY)
    pTemplate[CKA.KEY_TYPE] = eCK.ULONG(CKK.ECDSA)
    
    local isDS = self:is_ds(pTemplate) 
    pTemplate[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(isDS)
    
    local privKey, pubKey = curve.g:make_keypair(bignum.create("0x" .. hex.hexify(pTemplate[CKA.VALUE])))
    local point = pubKey:encode_point(true)
    log.output('create_object_ecc_privkey(): EC_POINT (calculated)', hex.hexify(point))
    pTemplate[CKA.EC_POINT] = der.build(der.STRING, point)
    
    
    log.output('token-nxp-chipdoc-lite:create_object_ecc_privkey(): allocating a keyReference for private key')
    keyReference = self:virtual_alloc_kid(self._indexes._private_keys_bin)
    if not keyReference  then
        log.output('token-nxp-chipdoc-lite:create_object_ecc_privkey(): no more keyReference left')
        return CKR.DEVICE_MEMORY
    end

    
    local authId = self.authID_Card_PIN
    local keyReference_pubkey = hex.hexf("DF%B", keyReference )
    local kdPriv, objNum = self:virtual_add_private_key_object(
        self._indexes._private_keys_bin,
        pTemplate[CKA.LABEL] or '',
        pTemplate[CKA.ID] or '',
        authId, keyReference, nil, isDS,
        keyReference_pubkey,
        pTemplate
        )
        
    if string.len(kdPriv) ~= string.len(self._indexes._private_keys_bin) then
        log.output('token-nxp-chipdoc-lite:create_object_ecc_privkey(): no more space left in Private KD file!')
        return CKR.DEVICE_MEMORY
    end

    obj = GetPrivKeyTemplate(t.mt.get_privkey)
    obj.private = true
    obj.num = objNum
    obj.kid = keyReference
    obj.keyReference_pubkey = keyReference_pubkey
    obj.parameters = pTemplate[CKA.EC_PARAMS]
    obj.userConsent = isDS and 1 or nil
    log.output(string.format("token-nxp-chipdoc-lite:create_object_ecc_privkey(): new obj num:%d kid:%d EC_PARAMS:%s (%s)", 
        obj.num or -1, obj.kid, hex.hexify(obj.parameters), der.der_oid_to_ascii_oid(obj.parameters)) )

    self.nxp_hcard:select_MF()
    local info = self:get_info()
    -- self.nxp_hcard:select_Generic()
    self.nxp_hcard:select_SSCD()
    
    log.output('token-nxp-chipdoc-lite:create_object_ecc_privkey(): importing key components...')
    self.nxp_hcard:delete_key(keyReference)
    
    self.nxp_hcard:create_ecdsa_key(keyReference, curve.keybits, NXPChipDocLite.ID_PIN, NXPChipDocLite.ID_PIN, NXPChipDocLite.ID_PIN, isDS)
    
    self.nxp_hcard:import_key_ecdsa(keyReference, curve, pTemplate[CKA.VALUE])

    self.nxp_hcard:select_Generic()
    log.output('token-nxp-chipdoc-lite:create_object_ecc_privkey(): importing pub key...')
    self.nxp_hcard:delete_file(keyReference_pubkey)
    self.nxp_hcard:create_binary_file(keyReference_pubkey, 
            string.len(pTemplate[CKA.EC_POINT]),
            NXPChipDocLite.AC_ALWAYS,
            NXPChipDocLite.AC_ALWAYS,
            NXPChipDocLite.AC_ALWAYS
        )
    self.nxp_hcard:mupdate_binary(0, pTemplate[CKA.EC_POINT])
    
    pTemplate[CKA.VALUE] = nil -- avoids keep key value in obj
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] and not t._is_private_attribute(k) then
            obj[k] = pTemplate[k]
        end
    end

    log.output('token-nxp-chipdoc-lite:create_object_ecc_privkey(): writing private key objects directory...')
    self:_write_file(kdPriv, self.files.PrivKD)
    self._indexes._private_keys_bin = kdPriv

    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    local hPriv = self.attributes.max_index
    -- crea l'oggetto chiave pubblica associato
    
    log.output('token-nxp-chipdoc-lite:create_object_ecc_privkey(): CKR.OK, hPriv:', hPriv)
    return CKR.OK, hPriv
end



function t.mt:generate_key_pair_ecc(pMechanism, templatePub, templatePriv)
    local keyReference
    log.output('token-nxp-chipdoc-lite:generate_key_pair_ecc()', templatePub, templatePriv)
    if self.userType ~= CKU.USER then
        log.output('token-nxp-chipdoc-lite:generate_key_pair_ecc(): not loggen in, userType', self.userType)
        return CKR.USER_NOT_LOGGED_IN
    end
    
    log.output('token-nxp-chipdoc-lite:generate_key_pair_ecc()', pTemplateOrig)
    
    if not self.mechanisms[CKM.EC_KEY_PAIR_GEN] then
        log.output('token-nxp-chipdoc-lite:generate_key_pair_ecc(): ECDSA curves not supported by the card!')
        return CKR.MECHANISM_INVALID
    end
    
    local ec_params = templatePub[CKA.EC_PARAMS]  or templatePriv[CKA.EC_PARAMS]
    if not ec_params then
        log.output('token-nxp-chipdoc-lite:generate_key_pair_ecc(): EC_PARAMS not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local curve = ecdhlib.get_curve_by_deroid(ec_params)
    if not curve then
        log.output('token-nxp-chipdoc-lite:generate_key_pair_ecc(): specified EC_PARAMS not supported:', ec_params or "")
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    
    
    self:check_clear_cache(true)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local templatePub1 = utility.clone_table(templatePub)
    local templatePriv1 = utility.clone_table(templatePriv)
    
    if templatePub1[CKA.ID] then
        templatePriv1[CKA.ID] = templatePub1[CKA.ID]
    elseif templatePriv1[CKA.ID] then
        templatePub1[CKA.ID] = templatePriv1[CKA.ID]
    end
    
    local isDS = self:is_ds(templatePriv1)
    
    templatePriv1[CKA.EC_PARAMS] = ec_params
    templatePub1[CKA.EC_PARAMS] = ec_params
    
    -- access control
    templatePub1[CKA.LOCAL] = eCK.BBOOL(true)
    templatePriv1[CKA.LOCAL] = eCK.BBOOL(true)
    templatePriv1[CKA.SENSITIVE] = eCK.BBOOL(true)
    templatePriv1[CKA.ALWAYS_SENSITIVE] = eCK.BBOOL(true)
    templatePriv1[CKA.NEVER_EXTRACTABLE] = eCK.BBOOL(true)
    templatePriv1[CKA.EXTRACTABLE] = eCK.BBOOL(false)
    
    -- key usage
    templatePriv1[CKA.SIGN] = eCK.BBOOL(true) -- overrides, the key can at least sign
    templatePriv1[CKA.DECRYPT] = eCK.BBOOL(false)
    
    templatePriv1[CKA.CLASS] = eCK.ULONG(CKO.PRIVATE_KEY)
    templatePriv1[CKA.KEY_TYPE] = eCK.ULONG(CKK.ECDSA)
    
    templatePriv1[CKA.VERIFY] = eCK.BBOOL(false)
    templatePriv1[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    templatePriv1[CKA.WRAP] = eCK.BBOOL(false)
    templatePriv1[CKA.ENCRYPT] = eCK.BBOOL(false)
    templatePriv1[CKA.DERIVE] = eCK.BBOOL(false)
    templatePriv1[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(isDS)
    
   
    objPriv = GetECCPrivKeyTemplate(t.mt.get_privkey)
    objPriv.private = true
    objPriv.parameters = ec_params
    
    self:invalidate_xproc_cache()
    self:cache_clear()
   
    local keyReference = self:virtual_alloc_kid(self._indexes._private_keys_bin)
    
    if not keyReference then
        log.output('token-nxp-chipdoc-lite:generate_key_pair_ecc(): no more space available for this type of object!')
        return CKR.DEVICE_MEMORY
    end
    
    local authId = self.authID_Card_PIN
    
    local keyReference_pubkey = hex.hexf("DF%B", keyReference )
    local kdPriv, objNum = self:virtual_add_private_key_object(
        self._indexes._private_keys_bin,
        templatePriv1[CKA.LABEL] or '',
        templatePriv1[CKA.ID] or '',
        authId, keyReference, nil, isDS,
        keyReference_pubkey,
        templatePriv1
        )
    
    if string.len(kdPriv) ~= string.len(self._indexes._private_keys_bin) then
        log.output('token-nxp-chipdoc-lite:generate_key_pair_ecc(): no more space left in Private KD file!')
        return CKR.DEVICE_MEMORY
    end
    
    objPriv.kid = keyReference
    objPriv.keyReference_pubkey = keyReference_pubkey
    objPriv.num = objNum
    objPriv.userConsent = isDS and 1 or nil
    log.output(string.format("token-nxp-chipdoc-lite:generate_key_pair_ecc(): new obj num:%d kid:%d EC_PARAMS:%s (%s)", 
        objPriv.num or -1, objPriv.kid, hex.hexify(objPriv.parameters), der.der_oid_to_ascii_oid(objPriv.parameters)) )
        
    -- self.nxp_hcard:auto_perform_mutual_authenticate()
    local info = self:get_info()
    
    
    self:verify_cached_pin_or_finger()


    self.nxp_hcard:select_MF()
    -- self.nxp_hcard:select_Generic()
    
    self.nxp_hcard:select_SSCD()
    log.output('token-nxp-chipdoc-lite:generate_key_pair_ecc(): AUTH OBJ: erasing SDOs...')
    
    self.nxp_hcard:delete_key(keyReference)
    
    local acsPrivk = self.nxp_hcard.SE_ID_WRITE
    
    log.output('token-nxp-chipdoc-lite:generate_key_pair_ecc(): AUTH OBJ: creating SDOs...')
    self.nxp_hcard:create_ecdsa_key(keyReference, curve.keybits, acsPrivk, acsPrivk, acsPrivk, isDS)
    
    log.output('token-nxp-chipdoc-lite:generate_key_pair_ecc(): AUTH OBJ: creating ECC domain parameters...')
    local dummyprivKey = string.rep("\0", curve.keysize)
    self.nxp_hcard:import_key_ecdsa(keyReference, curve, dummyprivKey)

    log.output('token-nxp-chipdoc-lite:generate_key_pair_ecc(): AUTH OBJ: generating key pair...')
    local pubKey = self.nxp_hcard:generate_key_pair(keyReference)
        
    templatePriv1[CKA.EC_PARAMS] = ec_params
    templatePriv1[CKA.EC_POINT] = der.build(der.STRING, pubKey)
    
    self.nxp_hcard:select_Generic()
    
    log.output('token-nxp-chipdoc-lite:generate_key_pair_ecc(): importing pub key...')
    self.nxp_hcard:delete_file(keyReference_pubkey)
    self.nxp_hcard:create_binary_file(keyReference_pubkey,
            string.len(templatePriv1[CKA.EC_POINT]),
            NXPChipDocLite.AC_ALWAYS,
            NXPChipDocLite.AC_ALWAYS,
            NXPChipDocLite.AC_ALWAYS
        )
    self.nxp_hcard:mupdate_binary(0, templatePriv1[CKA.EC_POINT])
        
    templatePub1[CKA.EC_PARAMS] = ec_params
    templatePub1[CKA.EC_POINT] = der.build(der.STRING, pubKey)
    templatePub1[CKA.CLASS] = eCK.ULONG(CKO.PUBLIC_KEY)
    templatePub1[CKA.KEY_TYPE] = eCK.ULONG(CKK.ECDSA)
    templatePub1[CKA.TOKEN] = eCK.BBOOL(true)
    templatePub1[CKA.ALWAYS_AUTHENTICATE] = templatePriv1[CKA.ALWAYS_AUTHENTICATE] 

    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if templatePriv1[k] and not t._is_private_attribute(k) then
            objPriv[k] = templatePriv1[k]
        end
    end
    
    objPriv[CKA.EC_PARAMS] = ec_params
    objPriv[CKA.EC_POINT] = templatePub1[CKA.EC_POINT]
    
    if kdPriv then
        log.output('token-nxp-chipdoc-lite:generate_key_pair_ecc(): writing private key objects directory...')
        self:_write_file(kdPriv, self.files.PrivKD)
        self._indexes._private_keys_bin = kdPriv
    end
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPriv
    local hPrivk = self.attributes.max_index
    
    local rv, hPubk  = self:create_object_ecc_pubkey(templatePub1, keyReference_pubkey, true)

    log.output('token-nxp-chipdoc-lite:generate_key_pair_ecc(): create_object_ecc_pubkey(): result:', rv, 'handle:', hPubk)
    
    self:update_free_mem(self.info)
    log.output("token-nxp-chipdoc-lite:generate_key_pair_ecc():calling update_cache_id()...")
    self:update_cache_id()
    log.output(string.format("token-nxp-chipdoc-lite:generate_key_pair_ecc(): rv=CKR.OK, hPubk=%d, hPrivk=%d",  hPubk, hPrivk) )
    return CKR.OK, hPubk, hPrivk
end

function t._enc_dec_sensitive_data(data, seed, enc)
    local mKey = sm.sm_ask_keys(10)  -- richiede la chiave #10, chiave master Oberthur
    local sha = md.sha256()
    sha:update(mKey .. seed)
    local k = sha:final()
    
    local check = "\0\0\0\0\0\0\0\1"
    local result
    if enc then
        result = aes.aes_encrypt_check(k, data, check)
    else
        result = aes.aes_decrypt_check(k, data, check)
    end
    mKey = nil
    collectgarbage() -- force clear unused memory
    return result
end

function t.mt:generate_key_pair_eddsa(pMechanism, templatePub, templatePriv)
    local keyReference
    log.output('token-nxp-chipdoc-lite:generate_key_pair_eddsa()', templatePub, templatePriv)
    if self.userType ~= CKU.USER then
        log.output('token-nxp-chipdoc-lite:generate_key_pair_eddsa(): not loggen in, userType', self.userType)
        return CKR.USER_NOT_LOGGED_IN
    end
    
    log.output('token-nxp-chipdoc-lite:generate_key_pair_eddsa()', pTemplateOrig)
    
    if not self.mechanisms[CKM.EC_EDWARDS_KEY_PAIR_GEN] then
        log.output('token-nxp-chipdoc-lite:generate_key_pair_eddsa(): EDDSA curves not supported by the card!')
        return CKR.MECHANISM_INVALID
    end
    
    local ec_params = templatePub[CKA.EC_PARAMS]  or templatePriv[CKA.EC_PARAMS]
    local asciiOid = der.der_oid_to_ascii_oid(ec_params)
    
    if not Ed25519_curves_oids[asciiOid] then
        log.output('token-nxp-chipdoc-lite:generate_key_pair_eddsa(): specified EC_PARAMS not supported:', asciiOid)
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    log.output('token-nxp-chipdoc-lite:generate_key_pair_eddsa(): selected curve', asciiOid, Ed25519_curves_oids[asciiOid])
    
    self:check_clear_cache(true)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local templatePub1 = utility.clone_table(templatePub)
    local templatePriv1 = utility.clone_table(templatePriv)
    
    if templatePub1[CKA.ID] then
        templatePriv1[CKA.ID] = templatePub1[CKA.ID]
    elseif templatePriv1[CKA.ID] then
        templatePub1[CKA.ID] = templatePriv1[CKA.ID]
    end
    
    local isDS = self:is_ds(templatePriv1)
    
    templatePriv1[CKA.EC_PARAMS] = ec_params
    templatePub1[CKA.EC_PARAMS] = ec_params
    
    -- access control
    templatePub1[CKA.LOCAL] = eCK.BBOOL(true)
    templatePriv1[CKA.LOCAL] = eCK.BBOOL(true)
    templatePriv1[CKA.SENSITIVE] = eCK.BBOOL(true)
    templatePriv1[CKA.ALWAYS_SENSITIVE] = eCK.BBOOL(true)
    templatePriv1[CKA.NEVER_EXTRACTABLE] = eCK.BBOOL(true)
    templatePriv1[CKA.EXTRACTABLE] = eCK.BBOOL(false)
    
    -- key usage
    templatePriv1[CKA.SIGN] = eCK.BBOOL(true) -- overrides, the key can at least sign
    templatePriv1[CKA.DECRYPT] = eCK.BBOOL(false)
    
    templatePriv1[CKA.CLASS] = eCK.ULONG(CKO.PRIVATE_KEY)
    templatePriv1[CKA.KEY_TYPE] = eCK.ULONG(CKK.ECDSA)
    
    templatePriv1[CKA.VERIFY] = eCK.BBOOL(false)
    templatePriv1[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    templatePriv1[CKA.WRAP] = eCK.BBOOL(false)
    templatePriv1[CKA.ENCRYPT] = eCK.BBOOL(false)
    templatePriv1[CKA.DERIVE] = eCK.BBOOL(false)
    templatePriv1[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(isDS)
    
    objPriv = GetECCPrivKeyTemplate(t.mt.get_privkey, CKK.EC_EDWARDS)
   
    objPriv.private = true
    objPriv.parameters = ec_params
    
    self:invalidate_xproc_cache()
    self:cache_clear()
   
    local keyReference = self:virtual_alloc_kid(self._indexes._private_keys_bin)
    
    if not keyReference then
        log.output('token-nxp-chipdoc-lite:generate_key_pair_eddsa(): no more space available for this type of object!')
        return CKR.DEVICE_MEMORY
    end
    
    local authId = self.authID_Card_PIN
    
    local keyReference_pubkey = hex.hexf("DF%B", keyReference )
    local keyReference_privkey = hex.hexf("DE%B", keyReference )
    
    local kdPriv, objNum = self:virtual_add_private_key_object(
        self._indexes._private_keys_bin,
        templatePriv1[CKA.LABEL] or '',
        templatePriv1[CKA.ID] or '',
        authId, keyReference, nil, isDS,
        keyReference_pubkey,
        templatePriv1
        )
    
    if string.len(kdPriv) ~= string.len(self._indexes._private_keys_bin) then
        log.output('token-nxp-chipdoc-lite:generate_key_pair_eddsa(): no more space left in Private KD file!')
        return CKR.DEVICE_MEMORY
    end
    
    objPriv.kid = keyReference
    objPriv.keyReference_pubkey = keyReference_pubkey
    objPriv.num = objNum
    objPriv.userConsent = isDS and 1 or nil
    log.output(string.format("token-nxp-chipdoc-lite:generate_key_pair_eddsa(): new obj num:%d kid:%d EC_PARAMS:%s (%s)", 
        objPriv.num or -1, objPriv.kid, hex.hexify(objPriv.parameters), der.der_oid_to_ascii_oid(objPriv.parameters)) )
        
    -- self.nxp_hcard:auto_perform_mutual_authenticate()
    local info = self:get_info()
    
    
    self:verify_cached_pin_or_finger()


    self.nxp_hcard:select_MF()
    -- self.nxp_hcard:select_Generic()
    
    self.nxp_hcard:select_SSCD()
    log.output('token-nxp-chipdoc-lite:generate_key_pair_eddsa(): AUTH OBJ: erasing SDOs...')
    
    self.nxp_hcard:delete_key(keyReference)
    
    local eddsaPubK, eddsaPrivK = sm.crypto_sign_ed25519_keypair()
    
    local enc_eddsaPrivK = t._enc_dec_sensitive_data(eddsaPrivK, self.info.serialNumber, true)
    objPriv.sk = enc_eddsaPrivK

    log.output('token-nxp-chipdoc-lite:generate_key_pair_eddsa(): write priv key...')
    self.nxp_hcard:delete_file(keyReference_privkey)
    self.nxp_hcard:create_binary_file(keyReference_privkey,
            string.len(enc_eddsaPrivK),
            NXPChipDocLite.AC_ALWAYS,
            NXPChipDocLite.AC_ALWAYS,
            NXPChipDocLite.AC_ALWAYS
        )    
    eddsaPrivK = nil
    collectgarbage() -- forza liberazione della memoria inutilizzata
    self.nxp_hcard:mupdate_binary(0, enc_eddsaPrivK)
    
    templatePriv1[CKA.EC_PARAMS] = ec_params
    templatePriv1[CKA.EC_POINT] = der.build(der.STRING, eddsaPubK)
    
    self.nxp_hcard:select_Generic()
    
    log.output('token-nxp-chipdoc-lite:generate_key_pair_eddsa(): importing pub key...')
    self.nxp_hcard:delete_file(keyReference_pubkey)
    self.nxp_hcard:create_binary_file(keyReference_pubkey,
            string.len(templatePriv1[CKA.EC_POINT]),
            NXPChipDocLite.AC_ALWAYS,
            NXPChipDocLite.AC_ALWAYS,
            NXPChipDocLite.AC_ALWAYS
        )
    self.nxp_hcard:mupdate_binary(0, templatePriv1[CKA.EC_POINT])
        
    templatePub1[CKA.EC_PARAMS] = ec_params
    templatePub1[CKA.EC_POINT] = templatePriv1[CKA.EC_POINT]
    templatePub1[CKA.CLASS] = eCK.ULONG(CKO.PUBLIC_KEY)
    templatePub1[CKA.TOKEN] = eCK.BBOOL(true)
    templatePub1[CKA.KEY_TYPE] = eCK.ULONG(CKK.EC_EDWARDS)
    templatePub1[CKA.ALWAYS_AUTHENTICATE] = templatePriv1[CKA.ALWAYS_AUTHENTICATE] 

    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if templatePriv1[k] and not t._is_private_attribute(k) then
            objPriv[k] = templatePriv1[k]
        end
    end
    
    objPriv[CKA.EC_PARAMS] = ec_params
    objPriv[CKA.EC_POINT] = templatePub1[CKA.EC_POINT]
    objPriv[CKA.KEY_TYPE] = eCK.ULONG(CKK.EC_EDWARDS)
    
    if kdPriv then
        log.output('token-nxp-chipdoc-lite:generate_key_pair_eddsa(): writing private key objects directory...')
        self:_write_file(kdPriv, self.files.PrivKD)
        self._indexes._private_keys_bin = kdPriv
    end
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPriv
    local hPrivk = self.attributes.max_index
    
    local rv, hPubk  = self:create_object_eddsa_pubkey(templatePub1, keyReference_pubkey, true)

    log.output('token-nxp-chipdoc-lite:generate_key_pair_eddsa(): create_object_ecc_pubkey(): result:', rv, 'handle:', hPubk)
    
    self:update_free_mem(self.info)
    log.output("token-nxp-chipdoc-lite:generate_key_pair_eddsa():calling update_cache_id()...")
    self:update_cache_id()
    log.output(string.format("token-nxp-chipdoc-lite:generate_key_pair_eddsa(): rv=CKR.OK, hPubk=%d, hPrivk=%d",  hPubk, hPrivk) )
    return CKR.OK, hPubk, hPrivk
end

function t.mt:create_object_certificate(pTemplate)
    local usObj, FAuthId
    log.output('token-nxp-chipdoc-lite:create_object_certificate()', pTemplate)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    if not pTemplate[CKA.VALUE] then
        log.output('token-nxp-chipdoc-lite:create_object_certificate(): VALUE not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    local actual_cert_data = pTemplate[CKA.VALUE]
    if self.use_cpr_mode then
        local cpr = zlib.compresscer2( pTemplate[CKA.VALUE])
        local decpr = cpr and zlib.decompresscer2(cpr)
        if decpr == actual_cert_data then
            actual_cert_data = cpr
            pcall(function()
            log.output('token-nxp-chipdoc-lite:create_object_certificate(): cpr ratio:', 
                string.len(cpr)/string.len(pTemplate[CKA.VALUE]))
            end)
        else
            log.output('token-nxp-chipdoc-lite:create_object_certificate(): compression failed!')
        end
    end

    obj = GetCertTemplate(t.mt.get_certificate)
    obj.private = false
    local parsed_cer
    
    pcall(function() parsed_cer = der.parse_x509cer( pTemplate[CKA.VALUE]) end )
    
    if not parsed_cer then
        log.output('token-nxp-chipdoc-lite:create_object_certificate(): parse certificate failed!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    if self.is_cns and (pTemplate[CKA.ID] == CNS0_ID or pTemplate[CKA.LABEL] == CNS0_ID) then
        log.output('token-nxp-chipdoc-lite:create_object_certificate(): CNS cert type...')
        if self.userType ~= CKU.USER then
            return CKR.USER_NOT_LOGGED_IN
        end
        
        if self.cns_info.cert_valid then
            log.output('token-nxp-chipdoc-lite:create_object_certificate(): CNS cert already here!')
            return CKR.DEVICE_MEMORY
        end
        

        local path = CNS0_CERT_PATH
        obj.iscns = true
        obj.path = path
        obj.private = false
        obj[CKA.ID] = pTemplate[CKA.ID]
        obj[CKA.LABEL] = pTemplate[CKA.LABEL]
        obj[CKA.VALUE] = pTemplate[CKA.VALUE]
        obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
        obj[CKA.SUBJECT] = (parsed_cer and parsed_cer.subject) or ''
        obj[CKA.ISSUER] = (parsed_cer and parsed_cer.issuer) or ''
        obj[CKA.SERIAL_NUMBER] = (parsed_cer and parsed_cer.serialNumber) or ''
        obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
        obj[CKA.TRUSTED]    = eCK.BBOOL(false)
        
        -- scrive il certificato
        local wasSMActive = self.nxp_hcard.ActiveSM
        self.nxp_hcard:select_applet_cns(false)
        if self.cached_main_pin then
            self.cns_hcard:verify_pin_cns(self.cached_main_pin)
        end
        self.cns_hcard:select(obj.path)
        self.cns_hcard:mupdate_binary(0, pTemplate[CKA.VALUE])
        self.cns_info.cert_valid = true
        self.cns_info.certVal = pTemplate[CKA.VALUE]

        self.nxp_hcard:select_applet(false)
        if wasSMActive then
            self.nxp_hcard:perform_mutual_authenticate()
        end
        -- adds new handle to the list
        self.attributes.max_index = self.attributes.max_index +1
        self.attributes[self.attributes.max_index] = obj
        log.output(
            string.format("token-nxp-chipdoc-lite:create_object_certificate(): added CNS certificate: path=%s, handle:%d", 
                hex.hexify(obj.path), self.attributes.max_index)
            )
        return CKR.OK, self.attributes.max_index
        
    end
    
    local fid = self:virtual_alloc_cert_file(self._indexes._certificates_bin)

    log.output("token-nxp-chipdoc-lite:create_object_certificate(): using FID:", hex.hexify(fid))
    obj.path = fid

    local HolderCD, objNum = self:virtual_add_cert_object(
        self._indexes._certificates_bin,
        pTemplate[CKA.LABEL] or '',
        pTemplate[CKA.ID] or '',
        obj.path,
        parsed_cer)
    
    if string.len(HolderCD) ~= string.len(self._indexes._certificates_bin) then
        log.output('token-nxp-chipdoc-lite:create_object_certificate(): no more space left in Certificate Holder Directory file!')
        return CKR.DEVICE_MEMORY
    end
    
    obj.num = objNum
    log.output(string.format("token-nxp-chipdoc-lite:create_object_certificate(): new obj num: %d", 
        obj.num) )
        
    self:invalidate_xproc_cache()

    -- self.nxp_hcard:auto_perform_mutual_authenticate()
    self.nxp_hcard:select_MF()
    local info = self:get_info()
    self.nxp_hcard:select_Generic()
    -- scrive il certificato
    self.nxp_hcard:delete_file(obj.path)
    
    self.nxp_hcard:create_binary_file(fid, 
        string.len(actual_cert_data),
        NXPChipDocLite.AC_ALWAYS,
        NXPChipDocLite.AC_ALWAYS,
        NXPChipDocLite.AC_ALWAYS
    )
    
    self:_write_file(actual_cert_data, obj.path)
    
    if HolderCD then
        -- scrive certificate directory file
        self:_write_file(HolderCD, self.files.CDF)
        self._indexes._certificates_bin = HolderCD
    end
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] then
            obj[k] = pTemplate[k]
        end
    end

    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj

    log.output(string.format("token-nxp-chipdoc-lite:create_object_certificate(): rv=CKR.OK, hObj=%d",  self.attributes.max_index) )
        
    return CKR.OK, self.attributes.max_index
end


function t.mt:is_pdata(pTemplate)
    return pTemplate[CKA.CLASS] == eCK.ULONG(CKO.DATA) and pTemplate[CKA.LABEL] == 'PDATA'
end


function t.mt:create_object_data(pTemplateOrig)
    local usObj, FAuthId
    log.output('token-nxp-chipdoc-lite:create_object_data()', pTemplateOrig)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    
    local pTemplate = utility.clone_table(pTemplateOrig)
    
    if not pTemplate[CKA.VALUE] then
        log.output('token-nxp-chipdoc-lite:create_object_data(): VALUE not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    local actual_data = pTemplate[CKA.VALUE]
    
    local ispdata = self:is_pdata(pTemplate)
    
    obj = GetDataObjectTemplate(t.mt.get_data_object)
    obj.private = not ispdata and (pTemplate[CKA.PRIVATE] and pTemplate[CKA.PRIVATE] ~= eCK.BBOOL(false))
    local SE_ID = obj.private and self.nxp_hcard.SE_ID_WRITE  or NXPChipDocLite.AC_ALWAYS
    -- local SE_ID = NXPChipDocLite.AC_ALWAYS
    
    local fid = self:virtual_alloc_data_file(self._indexes._data_objects_bin)

    log.output("token-nxp-chipdoc-lite:create_object_data(): using FID:", hex.hexify(fid))
    obj.path = fid

    
    pTemplate[CKA.LABEL] = pTemplate[CKA.LABEL] or ''
    pTemplate[CKA.APPLICATION] = pTemplate[CKA.APPLICATION] or ''
    pTemplate[CKA.OBJECT_ID] = pTemplate[CKA.OBJECT_ID] or ''
    
    if ispdata then
        if self.cns_info.pdata_valid then
            log.output('create_object_data(): CNS PDATA already exists')
            return CKR.DEVICE_MEMORY
        end
        local dataValue = pTemplate[CKA.VALUE] or '0\000'
        obj.iscns = true
        obj.path = CNS0_PDATA_PATH

        local wasSMActive = self.nxp_hcard.ActiveSM
        self.nxp_hcard:select_applet_cns(false)
        if self.cached_main_pin then
            self.cns_hcard:verify_pin_cns(self.cached_main_pin)
        end
    
        self.cns_hcard:select(obj.path)
        self.cns_hcard:mupdate_binary(0, dataValue)
        obj[CKA.VALUE] = pTemplate[CKA.VALUE]
        self.cns_info.pdata_valid = true
        
        self.nxp_hcard:select_applet(false)
        if wasSMActive then
            self.nxp_hcard:perform_mutual_authenticate()
        end
    else
        
        local dataD, objNum = self:virtual_add_data_object(
            self._indexes._data_objects_bin,
            pTemplate,
            pTemplate[CKA.LABEL],
            pTemplate[CKA.APPLICATION],
            pTemplate[CKA.OBJECT_ID],
            obj.path)
        
        if string.len(dataD) ~= string.len(self._indexes._data_objects_bin) then
            log.output('token-nxp-chipdoc-lite:create_object_data(): no more space left in data Directory file!')
            return CKR.DEVICE_MEMORY
        end
        
        obj.num = objNum
        log.output(string.format("token-nxp-chipdoc-lite:create_object_data(): new obj num: %d", 
            obj.num) )
            
        self:invalidate_xproc_cache()

        -- self.nxp_hcard:auto_perform_mutual_authenticate()
        self.nxp_hcard:select_MF()
        local info = self:get_info()
        self.nxp_hcard:select_Generic()
        -- scrive il certificato
        self.nxp_hcard:delete_file(obj.path)
        
        self.nxp_hcard:create_binary_file(fid, 
            string.len(actual_data), 
            SE_ID,
            SE_ID,
            SE_ID
        )
        
        self:_write_file(actual_data, obj.path)
        
        if dataD then
            -- scrive certificate directory file
            self:_write_file(dataD, self.files.dataDF)
            self._indexes._data_objects_bin = dataD
        end
        
    end
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] then
            obj[k] = pTemplate[k]
        end
    end
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj

    log.output(string.format("token-nxp-chipdoc-lite:create_object_data(): rv=CKR.OK, hObj=%d",  self.attributes.max_index) )
        
    return CKR.OK, self.attributes.max_index
end

function t.mt:generate_key_pair(pMechanism, templatePubOrig, templatePrivOrig)
    log.output('generate_key_pair()', templatePub, templatePriv)
    if pMechanism and pMechanism.mechanism then
        log.output(string.format('generate_key_pair(): mechanism=%x', pMechanism.mechanism ) )
        log.output(string.format('generate_key_pair(): parameter=%s', pMechanism.parameter and hex.hexify(pMechanism.parameter) or "<null>"))
    end
    
    if pMechanism and pMechanism.mechanism then
        if not self.mechanisms[pMechanism.mechanism] then
            log.output('generate_key_pair(): unsupported mechanism!', pMechanism.mechanism)
            return CKR.MECHANISM_INVALID
        end
    end
   
   
    local templatePub = utility.clone_table(templatePubOrig)
    local templatePriv = utility.clone_table(templatePrivOrig)
    templatePub[CKA.DESTROYABLE] = templatePub[CKA.DESTROYABLE] or eCK.BBOOL(true)
    templatePriv[CKA.DESTROYABLE] = templatePriv[CKA.DESTROYABLE] or eCK.BBOOL(true)

    if not pMechanism or not pMechanism.mechanism or pMechanism.mechanism == CKM.RSA_PKCS_KEY_PAIR_GEN then
        log.output('generate_key_pair(): generating RSA...')
        return self:generate_key_pair_rsa(pMechanism, templatePub, templatePriv)
        
    elseif pMechanism.mechanism == CKM.EC_EDWARDS_KEY_PAIR_GEN then
        log.output('generate_key_pair(): generating ECC EDWARDS...')
        return self:generate_key_pair_eddsa(pMechanism, templatePub, templatePriv)
        
    elseif pMechanism.mechanism == CKM.EC_KEY_PAIR_GEN then
        log.output('generate_key_pair(): generating ECC...')
        return self:generate_key_pair_ecc(pMechanism, templatePub, templatePriv)
        
    else
        log.output('generate_key_pair(): MECHANISM_INVALID!')
        return CKR.MECHANISM_INVALID
    end
end

function t.mt:generate_key_pair_rsa(pMechanism, templatePub, templatePriv)
    local keyReference
    log.output('token-nxp-chipdoc-lite:generate_key_pair_rsa()', templatePub, templatePriv)
    if self.userType ~= CKU.USER then
        log.output('token-nxp-chipdoc-lite:generate_key_pair_rsa(): not loggen in, userType', self.userType)
        return CKR.USER_NOT_LOGGED_IN
    end
    
    self:check_clear_cache(true)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local templatePub1 = utility.clone_table(templatePub)
    local templatePriv1 = utility.clone_table(templatePriv)
    
    if templatePub1[CKA.ID] then
        templatePriv1[CKA.ID] = templatePub1[CKA.ID]
    elseif templatePriv1[CKA.ID] then
        templatePub1[CKA.ID] = templatePriv1[CKA.ID]
    end
    
    -- access control
    templatePub1[CKA.LOCAL] = eCK.BBOOL(true)
    templatePriv1[CKA.LOCAL] = eCK.BBOOL(true)
    templatePriv1[CKA.SENSITIVE] = eCK.BBOOL(true)
    templatePriv1[CKA.ALWAYS_SENSITIVE] = eCK.BBOOL(true)
    templatePriv1[CKA.NEVER_EXTRACTABLE] = eCK.BBOOL(true)
    templatePriv1[CKA.EXTRACTABLE] = eCK.BBOOL(false)
    
    -- key usage
    templatePriv1[CKA.SIGN] = eCK.BBOOL(true) -- overrides, the key can at least sign
    templatePriv1[CKA.DECRYPT] = templatePriv1[CKA.DECRYPT] or eCK.BBOOL(true)
    
    templatePriv1[CKA.CLASS] = eCK.ULONG(CKO.PRIVATE_KEY)
    templatePriv1[CKA.KEY_TYPE] = eCK.ULONG(CKK.RSA)
    
    templatePriv1[CKA.VERIFY] = eCK.BBOOL(false)
    templatePriv1[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
    templatePriv1[CKA.WRAP] = eCK.BBOOL(false)
    templatePriv1[CKA.ENCRYPT] = eCK.BBOOL(false)
    templatePriv1[CKA.DERIVE] = eCK.BBOOL(false)
    

    
    local cka_modulus_bits = templatePub1[CKA.MODULUS_BITS] or templatePriv1[CKA.MODULUS_BITS] or eCK.ULONG(2048)
    local modulus_bits = 1024    
    if not cka_modulus_bits or cka_modulus_bits == eCK.ULONG(1024) then
        modulus_bits = 1024
    elseif cka_modulus_bits == eCK.ULONG(2048) then
        modulus_bits = 2048
    elseif self._supports_3072 and cka_modulus_bits == eCK.ULONG(3072) then
        modulus_bits = 3072
    elseif self._supports_4096 and cka_modulus_bits == eCK.ULONG(4096) then
        modulus_bits = 4096
    else
        log.output('token-nxp-chipdoc-lite:generate_key_pair_rsa(): key size invalid for selected filesystem:', hex.hexify(cka_modulus_bits or '') )
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
   
    objPriv = GetPrivKeyTemplate(t.mt.get_privkey)
    objPriv.private = true
    objPriv.key_bits = modulus_bits
    
    self:invalidate_xproc_cache()
    self:cache_clear()
    
    local isDS = self:is_ds(templatePriv1)
    log.output('token-nxp-chipdoc-lite:generate_key_pair_rsa(): isDS:', isDS)

    local is_cns = self.is_cns and (templatePub1[CKA.ID] == CNS0_ID or templatePub1[CKA.LABEL] == CNS0_ID or templatePriv1[CKA.LABEL] == CNS0_ID)

    if is_cns and modulus_bits == 1024 then
        if self.cns_info.key_valid then
            log.output('token-nxp-chipdoc-lite:generate_key_pair_rsa(): CNS key already here!')
            return CKR.DEVICE_MEMORY
        end
        
        -- if modulus_bits ~= 1024 then
            -- log.output('generate_key_pair_rsa(): key size invalid for CNS filesystem:', modulus_bits )
            -- return CKR.ATTRIBUTE_VALUE_INVALID
        -- end
        

        local path = CNS0_KEY_PATH
        local obj = GetPrivKeyTemplate()
        
        obj.key_bits = 1024
        obj.iscns = true
        obj.path = path
        obj.kid = 1
        obj.private = true
        obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
        obj[CKA.ID] = templatePriv1[CKA.ID]
        obj[CKA.LABEL] = templatePriv1[CKA.LABEL]
        
        obj[CKA.MODIFIABLE] = eCK.BBOOL(true)
        obj[CKA.SIGN] = eCK.BBOOL(true)
        obj[CKA.SIGN_RECOVER] = eCK.BBOOL(false)
        obj[CKA.VERIFY] = eCK.BBOOL(false)
        obj[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
        obj[CKA.UNWRAP] = eCK.BBOOL(false)
        obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)

        objPub = GetPubKeyTemplate()
        objPub.key_bits = obj.key_bits
        objPub.path = obj.path
        objPub.iscns = true
        objPub.private = false
        objPub.kid = obj.kid
        objPub[CKA.MODULUS] = obj[CKA.MODULUS]
        objPub[CKA.PUBLIC_EXPONENT] = obj[CKA.PUBLIC_EXPONENT]

        
        objPub[CKA.PRIVATE] = eCK.BBOOL(obj.private)
        objPub[CKA.ID] = obj[CKA.ID]
        objPub[CKA.LABEL] = obj[CKA.ID]
        objPub[CKA.MODIFIABLE] = eCK.BBOOL(true)
        objPub[CKA.VERIFY] = eCK.BBOOL(true)
        objPub[CKA.VERIFY_RECOVER] = eCK.BBOOL(false)
        objPub[CKA.ENCRYPT] = eCK.BBOOL(true)
        objPub[CKA.WRAP] = eCK.BBOOL(false)
        objPub[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)
        
        -- scrive la chiave
        local wasSMActive = self.nxp_hcard.ActiveSM
        self.nxp_hcard:select_applet_cns(false)
        if self.cached_main_pin then
            self.cns_hcard:verify_pin_cns(self.cached_main_pin)
        end
        
        -- crea / aggiorna il BSO
    
        self.cns_hcard:select(obj.path)
        
        self.cns_hcard:generate_key_pair(obj.kid, CNS0_KEY_PATH, 17)
        
        modulus, pubexp = self.cns_hcard:read_public_key(obj.path)
        
        self.cns_info.modulus = modulus
        self.cns_info.pubexp = pubexp
        obj[CKA.MODULUS] = modulus
        obj[CKA.PUBLIC_EXPONENT] = pubexp
        objPub[CKA.MODULUS] = modulus
        objPub[CKA.PUBLIC_EXPONENT] = pubexp
        
        self.cns_info.key_valid = true


        self.nxp_hcard:select_applet(false)
        if wasSMActive then
            self.nxp_hcard:perform_mutual_authenticate()
        end
        -- adds new handle to the list
        self.attributes.max_index = self.attributes.max_index +1
        self.attributes[self.attributes.max_index] = obj
        log.output(
            string.format("token-nxp-chipdoc-lite:generate_key_pair_rsa(): added CNS priv key: path=%s, handle:%d", 
                hex.hexify(obj.path), self.attributes.max_index)
            )
        local hPriv = self.attributes.max_index

        self.attributes.max_index = self.attributes.max_index +1
        self.attributes[self.attributes.max_index] = objPub       
        self.cns_info.pub_key_handle = self.attributes.max_index
        
        log.output(
            string.format("token-nxp-chipdoc-lite:generate_key_pair_rsa(): added CNS pub key: path=%s, handle:%d", 
                hex.hexify(obj.path), self.attributes.max_index)
            )

        return CKR.OK, self.cns_info.pub_key_handle, hPriv
        
    end
    
    local keyReference = self:virtual_alloc_kid(self._indexes._private_keys_bin)
    if not keyReference then
        log.output('token-nxp-chipdoc-lite:generate_key_pair_rsa(): no more space available for this type of object!')
        return CKR.DEVICE_MEMORY
    end
    

    if isDS then
        templatePriv1[CKA.UNWRAP] = eCK.BBOOL(false)
        templatePriv1[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(true)
        
        templatePub1[CKA.WRAP] = eCK.BBOOL(false)
    end


    local authId = self.authID_Card_PIN
    local keyReference_pubkey = hex.hexf("DF%B", keyReference )
    local kdPriv, objNum = self:virtual_add_private_key_object(
        self._indexes._private_keys_bin,
        templatePriv1[CKA.LABEL] or '',
        templatePriv1[CKA.ID] or '',
        authId, keyReference, modulus_bits, isDS,
        keyReference_pubkey,
        templatePriv1
        )
    
    if string.len(kdPriv) ~= string.len(self._indexes._private_keys_bin) then
        log.output('token-nxp-chipdoc-lite:generate_key_pair_rsa(): no more space left in Private KD file!')
        return CKR.DEVICE_MEMORY
    end
    
    objPriv.kid = keyReference
    objPriv.num = objNum
    objPriv.userConsent = isDS and 1 or nil
    log.output(string.format("token-nxp-chipdoc-lite:generate_key_pair_rsa(): new obj num:%d kid:%d bits:%d", 
        objPriv.num, objPriv.kid, objPriv.key_bits) )
    
    -- self.nxp_hcard:auto_perform_mutual_authenticate()
    local info = self:get_info()
    
    self:verify_cached_pin_or_finger()
    
    local modulus, pubExp
    

    self.nxp_hcard:select_MF()
    -- self.nxp_hcard:select_Generic()
    
    self.nxp_hcard:select_SSCD()
    log.output('token-nxp-chipdoc-lite:generate_key_pair_rsa(): AUTH OBJ: erasing SDOs...')
    self.nxp_hcard:delete_key(keyReference)
    
    log.output('token-nxp-chipdoc-lite:generate_key_pair_rsa(): AUTH OBJ: creating SDOs...')
    local acPrivk = self.nxp_hcard.SE_ID_WRITE
    self.nxp_hcard:create_rsa_key(false, keyReference, objPriv.key_bits, acPrivk, acPrivk, acPrivk, isDS)

    
    log.output('token-nxp-chipdoc-lite:generate_key_pair_rsa(): AUTH OBJ: generating key pair...')
    modulus = self.nxp_hcard:generate_key_pair(keyReference)
    log.output('token-nxp-chipdoc-lite:generate_key_pair_rsa(): modulus:', hex.hexify(modulus))
    pubExp = hex.hexf("010001")
    local pubExpPadded = string.rep("\0", 4 - string.len(pubExp)) .. pubExp
    
    self.nxp_hcard:select_Generic()
    
    self.nxp_hcard:delete_file(keyReference_pubkey)
    
    self.nxp_hcard:create_binary_file(keyReference_pubkey, 
            string.len(pubExpPadded .. modulus),
            NXPChipDocLite.AC_ALWAYS,
            NXPChipDocLite.AC_ALWAYS,
            NXPChipDocLite.AC_ALWAYS
        )
    self.nxp_hcard:mupdate_binary(0, pubExpPadded .. modulus)


    templatePub1[CKA.MODULUS] = modulus
    templatePub1[CKA.PUBLIC_EXPONENT] = pubExp
    templatePub1[CKA.CLASS] = eCK.ULONG(CKO.PUBLIC_KEY)
    templatePub1[CKA.KEY_TYPE] = eCK.ULONG(CKK.RSA)
    templatePub1[CKA.TOKEN] = eCK.BBOOL(true)

    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if templatePriv1[k] and not t._is_private_attribute(k) then
            objPriv[k] = templatePriv1[k]
        end
    end
    
    objPriv[CKA.MODULUS] = modulus        -- cache preventiva
    objPriv[CKA.PUBLIC_EXPONENT] = pubExp
    objPriv[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(false)

    if kdPriv then
        log.output('token-nxp-chipdoc-lite:generate_key_pair_rsa(): writing private key objects directory...')
        self:_write_file(kdPriv, self.files.PrivKD)
        self._indexes._private_keys_bin = kdPriv
    end
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPriv
    local hPrivk = self.attributes.max_index
    
    local rv, hPubk  = self:create_object_pubkey(templatePub1, keyReference_pubkey, true, isDS)

    log.output('token-nxp-chipdoc-lite:generate_key_pair_rsa(): create_object_pubkey(): result:', rv, 'handle:', hPubk)
    
    self:update_free_mem(self.info)
    log.output("token-nxp-chipdoc-lite:generate_key_pair_rsa():calling update_cache_id()...")
    self:update_cache_id()
    log.output(string.format("token-nxp-chipdoc-lite:generate_key_pair_rsa(): rv=CKR.OK, hPubk=%d, hPrivk=%d",  hPubk, hPrivk) )
    return CKR.OK, hPubk, hPrivk
end

function t.mt:generate_key(pMechanism, pTemplate)
    log.output('token-nxp-chipdoc-lite:generate_key(): pMechanism', pMechanism and pMechanism.mechanism)
    
    self:verify_cached_pin_or_finger()
    
    if pTemplate[CKA.PRIVATE]
        and pTemplate[CKA.PRIVATE] ~= eCK.BBOOL(false)
        and self.userType ~= CKU.USER then
        log.output('token-nxp-chipdoc-lite:generate_key(): not logged in: login required to create private objects')
        return CKR.USER_NOT_LOGGED_IN
    end
    
    if not pTemplate[CKA.VALUE_LEN] then
        log.output('token-nxp-chipdoc-lite:generate_key(): no key len specified')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local rv, hObj
    
    self:check_clear_cache(true)
    self:invalidate_xproc_cache()
    self:cache_clear()
    
    if pMechanism.mechanism == CKM.AES_KEY_GEN then
        local pTemplate2 = utility.clone_table(pTemplate)
        local value_len
        
        if pTemplate2[CKA.VALUE_LEN] == eCK.ULONG(16) then
            value_len = 16
        elseif pTemplate2[CKA.VALUE_LEN] == eCK.ULONG(24) then
            value_len = 24
        elseif pTemplate2[CKA.VALUE_LEN] == eCK.ULONG(32) then
            value_len = 32
        else
            log.output('token-nxp-chipdoc-lite:generate_key(): key len not supported:', hex.hexify(pTemplate2[CKA.VALUE_LEN] or ""))
            return CKR.ATTRIBUTE_VALUE_INVALID
        end
        
        pTemplate2[CKA.VALUE] = sm.gen_random(value_len)
        pTemplate2[CKA.CLASS] = eCK.ULONG(CKO.SECRET_KEY)
        pTemplate2[CKA.KEY_TYPE] = eCK.ULONG(CKK.AES)
        pTemplate2[CKA.ENCRYPT] = eCK.BBOOL(true)
        pTemplate2[CKA.DECRYPT] = eCK.BBOOL(true)
        
        rv, hObj = self:create_object_secret_key(pTemplate2, true)

    else
    
        log.output('token-nxp-chipdoc-lite:generate_key(): unsupported mechanism:', pMechanism.mechanism)
        rv = CKR.MECHANISM_INVALID
    end
    if rv == CKR.OK then
        self:update_free_mem(self.info)
        log.output("token-nxp-chipdoc-lite:generate_key(): calling update_cache_id()...")
        self:update_cache_id()
    end
    log.output(string.format("token-nxp-chipdoc-lite:generate_key(): returning rv=0x%08X, hobj=%d", rv or -1, hObj or -1))
    return rv, hObj
end

function t.mt:create_object_secret_key(pTemplate, as_local)

    log.output('token-nxp-chipdoc-lite:create_object_secret_key()', pTemplate)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    if not pTemplate[CKA.VALUE] then
        log.output('token-nxp-chipdoc-lite:create_object_secret_key(): VALUE not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    local value = pTemplate[CKA.VALUE]
    local value_len = string.len(value)
    
    if value_len ~= 16 and value_len ~= 24 and value_len ~= 32  then
        log.output('token-nxp-chipdoc-lite:create_object_secret_key(): VALUE len invalid!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end

    obj = GetSecretKeyTemplate(t.mt.get_secret_key)
    obj.private = true
    obj.value = value
    
    local keyReference = self:virtual_alloc_kid_secret_key(self._indexes._secret_keys_bin)
    local fid = hex.hexf("DA%B", tonumber("EF", 16) +  keyReference) -- secret key files: DAF0 - DAFF
    log.output("token-nxp-chipdoc-lite:create_object_secret_key(): using FID:", hex.hexify(fid))
    obj.path = fid

    local authId = self.authID_Card_PIN
    pTemplate[CKA.LOCAL] = eCK.BBOOL(as_local)
    local keyReference_pubkey = hex.hexf("DF%B", keyReference )
    local kdSecret, objNum = self:virtual_add_private_key_object(
        self._indexes._secret_keys_bin,
        pTemplate[CKA.LABEL] or '',
        pTemplate[CKA.ID] or '',
        authId, keyReference, value_len, false,
        keyReference_pubkey,
        pTemplate
        )
    
    if string.len(kdSecret) ~= string.len(self._indexes._secret_keys_bin) then
        log.output('token-nxp-chipdoc-lite:create_object_secret_key(): no more space left in secret keys Directory file!')
        return CKR.DEVICE_MEMORY
    end
    
    obj.num = objNum
    log.output(string.format("token-nxp-chipdoc-lite:create_object_secret_key(): new obj num: %d", 
        obj.num) )
        
    self:invalidate_xproc_cache()

    -- self.nxp_hcard:auto_perform_mutual_authenticate()
    self.nxp_hcard:select_MF()
    local info = self:get_info()
    self.nxp_hcard:select_Generic()
    -- scrive value
    self.nxp_hcard:delete_file(obj.path, true, true)
    
    local e_value = aes.aes_encrypt_check(self._mk, value, "00000001")
    log.output("token-nxp-chipdoc-lite:create_object_secret_key(): value:", hex.hexify(value))
    log.output("token-nxp-chipdoc-lite:create_object_secret_key(): e_value:", hex.hexify(e_value))
    
    self.nxp_hcard:create_binary_file(fid, 
        string.len(e_value), 
        NXPChipDocLite.AC_ALWAYS,
        NXPChipDocLite.AC_ALWAYS,
        NXPChipDocLite.AC_ALWAYS
    )
    
    self:_write_file(e_value, obj.path)
    
    if kdSecret then
        -- scrive secret keys directory file
        self:_write_file(kdSecret, self.files.secretKD)
        self._indexes._secret_keys_bin = kdSecret
    end
    
    pTemplate[CKA.VALUE] = nil
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] then
            obj[k] = pTemplate[k]
        end
    end

    
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj

    log.output(string.format("token-nxp-chipdoc-lite:create_object_secret_key(): rv=CKR.OK, hObj=%d",  self.attributes.max_index) )
    
    return CKR.OK, self.attributes.max_index
end


function t.mt:create_object(pTemplate)
    log.output('token-nxp-chipdoc-lite:create_object(): ')
    self:verify_cached_pin_or_finger()

    if pTemplate[CKA.PRIVATE]
        and pTemplate[CKA.PRIVATE] ~= eCK.BBOOL(false)
        and self.userType ~= CKU.USER then
        log.output('token-nxp-chipdoc-lite:create_object(): not logged in: login required to create private objects')
        return CKR.USER_NOT_LOGGED_IN
    end

    local rv, hObj
    
    self:check_clear_cache(true)
    self:invalidate_xproc_cache()
    self:cache_clear()
    
    if pTemplate[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        rv, hObj = self:create_object_certificate(pTemplate)
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
    
        rv, hObj = self:create_object_data(pTemplate)

    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.SECRET_KEY) then
        if pTemplate[CKA.KEY_TYPE] == eCK.ULONG(CKK.AES) then
    
            if not self.mechanisms[CKM.AES_KEY_GEN] then
                log.output('create_object(): AES obejct not supported')
                return CKR.ATTRIBUTE_VALUE_INVALID
            end
            
            rv, hObj = self:create_object_secret_key(pTemplate)
        else
            log.output('token-nxp-chipdoc-lite:create_object(): unsupported secret key type:', hex.hexify(pTemplate[CKA.KEY_TYPE] or ''))
            return CKR.ATTRIBUTE_VALUE_INVALID
        end
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        if pTemplate[CKA.KEY_TYPE] == eCK.ULONG(CKK.ECDSA) then

            if not self.mechanisms[CKM.EC_KEY_PAIR_GEN] then
                log.output('create_object(): ECDSA obejct not supported')
                return CKR.ATTRIBUTE_VALUE_INVALID
            end
            
            rv, hObj = self:create_object_ecc_privkey(pTemplate)
        else
            rv, hObj = self:create_object_privkey(pTemplate)
        end
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
    
        if pTemplate[CKA.KEY_TYPE] == eCK.ULONG(CKK.ECDSA) then

            if not self.mechanisms[CKM.EC_KEY_PAIR_GEN] then
                log.output('create_object(): ECDSA obejct not supported')
                return CKR.ATTRIBUTE_VALUE_INVALID
            end

            rv, hObj = self:create_object_ecc_pubkey(pTemplate)
        else
            rv, hObj = self:create_object_pubkey(pTemplate)
        end
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO_PIN_POLICY) then
        rv, hObj = self:create_object_pin_policy(pTemplate)
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO_FINGERPRINT) then
        rv, hObj = self:create_object_fingerprint(pTemplate)
    else
        log.output('token-nxp-chipdoc-lite:create_object(): unsupported object class:', hex.hexify(pTemplate[CKA.CLASS] or ''))
        rv = CKR.ATTRIBUTE_VALUE_INVALID
    end
    if rv == CKR.OK then
        self:update_free_mem(self.info)
        log.output("token-nxp-chipdoc-lite:create_object(): calling update_cache_id()...")
        self:update_cache_id()
    end
    log.output(string.format("token-nxp-chipdoc-lite:create_object(): returning rv=0x%08X, hobj=%d", rv or -1, hObj or -1))
    return rv, hObj
end


function t.mt:_renumber_objects(objRef)
    local obj
    for i=self.attributes.min_index, self.attributes.max_index do
        obj = self.attributes[i]
        if type(obj) == "table" 
            and obj[CKA.CLASS] == objRef[CKA.CLASS]
            and obj.num and objRef.num 
            and obj.num > objRef.num then
            obj.num = obj.num -1
        end
    end
end

function t.mt:_related_key_exists(kid, excludeNum)
    local obj
    for i=self.attributes.min_index, self.attributes.max_index do
        obj = self.attributes[i]
        if type(obj) == "table" and obj.kid == kid and obj.num ~= excludeNum then
            return true
        end
    end
    return false
end

function t.mt:destroy_object(hObject)
    log.output('token-nxp-chipdoc-lite:destroy_object(): ', hObject)
       
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hObject]
    
    if obj == nil then return CKR.OBJECT_HANDLE_INVALID end
    
    if obj[CKA.CLASS] == eCK.ULONG(CKO_FINGERPRINT) then
        if self.userType ~= CKU.SO then
            log.output('token-nxp-chipdoc-lite:destroy_object(): SO login required to destroy privte or NON-DATA objects')
            return CKR.USER_TYPE_INVALID
        end
    else
        
        local login_required = obj.private or obj[CKA.CLASS] ~= eCK.ULONG(CKO.DATA) or obj.iscns
        
        if login_required then
            if self.userType ~= CKU.USER then
                log.output('token-nxp-chipdoc-lite:destroy_object(): USER login required to destroy privte or NON-DATA objects')
                return CKR.USER_NOT_LOGGED_IN
            end
        end
    end
    if not obj.iscns then
        self:verify_cached_pin_or_finger()
    end
    self:check_clear_cache(true)
    
    self:invalidate_xproc_cache()
    -- self.nxp_hcard:auto_perform_mutual_authenticate()
    self:cache_clear()
    
    self.nxp_hcard:select_Generic()
    
    if obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        log.output('token-nxp-chipdoc-lite:destroy_object(): destroyng a certificate')
        
        if obj.iscns then
            log.output('token-nxp-chipdoc-lite:destroy_object(): CNS object')
            local wasSMActive = self.nxp_hcard.ActiveSM
            self.nxp_hcard:select_applet_cns(false)


            if self.cached_main_pin then
                self.cns_hcard:verify_pin_cns(self.cached_main_pin)
            end
            self.cns_hcard:select(obj.path)
            self.cns_hcard:mupdate_binary(0, "\0\0\0\0")
            self.cns_info.cert_valid = false


            self.nxp_hcard:select_applet(false)
            if wasSMActive then
                self.nxp_hcard:perform_mutual_authenticate()
            end
        
        else
            -- rimuove la entry indicata da "obj.num" dall'index
            local d = p15.parseCertDF(self._indexes._certificates_bin)
            if obj.num > table.getn(d) then
                log.output('token-nxp-chipdoc-lite:destroy_object(): obj.num invalid:', obj.num)
                return CKR.FUNCTION_FAILED
            end
            table.remove(d, obj.num)
            local HolderCD = p15.buildCertDF(d)
            HolderCD = HolderCD .. string.rep("\000", string.len(self._indexes._certificates_bin) - string.len(HolderCD))
            
            -- delete cert file:
            self.nxp_hcard:delete_file(obj.path)

            -- scrive certificate directory file
            self:_write_file(HolderCD, self.files.CDF)

            self._indexes._certificates_bin = HolderCD
            
            -- elimina l'oggetto dalla lista
            self.attributes[hObject] = nil
            
            -- rinumera tutti gli oggetti certificate con num > obj.num
            self:_renumber_objects(obj)
        end
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        log.output('token-nxp-chipdoc-lite:destroy_object(): destroyng a data object')
        
        
        if obj.iscns then
            log.output('destroy_object(): CNS PDATA')
            local wasSMActive = self.nxp_hcard.ActiveSM
            self.nxp_hcard:select_applet_cns(false)


            if self.cached_main_pin then
                self.cns_hcard:verify_pin_cns(self.cached_main_pin)
            end
            local pcRes, theErrorT = pcall(function()
                self.cns_hcard:select(obj.path)
                self.cns_hcard:mupdate_binary(0, "\0")
                self.cns_info.pdata_valid = false
                
            end)
            if not pcRes then
                log.output('token-nxp-chipdoc-lite:destroy_object(): error:', debug.traceback(theErrorT))
            end
            self.nxp_hcard:select_applet(false)
            if wasSMActive then
                self.nxp_hcard:perform_mutual_authenticate()
            end
        else
            
            -- rimuove la entry indicata da "obj.num" dall'index
            local d = p15.parsePubPrivDataD(self._indexes._data_objects_bin)
            if obj.num > table.getn(d) then
                log.output('token-nxp-chipdoc-lite:destroy_object(): obj.num invalid:', obj.num)
                return CKR.FUNCTION_FAILED
            end
            table.remove(d, obj.num)
            local dataD = p15.buildPubPrivDataD(d)
            dataD = dataD .. string.rep("\000", string.len(self._indexes._data_objects_bin) - string.len(dataD))
            
            -- delete cert file:
            self.nxp_hcard:delete_file(obj.path)

            -- scrive data object directory file
            self:_write_file(dataD, self.files.dataDF)

            self._indexes._data_objects_bin = dataD
            
            -- elimina l'oggetto dalla lista
            self.attributes[hObject] = nil
            
            -- rinumera tutti gli oggetti data con num > obj.num
            self:_renumber_objects(obj)
        end
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.SECRET_KEY) then
        log.output('token-nxp-chipdoc-lite:destroy_object(): destroyng a certificate')
        -- rimuove la entry indicata da "obj.num" dall'index
        local d = p15.parsePubPrivKD(self._indexes._secret_keys_bin)
        if obj.num > table.getn(d) then
            log.output('token-nxp-chipdoc-lite:destroy_object(): obj.num invalid:', obj.num)
            return CKR.FUNCTION_FAILED
        end
        table.remove(d, obj.num)
        local secretKD = p15.buildPubPrivKD(d)
        secretKD = secretKD .. string.rep("\000", string.len(self._indexes._secret_keys_bin) - string.len(secretKD))
        
        -- delete key file:
        self.nxp_hcard:delete_file(obj.path)

        -- scrive secret keys directory file
        self:_write_file(secretKD, self.files.secretKD)

        self._indexes._secret_keys_bin = secretKD
        
        -- elimina l'oggetto dalla lista
        self.attributes[hObject] = nil
        
        -- rinumera tutti gli oggetti secret key con num > obj.num
        self:_renumber_objects(obj)
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        log.output('token-nxp-chipdoc-lite:destroy_object(): destroyng a public key')
        
        if obj.iscns then
            log.output('destroy_object(): CNS PUBLIC_KEY: nothing to do')
            -- e' necessario cancellare la chiave privata
        else
            -- rimuove la entry indicata da "obj.num" dall'index
            local pkBin
            local d = p15.parsePubPrivKD(self._indexes._public_keys_bin)
            if obj.num > table.getn(d) then
                log.output('token-nxp-chipdoc-lite:destroy_object(): obj.num invalid:', obj.num)
                return CKR.FUNCTION_FAILED
            end
            table.remove(d, obj.num)
            pkBin = p15.buildPubPrivKD(d, {subClassAttributes={}})
            pkBin = pkBin .. string.rep("\000", string.len(self._indexes._public_keys_bin) - string.len(pkBin))

            
            if pkBin then
                -- scrive public key directory file
                self:_write_file(pkBin, self.files.PubKD)
                self._indexes._public_keys_bin = pkBin
            end

            if obj.keyReference_pubkey and not self:is_keyReference_pubkey_in_use(self._indexes._private_keys_bin, obj.keyReference_pubkey)
                and not self:is_keyReference_pubkey_in_use(self._indexes._public_keys_bin, obj.keyReference_pubkey) then
                self.nxp_hcard:delete_file(obj.keyReference_pubkey)
            end
        end
        -- elimina l'oggetto dalla lista
        self.attributes[hObject] = nil
        
        -- rinumera tutti gli oggetti public key con num > obj.num
        self:_renumber_objects(obj)

    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        log.output('token-nxp-chipdoc-lite:destroy_object(): destroyng a private key')
        
        if obj.iscns then
            log.output('destroy_object(): CNS PRIVATE_KEY')
            local wasSMActive = self.nxp_hcard.ActiveSM
            self.nxp_hcard:select_applet_cns(false)


            if self.cached_main_pin then
                self.cns_hcard:verify_pin_cns(self.cached_main_pin)
            end
            local pcRes, theErrorT = pcall(function()
                self:update_append_record_cns(obj.path, 1, hex.hexf('1082') .. string.rep('\255', 130) )
                self:update_append_record_cns(obj.path, 2, hex.hexf('1105') .. string.rep('\255', 5) )
                self.cns_info.key_valid=false
                self.cns_info.pub_key_handle = nil
            end)
            if not pcRes then
                log.output('token-nxp-chipdoc-lite:destroy_object(): error:', debug.traceback(theErrorT))
            end
            self.nxp_hcard:select_applet(false)
            if wasSMActive then
                self.nxp_hcard:perform_mutual_authenticate()
            end
        else
            -- rimuove la entry indicata da "obj.num" dall'index
            local pkBin
            local d = p15.parsePubPrivKD(self._indexes._private_keys_bin)
            if obj.num > table.getn(d) then
                log.output('token-nxp-chipdoc-lite:destroy_object(): obj.num invalid:', obj.num)
                return CKR.FUNCTION_FAILED
            end
            table.remove(d, obj.num)
            pkBin = p15.buildPubPrivKD(d, {subClassAttributes={}})
            pkBin = pkBin .. string.rep("\000", string.len(self._indexes._public_keys_bin) - string.len(pkBin))


            if pkBin then
                -- scrive private key directory file
                self:_write_file(pkBin, self.files.PrivKD)
                self._indexes._private_keys_bin = pkBin
            end
            
            if obj.keyReference_pubkey and not self:is_keyReference_pubkey_in_use(self._indexes._private_keys_bin, obj.keyReference_pubkey)
                and not self:is_keyReference_pubkey_in_use(self._indexes._public_keys_bin, obj.keyReference_pubkey) then
                self.nxp_hcard:delete_file(obj.keyReference_pubkey)
            end
            
            log.output('token-nxp-chipdoc-lite:destroy_object(): delete key SDO:', obj.kid)
            self.nxp_hcard:select_SSCD()
            self.nxp_hcard:delete_key(obj.kid)
        end
        -- elimina l'oggetto dalla lista
        self.attributes[hObject] = nil
        
        -- rinumera tutti gli oggetti private key con num > obj.num
        self:_renumber_objects(obj)
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO_FINGERPRINT) then
        log.output('token-nxp-chipdoc-lite:destroy_object(): destroyng a fingerprint object')
        
        local d = t._parse_fingerprint_objects(self._indexes._fingerprints_bin)
        
        for i, v in d do
            if v.id == obj[CKA.ID] then
                table.remove(d, i)
                local new_fingerprints_bin = t._build_fingerprint_objects(d)
                new_fingerprints_bin = new_fingerprints_bin .. string.rep("\0", string.len(self._indexes._fingerprints_bin)- string.len(new_fingerprints_bin))
                
                self:_write_file(new_fingerprints_bin, self.files.FPOD)
                
                self._indexes._fingerprints_bin = new_fingerprints_bin
            
                -- elimina l'oggetto dalla lista
                self.attributes[hObject] = nil
                
                -- rinumera tutti gli oggetti data con num > obj.num
                self:_renumber_objects(obj)
                
                self.nxp_hcard:delete_fingerprint(string.byte(v.id))
                
                break
            end
        end

    else
        log.output('token-nxp-chipdoc-lite:destroy_object(): WARNING! Unsupported object class!')
        return CKR.FUNCTION_FAILED
    end
    
    self.attributes[hObject] = nil
    
    self:update_free_mem(self.info)
    log.output("token-nxp-chipdoc-lite:destroy_object(): calling update_cache_id()...")
    self:update_cache_id()
    log.output("token-nxp-chipdoc-lite:destroy_object(): returning CKR.OK")
    return CKR.OK
end

function t.mt:set_attribute_value(hObject, pTemplate)
    log.output('token-nxp-chipdoc-lite:set_attribute_value():', hObject)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local rv
    local obj = self.attributes[hObject]
    if obj == nil then
        log.output('token-nxp-chipdoc-lite:set_attribute_value(): specified handle invalid: ', hObject)
        return CKR.OBJECT_HANDLE_INVALID
    end

    self:verify_cached_pin_or_finger()
    
    self:invalidate_xproc_cache()
    -- self.nxp_hcard:auto_perform_mutual_authenticate()
    
    if obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        if not obj.populated then self:get_pubkey(hObject, CKA.CLASS, false, true) end
        rv = self:set_attribute_value_pubkey(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        if not obj.populated then self:get_privkey(hObject, CKA.CLASS) end
        rv = self:set_attribute_value_privkey(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        if not obj.populated then self:get_certificate(hObject, CKA.CLASS, false, true) end
        rv = self:set_attribute_value_certificate(hObject, pTemplate)
        
    else
        log.output('token-nxp-chipdoc-lite:set_attribute_value(): unsupported object class:', hex.hexify(obj[CKA.CLASS]))
        rv = CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    if rv == CKR.OK then
        self:update_free_mem(self.info)
        log.output("token-nxp-chipdoc-lite:set_attribute_value(): calling update_cache_id()...")
        self:update_cache_id()
    end
    log.output("token-nxp-chipdoc-lite:set_attribute_value(): rv:", rv)
    return rv
    
end

function t.mt:set_attribute_value_privkey(hObj, pTemplate)
    log.output('token-nxp-chipdoc-lite:set_attribute_value_privkey()')
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    local obj = self.attributes[hObj]
    
    for k, v in pTemplate do
        if k ~= CKA.ID and k ~= CKA.LABEL and k ~= CKA.SUBJECT
            and k ~= CKA.START_DATE and k ~= CKA.END_DATE 
            and k ~= CKA.MODIFIABLE
            and k ~= CKA.DECRYPT and k ~= CKA.SIGN then
            return CKR.ATRIBUTE_TYPE_INVALID
        end
    end
    
    local templateNew = {}
    -- copia tutti gli attributi CKA_*
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if obj[k] then
            templateNew[k] = obj[k]
        end
    end
    for k, v in pTemplate do
        templateNew[k] = v
    end
    local fs = p15.parsePubPrivKD(self._indexes._private_keys_bin)
    if type(obj.num) ~= "number" or obj.num > table.getn(fs) then
        log.output('token-nxp-chipdoc-lite:set_attribute_value_privkey(): error: invalid obj.num:', obj.num)
        return CKR.FUNCTION_FAILED
    end
    if pTemplate[CKA.LABEL] or pTemplate[CKA.ID] then
        self.nxp_hcard:select_Generic()
        local v = fs[obj.num]
        v.commonObjectAttributes.label = pTemplate[CKA.LABEL] or v.commonObjectAttributes.label
        v.classAttributes.iD = pTemplate[CKA.ID] or v.classAttributes.iD
        local privKDBin = p15.buildPubPrivKD(fs, {subClassAttributes={}})
        privKDBin = privKDBin .. string.rep("\000", string.len(self._indexes._private_keys_bin) - string.len(privKDBin))
        if string.len(privKDBin) ~= string.len(self._indexes._private_keys_bin) then
            log.output('token-nxp-chipdoc-lite:set_attribute_value_privkey(): no more space left in Private KD file!')
            return CKR.DEVICE_MEMORY
        end
        self:_write_file(privKDBin, self.files.PrivKD)
        self._indexes._private_keys_bin = privKDBin
    end
    
    -- aggiorna i valori in cache
    for k, v in pTemplate do
        obj[k] = v
    end
    return CKR.OK
end



function t.mt:set_attribute_value_certificate(hObj, pTemplate)
    log.output('token-nxp-chipdoc-lite:set_attribute_value_certificate()')
    local obj = self.attributes[hObj]
    
    -- implementato come re-create: cancella il vecchio oggetto e lo ricrea coi nuovi attributi
    
    for k, v in pTemplate do
        if k ~= CKA.ID and k ~= CKA.LABEL and k ~= CKA.SUBJECT
            and k ~= CKA.ISSUER and k ~= CKA.SERIAL_NUMBER
            and k ~= CKA.MODIFIABLE and k ~= CKA.TRUESTED  then
            return CKR.ATRIBUTE_TYPE_INVALID
        end
    end

    local templateNew = {}
    -- copia tutti gli attributi CKA_*
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if obj[k] then
            templateNew[k] = obj[k]
        end
    end
    for k, v in pTemplate do
        templateNew[k] = v
    end
    local fs = p15.parseCertDF(self._indexes._certificates_bin)
    if type(obj.num) ~= "number" or obj.num > table.getn(fs) then
        log.output('token-nxp-chipdoc-lite:set_attribute_value_certificate(): error: invalid obj.num:', obj.num)
        return CKR.FUNCTION_FAILED
    end
    if pTemplate[CKA.LABEL] or pTemplate[CKA.ID] then
        self.nxp_hcard:select_Generic()
        local v = fs[obj.num]
        v.commonObjectAttributes.label = pTemplate[CKA.LABEL] or v.commonObjectAttributes.label
        v.classAttributes.iD = pTemplate[CKA.ID] or v.classAttributes.iD
        local certDF = p15.buildCertDF(fs)
        certDF = certDF .. string.rep("\000", string.len(self._indexes._certificates_bin) - string.len(certDF))
        if string.len(certDF) ~= string.len(self._indexes._certificates_bin) then
            log.output('token-nxp-chipdoc-lite:set_attribute_value_certificate(): no more space left in certDF file!')
            return CKR.DEVICE_MEMORY
        end
        self:_write_file(certDF, self.files.CDF)
        self._indexes._certificates_bin = certDF
    end
    
    -- aggiorna i valori in cache
    for k, v in pTemplate do
        obj[k] = v
    end
    return CKR.OK
end


function t.mt:set_attribute_value_pubkey(hObj, pTemplate)
    log.output('token-nxp-chipdoc-lite:set_attribute_value_pubkey()')
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    local obj = self.attributes[hObj]
    
    for k, v in pTemplate do
        if k ~= CKA.ID and k ~= CKA.LABEL and k ~= CKA.SUBJECT            
            and k ~= CKA.MODIFIABLE
            and k ~= CKA.START_DATE and k ~= CKA.END_DATE  then
            return CKR.ATRIBUTE_TYPE_INVALID
        end
    end

    local templateNew = {}
    -- copia tutti gli attributi CKA_*
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if obj[k] then
            templateNew[k] = obj[k]
        end
    end
    for k, v in pTemplate do
        templateNew[k] = v
    end
    local fs = p15.parsePubPrivKD(self._indexes._public_keys_bin)
    if type(obj.num) ~= "number" or obj.num > table.getn(fs) then
        log.output('token-nxp-chipdoc-lite:set_attribute_value_pubkey(): error: invalid obj.num:', obj.num)
        return CKR.FUNCTION_FAILED
    end
    if pTemplate[CKA.LABEL] or pTemplate[CKA.ID] then
        self.nxp_hcard:select_Generic()
        local v = fs[obj.num]
        v.commonObjectAttributes.label = pTemplate[CKA.LABEL] or v.commonObjectAttributes.label
        v.classAttributes.iD = pTemplate[CKA.ID] or v.classAttributes.iD
        local pubKDBin = p15.buildPubPrivKD(fs, {subClassAttributes={}})
        pubKDBin = pubKDBin .. string.rep("\000", string.len(self._indexes._public_keys_bin) - string.len(pubKDBin))
        if string.len(pubKDBin) ~= string.len(self._indexes._public_keys_bin) then
            log.output('token-nxp-chipdoc-lite:set_attribute_value_pubkey(): no more space left in Public KD file!')
            return CKR.DEVICE_MEMORY
        end
        self:_write_file(pubKDBin, self.files.PubKD)
        self._indexes._public_keys_bin = pubKDBin
    end
    
    -- aggiorna i valori in cache
    for k, v in pTemplate do
        obj[k] = v
    end
    return CKR.OK
end

function t.mt:get_special_ids(id_class)
    if id_class == 'DS' then
        local ids = {}
        for i=0,9 do
            table.insert(ids, string.format('DS%d', i))
        end
        return ids
    end
end


function t.mt:set_label(Puk, label)
    local rv = CKR.OK
    local info = self:get_info()
    log.output('token-nxp-chipdoc-lite:set_label():', Puk, label)
    local pcRes, theErrorT = pcall(function()
        
        self.nxp_hcard:select_Generic()
        local cia_infoD = self:read_cached_file(self.files.tokenInfo, 0, -1, true)
        local cia_info = p15.parse_tokenInfo(cia_infoD)
        if cia_info.label then
            label = string.sub(label, 1, string.len(cia_info.label))
            
            cia_info.label = label .. string.rep(" ", string.len(cia_info.label) - string.len(label))
            
            cia_infoD = p15.build_tokenInfo(cia_info)
            self:_write_file(cia_infoD, self.files.tokenInfo, 0)
            self:update_cache_id()
            
            info.label = cia_info.label
            log.output (string.format("token-nxp-chipdoc-lite:set_label(): label set to: '%s'", cia_info.label))
            
        end
  
    
    end)
    if not pcRes then
        log.output('token-nxp-chipdoc-lite:set_label(): error:', theErrorT)
        rv = CKR.FUNCTION_FAILED
    end
    return rv
end


return t



--===========================================================================
end
}
_LOADED['NXPChipDocLite'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
local p15util = require "p15util"
local aes = require 'aes'
local ecdhlib = require "ecdhlib"
local hex = require 'hex'
local util = require 'utility'
local repr = util.repr
local h2i, hexf, hexify = hex.h2i, hex.hexf, hex.hexify
local rsa = require("rsa")
local zlib = require 'zlib'
local der = require("der")

local JAVACARD_ALGS={
    ALG_ECDSA_SHA=17,
    ALG_ECDSA_SHA_224=37,
    ALG_ECDSA_SHA_256=33,
    ALG_ECDSA_SHA_384=34,
    ALG_ECDSA_SHA_512=38,
    ALG_RSA_MD5_PKCS1=11,
    ALG_RSA_MD5_PKCS1_PSS=22,
    ALG_RSA_MD5_RFC2409=16,
    ALG_RSA_RIPEMD160_ISO9796=12,
    ALG_RSA_RIPEMD160_ISO9796_MR=31,
    ALG_RSA_RIPEMD160_PKCS1=13,
    ALG_RSA_RIPEMD160_PKCS1_PSS=23,
    ALG_RSA_SHA_224_PKCS1=39,
    ALG_RSA_SHA_224_PKCS1_PSS=43,
    ALG_RSA_SHA_256_PKCS1=40,
    ALG_RSA_SHA_256_PKCS1_PSS=44,
    ALG_RSA_SHA_384_PKCS1=41,
    ALG_RSA_SHA_384_PKCS1_PSS=45,
    ALG_RSA_SHA_512_PKCS1=42,
    ALG_RSA_SHA_512_PKCS1_PSS=46,
    ALG_RSA_SHA_ISO9796=9,
    ALG_RSA_SHA_ISO9796_MR=30,
    ALG_RSA_SHA_PKCS1=10,
    ALG_RSA_SHA_PKCS1_PSS=21,
    ALG_RSA_SHA_RFC2409=15,
}

local Generic_AID = hex.hexf("E828BD080F014E585030")
local SSCD_AID = hex.hexf("E828BD080F014E585031")

local NXPChipDocLite = {JAVACARD_ALGS=JAVACARD_ALGS}
NXPChipDocLite.mt = {}
NXPChipDocLite.mt.__index = NXPChipDocLite.mt


NXPChipDocLite.User_CAN    = '12345'
NXPChipDocLite.User_CAN_ref    = 2 -- 1=MRZ, 2=CAN 
NXPChipDocLite.AC_ALWAYS = 0

NXPChipDocLite.MAX_TRANSMIT_BUFFER_SIZE = 100
NXPChipDocLite.ID_PIN = 3
NXPChipDocLite.SE_ID_WRITE = tonumber("30", 16)
NXPChipDocLite.SE_ID_USE = tonumber("31", 16)
NXPChipDocLite.ID_FINGERPRINT = 10 -- 0x0A
NXPChipDocLite.PIN_PADDING = 0
NXPChipDocLite.PADDING_CHAR = hex.hexf("FF")
NXPChipDocLite.ID_PUK = 6
NXPChipDocLite.PUK_PADDING = 0

NXPChipDocLite.NXPChipDocLiteError = {}
NXPChipDocLite.NXPChipDocLiteError.mt = {}
NXPChipDocLite.NXPChipDocLiteError.mt.__index = NXPChipDocLite.NXPChipDocLiteError.mt

function NXPChipDocLite.NXPChipDocLiteError.mt.__tostring(e)
    return "NXPChipDocLiteError: " .. (e.msg or '') .. ' ;SW=' .. hex.hexify(e.sw or '') 
end

function NXPChipDocLite.NXPChipDocLiteError.new(sw, msg)
    local e = msg .. ' ;sw=' .. hexify(sw or '')
    return e
end

function NXPChipDocLite.new(card)
    local self = {
                    MK=hex.hexf("C8".."12".."0".."FD82120".."1F77F18".."39D".."D886".."B05C".."F24".."F7".."E52".."66".."E5878".."92B".."F4C".."5E54".."C54".."A1553".."0"),
                    mw_mk="MI".."D" .. "WRC" .. "AN" .. "FF".."2A".."6D9".."159".."9D5".."6D4",
                    ID_PIN=NXPChipDocLite.ID_PIN,
                    PIN_PADDING=NXPChipDocLite.PIN_PADDING,
                    PADDING_CHAR=NXPChipDocLite.PADDING_CHAR,
                    ID_PUK=NXPChipDocLite.ID_PUK,
                    PUK_PADDING=NXPChipDocLite.PUK_PADDING,
                    
                    User_CAN=NXPChipDocLite.User_CAN,
                    User_CAN_ref=NXPChipDocLite.User_CAN_ref,
                    }
    self.card = card
    setmetatable(self, NXPChipDocLite.mt)
    return self
end

function NXPChipDocLite.mt:begin_transaction()
    self.card:begintransaction()
end

function NXPChipDocLite.mt:end_transaction()
    self._performed_mutual_auth = false
    self.card:endtransaction()
end

function NXPChipDocLite.mt:on_end_transaction()
    log.output('NXPChipDocLite:on_end_transaction()...')
    self._performed_mutual_auth = false
end

function NXPChipDocLite.mt:close_secure_channel()
    self.ActiveSM = false
    self._performed_mutual_auth = false
    self.ssc = nil
    self.sessENC = nil
    self.sessMAC = nil
end

local function compute_cmac(plaintext, key, IV)
    IV = IVS or string.rep('\0', 16)
    local ciphertext = aes.AES_CMAC(key, plaintext, string.len(plaintext))
    return string.sub(ciphertext, 1, 8)
end


function NXPChipDocLite.parse_tlv(tlv_struct)
    local len1 = string.len(tlv_struct)
    local i, tag, len
    local parsed_tlvs = {}
    for i=1, len1 do
        tag = string.byte(tlv_struct, i)
        len = string.byte(tlv_struct, i+1)
        parsed_tlvs[tag] = string.sub(tlv_struct, i+2, i+2+len-1)
        i = i+2+len-1
    end
    return parsed_tlvs
end

function NXPChipDocLite.parse_fci(fci)
    local fci1 = NXPChipDocLite.parse_tlv(fci)
    local fci2 = NXPChipDocLite.parse_tlv(fci1[98] or fci1[111]) -- 0x62 or 0x6F
    local size_value = fci2[128] or fci2[129]
    size_value = size_value and (string.rep("\0", 4- string.len(size_value)) .. size_value)
    
    local infos = {size=(size_value) and bin.unpack("%L", size_value),
                      filetype = fci2[130] and string.byte(fci2[130], 1),
                      options=fci2[130],
                      fid_n=fci2[131] and bin.unpack("%H", fci2[131]),
                      fid =fci2[131],
                      flags=fci2[133],
                      ac = fci2[134],
                      sm = fci2[135] or fci2[203] or fci2[139],
                      }
    return infos
end

function NXPChipDocLite.mt:select_applet(use_sm)
    local recv = self:sm_transmit(hex.hexf("00A4040007A0000002471001"), use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'select_applet error' ), 2)
    end
end

function NXPChipDocLite.mt:select_applet_cns(use_sm)
    local recv = self:sm_transmit(hex.hexf("00a404000CA000000530000B104001011B00"), use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'select_applet error' ), 2)
    end
end

function NXPChipDocLite.mt:select_MF(use_sm)
    return self:select(hex.hexf("3f00"), nil, use_sm)
end

function NXPChipDocLite.mt:select_p15(use_sm)
    local recv = self:sm_transmit(hex.hexf("00A4040C0AE828BD080F014E585030"), use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'select_p15 error' ), 2)
    end
end

function NXPChipDocLite.mt:select(path, relative, use_sm)
    local sw, recv, path1, relative_id
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    
    if type(relative) == "number" then
        relative_id = relative
    elseif relative then
        relative_id = 0
    else 
        relative_id = 8
    end
    local template_h, template_p = '00A4%B0002%H00', '00A4%B00%P00'
    log.output('select(): ', path and hexify(path))
    path1 = path
    if path1 == nil then
        recv = self:sm_transmit(hexf("00a40000"), use_sm)
        sw = string.sub(recv, -2, -1)
    elseif type(path)=='number' then
        recv = self:sm_transmit(hexf(template_h, relative_id, path1), use_sm)
        sw = string.sub(recv, -2, -1)
    else
        if path1 == hexf('3f00') then
            recv = self:sm_transmit(hexf('00A40000023f0000'), use_sm)
            sw = string.sub(recv, -2, -1)
        else
            if string.sub(path1, 1, 2) == hexf('3f00') then
                path1 = string.sub(path1, 3, -1)
                log.output('select(): ', hexify(path1))
            end
            recv = self:sm_transmit(hexf(template_p, relative_id, path1), use_sm)
            sw = string.sub(recv, -2, -1)
        end
    end
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'select Error'), 2)
    elseif string.len(recv) > 2 then
        return NXPChipDocLite.parse_fci(recv)
    end
end



-- local function parse_tlv_ber(data)
    -- local d = {}
    -- local i = 0
    -- local offset, le, tag
    -- local log_array = {}
    -- log.output("parse_tlv_ber():", hex.hexify(data or ""))
    -- while 1 do
        -- tag = string.byte(data, i+1)
        -- if tag == 127 then -- 0x7F
            -- i = i+1
            -- tag = (tag * 256) + string.byte(data, i+1)
        -- end
        -- le = string.byte(data, i+2)
        -- offset = 0
        -- if le > 127 then
           -- offset = (bin.flags(le) * bin.flags("0x0F")).asnumber
           -- local leS = string.sub(data, i+3, i+2+offset)
           -- leS = string.rep("\000", 4 - string.len(leS)) .. leS
           -- le = bin.unpack("%>%L", leS)
           -- i = i + offset
        -- end
        -- table.insert(log_array, string.format("TAG: %02x LEN:%d", tag, le))
        -- d[tag] = string.sub(data, i+3, i+2+le)
        
        -- i = i + le + 2
        -- if i >= string.len(data) then
            -- break
        -- end
    -- end
    -- log.output(table.concat(log_array, "; "))
    -- return d
-- end

local function sha256(data)
    local s = md.sha256()
    s:update(data)
    return s:final()
end


local function compute_cmac(plaintext, key, IV)
    IV = IVS or string.rep('\0', 16)
    local ciphertext = aes.AES_CMAC(key, plaintext, string.len(plaintext))
    return string.sub(ciphertext, 1, 8)
end

local function trim_pad_bn(data, padto)
    data = string.sub(data, -padto)
    data = string.rep("\000", padto - string.len(data)) .. data
    return data
end

-- local function pad_iso9797(data, padding_length)
    -- local l = string.len(data)
    -- local m = math.mod(l, padding_length)
    -- if l == 0 or m == 0 then
        -- return data
    -- end
    -- return data .. string.rep('\000', padding_length-m)
-- end

local function pad_iso9797_2(data, padding_length)
    local l = string.len(data)
    local m = math.mod(l, padding_length)
    local x = data .. "\128" .. string.rep('\000', padding_length-1-m)
    return x
    
end

local function unpad_iso9797_2(data, padding_length)
    local l = string.len(data)
    for i=1,padding_length do
        if string.byte(data, l-i+1) == 128 then
            return string.sub(data, 1, l-i)
        end
    end
end

-- local to_unpad = hex.hexf("B4F45B7E69A5F92BE8667B3DBBFE206F094089CF164A4A8320AB43F65DEA0E80")
-- print (hex.hexify(unpad_iso9797_2(to_unpad, 16)) )

-- local to_unpad = hex.hexf("B4F45B7E69A5F92BE8667B3DBBFE206F094089CF164A4A8320AB43F65DEA8000")
-- print (hex.hexify(unpad_iso9797_2(to_unpad, 16)) )

-- local to_unpad = hex.hexf("B4F45B7E69A5F92BE8667B3DBBFE206F80000000000000000000000000000000")
-- print (hex.hexify(unpad_iso9797_2(to_unpad, 16)) )

local function inc_ssc(ssc1)
    local ssc1_low = string.sub(ssc1, -3, -1)
    local ssc1_hi = string.sub(ssc1, 1, -4)
    local ssc1_low_num = bin.unpack("%>%L", "\000" .. ssc1_low)
    ssc1_low_num = ssc1_low_num +1
    ssc1_low = hex.hexf("%>%L", ssc1_low_num)
    
    local ssc = ssc1_hi .. string.sub(ssc1_low, -3, -1)
    log.output("SSC:+1", hex.hexify(ssc))
    return ssc
end


local function cypher(key, text, _IV)
    return aes.AES_CBC(key, text, true, _IV)
end

local function decypher(key, text, _IV)
    return aes.AES_CBC(key, text, false, _IV)
end

local function protectAPDU(ssc1, KSenc, KSmac, header, data_field, le, extended)
        
        -- 9303 parte 11  (9863 des  9873  aes (9862 des) (9872 aes))
        log.output ('header: ', hex.hexify(header))
        log.output ('data_field: ', hex.hexify(data_field))
        log.output ('le: ', hex.hexify(le))
        
        local cla_f = bin.flags(string.byte(header, 1))
        local ins = string.byte(header, 2)
        local EvenIns = math.mod(ins, 2) == 0
        local tag_97 = ""
        
        cla_f = cla_f * bin.flags("0xF0" )
        cla_f = cla_f + bin.flags("0x0C" )
        local padding_length = 16

        --   a) Increment SSC
        local extended_ssc = inc_ssc(ssc1)

        -- Mask Class and Pad command Header
        local UnpaddedCmdHeader = string.char(cla_f.asnumber) .. string.sub(header, 2, 4)
        log.output ('UnpaddedCmdHeader: ', hex.hexify(UnpaddedCmdHeader))

        -- Pad Data
        local Data = data_field
        log.output('Data: ', hex.hexify(Data))

        local CmdHeader = pad_iso9797_2(UnpaddedCmdHeader, padding_length)
        log.output ('CmdHeader: ', hex.hexify(CmdHeader))
        local iv, EncryptedData_bin, EncryptedData
        
        if string.len(Data) > 0 then
            local Pad_Data = pad_iso9797_2(Data, padding_length)
            log.output ('Pad_Data: ', hex.hexify(Pad_Data))
            log.output ('cypher ssc with KSenc: ', hex.hexify(extended_ssc), hex.hexify(KSenc))

            -- Encrypt with KSenc
            iv = string.sub(cypher(KSenc, extended_ssc), 1, 16)
            EncryptedData = cypher(KSenc, Pad_Data, iv)
            log.output ('EncryptedData: ', hex.hexify(EncryptedData))
        else
            EncryptedData = ''
        end
        if type(le) == "string" and string.len(le) >0 then  -- Commands with response (Le field not empty) have a protected Le-field (Tag 97) in the command data.
            if extended and string.len(le) <= 1 then
                le = string.rep("\0", 2 - string.len(le)) .. le
            end
            tag_97 = hex.hexf('97%P', le)
        end
        
        local M
        local DO87_85
        if string.len(Data) > 0 then
            local tagID = "85"  --  # For a command with odd INS, any command data is encrypted and capsulated in a Tag 85 without padding indicator
            local EncryptedDataE = EncryptedData
                if EvenIns then  -- For a command with even INS, any command data is encrypted and capsulated in a Tag 87 with padding indicator (01)
                -- Build 87 Tag
                tagID = "87"
                EncryptedDataE = '\001' .. EncryptedData
            end
            if string.len(EncryptedDataE) >= 256 then
                DO87_85 = hex.hexf(tagID..'82%>%H%S', string.len(EncryptedDataE), EncryptedDataE ) .. tag_97
            elseif string.len(EncryptedDataE) >= 128 then
                DO87_85 = hex.hexf(tagID..'81%P', EncryptedDataE ) .. tag_97
            else
                DO87_85 = hex.hexf(tagID..'%P', EncryptedDataE ) .. tag_97
            end
        else
            DO87_85 = tag_97
        end
        
        log.output ('DO87_85: ', hex.hexify(DO87_85))
        M = CmdHeader .. DO87_85
        log.output ('M: ', hex.hexify(M))
        
        local extended_ssc_M = extended_ssc .. M

        
        log.output ('extended_ssc_M: ', hex.hexify(extended_ssc_M))

        -- Compute MAC of M:
        --   1) Concatenate SSC and M and add padding:
        local N = pad_iso9797_2(extended_ssc_M, padding_length)
        log.output ('N: ', hex.hexify(N))

        --  2) Compute MAC over N with KSMAC:
        local CC = compute_cmac(N, KSmac)

        -- Build 8E Tag
        local DO8E = hex.hexf('8E%P', CC)

        log.output ('DO8E: ', hex.hexify(DO8E))

        --  Build ProtectedAPDU
        local protected_apdu_data = DO87_85 .. DO8E

        local _ext_len = string.len(protected_apdu_data)
        local ext_len
        if extended or _ext_len > 255 then
            extended=true
            ext_len = hex.hexf('00%H', _ext_len)
        else
            ext_len = hex.hexf('%B', _ext_len)
        end

        -- if extended then
            -- ext_len = '\0\0' .. ext_len
        -- end
        local ProtectedAPDU = UnpaddedCmdHeader .. ext_len .. protected_apdu_data .. (extended and "\0\0" or '\0')
        log.output ("ProtectedAPDU: ", hex.hexify(ProtectedAPDU))
        return ProtectedAPDU, extended_ssc, EvenIns

end


local function unprotectAPDUResponse(ssc1, keyEnc, keyMac, response)
    log.output("unprotectAPDUResponse():")
    if string.len(response) == 2 then
        log.output("unprotectAPDUResponse(): SW only response:", hex.hexify(response))
        return response, true, ssc1
    end
    local ssc = ssc1
    local data = string.sub(response, 1, -2)
    local SW1 = string.sub(response, -2, -1)
    log.output("SW1:", hex.hexify(SW1))
    local SW
    local DATATOMAC = ""
    local dec = ""
    local valid = false
    local responsedec = ""
    local i = 0
    log.output("data:", hex.hexify(data))
    while true do
        local tag = string.byte(data, i+1)
        local le = string.byte(data, i+2)
        local offset = 0
        if le > 127 then
           offset = (bin.flags(le) * bin.flags("0x0F")).asnumber
           local leS = string.sub(data, i+3, i+2+offset)
           leS = string.rep("\000", 4 - string.len(leS)) .. leS
           le = bin.unpack("%>%L", leS)
           i =  i + offset
        end
        log.output(string.format("TAG: %02x LEN:%d", tag, le) )
        if tag == 135 or tag == 133 then -- 0x87 or 0x85
            -- decrypt
            if ssc == ssc1 then
                ssc = inc_ssc(ssc)
            end
            local TODEC = string.sub(data, i+3, i+2+le)
            log.output("TAG 87 ENC:", hex.hexify(TODEC))
            
            if tag == 135 then
                TODEC = string.sub(TODEC, 2, -1)
            end
            local IV = string.sub(cypher(keyEnc, ssc), 1, 16)
            local dec = decypher(keyEnc, TODEC, IV)
            log.output("TAG 87 dec:", hex.hexify(dec))
            responsedec = responsedec .. unpad_iso9797_2(dec, 16)
            DATATOMAC = DATATOMAC .. string.sub(data, i-offset+1, i+2+le)
            log.output("DATATOMAC:", hex.hexify(DATATOMAC))
        elseif tag == 129 then -- 0x81
            -- plain text
            local PT = string.sub(data, i+3, i+2+le)
            log.output("TAG 81 PT:", hex.hexify(PT))
            responsedec = responsedec .. PT
            DATATOMAC = DATATOMAC .. string.sub(data, i-offset+1, i+2+le)
            log.output("DATATOMAC:", hex.hexify(DATATOMAC))
        elseif tag == 153 then -- 0x99
            -- SW
            assert (le == 2)
            SW = string.sub(data, i+3, i+2+le)
            log.output("TAG 99 SW:", hex.hexify(SW))
            DATATOMAC = DATATOMAC .. string.sub(data, i+1, i+2+le)
            log.output("DATATOMAC:", hex.hexify(DATATOMAC))
        elseif tag == 142 then -- 0x8e
            assert (le == 8)
            -- MAC
            if ssc == ssc1 then
                ssc = inc_ssc(ssc)
            end
            local MAC = string.sub(data, i+3, i+2+le)
            log.output("TAG 8E MAC:", hex.hexify(MAC))
            local toMAC = pad_iso9797_2(ssc .. DATATOMAC, 16)
            local MAC2 = compute_cmac(toMAC, keyMac)
            log.output("TAG 8E MAC2:", hex.hexify(MAC2))
            valid = (MAC2 == MAC)
            log.output("VALID:", valid)
            break
        else
            log.output("unknown TAG:", tag)
        end
        i = i + le+2
        if i >= string.len(data) then
            break
        end
    end
    if SW then
        responsedec = responsedec .. SW
    else
        responsedec = responsedec .. SW1
    end
    return responsedec, valid, ssc
end

local function parse_apdu(apdu)
    local header
    local LE = ""
    local data = ""
    local header = string.sub(apdu, 1, 4)
    local lc = string.byte(apdu, 5) or 0
    local data = string.sub(apdu, 6, -1)
    if string.len(apdu) == 4 then
        log.output("parse_apdu(): no data no LC")
        data=""
    elseif string.len(apdu) == 5 then
        LE = string.sub(apdu, -1, -1)
        log.output("parse_apdu(): no data, specified LE:", hex.hexify(LE))
        data=""
    elseif string.len(apdu) == 7 and lc == 0 then
        LE = string.sub(apdu, -2, -1)
        log.output("parse_apdu(): no data, specified extLE:", hex.hexify(LE))
        data=""
    else
        if lc == 0 and string.len(data) > 0 then
            lc = bin.unpack("%>%H", data)
            log.output("parse_apdu: data=", hex.hexify(data))
            log.output("parse_apdu: new LC=", lc)
            log.output("parse_apdu: len data=", string.len(data))
            assert(string.len(data) <= lc +4)
            if string.len(data) >= lc + 3 then
                LE = string.sub(data, lc+2-string.len(data), -1)
                log.output("parse_apdu: new LE=", hex.hexify(LE))
            end
            data = string.sub(data, 3, 3+lc-1)
            log.output("parse_apdu(): with extData, specified extLE:", hex.hexify(LE))
        elseif lc +1 == string.len(data) then
            LE = string.sub(data, -1, -1)
            log.output("parse_apdu(): with data, specified LE:", hex.hexify(LE))
            -- log.output("parse_apdu(): APDU:", hex.hexify(apdu))
            data = string.sub(data, 1, -2)
        end
    end
    return header, lc, data, LE
end

-- local header, lc, data, LE = parse_apdu(hex.hexf("8024008A02B000") )
-- print (hex.hexify(header), lc, hex.hexify(data), hex.hexify(LE))
-- local header, lc, data, LE = parse_apdu(hex.hexf("8024008A02B001"))
-- print (hex.hexify(header), lc, hex.hexify(data), hex.hexify(LE) )


function NXPChipDocLite.mt:SMTX(ssc, KskEnc, KskSig, apdu, forceExtended)
    local extended
    local header, lc, data, LE = parse_apdu(apdu)

    extended = forceExtended or string.len(LE) > 1 or lc > 255
    local encApdu, ssc = protectAPDU(ssc, KskEnc, KskSig, header, data, LE, extended)
    log.output( "SMTX: plainApdu: ", hex.hexify(apdu))
    log.output ("SMTX: encApdu SM:", hex.hexify(encApdu))
    log.output("ssc:", hex.hexify(ssc))
     local resp, valid
    resp = self:transmit(encApdu)
    log.output ("SMTX: resp:", hex.hexify(resp))
    resp, valid, ssc = unprotectAPDUResponse(ssc, KskEnc, KskSig, resp)
    log.output("resp:", hex.hexify(resp))

    return resp, valid, ssc
end


function NXPChipDocLite.mt:sm_transmit(apdu, use_sm, forceExtended)
    if not use_sm then
        return self:transmit(apdu)
    end
    if not self._performed_mutual_auth then
        self:auto_perform_mutual_authenticate()
    end
    local resp, valid, ssc = self:SMTX(self.ssc, self.KskEnc, self.KskSig, apdu, forceExtended)
    self.ssc = ssc or self.ssc
    self.last_sw = string.sub(resp, -2, -1)
    return resp, valid
end

function NXPChipDocLite.mt:transmit(apdu)
    log.output(">> APDU:", hex.hexify(apdu))
    local recv = self.card:transmit(apdu)
    log.output("<< RESP:", hex.hexify(recv))
    self.last_sw = string.sub(recv, -2, -1)
    return recv
end

function NXPChipDocLite.mt:read_binary(offset, size, use_sm)
    local recv
    
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    
    log.output("reading from:", offset, "size:", size)
    local apdu = hexf('00B0%H%B', offset, size)
    recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') and sw ~= hexf('6282') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'read_binary Error'), 2)
    end
    return string.sub(recv, 1, -3)
end

function NXPChipDocLite.mt:mread_binary(offset, size, use_sm)
    local buffer_size = NXPChipDocLite.MAX_TRANSMIT_BUFFER_SIZE
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output("multi reading from:", offset, "size:", size, "chunks:", buffer_size)
    local content = ''
    while size>0 do
        if size<buffer_size then buffer_size = size end
        local recv = self:read_binary(offset, buffer_size, use_sm)
        offset = offset  + buffer_size
        size = size - buffer_size
        content = content .. string.sub(recv, 1, buffer_size)
    end
    return content
end


function NXPChipDocLite.mt:mread_binary_smart(offset, size, use_sm)
    -- stops when a block of all zeroes is read back
    log.output("NXPChipDocLite:mread_binary_smart()")
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local buffer_size = NXPChipDocLite.MAX_TRANSMIT_BUFFER_SIZE
    log.output("NXPChipDocLite:mread_binary_smart:multi reading from:", offset, "size:", size, "chunks:", buffer_size)
    local content = ''
    local data
    while size>0 do
        if size<buffer_size then buffer_size = size end
        local recv = self:read_binary(offset, buffer_size, use_sm)
        if not recv or string.len(recv) == 0 then
            
            break
        end
        data = recv
        offset = offset  + string.len(data)
        size = size - string.len(data)
        content = content .. data
        log.output("NXPChipDocLite:mread_binary_smart: partial content:", hex.hexify(data))
        if data == string.rep("\0", string.len(data)) then
            log.output("NXPChipDocLite:mread_binary_smart: null content detected, stopping...")
            break
        end
    end
    log.output("NXPChipDocLite:mread_binary_smart:content:", hex.hexify(content))
    return content
end

function NXPChipDocLite.mt:read_cert(fid, use_sm)

    log.output('NXPChipDocLite:read_cert():', hex.hexify(fid), use_sm)
    
    use_sm = use_sm == nil and self.ActiveSM or use_sm

    self:select(fid, true, use_sm)
    local offset = 0
    local der_size = self:read_binary(offset, 4, use_sm)

    if string.sub(der_size, 1, 2) == hexf('3082') then
        local size = string.byte(der_size, 3) * 256 + string.byte(der_size, 4)
        local cert =  der_size .. self:mread_binary(offset+4, size, use_sm)        
        return cert
    elseif string.sub(der_size, 1, 2) == hexf('5a82') or string.sub(der_size, 1, 2) == hexf('7a82')  then  -- z|Z\x82 + sizeBE + compressed data
        local size = string.byte(der_size, 3) * 256 + string.byte(der_size, 4)
        log.output('read_cert(): using CPR mode: expected size:', size)
        local compr = self:mread_binary(offset+4, size, use_sm)        
        local decompr
        if string.sub(der_size, 1, 2) == hexf('7a82') then
            decompr = zlib.decompress2(compr, true, nil, nil)
        else
            decompr = zlib.decompress(compr, true, nil, nil)
        end
        return decompr
    else
        error('NXPChipDocLite:read_cert Error: bad certificate')
    end

end


function NXPChipDocLite.mt:auto_perform_mutual_authenticate(checkOnActiveSMOnly)
    -- funzione fondamentale per per il corretto uso del secure messaging
    -- ha lo scopi di:
    -- 1) individuare una mutua autenticazione valida gi