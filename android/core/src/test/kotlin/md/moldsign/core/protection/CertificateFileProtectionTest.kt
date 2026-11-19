package md.moldsign.core.protection
import org.junit.Assert.*
import org.junit.Test
import java.io.File
import java.security.KeyFactory
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.security.spec.PKCS8EncodedKeySpec
import javax.crypto.Cipher

class CertificateFileProtectionTest {
    @Test fun signingOnlyFixtureRequiresExplicitPublicKeyPolicy() {
        val root=File(System.getProperty("moldsign.repoRoot"),"spec/vectors/encryption")
        fun certificate(name:String)=File(root,name).inputStream().use { CertificateFactory.getInstance("X.509").generateCertificate(it) as X509Certificate }
        val cert=certificate("test-signing-only.der")
        val other=certificate("test-recipient.der")
        val key=KeyFactory.getInstance("RSA").generatePrivate(PKCS8EncodedKeySpec(File(root,"test-private-key.pk8").readBytes()))
        val plain=byteArrayOf(0,1,0x80.toByte(),0,255.toByte())
        assertThrows(IllegalArgumentException::class.java) { CertificateFileProtection.recipientKey(cert) }
        assertThrows(IllegalArgumentException::class.java) { CertificateFileProtection.encrypt(plain,cert) }
        val envelope=CertificateFileProtection.encrypt(plain,cert,CertificateRecipientPolicy.CARD_PUBLIC_KEY)
        var calls=0
        val unwrap:(ByteArray)->ByteArray={wrapped->calls++;Cipher.getInstance("RSA/ECB/PKCS1Padding").run { init(Cipher.DECRYPT_MODE,key);doFinal(wrapped) }}
        assertThrows(IllegalArgumentException::class.java) { CertificateFileProtection.decrypt(envelope,cert,unwrap) }
        assertThrows(IllegalStateException::class.java) { CertificateFileProtection.decryptWithPolicy(envelope,other,CertificateRecipientPolicy.CARD_PUBLIC_KEY,unwrap) }
        assertEquals(0,calls)
        assertArrayEquals(plain,CertificateFileProtection.decryptWithPolicy(envelope,cert,CertificateRecipientPolicy.CARD_PUBLIC_KEY,unwrap))
        assertEquals(1,calls)
    }
    @Test fun vendorCMSAndNativeRoundTrip() {
        val root = File(System.getProperty("moldsign.repoRoot"),"spec/vectors/encryption")
        val cert = File(root,"test-recipient.der").inputStream().use { CertificateFactory.getInstance("X.509").generateCertificate(it) as X509Certificate }
        val key = KeyFactory.getInstance("RSA").generatePrivate(PKCS8EncodedKeySpec(File(root,"test-private-key.pk8").readBytes()))
        val unwrap: (ByteArray) -> ByteArray = { Cipher.getInstance("RSA/ECB/PKCS1Padding").run { init(Cipher.DECRYPT_MODE,key); doFinal(it) } }
        val plain = File(root,"plain-1024.bin").readBytes()
        assertArrayEquals(plain,CertificateFileProtection.decrypt(File(root,"vendor-certificate.asymmetric.p7m").readBytes(),cert,unwrap))
        val native = CertificateFileProtection.encrypt(plain,cert)
        assertArrayEquals(plain,CertificateFileProtection.decrypt(native,cert,unwrap))
        assertEquals(ProtectionHeader(true), ProtectionHeader.detect(native.copyOf(96)))
        assertEquals(ProtectionHeader(true), ProtectionHeader.detect(File(root, "vendor-certificate.asymmetric.p7m").readBytes().copyOf(96)))
        System.getenv("MSIGN_ENCRYPTION_ORACLE_OUTPUT")?.let { File(it,"native-certificate.asymmetric.p7m").writeBytes(native) }
        var calls = 0
        assertThrows(IllegalArgumentException::class.java) { CertificateFileProtection.decrypt(native.copyOf(native.size-1),cert) { calls++; byteArrayOf() } }
        assertEquals(0,calls)
    }
}
