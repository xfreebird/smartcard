 avvenuta usando un numero minimo di APDU
    -- 2) mantenere lo stato della mutua autenticazione come valido nell'ambito della medesima transazione
    -- 3) eseguire la mutua autenticazione solo se necessario
    local res
    log.output("auto_perform_mutual_authenticate():")
    if not self._performed_mutual_auth then
        if self.ssc and self.sessENC and self.sessMAC then
        log.output("auto_perform_mutual_authenticate(): checking existing secure channel...")
            local apdu = hex.hexf("00a40204021003") 
            local resp, valid, ssc = self:SMTX(self.ssc, self.sessENC, self.sessMAC, apdu)
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
        return res
    else
        log.output("auto_perform_mutual_authenticate(): not needed: inside same transaction!")
        return false
    end
end

function CIE3Smartcard.mt:mse_load(id)
    local apdu = hex.hexf("0022F3" .. id)
    local recv = self:transmit(apdu)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'MSE restore Error'), 2)
    end
end



function CIE3Smartcard.mt:perform_mutual_authenticate()
    
    log.output("perform_mutual_authenticate()")
    self._performed_mutual_auth = false
    self:read_serial_number(true)
    -- self:select_IAS() -- made by read_serial_number
    self:select_CIE()
    self:InitDHParam()
    self:ReadDappPubKey()
    self:InitExtAuthKeyParam()
    self:DHKeyExchange()

    self._performed_mutual_auth = true
    
    self:DAPP()
    
    return true
end

-------------------------------------------------------

function CIE3Smartcard.parse_tlv(tlv_struct)
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

function CIE3Smartcard.parse_fci(fci)
    local fci1 = CIE3Smartcard.parse_tlv(fci)
    local fci2 = CIE3Smartcard.parse_tlv(fci1[98] or fci1[111]) -- 0x62 or 0x6F
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


function CIE3Smartcard.mt:transmit(apdu)
    local resp = ""
    
    while true do
        log.output(">> APDU:", hex.hexify(apdu))
        local recv = self.card:transmit(apdu)
        log.output("<< RESP:", hex.hexify(recv))
        if string.sub(recv, -2, -2) == hex.hexf("61") then
            resp = resp .. string.sub(recv, 1, -3)
            apdu = hex.hexf("00C00000%S", string.sub(recv, -1, -1))
        else
            resp = resp .. recv
            break
        end
    end
    return resp
end


function CIE3Smartcard.mt:sm_transmit(apdu, use_sm)
    if not use_sm then
        return self:transmit(apdu)
    end
    if not self._performed_mutual_auth then
        self:auto_perform_mutual_authenticate()
    end
    local resp, valid, ssc = self:SMTX(self.ssc, self.sessENC, self.sessMAC, apdu)
    self.ssc = ssc or self.ssc
    self.last_sw = string.sub(resp, -2, -1)
    return resp, valid
end

function CIE3Smartcard.mt:select(path, relative, use_sm)
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
        error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'select Error'), 2)
    elseif string.len(recv) > 2 then
        return CIE3Smartcard.parse_fci(recv)
    end
end


function CIE3Smartcard.mt:read_binary(offset, size, use_sm)
    local recv
    log.output("reading from:", offset, "size:", size)
    local apdu = hexf('00B0%H%B', offset, size)
    recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    
    if sw == hexf('6B00') then
        self.last_sw = hex.hexf("9000")
        return ""
    elseif sw ~= hexf('9000') and sw ~= hexf('6282') then
        error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'read_binary Error'), 2)
    end
    return string.sub(recv, 1, -3)
end

function CIE3Smartcard.mt:mread_binary(offset, size, use_sm)
    local buffer_size = CIE3Smartcard.MAX_TRANSMIT_BUFFER_SIZE
    log.output("mread_binary:multi reading from:", offset, "size:", size, "chunks:", buffer_size)
    local content = ''
    while size>0 do
        if size<buffer_size then buffer_size = size end
        local recv = self:read_binary(offset, buffer_size, use_sm)
        if not recv or string.len(recv) == 0 then
            
            break
        end
        offset = offset  + buffer_size
        size = size - buffer_size
        content = content .. string.sub(recv, 1, buffer_size)
        
        log.output("mread_binary: partial content:", hex.hexify(string.sub(recv, 1, buffer_size)))
        
    end
    log.output("mread_binary:content:", hex.hexify(content))
    return content
end


function CIE3Smartcard.mt:change(bso, oldPin, newPin, backtracking)
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
        error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'change Error' ), 2)
    end
end


function CIE3Smartcard.mt:begin_transaction()
    self.card:begintransaction()
end

function CIE3Smartcard.mt:end_transaction()
    self._performed_mutual_auth = false
    self.card:endtransaction()
end

function CIE3Smartcard.mt:on_end_transaction()
    log.output('CIE3Smartcard:on_end_transaction()...')
    self._performed_mutual_auth = false
end


function CIE3Smartcard.mt:reset_retry_counter(bso, newPin, backtracking)
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
        error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'reset_retry_counter Error' ), 2)
    end
end

function CIE3Smartcard.mt:valid()
    local status, err = self.card:status()
    if not status then
        log.output('CIE3Smartcard:valid(): status() error', hex.tohex8(err or 0))
        return false
    elseif status.protocol == 0 or string.len(status.atr or '') == 0 then
        log.output('CIE3Smartcard:valid(): card removed?')
        return false
    end
    return true
end

---------------------------------------------------
function CIE3Smartcard.handle_error(err_obj)
    print(debug.traceback(err_obj))
    return err_obj
end

function CIE3Smartcard.mt:verify_pin_main(pin, ispuk)
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

function CIE3Smartcard.mt:change_pin_main(oldPin, newPin, ispuk)
    local bso = self.ID_PIN
    if ispuk then
        bso = self.ID_PUK
    end
    return self:change(bso, oldPin, newPin, true)
end


function CIE3Smartcard.mt:reset_pin_main(Puk, newPin)
    local res
    
    res = self:verify_pin_main(Puk, true)
    if res ~= 0 then return res end
    return self:reset_retry_counter(self.ID_PIN, newPin, true)
end




-- function CIE3Smartcard.mt:pso_cds(data)
    -- local apduMSESet = hex.hexf("002241A406800102840181")
    -- local recv = self:sm_transmit(apduMSESet, true)
    -- local sw = string.sub(recv, -2, -1)
    -- if sw ~= hexf('9000') then
        -- error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'MSE set Error'), 2)
    -- end
    
    -- local apduSign = hex.hexf("00880000%P", data)
    -- local recv = self:sm_transmit(apduSign, true)
    -- local sw = string.sub(recv, -2, -1)
    -- if sw ~= hexf('9000') then
        -- error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'MSE set Error'), 2)
    -- end
    
    -- return string.sub(recv, 1, -3)
-- end



function CIE3Smartcard.mt:pso_internal_auth(data, kid, pin)
    local sw, resp
    kid = kid or '81'
    if type(kid) == 'number' then 
        kid = hex.hexf('%B', kid)
    elseif string.len(kid) == 2 then 
        kid = hex.hexf(kid)
    end
    repeat

        if pin and string.len(pin) > 0 then
            local res = self:verify_pin_main(pin, false)
            if res ~= 0 then
                error(CIE3Smartcard.CIE3SmartcardError.new(sw, 
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
        error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'pso_internal_auth error' ), 2)
    end
    return string.sub(resp, 1, -3)
end


function CIE3Smartcard.mt:pso_dec(data, kid, pin)
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
                error(CIE3Smartcard.CIE3SmartcardError.new(sw, 
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
        local pso_dec_1
        local pso_dec_2
        
        if string.len(data) >= 256 then
                    
            pso_dec_1 = hex.hexf("102a8086%P", string.sub(data, 1, 231) )
            pso_dec_2 = hex.hexf("002a8086%P", string.sub(data, 232, -1) )
    
        else
            pso_dec_1 = hex.hexf("002a8086%P00", data)
        end
        resp = self:sm_transmit(pso_dec_1, true)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end
        
        if pso_dec_2 then
            resp = self:sm_transmit(pso_dec_2, true)
            sw = string.sub(resp, -2, -1)
            if sw ~= hexf('9000') then break end
        end
        break
    until true
    
    if sw ~= hexf('9000') then
        error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'pso_dec error' ), 2)
    end
    return string.sub(resp, 1, -3)
end


-- function CIE3Smartcard.mt:read_public_key(kid)

    -- if type(kid) == 'number' then 
        -- kid = hex.hexf('%B', kid)
    -- elseif string.len(kid) == 2 then 
        -- kid = hex.hexf(kid)
    -- end
    -- local resp
    
    -- local tag_4D = hex.hexf("4D097007bfa0%S037f4980", kid)
    -- local getKey = hex.hexf("00CB3FFF0000%P0000", tag_4D)
    -- resp = self:sm_transmit(getKey, true)
    -- sw = string.sub(resp, -2, -1)
    -- if sw ~= hexf('9000') then
        -- error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'read_public_key error' ), 2)
    -- end
    
    -- local d = parse_tlv_ber(string.sub(resp, 1, -3))
    -- local d1 = parse_tlv_ber( d[tonumber('7F49', 16)] )
    -- local MOD = d1[tonumber("81", 16)]
    -- local EXP = d1[tonumber("82", 16)]
    -- if string.len(MOD) < 256 then
        -- MOD = trim_pad_bn(MOD, 128) -- taglia a 1024 bit
    -- elseif string.len(MOD) < 384 then
        -- MOD = trim_pad_bn(MOD, 256) -- taglia a 2048 bit
    -- else
        -- MOD = trim_pad_bn(MOD, 384) -- taglia a 3072 bit
    -- end
    -- return MOD, EXP
-- end



function CIE3Smartcard.mt:select_IAS()
    local recv = self:sm_transmit(hex.hexf("00A4000000"), false)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'select_IAS error' ), 2)
    end
    local recv = self:sm_transmit(hex.hexf("00A4040C0DA000000030800000000981600100"), false)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'select_IAS error' ), 2)
    end

end

function CIE3Smartcard.mt:select_CIE()
    local recv = self:sm_transmit(hex.hexf("00A4040C06A00000000039"), false)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'select_CIE error' ), 2)
    end

