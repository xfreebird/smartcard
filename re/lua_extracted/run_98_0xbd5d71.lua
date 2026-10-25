 oggetti ritorna 0
function t.mt:get_item(search_state, showprivate, template)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    if search_state.lastobj==nil then 
        search_state.lastobj=self.attributes.min_index 
    end
    for i=search_state.lastobj, self.attributes.max_index do
        local attr = self.attributes[i]
        if attr ~= nil then
            if type(attr[CKA.PRIVATE]) == 'function' then
                attr[CKA.PRIVATE](self, i, CKA.PRIVATE, false)
            end
            local visible = attr[CKA.PRIVATE] == eCK.BBOOL(false) or 
                            (attr[CKA.PRIVATE] == eCK.BBOOL(true) and showprivate)
            if not visible then
                log.output('get_item(): handle', i, 'not visible')
            end
            if visible and self:verify_template(i, template) then
                search_state.lastobj = i +1
                return i
            end
        end
    end
    search_state.lastobj = self.attributes.max_index +1 -- next search returns no object
    return 0
end

function t.mt:verify_template(hobj, template)
    -- contolla prima tutti gli attributi statici
    local static_attributes = {CKA.CLASS, CKA.TOKEN }
    for i, attr_type in static_attributes do
        if template[attr_type] then
            local rv, real_value = self:get_attribute_value(hobj, attr_type)
            if rv~=CKR.OK or real_value ~= template[attr_type] then
                -- log.output('>>>not match')
                -- log.output('>>>false')
                return false
            end
        end
    end

    for attr_type, value in template do
        
        local rv, real_value
        rv, real_value = self:get_attribute_value(hobj, attr_type)
        if attr_type == CKA.SERIAL_NUMBER
                and real_value ~= nil 
                and type(real_value) == 'string' 
                and value ~= nil then
            real_value = string.gsub(real_value, '%z*(.*)', '%1')
            value = string.gsub(value, '%z*(.*)', '%1')
        end
        --log.output('>>>template: ', hex.tohex8(attr_type),
        --           repr(value), repr(real_value), rv)
        if rv~=CKR.OK or real_value ~=value then
            -- log.output('>>>not match')
            -- log.output('>>>false')
            return false
        else
            -- log.output('>>>match')
        end
    end
    -- log.output('>>>true')
    return true
end

function t.mt:_add_objects(objects)
    log.output("_add_objects(): scanning objects...")
    
    for i=1,table.getn(self.cert_templates) do
        local cert = self.cert_templates[i]
        local pcRes, theErrorT = pcall(function()
            log.output("_add_objects(): evaluating:", hex.hexify(cert.id))
            local certValue, certInfo, MSCUID, objInfo = self.piv_hcard:get_certificate(cert.cert_path)
            -- log.output("_add_objects(): cert value:", hex.hexify(cert))
            cert.value = certValue
            cert.certInfo = certInfo
            cert.MSCUID = MSCUID
            cert.objInfo = objInfo
        end)
        if not pcRes then
            log.output('error:', theErrorT)
        end
    end
    
    log.output("_add_objects(): adding objects found...")
    for i=1,table.getn(self.cert_templates) do
        local cert = self.cert_templates[i]
        log.output("_add_objects(): evaluating object num:", i)
        local parsed_cer
        local keyvalid, certvalid
        local modulus, pubexp
        local cka_id = cert.id
        local cka_label_cert = cert.cert_label
        local cka_label_key = cert.key_label
        
        if cert.certInfo == 1 and type(cert.objInfo) == "string" and string.len(cert.objInfo) > 0 then
            log.output("_add_objects(): found a key only object...")
            local obj = {}
            obj = t.parse_p11v2_attributes(obj, cert.objInfo, {CKA.LABEL, CKA.ID, CKA.MODULUS, CKA.PUBLIC_EXPONENT})
            cka_label_key = obj[CKA.LABEL] or cka_label_key
            cka_id = obj[CKA.ID] or cka_id
            modulus = obj[CKA.MODULUS]
            pubexp = obj[CKA.PUBLIC_EXPONENT]
            keyvalid = true
            log.output("_add_objects(): cka_id", hex.hexify(cka_id or ""))
            log.output("_add_objects(): cka_label_key", hex.hexify(cka_label_key or ""))
            log.output("_add_objects(): modulus", hex.hexify(modulus or ""))
            log.output("_add_objects(): pubexp", hex.hexify(pubexp or ""))
        elseif type(cert.value) == "string" and string.len(cert.value) > 0 then
            local obj = {}
            log.output("_add_objects(): found cert value:", hex.hexify(cert.value))
            if cert.objInfo then
                obj = t.parse_p11v2_attributes(obj, cert.objInfo, {CKA.LABEL, CKA.ID})
                cka_id = obj[CKA.ID] or cka_id
                cka_label_cert = obj[CKA.LABEL] or cka_label_cert
                cka_label_key = cka_label_cert
            end
            parsed_cer = der.parse_x509cer(cert.value)
            if parsed_cer then
                certvalid = true
                keyvalid = cert.certInfo == 0
                modulus = parsed_cer.modulus
                pubexp = parsed_cer.pubexp
            end
            log.output("_add_objects(): cka_id", hex.hexify(cka_id or ""))
            log.output("_add_objects(): cka_label_cert", hex.hexify(cka_label_cert or ""))
            log.output("_add_objects(): cka_label_key", hex.hexify(cka_label_key or ""))
            log.output("_add_objects(): modulus", hex.hexify(modulus or ""))
            log.output("_add_objects(): pubexp", hex.hexify(pubexp or ""))
        end
        
        if certvalid then
            log.output("_add_objects(): adding CERT object with label:", cka_label_cert)
            local obj = GetCertTemplate()
            obj.private = false
            obj[CKA.PRIVATE] = eCK.BBOOL(false)
            obj[CKA.LABEL] = cka_label_cert
            obj[CKA.ID] = cka_id
            obj[CKA.VALUE] = cert.value
            obj[CKA.SUBJECT] = (parsed_cer and parsed_cer.subject) or ''
            obj[CKA.ISSUER] = (parsed_cer and parsed_cer.issuer) or ''
            obj[CKA.SERIAL_NUMBER] = (parsed_cer and parsed_cer.serialNumber) or ''
            obj.key_bits = string.len((parsed_cer and parsed_cer.modulus) or '') * 8
            obj.path = cert.cert_path
            objects.max_index = objects.max_index +1
            objects[ objects.max_index] = obj
            log.output(string.format("_add_objects(): added sign certificate handle:%d", objects.max_index))
        end
        
        if keyvalid then
        
            log.output("_add_objects(): adding PRIV KEY object with label:", cka_label_key)
            local obj = GetPrivKeyTemplate()
            obj.private = true
            obj[CKA.PRIVATE] = eCK.BBOOL(true)
            obj[CKA.LABEL] = cka_label_key
            obj[CKA.ID] = cka_id
            obj[CKA.MODULUS] = modulus or ''
            obj[CKA.PUBLIC_EXPONENT] = pubexp or ''

            obj.id = cert.key_kid
            obj.path = cert.cert_path -- related certificate
            obj.certvalid = certvalid
            
            obj.key_bits = string.len(modulus or '') * 8

            obj[CKA.SIGN] = eCK.BBOOL(true)
            obj[CKA.DECRYPT] = eCK.BBOOL(not cert.signonly)
            objects.max_index = objects.max_index +1
            objects[ objects.max_index] = obj
            log.output( string.format("_add_objects(): added priv key handle:%d", objects.max_index) )
            
            log.output("_add_objects(): adding PUK KEY object  with label:", cka_label_key)
            local obj = GetPubKeyTemplate()
            obj.private = false
            obj[CKA.PRIVATE] = eCK.BBOOL(false)
            obj[CKA.LABEL] = cka_label_key
            obj[CKA.ID] = cka_id
            obj[CKA.MODULUS] = modulus or ''
            obj[CKA.PUBLIC_EXPONENT] = pubexp or ''
            obj.id = cert.key_kid
            obj.path = cert.cert_path -- related certificate
            obj.certvalid = certvalid
            obj.key_bits = string.len(modulus or '') * 8
            
            obj[CKA.VERIFY] = eCK.BBOOL(true)
            obj[CKA.ENCRYPT] = eCK.BBOOL(not cert.signonly)
            objects.max_index = objects.max_index +1
            objects[ objects.max_index] = obj
            log.output( string.format("_add_objects(): added pub key handle:%d", objects.max_index) )
        end
        
        cert.modulus = modulus
        cert.pubexp = pubexp
    end
