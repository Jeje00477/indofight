"""Generate IndoFight per-character prompt sheets and the asset manifest.
Usage: python3 -I gen_characters.py <kit_dir>
"""
import sys, os, json, csv

KIT = sys.argv[1]
PAL_DIR = os.path.join(KIT, "art", "palettes")

STYLE = ("16-bit pixel art fighting game sprite in the style of 1990s SNK and Metal Slug arcade games, "
         "semi-realistic proportions about 6 heads tall (not chibi), 1px dark outline using the darkest palette "
         "colour (not pure black), 2 to 3 shade steps per colour, light from the top-left, crisp hard pixels, "
         "no anti-aliasing, no text, no brand logos")
VIEW = "side view, facing right, full body, standing on an invisible flat floor line, transparent background"
NEG = ("chibi, big head, anime eyes, blurry, anti-aliased edges, soft gradients, painterly, 3D render, photo, "
       "text, watermark, logo, extra limbs, extra weapons, cropped feet, front view, back view")

# Frame counts follow GDD 8.2, adjusted to even numbers because SpriteCook pixel animation needs 2-16 even frames.
ANIMS = [
    # key, nama, frames, loop, generic motion (EN), uses per-char move key
    ("idle", "Idle", 6, True, "breathes in a steady fighting stance, chest and shoulders rising and falling slightly, feet planted, held props bobbing gently", None),
    ("walk_forward", "Walk Forward", 8, True, "walks forward to the right in fighting stance with guarded steps, upper body staying upright and alert", "walk"),
    # Walk Backward tidak digenerate: engine memutar Walk Forward terbalik (docs/decisions.md no. 4).
    ("dash", "Dash / Step", 4, False, "makes one quick low burst step forward, body leaning in, then settles back into stance", None),
    ("jump", "Jump", 6, False, "crouches, springs straight up with knees tucked at the peak, then lands back in stance", "jump"),
    ("crouch", "Crouch", 2, False, "drops into a low crouched guard and holds it", None),
    ("light_punch", "Light Punch", 4, False, None, "lp"),
    ("heavy_punch", "Heavy Punch", 6, False, None, "hp"),
    ("light_kick", "Light Kick", 4, False, None, "lk"),
    ("heavy_kick", "Heavy Kick", 6, False, None, "hk"),
    ("block", "Block", 2, False, "raises arms and props into a tight defensive block, bracing against impact", "block"),
    ("hit", "Hit", 4, False, "is struck in the face, head snaps back and body recoils, then recovers to stance", None),
    ("knockup", "Knockup", 4, False, "is launched into the air by an uppercut, body arching backward, limbs flailing", None),
    ("knockdown", "Knockdown", 6, False, "falls backward flat onto the floor, bounces once, then pushes up and stands again", None),
    ("special", "Special Skill", 8, False, None, "skill"),
    ("ultimate_cast", "Ultimate Cast", 10, False, None, "ult"),
    ("defeat", "Defeat", 6, False, None, "defeat"),
    ("victory", "Victory", 8, True, None, "victory"),
    ("taunt", "Taunt", 6, True, None, "taunt"),
]

C = {}

C["mahasiswa"] = dict(
    nama="Mahasiswa", julukan="The Protester", tinggi=104,
    desc="a young Indonesian male university student with short spiky black hair, a red-and-white headband, an open royal-blue university almamater jacket over a white t-shirt, dark grey trousers, white sneakers and a small backpack; he holds a white megaphone in his left hand and a short wooden banner pole in his right hand",
    kunci=["Jaket almamater biru terbuka, kaos putih di dalam", "Ikat kepala merah putih selalu terlihat", "Toa putih di tangan kiri, tongkat kayu di tangan kanan", "Molotov hanya milik karakter ini dan hanya muncul di ultimate"],
    fix=[],
    moves=dict(
        walk="walks with a confident marching rhythm, megaphone held at chest height",
        jump="jumps with the banner pole raised",
        lp="jabs forward quickly with the butt end of the wooden banner pole, then pulls it back",
        hp="swings the wooden banner pole in a big overhead arc down onto the opponent",
        lk="snaps a quick front kick at knee height",
        hk="twists his whole body and swings his backpack around by the strap in a heavy horizontal arc",
        block="holds the banner pole horizontally across his body with both hands",
        skill="raises the megaphone to his mouth, leans forward and shouts with his whole body, shoulders tensing; the megaphone shakes from the force (sound waves are a separate VFX sprite)",
        ult="pumps his fist into the air and shouts toward the sky as if calling a crowd, then winds up and throws a bottle overhand",
        defeat="drops to his knees, the megaphone slipping from his hand, then slumps forward",
        victory="raises the megaphone and his fist high and cheers",
        taunt="waves a small red-and-white flag on the banner pole from side to side",
    ),
    props=[
        ("toa_soundwave", "Gelombang suara Sonic Toa (VFX)", 64, 48, 8, "three expanding curved sound-wave arcs in pale cyan and white bursting to the right from a megaphone mouth, comic style"),
        ("burning_tire", "Ban bekas terbakar (proyektil ultimate)", 32, 32, 6, "an old black rubber car tire on fire with orange and yellow pixel flames, spinning as it falls"),
        ("molotov", "Molotov (proyektil ultimate)", 16, 24, 4, "a glass bottle with a burning cloth wick, tumbling end over end"),
        ("burn_fire", "Api Burn di tanah", 48, 32, 6, "small ground fire with flickering orange and yellow flames, looping"),
    ],
)

