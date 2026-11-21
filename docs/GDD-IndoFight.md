# IndoFight — Game Design Document

Nov 10, 2026 · @jeje

## 1. Ringkasan Game

IndoFight adalah game fighting 2D bergaya pixel art dengan 10 karakter satire khas Indonesia dan 6 stage berlokasi ikonik. Tidak ada karakter utama: pemain langsung memilih dari roster seperti di Tekken, lalu bertarung dengan kombat pukul-tendang seperti Shadow Fight.

| Atribut | Isi |
| --- | --- |
| Judul | IndoFight |
| Genre | 2D Fighting Game |
| Acuan kombat | Shadow Fight (pukulan, tendangan, block, skill, ultimate) |
| Acuan roster dan UI | Tekken (grid pemilihan karakter, preview full-body P1 vs P2) |
| Gaya visual | Pixel art 16-bit, karakter berwarna penuh dengan kostum jelas, bukan siluet |
| Platform | PC dan Mobile (Android/iOS) |
| Mode | Arcade, Versus (lokal dan online), Training |
| Konten awal | 10 karakter, 6 stage |
| Karakter utama | Tidak ada |

**Pilar desain**

1. Satire budaya Indonesia: setiap karakter adalah tipe orang atau sosok yang langsung dikenali orang Indonesia, dan semua jurusnya lelucon visual tentang tipe itu.
2. Kombat yang terbaca jelas: setiap serangan punya animasi dan efek yang mudah dibedakan, sehingga pemain tahu apa yang terjadi meski layar ramai.
3. Presentasi arcade: layar pilih karakter, layar Versus, teks FIGHT! dan K.O. yang besar, ultimate dengan cinematic singkat.
4. Identitas audio Gamelan Cyberpunk: gamelan digabung EDM atau rock, dengan suara pukulan yang berat dan renyah.

## 2. Arah Visual dan Spesifikasi Teknis

Semua aset dibuat sebagai pixel art 16-bit pada resolusi dasar 480x270, lalu diperbesar tepat 4 kali ke 1920x1080. Keputusan ini menggantikan gaya "2.5D atau 2D High-Resolution Vector" di draf awal, karena gambar referensi tema yang dipakai adalah pixel art.

**Ciri gaya yang dipertahankan dari referensi**

- Proporsi karakter semi-realistis (sekitar 6 kepala), bukan chibi.
- Garis tepi gelap satu piksel, warna gelap dari palet karakter itu sendiri, bukan hitam murni.
- Bayangan 2 sampai 3 tingkat per warna, sumber cahaya dari kiri atas.
- Siluet tiap karakter harus bisa dikenali dari bentuknya saja: helm Ojol, caping Kuli, kain pocong, sayap Gatot Kaca, sapu lidi Emak-Emak.
- Stage bernuansa senja atau malam dengan langit gradasi, detail jalanan yang ramai, dan teks tulisan tangan yang terbaca.

**Spesifikasi teknis**

| Item | Ukuran asli (piksel) | Ukuran ekspor | Catatan |
| --- | --- | --- | --- |
| Layar game | 480 x 270 | 1920 x 1080 (4x) | Layar mobile yang lebih lebar menampilkan stage lebih banyak ke samping, bukan meregangkan gambar |
| Tinggi karakter berdiri | 96 sampai 112 | 384 sampai 448 | Gatot Kaca dan Kuli Jawa boleh di batas atas, Bocah Warnet di batas bawah |
| Kanvas frame animasi | 160 x 160 | 640 x 640 | Ruang untuk sapu lidi, ayunan keris, sayap |
| Splash art (layar pilih karakter dan Versus) | 270 x 480 | 1080 x 1920 | PNG transparan |
| Ikon grid (mugshot) | 64 x 64 | 256 x 256 | PNG, latar boleh berwarna sesuai tema karakter |
| Lebar stage | 960 x 270 per layer | 3840 x 1080 | Kamera bergeser mengikuti petarung |

**Aturan wajib supaya tampilan konsisten**

1. Perbesar selalu dengan kelipatan bulat (2x, 3x, 4x) memakai nearest-neighbor. Perbesaran 2,5x atau filter bilinear membuat piksel buram dan tidak rata.
2. Satu ukuran piksel untuk semua aset. Karakter, stage, efek, dan UI tidak boleh dicampur antara aset yang digambar di 480x270 dan aset yang digambar di resolusi lain.
3. Tanpa anti-aliasing otomatis dan tanpa piksel setengah transparan di tepi sprite, kecuali efek seperti asap dan cahaya.
4. Setiap karakter punya palet terkunci 16 sampai 24 warna. Warna di luar palet itu dianggap kesalahan.
5. Titik pivot setiap frame berada di tengah telapak kaki, supaya karakter tidak bergeser saat ganti animasi.

**Gambar referensi tema.** Dua gambar di bawah adalah contoh arah gaya, bukan aset final. Lihat bagian 10 untuk hal yang harus dirapikan dari gambar ini.

&#91;image: Referensi gaya karakter: 10 karakter IndoFight dalam pixel art, beberapa pose per karakter\]

&#91;image: Referensi gaya stage: Depan Gedung DPR saat senja dalam pixel art\]

## 3. Mode Permainan dan Alur Layar

Ada tiga mode bermain ditambah menu Options, dan semuanya melewati layar pilih karakter yang sama.

