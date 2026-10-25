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
import md.cts.moldsign.transferobjects.models.DecryptFileAsymmetricInputModel;
import md.cts.moldsign.transferobjects.models.EncryptDecryptFileResponseModel;
import md.cts.moldsign.transferobjects.models.EncryptDecryptFileSymmetricInputModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class DecryptClient {
    private static final Logger logger = LoggerFactory.getLogger(DecryptClient.class);
    private final Client client = ClientBuilder.newClient();
    private final WebTarget baseTarget = this.client.target("http://localhost.cts.md:18480");

    public URI decryptSymetricPost(EncryptDecryptFileSymmetricInputModel input) {
        logger.info("decryptSymetricPost(input:{})", (Object)input.getFilePath());
        WebTarget webTarget = this.baseTarget.path("/decrypt/symmetric");
        Response response = webTarget.request(new String[]{"application/json"}).post(Entity.entity((Object)input, (String)"application/json"));
        if (response.getStatusInfo().getStatusCode() == Response.Status.CREATED.getStatusCode()) {
            return response.getLocation();
        }
        logger.warn("Symmetric decryption failed with status: {}", (Object)response.getStatus());
        return null;
    }

    public URI decryptAsymetricPost(DecryptFileAsymmetricInputModel input) {
        logger.info("decryptAsymetricPost(input:{})", (Object)input.getFilePath());
        WebTarget webTarget = this.baseTarget.path("/decrypt/asymmetric");
        Response response = webTarget.request(new String[]{"application/json"}).post(Entity.entity((Object)input, (String)"application/json"));
        if (response.getStatusInfo().getStatusCode() == Response.Status.CREATED.getStatusCode()) {
            return response.getLocation();
        }
        logger.warn("Asymmetric decryption (post) failed with status: {}", (Object)response.getStatus());
        return null;
    }

    public EncryptDecryptFileResponseModel decryptAsymetricSymetricGet(URI uri) throws ServerException {
        logger.info("decryptAsymetricSymetricGet(uri:{})", (Object)uri);
        Client directClient = ClientBuilder.newClient();
        WebTarget webTarget = directClient.target(uri);
        Response response = webTarget.request(new String[]{"application/json"}).accept(new String[]{"application/json"}).get();
        if (response.getStatusInfo().getStatusCode() == Response.Status.OK.getStatusCode()) {
            return (EncryptDecryptFileResponseModel)response.readEntity(EncryptDecryptFileResponseModel.class);
        }
        if (response.getStatusInfo().getStatusCode() == Response.Status.BAD_REQUEST.getStatusCode()) {
            String errorMessage = response.getHeaderString("error");
            logger.warn("Asymmetric/symmetric decryption (get) failed with status: {} and error: {}", (Object)response.getStatus(), (Object)errorMessage);
            throw new ServerException(errorMessage);
        }
        logger.warn("Asymmetric/symmetric decryption (get) failed with status: {}", (Object)response.getStatus());
        return null;
    }
}

