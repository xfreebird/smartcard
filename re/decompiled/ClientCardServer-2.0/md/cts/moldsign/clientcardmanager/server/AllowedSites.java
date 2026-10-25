/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.gov.stisc.Updater
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.clientcardmanager.server;

import java.io.BufferedInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import java.util.jar.JarFile;
import java.util.zip.ZipEntry;
import md.cts.pkcs11.global.JarChecker;
import md.gov.stisc.Updater;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class AllowedSites {
    private static final Logger logger = LoggerFactory.getLogger(AllowedSites.class);
    private static List<String> allowedUrlList = null;

    public static List<String> getAllowedUrlList() {
        return allowedUrlList;
    }

    public static void initializeAllowedUrl() {
        logger.info("initAllowedUrl");
        ArrayList<String> allowedUrl = new ArrayList<String>();
        Properties prop = AllowedSites.checkAllowedJar();
        for (Object page : prop.values()) {
            if (!(page instanceof String)) continue;
            String url = (String)page;
            String regexUrl = url.replaceAll("\\.", "\\\\.").replaceAll("\\?", ".?").replaceAll("\\*", ".*");
            allowedUrl.add(regexUrl);
        }
        allowedUrlList = allowedUrl;
    }

    private static Properties checkAllowedJar() {
        Properties prop = new Properties();
        if (!JarChecker.checkJar(Updater.allowedSitesJar)) {
            return prop;
        }
        try (JarFile jarFile = new JarFile(Updater.allowedSitesJar);){
            ZipEntry entry = jarFile.getEntry("md/allowedURL.properties");
            if (entry != null) {
                BufferedInputStream ist = new BufferedInputStream(jarFile.getInputStream(entry));
                try {
                    prop.load(ist);
                }
                catch (IOException ex) {
                    logger.error("Can not load Allowed Url list", (Throwable)ex);
                }
            }
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
        }
        return prop;
    }
}

