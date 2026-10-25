 ECB)
        --             -- P2=9B (Key Reference Values->Card Management Key)
        --             -- Lc = 04 (DATA LENGTH)
        --             -- Data Field =
        --             --               7C (TAG)
        --             --               02 (LENGHT)
        --             --               81 00(DataObject->Challenge)
        --             -- Le = 00
        

        local recv = self:transmit(hex.hexf("0087039b047c02810000"))
        assert (string.sub(recv, -2, -1) == hex.hexf('9000'))

        local nonce = string.sub(recv, 5, -3)
        local nonce_enc = self:encrypt(nonce)
        recv = self:transmit(hex.hexf("0087039b0c7c0a8208%S", nonce_enc))
        log.output("external_auth(): ext auth recv=", hex.hexify(recv))
        assert (string.sub(recv, -2, -1) == hex.hexf('9000'))
        return true
    end
end

function Smartcard.mt:select_aid()
    log.output("select_aid()...")
    local recv = self:transmit(self.select_aid_PIV)
    assert (string.sub(recv, -2, -1) == hex.hexf('9000'))
end

local function trim_pad_bn(data, padto)
    data = string.sub(data, -padto)
    data = string.rep("\000", padto - string.len(data)) .. data
    return data
end

local function aes_enc_autopad(key, data)
    if math.mod(string.len(data), aes.BLOCK_LEN) > 0 then
        data = aes.PAD(data)
    end
    return aes.AES_CBC(key, data, true)
end

function Smartcard.mt:import_private_key(ktype, m, e, p, q, iq, dp, dq)

    local padto
    if not self._sm_active then
        self:create_secure_channel()
    end
    
    local algo = "06"
    
    if type(m) == "string" then
    
        if string.len(m) < 256 then
            m = trim_pad_bn(m, 128) -- taglia a 1024 bit
            algo = "06"
        else
            m = trim_pad_bn(m, 256) -- taglia a 2048 bit
            algo = "07"
        end
        padto = string.len(m) / 2        
    end
    assert(e == nil or string.len(e) < 8)
    
    local header = "00db3fff%P"
    local header10 = "10db3fff%P"
    local kidTag = hex.hexf("5c02"..ktype)
    
    -- first, erase:
    local apduErase39 =  hex.hexf(header, kidTag .. hex.hexf(algo.."53023900"))
    local resp = self:sm_transmit(apduErase39)
    local sw = string.sub(resp, -2, -1)
    assert(sw == hexf("9000") )
        
    if not m then
        return
    end
    
    
    if e then
        local eE = aes_enc_autopad(self.factory_dek, e)
        local apduPubExp40 = hex.hexf(header, kidTag .. hex.hexf(algo.."53%B40%P", 2+string.len(eE), eE))
        
        local resp = self:sm_transmit(apduPubExp40)
        local sw = string.sub(resp, -2, -1)
        assert(sw == hexf("9000") )
    
    end


    local apduMod41_a, apduMod41_b
    local eM = aes_enc_autopad(self.factory_dek, m)
    if string.len(m) > 128 then
        local eMTag = kidTag .. hex.hexf(algo.."5382%>%H4182%>%H%S", 4+string.len(eM), string.len(eM), eM)
        local eMTag_a = string.sub(eMTag, 1, 128)
        local eMTag_b = string.sub(eMTag, 129, -1)
        
        apduMod41_a = hex.hexf(header10, eMTag_a )
        apduMod41_b = hex.hexf(header, eMTag_b)
    else
        apduMod41_a = hex.hexf(header,  kidTag .. hex.hexf(algo.."5381%B4181%P", 3+string.len(eM), eM))
    end
    
    local resp = self:sm_transmit(apduMod41_a)
    local sw = string.sub(resp, -2, -1)
    assert(sw == hexf("9000") )
    
    if apduMod41_b then
        local resp = self:sm_transmit(apduMod41_b)
        local sw = string.sub(resp, -2, -1)
        assert(sw == hexf("9000") )
    end

    
    if p then
        p = trim_pad_bn(p, padto)
        local apduP42
        local eP = aes_enc_autopad(self.factory_dek, p)

        if string.len(eP) < 128 then
            apduP42 = hex.hexf(header, kidTag .. hex.hexf(algo.."53%B42%P", 2+string.len(eP), eP))
        else
            apduP42 = hex.hexf(header, kidTag .. hex.hexf(algo.."5381%B4281%P", 3+string.len(eP), eP))
        end
        local resp = self:sm_transmit(apduP42)
        local sw = string.sub(resp, -2, -1)
        assert(sw == hexf("9000") )
    end
    
    if q then
        q = trim_pad_bn(q, padto)
        local apduQ43
        local eQ = aes_enc_autopad(self.factory_dek, q)

        if string.len(eQ) < 128 then
            apduQ43 = hex.hexf(header, kidTag .. hex.hexf(algo.."53%B43%P", 2+string.len(eQ), eQ))
        else
            apduQ43 = hex.hexf(header, kidTag .. hex.hexf(algo.."5381%B4381%P", 3+string.len(eQ), eQ))
        end
        local resp = self:sm_transmit(apduQ43)
        local sw = string.sub(resp, -2, -1)
        assert(sw == hexf("9000") )
    end
    
    if dp then
        dp = trim_pad_bn(dp, padto)
        local apduDP44
        local eDP = aes_enc_autopad(self.factory_dek, dp)

        if string.len(eDP) < 128 then
            apduDP44 = hex.hexf(header, kidTag .. hex.hexf(algo.."53%B44%P", 2+string.len(eDP), eDP))
        else
            apduDP44 = hex.hexf(header, kidTag .. hex.hexf(algo.."5381%B4481%P", 3+string.len(eDP), eDP))
        end
        local resp = self:sm_transmit(apduDP44)
        local sw = string.sub(resp, -2, -1)
        assert(sw == hexf("9000") )
    end
    
    if dq then
        dq = trim_pad_bn(dq, padto)
        local apduDQ45
        local eDQ = aes_enc_autopad(self.factory_dek, dq, true)

        if string.len(eDQ) < 128 then
            apduDQ45 = hex.hexf(header, kidTag .. hex.hexf(algo.."53%B45%P", 2+string.len(eDQ), eDQ))
        else
            apduDQ45 = hex.hexf(header, kidTag .. hex.hexf(algo.."5381%B4581%P", 3+string.len(eDQ), eDQ))
        end
        local resp = self:sm_transmit(apduDQ45)
        local sw = string.sub(resp, -2, -1)
        assert(sw == hexf("9000") )
    end
    
    if iq then
        iq = trim_pad_bn(iq, padto)
        local apduIQ46
        local eIQ = aes_enc_autopad(self.factory_dek, iq, true)

        if string.len(eIQ) < 128 then
            apduIQ46 = hex.hexf(header, kidTag .. hex.hexf(algo.."53%B46%P", 2+string.len(eIQ), eIQ))
        else
            apduIQ46 = hex.hexf(header, kidTag .. hex.hexf(algo.."5381%B4681%P", 3+string.len(eIQ), eIQ))
        end
        local resp = self:sm_transmit(apduIQ46)
        local sw = string.sub(resp, -2, -1)
        assert(sw == hexf("9000") )
    end
    
    local apduEnd47 =  hex.hexf(header, kidTag .. hex.hexf(algo.."53024700"))
    local resp = self:sm_transmit(apduEnd47)
    local sw = string.sub(resp, -2, -1)
    assert(sw == hexf("9000") )
    
