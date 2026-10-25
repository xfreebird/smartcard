 avvenuta usando un numero minimo di APDU
    -- 2) mantenere lo stato della mutua autenticazione come valido nell'ambito della medesima transazione
    -- 3) eseguire la mutua autenticazione solo se necessario
    local pcRes
    local res
    log.output("NXPChipDocLite:auto_perform_mutual_authenticate(): checkOnActiveSMOnly:", checkOnActiveSMOnly)
    if checkOnActiveSMOnly and not self.ActiveSM then
        log.output("NXPChipDocLite:auto_perform_mutual_authenticate(): SM not Active, nothing to do...")
        return false
    end
    if not self._performed_mutual_auth then
        if self.ssc and self.KskEnc and self.KskSig then
            local resp, valid, ssc = self:SMTX(self.ssc, self.KskEnc, self.KskSig, hex.hexf("00CA010000")) -- 0x0100 -  Applet name
            self.ssc = ssc or self.ssc
            local sw = string.sub(resp, -2, -1)
            if valid and sw == hexf('9000') then
                log.output("auto_perform_mutual_authenticate(): not needed: still valid channel!")
                self._performed_mutual_auth=true
                
                return false
            else
                 self.ActiveSM = false
                 log.output("NXPChipDocLite:auto_perform_mutual_authenticate(): channel not valid!")
            end
        end
        log.output("auto_perform_mutual_authenticate(): not performed, starting...")
        res = self:perform_mutual_authenticate()
        return res
    else
        log.output("auto_perform_mutual_authenticate(): not needed: inside same transaction!")
        return false
    end
end

local function calculate_pi_password_sha256(CAN)
    local first_step = md.sha256()
    first_step:update(CAN .. hex.hexf('00000003'))
    local k = first_step:final()
    log.output("calculate_pi_password_sha256(): k:", hex.hexify(k))
    
    return k
end


local function decrypt_can(MK, enc_can)
    
    
    local sn = string.sub(enc_can, -8, -1)
    --  1- build this message :
    local d1 = hex.hexf("00000000000000000000000400010001") .. sn
    
    -- 2-  Do a AES CMAC on these data using the Master Key
    local k1 = aes.AES_CMAC( MK, d1) -- 88FE65D987CB40C63BDE717C0616A538
    
    -- 3- build this message
    local d2 = hex.hexf("00000000000000000000000400010002") .. sn

    -- 4-  Do a AES CMAC on these data using the Master Key
    local k2 = aes.AES_CMAC( MK, d2) -- C57483C7331623A19D9F4F22C659F123
    

    -- 5- concatenate
    local k = k1 .. k2

    -- 6- concatenate CAN with zeroes.
    -- 31323334350000000000000000000000
    local can = sm.aes_dec_block(k, string.sub(enc_can, 1, 16))
    -- remvoe padding zeroes
    while string.byte(can, -1) == 0 do
        can = string.sub(can, 1, -2)
    end
    return can, sn
end


function NXPChipDocLite.mt:decrypt_nonce(nonce)
    local pi_password = calculate_pi_password_sha256(self.User_CAN)
    log.output ("pi_passwor for decrypt nonce:", hex.hexify(pi_password))
    local decrypted_nonce = aes.AES_CBC(pi_password, nonce, false, string.rep("\0", 16))
    return decrypted_nonce
end

