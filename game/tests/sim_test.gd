extends SceneTree
## Uji simulasi kombat tanpa jendela.
## Jalankan: godot --headless --path game -s res://tests/sim_test.gd

const FightSim := preload("res://scripts/sim/fight_sim.gd")
const FighterState := preload("res://scripts/sim/fighter_state.gd")
const St := FighterState.St
const FP := FightSim.FP

const EMAK := "res://data/fighters/emak_emak.tres"
const OJOL := "res://data/fighters/abang_ojol.tres"

var checks := 0
var failures := 0


func _init() -> void:
	_test_frame_data()
	_test_hitstop_and_hitstun()
	_test_block_and_whiff()
	_test_input_buffer()
	_test_combo_scaling()
	_test_knockdown()
	_test_movement()
	_test_skill_projectile()
	_test_skill_teleport()
	_test_ultimate_unblockable()
	_test_ultimate_multi_hit()
	_test_round_flow()
	_test_time_up()
	_test_training()
	_test_effects()
	_test_determinism()
	_test_input_map()
	_print_frame_table()
	print("\n%d pemeriksaan, %d gagal" % [checks, failures])
	quit(1 if failures > 0 else 0)


# --- Alat bantu --------------------------------------------------------------

func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("  GAGAL: " + label)


func eq(got, want, label: String) -> void:
	check(got == want, "%s (dapat %s, harusnya %s)" % [label, str(got), str(want)])


## Simulasi baru yang sudah melewati intro, dengan jarak antar petarung `dist` piksel.
func new_sim(p1: String, p2: String, dist: int = 60) -> FightSim:
	var sim := FightSim.new()
	sim.setup(load("res://data/rules/match_rules.tres"), load("res://data/stages/gang.tres"),
			[load(p1), load(p2)])
	while sim.phase == FightSim.Phase.INTRO:
		sim.tick([0, 0])
	sim.fighters[0].x = 400 * FP
	sim.fighters[1].x = (400 + dist) * FP
	return sim


func step(sim: FightSim, n: int, in0: int = 0, in1: int = 0) -> Array:
	var seen: Array = []
	for i in n:
		sim.tick([in0, in1])
		seen.append_array(sim.events)
	return seen


## Tekan tombol satu frame lalu lepas.
func tap(sim: FightSim, in0: int, in1: int = 0) -> Array:
	return step(sim, 1, in0, in1)


# --- Uji ---------------------------------------------------------------------

func _test_frame_data() -> void:
	print("Frame data: startup tepat")
	var sim := new_sim(EMAK, OJOL)
	var vic: FighterState = sim.fighters[1]
	var lp: AttackData = sim.fighters[0].data.light_punch
	tap(sim, FightSim.IN_LP)
	step(sim, lp.startup)
	eq(vic.health, vic.data.max_health, "belum kena selama %d frame startup" % lp.startup)
	step(sim, 1)
	eq(vic.health, vic.data.max_health - lp.damage, "kena di frame ke-%d" % (lp.startup + 1))
	eq(vic.st, St.HITSTUN, "lawan masuk hitstun")


func _test_hitstop_and_hitstun() -> void:
	print("Hitstop hitungan frame dan lama hitstun")
	var sim := new_sim(EMAK, OJOL)
	var att: FighterState = sim.fighters[0]
	var vic: FighterState = sim.fighters[1]
	var lp: AttackData = att.data.light_punch
	tap(sim, FightSim.IN_LP)
	step(sim, lp.startup + 1)
	eq(sim.hitstop, lp.hitstop, "hitstop diisi dari data")
	var frame_before := att.st_frame
	var x_before := vic.x
	step(sim, lp.hitstop)
	eq(att.st_frame, frame_before, "penyerang berhenti selama hitstop")
	eq(vic.x, x_before, "lawan berhenti selama hitstop")
	eq(Engine.time_scale, 1.0, "time_scale tidak disentuh")
	step(sim, 1)
	eq(att.st_frame, frame_before + 1, "jalan lagi setelah hitstop")
	# Frame di atas sudah memakai 1 frame hitstun.
	step(sim, lp.hitstun - 2)
	eq(vic.st, St.HITSTUN, "masih hitstun 1 frame sebelum habis")
	step(sim, 1)
	eq(vic.st, St.IDLE, "pulih tepat setelah %d frame hitstun" % lp.hitstun)


