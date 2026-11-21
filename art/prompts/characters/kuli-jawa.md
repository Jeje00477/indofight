# Kuli Jawa (The Builder): Lembar Prompt Produksi

Lembar ini dipakai bersama SpriteCook. Ikuti urutan bagian 1 sampai 6. Jangan lompat ke animasi sebelum gambar dasar disetujui.

## 0. Ringkasan

- Palet terkunci: `art/palettes/kuli-jawa.hex` (20 warna)
- Tinggi karakter berdiri: sekitar 108 piksel di kanvas 160 x 160, kaki di baris piksel 150
- Arah hadap: kanan. Arah kiri dibuat engine dengan flip, jangan digambar terpisah
- Kunci visual (wajib sama di semua frame):
    - Caping bambu
    - Kaos abu-abu digulung ke bahu
    - Handuk kecil di leher (wajib ditambahkan)
    - Celana training biru dongker bergaris putih
- Perbaikan dari gambar referensi:
    - Handuk leher belum ada di referensi. Tambahkan di gambar dasar.

## 1. Gambar dasar (canonical)

Langkah awal: unggah `art/reference/characters/kuli-jawa.png` lewat skill `spritecook-upload-assets`, simpan asset_id-nya dengan label `kuli-jawa_ref`, lalu isi `<ASSET_ID_REFERENSI_KARAKTER>` di bawah. Referensi ini hanya acuan gaya, bukan desain final: kunci visual di bagian 0 yang menang bila berbeda.

Semua animasi dibuat dari SATU gambar ini. Generate 4 variasi, pilih 1, rapikan di Aseprite, unggah ulang, lalu simpan `asset_id`-nya di `production/spritecook-assets.json` dengan label `kuli-jawa_base`.

Alat: `generate_game_art`

```json
{
  "prompt": "a wiry, muscular Javanese construction worker with dark tan skin, a conical bamboo hat (caping), a grey t-shirt rolled up to the shoulders, a small white towel around his neck, navy track pants with white side stripes and rubber sandals; he holds a mason's trowel (cetok) in one hand and a glass of black coffee in the other. Neutral fighting stance. side view, facing right, full body, standing on an invisible flat floor line, transparent background. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos.",
  "width": 160,
  "height": 160,
  "pixel": true,
  "bg_mode": "transparent",
  "style": "16-bit SNK / Metal Slug arcade pixel art",
  "theme": "Indonesian street satire fighting game",
  "colors": ["#010000", "#111420", "#2b0e08", "#391d14", "#212842", "#442f24", "#5e3028", "#4c4039", "#3a4260", "#724e3c", "#5b5958", "#746f6b", "#96674d", "#8e8b8a", "#b0875d", "#c6976b", "#e0a379", "#bab1a9", "#dddddd", "#efeeed"],
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
  "prompt": "Full-body character select splash art of a wiry, muscular Javanese construction worker with dark tan skin, a conical bamboo hat (caping), a grey t-shirt rolled up to the shoulders, a small white towel around his neck, navy track pants with white side stripes and rubber sandals; he holds a mason's trowel (cetok) in one hand and a glass of black coffee in the other. Heroic three-quarter pose, slight low camera angle, dramatic rim light. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos. Transparent background.",
  "width": 270,
  "height": 480,
  "aspect_ratio": "9:16",
  "pixel": true,
  "bg_mode": "transparent",
  "colors": ["#010000", "#111420", "#2b0e08", "#391d14", "#212842", "#442f24", "#5e3028", "#4c4039", "#3a4260", "#724e3c", "#5b5958", "#746f6b", "#96674d", "#8e8b8a", "#b0875d", "#c6976b", "#e0a379", "#bab1a9", "#dddddd", "#efeeed"],
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
  "colors": ["#010000", "#111420", "#2b0e08", "#391d14", "#212842", "#442f24", "#5e3028", "#4c4039", "#3a4260", "#724e3c", "#5b5958", "#746f6b", "#96674d", "#8e8b8a", "#b0875d", "#c6976b", "#e0a379", "#bab1a9", "#dddddd", "#efeeed"],
  "reference_asset_id": "<ASSET_ID_GAMBAR_DASAR>"
}
```