function NXPChipDocLite.mt:perform_mutual_authenticate(pw_ref)
    
    pw_ref = pw_ref or self.User_CAN_ref
    log.output("perform_mutual_authenticate(): pw_ref=", pw_ref)
    self._performed_mutual_auth = false
    
    self:select_applet(false) -- no SM
    self:select_MF(false) -- no SM
    -- self:mse_load("03")

    -- read encrypted CAN from file E000
    if not self.PACE_RANDOM_CAN then
        log.output("perform_mutual_authenticate(): reading PACE_RANDOM_CAN from File E000...")
        local infos = self:select(hex.hexf("E000"), true)
        local enc_can = self:read_binary(0, 16+8)
        local dec_can, sn = decrypt_can(self.MK, enc_can)
        log.output("perform_mutual_authenticate(): PACE_RANDOM_CAN:", dec_can, hex.hexify(sn))
        self.PACE_RANDOM_CAN = dec_can
        self.User_CAN = dec_can
    else
        self.User_CAN = self.PACE_RANDOM_CAN
    end
    
    -- local info = self:select(hex.hexf("011C"), true) -- select Card Access 011C
    -- self:mread_binary(0, info.size)
    -- local recv = self:transmit(hex.hexf("00A4000002011c"))
    -- local sw = string.sub(recv, -2, -1)
    -- if sw ~= hexf('9000') then
        -- error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'set_at Error'), 2)
    -- end
    -- self:read_binary(0, 0)
    
    
    local PaceSelectedAlgorithm = hex.hexf("04007f00070202040204") -- brainpoolP256r1
    
    local set_at_data = hex.hexf('80%P8301%B', PaceSelectedAlgorithm, pw_ref)
    local set_at = hex.hexf("0022C1A4%P", set_at_data)
    log.output("set_at request: ", hex.hexify(set_at))
    
    local recv = self:transmit(set_at)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'set_at Error'), 2)
    end
    
    log.output ("****  General Authentication STEP 1 ****")
    
    -- CLA=10 (10 First step of PACE, 00 last step of PACE)
    -- INS=86
    -- P1=00 (Key and protocol implicitly know)
    -- P2=00 (Key and protocol implicitly know)
    -- Lc = 02 (DATA LENGTH)
    -- Data Field =
    --              7C (Tag -> Dynamic Authentication Data)
    --              00 (Length)
    -- Le = 00
    
    local apdu = hex.hexf("10860000027C0000")
    local recv = self:transmit(apdu)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'set_at Error'), 2)
    end
    
    local raw_nonce = NXPChipDocLite.parse_tlv(NXPChipDocLite.parse_tlv(recv)[124])[128]
    
    
    log.output("raw_nonce: ", hex.hexify(raw_nonce))
    
   
    local nonce_dec = self:decrypt_nonce(raw_nonce)
    log.output("nonce_dec: ", hex.hexify(nonce_dec))
    
    nonce_dec = bignum.create(nonce_dec, true)
     
    local curve = ecdhlib.get_curve("brainpoolP256r1")
    
    local Terminal_Private_Key, Terminal_Public_Key = curve.g:make_keypair(bignum.create("0x65537"))
    
    -- General Authentication STEP 2
    log.output ("****  General Authentication STEP 2 ****")

    -- CLA=10 (10 First step of PACE, 00 last step of PACE)
    -- INS=86
    -- P1=00 (Key and protocol implicitly know)
    -- P2=00 (Key and protocol implicitly know)
    -- Lc = xx (DATA LENGTH)
    -- Data Field =
    --              7C (Tag -> Dynamic Authentication Data)
    --              XX (Length)
    --              81 (TAG)
    --              XX ( LENGTH TAG)
    --              04 ( UNCOMPRESSED POINT)
    --              x coordinate
    --              y coordinate
    -- Le = 00
    
    
    local tag_81 = hex.hexf("81%P", Terminal_Public_Key:encode_point(true, 32))
    local tag_7c = hex.hexf("7C%P", tag_81)
    local gen_auth_2 = hex.hexf( "10860000%P00" , tag_7c)
    log.output("gen_auth_2:", hex.hexify(gen_auth_2))
    local recv = self:transmit(gen_auth_2)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'PACE step 2 Error'), 2)
    end
    local Mapping_Data = NXPChipDocLite.parse_tlv(NXPChipDocLite.parse_tlv(recv)[124])[130]

    log.output("Mapping_Data:", hex.hexify(Mapping_Data))

    local point = curve.g:decode_point(Mapping_Data, true)
    local ephemeralSecret = point:scalar_mult(Terminal_Private_Key)
    local mappedGenerator_multi = curve.g:scalar_mult(nonce_dec)
    local mappedGenerator = mappedGenerator_multi:point_add(ephemeralSecret)

    local ephemeral_curve_priv, ephemeral_curve = curve.g:make_keypair(bignum.create("0x65537"))
    
    log.output("ephemeral_curve:", ephemeral_curve)
    log.output("ephemeral_curve_priv:", ephemeral_curve_priv)
    
    local ephemeral_Public_Key = mappedGenerator:scalar_mult(ephemeral_curve_priv):encode_point(true, 32)
    local ephemeral_Private_Key = ephemeral_curve_priv:tostring(16, true)
    
    log.output("ephemeral_Public_Key:", hex.hexify(ephemeral_Public_Key))
    log.output("ephemeral_Private_Key:", ephemeral_Private_Key)
    
   --  CLA=10 (10 First step of PACE, 00 last step of PACE)
   -- INS=86
   -- P1=00 (Key and protocol implicitly know)
   -- P2=00 (Key and protocol implicitly know)
   -- Lc = xx (DATA LENGTH)
   -- Data Field =
   --              7C (Tag -> Dynamic Authentication Data)
   --              XX (Length)
   --              83 (TAG)
   --              XX ( LENGTH TAG)
   --              04 ( UNCOMPRESSED POINT)
   --              x coordinate
   --              y coordinate
   -- Le = 00

    local tag_83 = hex.hexf("83%P", ephemeral_Public_Key)
    local tag_7c = hex.hexf("7C%P", tag_83)
    local gen_auth_3 = hex.hexf( "10860000%P00" , tag_7c)
    log.output("gen_auth_3:", hex.hexify(gen_auth_3))
    local recv = self:transmit(gen_auth_3)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'PACE step 3 Error'), 2)
    end
    log.output("gen_auth_3 recv:", hex.hexify(recv))
    
    
    local Mapping_Data = NXPChipDocLite.parse_tlv(NXPChipDocLite.parse_tlv(recv)[124])[132]
    local ephemeralKeyPICC = curve.g:decode_point(Mapping_Data, true)
    local ephemeralSecret = ephemeralKeyPICC:scalar_mult(ephemeral_curve_priv)

    local Chip_Ephemeral_Public_Key = Mapping_Data
    log.output ("Chip_Ephemeral_Public_Key--> Returned step 3: ", hex.hexify(Chip_Ephemeral_Public_Key))

    local secretPoint_X = string.sub(ephemeralSecret:encode_point(false, 32), 1, 32)
    log.output ("secretPoint_X: ", hex.hexify(secretPoint_X))
    local secret = secretPoint_X

    local _kSenc = secret .. hex.hexf('00000001')
    local _kSmac = secret .. hex.hexf('00000002')
    log.output ("_kSenc =  secret + '00000001': ", hex.hexify(_kSenc))
    log.output ("_kSmac =  secret + '00000002': ", hex.hexify(_kSmac))

    
    local kSenc = sha256(_kSenc)
    local kSmac = sha256(_kSmac)
    
    log.output ("kSenc = sha256(_kSenc): ", hex.hexify(kSenc))
    log.output ("kSmac = sha256(_kSmac): ", hex.hexify(kSmac))

    local pkpicc_1 = Chip_Ephemeral_Public_Key
    local pkpicc_2 = hex.hexf("86%P", pkpicc_1)
    local pkpicc_3 = hex.hexf("06%P", PaceSelectedAlgorithm) .. pkpicc_2
    

    local tpcd = hex.hexf("7F49%P", pkpicc_3)
    log.output ("tpcd: ", hex.hexify(tpcd))

    local computedMac = compute_cmac(tpcd, kSmac)

    log.output ("computedMac with tpcd, kSmac: ", hex.hexify(computedMac))

    local rangedMac = string.sub(computedMac, 1, 8)
    log.output ("rangedMac=computedMac: ", hex.hexify(rangedMac))

    
        
-------------

    -- General Authentication STEP 4
    log.output ("****  General Authentication STEP 4 ****")

    -- CLA=10 (10 First step of PACE, 00 last step of PACE)
    -- INS=86
    -- P1=00 (Key and protocol implicitly know)
    -- P2=00 (Key and protocol implicitly know)
    -- Lc = xx (DATA LENGTH)
    -- Data Field =
    --              7C (Tag -> Dynamic Authentication Data)
    --              XX (Length)
    --              85 (TAG)
    --              XX ( LENGTH TAG)
    --              AUTH_TOKEN
    -- Le = 00

    local tag_85 = hex.hexf("85%P", rangedMac)
    local tag_7c = hex.hexf("7C%P", tag_85)
    local gen_auth_4 = hex.hexf( "00860000%P00" , tag_7c)
    log.output("gen_auth_4:", hex.hexify(gen_auth_4))
    local recv = self:transmit(gen_auth_4)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'PACE step 3 Error'), 2)
    end
    log.output("gen_auth_4 recv:", hex.hexify(recv))
    
    
    
    local Authentication_Token = NXPChipDocLite.parse_tlv(NXPChipDocLite.parse_tlv(recv)[124])[134]

    log.output ("Authentication_Token: ", hex.hexify(Authentication_Token))

    log.output("perform_mutual_authenticate(): completed")
    self._performed_mutual_auth = true
    self.ssc = string.rep("\0", 16)
    self.KskEnc, self.KskSig = kSenc, kSmac
    
    self.ActiveSM = true
    
    return true
