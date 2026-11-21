extends RefCounted
## Tabel pose dan animasi untuk rig Skeleton2D (docs/decisions.md no. 9, 15, dan 17).
## Dibaca tools/build_rigs.gd, yang mengubahnya menjadi animasi AnimationPlayer.
##
## Satu pose adalah kamus. Kunci yang tidak ditulis memakai nilai pose kuda-kuda (STAND).
##   torso   condong badan atas dari pinggang, dalam derajat, positif ke depan
##   pelvis  putaran tambahan badan bawah (rok atau pinggul). Tanpa ditulis pun badan bawah
##           ikut sepertiga condong badan atas, supaya badan melengkung dan tidak kaku.
##           Negatif = ujung bawah terayun ke depan (rok terangkat saat menendang).
##   head    miring kepala relatif ke badan, positif menunduk
##   af, ab  lengan depan dan belakang: [lengan atas, lengan bawah]
##   lf, lb  kaki depan dan belakang: [paha, betis]
##   prop    arah properti di tangan depan
##   hip     geser pinggul [x, y] dalam piksel. y dihitung otomatis supaya telapak kaki
##           menapak, kecuali animasinya bertanda "ground": false
##   leg_front  1 = kaki depan digambar di atas badan (untuk tendangan)
##   arm_back   1 = lengan depan dan propertinya digambar di belakang badan (ancang-ancang
##              ayunan ke belakang, supaya lengan tidak melintang di depan dada dan muka)
##   spin    putar seluruh badan (untuk jatuh), lift geser seluruh badan [x, y]
##   ground  true atau false untuk satu pose saja, mengalahkan tanda "ground" animasinya
##
## Arah anggota badan: 0 = lurus ke bawah, 90 = lurus ke depan, 180 = ke atas, negatif = ke belakang.
##
## Prinsip gerak yang dipakai di semua serangan, supaya seluruh badan ikut bergerak:
##   1. Ancang-ancang ke arah berlawanan (badan ditarik mundur, senjata diangkat).
##   2. Pukulan memindahkan pinggul ke depan, badan condong, dan kaki ikut melangkah.
##   3. Lengan yang tidak memukul mengayun berlawanan sebagai penyeimbang.
##   4. Kepala tetap menatap lawan (berlawanan dengan condong badan).
##
## Animasi serangan panjangnya 3 satuan: 0 sampai 1 ancang-ancang (startup), 1 sampai 2
## frame aktif, 2 sampai 3 pulih (recovery). Tampilan memetakan frame data ke waktu ini,
## jadi mengubah angka startup di data/attacks tidak perlu mengubah animasi.

const STAND := {
	"emak-emak": {
		"hip": [0, 0], "torso": 5, "pelvis": 0, "head": 0, "af": [40, 86], "ab": [-16, 22],
		"lf": [10, 4], "lb": [-10, -8], "prop": 176, "leg_front": 0, "arm_back": 0, "spin": 0, "lift": [0, 0],
	},
	"abang-ojol": {
		"hip": [0, 0], "torso": 8, "pelvis": 0, "head": -3, "af": [50, 132], "ab": [26, 118],
		"lf": [24, 0], "lb": [-18, -30], "prop": 20, "leg_front": 0, "arm_back": 0, "spin": 0, "lift": [0, 0],
	},
}


static func animations(character: String) -> Dictionary:
	var out := _common(character)
	if character == "emak-emak":
		out.merge(_emak(), true)
	else:
		out.merge(_ojol(), true)
	return out


## Geser dua sudut sebuah anggota badan.
static func _add(limb: Array, upper: float, lower: float) -> Array:
	return [limb[0] + upper, limb[1] + lower]


