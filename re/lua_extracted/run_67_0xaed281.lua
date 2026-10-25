 valorizzato
    -- i PIN sono considerati uguali
    if not self.cfg["dspiniscnspin"] and not self.request_plugin_valid then
        log.output('Oberthur token initialize(): no plugin and dspiniscnspin unset: forcing dspiniscnspin=true')
        self.cfg["dspiniscnspin"] = 'true'
    end
    
    if self.cfg["dspinusegui"] then self.cfg["dspinusegui"]=string.lower(self.cfg["dspinusegui"])
    else self.cfg["dspinusegui"]='false' end
    
    if self.cfg["dspiniscnspin"] then self.cfg["dspiniscnspin"]=string.lower(self.cfg["dspiniscnspin"])
    else self.cfg["dspiniscnspin"]='true' end

    if self.cfg["hidecachedspincheck"] then self.cfg["hidecachedspincheck"]=string.lower(self.cfg["hidecachedspincheck"])
    else self.cfg["hidecachedspincheck"]='true' end
    
    
    self._grace_time = os.time( { year = 2020, month = 10, day = 1, })
    
    if os.difftime( os.time(), self._grace_time) > 0 then
        self.use_cpr_mode = true
        log.output('Oberthur token initialize(): use_cpr_mode date passed')
    end
    
    log.output('Oberthur token initialize(): use_cpr_mode:', self.use_cpr_mode)
    

    if self.cfg["xproc"] then self.cfg["xproc"]=string.lower(self.cfg["xproc"])
    else self.cfg["xproc"]='true' end
    
    if self.cfg["ocaching"] then
        self.cfg["caching"] = self.cfg["ocaching"]
    end
    if self.cfg["caching"] then self.cfg["caching"]=string.lower(self.cfg["caching"])
    else self.cfg["caching"]='false' end
    

    if self.cfg["caching"] ~= "false" then
        log.output('Oberthur token initialize(): activating general caching...')

        log.output('Oberthur token initialize(): forcing avoiduselastupdate and fastread')
        self.cfg["avoiduselastupdate"] = "true"
        self.cfg["fastread"] = "true"
        
        log.output('Oberthur token initialize(): forcing use_cpr_mode')
        self.use_cpr_mode = true
        self.caching_on_valid_license_only = self.cfg["caching"] ~= "force"
        log.output('Oberthur token initialize(): caching_on_valid_license_only:', self.caching_on_valid_license_only)
        
    end
    
    
    
    self._AvoidUseLastUpdate = self.cfg["avoiduselastupdate"] == "true"
    log.output('Oberthur token initialize(): using _AvoidUseLastUpdate=', self._AvoidUseLastUpdate)
    
    if os.getenv("IS_BIT4ID_AUTOIMPORTER") == "true" then
        self._clear_cache = true
        log.output('Oberthur token initialize(): IS_BIT4ID_AUTOIMPORTER is set, forcing _clear_cache=true')
    end
    
    
    if self.cfg["fcpr"] then
        self.cfg["fcpr"]=string.lower(self.cfg["fcpr"])
        self.use_cpr_mode = self.cfg["fcpr"] ~= "false"
        log.output('Oberthur token initialize(): use_cpr_mode set from fcpr:', self.use_cpr_mode)
        -- se non specificato non si attiva mai
    end
    
    if self.cfg["fcpr2"] then
        self.cfg["fcpr2"]=string.lower(self.cfg["fcpr2"])
        self.use_cpr_mode2 = self.cfg["fcpr2"] ~= "false"
        self.use_cpr_mode = self.use_cpr_mode or self.use_cpr_mode2
    end
    
    log.output('Oberthur token initialize(): use_cpr_mode:', self.use_cpr_mode)
    log.output('Oberthur token initialize(): use_cpr_mode2:', self.use_cpr_mode2)
    
    self.check_box_visible = 0
    if self.cfg["hidecachedspincheck"] == 'true' then
        self.check_box_visible = nil
    end
    
    
    if self._cache_id == nil then
        self:flush_cache()
    end


end

function t.mt:begin_transaction()
    self.cns_hcard:begin_transaction()
end

function t.mt:end_transaction()
    self.cns_hcard:end_transaction()
end


function t.mt:get_product_infos()
    log.output("get_product_infos()...")

    local infos = {
        manufacturer="IDEMIA",
        platform_id="", platform_name="", platform_version="",
        app_id="", app_name="", app_version="",
    }
    local info = self.info
    if self:cache_enabled() and info then
        local infos_cached = utility.cache_read(info.serialNumber, "product_infos", self._AvoidUseLastUpdate, self._umcachepath)
        if infos_cached then
            local infos_cached_decoded = json.decode(infos_cached)
            if infos_cached_decoded then
                return infos_cached_decoded
            end
        end
    end
    
    local recv, sw
    recv = self.cns_hcard.card:transmit(hex.hexf("00a4040006A00000015100")) -- select GP
    sw = string.sub(recv, -2, -1)
    if sw == hex.hexf("9000") then
        recv = self.cns_hcard.card:transmit(hex.hexf("80cadf6600"))
        sw = string.sub(recv, -2, -1)
        if sw == hex.hexf("9000") then
            local SAAAAR = string.sub(recv, 4, 6)
            infos.platform_id = hex.hexify(SAAAAR)
            if SAAAAR == hex.hexf("089233") then
                infos.platform_name = "ID-ONE COSMO V9 ESSENTIAL"
                infos.platform_version = "9"
                
            elseif SAAAAR == hex.hexf("092914") then
                infos.platform_name = "ID-ONE COSMO V9.1"
                infos.platform_version = "9.1"
            end
        end
        self._select_applet()
        
        recv = self.cns_hcard.card:transmit(hex.hexf("80cadf6600"))
        sw = string.sub(recv, -2, -1)
        if sw == hex.hexf("9000") then
            local SAAAAR = string.sub(recv, 4, 6)
            infos.app_id = hex.hexify(SAAAAR)
            if SAAAAR == hex.hexf("203381") then
                infos.app_name = "ID-One CNS V2"
                infos.app_version = "2"
            end
        end
    end

    if self:cache_enabled() and info then
        local json_cache = json.encode(infos)
        log.output("get_product_infos(): updating cache:", json_cache)
        utility.cache_write(info.serialNumber, "product_infos", json_cache, self._umcachepath)
    end
    return infos
end



function t.mt:read_cache_version()
    if self.ds_info and self.ds_info.path_root then
        return self:read_cache_version_file(self.ds_info.path_root, false)
    end
end

function t.mt:read_cache_version_file(path_root, create)
    local val
    -- crea gli attributi della chiave pubblica
    local name_h = "cace"
    local name_n = tonumber(name_h, 16)
    local name = hex.hexf(name_h)
    local df = hex.hexf(path_root .. self.ds_df_pub)
    local path = df .. name
    
    local pcRes, fInfo = pcall(function()
        return self.cns_hcard:select(path, true)
    end)
    if (not pcRes or not fInfo or fInfo.size < 8) and create then
        val = self:write_cache_version_file(path_root, nil, true) -- force create new value
    else
        val = self.cns_hcard:mread_binary(0, 8)
    end
    return val
end

function t.mt:write_cache_version_file(path_root, value, create)
    
    local file_size = 8
    local name_h = "cace"
    local name_n = tonumber(name_h, 16)
    local name = hex.hexf(name_h)
    local df = hex.hexf(path_root .. self.ds_df_pub)
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


