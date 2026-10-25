/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.itextpdf.kernel.pdf.PdfDictionary
 *  com.itextpdf.kernel.pdf.PdfDocument
 *  com.itextpdf.kernel.pdf.PdfIndirectReference
 *  com.itextpdf.kernel.pdf.PdfName
 *  com.itextpdf.kernel.pdf.PdfObject
 *  com.itextpdf.kernel.pdf.PdfReader
 *  com.itextpdf.signatures.PdfPKCS7
 *  com.itextpdf.signatures.SignatureUtil
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.ghesar;

import com.itextpdf.kernel.pdf.PdfDictionary;
import com.itextpdf.kernel.pdf.PdfDocument;
import com.itextpdf.kernel.pdf.PdfIndirectReference;
import com.itextpdf.kernel.pdf.PdfName;
import com.itextpdf.kernel.pdf.PdfObject;
import com.itextpdf.kernel.pdf.PdfReader;
import com.itextpdf.signatures.PdfPKCS7;
import com.itextpdf.signatures.SignatureUtil;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import md.cts.moldsign.ghesar.SigInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class PdfFile {
    private static final Logger logger = LoggerFactory.getLogger(PdfFile.class);
    public final List<SigInfo> signList = new ArrayList<SigInfo>();
    private String fileName;
    private List<String> signatureNames;
    private PdfReader reader;
    private PdfDocument pdfDoc;
    private SignatureUtil signUtil;

    public InputStream extractRevision(String signatureName) {
        return this.signUtil.extractRevision(signatureName);
    }

    public boolean hasSignature() {
        return this.signatureNames != null && !this.signatureNames.isEmpty();
    }

    public String getFileName() {
        File f = new File(this.fileName);
        return f.getName();
    }

    public boolean open(String fileName) throws IOException {
        this.fileName = fileName;
        this.reader = new PdfReader(fileName);
        this.pdfDoc = new PdfDocument(this.reader);
        this.signUtil = new SignatureUtil(this.pdfDoc);
        this.signatureNames = this.signUtil.getSignatureNames();
        if (!this.signatureNames.isEmpty()) {
            for (String signatureName : this.signatureNames) {
                PdfPKCS7 pkcs7 = this.signUtil.readSignatureData(signatureName);
                boolean whole = this.signUtil.signatureCoversWholeDocument(signatureName);
                SigInfo sig = new SigInfo(signatureName, pkcs7, whole);
                sig.parse();
                this.signList.add(sig);
            }
        }
        return true;
    }

    public void close() {
        if (this.pdfDoc != null) {
            this.pdfDoc.close();
        }
        if (this.reader != null) {
            try {
                this.reader.close();
            }
            catch (IOException ex) {
                logger.error("", (Throwable)ex);
            }
        }
        this.fileName = null;
        this.signUtil = null;
        this.pdfDoc = null;
        this.reader = null;
        this.signatureNames = null;
        this.signList.clear();
    }

    public boolean getLastSigWhole() {
        boolean whole = false;
        int last = this.signList.size() - 1;
        if (last >= 0) {
            SigInfo sig = this.signList.get(last);
            whole = sig.whole;
        }
        return whole;
    }

    public boolean checkAux() {
        if (this.signatureNames.isEmpty()) {
            return false;
        }
        ArrayList<Integer> full = new ArrayList<Integer>();
        List listIndirectReferences = this.pdfDoc.listIndirectReferences();
        for (PdfIndirectReference x : listIndirectReferences) {
            full.add(x.getObjNumber());
        }
        ArrayList<Integer> last = new ArrayList<Integer>();
        String lastSigName = this.signatureNames.get(this.signatureNames.size() - 1);
        InputStream lastInput = this.signUtil.extractRevision(lastSigName);
        try (PdfReader reader2 = new PdfReader(lastInput);
             PdfDocument pdfDoc2 = new PdfDocument(reader2);){
            List listIndirectReferences2 = pdfDoc2.listIndirectReferences();
            for (PdfIndirectReference x : listIndirectReferences2) {
                last.add(x.getObjNumber());
            }
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
            return false;
        }
        full.removeAll(last);
        boolean result = true;
        Iterator iterator = full.iterator();
        block14: while (iterator.hasNext()) {
            PdfDictionary dict;
            int n = (Integer)iterator.next();
            PdfObject pdfObj = this.pdfDoc.getPdfObject(n);
            if (pdfObj.isArray()) continue;
            if (pdfObj.isStream()) {
                if (pdfObj instanceof PdfDictionary) {
                    dict = (PdfDictionary)pdfObj;
                    PdfObject v = dict.get(PdfName.Type);
                    if (PdfName.XRef.equals((Object)v) || PdfName.ObjStm.equals((Object)v)) continue;
                    for (PdfName k : dict.keySet()) {
                        if (PdfName.Filter.equals((Object)k) || PdfName.Length.equals((Object)k)) continue;
                        result = false;
                        continue block14;
                    }
                    continue;
                }
                result = false;
                continue;
            }
            if (pdfObj.isDictionary()) {
                if (pdfObj instanceof PdfDictionary) {
                    dict = (PdfDictionary)pdfObj;
                    for (PdfName k : dict.keySet()) {
                        if (PdfName.CRL.equals((Object)k) || PdfName.CRLs.equals((Object)k) || PdfName.VRI.equals((Object)k) || k.getValue().length() == 40) continue;
                        result = false;
                        continue block14;
                    }
                    continue;
                }
                result = false;
                continue;
            }
            result = false;
        }
        return result;
    }
}

