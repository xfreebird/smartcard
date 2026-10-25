/*
 * Decompiled with CFR 0.152.
 */
package cargo.model;

import cargo.DartCertificate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public final class CheckDeclarationSubjectReq {
    public final List<Org> checklist = new ArrayList<Org>();

    public CheckDeclarationSubjectReq(Map<Long, DartCertificate> certList) {
        for (Map.Entry<Long, DartCertificate> entry : certList.entrySet()) {
            String org = entry.getValue().getOrganization();
            if (org == null) continue;
            this.checklist.add(new Org(entry.getKey(), org));
        }
    }

    public record Org(long id, String organization) {
    }
}

