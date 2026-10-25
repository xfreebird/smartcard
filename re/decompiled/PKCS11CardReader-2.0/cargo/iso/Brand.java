/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.itextpdf.forms.form.element.SignatureFieldAppearance
 *  com.itextpdf.io.image.ImageData
 *  com.itextpdf.io.image.ImageDataFactory
 *  com.itextpdf.kernel.colors.ColorConstants
 *  com.itextpdf.kernel.font.PdfFont
 *  com.itextpdf.kernel.font.PdfFontFactory
 *  com.itextpdf.kernel.geom.Rectangle
 *  com.itextpdf.kernel.pdf.PdfDocument
 *  com.itextpdf.kernel.pdf.PdfReader
 *  com.itextpdf.kernel.pdf.PdfWriter
 *  com.itextpdf.kernel.pdf.StampingProperties
 *  com.itextpdf.kernel.pdf.xobject.PdfImageXObject
 *  com.itextpdf.kernel.pdf.xobject.PdfXObject
 *  com.itextpdf.layout.borders.Border
 *  com.itextpdf.layout.borders.SolidBorder
 *  com.itextpdf.layout.element.Div
 *  com.itextpdf.layout.element.IBlockElement
 *  com.itextpdf.layout.element.Paragraph
 *  com.itextpdf.layout.properties.BackgroundImage$Builder
 *  com.itextpdf.layout.properties.BackgroundPosition
 *  com.itextpdf.layout.properties.BackgroundPosition$PositionX
 *  com.itextpdf.layout.properties.BackgroundPosition$PositionY
 *  com.itextpdf.layout.properties.BackgroundRepeat
 *  com.itextpdf.layout.properties.BackgroundRepeat$BackgroundRepeatValue
 *  com.itextpdf.layout.properties.BackgroundSize
 *  com.itextpdf.signatures.BouncyCastleDigest
 *  com.itextpdf.signatures.CertificateInfo
 *  com.itextpdf.signatures.CertificateInfo$X500Name
 *  com.itextpdf.signatures.CrlClientOnline
 *  com.itextpdf.signatures.ICrlClient
 *  com.itextpdf.signatures.IExternalDigest
 *  com.itextpdf.signatures.IExternalSignature
 *  com.itextpdf.signatures.IOcspClient
 *  com.itextpdf.signatures.ITSAClient
 *  com.itextpdf.signatures.LtvVerification
 *  com.itextpdf.signatures.LtvVerification$CertificateInclusion
 *  com.itextpdf.signatures.LtvVerification$CertificateOption
 *  com.itextpdf.signatures.LtvVerification$Level
 *  com.itextpdf.signatures.OcspClientBouncyCastle
 *  com.itextpdf.signatures.PdfPKCS7
 *  com.itextpdf.signatures.PdfSigner
 *  com.itextpdf.signatures.PdfSigner$CryptoStandard
 *  com.itextpdf.signatures.PrivateKeySignature
 *  com.itextpdf.signatures.SignatureUtil
 *  com.itextpdf.signatures.SignerProperties
 *  com.itextpdf.signatures.TSAClientBouncyCastle
 *  org.bouncycastle.jce.provider.BouncyCastleProvider
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package cargo.iso;

