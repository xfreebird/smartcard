package md.moldsign.core

import java.util.Base64

/**
 * Two real, PUBLIC X.509 certificates used as stand-ins for "card A" and "card B" in the identity guard
 * tests: the MDQSign issuing CA and the mdtrustca root (the same bytes as ChainCerts.swift; embedded in
 * every signed document). No personal certificate is used in tests.
 */
internal object TestCertificates {
    val mdQSign: ByteArray = Base64.getDecoder().decode(
        listOf(
            "MIIHNDCCBRygAwIBAgIOQAAAABAwAdte06TtsCswDQYJKoZIhvcNAQELBQAwgZ8xCzAJBgNVBAYTAk1EMRMwEQYDVQQHDApDaGnI",
            "mWluxIN1MUkwRwYDVQQKDEBJUCBTZXJ2aWNpdWwgVGVobm9sb2dpYSBJbmZvcm1hyJtpZWkgxZ9pIFNlY3VyaXRhdGUgQ2liZXJu",
            "ZXRpY8SDMRIwEAYDVQQDEwltZHRydXN0Y2ExHDAaBgNVBGETE05UUk1ELTEwMDM2MDAwOTY2OTQwHhcNMjUwMTA0MTgwODIzWhcN",
            "MzUwMTA0MTgwODIzWjCBnTELMAkGA1UEBhMCTUQxEzARBgNVBAcMCkNoaciZaW7Eg3UxSTBHBgNVBAoMQElQIFNlcnZpY2l1bCBU",
            "ZWhub2xvZ2lhIEluZm9ybWHIm2llaSDFn2kgU2VjdXJpdGF0ZSBDaWJlcm5ldGljxIMxEDAOBgNVBAMTB01EUVNpZ24xHDAaBgNV",
            "BGETE05UUk1ELTEwMDM2MDAwOTY2OTQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDPVt3Po94BR147Wa6Y5XJlux6s",
            "n9qA48xabKCBdjSAi0GJ5RA0bvSA+55fS2n4WVgp7NtcwOZWcmEEd5L9seU8PFP4+Nyk49bbI57laZp9dB56UU7h0KO3B7eBObqI",
            "TS3I42sBxsO/dfju+kjP5pGQwCp3A5iW5DIzannVNDmUed4W9cZqkxuXtvmviLef1fGx8CTcumkvZk1uut++Z75RS/sQdehg1p/b",
            "Q8ZnHkY+XyXjsHyNfeXUSFzdrDFKfrRsa7KLJqKfsFBiXy0EomiWG8aOJTe5yCdRAB5owz+Xt7n95dvGBWXvQfj2BluJ24q2xj7t",
            "B1jj8sXIUH3KKiV9VN4FirkmUf+meS3Kbz6cI1HiL3ycsjGNEyujilJfzFNSSvO0sHSBiHF/l9TBLtRUm+y7eHKNwwjJ32E3lVsH",
            "gjrg+ilgIihTwLA65euVOuUh6ipCu2ljeLYN00LRofTLDPHHjc1nq3/9vOivxitQIOloMlDV3Xuu7fOQFtZqs6GRatNfbFYBD1uv",
            "6+kXrFfA5Gf3VVSrDp95EhOOnUyhSuJG9l+n+PRU/ilCjQJa9wt+AxVS6GoO23h4CUFg8zz1KVQp/eHwiEkDUtmXaE3BkgKPSdam",
            "IzxtvtCiLRKz0k0+7dSL7SfsvEdRlYW4fJtTHi4ZVSB+HifEPZICmvqsKQIDAQABo4IBbDCCAWgwZQYIKwYBBQUHAQEEWTBXMCgG",
            "CCsGAQUFBzABhhxodHRwOi8vbWR0cnVzdGNhLm9jc3AucGtpLm1kMCsGCCsGAQUFBzAChh9odHRwOi8vcGtpLm1kL2Nlci9tZHRy",
            "dXN0Y2EuY2VyMDAGA1UdHwQpMCcwJaAjoCGGH2h0dHA6Ly9wa2kubWQvY3JsL21kdHJ1c3RjYS5jcmwwDwYDVR0TAQH/BAUwAwEB",
            "/zAfBgNVHSMEGDAWgBRtNoe+Cl13PeP3cZUVjQNouLBteDA/BgNVHSAEODA2MDQGBFUdIAAwLDAqBggrBgEFBQcCARYeaHR0cDov",
            "L3BraS5tZC9wb2xpY3kvbWR0cnVzdGNhMA4GA1UdDwEB/wQEAwIBBjAdBgNVHQ4EFgQUk8qhnOFr3imIE6LXHXQyCMi27GAwKwYD",
            "VR0QBCQwIoAPMjAyNTAxMDQxODA3NDdagQ8yMDMwMDEwNDE4MDc0N1owDQYJKoZIhvcNAQELBQADggIBACp9nDDgF//MAtyF2dpm",
            "jiL48Fv0sjOjrALbLibFypd0TLHoKIfIcoYd4KlX+LdQzmKQPw5/dVg99XrCaZN5I/VWHrMjHSJNgwSD2DoylHjsJI21BnrVPsi+",
            "s1QWgIoC/GXC9Ig7M5I4puC/v5Z9ATgjP9Xqhv9zFlC6BabWVxQj/VunFsLgWFA1ttrIMTRAJV0QFFx6N3l2gTfGUlQjsVo+bzMV",
            "oQIs0c/cF/87iZRVNWwl0es6iQD7qzTOUsBusLlOySqMhxP+cWFrOol7U+H2IWKcDcfb0N17Le+Uc5knv3EIsnCHYovrk1yCwjwI",
            "smgKisRZ9OfBTNHKa8T7mlXOSIpUWZAG+pW18/PTTa5sVNYLLkWU8RwPNc5ly7+/XW6om16kMwKZAEcvLA5QIODDJOaIEy0mwbss",
            "38iHqrCCzHajZidT7fA2eTmr+GjgOvJKerykI0U8kR/mRtRH6jeU0LpAauT66iuC+aKkeAkNzPJ0CQ5JAgfTlq0L9vifvWlRg581",
            "DIH7uJ/Q4Q8HebQqZhRFYSpg52Ygr3QF0rr9HvqVAWQl6aeTFgpVNTUvlwwWl3qB3TOEmx7vNM7HDHZcyzGPjHGHcBgNaUN6082X",
            "GnE89eLjs/Ot9DHxTVeUYhWyszyRO5Fkbi9/NQBxwM1GGMPFnf72iz0onHxNkmVI",
        ).joinToString(""),
    )