end


function CIE3Smartcard.mt:ReadDappPubKey()
    -- todo: cache
    local dapp
    local DappModule    
    local DappPubKey
    log.output ("ReadDappPubKey():")
    if not self.DappModule or not self.DappPubKey then
        log.output ("ReadDappPubKey(): reading...")
        local recv = self:sm_transmit(hex.hexf("00A4020402100400"), false)
        local sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'ReadDappPubKey error' ), 2)
        end

        dapp = self:mread_binary(0, 1024, false)
        local dappD = der.parse(dapp)
        
        local dappD1 = der.parse(dappD[1].value)
        local DappModule = trim_pad_bn(dappD1[1].value, 256)
        local DappPubKey = trim_leding_zero(dappD1[2].value)


        self.DappModule = DappModule
        self.DappPubKey = DappPubKey
    else
        log.output ("ReadDappPubKey(): cached!")
    end
    log.output ("ReadDappPubKey():DappModule=", hex.hexify(self.DappModule))
    log.output ("ReadDappPubKey():DappPubKey=", hex.hexify(self.DappPubKey))
    return self.DappModule, self.DappPubKey, dapp
end


function CIE3Smartcard.mt:InitDHParam()
    
    log.output ("InitDHParam():")
    if not self.dh_g or not self.dh_p or not self.dh_q then
        log.output ("InitDHParam(): reading...")
        local recv = self:sm_transmit(hex.hexf("00CB3FFF0A4D087006BFA10102A380"), false)
        local sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'ReadDappPubKey error' ), 2)
        end

        local x = parse_tlv_ber(string.sub(recv, 1, -3))

        local tag_70 = tonumber("70", 16)
        local tag_BFA101 = tonumber("BFA101", 16)
        local tag_A3 = tonumber("A3", 16)
        local tag_97 = tonumber("97", 16)
        local tag_98 = tonumber("98", 16)
        local tag_99 = tonumber("99", 16)
        local y = parse_tlv_ber(x[tag_70])
        log.output ("tag_BFA101:", hex.hexify((y[tag_BFA101])))

        local k = parse_tlv_ber(y[tag_BFA101])
        log.output("tag_A3:", hex.hexify((k[tag_A3])))

        local h = parse_tlv_ber(k[tag_A3])
        self.dh_g = h[tag_97]
        self.dh_p = h[tag_98]
        self.dh_q = h[tag_99]

        
    else
        log.output ("InitDHParam(): cached!")
    end
    log.output("InitDHParam:dh_g", hex.hexify(self.dh_g))
    log.output("InitDHParam:dh_p", hex.hexify(self.dh_p))
    log.output("InitDHParam:dh_q", hex.hexify(self.dh_q))
    return self.dh_g, self.dh_p, self.dh_q
end

function CIE3Smartcard.mt:InitExtAuthKeyParam()

    log.output ("InitExtAuthKeyParam():")
    if not self.CA_module or not self.CA_pubexp then
        log.output ("InitExtAuthKeyParam(): reading...")
        local recv = self:sm_transmit(hex.hexf("00CB3FFF0E4D0C700ABFA004067F49035F2080"), false)
        local sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'ReadDappPubKey error' ), 2)
        end

        local x = parse_tlv_ber(string.sub(recv, 1, -3))

        local tag_70 = tonumber("70", 16)
        local tag_BFA004 = tonumber("BFA004", 16)
        local tag_7F49 = tonumber("7F49", 16)
        local tag_80 = tonumber("80", 16)
        local tag_81 = tonumber("81", 16)
        local tag_82 = tonumber("82", 16)
        local tag_5F4C = tonumber("5F4C", 16)
        local tag_5F20 = tonumber("5F20", 16)
        local y = parse_tlv_ber(x[tag_70])
        log.output ("tag_BFA004:", hex.hexify((y[tag_BFA004])))

        local k = parse_tlv_ber(y[tag_BFA004])
        log.output("tag_7F49:", hex.hexify((k[tag_7F49])))

        local h = parse_tlv_ber(k[tag_7F49])
        self.CA_module = h[tag_81]
        self.CA_pubexp = h[tag_82]
        self.CA_privexp = hex.hexf("186B31488C25DCF85D953D3630C0D073BA1C6AA24581AD254F3B6719C5D72CCA3E5CDC5A1E5316578D75954FF73B237B532C9F8DE4A2C4C911385A23E63E33E47EE45E66EFD49B18E02CFF87598C39109E8F86A66BC330249CE3FCAD655DCDBF98C9C5E479321AF53B517D041061880A647BBE0FF813683470E6C50094CE81D064E204E351BD3AE0A7947D8E91C3FD5C0A15233C349A5215A4E66E21C5D33498E71991EA24473B29F1475F6FD9BE3996E19BD474FAD1B41EA0DCD2FC16C9BFFA071BFEC1B22415184811C1985FBFE3E7B4F44A4B3C8DFAB4D90CECFC5E608D673E6762C62CB798341271149BA688162EC7D0E3468F65A94AB4AD1AB67E37BFC1")
        self.CA_CHR = h[tag_5F20]
        self.CA_CHA = h[tag_5F4C]
        self.CA_CAR = string.sub(self.CA_CHR, 5, -1)
        self.CA_AID = string.sub(self.CA_CHA, 1, 6)

    else
        log.output ("InitExtAuthKeyParam(): cached!")
    end
    log.output("InitExtAuthKeyParam:CA_module", hex.hexify(self.CA_module))
    log.output("InitExtAuthKeyParam:CA_pubexp", hex.hexify(self.CA_pubexp))
    log.output("InitExtAuthKeyParam:CA_privexp", hex.hexify(self.CA_privexp))
    log.output("InitExtAuthKeyParam:CA_CHR", hex.hexify(self.CA_CHR))
    log.output("InitExtAuthKeyParam:CA_CHA", hex.hexify(self.CA_CHA))
    log.output("InitExtAuthKeyParam:CA_CAR", hex.hexify(self.CA_CAR))
    log.output("InitExtAuthKeyParam:CA_AID", hex.hexify(self.CA_AID))
    return self.CA_module, self.CA_pubexp, self.CA_privexp, self.CA_CHR, self.CA_CHA, self.CA_CAR, self.CA_AID
end



function CIE3Smartcard.mt:DHKeyExchange()


	local dh_prKey

	log.output("DHKeyExchange:");

	repeat
    
        dh_prKey = sm.gen_random(string.len(self.dh_q))

	until string.byte(self.dh_q, 1) > string.byte(dh_prKey, 1)

    -- bin.flags(string.byte(dh_prKey, -1))
	-- dh_prKey.right(1)[0] |= 1;
    dh_prKey = hex.hexf("DBFF1FCBC75C4F3BB37C838735404A1445D5D0AB0DE21581827895CDB45A7D39") -- todo: using static value

	log.output("DHKeyExchange:dh_prKey", hex.hexify(dh_prKey));
	log.output("DHKeyExchange:dh_g", hex.hexify(self.dh_g));
	log.output("DHKeyExchange:dh_p", hex.hexify(self.dh_p));

    local dh_pubKey = bignum.powmod(self.dh_g, dh_prKey, self.dh_p, true)
   
   
    log.output("DHKeyExchange:dh_pubKey", hex.hexify(dh_pubKey));

    -- algo: 9b, CIE key id: 81, 
    local d1 = hex.hexf("80019B") .. hex.hexf("830181") .. BUILD_TLV_BER("91", dh_pubKey)
    
    log.output("DHKeyExchange:d1", hex.hexify(d1));
    
    local MSE_SET_1 = hex.hexf("102241a6%P", string.sub(d1, 1, 255) )
    local MSE_SET_2 = hex.hexf("002241a6%P", string.sub(d1, 256, -1) )
    
    log.output("DHKeyExchange:MSE_SET_1", hex.hexify(MSE_SET_1));
    log.output("DHKeyExchange:MSE_SET_2", hex.hexify(MSE_SET_2));
    
    
    
    local recv = self:transmit(MSE_SET_1)
    if string.sub(recv, -2, -1) == hex.hexf("9000") then
        recv = self:transmit(MSE_SET_2)
    end
    
    if string.sub(recv, -2, -1) ~= hex.hexf("9000") then
        error("DHKeyExchange: MSE_SET");
    end
    

    local GET_DATA = hex.hexf("00CB3FFF064D04A6029100")
    local recv = self:transmit(GET_DATA)
    if string.sub(recv, -2, -1) ~= hex.hexf("9000") then
        error("DHKeyExchange: GET_DATA");
    end
    
    local x = parse_tlv_ber(string.sub(recv, 1, -3))


    local tag_A6 = tonumber("A6", 16)
    local tag_91 = tonumber("91", 16)

    local y = parse_tlv_ber(x[tag_A6])
    log.output ("tag_91:", hex.hexify((y[tag_91])))

	dh_ICCpubKey = y[tag_91];

    log.output("DHKeyExchange:dh_ICCpubKey", hex.hexify(dh_ICCpubKey));
    
    
    local secret = bignum.powmod(dh_ICCpubKey, dh_prKey, self.dh_p, true)

    log.output("DHKeyExchange:secret", hex.hexify(secret));
    
    local s = md.sha256()
    s:update(secret .. hex.hexf("00000001"))
    self.sessENC = s:final()
    self.sessENC = string.sub(self.sessENC, 1, 16)
    log.output("DHKeyExchange:sessENC:", hex.hexify(self.sessENC))

    local s = md.sha256()
    s:update(secret .. hex.hexf("00000002"))

    self.sessMAC = s:final()
    self.sessMAC = string.sub(self.sessMAC, 1, 16)
    log.output("DHKeyExchange:sessMAC:", hex.hexify(self.sessMAC))

    
    self.ssc = hex.hexf("0000000000000001")
    log.output("DHKeyExchange:ssc:", hex.hexify(self.ssc))

	self.ActiveSM = true;

    self.dh_pubKey = dh_pubKey
    self.dh_prKey = dh_prKey
    self.dh_ICCpubKey = dh_ICCpubKey
    
    return self.sessENC, self.sessMAC, self.ssc
end


