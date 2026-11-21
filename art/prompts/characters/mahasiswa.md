# Mahasiswa (The Protester): Lembar Prompt Produksi

Lembar ini dipakai bersama SpriteCook. Ikuti urutan bagian 1 sampai 6. Jangan lompat ke animasi sebelum gambar dasar disetujui.

## 0. Ringkasan

- Palet terkunci: `art/palettes/mahasiswa.hex` (20 warna)
- Tinggi karakter berdiri: sekitar 104 piksel di kanvas 160 x 160, kaki di baris piksel 150
- Arah hadap: kanan. Arah kiri dibuat engine dengan flip, jangan digambar terpisah
- Kunci visual (wajib sama di semua frame):
    - Jaket almamater biru terbuka, kaos putih di dalam
    - Ikat kepala merah putih selalu terlihat
    - Toa putih di tangan kiri, tongkat kayu di tangan kanan
    - Molotov hanya milik karakter ini dan hanya muncul di ultimate

## 1. Gambar dasar (canonical)

Langkah awal: unggah `art/reference/characters/mahasiswa.png` lewat skill `spritecook-upload-assets`, simpan asset_id-nya dengan label `mahasiswa_ref`, lalu isi `<ASSET_ID_REFERENSI_KARAKTER>` di bawah. Referensi ini hanya acuan gaya, bukan desain final: kunci visual di bagian 0 yang menang bila berbeda.

Semua animasi dibuat dari SATU gambar ini. Generate 4 variasi, pilih 1, rapikan di Aseprite, unggah ulang, lalu simpan `asset_id`-nya di `production/spritecook-assets.json` dengan label `mahasiswa_base`.

Alat: `generate_game_art`

```json
{
  "prompt": "a young Indonesian male university student with short spiky black hair, a red-and-white headband, an open royal-blue university almamater jacket over a white t-shirt, dark grey trousers, white sneakers and a small backpack; he holds a white megaphone in his left hand and a short wooden banner pole in his right hand. Neutral fighting stance. side view, facing right, full body, standing on an invisible flat floor line, transparent background. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos.",
  "width": 160,
  "height": 160,
  "pixel": true,
  "bg_mode": "transparent",
  "style": "16-bit SNK / Metal Slug arcade pixel art",
  "theme": "Indonesian street satire fighting game",
  "colors": ["#040b23", "#220908", "#202127", "#2e2f36", "#592720", "#22375e", "#1f4174", "#373f4b", "#334f7d", "#564a48", "#5c5e64", "#3f67a1", "#ae7b63", "#929295", "#dda277", "#b1b0b2", "#c1c2c3", "#d6cfd0", "#e6e4e5", "#e23b3b"],
  "smart_crop": false,
  "variations": 4,
  "style_asset_ids": ["<ASSET_ID_REFERENSI_KARAKTER>"]
}
```

Negative/hindari: chibi, big head, anime eyes, blurry, anti-aliased edges, soft gradients, painterly, 3D render, photo, text, watermark, logo, extra limbs, extra weapons, cropped feet, front view, back view

Lolos jika: siluet terbaca dari jauh, semua kunci visual ada, kaki rata di lantai, warna 100% dari palet (cek dengan `python3 tools/validate_sprite.py`).

## 2. Splash art (Character Select dan layar Versus)

Alat: `generate_game_art`, lalu perbesar 4x dengan `tools/upscale.py` menjadi 1080 x 1920.

```json
{
  "prompt": "Full-body character select splash art of a young Indonesian male university student with short spiky black hair, a red-and-white headband, an open royal-blue university almamater jacket over a white t-shirt, dark grey trousers, white sneakers and a small backpack; he holds a white megaphone in his left hand and a short wooden banner pole in his right hand. Heroic three-quarter pose, slight low camera angle, dramatic rim light. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos. Transparent background.",
  "width": 270,
  "height": 480,
  "aspect_ratio": "9:16",
  "pixel": true,
  "bg_mode": "transparent",
  "colors": ["#040b23", "#220908", "#202127", "#2e2f36", "#592720", "#22375e", "#1f4174", "#373f4b", "#334f7d", "#564a48", "#5c5e64", "#3f67a1", "#ae7b63", "#929295", "#dda277", "#b1b0b2", "#c1c2c3", "#d6cfd0", "#e6e4e5", "#e23b3b"],
  "reference_asset_id": "<ASSET_ID_GAMBAR_DASAR>"
}
```

