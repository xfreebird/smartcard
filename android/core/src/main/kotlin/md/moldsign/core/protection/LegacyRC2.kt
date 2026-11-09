package md.moldsign.core.protection

/** Read-only RC2 compatibility (RFC 2268). Android does not ship an RC2 Cipher provider.
 * https://www.rfc-editor.org/rfc/rfc2268.html — used only for old 40-bit MoldSign files. */
internal object LegacyRC2 {
    private val pi=(
        "d978f9c419ddb5ed28e9fd794aa0d89d"+
        "c67e37832b76538e624c6488448bfba2"+
        "179a59f587b34f1361456d8d09817d32"+
        "bd8f40eb86b77b0bf09521225c6b4e82"+
        "54d66593ce60b21c7356c014a78cf1dc"+
        "1275ca1f3bbee4d1423dd430a33cb626"+
        "6fbf0eda4669075727f21d9bbc944303"+
        "f811c7f690ef3ee706c3d52fc8661ed7"+
        "08e8eade8052eef784aa72ac354d6a2a"+
        "961ad2715a1549744b9fd05e0418a4ec"+
        "c2e0416e0f51cbcc2491af50a1f47039"+
        "997c3a8523b8b47afc02365b25559731"+
        "2d5dfa98e38a92ae05df2910676cbac9"+
        "d300e6cfe19ea82c6316013f58e289a9"+
        "0d38341bab33ffb0bb480c5fb9b1cd2e"+
        "c5f3db47e5a59c770aa62068fe7fc1ad").chunked(2).map{it.toInt(16)}.toIntArray()
    private fun expand(key:ByteArray,bits:Int):IntArray {
        require(key.size in 1..128 && bits in 1..1024)
        val bytes=IntArray(128);key.forEachIndexed{i,b->bytes[i]=b.toInt() and 255}
        for(i in key.size..127)bytes[i]=pi[(bytes[i-1]+bytes[i-key.size]) and 255]
        val count=(bits+7)/8;val mask=255 ushr (8*count-bits)
        bytes[128-count]=pi[bytes[128-count] and mask]
        for(i in 127-count downTo 0)bytes[i]=pi[bytes[i+1] xor bytes[i+count]]
        return IntArray(64){bytes[it*2]+(bytes[it*2+1] shl 8)}.also{bytes.fill(0)}
    }
    private fun block(input:ByteArray,offset:Int,key:IntArray):ByteArray {
        val r=IntArray(4){(input[offset+it*2].toInt() and 255)+((input[offset+it*2+1].toInt() and 255) shl 8)}
        val shifts=intArrayOf(1,2,3,5);var j=63
        for(round in 15 downTo 0) {
            for(i in 3 downTo 0) {
                val value=r[i];val shift=shifts[i]
                val rotated=((value ushr shift) or (value shl (16-shift))) and 65535
                val previous=r[(i+3)%4]
                r[i]=(rotated-key[j--]-(previous and r[(i+2)%4])-(previous.inv() and r[(i+1)%4])) and 65535
            }
            if(round==11 || round==5)for(i in 3 downTo 0)r[i]=(r[i]-key[r[(i+3)%4] and 63]) and 65535
        }
        return ByteArray(8){if(it%2==0)r[it/2].toByte() else (r[it/2] ushr 8).toByte()}.also{r.fill(0)}
    }
    internal fun decryptBlock(input:ByteArray,key:ByteArray,bits:Int):ByteArray {
        require(input.size==8);val expanded=expand(key,bits)
        try{return block(input,0,expanded)}finally{expanded.fill(0)}
    }
    fun decryptCBC(input:ByteArray,key:ByteArray,iv:ByteArray):ByteArray {
        require(key.size==5 && iv.size==8 && input.isNotEmpty() && input.size%8==0)
        val expanded=expand(key,40);val output=ByteArray(input.size)
        try {
            for(offset in input.indices step 8) {
                val plain=block(input,offset,expanded)
                for(i in 0..7)output[offset+i]=(plain[i].toInt() xor (if(offset==0)iv[i] else input[offset-8+i]).toInt()).toByte()
                plain.fill(0)
            }
            val padding=output.last().toInt() and 255
            require(padding in 1..8 && (1..padding).all{output[output.size-it].toInt() and 255==padding}){"Unable to decrypt"}
            return output.copyOf(output.size-padding)
        }finally{expanded.fill(0);output.fill(0)}
    }
}
