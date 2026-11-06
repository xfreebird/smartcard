package md.moldsign.core

import java.nio.charset.StandardCharsets.ISO_8859_1
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.util.Locale

/** Fractions of the displayed CropBox from top-left; page is zero-based. Null means invisible. */
data class PdfStampPlacement(val page: Int = 0, val allPages: Boolean = false, val x: Double = .06,
    val y: Double = .72, val width: Double = .40, val height: Double = .113, val documentSHA256: String? = null) {
    fun resized(corner: Int, dx: Double, dy: Double): PdfStampPlacement {
        if (corner !in 0..3 || !dx.isFinite() || !dy.isFinite() || width <= 0 || height <= 0) return this
        val right = corner % 2 == 1; val bottom = corner >= 2; val ratio = height / width
        val horizontal = if (right) dx else -dx; val vertical = (if (bottom) dy else -dy) / ratio
        val delta = if (kotlin.math.abs(horizontal) >= kotlin.math.abs(vertical)) horizontal else vertical
        val limit = minOf(if (right) 1-x else x+width, (if (bottom) 1-y else y+height) / ratio)
        val w = minOf(limit, maxOf(minOf(.1,limit),width+delta)); val h = w*ratio
        return copy(x=if(right) x else x+width-w,y=if(bottom) y else y+height-h,width=w,height=h)
    }
    fun validate() {
        if (page < 0 || listOf(x,y,width,height).any { !it.isFinite() } || x < 0 || y < 0 || width <= 0 || height <= 0 ||
            x + width > 1.000001 || y + height > 1.000001) throw CardError.Format("The signature stamp must fit inside the page")
    }
}

sealed class PdfStampDecision {
    data object Cancel : PdfStampDecision()
    data class Proceed(val placement: PdfStampPlacement?) : PdfStampDecision()
}

