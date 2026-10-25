/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.x509.X509Certificate
 *  jakarta.ws.rs.DefaultValue
 *  jakarta.ws.rs.GET
 *  jakarta.ws.rs.OPTIONS
 *  jakarta.ws.rs.POST
 *  jakarta.ws.rs.Path
 *  jakarta.ws.rs.PathParam
 *  jakarta.ws.rs.Produces
 *  jakarta.ws.rs.QueryParam
 *  jakarta.ws.rs.core.Context
 *  jakarta.ws.rs.core.HttpHeaders
 *  jakarta.ws.rs.core.Response
 *  jakarta.ws.rs.core.Response$ResponseBuilder
 *  jakarta.ws.rs.core.Response$Status
 *  jakarta.ws.rs.core.UriBuilder
 *  jakarta.ws.rs.core.UriInfo
 *  md.gov.stisc.Single
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.clientcardmanager.server.services;

import iaik.x509.X509Certificate;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.OPTIONS;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriBuilder;
import jakarta.ws.rs.core.UriInfo;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Base64;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicInteger;
import md.cts.cryptography.providers.SecurityOperationsProviderManager;
import md.cts.cryptography.schedulers.Scheduler;
import md.cts.cryptography.schedulers.SchedulerManager;
import md.cts.moldsign.clientcardmanager.properties.PropertiesLoader;
import md.cts.moldsign.clientcardmanager.server.AllowedSites;
import md.cts.moldsign.clientcardmanager.start.ClientCardManager;
import md.cts.moldsign.clientcardmanager.ui.configuration.popups.DriversConfigurationPanel;
import md.cts.moldsign.clientcardmanager.ui.popups.PinBlockedDialog;
import md.cts.moldsign.clientcardmanager.ui.popups.PukBlockedDialog;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.moldsign.transferobjects.models.DeleteSignatureInputModel;
import md.cts.moldsign.transferobjects.models.SignDataInputModel;
import md.cts.moldsign.transferobjects.models.SignDataResponseModel;
import md.cts.moldsign.transferobjects.models.SignFileInputModel;
import md.cts.moldsign.transferobjects.models.SignPdfInputModel;
import md.cts.moldsign.transferobjects.models.SignPdfResponseModel;
import md.cts.moldsign.transferobjects.models.SignSimpleDataInputModel;
import md.cts.moldsign.transferobjects.models.SignSimpleDataResponseModel;
import md.cts.moldsign.transferobjects.models.VerifyPdfInputModel;
import md.cts.moldsign.transferobjects.models.VerifyPdfResponseModel;
import md.cts.moldsign.transferobjects.models.VerifySignedFileInputModel;
import md.cts.moldsign.transferobjects.models.VerifySignedFileResponseModel;
import md.cts.moldsign.transferobjects.models.XAdES.GetSignatureFileInputModel;
import md.cts.moldsign.transferobjects.models.XAdES.XadesSignatureModelContainer;
import md.cts.pkcs11.cards.Card;
import md.cts.pkcs11.cards.CardReaderManager;
import md.cts.pkcs11.cards.exceptions.InvalidPinException;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import md.cts.pkcs11.providers.pin_providers.PinDistributor;
import md.cts.pkcs11.providers.workers.DeleteSignatureWorker;
import md.cts.pkcs11.providers.workers.SignPDFWorker;
import md.cts.pkcs11.providers.workers.SignXAdESWorker;
import md.cts.pkcs11.providers.workers.VerifyPDFWorker;
import md.cts.pkcs11.providers.workers.VerifySignedFileWorker;
import md.cts.pkcs11.providers.workers.XAdESSignatureInfoWorker;
import md.gov.stisc.Single;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@jakarta.ws.rs.Path(value="sign")
public final class Signature {
    private static final Logger logger = LoggerFactory.getLogger(Signature.class);
    private static final AtomicInteger safeCounter = new AtomicInteger(1001);
    @Context
    public UriInfo uriInfo;

