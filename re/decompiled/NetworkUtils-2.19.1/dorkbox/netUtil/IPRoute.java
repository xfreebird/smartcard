/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.Unit
 *  kotlin.io.CloseableKt
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.netUtil;

import dorkbox.netUtil.Common;
import java.io.BufferedWriter;
import java.io.Closeable;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import kotlin.Metadata;
import kotlin.Unit;
import kotlin.io.CloseableKt;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u00000\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010%\n\u0002\u0010\b\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0010\u0002\n\u0002\u0010$\n\u0000\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u001a\u0010\u000b\u001a\u00020\f2\u0012\u0010\u0006\u001a\u000e\u0012\u0004\u0012\u00020\b\u0012\u0004\u0012\u00020\t0\rR\u0012\u0010\u0003\u001a\u00060\u0004j\u0002`\u0005X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u001c\u0010\u0006\u001a\u0010\u0012\u0004\u0012\u00020\b\u0012\u0006\u0012\u0004\u0018\u00010\t0\u0007X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\n\u001a\u00020\tX\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u000e"}, d2={"Ldorkbox/netUtil/IPRoute;", "", "()V", "reservedTable", "Ljava/lang/StringBuilder;", "Lkotlin/text/StringBuilder;", "tableNames", "", "", "", "version", "addRtTables", "", "", "NetworkUtils"})
public final class IPRoute {
    @NotNull
    public static final IPRoute INSTANCE = new IPRoute();
    @NotNull
    public static final String version = "2.19.1";
    @NotNull
    private static final StringBuilder reservedTable = new StringBuilder(2048);
    @NotNull
    private static final Map<Integer, String> tableNames = new HashMap(256);

    private IPRoute() {
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public final void addRtTables(@NotNull Map<Integer, String> tableNames) {
        Intrinsics.checkNotNullParameter(tableNames, (String)"tableNames");
        if (Common.INSTANCE.getOS_LINUX()) {
            block10: for (Map.Entry<Integer, String> object : tableNames.entrySet()) {
                int n = ((Number)object.getKey()).intValue();
                String tableName = object.getValue();
                switch (n) {
                    case 0: 
                    case 253: 
                    case 254: 
                    case 255: {
                        Common.INSTANCE.getLogger$NetworkUtils().error("Trying to add table with same number as reserved value. Skipping.");
                        continue block10;
                    }
                }
                if (!IPRoute.tableNames.containsKey(n)) {
                    Integer n2 = n;
                    IPRoute.tableNames.put(n2, tableName);
                    continue;
                }
                if (Intrinsics.areEqual((Object)IPRoute.tableNames.get(n), (Object)tableName)) continue;
                Common.INSTANCE.getLogger$NetworkUtils().error("Trying to add table with the same number as another table. Skipping");
            }
            StringBuilder table = new StringBuilder(2048);
            for (Map.Entry<Integer, String> entry : IPRoute.tableNames.entrySet()) {
                int tableNumber2 = ((Number)entry.getKey()).intValue();
                String tableName = entry.getValue();
                table.append(tableNumber2).append("  ").append(tableName).append("\n");
            }
            File file = new File("/etc/iproute2/rt_tables").getAbsoluteFile();
            if (!file.canRead()) {
                throw new IOException("Unable to initialize policy routing tables. Something is SERIOUSLY wrong, aborting startup!");
            }
            try {
                Closeable closeable = new BufferedWriter(new FileWriter(file));
                Throwable throwable = null;
                try {
                    BufferedWriter writer = (BufferedWriter)closeable;
                    boolean bl = false;
                    writer.write(reservedTable.toString());
                    writer.write(table.toString());
                    writer.flush();
                    Unit unit = Unit.INSTANCE;
                }
                catch (Throwable throwable2) {
                    throwable = throwable2;
                    throw throwable2;
                }
                finally {
                    CloseableKt.closeFinally((Closeable)closeable, (Throwable)throwable);
                }
            }
            catch (IOException iOException) {
                Common.INSTANCE.getLogger$NetworkUtils().error("Error saving routing table file: {}", (Object)file, (Object)iOException);
            }
        } else {
            throw new RuntimeException("NOT IMPL.");
        }
    }
}

