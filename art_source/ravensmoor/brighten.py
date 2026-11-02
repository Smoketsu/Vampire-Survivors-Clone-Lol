"""brighten.py: lifts a dark API source before prepare_sprite.py (the Burning Gate, Act VI phase 2): the black robes
and hides came out too dark for the lightness rule (art_check.py: main shape +0.15 L over a dark floor).
Usage: python3 art_source/burning_gate/brighten.py <src.png> <out.png> <factor>"""
import sys
from PIL import Image, ImageEnhance
im = Image.open(sys.argv[1]).convert("RGBA")
a = im.getchannel("A")
rgb = ImageEnhance.Brightness(im.convert("RGB")).enhance(float(sys.argv[3]))
out = rgb.convert("RGBA")
out.putalpha(a)
out.save(sys.argv[2])
