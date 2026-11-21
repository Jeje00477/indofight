#!/usr/bin/env python3
"""Ambil palet terkunci dari sebuah gambar (misalnya background stage yang sudah disetujui).

Contoh:
  python3 tools/extract_palette.py art/stages/gang/indofight_stage_gang_bg.png --name stage-gang --colors 32
Menghasilkan art/palettes/<name>.hex dan .gpl. Warna yang hampir kembar digabung.
"""
import argparse
import os

from PIL import Image

from palette import dist


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--name", required=True)
    ap.add_argument("--colors", type=int, default=24)
    ap.add_argument("--min-distance", type=float, default=10)
    ap.add_argument("--out", default="art/palettes")
    a = ap.parse_args()
    im = Image.open(a.image).convert("RGBA")
    data = im.get_flattened_data() if hasattr(im, "get_flattened_data") else im.getdata()
    px = [p[:3] for p in data if p[3] > 0]
    tmp = Image.new("RGB", (len(px), 1))
    tmp.putdata(px)
    q = tmp.quantize(colors=min(256, a.colors * 3), method=Image.Quantize.MEDIANCUT)
    pal = q.getpalette()
    counted = sorted(q.getcolors(), reverse=True)
    kept = []
    for _, i in counted:
        c = tuple(pal[i * 3:i * 3 + 3])
        if all(dist(c, k) ** 0.5 / 3 >= a.min_distance for k in kept):
            kept.append(c)
        if len(kept) >= a.colors:
            break
    kept.sort(key=lambda c: 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2])
    os.makedirs(a.out, exist_ok=True)
    base = os.path.join(a.out, a.name)
    with open(base + ".hex", "w") as f:
        f.write("\n".join("%02x%02x%02x" % c for c in kept) + "\n")
    with open(base + ".gpl", "w") as f:
        f.write(f"GIMP Palette\nName: IndoFight {a.name}\nColumns: 8\n#\n")
        for c in kept:
            f.write("%3d %3d %3d\t%02x%02x%02x\n" % (c + c))
    print(f"{len(kept)} warna -> {base}.hex dan {base}.gpl")


if __name__ == "__main__":
    main()
