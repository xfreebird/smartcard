 avvenuta usando un numero minimo di APDU
    -- 2) mantenere lo stato della mutua autenticazione come valido nell'ambito della medesima transazione
    -- 3) eseguire la mutua autenticazione solo se necessario
    local pcRes
    local res
    if not self._performed_mutual_auth then
        if self.ssc and self.KskEnc and self.KskSig then
            local resp, valid, ssc = self:SMTX(self.ssc, self.KskEnc, self.KskSig, hex.hexf("00CA01010A"))
            self.ssc = ssc or self.ssc
            local sw = string.sub(resp, -2, -1)
            if valid and sw == hexf('9000') then
                log.output("auto_perform_mutual_authenticate(): not needed: still valid channel!")
                self._performed_mutual_auth=true
                
                return false
            end
        end
        log.output("auto_perform_mutual_authenticate(): not performed, starting...")
        res = self:perform_mutual_authenticate()
        self:select_p15()
        local dec
        
        -- local pcRes, theErrorT = pcall(function()
            local fInfo = self:select(hex.hexf("0204"), true, true)
            local certD = self:mread_binary(0, fInfo.size, true)
            
            if type(self._cacerts) == "table" and table.getn(self._cacerts)>0 then
                local certok
                for i, ca in self._cacerts do
                    if self:verify_certificate(ca, certD) then
                        certok = true
                        log.output("perform_mutual_authenticate(): Card certificate validated!")
                        break
                    end
                end
                if not certok then
                    log.output("perform_mutual_authenticate(): invalid Card certificate, not validated by any CA")
                    error('unable to verify the card certificate')
                end
            end
            
            local cert = der.parse_x509cer(certD)
            local challenge = sm.gen_random(32)
            local response = self:pso_internal_auth(challenge, "04")
  
            dec = rsa.decrypt(response, hex.hexify(cert.modulus), hex.hexify(cert.pubexp))
        -- end)
        -- if not pcRes then
           -- log.output("perform_mutual_authenticate(): internal auth error:", theErrorT)
        -- end
        if dec ~= challenge then
            log.output("perform_mutual_authenticate(): invalid card signature")
            error('internal auth error: invalid signature')
        else
            log.output("perform_mutual_authenticate(): card authentication success!")
        end
    
        return res
    else
        log.output("auto_perform_mutual_authenticate(): not needed: inside same transaction!")
        return false
    end
end

function ArjoSmartcard.mt:mse_load(id)
    local apdu = hex.hexf("0022F3" .. id)
    local recv = self:transmit(apdu)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'MSE restore Error'), 2)
    end
end

function ArjoSmartcard.mt:calculate_pi_password()
    local first_step = md.sha1()
    log.output("calculate_pi_password: User_EXCAN:", hex.hexify(self.User_EXCAN))
    first_step:update(self.User_EXCAN)
    first_step = first_step:final()
    log.output("first_step:", hex.hexify(first_step))
    
    -- se 256
    local mdx
    if string.len(self.User_EXCAN) > 20 then
        mdx = md.sha256()
    else
        mdx = md.sha1()
    end
    
    mdx:update((first_step .. hex.hexf('00000003')))
    local k = mdx:final()
    if string.len(k) < 32 then
        k = string.sub(k, 1, 16)
        log.output ("calculate_pi_password: using AES128, first 16 bytes", hex.hexify(k))
    end
    return k
end

function ArjoSmartcard.mt:decrypt_nonce(nonce)
    local pi_password = self:calculate_pi_password()
    log.output ("pi_passwor for decrypt nonce:", hex.hexify(pi_password))
    local decrypted_nonce = aes.AES_CBC(pi_password, nonce, false, string.rep("\0", 16))
    return decrypted_nonce
end

function ArjoSmartcard.mt:dec_can(encoded)
    log.output("dec_can: encoded: ", hex.hexify(encoded))
    local res
    local first_step = md.sha1()
    first_step:update(self.mw_mk)
    first_step = first_step:final()
    local mdx = md.sha256()
    mdx:update((first_step .. hex.hexf('00000003')))
    local third_step = mdx:final()
    --print("third_step", hex.hexify(third_step))
    local mdx = md.sha256()
    mdx:update(third_step)
    local sha256_3 = mdx:final()
    --print("sha256_3", hex.hexify(sha256_3))
    
    local d = sm.aes_dec_block(sha256_3, encoded)
    if string.byte(d, 1) == 4 then
        res = string.sub(d, 3, 2+string.byte(d, 2))
    end
    
    log.output("dec_can: decoded: ", hex.hexify(res or ""))
    return res
end

function ArjoSmartcard.mt:verify_certificate(ca, cer)
    local cerP
    local caP = der.parse_x509cer(ca)
    
    cerP = der.parse(cer)
    if table.getn(cerP) ~= 1 or cerP[1].tag ~= der.SEQUENCE then
        error('X509 certificate parse error', 2)
    end
    
    local Certificate = der.parse(cerP[1].value)
   
    if table.getn(Certificate) ~= 3 or
        Certificate[1].tag ~= der.SEQUENCE or
        Certificate[2].tag ~= der.SEQUENCE or
        Certificate[3].tag ~= der.BIT_STRING then
        error('X509 certificate parse error', 2)
    end
  
    local tbsCertificate = der.build(Certificate[1].tag, Certificate[1].value)
    local signature = Certificate[3].value

    local dec
    pcall(function()
        dec = rsa.decrypt(signature, hex.hexify(caP.modulus), hex.hexify(caP.pubexp))
    end)
    if not dec then
        log.output("verify_certificate(): invalid signature: cannot decrypt")
        return false
    end
    for i, v in {md.sha1, md.sha256, md.sha384, md.sha512} do
        local ctx = v()
        ctx:update(tbsCertificate)
        local digest = ctx:final()
        
        if string.sub(dec, -string.len(digest), -1) == digest then
            return true
        end
    end
    
    log.output("verify_certificate(): invalid signature: digest")
    return false
end

