module dorkbox.jna {
    /* transitive */ requires dorkbox.updates;
    /* transitive */ requires dorkbox.os;
    /* transitive */ requires kotlin.stdlib;
    /* static phase */ requires com.sun.jna;
    /* static phase */ requires com.sun.jna.platform;
    /* static phase */ requires org.slf4j;

    exports dorkbox.jna;
    exports dorkbox.jna.rendering;
    exports dorkbox.jna.linux;
    exports dorkbox.jna.linux.structs;
    exports dorkbox.jna.macos;
    exports dorkbox.jna.macos.cocoa;
    exports dorkbox.jna.macos.foundation;
    exports dorkbox.jna.windows;
    exports dorkbox.jna.windows.structs;

}

