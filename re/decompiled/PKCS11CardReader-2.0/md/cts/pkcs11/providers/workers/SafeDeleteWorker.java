/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.cts.moldsign.transferobjects.models.SafeDeleteResponseModel
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.providers.workers;

import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.channels.FileLock;
import java.util.Iterator;
import java.util.LinkedList;
import md.cts.moldsign.transferobjects.models.SafeDeleteResponseModel;
import md.cts.pkcs11.cards.exceptions.InvalidPinException;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import md.cts.pkcs11.providers.workers.AbstractWork;
import md.cts.pkcs11.providers.workers.safedeletealgorythms.DoD3Algorithm;
import md.cts.pkcs11.providers.workers.safedeletealgorythms.DoD7Algorithm;
import md.cts.pkcs11.providers.workers.safedeletealgorythms.PeterGutmannAlgorithm;
import md.cts.pkcs11.providers.workers.safedeletealgorythms.PseudoRandomNumberAlgorithm;
import md.cts.pkcs11.providers.workers.safedeletealgorythms.ShreadAlgorythm;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class SafeDeleteWorker
extends AbstractWork<SafeDeleteResponseModel> {
    private static final Logger logger = LoggerFactory.getLogger(SafeDeleteWorker.class);
    private final String file;
    private final String algorithm;
    private int nrRetries;

    public SafeDeleteWorker(String file, String algorithm, int nrRetries) {
        this.file = file;
        this.algorithm = algorithm;
        this.nrRetries = nrRetries;
    }

    @Override
    public SafeDeleteResponseModel call() throws OperationFailedException, InvalidPinException {
        File f = new File(this.file);
        boolean deleted = false;
        if (f.exists()) {
            logger.info("Safe delete operationg started. File selected.");
            ShreadAlgorythm ah = null;
            if ("PeterGutmann".equals(this.algorithm)) {
                ah = new PeterGutmannAlgorithm();
            }
            if ("DoD3".equals(this.algorithm)) {
                ah = new DoD3Algorithm();
            }
            if ("DoD7".equals(this.algorithm)) {
                ah = new DoD7Algorithm();
            }
            if ("PseudoRandomNumber".equals(this.algorithm)) {
                if (this.nrRetries == 0) {
                    this.nrRetries = 10;
                }
                ah = new PseudoRandomNumberAlgorithm(this.nrRetries);
            }
            if (ah == null) {
                throw new OperationFailedException("unknown algorithm", new Exception("unknown algorithm"));
            }
            this.runAlgorithm(ah.getSeqList());
            for (int i = 0; i < 10; ++i) {
                if (f.delete()) {
                    logger.info("File successfully deleted.");
                    deleted = true;
                    break;
                }
                try {
                    Thread.sleep(500L);
                    continue;
                }
                catch (InterruptedException ex) {
                    logger.error("sleep", (Throwable)ex);
                }
            }
            if (!deleted) {
                logger.error("Cannot delete file {}", (Object)this.file);
                throw new OperationFailedException("exception.delete.unsuccessful", new Exception("Cannot delete file " + this.file));
            }
        } else {
            throw new OperationFailedException("exception.delete.unsuccessful", new Exception("Cannot delete file"));
        }
        return new SafeDeleteResponseModel(this.file);
    }

    private void runAlgorithm(LinkedList<byte[]> generatedBytes) throws OperationFailedException {
        Iterator iterator = generatedBytes.iterator();
        if (iterator.hasNext()) {
            byte[] overideBytes = (byte[])iterator.next();
            this.rewriteOnce(this.file, overideBytes);
        }
        System.gc();
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    private void rewriteOnce(String file, byte[] bytes) throws OperationFailedException {
        RandomAccessFile rwFile = null;
        FileChannel rwChannel = null;
        FileLock lock = null;
        try {
            rwFile = new RandomAccessFile(file, "rw");
            rwChannel = rwFile.getChannel();
            lock = rwChannel.lock();
            int nbrBytes = bytes.length;
            rwChannel.position(0L);
            while (rwChannel.position() < rwChannel.size()) {
                MappedByteBuffer buffer = rwChannel.map(FileChannel.MapMode.READ_WRITE, rwChannel.position(), nbrBytes);
                ((ByteBuffer)buffer).clear();
                buffer.put(bytes);
                rwChannel.write(buffer);
                rwChannel.force(false);
                rwChannel.position(rwChannel.position() + (long)nbrBytes);
            }
        }
        catch (IOException ex) {
            logger.error("rewriteOnce", (Throwable)ex);
        }
        finally {
            try {
                lock.release();
            }
            catch (Exception ex) {
                logger.info("Cannot release channel");
            }
            try {
                rwChannel.close();
            }
            catch (Exception ex) {
                logger.info("Cannot close channel");
            }
            try {
                rwFile.close();
            }
            catch (Exception ex) {
                logger.info("Cannot close rw file");
            }
        }
    }
}

