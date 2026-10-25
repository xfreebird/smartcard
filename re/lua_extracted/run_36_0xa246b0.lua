 (p^-1 mod q) invece di (q^-1 mod p)
            -- -- formato chiave: p .. q .. dp .. dq .. ip
            -- abPrivKey = hexf("%B00%>%H%S%S%S%S%S%B%B",
                            -- to_sign and h2i("91") or h2i("93"),
                            -- string.len(rsaInfos.p),
                            -- rsaInfos.q,
                            -- rsaInfos.p,
                            -- rsaInfos.dq,
                            -- rsaInfos.dp,
                            -- rsaInfos.ip,
                            -- pubGroup or 255,
                            -- pubIndex or 255
                            -- )
        -- elseif rsaInfos.d and rsaInfos.n then
            -- rsaInfos.n = string.rep("\0", math.mod(string.len(rsaInfos.n), 4)) .. rsaInfos.n
            -- rsaInfos.d = string.rep("\0", string.len(rsaInfos.n) - string.len(rsaInfos.d)) .. rsaInfos.d
            -- abPrivKey = hexf("%B00%>%H%S%H%S%B%B",
                            -- to_sign and h2i("90") or h2i("92"),
                            -- string.len(rsaInfos.n),
                            -- rsaInfos.n,
                            -- string.len(rsaInfos.d),
                            -- rsaInfos.d,
                            -- pubGroup or 255,
                            -- pubIndex or 255
                            -- )
        -- end
        -- privData = hexf("00FF%B%B%>%H%S%H",
                        -- rsaInfos.bmDelete.asnumber, rsaInfos.bmExecute.asnumber,
                        -- string.len(abPrivKey),
                        -- abPrivKey,
                        -- Crc16_CCITT_1189(abPrivKey, 0)
                        -- )
    -- end
    -- local apdu, apdu1, apdu2
    
    -- if pubData then
    
        -- if string.len(pubData) > 255 then
            -- apdu = hexf("9047%B%B%P", pubGroup, pubIndex, string.sub(pubData,1, 255) )
            -- apdu1 = hexf("8047%B%B%P", pubGroup, pubIndex, string.sub(pubData,256, -1))
        -- else
            -- apdu = hexf("8047%B%B%P", pubGroup, pubIndex, pubData )
        -- end
        -- local recv = self:transmit(apdu)
        -- sw = string.sub(recv, -2, -1)
        -- if sw ~= hexf('9000') and sw ~= hexf('6200') then
            -- error(SmartcardError.new(sw, 'put_rsa_key PUBLIC error' ), 2)
        -- end
        -- if apdu1 then
            -- recv = self:transmit(apdu1)
            -- sw = string.sub(recv, -2, -1)
            -- if sw ~= hexf('9000') then
                -- error(SmartcardError.new(sw, 'put_rsa_key PUBLIC1 error' ), 2)
            -- end
        -- end
    -- end
    
    -- if privData then
        -- if string.len(privData) > 255 then
            -- apdu  = hexf("9047%B%B%P", privGroup, privIndex, string.sub(privData,1, 255) )
            -- if string.len(privData) > 510 then
                -- apdu1 = hexf("9047%B%B%P", privGroup, privIndex, string.sub(privData,256, 510))
                -- apdu2 = hexf("8047%B%B%P", privGroup, privIndex, string.sub(privData,511, -1))
            -- else
                -- apdu1 = hexf("8047%B%B%P", privGroup, privIndex, string.sub(privData,256, 510))
            -- end
        -- else
            -- apdu = hexf("8047%B%B%P", privGroup, privIndex, privData )
        -- end
        -- local recv = self:transmit(apdu)
        -- sw = string.sub(recv, -2, -1)
        -- if sw ~= hexf('9000') and sw ~= hexf('6200') then
            -- error(SmartcardError.new(sw, 'put_rsa_key PRIVATE error' ), 2)
        -- end
        -- if apdu1 then
            -- recv = self:transmit(apdu1)
            -- sw = string.sub(recv, -2, -1)
            -- if sw ~= hexf('9000') and sw ~= hexf('6200') then
                -- error(SmartcardError.new(sw, 'put_rsa_key PRIVATE1 error' ), 2)
            -- end
            -- if apdu2 then
                -- recv = self:transmit(apdu2)
                -- sw = string.sub(recv, -2, -1)
                -- if sw ~= hexf('9000') then
                    -- error(SmartcardError.new(sw, 'put_rsa_key PRIVATE2 error' ), 2)
                -- end
            -- end
        -- end
    -- end
-- end


return Smartcard

