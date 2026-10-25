 valorizzato
    -- i PIN sono considerati uguali
    if not self.cfg["dspiniscnspin"] and not self.request_plugin_valid then
        log.output('Athena token initialize(): no plugin and dspiniscnspin unset: forcing dspiniscnspin=true')
        self.cfg["dspiniscnspin"] = 'true'
    end
    
    if self.cfg["dspinusegui"] then self.cfg["dspinusegui"]=string.lower(self.cfg["dspinusegui"])
    else self.cfg["dspinusegui"]='false' end
    
    if self.cfg["dspiniscnspin"] then self.cfg["dspiniscnspin"]=string.lower(self.cfg["dspiniscnspin"])
    else self.cfg["dspiniscnspin"]='false' end

    if self.cfg["hidecachedspincheck"] then self.cfg["hidecachedspincheck"]=string.lower(self.cfg["hidecachedspincheck"])
    else self.cfg["hidecachedspincheck"]='false' end
    
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
    if self._cache_id == nil then
        self:flush_cache()
    end
end

function t.mt:finalize()
    log.output("token-athena:finalize():", self.userType)
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
    if self.cns_only then
        return
    end
    repeat
        log.output('add_info_p11(): probing Fullp11 fileSystem...')
        if not pcall(function() return self.cns_hcard:select(hexf('3F004FFF7fff')) end ) then
            log.output('token-cns:get_info(): Fullp11 fileSystem not found...')
            break
        end
        local pcRes, p11_info_str
        local obj_table = {}
        local bso_table = {}
        local bso2048_table = {}

        -- main file structure: 64 bytes
        -- version major: BYTE (index 1)
        -- version minor: BYTE (index 2)
        -- OAT1: ULONG little endian bitmap, 4 BYTE (index 3)
        -- OAT2: ULONG little endian bitmap, 4 BYTE (index 7)
        -- OAT3: ULONG little endian bitmap, 4 BYTE (index 11)
        -- RFU/OAT4: ULONG little endian bitmap, 4 BYTE (index 15)
        -- BAT: WORD little endian bitmap, 2 BYTE (index 19)
        -- BAT_DES: WORD little endian bitmap, 2 BYTE (index 21) ignore
        -- BAT_2048: WORD little endian bitmap, 2 BYTE (index 23)
        -- TOKENINFO: 40 BYTES (index 25)
            -- LABEL: 40 chars
        
        pcRes, p11_info_str = pcall(function() return self.cns_hcard:read_binary(0,64) end )
        if not pcRes or string.len(p11_info_str) < 64 then
            log.output('token-cns:get_info(): FullP11 main file, read_binary error...')
            break
        end
        local p11_info = {}
        p11_info.oat_t = bin.flags(bin.unpack('%<%L', string.sub(p11_info_str, 3, 6)) )
        p11_info.oat2_t = bin.flags(bin.unpack('%<%L', string.sub(p11_info_str, 7, 10)) )
        p11_info.oat3_t = bin.flags(bin.unpack('%<%L', string.sub(p11_info_str, 11, 14)) )
        -- p11_info.oat4_t = bin.flags(bin.unpack('%<%L', string.sub(p11_info_str, 15, 18)) )
        
        p11_info.bat_t = bin.flags(bin.unpack('%<%H', string.sub(p11_info_str, 19, 20)) )
        p11_info.bat2048_t = bin.flags(bin.unpack('%<%H', string.sub(p11_info_str, 23, 24)) )
        
        -- p11_info.label = bin.flags(bin.unpack('%<%H', string.sub(p11_info_str, 25, 64)) )
        
        log.output(string.format('token-cns:add_info_p11(): oat_t: 0x%x', p11_info.oat_t.asnumber))
        log.output(string.format('token-cns:add_info_p11(): bat_t: 0x%x', p11_info.bat_t.asnumber))
        log.output(string.format('token-cns:add_info_p11(): oat2_t: 0x%x', p11_info.oat2_t.asnumber))
        log.output(string.format('token-cns:add_info_p11(): oat3_t: 0x%x', p11_info.oat3_t.asnumber))
        -- log.output(string.format('token-cns:add_info_p11(): oat4_t: 0x%x', p11_info.oat4_t.asnumber))
        log.output(string.format('token-cns:add_info_p11(): bat2048_t: 0x%x', p11_info.bat2048_t.asnumber))
        
        for i=0,31 do
            obj_table[i] = p11_info.oat_t[bin.flags(2^i)]
        end
        local k
        for i=32,63 do
            k = i-32
            obj_table[i] = p11_info.oat2_t[bin.flags(2^k)]
        end
        for i=64,95 do
            k = i-64
            obj_table[i] = p11_info.oat2_t[bin.flags(2^k)]
        end
        for i=0,15 do
            bso_table[i] = p11_info.bat_t[bin.flags(2^i)]
        end
        for i=0,15 do
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
        return
    end
    local changepin_explicit_test = false
    repeat
        log.output('add_info_ds(): probing DS fileSystem...')
        local ds_info_str, path_root, pcRes = '', nil, false
        -- NOTA: pcall non puo essere chiamato passando un metodo (si dovrebbe usare senza i ':' e passando esplicitamente l'oggetto come primo parametro)
        if pcall(function() return self.cns_hcard:select(hexf('3F0014007100')) end ) then
            path_root = '3F001400'
        elseif pcall(function() return self.cns_hcard:select(hexf('3F007100')) end ) then
            log.output('token-cns:get_info(): DS app on ROOT. Forcing explicit test on change_pin')
            path_root = '3F00'
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
        self.ds_info.path_root = path_root
        self.ds_info.ds_sig_path = path_root .. "7110"
        if self.ds_info.use_sm then 
            self.ds_info.sm_enc = sm.sm_ask_keys(0)
            self.ds_info.sm_sig = sm.sm_ask_keys(1)
            log.output('using sm_keys:')
            log.output('enc:', hex.hexify(self.ds_info.sm_enc), ', sig:', hex.hexify(self.ds_info.sm_sig)) 
        end
        self.ds_info.pin_initialized = true
        self.ds_info.changepin_explicit_test = changepin_explicit_test
        self.info.ulMaxPinLen = 8
        self.info.ulMinPinLen = 5
        pcall( function()
            log.output('add_info_ds(): checking DS AREA initialization state...')
            local recv = self.cns_hcard:sm_transmit(hex.hexf("00a40800%P", hexf(self.ds_info.ds_sig_path)))
            local sw = hex.hexify(string.sub(recv, -2, -1))
            if sw == '6283' then
                self.ds_info.pin_initialized = false
                log.output('add_info_ds(): DS PIN is NOT initialized')
            end
        end)
        break
    until true
end

function t.mt:add_info_cns()
    log.output('add_info_cns(): probing CNS fileSystem!!!...')
    if not pcall(function() return self.cns_hcard:select(hexf('3F0010001003')) end ) then
        log.output('add_info_cns(): CNS Serial Number file not found...')
    else
        self.info.serialNumber = self.cns_hcard:read_binary(0,16)
    end 
    
    local cns_key_prefix = '3F00'
    self.cns_info = {
        cert_valid      = false,
        key_valid       = false,
        cns_key_prefix = cns_key_prefix,
        cns_fs_valid=(self.info.serialNumber~=nil),
    }
    -- pcall (function()
        -- local hpc_prefix = '3F001700';
        -- log.output('add_info_cns(): probing HPC FS...')
        -- self.cns_hcard:select(hexf(hpc_prefix))
        -- cns_key_prefix = hpc_prefix
        -- self.info.label = "CNS-HPC"
    -- end)
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

function t.mt:update_free_mem(info)
    if not info then
        return
    end
    local freeMem = self.cns_hcard:transmit(hexf('00ca011c00'))
    local sw = string.sub(freeMem, -2, -1)
    if sw == hexf('9000') and string.len(freeMem) >= 4 then
        info.ulFreePublicMemory = bin.unpack("%>%L", string.sub(freeMem, 1, 4) )
        info.ulTotalPublicMemory = math.max(info.ulFreePublicMemory, 65536)
        info.ulFreePrivateMemory = info.ulFreePublicMemory
        info.ulTotalPrivateMemory = info.ulTotalPublicMemory
    end
    local freeBlock = self.cns_hcard:transmit(hexf('00ca011000'))
    local sw = string.sub(freeBlock, -2, -1)
    if sw == hexf('9000') and string.len(freeMem) >= 2 then
        info.ulFreePrivateMemory = bin.unpack("%>%H", string.sub(freeBlock, 1, 2) )
    end
end

function t.mt:get_info()
    if not self.info then
        self.info = {
            label = 'Bit4id CryptoCard',
            manufacturerID = 'Athena',
            model = '2048',
            serialNumber = nil,
            flags = CKF.RNG + CKF.LOGIN_REQUIRED + CKF.TOKEN_INITIALIZED,
            ulMaxSessionCount = CK.EFFECTIVELY_INFINITE,
            ulSessionCount = 0,
            ulMaxRwSessionCount = CK.EFFECTIVELY_INFINITE,
            ulRwSessionCount = CK.UNAVAILABLE_INFORMATION,
            ulMaxPinLen = 8,
            ulMinPinLen = 1,
            ulTotalPublicMemory = 65536,
            ulFreePublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulTotalPrivateMemory = 65536,
            ulFreePrivateMemory = CK.UNAVAILABLE_INFORMATION,
            hardwareVersion = { major=0, minor=0},
            firmwareVersion = { major=0, minor=0},
            utcTime = '0000000000000000'
        }
        
        self:add_info_cns()
        self:add_info_ds()
        self:add_info_p11()
        
        local licValid, license
        licValid, license = licensing.is_licensed(self, self.info.serialNumber)
        if licValid and license and 
           (license.card_type == nil or license.card_type == 0 or license.card_type == licensing.card_types.athena ) then
            self._license_valid = license
            self.info.model = self.info.model .. " (L)"
            if license and license.pin_behavior then
                log.output("get_info(): license specify PIN behavior:", license.pin_behavior)
                if license.pin_behavior == 1 then
                    self.cfg["dspiniscnspin"] = true
                    self.cfg["dspinusegui"] = false
                elseif license.pin_behavior == 2 then
                    self.cfg["dspiniscnspin"] = false
                    self.cfg["dspinusegui"] = true
                end
            end
            if license and license.label then
                self.info.label = license.label
            end
        end
        -- self._license_valid = {}
        
        self:update_free_mem(self.info)
        self.support2048new = true
        
        if (not self.cns_info or not self.cns_info.cns_fs_valid) 
           and not self.ds_info
           and self.p11_info then
            self.info.label = 'Bit4id PKCS11 Crypto Smart Card'
            log.output('get_info(): full p11, label set to: ', self.info.label)
        elseif (not self.cns_info or not self.cns_info.cns_fs_valid) 
           and self.ds_info
           then
            self.info.label = 'Bit4id DS Crypto Smart Card'
            log.output('get_info(): DS, label set to: ', self.info.label)
        else
            log.output('get_info(): fs status', self.cns_info, self.cns_info.cns_fs_valid, self.ds_info, self.p11_info)
        end

        if not self.info.serialNumber and not self.cns_only
            and pcall(function() return self.cns_hcard:select(hexf('3F002f02')) end ) then
            log.output('get_info(): trying GDO serial Number...')
            pcall(function()self.info.serialNumber = hex.hexify(self.cns_hcard:read_binary(18, 8)) end )
        end
        self.info.serialNumber = self.info.serialNumber or '0000000000000000'
        
        if self.cfg["tdefaultlabel"] then
            self.info.label = self.cfg["tdefaultlabel"]
        end
        
    end
    -- NOTA: il seguente codice 