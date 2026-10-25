 avvenuta usando un numero minimo di APDU
    -- 2) mantenere lo stato della mutua autenticazione come valido nell'ambito della medesima transazione
    -- 3) eseguire la mutua autenticazione solo se necessario
    local res
    log.output("CosmoXIASSmartCard:auto_perform_mutual_authenticate(): checkOnActiveSMOnly:", checkOnActiveSMOnly)
    if checkOnActiveSMOnly and not self.ActiveSM then
        log.output("CosmoXIASSmartCard:auto_perform_mutual_authenticate(): SM not Active, nothing to do...")
        return false
    end
    if not self._performed_mutual_auth then
        if self._current_selected_aid and self.ssc and self.sessENC and self.sessMAC then
            log.output("CosmoXIASSmartCard:auto_perform_mutual_authenticate(): checking existing secure channel...")
            local select_aid = hex.hexf("00a40404%P00", self._current_selected_aid)
            local resp, valid, ssc = self:SMTX(self.ssc, self.sessENC, self.sessMAC, select_aid)
            self.ssc = ssc or self.ssc
            local sw = string.sub(resp, -2, -1)
            if valid and sw == hexf('9000') then
                log.output("CosmoXIASSmartCard:auto_perform_mutual_authenticate(): not needed: still valid channel!")
                self._performed_mutual_auth = true
                
                return false
            else
                self.ActiveSM = false
                log.output("CosmoXIASSmartCard:auto_perform_mutual_authenticate(): channel not valid!")
            end
        end
        log.output("CosmoXIASSmartCard:auto_perform_mutual_authenticate(): not performed, starting...")
        res = self:perform_mutual_authenticate()
        return res
    else
        log.output("CosmoXIASSmartCard:auto_perform_mutual_authenticate(): not needed: inside same transaction!")
        return false
    end
end

local function calculate_AES_KEYS_sha256(CAN)
    local first_step = md.sha256()
    first_step:update(CAN .. hex.hexf('00000002'))
    local k1 = first_step:final()
    log.output("calculate_AES_KEYS_sha256(): k1:", hex.hexify(k1))

    local first_step = md.sha256()
    first_step:update(CAN .. hex.hexf('00000003'))
    local k2 = first_step:final()
    log.output("calculate_AES_KEYS_sha256(): k2:", hex.hexify(k2))
    
    return k1, k2
end

