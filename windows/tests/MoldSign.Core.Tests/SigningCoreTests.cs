using System.Formats.Asn1;
using System.Net;
using System.Security.Cryptography;
using System.Security.Cryptography.Pkcs;
using System.Security.Cryptography.X509Certificates;
using System.Security.Cryptography.Xml;
using System.Text;
using System.Xml;

namespace MoldSign.Core.Tests;

public sealed class SigningCoreTests
{
    [Fact]
    public void Signing_service_signs_pdf_and_requested_sha1_xades_with_one_consent_and_verify_per_document()
    {
        using var identity = new TestIdentity();
        using var pki = new FakePki(identity);
        using var files = new TestFiles();
        var input = files.Write("input.pdf", MinimalPdf());
        var simulations = new List<CosmoXCardTests.SimulatedSmCard>();
        var service = new SigningService(reader =>
        {
            var sim = IdentityGuardTests.Simulator(identity.Certificate, CosmoXCardTests.SessionAfterAuthentication());
            sim.InternalAuthenticate = identity.Sign;
            simulations.Add(sim);
            return new IdentityGuardTests.AuthenticatingTransport(sim, reader ?? "fixture reader");
        }, pki.Trust);
        var consentCalls = 0;
        ConsentResult Consent(ConsentRequest _)
        {
            consentCalls++;
            return ConsentResult.WithPin("0000"); // simulator only
        }
        var expected = Convert.ToHexString(SHA1.HashData(identity.Certificate));
        var pdfOutput = Path.Combine(files.DirectoryPath, "signed.pdf");
        service.SignPdf(input, pdfOutput, Consent, reader: "fixture reader", expectedCertificateSha1: expected);
        var xmlOutput = Path.Combine(files.DirectoryPath, "signed.xml");
        service.SignXades([input], XadesFormat.Bes, XadesPackaging.Detached, xmlOutput, Consent,
            reader: "fixture reader", expectedCertificateSha1: expected, digestAlgorithm: "SHA-1");
        Assert.Equal(2, consentCalls);
        Assert.All(simulations, sim => Assert.Single(sim.Commands, c => c[1] == 0x20));
        Assert.True(Assert.Single(service.Verify(pdfOutput)).SignatureValid);
        var report = Assert.Single(service.Verify(xmlOutput, [input]));
        Assert.True(report.ContentIntact, report.Notes);
        Assert.True(report.SignatureValid, report.Notes);
        Assert.Contains(XadesXml.RsaSha1, File.ReadAllText(xmlOutput));
    }

    [Fact]
    public void Pades_cms_is_real_cades_with_timestamp_and_countersigning_keeps_both_signatures()
    {
        using var identity = new TestIdentity();
        using var pki = new FakePki(identity);
        var signer = new PadesSigner(pki.Trust);
        var original = MinimalPdf();
        var once = signer.Sign(original, identity.Certificate, identity.Sign);
        var twice = signer.Sign(once, identity.Certificate, identity.Sign);
        Assert.Equal(original, twice[..original.Length]);
        Assert.Equal(once, twice[..once.Length]);
        var reports = new Validator().ValidatePdf(twice);
        Assert.Equal(["Signature1", "Signature2"], reports.Select(r => r.Name));
        Assert.All(reports, report =>
        {
            Assert.True(report.ContentIntact, report.Notes);
            Assert.True(report.SignatureValid, report.Notes);
            Assert.True(report.TimestampImprintValid, report.Notes);
            Assert.False(report.ChainTrusted); // fixture root must never become a trusted national root
            Assert.False(report.TimestampSignatureValidated);
            Assert.False(report.RevocationValidated);
            Assert.Equal(Verdict.Indeterminate, report.Verdict);
        });
        Assert.Equal(2, identity.SignCalls);
        Assert.Equal(2, pki.TimestampRequests);
        var firstCms = ExtractCms(once);
        var cms = new SignedCms(new ContentInfo(ExtractPdfContent(once)), true);
        cms.Decode(firstCms);
        cms.CheckSignature(true);
        Assert.Equal(3, cms.Certificates.Count);
        Assert.Contains(cms.Certificates.OfType<X509Certificate2>(), c => c.RawData.AsSpan().SequenceEqual(ChainCertificates.MdqSign));
        Assert.Contains(cms.SignerInfos[0].SignedAttributes.OfType<CryptographicAttributeObject>(),
            a => a.Oid.Value == "1.2.840.113549.1.9.16.2.47");
        var tampered = (byte[])twice.Clone();
        tampered[Encoding.ASCII.GetString(original).IndexOf("Hello", StringComparison.Ordinal)] ^= 1;
        Assert.All(new Validator().ValidatePdf(tampered), r =>
        {
            Assert.Equal(Verdict.Invalid, r.Verdict);
            Assert.False(r.ContentIntact);
            Assert.True(r.SignatureValid);
        });
        var appended = twice.Concat(Encoding.ASCII.GetBytes("unsigned data")).ToArray();
        Assert.Equal(Verdict.Invalid, new Validator().ValidatePdf(appended)[^1].Verdict);
    }