    val mdTrustCa: ByteArray = Base64.getDecoder().decode(
        listOf(
            "MIIHFTCCBP2gAwIBAgIOQAAAABVgAdtezl+78M8wDQYJKoZIhvcNAQELBQAwgZ8xCzAJBgNVBAYTAk1EMRMwEQYDVQQHDApDaGnI",
            "mWluxIN1MUkwRwYDVQQKDEBJUCBTZXJ2aWNpdWwgVGVobm9sb2dpYSBJbmZvcm1hyJtpZWkgxZ9pIFNlY3VyaXRhdGUgQ2liZXJu",
            "ZXRpY8SDMRIwEAYDVQQDEwltZHRydXN0Y2ExHDAaBgNVBGETE05UUk1ELTEwMDM2MDAwOTY2OTQwHhcNMjUwMTA0MTczMDM5WhcN",
            "NDUwMTA0MTczMDM5WjCBnzELMAkGA1UEBhMCTUQxEzARBgNVBAcMCkNoaciZaW7Eg3UxSTBHBgNVBAoMQElQIFNlcnZpY2l1bCBU",
            "ZWhub2xvZ2lhIEluZm9ybWHIm2llaSDFn2kgU2VjdXJpdGF0ZSBDaWJlcm5ldGljxIMxEjAQBgNVBAMTCW1kdHJ1c3RjYTEcMBoG",
            "A1UEYRMTTlRSTUQtMTAwMzYwMDA5NjY5NDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAKQhDtFb/SypixUXE4GPtw9G",
            "VVJjlTOuRXWj498xNAUbmLlIKTD4+O50/v2IZxAKWco4nBkNrd9A5kGYhzOms6GSeL+9PAlenij1KBHKhFbl4qX8vPPrjKK7Zvrl",
            "V/JDmIDEJv7Shcs2vXdEb2UN0GsfGiLvQgwnsXseL7p5/7v0TEs+Jobi5K+yySawd+RNMtPmMS7QjLPOw57XiLxaV4zu6xBrisiH",
            "uy+XJMwzix8PPw3exJjeGPsirFS3H/ZEPLkf0u3lrbjJi/8AUSPIrZXIQ1IQLzSc7LLEmRP3EyMH8XEqNyBVJ4W/LrC9okKFEtLK",
            "uUes9POxPqBnbFjyKbD0ecuZcMRAp2v/LtHndVWwJOjmAZCx/KmiDKtuJiX7+g+EOND8s84WJtTfrAZvacP0gLg4v28GsyZ3WeOM",
            "Z+sYrbVUeP7GvxsYYXBV6VVikvZ8aUBSnfb1hmNJlDdWPP9EWgmohE1X80CS8egH3HB9rGismfOKlBVVVnxYaxiMCJqTTpI4SBFE",
            "A6jXbK8m8UyFiZHTfOmVtL0IBw9qPTbeipV+gAG36dv7LHXZY75QWykvt2VmurLgImr8N7w070+sVf1tjvbYMqkzGCBlOs7iXIhW",
            "InLAYX3GB1kvaIgHoeq82oy9Dyf9bCzTJVBXiW7cm7o7pWPVJ2Jav4YIJ61dAgMBAAGjggFLMIIBRzBlBggrBgEFBQcBAQRZMFcw",
            "KAYIKwYBBQUHMAGGHGh0dHA6Ly9tZHRydXN0Y2Eub2NzcC5wa2kubWQwKwYIKwYBBQUHMAKGH2h0dHA6Ly9wa2kubWQvY2VyL21k",
            "dHJ1c3RjYS5jZXIwMAYDVR0fBCkwJzAloCOgIYYfaHR0cDovL3BraS5tZC9jcmwvbWR0cnVzdGNhLmNybDAPBgNVHRMBAf8EBTAD",
            "AQH/MD8GA1UdIAQ4MDYwNAYEVR0gADAsMCoGCCsGAQUFBwIBFh5odHRwOi8vcGtpLm1kL3BvbGljeS9tZHRydXN0Y2EwDgYDVR0P",
            "AQH/BAQDAgEGMB0GA1UdDgQWBBRtNoe+Cl13PeP3cZUVjQNouLBteDArBgNVHRAEJDAigA8yMDI1MDEwNDE3MzAzNFqBDzIwMzUw",
            "MTA1MDUzMDM0WjANBgkqhkiG9w0BAQsFAAOCAgEAoc24v9o61RJ7NJYmBQlUkXrq6ZthmU4C0cQLm+adRfhUo66zBynHa78Srkdo",
            "sMn6WtvH7WZumLxUOMR/7MNAGwsCOC3zDbLulII39VqCKM97wBaZ6gyC1zoIkMHmSzZepeny2dXDEkT1dp859fA1L9o6FWggP7Vm",
            "M7Zyk1LKW9fIJthM+G+ecT0i8Ua6KLLw67G2Y5ktTLTXVstUzhM0qRI4lwR3k/NStNL/oy8X+Fh0udiLK8pYX9HHtBJRcmcT3F2m",
            "4nbVc96x28vDVLLQaSfuD8uD2xAuiPuUQq7JFxotVXAE5Chs69XAzt7f/WDlO7A6lqhitStGhlBPlOmJtGGA8cGR2T8uFU1WqylA",
            "fgeoBe7uf6LmT2PJv8i88A4LDF7j/0OVEhO4vB1qQxDCX7SU8XHwnrDEkv0QWPXT/kH0kgKS2JcIFItDBOJy4g6n2evDWxWMQm51",
            "H8enzYyNFZGwnMpsUSvIl3skYHvArcgd103r/jkJUD5LdNF3AqQcY+bTC9fnZ5OIn7vNhwSzVXPQLU+GGXTBTwelTcDxsfe6Em9x",
            "qSSG1Ro7qPYG7OuB0jeIoIIUlc6Ol7LFFWsC5Y8rZbbtMkfsCNsDwzu4nFDDoyXMm1ZPwtdcRyR3xTYOBy8QNuZHkF4crArao6+J",
            "tA8gVixqjDljVLkbWGqTuSM=",
        ).joinToString(""),
    )

