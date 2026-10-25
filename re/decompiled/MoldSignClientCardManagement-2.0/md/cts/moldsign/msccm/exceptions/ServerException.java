/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.msccm.exceptions;

import java.util.MissingResourceException;
import java.util.ResourceBundle;

public class ServerException
extends Exception {
    private final ResourceBundle errorBundle = ResourceBundle.getBundle("error_messages");

    public ServerException(String msg) {
        super(msg);
    }

    @Override
    public String getLocalizedMessage() {
        String message;
        try {
            message = this.errorBundle.getString(this.getMessage());
        }
        catch (MissingResourceException ex) {
            message = this.getMessage();
        }
        return message;
    }
}

