"""Generate IndoFight stage, UI, VFX and audio prompt sheets plus their manifest rows.
Usage: python3 -I gen_stages.py <kit_dir>
"""
import sys, os, json, re

KIT = sys.argv[1]
STYLE = ("16-bit pixel art fighting game background in the style of 1990s SNK arcade stages, crisp hard pixels, "
         "no anti-aliasing, rich atmospheric lighting, readable shapes, no characters in the foreground, no text unless stated")


def jd(o):
    t = json.dumps(o, indent=2, ensure_ascii=False)
    return re.sub(r'\[\s*\n((?:\s*"[^"\n]*",?\s*\n)+)\s*\]',
                  lambda m: "[" + ", ".join(x.strip().rstrip(",") for x in m.group(1).strip().splitlines()) + "]", t)

# layer: (code, layer name, kind, w, h, frames, prompt)
# kind: "wide" = two 512x288 halves stitched to ~720 wide; "single" = one image; "tile" = seamless texture; "prop" = separate object
S = {}
S["dpr"] = dict(nama="Depan Gedung DPR", suasana="senja ungu-jingga, sisa demo", ref="art/reference/referensi-stage-dpr.png", layers=[
    ("sky", "Skybox", "single", 512, 288, 1, "a wide dusk sky gradient from deep purple at the top to warm orange at the horizon with scattered pink-orange pixel clouds, no buildings"),
    ("bg", "Background", "wide", 720, 270, 1, "an Indonesian parliament building with a large green dome and a long grey modernist facade behind a tall green iron fence and a closed green gate, graffiti on the fence pillars, a torn protest banner and red-and-white flags tied to the fence, thin drifting tear-gas haze, seen straight-on from street level at dusk"),
    ("floor", "Midground lantai (tile)", "tile", 64, 48, 1, "a seamless horizontally tileable strip of cracked dark asphalt road with a faded white lane marking, top-down slanted perspective, ends tile left to right"),
    ("floor_decals", "Midground hiasan lantai", "prop", 160, 48, 1, "scattered street debris on asphalt: spray-paint graffiti marks, crumpled papers, empty plastic water bottles and two old tyres, transparent background"),
    ("smoke_tyre", "Asap ban (animasi)", "prop", 32, 64, 8, "a thin column of grey smoke rising from a smouldering tyre, looping"),
    ("fg_wire", "Foreground kawat berduri (tile)", "tile", 96, 48, 1, "a seamless horizontally tileable segment of coiled barbed-wire barricade on short posts, dark silhouette, slightly out of focus"),
    ("fg_barrier", "Foreground barikade beton", "prop", 96, 48, 1, "a grey concrete jersey road barrier with faded graffiti, slightly blurred dark foreground object, transparent background"),
])
S["istana"] = dict(nama="Lobi Istana / Kemenhan", suasana="dalam ruangan, formal, mengkilap", ref=None, layers=[
    ("wall", "Dinding belakang (pengganti skybox)", "single", 512, 288, 1, "a tall cream-coloured formal state hall wall with an ornate carved ceiling cornice and tall windows with heavy curtains, warm chandelier light"),
    ("bg", "Background", "wide", 720, 270, 1, "a grand Indonesian state lobby interior with large framed paintings of national heroes, red-and-white flags on brass poles and two ceremonial honour guards in white uniforms standing perfectly still, symmetrical composition"),
    ("floor", "Midground lantai (tile)", "tile", 64, 48, 1, "a seamless horizontally tileable strip of polished white marble floor with a thick red carpet runner across the middle, shiny reflections"),
    ("guard_blink", "Penjaga berkedip (animasi)", "prop", 32, 80, 4, "a ceremonial honour guard in white uniform standing at attention, blinking once, looping idle"),
    ("fg_pillar", "Foreground pilar marmer", "prop", 64, 270, 1, "a huge white marble column with a gold-trimmed capital, seen close and slightly blurred, transparent background"),
])
S["prambanan"] = dict(nama="Candi Prambanan Malam", suasana="malam purnama, magis", ref=None, layers=[
    ("sky", "Skybox", "single", 512, 288, 1, "a deep blue night sky with a huge glowing full moon, faint stars and thin silver clouds"),
    ("bg", "Background", "wide", 720, 270, 1, "the silhouettes of tall Hindu temple spires of Prambanan, Central Java, lit from behind by moonlight, intricate stone carvings catching blue light, distant palm trees"),
    ("lightning", "Kilat petir (animasi)", "prop", 64, 160, 4, "a jagged white-blue lightning bolt striking down and flashing out"),
    ("floor", "Midground lantai (tile)", "tile", 64, 48, 1, "a seamless horizontally tileable strip of ancient dark grey andesite temple stone floor with worn carved blocks and moss"),
    ("fg_grass", "Foreground rumput gelap (tile)", "tile", 96, 40, 1, "a seamless horizontally tileable strip of dark tall grass silhouettes, slightly blurred"),
    ("fg_torch", "Foreground obor (animasi)", "prop", 24, 72, 6, "a traditional bamboo torch with a flickering orange flame, looping"),
])
S["gang"] = dict(nama="Gang Sempit Perkampungan", suasana="malam, padat, basah", ref=None, layers=[
    ("sky", "Skybox", "single", 512, 288, 1, "a cloudy dark navy night sky over a city with an orange light-pollution glow at the horizon"),
    ("bg", "Background", "wide", 720, 270, 1, "a dense Indonesian kampung alley at night: narrow two-storey houses with corrugated roofs, small shops with roll-up doors, a concrete utility pole with a chaotic tangle of electric cables, a flickering yellow street lamp, potted plants and laundry"),
    ("lamp_flicker", "Lampu jalan berkedip (animasi)", "prop", 24, 48, 4, "a yellow street lamp head flickering on and off, looping"),
    ("floor", "Midground lantai (tile)", "tile", 64, 48, 1, "a seamless horizontally tileable strip of narrow interlocking concrete paving blocks, wet with small puddles reflecting yellow light"),
    ("fg_cart", "Foreground gerobak bakso", "prop", 112, 80, 1, "a parked Indonesian bakso food cart with glass display and a small roof, dark slightly blurred foreground object, transparent background"),
    ("fg_laundry", "Foreground jemuran (animasi)", "prop", 128, 64, 6, "a clothesline with colourful laundry and a floral house dress swaying in the wind, looping"),
])
S["proyek"] = dict(nama="Proyek Mangkrak", suasana="ketinggian, berdebu, senja berkabut", ref=None, layers=[
    ("sky", "Skybox", "single", 512, 288, 1, "a hazy orange-grey dusk sky over a big Asian city, smoggy horizon"),
    ("bg", "Background", "wide", 720, 270, 1, "an unfinished concrete high-rise construction site with bamboo and steel scaffolding, exposed rebar and hanging tarps, distant skyscrapers of Jakarta seen from high up through the haze"),
    ("tarp", "Terpal berkibar (animasi)", "prop", 48, 64, 6, "a torn blue construction tarp flapping in the wind, looping"),
    ("floor", "Midground lantai (tile)", "tile", 64, 48, 1, "a seamless horizontally tileable strip of rough unfinished grey concrete floor with cracks and cement stains"),
    ("fg_pipes", "Foreground pipa dan sak semen", "prop", 128, 64, 1, "a pile of rusty steel pipes and stacked cement sacks, dark slightly blurred foreground object, transparent background"),
])
S["warnet"] = dict(nama="Warnet \"Berkah\"", suasana="dalam ruangan, pengap, neon biru-ungu", ref=None, layers=[
    ("wall", "Dinding belakang (pengganti skybox)", "single", 512, 288, 1, "a stuffy internet cafe back wall with peeling paint, old faded video game posters with unreadable titles and a dim blue-purple neon strip light"),
    ("bg", "Background", "wide", 720, 270, 1, "rows of old desktop computers in small wooden booths with glowing monitors showing colourful games, tangled cables, dim blue and purple neon lighting, a small counter with a sleepy operator in the distance"),
    ("screen_flicker", "Layar PC berkedip (animasi)", "prop", 32, 24, 4, "a small CRT-style monitor screen flickering between game scenes, looping"),
    ("floor", "Midground lantai (tile)", "tile", 64, 48, 1, "a seamless horizontally tileable strip of worn off-white ceramic floor tiles with grime in the grout"),
    ("fg_chair", "Foreground kursi plastik", "prop", 48, 64, 1, "a red plastic stackable chair, dark slightly blurred foreground object, transparent background"),
    ("fg_cups", "Foreground gelas minuman energi", "prop", 64, 48, 1, "a messy stack of empty plastic energy drink cups and cans, slightly blurred, transparent background"),
])
S["menu"] = dict(nama="Latar Main Menu", suasana="senja, ikonik, animasi ringan", ref=None, layers=[
    ("bg", "Latar menu", "wide", 720, 270, 1, "an iconic Jakarta roundabout with the Selamat Datang monument at dusk, busy traffic light trails, tall buildings, warm sunset sky (alternative: Malioboro street in Yogyakarta at dusk with becak and street lamps)"),
    ("traffic", "Lampu kendaraan lewat (animasi)", "prop", 128, 24, 8, "streaks of car headlights and red tail lights passing by, looping"),
])