end

function NXPChipDocLite.mt:get_ecdsa_parameters(curve, private_key)
    local key_bytes = curve.keysize

    local res = {
        key_bytes=key_bytes,
        p = trim_pad_bn(hex.hexf(curve.p:tostring(16, true)), key_bytes),
        a = trim_pad_bn(hex.hexf(curve.a:tostring(16, true)), key_bytes),
        b = trim_pad_bn(hex.hexf(curve.b:tostring(16, true)), key_bytes),
        Gx = trim_pad_bn(hex.hexf(curve.g.x:tostring(16, true)), key_bytes), -- coordinates x in F defining a curve point G
        Gy = trim_pad_bn(hex.hexf(curve.g.y:tostring(16, true)), key_bytes), -- coordinates y in F defining a curve point G
        n = trim_pad_bn(hex.hexf(curve.n:tostring(16, true)), key_bytes),
    }
    res.G = "\4" .. res.Gx .. res.Gy
    
    local encoded
    if private_key then
        encoded = hex.hexf("00%P" .. "00%P" .. "00%P" .. "00%P" .. "00%P" .. "0001" .. "00%P",
                res.p,
                res.a,
                res.b,
                res.G,
                res.n,
                private_key)
    end
    return res, encoded
end

function NXPChipDocLite.mt:get_security_status_flags(use_sm)

    local recv = self:sm_transmit(hex.hexf("00CA011900"), use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'get_security_status_flags error' ))
    end
    local secstatus = bin.unpack("%>%H", recv)
    return bin.flags(secstatus)    
end

function NXPChipDocLite.mt:is_pin_verified(ispuk, use_sm)
    local result = false
    log.output('NXPChipDocLite:is_pin_verified(): ispuk:', ispuk)
    log.output('NXPChipDocLite:is_pin_verified(): use_sm(1):', use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output('NXPChipDocLite:is_pin_verified(): use_sm(2):', use_sm)
    local bso = self.ID_PIN
    
    if ispuk then
        bso = self.ID_PUK
    end
    
    local secstatus = self:get_security_status_flags(use_sm)
    
    result = secstatus[bin.flags(2^bso)]
    log.output('NXPChipDocLite:is_pin_verified(): ', bso, result)
    return result
    
end

function NXPChipDocLite.mt:unverify_pin(ispuk, use_sm)

    local result = false
    log.output('NXPChipDocLite:unverify_pin(): ispuk:', ispuk)
    log.output('NXPChipDocLite:unverify_pin(): use_sm(1):', use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output('NXPChipDocLite:unverify_pin(): use_sm(2):', use_sm)
    local bso = self.ID_PIN
    
    if ispuk then
        bso = self.ID_PUK
    end
    
    
    local recv = self:sm_transmit(hex.hexf("00DA011902%>%H", bin.flags(2^bso).asnumber), use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'unverify_pin error' ))
    end
    
end

function NXPChipDocLite.mt:auto_verify_pin_main(pin, ispuk, use_sm)
    log.output('NXPChipDocLite:auto_verify_pin_main(): pin:', pin)
    log.output('NXPChipDocLite:auto_verify_pin_main(): ispuk:', ispuk)
    log.output('NXPChipDocLite:auto_verify_pin_main(): use_sm(1):', use_sm)
    
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output('NXPChipDocLite:auto_verify_pin_main(): use_sm(2):', use_sm)
    local bso = self.ID_PIN
    local padding = self.PIN_PADDING
    
    if ispuk then
        bso = self.ID_PUK
        padding = self.PUK_PADDING
    end
    
    local secstatus = self:get_security_status_flags(use_sm)
    
    if secstatus[bin.flags(2^bso)] then
        log.output('NXPChipDocLite:auto_verify_pin_main(): PIN ID already verified:', bso, secstatus)
        return 0
    end
    if string.len(pin)< padding then
        pin = pin .. string.rep(self.PADDING_CHAR, padding - string.len(pin))
    end
    
    log.output('NXPChipDocLite:auto_verify_pin_main(): PIN ID not verified:', bso, secstatus)
    return self:verify(bso, pin, true, use_sm)
end

function NXPChipDocLite.mt:verify_pin_main(pin, ispuk, use_sm)
    log.output('NXPChipDocLite:verify_pin_main(): pin:', pin)
    log.output('NXPChipDocLite:verify_pin_main(): ispuk:', ispuk)
    log.output('NXPChipDocLite:verify_pin_main(): use_sm(1):', use_sm)
    
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output('NXPChipDocLite:verify_pin_main(): use_sm(2):', use_sm)
    local bso = self.ID_PIN
    local padding = self.PIN_PADDING
    
    if ispuk then
        bso = self.ID_PUK
        padding = self.PUK_PADDING
    end
    
    if string.len(pin)< padding then
        pin = pin .. string.rep(self.PADDING_CHAR, padding - string.len(pin))
    end

    return self:verify(bso, pin, true, use_sm)
end


function NXPChipDocLite.mt:verify(bso, pin, backtracking, use_sm)
    log.output("NXPChipDocLite:verify():" )
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    if backtracking == nil then
        backtracking = true
    end
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
        log.output('NXPChipDocLite:verify(): Error ' .. hexify(sw) )
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'verify Error' ))
    end
end


function NXPChipDocLite.mt:change_pin_main(oldPin, newPin, ispuk, use_padding, use_sm)
    log.output('NXPChipDocLite:change_pin_main():', oldPin, newPin, ispuk, use_padding, use_sm  )
    local bso = self.ID_PIN
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    
    local padding = self.PIN_PADDING
    if ispuk then
        bso = self.ID_PUK
        padding = self.PUK_PADDING
    end
    
    
    if string.len(oldPin) < padding then
        log.output('NXPChipDocLite:change_pin_main(): using padding on old pin:', padding)
        oldPin = oldPin .. string.rep(self.PADDING_CHAR, padding - string.len(oldPin))
    end
    
    local res  = self:auto_verify_pin_main(oldPin, ispuk, use_sm)
    
    if res == 0 then
        if use_padding then
            if string.len(newPin) < padding then
                log.output('NXPChipDocLite:change_pin_main(): using padding on new pin:', padding)
                newPin = newPin .. string.rep(self.PADDING_CHAR, padding - string.len(newPin))
            end
        end 
        
        res = self:change(bso, newPin, true, use_sm)
        if res == 0 then
            log.output('change_pin_main(): calling verify_pin_main():...' )
            res = self:verify_pin_main(newPin, ispuk, use_sm)
        end
    end
    return res
end


