# Pocong Brawler (The Undead): Lembar Prompt Produksi

Lembar ini dipakai bersama SpriteCook. Ikuti urutan bagian 1 sampai 6. Jangan lompat ke animasi sebelum gambar dasar disetujui.

## 0. Ringkasan

- Palet terkunci: `art/palettes/pocong-brawler.hex` (15 warna)
- Tinggi karakter berdiri: sekitar 104 piksel di kanvas 160 x 160, kaki di baris piksel 150
- Arah hadap: kanan. Arah kiri dibuat engine dengan flip, jangan digambar terpisah
- Kunci visual (wajib sama di semua frame):
    - Kain kafan kusam, diikat di kepala dan kaki
    - Tali kafan dililit di kepalan seperti hand-wrap Muay Thai
    - Wajah gelap dengan dua mata menyala (wajib)
    - Semua gerakan berpindah tempat dengan melompat
- Perbaikan dari gambar referensi:
    - Mata di referensi masih hitam. Ganti dengan mata menyala.

## 1. Gambar dasar (canonical)

Langkah awal: unggah `art/reference/characters/pocong-brawler.png` lewat skill `spritecook-upload-assets`, simpan asset_id-nya dengan label `pocong-brawler_ref`, lalu isi `<ASSET_ID_REFERENSI_KARAKTER>` di bawah. Referensi ini hanya acuan gaya, bukan desain final: kunci visual di bagian 0 yang menang bila berbeda.

Semua animasi dibuat dari SATU gambar ini. Generate 4 variasi, pilih 1, rapikan di Aseprite, unggah ulang, lalu simpan `asset_id`-nya di `production/spritecook-assets.json` dengan label `pocong-brawler_base`.

Alat: `generate_game_art`

```json
{
  "prompt": "a modern Indonesian pocong ghost fighter, its whole body wrapped in a slightly dirty off-white burial shroud tied at the top of the head and at the feet, the shroud cords wrapped tightly around both fists like Muay Thai hand wraps, its face hidden in deep shadow with two glowing eyes; it moves by hopping because its feet are bound. Neutral fighting stance. side view, facing right, full body, standing on an invisible flat floor line, transparent background. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos.",
  "width": 160,
  "height": 160,
  "pixel": true,
  "bg_mode": "transparent",
  "style": "16-bit SNK / Metal Slug arcade pixel art",
  "theme": "Indonesian street satire fighting game",
  "colors": ["#221f1c", "#3c3734", "#494643", "#565450", "#65625e", "#78736e", "#88847f", "#a19c95", "#b0ada7", "#c0bbb5", "#d5d0c9", "#e8e1d7", "#fbf9f7", "#ff5a3c", "#ffd23f"],
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
  "prompt": "Full-body character select splash art of a modern Indonesian pocong ghost fighter, its whole body wrapped in a slightly dirty off-white burial shroud tied at the top of the head and at the feet, the shroud cords wrapped tightly around both fists like Muay Thai hand wraps, its face hidden in deep shadow with two glowing eyes; it moves by hopping because its feet are bound. Heroic three-quarter pose, slight low camera angle, dramatic rim light. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos. Transparent background.",
  "width": 270,
  "height": 480,
  "aspect_ratio": "9:16",
  "pixel": true,
  "bg_mode": "transparent",
  "colors": ["#221f1c", "#3c3734", "#494643", "#565450", "#65625e", "#78736e", "#88847f", "#a19c95", "#b0ada7", "#c0bbb5", "#d5d0c9", "#e8e1d7", "#fbf9f7", "#ff5a3c", "#ffd23f"],
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
  "colors": ["#221f1c", "#3c3734", "#494643", "#565450", "#65625e", "#78736e", "#88847f", "#a19c95", "#b0ada7", "#c0bbb5", "#d5d0c9", "#e8e1d7", "#fbf9f7", "#ff5a3c", "#ffd23f"],
  "reference_asset_id": "<ASSET_ID_GAMBAR_DASAR>"
}
```

## 4. Animasi (18 gerakan)

Walk Backward tidak dibuat sebagai job terpisah: engine memutar sheet Walk Forward secara terbalik (lihat `docs/decisions.md`).

Alat: `animate_game_art` dengan `asset_id` gambar dasar yang SAMA untuk setiap gerakan. Parameter tetap: `pixel: true`, `colors: 24`, `edge_margin: 6`, `output_format: "spritesheet"`, `auto_enhance_prompt: false`.

Jumlah frame dibulatkan ke genap karena SpriteCook hanya menerima 2 sampai 16 frame genap (Hit jadi 4, Knockdown jadi 6).

