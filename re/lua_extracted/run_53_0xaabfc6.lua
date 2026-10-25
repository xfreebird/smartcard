 valorizzato
    -- i PIN sono considerati uguali
    if not self.cfg["dspiniscnspin"] and not self.request_plugin_valid then
        log.output('Incard TS token initialize(): no plugin and dspiniscnspin unset: forcing dspiniscnspin=true')
        self.cfg["dspiniscnspin"] = 'true'
    end
    
    if self.cfg["dspinusegui"] then self.cfg["dspinusegui"]=string.lower(self.cfg["dspinusegui"])
    else self.cfg["dspinusegui"]='false' end
    
    if self.cfg["dspiniscnspin"] then self.cfg["dspiniscnspin"]=string.lower(self.cfg["dspiniscnspin"])
    else self.cfg["dspiniscnspin"]='true' end

    if self.cfg["hidecachedspincheck"] then self.cfg["hidecachedspincheck"]=string.lower(self.cfg["hidecachedspincheck"])
    else self.cfg["hidecachedspincheck"]='true' end
    
    if self.cfg["fcpr"] then
        self.cfg["fcpr"]=string.lower(self.cfg["fcpr"])
        self.use_cpr_mode = self.cfg["fcpr"] == "true"
    end
    
    if self.cfg["xproc"] then self.cfg["xproc"]=string.lower(self.cfg["xproc"])
    else self.cfg["xproc"]='true' end
    
    log.output('Incard TS token initialize(): use_cpr_mode:', self.use_cpr_mode)
    log.output('Incard TS token initialize(): mechanisms=', utility.repr(t.mechanisms))

    self.check_box_visible = 0
    if self.cfg["hidecachedspincheck"] == 'true' then
        self.check_box_visible = nil
    end
    self.default_container_data_obj = "CSPSmartLogon"
    self.mechanisms = utility.clone_table(t.mechanisms)
    
    if self.cfg["browsernotify"] then self.cfg["browsernotify"]=string.lower(self.cfg["browsernotify"])
    else self.cfg["browsernotify"]='false' end
    
    if not utility.check_browser_process() then
        self.cfg["browsernotify"]='false'
    end
    if self.cfg["browsernotify"] == 'true' then
        w32.notify_reader_attach()
    end
    
    if self.cfg["dsmode"] == "dsonly" then
        self.dsmode = "dsonly"
    elseif self.cfg["dsmode"] == "authonly" then
        self.dsmode = "authonly"
    end

    local pinpuklen = tonumber(self.cfg["ipinpuklen"] or self.cfg["pinpuklen"] or "")
    if pinpuklen and pinpuklen > 8 then
        log.output("token-ts:initialize(): pinpuklen:", pinpuklen)
        self.cns_hcard.PIN_PADDING = pinpuklen
        self.cns_hcard.PUK_PADDING = pinpuklen
    end
    
    local maxretrycountifshortkey1024 = tonumber(self.cfg["maxretrycountifshortkey1024"])
    if maxretrycountifshortkey1024 and maxretrycountifshortkey1024 > 0 then
       self.keygenmaxtryonlow1024 = maxretrycountifshortkey1024 +1
    end
    local maxretrycountifshortkey2048 = tonumber(self.cfg["maxretrycountifshortkey2048"])
    if maxretrycountifshortkey2048 and maxretrycountifshortkey2048 > 0 then
       self.keygenmaxtryonlow2048 = maxretrycountifshortkey2048 +1
    end
    
    local errorifshortkey = self.cfg["errorifshortkey"]
    if errorifshortkey then
       self.keygenerroronlow = (errorifshortkey == "true" or errorifshortkey == "yes")
    end
    
    log.output("token-ts:initialize(): keygenerroronlow:", self.keygenerroronlow)
    log.output("token-ts:initialize(): keygenmaxtryonlow1024:", self.keygenmaxtryonlow1024)
    log.output("token-ts:initialize(): keygenmaxtryonlow2048:", self.keygenmaxtryonlow2048)
    
    
    log.output("token-ts:initialize(): adding hcard:on_transmit()...")
    self.cns_hcard.on_transmit = function(self, apdu)
        if not self._jsign_applet_selected then
            log.output("checking CNS applet...")
            local recv = self.card:transmit(hexf('00ca01800a'))
            local sw = string.sub(recv, -2, -1)
            if sw ~= hexf('9000') then
                log.output("(re)selecting CNS (generic) applet...")
                
                local recv = self.card:transmit(hexf("00A4040009A00000009501004D00")) -- select CNS Jsign3 & "generic" applet
                if  recv and string.sub(recv, -2, -1) == hex.hexf("6a82") then
                    log.output("(re)selecting CNS (legacy) applet...")
                    self.card:transmit(hex.hexf("00A404000CA00000009501004D00000001")) -- select CNS Jsign1/2 applet
                end
                
            end
            self._jsign_applet_selected = true
        end
    end

    log.output("token-ts:initialize(): adding hcard:on_begin_transaction()...")
    self.cns_hcard.on_begin_transaction = function(self)
        self._jsign_applet_selected = false
    end

    if self._cache_id == nil then
        self:flush_cache()
    end
    