function NXPChipDocLite.mt:change(bso, newPin, backtracking, use_sm)
    log.output("NXPChipDocLite:change()")
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    if backtracking then
        bso = (bin.flags(bso) + bin.flags(128)).asnumber
    end
	local mode = 1
    local sw = self:sm_transmit(hexf('0024%B%B%P', mode, bso, newPin), use_sm)
    if sw == hexf('6983')  or sw == hexf('6984') then
        return 2, 'Authentication blocked'
    elseif sw == hexf('6700') or bin.mask_compare(sw, hexf('6300'), hexf('FF00')) then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        return 0, 'Authentication succeeded'
    else
        log.output('change(): Error ' .. hexify(sw) )
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'change Error' ))
    end
end



function NXPChipDocLite.mt:reset_pin_main(Puk, newPin, use_padding, use_sm)
    local res
    log.output('NXPChipDocLite:reset_pin_main():', Puk, newPin, use_padding, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm

    local puk_padding = self.PIN_PADDING
    local pin_padding = self.PUK_PADDING
    
    if string.len(Puk) < puk_padding then
        log.output('NXPChipDocLite:reset_pin_main(): using padding on puk:', puk_padding)
        Puk = Puk .. string.rep(self.PADDING_CHAR, puk_padding - string.len(Puk))
    end
    
    if use_padding then
        if string.len(newPin) < pin_padding then
            log.output('NXPChipDocLite:reset_pin_main(): using padding on new pin:', pin_padding)
            newPin = newPin .. string.rep(self.PADDING_CHAR, pin_padding - string.len(newPin))
        end
    end
    
    res = self:verify_pin_main(Puk, true, use_sm)
    if res ~= 0 then
        log.output('NXPChipDocLite:reset_pin_main(): verify_pin_main() error:', res)
        return res 
    end
    res =  self:reset_retry_counter(self.ID_PIN, true, use_sm) -- bso, backtracking, use_sm

    if res ~= 0 then
        log.output('NXPChipDocLite:reset_pin_main(): reset_retry_counter() error:', res)
        return res 
    end

    res = self:change(self.ID_PIN, newPin, true, use_sm) -- bso, newPin, backtracking, use_sm
    
    if res ~= 0 then
        log.output('NXPChipDocLite:reset_pin_main(): change() error:', res)
        return res 
    end
    
    return res
end


function NXPChipDocLite.mt:reset_retry_counter(bso, backtracking, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output("NXPChipDocLite:reset_retry_counter()", bso, backtracking, use_sm)
    if backtracking then
        bso = (bin.flags(bso) + bin.flags(128)).asnumber
    end
    local mode = 3
    
    local sw = self:sm_transmit(hexf('002C%B%B00', mode, bso), use_sm)
    if sw == hexf('6983')  or sw == hexf('6984') then
        return 2, 'Authentication blocked'
    elseif sw == hexf('6700') or bin.mask_compare(sw, hexf('6300'), hexf('FF00')) then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        return 0, 'Authentication succeeded'
    else
        log.output('reset_retry_counter(): Error ' .. hexify(sw) )
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'reset_retry_counter Error' ))
    end
end