PARALLAX = """| Layer | Faktor geser | Lebar yang dibutuhkan | Cara buat |
| --- | --- | --- | --- |
| Skybox / dinding | 0,1x | sekitar 512 | 1 gambar 512 x 288 |
| Background | 0,5x | sekitar 720 | 2 bagian 512 x 288 lalu disambung |
| Midground lantai | 1,0x | 960 | tekstur 64 x 48 yang diulang + hiasan terpisah |
| Foreground | 1,2x | 1056 | potongan benda yang ditata di engine, sebagian tile |
"""


def write_stage(code, st):
    L = [f"# Stage: {st['nama']}\n", f"Suasana: {st['suasana']}.\n"]
    L.append("## Cara kerja\n")
    L.append("SpriteCook membatasi lebar gambar 512 piksel, padahal stage IndoFight 960 piksel. Karena itu setiap layer dibuat dengan cara berbeda:\n")
    L.append(PARALLAX)
    L.append("Urutan: buat Background bagian kiri dulu, ekstrak paletnya dengan `tools/extract_palette.py` menjadi `art/palettes/stage-" + code + ".hex`, lalu pakai palet itu (`colors`) dan gambar itu (`style_asset_ids`) untuk SEMUA layer lain di stage ini.\n")
    if st["ref"]:
        L.append(f"Referensi gaya sudah ada: `{st['ref']}`. Unggah dulu, lalu pakai sebagai `style_asset_ids`. Palet awal tersedia di `art/palettes/stage-dpr.hex`. Teks spanduk di referensi rusak, jadi tulis ulang manual di Aseprite.\n")
    L.append("Aturan: lantai karakter berpijak ada di baris piksel 238 dari 270. Jangan taruh benda terang atau ramai di area tengah setinggi karakter (baris 120 sampai 238), supaya petarung tetap terbaca.\n")
    for lc, ln, kind, w, h, fr, p in st["layers"]:
        L.append(f"## {ln} (`stage_{code}_{lc}`)\n")
        if kind == "wide":
            for half in ("left", "right"):
                prm = {"prompt": f"{p}. This is the {half} half of a wide panoramic stage background; " + ("the right edge must continue seamlessly. " if half == "left" else "continue seamlessly from the reference image's right edge. ") + STYLE + ".",
                       "width": 512, "height": 288, "aspect_ratio": "16:9", "pixel": True, "bg_mode": "include",
                       "smart_crop": False, "colors": ["<palet stage, isi setelah langkah ekstrak>"] if half == "right" else None,
                       "reference_asset_id": "<ASSET_ID_BAGIAN_KIRI>" if half == "right" else None,
                       "style_asset_ids": ["<ASSET_ID_REFERENSI_STAGE>"]}
                prm = {k: v for k, v in prm.items() if v is not None}
                L.append(f"Bagian {'kiri' if half == 'left' else 'kanan'}:\n")
                L.append("```json\n" + jd(prm) + "\n```\n")
            L.append(f"Sambung kedua bagian di Aseprite menjadi {w} x {h}, rapikan sambungan, dan pastikan bagian bawah transparan di bawah garis lantai.\n")
        else:
            prm = {"prompt": f"{p}. {STYLE}.", "width": w, "height": h, "pixel": True,
                   "bg_mode": "transparent" if kind == "prop" else "include",
                   "mode": "texture" if kind == "tile" else "assets", "smart_crop": kind == "prop",
                   "colors": ["<palet stage>"], "style_asset_ids": ["<ASSET_ID_BACKGROUND_STAGE_INI>"]}
            L.append("```json\n" + jd(prm) + "\n```\n")
            if fr > 1:
                L.append(f"Lalu `animate_game_art` dengan `output_frames: {fr}`, `output_format: \"spritesheet\"`, prompt berisi gerakan loop yang halus.\n")
            if kind == "tile":
                L.append("Cek dengan menaruh 3 salinan berdampingan di Aseprite. Sambungan tidak boleh terlihat.\n")
    L.append("## Checklist\n")
    for t in ["Palet stage dikunci dan dipakai di semua layer", "Background tersambung tanpa jahitan terlihat",
              "Lantai berulang tanpa jahitan", "Area tengah tidak lebih ramai daripada karakter",
              "Semua layer PNG transparan kecuali skybox/dinding", "Dicoba di engine dengan 2 karakter dan HUD"]:
        L.append(f"- [ ] {t}")
    with open(os.path.join(KIT, "art", "prompts", "stages", f"{code}.md"), "w") as f:
        f.write("\n".join(L) + "\n")


