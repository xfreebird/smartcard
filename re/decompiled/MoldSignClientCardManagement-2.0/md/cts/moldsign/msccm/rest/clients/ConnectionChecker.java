/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  jakarta.ws.rs.client.Client
 *  jakarta.ws.rs.client.ClientBuilder
 *  jakarta.ws.rs.client.WebTarget
 *  jakarta.ws.rs.core.Response
 *  jakarta.ws.rs.core.Response$Status$Family
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.msccm.rest.clients;

import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.ClientBuilder;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.core.Response;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class ConnectionChecker {
    private static final Logger logger = LoggerFactory.getLogger(ConnectionChecker.class);

    public static boolean canConnectToServer() {
        logger.info("checkConnection()");
        long end = System.currentTimeMillis() + 40000L;
        boolean b = false;
        while (System.currentTimeMillis() <= end && !(b = ConnectionChecker.checkConnection())) {
            try {
                Thread.sleep(512L);
            }
            catch (InterruptedException ex) {
                logger.error("", (Throwable)ex);
            }
        }
        return b;
    }

    private static boolean checkConnection() {
        boolean bl;
        block8: {
            Client client = ClientBuilder.newClient();
            try {
                WebTarget webTarget = client.target("http://localhost.cts.md:18480/hello");
                Response response = webTarget.request(new String[]{"text/plain"}).get();
                boolean bl2 = bl = response.getStatusInfo().getFamily() == Response.Status.Family.SUCCESSFUL;
                if (client == null) break block8;
            }
            catch (Throwable throwable) {
                try {
                    if (client != null) {
                        try {
                            client.close();
                        }
                        catch (Throwable throwable2) {
                            throwable.addSuppressed(throwable2);
                        }
                    }
                    throw throwable;
                }
                catch (Exception ex) {
                    logger.error("{}", (Object)ex.getMessage());
                    return false;
                }
            }
            client.close();
        }
        return bl;
    }
}