    /** Self-signed X.509 v3 around [keys] (see [issued]). */
    fun selfSigned(keys: java.security.KeyPair, commonName: String = "Test Signer"): ByteArray =
        issued(keys, commonName, keys, commonName)

    /**
     * X.509 v3 for [subjectKeys] with subject `C=MD, CN=<subjectName>`, signed by [issuerKeys] as `C=MD, CN=<issuerName>`:
     * just enough DER for the signers and the validator (UTF-8 names, so diacritics exercise the vendor's `\XX` escaping).
     */
    fun issued(subjectKeys: java.security.KeyPair, subjectName: String, issuerKeys: java.security.KeyPair, issuerName: String): ByteArray {
        fun name(cn: String) = Der.seq(
            Der.set(Der.seq(Der.oid("550406".decodeHex()), Der.tlv(0x13, "MD".toByteArray()))),
            Der.set(Der.seq(Der.oid("550403".decodeHex()), Der.tlv(0x0C, cn.toByteArray(Charsets.UTF_8)))),
        )
        val algorithm = Der.seq(Der.oid("2A864886F70D01010B".decodeHex()), Der.NULL)
        val validity = Der.seq(Der.tlv(0x17, "250101000000Z".toByteArray()), Der.tlv(0x17, "350101000000Z".toByteArray()))
        val tbs = Der.seq(
            Der.tlv(0xA0, Der.integer(2)),
            Der.tlv(0x02, byteArrayOf(0x01, 0x23, 0x45)),
            algorithm, name(issuerName), validity, name(subjectName), subjectKeys.public.encoded,
        )
        val signature = java.security.Signature.getInstance("SHA256withRSA").run {
            initSign(issuerKeys.private)
            update(tbs)
            sign()
        }
        return Der.seq(tbs, algorithm, Der.tlv(0x03, byteArrayOf(0) + signature))
    }
}
