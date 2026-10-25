/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.cryptography.providers;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import md.cts.cryptography.providers.DefaultSecurityOperationsProvider;
import md.cts.cryptography.providers.SecurityOperationProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class SecurityOperationsProviderManager {
    private static final Logger logger = LoggerFactory.getLogger(SecurityOperationsProviderManager.class);
    private static final String DEFAULT_PROVIDER = "DEFAULT PROVIDER";
    private static SecurityOperationsProviderManager instance = null;
    private final Map<String, SecurityOperationProvider> providers = Collections.synchronizedMap(new HashMap());

    private static SecurityOperationsProviderManager getInstance() {
        if (instance == null) {
            instance = new SecurityOperationsProviderManager();
            SecurityOperationsProviderManager.instance.providers.put(DEFAULT_PROVIDER, new DefaultSecurityOperationsProvider());
        }
        return instance;
    }

    public static void registerProvider(String name, SecurityOperationProvider provider) {
        logger.info("registerProvider name={} provider={}", (Object)name, (Object)provider);
        SecurityOperationsProviderManager.getInstance().providers.put(name, provider);
    }

    public static SecurityOperationProvider getProvider(String name) {
        return SecurityOperationsProviderManager.getInstance().providers.get(name);
    }

    public static SecurityOperationProvider getDefault() {
        return SecurityOperationsProviderManager.getProvider(DEFAULT_PROVIDER);
    }

    public static void removeProvider(String name) {
        logger.info("removeProvider name={}", (Object)name);
        SecurityOperationsProviderManager.getInstance().providers.remove(name);
    }

    public static void debug() {
        StringBuilder b = new StringBuilder();
        b.append("---SecurityOperationsProviderManager---\r\n");
        b.append("providers size = ");
        if (instance != null) {
            b.append(SecurityOperationsProviderManager.instance.providers.size());
            b.append("\r\n");
            for (Map.Entry<String, SecurityOperationProvider> x : SecurityOperationsProviderManager.instance.providers.entrySet()) {
                b.append("name: ");
                b.append(x.getKey());
                b.append("\r\n");
                b.append("class: ");
                b.append(x.getValue().toString());
                b.append("\r\n");
            }
        }
        b.append("-----\r\n");
        System.out.println(b);
    }
}

