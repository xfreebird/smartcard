 creare un loop ricorsivo
    self:auto_select_p15()
    
    local result = self:TX(header, data, LE)
    self.last_sw = string.sub(result, -2, -1)
    return result
end


function IasEccSmartcard.mt:sm_transmit(apdu, use_sm)
    return self:transmit(apdu)
end

function IasEccSmartcard.mt:select(path, relative, use_sm)
    local sw, recv, path1, relative_id
    if relative then relative_id = 0 else relative_id = 8 end
    local template_h, template_p = '00A4%B0402%H', '00A4%B04%P'
    log.output('select(): ', path and hexify(path))
    path1 = path
    if path1 == nil then
        path1 = hexf('3f00')
    end
    if type(path)=='number' then
        recv = self:sm_transmit(hexf(template_h, relative_id, path1) .. "\0", use_sm)
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
            recv = self:sm_transmit(hexf(template_p, relative_id, path1) .. "\0", use_sm)
            sw = string.sub(recv, -2, -1)
        end
    end
    if sw ~= hexf('9000') then
        error(IasEccSmartcard.IasEccSmartcardError.new(sw, 'select Error'), 2)
    elseif string.len(recv) > 2 then
        return IasEccSmartcard.parse_fci(recv)
    end
end

function IasEccSmartcard.mt:get_random(ammount)
    assert (ammount == 8)
    local recv = self:transmit(hexf('00840000%B', ammount))
    local sw = string.sub(recv, -2, -1)
    if sw == hexf('9000') then
        self._last_random_from_card = string.sub(recv, 1, -3)
    else
       error(IasEccSmartcard.IasEccSmartcardError.new(sw, 'get_random Error'), 2)
    end
    
    return self._last_random_from_card
end

function IasEccSmartcard.mt:read_binary(offset, size, use_sm)
    local recv
    log.output("reading from:", offset, "size:", size)
    local apdu = hexf('00B0%H%B', offset, size)
    recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') and sw ~= hexf('6282') then
        error(IasEccSmartcard.IasEccSmartcardError.new(sw, 'read_binary Error'), 2)
    end
    return string.sub(recv, 1, -3)
end

function IasEccSmartcard.mt:mread_binary(offset, size, use_sm)
    local buffer_size = IasEccSmartcard.MAX_TRANSMIT_BUFFER_SIZE
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


function IasEccSmartcard.mt:verify(bso, pin, backtracking)
    return self:sm_verify(bso, pin, backtracking)
end

function IasEccSmartcard.mt:sm_verify(bso, pin, backtracking, use_sm)
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
        error(IasEccSmartcard.IasEccSmartcardError.new(sw, 'sm_verify Error' ), 2)
    end
end


function IasEccSmartcard.mt:sm_change(bso, oldPin, newPin, backtracking, use_sm)
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
        error(IasEccSmartcard.IasEccSmartcardError.new(sw, 'sm_change Error' ), 2)
    end
end


function IasEccSmartcard.mt:begin_transaction()
    self.card:begintransaction()
end

function IasEccSmartcard.mt:end_transaction()
    self._performed_mutual_auth = false
    self.card:endtransaction()
end

function IasEccSmartcard.mt:on_end_transaction()
    self._performed_mutual_auth = false
end


function IasEccSmartcard.mt:sm_reset_retry_counter(bso, newPin, backtracking, use_sm)
    if backtracking then
        bso = (bin.flags(bso) + bin.flags(128)).asnumber
    end
    local mode = 2
    if not newPin then
        mode = 3
    end
    local sw = self:sm_transmit(hexf('002C%B%B%P', mode, bso, (newPin or '')), use_sm)
    if sw == hexf('6983')  or sw == hexf('6984') then
        return 2, 'Authentication blocked'
    elseif bin.mask_compare(sw, hexf('6300'), hexf('FF00')) then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        return 0, 'Authentication succeeded'
    else
        log.output('sm_reset_retry_counter(): Error ' .. hexify(sw) )
        error(IasEccSmartcard.IasEccSmartcardError.new(sw, 'sm_reset_retry_counter Error' ), 2)
    end
end

function IasEccSmartcard.mt:valid()
    local status, err = self.card:status()
    if not status then
        log.output('IasEccSmartcard:valid(): status() error', hex.tohex8(err or 0))
        return false
    elseif status.protocol == 0 or string.len(status.atr or '') == 0 then
        log.output('IasEccSmartcard:valid(): card removed?')
        return false
    end
    return true
end

---------------------------------------------------
function IasEccSmartcard.handle_error(err_obj)
    print(debug.traceback(err_obj))
    return err_obj
end

-- path_key: ascii hex string, returns modulis,exponent as binary string
function IasEccSmartcard.mt:read_public_key(kid, use_sm)

    if type(kid) == 'number' then 
        kid = hex.hexify(hex.hexf('%B', kid))
    elseif string.len(kid) == 1 then 
        kid = hex.hexify(kid)
    end
    -- elimina bit 0x80 se presente
    kid = string.format("%02X", (bin.flags("0x" .. kid) - bin.flags("0x80")).asnumber)
    local resp
    
    -->> 00 cb 3f ff 0b 4d 09 70 07 bf a0 03 03 7f 49 80
    --<< 70 81 94 BF A0 03 81 8F 7F 49 81 8B 81 81 80 A4 DE C0 3A 88 7D BD 9E 95 60 74 2E 7C 07 19 E2 11 66 D5 A7 4E 1C AD E7 97 EF A9 B4 F0 21 63 E0 87 6F 4B D9 E0 86 55 A1 96 0B A9 6B C4 54 B2 BD 3C 5B 03 D9 8E 35 3A CA CF 8B 5C 8C EF 31 32 5C 1A 02 17 7A 9F 99 D6 CA F5 9C 36 BA 4D AE 13 79 9E E6 F6 80 9F 15 40 2B B7 D7 C7 97 CD 3A 7C 26 56 AE 15 23 74 0A 1E 27 15 60 55 1F C7 FE 35 D0 69 51 08 CE 98 EA 40 B9 F0 81 A9 8A ED 7E 24 09 82 03 01 00 01 80 01 00
    -- TAG-Oggetto su 3 byte: BF + MIDDLE-TAG + KID
    -- per le pub key il middle tag 