--===========================================================================
end
}
_LOADED['aes'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
local hex = require ("hex")

local function xor_string(a, b)
    assert(string.len(a) == string.len(b))
    local res = {}
    for i=1,string.len(a) do
        table.insert(res, (bin.flags(string.byte(a, i)) ^ bin.flags(string.byte(b, i))).asnumber )
    end
    return string.char(unpack(res))
end

local function and_string(a, b)
    assert(string.len(a) == string.len(b))
    local res = {}
    for i=1,string.len(a) do
        table.insert(res, (bin.flags(string.byte(a, i)) * bin.flags(string.byte(b, i))).asnumber )
    end
    return string.char(unpack(res))
end

local function lshift_string(s, v)
    local s1 = hex.hexf(bignum.create(s, true):lshift(v):tostring(16, true))
    s1 = string.rep("\0", string.len(s) - string.len(s1)) .. s1
    s1 = string.sub(s1, -string.len(s), -1)
    return s1
    
end

local function rshift_string(s, v)
    local s1 = hex.hexf(bignum.create(s, true):rshift(v):tostring(16, true))
    
    return string.rep("\0", string.len(s) - string.len(s1)) .. s1
end



local function Generate_Subkey(K)
    local nullIV = string.rep("\0", 16)
    local L = sm.aes_enc_block(K, nullIV)
    local Rb = hex.hexf("00000000000000000000000000000087")
    local L1 = lshift_string(L, 1)
    local L2
    local K1, K2
    
    if rshift_string(L, 127) == nullIV then
        K1 = L1
    else
        K1 = xor_string(Rb, L1)
    end
    
    L2 = lshift_string(K1, 1)
    if rshift_string(K1, 127) == nullIV then
        K2 = L2
    else
        K2 = xor_string(Rb, L2)
    end 
    return K1, K2
end


local BLOCK_LEN = 16
local function PAD(N)
    local padLen = BLOCK_LEN - math.mod(string.len(N), BLOCK_LEN)
    N = N .. '\128' .. string.rep('\0', (padLen-1))
    return N
end

local function pkcs5_padding(block_size, input)
	local padlen
    local input_len = string.len(input)
	local cipherLen = 0;
	local i = 0;

	-- Padding 
	if math.mod(input_len, block_size) ~= 0 then
		cipherLen = math.floor((input_len + block_size - 1) / block_size) * block_size
	else
		cipherLen = input_len + block_size
	end
    
    -- log.output ("cipherLen:", cipherLen)
    -- log.output ("input_len:", input_len)
    -- log.output ("block_size:", block_size)
    
	padlen = cipherLen - input_len

    -- log.output ("padlen:", padlen)
	if input == nil or string.len(input) == 0 then
		return ""
    end
	
    input = input .. string.rep(string.char(padlen), padlen)
	return input
end



local function pkcs5_padding2(block_size, input)
	local padlen
    local input_len = string.len(input)
	local cipherLen = 0;
	local i = 0;

	-- Padding
	if input_len ~= 0 and math.mod(input_len, block_size) ~= 0 then
		cipherLen = math.floor((input_len + block_size - 1) / block_size) * block_size
	else
		cipherLen = input_len + block_size
	end
    
    -- print("cipherLen:", cipherLen)
    -- print("input_len:", input_len)
    -- print("block_size:", block_size)
    
	padlen = cipherLen - input_len

    -- print ("padlen:", padlen)

	
    input = input .. string.rep(string.char(padlen), padlen)
	return input
end

-- print("pad2:", hex.hexify(pkcs5_padding2(16, "")) )
-- print("pad2:", hex.hexify(pkcs5_padding2(16, "1")) )
-- print("pad2:", hex.hexify(pkcs5_padding2(16, "22")) )
-- print("pad2:", hex.hexify(pkcs5_padding2(16, "333")) )
-- print("pad2:", hex.hexify(pkcs5_padding2(16, "4444")) )
-- print("pad2:", hex.hexify(pkcs5_padding2(16, "55555")) )
-- print("pad2:", hex.hexify(pkcs5_padding2(16, "666666")) )
-- print("pad2:", hex.hexify(pkcs5_padding2(16, "7777777")) )
-- print("pad2:", hex.hexify(pkcs5_padding2(16, "888888888")) )
-- print("pad2:", hex.hexify(pkcs5_padding2(16, "8888888889")) )
-- print("pad2:", hex.hexify(pkcs5_padding2(16, "8888888889a")) )
-- print("pad2:", hex.hexify(pkcs5_padding2(16, "8888888889ab")) )
-- print("pad2:", hex.hexify(pkcs5_padding2(16, "8888888889abc")) )
-- print("pad2:", hex.hexify(pkcs5_padding2(16, "8888888889abcd")) )
-- print("pad2:", hex.hexify(pkcs5_padding2(16, "8888888889abcde")) )
-- print("pad2:", hex.hexify(pkcs5_padding2(16, "8888888889abcdef")) )

-- print("pad:", hex.hexify(pkcs5_padding(16, "")) )
-- print("pad:", hex.hexify(pkcs5_padding(16, "1")) )
-- print("pad:", hex.hexify(pkcs5_padding(16, "22")) )
-- print("pad:", hex.hexify(pkcs5_padding(16, "333")) )
-- print("pad:", hex.hexify(pkcs5_padding(16, "4444")) )
-- print("pad:", hex.hexify(pkcs5_padding(16, "55555")) )
-- print("pad:", hex.hexify(pkcs5_padding(16, "666666")) )
-- print("pad:", hex.hexify(pkcs5_padding(16, "7777777")) )
-- print("pad:", hex.hexify(pkcs5_padding(16, "888888888")) )
-- print("pad:", hex.hexify(pkcs5_padding(16, "8888888889")) )
-- print("pad:", hex.hexify(pkcs5_padding(16, "8888888889a")) )
-- print("pad:", hex.hexify(pkcs5_padding(16, "8888888889ab")) )
-- print("pad:", hex.hexify(pkcs5_padding(16, "8888888889abc")) )
-- print("pad:", hex.hexify(pkcs5_padding(16, "8888888889abcd")) )
-- print("pad:", hex.hexify(pkcs5_padding(16, "8888888889abcde")) )
-- print("pad:", hex.hexify(pkcs5_padding(16, "8888888889abcdef")) )

local function pkcs5_unpad(input)
	local padlen = string.byte(input, string.len(input))
    
	return string.sub(input, 1, -1-padlen)
end

local function AES_CMAC(K, M, length)

    length = length or string.len(M)
    local const_Bsize = BLOCK_LEN
    local const_Zero  =  string.rep("\0", const_Bsize)

    M      = string.sub(M, 1, length)
    local K1, K2 = Generate_Subkey(K)
    local n      = math.floor(string.len(M) / const_Bsize)
    local flag,M_last, M_n
    
    if n == 0 then
        n = 1
        flag = false
    else
        if math.mod(length , const_Bsize) == 0 then
            flag = true
        else
            n = n +1
            flag = false
        end
    end
    
    M_n = string.sub(M, 1+ (n-1)*const_Bsize, -1)
    if flag then 
        M_last = xor_string(M_n, K1)
    else
        M_last = xor_string(PAD(M_n), K2)
    end
    
    local X = const_Zero
    local Y
    local M_i
    for i=0,n-2 do
        M_i = string.sub(M, 1+ (i*const_Bsize), (i*const_Bsize) + const_Bsize)
        Y   = xor_string(X, M_i)
        X   = sm.aes_enc_block(K, Y)
    end
    Y = xor_string(M_last, X)
    local T = sm.aes_enc_block(K, Y)

    return T
end

local function KDF(k, Label, Context, L)
    -- print("L:", L)
    local buffer1 = Label .. "\0" .. hex.hexf("%H", L) .. "\1" .. Context
    local buffer2 = Label .. "\0" .. hex.hexf("%H", L) .. "\2" .. Context
    -- print("buffer1 ", hex.hexify(buffer1))
    -- print("buffer2 ", hex.hexify(buffer2))

    local D1 = AES_CMAC(k,buffer1, string.len(buffer1))
    local D2 = AES_CMAC(k,buffer2, string.len(buffer2))
    return string.sub(D1 .. D2, 1, math.floor(L/8))
end

local function aes_decrypt_check(key, encData, check)
    local res
    local dec = sm.aes_dec_cbc(key, encData)
    local toCheck = string.sub(dec, 1, string.len(check))
    if toCheck == check then
        res = string.sub(dec, 17, -1)
    end
    return res
end

local function aes_encrypt_check(key, data, check)
    local res
    assert (string.len(check) <= 16)
    local header = check .. sm.gen_random(16 - string.len(check))
    res = sm.aes_enc_cbc(key, header .. data)
    return res
end

local function AES_CBC2(K, data, enc, iv) -- returns new IV
    local out = ""
    iv = iv or string.rep("\0", BLOCK_LEN)
    local AES_BLOCK_SIZE = BLOCK_LEN
    local const_Zero  =  string.rep("\0", AES_BLOCK_SIZE)
    local datalen = string.len(data)
    assert( math.mod(datalen , AES_BLOCK_SIZE) == 0 )
    local i=1
    if enc then
		while i < datalen do
            local block = string.sub(data, i, i +  AES_BLOCK_SIZE-1)
            local tmp = xor_string(block, iv)
            local tmp_enc = sm.aes_enc_block(K, tmp)
            out = out .. tmp_enc
            
			iv = tmp_enc
            i = i + AES_BLOCK_SIZE
		end
    else
        while i < datalen do
            local block = string.sub(data, i, i +  AES_BLOCK_SIZE-1)
			local tmp = sm.aes_dec_block(K, block)
            local tmp_dec = xor_string(tmp, iv)
			iv = block
            out = out .. tmp_dec
			i = i + AES_BLOCK_SIZE
		end
    end
    return out, iv
end

local function AES_CBC(K, data, enc, iv) -- do not returns new IV
    local out = AES_CBC2(K, data, enc, iv)
    return out
end

local function AES_ECB(K, data, enc)
    local out = ""
    
    local AES_BLOCK_SIZE = BLOCK_LEN
    local datalen = string.len(data)
    assert( math.mod(datalen , AES_BLOCK_SIZE) == 0 )
    local i=1
    if enc then
		while i < datalen do
            local block = string.sub(data, i, i +  AES_BLOCK_SIZE-1)
            local tmp_enc = sm.aes_enc_block(K, block)
            out = out .. tmp_enc
            
            i = i + AES_BLOCK_SIZE
		end
    else
        while i < datalen do
            local block = string.sub(data, i, i +  AES_BLOCK_SIZE-1)
			local tmp = sm.aes_dec_block(K, block)
            out = out .. tmp
			i = i + AES_BLOCK_SIZE
		end
    end
    return out
end


local t ={
    BLOCK_LEN=BLOCK_LEN,
    PAD = PAD,
    xor_string = xor_string,
    and_string = and_string,
    lshift_string = lshift_string,
    rshift_string = rshift_string,
    Generate_Subkey = Generate_Subkey,
    AES_CMAC = AES_CMAC,
    KDF = KDF,
    pkcs5_padding=pkcs5_padding,
    pkcs5_padding2=pkcs5_padding2,
    pkcs5_unpad=pkcs5_unpad,
    aes_decrypt_check=aes_decrypt_check,
    aes_encrypt_check=aes_encrypt_check,
    AES_CBC=AES_CBC,
    AES_CBC2=AES_CBC2,
    AES_ECB=AES_ECB,
}

-- local t = "111111"
-- local c = aes_encrypt_check("1234567812345678", t, "00000001")
-- local d = aes_decrypt_check("1234567812345678", c, "00000001")
-- print (hex.hexify(t))
-- print (hex.hexify(c))
-- print (hex.hexify(d))

-- assert(t == d)

return t

--===========================================================================
end
}
_LOADED['ecdhlib'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
local hex = require("hex")
local der = require("der")
local utility = require("utility")
local repr = utility.repr
local hexf2 = function(v, ...) return hex.hexf(string.gsub(v, '%s', ''), unpack(arg)) end

local t ={}


local Ed25519_GNU_OID    = "1.3.6.1.4.1.11591.15.1" -- names: Ed25519
local Ed25519_THAWTE_OID = "1.3.101.112" -- names: Edwards25519 / EdDSA25519
local X25519_THAWTE_OID  = "1.3.101.110" -- names: Curve25519/X25519
local ulMinKeySizeEd25519 = 32*8
local ulMaxKeySizeEd25519 = 32*8
local ulMinKeySizeX25519  = 32*8
local ulMaxKeySizeX25519  = 32*8

t.Ed25519_curves_oids = {
    [Ed25519_GNU_OID]="Ed25519",
    [Ed25519_THAWTE_OID]="Ed25519",
}

t.X25519_curves_oids = {
    [X25519_THAWTE_OID]="X25519",
}

t.Ed25519_curves_names = {
    Ed25519=Ed25519_THAWTE_OID,
    EdDSA25519=Ed25519_THAWTE_OID,
    Edwards25519=Ed25519_THAWTE_OID,
}

t.X25519_curves_names = {
    X25519=X25519_THAWTE_OID,
    Curve25519=X25519_THAWTE_OID,
}
t.Ed25519_GNU_OID = Ed25519_GNU_OID
t.Ed25519_THAWTE_OID = Ed25519_THAWTE_OID
t.X25519_THAWTE_OID = X25519_THAWTE_OID
t.ulMinKeySizeEd25519 =  ulMinKeySizeEd25519
t.ulMaxKeySizeEd25519 = ulMaxKeySizeEd25519
t.ulMinKeySizeX25519 = ulMinKeySizeX25519
t.ulMaxKeySizeX25519 = ulMaxKeySizeX25519

local curves = {
    brainpoolP224r1={
        name='brainpoolP224r1',
        asciiOid="1.3.36.3.3.2.8.1.1.5", -- https://oidref.com/1.3.36.3.3.2.8.1.1.5
        keysize=224/8,
        keybits=224,
        -- Field characteristic.
        p=bignum.create("0xD7C134AA264366862A18302575D1D787B09F075797DA89F57EC8C0FF"),
        -- Curve coefficients.
        a=bignum.create("0x68A5E62CA9CE6C1C299803A6C1530B514E182AD8B0042A59CAD29F43"),
        b=bignum.create("0x2580F63CCFE44138870713B1A92369E33E2135D266DBB372386C400B"),
        -- Base point.
        g={x=bignum.create("0x0D9029AD2C7E5CF4340823B2A87DC68C9E4CE3174C1E6EFDEE12C07D"),
           y=bignum.create("0x58AA56F772C0726F24C6B89E4ECDAC24354B9E99CAA3F6D3761402CD"),
          },
        -- Subgroup order.
        n=bignum.create("0xD7C134AA264366862A18302575D0FB98D116BC4B6DDEBCA3A5A7939F"),
        -- Subgroup cofactor.
        h=bignum.create("0x01"),
        },
        
    brainpoolP256r1={
        name='brainpoolP256r1',
        asciiOid="1.3.36.3.3.2.8.1.1.7", -- https://oidref.com/1.3.36.3.3.2.8.1.1.7
        keysize=256/8,
        keybits=256,
        -- Field characteristic.
        p=bignum.create("0xA9FB57DBA1EEA9BC3E660A909D838D726E3BF623D52620282013481D1F6E5377"),
        -- Curve coefficients.
        a=bignum.create("0x7D5A0975FC2C3057EEF67530417AFFE7FB8055C126DC5C6CE94A4B44F330B5D9"),
        b=bignum.create("0x26DC5C6CE94A4B44F330B5D9BBD77CBF958416295CF7E1CE6BCCDC18FF8C07B6"),
        -- Base point.
        g={x=bignum.create("0x8BD2AEB9CB7E57CB2C4B482FFC81B7AFB9DE27E1E3BD23C23A4453BD9ACE3262"),
           y=bignum.create("0x547EF835C3DAC4FD97F8461A14611DC9C27745132DED8E545C1D54C72F046997"),
          },
        -- Subgroup order.
        n=bignum.create("0xA9FB57DBA1EEA9BC3E660A909D838D718C397AA3B561A6F7901E0E82974856A7"),
        -- Subgroup cofactor.
        h=bignum.create("0x01"),
        },
        
        

    secp192r1 = { -- PARAMS OK, TESTED
        name = "secp192r1",
        asciiOid = "1.2.840.10045.3.1.1", -- oid prime192v1; ansi-X9-62 curves(3) prime(1) 1 -> iso(1) member-body(2) us(840) 10045 curves(3) prime(1) 1; https://oidref.com/1.2.840.10045.3.1.1
        keysize=192/8,
        keybits=192,
        p = bignum.create("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFF"),
        a = bignum.create("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFC"),
        b = bignum.create("0x64210519E59C80E70FA7E9AB72243049FEB8DEECC146B9B1"),
        g = {x=bignum.create("0x188DA80EB03090F67CBF20EB43A18800F4FF0AFD82FF1012"),
             y=bignum.create("0x07192B95FFC8DA78631011ED6B24CDD573F977A11E794811"),
            },
        n = bignum.create("0xFFFFFFFFFFFFFFFFFFFFFFFF99DEF836146BC9B1B4D22831"),
        h=bignum.create("0x01"),
    },
    
    secp224r1 = { -- PARAMS OK, TESTED
        name = "secp224r1",
        asciiOid = "1.3.132.0.33", -- oid ansip224r1; https://oidref.com/1.3.132.0.33
        keysize=224/8,
        keybits=224,
        p = bignum.create("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000001"),
        a = bignum.create("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFE"),
        b = bignum.create("0xB4050A850C04B3ABF54132565044B0B7D7BFD8BA270B39432355FFB4"),
        g = {x=bignum.create("0xB70E0CBD6BB4BF7F321390B94A03C1D356C21122343280D6115C1D21"),
             y=bignum.create("0xBD376388B5F723FB4C22DFE6CD4375A05A07476444D5819985007E34"),
            },
        n = bignum.create("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF16A2E0B8F03E13DD29455C5C2A3D"),
        h=bignum.create("0x01"),
    },
    
    secp256r1 = {
        name = "secp256r1",
        asciiOid = "1.2.840.10045.3.1.7", -- oid prime256v1 -- ansi-X9-62 curves(3) prime(1) 7 -> iso(1) member-body(2) us(840) 10045 curves(3) prime(1) 7; https://oidref.com/1.2.840.10045.3.1.7
        keysize=256/8,
        keybits=256,
        p = bignum.create("0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF"),
        a = bignum.create("0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC"),
        b = bignum.create("0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B"),
        g = {x=bignum.create("0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296"),
             y=bignum.create("0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5"),
            },
        n = bignum.create("0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551"),
        h=bignum.create("0x01"),
    },
    
    secp384r1 = { -- OK, TESTED
        name = "secp384r1",
        asciiOid = "1.3.132.0.34", -- oid ansip384r1; https://oidref.com/1.3.132.0.34
        keysize=384/8,
        keybits=384,
        p = bignum.create("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFF0000000000000000FFFFFFFF"),
        a = bignum.create("0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000fffffffc"),
        b = bignum.create("0xB3312FA7E23EE7E4988E056BE3F82D19181D9C6EFE8141120314088F5013875AC656398D8A2ED19D2A85C8EDD3EC2AEF"),
        g = {x=bignum.create("0xAA87CA22BE8B05378EB1C71EF320AD746E1D3B628BA79B9859F741E082542A385502F25DBF55296C3A545E3872760AB7"),
             y=bignum.create("0x3617DE4A96262C6F5D9E98BF9292DC29F8F41DBD289A147CE9DA3113B5F0B8C00A60B1CE1D7E819D7A431D7C90EA0E5F"),
            },
        n = bignum.create("0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc52973"),
        h=bignum.create("0x01"),
    },
    
    secp521r1 = { -- OK, TESTED
        name = "secp521r1",
        asciiOid = "1.3.132.0.35", -- oid ansip521r1; https://oidref.com/1.3.132.0.35
        keysize=528/8,
        keybits=521,
        p = bignum.create("0x01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"),
        a = bignum.create("0x01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC"),
        b = bignum.create("0x0051953EB9618E1C9A1F929A21A0B68540EEA2DA725B99B315F3B8B489918EF109E156193951EC7E937B1652C0BD3BB1BF073573DF883D2C34F1EF451FD46B503F00"),
        g = {x=bignum.create("0x00C6858E06B70404E9CD9E3ECB662395B4429C648139053FB521F828AF606B4D3DBAA14B5E77EFE75928FE1DC127A2FFA8DE3348B3C1856A429BF97E7E31C2E5BD66"),
             y=bignum.create("0x011839296A789A3BC0045C8A5FB42C7D1BD998F54449579B446817AFBD17273E662C97EE72995EF42640C550B9013FAD0761353C7086A272C24088BE94769FD16650"),
            },
        n = bignum.create("0x01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFA51868783BF2F966B7FCC0148F709A5D03BB5C9B8899C47AEBB6FB71E91386409"),
        h=bignum.create("0x01"),
    },
    
    secp256k1 = { -- OK, TESTED
        name = "secp256k1",
        asciiOid = "1.3.132.0.10", -- oid ansip256k1; https://oidref.com/1.3.132.0.10
        keysize=256/8,
        keybits=256,
        p = bignum.create("0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f"),
        a = bignum.create("0x0000000000000000000000000000000000000000000000000000000000000000"),
        b = bignum.create("0x0000000000000000000000000000000000000000000000000000000000000007"),
        g = {x=bignum.create("0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"), 
             y=bignum.create("0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8"),
            },
        n = bignum.create("0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"),
        h=bignum.create("0x01"),
    },
    
    secp521k={ -- same as secp521r1, used by cryptoid SM
        no_list=true,
        name='secp521k', -- TODO: rename to secp521r1, in use and left unmodified
        asciiOid="1.3.132.0.35", -- oid ansip521r1; https://oidref.com/1.3.132.0.35
        -- Field characteristic.
        keysize=528/8,
        keybits=521,
        p=bignum.create("0x000001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"),
        -- Curve coefficients.
        a=bignum.create("0x000001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC"),
        b=bignum.create("0x00000051953EB9618E1C9A1F929A21A0B68540EEA2DA725B99B315F3B8B489918EF109E156193951EC7E937B1652C0BD3BB1BF073573DF883D2C34F1EF451FD46B503F00"),
        -- Base point.
        g={x=bignum.create("0x000000C6858E06B70404E9CD9E3ECB662395B4429C648139053FB521F828AF606B4D3DBAA14B5E77EFE75928FE1DC127A2FFA8DE3348B3C1856A429BF97E7E31C2E5BD66"),
           y=bignum.create("0x0000011839296a789a3bc0045c8a5fb42c7d1bd998f54449579b446817afbd17273e662c97ee72995ef42640c550b9013fad0761353c7086a272c24088be94769fd16650")},
        -- Subgroup order.
        n=bignum.create("0x000001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFA51868783BF2F966B7FCC0148F709A5D03BB5C9B8899C47AEBB6FB71E91386409"),
        -- Subgroup cofactor.
        h=bignum.create("0x01"),
        },
        
}

local mt = {}
mt.__index = mt
for i, v in curves do
    v.g.curve = v
    setmetatable(v.g, mt)
end

local bignums = {}

for i=0,10 do
    bignums[i] = bignum.create(tostring(i))
end

local mod = bignum.mod


local flags_1_8 = {}

for i=1,8 do
    flags_1_8[i] = bin.flags(2^(i-1))
    -- print(flags_1_8[i] )
end
local function to_bin_str(a)
    local r = {}
    local aX = a:tostring(16, true)
    local aB = hex.hexf(aX)
    for i=1,string.len(aB) do
        local f = bin.flags(string.byte(aB, i))
        for x=8,1,-1 do
            table.insert(r, f[flags_1_8[x]] and "1" or "0")
        end
    end
    
    return table.concat(r, "")
end


local function pf_add(a, b, p)
    return mod(a + b, p)
end

local function pf_add2(a, b, p)
    local c = a + b
    if c >= p then
        return c - p
    elseif c < bignums[0] then
        return c + p
    else
        return c
    end
end

local function pf_neg(a, p)
    return mod(-a, p)
end

local function pf_mul(a, b, p)
    return mod(a * b, p)
end

function mt:is_on_curve()
    -- """Returns True if the given point lies on the elliptic curve."""
    if self.is_infinite then
        -- None represents the point at infinity.
        return true
    end
    local x, y = self.x, self.y
    local yy = y * y
    local xxx = x * x * x
    local ax=self.curve.a * x
    
    local r = yy - xxx - ax - self.curve.b
    local m =  mod(r, self.curve.p)
    return m == bignums[0]
end


function mt:point_is_equal(p2)
    return self.x == p2.x and self.y == p2.y
end

function mt:point_neg(check)
    -- """Returns -point."""

    if self.is_infinite then
        -- -0 = 0
        return self
    end
    local x, y = self.x, self.y
    local result = {curve=self.curve, x=x, y=mod(-y,  self.curve.p)}
    setmetatable(result, getmetatable(self))
    if check then
        assert (result:is_on_curve())
    end
    return result
end


function mt:point_add_v1(point2, check)
    local m
    local inverse_mod=bignum.invmod
    -- """Returns the result of point1 + point2 according to the group law."""
    if check then
        assert(point2:is_on_curve())
    end

    if self.is_infinite then
        -- 0 + point2 = point2
        return point2
    end
    if point2.is_infinite then
        -- point1 + 0 = point1
        return self
    end
    local x1, y1 = self.x, self.y
    local x2, y2 = point2.x, point2.y

    if x1 == x2 and y1 ~= y2 then
        -- point1 + (-point1) = 0
        local result = {curve=self.curve, is_infinite=true}
        setmetatable(result, getmetatable(self))
        return result
    end
    if x1 == x2 then
        -- This is the case point1 == point2.
        m = (bignums[3] * x1 * x1 + self.curve.a) * inverse_mod(bignums[2] * y1, self.curve.p)
    else
        -- This is the case point1 != point2.
        m = (y1 - y2) * inverse_mod(x1 - x2, self.curve.p)
    end
    local x3 = m * m - x1 - x2
    local y3 = y1 + m * (x3 - x1)
    local result = {curve=self.curve, x=mod(x3 , self.curve.p), y=mod(-y3, self.curve.p)}
    setmetatable(result, getmetatable(self))
    if check then
        assert (result:is_on_curve())
    end

    return result
end



function mt:point_add(point2, check) -- uses pf_add()/pf_neg()/pf_mul() functions
    local m
    local p = self.curve.p
    local inverse_mod=bignum.invmod
    -- """Returns the result of point1 + point2 according to the group law."""
    if check then
        assert(point2:is_on_curve())
    end

    if self.is_infinite then
        -- 0 + point2 = point2
        return point2
    end
    if point2.is_infinite then
        -- point1 + 0 = point1
        return self
    end
    local x1, y1 = self.x, self.y
    local x2, y2 = point2.x, point2.y

    if x1 == x2 and y1 ~= y2 then
        -- point1 + (-point1) = 0
        local result = {curve=self.curve, is_infinite=true}
        setmetatable(result, getmetatable(self))
        return result
    end
    if x1 == x2 then
        -- This is the case point1 == point2.
        -- m = (bignums[3] * x1 * x1 + self.curve.a) * inverse_mod(bignums[2] * y1, self.curve.p)
        m = pf_mul(pf_add(pf_mul(bignums[3], pf_mul(x1, x1, p), p), self.curve.a, p), inverse_mod(pf_mul(bignums[2], y1, p), self.curve.p), p)
    else
        -- This is the case point1 != point2.
        -- m = (y1 - y2) * inverse_mod(x1 - x2, self.curve.p)
        m = pf_mul(pf_add(y1, pf_neg(y2, p), p), inverse_mod(pf_add(x1, pf_neg(x2, p), p), self.curve.p), p)
    end
    local x3 = pf_add(pf_add(pf_mul(m, m, p), pf_neg(x1, p), p), pf_neg(x2, p), p) -- m * m - x1 - x2
    local y3 = pf_add(y1, pf_mul(m, pf_add(x3, pf_neg(x1, p), p), p), p) -- y1 + m * (x3 - x1)
    
    local result = {curve=self.curve, x=mod(x3 , self.curve.p), y=mod(-y3, self.curve.p)}
    setmetatable(result, getmetatable(self))
    if check then
        assert (result:is_on_curve())
    end

    return result
end

function mt:scalar_mult_v1(k) -- use normal point_add_v1()
    --"""Returns k * point computed using the double and point_add algorithm."""
    local infinite_point = {curve=self.curve, is_infinite=true}
    setmetatable(infinite_point, getmetatable(self))
    
    
    if mod(k, self.curve.n) == bignums[0] or self.is_infinite then
        return infinite_point
    end
    if k < bignums[0] then
        -- k * point = -k * (-point)
        return self:point_neg():scalar_mult_v1(-k)
    end
    local result = infinite_point
    local addend = self

    while k ~= bignums[0] do
        if mod(k, bignums[2]) == bignums[1] then
            result = addend:point_add_v1(result) -- Add.
        end
        addend = addend:point_add_v1(addend) -- Double.
        k = k:rshift(1)
    end
    assert (result:is_on_curve())

    return result

end

function mt:scalar_mult(k) -- use optimized point_add()
    --"""Returns k * point computed using the double and point_add algorithm."""
    local infinite_point = {curve=self.curve, is_infinite=true}
    setmetatable(infinite_point, getmetatable(self))
    
    
    if self.is_infinite or mod(k, self.curve.n) == bignums[0] then
        return infinite_point
    end
    if k < bignums[0] then
        -- k * point = -k * (-point)
        return self:point_neg():scalar_mult(-k)
    end
    local result = infinite_point
    local addend = self

    while k ~= bignums[0] do
        if mod(k, bignums[2]) == bignums[1] then
            result = addend:point_add(result) -- Add.
        end
        addend = addend:point_add(addend) -- Double.
        k = k:rshift(1)
    end
    assert (result:is_on_curve())

    return result

end


function mt:scalar_mult_v3(k) -- converts k to a string of binary digits
    --"""Returns k * point computed using the double and point_add algorithm."""
    local infinite_point = {curve=self.curve, is_infinite=true}
    setmetatable(infinite_point, getmetatable(self))
    
    
    if self.is_infinite or mod(k, self.curve.n) == bignums[0] then
        return infinite_point
    end
    if k < bignums[0] then
        -- k * point = -k * (-point)
        return self:point_neg():scalar_mult_v3(-k)
    end
    local result = infinite_point
    local addend = self

    local k1 = to_bin_str(k)
    for i=string.len(k1),1,-1 do
        -- print(i, string.byte(k1, i))
        if string.byte(k1, i) == 49 then
            result = addend:point_add(result)
        end
        addend = addend:point_add(addend)
    end
    assert (result:is_on_curve())
    
    return result

end


function mt:make_keypair(key)
    ---"""Generates a random private-public key pair."""
    -- local private_key = bignum.create("65537") -- random.randrange(1, curve.n)
    local generator = self
    local private_key = key or bignum.create(sm.gen_random(bignum.sizeof(generator.curve.n)), true)
    if not key and private_key >= generator.curve.n then
        while private_key >= generator.curve.n do
            private_key = bignum.create(sm.gen_random(bignum.sizeof(generator.curve.n)), true)
        end
    end    
    local public_key = generator:scalar_mult(private_key)

    return private_key, public_key
end

function mt:decode_point(p, useheader)
    local x, y
    if string.byte(p, 1) == 4 or not useheader then
        useheader = useheader and 1 or 0
        local l = (string.len(p)-useheader)/2
        x, y = string.sub(p, 1+useheader, l+useheader), string.sub(p, l+1+useheader, l+l+useheader)
        local result = {x=bignum.create(x, true), y=bignum.create(y, true), curve=self.curve}
        setmetatable(result, getmetatable(self))
        assert(result:is_on_curve())
        return result
    end
    return nil
end

function mt:encode_point(useheader, bytes)
    local part1 = hex.hexf(self.x:tostring(16, true))
    local part2 = hex.hexf(self.y:tostring(16, true))
    bytes = bytes or self.curve.keysize
    if bytes then
        assert (bytes >= string.len(part1))
        assert (bytes >= string.len(part2))
        part1 = string.rep("\0", bytes - string.len(part1)) .. part1
        part2 = string.rep("\0", bytes - string.len(part2)) .. part2
    end
    local res =  part1 .. part2
    if useheader then
        res = "\4" .. res
    end
    return res
end


function mt:__tostring()
    return string.format("{x=%s, y=%s}", tostring(self.x), tostring(self.y))
end



function mt:ecdsa_verifies(hash, r, s)

    hash = t.trunk_to_curve_order(self.curve, hash)

    -- # From X9.62 J.3.1.
    
    -- G = self.g
   local G = self.curve.g
    -- n = G.order()
   local n = self.curve.n
    -- r = signature.r
    -- s = signature.s
    local bn_one = bignum.create(1)
    local bn_n_minus_1 = n -1
    if not s then
        log.output("ecdsa_verifies(): recovering r and s from single value...")
        s = string.sub(r, string.len(r)/2+1, -1)
        r = string.sub(r, 1, (string.len(r)/2))
    end
    r = bignum.create( r, true)
    s = bignum.create( s, true)
    hash = bignum.create( hash, true)
    log.output("ecdsa_verifies(): r: " , r)
    log.output("ecdsa_verifies(): s: " , s)
    log.output("ecdsa_verifies(): hash: " , hash)
    -- if r < 1 or r > n - 1:
      -- return False
    if r < bn_one or r > (bn_n_minus_1) then
        log.output("ecdsa_verifies(): r has invalid value: " , r )
        return false
    end
    -- if s < 1 or s > n - 1:
      -- return False
    if s < bn_one or s > (bn_n_minus_1) then
        log.output("ecdsa_verifies(): s has invalid value: " , s )
        return false
    end
    -- c = numbertheory.inverse_mod(s, n)
    local c = bignum.invmod(s, n)
    log.output("ecdsa_verifies(): c: " , c)
    -- u1 = (hash * c) % n
    local u1 = mod (hash * c, n)
    log.output("ecdsa_verifies(): u1: " , u1)
    -- u2 = (r * c) % n
    local u2 = mod (r * c, n)
    log.output("ecdsa_verifies(): u2: " , u2)
    -- xy = u1 * G + u2 * self.point
    local xy = G:scalar_mult(u1):point_add(self:scalar_mult(u2))
    log.output("ecdsa_verifies(): xy: " , xy)
    -- v = xy.x() % n
    local v = mod(xy.x, n)
    -- return v == r
    log.output("ecdsa_verifies(): v: ", v)
    return v == r
end


local curves_by_oid = {}
for i, v in curves do
    if not v.no_list then
        curves_by_oid[v.asciiOid] = v
    end
end

function t.get_curves()
    return curves
end

function t.get_curve_names()
    local names = {}
    local n = 0
    for i, v in curves do
        table.insert(names, i)
        n = n+1
    end
    -- table.setn(curves, n)
    table.sort(names)
    return names
end

function t.get_curve(curvename)
    return curves[curvename]
end

function t.get_curve_by_asciioid(asciiOid)
    return curves_by_oid[asciiOid]
end

function t.get_curve_by_deroid(derOid)
    local oid = der.parse(derOid)
    local asciiOid, curve
    if oid[1] and oid[1].value and oid[1].tag == der.OID then
        asciiOid = der.decodeOID(oid[1].value)
        return asciiOid and t.get_curve_by_asciioid(asciiOid)
    end
end

function t.trim_pad_bn(data, padto)
    data = string.sub(data, -padto)
    data = string.rep("\000", padto - string.len(data)) .. data
    return data
end

function t.trim_leding_zero(data)
    while (string.len(data) >0 and string.byte(data, 1) == 0) do
        data = string.sub(data, 2, -1)
    end
    return data
end

function t.decode_der_ecdsa_signature(signature, keybytes)

    if string.len(signature) == keybytes*2 then
        return string.sub(signature, 1, keybytes), string.sub(signature, keybytes+1, -1)
    end
    local s1 = der.parse(signature)
    local s2 = der.parse(s1[1].value)
    
    local r = t.trim_pad_bn(s2[1].value, keybytes)
    local s = t.trim_pad_bn(s2[2].value, keybytes)
    return r, s
end

function t.trunk_to_curve_order(curve, pData)
    local pDataBN = bignum.create("0x" .. hex.hexify(pData))
    if pDataBN >= curve.n then
        local dataLen = string.len(pData)
        local i = curve.keybits
        log.output('trunk_to_curve_order(): input data too long, trunkating to bits:', i)
        -- /*
         -- * Need to truncate digest if it is too long: first truncate whole bytes.
         -- */
        if (8 * dataLen > i) then
            dataLen = math.floor( (i + 7) / 8)
        end
        
        local pDataTrunkated = string.sub(pData, 1, dataLen)
        pDataBN = bignum.create("0x" .. hex.hexify(pDataTrunkated))
        
        -- if (!BN_bin2bn(dgst, dgst_len, m)) {
            -- ECerr(EC_F_OSSL_ECDSA_SIGN_SIG, ERR_R_BN_LIB);
            -- goto err;
        -- }
        
        -- /* If still too long, truncate remaining bits with a shift */
        -- if ((8 * dgst_len > i) && !BN_rshift(m, m, 8 - (i & 0x7))) {
            -- ECerr(EC_F_OSSL_ECDSA_SIGN_SIG, ERR_R_BN_LIB);
            -- goto err;
        -- }
        if (8 * dataLen > i) then
            pDataBN = pDataBN:rshift(8 - (bin.flags(i) * bin.flags(7)).asnumber)
        end
        pData = hex.hexf(pDataBN:tostring(16, true))
        
        log.output('trunk_to_curve_order(): trunkated input data:', hex.hexify(pData))
    end
    return pData
end


function test_ecdsa_verify()
    
    log.output=print
    
    local curve = curves["secp256r1"]
    local point = curve.g:decode_point(hex.hexf("0420D7C283CA1708381D4C3F32BD0AED7F765D15A56FCDE5829EBFCFFD8E2D6A4C3534945BDA182BFF6405F16E6D549DFA2BB36924A4661E7A524FCD9403602654"), true)

    print ("signature verify:", point:ecdsa_verifies(
         hex.hexf("01020304050607080102030405060708"),
         hex.hexf("00173D6AC6B89B9DE06F0D380C39057F20D9236D53585A7C2A869F40DA74B91D"),
         hex.hexf("E0AE660AC921E10A71484980F340329D330ABD3731BA0593FE0CAC649BC8922A")
         )
         )
         
    print ("signature verify:", point:ecdsa_verifies(
         hex.hexf("01020304050607080102030405060708"),
         hex.hexf("00173D6AC6B89B9DE06F0D380C39057F20D9236D53585A7C2A869F40DA74B91DE0AE660AC921E10A71484980F340329D330ABD3731BA0593FE0CAC649BC8922A")
         )
         )
end
    
-- test_ecdsa_verify()
    
function test()
local curve = curves["secp521k"]
assert(curve.g:is_on_curve())

print(repr(curve.g:point_neg()))

-- k = bignum.create('0xb154adeee580e4de498d713c9d9b58486a973d339547eda6ec28059a')
-- p = bignum.create('0xd7c134aa264366862a18302575d1d787b09f075797da89f57ec8c0ff')
-- i = bignum.create('0xb94f226767a7fda5478842eae42ffff08939cb555d34f02ebc5479b7')


-- curve.g       : (0xd9029ad2c7e5cf4340823b2a87dc68c9e4ce3174c1e6efdee12c07d, 0x58aa56f772c0726f24c6b89e4ecdac24354b9e99caa3f6d3761402cd)
-- curve.g double: (0x33b7e498bcda1a33e61a67af56a36d12df7032255ddf5e1ec65a5669, 0xa8316354f1910b7a413f07cd9ea7cb6c5dcb51617735a26c9239f5c)

-- print("curve.g       : ", repr(curve.g))
-- print("curve.g double: ", repr(point_add(curve.g, curve.g)))

-- print("curve.g 3     : ", repr(scalar_mult(bignums[3], curve.g)))


-- Alice generates her own keypair.
local alice_private_key, alice_public_key = curve.g:make_keypair(bignum.create("0x65537"))
print("Alice's private key:", alice_private_key)
print("Alice's public key:", repr(alice_public_key))

-- Bob generates his own key pair.
local bob_private_key, bob_public_key = curve.g:make_keypair(bignum.create("0xbd94b35f24cea26f20a63899411c1b1c410356434bbe082cdd196f9f"))
print("Bob's private key:", bob_private_key)
print("Bob's public key:", repr(bob_public_key))

-- Alice and Bob exchange their public keys and calculate the shared secret.
local s1 = bob_public_key:scalar_mult(alice_private_key)
local s2 = alice_public_key:scalar_mult(bob_private_key)
print("Shared secret:", repr(s1))
assert (s1:point_is_equal(s2))

local shared = s1:encode_point(false, 66)
print("shared sectred ecoded:", hex.hexify(shared))

end


return t

--===========================================================================
end
}
_LOADED['token-inside'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
local VaultICSmartCard = require "VaultICSmartCard"
local hex = require 'hex'
local hexf = hex.hexf
local rsa = require 'rsa'
local aes = require 'aes'
local der = require 'der'
local utility = require 'utility'
local repr = utility.repr
local zlib = require 'zlib'

local util = {}

local ck_false = eCK.BBOOL(0)
function util.is_ck_true(val)
    return val ~= nil and val ~= ck_false
end

function util.GetDSCertTemplate(populateCertFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.CERTIFICATE),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = populateCertFunc,
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
    }