    [Fact]
    public void Pades_reuses_the_existing_acroform_and_preserves_field_and_catalog_entries()
    {
        using var identity = new TestIdentity();
        using var pki = new FakePki(identity);
        var text = Encoding.Latin1.GetString(MinimalPdf(existingAcro: true));
        var signed = new PadesSigner(pki.Trust).Sign(Encoding.Latin1.GetBytes(text), identity.Certificate, identity.Sign);
        var update = Encoding.Latin1.GetString(signed)[text.Length..];
        Assert.Contains("/Fields[6 0 R ", update);
        Assert.Contains("/NeedAppearances false", update);
        Assert.Contains("/SigFlags 3", update);
        Assert.DoesNotContain("1 0 obj", update);
        Assert.True(new Validator().ValidatePdf(signed)[0].SignatureValid);
    }

    [Theory]
    [InlineData(XadesFormat.Bes, XadesPackaging.Detached, "SHA-256")]
    [InlineData(XadesFormat.Bes, XadesPackaging.Enveloping, "SHA-1")]
    [InlineData(XadesFormat.T, XadesPackaging.Detached, "SHA-1")]
    [InlineData(XadesFormat.T, XadesPackaging.Enveloping, "SHA-256")]
    [InlineData(XadesFormat.C, XadesPackaging.Detached, "SHA-256")]
    [InlineData(XadesFormat.C, XadesPackaging.Enveloping, "SHA-1")]
    public void Xades_levels_packaging_and_digests_are_cryptographically_verifiable(
        XadesFormat level, XadesPackaging packaging, string digest)
    {
        using var identity = new TestIdentity();
        using var pki = new FakePki(identity);
        using var files = new TestFiles();
        var path = files.Write("document.txt", Encoding.UTF8.GetBytes("Știință <&> document"));
        var bytes = File.ReadAllBytes(path);
        var xml = new XadesSigner(pki.Trust).Sign([path], level, packaging, identity.Certificate, identity.Chain, identity.Sign, digest);
        var report = Assert.Single(new Validator().ValidateXades(xml, new Dictionary<string, byte[]> { ["document.txt"] = bytes }));
        Assert.True(report.ContentIntact, report.Notes);
        Assert.True(report.SignatureValid, report.Notes);
        Assert.False(report.ChainTrusted);
        Assert.Equal(level switch { XadesFormat.Bes => "XAdES-BES", XadesFormat.T => "XAdES-T", _ => "XAdES-C" }, report.Level);
        Assert.Equal(level == XadesFormat.Bes ? null : (bool?)true, report.TimestampImprintValid);
        Assert.Equal(1, identity.SignCalls);
        var doc = XadesXml.Parse(xml);
        var signature = doc.DocumentElement!;
        var info = XadesXml.Child(signature, "SignedInfo");
        var expectedHash = digest == "SHA-1" ? HashAlgorithmName.SHA1 : HashAlgorithmName.SHA256;
        using var rsa = identity.PrivateCertificate.GetRSAPublicKey();
        Assert.True(rsa!.VerifyData(XadesXml.Canonical(info, packaging == XadesPackaging.Enveloping),
            Convert.FromBase64String(XadesXml.Child(signature, "SignatureValue").InnerText), expectedHash, RSASignaturePadding.Pkcs1));
        if (packaging == XadesPackaging.Enveloping && digest == "SHA-256")
        {
            var standard = new SignedXml(doc);
            standard.LoadXml(signature);
            Assert.True(standard.CheckSignature(rsa), "The standard XMLDSig verifier must accept the enveloping signature");
        }
        var tamperedDoc = XadesXml.Parse(xml);
        if (packaging == XadesPackaging.Enveloping)
        {
            var obj = tamperedDoc.DocumentElement!.ChildNodes.OfType<XmlElement>()
                .Single(e => e.LocalName == "Object" && e.HasAttribute("Encoding"));
            obj.InnerText = Convert.ToBase64String(Encoding.UTF8.GetBytes("modified"));
        }
        var tamperedReferences = new Dictionary<string, byte[]> { ["document.txt"] = Encoding.UTF8.GetBytes("modified") };
        var tamperedReport = Assert.Single(new Validator().ValidateXades(Encoding.UTF8.GetBytes(tamperedDoc.OuterXml), tamperedReferences));
        Assert.Equal(Verdict.Invalid, tamperedReport.Verdict);
        if (level == XadesFormat.C)
        {
            Assert.Equal(2, doc.GetElementsByTagName("OCSPRef", XadesXml.Xades).Count);
            Assert.Equal(2, doc.GetElementsByTagName("CRLRef", XadesXml.Xades).Count);
            Assert.Equal(2, pki.CrlRequests);
            Assert.Equal(1, pki.OcspRequests);
            var refs = doc.GetElementsByTagName("OCSPRef", XadesXml.Xades).OfType<XmlElement>().ToArray();
            Assert.Equal(refs[0].OuterXml, refs[1].OuterXml);
        }
    }