func _test_block_and_whiff() -> void:
	print("Block dan meleset")
	var sim := new_sim(EMAK, OJOL)
	var vic: FighterState = sim.fighters[1]
	var lp: AttackData = sim.fighters[0].data.light_punch
	tap(sim, FightSim.IN_LP, FightSim.IN_BLOCK)
	var ev := step(sim, lp.startup + 1, 0, FightSim.IN_BLOCK)
	eq(vic.health, vic.data.max_health - lp.chip_damage, "block hanya kena chip damage")
	eq(vic.st, St.BLOCKSTUN, "lawan masuk blockstun")
	check(ev.has(&"block"), "kejadian block untuk suara")
	eq(sim.hitstop, lp.blockstop, "blockstop dari data")

	sim = new_sim(EMAK, OJOL, 200)
	vic = sim.fighters[1]
	tap(sim, FightSim.IN_LP)
	ev = step(sim, 40)
	eq(vic.health, vic.data.max_health, "meleset di jarak 200")
	check(ev.has(&"whoosh"), "kejadian whoosh saat ayunan meleset")


func _test_input_buffer() -> void:
	print("Input buffer")
	var sim := new_sim(EMAK, OJOL, 200)
	var lp: AttackData = sim.fighters[0].data.light_punch
	var total := lp.total_frames()
	var buf: int = sim.rules.input_buffer_frames
	# Tombol kedua ditekan 5 frame sebelum serangan pertama selesai: harus tetap keluar.
	tap(sim, FightSim.IN_LP)
	var ev := step(sim, total - 6)
	ev.append_array(tap(sim, FightSim.IN_LP))
	ev.append_array(step(sim, 40))
	eq(ev.count(&"whoosh"), 2, "tekan 5 frame lebih awal tetap keluar")
	# Ditekan jauh lebih awal dari jendela buffer: tidak keluar.
	sim = new_sim(EMAK, OJOL, 200)
	tap(sim, FightSim.IN_LP)
	ev = step(sim, total - buf - 6)
	ev.append_array(tap(sim, FightSim.IN_LP))
	ev.append_array(step(sim, 40))
	eq(ev.count(&"whoosh"), 1, "tekan di luar buffer %d frame tidak keluar" % buf)


func _test_combo_scaling() -> void:
	print("Kombo, cancel, dan skala damage")
	var sim := new_sim(OJOL, EMAK, 40)
	var att: FighterState = sim.fighters[0]
	var vic: FighterState = sim.fighters[1]
	var lp: AttackData = att.data.light_punch
	var lk: AttackData = att.data.light_kick
	tap(sim, FightSim.IN_LP)
	step(sim, lp.startup + 1)
	eq(vic.combo, 1, "pukulan pertama")
	# Tekan LK selama hitstop: harus masuk buffer lalu cancel.
	tap(sim, FightSim.IN_LK)
	step(sim, lp.hitstop + lk.startup + 2)
	eq(vic.combo, 2, "LP cancel ke LK jadi kombo 2")
	var want: int = vic.data.max_health - lp.damage - lk.damage * 90 / 100
	eq(vic.health, want, "pukulan kedua kena skala 90%")
	eq(sim.combo_show[0], 2, "hitungan kombo untuk HUD")
	# Hitstop lebih lama dari buffer: tombol di frame pertama hitstop tetap cancel.
	sim = new_sim(OJOL, EMAK, 40)
	vic = sim.fighters[1]
	tap(sim, FightSim.IN_LP)
	step(sim, lp.startup + 1)
	var long_stop: int = sim.rules.input_buffer_frames + 6
	sim.hitstop = long_stop
	tap(sim, FightSim.IN_LK)
	step(sim, long_stop + lk.startup + 2)
	eq(vic.combo, 2, "cancel tetap keluar setelah hitstop %d frame" % long_stop)
	# Tanpa kena, cancel tidak boleh terjadi.
	sim = new_sim(OJOL, EMAK, 200)
	tap(sim, FightSim.IN_LP)
	step(sim, lp.startup + 1)
	tap(sim, FightSim.IN_LK)
	eq(sim.fighters[0].attack_id, &"lp", "tanpa kena tidak bisa cancel")


