# Keputusan Desain IndoFight

Catatan keputusan Jeje yang menutup butir terbuka di GDD atau mengubah lembar prompt. Baca file ini sebelum mengerjakan aset atau kombat. Bila file ini berbeda dengan GDD atau lembar prompt, file ini yang berlaku untuk butir yang tercantum di sini.

## 10 November 2026

| No | Keputusan | Menutup atau mengubah | Diterapkan di |
| --- | --- | --- | --- |
| 1 | Emak-Emak dikunci: helm abu-abu dan daster pink | GDD 11.2 "Kombinasi warna helm dan daster Emak-Emak" | `art/prompts/characters/emak-emak.md` bagian 0, `tools/_generators/gen_characters.py` |
| 2 | Properti Emak-Emak (Tupperware merah, motor merah, lampu sein oranye) memakai palet terpisah `props-emak`, 8 warna. Validasi properti memakai palet itu, bukan palet karakter | Lembar prompt Emak-Emak bagian 5 | `art/palettes/props-emak.hex` dan `.gpl`, lembar prompt bagian 5, kolom `catatan` manifest |
| 3 | Hitam murni `000000` dihapus dari semua palet. Garis tepi memakai warna tergelap yang tersisa di tiap palet | GDD 2 "garis tepi bukan hitam murni" | Semua `art/palettes/*.hex` dan `.gpl`, daftar `colors` di semua lembar prompt karakter |
| 4 | Walk Backward tidak digenerate. Engine memutar sheet Walk Forward secara terbalik | GDD 8.2 animasi no. 3 | 10 baris `*_walk_backward` dihapus dari manifest, lembar prompt karakter kini 18 animasi, `game/` |
| 5 | Kecepatan geser skybox 0,1x, sesuai GDD 7 | Lembar stage yang menulis 0,05x | `art/prompts/stages/*.md`, `tools/_generators/gen_stages.py`, `game/data/stages/gang.tres` |
| 6 | Pertarungan best of 3 (menang 2 ronde). Angka damage, health, dan cooldown berupa usulan awal dan disimpan sebagai resource data. `ui_round_dots` masuk vertical slice | GDD 11.2 "Jumlah ronde" dan "Lama cooldown skill dan angka damage" | `game/data/` (`.tres`), baris `ui_round_dots` di manifest |
| 7 | Hitstop memakai hitungan frame di simulasi, bukan `Engine.time_scale` | Skill `godot-genre-fighting` (`hit_stop_controller.gd` memakai time-scale) | `game/scripts/sim/fight_sim.gd` |

## 10 November 2026, rencana tanpa paket SpriteCook

Jeje tidak membeli paket SpriteCook. Saldo 40 kredit tier free adalah seluruh anggaran generator gambar.

| No | Keputusan | Menutup atau mengubah | Diterapkan di |
| --- | --- | --- | --- |
| 8 | 40 kredit hanya dipakai untuk gambar dasar Emak-Emak dan Abang Ojol. Pose berdiri netral, menghadap kanan, lengan dan kaki terpisah jelas supaya mudah dipotong. Biaya ditunjukkan dulu sebelum generate | Lembar prompt bagian 1 (pose "fighting stance", 4 variasi) dan bagian 2 sampai 5 (tidak digenerate) | Lihat keputusan 12 dan 13 |
| 9 | Animasi karakter dibuat dengan memotong gambar dasar menjadi bagian tubuh (kepala, badan, lengan atas dan bawah, kaki, properti) lewat skrip Python, lalu digerakkan di Godot dengan Skeleton2D dan AnimationPlayer: idle, jalan, lompat, pukul, tendang, block, kena hit, KO | GDD 8 dan 10.1 ("frame per frame, tidak memakai rigging tulang") dan keputusan 4 (Walk Backward tetap dari jalan yang diputar terbalik) | `tools/cut_parts.py`, `art/characters/*/rig/cut.json`, `game/tools/`, `game/characters/` |
| 10 | Efek dan UI dibuat dengan kode, bukan sprite | GDD 9.1 dan 9.2 sebagai aset gambar, `art/prompts/ui-vfx.md`, baris `ui_*` dan `vfx_*` di manifest | `game/scripts/fight_view.gd`, `hud.gd`, `menu.gd` |
| 11 | Game kotak-kotak diselesaikan dulu sebelum keputusan 8 dan 9 dikerjakan | Urutan di `production/vertical-slice.md` | `game/` |

