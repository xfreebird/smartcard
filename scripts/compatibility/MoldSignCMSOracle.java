import java.nio.file.*;
import java.io.*;
import java.security.*;
import java.security.spec.*;
import java.util.Arrays;
import iaik.asn1.structures.AlgorithmID;
import iaik.cms.*;

/** Uses the exact IAIK CMS implementation and parameters shipped by MoldSign.
 * A synthetic RSA fixture substitutes for hardware; this does not prove card transport. */
public final class MoldSignCMSOracle {
    public static void main(String[] args) throws Exception {
        Security.addProvider(new iaik.security.provider.IAIK());
        Path root = Path.of(args[1]);
        byte[] plain = Files.readAllBytes(root.resolve("plain-1024.bin"));
        var certificate = new iaik.x509.X509Certificate(Files.readAllBytes(root.resolve("test-recipient.der")));
        var key = KeyFactory.getInstance("RSA").generatePrivate(new PKCS8EncodedKeySpec(Files.readAllBytes(root.resolve("test-private-key.pk8"))));
        if (args[0].equals("generate")) {
            var envelope = new EnvelopedDataStream(new ByteArrayInputStream(plain), (AlgorithmID)AlgorithmID.aes128_CBC.clone());
            envelope.setRecipientInfos(new RecipientInfo[]{new KeyTransRecipientInfo(certificate, 0, AlgorithmID.rsaEncryption)});
            try(var out = Files.newOutputStream(root.resolve("vendor-certificate.asymmetric.p7m"))) { envelope.writeTo(out); }
        }
        Path input = root.resolve(args[0].equals("generate") ? "vendor-certificate.asymmetric.p7m" : "native-certificate.asymmetric.p7m");
        try (var in = Files.newInputStream(input)) {
            var envelope = new EnvelopedDataStream(in);
            envelope.setupCipher(key, 0);
            if (!Arrays.equals(plain, envelope.getInputStream().readAllBytes())) throw new AssertionError("Plaintext mismatch");
        }
        System.out.println("Vendor CMS interoperability passed: " + args[0]);
    }
}
