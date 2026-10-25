 su 1 byte invece di 2
    obj.pubexp = utility.LV_get(buf, newOffset, 1, {[1]=1})[1]
    return obj  
end


function t.parse_ecc_ds_priv_pub_key_attribute(card, file_path, modulus_size)
    local obj = {}
    local infos = card:select(file_path, true)
    if not infos then infos = {size=240} end
    local buf
    if infos.size == 48 then
        buf = card:mread_binary(0, 32) .. card:mread_binary(32, 16)
    else
        buf = card:mread_binary(0, infos.size)
    end
    return t.parse_ecc_ds_priv_pub_key_attribute_val(buf, modulus_size), buf
end

function t.parse_ecc_ds_priv_pub_key_attribute_val(buf)
    local obj = {}
    
    local flags = string.sub(buf, 1, 2)
    --print('flags:', hex.hexify(flags))
    obj.flags = bin.flags(bin.unpack("%H", flags ))
    local fields = utility.LV_get(buf, 2, 2)
    local newOffset = 2 + string.len(fields[1])+2 + string.len(fields[2]) +2
    obj.label = fields[1]
    obj.id = fields[2]
    obj.startdate = string.sub(buf, newOffset+1, newOffset+8)
    --print("startdate:", obj.startdate)
    obj.enddate = string.sub(buf, newOffset+9, newOffset+16)
    --print("enddate:", obj.enddate)
    newOffset = newOffset +16
    obj.subject = utility.LV_get(buf, newOffset, 1 )[1]
    newOffset = newOffset + 2 + string.len(obj.subject)
    if string.len(buf) > newOffset then
        obj.eccPoint = utility.LV_get(buf, newOffset, 1 )[1]
        newOffset = newOffset + 2 + string.len(obj.eccPoint)
        obj.ecParams = utility.LV_get(buf, newOffset, 1 )[1]
        newOffset = newOffset + 2 + string.len(obj.ecParams)
    end
    return obj
end

function t.parse_ds_secretkey_attribute(card, file_path)
    local obj = {}
    local infos = card:select(file_path, true)
    if not infos then infos = {size=240} end
    local buf
    if infos.size == 48 then
        buf = card:mread_binary(0, 32) .. card:mread_binary(32, 16)
    else
        buf = card:mread_binary(0, infos.size)
    end
    return t.parse_ds_secretkey_attribute_val(buf), buf
end

function t.parse_ds_secretkey_attribute_val(buf)
    local obj = {}

    local flags = string.sub(buf, 1, 2)
    --print('flags:', hex.hexify(flags))
    obj.flags = bin.flags(bin.unpack("%H", flags ))
    local fields = utility.LV_get(buf, 2, 2)
    local newOffset = 2 + string.len(fields[1])+2 + string.len(fields[2]) +2
    obj.label = fields[1]
    obj.id = fields[2]
    obj.startdate = string.sub(buf, newOffset+1, newOffset+8)
    --print("startdate:", obj.startdate)
    obj.enddate = string.sub(buf, newOffset+9, newOffset+16)
    --print("enddate:", obj.enddate)
    newOffset = newOffset +16
    
    fields = utility.LV_get(buf, newOffset, 2)
    obj.subject = fields[1]
    obj.value = fields[2] -- Shall be encrypted
    
    return obj  
end


-- funzioni per la serializzazione

function t.serialize_bools(obj)
    local bools = bin.flags(0)
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

function t.serialize_attr(obj, template)
    log.output('serialize_attr():')
    local bools = t.serialize_bools(obj)
    local attr = bools
    for i, v in template do
        local value = obj[v.type] or v.default or ''
        log.output('serialize_attr(): type:', v.type)
        log.output('serialize_attr(): value:', hex.hexify(value))
        local t1 = '%H' -- default: double byte len
        if v.fixed then
            attr = attr .. value
        else
            if v.single then t1 = '%B' end -- single byte len
            attr = attr .. hex.hexf(t1, string.len(value)) .. value
        end
    end
    log.output('serialize_attr():', hex.hexify(attr))
    return attr
