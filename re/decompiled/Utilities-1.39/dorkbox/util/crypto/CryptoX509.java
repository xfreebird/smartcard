/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.bouncycastle.asn1.ASN1Encodable
 *  org.bouncycastle.asn1.ASN1EncodableVector
 *  org.bouncycastle.asn1.ASN1InputStream
 *  org.bouncycastle.asn1.ASN1Integer
 *  org.bouncycastle.asn1.ASN1ObjectIdentifier
 *  org.bouncycastle.asn1.ASN1OctetString
 *  org.bouncycastle.asn1.ASN1Primitive
 *  org.bouncycastle.asn1.ASN1Sequence
 *  org.bouncycastle.asn1.ASN1Set
 *  org.bouncycastle.asn1.BERSequence
 *  org.bouncycastle.asn1.BERSet
 *  org.bouncycastle.asn1.DERBMPString
 *  org.bouncycastle.asn1.DEROctetString
 *  org.bouncycastle.asn1.DERSet
 *  org.bouncycastle.asn1.cms.CMSObjectIdentifiers
 *  org.bouncycastle.asn1.cms.ContentInfo
 *  org.bouncycastle.asn1.cms.IssuerAndSerialNumber
 *  org.bouncycastle.asn1.cms.SignedData
 *  org.bouncycastle.asn1.cms.SignerIdentifier
 *  org.bouncycastle.asn1.cms.SignerInfo
 *  org.bouncycastle.asn1.pkcs.PKCSObjectIdentifiers
 *  org.bouncycastle.asn1.pkcs.RSAPublicKey
 *  org.bouncycastle.asn1.x500.X500Name
 *  org.bouncycastle.asn1.x509.AlgorithmIdentifier
 *  org.bouncycastle.asn1.x509.AuthorityKeyIdentifier
 *  org.bouncycastle.asn1.x509.BasicConstraints
 *  org.bouncycastle.asn1.x509.DSAParameter
 *  org.bouncycastle.asn1.x509.Extension
 *  org.bouncycastle.asn1.x509.SubjectKeyIdentifier
 *  org.bouncycastle.asn1.x509.SubjectPublicKeyInfo
 *  org.bouncycastle.asn1.x9.X9ObjectIdentifiers
 *  org.bouncycastle.cert.X509CertificateHolder
 *  org.bouncycastle.cert.X509v3CertificateBuilder
 *  org.bouncycastle.cert.jcajce.JcaX509ExtensionUtils
 *  org.bouncycastle.cms.CMSProcessable
 *  org.bouncycastle.cms.CMSProcessableByteArray
 *  org.bouncycastle.cms.CMSSignedData
 *  org.bouncycastle.cms.DefaultCMSSignatureAlgorithmNameGenerator
 *  org.bouncycastle.crypto.params.AsymmetricKeyParameter
 *  org.bouncycastle.crypto.params.DSAParameters
 *  org.bouncycastle.crypto.params.DSAPrivateKeyParameters
 *  org.bouncycastle.crypto.params.DSAPublicKeyParameters
 *  org.bouncycastle.crypto.params.ECDomainParameters
 *  org.bouncycastle.crypto.params.ECPrivateKeyParameters
 *  org.bouncycastle.crypto.params.ECPublicKeyParameters
 *  org.bouncycastle.crypto.params.RSAKeyParameters
 *  org.bouncycastle.crypto.params.RSAPrivateCrtKeyParameters
 *  org.bouncycastle.jcajce.provider.asymmetric.dsa.BCDSAPublicKey
 *  org.bouncycastle.jcajce.provider.asymmetric.dsa.DSAUtil
 *  org.bouncycastle.jcajce.provider.asymmetric.ec.BCECPublicKey
 *  org.bouncycastle.jcajce.provider.asymmetric.rsa.BCRSAPublicKey
 *  org.bouncycastle.jcajce.provider.asymmetric.rsa.RSAUtil
 *  org.bouncycastle.jcajce.provider.asymmetric.x509.CertificateFactory
 *  org.bouncycastle.jce.PrincipalUtil
 *  org.bouncycastle.jce.interfaces.PKCS12BagAttributeCarrier
 *  org.bouncycastle.jce.provider.BouncyCastleProvider
 *  org.bouncycastle.jce.provider.JCEECPublicKey
 *  org.bouncycastle.jce.spec.ECParameterSpec
 *  org.bouncycastle.operator.ContentSigner
 *  org.bouncycastle.operator.ContentVerifierProvider
 *  org.bouncycastle.operator.DefaultDigestAlgorithmIdentifierFinder
 *  org.bouncycastle.operator.DefaultSignatureAlgorithmIdentifierFinder
 *  org.bouncycastle.operator.DigestAlgorithmIdentifierFinder
 *  org.bouncycastle.operator.OperatorCreationException
 *  org.bouncycastle.operator.bc.BcDSAContentSignerBuilder
 *  org.bouncycastle.operator.bc.BcDSAContentVerifierProviderBuilder
 *  org.bouncycastle.operator.bc.BcRSAContentSignerBuilder
 *  org.bouncycastle.operator.bc.BcRSAContentVerifierProviderBuilder
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package dorkbox.util.crypto;

