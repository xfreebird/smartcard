/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  jakarta.ws.rs.GET
 *  jakarta.ws.rs.Path
 *  jakarta.ws.rs.Produces
 *  jakarta.ws.rs.core.Response
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.clientcardmanager.server.services;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Response;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Path(value="hello")
public final class HelloWorld {
    private static final Logger logger = LoggerFactory.getLogger(HelloWorld.class);

    @GET
    @Produces(value={"text/plain"})
    public Response hello() {
        logger.info("hello()");
        return Response.ok().entity((Object)"Hello world").build();
    }
}

