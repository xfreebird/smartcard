 necessario cancellare la chiave privata
        elseif obj.isp11 then
            log.output('destroy_object(): P11 PUBLIC_KEY')
            local the_attributes = {attrTypes.eMain, attrTypes.ePubKeyModExp, attrTypes.eLabel, attrTypes.eID, attrTypes.eSubject}
            for i, k in the_attributes do
                table.insert(files_delete, {path=hexf(self.p11_info.path_root), fid=hexf('%H', self:buildP11Fid(obj.num, objTypes.ePubKey, k) ) } )
            end
            self.p11_info.obj_table[obj.num] = false
            self:write_p11_indexes()
        else
            log.output('destroy_object(): DS PUBLIC_KEY')
            local oGroup = self.ds_info.ds_objects.o1024
            local index_base = 0
            if obj.num >= table.getn(self.ds_info.ds_objects.o1024) then
                oGroup = self.ds_info.ds_objects.o2048
                index_base = table.getn(self.ds_info.ds_objects.o1024)
            end
            oGroup[obj.num - index_base+1][2] = 0
            self:update_ds_index()
        end
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        log.output('destroy_object(): PRIVATE_KEY')
        if obj.iscns then
            log.output('destroy_object(): CNS PRIVATE_KEY')
            local pcRes, theErrorT = pcall(function()
                self:update_append_record(obj.related_public_key, 1, hex.hexf('1082') .. string.rep('\255', 130) )
                self:update_append_record(obj.related_public_key, 2, hex.hexf('1105') .. string.rep('\255', 5) )
                self.cns_info.key_valid=false
            end)
        elseif obj.isp11 then
            log.output('destroy_object(): P11 PRIVATE_KEY')
            local the_attributes = {attrTypes.eMain, attrTypes.eLabel, attrTypes.eID, attrTypes.eSubject, attrTypes.eModulus, attrTypes.ePubExp, }
            for i, k in the_attributes do
                table.insert(files_delete, {path=hexf(self.p11_info.path_root), fid=hexf('%H', self:buildP11Fid(obj.num, objTypes.ePrivKey, k) ) } )
            end
            table.insert(files_delete, {path=hexf(self.p11_info.path_root), fid=hexf('21%B', obj.kid) } )
            table.insert(files_delete, {path=hexf(self.p11_info.path_root), fid=hexf('20%B', obj.kid) } )
            self.p11_info.obj_table[obj.num] = false
            if obj.key_bits > 1024 then
                self.p11_info.bso2048_table[obj.kid - self.p11_bso_start_index_2048] = false
            else
                self.p11_info.bso_table[obj.kid - self.p11_bso_start_index_1024] = false
            end
            self:write_p11_indexes()
        else
            log.output('destroy_object(): DS PRIVATE_KEY')
            local oGroup = self.ds_info.ds_objects.o1024
            local index_base = 0
            if obj.num >= table.getn(self.ds_info.ds_objects.o1024) then
                oGroup = self.ds_info.ds_objects.o2048
                index_base = table.getn(self.ds_info.ds_objects.o1024)
            end
            oGroup[obj.num - index_base+1][1] = 0
            self:update_ds_index()
        end
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        log.output('destroy_object(): DATA')
        if obj.iscns then
            log.output('destroy_object(): CNS DATA')
            local pcRes, theErrorT = pcall(function()
                self.cns_hcard:select(hexf(obj.path) )
                self.cns_hcard:update_binary(0, '\000')
                self.cns_info.pdata_valid = false
            end)
        elseif obj.isp11 then
            log.output('destroy_object(): P11 DATA')
            local the_attributes = {attrTypes.eMain, attrTypes.eLabel, attrTypes.eObjectId, attrTypes.eApplication, }
            for i, k in the_attributes do
                table.insert(files_delete, {path=hexf(self.p11_info.path_root), fid=hexf('%H', self:buildP11Fid(obj.num, objTypes.eData, k) ) } )
            end
            self.p11_info.obj_table[obj.num] = false
            self:write_p11_indexes()
        else
            log.output('destroy_object(): WARNING: unknown DATA object type...')
        end
    else
        log.output('destroy_object(): WARNING! Unsupported object class!')
        return CKR.FUNCTION_FAILED
    end
    
    for i, v in files_delete do
        pcall(function()
            self.cns_hcard:select(v.path)
            self.cns_hcard:delete_file(v.fid, true)
        end)
    end
    self.attributes[hObject] = nil
    self:update_cache_id()
    self:update_free_mem(self.info, true)
    return CKR.OK
