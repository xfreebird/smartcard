package md.moldsign.core

/**
 * SEC-01 origin policy for the local MoldSign bridge (docs/09 §3.6), mirroring the vendor's
 * `AllowedSites` + `Certificates`/`Signature` checks:
 *
 * - every VALUE of `spec/bridge/allowed-origins.properties` becomes a regex the vendor way
 *   (`.` → `\.`, then `?` → `.?`, then `*` → `.*`), and the whole `Origin` header must match;
 * - a request WITHOUT an `Origin` header is allowed only with `moldSign: DesktopSuiteClient`;
 * - anything else gets 403 and no CORS headers.
 *
 * Duplicate keys (the file has two `gov=` lines) are all kept: `java.util.Properties` would keep
 * only the last, but `*.gov.md` covers the first anyway.
 */
class BridgeOriginPolicy(patterns: List<String>) {
    /** The compiled vendor patterns, in file order. */
    val regexes: List<Regex> = patterns.map { vendorPatternToRegex(it) }

    fun isAllowed(origin: String?, moldSignHeader: String?): Boolean =
        if (origin != null) {
            regexes.any { it.matches(origin) }
        } else {
            moldSignHeader == DESKTOP_CLIENT_VALUE
        }

    companion object {
        const val DESKTOP_CLIENT_HEADER = "moldSign"
        const val DESKTOP_CLIENT_VALUE = "DesktopSuiteClient"

        /** Classpath copy of `spec/bridge/allowed-origins.properties` (packaged by core/build.gradle.kts). */
        const val BUNDLED_RESOURCE = "allowed-origins.properties"

        fun fromProperties(text: String): BridgeOriginPolicy = BridgeOriginPolicy(propertyValues(text))

        /** Policy from the allow-list bundled into the core jar. */
        fun bundled(): BridgeOriginPolicy {
            // An absolute path survives R8 moving/renaming the anchor class's package.
            val stream = BridgeOriginPolicy::class.java.getResourceAsStream("/md/moldsign/core/$BUNDLED_RESOURCE")
                ?: error("Missing bundled resource md/moldsign/core/$BUNDLED_RESOURCE")
            return stream.use { fromProperties(it.readBytes().toString(Charsets.ISO_8859_1)) }
        }

        /** Vendor conversion, applied in the same order as `AllowedSites.initializeAllowedUrl`. */
        fun vendorPatternToRegex(value: String): Regex =
            Regex(value.replace(".", "\\.").replace("?", ".?").replace("*", ".*"))

        /**
         * All values of a `.properties` text, duplicates included, in file order.
         * Supports the subset of `java.util.Properties` syntax the allow-list uses: `#`/`!` comments,
         * key terminated by the first `=`, `:` or whitespace, surrounding whitespace trimmed.
         */
        fun propertyValues(text: String): List<String> {
            val values = mutableListOf<String>()
            for (rawLine in text.lineSequence()) {
                val line = rawLine.trimStart()
                if (line.isEmpty() || line[0] == '#' || line[0] == '!') continue
                var i = 0
                while (i < line.length && line[i] != '=' && line[i] != ':' && !line[i].isWhitespace()) i++
                while (i < line.length && line[i].isWhitespace()) i++
                if (i < line.length && (line[i] == '=' || line[i] == ':')) i++
                val value = line.substring(i).trim()
                if (value.isNotEmpty()) values += value
            }
            return values
        }
    }
}
