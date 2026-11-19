package md.moldsign.core.protection

import md.moldsign.core.CosmoXCard
import md.moldsign.core.CardError
import java.security.MessageDigest
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.security.interfaces.RSAPublicKey

class CardEncryptionIdentity internal constructor(internal val key: EncryptionKey, certificate: ByteArray,
    val recipientPolicy: CertificateRecipientPolicy = CertificateRecipientPolicy.ENCRYPTION_CERTIFICATE) {
    private val der = certificate.copyOf()
    val certificate: ByteArray get() = der.copyOf()
    val pinLengths: IntRange get() = key.minimum..key.maximum
    val label: String get() = key.label
    val fingerprint: String = MessageDigest.getInstance("SHA-256").digest(der).joinToString("") { "%02x".format(it) }
}
internal data class EncryptionKey(val id: String,val label: String,val reference: Int,val modulusBytes: Int,
                                  val minimum: Int,val maximum: Int,val certificateFile: Int)

internal object EncryptionDirectory {
    private fun records(input: ByteArray): List<ProtectionASN1> {
        require(input.size <= 32768)
        val result = mutableListOf<ProtectionASN1>(); var position = 0
        while (position < input.size) {
            if (input[position] == 0.toByte()) { require(input.copyOfRange(position,input.size).all { it == 0.toByte() }); break }
            val start = position; require(position+2 <= input.size); position++
            val first = input[position++].toInt() and 255; var length = first.toLong()
            if (first >= 128) {
                val count = first and 127; require(count in 1..4 && position+count <= input.size); length=0
                repeat(count) { length=length*256+(input[position++].toInt() and 255) }
            }
            require(length <= input.size-position)
            position+=length.toInt(); result+=ProtectionASN1.parse(input.copyOfRange(start,position)); require(result.size<=128)
        }
        return result
    }
    private fun ProtectionASN1.integer(): Int {
        require(content.size in 1..3 && content[0].toInt() and 128 == 0)
        return content.fold(0) { n,b -> n*256+(b.toInt() and 255) }
    }
    private fun List<ProtectionASN1>.firstTag(tag: Int) = firstOrNull { it.tag == tag }
    fun keys(privateKeys: ByteArray,certificates: ByteArray,authentication: ByteArray): List<EncryptionKey> {
        val certs=records(certificates);val pins=records(authentication)
        val result=records(privateKeys).mapNotNull { record ->
            if(record.tag!=0x30 || record.children.size<3) return@mapNotNull null
            val fields=record.children
            if(fields[0].tag!=0x30 || fields[1].tag!=0x30) return@mapNotNull null
            val common=fields[0].children;val attrs=fields[1].children
            if(common.any { it.tag==2 && it.content.any { b -> b!=0.toByte() } }) return@mapNotNull null
            val auth=common.firstTag(4)?.content ?: return@mapNotNull null
            if(attrs.size<3 || attrs[0].tag!=4 || attrs[1].tag!=3 || attrs[1].content.size<2 || attrs[1].content[1].toInt() and 0x40==0) return@mapNotNull null
            val reference=attrs.drop(2).firstTag(2)?.integer() ?: return@mapNotNull null
            val type=fields.firstTag(0xa1)?.children?.firstOrNull() ?: return@mapNotNull null
            if(type.tag!=0x30 || type.children.size<2 || type.children[0].tag!=0x30 || type.children[0].children.firstOrNull()?.tag!=4 || type.children[1].tag!=2) return@mapNotNull null
            val bits=type.children[1].integer()
            if(reference !in 1..255 || bits !in listOf(2048,3072,4096,8192)) return@mapNotNull null
            fun matching(records: List<ProtectionASN1>,id: ByteArray) = records.filter { it.tag==0x30 && it.children.size>=3 && it.children[1].tag==0x30 && it.children[1].children.firstOrNull()?.let { a -> a.tag==4 && a.content.contentEquals(id) }==true }.singleOrNull()
            val cert=matching(certs,attrs[0].content) ?: return@mapNotNull null
            val certType=cert.children.firstTag(0xa1)?.children?.singleOrNull() ?: return@mapNotNull null
            val path=certType.children.firstOrNull() ?: return@mapNotNull null
            if(certType.tag!=0x30 || path.tag!=0x30 || path.children.size!=1 || path.children[0].tag!=4 || path.children[0].content.size!=2) return@mapNotNull null
            val pin=matching(pins,auth)?.children?.firstTag(0xa1)?.children?.singleOrNull()?.children ?: return@mapNotNull null
            // Digits have the same encoding in ASCII-numeric (1) and UTF-8 (2).
            // Decryption still accepts only numeric PINs and the known ref 03.
            if(pin.size<4 || pin[0].tag!=3 || pin[0].content.size<2 || pin[0].content[1].toInt() and 7!=0 || pin[1].tag!=10 || pin[1].integer() !in listOf(1,2) || pin[2].tag!=2 || pin[3].tag!=2 || pin.firstTag(0x80)?.integer()!=3) return@mapNotNull null
            val minimum=pin[2].integer();val maximum=pin.drop(4).firstTag(2)?.integer() ?: pin[3].integer()
            if(minimum<4 || maximum !in minimum..8) return@mapNotNull null
            val file=path.children[0].content
            EncryptionKey(attrs[0].content.joinToString("") { "%02x".format(it) },common.firstTag(12)?.content?.toString(Charsets.UTF_8) ?: "",
                reference,bits/8,minimum,maximum,(file[0].toInt() and 255)*256+(file[1].toInt() and 255))
        }
        return result.filter { key -> result.count { it.id==key.id || it.reference==key.reference }==1 }
    }
}

