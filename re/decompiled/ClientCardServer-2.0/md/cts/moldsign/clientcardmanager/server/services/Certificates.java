/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.cms.EnvelopedData
 *  iaik.cms.RecipientInfo
 *  jakarta.ws.rs.DefaultValue
 *  jakarta.ws.rs.GET
 *  jakarta.ws.rs.OPTIONS
 *  jakarta.ws.rs.POST
 *  jakarta.ws.rs.Path
 *  jakarta.ws.rs.PathParam
 *  jakarta.ws.rs.Produces
 *  jakarta.ws.rs.QueryParam
 *  jakarta.ws.rs.core.Context
 *  jakarta.ws.rs.core.HttpHeaders
 *  jakarta.ws.rs.core.Response
 *  jakarta.ws.rs.core.Response$ResponseBuilder
 *  jakarta.ws.rs.core.Response$Status
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.clientcardmanager.server.services;

import iaik.cms.EnvelopedData;
import iaik.cms.RecipientInfo;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.OPTIONS;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.OpenOption;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import md.cts.cryptography.providers.GlobalCertificateProvider;
import md.cts.moldsign.clientcardmanager.server.AllowedSites;
import md.cts.moldsign.transferobjects.models.CertificateListModel;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Path(value="certificates")
public final class Certificates {
    private static final Logger logger = LoggerFactory.getLogger(Certificates.class);

    @OPTIONS
    public Response getCertificatesOptions() {
        return Response.ok().build();
    }

    @GET
    @Produces(value={"application/xml", "application/json"})
    public Response getCertificates(@Context HttpHeaders headers, @DefaultValue(value="1") @QueryParam(value="private_only") String privateOnlyS, @DefaultValue(value="1") @QueryParam(value="validated") String validOnlyS) {
        Response.ResponseBuilder builder;
        logger.info("getCertificates()");
        String origin = (String)headers.getRequestHeaders().getFirst((Object)"Origin");
        boolean matches = false;
        if (origin != null) {
            List<String> allowedUrlList = AllowedSites.getAllowedUrlList();
            if (allowedUrlList != null) {
                for (String pattern : allowedUrlList) {
                    if (!origin.matches(pattern)) continue;
                    matches = true;
                    break;
                }
            }
        } else {
            String desktopClientHeader = (String)headers.getRequestHeaders().getFirst((Object)"moldSign");
            if ("DesktopSuiteClient".equals(desktopClientHeader)) {
                matches = true;
            }
        }
        if (matches) {
            boolean privateOnly = "1".equals(privateOnlyS) || "true".equalsIgnoreCase(privateOnlyS);
            boolean validOnly = "1".equals(validOnlyS) || "true".equalsIgnoreCase(validOnlyS);
            logger.info("GET Certificates: validOnly: {} privateOnly {}", (Object)validOnly, (Object)privateOnly);
            List<CertificateModel> result = GlobalCertificateProvider.get().getCertificates(privateOnly);
            logger.info("cert to show: {}", (Object)result.size());
            ArrayList<CertificateModel> removeCert = new ArrayList<CertificateModel>();
            for (CertificateModel currentModel : result) {
                if (validOnly && currentModel.getVerified() != 0) {
                    removeCert.add(currentModel);
                    continue;
                }
                currentModel.setCertificateName(currentModel.toString());
            }
            if (!removeCert.isEmpty()) {
                result.removeAll(removeCert);
            }
            logger.info("cert to show remain: {}", (Object)result.size());
            CertificateListModel cm = new CertificateListModel(result);
            builder = Response.ok().entity((Object)cm);
        } else {
            logger.warn("Web site not authorized");
            builder = Response.status((Response.Status)Response.Status.UNAUTHORIZED).header("error", (Object)"Web site not authorized");
        }
        return builder.build();
    }

    @POST
    @Path(value="chain")
    @Produces(value={"application/xml", "application/json"})
    public List<CertificateModel> getChain(CertificateModel model) {
        logger.info("getChain()");
        return GlobalCertificateProvider.get().getCertificateChain(model);
    }

    @GET
    @Path(value="{providerId}")
    @Produces(value={"application/xml", "application/json"})
    public Collection<CertificateModel> getCertificatesForCard(@PathParam(value="providerId") String providerId, @DefaultValue(value="false") @QueryParam(value="privateOnly") String privateOnlyS) {
        logger.info("getCertificatesForCard()");
        boolean privateOnly = "1".equals(privateOnlyS) || "true".equalsIgnoreCase(privateOnlyS);
        return GlobalCertificateProvider.get().getCertificatesForProvider(providerId, privateOnly);
    }

    /*
     * Enabled aggressive block sorting
     * Enabled unnecessary exception pruning
     * Enabled aggressive exception aggregation
     */
    @POST
    @Path(value="fileChecker")
    public Response getFileCertificate(String filePath) {
        logger.info("getFileCertificate()");
        try (InputStream is = Files.newInputStream(Paths.get(filePath, new String[0]), new OpenOption[0]);){
            EnvelopedData ed = new EnvelopedData(is);
            RecipientInfo[] infos = ed.getRecipientInfos();
            List<CertificateModel> availableCertificatesList = GlobalCertificateProvider.get().getCertificates(true);
            CertificateModel currentFileCM = null;
            for (CertificateModel certificate : availableCertificatesList) {
                if ("MSCSP".equals(certificate.getProviderId())) continue;
                for (RecipientInfo recipientInfo : infos) {
                    if (recipientInfo.isRecipientInfoFor(certificate.getCertificate()) == null) continue;
                    currentFileCM = certificate;
                    break;
                }
                if (currentFileCM == null) continue;
            }
            if (currentFileCM == null) {
                for (CertificateModel certificate : availableCertificatesList) {
                    if (!"MSCSP".equals(certificate.getProviderId())) continue;
                    for (RecipientInfo recipientInfo : infos) {
                        if (recipientInfo.isRecipientInfoFor(certificate.getCertificate()) == null) continue;
                        currentFileCM = certificate;
                        break;
                    }
                    if (currentFileCM == null) continue;
                }
            }
            Response response = Response.ok().entity(currentFileCM).build();
            return response;
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
        }
        return Response.status((Response.Status)Response.Status.UNAUTHORIZED).build();
    }

    @POST
    @Path(value="refresh")
    public Response refreshCertificates() {
        logger.info("refreshCertificates()");
        GlobalCertificateProvider.get().refreshProviderCertificates();
        return Response.ok().build();
    }
}