end


function t.mt:get_objects()
    log.output('token-piv:get_objects()')
    
    local info = self:get_info() -- carica le info sul filesystem in cache
    
    local objects = {
            min_index = 11001, -- primo indice disponibile
            max_index = 11000, -- valore dell'indice massimo (i valori intermedi possono anche essere nil)
        }

    self:_add_objects(objects)

    return objects
end

function t.mt:get_attribute_value(hobj, attr, onlysize)
    if onlysize==nil then onlysize = false end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hobj]
    if obj == nil then return CKR.OBJECT_HANDLE_INVALID end
    local result = obj[attr]
    if result == nil then
        log.output('get_attribute_value(): object', hobj, 'doesn\'t define sepcified attribute', attr)
        return CKR.ATTRIBUTE_TYPE_INVALID 
    end
    if type(result)=='function' then
        local rv
        rv, result = result(self, hobj, attr, onlysize)
        if rv ~= CKR.OK then return rv end
    elseif type(result)=='number' then
        return CKR.ATTRIBUTE_SENSITIVE
    end
    if onlysize and type(result)=='string' then
        return CKR.OK, string.len(result)
    else
        return CKR.OK, result
    end
end



function t.mt:_pad_bignum(big_num, pad_to)
    if not big_num or big_num == "" then
       return CKR.ATTRIBUTE_VALUE_INVALID, nil 
    end
    while string.sub(big_num, 1, 1) == '\000' do big_num = string.sub(big_num, 2, -1) end
    big_num = string.rep('\000', pad_to - string.len(big_num))
                            .. big_num
    if string.len(big_num) ~= pad_to then
        log.output('_pad_bignum(): value len invalid; expected:', pad_to)
        return CKR.ATTRIBUTE_VALUE_INVALID, nil
    end
    return CKR.OK, big_num
end


function t._is_private_attribute(attr_type)
    local private_attributes = {
        CKA.PRIVATE_EXPONENT,
        CKA.PRIME_1,
        CKA.PRIME_2,
        CKA.EXPONENT_1,
        CKA.EXPONENT_2,
        CKA.COEFFICIENT,
        CKA.PRIME,
        CKA.SUBPRIME,
        CKA.BASE,
    }
    for i, v in private_attributes do
        if attr_type == v then
            return true
        end
    end
    return false
end

function t.parse_p11v2_attributes(obj, buf, items)
    local fields = utility.LV_get(buf, 0, table.getn(items))
    for i, v in items do
        obj[v] = fields[i]
    end
    return obj
end


function t.serialize_attr_p11v2(obj, template)
    local attr = ""
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
    log.output('serialize_attr_p11v2():', hex.hexify(attr))
    return attr
end


function t.serialize_attr_p11v2_cert(obj)

    local template ={ [1]={type=CKA.LABEL},
                      [2]={type=CKA.ID},
                    }
    return t.serialize_attr_p11v2(obj, template)
end


function t.serialize_attr_p11v2_privkey(obj)
    local template ={ [1]={type=CKA.LABEL},
                      [2]={type=CKA.ID},
                      [3]={type=CKA.MODULUS},
                      [4]={type=CKA.PUBLIC_EXPONENT},
                    }
    return t.serialize_attr_p11v2(obj, template)
end


