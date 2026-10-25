 avvenuta usando un numero minimo di APDU
    -- 2) mantenere lo stato della mutua autenticazione come valido nell'ambito della medesima transazione
    -- 3) eseguire la mutua autenticazione solo se necessario
    local pcRes
    if not self._performed_mutual_auth then
        if self.KskEnc and self.KskSig then
            log.output("auto_perform_mutual_authenticate(): checking PIN status")
            self._performed_mutual_auth = true -- forza l'uso delle chiavi SM correnti
            pcRes = pcall(function()
                self:verify_pin_main("", false, true, true)
            end)
            self._performed_mutual_auth = false
            log.output("auto_perform_mutual_authenticate(): pin status check result:",
                    hex.hexify(self.last_sw or ''))
            
            if pcRes and (self.last_sw == hex.hexf("9000") -- PIN verificato
                            or self.last_sw == hex.hexf("6984") -- PIN bloccato
                            or string.sub(self.last_sw, 1, 1) == hex.hexf("63") -- PIN non verificato
                            ) then
                self._performed_mutual_auth = true
                log.output("auto_perform_mutual_authenticate(): already performed!")
                return false
            end
        end
        log.output("auto_perform_mutual_authenticate(): not performed, starting...")
        return self:perform_mutual_authenticate()
    else
        log.output("auto_perform_mutual_authenticate(): not needed: inside same transaction!")
        return false
    end
end

function EIDASmartcard.mt:perform_mutual_authenticate()
    
    log.output("perform_mutual_authenticate()")
    self._performed_mutual_auth = false
    
    -- key 3DES di tipo A-B-A
    log.output("Actual 3DES key (A-B-A mode):", hex.hexify(self.default_master_key1), hex.hexify(self.default_master_key2), hex.hexify(self.default_master_key1))
    
    local master_key = self.default_master_key1 .. self.default_master_key2 .. self.default_master_key1
    assert (string.len(master_key) == 24)
    
    self:select_p15()
    
    self.TRnd = "12345678"
    self.IFD_SN = "00000001" -- terminal Serial Number (8)
    self.Kifd = "12345678123456781234567812345678"  -- Key IFD from terminal (32)
    
    if self.CardVersion == 2 then
        self:TX(hexf("002241A4"), hexf("8301%B950180", self.default_master_key_number))
        CSN = ICC_SN
    end

    local challenge = self:TX(hexf("8084000008"))
    challenge = string.sub(challenge, 1, 8)
    assert (string.len(challenge) == 8)
    self.CRnd = challenge  -- random from card (8)
    log.output("CRnd:", hex.hexify(self.CRnd))
    
    self.KENC, self.KMAC, self.S1, self.MAC = calc_mutial_authenticate(
        string.sub(master_key, 1, 16), 
        self.CSN,
        self.CRnd, 
        self.ICC_SN, 
        self.TRnd, 
        self.IFD_SN, 
        self.Kifd)
    
    master_key = nil
    collectgarbage() -- forza liberazione della memoria inutilizzata
    
    log.output("KENC:", hex.hexify(self.KENC))
    log.output("KMAC:", hex.hexify(self.KMAC))

    self.SMAC = self.S1 .. self.MAC
    
    local ma_res = self:TX(hexf("80820000"), self.SMAC)
    assert(string.sub(ma_res, -2, -1) == hexf("9000"))
    
    local ma_enc = string.sub(ma_res, 1, 64)
    local ma_mac = string.sub(ma_res, 65, 72)
    log.output("ma_enc:", hex.hexify(ma_enc))
    log.output("ma_mac:", hex.hexify(ma_mac))
    local ma1_mac = Retail_MAC(self.KMAC, ma_enc)
    local ma1 = sm.des3_dec(self.KENC, ma_enc, true)
    log.output("ma1_mac:", hex.hexify(ma1_mac))
    log.output("ma1:", hex.hexify(ma1))

    assert(ma_mac == ma1_mac)
    assert(string.sub(ma1, 1, 8) == self.CRnd)
    assert(string.sub(ma1, 9, 16) == self.ICC_SN)
    assert(string.sub(ma1, 17, 24) == self.TRnd)
    assert(string.sub(ma1, 25, 32) == self.IFD_SN)

    self.ssc = string.sub(self.CRnd, 5, 8) .. string.sub(self.TRnd, 5, 8)
    self.Kicc = string.sub(ma1, 33, 64)

    self.Kifdicc = ''
    for i=1,string.len(self.Kicc) do
        local Bicc = bin.flags(string.byte(self.Kicc, i))
        local Bifd = bin.flags(string.byte(self.Kifd, i))
        self.Kifdicc = self.Kifdicc .. string.char((Bicc ^ Bifd).asnumber)
    end
    log.output("Kifdicc:", hex.hexify(self.Kifdicc))
    local sha1 = md.sha1()
    sha1:reset()
    sha1:update(self.Kifdicc .. "\000\000\000\001")
    local KskEnc = sha1:final()
    sha1:reset()
    sha1:update(self.Kifdicc .. "\000\000\000\002")
    local KskSig = sha1:final()
    
    log.output("KskEnc:", hex.hexify(KskEnc))
    log.output("KskSig:", hex.hexify(KskSig))

    self.KskEnc = string.sub(KskEnc, 1, 8) .. string.sub(KskEnc, 9, 16) .. string.sub(KskEnc, 1, 8)
    self.KskSig = string.sub(KskSig, 1, 8) .. string.sub(KskSig, 9, 16) .. string.sub(KskSig, 1, 8)
    log.output("final KskEnc:", hex.hexify(self.KskEnc))
    log.output("final KskSig:", hex.hexify(self.KskSig))
    self._performed_mutual_auth = true
    
    log.output("perform_mutual_authenticate(): completed")
    return true
