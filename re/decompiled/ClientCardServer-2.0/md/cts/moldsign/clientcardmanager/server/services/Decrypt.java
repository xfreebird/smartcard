/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  jakarta.ws.rs.GET
 *  jakarta.ws.rs.POST
 *  jakarta.ws.rs.Path
 *  jakarta.ws.rs.PathParam
 *  jakarta.ws.rs.core.Context
 *  jakarta.ws.rs.core.Response
 *  jakarta.ws.rs.core.Response$Status
 *  jakarta.ws.rs.core.UriInfo
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.clientcardmanager.server.services;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.net.URI;
import md.cts.cryptography.providers.SecurityOperationsProviderManager;
import md.cts.cryptography.schedulers.Scheduler;
import md.cts.cryptography.schedulers.SchedulerManager;
import md.cts.moldsign.clientcardmanager.start.ClientCardManager;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.moldsign.transferobjects.models.DecryptFileAsymmetricInputModel;
import md.cts.moldsign.transferobjects.models.EncryptDecryptFileResponseModel;
import md.cts.moldsign.transferobjects.models.EncryptDecryptFileSymmetricInputModel;
import md.cts.pkcs11.cards.exceptions.InvalidPinException;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import md.cts.pkcs11.providers.workers.DecryptCMSAsymmetricWorker;
import md.cts.pkcs11.providers.workers.DecryptCMSSymmetricWorker;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Path(value="decrypt")
public final class Decrypt {
    private static final Logger logger = LoggerFactory.getLogger(Decrypt.class);
    @Context
    UriInfo uriInfo;

    @POST
    @Path(value="symmetric")
    public Response scheduleDecryption(EncryptDecryptFileSymmetricInputModel input) {
        logger.info("scheduleDecryption()");
        DecryptCMSSymmetricWorker encWorker = new DecryptCMSSymmetricWorker(input.getFilePath(), input.getSaveFileTo(), input.getPassword().toCharArray());
        Scheduler scheduler = SchedulerManager.getDefault();
        String session = scheduler.scheduleWorker(encWorker);
        URI uri = this.uriInfo.getAbsolutePathBuilder().replacePath("decrypt/symmetric").path(session).build(new Object[0]);
        return Response.created((URI)uri).build();
    }

    @GET
    @Path(value="symmetric/{sessionId}")
    public Response getEncryptedFileSymmetric(@PathParam(value="sessionId") String sessionId) {
        logger.info("getEncryptedFileSymmetric()");
        Scheduler scheduler = SchedulerManager.getDefault();
        try {
            EncryptDecryptFileResponseModel result = scheduler.getResult(sessionId, EncryptDecryptFileResponseModel.class);
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
    @Path(value="asymmetric")
    public Response scheduleAsymmetricDecryption(DecryptFileAsymmetricInputModel input) {
        logger.info("scheduleAsymmetricDecryption()");
        char[] pin = null;
        if (input.getPin() != null) {
            pin = input.getPin().toCharArray();
        }
        CertificateModel certificate = input.getCertificate();
        DecryptCMSAsymmetricWorker worker = new DecryptCMSAsymmetricWorker(SecurityOperationsProviderManager.getProvider(certificate.getProviderId()), input.getFilePath(), input.getSaveFileTo(), certificate, pin);
        String session = SchedulerManager.get("PKCS11").scheduleWorker(worker);
        URI uri = this.uriInfo.getAbsolutePathBuilder().replacePath("decrypt/asymmetric").path("PKCS11").path(session).build(new Object[0]);
        return Response.created((URI)uri).build();
    }

    @GET
    @Path(value="asymmetric/{providerId}/{sessionId}")
    public Response getEncryptedFileAsymmetric(@PathParam(value="providerId") String providerId, @PathParam(value="sessionId") String sessionId) {
        logger.info("getEncryptedFileAsymmetric()");
        Scheduler scheduler = SchedulerManager.get("PKCS11");
        try {
            EncryptDecryptFileResponseModel result = scheduler.getResult(sessionId, EncryptDecryptFileResponseModel.class);
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

