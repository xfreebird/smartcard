using MoldSign.Core;
using MoldSign.Core.Protection;
using System.Security.Cryptography.X509Certificates;
namespace MoldSign.Cli;

internal static class FileProtectionCommand
{
    internal static bool Handles(string? command)=>command is "encrypt" or "decrypt" or "encryption-certs" or "remove-file";
    internal static int Run(IReadOnlyList<string> arguments,CliHost host)
    {
        try {
            var command=arguments[0];var args=arguments.Skip(1).ToList();
            string? Take(string option){var i=args.IndexOf(option);if(i<0)return null;if(i+1>=args.Count)throw new UsageException("Missing option value.");var value=args[i+1];args.RemoveRange(i,2);return value;}
            bool Flag(string option){var found=args.Remove(option);return found;}
            var exportPath=Take("--out");if(exportPath!=null && command!="encryption-certs")throw new UsageException("--out is only supported by encryption-certs.");
            var reader=Take("--reader");var certPath=Take("--certificate");var fingerprint=Take("--card");
            var stdin=Flag("--password-stdin");var pinStdin=Flag("--pin-stdin");var confirmed=Flag("--confirm-removal");Flag("--quiet");
            if(args.Any(a=>a.StartsWith("--",StringComparison.Ordinal)))throw new UsageException("Unsupported option. Secrets are never accepted as command arguments.");
            var service=new SigningService(()=>host.Cards.Connect(reader));
            if(command=="encryption-certs") {
                if(args.Count!=0 || certPath!=null || (fingerprint==null)!=(exportPath==null) || stdin || pinStdin || confirmed)throw new UsageException("Use encryption-certs [--reader NAME] [--card SHA256 --out NEW-CERTIFICATE.cer].");
                var identities=service.EncryptionIdentities(reader);
                if(exportPath!=null && fingerprint!=null) {
                    if(fingerprint.Length!=64 || !fingerprint.All(Uri.IsHexDigit))throw new UsageException("Expected a full SHA-256 fingerprint.");
                    var selected=identities.SingleOrDefault(i=>i.Fingerprint.Equals(fingerprint,StringComparison.OrdinalIgnoreCase))??throw new UsageException("Selected encryption certificate not found.");
                    ProtectedFileIO.SaveNew(exportPath,selected.Certificate);host.Out.WriteLine("Exported public encryption certificate.");return 0;
                }
                foreach(var identity in identities)host.Out.WriteLine($"{identity.Fingerprint}  {identity.Label}");
                return 0;
            }
            if(command=="remove-file") {
                if(args.Count!=1 || !confirmed || certPath!=null || fingerprint!=null || stdin || pinStdin)throw new UsageException("Use remove-file PATH --confirm-removal. SSD remnants, snapshots and other copies may remain.");
                ProtectedFileIO.OverwriteAndRemove(args[0]);host.Out.WriteLine("Removed. Other copies and physical remnants may remain.");return 0;
            }
            if(args.Count!=2 || confirmed || (certPath!=null && fingerprint!=null) || (stdin && (certPath!=null || fingerprint!=null)) || (command=="decrypt" && certPath!=null) || (pinStdin && (fingerprint==null || command!="decrypt")))throw new UsageException("Use encrypt|decrypt INPUT NEW-OUTPUT [--password-stdin | --card SHA256]; encryption also accepts --certificate DER.");
            if(File.Exists(args[1]))throw new IOException("Destination exists; choose a new filename.");
            var input=ProtectedFileIO.Read(args[0]);byte[] output;
            if(certPath!=null) {
                using var cert=X509CertificateLoader.LoadCertificate(ProtectedFileIO.Read(certPath));output=CertificateFileProtection.Encrypt(input,cert);
            } else if(fingerprint!=null) {
                if(fingerprint.Length!=64 || !fingerprint.All(Uri.IsHexDigit))throw new UsageException("Expected the encryption certificate SHA-256 fingerprint.");
                var identity=service.EncryptionIdentities(reader).SingleOrDefault(i=>i.Fingerprint.Equals(fingerprint,StringComparison.OrdinalIgnoreCase))??throw new CardException(CardErrorKind.CardChanged,"Selected encryption identity not found.");
                if(command=="encrypt") {using var cert=X509CertificateLoader.LoadCertificate(identity.Certificate);output=CertificateFileProtection.Encrypt(input,cert);}
                else {
                    var pin=pinStdin?host.In.ReadLine():host.GetEnvironmentVariable("MSIGN_PIN");
                    if(string.IsNullOrEmpty(pin)) {if(host.IsInputRedirected())throw new UsageException("Use --pin-stdin for unattended input.");pin=host.PromptHidden("Card PIN: ");}
                    if(string.IsNullOrEmpty(pin))throw new UsageException("Card authorization cancelled.");
                    try{output=service.DecryptFile(input,identity,pin,reader);}finally{pin="";}
                }
            } else {
                string Secret(string prompt){if(stdin)return host.In.ReadLine()??"";if(host.IsInputRedirected())throw new UsageException("Use --password-stdin for non-interactive input.");return host.PromptHidden(prompt)??"";}
                var password=Secret("File password: ");
                try {
                    if(command=="encrypt") {if(!stdin && Secret("Confirm file password: ")!=password)throw new UsageException("Passwords do not match.");output=PasswordFileProtection.Encrypt(input,password);}
                    else output=PasswordFileProtection.Decrypt(input,password);
                } finally {password="";}
            }
            ProtectedFileIO.SaveNew(args[1],output);host.Out.WriteLine($"Saved: {Path.GetFullPath(args[1])}");
            if(command=="decrypt")host.Error.WriteLine("Check the decrypted content before using it. MoldSign-compatible CBC does not authenticate content or reliably detect wrong passwords.");
            return 0;
        } catch(CardException e){host.Error.WriteLine(e.Message);return ExitCodes.For(e);}
        catch(Exception e){host.Error.WriteLine(e.Message);return ExitCodes.UsageOrUnexpected;}
    }
}
