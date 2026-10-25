/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.pkcs.pkcs11.provider.IAIKPkcs11
 *  iaik.pkcs.pkcs11.provider.LoginManager
 *  iaik.x509.X509Certificate
 *  md.cts.moldsign.transferobjects.models.CertificateModel
 *  md.cts.moldsign.transferobjects.models.SignPdfInputModel
 *  md.cts.moldsign.transferobjects.models.SignPdfResponseModel
 *  md.ghesar.Resource
 *  org.apache.pdfbox.pdmodel.PDDocument
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.providers.workers;

import cargo.iso.Brand;
import cargo.iso.Kayak;
import iaik.pkcs.pkcs11.provider.IAIKPkcs11;
import iaik.pkcs.pkcs11.provider.LoginManager;
import iaik.x509.X509Certificate;
import java.awt.Component;
import java.awt.Dimension;
import java.awt.Image;
import java.awt.Point;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.OpenOption;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.security.PrivateKey;
import java.security.Provider;
import java.security.cert.Certificate;
import java.util.Calendar;
import java.util.List;
import javax.swing.JFrame;
import javax.swing.JLabel;
import md.cts.cryptography.providers.GlobalCertificateProvider;
import md.cts.cryptography.providers.SecurityOperationProvider;
import md.cts.cryptography.providers.SecurityOperationsProviderManager;
import md.cts.ghesar.PdfView;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.moldsign.transferobjects.models.SignPdfInputModel;
import md.cts.moldsign.transferobjects.models.SignPdfResponseModel;
import md.cts.pkcs11.cards.exceptions.InvalidPinException;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import md.cts.pkcs11.providers.pin_providers.PKCS11PinProvider;
import md.cts.pkcs11.providers.workers.AbstractWork;
import md.ghesar.Resource;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class SignPDFWorker
extends AbstractWork<SignPdfResponseModel> {
    private static final Logger logger = LoggerFactory.getLogger(SignPDFWorker.class);
    private final SignPdfInputModel input;
    private final SecurityOperationProvider secProvider;
    private final boolean usePdfPreview;
    private boolean appearance;
    private Point sigPoint;
    private int page = 1;

    public SignPDFWorker(SignPdfInputModel input, boolean usePdfPreview, boolean appearance) {
        this.input = input;
        this.usePdfPreview = usePdfPreview;
        this.appearance = appearance;
        this.secProvider = SecurityOperationsProviderManager.getProvider(input.getCertificate().getProviderId());
        logger.info("new SignPDFWorker ProviderId={}", (Object)input.getCertificate().getProviderId());
    }

    private static void createWindow(String fileName) {
        JFrame frame = new JFrame("File is read only");
        frame.setDefaultCloseOperation(1);
        JLabel textLabel = new JLabel("File: " + SignPDFWorker.getFileName(fileName) + " read only", 0);
        textLabel.setPreferredSize(new Dimension(400, 120));
        frame.getContentPane().add((Component)textLabel, "Center");
        frame.setLocationRelativeTo(null);
        frame.pack();
        frame.setVisible(true);
    }

    private static String getFileName(String file) {
        if (file.lastIndexOf("/") != -1) {
            return file.substring(file.lastIndexOf("/") + 1);
        }
        if (file.lastIndexOf("\\") != -1) {
            return file.substring(file.lastIndexOf("\\") + 1);
        }
        return file;
    }

    private void checkPdfReadOnly() throws OperationFailedException {
        boolean readOnly = true;
        try {
            File initialFile = new File(this.input.getOriginalFile());
            InputStream targetStream = Files.newInputStream(initialFile.toPath(), new OpenOption[0]);
            PDDocument doc = PDDocument.load((InputStream)targetStream);
            readOnly = doc.getCurrentAccessPermission().isReadOnly();
            logger.info("is PDF read only: {}", (Object)readOnly);
            doc.close();
            targetStream.close();
        }
        catch (IOException e) {
            logger.error("", (Throwable)e);
        }
        if (readOnly) {
            SignPDFWorker.createWindow(this.input.getOriginalFile());
            throw new OperationFailedException("exception.general.unknown_problem", new Exception("File is read only"));
        }
    }

    private boolean pdfPreview() {
        boolean ok = false;
        logger.info("pdfPreview open");
        try {
            PdfView pdfView = new PdfView(this.input.getOriginalFile());
            this.sigPoint = pdfView.getSigPoint();
            this.page = pdfView.getFinalPage();
            this.appearance = pdfView.getAppearance();
            ok = pdfView.getSuccess();
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
            return ok;
        }
        logger.info("pdfPreview done ok={}", (Object)ok);
        return ok;
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    @Override
    public SignPdfResponseModel call() throws OperationFailedException, InvalidPinException {
        boolean ok;
        String finalFilePath;
        String stage2FilePath;
        String stage1FilePath;
        block29: {
            boolean ok2;
            logger.info("SignPDFWorker call()");
            this.checkPdfReadOnly();
            if (this.usePdfPreview && this.appearance && !(ok2 = this.pdfPreview())) {
                return null;
            }
            logger.info("filename1: {}", (Object)this.input.getOriginalFile());
            logger.info("filename2: {}", (Object)this.input.getSignedFile());
            logger.info("certificate: {}", (Object)this.input.getCertificate());
            if (this.input.getOriginalFile() == null || this.input.getSignedFile() == null) {
                throw new OperationFailedException("exception.signatures.null_file", new Exception("file can not be null"));
            }
            if (this.input.getOriginalFile().trim().equals(this.input.getSignedFile().trim())) {
                throw new OperationFailedException("exception.signatures.both_files_match", new Exception("The origin and destination file can not be the same"));
            }
            Object stage0FilePath = this.input.getOriginalFile() + "_1.pdf";
            try {
                Files.deleteIfExists(Paths.get((String)stage0FilePath, new String[0]));
            }
            catch (IOException ex) {
                logger.error("", (Throwable)ex);
            }
            boolean converted = Kayak.stripCompliance(this.input.getOriginalFile(), (String)stage0FilePath);
            if (!converted) {
                stage0FilePath = this.input.getOriginalFile();
            }
            stage1FilePath = this.input.getSignedFile() + "_2.pdf";
            stage2FilePath = this.input.getSignedFile() + "_3.pdf";
            finalFilePath = this.input.getSignedFile();
            ok = false;
            try {
                ok = this.signPdf((String)stage0FilePath, stage1FilePath, stage2FilePath);
                if (!converted) break block29;
            }
            catch (Throwable throwable) {
                if (converted) {
                    try {
                        Files.deleteIfExists(Paths.get((String)stage0FilePath, new String[0]));
                    }
                    catch (IOException ex) {
                        logger.error("", (Throwable)ex);
                    }
                }
                try {
                    Files.deleteIfExists(Paths.get(stage1FilePath, new String[0]));
                }
                catch (IOException ex) {
                    logger.error("", (Throwable)ex);
                }
                Path source = Paths.get(stage2FilePath, new String[0]);
                if (ok) {
                    try {
                        Files.move(source, Paths.get(finalFilePath, new String[0]), StandardCopyOption.REPLACE_EXISTING);
                    }
                    catch (IOException ex) {
                        logger.error("", (Throwable)ex);
                    }
                    logger.info("File successfully signed.");
                } else {
                    try {
                        Files.deleteIfExists(source);
                    }
                    catch (IOException ex) {
                        logger.error("", (Throwable)ex);
                    }
                    logger.info("File not signed.");
                }
                throw throwable;
            }
            try {
                Files.deleteIfExists(Paths.get((String)stage0FilePath, new String[0]));
            }
            catch (IOException ex) {
                logger.error("", (Throwable)ex);
            }
        }
        try {
            Files.deleteIfExists(Paths.get(stage1FilePath, new String[0]));
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
        }
        Path source = Paths.get(stage2FilePath, new String[0]);
        if (ok) {
            try {
                Files.move(source, Paths.get(finalFilePath, new String[0]), StandardCopyOption.REPLACE_EXISTING);
            }
            catch (IOException ex) {
                logger.error("", (Throwable)ex);
            }
            logger.info("File successfully signed.");
        } else {
            try {
                Files.deleteIfExists(source);
            }
            catch (IOException ex) {
                logger.error("", (Throwable)ex);
            }
            logger.info("File not signed.");
        }
        return new SignPdfResponseModel(finalFilePath);
    }

    private boolean signPdf(String stage0FilePath, String stage1FilePath, String stage2FilePath) throws OperationFailedException {
        logger.info("Signing PDF file operation started...");
        GlobalCertificateProvider.get().validateCertificate(this.input.getCertificate(), 1);
        logger.info("Certificate validated.");
        char[] pin = null;
        if (this.input.getPin() != null) {
            pin = this.input.getPin().toCharArray();
        }
        Provider provider = this.secProvider.getProvider();
        logger.info("providerName: {}", (Object)provider.getName());
        if (provider instanceof IAIKPkcs11) {
            IAIKPkcs11 prov = (IAIKPkcs11)provider;
            PKCS11PinProvider loginManager = new PKCS11PinProvider(pin, this.getSessionId(), this.input.getRequester());
            prov.setLoginManager((LoginManager)loginManager);
        }
        try {
            PrivateKey key;
            List<CertificateModel> chainModels = GlobalCertificateProvider.get().getCertificateChain(this.input.getCertificate());
            X509Certificate[] chain = new X509Certificate[chainModels.size()];
            for (int i = 0; i < chainModels.size(); ++i) {
                chain[i] = chainModels.get(i).getCertificate();
            }
            for (X509Certificate cert : chain) {
                logger.info("chainCert {}", (Object)cert.getSubjectX500Principal());
            }
            logger.info("getLabel= {}", (Object)this.input.getCertificate().getLabel());
            logger.info("algo: {}", (Object)this.input.getAlgorithm());
            String digestAlgorithm = "SHA-256";
            if ("SunMSCAPI".equals(provider.getName())) {
                digestAlgorithm = "SHA-1";
            }
            if ((key = this.secProvider.getPrivateKey(this.input.getCertificate().getLabel())) == null) {
                throw new OperationFailedException("exception.general.unknown_problem", new Exception("PrivateKey not found"));
            }
            if (this.appearance) {
                int x = 22;
                int y = 72;
                if (this.usePdfPreview) {
                    x = this.sigPoint.x;
                    y = this.sigPoint.y;
                }
                Image img = Resource.getImage((String)"/pdfSignatureImage.png");
                String text = Brand.buildAppearanceText((Certificate)this.input.getCertificate().getCertificate(), Calendar.getInstance());
                Brand.stamp(stage0FilePath, stage1FilePath, key, (Certificate[])chain, provider.getName(), this.page, x, y, img, text, digestAlgorithm);
            } else {
                Brand.stamp(stage0FilePath, stage1FilePath, key, (Certificate[])chain, provider.getName(), this.page, 22, 72, null, null, digestAlgorithm);
            }
            Brand.stampLtv(stage1FilePath, stage2FilePath);
            int n = 1;
            return n != 0;
        }
        catch (Exception ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.general.unknown_problem", ex);
        }
        finally {
            try {
                if (provider instanceof IAIKPkcs11) {
                    IAIKPkcs11 prov = (IAIKPkcs11)provider;
                    logger.info("drop session");
                    prov.getTokenManager().closeSessions();
                }
            }
            catch (Exception ex) {
                logger.error("", (Throwable)ex);
            }
            logger.info("Signing operation finished.");
        }
    }
}