func _test_knockdown() -> void:
	print("Knockdown dan bangun")
	var sim := new_sim(OJOL, EMAK, 50)
	var vic: FighterState = sim.fighters[1]
	var hk: AttackData = sim.fighters[0].data.heavy_kick
	tap(sim, FightSim.IN_HK)
	step(sim, hk.startup + 1)
	eq(vic.st, St.KNOCKDOWN, "HK menjatuhkan")
	check(sim.is_invulnerable(vic), "kebal saat jatuh")
	var seen_down := false
	var frames := 0
	while vic.st != St.IDLE and frames < 300:
		step(sim, 1)
		frames += 1
		if vic.st == St.DOWN:
			seen_down = true
	check(seen_down, "sempat tergeletak")
	eq(vic.st, St.IDLE, "bangun lagi")
	eq(vic.y, 0, "kembali di lantai")
	print("  jatuh sampai bangun: %d frame" % frames)


func _test_movement() -> void:
	print("Gerak: jalan, dash, lompat, jongkok")
	var sim := new_sim(EMAK, OJOL, 200)
	var p: FighterState = sim.fighters[0]
	var x0 := p.x
	step(sim, 30, FightSim.IN_RIGHT)
	eq(p.x - x0, 30 * p.data.walk_forward_speed, "jalan maju 30 frame")
	eq(p.st, St.WALK_F, "state jalan maju")
	x0 = p.x
	step(sim, 30, FightSim.IN_LEFT)
	eq(x0 - p.x, 30 * p.data.walk_backward_speed, "jalan mundur 30 frame")
	eq(p.st, St.WALK_B, "state jalan mundur (animasi Walk Forward diputar terbalik)")
	step(sim, 3)
	tap(sim, FightSim.IN_RIGHT)
	step(sim, 2)
	tap(sim, FightSim.IN_RIGHT)
	step(sim, 1)
	eq(p.st, St.DASH_F, "ketuk arah dua kali jadi dash")
	step(sim, 30)
	tap(sim, FightSim.IN_UP)
	step(sim, 5)
	eq(p.st, St.JUMP, "lompat")
	check(p.y < 0, "di udara")
	var peak := 0
	var air := 5
	while p.st == St.JUMP and air < 200:
		peak = min(peak, p.y)
		step(sim, 1)
		air += 1
	print("  lompat Emak-Emak: tinggi %d px, %d frame di udara" % [-peak / FP, air])
	step(sim, 2, FightSim.IN_DOWN)
	eq(p.st, St.CROUCH, "jongkok")
	check(sim.hurtbox_rect(p).size.y < p.data.stand_hurtbox.size.y, "hurtbox mengecil saat jongkok")


func _test_skill_projectile() -> void:
	print("Skill Emak-Emak: bumerang dan cooldown")
	var sim := new_sim(EMAK, OJOL, 120)
	var att: FighterState = sim.fighters[0]
	var vic: FighterState = sim.fighters[1]
	var sk: AttackData = att.data.skill
	tap(sim, FightSim.IN_SKILL)
	step(sim, sk.startup + 1)
	eq(sim.projectiles.size(), 1, "proyektil dilepas di frame aktif pertama")
	eq(att.skill_cd > 0, true, "cooldown berjalan")
	step(sim, 60)
	eq(vic.health, vic.data.max_health - sk.damage, "proyektil kena satu kali")
	tap(sim, FightSim.IN_SKILL)
	step(sim, 2)
	check(att.attack_id != &"skill", "tidak bisa dipakai selama cooldown")
	step(sim, 200)
	eq(sim.projectiles.size(), 0, "bumerang kembali dan hilang")
	eq(vic.health, vic.data.max_health - sk.damage, "tidak kena dua kali")
	eq(att.skill_cd, 0, "cooldown habis")
	# Lawan menghindar dengan jongkok, lalu kena saat bumerang kembali (GDD 6.4).
	sim = new_sim(EMAK, OJOL, 120)
	vic = sim.fighters[1]
	tap(sim, FightSim.IN_SKILL, FightSim.IN_DOWN)
	var dodged := false
	var hit_on_return := false
	for i in 200:
		var returning: bool = not sim.projectiles.is_empty() and sim.projectiles[0]["returning"]
		if returning and vic.health == vic.data.max_health:
			dodged = true
		# Jongkok saat bumerang berangkat, berdiri saat ia kembali.
		step(sim, 1, 0, 0 if returning else FightSim.IN_DOWN)
		if dodged and vic.health < vic.data.max_health:
			hit_on_return = true
	check(dodged, "jongkok menghindari bumerang yang berangkat")
	check(hit_on_return, "berdiri terlalu cepat kena saat bumerang kembali")


