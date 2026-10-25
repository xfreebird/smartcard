/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.asn1.DerInputException
 *  jakarta.ws.rs.client.Client
 *  jakarta.ws.rs.client.ClientBuilder
 *  jakarta.ws.rs.client.Entity
 *  jakarta.ws.rs.client.WebTarget
 *  jakarta.ws.rs.core.Response
 *  jakarta.ws.rs.core.Response$Status
 *  jakarta.ws.rs.core.Response$Status$Family
 *  jakarta.ws.rs.core.Response$StatusType
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.msccm.rest.clients;

import iaik.asn1.DerInputException;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.ClientBuilder;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.core.Response;
import java.io.IOException;
import md.cts.moldsign.msccm.exceptions.ServerException;
import md.cts.moldsign.transferobjects.models.CertificateListModel;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.moldsign.transferobjects.models.SingleCertificatesModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class CertificatesClient {
    private static final Logger logger = LoggerFactory.getLogger(CertificatesClient.class);
    private final Client client = ClientBuilder.newClient();
    private final WebTarget baseTarget = this.client.target("http://localhost.cts.md:18480");

    public CertificateListModel getListOfCertificatesAll() {
        return this.getListOfCertificates(false);
    }

    public CertificateListModel getListOfCertificatesPrivateOnly() {
        return this.getListOfCertificates(true);
    }

    private CertificateListModel getListOfCertificates(boolean privateOnly) {
        logger.info("getListOfCertificates(privateOnly:{})", (Object)privateOnly);
        CertificateListModel responseModel = null;
        WebTarget webTarget = this.baseTarget.path("certificates").queryParam("private_only", new Object[]{privateOnly ? "true" : "false"});
        try (Response response = webTarget.request(new String[]{"application/json"}).header("moldSign", (Object)"DesktopSuiteClient").get();){
            if (response.getStatusInfo().getFamily() == Response.Status.Family.SUCCESSFUL) {
                responseModel = (CertificateListModel)response.readEntity(CertificateListModel.class);
            } else {
                logger.warn("Failed to get certificates (privateOnly: {}), status: {}", (Object)privateOnly, (Object)response.getStatus());
            }
        }
        catch (Exception ex) {
            logger.warn("getting response as CertificateListModel", (Throwable)ex);
            try {
                Response singleResponse = webTarget.request(new String[]{"application/json"}).header("moldSign", (Object)"DesktopSuiteClient").get();
                if (singleResponse.getStatusInfo().getFamily() == Response.Status.Family.SUCCESSFUL) {
                    SingleCertificatesModel model = (SingleCertificatesModel)singleResponse.readEntity(SingleCertificatesModel.class);
                    responseModel = new CertificateListModel();
                    responseModel.getCertificateModel().add(model.getCertificateModel());
                } else {
                    logger.error("Failed to get single certificate model (privateOnly: {}), status: {}", (Object)privateOnly, (Object)singleResponse.getStatus());
                }
            }
            catch (Exception singleEx) {
                logger.error("getting response as SingleCertificatesModel", (Throwable)singleEx);
            }
        }
        return responseModel != null ? responseModel : new CertificateListModel();
    }

    public CertificateModel findEncryptedFileCertificate(String filePath) throws IOException, ServerException {
        logger.info("findEncryptedFileCertificate(filePath:{})", (Object)filePath);
        WebTarget webTarget = this.baseTarget.path("certificates/fileChecker");
        try (Response response = webTarget.request(new String[]{"application/json"}).post(Entity.entity((Object)filePath, (String)"application/json"));){
            Response.StatusType status = response.getStatusInfo();
            if (status.getFamily() == Response.Status.Family.SUCCESSFUL) {
                CertificateModel certificateModel = (CertificateModel)response.readEntity(CertificateModel.class);
                return certificateModel;
            }
            if (status.getStatusCode() == Response.Status.UNSUPPORTED_MEDIA_TYPE.getStatusCode()) {
                throw new DerInputException("File not encrypted");
            }
            if (status.getStatusCode() == Response.Status.BAD_REQUEST.getStatusCode()) {
                throw new IOException("IO problems");
            }
            if (status.getStatusCode() == Response.Status.UNAUTHORIZED.getStatusCode()) {
                throw new ServerException("No suitable certificate");
            }
            logger.warn("Failed to find encrypted file certificate for path: {}, status: {}", (Object)filePath, (Object)response.getStatus());
            CertificateModel certificateModel = null;
            return certificateModel;
        }
    }

    public boolean refreshCertificates() {
        logger.info("refreshCertificates()");
        WebTarget webTarget = this.baseTarget.path("certificates/refresh");
        try (Response response = webTarget.request(new String[]{"application/json"}).post(Entity.entity((Object)"", (String)"application/json"));){
            boolean bl = response.getStatusInfo().getFamily() == Response.Status.Family.SUCCESSFUL;
            return bl;
        }
    }
}