/** Syntax reader for the uncompressed objects supported by the incremental signer. No source rewriting. */
internal object StampPdf {
    private fun fail(): Nothing = throw CardError.Format("This PDF cannot be stamped safely (unsupported page structure)")
    private fun tokens(s: String): List<String> {
        val out = mutableListOf<String>(); var i = 0
        while (i < s.length) {
            if (s[i].isWhitespace()) { i++; continue }
            if (s[i] == '%') { while (i < s.length && s[i] != '\n' && s[i] != '\r') i++; continue }
            val start = i
            when {
                s[i] == '(' -> { var depth = 1; i++
                    while (i < s.length && depth > 0) {
                        if (s[i] == '\\') { i += minOf(2, s.length-i); continue }
                        if (s[i] == '(') depth++; if (s[i] == ')') depth--; i++
                    }
                }
                s[i] == '<' && i+1 < s.length && s[i+1] != '<' -> { i++; while (i < s.length && s[i] != '>') i++; if (i < s.length) i++ }
                s.startsWith("<<", i) || s.startsWith(">>", i) -> i += 2
                s[i] in "[]<>" -> i++
                else -> { i++; while (i < s.length && !s[i].isWhitespace() && s[i] !in "/[]<>()%") i++ }
            }
            out += s.substring(start,i)
        }
        return out
    }
    private fun entries(dict: String): List<Pair<String,String>> {
        val t = tokens(dict); if (t.firstOrNull() != "<<") fail()
        val out = mutableListOf<Pair<String,String>>(); var i = 1
        while (i < t.size && t[i] != ">>") {
            val key = t[i++]; val start = i
            if (!key.startsWith('/') || key.contains('#') || out.any { it.first == key } || i >= t.size) fail()
            if (t[i] == "<<" || t[i] == "[") {
                var depth = 0
                do { if (t[i] == "<<" || t[i] == "[") depth++; if (t[i] == ">>" || t[i] == "]") depth--; i++ } while (i < t.size && depth > 0)
                if (depth != 0) fail()
            } else if (i+2 < t.size && t[i].toIntOrNull() != null && t[i+1].toIntOrNull() != null && t[i+2] == "R") i += 3
            else i++
            out += key to t.subList(start,i).joinToString(" ")
        }
        if (i != t.size-1 || t.last() != ">>") fail()
        return out
    }
    private fun value(dict: String, key: String): String? = entries(dict).filter { it.first == key }.let { if (it.size > 1) fail(); it.firstOrNull()?.second }
    private fun set(dict: String, key: String, value: String) = "<< " + (entries(dict).filter { it.first != key } + (key to value)).joinToString(" ") { "${it.first} ${it.second}" } + " >>"
    private fun ref(value: String): Int { val t=tokens(value); if (t.size != 3 || t[1] != "0" || t[2] != "R") fail(); return t[0].toIntOrNull()?.takeIf { it > 0 } ?: fail() }
    private fun refs(value: String): List<Int> { val t=tokens(value); if (t.firstOrNull() != "[" || t.lastOrNull() != "]" || (t.size-2)%3 != 0) fail(); return t.subList(1,t.size-1).chunked(3).map { ref(it.joinToString(" ")) } }
    private fun objText(text: String,n: Int): String {
        val m = Regex("(?<!\\d)$n\\s+0\\s+obj\\b").findAll(text).lastOrNull() ?: fail()
        val end=text.indexOf("endobj",m.range.last+1); if(end < 0) fail(); return text.substring(m.range.last+1,end).trim()
    }
    private data class Page(val number: Int,val dict: String,val box: List<Double>,val rotation: Int)
    private fun pages(text: String,catalog: String): List<Page> {
        if (text.contains("/Encrypt")) fail()
        val visited=mutableSetOf<Int>(); val out=mutableListOf<Page>()
        fun walk(n: Int,inherited: Map<String,String>,depth: Int) {
            if(depth >= 100 || !visited.add(n)) fail()
            val dict=objText(text,n); val props=inherited.toMutableMap()
            listOf("/MediaBox","/CropBox","/Rotate","/UserUnit").forEach { k -> value(dict,k)?.let { props[k]=it } }
            if(value(dict,"/Type") == "/Pages") refs(value(dict,"/Kids") ?: fail()).forEach { walk(it,props,depth+1) }
            else {
                if(value(dict,"/Type") != "/Page") fail()
                var box=props["/CropBox"] ?: props["/MediaBox"] ?: fail()
                if(!box.startsWith('[')) box=objText(text,ref(box))
                fun rectangle(input: String): List<Double> {
                    val raw=if(input.startsWith('[')) input else objText(text,ref(input))
                    val values=tokens(raw)
                    if(values.size != 6 || values.first() != "[" || values.last() != "]") fail()
                    val parsed=values.drop(1).dropLast(1).map { it.toDoubleOrNull() ?: fail() }
                    if(parsed.any { !it.isFinite() } || parsed[2] <= parsed[0] || parsed[3] <= parsed[1]) fail()
                    return parsed
                }
                var numbers=rectangle(box)
                props["/MediaBox"]?.let { media -> val b=rectangle(media); numbers=listOf(maxOf(numbers[0],b[0]),maxOf(numbers[1],b[1]),minOf(numbers[2],b[2]),minOf(numbers[3],b[3])) }
                val rotation=props["/Rotate"]?.let { it.toIntOrNull() ?: fail() } ?: 0
                if(numbers[2] <= numbers[0] || numbers[3] <= numbers[1] || rotation%90 != 0 || (props["/UserUnit"] ?: "1").toDoubleOrNull() != 1.0) fail()
                out += Page(n,dict,numbers,(rotation%360+360)%360)
            }
        }
        walk(ref(value(catalog,"/Pages") ?: fail()),emptyMap(),0)
        if(out.isEmpty()) fail(); return out
    }
    fun canApply(placement: PdfStampPlacement, data: ByteArray): Boolean = runCatching {
        val text = data.toString(ISO_8859_1)
        val root = Regex("""/Root\s+(\d+)\s+0\s+R\b""").findAll(text).lastOrNull()?.groupValues?.get(1)?.toIntOrNull() ?: return@runCatching false
        placement.page in pages(text,objText(text,root)).indices
    }.getOrDefault(false)
    private fun num(n: Double)=String.format(Locale.ROOT,"%.5f",n)
    private fun stream(data: ByteArray,extra: String=""): String {
        val hex=data.toHex()+">"; return "<< /Length ${hex.length} /Filter /ASCIIHexDecode $extra >>\nstream\n$hex\nendstream"
    }
    data class Appearance(val field: String,val chunks: List<String>,val next: Int)
    fun appearance(text: String,catalog: String,field: Int,signature: Int,first: Int,name: String,
                   placement: PdfStampPlacement,holder: String,date: ZonedDateTime): Appearance {
        placement.validate()
        if(value(catalog,"/Perms") != null) throw CardError.Format("A certified PDF cannot receive additional stamps")
        value(catalog,"/AcroForm")?.let { ref(it) }
        val pages=pages(text,catalog); if(placement.page !in pages.indices) fail()
        val primary=pages[placement.page]
        val selected=listOf(primary)+(if(placement.allPages) pages.filter { it.number != primary.number } else emptyList())
        fun resource(file: String)=StampPdf::class.java.getResourceAsStream("/md/moldsign/core/pdfstamp/$file")?.use { it.readBytes() } ?: error("Missing stamp font")
        val metrics=resource("metrics.txt").toString(Charsets.UTF_8).lineSequence().filter { it.isNotBlank() }.associate { line -> val v=line.split(' ').map(String::toInt); v[0] to (v[1] to v[2]) }
        val lines=listOf("Digitally signed by $holder", "Date: ${date.format(DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm:ss z",Locale.ROOT))}","Reason: MoldSign Signature","Location: Moldova","MOLDOVA EUROPEANĂ","Signed with eSemnBun")
        val used=sortedMapOf<Int,Pair<Int,Int>>(); val content=StringBuilder("q 0.65 G 0.5 w 0.5 10 174 21 re S 0 g\n")
        lines.forEachIndexed { index,line ->
            var width=0; val hex=StringBuilder()
            line.codePoints().forEach { scalar -> val (gid,advance)=metrics[scalar] ?: throw CardError.Format("The signature font cannot display a character in the signer name"); used[gid]=scalar to advance; width+=advance; hex.append(String.format(Locale.ROOT,"%04X",gid)) }
            val size=minOf(if(index==5) 7.0 else 13.0,228000.0/maxOf(width,1))
            content.append("BT /F ${num(size)} Tf 1 0 0 1 ${if(index==4) 5 else 0} ${listOf(82,67,52,37,16,2)[index]} Tm <$hex> Tj ET\n")
        }
        content.append("Q")
        val mappings=used.entries.map { (gid,v) -> "<${String.format(Locale.ROOT,"%04X",gid)}> <${String(Character.toChars(v.first)).toByteArray(Charsets.UTF_16BE).toHex()}>" }
        val sections=mappings.chunked(100).joinToString("\n") { "${it.size} beginbfchar\n"+it.joinToString("\n")+"\nendbfchar\n" }
        val cmap="/CIDInit /ProcSet findresource begin 12 dict begin begincmap /CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def /CMapName /StampUnicode def /CMapType 2 def 1 begincodespacerange <0000> <FFFF> endcodespacerange\n"+sections+"endcmap CMapName currentdict /CMap defineresource pop end end"
        val base=first; var next=first+5
        fun obj(n: Int,body: String)="$n 0 obj\n$body\nendobj\n"
        val widths=used.entries.joinToString(" ") { "${it.key} [${it.value.second}]" }; val font=resource("LiberationSerif-Regular.ttf")
        val descriptor="<< /Type /FontDescriptor /FontName /LiberationSerif-Regular /Flags 34 /FontBBox [-1000 -1000 2000 2000] /ItalicAngle 0 /Ascent 891 /Descent -216 /CapHeight 655 /StemV 80 /FontFile2 ${base+1} 0 R >>"
        val descendant="<< /Type /Font /Subtype /CIDFontType2 /BaseFont /LiberationSerif-Regular /CIDSystemInfo << /Registry (Adobe) /Ordering (Identity) /Supplement 0 >> /CIDToGIDMap /Identity /W [$widths] /FontDescriptor ${base+4} 0 R >>"
        val chunks=mutableListOf(obj(base,"<< /Type /Font /Subtype /Type0 /BaseFont /LiberationSerif-Regular /Encoding /Identity-H /DescendantFonts [${base+3} 0 R] /ToUnicode ${base+2} 0 R >>"),obj(base+1,stream(font,"/Length1 ${font.size}")),obj(base+2,stream(cmap.toByteArray(ISO_8859_1))),obj(base+3,descendant),obj(base+4,descriptor))
        val kids=mutableListOf<Int>(); var destination=""
        selected.forEach { page ->
            val widget=next; val ap=next+1; next+=2; val isPrimary=page.number==primary.number; if(isPrimary) kids+=widget
            val b=page.box; val w=b[2]-b[0]; val h=b[3]-b[1]
            fun point(u: Double,v: Double): Pair<Double,Double> = when(page.rotation) { 90 -> b[0]+v*w to b[1]+u*h; 180 -> b[0]+(1-u)*w to b[1]+v*h; 270 -> b[0]+(1-v)*w to b[1]+(1-u)*h; else -> b[0]+u*w to b[1]+(1-v)*h }
            val a=point(placement.x,placement.y); val z=point(placement.x+placement.width,placement.y+placement.height)
            val rect=listOf(minOf(a.first,z.first),minOf(a.second,z.second),maxOf(a.first,z.first),maxOf(a.second,z.second)).joinToString(" ",transform=::num)
            val matrix=when(page.rotation) { 90 -> "0 1 -1 0 96 0"; 180 -> "-1 0 0 -1 240 96"; 270 -> "0 -1 1 0 0 240"; else -> "1 0 0 1 0 0" }
            val added=mutableListOf(widget)
            if(isPrimary) {
                destination="[${page.number} 0 R /FitR $rect]"
                chunks+=obj(widget,"<< /Type /Annot /Subtype /Widget /Parent $field 0 R /P ${page.number} 0 R /Rect [$rect] /F 4 /AP << /N $ap 0 R >> >>")
            } else {
                chunks+=obj(widget,"<< /Type /Annot /Subtype /Stamp /P ${page.number} 0 R /Rect [$rect] /F 4 /AP << /N $ap 0 R >> >>")
                added+=next
                chunks+=obj(next,"<< /Type /Annot /Subtype /Link /P ${page.number} 0 R /Rect [$rect] /Border [0 0 0] /Dest $destination >>")
                next++
            }
            chunks+=obj(ap,stream(content.toString().toByteArray(ISO_8859_1),"/Type /XObject /Subtype /Form /BBox [0 0 240 96] /Matrix [$matrix] /Resources << /Font << /F $base 0 R >> >>"))
            var annots=value(page.dict,"/Annots") ?: "[]"; if(!annots.startsWith('[')) annots=objText(text,ref(annots))
            chunks+=obj(page.number,set(page.dict,"/Annots","["+(refs(annots)+added).joinToString(" ") { "$it 0 R" }+"]"))
        }
        return Appearance(obj(field,"<< /FT /Sig /T ($name) /V $signature 0 R /Kids ["+kids.joinToString(" ") { "$it 0 R" }+"] >>"),chunks,next)
    }
}
