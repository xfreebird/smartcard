namespace MoldSign.Core;

/// <summary>
/// App-facing facade (docs/09 §3.4). Synchronous like the Swift core: call it off the UI thread.
/// Owns the process-wide card lock: UI and bridge requests queue behind it, because two interleaved
/// secure-messaging sessions desync the SSC (6988).
/// </summary>
public sealed class SigningService : IDocumentSigner, IDocumentVerifier
{
    private static readonly object s_cardLock = new();

    private readonly Func<string?, ICardTransport> _connect;
    private readonly Action<string>? _trace;
    private readonly PadesSigner _pades;
    private readonly XadesSigner _xades;
    private ReaderState _readerState = new ReaderState.NoReader();
    private volatile bool _experimentalTokens;

    /// <summary>
    /// Experimental USB token support (Phase TOK), off by default and switched from the app's settings. On: a reader
    /// holding a recognized token (<see cref="TokenRecognizer"/>, by ATR) fails with
    /// <see cref="CardErrorKind.UnsupportedToken"/> before any APDU is sent. Off: exactly the eID-only behavior.
    /// </summary>
    public bool ExperimentalTokens
    {
        get => _experimentalTokens;
        set => _experimentalTokens = value;
    }

    /// <param name="connect">Opens a fresh transport per operation (e.g. <c>() =&gt; WinSCardTransport.Connect()</c>).</param>
    /// <param name="trust">TSA/OCSP/CRL client; a default <see cref="TrustServices"/> when null.</param>
    /// <param name="trace">Step-level diagnostics; never receives PINs or key material.</param>
    public SigningService(Func<ICardTransport> connect, TrustServices? trust = null, Action<string>? trace = null)
        : this(AnyReader(connect), trust, trace)
    {
    }

    /// <param name="connectReader">
    /// Opens a fresh transport per operation for the named reader; null = the caller's default choice
    /// (several eID cards can be connected at once, docs/09 §3.1b). Every card operation below takes the reader.
    /// </param>
    /// <param name="trust">TSA/OCSP/CRL client; a default <see cref="TrustServices"/> when null.</param>
    /// <param name="trace">Step-level diagnostics; never receives PINs or key material.</param>
    public SigningService(Func<string?, ICardTransport> connectReader, TrustServices? trust = null, Action<string>? trace = null)
    {
        _connect = connectReader ?? throw new ArgumentNullException(nameof(connectReader));
        _trace = trace;
        trust ??= new TrustServices();
        _pades = new PadesSigner(trust) { Progress = Report };
        _xades = new XadesSigner(trust) { Progress = Report };
    }

    /// <summary>"stream&lt;ReaderState&gt;": raised on the thread that published the change.</summary>
    public event EventHandler<ReaderState>? ReaderStateChanged;

    /// <summary>"progress: stream&lt;Step&gt;".</summary>
    public event EventHandler<SigningStep>? Progress;

    public IReadOnlyList<Protection.CardEncryptionIdentity> EncryptionIdentities(string? reader = null,
        Protection.CertificateRecipientPolicy policy = Protection.CertificateRecipientPolicy.EncryptionCertificate) =>
        WithCard(reader, card => Protection.CardFileProtection.Identities(card,policy));
    public byte[] DecryptFile(byte[] envelope, Protection.CardEncryptionIdentity identity, string pin, string? reader = null) =>
        WithCard(reader, card => Protection.CardFileProtection.Decrypt(card,envelope,identity,pin));

    public ReaderState ReaderState => Volatile.Read(ref _readerState);

    /// <summary>The platform ReaderMonitor (Windows: ReaderWatcher) publishes hot-plug changes here.</summary>
    public void PublishReaderState(ReaderState state)
    {
        ArgumentNullException.ThrowIfNull(state);
        Volatile.Write(ref _readerState, state);
        ReaderStateChanged?.Invoke(this, state);
    }

    /// <summary>PIN-less certificate read (full mutual auth, so it takes the card lock too).</summary>
    /// <param name="reader">Reader to read; null = the connect callback's default.</param>
    public CertificateSummary Certificate(string? reader = null) =>
        WithCard(reader, card => CertificateSummary.FromDer(ReadCertificate(card, expectedCertificateSha1: null)));

