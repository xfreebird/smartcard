/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.bouncycastle.crypto.BufferedBlockCipher
 *  org.bouncycastle.crypto.CipherParameters
 *  org.bouncycastle.crypto.modes.GCMBlockCipher
 *  org.bouncycastle.crypto.params.KeyParameter
 *  org.bouncycastle.crypto.params.ParametersWithIV
 *  org.slf4j.Logger
 */
package dorkbox.util.crypto;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import org.bouncycastle.crypto.BufferedBlockCipher;
import org.bouncycastle.crypto.CipherParameters;
import org.bouncycastle.crypto.modes.GCMBlockCipher;
import org.bouncycastle.crypto.params.KeyParameter;
import org.bouncycastle.crypto.params.ParametersWithIV;
import org.slf4j.Logger;

public final class CryptoAES {
    private static final int ivSize = 16;

    public static byte[] encryptWithIV(GCMBlockCipher aesEngine, byte[] aesKey, byte[] aesIV, byte[] data, Logger logger) {
        byte[] encryptAES = CryptoAES.encrypt(aesEngine, aesKey, aesIV, data, logger);
        int length = encryptAES.length;
        byte[] out = new byte[length + 16];
        System.arraycopy(aesIV, 0, out, 0, 16);
        System.arraycopy(encryptAES, 0, out, 16, length);
        return out;
    }

    @Deprecated
    public static byte[] encryptWithIV(BufferedBlockCipher aesEngine, byte[] aesKey, byte[] aesIV, byte[] data, Logger logger) {
        byte[] encryptAES = CryptoAES.encrypt(aesEngine, aesKey, aesIV, data, logger);
        int length = encryptAES.length;
        byte[] out = new byte[length + 16];
        System.arraycopy(aesIV, 0, out, 0, 16);
        System.arraycopy(encryptAES, 0, out, 16, length);
        return out;
    }

    public static boolean encryptStreamWithIV(GCMBlockCipher aesEngine, byte[] aesKey, byte[] aesIV, InputStream in, OutputStream out, Logger logger) {
        try {
            out.write(aesIV);
        }
        catch (IOException e) {
            if (logger != null) {
                logger.error("Unable to perform AES cipher.", (Throwable)e);
            }
            return false;
        }
        return CryptoAES.encryptStream(aesEngine, aesKey, aesIV, in, out, logger);
    }

    @Deprecated
    public static boolean encryptStreamWithIV(BufferedBlockCipher aesEngine, byte[] aesKey, byte[] aesIV, InputStream in, OutputStream out, Logger logger) {
        try {
            out.write(aesIV);
        }
        catch (IOException e) {
            if (logger != null) {
                logger.error("Unable to perform AES cipher.", (Throwable)e);
            }
            return false;
        }
        return CryptoAES.encryptStream(aesEngine, aesKey, aesIV, in, out, logger);
    }

    public static byte[] encrypt(GCMBlockCipher aesEngine, byte[] aesKey, byte[] aesIV, byte[] data, Logger logger) {
        int length = data.length;
        ParametersWithIV aesIVAndKey = new ParametersWithIV((CipherParameters)new KeyParameter(aesKey), aesIV);
        return CryptoAES.encrypt(aesEngine, (CipherParameters)aesIVAndKey, data, length, logger);
    }

    public static byte[] encrypt(GCMBlockCipher aesEngine, CipherParameters aesIVAndKey, byte[] data, int length, Logger logger) {
        aesEngine.reset();
        aesEngine.init(true, aesIVAndKey);
        int minSize = aesEngine.getOutputSize(length);
        byte[] outArray = new byte[minSize];
        int actualLength = aesEngine.processBytes(data, 0, length, outArray, 0);
        try {
            actualLength += aesEngine.doFinal(outArray, actualLength);
        }
        catch (Exception e) {
            if (logger != null) {
                logger.error("Unable to perform AES cipher.", (Throwable)e);
            }
            return new byte[0];
        }
        if (outArray.length == actualLength) {
            return outArray;
        }
        byte[] result = new byte[actualLength];
        System.arraycopy(outArray, 0, result, 0, result.length);
        return result;
    }

