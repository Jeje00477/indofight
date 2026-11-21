# Rencana Vertical Slice dan Prompt Siap Tempel

Target vertical slice: 2 karakter (Emak-Emak vs Abang Ojol) bertarung di 1 stage (Gang Sempit) dengan HUD, efek pukulan, dan suara, dan sudah terasa seperti game jadi. Karakter lain baru dikerjakan setelah ini lolos.

Kenapa dua karakter ini: Emak-Emak berjangkauan panjang dan lambat, Abang Ojol cepat dan suka serangan balik. Kontras ini langsung menguji jarak, kecepatan, dan frame data. Gang Sempit juga stage "rumah" mereka.

Ada 75 baris di `production/asset_manifest.csv` dengan kolom `vertical_slice = ya` (setelah keputusan di `docs/decisions.md`: Walk Backward dihapus, `ui_round_dots` ditambahkan).

## Urutan kerja

Setiap tahap punya prompt yang bisa langsung ditempel ke asisten AI. Jalankan satu tahap, periksa hasilnya, baru lanjut.

### Tahap 0: Cek alat

```
Baca docs/ATURAN-PROYEK.md. Lalu cek: (1) server MCP spritecook, godot, dan aseprite terhubung, (2) saldo kredit SpriteCook, (3) jalankan list_generation_models dan sebutkan model pixel art termurah serta biaya per gambar. Hitung perkiraan biaya untuk semua baris vertical_slice=ya di production/asset_manifest.csv. Jangan generate apa pun dulu.
```

### Tahap 1: Kunci desain Emak-Emak

```
Pakai skill indofight-art-rules. Kerjakan art/prompts/characters/emak-emak.md bagian 1 saja: unggah referensi art/reference/characters/emak-emak.png, simpan asset_id-nya, lalu generate 4 variasi gambar dasar dengan parameter di lembar itu. Tampilkan keempatnya diperbesar 4x berdampingan, beri nilai tiap variasi terhadap kunci visual di bagian 0, dan tunggu saya memilih.
```

Setelah memilih:

```
Pakai variasi nomor <N>. Rapikan di Aseprite: paskan ke palet art/palettes/emak-emak.hex, pastikan kaki di baris 150 dan tengah di kolom 80, buang piksel noise. Jalankan validator sampai lolos, unggah ulang sebagai emak-emak_base, catat asset_id di production/spritecook-assets.json, dan ubah status di manifest.
```

### Tahap 2: Animasi inti Emak-Emak (6 gerakan dulu)

```
Dari asset_id emak-emak_base, buat animasi idle, walk_forward, light_punch, heavy_punch, hit, dan block sesuai art/prompts/characters/emak-emak.md bagian 4. Satu job per animasi, parameter persis. Unduh sprite sheet-nya, jalankan validator dengan --frame 160 --floor 150, lalu tampilkan hasilnya sebagai GIF 4x supaya saya bisa menilai gerakannya. Laporkan frame mana yang desainnya berubah.
```

### Tahap 3: Ulangi tahap 1 dan 2 untuk Abang Ojol

Prompt sama, ganti nama karakter.

### Tahap 4: Stage Gang Sempit

```
Kerjakan art/prompts/stages/gang.md. Mulai dari Background bagian kiri, tampilkan, dan tunggu persetujuan saya. Setelah disetujui, ekstrak paletnya ke art/palettes/stage-gang.hex dengan tools/extract_palette.py, lalu lanjutkan bagian kanan, skybox, lantai tile, dan foreground memakai palet dan referensi yang sama. Susun preview 480x270 semua layer dengan dua sprite idle Emak-Emak dan Abang Ojol di garis lantai baris 238.
```

### Tahap 5: HUD dan efek inti

```
Pakai skill spritecook-build-ui-kits untuk membuat konsep HUD dari art/prompts/ui-vfx.md, lalu ekstrak komponen yang vertical_slice=ya di manifest. Setelah itu buat VFX vfx_hitspark_blunt, vfx_hitspark_slash, vfx_blockspark, dan vfx_dash_dust. Validasi semuanya (pakai --allow-alpha untuk efek).
```

### Tahap 6: Proyek Godot dan kombat

```
Buat proyek Godot 4 di folder game/ dengan pengaturan engine/godot/project_settings.md. Pakai skill godot-genre-fighting dan spritecook-use-assets-in-godot. Bangun: state machine petarung, frame data per serangan sebagai Resource, hitbox/hurtbox yang bisa ditampilkan dengan F1, hitstop, getaran layar, kilatan putih saat kena, input buffer, HUD dengan HP, energi, dan timer 99. Pakai aset Emak-Emak, Abang Ojol, dan stage Gang. Jalankan game lewat Godot MCP, perbaiki semua error, lalu jelaskan cara memainkannya.
```

### Tahap 7: Suara

```
Pakai skill sound-effects ElevenLabs. Buat SFX yang vertical_slice=ya dari audio/audio-list.md, 2 variasi untuk sfx_hit_light dan sfx_hit_heavy. Pasang di game: pukulan, block, ayunan meleset, dan K.O.
```

### Tahap 8: Penilaian vertical slice

Mainkan 10 ronde, lalu nilai sendiri:
- [ ] Setiap pukulan terasa "kena" (hitstop, efek, suara)
- [ ] Bisa membedakan serangan ringan dan berat hanya dari animasinya
- [ ] Kedua karakter terbaca jelas di depan background
- [ ] Tidak ada sprite yang bergetar atau bergeser saat ganti animasi
- [ ] Teman yang mencoba tanpa penjelasan paham cara mainnya dalam 1 menit

Kalau semua tercentang, lanjut ke 8 karakter lain dengan pola tahap 1 sampai 3. Kalau belum, perbaiki dulu. Memperbaiki di tahap ini jauh lebih murah daripada setelah 10 karakter jadi.