func _test_skill_teleport() -> void:
	print("Skill Abang Ojol: teleport dan kebal")
	var sim := new_sim(OJOL, EMAK, 50)
	var att: FighterState = sim.fighters[0]
	var vic: FighterState = sim.fighters[1]
	var sk: AttackData = att.data.skill
	var x0 := att.x
	tap(sim, FightSim.IN_SKILL)
	step(sim, sk.teleport_frame)
	# Bila mendarat menempel lawan, ia terdorong sedikit lebih jauh oleh lebar badan.
	var moved: int = att.x - x0
	check(moved >= sk.teleport_distance * FP and moved <= (sk.teleport_distance + 12) * FP,
			"pindah sekitar %d px ke depan (dapat %d)" % [sk.teleport_distance, moved / FP])
	check(att.x > vic.x, "muncul di belakang lawan")
	eq(att.facing, -1, "langsung menghadap lawan")
	check(sim.is_invulnerable(att), "kebal selama teleport")
	check(sim.effects.any(func(e): return e["kind"] == &"afterimage"), "bayangan digital tertinggal")
	# Teleport menembus serangan: Emak memukul, Ojol teleport saat hitbox aktif.
	sim = new_sim(OJOL, EMAK, 60)
	att = sim.fighters[0]
	var lp: AttackData = sim.fighters[1].data.light_punch
	tap(sim, 0, FightSim.IN_LP)
	step(sim, lp.startup - 1)
	tap(sim, FightSim.IN_SKILL)
	step(sim, 12)
	eq(att.health, att.data.max_health, "menghindari pukulan dengan teleport")


func _test_ultimate_unblockable() -> void:
	print("Ultimate Emak-Emak: energi, cinematic, peringatan, unblockable")
	var sim := new_sim(EMAK, OJOL, 130)
	var att: FighterState = sim.fighters[0]
	var vic: FighterState = sim.fighters[1]
	var ult: AttackData = att.data.ultimate
	tap(sim, FightSim.IN_ULT)
	step(sim, 2)
	check(att.attack_id != &"ultimate", "tidak bisa tanpa energi penuh")
	att.energy = sim.rules.energy_max
	var ev := tap(sim, FightSim.IN_ULT, FightSim.IN_BLOCK)
	check(ev.has(&"ultimate"), "ultimate dimulai")
	eq(att.energy, 0, "energi habis")
	eq(sim.cinematic, ult.cinematic_frames, "cinematic dari data")
	var timer_before := sim.timer_ticks
	step(sim, ult.cinematic_frames, 0, FightSim.IN_BLOCK)
	eq(sim.timer_ticks, timer_before, "timer berhenti selama cinematic")
	step(sim, 1, 0, FightSim.IN_BLOCK)
	check(sim.is_warning(att), "jeda peringatan aktif")
	step(sim, ult.startup - 2, 0, FightSim.IN_BLOCK)
	check(sim.is_warning(att), "peringatan sampai akhir startup (%d frame)" % ult.startup)
	eq(vic.health, vic.data.max_health, "belum kena selama peringatan")
	step(sim, ult.active + 5, 0, FightSim.IN_BLOCK)
	eq(vic.health, vic.data.max_health - ult.damage, "block tidak menahan unblockable")
	# Harus bisa dihindari dengan lompat (GDD 11.1).
	var dodge_windows := 0
	for delay in range(0, ult.startup + ult.active, 2):
		sim = new_sim(EMAK, OJOL, 130)
		sim.fighters[0].energy = sim.rules.energy_max
		tap(sim, FightSim.IN_ULT)
		step(sim, ult.cinematic_frames + delay)
		tap(sim, 0, FightSim.IN_UP | FightSim.IN_LEFT)
		step(sim, ult.total_frames())
		if sim.fighters[1].health == sim.fighters[1].data.max_health:
			dodge_windows += 1
	check(dodge_windows > 0, "bisa dihindari dengan lompat")
	print("  lompat menghindar berhasil di %d dari %d waktu yang dicoba" % [
			dodge_windows, (ult.startup + ult.active + 1) / 2])