## 4. Animasi (18 gerakan)

Walk Backward tidak dibuat sebagai job terpisah: engine memutar sheet Walk Forward secara terbalik (lihat `docs/decisions.md`).

Alat: `animate_game_art` dengan `asset_id` gambar dasar yang SAMA untuk setiap gerakan. Parameter tetap: `pixel: true`, `colors: 24`, `edge_margin: 6`, `output_format: "spritesheet"`, `auto_enhance_prompt: false`.

Jumlah frame dibulatkan ke genap karena SpriteCook hanya menerima 2 sampai 16 frame genap (Hit jadi 4, Knockdown jadi 6).

| No | Animasi | File | Frame | Loop |
| --- | --- | --- | --- | --- |
| 1 | Idle | `indofight_char_kuli-jawa_idle_sheet.png` | 6 | ya |
| 2 | Walk Forward | `indofight_char_kuli-jawa_walk_forward_sheet.png` | 8 | ya |
| 3 | Dash / Step | `indofight_char_kuli-jawa_dash_sheet.png` | 4 | tidak |
| 4 | Jump | `indofight_char_kuli-jawa_jump_sheet.png` | 6 | tidak |
| 5 | Crouch | `indofight_char_kuli-jawa_crouch_sheet.png` | 2 | tidak |
| 6 | Light Punch | `indofight_char_kuli-jawa_light_punch_sheet.png` | 4 | tidak |
| 7 | Heavy Punch | `indofight_char_kuli-jawa_heavy_punch_sheet.png` | 6 | tidak |
| 8 | Light Kick | `indofight_char_kuli-jawa_light_kick_sheet.png` | 4 | tidak |
| 9 | Heavy Kick | `indofight_char_kuli-jawa_heavy_kick_sheet.png` | 6 | tidak |
| 10 | Block | `indofight_char_kuli-jawa_block_sheet.png` | 2 | tidak |
| 11 | Hit | `indofight_char_kuli-jawa_hit_sheet.png` | 4 | tidak |
| 12 | Knockup | `indofight_char_kuli-jawa_knockup_sheet.png` | 4 | tidak |
| 13 | Knockdown | `indofight_char_kuli-jawa_knockdown_sheet.png` | 6 | tidak |
| 14 | Special Skill | `indofight_char_kuli-jawa_special_sheet.png` | 8 | tidak |
| 15 | Ultimate Cast | `indofight_char_kuli-jawa_ultimate_cast_sheet.png` | 10 | tidak |
| 16 | Defeat | `indofight_char_kuli-jawa_defeat_sheet.png` | 6 | tidak |
| 17 | Victory | `indofight_char_kuli-jawa_victory_sheet.png` | 8 | ya |
| 18 | Taunt | `indofight_char_kuli-jawa_taunt_sheet.png` | 6 | ya |