Catatan untuk keputusan 9: GDD menolak rigging karena memutar potongan pixel art merusak bentuk piksel. Karena game digambar di 480 x 270 lalu diperbesar 4x, potongan yang diputar tetap berada di grid piksel yang sama, tetapi tepinya akan bergerigi pada sudut miring. Ini risiko yang diterima Jeje; nilai hasilnya setelah animasi idle pertama jadi.

Manifest sudah diperbarui untuk keputusan 8 sampai 16 pada 11 November 2026 (lihat "Hasil 11 November 2026").

## 11 November 2026

| No | Keputusan | Menutup atau mengubah | Diterapkan di |
| --- | --- | --- | --- |
| 12 | Gambar dasar memakai sudut pandang tiga perempat menghadap kanan, supaya keempat anggota badan terlihat dan bisa dipotong | Lembar prompt bagian 1 ("side view") dan keputusan 8 | `production/spritecook-assets.json`, `art/characters/*/indofight_char_*_base.png` |
| 13 | Gambar dasar dicoba dulu dengan GPT-Image-2 kualitas low (2 gambar, 4 kredit) dan ditunjukkan ke Jeje. Bila jelek, baru diulang dengan Nano Banana 2.1 (24 kredit) | Keputusan 8 (pilihan model) | GPT-Image-2 low dipakai; Nano Banana tidak diperlukan |
| 14 | Sisa kredit dipakai untuk satu gambar stage Gang Sempit bila cukup. Bila tidak cukup, stage dibuat dengan kode | Catatan terbuka "Stage Gang Sempit" | `tools/pixelize_stage.py`, `art/stages/gang/`, `game/stages/gang/`, `game/data/stages/gang.tres` |
| 15 | Dash, jongkok, skill, ultimate, menang, dan kalah ikut dibuat dengan rig Skeleton2D, sehingga total 14 animasi per karakter | Catatan terbuka "Animasi di luar daftar keputusan 9" | `game/tools/rig_poses.gd`, `game/characters/*/*_rig.tscn` |
| 16 | HUD: semua teks diperbesar, bar ultimate dipindah ke bawah health bar tiap pemain, tulisan COMBO dan notifikasi diberi animasi muncul, daftar kontrol dirapikan | GDD 5.3 (energy bar di kiri dan kanan bawah) | `game/scripts/hud.gd`, `menu.gd`, `ui_font.gd` |

## 13 November 2026, masukan Jeje setelah mencoba game

| No | Keputusan | Menutup atau mengubah | Diterapkan di |
| --- | --- | --- | --- |
| 17 | Animasi tidak boleh kaku: seluruh badan harus ikut bergerak, badan bisa menekuk, dan tendangan harus tinggi dan panjang | Pose pertama (hanya anggota badan yang bergerak) | `art/characters/*/rig/cut.json`, `tools/cut_parts.py`, `game/tools/rig_poses.gd`, `game/tools/build_rigs.gd` |
| 18 | Game dibuka dengan halaman pembuka dan menu utama tersendiri berlatar menarik, bukan menu yang menumpang di layar pertarungan | GDD 5.1 | `game/scripts/title_backdrop.gd`, `menu.gd`, `main.gd` |
| 19 | Daftar kontrol ditutup dengan tombol apa saja, bukan hanya F3, dan bisa dibuka dari menu utama serta menu jeda | Keputusan 16 (daftar kontrol) | `game/scripts/controls_panel.gd`, `main.gd` |

Cara keputusan 17 diterapkan:

- Badan dibelah menjadi badan atas (`chest`) dan badan bawah (`pelvis`) dengan sendi di pinggang. Badan bawah otomatis ikut sepertiga condong badan atas, jadi badan melengkung.
- Paha Emak-Emak dipanjangkan (pangkal paha naik dari baris 115 ke 104), sehingga tendangannya sepanjang tendangan Abang Ojol.
- Kaki yang menendang digambar di atas badan, dan rok Emak-Emak ikut terangkat.
- Tiap serangan punya ancang-ancang ke arah berlawanan, pinggul yang bergeser maju, kaki yang melangkah, dan lengan penyeimbang. Kurva animasi dihaluskan (cubic).
- Jejak ayunan putih digambar di frame aktif pertama: busur untuk sapu, garis lesat untuk pukulan dan tendangan.
- Hitbox dan lebar badan disesuaikan lagi dengan pose baru. Pukulan ringan Emak-Emak sekarang 120 piksel, Abang Ojol 66; lebar badan 54 dan 44.

