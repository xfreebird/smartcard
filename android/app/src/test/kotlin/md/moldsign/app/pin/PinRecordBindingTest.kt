package md.moldsign.app.pin

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertThrows
import org.junit.Test
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

class PinRecordBindingTest {
    @Test fun encryptedRecordCannotMoveToAnotherCertificate() {
        val key = SecretKeySpec(ByteArray(32) { it.toByte() }, "AES")
        val plain = "fictional test value".toByteArray()
        val encrypt = Cipher.getInstance("AES/GCM/NoPadding").apply {
            init(Cipher.ENCRYPT_MODE, key)
            updateAAD(pinRecordBinding("card-a"))
        }
        val encrypted = encrypt.doFinal(plain)
        fun decrypt(cert: String) = Cipher.getInstance("AES/GCM/NoPadding").run {
            init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, encrypt.iv))
            updateAAD(pinRecordBinding(cert))
            doFinal(encrypted)
        }
        assertArrayEquals(plain, decrypt("card-a"))
        assertThrows(AEADBadTagException::class.java) { decrypt("card-b") }
    }
}