| Mode | Lawan | Isi |
| --- | --- | --- |
| Arcade | Komputer (AI) | Rangkaian pertarungan melawan karakter lain secara berurutan sampai tamat |
| Versus Lokal | Pemain lain di perangkat yang sama | 1 lawan 1, pilih karakter dan stage bebas |
| Versus Online | Pemain lain lewat internet | 1 lawan 1, matchmaking |
| Training | Boneka latihan | Latihan kombo, HP dan energi bisa diatur penuh terus |
| Options | - | Audio, kontrol, bahasa, grafis |

**Alur layar satu pertarungan**

1. Main Menu: pilih Arcade, Versus, Training, atau Options.
2. Character Select: P1 dan P2 memilih karakter dari grid.
3. Stage Select: hanya di Versus dan Training. Di Arcade stage ditentukan oleh lawan.
4. Layar Versus: splash art P1 di kiri dan P2 di kanan, dengan nama karakter besar.
5. Pertarungan: teks FIGHT! di awal ronde, K.O. atau TIME UP di akhir ronde.
6. Layar hasil: pose Victory pemenang, tombol Rematch, Ganti Karakter, Kembali ke Menu.

Jumlah lawan di Arcade, jumlah ronde per pertarungan, dan apakah ada bos terakhir belum ditentukan. Ketiganya ada di daftar keputusan terbuka (bagian 11).

## 4. Mekanik Kombat

Setiap karakter memakai set aksi yang sama: gerak, 4 serangan dasar, block, 1 skill, dan 1 ultimate yang memakai energi penuh. Perbedaan antar-karakter ada di jangkauan, kecepatan, senjata, dan efek dari skill serta ultimate.

**Aksi dasar**

| Aksi | Fungsi | Input PC (usulan) | Input mobile (usulan) |
| --- | --- | --- | --- |
| Jalan maju dan mundur | Mengatur jarak | A / D | Joystick virtual kiri |
| Dash dan step | Maju atau mundur cepat | Tekan arah dua kali | Geser cepat joystick |
| Lompat | Menghindari serangan bawah | W | Joystick ke atas |
| Jongkok | Menghindari serangan atas | S | Joystick ke bawah |
| Light Punch | Pukulan cepat, damage kecil | J | Tombol LP |
| Heavy Punch | Pukulan lambat, damage besar | K | Tombol HP |
| Light Kick | Tendangan cepat, jangkauan sedikit lebih jauh | U | Tombol LK |
| Heavy Kick | Tendangan lambat, bisa menjatuhkan lawan | I | Tombol HK |
| Block | Menahan serangan biasa, damage jadi sangat kecil | L (tahan) | Tombol Block (tahan) |
| Skill | Jurus khusus karakter, ada cooldown | O | Tombol Skill |
| Ultimate | Jurus pamungkas, butuh energi penuh | P | Tombol Ultimate (menyala saat penuh) |

Basic attack di bagian roster menjelaskan bentuk visual keempat serangan dasar itu untuk tiap karakter. Contohnya, Light Punch Emak-Emak adalah sabetan sapu lidi dengan jangkauan panjang.

**Aturan pertarungan**

- Waktu per ronde 99 detik. Jika waktu habis, pemain dengan sisa HP lebih banyak menang ronde itu.
- Energy bar terisi setiap kali memberi atau menerima damage. Saat penuh, ultimate bisa dipakai, lalu energi kembali ke nol.
- Ultimate memutar cinematic singkat dengan overlay hitam-putih atau merah. Selama cinematic, waktu ronde berhenti.
- Kombo dihitung dari serangan yang mengenai lawan berturut-turut tanpa lawan sempat pulih, dan ditampilkan sebagai COMBO xN.

**Efek status yang dipakai roster**

| Efek | Arti | Dipakai oleh |
| --- | --- | --- |
| Stun | Lawan tidak bisa bergerak sesaat | Mahasiswa (Sonic Toa), Pocong (Jump Scare) |
| Burn | Damage kecil terus-menerus selama beberapa detik | Mahasiswa (Demo Massa) |
| Blind | Serangan lawan meleset selama 3 detik | Intel Bakso (Kuah Sambal) |
| Slow | Gerakan lawan melambat di dalam area asap | Dukun Santet (Kemenyan Smoke) |
| Buff | Damage dan kecepatan naik 5 detik, HP berkurang sedikit | Kuli Jawa (Kopi Buff) |
| Unblockable | Tidak bisa ditahan dengan block | Emak-Emak (Sein Kanan Belok Kiri), Dukun Santet (Santet Paku) |
| Lifesteal | HP lawan berpindah ke HP penyerang | Pocong (Jump Scare) |
| Homing | Proyektil mengejar lawan | Bocah Warnet (Toxic Chat) |
| Projectile pierce | Menembus proyektil lawan | Gatot Kaca (Dash of Muscle) |
| Teleport/evade | Menghindar instan, cocok untuk serangan balik | Abang Ojol (Cancel Order) |

Angka pasti (damage tiap serangan, lama cooldown skill, lama stun dan burn) belum ditetapkan dan diatur saat balancing di bagian 11.

## 5. Desain UI dan UX

UI memakai gaya neon modern-grunge yang tetap pixel art, dengan teks besar dan sedikit tombol agar nyaman di layar sentuh.