function NXPChipDocLite.mt:delete_key(id, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    return self:delete_object(tonumber("0a", 16), id, use_sm)
end

function NXPChipDocLite.mt:delete_file(id, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    return self:delete_object(0, id, use_sm)
end


function NXPChipDocLite.mt:delete_object(obj_type, id, use_sm)
    local id_n
    if type(id) == "number" then
        id_n = id
    elseif type(id) == "string" then
        if string.len(id) == 1 then
            id_n = string.byte(id, 1)
        elseif string.len(id) == 2 then
            id_n = bin.unpack("%>%H", id)
        elseif string.len(id) >= 4 then
            id_n =  bin.unpack("%>%H", hex.hexf(id))
        end
    end
    local recv = self:sm_transmit(hex.hexf("00e4%B0002%>%H", obj_type, id_n), use_sm)
    
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        return false
    end
    return true
end

function NXPChipDocLite.mt:create_rsa_key(sign_only, id, key_bits, ac_use, ac_change, ac_delete, non_repudiation, use_sm)
    -- RSA solo firma: 0xC0 + id
    -- RSA decifra: 0x80 + id
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local id_n
    if type(id) == "number" then
        id_n = id
    elseif type(id) == "string" then
        if string.len(id) == 1 then
            id_n = string.byte(id, 1)
        elseif string.len(id) >= 2 then
            id_n =  string.byte(hex.hexf(id), 1)
        end
    end
    
    if sign_only then
        id_n = tonumber("C0", 16) + id_n
        if type(non_repudiation) ~= "number" then
            non_repudiation = non_repudiation and 1 or 0
        end
        
    else
        id_n = tonumber("80", 16) + id_n
        non_repudiation = 0
    end
    
    self:create_key(6, id_n, key_bits, ac_use, ac_change, ac_delete, non_repudiation, use_sm)
    
end

function NXPChipDocLite.mt:create_ecdsa_key(id, key_bits, ac_use, ac_change, ac_delete, non_repudiation, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local id_n
    if type(id) == "number" then
        id_n = id
    elseif type(id) == "string" then
        if string.len(id) == 1 then
            id_n = string.byte(id, 1)
        elseif string.len(id) >= 2 then
            id_n =  string.byte(hex.hexf(id), 1)
        end
    end
    if type(non_repudiation) ~= "number" then
        non_repudiation = non_repudiation and 1 or 0
    end
    
    id_n = tonumber("C0", 16) + id_n
    self:create_key(tonumber("0C", 16), id_n, key_bits, ac_use, ac_change, ac_delete, non_repudiation, use_sm)
end

function NXPChipDocLite.mt:create_key(key_type_n, id_n, key_bits, ac_use, ac_change, ac_delete, non_repudiation, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    ac_use = ac_use or 0
    ac_change = ac_change or 0
    ac_delete = ac_delete or 0
    non_repudiation = non_repudiation or 0
    
    local apdu = hex.hexf("80E002000B%B%B%>%H%B%B%B%B%B%B%B", id_n, key_type_n, key_bits,
        ac_use, ac_change, ac_delete, ac_use, ac_change, ac_delete,
        non_repudiation
    )
    
    local recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'create_key error' ))
    end
end

function NXPChipDocLite.mt:import_key_rsa(id, p, q, iq, dp, dq, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local components = {
        {value=p},  {value=q},  {value=iq},  {value=dp},  {value=dq}
    }
    local id_n
    if type(id) == "number" then
        id_n = id
    elseif type(id) == "string" then
        if string.len(id) == 1 then
            id_n = string.byte(id, 1)
        elseif string.len(id) >= 2 then
            id_n =  string.byte(hex.hexf(id), 1)
        end
    end
    return self:import_key(6, id_n, components, use_sm)
end

function NXPChipDocLite.mt:import_key_ecdsa(id, curve, privKey, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local id_n
    if type(id) == "number" then
        id_n = id
    elseif type(id) == "string" then
        if string.len(id) == 1 then
            id_n = string.byte(id, 1)
        elseif string.len(id) >= 2 then
            id_n =  string.byte(hex.hexf(id), 1)
        end
    end
    local privKeyEncoded = privKey
    if type(privKey) =="userdata" then
        privKeyEncoded = ecdhlib.trim_pad_bn(hex.hexf(privKey:tostring(16, true)), curve.keysize) 
    end
    local paramsMap, params = self:get_ecdsa_parameters(curve, privKeyEncoded)
    
    local components = {{value=params, fixed=true}}
    
    return self:import_key(tonumber("0c", 16), id_n, components, use_sm)
end

function NXPChipDocLite.mt:import_key(key_algo_n, id_n, components, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    ac_use = ac_use or 0
    ac_change = ac_change or 0
    ac_delete = ac_delete or 0
    
    id_n = tonumber("80", 16) + id_n
    local data = "" -- "0080DCD00634B0011592B0257B85108C8F68B02858583BA91D1049784F093CAED57C4D4F054DE1F4FC670FE34AD132F8C120B6F352AC7D98D49151010A6CC043100F9B889AE164243C7215DD34DC2E1EC09D329F42D8BCC1F9AEE22556EEE4BCC66C613237B6F9580793E64174610FAC214790666306A0C8E5958F7CCF7841DFB6630080C70F9D252305E5A937FDEC084A7F1D35EEB781CF072E30FDEDCA64A057D51168C898A741DA46E9F6ED2A827831197FBE8274A2C9557475CFB7FDC72D2E6130FA691DD4DA25F58D339E8875ADF85C8DA3FCDE5EC7790A69968C22920183F4090902CE775E80B68788050812CB33FDE14F382517F770C002EACE3EAE60F450162F008077182F39A2BDC4B0339EFBA4A85B1A7EDCE2D4F5B95C995C43E2C20C384E796B9E9722E87D8698B10E802DD47EDDCD5956ED5C9FC112F1514C84F67BCA17A84DA65B0D529D9D63E894E4702CF2A9CA67742D9CF580BDF74C896A4C073AD27078EFCE67DCF669A730C543D3DD49BD2DB61FFF8E091A0CC6F96BC989AB14CB439700809B7E09C0B4682F0EDAE7AA31ABD3AF71230B661ACBF86CB4F967B51066211FC8A6900CC62965E10F9A4A8E76FE93D93BF6592650BD2910173C99A503ABE80DB94FE744598FB14CB771DA11CD32D509022991A8FB0300FD983F3BD819E60D611514E4CE031556FE0F1247E972281D285A42BF36E085FCB25F3D69C097889BC6CD0080501F85C62BE9B4BE3F0E52D2278230B4C3A853748C54585DED37B8F71D4362E58550848A2A1CBF11A7F6A35B53900AEE18BE6FC39044F722ABD157396560B381278C5D5F8D45E016F5E9C14C4C1A9CDC73ECE1C37281F16C2A6DC3CD1E5ABCC446BFEA263CB2BBACD131A5B6EAEF76A0175E3EDE5720C24BD6C63E14426275FB"
    

    for i=1,table.getn(components) do
        local c = components[i]
        if c.fixed then
            data = data .. c.value
        else
            data = data .. hex.hexf("%>%H", string.len(c.value)).. c.value
        end
    end
    
    data = string.char(key_algo_n) .. data
    local apdu = hex.hexf("802400%B00%>%H", id_n, string.len(data)) .. data
    
    local recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'create_key error' ))
    end
end

function NXPChipDocLite.mt:import_fingerprint(finger_id_n, bdt, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    
    finger_id_n = finger_id_n or 0
    local bdt_data = ""
    local bit_data = ""
    
    assert (finger_id_n >= 0 and finger_id_n < 10)
    
    local bit = hex.hexf("7F6081%B800100830100A1178101088201008702010188020005B10786020B0C870115", 
        string.len(bdt) + 31)
   
    bit_data = hex.hexf("B0%B", finger_id_n) .. bit
    bdt_data = hex.hexf("B0%B", finger_id_n) .. bdt
    local apdu_bit = hex.hexf("802400%B%P", 128+NXPChipDocLite.ID_FINGERPRINT, bit_data)
    
    local recv = self:sm_transmit(apdu_bit, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'import_fingerprint BIT error' ))
    end
    
    local apdu_bdt = hex.hexf("802400%B%P", 128+NXPChipDocLite.ID_FINGERPRINT, bdt_data)
    local recv = self:sm_transmit(apdu_bdt, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'import_fingerprint BDT error' ))
    end
end

function NXPChipDocLite.mt:delete_fingerprint(finger_id_n, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    
    finger_id_n = finger_id_n or 0
    local bit_data = ""
    
    assert (finger_id_n >= 0 and finger_id_n < 10)

    bit_data = hex.hexf("B0%B", finger_id_n)

    local apdu_bit = hex.hexf("802400%B%P", 128+NXPChipDocLite.ID_FINGERPRINT, bit_data)
    
    -- GAM: added forceExtended=true to avoid invalid data (sw=6981) with finger_id_n=0
    local recv = self:sm_transmit(apdu_bit, use_sm, true) 
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') and sw ~= hexf('6a88')  then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'delete_fingerprint error' ))
    end
    
end

function NXPChipDocLite.mt:verify_fingerprint(bdt, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm

    local apdu_verify = hex.hexf("00200F%B%P", 128+NXPChipDocLite.ID_FINGERPRINT, bdt)
    
    local recv = self:sm_transmit(apdu_verify, use_sm)
    local sw = string.sub(recv, -2, -1)

    if sw == hexf('6983') then
        return 2, 'Authentication blocked'
    elseif sw == hexf('6700') or string.sub(hexify(sw), 1, 2) == '63' then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        return 0, 'Authentication succeeded'
    else
        log.output('NXPChipDocLite:verify_fingerprint(): Error ' .. hexify(sw) )
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'verify_fingerprint Error' ))
    end
    
end


function NXPChipDocLite.mt:pso_cds_rsa(data, id, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local id_n
    local algo_id = 0
    if type(id) == "number" then
        id_n = id
    elseif type(id) == "string" then
        if string.len(id) == 1 then
            id_n = string.byte(id, 1)
        elseif string.len(id) >= 2 then
            id_n =  string.byte(hex.hexf(id), 1)
        end
    end
    if string.len(data) == 16 then
        algo_id = JAVACARD_ALGS.ALG_RSA_MD5_PKCS1
    elseif string.len(data) == 20 then
        algo_id = JAVACARD_ALGS.ALG_RSA_SHA_PKCS1
    elseif string.len(data) == 32 then
        algo_id = JAVACARD_ALGS.ALG_RSA_SHA_256_PKCS1
    elseif string.len(data) == 48 then
        algo_id = JAVACARD_ALGS.ALG_RSA_SHA_384_PKCS1
    elseif string.len(data) == 64 then
        algo_id = JAVACARD_ALGS.ALG_RSA_SHA_512_PKCS1
    else
        error('pso_cds_rsa: unsupported hash type')
    end
    
    id_n = tonumber("80", 16) + id_n
    local recv = self:sm_transmit(hex.hexf("002281B6049102%B%B", algo_id, id_n), use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'pso_cds_rsa(): MSE error' ))
    end

    local recv = self:sm_transmit(hex.hexf("002A9E9A00%>%H%S0000", string.len(data), data), use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'pso_cds_rsa(): PSO SIGN error' ))
    end
    
    return string.sub(recv, 1, -3)
end

function NXPChipDocLite.mt:pso_cds_ecdsa(data, id, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local id_n
    local algo_id = 0
    if type(id) == "number" then
        id_n = id
    elseif type(id) == "string" then
        if string.len(id) == 1 then
            id_n = string.byte(id, 1)
        elseif string.len(id) >= 2 then
            id_n =  string.byte(hex.hexf(id), 1)
        end
    end
    if string.len(data) < 20 then
        algo_id = JAVACARD_ALGS.ALG_ECDSA_SHA_256
    elseif string.len(data) == 20 then
        algo_id = JAVACARD_ALGS.ALG_ECDSA_SHA
    elseif string.len(data) <= 32 then
        algo_id = JAVACARD_ALGS.ALG_ECDSA_SHA_256
    elseif string.len(data) <= 48 then
        algo_id = JAVACARD_ALGS.ALG_ECDSA_SHA_384
    else
        algo_id = JAVACARD_ALGS.ALG_ECDSA_SHA_512
    -- else
        -- error('pso_cds_ecdsa: unsupported hash type')
    end
    
    id_n = tonumber("80", 16) + id_n
    local recv = self:sm_transmit(hex.hexf("002281B6049102%B%B", algo_id, id_n), use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'pso_cds_ecdsa(): MSE error' ))
    end

    local recv = self:sm_transmit(hex.hexf("002A9E9A00%>%H%S0000", string.len(data), data), use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'pso_cds_ecdsa(): PSO SIGN error' ))
    end
    
    return string.sub(recv, 1, -3)
