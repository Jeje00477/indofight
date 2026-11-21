extends Node2D
## Menampilkan rig kedua petarung di antara lapisan belakang dan depan stage.
## Tiap frame, keadaan simulasi (state dan nomor frame) diterjemahkan menjadi nama
## animasi dan waktu, lalu rig diminta berpose di titik itu. Tidak ada animasi yang
## berjalan sendiri, jadi gambar selalu cocok dengan frame data.

const FightSim := preload("res://scripts/sim/fight_sim.gd")
const FighterState := preload("res://scripts/sim/fighter_state.gd")
const St := FighterState.St
const FP := FightSim.FP

## Waktu di animasi "ko": akhir fase terlempar, dan pose tergeletak.
const KO_FALL_END := 0.3
const KO_LYING := 0.45

var sim: FightSim
## Lapisan belakang, untuk kamera dan getaran layar.
var view: Node2D

## Bayangan gerak saat dash: muncul tiap sekian frame, hilang setelah sekian frame.
const GHOST_EVERY := 3
const GHOST_LIFE := 9
const GHOST_DASH := Color(1.0, 1.0, 1.0, 0.38)
const GHOST_TELEPORT := Color(0.45, 1.0, 0.92, 0.6)
const GHOST_TELEPORT_LIFE := 18

var _rigs: Array = [null, null]
var _rig_data: Array = [null, null]
## Animasi dan waktu yang terakhir ditampilkan tiap petarung.
var _shown: Array = [[&"idle", 0.0], [&"idle", 0.0]]
## Bayangan gerak yang sedang tampil: [rig, umur, lama hidup, warna].
var _ghosts: Array = []
var _last_tick := -1
## Efek teleport yang sudah dibuatkan bayangan: [tick lahir, nomor petarung].
var _ghosted: Array = []


func _process(_delta: float) -> void:
	if sim == null or view == null:
		return
	position = view.world_offset()
	for i in 2:
		var p: FighterState = sim.fighters[i]
		_sync_rig(i, p)
		var rig: Node2D = _rigs[i]
		if rig == null:
			continue
		@warning_ignore("integer_division")
		rig.position = Vector2(p.x / FP, p.y / FP)
		var a := _animation_for(p, rig)
		rig.pose(a[0], a[1], p.facing, p.flash > 0, _blend_for(p))
		_shown[i] = a
	_update_ghosts()
	# Yang sedang menyerang digambar di depan.
	var front := 1
	if sim.fighters[0].st == St.ATTACK and sim.fighters[1].st != St.ATTACK:
		front = 0
	if _rigs[front] != null:
		move_child(_rigs[front], -1)


## Pasang atau ganti rig bila petarung di slot ini berubah.
func _sync_rig(i: int, p: FighterState) -> void:
	if _rig_data[i] == p.data:
		return
	_rig_data[i] = p.data
	if _rigs[i] != null:
		_rigs[i].queue_free()
		_rigs[i] = null
	if p.data.rig_scene == null:
		return
	var rig: Node2D = p.data.rig_scene.instantiate()
	rig.modulate = p.data.tint
	add_child(rig)
	_rigs[i] = rig


## Jumlah frame peleburan saat petarung masuk ke animasi keadaannya sekarang. Serangan dan
## reaksi kena pukul dilebur singkat supaya tetap tegas dan cocok dengan frame data; gerak
## biasa dilebur lebih lama supaya mengalir.
func _blend_for(p: FighterState) -> int:
	match p.st:
		St.ATTACK:
			return 3
		St.HITSTUN, St.KNOCKDOWN, St.BLOCKSTUN:
			return 2
		St.BLOCK, St.DASH_F, St.DASH_B, St.JUMP:
			return 3
		St.DOWN, St.KO:
			return 4
	return 7


