# Stage: Lobi Istana / Kemenhan

Suasana: dalam ruangan, formal, mengkilap.

## Cara kerja

SpriteCook membatasi lebar gambar 512 piksel, padahal stage IndoFight 960 piksel. Karena itu setiap layer dibuat dengan cara berbeda:

| Layer | Faktor geser | Lebar yang dibutuhkan | Cara buat |
| --- | --- | --- | --- |
| Skybox / dinding | 0,1x | sekitar 512 | 1 gambar 512 x 288 |
| Background | 0,5x | sekitar 720 | 2 bagian 512 x 288 lalu disambung |
| Midground lantai | 1,0x | 960 | tekstur 64 x 48 yang diulang + hiasan terpisah |
| Foreground | 1,2x | 1056 | potongan benda yang ditata di engine, sebagian tile |

Urutan: buat Background bagian kiri dulu, ekstrak paletnya dengan `tools/extract_palette.py` menjadi `art/palettes/stage-istana.hex`, lalu pakai palet itu (`colors`) dan gambar itu (`style_asset_ids`) untuk SEMUA layer lain di stage ini.

Aturan: lantai karakter berpijak ada di baris piksel 238 dari 270. Jangan taruh benda terang atau ramai di area tengah setinggi karakter (baris 120 sampai 238), supaya petarung tetap terbaca.

## Dinding belakang (pengganti skybox) (`stage_istana_wall`)

```json
{
  "prompt": "a tall cream-coloured formal state hall wall with an ornate carved ceiling cornice and tall windows with heavy curtains, warm chandelier light. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
  "width": 512,
  "height": 288,
  "pixel": true,
  "bg_mode": "include",
  "mode": "assets",
  "smart_crop": false,
  "colors": ["<palet stage>"],
  "style_asset_ids": ["<ASSET_ID_BACKGROUND_STAGE_INI>"]
}
```

## Background (`stage_istana_bg`)

Bagian kiri:

```json
{
  "prompt": "a grand Indonesian state lobby interior with large framed paintings of national heroes, red-and-white flags on brass poles and two ceremonial honour guards in white uniforms standing perfectly still, symmetrical composition. This is the left half of a wide panoramic stage background; the right edge must continue seamlessly. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
  "width": 512,
  "height": 288,
  "aspect_ratio": "16:9",
  "pixel": true,
  "bg_mode": "include",
  "smart_crop": false,
  "style_asset_ids": ["<ASSET_ID_REFERENSI_STAGE>"]
}
```

Bagian kanan:

```json
{
  "prompt": "a grand Indonesian state lobby interior with large framed paintings of national heroes, red-and-white flags on brass poles and two ceremonial honour guards in white uniforms standing perfectly still, symmetrical composition. This is the right half of a wide panoramic stage background; continue seamlessly from the reference image's right edge. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
  "width": 512,
  "height": 288,
  "aspect_ratio": "16:9",
  "pixel": true,
  "bg_mode": "include",
  "smart_crop": false,
  "colors": ["<palet stage, isi setelah langkah ekstrak>"],
  "reference_asset_id": "<ASSET_ID_BAGIAN_KIRI>",
  "style_asset_ids": ["<ASSET_ID_REFERENSI_STAGE>"]
}
```

Sambung kedua bagian di Aseprite menjadi 720 x 270, rapikan sambungan, dan pastikan bagian bawah transparan di bawah garis lantai.

## Midground lantai (tile) (`stage_istana_floor`)

```json
{
  "prompt": "a seamless horizontally tileable strip of polished white marble floor with a thick red carpet runner across the middle, shiny reflections. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
  "width": 64,
  "height": 48,
  "pixel": true,
  "bg_mode": "include",
  "mode": "texture",
  "smart_crop": false,
  "colors": ["<palet stage>"],
  "style_asset_ids": ["<ASSET_ID_BACKGROUND_STAGE_INI>"]
}
```

Cek dengan menaruh 3 salinan berdampingan di Aseprite. Sambungan tidak boleh terlihat.

## Penjaga berkedip (animasi) (`stage_istana_guard_blink`)

```json
{
  "prompt": "a ceremonial honour guard in white uniform standing at attention, blinking once, looping idle. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
  "width": 32,
  "height": 80,
  "pixel": true,
  "bg_mode": "transparent",
  "mode": "assets",
  "smart_crop": true,
  "colors": ["<palet stage>"],
  "style_asset_ids": ["<ASSET_ID_BACKGROUND_STAGE_INI>"]
}
```

Lalu `animate_game_art` dengan `output_frames: 4`, `output_format: "spritesheet"`, prompt berisi gerakan loop yang halus.

## Foreground pilar marmer (`stage_istana_fg_pillar`)

```json
{
  "prompt": "a huge white marble column with a gold-trimmed capital, seen close and slightly blurred, transparent background. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
  "width": 64,
  "height": 270,
  "pixel": true,
  "bg_mode": "transparent",
  "mode": "assets",
  "smart_crop": true,
  "colors": ["<palet stage>"],
  "style_asset_ids": ["<ASSET_ID_BACKGROUND_STAGE_INI>"]
}
```

## Checklist

- [ ] Palet stage dikunci dan dipakai di semua layer
- [ ] Background tersambung tanpa jahitan terlihat
- [ ] Lantai berulang tanpa jahitan
- [ ] Area tengah tidak lebih ramai daripada karakter
- [ ] Semua layer PNG transparan kecuali skybox/dinding
- [ ] Dicoba di engine dengan 2 karakter dan HUD