def stage_rows():
    rows = []
    for code, st in S.items():
        for lc, ln, kind, w, h, fr, p in st["layers"]:
            rows.append(dict(id=f"stage_{code}_{lc}", kategori="stage", pemilik=code, isi=ln, ukuran_asli=f"{w}x{h}",
                             frame=fr, loop="ya" if fr > 1 else "", alat="SpriteCook + Aseprite",
                             file=f"art/stages/{code}/indofight_stage_{code}_{lc}.png", spritecook_asset_id="",
                             status="todo", catatan=""))
    return rows


UI = [
    ("ui_kit_concept", "Konsep layar pertarungan lengkap (HUD)", "480x270", 1),
    ("ui_hp_frame", "Frame health bar (kiri, dicerminkan untuk kanan)", "200x16", 1),
    ("ui_hp_fill", "Isi health bar hijau, kuning, merah + lapisan hilang", "192x8", 3),
    ("ui_energy_frame", "Frame energy bar", "160x12", 1),
    ("ui_energy_fill", "Isi energy bar biru neon dan emas berkedip", "152x6", 4),
    ("ui_timer_frame", "Frame timer", "40x28", 1),
    ("ui_digits", "Angka digital 0-9", "10x16 per angka", 10),
    ("ui_round_dots", "Penanda ronde menyala dan mati", "8x8", 2),
    ("ui_text_fight", "Teks FIGHT!", "200x60", 6),
    ("ui_text_ko", "Teks K.O.", "200x60", 6),
    ("ui_text_perfect", "Teks PERFECT", "200x48", 6),
    ("ui_text_timeup", "Teks TIME UP", "200x48", 6),
    ("ui_text_round", "Teks ROUND 1, 2, 3", "160x40", 3),
    ("ui_text_combo", "Teks COMBO x", "96x24", 1),
    ("ui_btn_menu", "Tombol menu Normal, Hover, Pressed", "120x24", 3),
    ("ui_select_cursor", "Kursor P1 merah dan P2 biru", "68x68", 2),
    ("ui_select_frame", "Bingkai grid Character Select", "64x64", 1),
    ("ui_touch_joystick", "Joystick virtual (mobile)", "56x56", 2),
    ("ui_touch_buttons", "6 tombol aksi LP HP LK HK Skill Ultimate (mobile)", "24x24", 12),
    ("ui_logo", "Logo IndoFight besar dan kecil", "240x80", 2),
]
VFX = [
    ("vfx_hitspark_blunt", "Hit spark tumpul", 48, 48, 6, "a comic-style white and yellow impact starburst with short speed lines, for blunt hits"),
    ("vfx_hitspark_slash", "Hit spark tajam", 64, 32, 6, "a sharp white crescent slash streak with small sparks, for blade and broom hits"),
    ("vfx_blockspark", "Block spark", 48, 48, 6, "a blue hexagonal energy shield flash with orange sparks bouncing off"),
    ("vfx_impact_flash", "Impact flash", 64, 64, 4, "a big white round flash ring expanding and vanishing"),
    ("vfx_speedlines", "Speed lines", 128, 64, 4, "comic manga speed lines streaking horizontally, white on transparent"),
    ("vfx_dash_dust", "Dash dust", 48, 24, 6, "a small puff of grey-brown ground dust kicked up behind a foot"),
    ("vfx_land_dust", "Debu mendarat", 64, 24, 6, "a symmetrical ring of dust puffs when landing from a jump"),
    ("vfx_screen_crack", "Screen crack", 240, 135, 4, "white cracked-glass lines spreading from a central impact point, transparent background"),
    ("vfx_status_stun", "Ikon Stun", 24, 16, 6, "three small yellow stars circling, looping"),
    ("vfx_status_burn", "Ikon Burn", 16, 16, 6, "a small orange flame flickering, looping"),
    ("vfx_status_blind", "Ikon Blind", 16, 16, 4, "a small closed-eye symbol with red chili drips, looping"),
    ("vfx_status_slow", "Ikon Slow", 16, 16, 4, "a small purple snail symbol, looping"),
    ("vfx_status_buff", "Ikon Buff", 16, 16, 4, "a small orange upward arrow pulsing, looping"),
]
SFX = [
    ("sfx_hit_light", "Pukulan ringan", "a quick light punch impact, short punchy thwack, video game fighting sound", 0.5),
    ("sfx_hit_heavy", "Pukulan berat", "a heavy crunchy bone-shaking punch impact with low bass thump, arcade fighting game", 0.8),
    ("sfx_hit_blunt", "Benda tumpul", "a hard hit with a metal tray, clang with a dull thud", 0.8),
    ("sfx_hit_slash", "Benda tajam", "a fast blade swish followed by a sharp slice impact", 0.6),
    ("sfx_block", "Block", "a muffled guarded impact with a short shield ping", 0.5),
    ("sfx_whoosh", "Ayunan meleset", "a quick whoosh of a swing missing", 0.4),
    ("sfx_dash", "Dash", "a quick footstep scuff and air whoosh", 0.4),
    ("sfx_jump_land", "Mendarat", "a light thud of feet landing on the ground", 0.4),
    ("sfx_ko", "K.O.", "a dramatic slow-motion final hit boom with a ringing tail", 2.0),
    ("sfx_toa", "Teriakan Toa", "a person shouting through a distorted megaphone with feedback squeal", 1.5),
    ("sfx_milk_throw", "Kotak susu dilempar", "a small cardboard box spinning through the air with a quick whistle", 0.6),
    ("sfx_thunder", "Petir Gatot Kaca", "a sharp electric lightning crackle and thunder clap", 1.5),
    ("sfx_scooter", "Motor matic dan sein", "an automatic scooter revving and accelerating with a ticking turn signal", 2.0),
    ("sfx_soup", "Kuah disiram", "a splash of hot soup liquid with sizzling", 0.8),
    ("sfx_coffee", "Seruput kopi", "a loud satisfied sip of hot coffee followed by an aah", 1.2),
    ("sfx_notif", "Notifikasi ojol", "a cheerful smartphone notification chime", 0.6),
    ("sfx_teleport", "Cancel Order", "a quick digital glitch teleport zap", 0.5),
    ("sfx_santet", "Tusukan santet", "a creepy straw doll being pierced with a nail, eerie whisper", 1.5),
    ("sfx_jumpscare", "Jump Scare", "a sudden shrill horror sting scream", 1.2),
    ("sfx_keyboard", "Keyboard mekanikal", "rapid loud clicky mechanical keyboard typing", 1.0),
    ("sfx_glitch", "Disconnect", "a power cut thunk followed by digital glitch static", 1.5),
    ("sfx_ui_move", "Kursor pindah", "a short soft retro UI blip", 0.2),
    ("sfx_ui_select", "Pilih", "a satisfying retro UI confirm chime", 0.4),
    ("sfx_ui_back", "Batal", "a short low retro UI cancel blip", 0.3),
    ("sfx_timer_tick", "Hitung mundur", "a single digital timer tick beep", 0.2),
]