C["jenderal-gemoy"] = dict(
    nama="Jenderal Gemoy", julukan="The General", tinggi=106,
    desc="a charismatic middle-aged Indonesian man drawn as a friendly caricature, upright military posture but slightly chubby, short neat grey hair, black sunglasses, a brown safari shirt with chest pockets and matching brown trousers, black shoes; he holds a rectangular stainless-steel school-lunch tray in front of him like a shield",
    kunci=["Kemeja safari cokelat lengkap dengan saku dada", "Kacamata hitam selalu dipakai", "Nampan stainless di tangan, dipakai sebagai perisai", "Tetap karikatur, bukan potret realistis tokoh nyata"],
    fix=["Di referensi frame pertama memegang molotov. Jangan pernah pakai frame itu sebagai referensi."],
    moves=dict(
        walk="marches forward with a steady military gait, tray held at his side",
        jump="jumps with the tray held flat above his head",
        lp="throws a short, tight military jab from behind the tray",
        hp="bashes forward with the flat face of the steel tray using his whole body weight",
        lk="snaps a low close-quarters kick at the shin",
        hk="drives forward with a heavy shoulder charge behind the tray",
        block="plants his feet and holds the steel tray up in front of his chest like a riot shield",
        skill="pulls a small milk carton from his pocket and flicks it forward side-arm with precise force like throwing a shuriken",
        ult="points forward commandingly with an outstretched arm, then looks up to the sky",
        defeat="staggers, sunglasses tilting, and sits down heavily on the floor",
        victory="stands at attention and gives a crisp formal salute",
        taunt="adjusts his sunglasses with one finger and smiles",
    ),
    props=[
        ("milk_carton", "Kotak susu (proyektil Susu Lempar)", 16, 16, 4, "a small white and blue milk carton spinning fast like a shuriken"),
        ("mbg_tray", "Nampan MBG jatuh (proyektil ultimate)", 32, 24, 4, "a rectangular stainless steel compartment lunch tray tumbling as it falls"),
        ("ration_crate", "Kotak ransum berparasut", 32, 48, 6, "a brown cardboard ration box hanging from a small white parachute, swaying as it descends"),
        ("heli_shadow", "Bayangan helikopter", 128, 48, 4, "a dark semi-transparent silhouette shadow of a military helicopter seen from the side, rotor blur"),
    ],
)

C["gatot-kaca"] = dict(
    nama="Gatot Kaca", julukan="The Legend", tinggi=112,
    desc="a muscular heroic knight inspired by Javanese wayang, bronze-skinned, wearing an ornate bronze chest armour (Brajamusti) with gold trim, a wayang-style golden crown headpiece, a dark red and black warrior waist cloth, bronze arm bands, and large black feathered magical wings folded on his back; faint pale-blue lightning crackles around his fists",
    kunci=["Zirah dada perunggu berhias emas", "Mahkota wayang emas", "Sayap hitam besar, dibuat sebagai sprite terpisah supaya bisa mengepak", "Petir warna biru muda di kepalan"],
    fix=["Referensi hanya punya pose terbang. Gambar dasar wajib pose berdiri di tanah."],
    moves=dict(
        walk="strides forward heavily, wings half folded, lightning flickering at the fists",
        jump="leaps with a strong wing beat",
        lp="throws a fast straight jab wrapped in pale-blue lightning",
        hp="winds back and delivers a crushing straight punch, lightning bursting from the fist",
        lk="drives a sharp rising knee strike",
        hk="spins into a heavy roundhouse kick leaving a lightning trail",
        block="crosses both armoured forearms in front of his face and half wraps his wings forward",
        skill="lowers his head, spreads his wings and launches forward horizontally like a rocket with one fist extended",
        ult="crouches deep, wings spread wide, then explodes upward and flies off the top of the frame",
        defeat="falls to one knee, wings drooping, lightning fading out",
        victory="hovers just above the ground with wings spread wide and arms crossed",
        taunt="flexes one arm as lightning crackles over the muscle",
    ),
    props=[
        ("wings", "Sayap terpisah (layer animasi)", 96, 80, 8, "a pair of large black feathered magical wings seen from the side, flapping loop"),
        ("fist_lightning", "Aura petir kepalan (VFX)", 32, 32, 6, "a crackling ball of pale-blue electric lightning sparks, looping"),
        ("meteor_dive", "Efek meteor menukik", 64, 96, 6, "a figure-shaped blazing meteor trail of blue-white energy diving diagonally downward"),
        ("screen_blast", "Ledakan seluas layar", 256, 128, 8, "a huge ground-level explosion shockwave of blue lightning and dust expanding sideways"),
    ],
)

