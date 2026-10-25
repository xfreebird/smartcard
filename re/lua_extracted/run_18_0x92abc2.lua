 piccolo che contiene "len"
function t.find_free_space(fs, file, len)
    local curLen = -1
    local sIndex = -1
    for i, v in fs do
        if v.path.efidOrPath == file then
            if v.path.length >= len and ( curLen > v.path.length or curLen < 0) then
                curLen = v.path.length
                sIndex = i
            end
        end
    end
    return sIndex
end

-- cerca un blocco libero e alloca uno spazio pari a "len"
function t.alloc_space(fs1, file, len)
    local sIndex = t.find_free_space(fs1, file, len)
    local index, authId
    if sIndex > 0 then
        local fs = util.clone_table(fs1)
        local v = fs[sIndex]
        index = v.path.index
        v.path.index = v.path.index +len
        v.path.length = v.path.length - len
        authId = v.authId
        if v.path.length == 0 then
            table.remove(fs, sIndex)
        end
        return fs, index, authId
    end
end


function t.release_space(fs1, file, index, len, authId)
--~ - cerca il blocco libero adiacente al bound inferiore ed il blocco adiacente al bound inferiore
    --~ - se esitono: effettua il merge dei blocchi adiacenti
    --~ - altrimenti: crea un nuovo blocco

    local fs = util.clone_table(fs1)
    local upper, lower
    for i, v in fs do
        if v.path.efidOrPath == file then
            log.output(i, v.path.index)
            if v.path.index - len == index then
                upper = i
                log.output("upper", upper)
            end
            if index - v.path.length == v.path.index then
                lower = i
                log.output("lower", lower)
            end
        end
    end
    if upper and lower then
        local v = fs[upper]
        local vl = fs[lower]
        -- estende upper in testa ed in coda: effettua il berge dei 3 blocchi adiacenti
        v.path.index = vl.path.index
        v.path.length = v.path.length + vl.path.length + len
        -- elimina la entry lower
        table.remove(fs, lower) -- merge dei blocchi
    elseif upper then
        -- estende upper in testa
        local v = fs[upper]
        v.path.index = v.path.index - len
        v.path.length = v.path.length + len
    elseif lower then
        -- estende lower in coda
        local v = fs[lower]
        v.path.length = v.path.length + len
    else
        -- aggiunge un blocco nuovo
        local v = {path={index=index, efidOrPath=file, length=len}, authId=authId}
        table.insert(fs, v)
    end
    return fs
end

function t.decode_CommonFlags(kuf, template)
    template = template or {}
    local unused = string.byte(kuf, 1)
    local kufdata = string.sub(kuf, 2)
    local count = string.len(kufdata)
    local kufdataPadded = string.sub(string.rep("\000", 4-count) .. kufdata, -4, -1)
    local f = bin.unpack("%>%L", kufdataPadded)
    f = f / (2^6)
    local ff = bin.flags(f)
    template[CKA.PRIVATE] = eCK.BBOOL(ff[bin.flags(2^1)])
    template[CKA.MODIFIABLE] = eCK.BBOOL(ff[bin.flags(2^0)])
    return template
    
end

function t.encode_CommonFlags(template)
    local ff = bin.flags(0)
    if t.is_cktrue(template[CKA.PRIVATE], false) then ff = ff + bin.flags(2^1) end
    if t.is_cktrue(template[CKA.MODIFIABLE], true) then ff = ff + bin.flags(2^0) end
    return hex.hexf("06%B", ff.asnumber * (2^6))
end