end


------------------ DSX BEGIN


local DSX_defaultFS = hex.hexf("0001" .. "0000" .. "00000000" .. "3000")
local DSX_df00_fid = tonumber("DF00", 16)
local DSX_dc00_prefix = tonumber("DC00", 16)
local DSX_df00_path = hex.hexf("1400%H", DSX_df00_fid)
local DSX_MK = hex.hexf("699c".."420".."5ba8".."7bb".."08".."958".."0ff".."d6d".."16e".."4b4".."f2f".."f3".."426".."67013".."f24".."b26".."fe9".."8ea".."09a".."b41".."22")

local DSX_TAG_A0_OBJ            = tonumber("A0", 16)
local DSX_A1_TYPE_ID        = tonumber("A1", 16)
local DSX_TAG_A2_FALGS          = tonumber("A2", 16)
local DSX_TAG_A3_BITS           = tonumber("A3", 16)
local DSX_TAG_A4_CKA_LABEL      = tonumber("A4", 16)
local DSX_TAG_A5_CKA_ID         = tonumber("A5", 16)
local DSX_TAG_A6_CKA_BOOLS      = tonumber("A6", 16)

local DSX_TYPE_INVALID                 = 0 -- FREE SLOT
local DSX_TYPE_RSA_PURE                = 1 -- PSO DEC
local DSX_TYPE_RSA_PKCS1_BT010         = 2 -- PSO CDS
local DSX_TYPE_ECC_SECP256_R1_NIST     = tonumber("10", 16)   -- PSO CDS
local DSX_TYPE_ECC_SECP384_R1_NIST     = tonumber("11", 16)   -- PSO CDS
local DSX_TYPE_ECC_SECP521_R1_NIST     = tonumber("12", 16)   -- PSO CDS
local DSX_TYPE_ECC_SECP256_K1_BITCOIN  = tonumber("13", 16)   -- PSO CDS
local DSX_TYPE_CERTIFICATE             = tonumber("81", 16)

local DSX_TYPE_TO_CURVE = {
    [DSX_TYPE_ECC_SECP256_R1_NIST]=ecdhlib.get_curve("secp256r1"),
    [DSX_TYPE_ECC_SECP384_R1_NIST]=ecdhlib.get_curve("secp384r1"),
    [DSX_TYPE_ECC_SECP521_R1_NIST]=ecdhlib.get_curve("secp521r1"),
    [DSX_TYPE_ECC_SECP256_K1_BITCOIN]=ecdhlib.get_curve("secp256k1"),
}

local DSX_TYPE_FROM_CURVE_NAME = {
    ["secp256r1"]=DSX_TYPE_ECC_SECP256_R1_NIST,
    ["secp384r1"]=DSX_TYPE_ECC_SECP384_R1_NIST,
    ["secp521r1"]=DSX_TYPE_ECC_SECP521_R1_NIST,
    ["secp256k1"]=DSX_TYPE_ECC_SECP256_K1_BITCOIN,
}

local DSX_FLAGS_DS = bin.flags(0) -- object DS PIN for signature
local DSX_FLAGS_NO_DS = bin.flags("0x01") -- object doesn't use DS PIN but MAIN PIN for signature

function t.build_dsx_fs(fs, use_cache_id)
    local objsD = ""
    for i=1,table.getn(fs.objects) do
        local obj = fs.objects[i]
        local A1_TYPE_ID = der.build(DSX_A1_TYPE_ID, hex.hexf("%B%B", obj.type, obj.id) )
        local A2_FALGS = der.build(DSX_TAG_A2_FALGS, hex.hexf("%H", obj.flags.asnumber) )
        local A3_BITS = der.build(DSX_TAG_A3_BITS, hex.hexf("%H", obj.bits) )
        local A4_CKA_LABEL = der.build(DSX_TAG_A4_CKA_LABEL,  obj.cka_label or "")
        local A5_CKA_ID = der.build(DSX_TAG_A5_CKA_ID,  obj.cka_id or "")
        local A6_CKA_BOOLS = der.build(DSX_TAG_A6_CKA_BOOLS,  obj.cka_bools or "\0\0")
        
        local Ax_VALUES = ""
        

        if type(obj.unknown_tags) == "table" then
            for x=1,table.getn(obj.unknown_tags) do
                Ax_VALUES = Ax_VALUES.. der.build(obj.unknown_tags[x].tag, obj.unknown_tags[x].value )
            end
        end
        
        objsD = objsD .. der.build(DSX_TAG_A0_OBJ, A1_TYPE_ID .. A2_FALGS .. A3_BITS .. A4_CKA_LABEL .. A5_CKA_ID .. A6_CKA_BOOLS .. Ax_VALUES)
        
    end
    local data = fs.version ..(use_cache_id and  fs.cache_id or ( "\0\0" .. sm.gen_random(4))) .. der.build(der.SEQUENCE, objsD)
    
    return data
