/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.util.properties;

import dorkbox.util.FileUtil;
import dorkbox.util.properties.SortedProperties;
import java.awt.Color;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Properties;

public class PropertiesProvider {
    private final Properties properties = new SortedProperties();
    private final File propertiesFile;
    private String comments = "Settings and configuration file. Strings must be escape formatted!";

    public PropertiesProvider(String propertiesFile) {
        this(new File(propertiesFile));
    }

    public PropertiesProvider(File propertiesFile) {
        if (propertiesFile == null) {
            throw new NullPointerException("propertiesFile");
        }
        File parentFile = (propertiesFile = FileUtil.INSTANCE.normalize(propertiesFile)).getParentFile();
        if (parentFile != null && !parentFile.exists() && !parentFile.mkdirs()) {
            throw new RuntimeException("Unable to create directories for: " + propertiesFile);
        }
        this.propertiesFile = propertiesFile;
        this._load();
    }

    public void setComments(String comments) {
        this.comments = comments;
    }

    private void _load() {
        if (!this.propertiesFile.canRead() || !this.propertiesFile.exists()) {
            this._save();
        }
        try {
            FileInputStream fis = new FileInputStream(this.propertiesFile);
            this.properties.load(fis);
            fis.close();
        }
        catch (FileNotFoundException e) {
            e.printStackTrace();
        }
        catch (IOException e) {
            System.err.println("Properties cannot load!");
            e.printStackTrace();
        }
    }

    private void _save() {
        try {
            FileOutputStream fos = new FileOutputStream(this.propertiesFile);
            this.properties.store(fos, this.comments);
            fos.flush();
            fos.close();
        }
        catch (FileNotFoundException e) {
            e.printStackTrace();
            System.err.println("Properties cannot save!");
        }
        catch (IOException e) {
            System.err.println("Properties cannot save!");
            e.printStackTrace();
        }
    }

    public final synchronized void remove(String key) {
        this.properties.remove(key);
        this._save();
    }

    public final synchronized void save(String key, Object value) {
        if (key == null || value == null) {
            return;
        }
        if (value instanceof Color) {
            value = ((Color)value).getRGB();
        }
        this.properties.setProperty(key, value.toString());
        this._save();
    }

    public synchronized <T> T get(String key, Class<T> clazz) {
        if (key == null || clazz == null) {
            return null;
        }
        String property = this.properties.getProperty(key);
        if (property == null) {
            return null;
        }
        try {
            if (clazz.equals(Integer.class)) {
                return (T)Integer.valueOf(Integer.parseInt(property));
            }
            if (clazz.equals(Long.class)) {
                return (T)Long.valueOf(Long.parseLong(property));
            }
            if (clazz.equals(Color.class)) {
                return (T)new Color(Integer.parseInt(property), true);
            }
            return (T)property;
        }
        catch (Exception e) {
            throw new RuntimeException("Properties Loader for property: " + key + System.getProperty("line.separator") + e.getMessage());
        }
    }

    public String toString() {
        return "PropertiesProvider [" + this.propertiesFile + "]";
    }
}