def write_ui_vfx():
    L = ["# UI, HUD, dan VFX\n"]
    L.append("UI dan HUD dibuat dengan skill `spritecook-build-ui-kits`, bukan `generate_game_art(mode=\"ui\")` satu per satu. Skill itu membuat satu konsep layar dulu, lalu memotong komponen dari konsep yang sama, sehingga semua tombol dan bar satu gaya.\n")
    L.append("## Konsep UI kit\n")
    L.append("Prompt konsep untuk `create_ui_kit`:\n")
    L.append("> A 16-bit pixel art fighting game HUD for a 480 x 270 screen, neon modern-grunge style inspired by Indonesian street culture: chunky metal-framed health bars at top left and top right with green fill, a digital 99 timer in the centre top, round-win dots beside the timer, neon blue energy bars at bottom left and bottom right, small square character portraits under each health bar. Spray-paint texture accents, rusty metal bolts, neon cyan and magenta glow, crisp hard pixels, no anti-aliasing.\n")
    L.append("Gunakan konsep yang sama untuk layar Character Select dan Main Menu supaya satu keluarga visual. Ikuti tata letak HUD di GDD bagian 5.3.\n")
    L.append("## Daftar komponen UI\n")
    L.append("| Kode | Isi | Ukuran asli | Variasi/frame |")
    L.append("| --- | --- | --- | --- |")
    for c, n, s, fr in UI:
        L.append(f"| `{c}` | {n} | {s} | {fr} |")
    L.append("\nFont: teks FIGHT!, K.O., dan nama karakter digambar sebagai sprite. Untuk font menu, pakai font pixel bebas lisensi (misalnya dari Lospec atau itch.io) dan catat lisensinya di `docs/credits.md`.\n")
    L.append("## Efek visual umum\n")
    L.append("Semua efek bergaya komik tanpa darah. Overlay hitam-putih atau merah saat ultimate, layar bergetar, dan hitstop dibuat di engine dengan shader dan kode, bukan sprite.\n")
    L.append("| Kode | Isi | Ukuran | Frame |")
    L.append("| --- | --- | --- | --- |")
    for c, n, w, h, fr, p in VFX:
        L.append(f"| `{c}` | {n} | {w} x {h} | {fr} |")
    L.append("")
    for c, n, w, h, fr, p in VFX:
        prm = {"prompt": f"{p}. 16-bit pixel art game VFX, crisp hard pixels, no anti-aliasing, transparent background.",
               "width": w, "height": h, "pixel": True, "bg_mode": "transparent"}
        L.append(f"### {c}\n\n```json\n{jd(prm)}\n```\n\nLalu `animate_game_art` dengan `output_frames: {fr}`, `output_format: \"spritesheet\"`.\n")
    with open(os.path.join(KIT, "art", "prompts", "ui-vfx.md"), "w") as f:
        f.write("\n".join(L) + "\n")


