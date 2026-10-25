module dorkbox.executor {
    /* transitive */ requires dorkbox.updates;
    /* transitive */ requires org.slf4j;
    /* static phase */ requires com.hierynomus.sshj;
    /* static phase */ requires ch.qos.logback.classic;
    /* transitive */ requires kotlin.stdlib;
    requires kotlinx.coroutines.core.jvm;

    exports dorkbox.executor;
    exports dorkbox.executor.exceptions;
    exports dorkbox.executor.listener;
    exports dorkbox.executor.processResults;
    exports dorkbox.executor.stop;
    exports dorkbox.executor.stream;
    exports dorkbox.executor.stream.nopStreams;
    exports dorkbox.executor.stream.slf4j;

}

