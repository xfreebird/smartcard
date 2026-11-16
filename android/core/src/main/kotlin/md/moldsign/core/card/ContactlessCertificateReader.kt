package md.moldsign.core

/** Public EF0001 read only. No authentication/PIN; the caller owns the connection. */
object ContactlessCertificateReader {
    /** Exact DER binding precedes mutual authentication and PIN use, including for a saved identity. */
    fun readIdentity(transport: ApduTransport, expected: ByteArray?): CertificateSummary {
        val der = read(transport)
        if (expected != null && !java.security.MessageDigest.isEqual(expected, der))
            throw CardError.CardChanged(Sha.sha1(expected).toHex(), Sha.sha1(der).toHex())
        return CertificateSummary.parse(der)
    }
    fun read(transport: ApduTransport): ByteArray {
        fun exchange(command: ByteArray): ByteArray {
            var request = command
            var data = ByteArray(0)
            repeat(8) {
                val response = ApduResponse.parse(transport.transmit(request))
                data += response.data
                if (data.size > 4096) throw CardError.Protocol("Public response too large")
                if (response.sw1 == 0x61) request = bytesOf(0, 0xC0, 0, 0, response.sw2)
                else {
                    if (response.sw != 0x9000) throw CardError.fromStatusWord(response.sw, "Public certificate")
                    return data
                }
            }
            throw CardError.Protocol("Public response chaining limit")
        }
        // IAS discovery is explicit on Android (iOS performs it before delivering the tag).
        exchange(bytesOf(0, 0xA4, 4, 0, CosmoXCard.IAS_AID.size) + CosmoXCard.IAS_AID + bytesOf(0))
        exchange(bytesOf(0, 0xA4, 4, 4, CosmoXCard.GENERIC_ADF.size) + CosmoXCard.GENERIC_ADF + bytesOf(0))
        exchange("00A4020402000100".decodeHex())
        var certificate = ByteArray(0)
        fun read(count: Int) {
            val offset = certificate.size
            val part = exchange(bytesOf(0, 0xB0, offset ushr 8, offset and 255, count))
            if (part.size != count) throw CardError.Protocol("Incomplete public certificate")
            certificate += part
        }
        read(2)
        if (certificate.u8(0) != 0x30) throw CardError.Protocol("Invalid certificate header")
        val first = certificate.u8(1)
        val length = if (first < 128) first else {
            val count = first and 127
            if (count !in 1..2) throw CardError.Protocol("Invalid certificate length")
            read(count)
            var n = 0
            for (b in certificate.drop(2)) n = n * 256 + (b.toInt() and 255)
            if (certificate.u8(2) == 0 || n < 128 || (count == 2 && n < 256))
                throw CardError.Protocol("Invalid certificate length encoding")
            n
        }
        val total = certificate.size + length
        if (total !in 16..4096) throw CardError.Protocol("Invalid certificate size")
        while (certificate.size < total) read(minOf(128, total - certificate.size))
        return certificate
    }
}
