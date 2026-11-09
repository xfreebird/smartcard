import java.nio.file.*;
import java.util.Arrays;
import md.cts.pkcs11.providers.workers.EncryptCMSSymmetricWorker;
import md.cts.pkcs11.providers.workers.DecryptCMSSymmetricWorker;

/** Calls the installed vendor implementation, not a reimplementation of its format.
 * Synthetic fixtures only. Passwords are test constants and never card PINs. */
public final class MoldSignEncryptionOracle {
    public static final String PASSWORD = "Test-șț-🔐-2026";
    public static void main(String[] args) throws Exception {
        Path root = Path.of(args[1]);
        Files.createDirectories(root);
        if (args[0].equals("generate-legacy")) {
            java.security.Security.addProvider(new iaik.security.provider.IAIK());
            for (String algorithm : new String[]{"3_KeyTripleDES_CBC", "DES_CBC", "RC2_CBC"}) {
                for (int length : new int[]{0, 1, 15, 16, 17, 1024}) {
                    Path source = root.resolve("plain-" + length + ".bin");
                    Path output = root.resolve("vendor-legacy-" + algorithm + "-" + length + ".p7m");
                    new EncryptCMSSymmetricWorker(source.toString(), output.toString(), algorithm, "Legacy-Test-2026".toCharArray()).call();
                    Path decoded = root.resolve("oracle-decoded.bin");
                    new DecryptCMSSymmetricWorker(output.toString(), decoded.toString(), "Legacy-Test-2026".toCharArray()).call();
                    if (!Arrays.equals(Files.readAllBytes(source), Files.readAllBytes(decoded))) throw new AssertionError(output);
                    Files.delete(decoded);
                }
            }
        } else if (args[0].equals("generate")) {
            for (int length : new int[]{0, 1, 15, 16, 17, 1024}) {
                byte[] plain = new byte[length];
                for (int i = 0; i < length; i++) plain[i] = (byte)(i * 37);
                Path source = root.resolve("plain-" + length + ".bin");
                Files.write(source, plain);
                for (int bits : new int[]{128, 192, 256}) {
                    Path output = root.resolve("vendor-" + bits + "-" + length + ".symmetric.p7m");
                    new EncryptCMSSymmetricWorker(source.toString(), output.toString(), bits + "bit_AES", PASSWORD.toCharArray()).call();
                    Path decoded = root.resolve("oracle-decoded.bin");
                    new DecryptCMSSymmetricWorker(output.toString(), decoded.toString(), PASSWORD.toCharArray()).call();
                    if (!Arrays.equals(plain, Files.readAllBytes(decoded))) throw new AssertionError(output);
                    Files.delete(decoded);
                }
            }
        } else if (args[0].equals("verify")) {
            try (var files = Files.list(root)) {
                for (Path file : files.filter(p -> p.getFileName().toString().matches("native-[0-9]+\\.symmetric\\.p7m")).toList()) {
                    int length = Integer.parseInt(file.getFileName().toString().split("-")[1].split("\\.")[0]);
                    Path decoded = root.resolve("oracle-decoded.bin");
                    new DecryptCMSSymmetricWorker(file.toString(), decoded.toString(), PASSWORD.toCharArray()).call();
                    if (!Arrays.equals(Files.readAllBytes(root.resolve("plain-" + length + ".bin")), Files.readAllBytes(decoded))) throw new AssertionError(file);
                    Files.delete(decoded);
                }
            }
        } else throw new IllegalArgumentException("generate|verify DIRECTORY");
        System.out.println("Vendor interoperability passed: " + args[0]);
    }
}