### 5.1 Main Menu

- Latar: animasi jalanan ikonik Indonesia saat senja, yaitu Bundaran HI atau Malioboro. Animasi ringan saja: lampu kendaraan lewat, awan bergerak, lampu jalan berkedip.
- Tombol: Arcade, Versus, Training, Options, tersusun vertikal di sisi kiri.
- Logo IndoFight di bagian atas.

### 5.2 Character Select (gaya Tekken)

- Grid ikon 64x64 di bagian bawah layar. Dengan 10 karakter, grid berisi 2 baris x 5 kolom.
- Saat kursor berada di ikon, splash art full-body muncul di kiri untuk P1 dan di kanan untuk P2, memutar animasi Idle atau Taunt karakter itu.
- Nama karakter tampil besar di bawah splash art, memakai font graffiti atau blok besi.
- Kursor P1 dan P2 dibedakan warna, misalnya merah untuk P1 dan biru untuk P2.

### 5.3 Combat HUD

| Elemen | Posisi | Tampilan |
| --- | --- | --- |
| Health bar | Kiri atas (P1) dan kanan atas (P2) | Isi hijau, berubah kuning lalu merah saat HP turun. Bagian yang hilang berkurang perlahan dengan efek pecah |
| Nama dan ikon karakter | Di bawah health bar masing-masing | Ikon 32x32 dan nama |
| Timer | Tengah atas | Angka digital besar, mulai dari 99 |
| Penanda ronde | Di samping timer | Titik yang menyala untuk tiap ronde yang dimenangkan |
| Energy bar | Kiri bawah (P1) dan kanan bawah (P2) | Biru neon, berubah emas dan berkedip saat penuh |
| Teks dinamis | Tengah layar | FIGHT!, K.O., PERFECT, TIME UP, COMBO xN |
| Tombol sentuh (mobile) | Joystick kiri bawah, tombol serangan kanan bawah | Semi-transparan, di atas energy bar |

Tata letak HUD dalam satu layar:

&#91;embedded content: Tata letak Combat HUD · layar 16:9\]

HP dan identitas pemain ada di atas, energi dan kontrol sentuh di bawah, sehingga area tengah tempat P1 dan P2 bertarung tetap bersih.

## 6. Roster Karakter

Roster berisi 10 karakter dengan gaya bertarung yang berbeda-beda, dari zoner jarak jauh sampai petarung jarak dekat yang cepat. Kolom peran adalah usulan pengelompokan dari kemampuan yang sudah ditulis, untuk membantu balancing.

| No | Karakter | Julukan | Peran (usulan) | Skill | Ultimate |
| --- | --- | --- | --- | --- | --- |
| 1 | Mahasiswa | The Protester | Kontrol jarak menengah | Sonic Toa | Demo Massa |
| 2 | Jenderal Gemoy | The General | Tank dengan proyektil | Susu Lempar | Supply Drop MBG |
| 3 | Gatot Kaca | The Legend | Petarung berat, menyerbu | Dash of Muscle | Hujan Brajamusti |
| 4 | Emak-Emak | The Street Boss | Jangkauan panjang | Tupperware Boomerang | Sein Kanan Belok Kiri |
| 5 | Intel Bakso | The Agent | Jarak dekat, pengganggu | Kuah Sambal | Kijang Satu Ganti |
| 6 | Kuli Jawa | The Builder | Power dengan buff | Kopi Buff | Proyek Roro Jonggrang |
| 7 | Abang Ojol | The Speedster | Cepat, serangan balik | Cancel Order | Bintang Lima Bos! |
| 8 | Dukun Santet | The Zoner | Zoner jarak jauh | Kemenyan Smoke | Santet Paku |
| 9 | Pocong Brawler | The Undead | Serangan kejutan | Earth Dive | Jump Scare |
| 10 | Bocah Warnet | The Annoyance | Pengganggu dengan proyektil | Toxic Chat | Disconnect |

Setiap karakter di bawah memuat konsep visual, serangan dasar, skill, ultimate, dan kunci visual. Kunci visual adalah detail yang wajib sama di semua frame, termasuk perbaikan dari gambar referensi.

### 6.1 Mahasiswa (The Protester)

- **Visual:** pemuda dengan jaket almamater biru terbuka, ikat kepala merah putih, Toa di satu tangan dan tongkat spanduk di tangan lain, ransel di punggung.
- **Serangan dasar:** pukulan dengan gagang spanduk dan ayunan tas ransel.
- **Skill, Sonic Toa:** berteriak lewat Toa, keluar gelombang suara yang terlihat. Jarak menengah, efek Stun.
- **Ultimate, Demo Massa:** hujan ban bekas terbakar jatuh dari langit, ditutup lemparan molotov yang memberi efek Burn.
- **Kunci visual:** jaket biru, ikat kepala merah putih, celana gelap. Molotov hanya milik karakter ini.

### 6.2 Jenderal Gemoy (The General)

