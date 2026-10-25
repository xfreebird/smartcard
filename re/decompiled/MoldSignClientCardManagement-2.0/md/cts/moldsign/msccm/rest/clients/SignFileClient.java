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
 *  jakarta.ws.rs.core.UriBuilder
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.msccm.rest.clients;

import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.ClientBuilder;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriBuilder;
import java.net.URI;
import md.cts.moldsign.msccm.exceptions.ServerException;
import md.cts.moldsign.transferobjects.models.SignFileInputModel;
import md.cts.moldsign.transferobjects.models.SignPdfInputModel;
import md.cts.moldsign.transferobjects.models.SignPdfResponseModel;
import md.cts.moldsign.transferobjects.models.XAdES.XadesSignatureModelContainer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class SignFileClient {
    private static final Logger logger = LoggerFactory.getLogger(SignFileClient.class);
    private final Client client = ClientBuilder.newClient();
    private final WebTarget baseTarget = this.client.target("http://localhost.cts.md:18480");

    public Inter signFilePost(SignFileInputModel sfim, String pinSessionId) {
        logger.info("signFilePost(sfim:{},pinSessionId:{})", sfim.getFilesToSign(), (Object)pinSessionId);
        WebTarget webTarget = this.baseTarget.path("/sign/file");
        if (pinSessionId != null) {
            webTarget = webTarget.queryParam("use_pin_session", new Object[]{pinSessionId});
        }
        try (Response response = webTarget.request(new String[]{"application/json"}).post(Entity.entity((Object)sfim, (String)"application/json"));){
            if (response.getStatusInfo().getStatusCode() == Response.Status.CREATED.getStatusCode()) {
                Inter inter = new Inter(response.getLocation(), (String)response.getHeaders().getFirst((Object)"sessionId"));
                return inter;
            }
            logger.warn("Sign file (post) failed with status: {}", (Object)response.getStatusInfo());
        }
        return null;
    }

    public Inter signPdfPost(SignPdfInputModel spdf, String pinSessionId) {
        logger.info("signPdfPost(spdf:{},pinSessionId:{})", (Object)spdf.getOriginalFile(), (Object)pinSessionId);
        WebTarget webTarget = this.baseTarget.path("/sign/pdf");
        if (pinSessionId != null) {
            webTarget = webTarget.queryParam("use_pin_session", new Object[]{pinSessionId});
        }
        try (Response response = webTarget.request(new String[]{"application/json"}).post(Entity.entity((Object)spdf, (String)"application/json"));){
            if (response.getStatusInfo().getStatusCode() == Response.Status.CREATED.getStatusCode()) {
                Inter inter = new Inter(response.getLocation(), (String)response.getHeaders().getFirst((Object)"sessionId"));
                return inter;
            }
            logger.warn("Sign PDF (post) failed with status: {}", (Object)response.getStatusInfo());
        }
        return null;
    }

    public XadesSignatureModelContainer signFileGet(URI uri, boolean keepPin) throws ServerException {
        logger.info("signFileGet(uri:{},keepPin:{})", (Object)uri, (Object)keepPin);
        try (Client directClient = ClientBuilder.newClient();){
            UriBuilder ub = UriBuilder.fromUri((URI)uri);
            if (keepPin) {
                ub.queryParam("keep_pin_session", new Object[]{"1"});
            }
            WebTarget webTarget = directClient.target(ub.build(new Object[0]));
            try (Response response = webTarget.request(new String[]{"application/json"}).accept(new String[]{"application/json"}).get();){
                if (response.getStatusInfo().getStatusCode() == Response.Status.OK.getStatusCode()) {
                    XadesSignatureModelContainer xadesSignatureModelContainer = (XadesSignatureModelContainer)response.readEntity(XadesSignatureModelContainer.class);
                    return xadesSignatureModelContainer;
                }
                if (response.getStatusInfo().getStatusCode() == Response.Status.BAD_REQUEST.getStatusCode()) {
                    String errorMessage = response.getHeaderString("error");
                    logger.warn("Sign file (get) failed with status: {} and error: {}", (Object)response.getStatus(), (Object)errorMessage);
                    throw new ServerException(errorMessage);
                }
                logger.warn("Sign file (get) failed with status: {}", (Object)response.getStatus());
            }
        }
        return null;
    }

    public SignPdfResponseModel signPdfGet(URI uri, boolean keepPin) throws ServerException {
        logger.info("signPdfGet(uri:{},keepPin:{})", (Object)uri, (Object)keepPin);
        try (Client directClient = ClientBuilder.newClient();){
            UriBuilder ub = UriBuilder.fromUri((URI)uri);
            if (keepPin) {
                ub.queryParam("keep_pin_session", new Object[]{"1"});
            }
            WebTarget webTarget = directClient.target(ub.build(new Object[0]));
            try (Response response = webTarget.request(new String[]{"application/json"}).accept(new String[]{"application/json"}).get();){
                if (response.getStatusInfo().getStatusCode() == Response.Status.OK.getStatusCode()) {
                    SignPdfResponseModel signPdfResponseModel = (SignPdfResponseModel)response.readEntity(SignPdfResponseModel.class);
                    return signPdfResponseModel;
                }
                if (response.getStatusInfo().getStatusCode() == Response.Status.BAD_REQUEST.getStatusCode()) {
                    String errorMessage = response.getHeaderString("error");
                    logger.warn("Sign PDF (get) failed with status: {} and error: {}", (Object)response.getStatus(), (Object)errorMessage);
                    throw new ServerException(errorMessage);
                }
                logger.warn("Sign PDF (get) failed with status: {}", (Object)response.getStatus());
            }
        }
        return null;
    }

    public record Inter(URI location, String sessionId) {
    }
}