## 3. Ikon grid 64 x 64 dan ikon HUD 32 x 32

Ikon HUD dibuat dengan memperkecil manual ikon grid di Aseprite, bukan generate ulang.

```json
{
  "prompt": "Head and shoulders portrait mugshot of the same character, facing three-quarter right, strong expression, 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos.",
  "width": 64,
  "height": 64,
  "pixel": true,
  "bg_mode": "include",
  "colors": ["#040b23", "#220908", "#202127", "#2e2f36", "#592720", "#22375e", "#1f4174", "#373f4b", "#334f7d", "#564a48", "#5c5e64", "#3f67a1", "#ae7b63", "#929295", "#dda277", "#b1b0b2", "#c1c2c3", "#d6cfd0", "#e6e4e5", "#e23b3b"],
  "reference_asset_id": "<ASSET_ID_GAMBAR_DASAR>"
}
```

## 4. Animasi (18 gerakan)

Walk Backward tidak dibuat sebagai job terpisah: engine memutar sheet Walk Forward secara terbalik (lihat `docs/decisions.md`).

Alat: `animate_game_art` dengan `asset_id` gambar dasar yang SAMA untuk setiap gerakan. Parameter tetap: `pixel: true`, `colors: 24`, `edge_margin: 6`, `output_format: "spritesheet"`, `auto_enhance_prompt: false`.

Jumlah frame dibulatkan ke genap karena SpriteCook hanya menerima 2 sampai 16 frame genap (Hit jadi 4, Knockdown jadi 6).

| No | Animasi | File | Frame | Loop |
| --- | --- | --- | --- | --- |
| 1 | Idle | `indofight_char_mahasiswa_idle_sheet.png` | 6 | ya |
| 2 | Walk Forward | `indofight_char_mahasiswa_walk_forward_sheet.png` | 8 | ya |
| 3 | Dash / Step | `indofight_char_mahasiswa_dash_sheet.png` | 4 | tidak |
| 4 | Jump | `indofight_char_mahasiswa_jump_sheet.png` | 6 | tidak |
| 5 | Crouch | `indofight_char_mahasiswa_crouch_sheet.png` | 2 | tidak |
| 6 | Light Punch | `indofight_char_mahasiswa_light_punch_sheet.png` | 4 | tidak |
| 7 | Heavy Punch | `indofight_char_mahasiswa_heavy_punch_sheet.png` | 6 | tidak |
| 8 | Light Kick | `indofight_char_mahasiswa_light_kick_sheet.png` | 4 | tidak |
| 9 | Heavy Kick | `indofight_char_mahasiswa_heavy_kick_sheet.png` | 6 | tidak |
| 10 | Block | `indofight_char_mahasiswa_block_sheet.png` | 2 | tidak |
| 11 | Hit | `indofight_char_mahasiswa_hit_sheet.png` | 4 | tidak |
| 12 | Knockup | `indofight_char_mahasiswa_knockup_sheet.png` | 4 | tidak |
| 13 | Knockdown | `indofight_char_mahasiswa_knockdown_sheet.png` | 6 | tidak |
| 14 | Special Skill | `indofight_char_mahasiswa_special_sheet.png` | 8 | tidak |
| 15 | Ultimate Cast | `indofight_char_mahasiswa_ultimate_cast_sheet.png` | 10 | tidak |
| 16 | Defeat | `indofight_char_mahasiswa_defeat_sheet.png` | 6 | tidak |
| 17 | Victory | `indofight_char_mahasiswa_victory_sheet.png` | 8 | ya |
| 18 | Taunt | `indofight_char_mahasiswa_taunt_sheet.png` | 6 | ya |