end

function t.parse_dsx_fs(fs_data)
    local fs = {
        version=string.sub(fs_data, 1, 2),
        cache_id=string.sub(fs_data, 3, 8),
        objects={},
    }
    local der_data = string.sub(fs_data, 9, -1)
    
    local obj1 = der.parse(der_data)
    local obj2 = der.parse(obj1[1].value)
    for i=1,table.getn(obj2) do
        local objX = der.parse(obj2[i].value)
        local obj = {unknown_tags={}, }
        for j=1,table.getn(objX) do
            if objX[j].tag == DSX_A1_TYPE_ID then
                obj.type = string.byte(objX[j].value, 1)
                obj.id = string.byte(objX[j].value, 2)
            elseif objX[j].tag == DSX_TAG_A2_FALGS then
                obj.flags = bin.flags(tonumber(hex.hexify(objX[j].value), 16))
            elseif objX[j].tag == DSX_TAG_A3_BITS then
                obj.bits = tonumber(hex.hexify(objX[j].value), 16)
            elseif objX[j].tag == DSX_TAG_A4_CKA_LABEL then
                obj.cka_label = objX[j].value
            elseif objX[j].tag == DSX_TAG_A5_CKA_ID then
                obj.cka_id = objX[j].value
            elseif objX[j].tag == DSX_TAG_A6_CKA_BOOLS then
                obj.cka_bools = objX[j].value
            else
                table.insert(obj.unknown_tags, objX[j])
            end
        end
        table.insert(fs.objects, obj)
    end

    return fs
end

-- local fs = {
-- version="\0\1",
-- cache_id="\0\0" .. "1234",
-- objects={{unknown_tags={{tag=48, value="123-data"}},type=1, id=2, bits=2048, cka_label="label_123", cka_id="id_456", cka_bools="12", flags=bin.flags(123), }, },
-- }

-- local fsD = t.build_dsx_fs(fs, true)
-- print(hex.hexify(fsD))
-- local fs1 = t.parse_dsx_fs(fsD)
-- print(utility.repr(fs))
-- print(utility.repr(fs1))

-- print(utility.objects_deep_equals(fs, fs1))


function t.look_for_dsx_free_id(fs)
    
    local all_ids = {}
    local max_id = 64
    for i=1,max_id do
        all_ids[i] = true
    end
    for i=1,table.getn(fs.objects) do
        local obj = fs.objects[i]
        all_ids[obj.id] = false
    end
    
    for i=1,max_id do
        if all_ids[i] then
            return i
        end
    end
    
    return nil
end

