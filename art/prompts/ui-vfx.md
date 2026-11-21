# UI, HUD, dan VFX

UI dan HUD dibuat dengan skill `spritecook-build-ui-kits`, bukan `generate_game_art(mode="ui")` satu per satu. Skill itu membuat satu konsep layar dulu, lalu memotong komponen dari konsep yang sama, sehingga semua tombol dan bar satu gaya.

## Konsep UI kit

Prompt konsep untuk `create_ui_kit`:

> A 16-bit pixel art fighting game HUD for a 480 x 270 screen, neon modern-grunge style inspired by Indonesian street culture: chunky metal-framed health bars at top left and top right with green fill, a digital 99 timer in the centre top, round-win dots beside the timer, neon blue energy bars at bottom left and bottom right, small square character portraits under each health bar. Spray-paint texture accents, rusty metal bolts, neon cyan and magenta glow, crisp hard pixels, no anti-aliasing.

Gunakan konsep yang sama untuk layar Character Select dan Main Menu supaya satu keluarga visual. Ikuti tata letak HUD di GDD bagian 5.3.

## Daftar komponen UI

| Kode | Isi | Ukuran asli | Variasi/frame |
| --- | --- | --- | --- |
| `ui_kit_concept` | Konsep layar pertarungan lengkap (HUD) | 480x270 | 1 |
| `ui_hp_frame` | Frame health bar (kiri, dicerminkan untuk kanan) | 200x16 | 1 |
| `ui_hp_fill` | Isi health bar hijau, kuning, merah + lapisan hilang | 192x8 | 3 |
| `ui_energy_frame` | Frame energy bar | 160x12 | 1 |
| `ui_energy_fill` | Isi energy bar biru neon dan emas berkedip | 152x6 | 4 |
| `ui_timer_frame` | Frame timer | 40x28 | 1 |
| `ui_digits` | Angka digital 0-9 | 10x16 per angka | 10 |
| `ui_round_dots` | Penanda ronde menyala dan mati | 8x8 | 2 |
| `ui_text_fight` | Teks FIGHT! | 200x60 | 6 |
| `ui_text_ko` | Teks K.O. | 200x60 | 6 |
| `ui_text_perfect` | Teks PERFECT | 200x48 | 6 |
| `ui_text_timeup` | Teks TIME UP | 200x48 | 6 |
| `ui_text_round` | Teks ROUND 1, 2, 3 | 160x40 | 3 |
| `ui_text_combo` | Teks COMBO x | 96x24 | 1 |
| `ui_btn_menu` | Tombol menu Normal, Hover, Pressed | 120x24 | 3 |
| `ui_select_cursor` | Kursor P1 merah dan P2 biru | 68x68 | 2 |
| `ui_select_frame` | Bingkai grid Character Select | 64x64 | 1 |
| `ui_touch_joystick` | Joystick virtual (mobile) | 56x56 | 2 |
| `ui_touch_buttons` | 6 tombol aksi LP HP LK HK Skill Ultimate (mobile) | 24x24 | 12 |
| `ui_logo` | Logo IndoFight besar dan kecil | 240x80 | 2 |

Font: teks FIGHT!, K.O., dan nama karakter digambar sebagai sprite. Untuk font menu, pakai font pixel bebas lisensi (misalnya dari Lospec atau itch.io) dan catat lisensinya di `docs/credits.md`.

## Efek visual umum

Semua efek bergaya komik tanpa darah. Overlay hitam-putih atau merah saat ultimate, layar bergetar, dan hitstop dibuat di engine dengan shader dan kode, bukan sprite.

| Kode | Isi | Ukuran | Frame |
| --- | --- | --- | --- |
| `vfx_hitspark_blunt` | Hit spark tumpul | 48 x 48 | 6 |
| `vfx_hitspark_slash` | Hit spark tajam | 64 x 32 | 6 |
| `vfx_blockspark` | Block spark | 48 x 48 | 6 |
| `vfx_impact_flash` | Impact flash | 64 x 64 | 4 |
| `vfx_speedlines` | Speed lines | 128 x 64 | 4 |
| `vfx_dash_dust` | Dash dust | 48 x 24 | 6 |
| `vfx_land_dust` | Debu mendarat | 64 x 24 | 6 |
| `vfx_screen_crack` | Screen crack | 240 x 135 | 4 |
| `vfx_status_stun` | Ikon Stun | 24 x 16 | 6 |
| `vfx_status_burn` | Ikon Burn | 16 x 16 | 6 |
| `vfx_status_blind` | Ikon Blind | 16 x 16 | 4 |
| `vfx_status_slow` | Ikon Slow | 16 x 16 | 4 |
| `vfx_status_buff` | Ikon Buff | 16 x 16 | 4 |

### vfx_hitspark_blunt

```json
{
  "prompt": "a comic-style white and yellow impact starburst with short speed lines, for blunt hits. 16-bit pixel art game VFX, crisp hard pixels, no anti-aliasing, transparent background.",
  "width": 48,
  "height": 48,
  "pixel": true,
  "bg_mode": "transparent"
}
```