Cara keputusan 18 diterapkan: halaman pembuka (logo dan "tekan tombol apa saja") lalu menu utama dengan pilihan di kiri, di atas latar Gang Sempit malam hujan dengan lampu berkedip dan dua petarung yang berlatih jurus. Latar ini memakai gambar stage yang sudah ada, bukan gambar Bundaran HI atau Malioboro seperti di GDD 5.1.

## 13 November 2026, pindah ke Blender

Jeje menilai rig potongan 2D masih gagal: lengan terlihat putus di bahu dan siku, kaki keluar dari rok, dan efek skill serta ultimate kurang. Jeje meminta pindah ke Blender.

| No | Keputusan | Menutup atau mengubah | Diterapkan di |
| --- | --- | --- | --- |
| 20 | Karakter dimodelkan 3D di Blender lewat skrip, dianimasikan, lalu dirender menjadi sprite sheet 160 x 160 berpalet terkunci (frame per frame, seperti GDD 8). Rig potongan Skeleton2D tidak dilanjutkan | Keputusan 9, 15, dan 17 (rig potongan) | `tools/blender/`, `tools/pack_sprites.py` |
| 21 | Properti dan efek skill serta ultimate (motor, kotak bekal, dan lain-lain) ikut dirender dari Blender, tidak lagi kotak dari kode | Keputusan 10 untuk properti | Belum |

Catatan keputusan 20:

- Blender 5.2 sudah terpasang dan dijalankan tanpa jendela (`blender --background --python ...`), jadi tidak butuh MCP.
- Gambar dasar dari generator (keputusan 12 dan 13) menjadi acuan desain, bukan lagi sumber potongan.
- Dicoba dulu pada Abang Ojol dengan beberapa animasi dan ditunjukkan ke Jeje sebelum semua animasi dan Emak-Emak dikerjakan.
- Kanvas tetap 160 x 160, sehingga jangkauan gambar ke depan paling jauh 80 piksel dari tengah badan. Sapu Emak-Emak harus lebih pendek daripada di rig potongan.

Hasil uji coba Abang Ojol (13 November 2026), belum dipasang ke game:

- Pipeline jalan: `tools/blender/render_fighter.py` membangun model dari bentuk dasar dan merender sekitar 20 frame per detik, lalu `tools/pack_sprites.py` mengubahnya menjadi sprite sheet 160 x 160 berpalet terkunci. Pose ada di `tools/blender/fighter_anims.py`.
- Yang berhasil: lengan dan kaki selalu tersambung, badan berputar sungguhan, tendangan tinggi terbaca jelas.
- Yang kurang: model dari bentuk dasar tampak seperti boneka polos. Wajah, lipatan jaket, dan detail lain jauh di bawah gambar dasar dari generator.
- Game masih memakai rig potongan sampai Jeje memutuskan arah tampilan karakter.

## 13 November 2026, karakter tetap 2D

Jeje menolak tampilan karakter 3D dari uji coba keputusan 20 ("jelek").

| No | Keputusan | Menutup atau mengubah | Diterapkan di |
| --- | --- | --- | --- |
| 22 | Karakter tetap 2D dari gambar generator. Keputusan 20 (karakter 3D) dibatalkan. Sambungan lengan, kaki, dan rok yang putus diperbaiki di rig 2D | Keputusan 20 | `tools/cut_parts.py`, `game/tools/build_rigs.gd` |
| 23 | Blender dipakai untuk properti dan efek skill serta ultimate saja, supaya jelas bendanya apa: kotak bekal Emak-Emak, motor matic, motor bebek | Keputusan 21 | `tools/blender/render_props.py`, `tools/pack_props.py`, `game/props/` |
| 24 | Nama skill ditampilkan di layar saat dipakai, supaya pemain tahu jurus apa yang keluar | GDD 5.3 | `game/scripts/hud.gd` |

Skrip uji karakter 3D (`render_fighter.py`, `fighter_anims.py`, `pack_sprites.py`) dipindah ke folder arsip `indofight-arsip/blender-3d/` di luar repo (21 November 2026). Bagian yang masih dipakai properti pindah ke `tools/pack_props.py` dan `tools/palette.py`.

### Hasil 15 November 2026 (keputusan 22 sampai 24)