    /// <summary>
    /// <c>listCards()</c> (docs/09 §3.1b): every given reader that holds a readable card, with its PIN-less
    /// certificate. Unreadable cards are skipped. The bridge's <c>/certificates</c> lists all of them.
    /// </summary>
    public IReadOnlyList<CardEntry> ListCards(IEnumerable<string> readers)
    {
        ArgumentNullException.ThrowIfNull(readers);
        var entries = new List<CardEntry>();
        foreach (var reader in readers)
        {
            try
            {
                entries.Add(new CardEntry(reader, Certificate(reader)));
            }
            catch (CardException e)
            {
                _trace?.Invoke($"listCards: {reader}: {e.Kind}");
            }
        }
        return entries;
    }

    /// <summary>
    /// Raw card signature over a DigestInfo (CLI <c>sign-hex</c>, bridge hash signing, and the callback
    /// the PAdES/XAdES builders use). Runs: auth → certificate → identity guard → consent → ADF → VERIFY → sign.
    /// </summary>
    /// <param name="reader">Reader holding the card to sign with; null = the connect callback's default.</param>
    /// <param name="expectedCertificateSha1">
    /// SHA-1 of the card the user chose (wallet selection, bridge <c>certificateId</c>). A different card in the
    /// reader fails with <see cref="CardErrorKind.CardChanged"/> before consent and before VERIFY.
    /// </param>
    public (byte[] Signature, CertificateSummary Certificate) SignDigestInfo(byte[] digestInfo, ConsentProvider consent,
                                                                            string requester = "Tu", string format = "RAW",
                                                                            string? reader = null,
                                                                            string? expectedCertificateSha1 = null)
    {
        ArgumentNullException.ThrowIfNull(digestInfo);
        ArgumentNullException.ThrowIfNull(consent);
        return WithCard(reader, card =>
        {
            var summary = CertificateSummary.FromDer(ReadCertificate(card, expectedCertificateSha1));
            var signature = SignWithConsent(card, summary, digestInfo, consent, requester, [], format);
            return (signature, summary);
        });
    }

    /// <summary>PAdES-T signature of <paramref name="input"/> into <paramref name="output"/>.</summary>
    /// <param name="reader">Reader holding the card to sign with; null = the connect callback's default.</param>
    /// <param name="expectedCertificateSha1">Identity guard, see <see cref="SignDigestInfo"/>.</param>
    public SignResult SignPdf(string input, string output, ConsentProvider consent, string requester = "Tu",
                              string? reader = null, string? expectedCertificateSha1 = null, PdfStampPlacement? placement = null)
    {
        ArgumentNullException.ThrowIfNull(consent);
        var pdf = ReadBoundedDocument(input);
        return WithCard(reader, card =>
        {
            var der = ReadCertificate(card, expectedCertificateSha1);
            var summary = CertificateSummary.FromDer(der);
            var signed = _pades.Sign(pdf, der, digestInfo =>
                SignWithConsent(card, summary, digestInfo, consent, requester, [Path.GetFileName(input)], "PAdES-T"), placement);
            Report(SigningStep.Writing);
            WriteNew(output, signed);
            Report(SigningStep.Done);
            return new SignResult([output], summary, "PAdES-T");
        });
    }

    /// <summary>Signs an immutable in-memory PDF while retaining the shared card-operation lock.
    /// The consent callback sees the exact certificate before PIN verification and may reject it.</summary>
    public byte[] SignPdfBytes(byte[] pdf, ConsentProvider consent, string requester = "Local automation",
                               string? reader = null)
    {
        ArgumentNullException.ThrowIfNull(pdf);
        DocumentRegex.CheckLength(pdf.Length);
        ArgumentNullException.ThrowIfNull(consent);
        var snapshot = (byte[])pdf.Clone();
        return WithCard(reader, card =>
        {
            var der = ReadCertificate(card, expectedCertificateSha1: null);
            var summary = CertificateSummary.FromDer(der);
            return _pades.Sign(snapshot, der, digestInfo =>
                SignWithConsent(card, summary, digestInfo, consent, requester, ["PDF document"], "PAdES-T"));
        });
    }