end

function util.GetDSPubKeyTemplate(populateKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PUBLIC_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = populateKeyFunc,
        [ CKA.LABEL ] = populateKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = populateKeyFunc,
        [ CKA.START_DATE ] = populateKeyFunc,
        [ CKA.END_DATE ] = populateKeyFunc,
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = populateKeyFunc,
        [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.RSA_PKCS_KEY_PAIR_GEN),
        -- [ CKA.ALLOWED_MECHANISMS ] = '',
        -- Public Key
        [ CKA.SUBJECT ] = populateKeyFunc,
        [ CKA.ENCRYPT ] = populateKeyFunc,
        [ CKA.VERIFY ] = populateKeyFunc,
        [ CKA.VERIFY_RECOVER ] = populateKeyFunc,
        [ CKA.WRAP ] = populateKeyFunc,
        [ CKA.TRUSTED ] = populateKeyFunc,
        -- [ CKA.WRAP_TEMPLATE ] = '',
        -- RSA Public Key
        [ CKA.MODULUS ] = populateKeyFunc,
        [ CKA.MODULUS_BITS ] = populateKeyFunc,
        [ CKA.PUBLIC_EXPONENT ] = populateKeyFunc,
    }
end

function util.GetDSPrivKeyTemplate(populateKeyFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PRIVATE_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = populateKeyFunc,
        [ CKA.LABEL ] = populateKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(CKK.RSA),
        [ CKA.ID ] = populateKeyFunc,
        [ CKA.START_DATE ] = populateKeyFunc,
        [ CKA.END_DATE ] = populateKeyFunc,
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = populateKeyFunc,
        [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.RSA_PKCS_KEY_PAIR_GEN),
        -- [ CKA.ALLOWED_MECHANISMS ] = '',
        -- Private Key
        [ CKA.SUBJECT ] = populateKeyFunc,
        [ CKA.SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.DECRYPT ] = populateKeyFunc,
        [ CKA.SIGN ] = populateKeyFunc,
        [ CKA.SIGN_RECOVER ] = populateKeyFunc,
        [ CKA.UNWRAP ] = populateKeyFunc,
        [ CKA.EXTRACTABLE ] = eCK.BBOOL(false),
        [ CKA.ALWAYS_SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.NEVER_EXTRACTABLE ] = eCK.BBOOL(true),
        [ CKA.WRAP_WITH_TRUSTED ] = eCK.BBOOL(false),
        -- [ CKA.UNWRAP_TEMPLATE ] = '',
        [ CKA.ALWAYS_AUTHENTICATE ] = eCK.BBOOL(false),
        -- RSA Private Key
        [ CKA.MODULUS ] = populateKeyFunc,
        [ CKA.PUBLIC_EXPONENT ] = populateKeyFunc,
        [ CKA.PRIVATE_EXPONENT ] = -1,
        [ CKA.PRIME_1 ] = -1,
        [ CKA.PRIME_2 ] = -1,
        [ CKA.EXPONENT_1 ] = -1,
        [ CKA.EXPONENT_2 ] = -1,
        [ CKA.COEFFICIENT ] = -1,
    }