**Sambungan badan (keputusan 22).** Lengan, kaki, dan rok tidak lagi potongan kaku yang diputar, tetapi mesh lentur: satu tekstur yang ditekuk oleh beberapa tulang (Polygon2D berbobot tulang).

- `cut.json` punya dua daftar baru di luar `parts`: `meshes` (bagian yang digabung jadi satu mesh) dan `hidden` (tulangnya dipakai, gambarnya tidak ditampilkan). `tools/cut_parts.py` menulis tekstur gabungannya, `game/tools/build_rigs.gd` membuat mesh dan bobotnya.
- Mode `chain` (lengan kedua karakter, kaki Abang Ojol): bobot berpindah halus di siku atau lutut. Bila tulang pertama adalah `chest`, pangkal lengan ikut badan, jadi bahu tidak mencuat saat lengan diangkat.
- Mode `skirt` (Emak-Emak): daster bagian bawah ikut paha di sisinya dan betis ikut dalam mesh yang sama, jadi rok terangkat bersama kaki dan tidak ada celah antara ujung rok dan kaki. Paha buatan skrip tidak ditampilkan lagi.
- Garis potong lengan depan Abang Ojol sebelumnya membelah lengan (separuh lengan tertinggal di badan). Garis potong, bahu, dan siku sudah dipindah ke tepi lengan yang sebenarnya.
- Lengan belakang Abang Ojol digambar di depan dada (di gambar dasar itu lengan yang dekat ke penonton), supaya kuda-kudanya terbaca.
- Kunci pose baru `arm_back`: lengan depan dan propertinya digambar di belakang badan. Dipakai di ancang-ancang HP Emak-Emak supaya lengan tidak melintang di depan muka.
- Saat seluruh badan diputar (jatuh, KO), mesh mengikuti Skeleton lewat `game/scripts/fighter_rig.gd`.

**Properti dari Blender (keputusan 23).** Kotak bekal (32 x 24, 8 frame putar), motor matic (96 x 64, 4 frame), motor bebek (96 x 64, 4 frame). Ketiganya lolos `tools/validate_sprite.py` dengan palet `props-emak` dan `abang-ojol`. Efek tambahan (asap knalpot, garis lesat, sorot lampu, jejak putar) tetap digambar kode di `game/scripts/fight_view.gd`.

Cara membuat ulang (Blender 5.2 LTS, tanpa jendela):

```
"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" --background --factory-startup --python tools/blender/render_props.py -- <folder_render>
python tools/pack_props.py <folder_render>
```

**Nama skill (keputusan 24).** Skill Emak-Emak tampil sebagai "Kotak Bekal Boomerang", bukan nama GDD, karena aturan seni 8 melarang nama merek. Nama di GDD belum diubah.

Uji: `game/tests/sim_test.gd` 131 pemeriksaan lolos setelah perubahan rig.

## 16 November 2026, gerak lebih mulus

Jeje minta gerak dibuat "mulus bagus kayak game Tekken".

| No | Keputusan | Menutup atau mengubah | Diterapkan di |
| --- | --- | --- | --- |
| 25 | Gerak dihaluskan di lapisan tampilan saja: peralihan antaranimasi dilebur, kepala, senjata, dan lengan belakang punya gerak susulan (pegas), bayangan gerak saat dash dan teleport, tepi bagian tubuh tidak robek saat diputar, animasi bangun sendiri, gerak lambat sesaat saat KO. Simulasi, hitbox, dan frame data tidak berubah | Keputusan 4 untuk bangun (tidak lagi "ko" diputar terbalik) | `game/scripts/fighter_rig.gd`, `game/scripts/fighters.gd`, `tools/cut_parts.py`, `game/tools/build_rigs.gd`, `game/tools/rig_poses.gd`, `game/scripts/main.gd` |

Rincian:

- **Peralihan:** saat animasi berganti, pose lama dilebur ke pose baru. Serangan 3 frame, kena pukul 2 frame (tetap tegas dan cocok dengan frame data), gerak biasa 7 frame. Angkanya di `_blend_for()` di `game/scripts/fighters.gd`.
- **Gerak susulan:** pegas per tulang di `SPRINGS` di `game/scripts/fighter_rig.gd` (kekakuan, redaman, simpangan maksimum, pengaruh percepatan badan). Geseran lebih dari 24 px dalam satu frame dianggap pindah tempat dan diabaikan.
- **Tepi halus saat diputar:** tekstur bagian tubuh disimpan 9x lebih besar dengan Scale3x dua kali (`tools/cut_parts.py`, kolom `tex_scale` di `rig.json`). Saat diam hasilnya persis gambar asli; saat diputar tepinya tetap piksel keras dari palet yang sama, tanpa anti-aliasing (aturan seni 5 tetap terpenuhi). Semua bagian sekarang Polygon2D yang digerakkan tulang, tidak ada lagi Sprite2D dengan RemoteTransform2D.
- **Bayangan gerak:** dash meninggalkan siluet putih tiap 3 frame; teleport Abang Ojol meninggalkan siluet hijau toska berbentuk badannya, menggantikan kotak cahaya lama. Shader rig punya parameter `ghost`.
- **Bangun:** animasi `getup` baru (duduk bertumpu tangan, jongkok, berdiri). Satu pose bisa memakai `"ground": true/false` sendiri.
- **Gerak lambat KO:** 54 frame gambar, simulasi maju satu tick tiap 3 frame. Simulasi tidak berubah, jadi tetap deterministik. Uji yang dipercepat (`--speed` di atas 1) tidak memakainya.
- **Tangkisan:** perisai berbentuk busur di depan badan, memudar seiring blockstun habis.
- **Pose:** ancang-ancang HP Abang Ojol diturunkan sedikit supaya lengannya tidak bergelombang.
- **Opsi uji:** `--no-help` dan `--screen=training` sekarang boleh ditulis dalam urutan apa pun.

Uji: `game/tests/sim_test.gd` 131 pemeriksaan lolos; layar title, select, versus, dan training terbuka tanpa error. Rekaman ada di `production/review/gerak_pertarungan.gif` dan `gerak_ultimate_emak.gif`.

## 23 November 2026, kontrol dan layar versus

Jeje minta P2 tanpa numpad (tidak semua keyboard punya), tombol bisa diubah, dan layar versus setelah memilih petarung diberi efek.

| No | Keputusan | Menutup atau mengubah | Diterapkan di |
| --- | --- | --- | --- |
| 26 | Tombol bisa diubah di menu KONTROL dan tersimpan di `user://kontrol.cfg`. Bawaan tanpa numpad: P1 `W A S D` gerak, `F` `G` pukul, `R` `T` tendang, `H` tahan, `Y` skill, `B` ultimate; P2 panah gerak, `J` `K` pukul, `U` `I` tendang, `L` tahan, `O` skill, `P` ultimate. Saat main sendiri (lawan komputer, latihan), tombol P2 ikut menggerakkan P1, jadi tata letak lama (`W A S D` + `J K U I L O P`) tetap jalan. Panel kontrol ditutup dengan Esc, bukan tombol apa saja | Keputusan 19 (tutup dengan tombol apa saja) | `game/scripts/key_bindings.gd`, `game/scripts/controls_panel.gd`, `game/scripts/main.gd` |
| 27 | Layar versus beranimasi: dua sisi miring masuk dari samping, VS dibanting dengan kilat putih, guncangan, cincin, dan percikan, petarung tampil dengan rig beranimasi, papan nama dengan nama ultimate, bara naik, kilat di garis tengah, bilah hitam sinematik, lalu layar memutih masuk ke pertarungan | Layar versus polos | `game/scripts/menu.gd`, `game/scripts/main.gd` (suara di frame 1 dan 12) |

Rincian:

- **Ubah tombol:** atas/bawah pilih aksi, kiri/kanan pilih pemain, Enter lalu tekan tombol baru. Tombol yang sudah dipakai aksi lain bertukar otomatis, jadi tidak ada satu tombol untuk dua aksi. Esc, Enter, Backspace, dan F1 sampai F6 serta F11 tidak bisa dipakai bertarung karena dipakai menu.
- **`project.godot`:** daftar tombol `p1_` dan `p2_` di sana hanya cadangan; `key_bindings.gd` mengisi ulang Input Map saat game dibuka.
- **Menu:** `F` dan `G` ikut berfungsi sebagai OK dan kembali di menu, sama seperti `J` dan `K`.
- **Uji:** `game/tests/key_bindings_test.gd` (tukar, tolak tombol menu, simpan dan muat, bawaan tanpa tombol ganda). Tombol simpanan pemain dikembalikan setelah uji.

## Hasil 11 November 2026

### Kredit SpriteCook

