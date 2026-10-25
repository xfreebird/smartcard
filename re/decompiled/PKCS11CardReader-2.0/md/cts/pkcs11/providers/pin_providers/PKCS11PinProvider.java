/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.pkcs.pkcs11.Session
 *  iaik.pkcs.pkcs11.TokenException
 *  iaik.pkcs.pkcs11.provider.IAIKPkcs11AuthenticationException
 *  iaik.pkcs.pkcs11.provider.LoginManager
 *  iaik.pkcs.pkcs11.provider.TokenManager
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.providers.pin_providers;

import iaik.pkcs.pkcs11.Session;
import iaik.pkcs.pkcs11.TokenException;
import iaik.pkcs.pkcs11.provider.IAIKPkcs11AuthenticationException;
import iaik.pkcs.pkcs11.provider.LoginManager;
import iaik.pkcs.pkcs11.provider.TokenManager;
import md.cts.pkcs11.providers.pin_providers.EnterPinDialog;
import md.cts.pkcs11.providers.pin_providers.NoMoreAttemptsException;
import md.cts.pkcs11.providers.pin_providers.PinDistributor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class PKCS11PinProvider
extends LoginManager {
    private static final Logger logger = LoggerFactory.getLogger(PKCS11PinProvider.class);
    private final String sessionId;
    private final String requester;
    private char[] pincode;

    public PKCS11PinProvider(char[] pin, String sessionId, String requester) {
        this.pincode = pin;
        this.sessionId = sessionId;
        this.requester = requester;
        logger.info("new PKCS11PinProvider() {}", (Object)sessionId);
    }

    public void loginUser(TokenManager tokenManager, Session session, char[] pin) {
        logger.info("loginUser() {}", (Object)this.sessionId);
        if (tokenManager == null) {
            logger.error("tokenManager is null");
            return;
        }
        if (session == null) {
            logger.error("session is null");
            return;
        }
        boolean logedin = false;
        if (pin != null) {
            logger.info("session.login with pin");
            try {
                session.login(true, pin);
                PinDistributor.setPinForSession(this.sessionId, pin);
                logedin = true;
            }
            catch (TokenException tokenException) {
                logger.error("", (Throwable)tokenException);
            }
        }
        if (this.pincode != null && !logedin) {
            logger.info("session.login with pincode");
            try {
                session.login(true, this.pincode);
                PinDistributor.setPinForSession(this.sessionId, this.pincode);
                logedin = true;
            }
            catch (TokenException tokenException) {
                logger.error("", (Throwable)tokenException);
            }
        }
        if (!logedin) {
            EnterPinDialog pinProvider = new EnterPinDialog(this.requester);
            while (!logedin) {
                try {
                    try {
                        this.pincode = pinProvider.getNextPin();
                        session.login(true, this.pincode);
                        PinDistributor.setPinForSession(this.sessionId, this.pincode);
                        logedin = true;
                    }
                    catch (NoMoreAttemptsException ex) {
                        this.pincode = null;
                        break;
                    }
                }
                catch (TokenException ex) {
                    this.pincode = null;
                }
            }
        }
        logger.info("LoginManager isLoggedIn={}", (Object)logedin);
    }

    public void loginSO(TokenManager tokenManager, Session session, char[] chars) throws IAIKPkcs11AuthenticationException {
        logger.info("loginSO() {}", (Object)this.sessionId);
        throw new UnsupportedOperationException("Not supported yet.");
    }

    public void login(TokenManager tokenManager, Session session, boolean b, char[] chars) throws IAIKPkcs11AuthenticationException {
        logger.info("login() {}", (Object)this.sessionId);
        if (b) {
            throw new UnsupportedOperationException("Not supported yet.");
        }
        this.loginUser(tokenManager, session, chars);
    }

    public void setUserPIN(TokenManager arg0, Session arg1, char[] arg2, char[] arg3) {
        logger.info("setUserPIN() {}", (Object)this.sessionId);
        throw new UnsupportedOperationException("Not supported yet.");
    }

    public void logout(TokenManager tokenManager, Session session) {
        if (session != null) {
            try {
                session.logout();
            }
            catch (TokenException tokenException) {
                logger.error("", (Throwable)tokenException);
            }
        }
    }
}

