package md.moldsign.core

import org.junit.Assert.*
import org.junit.Test

class SecureResponseValidationTest {
    private val key = ByteArray(32) { it.toByte() }
    private val status = bytesOf(0x99, 2, 0x90, 0)
    private fun channel() = SecureChannel(key, key, ByteArray(16))
    private fun authenticated(body: ByteArray, outer: ByteArray = bytesOf(0x90, 0)): ByteArray {
        val ssc = ByteArray(16).also { it[15] = 1 }
        return body + SecureChannel.tlv(0x8E, Cmac.aesCmac(key, Iso9797.pad(ssc + body)).copyOf(8)) + outer
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
    @Test fun mirroredEofPreservesAuthenticatedFinalChunk() {
        val ssc = ByteArray(16).also { it[15] = 1 }
        val aes = Aes(key)
        val payload = bytesOf(0x30, 0x80, 0, 0)
        val encrypted = aes.cbcEncrypt(Iso9797.pad(payload), aes.ecbEncryptBlock(ssc))
        val body = SecureChannel.tlv(0x87, bytesOf(1) + encrypted) + bytesOf(0x99, 2, 0x62, 0x82)
        val channel = channel()
        val result = channel.unwrap(authenticated(body, bytesOf(0x62, 0x82)))
        assertEquals(0x6282,result.sw)
        assertArrayEquals(payload,result.data)
        assertEquals(1,channel.ssc.last().toInt())
    }
    @Test fun mirroredEofCannotBypassAuthentication() {
        val eof = bytesOf(0x99, 2, 0x62, 0x82)
        val tampered = authenticated(eof, bytesOf(0x62, 0x82)).also { it[it.size-3] = (it[it.size-3].toInt() xor 1).toByte() }
        for(response in listOf(tampered, eof + bytesOf(0x62, 0x82), authenticated(status,bytesOf(0x62,0x82)))) {
            assertThrows(CardError.SmOutOfSync::class.java) { channel().unwrap(response) }
        }
    }
    @Test fun mirroredErrorIsAuthenticatedAndReturnedToCaller() {
        val result = channel().unwrap(authenticated(bytesOf(0x99,2,0x6b,0),bytesOf(0x6b,0)))
        assertEquals(0x6b00,result.sw)
        assertTrue(result.data.isEmpty())
    }
}
