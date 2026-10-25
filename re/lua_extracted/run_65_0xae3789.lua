 stato ricevuto
        end
    else
        recv = self:transmit(apdu)
    end
    return recv
end

local function build_ext_tlv(dict, order)
    local tlv = '', i
    if type(order) ~= "table" then
        order = {}
        for i =0,255 do
            order[i] = i
        end        
    end
    for x,i in order do
        if dict[i] then
            if string.len(dict[i]) > 254 then
                tlv = tlv .. string.char(i) .. "\255" .. hex.hexf("%H", string.len(dict[i])) .. dict[i]
            else
                --print (i, hex.hexify(dict[i]))
                tlv = tlv .. string.char(i) .. string.char(string.len(dict[i])) .. dict[i]
            end
        end
    end
    return tlv
end

function CnsSmartcard.mt:create_rsa_bso_oberthur(rsa_info, sm_enc, sm_sig)
    
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
    
    local ccms = hex.hexf('8100')
    if rsa_info.key_bits > 1024 then
        modulus = rsa_info.modulus and string.sub(rsa_info.modulus, 1, 128) or string.rep(hex.hexf('ff'), 128)
        modulus_2 = rsa_info.modulus and string.sub(rsa_info.modulus, 129, -1) or string.rep(hex.hexf('ff'), 128)
        exponent = rsa_info.exponent and string.sub(rsa_info.exponent, 1, 128) or string.rep(hex.hexf('ff'), 128)
        exponent_2 = rsa_info.exponent and string.sub(rsa_info.exponent, 129, -1) or string.rep(hex.hexf('ff'), 128)
    else
        modulus = rsa_info.modulus or string.rep(hex.hexf('ff'), 128)
        exponent = rsa_info.exponent or string.rep(hex.hexf('ff'), 128)
    end
    dict = {
        [tonumber('83', 16)] = modId,
        [tonumber('85', 16)] = hex.hexf('2200' .. algo .. '0FFFFF0000'),
        [tonumber('86', 16)] = ac,
        [tonumber('CB', 16)] = sm,
        [tonumber('8f', 16)] = ccms .. modulus,
    }
    local order = {
        tonumber('83', 16),
        tonumber('85', 16),
        tonumber('86', 16),
        tonumber('CB', 16),
        tonumber('8f', 16),
    }
    
    put_data_oci_mod = hex.hexf('%BDA016E%P', modulus_2 and 16 or 0, build_ext_tlv(dict, order) )
    put_data_oci_mod_2 = modulus_2 and hex.hexf('00DA016E%P', modulus_2 )
    --print(hex.hexify(put_data_oci_mod))
    
    dict[tonumber('83', 16)] = expId
    dict[tonumber('85', 16)] = hex.hexf('0200' .. algo .. '0FFFFF0000')
    dict[tonumber('8f', 16)] = ccms .. exponent
    put_data_oci_exp = hex.hexf('%BDA016E%P',  exponent_2 and 16 or 0, build_ext_tlv(dict, order) )
    put_data_oci_exp_2 = exponent_2 and hex.hexf('00DA016E%P',  exponent_2)
    --print(hex.hexify(put_data_oci_exp))
    
    recv =  self:sm_transmit(put_data_oci_mod, sm_enc, sm_sig)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CnsSmartcardError.new(sw, 'put_data_oci_mod Error'), 2)
    end
    if put_data_oci_mod_2 then
        recv =  self:sm_transmit_oberthur(put_data_oci_mod_2, sm_enc, sm_sig, true)
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
        recv =  self:sm_transmit_oberthur(put_data_oci_exp_2, sm_enc, sm_sig, true)
        sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            error(CnsSmartcardError.new(sw, 'put_data_oci_exp_2 Error'), 2)
        end
    end
end