function t.decode_KeyUsageFlags(kuf, template)
    template = template or {}
    local unused = string.byte(kuf, 1)
    local kufdata = string.sub(kuf, 2)
    local count = string.len(kufdata)
    local kufdataPadded = string.sub(string.rep("\000", 4-count) .. kufdata, -4, -1)
    local f = bin.unpack("%>%L", kufdataPadded)
    if count == 1  then
        f = f * 4 -- shift a sinistra di 2 bit: 10(bit massimo) - 8
    else
        f = f / (2^unused) -- shift a destra dei bit inutilizzati
    end
    local ff = bin.flags(f)
    template[CKA.ENCRYPT] = eCK.BBOOL(ff[bin.flags(2^9)])
    template[CKA.DECRYPT] = eCK.BBOOL(ff[bin.flags(2^8)])
    template[CKA.SIGN] = eCK.BBOOL(ff[bin.flags(2^7)])
    template[CKA.SIGN_RECOVER] = eCK.BBOOL(ff[bin.flags(2^6)])
    template[CKA.WRAP] = eCK.BBOOL(ff[bin.flags(2^5)])
    template[CKA.UNWRAP] = eCK.BBOOL(ff[bin.flags(2^4)])
    template[CKA.VERIFY] = eCK.BBOOL(ff[bin.flags(2^3)])
    template[CKA.VERIFY_RECOVER] = eCK.BBOOL(ff[bin.flags(2^2)])
    template[CKA.DERIVE] = eCK.BBOOL(ff[bin.flags(2^1)])
    template[CKA.ALWAYS_AUTHENTICATE] = eCK.BBOOL(ff[bin.flags(2^0)])
    return template
end


function t.is_cktrue(v, default)
    --~ print(hex.hexify(v or ''))
    if not v and default ~= nil then 
        return default
    end
    return v == eCK.BBOOL(true)
end

function t.encode_KeyUsageFlags(template)
    local ff = bin.flags(0)
    local unused = 6
    if t.is_cktrue(template[CKA.ENCRYPT]) then ff = ff + bin.flags(2^9) end
    if t.is_cktrue(template[CKA.DECRYPT]) then ff = ff + bin.flags(2^8) end
    if t.is_cktrue(template[CKA.SIGN]) then ff = ff + bin.flags(2^7) end
    if t.is_cktrue(template[CKA.SIGN_RECOVER]) then ff = ff + bin.flags(2^6) end
    if t.is_cktrue(template[CKA.WRAP]) then ff = ff + bin.flags(2^5) end
    if t.is_cktrue(template[CKA.UNWRAP]) then ff = ff + bin.flags(2^4) end
    if t.is_cktrue(template[CKA.VERIFY]) then ff = ff + bin.flags(2^3) end
    if t.is_cktrue(template[CKA.VERIFY_RECOVER]) then ff = ff + bin.flags(2^2) end
    if t.is_cktrue(template[CKA.DERIVE]) then ff = ff + bin.flags(2^1) end
    if t.is_cktrue(template[CKA.ALWAYS_AUTHENTICATE]) then ff = ff + bin.flags(2^0) end
    return hex.hexf("%B%H", unused, ff.asnumber * (2^unused))
end



function t.decode_KeyAccessFlags(kuf, template)
    
    template = template or {}
    local unused = string.byte(kuf, 1)
    local kufdata = string.sub(kuf, 2)
    local count = string.len(kufdata)
    local kufdataPadded = string.sub(string.rep("\000", 4-count) .. kufdata, -4, -1)
    local f = bin.unpack("%>%L", kufdataPadded)
    
    f = f / 8
    
    local ff = bin.flags(f)
    template[CKA.SENSITIVE] = eCK.BBOOL(ff[bin.flags(2^4)])
    template[CKA.EXTRACTABLE] = eCK.BBOOL(ff[bin.flags(2^3)])
    template[CKA.ALWAYS_SENSITIVE] = eCK.BBOOL(ff[bin.flags(2^2)])
    template[CKA.NEVER_EXTRACTABLE] = eCK.BBOOL(ff[bin.flags(2^1)])
    template[CKA.LOCAL] = eCK.BBOOL(ff[bin.flags(2^0)])
    
    return template
end

function t.encode_KeyAccessFlags(template)
    local ff = bin.flags(0)
    if t.is_cktrue(template[CKA.SENSITIVE]) then ff = ff + bin.flags(2^4) end
    if t.is_cktrue(template[CKA.EXTRACTABLE]) then ff = ff + bin.flags(2^3) end
    if t.is_cktrue(template[CKA.ALWAYS_SENSITIVE]) then ff = ff + bin.flags(2^2) end
    if t.is_cktrue(template[CKA.NEVER_EXTRACTABLE]) then ff = ff + bin.flags(2^1) end
    if t.is_cktrue(template[CKA.LOCAL]) then ff = ff + bin.flags(2^0) end
    return hex.hexf("03%B", ff.asnumber * (2^3)) --  da rivedere
