import sys, time
from vncdotool import api
c = api.connect('127.0.0.1::5901')
pts = [(int(a), int(b)) for a, b in (p.split(',') for p in sys.argv[1:])]
c.mouseMove(*pts[0]); time.sleep(0.2); c.mousePress(1); time.sleep(0.3)
c.keyDown('ctrl')
for x, y in pts[1:]:
    c.mouseMove(x, y); time.sleep(0.2); c.mousePress(1); time.sleep(0.3)
c.keyUp('ctrl'); c.disconnect()
