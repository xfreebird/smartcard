/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.os.OS
 */
package dorkbox.util;

import dorkbox.os.OS;
import dorkbox.util.FileUtil;
import dorkbox.util.LocationResolver;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.math.BigInteger;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Locale;

public class CacheUtil {
    private static final ThreadLocal<MessageDigest> digestLocal = ThreadLocal.withInitial(() -> {
        try {
            return MessageDigest.getInstance("SHA1");
        }
        catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("Unable to initialize hash algorithm. SHA1 digest doesn't exist?!? (This should not happen");
        }
    });
    private final String tempDir;

    public static void clear(String tempDir) {
        new CacheUtil(tempDir).clear();
    }

    public CacheUtil() {
        this("cache");
    }

    public CacheUtil(String tempDir) {
        this.tempDir = tempDir;
    }

    public void clear() {
        FileUtil.delete(new File(OS.INSTANCE.getTEMP_DIR(), this.tempDir), new String[0]);
    }

    public File check(File file) {
        if (file == null) {
            throw new NullPointerException("file");
        }
        return this.check(file.getAbsolutePath());
    }

    public File check(String fileName) {
        if (fileName == null) {
            throw new NullPointerException("fileName");
        }
        File newFile = this.makeCacheFile(fileName);
        if (newFile.canRead() && newFile.isFile()) {
            return newFile;
        }
        return null;
    }

    public File check(URL fileResource) {
        if (fileResource == null) {
            throw new NullPointerException("fileResource");
        }
        return this.check(fileResource.getPath());
    }

    public File check(InputStream fileStream) throws IOException {
        if (fileStream == null) {
            throw new NullPointerException("fileStream");
        }
        return this.check(null, fileStream);
    }

    public File check(String cacheName, InputStream fileStream) throws IOException {
        File newFile;
        if (fileStream == null) {
            throw new NullPointerException("fileStream");
        }
        if (cacheName == null) {
            cacheName = CacheUtil.createNameAsHash(fileStream);
        }
        if ((newFile = this.makeCacheFile(cacheName)).canRead() && newFile.isFile()) {
            return newFile;
        }
        return null;
    }

    public File save(File file) throws IOException {
        return this.save(file.getAbsolutePath(), file);
    }

    public File save(String cacheName, File file) throws IOException {
        if (cacheName == null) {
            cacheName = file.getAbsolutePath();
        }
        return this.save(cacheName, file.getAbsolutePath());
    }

    public File save(String fileName) throws IOException {
        return this.save(null, fileName);
    }

    public File save(String cacheName, String fileName) throws IOException {
        File newFile;
        if (cacheName == null) {
            cacheName = fileName;
        }
        if ((newFile = this.makeCacheFile(cacheName)).canRead() && newFile.isFile()) {
            return newFile;
        }
        File iconTest = new File(fileName);
        if (iconTest.isFile()) {
            if (!iconTest.canRead()) {
                throw new IOException("File exists but unable to read source file " + fileName);
            }
            FileUtil.copyFile(iconTest, newFile);
            return newFile;
        }
        URL systemResource = LocationResolver.getResource(fileName);
        if (systemResource == null) {
            throw new IOException("Unable to load URL resource " + fileName);
        }
        InputStream inStream = systemResource.openStream();
        return this.makeFileViaStream(cacheName, inStream);
    }

    public File save(URL fileResource) throws IOException {
        return this.save(null, fileResource);
    }

    public File save(String cacheName, URL fileResource) throws IOException {
        File newFile;
        if (cacheName == null) {
            cacheName = fileResource.getPath();
        }
        if ((newFile = this.makeCacheFile(cacheName)).canRead() && newFile.isFile()) {
            return newFile;
        }
        InputStream inStream = fileResource.openStream();
        return this.makeFileViaStream(cacheName, inStream);
    }

    public File save(InputStream fileStream) throws IOException {
        if (fileStream == null) {
            throw new NullPointerException("fileStream");
        }
        return this.save(null, fileStream);
    }

    public File save(String cacheName, InputStream fileStream) throws IOException {
        File newFile;
        if (cacheName == null) {
            cacheName = CacheUtil.createNameAsHash(fileStream);
        }
        if ((newFile = this.makeCacheFile(cacheName)).canRead() && newFile.isFile()) {
            return newFile;
        }
        return this.makeFileViaStream(cacheName, fileStream);
    }

    private File makeFileViaStream(String cacheName, InputStream resourceStream) throws IOException {
        if (resourceStream == null) {
            throw new NullPointerException("resourceStream");
        }
        if (cacheName == null) {
            throw new NullPointerException("cacheName");
        }
        File newFile = this.makeCacheFile(cacheName);
        if (newFile.canRead() && newFile.isFile()) {
            return newFile.getAbsoluteFile();
        }
        FileOutputStream outStream = null;
        try {
            int read2;
            byte[] buffer = new byte[2048];
            outStream = new FileOutputStream(newFile);
            while ((read2 = resourceStream.read(buffer)) > 0) {
                ((OutputStream)outStream).write(buffer, 0, read2);
            }
        }
        catch (IOException e) {
            String message = "Unable to copy '" + cacheName + "' to temporary location: '" + newFile.getAbsolutePath() + "'";
            throw new IOException(message, e);
        }
        finally {
            try {
                resourceStream.close();
            }
            catch (Exception exception) {}
            try {
                if (outStream != null) {
                    ((OutputStream)outStream).close();
                }
            }
            catch (Exception exception) {}
        }
        return newFile.getAbsoluteFile();
    }

    public File create(String cacheName) {
        return this.makeCacheFile(cacheName);
    }

    private File makeCacheFile(String cacheName) {
        if (cacheName == null) {
            throw new NullPointerException("cacheName");
        }
        File saveDir = new File(OS.INSTANCE.getTEMP_DIR(), this.tempDir);
        String hash = CacheUtil.hashName(cacheName);
        String extension = FileUtil.INSTANCE.getExtension(cacheName);
        if (extension.isEmpty()) {
            extension = "cache";
        }
        File newFile = new File(saveDir, hash + '.' + extension).getAbsoluteFile();
        newFile.getParentFile().mkdirs();
        return newFile;
    }

    private static String hashName(String name) {
        byte[] bytes = name.getBytes(StandardCharsets.UTF_8);
        MessageDigest digest = digestLocal.get();
        digest.reset();
        digest.update(bytes);
        return new BigInteger(1, digest.digest()).toString(32).toUpperCase(Locale.US);
    }

    public static String createNameAsHash(InputStream resourceStream) throws IOException {
        MessageDigest digest = digestLocal.get();
        digest.reset();
        try {
            int read2;
            ByteArrayOutputStream outStream = new ByteArrayOutputStream(4096);
            byte[] buffer = new byte[2048];
            while ((read2 = resourceStream.read(buffer)) > 0) {
                digest.update(buffer, 0, read2);
                outStream.write(buffer, 0, read2);
            }
            String string = new BigInteger(1, digest.digest()).toString(32).toUpperCase(Locale.US) + ".cache";
            return string;
        }
        catch (IOException e) {
            String message = "Unable to copy InputStream to memory.";
            throw new IOException(message, e);
        }
        finally {
            try {
                resourceStream.close();
            }
            catch (Exception exception) {}
        }
    }
}