function t.mt:read_dsx_fs(force, create_on_fail)
    log.output("read_dsx_fs(): force: ", force)
    log.output("read_dsx_fs(): create_on_fail(pre): ", create_on_fail)
    local fs_data
    create_on_fail = create_on_fail == nil and true or create_on_fail
    log.output("read_dsx_fs(): create_on_fail(post): ", create_on_fail)

    local info = self.info or self:get_info()

    if self.dsx and self.dsx.fs and not force then
        log.output("read_dsx_fs(): return cached self.dsx.fs...")
        return self.dsx.fs
    end
    

    if self:cache_enabled() then
        log.output("read_dsx_fs(): try reading dsx fs from cache...")
        fs_data = self:read_cached_file(DSX_df00_path, 0, -1, true, true)
        log.output("read_dsx_fs(): got fs_data:", hex.hexify(fs_data or ""))
    end
    
    if not fs_data or string.len(fs_data) == 0 then
        log.output("read_dsx_fs(): reading dsx fs from card...")
        local pcRes, fInfo = pcall(function()
            return self.cns_hcard:select(DSX_df00_path, true)
        end)
        if not pcRes then
            log.output('read_dsx_fs(): error:', debug.traceback(fInfo))
            if self.cns_hcard.last_sw == hex.hexf("6a82") and create_on_fail then
                return self:create_dsx_fs()
            end
        end
        
        if pcRes then
            local der_len = 0
            local read_len = 12
            local header_len = read_len
            
            log.output("read_dsx_fs(): reading dsx fs: header...")
            local header = self.cns_hcard:mread_binary(0, read_len)
            if string.byte(header, 9) == der.SEQUENCE then
                if string.byte(header, 10) < 128 then
                    der_len = string.byte(header, 10)
                    header_len = 10
                elseif string.byte(header, 10) == 129 then -- 81
                    der_len = string.byte(header, 11)
                    header_len = 11
                elseif string.byte(header, 10) == 130 then -- 82
                    der_len = string.byte(header, 11) * 256 + string.byte(header, 12)
                    header_len = 12
                end
            end
            
            log.output("read_dsx_fs(): reading dsx fs: header:", hex.hexify(header or ""))
            log.output("read_dsx_fs(): reading dsx fs: header_len:", header_len)
            log.output("read_dsx_fs(): reading dsx fs: der_len:", der_len)
            
            log.output("read_dsx_fs(): reading dsx fs: data...")
            
            local data = self.cns_hcard:mread_binary(read_len, der_len)
            
            log.output("read_dsx_fs(): reading dsx fs: data:", hex.hexify(data or ""))
            
            log.output("read_dsx_fs(): parsing dsx fs...")
            fs_data = header .. data
            if self:cache_enabled() then
                utility.cache_write(info.serialNumber, DSX_df00_path, fs_data, self._umcachepath)
            end
        end
    end
    
    if fs_data then
        local fs = t.parse_dsx_fs(fs_data)
        log.output("read_dsx_fs(): dsx fs:", utility.repr(fs))
        
        self.dsx = self.dsx or {}
        self.dsx.fs = fs
        
        if not self.dsx.DERIVED_KEY then

            log.output('read_dsx_fs(): calculating DERIVED_KEY...')
            self.dsx.DERIVED_KEY = hmac.derive_keys(DSX_MK, info.serialNumber)
        end
        
        return self.dsx.fs
    end
end

function t.mt:create_dsx_fs(new_data, delete)
    log.output("create_dsx_fs(): new_data=", hex.hexify(new_data or ""), ", delete=", delete)
    local fs
    
    local pcRes1, theErrorT = pcall(function()
    
        local dspath = hex.hexf(self.ds_info.path_root or "1400")
        
        local info = self.info or self:get_info()
        local sn = info.serialNumber
        local pcRes, fInfo = pcall(function()
            return self.cns_hcard:select(DSX_df00_path, true)
        end)
        if not pcRes then
            log.output('create_dsx_fs(): error 0:', debug.traceback(fInfo))
        end
        if pcRes and delete then
            self.cns_hcard:select(dspath)
            self.cns_hcard:delete_file(DSX_df00_fid, true)
            pcRes = false
            self.cns_hcard.last_sw = hexf('6a82')
        end
        
        if not pcRes then
            if self.cns_hcard.last_sw == hexf('6a82') then

                log.output('create_dsx_fs(): creating DF00 file:', hex.hexify(DSX_df00_path))
                
                local finfo1 = { size=2048,
                                        filetype=CnsSmartcard.fileTypes.Binary,
                                        parent=dspath,
                                        fid=DSX_df00_fid,
                                        asm={},
                                        aac = {read=0, update=0, append=0, delete=CnsSmartcard.BSO_CNS_PIN},
                                        
                                        }
                fs = t.parse_dsx_fs(new_data or DSX_defaultFS)
                self.cns_hcard:create_file(finfo1, false)
                log.output('create_dsx_fs(): writing default/new FS:', hex.hexify(new_data or DSX_defaultFS))
                self.cns_hcard:mupdate_binary(0, new_data or DSX_defaultFS)
                
                if self:cache_enabled() then
                    utility.cache_write(info.serialNumber, DSX_df00_path, new_data or DSX_defaultFS, self._umcachepath)
                end
            end

        elseif new_data then
            fs = t.parse_dsx_fs(new_data)
            log.output('create_dsx_fs(): writing new_data FS:', hex.hexify(new_data))
            self.cns_hcard:mupdate_binary(0, new_data)
            
            if self:cache_enabled() then
                utility.cache_write(info.serialNumber, DSX_df00_path, new_data, self._umcachepath)
            end
        end
        
        self.dsx = self.dsx or {}
        
        if not self.dsx.DERIVED_KEY then
            log.output('create_dsx_fs(): calculating DERIVED_KEY...')
            self.dsx.DERIVED_KEY = hmac.derive_keys(DSX_MK, sn)
        end
            
        if fs then
            log.output("create_dsx_fs(): new dsx fs:", utility.repr(fs))
            self.dsx.fs = fs
        end
    end)
    if not pcRes1 then 
        log.output("create_dsx_fs(): error 1:", debug.traceback(theErrorT))
        return nil
    end
    return fs
    
