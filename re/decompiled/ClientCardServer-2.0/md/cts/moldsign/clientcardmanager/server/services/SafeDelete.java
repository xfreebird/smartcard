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
import md.cts.cryptography.schedulers.SchedulerManager;
import md.cts.moldsign.clientcardmanager.start.ClientCardManager;
import md.cts.moldsign.transferobjects.models.SafeDeleteInputModel;
import md.cts.moldsign.transferobjects.models.SafeDeleteResponseModel;
import md.cts.pkcs11.cards.exceptions.InvalidPinException;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import md.cts.pkcs11.providers.workers.SafeDeleteWorker;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Path(value="delete")
public final class SafeDelete {
    private static final Logger logger = LoggerFactory.getLogger(SafeDelete.class);
    @Context
    UriInfo uriInfo;

    @POST
    public Response scheduleDelete(SafeDeleteInputModel input) {
        logger.info("scheduleDelete()");
        SafeDeleteWorker worker = new SafeDeleteWorker(input.getFile(), input.getAlgorithm(), input.getNrRetries());
        String session = SchedulerManager.getDefault().scheduleWorker(worker);
        URI uri = this.uriInfo.getAbsolutePathBuilder().replacePath("delete").path(session).build(new Object[0]);
        return Response.created((URI)uri).build();
    }

    @GET
    @Path(value="{sessionId}")
    public Response getDeleteResult(@PathParam(value="sessionId") String sessionId) {
        logger.info("getDeleteResult()");
        try {
            SafeDeleteResponseModel result = SchedulerManager.getDefault().getResult(sessionId, SafeDeleteResponseModel.class);
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