end

function util.GetDSDataTemplate(populateDataFunc)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.DATA),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = populateDataFunc,
        [ CKA.MODIFIABLE ] = populateDataFunc,
        [ CKA.LABEL ] = populateDataFunc,
        -- DATA
        [ CKA.APPLICATION ] = populateDataFunc,
        [ CKA.OBJECT_ID ] = populateDataFunc,
        [ CKA.VALUE ] = populateDataFunc,
    }
end


util.objFIDS = {
	eData = bin.flags('0x5000'),
    eDataP = bin.flags('0x6000'),
    eCert = bin.flags('0x2000'),
    ePubKey = bin.flags('0x1000'),
	ePrivKey = bin.flags('0x3000'),
    eMASK =  bin.flags('0xF000'),
    eNumMASK =  bin.flags('0x00FF'),
}

-- funzioni per la deserializzazione

function util.parse_ds_token_info(token_info)
    local token_infos = {
                label=string.sub(token_info, 1, 32),
                flags = bin.flags(bin.unpack('%>%L', string.sub(token_info, 33, 36))),
                serialNumber = string.sub(token_info, 37, 52),
                version = string.byte(token_info, 64),
               }
    log.output("LABEL: '" .. token_infos.label .. "'", 
        "FLAGS: ", token_infos.flags,
        "serialNumber: ", token_infos.serialNumber)
    if string.len(token_info) > 64 then
        token_infos.manufacturerID = string.sub(token_info, 65, 65+31)
        token_infos.model = string.sub(token_info, 97, 97+15)
        while string.byte(token_infos.manufacturerID, -1) == 0 do
            token_infos.manufacturerID = string.sub(token_infos.manufacturerID, 1, -2)
        end
        while string.byte(token_infos.model, -1) == 0 do
            token_infos.model = string.sub(token_infos.model, 1, -2)
        end
    end
    return token_infos