| Aset | Model | Kredit |
| --- | --- | --- |
| Gambar dasar Emak-Emak | GPT-Image-2 low | 2 |
| Gambar dasar Abang Ojol | GPT-Image-2 low | 2 |
| Stage Gang Sempit | GPT-Image-2 medium | 9 |
| **Terpakai / sisa** | | **13 / 27** |

Unggah gambar referensi tidak memakai kredit. `asset_id` dan sidik file ada di `production/spritecook-assets.json`. Sisa 27 kredit belum punya peruntukan.

Ketiga aset berstatus `review` di manifest. Jeje belum menyatakan lolos.

### Dari gambar generator ke aset game

Generator mengembalikan gambar dengan ukuran dan ribuan warna bebas (380 x 317 dan 170 x 176 untuk karakter, 503 x 283 untuk stage), bukan 160 x 160 berpalet. Tiga skrip mengubahnya dan hasilnya lolos `tools/validate_sprite.py`:

| Skrip | Kerja |
| --- | --- |
| `tools/pixelize_base.py` | Mengecilkan karakter ke tinggi spesifikasi (Emak-Emak 100, Abang Ojol 104), memaskan ke palet terkunci, memberi garis tepi 1 piksel, menaruh kaki di baris 150 dan tengah di kolom 80 |
| `tools/cut_parts.py` | Memotong 11 bagian per karakter menurut poligon di `art/characters/<nama>/rig/cut.json` |
| `tools/pixelize_stage.py` | Mengunci palet `stage-gang` (21 warna), membelah gambar jadi layer latar dan lantai, melebarkannya dengan cerminan |

Membangun ulang setelah mengubah potongan atau pose:

```
python tools/cut_parts.py art/characters/emak-emak/rig/cut.json
C:/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path game --import
C:/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path game -s res://tools/build_rigs.gd
```

Lembar periksa semua pose: `godot --path game res://tests/rig_preview.tscn -- --out=FILE.png`.

### Rig (keputusan 9 dan 15)

- **Tulang (13):** pinggul, badan atas, badan bawah, kepala, lengan atas dan bawah (depan dan belakang), paha dan betis (depan dan belakang), properti di tangan depan. Badan atas dan bawah dipisah pada 13 November (keputusan 17).
- **Beda dari keputusan 9:** kaki dibagi dua di lutut, bukan satu potong, supaya jongkok dan tendangan bisa menekuk. Paha Emak-Emak tertutup daster di gambar, jadi dibuat oleh skrip dari warna betis.
- **Properti:** sapu lidi Emak-Emak dan helm cadangan Abang Ojol digambar terpisah di gambar dasar lalu dipasang ke tangan depan.
- **Animasi (17):** idle, walk, jump, crouch, dash, backdash, block, hit, ko, defeat, win, lp, hp, lk, hk, skill, ultimate. Jalan mundur dan bangun memakai animasi yang diputar terbalik. Taunt belum dibuat.
- **Waktu serangan:** animasi serangan dibagi tiga bagian (startup, aktif, recovery) dan dipetakan dari frame data, jadi mengubah angka di `game/data/attacks/` tidak perlu mengubah animasi.
- **Scene rig ditimpa** tiap `build_rigs.gd` dijalankan. Ubah pose di `game/tools/rig_poses.gd`, bukan di editor, kecuali skrip itu tidak akan dijalankan lagi.

### Stage (keputusan 14)

Satu gambar menghasilkan dua layer: latar (rumah dan langit, 0,5x) dan lantai (jalan, 1,0x). Tidak ada layer langit terpisah, jadi kecepatan skybox 0,1x (keputusan 5) tidak berlaku di stage ini. Lampu berkedip, gerobak, dan jemuran beranimasi tidak dibuat.

### Angka yang diubah supaya cocok dengan gambar

Usulan awal, belum di-balance lewat permainan:

- Jangkauan serangan mengikuti panjang sapu dan kaki di rig. Pukulan ringan Emak-Emak sekarang 110 piksel (sebelumnya 90), Abang Ojol 58 (sebelumnya 46).
- Lebar badan untuk saling dorong naik ke 44 (Emak-Emak) dan 34 (Abang Ojol) supaya gambar tidak saling menembus.
- Hurtbox jongkok naik ke 76 dan 74 piksel mengikuti pose jongkok.
- Ultimate Emak-Emak kebal selama 50 frame peringatan; frame aktif ultimate Abang Ojol 36.