end

function t.serialize_attr_pubkey(obj)

    local template ={ [1]={type=CKA.LABEL},
                      [2]={type=CKA.ID},
                      [3]={type=CKA.START_DATE, fixed=true, default=string.rep(string.char(0), 8)},
                      [4]={type=CKA.END_DATE, fixed=true, default=string.rep(string.char(0), 8)},
                      [5]={type=CKA.SUBJECT},
                      [6]={type=CKA.MODULUS},
                      [7]={type=CKA.PUBLIC_EXPONENT},
                    }
    return t.serialize_attr(obj, template)
end


function t.serialize_attr_cert(obj)

    local template ={ [1]={type=CKA.LABEL},
                      [2]={type=CKA.ID},
                      [3]={type=CKA.SUBJECT},
                      [4]={type=CKA.ISSUER},
                      [5]={type=CKA.SERIAL_NUMBER},
                    }
    return t.serialize_attr(obj, template)
end


function t.serialize_attr_privkey(obj)
    local template ={ [1]={type=CKA.LABEL},
                      [2]={type=CKA.ID},
                      [3]={type=CKA.START_DATE, fixed=true, default=string.rep('\000', 8)},
                      [4]={type=CKA.END_DATE, fixed=true, default=string.rep('\000', 8)},
                      [5]={type=CKA.SUBJECT},
                      [6]={type=CKA.MODULUS, fixed=true},
                      [7]={type=CKA.PUBLIC_EXPONENT, single=true},
                    }
    return t.serialize_attr(obj, template)
end

function t.serialize_attr_data(obj)
    local template ={ [1]={type=CKA.LABEL},
                      [2]={type=CKA.APPLICATION },
                      [3]={type=CKA.OBJECT_ID},
                    }
    return t.serialize_attr(obj, template)
end

function t.serialize_attr_secretkey(obj)
    local template ={ [1]={type=CKA.LABEL},
                      [2]={type=CKA.ID},
                      [3]={type=CKA.START_DATE, fixed=true, default=string.rep('\000', 8)},
                      [4]={type=CKA.END_DATE, fixed=true, default=string.rep('\000', 8)},
                      [5]={type=CKA.SUBJECT},
                      [7]={type=CKA.VALUE},
                    }
    return t.serialize_attr(obj, template)
end

function t.serialize_attr_ecc_priv_pub_key(obj)

    local template ={ [1]={type=CKA.LABEL},
                      [2]={type=CKA.ID},
                      [3]={type=CKA.START_DATE, fixed=true, default=string.rep(string.char(0), 8)},
                      [4]={type=CKA.END_DATE, fixed=true, default=string.rep(string.char(0), 8)},
                      [5]={type=CKA.SUBJECT},
                      [6]={type=CKA.EC_POINT},
                      [7]={type=CKA.EC_PARAMS},
                    }
    return t.serialize_attr(obj, template)
end