def write_audio():
    L = ["# Audio IndoFight\n"]
    L.append("## Efek suara (SFX)\n")
    L.append("Dibuat dengan skill ElevenLabs `sound-effects` (`npx skills add https://github.com/elevenlabs/skills --skill sound-effects`). Simpan sebagai WAV atau OGG di `audio/sfx/`. Buat 2 sampai 3 variasi untuk pukulan supaya tidak terdengar berulang.\n")
    L.append("| Kode | Isi | Durasi (detik) | Prompt |")
    L.append("| --- | --- | --- | --- |")
    for c, n, p, d in SFX:
        L.append(f"| `{c}` | {n} | {d} | {p} |")
    L.append("\n## Musik (brief untuk komposer)\n")
    L.append("Gaya: Gamelan Cyberpunk, yaitu gamelan Jawa atau Bali digabung EDM atau rock. Tempo 140 sampai 170 BPM untuk pertarungan. Setiap lagu harus bisa diputar berulang tanpa jeda terasa.\n")
    L.append("| Lagu | Suasana |")
    L.append("| --- | --- |")
    for a, b in [("Main Menu", "megah, mengundang, gong dan synth"), ("Character Select", "tegang, berulang pendek"),
                 ("Depan Gedung DPR", "rock keras, drum demo"), ("Lobi Istana / Kemenhan", "marching band elektronik, megah"),
                 ("Candi Prambanan Malam", "gamelan mistis, sub bass gelap"), ("Gang Sempit", "dangdut koplo elektronik"),
                 ("Proyek Mangkrak", "industrial, suara besi dipukul"), ("Warnet Berkah", "chiptune cepat")]:
        L.append(f"| {a} | {b} |")
    L.append("\nMusik sebaiknya dibuat komposer atau memakai musik berlisensi, karena musik adalah identitas utama game ini. Catat semua lisensi di `docs/credits.md`.\n")
    with open(os.path.join(KIT, "audio", "audio-list.md"), "w") as f:
        f.write("\n".join(L) + "\n")


