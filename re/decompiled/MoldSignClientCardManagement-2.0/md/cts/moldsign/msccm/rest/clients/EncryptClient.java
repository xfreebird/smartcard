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
import md.cts.moldsign.transferobjects.models.EncryptDecryptFileResponseModel;
import md.cts.moldsign.transferobjects.models.EncryptDecryptFileSymmetricInputModel;
import md.cts.moldsign.transferobjects.models.EncryptFileAsymmetricInputModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class EncryptClient {
    private static final Logger logger = LoggerFactory.getLogger(EncryptClient.class);
    private final Client client = ClientBuilder.newClient();
    private final WebTarget baseTarget = this.client.target("http://localhost.cts.md:18480");

    public URI encryptSymetricPost(EncryptDecryptFileSymmetricInputModel input) {
        logger.info("encryptSymetricPost(input:{})", (Object)input.getFilePath());
        WebTarget webTarget = this.baseTarget.path("/encrypt/symmetric");
        Response response = webTarget.request(new String[]{"application/json"}).post(Entity.entity((Object)input, (String)"application/json"));
        if (response.getStatusInfo().getStatusCode() == Response.Status.CREATED.getStatusCode()) {
            return response.getLocation();
        }
        logger.warn("Symmetric encryption (post) failed with status: {}", (Object)response.getStatus());
        return null;
    }

    public URI encryptAsymetricPost(EncryptFileAsymmetricInputModel input) {
        logger.info("encryptAsymetricPost(input:{})", (Object)input.getFilePath());
        WebTarget webTarget = this.baseTarget.path("/encrypt/asymmetric");
        Response response = webTarget.request(new String[]{"application/json"}).post(Entity.entity((Object)input, (String)"application/json"));
        if (response.getStatusInfo().getStatusCode() == Response.Status.CREATED.getStatusCode()) {
            return response.getLocation();
        }
        logger.warn("Asymmetric encryption (post) failed with status: {}", (Object)response.getStatus());
        return null;
    }

    public EncryptDecryptFileResponseModel encryptAsymetricSymetricGet(URI uri) throws ServerException {
        logger.info("encryptAsymetricSymetricGet(uri:{})", (Object)uri);
        Client directClient = ClientBuilder.newClient();
        WebTarget webTarget = directClient.target(uri);
        Response response = webTarget.request(new String[]{"application/json"}).accept(new String[]{"application/json"}).get();
        if (response.getStatusInfo().getStatusCode() == Response.Status.OK.getStatusCode()) {
            return (EncryptDecryptFileResponseModel)response.readEntity(EncryptDecryptFileResponseModel.class);
        }
        if (response.getStatusInfo().getStatusCode() == Response.Status.BAD_REQUEST.getStatusCode()) {
            String errorMessage = response.getHeaderString("error");
            logger.warn("Asymmetric/symmetric encryption (get) failed with status: {} and error: {}", (Object)response.getStatus(), (Object)errorMessage);
            throw new ServerException(errorMessage);
        }
        logger.warn("Asymmetric/symmetric encryption (get) failed with status: {}", (Object)response.getStatus());
        return null;
    }
}

