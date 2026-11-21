#!/usr/bin/env python3
"""Ubah satu gambar stage dari generator menjadi layer stage ukuran game.

Stage IndoFight selebar 960 piksel dengan layer yang bergeser beda kecepatan (GDD 7),
sedangkan generator hanya memberi satu gambar sekitar 500 piksel. Skrip ini:
  1. Memotong gambar menjadi 270 baris mulai dari baris --top.
  2. Mengunci palet stage (art/palettes/<nama palet>.hex dan .gpl) dan memaskan semua piksel ke palet itu.
  3. Membelah gambar di baris --cut (batas trotoar dan jalan):
       background  baris di atas --cut, bergeser 0,5x, lebar 720
       floor       baris --cut ke bawah, bergeser 1,0x, lebar 960 (tempat petarung berpijak)
  4. Melebarkan tiap layer dengan menyambung cerminan gambar itu sendiri, supaya sambungannya rata.

Contoh:
  python tools/pixelize_stage.py raw.png --name gang --top 5 --cut 226
"""
import argparse
import os

from PIL import Image, ImageOps

from palette import dist, nearest

VIEW_H = 270
BG_W = 720
FLOOR_W = 960


def lock_palette(im, colors, min_distance=8.0):
    """Ambil palet dari gambar: warna terbanyak dulu, warna yang hampir kembar digabung."""
    q = im.quantize(colors=min(256, colors * 4), method=Image.Quantize.MEDIANCUT)
    pal = q.getpalette()
    kept = []
    for _, i in sorted(q.getcolors(), reverse=True):
        c = tuple(pal[i * 3:i * 3 + 3])
        if all(dist(c, k) ** 0.5 / 3 >= min_distance for k in kept):
            kept.append(c)
        if len(kept) >= colors:
            break
    kept.sort(key=lambda c: 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2])
    return kept


def snap(im, pal):
    out = Image.new("RGB", im.size)
    src, dst = im.load(), out.load()
    cache = {}
    for y in range(im.height):
        for x in range(im.width):
            c = src[x, y]
            if c not in cache:
                cache[c] = nearest(c, pal)
            dst[x, y] = cache[c]
    return out


def widen(im, width):
    """Sambung gambar dengan cerminannya sampai selebar `width`."""
    out = Image.new(im.mode, (width, im.height))
    x, flip = 0, False
    while x < width:
        out.paste(ImageOps.mirror(im) if flip else im, (x, 0))
        x += im.width
        flip = not flip
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("raw")
    ap.add_argument("--name", required=True, help="kode stage, misalnya gang")
    ap.add_argument("--top", type=int, default=0, help="baris pertama gambar mentah yang dipakai")
    ap.add_argument("--cut", type=int, required=True, help="baris (0 sampai 269) tempat lantai dimulai")
    ap.add_argument("--colors", type=int, default=32)
    ap.add_argument("--out", default="art/stages")
    ap.add_argument("--palettes", default="art/palettes")
    a = ap.parse_args()

    raw = Image.open(a.raw).convert("RGB")
    if raw.height < a.top + VIEW_H:
        raise SystemExit(f"Gambar hanya {raw.height} baris, butuh {a.top + VIEW_H}.")
    im = raw.crop((0, a.top, raw.width, a.top + VIEW_H))

    pal = lock_palette(im, a.colors)
    pname = f"stage-{a.name}"
    with open(os.path.join(a.palettes, pname + ".hex"), "w", newline="\n") as f:
        f.write("\n".join("%02x%02x%02x" % c for c in pal) + "\n")
    with open(os.path.join(a.palettes, pname + ".gpl"), "w", newline="\n") as f:
        f.write(f"GIMP Palette\nName: IndoFight {pname}\nColumns: 8\n#\n")
        for c in pal:
            f.write("%3d %3d %3d\t%02x%02x%02x\n" % (c + c))
    im = snap(im, pal)

    out_dir = os.path.join(a.out, a.name)
    os.makedirs(out_dir, exist_ok=True)
    bg = widen(im.crop((0, 0, im.width, a.cut)), BG_W)
    floor = widen(im.crop((0, a.cut, im.width, VIEW_H)), FLOOR_W)
    bg_path = os.path.join(out_dir, f"indofight_stage_{a.name}_bg.png")
    floor_path = os.path.join(out_dir, f"indofight_stage_{a.name}_floor.png")
    bg.save(bg_path)
    floor.save(floor_path)
    print(f"Palet {pname}: {len(pal)} warna")
    print(f"{bg_path}: {bg.width} x {bg.height}")
    print(f"{floor_path}: {floor.width} x {floor.height} (mulai baris {a.cut})")


if __name__ == "__main__":
    main()
