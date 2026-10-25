#!/bin/bash
# MoldSign APDU capture runner
#
# Prereq: QUIT both "MoldSign Desktop" and "MoldSign Server" first
# (they must not be running; the instrumented server binds the same ports).
#
# Run:  bash /Users/nghimbovschi/Projects/smartcard/re/run_capture.sh
# Server runs in the foreground; Ctrl-C stops it.
# Then relaunch the original "MoldSign Server.app" as usual.

set -e
cd "/Applications/STISC/MoldSign"
export DYLD_LIBRARY_PATH="/Applications/STISC/MoldSign/native_lib"
export USE_CLEARTEXT_LOG=12345678
export DYLD_INSERT_LIBRARIES="/Users/nghimbovschi/Projects/smartcard/re/pcsc_trace.dylib"
export PCSC_TRACE_FILE="/Users/nghimbovschi/Projects/smartcard/re/apdu_capture.log"
echo "APDU trace -> $PCSC_TRACE_FILE"
exec "/Users/nghimbovschi/Projects/smartcard/re/jre_trace/Contents/Home/bin/java" \
  -DMoldSign.TempDir=./log \
  -DMoldSign.DataDir=./MoldSignData \
  -Xdock:icon="./MoldSign Server.app/Contents/Resources/app.icns" \
  -Xdock:name="MoldSign Server" \
  -jar ./lib/ClientCardServer-2.0.jar
