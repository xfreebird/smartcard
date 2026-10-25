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
import md.cts.moldsign.transferobjects.models.DeleteSignatureInputModel;
import md.cts.moldsign.transferobjects.models.XAdES.GetSignatureFileInputModel;
import md.cts.moldsign.transferobjects.models.XAdES.XadesSignatureModelContainer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class SignaturesClient {
    private static final Logger logger = LoggerFactory.getLogger(SignaturesClient.class);
    private final Client client = ClientBuilder.newClient();
    private final WebTarget baseTarget = this.client.target("http://localhost.cts.md:18480");

    public URI getSignatureInfo(GetSignatureFileInputModel gsfim) {
        logger.info("getSignatureInfo(gsfim:{})", (Object)gsfim.getSignatureFile());
        WebTarget webTarget = this.baseTarget.path("/sign/file/info");
        try (Response response = webTarget.request(new String[]{"application/json"}).post(Entity.entity((Object)gsfim, (String)"application/json"));){
            URI uRI = response.getLocation();
            return uRI;
        }
    }

    public XadesSignatureModelContainer signatureFileResult(URI uri) throws ServerException {
        logger.info("signatureFileResult(uri:{})", (Object)uri);
        try (Client directClient = ClientBuilder.newClient();){
            WebTarget webTarget = directClient.target(uri);
            Response response = webTarget.request(new String[]{"application/json"}).accept(new String[]{"application/json"}).get();
            if (response.getStatusInfo().getStatusCode() == Response.Status.OK.getStatusCode()) {
                XadesSignatureModelContainer xadesSignatureModelContainer = (XadesSignatureModelContainer)response.readEntity(XadesSignatureModelContainer.class);
                return xadesSignatureModelContainer;
            }
            if (response.getStatusInfo().getStatusCode() == Response.Status.BAD_REQUEST.getStatusCode()) {
                String errorMessage = response.getHeaderString("error");
                logger.warn("Get signature file result failed with status: {} and error: {}", (Object)response.getStatus(), (Object)errorMessage);
                throw new ServerException(errorMessage);
            }
            logger.warn("Get signature file result failed with status: {}", (Object)response.getStatus());
        }
        return null;
    }

    public URI deleteSignature(DeleteSignatureInputModel dsim) {
        logger.info("deleteSignature(dsim:{})", (Object)dsim.getSignatureFile());
        WebTarget webTarget = this.baseTarget.path("/sign/file/delete");
        try (Response response = webTarget.request(new String[]{"application/json"}).post(Entity.entity((Object)dsim, (String)"application/json"));){
            URI uRI = response.getLocation();
            return uRI;
        }
    }

    public XadesSignatureModelContainer deleteSignatureResult(URI uri) throws ServerException {
        logger.info("deleteSignatureResult(uri:{})", (Object)uri);
        try (Client directClient = ClientBuilder.newClient();){
            WebTarget webTarget = directClient.target(uri);
            Response response = webTarget.request(new String[]{"application/json"}).accept(new String[]{"application/json"}).get();
            if (response.getStatusInfo().getStatusCode() == Response.Status.OK.getStatusCode()) {
                XadesSignatureModelContainer xadesSignatureModelContainer = (XadesSignatureModelContainer)response.readEntity(XadesSignatureModelContainer.class);
                return xadesSignatureModelContainer;
            }
            if (response.getStatusInfo().getStatusCode() == Response.Status.BAD_REQUEST.getStatusCode()) {
                String errorMessage = response.getHeaderString("error");
                logger.warn("Delete signature result failed with status: {} and error: {}", (Object)response.getStatus(), (Object)errorMessage);
                throw new ServerException(errorMessage);
            }
            logger.warn("Delete signature result failed with status: {}", (Object)response.getStatus());
        }
        return null;
    }
}

