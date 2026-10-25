/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.asn1.structures.AlgorithmID
 *  iaik.tsp.MessageImprint
 *  iaik.tsp.TimeStampReq
 *  iaik.xml.crypto.xades.timestamp.TimeStampException
 *  iaik.xml.crypto.xades.timestamp.TimeStampProcessor
 *  iaik.xml.crypto.xades.timestamp.TimeStampToken
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.sim;

import iaik.asn1.structures.AlgorithmID;
import iaik.tsp.MessageImprint;
import iaik.tsp.TimeStampReq;
import iaik.xml.crypto.xades.timestamp.TimeStampException;
import iaik.xml.crypto.xades.timestamp.TimeStampProcessor;
import iaik.xml.crypto.xades.timestamp.TimeStampToken;
import java.io.IOException;
import java.io.InputStream;
import java.security.DigestInputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import javax.xml.crypto.OctetStreamData;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class TSPTimeStampProcessor
implements TimeStampProcessor {
    private static final Logger logger = LoggerFactory.getLogger(TSPTimeStampProcessor.class);
    private final AlgorithmID algorithmID;
    private final int timeSleep;

    TSPTimeStampProcessor(int timeSleep, AlgorithmID algorithmID) {
        this.timeSleep = timeSleep;
        this.algorithmID = algorithmID;
    }

    public abstract TimeStampToken timeStamp(OctetStreamData var1) throws TimeStampException;

    protected MessageImprint calculateMessageImprint(OctetStreamData var1) throws TimeStampException {
        MessageDigest var3;
        InputStream var2 = var1.getOctetStream();
        try {
            var3 = MessageDigest.getInstance(this.algorithmID.getName());
        }
        catch (NoSuchAlgorithmException var6) {
            throw new TimeStampException("Failed to calculate digest from given input, " + var6.getMessage(), (Throwable)var6);
        }
        DigestInputStream var4 = new DigestInputStream(var2, var3);
        try {
            Thread.sleep(this.timeSleep);
        }
        catch (InterruptedException e) {
            logger.error("sleep", (Throwable)e);
        }
        try {
            byte[] arrayOfByte = new byte[4096];
            if (var4.read(arrayOfByte) == -1) {
                throw new TimeStampException("Failed to calculate digest from given input");
            }
        }
        catch (IOException var7) {
            throw new TimeStampException("Failed to calculate digest from given input", (Throwable)var7);
        }
        byte[] var5 = var3.digest();
        return new MessageImprint(this.algorithmID, var5);
    }

    protected TimeStampReq createTimeStampReq(MessageImprint var1) {
        if (var1 == null) {
            throw new NullPointerException("Argument 'messageImprint' must not be null");
        }
        TimeStampReq var2 = new TimeStampReq(var1);
        var2.setCertReq(true);
        return var2;
    }
}

