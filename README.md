# IndoFight

Game fighting 2D pixel art dengan 10 karakter satire Indonesia dan 6 stage, dibuat di Godot 4. Desain lengkap ada di `docs/GDD-IndoFight.md`.

## Mulai

1. Pasang Godot 4.7 (versi standar, tanpa .NET), Git, dan Python 3.10+ dengan `pip install pillow`.
2. Baca `docs/ATURAN-PROYEK.md`: spesifikasi teknis, aturan seni, dan alur kerja aset. Keputusan desain ada di `docs/decisions.md`.
3. Buka folder `game/` di Godot lalu jalankan (F5).
4. Sebelum membuka Pull Request, jalankan tes:
   - `godot --headless --path game -s res://tests/sim_test.gd`
   - `python tools/test_tools.py`

## Alur kerja tim

- `main` selalu dalam keadaan bisa jalan. Jangan push langsung ke `main`.
- Satu pekerjaan = satu branch (`fitur/stage-gang`, `art/emak-emak-idle`, `fix/lompat-ganda`), lalu buka Pull Request dan minta satu orang mengecek.
- Jangan dua orang mengedit scene `.tscn` atau PNG yang sama bersamaan; bagi tugas per karakter atau per stage.
- `production/asset_manifest.csv` berisi daftar 362 aset dengan status, dipakai untuk melacak progres. `production/vertical-slice.md` berisi urutan kerja vertical slice.

## Isi repo

| Folder / file | Isi |
| --- | --- |
| `art/palettes/` | Palet terkunci 10 karakter (16 sampai 23 warna) dan stage DPR, format .hex dan .gpl, plus `_preview_palettes.png` |
| `art/reference/` | Gambar referensi asli dan potongan per karakter (frame bermasalah sudah dibuang) |
| `art/prompts/characters/` | 10 lembar prompt: gambar dasar, splash, ikon, 19 animasi, properti dan efek khusus, dalam JSON siap pakai untuk SpriteCook |
| `art/prompts/stages/` | 6 stage + latar menu, tiap layer parallax dengan cara mengakali batas lebar 512 px |
| `art/prompts/ui-vfx.md` | Konsep UI kit HUD, 20 komponen UI, 13 efek visual |
| `audio/audio-list.md` | 25 SFX dengan prompt ElevenLabs dan brief musik per stage |
| `game/` | Proyek Godot: simulasi pertarungan (`scripts/sim/`), data serangan (`data/`), tes (`tests/`) |
| `tools/validate_sprite.py` | Cek palet, transparansi, garis kaki, pivot, perbesaran 4x; bisa memaskan warna ke palet |
| `tools/normalize_sheet.py` | Seragamkan frame hasil generator ke 160 x 160 dengan kaki di baris 150, gerakan tetap terjaga |
| `tools/upscale.py` | Perbesar nearest-neighbor kelipatan bulat |
| `tools/palette.py` | Baca palet dan paskan warna, dipakai bersama semua skrip `tools/` |
| `tools/test_tools.py` | Uji kecil untuk validator dan upscale |
| `tools/extract_palette.py` | Ambil palet dari gambar yang sudah disetujui |
| `tools/_generators/` | Skrip pembuat lembar prompt dan manifest, bila ingin mengubah data lalu membuat ulang |
| `engine/` | Pengaturan Godot 4 dan catatan Unity |
| `docs/` | GDD, aturan proyek, keputusan desain, dan daftar kredit lisensi |

## Angka kunci

- Resolusi 480 x 270, ekspor 4x
- Frame karakter 160 x 160, kaki di baris 150
- 10 karakter x 19 animasi = 190 sprite sheet, sekitar 1.080 frame
- Batas SpriteCook: gambar maksimal 512 px, animasi 2 sampai 16 frame genap

## Butir yang belum diputuskan

Lihat GDD bagian 11.2 dan bagian "Catatan terbuka" di `docs/decisions.md`.