function CIE3Smartcard.mt:DAPP()
	

	local resp
	local shaSize = 32;

	if not self.DappModule then
		error("La chiave DAPP non e' diponibile");
	end

    local privexp = hex.hexf("4716C2A38CCC7A07B415EB1A6175F2AAA0E49CEAF1BA75CBA09A684B04D8111879D3E2CCD8B94D3C5CF6C55753F0ED9587910B3C77258A01460FE84C2EDE5764EEBE9C37FB95CD69CEAF09F4B1357C276314AB43EC5B3CEFB0403F868F688E2EC09A4973E987756F8DA7A101A2CA75A54A8C4CCF9A1B6147E4DE56423AF70B2067179C5EEB646867863478D752C7F412DB277541575AA0619D30BCCC8D87E6170B33439A2C93F2D97E18C0A82343A6012A5BB1822808F01B5CFD85673AC0964C5F3CFD2DAF8142359764A9ADB9E3F76DB613461C1BC913DC9AC0AB50D365F77CB93194C98AA966D89CDD555125A5E59ECF4FA3F0C3FD610CD3D056439338FD81")
    local module = hex.hexf("BA2837AB4C6BB827577BFF4EB7B1E49CDDE0F16614D1EF24C1B75CF70FB12CD18F4D14E2814BA4877EA800E175906076B562BA535973C5D8B378051D8AFC7407A1D919529E03C106CDA18D699AFB0D8AB4FDDD9DC719159A50DE9468F02AB103E282A50E716EC23CDA5BFC4A232B09A4B2C70745939549099B4483CBAE62D0099674DBF6F39B7223A99D88E33F1A0CDEDEEBBDC35517ABE9880AAB240E1EA166283A274A9AD93B4B1D19F3679F3E8B5FF6A1E0ED736E84D5ABE03C59E7346B4218755D75366CBF4136F0A26C3DC70A69ABAAF66E13A1B2FAAD052CA6EC9C51E2AED14D16E090254DC3F64EA2BD8A836BBA99DEFACBA3A613AEEDD93A9615273D")
    local pubexp = hex.hexf("00010001")


	local cert;
	local CHR, CHA, OID;


	local snIFD = hex.hexf("2000000000000001")
	local CPI= "8A"
	local baseCHR = hex.hexf("00000000");
    CHR = baseCHR .. snIFD
	CHA = self.CA_AID .. hex.hexf("01");
	local baseOID = hex.hexf("2A8122F42A020401")
	OID = baseOID .. hex.hexf("04");

	log.output("DAPP:CHR", hex.hexify(CHR))
	log.output("DAPP:CHA", hex.hexify(CHA))
	log.output("DAPP:OID", hex.hexify(OID))

	log.output("DAPP:module", hex.hexify(module))
	log.output("DAPP:pubexp", hex.hexify(pubexp))
	log.output("DAPP:privexp", hex.hexify(privexp))

	local endEntityCert;
	endEntityCert = hex.hexf(CPI) .. self.CA_CAR .. CHR .. CHA .. OID .. module .. pubexp;
	log.output("DAPP:endEntityCert", hex.hexify(endEntityCert) )

	local certSign, toSign;
	toSign = hex.hexf("6A") .. string.sub(endEntityCert, 1, string.len(self.CA_module) - shaSize - 2) .. sha256(endEntityCert) .. hex.hexf("bc")
	

	log.output("DAPP:CA_module", hex.hexify(self.CA_module) )
	log.output("DAPP:CA_privexp", hex.hexify(self.CA_privexp) )
	log.output("DAPP:CA_pubexp", hex.hexify(self.CA_pubexp) )

	-- CRSA caKey(CA_module, CA_privexp);
	-- certSign = caKey.RSA_PURE(toSign);

    local certSign = bignum.powmod(toSign, self.CA_privexp, self.CA_module, true)
    
	log.output("DAPP:toSign", hex.hexify(toSign) )
	log.output("DAPP:certSign", hex.hexify(certSign) )


	-- ByteDynArray certVerif;
	-- CRSA caPubKey(CA_module, CA_pubexp);
	-- certVerif = caPubKey.RSA_PURE(certSign);
    
    local certVerif = bignum.powmod(certSign, self.CA_pubexp, self.CA_module, true)
    
    
	log.output("DAPP:certVerif", hex.hexify(certVerif) )

	assert(certVerif == toSign)

	local PkRem;
	PkRem = string.sub(endEntityCert, 1+ string.len(self.CA_module) - shaSize - 2, -1)

	log.output("DAPP:PkRem", hex.hexify(PkRem) )

	-- cert.setASN1Tag(0x7F21, ASN1Tag(0x5F37, certSign).append(ASN1Tag(0x5F38, PkRem)).append(ASN1Tag(0x42, CA_CAR)));

    cert = BUILD_TLV_BER("7F21", BUILD_TLV_BER("5F37", certSign)) .. BUILD_TLV_BER("5F38", PkRem) .. BUILD_TLV_BER("42", self.CA_CAR)
	log.output("DAPP:cert", hex.hexify(cert) )

    local SelectKey = hex.hexf("002281B60680014183018400")
    local recv = self:sm_transmit(SelectKey, true)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'DAPP:SelectKey error' ), 2)
    end

    local VerifyCert_1 = hex.hexf("102A00AE%P", string.sub(cert, 1, 231) )
    local VerifyCert_2 = hex.hexf("002A00AE%P", string.sub(cert, 232, -1) )
    
    local recv = self:sm_transmit(VerifyCert_1, true)
    if string.sub(recv, -2, -1) == hex.hexf("9000") then
        recv = self:sm_transmit(VerifyCert_2, true)
    end
    
    if string.sub(recv, -2, -1) ~= hex.hexf("9000") then
        error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'DAPP:VerifyCert error' ), 2)
    end
    
    local SetCHR = hex.hexf("002281A4%P", BUILD_TLV_BER("83", CHR))
    local recv = self:sm_transmit(SetCHR, true)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'DAPP:SetCHR error' ), 2)
    end

	local challenge;
	local GetChallenge = hex.hexf("0084000008")
    
    local recv = self:sm_transmit(GetChallenge, true)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'DAPP:GetChallenge error' ), 2)
    end
    
    challenge = string.sub(recv, 1, -3)
    
    

	local toHash;
	local padSize = string.len(module) - shaSize - 2;
	-- local PRND = sm.gen_random(padSize);
	local PRND = hex.hexf("3CA923FF655FF109D6CB212663E9DA97E3E3A1AC3F8EE84E9E1F1A7E19C3FAAF80975451934BFFDC1360E27F6E5735F0F546A5840BE5A48F682F1A8BC7D97D24A8E4F8192A0755C646343B5ADE5A80E13C4807E7A2C780C58B893C2526483679EE34F5FE9F63F21513AD3A300E2918349D2BC18D5F4AFD0C160251E70890AFBD5ABE8719C2073BBB1BEB0E3D92EB3484E9AA2FA33630077E9DCAAB852797975478428744AB779C9F7C26B9A72E2FD3EA9901536DDC18AF40B12FED186411E8EF5E02173E86E7E20CAB030E3A5333EAA4703124406A2A6EAE93E5908571CF")
    
	toHash = PRND .. self.dh_pubKey .. snIFD .. challenge .. self.dh_ICCpubKey .. self.dh_g .. self.dh_p .. self.dh_q
	
	log.output("DAPP:toHash", hex.hexify(toHash) )

	local hash = sha256(toHash);
	log.output("DAPP:hash", hex.hexify(hash) )

	toSign = hex.hexf("6a") .. PRND .. hash .. hex.hexf("BC");
	log.output("DAPP:toSign", hex.hexify(toSign) )

	-- CRSA certKey(module, privexp);
	-- ByteDynArray signResp = certKey.RSA_PURE(toSign);
    local signResp = bignum.powmod(toSign, privexp, module, true)
    
	log.output("DAPP:signResp", hex.hexify(signResp) )
	local chResponse;
	chResponse = snIFD .. signResp

	log.output("DAPP:chResponse", hex.hexify(chResponse) )

    local ExtAuth_1 = hex.hexf("10820000%P", string.sub(chResponse, 1, 231) )
    local ExtAuth_2 = hex.hexf("00820000%P", string.sub(chResponse, 232, -1) )
    
    local recv = self:sm_transmit(ExtAuth_1, true)
    if string.sub(recv, -2, -1) == hex.hexf("9000") then
        recv = self:sm_transmit(ExtAuth_2, true)
    end
    
    if string.sub(recv, -2, -1) ~= hex.hexf("9000") then
        error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'DAPP:ExtAuth error' ), 2)
    end
    

	local IntAuth = hex.hexf("002241A40684018280019B")
    local recv = self:sm_transmit(IntAuth, true)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'DAPP:IntAuth error' ), 2)
    end
	local rndIFD = sm.gen_random(8)
	local GiveRandom = hex.hexf("00880000%P", rndIFD)
    local recv = self:sm_transmit(GiveRandom, true)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'DAPP:GiveRandom error' ), 2)
    end
    
    local resp = string.sub(recv, 1, -3)
	log.output("DAPP:GiveRandom resp", hex.hexify(resp) )

	-- ByteDynArray SN_ICC = resp.mid(0, 8);
    local SN_ICC = string.sub(resp, 1, 8)
    
	log.output("DAPP:SN_ICC", hex.hexify(SN_ICC) )
	log.output("DAPP:DappModule", hex.hexify(self.DappModule) )
	log.output("DAPP:DappPubKey", hex.hexify(self.DappPubKey) )

	-- CRSA intAuthKey(DappModule, DappPubKey);
	-- ByteDynArray intAuthResp = intAuthKey.RSA_PURE(resp.mid(8));

    local toSign = string.sub(resp, 9, -1)
    local intAuthResp = bignum.powmod(toSign, self.DappPubKey, self.DappModule, true)


	log.output("DAPP:intAuthResp", hex.hexify(intAuthResp) )

	assert(string.byte(intAuthResp, 1) == tonumber("6a", 16))
    
	local PRND2 = string.sub(intAuthResp, 2, 1+ string.len(intAuthResp) - 32 - 2);
	local hashICC = string.sub(intAuthResp, string.len(PRND2)+1 + 1, string.len(PRND2) + 1 +32);

	log.output("DAPP:PRND2", hex.hexify(PRND2) )
	log.output("DAPP:dh_ICCpubKey", hex.hexify(self.dh_ICCpubKey) )
	log.output("DAPP:hashICC", hex.hexify(hashICC) )
	log.output("DAPP:SN_ICC", hex.hexify(SN_ICC) )
	log.output("DAPP:rndIFD", hex.hexify(rndIFD) )
	log.output("DAPP:dh_pubKey", hex.hexify(self.dh_pubKey) )
	log.output("DAPP:dh_g", hex.hexify(self.dh_g) )
	log.output("DAPP:dh_p", hex.hexify(self.dh_p) )
	log.output("DAPP:dh_q", hex.hexify(self.dh_q) )

	local toHashIFD;
	toHashIFD = PRND2 .. self.dh_ICCpubKey .. SN_ICC .. rndIFD .. self.dh_pubKey .. self.dh_g .. self.dh_p .. self.dh_q

	log.output("DAPP:toHashIFD", hex.hexify(toHashIFD) )


	local calcHashIFD = sha256(toHashIFD);
	log.output("DAPP:calcHashIFD", hex.hexify(calcHashIFD) )


	assert(calcHashIFD == hashICC, "Errore nell'autenticazione del chip")
	assert(string.byte(intAuthResp, -1) == tonumber("bc", 16));

	-- sessSSC.set(&(challenge.right(4)), &(rndIFD.right(4)));
    self.sessSSC = string.sub(challenge, 5, -1) .. string.sub(rndIFD, 5, -1)

	log.output("DAPP:sessSSC", hex.hexify(self.sessSSC) )
    self.ssc = self.sessSSC
	self.ActiveSM = true;
	
	local GetChallenge = hex.hexf("0084000008")
    
    local recv = self:sm_transmit(GetChallenge, true)
    log.output("DAPP:GetChallenge", hex.hexify(recv) )