end


function t.mt:destroy_dsx_container(id)
    -- delete 1400 DFXX
    local dfXX_fid = DSX_df00_fid + id
    log.output(string.format("destroy_dsx_container(): %X", dfXX_fid))
    local dspath = hex.hexf(self.ds_info.path_root or "1400")
    
    self.cns_hcard:select(dspath)
    local pcRes, theErrorT = pcall(function()
        self.cns_hcard:delete_file(dfXX_fid, true)
    end)
    if not pcRes then
        log.output('destroy_dsx_container(): delete_file error:', debug.traceback(theErrorT))
    end
end

function t.mt:get_dsx_sm_keys(id)
    
    id = id or 0
    
    local sID
    if type(id) == "number" then
        sID = string.char(id)
    else
        sID = id
    end
    
    if not self.dsx.DERIVED_KEY then
        self:read_dsx_fs()
    end
    
    local sm_enc = hmac.hmac_sha256(self.dsx.DERIVED_KEY, sID .. "\0\0\0\1")
    local sm_sig = hmac.hmac_sha256(self.dsx.DERIVED_KEY, sID .. "\0\0\0\2")
    
    sm_enc = string.sub(sm_enc, 1, 16) .. string.sub(sm_enc, 1, 8)
    sm_sig = string.sub(sm_sig, 1, 16) .. string.sub(sm_sig, 1, 8)
    
    return sm_enc, sm_sig
end

function t.mt:create_dsx_container(id)
    log.output("create_dsx_container(): ", id)
    local dspath = hex.hexf(self.ds_info.path_root or "1400")
    local dfXX_fid = DSX_df00_fid + id
    local dfXX_path = dspath .. hex.hexf("%H", dfXX_fid)
    
    self.cns_hcard:select(dspath)
    
    local create_dfXX_apdu = hex.hexf("00e000003862368102000082033800008302DF%B850101860a00000000000000000000cb18ffff0201ffffffffffffffffffff0807ffffffffffffffff", id)
    
    log.output(string.format("create_dsx_container(): delete DF %X", dfXX_fid))
    
    -- first: delete DFXX
    local pcRes, theErrorT = pcall(function()
        self.cns_hcard:delete_file(dfXX_fid, true)
    end)
    if not pcRes then
        log.output('create_dsx_container(): delete_file error:', debug.traceback(theErrorT))
    end
    
    -- create the DFXX
    log.output(string.format("create_dsx_container(): create DF %X", dfXX_fid))
    local recv = self.cns_hcard:transmit(create_dfXX_apdu)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        log.output('create_dsx_container(): create_dfXX_apdu error:', hex.hexify(sw))
        error(CnsSmartcardError.new(sw, 'create_dsx_container create_dfXX_apdu Error'))
    end
    
    local sm_enc, sm_sig = self:get_dsx_sm_keys(id)
    
    -- create the DFXX SM keys 07 & 07
    local create_sm_sig_07 = hex.hexf("00da016e438302100785088300820fffff0000860700FFffffffFFFFcb10ffffffffffffffffffffffffffffffff8f18%S", sm_sig)
    local create_sm_enc_08 = hex.hexf("00da016e438302100885088300030fffff0008860700FFffffffFFFFcb10ffffffffffffffffffffffffffffffff8f18%S", sm_enc)
    
    log.output("create_dsx_container(): create_sm_sig_07")
    
    local recv = self.cns_hcard:sm_transmit(create_sm_sig_07, self.ds_info.sm_enc, self.ds_info.sm_sig)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        log.output('create_dsx_container(): create_sm_sig_07 error:', hex.hexify(sw))
        error(CnsSmartcardError.new(sw, 'create_dsx_container create_sm_sig_07 Error'))
    end
    
    log.output("create_dsx_container(): create_sm_enc_08")
    local recv = self.cns_hcard:sm_transmit(create_sm_enc_08, self.ds_info.sm_enc, self.ds_info.sm_sig)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        log.output('create_dsx_container(): create_sm_enc_08 error:', hex.hexify(sw))
        error(CnsSmartcardError.new(sw, 'create_dsx_container create_sm_enc_08 Error'))
    end
    

    