-- controlla il template di un oggetto che deve essere creato o generato
function t.create_object_check_template(obj, generate, max_key_bits)
    if not obj[CKA.CLASS] then return CKR.TEMPLATE_INCOMPLETE end
    if max_key_bits == nil then max_key_bits = 1024 end
    if generate == nil then generate = false end
    
    if obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        if not generate and not (obj[CKA.MODULUS] and obj[CKA.PUBLIC_EXPONENT]) then
            log.output('create_object_check_template(): MODULUS or PUBLIC_EXPONENT missing')
            return CKR.TEMPLATE_INCOMPLETE
        elseif generate and not obj[CKA.MODULUS_BITS] then
            log.output('create_object_check_template(): MODULUS_BITS missing')
            return CKR.TEMPLATE_INCOMPLETE
        end
        
        if not obj[CKA.KEY_TYPE] then
            log.output('create_object_check_template(): key type missing')
            return CKR.TEMPLATE_INCOMPLETE
        end
        
        if obj[CKA.KEY_TYPE] ~= eCK.ULONG(CKK.RSA) then
            log.output('create_object_check_template(): key type invalid', hex.hexify(obj[CKA.KEY_TYPE]) )
            return CKR.ATTRIBUTE_VALUE_INVALID
        end
        if obj[CKA.MODULUS] and (string.len(obj[CKA.MODULUS])*8 > max_key_bits) then
            log.output('create_object_check_template(): key too long', hex.hexify(obj[CKA.MODULUS_BITS]) )
            return CKR.ATTRIBUTE_VALUE_INVALID
        end
        if obj[CKA.MODULUS_BITS] and (obj[CKA.MODULUS_BITS] > eCK.ULONG(max_key_bits) ) then
            log.output('create_object_check_template(): key too long', hex.hexify(obj[CKA.MODULUS_BITS]) )
            return CKR.ATTRIBUTE_VALUE_INVALID
        end
    
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        if not generate 
           and not (obj[CKA.MODULUS] and obj[CKA.PUBLIC_EXPONENT] 
                    and obj[CKA.PRIVATE_EXPONENT] ) then
            log.output('create_object_check_template(): MODULUS or PRIVATE_EXPONENT or PUBLIC_EXPONENT missing')
            return CKR.TEMPLATE_INCOMPLETE
        end
        if not obj[CKA.KEY_TYPE] then
            log.output('create_object_check_template(): key type missing')
            return CKR.TEMPLATE_INCOMPLETE
        end
        if obj[CKA.KEY_TYPE] ~= eCK.ULONG(CKK.RSA) then
            log.output('create_object_check_template(): key type invalid', hex.hexify(obj[CKA.KEY_TYPE]) )
            return CKR.ATTRIBUTE_VALUE_INVALID
        end
        if obj[CKA.MODULUS] and (string.len(obj[CKA.MODULUS])*8 > max_key_bits) then
            log.output('create_object_check_template(): key too long', hex.hexify(obj[CKA.MODULUS_BITS]) )
            return CKR.ATTRIBUTE_VALUE_INVALID
        end
    
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        if not obj[CKA.VALUE] then
            log.output('create_object_check_template(): missing certificate value')
            return CKR.TEMPLATE_INCOMPLETE
        end
    
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        -- niente da verificare, tutto opzionale
    
    else
        log.output('create_object_check_template(): unspupported object class', obj[CKA.CLASS] )
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    return CKR.OK
end

function t.serialize_ds_objlist(ds_objlist)
    local i, v
    local result = ''
    for i, v in ds_objlist do
        result = result .. string.char(v.usage) .. v.id .. hex.hexf('%H', v.infos)
    end
    return result
end

function t.look_for_free_id(object_class, ds_objlist, start_id, start_slot)
    local i, v
    local idList = {}
    local cur_id = 0
    local ffid, slot = 0, -1
    if not start_slot then start_slot = 1 end
    -- compila una lista di ID occupati
    for i=start_slot,table.getn(ds_objlist) do
        v = ds_objlist[i]
        ffid = bin.flags(v.id_numeric)
        if v.usage ~= 0 and (ffid * t.objFIDS.eMASK) == object_class then
            cur_id = (ffid * t.objFIDS.eNumMASK ).asnumber
            idList[cur_id] = true
        end
    end
    -- cerca il primo id libero (usa come limite la lunghezza di ds_objlist)
    --print ('start_id', start_id, 'idList:', utility.repr(idList))
    for i=start_id,255 do
        if not idList[i] and i >= start_id then
            log.output('look_for_free_id(): found id', i )
            return i
        end
    end
    return nil
end

