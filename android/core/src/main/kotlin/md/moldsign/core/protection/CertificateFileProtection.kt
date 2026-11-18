package md.moldsign.core.protection

import java.security.SecureRandom
import java.security.cert.X509Certificate
import java.security.interfaces.RSAPublicKey
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec

object CertificateFileProtection {
    const val SUFFIX = ".asymmetric.p7m"
    private fun hex(s: String) = s.chunked(2).map { it.toInt(16).toByte() }.toByteArray()
    private val enveloped = hex("2a864886f70d010703")
    private val dataOID = hex("2a864886f70d010701")
    private val rsaOID = hex("2a864886f70d010101")
    private val aesOID = hex("608648016503040102")
    private fun w(tag: Int, content: ByteArray) = ProtectionASN1.wrap(tag,content)
    fun recipientKey(certificate: X509Certificate): RSAPublicKey {
        require(certificate.keyUsage?.getOrNull(2) == true) { "Choose an encryption certificate, not a signing-only certificate." }
        val key = certificate.publicKey as? RSAPublicKey ?: error("Unsupported encryption certificate.")
        require(key.modulus.bitLength() in 2048..8192)
        return key
    }

    private fun identity(certificate: X509Certificate): ByteArray {
        val fields = ProtectionASN1.parse(certificate.encoded).requireTag(0x30,3)[0].requireTag(0x30)
        val offset = if (fields.first().tag == 0xa0) 1 else 0
        require(fields.size >= offset+6 && fields[offset].tag == 2 && fields[offset+2].tag == 0x30)
        return w(0x30, fields[offset+2].encoded + fields[offset].encoded)
    }
    fun encrypt(plain: ByteArray, certificate: X509Certificate): ByteArray {
        require(plain.size <= PasswordFileProtection.MAXIMUM_SIZE) { "Choose a file smaller than 64 MB." }
        val identity = identity(certificate)
        val publicKey = recipientKey(certificate)
        val random = SecureRandom(); val key = ByteArray(16).also(random::nextBytes); val iv = ByteArray(16).also(random::nextBytes)
        try {
            val wrapped = Cipher.getInstance("RSA/ECB/PKCS1Padding").run { init(Cipher.ENCRYPT_MODE,publicKey); doFinal(key) }
            val encrypted = Cipher.getInstance("AES/CBC/PKCS5Padding").run { init(Cipher.ENCRYPT_MODE,SecretKeySpec(key,"AES"),IvParameterSpec(iv)); doFinal(plain) }
            val recipient = w(0x30,w(2,byteArrayOf(0)) + identity + w(0x30,w(6,rsaOID)+byteArrayOf(5,0)) + w(4,wrapped))
            val content = w(0x30,w(6,dataOID) + w(0x30,w(6,aesOID)+w(4,iv)) + w(0x80,encrypted))
            return w(0x30,w(6,enveloped)+w(0xa0,w(0x30,w(2,byteArrayOf(0))+w(0x31,recipient)+content)))
        } finally { key.fill(0) }
    }
    fun decrypt(envelope: ByteArray, certificate: X509Certificate, unwrap: (ByteArray) -> ByteArray): ByteArray {
        val identity = identity(certificate)
        val publicKey = recipientKey(certificate)
        val root = ProtectionASN1.parse(envelope)
        val outer = root.requireTag(0x30)
        val body = if (outer.firstOrNull()?.tag == 2) root.requireTag(0x30,3) else {
            require(outer.size == 2 && outer[0].tag == 6 && outer[0].content.contentEquals(enveloped))
            outer[1].requireTag(0xa0,1)[0].requireTag(0x30,3)
        }
        require(body[0].tag == 2 && body[0].content.contentEquals(byteArrayOf(0)))
        val recipients = body[1].requireTag(0x31); require(recipients.size in 1..32)
        var encryptedKey: ByteArray? = null
        for (node in recipients) {
            val r = node.requireTag(0x30,4); val algorithm = r[2].requireTag(0x30)
            require(r[0].tag == 2 && r[0].content.contentEquals(byteArrayOf(0)) && r[3].tag == 4 && algorithm.size in 1..2 && algorithm[0].tag == 6 && algorithm[0].content.contentEquals(rsaOID) && (algorithm.size == 1 || (algorithm[1].tag == 5 && algorithm[1].content.isEmpty())))
            if (r[1].encoded.contentEquals(identity)) { require(encryptedKey == null && r[3].content.size == (publicKey.modulus.bitLength()+7)/8); encryptedKey = r[3].content }
        }
        val content = body[2].requireTag(0x30,3); val algorithm = content[1].requireTag(0x30,2)
        require(content[0].tag == 6 && content[0].content.contentEquals(dataOID) && algorithm[0].tag == 6 && algorithm[0].content.contentEquals(aesOID) && algorithm[1].tag == 4 && algorithm[1].content.size == 16)
        val ciphertext = content[2].octets(true); require(ciphertext.isNotEmpty() && ciphertext.size % 16 == 0)
        val key = unwrap(encryptedKey ?: error("File does not match this encryption certificate."))
        try {
            require(key.size == 16)
            return Cipher.getInstance("AES/CBC/PKCS5Padding").run { init(Cipher.DECRYPT_MODE,SecretKeySpec(key,"AES"),IvParameterSpec(algorithm[1].content)); doFinal(ciphertext) }
        } finally { key.fill(0) }
    }
}