    [Fact]
    public void Xades_detects_missing_files_signature_tampering_and_duplicate_ids_without_fetching_urls()
    {
        using var identity = new TestIdentity();
        using var pki = new FakePki(identity);
        using var files = new TestFiles();
        var path = files.Write("payload.txt", [1, 2, 3]);
        var xml = new XadesSigner(pki.Trust).Sign([path], XadesFormat.Bes, XadesPackaging.Detached,
            identity.Certificate, identity.Chain, identity.Sign);
        Assert.Equal(Verdict.Invalid, Assert.Single(new Validator().ValidateXades(xml, new Dictionary<string, byte[]>())).Verdict);
        var doc = XadesXml.Parse(xml);
        var signature = doc.DocumentElement!;
        var raw = Convert.FromBase64String(XadesXml.Child(signature, "SignatureValue").InnerText);
        raw[0] ^= 1;
        XadesXml.Child(signature, "SignatureValue").InnerText = Convert.ToBase64String(raw);
        var references = new Dictionary<string, byte[]> { ["payload.txt"] = [1, 2, 3] };
        var report = Assert.Single(new Validator().ValidateXades(Encoding.UTF8.GetBytes(doc.OuterXml), references));
        Assert.True(report.ContentIntact);
        Assert.False(report.SignatureValid);
        var duplicate = doc.CreateElement("duplicate");
        duplicate.SetAttribute("Id", XadesXml.Child(signature, "SignedInfo").GetAttribute("Id"));
        signature.AppendChild(duplicate);
        Assert.Equal(Verdict.Invalid, Assert.Single(new Validator().ValidateXades(Encoding.UTF8.GetBytes(doc.OuterXml), references)).Verdict);
        Assert.Equal(0, pki.TimestampRequests + pki.OcspRequests + pki.CrlRequests);
    }

    [Theory]
    [InlineData(XadesPackaging.Detached)]
    [InlineData(XadesPackaging.Enveloping)]
    public void Xades_multiple_documents_include_empty_data_without_ambiguous_object_ids(XadesPackaging packaging)
    {
        using var identity = new TestIdentity();
        using var pki = new FakePki(identity);
        using var files = new TestFiles();
        var first = files.Write("empty.txt", []);
        var second = files.Write("știință.txt", [0, 0x80, 0xff]);
        var xml = new XadesSigner(pki.Trust).Sign([first, second], XadesFormat.Bes, packaging,
            identity.Certificate, identity.Chain, identity.Sign);
        var references = new Dictionary<string, byte[]> { ["empty.txt"] = [], ["știință.txt"] = [0, 0x80, 0xff] };
        var report = Assert.Single(new Validator().ValidateXades(xml, references));
        Assert.True(report.ContentIntact, report.Notes);
        Assert.True(report.SignatureValid, report.Notes);
        var document = XadesXml.Parse(xml);
        var referenceElements = document.GetElementsByTagName("Reference", XadesXml.Ds).OfType<XmlElement>().ToArray();
        Assert.Equal(3, referenceElements.Length);
        Assert.Equal(3, referenceElements.Select(r => r.GetAttribute("URI")).Distinct(StringComparer.Ordinal).Count());
    }