C["emak-emak"] = dict(
    nama="Emak-Emak", julukan="The Street Boss", tinggi=100,
    desc="a plump, fierce Indonesian middle-aged housewife wearing a loose pink floral-print daster house dress, an oversized grey half-face motorcycle helmet, black sunglasses and flip-flop sandals; she grips a very long giant broom made of bundled palm-leaf ribs (sapu lidi) with both hands",
    props_palette="props-emak",
    kunci=["Daster pink motif bunga (dikunci)", "Helm half-face abu-abu kebesaran (dikunci)", "Kacamata hitam", "Sapu lidi sangat panjang, jangkauan serangan terlihat jauh"],
    fix=["Referensi berganti helm abu-abu/pink dan daster pink/hijau. Sudah dikunci: helm abu-abu dan daster pink (docs/decisions.md no. 1). Abaikan frame referensi yang berhelm pink atau berdaster hijau."],
    moves=dict(
        walk="waddles forward confidently, broom held across her body",
        jump="hops up holding the broom high",
        lp="pokes the tip of the long broom forward quickly",
        hp="sweeps the long broom in a very wide horizontal arc",
        lk="kicks forward with a flip-flop sandal",
        hk="lifts the broom high and smashes it straight down",
        block="holds the broom handle vertically in front of her and leans back",
        skill="winds up and flings a red plastic food container side-arm so it spins away like a boomerang, then holds her hand out to catch it",
        ult="whistles, points behind herself, then steps sideways as if climbing onto a scooter",
        defeat="sits down hard on the floor, helmet tilted over her sunglasses",
        victory="plants the broom like a flag and puts her other hand on her hip",
        taunt="wags her finger and nods her helmet scoldingly",
    ),
    props=[
        ("tupperware", "Tupperware berputar (proyektil)", 24, 16, 6, "a red plastic food storage container with a lid spinning flat like a frisbee"),
        ("scooter", "Motor matic (aset ultimate)", 96, 64, 4, "a red automatic scooter seen from the side with the right turn signal blinking orange, wheels spinning"),
        ("sein_blink", "Lampu sein berkedip (VFX)", 16, 16, 2, "a small orange indicator light blinking on and off"),
    ],
)

C["intel-bakso"] = dict(
    nama="Intel Bakso", julukan="The Agent", tinggi=104,
    desc="an Indonesian man in his thirties wearing a grey knit beanie, a faded red plaid flannel shirt, blue jeans and dark shoes, with a thin earpiece wire coming from one ear; he holds a white ceramic bakso bowl with a rooster pattern in his left hand and a black walkie-talkie in his right hand",
    kunci=["Kupluk abu-abu", "Flanel merah kotak-kotak", "Mangkok bakso ayam jago di tangan kiri", "Kacamata hitam hanya dipakai saat ultimate"],
    fix=[],
    moves=dict(
        walk="walks casually, eyes scanning, bowl held steady",
        jump="jumps while keeping the bowl level",
        lp="flicks hot soup from the bowl forward in a short splash",
        hp="swings the heavy ceramic bowl like a club",
        lk="snaps a quick low kick",
        hk="spins into a back kick",
        block="turns his shoulder and shields himself with the bowl",
        skill="tilts the bowl and sprays a burst of bright red chili soup forward in an arc",
        ult="lifts the walkie-talkie to his mouth and speaks, then slides on black sunglasses",
        defeat="falls backward, the bowl landing upside down on his chest",
        victory="calmly lifts a meatball on a spoon and eats it",
        taunt="taps his earpiece and nods knowingly",
    ),
    props=[
        ("soup_splash", "Cipratan kuah panas (VFX)", 48, 32, 6, "a short splash of hot yellow-brown soup droplets with steam"),
        ("chili_spray", "Semburan kuah sambal (proyektil)", 64, 32, 6, "a burst of bright red chili soup spraying forward in an arc"),
        ("sniper_laser", "Laser sniper merah", 128, 8, 2, "a thin glowing red laser line with a small red dot at the end"),
        ("muzzle_flash", "Kilatan tembakan dari luar layar", 32, 32, 4, "a bright muzzle flash and a small bullet impact spark"),
    ],
)