end

function Smartcard.mt:change_pin(current_pin, new_pin, is_puk)
    local pin_id = tonumber("80", 16)
    
    if is_puk then
        pin_id = tonumber("81", 16)
    end
    
    current_pin = self:pad_pin(current_pin)
    new_pin = self:pad_pin(new_pin)
    
    if self._sm_active then
        
        local encrcurrent_pin = aes.AES_CBC(self.factory_dek, aes.PAD(current_pin), true)
        local encrnew_pin = aes.AES_CBC(self.factory_dek, aes.PAD(new_pin), true)
        log.output ("encrcurrent_pin:", hex.hexify(encrcurrent_pin))
        log.output ("encrnew_pin:", hex.hexify(encrnew_pin))
        
        local apdu = hex.hexf("002400%B%P", pin_id, encrcurrent_pin .. encrnew_pin)
        log.output(">>", hex.hexify(apdu))
        recv = self:sm_transmit(apdu)
    else
        local apdu = hex.hexf("002400%B%P", pin_id,  current_pin .. new_pin )
        log.output(">>", hex.hexify(apdu))
        recv = self:transmit(apdu)
    end
    
    log.output("change pin recv:", hex.hexify(recv))

    if string.sub(recv, -2, -1) == hex.hexf('9000') then
        return 0
    elseif string.sub(recv, -2, -2) == hex.hexf('63') then
        return 1
    elseif string.sub(recv, -2, -1) == hex.hexf('6983') then
        return 2
    else
        error(SmartcardError.new(sw, 'change_pin error'), 2)
    end

    
end        


function Smartcard.mt:unlock_card(current_puk, new_pin)
      
    current_puk = self:pad_pin(current_puk)
    new_pin = self:pad_pin(new_pin)
    
    if self._sm_active then
        
        local encrcurrent_puk = aes.AES_CBC(self.factory_dek, aes.PAD(current_puk), true)
        local encrnew_pin = aes.AES_CBC(self.factory_dek, aes.PAD(new_pin), true)
        log.output ("encrcurrent_puk:", hex.hexify(encrcurrent_puk))
        log.output ("encrnew_pin:", hex.hexify(encrnew_pin))
        
        local apdu = hex.hexf("002C0080%P", encrcurrent_puk .. encrnew_pin)
        log.output(">>", hex.hexify(apdu))
        recv = self:sm_transmit(apdu)
    else
        local apdu = hex.hexf("002C0080%P", current_puk .. new_pin)
        log.output(">>", hex.hexify(apdu))
        recv = self:transmit(apdu)
    end
    log.output("reset pin recv:", hex.hexify(recv))
   
    
    if string.sub(recv, -2, -1) == hex.hexf('9000') then
        return 0
    elseif string.sub(recv, -2, -2) == hex.hexf('63') then
        return 1
    elseif string.sub(recv, -2, -1) == hex.hexf('6983') then
        return 2
    else
        error(SmartcardError.new(sw, 'unlock_card error'), 2)
    end

end        

function Smartcard.mt:get_certificate(_type)
    local MSCUID, objInfo, certInfo
    
    local crt = ""
    -- if not self._external_auth_use_aes then
        local apdu = hex.hexf("00cb3fff055c03" .. _type .. "00")
        recv = self:sm_transmit(apdu)
        crt =  string.sub(recv, 1, -3)
        while string.sub(recv, -2, -2) == hex.hexf('61') do
            -- GET DATA Card Command
            recv = self:transmit(hex.hexf("00c0000000"))
            crt =  crt .. string.sub(recv, 1, -3)
        end
    -- else
        -- local apdu = hex.hexf("00cb3fff0000055c03" .. _type .. "0000")
        -- recv = self:transmit(apdu)
        -- log.output ("get_certificate recv:", hex.hexify(recv))
        -- crt = recv .. string.sub(recv, 1, -3)
    -- end
    
    local crtDec = Smartcard.parse_tlv_ber(crt)
    local decoded
    if crtDec and type(crtDec[tag_53]) == "string" and string.len(crtDec[tag_53]) > 0 then
        local crtDec1 = Smartcard.parse_tlv_ber(crtDec[tag_53] )
        if crtDec1 and (type(crtDec1[tag_70]) == "string" or type(crtDec1[tag_73]) == "string") then
            decoded = true
            crt = crtDec1[tag_70]
            if string.len(crtDec1[tag_71] or "") > 0 then
                certInfo = string.byte(crtDec1[tag_71], 1)
            end
            MSCUID = crtDec1[tag_72]
            objInfo = crtDec1[tag_73]
        end
    end
    if not decoded then
        crt = string.sub(crt, 9, -6)
    end
    log.output ("cert:", hex.hexify(crt or ''))
    log.output ("certInfo:", certInfo or "<nil>")
    log.output ("MSCUID:", hex.hexify(MSCUID or ''))
    log.output ("objInfo:", hex.hexify(objInfo or ''))
    return crt, certInfo, MSCUID, objInfo