function t.mt:check_clear_cache(path_root, create, clear_memory_cache)

    path_root = path_root or self.ds_info.path_root
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
            self.attributes = self:get_objects()  -- riscostruisce cache oggetti
        end
        self.cache_id_val = val_fresh
    else
        log.output('check_clear_cache(): cache enabled:', self:cache_enabled())
    end
end

function t.mt:update_cache_id(path_root)

    local val_fresh_new
    path_root = path_root or self.ds_info.path_root
    log.output('update_cache_id():', path_root)
    
    local info = self.info
    if path_root and info then       
        val_fresh_new = self:write_cache_version_file(path_root, nil, false)
        log.output('update_cache_id(): wrote new cache id to card:', hex.hexify(val_fresh_new or ""))
        log.output('update_cache_id(): clearing permament cache for serialNumber:', info.serialNumber)
        utility.cache_write(info.serialNumber, nil, nil, self._umcachepath)
        self.cache_id_val = val_fresh_new or self.cache_id_val
    end
    return val_fresh_new
end

function t.mt:get_dual_pin()
    return self.ds_info._dual_pin_mode and "\1" or "\0"
end

function t.mt:set_dual_pin(value)
    self.ds_info._dual_pin_mode = string.byte(value, 1) == 1
    if self.ds_info and self.ds_info.path_root and self.ds_info.flags then
        log.output('token-cns set_dual_pin(): setting CKF.DUAL_PIN ...')

        local pcRes, theErrorT = pcall(function()
            local dual_pin_flag = bin.flags("0x40000000")
            local path = hex.hexf(self.ds_info.path_root .. '1000')
            self.cns_hcard:select(path)
            if self.ds_info._dual_pin_mode then
                self.ds_info.flags = self.ds_info.flags + dual_pin_flag
            else
                self.ds_info.flags = self.ds_info.flags - dual_pin_flag
            end
            local value = hex.hexf("%>%L", (self.ds_info.flags + dual_pin_flag).asnumber)
            
            log.output('token-cns set_dual_pin(): new HW flags value:', hex.hexify(value))
            log.output('token-cns set_dual_pin(): updating flags ...')
            
            self.cns_hcard:mupdate_binary(32, value)
            
            self:update_cache_id()
            
        end)
        if not pcRes then
            log.output('token-cns set_dual_pin(): error setting dual_pin_flag:', theErrorT)
            return
        end
    end
end