function ArjoSmartcard.mt:perform_mutual_authenticate()
    
    log.output("perform_mutual_authenticate()")
    self._performed_mutual_auth = false
    
    self:select() -- MF
    self:mse_load("03")
    
    local recv = self:transmit(hex.hexf("00A4020002003900"))
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'select 0039 file Error'), 2)
    end
    local encCAN = self:read_binary(0, 0)
    local USERS_CAN = self:dec_can(string.sub(encCAN, 3, -1))
    self.User_EXCAN = USERS_CAN and (USERS_CAN .. hex.hexf(ArjoSmartcard.SSCD_APP_SECRET)) or self.User_EXCAN
    log.output("User_EXCAN:", hex.hexify(self.User_EXCAN))
    
    -- local info = self:select(hex.hexf("010C")) -- elect SSCD Card Access
    --self:mread_binary(0, info.size)
    local recv = self:transmit(hex.hexf("00A4020C02010C"))
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'set_at Error'), 2)
    end
    self:read_binary(0, 0)
    self:mse_load("03")
    
    local PaceSelectedAlgorithm = hex.hexf("04007f00070202040204")
    
    local set_at_data = hex.hexf('80%P830101', PaceSelectedAlgorithm)
    local set_at = hex.hexf("0022C1A4%P", set_at_data)
    log.output("set_at request: ", hex.hexify(set_at))
    
    local recv = self:transmit(set_at)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'set_at Error'), 2)
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
        error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'set_at Error'), 2)
    end
    
    local raw_nonce = ArjoSmartcard.parse_tlv(ArjoSmartcard.parse_tlv(recv)[124])[128]
    
    
    log.output("raw_nonce: ", hex.hexify(raw_nonce))
    
   
    local nonce_dec = self:decrypt_nonce(raw_nonce)
    log.output("nonce_dec: ", hex.hexify(nonce_dec))
    
    nonce_dec = bignum.create(nonce_dec, true)
     
    local curve = ecdhlib.get_curve("brainpoolP224r1")
    
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
    
    
    local tag_81 = hex.hexf("81%P", Terminal_Public_Key:encode_point(true, 28))
    local tag_7c = hex.hexf("7C%P", tag_81)
    local gen_auth_2 = hex.hexf( "10860000%P00" , tag_7c)
    log.output("gen_auth_2:", hex.hexify(gen_auth_2))
    local recv = self:transmit(gen_auth_2)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'PACE step 2 Error'), 2)
    end
    local Mapping_Data = ArjoSmartcard.parse_tlv(ArjoSmartcard.parse_tlv(recv)[124])[130]

    log.output("Mapping_Data:", hex.hexify(Mapping_Data))

    local point = curve.g:decode_point(Mapping_Data, true)
    local ephemeralSecret = point:scalar_mult(Terminal_Private_Key)
    local mappedGenerator_multi = curve.g:scalar_mult(nonce_dec)
    local mappedGenerator = mappedGenerator_multi:point_add(ephemeralSecret)

    local ephemeral_curve_priv, ephemeral_curve = curve.g:make_keypair(bignum.create("0x65537"))
    
    log.output("ephemeral_curve:", ephemeral_curve)
    log.output("ephemeral_curve_priv:", ephemeral_curve_priv)
    
    local ephemeral_Public_Key = mappedGenerator:scalar_mult(ephemeral_curve_priv):encode_point(true, 28)
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
        error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'PACE step 3 Error'), 2)
    end
    log.output("gen_auth_3 recv:", hex.hexify(recv))
    
    
    local Mapping_Data = ArjoSmartcard.parse_tlv(ArjoSmartcard.parse_tlv(recv)[124])[132]
    local ephemeralKeyPICC = curve.g:decode_point(Mapping_Data, true)
    local ephemeralSecret = ephemeralKeyPICC:scalar_mult(ephemeral_curve_priv)

    local Chip_Ephemeral_Public_Key = Mapping_Data
    log.output ("Chip_Ephemeral_Public_Key--> Returned step 3: ", hex.hexify(Chip_Ephemeral_Public_Key))

    local secretPoint_X = string.sub(ephemeralSecret:encode_point(false, 28), 1, 28)
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
        error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'PACE step 3 Error'), 2)
    end
    log.output("gen_auth_4 recv:", hex.hexify(recv))
    
    
    
    local Authentication_Token = ArjoSmartcard.parse_tlv(ArjoSmartcard.parse_tlv(recv)[124])[134]

    log.output ("Authentication_Token: ", hex.hexify(Authentication_Token))

    log.output("perform_mutual_authenticate(): completed")
    self._performed_mutual_auth = true
    self.ssc = string.rep("\0", 16)
    self.KskEnc, self.KskSig = kSenc, kSmac
    

    return true
end

-------------------------------------------------------

function ArjoSmartcard.parse_tlv(tlv_struct)
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

function ArjoSmartcard.parse_fci(fci)
    local fci1 = ArjoSmartcard.parse_tlv(fci)
    local fci2 = ArjoSmartcard.parse_tlv(fci1[98] or fci1[111]) -- 0x62 or 0x6F
    local infos = {size=(fci2[128] or fci2[129]) and bin.unpack("%H", fci2[128] or fci2[129]),
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


function ArjoSmartcard.mt:transmit(apdu)
    log.output(">> APDU:", hex.hexify(apdu))
    local recv = self.card:transmit(apdu)
    log.output("<< RESP:", hex.hexify(recv))
    return recv
end


function ArjoSmartcard.mt:sm_transmit(apdu, use_sm)
    if not use_sm then
        return self:transmit(apdu)
    end
    if not self._performed_mutual_auth then
        self:auto_perform_mutual_authenticate()
    end
    local resp, valid, ssc = self:SMTX(self.ssc, self.KskEnc, self.KskSig, apdu)
    self.ssc = ssc or self.ssc
    self.last_sw = string.sub(resp, -2, -1)
    return resp, valid
end

function ArjoSmartcard.mt:select(path, relative, use_sm)
    local sw, recv, path1, relative_id
    if relative then relative_id = 0 else relative_id = 8 end
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
        error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'select Error'), 2)
    elseif string.len(recv) > 2 then
        return ArjoSmartcard.parse_fci(recv)
    end
