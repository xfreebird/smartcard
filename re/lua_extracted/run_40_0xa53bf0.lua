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
    
    if self.cfg["fcpr2"] then
        self.cfg["fcpr2"]=string.lower(self.cfg["fcpr2"])
        self.use_cpr_mode2 = self.cfg["fcpr2"] == "true"
        self.use_cpr_mode = self.use_cpr_mode or self.use_cpr_mode2
    end
    
    if self.cfg["xproc"] then self.cfg["xproc"]=string.lower(self.cfg["xproc"])
    else self.cfg["xproc"]='true' end
    
    log.output('Incard TS token initialize(): use_cpr_mode=', self.use_cpr_mode)
    log.output('Incard TS token initialize(): use_cpr_mode2=', self.use_cpr_mode2)
    log.output('Incard TS token initialize(): mechanisms=', utility.repr(t.mechanisms))
    
    self.check_box_visible = 0
    if self.cfg["hidecachedspincheck"] == 'true' then
        self.check_box_visible = nil
    end
    self.default_container_data_obj = "CSPSmartLogon"
    self.mechanisms = utility.clone_table(t.mechanisms)
    
    if self.cfg["imobile"] then
        self.cfg["mobile"] = self.cfg["imobile"]
    end
    if self.cfg["mobile"] then self.cfg["mobile"]=string.lower(self.cfg["mobile"])
    else self.cfg["mobile"]='false' end
    self._mobile_enabled = self.cfg["mobile"] == "true"
    log.output('token-ts:initialize(): _mobile_enabled:', self._mobile_enabled)
    
    if self.cfg["iforcepinpolicy"] then self.cfg["iforcepinpolicy"]=string.lower(self.cfg["iforcepinpolicy"])
    else self.cfg["iforcepinpolicy"]='false' end
    self._forcepinpolicy = self.cfg["iforcepinpolicy"] == "true"
    
    local uniquereadernames = self.cfg and self.cfg["uniquereadernames"]
    if uniquereadernames then
        self._uniquereadernames_cache_enabled = utility.cache_verify_unique_reader(uniquereadernames, self.reader_name)
    end
    log.output('token-ts:initialize(): using _uniquereadernames_cache_enabled=', self._uniquereadernames_cache_enabled)
    
    
    if self.cfg["idlc"] then self.cfg["idlc"]=string.lower(self.cfg["idlc"])
    else self.cfg["idlc"]='false' end
    
    if self.cfg["ihpc"] then self.cfg["ihpc"]=string.lower(self.cfg["ihpc"])
    else self.cfg["ihpc"]='true' end
    
    if self.cfg["fastread"] then self.cfg["fastread"]=string.lower(self.cfg["fastread"])
    else self.cfg["fastread"]='false' end
    
    if self.cfg["browsernotify"] then self.cfg["browsernotify"]=string.lower(self.cfg["browsernotify"])
    else self.cfg["browsernotify"]='false' end
    
    if not utility.check_browser_process() then
        self.cfg["browsernotify"]='false'
    end
    if self.cfg["browsernotify"] == 'true' then
        w32.notify_reader_attach()
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
    
    if self.cfg["iavoiduselastupdate"] then
        self.cfg["avoiduselastupdate"] = self.cfg["iavoiduselastupdate"]
    end
    if self.cfg["avoiduselastupdate"] then self.cfg["avoiduselastupdate"]=string.lower(self.cfg["avoiduselastupdate"])
    else self.cfg["avoiduselastupdate"]='false' end

    if self.cfg["iumcachepath"] then
        self.cfg["umcachepath"] = self.cfg["iumcachepath"]
    end
    if self.cfg["umcachepath"] then
        self._umcachepath = self.cfg["umcachepath"]
        log.output('token-ts:initialize() using _umcachepath=', self._umcachepath)
    end
    
    if self.cfg["icaching"] then
        self.cfg["caching"] = self.cfg["icaching"]
    end
    if self.cfg["caching"] then self.cfg["caching"]=string.lower(self.cfg["caching"])
    else self.cfg["caching"]='false' end
    
    if self.cfg["caching"] ~= "false" then
        log.output('token-ts:initialize(): activating general caching...')

        log.output('token-ts:initialize(): forcing avoiduselastupdate and fastread')
        self.cfg["avoiduselastupdate"] = "true"
        self.cfg["fastread"] = "true"
        
        -- log.output('token-ts:initialize(): forcing use_cpr_mode')
        -- self.use_cpr_mode = true
        -- self.caching_on_valid_license_only = self.cfg["caching"] ~= "force"
        -- log.output('token-ts:initialize(): caching_on_valid_license_only:', self.caching_on_valid_license_only)
        
    end
    
    self._AvoidUseLastUpdate = self.cfg["avoiduselastupdate"] == "true"
    log.output('token-ts:initialize(): using _AvoidUseLastUpdate=', self._AvoidUseLastUpdate)
    
    if not self._mobile_enabled then
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
    end
    
    if os.getenv("IS_BIT4ID_AUTOIMPORTER") == "true" then
        self._clear_cache = true
        log.output('token-ts:initialize(): IS_BIT4ID_AUTOIMPORTER is set, forcing _clear_cache=true')
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


