/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.os.OS
 */
package dorkbox.util;

import dorkbox.os.OS;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.MalformedURLException;
import java.net.URISyntaxException;
import java.net.URL;
import java.net.URLClassLoader;
import java.net.URLDecoder;
import java.security.CodeSource;
import java.security.ProtectionDomain;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Enumeration;
import java.util.HashSet;
import java.util.List;
import java.util.Vector;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;
import java.util.regex.Pattern;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public class LocationResolver {
    private static final Pattern SLASH_PATTERN = Pattern.compile("\\\\");

    private static void log(String message) {
        System.err.println(LocationResolver.prefix() + message);
    }

    private static String normalizePath(String path) throws IOException {
        path = SLASH_PATTERN.matcher(path).replaceAll("/");
        return URLDecoder.decode(path, "UTF-8");
    }

    public static File get() {
        return LocationResolver.get(LocationResolver.class);
    }

    public static File get(Class<?> clazz) {
        ProtectionDomain pDomain = clazz.getProtectionDomain();
        CodeSource cSource = pDomain.getCodeSource();
        URL loc = cSource.getLocation();
        if (loc == null) {
            return null;
        }
        try {
            File file = new File(LocationResolver.normalizePath(loc.getFile())).getAbsoluteFile().getCanonicalFile();
            return file;
        }
        catch (UnsupportedEncodingException e) {
            throw new RuntimeException("Unable to decode file path!", e);
        }
        catch (IOException e) {
            throw new RuntimeException("Unable to get canonical file path!", e);
        }
    }

    public static URL getResource(String resourceName) {
        try {
            resourceName = LocationResolver.normalizePath(resourceName);
        }
        catch (IOException e) {
            e.printStackTrace();
        }
        URL resource = null;
        File file = new File(resourceName);
        if (file.canRead()) {
            try {
                resource = file.toURI().toURL();
            }
            catch (MalformedURLException e) {
                e.printStackTrace();
            }
        }
        if (resource == null) {
            resource = Thread.currentThread().getContextClassLoader().getResource(resourceName);
        }
        if (resource == null) {
            resource = ClassLoader.getSystemResource(resourceName);
        }
        if (resource == null) {
            try {
                LocationResolver.searchResource(resourceName);
            }
            catch (IOException e) {
                e.printStackTrace();
            }
        }
        return resource;
    }

    public static Enumeration<URL> getResources(String resourceName) {
        try {
            resourceName = LocationResolver.normalizePath(resourceName);
        }
        catch (IOException e) {
            e.printStackTrace();
        }
        Enumeration<URL> resources = null;
        try {
            File file = new File(resourceName);
            if (file.canRead()) {
                File[] files;
                ArrayDeque<URL> urlList = new ArrayDeque<URL>(4);
                urlList.add(file.toURI().toURL());
                if (file.isDirectory() && (files = file.listFiles()) != null) {
                    int n = files.length;
                    for (int i = 0; i < n; ++i) {
                        urlList.add(files[i].toURI().toURL());
                    }
                }
                resources = new Vector(urlList).elements();
            }
            if (resources == null) {
                resources = Thread.currentThread().getContextClassLoader().getResources(resourceName);
            }
            if (resources == null) {
                resources = ClassLoader.getSystemResources(resourceName);
            }
            if (resources == null) {
                LocationResolver.searchResource(resourceName);
            }
        }
        catch (IOException e) {
            e.printStackTrace();
        }
        return resources;
    }

    public static InputStream getResourceAsStream(String resourceName) {
        try {
            resourceName = LocationResolver.normalizePath(resourceName);
        }
        catch (IOException e) {
            e.printStackTrace();
        }
        InputStream resourceAsStream = null;
        if (new File(resourceName).canRead()) {
            try {
                resourceAsStream = new FileInputStream(resourceName);
            }
            catch (FileNotFoundException e) {
                e.printStackTrace();
            }
        }
        if (resourceAsStream == null) {
            resourceAsStream = Thread.currentThread().getContextClassLoader().getResourceAsStream(resourceName);
        }
        if (resourceAsStream == null) {
            resourceAsStream = ClassLoader.getSystemResourceAsStream(resourceName);
        }
        if (resourceAsStream == null) {
            try {
                LocationResolver.searchResource(resourceName);
            }
            catch (IOException e) {
                e.printStackTrace();
            }
        }
        return resourceAsStream;
    }

    public static void searchResource(String path) throws IOException {
        try {
            path = LocationResolver.normalizePath(path);
        }
        catch (IOException e) {
            e.printStackTrace();
        }
        ArrayList<Root> roots = new ArrayList<Root>();
        ClassLoader contextClassLoader = Thread.currentThread().getContextClassLoader();
        if (contextClassLoader instanceof URLClassLoader) {
            URL[] urLs;
            for (URL url : urLs = ((URLClassLoader)contextClassLoader).getURLs()) {
                roots.add(new Root(url));
            }
            System.err.println();
            LocationResolver.log("SEARCHING: \"" + path + "\"");
            for (int attempt = 1; attempt <= 6; ++attempt) {
                for (Root root : roots) {
                    if (!root.search(path, attempt)) continue;
                    return;
                }
            }
            LocationResolver.log("FAILED: failed to find anything like");
            LocationResolver.log("               \"" + path + "\"");
            LocationResolver.log("         in all classpath entries:");
            for (Root root : roots) {
                File entry = root.entry;
                if (entry == null) continue;
                LocationResolver.log("               \"" + entry.getAbsolutePath() + "\"");
            }
        } else {
            throw new IOException("Unable to search for '" + path + "' in the context classloader of type '" + contextClassLoader.getClass() + "'.  Please report this issue with as many specific details as possible (OS, Java version, application version");
        }
    }

    String[] getDirectoryContents(Class clazz, String path) throws URISyntaxException, IOException {
        URL dirURL = clazz.getClassLoader().getResource(path);
        if (dirURL != null && dirURL.getProtocol().equals("file")) {
            return new File(dirURL.toURI()).list();
        }
        if (dirURL == null) {
            String me = clazz.getName().replace(".", "/") + ".class";
            dirURL = clazz.getClassLoader().getResource(me);
        }
        if (dirURL.getProtocol().equals("jar")) {
            String jarPath = dirURL.getPath().substring(5, dirURL.getPath().indexOf("!"));
            JarFile jar = new JarFile(URLDecoder.decode(jarPath, "UTF-8"));
            Enumeration<JarEntry> entries = jar.entries();
            HashSet<String> result = new HashSet<String>();
            while (entries.hasMoreElements()) {
                String name = entries.nextElement().getName();
                if (!name.startsWith(path)) continue;
                String entry = name.substring(path.length());
                int checkSubdir = entry.indexOf("/");
                if (checkSubdir >= 0) {
                    entry = entry.substring(0, checkSubdir);
                }
                result.add(entry);
            }
            return result.toArray(new String[result.size()]);
        }
        throw new UnsupportedOperationException("Cannot list files for URL " + dirURL);
    }

    private static File visitRoot(URL url, List<String> resources) throws IOException {
        File root;
        if (!url.getProtocol().equals("file")) {
            throw new IllegalStateException();
        }
        String path = url.getPath();
        if (OS.INSTANCE.isWindows() && path.startsWith("/")) {
            path = path.substring(1);
        }
        if (!(root = new File(path)).exists()) {
            LocationResolver.log("failed to find classpath entry in filesystem: " + path);
            return null;
        }
        if (root.isDirectory()) {
            LocationResolver.visitDir(LocationResolver.normalizePath(root.getAbsolutePath()), root, resources);
        } else {
            String s = root.getName().toLowerCase();
            if (s.endsWith(".zip")) {
                LocationResolver.visitZip(root, resources);
            } else if (s.endsWith(".jar")) {
                LocationResolver.visitZip(root, resources);
            } else {
                LocationResolver.log("unknown classpath entry type: " + path);
                return null;
            }
        }
        return root;
    }

    private static void visitDir(String root, File dir, Collection<String> out) {
        File[] files = dir.listFiles();
        if (files != null) {
            for (File file : files) {
                if (file.isDirectory()) {
                    LocationResolver.visitDir(root, file, out);
                }
                out.add(file.getAbsolutePath().replace('\\', '/').substring(root.length() + 1));
            }
        }
    }

    private static void visitZip(File jar, Collection<String> out) throws IOException {
        ZipEntry entry;
        ZipInputStream zis = new ZipInputStream(new FileInputStream(jar));
        while ((entry = zis.getNextEntry()) != null) {
            out.add(entry.getName().replace('\\', '/'));
        }
        zis.close();
    }

    private static String prefix() {
        return "[" + LocationResolver.class.getSimpleName() + "] ";
    }

    private static class Root {
        final File entry;
        final List<String> resources = new ArrayList<String>();

        public Root(URL entry) throws IOException {
            this.entry = LocationResolver.visitRoot(entry, this.resources);
        }

        public boolean search(String path, int attempt) {
            try {
                path = LocationResolver.normalizePath(path);
            }
            catch (IOException e) {
                e.printStackTrace();
            }
            switch (attempt) {
                case 1: {
                    for (String resource : this.resources) {
                        if (!path.equals(resource)) continue;
                        LocationResolver.log("SUCCESS: found resource \"" + path + "\" in root: " + this.entry);
                        return true;
                    }
                    break;
                }
                case 2: {
                    for (String resource : this.resources) {
                        if (!path.toLowerCase().equals(resource.toLowerCase())) continue;
                        LocationResolver.log("FOUND: similarly named resource:");
                        LocationResolver.log("               \"" + resource + "\"");
                        LocationResolver.log("         in classpath entry:");
                        LocationResolver.log("               \"" + this.entry + "\"");
                        LocationResolver.log("         for access use:");
                        LocationResolver.log("               getResourceAsStream(\"/" + resource + "\");");
                        return true;
                    }
                    break;
                }
                case 3: {
                    for (String resource : this.resources) {
                        String r1 = path;
                        String r2 = resource;
                        if (r1.contains("/")) {
                            r1 = r1.substring(r1.lastIndexOf(47) + 1);
                        }
                        if (r2.contains("/")) {
                            r2 = r2.substring(r2.lastIndexOf(47) + 1);
                        }
                        if (!r1.equals(r2)) continue;
                        LocationResolver.log("FOUND: mislocated resource:");
                        LocationResolver.log("               \"" + resource + "\"");
                        LocationResolver.log("         in classpath entry:");
                        LocationResolver.log("               \"" + this.entry + "\"");
                        LocationResolver.log("         for access use:");
                        LocationResolver.log("               getResourceAsStream(\"/" + resource + "\");");
                        return true;
                    }
                    break;
                }
                case 4: {
                    for (String resource : this.resources) {
                        String r1 = path.toLowerCase();
                        String r2 = resource.toLowerCase();
                        if (r1.contains("/")) {
                            r1 = r1.substring(r1.lastIndexOf(47) + 1);
                        }
                        if (r2.contains("/")) {
                            r2 = r2.substring(r2.lastIndexOf(47) + 1);
                        }
                        if (!r1.equals(r2)) continue;
                        LocationResolver.log("FOUND: mislocated, similarly named resource:");
                        LocationResolver.log("               \"" + resource + "\"");
                        LocationResolver.log("         in classpath entry:");
                        LocationResolver.log("               \"" + this.entry + "\"");
                        LocationResolver.log("         for access use:");
                        LocationResolver.log("               getResourceAsStream(\"/" + resource + "\");");
                        return true;
                    }
                    break;
                }
                case 5: {
                    for (String resource : this.resources) {
                        String r1 = path;
                        String r2 = resource;
                        if (r1.contains("/")) {
                            r1 = r1.substring(r1.lastIndexOf(47) + 1);
                        }
                        if (r2.contains("/")) {
                            r2 = r2.substring(r2.lastIndexOf(47) + 1);
                        }
                        if (r1.contains(".")) {
                            r1 = r1.substring(0, r1.lastIndexOf(46));
                        }
                        if (r2.contains(".")) {
                            r2 = r2.substring(0, r2.lastIndexOf(46));
                        }
                        if (!r1.equals(r2)) continue;
                        LocationResolver.log("FOUND: resource with different extension:");
                        LocationResolver.log("               \"" + resource + "\"");
                        LocationResolver.log("         in classpath entry:");
                        LocationResolver.log("               \"" + this.entry + "\"");
                        LocationResolver.log("         for access use:");
                        LocationResolver.log("               getResourceAsStream(\"/" + resource + "\");");
                        return true;
                    }
                    break;
                }
                case 6: {
                    for (String resource : this.resources) {
                        String r1 = path.toLowerCase();
                        String r2 = resource.toLowerCase();
                        if (r1.contains("/")) {
                            r1 = r1.substring(r1.lastIndexOf(47) + 1);
                        }
                        if (r2.contains("/")) {
                            r2 = r2.substring(r2.lastIndexOf(47) + 1);
                        }
                        if (r1.contains(".")) {
                            r1 = r1.substring(0, r1.lastIndexOf(46));
                        }
                        if (r2.contains(".")) {
                            r2 = r2.substring(0, r2.lastIndexOf(46));
                        }
                        if (!r1.equals(r2)) continue;
                        LocationResolver.log("FOUND: similarly named resource with different extension:");
                        LocationResolver.log("               \"" + resource + "\"");
                        LocationResolver.log("         in classpath entry:");
                        LocationResolver.log("               \"" + this.entry + "\"");
                        LocationResolver.log("         for access use:");
                        LocationResolver.log("               getResourceAsStream(\"/" + resource + "\");");
                        return true;
                    }
                    break;
                }
                default: {
                    return false;
                }
            }
            return false;
        }
    }
}

