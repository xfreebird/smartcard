 avvenuta usando un numero minimo di APDU
    -- 2) mantenere lo stato della mutua autenticazione come valido nell'ambito della medesima transazione
    -- 3) eseguire la mutua autenticazione solo se necessario
    local res
    log.output("NXPIASSmartCard:auto_perform_mutual_authenticate(): checkOnActiveSMOnly:", checkOnActiveSMOnly)
    if checkOnActiveSMOnly and not self.ActiveSM then
        log.output("NXPIASSmartCard:auto_perform_mutual_authenticate(): SM not Active, nothing to do...")
        return false
    end
    if not self._performed_mutual_auth then
        if self._current_selected_aid and self.ssc and self.sessENC and self.sessMAC then
            log.output("NXPIASSmartCard:auto_perform_mutual_authenticate(): checking existing secure channel...")
            local select_aid = hex.hexf("00a40404%P00", self._current_selected_aid)
            local resp, valid, ssc = self:SMTX(self.ssc, self.sessENC, self.sessMAC, select_aid)
            self.ssc = ssc or self.ssc
            local sw = string.sub(resp, -2, -1)
            if valid and sw == hexf('9000') then
                log.output("NXPIASSmartCard:auto_perform_mutual_authenticate(): not needed: still valid channel!")
                self._performed_mutual_auth = true
                
                return false
            else
                self.ActiveSM = false
                log.output("NXPIASSmartCard:auto_perform_mutual_authenticate(): channel not valid!")
            end
        end
        log.output("NXPIASSmartCard:auto_perform_mutual_authenticate(): not performed, starting...")
        res = self:perform_mutual_authenticate()
        return res
    else
        log.output("NXPIASSmartCard:auto_perform_mutual_authenticate(): not needed: inside same transaction!")
        return false
    end
end

function NXPIASSmartCard.mt:mse_load(id)
    log.output("NXPIASSmartCard:mse_load()")
    local apdu = hex.hexf("0022F3" .. id)
    local recv = self:transmit(apdu)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'MSE restore Error'))
    end
end



function NXPIASSmartCard.mt:perform_mutual_authenticate(aid)
    
    log.output("NXPIASSmartCard:perform_mutual_authenticate(): ", aid and hex.hexify(aid) or "")
    self._performed_mutual_auth = false

    if self._current_selected_aid == SSCD_AID or aid == SSCD_AID then
        self:StartSM_SSCD_FS()
    else
        self:StartSM_Generic_FS()
    end
    self._performed_mutual_auth = true
    
    
    return true
end

-------------------------------------------------------

function NXPIASSmartCard.parse_tlv(tlv_struct)
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

function NXPIASSmartCard.parse_fci(fci)
    local fci1 = NXPIASSmartCard.parse_tlv(fci)
    local fci2 = NXPIASSmartCard.parse_tlv(fci1[98] or fci1[111]) -- 0x62 or 0x6F
    local infos = {size=(fci2[128] or fci2[129]) and bin.unpack("%>%H", fci2[128] or fci2[129]),
                      filetype = fci2[130] and string.byte(fci2[130], 1),
                      options=fci2[130],
                      fid_n=fci2[131] and bin.unpack("%>%H", fci2[131]),
                      fid =fci2[131],
                      flags=fci2[133],
                      ac = fci2[134],
                      sm = fci2[135] or fci2[203] or fci2[139],
                      }
    return infos
end


function NXPIASSmartCard.mt:transmit(apdu)
    local resp = ""
    
    if self.on_transmit then
        self:on_transmit(apdu)
    end
    
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
    self.last_sw = string.sub(resp, -2, -1)
    return resp
end


function NXPIASSmartCard.mt:sm_transmit(apdu, use_sm)
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

function NXPIASSmartCard.mt:select(path, relative, use_sm)
    log.output("NXPIASSmartCard:select()")
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local sw, recv, path1, relative_id
    if relative == 1 then 
        relative_id = 1
    elseif relative then
        relative_id = 2
    else
        relative_id = 8 
    end
    local template_h, template_p = '00A4%B0402%H00', '00A4%B04%P00'
    path1 = path
    if path1 == nil then
        log.output('select(): fid=nil')
        recv = self:sm_transmit(hexf("00a40000"), use_sm)
        sw = string.sub(recv, -2, -1)
    elseif type(path)=='number' then
        log.output(string.format('select(): number fid=%04X', path))
        recv = self:sm_transmit(hexf(template_h, relative_id, path1), use_sm)
        sw = string.sub(recv, -2, -1)
    else
        if path1 == hexf('3f00') then
            log.output('select(): fid=MF')
            recv = self:sm_transmit(hexf('00A40000023f0000'), use_sm)
            sw = string.sub(recv, -2, -1)
        else
            log.output('select(): path=', hexify(path))
            if string.sub(path1, 1, 2) == hexf('3f00') then
                path1 = string.sub(path1, 3, -1)
                log.output('select(): removed MF from path', hexify(path1))
            end
            recv = self:sm_transmit(hexf(template_p, relative_id, path1), use_sm)
            sw = string.sub(recv, -2, -1)
        end
    end
    if sw ~= hexf('9000') then
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'select Error'))
    elseif string.len(recv) > 2 then
        return NXPIASSmartCard.parse_fci(recv)
    end
end


function NXPIASSmartCard.mt:read_binary(offset, size, use_sm)
    log.output("NXPIASSmartCard:read_binary()")
    local recv
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    log.output("reading from:", offset, "size:", size)
    local apdu = hexf('00B0%H%B', offset, size)
    recv = self:sm_transmit(apdu, use_sm)
    local sw = string.sub(recv, -2, -1)
    
    if sw == hexf('6B00') then
        self.last_sw = hex.hexf("9000")
        return ""
    elseif sw ~= hexf('9000') and sw ~= hexf('6282') then
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'read_binary Error'))
    end
    return string.sub(recv, 1, -3)