function t.look_for_free_id2(object_class1, object_class2, ds_objlist, start_id, start_slot)
    local i, v
    local idList = {}
    local cur_id = 0
    local ffid, slot = 0, -1
    if not start_slot then start_slot = 1 end
    -- compila una lista di ID occupati
    for i=start_slot,table.getn(ds_objlist) do
        v = ds_objlist[i]
        ffid = bin.flags(v.id_numeric)
        if v.usage ~= 0 and ((ffid * t.objFIDS.eMASK) == object_class1 or (ffid * t.objFIDS.eMASK) == object_class2) then
            cur_id = (ffid * t.objFIDS.eNumMASK ).asnumber
            idList[cur_id] = true
        end
    end
    -- cerca il primo id libero (usa come limite la lunghezza di ds_objlist)
    --print ('start_id', start_id, 'idList:', utility.repr(idList))
    for i=start_id,255 do
        if not idList[i] and i >= start_id then
            log.output('look_for_free_id2(): found id', i )
            return i
        end
    end
    return nil
end


function t.look_for_free_slots(ds_objlist, number_of_slots, start_from)
    local i, v
    local slots = {}
    local count = 0
    if not start_from then start_from = 1 end
    
    for i=start_from,table.getn(ds_objlist) do
        v = ds_objlist[i]
        if v.usage == 0 then
            count = count +1
            slots[count] = v.index
            if count == number_of_slots then break end
        end
    end
    table.setn(slots, count)
    return slots
end

return t

--===========================================================================
end
}
_LOADED['token-athena'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- pcsc-token-cns.lua
local CnsSmartcard = require 'CnsSmartcard'
local CnsSmartcard_w = require 'CnsSmartcard_w'

local CnsSmartcardCommon = require 'CnsSmartcardCommon'
local fileTypes = CnsSmartcardCommon.fileTypes
local CnsSmartcardError = CnsSmartcardCommon.CnsSmartcardError

local zlib = require "zlib"

local hex = require 'hex'
local hexf = hex.hexf
local der = require 'der'
local utility = require 'utility'
local rsa = require 'rsa'
local licensing = require 'licensing'

local objCnsTmpl = require 'token-cns-objects'
local objP11Tmpl = require 'token-p11-objects'

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

local MinKSize, MaxKSize = 1024, 2048
local DS_FS_VERSION_2_0 = tonumber('20', 16)

local t = {
    name = 'athena',
    mt = { },
    mechanisms = {
        [ CKM.RSA_PKCS_KEY_PAIR_GEN ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.GENERATE_KEY_PAIR},
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_X_509 ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.HW+CKF.DECRYPT+CKF.SIGN},
    },
    cns_hcard = nil,
    capabilities = { private_attributes_readable=false, always_authenticate_on_cert=true, },
    
    CnsSmartcard=CnsSmartcard,
    CnsSmartcard_w=CnsSmartcard_w,
}
t.mt.__index = t.mt

-- patch della card CNS base: aggiunge le funzioni per la carta ATHENA