### 4.1 Idle

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Mahasiswa character breathes in a steady fighting stance, chest and shoulders rising and falling slightly, feet planted, held props bobbing gently. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion loops seamlessly.",
  "output_frames": 6,
  "pixel": true,
  "colors": 24,
  "edge_margin": 6,
  "output_format": "spritesheet",
  "auto_enhance_prompt": false,
  "negative_prompt": "changing outfit, changing colours, new weapons, camera movement, character turning to face the viewer, sliding feet"
}
```

### 4.2 Walk Forward

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Mahasiswa character walks with a confident marching rhythm, megaphone held at chest height. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion loops seamlessly.",
  "output_frames": 8,
  "pixel": true,
  "colors": 24,
  "edge_margin": 6,
  "output_format": "spritesheet",
  "auto_enhance_prompt": false,
  "negative_prompt": "changing outfit, changing colours, new weapons, camera movement, character turning to face the viewer, sliding feet"
}
```

### 4.3 Dash / Step

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Mahasiswa character makes one quick low burst step forward, body leaning in, then settles back into stance. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
  "output_frames": 4,
  "pixel": true,
  "colors": 24,
  "edge_margin": 6,
  "output_format": "spritesheet",
  "auto_enhance_prompt": false,
  "negative_prompt": "changing outfit, changing colours, new weapons, camera movement, character turning to face the viewer, sliding feet"
}
```

### 4.4 Jump

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Mahasiswa character jumps with the banner pole raised. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
  "output_frames": 6,
  "pixel": true,
  "colors": 24,
  "edge_margin": 6,
  "output_format": "spritesheet",
  "auto_enhance_prompt": false,
  "negative_prompt": "changing outfit, changing colours, new weapons, camera movement, character turning to face the viewer, sliding feet"
}
```

### 4.5 Crouch

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Mahasiswa character drops into a low crouched guard and holds it. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
  "output_frames": 2,
  "pixel": true,
  "colors": 24,
  "edge_margin": 6,
  "output_format": "spritesheet",
  "auto_enhance_prompt": false,
  "negative_prompt": "changing outfit, changing colours, new weapons, camera movement, character turning to face the viewer, sliding feet"
}
```

### 4.6 Light Punch

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Mahasiswa character jabs forward quickly with the butt end of the wooden banner pole, then pulls it back. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
  "output_frames": 4,
  "pixel": true,
  "colors": 24,
  "edge_margin": 6,
  "output_format": "spritesheet",
  "auto_enhance_prompt": false,
  "negative_prompt": "changing outfit, changing colours, new weapons, camera movement, character turning to face the viewer, sliding feet"
}
```

### 4.7 Heavy Punch

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Mahasiswa character swings the wooden banner pole in a big overhead arc down onto the opponent. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
  "output_frames": 6,
  "pixel": true,
  "colors": 24,
  "edge_margin": 6,
  "output_format": "spritesheet",
  "auto_enhance_prompt": false,
  "negative_prompt": "changing outfit, changing colours, new weapons, camera movement, character turning to face the viewer, sliding feet"
}
```

### 4.8 Light Kick

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Mahasiswa character snaps a quick front kick at knee height. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
  "output_frames": 4,
  "pixel": true,
  "colors": 24,
  "edge_margin": 6,
  "output_format": "spritesheet",
  "auto_enhance_prompt": false,
  "negative_prompt": "changing outfit, changing colours, new weapons, camera movement, character turning to face the viewer, sliding feet"
}
```

### 4.9 Heavy Kick

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Mahasiswa character twists his whole body and swings his backpack around by the strap in a heavy horizontal arc. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
  "output_frames": 6,
  "pixel": true,
  "colors": 24,
  "edge_margin": 6,
  "output_format": "spritesheet",
  "auto_enhance_prompt": false,
  "negative_prompt": "changing outfit, changing colours, new weapons, camera movement, character turning to face the viewer, sliding feet"
}
```

### 4.10 Block

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Mahasiswa character holds the banner pole horizontally across his body with both hands. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
  "output_frames": 2,
  "pixel": true,
  "colors": 24,
  "edge_margin": 6,
  "output_format": "spritesheet",
  "auto_enhance_prompt": false,
  "negative_prompt": "changing outfit, changing colours, new weapons, camera movement, character turning to face the viewer, sliding feet"
}
```