    private static void saveToDisk(File sourceFile, byte[] data) {
        try (FileOutputStream fop = new FileOutputStream(sourceFile);){
            try {
                fop.write(data);
                fop.flush();
            }
            catch (IOException ex) {
                logger.error("", (Throwable)ex);
            }
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
        }
    }

    @OPTIONS
    @jakarta.ws.rs.Path(value="data")
    public Response postDataOptions() {
        logger.info("postDataOptions()");
        return Response.ok().build();
    }

    @POST
    @jakarta.ws.rs.Path(value="data")
    public Response signDataString(@Context HttpHeaders headers, SignDataInputModel input, @DefaultValue(value="") @QueryParam(value="use_pin_session") String usePinSession) {
        Response.ResponseBuilder builder;
        block17: {
            List<String> allowedUrlList;
            logger.info("POST signDataString(use_pin_session:{})", (Object)usePinSession);
            String origin = (String)headers.getRequestHeaders().getFirst((Object)"Origin");
            boolean matches = false;
            if (origin != null && (allowedUrlList = AllowedSites.getAllowedUrlList()) != null) {
                for (String pattern : allowedUrlList) {
                    if (!origin.matches(pattern)) continue;
                    matches = true;
                    input.setRequester(origin);
                    break;
                }
            }
            logger.info("Algorithm={}", (Object)input.getAlgorithm());
            if (matches) {
                int unique = safeCounter.getAndIncrement();
                File sourceFile = new File(Single.appTempDir + File.separator + "signData_" + unique + "_src.tmp");
                logger.info("sourceFile={}", (Object)sourceFile.getPath());
                byte[] data = Base64.getDecoder().decode(input.getData());
                Signature.saveToDisk(sourceFile, data);
                String destinationFile = Single.appTempDir + File.separator + "signData_" + unique + "_dst.tmp";
                logger.info("destinationFile={}", (Object)destinationFile);
                try {
                    String sessionId;
                    String type;
                    logger.info("contentType={}", (Object)input.getContentType());
                    String signFormat = input.getSignFormat();
                    logger.info("signFormat={}", (Object)signFormat);
                    if (!signFormat.equalsIgnoreCase("PAdES") && !signFormat.equalsIgnoreCase("PAdES-T")) {
                        char[] oldPin;
                        type = "XAdES";
                        fileInputModel = new SignFileInputModel(input, sourceFile.getAbsolutePath(), destinationFile);
                        if ("XAdES".equalsIgnoreCase(input.getContentType())) {
                            ((SignFileInputModel)fileInputModel).setSignatureFile(sourceFile.getAbsolutePath());
                        }
                        if (usePinSession != null && !usePinSession.isEmpty() && (oldPin = PinDistributor.getPinForSesssion(usePinSession)) != null) {
                            ((SignFileInputModel)fileInputModel).setPin(new String(oldPin));
                        }
                        SignXAdESWorker xAdESWorker = new SignXAdESWorker((SignFileInputModel)fileInputModel);
                        sessionId = SchedulerManager.get("PKCS11").scheduleWorker(xAdESWorker);
                    } else {
                        type = "pdf";
                        fileInputModel = new SignPdfInputModel(input, sourceFile.getAbsolutePath(), destinationFile);
                        if (!PropertiesLoader.useMscsp()) {
                            CertificateModel currentCertModel = ((SignPdfInputModel)fileInputModel).getCertificate();
                            X509Certificate selectedCert = currentCertModel.getCertificate();
                            Card currentCard = CardReaderManager.get().getCardByCertificate(selectedCert);
                            if (currentCard == null) {
                                logger.warn("card not found");
                                throw new Exception("card not found");
                            }
                            boolean isPinLocked = currentCard.isPinLocked();
                            boolean isPukLocked = currentCard.isPukLocked();
                            if (isPukLocked) {
                                PukBlockedDialog pukDialog = new PukBlockedDialog();
                                pukDialog.init();
                                logger.warn("Invalid Puk");
                                throw new Exception("invalid puk");
                            }
                            if (isPinLocked) {
                                PinBlockedDialog pinDialog = new PinBlockedDialog();
                                pinDialog.init();
                                logger.warn("Invalid Pin");
                                throw new Exception("invalid pin");
                            }
                        }
                        boolean usePdfPreview = DriversConfigurationPanel.getUsePdfPreview();
                        boolean signatureAppearance = DriversConfigurationPanel.getSignatureAppearance();
                        SignPDFWorker pdfWorker = new SignPDFWorker((SignPdfInputModel)fileInputModel, usePdfPreview, signatureAppearance);
                        sessionId = SchedulerManager.get("PKCS11").scheduleWorker(pdfWorker);
                    }
                    logger.info("sessionId={}", (Object)sessionId);
                    if (input.getHttpCallBackID() != null && input.getHttpCallBackURL() != null) {
                        logger.info("http callback\n id= {}\n url= {}", (Object)input.getHttpCallBackID(), (Object)input.getHttpCallBackURL());
                    }
                    UriBuilder ub = this.uriInfo.getAbsolutePathBuilder();
                    URI uri = ub.replacePath("sign/data/").path("PKCS11").path(sessionId).path(type).build(new Object[0]);
                    builder = Response.created((URI)uri).header("sessionId", (Object)sessionId);
                }
                catch (Exception t) {
                    if (Objects.equals(t.getMessage(), "invalidpin")) {
                        builder = Response.status((Response.Status)Response.Status.BAD_REQUEST).header("error", (Object)"Pin Locked");
                        break block17;
                    }
                    if (Objects.equals(t.getMessage(), "invalidpuk")) {
                        builder = Response.status((Response.Status)Response.Status.BAD_REQUEST).header("error", (Object)"Puk Locked");
                        break block17;
                    }
                    builder = Response.status((Response.Status)Response.Status.BAD_REQUEST).header("error", (Object)"Invalid API usage");
                }
            } else {
                builder = Response.status((Response.Status)Response.Status.UNAUTHORIZED).header("error", (Object)"Web site not authorized");
            }
        }
        logger.info("signDataString done");
        return builder.build();
    }

