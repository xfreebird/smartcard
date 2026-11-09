package md.moldsign.core.protection

import org.junit.Assert.*
import org.junit.Test
import java.io.File

class PasswordFileProtectionTest {
    private val password = "Test-șț-🔐-2026".toCharArray()
    private val root = File(System.getProperty("moldsign.repoRoot"), "spec/vectors/encryption")
    @Test fun vendorCompatibility() {
        for (length in listOf(0,1,15,16,17,1024)) {
            val plain = File(root, "plain-$length.bin").readBytes()
            for (bits in listOf(128,192,256)) {
                assertArrayEquals(plain, PasswordFileProtection.decrypt(File(root, "vendor-$bits-$length.symmetric.p7m").readBytes(), password))
            }
            val encrypted = PasswordFileProtection.encrypt(plain, password)
            assertArrayEquals(plain, PasswordFileProtection.decrypt(encrypted, password))
            System.getenv("MSIGN_ENCRYPTION_ORACLE_OUTPUT")?.let { File(it, "native-$length.symmetric.p7m").writeBytes(encrypted) }
        }
    }
    @Test fun legacyVendorFiles() {
        for(algorithm in listOf("3_KeyTripleDES_CBC","DES_CBC","RC2_CBC")) for(length in listOf(0,1,15,16,17,1024)) {
            assertArrayEquals(File(root,"plain-$length.bin").readBytes(),PasswordFileProtection.decrypt(File(root,"vendor-legacy-$algorithm-$length.p7m").readBytes(),"Legacy-Test-2026".toCharArray()))
        }
    }
    @Test fun invalidInputs() {
        val vendor = File(root,"vendor-256-1024.symmetric.p7m").readBytes()
        runCatching { PasswordFileProtection.decrypt(vendor, "wrong".toCharArray()) }.getOrNull()?.let {
            assertFalse(it.contentEquals(File(root,"plain-1024.bin").readBytes()))
        }
        for (length in listOf(0,31,95,96,111,113)) assertThrows(IllegalArgumentException::class.java) { PasswordFileProtection.decrypt(vendor.copyOf(length),password) }
        vendor[32] = (vendor[32].toInt() xor 1).toByte()
        assertThrows(IllegalArgumentException::class.java) { PasswordFileProtection.decrypt(vendor,password) }
    }
}