C["kuli-jawa"] = dict(
    nama="Kuli Jawa", julukan="The Builder", tinggi=108,
    desc="a wiry, muscular Javanese construction worker with dark tan skin, a conical bamboo hat (caping), a grey t-shirt rolled up to the shoulders, a small white towel around his neck, navy track pants with white side stripes and rubber sandals; he holds a mason's trowel (cetok) in one hand and a glass of black coffee in the other",
    kunci=["Caping bambu", "Kaos abu-abu digulung ke bahu", "Handuk kecil di leher (wajib ditambahkan)", "Celana training biru dongker bergaris putih"],
    fix=["Handuk leher belum ada di referensi. Tambahkan di gambar dasar."],
    moves=dict(
        walk="walks with a relaxed working-man swagger",
        jump="jumps with the trowel raised",
        lp="snaps the neck towel forward like a whip",
        hp="swings the heavy steel trowel in a downward chop",
        lk="kicks low at the shin",
        hk="stomps forward with a heavy push kick",
        block="raises the trowel flat in front of his face with his forearm braced",
        skill="takes a long sip of black coffee, steam rising, then exhales and flexes as his body tenses with energy",
        ult="moves his hands in a rapid blur as if laying bricks, then lifts one leg for a kick",
        defeat="sits down tiredly and fans himself with the caping",
        victory="leans on the trowel and sips coffee with a satisfied grin",
        taunt="tips the caping and taps the trowel on his palm",
    ),
    props=[
        ("coffee_steam", "Uap kopi (VFX)", 16, 24, 6, "thin wisps of white steam rising and curling, looping"),
        ("buff_aura", "Aura buff (VFX)", 48, 64, 6, "a flickering orange-red heat aura around a body outline, looping"),
        ("brick_wall", "Tembok bata (aset ultimate)", 64, 96, 6, "a red brick wall being built up row by row, then toppling forward and breaking apart"),
        ("dust_cloud", "Debu roboh", 64, 32, 6, "a puff of grey construction dust expanding and fading"),
    ],
)

C["abang-ojol"] = dict(
    nama="Abang Ojol", julukan="The Speedster", tinggi=104,
    desc="a lean young Indonesian motorcycle taxi driver wearing a bright green riding jacket with glowing reflective stripes, a matching green full-face helmet with a clear visor, black trousers and sneakers, with a smartphone mounted on his chest showing a map; he carries a spare green helmet in one hand",
    kunci=["Hijau jaket dan helm sama persis", "Garis reflektif menyala", "Smartphone di dada dengan peta (wajib ditambahkan)", "Tanpa logo atau nama aplikasi ojek nyata"],
    fix=["Smartphone di dada belum ada di referensi. Tambahkan di gambar dasar."],
    moves=dict(
        walk="bounces lightly on his toes like a taekwondo fighter",
        jump="springs up lightly with knees tucked",
        lp="throws a very fast straight jab",
        hp="swings the spare helmet in a hooking arc",
        lk="fires a quick taekwondo roundhouse kick",
        hk="spins into a high spinning hook kick",
        block="raises the spare helmet in front of his face",
        skill="blinks forward in a short teleport, leaving a glitchy green digital afterimage of himself behind",
        ult="revs an imaginary throttle and hops sideways as if mounting a motorbike",
        defeat="falls back, phone screen on his chest cracking",
        victory="checks the phone on his chest and gives a thumbs up",
        taunt="taps the phone on his chest and shakes his head impatiently",
    ),
    props=[
        ("afterimage", "Bayangan digital Cancel Order (VFX)", 64, 112, 6, "a glitchy translucent green pixel afterimage silhouette breaking into scanlines and fading"),
        ("motor_bebek", "Motor bebek (aset ultimate)", 96, 64, 4, "a small yellow and black underbone moped motorcycle seen from the side, wheels spinning"),
        ("star5_notif", "Notifikasi Bintang 5", 64, 24, 6, "a small phone notification popup with five yellow stars dropping down and bouncing"),
    ],
)