### 4.1 Idle

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Kuli Jawa character breathes in a steady fighting stance, chest and shoulders rising and falling slightly, feet planted, held props bobbing gently. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion loops seamlessly.",
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
  "prompt": "The Kuli Jawa character walks with a relaxed working-man swagger. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion loops seamlessly.",
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
  "prompt": "The Kuli Jawa character makes one quick low burst step forward, body leaning in, then settles back into stance. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Kuli Jawa character jumps with the trowel raised. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Kuli Jawa character drops into a low crouched guard and holds it. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Kuli Jawa character snaps the neck towel forward like a whip. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Kuli Jawa character swings the heavy steel trowel in a downward chop. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Kuli Jawa character kicks low at the shin. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Kuli Jawa character stomps forward with a heavy push kick. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Kuli Jawa character raises the trowel flat in front of his face with his forearm braced. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Kuli Jawa character is struck in the face, head snaps back and body recoils, then recovers to stance. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Kuli Jawa character is launched into the air by an uppercut, body arching backward, limbs flailing. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Kuli Jawa character falls backward flat onto the floor, bounces once, then pushes up and stands again. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Kuli Jawa character takes a long sip of black coffee, steam rising, then exhales and flexes as his body tenses with energy. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Kuli Jawa character moves his hands in a rapid blur as if laying bricks, then lifts one leg for a kick. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Kuli Jawa character sits down tiredly and fans himself with the caping. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Kuli Jawa character leans on the trowel and sips coffee with a satisfied grin. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion loops seamlessly.",
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
  "prompt": "The Kuli Jawa character tips the caping and taps the trowel on his palm. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion loops seamlessly.",
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
| `kuli-jawa_coffee_steam` | Uap kopi (VFX) | 16 x 24 | 6 |
| `kuli-jawa_buff_aura` | Aura buff (VFX) | 48 x 64 | 6 |
| `kuli-jawa_brick_wall` | Tembok bata (aset ultimate) | 64 x 96 | 6 |
| `kuli-jawa_dust_cloud` | Debu roboh | 64 x 32 | 6 |

### kuli-jawa_coffee_steam

```json
{
  "prompt": "thin wisps of white steam rising and curling, looping. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos. Transparent background.",
  "width": 16,
  "height": 24,
  "pixel": true,
  "bg_mode": "transparent",
  "colors": ["#010000", "#111420", "#2b0e08", "#391d14", "#212842", "#442f24", "#5e3028", "#4c4039", "#3a4260", "#724e3c", "#5b5958", "#746f6b", "#96674d", "#8e8b8a", "#b0875d", "#c6976b", "#e0a379", "#bab1a9", "#dddddd", "#efeeed"],
  "style_asset_ids": ["<ASSET_ID_GAMBAR_DASAR>"]
}
```

Lalu `animate_game_art` dengan `output_frames: 6`.

### kuli-jawa_buff_aura

```json
{
  "prompt": "a flickering orange-red heat aura around a body outline, looping. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos. Transparent background.",
  "width": 48,
  "height": 64,
  "pixel": true,
  "bg_mode": "transparent",
  "colors": ["#010000", "#111420", "#2b0e08", "#391d14", "#212842", "#442f24", "#5e3028", "#4c4039", "#3a4260", "#724e3c", "#5b5958", "#746f6b", "#96674d", "#8e8b8a", "#b0875d", "#c6976b", "#e0a379", "#bab1a9", "#dddddd", "#efeeed"],
  "style_asset_ids": ["<ASSET_ID_GAMBAR_DASAR>"]
}
```

Lalu `animate_game_art` dengan `output_frames: 6`.

### kuli-jawa_brick_wall

```json
{
  "prompt": "a red brick wall being built up row by row, then toppling forward and breaking apart. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos. Transparent background.",
  "width": 64,
  "height": 96,
  "pixel": true,
  "bg_mode": "transparent",
  "colors": ["#010000", "#111420", "#2b0e08", "#391d14", "#212842", "#442f24", "#5e3028", "#4c4039", "#3a4260", "#724e3c", "#5b5958", "#746f6b", "#96674d", "#8e8b8a", "#b0875d", "#c6976b", "#e0a379", "#bab1a9", "#dddddd", "#efeeed"],
  "style_asset_ids": ["<ASSET_ID_GAMBAR_DASAR>"]
}
```

Lalu `animate_game_art` dengan `output_frames: 6`.

### kuli-jawa_dust_cloud

```json
{
  "prompt": "a puff of grey construction dust expanding and fading. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos. Transparent background.",
  "width": 64,
  "height": 32,
  "pixel": true,
  "bg_mode": "transparent",
  "colors": ["#010000", "#111420", "#2b0e08", "#391d14", "#212842", "#442f24", "#5e3028", "#4c4039", "#3a4260", "#724e3c", "#5b5958", "#746f6b", "#96674d", "#8e8b8a", "#b0875d", "#c6976b", "#e0a379", "#bab1a9", "#dddddd", "#efeeed"],
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
