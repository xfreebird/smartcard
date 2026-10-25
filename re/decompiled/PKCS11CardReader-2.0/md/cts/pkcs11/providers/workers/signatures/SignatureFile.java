/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.xml.crypto.XSecProvider
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.providers.workers.signatures;

import iaik.xml.crypto.XSecProvider;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import md.cts.pkcs11.providers.workers.signatures.SignatureInstance;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.w3c.dom.DOMException;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

public final class SignatureFile {
    private static final Logger logger = LoggerFactory.getLogger(SignatureFile.class);
    private final File signatureFile;
    private Document doc;

    public SignatureFile(File signatureFile) throws OperationFailedException {
        this.signatureFile = signatureFile;
        this.getDocument();
    }

    public SignatureFile() throws OperationFailedException {
        this(null);
    }

    public Document getDocument() throws OperationFailedException {
        if (this.doc != null) {
            return this.doc;
        }
        logger.info("build Document");
        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        dbf.setNamespaceAware(true);
        dbf.setAttribute("http://xml.org/sax/features/namespaces", Boolean.TRUE);
        FileInputStream fis = null;
        try {
            if (this.signatureFile != null) {
                fis = new FileInputStream(this.signatureFile);
                this.doc = dbf.newDocumentBuilder().parse(fis);
                fis.close();
            } else {
                this.doc = dbf.newDocumentBuilder().newDocument();
            }
        }
        catch (SAXException ex) {
            logger.error("Error reading file. Problem with XML data{}", (Object)this.signatureFile, (Object)ex);
            throw new OperationFailedException(ex);
        }
        catch (FileNotFoundException ex) {
            logger.error("Error reading file. The file doesn't seem to exist{}", (Object)this.signatureFile, (Object)ex);
            throw new OperationFailedException("exception.general.file_not_found", ex);
        }
        catch (IOException ex) {
            logger.error("Error reading file.{}", (Object)this.signatureFile, (Object)ex);
            throw new OperationFailedException("exception.general.io_exception", ex);
        }
        catch (ParserConfigurationException ex) {
            logger.error("Error in XAdES parser configuration", (Throwable)ex);
            throw new OperationFailedException("exception.signature.xades_parsing_exception", ex);
        }
        finally {
            try {
                if (fis != null) {
                    fis.close();
                }
            }
            catch (Exception ex) {
                logger.error("", (Throwable)ex);
            }
        }
        if (this.doc != null && this.doc.getDocumentElement() != null) {
            this.recursiveSetId(this.doc.getDocumentElement(), "Id");
        }
        return this.doc;
    }

    private void recursiveSetId(Element el, String idString) {
        if (el.hasAttribute(idString)) {
            el.setIdAttribute(idString, true);
        }
        NodeList nodeList = el.getChildNodes();
        for (int i = 0; i < nodeList.getLength(); ++i) {
            Node n = nodeList.item(i);
            if (!(n instanceof Element)) continue;
            this.recursiveSetId((Element)n, idString);
        }
    }

    public Node getContainerNode() throws OperationFailedException {
        this.getDocument();
        Element docElement = this.doc.getDocumentElement();
        if (docElement == null) {
            return this.doc;
        }
        NodeList nl = this.doc.getElementsByTagNameNS("http://www.w3.org/2000/09/xmldsig#", "Signature");
        for (int i = 0; i < nl.getLength(); ++i) {
            Node node = nl.item(i);
            if (!(node instanceof Element)) continue;
            Element signatureElement = (Element)node;
            if (signatureElement.getParentNode().equals(docElement)) {
                return docElement;
            }
            if (!signatureElement.getParentNode().equals(this.doc)) continue;
            Element newElement = this.doc.createElement("SignatureHolder");
            this.doc.removeChild(signatureElement);
            newElement.appendChild(signatureElement);
            this.doc.appendChild(newElement);
            return newElement;
        }
        return null;
    }

    public void writeToFile(File f) throws OperationFailedException {
        FileOutputStream os;
        try {
            os = new FileOutputStream(f);
        }
        catch (FileNotFoundException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.general.io_exception_write", ex);
        }
        TransformerFactory tf = TransformerFactory.newInstance();
        try {
            Transformer trans = tf.newTransformer();
            trans.transform(new DOMSource(this.getDocument()), new StreamResult(os));
        }
        catch (TransformerException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException(ex);
        }
        finally {
            try {
                os.flush();
                ((OutputStream)os).close();
            }
            catch (IOException ex) {
                logger.error("", (Throwable)ex);
            }
        }
    }

    public SignatureInstance createNewSignature(XSecProvider xSecProvider) {
        return new SignatureInstance(xSecProvider, this);
    }

    public Node getSignatureContainingNode(String id) {
        NodeList nl = this.doc.getElementsByTagNameNS("http://www.w3.org/2000/09/xmldsig#", "Signature");
        for (int i = 0; i < nl.getLength(); ++i) {
            Element signatureElement;
            Node node = nl.item(i);
            if (!(node instanceof Element) || !(signatureElement = (Element)node).getAttribute("Id").equals(id)) continue;
            return signatureElement;
        }
        logger.info("SignatureContainingNode not found");
        return null;
    }

    public SignatureInstance getSignatureByID(XSecProvider xSecProvider, String id) throws OperationFailedException {
        Node node = this.getSignatureContainingNode(id);
        if (node == null) {
            return null;
        }
        return new SignatureInstance(xSecProvider, node, this);
    }

    public List<SignatureInstance> getTopLevelSignatures(XSecProvider xSecProvider) throws OperationFailedException {
        ArrayList<SignatureInstance> topLevelSignatures = new ArrayList<SignatureInstance>();
        Element docElement = this.doc.getDocumentElement();
        NodeList nl = this.doc.getElementsByTagNameNS("http://www.w3.org/2000/09/xmldsig#", "Signature");
        for (int i = 0; i < nl.getLength(); ++i) {
            Element signatureElement;
            Node node = nl.item(i);
            if (!(node instanceof Element) || !(signatureElement = (Element)node).getParentNode().equals(this.doc) && !signatureElement.getParentNode().equals(docElement)) continue;
            topLevelSignatures.add(new SignatureInstance(xSecProvider, signatureElement, this));
        }
        return topLevelSignatures;
    }

    public void deleteSignature(String signatureReference) throws OperationFailedException {
        Element parentElement;
        Node node = this.getSignatureContainingNode(signatureReference);
        if (node == null) {
            return;
        }
        Node parent = node.getParentNode();
        if (parent instanceof Element && (parentElement = (Element)parent).getNodeName().endsWith("CounterSignature")) {
            parent = parentElement.getParentNode();
            node = parentElement;
        }
        try {
            parent.removeChild(node);
        }
        catch (DOMException ex) {
            throw new OperationFailedException(ex);
        }
    }

    public String getDataForId(String id) {
        Element el = this.doc.getElementById(id);
        return el.getFirstChild().getNodeValue();
    }
}