- **Visual:** pria paruh baya karismatik, tegap tapi agak chubby, kemeja safari cokelat, kacamata hitam, membawa nampan stainless Makan Bergizi Gratis (MBG) sebagai perisai.
- **Serangan dasar:** pukulan taktis militer (CQC) dan hantaman nampan MBG.
- **Skill, Susu Lempar:** melempar kotak susu dengan presisi seperti shuriken, cepat dan lurus.
- **Ultimate, Supply Drop MBG:** menunjuk lawan, lalu kotak ransum dan nampan MBG berjatuhan dari helikopter yang hanya terlihat bayangannya, ditutup pose hormat.
- **Kunci visual:** safari cokelat, kacamata hitam, nampan bertulisan Makan Bergizi Gratis. Di gambar referensi, frame pertama memegang molotov. Itu salah dan harus dihapus.

### 6.3 Gatot Kaca (The Legend)

- **Visual:** kesatria wayang versi modern, tubuh berotot, zirah perunggu Brajamusti yang menyala dengan petir, sayap hitam magis di punggung.
- **Serangan dasar:** tinju dan tendangan berat yang dibalut energi petir.
- **Skill, Dash of Muscle:** melesat terbang ke arah lawan seperti roket, menembus proyektil lawan.
- **Ultimate, Hujan Brajamusti:** terbang tinggi ke luar layar, lalu menukik seperti meteor dan menghasilkan ledakan seluas layar.
- **Kunci visual:** zirah perunggu, petir warna biru muda, sayap hitam. Sayap digambar sebagai sprite terpisah agar bisa mengepak sendiri. Referensi baru punya pose terbang, jadi pose berdiri di tanah masih harus dirancang.

### 6.4 Emak-Emak (The Street Boss)

- **Visual:** ibu-ibu berdaster motif bunga, helm half-face kebesaran, kacamata hitam, membawa sapu lidi raksasa atau Tupperware.
- **Serangan dasar:** sabetan sapu lidi dengan jangkauan sangat panjang.
- **Skill, Tupperware Boomerang:** melempar kotak bekal yang berputar dan kembali ke tangannya. Lawan yang berhasil menghindar masih bisa terkena saat kotak kembali.
- **Ultimate, Sein Kanan Belok Kiri:** memanggil motor matic, menyalakan sein kanan, lalu tiba-tiba menabrak ke kiri dengan cepat. Unblockable.
- **Kunci visual:** di referensi warna helm berganti abu-abu dan pink, dan warna daster berganti pink dan hijau. Pilih satu kombinasi dan kunci di palet.

### 6.5 Intel Bakso (The Agent)

- **Visual:** pria dengan topi kupluk, kemeja flanel pudar, jeans, mangkok bakso ayam jago di tangan kiri, Walkie Talkie di tangan kanan, earphone agen rahasia.
- **Serangan dasar:** siraman kuah panas jarak dekat dan pukulan mangkok keramik tebal.
- **Skill, Kuah Sambal:** menyemburkan kuah merah menyala yang membuat lawan Blind selama 3 detik.
- **Ultimate, Kijang Satu Ganti:** bicara ke Walkie Talkie, laser sniper merah mengunci lawan, lalu tembakan beruntun dari luar layar. Ditutup dengan Intel makan bakso dengan santai.
- **Kunci visual:** kupluk abu-abu, flanel merah kotak-kotak, mangkok ayam jago. Kacamata hitam hanya dipakai saat ultimate.

### 6.6 Kuli Jawa (The Builder)

- **Visual:** pria berotot kawat, kulit sawo matang gelap, kaos oblong digulung ke bahu, celana training, caping. Membawa cetok semen dan segelas kopi hitam, handuk di leher.
- **Serangan dasar:** ayunan cetok semen yang berat dan sabetan handuk leher.
- **Skill, Kopi Buff:** minum kopi hitam. HP berkurang sedikit, tetapi damage dan kecepatan naik drastis selama 5 detik.
- **Ultimate, Proyek Roro Jonggrang:** menyusun tembok bata dengan kilat di depan lawan, lalu menendangnya sampai roboh menimpa lawan.
- **Kunci visual:** caping dipakai sebagai topi utama, mengikuti referensi. Handuk leher belum terlihat di referensi dan harus ditambahkan.

### 6.7 Abang Ojol (The Speedster)

- **Visual:** pemuda berjaket hijau dengan garis reflektif yang menyala, helm hijau, smartphone di dada yang menampilkan peta.
- **Serangan dasar:** kombo tendangan cepat gaya taekwondo dan pukulan dengan helm cadangan.
- **Skill, Cancel Order:** menghindar instan dengan teleport jarak pendek, meninggalkan bayangan digital. Cocok untuk serangan balik.
- **Ultimate, Bintang Lima Bos!:** menabrak lawan dengan motor bebek, lalu serangkaian serangan kilat dengan helm hijau, ditutup notifikasi Bintang 5 yang jatuh di atas kepala lawan.
- **Kunci visual:** hijau jaket dan helm satu warna yang sama. Smartphone di dada belum ada di referensi dan harus ditambahkan. Jangan memakai logo atau nama aplikasi ojek online yang nyata.

### 6.8 Dukun Santet (The Zoner)

- **Visual:** pria tua bernuansa gelap dan misterius, pakaian adat hitam legam, blangkon, membawa boneka voodoo jerami, diselimuti asap kemenyan.
- **Serangan dasar:** tembakan energi ungu jarak jauh dan ayunan keris.
- **Skill, Kemenyan Smoke:** membuat awan asap di arena. Lawan yang masuk asap menjadi Slow.
- **Ultimate, Santet Paku:** menusuk boneka jerami, layar berkedip merah, lalu lawan memuntahkan paku hitam dari dalam tubuhnya. Unblockable.
- **Kunci visual:** blangkon wajib ada, di referensi belum terlihat. Wajah ungu hanya muncul saat merapal jurus, bukan di pose biasa.

