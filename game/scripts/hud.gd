extends Control
## HUD yang digambar dengan kode (docs/decisions.md no. 10 dan 16).
## Tata letak tiap pemain, dari atas: health bar, bar ultimate, lalu ikon, nama, dan
## status skill. Timer dan titik ronde di tengah atas, teks besar di tengah layar.

const FightSim := preload("res://scripts/sim/fight_sim.gd")
const FighterState := preload("res://scripts/sim/fighter_state.gd")
const UiFont := preload("res://scripts/ui_font.gd")

const C_FRAME := Color("14151c")
const C_EDGE := Color("8a8f9c")
const C_GREEN := Color("3cc84a")
const C_YELLOW := Color("e8c832")
const C_RED := Color("e23b3b")
const C_LOST := Color("f2e6d0")
const C_ENERGY := Color("2bc8ff")
const C_GOLD := Color("ffd23f")
const C_TEXT := Color("f4f4f4")
const C_DIM := Color("b4bac6")
const C_SHADOW := Color("101018")
const C_READY := Color("7dff3a")

const BAR_W := 184
const BAR_H := 10
const MARGIN := 12
const HEALTH_Y := 8
const ENERGY_Y := 22
const ENERGY_H := 6
const NAME_Y := 32
## Lama animasi muncul teks, dalam frame.
const POP_FRAMES := 10

var sim: FightSim
var p2_mode_label := ""
var mode_label := ""
var paused := false
## Menu hasil sedang tampil, jadi teks pemenang digeser ke atas.
var result_menu := false

var _font: Font
## Health yang ditampilkan lapisan "hilang perlahan" (GDD 5.3).
var _trail := [1.0, 1.0]
var _trail_hold := [0, 0]
var _last_ratio := [1.0, 1.0]
## Pecahan health bar yang jatuh saat health berkurang: [x, y, vx, vy, umur].
var _shards: Array = []
var _shard_seed := 1
## Umur (frame) tiap teks sejak muncul atau berubah, untuk animasi muncul.
var _combo_seen := [0, 0]
var _combo_age := [99, 99]
var _ult_age := [99, 99]
var _ult_full := [false, false]
## Nama skill yang baru dipakai tiap pemain, dan umurnya dalam frame.
var _skill_name := ["", ""]
var _skill_age := [999, 999]
var _center_text := ""
var _center_age := 99


func _ready() -> void:
	_font = UiFont.get_font()


func _process(_delta: float) -> void:
	queue_redraw()


func reset() -> void:
	_trail = [1.0, 1.0]
	_trail_hold = [0, 0]
	_last_ratio = [1.0, 1.0]
	_shards.clear()
	_combo_seen = [0, 0]
	_combo_age = [99, 99]
	_ult_age = [99, 99]
	_ult_full = [false, false]
	_skill_age = [999, 999]
	_center_text = ""
	_center_age = 99


func _bar_x(i: int) -> float:
	return MARGIN if i == 0 else size.x - MARGIN - BAR_W


## Posisi x di layar untuk rasio health tertentu. Bar P1 habis dari kiri, P2 dari kanan.
func _ratio_x(i: int, ratio: float) -> float:
	if i == 0:
		return _bar_x(0) + BAR_W - roundf(BAR_W * ratio)
	return _bar_x(1) + roundf(BAR_W * ratio)


func _spawn_shards(i: int, from_ratio: float, to_ratio: float) -> void:
	var x0 := _ratio_x(i, from_ratio)
	var x1 := _ratio_x(i, to_ratio)
	var count := clampi(int(absf(x1 - x0) / 5.0) + 2, 2, 9)
	for k in count:
		_shard_seed = (_shard_seed * 1103515245 + 12345) & 0x7fffffff
		var r1 := float((_shard_seed >> 8) % 100) / 100.0
		var r2 := float((_shard_seed >> 16) % 100) / 100.0
		_shards.append([lerpf(x0, x1, r1), HEALTH_Y + r2 * BAR_H, (r1 - 0.5) * 2.4, -0.6 - r2 * 1.4, 0])


