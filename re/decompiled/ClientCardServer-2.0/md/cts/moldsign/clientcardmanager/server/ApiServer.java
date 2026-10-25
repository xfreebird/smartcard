/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.fasterxml.jackson.jakarta.rs.xml.JacksonXMLProvider
 *  jakarta.ws.rs.core.Application
 *  md.gov.stisc.Updater
 *  org.glassfish.grizzly.http.server.HttpHandler
 *  org.glassfish.grizzly.http.server.HttpServer
 *  org.glassfish.grizzly.http.server.NetworkListener
 *  org.glassfish.grizzly.http.server.ServerConfiguration
 *  org.glassfish.grizzly.ssl.SSLContextConfigurator
 *  org.glassfish.grizzly.ssl.SSLEngineConfigurator
 *  org.glassfish.jersey.server.ContainerFactory
 *  org.glassfish.jersey.server.ResourceConfig
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.clientcardmanager.server;

import com.fasterxml.jackson.jakarta.rs.xml.JacksonXMLProvider;
import jakarta.ws.rs.core.Application;
import java.io.File;
import java.io.IOException;
import md.cts.moldsign.clientcardmanager.server.CORSFilter;
import md.cts.moldsign.clientcardmanager.server.services.Certificates;
import md.cts.moldsign.clientcardmanager.server.services.Decrypt;
import md.cts.moldsign.clientcardmanager.server.services.Encrypt;
import md.cts.moldsign.clientcardmanager.server.services.HelloWorld;
import md.cts.moldsign.clientcardmanager.server.services.SafeDelete;
import md.cts.moldsign.clientcardmanager.server.services.Signature;
import md.gov.stisc.Updater;
import org.glassfish.grizzly.http.server.HttpHandler;
import org.glassfish.grizzly.http.server.HttpServer;
import org.glassfish.grizzly.http.server.NetworkListener;
import org.glassfish.grizzly.http.server.ServerConfiguration;
import org.glassfish.grizzly.ssl.SSLContextConfigurator;
import org.glassfish.grizzly.ssl.SSLEngineConfigurator;
import org.glassfish.jersey.server.ContainerFactory;
import org.glassfish.jersey.server.ResourceConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class ApiServer {
    private static final Logger logger = LoggerFactory.getLogger(ApiServer.class);
    private HttpServer seServer;

    public ApiServer() {
        this.initSecureServer();
    }

    private static SSLEngineConfigurator getEngineConfigurator() {
        SSLContextConfigurator sslContext = new SSLContextConfigurator(false);
        sslContext.setTrustStoreFile(Updater.localhostJks);
        sslContext.setKeyStoreFile(Updater.localhostJks);
        sslContext.setTrustStorePass("u9mUvI9BNb1U9jSbpBKf36YWINVK5XX5KAzql3bILNnjscVfLn");
        sslContext.setKeyStorePass("u9mUvI9BNb1U9jSbpBKf36YWINVK5XX5KAzql3bILNnjscVfLn");
        sslContext.setKeyPass("u9mUvI9BNb1U9jSbpBKf36YWINVK5XX5KAzql3bILNnjscVfLn");
        SSLEngineConfigurator sslConfig = new SSLEngineConfigurator(sslContext, false, false, false);
        sslConfig.setEnabledProtocols(new String[]{"TLSv1.2", "TLSv1.3"});
        sslConfig.setEnabledCipherSuites(new String[]{"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256", "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384", "TLS_AES_128_GCM_SHA256", "TLS_AES_256_GCM_SHA384"});
        return sslConfig;
    }

    private void initSecureServer() {
        logger.info("init server");
        File storeFile = new File(Updater.localhostJks);
        if (!storeFile.exists()) {
            logger.error("jks not found");
            return;
        }
        NetworkListener listener1 = new NetworkListener("http", "localhost.cts.md", 18480);
        listener1.getFileCache().setEnabled(false);
        NetworkListener listener2 = new NetworkListener("https", "localhost.cts.md", 18443);
        listener2.getFileCache().setEnabled(false);
        listener2.setSecure(true);
        SSLEngineConfigurator sslConfig = ApiServer.getEngineConfigurator();
        listener2.setSSLEngineConfig(sslConfig);
        this.seServer = new HttpServer();
        this.seServer.addListener(listener1);
        this.seServer.addListener(listener2);
        ResourceConfig resourceConfig = new ResourceConfig();
        resourceConfig.register(JacksonXMLProvider.class);
        resourceConfig.register(CORSFilter.class);
        resourceConfig.register(Certificates.class);
        resourceConfig.register(Decrypt.class);
        resourceConfig.register(Encrypt.class);
        resourceConfig.register(HelloWorld.class);
        resourceConfig.register(SafeDelete.class);
        resourceConfig.register(Signature.class);
        HttpHandler httpHandler = (HttpHandler)ContainerFactory.createContainer(HttpHandler.class, (Application)resourceConfig);
        ServerConfiguration config = this.seServer.getServerConfiguration();
        config.addHttpHandler(httpHandler, new String[]{"/"});
    }

    public void start() throws IOException {
        logger.info("Starting API server");
        this.seServer.start();
    }

    public void stop() {
        logger.info("Stopping API server");
        this.seServer.shutdownNow();
    }
}