static func _common(c: String) -> Dictionary:
	var s: Dictionary = STAND[c]
	var af: Array = s["af"]
	var ab: Array = s["ab"]
	var lf: Array = s["lf"]
	var lb: Array = s["lb"]
	var emak := c == "emak-emak"
	# Abang Ojol memantul lebih lincah; Emak-Emak bergoyang berat.
	var k := 1.0 if emak else 1.7
	var sink := {"torso": s["torso"] + 2.0 * k, "head": s["head"] + 1.5 * k, "lf": _add(lf, 6 * k, -8 * k),
		"lb": _add(lb, 4 * k, -9 * k), "af": _add(af, 4 * k, -5 * k), "ab": _add(ab, 5 * k, -4 * k),
		"prop": s["prop"] - 3}
	var half := {"torso": s["torso"] + 1.0 * k, "lf": _add(lf, 3 * k, -4 * k), "lb": _add(lb, 2 * k, -5 * k),
		"af": _add(af, 2 * k, -2 * k), "ab": _add(ab, 2 * k, -2 * k), "prop": s["prop"] - 1}
	var rise := {"torso": s["torso"] - 1.0 * k, "head": s["head"] - 1.0, "af": _add(af, -2 * k, 3 * k),
		"ab": _add(ab, -3 * k, 2 * k), "prop": s["prop"] + 2}
	# Tergeletak setelah jatuh. Dipakai di akhir "ko" dan awal "getup".
	var lying := {"spin": -90, "lift": [46, -9], "torso": 0, "pelvis": 0, "head": 6, "af": [30, 44], "ab": [-16, 8],
		"lf": [16, 10], "lb": [-6, -10], "prop": 120 if emak else 40}
	return {
		"idle": {"length": 1.2, "loop": true, "keys": [
			[0.0, rise], [0.3, half], [0.6, sink], [0.9, half], [1.2, rise],
		]},
		# Jalan mundur memakai animasi ini diputar terbalik (keputusan 4).
		"walk": {"length": 0.64, "loop": true, "keys": [
			[0.0, {"torso": s["torso"] + 3, "lf": [32, 10], "lb": [-26, -36], "ab": _add(ab, 22, 14), "af": _add(af, -6, -4), "head": s["head"] - 2}],
			[0.16, {"torso": s["torso"] + 6, "lf": [10, -2], "lb": [10, -56], "ab": _add(ab, 2, 0), "af": _add(af, 0, 0)}],
			[0.32, {"torso": s["torso"] + 3, "lf": [-26, -36], "lb": [32, 10], "ab": _add(ab, -22, -12), "af": _add(af, 6, 4), "head": s["head"] - 2}],
			[0.48, {"torso": s["torso"] + 6, "lf": [10, -56], "lb": [10, -2], "ab": _add(ab, -2, 0), "af": _add(af, 0, 0)}],
			[0.64, {"torso": s["torso"] + 3, "lf": [32, 10], "lb": [-26, -36], "ab": _add(ab, 22, 14), "af": _add(af, -6, -4), "head": s["head"] - 2}],
		]},
		"jump": {"length": 0.66, "loop": false, "ground": false, "keys": [
			[0.0, {"torso": 18, "head": -8, "lf": [62, -30], "lb": [36, -66], "hip": [0, 12], "ab": _add(ab, -50, -30), "af": _add(af, -10, -10)}],
			[0.1, {"torso": -6, "head": 4, "lf": [4, 10], "lb": [-16, -24], "ab": _add(ab, 60, 40), "af": _add(af, 20, 20)}],
			[0.33, {"torso": 10, "lf": [84, -6], "lb": [52, -62], "ab": _add(ab, 30, 30), "af": _add(af, 10, 10), "leg_front": 1}],
			[0.56, {"torso": 0, "lf": [20, 8], "lb": [-12, -26], "ab": _add(ab, -30, -20)}],
			[0.66, {"torso": 14, "lf": [52, -22], "lb": [22, -56], "hip": [0, 8], "ab": _add(ab, -40, -20)}],
		]},
		"crouch": {"length": 0.1, "loop": false, "keys": [
			[0.0, {}],
			[0.1, {"torso": 26 if emak else 22, "head": -16 if emak else -12,
				"lf": [100, -6] if emak else [104, -22], "lb": [70, -66] if emak else [70, -76],
				"af": _add(af, 14, 10), "ab": _add(ab, 30, 30), "leg_front": 1}],
		]},
		"dash": {"length": 0.16, "loop": false, "keys": [
			[0.0, {"torso": 18, "lf": [44, 4], "lb": [-34, -56], "ab": _add(ab, -30, -20)}],
			[0.08, {"torso": 32, "head": -14, "hip": [4, 0], "lf": [70, 24], "lb": [-58, -78], "ab": _add(ab, -70, -50), "af": _add(af, 16, 0)}],
			[0.16, {"torso": 14, "lf": [34, -4], "lb": [-24, -40]}],
		]},
		"backdash": {"length": 0.16, "loop": false, "keys": [
			[0.0, {"torso": -8, "lf": [34, 20], "lb": [-10, -12]}],
			[0.08, {"torso": -20, "head": 10, "hip": [-4, 0], "lf": [58, 46], "lb": [-30, -18], "ab": _add(ab, 50, 30), "af": _add(af, 20, 10)}],
			[0.16, {"torso": -6, "lf": [28, 10], "lb": [-16, -18]}],
		]},
		"hit": {"length": 0.4, "loop": false, "keys": [
			[0.0, {"torso": -28, "pelvis": 6, "head": -24, "hip": [-5, 0], "af": [10, 30], "ab": [-76, -56],
				"lf": [40, 20], "lb": [4, -24], "prop": s["prop"] - 30}],
			[0.1, {"torso": -34, "pelvis": 8, "head": -14, "hip": [-7, 0], "af": [0, 10], "ab": [-90, -70],
				"lf": [36, 14], "lb": [0, -28], "prop": s["prop"] - 44}],
			[0.4, {"torso": -6, "hip": [-2, 0]}],
		]},
		# 0 sampai 0,3 terlempar, 0,4 ke atas tergeletak.
		"ko": {"length": 0.5, "loop": false, "ground": false, "keys": [
			[0.0, {"spin": -20, "lift": [0, -2], "torso": -20, "head": -26, "af": [80, 110], "ab": [-70, -40],
				"lf": [60, 30], "lb": [20, -20]}],
			[0.15, {"spin": -48, "lift": [6, -6], "torso": -10, "head": -18, "af": [120, 150], "ab": [-100, -70],
				"lf": [84, 40], "lb": [44, 0]}],
			[0.3, {"spin": -74, "lift": [14, -8], "torso": 8, "head": -6, "af": [100, 130], "ab": [-60, -30],
				"lf": [50, 20], "lb": [20, -10]}],
			[0.4, lying],
			[0.5, lying],
		]},
		# Bangun: dari tergeletak, duduk sambil menekuk lutut dan bertumpu tangan, jongkok, lalu
		# berdiri. Saat badan masih rebah (spin -90), arah anggota badan ikut terputar: 0 = ke
		# depan sejajar lantai, 90 = ke atas.
		"getup": {"length": 0.5, "loop": false, "ground": false, "keys": [
			[0.0, lying],
			[0.2, {"spin": -90, "lift": [40, -15 if emak else -9], "torso": 74, "pelvis": 16, "head": 8, "af": [-30, -6], "ab": [-112, -100],
				"lf": [44, -22], "lb": [30, -30], "prop": 96 if emak else 30}],
			[0.36, {"ground": true, "torso": 30 if emak else 26, "head": -14, "lf": [100, -6] if emak else [104, -22],
				"lb": [70, -66] if emak else [70, -76], "af": _add(af, 10, 6), "ab": [-30, 10], "leg_front": 1}],
			[0.5, {"ground": true}],
		]},
		"defeat": {"length": 0.5, "loop": false, "keys": [
			[0.0, {}],
			[0.5, {"torso": 34, "head": 26, "af": [14, 20], "ab": [-6, 4], "lf": [96, -30], "lb": [24, -92],
				"prop": 150 if emak else 0, "leg_front": 1}],
		]},
	}