function t.mt:create_object_certificate(pTemplate)
    log.output('create_object_certificate()', pTemplate)
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    if not pTemplate[CKA.VALUE] then
        log.output('create_object_certificate(): VALUE not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    local actual_cert_data = pTemplate[CKA.VALUE]
    
    local parsed_cer = der.parse_x509cer(actual_cert_data)
    
    if not parsed_cer then
        log.output('create_object_certificate(): error parsing X509 certificate')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    if self.use_cpr_mode then
        local cpr = zlib.compresscer( pTemplate[CKA.VALUE])
        local decpr = cpr and zlib.decompresscer(cpr)
        if decpr == actual_cert_data then
            actual_cert_data = cpr
            pcall(function()
            log.output('create_object_certificate(): cpr ratio:', 
                string.len(cpr)/string.len(pTemplate[CKA.VALUE]))
            end)
        else
            log.output('create_object_certificate(): compression failed!')
        end
    end

    obj = GetCertTemplate()
    obj.private = false
    local foundcert
    local cert
    local matching = false
    
    log.output("create_object_certificate():  self.cert_templates before:", repr( self.cert_templates))
    
    if pTemplate[CKA.ID] == cert_ids.CERT_CARDAUTH
            or pTemplate[CKA.LABEL] == cert_ids.CERT_CARDAUTH then
        
        foundcert = cert_ids.auth
        cert = self.cert_templates[1]
        
    elseif pTemplate[CKA.ID] == cert_ids.CERT_PIVAUTH
            or pTemplate[CKA.LABEL] == cert_ids.CERT_PIVAUTH then
        
        foundcert = cert_ids.piv
        cert = self.cert_templates[2]
        
    elseif pTemplate[CKA.ID] == cert_ids.CERT_DIGSIG
            or pTemplate[CKA.LABEL] == cert_ids.CERT_DIGSIG then
        foundcert = cert_ids.sign
        cert = self.cert_templates[3]
        
    elseif pTemplate[CKA.ID] == cert_ids.CERT_KEYMANAGE
            or pTemplate[CKA.LABEL] == cert_ids.CERT_KEYMANAGE then
        foundcert = cert_ids.encr
        cert = self.cert_templates[4]
        
    else
        -- look for free slot
        for i=5,table.getn(self.cert_templates) do
            local cert1 = self.cert_templates[i]
            log.output("create_object_certificate(): find free slot: evaluating slot", i, repr(cert1))
            if parsed_cer.modulus == cert1.modulus then
                log.output('create_object_certificate(): found matching private key:', cert1.key_kid)
                foundcert = cert1.cert_path
                matching=true
                cert = cert1
            end
            if not foundcert then
                if cert1.certInfo == nil then
                    log.output('create_object_certificate(): found free slot:', cert1.key_kid)
                    foundcert = cert1.cert_path
                    cert = cert1
                end
            end
        end
    end
    
    if not foundcert then
        log.output('create_object_certificate(): no free slot found!')
        return CKR.DEVICE_MEMORY
    end
    
    obj.path = foundcert
    
    log.output('create_object_certificate(): selected cert:', obj.path )
    
    self:invalidate_xproc_cache()


    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] then
            obj[k] = pTemplate[k]
        end
    end
    
    local certInfo = 2
    if matching then
        certInfo = 0
    end
    -- scrive il certificato
    self.piv_hcard:external_auth()
    local certAttributes = t.serialize_attr_p11v2_cert(obj) 
    log.output('create_object_certificate(): certAttributes=', hex.hexify(certAttributes))
    self.piv_hcard:write_certificate(actual_cert_data, obj.path, certInfo, nil, certAttributes )
 
    cert.certInfo = certInfo
    cert.modulus = parsed_cer.modulus
    cert.pubexp = parsed_cer.pubexp
    cert.value = actual_cert_data
    
    log.output("create_object_certificate(): poupated slot:", repr(cert))
    log.output("create_object_certificate():  self.cert_templates after:", repr( self.cert_templates))
 
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj

    return CKR.OK, self.attributes.max_index
end