-- data: binary string, path and id: hex ascii strings
function CnsSmartcard.mt:rsa_oberthur(data, path, id)
    local sw
    local data_1 = string.sub(data, 1, 128)
    local data_2 =  string.sub(data, 129, -1)
    data_2 = string.len(data_2) > 0 and data_2
    local recv
    if path ~=nil then
        self:select(hexf(path))
    end
    if id == nil then id = '01'
    elseif type(id) == 'number' then 
        id = hex.hexify(hex.hexf('%B', id))
    elseif string.len(id) == 1 then 
        id = hex.hexify(id)
    end
    -- MANAGE SECURITY ENVIRONMENT RESTORE
    sw = self:transmit(hexf('0022F303'))
    if sw == hexf('6700') then
        sw = self:transmit(hexf('0022F303'))
    end
    if sw ~= hexf('9000') and sw ~= hexf('6700') then
        error(CnsSmartcardError.new(sw, 'MSE restore Error' ), 2)
    end
    -- MANAGE SECURITY ENVIRONMENT SET
    sw = self:transmit(hexf('0022F1B8038301' .. id))
    if sw ~= hexf('9000') then
        error(CnsSmartcardError.new(sw, 'MSE set Error' ), 2)
    end
    recv = self:transmit(hexf('%B2A8086%P00',data_2 and 16 or 0, '\0' .. data_1))
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CnsSmartcardError.new(sw, 'rsa_oberthur part1 error' ), 2)
    end
    if data_2 then
        recv = self:transmit(hexf('002A8086%P00', data_2))
        sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            error(CnsSmartcardError.new(sw, 'rsa_oberthur part2 error' ), 2)
        end
    end
    return string.sub(recv, 1, -3)
end


-- data: binary string, path and id: hex ascii strings
function CnsSmartcard.mt:rsa_oberthur_sm(data, path, id, sm_enc, sm_sig)
    local sw
    local data_1 = string.sub(data, 1, 128)
    local data_2 =  string.sub(data, 129, -1)
    data_2 = string.len(data_2) > 0 and data_2
    local recv
    if path ~=nil then
        self:select(hexf(path))
    end
    if id == nil then id = '01'
    elseif type(id) == 'number' then 
        id = hex.hexify(hex.hexf('%B', id))
    elseif string.len(id) == 1 then 
        id = hex.hexify(id)
    end
    -- MANAGE SECURITY ENVIRONMENT RESTORE
    sw = self:transmit(hexf('0022F303'))
    if sw == hexf('6700') then
        sw = self:transmit(hexf('0022F303'))
    end
    if sw ~= hexf('9000') and sw ~= hexf('6700') then
        error(CnsSmartcardError.new(sw, 'MSE restore Error' ), 2)
    end
    -- MANAGE SECURITY ENVIRONMENT SET
    sw = self:transmit(hexf('0022F1B8038301' .. id))
    if sw ~= hexf('9000') then
        error(CnsSmartcardError.new(sw, 'MSE set Error' ), 2)
    end
    recv = self:sm_transmit(hexf('%B2A8086%P00',data_2 and 16 or 0, '\0' .. data_1), sm_enc, sm_sig)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CnsSmartcardError.new(sw, 'rsa_oberthur part1 error' ), 2)
    end
    if data_2 then
        recv = self:sm_transmit_oberthur(hexf('002A8086%P00', data_2), sm_enc, sm_sig, true)
        sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            error(CnsSmartcardError.new(sw, 'rsa_oberthur part2 error' ), 2)
        end
    end
    return string.sub(recv, 1, -3)
end


-- 0x40 -- p = Prime number P          format: LEN-OF-FOLLOWING 00 p_COMPONENT_VALUE
-- 0x41 -- a = Parameter A             format: LEN-OF-FOLLOWING 00 a_COMPONENT_VALUE
-- 0x42 -- b = Parameter B             format: LEN-OF-FOLLOWING 00 b_COMPONENT_VALUE
-- 0x43 -- G = Generator point         format: LEN-OF-FOLLOWING 00 04 Gx_COMPONENT_VALUE Gy_COMPONENT_VALUE  (uncompressed format only!)
-- 0x44 -- r = Order of the generator  format: LEN-OF-FOLLOWING 00 r_COMPONENT_VALUE

local hexf2 = function(v, ...) return hex.hexf(string.gsub(v, '%s', ''), unpack(arg)) end

local Ed25519_GNU_OID = "1.3.6.1.4.1.11591.15.1" -- names: Ed25519
local Ed25519_THAWTE_OID = "1.3.101.112" -- names: Edwards25519 / EdDSA25519
local X25519_THAWTE_OID = "1.3.101.110" -- names: Curve25519/X25519

local Ed25519_curves_oids = {
    [Ed25519_GNU_OID]="Ed25519",
    [Ed25519_THAWTE_OID]="Ed25519",
}