static func _emak() -> Dictionary:
	var ride := {"hip": [-4, 9], "torso": 8, "pelvis": 0, "head": 0, "lf": [78, 10], "lb": [70, 6],
		"af": [72, 86], "ab": [64, 86], "prop": 198, "leg_front": 1}
	return {
		# Menahan dengan gagang sapu tegak di depan badan (GDD 6.4).
		"block": {"length": 0.1, "loop": false, "keys": [
			[0.0, {"torso": -4, "af": [56, 104], "prop": 180}],
			[0.1, {"torso": -12, "head": 10, "hip": [-3, 0], "af": [66, 118], "ab": [44, 112], "prop": 186,
				"lf": [24, 12], "lb": [-24, -20]}],
		]},
		"win": {"length": 0.8, "loop": true, "keys": [
			[0.0, {"torso": -6, "head": -6, "af": [156, 174], "prop": 182, "ab": [-50, -112]}],
			[0.4, {"torso": -10, "head": -10, "af": [164, 182], "prop": 176, "ab": [-56, -118], "lf": [26, -14], "lb": [-4, -30]}],
			[0.8, {"torso": -6, "head": -6, "af": [156, 174], "prop": 182, "ab": [-50, -112]}],
		]},
		# Colek sapu: melangkah maju dan menusuk lurus.
		"lp": {"length": 3.0, "loop": false, "keys": [
			[0.0, {}],
			[0.55, {"torso": -10, "head": 4, "hip": [-4, 0], "af": [0, 70], "prop": 118, "ab": [24, 74], "lf": [8, 6], "lb": [-10, -4]}],
			[1.0, {"torso": 24, "pelvis": 4, "head": -14, "hip": [10, 0], "af": [84, 88], "prop": 91, "ab": [-56, -34],
				"lf": [40, -12], "lb": [-38, -32]}],
			[2.0, {"torso": 26, "pelvis": 4, "head": -14, "hip": [11, 0], "af": [86, 90], "prop": 90, "ab": [-60, -38],
				"lf": [42, -14], "lb": [-40, -34]}],
			[2.5, {"torso": 10, "hip": [5, 0], "af": [58, 92], "prop": 126, "ab": [-20, 10]}],
			[3.0, {}],
		]},
		# Sabetan lebar: badan diputar ke belakang, lalu sapu menyapu dari atas ke bawah depan.
		"hp": {"length": 3.0, "loop": false, "keys": [
			[0.0, {}],
			[0.7, {"torso": -18, "pelvis": -4, "head": 10, "hip": [-6, 0], "af": [-44, 16], "prop": 252, "ab": [44, 104], "arm_back": 1,
				"lf": [6, 6], "lb": [-8, -2]}],
			[1.0, {"torso": 8, "head": -4, "hip": [6, 0], "af": [84, 100], "prop": 124, "ab": [-10, 30], "lf": [30, -8], "lb": [-30, -26]}],
			[1.5, {"torso": 22, "head": -12, "hip": [10, 0], "af": [74, 76], "prop": 84, "ab": [-44, -12], "lf": [38, -12], "lb": [-38, -32]}],
			[2.0, {"torso": 32, "pelvis": 6, "head": -18, "hip": [12, 0], "af": [58, 44], "prop": 44, "ab": [-66, -34],
				"lf": [44, -16], "lb": [-42, -36]}],
			[2.5, {"torso": 16, "hip": [6, 0], "af": [50, 72], "prop": 104, "ab": [-30, 0]}],
			[3.0, {}],
		]},
		# Tendang sandal: lutut diangkat, badan condong ke belakang, kaki lurus setinggi perut,
		# rok terangkat, lengan belakang mengayun sebagai penyeimbang.
		"lk": {"length": 3.0, "loop": false, "keys": [
			[0.0, {}],
			[0.5, {"torso": -12, "pelvis": -12, "head": 8, "hip": [-2, 0], "lf": [84, -14], "leg_front": 1, "lb": [-10, -6],
				"af": [54, 116], "ab": [-30, 10], "prop": 184}],
			[1.0, {"torso": -30, "pelvis": -24, "head": 18, "hip": [6, 0], "lf": [98, 96], "leg_front": 1, "lb": [-18, -8],
				"af": [60, 130], "ab": [-64, -30], "prop": 196}],
			[2.0, {"torso": -32, "pelvis": -26, "head": 18, "hip": [7, 0], "lf": [100, 98], "leg_front": 1, "lb": [-20, -10],
				"af": [62, 132], "ab": [-68, -34], "prop": 198}],
			[2.5, {"torso": -12, "pelvis": -10, "head": 8, "lf": [76, -16], "leg_front": 1, "ab": [-20, 10]}],
			[3.0, {}],
		]},
		# Gebuk sapu: berdiri tinggi dengan sapu di atas kepala, lalu seluruh badan menghantam ke bawah.
		"hk": {"length": 3.0, "loop": false, "keys": [
			[0.0, {}],
			[0.7, {"torso": -22, "pelvis": -6, "head": -10, "hip": [-4, 0], "af": [164, 178], "prop": 208, "ab": [86, 152],
				"lf": [8, 0], "lb": [-6, 0]}],
			[1.0, {"torso": 4, "head": -4, "hip": [4, 0], "af": [118, 108], "prop": 108, "ab": [64, 112], "lf": [28, -6], "lb": [-26, -22]}],
			[2.0, {"torso": 36, "pelvis": 8, "head": -22, "hip": [10, 0], "af": [76, 62], "prop": 62, "ab": [30, 60],
				"lf": [48, -22], "lb": [-42, -44]}],
			[2.5, {"torso": 20, "hip": [5, 0], "af": [56, 68], "prop": 92, "ab": [0, 40]}],
			[3.0, {}],
		]},
		# Lemparan menyamping dengan tangan belakang, badan ikut berputar.
		"skill": {"length": 3.0, "loop": false, "keys": [
			[0.0, {}],
			[0.6, {"torso": -16, "head": 8, "hip": [-4, 0], "ab": [-84, -44], "af": [50, 100], "lf": [8, 6], "lb": [-8, -2]}],
			[1.0, {"torso": 22, "pelvis": 4, "head": -12, "hip": [8, 0], "ab": [88, 100], "lf": [36, -10], "lb": [-32, -30]}],
			[2.0, {"torso": 18, "head": -8, "hip": [6, 0], "ab": [70, 56], "lf": [30, -8], "lb": [-28, -26]}],
			[3.0, {}],
		]},
		# Duduk di motor matic. Motornya digambar oleh tampilan.
		"ultimate": {"length": 3.0, "loop": false, "ground": false, "keys": [
			[0.0, ride],
			[2.0, ride],
			[2.4, {"torso": 12, "lf": [44, -4], "lb": [10, -34]}],
			[3.0, {}],
		]},
	}