### 6.9 Pocong Brawler (The Undead)

- **Visual:** hantu modern, bukan pocong seram biasa. Kain kafan agak kotor, tali pocong dililit ke tangan seperti hand-wrap Muay Thai, wajah tertutup bayangan dengan mata menyala.
- **Serangan dasar:** lompatan sundulan dan cambukan tali kafan.
- **Skill, Earth Dive:** melompat masuk ke tanah lalu muncul dari bawah kaki lawan dengan uppercut.
- **Ultimate, Jump Scare:** wajah pocong memenuhi layar selama 1 detik dengan suara melengking. Lawan terkena Stun total dan HP-nya terserap pelan-pelan ke Pocong (Lifesteal).
- **Kunci visual:** gerakan tetap melompat-lompat karena kaki terikat. Mata di referensi masih hitam dan harus diganti menjadi mata menyala.

### 6.10 Bocah Warnet (The Annoyance)

- **Visual:** anak SMP berseragam putih-biru berantakan, kantung mata hitam karena kurang tidur, ransel, keyboard mekanikal RGB dengan kabel putus sebagai senjata utama.
- **Serangan dasar:** pukulan keyboard dan lemparan mouse gaming yang terikat kabel seperti yoyo.
- **Skill, Toxic Chat:** memaki lawan, muncul balon teks berisi simbol sensor @#$%! yang berbentuk fisik dan mengejar lawan (Homing).
- **Ultimate, Disconnect:** mencabut kabel power khayalan, arena gelap gulita dengan efek lag dan glitch. Dalam gelap, Bocah Warnet memukul bertubi-tubi dengan keyboard RGB yang menyala, ditutup pukulan GGWP.
- **Kunci visual:** lampu RGB keyboard adalah satu-satunya sumber cahaya saat ultimate, jadi butuh palet terang khusus untuk keyboard.

## 7. Stage dan Arena

Ada 6 stage, masing-masing tersusun dari 4 layer parallax PNG transparan yang bergeser dengan kecepatan berbeda supaya terasa punya kedalaman. Stage keenam, Proyek Mangkrak, berasal dari daftar aset dan belum ada di draf konsep awal.

**Struktur 4 layer (berlaku untuk semua stage)**

| Layer | Posisi | Kecepatan geser terhadap kamera (usulan) | Isi |
| --- | --- | --- | --- |
| Foreground | Paling depan | 1,2x | Benda yang sedikit menutupi tepi bawah layar, agak gelap atau buram |
| Midground | Area tarung | 1,0x | Lantai tempat karakter berpijak, garis lantai harus rata |
| Background | Di belakang petarung | 0,5x | Gedung, pohon, atau elemen utama arena |
| Skybox | Paling jauh | 0,1x | Langit, awan, bulan, atau matahari. Untuk stage dalam ruangan diganti dinding belakang |

**Daftar stage**

| No | Stage | Suasana | Karakter tuan rumah (usulan) |
| --- | --- | --- | --- |
| 1 | Depan Gedung DPR | Senja, sisa demo | Mahasiswa |
| 2 | Lobi Istana / Kemenhan | Dalam ruangan, formal dan mengkilap | Jenderal Gemoy |
| 3 | Candi Prambanan Malam | Malam purnama, magis | Gatot Kaca, Dukun Santet |
| 4 | Gang Sempit Perkampungan | Malam, padat dan basah | Emak-Emak, Intel Bakso, Pocong Brawler |
| 5 | Proyek Mangkrak | Ketinggian, berdebu | Kuli Jawa |
| 6 | Warnet "Berkah" | Dalam ruangan, pengap, lampu neon | Bocah Warnet, Abang Ojol |

### 7.1 Depan Gedung DPR

- **Skybox:** langit senja ungu-jingga dengan awan, seperti di gambar referensi.
- **Background:** gedung dewan dengan kubah hijau, gerbang hijau tertutup, pagar penuh coretan, spanduk tuntutan, bendera merah putih, asap gas air mata tipis.
- **Midground:** jalan aspal retak dengan coretan cat semprot, botol air, kertas berserakan, ban bekas berasap.
- **Foreground:** pagar kawat berduri dan barikade beton yang sedikit buram.
- **Animasi:** asap tipis bergerak, asap ban mengepul.

### 7.2 Lobi Istana / Kemenhan

- **Dinding belakang:** pengganti skybox, dinding tinggi berwarna krem dengan langit-langit berornamen.
- **Background:** lukisan pahlawan, bendera merah putih, penjaga kehormatan yang berdiri diam.
- **Midground:** karpet merah tebal di atas lantai pualam mengkilap dengan pantulan karakter.
- **Foreground:** pilar marmer besar di kiri dan kanan layar.
- **Animasi:** kilau pantulan lantai, penjaga sesekali berkedip.

### 7.3 Candi Prambanan Malam

- **Skybox:** langit malam dengan bulan purnama.
- **Background:** siluet candi besar yang disinari cahaya bulan, petir menyambar sesekali.
- **Midground:** pijakan batu andesit candi kuno.
- **Foreground:** rerumputan gelap dan obor menyala.
- **Animasi:** api obor, kilat petir yang menerangi layar sesaat.

