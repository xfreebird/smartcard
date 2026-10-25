/*
 * Decompiled with CFR 0.152.
 */
package cargo.model;

public final class TokenInformation {
    private final String label;
    private final String manufacture;
    private final String model;
    private final String serial_number;
    private final long slot_id;
    private final String module;

    public TokenInformation(String label, String manufacture, String model, String serial_number, long slot_id, String module) {
        this.label = label;
        this.manufacture = manufacture;
        this.model = model;
        this.serial_number = serial_number;
        this.slot_id = slot_id;
        this.module = module;
    }
}

