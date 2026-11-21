# Stage: Depan Gedung DPR

Suasana: senja ungu-jingga, sisa demo.

## Cara kerja

SpriteCook membatasi lebar gambar 512 piksel, padahal stage IndoFight 960 piksel. Karena itu setiap layer dibuat dengan cara berbeda:

| Layer | Faktor geser | Lebar yang dibutuhkan | Cara buat |
| --- | --- | --- | --- |
| Skybox / dinding | 0,1x | sekitar 512 | 1 gambar 512 x 288 |
| Background | 0,5x | sekitar 720 | 2 bagian 512 x 288 lalu disambung |
| Midground lantai | 1,0x | 960 | tekstur 64 x 48 yang diulang + hiasan terpisah |
| Foreground | 1,2x | 1056 | potongan benda yang ditata di engine, sebagian tile |

Urutan: buat Background bagian kiri dulu, ekstrak paletnya dengan `tools/extract_palette.py` menjadi `art/palettes/stage-dpr.hex`, lalu pakai palet itu (`colors`) dan gambar itu (`style_asset_ids`) untuk SEMUA layer lain di stage ini.

Referensi gaya sudah ada: `art/reference/referensi-stage-dpr.png`. Unggah dulu, lalu pakai sebagai `style_asset_ids`. Palet awal tersedia di `art/palettes/stage-dpr.hex`. Teks spanduk di referensi rusak, jadi tulis ulang manual di Aseprite.

Aturan: lantai karakter berpijak ada di baris piksel 238 dari 270. Jangan taruh benda terang atau ramai di area tengah setinggi karakter (baris 120 sampai 238), supaya petarung tetap terbaca.

## Skybox (`stage_dpr_sky`)

```json
{
  "prompt": "a wide dusk sky gradient from deep purple at the top to warm orange at the horizon with scattered pink-orange pixel clouds, no buildings. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
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

## Background (`stage_dpr_bg`)

Bagian kiri:

```json
{
  "prompt": "an Indonesian parliament building with a large green dome and a long grey modernist facade behind a tall green iron fence and a closed green gate, graffiti on the fence pillars, a torn protest banner and red-and-white flags tied to the fence, thin drifting tear-gas haze, seen straight-on from street level at dusk. This is the left half of a wide panoramic stage background; the right edge must continue seamlessly. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
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
  "prompt": "an Indonesian parliament building with a large green dome and a long grey modernist facade behind a tall green iron fence and a closed green gate, graffiti on the fence pillars, a torn protest banner and red-and-white flags tied to the fence, thin drifting tear-gas haze, seen straight-on from street level at dusk. This is the right half of a wide panoramic stage background; continue seamlessly from the reference image's right edge. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
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

## Midground lantai (tile) (`stage_dpr_floor`)

```json
{
  "prompt": "a seamless horizontally tileable strip of cracked dark asphalt road with a faded white lane marking, top-down slanted perspective, ends tile left to right. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
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

## Midground hiasan lantai (`stage_dpr_floor_decals`)

```json
{
  "prompt": "scattered street debris on asphalt: spray-paint graffiti marks, crumpled papers, empty plastic water bottles and two old tyres, transparent background. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
  "width": 160,
  "height": 48,
  "pixel": true,
  "bg_mode": "transparent",
  "mode": "assets",
  "smart_crop": true,
  "colors": ["<palet stage>"],
  "style_asset_ids": ["<ASSET_ID_BACKGROUND_STAGE_INI>"]
}
```

## Asap ban (animasi) (`stage_dpr_smoke_tyre`)

```json
{
  "prompt": "a thin column of grey smoke rising from a smouldering tyre, looping. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
  "width": 32,
  "height": 64,
  "pixel": true,
  "bg_mode": "transparent",
  "mode": "assets",
  "smart_crop": true,
  "colors": ["<palet stage>"],
  "style_asset_ids": ["<ASSET_ID_BACKGROUND_STAGE_INI>"]
}
```

Lalu `animate_game_art` dengan `output_frames: 8`, `output_format: "spritesheet"`, prompt berisi gerakan loop yang halus.

## Foreground kawat berduri (tile) (`stage_dpr_fg_wire`)

```json
{
  "prompt": "a seamless horizontally tileable segment of coiled barbed-wire barricade on short posts, dark silhouette, slightly out of focus. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
  "width": 96,
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

## Foreground barikade beton (`stage_dpr_fg_barrier`)

```json
{
  "prompt": "a grey concrete jersey road barrier with faded graffiti, slightly blurred dark foreground object, transparent background. 16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated.",
  "width": 96,
  "height": 48,
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
