/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.bouncycastle.bcpg.ArmoredOutputStream
 *  org.bouncycastle.bcpg.BCPGOutputStream
 *  org.bouncycastle.openpgp.PGPCompressedData
 *  org.bouncycastle.openpgp.PGPCompressedDataGenerator
 *  org.bouncycastle.openpgp.PGPEncryptedDataGenerator
 *  org.bouncycastle.openpgp.PGPException
 *  org.bouncycastle.openpgp.PGPLiteralDataGenerator
 *  org.bouncycastle.openpgp.PGPObjectFactory
 *  org.bouncycastle.openpgp.PGPPublicKey
 *  org.bouncycastle.openpgp.PGPPublicKeyRing
 *  org.bouncycastle.openpgp.PGPPublicKeyRingCollection
 *  org.bouncycastle.openpgp.PGPSecretKey
 *  org.bouncycastle.openpgp.PGPSecretKeyRing
 *  org.bouncycastle.openpgp.PGPSecretKeyRingCollection
 *  org.bouncycastle.openpgp.PGPSignatureGenerator
 *  org.bouncycastle.openpgp.PGPSignatureList
 *  org.bouncycastle.openpgp.PGPSignatureSubpacketGenerator
 *  org.bouncycastle.openpgp.PGPUtil
 *  org.bouncycastle.openpgp.operator.KeyFingerPrintCalculator
 *  org.bouncycastle.openpgp.operator.PBESecretKeyDecryptor
 *  org.bouncycastle.openpgp.operator.PGPContentSignerBuilder
 *  org.bouncycastle.openpgp.operator.PGPDataEncryptorBuilder
 *  org.bouncycastle.openpgp.operator.PGPDigestCalculatorProvider
 *  org.bouncycastle.openpgp.operator.PGPKeyEncryptionMethodGenerator
 *  org.bouncycastle.openpgp.operator.bc.BcKeyFingerprintCalculator
 *  org.bouncycastle.openpgp.operator.bc.BcPBESecretKeyDecryptorBuilder
 *  org.bouncycastle.openpgp.operator.bc.BcPGPContentSignerBuilder
 *  org.bouncycastle.openpgp.operator.bc.BcPGPDataEncryptorBuilder
 *  org.bouncycastle.openpgp.operator.bc.BcPGPDigestCalculatorProvider
 *  org.bouncycastle.openpgp.operator.bc.BcPublicKeyKeyEncryptionMethodGenerator
 */
package dorkbox.util.crypto;

import dorkbox.util.IO;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.Closeable;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.security.NoSuchProviderException;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.bouncycastle.bcpg.ArmoredOutputStream;
import org.bouncycastle.bcpg.BCPGOutputStream;
import org.bouncycastle.openpgp.PGPCompressedData;
import org.bouncycastle.openpgp.PGPCompressedDataGenerator;
import org.bouncycastle.openpgp.PGPEncryptedDataGenerator;
import org.bouncycastle.openpgp.PGPException;
import org.bouncycastle.openpgp.PGPLiteralDataGenerator;
import org.bouncycastle.openpgp.PGPObjectFactory;
import org.bouncycastle.openpgp.PGPPublicKey;
import org.bouncycastle.openpgp.PGPPublicKeyRing;
import org.bouncycastle.openpgp.PGPPublicKeyRingCollection;
import org.bouncycastle.openpgp.PGPSecretKey;
import org.bouncycastle.openpgp.PGPSecretKeyRing;
import org.bouncycastle.openpgp.PGPSecretKeyRingCollection;
import org.bouncycastle.openpgp.PGPSignatureGenerator;
import org.bouncycastle.openpgp.PGPSignatureList;
import org.bouncycastle.openpgp.PGPSignatureSubpacketGenerator;
import org.bouncycastle.openpgp.PGPUtil;
import org.bouncycastle.openpgp.operator.KeyFingerPrintCalculator;
import org.bouncycastle.openpgp.operator.PBESecretKeyDecryptor;
import org.bouncycastle.openpgp.operator.PGPContentSignerBuilder;
import org.bouncycastle.openpgp.operator.PGPDataEncryptorBuilder;
import org.bouncycastle.openpgp.operator.PGPDigestCalculatorProvider;
import org.bouncycastle.openpgp.operator.PGPKeyEncryptionMethodGenerator;
import org.bouncycastle.openpgp.operator.bc.BcKeyFingerprintCalculator;
import org.bouncycastle.openpgp.operator.bc.BcPBESecretKeyDecryptorBuilder;
import org.bouncycastle.openpgp.operator.bc.BcPGPContentSignerBuilder;
import org.bouncycastle.openpgp.operator.bc.BcPGPDataEncryptorBuilder;
import org.bouncycastle.openpgp.operator.bc.BcPGPDigestCalculatorProvider;
import org.bouncycastle.openpgp.operator.bc.BcPublicKeyKeyEncryptionMethodGenerator;