end

function Smartcard.make_tlv_ber(tag, value)
    local l = string.len(value)
    local p
    if type(tag) == "number" then
        if tag > 255 then
            tag = hex.hexf("%H", tag)
        else
            tag = hex.hexf("%B", tag)
        end
    end
    if l < 128 then
        p = "%B"
    elseif l < 256 then
        p = "81%B"
    elseif l < 65536 then
        p = "82%>%H"
    else
        p = "82%>%L"
    end
    return tag .. hex.hexf(p, l) .. value
end

function Smartcard.parse_tlv_ber(data)
    local d = {}
    local i = 0
    local offset, le, tag
    local log_array = {}
    log.output("parse_tlv_ber():", hex.hexify(data or ""))
    while 1 do
        tag = string.byte(data, i+1)
        if tag == 127 then -- 0x7F
            i = i+1
            tag = (tag * 256) + string.byte(data, i+1)
        end
        le = string.byte(data, i+2)
        offset = 0
        if le > 127 then
           offset = (bin.flags(le) * bin.flags("0x0F")).asnumber
           local leS = string.sub(data, i+3, i+2+offset)
           leS = string.rep("\000", 4 - string.len(leS)) .. leS
           le = bin.unpack("%>%L", leS)
           i = i + offset
        end
        table.insert(log_array, string.format("TAG: %02x LEN:%d", tag, le))
        d[tag] = string.sub(data, i+3, i+2+le)
        
        i = i + le + 2
        if i >= string.len(data) then
            break
        end
    end
    log.output(table.concat(log_array, "; "))
    return d
end



local function get_public_key_components(key)
    log.output("get_public_key_components", hex.hexify(key))
    local parsed1 = Smartcard.parse_tlv_ber(key) or {}
    local parsed2 = Smartcard.parse_tlv_ber(parsed1[tonumber("7F49", 16)] or "") or {}
    
    local exponent = parsed2[tonumber("82", 16)]
    local modulus = parsed2[tonumber("81", 16)]
    return modulus, exponent
end

function Smartcard.mt:pad_pin(pin)
    local padding = 8
    pin = string.sub(pin .. string.rep("\255", padding - string.len(pin)), 1, padding)
    return pin
 end

 function Smartcard.mt:get_pin_puk_status(pinRetryMax)
    log.output("Smartcard:get_pin_puk_status:")
    local apdu = hex.hexf("0020008000")
    log.output(">>", hex.hexify(apdu))
    local resPin = self:sm_transmit(apdu)
    
    
    pinRetryMax = pinRetryMax or 10
    local pinRetry
    if resPin == hexf("9000") then
        pinRetry = pinRetryMax
    elseif resPin == hexf("6983") or resPin == hexf("6984") then
        pinRetry = 0
    else
        pinRetry = (bin.flags(string.byte(resPin, -1)) * bin.flags(hex.h2i("F"))).asnumber
    end
    
    if pinRetry > pinRetryMax then 
        pinRetryMax = pinRetry
    end

    return pinRetry, pinRetryMax
end


function Smartcard.mt:verify_pin(pin)
    log.output("Smartcard:verify_pin:", pin)
    self.cached_main_pin = pin
    pin = self:pad_pin(pin)
    if self._sm_active then
        
        local encrPin = aes.AES_CBC(self.factory_dek, aes.PAD(pin), true)
        log.output ("encrPin:", hex.hexify(encrPin))
        
        local apdu = hex.hexf("00200080%P", encrPin)
        recv = self:sm_transmit(apdu)
    else
        local apdu = hex.hexf("00200080%P", pin)
        log.output(">>", hex.hexify(apdu))
        recv = self:transmit(apdu)
    end
    log.output("<<", hex.hexify(recv))
    if string.sub(recv, -2, -1) == hex.hexf('9000') then
        return 0
    elseif string.sub(recv, -2, -2) == hex.hexf('63') then
        return 1
    elseif string.sub(recv, -2, -1) == hex.hexf('6983') then
        return 2
    else
        error(SmartcardError.new(sw, 'verify PIN error'), 2)
    end
    
end

function Smartcard.mt:verify_puk(puk)
    log.output("Smartcard:verify_puk:", puk)
    puk = self:pad_pin(puk)
    if self._sm_active then
        
        local encrPuk = aes.AES_CBC(self.factory_dek, aes.PAD(puk), true)
        log.output ("encrPuk:", hex.hexify(encrPuk))
        
        local apdu = hex.hexf("00240081%P", encrPuk .. encrPuk)
        recv = self:sm_transmit(apdu)
    else
        local apdu = hex.hexf("00240081%P", puk .. puk)
        log.output(">>", hex.hexify(apdu))
        recv = self:transmit(apdu)
    end
    log.output("<<", hex.hexify(recv))
    if string.sub(recv, -2, -1) == hex.hexf('9000') then
        return 0
    elseif string.sub(recv, -2, -2) == hex.hexf('63') then
        return 1
    elseif string.sub(recv, -2, -1) == hex.hexf('6983') then
        return 2
    else
        error(SmartcardError.new(sw, 'verify PUK error'), 2)
    end
    