end

function t.mt:finalize()
    log.output("token-ts:finalize():", self.session, self.userType)
    utility.forget_token_changed(self, "cache")
    if self.cfg["browsernotify"] == 'true' then
        w32.notify_reader_detach()
    end
    
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
        self.cns_hcard:end_transaction()
    end
    local res = w32.show_message(msgid)
    self.hcard:status() -- in caso di reset effettua una reconnect
    if transactionDisabled then
        self.hcard:begintransaction()
    else
        self.cns_hcard:begin_transaction()
    end
    self.hcard:disabletransactions(transactionDisabled)
    return res
end

function t.mt:gui_change_pin_ds(ispuk)
    local transactionDisabled = self.hcard:transactionsdisabled()
    self.hcard:disabletransactions(false)
    if transactionDisabled then
        self.hcard:endtransaction()
    else
        self.cns_hcard:end_transaction()
    end
    local res, pinDs, newpinDs = w32.change_pin_ds(ispuk)
    self.hcard:status() -- in caso di reset effettua una reconnect
    if transactionDisabled then
        self.hcard:begintransaction()
    else
        self.cns_hcard:begin_transaction()
    end
    self.hcard:disabletransactions(transactionDisabled)
    
    return res, pinDs, newpinDs
end

function t.mt:gui_unlock_pin_ds()
    local transactionDisabled = self.hcard:transactionsdisabled()
    self.hcard:disabletransactions(false)
    if transactionDisabled then
        self.hcard:endtransaction()
    else
        self.cns_hcard:end_transaction()
    end
    local res, pukDs, newpinDs = w32.unlock_pin_ds()
    self.hcard:status() -- in caso di reset effettua una reconnect
    if transactionDisabled then
        self.hcard:begintransaction()
    else
        self.cns_hcard:begin_transaction()
    end
    self.hcard:disabletransactions(transactionDisabled)
    return res, pukDs, newpinDs
end
                
function t.mt:gui_request_pin_ds()
    local transactionDisabled = self.hcard:transactionsdisabled()
    self.hcard:disabletransactions(false)
    if transactionDisabled then
        self.hcard:endtransaction()
    else
        self.cns_hcard:end_transaction()
    end
    local res, contextual_pin, cache_ds_pin = w32.request_pin_ds(self.check_box_visible)
    self.hcard:status() -- in caso di reset effettua una reconnect
    if transactionDisabled then
        self.hcard:begintransaction()
    else
        self.cns_hcard:begin_transaction()
    end
    self.hcard:disabletransactions(transactionDisabled)
    return res, contextual_pin, cache_ds_pin
end


function t.mt:begin_transaction()
    self.cns_hcard:begin_transaction()
end

function t.mt:end_transaction()
    self.cns_hcard:end_transaction()
end