local X25519_curves_oids = {
    [X25519_THAWTE_OID]="X25519",
}

local Ed25519_curves_names = {
    Ed25519=Ed25519_THAWTE_OID,
    EdDSA25519=Ed25519_THAWTE_OID,
    Edwards25519=Ed25519_THAWTE_OID,
}

local X25519_curves_namess = {
    X25519=X25519_THAWTE_OID,
    Curve25519=X25519_THAWTE_OID,
}


-- OIDs:
-- 1.3.6.1.4.1.11591.15.1 Ed25519
-- 1.2.840.10045.3.1.1 secp192r1
-- 1.3.132.0.33 secp224r1
-- 1.2.840.10045.3.1.7 secp256r1
-- 1.3.132.0.34 secp384r1
-- 1.3.132.0.35 secp521r1
-- 1.3.132.0.10 secp256k1
local domain_parameters = {

    secp192r1 = { -- PARAMS OK, TESTED
        name = "secp192r1",
        asciiOid = "1.2.840.10045.3.1.1", -- oid prime192v1; ansi-X9-62 curves(3) prime(1) 1 -> iso(1) member-body(2) us(840) 10045 curves(3) prime(1) 1; https://oidref.com/1.2.840.10045.3.1.1
        keysize=192/8,
        pubkeysize=192/4 + 5, -- TAG_20 + LEN + [LEN + [00 + 04 + [Gx+Gy]]]
        ref = hexf("01"),
        p = hexf2("19 00 FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFF"),
        a = hexf2("19 00 FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFC"),
        b = hexf2("19 00 64210519E59C80E70FA7E9AB72243049FEB8DEECC146B9B1"),
        G = hexf2("32 00 04 188DA80EB03090F67CBF20EB43A18800F4FF0AFD82FF1012 07192B95FFC8DA78631011ED6B24CDD573F977A11E794811"),
        r = hexf2("19 00 FFFFFFFFFFFFFFFFFFFFFFFF99DEF836146BC9B1B4D22831"),
    },
    
    secp224r1 = { -- PARAMS OK, TESTED
        name = "secp224r1",
        asciiOid = "1.3.132.0.33", -- oid ansip224r1; https://oidref.com/1.3.132.0.33
        keysize=224/8,
        pubkeysize=224/4 + 5, -- TAG_20 + LEN + [LEN + [00 + 04 + [Gx+Gy]]]
        ref = hexf("02"),
        p = hexf2("1D 00 FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000001"),
        a = hexf2("1D 00 FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFE"),
        b = hexf2("1D 00 B4050A850C04B3ABF54132565044B0B7D7BFD8BA270B39432355FFB4"),
        G = hexf2("3A 00 04 B70E0CBD6BB4BF7F321390B94A03C1D356C21122343280D6115C1D21 BD376388B5F723FB4C22DFE6CD4375A05A07476444D5819985007E34"),
        r = hexf2("1D 00 FFFFFFFFFFFFFFFFFFFFFFFFFFFF16A2E0B8F03E13DD29455C5C2A3D"),
    },
    
    secp256r1 = { -- OK, TESTED
        name = "secp256r1",
        asciiOid = "1.2.840.10045.3.1.7", -- oid prime256v1 -- ansi-X9-62 curves(3) prime(1) 7 -> iso(1) member-body(2) us(840) 10045 curves(3) prime(1) 7; https://oidref.com/1.2.840.10045.3.1.7
        keysize=256/8,
        pubkeysize=256/4 + 5, -- TAG_20 + LEN + [LEN + [00 + 04 + [Gx+Gy]]]
        ref = hexf("03"),
        p = hexf2("21 00 FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF"),
        a = hexf2("21 00 FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC"),
        b = hexf2("21 00 5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B"),
        G = hexf2("42 00 04 6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296 4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5"),
        r = hexf2("21 00 FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551"),
    },
    
    secp384r1 = { -- OK, TESTED
        name = "secp384r1",
        asciiOid = "1.3.132.0.34", -- oid ansip384r1; https://oidref.com/1.3.132.0.34
        ref = hexf("04"),
        keysize=384/8,
        pubkeysize=384/4 + 5, -- TAG_20 + LEN + [LEN + [00 + 04 + [Gx+Gy]]]
        p = hexf2("31 00 FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFF0000000000000000FFFFFFFF"),
        a = hexf2("31 00 fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000fffffffc"),
        b = hexf2("31 00 B3312FA7E23EE7E4988E056BE3F82D19181D9C6EFE8141120314088F5013875AC656398D8A2ED19D2A85C8EDD3EC2AEF"),
        G = hexf2("62 00 04 AA87CA22BE8B05378EB1C71EF320AD746E1D3B628BA79B9859F741E082542A385502F25DBF55296C3A545E3872760AB7 3617DE4A96262C6F5D9E98BF9292DC29F8F41DBD289A147CE9DA3113B5F0B8C00A60B1CE1D7E819D7A431D7C90EA0E5F"),
        r = hexf2("31 00 ffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc52973"),
    },
    
    secp521r1 = { -- OK, TESTED
        name = "secp521r1",
        asciiOid = "1.3.132.0.35", -- oid ansip521r1; https://oidref.com/1.3.132.0.35
        ref = hexf("05"),
        keysize=528/8,
        pubkeysize=528/4 + 5, -- TAG_20 + LEN + [LEN + [00 + 04 + [Gx+Gy]]]
        p = hexf2("43 00 01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"),
        a = hexf2("43 00 01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC"),
        b = hexf2("43 00 0051953EB9618E1C9A1F929A21A0B68540EEA2DA725B99B315F3B8B489918EF109E156193951EC7E937B1652C0BD3BB1BF073573DF883D2C34F1EF451FD46B503F00"),
        G = hexf2("86 00 04 00C6858E06B70404E9CD9E3ECB662395B4429C648139053FB521F828AF606B4D3DBAA14B5E77EFE75928FE1DC127A2FFA8DE3348B3C1856A429BF97E7E31C2E5BD66 011839296A789A3BC0045C8A5FB42C7D1BD998F54449579B446817AFBD17273E662C97EE72995EF42640C550B9013FAD0761353C7086A272C24088BE94769FD16650"),
        r = hexf2("43 00 01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFA51868783BF2F966B7FCC0148F709A5D03BB5C9B8899C47AEBB6FB71E91386409"),
    },
    
    secp256k1 = { -- OK, TESTED
        name = "secp256k1",
        asciiOid = "1.3.132.0.10", -- oid ansip256k1; https://oidref.com/1.3.132.0.10
        keysize=256/8,
        pubkeysize=256/4 + 5, -- TAG_20 + LEN + [LEN + [00 + 04 + [Gx+Gy]]]
        ref = hexf("10"),
        p = hexf2("21 00 fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f"),
        a = hexf2("21 00 0000000000000000000000000000000000000000000000000000000000000000"),
        b = hexf2("21 00 0000000000000000000000000000000000000000000000000000000000000007"),
        G = hexf2("42 00 04 79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798 483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8"),
        r = hexf2("21 00 fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"),
    },
}

