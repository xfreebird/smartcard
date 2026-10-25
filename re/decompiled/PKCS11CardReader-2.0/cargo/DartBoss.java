/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.pkcs.pkcs11.Module
 *  iaik.pkcs.pkcs11.Token
 *  org.bouncycastle.jce.provider.BouncyCastleProvider
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package cargo;

import cargo.DartApi;
import cargo.DartCallback;
import cargo.DartCertificate;
import cargo.DartKey;
import cargo.DartModule;
import cargo.DartPki;
import cargo.DartSignature;
import cargo.Rust;
import cargo.model.CheckDeclarationSubjectReq;
import cargo.model.CheckDeclarationSubjectResp;
import cargo.model.IssueNewCertificateReq;
import cargo.model.IssueNewCertificateResp;
import cargo.model.RenewalPossibilityReq;
import cargo.model.RenewalPossibilityResp;
import iaik.pkcs.pkcs11.Module;
import iaik.pkcs.pkcs11.Token;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.security.Provider;
import java.security.SecureRandom;
import java.security.Security;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import md.cts.pkcs11.cards.CardReaderManager;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class DartBoss {
    private static final Logger logger = LoggerFactory.getLogger(DartBoss.class);
    private static final Object synchro = new Object();
    private static Map<Long, DartCertificate> dartCertificateList = null;

    private DartBoss() {
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public static Map<Long, DartCertificate> getDartCertificateList() {
        Object object = synchro;
        synchronized (object) {
            return dartCertificateList;
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public static DartCertificate getDartCertificate(Long id) {
        Object object = synchro;
        synchronized (object) {
            if (dartCertificateList != null) {
                return dartCertificateList.get(id);
            }
        }
        return null;
    }

    private static List<Module> getDriver() {
        List<Module> drvList = CardReaderManager.get().getAllModules();
        logger.info("getDriver() {}", (Object)drvList.size());
        return drvList;
    }

    public static void startCheckCertificate(DartCallback callback) {
        Thread th = new Thread(() -> DartBoss.loadListOfCertificateForAllModule(callback));
        th.start();
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    private static void loadListOfCertificateForAllModule(DartCallback callback) {
        logger.info("load the list of Certificates for renewal checking");
        Security.addProvider((Provider)new BouncyCastleProvider());
        Object object = synchro;
        synchronized (object) {
            dartCertificateList = null;
        }
        HashMap<Long, DartCertificate> certList = new HashMap<Long, DartCertificate>();
        List<Module> drvList = DartBoss.getDriver();
        for (Module module : drvList) {
            Map<Long, DartCertificate> map = DartBoss.loadListOfCertificate(module);
            if (map == null) continue;
            certList.putAll(map);
        }
        logger.info("renewal all={}", (Object)certList.size());
        if (certList.isEmpty()) {
            return;
        }
        HashMap<Long, DartCertificate> certList1 = new HashMap<Long, DartCertificate>();
        for (Map.Entry entry : certList.entrySet()) {
            Long key = (Long)entry.getKey();
            DartCertificate dart = (DartCertificate)entry.getValue();
            if (!dart.hasSpecificIssuer() || !dart.isNearingExpiration() || DartBoss.isAlReady(dart, certList)) continue;
            certList1.put(key, dart);
        }
        logger.info("renewal expiring={}", (Object)certList1.size());
        if (certList1.isEmpty()) {
            return;
        }
        CheckDeclarationSubjectReq checkDeclarationSubjectReq = new CheckDeclarationSubjectReq(certList1);
        logger.info("renewal for check={}", (Object)checkDeclarationSubjectReq.checklist.size());
        if (checkDeclarationSubjectReq.checklist.isEmpty()) {
            return;
        }
        CheckDeclarationSubjectResp checkDeclarationSubjectResp = DartApi.doHttpCall("CheckDeclarationSubjectPerson", checkDeclarationSubjectReq, CheckDeclarationSubjectReq.class, CheckDeclarationSubjectResp.class);
        if (checkDeclarationSubjectResp == null) {
            return;
        }
        HashMap<Long, DartCertificate> certList2 = new HashMap<Long, DartCertificate>();
        for (CheckDeclarationSubjectResp.Org org : checkDeclarationSubjectResp.checklist) {
            if (!org.confirm()) continue;
            certList2.put(org.id(), (DartCertificate)certList1.get(org.id()));
        }
        logger.info("renewal to go={}", (Object)certList2.size());
        if (certList2.isEmpty()) {
            return;
        }
        Object object2 = synchro;
        synchronized (object2) {
            dartCertificateList = certList2;
        }
        callback.run(DartCallback.Code.OK);
    }

    private static boolean isAlReady(DartCertificate dart, Map<Long, DartCertificate> certList) {
        for (DartCertificate entry : certList.values()) {
            if (!dart.isAlReady(entry.getCert())) continue;
            return true;
        }
        return false;
    }

    private static Map<Long, DartCertificate> loadListOfCertificate(Module drv) {
        Map<Long, DartCertificate> map;
        DartModule dart = new DartModule(null);
        try {
            dart.bridge(drv);
            dart.scanTokens();
            map = dart.scanCertificates();
        }
        catch (Throwable throwable) {
            try {
                try {
                    dart.close();
                }
                catch (Throwable throwable2) {
                    throwable.addSuppressed(throwable2);
                }
                throw throwable;
            }
            catch (Exception ex) {
                logger.error("", (Throwable)ex);
                return null;
            }
        }
        dart.close();
        return map;
    }

    public static void startRenewalPossibility(long dartKey, DartCallback callback) {
        Thread th = new Thread(() -> DartBoss.checkRenewalPossibility(dartKey, callback));
        th.start();
    }

    private static void checkRenewalPossibility(long dartKey, DartCallback callback) {
        logger.info("checkRenewalPossibility()");
        if (dartCertificateList == null) {
            logger.error("empty list");
            callback.run(DartCallback.Code.LOCAL_ERROR);
            return;
        }
        DartCertificate dartCert = dartCertificateList.get(dartKey);
        if (dartCert == null) {
            logger.error("not found");
            callback.run(DartCallback.Code.LOCAL_ERROR);
            return;
        }
        String pem = dartCert.getCert_b64();
        if (pem == null) {
            logger.error("empty pem");
            callback.run(DartCallback.Code.LOCAL_ERROR);
            return;
        }
        RenewalPossibilityReq reqJson = new RenewalPossibilityReq(pem);
        RenewalPossibilityResp respJson = DartApi.doHttpCall("CheckRenewalPossibility", reqJson, RenewalPossibilityReq.class, RenewalPossibilityResp.class);
        if (respJson == null) {
            callback.run(DartCallback.Code.REMOTE_ERROR);
            return;
        }
        if (!respJson.success || !respJson.confirm) {
            callback.run(DartCallback.Code.REMOTE_ERROR);
            return;
        }
        callback.run(DartCallback.Code.OK);
    }

    public static void startGenerate(long dartKey, char[] pin, DartCallback callback) {
        Thread th = new Thread(() -> DartBoss.generate(dartKey, pin, callback));
        th.start();
    }

    private static void generate(long dartKey, char[] pin, DartCallback callback) {
        logger.info("generate()");
        if (dartCertificateList == null) {
            logger.error("generate() empty list");
            callback.run(DartCallback.Code.LOCAL_ERROR);
            return;
        }
        DartCertificate dartCert = dartCertificateList.get(dartKey);
        if (dartCert == null) {
            logger.error("generate() not found");
            callback.run(DartCallback.Code.LOCAL_ERROR);
            return;
        }
        Module drv = dartCert.getToken().getSlot().getModule();
        if (drv == null) {
            callback.run(DartCallback.Code.LOCAL_ERROR);
            return;
        }
        String pem = dartCert.getCert_b64();
        if (pem == null) {
            logger.error("generate() empty pem");
            callback.run(DartCallback.Code.LOCAL_ERROR);
            return;
        }
        SecureRandom random = new SecureRandom();
        byte[] random_nonce = new byte[32];
        random.nextBytes(random_nonce);
        logger.info("random_nonce: {}", (Object)Base64.getEncoder().encodeToString(random_nonce));
        try (DartModule dart = new DartModule(pin);){
            dart.bridge(drv);
            dart.delete(dartCert.getToken());
            DartKey newKey = dart.generate(dartCert.getToken(), 1);
            if (newKey == null) {
                callback.run(DartCallback.Code.LOCAL_ERROR);
                return;
            }
            byte[] data1 = Rust.concatenateByteArrays(random_nonce, newKey.getId(), dartCert.getCertBytes(), newKey.getKeyBytes());
            DartSignature signature1 = dart.sign(dartCert.getToken(), newKey.getId(), data1);
            if (signature1 == null) {
                callback.run(DartCallback.Code.LOCAL_ERROR);
                return;
            }
            byte[] data2 = Rust.concatenateByteArrays(data1, signature1.signature());
            DartSignature signature2 = dart.sign(dartCert.getToken(), dartCert.getId(), data2);
            if (signature2 == null) {
                callback.run(DartCallback.Code.LOCAL_ERROR);
                return;
            }
            boolean v1 = DartPki.verify(newKey.getKey(), signature1.signature(), data1);
            boolean v2 = DartPki.verify(dartCert.getCert().getPublicKey(), signature2.signature(), data2);
            logger.info("verify {} {}", (Object)v1, (Object)v2);
            IssueNewCertificateReq reqJson = new IssueNewCertificateReq(Base64.getEncoder().encodeToString(random_nonce), newKey.getId_b64(), dartCert.getCert_b64(), newKey.getPubKey_b64(), Base64.getEncoder().encodeToString(signature1.signature()), Base64.getEncoder().encodeToString(signature2.signature()), dart.getTokenInformation(dartCert.getToken()));
            logger.info("generate() hard work done");
            IssueNewCertificateResp respJson = DartApi.doHttpCall("IssueNewCertificate", reqJson, IssueNewCertificateReq.class, IssueNewCertificateResp.class);
            if (respJson == null) {
                callback.run(DartCallback.Code.REMOTE_ERROR);
                return;
            }
            if (!reqJson.key_id.equals(respJson.key_id) || !reqJson.client_nonce.equals(respJson.client_nonce)) {
                callback.run(DartCallback.Code.REMOTE_ERROR);
                return;
            }
            boolean valid = DartPki.checkNew(respJson.new_certificate, "");
            if (!valid) {
                callback.run(DartCallback.Code.REMOTE_ERROR);
                return;
            }
            byte[] newDer = Base64.getDecoder().decode(respJson.new_certificate);
            boolean putOk = dart.putCertificate(dartCert.getToken(), newDer, newKey.getId(), dartCert.getId());
            if (!putOk) {
                callback.run(DartCallback.Code.LOCAL_ERROR);
                return;
            }
            logger.info("put certificate done");
            callback.run(DartCallback.Code.OK);
            return;
        }
        catch (Exception ex) {
            logger.error("", (Throwable)ex);
            callback.run(DartCallback.Code.LOCAL_ERROR);
            return;
        }
    }

    public static void startGenerateNew() {
        Thread th = new Thread(DartBoss::generateNew);
        th.start();
    }

    private static void generateNew() {
        logger.info("generateNew()");
        Security.addProvider((Provider)new BouncyCastleProvider());
        List<Module> drvList = DartBoss.getDriver();
        for (Module module : drvList) {
            logger.info("drv: {}", (Object)module);
        }
        Module drv = null;
        for (Module d : drvList) {
            if (!d.toString().contains("bit4xpki.dll")) continue;
            drv = d;
            break;
        }
        if (drv == null) {
            logger.error("drv not found");
            return;
        }
        char[] cArray = "11111111".toCharArray();
        try (DartModule dart = new DartModule(cArray);){
            dart.bridge(drv);
            dart.scanTokens();
            Token tok = dart.getToken(0L);
            if (tok == null) {
                logger.error("tok == null");
                return;
            }
            dart.delete(tok);
            DartKey newKey = dart.generate(tok, 2);
            if (newKey == null) {
                logger.error("newKey == null");
                return;
            }
            logger.info("generateNew() done");
        }
        catch (Exception ex) {
            logger.error("", (Throwable)ex);
        }
    }

    public static void startPutNew() {
        Thread th = new Thread(DartBoss::putNew);
        th.start();
    }

    private static void putNew() {
        logger.info("putNew()");
        Security.addProvider((Provider)new BouncyCastleProvider());
        List<Module> drvList = DartBoss.getDriver();
        for (Module module : drvList) {
            logger.info("put drv: {}", (Object)module);
        }
        Module drv = null;
        for (Module d : drvList) {
            if (!d.toString().contains("bit4xpki.dll")) continue;
            drv = d;
            break;
        }
        if (drv == null) {
            logger.error("put drv not found");
            return;
        }
        char[] cArray = "11111111".toCharArray();
        try (DartModule dart = new DartModule(cArray);){
            dart.bridge(drv);
            dart.scanTokens();
            Token tok = dart.getToken(0L);
            if (tok == null) {
                logger.error("put tok == null");
                return;
            }
            byte[] id = Rust.hexToBytes("D5ABD7F8543BD81A8390E695ABA008F69DE9324253A09A1BD691E3CE6C2A475B");
            byte[] fileBytes = Files.readAllBytes(Paths.get("d:\\qq\\csr_cert.crt", new String[0]));
            boolean putOk = dart.putCertificate(tok, fileBytes, id, new byte[0]);
            if (!putOk) {
                logger.error("put not Ok");
                return;
            }
            logger.info("put new certificate done");
        }
        catch (Exception ex) {
            logger.error("", (Throwable)ex);
        }
    }
}