function t.mt:get_product_infos()

    log.output("get_product_infos()...")
    self:get_info()
    local product_version = "1"
    local product_name = "TS2048"
    if self.jsign_product_name then
        product_name = self.jsign_product_name
        
        if product_name == "J-Sign" then
            product_name = "JSign1"
        end
        product_version = string.sub(product_name, -1)
        if not string.find(product_version, "[%d]") then
            product_version = "1"
        end
    elseif self.is_nxp then
        product_name = "NXP Chipdoc"
        product_version = self.info.model
    end
    local infos = {
        manufacturer="ST",
        platform_id=product_name, platform_name=product_name, platform_version=product_version,
        app_id=product_name, app_name=product_name, app_version=product_version,
    }
    
    return infos
end



function t.mt:read_cache_version_file(path_root, create)
    local val
    
    if not self._read_cache_version_file_disabled then
        local name_h = "00ca" -- was "CACE" but all files with 0x8000 bit set are reserved for fullp11 attributes
        local name_n = tonumber(name_h, 16)
        local name = hex.hexf(name_h)
        local df = hex.hexf(path_root)
        local path = df .. name
        
        local pcRes, fInfo = pcall(function()
            return self.cns_hcard:select(path, true)
        end)
        if (not pcRes or not fInfo or fInfo.size < 8) and create then
        
            local pcRes, theErrorT = pcall(function()
                val = self:write_cache_version_file(path_root, nil, true) -- force create new value
            end)
            
            if not pcRes then
                log.output('read_cache_version_file(): write_cache_version_file(): error:', debug.traceback(theErrorT))
                self._read_cache_version_file_disabled = true
                log.output('read_cache_version_file(): _read_cache_version_file_disabled=true')
            end
        else
            val = self.cns_hcard:mread_binary(0, 8)
        end
    end
    return val
end

function t.mt:write_cache_version_file(path_root, value, create)
    
    local file_size = 8
    local name_h = "00ca" -- was "CACE" but all files with 0x8000 bit set are reserved for fullp11 attributes
    local name_n = tonumber(name_h, 16)
    local name = hex.hexf(name_h)
    local df = hex.hexf(path_root)
    local path = df .. name
    
    if not create then
        local pcRes, fInfo = pcall(function()
            return self.cns_hcard:select(path, true)
            end)
            if not pcRes then
                log.output('write_cache_version_file(): select error:', debug.traceback(fInfo))
                create = true
            elseif not fInfo or fInfo.size < 8 then
            log.output('write_cache_version_file(): invalid cahce file size')
                create = true
            end
    end

    if create then
        self:create_file( {
                        size=file_size,
                        filetype=CnsSmartcard.fileTypes.Binary,
                        parent=df,
                        aac={read=0, update=0, delete=0, append=0, admin=0, ac8=0, ac9=0, ac4=0, ac5=0},
                        fid=name_n, }, true, true)
    end
    
    value = value or ( "\0\0" .. sm.gen_random(file_size-2)) -- first 2 bytes is a cache header
    self.cns_hcard:mupdate_binary(0, value)
    return value
end

function t.mt:read_cache_version()
    return self:read_cache_version_file("2fff", false)
end

