"""Tiny VNC driver for the test VMs: python vshot.py <port> <cmd> [args]... (cmds chain: click X Y, dbl X Y, type TEXT, key NAME, sleep S, shot FILE)"""
import sys, time, os
from vncdotool import api
port = sys.argv[1]; args = sys.argv[2:]
c = api.connect(f'127.0.0.1::{port}')
SHIFTED = dict(zip('~!@#$%^&*()_+{}|:"<>?', "`1234567890-=[]\\;',./"))
def typech(ch):
    # QEMU's VNC server maps keysyms to scancodes without adding Shift: press it explicitly.
    base = SHIFTED.get(ch) or (ch.lower() if ch.isupper() else None)
    if base:
        c.keyDown('shift'); c.keyPress(base); c.keyUp('shift')
    else:
        c.keyPress(ch)
i = 0
while i < len(args):
    a = args[i]
    if a == 'click': c.mouseMove(int(args[i+1]), int(args[i+2])); time.sleep(0.2); c.mousePress(1); i += 3
    elif a == 'rclick': c.mouseMove(int(args[i+1]), int(args[i+2])); time.sleep(0.2); c.mousePress(3); i += 3
    elif a == 'dbl': c.mouseMove(int(args[i+1]), int(args[i+2])); c.mousePress(1); time.sleep(0.05); c.mousePress(1); i += 3
    elif a == 'drag':
        x1,y1,x2,y2 = (int(v) for v in args[i+1:i+5]); c.mouseMove(x1,y1); time.sleep(0.2); c.mouseDown(1)
        for k in range(1,21): c.mouseMove(x1+(x2-x1)*k//20, y1+(y2-y1)*k//20); time.sleep(0.03)
        time.sleep(0.2); c.mouseUp(1); i += 5
    elif a == 'move': c.mouseMove(int(args[i+1]), int(args[i+2])); i += 3
    elif a == 'type':
        for ch in args[i+1]: typech(ch); time.sleep(0.03)
        i += 2
    elif a == 'typeenv':
        for ch in os.environ[args[i+1]]: typech(ch); time.sleep(0.05)
        i += 2
    elif a == 'key': c.keyPress(args[i+1]); i += 2
    elif a == 'sleep': time.sleep(float(args[i+1])); i += 2
    elif a == 'shot': c.refreshScreen(); c.captureScreen(args[i+1]); i += 2
    else: raise SystemExit('unknown ' + a)
c.disconnect()