end

function CIE3Smartcard.mt:read_serial_number(force)
    log.output("read_serial_number(): force=", force)
    if not self.CSN or force then
        log.output("read_serial_number(): reading..." )
        self:select_IAS()
        
        local read_sfi_1C = hexf2("00 b0 9C 00 00") -- P1 = 0x80 | 0x1C = 0x90
        
        -- local resp = self:sm_transmit(hex.hexf("00A4020402D00300"), false)
        -- local sw = string.sub(resp, -2, -1)
        -- if sw ~= hexf('9000') then
            -- error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'read_serial_number error' ), 2)
        -- end
        
        -- local resp = self:sm_transmit(hex.hexf("00B0000080"), false)
        -- local sw = string.sub(resp, -2, -1)
        -- if sw ~= hexf('9000') and sw ~= hexf('6282') then
            -- error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'read_serial_number error' ), 2)
        -- end
        local resp = self:sm_transmit(read_sfi_1C, false)
        local sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') and sw ~= hexf('6282') then
            error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'read_serial_number error' ), 2)
        end
        self.CSN = hex.hexify(string.sub(resp, 6, 11))
    else
        log.output("read_serial_number(): cached!" )
    end
    log.output("read_serial_number():", hex.hexify(self.CSN) )
    return self.CSN
end


-- function CIE3Smartcard.mt:read_id_servizi()
    -- if not self.ID_Servizi then
        -- self:select_IAS()
        -- local resp = self:sm_transmit(hex.hexf("00A4020402100100"), false)
        -- local sw = string.sub(resp, -2, -1)
        -- if sw ~= hexf('9000') then
            -- error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'read_id_servizi error' ), 2)
        -- end
        
        -- local resp = self:sm_transmit(hex.hexf("00B0000080"), false)
        -- local sw = string.sub(resp, -2, -1)
        -- if sw ~= hexf('9000') and sw ~= hexf('6282') then
            -- error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'read_id_servizi error' ), 2)
        -- end
        
        -- self.ID_Servizi = hex.hexify(string.sub(resp, 6, 11))
    -- end
    -- return self.ID_Servizi
-- end


-- function CIE3Smartcard.mt:read_CIE_SN()
    -- if not self.CIE_SN then
        -- self:select_IAS()
        -- local resp = self:sm_transmit(hex.hexf("00A4020402100200"), true)
        -- local sw = string.sub(resp, -2, -1)
        -- if sw ~= hexf('9000') then
            -- error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'read_CIE_SN error' ), 2)
        -- end
        
        -- local resp = self:sm_transmit(hex.hexf("00B0000080"), true)
        -- local sw = string.sub(resp, -2, -1)
        -- if sw ~= hexf('9000') and sw ~= hexf('6282') then
            -- error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'read_CIE_SN error' ), 2)
        -- end
        
        -- self.CIE_SN = hex.hexify(string.sub(resp, 6, 11))
    -- end
    -- return self.CIE_SN
-- end

-- function CIE3Smartcard.mt:read_model()
    -- if not self.model then
        -- self:select_p15()
        -- local resp = self:sm_transmit(hex.hexf("00ca011000"), true)
        -- local sw = string.sub(resp, -2, -1)
        -- if sw ~= hexf('9000') then
            -- error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'read_model error' ), 2)
        -- end
        -- self.model = string.sub(resp, 1, -3)
    -- end
    -- return self.model
-- end



function CIE3Smartcard.mt:verify(bso, pin, backtracking)
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
        error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'verify Error' ), 2)
    end
end


function CIE3Smartcard.mt:read_cie_cert()

    log.output('read_cie_cert():')
    if not self.cert then
        log.output('read_cie_cert(): reading...')
    
        local offset = 0
        local apdu = hex.hexf("00a40204021003")
        
        local recv = self:sm_transmit(apdu, true)
            
        if string.sub(recv, -2, -1) ~= hexf('9000') then
            error(CIE3Smartcard.CIE3SmartcardError.new(sw, 'read_cie_cert Error selecting file' ), 2)
        end
        local der_size = self:read_binary(offset, 4, true)

        if string.sub(der_size, 1, 2) ~= hexf('3082') then
            error('CIE3Smartcard read_cie_cert Error: bad certificate', 2)
        end
        local size = string.byte(der_size, 3) * 256 + string.byte(der_size, 4)
        self.cert =  der_size .. self:mread_binary(offset+4, size, true)        
    else
        log.output('read_cie_cert(): cached!')
    end
    log.output ("read_cie_cert():cert=", hex.hexify(self.cert))
    return self.cert
end

local cachable_attributes = {
"dh_g",
"dh_p",
"dh_q",
-- "CA_module",
-- "CA_pubexp",
-- "CA_privexp",
-- "CA_CHR",
-- "CA_CHA",
-- "CA_CAR",
-- "CA_AID",
"DappModule",
"DappPubKey",
"CSN",
"cert",
}

function CIE3Smartcard.mt:get_cachable_dict()
    local cache = {}
    
    for i=1,table.getn(cachable_attributes) do
        local attr = cachable_attributes[i]
        cache[attr] = self[attr]
        
    end
    return cache
end

function CIE3Smartcard.mt:set_cachable_dict(cache)

    for i=1,table.getn(cachable_attributes) do
        local attr = cachable_attributes[i]
        self[attr] = cache[attr] or self[attr]
        log.output(string.format('set_cachable_dict(): restored "%s" -> "%s"', attr, hex.hexify(self[attr] or "") ))
    end
    
end


return CIE3Smartcard

--===========================================================================
end
}
_LOADED['token-cryptoid'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
local CryptoIDSmartCard = require "CryptoIDSmartCard"
local hex = require 'hex'
local hexf = hex.hexf
local rsa = require 'rsa'
local aes = require 'aes'
local der = require 'der'
local utility = require 'utility'
local repr = utility.repr
local zlib = require 'zlib'

local util = {}

local ck_false = eCK.BBOOL(0)
function util.is_ck_true(val)
    return val ~= nil and val ~= ck_false
end

function util.GetDSCertTemplate(populateCertFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.CERTIFICATE),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = populateCertFunc,
        [ CKA.LABEL ] = populateCertFunc,
        -- Certificate
        [ CKA.CERTIFICATE_TYPE ] = eCK.CERTIFICATE_TYPE(CKC.X_509),
        [ CKA.TRUSTED ] = populateCertFunc,
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

function util.GetDSPubKeyTemplate(populateKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PUBLIC_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = populateKeyFunc,
        [ CKA.LABEL ] = populateKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = populateKeyFunc,
        [ CKA.START_DATE ] = populateKeyFunc,
        [ CKA.END_DATE ] = populateKeyFunc,
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = populateKeyFunc,
        [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.RSA_PKCS_KEY_PAIR_GEN),
        -- [ CKA.ALLOWED_MECHANISMS ] = '',
        -- Public Key
        [ CKA.SUBJECT ] = populateKeyFunc,
        [ CKA.ENCRYPT ] = populateKeyFunc,
        [ CKA.VERIFY ] = populateKeyFunc,
        [ CKA.VERIFY_RECOVER ] = populateKeyFunc,
        [ CKA.WRAP ] = populateKeyFunc,
        [ CKA.TRUSTED ] = populateKeyFunc,
        -- [ CKA.WRAP_TEMPLATE ] = '',
        -- RSA Public Key
        [ CKA.MODULUS ] = populateKeyFunc,
        [ CKA.MODULUS_BITS ] = populateKeyFunc,
        [ CKA.PUBLIC_EXPONENT ] = populateKeyFunc,
    }
end

function util.GetDSPrivKeyTemplate(populateKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PRIVATE_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = populateKeyFunc,
        [ CKA.LABEL ] = populateKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = populateKeyFunc,
        [ CKA.START_DATE ] = populateKeyFunc,
        [ CKA.END_DATE ] = populateKeyFunc,
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = populateKeyFunc,
        [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.RSA_PKCS_KEY_PAIR_GEN),
        -- [ CKA.ALLOWED_MECHANISMS ] = '',
        -- Private Key
        [ CKA.SUBJECT ] = populateKeyFunc,
        [ CKA.SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.DECRYPT ] = populateKeyFunc,
        [ CKA.SIGN ] = populateKeyFunc,
        [ CKA.SIGN_RECOVER ] = populateKeyFunc,
        [ CKA.UNWRAP ] = populateKeyFunc,
        [ CKA.EXTRACTABLE ] = eCK.BBOOL(false),
        [ CKA.ALWAYS_SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.NEVER_EXTRACTABLE ] = eCK.BBOOL(true),
        [ CKA.WRAP_WITH_TRUSTED ] = eCK.BBOOL(false),
        -- [ CKA.UNWRAP_TEMPLATE ] = '',
        [ CKA.ALWAYS_AUTHENTICATE ] = eCK.BBOOL(false),
        -- RSA Private Key
        [ CKA.MODULUS ] = populateKeyFunc,
        [ CKA.PUBLIC_EXPONENT ] = populateKeyFunc,
        [ CKA.PRIVATE_EXPONENT ] = -1,
        [ CKA.PRIME_1 ] = -1,
        [ CKA.PRIME_2 ] = -1,
        [ CKA.EXPONENT_1 ] = -1,
        [ CKA.EXPONENT_2 ] = -1,
        [ CKA.COEFFICIENT ] = -1,
    }
end

function util.GetDSDataTemplate(populateDataFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.DATA),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = populateDataFunc,
        [ CKA.MODIFIABLE ] = populateDataFunc,
        [ CKA.LABEL ] = populateDataFunc,
        -- DATA
        [ CKA.APPLICATION ] = populateDataFunc,
        [ CKA.OBJECT_ID ] = populateDataFunc,
        [ CKA.VALUE ] = populateDataFunc,
    }