C["dukun-santet"] = dict(
    nama="Dukun Santet", julukan="The Zoner", tinggi=104,
    desc="an old, gaunt, mysterious Javanese shaman with long grey hair, wearing pitch-black traditional clothing, a black sarong and a dark batik blangkon head cloth; he holds a straw voodoo doll in one hand and a wavy kris dagger in the other, with thin wisps of incense smoke drifting around him",
    kunci=["Blangkon wajib ada", "Pakaian hitam legam dan sarung hitam", "Boneka jerami dan keris berlekuk", "Wajah warna normal di pose biasa, ungu hanya saat merapal jurus"],
    fix=["Blangkon tidak terlihat di referensi dan wajah ungu di satu frame. Perbaiki di gambar dasar."],
    moves=dict(
        walk="glides forward slowly, robes swaying, smoke trailing",
        jump="floats upward unnaturally slowly",
        lp="slashes the kris in a short arc",
        hp="thrusts the kris forward with both hands",
        lk="sweeps a low kick under the sarong",
        hk="pushes an open palm forward releasing a small purple flame",
        block="raises the straw doll in front of him as a ward",
        skill="sweeps his arm wide and releases a rolling cloud of grey incense smoke",
        ult="holds up the straw doll and drives a black nail into it, face turning purple with dark energy",
        defeat="collapses into a heap of black cloth as the doll falls",
        victory="laughs silently, the doll held up, purple smoke swirling",
        taunt="whispers to the straw doll and strokes its head",
    ),
    props=[
        ("purple_orb", "Bola energi ungu (proyektil basic)", 24, 24, 6, "a glowing purple and magenta energy orb with a short trailing flame"),
        ("incense_cloud", "Awan asap kemenyan", 96, 48, 8, "a slow rolling cloud of grey-violet incense smoke, looping"),
        ("black_nail", "Paku hitam (proyektil ultimate)", 16, 8, 2, "a sharp black iron nail flying forward"),
        ("red_flash", "Layar berkedip merah", 32, 32, 2, "a flat red full-screen flash tile, solid then transparent"),
    ],
)

C["pocong-brawler"] = dict(
    nama="Pocong Brawler", julukan="The Undead", tinggi=104,
    desc="a modern Indonesian pocong ghost fighter, its whole body wrapped in a slightly dirty off-white burial shroud tied at the top of the head and at the feet, the shroud cords wrapped tightly around both fists like Muay Thai hand wraps, its face hidden in deep shadow with two glowing eyes; it moves by hopping because its feet are bound",
    kunci=["Kain kafan kusam, diikat di kepala dan kaki", "Tali kafan dililit di kepalan seperti hand-wrap Muay Thai", "Wajah gelap dengan dua mata menyala (wajib)", "Semua gerakan berpindah tempat dengan melompat"],
    fix=["Mata di referensi masih hitam. Ganti dengan mata menyala."],
    moves=dict(
        walk="hops forward in short bouncing hops with fists up",
        jump="springs high with both bound feet together",
        lp="throws a wrapped-fist jab",
        hp="lunges forward with a hard headbutt",
        lk="hops and kicks forward with both bound feet together",
        hk="whips a loose shroud cord forward in a long lash",
        block="hunches and raises both wrapped fists in a Muay Thai guard",
        skill="hops high and dives head-first into the ground, disappearing",
        ult="leans its shadowed face sharply toward the viewer, eyes flaring bright",
        defeat="topples stiffly backward like a falling log",
        victory="bounces in place, fists raised",
        taunt="tilts its head slowly with glowing eyes blinking",
    ),
    props=[
        ("ground_hole", "Lubang tanah Earth Dive", 48, 16, 6, "a dark hole opening in dirt ground with debris flying up"),
        ("jumpscare_face", "Wajah pocong layar penuh (ultimate)", 240, 135, 4, "an extreme close-up of a pocong ghost face in shadow wrapped in a dirty shroud, two huge glowing eyes, horror comic style, filling the frame"),
        ("lifesteal", "Efek HP terserap", 48, 48, 6, "small red glowing orbs streaming in an arc, looping"),
    ],
)

