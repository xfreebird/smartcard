/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.msccm.properties;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import md.gov.stisc.Single;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class PropertiesLoader {
    private static final Logger logger = LoggerFactory.getLogger(PropertiesLoader.class);
    private static PropertiesLoader instance;
    private final Map<String, Properties> propertiesMap = new HashMap<String, Properties>();
    private File propertiesFolder = null;

    public PropertiesLoader() {
        File folder = new File(Single.appDataDirectory);
        if (folder.exists() && folder.canRead() && folder.isDirectory()) {
            this.propertiesFolder = folder;
        }
    }

    private static Properties reloadProps(String propsCategory) {
        Properties props = new Properties();
        InputStream propsStream = instance.getPropertiesStream(propsCategory);
        if (propsStream != null) {
            try {
                props.load(propsStream);
            }
            catch (IOException ex) {
                logger.error("", (Throwable)ex);
            }
            try {
                propsStream.close();
            }
            catch (IOException iOException) {
                logger.error("", (Throwable)iOException);
            }
        }
        return props;
    }

    public static Properties getProperties(String propsCategory) {
        if (instance == null) {
            instance = new PropertiesLoader();
        }
        if (instance.getPropertiesMap().containsKey(propsCategory)) {
            return instance.getPropertiesMap().get(propsCategory);
        }
        Properties props = PropertiesLoader.reloadProps(propsCategory);
        instance.getPropertiesMap().put(propsCategory, props);
        return props;
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    private static void setProperty(String propsCategory, String propsName, String propsValue) {
        if (instance == null) {
            instance = new PropertiesLoader();
        }
        Properties props = instance.getPropertiesMap().get(propsCategory);
        OutputStream propsStream = null;
        try {
            InputStream propsInStream = instance.getPropertiesStream(propsCategory);
            props.load(propsInStream);
            propsInStream.close();
            propsStream = instance.getPropertiesOutputStream(propsCategory);
            props.setProperty(propsName, propsValue);
            props.store(propsStream, null);
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
        }
        finally {
            try {
                propsStream.close();
            }
            catch (IOException ex) {
                logger.error("", (Throwable)ex);
            }
        }
    }

    public InputStream getPropertiesStream(String propsCategory) {
        File propsFile;
        InputStream stream = null;
        if (this.propertiesFolder != null && (propsFile = new File(this.propertiesFolder, propsCategory + ".properties")).exists() && propsFile.canRead() && propsFile.isFile()) {
            try {
                stream = new FileInputStream(propsFile);
            }
            catch (FileNotFoundException ex) {
                logger.error("", (Throwable)ex);
            }
        }
        if (stream == null) {
            stream = ClassLoader.getSystemResourceAsStream("md.cts.moldsign.default_properties" + propsCategory + ".properties");
        }
        return stream;
    }

    public OutputStream getPropertiesOutputStream(String propsCategory) throws IOException {
        File propsFile;
        FileOutputStream stream = null;
        if (this.propertiesFolder != null && (propsFile = new File(this.propertiesFolder, propsCategory + ".properties")).exists() && propsFile.canRead() && propsFile.isFile()) {
            try {
                stream = new FileOutputStream(propsFile);
            }
            catch (FileNotFoundException ex) {
                logger.error("", (Throwable)ex);
            }
        }
        if (stream == null) {
            throw new IOException();
        }
        return stream;
    }

    public Map<String, Properties> getPropertiesMap() {
        return this.propertiesMap;
    }
}