func _test_ultimate_multi_hit() -> void:
	print("Ultimate Abang Ojol: pukulan beruntun")
	var sim := new_sim(OJOL, EMAK, 70)
	var att: FighterState = sim.fighters[0]
	var vic: FighterState = sim.fighters[1]
	var ult: AttackData = att.data.ultimate
	att.energy = sim.rules.energy_max
	tap(sim, FightSim.IN_ULT)
	var ev := step(sim, ult.cinematic_frames + ult.total_frames() + ult.hit_count * ult.hitstop + 10)
	eq(ev.count(&"hit_heavy"), ult.hit_count, "kena %d kali" % ult.hit_count)
	var dealt: int = vic.data.max_health - vic.health
	print("  total damage %d dari %d pukulan" % [dealt, ult.hit_count])
	check(dealt > ult.damage * 3, "damage beruntun masuk")
	check(vic.st == St.KNOCKDOWN or vic.st == St.DOWN or vic.st == St.GETUP, "pukulan terakhir menjatuhkan")
	eq(att.energy, 0, "ultimate tidak mengisi energi sendiri")
	# Bisa ditahan.
	sim = new_sim(OJOL, EMAK, 70)
	sim.fighters[0].energy = sim.rules.energy_max
	tap(sim, FightSim.IN_ULT, FightSim.IN_BLOCK)
	step(sim, ult.cinematic_frames + ult.total_frames() + 40, 0, FightSim.IN_BLOCK)
	var chip: int = sim.fighters[1].data.max_health - sim.fighters[1].health
	check(chip <= ult.chip_damage * ult.hit_count, "ultimate Ojol bisa ditahan (chip %d)" % chip)


func _test_round_flow() -> void:
	print("Ronde: K.O., best of 3")
	var sim := new_sim(EMAK, OJOL)
	var lp: AttackData = sim.fighters[0].data.light_punch
	sim.fighters[1].health = 10
	tap(sim, FightSim.IN_LP)
	var ev := step(sim, lp.startup + 1)
	check(ev.has(&"ko"), "kejadian K.O.")
	eq(sim.phase, FightSim.Phase.ROUND_END, "ronde berakhir")
	eq(sim.round_winner, 0, "P1 menang ronde")
	eq(sim.round_result, &"perfect", "tanpa kena damage dihitung PERFECT")
	eq(sim.wins, [1, 0], "titik ronde P1 menyala")
	eq(sim.hitstop, lp.hitstop + sim.rules.ko_hitstop, "hitstop K.O. lebih lama")
	step(sim, 100)
	eq(sim.fighters[1].st, St.KO, "yang kalah tergeletak")
	eq(sim.fighters[0].st, St.WIN, "pemenang berpose")
	step(sim, sim.rules.round_end_frames)
	eq(sim.phase, FightSim.Phase.INTRO, "lanjut ronde berikutnya")
	eq(sim.round_no, 2, "ronde 2")
	eq(sim.fighters[1].health, sim.fighters[1].data.max_health, "health penuh lagi")
	while sim.phase == FightSim.Phase.INTRO:
		sim.tick([0, 0])
	sim.fighters[0].x = 400 * FP
	sim.fighters[1].x = 460 * FP
	sim.fighters[1].health = 10
	tap(sim, FightSim.IN_LP)
	step(sim, lp.startup + 1 + sim.rules.round_end_frames + lp.hitstop + sim.rules.ko_hitstop + 5)
	eq(sim.phase, FightSim.Phase.MATCH_END, "menang 2 ronde mengakhiri pertandingan")
	eq(sim.match_winner, 0, "P1 pemenang pertandingan")
	step(sim, 200, FightSim.IN_LP)
	eq(sim.phase, FightSim.Phase.MATCH_END, "menunggu menu hasil, tidak mulai sendiri")
	sim.reset_match()
	eq(sim.phase, FightSim.Phase.INTRO, "reset_match memulai ulang")
	eq(sim.wins, [0, 0], "skor kembali nol")


