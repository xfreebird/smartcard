/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.pkcs.pkcs11.objects.ByteArrayAttribute
 */
package md.cts.pkcs11.util;

import iaik.pkcs.pkcs11.objects.ByteArrayAttribute;
import java.io.IOException;
import java.io.OutputStream;
import java.util.Arrays;
import java.util.Base64;
import java.util.HexFormat;

public final class ByteArrayWrapper {
    private byte[] values;

    public ByteArrayWrapper(byte[] values) {
        this.values = values;
    }

    public ByteArrayWrapper(ByteArrayAttribute values) {
        this(values.getByteArrayValue());
    }

    public ByteArrayWrapper(String value, boolean base64) {
        this.values = base64 ? Base64.getDecoder().decode(value) : HexFormat.of().parseHex(value);
    }

    public void reverse() {
        byte[] result = new byte[this.values.length];
        for (int i = this.values.length; i > 0; --i) {
            result[this.values.length - i] = this.values[i - 1];
        }
        this.values = result;
    }

    public boolean equals(Object obj) {
        if (obj == null) {
            return false;
        }
        if (this.getClass() != obj.getClass()) {
            return false;
        }
        ByteArrayWrapper other = (ByteArrayWrapper)obj;
        return Arrays.equals(this.values, other.values);
    }

    public String asBase64() {
        return Base64.getEncoder().encodeToString(this.values);
    }

    public int hashCode() {
        int hash = 5;
        hash = 31 * hash + Arrays.hashCode(this.values);
        return hash;
    }

    public String toString() {
        return HexFormat.of().formatHex(this.values);
    }

    public void store(OutputStream os) throws IOException {
        os.write(this.values);
    }

    public void storeBase64(OutputStream os) throws IOException {
        if (this.asBase64() != null) {
            os.write(this.asBase64().getBytes());
        }
    }
}