Lalu `animate_game_art` dengan `output_frames: 6`, `output_format: "spritesheet"`.

### vfx_hitspark_slash

```json
{
  "prompt": "a sharp white crescent slash streak with small sparks, for blade and broom hits. 16-bit pixel art game VFX, crisp hard pixels, no anti-aliasing, transparent background.",
  "width": 64,
  "height": 32,
  "pixel": true,
  "bg_mode": "transparent"
}
```

Lalu `animate_game_art` dengan `output_frames: 6`, `output_format: "spritesheet"`.

### vfx_blockspark

```json
{
  "prompt": "a blue hexagonal energy shield flash with orange sparks bouncing off. 16-bit pixel art game VFX, crisp hard pixels, no anti-aliasing, transparent background.",
  "width": 48,
  "height": 48,
  "pixel": true,
  "bg_mode": "transparent"
}
```

Lalu `animate_game_art` dengan `output_frames: 6`, `output_format: "spritesheet"`.

### vfx_impact_flash

```json
{
  "prompt": "a big white round flash ring expanding and vanishing. 16-bit pixel art game VFX, crisp hard pixels, no anti-aliasing, transparent background.",
  "width": 64,
  "height": 64,
  "pixel": true,
  "bg_mode": "transparent"
}
```

Lalu `animate_game_art` dengan `output_frames: 4`, `output_format: "spritesheet"`.

### vfx_speedlines

```json
{
  "prompt": "comic manga speed lines streaking horizontally, white on transparent. 16-bit pixel art game VFX, crisp hard pixels, no anti-aliasing, transparent background.",
  "width": 128,
  "height": 64,
  "pixel": true,
  "bg_mode": "transparent"
}
```

Lalu `animate_game_art` dengan `output_frames: 4`, `output_format: "spritesheet"`.

### vfx_dash_dust

```json
{
  "prompt": "a small puff of grey-brown ground dust kicked up behind a foot. 16-bit pixel art game VFX, crisp hard pixels, no anti-aliasing, transparent background.",
  "width": 48,
  "height": 24,
  "pixel": true,
  "bg_mode": "transparent"
}
```

Lalu `animate_game_art` dengan `output_frames: 6`, `output_format: "spritesheet"`.

### vfx_land_dust

```json
{
  "prompt": "a symmetrical ring of dust puffs when landing from a jump. 16-bit pixel art game VFX, crisp hard pixels, no anti-aliasing, transparent background.",
  "width": 64,
  "height": 24,
  "pixel": true,
  "bg_mode": "transparent"
}
```

Lalu `animate_game_art` dengan `output_frames: 6`, `output_format: "spritesheet"`.

### vfx_screen_crack

```json
{
  "prompt": "white cracked-glass lines spreading from a central impact point, transparent background. 16-bit pixel art game VFX, crisp hard pixels, no anti-aliasing, transparent background.",
  "width": 240,
  "height": 135,
  "pixel": true,
  "bg_mode": "transparent"
}
```

Lalu `animate_game_art` dengan `output_frames: 4`, `output_format: "spritesheet"`.

### vfx_status_stun

```json
{
  "prompt": "three small yellow stars circling, looping. 16-bit pixel art game VFX, crisp hard pixels, no anti-aliasing, transparent background.",
  "width": 24,
  "height": 16,
  "pixel": true,
  "bg_mode": "transparent"
}
```

Lalu `animate_game_art` dengan `output_frames: 6`, `output_format: "spritesheet"`.

### vfx_status_burn

```json
{
  "prompt": "a small orange flame flickering, looping. 16-bit pixel art game VFX, crisp hard pixels, no anti-aliasing, transparent background.",
  "width": 16,
  "height": 16,
  "pixel": true,
  "bg_mode": "transparent"
}
```

Lalu `animate_game_art` dengan `output_frames: 6`, `output_format: "spritesheet"`.

### vfx_status_blind

```json
{
  "prompt": "a small closed-eye symbol with red chili drips, looping. 16-bit pixel art game VFX, crisp hard pixels, no anti-aliasing, transparent background.",
  "width": 16,
  "height": 16,
  "pixel": true,
  "bg_mode": "transparent"
}
```

Lalu `animate_game_art` dengan `output_frames: 4`, `output_format: "spritesheet"`.

### vfx_status_slow

```json
{
  "prompt": "a small purple snail symbol, looping. 16-bit pixel art game VFX, crisp hard pixels, no anti-aliasing, transparent background.",
  "width": 16,
  "height": 16,
  "pixel": true,
  "bg_mode": "transparent"
}
```

Lalu `animate_game_art` dengan `output_frames: 4`, `output_format: "spritesheet"`.

### vfx_status_buff

```json
{
  "prompt": "a small orange upward arrow pulsing, looping. 16-bit pixel art game VFX, crisp hard pixels, no anti-aliasing, transparent background.",
  "width": 16,
  "height": 16,
  "pixel": true,
  "bg_mode": "transparent"
}
```

Lalu `animate_game_art` dengan `output_frames: 4`, `output_format: "spritesheet"`.