end

local function parse_tlv_ber(data)
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

-------------------------------------------------------

function EIDASmartcard.parse_fci(fci)
    local fci1 = parse_tlv_ber(fci)
    local fci2 = parse_tlv_ber(fci1[98] or fci1[111]) -- 0x62 or 0x6F
    local infos = {size=(fci2[128] or fci2[129]) and bin.unpack("%H", fci2[128] or fci2[129]),
                      filetype = fci2[130] and string.byte(fci2[130], 1),
                      options=fci2[130],
                      fid_n=fci2[131] and bin.unpack("%H", fci2[131]),
                      fid =fci2[131],
                      sc = fci2[140],
                      }
    return infos
end

function EIDASmartcard.mt:transmit(apdu)
    local header, data = string.sub(apdu, 1, 4), string.sub(apdu, 6)
    if string.len(apdu) <= 5 then -- APDU con il solo LE
        header, data = apdu, nil
    end
    local result = self:TX(header, data)
    self.last_sw = string.sub(result, -2, -1)
    return result
end


function EIDASmartcard.mt:sm_transmit(apdu, use_sm)
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

function EIDASmartcard.mt:select(path, relative, use_sm)
    local sw, recv, path1, relative_id
    if relative then relative_id = 0 else relative_id = 8 end
    local template_h, template_p = '00A4%B0002%H', '00A4%B00%P'
    log.output('select(): ', path and hexify(path))
    path1 = path
    if path1 == nil then
        path1 = hexf('3f00')
    end
    if type(path)=='number' then
        recv = self:sm_transmit(hexf(template_h, relative_id, path1), use_sm)
        sw = string.sub(recv, -2, -1)
    else
        if path1 == hexf('3f00') then
            recv = self:sm_transmit(hexf('00A40000023f00'), use_sm)
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
        error(EIDASmartcard.EIDASmartcardError.new(sw, 'select Error'), 2)
    elseif string.len(recv) > 2 then
        return EIDASmartcard.parse_fci(recv)
    end
end

function EIDASmartcard.mt:get_random(ammount)
    assert (ammount == 8)
    local recv = self:transmit(hexf('80840000%B', ammount))
    local sw = string.sub(recv, -2, -1)
    if sw == hexf('9000') then
        self._last_random_from_card = string.sub(recv, 1, -3)
    else
       error(EIDASmartcard.EIDASmartcardError.new(sw, 'get_random Error'), 2)
    end
    
    return self._last_random_from_card
end

function EIDASmartcard.mt:read_binary(offset, size, use_sm)
    local recv
    log.output("reading from:", offset, "size:", size)
    local apdu = hexf('00B0%H%B', offset, size)
    recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') and sw ~= hexf('6282') then
        error(EIDASmartcard.EIDASmartcardError.new(sw, 'read_binary Error'), 2)
    end
    return string.sub(recv, 1, -3)
end

function EIDASmartcard.mt:mread_binary(offset, size, use_sm)
    local buffer_size = EIDASmartcard.MAX_TRANSMIT_BUFFER_SIZE
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