function t.mt:generate_key_pair(pMechanism, templatePub, templatePriv)
    log.output('generate_key_pair()', templatePub, templatePriv)
    if self.userType ~= CKU.USER then
        log.output('generate_key_pair(): not loggen in, userType', self.userType)
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local templatePub1 = utility.clone_table(templatePub)
    local templatePriv1 = utility.clone_table(templatePriv)
    
    if templatePub1[CKA.ID] then
        templatePriv1[CKA.ID] = templatePub1[CKA.ID]
    elseif templatePriv1[CKA.ID] then
        templatePub1[CKA.ID] = templatePriv1[CKA.ID]
    end
    
    templatePub1[CKA.LOCAL] = eCK.BBOOL(true)
    templatePriv1[CKA.LOCAL] = eCK.BBOOL(true)
    
    templatePriv1[CKA.SIGN] = templatePriv1[CKA.SIGN] or eCK.BBOOL(true)
    templatePriv1[CKA.DECRYPT] = templatePriv1[CKA.DECRYPT] or eCK.BBOOL(true)
    
    templatePriv1[CKA.CLASS] = eCK.ULONG(CKO.PRIVATE_KEY)
    templatePriv1[CKA.KEY_TYPE] = eCK.ULONG(CKK.RSA)
    
    local cka_modulus_bits = templatePub1[CKA.MODULUS_BITS] or templatePriv1[CKA.MODULUS_BITS] or eCK.ULONG(1024)
    local modulus_bits = 1024    
    if not cka_modulus_bits or cka_modulus_bits == eCK.ULONG(1024) then
        modulus_bits = 1024
    elseif cka_modulus_bits == eCK.ULONG(2048) then
        modulus_bits = 2048
    else
        log.output('generate_key_pair(): key size invalid for selected filesystem:', hex.hexify(cka_modulus_bits or '') )
        return CKR.ATTRIBUTE_VALUE_INVALID    
    end
   
    local objPriv = GetPrivKeyTemplate()
    local objPub = GetPubKeyTemplate()
    objPriv.private = true
    objPriv.key_bits = modulus_bits

    objPub.private = false
    objPub.key_bits = modulus_bits

    
    self:invalidate_xproc_cache()

    local cert_path = ""
    local foundkey
    local cert
    if templatePriv1[CKA.ID] == cert_ids.CERT_CARDAUTH
            or templatePriv1[CKA.LABEL] == cert_ids.CERT_CARDAUTH
            or templatePub1[CKA.LABEL] == cert_ids.CERT_CARDAUTH then
            
        foundkey = key_ids.auth
        cert = self.cert_templates[1]
        
    elseif templatePriv1[CKA.ID] == cert_ids.CERT_PIVAUTH
            or templatePriv1[CKA.LABEL] == cert_ids.CERT_PIVAUTH
            or templatePub1[CKA.LABEL] == cert_ids.CERT_PIVAUTH then
            
        foundkey = key_ids.piv
        cert = self.cert_templates[2]
        
    elseif templatePriv1[CKA.ID] == cert_ids.CERT_DIGSIG
            or templatePriv1[CKA.LABEL] == cert_ids.CERT_DIGSIG
            or templatePub1[CKA.LABEL] == cert_ids.CERT_DIGSIG then
        foundkey = key_ids.sign
        cert = self.cert_templates[3]
        
    elseif templatePriv1[CKA.ID] == cert_ids.CERT_KEYMANAGE
            or templatePriv1[CKA.LABEL] == cert_ids.CERT_KEYMANAGE
            or templatePub1[CKA.LABEL] == cert_ids.CERT_KEYMANAGE then
        foundkey = key_ids.encr
        cert = self.cert_templates[4]
        
    else
        -- look for free slot
        for i=5,table.getn(self.cert_templates) do
            cert = self.cert_templates[i]
            log.output("generate_key_pair(): find free slot: evaluating slot", i, repr(cert))
            if not cert.certInfo then
                log.output('generate_key_pair(): found free slot:', cert.key_kid)
                foundkey = cert.key_kid
                break
            end
        end
    end
    
    if not foundkey then
        log.output('generate_key_pair(): no free slot found!')
        return CKR.DEVICE_MEMORY
    end
    
    cert_path = key_ids.match[foundkey]
    objPriv.id = foundkey
    log.output('generate_key_pair(): selected Kid:', objPriv.id )
    log.output('generate_key_pair(): cert_path:', cert_path )
    
    objPub.id = objPriv.id
    
    log.output(string.format("generate_key_pair(): new obj id:%s bits:%d", 
        objPriv.id, objPriv.key_bits) )
    
    
    log.output('generate_key_pair(): verify_pin() with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.piv_hcard:verify_pin(self.cached_main_pin)
    end
    
    log.output('generate_key_pair(): generating key pair...')
    self.piv_hcard:external_auth()
    local modulus, pubExp = self.piv_hcard:new_generate_keypair(objPriv.id, modulus_bits)
    templatePub1[CKA.MODULUS] = modulus
    templatePub1[CKA.PUBLIC_EXPONENT] = pubExp
    templatePub1[CKA.CLASS] = eCK.ULONG(CKO.PUBLIC_KEY)
    templatePub1[CKA.KEY_TYPE] = eCK.ULONG(CKK.RSA)
    templatePub1[CKA.TOKEN] = eCK.BBOOL(true)
    
    templatePriv1[CKA.MODULUS] = modulus        -- cache preventiva
    templatePriv1[CKA.PUBLIC_EXPONENT] = pubExp
    
    cert.modulus = modulus
    cert.pubexp = pubExp
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if templatePriv1[k] and not t._is_private_attribute(k) then
            objPriv[k] = templatePriv1[k]
        end
    end

    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if templatePub1[k]  then
            objPub[k] = templatePub1[k]
        end
    end
    

    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPriv
    local hPrivk = self.attributes.max_index


    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = objPub
    local hPubk = self.attributes.max_index
    
    local privAttributes = t.serialize_attr_p11v2_privkey(objPriv)
    
    log.output('generate_key_pair(): privAttributes=', hex.hexify(privAttributes))
    self.piv_hcard:write_certificate("", cert_path, 1, nil,  privAttributes)
    cert.certInfo = 1
    return CKR.OK, hPubk, hPrivk
end




function t.mt:create_object_pubkey(pTemplateOrig, keyReference, as_local)
    log.output('create_object_pubkey():', pTemplateOrig, "as_local:", as_local, "keyReference:", keyReference)
    
    -- keyReference: quando specificato crea una chiave pubblica associata ad una chiave privata
    local pTemplate = utility.clone_table(pTemplateOrig)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    if not pTemplate[CKA.MODULUS] or not pTemplate[CKA.PUBLIC_EXPONENT] then
        log.output('create_object_pubkey(): MODULUS or PUBLIC_EXPONENT not specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local modulus_bits = string.len(pTemplate[CKA.MODULUS]) * 8
    if modulus_bits ~= 1024 and modulus_bits ~= 2048 then
        log.output('create_object_pubkey(): MODULUS size not 1024 or 2048!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end
    
    obj = GetPubKeyTemplate()
    obj.private = false
    obj.key_bits = modulus_bits
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if not pTemplate[k] and obj[k] and type(pTemplate[k]) == 'string' then
            obj[k] = pTemplate[k]
        end
    end
    obj[CKA.LOCAL] = eCK.BBOOL(as_local)

    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    return CKR.OK, self.attributes.max_index
end

function t.mt:create_object_privkey(pTemplateOrig)
    log.output('create_object_privkey()', pTemplateOrig)
    
    local pTemplate = utility.clone_table(pTemplateOrig)
    pTemplate[CKA.LOCAL] = eCK.BBOOL(false)
    
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    if not pTemplate[CKA.MODULUS]
        or not pTemplate[CKA.PUBLIC_EXPONENT] 
        -- or not pTemplate[CKA.PRIVATE_EXPONENT] -- non usato
        or not pTemplate[CKA.PRIME_1]
        or not pTemplate[CKA.PRIME_2]
        or not pTemplate[CKA.EXPONENT_1]
        or not pTemplate[CKA.EXPONENT_2]
        or not pTemplate[CKA.COEFFICIENT]
        then
            log.output('create_object_privkey(): all Private Key components must be specified!')
        return CKR.TEMPLATE_INCOMPLETE
    end
    
    local modulus_bits = string.len(pTemplate[CKA.MODULUS]) * 8
    if modulus_bits ~= 1024 and modulus_bits ~= 2048 then
        log.output('create_object_privkey(): MODULUS size not 1024 or 2048!')
        return CKR.ATTRIBUTE_VALUE_INVALID
    end

    self:invalidate_xproc_cache()
    
    obj = GetPrivKeyTemplate()
    obj.private = true
    obj.key_bits = modulus_bits
    
    local cert_path = ""
    local foundkey
    local cert
    local matching
    
    log.output("create_object_privkey():  self.cert_templates before:", repr( self.cert_templates))
    
    if pTemplate[CKA.ID] == cert_ids.CERT_CARDAUTH
            or pTemplate[CKA.LABEL] == cert_ids.CERT_CARDAUTH then
            
        foundkey = key_ids.auth
        cert = self.cert_templates[1]
        
    elseif pTemplate[CKA.ID] == cert_ids.CERT_PIVAUTH
            or pTemplate[CKA.LABEL] == cert_ids.CERT_PIVAUTH then
            
        foundkey = key_ids.piv
        cert = self.cert_templates[2]
        
    elseif pTemplate[CKA.ID] == cert_ids.CERT_DIGSIG
            or pTemplate[CKA.LABEL] == cert_ids.CERT_DIGSIG then
        foundkey = key_ids.sign
        cert = self.cert_templates[3]
        
    elseif pTemplate[CKA.ID] == cert_ids.CERT_KEYMANAGE
            or pTemplate[CKA.LABEL] == cert_ids.CERT_KEYMANAGE then
        foundkey = key_ids.encr
        cert = self.cert_templates[4]
        
    else
        -- look for free slot
        for i=5,table.getn(self.cert_templates) do
            local cert1 = self.cert_templates[i]
            log.output("create_object_privkey(): find free slot: evaluating slot", i, repr(cert1))
            if pTemplate[CKA.MODULUS] == cert1.modulus then
                log.output('create_object_privkey(): found matching certificate:', cert1.key_kid)
                foundkey = cert1.key_kid
                matching = true
                cert = cert1
            end
            if not foundkey then
                if cert1.certInfo == nil then
                    log.output('create_object_privkey(): found free slot:', cert1.key_kid)
                    foundkey = cert1.key_kid
                    cert = cert1
                end
            end
        end
        -- for i=5,table.getn(self.cert_templates) do
            -- cert = self.cert_templates[i]
            -- if not cert.certInfo then
                -- log.output('create_object_privkey(): found free slot:', cert.key_kid)
                -- foundkey = cert.key_kid
                -- break
            -- end
        -- end
    end
    
    if not foundkey then
        log.output('create_object_privkey(): no free slot found!')
        return CKR.DEVICE_MEMORY
    end

    cert_path = key_ids.match[foundkey]
    obj.id = foundkey
    log.output('create_object_privkey(): selected Kid:', obj.id )
    log.output('create_object_privkey(): cert_path:', cert_path )
    
    
    self.piv_hcard:external_auth()
    
    self.piv_hcard:import_private_key(obj.id,
                pTemplate[CKA.MODULUS], 
                pTemplate[CKA.PUBLIC_EXPONENT],
                pTemplate[CKA.PRIME_1],
                pTemplate[CKA.PRIME_2],
                pTemplate[CKA.COEFFICIENT],
                pTemplate[CKA.EXPONENT_1],
                pTemplate[CKA.EXPONENT_2]
                )
    
    cert.modulus = pTemplate[CKA.MODULUS]
    cert.pubexp = pTemplate[CKA.PUBLIC_EXPONENT]
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] and not t._is_private_attribute(k) then
            obj[k] = pTemplate[k]
        end
    end
    
    local privAttributes
    
    if matching then
        privAttributes = t.serialize_attr_p11v2_cert(obj)
        log.output('create_object_privkey(): privAttributes=certAttributes=', hex.hexify(privAttributes))
        self.piv_hcard:write_certificate(cert.value, cert_path, 0, nil,  privAttributes)
        cert.certInfo = 0
    else
        privAttributes = t.serialize_attr_p11v2_privkey(obj)
        log.output('create_object_privkey(): privAttributes=', hex.hexify(privAttributes))
        self.piv_hcard:write_certificate("", cert_path, 1, nil,  privAttributes)
        cert.certInfo = 1
    end
    
    log.output("create_object_privkey(): poupated slot:", repr(cert))
    log.output("create_object_privkey():  self.cert_templates after:", repr( self.cert_templates))
    
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj
    local hPriv = self.attributes.max_index
    return CKR.OK, hPriv
end


function t.mt:create_object_data(pTemplate)
    local usBin, index, FAuthId
    log.output('create_object_data()', pTemplate)
    if self.userType ~= CKU.USER then
        return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj
    local dataValue = pTemplate[CKA.VALUE] or '\000'

    obj = GetDataObjectTemplate()
    obj.private = pTemplate[CKA.PRIVATE] and pTemplate[CKA.PRIVATE] ~= eCK.BBOOL(false)
    
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] then
            obj[k] = pTemplate[k]
        end
    end
    
    -- adds new handle to the list
    self.attributes.max_index = self.attributes.max_index +1
    self.attributes[self.attributes.max_index] = obj

    return CKR.OK, self.attributes.max_index
end


function t.mt:create_object(pTemplate)

    log.output('create_object(): verify_pin() cached pin, with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        log.output('create_object(): verifying cached pin...')
        self.piv_hcard:verify_pin(self.cached_main_pin)
    end
    local rv, hObj
    
    self:invalidate_xproc_cache()
    
    if pTemplate[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        rv, hObj = self:create_object_pubkey(pTemplate)
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        rv, hObj = self:create_object_privkey(pTemplate)
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        rv, hObj = self:create_object_certificate(pTemplate)
        
    elseif pTemplate[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        rv, hObj = self:create_object_data(pTemplate)        
    else
        log.output('create_object(): unsupported object class:', hex.hexify(pTemplate[CKA.CLASS] or ''))
        rv = CKR.ATTRIBUTE_VALUE_INVALID
    end
    return rv, hObj

end

function t.mt:destroy_object(hObject)
    log.output('destroy_object(): ', hObject)

    log.output('destroy_object(): verify_pin() cached pin, with:', self.cached_main_pin, self.userType)
    if self.userType == CKU.USER and self.cached_main_pin then
        self.piv_hcard:verify_pin(self.cached_main_pin)
    end

    if self.userType ~= CKU.USER then
        --return CKR.USER_NOT_LOGGED_IN
    end
    if self.attributes == nil then
        log.output('destroy_object(): WARNING: user not logged in!')
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hObject]

    if not obj then
        log.output('destroy_object(): invalid handle!')
        return CKR.OBJECT_HANDLE_INVALID
    end
    
    self:invalidate_xproc_cache()
    local erase
    
    if obj[CKA.CLASS] == eCK.ULONG(CKO.CERTIFICATE) then
        log.output('destroy_object(): CERTIFICATE')
        erase = true
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PUBLIC_KEY) then
        log.output('destroy_object(): PUBLIC_KEY')
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.PRIVATE_KEY) then
        log.output('destroy_object(): PRIVATE_KEY')
        log.output('destroy_object(): obj.certvalid:', obj.certvalid)
        if not obj.certvalid then
            erase = true
        end
        
    elseif obj[CKA.CLASS] == eCK.ULONG(CKO.DATA) then
        log.output('destroy_object(): DATA')
    else
        log.output('destroy_object(): WARNING! Unsupported object class!')
        return CKR.FUNCTION_FAILED
    end
    
    if erase then
        self.piv_hcard:external_auth()
        log.output('destroy_object(): writing blank certificate to:', obj.path)
        self.piv_hcard:write_certificate("", obj.path)
        local cert = cert_ids.certs[obj.path]
        if cert then
            cert.value = ""
            cert.certInfo = nil
            cert.modulus = nil
            cert.MSCUID = nil
            cert.objInfo = nil
            cert.certvalid = false
        end
    end
    self.attributes[hObject] = nil
    return CKR.OK
end


function t.mt:set_attribute_value(hObject, pTemplate)

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

    log.output('set_attribute_value(): copying new values in memory')
    for k=CKA.CLASS,CKA.ALWAYS_AUTHENTICATE do
        if pTemplate[k] then
            obj[k] = pTemplate[k]
        end
    end
    return CKR.OK
end


function t.mt:alloc_object_handle()
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    self.attributes.max_index = self.attributes.max_index + 1
    return self.attributes.max_index
end


function t.mt:flush_cache()
    if self.cfg["xproc"] ~= "true" then
        return false
    end
    local changed, cache_id
    if self._cache_id == nil then
        log.output("token-piv:flush_cache(): initializing _cache_id")
        changed, self._cache_id = utility.has_token_changed(self, "cache", 0)
        log.output("token-piv:flush_cache(): initialize: _cache_id:", self._cache_id)
    end
    changed, cache_id = utility.has_token_changed(self, "cache", self._cache_id)
    if changed then
        log.output("token-piv:flush_cache(): token has changed!")
        self._cache_id = cache_id
        self.info = nil -- rimuove cache oggetti
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

function t.mt:valid()
    local rv = self.piv_hcard:valid()
    return rv
end


function t.mt:set_label(Puk, label)
    local rv = CKR.OK
    local info = self:get_info()
    log.output('set_label():', Puk, label)
    local value = label .. string.rep(" ", 32 - string.len(label))
    value = string.sub(value, 1, 32)
            
    local recv = self.piv_hcard:transmit(hex.hexf("00CB3FFF055C035FC10700"))
    if recv and string.sub(recv, -2, -1) == hex.hexf('9000') and 
        string.sub(recv, 1, 1) == hex.hexf('53')
        then
        
        local parsed1 = Smartcard.parse_tlv_ber(recv)
        local parsed2 = Smartcard.parse_tlv_ber(parsed1[tag_53] or "") or {}
        parsed2[tag_C1] = value
        
        local newData = ""
        
        for i, v in parsed2 do
            log.output('set_label(): tag:', i, "value:", hex.hexify(v))
            newData = newData .. Smartcard.make_tlv_ber(i, v)
        end
        
        newData = hex.hexf("5C035FC107") .. Smartcard.make_tlv_ber(tag_53, newData)
        self.piv_hcard:external_auth()
        recv = self.piv_hcard:transmit(hex.hexf("00DB3FFF%P", newData))
        
        if string.sub(recv, -2, -1) == hex.hexf('9000') then
            self.info.label = value
            return CKR.OK
        end
    end

    return CKR.FUNCTION_FAILED
end

return t

--===========================================================================
end
}
_LOADED['token-iasecc'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- token-iasecc.lua
local IasEccSmartcard = require 'IasEccSmartcard'
local hex = require 'hex'
local zlib = require "zlib"
local hexf = hex.hexf
local der = require 'der'
local p15 = require 'p15util'
local utility = require 'utility'
local repr = utility.repr

local MinKSize, MaxKSize = 1024, 1024
local t = {
    name = 'iasecc',
    mt = { },
    mechanisms = {
        [ CKM.RSA_PKCS_KEY_PAIR_GEN ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.GENERATE_KEY_PAIR},
        [ CKM.RSA_PKCS ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.DECRYPT+CKF.SIGN},
        [ CKM.RSA_X_509 ] = {ulMinKeySize=MinKSize, ulMaxKeySize=MaxKSize, flags=CKF.DECRYPT+CKF.SIGN},
    },
    iasecc_hcard = nil,
    capabilities = { private_attributes_readable=false, always_authenticate_on_cert=false, },
    IasEccSmartcard=IasEccSmartcard,
}
t.mt.__index = t.mt


function t.mt:initialize(cfg)
    log.output('token-iasecc:initialize():')
    
    self.capabilities = utility.clone_table(t.capabilities)
    self.iasecc_hcard = IasEccSmartcard.new(self.hcard)
    self.iasecc_hcard.BSO_PIN = hex.h2i('82')
    self.iasecc_hcard.BSO_PUK = hex.h2i('83')
    self.mechanisms = utility.clone_table(t.mechanisms)
    
    self.slow_card = false
    self.userPinInitialized = true
    
    self.request_plugin_valid = w32.request_plugin_valid()
    self.cfg = cfg or utility.parse_cfg()

    self.cfg["fcpr"] = self.cfg["fcpr"] or self.cfg["acfcpr"]
    self.cfg["xproc"] = self.cfg["xproc"] or self.cfg["acxproc"]
    
    
    if self.cfg["fcpr"] then
        self.cfg["fcpr"]=string.lower(self.cfg["fcpr"])
        self.use_cpr_mode = self.cfg["fcpr"] == "true"
        -- se non specificato non si attiva mai
    end
    
    if self.cfg["xproc"] then self.cfg["xproc"]=string.lower(self.cfg["xproc"])
    else self.cfg["xproc"]='true' end
    
    log.output('iassecc token initialize(): use_cpr_mode:', self.use_cpr_mode)
    
    self.check_box_visible = 0
    if self.cfg["hidecachedspincheck"] == 'true' then
        self.check_box_visible = nil
    end
    if self._cache_id == nil then
        self:flush_cache()
    end
end

function t.mt:begin_transaction()
    self.iasecc_hcard:begin_transaction()
end

function t.mt:end_transaction()
    self.iasecc_hcard:end_transaction()
end

function t.mt:_call_on_end_transaction()
    log.output('token-iasecc:_call_on_end_transaction()...')
    self.iasecc_hcard:on_end_transaction()
end


function t.mt:finalize()
    log.output("token-iasecc:finalize():", self.userType)
    utility.forget_token_changed(self, "cache")
end

function t.mt:add_info()
    log.output("add_info() reading SN")
    self.info.serialNumber = string.upper(self.iasecc_hcard:read_serial_number())
    log.output("add_info() reading indexes")
    self:_read_token_info_indexes()
    local infos, pcRes, theErrorT
    log.output("add_info() reading total space")
    pcRes, theErrorT = pcall(function()
        infos = self.iasecc_hcard:select(self.files.PubValues, true)
        self.info.ulTotalPublicMemory = infos.size
        log.output("add_info() total pub space:", self.info.ulTotalPublicMemory)
    end)
    if not pcRes then
        log.output("add_info() read total pub mem error:", theErrorT)
    end
    pcRes, theErrorT = pcall(function()
        infos = self.iasecc_hcard:select(self.files.PrivValues, true)
        self.info.ulTotalPrivateMemory = infos.size
        log.output("add_info() total priv space:", self.info.ulTotalPrivateMemory)
    end)
    if not pcRes then
        log.output("add_info() read total priv mem error:", theErrorT)
    end

    if self.userPinInitialized then
        self.info.flags = self.info.flags + CKF.USER_PIN_INITIALIZED
    else
        self.info.flags = self.info.flags - CKF.USER_PIN_INITIALIZED
    end
    
    self:_update_retry_counters()
end

function t.mt:_update_retry_counters()

    if (self.info) then
        pcall (function()
        
            self.info.flags = self.info.flags - CKF.USER_PIN_LOCKED
            self.info.flags = self.info.flags - CKF.USER_PIN_FINAL_TRY
            self.info.flags = self.info.flags - CKF.USER_PIN_COUNT_LOW
            self.info.flags = self.info.flags - CKF.SO_PIN_LOCKED
            self.info.flags = self.info.flags - CKF.SO_PIN_FINAL_TRY
            self.info.flags = self.info.flags - CKF.SO_PIN_COUNT_LOW
            
            local pinRetry, pinRetryMax, pukRetry, pukRetryMax = self.iasecc_hcard:get_pin_puk_status()
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

function t.mt:update_free_mem(info)
    self:_read_indexes()
end

function t.mt:get_info()
    if not self.info then
        self.info = {
            label = 'Bit4id IAS/ECC',
            manufacturerID = '',
            model = 'IAS/ECC',
            serialNumber = '0000000000000000',
            flags = CKF.RNG + CKF.LOGIN_REQUIRED +
                    CKF.USER_PIN_INITIALIZED + CKF.TOKEN_INITIALIZED,
            ulMaxSessionCount = CK.EFFECTIVELY_INFINITE,
            ulSessionCount = 0,
            ulMaxRwSessionCount = CK.EFFECTIVELY_INFINITE,
            ulRwSessionCount = CK.UNAVAILABLE_INFORMATION,
            ulMaxPinLen = 8,
            ulMinPinLen = 4,
            ulTotalPublicMemory = 30000,
            ulFreePublicMemory = CK.UNAVAILABLE_INFORMATION,
            ulTotalPrivateMemory = 768,
            ulFreePrivateMemory = CK.UNAVAILABLE_INFORMATION,
            hardwareVersion = { major=3, minor=0},
            firmwareVersion = { major=3, minor=0},
            utcTime = '0000000000000000'
        }
        
        self:add_info()
        self:update_free_mem(self.info)      
        if self.cfg["adefaultlabel"] then
            self.info.label = self.cfg["adefaultlabel"]
        end

    end
    if self._schedule_update_retry_counters then
        self._schedule_update_retry_counters = false
        self:_update_retry_counters()
    end

    return self.info
end

function t.mt:get_mechanisms()
    local info = self:get_info()
    return self.mechanisms
end

function t.mt:verify_pin(pin, userType, contextual_obj)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk = false
    local result
    if userType == CKU.SO then 
        ispuk = true
    end
    log.output("verify_pin()", pin, userType, ispuk, contextual_obj)
    self._schedule_update_retry_counters = true
    
    result = self.iasecc_hcard:verify_pin_main(pin, ispuk, false) -- pin, ispuk, check
    log.output("verify_pin_main(): result=", result)
    if result == 0 then
        self.cached_main_pin = pin
        self.userType = userType
        self.cached_ds_pin = nil
        
        if self.attributes == nil then
            self.attributes = self:get_objects()
        else
            self:_add_private_objects(self.attributes)
        end
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

function t.mt:unverify_pin()
    -- per il momento non fa niente, potrebbe essere configurata per il reset della carta, se necessario
    self.cached_main_pin = nil
    self.userType = nil
    self.cached_ds_pin = nil
end

function t.mt:change_pin(oldPin, newPin)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local ispuk = false
    if self.userType == CKU.SO then ispuk = true end
    local pcRes, result
    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-iasecc change_pin(): oldPin:' .. oldPin, 'newPin:' .. newPin)

    self._schedule_update_retry_counters = true
    
    if newPin and (string.len(newPin) < info.ulMinPinLen or string.len(newPin) > info.ulMaxPinLen) then
        log.output('token-iasecc change_pin(): value not in range:', info.ulMinPinLen, info.ulMaxPinLen)
        return CKR.PIN_LEN_RANGE   
    end
    if ispuk and self.puk_not_modifiable then
        log.output('token-iasecc change_pin(): PUK not modifiable!')
        return CKR.PIN_LEN_RANGE
    end
    local rv
    log.output('token-iasecc change_pin(): cambio pin MAIN...')

    pcRes, result = pcall(function() 
            return self.iasecc_hcard:change_pin_main(oldPin, newPin, ispuk) -- oldPin, newPin, ispuk
        end)

    if result == 0 then
        -- la carta potrebbe dimenticare lo stato di logged in quando si effettua una change pin
        self.cached_main_pin = newPin
        pcRes, result = pcall(function()    
                return self.iasecc_hcard:verify_pin_main(newPin, ispuk, false)  -- pin, ispuk, check
            end)
        return CKR.OK
    elseif result == 1 then
        return CKR.PIN_INCORRECT
    elseif result == 2 then
        return CKR.PIN_LOCKED
    else
        return CKR.FUNCTION_FAILED
    end
end

function t.mt:reset_pin(newPin)
    -- result == 0 (ok), 1 (failed), 2(blocked)
    local pcRes, result
    local info = self:get_info() -- carica le info sul filesystem in cache
    log.output('token-iasecc reset_pin(): newPin:', newPin)
    log.output('token-iasecc reset_pin(): reset pin MAIN...')
    if self.userType ~= CKU.SO then
        log.output('token-iasecc reset_pin(): user not SO!')
        return CKR.USER_TYPE_INVALID
    end
    
    local rv

    self._schedule_update_retry_counters = true
    
    if newPin and (string.len(newPin) < info.ulMinPinLen or string.len(newPin) > info.ulMaxPinLen) then
        log.output('token-iasecc reset_pin(): value not in range:', info.ulMinPinLen, info.ulMaxPinLen)
        return CKR.PIN_LEN_RANGE   
    end
    
    pcRes, result = pcall(function()
        return self.iasecc_hcard:reset_pin_main(self.cached_main_pin, newPin) -- Puk, newPin
        end)
    if result == 0 then
        return CKR.OK
    elseif result == 1 then
        return CKR.PIN_INCORRECT
    elseif result == 2 then
        return CKR.PIN_LOCKED
    else
        return CKR.FUNCTION_FAILED
    end
end



--=====================================================================================

function t.mt:sign_buffer(hKey, pMechanism, pData, allocated_space)
    
    log.output('sign_buffer():', hKey, pMechanism, hex.hexify(pData or ''), allocated_space)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('sign_buffer(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('sign_buffer(): ERROR: non private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end
    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    local pcRes, result

    if dataLen > keyBytes or (dataLen > (keyBytes -4) and dataLen <  keyBytes) then
        -- nota: il padding pkcs1 richiede almeno 8 byte di oxFF prima dei dati da firmare
        log.output('sign_buffer(): specified data len invalid: ', dataLen)
        return CKR.DATA_LEN_RANGE
    end
    if allocated_space==nil then
        log.output('sign_buffer(): returning signature length:', keyBytes)
        return CKR.OK, keyBytes
    else
    
        local contextual_pin = nil
        local check_pin_status = 0
        log.output('sign_buffer(): using RSA-CDS mode on kid:', obj.kid)
            
        
        pcall(function()
            log.output('sign_buffer(): verify_pin_main() with:', self.cached_main_pin, self.userType)
            if self.cached_main_pin and self.userType == CKU.USER then
                self.iasecc_hcard:verify_pin_main(self.cached_main_pin, false, false, true) -- pin, ispuk, check, use_sm
            end
        end)
            
        pcRes, result = pcall(function()
                        return self.iasecc_hcard:pso_rsa_internal_authenticate(
                            pData,
                            obj.kid,
                            contextual_pin)
                        end )
        local last_sw = self.iasecc_hcard.last_sw
        local pin_incorrect = string.sub(last_sw, 1, 1) == hexf('63')
        local pin_locked = last_sw == hexf('6983')
        if not pcRes then
            log.output("sign_buffer(): error:", theErrorT)
        end

        if pcRes then
            return CKR.OK, result
        elseif contextual_pin and (pin_incorrect or pin_locked ) then
            log.output('sign_buffer(): contextual PIN was incorrect or locked!')
            if pin_incorrect then return CKR.PIN_INCORRECT
            elseif pin_locked then return CKR.PIN_LOCKED
            else return CKR.FUNCTION_FAILED
            end
        end

    end
    log.output('sign_buffer(): unexpected!')
    return CKR.FUNCTION_FAILED
end

function t.mt:decrypt_buffer(hKey, pMechanism, pData, allocated_space)
    
    if self.attributes == nil then
        self.attributes = self:get_objects()
    end
    local obj = self.attributes[hKey]
    if obj == nil then
        log.output('decrypt_buffer(): specified handle invalid: ' .. hKey)
        return CKR.OBJECT_HANDLE_INVALID
    end
    if obj[CKA.CLASS] ~= eCK.OBJECT_CLASS(CKO.PRIVATE_KEY) then
        log.output('decrypt_buffer(): ERROR: not a private key object!')
        return CKR.KEY_TYPE_INCONSISTENT
    end

    local keyBytes = obj.key_bits/8
    local dataLen = string.len(pData)
    if dataLen ~= keyBytes then
        log.output('decrypt_buffer(): specified data len invalid: ', dataLen, ', expected:', keyBytes)
        return CKR.ENCRYPTED_DATA_LEN_RANGE
    end
    
    pcall(function()
        log.output('decrypt_buffer(): verify_pin_main() with:', self.cached_main_pin, self.userType)
        if self.cached_main_pin and self.userType == CKU.USER then
            self.iasecc_hcard:verify_pin_main(self.cached_main_pin, false, false, true) -- pin, ispuk, check, use_sm
        end
    end)
    local pDataPadded
    pDataDecrypted = self.iasecc_hcard:pso_decrypt(pData, obj.kid) -- data, id
    
    return CKR.OK, pDataDecrypted
end


-- se search_state.lastobj==nil si richiede l'handle del primo oggetto che risponda
-- al template. Altrimenti restituisce il primo oggetto che sia
-- compatibile con il template e abbia handle>search_state.lastobj.
-- quando non ci sono pi