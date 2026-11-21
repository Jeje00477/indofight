# Jenderal Gemoy (The General): Lembar Prompt Produksi

Lembar ini dipakai bersama SpriteCook. Ikuti urutan bagian 1 sampai 6. Jangan lompat ke animasi sebelum gambar dasar disetujui.

## 0. Ringkasan

- Palet terkunci: `art/palettes/jenderal-gemoy.hex` (20 warna)
- Tinggi karakter berdiri: sekitar 106 piksel di kanvas 160 x 160, kaki di baris piksel 150
- Arah hadap: kanan. Arah kiri dibuat engine dengan flip, jangan digambar terpisah
- Kunci visual (wajib sama di semua frame):
    - Kemeja safari cokelat lengkap dengan saku dada
    - Kacamata hitam selalu dipakai
    - Nampan stainless di tangan, dipakai sebagai perisai
    - Tetap karikatur, bukan potret realistis tokoh nyata
- Perbaikan dari gambar referensi:
    - Di referensi frame pertama memegang molotov. Jangan pernah pakai frame itu sebagai referensi.

## 1. Gambar dasar (canonical)

Langkah awal: unggah `art/reference/characters/jenderal-gemoy.png` lewat skill `spritecook-upload-assets`, simpan asset_id-nya dengan label `jenderal-gemoy_ref`, lalu isi `<ASSET_ID_REFERENSI_KARAKTER>` di bawah. Referensi ini hanya acuan gaya, bukan desain final: kunci visual di bagian 0 yang menang bila berbeda.

Semua animasi dibuat dari SATU gambar ini. Generate 4 variasi, pilih 1, rapikan di Aseprite, unggah ulang, lalu simpan `asset_id`-nya di `production/spritecook-assets.json` dengan label `jenderal-gemoy_base`.

Alat: `generate_game_art`

```json
{
  "prompt": "a charismatic middle-aged Indonesian man drawn as a friendly caricature, upright military posture but slightly chubby, short neat grey hair, black sunglasses, a brown safari shirt with chest pockets and matching brown trousers, black shoes; he holds a rectangular stainless-steel school-lunch tray in front of him like a shield. Neutral fighting stance. side view, facing right, full body, standing on an invisible flat floor line, transparent background. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos.",
  "width": 160,
  "height": 160,
  "pixel": true,
  "bg_mode": "transparent",
  "style": "16-bit SNK / Metal Slug arcade pixel art",
  "theme": "Indonesian street satire fighting game",
  "colors": ["#1e0c06", "#1e1b19", "#3c2a1c", "#45382c", "#5b4328", "#504c48", "#795e39", "#6e6559", "#886e49", "#6f747b", "#a28555", "#898e94", "#c78f6d", "#a0a4aa", "#dfa279", "#bbbfc3", "#d6c8c0", "#d8d9db", "#e7e9ea", "#d8dde3"],
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
  "prompt": "Full-body character select splash art of a charismatic middle-aged Indonesian man drawn as a friendly caricature, upright military posture but slightly chubby, short neat grey hair, black sunglasses, a brown safari shirt with chest pockets and matching brown trousers, black shoes; he holds a rectangular stainless-steel school-lunch tray in front of him like a shield. Heroic three-quarter pose, slight low camera angle, dramatic rim light. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos. Transparent background.",
  "width": 270,
  "height": 480,
  "aspect_ratio": "9:16",
  "pixel": true,
  "bg_mode": "transparent",
  "colors": ["#1e0c06", "#1e1b19", "#3c2a1c", "#45382c", "#5b4328", "#504c48", "#795e39", "#6e6559", "#886e49", "#6f747b", "#a28555", "#898e94", "#c78f6d", "#a0a4aa", "#dfa279", "#bbbfc3", "#d6c8c0", "#d8d9db", "#e7e9ea", "#d8dde3"],
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
  "colors": ["#1e0c06", "#1e1b19", "#3c2a1c", "#45382c", "#5b4328", "#504c48", "#795e39", "#6e6559", "#886e49", "#6f747b", "#a28555", "#898e94", "#c78f6d", "#a0a4aa", "#dfa279", "#bbbfc3", "#d6c8c0", "#d8d9db", "#e7e9ea", "#d8dde3"],
  "reference_asset_id": "<ASSET_ID_GAMBAR_DASAR>"
}
```

## 4. Animasi (18 gerakan)

Walk Backward tidak dibuat sebagai job terpisah: engine memutar sheet Walk Forward secara terbalik (lihat `docs/decisions.md`).

