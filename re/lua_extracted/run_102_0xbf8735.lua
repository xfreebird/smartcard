 0x90
    
    -- questo comando legge l'intera chiave pubblica (mod + pubexp)
    -- comando non documentato, ricavato da osservazione MW Oberthur
    local getPubK = "00CB3fFF0b4d097007BF" .. "A0" .. kid .. "037f4980"
    getPubK = hex.hexf(getPubK)
    resp = self:sm_transmit(getPubK, use_sm)
    local sw = string.sub(resp, -2, -1)
    if sw ~= hexf("9000") then
        return
    end
    
    local d = parse_tlv_ber(string.sub(resp, 1, -3) )
    local d1 = parse_tlv_ber( d[tonumber('70', 16)] )
    for tag, v in d1 do
        if (bin.flags(tag) * bin.flags('0xffff00')).asnumber == h2i("bfa000") then
            local d2 = parse_tlv_ber( v )
            local d3 = parse_tlv_ber( d2[tonumber('7F49', 16)] )
            local MOD = d3[tonumber("81", 16)]
            local EXP = d3[tonumber("82", 16)]
            return MOD, EXP
        end
    end
end


-- pin binary string;
function IasEccSmartcard.mt:verify_pin_main(pin, ispuk, check, use_sm)
    log.output('verify_pin_main():', pin, ispuk, check)
    local bso = self.BSO_PIN
    local padding = self.PIN_PADDING
    local padChar = self.PIN_PADDING_CHAR
    if ispuk then
        bso = self.BSO_PUK
        padding = self.PUK_PADDING
        padChar = self.PUK_PADDING_CHAR
    end
    if string.len(pin)> padding then
        pin = string.sub(pin, 1, padding)
    end
    if check then
        if 0 == self:sm_verify(bso, "", false, use_sm) then
            return 0
        else
            return -1
        end
    end
    pin = pin .. string.rep(padChar, padding - string.len(pin))
    return self:sm_verify(bso, pin, false, use_sm)
end

function IasEccSmartcard.mt:change_pin_main(oldPin, newPin, ispuk, use_sm)
    local bso = self.BSO_PIN
    local padding = self.PIN_PADDING
    local padChar = self.PIN_PADDING_CHAR
    if ispuk then
        bso = self.BSO_PUK
        padding = self.PUK_PADDING
        padChar = self.PUK_PADDING_CHAR
    end
    if string.len(oldPin or '') > padding then
        oldPin = string.sub(oldPin, 1, padding)
    end
    if string.len(newPin) > padding then
        error('IasEccSmartcard change_pin_main Error: wrong PIN size', 2)
    end
    if oldPin then
        oldPin = oldPin .. string.rep(padChar, padding - string.len(oldPin))
    end
    newPin = newPin .. string.rep(padChar, padding - string.len(newPin))
    return self:sm_change(bso, oldPin, newPin, false, use_sm)
end


function IasEccSmartcard.mt:reset_pin_main(Puk, newPin, use_sm)
    if string.len(Puk or '' ) > self.PUK_PADDING then
        Puk = string.sub(Puk, 1, self.PUK_PADDING)
    end
    if string.len(newPin) > self.PIN_PADDING then
        error('IasEccSmartcard reset_pin_main Error: wrong PIN size', 2)
    end
    Puk = Puk .. string.rep(self.PUK_PADDING_CHAR, self.PUK_PADDING - string.len(Puk))
    newPin = newPin .. string.rep(self.PIN_PADDING_CHAR, self.PIN_PADDING - string.len(newPin))
    local res
    
    res = self:verify_pin_main(Puk, true, false, use_sm)
    if res ~= 0 then return res end
    return self:sm_reset_retry_counter(self.BSO_PIN, newPin, false, use_sm)
end

function IasEccSmartcard.mt:pso_rsa_internal_authenticate(data, id, pin, use_sm)
    local sw, resp
    if id == nil then id = '3'
    elseif type(id) == 'number' then 
        id = hex.hexify(hex.hexf('%B', id))
    elseif string.len(id) == 1 then 
        id = hex.hexify(id)
    end
    repeat 
        -- local seRestore = hex.hexf("0022f30100")
        -- resp = self:sm_transmit(seRestore, use_sm)
        -- sw = string.sub(resp, -2, -1)
        -- if sw ~= hexf('9000') then break end
        local algo = 2 -- NO HASH DSI OID
        
        
        -- local SHA256_DIGEST_OID = hex.hexf("3031300d060960864801650304020105000420")
        -- if SHA256_DIGEST_OID == string.sub(data, 1, string.len(SHA256_DIGEST_OID)) then
            -- algo = 66 -- 0x42: SHA256
            -- data = string.sub(data, string.len(SHA256_DIGEST_OID)+1, -1)
        -- end
        local seSet = hex.hexf("002241a4068001%B8401" .. id, algo)
        resp = self:sm_transmit(seSet, use_sm)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end

        if pin and string.len(pin) > 0 then
            local res = self:verify_pin_main(pin, false, false, use_sm)
            if res ~= 0 then
                error(IasEccSmartcard.IasEccSmartcardError.new(sw, 
                    'pso_rsa_internal_authenticate error: verify_pin_main failed!' ), 2)
            end
        end
        
        local extAuth = hex.hexf("00880000%P", data)
        resp = self:sm_transmit(extAuth, use_sm)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end
        
        break
    until true
    
    if sw ~= hexf('9000') then
        error(IasEccSmartcard.IasEccSmartcardError.new(sw, 'pso_cds error' ), 2)
    end
    return string.sub(resp, 1, -3)
end

function IasEccSmartcard.mt:pso_cds(data, id, pin, use_sm)
    local sw, resp
    if id == nil then id = '3'
    elseif type(id) == 'number' then 
        id = hex.hexify(hex.hexf('%B', id))
    elseif string.len(id) == 1 then 
        id = hex.hexify(id)
    end
    repeat 
        local algo = 2 -- NO HASH DSI OID
        local SHA256_DIGEST_OID = hex.hexf("3031300d060960864801650304020105000420")
        local SHA1_DIGEST_OID = hex.hexf("3021300906052b0e03021a05000414")
        if SHA1_DIGEST_OID == string.sub(data, 1, string.len(SHA1_DIGEST_OID)) then
            algo = 18 -- 0x12: SHA1
            data = string.sub(data, string.len(SHA1_DIGEST_OID)+1, -1)       
       
        elseif SHA256_DIGEST_OID == string.sub(data, 1, string.len(SHA256_DIGEST_OID)) then
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
                error(IasEccSmartcard.IasEccSmartcardError.new(sw, 
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
        error(IasEccSmartcard.IasEccSmartcardError.new(sw, 'pso_cds error' ), 2)
    end
    return string.sub(resp, 1, -3)
end


function IasEccSmartcard.mt:pso_decrypt(data, id, use_sm)

    local sw, resp
    if id == nil then id = '3'
    elseif type(id) == 'number' then 
        id = hex.hexify(hex.hexf('%B', id))
    elseif string.len(id) == 1 then 
        id = hex.hexify(id)
    end
    repeat
        
        seSetCT = hex.hexf("002241b80680011a8401" .. id)
        resp = self:sm_transmit(seSetCT, use_sm)
        sw = string.sub(resp, -2, -1)
        if sw ~= hexf('9000') then break end
        
        -- NOTA: non si pu