package md.moldsign.core

import org.junit.Assert.*
import org.junit.Test

class SecureResponseValidationTest {
    private val key = ByteArray(32) { it.toByte() }
    private val status = bytesOf(0x99, 2, 0x90, 0)
    private fun channel() = SecureChannel(key, key, ByteArray(16))
    private fun authenticated(body: ByteArray): ByteArray {
        val ssc = ByteArray(16).also { it[15] = 1 }
        return body + SecureChannel.tlv(0x8E, Cmac.aesCmac(key, Iso9797.pad(ssc + body)).copyOf(8)) + bytesOf(0x90, 0)
    }
    @Test fun validStatusOnlyResponseIsAuthenticated() { assertEquals(0x9000, channel().unwrap(authenticated(status)).sw) }
    @Test fun bareSuccessIsRejected() { assertThrows(CardError.SmOutOfSync::class.java) { channel().unwrap(bytesOf(0x90, 0)) } }
    @Test fun missingMacIsRejected() { assertThrows(CardError.SmOutOfSync::class.java) { channel().unwrap(status + bytesOf(0x90, 0)) } }
    @Test fun missingStatusIsRejected() { assertThrows(CardError.SmOutOfSync::class.java) { channel().unwrap(authenticated(ByteArray(0))) } }
    @Test fun duplicateStatusIsRejected() { assertThrows(CardError.SmOutOfSync::class.java) { channel().unwrap(authenticated(status + status)) } }
    @Test fun modifiedMacIsRejected() {
        val response = authenticated(status).also { it[8] = (it[8].toInt() xor 1).toByte() }
        assertThrows(CardError.SmOutOfSync::class.java) { channel().unwrap(response) }
    }
    @Test fun trailingDataIsRejected() {
        val response = authenticated(status).dropLast(2).toByteArray() + bytesOf(0x99, 0, 0x90, 0)
        assertThrows(CardError.SmOutOfSync::class.java) { channel().unwrap(response) }
    }
    @Test fun unprotectedErrorStillConsumesOneCounter() {
        val channel = channel()
        assertEquals(0x63C2, channel.unwrap(bytesOf(0x63, 0xC2)).sw)
        assertEquals(1, channel.ssc.last().toInt())
    }
}
