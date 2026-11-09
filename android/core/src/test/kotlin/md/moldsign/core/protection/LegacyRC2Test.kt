package md.moldsign.core.protection
import org.junit.Assert.*
import org.junit.Test

class LegacyRC2Test {
    private fun hex(s:String)=s.chunked(2).map{it.toInt(16).toByte()}.toByteArray()
    @Test fun rfc2268Vectors() {
        val vectors=listOf(
            listOf("0000000000000000","63","0000000000000000","ebb773f993278eff"),
            listOf("ffffffffffffffff","64","ffffffffffffffff","278b27e42e2f0d49"),
            listOf("3000000000000000","64","1000000000000001","30649edf9be7d2c2"),
            listOf("88","64","0000000000000000","61a8a244adacccf0"),
            listOf("88bca90e90875a","64","0000000000000000","6ccf4308974c267f"),
            listOf("88bca90e90875a7f0f79c384627bafb2","64","0000000000000000","1a807d272bbe5db1"),
            listOf("88bca90e90875a7f0f79c384627bafb2","128","0000000000000000","2269552ab0f85ca6"),
            listOf("88bca90e90875a7f0f79c384627bafb216f80a6f85920584c42fceb0be255daf1e","129","0000000000000000","5b78d3a43dfff1f1")
        )
        for(v in vectors)assertArrayEquals(hex(v[2]),LegacyRC2.decryptBlock(hex(v[3]),hex(v[0]),v[1].toInt()))
    }
}