def other_rows():
    rows = []
    for c, n, s, fr in UI:
        rows.append(dict(id=c, kategori="ui", pemilik="", isi=n, ukuran_asli=s, frame=fr, loop="", alat="SpriteCook UI kit + Aseprite",
                         file=f"art/ui/indofight_{c}.png", spritecook_asset_id="", status="todo", catatan=""))
    for c, n, w, h, fr, p in VFX:
        rows.append(dict(id=c, kategori="vfx", pemilik="", isi=n, ukuran_asli=f"{w}x{h}", frame=fr, loop="", alat="SpriteCook",
                         file=f"art/vfx/indofight_{c}_sheet.png", spritecook_asset_id="", status="todo", catatan=""))
    for c, n, p, d in SFX:
        rows.append(dict(id=c, kategori="sfx", pemilik="", isi=n, ukuran_asli=f"{d}s", frame="", loop="", alat="ElevenLabs",
                         file=f"audio/sfx/indofight_{c}.wav", spritecook_asset_id="", status="todo", catatan=""))
    return rows


if __name__ == "__main__":
    for code, st in S.items():
        write_stage(code, st)
    write_ui_vfx()
    write_audio()
    with open(os.path.join(KIT, "production", "_other_rows.json"), "w") as f:
        json.dump(stage_rows() + other_rows(), f, ensure_ascii=False)
    print("stages", len(S))
