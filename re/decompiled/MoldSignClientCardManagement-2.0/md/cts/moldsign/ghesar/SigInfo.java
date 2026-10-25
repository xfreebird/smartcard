/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.itextpdf.signatures.PdfPKCS7
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.ghesar;

import com.itextpdf.signatures.PdfPKCS7;
import ghesar.DNParser;
import java.security.GeneralSecurityException;
import java.security.cert.X509Certificate;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Calendar;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class SigInfo {
    private static final Logger logger = LoggerFactory.getLogger(SigInfo.class);
    public final String signatureName;
    public final PdfPKCS7 pdfPk;
    public final boolean whole;
    public X509Certificate signCert;
    public String personName;
    public String organization;
    public String serialNumber;
    public String formattedDate;
    public boolean isValid;
    public boolean isTimestampValid;
    public Instant signInstant;

    public SigInfo(String signatureName, PdfPKCS7 pdfPk, boolean whole) {
        this.signatureName = signatureName;
        this.pdfPk = pdfPk;
        this.whole = whole;
    }

    public void parse() {
        this.signCert = this.pdfPk.getSigningCertificate();
        String certSubject = this.signCert.getSubjectX500Principal().toString();
        DNParser certSubjectEx = new DNParser(certSubject);
        this.personName = certSubjectEx.get("CN");
        this.serialNumber = certSubjectEx.get("SERIALNUMBER");
        this.organization = certSubjectEx.get("O");
        Calendar c = this.pdfPk.getSignDate();
        if (c != null) {
            this.signInstant = c.toInstant();
        }
        DateTimeFormatter formatter = DateTimeFormatter.RFC_1123_DATE_TIME.withZone(ZoneId.systemDefault());
        this.formattedDate = formatter.format(this.signInstant);
        try {
            this.isValid = this.pdfPk.verifySignatureIntegrityAndAuthenticity();
        }
        catch (GeneralSecurityException ex) {
            logger.error("", (Throwable)ex);
        }
        try {
            this.isTimestampValid = this.pdfPk.verifyTimestampImprint();
        }
        catch (GeneralSecurityException ex) {
            logger.error("", (Throwable)ex);
        }
    }
}