function EIDASmartcard.mt:verify(bso, pin, backtracking)
    return self:sm_verify(bso, pin, backtracking)
end

function EIDASmartcard.mt:sm_verify(bso, pin, backtracking, use_sm)
    if string.len(pin) == 0 then
        log.output('sm_verify(): checking pin status...')
    end
    if backtracking then
        bso = (bin.flags(bso) + bin.flags(128)).asnumber
    end
    local sw = self:sm_transmit(hexf('002000%B%P', bso, pin), use_sm)
    if sw == hexf('6983') or sw == hexf('6984') then
        return 2, 'Authentication blocked'
    elseif string.sub(hexify(sw), 1, 2) == '63' then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        return 0, 'Authentication succeeded'
    else
        log.output('sm_verify(): Error ' .. hexify(sw) )
        error(EIDASmartcard.EIDASmartcardError.new(sw, 'sm_verify Error' ), 2)
    end
end


function EIDASmartcard.mt:sm_change(bso, oldPin, newPin, backtracking, use_sm)
    if backtracking then
        bso = (bin.flags(bso) + bin.flags(128)).asnumber
    end
	local mode = 0
	if not oldPin then
		mode = 1
		oldPin = ''
	end
    local sw = self:sm_transmit(hexf('0024%B%B%P', mode, bso, oldPin..newPin), use_sm)
    if sw == hexf('6983')  or sw == hexf('6984') then
        return 2, 'Authentication blocked'
    elseif bin.mask_compare(sw, hexf('6300'), hexf('FF00')) then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        return 0, 'Authentication succeeded'
    else
        log.output('sm_change(): Error ' .. hexify(sw) )
        error(EIDASmartcard.EIDASmartcardError.new(sw, 'sm_change Error' ), 2)
    end
end


function EIDASmartcard.mt:begin_transaction()
    self.card:begintransaction()
end

function EIDASmartcard.mt:end_transaction()
    self._performed_mutual_auth = false
    self.card:endtransaction()
end

function EIDASmartcard.mt:on_end_transaction()
    log.output('EIDASmartcard:on_end_transaction()...')
    self._performed_mutual_auth = false
end


function EIDASmartcard.mt:sm_reset_retry_counter(bso, Puk, newPin, backtracking, use_sm)
    if backtracking then
        bso = (bin.flags(bso) + bin.flags(128)).asnumber
    end
    local mode = 0
    if not newPin then
        mode = 1
    end
    local sw = self:sm_transmit(hexf('002C%B%B%P', mode, bso, (Puk or '') .. (newPin or '')), use_sm)
    if sw == hexf('6983')  or sw == hexf('6984') then
        return 2, 'Authentication blocked'
    elseif bin.mask_compare(sw, hexf('6300'), hexf('FF00')) then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        return 0, 'Authentication succeeded'
    else
        log.output('sm_reset_retry_counter(): Error ' .. hexify(sw) )
        error(EIDASmartcard.EIDASmartcardError.new(sw, 'sm_reset_retry_counter Error' ), 2)
    end
end

function EIDASmartcard.mt:valid()
    local status, err = self.card:status()
    if not status then
        log.output('EIDASmartcard:valid(): status() error', hex.tohex8(err or 0))
        return false
    elseif status.protocol == 0 or string.len(status.atr or '') == 0 then
        log.output('EIDASmartcard:valid(): card removed?')
        return false
    end
    return true
end

---------------------------------------------------
function EIDASmartcard.handle_error(err_obj)
    print(debug.traceback(err_obj))
    return err_obj
end


local function make_bcd_like(padding, padchar, value)
    value = value .. string.rep(padchar, padding - string.len(value))
    value = hex.hexf(value) -- conversione in "BCD"
    return value
end

-- pin binary string;
function EIDASmartcard.mt:verify_pin_main(pin, ispuk, check, use_sm)
    log.output('verify_pin_main():', pin, ispuk, check)
    local bso = self.BSO_PIN
    local padding = self.PIN_PADDING
    if ispuk then
        bso = self.BSO_PUK
        padding = self.PUK_PADDING
    end
    if string.len(pin)> padding then
        pin = string.sub(pin, 1, padding)
    end
    local backtracking = false
    if self.CardVersion == 2 then
        backtracking = true
    end    
    if check then
        if 0 == self:sm_verify(bso, "", backtracking, use_sm) then
            return 0
        else
            return -1
        end
    end
    pin = make_bcd_like(padding, self.PADDING_CHAR, pin)

    return self:sm_verify(bso, pin, backtracking, use_sm)
    