    /// <summary>XAdES signature over <paramref name="files"/> written to <paramref name="output"/>.</summary>
    /// <param name="reader">Reader holding the card to sign with; null = the connect callback's default.</param>
    /// <param name="expectedCertificateSha1">Identity guard, see <see cref="SignDigestInfo"/>.</param>
    public SignResult SignXades(IReadOnlyList<string> files, XadesFormat format, XadesPackaging packaging,
                                string output, ConsentProvider consent, string requester = "Tu",
                                string? reader = null, string? expectedCertificateSha1 = null, string? digestAlgorithm = null)
    {
        ArgumentNullException.ThrowIfNull(files);
        ArgumentNullException.ThrowIfNull(consent);
        var label = format switch { XadesFormat.Bes => "XAdES-BES", XadesFormat.T => "XAdES-T", _ => "XAdES-C" };
        return WithCard(reader, card =>
        {
            var der = ReadCertificate(card, expectedCertificateSha1);
            var summary = CertificateSummary.FromDer(der);
            var xml = _xades.Sign(files, format, packaging, der, ChainCertificates.All, digestInfo =>
                SignWithConsent(card, summary, digestInfo, consent, requester,
                                files.Select(Path.GetFileName).OfType<string>().ToArray(), label), digestAlgorithm);
            Report(SigningStep.Writing);
            WriteNew(output, xml);
            Report(SigningStep.Done);
            return new SignResult([output], summary, label);
        });
    }

    /// <summary>
    /// Signs one document in the chosen <paramref name="format"/> (the Sign page's per-document picker): PAdES-T for a
    /// PDF, or XAdES-BES/T/C over any file, PDFs included (detached over the bytes → <c>&lt;name&gt;-semnat.xml</c>).
    /// Output next to the input, never overwriting (<see cref="SignatureFormats.OutputPath"/>).
    /// </summary>
    public SignResult Sign(string input, SignatureFormat format, XadesPackaging packaging, ConsentProvider consent,
                           string requester = "Tu", string? reader = null, string? expectedCertificateSha1 = null)
    {
        ArgumentNullException.ThrowIfNull(input);
        if (!SignatureFormats.Allowed(input).Contains(format))
            throw new ArgumentException($"{SignatureFormats.Label(format)} cannot sign {Path.GetFileName(input)}", nameof(format));
        var output = SignatureFormats.OutputPath(input, format);
        return SignatureFormats.ToXades(format) is { } xades
            ? SignXades([input], xades, packaging, output, consent, requester, reader, expectedCertificateSha1)
            : SignPdf(input, output, consent, requester, reader, expectedCertificateSha1);
    }

    public SignResult SignVisible(string input, SignatureFormat format, XadesPackaging packaging, ConsentProvider consent,
        PdfStampPlacement placement, string requester = "Tu", string? reader = null, string? expectedCertificateSha1 = null)
    {
        if (format != SignatureFormat.PadesT) throw new ArgumentException("A visible stamp requires a PDF signature", nameof(format));
        return SignPdf(input, SignatureFormats.OutputPath(input, format), consent, requester, reader, expectedCertificateSha1, placement);
    }