end


function ArjoSmartcard.mt:read_binary(offset, size, use_sm)
    local recv
    log.output("reading from:", offset, "size:", size)
    local apdu = hexf('00B0%H%B', offset, size)
    recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') and sw ~= hexf('6282') then
        error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'read_binary Error'), 2)
    end
    return string.sub(recv, 1, -3)
end

function ArjoSmartcard.mt:mread_binary(offset, size, use_sm)
    local buffer_size = ArjoSmartcard.MAX_TRANSMIT_BUFFER_SIZE
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


function ArjoSmartcard.mt:change(bso, oldPin, newPin, backtracking)
    if backtracking then
        bso = (bin.flags(bso) + bin.flags(128)).asnumber
    end
	local mode = 0
    local sw = self:sm_transmit(hexf('0024%B%B%P', mode, bso, oldPin..newPin), true)
    if sw == hexf('6983')  or sw == hexf('6984') then
        return 2, 'Authentication blocked'
    elseif sw == hexf('6700') or bin.mask_compare(sw, hexf('6300'), hexf('FF00')) then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        return 0, 'Authentication succeeded'
    else
        log.output('change(): Error ' .. hexify(sw) )
        error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'change Error' ), 2)
    end
end


function ArjoSmartcard.mt:begin_transaction()
    self.card:begintransaction()
end

function ArjoSmartcard.mt:end_transaction()
    self._performed_mutual_auth = false
    self.card:endtransaction()
end

function ArjoSmartcard.mt:on_end_transaction()
    log.output('ArjoSmartcard:on_end_transaction()...')
    self._performed_mutual_auth = false
end


function ArjoSmartcard.mt:reset_retry_counter(bso, newPin, backtracking)
    if backtracking then
        bso = (bin.flags(bso) + bin.flags(128)).asnumber
    end
    local mode = 2
    if not newPin then
        mode = 3
    end
    local sw = self:sm_transmit(hexf('002C%B%B%P', mode, bso, (newPin or '')), true)
    if sw == hexf('6983')  or sw == hexf('6984') then
        return 2, 'Authentication blocked'
    elseif sw == hexf('6700') or bin.mask_compare(sw, hexf('6300'), hexf('FF00')) then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        return 0, 'Authentication succeeded'
    else
        log.output('reset_retry_counter(): Error ' .. hexify(sw) )
        error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'reset_retry_counter Error' ), 2)
    end
end

function ArjoSmartcard.mt:valid()
    local status, err = self.card:status()
    if not status then
        log.output('ArjoSmartcard:valid(): status() error', hex.tohex8(err or 0))
        return false
    elseif status.protocol == 0 or string.len(status.atr or '') == 0 then
        log.output('ArjoSmartcard:valid(): card removed?')
        return false
    end
    return true
end

---------------------------------------------------
function ArjoSmartcard.handle_error(err_obj)
    print(debug.traceback(err_obj))
    return err_obj
end

function ArjoSmartcard.mt:verify_pin_main(pin, ispuk)
    log.output('verify_pin_main():', pin, ispuk )
    local bso = self.ID_PIN
    -- local padding = self.PIN_PADDING
    if ispuk then
        bso = self.ID_PUK
        -- padding = self.PUK_PADDING
    end
    -- if string.len(pin)> padding then
        -- pin = string.sub(pin, 1, padding)
    -- end
    -- pin = pin .. string.rep(self.PADDING_CHAR, padding - string.len(pin))
    return self:verify(bso, pin, true)
end

function ArjoSmartcard.mt:change_pin_main(oldPin, newPin, ispuk)
    local bso = self.ID_PIN
    if ispuk then
        bso = self.ID_PUK
    end
    return self:change(bso, oldPin, newPin, true)
end


function ArjoSmartcard.mt:reset_pin_main(Puk, newPin)
    local res
    
    res = self:verify_pin_main(Puk, true)
    if res ~= 0 then return res end
    return self:reset_retry_counter(self.ID_PIN, newPin, true)
end




function ArjoSmartcard.mt:pso_cds(data, kid, pin)
    local sw, resp
    if type(kid) == 'number' then 
        kid = hex.hexf('%B', kid)
    elseif string.len(kid) == 2 then 
        kid = hex.hexf(kid)
    end
    repeat

        local SHA256_DIGEST_OID = hex.hexf("3031300d060960864801650304020105000420")
        local SHA1_DIGEST_OID = hex.hexf("3021300906052b0e03021a05000414")
        local algIDhash = hex.hexf("40")
        local algIDsign = hex.hexf("42")
        
        if SHA256_DIGEST_OID == string.sub(data, 1, string.len(SHA256_DIGEST_OID)) then
            data = string.sub(data, string.len(SHA256_DIGEST_OID)+1, -1)
        elseif SHA1_DIGEST_OID == string.sub(data, 1, string.len(SHA1_DIGEST_OID)) then
            algIDhash = hex.hexf("10")
            algIDsign = hex.hexf("12")
            data = string.sub(data, string.len(SHA1_DIGEST_OID)+1, -1)
        elseif string.len(data) == 20 then
            algIDhash = hex.hexf("10")
            algIDsign = hex.hexf("12")
        end
        
        if pin and string.len(pin) > 0 then
            local res = self:verify_pin_main(pin, false)
            if res ~= 0 then
                error(ArjoSmartcard.ArjoSmartcardError.new(sw, 
                    'pso_cds error: verify_pin_main failed!' ), 2)
            end
        end
        
        local seRestore = hex.hexf("002241AA038001") .. algIDhash
        resp = self:sm_transmit(seRestore, true)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end

        
        local hash = hex.hexf("90%P8000", data)
        local putHash = hex.hexf("002a90a0%B", string.len(hash)) .. hash
        resp = self:sm_transmit(putHash, true)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end
        
        local Key = hex.hexf("8001%S8401%S", algIDsign, kid)
        local setKey = hex.hexf("002241B6%P", Key)
        resp = self:sm_transmit(setKey, true)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end

        local pso_cds = hex.hexf("002a9e9a000000")
        resp = self:sm_transmit(pso_cds, true)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end
        
        break
    until true
    
    if sw ~= hexf('9000') then
        error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'pso_cds error' ), 2)
    end
    return string.sub(resp, 1, -3)