| No | Animasi | File | Frame | Loop |
| --- | --- | --- | --- | --- |
| 1 | Idle | `indofight_char_pocong-brawler_idle_sheet.png` | 6 | ya |
| 2 | Walk Forward | `indofight_char_pocong-brawler_walk_forward_sheet.png` | 8 | ya |
| 3 | Dash / Step | `indofight_char_pocong-brawler_dash_sheet.png` | 4 | tidak |
| 4 | Jump | `indofight_char_pocong-brawler_jump_sheet.png` | 6 | tidak |
| 5 | Crouch | `indofight_char_pocong-brawler_crouch_sheet.png` | 2 | tidak |
| 6 | Light Punch | `indofight_char_pocong-brawler_light_punch_sheet.png` | 4 | tidak |
| 7 | Heavy Punch | `indofight_char_pocong-brawler_heavy_punch_sheet.png` | 6 | tidak |
| 8 | Light Kick | `indofight_char_pocong-brawler_light_kick_sheet.png` | 4 | tidak |
| 9 | Heavy Kick | `indofight_char_pocong-brawler_heavy_kick_sheet.png` | 6 | tidak |
| 10 | Block | `indofight_char_pocong-brawler_block_sheet.png` | 2 | tidak |
| 11 | Hit | `indofight_char_pocong-brawler_hit_sheet.png` | 4 | tidak |
| 12 | Knockup | `indofight_char_pocong-brawler_knockup_sheet.png` | 4 | tidak |
| 13 | Knockdown | `indofight_char_pocong-brawler_knockdown_sheet.png` | 6 | tidak |
| 14 | Special Skill | `indofight_char_pocong-brawler_special_sheet.png` | 8 | tidak |
| 15 | Ultimate Cast | `indofight_char_pocong-brawler_ultimate_cast_sheet.png` | 10 | tidak |
| 16 | Defeat | `indofight_char_pocong-brawler_defeat_sheet.png` | 6 | tidak |
| 17 | Victory | `indofight_char_pocong-brawler_victory_sheet.png` | 8 | ya |
| 18 | Taunt | `indofight_char_pocong-brawler_taunt_sheet.png` | 6 | ya |

### 4.1 Idle

```json
{
  "asset_id": "<ASSET_ID_GAMBAR_DASAR>",
  "prompt": "The Pocong Brawler character breathes in a steady fighting stance, chest and shoulders rising and falling slightly, feet planted, held props bobbing gently. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion loops seamlessly.",
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
  "prompt": "The Pocong Brawler character hops forward in short bouncing hops with fists up. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion loops seamlessly.",
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
  "prompt": "The Pocong Brawler character makes one quick low burst step forward, body leaning in, then settles back into stance. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Pocong Brawler character springs high with both bound feet together. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Pocong Brawler character drops into a low crouched guard and holds it. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Pocong Brawler character throws a wrapped-fist jab. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Pocong Brawler character lunges forward with a hard headbutt. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Pocong Brawler character hops and kicks forward with both bound feet together. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Pocong Brawler character whips a loose shroud cord forward in a long lash. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Pocong Brawler character hunches and raises both wrapped fists in a Muay Thai guard. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Pocong Brawler character is struck in the face, head snaps back and body recoils, then recovers to stance. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Pocong Brawler character is launched into the air by an uppercut, body arching backward, limbs flailing. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Pocong Brawler character falls backward flat onto the floor, bounces once, then pushes up and stands again. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Pocong Brawler character hops high and dives head-first into the ground, disappearing. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Pocong Brawler character leans its shadowed face sharply toward the viewer, eyes flaring bright. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Pocong Brawler character topples stiffly backward like a falling log. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion starts and ends in the fighting stance.",
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
  "prompt": "The Pocong Brawler character bounces in place, fists raised. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion loops seamlessly.",
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
  "prompt": "The Pocong Brawler character tilts its head slowly with glowing eyes blinking. Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line. The motion loops seamlessly.",
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
| `pocong-brawler_ground_hole` | Lubang tanah Earth Dive | 48 x 16 | 6 |
| `pocong-brawler_jumpscare_face` | Wajah pocong layar penuh (ultimate) | 240 x 135 | 4 |
| `pocong-brawler_lifesteal` | Efek HP terserap | 48 x 48 | 6 |

### pocong-brawler_ground_hole

```json
{
  "prompt": "a dark hole opening in dirt ground with debris flying up. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos. Transparent background.",
  "width": 48,
  "height": 16,
  "pixel": true,
  "bg_mode": "transparent",
  "colors": ["#221f1c", "#3c3734", "#494643", "#565450", "#65625e", "#78736e", "#88847f", "#a19c95", "#b0ada7", "#c0bbb5", "#d5d0c9", "#e8e1d7", "#fbf9f7", "#ff5a3c", "#ffd23f"],
  "style_asset_ids": ["<ASSET_ID_GAMBAR_DASAR>"]
}
```

Lalu `animate_game_art` dengan `output_frames: 6`.

### pocong-brawler_jumpscare_face

```json
{
  "prompt": "an extreme close-up of a pocong ghost face in shadow wrapped in a dirty shroud, two huge glowing eyes, horror comic style, filling the frame. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos. Transparent background.",
  "width": 240,
  "height": 135,
  "pixel": true,
  "bg_mode": "transparent",
  "colors": ["#221f1c", "#3c3734", "#494643", "#565450", "#65625e", "#78736e", "#88847f", "#a19c95", "#b0ada7", "#c0bbb5", "#d5d0c9", "#e8e1d7", "#fbf9f7", "#ff5a3c", "#ffd23f"],
  "style_asset_ids": ["<ASSET_ID_GAMBAR_DASAR>"]
}
```

Lalu `animate_game_art` dengan `output_frames: 4`.

### pocong-brawler_lifesteal

```json
{
  "prompt": "small red glowing orbs streaming in an arc, looping. 16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, no anti-aliasing, no text, no brand logos. Transparent background.",
  "width": 48,
  "height": 48,
  "pixel": true,
  "bg_mode": "transparent",
  "colors": ["#221f1c", "#3c3734", "#494643", "#565450", "#65625e", "#78736e", "#88847f", "#a19c95", "#b0ada7", "#c0bbb5", "#d5d0c9", "#e8e1d7", "#fbf9f7", "#ff5a3c", "#ffd23f"],
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