    [Fact]
    public void Network_failure_after_signing_does_not_retry_PIN_or_mark_the_card_failed()
    {
        using var identity = new TestIdentity();
        using var files = new TestFiles();
        using var handler = new StatusHandler(HttpStatusCode.BadGateway);
        using var http = new HttpClient(handler);
        var sim = IdentityGuardTests.Simulator(identity.Certificate, CosmoXCardTests.SessionAfterAuthentication());
        sim.InternalAuthenticate = identity.Sign;
        var connects = 0;
        var service = new SigningService(reader =>
        {
            connects++;
            return new IdentityGuardTests.AuthenticatingTransport(sim, reader ?? "fixture reader");
        }, new TrustServices(http));
        var idle = new ReaderState.CardPresent("fixture reader", null);
        service.PublishReaderState(idle);
        var input = files.Write("input.pdf", MinimalPdf());
        var output = Path.Combine(files.DirectoryPath, "signed.pdf");
        var error = Assert.Throws<CardException>(() =>
            service.SignPdf(input, output, _ => ConsentResult.WithPin("0000")));
        Assert.Equal(CardErrorKind.Network, error.Kind);
        Assert.Equal(idle, service.ReaderState);
        Assert.Equal(1, connects);
        Assert.Equal(1, identity.SignCalls);
        Assert.Single(sim.Commands, command => command[1] == 0x20);
        Assert.Equal(2, handler.Count);
        Assert.False(File.Exists(output));
    }

    [Fact]
    public void Timestamps_parse_granted_status_retry_transient_HTTP_and_reject_wrong_imprints()
    {
        using var identity = new TestIdentity();
        using var pki = new FakePki(identity) { FailFirstTimestamp = true };
        var digest = SHA256.HashData([1, 2, 3]);
        var token = pki.Trust.GetTimestampToken(digest);
        Assert.Equal(2, pki.TimestampRequests);
        Assert.True(TrustServices.TimestampMatches(token, digest, out var time));
        Assert.NotNull(time);
        Assert.Equal(token, TrustServices.ParseTimestampResponse(
            SigningAsn.Sequence(SigningAsn.Sequence(SigningAsn.Integer(0)), token)));
        pki.WrongImprint = true;
        Assert.Equal(CardErrorKind.Network, Assert.Throws<CardException>(() => pki.Trust.GetTimestampToken(digest)).Kind);
        Assert.Equal(3, pki.TimestampRequests);
        var denied = SigningAsn.Sequence(SigningAsn.Sequence(SigningAsn.Integer(2)), token);
        Assert.Throws<AsnContentException>(() => TrustServices.ParseTimestampResponse(denied));
        Assert.Throws<ArgumentException>(() => pki.Trust.GetTimestampToken([0]));
    }

    [Fact]
    public void Ocsp_CertID_hashes_issuer_DER_name_and_public_key_bits_and_uses_leaf_serial()
    {
        using var identity = new TestIdentity();
        using var issuer = SigningAsn.Certificate(identity.Chain[0]);
        var request = RevocationData.OcspRequest(identity.Certificate, identity.Chain[0]);
        var certId = SigningAsn.Read(request).Children()[0].Children()[0].Children()[0].Children()[0].Children();
        Assert.Equal(SigningAsn.Sha1Oid, certId[0].Children()[0].ObjectIdentifier());
        Assert.Equal(SHA1.HashData(issuer.SubjectName.RawData), certId[1].Value);
        Assert.Equal(SHA1.HashData(issuer.GetPublicKey()), certId[2].Value);
        Assert.Equal(new System.Numerics.BigInteger([4, 5, 6], isUnsigned: true, isBigEndian: true), certId[3].Number());
    }

    [Theory]
    [InlineData(SigningAsn.Sha1Oid)]
    [InlineData("2.16.840.1.101.3.4.2.3")]
    public void Offline_timestamp_imprints_honor_the_token_hash_algorithm(string algorithm)
    {
        using var identity = new TestIdentity();
        using var pki = new FakePki(identity);
        byte[] data = [1, 2, 3];
        var digest = algorithm == SigningAsn.Sha1Oid ? SHA1.HashData(data) : SHA512.HashData(data);
        var token = pki.TimestampToken(digest, algorithm);
        Assert.True(TrustServices.TimestampMatchesData(token, data, out _));
        Assert.False(TrustServices.TimestampMatchesData(token, [1, 2, 4], out _));
    }