-- OK
function CnsSmartcard.mt:create_rsa_bso_athena(rsa_info, sm_enc, sm_sig)
    
    --print('create_rsa_bso():', utility.repr(rsa_info))
    
    local put_data_oci_mod, put_data_oci_exp
    local put_data_oci_mod_2, put_data_oci_exp_2
    
    local recv
    local algo, dict, ac, sm
    local recv, sw
    
    local modulus, modulus_2
    local exponent, exponent_2
    
    if rsa_info.modulus then
        rsa_info.key_bits = 8 * string.len(rsa_info.modulus)
    elseif not rsa_info.key_bits then
        error(CnsSmartcardError.new(nil, 'moduls nor key_bits was specified, unknown key size'), 2)
    end
    
    if rsa_info.pso_dec then algo='0c' else algo='88' end
    local modId = hex.hexf('20%B', rsa_info.kid)
    local expId = hex.hexf('21%B', rsa_info.kid)

    ac = CnsSmartcard_w._convert2bsoac(rsa_info, rsa_info._ac_padto or 7)
    sm = CnsSmartcard_w._convert2bsosm(rsa_info)
    
    local ccms, pad_to
    if rsa_info.key_bits > 1024 then
        ccms = hex.hexf('0100')
        pad_to = 256
    else
        ccms = hex.hexf('8100')
        pad_to = 128
    end
    dict = {
        [tonumber('83', 16)] = modId,
        [tonumber('85', 16)] = hex.hexf('2200' .. algo .. '0FFFFF0008'),
        [tonumber('86', 16)] = ac,
        [tonumber('CB', 16)] = sm,
        [tonumber('8f', 16)] = ccms .. (rsa_info.modulus or string.rep(hex.hexf('ff'), pad_to) ),
    }
    
    local apdu_data = CnsSmartcard_w.build_ext_tlv(dict)
    if string.len(apdu_data) > 200 then
        put_data_oci_mod =   hex.hexf('10DA016E%P', string.sub(apdu_data, 1, 200) )
        put_data_oci_mod_2 = hex.hexf('00DA016E%P', string.sub(apdu_data, 201, -1) )
    else
        put_data_oci_mod = hex.hexf('00DA016E%P', apdu_data )
    end
    --print(hex.hexify(put_data_oci_mod))
    
    dict[tonumber('83', 16)] = expId
    dict[tonumber('85', 16)] = hex.hexf('0200' .. algo .. '0FFFFF0008')
    dict[tonumber('8f', 16)] = ccms .. (rsa_info.exponent or string.rep(hex.hexf('ff'), pad_to) )
    
    local apdu_data = CnsSmartcard_w.build_ext_tlv(dict)
    
    if string.len(apdu_data) > 200 then
        put_data_oci_exp =   hex.hexf('10DA016E%P', string.sub(apdu_data, 1, 200) )
        put_data_oci_exp_2 = hex.hexf('00DA016E%P', string.sub(apdu_data, 201, -1) )
    else
        put_data_oci_exp = hex.hexf('00DA016E%P', apdu_data )
    end
    --print(hex.hexify(put_data_oci_exp))
    
    recv =  self:sm_transmit(put_data_oci_mod, sm_enc, sm_sig)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CnsSmartcardError.new(sw, 'put_data_oci_mod Error'), 2)
    end
    if put_data_oci_mod_2 then
        recv =  self:sm_transmit(put_data_oci_mod_2, sm_enc, sm_sig)
        sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            error(CnsSmartcardError.new(sw, 'put_data_oci_mod_2 Error'), 2)
        end
    end
    
    recv =  self:sm_transmit(put_data_oci_exp, sm_enc, sm_sig)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CnsSmartcardError.new(sw, 'put_data_oci_exp Error'), 2)
    end
    
    if put_data_oci_exp_2 then
        recv =  self:sm_transmit(put_data_oci_exp_2, sm_enc, sm_sig)
        sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            error(CnsSmartcardError.new(sw, 'put_data_oci_exp_2 Error'), 2)
        end
    end

end

-- OK
function CnsSmartcard.mt:delete_file_athena(fid, mode)
    local apdu
    if not mode then mode = 2 end
    local apdu_head = hex.hexify(hexf("00E4%B00", mode))
    if type(fid)=='number' then
        apdu = hexf(apdu_head .. '02%H', fid)
    else
        apdu = hexf(apdu_head .. '%P', fid)
    end 
    local recv = self:transmit(apdu)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        log.output('delete_file(): error:', hex.hexify(sw))
        error(CnsSmartcardError.new(sw, 'delete_file Error'), 2)
    end
end

-- OK
function CnsSmartcard.mt:read_public_key_athena(kid, sm_enc, sm_sig)
    local apdu, recv, sw
    local modulus, pubExp
    log.output("read_public_key_athena: kid:", kid)
    recv = self:transmit(hexf("0022F303"))
    recv = self:transmit(hexf("0022F1B8038301%B", kid))
    recv = self:transmit(hexf("0022F1B6038301%B", kid))
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        log.output('read_public_key_athena(): MSE set error:', hex.hexify(sw))
        error(CnsSmartcardError.new(sw, 'read_public_key_athena Error'), 2)
    end
    
    recv = self:sm_transmit(hexf("002a8a1000"), sm_enc, sm_sig)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        log.output('read_public_key_athena(): read modulus error:', hex.hexify(sw))
        error(CnsSmartcardError.new(sw, 'read_public_key_athena Error'), 2)
    end
    modulus = string.sub(recv, 1, -3)
    
    recv = self:sm_transmit(hexf("002a8a1100"), sm_enc, sm_sig)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        log.output('read_public_key_athena(): read modulus error:', hex.hexify(sw))
        error(CnsSmartcardError.new(sw, 'read_public_key_athena Error'), 2)
    end
    pubExp = string.sub(recv, 1, -3)
    
    return modulus, pubExp
    