    private static byte[] ReadBoundedDocument(string path)
    {
        using var input = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read);
        if (input.Length > DocumentRegex.MaximumDocumentBytes)
            throw new CardException(CardErrorKind.Format, "Document exceeds safe processing limits");
        var bytes = new byte[checked((int)input.Length)];
        input.ReadExactly(bytes);
        if (input.ReadByte() != -1) throw new CardException(CardErrorKind.Format, "Document changed while reading");
        return bytes;
    }

    /// <summary>Offline verification of a signed PDF, or of an XAdES file plus its detached documents.</summary>
    public IReadOnlyList<VerificationReport> Verify(string file, IReadOnlyList<string>? detachedDocs = null)
    {
        var bytes = ReadBoundedDocument(file);
        if (string.Equals(Path.GetExtension(file), ".pdf", StringComparison.OrdinalIgnoreCase))
            return Validator.ValidatePdf(bytes);
        var referenced = (detachedDocs ?? [])
            .ToDictionary(p => Path.GetFileName(p), File.ReadAllBytes, StringComparer.Ordinal);
        return Validator.ValidateXades(bytes, referenced);
    }

    /// <summary>D-06: <c>&lt;name&gt;-semnat.&lt;ext&gt;</c> next to the original, never overwriting (adds " (2)", " (3)"…).</summary>
    public static string DefaultOutputPath(string input, string? extension = null)
    {
        var dir = Path.GetDirectoryName(Path.GetFullPath(input)) ?? ".";
        var stem = Path.GetFileNameWithoutExtension(input);
        var ext = extension ?? Path.GetExtension(input);
        var candidate = Path.Combine(dir, $"{stem}-semnat{ext}");
        for (var n = 2; File.Exists(candidate); n++)
            candidate = Path.Combine(dir, $"{stem}-semnat ({n}){ext}");
        return candidate;
    }

    // MARK: - Internals

    private T WithCard<T>(string? reader, Func<CosmoXCard, T> operation)
    {
        lock (s_cardLock)
        {
            var previous = ReaderState;
            Report(SigningStep.Connecting);
            ICardTransport transport;
            try
            {
                transport = _connect(reader);
            }
            catch (CardException e)
            {
                PublishReaderState(new ReaderState.Error(e.Kind, e.Message));
                throw;
            }

            using (transport)
            {
                var connected = transport.ReaderName;
                var idle = previous as ReaderState.CardPresent ?? new ReaderState.CardPresent(connected, null);
                try
                {
                    if (ExperimentalTokens && TokenRecognizer.Family(transport.Atr) is { } token)
                        throw new CardException(CardErrorKind.UnsupportedToken,
                            $"{token.DisplayName()} recognized; signing with USB tokens is not available yet");
                    PublishReaderState(new ReaderState.Busy(connected, SigningStep.Authenticating));
                    Report(SigningStep.Authenticating);
                    var card = new CosmoXCard(transport, _trace);
                    card.Authenticate();
                    var result = operation(card);
                    PublishReaderState(idle);
                    return result;
                }
                catch (CardException e) when (e.Kind is not CardErrorKind.Cancelled and not CardErrorKind.Format and not CardErrorKind.Network)
                {
                    PublishReaderState(new ReaderState.Error(e.Kind, e.Message, connected));
                    throw;
                }
                catch
                {
                    // Consent, document and network failures do not mean the card itself failed.
                    PublishReaderState(idle);
                    throw;
                }
            }
        }
    }

    /// <summary>
    /// Reads the certificate and applies the identity guard (docs/09 §3.1b) before anything else happens: the
    /// consent UI, the stored-PIN lookup and VERIFY all run only for the expected card.
    /// </summary>
    private byte[] ReadCertificate(CosmoXCard card, string? expectedCertificateSha1)
    {
        Report(SigningStep.ReadingCertificate);
        var der = card.ReadCertificate();
        CosmoXCard.EnsureExpectedCard(der, expectedCertificateSha1);
        return der;
    }

    private static Func<string?, ICardTransport> AnyReader(Func<ICardTransport> connect)
    {
        ArgumentNullException.ThrowIfNull(connect);
        return _ => connect();
    }

    private byte[] SignWithConsent(CosmoXCard card, CertificateSummary summary, byte[] digestInfo,
                                   ConsentProvider consent, string requester, IReadOnlyList<string> documents,
                                   string format)
    {
        var answer = consent(new ConsentRequest
        {
            Requester = requester,
            Documents = documents,
            Format = format,
            Certificate = summary,
        });
        if (answer.IsCancelled)
            throw new CardException(CardErrorKind.Cancelled, "Signing cancelled by the user");

        // Never auto-retry a PIN (protects the retry counter): a WrongPin bubbles up to the caller,
        // which deletes the stored PIN and shows the remaining attempts.
        Report(SigningStep.VerifyingPin);
        card.SelectGenericAdf();
        card.VerifyPin(answer.Pin!);
        Report(SigningStep.Signing);
        return card.Sign(digestInfo);
    }

    private void Report(SigningStep step)
    {
        _trace?.Invoke($"step: {step}");
        Progress?.Invoke(this, step);
    }

    private static void WriteNew(string path, byte[] bytes)
    {
        using var stream = new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.None);
        stream.Write(bytes);
    }
}
