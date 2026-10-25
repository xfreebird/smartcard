/*
 * Decompiled with CFR 0.152.
 */
package cargo.model;

import java.util.List;

public final class CheckDeclarationSubjectResp {
    public final List<Org> checklist;

    public CheckDeclarationSubjectResp(List<Org> checklist) {
        this.checklist = checklist;
    }

    public record Org(long id, boolean confirm) {
    }
}

