/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.bouncycastle.crypto.Digest
 *  org.bouncycastle.crypto.digests.MD5Digest
 *  org.bouncycastle.crypto.digests.SHA1Digest
 *  org.bouncycastle.crypto.digests.SHA256Digest
 *  org.bouncycastle.crypto.digests.SHA512Digest
 *  org.bouncycastle.crypto.generators.PKCS5S2ParametersGenerator
 *  org.bouncycastle.crypto.params.KeyParameter
 *  org.bouncycastle.jce.provider.BouncyCastleProvider
 *  org.lwjgl.util.xxhash.XXH32State
 *  org.lwjgl.util.xxhash.XXHash
 *  org.slf4j.Logger
 */
package dorkbox.util.crypto;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.NoSuchAlgorithmException;
import java.security.Provider;
import java.security.Security;
import java.util.Arrays;
import java.util.Enumeration;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;
import javax.crypto.Cipher;
import org.bouncycastle.crypto.Digest;
import org.bouncycastle.crypto.digests.MD5Digest;
import org.bouncycastle.crypto.digests.SHA1Digest;
import org.bouncycastle.crypto.digests.SHA256Digest;
import org.bouncycastle.crypto.digests.SHA512Digest;
import org.bouncycastle.crypto.generators.PKCS5S2ParametersGenerator;
import org.bouncycastle.crypto.params.KeyParameter;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.lwjgl.util.xxhash.XXH32State;
import org.lwjgl.util.xxhash.XXHash;
import org.slf4j.Logger;

public final class Crypto {
    private static final byte[] CUSTOM_HEADER = new byte[]{-2, -54, -54, -98};

    private Crypto() {
    }

    public static void addProvider() {
        Provider provider = Security.getProvider("BC");
        if (provider == null) {
            Security.addProvider((Provider)new BouncyCastleProvider());
        }
    }