end



function Smartcard.mt:force_end_transaction(dispo)
    local disabled = self.card:transactionsdisabled()
    if disabled then
        self.card:disabletransactions(false)
    end
    self.card:endtransaction(dispo)
    if disabled then
        self.card:disabletransactions(true)
    end
end

function Smartcard.mt:force_begin_transaction()
    local disabled = self.card:transactionsdisabled()
    if disabled then
        self.card:disabletransactions(false)
    end
    self.card:begintransaction()
    if disabled then
        self.card:disabletransactions(true)
    end
end

function Smartcard.mt:new_generate_keypair(ktype, bits)
         -- CLA=00 ('00' or '10' indicating command chaining)
         -- INS=47
         -- P1=00
         -- P2=9e (PIV Key References-> Card Authentication Key) TABLE 6-1 9e:Card Authentication Key
         -- Lc = 05 (DATA LENGTH)
         -- Data Field =
         --               AC (TAG)
         --               03 (LENGHT)
         --               80 01 07 (Cryptographic mechanism identifier)
         --                        TAG + LENGTH + DATA [07 = RSA 2048 bit modulus, 65,537 = exponent = 2256 - 1] )

    local algo ="06"
    local apdu
    if bits == 2048 then
        algo = "07"
    end
    
    log.output("new_generate_keypair():  ktype",  ktype)
    log.output("new_generate_keypair():  bits",  bits)
    log.output("new_generate_keypair():  self._external_auth_use_aes",  self._external_auth_use_aes)
    local recv, sw
    local key = ""
    
    if self._external_auth_use_aes then
        apdu = "004700" .. ktype .. "05ac038001" .. algo .. "00"
    else
        apdu = "004700" .. ktype .. "05ac038001" .. algo
    end

    for i=1,20 do
        recv = self:sm_transmit(hex.hexf(apdu))
        sw = string.sub(recv or "", -2, -1)
        if not recv or sw == hex.hexf("6300") then
            log.output("new_generate_keypair(): generate key pair error, retry n.", i)
            self:force_end_transaction(pcsc.SCARD_UNPOWER_CARD)
            log.output("new_generate_keypair(): sleeping for sw = 0x6300...")
            w32.sleep(3000)
            log.output("new_generate_keypair(): sleep done!")
            self.card:reconnect()
            self:force_begin_transaction()
            local pcRes, theErrorT = pcall(function()
                if self._sm_active then
                    self:create_secure_channel()
                end
                if self.cached_main_pin then
                    self:verify_pin(self.cached_main_pin)
                end
            end)
            if not pcRes then
                log.output("new_generate_keypair(): sleeping for error:", debug.traceback(theErrorT))
                w32.sleep(3000)
                log.output("new_generate_keypair(): sleep done!")
            end
        else
            break
        end
        key = ""
    end
    
    if self._external_auth_use_aes then
        key = key .. string.sub(recv, 1, -3)
        
        while string.sub(sw, 1, 1) == hex.hexf("61") do
            local recv1 = self:transmit(hex.hexf("00c00000%B", string.byte(sw, 2)))
            key = key .. string.sub(recv1, 1, -3)
            sw = string.sub(recv1, -2, -1)
        end
    else
        -- get response first chunk
        local recv1 = self:transmit(hex.hexf("00c0000000"))
        key = string.sub(recv1, 1, -3)
        if bits == 2048 then
            -- get response second chunk
            local recv2 = self:transmit(hex.hexf("00c0000000"))
            key = key .. string.sub(recv2, 1, -3)
        end
    end
    local modulus, exponent = get_public_key_components(key)
    
    log.output("exponent:", hex.hexify(exponent))
    log.output("modulus:", hex.hexify(modulus))
    return modulus, exponent

end

function Smartcard.mt:rsa(ktype, buffer)
    -- CLA=00
    -- INS=A4
    -- P1=04
    -- P2=00
    -- Lc = 0c (Length of application identifier [09 byte] )
    -- Data Field = AID of the PIV Card Application
    -- Le = Length of application property template

    local ds
    local block_length = 256

    
    if string.len(buffer) > 128 then
        apdu = hex.hexf("108707" .. ktype .. "8A7c820106820081820100") .. string.sub(buffer, 1, 128)
        recv = self:sm_transmit(apdu)
        assert (string.sub(recv, -2, -1) == hex.hexf('9000'))
        apdu = hex.hexf("008707" .. ktype .. "80") .. string.sub(buffer, 129, -1) .. "\000"
        recv = self:sm_transmit(apdu)
        log.output("signature1:", hex.hexify(recv))
        assert (string.sub(recv, -2, -2) == hex.hexf('61'))
        ds = string.sub(recv, 1, -3)
        apdu = hex.hexf("00C00000") .. string.sub(recv, -1, -1)
        -- remove tlv at begin (first 8 bytes) and sw at the end
        recv = self:transmit(apdu)
        log.output("signature2:", hex.hexify(recv))
        assert (string.sub(recv, -2, -1) == hex.hexf('9000'))
        ds = ds .. string.sub(recv, 1, -3)
    else
        apdu = hex.hexf("008706" .. ktype .. "%B7c81858200818180%S00", string.len(buffer) + 8, buffer)
        recv = self:sm_transmit(apdu)
        assert (string.sub(recv, -2, -1) == hex.hexf('9000'))
        ds = string.sub(recv, 1, -3)
    end
    local parsed1 = Smartcard.parse_tlv_ber(ds)
    local parsed2 = Smartcard.parse_tlv_ber(parsed1[tonumber("7C", 16)])
    ds = parsed2[tonumber("82", 16)]
    
    log.output("signature:", hex.hexify(ds))
    
    -- if type(modulus) =="string" and string.len(modulus) > 0 and type(exponent) =="string" and string.len(exponent) > 0 then
        -- local dec = rsa.decrypt(ds, hex.hexify(modulus), hex.hexify(exponent))
        
        -- log.output("dec signature:", hex.hexify(dec))
        -- assert(dec == data)
    -- end
    return ds