func _physics_process(_delta: float) -> void:
	if sim == null:
		return
	var k := _shards.size() - 1
	while k >= 0:
		var s: Array = _shards[k]
		s[0] += s[2]
		s[1] += s[3]
		s[3] += 0.22
		s[4] += 1
		if s[4] > 26:
			_shards.remove_at(k)
		k -= 1
	_center_age += 1
	for i in 2:
		var p: FighterState = sim.fighters[i]
		var ratio: float = float(p.health) / p.data.max_health
		if ratio < _last_ratio[i]:
			_trail_hold[i] = 28
			if visible:
				_spawn_shards(i, _last_ratio[i], ratio)
		elif ratio > _last_ratio[i]:
			_trail[i] = ratio
		_last_ratio[i] = ratio
		if _trail_hold[i] > 0:
			_trail_hold[i] -= 1
		else:
			_trail[i] = maxf(ratio, _trail[i] - 0.012)
		# Animasi muncul: mulai lagi tiap hitungan kombo naik atau ultimate baru penuh.
		_combo_age[i] += 1
		if sim.combo_show[i] != _combo_seen[i]:
			if sim.combo_show[i] >= 2:
				_combo_age[i] = 0
			_combo_seen[i] = sim.combo_show[i]
		_ult_age[i] += 1
		var full: bool = p.energy >= sim.rules.energy_max
		if full and not _ult_full[i]:
			_ult_age[i] = 0
		_ult_full[i] = full
		# Nama skill tampil saat skill mulai (docs/decisions.md no. 24).
		_skill_age[i] += 1
		if p.attack_id == &"skill" and p.st_frame <= 1:
			_skill_name[i] = p.data.skill.display_name.to_upper()
			_skill_age[i] = 0


# --- Alat gambar -------------------------------------------------------------

func _text(pos: Vector2, text: String, font_size: int, color: Color,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1) -> void:
	var shadow := Color(C_SHADOW, color.a)
	for off in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1), Vector2(1, 1)]:
		draw_string(_font, pos + off, text, align, width, font_size, shadow)
	draw_string(_font, pos, text, align, width, font_size, color)


func _text_width(text: String, font_size: int) -> float:
	return _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


## Skala animasi muncul: membesar cepat lalu mengecil ke ukuran normal.
func _pop_scale(age: int) -> float:
	if age >= POP_FRAMES:
		return 1.0
	var t := float(age) / POP_FRAMES
	return 1.0 + 0.7 * (1.0 - t) * (1.0 - t)


## Teks yang diperbesar dari titik jangkar. anchor: 0 = kiri, 0,5 = tengah, 1 = kanan.
func _pop_text(pos: Vector2, text: String, font_size: int, color: Color, anchor: float, scale_now: float) -> void:
	var w := _text_width(text, font_size)
	draw_set_transform(pos, 0.0, Vector2(scale_now, scale_now))
	_text(Vector2(-w * anchor, 0), text, font_size, color)
	draw_set_transform(Vector2.ZERO)


func _frame(r: Rect2) -> void:
	draw_rect(r.grow(2), C_EDGE)
	draw_rect(r.grow(1), C_FRAME)


func _draw() -> void:
	if sim == null:
		return
	var w := int(size.x)
	var h := int(size.y)
	for i in 2:
		_draw_player(i, w)
	_draw_timer(w)
	for s in _shards:
		draw_rect(Rect2(roundf(s[0]) - 1, roundf(s[1]) - 1, 3, 3), Color(C_LOST, 1.0 - s[4] / 26.0))
	_draw_center_text(w, h)
	var hint := "Esc: jeda dan kontrol"
	if paused:
		hint = "JEDA FRAME   F4 lanjut   F6 maju 1 frame"
	_text(Vector2(0, h - 5), "%s     %s     P2: %s" % [mode_label, hint, p2_mode_label], UiFont.SMALL,
			Color(C_TEXT, 0.8), HORIZONTAL_ALIGNMENT_CENTER, w)


