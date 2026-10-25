module dorkbox.utilities {
    /* transitive */ requires dorkbox.executor;
    /* transitive */ requires dorkbox.updates;
    /* transitive */ requires dorkbox.os;
    /* transitive */ requires kotlin.stdlib;
    requires kotlinx.coroutines.core.jvm;
    /* static phase */ requires com.sun.jna;
    /* static phase */ requires com.sun.jna.platform;
    /* static phase */ requires org.slf4j;

    exports dorkbox.exit;
    exports dorkbox.urlHandler;
    exports dorkbox.util;
    exports dorkbox.util.classes;
    exports dorkbox.util.crypto;
    exports dorkbox.util.crypto.signers;
    exports dorkbox.util.entropy;
    exports dorkbox.util.exceptions;
    exports dorkbox.util.gwt;
    exports dorkbox.util.properties;
    exports dorkbox.util.userManagement;

}