    [Theory]
    [InlineData(HttpStatusCode.BadRequest, 1)]
    [InlineData(HttpStatusCode.BadGateway, 2)]
    public void Permanent_HTTP_errors_are_not_retried_and_transient_errors_retry_once(HttpStatusCode status, int count)
    {
        using var handler = new StatusHandler(status);
        using var http = new HttpClient(handler);
        var trust = new TrustServices(http);
        Assert.Equal(CardErrorKind.Network, Assert.Throws<CardException>(() => trust.FetchCrl(new Uri("http://test.invalid/crl"))).Kind);
        Assert.Equal(count, handler.Count);
    }

    [Fact]
    public void Timestamp_imprint_tampering_is_invalid_without_claiming_TSA_or_revocation_authentication()
    {
        using var identity = new TestIdentity();
        using var pki = new FakePki(identity);
        using var files = new TestFiles();
        var path = files.Write("payload.txt", [4, 5, 6]);
        var xml = new XadesSigner(pki.Trust).Sign([path], XadesFormat.T, XadesPackaging.Enveloping,
            identity.Certificate, identity.Chain, identity.Sign);
        var doc = XadesXml.Parse(xml);
        doc.GetElementsByTagName("EncapsulatedTimeStamp", XadesXml.Xades)[0]!.InnerText =
            Convert.ToBase64String(pki.TimestampToken(new byte[32]));
        var report = Assert.Single(new Validator().ValidateXades(Encoding.UTF8.GetBytes(doc.OuterXml), new Dictionary<string, byte[]>()));
        Assert.True(report.ContentIntact);
        Assert.True(report.SignatureValid);
        Assert.False(report.TimestampImprintValid);
        Assert.Equal(Verdict.Invalid, report.Verdict);
        Assert.False(report.TimestampSignatureValidated);
        Assert.False(report.RevocationValidated);
    }

    internal static byte[] MinimalPdf(bool existingAcro = false)
    {
        var text = "%PDF-1.7\n";
        string[] bodies =
        [
            "<</Type/Catalog /Pages 2 0 R>>", "<</Type/Pages /Kids[3 0 R] /Count 1>>",
            "<</Type/Page /Parent 2 0 R /MediaBox[0 0 200 200] /Contents 4 0 R>>",
            "<</Length 5>>\nstream\nHello\nendstream",
        ];
        if (existingAcro)
        {
            bodies[0] = "<</Type/Catalog /Pages 2 0 R /AcroForm 5 0 R /ViewerPreferences<</HideToolbar true>>>>";
            bodies = [.. bodies, "<</Fields[6 0 R]/SigFlags 1 /NeedAppearances false>>", "<</FT/Tx /T(ExistingField)>>"];
        }
        var offsets = new List<int>();
        for (var i = 0; i < bodies.Length; i++)
        {
            offsets.Add(text.Length);
            text += $"{i + 1} 0 obj\n{bodies[i]}\nendobj\n";
        }
        var xref = text.Length;
        text += $"xref\n0 {bodies.Length + 1}\n0000000000 65535 f \n";
        foreach (var offset in offsets) text += $"{offset:D10} 00000 n \n";
        text += $"trailer\n<</Size {bodies.Length + 1} /Root 1 0 R>>\nstartxref\n{xref}\n%%EOF\n";
        return Encoding.Latin1.GetBytes(text);
    }

    private static byte[] ExtractCms(byte[] pdf)
    {
        var text = Encoding.Latin1.GetString(pdf);
        var match = System.Text.RegularExpressions.Regex.Match(text, @"/Contents<([a-f0-9]+)>");
        var bytes = Convert.FromHexString(match.Groups[1].Value);
        AsnDecoder.ReadEncodedValue(bytes, AsnEncodingRules.BER, out _, out _, out var consumed);
        return bytes[..consumed];
    }
    private static byte[] ExtractPdfContent(byte[] pdf)
    {
        var match = System.Text.RegularExpressions.Regex.Match(Encoding.Latin1.GetString(pdf), @"/ByteRange \[0 (\d+) (\d+) (\d+) \]");
        var a = int.Parse(match.Groups[1].Value, System.Globalization.CultureInfo.InvariantCulture);
        var b = int.Parse(match.Groups[2].Value, System.Globalization.CultureInfo.InvariantCulture);
        var c = int.Parse(match.Groups[3].Value, System.Globalization.CultureInfo.InvariantCulture);
        return [.. pdf.AsSpan(0, a), .. pdf.AsSpan(b, c)];
    }