function CosmoXIASSmartCard.mt:perform_mutual_authenticate()
    
    log.output("CosmoXIASSmartCard:perform_mutual_authenticate(): ")
    self._performed_mutual_auth = false
    self.ActiveSM = false

    -- recv = self:sm_transmit(CosmoXIASSmartCard.SELECT_MAIN_APPLET_MF_AID, false)
    self:select_Applet(false)
    

    
    local ICC_SN_FULL = self:read_serial_number(true) -- force=true
    
    if not self.RANDOM_SEED then
        -- MF already selected!
        self:select(hex.hexf("d004"))
        self.RANDOM_SEED = self:read_binary(0, 16)
    end
    local ADMIN_AES_KEY_ENC, ADMIN_AES_KEY_SIG = calculate_AES_KEYS_sha256(string.sub(self.RANDOM_SEED, 1, 16) .. ICC_SN_FULL .. self.MK)
    
    log.output("ADMIN_AES_KEY_ENC:", hex.hexify(ADMIN_AES_KEY_ENC))
    log.output("ADMIN_AES_KEY_SIG:", hex.hexify(ADMIN_AES_KEY_SIG))
    
    local ICC_SN = string.sub(ICC_SN_FULL, string.len(ICC_SN_FULL)-7, string.len(ICC_SN_FULL))
    log.output("STEP: ICC_SN:", hex.hexify(ICC_SN))
    self.ICC_SN = ICC_SN
    
    self.ICC_SN_FULL = ICC_SN_FULL
    self.kEnc = ADMIN_AES_KEY_ENC
    self.kMac = ADMIN_AES_KEY_SIG
    
    local apdu = hex.hexf("0022c1a4098004ff40108c830104")
    log.output("STEP: set MSE SM AES + sha256 APDU:", hex.hexify(apdu))
    local recv = self:transmit(apdu) -- set MSE SM AES + sha256
    log.output("STEP: set MSE SM AES + sha256 RECV:", hex.hexify(recv))
    if string.sub(recv, -2, -1) ~= hex.hexf("9000") then
        error("perform_mutual_authenticate: MSE SET");
    end
    
    local apdu = hex.hexf("0084000010")
    log.output("STEP: get ICC random APDU:", hex.hexify(apdu))
    local recv = self:transmit(apdu)
    log.output("STEP: get ICC random RECV:", hex.hexify(recv))
    if string.sub(recv, -2, -1) ~= hex.hexf("9000") then
        error("perform_mutual_authenticate: get ICC random");
    end
    
    local ICC_RND = string.sub(recv, 1, -3)
    log.output("STEP: ICC_RND:", hex.hexify(ICC_RND))


    
    local payload, SSC, RND_IFD_1, SN_IFD_1, K_IFD_1 = DO_MUTUAL_AUTH(ICC_RND, ICC_SN,  self.kEnc, self.kMac)
    local mutual_auth_apdu = hex.hexf("00820000%P60", payload)
    log.output("STEP: mutual_auth_apdu:", hex.hexify(mutual_auth_apdu))
    
    local recv = self:transmit(mutual_auth_apdu)
    log.output("STEP: mutual_auth_apdu RECV:", hex.hexify(recv))
    if string.sub(recv, -2, -1) ~= hex.hexf("9000") then
        error("perform_mutual_authenticate: MUTUAL AUTH");
    end
    
    local RND_ICC_1, SN_ICC_1, K_ICC_1, sessENC_1, sessMAC_1 = DECODE_MUTUAL_AUTH_RESPONSE(recv, RND_IFD_1, SN_IFD_1, K_IFD_1,  self.kEnc, self.kMac)

    log.output("STEP: RND_ICC_1:", hex.hexify(RND_ICC_1))
    log.output("STEP: SN_ICC_1:", hex.hexify(SN_ICC_1))
    log.output("STEP: K_ICC_1:", hex.hexify(K_ICC_1))
    log.output("STEP: sessENC_1:", hex.hexify(sessENC_1))
    log.output("STEP: sessMAC_1:", hex.hexify(sessMAC_1))


    self.RND_ICC = RND_ICC_1
    self.SN_ICC  = SN_ICC_1
    self.RND_ICC = RND_ICC_1
    self.K_ICC   = K_ICC_1
    self.sessENC = sessENC_1
    self.sessMAC = sessMAC_1
    self.ssc = SSC

    self._performed_mutual_auth = true
    self.ActiveSM = true
    return true
end

-------------------------------------------------------

function CosmoXIASSmartCard.parse_tlv(tlv_struct)
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

function CosmoXIASSmartCard.parse_fci(fci)
    local fci1 = CosmoXIASSmartCard.parse_tlv(fci)
    local fci2 = CosmoXIASSmartCard.parse_tlv(fci1[98] or fci1[111]) -- 0x62 or 0x6F
    local ac_contact, ac_cless
    local mapped_ambs_contact, mapped_ambs_cless
    local ambs_contact, ambs_cless
    local filetype = fci2[130] and string.byte(fci2[130], 1) or 1
    if fci2 and fci2[tonumber("a1", 16)] then
        local fci_ac = CosmoXIASSmartCard.parse_tlv(fci2[tonumber("a1", 16)])
        ac_contact = fci_ac[tonumber("8C", 16)]
        ac_cless = fci_ac[tonumber("9C", 16)]
        
       ambs_contact = CosmoXIASSmartCard.parse_ambs(ac_contact)
       ambs_cless = CosmoXIASSmartCard.parse_ambs(ac_cless)
       
       mapped_ambs_contact = CosmoXIASSmartCard.map_ambs(filetype, ambs_contact)
       mapped_ambs_cless = CosmoXIASSmartCard.map_ambs(filetype, ambs_cless)
       
        
    end
    local infos = {size=(fci2[128] or fci2[129]) and bin.unpack("%>%H", fci2[128] or fci2[129]),
                      filetype = filetype,
                      options=fci2[130],
                      fid_n=fci2[131] and bin.unpack("%>%H", fci2[131]),
                      fid =fci2[131],
                      flags=fci2[133],
                      ac_contact = ac_contact,
                      ac_cless = ac_cless,
                      mapped_ambs_contact=mapped_ambs_contact,
                      mapped_ambs_cless=mapped_ambs_cless,
                      sm = fci2[135] or fci2[203] or fci2[139],
                      }
    return infos