### 7.4 Gang Sempit Perkampungan

- **Skybox:** langit malam berawan (usulan, waktu belum disebut di konsep).
- **Background:** rumah padat penduduk, tiang listrik dengan kabel ruwet, lampu jalan kuning yang berkedip.
- **Midground:** jalan konblok sempit dengan genangan air.
- **Foreground:** gerobak bakso yang terparkir dan jemuran baju emak-emak.
- **Animasi:** lampu jalan berkedip, jemuran bergoyang, riak genangan saat diinjak.

### 7.5 Proyek Mangkrak

- **Skybox:** langit kota senja yang berkabut (usulan).
- **Background:** scaffolding bambu dan besi, pemandangan gedung pencakar langit dari ketinggian.
- **Midground:** lantai beton kasar yang belum jadi.
- **Foreground:** tumpukan pipa besi dan sak semen.
- **Animasi:** debu beterbangan, terpal berkibar.

### 7.6 Warnet "Berkah"

- **Dinding belakang:** pengganti skybox, dinding kusam penuh poster game jadul.
- **Background:** barisan PC dengan layar menyala menampilkan game, lampu redup neon biru dan ungu.
- **Midground:** lantai keramik putih usang.
- **Foreground:** kursi plastik merah dan tumpukan gelas minuman energi.
- **Animasi:** layar PC berkedip, lampu neon sesekali padam.

## 8. Kebutuhan Aset Karakter

Setiap karakter butuh 4 paket aset: splash art, ikon grid, sprite sheet animasi, dan properti khusus. Animasi dibuat frame per frame, tidak memakai rigging tulang Spine 2D atau Unity Anima2D. Rigging memutar potongan gambar, dan pada pixel art putaran itu merusak bentuk piksel.

### 8.1 Paket aset per karakter

| Aset | Ukuran asli | Ukuran ekspor | Format | Dipakai di |
| --- | --- | --- | --- | --- |
| Splash art full-body | 270 x 480 | 1080 x 1920 | PNG transparan | Character Select, layar Versus |
| Ikon grid (mugshot) | 64 x 64 | 256 x 256 | PNG | Grid Character Select |
| Ikon HUD | 32 x 32 | 128 x 128 | PNG | Samping health bar |
| Sprite sheet animasi | 160 x 160 per frame | 640 x 640 per frame | PNG + data frame (JSON) | Pertarungan |
| Properti dan proyektil | Sesuai benda | 4x | PNG transparan | Pertarungan, ultimate |

### 8.2 Animasi wajib

Daftar ini menggabungkan 11 animasi di draf konsep dengan 18 animasi di daftar aset, ditambah Taunt untuk preview di Character Select. Jumlah frame adalah usulan awal untuk menghitung beban kerja.

| No | Animasi | Keterangan | Frame (usulan) |
| --- | --- | --- | --- |
| 1 | Idle | Bernapas, berulang | 6 |
| 2 | Walk Forward | Berulang | 8 |
| 3 | Walk Backward | Berulang | 8 |
| 4 | Dash / Step | Maju atau mundur cepat | 4 |
| 5 | Jump | Naik, puncak, turun | 6 |
| 6 | Crouch | Turun lalu diam | 2 |
| 7 | Light Punch | Cepat | 4 |
| 8 | Heavy Punch | Ada ancang-ancang | 6 |
| 9 | Light Kick | Cepat | 4 |
| 10 | Heavy Kick | Ada ancang-ancang | 6 |
| 11 | Block | Posisi bertahan | 2 |
| 12 | Hit | Terkena serangan | 3 |
| 13 | Knockup | Terlempar ke udara | 4 |
| 14 | Knockdown | Jatuh lalu bangun | 5 |
| 15 | Special Skill | Jurus skill karakter | 8 |
| 16 | Ultimate Cast | Pose awal ultimate sebelum cinematic | 10 |
| 17 | Defeat | Kalah | 6 |
| 18 | Victory | Pose menang | 8 |
| 19 | Taunt | Untuk preview Character Select | 6 |

Totalnya sekitar 106 frame per karakter, atau sekitar 1.060 frame untuk 10 karakter, belum termasuk frame cinematic ultimate dan efek.

### 8.3 Properti, proyektil, dan aset ultimate per karakter

