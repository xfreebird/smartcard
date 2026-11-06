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
    fun signVisible(pdf: ByteArray, certificateDer: ByteArray, chainDer: List<ByteArray>, signer: RawSigner, placement: PdfStampPlacement): ByteArray =
        throw CardError.Format("Visible signatures are not supported by this signer")
    fun sign(pdf: ByteArray, certificateDer: ByteArray, chainDer: List<ByteArray>, signer: RawSigner): ByteArray
}

/** XAdES-BES/T/C, detached or enveloping, middleware-faithful (docs/03). Port of Swift `XAdES.swift`: [XadesDocumentSigner]. */
interface XadesSigner {
    /**
     * [digest] is what the references, SignedProperties, certificate digest and signature method use. The portal asks
     * SHA-1 for Xml/Text contents and the vendor honours it; the card then signs a SHA-1 DigestInfo.
     */
    fun sign(
        documents: List<Document>,
        level: XadesLevel,
        packaging: XadesPackaging,
        certificateDer: ByteArray,
        chainDer: List<ByteArray>,
        signer: RawSigner,
        digest: XadesDigest = XadesDigest.SHA256,
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

/** Offline validator (ByteRange / CMS / RSA / chain, XAdES c14n), docs/05: [OfflineValidator]. */
interface Validator {
    fun verifyPdf(pdf: ByteArray): List<ValidationReport>

    fun verifyXades(signatureXml: ByteArray, detachedDocuments: List<Document>): List<ValidationReport>
}