static func _ojol() -> Dictionary:
	var ride := {"hip": [-4, 9], "torso": 16, "pelvis": 0, "head": -6, "lf": [80, 10], "lb": [72, 6],
		"af": [76, 88], "ab": [70, 88], "prop": 60, "leg_front": 1}
	var punch := ride.duplicate()
	punch["af"] = [98, 94]
	punch["torso"] = 24
	var pull := ride.duplicate()
	pull["af"] = [46, 130]
	pull["torso"] = 10
	return {
		"block": {"length": 0.1, "loop": false, "keys": [
			[0.0, {"af": [62, 144], "ab": [46, 134]}],
			[0.1, {"torso": -8, "head": 12, "hip": [-3, 0], "af": [76, 160], "ab": [66, 154], "prop": 0, "lf": [30, 8], "lb": [-24, -32]}],
		]},
		"win": {"length": 0.8, "loop": true, "keys": [
			[0.0, {"torso": -6, "head": -8, "af": [162, 178], "prop": 150, "ab": [-24, -64]}],
			[0.4, {"torso": -10, "head": -12, "af": [170, 188], "prop": 164, "ab": [-30, -70], "lf": [30, -16], "lb": [-8, -40]}],
			[0.8, {"torso": -6, "head": -8, "af": [162, 178], "prop": 150, "ab": [-24, -64]}],
		]},
		# Jab helm: bahu didorong, kaki depan melangkah.
		"lp": {"length": 3.0, "loop": false, "keys": [
			[0.0, {}],
			[0.5, {"torso": 0, "head": 2, "hip": [-2, 0], "af": [16, 126], "ab": [34, 126]}],
			[1.0, {"torso": 20, "pelvis": 4, "head": -12, "hip": [8, 0], "af": [90, 92], "prop": 84, "ab": [-10, 100],
				"lf": [40, -10], "lb": [-34, -40]}],
			[2.0, {"torso": 22, "pelvis": 4, "head": -12, "hip": [9, 0], "af": [92, 94], "prop": 84, "ab": [-14, 96],
				"lf": [42, -12], "lb": [-36, -42]}],
			[3.0, {}],
		]},
		# Hantam helm: helm diangkat tinggi di belakang kepala lalu dihantamkan dengan seluruh badan.
		"hp": {"length": 3.0, "loop": false, "keys": [
			[0.0, {}],
			[0.7, {"torso": -16, "pelvis": -4, "head": 8, "hip": [-4, 0], "af": [152, 196], "prop": 204, "ab": [56, 116],
				"lf": [16, 6], "lb": [-12, -16]}],
			[1.0, {"torso": 12, "head": -6, "hip": [8, 0], "af": [116, 90], "prop": 100, "ab": [0, 70], "lf": [36, -8], "lb": [-32, -38]}],
			[2.0, {"torso": 36, "pelvis": 8, "head": -22, "hip": [13, 0], "af": [54, 32], "prop": 26, "ab": [-50, 20],
				"lf": [48, -18], "lb": [-42, -50]}],
			[2.5, {"torso": 16, "hip": [6, 0], "af": [50, 90], "prop": 40}],
			[3.0, {}],
		]},
		# Tendangan cepat setinggi perut: lutut diangkat dulu, lalu kaki dilecutkan.
		"lk": {"length": 3.0, "loop": false, "keys": [
			[0.0, {}],
			[0.5, {"torso": -10, "pelvis": -6, "head": 8, "lf": [88, -24], "leg_front": 1, "ab": [-10, 80], "af": [56, 146]}],
			[1.0, {"torso": -26, "pelvis": -12, "head": 16, "hip": [5, 0], "lf": [94, 92], "leg_front": 1, "lb": [-14, -8],
				"af": [64, 154], "ab": [-56, -14]}],
			[2.0, {"torso": -28, "pelvis": -12, "head": 16, "hip": [6, 0], "lf": [96, 94], "leg_front": 1, "lb": [-16, -10],
				"af": [66, 156], "ab": [-60, -18]}],
			[2.5, {"torso": -10, "head": 6, "lf": [80, -20], "leg_front": 1}],
			[3.0, {}],
		]},
		# Tendangan putar tinggi: badan rebah jauh ke belakang, kaki naik setinggi kepala lawan.
		"hk": {"length": 3.0, "loop": false, "keys": [
			[0.0, {}],
			[0.7, {"torso": -16, "pelvis": -8, "head": 10, "hip": [2, 0], "lf": [106, -6], "leg_front": 1, "af": [30, 100],
				"ab": [64, 134], "lb": [-10, -8]}],
			[1.0, {"torso": -44, "pelvis": -20, "head": 26, "hip": [7, 0], "lf": [132, 128], "leg_front": 1, "lb": [-12, -4],
				"af": [-26, 14], "ab": [76, 112]}],
			[2.0, {"torso": -46, "pelvis": -20, "head": 26, "hip": [8, 0], "lf": [134, 132], "leg_front": 1, "lb": [-14, -6],
				"af": [-30, 10], "ab": [80, 116]}],
			[2.5, {"torso": -16, "head": 8, "lf": [92, -12], "leg_front": 1, "af": [20, 90]}],
			[3.0, {}],
		]},
		# Cancel Order: merunduk rendah lalu menghilang.
		"skill": {"length": 3.0, "loop": false, "keys": [
			[0.0, {"torso": 18}],
			[0.5, {"torso": 36, "head": -14, "lf": [92, -20], "lb": [-38, -80], "af": [-40, 6], "ab": [-56, -10], "leg_front": 1}],
			[2.0, {"torso": 36, "head": -14, "lf": [92, -20], "lb": [-38, -80], "af": [-40, 6], "ab": [-56, -10], "leg_front": 1}],
			[3.0, {}],
		]},
		# Naik motor bebek lalu pukulan beruntun dengan helm.
		"ultimate": {"length": 3.0, "loop": false, "ground": false, "keys": [
			[0.0, ride],
			[1.0, punch], [1.125, pull], [1.25, punch], [1.375, pull], [1.5, punch],
			[1.625, pull], [1.75, punch], [1.875, pull], [2.0, punch],
			[2.4, {"torso": 12, "lf": [44, -4], "lb": [6, -44]}],
			[3.0, {}],
		]},
	}
