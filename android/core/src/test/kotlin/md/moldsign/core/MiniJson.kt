package md.moldsign.core

import java.io.File

/**
 * Minimal JSON reader for the vector files (objects, arrays, strings, numbers, booleans, null).
 * Avoids a test dependency: org.json is Android-only and nothing else is needed.
 */
internal class MiniJson private constructor(private val s: String) {
    private var i = 0

    companion object {
        fun parse(text: String): Any? = MiniJson(text).run {
            val v = value()
            ws()
            check(i == s.length) { "Trailing data at $i" }
            v
        }
    }

    private fun ws() {
        while (i < s.length && s[i].isWhitespace()) i++
    }

    private fun value(): Any? {
        ws()
        check(i < s.length) { "Unexpected end of JSON" }
        return when (val c = s[i]) {
            '{' -> obj()
            '[' -> arr()
            '"' -> str()
            't' -> literal("true", true)
            'f' -> literal("false", false)
            'n' -> literal("null", null)
            else -> if (c == '-' || c.isDigit()) num() else error("Unexpected '$c' at $i")
        }
    }

    private fun literal(word: String, v: Any?): Any? {
        check(s.startsWith(word, i)) { "Bad literal at $i" }
        i += word.length
        return v
    }

    private fun num(): Number {
        val start = i
        while (i < s.length && (s[i].isDigit() || s[i] in "+-.eE")) i++
        val t = s.substring(start, i)
        return t.toLongOrNull() ?: t.toDouble()
    }

    private fun str(): String {
        check(s[i] == '"')
        i++
        val sb = StringBuilder()
        while (true) {
            check(i < s.length) { "Unterminated string" }
            val c = s[i++]
            when (c) {
                '"' -> return sb.toString()
                '\\' -> {
                    when (val e = s[i++]) {
                        '"', '\\', '/' -> sb.append(e)
                        'b' -> sb.append('\b')
                        'f' -> sb.append('\u000C')
                        'n' -> sb.append('\n')
                        'r' -> sb.append('\r')
                        't' -> sb.append('\t')
                        'u' -> { sb.append(s.substring(i, i + 4).toInt(16).toChar()); i += 4 }
                        else -> error("Bad escape \\$e")
                    }
                }
                else -> sb.append(c)
            }
        }
    }

    private fun arr(): List<Any?> {
        i++
        val out = mutableListOf<Any?>()
        ws()
        if (s[i] == ']') { i++; return out }
        while (true) {
            out += value()
            ws()
            when (s[i++]) {
                ',' -> continue
                ']' -> return out
                else -> error("Expected , or ] at ${i - 1}")
            }
        }
    }

    private fun obj(): Map<String, Any?> {
        i++
        val out = LinkedHashMap<String, Any?>()
        ws()
        if (s[i] == '}') { i++; return out }
        while (true) {
            ws()
            val k = str()
            ws()
            check(s[i++] == ':') { "Expected : at ${i - 1}" }
            out[k] = value()
            ws()
            when (s[i++]) {
                ',' -> continue
                '}' -> return out
                else -> error("Expected , or } at ${i - 1}")
            }
        }
    }
}

/** Typed access helpers over parsed JSON. */
@Suppress("UNCHECKED_CAST")
internal fun Any?.obj(key: String): Map<String, Any?> = (this as Map<String, Any?>)[key] as Map<String, Any?>

@Suppress("UNCHECKED_CAST")
internal fun Any?.list(key: String): List<Any?> = (this as Map<String, Any?>)[key] as List<Any?>

@Suppress("UNCHECKED_CAST")
internal fun Any?.str(key: String): String = (this as Map<String, Any?>)[key] as String

internal fun Any?.hex(key: String): ByteArray = str(key).decodeHex()

/** Locates files under the repository's `spec/` folder. */
internal object SpecFiles {
    val repoRoot: File by lazy {
        val candidates = sequence {
            System.getProperty("moldsign.repoRoot")?.let { yield(File(it)) }
            var dir: File? = File(System.getProperty("user.dir")).absoluteFile
            while (dir != null) {
                yield(dir)
                dir = dir.parentFile
            }
        }
        candidates.firstOrNull { File(it, "spec/vectors").isDirectory }
            ?: error("Cannot find spec/vectors walking up from ${System.getProperty("user.dir")}")
    }

    fun read(relative: String): String = File(repoRoot, relative).readText(Charsets.UTF_8)

    val cardCrypto: Any? by lazy { MiniJson.parse(read("spec/vectors/card-crypto.json")) }
}