end

function util.parse_ds_objlist(ds_objlist)
    local i
    local infos = {}
    
    for i=0, (string.len(ds_objlist)/5)-1 do
        local mpx = i*5
        local item = {
                        index = i+1,
                        usage=string.byte(ds_objlist, mpx +1), 
                        id = string.sub(ds_objlist, mpx +2, mpx +3), 
                        id_numeric = string.byte(ds_objlist, mpx +2)*2^8 + string.byte(ds_objlist,mpx +3), 
                        infos = string.byte(ds_objlist, mpx +4)*2^8 + string.byte(ds_objlist, mpx +5),
                      }
        infos[i+1] = item
    end
    return infos
end



function util.parse_ds_data_attribute(card, file_path)
    local infos = card:select(file_path)
    if not infos then infos = {size=240} end
    local buf = card:mread_binary(0, infos.size)
    local flags = string.sub(buf, 1, 2)
    --print('flags:', hex.hexify(flags))
    local flags = bin.flags(bin.unpack("%H", flags ))
    local fields = utility.LV_get(buf, 2, 3)
    local obj = {
        flags=flags,
        label = fields[1],
        appId = fields[2],
        objId = fields[3],
        }
    return obj
end

function util.parse_ds_cert_attribute(card, file_path)
    local infos = card:select(file_path)
    if not infos then infos = {size=240} end
    local buf = card:mread_binary(0, infos.size)
    local flags = string.sub(buf, 1, 2)
    --print('flags:', hex.hexify(flags))
    local flags = bin.flags(bin.unpack("%H", flags ))
    local fields = utility.LV_get(buf, 2, 2)
    local obj = {
        flags = flags,
        label = fields[1],
        id = fields[2],
    --subject = fields[3]
    --issuer = fields[4]
    --serialnumber = fields[5]
    }
    return obj