end



function ArjoSmartcard.mt:pso_internal_auth(data, kid, pin)
    local sw, resp
    if type(kid) == 'number' then 
        kid = hex.hexf('%B', kid)
    elseif string.len(kid) == 2 then 
        kid = hex.hexf(kid)
    end
    repeat

        if pin and string.len(pin) > 0 then
            local res = self:verify_pin_main(pin, false)
            if res ~= 0 then
                error(ArjoSmartcard.ArjoSmartcardError.new(sw, 
                    'pso_internal_auth error: verify_pin_main failed!' ), 2)
            end
        end
        
        local Key = hex.hexf("8001028401%S", kid)
        local setKey = hex.hexf("002241A4%P", Key)
        resp = self:sm_transmit(setKey, true)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then
            log.output("pso_internal_auth: MSE SW", hex.hexify(sw))
            break
        end

        local pso_internal_auth = hex.hexf("008800000000%P0000", data)
        resp = self:sm_transmit(pso_internal_auth, true)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then
            log.output("pso_internal_auth: INTERNAL AUTH SW", hex.hexify(sw))
            break
        end
        
        break
    until true
    
    if sw ~= hexf('9000') then
        error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'pso_internal_auth error' ), 2)
    end
    return string.sub(resp, 1, -3)
end


function ArjoSmartcard.mt:pso_dec(data, kid, pin)
    local sw, resp
    if type(kid) == 'number' then 
        kid = hex.hexf('%B', kid)
    elseif string.len(kid) == 2 then 
        kid = hex.hexf(kid)
    end
    repeat

        if pin and string.len(pin) > 0 then
            local res = self:verify_pin_main(pin, false)
            if res ~= 0 then
                error(ArjoSmartcard.ArjoSmartcardError.new(sw, 
                    'pso_dec error: verify_pin_main failed!' ), 2)
            end
        end
        
        local Key = hex.hexf("80011A8401%S", kid)
        local setKey = hex.hexf("002241B8%P", Key)
        resp = self:sm_transmit(setKey, true)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end

        data = hex.hexf("81") .. data
        local s_data
        if string.len(data) >= 256 then
            s_data = hex.hexf("00%>%H%S", string.len(data), data)
        else
            s_data = hex.hexf("%P", data)
        end
        local pso_dec = hex.hexf("002a8086%S00", s_data)
        resp = self:sm_transmit(pso_dec, true)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end
        
        break
    until true
    
    if sw ~= hexf('9000') then
        error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'pso_dec error' ), 2)
    end
    return string.sub(resp, 1, -3)
end


function ArjoSmartcard.mt:generate_key_pair(kid)
    local sw, resp
    if type(kid) == 'number' then 
        kid = hex.hexf('%B', kid)
    elseif string.len(kid) == 2 then 
        kid = hex.hexf(kid)
    end
    local sdo = hex.hexf("7003bf90") .. kid
    local generate = hex.hexf("00470000%P", sdo)
    resp = self:sm_transmit(generate, true)
    sw = string.sub(resp, -2, -1)
    if sw ~= hexf('9000') and sw ~= hexf('6985') then
        error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'generate_key_pair error' ), 2)
    end
end

function ArjoSmartcard.mt:read_public_key(kid)

    if type(kid) == 'number' then 
        kid = hex.hexf('%B', kid)
    elseif string.len(kid) == 2 then 
        kid = hex.hexf(kid)
    end
    local resp
    
    local tag_4D = hex.hexf("4D097007bfa0%S037f4980", kid)
    local getKey = hex.hexf("00CB3FFF0000%P0000", tag_4D)
    resp = self:sm_transmit(getKey, true)
    sw = string.sub(resp, -2, -1)
    if sw ~= hexf('9000') then
        error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'read_public_key error' ), 2)
    end
    
    local d = parse_tlv_ber(string.sub(resp, 1, -3))
    local d1 = parse_tlv_ber( d[tonumber('7F49', 16)] )
    local MOD = d1[tonumber("81", 16)]
    local EXP = d1[tonumber("82", 16)]
    if string.len(MOD) < 256 then
        MOD = trim_pad_bn(MOD, 128) -- taglia a 1024 bit
    elseif string.len(MOD) < 384 then
        MOD = trim_pad_bn(MOD, 256) -- taglia a 2048 bit
    else
        MOD = trim_pad_bn(MOD, 384) -- taglia a 3072 bit
    end
    return MOD, EXP
end



function ArjoSmartcard.mt:select_p15()
    local recv = self:sm_transmit(hex.hexf("00A404000CA000000063504B43532D313500"), true)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'select_p15 error' ), 2)
    end
end

function ArjoSmartcard.mt:read_serial_number()
    if not self.CSN then
        self:select_p15()
        local resp = self:sm_transmit(hex.hexf("00CA01010A"), true)
        local sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then
            error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'read_serial_number error' ), 2)
        end
        self.CSN = string.sub(resp, 1, -3)
    end
    return self.CSN
end

function ArjoSmartcard.mt:read_model()
    if not self.model then
        self:select_p15()
        local resp = self:sm_transmit(hex.hexf("00ca011000"), true)
        local sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then
            error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'read_model error' ), 2)
        end
        self.model = string.sub(resp, 1, -3)
    end
    return self.model
end



