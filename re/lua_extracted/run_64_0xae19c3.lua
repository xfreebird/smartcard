 quindi possibile usare l'attributo CKA_ALWAYS_AUTHENTICATE
    -- per stabilire quale dei PIN usare. Viene dunque sfruttato lo stesso meccanismo del PKCS#11:
    -- i PIN sono identici oppure viene usata l'interfaccia utente.
    capabilities = { private_attributes_readable=false, always_authenticate_on_cert=false, },
    CnsSmartcard=CnsSmartcard,
    CnsSmartcard_w=CnsSmartcard_w,
}
t.mt.__index = t.mt


-- CKM_EC_KEY_PAIR_GEN
-- CKM_ECDSA
-- CKM_ECDSA_SHA1 ?
-- CKM_ECDH1_DERIVE ?
-- CKM_ECDH1_COFACTOR_DERIVE ?
-- CKM_ECMQV_DERIVE ?

-- ECC mechanism infos:
-- CKF_EC_F_P
-- CKF_EC_OID
-- CKF_EC_UNCOMPRESS
-- CKF_EC_COMPRESS ?

-- Parameters ::= CHOICE {
-- ecParameters ECParameters,
-- namedCurve CURVES.&id({CurveNames}),
-- implicitlyCA NULL                      -- NOT SUPPORTED by Cryptoki
-- curveName PrintableString              -- NEW TO Cryptoki v3.0
-- }



local function GetSecretKeyTemplate(populatePubKeyFunc, cka_key_type)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.SECRET_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = eCK.BBOOL(true),
        [ CKA.LABEL ] = populatePubKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(cka_key_type or CKK.AES),
        [ CKA.ID ] = populatePubKeyFunc,
        [ CKA.START_DATE ] = populatePubKeyFunc,
        [ CKA.END_DATE ] = populatePubKeyFunc,
        [ CKA.DERIVE ] = eCK.BBOOL(false),
        [ CKA.LOCAL ] = populatePubKeyFunc,
        [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.AES_KEY_GEN),
        -- [ CKA.ALLOWED_MECHANISMS ] = '',
        -- Private Key
        [ CKA.SUBJECT ] = populatePubKeyFunc,
        [ CKA.SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.DECRYPT ] = populatePubKeyFunc,
        [ CKA.ENCRYPT ] = populatePubKeyFunc,
        [ CKA.SIGN ] = eCK.BBOOL(false),
        [ CKA.SIGN_RECOVER ] = eCK.BBOOL(false),
        [ CKA.UNWRAP ] = eCK.BBOOL(false),
        [ CKA.EXTRACTABLE ] = eCK.BBOOL(false),
        [ CKA.ALWAYS_SENSITIVE ] = eCK.BBOOL(true),
        [ CKA.NEVER_EXTRACTABLE ] = eCK.BBOOL(true),
        [ CKA.WRAP_WITH_TRUSTED ] = eCK.BBOOL(false),
        -- [ CKA.UNWRAP_TEMPLATE ] = '',
        [ CKA.ALWAYS_AUTHENTICATE ] = eCK.BBOOL(false),
        --  Private Key
        [ CKA.VALUE ] = -1,
    }
end

function objOberthurTmpl.GetECCPubKeyTemplate(populateKeyFunc, cka_key_type)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PUBLIC_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(false),
        [ CKA.MODIFIABLE ] = populateKeyFunc,
        [ CKA.DESTROYABLE ] = populateKeyFunc,
        [ CKA.LABEL ] = populateKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(cka_key_type or CKK.ECDSA),
        [ CKA.ID ] = populateKeyFunc,
        [ CKA.START_DATE ] = populateKeyFunc,
        [ CKA.END_DATE ] = populateKeyFunc,
        [ CKA.DERIVE ] = populateKeyFunc,
        [ CKA.LOCAL ] = populateKeyFunc,
        --[ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.EC_KEY_PAIR_GEN),
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
        [ CKA.EC_PARAMS ] = populateKeyFunc,
        [ CKA.EC_POINT ] = populateKeyFunc,
    }
