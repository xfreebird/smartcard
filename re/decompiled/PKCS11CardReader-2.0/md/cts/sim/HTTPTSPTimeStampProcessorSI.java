/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.asn1.CodingException
 *  iaik.asn1.structures.AlgorithmID
 *  iaik.tsp.TimeStampReq
 *  iaik.tsp.TimeStampResp
 *  iaik.tsp.TimeStampToken
 *  iaik.tsp.transport.http.TspHttpClient
 *  iaik.tsp.transport.http.TspHttpResponse
 *  iaik.xml.crypto.xades.timestamp.TimeStampException
 *  iaik.xml.crypto.xades.timestamp.TimeStampProcessor
 *  iaik.xml.crypto.xades.timestamp.TimeStampToken
 *  iaik.xml.crypto.xades.timestamp.impl.TSPTimeStampTokenImpl
 */
package md.cts.sim;

import iaik.asn1.CodingException;
import iaik.asn1.structures.AlgorithmID;
import iaik.tsp.TimeStampReq;
import iaik.tsp.TimeStampResp;
import iaik.tsp.transport.http.TspHttpClient;
import iaik.tsp.transport.http.TspHttpResponse;
import iaik.xml.crypto.xades.timestamp.TimeStampException;
import iaik.xml.crypto.xades.timestamp.TimeStampProcessor;
import iaik.xml.crypto.xades.timestamp.TimeStampToken;
import iaik.xml.crypto.xades.timestamp.impl.TSPTimeStampTokenImpl;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import javax.xml.crypto.OctetStreamData;
import md.cts.sim.TSPTimeStampProcessor;

public final class HTTPTSPTimeStampProcessorSI
extends TSPTimeStampProcessor
implements TimeStampProcessor {
    private final URL url_;

    public HTTPTSPTimeStampProcessorSI(String var1, int timeSleep, AlgorithmID algorithmID) throws MalformedURLException {
        super(timeSleep, algorithmID);
        this.url_ = new URL(var1);
    }

    @Override
    public TimeStampToken timeStamp(OctetStreamData var1) throws TimeStampException {
        TspHttpResponse var2;
        try {
            TspHttpClient var3 = new TspHttpClient(this.url_);
            TimeStampReq var4 = this.createTimeStampReq(this.calculateMessageImprint(var1));
            var2 = var3.sendRequest(var4);
        }
        catch (CodingException | IOException var5) {
            throw new TimeStampException("Failed to receive time-stamp, " + var5.getMessage());
        }
        if (var2.isErrorResponse()) {
            throw new TimeStampException("Failed to receive time-stamp, " + var2.getErrorMsg());
        }
        TimeStampResp var7 = var2.getTimeStampResp();
        iaik.tsp.TimeStampToken var8 = var7.getTimeStampToken();
        if (var8 == null) {
            throw new TimeStampException("Failed to receive time-stamp, " + var7.getPKIStatusInfo().getPKIFailureInfo().getFailureInfo());
        }
        return new TSPTimeStampTokenImpl(var8);
    }
}