    public static boolean restrictedCryptography() {
        try {
            return Cipher.getMaxAllowedKeyLength("AES/CBC/PKCS5Padding") < Integer.MAX_VALUE;
        }
        catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("The transform \"AES/CBC/PKCS5Padding\" is not available (the availability of this algorithm is mandatory for Java SE implementations)", e);
        }
    }

    public static byte[] hashFileMD5(File file) {
        MD5Digest digest = new MD5Digest();
        return Crypto.hashFile(file, (Digest)digest, null);
    }

    public static byte[] hashFileSHA1(File file) {
        SHA1Digest digest = new SHA1Digest();
        return Crypto.hashFile(file, (Digest)digest, null);
    }

    public static byte[] hashFileSHA256(File file) {
        SHA256Digest digest = new SHA256Digest();
        return Crypto.hashFile(file, (Digest)digest, null);
    }

    public static byte[] hashFileSHA512(File file) {
        SHA512Digest digest = new SHA512Digest();
        return Crypto.hashFile(file, (Digest)digest, null);
    }

    public static byte[] hashFile(File file, Digest digest, Logger logger) {
        return Crypto.hashFile(file, digest, 0L, file.length(), logger);
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public static byte[] hashFile(File file, Digest digest, long startPosition, long endPosition, Logger logger) {
        if (file.isFile() && file.canRead()) {
            FileInputStream inputStream = null;
            try {
                inputStream = new FileInputStream(file);
                long skip = ((InputStream)inputStream).skip(startPosition);
                if (skip != startPosition) {
                    throw new RuntimeException("Unable to skip " + startPosition + " bytes. Only skippped " + skip + " instead");
                }
                long size = file.length() - startPosition;
                long lengthFromEnd = size - endPosition;
                if (lengthFromEnd > 0L && lengthFromEnd < size) {
                    size -= lengthFromEnd;
                }
                int bufferSize = 4096;
                byte[] buffer = new byte[bufferSize];
                digest.reset();
                while (size > 0L) {
                    int maxToRead = (int)Math.min((long)bufferSize, size);
                    int readBytes = ((InputStream)inputStream).read(buffer, 0, maxToRead);
                    size -= (long)readBytes;
                    if (readBytes == 0) {
                        byte[] byArray = null;
                        return byArray;
                    }
                    digest.update(buffer, 0, readBytes);
                }
            }
            catch (Exception e) {
                if (logger != null) {
                    logger.error("Error hashing file: {}", (Object)file.getAbsolutePath(), (Object)e);
                } else {
                    e.printStackTrace();
                }
            }
            finally {
                if (inputStream != null) {
                    try {
                        ((InputStream)inputStream).close();
                    }
                    catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
            byte[] digestBytes = new byte[digest.getDigestSize()];
            digest.doFinal(digestBytes, 0);
            return digestBytes;
        }
        return null;
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public static int xxHashFile(File file, long lengthFromEnd, Logger logger) {
        if (file.isFile() && file.canRead()) {
            FileInputStream inputStream = null;
            int seed = -1756908916;
            XXH32State state = XXHash.XXH32_createState();
            XXHash.XXH32_reset((XXH32State)state, (int)seed);
            try {
                inputStream = new FileInputStream(file);
                long size = file.length();
                if (lengthFromEnd > 0L && lengthFromEnd < size) {
                    size -= lengthFromEnd;
                }
                int bufferSize = 4096;
                byte[] buffer = new byte[bufferSize];
                ByteBuffer bbuffer = ByteBuffer.wrap(buffer);
                while (size > 0L) {
                    int maxToRead = (int)Math.min((long)bufferSize, size);
                    int readBytes = ((InputStream)inputStream).read(buffer, 0, maxToRead);
                    size -= (long)readBytes;
                    if (readBytes == 0) {
                        int n = 0;
                        return n;
                    }
                    bbuffer.limit(readBytes);
                    XXHash.XXH32_update((XXH32State)state, (ByteBuffer)bbuffer);
                }
            }
            catch (Exception e) {
                if (logger != null) {
                    logger.error("Error hashing file: {}", (Object)file.getAbsolutePath(), (Object)e);
                } else {
                    e.printStackTrace();
                }
            }
            finally {
                if (inputStream != null) {
                    try {
                        ((InputStream)inputStream).close();
                    }
                    catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
            return XXHash.XXH32_digest((XXH32State)state);
        }
        return 0;
    }

    static int toInt(byte[] bytes) {
        int number = 0;
        switch (bytes.length) {
            default: {
                number |= (bytes[3] & 0xFF) << 24;
            }
            case 3: {
                number |= (bytes[2] & 0xFF) << 16;
            }
            case 2: {
                number |= (bytes[1] & 0xFF) << 8;
            }
            case 1: 
        }
        return number |= (bytes[0] & 0xFF) << 0;
    }

    public static byte[] hashJarContentsExcludeAction(File jarDestFilename, Digest digest, int action) throws IOException {
        try (JarFile jarDestFile = new JarFile(jarDestFilename);){
            Enumeration<JarEntry> jarElements = jarDestFile.entries();
            byte[] buffer = new byte[2048];
            digest.reset();
            while (jarElements.hasMoreElements()) {
                int read2;
                boolean okToHash;
                JarEntry jarEntry = jarElements.nextElement();
                String name = jarEntry.getName();
                boolean bl = okToHash = !jarEntry.isDirectory();
                if (!okToHash) continue;
                okToHash = false;
                boolean hasAction = false;
                byte[] extraData = jarEntry.getExtra();
                if (extraData == null || extraData.length == 0) {
                    okToHash = false;
                } else if (extraData.length >= 4) {
                    for (int i = 0; i < CUSTOM_HEADER.length; ++i) {
                        if (extraData[i] == CUSTOM_HEADER[i]) continue;
                        throw new RuntimeException("Unexpected extra data in zip assigned. Aborting");
                    }
                    if (extraData[4] > 0) {
                        hasAction = true;
                        int fileAction = Crypto.toInt(new byte[]{extraData[5], extraData[6], extraData[7], extraData[8]});
                        if ((fileAction & action) != action) {
                            okToHash = true;
                        }
                    } else {
                        okToHash = true;
                    }
                } else {
                    throw new RuntimeException("Unexpected extra data in zip assigned. Aborting");
                }
                if (!okToHash) continue;
                byte[] bytes = name.getBytes(StandardCharsets.US_ASCII);
                digest.update(bytes, 0, bytes.length);
                if (hasAction) {
                    digest.update(extraData, 5, 4);
                }
                InputStream inputStream = jarDestFile.getInputStream(jarEntry);
                while ((read2 = inputStream.read(buffer)) > 0) {
                    digest.update(buffer, 0, read2);
                }
                inputStream.close();
            }
        }
        byte[] digestBytes = new byte[digest.getDigestSize()];
        digest.doFinal(digestBytes, 0);
        return digestBytes;
    }

    public static byte[] hashStream(Digest digest, InputStream inputStream) throws IOException {
        int read2;
        byte[] buffer = new byte[2048];
        digest.reset();
        while ((read2 = inputStream.read(buffer)) > 0) {
            digest.update(buffer, 0, read2);
        }
        inputStream.close();
        byte[] digestBytes = new byte[digest.getDigestSize()];
        digest.doFinal(digestBytes, 0);
        return digestBytes;
    }

    public static byte[] PBKDF2(char[] password, byte[] salt, int iterationCount) {
        byte[] charToBytes = Crypto.charToBytesPassword_UTF16(password);
        return Crypto.PBKDF2(charToBytes, salt, iterationCount);
    }

    public static byte[] PBKDF2(byte[] password, byte[] salt, int iterationCount) {
        SHA256Digest digest = new SHA256Digest();
        PKCS5S2ParametersGenerator pGen = new PKCS5S2ParametersGenerator((Digest)digest);
        pGen.init(password, salt, iterationCount);
        KeyParameter key = (KeyParameter)pGen.generateDerivedMacParameters(digest.getDigestSize() * 8);
        Arrays.fill(password, (byte)0);
        return key.getKey();
    }

    public static byte[] charToBytesPassword_UTF16(char[] password) {
        byte[] passwordBytes = new byte[password.length * 2];
        for (int i = 0; i < password.length; ++i) {
            passwordBytes[2 * i] = (byte)((password[i] & 0xFF00) >> 8);
            passwordBytes[2 * i + 1] = (byte)(password[i] & 0xFF);
        }
        Arrays.fill(password, '*');
        return passwordBytes;
    }
}