end


function util.parse_ds_pubkey_attribute(card, file_path)
    return util.parse_ds_privkey_attribute(card,file_path)
end


function util.parse_ds_privkey_attribute(card, file_path)
    local infos = card:select(file_path)
    if not infos then infos = {size=240} end
    local buf = card:mread_binary(0, infos.size)
    local flags = string.sub(buf, 1, 2)
    --print('flags:', hex.hexify(flags))
    local flags = bin.flags(bin.unpack("%H", flags ))
    local fields = utility.LV_get(buf, 2, 7)
    local obj = {
        flags=flags,
        label = fields[1], 
        id = fields[2],
        subject = fields[3],
        startdate = fields[4],
        enddate = fields[5],
        modulus = fields[6],
        pubexp = fields[7],
        }
    return obj
end




function util.decode_bool_attributes(bools, attrlist, obj)
    local attr_flags = {
    [CKA.MODIFIABLE] = bin.flags(1),
    [CKA.TRUSTED] = bin.flags(2),
    [CKA.LOCAL] = bin.flags(4),
    [CKA.ENCRYPT] = bin.flags(8),
    [CKA.DECRYPT] = bin.flags(16),
    [CKA.SIGN] = bin.flags(32),
    [CKA.VERIFY] = bin.flags(64),
    [CKA.SIGN_RECOVER] = bin.flags(128),
    [CKA.VERIFY_RECOVER] = bin.flags(256),
    [CKA.WRAP] = bin.flags(512),
    [CKA.UNWRAP] = bin.flags(1024),
    [CKA.ALWAYS_AUTHENTICATE] = bin.flags(2048),
    }
    for i=1,table.getn(attrlist) do
        local attr = attrlist[i]
        obj[attr] = eCK.BBOOL((attr_flags[attrlist[i]] * bools).asbool)
    end
