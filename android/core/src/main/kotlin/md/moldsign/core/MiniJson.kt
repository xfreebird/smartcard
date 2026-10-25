package md.moldsign.core

/**
 * Minimal JSON reader / writer helpers (objects, arrays, strings, numbers, booleans, null). The core is pure JVM,
 * where `org.json` does not exist, and the bridge and the test vectors need nothing more.
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

        /** [text] as a JSON string literal (quotes included); non-ASCII stays as is, control characters are escaped. */
        fun quote(text: String): String {
            val sb = StringBuilder(text.length + 2).append('"')
            for (c in text) {
                when {
                    c == '"' -> sb.append("\\\"")
                    c == '\\' -> sb.append("\\\\")
                    c == '\n' -> sb.append("\\n")
                    c == '\r' -> sb.append("\\r")
                    c == '\t' -> sb.append("\\t")
                    c < ' ' -> sb.append("\\u%04x".format(c.code))
                    else -> sb.append(c)
                }
            }
            return sb.append('"').toString()
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
        check(i < s.length && s[i] == '"') { "Expected string at $i" }
        i++
        val sb = StringBuilder()
        while (true) {
            check(i < s.length) { "Unterminated string" }
            val c = s[i++]
            when (c) {
                '"' -> return sb.toString()
                '\\' -> {
                    check(i < s.length) { "Unterminated escape" }
                    when (val e = s[i++]) {
                        '"', '\\', '/' -> sb.append(e)
                        'b' -> sb.append('\b')
                        'f' -> sb.append('\u000C')
                        'n' -> sb.append('\n')
                        'r' -> sb.append('\r')
                        't' -> sb.append('\t')
                        'u' -> {
                            check(i + 4 <= s.length) { "Bad \\u escape" }
                            sb.append(s.substring(i, i + 4).toInt(16).toChar())
                            i += 4
                        }
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
        check(i < s.length) { "Unterminated array" }
        if (s[i] == ']') { i++; return out }
        while (true) {
            out += value()
            ws()
            check(i < s.length) { "Unterminated array" }
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
        check(i < s.length) { "Unterminated object" }
        if (s[i] == '}') { i++; return out }
        while (true) {
            ws()
            val k = str()
            ws()
            check(i < s.length && s[i++] == ':') { "Expected : at ${i - 1}" }
            out[k] = value()
            ws()
            check(i < s.length) { "Unterminated object" }
            when (s[i++]) {
                ',' -> continue
                '}' -> return out
                else -> error("Expected , or } at ${i - 1}")
            }
        }
    }
}