local dp_component_names_to_ids = {
    p = hex.hexf("40"),
    a = hex.hexf("41"),
    b = hex.hexf("42"),
    G = hex.hexf("43"),
    r = hex.hexf("44"),
}

local dp_component_flags_to_bso_ids = {
}

local named_curves_ascii_oid_to_dp = {
}

local named_curves_name_to_dp = {
}

for i, v in domain_parameters do
    named_curves_ascii_oid_to_dp[v.asciiOid] = v
    named_curves_name_to_dp[v.name] = v
    local flag = 2^string.byte(v.ref)
    dp_component_flags_to_bso_ids[flag] = v  
end

CnsSmartcard.mt.domain_parameters_oberthur = domain_parameters
CnsSmartcard.mt.named_curves_ascii_oid_to_dp_oberthur = named_curves_ascii_oid_to_dp


function CnsSmartcard.mt.get_domain_parameter_by_name_oberthur(name)
    return named_curves_name_to_dp[name]
end

function CnsSmartcard.mt.get_domain_parameter_by_ascii_oid_oberthur(asciiOid)
    return named_curves_ascii_oid_to_dp[asciiOid]
end

function CnsSmartcard.mt:erase_rsa_bso_oberthur(kid, sm_enc, sm_sig)
    log.output('erase_rsa_bso_oberthur(): kid: ', kid)
    local componentId = hex.hexf('20%B', kid)
    return self:erase_bso_oberthur(componentId, sm_enc, sm_sig)