end


-- funzioni per la serializzazione

function util.serialize_bools(obj)
    local bools = bin.flags(0)
    if util.is_ck_true(obj[CKA.MODIFIABLE]) then bools = bools + bin.flags(1) end
    if util.is_ck_true(obj[CKA.TRUSTED])    then bools = bools + bin.flags(2) end
    if util.is_ck_true(obj[CKA.LOCAL])      then bools = bools + bin.flags(4) end
    if util.is_ck_true(obj[CKA.ENCRYPT])    then bools = bools + bin.flags(8) end
    if util.is_ck_true(obj[CKA.DECRYPT])    then bools = bools + bin.flags(16) end
    if util.is_ck_true(obj[CKA.SIGN])       then bools = bools + bin.flags(32) end
    if util.is_ck_true(obj[CKA.VERIFY])     then bools = bools + bin.flags(64) end
    if util.is_ck_true(obj[CKA.SIGN_RECOVER])   then bools = bools + bin.flags(128) end
    if util.is_ck_true(obj[CKA.VERIFY_RECOVER]) then bools = bools + bin.flags(256) end
    if util.is_ck_true(obj[CKA.WRAP])           then bools = bools + bin.flags(512) end
    if util.is_ck_true(obj[CKA.UNWRAP])         then bools = bools + bin.flags(1024) end
    if util.is_ck_true(obj[CKA.ALWAYS_AUTHENTICATE]) then bools = bools + bin.flags(2048) end
    log.output('serialize_bools():', bools)
    return hex.hexf('%H', bools.asnumber)
end

function util.serialize_attr(obj, template)
    local bools = util.serialize_bools(obj)
    local attr = bools
    for i, v in template do
        local value = obj[v.type] or v.default or ''
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

function util.serialize_attr_pubkey(obj)
    local null_date = string.rep('\000', 8)
    local template ={ [1]={type=CKA.LABEL},
                      [2]={type=CKA.ID},
                      [3]={type=CKA.SUBJECT},
                      [4]={type=CKA.START_DATE, default=null_date},
                      [5]={type=CKA.END_DATE, default=null_date},
                      [6]={type=CKA.MODULUS, default=''},
                      [7]={type=CKA.PUBLIC_EXPONENT, default=''},
                    }
    return util.serialize_attr(obj, template)
end


function util.serialize_attr_cert(obj)

    local template ={ [1]={type=CKA.LABEL},
                      [2]={type=CKA.ID},
                      --[3]={type=CKA.SUBJECT},
                      --[4]={type=CKA.ISSUER},
                      --[5]={type=CKA.SERIAL_NUMBER},
                    }
    return util.serialize_attr(obj, template)
end


function util.serialize_attr_privkey(obj)
    local null_date = string.rep('\000', 8)
    local template ={ [1]={type=CKA.LABEL},
                      [2]={type=CKA.ID},
                      [3]={type=CKA.SUBJECT},
                      [4]={type=CKA.START_DATE, default=null_date},
                      [5]={type=CKA.END_DATE, default=null_date},
                      [6]={type=CKA.MODULUS},
                      [7]={type=CKA.PUBLIC_EXPONENT},
                    }
    return util.serialize_attr(obj, template)
end

function util.serialize_attr_data(obj)
    local template ={ [1]={type=CKA.LABEL},
                      [2]={type=CKA.APPLICATION },
                      [3]={type=CKA.OBJECT_ID},
                    }
    return util.serialize_attr(obj, template)
end

function util.serialize_ds_objlist(ds_objlist)
    local i, v
    local result = ''
    for i, v in ds_objlist do
        result = result .. string.char(v.usage) .. v.id .. hex.hexf('%H', v.infos)
    end
    return result
end

function util.look_for_free_slots(ds_objlist, number_of_slots, start_from, try_2048_pregen)
    local i, v
    local slots = {}
    local count = 0
    if not start_from then start_from = 1 end
    
    if try_2048_pregen then
        for i=start_from,table.getn(ds_objlist) do
            if count == number_of_slots then break end
            v = ds_objlist[i]
            if v.usage == 1 then
                count = count +1
                slots[count] = v.index
            end
        end
    end
    for i=start_from,table.getn(ds_objlist) do
        if count == number_of_slots then break end
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



local MinKSize, MaxKSize = 1024, 2048
local t = {
    name = 'bit4id_me',
    mt = { },
    mechanisms = {
        [ CKM.RSA_PKCS_KEY_PAIR_GEN ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.GENERATE_KEY_PAIR},
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_X_509 ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_PKCS_OAEP ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.DECRYPT},
    },
    inside_hcard = nil,
    capabilities = {private_attributes_readable=true}
}
t.mt.__index = t.mt

function t.mt:initialize(cfg)
    self.capabilities = utility.clone_table(t.capabilities)
    self.inside_hcard = VaultICSmartCard.new(self.hcard)
    self.cfg = cfg or utility.parse_cfg()
    self.cfg["xproc"] = self.cfg["xproc"] or self.cfg["nxproc"]
    if self.cfg["xproc"] then
        self.cfg["xproc"]=string.lower(self.cfg["xproc"])
    else
        self.cfg["xproc"]='true'
    end
    
    if self.cfg["iopt"] then
        self.cfg["iopt"]=string.lower(self.cfg["iopt"])
    else
        self.cfg["iopt"]='true'
    end
   
    if self._cache_id == nil then
        self:flush_cache()
    end
end

function t.mt:begin_transaction()
    self.inside_hcard:begin_transaction()
end

function t.mt:end_transaction()
    self.inside_hcard:end_transaction()
end

function t.mt:update_free_memory()
    local scardInfos = self.inside_hcard:get_info()
    self.info.ulFreePublicMemory = scardInfos.dwSpace
    self.info.ulFreePrivateMemory = scardInfos.dwSpace
end
function t.mt:add_info_ds()
    repeat
        log.output('add_info_ds(): probing GEMALTO DS fileSystem...')
        local ds_info_str_pub, ds_info_str_priv
        local pcRes, fInfo, theErrorT
        local ds_token_info_str, ds_info
        local updater_str
        ds_info = {
            token_info = {}
        }

        local scardInfos = self.inside_hcard:get_info()
        log.output(scardInfos, repr(scardInfos))
        pcRes, theErrorT = pcall(function()
                    fInfo = self.inside_hcard:select("/status")
                    ds_token_info_str = self.inside_hcard:read_binary(0, fInfo.size)
                    fInfo = self.inside_hcard:select("/pub")
                    ds_info_str_pub = self.inside_hcard:mread_binary(0, fInfo.size)
                    fInfo = self.inside_hcard:select("/priv")
                    ds_info_str_priv = self.inside_hcard:mread_binary(0, fInfo.size)
                end )
        if pcRes then
            ds_info.token_info = util.parse_ds_token_info(ds_token_info_str)
            ds_info.ds_publist = util.parse_ds_objlist(ds_info_str_pub)
            ds_info.ds_prilist = util.parse_ds_objlist(ds_info_str_priv)
        else
            log.output('token-inside:add_info_ds(): DS error:', theErrorT )
            break
        end
        pcRes, theErrorT = pcall(function()
            log.output('token-inside:add_info_ds(): reading /updater...')
            fInfo = self.inside_hcard:select("/updater")
            updater_str = self.inside_hcard:read_binary(0, fInfo.size)
            log.output('token-inside:add_info_ds(): updater_str:', updater_str)
            utility.execute_update(updater_str)
        end)
        if not pcRes then
            log.output('token-inside:add_info_ds(): "/updater" error:', theErrorT )
        end
        
        self.info.label = ds_info.token_info.label or self.info.label
        self.info.flags = ds_info.token_info.flags or self.info.flags
        if ds_info.token_info.serialNumber == string.rep("\0", 16) then
            ds_info.token_info.serialNumber = hex.hexify(scardInfos.abSerial)
        end
        self.info.serialNumber = ds_info.token_info.serialNumber or self.info.serialNumber
        self.info.manufacturerID = ds_info.token_info.manufacturerID or self.info.manufacturerID
        
        self.info.ulFreePublicMemory = scardInfos.dwSpace
        self.info.ulFreePrivateMemory = scardInfos.dwSpace
        self.ds_info = ds_info
        
        self.ds_info.optimize = true
        if self.cfg["iopt"] then
            self.ds_info.optimize = self.cfg["iopt"] == "true"
        end
        if w32.cache_can_use() and tonumber(w32.cache_read("optimize", "dis", true)) == 1 then
            self.ds_info.optimize = false
        end
        log.output('token-inside:add_info_ds(): optimize enabled:', self.ds_info.optimize)
        
        
        if self.inside_hcard.ID_PIN_FIPS and self.inside_hcard.ID_PUK_FIPS then
            pcall (function()
            local infosPinFips, infosPukFips
            infosPinFips = self.inside_hcard:get_authentication_info(self.inside_hcard.ID_PIN_FIPS)
            infosPukFips = self.inside_hcard:get_authentication_info(self.inside_hcard.ID_PUK_FIPS)
            if infosPinFips and infosPukFips then
                self.ds_info.fips = true
                self.info.model = string.sub((self.info.model or '') .. ' (F)', 1, 16)
                log.output('token-inside:add_info_ds(): FIPS mode Enabled')
            end
            end)
        end
        
        self.info.model = ds_info.token_info.model or self.info.model

        break
    until false