end


function NXPChipDocLite.mt:pso_dec_rsa(data, id, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local id_n
    local algo_id = 0
    if type(id) == "number" then
        id_n = id
    elseif type(id) == "string" then
        if string.len(id) == 1 then
            id_n = string.byte(id, 1)
        elseif string.len(id) >= 2 then
            id_n =  string.byte(hex.hexf(id), 1)
        end
    end

    -- id_n = tonumber("80", 16) + id_n
    
    local recv = self:sm_transmit(hex.hexf("002241B8038301%B", id_n), use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'pso_dec_rsa(): MSE error' ))
    end
    
    local recv = self:sm_transmit(hex.hexf("002A808600%>%H%S0000", string.len(data), data), use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'pso_cds_rsa(): PSO SIGN error' ))
    end
    
    return string.sub(recv, 1, -3)
end

function NXPChipDocLite.mt:generate_key_pair(id, use_sm)
    -- generate key pair
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local id_n
    if type(id) == "number" then
        id_n = id
    elseif type(id) == "string" then
        if string.len(id) == 1 then
            id_n = string.byte(id, 1)
        elseif string.len(id) >= 2 then
            id_n =  string.byte(hex.hexf(id), 1)
        end
    end
    local recv = self:sm_transmit(hex.hexf("004600%B000000", id_n), use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'generate_key_pair(): error' ))
    end
    
    return string.sub(recv, 1, -3)
end


function NXPChipDocLite.mt:create_binary_file(id, size, ac_read, ac_write, ac_delete, use_sm)

    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local id_n
    if type(id) == "number" then
        id_n = id
    elseif type(id) == "string" then
        if string.len(id) == 1 then
            id_n = string.byte(id, 1)
        elseif string.len(id) == 2 then
            id_n = bin.unpack("%>%H", id)
        elseif string.len(id) >= 4 then
            id_n =  bin.unpack("%>%H", hex.hexf(id))
        end
    end
    
    ac_read = ac_read or 0
    ac_write = ac_write or 0
    ac_delete = ac_delete or 0
    
    local data = hex.hexf("8002%>%H8201018302%>%H8603%B%B%B", size, id_n, ac_read, ac_write, ac_delete)
    data = hex.hexf("62%P", data)
    local apdu = hex.hexf("00E00000%P", data)
    
    local recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'create_binary_file error' ))
    end
end

function NXPChipDocLite.mt:get_pin_puk_status(use_sm)
    
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    
    local pinRetry, pukRetry = 0, 0
    local apdu = hex.hexf("002000%B00", 128 + self.ID_PIN)
    local recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    local fF = bin.flags("0x0F")
    if string.sub(sw, 1, 1) == hexf('63') then
        pinRetry = (bin.flags(string.byte(sw, 2)) * fF).asnumber 
    end
    
    local apdu = hex.hexf("002000%B00", 128 + self.ID_PUK)
    local recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    
    if string.sub(sw, 1, 1) == hexf('63') then
        pukRetry = (bin.flags(string.byte(sw, 2)) * fF).asnumber
    end
    
    return pinRetry, pukRetry
end

function NXPChipDocLite.mt:get_free_mem(use_sm)
    
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    
    local free_mem = 0
    local apdu = hex.hexf("00CA011C00")
    local recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw == hexf('9000') then
        free_mem = bin.unpack("%>%L", recv)
    end
    
    return free_mem
end


local cachable_attributes = {
}

function NXPChipDocLite.mt:get_cachable_dict()
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

function NXPChipDocLite.mt:set_cachable_dict(cache)

    for i=1,table.getn(cachable_attributes) do
        local attr = cachable_attributes[i]
        if type(cache[attr]) == "string" then
            self[attr] = hex.hexf(cache[attr])
        else
            self[attr] = cache[attr] or self[attr]
        end
        log.output(string.format('NXPChipDocLite:set_cachable_dict(): restored "%s" -> "%s"', attr, hex.hexify(self[attr] or "") ))
    end
    
