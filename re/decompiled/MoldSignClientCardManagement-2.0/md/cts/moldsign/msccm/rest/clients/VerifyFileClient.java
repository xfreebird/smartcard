/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  jakarta.ws.rs.client.Client
 *  jakarta.ws.rs.client.ClientBuilder
 *  jakarta.ws.rs.client.Entity
 *  jakarta.ws.rs.client.WebTarget
 *  jakarta.ws.rs.core.Response
 *  jakarta.ws.rs.core.Response$Status
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.msccm.rest.clients;

import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.ClientBuilder;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.core.Response;
import java.net.URI;
import md.cts.moldsign.msccm.exceptions.ServerException;
import md.cts.moldsign.transferobjects.models.VerifySignedFileInputModel;
import md.cts.moldsign.transferobjects.models.VerifySignedFileResponseModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class VerifyFileClient {
    private static final Logger logger = LoggerFactory.getLogger(VerifyFileClient.class);
    private final Client client = ClientBuilder.newClient();
    private final WebTarget baseTarget = this.client.target("http://localhost.cts.md:18480");

    public URI verifySignedFilePost(VerifySignedFileInputModel vsfim) {
        logger.info("verifySignedFilePost(vsfim:{})", vsfim.getSignedFiles());
        WebTarget webTarget = this.baseTarget.path("/sign/file/verify");
        try (Response response = webTarget.request(new String[]{"application/json"}).post(Entity.entity((Object)vsfim, (String)"application/json"));){
            if (response.getStatusInfo().getStatusCode() == Response.Status.CREATED.getStatusCode()) {
                URI uRI = response.getLocation();
                return uRI;
            }
            logger.warn("Verify signed file (post) failed with status: {}", (Object)response.getStatus());
        }
        return null;
    }

    public VerifySignedFileResponseModel verifySignedFileGet(URI uri) throws ServerException {
        logger.info("verifySignedFileGet(uri:{})", (Object)uri);
        try (Client directClient = ClientBuilder.newClient();){
            WebTarget webTarget = directClient.target(uri);
            try (Response response = webTarget.request(new String[]{"application/json"}).accept(new String[]{"application/json"}).get();){
                if (response.getStatusInfo().getStatusCode() == Response.Status.OK.getStatusCode()) {
                    VerifySignedFileResponseModel verifySignedFileResponseModel = (VerifySignedFileResponseModel)response.readEntity(VerifySignedFileResponseModel.class);
                    return verifySignedFileResponseModel;
                }
                if (response.getStatusInfo().getStatusCode() == Response.Status.BAD_REQUEST.getStatusCode()) {
                    String errorMessage = response.getHeaderString("error");
                    logger.warn("Verify signed file (get) failed with status: {} and error: {}", (Object)response.getStatus(), (Object)errorMessage);
                    throw new ServerException(errorMessage);
                }
                logger.warn("Verify signed file (get) failed with status: {}", (Object)response.getStatus());
            }
        }
        return null;
    }
}