end

function t.mt:lock_dsx_container(id)
    log.output("lock_dsx_container(): ", id)
    local dspath = hex.hexf(self.ds_info.path_root or "1400")
    local dfXX_fid = DSX_df00_fid + id
    local dfXX_path = dspath .. hex.hexf("%H", dfXX_fid)
    
    local apdulock = hex.hexf("00da016f0c860aFFFFFFFFFF101010FFFF")
    
    self.cns_hcard:select(dfXX_path)
    
    -- lock DFXX
    local recv = self.cns_hcard:transmit(apdulock)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        log.output('lock_dsx_container(): apdulock error:', hex.hexify(sw))
        error(CnsSmartcardError.new(sw, 'lock_dsx_container apdulock Error'))
    end
end



function t.dump_template(pTemplate)
    if log.canlog() then
        log.output("dump_template():")
        for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
            -- if pTemplate[k] then
                -- log.output(string.format("0x%08X -> type: %s", k, type(pTemplate[k]) ) )
            -- end
            if type(pTemplate[k]) == "string" then
                log.output(string.format("CKA.%s (0x%08X) -> value: %s", utility.CKA_NAMES[k] or "<nil>", k, hex.hexify(pTemplate[k]) ) )
            end
        end
    end
end
function t.serialize_bools(obj)
    local bools = bin.flags(0)
    t.dump_template(obj)
    
    if t.is_ck_true(obj[CKA.MODIFIABLE]) then bools = bools + bin.flags("0x0001") end
    if t.is_ck_true(obj[CKA.TRUSTED])    then bools = bools + bin.flags("0x0002") end
    if t.is_ck_true(obj[CKA.LOCAL])      then bools = bools + bin.flags("0x0004") end
    if t.is_ck_true(obj[CKA.ENCRYPT])    then bools = bools + bin.flags("0x0008") end
    if t.is_ck_true(obj[CKA.DECRYPT])    then bools = bools + bin.flags("0x0010") end
    if t.is_ck_true(obj[CKA.SIGN])       then bools = bools + bin.flags("0x0020") end
    if t.is_ck_true(obj[CKA.VERIFY])     then bools = bools + bin.flags("0x0040") end
    if t.is_ck_true(obj[CKA.SIGN_RECOVER])   then bools = bools + bin.flags("0x0080") end
    if t.is_ck_true(obj[CKA.VERIFY_RECOVER]) then bools = bools + bin.flags("0x0100") end
    if t.is_ck_true(obj[CKA.WRAP])           then bools = bools + bin.flags("0x0200") end
    if t.is_ck_true(obj[CKA.UNWRAP])         then bools = bools + bin.flags("0x0400") end
    if t.is_ck_true(obj[CKA.ALWAYS_AUTHENTICATE]) then bools = bools + bin.flags("0x0800") end
    
    -- added NOV 2019
    if t.is_ck_true(obj[CKA.DERIVE]) then bools = bools + bin.flags("0x1000") end
    if t.is_ck_true(obj[CKA.COPYABLE]) then bools = bools + bin.flags("0x2000") end
    
    if not t.is_ck_true(obj[CKA.DESTROYABLE]) then bools = bools + bin.flags("0x8000") end -- inverse logic (so defaults true)
    
    log.output('serialize_bools():', bools)
    return hex.hexf('%H', bools.asnumber)
end