func _test_time_up() -> void:
	print("Waktu habis")
	var sim := new_sim(EMAK, OJOL, 200)
	eq(sim.seconds_left(), 99, "timer mulai dari 99")
	sim.fighters[0].health = 500
	sim.timer_ticks = 2
	var ev := step(sim, 2)
	check(ev.has(&"time_up"), "kejadian TIME UP")
	eq(sim.round_winner, 1, "sisa health lebih banyak menang")
	eq(sim.round_result, &"time", "hasil ronde: waktu habis")
	step(sim, 60)
	eq(sim.fighters[0].st, St.DEFEAT, "yang kalah berpose kalah")
	eq(sim.fighters[1].st, St.WIN, "pemenang berpose")
	# Seri: ronde diulang tanpa titik.
	sim = new_sim(EMAK, OJOL, 200)
	sim.fighters[0].health = 500
	sim.fighters[1].health = 500
	sim.timer_ticks = 1
	step(sim, 1)
	eq(sim.round_winner, -1, "health sama berarti seri")
	step(sim, sim.rules.round_end_frames + 1)
	eq(sim.wins, [0, 0], "seri tidak memberi titik")
	eq(sim.round_no, 1, "ronde diulang")


func _test_training() -> void:
	print("Mode latihan")
	var sim := new_sim(EMAK, OJOL)
	sim.training = true
	var att: FighterState = sim.fighters[0]
	var vic: FighterState = sim.fighters[1]
	var lp: AttackData = att.data.light_punch
	var timer_before := sim.timer_ticks
	vic.health = 10
	vic.hurt_tick = sim.tick_count
	tap(sim, FightSim.IN_LP)
	step(sim, lp.startup + 1)
	eq(vic.health, 1, "tidak bisa K.O. di latihan")
	eq(sim.phase, FightSim.Phase.FIGHT, "ronde tidak berakhir")
	step(sim, 120)
	eq(vic.health, vic.data.max_health, "health terisi lagi setelah kombo berakhir")
	eq(att.energy, sim.rules.energy_max, "energi selalu penuh")
	eq(sim.timer_ticks, timer_before, "timer berhenti")
	tap(sim, FightSim.IN_ULT)
	step(sim, 2)
	eq(att.attack_id, &"ultimate", "ultimate bisa dicoba kapan saja")


func _test_effects() -> void:
	print("Efek: impact, retak layar, bintang 5")
	var kinds := func(sim: FightSim) -> Array:
		return sim.effects.map(func(e): return e["kind"])
	var sim := new_sim(OJOL, EMAK, 40)
	tap(sim, FightSim.IN_LP)
	step(sim, sim.fighters[0].data.light_punch.startup + 1)
	check(not kinds.call(sim).has(&"impact"), "pukulan ringan tanpa impact flash")
	sim = new_sim(OJOL, EMAK, 40)
	tap(sim, FightSim.IN_HP)
	step(sim, sim.fighters[0].data.heavy_punch.startup + 1)
	check(kinds.call(sim).has(&"impact"), "pukulan berat memicu impact flash")
	sim = new_sim(OJOL, EMAK, 70)
	var ult: AttackData = sim.fighters[0].data.ultimate
	sim.fighters[0].energy = sim.rules.energy_max
	tap(sim, FightSim.IN_ULT)
	var seen: Array = []
	for i in ult.cinematic_frames + ult.total_frames() + 40:
		step(sim, 1)
		for k in kinds.call(sim):
			if not seen.has(k):
				seen.append(k)
	check(seen.has(&"crack"), "ultimate yang kena meretakkan layar")
	check(seen.has(&"star5"), "ultimate Ojol ditutup notifikasi Bintang 5")
	check(ult.vehicle, "ultimate Ojol memakai motor")


func _random_inputs(count: int, rng_seed: int) -> Array:
	var out: Array = []
	var s := rng_seed
	var cur := [0, 0]
	for i in count:
		for p in 2:
			s = (s * 1103515245 + 12345) & 0x7fffffff
			if (s >> 16) % 5 == 0:
				s = (s * 1103515245 + 12345) & 0x7fffffff
				var bits := (s >> 8) & 0x7ff
				# Kurangi block dan ultimate supaya pertarungan tetap ramai.
				if (s >> 20) % 3 != 0:
					bits &= ~FightSim.IN_BLOCK
				cur[p] = bits
		out.append(cur.duplicate())
	return out


