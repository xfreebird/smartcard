/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.os.OS
 *  org.slf4j.LoggerFactory
 */
package dorkbox.util;

import dorkbox.os.OS;
import dorkbox.util.FileUtil;
import dorkbox.util.LocationResolver;
import java.awt.AlphaComposite;
import java.awt.Color;
import java.awt.Component;
import java.awt.Dimension;
import java.awt.Graphics2D;
import java.awt.Image;
import java.awt.MediaTracker;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.awt.image.RenderedImage;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.util.Iterator;
import java.util.concurrent.atomic.AtomicInteger;
import javax.imageio.ImageIO;
import javax.imageio.ImageReader;
import javax.imageio.stream.ImageInputStream;
import javax.swing.Icon;
import javax.swing.ImageIcon;
import org.slf4j.LoggerFactory;

public class ImageUtil {
    private static final Object mediaTrackerLock = new Object();
    private static final AtomicInteger imageTrackerIndex = new AtomicInteger(0);
    private static MediaTracker tracker = null;

    public static BufferedImage clampMaxImageSize(BufferedImage image, int size) {
        int type;
        double scaleRatio;
        int width = image.getWidth(null);
        int height = image.getHeight(null);
        if (width <= size && height <= size) {
            return image;
        }
        if (width > size) {
            scaleRatio = (double)size / (double)width;
            width = size;
            height = (int)((double)height * scaleRatio);
        }
        if (height > size) {
            scaleRatio = (double)size / (double)height;
            height = size;
            width = (int)((double)width * scaleRatio);
        }
        if ((type = image.getType()) == 0) {
            type = 2;
        }
        BufferedImage resizedImage = new BufferedImage(width, height, type);
        Graphics2D g = resizedImage.createGraphics();
        g.addRenderingHints(new RenderingHints(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY));
        g.setComposite(AlphaComposite.getInstance(3));
        g.drawImage(image, 0, 0, width, height, null);
        g.dispose();
        return resizedImage;
    }

    public static BufferedImage resizeImage(BufferedImage originalImage, int width, int height) {
        int originalHeight = originalImage.getHeight();
        int originalWidth = originalImage.getWidth();
        double ratio = (double)originalWidth / (double)originalHeight;
        if (width == -1 && height == -1) {
            width = originalWidth;
            height = originalHeight;
        } else if (width == -1) {
            width = (int)((double)height * ratio);
        } else if (height == -1) {
            height = (int)((double)width / ratio);
        }
        int type = originalImage.getType();
        if (type == 0) {
            type = 2;
        }
        BufferedImage resizedImage = new BufferedImage(width, height, type);
        Graphics2D g = resizedImage.createGraphics();
        g.addRenderingHints(new RenderingHints(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY));
        g.setComposite(AlphaComposite.getInstance(3));
        g.drawImage(originalImage, 0, 0, width, height, null);
        g.dispose();
        return resizedImage;
    }

    public static String resizeFileOrResource(int size, String fileName) throws IOException {
        Image image;
        FileInputStream fileInputStream = new FileInputStream(fileName);
        Dimension imageSize = ImageUtil.getImageSize(fileInputStream);
        if (size == (int)imageSize.getWidth() && size == (int)imageSize.getHeight()) {
            return fileName;
        }
        String extension = FileUtil.INSTANCE.getExtension(fileName);
        if (extension.isEmpty()) {
            extension = "png";
        }
        File newFile = new File(OS.INSTANCE.getTEMP_DIR(), "temp_resize." + extension).getAbsoluteFile();
        File iconTest = new File(fileName);
        if (iconTest.isFile() && iconTest.canRead()) {
            String absolutePath = iconTest.getAbsolutePath();
            image = new ImageIcon(absolutePath).getImage();
        } else {
            URL systemResource = LocationResolver.getResource(fileName);
            image = new ImageIcon(systemResource).getImage();
        }
        ImageUtil.waitForImageLoad(image);
        boolean mkdirs = newFile.getParentFile().mkdirs();
        if (!mkdirs) {
            throw new IOException("Unable to create directories for " + newFile.getParentFile());
        }
        boolean delete = newFile.delete();
        if (!delete) {
            throw new IOException("Temporary file already in use, cannot delete it " + newFile);
        }
        BufferedImage bufferedImage = ImageUtil.getSquareBufferedImage(image);
        ImageIO.write((RenderedImage)bufferedImage, extension, newFile);
        return newFile.getAbsolutePath();
    }