function t.deserialize_bools(obj, bools, attr_list)
    log.output('deserialize_bools():', bools)
    obj[CKA.MODIFIABLE]          =  (attr_list==nil or attr_list[CKA.MODIFIABLE]         ) and eCK.BBOOL(bools[bin.flags("0x0001")])
    obj[CKA.TRUSTED]             =  (attr_list==nil or attr_list[CKA.TRUSTED]            ) and eCK.BBOOL(bools[bin.flags("0x0002")])
    obj[CKA.LOCAL]               =  (attr_list==nil or attr_list[CKA.LOCAL]              ) and eCK.BBOOL(bools[bin.flags("0x0004")])
    obj[CKA.ENCRYPT]             =  (attr_list==nil or attr_list[CKA.ENCRYPT]            ) and eCK.BBOOL(bools[bin.flags("0x0008")])
    obj[CKA.DECRYPT]             =  (attr_list==nil or attr_list[CKA.DECRYPT]            ) and eCK.BBOOL(bools[bin.flags("0x0010")])
    obj[CKA.SIGN]                =  (attr_list==nil or attr_list[CKA.SIGN]               ) and eCK.BBOOL(bools[bin.flags("0x0020")])
    obj[CKA.VERIFY]              =  (attr_list==nil or attr_list[CKA.VERIFY]             ) and eCK.BBOOL(bools[bin.flags("0x0040")])
    obj[CKA.SIGN_RECOVER]        =  (attr_list==nil or attr_list[CKA.SIGN_RECOVER]       ) and eCK.BBOOL(bools[bin.flags("0x0080")])
    obj[CKA.VERIFY_RECOVER]      =  (attr_list==nil or attr_list[CKA.VERIFY_RECOVER]     ) and eCK.BBOOL(bools[bin.flags("0x0100")])
    obj[CKA.WRAP]                =  (attr_list==nil or attr_list[CKA.WRAP]               ) and eCK.BBOOL(bools[bin.flags("0x0200")])
    obj[CKA.UNWRAP]              =  (attr_list==nil or attr_list[CKA.UNWRAP]             ) and eCK.BBOOL(bools[bin.flags("0x0400")])
    obj[CKA.ALWAYS_AUTHENTICATE] =  (attr_list==nil or attr_list[CKA.ALWAYS_AUTHENTICATE]) and eCK.BBOOL(bools[bin.flags("0x0800")])
    obj[CKA.DERIVE]              =  (attr_list==nil or attr_list[CKA.DERIVE]             ) and eCK.BBOOL(bools[bin.flags("0x1000")])
    obj[CKA.COPYABLE]            =  (attr_list==nil or attr_list[CKA.COPYABLE]           ) and eCK.BBOOL(bools[bin.flags("0x2000")])
    obj[CKA.DESTROYABLE]         =  (attr_list==nil or attr_list[CKA.DESTROYABLE]        ) and eCK.BBOOL(not bools[bin.flags("0x8000")])
    
    log.output('deserialize_bools(): dumping obj:')
    t.dump_template(obj)
    
    return obj
end

function t.GetDSXCertTemplate(populateCertFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.CERTIFICATE),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(false),
        [ CKA.LABEL ] = populateCertFunc,
        -- Certificate
        [ CKA.CERTIFICATE_TYPE ] = eCK.CERTIFICATE_TYPE(CKC.X_509),
        [ CKA.TRUSTED ] = populateCertFunc,
        [ CKA.CERTIFICATE_CATEGORY ] = eCK.ULONG(1), -- user
        -- [ CKA.CHECK_VALUE ] = '',
        [ CKA.START_DATE ] = '',
        [ CKA.END_DATE ] = '',
        -- Certificate X.509
        [ CKA.SUBJECT ] = populateCertFunc,
        [ CKA.ID ] = populateCertFunc,
        [ CKA.ISSUER ] = populateCertFunc,
        [ CKA.SERIAL_NUMBER ] = populateCertFunc,
        [ CKA.VALUE ] = populateCertFunc,
        [ CKA.URL ] = '',
        [ CKA.HASH_OF_SUBJECT_PUBLIC_KEY ] = '',
        [ CKA.HASH_OF_ISSUER_PUBLIC_KEY ] = '',
        [ CKA.JAVA_MIDP_SECURITY_DOMAIN ] = eCK.ULONG(0),
        
        -- attributo non standard: usato per stabilire
        -- se un certificato 