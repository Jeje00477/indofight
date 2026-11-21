#!/usr/bin/env python3
"""Pemeriksa sprite IndoFight.

Memeriksa satu PNG (sprite tunggal atau sprite sheet horizontal):
  1. Semua piksel tidak transparan memakai warna dari palet terkunci.
  2. Tidak ada piksel setengah transparan (alpha selain 0 dan 255).
  3. Untuk sprite sheet: lebar habis dibagi lebar frame, tidak ada frame kosong.
  4. Garis kaki (baris piksel terbawah yang terisi) sama di semua frame.
  5. Posisi tengah kaki tidak bergeser jauh antar frame.
  6. Untuk file yang sudah diperbesar: setiap blok NxN berwarna seragam.

Contoh:
  python3 tools/validate_sprite.py art/characters/emak-emak/emak-emak_idle_sheet.png \
      --palette art/palettes/emak-emak.hex --frame 160 --floor 150
  python3 tools/validate_sprite.py file.png --palette p.hex --fix-palette
  python3 tools/validate_sprite.py splash_4x.png --scale 4

Kode keluar 0 = lolos, 1 = gagal, 2 = salah pemakaian.
Untuk efek asap/cahaya yang memang setengah transparan, tambahkan --allow-alpha.
"""
import argparse
import sys
from collections import Counter

try:
    from PIL import Image
except ImportError:
    print("Butuh Pillow: pip install pillow")
    sys.exit(2)

from palette import load_palette, nearest  # noqa: E402


def main():
    ap = argparse.ArgumentParser(description="Pemeriksa sprite IndoFight")
    ap.add_argument("png")
    ap.add_argument("--palette", help="file .hex palet terkunci")
    ap.add_argument("--frame", type=int, help="lebar frame untuk sprite sheet (mis. 160)")
    ap.add_argument("--frame-height", type=int, help="tinggi frame bila beda dari tinggi gambar")
    ap.add_argument("--floor", type=int, help="baris garis kaki yang diharapkan (mis. 150)")
    ap.add_argument("--floor-tolerance", type=int, default=1)
    ap.add_argument("--center-tolerance", type=int, default=6, help="pergeseran tengah kaki maksimal (px)")
    ap.add_argument("--scale", type=int, help="cek file yang sudah diperbesar N kali")
    ap.add_argument("--allow-alpha", action="store_true", help="izinkan piksel setengah transparan")
    ap.add_argument("--fix-palette", action="store_true", help="simpan salinan *_fixed.png dengan warna dipaskan ke palet")
    a = ap.parse_args()

    im = Image.open(a.png).convert("RGBA")
    W, H = im.size
    px = im.load()
    fails, warns = [], []
    print(f"File: {a.png}  ukuran {W} x {H}")

    # 2. alpha
    semi = sum(1 for y in range(H) for x in range(W) if 0 < px[x, y][3] < 255)
    if semi:
        (warns if a.allow_alpha else fails).append(f"{semi} piksel setengah transparan")

    # 1. palet
    if a.palette:
        pal = load_palette(a.palette)
        pset = set(pal)
        bad = Counter()
        for y in range(H):
            for x in range(W):
                r, g, b, al = px[x, y]
                if al > 0 and (r, g, b) not in pset:
                    bad[(r, g, b)] += 1
        if bad:
            total = sum(bad.values())
            top = ", ".join("#%02x%02x%02x (%d)" % (c + (n,)) for c, n in bad.most_common(5))
            fails.append(f"{total} piksel di luar palet, {len(bad)} warna asing. Terbanyak: {top}")
            if a.fix_palette:
                out = im.copy()
                op = out.load()
                cache = {}
                for y in range(H):
                    for x in range(W):
                        r, g, b, al = op[x, y]
                        if al == 0:
                            continue
                        c = (r, g, b)
                        if c not in pset:
                            cache.setdefault(c, nearest(c, pal))
                            nr, ng, nb = cache[c]
                            op[x, y] = (nr, ng, nb, 255 if al >= 128 else 0)
                        elif 0 < al < 255:
                            op[x, y] = (r, g, b, 255 if al >= 128 else 0)
                dst = a.png[:-4] + "_fixed.png"
                out.save(dst)
                print(f"Salinan dengan warna dipaskan ke palet: {dst} (periksa secara visual)")

    # 6. skala
    if a.scale and a.scale > 1:
        n = a.scale
        if W % n or H % n:
            fails.append(f"ukuran {W} x {H} tidak habis dibagi {n}")
        else:
            broken = 0
            for by in range(0, H, n):
                for bx in range(0, W, n):
                    c = px[bx, by]
                    if any(px[bx + i, by + j] != c for j in range(n) for i in range(n)):
                        broken += 1
            if broken:
                fails.append(f"{broken} blok {n}x{n} tidak seragam: perbesaran bukan nearest-neighbor")

    # 3-5. frame
    fw = a.frame or W
    fh = a.frame_height or H
    if W % fw:
        fails.append(f"lebar {W} tidak habis dibagi lebar frame {fw}")
    else:
        nf = W // fw
        rows = H // fh if H % fh == 0 else 1
        feet, centers = [], []
        empty = []
        for r in range(rows):
            for i in range(nf):
                x0, y0 = i * fw, r * fh
                bottom = None
                for y in range(y0 + fh - 1, y0 - 1, -1):
                    xs = [x for x in range(x0, x0 + fw) if px[x, y][3] > 0]
                    if xs:
                        bottom = y - y0
                        # tengah kaki dari 3 baris terbawah
                        foot = []
                        for yy in range(y, max(y0, y - 3), -1):
                            foot += [x - x0 for x in range(x0, x0 + fw) if px[x, yy][3] > 0]
                        centers.append(sum(foot) / len(foot))
                        break
                if bottom is None:
                    empty.append(r * nf + i + 1)
                else:
                    feet.append(bottom)
        print(f"Frame: {nf * rows} ({fw} x {fh})")
        if empty:
            fails.append(f"frame kosong: {empty}")
        if feet:
            print(f"Garis kaki per frame: {feet}")
            if a.floor is not None:
                off = [f for f in feet if abs(f - a.floor) > a.floor_tolerance]
                if off:
                    fails.append(f"{len(off)} frame garis kakinya tidak di baris {a.floor} (+/-{a.floor_tolerance})")
            elif max(feet) - min(feet) > a.floor_tolerance:
                warns.append(f"garis kaki berbeda antar frame ({min(feet)} sampai {max(feet)}); boleh untuk lompat/terlempar")
        if len(centers) > 1:
            drift = max(centers) - min(centers)
            print(f"Pergeseran tengah kaki: {drift:.1f} px")
            if drift > a.center_tolerance:
                warns.append(f"tengah kaki bergeser {drift:.1f} px; cek pivot (wajar untuk dash, jump, knockdown)")

    for w in warns:
        print(f"PERINGATAN: {w}")
    for f_ in fails:
        print(f"GAGAL: {f_}")
    if fails:
        sys.exit(1)
    print("LOLOS")
    sys.exit(0)


if __name__ == "__main__":
    main()