    internal sealed class TestIdentity : IDisposable
    {
        internal RSA Key { get; } = RSA.Create(2048);
        internal X509Certificate2 PrivateCertificate { get; }
        internal byte[] Certificate => PrivateCertificate.RawData;
        internal IReadOnlyList<byte[]> Chain { get; }
        internal int SignCalls { get; private set; }
        internal TestIdentity()
        {
            using var rootKey = RSA.Create(2048);
            using var issuerKey = RSA.Create(2048);
            var now = DateTimeOffset.UtcNow;
            var rootRequest = Request("CN=Fixture Root,C=MD", rootKey, true);
            using var root = rootRequest.CreateSelfSigned(now.AddDays(-2), now.AddYears(10));
            var issuerRequest = Request("CN=Fixture Issuer,C=MD", issuerKey, true);
            AddCrl(issuerRequest);
            using var issuerPublic = issuerRequest.Create(root, now.AddDays(-1), now.AddYears(5), [1, 2, 3]);
            using var issuer = issuerPublic.CopyWithPrivateKey(issuerKey);
            var request = Request("CN=TEST SIGNER,C=MD", Key, false);
            AddCrl(request);
            using var leaf = request.Create(issuer, now.AddHours(-1), now.AddYears(1), [4, 5, 6]);
            PrivateCertificate = leaf.CopyWithPrivateKey(Key);
            Chain = [issuer.RawData, root.RawData];
        }
        private static CertificateRequest Request(string subject, RSA key, bool ca)
        {
            var request = new CertificateRequest(subject, key, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
            request.CertificateExtensions.Add(new X509BasicConstraintsExtension(ca, ca, ca ? 1 : 0, true));
            request.CertificateExtensions.Add(new X509KeyUsageExtension(ca
                ? X509KeyUsageFlags.KeyCertSign | X509KeyUsageFlags.CrlSign : X509KeyUsageFlags.DigitalSignature, true));
            return request;
        }
        private static void AddCrl(CertificateRequest request)
        {
            var name = SigningAsn.Encode(w => w.WriteCharacterString(UniversalTagNumber.IA5String,
                "http://pki.fixture.test/test.crl", new Asn1Tag(TagClass.ContextSpecific, 6)));
            request.CertificateExtensions.Add(new X509Extension("2.5.29.31",
                SigningAsn.Sequence(SigningAsn.Sequence(SigningAsn.Context(0, SigningAsn.Context(0, name)))), false));
        }
        internal byte[] Sign(byte[] info)
        {
            SignCalls++;
            var values = SigningAsn.Read(info).Children();
            var name = values[0].Children()[0].ObjectIdentifier() == SigningAsn.Sha1Oid ? HashAlgorithmName.SHA1 : HashAlgorithmName.SHA256;
            return Key.SignHash(values[1].Value, name, RSASignaturePadding.Pkcs1);
        }
        public void Dispose() { PrivateCertificate.Dispose(); Key.Dispose(); }
    }