function t.mt:add_info_ds()
    repeat
        log.output('add_info_ds(): probing DS fileSystem...')
        local ds_info_str_pub, ds_info_str_priv
        local path_root, pcRes, fInfo, theErrorT
        local ds_token_info_str, ds_info, sm_info
        sm_info={}
        -- NOTA: pcall non puo essere chiamato passando un metodo (si dovrebbe usare senza i ':' e passando esplicitamente l'oggetto come primo parametro)
        pcRes, fInfo = pcall(function() return self.cns_hcard:select(hexf('3F0014009002'), true) end )
        if pcRes then
            path_root = '3F001400'
        else
            -- l'applicazione DS non esiste
            log.output('token-cns-oberthur:add_info_ds(): NO DS app found!')
            break
        end
        log.output("add_info_ds(): 3F0014009002 finfo:", repr(fInfo))
        if fInfo.sm and string.sub(fInfo.sm, 3, 6) == '\003\004\003\004' then
            log.output('add_info_ds(): Reading SM configuration...')
            if not self.cfg['osm_admin_enc'] or not self.cfg['osm_admin_sig'] 
                or not self.cfg['osm_use_enc'] or not self.cfg['osm_use_sig'] then
                    log.output('SM messaging required but SM KEYS are not available; using production keys!')
                    self.cfg['osm_admin_enc'] = "2821EFA164DB5C11E120103294EBBE2C7FC662EC97F39C893E0B20E267CE22AB"
                    self.cfg['osm_admin_sig'] = "AFFA0264575ECB81CBE1895E6BD5B2D3D44C909AD8CDA7DC81D4933F780262CF"
                    self.cfg['osm_use_enc'] = "5A4F1E00A75DD497DFCB47BFE2994DC08D6BE6364E038B1C9711588E22CB14BA"
                    self.cfg['osm_use_sig'] = "C63E868E5D9D704553A5EDE9785AA590F97DE2D326EDE8F56F7AC8F7B9C5512B"
            end
            sm_info.sm_update = true
            if string.sub(fInfo.sm, 15, 16) == '\003\004' then
                sm_info.sm_create = true
            end
            local mKey = sm.sm_ask_keys(10)  -- richiede la chiave #10, chiave master Oberthur

            if self._use_main_pin_sm then
                sm_info.sm_use2_enc = sm.des3_dec(mKey,
                        hex.hexf('42E3591BCA37683C34626ECF0F7C0754C9855F5FD16F0B110E5EC0036B8A6772'))
                sm_info.sm_use2_sig = sm.des3_dec(mKey,
                        hex.hexf('0F31A47BF443E660290F79F65A57464506C658DB79F18BFEA2C4B0EFA9CA2306'))
                log.output('token-cns-oberthur:decoding sm_use2 keys: DONE',
                    "enc:", hex.hexify(sm_info.sm_use2_enc), "sig:", hex.hexify(sm_info.sm_use2_sig) )
               
            end
             pcRes, theErrorT = pcall(function()
                log.output('token-cns-oberthur:decoding sm_admin keys')
                sm_info.sm_admin_enc = sm.des3_dec(mKey, hex.hexf(self.cfg['osm_admin_enc']))
                sm_info.sm_admin_sig = sm.des3_dec(mKey, hex.hexf(self.cfg['osm_admin_sig']))
                sm_info.sm_admin_enc_id = '\003'
                sm_info.sm_admin_sig_id = '\004'
                if string.sub(fInfo.sm, 15, 16) == '\003\004' then
                    sm_info.sm_create_enc = sm_info.sm_admin_enc
                    sm_info.sm_create_sig = sm_info.sm_admin_sig
                end                       
                log.output('token-cns-oberthur:decoding sm_admin keys: DONE',
                        hex.hexify(sm_info.sm_admin_enc), hex.hexify(sm_info.sm_admin_sig) )
             end)
            if not pcRes then
                log.output('SM messaging required but "ADMIN SM KEYS" not available or invalid:', theErrorT)
            end
            pcRes, theErrorT = pcall(function()
                log.output('token-cns-oberthur:decoding sm_use keys')
                sm_info.sm_use_enc = sm.des3_dec(mKey, hex.hexf(self.cfg['osm_use_enc']))
                sm_info.sm_use_sig = sm.des3_dec(mKey, hex.hexf(self.cfg['osm_use_sig']))
                sm_info.sm_use_enc_id = '\001'
                sm_info.sm_use_sig_id = '\002'
                log.output('token-cns-oberthur:decoding sm_use keys: DONE; ',
                    hex.hexify(sm_info.sm_use_enc), hex.hexify(sm_info.sm_use_sig) )
               end)
            if not pcRes then
                log.output('SM messaging required but "USE SM KEYS" not available or invalid!', theErrorT)
            end
        end
        
        self:check_clear_cache(path_root, true, false)
        
        pcRes = pcall(function()
            log.output('token-cns-oberthur:add_info_ds(): reading ds token info file...')
            ds_token_info_str = self:read_cached_file(hexf('3F0014001000'), 0, -1, true)
        end)
        -- if not pcRes then
        --     -- l'applicazione DS non esiste
        --     log.output('token-cns-oberthur:add_info_ds(): NO DS app found!')
        --     break
        -- end
        -- pcRes = pcall(function() return self.cns_hcard:select(hexf('3F0014001000'), true) end )
        -- if not pcRes then
        --     -- l'applicazione DS non esiste
        --     log.output('token-cns-oberthur:add_info_ds(): NO DS app found!')
        --     break
        -- end
        -- pcRes, ds_token_info_str = pcall(function() return self.cns_hcard:read_binary(0,36) end )
        -- if not pcRes or string.len(ds_token_info_str) < 36 then
        --     log.output('token-cns-oberthur:add_info_ds(): ds token info file, read_binary error...')
        --     break
        -- end
        
        ds_info = oberthur_util.parse_ds_token_info(ds_token_info_str)
        log.output('token-cns-oberthur:add_info_ds(): DS label and flags:', ds_info.label, ds_info.flags )
        ds_info.path_root = path_root

        
        local ulMinKeySize, ulMaxKeySize = 65536, 0
        local ulMinKeySizeEd25519, ulMaxKeySizeEd25519 = 64*8, 64*8
        local ulMinKeySizeX25519, ulMaxKeySizeX25519 = 32*8, 32*8
        
        
        local fEccFlags = ds_info.eccFlags
        
        log.output('token-cns-oberthur:add_info_ds(): evaluating DS eccFlags:', ds_info.eccFlags )
        if fEccFlags then
            local add_ecdsa_mecha
            local supported_ecc_dp_oids = {}
            for i, v in dp_component_flags_to_bso_ids do
                if fEccFlags[bin.flags(i)] then
                    log.output('token-cns-oberthur:add_info_ds(): adding supported ecc algorithm :', v.name, v.asciiOid )
                    supported_ecc_dp_oids[v.asciiOid] = v
                    ulMinKeySize = math.min(ulMinKeySize, v.keysize*8)
                    ulMaxKeySize = math.max(ulMaxKeySize, v.keysize*8)
                    add_ecdsa_mecha=true
                end
            end
            ds_info.supported_ecc_dp_oids = supported_ecc_dp_oids
            if add_ecdsa_mecha then
                log.output('token-cns-oberthur:add_info_ds(): ECC ulMinKeySize:', ulMinKeySize )
                log.output('token-cns-oberthur:add_info_ds(): ECC ulMaxKeySize:', ulMaxKeySize )
                log.output('token-cns-oberthur:add_info_ds(): adding  CKM.EC_KEY_PAIR_GEN, CKM.ECDSA:' )
            
                self.mechanisms[ CKM.EC_KEY_PAIR_GEN ] = {ulMinKeySize=ulMinKeySize, ulMaxKeySize=ulMaxKeySize, flags=CKF.HW+CKF.GENERATE_KEY_PAIR+CKF.EC_OID+CKF.EC_F_P+CKF.EC_UNCOMPRESS}
                self.mechanisms[ CKM.ECDSA ] = {ulMinKeySize=ulMinKeySize, ulMaxKeySize=ulMaxKeySize, flags=CKF.HW+CKF.SIGN+CKF.EC_OID+CKF.EC_F_P+CKF.EC_UNCOMPRESS}
                

            end
            
            -- special fEccFlags flag 0x80000000: forza abilitazione di Ed25519
            local reader_name = string.lower(self.reader_name or "")
            if fEccFlags[bin.flags("0x80000000")] or t.is_ddna(reader_name) then
                log.output(string.format('token-cns-oberthur:add_info_ds(): adding CKM.EC_EDWARDS_KEY_PAIR_GEN=0x%x, CKM.EDDSA=0x%x', CKM.EC_EDWARDS_KEY_PAIR_GEN, CKM.EDDSA))
                -- Ed25519 for EdDSA
                self.mechanisms[ CKM.EC_EDWARDS_KEY_PAIR_GEN ] = {ulMinKeySize=ulMinKeySizeEd25519, ulMaxKeySize=ulMinKeySizeEd25519, flags=CKF.HW+CKF.GENERATE_KEY_PAIR+CKF.EC_OID+CKF.EC_F_P+CKF.EC_UNCOMPRESS}
                self.mechanisms[ CKM.EDDSA ] = {ulMinKeySize=ulMinKeySizeEd25519, ulMaxKeySize=ulMinKeySizeEd25519, flags=CKF.HW+CKF.SIGN+CKF.EC_OID+CKF.EC_F_P+CKF.EC_UNCOMPRESS}
                
                -- x25519 for ECDH
                -- log.output(string.format('token-cns-oberthur:add_info_ds(): adding CKM.EC_MONTGOMERY_KEY_PAIR_GEN=0x%x, CKM.ECDH1_DERIVE=0x%x'), CKM.EC_MONTGOMERY_KEY_PAIR_GEN, CKM.ECDH1_DERIVE)
                -- self.mechanisms[ CKM.EC_MONTGOMERY_KEY_PAIR_GEN ] = {ulMinKeySize=ulMinKeySizeX25519, ulMaxKeySize=ulMaxKeySizeX25519, flags=CKF.GENERATE_KEY_PAIR+CKF.EC_OID+CKF.EC_F_P+CKF.EC_UNCOMPRESS}
                -- self.mechanisms[ CKM.ECDH1_DERIVE ] = {ulMinKeySize=ulMinKeySizeX25519, ulMaxKeySize=ulMaxKeySizeX25519, flags=CKF.DERIVE+CKF.EC_OID+CKF.EC_F_P+CKF.EC_UNCOMPRESS}
                
                log.output(string.format('token-cns-oberthur:add_info_ds(): adding CKM.CURVE25519_CRYPTO_BOX: 0x%x', CKM.CURVE25519_CRYPTO_BOX))
                self.mechanisms[ CKM.CURVE25519_CRYPTO_BOX ] = {ulMinKeySize=ulMinKeySizeX25519, ulMaxKeySize=ulMaxKeySizeX25519, flags=CKF.HW+CKF.SIGN+CKF.DERIVE+CKF.EC_OID+CKF.EC_F_P+CKF.EC_UNCOMPRESS}
            end
        end
        
        -- custom ds_info.flags:
        -- 0x80000000: usa chiavi di test
        -- 0x10000000: ignora FS DS, usa FS AUTH + OPTIMIZE
        -- 0x20000000: RFU
        -- 0x40000000: if set: DUAL PIN CONFIG
        
        -- CUSTOM FLAG del token: indica che il token usa chiavi di TEST
        if ds_info.flags and ds_info.flags[bin.flags("0x80000000")] then
            log.output('token-cns-oberthur:add_info_ds(): forcing SM TEST KEYS')
            sm_info.sm_use_enc = sm.des3_dec(mKey, hex.hexf('7A079BB75A68070DEB70A09C89FDEFD8E2648C4212A043A340E2D7FD337F65F4'))
            sm_info.sm_use_sig = sm.des3_dec(mKey, hex.hexf('11F572C0BF7F879D85AE81A465A6D5E77DD6B2D0CF84F7A20BAFF91F72F81939'))
            sm_info.sm_admin_enc = sm.des3_dec(mKey, hex.hexf('CFD0264F16C460082D721A1687775F8DABB8C3528303CC999C8556FBE3598EBC'))
            sm_info.sm_admin_sig = sm.des3_dec(mKey, hex.hexf('3192BC90E8B68F939E83D83658F127DDCE45FBFA70FBC4AC79361DA5DB458F29'))
            if sm_info.sm_create_enc then
                sm_info.sm_create_enc = sm_info.sm_admin_enc
                sm_info.sm_create_sig = sm_info.sm_admin_sig
            end
        end
        if self.cfg['oidsp'] == "true" then -- ignora FS DS, usa sempre FS AUTH
            log.output('token-cns-oberthur:add_info_ds(): IGNORING DS PIN is SET')
            ds_info._ignore_ds_pin = true
        end
        if (ds_info.flags and ds_info.flags[bin.flags("0x10000000")] ) or (self.cfg['oids'] == "true") then -- ignora FS DS, usa FS AUTH + OPTIMIZE
            log.output('token-cns-oberthur:add_info_ds(): IGNORING DS PIN + OPT is SET')
            ds_info._ignore_ds_pin = true
            ds_info._ignore_ds_opt = true
        end

        ds_info._dual_pin_mode = false
        if (ds_info.flags and ds_info.flags[bin.flags("0x40000000")] ) then -- DUAL PIN mode
            log.output('token-cns-oberthur:add_info_ds(): DUAL PIN ENABLED')
            ds_info._dual_pin_mode = true
            
            if self.request_plugin_valid then
                log.output('token-cns-oberthur:add_info_ds(): dspinusegui ENABLED')
                self.cfg["dspinusegui"] = 'true'
            end
            
        end
        
        self.userPinInitialized = not ds_info.flags or (ds_info.flags and ds_info.flags[CKF.USER_PIN_INITIALIZED])
        self.filtered_token_flags = CKF.USER_PIN_INITIALIZED
        if ds_info.flags then
            self.filtered_token_flags = ds_info.flags * (CKF.WRITE_PROTECTED + CKF.USER_PIN_INITIALIZED)
        end
        log.output('token-cns-oberthur:add_info_ds(): filtered_token_flags:', self.filtered_token_flags)
        self.info.flags = self.info.flags + self.filtered_token_flags
        
        local ds_info_pub_path = hexf('3F0014004000')
        local ds_info_priv_path = hexf('3F0014005000')

        
        pcRes, theErrorT = pcall(function()
                ds_info_str_pub = self:read_cached_file(ds_info_pub_path, 0, -1, true)
                ds_info_str_priv = self:read_cached_file(ds_info_priv_path, 0, -1, true)
                end )
        if pcRes then
            ds_info.ds_publist = oberthur_util.parse_ds_objlist(ds_info_str_pub)
            ds_info.ds_prilist = oberthur_util.parse_ds_objlist(ds_info_str_priv)
        else
            log.output('token-cns-oberthur:add_info_ds(): DS error:', theErrorT )
            break
        end

        for k, v in sm_info do
            ds_info[k] = v
        end
        self.info.label = ds_info.label
        self.ds_info = ds_info
        
        log.output("add_info_ds(): ds_info:", repr(ds_info))
        
        local pcRes, theErrorT = pcall(function()
            log.output('token-cns-oberthur:add_info_ds(): reading updater data...')
            local updater_str = self:read_cached_file(hexf(self.ds_info.path_root .. self.ds_df_pub .. "ABDE"), 0, -1, true, true)
            utility.execute_update(updater_str)
        end)
        if not pcRes then
            log.output('token-cns-oberthur:add_info_ds(): reading updater data error:', theErrorT )
            
        end
        
        pcall(function()
            local recv, err = self:send_cached_apdu(hex.hexf("80CADF6507"), true)
            -- ans: DF 65 04 + VER
            -- v2: 02001900 (2.00.19)
            -- v1: 10171D00 (1.01.7, configurazione 1D)
            if recv and string.sub(recv, 1, 4) == hex.hexf("DF650402") then
                log.output("detected CNSv2:", hex.hexify(recv));
                self.info.model = "v2"
                self._is_cnsv2 = true
            elseif recv and string.sub(recv, 1, 4) == hex.hexf("DF650410") then
                log.output("detected CNSv1:", hex.hexify(recv));
                self._is_cnsv1 = true
            end
    end)
    
        break
    until false
end

function t.mt:finalize()
    log.output("token-cns-oberthur:finalize():", self.userType)
    utility.forget_token_changed(self, "cache")
end

function t.mt:add_info_cns()
    log.output('token-cns-oberthur:add_info_cns(): probing CNS fileSystem...')
    
    local unique_name_serial_found
    if self._uniquereadernames_cache_enabled then
        log.output('token-cns-oberthur:add_info_cns(): uniquereadername: trying cached serial number...')
        local unique_name_serial = utility.cache_read(self.reader_name, "unique_name_serial", self._AvoidUseLastUpdate, self._umcachepath)
        if type(unique_name_serial) == "string" then
            self.info.serialNumber = unique_name_serial
            unique_name_serial_found = true
            log.output('token-cns-oberthur:add_info_cns(): uniquereadername: unique_name_serial:', unique_name_serial)
        end
    end
    
    if not unique_name_serial_found then
    
        self._use_main_pin_sm = false
        local pcRes = pcall(function() return self.cns_hcard:select(hexf('3F0010001003')) end )
        if not pcRes then
            pcRes = pcall(function()
                -- carta modificata per POSTECOM: usa il SM anche per MAIN pin e puk
                self.cns_hcard:select(hexf('3F0010001010'))
                self._use_main_pin_sm = true
                end )
        end
        if not pcRes then
            log.output('token-cns-oberthur:add_info_cns(): Serial Number file not found...')
            self.info.serialNumber = '0000000000000000'
        else
            self.info.serialNumber = self.cns_hcard:read_binary(0,16)
        end
        
        if self._uniquereadernames_cache_enabled then
            log.output('token-cns-oberthur:add_info_cns(): uniquereadername: caching unique_name_serial:', self.info.serialNumber)
            utility.cache_write(self.reader_name, "unique_name_serial", self.info.serialNumber, self._umcachepath)
        end
    end
    
    if not self._mobile_enabled then
        log.output('token-cns-oberthur:add_info_cns(): detecting CNS read only card...') 
        pcall(function()
            local info = self.cns_hcard:select(hexf(objCnsTmpl.GetCNSCertTemplate().path), true)
            -- log.output('token-cns-oberthur:add_info_cns(): finfos:', utility.repr(info), string.byte(info.ac, 2))
            if info and info.ac and string.len(info.ac) > 2 and string.byte(info.ac, 2) == 255 then
                log.output('token-cns-oberthur:add_info_cns(): detected CNS read only card!')
                self.info.ulMinPinLen = math.max(self.info.ulMinPinLen, 5)
                self._cns_read_only = true
                log.output('token-cns-oberthur:add_info_cns(): ulMinPinLen set to:', self.info.ulMinPinLen)
            end
        end)
    end
    -- self.cns_info = {
        -- cert_valid      = false,
        -- key_valid       = false
    -- }
    -- pcall (function()
        -- self.cns_hcard:select(hexf(objCnsTmpl.GetCNSCertTemplate().path))
        -- local certVal = self.cns_hcard:read_binary(0, 1)
        -- self.cns_info.cert_valid = (string.byte(certVal, 1) == 48) -- hex 30
    -- end)
    -- log.output('add_info_cns(): certificate valid:', self.cns_info.cert_valid)
    -- pcall (function()
        -- self.cns_hcard:select(hexf(objCnsTmpl.GetCNSPubKeyTemplate().path))
        -- local pubKeyVal = self.cns_hcard:read_record(1, 4, 3)
        -- self.cns_info.key_valid = ( 
                        -- (string.byte(pubKeyVal, 1) == 16 or string.byte(pubKeyVal, 1) == 17) -- hex 10, 11
                        -- and string.byte(pubKeyVal, 3) ~= 255 -- hex FF
                        -- )
    -- end)
    -- log.output('add_info_cns(): key valid:', self.cns_info.key_valid)
end

function t.mt:update_free_mem(info)
    log.output("update_free_mem():")
    
    if not info then
        return
    end
    local pcRes, theErrorT =  pcall(function()
        local apdu = hex.hexf("80CADF6405")
        if self._is_cnsv2 then
            apdu = hex.hexf("80CADF6406")
        end
        local recv = self:send_cached_apdu(apdu, true)
    
        -- ans: DF 64 XX + <spazio residuo in due bytes>
        if recv then
            local v = string.sub(recv, 4, -3)
            v = string.rep("\0", 4 - string.len(v) ) .. v
            info.ulFreePublicMemory = bin.unpack("%>%L",v )
            info.ulFreePrivateMemory = self.info.ulFreePublicMemory
            log.output("oberthur token free space:", info.ulFreePublicMemory);
        end
    end)
    if not pcRes then
        log.output('update_free_mem(): error:', debug.traceback( theErrorT))
    end
end

function t.is_ddna(name)
    return string.find(name, "digital-dna", 1, true)
                or string.find(name, "digitaldna", 1, true)
                or string.find(name, "digital dna", 1, true)
end


function t.mt:get_info()
    log.output("get_info():");
    if not self.info then
        log.output("get_info(): first call");
        self.info = {
            label = 'CryptoCard',
            manufacturerID = 'IDEMIA',
            model = 'Cosmo ID ONE',
            serialNumber = '0000000000000000',
            flags = CKF.RNG + CKF.LOGIN_REQUIRED + CKF.TOKEN_INITIALIZED, -- CKF.USER_PIN_INITIALIZED is added by add_info_ds
            ulMaxSessionCount = CK.EFFECTIVELY_INFINITE,
            ulSessionCount = 0,
            ulMaxRwSessionCount = CK.EFFECTIVELY_INFINITE,
            ulRwSessionCount = CK.UNAVAILABLE_INFORMATION,
            ulMaxPinLen = self.ulMaxPinLen_HW,
            ulMinPinLen = 4,
            ulTotalPublicMemory = 65535,
            ulFreePublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulTotalPrivateMemory = 65535,
            ulFreePrivateMemory = CK.UNAVAILABLE_INFORMATION,
            hardwareVersion = { major=0, minor=0},
            firmwareVersion = { major=0, minor=0},
            utcTime = '0000000000000000',
            supportsPinpolicy=true,
        }
        
        if self._pinpad_hw then
            log.output("self._pinpad_hw==true, PROTECTED_AUTHENTICATION_PATH: active!")
            self.info.flags = self.info.flags + CKF.PROTECTED_AUTHENTICATION_PATH
        end
    
        if self.cfg["odefaultvendor"] then
            self.info.manufacturerID = string.sub(self.cfg["odefaultvendor"], 1, 32)
        end
        if self.cfg["odefaultmodel"] then
            self.info.model = string.sub(self.cfg["odefaultmodel"], 1, 16)
        end
        self:add_info_cns()
        self:add_info_ds()

        local s = md.sha256()
        s:update(self.info.serialNumber .. "aahsgdhj" .. "ryuw983894kcjcn2" .. "aloijs830" .. "alqoj93sj65vn,ufh")
        self._mk = s:final()
    
        log.output("get_info(): mk:", hex.hexify(self._mk))
    
        self:init_pin_policy()
        
        self._schedule_update_retry_counters=true
        -- self:update_free_mem(self.info)
        -- self:_update_retry_counters()
        
        local label = string.lower(self.info.label)
        local reader_name = string.lower(self.reader_name or "")
        log.output("get_info(): current label:", label)
        log.output("get_info(): current reader_name:", reader_name)
        if t.is_ddna(reader_name) or t.is_ddna(label) then
            
            log.output("get_info(): detected Digitla DNA, overriding token infos...");
            -- if string.find(label, "digital-dna", 1, true) 
                -- or string.find(label, "digitaldna", 1, true)
                -- or string.find(label, "digital dna", 1, true)
                -- then
                -- self.info.label = "DigitalDNA " .. self.info.serialNumber
            -- end
            self.info.manufacturerID = "Bit4id"
            -- self.info.model = "DigitalDNA"
        end
        
        -- NOTA: lasciare manufacturerID a questi valori
        -- cambiare valore solo in caso di cambio di versione carta
        -- alcuni clienti usano questi valori per il detect del tipo di carta
        if self._is_cnsv2 then
            self.info.manufacturerID = "IDEMIA"
            self.info.ulTotalPublicMemory  = 128000
            self.info.ulTotalPrivateMemory = 128000
        elseif self._is_cnsv1 then
            self.info.manufacturerID = 'Oberthur Technologies'
        end
        
        
        log.output("get_info(): self.ds_info.manufacturerID: ", self.ds_info.manufacturerID)
        log.output("get_info(): self.ds_info.model: ", self.ds_info.model)
        
        self.info.manufacturerID = self.ds_info.manufacturerID or self.info.manufacturerID
        self.info.model = self.ds_info.model or self.info.model
        
        log.output("get_info(): 1 self.info.label: ", self.info.label)
        log.output("get_info(): 1 self.info.manufacturerID: ", self.info.manufacturerID)
        log.output("get_info(): 1 self.info.model: ", self.info.model)
        
        local licValid, license
        licValid, license = licensing.is_licensed(self, self.info.serialNumber)
        if licValid and license and 
           (license.card_type == nil or license.card_type == 0 or license.card_type == licensing.card_types.oberthur ) then
            self._license_valid = license
            self._ecc_license_valid = license
            self.info.is_licensed = true
            
            self.info.model = string.sub(self.info.model .. " (L)", 1, 16)
            if license and license.pin_behavior then
                log.output("get_info(): license specify PIN behavior:", license.pin_behavior)
                if license.pin_behavior == 1 then
                    self.cfg["dspiniscnspin"] = "true"
                    self.cfg["dspinusegui"] = "false"
                elseif license.pin_behavior == 2 then
                    self.cfg["dspiniscnspin"] = "false"
                    self.cfg["dspinusegui"] = "true"
                elseif license.pin_behavior == 66 then
                    self.puk_not_modifiable=true
                    self.info.ulMaxPinLen=8
                    self.info.ulMinPinLen=6
                elseif license.pin_behavior == 68 then
                    self.info.ulMaxPinLen=8
                    self.info.ulMinPinLen=6
                end
            end
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
            if license and license.disable_ds_app then
                log.output("get_info(): license.disable_ds_app is set: setting self._ignore_ds_pin=true")
                ds_info._ignore_ds_pin = true
            end
        end

        log.output("get_info(): 2 self.info.label: ", self.info.label)
        log.output("get_info(): 2 self.info.manufacturerID: ", self.info.manufacturerID)
        log.output("get_info(): 2 self.info.model: ", self.info.model)
        
        if self._custom_atr then
            log.output("get_info(): temporary license not allowed for custom atr")
        else

            if not licValid then
                local tempLicensEnabled
                log.output("get_info(): temporary license?")
                local _grace_time = os.time( { year = 2030, month = 10, day = 1, })
                
                local reader_name = string.lower(self.reader_name or "")
                if t.is_ddna(reader_name) then
                    log.output("get_info(): forcing temporary license on DDNA reader:", reader_name)
                    tempLicensEnabled = true
                elseif not self._is_cnsv2 then
                    log.output("get_info(): temporary license enabled!")
                    tempLicensEnabled = true
                elseif os.difftime( os.time(), _grace_time) < 0 then
                    log.output("get_info(): temporary license for CNSv2 enabled")
                    self.info.model = "v2-T"
                    tempLicensEnabled = true
                end
                
                if tempLicensEnabled then
                    log.output("get_info(): enabling temporary license...")
                    local LB = "(T)"
                    self.info.model = string.sub(self.info.model .. LB, 1, 16)
                    self._license_valid = {version=0, card_type=licensing.card_types.oberthur}
                end
            end
        end
        
        
        log.output("get_info(): self._license_valid:", self._license_valid)
        log.output("get_info(): self._ecc_license_valid:", self._ecc_license_valid)
        
        if self._license_valid then
            log.output("get_info(): _license_valid: enabling RSA 2048 mechanisms...")
            for i, v in self.mechanisms do
                if v.ulMaxKeySize == 1024 then -- detects RSA from 1024bit value...
                    v.ulMaxKeySize = 2048
                end
            end
        end
        
        if self.caching_on_valid_license_only and not licValid and self:cache_enabled() then
            log.output("get_info(): disabling cache for unlicensed card and clearing existing cache...")
            self.cfg["fastread"] = "false"
            self.cfg["ofastread"] = "false"
            self.cfg["caching"] = "false"
            self.cfg["ocaching"] = "false"
            self.cfg["avoiduselastupdate"] = "false"
            self.cfg["oavoiduselastupdate"] = "false"
            utility.cache_write(self.info.serialNumber, nil, nil, self._umcachepath)
        end
        
        if type(self.cfg["odefaultlabel"]) == "string" then
            self.info.label = string.sub(self.cfg["odefaultlabel"], 1, 32)
        end
        if type(self.cfg["odefaultmanufacturer"]) == "string" then
            self.info.manufacturerID = string.sub(self.cfg["odefaultmanufacturer"], 1, 32)
        end
        if type(self.cfg["odefaultmodel"]) == "string" then
            self.info.model = string.sub(self.cfg["odefaultmodel"], 1, 16)
        end
        
        if not self._ecc_license_valid then
            log.output("get_info(): not _ecc_license_valid: disabling ECC support for unlicensed card")
            local to_disable = {CKM.EC_KEY_PAIR_GEN, CKM.ECDSA, CKM.EDDSA, CKM.EC_EDWARDS_KEY_PAIR_GEN, CKM.CURVE25519_CRYPTO_BOX, }
            for i, v in to_disable do
                log.output("get_info(): disabling CKM:", v)
                self.mechanisms[v] = nil
            end
        end
        
        log.output("get_info(): 3 self.info.label: ", self.info.label)
        log.output("get_info(): 3 self.info.manufacturerID: ", self.info.manufacturerID)
        log.output("get_info(): 3 self.info.model: ", self.info.model)
    
        self.info.has_pss_qscd = self:is_dsx_licensed()
    end
    
    if not self.DSX_DERIVED_KEY then
        log.output('get_info(): calculating DSX_DERIVED_KEY...')
        local DSX_MK = hex.hexf("aaac".."5fa".."5ba8".."897".."99".."958".."000".."d6d".."555".."4b4".."f2f".."f3".."426".."67013".."f24".."ccc".."fe9".."8ea".."999".."b41".."22")
        self.DSX_DERIVED_KEY = hmac.derive_keys(DSX_MK, self.info.serialNumber)
        DSX_MK = nil
        self.DSX_DERIVED_KEY_AUTH = hmac.hmac_sha256(self.DSX_DERIVED_KEY, "\0\0\0\1")
        self.DSX_DERIVED_KEY_AUTH = string.sub(self.DSX_DERIVED_KEY_AUTH, 1, 16) .. string.sub(self.DSX_DERIVED_KEY_AUTH, 1, 8)
        collectgarbage()
    end
    
    log.output("get_info(): self._schedule_update_retry_counters:", self._schedule_update_retry_counters);
    if self._schedule_update_retry_counters then
        self._schedule_update_retry_counters = false
        self:_update_retry_counters()
        self:update_free_mem(self.info)
    end

    return self.info
end

function t.mt:get_mechanisms()
    local info = self:get_info()
    return self.mechanisms
end

function t.mt:_update_retry_counters()
    log.output("_update_retry_counters():")
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
                local pinRetry, pinRetryMax, pukRetry, pukRetryMax = self.cns_hcard:get_pin_puk_status(self.pinRetry, self.pukRetry)
                if pinRetryMax >= 3 and pukRetry == pinRetryMax then
                    -- BES: DIRT FIX: when the PUK retry counters is equal to pinRetryMax
                    -- we assume PUK max retry counter is same PIN max retry counter
                    -- Side effect: when pukRetryMax is 8 and pukRetry is same as pinRetryMax, the PUK
                    -- will looks OK... 
                    log.output("get_pin_puk_status, PUK prev/cur retry max:", pukRetryMax, pukRetry);
                    pukRetryMax = pukRetry
                end
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

function t.mt:cache_enabled()
    return utility.cache_can_use() and self.cfg["fastread"]=='true' or self.cfg["ofastread"]=='true'
end

function t.mt:cache_clear()
    if self:cache_enabled() then
        log.output('removing whole cache...')
        -- elimina tutta la cache statica del token
        local info = self:get_info()
        log.output('removing cache for serial', info.serialNumber)
        utility.cache_write(info.serialNumber, nil, nil, self._umcachepath)
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
                            self.cns_hcard:verify_pin_cns(self.cached_main_pin, false, false, self.ds_info.sm_use2_enc, self.ds_info.sm_use2_sig)
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


function t.mt:verify_pin(pin, userType, contextual_obj)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk = false
    local result
    if userType == CKU.SO then 
        ispuk = true
    end
    log.output("verify_pin()", pin, userType, ispuk, contextual_obj)
    
    local info = self:get_info()
    local rv
    
    if self._pinpad_hw and not pin and (userType == CKU.USER or userType == CKU.SO) then
    
        local pin_id = ispuk and self.cns_hcard.BSO_CNS_PUK or self.cns_hcard.BSO_CNS_PIN
        local pin_op = ispuk and PINPAD_CTL_PUK or PINPAD_CTL_PIN
        result = pcsc.pinpad_ctl(
            PINPAD_CTL_VERIFY + pin_op,
            self.cns_hcard.card,
            self.reader_name,
            pin_id)
        log.output("verify_pin(): pinpad_verify(DS): result=", result)
        if result == 0 then
            self.cached_main_pin = nil
            self.userType = userType
            self.cached_ds_pin = nil
            return CKR.OK
        end
    else
        
        rv, pin = self:check_pin_value(pin, false, ispuk)
        if rv ~= CKR.OK then
            return rv
        end
        
        self._schedule_update_retry_counters = true
        if not self._mobile_enabled then
            -- on mobile avoids checking cache at each login
            self:check_clear_cache(nil, true, true)
        end
        
        if userType == CKU.CONTEXT_SPECIFIC then
            if self.ds_info._ignore_ds_pin then
                log.output("verify_pin(CKU_CONTEXT_SPECIFIC): _ignore_ds_pin is set")
                result = 0
            else
                local pcRes = pcall(function() return self.cns_hcard:select(hexf(self.ds_info.path_root .. self.ds_df_priv )) end )
                result = self.cns_hcard:verify_pin_ds(pin, self.ds_info.sm_use_enc, self.ds_info.sm_use_sig)
                log.output("verify_pin(): verify_pin_ds(): result=", result)
            end
            
            if result == 0 then
                self.contextual_pin_verified = true
                self.contextual_pin_verified_cache = pin
                return CKR.OK
            end
        else
            result = self.cns_hcard:verify_pin_cns(pin, ispuk, false, self.ds_info.sm_use2_enc, self.ds_info.sm_use2_sig)
            log.output("verify_pin(): result=", result)
            if result == 0 then
                self.cached_main_pin = pin
                self.userType = userType
                self.cached_ds_pin = nil
                return CKR.OK
            end
        end
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
    self.cached_ds_pin = nil
end

function t.mt:init_pin_policy(pinPolicy)
    log.output("init_pin_policy()")

    local pcRes, theErrorT = pcall(function()
        local pcRes, theErrorT
        self.pinRetry = 3 -- default
        local pinPolicyPath = hex.hexf(self.ds_info.path_root .. self.ds_df_pub .. 'FFF0')
        local curPinLen = string.len(pin or "")
        local pcRes, theErrorT
        if type(pinPolicy) ~= "string" then
            pcRes, theErrorT = pcall( function()
                pinPolicy = self:read_cached_file(pinPolicyPath, 0, -1, true, true)
                if  type(pinPolicy) ~= "string" or string.len(pinPolicy) == 0 then
                    log.output("init_pin_policy(): not exists?")
                    error("init_pin_policy(): not exists?")
                end
            end) 
        else
            pcRes=true
        end
        if pcRes then
        
            -- struct format
            -- minLen: 1 byte
            -- maxLen: 1 byte
            -- complexityLevel: 1 byte, 0=disable, 1=only digits, 2=only digits and alpha, 2=
            -- pinHistory: 1 byte, 0=disable
            -- pinRetry: 1 byte
            
            -- adjacent   1 byte  allwoed repet|max appear
            -- allow numeric       0x80 | min
            -- allow alpha         0x80 | min
            -- allow symbols       0x80 | min
            -- allow extraascii    0x80 | min


            local pin_policy = string.sub(pinPolicy, 1, 10)
            pin_policy = pin_policy .. string.rep("\0", 10- string.len(pin_policy))
            local minLen, maxLen, complexityLevel, pinHistory, pinRetry = bin.unpack("%B%B%B%B%B", pin_policy)

            log.output("init_pin_policy(): minLen, maxLen, complexityLevel, pinHistory, pinRetry:", minLen, maxLen, complexityLevel, pinHistory, pinRetry)
            
            if minLen > 0 and curPinLen then
                self.info.ulMinPinLen=minLen
            end
            if maxLen > 0 then
                self.info.ulMaxPinLen=maxLen
            end
            local complexityLevel_f = bin.flags(complexityLevel)
            self.complexityLevel = (complexityLevel_f - bin.flags(128+64)).asnumber
            if self.complexityLevel > 3 and string.len(pinPolicy) >= 10 then
                local extPinPolicy = string.sub(pinPolicy, 6, -1)
                local adjacent, numeric, alpha, symbols, nonascii = bin.unpack("%B%B%B%B%B", extPinPolicy)
                self.max_repeat_same_char = (bin.flags(adjacent) * bin.flags(240)).asnumber / 16 -- hi nibble
                self.max_same_char = (bin.flags(adjacent) * bin.flags(15)).asnumber -- low nibble
                self.enable_numeric = numeric
                self.enable_alpha = alpha
                self.enable_symbols = symbols
                self.enable_nonascii = nonascii
                log.output(string.format(
                    "init_pin_policy() extended: max_repeat_same_char=%d, max_same_char=%d, enable_numeric=0x%02X, enable_alpha=0x%02X, enable_symbols=0x%02X, enable_nonascii=0x%02X", 
                    self.max_repeat_same_char, self.max_same_char, self.enable_numeric, self.enable_alpha, self.enable_symbols, self.enable_nonascii)
                )
            end
            self.pinUnchangable = complexityLevel_f[bin.flags(128)]
            self.pinNotUnlockable = complexityLevel_f[bin.flags(64)]
            self.pinHistory = pinHistory
            self.pinRetry = pinRetry
            self.pin_policy_value = pin_policy
            if self.pinRetry == 0 then
                self.pinRetry = 3
            end 

        else
            log.output("init_pin_policy(): read error=", debug.traceback( theErrorT))
        end
    end)
    if not pcRes then
        log.output("init_pin_policy(): generic error=", debug.traceback( theErrorT))
    end
end

function t.mt:check_pin_policy(newPin)
    log.output('check_pin_policy()', newPin, isPuk)
    local curPinLen = string.len(newPin or "")
    
    if curPinLen > self.info.ulMaxPinLen then
        log.output('check_pin_policy(): newPin too long')
        return CKR.PIN_LEN_RANGE
    end
    if curPinLen < self.info.ulMinPinLen then
        log.output('check_pin_policy(): newPin too short')
        return CKR.PIN_LEN_RANGE
    end

    if self.complexityLevel then
        if self.complexityLevel == 4 then
            if not utility.check_ext_policy(newPin, 
                self.max_same_char, 
                self.max_repeat_same_char,
                self.enable_numeric,
                self.enable_alpha,
                self.enable_symbols,
                self.enable_nonascii) then
                log.output('check_pin_policy(): newPin extended policy do not match!')
                return CKR.PIN_INVALID
            end
        elseif self.complexityLevel == 3 then
            -- upper & lower & numeric & symbols
            local level = 0
            if string.find(newPin, "[%d]") then level = level +1 end
            if string.find(newPin, "[%u]") then level = level +1 end
            if string.find(newPin, "[%l]") then level = level +1 end
            if string.find(newPin, "[%p]") then level = level +1 end
            if level < 3 then
                log.output('check_pin_policy(): newPin must contain at least 3 of: upper , lower , numeric , symbols');
                return CKR.PIN_INVALID
            end
        elseif self.complexityLevel == 2 then
            if not string.find(newPin, "[%d]") or not string.find(newPin, "[%a]") then
                log.output('check_pin_policy(): newPin must contain alpha + numeric');
                return CKR.PIN_INVALID
            end
        elseif self.complexityLevel == 1 then
            -- at least alpha + numeric
            if string.find(newPin, "[^%d]") then
                log.output('check_pin_policy(): newPin must contain only digits');
                return CKR.PIN_INVALID
            end           
        else
            -- any value is ok
        end
    end
    
    local historyList = self:manage_pin_history()
    
    if historyList and table.getn(historyList) > 0 then
        local sha = md.sha1()
        sha:update(newPin)
        local hNewPin = sha:final()
        
        for i=1,table.getn(historyList) do
            log.output('check_pin_policy(): history entry:', i, hex.hexify(historyList[i]));
            if historyList[i] == hNewPin then
                log.output('check_pin_policy(): pin value in history');
                return CKR.PIN_INVALID
            end
        end
    end
    return CKR.OK
end

function t.mt:manage_pin_history(newHistoryList)
    log.output('manage_pin_history():', repr(newHistoryList))
    local valueHistoryPath
    local historyLen
    local historyValue
    local historyList
    local newHistory
    if self.pinHistory and self.pinHistory >0 then
        valueHistoryPath = hex.hexf(self.ds_info.path_root .. self.ds_df_pub .. 'FFF1')
        historyLen = self.pinHistory
    end
    
    if valueHistoryPath then
        if newHistoryList then
            newHistory = table.concat(newHistoryList, "")
            newHistory = newHistory .. string.rep("\0", (historyLen * 20) - string.len(newHistory))
            newHistory = string.sub(newHistory, 1, historyLen * 20)
            log.output('manage_pin_history(): newHistory:',  hex.hexify(newHistory))
        end
        -- read/update value history
        local pcRes, theErrorT = pcall(function()
            log.output('manage_pin_history(): -- read/update value history')
            local fInfo = self.cns_hcard:select(valueHistoryPath, true)
            if newHistory then
                newHistory = string.sub(newHistory, 1, math.min(fInfo.size, string.len(newHistory)))
                log.output('manage_pin_history(): updating actual newHistory:',  hex.hexify(newHistory))
                self.cns_hcard:mupdate_binary(0, newHistory)
                log.output('manage_pin_history(): update done')
                historyValue = newHistory
            else
                historyValue = self.cns_hcard:mread_binary(0, math.min(fInfo.size, historyLen * 20))
            end
        end)
        if not pcRes then
            log.output('manage_pin_history() error:', theErrorT)
        end
        if pcRes and historyValue then
            historyList = {}
            for i=1,string.len(historyValue),20 do
                table.insert(historyList, string.sub(historyValue, i, i-1+20))
            end
        end
    end
    return historyList
end

local function table_insert_unique(t, value)
    for i=1,table.getn(t) do
        if t[i] == value then
            return
        end
    end
    table.insert(t, 1, value)
end

function t.mt:update_pin_history(oldPin, newPin)
    log.output('update_pin_history(oldPin, newPin): ', oldPin, newPin);
    local historyList = self:manage_pin_history()
    if historyList then
        local sha = md.sha1()
        sha:update(newPin)
        local hnewPin = sha:final()
        local sha = md.sha1()
        sha:update(oldPin)
        local holdPin = sha:final()
        
        table_insert_unique(historyList, holdPin)
        table_insert_unique(historyList, hnewPin)
        self:manage_pin_history(historyList)
    end
end



function t.mt:check_pin_value(newPin, check_value, isPuk)
    log.output('check_pin_value():', newPin, check_value, isPuk);
    local rv = CKR.OK
    local info = self:get_info()
    local pcRes, theErrorT = pcall(function()
        if type(newPin) == "string" then
            if check_value then
                if (string.len(newPin) < info.ulMinPinLen or string.len(newPin) > info.ulMaxPinLen) then
                    log.output('token-cns check_pin_value(): invalid newPin len:', string.len(newPin),
                        "ulMinPinLen:", info.ulMinPinLen, "ulMaxPinLen:", info.ulMaxPinLen)
                    rv = CKR.PIN_LEN_RANGE
                    return
                end
            end
            
            if string.find(newPin, "[^%d]") or string.len(newPin) > self.ulMaxPinLen_HW then
                sha = md.sha1()
                sha:update(newPin)
                d = sha:final()
                pinNum = bin.unpack("%>%L", string.sub(d, 1, 4))
                newPin = string.sub(tostring(math.mod(pinNum, 99999999)), 1, info.ulMaxPinLen_HW )
                log.output('token-cns check_pin_value(): non numeric pin patched: pinNum: ', pinNum, 'patched newPin:', newPin)
            end
        end
    end)
    if not pcRes then
        log.output('token-cns check_pin_value error:', theErrorT)
        rv = CKR.FUNCTION_FAILED
    end
    return rv, newPin
end

function t.mt:change_pin(oldPin, newPin)
    local newPinOrig = newPin
    local oldPinOrig = oldPin
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk = false
    if self.userType == CKU.SO then ispuk = true end
    local pcRes, result
    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-cns change_pin(): oldPin:', oldPin, 'newPin:', newPin)
    
    if ispuk and self.puk_not_modifiable then
        log.output('token-cns change_pin(): PUK not modifiable!')
        return CKR.PIN_LEN_RANGE
    end
    local rv
    
    if not ispuk and self.pinUnchangable then
        log.output('token-cns change_pin(): PIN not modifiable by policy!')
        return CKR.TOKEN_WRITE_PROTECTED
    end
    
    local pinpadPUK = "***pinpadPUK"
    if self._pinpad_hw and (oldPin == nil or oldPin == pinpadPUK) then  -- custom behavior to change the PUK
    
        ispuk = oldPin == pinpadPUK or ispuk
        local pin_cns_id = ispuk and self.cns_hcard.BSO_CNS_PUK or self.cns_hcard.BSO_CNS_PIN
        local pin_cns_op = ispuk and PINPAD_CTL_PUK or PINPAD_CTL_PIN

        pcRes = pcall(function() return self.cns_hcard:select(hexf('3F00')) end )
        result = pcsc.pinpad_ctl(
                    PINPAD_CTL_CHANGE + pin_cns_op,
                    self.cns_hcard.card,
                    self.reader_name,
                    pin_cns_id)
        log.output("change_pin(): pinpad_change(CNS): result=", result)

    else

        pcall(function()
            self:init_pin_policy()
        end)
        
        if (not ispuk and self.pinHistory and self.pinHistory >0)
            and type(oldPin) == "string" and oldPin == newPin then
            log.output('token-cns change_pin(): new and old values must differ')
            return CKR.PIN_INVALID
        end
        
        rv, oldPin = self:check_pin_value(oldPin, false, ispuk)
        if rv ~= CKR.OK then
            return rv
        end

        rv, newPin = self:check_pin_value(newPin, true, ispuk)
        if rv ~= CKR.OK then
            return rv
        end
        
        if not ispuk then
            rv = self:check_pin_policy(newPinOrig)
            if rv ~= CKR.OK then
                log.output('check_pin_value(): newPin rejected');
                return rv
            end
        end
        
        self._schedule_update_retry_counters = true
        
        log.output('token-cns change_pin(): cambio pin CNS...')
        pcRes = pcall(function() return self.cns_hcard:select(hexf('3F00')) end )
        pcRes, result = pcall(function() 
                return self.cns_hcard:change_pin_cns(oldPin, newPin, ispuk, self.ds_info.sm_use2_enc, self.ds_info.sm_use2_sig)
            end)
    end
     
    if self.ds_info ~= nil and not self.ds_info._ignore_ds_pin and pcRes and result == 0 then
        local changeDsPin = false
        while true do -- simulazione del goto...
            local res, pinDs, newpinDs
            if self.cfg["dspinusegui"] == 'true' and self.request_plugin_valid then
                log.output('token-cns change_pin(): requesting DS pin using GUI...')
                res, pinDs, newpinDs = self:gui_change_pin_ds(ispuk)
                log.output('token-cns change_pin(): DS request result:', res, pinDs, newpinDs)
                if res ~= 1 then
                    log.output('change_pin(): cancelled by plugin with code:', res)
                    return CKR.FUNCTION_FAILED
                else
                    changeDsPin = true
                end
            elseif self.cfg["dspiniscnspin"] == 'true' or 
                self.cfg["dspinusegui"] == 'sign' then
                log.output('token-cns change_pin(): main PIN is DS PIN...')
                changeDsPin = true
                pinDs, newpinDs = oldPin, newPin           
            end
            
            if changeDsPin then
                log.output('token-cns change_pin(): cambio pin DS...')
                pcRes = pcall(function() return self.cns_hcard:select(hexf(self.ds_info.path_root .. self.ds_df_priv )) end )
                pcRes, result = pcall(
                    function()
                        return self.cns_hcard:change_pin_ds(pinDs, newpinDs,
                            self.ds_info.sm_admin_enc, self.ds_info.sm_admin_sig,
                            ispuk)
                    end)
                if result ~= 0 then
                    -- ripristina il vecchio pin principale
                    log.output('token-cns change_pin(): errore ',
                                result,
                                ' cambiando il pin DS!', 
                                'Il pin CNS verr