end

-- function CnsSmartcard.mt:delete_file(fid, forcethisdf)
    -- return self:delete_ef_athena(fid)
-- end

function CnsSmartcard.mt:delete_ef_athena(fid)
    return self:delete_file_athena(fid, 2)
end

function CnsSmartcard.mt:delete_df_athena(fid)
    return self:delete_file_athena(fid, 1)
end

function CnsSmartcard.mt:delete_bso_athena(fid)
    return self:delete_file_athena(fid, 10)
end

function CnsSmartcard.mt:delete_current_df_athena()
    return self:delete_file_athena("", 4)
end




-------------------------
-------------------------
function t.mt:generate_key_pair_athena(kid, tlvPath, pub_exp_bits, sm_enc, sm_sig )
    if type(kid) == 'string' then 
        if string.len(kid) == 1 then
            kid = string.byte(kid)
        else
            kid = tonumber(kid, 16)
        end
    end
    self.cns_hcard:generate_key_pair(kid, nil, pub_exp_bits)
    
    local rv
    local modulus, pubExp = self.cns_hcard:read_public_key_athena(kid, sm_enc, sm_sig)
    if string.len(modulus) > 128 then
        self.cns_hcard:select(hex.hexf(tlvPath))
        rv, modulus = self:_pad_bignum(modulus, 256)
        rv, pubExp = self:_pad_bignum(pubExp, 8)
        self.cns_hcard:mupdate_binary(0, modulus)
        self.cns_hcard:mupdate_binary(256, pubExp)
    else
        rv, modulus = self:_pad_bignum(modulus, 128)
        modulus = hex.hexf('10828100')  .. modulus
        pubExp = hex.hexf('11%B%B00', string.len(pubExp)+2, string.len(pubExp)+1)  .. pubExp
        self:update_append_record(tlvPath, 1, modulus)
        self:update_append_record(tlvPath, 2, pubExp)
    end
    return modulus, pubExp
end
-------------------------
-------------------------


function t.mt:initialize(cfg)
    self.capabilities = utility.clone_table(t.capabilities)
    self.cns_hcard = CnsSmartcard.new(self.hcard)
    self.cns_hcard._ef_ac_padto = 8
    self.request_plugin_valid = w32.request_plugin_valid()
    self.cfg = cfg or utility.parse_cfg()

    self.cfg["dspiniscnspin"] = self.cfg["tdspiniscnspin"] or self.cfg["dspiniscnspin"]
    self.cfg["dspinusegui"] = self.cfg["tdspinusegui"] or self.cfg["dspinusegui"]
    self.cfg["hidecachedspincheck"] = self.cfg["thidecachedspincheck"] or self.cfg["hidecachedspincheck"]
    self.cfg["fcpr"] = self.cfg["fcpr"] or self.cfg["afcpr"]
    self.cfg["xproc"] = self.cfg["xproc"] or self.cfg["axproc"]
        
    if self.cfg["fcpr"] then
        self.cfg["fcpr"]=string.lower(self.cfg["fcpr"])
        self.use_cpr_mode = self.cfg["fcpr"] == "true"
    else
        -- non specificato: a aprtire da agosto 2011
        self.use_cpr_mode = ( os.time() > os.time({year=2011, month=8, day=1}) )
    end
    
    if self.cfg["xproc"] then self.cfg["xproc"]=string.lower(self.cfg["dspinusegui"])
    else self.cfg["xproc"]='true' end

    log.output('Athena token initialize(): use_cpr_mode:', self.use_cpr_mode)
    
    -- se il plugin del PIN non 