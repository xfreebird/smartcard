package md.moldsign.core.protection
import java.security.MessageDigest
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec

internal object LegacyPasswordProtection {
    private fun hex(s:String)=s.chunked(2).map{it.toInt(16).toByte()}.toByteArray()
    fun decrypt(envelope:ByteArray,password:CharArray):ByteArray {
        require(password.size<2048)
        val root=ProtectionASN1.parse(envelope);val outer=root.requireTag(0x30)
        val body=if(outer.firstOrNull()?.tag==2)root.requireTag(0x30,2) else {
            require(outer.size==2 && outer[0].tag==6 && outer[0].content.contentEquals(hex("2a864886f70d010706")))
            outer[1].requireTag(0xa0,1)[0].requireTag(0x30,2)
        }
        require(body[0].tag==2 && body[0].content.contentEquals(byteArrayOf(0)))
        val content=body[1].requireTag(0x30,3);val algorithm=content[1].requireTag(0x30,2)
        require(content[0].tag==6 && content[0].content.contentEquals(hex("2a864886f70d010701")) && algorithm[0].tag==6)
        val kind=when(algorithm[0].content.joinToString(""){"%02x".format(it)}) {
            "2a864886f70d010c0103"->1;"2a864886f70d010503"->2;"2a864886f70d010c0106"->3;else->error("Unsupported legacy encryption")
        }
        val params=algorithm[1].requireTag(0x30,2)
        require(params[0].tag==4 && params[0].content.size in 1..64 && params[1].tag==2 && params[1].content.size in 1..3 && params[1].content[0].toInt() and 128==0)
        val iterations=params[1].content.fold(0){n,b->n*256+(b.toInt() and 255)};require(iterations in 1..1_000_000)
        val ciphertext=content[2].octets(true);require(ciphertext.isNotEmpty() && ciphertext.size%8==0)
        val salt=params[0].content
        val key:ByteArray;val iv:ByteArray
        if(kind==2) {
            require(salt.size==8 && password.all{it.code<=127})
            val bytes=ByteArray(password.size){password[it].code.toByte()}+salt
            val digest=MessageDigest.getInstance("MD5");var hash=digest.digest(bytes);bytes.fill(0)
            repeat(iterations-1){val next=digest.digest(hash);hash.fill(0);hash=next}
            key=hash.copyOfRange(0,8);iv=hash.copyOfRange(8,16);hash.fill(0)
        } else {
            key=derive(password,salt,iterations,1,if(kind==1)24 else 5)
            iv=derive(password,salt,iterations,2,8)
        }
        try {
            if(kind==3)return LegacyRC2.decryptCBC(ciphertext,key,iv)
            val name=if(kind==1)"DESede" else "DES"
            val cipher=Cipher.getInstance("$name/CBC/PKCS5Padding")
            cipher.init(Cipher.DECRYPT_MODE,SecretKeySpec(key,name),IvParameterSpec(iv))
            return cipher.doFinal(ciphertext)
        } finally {key.fill(0);iv.fill(0)}
    }
    private fun derive(password:CharArray,salt:ByteArray,iterations:Int,id:Int,length:Int):ByteArray {
        val p=if(password.isEmpty())byteArrayOf() else ByteArray(password.size*2+2).also{bytes->password.forEachIndexed{i,c->bytes[i*2]=(c.code ushr 8).toByte();bytes[i*2+1]=c.code.toByte()}}
        val sn=64*((salt.size+63)/64);val pn=if(p.isEmpty())0 else 64*((p.size+63)/64)
        val input=ByteArray(64+sn+pn){i->if(i<64)id.toByte() else if(i<64+sn)salt[(i-64)%salt.size] else p[(i-64-sn)%p.size]}
        val result=ByteArray(length);val digest=MessageDigest.getInstance("SHA-1");var offset=0
        try {
            while(offset<length) {
                var hash=digest.digest(input)
                repeat(iterations-1){val next=digest.digest(hash);hash.fill(0);hash=next}
                val count=minOf(20,length-offset);hash.copyInto(result,offset,0,count);offset+=count
                if(offset<length)for(chunk in 64 until input.size step 64) {
                    var carry=1
                    for(j in 63 downTo 0){val sum=(input[chunk+j].toInt() and 255)+(hash[j%20].toInt() and 255)+carry;input[chunk+j]=sum.toByte();carry=sum ushr 8}
                }
                hash.fill(0)
            }
            return result
        } finally{p.fill(0);input.fill(0)}
    }
}