| Karakter | Properti dan senjata | Proyektil dan efek khusus | Aset ultimate |
| --- | --- | --- | --- |
| Mahasiswa | Jaket almamater, ransel, Toa, tongkat spanduk | Gelombang suara Toa | Ban bekas terbakar, molotov, api Burn |
| Jenderal Gemoy | Kacamata hitam, nampan MBG | Kotak susu | Bayangan helikopter, kotak ransum berparasut, nampan MBG jatuh |
| Gatot Kaca | Zirah Brajamusti, sayap hitam (sprite terpisah) | Aura petir di kepalan, jejak dash | Efek meteor menukik, ledakan seluas layar |
| Emak-Emak | Daster, helm half-face, kacamata hitam, sapu lidi | Tupperware berputar | Motor matic dengan lampu sein menyala |
| Intel Bakso | Kupluk, earphone, mangkok ayam jago, Walkie Talkie | Cipratan kuah panas, semburan kuah sambal | Laser sniper merah, kilatan tembakan dari luar layar, bakso di sendok |
| Kuli Jawa | Caping, handuk leher, cetok semen, gelas kopi | Uap kopi, aura buff | Tumpukan batu bata, tembok bata roboh, debu |
| Abang Ojol | Jaket hijau reflektif, helm hijau, smartphone di dada, helm cadangan | Bayangan digital Cancel Order | Motor bebek, jejak serangan kilat, notifikasi Bintang 5 |
| Dukun Santet | Blangkon, keris, boneka voodoo jerami | Bola energi ungu, awan asap kemenyan | Layar berkedip merah, proyektil paku hitam |
| Pocong Brawler | Kain kafan, tali kafan sebagai hand-wrap | Mata menyala, lubang tanah Earth Dive | Wajah pocong layar penuh, efek HP terserap |
| Bocah Warnet | Keyboard RGB kabel putus, mouse gaming berkabel, ransel | Balon teks @#$%! | Layar gelap dengan glitch, cahaya RGB, teks GGWP |

## 9. Kebutuhan Aset UI, VFX, dan Audio

Selain karakter dan stage, game butuh 3 kelompok aset pendukung: UI dan HUD, efek visual, serta musik dan suara. Semuanya mengikuti aturan pixel art di bagian 2.

### 9.1 UI dan HUD

| Aset | Isi | Catatan |
| --- | --- | --- |
| Tombol menu | State Normal, Hover, Pressed | Gaya neon modern atau besi berkarat, pilih satu (bagian 11) |
| Frame health bar | Desain metalik atau bercak cat | Kiri dan kanan, dicerminkan |
| Isi health bar | Hijau, kuning, merah + lapisan bagian yang hilang perlahan | Efek pecah saat berkurang |
| Energy bar | Biru neon, emas saat penuh | Ada animasi berkedip saat penuh |
| Timer | Frame timer + angka digital 0 sampai 9 | Angka sebagai sprite terpisah |
| Teks dinamis | FIGHT!, K.O., PERFECT, TIME UP, COMBO xN, ROUND 1 sampai 3 | Sprite teks besar, ada animasi masuk |
| Font nama karakter | Heavy sans serif atau graffiti, versi pixel | Dipakai di Character Select dan layar Versus |
| Font UI umum | Font pixel yang mudah dibaca | Untuk menu, Options, angka kecil |
| Kontrol sentuh | Joystick virtual, 6 tombol aksi | Semi-transparan, hanya di mobile |
| Logo IndoFight | Versi besar dan kecil | Main menu dan ikon aplikasi |
| Latar main menu | Bundaran HI atau Malioboro senja, beranimasi | Belum ada di daftar aset awal |

### 9.2 Efek visual (VFX)

Semua efek bergaya komik, tanpa darah realistis.

| Efek | Kapan muncul |
| --- | --- |
| Hit spark tumpul | Pukulan, tendangan, benda tumpul mengenai lawan |
| Hit spark tajam | Keris, sapu lidi, cetok mengenai lawan |
| Block spark | Serangan ditangkis, percikan api atau perisai biru |
| Impact flash dan speed lines | Heavy attack dan serangan terakhir kombo |
| Dash dust | Kepulan debu kecil di kaki saat dash, lompat, mendarat |
| Overlay ultimate | Filter hitam-putih atau merah saat ultimate dimulai |
| Screen crack | Retakan kaca transparan saat ultimate mengenai lawan |
| Ikon status | Bintang berputar (Stun), api (Burn), mata tertutup (Blind), siput (Slow), panah naik (Buff) |

### 9.3 Audio

- **Musik:** Gamelan Cyberpunk, yaitu gamelan digabung EDM atau rock. Minimal 1 lagu main menu, 1 lagu Character Select, dan 1 lagu per stage (6 lagu).
- **Suara pukulan:** berat dan renyah, dibedakan untuk pukulan ringan, pukulan berat, benda tumpul, benda tajam, dan block.
- **Suara khas karakter:** teriakan Toa, kotak susu dilempar, petir Gatot Kaca, motor matic dan bunyi sein, kuah disiram, seruput kopi, bunyi notifikasi ojol, tusukan boneka santet, lengkingan Jump Scare, ketikan keyboard mekanikal.
- **Suara UI:** kursor pindah, pilih, batal, hitung mundur timer.
- **Penyiar (announcer):** suara untuk FIGHT!, K.O., PERFECT belum disebut di konsep awal dan masuk keputusan terbuka.

## 10. Pipeline Produksi Aset dan Konsistensi

AI image generator boleh dipakai untuk konsep awal, tetapi aset final harus dirapikan manual di editor pixel art seperti Aseprite. Alasannya, AI sering mengubah detail karakter dari satu gambar ke gambar lain, dan grid pikselnya tidak rapi.

### 10.1 Urutan kerja per karakter

1. Model sheet: gambar karakter dari depan, samping, dan belakang di ukuran asli, lengkap dengan palet terkunci dan daftar kunci visual dari bagian 6.
2. Konsep pose: buat pose kunci (Idle, Light Punch, Skill, Ultimate) dengan AI atau sketsa tangan, selalu menyertakan model sheet sebagai acuan.
3. Rapikan di Aseprite: sesuaikan ke ukuran asli, ganti semua warna ke palet terkunci, hapus piksel buram dan anti-aliasing.
4. Animasi frame per frame: kerjakan 19 animasi dari bagian 8.2, mulai dari Idle dan serangan dasar supaya bisa langsung diuji di game.
5. Ekspor: sprite sheet PNG + file data frame JSON, pivot di tengah telapak kaki.
6. Uji di engine: cek ukuran, posisi, dan kecepatan animasi bersama HUD dan stage sebelum lanjut ke karakter berikutnya.