end
function CnsSmartcard.mt:erase_ecc_bso_oberthur(kid, sm_enc, sm_sig)
    log.output('erase_ecc_bso_oberthur(): kid: ', kid)
    local componentId = hex.hexf('38%B', kid)
    return self:erase_bso_oberthur(componentId, sm_enc, sm_sig)
end

function CnsSmartcard.mt:erase_bso_oberthur(componentId, sm_enc, sm_sig)
    log.output('erase_bso_oberthur(): componentId: ', hex.hexify(componentId))
    local erase_bso = hex.hexf('80E4016E%P', componentId)
    log.output('erase_bso_oberthur(): erase_bso APDU: ', hex.hexify(erase_bso))
    local recv = self:sm_transmit(erase_bso, sm_enc, sm_sig)
    log.output("erase_bso_oberthur(): erasing BSO RECV: ", hex.hexify(recv or ""))
    local sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        log.output('erase_bso_oberthur(): error erasing componentId: ', hex.hexify(componentId), hex.hexify(sw or ""))
    end
end

function CnsSmartcard.mt:create_ecc_dp_bso_by_asciioid_oberthur(asciiOid, sm_enc, sm_sig)
    log.output('create_ecc_dp_bso_by_asciioid_oberthur(): creating named curve OID: ' .. asciiOid)
    local dp = named_curves_ascii_oid_to_dp[asciiOid]
    
    if not dp then
        error('create_ecc_dp_bso_by_asciioid_oberthur(): unsupported named curve OID: ' .. asciiOid)
    end
    
    self:create_ecc_dp_bso_oberthur(dp)
end
    
function CnsSmartcard.mt:create_ecc_dp_bso_oberthur(dp_info_i, sm_enc, sm_sig)
    local put_data_oci_dp
    local recv
    local algo, dict, ac, sm
    local recv, sw
    local component_names = {"p", "a", "b", "G", "r", }

    -- dp_info.aac = {use=0, change=self.cns_hcard.BSO_CNS_PIN, delete=self.cns_hcard.BSO_CNS_PIN },
    -- TODO: use above definitive ACs
    local dp_info = utility.clone_table(dp_info_i)
    
    log.output(string.format(
                'create_ecc_dp_bso_oberthur(): creating dp_info.name=%s, dp_info.asciiOid=%s', 
                dp_info.name, dp_info.asciiOid))

    assert (self.BSO_CNS_PIN)

    dp_info.aac = dp_info.aac or {use=0, delete=self.BSO_CNS_PIN }

    -- 00 DA 01 6E 5D 83 02 COMPONENT_ID DP_ID 85 08 40 00 01 0F FF FF FF 00 86 07 00 00 00 00 00 00 00 8F 44 43 00 01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    
    -- erasing BSO fails if BSO is referenced by any BSO
    log.output("create_ecc_dp_bso_oberthur(): erasing DP BSO (shal fail if any BSO reference it)")
    
    -- DP can be only on MF
    local select_mf = hexf2("00a40000023f0000")
    log.output('create_ecc_dp_bso_oberthur(): select_mf: ' .. hex.hexify(select_mf))
    recv = self:sm_transmit(select_mf)
    log.output("create_ecc_dp_bso_oberthur(): select_mf: ", hex.hexify(recv or ""))
    
    local apdu_erase_dp_bso = hexf2("80E4016E02") .. dp_component_names_to_ids["p"] .. dp_info.ref
    log.output('create_ecc_dp_bso_oberthur(): apdu_erase_dp_bso APDU: ' .. hex.hexify(apdu_erase_dp_bso))
    recv = self:sm_transmit(apdu_erase_dp_bso, sm_enc, sm_sig)
    log.output("create_ecc_dp_bso_oberthur(): erasing DP BSO: ", hex.hexify(recv or ""))
    
    sw = string.sub(recv, -2, -1)
    if sw == hexf('6985') then        
        log.output("create_ecc_dp_bso_oberthur(): got sw=6985 erarsing DP BSO, already exists and in use")
        return
    end
    if  sw == hexf('6982') then        
        log.output("create_ecc_dp_bso_oberthur(): got sw=6982 erarsing DP BSO, already exists and undeletable")
        return
    end
    
    for i=1,table.getn(component_names) do
        ac = CnsSmartcard_w._convert2bsoac(dp_info, dp_info._ac_padto or 7)
        sm = CnsSmartcard_w._convert2bsosm(dp_info)
        
        local component_name = component_names[i]
        local component = dp_info[component_name]
        local component_id = dp_component_names_to_ids[component_name]
        
        dict = {
            [tonumber('83', 16)] =  component_id .. dp_info.ref,
            [tonumber('85', 16)] = hexf2("40 00 01 0F FF FF FF 00"),
            [tonumber('86', 16)] = ac,
            [tonumber('CB', 16)] = sm,
            [tonumber('8f', 16)] = component,
        }
        local order = {
            tonumber('83', 16),
            tonumber('85', 16),
            tonumber('86', 16),
            tonumber('CB', 16),
            tonumber('8f', 16),
        }

        log.output('create_ecc_dp_bso_oberthur(): creating DP component: ' .. component_name)
        
        put_data_oci_dp = hex.hexf('00DA016E%P', build_ext_tlv(dict, order) )
        --print(hex.hexify(put_data_oci_dp))
        
        log.output('create_ecc_dp_bso_oberthur(): DP component APDU: ' .. hex.hexify(put_data_oci_dp))
        recv =  self:sm_transmit(put_data_oci_dp, sm_enc, sm_sig)
        sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            error(CnsSmartcardError.new(sw, 'put_data_oci_dp Error'), 2)
        end
    end