import dorkbox.util.crypto.signers.BcECDSAContentSignerBuilder;
import dorkbox.util.crypto.signers.BcECDSAContentVerifierProviderBuilder;
import java.io.BufferedWriter;
import java.io.ByteArrayInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.Writer;
import java.lang.reflect.Method;
import java.math.BigInteger;
import java.security.InvalidKeyException;
import java.security.KeyFactory;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.PrivateKey;
import java.security.Provider;
import java.security.PublicKey;
import java.security.Security;
import java.security.SignatureException;
import java.security.cert.Certificate;
import java.security.cert.CertificateEncodingException;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.security.interfaces.DSAParams;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.RSAPrivateCrtKeySpec;
import java.security.spec.RSAPublicKeySpec;
import java.util.Base64;
import java.util.Date;
import org.bouncycastle.asn1.ASN1Encodable;
import org.bouncycastle.asn1.ASN1EncodableVector;
import org.bouncycastle.asn1.ASN1InputStream;
import org.bouncycastle.asn1.ASN1Integer;
import org.bouncycastle.asn1.ASN1ObjectIdentifier;
import org.bouncycastle.asn1.ASN1OctetString;
import org.bouncycastle.asn1.ASN1Primitive;
import org.bouncycastle.asn1.ASN1Sequence;
import org.bouncycastle.asn1.ASN1Set;
import org.bouncycastle.asn1.BERSequence;
import org.bouncycastle.asn1.BERSet;
import org.bouncycastle.asn1.DERBMPString;
import org.bouncycastle.asn1.DEROctetString;
import org.bouncycastle.asn1.DERSet;
import org.bouncycastle.asn1.cms.CMSObjectIdentifiers;
import org.bouncycastle.asn1.cms.ContentInfo;
import org.bouncycastle.asn1.cms.IssuerAndSerialNumber;
import org.bouncycastle.asn1.cms.SignedData;
import org.bouncycastle.asn1.cms.SignerIdentifier;
import org.bouncycastle.asn1.cms.SignerInfo;
import org.bouncycastle.asn1.pkcs.PKCSObjectIdentifiers;
import org.bouncycastle.asn1.pkcs.RSAPublicKey;
import org.bouncycastle.asn1.x500.X500Name;
import org.bouncycastle.asn1.x509.AlgorithmIdentifier;
import org.bouncycastle.asn1.x509.AuthorityKeyIdentifier;
import org.bouncycastle.asn1.x509.BasicConstraints;
import org.bouncycastle.asn1.x509.DSAParameter;
import org.bouncycastle.asn1.x509.Extension;
import org.bouncycastle.asn1.x509.SubjectKeyIdentifier;
import org.bouncycastle.asn1.x509.SubjectPublicKeyInfo;
import org.bouncycastle.asn1.x9.X9ObjectIdentifiers;
import org.bouncycastle.cert.X509CertificateHolder;
import org.bouncycastle.cert.X509v3CertificateBuilder;
import org.bouncycastle.cert.jcajce.JcaX509ExtensionUtils;
import org.bouncycastle.cms.CMSProcessable;
import org.bouncycastle.cms.CMSProcessableByteArray;
import org.bouncycastle.cms.CMSSignedData;
import org.bouncycastle.cms.DefaultCMSSignatureAlgorithmNameGenerator;
import org.bouncycastle.crypto.params.AsymmetricKeyParameter;
import org.bouncycastle.crypto.params.DSAParameters;
import org.bouncycastle.crypto.params.DSAPrivateKeyParameters;
import org.bouncycastle.crypto.params.DSAPublicKeyParameters;
import org.bouncycastle.crypto.params.ECDomainParameters;
import org.bouncycastle.crypto.params.ECPrivateKeyParameters;
import org.bouncycastle.crypto.params.ECPublicKeyParameters;
import org.bouncycastle.crypto.params.RSAKeyParameters;
import org.bouncycastle.crypto.params.RSAPrivateCrtKeyParameters;
import org.bouncycastle.jcajce.provider.asymmetric.dsa.BCDSAPublicKey;
import org.bouncycastle.jcajce.provider.asymmetric.dsa.DSAUtil;
import org.bouncycastle.jcajce.provider.asymmetric.ec.BCECPublicKey;
import org.bouncycastle.jcajce.provider.asymmetric.rsa.BCRSAPublicKey;
import org.bouncycastle.jcajce.provider.asymmetric.rsa.RSAUtil;
import org.bouncycastle.jcajce.provider.asymmetric.x509.CertificateFactory;
import org.bouncycastle.jce.PrincipalUtil;
import org.bouncycastle.jce.interfaces.PKCS12BagAttributeCarrier;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.bouncycastle.jce.provider.JCEECPublicKey;
import org.bouncycastle.jce.spec.ECParameterSpec;
import org.bouncycastle.operator.ContentSigner;
import org.bouncycastle.operator.ContentVerifierProvider;
import org.bouncycastle.operator.DefaultDigestAlgorithmIdentifierFinder;
import org.bouncycastle.operator.DefaultSignatureAlgorithmIdentifierFinder;
import org.bouncycastle.operator.DigestAlgorithmIdentifierFinder;
import org.bouncycastle.operator.OperatorCreationException;
import org.bouncycastle.operator.bc.BcDSAContentSignerBuilder;
import org.bouncycastle.operator.bc.BcDSAContentVerifierProviderBuilder;
import org.bouncycastle.operator.bc.BcRSAContentSignerBuilder;
import org.bouncycastle.operator.bc.BcRSAContentVerifierProviderBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class CryptoX509 {
    private static final Logger logger = LoggerFactory.getLogger(CryptoX509.class);

    public static void addProvider() {
        Provider provider = Security.getProvider("BC");
        if (provider == null) {
            Security.addProvider((Provider)new BouncyCastleProvider());
        }
    }

    public static byte[] createSignature(byte[] signatureSourceData, X509CertificateHolder x509CertificateHolder, AsymmetricKeyParameter privateKey) {
        try {
            AlgorithmIdentifier digEncryptionAlgorithm;
            BcECDSAContentSignerBuilder contentSignerBuilder;
            CMSProcessableByteArray content = new CMSProcessableByteArray(signatureSourceData);
            ASN1ObjectIdentifier contentTypeOID = new ASN1ObjectIdentifier(content.getContentType().getId());
            ASN1EncodableVector digestAlgs = new ASN1EncodableVector();
            ASN1EncodableVector signerInfos = new ASN1EncodableVector();
            AlgorithmIdentifier sigAlgId = x509CertificateHolder.getSignatureAlgorithm();
            AlgorithmIdentifier digAlgId = new DefaultDigestAlgorithmIdentifierFinder().find(sigAlgId);
            if (privateKey instanceof ECPrivateKeyParameters) {
                contentSignerBuilder = new BcECDSAContentSignerBuilder(sigAlgId, digAlgId);
                digEncryptionAlgorithm = new AlgorithmIdentifier(DSAUtil.dsaOids[0], null);
            } else if (privateKey instanceof DSAPrivateKeyParameters) {
                contentSignerBuilder = new BcDSAContentSignerBuilder(sigAlgId, digAlgId);
                digEncryptionAlgorithm = new AlgorithmIdentifier(DSAUtil.dsaOids[0], null);
            } else if (privateKey instanceof RSAPrivateCrtKeyParameters) {
                contentSignerBuilder = new BcRSAContentSignerBuilder(sigAlgId, digAlgId);
                digEncryptionAlgorithm = new AlgorithmIdentifier(RSAUtil.rsaOids[0], null);
            } else {
                throw new RuntimeException("Invalid signature type. Only ECDSA, DSA, RSA supported.");
            }
            ContentSigner hashSigner = contentSignerBuilder.build(privateKey);
            OutputStream outputStream = hashSigner.getOutputStream();
            outputStream.write(signatureSourceData, 0, signatureSourceData.length);
            outputStream.flush();
            byte[] sigBytes = hashSigner.getSignature();
            SignerIdentifier sigId = new SignerIdentifier(new IssuerAndSerialNumber(x509CertificateHolder.toASN1Structure()));
            SignerInfo inf = new SignerInfo(sigId, digAlgId, null, digEncryptionAlgorithm, (ASN1OctetString)new DEROctetString(sigBytes), (ASN1Set)null);
            digestAlgs.add((ASN1Encodable)inf.getDigestAlgorithm());
            signerInfos.add((ASN1Encodable)inf);
            ASN1EncodableVector certs = new ASN1EncodableVector();
            certs.add((ASN1Encodable)x509CertificateHolder.toASN1Structure());
            ContentInfo encInfo = new ContentInfo(contentTypeOID, null);
            SignedData sd = new SignedData((ASN1Set)new DERSet(digestAlgs), encInfo, (ASN1Set)new BERSet(certs), null, (ASN1Set)new DERSet(signerInfos));
            ContentInfo contentInfo = new ContentInfo(CMSObjectIdentifiers.signedData, (ASN1Encodable)sd);
            CMSSignedData cmsSignedData2 = new CMSSignedData((CMSProcessable)content, contentInfo);
            return cmsSignedData2.getEncoded();
        }
        catch (Throwable t) {
            logger.error("Error signing data.", t);
            throw new RuntimeException("Error trying to sign data. " + t.getMessage());
        }
    }

    public static void loadKeystore(String keystoreLocation, String alias, char[] passwd, char[] keypasswd) {
    }

    public static class ECDSA {
        public static X509CertificateHolder createCertHolder(String digestName, Date startDate, Date expiryDate, X500Name issuerName, X500Name subjectName, BigInteger serialNumber, ECPrivateKeyParameters privateKey, ECPublicKeyParameters publicKey) {
            ContentSigner build;
            SubjectPublicKeyInfo subjectPublicKeyInfo;
            String signatureAlgorithm = digestName + "withECDSA";
            JCEECPublicKey pubKey = new JCEECPublicKey("EC", publicKey, (ECParameterSpec)null);
            AlgorithmIdentifier sigAlgId = new DefaultSignatureAlgorithmIdentifierFinder().find(signatureAlgorithm);
            AlgorithmIdentifier digAlgId = new DefaultDigestAlgorithmIdentifierFinder().find(sigAlgId);
            try {
                byte[] encoded = pubKey.getEncoded();
                ASN1Sequence seq = (ASN1Sequence)ASN1Primitive.fromByteArray((byte[])encoded);
                subjectPublicKeyInfo = SubjectPublicKeyInfo.getInstance((Object)seq);
            }
            catch (IOException e) {
                logger.error("Unable to perform DSA.", (Throwable)e);
                return null;
            }
            X509v3CertificateBuilder v3CertBuilder = new X509v3CertificateBuilder(issuerName, serialNumber, startDate, expiryDate, subjectName, subjectPublicKeyInfo);
            BcECDSAContentSignerBuilder contentSignerBuilder = new BcECDSAContentSignerBuilder(sigAlgId, digAlgId);
            try {
                build = contentSignerBuilder.build((AsymmetricKeyParameter)privateKey);
            }
            catch (OperatorCreationException e) {
                logger.error("Error creating certificate.", (Throwable)e);
                return null;
            }
            return v3CertBuilder.build(build);
        }

        public static boolean validate(X509CertificateHolder x509CertificateHolder) {
            try {
                ContentVerifierProvider contentVerifierProvider = new BcECDSAContentVerifierProviderBuilder((DigestAlgorithmIdentifierFinder)new DefaultDigestAlgorithmIdentifierFinder()).build(x509CertificateHolder);
                boolean signatureValid = x509CertificateHolder.isSignatureValid(contentVerifierProvider);
                if (!signatureValid) {
                    return false;
                }
                CertificateFactory certFactory = new CertificateFactory();
                Certificate certificate = certFactory.engineGenerateCertificate((InputStream)new ByteArrayInputStream(x509CertificateHolder.getEncoded()));
                if (certificate == null || certificate.getPublicKey() == null) {
                    return false;
                }
                ((X509Certificate)certificate).checkValidity(new Date());
                return true;
            }
            catch (Throwable t) {
                logger.error("Error validating certificate.", t);
                return false;
            }
        }

        /*
         * WARNING - Removed try catching itself - possible behaviour change.
         */
        public static boolean verifySignature(byte[] signatureBytes, ECPublicKeyParameters optionalOriginalPublicKey) {
            ASN1InputStream asn1InputStream = null;
            try {
                asn1InputStream = new ASN1InputStream((InputStream)new ByteArrayInputStream(signatureBytes));
                ASN1Primitive signatureASN = asn1InputStream.readObject();
                BERSequence seq = (BERSequence)ASN1Sequence.getInstance((Object)signatureASN);
                ContentInfo contentInfo = ContentInfo.getInstance((Object)seq);
                SignedData newSignedData = SignedData.getInstance((Object)contentInfo.getContent());
                ByteArrayInputStream newSigIn = new ByteArrayInputStream(newSignedData.getCertificates().parser().readObject().toASN1Primitive().getEncoded());
                CertificateFactory certificateFactory = new CertificateFactory();
                Certificate certificate = certificateFactory.engineGenerateCertificate((InputStream)newSigIn);
                PublicKey publicKey2 = certificate.getPublicKey();
                if (optionalOriginalPublicKey != null) {
                    ECDomainParameters parameters = optionalOriginalPublicKey.getParameters();
                    ECParameterSpec ecParameterSpec = new ECParameterSpec(parameters.getCurve(), parameters.getG(), parameters.getN(), parameters.getH());
                    BCECPublicKey origPublicKey = new BCECPublicKey("EC", optionalOriginalPublicKey, ecParameterSpec, null);
                    boolean equals = origPublicKey.equals((Object)publicKey2);
                    if (!equals) {
                        boolean bl = false;
                        return bl;
                    }
                    publicKey2 = origPublicKey;
                }
                certificate.verify(publicKey2);
                boolean bl = true;
                return bl;
            }
            catch (Throwable t) {
                logger.error("Error validating certificate.", t);
                boolean bl = false;
                return bl;
            }
            finally {
                if (asn1InputStream != null) {
                    try {
                        asn1InputStream.close();
                    }
                    catch (IOException e) {
                        logger.error("Error during ECDSA.", (Throwable)e);
                    }
                }
            }
        }

        static {
            Provider provider = Security.getProvider("BC");
            if (provider == null) {
                Security.addProvider((Provider)new BouncyCastleProvider());
            }
        }
    }

    public static class RSA {
        public static X509Certificate generateCert(KeyFactory factory, Date startDate, Date expiryDate, X509Certificate issuerCert, String subject, String friendlyName, RSAKeyParameters publicKey, RSAPrivateCrtKeyParameters signingCaKey) throws InvalidKeySpecException, InvalidKeyException, IOException, OperatorCreationException, CertificateException, NoSuchAlgorithmException, NoSuchProviderException, SignatureException {
            return RSA.generateCert(factory, startDate, expiryDate, X500Name.getInstance((Object)PrincipalUtil.getSubjectX509Principal((X509Certificate)issuerCert)), new X500Name(subject), friendlyName, publicKey, issuerCert, signingCaKey);
        }

        public static X509Certificate generateCert(KeyFactory factory, Date startDate, Date expiryDate, String subject, String friendlyName, RSAKeyParameters publicKey, RSAPrivateCrtKeyParameters privateKey) throws InvalidKeySpecException, InvalidKeyException, IOException, OperatorCreationException, CertificateException, NoSuchAlgorithmException, NoSuchProviderException, SignatureException {
            return RSA.generateCert(factory, startDate, expiryDate, new X500Name(subject), new X500Name(subject), friendlyName, publicKey, null, privateKey);
        }

        private static X509Certificate generateCert(KeyFactory factory, Date startDate, Date expiryDate, X500Name issuer, X500Name subject, String friendlyName, RSAKeyParameters certPublicKey, X509Certificate signingCertificate, RSAPrivateCrtKeyParameters signingPrivateKey) throws InvalidKeySpecException, IOException, InvalidKeyException, OperatorCreationException, CertificateException, NoSuchAlgorithmException, NoSuchProviderException, SignatureException {
            String signatureAlgorithm = "SHA1withRSA";
            AlgorithmIdentifier sigAlgId = new DefaultSignatureAlgorithmIdentifierFinder().find(signatureAlgorithm);
            AlgorithmIdentifier digAlgId = new DefaultDigestAlgorithmIdentifierFinder().find(sigAlgId);
            PublicKey jcePublicKey = RSA.convertToJCE(factory, certPublicKey);
            SubjectPublicKeyInfo subjectPublicKeyInfo = RSA.createSubjectPublicKey(jcePublicKey);
            X509v3CertificateBuilder certBuilder = new X509v3CertificateBuilder(issuer, BigInteger.valueOf(System.currentTimeMillis()), startDate, expiryDate, subject, subjectPublicKeyInfo);
            JcaX509ExtensionUtils jcaX509ExtensionUtils = new JcaX509ExtensionUtils();
            SubjectKeyIdentifier createSubjectKeyIdentifier = jcaX509ExtensionUtils.createSubjectKeyIdentifier(subjectPublicKeyInfo);
            certBuilder.addExtension(Extension.subjectKeyIdentifier, false, (ASN1Encodable)createSubjectKeyIdentifier);
            if (signingCertificate != null) {
                AuthorityKeyIdentifier createAuthorityKeyIdentifier = jcaX509ExtensionUtils.createAuthorityKeyIdentifier(signingCertificate.getPublicKey());
                certBuilder.addExtension(Extension.authorityKeyIdentifier, false, (ASN1Encodable)createAuthorityKeyIdentifier);
            }
            certBuilder.addExtension(Extension.basicConstraints, true, (ASN1Encodable)new BasicConstraints(false));
            ContentSigner signer = new BcRSAContentSignerBuilder(sigAlgId, digAlgId).build((AsymmetricKeyParameter)signingPrivateKey);
            X509CertificateHolder certHolder = certBuilder.build(signer);
            Certificate certificate = new CertificateFactory().engineGenerateCertificate((InputStream)new ByteArrayInputStream(certHolder.getEncoded()));
            if (!(certificate instanceof X509Certificate)) {
                logger.error("Error generating certificate, it's the wrong type.");
                return null;
            }
            if (signingCertificate != null) {
                certificate.verify(signingCertificate.getPublicKey());
            } else {
                certificate.verify(jcePublicKey);
            }
            if (certificate instanceof PKCS12BagAttributeCarrier) {
                PKCS12BagAttributeCarrier bagAttr = (PKCS12BagAttributeCarrier)certificate;
                bagAttr.setBagAttribute(PKCSObjectIdentifiers.pkcs_9_at_friendlyName, (ASN1Encodable)new DERBMPString(friendlyName));
                if (signingCertificate != null) {
                    bagAttr.setBagAttribute(PKCSObjectIdentifiers.pkcs_9_at_localKeyId, (ASN1Encodable)subjectPublicKeyInfo);
                }
            }
            return (X509Certificate)certificate;
        }

        private static SubjectPublicKeyInfo createSubjectPublicKey(PublicKey jcePublicKey) throws IOException {
            try (ASN1InputStream asn1InputStream = null;){
                asn1InputStream = new ASN1InputStream((InputStream)new ByteArrayInputStream(jcePublicKey.getEncoded()));
                SubjectPublicKeyInfo subjectPublicKeyInfo = SubjectPublicKeyInfo.getInstance((Object)asn1InputStream.readObject());
                return subjectPublicKeyInfo;
            }
        }

        public static PublicKey convertToJCE(RSAKeyParameters publicKey) throws NoSuchAlgorithmException, InvalidKeySpecException {
            KeyFactory keyFactory = KeyFactory.getInstance("RSA");
            return RSA.convertToJCE(keyFactory, publicKey);
        }

        public static PublicKey convertToJCE(KeyFactory keyFactory, RSAKeyParameters publicKey) throws InvalidKeySpecException {
            return keyFactory.generatePublic(new RSAPublicKeySpec(publicKey.getModulus(), publicKey.getExponent()));
        }

        public static RSAKeyParameters convertToBC(PublicKey publicKey) {
            RSAPublicKey pubKey = RSAPublicKey.getInstance((Object)publicKey);
            return new RSAKeyParameters(false, pubKey.getModulus(), pubKey.getPublicExponent());
        }

        public static PrivateKey convertToJCE(RSAKeyParameters publicKey, RSAPrivateCrtKeyParameters privateKey) throws InvalidKeySpecException, NoSuchAlgorithmException {
            KeyFactory keyFactory = KeyFactory.getInstance("RSA");
            return RSA.convertToJCE(keyFactory, publicKey, privateKey);
        }

        public static PrivateKey convertToJCE(KeyFactory keyFactory, RSAKeyParameters publicKey, RSAPrivateCrtKeyParameters privateKey) throws InvalidKeySpecException {
            return keyFactory.generatePrivate(new RSAPrivateCrtKeySpec(publicKey.getModulus(), publicKey.getExponent(), privateKey.getExponent(), privateKey.getP(), privateKey.getQ(), privateKey.getDP(), privateKey.getDQ(), privateKey.getQInv()));
        }

        public static X509CertificateHolder createCertHolder(Date startDate, Date expiryDate, X500Name issuerName, X500Name subjectName, BigInteger serialNumber, RSAPrivateCrtKeyParameters privateKey, RSAKeyParameters publicKey) {
            SubjectPublicKeyInfo subjectPublicKeyInfo;
            String signatureAlgorithm = "SHA256withRSA";
            AlgorithmIdentifier sigAlgId = new DefaultSignatureAlgorithmIdentifierFinder().find(signatureAlgorithm);
            AlgorithmIdentifier digAlgId = new DefaultDigestAlgorithmIdentifierFinder().find(sigAlgId);
            try {
                PublicKey jcePublicKey = RSA.convertToJCE(publicKey);
                subjectPublicKeyInfo = RSA.createSubjectPublicKey(jcePublicKey);
            }
            catch (Exception e) {
                logger.error("Unable to create RSA keyA.", (Throwable)e);
                return null;
            }
            try {
                X509v3CertificateBuilder certBuilder = new X509v3CertificateBuilder(issuerName, serialNumber, startDate, expiryDate, subjectName, subjectPublicKeyInfo);
                JcaX509ExtensionUtils jcaX509ExtensionUtils = new JcaX509ExtensionUtils();
                SubjectKeyIdentifier createSubjectKeyIdentifier = jcaX509ExtensionUtils.createSubjectKeyIdentifier(subjectPublicKeyInfo);
                certBuilder.addExtension(Extension.subjectKeyIdentifier, false, (ASN1Encodable)createSubjectKeyIdentifier);
                certBuilder.addExtension(Extension.basicConstraints, true, (ASN1Encodable)new BasicConstraints(false));
                ContentSigner hashSigner = new BcRSAContentSignerBuilder(sigAlgId, digAlgId).build((AsymmetricKeyParameter)privateKey);
                return certBuilder.build(hashSigner);
            }
            catch (Exception e) {
                logger.error("Error generating certificate.", (Throwable)e);
                return null;
            }
        }

        public static boolean validate(X509CertificateHolder x509CertificateHolder) {
            try {
                ContentVerifierProvider contentVerifierProvider = new BcRSAContentVerifierProviderBuilder((DigestAlgorithmIdentifierFinder)new DefaultDigestAlgorithmIdentifierFinder()).build(x509CertificateHolder);
                boolean signatureValid = x509CertificateHolder.isSignatureValid(contentVerifierProvider);
                if (!signatureValid) {
                    return false;
                }
                Certificate certificate = new CertificateFactory().engineGenerateCertificate((InputStream)new ByteArrayInputStream(x509CertificateHolder.getEncoded()));
                if (certificate == null || certificate.getPublicKey() == null) {
                    return false;
                }
                if (!(certificate instanceof X509Certificate)) {
                    return false;
                }
                ((X509Certificate)certificate).checkValidity(new Date());
                return true;
            }
            catch (Throwable t) {
                logger.error("Error validating certificate.", t);
                return false;
            }
        }

        /*
         * WARNING - Removed try catching itself - possible behaviour change.
         */
        public static boolean verifySignature(byte[] signatureBytes, RSAKeyParameters publicKey) {
            ASN1InputStream asn1InputStream = null;
            try {
                asn1InputStream = new ASN1InputStream((InputStream)new ByteArrayInputStream(signatureBytes));
                ASN1Primitive signatureASN = asn1InputStream.readObject();
                BERSequence seq = (BERSequence)ASN1Sequence.getInstance((Object)signatureASN);
                ContentInfo contentInfo = ContentInfo.getInstance((Object)seq);
                SignedData newSignedData = SignedData.getInstance((Object)contentInfo.getContent());
                ByteArrayInputStream newSigIn = new ByteArrayInputStream(newSignedData.getCertificates().parser().readObject().toASN1Primitive().getEncoded());
                CertificateFactory certFactory = new CertificateFactory();
                Certificate certificate = certFactory.engineGenerateCertificate((InputStream)newSigIn);
                BCRSAPublicKey publicKey2 = (BCRSAPublicKey)certificate.getPublicKey();
                if (!(publicKey == null || publicKey.getModulus().equals(publicKey2.getModulus()) && publicKey.getExponent().equals(publicKey2.getPublicExponent()))) {
                    boolean bl = false;
                    return bl;
                }
                certificate.verify((PublicKey)publicKey2);
                boolean bl = true;
                return bl;
            }
            catch (Throwable t) {
                logger.error("Error validating certificate.", t);
                boolean bl = false;
                return bl;
            }
            finally {
                if (asn1InputStream != null) {
                    try {
                        asn1InputStream.close();
                    }
                    catch (IOException e) {
                        logger.error("Error closing stream during RSA.", (Throwable)e);
                    }
                }
            }
        }

        static {
            CryptoX509.addProvider();
        }

        public static class SelfSigned {
            public static X509Certificate generateCert(KeyFactory factory, Date startDate, Date endDate, String subject, String friendlyName, RSAKeyParameters publicKey, RSAPrivateCrtKeyParameters privateKey) {
                String signatureAlgorithm = "SHA1withRSA";
                AlgorithmIdentifier sigAlgId = new DefaultSignatureAlgorithmIdentifierFinder().find(signatureAlgorithm);
                AlgorithmIdentifier digAlgId = new DefaultDigestAlgorithmIdentifierFinder().find(sigAlgId);
                try {
                    PublicKey jcePublicKey = RSA.convertToJCE(factory, publicKey);
                    SubjectPublicKeyInfo subjectPublicKeyInfo = RSA.createSubjectPublicKey(jcePublicKey);
                    X509v3CertificateBuilder certBuilder = new X509v3CertificateBuilder(new X500Name(subject), BigInteger.valueOf(System.currentTimeMillis()), startDate, endDate, new X500Name(subject), subjectPublicKeyInfo);
                    JcaX509ExtensionUtils jcaX509ExtensionUtils = new JcaX509ExtensionUtils();
                    SubjectKeyIdentifier createSubjectKeyIdentifier = jcaX509ExtensionUtils.createSubjectKeyIdentifier(subjectPublicKeyInfo);
                    certBuilder.addExtension(Extension.subjectKeyIdentifier, false, (ASN1Encodable)createSubjectKeyIdentifier);
                    certBuilder.addExtension(Extension.basicConstraints, true, (ASN1Encodable)new BasicConstraints(false));
                    ContentSigner hashSigner = new BcRSAContentSignerBuilder(sigAlgId, digAlgId).build((AsymmetricKeyParameter)privateKey);
                    X509CertificateHolder certHolder = certBuilder.build(hashSigner);
                    Certificate certificate = new CertificateFactory().engineGenerateCertificate((InputStream)new ByteArrayInputStream(certHolder.getEncoded()));
                    if (!(certificate instanceof X509Certificate)) {
                        logger.error("Error generating certificate, it's the wrong type.");
                        return null;
                    }
                    certificate.verify(jcePublicKey);
                    if (certificate instanceof PKCS12BagAttributeCarrier) {
                        PKCS12BagAttributeCarrier bagAttr = (PKCS12BagAttributeCarrier)certificate;
                        bagAttr.setBagAttribute(PKCSObjectIdentifiers.pkcs_9_at_friendlyName, (ASN1Encodable)new DERBMPString(friendlyName));
                    }
                    return (X509Certificate)certificate;
                }
                catch (Exception e) {
                    logger.error("Error generating certificate.", (Throwable)e);
                    return null;
                }
            }
        }

        public static class CertificateAuthrority {
            public static X509Certificate generateCert(KeyFactory factory, Date startDate, Date endDate, String subject, String friendlyName, RSAKeyParameters publicKey, RSAPrivateCrtKeyParameters privateKey) {
                String signatureAlgorithm = "SHA1withRSA";
                AlgorithmIdentifier sigAlgId = new DefaultSignatureAlgorithmIdentifierFinder().find(signatureAlgorithm);
                AlgorithmIdentifier digAlgId = new DefaultDigestAlgorithmIdentifierFinder().find(sigAlgId);
                try {
                    PublicKey jcePublicKey = RSA.convertToJCE(factory, publicKey);
                    SubjectPublicKeyInfo subjectPublicKeyInfo = RSA.createSubjectPublicKey(jcePublicKey);
                    X509v3CertificateBuilder certBuilder = new X509v3CertificateBuilder(new X500Name(subject), BigInteger.valueOf(System.currentTimeMillis()), startDate, endDate, new X500Name(subject), subjectPublicKeyInfo);
                    JcaX509ExtensionUtils jcaX509ExtensionUtils = new JcaX509ExtensionUtils();
                    SubjectKeyIdentifier createSubjectKeyIdentifier = jcaX509ExtensionUtils.createSubjectKeyIdentifier(subjectPublicKeyInfo);
                    certBuilder.addExtension(Extension.subjectKeyIdentifier, false, (ASN1Encodable)createSubjectKeyIdentifier);
                    certBuilder.addExtension(Extension.basicConstraints, true, (ASN1Encodable)new BasicConstraints(1));
                    ContentSigner hashSigner = new BcRSAContentSignerBuilder(sigAlgId, digAlgId).build((AsymmetricKeyParameter)privateKey);
                    X509CertificateHolder certHolder = certBuilder.build(hashSigner);
                    Certificate certificate = new CertificateFactory().engineGenerateCertificate((InputStream)new ByteArrayInputStream(certHolder.getEncoded()));
                    if (!(certificate instanceof X509Certificate)) {
                        logger.error("Error generating certificate, it's the wrong type.");
                        return null;
                    }
                    certificate.verify(jcePublicKey);
                    if (certificate instanceof PKCS12BagAttributeCarrier) {
                        PKCS12BagAttributeCarrier bagAttr = (PKCS12BagAttributeCarrier)certificate;
                        bagAttr.setBagAttribute(PKCSObjectIdentifiers.pkcs_9_at_friendlyName, (ASN1Encodable)new DERBMPString(friendlyName));
                    }
                    return (X509Certificate)certificate;
                }
                catch (Exception e) {
                    logger.error("Error generating certificate.", (Throwable)e);
                    return null;
                }
            }
        }
    }

    public static class DSA {
        public static X509CertificateHolder createCertHolder(Date startDate, Date expiryDate, X500Name issuerName, X500Name subjectName, BigInteger serialNumber, DSAPrivateKeyParameters privateKey, DSAPublicKeyParameters publicKey) {
            ContentSigner build;
            SubjectPublicKeyInfo subjectPublicKeyInfo;
            String signatureAlgorithm = "SHA1withDSA";
            AlgorithmIdentifier sigAlgId = new DefaultSignatureAlgorithmIdentifierFinder().find(signatureAlgorithm);
            AlgorithmIdentifier digAlgId = new DefaultDigestAlgorithmIdentifierFinder().find(sigAlgId);
            DSAParameters parameters = publicKey.getParameters();
            try {
                byte[] encoded = new SubjectPublicKeyInfo(new AlgorithmIdentifier(X9ObjectIdentifiers.id_dsa, (ASN1Encodable)new DSAParameter(parameters.getP(), parameters.getQ(), parameters.getG())), (ASN1Encodable)new ASN1Integer(publicKey.getY())).getEncoded("DER");
                ASN1Sequence seq = (ASN1Sequence)ASN1Primitive.fromByteArray((byte[])encoded);
                subjectPublicKeyInfo = SubjectPublicKeyInfo.getInstance((Object)seq);
            }
            catch (IOException e) {
                logger.error("Error during DSA.", (Throwable)e);
                return null;
            }
            X509v3CertificateBuilder v3CertBuilder = new X509v3CertificateBuilder(issuerName, serialNumber, startDate, expiryDate, subjectName, subjectPublicKeyInfo);
            BcDSAContentSignerBuilder contentSignerBuilder = new BcDSAContentSignerBuilder(sigAlgId, digAlgId);
            try {
                build = contentSignerBuilder.build((AsymmetricKeyParameter)privateKey);
            }
            catch (OperatorCreationException e) {
                logger.error("Error creating certificate.", (Throwable)e);
                return null;
            }
            return v3CertBuilder.build(build);
        }

        public static boolean validate(X509CertificateHolder x509CertificateHolder) {
            try {
                ContentVerifierProvider contentVerifierProvider = new BcDSAContentVerifierProviderBuilder((DigestAlgorithmIdentifierFinder)new DefaultDigestAlgorithmIdentifierFinder()).build(x509CertificateHolder);
                boolean signatureValid = x509CertificateHolder.isSignatureValid(contentVerifierProvider);
                if (!signatureValid) {
                    return false;
                }
                CertificateFactory certificateFactory = new CertificateFactory();
                Certificate certificate = certificateFactory.engineGenerateCertificate((InputStream)new ByteArrayInputStream(x509CertificateHolder.getEncoded()));
                if (certificate == null || certificate.getPublicKey() == null) {
                    return false;
                }
                ((X509Certificate)certificate).checkValidity(new Date());
                return true;
            }
            catch (Throwable t) {
                throw new RuntimeException(t);
            }
        }

        /*
         * WARNING - Removed try catching itself - possible behaviour change.
         */
        public static boolean verifySignature(byte[] signatureBytes, DSAPublicKeyParameters optionalOriginalPublicKey) {
            ASN1InputStream asn1InputStream = null;
            try {
                asn1InputStream = new ASN1InputStream((InputStream)new ByteArrayInputStream(signatureBytes));
                ASN1Primitive signatureASN = asn1InputStream.readObject();
                BERSequence seq = (BERSequence)ASN1Sequence.getInstance((Object)signatureASN);
                ContentInfo contentInfo = ContentInfo.getInstance((Object)seq);
                SignedData newSignedData = SignedData.getInstance((Object)contentInfo.getContent());
                ByteArrayInputStream newSigIn = new ByteArrayInputStream(newSignedData.getCertificates().parser().readObject().toASN1Primitive().getEncoded());
                CertificateFactory certificateFactory = new CertificateFactory();
                Certificate engineGenerateCert = certificateFactory.engineGenerateCertificate((InputStream)newSigIn);
                BCDSAPublicKey publicKey2 = (BCDSAPublicKey)engineGenerateCert.getPublicKey();
                if (optionalOriginalPublicKey != null) {
                    DSAParams params = publicKey2.getParams();
                    DSAParameters parameters = optionalOriginalPublicKey.getParameters();
                    if (!(publicKey2.getY().equals(optionalOriginalPublicKey.getY()) && params.getP().equals(parameters.getP()) && params.getQ().equals(parameters.getQ()) && params.getG().equals(parameters.getG()))) {
                        boolean bl = false;
                        return bl;
                    }
                }
                engineGenerateCert.verify((PublicKey)publicKey2);
                boolean bl = true;
                return bl;
            }
            catch (Throwable t) {
                boolean bl = false;
                return bl;
            }
            finally {
                if (asn1InputStream != null) {
                    try {
                        asn1InputStream.close();
                    }
                    catch (IOException e) {
                        logger.error("Error closing stream during DSA.", (Throwable)e);
                    }
                }
            }
        }

        static {
            CryptoX509.addProvider();
        }
    }

    public static class Util {
        /*
         * WARNING - Removed try catching itself - possible behaviour change.
         */
        public static boolean convertToPemFile(X509Certificate x509cert, String fileName) {
            boolean failed = false;
            Writer output = null;
            try {
                String lineSeparator = "\r\n";
                String cert_begin = "-----BEGIN CERTIFICATE-----";
                String cert_end = "-----END CERTIFICATE-----";
                byte[] derCert = Base64.getMimeEncoder().encode(x509cert.getEncoded());
                char[] encodeToChar = new char[derCert.length];
                for (int i = 0; i < derCert.length; ++i) {
                    encodeToChar[i] = (char)derCert[i];
                }
                int newLineCount = encodeToChar.length / 64;
                int length = encodeToChar.length;
                output = new BufferedWriter(new FileWriter(fileName, false), cert_begin.length() + cert_end.length() + length + newLineCount + 3);
                output.write(cert_begin);
                output.write(lineSeparator);
                int copyCount = 64;
                for (int i = 0; i < length; i += 64) {
                    if (i + 64 > length) {
                        copyCount = length - i;
                    }
                    output.write(encodeToChar, i, copyCount);
                    output.write(lineSeparator);
                }
                output.write(cert_end);
                output.write(lineSeparator);
            }
            catch (Exception e) {
                logger.error("Error during conversion.", (Throwable)e);
                failed = true;
            }
            finally {
                if (output != null) {
                    try {
                        output.close();
                    }
                    catch (IOException e) {
                        logger.error("Error closing resource.", (Throwable)e);
                    }
                }
            }
            return !failed;
        }

        public static String convertToPem(X509Certificate x509cert) throws CertificateEncodingException {
            String lineSeparator = "\r\n";
            String cert_begin = "-----BEGIN CERTIFICATE-----";
            String cert_end = "-----END CERTIFICATE-----";
            byte[] derCert = Base64.getMimeEncoder().encode(x509cert.getEncoded());
            char[] encodeToChar = new char[derCert.length];
            for (int i = 0; i < derCert.length; ++i) {
                encodeToChar[i] = (char)derCert[i];
            }
            int newLineCount = encodeToChar.length / 64;
            int length = encodeToChar.length;
            int lastIndex = 0;
            StringBuilder sb = new StringBuilder(cert_begin.length() + cert_end.length() + length + newLineCount + 2);
            sb.append(cert_begin);
            sb.append(lineSeparator);
            for (int i = 64; i < length; i += 64) {
                sb.append(encodeToChar, lastIndex, i);
                sb.append(lineSeparator);
                lastIndex = i;
            }
            sb.append(cert_end);
            return sb.toString();
        }

        public static String getDigestNameFromCert(X509CertificateHolder x509CertificateHolder) {
            return Util.getDigestNameFromSigAlgId(x509CertificateHolder.getSignatureAlgorithm().getAlgorithm());
        }

        public static String getDigestNameFromSigAlgId(ASN1ObjectIdentifier algorithm) {
            String digest = null;
            try {
                DefaultCMSSignatureAlgorithmNameGenerator defaultCMSSignatureAlgorithmNameGenerator = new DefaultCMSSignatureAlgorithmNameGenerator();
                Method declaredMethod = DefaultCMSSignatureAlgorithmNameGenerator.class.getDeclaredMethod("getDigestAlgName", ASN1ObjectIdentifier.class);
                declaredMethod.setAccessible(true);
                digest = (String)declaredMethod.invoke((Object)defaultCMSSignatureAlgorithmNameGenerator, algorithm);
            }
            catch (Throwable t) {
                throw new RuntimeException("Weird error using reflection to get the digest name: " + algorithm.getId() + t.getMessage());
            }
            if (algorithm.getId().equals(digest)) {
                throw new RuntimeException("Unable to get digest name from algorithm ID: " + algorithm.getId());
            }
            return digest;
        }

        public static boolean isTrusted(X509Certificate cert, X509Certificate[] trustedCaCerts) {
            int i;
            for (i = 0; i < trustedCaCerts.length; ++i) {
                if (!cert.getSubjectDN().equals(trustedCaCerts[i].getSubjectDN()) || !cert.equals(trustedCaCerts[i])) continue;
                return true;
            }
            for (i = 0; i < trustedCaCerts.length; ++i) {
                if (!cert.getIssuerDN().equals(trustedCaCerts[i].getSubjectDN())) continue;
                try {
                    cert.verify(trustedCaCerts[i].getPublicKey());
                    return true;
                }
                catch (Exception exception) {
                    // empty catch block
                }
            }
            return false;
        }
    }
}

