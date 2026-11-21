#!/usr/bin/env python3
"""Potong gambar dasar menjadi bagian tubuh untuk rig Skeleton2D (docs/decisions.md no. 9).

Masukan: file cut.json yang berisi daftar bagian. Tiap bagian punya:
  name      nama bagian dan nama tulang
  parent    tulang induk ("hip" untuk tulang akar)
  pivot     [x, y] titik sendi di koordinat sheet (bahu, siku, lutut, dan seterusnya)
  end       [x, y] ujung tulang, dipakai untuk menghitung arah diam bagian itu
  z         urutan gambar, kecil di belakang
  polygon   daftar titik yang melingkupi piksel bagian ini. Piksel yang masuk beberapa
            poligon menjadi milik bagian yang ditulis lebih dulu.
  joint     radius tumpang-tindih di sekitar pivot. Bagian ini dan induknya saling
            menyalin piksel di lingkaran itu, supaya tidak ada celah saat sendi ditekuk.
  extra     {"from": bagian, "polygon": [...]}: salin piksel bagian lain yang ada di dalam
            poligon ini. Dipakai untuk sendi lebar seperti pinggang, supaya badan atas dan
            bawah saling menutupi saat menekuk.
  pad_top   jumlah baris tambahan di atas, hasil mengulang baris teratas (untuk bagian
            yang pangkalnya tertutup bagian lain, misalnya paha di balik jaket).
  attach    [x, y] titik di bagian induk tempat bagian ini dipasang, untuk properti yang
            digambar terpisah dari badan (sapu di tangan).
  (di luar daftar bagian) "meshes": bagian yang digabung jadi satu mesh lentur, dan
            "hidden": bagian yang tulangnya dipakai tetapi gambarnya tidak ditampilkan.
  extend_up {"from": bagian, "rows": n}: bagian buatan yang tidak ada di gambar, dibuat
            dengan mengulang baris teratas bagian lain ke atas (paha di balik daster).

Keluaran: satu PNG per bagian, rig.json untuk pembangun rig Godot, dan gambar periksa.

Contoh:
  python tools/cut_parts.py art/characters/emak-emak/rig/cut.json
"""
import argparse
import json
import math
import os

from PIL import Image

DEBUG_COLORS = [
    (230, 60, 60), (60, 200, 90), (70, 120, 240), (240, 200, 50), (220, 90, 220), (60, 210, 220),
    (250, 140, 40), (150, 110, 250), (130, 220, 60), (240, 110, 150), (110, 110, 110), (200, 200, 200),
]


# Tekstur bagian disimpan diperbesar dengan Scale3x (dua kali = 9x). Di game tekstur itu
# digambar 1/9, jadi saat diam hasilnya persis gambar aslinya (titik tengah tiap blok 9 x 9
# selalu warna asli), tetapi saat bagian diputar tepinya diambil dari versi yang sudah
# dihaluskan dan tidak robek-robek. Ini cara rotasi pixel art (RotSprite): tetap piksel keras
# dari palet yang sama, tanpa anti-aliasing.
TEX_PASSES = 2
TEX_SCALE = 3 ** TEX_PASSES
CLEAR = (0, 0, 0, 0)