end

function CnsSmartcard.mt:create_ecc_bso_oberthur(bso_info_i, sm_enc, sm_sig, is_ds, dsi)
    
    local put_data_oci_dp_reference, put_data_oci_priv_component
    local recv
    local algo, dict, ac, sm
    local recv, sw
    
    log.output('create_ecc_bso_oberthur()...')
    log.output('create_ecc_bso_oberthur(): sm_enc: ', hex.hexify(sm_enc or "") )
    log.output('create_ecc_bso_oberthur(): sm_sig: ', hex.hexify(sm_sig or "") )
    log.output('create_ecc_bso_oberthur(): is_ds: ', is_ds )
    if not bso_info_i.asciiOid then
        error('create_ecc_bso_oberthur: error: der bso_info.asciiOid is nil')
    end


    log.output('create_ecc_bso_oberthur(): bso_info.asciiOid: ' .. bso_info_i.asciiOid)
    
    local dp = named_curves_ascii_oid_to_dp[bso_info_i.asciiOid]
    if not dp then
        error('create_ecc_bso_oberthur(): unsupported named curve OID: ' .. bso_info_i.asciiOid)
    end
    
    local bso_info = utility.clone_table(bso_info_i)
    
    
    bso_info.aac =  bso_info.aac or {use=self.BSO_CNS_PIN, 
                                     change=self.BSO_CNS_PIN, 
                                     delete=self.BSO_CNS_PIN, 
                                     generate=self.BSO_CNS_PIN}
    -- bso_info.aac = bso_info.aac or {use=0, change=0, delete=0, generate=0 }

    if is_ds then
        bso_info.aac.use = self.BSO_DS_PIN
        bso_info.aac.change = nil
        if not bso_info.asm and dsi and dsi.sm_admin_enc and dsi.sm_admin_sig and dsi.sm_use_enc and dsi.sm_use_sig then
            bso_info.asm = {
            use_in_enc=dsi.sm_use_enc_id, use_in_sig=dsi.sm_use_sig_id,
            use_out_enc=dsi.sm_use_enc_id, use_out_sig=dsi.sm_use_sig_id,
            change_enc=dsi.sm_admin_enc_id, change_sig=dsi.sm_admin_sig_id }
        end
    end
    
    
    algo = "91"
    local pub_componentId = hex.hexf('38%B', bso_info.kid)
    local priv_componentId = hex.hexf('39%B', bso_info.kid)


    ac = CnsSmartcard_w._convert2bsoac(bso_info, bso_info._ac_padto or 7)
    sm = CnsSmartcard_w._convert2bsosm(bso_info)
    
    dict = {
        [tonumber('83', 16)] = pub_componentId,
        [tonumber('85', 16)] = hex.hexf('4100' .. algo .. 'FFFFFFFF00'),
        [tonumber('86', 16)] = ac,
        [tonumber('CB', 16)] = sm,
        [tonumber('8f', 16)] = dp.ref,
    }
    local order = {
        tonumber('83', 16),
        tonumber('85', 16),
        tonumber('86', 16),
        tonumber('CB', 16),
        tonumber('8f', 16),
    }
  

    put_data_oci_dp_reference = hex.hexf('00DA016E%P', build_ext_tlv(dict, order) )
    --print(hex.hexify(put_data_oci_dp_reference))
    
    log.output('create_ecc_bso_oberthur(): put_data_oci_dp_reference APDU: ' .. hex.hexify(put_data_oci_dp_reference))
    
    if bso_info.private_component then
        local private_component1 = hex.hexf( "%P", "\0" .. bso_info.private_component )
    
        
        dict[tonumber('83', 16)] = priv_componentId
        -- dict[tonumber('85', 16)] = hex.hexf('4100' .. algo .. 'FFFFFFFF00')
        dict[tonumber('8f', 16)] = private_component1
        
        put_data_oci_priv_component = hex.hexf('00DA016E%P', build_ext_tlv(dict, order) )

        log.output('create_ecc_bso_oberthur(): put_data_oci_priv_component APDU: ' .. hex.hexify(put_data_oci_priv_component))

        --print(hex.hexify(put_data_oci_priv_component))
    end
    
    
    if bso_info.path then
        self:select(bso_info.path, true)
    end
    
    self:erase_bso_oberthur(pub_componentId)
        
    recv =  self:sm_transmit(put_data_oci_dp_reference, sm_enc, sm_sig)
    log.output('create_ecc_bso_oberthur(): put_data_oci_dp_reference RESP: ' .. hex.hexify(recv))
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CnsSmartcardError.new(sw, 'put_data_oci_dp_reference Error'), 2)
    end
    
    if put_data_oci_priv_component then
        recv =  self:sm_transmit(put_data_oci_priv_component, sm_enc, sm_sig)
        log.output('create_ecc_bso_oberthur(): put_data_oci_priv_component RESP: ' .. hex.hexify(recv))
        sw = string.sub(recv, -2, -1)
        if sw ~= hexf('9000') then
            error(CnsSmartcardError.new(sw, 'put_data_oci_priv_component Error'), 2)
        end
    end

