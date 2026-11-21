#!/usr/bin/env python3
"""Perbesar PNG pixel art dengan kelipatan bulat (nearest-neighbor).

Contoh:
  python3 tools/upscale.py art/characters/mahasiswa/indofight_char_mahasiswa_splash.png        # 4x
  python3 tools/upscale.py art/characters/mahasiswa --scale 4 --out export/4x                  # satu folder
Hasil diberi akhiran _4x.png kecuali --out diisi.
"""
import argparse
import os
import sys

from PIL import Image


def up(src, dst, n):
    im = Image.open(src)
    im.resize((im.width * n, im.height * n), Image.NEAREST).save(dst)
    print(f"{src} -> {dst} ({im.width * n} x {im.height * n})")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("path")
    ap.add_argument("--scale", type=int, default=4)
    ap.add_argument("--out", help="folder hasil")
    a = ap.parse_args()
    if a.scale < 1:
        sys.exit("scale harus bilangan bulat >= 1")
    files = []
    if os.path.isdir(a.path):
        files = [os.path.join(a.path, f) for f in sorted(os.listdir(a.path)) if f.lower().endswith(".png") and "_%dx" % a.scale not in f]
    else:
        files = [a.path]
    for f in files:
        if a.out:
            os.makedirs(a.out, exist_ok=True)
            dst = os.path.join(a.out, os.path.basename(f))
            if os.path.abspath(dst) == os.path.abspath(f):
                sys.exit("--out tidak boleh folder sumber: gambar asli akan tertimpa")
        else:
            dst = f[:-4] + f"_{a.scale}x.png"
        up(f, dst, a.scale)


if __name__ == "__main__":
    main()