Alat: `animate_game_art` dengan `asset_id` gambar dasar yang SAMA untuk setiap gerakan. Parameter tetap: `pixel: true`, `colors: 24`, `edge_margin: 6`, `output_format: "spritesheet"`, `auto_enhance_prompt: false`.

Jumlah frame dibulatkan ke genap karena SpriteCook hanya menerima 2 sampai 16 frame genap (Hit jadi 4, Knockdown jadi 6).

| No | Animasi | File | Frame | Loop |
| --- | --- | --- | --- | --- |
| 1 | Idle | `indofight_char_jenderal-gemoy_idle_sheet.png` | 6 | ya |
| 2 | Walk Forward | `indofight_char_jenderal-gemoy_walk_forward_sheet.png` | 8 | ya |
| 3 | Dash / Step | `indofight_char_jenderal-gemoy_dash_sheet.png` | 4 | tidak |
| 4 | Jump | `indofight_char_jenderal-gemoy_jump_sheet.png` | 6 | tidak |
| 5 | Crouch | `indofight_char_jenderal-gemoy_crouch_sheet.png` | 2 | tidak |
| 6 | Light Punch | `indofight_char_jenderal-gemoy_light_punch_sheet.png` | 4 | tidak |
| 7 | Heavy Punch | `indofight_char_jenderal-gemoy_heavy_punch_sheet.png` | 6 | tidak |
| 8 | Light Kick | `indofight_char_jenderal-gemoy_light_kick_sheet.png` | 4 | tidak |
| 9 | Heavy Kick | `indofight_char_jenderal-gemoy_heavy_kick_sheet.png` | 6 | tidak |
| 10 | Block | `indofight_char_jenderal-gemoy_block_sheet.png` | 2 | tidak |
| 11 | Hit | `indofight_char_jenderal-gemoy_hit_sheet.png` | 4 | tidak |
| 12 | Knockup | `indofight_char_jenderal-gemoy_knockup_sheet.png` | 4 | tidak |
| 13 | Knockdown | `indofight_char_jenderal-gemoy_knockdown_sheet.png` | 6 | tidak |
| 14 | Special Skill | `indofight_char_jenderal-gemoy_special_sheet.png` | 8 | tidak |
| 15 | Ultimate Cast | `indofight_char_jenderal-gemoy_ultimate_cast_sheet.png` | 10 | tidak |
| 16 | Defeat | `indofight_char_jenderal-gemoy_defeat_sheet.png` | 6 | tidak |
| 17 | Victory | `indofight_char_jenderal-gemoy_victory_sheet.png` | 8 | ya |
| 18 | Taunt | `indofight_char_jenderal-gemoy_taunt_sheet.png` | 6 | ya |

### 4.1 Idle

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Jenderal Gemoy character breathes in a steady fighting stance, chest and shoulders rising and falling slightly, feet planted, held props bobbing gently. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion loops seamlessly.",
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
  "prompt": "The Jenderal Gemoy character marches forward with a steady military gait, tray held at his side. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion loops seamlessly.",
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
  "prompt": "The Jenderal Gemoy character makes one quick low burst step forward, body leaning in, then settles back into stance. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Jenderal Gemoy character jumps with the tray held flat above his head. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Jenderal Gemoy character drops into a low crouched guard and holds it. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Jenderal Gemoy character throws a short, tight military jab from behind the tray. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Jenderal Gemoy character bashes forward with the flat face of the steel tray using his whole body weight. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Jenderal Gemoy character snaps a low close-quarters kick at the shin. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Jenderal Gemoy character drives forward with a heavy shoulder charge behind the tray. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Jenderal Gemoy character plants his feet and holds the steel tray up in front of his chest like a riot shield. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Jenderal Gemoy character is struck in the face, head snaps back and body recoils, then recovers to stance. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Jenderal Gemoy character is launched into the air by an uppercut, body arching backward, limbs flailing. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Jenderal Gemoy character falls backward flat onto the floor, bounces once, then pushes up and stands again. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Jenderal Gemoy character pulls a small milk carton from his pocket and flicks it forward side-arm with precise force like throwing a shuriken. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Jenderal Gemoy character points forward commandingly with an outstretched arm, then looks up to the sky. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Jenderal Gemoy character staggers, sunglasses tilting, and sits down heavily on the floor. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Jenderal Gemoy character stands at attention and gives a crisp formal salute. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion loops seamlessly.",
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
  "prompt": "The Jenderal Gemoy character adjusts his sunglasses with one finger and smiles. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion loops seamlessly.",
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
| `jenderal-gemoy_milk_carton` | Kotak susu (proyektil Susu Lempar) | 16 x 16 | 4 |
| `jenderal-gemoy_mbg_tray` | Nampan MBG jatuh (proyektil ultimate) | 32 x 24 | 4 |
| `jenderal-gemoy_ration_crate` | Kotak ransum berparasut | 32 x 48 | 6 |
| `jenderal-gemoy_heli_shadow` | Bayangan helikopter | 128 x 48 | 4 |