import cargo.AppException;
import com.itextpdf.forms.form.element.SignatureFieldAppearance;
import com.itextpdf.io.image.ImageData;
import com.itextpdf.io.image.ImageDataFactory;
import com.itextpdf.kernel.colors.ColorConstants;
import com.itextpdf.kernel.font.PdfFont;
import com.itextpdf.kernel.font.PdfFontFactory;
import com.itextpdf.kernel.geom.Rectangle;
import com.itextpdf.kernel.pdf.PdfDocument;
import com.itextpdf.kernel.pdf.PdfReader;
import com.itextpdf.kernel.pdf.PdfWriter;
import com.itextpdf.kernel.pdf.StampingProperties;
import com.itextpdf.kernel.pdf.xobject.PdfImageXObject;
import com.itextpdf.kernel.pdf.xobject.PdfXObject;
import com.itextpdf.layout.borders.Border;
import com.itextpdf.layout.borders.SolidBorder;
import com.itextpdf.layout.element.Div;
import com.itextpdf.layout.element.IBlockElement;
import com.itextpdf.layout.element.Paragraph;
import com.itextpdf.layout.properties.BackgroundImage;
import com.itextpdf.layout.properties.BackgroundPosition;
import com.itextpdf.layout.properties.BackgroundRepeat;
import com.itextpdf.layout.properties.BackgroundSize;
import com.itextpdf.signatures.BouncyCastleDigest;
import com.itextpdf.signatures.CertificateInfo;
import com.itextpdf.signatures.CrlClientOnline;
import com.itextpdf.signatures.ICrlClient;
import com.itextpdf.signatures.IExternalDigest;
import com.itextpdf.signatures.IExternalSignature;
import com.itextpdf.signatures.IOcspClient;
import com.itextpdf.signatures.ITSAClient;
import com.itextpdf.signatures.LtvVerification;
import com.itextpdf.signatures.OcspClientBouncyCastle;
import com.itextpdf.signatures.PdfPKCS7;
import com.itextpdf.signatures.PdfSigner;
import com.itextpdf.signatures.PrivateKeySignature;
import com.itextpdf.signatures.SignatureUtil;
import com.itextpdf.signatures.SignerProperties;
import com.itextpdf.signatures.TSAClientBouncyCastle;
import java.awt.Image;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.OpenOption;
import java.nio.file.Paths;
import java.security.GeneralSecurityException;
import java.security.PrivateKey;
import java.security.Provider;
import java.security.Security;
import java.security.cert.Certificate;
import java.security.cert.X509Certificate;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.List;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class Brand {
    private static final Logger logger = LoggerFactory.getLogger(Brand.class);
    private static final String location = "Moldova";
    private static final String reason = "MoldSign Signature";

    public static String buildAppearanceText(Certificate signCertificate, Calendar signDate) {
        String text = null;
        StringBuilder buf = new StringBuilder();
        buf.append("Digitally signed by ");
        CertificateInfo.X500Name x500name = CertificateInfo.getSubjectFields((X509Certificate)((X509Certificate)signCertificate));
        if (x500name != null && (text = x500name.getField("CN")) == null) {
            text = x500name.getField("E");
        }
        if (text == null) {
            text = "";
        }
        buf.append(text).append('\n');
        SimpleDateFormat sd = new SimpleDateFormat("yyyy.MM.dd HH:mm:ss z");
        buf.append("Date: ").append(sd.format(signDate.getTime()));
        buf.append('\n').append("Reason: ").append(reason);
        buf.append('\n').append("Location: ").append(location);
        text = buf.toString();
        return text;
    }

    public static void stamp(String inFileName, String outFileName, PrivateKey key, Certificate[] chain, String providerName, int page, int x, int y, Image img, String text, String digestAlgorithm) throws AppException {
        Rectangle rect = new Rectangle((float)x, (float)(y - 56), 196.0f, 56.0f);
        SignatureFieldAppearance appearance = null;
        if (text != null) {
            ImageData imageData;
            try {
                imageData = ImageDataFactory.create((Image)img, null);
            }
            catch (IOException ex) {
                throw new AppException(ex);
            }
            appearance = new SignatureFieldAppearance("");
            try {
                PdfFont fnt = PdfFontFactory.createFont((String)"/TIMES.TTF");
                appearance.setFont(fnt);
            }
            catch (IOException ex) {
                throw new AppException(ex);
            }
            BackgroundSize size = new BackgroundSize();
            size.setBackgroundSizeToCover();
            BackgroundPosition backgroundPosition = new BackgroundPosition();
            backgroundPosition.setPositionX(BackgroundPosition.PositionX.CENTER).setPositionY(BackgroundPosition.PositionY.CENTER);
            appearance.setBackgroundImage(new BackgroundImage.Builder().setImage((PdfXObject)new PdfImageXObject(imageData)).setBackgroundRepeat(new BackgroundRepeat(BackgroundRepeat.BackgroundRepeatValue.NO_REPEAT)).setBackgroundPosition(backgroundPosition).setBackgroundSize(size).build());
            Div customAppearance = ((Div)((Div)((Div)new Div().setMargin(0.0f)).setPadding(0.0f)).setFontSize(7.8f)).add((IBlockElement)((Paragraph)((Paragraph)new Paragraph(text).setMargin(0.0f)).setPadding(0.0f)).setMultipliedLeading(1.1f)).add((IBlockElement)((Paragraph)((Paragraph)((Paragraph)new Paragraph("MOLDOVA EUROPEAN\u0102").setMargins(1.0f, 0.0f, 0.0f, 0.0f)).setPaddings(0.0f, 0.0f, 0.0f, 4.0f)).setWidth(94.0f)).setBorder((Border)new SolidBorder(ColorConstants.GRAY, 0.3f)));
            appearance.setContent(customAppearance);
        }
        SignerProperties prop = new SignerProperties();
        prop.setPageNumber(page);
        prop.setPageRect(rect);
        prop.setReason(reason);
        prop.setLocation(location);
        if (appearance != null) {
            prop.setSignatureAppearance(appearance);
        }
        Security.addProvider((Provider)new BouncyCastleProvider());
        String digestAlgorithmTSA = "SHA-256";
        try (PdfReader reader = new PdfReader(inFileName);
             OutputStream output = Files.newOutputStream(Paths.get(outFileName, new String[0]), new OpenOption[0]);){
            PdfSigner signer = new PdfSigner(reader, output, new StampingProperties().useAppendMode());
            signer.setSignerProperties(prop);
            PrivateKeySignature externalSignature = new PrivateKeySignature(key, digestAlgorithm, providerName);
            BouncyCastleDigest externalDigest = new BouncyCastleDigest();
            OcspClientBouncyCastle ocspClient = new OcspClientBouncyCastle();
            TSAClientBouncyCastle tsaClient = new TSAClientBouncyCastle("http://tsp.pki.gov.md/moldsign2/", "", "", 6500, "SHA-256");
            logger.info("signDetached");
            signer.signDetached((IExternalDigest)externalDigest, (IExternalSignature)externalSignature, chain, null, (IOcspClient)ocspClient, (ITSAClient)tsaClient, 0, PdfSigner.CryptoStandard.CADES);
        }
        catch (IOException | GeneralSecurityException ex) {
            throw new AppException(ex);
        }
    }

    public static void stampLtv(String inFileName, String outFileName) throws AppException {
        try (PdfReader reader = new PdfReader(inFileName);
             PdfWriter writer = new PdfWriter(outFileName);
             PdfDocument pdfDoc = new PdfDocument(reader, writer, new StampingProperties().useAppendMode());){
            SignatureUtil signUtil = new SignatureUtil(pdfDoc);
            List names = signUtil.getSignatureNames();
            String lastSigName = (String)names.get(names.size() - 1);
            PdfPKCS7 pdfPKCS7 = signUtil.readSignatureData(lastSigName, "BC");
            OcspClientBouncyCastle ocspClient = new OcspClientBouncyCastle();
            CrlClientOnline crlClient = new CrlClientOnline();
            LtvVerification ltv = new LtvVerification(pdfDoc);
            if (pdfPKCS7.isTsp()) {
                logger.info("TLV for T");
                ltv.addVerification(lastSigName, (IOcspClient)ocspClient, (ICrlClient)crlClient, LtvVerification.CertificateOption.SIGNING_CERTIFICATE, LtvVerification.Level.OCSP_CRL, LtvVerification.CertificateInclusion.NO);
            } else {
                logger.info("TLV for S");
                ltv.addVerification(lastSigName, (IOcspClient)ocspClient, (ICrlClient)crlClient, LtvVerification.CertificateOption.WHOLE_CHAIN, LtvVerification.Level.OCSP_CRL, LtvVerification.CertificateInclusion.NO);
            }
            ltv.merge();
        }
        catch (IOException | GeneralSecurityException ex) {
            throw new AppException(ex);
        }
    }
}