function ArjoSmartcard.mt:verify(bso, pin, backtracking)
    if backtracking then
        bso = (bin.flags(bso) + bin.flags(128)).asnumber
    end
    local apdu = hex.hexf("002000%B%P", bso, pin)
    local recv = self:sm_transmit(apdu, true)
    local sw = string.sub(recv, -2, -1)
    if sw == hexf('6983') then
        return 2, 'Authentication blocked'
    elseif sw == hexf('6700') or string.sub(hexify(sw), 1, 2) == '63' then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        return 0, 'Authentication succeeded'
    else
        log.output('verify(): Error ' .. hexify(sw) )
        error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'verify Error' ), 2)
    end
end


function ArjoSmartcard.mt:update_binary(offset, data, use_sm)
    local apdu = hex.hexf('00D6%H%P', offset, data)
    local recv, sw
    recv =  self:sm_transmit(apdu, use_sm)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(ArjoSmartcard.ArjoSmartcardError.new(sw, 'update_binary Error'), 2)
    end
end


function ArjoSmartcard.mt:mupdate_binary(offset, data, use_sm)
    local buffer_size = ArjoSmartcard.MAX_TRANSMIT_BUFFER_SIZE
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

function ArjoSmartcard.mt:read_x509_certificate(cert_id, offset, use_sm)
    if offset == nil then offset=0 end

    log.output('read_x509_certificate():')
    local fInfo = self:select(cert_id, true, use_sm)
    
    local der_size = self:read_binary(offset, 4, use_sm)
    if string.sub(der_size, 1, 2) == hexf('5a82') then  -- Z\x82 + sizeBE + compressed data
        local size = string.byte(der_size, 3) * 256 + string.byte(der_size, 4)
        log.output('read_x509_certificate(): PT: using CPR mode: expected size:', size)
        local compr = self:mread_binary(offset+4, size, use_sm)
        local decompr = zlib.decompress(compr, true, nil, nil)
        log.output('read_x509_certificate(): PT: cpr ratio:', 
                (4+string.len(compr))/string.len(decompr or "0"))
        return decompr
    else
        if string.sub(der_size, 1, 2) ~= hexf('3082') then
            error('ArjoSmartcard read_x509_certificate Error: bad certificate', 2)
        end
        local size = string.byte(der_size, 3) * 256 + string.byte(der_size, 4)
        return der_size .. self:mread_binary(offset+4, size, use_sm)        
    end

end


-- local function testSM()
    -- local x = protectAPDU(string.rep("\0", 15) .. "\1", string.rep("\1", 16), string.rep("\2", 16), hex.hexf("00a40000"), hex.hexf("3f00"), "\0", false)


    -- local ssc1 = hex.hexf("00000000000000000000000000000003")
    -- local keyEnc = hex.hexf("8873729d03216bdf05cdeba9bd00d7e9d21e553bf740387f1d2b9a500cfa10da")
    -- local keyMac = hex.hexf("b5be26718e41d453ef405d989be5cce3d9d4c06a9ff0c1707376ac68785342df")
    -- local response = hex.hexf("990290008e08315d177c3842838d9000")

    -- local x, valid, ssc1 = unprotectAPDUResponse(ssc1, keyEnc, keyMac, response, EvenIns)
    -- print ("resp", hex.hexify(x))
    -- print ("valid:", valid)
    -- print ("ssc1:", hex.hexify(ssc1))


    -- local ssc1 = hex.hexf("00000000000000000000000000000001")
    -- local keyEnc = hex.hexf("d163bbee51e63cdd6e172ed8f4e3bbb5a109c793e3d8094ecd2351358a156d96")
    -- local keyMac = hex.hexf("62fdbc97241bb74cb87124e8759a8be0ac14fe69950ad1939776b61c1ec77086")
    -- local response = hex.hexf("8731015b1af8220e21035c9f8aa6a90edd6860adb9410901dbe20c1af027c5492788a0cec87534d0a11e8af01d2b3fd1bc10c2990290008e08614b8b2141e757c79000")

    -- local x, valid, ssc1 = unprotectAPDUResponse(ssc1, keyEnc, keyMac, response, true)
    -- print ("resp", hex.hexify(x))
    -- print ("valid:", valid)
    -- print ("ssc1:", hex.hexify(ssc1))


    -- local ssc1 = hex.hexf("00000000000000000000000000000005")
    -- local keyEnc = hex.hexf("b83d37b2145c988e9aaa60a99a9a7a566125616f17b0a14a0cbadf86256884c6")
    -- local keyMac = hex.hexf("a9474166d633bfeaba30e78604a7e576df39a32c9d2e57c46a44c0f6b5548a4c")
    -- local response = hex.hexf("85820120620e5a3d85120708c803f050bdb48d51daaf581566d3770896132b63d31d31a62835126232aba3f91028e7525f589633fb1e4f26433c81232ebda4a41fc56853c2735c45bd66a99c57b9f1129bcd51d8bcfbed131b3888bf8600623efb644760d5bbe6b3dcd40aeacf8b84f6f9892b730b8356987612e8cc1c45a5e5f1a9062686829dd58c074652bb505e78f932b6f3388134cc96d3c10cb20d544698f8857ee98f941a73f9028fbe0f89b5c41a664cf3f5ca45e554dfb2481ffc831f17ed005884fac027cba2f2a8b429817c7dbbb594647edcecccf193fdd3370224db87a1c3d28540a20de949ff8774a5b18e0c41fd1314e703389c8df86229b2c80af95b6c658a87e7721e0bf666878f409202b06a760d9ae33b4066b58e5ab59a7901cd990290008e08581b8e4ab4bdafd99000")

    -- local x, valid, ssc1 = unprotectAPDUResponse(ssc1, keyEnc, keyMac, response, false)
    -- print ("resp", hex.hexify(x))
    -- print ("valid:", valid)
    -- print ("ssc1:", hex.hexify(ssc1))

    -- local ssc1 = hex.hexf("00000000000000000000000000000000")
    -- local keyEnc = hex.hexf("39A7E32D15F9D765096CC8F0A4DB72EFBB159CC48AD1018A5D1CCD7E1340A8CE")
    -- local keyMac = hex.hexf("EB8D8CF15CBB931D8B61827F3EB2B967A0FD15574AE5F79D2500891C53E09F0C")
    -- local response = hex.hexf("8731015b1af8220e21035c9f8aa6a90edd6860adb9410901dbe20c1af027c5492788a0cec87534d0a11e8af01d2b3fd1bc10c2990290008e08614b8b2141e757c79000")

    -- local x = protectAPDU(ssc1, keyEnc, keyMac, hex.hexf("00a40000"), hex.hexf("3f00"), "\0", false)
    -- print ("apdu", hex.hexify(x))