end

function NXPIASSmartCard.mt:mread_binary(offset, size, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local buffer_size = NXPIASSmartCard.MAX_TRANSMIT_BUFFER_SIZE
    log.output("NXPIASSmartCard:mread_binary:multi reading from:", offset, "size:", size, "chunks:", buffer_size)
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
        
        log.output("NXPIASSmartCard:mread_binary: partial content:", hex.hexify(string.sub(recv, 1, buffer_size)))
        
    end
    log.output("NXPIASSmartCard:mread_binary:content:", hex.hexify(content))
    return content
end

function NXPIASSmartCard.mt:mread_binary_smart(offset, size, use_sm)
    -- stops when a block of all zeroes is read back
    log.output("NXPIASSmartCard:mread_binary_smart()")
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local buffer_size = NXPIASSmartCard.MAX_TRANSMIT_BUFFER_SIZE
    log.output("NXPIASSmartCard:mread_binary_smart:multi reading from:", offset, "size:", size, "chunks:", buffer_size)
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
        log.output("NXPIASSmartCard:mread_binary_smart: partial content:", hex.hexify(data))
        if data == string.rep("\0", string.len(data)) then
            log.output("NXPIASSmartCard:mread_binary_smart: null content detected, stopping...")
            break
        end
    end
    log.output("NXPIASSmartCard:mread_binary_smart:content:", hex.hexify(content))
    return content
end


function NXPIASSmartCard.mt:change(bso, oldPin, newPin, backtracking)
    log.output("NXPIASSmartCard:change()")
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
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'change Error' ))
    end
end


function NXPIASSmartCard.mt:begin_transaction()
    log.output('NXPIASSmartCard:begin_transaction()')
    self.card:begintransaction()
    if self.on_begin_transaction then
        self:on_begin_transaction()
    end
end

function NXPIASSmartCard.mt:end_transaction()
    self._performed_mutual_auth = false
    log.output('NXPIASSmartCard:end_transaction(): self._performed_mutual_auth = false')
    
    if self.on_end_transaction then
        self:on_end_transaction()
    end
    
    self.card:endtransaction()
end

function NXPIASSmartCard.mt:on_end_transaction()
    log.output('NXPIASSmartCard:on_end_transaction()...')
    self._performed_mutual_auth = false
end


function NXPIASSmartCard.mt:reset_retry_counter(bso, newPin, backtracking)
    log.output("NXPIASSmartCard:reset_retry_counter()")
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
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'reset_retry_counter Error' ))
    end
end

function NXPIASSmartCard.mt:get_pin_puk_docp(force)
    log.output("NXPIASSmartCard:get_pin_puk_docp()")
  
        if not self.pinDOCP or not self.pukDOCP or force then
            local pcRes, theErrorT = pcall(function()
                self:select_MF()
                self.pinDOCP = self:get_DOCP(NXPIASSmartCard.object_classes.PIN, self.ID_PIN)
                self.pukDOCP = self:get_DOCP(NXPIASSmartCard.object_classes.PIN, self.ID_PUK)
            end)
            if not pcRes then
                log.output('get_pin_puk_docp(): Error:', debug.traceback(theErrorT) )
            end
        end
    return self.pinDOCP, self.pukDOCP
end
    
function NXPIASSmartCard.mt:get_pin_puk_status()
    log.output("NXPIASSmartCard:get_pin_puk_status()")
    local pinRetry, pinRetryMax, pukRetry, pukRetryMax 


    local pinDOCP, pukDOCP = self:get_pin_puk_docp(true)

    
    pinRetry = pinDOCP and pinDOCP.tries or 3
    pinRetryMax = pinDOCP and pinDOCP.maxTries or 10
    
    pukRetry = pukDOCP and pukDOCP.tries or 3
    pukRetryMax = pukDOCP and pukDOCP.maxTries or 3
    
    log.output("NXPIASSmartCard:get_pin_puk_status():", pinRetry, pinRetryMax, pukRetry, pukRetryMax)
    return pinRetry, pinRetryMax, pukRetry, pukRetryMax
end


function NXPIASSmartCard.mt:valid()
    local status, err = self.card:status()
    if not status then
        log.output('NXPIASSmartCard:valid(): status() error', hex.tohex8(err or 0))
        return false
    elseif status.protocol == 0 or string.len(status.atr or '') == 0 then
        log.output('NXPIASSmartCard:valid(): card removed?')
        return false
    end
    return true
end

---------------------------------------------------
function NXPIASSmartCard.handle_error(err_obj)
    print(debug.traceback(err_obj))
    return err_obj
end

-- GET DATA SDO examples:
-- 00 cb 00 03 04: get data, card / os version on 4 bytes
-- 80 cb 00 11 00: get data, available eeprom size on 4 bytes (Big Endian?)
-- 00 cb 3f ff 0a 4d 08 70 06 bf 81 02 02 a0 80 00: get DOCP (tag A0) PIN #2 (PUK) User authentication: PIN / Password BF->'81'
-- 00 cb 3f ff 0a 4d 08 70 06 bf 81 01 02 a0 80 00: get DOCP (tag A0) PIN #1 (PIN) User authentication: PIN / Password BF->'81'
-- 00 cb 3f ff 0b 4D 09 70 07 BF A0 10 03 7F 49 80 00: get DOUP Asymmetric keys RSA #0x10 (BF-> 'A0' -> #0x10) 