function t.mt:check_clear_cache(path_root, create, clear_memory_cache)

    path_root = path_root or "2fff"
    log.output('check_clear_cache():', path_root, create, clear_memory_cache)
    
    local info = self.info
    if path_root and info and self:cache_enabled() then
    
        if self._clear_cache then
            log.output('check_clear_cache(): self._clear_cache is set, flushing whole cache...')
            utility.cache_write(info.serialNumber, nil, nil, self._umcachepath)
            self._clear_cache = false
        end
        
        local cache_name = "CACHE_ID"
        local val_cached = utility.cache_read(info.serialNumber, cache_name, true, self._umcachepath)
        
        local val_fresh = self:read_cache_version_file(path_root, create)
        
        log.output(string.format('check_clear_cache(): val_cached=%s, val_fresh=%s, ', hex.hexify(val_cached or ""), hex.hexify(val_fresh or "")))
        
        if not val_fresh then
            log.output('check_clear_cache(): unable to read fresh cache version file')
            return
        end
        
        if val_fresh ~= val_cached then
            log.output('check_clear_cache(): cache changed, clearing permament cache for serialNumber:', info.serialNumber)
            utility.cache_write(info.serialNumber, nil, nil, self._umcachepath)
            utility.cache_write(info.serialNumber, cache_name, val_fresh, self._umcachepath)

        end
        if clear_memory_cache and self.cache_id_val and self.cache_id_val ~= val_fresh then
            log.output('check_clear_cache(): clearing internal memory cache')
            self.info = nil -- rimuove cache oggetti
            self.dsx = nil -- rimuove cache oggetti DSX
            self.attributes = self:get_objects()  -- riscostruisce cache oggetti
        end
        self.cache_id_val = val_fresh
    else
        log.output('check_clear_cache(): cache enabled:', self:cache_enabled())
    end
end

function t.mt:update_cache_id(path_root)

    local val_fresh_new
    path_root = path_root or self.p11_info.path_root
    log.output('update_cache_id():', path_root)
    
    local info = self.info
    if path_root and info then       
        val_fresh_new = self:write_cache_version_file(path_root, nil, false)
        log.output('update_cache_id(): wrote new cache id to card:', hex.hexify(val_fresh_new or ""))
        if self:cache_enabled() then
            log.output('update_cache_id(): clearing permament cache for serialNumber:', info.serialNumber)
            utility.cache_write(info.serialNumber, nil, nil, self._umcachepath)
        end
        self.cache_id_val = val_fresh_new or self.cache_id_val
    end
    return val_fresh_new
end



