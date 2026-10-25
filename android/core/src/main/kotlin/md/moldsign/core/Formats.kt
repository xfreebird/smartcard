package md.moldsign.core

/**
 * Raw signing callback handed to the format signers: DigestInfo(SHA-256) in, 512-byte RSA out.
 * The card session (ADF select + VERIFY PIN + MSE/INTERNAL AUTHENTICATE) lives behind it.
 */
fun interface RawSigner {
    fun sign(digestInfo: ByteArray): ByteArray
}

/**
 * PAdES-T (iText-style incremental update + detached CMS + RFC 3161 token), docs/02.
 * Port target: Swift `PAdESSigner` (Signing.swift).
 */
interface PadesSigner {
    fun sign(pdf: ByteArray, certificateDer: ByteArray, chainDer: List<ByteArray>, signer: RawSigner): ByteArray
}

/** XAdES-BES/T/C, detached or enveloping, middleware-faithful (docs/03). Port target: Swift `XAdES.swift`. */
interface XadesSigner {
    fun sign(
        documents: List<Document>,
        level: XadesLevel,
        packaging: XadesPackaging,
        certificateDer: ByteArray,
        chainDer: List<ByteArray>,
        signer: RawSigner,
    ): ByteArray
}

/**
 * The format chosen per file (docs/10 FormatChip). A PDF offers PAdES-T (default) or a detached XAdES over the PDF
 * bytes (BES / T / C); any other file offers XAdES only (default XAdES-T).
 */
enum class SignFormat(val label: String, val xadesLevel: XadesLevel?) {
    PadesT("PAdES-T", null),
    XadesBes("XAdES-BES", XadesLevel.BES),
    XadesT("XAdES-T", XadesLevel.T),
    XadesC("XAdES-C", XadesLevel.C),
    ;

    /** Output extension: the signed PDF for PAdES, the detached signature for XAdES. */
    val extension: String get() = if (xadesLevel == null) "pdf" else "xml"

    companion object {
        fun options(isPdf: Boolean): List<SignFormat> = if (isPdf) entries.toList() else listOf(XadesBes, XadesT, XadesC)

        fun default(isPdf: Boolean): SignFormat = if (isPdf) PadesT else XadesT

        /**
         * `<name>-semnat.<pdf|xml>` (Swift `SigningService.outputURL`): `contract.pdf` + XAdES-T → `contract-semnat.xml`.
         * De-duplication (" 2") is left to the platform's save dialog.
         */
        fun outputName(inputName: String, format: SignFormat): String {
            val dot = inputName.lastIndexOf('.')
            val base = if (dot > 0) inputName.substring(0, dot) else inputName
            return "$base-semnat.${format.extension}"
        }
    }
}

/** `%PDF-` header check (PAdES needs a PDF, whatever the file is called). */
fun Document.isPdf(): Boolean = bytes.size >= 5 && String(bytes, 0, 5, Charsets.ISO_8859_1) == "%PDF-"

/** TSA / OCSP / CRL over HttpURLConnection (no OkHttp), docs/06. */
interface TrustServices {
    /** RFC 3161 token over [messageImprint] (SHA-256) from `http://tsp.pki.gov.md/moldsign2/`. */
    fun timestamp(messageImprint: ByteArray): ByteArray

    fun fetchCrl(url: String): ByteArray

    fun ocsp(certificateDer: ByteArray, issuerDer: ByteArray): ByteArray
}

/** Offline validator (ByteRange / CMS / RSA / chain, XAdES c14n), docs/05. */
interface Validator {
    fun verifyPdf(pdf: ByteArray): List<ValidationReport>

    fun verifyXades(signatureXml: ByteArray, detachedDocuments: List<Document>): List<ValidationReport>
}

// TODO(AND-01): port PAdESSigner (Signing.swift + TimestampRequest.swift + ChainCerts.swift).
class UnportedPadesSigner : PadesSigner {
    override fun sign(pdf: ByteArray, certificateDer: ByteArray, chainDer: List<ByteArray>, signer: RawSigner): ByteArray =
        TODO("AND-01: PAdES signer not ported yet")
}

// TODO(AND-01): port XAdES BES/T/C (XAdES.swift), incl. vendor quirks (full-path ObjectReference, double OCSPRef).
class UnportedXadesSigner : XadesSigner {
    override fun sign(
        documents: List<Document>,
        level: XadesLevel,
        packaging: XadesPackaging,
        certificateDer: ByteArray,
        chainDer: List<ByteArray>,
        signer: RawSigner,
    ): ByteArray = TODO("AND-01: XAdES signer not ported yet")
}

// TODO(AND-01): TSA (RFC 3161 request DER), CRL fetch, native OCSP request builder (no `openssl` process).
class UnportedTrustServices : TrustServices {
    override fun timestamp(messageImprint: ByteArray): ByteArray = TODO("AND-01: TSA client not ported yet")
    override fun fetchCrl(url: String): ByteArray = TODO("AND-01: CRL client not ported yet")
    override fun ocsp(certificateDer: ByteArray, issuerDer: ByteArray): ByteArray = TODO("AND-01: OCSP client not ported yet")
}

// TODO(AND-01): port Validation.swift (ByteRange/CMS/RSA, manual chain, XAdES c14n checks).
class UnportedValidator : Validator {
    override fun verifyPdf(pdf: ByteArray): List<ValidationReport> = TODO("AND-01: PDF validator not ported yet")
    override fun verifyXades(signatureXml: ByteArray, detachedDocuments: List<Document>): List<ValidationReport> =
        TODO("AND-01: XAdES validator not ported yet")
}