### 4.11 Hit

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Mahasiswa character is struck in the face, head snaps back and body recoils, then recovers to stance. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
  "output_frames": 4,
  "pixel": true,
  "colors": 24,
  "edge_margin": 6,
  "output_format": "spritesheet",
  "auto_enhance_prompt": false,
  "negative_prompt": "changing outfit, changing colours, new weapons, camera movement, character turning to face the viewer, sliding feet"
}
```

### 4.12 Knockup

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Mahasiswa character is launched into the air by an uppercut, body arching backward, limbs flailing. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
  "output_frames": 4,
  "pixel": true,
  "colors": 24,
  "edge_margin": 6,
  "output_format": "spritesheet",
  "auto_enhance_prompt": false,
  "negative_prompt": "changing outfit, changing colours, new weapons, camera movement, character turning to face the viewer, sliding feet"
}
```

### 4.13 Knockdown

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Mahasiswa character falls backward flat onto the floor, bounces once, then pushes up and stands again. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
  "output_frames": 6,
  "pixel": true,
  "colors": 24,
  "edge_margin": 6,
  "output_format": "spritesheet",
  "auto_enhance_prompt": false,
  "negative_prompt": "changing outfit, changing colours, new weapons, camera movement, character turning to face the viewer, sliding feet"
}
```

### 4.14 Special Skill

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Mahasiswa character raises the megaphone to his mouth, leans forward and shouts with his whole body, shoulders tensing; the megaphone shakes from the force (sound waves are a separate VFX sprite). Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
  "output_frames": 8,
  "pixel": true,
  "colors": 24,
  "edge_margin": 6,
  "output_format": "spritesheet",
  "auto_enhance_prompt": false,
  "negative_prompt": "changing outfit, changing colours, new weapons, camera movement, character turning to face the viewer, sliding feet"
}
```

### 4.15 Ultimate Cast

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Mahasiswa character pumps his fist into the air and shouts toward the sky as if calling a crowd, then winds up and throws a bottle overhand. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
  "output_frames": 10,
  "pixel": true,
  "colors": 24,
  "edge_margin": 6,
  "output_format": "spritesheet",
  "auto_enhance_prompt": false,
  "negative_prompt": "changing outfit, changing colours, new weapons, camera movement, character turning to face the viewer, sliding feet"
}
```

### 4.16 Defeat

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Mahasiswa character drops to his knees, the megaphone slipping from his hand, then slumps forward. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
  "output_frames": 6,
  "pixel": true,
  "colors": 24,
  "edge_margin": 6,
  "output_format": "spritesheet",
  "auto_enhance_prompt": false,
  "negative_prompt": "changing outfit, changing colours, new weapons, camera movement, character turning to face the viewer, sliding feet"
}
```

### 4.17 Victory

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Mahasiswa character raises the megaphone and his fist high and cheers. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion loops seamlessly.",
  "output_frames": 8,
  "pixel": true,
  "colors": 24,
  "edge_margin": 6,
  "output_format": "spritesheet",
  "auto_enhance_prompt": false,
  "negative_prompt": "changing outfit, changing colours, new weapons, camera movement, character turning to face the viewer, sliding feet"
}
```

### 4.18 Taunt

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Mahasiswa character waves a small red-and-white flag on the banner pole from side to side. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion loops seamlessly.",
  "output_frames": 6,
  "pixel": true,
  "colors": 24,
  "edge_margin": 6,
  "output_format": "spritesheet",
  "auto_enhance_prompt": false,
  "negative_prompt": "changing outfit, changing colours, new weapons, camera movement, character turning to face the viewer, sliding feet"
}
```

Catatan: animasi Ultimate Cast hanya pose karakter. Efek besar ultimate (proyektil, kendaraan, layar penuh) ada di bagian 5 dan digabung di engine.

## 5. Properti, proyektil, dan efek khusus

Alat: `generate_game_art` untuk gambar diam, lalu `animate_game_art` bila kolom frame lebih dari 1. Pakai `style_asset_ids` berisi gambar dasar karakter ini supaya gayanya sama.