## Rincian

### Palet setelah keputusan 3

| Palet | Jumlah warna | Warna garis tepi (tergelap) |
| --- | --- | --- |
| abang-ojol | 19 | `011401` |
| bocah-warnet | 22 | `270908` |
| dukun-santet | 20 | `060706` (tidak berubah, sudah bukan hitam murni) |
| emak-emak | 19 | `1b0205` |
| gatot-kaca | 20 | `200805` |
| intel-bakso | 20 | `1b0202` |
| jenderal-gemoy | 20 | `1e0c06` |
| kuli-jawa | 20 | `010000` (tidak berubah, lihat catatan terbuka) |
| mahasiswa | 20 | `040b23` |
| pocong-brawler | 15 | `221f1c` (lihat catatan terbuka) |
| stage-dpr | 32 | `050001` (tidak berubah) |
| props-emak | 8 | `1b0205` |

### Palet `props-emak`

| Hex | Dipakai untuk |
| --- | --- |
| `1b0205` | Garis tepi, sama dengan warna tergelap palet Emak-Emak |
| `6e141b` | Merah gelap (bayangan) |
| `b3222b` | Merah tengah |
| `e8504a` | Merah terang (sorotan) |
| `f08a24` | Oranye lampu sein |
| `ffcf4a` | Kuning sein menyala |
| `4f4f52` | Abu-abu gelap ban dan mesin, dari palet Emak-Emak |
| `d8d8da` | Abu-abu terang logam dan kilau |

Warna merah, oranye, dan abu-abu terang adalah usulan awal. Jeje belum melihatnya di sprite.

### Angka kombat (keputusan 6)

Angka awal adalah usulan pertama dan belum di-balance lewat permainan. Semuanya ada di `game/data/` sebagai resource dan bisa diubah tanpa menyentuh kode:

- `game/data/rules/match_rules.tres`: ronde, waktu, energi, input buffer, skala kombo.
- `game/data/fighters/*.tres`: health, kecepatan, lompat, ukuran kotak.
- `game/data/attacks/*.tres`: startup, active, recovery, damage, hitstun, blockstun, hitstop, pushback, cooldown.

Setelah mengubah angka, jalankan uji simulasi (131 pemeriksaan: frame data, hitstop, block, kombo, ronde, latihan, efek, determinisme):

```
C:/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path game -s res://tests/sim_test.gd
```

Di Windows ini `python3` hanya stub Microsoft Store. Pakai `python` untuk skrip di `tools/`.

## Catatan terbuka (belum diputuskan)

- **Latar menu utama.** GDD 5.1 meminta Bundaran HI atau Malioboro saat senja. Sekarang menu memakai stage Gang Sempit. Gambar khusus bisa dibuat dengan sekitar 9 dari 27 kredit yang tersisa, tetapi lokasinya (GDD 11.2) belum diputuskan.
- **Persetujuan aset.** Gambar dasar Emak-Emak, gambar dasar Abang Ojol, dan stage Gang Sempit menunggu keputusan lolos dari Jeje.
- **Sisa 27 kredit.** Belum diputuskan dipakai untuk apa.
- **Animasi rig belum dinilai manusia.** Pose dibuat dari angka dan diperiksa lewat tangkapan layar, bukan dimainkan.
- **Suara.** Masih placeholder dari rumus di `game/scripts/sfx.gd`. Skill ElevenLabs belum terpasang.
- **Splash art, ikon, dan Taunt** tidak dibuat. Layar pilih petarung dan versus memakai gambar dasar.
- **Pocong Brawler 15 warna.** Setelah hitam murni dihapus, palet ini di bawah batas 16 sampai 24 warna (GDD 2). Perlu satu warna tambahan atau izin pengecualian sebelum Pocong dikerjakan.
- **Kuli Jawa `010000`.** Bukan `000000` sehingga tidak tersentuh keputusan 3, tetapi di layar tampak hitam murni.
- **GDD belum diubah.** GDD 8.2 masih mencantumkan Walk Backward dan GDD 11.2 masih menandai butir 1 dan 6 sebagai terbuka. File ini yang berlaku sampai Jeje memperbarui GDD.
- **Folder `indofight-starter-kit/`** (salinan kit asli yang tidak sengaja ikut tersalin) dipindah ke Recycle Bin pada 21 November 2026. Isinya hanya versi lama file yang sudah ada di folder utama.
