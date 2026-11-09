package md.moldsign.core

import org.junit.Assert.*
import org.junit.Test

class ExtendedSecureChannelTest {
    @Test fun independentExtendedVectors() {
        val fixture = MiniJson.parse(SpecFiles.read("spec/vectors/encryption/extended-sm.json"))
        for (vector in fixture.list("vectors")) {
            val channel = SecureChannel(fixture.hex("enc"),fixture.hex("mac"),fixture.hex("ssc"))
            assertArrayEquals(vector.hex("wrapped"),channel.wrap(vector.hex("command")))
        }
    }
    @Test fun malformedCommandsDoNotConsumeCounter() {
        for (command in listOf("002a80860001".decodeHex(), "002a808600000301020000".decodeHex(),
            "002a80860201".decodeHex(), "002a808600ffff".decodeHex() + ByteArray(65535))) {
            val channel = SecureChannel(ByteArray(32){1},ByteArray(32){2},ByteArray(16))
            assertThrows(IllegalArgumentException::class.java) { channel.wrap(command) }
            assertArrayEquals(ByteArray(16),channel.ssc)
        }
    }
}
