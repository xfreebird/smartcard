/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.os.OS
 */
package dorkbox.exit;

import dorkbox.exit.ExitBase;
import dorkbox.exit.ExitError;
import dorkbox.exit.ExitRestart;
import dorkbox.os.OS;
import java.io.BufferedWriter;
import java.io.ByteArrayOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.NotSerializableException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

public final class Exit {
    private static int UNDEFINED = -1;
    private static int NORMAL = 0;
    private static int FAILED_CONFIG = 1;
    private static int FAILED_INIT = 2;
    private static int FAILED_SECURITY = 3;
    private static int RESERVED = 100;
    private static List<Integer> RESERVED_LIST = new ArrayList<Integer>(2);
    private static int SAVED_IN_LOG_FILE = 101;
    private static int RESTART = 102;
    private static int UPGRADE_EXECUTABLE = 103;
    private static AtomicInteger exitValue;
    private static ExitBase exitError;

    private static native void setExitError(String var0);

    private static native boolean isNative0();

    public static final boolean isNative() {
        try {
            return Exit.isNative0();
        }
        catch (Throwable t) {
            return false;
        }
    }

    private Exit() {
    }

    public static int getExitValue() {
        Exit._setExitData(exitError);
        int exit = exitValue.get();
        if (exit > RESERVED) {
            if (RESERVED_LIST.contains(exitError)) {
                return exit;
            }
            Exit.setExitError("You cannot use any number greater than 99");
            return RESERVED;
        }
        return exit;
    }

    public static int getExitDuringException(ExitBase exitError) {
        if (Exit.exitError != null) {
            Exit._setExitData(Exit.exitError);
        } else {
            Exit._setExitData(exitError);
        }
        int exit = exitValue.get();
        if (exit > RESERVED) {
            if (RESERVED_LIST.contains(exitError)) {
                return exit;
            }
            Exit.setExitError("You cannot use any number greater than 99");
            return RESERVED;
        }
        return exit;
    }

    public static void writeToLogFile(String title, String message) {
        try (BufferedWriter output = new BufferedWriter(new FileWriter("error.log", true));){
            if (message != null) {
                if (title != null) {
                    output.write(title);
                    output.write(OS.INSTANCE.getLINE_SEPARATOR() + "   ");
                }
                output.write(new Date() + OS.INSTANCE.getLINE_SEPARATOR() + "     ");
                output.write(message);
                output.write(OS.INSTANCE.getLINE_SEPARATOR());
            } else {
                output.write("Execption thrown! Unknown error.");
            }
            output.write(OS.INSTANCE.getLINE_SEPARATOR());
        }
        catch (IOException iOException) {
            // empty catch block
        }
    }

    public static void handleUncaughtException(Throwable error) {
        if (!(error instanceof ExitBase)) {
            String message = error.getMessage();
            if (message == null) {
                message = Exit.getStackStrace(error);
            }
            Exit.writeToLogFile("Uncaught Exception: " + error.getClass(), message);
            Exit._throwIfLaunching(new ExitError(UNDEFINED, "Abnormal termination from an uncaught exception! See log file.)"));
        }
    }

    public static int Undefined(Throwable e) {
        String message = e.getMessage();
        if (message == null) {
            ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream(8196);
            PrintStream printStream = new PrintStream(byteArrayOutputStream);
            e.printStackTrace(printStream);
            message = byteArrayOutputStream.toString();
            printStream.close();
        }
        message = e.getClass().toString() + " : " + message;
        Exit.writeToLogFile("Error", message);
        return Exit.Generic(UNDEFINED, "Undefined exception! Saved in log file.", message);
    }

    public static int Normal() {
        return Exit.Generic(NORMAL, "Normal exit called.");
    }

    public static int FailedConfiguration(String errorMessage, Throwable throwable) {
        return Exit.Generic(FAILED_CONFIG, "FailedConfiguration called: " + errorMessage, throwable);
    }

