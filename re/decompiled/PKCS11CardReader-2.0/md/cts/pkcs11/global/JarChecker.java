/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.cts.moldsign.transferobjects.models.CertificateModel
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.global;

import java.io.IOException;
import java.io.InputStream;
import java.security.cert.Certificate;
import java.security.cert.X509Certificate;
import java.util.Enumeration;
import java.util.List;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;
import md.cts.cryptography.providers.GlobalCertificateProvider;
import md.cts.cryptography.providers.JKSTrustedCertificateProvider;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class JarChecker {
    private static final Logger logger = LoggerFactory.getLogger(JarChecker.class);

    public static boolean checkJar(String jarFile) {
        GlobalCertificateProvider.get().registerProvider(new JKSTrustedCertificateProvider(), true);
        try {
            JarFile jar = new JarFile(jarFile, true);
            byte[] buffer = new byte[8192];
            Enumeration<JarEntry> entries = jar.entries();
            while (entries.hasMoreElements()) {
                JarEntry entry = entries.nextElement();
                if (entry.isDirectory()) continue;
                logger.info("Verifing entry: {}", (Object)entry.getName());
                InputStream entryStream = jar.getInputStream(entry);
                while (entryStream.read(buffer) != -1) {
                }
                entryStream.close();
                Certificate[] certificates = entry.getCertificates();
                if (certificates == null) {
                    if (entry.getName().startsWith("META-INF")) continue;
                    return false;
                }
                Certificate certificate = certificates[0];
                boolean result = false;
                if (!(certificate instanceof X509Certificate)) continue;
                X509Certificate cert = (X509Certificate)certificate;
                List<CertificateModel> certificateChain = GlobalCertificateProvider.get().getCertificateChain(new CertificateModel(cert));
                for (CertificateModel certModel : certificateChain) {
                    if (!certModel.isTrusted()) continue;
                    result = true;
                    break;
                }
                if (result) continue;
                return false;
            }
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
            return false;
        }
        return true;
    }
}

