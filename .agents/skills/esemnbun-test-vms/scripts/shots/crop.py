import sys
from PIL import Image
src, dst = sys.argv[1], sys.argv[2]
box = tuple(int(v) for v in sys.argv[3].split(',')) if len(sys.argv) > 3 else None
im = Image.open(src)
(im.crop(box) if box else im).save(dst)