end


function NXPChipDocLite.mt:read_serial_number(force, use_sm)
    
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output("NXPChipDocLite:read_serial_number(): force=", force)
    if not self.CSN or force then
        log.output("NXPChipDocLite:read_serial_number(): reading..." )
        
        local read_csn = hex.hexf("00CA011400")
        local resp = self:sm_transmit(read_csn, use_sm)
        local sw = string.sub(resp, -2, -1)
        
        if sw ~= hexf('9000') then
            log.output("NXPChipDocLite:read_serial_number(): try reselecting main CD APPLET...")
            self:select_applet()
            self:select_MF()
            resp = self:sm_transmit(read_csn, use_sm)
            sw = string.sub(resp, -2, -1)
        end
         
        if sw ~= hexf('9000')then
            error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'read_serial_number error' ))
        end
        self.CSN = hex.hexify(string.sub(resp, 1, 8))
    else
        log.output("NXPChipDocLite:read_serial_number(): cached!" )
    end
    log.output("NXPChipDocLite:read_serial_number():", hex.hexify(self.CSN) )
    return self.CSN
end


function NXPChipDocLite.mt:select_AID(aid, use_sm)
    log.output("NXPChipDocLite:select_AID():", hex.hexify(aid), use_sm)
    log.output("NXPChipDocLite:select_AID(): self.ActiveSM", self.ActiveSM)
    use_sm = use_sm == nil and self.ActiveSM or use_sm

    self._current_selected_aid = nil
    local apdu = hex.hexf("00a40404%P00", aid)
    
    local recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw == hexf('6D00') or sw == hexf('6a86') or sw == hexf('6a82') then
        log.output("NXPChipDocLite:select_AID(): try reselecting main CD APPLET...")
        
        recv = self:select_applet(use_sm)
        
        if not use_sm then
            log.output("NXPChipDocLite:select_AID(): retransmit PLAIN select AID...")
            recv = self:sm_transmit(apdu, false)
            sw = string.sub(recv, -2, -1)
        else
            log.output("NXPChipDocLite:select_AID(): force retransmit select AID after rebuild SM session...")
            sw = hexf('6988')
        end
    end
    if sw == hexf('6988') and use_sm then
        log.output("NXPChipDocLite:select_AID(): SM session invalid?")
        if self:perform_mutual_authenticate(aid) then
            log.output("NXPChipDocLite:select_AID(): retry sending APDU...")
            recv = self:sm_transmit(apdu, use_sm)
            sw = string.sub(recv, -2, -1)
        end
    end
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'select_AID error' ))
    end
    self._current_selected_aid = aid
end

function NXPChipDocLite.mt:select_Generic(use_sm)
    log.output("NXPChipDocLite:select_Generic():", use_sm)
    self:select_AID(Generic_AID, use_sm)
end

function NXPChipDocLite.mt:select_SSCD(use_sm)
    log.output("NXPChipDocLite:select_SSCD():", use_sm)
    self:select_AID(SSCD_AID, use_sm)
end


function NXPChipDocLite.mt:read_binary_sfi(sfi, offset, size, use_sm)
    log.output('NXPChipDocLite:read_binary_sfi():', sfi, offset, size)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    
    offset = offset or 0

    local apdu = hex.hexf("00B0%B%B00%>%H", 128 + sfi, offset, size)    
    local recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hex.hexf("9000") and sw ~= hex.hexf("6282") then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'read_binary_sfi Error' ))
    end
    return string.sub(recv, 1, -3)
end


function NXPChipDocLite.mt:update_binary(offset, data, use_sm, sfi)
    local recv
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    
    local p1p2
    if sfi then
        sfi = 128+sfi
        p1p2 = hex.hexf("%B%B", sfi, offset)
    else
        p1p2 = hex.hexf("%H", offset)
    end
    local size = string.len(data)
    log.output("NXPChipDocLite:update_binary(): writing to:", offset, "size:", size, "sfi:", sfi)
    
    local apdu = hex.hexf("00d6%S%P", p1p2, data)

    recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPChipDocLite.NXPChipDocLiteError.new(sw, 'update_binary Error'))
    end
end

function NXPChipDocLite.mt:mupdate_binary(offset, data, use_sm, sfi, padding_blocks)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output("NXPChipDocLite:mupdate_binary(): offset=", offset, "sfi=", sfi)
    local buffer_size = NXPChipDocLite.MAX_TRANSMIT_BUFFER_SIZE
    padding_blocks = padding_blocks or 0
    local padding_max_len = padding_blocks * buffer_size
    if padding_max_len > 0 then
        local padding_len = padding_max_len - math.mod(string.len(data), buffer_size)
        if padding_len > 0 then
            data = data .. string.rep("\0", padding_len)
            log.output("NXPChipDocLite:mupdate_binary(): added padding_len:", padding_len)
        end
    end
    local left = string.len(data)
    log.output("NXPChipDocLite:mupdate_binary():multi update from:", offset, "size:", left, "chunks:", buffer_size)
    local curOffset = offset
    local chunk
    while left > 0 do
        chunk = string.sub(data, curOffset-offset+1, curOffset-offset + buffer_size)
        if chunk == 0 then
            log.output("NXPChipDocLite:mupdate_binary(): WARNING: specified data len is not enough?")
            break
        end
        self:update_binary(curOffset, chunk, use_sm, sfi)
        left = left - string.len(chunk)
        curOffset = curOffset + string.len(chunk)
    end
end

function NXPChipDocLite.mt:mupdate_binary_smart(offset, data, use_sm, sfi)
    log.output("NXPChipDocLite:mupdate_binary_smart():")
    return self:mupdate_binary(offset, data, use_sm, sfi, 2)
end

function NXPChipDocLite.mt:valid()
    local status, err = self.card:status()
    if not status then
        log.output('NXPChipDocLite:valid(): status() error', hex.tohex8(err or 0))
        return false
    elseif status.protocol == 0 or string.len(status.atr or '') == 0 then
        log.output('NXPChipDocLite:valid(): card removed?')
        return false
    end
    return true
end


return NXPChipDocLite

