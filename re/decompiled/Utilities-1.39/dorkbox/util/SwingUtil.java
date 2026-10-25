/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.util;

import dorkbox.util.ScreenUtil;
import java.awt.Component;
import java.awt.Dimension;
import java.awt.EventQueue;
import java.awt.Frame;
import java.awt.HeadlessException;
import java.awt.Image;
import java.awt.Point;
import java.awt.Toolkit;
import java.awt.Window;
import java.awt.event.HierarchyEvent;
import java.awt.event.HierarchyListener;
import java.awt.event.WindowListener;
import java.awt.image.BufferedImage;
import java.lang.reflect.InvocationTargetException;
import java.util.Locale;
import javax.swing.AbstractButton;
import javax.swing.Icon;
import javax.swing.ImageIcon;
import javax.swing.JDialog;
import javax.swing.JOptionPane;
import javax.swing.SwingUtilities;
import javax.swing.UIManager;

public class SwingUtil {
    public static final Image BLANK_ICON;

    public static void setLookAndFeel(Class<?> lookAndFeel) {
        if (lookAndFeel == null) {
            SwingUtil.setLookAndFeelByName(null);
        } else {
            SwingUtil.setLookAndFeelByName(lookAndFeel.getName());
        }
    }

    public static void setLookAndFeelByName(String lookAndFeel) {
        String current;
        if (lookAndFeel == null) {
            try {
                UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
            }
            catch (Exception e) {
                e.printStackTrace();
            }
            return;
        }
        String specified = lookAndFeel.toLowerCase(Locale.US).trim();
        if (!specified.equals(current = UIManager.getLookAndFeel().getName().toLowerCase(Locale.US))) {
            try {
                for (UIManager.LookAndFeelInfo info : UIManager.getInstalledLookAndFeels()) {
                    String name = info.getName().toLowerCase(Locale.US);
                    String className = info.getClassName().toLowerCase(Locale.US);
                    if (!specified.equals(name) && !specified.equals(className)) continue;
                    UIManager.setLookAndFeel(info.getClassName());
                    return;
                }
            }
            catch (Exception e) {
                e.printStackTrace();
            }
        }
        new Exception("Could not load " + lookAndFeel + ", it was not available.").printStackTrace();
    }

    public static boolean isDefaultLookAndFeel() {
        return UIManager.getLookAndFeel().getClass().getName().equals(UIManager.getSystemLookAndFeelClassName());
    }

    public static void addWindowListener(final Component source, final WindowListener listener) {
        if (source instanceof Window) {
            ((Window)source).addWindowListener(listener);
        } else {
            source.addHierarchyListener(new HierarchyListener(){

                @Override
                public void hierarchyChanged(HierarchyEvent e) {
                    if ((e.getChangeFlags() & 4L) == 4L) {
                        SwingUtilities.getWindowAncestor(source).addWindowListener(listener);
                    }
                }
            });
        }
    }

    public static int getLargestIconHeightForButton(AbstractButton button) {
        Icon icon = button.getIcon();
        String text = button.getText();
        button.setText("`Tj|\u2503");
        int minHeight = 0;
        int iconSize = 0;
        for (int i = 1; i < 128; ++i) {
            ImageIcon imageIcon = new ImageIcon(new BufferedImage(1, i, 12));
            button.setIcon(imageIcon);
            button.invalidate();
            int height = (int)button.getPreferredSize().getHeight();
            if (minHeight == 0) {
                minHeight = height;
            } else if (minHeight != height) break;
            iconSize = imageIcon.getIconHeight();
        }
        button.setIcon(icon);
        button.setText(text);
        return iconSize;
    }

    public static void centerInWindow(Window window, Component component) {
        Dimension size = window.getSize();
        Point loc = window.getLocationOnScreen();
        Dimension cmpSize = component.getSize();
        loc.x += (size.width - cmpSize.width) / 2;
        loc.y += (size.height - cmpSize.height) / 2;
        component.setBounds(loc.x, loc.y, cmpSize.width, cmpSize.height);
    }

    public static void invokeLater(Runnable runnable) {
        if (EventQueue.isDispatchThread()) {
            runnable.run();
        } else {
            SwingUtilities.invokeLater(runnable);
        }
    }

    public static void invokeAndWait(Runnable runnable) throws InvocationTargetException, InterruptedException {
        if (EventQueue.isDispatchThread()) {
            runnable.run();
        } else {
            EventQueue.invokeAndWait(runnable);
        }
    }