    @Deprecated
    public static byte[] encrypt(BufferedBlockCipher aesEngine, byte[] aesKey, byte[] aesIV, byte[] data, Logger logger) {
        int length = data.length;
        ParametersWithIV aesIVAndKey = new ParametersWithIV((CipherParameters)new KeyParameter(aesKey), aesIV);
        aesEngine.reset();
        aesEngine.init(true, (CipherParameters)aesIVAndKey);
        int minSize = aesEngine.getOutputSize(length);
        byte[] outBuf = new byte[minSize];
        int actualLength = aesEngine.processBytes(data, 0, length, outBuf, 0);
        try {
            actualLength += aesEngine.doFinal(outBuf, actualLength);
        }
        catch (Exception e) {
            if (logger != null) {
                logger.error("Unable to perform AES cipher.", (Throwable)e);
            }
            return new byte[0];
        }
        if (outBuf.length == actualLength) {
            return outBuf;
        }
        byte[] result = new byte[actualLength];
        System.arraycopy(outBuf, 0, result, 0, result.length);
        return result;
    }

    @Deprecated
    public static boolean encryptStream(BufferedBlockCipher aesEngine, byte[] aesKey, byte[] aesIV, InputStream in, OutputStream out, Logger logger) {
        byte[] buf = new byte[16];
        byte[] outbuf = new byte[512];
        ParametersWithIV aesIVAndKey = new ParametersWithIV((CipherParameters)new KeyParameter(aesKey), aesIV);
        aesEngine.reset();
        aesEngine.init(true, (CipherParameters)aesIVAndKey);
        try {
            int bytesProcessed;
            int bytesRead;
            while ((bytesRead = in.read(buf)) >= 0) {
                bytesProcessed = aesEngine.processBytes(buf, 0, bytesRead, outbuf, 0);
                out.write(outbuf, 0, bytesProcessed);
            }
            bytesProcessed = aesEngine.doFinal(outbuf, 0);
            out.write(outbuf, 0, bytesProcessed);
            out.flush();
        }
        catch (Exception e) {
            if (logger != null) {
                logger.error("Unable to perform AES cipher.", (Throwable)e);
            }
            return false;
        }
        return true;
    }

    public static boolean encryptStream(GCMBlockCipher aesEngine, byte[] aesKey, byte[] aesIV, InputStream in, OutputStream out, Logger logger) {
        byte[] buf = new byte[16];
        byte[] outbuf = new byte[512];
        ParametersWithIV aesIVAndKey = new ParametersWithIV((CipherParameters)new KeyParameter(aesKey), aesIV);
        aesEngine.reset();
        aesEngine.init(true, (CipherParameters)aesIVAndKey);
        try {
            int bytesProcessed;
            int bytesRead;
            while ((bytesRead = in.read(buf)) >= 0) {
                bytesProcessed = aesEngine.processBytes(buf, 0, bytesRead, outbuf, 0);
                out.write(outbuf, 0, bytesProcessed);
            }
            bytesProcessed = aesEngine.doFinal(outbuf, 0);
            out.write(outbuf, 0, bytesProcessed);
            out.flush();
        }
        catch (Exception e) {
            if (logger != null) {
                logger.error("Unable to perform AES cipher.", (Throwable)e);
            }
            return false;
        }
        return true;
    }

    public static byte[] decryptWithIV(GCMBlockCipher aesEngine, byte[] aesKey, byte[] data, Logger logger) {
        byte[] aesIV = new byte[16];
        System.arraycopy(data, 0, aesIV, 0, 16);
        byte[] in = new byte[data.length - 16];
        System.arraycopy(data, 16, in, 0, in.length);
        return CryptoAES.decrypt(aesEngine, aesKey, aesIV, in, logger);
    }

    @Deprecated
    public static byte[] decryptWithIV(BufferedBlockCipher aesEngine, byte[] aesKey, byte[] data, Logger logger) {
        byte[] aesIV = new byte[16];
        System.arraycopy(data, 0, aesIV, 0, 16);
        byte[] in = new byte[data.length - 16];
        System.arraycopy(data, 16, in, 0, in.length);
        return CryptoAES.decrypt(aesEngine, aesKey, aesIV, in, logger);
    }

    public static boolean decryptStreamWithIV(GCMBlockCipher aesEngine, byte[] aesKey, InputStream in, OutputStream out, Logger logger) {
        byte[] aesIV = new byte[16];
        try {
            in.read(aesIV, 0, 16);
        }
        catch (Exception e) {
            if (logger != null) {
                logger.error("Unable to perform AES cipher.", (Throwable)e);
            }
            return false;
        }
        return CryptoAES.decryptStream(aesEngine, aesKey, aesIV, in, out, logger);
    }

    @Deprecated
    public static boolean decryptStreamWithIV(BufferedBlockCipher aesEngine, byte[] aesKey, InputStream in, OutputStream out, Logger logger) {
        byte[] aesIV = new byte[16];
        try {
            in.read(aesIV, 0, 16);
        }
        catch (Exception e) {
            if (logger != null) {
                logger.error("Unable to perform AES cipher.", (Throwable)e);
            }
            return false;
        }
        return CryptoAES.decryptStream(aesEngine, aesKey, aesIV, in, out, logger);
    }

