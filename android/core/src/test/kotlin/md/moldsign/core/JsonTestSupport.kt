package md.moldsign.core

import java.io.File

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
