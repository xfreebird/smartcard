 RSA-Decrypt
            log.output('sign_buffer_dsx(): using RSA-Decrypt mode on ' .. obj.path .. '/' .. obj.kid)
            local pDataPadded
            if string.len(pData) == keyBytes then -- firma raw
                pDataPadded = pData
            else
                pDataPadded = '\0\1'..string.rep('\255',(keyBytes-3)-string.len(pData))
                                ..'\0'..pData
            end
            
            local contextual_pin = nil
            local sm_enc, sm_sig = nil, nil

            local sm_enc_local, sm_sig_local = self:get_dsx_sm_keys(obj.num)
            
            log.output('sign_buffer_dsx(): alw_verify_pin:', self.ds_info.alw_verify_pin)
            log.output('sign_buffer_dsx(): use_sm:', self.ds_info.use_sm)

            if self.ds_info.use_sm and self.ds_info.sm_enc ~= nil and self.ds_info.sm_sig ~= nil then
                sm_enc = self.ds_info.sm_enc
                sm_sig = self.ds_info.sm_sig
            end
            
            local rv
            rv, contextual_pin = self:check_ask_ds_pin(obj, sm_enc, sm_sig)
            if rv ~= CKR.OK then return rv end
            
            self.contextual_pin_verified = false
            
            pcRes, result = pcall(function()
                return self.cns_hcard:rsa_extended(
                    pDataPadded,
                    obj.path, obj.kid,
                    sm_enc_local, sm_sig_local)
                end)
            if not pcRes then
                log.output('sign_buffer_dsx(): rsa_extended error:', debug.traceback(result))
            end
            local last_sw = self.cns_hcard.last_sw
            local pin_required = last_sw == hexf('6982')
            
            if not pcRes and pin_required and contextual_pin then
                log.output('sign_buffer_dsx(): pin_required, verifying DS PIN and retry...')
                result = self.cns_hcard:verify_pin_ds(contextual_pin, sm_enc, sm_sig)
                if result == 0 then
                    pcRes, result = pcall(function()
                        return self.cns_hcard:rsa_extended(
                            pDataPadded,
                            obj.path, obj.kid,
                            sm_enc_local, sm_sig_local)
                        end)
                    last_sw = self.cns_hcard.last_sw
                end
            end
            
            local pin_incorrect = string.sub(last_sw, 1, 1) == hexf('63')
            local pin_locked = last_sw == hexf('6983')
            if not pcRes then
                log.output('sign_buffer_dsx(): rsa_extended error:', debug.traceback(result))
                if contextual_pin and (pin_incorrect or pin_locked ) then
                    log.output('sign_buffer_dsx(): contextual PIN was incorrect or locked!')
                    self.cached_ds_pin = nil
                    self.contextual_pin_verified = false
                    if pin_incorrect then return CKR.PIN_INCORRECT
                    elseif pin_locked then return CKR.PIN_LOCKED
                    else return CKR.FUNCTION_FAILED
                    end
                end
            end
            if pcRes then
                self.contextual_pin_verified = false
                return CKR.OK, result
            elseif self.cfg["dspiniscnspin"]~='true' and
                    not self.contextual_pin_verified and
                    last_sw == hexf('6982') then
                log.output('sign_buffer_dsx(): requesting contextual login...')
                return CKR.USER_NOT_LOGGED_IN
            end
            return CKR.FUNCTION_FAILED
        end
    end
    log.output('sign_buffer_dsx(): unexpected: should never reach this part!')
    return CKR.FUNCTION_FAILED

end