end



function Smartcard.mt:write_certificate(certificate, _type, certInfo, MSCUID, objInfo)
    
    local block_length = self._sm_active and 216 or 248
    local data_len = string.len(certificate)
    certInfo = certInfo or 0

    log.output("data_len --> ", data_len)
    log.output("certInfo --> ", certInfo)
    log.output("MSCUID --> ", hex.hexify(MSCUID or ""))
    log.output("objInfo --> ", hex.hexify(objInfo or ""))
    local apdu

   
    local apduData
    if data_len == 0 and not MSCUID and not objInfo then
        apduData = hex.hexf('5c03' .. _type ..'5300')
    else
        local MSCUID_OID, objInfoOID = "", ""
        local certOID = Smartcard.make_tlv_ber(tag_70, certificate)
        if MSCUID then MSCUID_OID = Smartcard.make_tlv_ber(tag_72, MSCUID) end
        if objInfo then objInfoOID = Smartcard.make_tlv_ber(tag_73, objInfo) end
        local data = certOID ..  hex.hexf("7101%B", certInfo) .. MSCUID_OID .. objInfoOID .. hex.hexf("fe00")
        apduData = hex.hexf('5c03' .. _type) .. Smartcard.make_tlv_ber(tag_53, data)
    end

    log.output("apduData:", hex.hexify(apduData))
    -- local apduData_len = string.len(apduData)
    -- local num_chunck = math.floor(apduData_len / block_length)
    -- log.output ("NUM CHUNCK --> ", num_chunck)

    -- local cla = "00"
    -- if num_chunck>1 then
        -- cla = "10"
    -- end
    
    local cla = "10"
    while true do
        local curApduData = string.sub(apduData, 1, block_length)
        apduData = string.sub(apduData, block_length+1, -1)
        if string.len(curApduData) < block_length then
            log.output ("-- LAST CHUNCK in chained APDU ")
            cla = "00"
        else
            log.output (">> CHUNCK in chained APDU ")
        end
        local apdu = hex.hexf(cla .. "db3fff%P", curApduData)
        log.output(">>", hex.hexify(apdu))
        recv = self:sm_transmit(apdu)
        log.output("<<", hex.hexify(recv))
        assert (string.sub(recv, -2, -1) == hex.hexf('9000'))
        if not apduData or apduData == "" then
            break
        end
    end

    log.output("ok")
    return true


        
end


local function GetDataObjectTemplate()
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.DATA),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(true),
        [ CKA.LABEL ] = "",
        -- Data
        [ CKA.VALUE ] = "",
        [ CKA.APPLICATION ] = "",
    }
end


local function GetCertTemplate()
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.CERTIFICATE),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(false),
        [ CKA.LABEL ] = '',
        -- Certificate
        [ CKA.CERTIFICATE_TYPE ] = eCK.CERTIFICATE_TYPE(CKC.X_509),
        [ CKA.TRUSTED ] = eCK.BBOOL(true),
        [ CKA.CERTIFICATE_CATEGORY ] = eCK.ULONG(1), -- user
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        -- Certificate X.509
        [ CKA.SUBJECT ] = "",
        [ CKA.ID ] = '',
        [ CKA.ISSUER ] = "",
        [ CKA.SERIAL_NUMBER ] = "",
        [ CKA.VALUE ] = "",
        [ CKA.URL ] = '',
        [ CKA.HASH_OF_SUBJECT_PUBLIC_KEY ] = '',
        [ CKA.HASH_OF_ISSUER_PUBLIC_KEY ] = '',
        [ CKA.JAVA_MIDP_SECURITY_DOMAIN ] = eCK.ULONG(0),
    }
end

local function GetPubKeyTemplate()
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PUBLIC_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(false),
        [ CKA.LABEL ] = '',
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = '',
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
        [ CKA.MODULUS ] = "",
        [ CKA.MODULUS_BITS ] = "",
        [ CKA.PUBLIC_EXPONENT ] = "",
    }
end

local function GetPrivKeyTemplate()
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PRIVATE_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(false),
        [ CKA.LABEL ] = '',
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = '',
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
        [ CKA.ALWAYS_AUTHENTICATE ] = eCK.BBOOL(true),
        -- RSA Private Key
        [ CKA.MODULUS ] = "",
        [ CKA.PUBLIC_EXPONENT ] = "",
        [ CKA.PRIVATE_EXPONENT ] = -1,
        [ CKA.PRIME_1 ] = -1,
        [ CKA.PRIME_2 ] = -1,
        [ CKA.EXPONENT_1 ] = -1,
        [ CKA.EXPONENT_2 ] = -1,
        [ CKA.COEFFICIENT ] = -1,
    }
end


local key_ids = {
    piv="9a", CERT_PIVAUTH="PIVAUTH",
    sign="9c", CERT_DIGSIG="DIGSIG",
    encr="9d", CERT_KEYMANAGE="KEYMANAGE",
    auth="9e", CERT_CARDAUTH="CARDAUTH",
    match={},
    certs={},
}

local cert_ids = {
    piv="5FC105", CERT_PIVAUTH="CERT_PIVAUTH",
    sign="5fc10a", CERT_DIGSIG="CERT_DIGSIG",
    encr="5fc10b", CERT_KEYMANAGE="CERT_KEYMANAGE",
    auth="5fc101", CERT_CARDAUTH="CERT_CARDAUTH",
    match={},
    certs={},
}


