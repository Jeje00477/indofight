# Stage: Gang Sempit Perkampungan

Suasana: malam, padat, basah.

## Cara kerja

SpriteCook membatasi lebar gambar 512 piksel, padahal stage IndoFight 960 piksel. Karena itu setiap layer dibuat dengan cara berbeda:

| Layer | Faktor geser | Lebar yang dibutuhkan | Cara buat |
| --- | --- | --- | --- |
| Skybox / dinding | 0,1x | sekitar 512 | 1 gambar 512 x 288 |
| Background | 0,5x | sekitar 720 | 2 bagian 512 x 288 lalu disambung |
| Midground lantai | 1,0x | 960 | tekstur 64 x 48 yang diulang + hiasan terpisah |
| Foreground | 1,2x | 1056 | potongan benda yang ditata di engine, sebagian tile |

Urutan: buat Background bagian kiri dulu, ekstrak paletnya dengan `tools/extract_palette.py` menjadi `art/palettes/stage-gang.hex`, lalu pakai palet itu (`colors`) dan gambar itu (`style_asset_ids`) untuk SEMUA layer lain di stage ini.

Aturan: lantai karakter berpijak ada di baris piksel 238 dari 270. Jangan taruh benda terang atau ramai di area tengah setinggi karakter (baris 120 sampai 238), supaya petarung tetap terbaca.

## Skybox (`stage_gang_sky`)

```json
{
  "prompt": "a cloudy dark navy night sky over a city with an orange light-pollution glow at the horizon. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
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

## Background (`stage_gang_bg`)

Bagian kiri:

```json
{
  "prompt": "a dense Indonesian kampung alley at night: narrow two-storey houses with corrugated roofs, small shops with roll-up doors, a concrete utility pole with a chaotic tangle of electric cables, a flickering yellow street lamp, potted plants and laundry. This is the left half of a wide panoramic stage background; the right edge must continue seamlessly. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
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
  "prompt": "a dense Indonesian kampung alley at night: narrow two-storey houses with corrugated roofs, small shops with roll-up doors, a concrete utility pole with a chaotic tangle of electric cables, a flickering yellow street lamp, potted plants and laundry. This is the right half of a wide panoramic stage background; continue seamlessly from the reference image's right edge. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
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

## Lampu jalan berkedip (animasi) (`stage_gang_lamp_flicker`)

```json
{
  "prompt": "a yellow street lamp head flickering on and off, looping. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
  "width": 24,
  "height": 48,
  "pixel": true,
  "bg_mode": "transparent",
  "mode": "assets",
  "smart_crop": true,
  "colors": ["<palet stage>"],
  "style_asset_ids": ["<ASSET_ID_BACKGROUND_STAGE_INI>"]
}
```

Lalu `animate_game_art` dengan `output_frames: 4`, `output_format: "spritesheet"`, prompt berisi gerakan loop yang halus.

## Midground lantai (tile) (`stage_gang_floor`)

```json
{
  "prompt": "a seamless horizontally tileable strip of narrow interlocking concrete paving blocks, wet with small puddles reflecting yellow light. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
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

## Foreground gerobak bakso (`stage_gang_fg_cart`)

```json
{
  "prompt": "a parked Indonesian bakso food cart with glass display and a small roof, dark slightly blurred foreground object, transparent background. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
  "width": 112,
  "height": 80,
  "pixel": true,
  "bg_mode": "transparent",
  "mode": "assets",
  "smart_crop": true,
  "colors": ["<palet stage>"],
  "style_asset_ids": ["<ASSET_ID_BACKGROUND_STAGE_INI>"]
}
```

## Foreground jemuran (animasi) (`stage_gang_fg_laundry`)

```json
{
  "prompt": "a clothesline with colourful laundry and a floral house dress swaying in the wind, looping. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
  "width": 128,
  "height": 64,
  "pixel": true,
  "bg_mode": "transparent",
  "mode": "assets",
  "smart_crop": true,
  "colors": ["<palet stage>"],
  "style_asset_ids": ["<ASSET_ID_BACKGROUND_STAGE_INI>"]
}
```

Lalu `animate_game_art` dengan `output_frames: 6`, `output_format: "spritesheet"`, prompt berisi gerakan loop yang halus.

## Checklist

- [ ] Palet stage dikunci dan dipakai di semua layer
- [ ] Background tersambung tanpa jahitan terlihat
- [ ] Lantai berulang tanpa jahitan
- [ ] Area tengah tidak lebih ramai daripada karakter
- [ ] Semua layer PNG transparan kecuali skybox/dinding
- [ ] Dicoba di engine dengan 2 karakter dan HUD