    public static void invokeAndWaitQuietly(Runnable runnable) {
        if (EventQueue.isDispatchThread()) {
            runnable.run();
        } else {
            try {
                EventQueue.invokeAndWait(runnable);
            }
            catch (Exception exception) {
                // empty catch block
            }
        }
    }

    public static int getVirtualKey(char key) {
        switch (key) {
            case '\b': {
                return 8;
            }
            case '\t': {
                return 9;
            }
            case '\n': {
                return 10;
            }
            case '\u001b': {
                return 27;
            }
            case '\u20ac': {
                return 516;
            }
            case ' ': {
                return 32;
            }
            case '!': {
                return 517;
            }
            case '\"': {
                return 152;
            }
            case '#': {
                return 520;
            }
            case '$': {
                return 515;
            }
            case '&': {
                return 150;
            }
            case '\'': {
                return 222;
            }
            case '(': {
                return 519;
            }
            case ')': {
                return 522;
            }
            case '*': {
                return 151;
            }
            case '+': {
                return 521;
            }
            case ',': {
                return 44;
            }
            case '-': {
                return 45;
            }
            case '.': {
                return 46;
            }
            case '/': {
                return 47;
            }
            case '0': {
                return 48;
            }
            case '1': {
                return 49;
            }
            case '2': {
                return 50;
            }
            case '3': {
                return 51;
            }
            case '4': {
                return 52;
            }
            case '5': {
                return 53;
            }
            case '6': {
                return 54;
            }
            case '7': {
                return 55;
            }
            case '8': {
                return 56;
            }
            case '9': {
                return 57;
            }
            case ':': {
                return 513;
            }
            case ';': {
                return 59;
            }
            case '<': {
                return 153;
            }
            case '=': {
                return 61;
            }
            case '>': {
                return 160;
            }
            case '@': {
                return 512;
            }
            case 'A': {
                return 65;
            }
            case 'B': {
                return 66;
            }
            case 'C': {
                return 67;
            }
            case 'D': {
                return 68;
            }
            case 'E': {
                return 69;
            }
            case 'F': {
                return 70;
            }
            case 'G': {
                return 71;
            }
            case 'H': {
                return 72;
            }
            case 'I': {
                return 73;
            }
            case 'J': {
                return 74;
            }
            case 'K': {
                return 75;
            }
            case 'L': {
                return 76;
            }
            case 'M': {
                return 77;
            }
            case 'N': {
                return 78;
            }
            case 'O': {
                return 79;
            }
            case 'P': {
                return 80;
            }
            case 'Q': {
                return 81;
            }
            case 'R': {
                return 82;
            }
            case 'S': {
                return 83;
            }
            case 'T': {
                return 84;
            }
            case 'U': {
                return 85;
            }
            case 'V': {
                return 86;
            }
            case 'W': {
                return 87;
            }
            case 'X': {
                return 88;
            }
            case 'Y': {
                return 89;
            }
            case 'Z': {
                return 90;
            }
            case '[': {
                return 91;
            }
            case '\\': {
                return 92;
            }
            case ']': {
                return 93;
            }
            case '^': {
                return 514;
            }
            case '_': {
                return 523;
            }
            case '`': {
                return 192;
            }
            case 'a': {
                return 65;
            }
            case 'b': {
                return 66;
            }
            case 'c': {
                return 67;
            }
            case 'd': {
                return 68;
            }
            case 'e': {
                return 69;
            }
            case 'f': {
                return 70;
            }
            case 'g': {
                return 71;
            }
            case 'h': {
                return 72;
            }
            case 'i': {
                return 73;
            }
            case 'j': {
                return 74;
            }
            case 'k': {
                return 75;
            }
            case 'l': {
                return 76;
            }
            case 'm': {
                return 77;
            }
            case 'n': {
                return 78;
            }
            case 'o': {
                return 79;
            }
            case 'p': {
                return 80;
            }
            case 'q': {
                return 81;
            }
            case 'r': {
                return 82;
            }
            case 's': {
                return 83;
            }
            case 't': {
                return 84;
            }
            case 'u': {
                return 85;
            }
            case 'v': {
                return 86;
            }
            case 'w': {
                return 87;
            }
            case 'x': {
                return 88;
            }
            case 'y': {
                return 89;
            }
            case 'z': {
                return 90;
            }
            case '{': {
                return 161;
            }
            case '}': {
                return 162;
            }
            case '\u007f': {
                return 127;
            }
            case '\u00a1': {
                return 518;
            }
        }
        return 0;
    }