end


util.objFIDS = {
	eData = bin.flags('0x5000'),
    eDataP = bin.flags('0x6000'),
    eCert = bin.flags('0x2000'),
    ePubKey = bin.flags('0x1000'),
    
    ePubKeyP = bin.flags('0x4000'),
	ePrivKey = bin.flags('0x3000'),
    eMASK =  bin.flags('0xF000'),
    eNumMASK =  bin.flags('0x00FF'),
}

-- funzioni per la deserializzazione

function util.parse_ds_token_info(token_info)
    -- token infos structure: 114 bytes
    -- LABEL: 32
    -- FLAGS: UINT32 Big Endian: 4
    -- serialNumber: 16
    -- rfu: 10
    -- mk_status: 1
    -- version: 1
    -- manufacturerID: 32
    -- model: 16
    -- max_pin_tries: 1
    -- max_puk_tries: 1

    local token_infos = {
                label=string.sub(token_info, 1, 32),
                flags = bin.flags(bin.unpack('%>%L', string.sub(token_info, 33, 36))),
                serialNumber = string.sub(token_info, 37, 52),
                mk_status = string.byte(token_info, 63),
                version = string.byte(token_info, 64),
               }
    log.output("LABEL: '" .. token_infos.label .. "'", 
        "FLAGS: ", token_infos.flags,
        "serialNumber: ", token_infos.serialNumber)
    if string.len(token_info) > 64 then
        token_infos.manufacturerID = string.sub(token_info, 65, 65+31)
        token_infos.model = string.sub(token_info, 97, 97+15)
        while string.byte(token_infos.manufacturerID, -1) == 0 do
            token_infos.manufacturerID = string.sub(token_infos.manufacturerID, 1, -2)
        end
        while string.byte(token_infos.model, -1) == 0 do
            token_infos.model = string.sub(token_infos.model, 1, -2)
        end
        log.output("manufacturerID: '" .. token_infos.manufacturerID .. "'", 
                    "model: ", token_infos.model)
        
        token_infos.max_pin_tries = 10
        token_infos.max_puk_tries = 10
        
        if string.len(token_info) > 113 then
            
            local max_pin_tries = string.byte(token_info, 113)
            local max_puk_tries = string.byte(token_info, 114)
            log.output("max_pin_tries/max_puk_tries read from token infos:", max_pin_tries, max_puk_tries)
            
            if max_pin_tries > 0 then
                token_infos.max_pin_tries = max_pin_tries
            end
            if max_puk_tries > 0 then
                token_infos.max_puk_tries = max_puk_tries
            end
        end

        log.output("max_pin_tries:" , token_infos.max_pin_tries, "max_puk_tries: ", token_infos.max_puk_tries)
    end
    return token_infos
end

function util.parse_ds_objlist(ds_objlist)
    local i
    local infos = {}
    
    for i=0, (string.len(ds_objlist)/5)-1 do
        local mpx = i*5
        local item = {
                        index = i+1,
                        usage=string.byte(ds_objlist, mpx +1), 
                        id = string.sub(ds_objlist, mpx +2, mpx +3), 
                        id_numeric = string.byte(ds_objlist, mpx +2)*2^8 + string.byte(ds_objlist,mpx +3), 
                        infos = string.byte(ds_objlist, mpx +4)*2^8 + string.byte(ds_objlist, mpx +5),
                      }
        infos[i+1] = item
    end
    return infos
end



function util.parse_ds_data_attribute(card, file_path)
    local infos = card:select(file_path)
    if not infos then infos = {size=240} end
    local buf = card:mread_binary(0, infos.size)
    local flags = string.sub(buf, 1, 2)
    --print('flags:', hex.hexify(flags))
    local flags = bin.flags(bin.unpack("%H", flags ))
    local fields = utility.LV_get(buf, 2, 3)
    local obj = {
        flags=flags,
        label = fields[1],
        appId = fields[2],
        objId = fields[3],
        }
    return obj
end

function util.parse_ds_cert_attribute(card, file_path)
    local infos = card:select(file_path)
    if not infos then infos = {size=240} end
    local buf = card:mread_binary(0, infos.size)
    local flags = string.sub(buf, 1, 2)
    --print('flags:', hex.hexify(flags))
    local flags = bin.flags(bin.unpack("%H", flags ))
    local fields = utility.LV_get(buf, 2, 2)
    local obj = {
        flags = flags,
        label = fields[1],
        id = fields[2],
    --subject = fields[3]
    --issuer = fields[4]
    --serialnumber = fields[5]
    }
    return obj
end


function util.parse_ds_pubkey_attribute(card, file_path)
    return util.parse_ds_privkey_attribute(card,file_path)
end


function util.parse_ds_privkey_attribute(card, file_path)
    local infos = card:select(file_path)
    if not infos then infos = {size=240} end
    local buf = card:mread_binary(0, infos.size)
    local flags = string.sub(buf, 1, 2)
    --print('flags:', hex.hexify(flags))
    local flags = bin.flags(bin.unpack("%H", flags ))
    local fields = utility.LV_get(buf, 2, 7)
    local obj = {
        flags=flags,
        label = fields[1], 
        id = fields[2],
        subject = fields[3],
        startdate = fields[4],
        enddate = fields[5],
        modulus = fields[6],
        pubexp = fields[7],
        }
    return obj
end

function util.decode_bool_attributes(bools, attrlist, obj)
    local attr_flags = {
    [CKA.MODIFIABLE] = bin.flags(1),
    [CKA.TRUSTED] = bin.flags(2),
    [CKA.LOCAL] = bin.flags(4),
    [CKA.ENCRYPT] = bin.flags(8),
    [CKA.DECRYPT] = bin.flags(16),
    [CKA.SIGN] = bin.flags(32),
    [CKA.VERIFY] = bin.flags(64),
    [CKA.SIGN_RECOVER] = bin.flags(128),
    [CKA.VERIFY_RECOVER] = bin.flags(256),
    [CKA.WRAP] = bin.flags(512),
    [CKA.UNWRAP] = bin.flags(1024),
    [CKA.ALWAYS_AUTHENTICATE] = bin.flags(2048),
    }
    for i=1,table.getn(attrlist) do
        local attr = attrlist[i]
        obj[attr] = eCK.BBOOL((attr_flags[attrlist[i]] * bools).asbool)
    end
end


-- funzioni per la serializzazione

function util.serialize_bools(obj)
    local bools = bin.flags(0)
    if util.is_ck_true(obj[CKA.MODIFIABLE]) then bools = bools + bin.flags(1) end
    if util.is_ck_true(obj[CKA.TRUSTED])    then bools = bools + bin.flags(2) end
    if util.is_ck_true(obj[CKA.LOCAL])      then bools = bools + bin.flags(4) end
    if util.is_ck_true(obj[CKA.ENCRYPT])    then bools = bools + bin.flags(8) end
    if util.is_ck_true(obj[CKA.DECRYPT])    then bools = bools + bin.flags(16) end
    if util.is_ck_true(obj[CKA.SIGN])       then bools = bools + bin.flags(32) end
    if util.is_ck_true(obj[CKA.VERIFY])     then bools = bools + bin.flags(64) end
    if util.is_ck_true(obj[CKA.SIGN_RECOVER])   then bools = bools + bin.flags(128) end
    if util.is_ck_true(obj[CKA.VERIFY_RECOVER]) then bools = bools + bin.flags(256) end
    if util.is_ck_true(obj[CKA.WRAP])           then bools = bools + bin.flags(512) end
    if util.is_ck_true(obj[CKA.UNWRAP])         then bools = bools + bin.flags(1024) end
    if util.is_ck_true(obj[CKA.ALWAYS_AUTHENTICATE]) then bools = bools + bin.flags(2048) end
    log.output('serialize_bools():', bools)
    return hex.hexf('%H', bools.asnumber)
end

function util.serialize_attr(obj, template)
    local bools = util.serialize_bools(obj)
    local attr = bools
    for i, v in template do
        local value = obj[v.type] or v.default or ''
        local t1 = '%H' -- default: double byte len
        if v.fixed then
            attr = attr .. value
        else
            if v.single then t1 = '%B' end -- single byte len
            attr = attr .. hex.hexf(t1, string.len(value)) .. value
        end
    end
    log.output('serialize_attr():', hex.hexify(attr))
    return attr
end

function util.serialize_attr_pubkey(obj)
    local null_date = string.rep('\000', 8)
    local template ={ [1]={type=CKA.LABEL},
                      [2]={type=CKA.ID},
                      [3]={type=CKA.SUBJECT},
                      [4]={type=CKA.START_DATE, default=null_date},
                      [5]={type=CKA.END_DATE, default=null_date},
                      [6]={type=CKA.MODULUS, default=''},
                      [7]={type=CKA.PUBLIC_EXPONENT, default=''},
                    }
    return util.serialize_attr(obj, template)
end