### jenderal-gemoy_milk_carton

```json
{
  "prompt": "a small white and blue milk carton spinning fast like a shuriken. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos. Transparent background.",
  "width": 16,
  "height": 16,
  "pixel": true,
  "bg_mode": "transparent",
  "colors": ["#1e0c06", "#1e1b19", "#3c2a1c", "#45382c", "#5b4328", "#504c48", "#795e39", "#6e6559", "#886e49", "#6f747b", "#a28555", "#898e94", "#c78f6d", "#a0a4aa", "#dfa279", "#bbbfc3", "#d6c8c0", "#d8d9db", "#e7e9ea", "#d8dde3"],
  "style_asset_ids": ["<ASSET_ID_GAMBAR_DASAR>"]
}
```

Lalu `animate_game_art` dengan `output_frames: 4`.

### jenderal-gemoy_mbg_tray

```json
{
  "prompt": "a rectangular stainless steel compartment lunch tray tumbling as it falls. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos. Transparent background.",
  "width": 32,
  "height": 24,
  "pixel": true,
  "bg_mode": "transparent",
  "colors": ["#1e0c06", "#1e1b19", "#3c2a1c", "#45382c", "#5b4328", "#504c48", "#795e39", "#6e6559", "#886e49", "#6f747b", "#a28555", "#898e94", "#c78f6d", "#a0a4aa", "#dfa279", "#bbbfc3", "#d6c8c0", "#d8d9db", "#e7e9ea", "#d8dde3"],
  "style_asset_ids": ["<ASSET_ID_GAMBAR_DASAR>"]
}
```

Lalu `animate_game_art` dengan `output_frames: 4`.

### jenderal-gemoy_ration_crate

```json
{
  "prompt": "a brown cardboard ration box hanging from a small white parachute, swaying as it descends. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos. Transparent background.",
  "width": 32,
  "height": 48,
  "pixel": true,
  "bg_mode": "transparent",
  "colors": ["#1e0c06", "#1e1b19", "#3c2a1c", "#45382c", "#5b4328", "#504c48", "#795e39", "#6e6559", "#886e49", "#6f747b", "#a28555", "#898e94", "#c78f6d", "#a0a4aa", "#dfa279", "#bbbfc3", "#d6c8c0", "#d8d9db", "#e7e9ea", "#d8dde3"],
  "style_asset_ids": ["<ASSET_ID_GAMBAR_DASAR>"]
}
```

Lalu `animate_game_art` dengan `output_frames: 6`.

### jenderal-gemoy_heli_shadow

```json
{
  "prompt": "a dark semi-transparent silhouette shadow of a military helicopter seen from the side, rotor blur. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos. Transparent background.",
  "width": 128,
  "height": 48,
  "pixel": true,
  "bg_mode": "transparent",
  "colors": ["#1e0c06", "#1e1b19", "#3c2a1c", "#45382c", "#5b4328", "#504c48", "#795e39", "#6e6559", "#886e49", "#6f747b", "#a28555", "#898e94", "#c78f6d", "#a0a4aa", "#dfa279", "#bbbfc3", "#d6c8c0", "#d8d9db", "#e7e9ea", "#d8dde3"],
  "style_asset_ids": ["<ASSET_ID_GAMBAR_DASAR>"]
}
```

Lalu `animate_game_art` dengan `output_frames: 4`.

## 6. Checklist sebelum karakter dianggap selesai

- [ ] Gambar dasar disetujui dan asset_id tersimpan di manifest
- [ ] 18 sprite sheet lolos `tools/validate_sprite.py` (palet, transparansi, garis kaki)
- [ ] Pivot di tengah telapak kaki sama di semua frame
- [ ] Splash 1080 x 1920 dan ikon 256 x 256 sudah diekspor 4x
- [ ] Semua properti dan efek di bagian 5 sudah dibuat
- [ ] Sudah dicoba di engine bersama HUD dan stage
- [ ] Baris karakter ini di `production/asset_manifest.csv` sudah berstatus done