object CardFileProtection {
    private fun certificate(bytes: ByteArray) = CertificateFactory.getInstance("X.509").generateCertificate(bytes.inputStream()) as X509Certificate
    fun identities(card: CosmoXCard, policy: CertificateRecipientPolicy = CertificateRecipientPolicy.ENCRYPTION_CERTIFICATE): List<CardEncryptionIdentity> {
        val auth=read(card,0x7001);val keys=read(card,0x7002);val certs=read(card,0x7005)
        return EncryptionDirectory.keys(keys,certs,auth).mapNotNull { key ->
            val bytes=read(card,key.certificateFile)
            val cert=certificate(bytes)
            val rsa=runCatching { CertificateFileProtection.recipientKey(cert,policy) }.getOrNull()
            if(rsa==null || (rsa.modulus.bitLength()+7)/8!=key.modulusBytes) null
            else CardEncryptionIdentity(key,cert.encoded,policy)
        }
    }
    fun decrypt(card: CosmoXCard,envelope: ByteArray,identity: CardEncryptionIdentity,pin: CharArray): ByteArray =
        CertificateFileProtection.decryptWithPolicy(envelope,certificate(identity.certificate),identity.recipientPolicy) { wrapped ->
            require(wrapped.size==identity.key.modulusBytes)
            if(identities(card,identity.recipientPolicy).none { it.fingerprint==identity.fingerprint && it.key==identity.key }) throw CardError.CardChanged(MessageDigest.getInstance("SHA-1").digest(identity.certificate).joinToString("") { "%02x".format(it) }, "")
            require(pin.size in identity.key.minimum..identity.key.maximum && pin.all { it in '0'..'9' })
            card.selectMF();card.selectGenericADF();card.verifyPin(pin)
            val mse=card.smTransmit(byteArrayOf(0,0x22,0x41,0xb8.toByte(),6,0x80.toByte(),1,0x1a,0x84.toByte(),1,(identity.key.reference or 0x80).toByte()))
            check(mse.sw)
            val payload=byteArrayOf(0x81.toByte())+wrapped
            val response=card.smTransmit(byteArrayOf(0,0x2a,0x80.toByte(),0x86.toByte(),0,(payload.size ushr 8).toByte(),payload.size.toByte())+payload+byteArrayOf(0,0))
            check(response.sw);require(response.data.size==16);response.data
        }
    private fun check(status: Int) { if(status!=0x9000) throw CardError.fromStatusWord(status,"File decryption") }
    private fun read(card: CosmoXCard,file: Int): ByteArray {
        card.selectMF();card.selectGenericADF()
        check(card.smTransmit(byteArrayOf(0,0xa4.toByte(),2,4,2,(file ushr 8).toByte(),file.toByte(),0)).sw)
        val out=java.io.ByteArrayOutputStream()
        while(out.size()<32768) {
            val offset=out.size();val response=card.smTransmit(byteArrayOf(0,0xb0.toByte(),(offset ushr 8).toByte(),offset.toByte(),0x80.toByte()))
            if(response.sw==0x6b00 && out.size()>0) return out.toByteArray()
            if(response.sw!=0x9000 && response.sw!=0x6282) check(response.sw)
            require(response.data.size<=128);out.write(response.data)
            if(response.data.size<128 || response.sw==0x6282) return out.toByteArray()
        }
        error("Card metadata exceeds limit")
    }
}