function t.mt:add_info_p11()
    local path_root
    if self.cns_only or self.dsmode == "dsonly" then
        return
    end
    repeat
        local finfo
        log.output('add_info_p11(): probing Fullp11 fileSystem...')
        path_root = "2FFF"
        if not pcall(function() finfo = self.cns_hcard:select(hexf(path_root.. '0000'), true) end ) then
            log.output('token-cns:get_info(): probing 4FFF')
            path_root = "4FFF"
            if not pcall(function() finfo = self.cns_hcard:select(hexf(path_root.. '0000'), true) end ) then
                log.output('token-cns:get_info(): Fullp11 fileSystem not found...')
                break
            end
            if not finfo then
                finfo = {size=64}
            end
        end
        local pcRes, p11_info_str
        local obj_table = {}
        local bso_table = {}
        local bso2048_table = {}

        -- main file structure: 64 bytes
        -- version major: BYTE (index 1)
        -- version minor: BYTE (index 2)
        -- OAT: ULONG little endian bitmap, 4 BYTE (index 3)
        -- BAT: WORD little endian bitmap, 2 BYTE (index 7)
        -- BAT_DES: WORD little endian bitmap, 2 BYTE (index 9)
        -- BAT_2048: 1 BYTE bitmap (index 11)
        -- OAT2_1_3: ULONG little endian bitmap, bytes 1 to 3 (index 12)
        -- TOKENINFO: 49 BYTES (index 15)
            -- LABEL: 40 chars
            -- PIN LENS: 1 BYTE, nib1 minpinlen, nib2 maxpinlen. Ignore
            -- OBJ MAX COUNT: 1 BYTE. Ignore
            -- BSOs MAX COUNT: 2 BYTE. Ignore
            -- SECOND_DF_KEYS_FID: 2 BYTES. Ignore
            -- SECOND_DF_CERT_FID: 2 BYTES. Ignore
            -- TOKEN_FLAGS: 1 BYTE
                -- bit0: TokenNeedInit. Ignore
                -- bit1: PinNeedInit. Ignore
                -- bit2-3: RFU
                -- bit4: Supports2048BitKeys_32k. Ignore
                -- bit5: Supports2048BitKeys_64k
                -- bit6-7: RFU
        -- OAT2_4: ULONG little endian bitmap, byte 4 (index 64)
        -- OPTIONAL:
            -- 32 bytes: manufacturerID (index 65)
            -- 16 bytes: model (index 98)

        pcRes, p11_info_str = pcall(function() return self.cns_hcard:read_binary(0,finfo.size) end )
        if not pcRes or string.len(p11_info_str) < 64 then
            log.output('token-cns:get_info(): FullP11 main file, read_binary error...')
            break
        end
        local p11_info = {}
        p11_info.path_root = path_root
        p11_info.version_major = string.byte(p11_info_str, 1)
        p11_info.version_minor = string.byte(p11_info_str, 2)
        p11_info.oat_t = bin.flags(bin.unpack('%<%L', string.sub(p11_info_str, 3, 6)) )
        p11_info.bat_t = bin.flags(bin.unpack('%<%H', string.sub(p11_info_str, 7, 8)) )
        p11_info.fs_flags_f = bin.flags(string.byte(p11_info_str, 63))
        local bat2048 = string.byte(p11_info_str, 11)
        p11_info.bat2048_t = bin.flags(bat2048)
        p11_info.oat2_t = bin.flags(bin.unpack('%<%L', string.sub(p11_info_str, 12, 14) .. string.sub(p11_info_str, 64) ) )
        p11_info.label = string.sub(p11_info_str, 15, 15+32)
        
        if string.len(p11_info_str) > 64 then
            p11_info.manufacturerID = string.sub(p11_info_str, 65, 65+31)
            p11_info.model = string.sub(p11_info_str, 97, 97+15)
            while string.byte(p11_info.manufacturerID, -1) == 0 do
                p11_info.manufacturerID = string.sub(p11_info.manufacturerID, 1, -2)
            end
            while string.byte(p11_info.model, -1) == 0 do
                p11_info.model = string.sub(p11_info.model, 1, -2)
            end
        end
        
        
        while string.byte(p11_info.label, -1) == 0 do
            p11_info.label = string.sub(p11_info.label, 1, -2)
        end

        log.output(string.format('token-cns:add_info_p11(): oat_t: 0x%x', p11_info.oat_t.asnumber))
        log.output(string.format('token-cns:add_info_p11(): bat_t: 0x%x', p11_info.bat_t.asnumber))
        log.output(string.format('token-cns:add_info_p11(): oat2_t: 0x%x', p11_info.oat2_t.asnumber))
        log.output(string.format('token-cns:add_info_p11(): bat2048_t: 0x%x', p11_info.bat2048_t.asnumber))
        log.output(string.format('token-cns:add_info_p11(): fs_flags_f: 0x%x', p11_info.fs_flags_f.asnumber))
        log.output(string.format('token-cns:add_info_p11(): label: "%s"', p11_info.label))
        
        p11_info.TokenNeedInit = p11_info.fs_flags_f[bin.flags(2^0)]
        p11_info.PinNeedInit = p11_info.fs_flags_f[bin.flags(2^1)]
        p11_info.support2048old = p11_info.fs_flags_f[bin.flags(2^4)]
        
        log.output(string.format('token-cns:add_info_p11(): TokenNeedInit:%s, PinNeedInit:%s, support2048old:%s',
            tostring(p11_info.TokenNeedInitialization),
            tostring(p11_info.UserPinNeedInitialization),
            tostring(p11_info.support2048old)))
        
        for i=0,31 do
            obj_table[i] = p11_info.oat_t[bin.flags(2^i)]
        end
        local k
        for i=32,63 do
            k = i-32
            obj_table[i] = p11_info.oat2_t[bin.flags(2^k)]
        end
        for i=0,15 do
            bso_table[i] = p11_info.bat_t[bin.flags(2^i)]
        end
        for i=0,7 do
            bso2048_table[i] = p11_info.bat2048_t[bin.flags(2^i)]
        end
        
        p11_info.obj_table = obj_table
        p11_info.bso_table = bso_table
        p11_info.bso2048_table = bso2048_table
        self.p11_info = p11_info
        break
    until true
