"""Alat palet bersama untuk skrip di tools/: baca palet .hex dan paskan warna ke palet.

Semua skrip memakai jarak warna yang sama, supaya satu warna selalu dipaskan ke warna
palet yang sama, di skrip mana pun.
"""
import sys


def load_palette(path):
    cols = []
    with open(path) as f:
        for line in f:
            s = line.strip().lstrip("#")
            if len(s) == 6:
                cols.append(tuple(int(s[i:i + 2], 16) for i in (0, 2, 4)))
    if not cols:
        print(f"Palet kosong atau format salah: {path}")
        sys.exit(2)
    return cols


def dist(a, b):
    """Jarak warna kuadrat yang mendekati persepsi mata (rumus redmean)."""
    rm = (a[0] + b[0]) / 2
    dr, dg, db = a[0] - b[0], a[1] - b[1], a[2] - b[2]
    return (2 + rm / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rm) / 256) * db * db


def nearest(c, pal):
    return min(pal, key=lambda p: dist(p, c))
