#!/usr/bin/env python3
"""Uji kecil untuk alat aset. Jalankan: python tools/test_tools.py

Membuat sprite palsu di folder sementara, lalu memastikan validate_sprite.py menolak
sprite yang salah dan upscale.py tidak menimpa gambar asli.
"""
import os
import subprocess
import sys
import tempfile

from PIL import Image

TOOLS = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, TOOLS)
from palette import nearest  # noqa: E402

PAL = [(0x20, 0x18, 0x30), (0xdc, 0xa4, 0x83), (0xba, 0x86, 0x6a)]


def run(script, *args):
    return subprocess.run([sys.executable, os.path.join(TOOLS, script), *args],
                          capture_output=True, text=True).returncode


def sprite(path, color=PAL[1], foot_row=150, alpha=255):
    im = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
    for y in range(foot_row - 100, foot_row + 1):
        for x in range(70, 91):
            im.putpixel((x, y), color + (alpha,))
    im.save(path)
    return path


def main():
    with tempfile.TemporaryDirectory() as d:
        pal = os.path.join(d, "p.hex")
        with open(pal, "w") as f:
            f.write("\n".join("%02x%02x%02x" % c for c in PAL))
        check = ("--palette", pal, "--frame", "160", "--floor", "150")

        assert run("validate_sprite.py", sprite(os.path.join(d, "ok.png")), *check) == 0, "sprite benar harus lolos"
        assert run("validate_sprite.py", sprite(os.path.join(d, "warna.png"), color=(199, 221, 1)), *check) == 1, \
            "warna di luar palet harus gagal"
        assert run("validate_sprite.py", sprite(os.path.join(d, "kaki.png"), foot_row=140), *check) == 1, \
            "kaki di baris 140 harus gagal"
        assert run("validate_sprite.py", sprite(os.path.join(d, "alpha.png"), alpha=128), *check) == 1, \
            "piksel setengah transparan harus gagal"

        # --fix-palette memakai aturan warna yang sama dengan pipeline (palette.nearest).
        bad = sprite(os.path.join(d, "fix.png"), color=(199, 221, 1))
        run("validate_sprite.py", bad, "--palette", pal, "--fix-palette")
        got = Image.open(bad[:-4] + "_fixed.png").convert("RGBA").getpixel((80, 100))[:3]
        assert got == nearest((199, 221, 1), PAL), f"fix-palette memberi {got}"

        # upscale --out ke folder sumber harus menolak dan tidak menyentuh file.
        src = os.path.join(d, "up")
        os.makedirs(src)
        sprite(os.path.join(src, "a.png"))
        assert run("upscale.py", src, "--out", src) != 0, "upscale ke folder sumber harus ditolak"
        assert Image.open(os.path.join(src, "a.png")).size == (160, 160), "gambar asli tertimpa"
    print("tools: semua uji lolos")


if __name__ == "__main__":
    main()