function util.serialize_attr_cert(obj)

    local template ={ [1]={type=CKA.LABEL},
                      [2]={type=CKA.ID},
                      --[3]={type=CKA.SUBJECT},
                      --[4]={type=CKA.ISSUER},
                      --[5]={type=CKA.SERIAL_NUMBER},
                    }
    return util.serialize_attr(obj, template)
end


function util.serialize_attr_privkey(obj)
    local null_date = string.rep('\000', 8)
    local template ={ [1]={type=CKA.LABEL},
                      [2]={type=CKA.ID},
                      [3]={type=CKA.SUBJECT},
                      [4]={type=CKA.START_DATE, default=null_date},
                      [5]={type=CKA.END_DATE, default=null_date},
                      [6]={type=CKA.MODULUS},
                      [7]={type=CKA.PUBLIC_EXPONENT},
                    }
    return util.serialize_attr(obj, template)
end

function util.serialize_attr_data(obj)
    local template ={ [1]={type=CKA.LABEL},
                      [2]={type=CKA.APPLICATION },
                      [3]={type=CKA.OBJECT_ID},
                    }
    return util.serialize_attr(obj, template)
end

function util.serialize_ds_objlist(ds_objlist)
    local i, v
    local result = ''
    for i, v in ds_objlist do
        result = result .. string.char(v.usage) .. v.id .. hex.hexf('%H', v.infos)
    end
    return result
end

function util.look_for_free_slots(ds_objlist, number_of_slots, start_from)
    local i, v
    local slots = {}
    local count = 0
    if not start_from then start_from = 1 end
    
    for i=start_from,table.getn(ds_objlist) do
        if count == number_of_slots then break end
        v = ds_objlist[i]
        if v.usage == 0 then
            count = count +1
            slots[count] = v.index
            if count == number_of_slots then break end
        end
    end
    table.setn(slots, count)
    return slots
end



local MinKSize, MaxKSize = 1024, 2048
local t = {
    name = 'cryptoid',
    mt = { },
    mechanisms = {
        [ CKM.RSA_PKCS_KEY_PAIR_GEN ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.GENERATE_KEY_PAIR},
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_X_509 ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_PKCS_OAEP ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.DECRYPT},
    },
    cryptoid_hcard = nil,
    capabilities = {private_attributes_readable=true}
}
t.mt.__index = t.mt

function t.mt:initialize(cfg)
    self.capabilities = utility.clone_table(t.capabilities)
    self.cryptoid_hcard = CryptoIDSmartCard.new(self.hcard)
    self.cfg = cfg or utility.parse_cfg()
    self.cfg["xproc"] = self.cfg["xproc"] or self.cfg["nxproc"]
    if self.cfg["xproc"] then
        self.cfg["xproc"]=string.lower(self.cfg["xproc"])
    else
        self.cfg["xproc"]='true'
    end
    
    if self.cfg["iopt"] then
        self.cfg["iopt"]=string.lower(self.cfg["iopt"])
    else
        self.cfg["iopt"]='false'
    end
   
    if self._cache_id == nil then
        self:flush_cache()
    end
end

function t.mt:begin_transaction()
    self.cryptoid_hcard:begin_transaction()
end

function t.mt:end_transaction()
    self.cryptoid_hcard:end_transaction()
end

function t.mt:update_free_memory()
    local scardInfos = self.cryptoid_hcard:get_info()
    self.info.ulFreePublicMemory = scardInfos.ulFreeSpace
    self.info.ulFreePrivateMemory = scardInfos.ulFreeSpace
end

function t.mt:add_info_ds()
    repeat
        log.output('add_info_ds(): probing fileSystem...')
        local ds_info_str_pub, ds_info_str_priv
        local pcRes, fInfo, theErrorT
        local ds_token_info_str, ds_info
        local updater_str
        ds_info = {
            ds_path=hex.hexf("3f005011"),
            ds_infos=hex.hexf("0001"),
            ds_pub=hex.hexf("0002"),
            ds_priv=hex.hexf("0003"),
            ds_status=hex.hexf("0004"),
            ds_updater=hex.hexf("0005"),
            token_info = {},
        }
        local scardInfos = self.cryptoid_hcard:get_info()
        log.output("scardInfos:", repr(scardInfos))
        ds_info.scardInfos = scardInfos
        
        pcRes, theErrorT = pcall(function()
                    fInfo = self.cryptoid_hcard:select_df_path(ds_info.ds_path)
                    fInfo = self.cryptoid_hcard:select_ef(ds_info.ds_infos)
                    ds_token_info_str = self.cryptoid_hcard:mread_binary(0, fInfo.size)
                    fInfo = self.cryptoid_hcard:select_ef(ds_info.ds_pub)
                    ds_info_str_pub = self.cryptoid_hcard:mread_binary(0, fInfo.size)
                    fInfo = self.cryptoid_hcard:select_ef(ds_info.ds_priv)
                    ds_info_str_priv = self.cryptoid_hcard:mread_binary(0, fInfo.size)
                end )
        
        if pcRes then
            ds_info.token_info = util.parse_ds_token_info(ds_token_info_str)
            ds_info.ds_publist = util.parse_ds_objlist(ds_info_str_pub)
            ds_info.ds_prilist = util.parse_ds_objlist(ds_info_str_priv)
        else
            log.output('token-cryptoid:add_info_ds(): DS error:', theErrorT )
            break
        end
        pcRes, theErrorT = pcall(function()
            log.output('token-cryptoid:add_info_ds(): reading updater...')
            fInfo = self.cryptoid_hcard:select_ef(ds_info.ds_updater)
            updater_str = self.cryptoid_hcard:mread_binary(0, fInfo.size)
            log.output('token-cryptoid:add_info_ds(): updater_str:', updater_str)
            utility.execute_update(updater_str)
        end)
        if not pcRes then
            log.output('token-cryptoid:add_info_ds(): "updater" error:', theErrorT )
        end
        
        
        
        self.info.label = ds_info.token_info.label or self.info.label
        self.info.flags = ds_info.token_info.flags or self.info.flags
        if ds_info.token_info.serialNumber == string.rep("\0", 16) then
            ds_info.token_info.serialNumber = scardInfos.bChipSerial2 -- bChipSerial2 is unique, bChipSerial may be duplicate
        end
        self.info.serialNumber = ds_info.token_info.serialNumber or self.info.serialNumber
        self.info.manufacturerID = ds_info.token_info.manufacturerID or self.info.manufacturerID
        
        self.info.hardwareVersion.major = scardInfos.hwVersionMajor
        self.info.hardwareVersion.minor = scardInfos.hwVersionMinor
        self.info.firmwareVersion.major = scardInfos.fwVersionMajor
        self.info.firmwareVersion.minor = scardInfos.fwVersionMinor
        
        
        self.info.ulTotalPrivateMemory = scardInfos.ulTotalSpace
        self.info.ulTotalPublicMemory = scardInfos.ulTotalSpace
        self.info.ulFreePublicMemory = scardInfos.ulFreeSpace
        self.info.ulFreePrivateMemory = scardInfos.ulFreeSpace
        self.ds_info = ds_info

        self.info.model = ds_info.token_info.model or self.info.model
        log.output('token-cryptoid:add_info_ds(): DONE!' )
        if ds_info.token_info.mk_status > 0 then
            
            local mKey = sm.sm_ask_keys(10)  -- richiede la chiave #10, master key per cifratura chiavi	
            local eMc = hex.hexf("B0B6946BBDB748479E0BF" .. "0E54CB166A0E863A9BB19F7BC6D98F0F8013B1BCFE9258D8391249AC452") -- "d8ec0d4355e7ebb2bd683178fbaa014038902dc909547ef68f5500a53a34bd4f"
            local eEa = hex.hexf("4433F94DA98F9CFDB820CFF095".."6536D9FA859F0D641048B5A8EC288FDB3A403C347DA0573921571F") -- "0295db162240434ce27202628615d7f8ccab2ead0751554f62be5f606ece323b"
            
            self.cryptoid_hcard.KEY_MC = sm.des3_dec(mKey, eMc)
            self.cryptoid_hcard.KEY_EA = sm.des3_dec(mKey, eEa)
            
            eMc = nil
            eEa = nil
            mKey = nil
            collectgarbage() -- forza liberazione della memoria inutilizzata
        end
        break
    until false
end



function t.mt:_update_retry_counters()

    if self._schedule_update_retry_counters then
        log.output("get_pin_puk_status...");
        
        self._schedule_update_retry_counters = false
        local bMaxTries = 10 -- guess
        if (self.info) then
            pcall (function()
                self.cryptoid_hcard:select_df_path(self.ds_info.ds_path)
                local infosPin = self.cryptoid_hcard:get_authentication_info(self.cryptoid_hcard.ID_PIN)
                local infosPuk = self.cryptoid_hcard:get_authentication_info(self.cryptoid_hcard.ID_PUK)
                
                self.info.flags = self.info.flags - CKF.USER_PIN_LOCKED
                self.info.flags = self.info.flags - CKF.USER_PIN_FINAL_TRY
                self.info.flags = self.info.flags - CKF.USER_PIN_COUNT_LOW
                self.info.flags = self.info.flags - CKF.SO_PIN_LOCKED
                self.info.flags = self.info.flags - CKF.SO_PIN_FINAL_TRY
                self.info.flags = self.info.flags - CKF.SO_PIN_COUNT_LOW
                log.output("get_pin_puk_status, pin / puk try left=", infosPin.bLeftTryTimes, infosPuk.bLeftTryTimes)
                if infosPin.bLeftTryTimes == 0 then
                    self.info.flags = self.info.flags + CKF.USER_PIN_LOCKED
                elseif infosPin.bLeftTryTimes == 1 then
                    self.info.flags = self.info.flags + CKF.USER_PIN_FINAL_TRY
                elseif infosPin.bLeftTryTimes < self.ds_info.token_info.max_pin_tries then
                    self.info.flags = self.info.flags + CKF.USER_PIN_COUNT_LOW
                end
                
                if  infosPuk.bLeftTryTimes == 0 then
                    self.info.flags = self.info.flags + CKF.SO_PIN_LOCKED
                elseif  infosPuk.bLeftTryTimes == 1 then
                    self.info.flags = self.info.flags + CKF.SO_PIN_FINAL_TRY 
                elseif  infosPuk.bLeftTryTimes <  self.ds_info.token_info.max_puk_tries then
                    self.info.flags = self.info.flags + CKF.SO_PIN_COUNT_LOW
                end
                
                self.info.pinRetry    = infosPin.bLeftTryTimes
                self.info.pinRetryMax = self.ds_info.token_info.max_pin_tries
                self.info.pukRetry    = infosPuk.bLeftTryTimes
                self.info.pukRetryMax = self.ds_info.token_info.max_puk_tries
            
            end)
            log.output("get_pin_puk_status: flags", self.info.flags);
        end
    end