function t.mt:sign_buffer_ecdsa_dsx(hKey, pMechanism, pData, allocated_space)
    log.output('sign_buffer_ecdsa_dsx(): ', hKey)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('sign_buffer_ecdsa_dsx(): specified handle invalid: ', hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('sign_buffer_ecdsa_dsx(): ERROR: non private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    if obj[CKA.KEY_TYPE] ~= eCK.OBJECT_CLASS(CKK.ECDSA) then
        log.output('sign_buffer_ecdsa_dsx(): ERROR: non ECDSA key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    
    local keyBytes = obj.curve.keysize * 2 -- r + s
    
    if not self._license_valid then
        log.output('sign_buffer_ecdsa_dsx(): ERROR: invalid license for ECDSA key type')
        return CKR.KEY_FUNCTION_NOT_PERMITTED
    end
    
    log.output('sign_buffer_ecdsa_dsx(): trimming data to key size:', hex.hexify(pData or ''))
    pData = ecdhlib.trunk_to_curve_order(obj.curve, pData)
    log.output('sign_buffer_ecdsa_dsx(): trimmed data to key size:', hex.hexify(pData or ''))
    
    local pcRes, result
    
    if allocated_space==nil then
        return CKR.OK, keyBytes
    else
        if type(obj.kid) == 'function' then
            local rv = obj.kid(self, hKey, CKA.CLASS, false)
            if rv ~= CKR.OK then return rv end
        end
        pcall(function() 
            self:auto_verify_pin_main()
        end)
    
        log.output('sign_buffer_ecdsa_dsx(): using PSO CDS mode on ' .. obj.path .. '/' .. obj.kid)

        local contextual_pin = nil
        local sm_enc, sm_sig = nil, nil

        local sm_enc_local, sm_sig_local = self:get_dsx_sm_keys(obj.num)
        
        log.output('sign_buffer_ecdsa_dsx(): alw_verify_pin:', self.ds_info.alw_verify_pin)
        log.output('sign_buffer_ecdsa_dsx(): use_sm:', self.ds_info.use_sm)

        if self.ds_info.use_sm and self.ds_info.sm_enc ~= nil and self.ds_info.sm_sig ~= nil then
            sm_enc = self.ds_info.sm_enc
            sm_sig = self.ds_info.sm_sig
        end
        
        local rv
        rv, contextual_pin = self:check_ask_ds_pin(obj, sm_enc, sm_sig)
        if rv ~= CKR.OK then return rv end
        
        self.contextual_pin_verified = false
        
        pcRes, result = pcall(function()
            return self.cns_hcard:jsign_cds_ecdsa(obj.curve,
                pData,
                obj.path, obj.kid,
                sm_enc_local, sm_sig_local)
            end)
        if not pcRes then
            log.output('sign_buffer_ecdsa_dsx(): jsign_cds_ecdsa error:', debug.traceback(result))
        end
        local last_sw = self.cns_hcard.last_sw
        local pin_required = last_sw == hexf('6982')
        
        if not pcRes and pin_required and contextual_pin then
            log.output('sign_buffer_ecdsa_dsx(): pin_required, verifying DS PIN and retry...')
            result = self.cns_hcard:verify_pin_ds(contextual_pin, sm_enc, sm_sig)
            if result == 0 then
                pcRes, result = pcall(function()
                    return self.cns_hcard:jsign_cds_ecdsa(obj.curve,
                        pData,
                        obj.path, obj.kid,
                        sm_enc_local, sm_sig_local)
                    end)
                last_sw = self.cns_hcard.last_sw
            end
        end
        
        local pin_incorrect = string.sub(last_sw, 1, 1) == hexf('63')
        local pin_locked = last_sw == hexf('6983')
        if not pcRes then
            log.output('sign_buffer_ecdsa_dsx(): jsign_cds_ecdsa error:', debug.traceback(result))
            if contextual_pin and (pin_incorrect or pin_locked ) then
                log.output('sign_buffer_ecdsa_dsx(): contextual PIN was incorrect or locked!')
                self.cached_ds_pin = nil
                self.contextual_pin_verified = false
                if pin_incorrect then return CKR.PIN_INCORRECT
                elseif pin_locked then return CKR.PIN_LOCKED
                else return CKR.FUNCTION_FAILED
                end
            end
        end
        if pcRes then
            self.contextual_pin_verified = false
            local r, s = ecdhlib.decode_der_ecdsa_signature(result, obj.curve.keysize)
            return CKR.OK, r..s
        elseif self.cfg["dspiniscnspin"]~='true' and
                not self.contextual_pin_verified and
                last_sw == hexf('6982') then
            log.output('sign_buffer_ecdsa_dsx(): requesting contextual login...')
            return CKR.USER_NOT_LOGGED_IN
        end
        return CKR.FUNCTION_FAILED
    end
    log.output('sign_buffer_ecdsa_dsx(): unexpected: should never reach this part!')
    return CKR.FUNCTION_FAILED

end


function t.mt:generate_dsx_rsa_key_pair(pMechanism, templatePub1, templatePriv1)
    -- NOTE: DSX RSA key pair is always a Qualified DS object
    log.output('generate_dsx_rsa_key_pair():')
    
    if not self:is_dsx_licensed() then
        log.output('generate_dsx_rsa_key_pair(): DSX objects are not licensed on this card!')
        return CKR.ACTION_PROHIBITED
    end
    
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    
    local dspath = hex.hexf(self.ds_info.path_root or "1400")
    
    local templatePub = utility.clone_table(templatePub1)
    local templatePriv = utility.clone_table(templatePriv1)
    
    if templatePub[CKA.ID] then
        templatePriv[CKA.ID] = templatePub[CKA.ID]
    elseif templatePriv[CKA.ID] then
        templatePub[CKA.ID] = templatePriv[CKA.ID]
    end
    
    local isds = true -- self:is_dsx(templatePriv) -- NOTE: DSX RSA key pair is always a Qualified DS object
    local cka_label = templatePriv[CKA.LABEL] or ""
    local cka_id = templatePriv[CKA.ID]  or ""
    local cka_modulus_bit = templatePub[CKA.MODULUS_BITS] or templatePriv[CKA.MODULUS_BITS] or eCK.ULONG(2048)
    
    templatePriv[CKA.SIGN] = eCK.BBOOL(true)
    templatePriv[CKA.MODIFIABLE] = templatePriv[CKA.MODIFIABLE] or eCK.BBOOL(true)
    templatePriv[CKA.DESTROYABLE] = templatePriv[CKA.DESTROYABLE] or eCK.BBOOL(true)
    templatePriv[CKA.DECRYPT] = eCK.BBOOL(false)
    templatePriv[CKA.DERIVE] = eCK.BBOOL(false)
    templatePriv[CKA.LOCAL] = eCK.BBOOL(true)
    templatePriv[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(isds)
    
    log.output("generate_dsx_rsa_key_pair(): ", cka_label, hex.hexify(cka_id or ""))
    local info = self.info or self:get_info()
    local fs = self:read_dsx_fs()

    
    if cka_modulus_bit ~= eCK.ULONG(2048) then
        log.output('generate_dsx_rsa_key_pair(): key size invalid for DSX filesystem:', hex.hexify(cka_modulus_bit or "") )
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end

    templatePriv1[CKA.SIGN] = templatePriv1[CKA.SIGN] or eCK.BBOOL(true)
    templatePriv1[CKA.DECRYPT] = templatePriv1[CKA.DECRYPT] or eCK.BBOOL(true)
    
    local bits = 2048
    
    local free_id = t.look_for_dsx_free_id(fs)
    
    if not free_id  then
        log.output('generate_dsx_rsa_key_pair(): no more free DSX slots')
        return CKR.DEVICE_MEMORY
    end
    
    log.output("generate_dsx_rsa_key_pair(): found free_id:", free_id)
    
    local dfXX_fid = DSX_df00_fid + free_id
    local dfXX_path = dspath .. hex.hexf("%H", dfXX_fid)
    local pubkey_fid = hex.hexf("8041")
    local dfXX_pubkey_path = dfXX_path .. pubkey_fid
    
    
    -- ask DS PIN
    local contextual_pin = nil
    local res, cache_ds_pin
    log.output('generate_dsx_rsa_key_pair(): use_sm:', self.ds_info.use_sm)
    if self.ds_info.alw_verify_pin then
        if self.cfg["dspinusegui"] == 'true' and self.request_plugin_valid then
            if self.cached_ds_pin then
                contextual_pin = self.cached_ds_pin
            else
                while true do
                    res, contextual_pin, cache_ds_pin = self:gui_request_pin_ds(self.check_box_visible)
                    if res ~= 1 then
                        log.output('generate_dsx_rsa_key_pair(): cancelled by plugin with code:', res)
                        return CKR.FUNCTION_FAILED
                    end
                    self.cns_hcard:select(hexf(self.ds_info.ds_sig_path))
                    result = self.cns_hcard:verify_pin_ds(contextual_pin, self.ds_info.sm_enc, self.ds_info.sm_sig)
                    if result == 0 and cache_ds_pin then self.cached_ds_pin = contextual_pin end
                    contextual_pin = nil
                    if self:gui_show_pin_message(result, false) ~= 1 then
                        break
                    end
                end
                
            end
        elseif self.cfg["dspiniscnspin"]=='true' or self.cfg["dspiniscnspin"]=='sign' then
            log.output('generate_dsx_rsa_key_pair(): using main pin as contextual pin...')
            contextual_pin = self.cached_main_pin
        else
            log.output('generate_dsx_rsa_key_pair(): requesting contextual login since ALWAYS_AUTHENTICATE is set...')
            return CKR.USER_NOT_LOGGED_IN
        end
    end
    
    
    
    self:create_dsx_container(free_id)
    
    -- create RSA BSOs
    -- BSO RSA 2048 part 1 KID=2041
    local create_rsa_bso_apdu1 = hex.hexf("00da016e00012D83022041850862000e0fffff000886071affff1c1a101acb100807ffffffffffffffffffffffff08078f820100ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff")
    
    -- BSO RSA 2048 part 2 KID=2041
    local create_rsa_bso_apdu2 = hex.hexf("00da016e0001B583022141850842000e0fffff000886071affff1c1a101acb100807ffffffffffffffffffffffff08078f820188ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff")
    
    
    local recv = self.cns_hcard:sm_transmit2(create_rsa_bso_apdu1, self.ds_info.sm_enc, self.ds_info.sm_sig, true)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        log.output('generate_dsx_rsa_key_pair(): create_rsa_bso_apdu1 error:', hex.hexify(sw))
        return CKR.FUNCTION_FAILED
    end
    
    local recv = self.cns_hcard:sm_transmit2(create_rsa_bso_apdu2, self.ds_info.sm_enc, self.ds_info.sm_sig, true)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        log.output('generate_dsx_rsa_key_pair(): create_rsa_bso_apdu2 error:', hex.hexify(sw))
        return CKR.FUNCTION_FAILED
    end
    
    
    local sm_enc, sm_sig = self:get_dsx_sm_keys(free_id)
    local create_fid_8041_apdu = hex.hexf("00e000001e6f1c8102012c82030100008302%S850101860a00000000000000000000", pubkey_fid)
    local recv = self.cns_hcard:sm_transmit2(create_fid_8041_apdu, sm_enc, sm_sig)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        log.output('generate_dsx_rsa_key_pair(): create_fid_8041_apdu error:', hex.hexify(sw))
        return CKR.FUNCTION_FAILED
    end
    


    local keygenmaxtryonlow = self.keygenmaxtryonlow2048
    local modulus, pubexp
    for retry=1,keygenmaxtryonlow do
        log.output('generate_dsx_rsa_key_pair(): DS: retry=', retry, "/", keygenmaxtryonlow)
        -- generate key pair
        -- generate key pair KID=2041 FID=8041
        
        if contextual_pin then
            self.cns_hcard:select(hexf(self.ds_info.ds_sig_path))
            result = self.cns_hcard:verify_pin_ds(contextual_pin, self.ds_info.sm_enc, self.ds_info.sm_sig)
            if result ~= 0 then
                log.output('generate_dsx_rsa_key_pair(): cached DS PIN verify failed:', result)
                return CKR.FUNCTION_FAILED
            end
        end

        self.cns_hcard:select(dfXX_pubkey_path)

        local generate_kid_2041_fid_8041_apdu = hex.hexf("00460000082041%S00000000", pubkey_fid)
        local recv = self.cns_hcard:transmit(generate_kid_2041_fid_8041_apdu)
        local sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            log.output('generate_dsx_rsa_key_pair(): generate_kid_2041_fid_8041_apdu error:', hex.hexify(sw))
            return CKR.FUNCTION_FAILED
        end
        
        self.cns_hcard:select(dfXX_pubkey_path)
        modulus = self.cns_hcard:mread_binary(0, 256)
        pubexp = self.cns_hcard:mread_binary(256, 8)
        while string.sub(pubexp, 1, 1) == '\000' do pubexp = string.sub(pubexp, 2, -1) end
        
        log.output('generate_dsx_rsa_key_pair(): DS: modulus[0]=', string.byte(modulus, 1))
        
        if string.byte(modulus, 1) > 128 then
            break
        else
            log.output('generate_dsx_rsa_key_pair(): DS: key pair low, retry=', retry)
        end
            
    end
    
    if string.byte(modulus, 1) < 128 and self.keygenerroronlow then
        log.output('generate_key_pair(): DS: key pair low, returning error')
        return CKR.FUNCTION_FAILED
    end

    self:lock_dsx_container(free_id)
    
    log.output("generate_dsx_rsa_key_pair(): modulus:", hex.hexify(modulus))
    log.output("generate_dsx_rsa_key_pair(): pubexp:", hex.hexify(pubexp))
    
    -- add container to DSX fs
    local cka_bools = t.serialize_bools(templatePriv)
    log.output("generate_dsx_rsa_key_pair(): cka_bools:", hex.hexify(cka_bools or ''))
    
    local new_obj = {type=DSX_TYPE_RSA_PURE, id=free_id,
                                    bits=bits, cka_label=cka_label, cka_id=cka_id, 
                                    flags=bin.flags(0),
                                    cka_bools=cka_bools,
                                    }
    table.insert(self.dsx.fs.objects, new_obj)
    
    -- update fs file
    local fs_data = t.build_dsx_fs(self.dsx.fs)
    
    self:create_dsx_fs(fs_data)
    
    local objPriv = t.GetDSXPrivKeyTemplate(t.mt.get_public_key)
    objPriv[CKA.ID] = cka_id
    objPriv[CKA.LABEL] = cka_label
    objPriv[CKA.MODULUS_BITS] = cka_modulus_bit
    objPriv[CKA.MODULUS] = modulus
    objPriv[CKA.PUBLIC_EXPONENT] = pubexp
    objPriv[CKA.LOCAL] = templatePriv[CKA.LOCAL]
    objPriv[CKA.ALWAYS_AUTHENTICATE] = templatePriv[CKA.ALWAYS_AUTHENTICATE]
    objPriv[CKA.DESTROYABLE] = templatePriv[CKA.DESTROYABLE] or eCK.BBOOL(true)
    objPriv[CKA.DERIVE] = templatePriv[CKA.DERIVE]
    objPriv[CKA.MODIFIABLE] = templatePriv[CKA.MODIFIABLE]
    objPriv.num = free_id
    objPriv.path = hex.hexify(dfXX_path)
    objPriv.kid = "41"
    objPriv.related_public_key = hex.hexify(dfXX_pubkey_path)
    objPriv.key_bits = bits
    objPriv.key_flags = DSX_FLAGS_DS
    
    
    local objPub = t.GetDSXPubKeyTemplate(t.mt.get_public_key)
    objPub.path = objPriv.related_public_key
    objPub.num = free_id
    objPub.key_bits = bits
    objPub[CKA.ID] = objPriv[CKA.ID]
    objPub[CKA.LABEL] = objPub[CKA.LABEL] or objPriv[CKA.LABEL]
    objPub[CKA.MODULUS_BITS] = objPriv[CKA.MODULUS_BITS]
    objPub[CKA.MODULUS] = objPriv[CKA.MODULUS]
    objPub[CKA.PUBLIC_EXPONENT] = objPriv[CKA.PUBLIC_EXPONENT]
    objPub[CKA.LOCAL] = objPriv[CKA.LOCAL]
    objPub[CKA.DESTROYABLE] = templatePub[CKA.DESTROYABLE] or eCK.BBOOL(true)
    objPub[CKA.ALWAYS_AUTHENTICATE] = objPriv[CKA.ALWAYS_AUTHENTICATE]
    objPub[CKA.DERIVE] = eCK.BBOOL(false)
    objPub[CKA.MODIFIABLE] = eCK.BBOOL(true)
    
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPriv
    local hPrivk = self.attributes.max_index
    
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPub
    
    local hPubk = self.attributes.max_index
    
    return CKR.OK, hPubk, hPrivk
    
end


function t.mt:generate_dsx_ecdsa_key_pair(pMechanism, templatePub1, templatePriv1)
    log.output('generate_dsx_ecdsa_key_pair():')
    
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    
    local dspath = hex.hexf(self.ds_info.path_root or "1400")
    
    local templatePub = utility.clone_table(templatePub1)
    local templatePriv = utility.clone_table(templatePriv1)
    
    if templatePub[CKA.ID] then
        templatePriv[CKA.ID] = templatePub[CKA.ID]
    elseif templatePriv[CKA.ID] then
        templatePub[CKA.ID] = templatePriv[CKA.ID]
    end
    
    -- ECDSA object may be Qualifed DS or non qualifed
    -- "DX#" as well as legacy "DS" prefix trigger Qualified DS mode
    local isds = self:is_dsx(templatePriv) or self:is_ds(templatePriv)
    
    
    local cka_label = templatePriv[CKA.LABEL] or ""
    local cka_id = templatePriv[CKA.ID]  or ""
    local cka_ec_params = templatePub[CKA.EC_PARAMS] or templatePriv[CKA.EC_PARAMS]
    
    log.output("generate_dsx_ecdsa_key_pair(): ", cka_label, hex.hexify(cka_id or ""))
    local info = self.info or self:get_info()
    local fs = self:read_dsx_fs()

    
    if not cka_ec_params then
        log.output('generate_dsx_ecdsa_key_pair(): cka_ec_params not specified')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local curve = ecdhlib.get_curve_by_deroid(cka_ec_params)
    
    if not curve then
        log.output('generate_dsx_ecdsa_key_pair(): cka_ec_params not supported:', hex.hexify(cka_ec_params))
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    local oType = DSX_TYPE_FROM_CURVE_NAME[curve.name]
    if not oType then
        log.output('generate_dsx_ecdsa_key_pair(): curve type not supported by card:', curve.name)
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end

    templatePriv[CKA.SIGN] = eCK.BBOOL(true)
    templatePriv[CKA.MODIFIABLE] = templatePriv[CKA.MODIFIABLE] or eCK.BBOOL(true)
    templatePriv[CKA.DESTROYABLE] = templatePriv[CKA.DESTROYABLE] or eCK.BBOOL(true)
    templatePriv[CKA.DECRYPT] = eCK.BBOOL(false)
    templatePriv[CKA.DERIVE] = eCK.BBOOL(false)
    templatePriv[CKA.LOCAL] = eCK.BBOOL(true)
    templatePriv[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(isds)
    
    local bits = curve.keybits
    
    local free_id = t.look_for_dsx_free_id(fs)
    
    if not free_id  then
        log.output('generate_dsx_ecdsa_key_pair(): no more free DSX slots')
        return CKR.DEVICE_MEMORY
    end
    
    log.output("generate_dsx_ecdsa_key_pair(): found free_id:", free_id)
    
    local dfXX_fid = DSX_df00_fid + free_id
    local dfXX_path = dspath .. hex.hexf("%H", dfXX_fid)
    local pubkey_fid = hex.hexf("8041")
    local dfXX_pubkey_path = dfXX_path .. pubkey_fid
    
    
    -- ask DS PIN
    local contextual_pin = nil
    local res, cache_ds_pin
    log.output('generate_dsx_ecdsa_key_pair(): use_sm:', self.ds_info.use_sm)
    if isds and self.ds_info.alw_verify_pin then
        if self.cfg["dspinusegui"] == 'true' and self.request_plugin_valid then
            if self.cached_ds_pin then
                contextual_pin = self.cached_ds_pin
            else
                while true do
                    res, contextual_pin, cache_ds_pin = self:gui_request_pin_ds(self.check_box_visible)
                    if res ~= 1 then
                        log.output('generate_dsx_ecdsa_key_pair(): cancelled by plugin with code:', res)
                        return CKR.FUNCTION_FAILED
                    end
                    self.cns_hcard:select(hexf(self.ds_info.ds_sig_path))
                    result = self.cns_hcard:verify_pin_ds(contextual_pin, self.ds_info.sm_enc, self.ds_info.sm_sig)
                    if result == 0 and cache_ds_pin then self.cached_ds_pin = contextual_pin end
                    contextual_pin = nil
                    if self:gui_show_pin_message(result, false) ~= 1 then
                        break
                    end
                end
                
            end
        elseif self.cfg["dspiniscnspin"]=='true' or self.cfg["dspiniscnspin"]=='sign' then
            log.output('generate_dsx_ecdsa_key_pair(): using main pin as contextual pin...')
            contextual_pin = self.cached_main_pin
        else
            log.output('generate_dsx_ecdsa_key_pair(): requesting contextual login since ALWAYS_AUTHENTICATE is set...')
            return CKR.USER_NOT_LOGGED_IN
        end
    end

    self:create_dsx_container(free_id)
    

    -- ECDSA BSOs
    local bso_info = {
        keysize=curve.keysize,
        kid=tonumber("41", 16),
        parent=dfXX_path,
        aac={
            use = isds and self.cns_hcard.BSO_DS_PIN or self.cns_hcard.BSO_CNS_PIN, 
            change=self.cns_hcard.BSO_CNS_PIN,
            delete=self.cns_hcard.BSO_CNS_PIN,
            generate=self.cns_hcard.BSO_CNS_PIN, },
        sm=hex.hexf("0807ffffffffffffffffffffffff0807"),
    }
    -- ECDSA parameters
    local params_file_info_ef = {
        filetype=CnsSmartcard.fileTypes.Binary,
        --size=132+16,
        fid=hexf('ECDC'),
        parent=dfXX_path,
        aac= {
            read=0,
            update=0,
            append=0,
            delete=0,
            admin=0,
        }
    }
    -- ECDSA public key
    local file_info_ef_tlv = {
        filetype=CnsSmartcard.fileTypes.RecordTLV,
        size=192, -- max size for 521 bits: (66+2)*2 + 3 = 139
        fid=hexf('8041'),
        parent=dfXX_path,
        aac= {
            read=0,
            update=0,
            append=0,
            delete=0,
            admin=0,
        }
    }
    
    pcall(function()
        self.cns_hcard:delete_file(hexf('20%B', bso_info.kid), true)
    end)
    
    local pcRes, theErrorT = pcall( function()
        log.output('generate_dsx_ecdsa_key_pair(): SM main: creating ECDSA BSO:', bso_info.kid)
        self.cns_hcard:jsign_create_ecdsa_bso(bso_info, self.ds_info.sm_enc, self.ds_info.sm_sig)
        
        
        local sm_enc, sm_sig = self:get_dsx_sm_keys(free_id)
        
        local data = self.cns_hcard:jsign_get_ecdsa_parameters(curve)
    
        params_file_info_ef.size = string.len(data)
        log.output('generate_dsx_ecdsa_key_pair(): SM local: creating ECDSA parameters...')
        self.cns_hcard:create_file(params_file_info_ef, true, sm_enc, sm_sig)
    
        log.output('generate_dsx_ecdsa_key_pair(): NO SM: writing ECDSA parameters...')
        self.cns_hcard:mupdate_binary(0, data)
    
        log.output('generate_dsx_ecdsa_key_pair(): SM local: creating ECDSA public key TLV...')
        self.cns_hcard:create_file(file_info_ef_tlv, true, sm_enc, sm_sig)
    
    end)
    
    if not pcRes then
        log.output('generate_dsx_ecdsa_key_pair(): error:', debug.traceback(theErrorT))
        return CKR.FUNCTION_FAILED
    end

    -- generate key pair
    -- generate key pair KID=2041 FID=8041
    
    if contextual_pin then
        self.cns_hcard:select(hexf(self.ds_info.ds_sig_path))
        result = self.cns_hcard:verify_pin_ds(contextual_pin, self.ds_info.sm_enc, self.ds_info.sm_sig)
        if result ~= 0 then
            log.output('generate_dsx_ecdsa_key_pair(): cached DS PIN verify failed:', result)
            return CKR.FUNCTION_FAILED
        end
    end

    self.cns_hcard:select(dfXX_pubkey_path)

    self.cns_hcard:jsign_generate_key_pair_ecdsa(bso_info.kid, file_info_ef_tlv.fid, params_file_info_ef.fid)

    local point = self.cns_hcard:jsign_ecdsa_read_public_key(file_info_ef_tlv.parent .. file_info_ef_tlv.fid)

    self:lock_dsx_container(free_id)
    
    log.output("generate_dsx_ecdsa_key_pair(): point:", hex.hexify(point or ''))
    
    -- add container to DSX fs
    local cka_bools = t.serialize_bools(templatePriv)
    log.output("generate_dsx_ecdsa_key_pair(): cka_bools:", hex.hexify(cka_bools or ''))
    
    
    local dsx_flags = isds and DSX_FLAGS_DS or DSX_FLAGS_NO_DS
    
    local new_obj = {type=oType, id=free_id,
                                    bits=bits, cka_label=cka_label, cka_id=cka_id, 
                                    flags=dsx_flags,
                                    cka_bools=cka_bools,
                                    }
    table.insert(self.dsx.fs.objects, new_obj)
    
    -- update fs file
    local fs_data = t.build_dsx_fs(self.dsx.fs)
    
    self:create_dsx_fs(fs_data)
    
    local objPriv = t.GetDSXECDSAPrivKeyTemplate(t.mt.get_public_key_ecc)
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if templatePriv[k] and not t._is_private_attribute(k) then
            objPriv[k] = templatePriv[k]
        end
    end
    
    objPriv[CKA.ID] = cka_id
    objPriv[CKA.LABEL] = cka_label
    objPriv[CKA.EC_POINT] = der.build(der.STRING, point)
    objPriv[CKA.EC_PARAMS] = cka_ec_params
    objPriv[CKA.LOCAL] = templatePriv[CKA.LOCAL]
    objPriv[CKA.ALWAYS_AUTHENTICATE] = templatePriv[CKA.ALWAYS_AUTHENTICATE]
    objPriv[CKA.DESTROYABLE] = templatePriv[CKA.DESTROYABLE]
    objPriv[CKA.DERIVE] = templatePriv[CKA.DERIVE]
    objPriv[CKA.MODIFIABLE] = templatePriv[CKA.MODIFIABLE]
    objPriv.num = free_id
    objPriv.path = hex.hexify(dfXX_path)
    objPriv.kid = "41"
    objPriv.related_public_key = hex.hexify(dfXX_pubkey_path)
    objPriv.key_bits = bits
    objPriv.key_flags = dsx_flags
    objPriv.curve=curve
    
    local objPub = t.GetDSXECDSAPubKeyTemplate(t.mt.get_public_key_ecc)
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if templatePub[k] and not t._is_private_attribute(k) then
            objPub[k] = templatePub[k]
        end
    end
    objPub.path = objPriv.related_public_key
    objPub.num = free_id
    objPub.key_bits = bits
    objPub.curve=curve
    objPub[CKA.ID] = objPriv[CKA.ID]
    objPub[CKA.LABEL] = templatePub[CKA.LABEL] or objPriv[CKA.LABEL]
    objPub[CKA.EC_POINT] = objPriv[CKA.EC_POINT]
    objPub[CKA.EC_PARAMS] = objPriv[CKA.EC_PARAMS]
    objPub[CKA.LOCAL] = objPriv[CKA.LOCAL]
    objPub[CKA.DESTROYABLE] = templatePub[CKA.DESTROYABLE] or eCK.BBOOL(true)
    objPub[CKA.ALWAYS_AUTHENTICATE] = objPriv[CKA.ALWAYS_AUTHENTICATE]
    objPub[CKA.DERIVE] = eCK.BBOOL(false)
    objPub[CKA.MODIFIABLE] = eCK.BBOOL(true)
    
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPriv
    local hPrivk = self.attributes.max_index
    
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPub
    
    local hPubk = self.attributes.max_index
    
    return CKR.OK, hPubk, hPrivk
    
end


function t.mt:create_object_dsx_ecdsa_private_key(templatePriv1)
    log.output('create_object_dsx_ecdsa_private_key():')
    
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    
    local dspath = hex.hexf(self.ds_info.path_root or "1400")
    
    local templatePriv = utility.clone_table(templatePriv1)

    -- ECDSA object may be Qualifed DS or non qualifed
    -- "DX#" as well as legacy "DS" prefix trigger Qualified DS mode
    local isds = self:is_dsx(templatePriv) or self:is_ds(templatePriv)

    local cka_label = templatePriv[CKA.LABEL] or ""
    local cka_id = templatePriv[CKA.ID]  or ""
    local cka_ec_params = templatePriv[CKA.EC_PARAMS]
    local cka_value = templatePriv[CKA.VALUE]
    
    log.output("create_object_dsx_ecdsa_private_key(): ", cka_label, hex.hexify(cka_id or ""))
    local info = self.info or self:get_info()
    local fs = self:read_dsx_fs()

    
    if not cka_ec_params or not cka_value then
        log.output('create_object_dsx_ecdsa_private_key(): cka_ec_params not specified')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local curve = ecdhlib.get_curve_by_deroid(cka_ec_params)
    
    if not curve then
        log.output('create_object_dsx_ecdsa_private_key(): cka_ec_params not supported:', hex.hexify(cka_ec_params))
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    local oType = DSX_TYPE_FROM_CURVE_NAME[curve.name]
    if not oType then
        log.output('create_object_dsx_ecdsa_private_key(): curve type not supported by card:', curve.name)
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    if string.len(cka_value) ~= curve.keysize then
        log.output('create_object_dsx_ecdsa_private_key(): cka_value len invalid: got', string.len(cka_value), " expected:", curve.keysize)
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    
    local privKey, pubKey = curve.g:make_keypair(bignum.create("0x" .. hex.hexify(cka_value)))
    local point = pubKey:encode_point(true)
    log.output('create_object_dsx_ecdsa_private_key(): EC_POINT (calculated)', hex.hexify(point))
    templatePriv[CKA.EC_POINT] = der.build(der.STRING, point)
    
    templatePriv[CKA.SIGN] = eCK.BBOOL(true)
    templatePriv[CKA.MODIFIABLE] = templatePriv[CKA.MODIFIABLE] or eCK.BBOOL(true)
    templatePriv[CKA.DESTROYABLE] = templatePriv[CKA.DESTROYABLE] or eCK.BBOOL(true)
    templatePriv[CKA.DECRYPT] = eCK.BBOOL(false)
    templatePriv[CKA.DERIVE] = eCK.BBOOL(false)
    templatePriv[CKA.LOCAL] = eCK.BBOOL(false)
    templatePriv[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(isds)
    
    local bits = curve.keybits
    
    local free_id = t.look_for_dsx_free_id(fs)
    
    if not free_id  then
        log.output('create_object_dsx_ecdsa_private_key(): no more free DSX slots')
        return CKR.DEVICE_MEMORY
    end
    
    log.output("create_object_dsx_ecdsa_private_key(): found free_id:", free_id)
    
    local dfXX_fid = DSX_df00_fid + free_id
    local dfXX_path = dspath .. hex.hexf("%H", dfXX_fid)
    local pubkey_fid = hex.hexf("8041")
    local dfXX_pubkey_path = dfXX_path .. pubkey_fid
    
    
    -- ask DS PIN
    local contextual_pin = nil
    local res, cache_ds_pin
    log.output('create_object_dsx_ecdsa_private_key(): use_sm:', self.ds_info.use_sm)
    if isds and self.ds_info.alw_verify_pin then
        if self.cfg["dspinusegui"] == 'true' and self.request_plugin_valid then
            if self.cached_ds_pin then
                contextual_pin = self.cached_ds_pin
            else
                while true do
                    res, contextual_pin, cache_ds_pin = self:gui_request_pin_ds(self.check_box_visible)
                    if res ~= 1 then
                        log.output('create_object_dsx_ecdsa_private_key(): cancelled by plugin with code:', res)
                        return CKR.FUNCTION_FAILED
                    end
                    self.cns_hcard:select(hexf(self.ds_info.ds_sig_path))
                    result = self.cns_hcard:verify_pin_ds(contextual_pin, self.ds_info.sm_enc, self.ds_info.sm_sig)
                    if result == 0 and cache_ds_pin then self.cached_ds_pin = contextual_pin end
                    contextual_pin = nil
                    if self:gui_show_pin_message(result, false) ~= 1 then
                        break
                    end
                end
                
            end
        elseif self.cfg["dspiniscnspin"]=='true' or self.cfg["dspiniscnspin"]=='sign' then
            log.output('create_object_dsx_ecdsa_private_key(): using main pin as contextual pin...')
            contextual_pin = self.cached_main_pin
        else
            log.output('create_object_dsx_ecdsa_private_key(): requesting contextual login since ALWAYS_AUTHENTICATE is set...')
            return CKR.USER_NOT_LOGGED_IN
        end
    end

    self:create_dsx_container(free_id)
    

    -- ECDSA BSOs
    local bso_info = {
        keysize=curve.keysize,
        value=cka_value,
        kid=tonumber("41", 16),
        parent=dfXX_path,
        aac={
            use = isds and self.cns_hcard.BSO_DS_PIN or self.cns_hcard.BSO_CNS_PIN, 
            change=self.cns_hcard.BSO_CNS_PIN,
            delete=self.cns_hcard.BSO_CNS_PIN,
            generate=self.cns_hcard.BSO_CNS_PIN,
            },
        sm=hex.hexf("0807ffffffffffffffffffffffff0807"),
    }
    -- ECDSA parameters: strictly required for ECDSA import
    local params_file_info_ef = {
        filetype=CnsSmartcard.fileTypes.Binary,
        --size=132+16,
        fid=hexf('ECDC'),
        parent=dfXX_path,
        aac= {
            read=0,
            update=0,
            append=0,
            delete=0,
            admin=0,
        }
    }
    -- ECDSA public key
    local file_info_ef_tlv = {
        filetype=CnsSmartcard.fileTypes.RecordTLV,
        size=192, -- max size for 521 bits: (66+2)*2 + 3 = 139
        fid=hexf('8041'),
        parent=dfXX_path,
        aac= {
            read=0,
            update=0,
            append=0,
            delete=0,
            admin=0,
        }
    }
    
    pcall(function()
        self.cns_hcard:delete_file(hexf('20%B', bso_info.kid), true)
    end)
    
    local pcRes, theErrorT = pcall( function()
        log.output('create_object_dsx_ecdsa_private_key(): SM main: creating ECDSA BSO:', bso_info.kid)
        self.cns_hcard:jsign_create_ecdsa_bso(bso_info, self.ds_info.sm_enc, self.ds_info.sm_sig)
        
        
        local sm_enc, sm_sig = self:get_dsx_sm_keys(free_id)
        
        local data = self.cns_hcard:jsign_get_ecdsa_parameters(curve)
    
        params_file_info_ef.size = string.len(data)
        log.output('create_object_dsx_ecdsa_private_key(): SM local: creating ECDSA parameters...')
        self.cns_hcard:create_file(params_file_info_ef, true, sm_enc, sm_sig)
    
        log.output('create_object_dsx_ecdsa_private_key(): NO SM: writing ECDSA parameters...')
        self.cns_hcard:mupdate_binary(0, data)
    
        log.output('create_object_dsx_ecdsa_private_key(): SM local: creating ECDSA public key TLV...')
        self.cns_hcard:create_file(file_info_ef_tlv, true, sm_enc, sm_sig)
        
        -- append record EC_POINT
        local data = hex.hexf('10%P', point)
        log.output('create_object_dsx_ecdsa_private_key(): writing point to TLV record: ', hex.hexify(data))
        self.cns_hcard:append_record(data)

    
    end)
    
    if not pcRes then
        log.output('create_object_dsx_ecdsa_private_key(): error:', debug.traceback(theErrorT))
        return CKR.FUNCTION_FAILED
    end

    -- generate key pair
    -- generate key pair KID=2041 FID=8041
    
    if contextual_pin then
        self.cns_hcard:select(hexf(self.ds_info.ds_sig_path))
        result = self.cns_hcard:verify_pin_ds(contextual_pin, self.ds_info.sm_enc, self.ds_info.sm_sig)
        if result ~= 0 then
            log.output('create_object_dsx_ecdsa_private_key(): cached DS PIN verify failed:', result)
            return CKR.FUNCTION_FAILED
        end
    end

    self.cns_hcard:select(dfXX_pubkey_path)

    self.cns_hcard:jsign_generate_key_pair_ecdsa(bso_info.kid, nil, params_file_info_ef.fid)

    local point = self.cns_hcard:jsign_ecdsa_read_public_key(file_info_ef_tlv.parent .. file_info_ef_tlv.fid)

    self:lock_dsx_container(free_id)
    
    log.output("create_object_dsx_ecdsa_private_key(): point:", hex.hexify(point or ''))
    
    -- add container to DSX fs
    local cka_bools = t.serialize_bools(templatePriv)
    log.output("create_object_dsx_ecdsa_private_key(): cka_bools:", hex.hexify(cka_bools or ''))
    
    local dsx_flags = isds and DSX_FLAGS_DS or DSX_FLAGS_NO_DS
    
    local new_obj = {type=oType, id=free_id,
                                    bits=bits, cka_label=cka_label, cka_id=cka_id, 
                                    flags=dsx_flags,
                                    cka_bools=cka_bools,
                                    }
    table.insert(self.dsx.fs.objects, new_obj)
    
    -- update fs file
    local fs_data = t.build_dsx_fs(self.dsx.fs)
    
    self:create_dsx_fs(fs_data)
    
    local objPriv = t.GetDSXECDSAPrivKeyTemplate(t.mt.get_public_key_ecc)
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if templatePriv[k] and not t._is_private_attribute(k) then
            objPriv[k] = templatePriv[k]
        end
    end
    
    objPriv[CKA.ID] = cka_id
    objPriv[CKA.LABEL] = cka_label
    objPriv[CKA.EC_POINT] = der.build(der.STRING, point)
    objPriv[CKA.EC_PARAMS] = cka_ec_params
    objPriv[CKA.LOCAL] = templatePriv[CKA.LOCAL]
    objPriv[CKA.ALWAYS_AUTHENTICATE] = templatePriv[CKA.ALWAYS_AUTHENTICATE]
    objPriv[CKA.DESTROYABLE] = templatePriv[CKA.DESTROYABLE]
    objPriv[CKA.DERIVE] = templatePriv[CKA.DERIVE]
    objPriv[CKA.MODIFIABLE] = templatePriv[CKA.MODIFIABLE]
    objPriv.num = free_id
    objPriv.path = hex.hexify(dfXX_path)
    objPriv.kid = "41"
    objPriv.related_public_key = hex.hexify(dfXX_pubkey_path)
    objPriv.key_bits = bits
    objPriv.key_flags = dsx_flags
    objPriv.curve=curve

    
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPriv
    local hPrivk = self.attributes.max_index
    
    
    return CKR.OK, hPrivk
    
end



function t.mt:create_object_dsx_ecdsa_public_key(pTemplateOrig)
    log.output('create_object_dsx_ecdsa_public_key():')
    
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    
    local dspath = hex.hexf(self.ds_info.path_root or "1400")
    
    local pTemplate = utility.clone_table(pTemplateOrig)

    -- ECDSA object may be Qualifed DS or non qualifed
    -- "DX#" as well as legacy "DS" prefix trigger Qualified DS mode
    local isds = self:is_dsx(pTemplate) or self:is_ds(pTemplate)

    local cka_label = pTemplate[CKA.LABEL] or ""
    local cka_id = pTemplate[CKA.ID]  or ""
    local cka_ec_params = pTemplate[CKA.EC_PARAMS]
    local cka_ec_point = pTemplate[CKA.EC_POINT]
    
    log.output("create_object_dsx_ecdsa_public_key(): ", cka_label, hex.hexify(cka_id or ""))
    local info = self.info or self:get_info()
    local fs = self:read_dsx_fs()

    
    if not cka_ec_params or not cka_ec_point then
        log.output('create_object_dsx_ecdsa_public_key(): cka_ec_params not specified')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local curve = ecdhlib.get_curve_by_deroid(cka_ec_params)
    
    if not curve then
        log.output('create_object_dsx_ecdsa_public_key(): cka_ec_params not supported:', hex.hexify(cka_ec_params))
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    


    local objPub = t.GetDSXECDSAPubKeyTemplate(t.mt.get_public_key_ecc)
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] then
            objPub[k] = pTemplate[k]
        end
    end
    objPub.num = free_id
    objPub.key_bits = bits
    objPub.curve=curve
        
    objPub[ CKA.LABEL ] = cka_label
    objPub[ CKA.ID ] = cka_id
    objPub[ CKA.EC_POINT ] = cka_ec_point
    objPub[ CKA.EC_PARAMS ] = cka_ec_params
    

    objPub[ CKA.MODIFIABLE ] = eCK.BBOOL(true)
    objPub[ CKA.DERIVE ] = eCK.BBOOL(false)
    objPub[ CKA.KEY_GEN_MECHANISM ] = nil
    objPub[ CKA.ALWAYS_AUTHENTICATE ] = eCK.BBOOL(isds)
    objPub[ CKA.DESTROYABLE ] = eCK.BBOOL(true)
    objPub[ CKA.LOCAL ] =  eCK.BBOOL(false)
    
        
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPub
    
    local hPubk = self.attributes.max_index
    
    return CKR.OK, hPubk
    
end



function t.mt:create_object_dsx_certificate(pTemplateOrig)
    
    log.output("create_object_dsx_certificate() ")
    
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    
    local pTemplate = utility.clone_table(pTemplateOrig)
    
    pTemplate[CKA.LABEL] = pTemplate[CKA.LABEL] or ""
    pTemplate[CKA.ID] = pTemplate[CKA.ID] or ""
    
    pTemplate[CKA.TRUSTED] = pTemplate[CKA.TRUSTED] or eCK.BBOOL(false)
    pTemplate[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(true)
    pTemplate[CKA.MODIFIABLE] = pTemplate[CKA.MODIFIABLE] or eCK.BBOOL(true)
    pTemplate[CKA.DESTROYABLE] = pTemplate[CKA.DESTROYABLE] or eCK.BBOOL(true)

    log.output("create_object_dsx_certificate(): ", pTemplate[CKA.LABEL], hex.hexify(pTemplate[CKA.ID] or "") )
    
    if not pTemplate[CKA.VALUE] then
        log.output('create_object_dsx_certificate(): VALUE not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end

    local parsed_cer
    
    pcall(function()
        parsed_cer = der.parse_x509cer(pTemplate[CKA.VALUE])
    end)

    local fs = self:read_dsx_fs()
    local free_id = t.look_for_dsx_free_id(fs)

    local dspath = hex.hexf(self.ds_info.path_root or "1400")
    local dcXX_fid = DSX_dc00_prefix + free_id
    local dcXX_path = dspath .. hex.hexf("%H", dcXX_fid)
    
    local pcRes, theErrorT = pcall(function()
        self:create_file( {
        size=string.len(pTemplate[CKA.VALUE]), 
        filetype=CnsSmartcard.fileTypes.Binary,
        parent=dspath,
        fid=hex.hexf("%>%H", dcXX_fid), 
        aac={read=0, update=self.cns_hcard.BSO_CNS_PIN, delete=self.cns_hcard.BSO_CNS_PIN,},
        }, true, true)
        end)
    local _last_sw = self.cns_hcard.last_sw 
    if not pcRes and _last_sw ~= hexf('6982') and _last_sw ~= hexf('6a89')then
        error(theErrorT)
    end
    
    local actual_cert_data = pTemplate[CKA.VALUE]
    if self.use_cpr_mode then
        local cpr, decpr
        if self.use_cpr_mode2 then
            cpr = zlib.compresscer2( pTemplate[CKA.VALUE])
            decpr = cpr and zlib.decompresscer2(cpr)
        else
            cpr = zlib.compresscer( pTemplate[CKA.VALUE])
            decpr = cpr and zlib.decompresscer(cpr)
        end
        if decpr == actual_cert_data then
            actual_cert_data = cpr
            pcall(function()
            log.output('create_object_dsx_certificate(): cpr ratio:', 
                string.len(cpr)/string.len(pTemplate[CKA.VALUE]))
            end)
        else
            log.output('create_object_dsx_certificate(): compression failed!')
        end
    end
    self.cns_hcard:mupdate_binary(0, actual_cert_data)
    
    -- add container to DSX fs
    local cka_bools = t.serialize_bools(pTemplate)
    log.output("create_object_dsx_certificate(): cka_bools:", hex.hexify(cka_bools or ''))
    local new_obj = {type=DSX_TYPE_CERTIFICATE, id=free_id,
                                    bits=string.len(actual_cert_data),
                                    cka_label=pTemplate[CKA.LABEL],
                                    cka_id=pTemplate[CKA.ID], 
                                    flags=bin.flags(0),
                                    cka_bools=cka_bools,
                                    }
    table.insert(self.dsx.fs.objects, new_obj)
    
    -- update fs file
    local fs_data = t.build_dsx_fs(self.dsx.fs)
    self:create_dsx_fs(fs_data)
        
    local obj = t.GetDSXCertTemplate(t.mt.get_certificate) -- normal get certificate should work
    obj.path = hex.hexify(dcXX_path)
    obj.num = free_id
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] and not t._is_private_attribute(k) then
            obj[k] = pTemplate[k]
        end
    end

    if parsed_cer then
        obj[CKA.SUBJECT] = pTemplate[CKA.SUBJECT] or parsed_cer.subject
        obj[CKA.ISSUER] = pTemplate[CKA.ISSUER] or parsed_cer.issuer
        obj[CKA.SERIAL_NUMBER] = pTemplate[CKA.SERIAL_NUMBER] or parsed_cer.serialNumber
    end
    
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    
    local hCert = self.attributes.max_index
    
    return CKR.OK, hCert
    

end

function t.mt:add_dsx_objects(objects)
    log.output('token-cns:add_dsx_objects(): ...')
    -- oggetti DS; l'applicazione puo' non esistere;  gli oggetti possono non essere presenti
    local info = self:get_info() -- carica le info sul filesystem in cache
    if (self.ds_info ~= nil and self.ds_info.ds_objects ~= nil) then
    
        log.output('token-cns:add_dsx_objects(): adding DSX objects...')
        
        local fs

        local pcRes, theErrorT = pcall(function()
            fs = self:read_dsx_fs()
        end)
        
        if not pcRes then
            log.output('token-cns:add_dsx_objects(): read_dsx_fs() error:', theErrorT)
            return
        end
        
        if type(fs) ~= "table" or type(fs.objects) ~= "table" then
            log.output('token-cns:add_dsx_objects(): invalid DSX filesystem!')
            return
        end
        local obj
        for i=1,table.getn(fs.objects) do
            local o = fs.objects[i]
            log.output('token-cns:add_dsx_objects(): evaluating DSX object:', utility.repr(o))
            if o.type == DSX_TYPE_RSA_PURE then
                log.output('token-cns:add_dsx_objects(): found DSX key pair...')
                local dspath = hex.hexf(self.ds_info.path_root or "1400")
                local dfXX_fid = DSX_df00_fid + o.id
                local dfXX_path = dspath .. hex.hexf("%H", dfXX_fid)
                local pubkey_fid = hex.hexf("8041")
                local dfXX_pubkey_path = dfXX_path .. pubkey_fid
                
                obj = t.GetDSXPrivKeyTemplate(t.mt.get_public_key)
                
                t.deserialize_bools(obj, bin.flags("0x" .. hex.hexify(o.cka_bools)))
                obj[CKA.ID] = o.cka_id
                obj[CKA.LABEL] = o.cka_label
                obj[CKA.MODULUS_BITS] = eCK.ULONG(o.bits)
                obj[CKA.LOCAL] = obj[CKA.LOCAL] or eCK.BBOOL(true)
                obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(o.flags[DSX_FLAGS_DS])
                obj[CKA.DERIVE] = eCK.BBOOL(false)
                
                obj.num = o.id
                obj.path = hex.hexify(dfXX_path)
                obj.kid = "41"
                obj.related_public_key = hex.hexify(dfXX_pubkey_path)
                obj.key_bits = o.bits
                obj.key_flags = o.flags
                
                objects.max_index = objects.max_index +1
                objects[objects.max_index] = obj
    
                log.output('token-cns:add_dsx_objects(): added private key:', obj[CKA.LABEL],
                    objects.max_index, 
                    hex.hexify(objects[ objects.max_index ][CKA.CLASS]))

                local objPub = t.GetDSXPubKeyTemplate(t.mt.get_public_key)
                
                objPub[CKA.ID] =  obj[CKA.ID]
                objPub[CKA.LABEL] = obj[CKA.LABEL]
                objPub[CKA.MODULUS_BITS] = obj[CKA.MODULUS_BITS]
                objPub[CKA.LOCAL] = obj[CKA.LOCAL]
                objPub[CKA.MODIFIABLE] = obj[CKA.MODIFIABLE]
                objPub[CKA.ALWAYS_AUTHENTICATE] = obj[CKA.ALWAYS_AUTHENTICATE]
                objPub[CKA.DESTROYABLE] = obj[CKA.DESTROYABLE]
                objPub[CKA.ENCRYPT] = obj[CKA.DECRYPT]
                objPub[CKA.VERIFY] = obj[CKA.SIGN]
                objPub[CKA.DERIVE] = obj[CKA.DERIVE]

                objPub.num = o.id
                objPub.path = hex.hexify(dfXX_pubkey_path)
                objPub.key_bits = o.bits
                
                objects.max_index = objects.max_index +1
                objects[objects.max_index] = objPub
                
                log.output('token-cns:add_dsx_objects(): added public key:', objPub[CKA.LABEL],
                    objects.max_index, 
                    hex.hexify(objects[ objects.max_index ][CKA.CLASS]))

            elseif o.type == DSX_TYPE_CERTIFICATE then
                local dspath = hex.hexf(self.ds_info.path_root or "1400")
                local dcXX_fid = DSX_dc00_prefix + o.id
                local dcXX_path = dspath .. hex.hexf("%H", dcXX_fid)

                
                obj = t.GetDSXCertTemplate(t.mt.get_certificate)
                
                t.deserialize_bools(obj, bin.flags("0x" .. hex.hexify(o.cka_bools)))
                obj[CKA.ID] = o.cka_id
                obj[CKA.LABEL] = o.cka_label
                --obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(true) -- still use value in BOOLs
                
                obj.num = o.id
                obj.path = hex.hexify(dcXX_path)

                objects.max_index = objects.max_index +1
                objects[objects.max_index] = obj
    
                log.output('token-cns:add_dsx_objects(): added certificate:', obj[CKA.LABEL],
                    objects.max_index, 
                    hex.hexify(objects[ objects.max_index ][CKA.CLASS]))
            
            elseif DSX_TYPE_TO_CURVE[o.type] then
                log.output('token-cns:add_dsx_objects(): found DSX ECDSA key pair:', o.type)
                local dspath = hex.hexf(self.ds_info.path_root or "1400")
                local dfXX_fid = DSX_df00_fid + o.id
                local dfXX_path = dspath .. hex.hexf("%H", dfXX_fid)
                local pubkey_fid = hex.hexf("8041")
                local dfXX_pubkey_path = dfXX_path .. pubkey_fid
                
                local curve = DSX_TYPE_TO_CURVE[o.type]
                log.output('token-cns:add_dsx_objects(): DSX ECDSA key curve:', curve.name)
                
                obj = t.GetDSXECDSAPrivKeyTemplate(t.mt.get_public_key_ecc)
                
                t.deserialize_bools(obj, bin.flags("0x" .. hex.hexify(o.cka_bools)))
                obj[CKA.ID] = o.cka_id
                obj[CKA.LABEL] = o.cka_label
                obj[CKA.LOCAL] = obj[CKA.LOCAL] or eCK.BBOOL(true)
                obj[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(o.flags[DSX_FLAGS_DS])
                obj[CKA.DERIVE] = eCK.BBOOL(false)
                obj[CKA.EC_PARAMS] = der.derEncodeOID(curve.asciiOid)
                obj.curve = curve
                
                obj.num = o.id
                obj.path = hex.hexify(dfXX_path)
                obj.kid = "41"
                obj.related_public_key = hex.hexify(dfXX_pubkey_path)
                obj.key_bits = o.bits
                obj.key_flags = o.flags
                
                objects.max_index = objects.max_index +1
                objects[objects.max_index] = obj
    
                log.output('token-cns:add_dsx_objects(): added ECDSA private key:', obj[CKA.LABEL],
                    objects.max_index, 
                    hex.hexify(objects[ objects.max_index ][CKA.CLASS]))

                local objPub = t.GetDSXECDSAPubKeyTemplate(t.mt.get_public_key_ecc)
                
                objPub[CKA.ID] =  obj[CKA.ID]
                objPub[CKA.LABEL] = obj[CKA.LABEL]
                objPub[CKA.LOCAL] = obj[CKA.LOCAL]
                objPub[CKA.MODIFIABLE] = obj[CKA.MODIFIABLE]
                objPub[CKA.ALWAYS_AUTHENTICATE] = obj[CKA.ALWAYS_AUTHENTICATE]
                objPub[CKA.DESTROYABLE] = obj[CKA.DESTROYABLE]
                objPub[CKA.ENCRYPT] = obj[CKA.DECRYPT]
                objPub[CKA.VERIFY] = obj[CKA.SIGN]
                objPub[CKA.DERIVE] = obj[CKA.DERIVE]
                objPub[CKA.EC_PARAMS] = der.derEncodeOID(curve.asciiOid)
                objPub.curve = curve
                
                objPub.num = o.id
                objPub.path = hex.hexify(dfXX_pubkey_path)
                objPub.key_bits = o.bits
                
                objects.max_index = objects.max_index +1
                objects[objects.max_index] = objPub
                
                log.output('token-cns:add_dsx_objects(): added ECDSA public key:', objPub[CKA.LABEL],
                    objects.max_index, 
                    hex.hexify(objects[ objects.max_index ][CKA.CLASS]))
                    
            else
                log.output('token-cns:add_dsx_objects(): unknown object type:', o.type)
            end
        end


    end -- end raccolta degli oggetti DS
end

function t.mt:destroy_object_dsx(hObject)
    log.output('destroy_object_dsx(): ', hObject)

    if self.attributes == nil then
        log.output('destroy_object_dsx(): WARNING: user not logged in!')
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hObject]

    self:check_clear_cache(nil, true, true)
    
    if not obj then
        log.output('destroy_object_dsx(): invalid handle!')
        return CKR.OBJECT_HANDLE_INVALID
    end
    
    if not obj.dsx then
        log.output('destroy_object_dsx(): invalid DSX object!')
        return CKR.FUNCTION_FAILED
    end
    local files_delete={}
    
    
    self:get_attribute_value(hObject, CKA.LABEL)
    
    if self.cfg["dsdisabledestroy"] == "true" then
        log.output('destroy_object_dsx(): DS object destroy disabled')
        return CKR.TOKEN_WRITE_PROTECTED
    end
    
    self:invalidate_xproc_cache()
    
    if obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        log.output('destroy_object_dsx(): DSX PUBLIC KEY: nothing to do')
    else
        local fs = self:read_dsx_fs()
        local proceed = false
        for i=1,table.getn(fs.objects) do
            local o = fs.objects[i]
            if obj.num == o.id then
                
                local pcRes, theErrorT = pcall(function()
                    if obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
                        log.output('destroy_object_dsx(): DSX CERTIFICATE: deleting path:', obj.path)
                        local path = hex.hexf(obj.path)
                        table.insert(files_delete, {path=string.sub(path, 1, -3), fid=string.sub(path, -2, -1) }  )
                        proceed = true
                    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
                        log.output('destroy_object_dsx(): DSX PRIVATE KEY: deleting path:', obj.path)
                        local path = hex.hexf(obj.path)
                        table.insert(files_delete, {path=string.sub(path, 1, -3), fid=string.sub(path, -2, -1) }  )
                        proceed = true
                    else
                        log.output('destroy_object_dsx(): UNKNOWN OBJECT type: nothing to do')
                    end
                    
                    table.remove(fs.objects, i)
                end)
                if not pcRes then
                    log.output("destroy_object_dsx(): error:", theErrorT)
                end
                break
            end
        end
        
        for i, v in files_delete do
            pcall(function()
                log.output('destroy_object_dsx(): selecting parent:', hex.hexify(v.path))
                self.cns_hcard:select(v.path)
                log.output('destroy_object_dsx(): deleting FID:', hex.hexify(v.fid))
                self.cns_hcard:delete_file(v.fid, true)
            end)
        end
        
        if proceed then
            -- update fs file
            log.output('destroy_object_dsx(): updating DSX FS index...')
            local fs_data = t.build_dsx_fs(fs)
            self:create_dsx_fs(fs_data)
        end
    end
    self.attributes[hObject] = nil
    self:update_cache_id()
    self:update_free_mem(self.info, true)
    return CKR.OK
end


------------------ DSX END



function t.mt:set_attribute_value(hObject, pTemplate)

    if self.cns_only then
        log.output('set_attribute_value(): CNS only Token, cannot modify objects')
        return CKR.TOKEN_WRITE_PROTECTED
    end

    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hObject]
    if obj == nil then
        log.output('set_attribute_value(): specified handle invalid: ', hObject)
        return CKR.OBJECT_HANDLE_INVALID
    end  

    if obj.private and self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    
    self:check_clear_cache(nil, true, true)

    -- if self:cache_enabled() then
        -- log.output('removing cache...')
        -- elimina tutta la cache statica del token
        -- local info = self:get_info()
        -- log.output('removing cache for serial', info.serialNumber)
        -- utility.cache_write(info.serialNumber, nil, nil, self._umcachepath)
    -- end
    
    if obj.iscns or not obj.isp11 then
        log.output('set_attribute_value(): CNS/DS object: copying new values in memory')
        for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
            if pTemplate[k] then
                obj[k] = pTemplate[k]
            end
        end
        return CKR.OK
    end

    if not obj.isp11 then
        log.output('set_attribute_value(): Object not in P11 FS')
        return CKR.FUNCTION_FAILED
    end
    
    self:auto_verify_pin_main()
    
    if not obj.populated then
        self:get_attribute_value(hObject, -1)
    end
    
    self:invalidate_xproc_cache()
    
    if obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        rv = self:set_attribute_value_pubkey(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        rv = self:set_attribute_value_privkey(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        rv = self:set_attribute_value_certificate(hObject, pTemplate)
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        rv = self:set_attribute_value_data(hObject, pTemplate)        
        
    else
        log.output('set_attribute_value(): unsupported object class:', hex.hexify(obj[CKA.CLASS]))
        rv = CKR.ATTRIBUTE_VALUE_INVALID
    end
    if rv == CRK_OK then
        self:update_cache_id()
        self:update_free_mem(self.info, true)
    end
    return rv
end

function t.mt:set_attribute_value_privkey(hObj, pTemplate)
    log.output('set_attribute_value_privkey()')
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    local obj = self.attributes[hObj]
    
    for k, v in pTemplate do
        if k ~= CKA.ID and k ~= CKA.LABEL and k ~= CKA.SUBJECT
            and k ~= CKA.START_DATE and k ~= CKA.END_DATE 
            and k ~= CKA.MODIFIABLE
            and k ~= CKA.DESTROYABLE
            and k ~= CKA.DECRYPT and k ~= CKA.SIGN then
            return CKR.ATRIBUTE_TYPE_INVALID
        end
    end
    
    local templateNew = {}
    -- copia tutti gli attributi CKA_*
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if obj[k] then
            templateNew[k] = obj[k]
        end
    end
    for k, v in pTemplate do
        templateNew[k] = v
    end
    local fid_main = self:buildP11Fid(obj.num, objTypes.ePrivKey, attrTypes.eMain)
    
    if self.p11_info.version_major >= 2 then
        local privk_mainfile = t.serialize_attr_p11v2_privkey(templateNew, obj.kid, obj.key_bits)
        self:create_p11_file(privk_mainfile, fid_main, true)
    else

        local privk_mainfile = self:privkey_serialize_mainfile(templateNew, obj.kid, obj.key_bits)
        self:create_p11_file(privk_mainfile, fid_main, false)
        
        if (pTemplate[CKA.LABEL]) then
            self:set_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.eLabel, pTemplate[CKA.LABEL], false )
        end
        
        if (pTemplate[CKA.ID]) then
        self:set_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.eID, pTemplate[CKA.ID], false )
        end
        
        if (pTemplate[CKA.SUBJECT]) then
        self:set_p11_attribute(obj.num, objTypes.ePrivKey, attrTypes.eSubject, pTemplate[CKA.SUBJECT], false )
        end
    end
    
    -- aggiorna i valori in cache
    for k, v in pTemplate do
        obj[k] = v
    end
    return CKR.OK
end



function t.mt:set_attribute_value_certificate(hObj, pTemplate)
    log.output('set_attribute_value_certificate()')

    local obj = self.attributes[hObj]
    
    for k, v in pTemplate do
        if k ~= CKA.ID and k ~= CKA.LABEL and k ~= CKA.SUBJECT
            and k ~= CKA.ISSUER and k ~= CKA.SERIAL_NUMBER
            and k ~= CKA.MODIFIABLE
            and k ~= CKA.DESTROYABLE
            and k ~= CKA.TRUESTED  then
            return CKR.ATRIBUTE_TYPE_INVALID
        end
    end
    local templateNew = {}
    
    -- copia tutti gli attributi CKA_*
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if obj[k] then
            templateNew[k] = obj[k]
        end
    end
    for k, v in pTemplate do
        templateNew[k] = v
    end
    
    local fid_main = self:buildP11Fid(obj.num, objTypes.eCert, attrTypes.eMain)
    
    if self.p11_info.version_major >= 2 then
        local cert_mainfile = t.serialize_attr_p11v2_cert(templateNew, obj.num)
        self:create_p11_file(cert_mainfile, fid_main, true)
    else
        local cert_mainfile = self:cert_serialize_mainfile(templateNew, obj.num)
        self:create_p11_file(cert_mainfile, fid_main, true)

        if (pTemplate[CKA.LABEL]) then
            self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eLabel, pTemplate[CKA.LABEL], true )
        end
        
        if (pTemplate[CKA.ID]) then
            self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eID, pTemplate[CKA.ID], true )
        end
        
        if (pTemplate[CKA.SUBJECT]) then
            self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eSubject, pTemplate[CKA.SUBJECT], true )
        end
        
        if (pTemplate[CKA.ISSUER]) then
            self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eIssuer, pTemplate[CKA.ISSUER], true )
        end
        
        if (pTemplate[CKA.SERIAL_NUMBER]) then
            self:set_p11_attribute(obj.num, objTypes.eCert, attrTypes.eSN, pTemplate[CKA.SERIAL_NUMBER], true )
        end
    end
    
    -- aggiorna i valori in cache
    for k, v in pTemplate do
        obj[k] = v
    end
    return CKR.OK
end


function t.mt:set_attribute_value_pubkey(hObj, pTemplate)
    log.output('set_attribute_value_pubkey()')
    local obj = self.attributes[hObj]
    
    for k, v in pTemplate do
        if k ~= CKA.ID and k ~= CKA.LABEL and k ~= CKA.SUBJECT            
            and k ~= CKA.MODIFIABLE
            and k ~= CKA.DESTROYABLE
            and k ~= CKA.START_DATE and k ~= CKA.END_DATE then
            return CKR.ATRIBUTE_TYPE_INVALID
        end
    end

    local templateNew = {}
    -- copia tutti gli attributi CKA_*
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if obj[k] then
            templateNew[k] = obj[k]
        end
    end
    for k, v in pTemplate do
        templateNew[k] = v
    end
    
    local fid_main = self:buildP11Fid(obj.num, objTypes.ePubKey, attrTypes.eMain)
    
    
    if self.p11_info.version_major >= 2 then
        local pubk_mainfile = t.serialize_attr_p11v2_pubkey(templateNew, obj.num, obj.key_bits)
        self:create_p11_file(pubk_mainfile, fid_main, true)
        
    else
        local pubk_mainfile = self:pubkey_serialize_mainfile(templateNew, obj.num, obj.key_bits)
        self:create_p11_file(pubk_mainfile, fid_main, true)

        if (pTemplate[CKA.LABEL]) then
            self:set_p11_attribute(obj.num, objTypes.ePubKey, attrTypes.eLabel, pTemplate[CKA.LABEL], true )
        end
        
        if (pTemplate[CKA.ID]) then
            self:set_p11_attribute(obj.num, objTypes.ePubKey, attrTypes.eID, pTemplate[CKA.ID], true )
        end
        
        if (pTemplate[CKA.SUBJECT]) then
            self:set_p11_attribute(obj.num, objTypes.ePubKey, attrTypes.eSubject, pTemplate[CKA.SUBJECT], true )
        end
    end
    
    -- aggiorna i valori in cache
    for k, v in pTemplate do
        obj[k] = v
    end
    return CKR.OK
end



function t.mt:set_attribute_value_data(hObj, pTemplate)
    local obj = self.attributes[hObj]
    log.output('set_attribute_value_data()')
    local obj = self.attributes[hObj]
    
    for k, v in pTemplate do
        if k ~= CKA.OBJECT_ID and k ~= CKA.LABEL and k ~= CKA.APPLICATION
            and k ~= CKA.VALUE
            and k ~= CKA.MODIFIABLE
            and k ~= CKA.DESTROYABLE then
            return CKR.ATRIBUTE_TYPE_INVALID
        end
    end

    local templateNew = {}
    -- copia tutti gli attributi CKA_*
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if obj[k] then
            templateNew[k] = obj[k]
        end
    end
    for k, v in pTemplate do
        templateNew[k] = v
    end
    
    local fid_main = self:buildP11Fid(obj.num, objTypes.eData, attrTypes.eMain)
        
    if self.p11_info.version_major >= 2 then
        local data_mainfile = t.serialize_attr_p11v2_data(templateNew)
        local finfo = self.cns_hcard:select(hexf(self.p11_info.path_root .. "%H", fid_main), true)
        if finfo and finfo.size == string.len(data_mainfile) then
            log.output('set_attribute_value_data(): recycling existing file')
            self.cns_hcard:mupdate_binary(0, data_mainfile)
        else
            log.output('set_attribute_value_data(): recreating into a new file')
            self:create_p11_file(data_mainfile, fid_main, true)
        end
    else
        local data_mainfile = self:data_serialize_mainfile(templateNew)
        self:create_p11_file(data_mainfile, fid_main, not obj.private)

        if (pTemplate[CKA.LABEL]) then
            self:set_p11_attribute(obj.num, objTypes.eData, attrTypes.eLabel, pTemplate[CKA.LABEL], not obj.private )
        end
        
        if (pTemplate[CKA.OBJECT_ID]) then
            self:set_p11_attribute(obj.num, objTypes.eData, attrTypes.eObjectId, pTemplate[CKA.OBJECT_ID], not obj.private )
        end
        
        if (pTemplate[CKA.APPLICATION]) then
            self:set_p11_attribute(obj.num, objTypes.eData, attrTypes.eapplication, pTemplate[CKA.APPLICATION], not obj.private )
        end
    end
    
    if (pTemplate[CKA.VALUE]) then
        self:set_p11_attribute(obj.num, objTypes.eData, attrTypes.eValue, pTemplate[CKA.VALUE], not obj.private, obj.private )
    end
    
    -- aggiorna i valori in cache
    for k, v in pTemplate do
        obj[k] = v
    end
    return CKR.OK
end

function t.mt:get_special_ids(id_class)
    if id_class == 'CNS' then
        return {OBJ_IDS.CNS0_ID}
    elseif id_class == 'DS' then
        local ids = {}
        for i=0,self.ds_info.ds_objects.DS_MAX_INDEX do
            table.insert(ids, OBJ_IDS.DS_ID .. string.format('%d', i))
        end
        return ids
    end
end

function t.mt:alloc_object_handle()
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    self.attributes.max_index = self.attributes.max_index + 1
    return self.attributes.max_index
end

function t.mt:_get_license()
    
    if self.cfg["idlc"] ~= "true" then
        
        local info = self.info or self:get_info()
        local pcRes
        local fInfos
        local licenseContents
        
        local files = {
            [1] = (self.ds_info and (self.ds_info.path_root .. "11ce")) or (self.p11_info and (self.p11_info.path_root..'0001'))
        }
        for i=1,table.getn(files) do
            licenseContents = self:read_cached_file(hexf(files[i]), 0, -1, true, true)
            -- pcRes = pcall(function()
                -- fInfos = self.cns_hcard:select(hexf(files[i]), true)
            -- end)
            -- if pcRes then
                -- licenseContents = self.cns_hcard:mread_binary(0, fInfos.size)
                -- break
            -- end
        end
        if not licenseContents or string.len(licenseContents) < 2 then
            return
        end
        local license_len = bin.unpack('%H', string.sub(licenseContents, 1, 2))
        return string.sub(licenseContents, 3, license_len+2)
    end
    return ""
end


function t.mt:set_label(Puk, label)
    local rv = CKR.OK
    local info = self:get_info()
    -- if Puk and string.len(Puk) > 0 then
        -- rv = self:verify_pin(Puk, CKU.SO)
        -- if rv ~= CKR.OK then
            -- return rv
        -- end
    -- end
    if self.p11_info then
        local pcRes, theErrorT = pcall(function()
            local p11infopath = self.p11_info.path_root..'0000'
            self.cns_hcard:select(hex.hexf(p11infopath))
            local value = label .. string.rep(" ", 32 - string.len(label))
            value = string.sub(value, 1, 32)
            self.cns_hcard:mupdate_binary(14, value)
            self.info.label = value
            self.p11_info.label = value
            self:update_cache_id()
        end)
        if not pcRes then
            log.output('set_label(): error:', theErrorT)
            rv = CKR.FUNCTION_FAILED
        end
    end
    return rv
end

function t.mt:update_free_mem(info, force_refresh)
    log.output("update_free_mem():")
    if not info or not self.jsign_2048 then
        return
    end
    pcall(function()
        local recv, err = self:send_cached_apdu(hex.hexf("00ca018a03"), true, force_refresh )
        -- ans: <spazio residuo su 3 bytes>
        local sw = string.sub(recv, -2, -1)
        if recv and sw == hexf('9000') then
            info.ulFreePublicMemory = bin.unpack("%>%L", "\0" .. string.sub(recv, 1, 3))
            info.ulFreePrivateMemory = self.info.ulFreePublicMemory
            log.output("token free space:", info.ulFreePublicMemory);
            
            if info.ulFreePublicMemory > info.ulTotalPublicMemory then
                info.ulTotalPublicMemory = 131072
                info.ulTotalPrivateMemory = info.ulTotalPublicMemory
            end
        end
    end)
end



function t.mt:flush_cache()
    if self.cfg["xproc"] ~= "true" then
        return false
    end
    local changed, cache_id
    if self._cache_id == nil then
        log.output("token-ts:flush_cache(): initializing _cache_id")
        changed, self._cache_id = utility.has_token_changed(self, "cache", 0)
        log.output("token-ts:flush_cache(): initialize: _cache_id:", self._cache_id)
    end
    changed, cache_id = utility.has_token_changed(self, "cache", self._cache_id)
    if changed then
        log.output("token-ts:flush_cache(): token has changed!")
        self._cache_id = cache_id
        self.info = nil -- rimuove cache oggetti
        self.dsx = nil -- rimuove cache oggetti DSX
        self.attributes = self:get_objects()  -- riscostruisce cache oggetti
    end
    return changed, self._cache_id
end

function t.mt:invalidate_xproc_cache()
    if self.cfg["xproc"] ~= "true" then
        return
    end
    self._cache_id = utility.set_token_changed(self, "cache")
end


function t.mt:set_param(name, value)

    if not name or string.len(name) == 0 then
        log.output('set_param(): name is required')
        return CKR.ATTRIBUTE_TYPE_INVALID
    end
    
    log.output('set_param(): value:', value)
    
    if name == "dspinusegui" then
        self.cfg[name] = value
    elseif name == "dspiniscnspin" then
        self.cfg[name] = value
    elseif name == "hidecachedspincheck" then
        self.cfg[name] = value
    else
        log.output('set_param(): unknown param name')
        return CKR.ATTRIBUTE_TYPE_INVALID
    end
    
    log.output('set_param(): OK!')
    return CKR.OK
end

function t.mt:get_param(name)

    local rv, value = CKR.ATTRIBUTE_TYPE_INVALID, ""
    
    if not name or string.len(name) == 0 then
        log.output('get_param(): name is required')
        return CKR.ATTRIBUTE_TYPE_INVALID
    end
    
    log.output('get_param(): name:', name)
    
    name = string.lower(name)
    if name == "dspinusegui" then
        rv, value = CKR.OK, self.cfg[name]
    elseif name == "dspiniscnspin" then
        rv, value = CKR.OK, self.cfg[name]
     elseif name == "hidecachedspincheck" then
        rv, value = CKR.OK, self.cfg[name]
    end

    log.output('get_param(): rv:', rv)
    log.output('get_param(): value:', value)
    return rv, value
end



return t

--===========================================================================
end
}
_LOADED['token-ts-pinpad'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- pcsc-token-cns.lua
local CnsSmartcard = require 'CnsSmartcard'
local hex = require 'hex'
local hexf = hex.hexf
local der = require 'der'
local utility = require 'utility'
local rsa = require 'rsa'
local zlib = require 'zlib'
local rsa = require 'rsa'

local licensing = require 'licensing'

local objCnsTmpl = require 'token-cns-objects'
local objP11Tmpl = require 'token-p11-objects'


local PINPAD_CTL_VERIFY=1
local PINPAD_CTL_CHANGE=2
local PINPAD_CTL_RESET=3

local PINPAD_CTL_PIN=256
local PINPAD_CTL_PUK=512
local PINPAD_CTL_DSPIN=768
local PINPAD_CTL_DSPUK=1024



local OBJ_IDS = {
    PDATA_LABEL = 'PDATA',
    CNS0_LABEL = 'CNS0',
    CNS0_ID = 'CNS0',
    DS_LABEL = 'DS',
    DS_ID = 'DS',
}

local emt = {
	OperationOk = 0, -- Report "operation success", generic, return 0
	OperationFailed = 1, -- Report "operation failed", generic, return 0

	PinIncorrect = 8, -- Report "PIN incorrect, retry?", return 1 if YES, 0 if NO
	PinLocked = 9,    -- Report "Smartcard locked", return 0
	PinDeactivated = 10, -- Report "Smartcard not yet activated", return 0

	PukIncorrect = 16, -- Report "PUK incorrect, retry?", return 1 if YES, 0 if NO
	PukLocked = 17, -- Report "PUK locked", return 0

    }

local objTypes = {
	ePubKey = 0,
	ePrivKey = 1,
	eCert = 2,
	eSymKey = 3,
	eData = 4,
}
local attrTypes = {
	eMain = 0,
	eLabel = 1,
	eID = 2,
	eSubject = 3,
	eIssuer = 4,
	eSN = 5,
	eModulus = 6,
	ePubExp = 7,
	eValue = 8,
	ePubKeyModExp = 8,
	eApplication = 9,
	eObjectId = 10,
}

local pubkey_bitfields = {
    MODIFIABLE = bin.flags(1),
	PRIVATE = bin.flags(2),
	DERIVE = bin.flags(4),
	LOCAL = bin.flags(8),
	TRUSTED = bin.flags(16),
	ENCRYPT = bin.flags(32),
	VERIFY = bin.flags(64),
	VERIFY_RECOVER = bin.flags(128),
    WRAP = bin.flags(256),
}

local privkey_bitfields = {
    MODIFIABLE = bin.flags(1),
	PRIVATE = bin.flags(2),
	DERIVE = bin.flags(4),
	LOCAL = bin.flags(8),
	DECRYPT = bin.flags(16),
	SIGN = bin.flags(32),
	SIGN_RECOVER = bin.flags(64),
	UNWRAP = bin.flags(128),
}

local cert_data_bitfields = {
    MODIFIABLE = bin.flags(1),
	PRIVATE = bin.flags(2),
	TRUSTED = bin.flags(4),
}

local MinKSize, MaxKSize = 1024, 1024
local DS_FS_VERSION_2_0 = tonumber('20', 16)

local t = {
    name = 'incardtspinpad',
    mt = { },
    mechanisms = {
        [ CKM.RSA_PKCS_KEY_PAIR_GEN ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.GENERATE_KEY_PAIR},
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_PKCS_PSS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.SIGN},
        [ CKM.RSA_X_509 ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_PKCS_OAEP ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.DECRYPT},
    },
    cns_hcard = nil,
    capabilities = { private_attributes_readable=false, always_authenticate_on_cert=true, },
}
t.mt.__index = t.mt


