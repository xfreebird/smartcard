/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.os;

import kotlin.Metadata;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000 \n\u0002\u0018\u0002\n\u0002\u0010\u0010\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u0011\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0002\b&\b\u0086\u0001\u0018\u00002\b\u0012\u0004\u0012\u00020\u00000\u0001B#\b\u0002\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0012\u0010\u0004\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00030\u0005\"\u00020\u0003\u00a2\u0006\u0002\u0010\u0006R\u0011\u0010\u0007\u001a\u00020\b8F\u00a2\u0006\u0006\u001a\u0004\b\u0007\u0010\tR\u0011\u0010\n\u001a\u00020\b8F\u00a2\u0006\u0006\u001a\u0004\b\n\u0010\tR\u0011\u0010\u000b\u001a\u00020\b8F\u00a2\u0006\u0006\u001a\u0004\b\u000b\u0010\tR\u0011\u0010\f\u001a\u00020\b8F\u00a2\u0006\u0006\u001a\u0004\b\f\u0010\tR\u0011\u0010\r\u001a\u00020\b8F\u00a2\u0006\u0006\u001a\u0004\b\r\u0010\tR\u0011\u0010\u000e\u001a\u00020\b8F\u00a2\u0006\u0006\u001a\u0004\b\u000e\u0010\tR\u0011\u0010\u000f\u001a\u00020\b8F\u00a2\u0006\u0006\u001a\u0004\b\u000f\u0010\tR\u0011\u0010\u0010\u001a\u00020\b8F\u00a2\u0006\u0006\u001a\u0004\b\u0010\u0010\tR\u0011\u0010\u0011\u001a\u00020\b8F\u00a2\u0006\u0006\u001a\u0004\b\u0011\u0010\tR\u0011\u0010\u0012\u001a\u00020\b8F\u00a2\u0006\u0006\u001a\u0004\b\u0012\u0010\tR\u0011\u0010\u0013\u001a\u00020\b8F\u00a2\u0006\u0006\u001a\u0004\b\u0013\u0010\tR\u001b\u0010\u0004\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00030\u0005\u00a2\u0006\n\n\u0002\u0010\u0016\u001a\u0004\b\u0014\u0010\u0015R\u0011\u0010\u0017\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0018\u0010\u0019j\u0002\b\u001aj\u0002\b\u001bj\u0002\b\u001cj\u0002\b\u001dj\u0002\b\u001ej\u0002\b\u001fj\u0002\b j\u0002\b!j\u0002\b\"j\u0002\b#j\u0002\b$j\u0002\b%j\u0002\b&j\u0002\b'j\u0002\b(j\u0002\b)j\u0002\b*j\u0002\b+j\u0002\b,j\u0002\b-\u00a8\u0006."}, d2={"Ldorkbox/os/OSType;", "", "name", "", "libraryNames", "", "(Ljava/lang/String;ILjava/lang/String;[Ljava/lang/String;)V", "is32bit", "", "()Z", "is64bit", "isAndroid", "isArm", "isLinux", "isMacOsX", "isMips", "isSolaris", "isUnix", "isWindows", "isX86", "getLibraryNames", "()[Ljava/lang/String;", "[Ljava/lang/String;", "standardName", "getStandardName", "()Ljava/lang/String;", "Windows32", "Windows64", "Linux32", "Linux64", "MacOsX32", "MacOsX64", "MacOsArm", "UnixArm", "Unix32", "Unix64", "Solaris", "AndroidArm56", "AndroidArm7", "AndroidArm8", "AndroidMips", "AndroidX86", "AndroidMips64", "AndroidX86_64", "LinuxArm32", "LinuxArm64", "OS"})
public final class OSType
extends Enum<OSType> {
    @NotNull
    private final String standardName;
    @NotNull
    private final String[] libraryNames;
    public static final /* enum */ OSType Windows32;
    public static final /* enum */ OSType Windows64;
    public static final /* enum */ OSType Linux32;
    public static final /* enum */ OSType Linux64;
    public static final /* enum */ OSType MacOsX32;
    public static final /* enum */ OSType MacOsX64;
    public static final /* enum */ OSType MacOsArm;
    public static final /* enum */ OSType UnixArm;
    public static final /* enum */ OSType Unix32;
    public static final /* enum */ OSType Unix64;
    public static final /* enum */ OSType Solaris;
    public static final /* enum */ OSType AndroidArm56;
    public static final /* enum */ OSType AndroidArm7;
    public static final /* enum */ OSType AndroidArm8;
    public static final /* enum */ OSType AndroidMips;
    public static final /* enum */ OSType AndroidX86;
    public static final /* enum */ OSType AndroidMips64;
    public static final /* enum */ OSType AndroidX86_64;
    public static final /* enum */ OSType LinuxArm32;
    public static final /* enum */ OSType LinuxArm64;
    private static final /* synthetic */ OSType[] $VALUES;

    private OSType(String name, String ... libraryNames) {
        this.standardName = name;
        this.libraryNames = libraryNames;
    }

    @NotNull
    public final String getStandardName() {
        return this.standardName;
    }

    @NotNull
    public final String[] getLibraryNames() {
        return this.libraryNames;
    }

    public final boolean is64bit() {
        return this == Linux64 || this == LinuxArm64 || this == Windows64 || this == MacOsX64 || this == AndroidArm8 || this == AndroidX86_64 || this == AndroidMips64 || this == Unix64;
    }

    public final boolean is32bit() {
        return this == Linux32 || this == LinuxArm32 || this == Windows32 || this == MacOsX32 || this == AndroidArm56 || this == AndroidArm7 || this == AndroidX86 || this == AndroidMips || this == UnixArm || this == Unix32;
    }

    public final boolean isMips() {
        return this == AndroidMips || this == AndroidMips64;
    }

    public final boolean isX86() {
        return this == Linux64 || this == LinuxArm64 || this == Windows64 || this == MacOsX64 || this == Linux32 || this == LinuxArm32 || this == Windows32 || this == MacOsX32 || this == Unix32 || this == Unix64 || this == AndroidX86 || this == AndroidX86_64;
    }

    public final boolean isArm() {
        return this == LinuxArm32 || this == LinuxArm64 || this == AndroidArm56 || this == AndroidArm7 || this == AndroidArm8 || this == MacOsArm || this == UnixArm;
    }

    public final boolean isLinux() {
        return this == Linux32 || this == Linux64 || this == LinuxArm64 || this == LinuxArm32;
    }

    public final boolean isUnix() {
        return this == Unix32 || this == Unix64 || this == UnixArm;
    }

    public final boolean isSolaris() {
        return this == Solaris;
    }

    public final boolean isWindows() {
        return this == Windows64 || this == Windows32;
    }

    public final boolean isMacOsX() {
        return this == MacOsX64 || this == MacOsX32 || this == MacOsArm;
    }

    public final boolean isAndroid() {
        return this == AndroidArm56 || this == AndroidArm7 || this == AndroidX86 || this == AndroidMips || this == AndroidArm8 || this == AndroidX86_64 || this == AndroidMips64;
    }

    public static OSType[] values() {
        return (OSType[])$VALUES.clone();
    }

    public static OSType valueOf(String value) {
        return Enum.valueOf(OSType.class, value);
    }

    static {
        String[] stringArray = new String[]{".dll"};
        Windows32 = new OSType("windows_32", stringArray);
        stringArray = new String[]{".dll"};
        Windows64 = new OSType("windows_64", stringArray);
        stringArray = new String[]{".so"};
        Linux32 = new OSType("linux_32", stringArray);
        stringArray = new String[]{".so"};
        Linux64 = new OSType("linux_64", stringArray);
        stringArray = new String[]{".jnilib", ".dylib"};
        MacOsX32 = new OSType("macosx_32", stringArray);
        stringArray = new String[]{".jnilib", ".dylib"};
        MacOsX64 = new OSType("macosx_64", stringArray);
        stringArray = new String[]{".jnilib", ".dylib"};
        MacOsArm = new OSType("macosx_aarch64", stringArray);
        stringArray = new String[]{".so"};
        UnixArm = new OSType("unix_arm", stringArray);
        stringArray = new String[]{".so"};
        Unix32 = new OSType("unix_32", stringArray);
        stringArray = new String[]{".so"};
        Unix64 = new OSType("unix_64", stringArray);
        stringArray = new String[]{".so"};
        Solaris = new OSType("solaris", stringArray);
        stringArray = new String[]{".so"};
        AndroidArm56 = new OSType("android_arm56", stringArray);
        stringArray = new String[]{".so"};
        AndroidArm7 = new OSType("android_arm7", stringArray);
        stringArray = new String[]{".so"};
        AndroidArm8 = new OSType("android_arm8", stringArray);
        stringArray = new String[]{".so"};
        AndroidMips = new OSType("android_mips", stringArray);
        stringArray = new String[]{".so"};
        AndroidX86 = new OSType("android_x86", stringArray);
        stringArray = new String[]{".so"};
        AndroidMips64 = new OSType("android_mips64", stringArray);
        stringArray = new String[]{".so"};
        AndroidX86_64 = new OSType("android_x86_64", stringArray);
        stringArray = new String[]{".so"};
        LinuxArm32 = new OSType("linux_arm7_hf", stringArray);
        stringArray = new String[]{".so"};
        LinuxArm64 = new OSType("linux_arm8_hf", stringArray);
        $VALUES = oSTypeArray = new OSType[]{OSType.Windows32, OSType.Windows64, OSType.Linux32, OSType.Linux64, OSType.MacOsX32, OSType.MacOsX64, OSType.MacOsArm, OSType.UnixArm, OSType.Unix32, OSType.Unix64, OSType.Solaris, OSType.AndroidArm56, OSType.AndroidArm7, OSType.AndroidArm8, OSType.AndroidMips, OSType.AndroidX86, OSType.AndroidMips64, OSType.AndroidX86_64, OSType.LinuxArm32, OSType.LinuxArm64};
    }
}

