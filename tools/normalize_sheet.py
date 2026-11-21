#!/usr/bin/env python3
"""Seragamkan sprite sheet hasil generator menjadi frame 160 x 160 IndoFight.

Hasil SpriteCook bisa punya ukuran frame lain karena margin. Alat ini:
  1. Memotong sheet menjadi N frame (N diberikan, atau dihitung dari --src-frame).
  2. Menghitung posisi kaki di frame acuan (default frame pertama).
  3. Menggeser SEMUA frame dengan jarak yang sama, supaya kaki frame acuan berada di
     kolom 80 dan baris 150. Gerakan maju-mundur di dalam animasi tetap terjaga.
  4. Menyimpan sheet baru selebar N x 160.

Dengan --snap-floor, setiap frame juga diturunkan atau dinaikkan supaya kakinya tepat
di baris 150. Pakai hanya untuk animasi yang kakinya selalu menapak (idle, walk,
serangan). Jangan pakai untuk jump, knockup, knockdown.

Contoh:
  python3 tools/normalize_sheet.py hasil.png --frames 6 --out art/characters/emak-emak/indofight_char_emak-emak_idle_sheet.png --snap-floor
"""
import argparse
import sys

from PIL import Image

FW = FH = 160
FLOOR = 150
CENTER = 80


def foot(img):
    w, h = img.size
    px = img.load()
    for y in range(h - 1, -1, -1):
        xs = [x for x in range(w) if px[x, y][3] > 0]
        if xs:
            foot_xs = []
            for yy in range(y, max(-1, y - 3), -1):
                foot_xs += [x for x in range(w) if px[x, yy][3] > 0]
            return y, sum(foot_xs) / len(foot_xs)
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sheet")
    ap.add_argument("--frames", type=int, help="jumlah frame dalam sheet (horizontal)")
    ap.add_argument("--src-frame", type=int, help="lebar frame sumber, bila jumlah frame tidak diketahui")
    ap.add_argument("--anchor", type=int, default=0, help="indeks frame acuan (default 0)")
    ap.add_argument("--snap-floor", action="store_true")
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    src = Image.open(a.sheet).convert("RGBA")
    if a.frames:
        n = a.frames
        sw = src.width // n
    elif a.src_frame:
        sw = a.src_frame
        n = src.width // sw
    else:
        sys.exit("isi --frames atau --src-frame")
    sh = src.height
    frames = [src.crop((i * sw, 0, (i + 1) * sw, sh)) for i in range(n)]
    ref = foot(frames[a.anchor])
    if ref is None:
        sys.exit("frame acuan kosong")
    dx = round(CENTER - ref[1])
    dy = FLOOR - ref[0]
    out = Image.new("RGBA", (FW * n, FH), (0, 0, 0, 0))
    clipped = 0
    for i, f in enumerate(frames):
        fdy = dy
        if a.snap_floor:
            ft = foot(f)
            if ft:
                fdy = FLOOR - ft[0]
        cell = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
        cell.paste(f, (dx, fdy), f)
        before = f.width * f.height - f.getchannel("A").histogram()[0]
        after = cell.width * cell.height - cell.getchannel("A").histogram()[0]
        if after < before:
            clipped += 1
        out.paste(cell, (i * FW, 0))
    out.save(a.out)
    print(f"{n} frame {sw}x{sh} -> {FW}x{FH}, geser ({dx}, {dy}). Simpan: {a.out}")
    if clipped:
        print(f"PERINGATAN: {clipped} frame terpotong di tepi kanvas 160 x 160. Periksa ayunan senjata atau lompatan.")


if __name__ == "__main__":
    main()