end


function t.encode_PinFlags(f)
    local ff = bin.flags(0)
    local unused = 4
    -- case-sensitive		(0),
    -- local 			(1),
    -- change-disabled 		(2),
    -- unblock-disabled 		(3),
    -- initialized  		(4),
    -- needs-padding 		(5),
    -- unblockingPin 		(6),
    -- soPin 			(7),
    -- disable-allowed 		(8),
    -- integrity-protected		(9),
    -- confidentiality-protected	(10),
    -- exchangeRefData		(11)
    if f.case_sensitive               then ff = ff + bin.flags(2^11) end
    if f.is_local                     then ff = ff + bin.flags(2^10) end
    if f.change_disabled              then ff = ff + bin.flags(2^9) end
    if f.unblock_disabled             then ff = ff + bin.flags(2^8) end
    if f.initialized                  then ff = ff + bin.flags(2^7) end
    if f.needs_padding                then ff = ff + bin.flags(2^6) end
    if f.unblockingPin                then ff = ff + bin.flags(2^5) end
    if f.soPin                        then ff = ff + bin.flags(2^4) end
    if f.disable_allowed              then ff = ff + bin.flags(2^3) end
    if f.integrity_protected          then ff = ff + bin.flags(2^2) end
    if f.confidentiality_protected    then ff = ff + bin.flags(2^1) end
    if f.exchangeRefData              then ff = ff + bin.flags(2^0) end
    
    return hex.hexf("%B%H", unused, ff.asnumber * (2^unused))
end



function t.decode_PinFlags(kuf)
    local f1 = {}
    local unused = string.byte(kuf, 1)
    local kufdata = string.sub(kuf, 2)
    local count = string.len(kufdata)
    local kufdataPadded = string.sub(string.rep("\000", 4-count) .. kufdata, -4, -1)
    local f = bin.unpack("%>%L", kufdataPadded)
    if count == 1  then
        f = f * 16 -- shift a sinistra di 4 bit: 12(bit massimo) - 8
    else
        f = f / (2^unused) -- shift a destra dei bit inutilizzati
    end
    local ff = bin.flags(f)
    
    f1.case_sensitive               = ff[bin.flags(2^11)]
    f1.is_local                     = ff[bin.flags(2^10)]
    f1.change_disabled              = ff[bin.flags(2^9)]
    f1.unblock_disabled             = ff[bin.flags(2^8)]
    f1.initialized                  = ff[bin.flags(2^7)]
    f1.needs_padding                = ff[bin.flags(2^6)]
    f1.unblockingPin                = ff[bin.flags(2^5)]
    f1.soPin                        = ff[bin.flags(2^4)]
    f1.disable_allowed              = ff[bin.flags(2^3)]
    f1.integrity_protected          = ff[bin.flags(2^2)]
    f1.confidentiality_protected    = ff[bin.flags(2^1)]
    f1.exchangeRefData              = ff[bin.flags(2^0)]

    return f1
end

local pin_flags = {
    "case_sensitive",  -- bit (0)
    "is_local",
    "change_disabled",
    "unblock_disabled",
    "initialized",
    "needs_padding",
    "unblockingPin",
    "soPin",
    "disable_allowed",
    "integrity_protected",
    "confidentiality_protected",
    "exchangeRefData",  -- bit (11)
    }

function t.encode_PinFlags_new(f)
    local ff = bin.flags(0)
    local unused = 4
    local numbitsMAX = 12

    for i=1,numbitsMAX do
        ff = bin.flags(ff.asnumber * 2) -- << 1
        if f[pin_flags[i]] then ff = ff + bin.flags(1) end
    end
    return hex.hexf("%B%H", unused, ff.asnumber * (2^unused))
end

function t.decode_PinFlags_new(kuf)
    -- esempio: 04 80 E0 -> unused-bits=4, value='100000001110' + unused'0000'
    -- rappresenta un array di bite che comincia col bit pi