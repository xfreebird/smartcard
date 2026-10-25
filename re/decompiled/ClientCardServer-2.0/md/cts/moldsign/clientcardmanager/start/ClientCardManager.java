/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.formdev.flatlaf.FlatLightLaf
 *  iaik.security.provider.IAIK
 *  md.ghesar.Intern
 *  md.gov.stisc.Single
 *  md.gov.stisc.Updater
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.clientcardmanager.start;

import com.formdev.flatlaf.FlatLightLaf;
import iaik.security.provider.IAIK;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.Proxy;
import java.net.ProxySelector;
import java.net.Socket;
import java.net.URI;
import java.util.List;
import java.util.Locale;
import java.util.Properties;
import java.util.ResourceBundle;
import javax.swing.SwingUtilities;
import md.cts.cryptography.providers.GlobalCertificateProvider;
import md.cts.cryptography.providers.JKSTrustedCertificateProvider;
import md.cts.cryptography.providers.MSCSPSecurityProvider;
import md.cts.cryptography.providers.SecurityOperationsProviderManager;
import md.cts.moldsign.clientcardmanager.properties.PropertiesLoader;
import md.cts.moldsign.clientcardmanager.server.AllowedSites;
import md.cts.moldsign.clientcardmanager.server.ApiServer;
import md.cts.moldsign.clientcardmanager.start.CardManager;
import md.cts.moldsign.clientcardmanager.ui.main.GnomeTray;
import md.cts.moldsign.clientcardmanager.ui.main.MotoTray;
import md.cts.pkcs11.cards.CardReaderManager;
import md.ghesar.Intern;
import md.gov.stisc.Single;
import md.gov.stisc.Updater;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class ClientCardManager {
    public static final ResourceBundle exceptionBundle = ResourceBundle.getBundle("error_messages");
    private static final Logger logger = LoggerFactory.getLogger(ClientCardManager.class);
    private static ApiServer server;

    public static void main(String[] args) {
        logger.info("main start");
        System.setProperty("dorkbox.updates.Updates.ENABLE", "false");
        FlatLightLaf.setup();
        ClientCardManager.setupProxy();
        PropertiesLoader.init();
        String locale = PropertiesLoader.getProperties("Locale").getProperty("Locale", "");
        Locale.setDefault(Locale.forLanguageTag(locale));
        PropertiesLoader.setupHttpProxy();
        if (ClientCardManager.checkDuplicate()) {
            logger.info("duplicate. main done");
            return;
        }
        Properties app_prop = PropertiesLoader.getProperties("PKCS11");
        Intern.useClassicSystemTray = "true".equals(app_prop.getProperty("use_classic_system_tray", "false"));
        Intern.resetOnSlotListRefresh = "true".equals(app_prop.getProperty("reset_on_slot_list_refresh", "true"));
        if (Intern.useClassicSystemTray) {
            SwingUtilities.invokeLater(MotoTray::showSystemTray);
        } else {
            SwingUtilities.invokeLater(GnomeTray::showSystemTray);
        }
        ClientCardManager.startApplication();
        Updater.startCheckVersion();
        Updater.startDownloadAllowedUrl();
        Updater.startLoadLocalHostJks();
        logger.info("main done");
    }

    private static boolean checkPortsAvailable() {
        logger.info("Checking port availability");
        try {
            InetSocketAddress sockAddress = new InetSocketAddress("localhost.cts.md", 18480);
            Socket tempSocket = new Socket(Proxy.NO_PROXY);
            tempSocket.connect(sockAddress, 1000);
            logger.info("NotOk. Port 18480 in use");
            tempSocket.close();
            return false;
        }
        catch (Exception ex) {
            logger.info("Ok. Port 18480 NOT in use");
            try {
                InetSocketAddress sockAddress = new InetSocketAddress("localhost.cts.md", 18443);
                Socket tempSocket = new Socket(Proxy.NO_PROXY);
                tempSocket.connect(sockAddress, 1000);
                logger.info("NotOk. Port 18443 in use");
                tempSocket.close();
                return false;
            }
            catch (Exception ex2) {
                logger.info("Ok. Port 18443 NOT in use");
                return true;
            }
        }
    }

    private static void setupProxy() {
        System.setProperty("http.nonProxyHosts", "127.0.0.1|localhost|localhost.cts.md");
        System.setProperty("java.net.useSystemProxies", "true");
        try {
            List<Proxy> list = ProxySelector.getDefault().select(new URI("https://stisc.gov.md/"));
            for (Proxy proxy : list) {
                logger.info("proxy type: {}", (Object)proxy.type());
                InetSocketAddress addr = (InetSocketAddress)proxy.address();
                if (addr == null) {
                    logger.info("No Proxy");
                    continue;
                }
                logger.info("proxy hostname: {}", (Object)addr.getHostName());
                logger.info("proxy port: {}", (Object)addr.getPort());
            }
        }
        catch (Exception ex) {
            logger.error("", (Throwable)ex);
        }
    }

    private static boolean checkDuplicate() {
        logger.info("checkDuplicate");
        return !ClientCardManager.checkPortsAvailable();
    }

    private static void startApplication() {
        logger.info("IAIK.addAsProvider()");
        IAIK.addAsProvider();
        if (Single.isWindows && PropertiesLoader.useMscsp()) {
            MSCSPSecurityProvider msCspSecurityProvider = new MSCSPSecurityProvider();
            SecurityOperationsProviderManager.registerProvider("MSCSP", msCspSecurityProvider);
            GlobalCertificateProvider.get().registerProvider(msCspSecurityProvider, false);
        }
        GlobalCertificateProvider.get().registerProvider(new JKSTrustedCertificateProvider(), true);
        CardManager cardManager = new CardManager();
        CardReaderManager.get().registerCardActionObserver(cardManager);
        List<String> driverLibs = PropertiesLoader.readDrivers();
        CardReaderManager.get().loadDriverLibList(driverLibs);
        CardReaderManager.get().startListeners();
        AllowedSites.initializeAllowedUrl();
        ClientCardManager.startApiServer();
        ClientCardManager.setupOnExitHandler();
    }

    private static void startApiServer() {
        try {
            server = new ApiServer();
            server.start();
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
        }
    }

    public static void stopApplication() {
        CardReaderManager.get().stopListening();
        server.stop();
    }

    private static void setupOnExitHandler() {
        Runtime.getRuntime().addShutdownHook(new Thread(ClientCardManager::stopApplication));
    }

    static {
        Single.init();
    }
}