end

function CnsSmartcard.mt:generate_ecc_bso_oberthur(kid, tlvId, sm_enc, sm_sig)

    if type(kid) == 'string' then 
        if string.len(kid) == 1 then
            kid = string.byte(kid)
        else
            kid = tonumber(kid, 16)
        end
    end
    
    local apdu = hex.hexf("004600000639%B%S0000", kid, tlvId)
    log.output('generate_ecc_bso_oberthur(): APDU: ' .. hex.hexify(apdu))
    local sw, recv
    recv =  self:sm_transmit(apdu, sm_enc, sm_sig)
    log.output('generate_ecc_bso_oberthur(): RESP: ' .. hex.hexify(recv))
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CnsSmartcardError.new(sw, 'generate_ecc_bso_oberthur Error'), 2)
    end

    return self:read_ecc_pubkey_oberthur(tlvId, true)
end


function CnsSmartcard.mt:read_ecc_pubkey_oberthur(tlvId, relative)

    self:select(tlvId, true, relative)
    local pubKey = self:read_record(1, 4, 0)
    log.output('read_ecc_pubkey_oberthur(): RAW pubKey: ' .. hex.hexify(pubKey))
    
    -- format: TAG-20 LEN  + LEN 00 + 04 PUBKEY
    local pubKeyTlv = CnsSmartcard.parse_tlv(pubKey)
    local pubKeyInner = pubKeyTlv[tonumber("20", 16)]
    log.output('read_ecc_pubkey_oberthur(): pubKeyInner: ' .. hex.hexify(pubKeyInner or ""))
    local pubKeyValue = string.sub(pubKeyInner, 3, -1)
    log.output('read_ecc_pubkey_oberthur(): PUB KEY VALUE: ' .. hex.hexify(pubKeyValue or ""))
    return pubKeyValue
end