func _draw_player(i: int, w: int) -> void:
	var p: FighterState = sim.fighters[i]
	var left := i == 0
	var x := _bar_x(i)

	# Health bar. Isinya menempel ke sisi tengah layar dan habis dari sisi luar.
	var bar := Rect2(x, HEALTH_Y, BAR_W, BAR_H)
	_frame(bar)
	var ratio := float(p.health) / p.data.max_health
	var fill_w := roundf(BAR_W * ratio)
	var lost_w := roundf(BAR_W * _trail[i])
	var col := C_GREEN
	if ratio <= 0.25:
		col = C_RED
	elif ratio <= 0.5:
		col = C_YELLOW
	var fill_x := bar.end.x - fill_w if left else bar.position.x
	var lost_x := bar.end.x - lost_w if left else bar.position.x
	draw_rect(Rect2(lost_x, HEALTH_Y, lost_w, BAR_H), C_LOST)
	draw_rect(Rect2(fill_x, HEALTH_Y, fill_w, BAR_H), col)
	draw_rect(Rect2(fill_x, HEALTH_Y, fill_w, 2), col.lightened(0.35))

	# Bar ultimate tepat di bawah health bar. Emas dan berkedip saat penuh.
	var ebar := Rect2(x, ENERGY_Y, BAR_W, ENERGY_H)
	_frame(ebar)
	var full := p.energy >= sim.rules.energy_max
	var efill := roundf(BAR_W * float(p.energy) / sim.rules.energy_max)
	var ecol := C_ENERGY
	if full:
		ecol = C_GOLD if sim.tick_count % 12 < 6 else C_GOLD.lightened(0.5)
	draw_rect(Rect2(ebar.end.x - efill if left else ebar.position.x, ENERGY_Y, efill, ENERGY_H), ecol)

	# Ikon dan nama.
	var icon := Rect2(x if left else x + BAR_W - 12, NAME_Y, 12, 12)
	draw_rect(icon.grow(1), C_EDGE)
	draw_rect(icon, p.data.color)
	draw_rect(Rect2(icon.position.x, icon.position.y, 12, 4), p.data.accent)
	if left:
		_text(Vector2(x + 17, NAME_Y + 11), p.data.display_name, UiFont.NORMAL, C_TEXT)
	else:
		_text(Vector2(x, NAME_Y + 11), p.data.display_name, UiFont.NORMAL, C_TEXT,
				HORIZONTAL_ALIGNMENT_RIGHT, BAR_W - 17)

	# Status skill di ujung baris nama: terisi selama cooldown, hijau saat siap.
	var skill := p.data.skill
	if skill != null and skill.cooldown > 0:
		var pill := Rect2(x + BAR_W - 46 if left else x, NAME_Y, 46, 12)
		_frame(pill)
		var ready_ratio := 1.0 - float(p.skill_cd) / skill.cooldown
		var is_ready := p.skill_cd == 0
		draw_rect(Rect2(pill.position.x, pill.position.y, roundf(46 * ready_ratio), 12),
				C_READY.darkened(0.45) if is_ready else Color("4a5060"))
		_text(Vector2(pill.position.x, NAME_Y + 10), "SKILL", UiFont.SMALL, C_READY if is_ready else C_DIM,
				HORIZONTAL_ALIGNMENT_CENTER, 46)

	# Titik ronde di samping timer.
	@warning_ignore("integer_division")
	var cx := w / 2
	for k in sim.rules.rounds_to_win:
		var dx := cx - 24 - 9 * (k + 1) + 2 if left else cx + 24 + 9 * k + 1
		var dot := Rect2(dx, 11, 6, 6)
		draw_rect(dot.grow(1), C_EDGE)
		draw_rect(dot, C_GOLD if sim.wins[i] > k else C_FRAME)

	# Notifikasi ULTIMATE! muncul dengan animasi saat bar penuh.
	var side_x := float(x) if left else float(x + BAR_W)
	var anchor := 0.0 if left else 1.0
	if full:
		var blink := 1.0 if sim.tick_count % 30 < 20 else 0.55
		_pop_text(Vector2(side_x, 62), "ULTIMATE SIAP!  [P]" if left else "ULTIMATE SIAP!", UiFont.NORMAL,
				Color(C_GOLD, blink), anchor, _pop_scale(_ult_age[i]))

	# Nama skill muncul sebentar saat dipakai, supaya jelas jurus apa yang keluar.
	if _skill_age[i] < 70:
		var fade: float = 1.0 if _skill_age[i] < 50 else 1.0 - (_skill_age[i] - 50) / 20.0
		_pop_text(Vector2(side_x, 78), _skill_name[i], UiFont.NORMAL, Color(0.6, 0.95, 1.0, fade), anchor,
				_pop_scale(_skill_age[i]))

	# Hitungan kombo di sisi penyerang, muncul membesar tiap pukulan masuk.
	if sim.combo_show[i] >= 2:
		_pop_text(Vector2(side_x, 106), "COMBO x%d" % sim.combo_show[i], UiFont.LARGE, C_GOLD, anchor,
				_pop_scale(_combo_age[i]))


