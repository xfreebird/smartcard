package md.moldsign.core.protection
import org.junit.Assert.*
import org.junit.Test

class CardEncryptionDirectoryTest {
    private fun w(tag:Int, bytes:ByteArray)=ProtectionASN1.wrap(tag,bytes)
    internal fun fixture(consent:Boolean=false,usage:Int=0x40,pinRef:Int=3,pinType:Int=1):Triple<ByteArray,ByteArray,ByteArray> {
        val common=w(0x30,w(12,"Encryption key".toByteArray())+w(4,byteArrayOf(1))+(if(consent)w(2,byteArrayOf(1)) else byteArrayOf()))
        val attrs=w(0x30,w(4,byteArrayOf(2))+w(3,byteArrayOf(6,usage.toByte()))+w(2,byteArrayOf(2)))
        val type=w(0xa1,w(0x30,w(0x30,w(4,byteArrayOf()))+w(2,byteArrayOf(8,0))))
        val key=w(0x30,common+attrs+type)
        val cert=w(0x30,w(0x30,byteArrayOf())+w(0x30,w(4,byteArrayOf(2)))+w(0xa1,w(0x30,w(0x30,w(4,byteArrayOf(0,2))))))
        val pin=w(0x30,w(0x30,byteArrayOf())+w(0x30,w(4,byteArrayOf(1)))+w(0xa1,w(0x30,w(3,byteArrayOf(0,8))+w(10,byteArrayOf(pinType.toByte()))+w(2,byteArrayOf(4))+w(2,byteArrayOf(8))+w(0x80,byteArrayOf(pinRef.toByte())))))
        return Triple(key,cert,pin)
    }
    @Test fun joinsEncryptionCapability() {
        val (key,cert,pin)=fixture()
        val result=EncryptionDirectory.keys(key+ByteArray(32),cert,pin)
        assertEquals(1,result.size);assertEquals(256,result.single().modulusBytes);assertEquals(2,result.single().certificateFile)
    }
    @Test fun rejectsSigningAndAmbiguousKeys() {
        for((key,cert,pin) in listOf(fixture(consent=true),fixture(usage=0x20),fixture(pinRef=4),fixture(pinType=0))) assertTrue(EncryptionDirectory.keys(key,cert,pin).isEmpty())
        val (key,cert,pin)=fixture()
        assertTrue(EncryptionDirectory.keys(key+key,cert,pin).isEmpty())
        assertTrue(EncryptionDirectory.keys(key,cert+cert,pin).isEmpty())
        assertTrue(EncryptionDirectory.keys(key,cert,byteArrayOf()).isEmpty())
        assertThrows(IllegalArgumentException::class.java) {EncryptionDirectory.keys(key+byteArrayOf(0,1),cert,pin)}
    }
    @Test fun supportsUtf8MetadataForNumericPin() {
        val (key,cert,pin)=fixture(pinType=2)
        assertEquals(1,EncryptionDirectory.keys(key,cert,pin).size)
    }
}