C["bocah-warnet"] = dict(
    nama="Bocah Warnet", julukan="The Annoyance", tinggi=96,
    desc="a skinny Indonesian junior-high schoolboy with messy black hair and dark eye bags from lack of sleep, wearing an untucked white short-sleeve school shirt with a loose red tie, navy blue school shorts, sneakers and a backpack; he holds a rainbow RGB mechanical keyboard with a broken cable dangling from it",
    kunci=["Seragam SMP putih-biru berantakan", "Kantung mata hitam", "Keyboard RGB pelangi dengan kabel putus menjuntai", "Paling pendek di roster"],
    fix=[],
    moves=dict(
        walk="shuffles forward slouching, keyboard dragging at his side",
        jump="hops up clumsily holding the keyboard over his head",
        lp="jabs forward with the edge of the keyboard",
        hp="smashes the keyboard down with both hands",
        lk="throws a gaming mouse forward on its cable like a yo-yo and reels it back",
        hk="kicks forward with a sneaker",
        block="hugs the keyboard flat in front of his chest",
        skill="leans forward and yells angrily with his mouth wide open (the swear speech bubble is a separate projectile sprite)",
        ult="mimes yanking an invisible power cable out of the floor with both hands",
        defeat="falls asleep sitting on the floor, keyboard on his lap",
        victory="raises the glowing keyboard over his head triumphantly",
        taunt="types furiously on the keyboard while smirking",
    ),
    props=[
        ("mouse_yoyo", "Mouse gaming bertali", 16, 16, 4, "a black gaming mouse with a glowing RGB stripe spinning on a cable"),
        ("toxic_bubble", "Balon teks @#$%! (proyektil homing)", 32, 24, 6, "a red comic speech bubble containing scribbled censor symbols, wobbling as it flies"),
        ("glitch_overlay", "Layar gelap glitch (ultimate)", 240, 135, 6, "a dark screen with colourful digital glitch bars and scanlines flickering"),
        ("ggwp_text", "Teks GGWP", 64, 24, 4, "the letters GGWP in a bold glowing RGB pixel font popping in"),
    ],
)

ORDER = list(C.keys())


import re
def jd(o):
    t = json.dumps(o, indent=2, ensure_ascii=False)
    return re.sub(r'\[\s*\n((?:\s*"[^"\n]*",?\s*\n)+)\s*\]', lambda m: "[" + ", ".join(x.strip().rstrip(",") for x in m.group(1).strip().splitlines()) + "]", t)


def palette(name):
    with open(os.path.join(PAL_DIR, f"{name}.hex")) as f:
        return ["#" + l.strip() for l in f if l.strip()]


def anim_prompt(ch, a):
    key, nama, frames, loop, generic, mkey = a
    who = f"The {ch['nama']} character"
    if generic and mkey and mkey in ch["moves"]:
        body = f"{who} {ch['moves'][mkey]}."
    elif generic:
        body = f"{who} {generic}."
    else:
        body = f"{who} {ch['moves'][mkey]}."
    body += " Keep the exact same design, colours, outfit and props as the source sprite. Side view facing right. Feet stay on the same floor line."
    if loop:
        body += " The motion loops seamlessly."
    else:
        body += " The motion starts and ends in the fighting stance."
    return body


