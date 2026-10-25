namespace MoldSign.Core;

/// <summary>
/// App-facing facade (docs/09 §3.4). Synchronous like the Swift core: call it off the UI thread.
/// Owns the process-wide card lock: UI and bridge requests queue behind it, because two interleaved
/// secure-messaging sessions desync the SSC (6988).
/// </summary>
public sealed class SigningService
{
    private static readonly object s_cardLock = new();

    private readonly Func<ICardTransport> _connect;
    private readonly Action<string>? _trace;
    private readonly PadesSigner _pades;
    private readonly XadesSigner _xades;
    private readonly Validator _validator;
    private ReaderState _readerState = new ReaderState.NoReader();

    /// <param name="connect">Opens a fresh transport per operation (e.g. <c>() =&gt; WinSCardTransport.Connect()</c>).</param>
    /// <param name="trust">TSA/OCSP/CRL client; a default <see cref="TrustServices"/> when null.</param>
    /// <param name="trace">Step-level diagnostics; never receives PINs or key material.</param>
    public SigningService(Func<ICardTransport> connect, TrustServices? trust = null, Action<string>? trace = null)
    {
        _connect = connect ?? throw new ArgumentNullException(nameof(connect));
        _trace = trace;
        trust ??= new TrustServices();
        _pades = new PadesSigner(trust);
        _xades = new XadesSigner(trust);
        _validator = new Validator();
    }

    /// <summary>"stream&lt;ReaderState&gt;": raised on the thread that published the change.</summary>
    public event EventHandler<ReaderState>? ReaderStateChanged;

    /// <summary>"progress: stream&lt;Step&gt;".</summary>
    public event EventHandler<SigningStep>? Progress;

    public ReaderState ReaderState => Volatile.Read(ref _readerState);

    /// <summary>The platform ReaderMonitor (Windows: ReaderWatcher) publishes hot-plug changes here.</summary>
    public void PublishReaderState(ReaderState state)
    {
        ArgumentNullException.ThrowIfNull(state);
        Volatile.Write(ref _readerState, state);
        ReaderStateChanged?.Invoke(this, state);
    }

    /// <summary>PIN-less certificate read (full mutual auth, so it takes the card lock too).</summary>
    public CertificateSummary Certificate() =>
        WithCard(card => CertificateSummary.FromDer(ReadCertificate(card)));

    /// <summary>
    /// Raw card signature over a DigestInfo (CLI <c>sign-hex</c>, bridge hash signing, and the callback
    /// the PAdES/XAdES builders use). Runs: auth → certificate → consent → ADF → VERIFY → sign.
    /// </summary>
    public (byte[] Signature, CertificateSummary Certificate) SignDigestInfo(byte[] digestInfo, ConsentProvider consent,
                                                                            string requester = "Tu", string format = "RAW")
    {
        ArgumentNullException.ThrowIfNull(digestInfo);
        ArgumentNullException.ThrowIfNull(consent);
        return WithCard(card =>
        {
            var summary = CertificateSummary.FromDer(ReadCertificate(card));
            var signature = SignWithConsent(card, summary, digestInfo, consent, requester, [], format);
            return (signature, summary);
        });
    }

    /// <summary>PAdES-T signature of <paramref name="input"/> into <paramref name="output"/>.</summary>
    public SignResult SignPdf(string input, string output, ConsentProvider consent, string requester = "Tu")
    {
        ArgumentNullException.ThrowIfNull(consent);
        var pdf = File.ReadAllBytes(input);
        return WithCard(card =>
        {
            var der = ReadCertificate(card);
            var summary = CertificateSummary.FromDer(der);
            var signed = _pades.Sign(pdf, der, digestInfo =>
                SignWithConsent(card, summary, digestInfo, consent, requester, [Path.GetFileName(input)], "PAdES-T"));
            Report(SigningStep.Writing);
            WriteNew(output, signed);
            Report(SigningStep.Done);
            return new SignResult([output], summary, "PAdES-T");
        });
    }

    /// <summary>XAdES signature over <paramref name="files"/> written to <paramref name="output"/>.</summary>
    public SignResult SignXades(IReadOnlyList<string> files, XadesFormat format, XadesPackaging packaging,
                                string output, ConsentProvider consent, string requester = "Tu")
    {
        ArgumentNullException.ThrowIfNull(files);
        ArgumentNullException.ThrowIfNull(consent);
        var label = format switch { XadesFormat.Bes => "XAdES-BES", XadesFormat.T => "XAdES-T", _ => "XAdES-C" };
        return WithCard(card =>
        {
            var der = ReadCertificate(card);
            var summary = CertificateSummary.FromDer(der);
            // TODO(WIN-01): chain = MDQSign CA + mdtrustca (port ChainCerts.swift).
            var xml = _xades.Sign(files, format, packaging, der, [], digestInfo =>
                SignWithConsent(card, summary, digestInfo, consent, requester,
                                files.Select(Path.GetFileName).OfType<string>().ToArray(), label));
            Report(SigningStep.Writing);
            WriteNew(output, xml);
            Report(SigningStep.Done);
            return new SignResult([output], summary, label);
        });
    }

    /// <summary>Offline verification of a signed PDF, or of an XAdES file plus its detached documents.</summary>
    public IReadOnlyList<VerificationReport> Verify(string file, IReadOnlyList<string>? detachedDocs = null)
    {
        var bytes = File.ReadAllBytes(file);
        if (string.Equals(Path.GetExtension(file), ".pdf", StringComparison.OrdinalIgnoreCase))
            return _validator.ValidatePdf(bytes);
        var referenced = (detachedDocs ?? [])
            .ToDictionary(p => Path.GetFileName(p), File.ReadAllBytes, StringComparer.Ordinal);
        return _validator.ValidateXades(bytes, referenced);
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

    private T WithCard<T>(Func<CosmoXCard, T> operation)
    {
        lock (s_cardLock)
        {
            var previous = ReaderState;
            Report(SigningStep.Connecting);
            ICardTransport transport;
            try
            {
                transport = _connect();
            }
            catch (CardException e)
            {
                PublishReaderState(new ReaderState.Error(e.Kind, e.Message));
                throw;
            }

            using (transport)
            {
                var reader = transport.ReaderName;
                var idle = previous as ReaderState.CardPresent ?? new ReaderState.CardPresent(reader, null);
                try
                {
                    PublishReaderState(new ReaderState.Busy(reader, SigningStep.Authenticating));
                    Report(SigningStep.Authenticating);
                    var card = new CosmoXCard(transport, _trace);
                    card.Authenticate();
                    var result = operation(card);
                    PublishReaderState(idle);
                    return result;
                }
                catch (CardException e) when (e.Kind != CardErrorKind.Cancelled)
                {
                    PublishReaderState(new ReaderState.Error(e.Kind, e.Message, reader));
                    throw;
                }
                catch
                {
                    // Cancelled, I/O, format or not-yet-ported (NotImplementedException) failures:
                    // the card itself is fine.
                    PublishReaderState(idle);
                    throw;
                }
            }
        }
    }

    private byte[] ReadCertificate(CosmoXCard card)
    {
        Report(SigningStep.ReadingCertificate);
        return card.ReadCertificate();
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