end


function CosmoXIASSmartCard.mt:transmit(apdu)
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


function CosmoXIASSmartCard.mt:sm_transmit(apdu, use_sm)
    log.output("sm_transmit:....")
    if not use_sm then
        return self:transmit(apdu)
    end
    if not self._performed_mutual_auth then
        self:auto_perform_mutual_authenticate()
    end
    
    -- log.output("sm_transmit: apdu:", hex.hexify(apdu))
    -- io.stdout:flush()
    
    local resp, valid, ssc = self:SMTX(self.ssc, self.sessENC, self.sessMAC, apdu)
    self.ssc = ssc or self.ssc
    self.last_sw = string.sub(resp, -2, -1)
    return resp, valid
end

function CosmoXIASSmartCard.mt:select(id, select_df, use_sm)
    log.output("CosmoXIASSmartCard:select()")
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local sw, recv, relative_id
    if select_df then 
        relative_id = 1 -- Select child DF 
    else
        relative_id = 2 -- Select EF under the current DF
    end
    local template_h, template_p = '00A4%B0402%H00', '00A4%B04%P00'
    if id == nil or id == hexf('3f00') then
        log.output('select(): fid=MF')
        recv = self:sm_transmit(hexf('00A40004023f0000'), use_sm)
        sw = string.sub(recv, -2, -1)
    elseif type(id)=='number' then
        log.output(string.format('select(): number fid=%04X', id))
        recv = self:sm_transmit(hexf(template_h, relative_id, id), use_sm)
        sw = string.sub(recv, -2, -1)
    else
        log.output('select(): path=', hexify(id))
        recv = self:sm_transmit(hexf(template_p, relative_id, id), use_sm)
        sw = string.sub(recv, -2, -1)
    
    end
    if sw ~= hexf('9000') then
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'select Error'))
    elseif string.len(recv) > 2 then
        return CosmoXIASSmartCard.parse_fci(recv)
    end
end


function CosmoXIASSmartCard.mt:read_binary(offset, size, use_sm)
    log.output("CosmoXIASSmartCard:read_binary()")
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
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'read_binary Error'))
    end
    return string.sub(recv, 1, -3)
end

function CosmoXIASSmartCard.mt:mread_binary(offset, size, use_sm)
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local buffer_size = CosmoXIASSmartCard.MAX_TRANSMIT_BUFFER_SIZE
    log.output("CosmoXIASSmartCard:mread_binary:multi reading from:", offset, "size:", size, "chunks:", buffer_size)
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
        
        log.output("CosmoXIASSmartCard:mread_binary: partial content:", hex.hexify(string.sub(recv, 1, buffer_size)))
        
    end
    log.output("CosmoXIASSmartCard:mread_binary:content:", hex.hexify(content))
    return content
end

function CosmoXIASSmartCard.mt:mread_binary_smart(offset, size, use_sm)
    -- stops when a block of all zeroes is read back
    log.output("CosmoXIASSmartCard:mread_binary_smart()")
    use_sm = use_sm == nil and self.ActiveSM or use_sm
    local buffer_size = CosmoXIASSmartCard.MAX_TRANSMIT_BUFFER_SIZE
    log.output("CosmoXIASSmartCard:mread_binary_smart:multi reading from:", offset, "size:", size, "chunks:", buffer_size)
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
        log.output("CosmoXIASSmartCard:mread_binary_smart: partial content:", hex.hexify(data))
        if data == string.rep("\0", string.len(data)) then
            log.output("CosmoXIASSmartCard:mread_binary_smart: null content detected, stopping...")
            break
        end
    end
    log.output("CosmoXIASSmartCard:mread_binary_smart:content:", hex.hexify(content))
    return content
end


function CosmoXIASSmartCard.mt:change(bso, oldPin, newPin, backtracking)
    log.output("CosmoXIASSmartCard:change()")
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
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'change Error' ))
    end
end


