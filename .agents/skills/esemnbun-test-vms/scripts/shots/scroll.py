import sys, time
from vncdotool import api
port, direction, n = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
c = api.connect(f'127.0.0.1::{port}')
c.mouseMove(790, 600)
for _ in range(n): c.mousePress(direction); time.sleep(0.05)
time.sleep(1); c.mouseMove(1590, 10); time.sleep(0.4)
if len(sys.argv) > 4: c.refreshScreen(); c.captureScreen(sys.argv[4])
c.disconnect()