end

function t.mt:get_info()
    if not self.info then
        self.info = {
            label = 'Bit4id tokenME',
            manufacturerID = 'Bit4id',
            model = 'TMVK3',
            serialNumber = '0000000000000000',
            flags = CKF.RNG + CKF.LOGIN_REQUIRED +
                    CKF.USER_PIN_INITIALIZED + CKF.TOKEN_INITIALIZED,
            ulMaxSessionCount = CK.EFFECTIVELY_INFINITE,
            ulSessionCount = 0,
            ulMaxRwSessionCount = CK.EFFECTIVELY_INFINITE,
            ulRwSessionCount = CK.UNAVAILABLE_INFORMATION,
            ulMaxPinLen = 16,
            ulMinPinLen = 4,
            ulTotalPublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulFreePublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulTotalPrivateMemory = CK.UNAVAILABLE_INFORMATION,
            ulFreePrivateMemory = CK.UNAVAILABLE_INFORMATION,
            hardwareVersion = { major=1, minor=3},
            firmwareVersion = { major=1, minor=3},
            utcTime = '0000000000000000'
        }
        if self.cfg["ndefaultlabel"] then
            self.info.label = string.sub(self.cfg["ndefaultlabel"], 1, 32)
        end
        if self.cfg["ndefaultvendor"] then
            self.info.manufacturerID = string.sub(self.cfg["ndefaultvendor"], 1, 32)
        end
        if self.cfg["ndefaultmodel"] then
            self.info.model = string.sub(self.cfg["ndefaultmodel"], 1, 16)
        end
        self:add_info_ds()
        
        local pcRes, theErrorT = pcall( function()
            local sha2 = md.sha256()
            sha2:update("a" .. "c" .. "g" .. "7" .. "8" .. "8" .. "1" .. "0" .. "0" .. "5" .. "5" .. "5" .. "5" .. "%" .. "!" .. "-"
            .. self.ds_info.scardInfos.bChipSerial)
            self.ds_info.aes_check = "\0\0\0\0\0\0\0\1"
            self.ds_info.aes_key = sha2:final()
            log.output("self.ds_info.aes_key:", hex.hexify(self.ds_info.aes_key))
            log.output("self.ds_info.aes_check:", hex.hexify(self.ds_info.aes_check))
        end)
        if not pcRes then
            log.output("error:", theErrorT)
        end
        self._schedule_update_retry_counters=true
    end
    
    self:_update_retry_counters()

    return self.info
end

function t.mt:get_mechanisms()
    return t.mechanisms
end

function t.mt:verify_pin(pin, userType)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk = false
    local result
    if userType == CKU.SO then 
        ispuk = true
    end
    log.output("verify_pin()", pin, userType, ispuk)
    self.cryptoid_hcard:select_df_path(self.ds_info.ds_path)
    
    self._schedule_update_retry_counters = true
    if ispuk then
        result = self.cryptoid_hcard:verify_puk(pin)
    else
        result = self.cryptoid_hcard:verify_pin(pin)
    end
    log.output("verify: result=", result)
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

function t.mt:verify_loggedon_user()
    local pcRes, theErrorT
    local res = -1
    if self.userType == CKU.USER and self.cached_main_pin then
        pcRes, theErrorT =pcall(function()
            self.cryptoid_hcard:select_df_path(self.ds_info.ds_path)
            res = self.cryptoid_hcard:verify_pin(self.cached_main_pin)
        end)
    elseif self.userType == CKU.SO and self.cached_main_pin then
        pcRes, theErrorT =pcall(function()
            self.cryptoid_hcard:select_df_path(self.ds_info.ds_path)
            res = self.cryptoid_hcard:verify_puk(self.cached_main_pin)
        end)
    end
    if not pcRes then
        log.output('verify_loggedon_user(): error:', theErrorT)
    end
    if res ~= 0 then
        self:unverify_pin()
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
    log.output('token-cryptoid change_pin(): oldPin:' .. oldPin, 'newPin:' .. newPin)
    
    self._schedule_update_retry_counters = true
    
    if not newPin or string.len(newPin) > info.ulMaxPinLen or string.len(newPin) < info.ulMinPinLen then
        return CKR.PIN_LEN_RANGE
    end

    
    self.cryptoid_hcard:select_df_path(self.ds_info.ds_path)
    
    pcRes, result = pcall(function() 
        if ispuk then
            return self.cryptoid_hcard:change_puk(oldPin, newPin) 
        else
            return self.cryptoid_hcard:change_pin(oldPin, newPin) 
        end
        
    end)
    
    if not pcRes then
        log.output('token-cryptoid change_pin(): error', result)
        return CKR.FUNCTION_FAILED
    end
    
    if result == 0 then
        self.cached_main_pin = newPin
        self:verify_loggedon_user()
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
    local pcRes, theErrorT, result
    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-cryptoid reset_pin(): newPin:' .. newPin)
    log.output('token-cryptoid reset_pin(): reset pin...')
    if self.userType ~= CKU.SO then
        log.output('token-cryptoid reset_pin(): user not SO!')
        return CKR.FUNCTION_FAILED
    end
    
    self._schedule_update_retry_counters = true
    
    if not newPin or string.len(newPin) > info.ulMaxPinLen or string.len(newPin) < info.ulMinPinLen then
        return CKR.PIN_LEN_RANGE
    end

    pcRes, theErrorT = pcall(function() result = self.cryptoid_hcard:reset_pin(self.cached_main_pin, newPin) end)
    if not pcRes then
        log.output("reset_pin(): error", theErrorT)
        return CKR.FUNCTION_FAILED
    end
    
    if result == 0 then
        self:verify_loggedon_user()
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
-- Funzioni per il recupero degli attributi
--=====================================================================================