function CosmoXIASSmartCard.mt:begin_transaction()
    log.output('CosmoXIASSmartCard:begin_transaction()')
    self.card:begintransaction()
    if self.on_begin_transaction then
        self:on_begin_transaction()
    end
end

function CosmoXIASSmartCard.mt:end_transaction()
    self._performed_mutual_auth = false
    log.output('CosmoXIASSmartCard:end_transaction(): self._performed_mutual_auth = false')
    
    if self.on_end_transaction then
        self:on_end_transaction()
    end
    
    self.card:endtransaction()
end

function CosmoXIASSmartCard.mt:on_end_transaction()
    log.output('CosmoXIASSmartCard:on_end_transaction()...')
    self._performed_mutual_auth = false
end


function CosmoXIASSmartCard.mt:reset_retry_counter(bso, newPin, backtracking)
    log.output("CosmoXIASSmartCard:reset_retry_counter()")
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
    elseif sw == hexf('6982') or sw == hexf('6700') or bin.mask_compare(sw, hexf('6300'), hexf('FF00')) then
        return 1, 'Authentication failed'
    elseif sw == hexf('9000') then
        return 0, 'Authentication succeeded'
    else
        log.output('reset_retry_counter(): Error ' .. hexify(sw) )
        error(CosmoXIASSmartCard.CosmoXIASSmartCardError.new(sw, 'reset_retry_counter Error' ))
    end
end

function CosmoXIASSmartCard.mt:get_pin_puk_docp(force)
    log.output("CosmoXIASSmartCard:get_pin_puk_docp()")
  
        if not self.pinDOCP or not self.pukDOCP or force then
            local pcRes, theErrorT = pcall(function()
                self:select_MF()
                self.pinDOCP = self:get_DOCP(CosmoXIASSmartCard.object_classes.PIN, self.ID_PIN)
                self.pukDOCP = self:get_DOCP(CosmoXIASSmartCard.object_classes.PIN, self.ID_PUK)
            end)
            if not pcRes then
                log.output('get_pin_puk_docp(): Error:', debug.traceback(theErrorT) )
            end
        end
    return self.pinDOCP, self.pukDOCP
end

function CosmoXIASSmartCard.mt:get_pin_puk_status()
    log.output("CosmoXIASSmartCard:get_pin_puk_status()")
    local pinRetry, pinRetryMax, pukRetry, pukRetryMax 


    local pinDOCP, pukDOCP = self:get_pin_puk_docp(true)

    
    pinRetry = pinDOCP and pinDOCP.tries or 3
    pinRetryMax = pinDOCP and pinDOCP.maxTries or 10
    
    pukRetry = pukDOCP and pukDOCP.tries or 3
    pukRetryMax = pukDOCP and pukDOCP.maxTries or 3
    
    log.output("CosmoXIASSmartCard:get_pin_puk_status():", pinRetry, pinRetryMax, pukRetry, pukRetryMax)
    return pinRetry, pinRetryMax, pukRetry, pukRetryMax
end


function CosmoXIASSmartCard.mt:valid()
    local status, err = self.card:status()
    if not status then
        log.output('CosmoXIASSmartCard:valid(): status() error', hex.tohex8(err or 0))
        return false
    elseif status.protocol == 0 or string.len(status.atr or '') == 0 then
        log.output('CosmoXIASSmartCard:valid(): card removed?')
        return false
    end
    return true
end

---------------------------------------------------
function CosmoXIASSmartCard.handle_error(err_obj)
    print(debug.traceback(err_obj))
    return err_obj
end

-- GET DATA SDO examples:
-- 00 cb 00 03 04: get data, card / os version on 4 bytes
-- 80 cb 00 11 00: get data, available eeprom size on 4 bytes (Big Endian?)
-- 00 cb 3f ff 0a 4d 08 70 06 bf 81 02 02 a0 80 00: get DOCP (tag A0) PIN #2 (PUK) User authentication: PIN / Password BF->'81'
-- 00 cb 3f ff 0a 4d 08 70 06 bf 81 01 02 a0 80 00: get DOCP (tag A0) PIN #1 (PIN) User authentication: PIN / Password BF->'81'
-- 00 cb 3f ff 0b 4D 09 70 07 BF A0 10 03 7F 49 80 00: get DOUP Asymmetric keys RSA #0x10 (BF-> 'A0' -> #0x10) 