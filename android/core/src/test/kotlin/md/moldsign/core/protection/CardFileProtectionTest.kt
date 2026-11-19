package md.moldsign.core.protection
import md.moldsign.core.*
import org.junit.Assert.*
import org.junit.Test
import java.io.File
import java.security.KeyFactory
import java.security.spec.PKCS8EncodedKeySpec

class CardFileProtectionTest {
    private val root=File(SpecFiles.repoRoot,"spec/vectors/encryption")
    private fun setup(signingOnly:Boolean=false):Pair<CosmoXCard,SimulatedCard> {
        val transport=SimulatedCard(SpecFiles.cardCrypto)
        val (key,cert,pin)=CardEncryptionDirectoryTest().fixture(pinType=2)
        transport.extraFiles.putAll(mapOf("7001" to pin,"7002" to key,"7005" to cert,"0002" to File(root,if(signingOnly) "test-signing-only.der" else "test-recipient.der").readBytes()))
        transport.decryptKey=KeyFactory.getInstance("RSA").generatePrivate(PKCS8EncodedKeySpec(File(root,"test-private-key.pk8").readBytes()))
        val card=CosmoXCard(transport);card.authenticate();return card to transport
    }
    @Test fun vendorFileThroughSimulatedCard() {
        val (card,transport)=setup();val identity=CardFileProtection.identities(card).single()
        val result=CardFileProtection.decrypt(card,File(root,"vendor-certificate.asymmetric.p7m").readBytes(),identity,SimulatedCard.PIN.toCharArray())
        assertArrayEquals(File(root,"plain-1024.bin").readBytes(),result)
        assertEquals(1,transport.decryptAttempts)
        assertEquals(1,transport.plainLog.count { it=="SM:20" })
    }
    @Test fun wrongPINNeverRetries() {
        val (card,transport)=setup();val identity=CardFileProtection.identities(card).single()
        assertThrows(CardError.WrongPin::class.java) { CardFileProtection.decrypt(card,File(root,"vendor-certificate.asymmetric.p7m").readBytes(),identity,"999999".toCharArray()) }
        assertEquals(2,transport.attempts);assertEquals(0,transport.decryptAttempts)
        assertEquals(1,transport.plainLog.count { it=="SM:20" })
    }
    @Test fun missingCapabilityNeverSendsPIN() {
        val (card,transport)=setup();val identity=CardFileProtection.identities(card).single()
        transport.extraFiles["7002"]=byteArrayOf(0)
        assertThrows(CardError.CardChanged::class.java) {CardFileProtection.decrypt(card,File(root,"vendor-certificate.asymmetric.p7m").readBytes(),identity,SimulatedCard.PIN.toCharArray())}
        assertEquals(0,transport.decryptAttempts);assertEquals(0,transport.plainLog.count {it=="SM:20"})
    }
    @Test fun explicitPublicKeyPolicyKeepsCardAndPinBinding() {
        val (card,transport)=setup(signingOnly=true)
        assertTrue(CardFileProtection.identities(card).isEmpty())
        val identity=CardFileProtection.identities(card,CertificateRecipientPolicy.CARD_PUBLIC_KEY).single()
        assertEquals(CertificateRecipientPolicy.CARD_PUBLIC_KEY,identity.recipientPolicy)
        assertEquals(0,transport.plainLog.count {it=="SM:20"})
        val cert=java.security.cert.CertificateFactory.getInstance("X.509").generateCertificate(identity.certificate.inputStream()) as java.security.cert.X509Certificate
        val plain=byteArrayOf(1,0x80.toByte(),0,0,255.toByte())
        val envelope=CertificateFileProtection.encrypt(plain,cert,CertificateRecipientPolicy.CARD_PUBLIC_KEY)
        assertArrayEquals(plain,CardFileProtection.decrypt(card,envelope,identity,SimulatedCard.PIN.toCharArray()))
        assertEquals(1,transport.plainLog.count {it=="SM:20"});assertEquals(1,transport.decryptAttempts)
    }
}