    @OPTIONS
    @jakarta.ws.rs.Path(value="data/{providerId}/{sessionId}/{type}")
    public Response getDataOptions() {
        logger.info("getDataOptions()");
        return Response.ok().build();
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    @GET
    @jakarta.ws.rs.Path(value="data/{providerId}/{sessionId}/{type}")
    @Produces(value={"application/xml", "application/json"})
    public Response getSignedData(@Context HttpHeaders headers, @PathParam(value="providerId") String providerId, @PathParam(value="sessionId") String sessionId, @PathParam(value="type") String type, @DefaultValue(value="0") @QueryParam(value="keep_pin_session") String keepPinSession) {
        logger.info("GET getSignedData(providerId:{},type:{},keep_pin_session:{}\n sessionId:{})", new Object[]{providerId, type, keepPinSession, sessionId});
        boolean matches = false;
        Response.ResponseBuilder builder = null;
        Scheduler scheduler = SchedulerManager.get("PKCS11");
        String origin = (String)headers.getRequestHeaders().getFirst((Object)"Origin");
        if (origin != null) {
            List<String> allowedUrlList = AllowedSites.getAllowedUrlList();
            if (allowedUrlList != null) {
                for (String pattern : allowedUrlList) {
                    if (!origin.matches(pattern)) continue;
                    matches = true;
                    break;
                }
            }
        } else {
            matches = true;
        }
        if (matches) {
            String destinationFilePath = null;
            if (!type.equalsIgnoreCase("pdf")) {
                try {
                    result = scheduler.getResult(sessionId, XadesSignatureModelContainer.class);
                    destinationFilePath = ((XadesSignatureModelContainer)result).getFileLocation();
                    logger.info("1 destinationFilePath= {}", (Object)destinationFilePath);
                }
                catch (OperationFailedException ex) {
                    logger.error("Operation failed", (Throwable)ex);
                    message = ex.getLocalizedMessage() != null && !ex.getLocalizedMessage().isEmpty() ? ClientCardManager.exceptionBundle.getString(ex.getLocalizedMessage()) : ex.getMessage();
                    builder = Response.status((Response.Status)Response.Status.BAD_REQUEST).header("error", (Object)message);
                }
                catch (ClassCastException | InvalidPinException ex) {
                    logger.error("Invalid pin", (Throwable)ex);
                    builder = Response.status((Response.Status)Response.Status.BAD_REQUEST).header("error", (Object)ex.getMessage());
                }
                finally {
                    if (!"1".equals(keepPinSession)) {
                        PinDistributor.clearPinSession(sessionId);
                    }
                }
            } else {
                try {
                    result = scheduler.getResult(sessionId, SignPdfResponseModel.class);
                    destinationFilePath = ((SignPdfResponseModel)result).getSaveToPath();
                    logger.info("2 destinationFilePath= {}", (Object)destinationFilePath);
                }
                catch (OperationFailedException ex) {
                    logger.error("Operation failed", (Throwable)ex);
                    message = ex.getLocalizedMessage() != null && !ex.getLocalizedMessage().isEmpty() ? ClientCardManager.exceptionBundle.getString(ex.getLocalizedMessage()) : ex.getMessage();
                    builder = Response.status((Response.Status)Response.Status.BAD_REQUEST).header("error", (Object)message);
                }
                catch (ClassCastException | InvalidPinException ex) {
                    logger.error("Invalid pin", ex.getCause());
                    builder = Response.status((Response.Status)Response.Status.BAD_REQUEST).header("error", (Object)ex.getMessage());
                }
                finally {
                    if (!"1".equals(keepPinSession)) {
                        PinDistributor.clearPinSession(sessionId);
                    }
                }
            }
            if (destinationFilePath != null) {
                try {
                    Path path = Paths.get(destinationFilePath, new String[0]);
                    byte[] fileBytes = Files.readAllBytes(path);
                    String encodedDataString = Base64.getEncoder().encodeToString(fileBytes);
                    SignDataResponseModel sdrm = new SignDataResponseModel(encodedDataString);
                    File destFile = new File(destinationFilePath);
                    builder = Response.ok().entity((Object)sdrm);
                }
                catch (IOException ex) {
                    logger.error("Operation failed", (Throwable)ex);
                    builder = Response.status((Response.Status)Response.Status.BAD_REQUEST).header("error", (Object)ex.getMessage());
                }
            } else {
                logger.error("destinationFilePath is null");
            }
        } else {
            builder = Response.status((Response.Status)Response.Status.UNAUTHORIZED).header("error", (Object)"Web site not authorized");
        }
        if (builder == null) {
            logger.error("builder is null");
            builder = Response.serverError();
        }
        return builder.build();
    }

    @POST
    public Response signData(SignSimpleDataInputModel input) {
        logger.info("POST signData()");
        return Response.status((Response.Status)Response.Status.NOT_IMPLEMENTED).build();
    }

    @POST
    @jakarta.ws.rs.Path(value="file")
    public Response signFile(SignFileInputModel input, @QueryParam(value="use_pin_session") String usePinSession) {
        logger.info("POST signFile(use_pin_session:{})", (Object)usePinSession);
        SignXAdESWorker worker = new SignXAdESWorker(input);
        if (usePinSession != null && !usePinSession.isEmpty()) {
            char[] oldPin = PinDistributor.getPinForSesssion(usePinSession);
            if (oldPin == null) {
                return Response.status((Response.Status)Response.Status.GONE).build();
            }
            if (input.getPin() == null || input.getPin().trim().isEmpty()) {
                input.setPin(new String(oldPin));
            }
        }
        String sessionId = SchedulerManager.get("PKCS11").scheduleWorker(worker);
        UriBuilder ub = this.uriInfo.getAbsolutePathBuilder();
        URI uri = ub.replacePath("sign/file").path("PKCS11").path(sessionId).build(new Object[0]);
        return Response.created((URI)uri).header("sessionId", (Object)sessionId).build();
    }

    @OPTIONS
    @jakarta.ws.rs.Path(value="file/info")
    public Response getFileInfoOptions() {
        logger.info("getFileInfoOptions()");
        return Response.ok().build();
    }

    @POST
    @jakarta.ws.rs.Path(value="file/info")
    public Response getFileInfo(GetSignatureFileInputModel input) {
        logger.info("POST getFileInfo()");
        XAdESSignatureInfoWorker worker = new XAdESSignatureInfoWorker(SecurityOperationsProviderManager.getDefault(), input.getSignatureFile());
        String sessionId = SchedulerManager.getDefault().scheduleWorker(worker);
        UriBuilder ub = this.uriInfo.getAbsolutePathBuilder();
        URI uri = ub.replacePath("sign/file/info").path(sessionId).build(new Object[0]);
        return Response.created((URI)uri).build();
    }

    @OPTIONS
    @jakarta.ws.rs.Path(value="file/info/{sessionId}")
    public Response getFileInfoResultOptions() {
        logger.info("getFileInfoResultOptions()");
        return Response.ok().build();
    }

    @GET
    @jakarta.ws.rs.Path(value="file/info/{sessionId}")
    public Response getFileInfoResult(@PathParam(value="sessionId") String sessionId) {
        logger.info("GET getFileInfoResult(sessionId:{})", (Object)sessionId);
        Scheduler scheduler = SchedulerManager.getDefault();
        try {
            XadesSignatureModelContainer result = scheduler.getResult(sessionId, XadesSignatureModelContainer.class);
            return Response.ok().entity((Object)result).build();
        }
        catch (OperationFailedException ex) {
            logger.error("Operation failed", (Throwable)ex);
            String message = ex.getLocalizedMessage() != null && !ex.getLocalizedMessage().isEmpty() ? ClientCardManager.exceptionBundle.getString(ex.getLocalizedMessage()) : ex.getMessage();
            return Response.status((Response.Status)Response.Status.BAD_REQUEST).header("error", (Object)message).build();
        }
        catch (InvalidPinException ex) {
            logger.error("Invalid pin", (Throwable)ex);
            return Response.status((Response.Status)Response.Status.UNAUTHORIZED).build();
        }
        catch (ClassCastException ex) {
            return Response.status((Response.Status)Response.Status.CONFLICT).build();
        }
    }

    @OPTIONS
    @jakarta.ws.rs.Path(value="file/verify")
    public Response getFileVerifyOptions() {
        logger.info("getFileVerifyOptions()");
        return Response.ok().build();
    }

    @POST
    @jakarta.ws.rs.Path(value="file/verify")
    public Response verifyFile(VerifySignedFileInputModel input) {
        logger.info("POST verifyFile()");
        VerifySignedFileWorker worker = new VerifySignedFileWorker(SecurityOperationsProviderManager.getDefault(), input.getSignature(), input.getSignedFiles(), input.getSignatureId());
        String sessionId = SchedulerManager.getDefault().scheduleWorker(worker);
        UriBuilder ub = this.uriInfo.getAbsolutePathBuilder();
        URI uri = ub.replacePath("sign/file/verify").path(sessionId).build(new Object[0]);
        return Response.created((URI)uri).build();
    }

    @OPTIONS
    @jakarta.ws.rs.Path(value="file/verify/{sessionId}")
    public Response getFileVerificationResultOptions() {
        logger.info("getFileVerificationResultOptions()");
        return Response.ok().build();
    }

    @GET
    @jakarta.ws.rs.Path(value="file/verify/{sessionId}")
    public Response getSignedFileVerificationResult(@PathParam(value="sessionId") String sessionId) {
        logger.info("GET getSignedFileVerificationResult(sessionId:{})", (Object)sessionId);
        Scheduler scheduler = SchedulerManager.getDefault();
        try {
            VerifySignedFileResponseModel result = scheduler.getResult(sessionId, VerifySignedFileResponseModel.class);
            return Response.ok().entity((Object)result).build();
        }
        catch (OperationFailedException ex) {
            logger.error("Operation failed", (Throwable)ex);
            String message = ex.getLocalizedMessage() != null && !ex.getLocalizedMessage().isEmpty() ? ClientCardManager.exceptionBundle.getString(ex.getLocalizedMessage()) : ex.getMessage();
            return Response.status((Response.Status)Response.Status.BAD_REQUEST).header("error", (Object)message).build();
        }
        catch (InvalidPinException ex) {
            logger.error("Invalid pin", (Throwable)ex);
            return Response.status((Response.Status)Response.Status.UNAUTHORIZED).build();
        }
        catch (ClassCastException ex) {
            return Response.status((Response.Status)Response.Status.CONFLICT).build();
        }
    }

    @POST
    @jakarta.ws.rs.Path(value="pdf/verify")
    public Response verifyPdf(VerifyPdfInputModel input) {
        logger.info("POST verifyPdf()");
        VerifyPDFWorker worker = new VerifyPDFWorker(input);
        String sessionId = SchedulerManager.getDefault().scheduleWorker(worker);
        UriBuilder ub = this.uriInfo.getAbsolutePathBuilder();
        URI uri = ub.replacePath("sign/pdf/verify").path(sessionId).build(new Object[0]);
        return Response.created((URI)uri).build();
    }

    @GET
    @jakarta.ws.rs.Path(value="pdf/verify/{sessionId}")
    public Response getPdfVerificationResult(@PathParam(value="sessionId") String sessionId) {
        logger.info("GET getPdfVerificationResult(sessionId:{})", (Object)sessionId);
        Scheduler scheduler = SchedulerManager.getDefault();
        try {
            VerifyPdfResponseModel result = scheduler.getResult(sessionId, VerifyPdfResponseModel.class);
            return Response.ok().entity((Object)result).build();
        }
        catch (OperationFailedException ex) {
            logger.error("Operation failed", (Throwable)ex);
            String message = ex.getLocalizedMessage() != null && !ex.getLocalizedMessage().isEmpty() ? ClientCardManager.exceptionBundle.getString(ex.getLocalizedMessage()) : ex.getMessage();
            return Response.status((Response.Status)Response.Status.BAD_REQUEST).header("error", (Object)message).build();
        }
        catch (InvalidPinException ex) {
            logger.error("Invalid pin", (Throwable)ex);
            return Response.status((Response.Status)Response.Status.UNAUTHORIZED).build();
        }
        catch (ClassCastException ex) {
            return Response.status((Response.Status)Response.Status.CONFLICT).build();
        }
    }

    @POST
    @jakarta.ws.rs.Path(value="file/delete")
    public Response deleteSignatureFromFile(DeleteSignatureInputModel input) {
        logger.info("POST deleteSignatureFromFile()");
        DeleteSignatureWorker deleteSignatureWorker = new DeleteSignatureWorker(SecurityOperationsProviderManager.getDefault(), input);
        String sessionId = SchedulerManager.getDefault().scheduleWorker(deleteSignatureWorker);
        UriBuilder ub = this.uriInfo.getAbsolutePathBuilder();
        URI uri = ub.replacePath("sign/file/delete").path(sessionId).build(new Object[0]);
        return Response.created((URI)uri).build();
    }

    @GET
    @jakarta.ws.rs.Path(value="file/delete/{sessionId}")
    public Response getSignatureDeleteResult(@PathParam(value="sessionId") String sessionId) {
        logger.info("GET getSignatureDeleteResult(sessionId:{})", (Object)sessionId);
        Scheduler scheduler = SchedulerManager.getDefault();
        try {
            XadesSignatureModelContainer result = scheduler.getResult(sessionId, XadesSignatureModelContainer.class);
            return Response.ok().entity((Object)result).build();
        }
        catch (OperationFailedException ex) {
            logger.error("Operation failed", (Throwable)ex);
            String message = ex.getLocalizedMessage() != null && !ex.getLocalizedMessage().isEmpty() ? ClientCardManager.exceptionBundle.getString(ex.getLocalizedMessage()) : ex.getMessage();
            return Response.status((Response.Status)Response.Status.BAD_REQUEST).header("error", (Object)message).build();
        }
        catch (InvalidPinException ex) {
            logger.error("Invalid pin", (Throwable)ex);
            return Response.status((Response.Status)Response.Status.UNAUTHORIZED).build();
        }
        catch (ClassCastException ex) {
            return Response.status((Response.Status)Response.Status.CONFLICT).build();
        }
    }

    @GET
    @jakarta.ws.rs.Path(value="file/{providerId}/{sessionId}")
    public Response getSignedFile(@PathParam(value="providerId") String providerId, @PathParam(value="sessionId") String sessionId, @DefaultValue(value="0") @QueryParam(value="keep_pin_session") String keepPinSession) {
        logger.info("GET getSignedFile(providerId:{},sessionId:{},keep_pin_session:{})", new Object[]{providerId, sessionId, keepPinSession});
        Scheduler scheduler = SchedulerManager.get("PKCS11");
        try {
            XadesSignatureModelContainer result = scheduler.getResult(sessionId, XadesSignatureModelContainer.class);
            Response.ResponseBuilder resp = Response.ok().entity((Object)result);
            if (!"1".equals(keepPinSession.trim())) {
                PinDistributor.clearPinSession(sessionId);
            }
            return resp.build();
        }
        catch (OperationFailedException ex) {
            logger.error("Operation failed", (Throwable)ex);
            String message = ex.getLocalizedMessage() != null && !ex.getLocalizedMessage().isEmpty() ? ClientCardManager.exceptionBundle.getString(ex.getLocalizedMessage()) : ex.getMessage();
            return Response.status((Response.Status)Response.Status.BAD_REQUEST).header("error", (Object)message).build();
        }
        catch (InvalidPinException ex) {
            logger.error("Invalid pin", (Throwable)ex);
            return Response.status((Response.Status)Response.Status.UNAUTHORIZED).build();
        }
        catch (ClassCastException ex) {
            return Response.status((Response.Status)Response.Status.CONFLICT).build();
        }
    }

    @GET
    @jakarta.ws.rs.Path(value="{providerId}/{sessionId}")
    public Response getSignedDataBase64(@PathParam(value="providerId") String providerId, @PathParam(value="sessionId") String sessionId) {
        logger.info("GET getSignedDataBase64(providerId:{},sessionId:{})", (Object)providerId, (Object)sessionId);
        Scheduler scheduler = SchedulerManager.getDefault();
        try {
            SignSimpleDataResponseModel result = scheduler.getResult(sessionId, SignSimpleDataResponseModel.class);
            return Response.ok().entity((Object)result).build();
        }
        catch (OperationFailedException ex) {
            logger.error("Operation failed", (Throwable)ex);
            String message = ex.getLocalizedMessage() != null && !ex.getLocalizedMessage().isEmpty() ? ClientCardManager.exceptionBundle.getString(ex.getLocalizedMessage()) : ex.getMessage();
            return Response.status((Response.Status)Response.Status.BAD_REQUEST).header("error", (Object)message).build();
        }
        catch (InvalidPinException ex) {
            logger.error("Invalid pin", (Throwable)ex);
            return Response.status((Response.Status)Response.Status.UNAUTHORIZED).build();
        }
        catch (ClassCastException ex) {
            return Response.status((Response.Status)Response.Status.CONFLICT).build();
        }
    }

    @OPTIONS
    @jakarta.ws.rs.Path(value="pdf")
    public Response postPdfOptions() {
        logger.info("postPdfOptions()");
        return Response.ok().build();
    }

    @POST
    @jakarta.ws.rs.Path(value="pdf")
    public Response signPdf(SignPdfInputModel input, @QueryParam(value="use_pin_session") String usePinSession) {
        logger.info("POST signPdf(use_pin_session:{})", (Object)usePinSession);
        if (input == null) {
            logger.warn("input == null");
            return Response.status((Response.Status)Response.Status.BAD_REQUEST).build();
        }
        logger.info("getOriginalFile={}", (Object)input.getOriginalFile());
        CertificateModel cer = input.getCertificate();
        if (cer == null) {
            logger.warn("cer == null");
            return Response.status((Response.Status)Response.Status.BAD_REQUEST).build();
        }
        logger.info("getCertificate={}", (Object)cer);
        boolean usePdfPreview = DriversConfigurationPanel.getUsePdfPreview();
        boolean signatureAppearance = DriversConfigurationPanel.getSignatureAppearance();
        SignPDFWorker worker = new SignPDFWorker(input, usePdfPreview, signatureAppearance);
        String sessionId = SchedulerManager.get("PKCS11").scheduleWorker(worker);
        logger.info("schedule work sessionId={}", (Object)sessionId);
        if (usePinSession != null && !usePinSession.isEmpty()) {
            char[] oldPin = PinDistributor.getPinForSesssion(usePinSession);
            if (oldPin == null) {
                return Response.status((Response.Status)Response.Status.GONE).build();
            }
            if (input.getPin() == null || input.getPin().trim().isEmpty()) {
                input.setPin(new String(oldPin));
            }
        }
        UriBuilder ub = this.uriInfo.getAbsolutePathBuilder();
        URI uri = ub.replacePath("sign/pdf").path("PKCS11").path(sessionId).build(new Object[0]);
        logger.info("uri={}", (Object)uri);
        return Response.created((URI)uri).header("sessionId", (Object)sessionId).build();
    }

    @GET
    @jakarta.ws.rs.Path(value="pdf/{providerId}/{sessionId}")
    @Produces(value={"application/xml", "application/json"})
    public Response getSignedPdf(@PathParam(value="providerId") String providerId, @PathParam(value="sessionId") String sessionId, @DefaultValue(value="0") @QueryParam(value="keep_pin_session") String keepPinSession) {
        logger.info("GET getSignedPdf(providerId:{},sessionId:{},keep_pin_session:{})", new Object[]{providerId, sessionId, keepPinSession});
        Scheduler scheduler = SchedulerManager.get("PKCS11");
        try {
            SignPdfResponseModel result = scheduler.getResult(sessionId, SignPdfResponseModel.class);
            if (!"1".equals(keepPinSession.trim())) {
                PinDistributor.clearPinSession(sessionId);
            }
            return Response.ok().entity((Object)result).build();
        }
        catch (OperationFailedException ex) {
            logger.error("Operation failed", (Throwable)ex);
            String message = ex.getLocalizedMessage() != null && !ex.getLocalizedMessage().isEmpty() ? ClientCardManager.exceptionBundle.getString(ex.getLocalizedMessage()) : ex.getMessage();
            return Response.status((Response.Status)Response.Status.BAD_REQUEST).header("error", (Object)message).build();
        }
        catch (InvalidPinException ex) {
            logger.error("Invalid pin", (Throwable)ex);
            return Response.status((Response.Status)Response.Status.UNAUTHORIZED).build();
        }
        catch (ClassCastException ex) {
            return Response.status((Response.Status)Response.Status.CONFLICT).build();
        }
    }
}