local cert_templates = {
    [1]={value="", key_kid=key_ids.auth, key_label=key_ids.CERT_CARDAUTH, id=cert_ids.CERT_CARDAUTH, cert_path=cert_ids.auth, cert_label=cert_ids.CERT_CARDAUTH, signonly=false},
    [2]={value="", key_kid=key_ids.piv, key_label=key_ids.CERT_PIVAUTH, id=cert_ids.CERT_PIVAUTH, cert_path=cert_ids.piv, cert_label=cert_ids.CERT_PIVAUTH, signonly=false},
    [3]={value="", key_kid=key_ids.sign, key_label=key_ids.CERT_DIGSIG, id=cert_ids.CERT_DIGSIG, cert_path=cert_ids.sign, cert_label=cert_ids.CERT_DIGSIG, signonly=true},
    [4]={value="", key_kid=key_ids.encr, key_label=key_ids.CERT_KEYMANAGE, id=cert_ids.CERT_KEYMANAGE, cert_path=cert_ids.encr, cert_label=cert_ids.CERT_KEYMANAGE, signonly=false},
}

for x=0,19 do
    local kid82=tonumber("82", 16)
    local cert0C = tonumber("0c", 16)
    local id=string.format("KEY-%02X", kid82+x)
    local cert_path = string.format("5fc1%02X", x+cert0C)
    local key_kid=string.format("%02X", kid82+x)
    cert_templates[x+5]={value="", key_kid=key_kid, 
                                   key_label=string.format("KEY-%02X", kid82+x),
                                   id=id, cert_path=cert_path, 
                                   cert_label=string.format("CERT-%02X", x+cert0C), 
                                   signonly=false}
    

end

for i=1,table.getn(cert_templates) do
    local cert_path, key_kid
    key_kid = cert_templates[i].key_kid
    cert_path = cert_templates[i].cert_path
    
    cert_ids.match[cert_path] = key_kid
    cert_ids.certs[cert_path] = cert_templates[i]
    key_ids.match[key_kid] = cert_path
    key_ids.certs[key_kid] = cert_templates[i]
end

local MinKSize, MaxKSize = 1024, 2048
local t = {
    name = 'piv',
    mt = { },
    mechanisms = {
        [ CKM.RSA_PKCS_KEY_PAIR_GEN ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.GENERATE_KEY_PAIR},
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_X_509 ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
    },
    piv_hcard = nil,
    -- le chiavi PIV sono protette da un singolo PIN
    capabilities = { private_attributes_readable=false, always_authenticate_on_cert=false, },
    Smartcard=Smartcard,
}
t.mt.__index = t.mt



function t.mt:initialize(cfg)
    log.output('token-piv:initialize():')
    
    self.capabilities = utility.clone_table(t.capabilities)
    self.piv_hcard = Smartcard.new(self.hcard)
    self.piv_hcard.allow_6310_chained_responses = true
    self.piv_hcard.BSO_PIN = hex.h2i('80')
    self.piv_hcard.BSO_PUK = hex.h2i('81')
    self.mechanisms = utility.clone_table(t.mechanisms)

    self.cert_templates = utility.clone_table(cert_templates)

    self.slow_card = false
    self.userPinInitialized = true
    -- self.request_plugin_valid = w32.request_plugin_valid()
    
    
    self.cfg = cfg or utility.parse_cfg()
    
    
    self.cfg["xproc"] = self.cfg["xproc"] or self.cfg["pxproc"]
    
    if self.cfg["xproc"] then self.cfg["xproc"]=string.lower(self.cfg["xproc"])
    else self.cfg["xproc"]='true' end
    
    if self.cfg["ptk"] == "true" then
        self.piv_hcard.piv_admin_key = self.piv_hcard.piv_admin_key_test
        log.output('token-piv:initialize(): conf: using test keys')
    end

    
    if self._cache_id == nil then
        self.piv_hcard:select_aid()
        self:flush_cache()
    end
end

function t.mt:begin_transaction()
    self.piv_hcard:begin_transaction()
end

function t.mt:end_transaction()
    self.piv_hcard:end_transaction()
end

function t.mt:_call_on_end_transaction()
    log.output('token-piv:_call_on_end_transaction()...')
    self.piv_hcard:on_end_transaction()
end

function t.mt:_call_on_begin_transaction()
    log.output('token-piv:_call_on_begin_transaction()...')
    self.piv_hcard:on_begin_transaction()
end


function t.mt:finalize()
    log.output("token-piv:finalize():", self.userType)
    utility.forget_token_changed(self, "cache")
end

function t.mt:_update_retry_counters()

    log.output("get_pin_puk_status...");
    if (self.info) then
        local pcRes, theErrorT = pcall (function()
            self.info.flags = self.info.flags - CKF.USER_PIN_LOCKED
            self.info.flags = self.info.flags - CKF.USER_PIN_FINAL_TRY
            self.info.flags = self.info.flags - CKF.USER_PIN_COUNT_LOW
            self.info.flags = self.info.flags - CKF.SO_PIN_LOCKED
            self.info.flags = self.info.flags - CKF.SO_PIN_FINAL_TRY
            self.info.flags = self.info.flags - CKF.SO_PIN_COUNT_LOW
            local pinRetry, pinRetryMax, pukRetry, pukRetryMax = self.piv_hcard:get_pin_puk_status()
            log.output("get_pin_puk_status, PIN cur/max", pinRetry, pinRetryMax);
            if pinRetry == 0 then
                self.info.flags = self.info.flags + CKF.USER_PIN_LOCKED
            elseif pinRetry == 1 then
                self.info.flags = self.info.flags + CKF.USER_PIN_FINAL_TRY
            elseif pinRetry < pinRetryMax then
                self.info.flags = self.info.flags + CKF.USER_PIN_COUNT_LOW
            end
            
            self.info.pinRetry    = pinRetry
            self.info.pinRetryMax = pinRetryMax
            self.info.pukRetry    = pukRetry
            self.info.pukRetryMax = pukRetryMax

        end)
        if not pcRes then
            log.output("get_pin_puk_status() error:", theErrorT)
        end
    end