## Bayangan gerak: salinan rig yang dibekukan di satu pose lalu memudar. Hanya tampilan.
func _update_ghosts() -> void:
	if sim.tick_count != _last_tick:
		var ticks := 1 if _last_tick < 0 else clampi(sim.tick_count - _last_tick, 0, 4)
		if sim.tick_count < _last_tick:
			# Ronde atau pertandingan baru.
			for g in _ghosts:
				g[0].queue_free()
			_ghosts.clear()
			_ghosted.clear()
			for rig in _rigs:
				if rig != null:
					rig.reset_motion()
		_last_tick = sim.tick_count
		for g in _ghosts:
			g[1] += ticks
		for i in 2:
			var p: FighterState = sim.fighters[i]
			if (p.st == St.DASH_F or p.st == St.DASH_B) and p.st_frame % GHOST_EVERY == 1:
				@warning_ignore("integer_division")
				_spawn_ghost(i, Vector2(p.x / FP, p.y / FP), GHOST_DASH, GHOST_LIFE)
		# Teleport: bayangan tertinggal di tempat asal.
		for e in sim.effects:
			if e["kind"] != &"afterimage":
				continue
			# Keadaan simulasi tidak boleh diubah dari tampilan, jadi dicatat di sini.
			var born := [sim.tick_count - int(e["age"]), int(e["extra"])]
			if e["age"] <= 2 and not _ghosted.has(born):
				_ghosted.append(born)
				if _ghosted.size() > 8:
					_ghosted.pop_front()
				_spawn_ghost(e["extra"], Vector2(e["x"], e["y"]), GHOST_TELEPORT, GHOST_TELEPORT_LIFE, e["dir"])
	var k := _ghosts.size() - 1
	while k >= 0:
		var g: Array = _ghosts[k]
		if g[1] >= g[2]:
			g[0].queue_free()
			_ghosts.remove_at(k)
		else:
			var c: Color = g[3]
			var fade: float = 1.0 - float(g[1]) / float(g[2])
			g[0].set_ghost(Color(c.r, c.g, c.b, c.a * fade))
		k -= 1


func _spawn_ghost(i: int, at: Vector2, color: Color, life: int, facing: int = 0) -> void:
	var p: FighterState = sim.fighters[i]
	if p.data.rig_scene == null:
		return
	var ghost: Node2D = p.data.rig_scene.instantiate()
	add_child(ghost)
	move_child(ghost, 0)
	ghost.position = at
	ghost.pose(_shown[i][0], _shown[i][1], p.facing if facing == 0 else facing, false)
	ghost.set_ghost(color)
	_ghosts.append([ghost, 0, life, color])


## Nama animasi dan waktu (detik) untuk keadaan petarung sekarang.
func _animation_for(p: FighterState, rig: Node2D) -> Array:
	var t := p.st_frame / 60.0
	match p.st:
		St.IDLE:
			return [&"idle", fposmod(sim.tick_count / 60.0, rig.animation_length(&"idle"))]
		St.WALK_F:
			return [&"walk", fposmod(t, rig.animation_length(&"walk"))]
		St.WALK_B:
			# Jalan mundur = animasi jalan diputar terbalik (docs/decisions.md no. 4).
			var length: float = rig.animation_length(&"walk")
			return [&"walk", length - fposmod(t, length)]
		St.CROUCH:
			return [&"crouch", t]
		St.BLOCK, St.BLOCKSTUN:
			return [&"block", t]
		St.JUMP:
			var air_frames := 2.0 * p.data.jump_speed / p.data.gravity
			return [&"jump", p.st_frame / air_frames * rig.animation_length(&"jump")]
		St.DASH_F:
			return [&"dash", float(p.st_frame) / p.data.dash_frames * rig.animation_length(&"dash")]
		St.DASH_B:
			return [&"backdash", float(p.st_frame) / p.data.dash_frames * rig.animation_length(&"backdash")]
		St.ATTACK:
			return [p.attack_id, _attack_time(p)]
		St.HITSTUN:
			return [&"hit", t]
		St.KNOCKDOWN:
			return [&"ko", minf(t, KO_FALL_END)]
		St.DOWN, St.KO:
			return [&"ko", KO_LYING]
		St.GETUP:
			return [&"getup", float(p.st_frame) / sim.rules.getup_frames * rig.animation_length(&"getup")]
		St.DEFEAT:
			return [&"defeat", t]
		St.WIN:
			return [&"win", fposmod(t, rig.animation_length(&"win"))]
	return [&"idle", 0.0]


## Animasi serangan dibagi tiga satuan waktu: 0 sampai 1 startup, 1 sampai 2 frame
## aktif, 2 sampai 3 recovery. Dengan begitu animasi mengikuti angka di data/attacks.
func _attack_time(p: FighterState) -> float:
	var a := p.attack()
	var fr := p.st_frame
	if fr <= a.startup:
		return float(fr) / maxf(1.0, a.startup)
	if fr <= a.startup + a.active:
		return 1.0 + float(fr - a.startup) / maxf(1.0, a.active)
	return 2.0 + float(fr - a.startup - a.active) / maxf(1.0, a.recovery)