    internal sealed class FakePki : HttpMessageHandler
    {
        private readonly TestIdentity _identity;
        private readonly HttpClient _http;
        internal TrustServices Trust { get; }
        internal int TimestampRequests { get; private set; }
        internal int OcspRequests { get; private set; }
        internal int CrlRequests { get; private set; }
        internal bool FailFirstTimestamp { get; set; }
        internal bool WrongImprint { get; set; }
        internal FakePki(TestIdentity identity)
        {
            _identity = identity;
            _http = new HttpClient(this, disposeHandler: false);
            Trust = new TrustServices(_http);
        }
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            byte[] response;
            if (request.RequestUri == TrustServices.TsaUri)
            {
                TimestampRequests++;
                Assert.Equal("application/timestamp-query", request.Content!.Headers.ContentType!.MediaType);
                if (FailFirstTimestamp && TimestampRequests == 1) return new HttpResponseMessage(HttpStatusCode.ServiceUnavailable);
                var fields = SigningAsn.Read(await request.Content.ReadAsByteArrayAsync(cancellationToken)).Children();
                Assert.Equal(System.Numerics.BigInteger.One, fields[0].Number());
                Assert.Equal((byte)0xff, fields[2].Value[0]); // certReq
                var digest = fields[1].Children()[1].Value;
                response = SigningAsn.Sequence(SigningAsn.Sequence(SigningAsn.Integer(1)),
                    TimestampToken(WrongImprint ? new byte[32] : digest));
            }
            else if (request.RequestUri == TrustServices.MdqSignOcspUri)
            {
                OcspRequests++;
                Assert.Equal("application/ocsp-request", request.Content!.Headers.ContentType!.MediaType);
                var requestBytes = await request.Content.ReadAsByteArrayAsync(cancellationToken);
                Assert.Equal(RevocationData.OcspRequest(_identity.Certificate, _identity.Chain[0]), requestBytes);
                response = OcspResponse();
            }
            else
            {
                CrlRequests++;
                Assert.Equal(HttpMethod.Get, request.Method);
                response = Crl();
            }
            return new HttpResponseMessage(HttpStatusCode.OK) { Content = new ByteArrayContent(response) };
        }
        internal byte[] TimestampToken(byte[] digest, string algorithm = SigningAsn.Sha256Oid)
        {
            var tst = SigningAsn.Sequence(SigningAsn.Integer(1), SigningAsn.Oid("1.2.3.4"),
                SigningAsn.Sequence(SigningAsn.Algorithm(algorithm), SigningAsn.Octet(digest)),
                SigningAsn.Integer(42), SigningAsn.Encode(w => w.WriteGeneralizedTime(DateTimeOffset.UtcNow, omitFractionalSeconds: true)));
            var cms = new SignedCms(new ContentInfo(new Oid("1.2.840.113549.1.9.16.1.4"), tst));
            var signer = new CmsSigner(SubjectIdentifierType.IssuerAndSerialNumber, _identity.PrivateCertificate)
                { IncludeOption = X509IncludeOption.EndCertOnly };
            cms.ComputeSignature(signer);
            return cms.Encode();
        }
        private byte[] Crl()
        {
            using var issuer = SigningAsn.Certificate(_identity.Chain[0]);
            var tbs = SigningAsn.Sequence(SigningAsn.Integer(1), SigningAsn.Algorithm("1.2.840.113549.1.1.11"),
                issuer.SubjectName.RawData, SigningAsn.Encode(w => w.WriteUtcTime(DateTimeOffset.UtcNow)),
                SigningAsn.Context(0, SigningAsn.Sequence(SigningAsn.Sequence(SigningAsn.Oid("2.5.29.20"),
                    SigningAsn.Octet(SigningAsn.Integer(7))))));
            return SigningAsn.Sequence(tbs, SigningAsn.Algorithm("1.2.840.113549.1.1.11"),
                SigningAsn.Encode(w => w.WriteBitString(_identity.Key.SignData(tbs, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1))));
        }
        private byte[] OcspResponse()
        {
            using var issuer = SigningAsn.Certificate(_identity.Chain[0]);
            var data = SigningAsn.Sequence(SigningAsn.Context(1, issuer.SubjectName.RawData),
                SigningAsn.Encode(w => w.WriteGeneralizedTime(DateTimeOffset.UtcNow, true)), SigningAsn.Sequence());
            var basic = SigningAsn.Sequence(data, SigningAsn.Algorithm("1.2.840.113549.1.1.11"),
                SigningAsn.Encode(w => w.WriteBitString(_identity.Key.SignData(data, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1))));
            return SigningAsn.Sequence([10, 1, 0], SigningAsn.Context(0,
                SigningAsn.Sequence(SigningAsn.Oid("1.3.6.1.5.5.7.48.1.1"), SigningAsn.Octet(basic))));
        }
        protected override void Dispose(bool disposing)
        {
            if (disposing) _http.Dispose();
            base.Dispose(disposing);
        }
    }

    internal sealed class TestFiles : IDisposable
    {
        internal string DirectoryPath { get; } = Path.Combine(Environment.CurrentDirectory, ".signing-test-" + Guid.NewGuid().ToString("N"));
        internal TestFiles() => Directory.CreateDirectory(DirectoryPath);
        internal string Write(string name, byte[] bytes)
        {
            var path = Path.Combine(DirectoryPath, name);
            File.WriteAllBytes(path, bytes);
            return path;
        }
        public void Dispose() => Directory.Delete(DirectoryPath, recursive: true);
    }
    private sealed class StatusHandler(HttpStatusCode status) : HttpMessageHandler
    {
        internal int Count { get; private set; }
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            Count++;
            return Task.FromResult(new HttpResponseMessage(status));
        }
    }
}