end


function t.mt:add_info()

    local sw = self.piv_hcard:transmit(hex.hexf("0020008000"))
    if sw == hex.hexf("6982") or sw == hex.hexf("6e00")  then
        log.output('token-piv:add_info(): SM required (CLESS interface in use?)')
        self.piv_hcard:create_secure_channel()
    end
    
    local version_major, version_minor = self.piv_hcard:get_PIV_Version()
    
    log.output(string.format("add_info(): version: %02X.%02X :", version_major, version_minor))
    
    if version_major == 2 and version_minor and version_minor >= tonumber("40", 16) then
        self.piv_hcard._external_auth_use_aes = true
        log.output(string.format("add_info(): external_auth() AES enabled for PIV version %02X.%02X :", version_major, version_minor))
        self.info.model = "P-2.40"
    end
    
    local sn, label, license, test_keys = self.piv_hcard:get_sn_label_license()

    if test_keys and (test_keys == 1 or test_keys == "\1") then
        self.piv_hcard.piv_admin_key = self.piv_hcard.piv_admin_key_test
        log.output('token-piv:add_info(): card info: using test keys')
    elseif test_keys and (test_keys == 0 or test_keys == "\0") then
        self.piv_hcard.piv_admin_key = self.piv_hcard.piv_admin_key_prod
        log.output('token-piv:add_info(): card info: using prod keys')
    end
    if sn then
        self._license = license
        self.info.serialNumber = sn
        self.info.label = (label and string.sub(label, 1, 32)) or "P-" .. self.info.serialNumber
    else
        local CIN, sn = self.piv_hcard:get_CIN()
        self.info.serialNumber = sn or self.info.serialNumber
        self.info.label = "P-" .. self.info.serialNumber
    end
    
    local infos
    if self.userPinInitialized then
        self.info.flags = self.info.flags + CKF.USER_PIN_INITIALIZED
    else
        self.info.flags = self.info.flags - CKF.USER_PIN_INITIALIZED
    end
    

    self:_update_retry_counters()
end




function t.mt:get_info()
    if not self.info then
        self.info = {
            label = 'PIV',
            manufacturerID = 'Bit4id',
            model = 'PIV',
            serialNumber = '0000000000000000',
            flags = CKF.RNG + CKF.LOGIN_REQUIRED +
                    CKF.USER_PIN_INITIALIZED + CKF.TOKEN_INITIALIZED,
            ulMaxSessionCount = CK.EFFECTIVELY_INFINITE,
            ulSessionCount = 0,
            ulMaxRwSessionCount = CK.EFFECTIVELY_INFINITE,
            ulRwSessionCount = CK.UNAVAILABLE_INFORMATION,
            ulMaxPinLen = 8,
            ulMinPinLen = 6,
            ulTotalPublicMemory = 65535,
            ulFreePublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulTotalPrivateMemory = 65535,
            ulFreePrivateMemory = CK.UNAVAILABLE_INFORMATION,
            hardwareVersion = { major=1, minor=0},
            firmwareVersion = { major=2, minor=40},
            utcTime = '0000000000000000'
        }
        
        self:add_info()
        if self.cfg["pdefaultlabel"] then
            self.info.label = self.cfg["pdefaultlabel"]
        end
        
        local licValid, license = licensing.is_licensed(self, self.info.serialNumber)
        if licValid and license then
            self._license_valid = license
            self.info.model = string.sub(self.info.model .. " (L)", 1, 16)
            if license and license.pin_lengths then
                self.info.ulMaxPinLen = license.pin_lengths.ulMaxPinLen or self.info.ulMaxPinLen
                self.info.ulMinPinLen = license.pin_lengths.ulMinPinLen or self.info.ulMinPinLen
                log.output("get_info(): license.pin_lengths: ", repr(license.pin_lengths));
                self.info.ulMaxPinLen = math.max(self.info.ulMaxPinLen, 4)
                self.info.ulMinPinLen = math.max(self.info.ulMinPinLen, 4)
                log.output(string.format("get_info(): self.info.ulMinPinLen=%d, self.info.ulMaxPinLen=%d ", self.info.ulMinPinLen, self.info.ulMaxPinLen));
            end
            if license and license.label then
                self.info.label = license.label
            end
            if license and license.serial then
                log.output("get_info(): serialNumber override:", license.serial)
                self.info.serialNumber = license.serial
            end
            if license and license.model then
                log.output("get_info(): model override:", license.model)
                self.info.model = license.model
            end
            if license and license.manufacturerID then
                log.output("get_info(): manufacturerID override:", license.manufacturerID)
                self.info.manufacturerID = license.manufacturerID
            end
            
        end
    end
    
    if self._schedule_update_retry_counters then
        self._schedule_update_retry_counters = false
        self:_update_retry_counters()
    end
    return self.info
end

function t.mt:_get_license()
   
    local info = self.info or self:get_info()
    local pcRes
    local fInfos
    local licenseContents = self._license or ""
    
    if string.len(licenseContents) < 2 then
        return
    end
    local license_len = bin.unpack('%H', string.sub(licenseContents, 1, 2))
    return string.sub(licenseContents, 3, license_len+2)
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
    log.output("verify_pin()", pin, userType, ispuk, contextual_obj)
    
    self._schedule_update_retry_counters = true
    
    if ispuk then
        -- result = 0
        result = self.piv_hcard:verify_puk(pin)
        
        -- log.output("verify_pin(): no PUK verify")
        log.output("verify_puk(): result=", result)
    else
        result = self.piv_hcard:verify_pin(pin)
        log.output("verify_pin(): result=", result)
    end
    if result == 0 then
        self.cached_main_pin = pin
        self.userType = userType
        return CKR.OK
    end

    
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
end