    public static int FailedInitialization(Throwable throwable) {
        return Exit.Generic(FAILED_INIT, "FailedInitialization called: " + throwable.getMessage(), throwable);
    }

    public static int FailedConfiguration(String errorMessage) {
        return Exit.Generic(FAILED_CONFIG, "FailedConfiguration called: " + errorMessage);
    }

    public static int FailedInitialization(String errorMessage, Throwable throwable) {
        return Exit.Generic(FAILED_INIT, "FailedInitialization called: " + errorMessage, throwable);
    }

    public static int FailedInitialization(String errorMessage) {
        return Exit.Generic(FAILED_INIT, "FailedInitialization called: " + errorMessage);
    }

    public static int FailedSecurity(Throwable throwable) {
        return Exit.Generic(FAILED_SECURITY, "FailedSecurity called: " + throwable.getMessage(), throwable);
    }

    public static int FailedSecurity(String errorMessage, Throwable throwable) {
        return Exit.Generic(FAILED_SECURITY, "FailedSecurity called: " + errorMessage, throwable);
    }

    public static int FailedSecurity(String errorMessage) {
        return Exit.Generic(FAILED_SECURITY, "FailedSecurity called: " + errorMessage);
    }

    public static int Generic(int exitCode, String errorMessage, Throwable throwable) {
        return Exit.Generic(exitCode, errorMessage + OS.INSTANCE.getLINE_SEPARATOR() + throwable.getClass() + OS.INSTANCE.getLINE_SEPARATOR() + throwable.getMessage());
    }

    public static int Generic(int exitCode, String errorMessage) {
        Exit._throwIfLaunching(new ExitError(exitCode, errorMessage));
        return exitCode;
    }

    public static int Generic(int exitCode, String errorTitle, String errorMessage) {
        Exit._throwIfLaunching(new ExitError(exitCode, errorTitle, errorMessage));
        return exitCode;
    }

    public static void Restart() {
        Exit._throwIfLaunching(new ExitRestart(RESTART));
    }

    public static void UpgradeExectuable() {
        Exit._throwIfLaunching(new ExitRestart(UPGRADE_EXECUTABLE));
    }

    static void _setExitData(ExitBase e) {
        if (e == null) {
            return;
        }
        exitValue.set(e.getExitCode());
        if (e.getMessage() != null) {
            String message = e.getMessage();
            if (Exit.isNative()) {
                if (e.getTitle() != null) {
                    Exit.setExitError("<title>" + e.getTitle() + "</title>" + OS.INSTANCE.getLINE_SEPARATOR() + message);
                } else {
                    Exit.setExitError(message);
                }
            }
        }
    }

    static void _setExitCode(int exitCode) {
        exitValue.set(exitCode);
    }

    static void _throwIfLaunching(ExitBase exitError) {
        if (exitError != null && Exit.exitError == null) {
            Exit.exitError = exitError;
        }
        if (exitError != null) {
            throw exitError;
        }
        throw new ExitError(FAILED_INIT, "Unable to have a null errorMessage!");
    }

    public static String getStackStrace(Throwable throwable) {
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream(8196);
        PrintStream printStream = new PrintStream(byteArrayOutputStream);
        throwable.printStackTrace(printStream);
        String message = byteArrayOutputStream.toString();
        printStream.flush();
        printStream.close();
        return message;
    }

    public final Object clone() throws CloneNotSupportedException {
        throw new CloneNotSupportedException();
    }

    public final void writeObject(ObjectOutputStream out) throws IOException {
        throw new NotSerializableException();
    }

    public final void readObject(ObjectInputStream in) throws IOException {
        throw new NotSerializableException();
    }

    static {
        RESERVED_LIST.add(SAVED_IN_LOG_FILE);
        RESERVED_LIST.add(RESTART);
        RESERVED_LIST.add(UPGRADE_EXECUTABLE);
        exitValue = new AtomicInteger(NORMAL);
        exitError = null;
    }
}

