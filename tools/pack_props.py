#!/usr/bin/env python3
"""Ubah render properti dari Blender menjadi sprite sheet berpalet terkunci (docs/decisions.md no. 23).

Masukan: folder hasil tools/blender/render_props.py.
Keluaran:
  game/props/<nama>.png                                        dipakai game
  art/characters/<pemilik>/props/indofight_char_<pemilik>_<kode>.png   nama sesuai manifest

Contoh:
  python tools/pack_props.py <folder render>
"""
import argparse
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette import load_palette, nearest  # noqa: E402

# Render Blender 3x ukuran game; pixelize membaca render ID di tengah tiap blok 3x3.
SS = 3

# nama render: (ukuran frame, jumlah frame, palet, pemilik, kode aset di manifest)
PROPS = {
    "bekal": ((32, 24), 8, "props-emak", "emak-emak", "tupperware"),
    "scooter": ((96, 64), 4, "props-emak", "emak-emak", "scooter"),
    "motor": ((96, 64), 4, "abang-ojol", "abang-ojol", "motor_bebek"),
}


class Snapper:
    def __init__(self, pal):
        self.pal = pal
        self.dark = min(pal, key=lambda c: 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2])
        self._near = {}
        self._darker = {}

    def near(self, c):
        if c not in self._near:
            self._near[c] = nearest(c, self.pal)
        return self._near[c]

    def darker(self, c):
        """Warna palet satu tingkat lebih gelap dari c, untuk garis di antara bagian tubuh."""
        if c not in self._darker:
            target = (c[0] * 0.5, c[1] * 0.5, c[2] * 0.5)
            self._darker[c] = nearest(target, self.pal)
        return self._darker[c]


def pixelize(color_path, id_path, snap, size):
    col = Image.open(color_path).convert("RGBA")
    ids = Image.open(id_path).convert("RGBA")
    pre = col.copy()
    px = pre.load()
    for y in range(pre.height):
        for x in range(pre.width):
            r, g, b, a = px[x, y]
            if a < 255:
                px[x, y] = (r * a // 255, g * a // 255, b * a // 255, a)
    w, h = size
    small = pre.resize((w, h), Image.BOX).load()
    idp = ids.load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    op = out.load()
    part = {}
    raw = {}
    for y in range(h):
        for x in range(w):
            r, g, b, a = small[x, y]
            if a < 128:
                continue
            c = (min(255, r * 255 // a), min(255, g * 255 // a), min(255, b * 255 // a))
            raw[(x, y)] = c
            ir, ig, ib, ia = idp[x * SS + 1, y * SS + 1]
            # Warna ID berkelipatan 17 (0 sampai 255 dalam 16 tingkat); dibulatkan supaya tahan selisih kecil.
            part[(x, y)] = ((ir + 8) // 17, (ig + 8) // 17, (ib + 8) // 17) if ia > 128 else None
    # Warna dirata-rata dengan tetangga di bagian tubuh yang sama sebelum dipaskan ke palet.
    # Tanpa ini, bidang yang warnanya di tengah dua warna palet menjadi bintik-bintik.
    for (x, y), c in raw.items():
        p = part[(x, y)]
        acc = [0, 0, 0]
        n = 0
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                q = (x + dx, y + dy)
                if q in raw and part[q] == p:
                    r2, g2, b2 = raw[q]
                    acc[0] += r2
                    acc[1] += g2
                    acc[2] += b2
                    n += 1
        op[x, y] = snap.near((acc[0] // n // 4 * 4, acc[1] // n // 4 * 4, acc[2] // n // 4 * 4)) + (255,)
    # Buang bintik: piksel yang warnanya beda dari mayoritas tetangganya ikut mayoritas,
    # supaya bayangan membentuk bidang rata, bukan derau.
    for _ in range(2):
        changes = []
        for (x, y), p in part.items():
            mine = op[x, y]
            count = {}
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1), (x + 1, y + 1), (x - 1, y - 1), (x + 1, y - 1), (x - 1, y + 1)):
                if part.get((nx, ny)) == p and (nx, ny) in part:
                    c = op[nx, ny]
                    count[c] = count.get(c, 0) + 1
            if count:
                best = max(count, key=count.get)
                if best != mine and count[best] >= 5 and count.get(mine, 0) <= 2:
                    changes.append((x, y, best))
        for x, y, c in changes:
            op[x, y] = c
    # Garis antarbagian: gelapkan piksel yang bersebelahan dengan bagian lain di kanan atau bawah.
    lines = []
    for (x, y), p in part.items():
        if p is None:
            continue
        for nx, ny in ((x + 1, y), (x, y + 1)):
            q = part.get((nx, ny))
            if q is not None and q != p:
                lines.append((x, y))
                break
    for x, y in lines:
        op[x, y] = snap.darker(op[x, y][:3]) + (255,)
    # Garis tepi siluet.
    edge = []
    for (x, y) in part:
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if (nx, ny) not in part:
                edge.append((x, y))
                break
    for x, y in edge:
        op[x, y] = snap.dark + (255,)
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("render_dir")
    ap.add_argument("--project", default=".")
    a = ap.parse_args()
    game_dir = os.path.join(a.project, "game", "props")
    os.makedirs(game_dir, exist_ok=True)
    for name, (size, count, palette, owner, code) in PROPS.items():
        first = os.path.join(a.render_dir, "%s_00_c.png" % name)
        if not os.path.exists(first):
            continue
        snap = Snapper(load_palette(os.path.join(a.project, "art", "palettes", palette + ".hex")))
        sheet = Image.new("RGBA", (size[0] * count, size[1]), (0, 0, 0, 0))
        for i in range(count):
            c = os.path.join(a.render_dir, "%s_%02d_c.png" % (name, i))
            sheet.paste(pixelize(c, c.replace("_c.png", "_id.png"), snap, size), (i * size[0], 0))
        sheet.save(os.path.join(game_dir, name + ".png"))
        art_dir = os.path.join(a.project, "art", "characters", owner, "props")
        os.makedirs(art_dir, exist_ok=True)
        art_path = os.path.join(art_dir, "indofight_char_%s_%s.png" % (owner, code))
        sheet.save(art_path)
        print("%s: %d frame %d x %d, palet %s -> %s" % (name, count, size[0], size[1], palette, art_path))


if __name__ == "__main__":
    main()
