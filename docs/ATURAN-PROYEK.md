# IndoFight: Aturan Proyek

IndoFight adalah game fighting 2D pixel art dengan 10 karakter satire Indonesia dan 6 stage. Sumber kebenaran desain adalah GDD di `docs/GDD-IndoFight.md`. Bila aturan ini dan GDD berbeda, tanyakan dulu ke Jeje sebelum mengubah apa pun. Keputusan Jeje yang menutup butir terbuka GDD dicatat di `docs/decisions.md`; untuk butir yang tercantum di sana, file itu yang berlaku.

Bahasa kerja: catatan dalam Bahasa Indonesia. Prompt ke generator gambar dan suara ditulis dalam Bahasa Inggris.

## 1. Spesifikasi teknis (jangan diubah tanpa izin)

| Item | Nilai |
| --- | --- |
| Resolusi dasar game | 480 x 270, diperbesar tepat 4x ke 1920 x 1080 |
| Kanvas frame karakter | 160 x 160, karakter setinggi 96 sampai 112 px |
| Garis kaki karakter | baris piksel 150 di kanvas 160 x 160, tengah horizontal di kolom 80 |
| Garis lantai stage | baris piksel 238 dari 270 |
| Lebar stage | 960 px (4 layer parallax) |
| Splash art | 270 x 480, ekspor 4x |
| Ikon grid / HUD | 64 x 64 / 32 x 32, ekspor 4x |
| Frame rate logika | 60 tick per detik, tetap |
| Arah hadap sprite | kanan; arah kiri dibuat dengan flip di engine |
| Engine | Godot 4 (default). Untuk Unity, lihat `engine/unity/NOTES.md` |

## 2. Aturan seni wajib

1. Setiap karakter punya palet terkunci di `art/palettes/<nama>.hex`. Selalu kirim palet itu ke parameter `colors` SpriteCook, dan setiap sprite harus lolos `tools/validate_sprite.py`.
2. Satu karakter = satu gambar dasar canonical. Semua animasi dibuat dari `asset_id` gambar dasar yang sama. Jangan pernah generate gambar baru per animasi.
3. Kunci visual tiap karakter ada di `art/prompts/characters/<nama>.md` bagian 0. Kunci visual mengalahkan gambar referensi bila berbeda.
4. Perbesaran hanya kelipatan bulat dengan nearest-neighbor (`tools/upscale.py`). Tidak boleh filter bilinear atau skala pecahan.
5. Tanpa anti-aliasing dan tanpa piksel setengah transparan di tepi sprite, kecuali efek asap, cahaya, dan glow.
6. Satu ukuran piksel untuk semua aset. Jangan mencampur aset yang digambar di resolusi berbeda.
7. Pakai mode pixel SpriteCook (`pixel: true`). Jangan pakai mode detailed untuk sprite game.
8. Tanpa logo atau nama merek nyata (ojek online, Tupperware, dan lain-lain). Jenderal Gemoy selalu karikatur, bukan potret realistis.

## 3. Alur kerja satu aset

1. Baca lembar prompt aset itu di `art/prompts/`.
2. Cek `production/spritecook-assets.json` apakah `asset_id` referensi atau gambar dasar sudah ada. Jangan buat ulang yang sudah ada.
3. Untuk batch, cek saldo kredit SpriteCook dan sebutkan perkiraan biayanya ke Jeje sebelum mulai.
4. Generate dengan parameter persis dari lembar prompt. Ganti placeholder `<ASSET_ID_...>` dengan asset_id dari manifest.
5. Unduh `sprite_url` atau `spritesheet_url` ke folder tujuan di `production/asset_manifest.csv`. Untuk sprite sheet karakter, seragamkan dulu ke frame 160 x 160 dengan `python tools/normalize_sheet.py <hasil.png> --frames <N> --out <file final>`. Tambahkan `--snap-floor` untuk animasi yang kakinya selalu menapak.
6. Jalankan `python tools/validate_sprite.py <file> --palette art/palettes/<nama>.hex`. Untuk sprite sheet karakter tambahkan `--frame 160 --floor 150`; untuk animasi lompat, terlempar, atau jatuh, hapus `--floor` (peringatan garis kaki wajar).
7. Gagal palet: jalankan dengan `--fix-palette`, lalu periksa hasilnya secara visual. Gagal hal lain: rapikan di Aseprite atau generate ulang.
8. Tampilkan hasil ke Jeje dalam ukuran 4x sebelum dianggap selesai. Jeje yang memutuskan lolos atau tidak.
9. Catat `asset_id` di `production/spritecook-assets.json` dan ubah status di `production/asset_manifest.csv` menjadi `review` atau `done`.

## 4. Aturan game feel (supaya terasa seperti game jadi)

- Data serangan (startup, active, recovery frame, damage, hitstun, blockstun, pushback) disimpan sebagai data, bukan ditulis langsung di kode, supaya bisa di-balance.
- Hitbox dan hurtbox terpisah dari sprite, bisa ditampilkan dengan tombol debug.
- Setiap pukulan yang kena memicu hitstop (berhenti sebentar beberapa frame), getaran layar kecil, kilatan putih di sprite yang terkena, efek hit spark, dan suara.
- Input buffer beberapa frame supaya kombo terasa responsif.
- Logika pertarungan berjalan di tick tetap 60 per detik dan deterministik, supaya rollback netcode bisa ditambahkan nanti.
- Ultimate yang tidak bisa diblok harus punya jeda peringatan yang jelas (GDD 11.1).

## 5. Struktur folder

```
art/palettes/          palet terkunci (.hex untuk SpriteCook, .gpl untuk Aseprite)
art/reference/         gambar referensi gaya, termasuk potongan per karakter
art/prompts/           lembar prompt siap pakai (karakter, stage, UI, VFX)
art/characters/<nama>/ hasil sprite karakter
art/stages/<kode>/     hasil layer stage
art/ui/, art/vfx/      hasil UI dan efek
audio/                 daftar audio, folder sfx/ dan music/
game/                  proyek Godot
production/            manifest aset, asset_id SpriteCook, rencana kerja
tools/                 skrip validasi, perbesar, ekstrak palet
engine/                pengaturan Godot dan catatan Unity
docs/                  GDD, aturan ini, keputusan desain, dan kredit lisensi
```

## 6. Penamaan file

`indofight_<kategori>_<nama>_<aset>.png`, huruf kecil tanpa spasi. Kolom `file` di `production/asset_manifest.csv` adalah nama final yang benar.

## 7. Larangan

- Jangan menambah fitur, karakter, atau aset di luar GDD tanpa diminta.
- Jangan menulis API key ke file, prompt, atau chat. Simpan kredensial di variabel lingkungan atau `.env` (tidak ikut repo).
- Jangan menimpa aset berstatus `done` tanpa izin.
- Jangan menganggap aset selesai hanya karena generator berhasil. Validator dan persetujuan Jeje wajib.
- Jangan push langsung ke `main`. Kerjakan di branch sendiri lalu buka Pull Request.