end

function t.mt:add_info_ds()
    if self.cns_only or self.dsmode == "authonly" then
        return
    end
    local changepin_explicit_test = false
    repeat
        local custom_sm_enc, custom_sm_sig, caller_filename
        log.output('add_info_ds(): probing DS fileSystem...')
        local ds_info_str, path_root, pcRes = '', nil, false
        local ds_index
        -- NOTA: pcall non puo essere chiamato passando un metodo (si dovrebbe usare senza i ':' e passando esplicitamente l'oggetto come primo parametro)
        if pcall(function() return self.cns_hcard:select(hexf('3F0014008100')) end ) then
            path_root = '3F001400'
            ds_index="8100"
        elseif pcall(function() return self.cns_hcard:select(hexf('3F008100')) end ) then
            log.output('token-cns:get_info(): DS app on ROOT. Forcing explicit test on change_pin')
            path_root = '3F00'
            ds_index="8100"
            changepin_explicit_test = true
        elseif pcall(function() return self.cns_hcard:select(hexf('3F007F00')) end ) then
            log.output('token-cns:get_info(): 7F00 DS app on ROOT. Forcing explicit test on change_pin')
            path_root = '3F00'
            ds_index="7F00"
            changepin_explicit_test = true
        end
        if path_root == nil then
            -- l'applicazione DS non esiste
            log.output('token-cns:get_info(): NO DS app found!')
            break
        end
        
        log.output('add_info_ds(): DS root is:', path_root)
        
        pcRes, ds_info_str = pcall(function() return self.cns_hcard:read_binary(0,32) end )
        if not pcRes then
            log.output('add_info_ds(): ds main file, read_binary error...')
            break
        end
        if string.len(ds_info_str) < 12 then
            log.output('add_info_ds(): ds main file len invalid:', string.len(ds_info_str))
            break
        end
        
        local pcRes, ext_ds_info_str = pcall(function() return self.cns_hcard:read_binary(32,128) end )
        if pcRes and type(ext_ds_info_str) == "string" and string.len(ext_ds_info_str) == 128 then
            log.output('add_info_ds(): decrypting ext_ds_info_str...')
            local m="D3E5231A0DC2CB8EEBA85C83B201A37C6F7728B0" .. "994E2FB9364ECA94BB1FF5B479ACFEB17C3F4720302CB1BEF3E39663" .. "1CF9FAE68C9CE11A2B001FF789995526200C8010BAF40845AB13AE48EBC9B3C1597ED9C1EC6989F3DB5205E4F72CBF54EF351F263DA366B1CE0B633629BD234EA27B0B3B2E19058960ABC2A96E193C95"
            -- local e="010001"
            local d="73FDD388388E3065CD047D982DC20DDF" .. "59190E721589A2402DC555C9B2E15CDB" .. "ED5B509491A205EA4DD4B97C00FFCD5B" .. "F609B559AD11577BBE9C33E38A3420" .. "525E3F71351A20BB".."B5363FC4FB96ED421EF".."55B89739157F7845B2501A9F78D1CA4D57210D3A50".."6510F15D6455D6ECE62F8052CD0C0FAD4B7F5C5780DA69DA94BE5"
            local result = rsa.decrypt(ext_ds_info_str, m, d)
            log.output('add_info_ds(): decrypted ext_ds_info_str:', hex.hexify(result))
            custom_sm_enc = string.sub(result, 1, 24)
            custom_sm_sig = string.sub(result, 25, 48)
            log.output('custom SM keys:')
            log.output('enc key:', hex.hexify(custom_sm_enc), ', sig key:', hex.hexify(custom_sm_sig)) 
            caller_filename = string.sub(result, 49, -1)
            if type(caller_filename) == "string" and string.len(caller_filename) > 0 then
                if not utility.check_caller(caller_filename) then
                    error("add_info_ds(): invalid caller detected")
                end
            end
        end

        -- V 2.0 DS main file contents, 32 bytes: 20 03 33 0000000000000000000000000000000000000000000000000000000000
        -- 20 : ver, major.minor: 2.0
        -- 03 : flags: bit_0=use_sm, bit_1=alw_verify_pin
        -- 33: major is #of 1024 objects, minor is #of 2048 objects
        -- 27 bytes of data: up to 9 slot statuses. each 3 bytes group have following meaning:
            -- byte_0 = private key
            -- byte_1 = public key
            -- byte_2 = certificate key
            -- values: 0=empty, 1=in use; any other value means "object not usable"
        -- 2 bytes of data: RFU
        
        self.ds_info = {}
        self.ds_info.ds_version = string.byte(ds_info_str, 1)
        self.ds_info.ds_status1 = bin.flags(string.byte(ds_info_str, 2))
        self.ds_info.ds_status2 = bin.flags(string.byte(ds_info_str, 3))
        self.ds_info.ds_objects = {}
        self.ds_info.ds_objects.o1024 = {}
        self.ds_info.ds_objects.o2048 = {}
        local objects1024 = 0
        local objects2048 = 0
        
        if (self.ds_info.ds_version >= DS_FS_VERSION_2_0 ) then
            objects1024 = ((self.ds_info.ds_status2 * bin.flags(tonumber('f0', 16) )).asnumber / 16)
            objects2048 = (self.ds_info.ds_status2 * bin.flags(tonumber('0f', 16) )).asnumber
        else
            objects1024 = 3
        end
        if string.len(ds_info_str) < (1+objects1024+objects2048)*3 then
            self.ds_info = nil
            log.output('add_info_ds(): ds main file len invalid:', string.len(ds_info_str))
            break
        end
        for i=0,objects1024-1 do
            local cur_index = 4 + i*3
            local objStatus = { bin.unpack('%B%B%B', string.sub(ds_info_str, cur_index, cur_index +3)) }
            table.insert(self.ds_info.ds_objects.o1024, objStatus)
        end
        for i=objects1024,objects1024+objects2048-1 do
            local cur_index = 4 + i*3
            local objStatus = { bin.unpack('%B%B%B', string.sub(ds_info_str, cur_index, cur_index +3)) }
            table.insert(self.ds_info.ds_objects.o2048, objStatus)
        end        
        self.ds_info.ds_objects.DS_MAX_INDEX = objects1024 + objects2048 -1
        
        self.ds_info.use_sm = self.ds_info.ds_status1[bin.flags(1)]
        self.ds_info.alw_verify_pin = self.ds_info.ds_status1[bin.flags(2)]
        
        self.ds_info.pin_pad_no_sm_on_pin = self.ds_info.ds_status1[bin.flags(2^7)]
        
        log.output(string.format(
            'add_info_ds(): use_sm:%s, alw_verify_pin:%s, pin_pad_no_sm_on_pin:%s, ', 
            tostring(self.ds_info.use_sm), 
            tostring(self.ds_info.alw_verify_pin), 
            tostring(self.ds_info.pin_pad_no_sm_on_pin)
            ))
        
        self.ds_info.path_root = path_root
        self.ds_info.ds_index = ds_index
        self.ds_info.ds_sig_path = path_root .. "8110"
        if self.ds_info.use_sm then 
            self.ds_info.sm_enc = custom_sm_enc or sm.sm_ask_keys(0)
            self.ds_info.sm_sig = custom_sm_sig or sm.sm_ask_keys(1)
            log.output('using sm keys:')
            log.output('ENC key:', hex.hexify(self.ds_info.sm_enc), ', SIG key:', hex.hexify(self.ds_info.sm_sig)) 
        end
        self.ds_info.pin_initialized = true
        self.ds_info.changepin_explicit_test = changepin_explicit_test
        self.info.ulMaxPinLen = self.cns_hcard.PUK_PADDING or 8
        self.info.ulMinPinLen = 4
        pcall( function()
            local sm_enc, sm_sig = self.ds_info.sm_enc, self.ds_info.sm_sig
            if self.ds_info.pin_pad_no_sm_on_pin then
                sm_enc, sm_sig = nil, nil
            end
            log.output('add_info_ds(): checking DS PIN initialization state...')
            self.cns_hcard:select(hex.hexf(self.ds_info.ds_sig_path))
            local recv = self.cns_hcard:sm_transmit(hexf('0020009a00'), sm_enc, sm_sig)
            local swf = bin.flags(bin.unpack("%H", recv))
            if recv ~= hexf('9000')
               and (swf * bin.flags('0xFFF0')) ~= bin.flags('0x63c0') then
                self.ds_info.pin_initialized = false
                log.output('add_info_ds(): DS PIN is NOT initialized')
            end
        end)
        if not pcall(function() return self.cns_hcard:select(hexf(self.ds_info.ds_sig_path .. '811f')) end ) then
            log.output('add_info_ds(): DS TMP sign file not found: found a jsign!')
            self.jsign_2048 = true
        end
        break
    until true
end

function t.mt:_update_retry_counters()

    if self.check_pin_status then
        log.output("get_pin_puk_status...");
        if (self.info) then
            pcall (function()
                self.info.flags = self.info.flags - CKF.USER_PIN_LOCKED
                self.info.flags = self.info.flags - CKF.USER_PIN_FINAL_TRY
                self.info.flags = self.info.flags - CKF.USER_PIN_COUNT_LOW
                self.info.flags = self.info.flags - CKF.SO_PIN_LOCKED
                self.info.flags = self.info.flags - CKF.SO_PIN_FINAL_TRY
                self.info.flags = self.info.flags - CKF.SO_PIN_COUNT_LOW
                local pinRetry, pinRetryMax, pukRetry, pukRetryMax = self.cns_hcard:get_pin_puk_status()
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
        end
    end
end


function t.mt:add_info_cns()
    log.output('add_info_cns(): probing CNS fileSystem!!!...')
    if not pcall(function() return self.cns_hcard:select(hexf('3F0010001003')) end ) then
        log.output('add_info_cns(): CNS Serial Number file not found...')
    else
        self.info.serialNumber = self.cns_hcard:read_binary(0,16)
        if string.len(self.info.serialNumber) ~= 16 then
            self.info.serialNumber = string.sub(self.info.serialNumber, 1, 16)
            self.info.serialNumber = string.rep("0", 16 - string.len(self.info.serialNumber)) .. self.info.serialNumber
        end
    end 
    local hpc_prefix = '3F001700';
    local cns_key_prefix = '3F00'
    self.cns_info = {
        cert_valid      = false,
        key_valid       = false,
        cns_key_prefix = cns_key_prefix,
        cns_fs_valid=(self.info.serialNumber~=nil),
    }
    pcall (function()
        log.output('add_info_cns(): probing HPC FS...')
        self.cns_hcard:select(hexf(hpc_prefix))
        cns_key_prefix = hpc_prefix
        self.info.label = "CNS-HPC"
    end)
    pcall (function()
        self.cns_hcard:select(hexf(objCnsTmpl.GetCNSCertTemplate().path))
        local certVal = self.cns_hcard:read_binary(0, 1)
        self.cns_info.cert_valid = (string.byte(certVal, 1) == 48) -- hex 30
    end)
    pcall (function()
        self.cns_hcard:select(hexf(objCnsTmpl.GetCNSPDATATemplate().path))
        local dataVal = self.cns_hcard:read_binary(0, 1)
        local dataValB = string.byte(dataVal, 1)
        self.cns_info.pdata_valid = (dataValB ~= 255 and dataValB ~= 0)
    end)
    log.output('add_info_cns(): certificate valid:', self.cns_info.cert_valid)
    pcall (function()
        self.cns_hcard:select(hexf(cns_key_prefix .. objCnsTmpl.GetCNSPubKeyTemplate().path))
        local pubKeyVal = self.cns_hcard:read_record(1, 4, 3)
        self.cns_info.key_valid = ( 
                        (string.byte(pubKeyVal, 1) == 16 or string.byte(pubKeyVal, 1) == 17) -- hex 10, 11
                        and string.byte(pubKeyVal, 3) ~= 255 -- hex FF
                        )
    end)
    self.cns_info.cns_key_prefix = cns_key_prefix;
    log.output('add_info_cns(): key valid:', self.cns_info.key_valid)
end

function t.mt:get_info()
    if not self.info then
        self.info = {
            label = 'CNS',
            manufacturerID = 'Bit4id',
            model = '',
            serialNumber = nil,
            flags = CKF.RNG + CKF.LOGIN_REQUIRED + CKF.TOKEN_INITIALIZED,
            ulMaxSessionCount = CK.EFFECTIVELY_INFINITE,
            ulSessionCount = 0,
            ulMaxRwSessionCount = CK.EFFECTIVELY_INFINITE,
            ulRwSessionCount = CK.UNAVAILABLE_INFORMATION,
            ulMaxPinLen = self.cns_hcard.PUK_PADDING or 8,
            ulMinPinLen = 4,
            ulTotalPublicMemory = 80000,
            ulFreePublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulTotalPrivateMemory = 80000,
            ulFreePrivateMemory = CK.UNAVAILABLE_INFORMATION,
            hardwareVersion = { major=0, minor=0},
            firmwareVersion = { major=0, minor=0},
            utcTime = '0000000000000000'
        }
        
        self:add_info_cns()
        self:add_info_ds()
        self:add_info_p11()
        
        if self.p11_info and type(self.p11_info.label) == "string" and string.len(self.p11_info.label) > 0 then
            self.info.label = self.p11_info.label
        end
        if self.dsmode == "dsonly" then
            self.info.flags = self.info.flags - CKF.LOGIN_REQUIRED
        end
        
        local getCTrcbl -- get card traceability result
        local recv = self.cns_hcard:transmit(hexf('B0FD000051'))
        local sw = string.sub(recv, -2, -1)
        if sw == hexf('9000') then
            -- self.info.manufacturerID = 'ST Incard'
            self.cns_hcard.is_incard = true
            self.check_pin_status = self.cns_hcard.is_incard and not self.cns_only
            getCTrcbl = recv
            
            recv = self.cns_hcard:transmit(hexf('00ca01800a'))
            sw = string.sub(recv, -2, -1)
            if sw == hexf('9000') and (string.sub(recv, 1, 5) == "JSign" or string.sub(recv, 1, 6) == "J-Sign") then
                log.output('get_info(): GET DATA: found  J-Sign product')
                self.jsign_2048 = true
                self.jsign3 = string.sub(recv, 1, 6) == "JSign3"
                self.jsign4 =  string.sub(recv, 1, 6) == "JSign4"
                self.jsign3plus = self.jsign3 or self.jsign4
            end
        end

        
        if not self.jsign_2048 then
            log.output('get_info(): disabling CNS applet selection for non JSign cards...')
            self.cns_hcard.on_transmit = nil
            self.cns_hcard.on_begin_transaction = nil
        end
        
        if self.p11_info and self.p11_info.version_major < 2 and self.jsign_2048 then
            self.p11_info.version_major = 2
        end
        
        log.output('get_info(): self.cns_hcard.is_incard:', self.cns_hcard.is_incard)
        log.output('get_info(): self.cns_only:',self.cns_only)
        log.output('get_info(): self.check_pin_status:', self.check_pin_status)
        log.output('get_info(): self.jsign_2048:', self.jsign_2048)
        log.output('get_info(): self.jsign3:', self.jsign3)
        log.output('get_info(): self.jsign4:', self.jsign4)
        if self.p11_info then
            log.output('get_info(): self.p11_info.version_major:', self.p11_info.version_major)
            log.output('get_info(): self.p11_info.version_minor:', self.p11_info.version_minor)
        end
        
        local qResult = self.cns_hcard:transmit(hexf('00CA01800A'))
        local sw = string.sub(qResult, -2, -1)
        self.support2048new = (sw == hexf('9000') and self.cns_hcard.is_incard) -- hex.hexf("496E5472") == string.sub(qResult, 1, 4) )
        log.output(string.format('get_info(): support2048new:%s...', tostring(self.support2048new) ))
        if self.support2048new then
            local prefix = "DS"
            if self.jsign_2048 then
                prefix = "JS"
            end
            if self.ds_info and self.ds_info.ds_objects then
                if table.getn(self.ds_info.ds_objects.o2048) > 0 then
                    self.info.model = prefix .. "2048"
                else
                    self.info.model = prefix .. "1024"
                end
            else
                self.info.model = prefix
            end
            
            self.info.ulTotalPublicMemory = 65536
            self.info.ulTotalPrivateMemory = 32768
            for i, v in self.mechanisms do
                v.ulMaxKeySize = 2048
            end
        end
        
        if (not self.cns_info or not self.cns_info.cns_fs_valid) 
           and not self.ds_info
           and self.p11_info then
            log.output('get_info(): full p11 FS type')
        elseif (not self.cns_info or not self.cns_info.cns_fs_valid) 
           and self.ds_info
           then
            log.output('get_info(): DS FS type')
        else
            log.output('get_info(): fs status', self.cns_info, self.cns_info.cns_fs_valid, self.ds_info, self.p11_info)
        end

        if not self.info.serialNumber and not self.cns_only
            and pcall(function() return self.cns_hcard:select(hexf('3F002f02')) end ) then
            log.output('get_info(): trying GDO serial Number...')
            pcall(function()self.info.serialNumber = hex.hexify(self.cns_hcard:read_binary(18, 8)) end )
        end
        self.info.serialNumber = self.info.serialNumber or '0000000000000000'
        
        -- getCTrcbl: byte 8 e 9 codificano anno mese e giorno di produzione. esempio: a4a4 -> 1010 0100 1010 0100
        -- anno di produzione 5 bit: 1010 0 -> 20 -> ovvero 20 +1990 = 2010
        -- mese 4 bit: 1001 -> 9, Settembre
        -- giorno di produzione 5 bit: 01001 -> 9
        local ProductionYear=2011
        local ProductionMonth=5  -- data oltre la quale non sono pi