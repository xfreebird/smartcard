package md.moldsign.app.pin

import android.content.Context
import android.util.Base64
import md.moldsign.core.CertificateSummary

/** Public metadata only. Written after a PIN is saved, using that same certificate account. */
class SavedCardIdentities(context: Context) {
    private val preferences = context.getSharedPreferences("saved_card_identities", Context.MODE_PRIVATE)
    fun read(): List<CertificateSummary> = preferences.all.mapNotNull { (id, value) ->
        runCatching {
            val der = Base64.decode(value as String, Base64.NO_WRAP)
            require(der.size <= 4096)
            CertificateSummary.parse(der).takeIf { it.sha1Hex == id }
        }.getOrNull()
    }
    fun save(certificate: CertificateSummary) {
        val der = certificate.der ?: return
        if (CertificateSummary.parse(der).sha1Hex != certificate.sha1Hex) return
        preferences.edit().putString(certificate.sha1Hex, Base64.encodeToString(der, Base64.NO_WRAP)).apply()
    }
    fun delete(id: String) { preferences.edit().remove(id).apply() }
}