function t.mt:initialize(cfg)
    self.keygenmaxtryonlow1024 = 20
    self.keygenmaxtryonlow2048 = 20
    self.keygenerroronlow = true
    self.capabilities = utility.clone_table(t.capabilities)
    self.cns_hcard = CnsSmartcard.new(self.hcard)
    self.request_plugin_valid = w32.request_plugin_valid()
    self.use_cpr_mode = true
    self.cfg = cfg or utility.parse_cfg()
    self.cfg["dspiniscnspin"] = self.cfg["idspiniscnspin"] or self.cfg["dspiniscnspin"]
    self.cfg["dspinusegui"] = self.cfg["idspinusegui"] or self.cfg["dspinusegui"]
    self.cfg["dspinusepinpad"] = self.cfg["idspinusepinpad"] or self.cfg["dspinusepinpad"]
    self.cfg["pinpad"] = self.cfg["ipinpad"] or self.cfg["pinpad"]
    
    if self.cfg["pinpad"] == "true" then
        self.cfg["dspinusepinpad"] = "true"
    end
    
    self.cfg["hidecachedspincheck"] = self.cfg["ihidecachedspincheck"] or self.cfg["hidecachedspincheck"]
    self.cfg["fcpr"] = self.cfg["fcpr"] or self.cfg["ifcpr"]
    
    self.cfg["xproc"] = self.cfg["xproc"] or self.cfg["ixproc"]
    
    -- se il plugin del PIN non 