-- end

-- local ssc1 = hex.hexf("00000000000000000000000000000004")
-- local keyEnc = hex.hexf("c92b5b31aff0473f66467e807bcff3010277be78db353a0a64556859cd491b12")
-- local keyMac = hex.hexf("ee9e929720a7b8b51eae3144bdec26b23099a3a3be7b0808ecbdb1f87279967b")


-- local x, ssc1 = protectAPDU(ssc1, keyEnc, keyMac, hex.hexf("00CB3FFF"), hex.hexf("4D097007bfa008037f4980"), "\0", true)
-- print ("apdu", hex.hexify(x))

-- local ssc1 = hex.hexf("00000000000000000000000000000000")
-- local keyEnc = hex.hexf("bd37c766c6f5cd939dc0cec78e957345f5c2e93ed96f75224f6148a006fca539")
-- local keyMac = hex.hexf("fa6fce2bcf56f260e41b77e94eb67f60154fb2cfb26b51c58ddb35ade490fe11")
-- local response = hex.hexf("8731018a0a5090006f810d57908be3cf4b448740857e9217d5bbebf7acc648597ba0b46eb2588a518eaf77a2c1f7f45c96291f990290008e08db509ea6211e16919000")


-- local x, ssc1 = protectAPDU(ssc1, keyEnc, keyMac, hex.hexf("00A40400"), hex.hexf("A000000063504B43532D3135"), "\0", false)
-- print ("apdu", hex.hexify(x))


-- local x, valid, ssc1 = unprotectAPDUResponse(ssc1, keyEnc, keyMac, response, false)
-- print ("resp", hex.hexify(x))
-- print ("valid:", valid)
-- print ("ssc1:", hex.hexify(ssc1))
    
return ArjoSmartcard