### 10.2 Perbaikan dari gambar referensi

| Gambar | Masalah | Perbaikan |
| --- | --- | --- |
| Jenderal Gemoy frame 1 | Memegang molotov | Hapus, ganti nampan MBG |
| Emak-Emak | Helm abu-abu dan pink, daster pink dan hijau | Pilih satu kombinasi warna |
| Dukun Santet | Wajah ungu di satu frame, blangkon tidak terlihat | Wajah normal di pose biasa, tambahkan blangkon |
| Pocong Brawler | Mata hitam | Ganti dengan mata menyala |
| Abang Ojol | Tidak ada smartphone di dada | Tambahkan smartphone dengan layar peta |
| Kuli Jawa | Tidak ada handuk leher | Tambahkan handuk |
| Gatot Kaca | Hanya pose terbang | Rancang pose berdiri di tanah |
| Stage DPR | Teks spanduk rusak, masih satu gambar utuh | Tulis ulang teks secara manual, pisah jadi 4 layer |

### 10.3 Penamaan file

Format: `indofight_<kategori>_<nama>_<aset>_<nomor>.png`, semua huruf kecil tanpa spasi.

- `indofight_char_mahasiswa_idle_sheet.png`
- `indofight_char_mahasiswa_splash.png`
- `indofight_stage_dpr_midground.png`
- `indofight_vfx_hitspark_blunt_sheet.png`
- `indofight_ui_healthbar_frame.png`

### 10.4 Checklist sebelum aset dianggap selesai

- [ ] Dibuat di ukuran asli, diekspor tepat 4x dengan nearest-neighbor
- [ ] Semua warna ada di palet terkunci karakter atau stage
- [ ] Tidak ada anti-aliasing atau piksel setengah transparan di tepi sprite
- [ ] Latar transparan untuk sprite, splash art, dan layer stage
- [ ] Pivot di tengah telapak kaki dan sama di semua frame
- [ ] Kunci visual dari bagian 6 terpenuhi di semua frame
- [ ] Nama file sesuai format
- [ ] Sudah diuji di dalam game bersama HUD dan stage

## 11. Risiko dan Keputusan Terbuka

Risiko terbesar ada di Jenderal Gemoy, karena karakter ini memparodikan presiden yang sedang menjabat. Risiko lain menyangkut rating konten dan keseimbangan ultimate.

### 11.1 Risiko

| Risiko | Dampak | Penanganan |
| --- | --- | --- |
| Jenderal Gemoy memparodikan presiden yang sedang menjabat, ditambah tema demo di stage DPR | Bisa ditolak saat review Play Store atau App Store. Ada juga pasal penyerangan harkat dan martabat presiden di KUHP baru (delik aduan) | Hapus keterangan "Terinspirasi P. Prabowo" dari semua materi publik, jaga desain tetap karikatur. Risiko kecil jika hanya proyek kuliah atau portofolio |
| Molotov, gas air mata, santet, pocong, anak SMP yang dipukul | Rating usia naik, sebagian negara atau store membatasi | Tetap gaya komik tanpa darah, cek panduan rating IARC sebelum rilis |
| Merek nyata (jaket ojol, Tupperware, mangkok ayam jago) | Masalah merek dagang | Pakai warna khas tanpa logo atau nama merek asli |
| Tiga ultimate unblockable atau instan (Emak-Emak, Dukun Santet, Kuli Jawa) ditambah ledakan seluas layar Gatot Kaca | Pemain lawan tidak punya cara menghindar, terasa tidak adil | Beri jeda peringatan sebelum kena, atau buat bisa dihindari dengan lompat atau dash |
| Aset dari AI tidak konsisten | Karakter terlihat berubah antar-animasi | Ikuti pipeline di bagian 10 |
| Volume animasi sekitar 1.060 frame | Produksi lama | Buat 2 sampai 3 karakter dulu sebagai vertical slice |

### 11.2 Keputusan yang belum diambil

- [ ] Jumlah ronde per pertarungan (best of 3 adalah standar genre)
- [ ] Jumlah lawan di Arcade dan ada tidaknya bos terakhir
- [ ] Lama cooldown skill dan angka damage tiap serangan
- [ ] Engine yang dipakai (draf awal menyebut Unity)
- [ ] Cakupan Versus Online: matchmaking acak, room dengan kode, atau keduanya
- [ ] Gaya tombol UI: neon modern atau besi berkarat
- [ ] Kombinasi warna helm dan daster Emak-Emak
- [ ] Nama stage 2: Lobi Istana atau Lobi Kemenhan
- [ ] Latar main menu: Bundaran HI atau Malioboro
- [ ] Ada tidaknya suara penyiar untuk FIGHT!, K.O., PERFECT
- [ ] Tujuan rilis: proyek kuliah, portofolio, atau rilis publik di store (menentukan penanganan risiko Jenderal Gemoy)