    public static File createImage(int size, File fileToUse, Color color) throws IOException {
        if (fileToUse.canRead() && fileToUse.isFile()) {
            return fileToUse.getAbsoluteFile();
        }
        fileToUse.getParentFile().mkdirs();
        BufferedImage image = ImageUtil.createImageAsBufferedImage(size, color);
        ImageIO.write((RenderedImage)image, "png", fileToUse);
        return fileToUse.getAbsoluteFile();
    }

    public static BufferedImage createImageAsBufferedImage(int size, Color color) {
        return ImageUtil.createImageAsBufferedImage(size, size, color);
    }

    public static BufferedImage createImageAsBufferedImage(int width, int height, Color color) {
        BufferedImage image = new BufferedImage(width, height, 2);
        Graphics2D g2d = image.createGraphics();
        if (color == null) {
            g2d.setColor(new Color(0, 0, 0, 0));
        } else {
            g2d.setColor(color);
        }
        g2d.fillRect(0, 0, width, height);
        g2d.dispose();
        return image;
    }

    public static BufferedImage getSquareBufferedImage(Image image) {
        int width = image.getWidth(null);
        int height = image.getHeight(null);
        int paddingX = 0;
        int paddingY = 0;
        int size = width;
        if (width < height) {
            size = height;
            paddingX = (height - width) / 2;
        } else {
            paddingY = (width - height) / 2;
        }
        BufferedImage bimage = new BufferedImage(size, size, 2);
        Graphics2D g = bimage.createGraphics();
        g.addRenderingHints(new RenderingHints(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY));
        g.setComposite(AlphaComposite.getInstance(3));
        g.drawImage(image, paddingX, paddingY, null);
        g.dispose();
        return bimage;
    }

    public static BufferedImage getBufferedImage(Image image) {
        if (image instanceof BufferedImage) {
            return (BufferedImage)image;
        }
        BufferedImage bimage = new BufferedImage(image.getWidth(null), image.getHeight(null), 2);
        Graphics2D g = bimage.createGraphics();
        g.addRenderingHints(new RenderingHints(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY));
        g.setComposite(AlphaComposite.getInstance(3));
        g.drawImage(image, 0, 0, null);
        g.dispose();
        return bimage;
    }

    public static BufferedImage getBufferedImage(Icon icon) {
        if (icon instanceof BufferedImage) {
            return (BufferedImage)((Object)icon);
        }
        BufferedImage bimage = new BufferedImage(icon.getIconWidth(), icon.getIconHeight(), 2);
        Graphics2D g = bimage.createGraphics();
        g.addRenderingHints(new RenderingHints(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY));
        g.setComposite(AlphaComposite.getInstance(3));
        icon.paintIcon(null, g, 0, 0);
        g.dispose();
        return bimage;
    }

    public static byte[] toBytes(BufferedImage image) throws IOException {
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        ImageIO.write((RenderedImage)image, "PNG", byteArrayOutputStream);
        return byteArrayOutputStream.toByteArray();
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public static Dimension getImageSize(InputStream fileStream) throws IOException {
        ImageInputStream in = null;
        ImageReader reader = null;
        try {
            in = ImageIO.createImageInputStream(fileStream);
            Iterator<ImageReader> readers = ImageIO.getImageReaders(in);
            if (readers.hasNext()) {
                reader = readers.next();
                reader.setInput(in);
                Dimension dimension = new Dimension(reader.getWidth(0), reader.getHeight(0));
                return dimension;
            }
        }
        finally {
            if (in != null) {
                try {
                    in.close();
                }
                catch (IOException iOException) {}
            }
            if (reader != null) {
                reader.dispose();
            }
        }
        throw new IOException("Unable to read file inputStream for image size data.");
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public static void waitForImageLoad(Image image) {
        int imageId = imageTrackerIndex.getAndIncrement();
        Object object = mediaTrackerLock;
        synchronized (object) {
            if (tracker == null) {
                tracker = new MediaTracker(new Component(){});
            }
            tracker.addImage(image, imageId);
        }
        try {
            tracker.waitForID(imageId);
            if (tracker.isErrorID(imageId)) {
                LoggerFactory.getLogger(ImageUtil.class).error("Error loading image!");
            }
        }
        catch (InterruptedException interruptedException) {
            Object object2 = mediaTrackerLock;
            synchronized (object2) {
                tracker.removeImage(image);
            }
        }
        finally {
            object = mediaTrackerLock;
            synchronized (object) {
                tracker.removeImage(image);
            }
        }
    }
}