--===========================================================================
end
}
_LOADED['token-siae'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- pcsc-token-siae.lua
local CnsSmartcard = require 'CnsSmartcard'
local hex = require 'hex'
local hexf = hex.hexf
local der = require 'der'
local utility = require 'utility'

local objCnsTmpl = require 'token-cns-objects'

local MinKSize, MaxKSize = 1024, 1024

local t = {
    name = 'siae',
    mt = { },
    mechanisms = {
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
    },
    siae_hcard = nil,
    capabilities = { private_attributes_readable=true, always_authenticate_on_cert=false, },
}
t.mt.__index = t.mt


function t.mt:initialize(cfg)

    self.root_path = hex.hexf("00001111")
    self.capabilities = utility.clone_table(t.capabilities)
    self.siae_hcard = CnsSmartcard.new(self.hcard)
    self.siae_hcard.BSO_CNS_PIN = hex.h2i('01')
    self.siae_hcard.BSO_CNS_PUK = hex.h2i('02')
    self.request_plugin_valid = w32.request_plugin_valid()

    self.cfg = cfg or utility.parse_cfg()
    self.cfg["xproc"] = self.cfg["xproc"] or self.cfg["ixproc"]

    if self.cfg["xproc"] then self.cfg["xproc"]=string.lower(self.cfg["xproc"])
    else self.cfg["xproc"]='true' end
    log.output('siae token initialize(): mechanisms=', utility.repr(t.mechanisms))
    
    self.mechanisms = utility.clone_table(t.mechanisms)
    if self._cache_id == nil then
        self:flush_cache()
    end

    
end

function t.mt:finalize()
    log.output("token-siae:finalize():", self.session, self.userType)
    
end

function t.mt:begin_transaction()
    self.siae_hcard:begin_transaction()
end

function t.mt:end_transaction()
    self.siae_hcard:end_transaction()
end

function  t.mt:get_pin_puk_status(pinRetryMax, pukRetryMax)

    -- log.output(debug.traceback ( "get_pin_puk_status called from:"))

    log.output("get_pin_puk_status:", pinRetryMax, pukRetryMax)
    log.output("get_pin_puk_status: pin...", self.siae_hcard.BSO_CNS_PIN)

    self.siae_hcard:select(self.root_path)
    self.siae_hcard:sm_verify(self.siae_hcard.BSO_CNS_PIN, "", true)
    local resPin = self.siae_hcard.last_sw
    
    log.output("get_pin_puk_status: puk...", self.siae_hcard.BSO_CNS_PUK)
    self.siae_hcard:sm_verify(self.siae_hcard.BSO_CNS_PUK, "", true)
    local resPuk = self.siae_hcard.last_sw
    
    pinRetryMax = pinRetryMax or 5
    local pinRetry
    if resPin == hexf("9000") then
        pinRetry = pinRetryMax
    elseif resPin == hexf("6983") or resPin == hexf("6984") then
        pinRetry = 0
    else
        pinRetry = (bin.flags(string.byte(resPin, -1)) * bin.flags(hex.h2i("F"))).asnumber
    end
    
    pukRetryMax = pukRetryMax or 10
    local pukRetry
    if resPuk == hexf("9000") then
        pukRetry = pukRetryMax
    elseif resPuk == hexf("6983") or resPuk == hexf("6984") then
        pukRetry = 0
    else
        pukRetry = (bin.flags(string.byte(resPuk, -1)) * bin.flags(hex.h2i("F"))).asnumber
    end
    
    if pinRetry > pinRetryMax then 
        pinRetryMax = pinRetry
    end
    if pukRetry > pukRetryMax then 
        pukRetryMax = pukRetry
    end
    return pinRetry, pinRetryMax, pukRetry, pukRetryMax
end

function t.mt:_update_retry_counters()


    
    if (self.info) then
        log.output("_update_retry_counters...")
        local pcRes, theErrorT =  pcall (function()
            self.info.flags = self.info.flags - CKF.USER_PIN_LOCKED
            self.info.flags = self.info.flags - CKF.USER_PIN_FINAL_TRY
            self.info.flags = self.info.flags - CKF.USER_PIN_COUNT_LOW
            self.info.flags = self.info.flags - CKF.SO_PIN_LOCKED
            self.info.flags = self.info.flags - CKF.SO_PIN_FINAL_TRY
            self.info.flags = self.info.flags - CKF.SO_PIN_COUNT_LOW
            
            
            local pinRetry, pinRetryMax, pukRetry, pukRetryMax = self:get_pin_puk_status(5, 10)
            log.output("get_pin_puk_status, PIN cur/max", pinRetry, pinRetryMax, "PUK cur/max:", pukRetry, pukRetryMax);
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
        if not pcRes then
            log.output("_update_retry_counters error:", theErrorT)
        end
    end

end

function t.mt:add_info_siae()
    log.output('add_info_cns(): probing SIAE fileSystem!!!...')
    log.output('add_info_cns(): reading sn...')
        pcall(function()
            self.siae_hcard:select(hexf('2f02'))
            self.info.serialNumber = self.siae_hcard:read_binary(18,8)
            self.info.label = "SIAE-" .. self.info.serialNumber
            self.info.serialNumber = string.rep("0", 16 - string.len(self.info.serialNumber)) .. self.info.serialNumber
            
        end)
        
    if not pcall(function() return self.siae_hcard:select(self.root_path .. hexf('5f02')) end ) then
        log.output('add_info_cns(): SIAE main file not found...')
    else
        self._5f02 = {}
        local nRec = 1
        while true do
            local record = ''
            local pcRes, theErrorT = pcall( function()
                record = self.siae_hcard:read_record(nRec)
                table.insert(self._5f02, record);
            end )
            if not pcRes then
                log.output('reading 5f02 index file: error:', theErrorT)
                break
            end
            nRec = nRec+1
        end
        

    end 
end

function t.mt:get_info()
    if not self.info then
        self.info = {
            label = 'SIAE',
            manufacturerID = 'Bit4id',
            model = 'SIAE',
            serialNumber = nil,
            flags = CKF.RNG + CKF.LOGIN_REQUIRED + CKF.TOKEN_INITIALIZED + CKF.USER_PIN_INITIALIZED,
            ulMaxSessionCount = CK.EFFECTIVELY_INFINITE,
            ulSessionCount = 0,
            ulMaxRwSessionCount = CK.EFFECTIVELY_INFINITE,
            ulRwSessionCount = CK.UNAVAILABLE_INFORMATION,
            ulMaxPinLen = self.siae_hcard.PUK_PADDING or 8,
            ulMinPinLen = 4,
            ulTotalPublicMemory = 65536,
            ulFreePublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulTotalPrivateMemory = 65536,
            ulFreePrivateMemory = CK.UNAVAILABLE_INFORMATION,
            hardwareVersion = { major=0, minor=0},
            firmwareVersion = { major=0, minor=0},
            utcTime = '0000000000000000'
        }
        
        self:add_info_siae()

        self:_update_retry_counters()
    
    end
    -- NOTA: il seguente codice 