| Kode | Isi | Ukuran | Frame |
| --- | --- | --- | --- |
| `mahasiswa_toa_soundwave` | Gelombang suara Sonic Toa (VFX) | 64 x 48 | 8 |
| `mahasiswa_burning_tire` | Ban bekas terbakar (proyektil ultimate) | 32 x 32 | 6 |
| `mahasiswa_molotov` | Molotov (proyektil ultimate) | 16 x 24 | 4 |
| `mahasiswa_burn_fire` | Api Burn di tanah | 48 x 32 | 6 |

### mahasiswa_toa_soundwave

```json
{
  "prompt": "three expanding curved sound-wave arcs in pale cyan and white bursting to the right from a megaphone mouth, comic style. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos. Transparent background.",
  "width": 64,
  "height": 48,
  "pixel": true,
  "bg_mode": "transparent",
  "colors": ["#040b23", "#220908", "#202127", "#2e2f36", "#592720", "#22375e", "#1f4174", "#373f4b", "#334f7d", "#564a48", "#5c5e64", "#3f67a1", "#ae7b63", "#929295", "#dda277", "#b1b0b2", "#c1c2c3", "#d6cfd0", "#e6e4e5", "#e23b3b"],
  "style_asset_ids": ["<ASSET_ID_GAMBAR_DASAR>"]
}
```

Lalu `animate_game_art` dengan `output_frames: 8`.

### mahasiswa_burning_tire

```json
{
  "prompt": "an old black rubber car tire on fire with orange and yellow pixel flames, spinning as it falls. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos. Transparent background.",
  "width": 32,
  "height": 32,
  "pixel": true,
  "bg_mode": "transparent",
  "colors": ["#040b23", "#220908", "#202127", "#2e2f36", "#592720", "#22375e", "#1f4174", "#373f4b", "#334f7d", "#564a48", "#5c5e64", "#3f67a1", "#ae7b63", "#929295", "#dda277", "#b1b0b2", "#c1c2c3", "#d6cfd0", "#e6e4e5", "#e23b3b"],
  "style_asset_ids": ["<ASSET_ID_GAMBAR_DASAR>"]
}
```

Lalu `animate_game_art` dengan `output_frames: 6`.

### mahasiswa_molotov

```json
{
  "prompt": "a glass bottle with a burning cloth wick, tumbling end over end. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos. Transparent background.",
  "width": 16,
  "height": 24,
  "pixel": true,
  "bg_mode": "transparent",
  "colors": ["#040b23", "#220908", "#202127", "#2e2f36", "#592720", "#22375e", "#1f4174", "#373f4b", "#334f7d", "#564a48", "#5c5e64", "#3f67a1", "#ae7b63", "#929295", "#dda277", "#b1b0b2", "#c1c2c3", "#d6cfd0", "#e6e4e5", "#e23b3b"],
  "style_asset_ids": ["<ASSET_ID_GAMBAR_DASAR>"]
}
```

Lalu `animate_game_art` dengan `output_frames: 4`.

### mahasiswa_burn_fire

```json
{
  "prompt": "small ground fire with flickering orange and yellow flames, looping. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos. Transparent background.",
  "width": 48,
  "height": 32,
  "pixel": true,
  "bg_mode": "transparent",
  "colors": ["#040b23", "#220908", "#202127", "#2e2f36", "#592720", "#22375e", "#1f4174", "#373f4b", "#334f7d", "#564a48", "#5c5e64", "#3f67a1", "#ae7b63", "#929295", "#dda277", "#b1b0b2", "#c1c2c3", "#d6cfd0", "#e6e4e5", "#e23b3b"],
  "style_asset_ids": ["<ASSET_ID_GAMBAR_DASAR>"]
}
```

Lalu `animate_game_art` dengan `output_frames: 6`.

## 6. Checklist sebelum karakter dianggap selesai

- [ ] Gambar dasar disetujui dan asset_id tersimpan di manifest
- [ ] 18 sprite sheet lolos `tools/validate_sprite.py` (palet, transparansi, garis kaki)
- [ ] Pivot di tengah telapak kaki sama di semua frame
- [ ] Splash 1080 x 1920 dan ikon 256 x 256 sudah diekspor 4x
- [ ] Semua properti dan efek di bagian 5 sudah dibuat
- [ ] Sudah dicoba di engine bersama HUD dan stage
- [ ] Baris karakter ini di `production/asset_manifest.csv` sudah berstatus done
