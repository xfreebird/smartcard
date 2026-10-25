package md.moldsign.core

import java.io.ByteArrayInputStream
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.util.Date
import javax.security.auth.x500.X500Principal

/** Reader/card state shown by the StatusCard (docs/09 §3.4, docs/10 §3). */
sealed class ReaderState {
    data object NoReader : ReaderState()

    /** A USB reader is attached but the user has not granted access yet (AND-03). */
    data class PermissionRequired(val reader: String) : ReaderState()

    data class Empty(val reader: String) : ReaderState()

    data class CardPresent(val reader: String, val holder: String? = null) : ReaderState()

    data object Busy : ReaderState()

    data class Error(val message: String) : ReaderState()
}

/** Progress of one operation (docs/09 §3.4). */
enum class SigningStep { Idle, Connecting, Authenticating, ReadingCertificate, VerifyingPin, Signing, Timestamping, Revocation, Writing, Done }

enum class XadesLevel { BES, T, C }

enum class XadesPackaging { Detached, Enveloping }

/** Public data about the card certificate; reading it needs mutual auth but no PIN. */
data class CertificateSummary(
    val commonName: String,
    val subjectDn: String,
    val issuerDn: String,
    val issuerCommonName: String?,
    val notBefore: Date,
    val notAfter: Date,
    val serialHex: String,
    /** SHA-1 of the DER: the vendor `certificateId` and the PinVault key (docs/09 §3.5). */
    val sha1Hex: String,
    /** Subject `SN` (2.5.4.4), when the certificate has one. */
    val surname: String? = null,
    /** Subject `GN` (2.5.4.42), when the certificate has one. */
    val givenNames: String? = null,
    /** The X.509 DER this summary was parsed from (the browser bridge lists it as `certificateBase64`). */
    val der: ByteArray? = null,
) {
    /**
     * Surname and given name(s) for the ID-card face (docs/10 §0.2b): the subject's SN / GN when present,
     * otherwise the holder name split at the first space (first word = surname, the rest = given names).
     */
    val nameParts: Pair<String, String>
        get() {
            val sn = surname?.trim().orEmpty()
            val gn = givenNames?.trim().orEmpty()
            if (sn.isNotEmpty() || gn.isNotEmpty()) return sn to gn
            val cn = commonName.trim()
            val space = cn.indexOf(' ')
            return if (space < 0) cn to "" else cn.substring(0, space) to cn.substring(space + 1).trim()
        }

    companion object {
        /** OID → keyword so RFC 2253 output prints SN / GN as strings instead of `#hex`. */
        private val NAME_KEYWORDS = mapOf("2.5.4.4" to "SURNAME", "2.5.4.42" to "GIVENNAME")

        fun parse(der: ByteArray): CertificateSummary {
            val cert = CertificateFactory.getInstance("X.509").generateCertificate(ByteArrayInputStream(der)) as X509Certificate
            val subject = cert.subjectX500Principal.getName(X500Principal.RFC2253)
            val issuer = cert.issuerX500Principal.getName(X500Principal.RFC2253)
            val named = runCatching { cert.subjectX500Principal.getName(X500Principal.RFC2253, NAME_KEYWORDS) }.getOrNull()
            return CertificateSummary(
                commonName = rdnValue(subject, "CN") ?: subject,
                subjectDn = subject,
                issuerDn = issuer,
                issuerCommonName = rdnValue(issuer, "CN"),
                notBefore = cert.notBefore,
                notAfter = cert.notAfter,
                serialHex = cert.serialNumber.toString(16).uppercase(),
                sha1Hex = Sha.sha1(der).toHex(),
                surname = named?.let { rdnValue(it, "SURNAME") },
                givenNames = named?.let { rdnValue(it, "GIVENNAME") },
                der = der,
            )
        }

        /** First value of attribute [type] in an RFC 2253 DN (handles `\,` escapes; no javax.naming on Android). */
        internal fun rdnValue(dn: String, type: String): String? {
            var i = 0
            while (i < dn.length) {
                val eq = dn.indexOf('=', i)
                if (eq < 0) return null
                val key = dn.substring(i, eq).trim()
                val value = StringBuilder()
                var j = eq + 1
                while (j < dn.length && dn[j] != ',' && dn[j] != '+') {
                    if (dn[j] == '\\' && j + 1 < dn.length) j++
                    value.append(dn[j])
                    j++
                }
                if (key.equals(type, ignoreCase = true)) return value.toString()
                i = j + 1
            }
            return null
        }
    }
}

/** What the platform consent UI is asked to approve (docs/10 ConsentSheet / PIN sheet). */
data class ConsentRequest(
    /** `null` for the local user ("Tu"), else the requesting web origin. */
    val requester: String?,
    val documentNames: List<String>,
    val format: String,
    val certificate: CertificateSummary,
    /** Remaining PIN attempts when known (after a wrong PIN). */
    val attemptsLeft: Int? = null,
)

sealed class ConsentResult {
    /** The PIN to present; the service wipes the array after VERIFY. */
    class Pin(val pin: CharArray) : ConsentResult()

    data object Cancelled : ConsentResult()
}

/**
 * The single place where the platform shows UI (PIN sheet, biometric prompt for the stored PIN,
 * bridge consent). Called on the signing thread; may block until the user answers.
 */
fun interface Consent {
    fun obtain(request: ConsentRequest): ConsentResult
}

class SignResult(
    val output: ByteArray,
    val certificate: CertificateSummary,
    val format: String,
)

class RawSignature(val signature: ByteArray, val certificateDer: ByteArray)

/** One signature's verdict (docs/10 VerdictBadge / SignatureCard). */
data class ValidationReport(
    val signerName: String?,
    val signingTime: Date?,
    val timestampTime: Date?,
    val level: String?,
    val integrityOk: Boolean,
    val signatureOk: Boolean,
    val chainOk: Boolean?,
    /** Technical notes for the "Detalii tehnice" disclosure (English, not localized). */
    val details: List<String> = emptyList(),
    /** Names of the signed documents a detached XAdES refers to and that were not supplied (integrity cannot be checked). */
    val missingDocuments: List<String> = emptyList(),
)

/** docs/10 VerdictBadge: what the user is told about a verified file. */
enum class Verdict {
    /** Every signature: content unchanged, signature correct, certificate chains to MDQSign / mdtrustca. */
    Valid,

    /** A signature is wrong or the content changed after signing. */
    Invalid,

    /** Nothing is wrong, but it cannot be confirmed: the chain is not the MoldSign trust chain, or a detached XAdES lacks its document. */
    Unconfirmed,

    /** No signature this app can read. */
    NoSignature,
    ;

    companion object {
        fun of(reports: List<ValidationReport>): Verdict = when {
            reports.isEmpty() -> NoSignature
            // a document that was not supplied is not evidence of a change: only a supplied-but-different one is
            reports.any { !it.signatureOk || (!it.integrityOk && it.missingDocuments.isEmpty()) } -> Invalid
            reports.any { it.missingDocuments.isNotEmpty() || it.chainOk != true } -> Unconfirmed
            else -> Valid
        }
    }
}

/** A named input document. */
class Document(val name: String, val bytes: ByteArray)
