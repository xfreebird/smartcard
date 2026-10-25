/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.util.gwt;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.Charset;
import java.util.HashMap;
import java.util.Map;

public class GwtSymbolMapParser {
    private static final Charset UTF_8 = Charset.forName("UTF-8");
    private final Map<String, String> symbolMap = new HashMap<String, String>();

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public void parse(InputStream inputStream) {
        if (inputStream == null) {
            return;
        }
        InputStreamReader in = new InputStreamReader(inputStream, UTF_8);
        StringBuilder builder = new StringBuilder(1024);
        int charRead = 13;
        char CHAR = (char)charRead;
        try {
            while ((charRead = in.read()) != -1) {
                CHAR = (char)charRead;
                if (CHAR != '\r' && CHAR != '\n') {
                    builder.append(CHAR);
                    continue;
                }
                this.processLine(builder.toString());
                builder.delete(0, builder.capacity());
            }
        }
        catch (IOException iOException) {
        }
        finally {
            try {
                in.close();
            }
            catch (IOException iOException) {}
        }
    }

    public Map<String, String> getSymbolMap() {
        return this.symbolMap;
    }

    public void processLine(String line) {
        if (line.charAt(0) == '#') {
            return;
        }
        String[] symbolInfo = line.split(",");
        if (symbolInfo.length > 2) {
            String jsName = symbolInfo[0];
            String className = symbolInfo[2];
            String memberName = symbolInfo[3];
            if (memberName.isEmpty() && !jsName.equals(className)) {
                this.symbolMap.put(jsName, className);
            }
        } else {
            this.symbolMap.put(symbolInfo[0], symbolInfo[1]);
        }
    }
}

