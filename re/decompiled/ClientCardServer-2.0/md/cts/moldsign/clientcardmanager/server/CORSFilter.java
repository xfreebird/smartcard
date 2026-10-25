/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  jakarta.ws.rs.container.ContainerRequestContext
 *  jakarta.ws.rs.container.ContainerResponseContext
 *  jakarta.ws.rs.container.ContainerResponseFilter
 *  jakarta.ws.rs.core.MultivaluedMap
 *  jakarta.ws.rs.ext.Provider
 */
package md.cts.moldsign.clientcardmanager.server;

import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.ext.Provider;
import java.io.IOException;

@Provider
public final class CORSFilter
implements ContainerResponseFilter {
    public void filter(ContainerRequestContext requestContext, ContainerResponseContext responseContext) throws IOException {
        String origin = requestContext.getHeaderString("Origin");
        if (origin == null) {
            origin = "*";
        }
        MultivaluedMap hdr = responseContext.getHeaders();
        hdr.add((Object)"Access-Control-Allow-Origin", (Object)origin);
        hdr.add((Object)"Access-Control-Allow-Methods", (Object)"GET, POST, OPTIONS");
        hdr.add((Object)"Access-Control-Allow-Headers", (Object)"Origin, x-requested-with, content-type, accept, error, Location");
        hdr.add((Object)"Access-Control-Expose-Headers", (Object)"Origin, x-requested-with, content-type, accept, error, Location");
        hdr.add((Object)"Access-Control-Max-Age", (Object)"3600");
    }
}

