import os, struct, glob
from PIL import Image

BASE = r"D:\Downloads\пример"
OUT = os.path.join(BASE, "generated", "textures")
os.makedirs(OUT, exist_ok=True)

count = 0
for sub in ["assets/sprites", "assets/tilesets"]:
    d = os.path.join(BASE, sub)
    for fn in sorted(os.listdir(d)):
        if not fn.endswith(".png"):
            continue
        im = Image.open(os.path.join(d, fn)).convert("RGBA")
        w, h = im.size
        data = im.tobytes()  # top-left origin, RGBA
        row = w * 4
        # Godot stores Image data bottom-left origin: reverse row order.
        flipped = b"".join(data[i * row:(i + 1) * row] for i in range(h - 1, -1, -1))
        name = fn[:-4]
        with open(os.path.join(OUT, name + ".rgba"), "wb") as f:
            f.write(b"PHRAW")                 # magic
            f.write(struct.pack("<III", w, h, 4))  # w, h, fmt(4=RGBA8)
            f.write(flipped)
        count += 1
        print("WROTE", name, w, h)
print("PY_DONE count=%d" % count)