func _test_determinism() -> void:
	print("Determinisme dan snapshot")
	var inputs := _random_inputs(6000, 20261110)
	var a := FightSim.new()
	var b := FightSim.new()
	for sim in [a, b]:
		sim.setup(load("res://data/rules/match_rules.tres"), load("res://data/stages/gang.tres"),
				[load(EMAK), load(OJOL)])
	var snapshot: Dictionary = {}
	var hits := 0
	for i in inputs.size():
		a.tick(inputs[i])
		hits += a.events.count(&"hit_light") + a.events.count(&"hit_heavy")
		if i == 1999:
			snapshot = a.save_state()
	for i in inputs.size():
		b.tick(inputs[i])
	eq(a.state_hash(), b.state_hash(), "dua simulasi dengan input sama berakhir sama")
	check(hits > 20, "input acak menghasilkan pertarungan nyata (%d pukulan)" % hits)
	# Rollback: pulihkan snapshot tick 2000 lalu ulangi sisanya.
	var final_hash := a.state_hash()
	a.load_state(snapshot)
	eq(a.tick_count, 2000, "snapshot memulihkan tick")
	for i in range(2000, inputs.size()):
		a.tick(inputs[i])
	eq(a.state_hash(), final_hash, "ulang dari snapshot menghasilkan keadaan yang sama")
	print("  6000 tick, %d pukulan, ronde %d, skor %s" % [hits, a.round_no, str(a.wins)])


func _test_input_map() -> void:
	print("Input map")
	var want := {
		"p1_left": KEY_A, "p1_right": KEY_D, "p1_up": KEY_W, "p1_down": KEY_S,
		"p1_lp": KEY_J, "p1_hp": KEY_K, "p1_lk": KEY_U, "p1_hk": KEY_I,
		"p1_block": KEY_L, "p1_skill": KEY_O, "p1_ultimate": KEY_P,
		"p2_left": KEY_LEFT, "p2_right": KEY_RIGHT, "p2_up": KEY_UP, "p2_down": KEY_DOWN,
		"p2_lp": KEY_KP_1, "p2_hp": KEY_KP_2, "p2_lk": KEY_KP_4, "p2_hk": KEY_KP_5,
		"p2_block": KEY_KP_3, "p2_skill": KEY_KP_6, "p2_ultimate": KEY_KP_0,
	}
	for action in want:
		var ok := false
		if InputMap.has_action(action):
			for ev in InputMap.action_get_events(action):
				if ev is InputEventKey and ev.physical_keycode == want[action]:
					ok = true
		check(ok, "aksi %s terpasang ke tombol yang benar" % action)
	# Pembaca input menghasilkan bit yang sama dengan urutan tombol simulasi.
	Input.action_press("p1_hk")
	Input.action_press("p2_block")
	var reader := preload("res://scripts/input_reader.gd")
	eq(reader.read(0), FightSim.IN_HK, "p1_hk terbaca sebagai bit HK")
	eq(reader.read(1), FightSim.IN_BLOCK, "p2_block terbaca sebagai bit block")
	Input.action_release("p1_hk")
	Input.action_release("p2_block")


func _print_frame_table() -> void:
	print("\nFrame data (S/A/R = startup/active/recovery, selisih + berarti penyerang untung)")
	for path in [EMAK, OJOL]:
		var d: FighterData = load(path)
		print("  %s  health %d" % [d.display_name, d.max_health])
		for slot in [&"lp", &"lk", &"hp", &"hk", &"skill", &"ultimate"]:
			var a := d.get_attack(slot)
			var reach := a.hitbox.end.x if a.has_hitbox() else 0
			print("    %-9s %-22s S%2d A%2d R%2d  dmg %3d x%d  kena %+3d  tahan %+3d  jangkauan %3d px%s" % [
					slot, a.display_name, a.startup, a.active, a.recovery, a.damage, a.hit_count,
					a.advantage_on_hit(), a.advantage_on_block(), reach,
					("  cooldown %d" % a.cooldown) if a.cooldown > 0 else ""])