    public static char getFromVirtualKey(int key) {
        switch (key) {
            case 8: {
                return '\b';
            }
            case 9: {
                return '\t';
            }
            case 10: {
                return '\n';
            }
            case 27: {
                return '\u001b';
            }
            case 516: {
                return '\u20ac';
            }
            case 32: {
                return ' ';
            }
            case 517: {
                return '!';
            }
            case 152: {
                return '\"';
            }
            case 520: {
                return '#';
            }
            case 515: {
                return '$';
            }
            case 150: {
                return '&';
            }
            case 222: {
                return '\'';
            }
            case 519: {
                return '(';
            }
            case 522: {
                return ')';
            }
            case 151: {
                return '*';
            }
            case 521: {
                return '+';
            }
            case 44: {
                return ',';
            }
            case 45: {
                return '-';
            }
            case 46: {
                return '.';
            }
            case 47: {
                return '/';
            }
            case 48: {
                return '0';
            }
            case 49: {
                return '1';
            }
            case 50: {
                return '2';
            }
            case 51: {
                return '3';
            }
            case 52: {
                return '4';
            }
            case 53: {
                return '5';
            }
            case 54: {
                return '6';
            }
            case 55: {
                return '7';
            }
            case 56: {
                return '8';
            }
            case 57: {
                return '9';
            }
            case 513: {
                return ':';
            }
            case 59: {
                return ';';
            }
            case 153: {
                return '<';
            }
            case 61: {
                return '=';
            }
            case 160: {
                return '>';
            }
            case 512: {
                return '@';
            }
            case 65: {
                return 'A';
            }
            case 66: {
                return 'B';
            }
            case 67: {
                return 'C';
            }
            case 68: {
                return 'D';
            }
            case 69: {
                return 'E';
            }
            case 70: {
                return 'F';
            }
            case 71: {
                return 'G';
            }
            case 72: {
                return 'H';
            }
            case 73: {
                return 'I';
            }
            case 74: {
                return 'J';
            }
            case 75: {
                return 'K';
            }
            case 76: {
                return 'L';
            }
            case 77: {
                return 'M';
            }
            case 78: {
                return 'N';
            }
            case 79: {
                return 'O';
            }
            case 80: {
                return 'P';
            }
            case 81: {
                return 'Q';
            }
            case 82: {
                return 'R';
            }
            case 83: {
                return 'S';
            }
            case 84: {
                return 'T';
            }
            case 85: {
                return 'U';
            }
            case 86: {
                return 'V';
            }
            case 87: {
                return 'W';
            }
            case 88: {
                return 'X';
            }
            case 89: {
                return 'Y';
            }
            case 90: {
                return 'Z';
            }
            case 91: {
                return '[';
            }
            case 92: {
                return '\\';
            }
            case 93: {
                return ']';
            }
            case 514: {
                return '^';
            }
            case 523: {
                return '_';
            }
            case 192: {
                return '`';
            }
            case 161: {
                return '{';
            }
            case 162: {
                return '}';
            }
            case 127: {
                return '\u007f';
            }
            case 518: {
                return '\u00a1';
            }
        }
        return '\u0000';
    }

    public static int showMessageDialog(String title, String message, int messageType) throws HeadlessException {
        boolean supportsWindowDecorations;
        int style;
        JOptionPane pane = new JOptionPane(message, messageType, -1, null, null, null);
        pane.setInitialValue(null);
        Frame rootFrame = JOptionPane.getRootFrame();
        pane.setComponentOrientation(rootFrame.getComponentOrientation());
        switch (messageType) {
            case 0: {
                style = 4;
                break;
            }
            case 3: {
                style = 7;
                break;
            }
            case 2: {
                style = 8;
                break;
            }
            case 1: {
                style = 3;
                break;
            }
            default: {
                style = 2;
            }
        }
        JDialog dialog = pane.createDialog(title);
        dialog.setModal(true);
        if (JDialog.isDefaultLookAndFeelDecorated() && (supportsWindowDecorations = UIManager.getLookAndFeel().getSupportsWindowDecorations())) {
            dialog.setUndecorated(true);
            dialog.getRootPane().setWindowDecorationStyle(style);
        }
        pane.selectInitialValue();
        ScreenUtil.showOnSameScreenAsMouse_Center(dialog);
        dialog.setVisible(true);
        dialog.dispose();
        Object selectedValue = pane.getValue();
        if (selectedValue instanceof Integer) {
            return (Integer)selectedValue;
        }
        return -1;
    }

    static {
        Toolkit.getDefaultToolkit();
        BLANK_ICON = new BufferedImage(1, 1, 3);
    }
}