def write_char(name, ch):
    pal = palette(name)
    out = os.path.join(KIT, "art", "prompts", "characters", f"{name}.md")
    base_prompt = f"{ch['desc']}. Neutral fighting stance. {VIEW}. {STYLE}."
    base_params = {
        "prompt": base_prompt,
        "width": 160, "height": 160, "pixel": True, "bg_mode": "transparent",
        "style": "16-bit SNK / Metal Slug arcade pixel art",
        "theme": "Indonesian street satire fighting game",
        "colors": pal, "smart_crop": False, "variations": 4,
        "style_asset_ids": ["<ASSET_ID_REFERENSI_KARAKTER>"],
    }
    splash_params = {
        "prompt": f"Full-body character select splash art of {ch['desc']}. Heroic three-quarter pose, slight low camera angle, dramatic rim light. {STYLE}. Transparent background.",
        "width": 270, "height": 480, "aspect_ratio": "9:16", "pixel": True, "bg_mode": "transparent",
        "colors": pal, "reference_asset_id": "<ASSET_ID_GAMBAR_DASAR>",
    }
    icon_params = {
        "prompt": f"Head and shoulders portrait mugshot of the same character, facing three-quarter right, strong expression, {STYLE}.",
        "width": 64, "height": 64, "pixel": True, "bg_mode": "include",
        "colors": pal, "reference_asset_id": "<ASSET_ID_GAMBAR_DASAR>",
    }
    L = []
    L.append(f"# {ch['nama']} ({ch['julukan']}): Lembar Prompt Produksi\n")
    L.append("Lembar ini dipakai bersama SpriteCook. Ikuti urutan bagian 1 sampai 6. Jangan lompat ke animasi sebelum gambar dasar disetujui.\n")
    L.append("## 0. Ringkasan\n")
    L.append(f"- Palet terkunci: `art/palettes/{name}.hex` ({len(pal)} warna)")
    L.append(f"- Tinggi karakter berdiri: sekitar {ch['tinggi']} piksel di kanvas 160 x 160, kaki di baris piksel 150")
    L.append("- Arah hadap: kanan. Arah kiri dibuat engine dengan flip, jangan digambar terpisah")
    L.append("- Kunci visual (wajib sama di semua frame):")
    for k in ch["kunci"]:
        L.append(f"    - {k}")
    if ch["fix"]:
        L.append("- Perbaikan dari gambar referensi:")
        for k in ch["fix"]:
            L.append(f"    - {k}")
    L.append("")
    L.append("## 1. Gambar dasar (canonical)\n")
    L.append(f"Langkah awal: unggah `art/reference/characters/{name}.png` lewat skill `spritecook-upload-assets`, simpan asset_id-nya dengan label `{name}_ref`, lalu isi `<ASSET_ID_REFERENSI_KARAKTER>` di bawah. Referensi ini hanya acuan gaya, bukan desain final: kunci visual di bagian 0 yang menang bila berbeda.\n")
    L.append("Semua animasi dibuat dari SATU gambar ini. Generate 4 variasi, pilih 1, rapikan di Aseprite, unggah ulang, lalu simpan `asset_id`-nya di `production/spritecook-assets.json` dengan label `" + name + "_base`.\n")
    L.append("Alat: `generate_game_art`\n")
    L.append("```json\n" + jd(base_params) + "\n```\n")
    L.append(f"Negative/hindari: {NEG}\n")
    L.append("Lolos jika: siluet terbaca dari jauh, semua kunci visual ada, kaki rata di lantai, warna 100% dari palet (cek dengan `python3 tools/validate_sprite.py`).\n")
    L.append("## 2. Splash art (Character Select dan layar Versus)\n")
    L.append("Alat: `generate_game_art`, lalu perbesar 4x dengan `tools/upscale.py` menjadi 1080 x 1920.\n")
    L.append("```json\n" + jd(splash_params) + "\n```\n")
    L.append("## 3. Ikon grid 64 x 64 dan ikon HUD 32 x 32\n")
    L.append("Ikon HUD dibuat dengan memperkecil manual ikon grid di Aseprite, bukan generate ulang.\n")
    L.append("```json\n" + jd(icon_params) + "\n```\n")
    L.append(f"## 4. Animasi ({len(ANIMS)} gerakan)\n")
    L.append("Walk Backward tidak dibuat sebagai job terpisah: engine memutar sheet Walk Forward secara terbalik (lihat `docs/decisions.md`).\n")
    L.append("Alat: `animate_game_art` dengan `asset_id` gambar dasar yang SAMA untuk setiap gerakan. Parameter tetap: `pixel: true`, `colors: 24`, `edge_margin: 6`, `output_format: \"spritesheet\"`, `auto_enhance_prompt: false`.\n")
    L.append("Jumlah frame dibulatkan ke genap karena SpriteCook hanya menerima 2 sampai 16 frame genap (Hit jadi 4, Knockdown jadi 6).\n")
    L.append("| No | Animasi | File | Frame | Loop |")
    L.append("| --- | --- | --- | --- | --- |")
    for i, a in enumerate(ANIMS, 1):
        L.append(f"| {i} | {a[1]} | `indofight_char_{name}_{a[0]}_sheet.png` | {a[2]} | {'ya' if a[3] else 'tidak'} |")
    L.append("")
    for i, a in enumerate(ANIMS, 1):
        params = {"asset_id": "<ASSET_ID_GAMBAR_DASAR>", "prompt": anim_prompt(ch, a), "output_frames": a[2],
                  "pixel": True, "colors": 24, "edge_margin": 6, "output_format": "spritesheet",
                  "auto_enhance_prompt": False,
                  "negative_prompt": "changing outfit, changing colours, new weapons, camera movement, character turning to face the viewer, sliding feet"}
        L.append(f"### 4.{i} {a[1]}\n")
        L.append("```json\n" + jd(params) + "\n```\n")
    L.append("Catatan: animasi Ultimate Cast hanya pose karakter. Efek besar ultimate (proyektil, kendaraan, layar penuh) ada di bagian 5 dan digabung di engine.\n")
    L.append("## 5. Properti, proyektil, dan efek khusus\n")
    L.append("Alat: `generate_game_art` untuk gambar diam, lalu `animate_game_art` bila kolom frame lebih dari 1. Pakai `style_asset_ids` berisi gambar dasar karakter ini supaya gayanya sama.\n")
    L.append("| Kode | Isi | Ukuran | Frame |")
    L.append("| --- | --- | --- | --- |")
    for code, isi, w, h, fr, _ in ch["props"]:
        L.append(f"| `{name}_{code}` | {isi} | {w} x {h} | {fr} |")
    L.append("")
    ppal_name = ch.get("props_palette", name)
    ppal = palette(ppal_name)
    if ppal_name != name:
        L.append(f"Palet properti: `art/palettes/{ppal_name}.hex` ({len(ppal)} warna), terpisah dari palet karakter. Validasi properti dengan `python3 tools/validate_sprite.py <file> --palette art/palettes/{ppal_name}.hex`.\n")
    for code, isi, w, h, fr, p in ch["props"]:
        params = {"prompt": f"{p}. {STYLE}. Transparent background.", "width": w, "height": h, "pixel": True,
                  "bg_mode": "transparent", "colors": ppal, "style_asset_ids": ["<ASSET_ID_GAMBAR_DASAR>"]}
        L.append(f"### {name}_{code}\n")
        L.append("```json\n" + jd(params) + "\n```\n")
        if fr > 1:
            L.append(f"Lalu `animate_game_art` dengan `output_frames: {fr}`.\n")
    L.append("## 6. Checklist sebelum karakter dianggap selesai\n")
    for t in ["Gambar dasar disetujui dan asset_id tersimpan di manifest",
              f"{len(ANIMS)} sprite sheet lolos `tools/validate_sprite.py` (palet, transparansi, garis kaki)",
              "Pivot di tengah telapak kaki sama di semua frame",
              "Splash 1080 x 1920 dan ikon 256 x 256 sudah diekspor 4x",
              "Semua properti dan efek di bagian 5 sudah dibuat",
              "Sudah dicoba di engine bersama HUD dan stage",
              "Baris karakter ini di `production/asset_manifest.csv` sudah berstatus done"]:
        L.append(f"- [ ] {t}")
    L.append("")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w") as f:
        f.write("\n".join(L))