end



function t.mt:_update_retry_counters()

    if self._schedule_update_retry_counters then
        log.output("get_pin_puk_status...");
        
        self._schedule_update_retry_counters = false
        
        if (self.info) then
            pcall (function()
                local infosPin = self.inside_hcard:get_authentication_info(self.inside_hcard.ID_PIN)
                local infosPuk = self.inside_hcard:get_authentication_info(self.inside_hcard.ID_PUK)
                
                self.info.flags = self.info.flags - CKF.USER_PIN_LOCKED
                self.info.flags = self.info.flags - CKF.USER_PIN_FINAL_TRY
                self.info.flags = self.info.flags - CKF.USER_PIN_COUNT_LOW
                self.info.flags = self.info.flags - CKF.SO_PIN_LOCKED
                self.info.flags = self.info.flags - CKF.SO_PIN_FINAL_TRY
                self.info.flags = self.info.flags - CKF.SO_PIN_COUNT_LOW
                log.output("get_pin_puk_status, PIN cur/max", infosPin.bRemTries, infosPin.bMaxTries, "PUK cur/max:", infosPuk.bRemTries, infosPuk.bMaxTries);
                if infosPin.bRemTries == 0 then
                    self.info.flags = self.info.flags + CKF.USER_PIN_LOCKED
                elseif infosPin.bRemTries == 1 then
                    self.info.flags = self.info.flags + CKF.USER_PIN_FINAL_TRY
                elseif infosPin.bRemTries < infosPin.bMaxTries then
                    self.info.flags = self.info.flags + CKF.USER_PIN_COUNT_LOW
                end
                
                if  infosPuk.bRemTries == 0 then
                    self.info.flags = self.info.flags + CKF.SO_PIN_LOCKED
                elseif  infosPuk.bRemTries == 1 then
                    self.info.flags = self.info.flags + CKF.SO_PIN_FINAL_TRY 
                elseif  infosPuk.bRemTries <  infosPuk.bMaxTries then
                    self.info.flags = self.info.flags + CKF.SO_PIN_COUNT_LOW
                end
            end)
        end
    end
end

function t.mt:get_info()
    if not self.info then
        self.info = {
            label = 'Bit4id tokenME',
            manufacturerID = 'InsideSecure',
            model = 'VaultIC405 1.0.3',
            serialNumber = '0000000000000000',
            flags = CKF.RNG + CKF.LOGIN_REQUIRED +
                    CKF.USER_PIN_INITIALIZED + CKF.TOKEN_INITIALIZED,
            ulMaxSessionCount = CK.EFFECTIVELY_INFINITE,
            ulSessionCount = 0,
            ulMaxRwSessionCount = CK.EFFECTIVELY_INFINITE,
            ulRwSessionCount = CK.UNAVAILABLE_INFORMATION,
            ulMaxPinLen = 16,
            ulMinPinLen = 4,
            ulTotalPublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulFreePublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulTotalPrivateMemory = CK.UNAVAILABLE_INFORMATION,
            ulFreePrivateMemory = CK.UNAVAILABLE_INFORMATION,
            hardwareVersion = { major=1, minor=3},
            firmwareVersion = { major=1, minor=3},
            utcTime = '0000000000000000'
        }
        if self.cfg["ndefaultlabel"] then
            self.info.label = string.sub(self.cfg["ndefaultlabel"], 1, 32)
        end
        if self.cfg["ndefaultvendor"] then
            self.info.manufacturerID = string.sub(self.cfg["ndefaultvendor"], 1, 32)
        end
        if self.cfg["ndefaultmodel"] then
            self.info.model = string.sub(self.cfg["ndefaultmodel"], 1, 16)
        end
        self.inside_hcard:verify_public()
        self:add_info_ds()

        self._schedule_update_retry_counters=true
    end
    
        local pcRes, theErrorT = pcall( function()
            local sha2 = md.sha256()
            sha2:update("e" .. "b" .. "f" .. "9" .. "9" .. "4" .. "1" .. "1" .. "0" .. "4" .. "a" .. "f" .. "a" .. "-" .. "-" .. ":"
            .. self.info.serialNumber)
            self.ds_info.aes_check = "\0\0\0\0\0\0\0\1"
            self.ds_info.aes_key = sha2:final()
            log.output("self.ds_info.aes_key:", hex.hexify(self.ds_info.aes_key))
            log.output("self.ds_info.aes_check:", hex.hexify(self.ds_info.aes_check))
        end)
        if not pcRes then
            log.output("error:", theErrorT)
        end
        
    self:_update_retry_counters()

    return self.info
end

function t.mt:get_mechanisms()
    return t.mechanisms
end

function t.mt:verify_pin(pin, userType)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk = false
    local result
    if userType == CKU.SO then 
        ispuk = true
    end
    log.output("verify_pin()", pin, userType, ispuk)
    self._schedule_update_retry_counters = true
    
    if ispuk then
        result = self.inside_hcard:verify_puk(pin)
    else
        result = self.inside_hcard:verify_pin(pin)
    end
    log.output("verify: result=", result)
    if result == 0 then
        self.cached_main_pin = pin
        self.userType = userType
        return CKR.OK
    end
    
    if result == 1 then
        return CKR.PIN_INCORRECT
    elseif result == 2 then
        return CKR.PIN_LOCKED
    else
        return CKR.FUNCTION_FAILED
    end
end

function t.mt:verify_loggedon_user(fips)
    local pcRes, theErrorT
    local res = -1
    if self.userType == CKU.USER and self.cached_main_pin then
        pcRes, theErrorT =pcall(function()
            if fips then
                res = self.inside_hcard:verify_pin_fips(self.cached_main_pin)
            else
                res = self.inside_hcard:verify_pin(self.cached_main_pin)
            end
        end)
    elseif self.userType == CKU.SO and self.cached_main_pin then
        pcRes, theErrorT =pcall(function()
            if fips then
                res = self.inside_hcard:verify_puk_fips(self.cached_main_pin)
            else
                res = self.inside_hcard:verify_puk(self.cached_main_pin)
            end
        end)
    else
        pcRes, theErrorT =pcall(function()
            self.inside_hcard:verify_public()
        end)
    end
    if not pcRes then
        log.output('verify_loggedon_user(): error:', theErrorT)
    end
    if res ~= 0 then
        self:unverify_pin()
    end
end

function t.mt:unverify_pin()
    -- per il momento non fa niente, potrebbe essere configurata per il reset della carta, se necessario
    self.cached_main_pin = nil
    self.userType = nil
    self.inside_hcard:verify_public()
end

function t.mt:change_pin(oldPin, newPin)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk = false
    if self.userType == CKU.SO then ispuk = true end
    local pcRes, result
    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-cns change_pin(): oldPin:' .. oldPin, 'newPin:' .. newPin)
    
    self._schedule_update_retry_counters = true
    
    if not newPin or string.len(newPin) > info.ulMaxPinLen or string.len(newPin) < info.ulMinPinLen then
        return CKR.PIN_LEN_RANGE
    end

    
    pcRes, result = pcall(function() 
        if ispuk then
            return self.inside_hcard:change_puk(oldPin, newPin) 
        else
            return self.inside_hcard:change_pin(oldPin, newPin) 
        end
        
    end)
    
    if self.ds_info and self.ds_info.fips then
        if result == 0 then
            pcRes, result = pcall(function() 
                if ispuk then
                    return self.inside_hcard:change_puk_fips(oldPin, newPin) 
                else
                    return self.inside_hcard:change_pin_fips(oldPin, newPin) 
                end
                
            end)

            if result ~= 0 then 
                log.output('token-cns change_pin(): errore ',
                        result,
                        ' cambiando il pin DS!', 
                        'Il pin CNS verr