public final class CryptoPGP {
    private static final BcPGPDigestCalculatorProvider digestCalculatorProvider = new BcPGPDigestCalculatorProvider();
    private static final BcKeyFingerprintCalculator fingerprintCalculator = new BcKeyFingerprintCalculator();

    public static byte[] signGpgCompatible(InputStream privateKeyInputStream, String userId, char[] password, byte[] messageAsUtf8Bytes) throws PGPException {
        return CryptoPGP.sign(privateKeyInputStream, userId, password, new ByteArrayInputStream(messageAsUtf8Bytes), 0, false, true, false, false, false);
    }

    public static byte[] signGpgCompatible(InputStream privateKeyInputStream, String userId, char[] password, InputStream message) throws PGPException {
        return CryptoPGP.sign(privateKeyInputStream, userId, password, message, 0, false, true, false, false, false);
    }

    /*
     * Loose catch block
     * Enabled aggressive block sorting
     * Enabled unnecessary exception pruning
     * Enabled aggressive exception aggregation
     */
    public static void signGpgCompatible(InputStream privateKeyInputStream, String userId, char[] password, File file) throws PGPException {
        byte[] sign = CryptoPGP.sign(privateKeyInputStream, userId, password, file, 0, false, true, false, false, false);
        FileOutputStream fileOutputStream1 = null;
        try {
            fileOutputStream1 = new FileOutputStream(new File(file.getAbsolutePath() + ".asc"));
            fileOutputStream1.write(sign);
            fileOutputStream1.flush();
        }
        catch (FileNotFoundException e) {
            try {
                throw new PGPException("Unable to save signature to file " + file.getAbsolutePath() + ".asc", (Exception)e);
                catch (IOException e2) {
                    throw new PGPException("Unable to save signature to file " + file.getAbsolutePath() + ".asc", (Exception)e2);
                }
            }
            catch (Throwable throwable) {
                IO.close(fileOutputStream1);
                throw throwable;
            }
        }
        IO.close(fileOutputStream1);
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public static byte[] sign(InputStream privateKeyInputStream, String userId, char[] password, InputStream message, int signatureType, boolean compressSignature, boolean asciiArmoredOutput, boolean includeDataInSignature, boolean generateUserIdSubPacket, boolean generateOnePassVersion) throws PGPException {
        ByteArrayOutputStream byteArrayOutputStream;
        block22: {
            BCPGOutputStream bcOutputStream;
            List<PGPSecretKey> secretKeys = CryptoPGP.getSecretKeys(privateKeyInputStream, userId);
            PGPSignatureGenerator signature = CryptoPGP.createSignature(secretKeys, password, signatureType, generateUserIdSubPacket);
            ByteArrayOutputStream outputStream = byteArrayOutputStream = new ByteArrayOutputStream();
            if (asciiArmoredOutput) {
                outputStream = new ArmoredOutputStream((OutputStream)byteArrayOutputStream);
            }
            PGPCompressedDataGenerator compressedDataGenerator = null;
            if (compressSignature) {
                compressedDataGenerator = new PGPCompressedDataGenerator(2);
                try {
                    bcOutputStream = new BCPGOutputStream(compressedDataGenerator.open((OutputStream)outputStream));
                }
                catch (IOException e) {
                    throw new PGPException("Unable to open compression stream in the signature", (Exception)e);
                }
            } else {
                bcOutputStream = new BCPGOutputStream((OutputStream)outputStream);
            }
            if (generateOnePassVersion) {
                try {
                    signature.generateOnePassVersion(false).encode((OutputStream)bcOutputStream);
                }
                catch (IOException e) {
                    throw new PGPException("Unable to generate OnePass signature header", (Exception)e);
                }
            }
            PGPLiteralDataGenerator literalDataGenerator = null;
            OutputStream literalDataOutput = null;
            if (includeDataInSignature) {
                literalDataGenerator = new PGPLiteralDataGenerator();
                try {
                    literalDataOutput = literalDataGenerator.open((OutputStream)bcOutputStream, 'b', "_CONSOLE", (long)message.available(), new Date());
                }
                catch (IOException e1) {
                    throw new PGPException("Unable to generate Literal Data signature header", (Exception)e1);
                }
            }
            try {
                byte[] buffer = new byte[4096];
                if (literalDataOutput != null) {
                    int read2;
                    while ((read2 = message.read(buffer)) > 0) {
                        literalDataOutput.write(buffer, 0, read2);
                        signature.update(buffer, 0, read2);
                    }
                    literalDataOutput.flush();
                } else {
                    int read3;
                    while ((read3 = message.read(buffer)) > 0) {
                        signature.update(buffer, 0, read3);
                    }
                }
                if (literalDataGenerator != null) {
                    literalDataGenerator.close();
                }
                signature.generate().encode((OutputStream)bcOutputStream);
                if (compressedDataGenerator != null) {
                    compressedDataGenerator.close();
                }
                IO.close((Closeable)bcOutputStream);
            }
            catch (Exception e) {
                e.printStackTrace();
                break block22;
            }
            finally {
                IO.close((Closeable)bcOutputStream);
                IO.close(outputStream);
                IO.close(literalDataOutput);
            }
            IO.close(outputStream);
            IO.close(literalDataOutput);
        }
        return byteArrayOutputStream.toByteArray();
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public static byte[] sign(InputStream privateKeyInputStream, String userId, char[] password, File fileMessage, int signatureType, boolean compressSignature, boolean asciiArmoredOutput, boolean includeDataInSignature, boolean generateUserIdSubPacket, boolean generateOnePassVersion) throws PGPException {
        OutputStream literalDataOutput;
        BCPGOutputStream bcOutputStream;
        ByteArrayOutputStream outputStream;
        ByteArrayOutputStream byteArrayOutputStream;
        block20: {
            List<PGPSecretKey> secretKeys = CryptoPGP.getSecretKeys(privateKeyInputStream, userId);
            PGPSignatureGenerator signature = CryptoPGP.createSignature(secretKeys, password, signatureType, generateUserIdSubPacket);
            outputStream = byteArrayOutputStream = new ByteArrayOutputStream();
            if (asciiArmoredOutput) {
                outputStream = new ArmoredOutputStream((OutputStream)byteArrayOutputStream);
            }
            PGPCompressedDataGenerator compressedDataGenerator = null;
            if (compressSignature) {
                compressedDataGenerator = new PGPCompressedDataGenerator(2);
                try {
                    bcOutputStream = new BCPGOutputStream(compressedDataGenerator.open((OutputStream)outputStream));
                }
                catch (IOException e) {
                    throw new PGPException("Unable to open compression stream in the signature", (Exception)e);
                }
            } else {
                bcOutputStream = new BCPGOutputStream((OutputStream)outputStream);
            }
            if (generateOnePassVersion) {
                try {
                    signature.generateOnePassVersion(false).encode((OutputStream)bcOutputStream);
                }
                catch (IOException e) {
                    throw new PGPException("Unable to generate OnePass signature header", (Exception)e);
                }
            }
            PGPLiteralDataGenerator literalDataGenerator = null;
            literalDataOutput = null;
            if (includeDataInSignature) {
                literalDataGenerator = new PGPLiteralDataGenerator();
                try {
                    literalDataOutput = literalDataGenerator.open((OutputStream)bcOutputStream, 'b', fileMessage);
                }
                catch (IOException e1) {
                    throw new PGPException("Unable to generate Literal Data signature header", (Exception)e1);
                }
            }
            try {
                FileInputStream fileInputStream = new FileInputStream(fileMessage);
                byte[] buffer = new byte[4096];
                if (literalDataOutput != null) {
                    int read2;
                    while ((read2 = fileInputStream.read(buffer)) > 0) {
                        literalDataOutput.write(buffer, 0, read2);
                        signature.update(buffer, 0, read2);
                    }
                    literalDataOutput.flush();
                } else {
                    int read3;
                    while ((read3 = fileInputStream.read(buffer)) > 0) {
                        signature.update(buffer, 0, read3);
                    }
                }
                if (literalDataGenerator != null) {
                    literalDataGenerator.close();
                }
                signature.generate().encode((OutputStream)bcOutputStream);
                if (compressedDataGenerator == null) break block20;
                compressedDataGenerator.close();
            }
            catch (Exception e) {
                try {
                    e.printStackTrace();
                }
                catch (Throwable throwable) {
                    IO.close((Closeable)bcOutputStream);
                    IO.close(outputStream);
                    IO.close(literalDataOutput);
                    throw throwable;
                }
                IO.close((Closeable)bcOutputStream);
                IO.close(outputStream);
                IO.close(literalDataOutput);
            }
        }
        IO.close((Closeable)bcOutputStream);
        IO.close(outputStream);
        IO.close(literalDataOutput);
        return byteArrayOutputStream.toByteArray();
    }

    public static List<PGPSecretKey> getSecretKeys(InputStream inputStream, String userId) throws PGPException {
        PGPSecretKeyRingCollection secretKeyRings;
        try {
            secretKeyRings = new PGPSecretKeyRingCollection(PGPUtil.getDecoderStream((InputStream)inputStream), (KeyFingerPrintCalculator)fingerprintCalculator);
        }
        catch (IOException e) {
            throw new PGPException("No private key found in stream!", (Exception)e);
        }
        finally {
            IO.close(inputStream);
        }
        Iterator secretKeys = secretKeyRings.getKeyRings(userId);
        ArrayList<PGPSecretKey> pgpSecretKeys = new ArrayList<PGPSecretKey>();
        while (secretKeys.hasNext()) {
            PGPSecretKeyRing secretKeyRing = (PGPSecretKeyRing)secretKeys.next();
            PGPSecretKey tmpKey = secretKeyRing.getSecretKey();
            if (tmpKey == null) continue;
            pgpSecretKeys.add(tmpKey);
        }
        if (!pgpSecretKeys.isEmpty()) {
            return pgpSecretKeys;
        }
        throw new PGPException("No private key found in stream!");
    }

    private static PGPSignatureGenerator createSignature(List<PGPSecretKey> secretKeys, char[] password, int signatureType, boolean generateUserIdSubPacket) throws PGPException {
        PGPSecretKey secretKey = null;
        for (int i = 0; i < secretKeys.size(); ++i) {
            secretKey = secretKeys.get(i);
            if (secretKey.isSigningKey() && secretKey.isMasterKey()) continue;
            secretKey = null;
        }
        if (secretKey == null) {
            throw new PGPException("Secret key is not the signing master key");
        }
        if (password == null) {
            password = new char[]{};
        }
        PBESecretKeyDecryptor build = new BcPBESecretKeyDecryptorBuilder((PGPDigestCalculatorProvider)digestCalculatorProvider).build(password);
        SecureRandom random = new SecureRandom();
        BcPGPContentSignerBuilder bcPGPContentSignerBuilder = new BcPGPContentSignerBuilder(secretKey.getPublicKey().getAlgorithm(), 2).setSecureRandom(random);
        PGPSignatureGenerator signature = new PGPSignatureGenerator((PGPContentSignerBuilder)bcPGPContentSignerBuilder);
        signature.init(signatureType, secretKey.extractPrivateKey(build));
        Iterator userIds = secretKey.getPublicKey().getUserIDs();
        if (userIds.hasNext()) {
            if (generateUserIdSubPacket) {
                PGPSignatureSubpacketGenerator subpacketGenerator = new PGPSignatureSubpacketGenerator();
                subpacketGenerator.addSignerUserID(false, (String)userIds.next());
                signature.setHashedSubpackets(subpacketGenerator.generate());
            } else {
                signature.setHashedSubpackets(null);
            }
            return signature;
        }
        throw new PGPException("Did not find specified userId");
    }

    public static PGPPublicKeyRing getKeyring(InputStream keyBlockStream) throws IOException {
        BcKeyFingerprintCalculator keyfp = new BcKeyFingerprintCalculator();
        PGPObjectFactory factory = new PGPObjectFactory(PGPUtil.getDecoderStream((InputStream)keyBlockStream), (KeyFingerPrintCalculator)keyfp);
        Object o = factory.nextObject();
        if (o instanceof PGPPublicKeyRing) {
            return (PGPPublicKeyRing)o;
        }
        throw new IllegalArgumentException("Input stream does not contain a PGP Public Key");
    }

    public static PGPPublicKey getEncryptionKey(PGPPublicKeyRing keyRing) {
        if (keyRing == null) {
            return null;
        }
        Iterator keys = keyRing.getPublicKeys();
        while (keys.hasNext()) {
            PGPPublicKey key = (PGPPublicKey)keys.next();
            if (!key.isEncryptionKey()) continue;
            return key;
        }
        return null;
    }

    public PGPSecretKey getDecryptionKey(PGPSecretKeyRing keyRing) {
        if (keyRing == null) {
            return null;
        }
        Iterator keys = keyRing.getSecretKeys();
        while (keys.hasNext()) {
            PGPSecretKey key = (PGPSecretKey)keys.next();
            if (!key.isMasterKey()) continue;
            return key;
        }
        return null;
    }

    /*
     * Loose catch block
     * Enabled aggressive block sorting
     * Enabled unnecessary exception pruning
     * Enabled aggressive exception aggregation
     */
    private String encrypt(InputStream publicKeyInputStream, String message) throws PGPException, IOException, NoSuchProviderException {
        PGPPublicKey publicKey = CryptoPGP.findPublicGPGKey(publicKeyInputStream);
        if (publicKey == null) {
            System.err.println("Did not find public GPG key");
            return null;
        }
        byte[] utf8Bytes = message.getBytes(StandardCharsets.UTF_8);
        ByteArrayOutputStream compressedOutput = new ByteArrayOutputStream();
        PGPLiteralDataGenerator literalDataGenerator = new PGPLiteralDataGenerator();
        PGPCompressedDataGenerator compressedDataGenerator = new PGPCompressedDataGenerator(1);
        try {
            OutputStream literalDataOutput = literalDataGenerator.open((OutputStream)compressedOutput, 'b', "_CONSOLE", (long)utf8Bytes.length, new Date());
            literalDataOutput.write(utf8Bytes);
        }
        catch (IOException e) {
            throw e;
        }
        finally {
            compressedDataGenerator.close();
            IO.close(compressedOutput);
        }
        SecureRandom random = new SecureRandom();
        byte[] compressedBytes = compressedOutput.toByteArray();
        BcPGPDataEncryptorBuilder bcPGPDataEncryptorBuilder = new BcPGPDataEncryptorBuilder(3).setWithIntegrityPacket(true).setSecureRandom(random);
        PGPEncryptedDataGenerator encryptedDataGenerator = new PGPEncryptedDataGenerator((PGPDataEncryptorBuilder)bcPGPDataEncryptorBuilder);
        BcPublicKeyKeyEncryptionMethodGenerator encKeyGen = new BcPublicKeyKeyEncryptionMethodGenerator(publicKey).setSecureRandom(random);
        encryptedDataGenerator.addMethod((PGPKeyEncryptionMethodGenerator)encKeyGen);
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        ArmoredOutputStream armoredOut = new ArmoredOutputStream((OutputStream)byteArrayOutputStream);
        OutputStream encryptedOutput = null;
        try {
            encryptedOutput = encryptedDataGenerator.open((OutputStream)armoredOut, (long)compressedBytes.length);
            encryptedOutput.write(compressedBytes);
        }
        catch (IOException e) {
            try {
                throw e;
                catch (PGPException e2) {
                    throw e2;
                }
            }
            catch (Throwable throwable) {
                IO.close(encryptedOutput);
                IO.close((Closeable)armoredOut);
                throw throwable;
            }
        }
        IO.close(encryptedOutput);
        IO.close((Closeable)armoredOut);
        String encrypted = new String(byteArrayOutputStream.toByteArray());
        System.err.println("Message: " + message);
        System.err.println("Encrypted: " + encrypted);
        return encrypted;
    }

    private static PGPPublicKey findPublicGPGKey(InputStream inputStream) throws IOException, PGPException {
        PGPPublicKeyRingCollection publicKeyRingCollection = new PGPPublicKeyRingCollection(PGPUtil.getDecoderStream((InputStream)inputStream), (KeyFingerPrintCalculator)fingerprintCalculator);
        System.err.println("key ring size: " + publicKeyRingCollection.size());
        Iterator keyRingIter = publicKeyRingCollection.getKeyRings();
        while (keyRingIter.hasNext()) {
            PGPPublicKey tmpKey;
            PGPPublicKeyRing keyRing = (PGPPublicKeyRing)keyRingIter.next();
            Iterator keyIter = keyRing.getPublicKeys();
            while (keyIter.hasNext() && (tmpKey = (PGPPublicKey)keyIter.next()) != null) {
                Iterator userIDs = tmpKey.getUserIDs();
                ArrayList<String> strings = new ArrayList<String>();
                while (userIDs.hasNext()) {
                    String next = (String)userIDs.next();
                    strings.add(next);
                }
                System.err.println("Encryption key = " + tmpKey.isEncryptionKey() + ", Master key = " + tmpKey.isMasterKey() + ", UserId = " + strings);
                if (!tmpKey.isEncryptionKey() || !tmpKey.isMasterKey()) continue;
                return tmpKey;
            }
        }
        throw new PGPException("No public key found!");
    }

    private static void verify(InputStream publicKeyInputStream, byte[] signature) throws Exception {
        PGPPublicKey publicKey = CryptoPGP.findPublicGPGKey(publicKeyInputStream);
        String text = new String(signature);
        Pattern regex = Pattern.compile("-----BEGIN PGP SIGNED MESSAGE-----\\r?\\n.*?\\r?\\n\\r?\\n(.*)\\r?\\n(-----BEGIN PGP SIGNATURE-----\\r?\\n.*-----END PGP SIGNATURE-----)", 160);
        Matcher regexMatcher = regex.matcher(text);
        if (regexMatcher.find()) {
            Object o;
            String dataText = regexMatcher.group(1);
            String signText = regexMatcher.group(2);
            ByteArrayInputStream dataIn = new ByteArrayInputStream(dataText.getBytes("UTF8"));
            ByteArrayInputStream signIn = new ByteArrayInputStream(signText.getBytes("UTF8"));
            InputStream signIn2 = PGPUtil.getDecoderStream((InputStream)signIn);
            PGPObjectFactory pgpFact = new PGPObjectFactory(signIn2, (KeyFingerPrintCalculator)new BcKeyFingerprintCalculator());
            PGPSignatureList p3 = null;
            try {
                o = pgpFact.nextObject();
                if (o == null) {
                    throw new Exception();
                }
            }
            catch (Exception ex) {
                throw new Exception("Invalid input data");
            }
            if (o instanceof PGPCompressedData) {
                PGPCompressedData c1 = (PGPCompressedData)o;
                pgpFact = new PGPObjectFactory(c1.getDataStream(), (KeyFingerPrintCalculator)new BcKeyFingerprintCalculator());
                p3 = (PGPSignatureList)pgpFact.nextObject();
            } else {
                p3 = (PGPSignatureList)o;
            }
        }
    }

    private CryptoPGP() {
    }

    public static void main(String[] args) throws Exception {
        FileInputStream privateKeyInputStream = new FileInputStream(new File("/home/user/dorkbox/sonatype_private.key"));
        byte[] textBytes = "hello".getBytes(StandardCharsets.UTF_8);
        byte[] bytes = CryptoPGP.signGpgCompatible((InputStream)privateKeyInputStream, "Dorkbox <sonatype@dorkbox.com>", new char[0], textBytes);
        FileOutputStream fileOutputStream = new FileOutputStream(new File("/home/user/dorkbox/hello2.txt"));
        fileOutputStream.write(textBytes);
        fileOutputStream.flush();
        IO.close(fileOutputStream);
        FileOutputStream fileOutputStream1 = new FileOutputStream(new File("/home/user/dorkbox/hello2.txt.asc"));
        fileOutputStream1.write(bytes);
        fileOutputStream1.flush();
        IO.close(fileOutputStream1);
    }
}

