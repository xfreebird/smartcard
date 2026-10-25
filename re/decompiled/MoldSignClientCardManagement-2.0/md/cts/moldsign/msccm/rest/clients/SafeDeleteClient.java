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
import md.cts.moldsign.transferobjects.models.SafeDeleteInputModel;
import md.cts.moldsign.transferobjects.models.SafeDeleteResponseModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class SafeDeleteClient {
    private static final Logger logger = LoggerFactory.getLogger(SafeDeleteClient.class);
    private final Client client = ClientBuilder.newClient();
    private final WebTarget baseTarget = this.client.target("http://localhost.cts.md:18480");

    public URI safeDeletePost(SafeDeleteInputModel sdim) {
        logger.info("safeDeletePost(sdim:{})", (Object)sdim.getFile());
        WebTarget webTarget = this.baseTarget.path("/delete");
        Response response = webTarget.request(new String[]{"application/json"}).post(Entity.entity((Object)sdim, (String)"application/json"));
        if (response.getStatusInfo().getStatusCode() == Response.Status.CREATED.getStatusCode()) {
            return response.getLocation();
        }
        logger.warn("Safe delete (post) failed with status: {}", (Object)response.getStatus());
        return null;
    }

    public SafeDeleteResponseModel safeDeleteGet(URI uri) throws ServerException {
        logger.info("safeDeleteGet(uri:{})", (Object)uri);
        Client directClient = ClientBuilder.newClient();
        WebTarget webTarget = directClient.target(uri);
        Response response = webTarget.request(new String[]{"application/json"}).accept(new String[]{"application/json"}).get();
        if (response.getStatusInfo().getStatusCode() == Response.Status.OK.getStatusCode()) {
            return (SafeDeleteResponseModel)response.readEntity(SafeDeleteResponseModel.class);
        }
        if (response.getStatusInfo().getStatusCode() == Response.Status.BAD_REQUEST.getStatusCode()) {
            String errorMessage = response.getHeaderString("error");
            logger.warn("Safe delete (get) failed with status: {} and error: {}", (Object)response.getStatus(), (Object)errorMessage);
            throw new ServerException(errorMessage);
        }
        logger.warn("Safe delete (get) failed with status: {}", (Object)response.getStatus());
        return null;
    }
}

