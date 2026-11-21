#!/usr/bin/env python3
"""Ubah gambar dasar dari generator menjadi pixel art ukuran game.

Generator mengembalikan gambar dengan ukuran dan jumlah warna bebas. Skrip ini:
  1. Memisahkan karakter (bentuk terbesar) dari properti di sampingnya.
  2. Mengecilkan semuanya dengan satu faktor yang sama, sehingga karakter setinggi --height piksel.
  3. Memaskan setiap piksel ke palet terkunci dan membuang piksel setengah transparan.
  4. Menulis:
       --out-base   kanvas 160 x 160 berisi karakter saja, kaki di baris 150, tengah di kolom 80
       --out-sheet  karakter di posisi yang sama, ditambah properti di sebelah kanan (bahan potong)

Contoh:
  python tools/pixelize_base.py raw.png --palette art/palettes/emak-emak.hex --height 100 \\
      --out-base art/characters/emak-emak/indofight_char_emak-emak_base.png \\
      --out-sheet art/characters/emak-emak/rig/sheet.png
"""
import argparse
import os
from collections import deque

from PIL import Image

from palette import load_palette, nearest

CANVAS = 160
FLOOR = 150
CENTER = 80


def components(im, min_pixels=40):
    """Kotak pembatas tiap bentuk yang terpisah, terbesar dulu."""
    w, h = im.size
    alpha = im.getchannel("A").load()
    seen = [[False] * w for _ in range(h)]
    found = []
    for y0 in range(h):
        for x0 in range(w):
            if seen[y0][x0] or alpha[x0, y0] < 128:
                continue
            q = deque([(x0, y0)])
            seen[y0][x0] = True
            n, l, t, r, b = 0, x0, y0, x0, y0
            while q:
                x, y = q.popleft()
                n += 1
                l, t, r, b = min(l, x), min(t, y), max(r, x), max(b, y)
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and alpha[nx, ny] >= 128:
                            seen[ny][nx] = True
                            q.append((nx, ny))
            if n >= min_pixels:
                found.append((n, (l, t, r + 1, b + 1)))
    found.sort(reverse=True)
    return [box for _, box in found]


def shrink(im, factor, pal, outline):
    """Kecilkan dengan rata-rata berbobot alpha, lalu paskan ke palet."""
    w = max(1, round(im.width * factor))
    h = max(1, round(im.height * factor))
    # Kalikan warna dengan alpha dulu supaya warna latar tidak ikut tercampur ke tepi.
    pre = im.copy()
    px = pre.load()
    for y in range(pre.height):
        for x in range(pre.width):
            r, g, b, a = px[x, y]
            px[x, y] = (r * a // 255, g * a // 255, b * a // 255, a)
    small = pre.resize((w, h), Image.BOX)
    sp = small.load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    op = out.load()
    cache = {}
    for y in range(h):
        for x in range(w):
            r, g, b, a = sp[x, y]
            if a < 128:
                continue
            c = (min(255, r * 255 // a), min(255, g * 255 // a), min(255, b * 255 // a))
            if c not in cache:
                cache[c] = nearest(c, pal)
            op[x, y] = cache[c] + (255,)
    if outline:
        add_outline(out, pal)
    return out


def add_outline(im, pal):
    """Garis tepi 1 piksel dari warna tergelap palet di sepanjang siluet (GDD 2)."""
    dark = min(pal, key=lambda c: 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2])
    w, h = im.size
    px = im.load()
    edge = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < w and 0 <= ny < h) or px[nx, ny][3] == 0:
                    edge.append((x, y))
                    break
    for x, y in edge:
        px[x, y] = dark + (255,)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("raw")
    ap.add_argument("--palette", required=True)
    ap.add_argument("--height", type=int, required=True, help="tinggi karakter berdiri dalam piksel (96 sampai 112)")
    ap.add_argument("--out-base", required=True)
    ap.add_argument("--out-sheet", required=True)
    ap.add_argument("--no-outline", action="store_true")
    a = ap.parse_args()

    pal = load_palette(a.palette)
    raw = Image.open(a.raw).convert("RGBA")
    boxes = components(raw)
    if not boxes:
        raise SystemExit("Tidak ada bentuk di gambar.")
    char_box, prop_boxes = boxes[0], sorted(boxes[1:], key=lambda b: b[0])
    factor = a.height / (char_box[3] - char_box[1])
    print(f"Karakter {char_box}, {len(prop_boxes)} properti, faktor {factor:.3f}")

    char = shrink(raw.crop(char_box), factor, pal, not a.no_outline)
    props = [shrink(raw.crop(b), factor, pal, not a.no_outline) for b in prop_boxes]

    # Tengah kaki: rata-rata kolom terisi di 3 baris terbawah.
    cp = char.load()
    foot = [x for y in range(char.height - 3, char.height) for x in range(char.width) if cp[x, y][3]]
    foot_center = round(sum(foot) / len(foot))
    ox = CENTER - foot_center
    oy = FLOOR + 1 - char.height

    base = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    base.alpha_composite(char, (ox, oy))
    os.makedirs(os.path.dirname(a.out_base) or ".", exist_ok=True)
    base.save(a.out_base)

    gap = 8
    sheet_w = CANVAS + sum(p.width + gap for p in props)
    sheet = Image.new("RGBA", (sheet_w, CANVAS), (0, 0, 0, 0))
    sheet.alpha_composite(char, (ox, oy))
    x = CANVAS
    for p in props:
        sheet.alpha_composite(p, (x, FLOOR + 1 - p.height))
        print(f"Properti di sheet: x {x} sampai {x + p.width - 1}, y {FLOOR + 1 - p.height} sampai {FLOOR}")
        x += p.width + gap
    os.makedirs(os.path.dirname(a.out_sheet) or ".", exist_ok=True)
    sheet.save(a.out_sheet)
    print(f"Karakter {char.width} x {char.height} di kolom {ox} sampai {ox + char.width - 1}, baris {oy} sampai {FLOOR}")
    print(f"Tulis {a.out_base} dan {a.out_sheet} ({sheet_w} x {CANVAS})")


if __name__ == "__main__":
    main()
