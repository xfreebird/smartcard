/*
 * Decompiled with CFR 0.152.
 */
package ghesar;

public final class DNParser {
    private static final String ERROR_PARSE_ERROR = "Failed to parse DN";
    private final char[] chars;
    private int pos;

    public DNParser(String dn) {
        this.chars = dn.toCharArray();
    }

    public String get(String attribute) {
        try {
            return this.find(attribute);
        }
        catch (Exception e) {
            return null;
        }
    }

    private String find(String attribute) throws Exception {
        if (attribute == null) {
            return null;
        }
        this.pos = 0;
        while (true) {
            if (this.pos < this.chars.length && this.chars[this.pos] == ' ') {
                ++this.pos;
                continue;
            }
            if (this.pos >= this.chars.length) {
                return null;
            }
            String attType = this.nextAT();
            while (this.pos < this.chars.length && this.chars[this.pos] == ' ') {
                ++this.pos;
            }
            if (this.pos >= this.chars.length) {
                if (attribute.equals(attType)) {
                    return "";
                }
                return null;
            }
            String attValue = this.chars[this.pos] == '\"' ? this.quotedAV() : this.escapedAV();
            if (attribute.equals(attType)) {
                return attValue;
            }
            while (this.pos < this.chars.length && this.chars[this.pos] == ' ') {
                ++this.pos;
            }
            if (this.pos >= this.chars.length) {
                return null;
            }
            if (this.chars[this.pos] != ',' && this.chars[this.pos] != ';') break;
            ++this.pos;
        }
        throw new Exception(ERROR_PARSE_ERROR);
    }

    private String nextAT() throws Exception {
        int beg = this.pos;
        while (this.pos < this.chars.length && this.chars[this.pos] != '=' && this.chars[this.pos] != ' ') {
            ++this.pos;
        }
        if (this.pos >= this.chars.length) {
            throw new Exception(ERROR_PARSE_ERROR);
        }
        int end = this.pos;
        if (end == beg) {
            throw new Exception(ERROR_PARSE_ERROR);
        }
        while (this.pos < this.chars.length && this.chars[this.pos] == ' ' && this.chars[this.pos] != '=') {
            ++this.pos;
        }
        if (this.pos >= this.chars.length || this.chars[this.pos] != '=') {
            throw new Exception(ERROR_PARSE_ERROR);
        }
        ++this.pos;
        return new String(this.chars, beg, end - beg);
    }

    private String quotedAV() throws Exception {
        ++this.pos;
        int beg = this.pos;
        while (true) {
            if (this.pos < this.chars.length && this.chars[this.pos] != '\"' && this.chars[this.pos] != '\\') {
                ++this.pos;
                continue;
            }
            if (this.pos >= this.chars.length) {
                throw new Exception(ERROR_PARSE_ERROR);
            }
            if (this.chars[this.pos] == '\"') break;
            if (this.chars[this.pos] != '\\') continue;
            ++this.pos;
            if (this.pos >= this.chars.length) {
                throw new Exception(ERROR_PARSE_ERROR);
            }
            ++this.pos;
        }
        int end = this.pos++;
        return new String(this.chars, beg, end - beg);
    }

    private String escapedAV() throws Exception {
        int beg = this.pos;
        while (this.pos < this.chars.length && this.chars[this.pos] != ',' && this.chars[this.pos] != ';') {
            if (this.chars[this.pos] == '\\') {
                ++this.pos;
                if (this.pos >= this.chars.length) {
                    throw new Exception(ERROR_PARSE_ERROR);
                }
            }
            ++this.pos;
        }
        int end = this.pos;
        return new String(this.chars, beg, end - beg);
    }
}