--===========================================================================
end
}
_LOADED['GemaltoSmartcard'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
local hex = require 'hex'
local util = require 'utility'
local h2i, hexf, hexify = hex.h2i, hex.hexf, hex.hexify
local rsa
local zlib = require 'zlib'

local function hexf2(data, ...)
    data = string.gsub(data, "%s", "")
    return hex.hexf(data, unpack(arg))
end

pcall(function() rsa = require("rsa"); end)

-- GemaltoSmartcard

local tr_dl

local GemaltoSmartcard = {}
GemaltoSmartcard.mt = {}
GemaltoSmartcard.mt.__index = GemaltoSmartcard.mt


GemaltoSmartcard.PIN_PADDING = 16
GemaltoSmartcard.PUK_PADDING = 16
GemaltoSmartcard.PIN_PADDING_CHAR = "\000"
GemaltoSmartcard.PUK_PADDING_CHAR = "\000"
GemaltoSmartcard.BSO_PIN = h2i('81')
GemaltoSmartcard.BSO_PUK = h2i('82')

GemaltoSmartcard.MAX_TRANSMIT_BUFFER_SIZE = 200

GemaltoSmartcard.GemaltoSmartcardError = {}
GemaltoSmartcard.GemaltoSmartcardError.mt = {}
GemaltoSmartcard.GemaltoSmartcardError.mt.__index = GemaltoSmartcard.GemaltoSmartcardError.mt

function GemaltoSmartcard.GemaltoSmartcardError.mt.__tostring(e)
    return "GemaltoSmartcardError: " .. (e.msg or '') .. ' ;SW=' .. hex.hexify(e.sw or '') 
end

function GemaltoSmartcard.GemaltoSmartcardError.new(sw, msg)
    local e = msg .. ' ;sw=' .. hexify(sw or '')
    return e
end


function GemaltoSmartcard.new(card)
    local self = {
                    PIN_PADDING=GemaltoSmartcard.PIN_PADDING,
                    PUK_PADDING=GemaltoSmartcard.PUK_PADDING,
                    PIN_PADDING_CHAR=GemaltoSmartcard.PIN_PADDING_CHAR,
                    PUK_PADDING_CHAR=GemaltoSmartcard.PUK_PADDING_CHAR,
                    BSO_PIN=GemaltoSmartcard.BSO_PIN, BSO_DS_PIN=GemaltoSmartcard.BSO_DS_PIN,
                    BSO_PUK=GemaltoSmartcard.BSO_PUK, BSO_DS_PUK=GemaltoSmartcard.BSO_DS_PUK,
                  }
    self.card = card
    setmetatable(self, GemaltoSmartcard.mt)
    return self
end


function GemaltoSmartcard.mt:get_pin_puk_status()
    self:verify_pin_main("", false, true, false)
    local resPin = self.last_sw

    self:verify_pin_main("", true, true, false)
    local resPuk = self.last_sw
    
    local pinRetryMax = 3
    local pinRetry
    if resPin == hexf("9000") then
        pinRetry = pinRetryMax
    else
        pinRetry = (bin.flags(string.byte(resPin, -1)) * bin.flags(h2i("F"))).asnumber
    end
    
    local pukRetryMax = 3
    local pukRetry
    if resPuk == hexf("9000") then
        pukRetry = pukRetryMax
    else
        pukRetry = (bin.flags(string.byte(resPuk, -1)) * bin.flags(h2i("F"))).asnumber
    end
    
    if pinRetry > pinRetryMax then 
        pinRetryMax = pinRetry
    end
    if pukRetry > pukRetryMax then 
        pukRetryMax = pukRetry
    end
    
    return pinRetry, pinRetryMax, pukRetry, pukRetryMax
end


local function pad_iso9797(data)
    local l = string.len(data)
    local m = math.mod(l, 8)
    if l == 0 or m == 0 then
        return data
    end
    return data .. string.rep('\000', 8-m)
end

local function pad_iso9797_2(data)
    local l = string.len(data)
    local m = math.mod(l, 8)
    local x = data .. "\128" .. string.rep('\000', 7-m)
    return x
    
end

local function unpad_iso9797_2(data)
    local l = string.len(data)
    for i=1,8 do
        if string.byte(data, l-i) == 128 then
            return string.sub(data, 1, l-i-1)
        end
    end
end

local function Retail_MAC(key, data, ssc)
    if not ssc then
        ssc=hex.hexf("0000000000000000")
    end
    S1TOMAC = pad_iso9797_2(ssc .. data)
    return sm.des3_mac(key, S1TOMAC)
end

local function calc_diversified_keys(CSN, MK1)
    --~ KENC = 3DES [CSN] <MK> || 3DES [CSN] <MK_inv>
    --~ KMAC = 3DES [inv_CSN] <MK> || 3DES [inv_CSN] <MK_inv>
    --~ MK: MK_Part1 || MK_Part2
    --~ CSN: aabbccddeeffgghh
    --~ MK_inv: MK_Part2 || MK_Part1
    --~ inv_CSN: hhggffeeddccbbaa
    --~ Example:
    --~ MK = 01 02 03 04 05 06 07 08 01 02 03 04 05 06 07 08h
    --~ CSN = 0F 80 00 1A D7 68 3C 6Dh
    --~ KENC = A7 AA 10 E9 BE DC 5A EF A7 AA 10 E9 BE DC 5A EFh
    --~ KMAC = B3 D4 AF 9B 29 FD F6 E3 B3 D4 AF 9B 29 FD F6 E3h
    log.output("calc_diversified_keys():")
    local MK_Part1 = string.sub(MK1, 1, 8)
    local MK_Part2 = string.sub(MK1, 9, 16)
    local MK = MK_Part1 .. MK_Part2 .. MK_Part1
    local MK_inv = MK_Part2 .. MK_Part1 .. MK_Part2
    local inv_CSN = ""
    for i=1,string.len(CSN) do
        inv_CSN = string.sub(CSN, i, i) .. inv_CSN
    end
    local KENC = sm.des3_enc(MK, CSN, true) .. sm.des3_enc(MK_inv, CSN, true)
    local KMAC = sm.des3_enc(MK, inv_CSN, true) .. sm.des3_enc(MK_inv, inv_CSN, true)
    return KENC, KMAC
end


local function calc_mutial_authenticate(key, CSN, CRnd, ICC_SN, TRnd, IFD_SN, Kifd)
    log.output("calc_mutial_authenticate():")
    local KENC, KMAC = calc_diversified_keys(string.sub(CSN, 1, 8), string.sub(key, 1, 16))
    KENC = KENC .. string.sub(KENC, 1, 8)
    KMAC = KMAC .. string.sub(KMAC, 1, 8)
    local S = TRnd .. IFD_SN .. CRnd .. ICC_SN .. Kifd
    local S1 = sm.des3_enc(KENC, S, true)
    local SSC_NULL=hex.hexf("0000000000000000")
    local S1TOMAC = pad_iso9797_2(SSC_NULL .. S1)
    local MAC = sm.des3_mac(KMAC, S1TOMAC)
    return KENC, KMAC, S1, MAC
end

local function L(value)
    return string.char(string.len(value)) .. value
end

function GemaltoSmartcard.mt:TXchain(value, data)
    log.output("TXchain():")
    local resp = ""
    local value2
    local data2
    local data1 = data
    local value1 = value
    if data then
        if string.len(data) > 254 then
            data1 = string.sub(data, 1, 220)
            data2 = string.sub(data, 221)
            value1 = string.char(string.byte(value, 1) + 16) .. string.sub(value, 2, 4)
            value2 = string.sub(value, 1, 4)
            log.output("TXchain: value1", hex.hexify(value1))
            log.output("TXchain: data1", hex.hexify(data1))
            log.output("TXchain: value2", hex.hexify(value2))
            log.output("TXchain: data2", hex.hexify(data2))
        end
    end
    resp = self:TX(value1, data1)
    if value2 then
        resp = self:TX(value2, data2)
    end
    return resp
end
    

function GemaltoSmartcard.mt:TX(value, data)
    local resp = ""
    if data then
        value = value .. L(data)
    end
    log.output('<<', hex.hexify(value))
    local stop
    while true do
        local r = self.card:transmit(value)
        if string.sub(r, -2, -2) == hexf("61") then -- more data
            log.output('*>>', hex.hexify(r))
            local r1 = string.byte(r, -1)
            -- if r1 == 0 then
                -- r1 = 128
            -- end
            value = hex.hexf('00C00000%B', r1)
            log.output('<<*', hex.hexify(value))
            resp = resp .. string.sub(r, 1, -3)          
        elseif string.sub(r, -2, -2) == hexf("6c") and string.len(value)==5 then -- wrong length
            log.output('*>>', hex.hexify(r))
            value = string.sub(value, 1, 4) .. string.sub(r, -1)
            log.output('<<*', hex.hexify(value))
            resp = resp .. string.sub(r, 1, -3)
        else
            resp = resp .. r
            break
        end
    end
    log.output('>>', hex.hexify(resp) )
    return resp
end
    
local function enc_msg(key, apdu)
    log.output("enc_msg():")
    local edfb
    local lc = string.byte(apdu, 5)
    log.output('enc_msg: lc: ', lc )
    if lc > 0 then
        data = string.sub(apdu, 6)
    else
        data = ""
    end
    log.output("data:", hex.hexify(data))
    local pbData = pad_iso9797_2(data)
    log.output("pbData:", hex.hexify(pbData))
    local eData = "\001" .. sm.des3_enc(key, pbData, true)
    log.output("eData:", hex.hexify(eData))
    if string.len(eData) > 127 then
        edfb = hex.hexf("8782%H", string.len(eData) ) .. eData
    else
        edfb = hex.hexf("87%B", string.len(eData) ) .. eData
    end
    log.output("edfb:", hex.hexify(edfb))
    return edfb
end

local function inc_ssc(ssc1)
    log.output("inc_ssc():")
    log.output("SSC:", hex.hexify(ssc1))
    local ssc1_low = string.sub(ssc1, -3, -1)
    local ssc1_hi = string.sub(ssc1, 1, -4)
    local ssc1_low_num = bin.unpack("%>%L", "\000" .. ssc1_low)
    ssc1_low_num = ssc1_low_num +1
    ssc1_low = hex.hexf("%>%L", ssc1_low_num)
    
    local ssc = ssc1_hi .. string.sub(ssc1_low, -3, -1)
    log.output("SSC:+1", hex.hexify(ssc))
    return ssc
end


local function enc_mac_msg(ssc1, keyEnc, keyMac, apdu)
    log.output("enc_mac_msg():")
    log.output("ORIGINAL APDU:", hex.hexify(apdu))
    local cla_f = bin.flags(string.byte(apdu, 1))
    local edfb
    cla_f = cla_f * bin.flags("0xF0" )
    cla_f = cla_f + bin.flags("0x0C" )
    apdu = string.char(cla_f.asnumber) .. string.sub(apdu, 2, -1)
    local ssc = inc_ssc(ssc1)
    local lc = string.byte(apdu, 5)
    if lc > 0 and string.len(string.sub(apdu, 6)) == 0 then
        local le = lc
        log.output("using LE:", le)
        lc = 0
        edfb = hex.hexf("9701") .. string.char(le)
    else
        edfb = enc_msg(keyEnc, apdu)
        log.output("using LC:", lc)
    end
    local ch = string.sub(apdu, 1, 4)
    log.output("ch:", hex.hexify(ch))
    
    local chPB = ch .. hex.hexf("80000000")
    log.output("ch||PB:", hex.hexify(chPB))
    local chPBedfbPB = pad_iso9797_2(chPB .. edfb)
    log.output("ch||PB||edfb||PB:", hex.hexify(chPBedfbPB))
    local sscchPBedfbPB = ssc .. chPBedfbPB
    log.output("ssc||ch||PB||edfb||PB:", hex.hexify(sscchPBedfbPB))
    local mac1 = Retail_MAC(keyMac, chPB .. edfb, ssc)
    local mac2 = sm.des3_mac(keyMac, sscchPBedfbPB)
    assert(mac1 == mac2)
    mac = mac1
    log.output("mac:", hex.hexify(mac))
    local ccfb = hex.hexf("8e%B", string.len(mac) ) .. mac
    log.output("ccfb:", hex.hexify(ccfb))
    local edfb_ccfb = edfb .. ccfb
    log.output("edfb||ccfb:", hex.hexify(edfb_ccfb))
    local lenAPDU = string.len(edfb_ccfb)
    if lenAPDU > 255 then
        lenAPDU = 255
    end
    local apduENCMAC = string.sub(apdu, 1, 4) .. string.char(lenAPDU) ..  edfb_ccfb
    log.output("ENC MAC APDU:", hex.hexify(apduENCMAC))
    return apduENCMAC, ssc
end



local function dec_mac_msg(ssc1, keyEnc, keyMac, response)
    log.output("dec_mac_msg():")
    if string.len(response) == 2 then
        log.output("dec_mac_msg(): SW only response:", hex.hexify(response))
        return response
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
        if tag == 135 then -- 0x87
            -- decrypt
            local TODEC = string.sub(data, i+3, i+2+le)
            log.output("TAG 87 ENC:", hex.hexify(TODEC))
            assert (string.byte(TODEC, 1) == 1) -- pading indicator
            local dec = sm.des3_dec(keyEnc, string.sub(TODEC, 2, -1), true)
            log.output("TAG 87 dec:", hex.hexify(dec))
            responsedec = responsedec .. unpad_iso9797_2(dec)
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
            ssc = inc_ssc(ssc)
            local MAC = string.sub(data, i+3, i+2+le)
            log.output("TAG 8E MAC:", hex.hexify(MAC))
            local MAC2 = Retail_MAC(keyMac, DATATOMAC, ssc)
            log.output("TAG 8E MAC2:", hex.hexify(MAC2))
            valid = MAC2 == MAC
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

function GemaltoSmartcard.mt:SMTX(ssc, KskEnc, KskSig, apdu)
    local encApdu, ssc = enc_mac_msg(ssc, KskEnc, KskSig, apdu)
    --~ print ("SMTX: apdu:", hex.hexify(apdu))
    --~ print ("SMTX: encApdu SM:", hex.hexify(encApdu))
    local resp, valid
    resp = self:TXchain(string.sub(encApdu, 1, 4), string.sub(encApdu, 6))
    --~ print ("SMTX: resp:", hex.hexify(resp))
    resp, valid, ssc = dec_mac_msg(ssc, KskEnc, KskSig, resp)
    return resp, valid, ssc
end


function GemaltoSmartcard.mt:select_classic_applet()
    log.output("select_classic_applet()")
    local res = self:TX(hex.hexf("00a40400"), hex.hexf("A0000000180C000001634200"))
    if string.sub(res, -2, -1) ~= hex.hexf("9000") then
        res = self:TX(hex.hexf("00a40400"), hex.hexf("A0000000180E000001634200"))
    end
    assert (string.sub(res, -2, -1) == hex.hexf("9000") )
end


function GemaltoSmartcard.mt:select_p15()
    log.output("select_p15()")
    self:select_classic_applet()
    local res = self:TX(hex.hexf("00a40400"), hex.hexf("E828BD080F0147656D20503135"))
    assert (string.sub(res, -2, -1) == hex.hexf("9000") )
end

function GemaltoSmartcard.mt:auto_perform_mutual_authenticate()
    -- funzione fondamentale per per il corretto uso del secure messaging
    -- ha lo scopi di:
    -- 1) individuare una mutua autenticazione valida gi