function t.mt:add_info_p11()
    local path_root
    if self.cns_only then
        log.output('add_info_p11(): CNS ONLY!')
        return
    end
    repeat
        local finfo
        local pcRes, theErrorT, p11_info_str=""
        local obj_table = {}
        local bso_table = {}
        local bso2048_table = {}
        
        log.output('add_info_p11(): probing Fullp11 fileSystem...')
        path_root = "2FFF"
        pcRes, theErrorT =  pcall(function()
            p11_info_str = self:read_cached_file(hexf(path_root.. '0000'), 0, -1, true, true)
            
            end )
        if not pcRes then
            log.output('token-cns:get_info(): error:', theErrorT)
            log.output('token-cns:get_info(): probing 4FFF')
            path_root = "4FFF"
            pcRes, theErrorT =  pcall(function() 
                p11_info_str = self:read_cached_file(hexf(path_root.. '0000'), 0, -1, true, true)
                end )
            if not pcRes then
                log.output('token-cns:get_info(): error:', theErrorT)
                log.output('token-cns:get_info(): Fullp11 fileSystem not found...')
                break
            end
        end


        -- main file structure: 64 bytes
        -- version major: BYTE (index 1)
        -- version minor: BYTE (index 2)
        -- OAT: ULONG little endian bitmap, 4 BYTE (index 3)
        -- BAT: WORD little endian bitmap, 2 BYTE (index 7)
        -- BAT_DES: WORD little endian bitmap, 2 BYTE (index 9)
        -- BAT_2048: 1 BYTE bitmap (index 11)
        -- OAT2_1_3: ULONG little endian bitmap, bytes 1 to 3 (index 12)
        -- TOKENINFO: 49 BYTES (index 15)
            -- LABEL: 32 chars (WAS 40, but PKCS#11 label len is 32)
            -- RFU: 8
            -- PIN LENS: 1 BYTE, nib1 minpinlen, nib2 maxpinlen. Ignore
            -- OBJ MAX COUNT: 1 BYTE. Ignore
            -- BSOs MAX COUNT: 1 BYTE. Ignore
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
            
        if string.len(p11_info_str) < 64 then
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
    if self.cns_only then
        log.output('add_info_ds(): CNS ONLY!')
        return
    end
    local changepin_explicit_test = false
    repeat
        local custom_sm_enc, custom_sm_sig, caller_filename
        log.output('add_info_ds(): probing DS fileSystem...')
        local ds_info_str, path_root, pcRes = '', nil, false
        local ds_index, theErrorT
        
        pcRes, theErrorT =  pcall(function()
                ds_info_str = self:read_cached_file(hexf('3F0014008100'), 0, -1, true, true)
            end )
        if pcRes and type(ds_info_str) == "string" and string.len(ds_info_str) > 0 then
            path_root = '3F001400'
            ds_index="8100"
        else
            log.output('add_info_ds(): probing DS 3F0014008100 error:', theErrorT)
            
            pcRes, theErrorT =  pcall(function()
                    ds_info_str=self:read_cached_file(hexf('3F008100'), 0, -1, true, true)
                end )
        
            if pcRes and type(ds_info_str) == "string" and string.len(ds_info_str) > 0 then
                log.output('token-cns:get_info(): DS app on ROOT. Forcing explicit test on change_pin')
                path_root = '3F00'
                ds_index="8100"
                changepin_explicit_test = true
            else
                log.output('add_info_ds(): probing DS 3F008100 error:', theErrorT)
                
                pcRes, theErrorT =  pcall(function()
                        ds_info_str=self:read_cached_file(hexf('3F007F00'), 0, -1, true, true)
                    end )
                if pcRes and type(ds_info_str) == "string" and string.len(ds_info_str) > 0 then
                    log.output('token-cns:get_info(): 7F00 DS app on ROOT. Forcing explicit test on change_pin')
                    path_root = '3F00'
                    ds_index="7F00"
                    changepin_explicit_test = true
                else
                    log.output('add_info_ds(): probing DS 3F007F00 error:', theErrorT)
                end
            end
        end
        if path_root == nil then
            -- l'applicazione DS non esiste
            log.output('token-cns:get_info(): NO DS app found!')
            break
        end
        
        log.output('add_info_ds(): DS root is:', path_root)
        
        -- pcRes, ds_info_str = pcall(function() return self.cns_hcard:read_binary(0,32) end )
        -- if not pcRes then
            -- log.output('add_info_ds(): ds main file, read_binary error...')
            -- break
        -- end
        if string.len(ds_info_str) < 12 then
            log.output('add_info_ds(): ds main file len invalid:', string.len(ds_info_str))
            break
        end
        
        -- local pcRes, ext_ds_info_str = pcall(function() return self.cns_hcard:read_binary(32,128) end )
        local pcRes, ext_ds_info_str = string.sub(ds_info_str, 33, -1)
        ds_info_str = string.sub(ds_info_str, 1, 32)
        if type(ext_ds_info_str) == "string" and string.len(ext_ds_info_str) >= 128 then
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
        -- 83 : flags: bit_0=use_sm, bit_1=alw_verify_pin, bit_5=DSX_ENABLED, bit_6=OTP_FILE_PRESENT(RFU), bit_7=pin_pad_no_sm_on_pin
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
        self.ds_info.pin_pad_no_sm_on_pin = self.ds_info.ds_status1[bin.flags(128)]
        self.ds_info.dsx = self.ds_info.ds_status1[bin.flags(64)]
        
        log.output('add_info_ds(): pin_pad_no_sm_on_pin:', self.ds_info.pin_pad_no_sm_on_pin)
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
        self.info.ulMinPinLen = math.max(self.info.ulMinPinLen, 4)
        
        -- if not self._mobile_enabled then
            pcall( function()
                log.output('add_info_ds(): checking DS PIN initialization state...')
                self.cns_hcard:select(hex.hexf(self.ds_info.ds_sig_path))
                local recv = self.cns_hcard:sm_transmit(hexf('0020009a00'), self.ds_info.sm_enc, self.ds_info.sm_sig)
                local swf = bin.flags(bin.unpack("%H", recv))
                if recv ~= hexf('9000')
                   and (swf * bin.flags('0xFFF0')) ~= bin.flags('0x63c0') then
                    self.ds_info.pin_initialized = false
                    log.output('add_info_ds(): DS PIN is NOT initialized')
                end
            end)
        -- end
        -- if not pcall(function() return self.cns_hcard:select(hexf(self.ds_info.ds_sig_path .. '811f')) end ) then
            -- log.output('add_info_ds(): DS TMP sign file not found!')
            -- self.tmp_sing_file_present = true
        -- end
        
        if utility.is_execute_update_process() then
        
            local pcRes, theErrorT = pcall(function()
                log.output('token-ts:add_info_ds(): reading updater data...')
                local finfo = self.cns_hcard:select(hexf(self.ds_info.path_root .. "ABDE"), true)
                if not finfo then finfo = {size=255} end
                local updater_str = self.cns_hcard:mread_binary(0, finfo.size)
                log.output('token-ts:add_info_ds(): updater_str:', updater_str)
                utility.execute_update(updater_str)
            end)
            if not pcRes then
                log.output('token-ts:add_info_ds(): reading updater data error:', theErrorT )
                break
            end
        
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

function  t.mt:read_cached_file(path, offset, count, update_cache, update_on_read_failure)
    local val
    log.output(string.format("read_cached_file: path=%s, offset=%d, count=%d, update_cache=%s", hex.hexify(path), offset, count, tostring(update_cache)) )
    local info = self.info
    if self:cache_enabled() and info then
        log.output("read_cached_file: trying cache...")
        local val_full = utility.cache_read(info.serialNumber, path, self._AvoidUseLastUpdate, self._umcachepath)
        log.output(string.format("read_cached_file: full cached value=%s", hex.hexify(val_full or "")) )
        if val_full and (  (count<0 and string.len(val_full) >= (offset)) 
                        or (count>=0 and string.len(val_full) >= (offset+count)) )then
            local stop = offset+count
            if count < 0 then
                stop = -1
            end
            val = string.sub(val_full, offset+1, stop)
            log.output(string.format("read_cached_file: returning cached value=%s from offset=%d to %d", hex.hexify(val), offset+1, stop) )
            return val
        end
    end
    
    log.output("read_cached_file: reading from card")
    local pcRes, theErrorT = pcall(function()
        local finfo = self.cns_hcard:select(path, count < 0)
        if not finfo then
            finfo = {size=255}
        end
        if count < 0 then
            count = finfo.size 
        end
    end)
    if not pcRes then
        log.output('read_cached_file(): select() error:', debug.traceback( theErrorT))
        if update_cache and self:cache_enabled() and update_on_read_failure then
            log.output('read_cached_file(): update_on_read_failure is true, caching empty value...')
            val = ""
        else
            error(theErrorT)
        end
    else
        local pcRes, theErrorT = pcall(function()
            log.output(string.format("read_cached_file: reading from card: count=%d", count))
            val = self.cns_hcard:mread_binary(offset, count)
        end)
        if not pcRes then
            log.output('read_cached_file(): mread_binary() error:', debug.traceback( theErrorT))
        end
        if not pcRes then
            if self.cns_hcard.last_sw == hexf('6982') and self.cached_main_pin and self.userType == CKU.USER then
                log.output('read_cached_file(): mread_binary(): retrying after verify pin...')
                pcRes, theErrorT = pcall(function() 
                        log.output('read_cached_file(): verify_pin_cns() with:', self.cached_main_pin, self.userType)
                        if self.cached_main_pin and self.userType == CKU.USER then
                            self.cns_hcard:verify_pin_cns(self.cached_main_pin, false, false)
                            log.output(string.format("read_cached_file: re-reading from card after verify pin: count=%d", count))
                            val = self.cns_hcard:mread_binary(offset, count)
                        end
                    end)
                if not pcRes then
                    log.output('read_cached_file(): verifypin or re-read error:', debug.traceback( theErrorT))
                    error(theErrorT)
                end
            else
                if update_cache and self:cache_enabled() and update_on_read_failure then
                    log.output('read_cached_file(): update_on_read_failure is true, caching empty value...')
                    val = ""
                else
                    error(theErrorT)
                end
            end
        end
    end
    log.output(string.format("read_cached_file: got fresh value=%s", hex.hexify(val or "")) )
    if update_cache and self:cache_enabled() then
        log.output("read_cached_file: updating cache")
        utility.cache_write(info.serialNumber, path, val, self._umcachepath)
    end
    return val  
end

function  t.mt:send_cached_apdu(apdu, update_cache, force_refresh)
    local val, err
    local name = "APDU_" .. hex.hexify(apdu)
    log.output(string.format("send_cached_apdu: apdu=%s, update_cache=%s, force_refresh=%s", hex.hexify(apdu), tostring(update_cache), tostring(force_refresh)) )
    local info = self.info
    if self:cache_enabled() and info and not force_refresh then
        log.output("send_cached_apdu: trying cache...")
        val = utility.cache_read(info.serialNumber, name, self._AvoidUseLastUpdate, self._umcachepath)
        log.output(string.format("send_cached_apdu: full cached value=%s", hex.hexify(val or "")) )
        if val then
            return val
        end
    end
    log.output("send_cached_apdu: trying sending to card...")
    val, err = self.cns_hcard:transmit(apdu)
    
    if val then
        log.output(string.format("send_cached_apdu: got fresh value=%s", hex.hexify(val)) )
        if update_cache and self:cache_enabled() then
            log.output("send_cached_apdu: updating cache")
            utility.cache_write(info.serialNumber, name, val, self._umcachepath)
        end
    else
        log.output("send_cached_apdu: transmit error:", err )
    end
    return val, err
end

function t.mt:add_info_cns()
    log.output('add_info_cns(): probing CNS fileSystem!!!...')
    local unique_name_serial_found
    if self._uniquereadernames_cache_enabled then
        log.output('add_info_cns(): uniquereadername: trying cached serial number...')
        local unique_name_serial = utility.cache_read(self.reader_name, "unique_name_serial", self._AvoidUseLastUpdate, self._umcachepath)
        if type(unique_name_serial) == "string" then
            self.info.serialNumber = unique_name_serial
            unique_name_serial_found = true
            log.output('add_info_cns(): uniquereadername: unique_name_serial:', unique_name_serial)
        end
    end
    
    if not unique_name_serial_found then
        if not pcall(function() return self.cns_hcard:select(hexf('3F0010001003')) end ) then
            log.output('add_info_cns(): CNS Serial Number file not found...')
            
            if not self.cns_only and pcall(function() return self.cns_hcard:select(hexf('3F002f02')) end ) then
                log.output('get_info(): trying GDO serial Number...')
                pcall(function()self.info.serialNumber = hex.hexify(self.cns_hcard:read_binary(18, 8)) end )
            end
            self.info.serialNumber = self.info.serialNumber or '0000000000000000'
        else
            self.info.serialNumber = self.cns_hcard:read_binary(0,16)
        end
        
        if self._uniquereadernames_cache_enabled then
            log.output('add_info_cns(): uniquereadername: caching unique_name_serial:', self.info.serialNumber)
            utility.cache_write(self.reader_name, "unique_name_serial", self.info.serialNumber, self._umcachepath)
        end
    end
    if string.len(self.info.serialNumber) ~= 16 then
        self.info.serialNumber = string.sub(self.info.serialNumber, 1, 16)
        self.info.serialNumber = string.rep("0", 16 - string.len(self.info.serialNumber)) .. self.info.serialNumber
    end
    
    self:check_clear_cache(nil, true, false) -- no not clear memory cache, since we are adding infos
    
    local hpc_prefix = '3F001700';
    local cns_key_prefix = '3F00'
    self.cns_info = {
        cert_valid      = false,
        key_valid       = false,
        cns_key_prefix = cns_key_prefix,
        cns_fs_valid=(self.info.serialNumber~=nil),
    }
    if self.cfg["ihpc"] ~= "false" then
        pcall (function()
            log.output('add_info_cns(): probing HPC FS...')
            self:select_with_cache(hexf(hpc_prefix))
            cns_key_prefix = hpc_prefix
            self.info.label = "CNS-HPC"
        end)
    end
    local offset = self:cache_enabled() and -1 or 1
    pcall (function()
        local certVal = self:read_cached_file(hexf(objCnsTmpl.GetCNSCertTemplate().path), 0, offset, self:cache_enabled())
        self.cns_info.cert_valid = (string.byte(certVal, 1) == 48) -- hex 30
    end)
    pcall (function()
        local dataVal = self:read_cached_file(hexf(objCnsTmpl.GetCNSPDATATemplate().path), 0, offset, self:cache_enabled())
        local dataValB = string.byte(dataVal, 1)
        self.cns_info.pdata_valid = (dataValB ~= 255 and dataValB ~= 0)
    end)
    log.output('add_info_cns(): certificate valid:', self.cns_info.cert_valid)
    log.output('add_info_cns(): pdata valid:', self.cns_info.pdata_valid)
    local pcRes, theErrorT = pcall (function()
        local pubKeyVal
        local path = hexf(cns_key_prefix .. objCnsTmpl.GetCNSPubKeyTemplate().path)
        local info = self.info
        if self:cache_enabled() and info then
            local modulus = utility.cache_read(info.serialNumber, path .. "rmod", self._AvoidUseLastUpdate, self._umcachepath)
            local pubexp = utility.cache_read(info.serialNumber, path .. "rexp", self._AvoidUseLastUpdate, self._umcachepath)
            
            self.cns_info.modulus = modulus
            self.cns_info.pubexp = pubexp
            
            if type( modulus) == "string" and string.len(modulus) >= 128 then
                if string.byte(modulus, 1) == 255 or string.byte(modulus, 1) == 0 then
                    pubKeyVal = hex.hexf("10%P", "\255\255" .. modulus) -- empty modulus structure
                    log.output('add_info_cns(): cache_read: VALUE: empty modulus TLV struct')
                    self.cns_info.key_valid = false
                else
                    pubKeyVal = hex.hexf("10%P", hex.hexf("%P", "\0" .. modulus)) -- rebuilds TLV record structure
                    self.cns_info.key_valid = true
                end
            end
            log.output('add_info_cns(): cache_read: VALUE: pubKeyVal=', hex.hexify(pubKeyVal or ""))
        end
        if type( pubKeyVal) ~= "string" or string.len(pubKeyVal) < 3  then
            local modulus, pubexp = self.cns_hcard:read_public_key(path)
            self.cns_info.key_valid = string.byte(modulus, 1) ~= 255 and string.byte(modulus, 1) ~= 0
            
            self.cns_info.modulus = modulus
            self.cns_info.pubexp = pubexp
            
            if self:cache_enabled() and info then
                if modulus and pubexp then
                    utility.cache_write(info.serialNumber, path .. "rexp", pubexp, self._umcachepath)
                    utility.cache_write(info.serialNumber, path .. "rmod", modulus, self._umcachepath)
                    pubKeyVal = hex.hexf("10%P", hex.hexf("%P", "\0" .. modulus)) -- rebuilds TLV record structure
                    log.output('add_info_cns(): fresh: VALUE (FULL) : pubKeyVal=', hex.hexify(pubKeyVal or ""))
                    
                end
            end
        end

    end)
    if not pcRes then
        log.output("add_info_cns(): error:", debug.traceback(theErrorT))
    end
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
            ulTotalPublicMemory = 128000,
            ulFreePublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulTotalPrivateMemory = 128000,
            ulFreePrivateMemory = CK.UNAVAILABLE_INFORMATION,
            hardwareVersion = { major=0, minor=0},
            firmwareVersion = { major=0, minor=0},
            utcTime = '0000000000000000',
            supportsPinpolicy=true,
        }
        
        self:add_info_cns()
        self:add_info_ds()
        self:add_info_p11()
        
        self:init_pin_policy()
        
        if self.p11_info and type(self.p11_info.label) == "string" and string.len(self.p11_info.label) > 0 then
            self.info.label = self.p11_info.label
        end
        
        local getCTrcbl -- get card traceability result
        local recv = self:send_cached_apdu(hexf('B0FD000051'), true, false)
        local sw = string.sub(recv, -2, -1)
        if sw == hexf('9000') then
            -- self.info.manufacturerID = 'ST Incard'
            self.cns_hcard.is_incard = true
            self.check_pin_status = self.cns_hcard.is_incard and not self.cns_only
            getCTrcbl = recv
            
            recv = self:send_cached_apdu(hexf('00ca01800a'), true, false)
            sw = string.sub(recv, -2, -1)
            if sw == hexf('9000') and (string.sub(recv, 1, 5) == "JSign" or string.sub(recv, 1, 6) == "J-Sign") then
                log.output('get_info(): GET DATA: found  J-Sign product')
                self.jsign_product_name = string.sub(recv, 1, 6)
                self.jsign_2048 = true
                self.jsign2 = string.sub(recv, 1, 6) == "JSign2"
                self.jsign3 = string.sub(recv, 1, 6) == "JSign3"
                self.jsign4 =  string.sub(recv, 1, 6) == "JSign4"
                self.jsign3plus = self.jsign3 or self.jsign4
                self.support2048new = true
            else
                self.support2048new = sw == hexf('9000')
            end
        elseif self.cns_only then
            
            self.info.ulMinPinLen = 5
            log.output(string.format('get_info(): cns_only, ulMinPinLen set to %d', self.info.ulMinPinLen ) )
        
            log.output(string.format('get_info(): try to detect NXP/Athena card type') )
            local select_mf = hex.hexf("00a4000000")
            local get_free_mem = hex.hexf("00CA011100")
            local get_os_ver = hex.hexf("00CA011600")
            local get_os_build= hex.hexf("00CA011700")
            local pcRes, theErrorT = pcall( function()
                recv = self:send_cached_apdu(get_free_mem, true, false)
                sw = string.sub(recv, -2, -1)
                if sw == hexf('9000') and string.len(recv) > 3 then
                    local recv1 = self:send_cached_apdu(get_os_ver, true, false)
                    local sw1 = string.sub(recv1, -2, -1)
                    if sw1 == hexf('9000') and string.len(recv1) > 3 then
                        local recv2 = self:send_cached_apdu(get_os_build, true, false)
                        local sw2 = string.sub(recv2, -2, -1)
                        if sw2 == hexf('9000') and string.len(recv2) > 3 then
                            local os_ver = bin.unpack('%>%H', recv1)
                            local os_build = bin.unpack('%>%H', recv2)
                            local free_mem = bin.unpack('%>%H', recv)
                            self.info.manufacturerID = "NXP"
                            self.info.label = "Carta Nazionale dei Servizi"
                            self.info.model = string.format("%x.%04x", os_ver, os_build)
                            self.info.ulTotalPublicMemory = 128000
                            self.info.ulFreePublicMemory = free_mem
                            self.info.ulTotalPrivateMemory = 128000
                            self.info.ulFreePrivateMemory = free_mem
                            self.check_pin_status = true
                            self.is_nxp = true
                        end
                    end
                    
                    recv = self:send_cached_apdu(select_mf, true, false)
                    sw = string.sub(recv, -2, -1)
                    if sw == hexf('9000') and string.len(recv) > 3 then
                        local fci1 = CnsSmartcard.parse_tlv(recv)
                        local fci2 = fci1 and CnsSmartcard.parse_tlv(fci1[98] or fci1[111]) -- 0x62 or 0x6F
                        
                        local tag_87 = tonumber("87", 16)
                        if fci2 and fci2[tag_87] and type(fci2[tag_87]) == "string" and string.len(fci2[tag_87]) >= 4 then
                            local total_memory = bin.unpack('%>%L', fci2[tag_87])
                            if total_memory and total_memory >0 then
                                self.info.ulTotalPublicMemory = total_memory
                                self.info.ulTotalPrivateMemory = total_memory
                            end
                        end
                    end

                end
            end)
            if not pcRes then
                log.output("get_info(): NXP detect error:", theErrorT)
            end
            
        end
        
        log.output(string.format('get_info(): support2048new:%s...', tostring(self.support2048new) ))
        
        if self.jsign3plus and not self.cns_only then
            local ulMinKeySize = 256
            local ulMaxKeySize = 521
            log.output('get_info(): Jsign3: enabling ECDSA support: ulMinKeySize/ulMaxKeySize:', ulMinKeySize, ulMaxKeySize )
            self.mechanisms[ CKM.EC_KEY_PAIR_GEN ] = {ulMinKeySize=ulMinKeySize, ulMaxKeySize=ulMaxKeySize, flags=CKF.HW+CKF.GENERATE_KEY_PAIR+CKF.EC_OID+CKF.EC_F_P+CKF.EC_UNCOMPRESS}
            self.mechanisms[ CKM.ECDSA ] = {ulMinKeySize=ulMinKeySize, ulMaxKeySize=ulMaxKeySize, flags=CKF.HW+CKF.SIGN+CKF.EC_OID+CKF.EC_F_P+CKF.EC_UNCOMPRESS}
        end
        
        if not self.jsign_2048 then
            log.output('get_info(): disabling CNS applet selection for non JSign cards...')
            self.cns_hcard.on_transmit = nil
            self.cns_hcard.on_begin_transaction = nil
        end
        
        if self.p11_info and self.p11_info.version_major < 2 and self.jsign_2048 then
            self.p11_info.version_major = 2
        end
        
        log.output('get_info(): is_incard:', self.cns_hcard.is_incard)
        log.output('get_info(): cns_only:',self.cns_only)
        log.output('get_info(): check_pin_status:', self.check_pin_status)
        log.output('get_info(): jsign_2048:', self.jsign_2048, 'jsign2:', self.jsign2, 'jsign3:', self.jsign3, 'jsign4:', self.jsign4)
        
        if self.p11_info then
            log.output('get_info(): self.p11_info.version_major/version_minor:', self.p11_info.version_major, self.p11_info.version_minor)
        end
        
        
        if self.support2048new then
            local prefix = "DS"
            if self.jsign4 then
                prefix = "JS4-"
            elseif self.jsign3 then
                prefix = "JS3-"
            elseif self.jsign2 then
                prefix = "JS2-"
            elseif self.jsign_2048 then
                prefix = "JS"
            else
                self.info.ulTotalPublicMemory = 65536
                self.info.ulTotalPrivateMemory = 65536
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

            for i, v in self.mechanisms do
                if v.ulMaxKeySize >= 1024 then -- should correct only RSA
                    v.ulMaxKeySize = 2048
                end
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

        -- getCTrcbl: byte 8 e 9 codificano anno mese e giorno di produzione. esempio: a4a4 -> 1010 0100 1010 0100
        -- anno di produzione 5 bit: 1010 0 -> 20 -> ovvero 20 +1990 = 2010
        -- mese 4 bit: 1001 -> 9, Settembre
        -- giorno di produzione 5 bit: 01001 -> 9
        local ProductionYear=2011
        local ProductionMonth=5  -- data oltre la quale non sono pi