function t.mt:change_pin(oldPin, newPin)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk = false
    if self.userType == CKU.SO then ispuk = true end
    local pcRes, result
    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-piv change_pin(): oldPin:' .. oldPin, 'newPin:' .. newPin)

    if newPin and (string.len(newPin) < info.ulMinPinLen or string.len(newPin) > info.ulMaxPinLen) then
        log.output('token-piv change_pin(): value not in range:', info.ulMinPinLen, info.ulMaxPinLen)
        return CKR.PIN_LEN_RANGE   
    end
    if ispuk and self.puk_not_modifiable then
        log.output('token-piv change_pin(): PUK not modifiable!')
        return CKR.PIN_LEN_RANGE
    end
    local rv
    log.output('token-piv change_pin(): cambio pin...')

    self._schedule_update_retry_counters = true
    
    pcRes, result = pcall(function() 
            return self.piv_hcard:change_pin(oldPin, newPin, ispuk) -- oldPin, newPin, ispuk
        end)

    if result == 0 then
        -- la carta potrebbe dimenticare lo stato di logged in quando si effettua una change pin
        self.cached_main_pin = newPin
        pcRes, result = pcall(function()    
                return self.piv_hcard:verify_pin(newPin)
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
    log.output('token-piv reset_pin(): newPin:', newPin)
    log.output('token-piv reset_pin(): reset pin...')
    if self.userType ~= CKU.SO then
        log.output('token-piv reset_pin(): user not SO!')
        return CKR.USER_TYPE_INVALID
    end
    
    local rv

    self._schedule_update_retry_counters = true
    
    if newPin and (string.len(newPin) < info.ulMinPinLen or string.len(newPin) > info.ulMaxPinLen) then
        log.output('token-piv reset_pin(): value not in range:', info.ulMinPinLen, info.ulMaxPinLen)
        return CKR.PIN_LEN_RANGE   
    end
    
    pcRes, result = pcall(function()
        return self.piv_hcard:unlock_card(self.cached_main_pin, newPin) -- Puk, newPin
        end)
    if pcRes and result == 0 then
        pcRes, result = pcall(function()
            return self.piv_hcard:verify_pin(newPin)
        end)
    end
    if result == 0 then
        self.cached_main_pin = newPin
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

function t.mt:sign_buffer(hKey, pMechanism, pData, allocated_space)
    
    log.output('sign_buffer():', hKey, pMechanism, hex.hexify(pData or ''), allocated_space)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('sign_buffer(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('sign_buffer(): ERROR: non private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    local pcRes, result

    if dataLen > keyBytes or (dataLen > (keyBytes -4) and dataLen <  keyBytes) then
        -- nota: il padding pkcs1 richiede almeno 8 byte di oxFF prima dei dati da firmare
        log.output('sign_buffer(): specified data len invalid: ', dataLen)
        return CKR.DATA_LEN_RANGE
    end
    if allocated_space==nil then
        log.output('sign_buffer(): returning signature length:', keyBytes)
        return CKR.OK, keyBytes
    else
        log.output('sign_buffer(): using RSA-CDS mode on id:', obj.id)
        
        self.piv_hcard:verify_pin(self.cached_main_pin)
        
        local buffer = rsa.pkcs1_bt01_pad(pData, keyBytes)
        
        pcRes, result = pcall(function()
                        return self.piv_hcard:rsa(
                            obj.id, -- ktype
                            buffer
                            )
                        end )
        if pcRes then
            self.contextual_pin_verified = false
            return CKR.OK, result
        else
            log.output('sign_buffer(): error:', result)
        end

    end
    log.output('sign_buffer(): unexpected!')
    return CKR.FUNCTION_FAILED
end



function t.mt:decrypt_buffer(hKey, pMechanism, pData, allocated_space)

    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('decrypt_buffer(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('decrypt_buffer(): ERROR: not a private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end

    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    if dataLen ~= keyBytes then
        log.output('decrypt_buffer(): specified data len invalid: ', dataLen, ', expected:', keyBytes)
        return CKR.ENCRYPTED_DATA_LEN_RANGE
    end
    
    
        
    
    pcall(function()
        if self.cached_main_pin and self.userType == CKU.USER then
            log.output('decrypt_buffer(): verify_pin_main() with:', self.cached_main_pin, self.userType)
            self.piv_hcard:verify_pin(self.cached_main_pin)
        end
    end)
    
    local pcRes, result = pcall(function()
                        return self.piv_hcard:rsa(
                            obj.id, -- ktype
                            pData
                            )
                        end )
    if pcRes then
        self.contextual_pin_verified = false
        local pDataDecrypted = rsa.pkcs1_unpad(result)
        
        if not pDataDecrypted then
            log.output('decrypt_buffer(): cannot decrypt specified data')
            return CKR.ENCRYPTED_DATA_INVALID
        end
        log.output('decrypt_buffer(): pDataDecrypted:', hex.hexify(pDataDecrypted))
        return CKR.OK, pDataDecrypted
    else
        log.output('decrypt_buffer(): error:', result)
    end

    return CKR.FUNCTION_FAILED
end



-- se search_state.lastobj==nil si richiede l'handle del primo oggetto che risponda
-- al template. Altrimenti restituisce il primo oggetto che sia
-- compatibile con il template e abbia handle>search_state.lastobj.
-- quando non ci sono pi