end

function objOberthurTmpl.GetECCPrivKeyTemplate(populateKeyFunc, cka_key_type)
    return {
        [ CKA.CLASS ] = eCK.OBJECT_CLASS(CKO.PRIVATE_KEY),
        -- Storage
        [ CKA.TOKEN ] = eCK.BBOOL(true),
        [ CKA.PRIVATE] = eCK.BBOOL(true),
        [ CKA.MODIFIABLE ] = populateKeyFunc,
        [ CKA.DESTROYABLE ] = populateKeyFunc,
        [ CKA.LABEL ] = populateKeyFunc,
        -- Key
        [ CKA.KEY_TYPE ] = eCK.KEY_TYPE(cka_key_type or CKK.ECDSA),
        [ CKA.ID ] = populateKeyFunc,
        [ CKA.START_DATE ] = populateKeyFunc,
        [ CKA.END_DATE ] = populateKeyFunc,
        [ CKA.DERIVE ] = populateKeyFunc,
        [ CKA.LOCAL ] = populateKeyFunc,
        -- [ CKA.KEY_GEN_MECHANISM ] = eCK.ULONG(CKM.EC_KEY_PAIR_GEN),
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
        [ CKA.ALWAYS_AUTHENTICATE ] = populateKeyFunc,
        -- RSA Private Key
        [ CKA.EC_PARAMS ] = populateKeyFunc,
        [ CKA.EC_POINT ] = populateKeyFunc,
        [ CKA.VALUE ] = populateKeyFunc,
    }
end


function CnsSmartcard.mt:sm_transmit_oberthur(plain_apdu, sm_enc, sm_sig, reuse_nonces)
    local recv = nil
    local apdu = plain_apdu
    local sw
    if sm_enc and sm_sig then
        local nonce_to_card
        local nonce_from_card
        log.output('sm_transmit(): sending SM apdu; plain:', hex.hexify(plain_apdu))
        if reuse_nonces and self._last_random_from_card and self._last_random_to_card then
        
            nonce_to_card = self._last_random_to_card
            nonce_from_card = self._last_random_from_card
            log.output('sm_transmit(): reusing last used nonces:', hex.hexify(nonce_to_card), hex.hexify(nonce_from_card))
        else
            nonce_to_card = sm.gen_random(8)
            nonce_from_card = self:get_random(8)
            nonce_to_card = self:set_random(nonce_to_card)
        end
        local sm_apdu = sm.sm_encode(
                        apdu, 
                        nonce_from_card, sm_enc, sm_sig)

        recv = self:transmit(sm_apdu)
        if string.len(recv) == 2 then
            -- response is not encrypted
            return recv
        end
        sw = string.sub(recv, -2, -1)
        
        if sw ~= hexf('9000') and sw ~= hexf('6282') then
            if string.sub(recv, 1, 2) == hex.hexf("9902") then
                log.output('sm_transmit(): detected possible signed SW response:', hex.hexify(recv))
            else
                log.output('sm_transmit(): Error ' .. hexify(sw))
                error(CnsSmartcardError.new(sw, 'sm_transmit Error' ), 2)
            end
        end
        local decoded, valid, mac_valid, inner_sw = self:dec_mac_msg(
                        recv,
                        apdu,
                        nonce_to_card,
                        sm_enc,
                        sm_sig
                        )
        if decoded ~= nil and (valid and not mac_valid) then
            log.output('sm_transmit(): Error response data MAC not valid')
            error(CnsSmartcardError.new(nil, 'sm_transmit Error: response data MAC not valid' ), 2)
        elseif decoded ~= nil and (valid and mac_valid) then
            recv = decoded .. inner_sw
        else
            log.output('sm_transmit(): Warning, SM response data was not decoded...')
            -- restituisce recv cosi' come 