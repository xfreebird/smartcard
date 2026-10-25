/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.gov.stisc.Single
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.clientcardmanager.properties;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import md.gov.stisc.Single;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class PropertiesLoader {
    private static final Logger logger = LoggerFactory.getLogger(PropertiesLoader.class);
    private static final Map<String, Properties> propertiesMap = new HashMap<String, Properties>();
    private static File propertiesFolder = null;

    public static void init() {
        File folder = new File(Single.appDataDirectory);
        if (folder.exists() && folder.isDirectory()) {
            propertiesFolder = folder;
        }
    }

    public static Properties getProperties(String propsCategory) {
        if (propertiesMap.containsKey(propsCategory)) {
            return propertiesMap.get(propsCategory);
        }
        Properties props = new Properties();
        try (InputStream propsStream = PropertiesLoader.getPropertiesStream(propsCategory);){
            if (propsStream != null) {
                props.load(propsStream);
            }
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
        }
        propertiesMap.put(propsCategory, props);
        return props;
    }

    public static void setProperty(String propsCategory, String propsName, String propsValue) {
        Properties props = PropertiesLoader.getProperties(propsCategory);
        try (OutputStream propsStream = PropertiesLoader.getPropertiesOutputStream(propsCategory);){
            props.setProperty(propsName, propsValue);
            if (propsStream != null) {
                props.store(propsStream, null);
            }
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
        }
    }

    public static List<String> readDrivers() {
        String drivers = PropertiesLoader.getProperties("PKCS11").getProperty("driver_lib");
        ArrayList<String> driversArr = new ArrayList<String>();
        if (drivers != null && !drivers.isEmpty()) {
            String[] vec = drivers.split("\\|");
            driversArr.addAll(Arrays.asList(vec));
        }
        return driversArr;
    }

    public static boolean useMscsp() {
        String shouldUseMscsp = PropertiesLoader.getProperties("PKCS11").getProperty("use_mscsp");
        return "true".equals(shouldUseMscsp);
    }

    public static void setUseMscsp(boolean v) {
        PropertiesLoader.setProperty("PKCS11", "use_mscsp", String.valueOf(v));
    }

    public static void setupHttpProxy() {
        String useProxy = PropertiesLoader.getProperties("PKCS11").getProperty("http_proxy_use", "");
        String proxyHost = PropertiesLoader.getProperties("PKCS11").getProperty("http_proxy_url", "");
        String proxyPort = PropertiesLoader.getProperties("PKCS11").getProperty("http_proxy_port", "");
        if (!"true".equals(useProxy)) {
            return;
        }
        System.setProperty("http.proxyHost", proxyHost);
        System.setProperty("http.proxyPort", proxyPort);
    }

    private static InputStream getPropertiesStream(String propsCategory) {
        File propsFile;
        FileInputStream stream = null;
        if (propertiesFolder != null && (propsFile = new File(propertiesFolder, propsCategory + ".properties")).exists() && propsFile.isFile() && propsFile.canRead()) {
            try {
                stream = new FileInputStream(propsFile);
            }
            catch (FileNotFoundException ex) {
                logger.error("", (Throwable)ex);
            }
        }
        return stream;
    }

    private static OutputStream getPropertiesOutputStream(String propsCategory) {
        File propsFile;
        FileOutputStream stream = null;
        if (propertiesFolder != null && (propsFile = new File(propertiesFolder, propsCategory + ".properties")).exists() && propsFile.isFile() && propsFile.canWrite()) {
            try {
                stream = new FileOutputStream(propsFile);
            }
            catch (FileNotFoundException ex) {
                logger.error("", (Throwable)ex);
            }
        }
        return stream;
    }
}