end

function EIDASmartcard.mt:change_pin_main(oldPin, newPin, ispuk, use_sm)
    local bso = self.BSO_PIN
    local padding = self.PIN_PADDING
    if ispuk then
        bso = self.BSO_PUK
        padding = self.PUK_PADDING
    end
    if string.len(oldPin or '') > padding then
        oldPin = string.sub(oldPin, 1, padding)
    end
    if string.len(newPin) > padding then
        error('EIDASmartcard change_pin_main Error: wrong PIN size', 2)
    end
    if oldPin then
        oldPin = make_bcd_like(padding, self.PADDING_CHAR, oldPin)
    end
    newPin = make_bcd_like(padding, self.PADDING_CHAR, newPin)
    local backtracking = false
    if self.CardVersion == 2 then
        backtracking = true
    end
    return self:sm_change(bso, oldPin, newPin, backtracking, use_sm)
end


function EIDASmartcard.mt:reset_pin_main(Puk, newPin, use_sm)
    if string.len(Puk or '' ) > self.PUK_PADDING then
        Puk = string.sub(Puk, 1, self.PUK_PADDING)
    end
    if string.len(newPin) > self.PIN_PADDING then
        error('EIDASmartcard reset_pin_main Error: wrong PIN size', 2)
    end
    local backtracking = false
    if self.CardVersion == 2 then
        backtracking = true
    end
    
    Puk = make_bcd_like(self.PUK_PADDING, self.PADDING_CHAR, Puk)
    newPin = make_bcd_like(self.PIN_PADDING, self.PADDING_CHAR, newPin)
    local res
    
    res = self:verify_pin_main(Puk, true, false, use_sm)
    if res ~= 0 then return res end
    return self:sm_reset_retry_counter(self.BSO_PIN, Puk, newPin, backtracking, use_sm)
end


function EIDASmartcard.mt:pso_cds(data, id, pin, use_sm)
    local sw, resp
    if id == nil then id = '3'
    elseif type(id) == 'number' then 
        id = hex.hexify(hex.hexf('%B', id))
    elseif string.len(id) == 1 then 
        id = hex.hexify(id)
    end
    repeat 
        local seRestore = hex.hexf("0022730100")
        resp = self:sm_transmit(seRestore, use_sm)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end
        local algo = 2 -- NO HASH DSI OID
        local SHA256_DIGEST_OID = hex.hexf("3031300d060960864801650304020105000420")
        if SHA256_DIGEST_OID == string.sub(data, 1, string.len(SHA256_DIGEST_OID)) then
            algo = 66 -- 0x42: SHA256
            data = string.sub(data, string.len(SHA256_DIGEST_OID)+1, -1)
        end
        local seSet = hex.hexf("002241b6068001%B8401" .. id, algo)
        resp = self:sm_transmit(seSet, use_sm)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end
        
        local hash = hex.hexf("90%B", string.len(data)) .. data
        local putHash = hex.hexf("002a90a0%B", string.len(hash)) .. hash
        resp = self:sm_transmit(putHash, use_sm)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end
        
        if pin and string.len(pin) > 0 then
            local res = self:verify_pin_main(pin, false, false, use_sm)
            if res ~= 0 then
                error(EIDASmartcard.EIDASmartcardError.new(sw, 
                    'pso_cds error: verify_pin_main failed!' ), 2)
            end
        end
        local pso_cds = hex.hexf("002a9e9a00")
        resp = self:sm_transmit(pso_cds, use_sm)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end
        
        break
    until true
    
    if sw ~= hexf('9000') then
        error(EIDASmartcard.EIDASmartcardError.new(sw, 'pso_cds error' ), 2)
    end
    return string.sub(resp, 1, -3)
end


function EIDASmartcard.mt:pso_decrypt(data, id, use_sm)

    local sw, resp
    if id == nil then id = '3'
    elseif type(id) == 'number' then 
        id = hex.hexify(hex.hexf('%B', id))
    elseif string.len(id) == 1 then 
        id = hex.hexify(id)
    end
    repeat
        local seRestore = hex.hexf("0022730100")
        resp = self:sm_transmit(seRestore, use_sm)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end
        
        seSetCT = hex.hexf("002241b80680011a8401" .. id)
        resp = self:sm_transmit(seSetCT, use_sm)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end
        
        -- NOTA: non si pu