def scale3x(im):
    """Perbesar 3x dengan Scale3x (AdvMAME3x). Hanya menyalin warna yang sudah ada."""
    w, h = im.size
    src = im.load()

    def at(x, y):
        if 0 <= x < w and 0 <= y < h:
            c = src[x, y]
            return c if c[3] else CLEAR
        return CLEAR

    out = Image.new("RGBA", (w * 3, h * 3), CLEAR)
    op = out.load()
    for y in range(h):
        for x in range(w):
            a, b, c = at(x - 1, y - 1), at(x, y - 1), at(x + 1, y - 1)
            d, e, f = at(x - 1, y), at(x, y), at(x + 1, y)
            g, hh, i = at(x - 1, y + 1), at(x, y + 1), at(x + 1, y + 1)
            cell = [e] * 9
            if b != hh and d != f:
                cell[0] = d if d == b else e
                cell[1] = b if (d == b and e != c) or (b == f and e != a) else e
                cell[2] = f if b == f else e
                cell[3] = d if (d == b and e != g) or (d == hh and e != a) else e
                cell[5] = f if (b == f and e != i) or (hh == f and e != c) else e
                cell[6] = d if d == hh else e
                cell[7] = hh if (d == hh and e != i) or (hh == f and e != g) else e
                cell[8] = f if hh == f else e
            for k in range(9):
                op[x * 3 + k % 3, y * 3 + k // 3] = cell[k]
    return out


def save_texture(im, path):
    """Simpan tekstur bagian dalam ukuran TEX_SCALE kali."""
    for _ in range(TEX_PASSES):
        im = scale3x(im)
    im.save(path)


def inside(poly, x, y):
    """Titik tengah piksel (x + 0.5, y + 0.5) ada di dalam poligon?"""
    px, py = x + 0.5, y + 0.5
    hit = False
    n = len(poly)
    for i in range(n):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % n]
        if (y1 > py) != (y2 > py) and px < (x2 - x1) * (py - y1) / (y2 - y1) + x1:
            hit = not hit
    return hit


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cut_json")
    ap.add_argument("--debug", help="simpan gambar periksa kepemilikan piksel (4x)")
    a = ap.parse_args()

    with open(a.cut_json, encoding="utf-8") as f:
        cfg = json.load(f)
    root = os.path.dirname(os.path.abspath(a.cut_json))
    project = os.path.abspath(os.path.join(root, "..", "..", "..", ".."))
    sheet = Image.open(os.path.join(root, cfg["sheet"])).convert("RGBA")
    W, H = sheet.size
    src = sheet.load()
    out_dir = os.path.join(project, cfg["out_dir"])
    os.makedirs(os.path.join(out_dir, "parts"), exist_ok=True)
    origin = cfg["origin"]

    parts = cfg["parts"]
    by_name = {p["name"]: p for p in parts}

    # 1. Kepemilikan piksel: poligon pertama yang memuat piksel itu menang.
    owner = {}
    for y in range(H):
        for x in range(W):
            if src[x, y][3] == 0:
                continue
            for p in parts:
                if "polygon" in p and inside(p["polygon"], x, y):
                    owner[(x, y)] = p["name"]
                    break
    lost = [xy for xy in ((x, y) for y in range(H) for x in range(W)) if src[xy][3] and xy not in owner]
    if lost:
        print(f"PERINGATAN: {len(lost)} piksel tidak masuk bagian mana pun, contoh {lost[:5]}")

    # 2. Piksel tiap bagian, dalam koordinat sheet.
    pixels = {p["name"]: {} for p in parts}
    for (x, y), name in owner.items():
        pixels[name][(x, y)] = src[x, y]

    # 3. Bagian buatan dan baris tambahan.
    for p in parts:
        ext = p.get("extend_up")
        if ext:
            base = pixels[ext["from"]]
            top = min(y for _, y in base)
            # Pakai baris ketiga dari atas: baris teratas biasanya garis tepi atau bayangan gelap.
            row = top + min(3, max(y for _, y in base) - top)
            # Dimiringkan dari lutut ke pangkal paha, supaya pangkalnya tetap di dalam badan.
            lean = p["pivot"][0] - p["end"][0]
            for (x, y), c in list(base.items()):
                if y == row:
                    for k in range(ext["rows"] + 1):
                        pixels[p["name"]][(x + round(lean * k / ext["rows"]), top - k)] = c
        pad = p.get("pad_top", 0)
        if pad:
            mine = pixels[p["name"]]
            top = min(y for _, y in mine)
            # Pakai baris kedua dari atas: baris teratas biasanya garis tepi gelap.
            row = top + min(2, max(y for _, y in mine) - top)
            for (x, y), c in list(mine.items()):
                if y == row:
                    for k in range(1, pad + 1):
                        mine.setdefault((x, top - k), c)

    # 4. Tumpang-tindih di sendi.
    snapshot = {n: dict(px) for n, px in pixels.items()}
    for p in parts:
        extra = p.get("extra")
        if extra:
            for (x, y), c in snapshot[extra["from"]].items():
                if inside(extra["polygon"], x, y):
                    pixels[p["name"]].setdefault((x, y), c)
    for p in parts:
        r = p.get("joint", 0)
        parent = p.get("parent")
        if not r or parent not in by_name:
            continue
        cx, cy = p["pivot"]
        for a_name, b_name in ((p["name"], parent), (parent, p["name"])):
            for (x, y), c in snapshot[b_name].items():
                if math.hypot(x + 0.5 - cx, y + 0.5 - cy) <= r:
                    pixels[a_name].setdefault((x, y), c)

    # 5. Simpan PNG dan rig.json.
    rig = {"name": cfg["name"], "origin": origin, "tex_scale": TEX_SCALE, "bones": []}
    for p in parts:
        px = pixels[p["name"]]
        if not px:
            raise SystemExit(f"Bagian {p['name']} kosong: periksa poligonnya.")
        x0 = min(x for x, _ in px)
        y0 = min(y for _, y in px)
        x1 = max(x for x, _ in px)
        y1 = max(y for _, y in px)
        im = Image.new("RGBA", (x1 - x0 + 1, y1 - y0 + 1), (0, 0, 0, 0))
        ip = im.load()
        for (x, y), c in px.items():
            ip[x - x0, y - y0] = c
        rel = f"parts/{p['name']}.png"
        save_texture(im, os.path.join(out_dir, rel))
        pivot = p["pivot"]
        parent = p.get("parent", "hip")
        parent_pivot = by_name[parent]["pivot"] if parent in by_name else cfg["hip"]
        end = p.get("end", pivot)
        # Properti digambar terpisah di sheet: "attach" adalah titik di induk tempat ia dipasang.
        anchor = p.get("attach", pivot)
        rig["bones"].append({
            "name": p["name"],
            "parent": parent,
            "texture": rel,
            "z": p["z"],
            # Posisi tulang relatif ke tulang induk, dan letak sudut kiri atas gambar relatif ke tulang.
            "position": [anchor[0] - parent_pivot[0], anchor[1] - parent_pivot[1]],
            "sprite_offset": [x0 - pivot[0], y0 - pivot[1]],
            "length": round(math.hypot(end[0] - pivot[0], end[1] - pivot[1]), 2),
            # Arah diam: 0 = lurus ke bawah, positif = ke depan (kanan).
            "rest_dir": round(math.degrees(math.atan2(end[0] - pivot[0], end[1] - pivot[1])), 2),
            "size": [im.width, im.height],
        })
        print(f"  {p['name']:14s} {im.width:3d} x {im.height:3d}  pivot {pivot}  arah diam {rig['bones'][-1]['rest_dir']:7.2f}")
    rig["hip"] = [cfg["hip"][0] - origin[0], cfg["hip"][1] - origin[1]]

    # 6. Mesh lentur: beberapa bagian digabung jadi satu tekstur yang ditekuk oleh tulang,
    #    supaya siku, lutut, dan rok tidak pernah terlihat putus.
    skinned = set(cfg.get("hidden", []))
    rig["meshes"] = []
    for m in cfg.get("meshes", []):
        px = {}
        for part_name in m["parts"]:
            px.update(pixels[part_name])
            skinned.add(part_name)
        x0 = min(x for x, _ in px)
        y0 = min(y for _, y in px)
        x1 = max(x for x, _ in px)
        y1 = max(y for _, y in px)
        im = Image.new("RGBA", (x1 - x0 + 1, y1 - y0 + 1), (0, 0, 0, 0))
        ip = im.load()
        for (x, y), c in px.items():
            ip[x - x0, y - y0] = c
        rel = "parts/%s.png" % m["name"]
        save_texture(im, os.path.join(out_dir, rel))
        rig["meshes"].append({
            "name": m["name"], "mode": m["mode"], "texture": rel, "z": m["z"],
            "bones": m.get("bones", m["parts"]),
            # Sudut kiri atas tekstur di ruang rig (relatif ke titik kaki).
            "origin": [x0 - origin[0], y0 - origin[1]], "size": [im.width, im.height],
        })
        print(f"  mesh {m['name']:9s} {im.width:3d} x {im.height:3d}  tulang {', '.join(rig['meshes'][-1]['bones'])}")
    for b in rig["bones"]:
        b["sprite"] = b["name"] not in skinned
    with open(os.path.join(out_dir, "rig.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(rig, f, indent=2)
        f.write("\n")
    print(f"{len(parts)} bagian -> {out_dir}")

    if a.debug:
        dbg = Image.new("RGBA", (W, H), (40, 40, 50, 255))
        dp = dbg.load()
        idx = {p["name"]: i for i, p in enumerate(parts)}
        for (x, y), name in owner.items():
            r, g, b, _ = src[x, y]
            cr, cg, cb = DEBUG_COLORS[idx[name] % len(DEBUG_COLORS)]
            dp[x, y] = ((r + cr * 2) // 3, (g + cg * 2) // 3, (b + cb * 2) // 3, 255)
        for xy in lost:
            dp[xy] = (255, 0, 255, 255)
        for p in parts:
            x, y = int(p["pivot"][0]), int(p["pivot"][1])
            if 0 <= x < W and 0 <= y < H:
                dp[x, y] = (255, 255, 255, 255)
        dbg.resize((W * 4, H * 4), Image.NEAREST).save(a.debug)


if __name__ == "__main__":
    main()