func _draw_timer(w: int) -> void:
	@warning_ignore("integer_division")
	var cx := w / 2
	var box := Rect2(cx - 20, 6, 40, 24)
	_frame(box)
	var secs := sim.seconds_left()
	var col := C_TEXT if secs > 10 else C_RED
	# Di latihan timer berhenti (GDD 3).
	_text(Vector2(cx - 20, 26), "--" if sim.training else "%02d" % secs, UiFont.LARGE, col,
			HORIZONTAL_ALIGNMENT_CENTER, 40)


func _draw_center_text(w: int, h: int) -> void:
	var y := h * 0.5 - 6.0
	var big := ""
	var small := ""
	var col := C_TEXT
	match sim.phase:
		FightSim.Phase.INTRO:
			if sim.phase_frame < sim.intro_fight_frame():
				big = "ROUND %d" % sim.round_no
			else:
				big = "FIGHT!"
				col = C_GOLD
		FightSim.Phase.FIGHT:
			if sim.phase_frame < 20 and sim.cinematic == 0:
				big = "FIGHT!"
				col = C_GOLD
		FightSim.Phase.ROUND_END:
			if sim.round_result == &"time":
				big = "TIME UP"
			else:
				big = "K.O."
				col = C_RED
			if sim.round_winner < 0:
				small = "SERI"
			elif sim.round_result == &"perfect" and sim.phase_frame > 50:
				small = "PERFECT"
		FightSim.Phase.MATCH_END:
			big = "%s MENANG" % sim.fighters[sim.match_winner].data.display_name
			col = C_GOLD
			if result_menu:
				y -= 34.0
	if sim.cinematic > 0:
		# Pita nama ultimate selama cinematic (GDD 4).
		var owner_p: FighterState = sim.fighters[sim.cinematic_owner]
		draw_rect(Rect2(0, y - 26, w, 38), Color(owner_p.data.color.darkened(0.5), 0.85))
		draw_rect(Rect2(0, y - 26, w, 2), C_GOLD)
		draw_rect(Rect2(0, y + 10, w, 2), C_GOLD)
		big = owner_p.data.ultimate.display_name
		col = C_GOLD
	if big != _center_text:
		_center_text = big
		_center_age = 0
	if big != "":
		var fs := UiFont.HUGE if big.length() <= 10 else UiFont.LARGE + 4
		_pop_text(Vector2(w * 0.5, y + (8 if fs == UiFont.HUGE else 2)), big, fs, col, 0.5, _pop_scale(_center_age))
	if small != "":
		_text(Vector2(0, y + 30), small, UiFont.LARGE, C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, w)