function t.mt:get_privkey_ds(hobj, att_type, onlysize)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local id = nil
    local obj = self.attributes[hobj]
    local fid, attr_path
    local obj_attributes
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('get_privkey_ds(): ERROR! not a private key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    fid = bin.flags('0x0100') + bin.flags(obj.num) + util.objFIDS.ePrivKey
    log.output('get_privkey_ds(): calculated fid:', fid )
    attr_path = obj.ds_parent_path .. hexf('%H', fid.asnumber)
    local pcRes, theErrorT
    
    self:verify_loggedon_user()
    
    pcRes, theErrorT = pcall(function()
                log.output('get_privkey_ds(): reading attributes for privkey :', hex.hexify(attr_path) )
                obj_attributes = util.parse_ds_privkey_attribute(
                    self.cryptoid_hcard, attr_path, obj.key_bits / 8
                    )
                    
                local finfos = self.cryptoid_hcard:select_ef(hex.hexf(obj.ds_id))
                
                if obj.imported then
                    obj.eExponent = self.cryptoid_hcard:mread_binary(0, finfos.size)
                end
            end
            )

    if pcRes then
        obj[CKA.LABEL] = obj_attributes.label
        obj[CKA.ID] = obj_attributes.id
        obj[CKA.MODULUS] = obj_attributes.modulus
        obj[CKA.PUBLIC_EXPONENT] = obj_attributes.pubexp
        obj[CKA.MODULUS_BITS] = eCK.ULONG(obj.key_bits)
        obj[CKA.START_DATE] = obj_attributes.startdate
        obj[CKA.END_DATE] = obj_attributes.enddate
        obj[CKA.SUBJECT] = obj_attributes.subject
        
        util.decode_bool_attributes(
            obj_attributes.flags, 
            {CKA.MODIFIABLE, CKA.LOCAL, CKA.DECRYPT, CKA.SIGN, CKA.SIGN_RECOVER,CKA.UNWRAP,CKA.ALWAYS_AUTHENTICATE},
            obj
        )
        if not obj[CKA.PUBLIC_EXPONENT] or string.len(obj[CKA.PUBLIC_EXPONENT]) == 0 then
            obj[CKA.PUBLIC_EXPONENT] = hex.hexf('010001') -- default exponent
        end
        obj.populated = true
        return CKR.OK, obj[att_type]
    else
        log.output('get_privkey_ds(): error reading attribute:', theErrorT )
        return CKR.ATTRIBUTE_TYPE_INVALID
    end
end

function t.mt:get_pubkey_ds(hobj, att_type, onlysize)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local sm_enc, sm_sig
    local id = nil
    local obj = self.attributes[hobj]
    local attr_fid, attr_path
    local obj_attributes
    local modulus, exponent
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PUBLIC_KEY) then
        log.output('get_pubkey_ds(): ERROR! not a public key object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    
    self:verify_loggedon_user()
    
    attr_fid = bin.flags('0x0100') + bin.flags(obj.num) + util.objFIDS.ePubKey
    attr_path = obj.ds_parent_path .. hexf('%H', attr_fid.asnumber)
    log.output('get_pubkey_ds(): calculated fids:', 'attr_path:', hex.hexify(attr_path), 'num:', obj.num )
    local pcRes, theErrorT = pcall(function() 
                log.output('get_pubkey_ds(): reading attributes for pubkey :', hex.hexify(attr_path) )
                obj_attributes = util.parse_ds_pubkey_attribute(
                    self.cryptoid_hcard, attr_path
                    )
            end
            )
    if pcRes then
        obj[CKA.LABEL] = obj_attributes.label
        obj[CKA.ID] = obj_attributes.id
        obj[CKA.MODULUS] = obj_attributes.modulus
        obj[CKA.PUBLIC_EXPONENT] = obj_attributes.pubexp
        obj[CKA.MODULUS_BITS] = (obj_attributes.modulus and eCK.ULONG(string.len(obj_attributes.modulus) * 8)) or obj[CKA.MODULUS_BITS]
        obj[CKA.START_DATE] = obj_attributes.startdate
        obj[CKA.END_DATE] = obj_attributes.enddate
        obj[CKA.SUBJECT] = obj_attributes.subject
        
        util.decode_bool_attributes(
            obj_attributes.flags, 
            {CKA.MODIFIABLE, CKA.TRUSTED, CKA.LOCAL, CKA.ENCRYPT, CKA.VERIFY,CKA.VERIFY_RECOVER,CKA.WRAP},
            obj
        )
        obj.populated = true
        if type(obj[att_type]) == 'function' then
            return CKR.FUNCTION_FAILED
        end
        
        return CKR.OK, obj[att_type]
    else
        log.output('get_pubkey_ds(): error reading attribute:', theErrorT )
        return CKR.ATTRIBUTE_TYPE_INVALID
    end
end

function t.mt:get_certificate_ds(hobj, att_type, onlysize)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end

    local parsed_cer
    local cert_value
    local id = nil
    local obj = self.attributes[hobj]
    local attr_fid, attr_path, val_fid, val_path
    local obj_attributes
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.CERTIFICATE) then
        log.output('get_certificate_ds(): ERROR! not a certificate object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    self:verify_loggedon_user()
    
    attr_fid = bin.flags('0x0100') + bin.flags(obj.num) + util.objFIDS.eCert
    attr_path = obj.ds_parent_path .. hexf('%H', attr_fid.asnumber)
    val_path = obj.path
    log.output('get_certificate_ds(): calculated fids:', 'attr_path:', hex.hexify(attr_path), 'val_path:', hex.hexify(val_path) )
    local pcRes, theErrorT = pcall(function() 
                log.output('get_certificate_ds(): reading value for cert:', hex.hexify(val_path) )
                cert_value = self.cryptoid_hcard:read_x509_certificate(val_path)
                log.output('get_certificate_ds(): reading attributes for cert:', hex.hexify(attr_path) )
                obj_attributes = util.parse_ds_cert_attribute(
                    self.cryptoid_hcard, attr_path
                    )
            end
            )
    if pcRes then
        pcall(function() parsed_cer = der.parse_x509cer(cert_value) end )
        obj[CKA.LABEL] = obj_attributes.label
        obj[CKA.ID] = obj_attributes.id
        obj[CKA.VALUE] = cert_value
        obj[CKA.SUBJECT] = obj_attributes.subject or (parsed_cer and parsed_cer.subject)
        obj[CKA.ISSUER] = obj_attributes.issuer or (parsed_cer and parsed_cer.issuer)
        obj[CKA.SERIAL_NUMBER] = obj_attributes.serialnumber or (parsed_cer and parsed_cer.serialNumber)
        
        util.decode_bool_attributes(
            obj_attributes.flags, 
            {CKA.MODIFIABLE, CKA.TRUSTED},
            obj
        )
        obj.populated = true
        return CKR.OK, obj[att_type]
    else
        log.output('get_certificate_ds(): error reading attribute:', theErrorT )
        return CKR.ATTRIBUTE_TYPE_INVALID
    end
end

function t.mt:get_data_ds(hobj, att_type, onlysize)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local id = nil
    local obj = self.attributes[hobj]
    local attr_fid, attr_path, val_fid, val_path
    local obj_attributes
    local value = ''
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.DATA) then
        log.output('get_data_ds(): ERROR! not a DATA object!')
        return CKR.ATTRIBUTE_TYPE_INVALID -- non dovrebbe accadare
    end
    if obj.private then
        attr_fid = bin.flags('0x0100') + bin.flags(obj.num) + util.objFIDS.eDataP
    else
        attr_fid = bin.flags('0x0100') + bin.flags(obj.num) + util.objFIDS.eData
    end
    attr_path = obj.ds_parent_path .. hexf('%H', attr_fid.asnumber)
    val_path = obj.path
    log.output('get_data_ds(): calculated fids:', 'attr_path:', hex.hexify(attr_path), 'val_path:', hex.hexify(val_path) )
    local pcRes, theErrorT
    
    self:verify_loggedon_user()
    
    if obj.size > 0 then
        pcRes, theErrorT = pcall(function() 
                log.output('get_data_ds(): reading value for data obj:', hex.hexify(val_path) )
                self.cryptoid_hcard:select(val_path)
                value = self.cryptoid_hcard:mread_binary(0, obj.size)

                log.output('get_data_ds(): reading attributes for data obj :', hex.hexify(attr_path) )
                obj_attributes = util.parse_ds_data_attribute(self.cryptoid_hcard, attr_path)
            end)
    else
        pcRes = true
    end
    if pcRes then
        obj[CKA.PRIVATE] = eCK.BBOOL(obj.private)
        obj[CKA.MODIFIABLE] = eCK.BBOOL((bin.flags('0x0001') * obj_attributes.flags).asbool)
        obj[CKA.LABEL] = obj_attributes.label
        obj[CKA.APPLICATION] = obj_attributes.appId
        obj[CKA.OBJECT_ID] = obj_attributes.objId
        obj[CKA.VALUE] = value
        obj.populated = true
        return CKR.OK, obj[att_type]
    else
        log.output('get_pubkey_ds(): error reading attribute:', theErrorT )
        return CKR.ATTRIBUTE_TYPE_INVALID
    end 
end

--=====================================================================================

function t.mt:sign_buffer(hKey, pMechanism, pData, allocated_space)
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
        -- nota: il padding pkcs1 richiede almeno 8 byte di 0xFF prima dei dati da firmare
        log.output('sign_buffer(): specified data len invalid: ', dataLen)
        return CKR.DATA_LEN_RANGE
    end
    if allocated_space==nil then
        return CKR.OK, keyBytes
    else
    
        self:verify_loggedon_user() -- verify normal user
        
        
        
        local pDataPadded
        if string.len(pData) == keyBytes then -- firma raw
            pDataPadded = pData
        else
            pDataPadded = '\0\1'..string.rep('\255',(keyBytes-3)-string.len(pData))
                            ..'\0'..pData
        end
        if obj.imported then
            log.output('sign_buffer(): using RSA ENC mode', obj.ds_id)
            -- forza polulate dell'oggetto:
            self:get_attribute_value(hKey, CKA.ID)
            if not obj.eExponent then
                log.output('sign_buffer(): FUNCTION_FAILED: eExponent not found!')
                return CKR.FUNCTION_FAILED
            end
            local pExp = aes.aes_decrypt_check(
                                        self.ds_info.aes_key,
                                        obj.eExponent,
                                        self.ds_info.aes_check
                                        )
            if not pExp then
                log.output('sign_buffer(): FUNCTION_FAILED: eExponent invalid')
                return CKR.FUNCTION_FAILED
            end
            
            result = rsa.encrypt(pData, hex.hexify(obj[CKA.MODULUS]), nil, hex.hexify(pExp))
            
            pExp=nil
            collectgarbage() -- forza liberazione della memoria inutilizzata
            return CKR.OK, result
        else
            log.output('sign_buffer(): using RSA-Decrypt mode on ', obj.ds_id)
            local pcRes, result = pcall(function()
                return self.cryptoid_hcard:rsa_dec(pDataPadded, obj.ds_id)
            end)
            if pcRes then
                return CKR.OK, result
            end
        end
    end
    log.output('sign_buffer(): function failed!')
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
    --if not obj.pso_dec then
    --    log.output('decrypt_buffer(): ERROR: decrypt not supported!')
    --    return CKR.KEY_TYPE_INCONSISTENT -- todo: errore non adatto
    --end

    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    if dataLen ~= keyBytes then
        log.output('decrypt_buffer(): specified data len invalid: ', dataLen, ', expected:', keyBytes)
        return CKR.ENCRYPTED_DATA_LEN_RANGE
    end
    
    self:verify_loggedon_user()
    
    local pDataPadded
 
    if obj.imported then
        log.output('decrypt_buffer(): using RSA ENC mode', obj.ds_id)
        -- forza polulate dell'oggetto:
        self:get_attribute_value(hKey, CKA.ID)
        if not obj.eExponent then
            log.output('decrypt_buffer(): FUNCTION_FAILED: eExponent not found!')
            return CKR.FUNCTION_FAILED
        end
        local pExp = aes.aes_decrypt_check(
                                    self.ds_info.aes_key,
                                    obj.eExponent,
                                    self.ds_info.aes_check
                                    )
        if not pExp then
            log.output('decrypt_buffer(): FUNCTION_FAILED: eExponent invalid')
            return CKR.FUNCTION_FAILED
        end
        
        pDataPadded = rsa.encrypt(pData, hex.hexify(obj[CKA.MODULUS]), nil, hex.hexify(pExp))
        
        pExp=nil
        collectgarbage() -- forza liberazione della memoria inutilizzata
    else
        log.output('decrypt_buffer(): using RSA-Decrypt mode on ', obj.ds_id)
        pDataPadded = self.cryptoid_hcard:rsa_dec(pData, obj.ds_id)
        if pDataPadded == nil or string.len(pDataPadded) ~= keyBytes then
            log.output('decrypt_buffer(): cannot decrypt specified data')
            return CKR.ENCRYPTED_DATA_INVALID
        end
    end
    if not pMechanism or not pMechanism.mechanism or pMechanism.mechanism == CKM.RSA_PKCS then
        if string.byte(pDataPadded, 1) ~= 0 or string.byte(pDataPadded, 2) ~= 2 then
            
            log.output('decrypt_buffer(): data decrypted, pkcs1 padding invalid, byte1:',
                        string.byte(pDataPadded, 1),
                        'byte2:', string.byte(pDataPadded, 2))
            return CKR.ENCRYPTED_DATA_INVALID
        end
        local idx = string.find(pDataPadded, '\0', 4, true)
        if idx == nil then
            log.output('decrypt_buffer(): data decrypted, pkcs1 padding invalid, cannot find payload')
            return CKR.ENCRYPTED_DATA_INVALID
        end
        local result = string.sub(pDataPadded, idx+1, -1)
        return CKR.OK, result
    else
        return CKR.OK, pDataPadded
    end
    
end


-- se search_state.lastobj==nil si richiede l'handle del primo oggetto che risponda
-- al template. Altrimenti restituisce il primo oggetto che sia
-- compatibile con il template e abbia handle>search_state.lastobj.
-- quando non ci sono pi