function CnsSmartcard.mt:ecdsa_oberthur(data, path, id, sm_enc, sm_sig)
    local sw
    if path ~=nil then
        self:select(hexf(path))
    end
    if id == nil then id = '01'
    elseif type(id) == 'number' then 
        id = hex.hexify(hex.hexf('%B', id))
    elseif string.len(id) == 1 then 
        id = hex.hexify(id)
    end
    -- MANAGE SECURITY ENVIRONMENT RESTORE
    sw = self:transmit(hexf('0022F303'))
    sw = string.sub(sw, -2, -1)
    if sw == hexf('6700') then
        sw = self:transmit(hexf('0022F303'))
        sw = string.sub(sw, -2, -1)
    end
    if sw == hexf('6a83') and self._mse_seid then
        sw = self:transmit(hexf('0022F3' .. self._mse_seid)) -- fix per CARDOS
        sw = string.sub(sw, -2, -1)
    end

    if sw ~= hexf('9000') and sw ~= hexf('6700') then
        error(CnsSmartcardError.new(sw, 'MSE restore Error' ), 2)
    end
    -- MANAGE SECURITY ENVIRONMENT SET
    sw = self:transmit(hexf('0022F1B6038301' .. id))
    sw = string.sub(sw, -2, -1)
    if sw ~= hexf('9000') then
        error(CnsSmartcardError.new(sw, 'MSE set Error' ), 2)
    end
    local recv = self:sm_transmit(hexf('002A9E9A%P00', data), sm_enc, sm_sig)
    sw = string.sub(recv, -2, -1)
    if sw ~= hexf('9000') then
        error(CnsSmartcardError.new(sw, 'ecdsa_oberthur error' ), 2)
    end
    return string.sub(recv, 1, -3)


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
  

function t.mt:initialize(cfg)
    self.capabilities = utility.clone_table(t.capabilities)
    self.cns_hcard = CnsSmartcard.new(self.hcard)
    self.cns_hcard.allow_6310_chained_responses = true
    self.cns_hcard.BSO_CNS_PIN = hex.h2i('10')
    self.cns_hcard.BSO_CNS_PUK = hex.h2i('11')
    self.cns_hcard.BSO_DS_PIN = hex.h2i('1d')
    self.cns_hcard.BSO_DSX_AUTH = hex.h2i('1e')
    self.cns_hcard.BSO_DS_PUK = hex.h2i('1f')
    self.cns_hcard.pz8oberthur = true
    self.check_pin_status = true
    self.ulMaxPinLen_HW = 8
    self.ds_df_pub = "9001"
    self.ds_df_priv = "9002"
    self.ds_df_ecc = "9ecc"
    
    self.pinRetry = 3
    self.pukRetry = 8
    
    local status, err = self.hcard:status()
    
    local select_v1 = hexf("00A4040010A0000000770103000610000000000002")
    local select_v2 = hexf("00a4040010A000000077010800071000FE00000900")
    
    local select_aid_default = select_v1 -- default applet is v1
    if status and status.atr == hex.hexf("3BFF1800008131FE45006B05052000012101434E5310318079") then
        select_aid_default = select_v2 -- default applet is v2
        log.output('Oberthur token initialize(): default applet type set to V2')
    else
        log.output('Oberthur token initialize(): default applet type set to V1')
    end
    
    local select_aid = select_aid_default
    
    local self_parent = self
    
    self._select_applet = function()
    
        log.output("(re)selecting CNS applet...")
        local recv, sw
        recv = self_parent.cns_hcard.card:transmit(select_aid)
        sw = string.sub(recv, -2, -1)
        if sw ~= hex.hexf("9000") and select_aid == select_aid_default then
            log.output("(re)selecting CNS applet: error, trying other applet...")
            select_aid = (select_aid == select_v1) and select_v2 or select_v1
            recv = self_parent.cns_hcard.card:transmit(select_aid)
        end
    end
    
    self.cns_hcard.on_transmit = function(self, apdu)
        if not self_parent._oberthur_applet_selected then
            if not self_parent._mobile_enabled then
                self_parent._select_applet()
            end
            self_parent._oberthur_applet_selected = true
        end
    end

    self.cns_hcard.on_begin_transaction = function(self)
        self_parent._oberthur_applet_selected = false
    end
    self.mechanisms = utility.clone_table(t.mechanisms)
    
    -- l'attributo seguente potrebbe abilitare delle ottimizzazioni che per