def manifest_rows():
    rows = []
    def add(cat, owner, code, desc, size, frames, loop, tool, path):
        rows.append(dict(id=f"{owner}_{code}" if owner else code, kategori=cat, pemilik=owner, isi=desc,
                         ukuran_asli=size, frame=frames, loop=loop, alat=tool, file=path, spritecook_asset_id="",
                         status="todo", catatan=""))
    for name in ORDER:
        ch = C[name]
        base = f"art/characters/{name}/"
        add("karakter", name, "base", "Gambar dasar canonical", "160x160", 1, "", "SpriteCook generate_game_art + Aseprite", base + f"indofight_char_{name}_base.png")
        add("karakter", name, "splash", "Splash art", "270x480", 1, "", "SpriteCook + upscale 4x", base + f"indofight_char_{name}_splash.png")
        add("karakter", name, "icon", "Ikon grid", "64x64", 1, "", "SpriteCook + upscale 4x", base + f"indofight_char_{name}_icon.png")
        add("karakter", name, "icon_hud", "Ikon HUD", "32x32", 1, "", "Aseprite (dari ikon grid)", base + f"indofight_char_{name}_iconhud.png")
        for a in ANIMS:
            add("animasi", name, a[0], a[1], "160x160/frame", a[2], "ya" if a[3] else "tidak", "SpriteCook animate_game_art + Aseprite", base + f"indofight_char_{name}_{a[0]}_sheet.png")
        for code, isi, w, h, fr, _ in ch["props"]:
            add("properti", name, code, isi, f"{w}x{h}", fr, "", "SpriteCook", base + f"props/indofight_char_{name}_{code}.png")
    return rows


if __name__ == "__main__":
    for n in ORDER:
        write_char(n, C[n])
    rows = manifest_rows()
    with open(os.path.join(KIT, "production", "_char_rows.json"), "w") as f:
        json.dump(rows, f, ensure_ascii=False)
    print("characters:", len(ORDER), "rows:", len(rows))