    public static byte[] decrypt(GCMBlockCipher aesEngine, byte[] aesKey, byte[] aesIV, byte[] data, Logger logger) {
        int length = data.length;
        ParametersWithIV aesIVAndKey = new ParametersWithIV((CipherParameters)new KeyParameter(aesKey), aesIV);
        aesEngine.reset();
        aesEngine.init(false, (CipherParameters)aesIVAndKey);
        int minSize = aesEngine.getOutputSize(length);
        byte[] outBuf = new byte[minSize];
        int actualLength = aesEngine.processBytes(data, 0, length, outBuf, 0);
        try {
            actualLength += aesEngine.doFinal(outBuf, actualLength);
        }
        catch (Exception e) {
            if (logger != null) {
                logger.debug("Unable to perform AES cipher.", (Throwable)e);
            }
            return new byte[0];
        }
        if (outBuf.length == actualLength) {
            return outBuf;
        }
        byte[] result = new byte[actualLength];
        System.arraycopy(outBuf, 0, result, 0, result.length);
        return result;
    }

    @Deprecated
    public static byte[] decrypt(BufferedBlockCipher aesEngine, byte[] aesKey, byte[] aesIV, byte[] data, Logger logger) {
        int length = data.length;
        ParametersWithIV aesIVAndKey = new ParametersWithIV((CipherParameters)new KeyParameter(aesKey), aesIV);
        aesEngine.reset();
        aesEngine.init(false, (CipherParameters)aesIVAndKey);
        int minSize = aesEngine.getOutputSize(length);
        byte[] outBuf = new byte[minSize];
        int actualLength = aesEngine.processBytes(data, 0, length, outBuf, 0);
        try {
            actualLength += aesEngine.doFinal(outBuf, actualLength);
        }
        catch (Exception e) {
            if (logger != null) {
                logger.error("Unable to perform AES cipher.", (Throwable)e);
            }
            return new byte[0];
        }
        if (outBuf.length == actualLength) {
            return outBuf;
        }
        byte[] result = new byte[actualLength];
        System.arraycopy(outBuf, 0, result, 0, result.length);
        return result;
    }

    public static boolean decryptStream(GCMBlockCipher aesEngine, byte[] aesKey, byte[] aesIV, InputStream in, OutputStream out, Logger logger) {
        byte[] buf = new byte[16];
        byte[] outbuf = new byte[512];
        ParametersWithIV aesIVAndKey = new ParametersWithIV((CipherParameters)new KeyParameter(aesKey), aesIV);
        aesEngine.reset();
        aesEngine.init(false, (CipherParameters)aesIVAndKey);
        try {
            int bytesProcessed;
            int bytesRead;
            while ((bytesRead = in.read(buf)) >= 0) {
                bytesProcessed = aesEngine.processBytes(buf, 0, bytesRead, outbuf, 0);
                out.write(outbuf, 0, bytesProcessed);
            }
            bytesProcessed = aesEngine.doFinal(outbuf, 0);
            out.write(outbuf, 0, bytesProcessed);
            out.flush();
        }
        catch (Exception e) {
            if (logger != null) {
                logger.error("Unable to perform AES cipher.", (Throwable)e);
            }
            return false;
        }
        return true;
    }

    @Deprecated
    public static boolean decryptStream(BufferedBlockCipher aesEngine, byte[] aesKey, byte[] aesIV, InputStream in, OutputStream out, Logger logger) {
        byte[] buf = new byte[16];
        byte[] outbuf = new byte[512];
        ParametersWithIV aesIVAndKey = new ParametersWithIV((CipherParameters)new KeyParameter(aesKey), aesIV);
        aesEngine.reset();
        aesEngine.init(false, (CipherParameters)aesIVAndKey);
        try {
            int bytesProcessed;
            int bytesRead;
            while ((bytesRead = in.read(buf)) >= 0) {
                bytesProcessed = aesEngine.processBytes(buf, 0, bytesRead, outbuf, 0);
                out.write(outbuf, 0, bytesProcessed);
            }
            bytesProcessed = aesEngine.doFinal(outbuf, 0);
            out.write(outbuf, 0, bytesProcessed);
            out.flush();
        }
        catch (Exception e) {
            if (logger != null) {
                logger.error("Unable to perform AES cipher.", (Throwable)e);
            }
            return false;
        }
        return true;
    }

    private CryptoAES() {
    }
}

