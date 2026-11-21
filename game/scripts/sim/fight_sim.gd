extends RefCounted
## Simulasi pertarungan IndoFight.
##
## Aturan yang dijaga di sini (docs/ATURAN-PROYEK.md bagian 4):
## - Satu panggilan tick() = satu frame logika. Dipanggil 60 kali per detik.
## - Deterministik: hanya bilangan bulat, tanpa acak, tanpa waktu nyata. Input yang
##   sama selalu menghasilkan keadaan yang sama, dan save_state()/load_state()
##   mengembalikan keadaan persis, sehingga rollback netcode bisa ditambahkan nanti.
## - Hitbox dan hurtbox dihitung langsung tiap tick dari data, tidak lewat sinyal Area2D.
## - Hitstop memakai hitungan frame (docs/decisions.md no. 7), bukan Engine.time_scale.
## - Simulasi tidak menggambar dan tidak memutar suara. Ia hanya mengisi `effects`
##   dan `events` untuk dibaca lapisan tampilan.

const FighterState := preload("res://scripts/sim/fighter_state.gd")
const St := FighterState.St

## Posisi disimpan dalam 1/100 piksel.
const FP := 100

const BIT_LEFT := 0
const BIT_RIGHT := 1
const BIT_UP := 2
const BIT_DOWN := 3
const BIT_LP := 4
const BIT_HP := 5
const BIT_LK := 6
const BIT_HK := 7
const BIT_BLOCK := 8
const BIT_SKILL := 9
const BIT_ULT := 10

const IN_LEFT := 1 << BIT_LEFT
const IN_RIGHT := 1 << BIT_RIGHT
const IN_UP := 1 << BIT_UP
const IN_DOWN := 1 << BIT_DOWN
const IN_LP := 1 << BIT_LP
const IN_HP := 1 << BIT_HP
const IN_LK := 1 << BIT_LK
const IN_HK := 1 << BIT_HK
const IN_BLOCK := 1 << BIT_BLOCK
const IN_SKILL := 1 << BIT_SKILL
const IN_ULT := 1 << BIT_ULT
const IN_ANY_ATTACK := IN_LP | IN_HP | IN_LK | IN_HK | IN_SKILL | IN_ULT

## Urutan prioritas bila beberapa tombol masuk bersamaan: yang paling berat dulu.
const ATTACK_ORDER := [&"ultimate", &"skill", &"hk", &"hp", &"lk", &"lp"]
const BUTTON_OF := {
	&"lp": BIT_LP, &"hp": BIT_HP, &"lk": BIT_LK, &"hk": BIT_HK,
	&"skill": BIT_SKILL, &"ultimate": BIT_ULT,
}

enum Phase { INTRO, FIGHT, ROUND_END, MATCH_END }

const EFFECT_LIFE := {
	&"blunt": 12, &"slash": 12, &"block": 12, &"dust": 14, &"afterimage": 18,
	&"impact": 10, &"crack": 54, &"star5": 84,
}

var rules: MatchRules
var stage: StageData
var fighters: Array = []
## Tiap proyektil: {owner, attack, x, y, dir, traveled, returning, hit_done, age}
var projectiles: Array = []
## Efek tampilan: {kind, x, y, dir, age, life, extra}. x dan y dalam piksel, y relatif ke lantai.
var effects: Array = []
## Kejadian di tick terakhir, untuk suara: hit_light, hit_heavy, block, whoosh, ko, dan lain-lain.
var events: Array = []

var tick_count: int = 0
var phase: int = Phase.INTRO
var phase_frame: int = 0
var round_no: int = 1
var wins: Array = [0, 0]
var timer_ticks: int = 0
## Sisa frame layar berhenti setelah pukulan kena.
var hitstop: int = 0
## Sisa frame cinematic ultimate. Simulasi dan timer berhenti selama ini.
var cinematic: int = 0
var cinematic_owner: int = -1
var shake_frames: int = 0
var shake_mag: int = 0
## -2 belum ada, -1 seri, 0 atau 1 pemenang ronde.
var round_winner: int = -2
## ko, perfect, atau time.
var round_result: StringName = &""
var match_winner: int = -1
## Hitungan kombo yang sedang ditampilkan untuk tiap penyerang.
var combo_show: Array = [0, 0]
var combo_timer: Array = [0, 0]
## Mode Training (GDD 3): timer berhenti, tidak ada K.O., health dan energi terisi lagi.
var training: bool = false


func setup(p_rules: MatchRules, p_stage: StageData, fighter_data: Array) -> void:
	rules = p_rules
	stage = p_stage
	fighters.clear()
	for i in 2:
		var p := FighterState.new()
		p.data = fighter_data[i]
		p.index = i
		fighters.append(p)
	tick_count = 0
	reset_match()


func reset_match() -> void:
	wins = [0, 0]
	round_no = 1
	match_winner = -1
	for p in fighters:
		p.energy = 0
	_start_round()


func _start_round() -> void:
	for i in 2:
		var p: FighterState = fighters[i]
		var side := -1 if i == 0 else 1
		@warning_ignore("integer_division")
		p.x = (stage.width / 2 + side * rules.start_offset) * FP
		p.y = 0
		p.vx = 0
		p.vy = 0
		p.kb = 0
		p.facing = -side
		p.st = St.IDLE
		p.st_frame = 0
		p.health = p.data.max_health
		p.attack_id = &""
		p.attack_dir = 1
		p.hits_done = 0
		p.next_hit_frame = 0
		p.contact = false
		p.stun = 0
		p.combo = 0
		p.skill_cd = 0
		p.flash = 0
		p.hurt_tick = FighterState.NEVER
		p.buf.fill(FighterState.NEVER)
		p.tap_dir = 0
		p.tap_tick = FighterState.NEVER
		p.dash_dir = 0
		p.dash_tick = FighterState.NEVER
	projectiles.clear()
	effects.clear()
	timer_ticks = rules.round_seconds * 60
	hitstop = 0
	cinematic = 0
	cinematic_owner = -1
	shake_frames = 0
	shake_mag = 0
	phase = Phase.INTRO
	phase_frame = 0
	round_winner = -2
	round_result = &""
	combo_show = [0, 0]
	combo_timer = [0, 0]


## Majukan simulasi satu frame. `inputs` berisi bitmask tombol P1 dan P2.
func tick(inputs: Array) -> void:
	events.clear()
	tick_count += 1
	# Input selalu dicatat, juga saat hitstop, supaya tombol yang ditekan
	# selama layar berhenti tetap masuk buffer.
	for i in 2:
		_record_input(fighters[i], inputs[i])
	_age_effects()
	if shake_frames > 0:
		shake_frames -= 1
	for i in 2:
		if fighters[i].flash > 0:
			fighters[i].flash -= 1
		if combo_timer[i] > 0:
			combo_timer[i] -= 1
			if combo_timer[i] == 0:
				combo_show[i] = 0

	match phase:
		Phase.INTRO:
			phase_frame += 1
			if phase_frame == 1:
				events.append(&"round")
			if phase_frame == intro_fight_frame():
				events.append(&"fight")
			if phase_frame >= rules.intro_frames:
				phase = Phase.FIGHT
				phase_frame = 0
		Phase.FIGHT:
			if cinematic > 0:
				cinematic -= 1
				return
			if hitstop > 0:
				hitstop -= 1
				return
			phase_frame += 1
			if training:
				_step(true)
				_training_refill()
			else:
				timer_ticks -= 1
				_step(true)
				_check_round_end()
		Phase.ROUND_END:
			if hitstop > 0:
				hitstop -= 1
				return
			phase_frame += 1
			_mute_inputs()
			_step(false)
			if phase_frame >= 40:
				_settle_poses()
			if phase_frame >= rules.round_end_frames:
				_finish_round()
		Phase.MATCH_END:
			# Menunggu menu hasil memanggil reset_match().
			phase_frame += 1
			_mute_inputs()
			_step(false)


## Frame intro saat teks berganti dari ROUND ke FIGHT!.
func intro_fight_frame() -> int:
	@warning_ignore("integer_division")
	return rules.intro_frames * 2 / 3


func seconds_left() -> int:
	@warning_ignore("integer_division")
	return (max(timer_ticks, 0) + 59) / 60


# --- Input -------------------------------------------------------------------

func _record_input(p: FighterState, inp: int) -> void:
	p.prev_inp = p.inp
	p.inp = inp
	var pressed := inp & ~p.prev_inp
	if pressed == 0:
		return
	# Dicap di tick saat simulasi jalan lagi, supaya umur buffer tidak habis selama hitstop.
	for b in 11:
		if pressed & (1 << b):
			p.buf[b] = tick_count + hitstop
	for bit in [BIT_LEFT, BIT_RIGHT]:
		if pressed & (1 << bit):
			var d := -1 if bit == BIT_LEFT else 1
			if p.tap_dir == d and tick_count - p.tap_tick <= rules.dash_tap_window:
				p.dash_dir = d
				p.dash_tick = tick_count
				p.tap_tick = FighterState.NEVER
			else:
				p.tap_dir = d
				p.tap_tick = tick_count


func _mute_inputs() -> void:
	for p in fighters:
		p.inp = 0
		p.buf.fill(FighterState.NEVER)
		p.dash_tick = FighterState.NEVER


func _buffered(p: FighterState, bit: int) -> bool:
	return tick_count - p.buf[bit] <= rules.input_buffer_frames


func _held_dir(p: FighterState) -> int:
	var l := p.inp & IN_LEFT != 0
	var r := p.inp & IN_RIGHT != 0
	if l and not r:
		return -1
	if r and not l:
		return 1
	return 0


# --- Langkah simulasi --------------------------------------------------------

func _step(live: bool) -> void:
	for i in 2:
		_update_fighter(fighters[i], fighters[1 - i])
	_update_projectiles()
	_separate()
	if live:
		_resolve_hits()


func _enter(p: FighterState, st: int) -> void:
	p.st = st
	p.st_frame = 0


func _enter_if(p: FighterState, st: int) -> void:
	if p.st != st:
		_enter(p, st)


func _face(p: FighterState, o: FighterState) -> void:
	if o.x > p.x:
		p.facing = 1
	elif o.x < p.x:
		p.facing = -1


func is_neutral(p: FighterState) -> bool:
	return p.st == St.IDLE or p.st == St.WALK_F or p.st == St.WALK_B \
			or p.st == St.CROUCH or p.st == St.BLOCK


func _update_fighter(p: FighterState, o: FighterState) -> void:
	if p.skill_cd > 0:
		p.skill_cd -= 1
	p.st_frame += 1
	var d := p.data
	match p.st:
		St.IDLE, St.WALK_F, St.WALK_B, St.CROUCH, St.BLOCK:
			_face(p, o)
			if _try_action(p):
				return
			var dir := _held_dir(p)
			if p.inp & IN_BLOCK:
				_enter_if(p, St.BLOCK)
			elif p.inp & IN_DOWN:
				_enter_if(p, St.CROUCH)
			elif dir != 0 and dir == p.facing:
				_enter_if(p, St.WALK_F)
				p.x += p.facing * d.walk_forward_speed
			elif dir != 0:
				_enter_if(p, St.WALK_B)
				p.x -= p.facing * d.walk_backward_speed
			else:
				_enter_if(p, St.IDLE)
		St.JUMP:
			p.x += p.vx
			p.vy += d.gravity
			p.y += p.vy
			if p.y >= 0:
				p.y = 0
				p.vy = 0
				p.vx = 0
				_enter(p, St.IDLE)
				@warning_ignore("integer_division")
				_add_effect(&"dust", p.x / FP, 0, p.facing)
				events.append(&"land")
		St.DASH_F:
			p.x += p.facing * d.dash_speed
			if p.st_frame >= d.dash_frames:
				_enter(p, St.IDLE)
		St.DASH_B:
			p.x -= p.facing * d.backdash_speed
			if p.st_frame >= d.dash_frames:
				_enter(p, St.IDLE)
		St.ATTACK:
			_update_attack(p, o)
		St.HITSTUN, St.BLOCKSTUN:
			_apply_kb(p)
			p.stun -= 1
			if p.stun <= 0:
				var keep_block := p.st == St.BLOCKSTUN and p.inp & IN_BLOCK != 0
				p.combo = 0
				_enter(p, St.BLOCK if keep_block else St.IDLE)
		St.KNOCKDOWN:
			p.x += p.kb
			p.vy += d.gravity
			p.y += p.vy
			if p.y >= 0 and p.vy > 0:
				p.y = 0
				p.vy = 0
				@warning_ignore("integer_division")
				p.kb = p.kb / 2
				_enter(p, St.KO if p.health <= 0 else St.DOWN)
				@warning_ignore("integer_division")
				_add_effect(&"dust", p.x / FP, 0, p.facing)
				events.append(&"land_heavy")
				shake_frames = max(shake_frames, 5)
				shake_mag = max(shake_mag, 1)
		St.DOWN:
			_apply_kb(p)
			if p.st_frame >= rules.knockdown_frames:
				_enter(p, St.GETUP)
		St.GETUP:
			if p.st_frame >= rules.getup_frames:
				p.combo = 0
				_enter(p, St.IDLE)
		St.KO, St.DEFEAT:
			_apply_kb(p)
		St.WIN:
			pass


func _apply_kb(p: FighterState) -> void:
	p.x += p.kb
	@warning_ignore("integer_division")
	p.kb = p.kb * rules.pushback_friction / 100


func _can_use(p: FighterState, a: AttackData) -> bool:
	if a.requires_full_energy and p.energy < rules.energy_max:
		return false
	if a.cooldown > 0 and p.skill_cd > 0:
		return false
	return true


func _try_action(p: FighterState) -> bool:
	for slot in ATTACK_ORDER:
		var bit: int = BUTTON_OF[slot]
		if _buffered(p, bit):
			var a := p.data.get_attack(slot)
			if a != null and _can_use(p, a):
				p.buf[bit] = FighterState.NEVER
				_start_attack(p, slot, a)
				return true
	if tick_count - p.dash_tick <= rules.input_buffer_frames:
		p.dash_tick = FighterState.NEVER
		_enter(p, St.DASH_F if p.dash_dir == p.facing else St.DASH_B)
		@warning_ignore("integer_division")
		_add_effect(&"dust", p.x / FP, 0, p.facing)
		events.append(&"dash")
		return true
	if p.inp & IN_UP:
		p.vy = -p.data.jump_speed
		p.vx = _held_dir(p) * p.data.air_speed
		_enter(p, St.JUMP)
		events.append(&"jump")
		return true
	return false


func _start_attack(p: FighterState, slot: StringName, a: AttackData) -> void:
	_enter(p, St.ATTACK)
	p.attack_id = slot
	p.hits_done = 0
	p.next_hit_frame = 0
	p.contact = false
	p.attack_dir = -1 if _held_dir(p) == -p.facing else 1
	if a.requires_full_energy:
		p.energy = 0
	if a.cooldown > 0:
		p.skill_cd = a.cooldown
	if a.cinematic_frames > 0:
		cinematic = a.cinematic_frames
		cinematic_owner = p.index
		events.append(&"ultimate")


func _update_attack(p: FighterState, o: FighterState) -> void:
	var a := p.data.get_attack(p.attack_id)
	var fr := p.st_frame
	if a.lunge_speed != 0 and fr >= a.lunge_from and fr <= a.lunge_to:
		p.x += p.facing * a.lunge_speed
	if a.teleport_distance != 0 and fr == a.teleport_frame:
		@warning_ignore("integer_division")
		_add_effect(&"afterimage", p.x / FP, 0, p.facing, p.index)
		p.x += p.facing * p.attack_dir * a.teleport_distance * FP
		p.x = clampi(p.x, _stage_lo(), _stage_hi())
		_face(p, o)
		events.append(&"teleport")
	if fr == a.startup + 1:
		if a.projectile != null:
			_spawn_projectile(p, a)
		if a.has_hitbox() or a.projectile != null:
			events.append(&"whoosh_heavy" if a.heavy else &"whoosh")
	if p.contact and fr > a.startup:
		for slot in a.cancel_into:
			var bit: int = BUTTON_OF[slot]
			if _buffered(p, bit):
				var next := p.data.get_attack(slot)
				if next != null and _can_use(p, next):
					p.buf[bit] = FighterState.NEVER
					_start_attack(p, slot, next)
					return
	if fr >= a.total_frames():
		p.attack_id = &""
		_enter(p, St.IDLE)


# --- Proyektil ---------------------------------------------------------------

func _spawn_projectile(p: FighterState, a: AttackData) -> void:
	var pd := a.projectile
	projectiles.append({
		"owner": p.index,
		"attack": p.attack_id,
		"x": p.x + p.facing * pd.spawn_offset.x * FP,
		"y": pd.spawn_offset.y * FP,
		"dir": p.facing,
		"traveled": 0,
		"returning": false,
		"hit_done": false,
		"age": 0,
	})


func _update_projectiles() -> void:
	var i := projectiles.size() - 1
	while i >= 0:
		var pr: Dictionary = projectiles[i]
		var owner: FighterState = fighters[pr["owner"]]
		var pd: ProjectileData = owner.data.get_attack(pr["attack"]).projectile
		pr["age"] += 1
		var dead: bool = pr["age"] > pd.lifetime
		if pr["returning"]:
			var dx: int = owner.x - pr["x"]
			if abs(dx) <= pd.speed + 8 * FP:
				dead = true
				events.append(&"catch")
			else:
				pr["dir"] = 1 if dx > 0 else -1
				pr["x"] += pr["dir"] * pd.speed
		else:
			pr["x"] += pr["dir"] * pd.speed
			pr["traveled"] += pd.speed
			var out: bool = pr["x"] < 0 or pr["x"] > stage.width * FP
			if pr["traveled"] >= pd.max_distance * FP or out:
				if pd.returns:
					pr["returning"] = true
				else:
					dead = true
		if dead:
			projectiles.remove_at(i)
		i -= 1


# --- Kotak -------------------------------------------------------------------
# Semua kotak dalam piksel dunia. y relatif ke lantai: 0 di lantai, negatif ke atas.

func hurtbox_rect(p: FighterState) -> Rect2i:
	var r := p.data.crouch_hurtbox if p.st == St.CROUCH else p.data.stand_hurtbox
	@warning_ignore("integer_division")
	var origin := Vector2i(p.x / FP, p.y / FP)
	if p.is_lying():
		# Tergeletak: kotak direbahkan. Hanya untuk tampilan, petarung yang jatuh kebal.
		@warning_ignore("integer_division")
		return Rect2i(origin.x - r.size.y / 2, origin.y - r.size.x, r.size.y, r.size.x)
	return Rect2i(origin + r.position, r.size)


func hitbox_rect(p: FighterState, a: AttackData) -> Rect2i:
	var r := a.hitbox
	@warning_ignore("integer_division")
	var px := p.x / FP
	@warning_ignore("integer_division")
	var py := p.y / FP
	var left := px + r.position.x if p.facing == 1 else px - r.position.x - r.size.x
	return Rect2i(left, py + r.position.y, r.size.x, r.size.y)


func pushbox_rect(p: FighterState) -> Rect2i:
	var h := hurtbox_rect(p)
	@warning_ignore("integer_division")
	return Rect2i(p.x / FP - p.data.push_width / 2, h.position.y, p.data.push_width, h.size.y)


func projectile_rect(pr: Dictionary) -> Rect2i:
	var pd: ProjectileData = fighters[pr["owner"]].data.get_attack(pr["attack"]).projectile
	@warning_ignore("integer_division")
	var c := Vector2i(pr["x"] / FP, pr["y"] / FP)
	@warning_ignore("integer_division")
	return Rect2i(c - pd.size / 2, pd.size)


func is_invulnerable(p: FighterState) -> bool:
	match p.st:
		St.KNOCKDOWN, St.DOWN, St.GETUP, St.KO, St.DEFEAT, St.WIN:
			return true
		St.ATTACK:
			var a := p.data.get_attack(p.attack_id)
			return a.invulnerable_to > 0 and p.st_frame >= a.invulnerable_from \
					and p.st_frame <= a.invulnerable_to
	return false


## Serangan unblockable sedang dalam jeda peringatan (GDD 11.1).
func is_warning(p: FighterState) -> bool:
	var a := p.attack()
	return a != null and a.unblockable and p.st_frame <= a.startup


# --- Dorong badan dan batas stage --------------------------------------------

func _stage_lo() -> int:
	return rules.stage_margin * FP


func _stage_hi() -> int:
	return (stage.width - rules.stage_margin) * FP


func _solid(p: FighterState) -> bool:
	match p.st:
		St.KNOCKDOWN, St.DOWN, St.KO:
			return false
	return p.y > -30 * FP


func _clamp_to_stage() -> void:
	var lo := _stage_lo()
	var hi := _stage_hi()
	for i in 2:
		var p: FighterState = fighters[i]
		var o: FighterState = fighters[1 - i]
		var stunned := p.st == St.HITSTUN or p.st == St.BLOCKSTUN
		if p.x < lo:
			# Lawan terpojok: sisa dorongan dipindah ke penyerang.
			if stunned:
				o.x += lo - p.x
			p.x = lo
		elif p.x > hi:
			if stunned:
				o.x -= p.x - hi
			p.x = hi
	for p in fighters:
		p.x = clampi(p.x, lo, hi)


func _separate() -> void:
	var a: FighterState = fighters[0]
	var b: FighterState = fighters[1]
	var lo := _stage_lo()
	var hi := _stage_hi()
	_clamp_to_stage()
	if _solid(a) and _solid(b):
		@warning_ignore("integer_division")
		var min_d := (a.data.push_width + b.data.push_width) * FP / 2
		var dx := b.x - a.x
		if abs(dx) < min_d:
			var s := 1 if (dx > 0 or (dx == 0 and a.facing == 1)) else -1
			var overlap: int = min_d - abs(dx)
			@warning_ignore("integer_division")
			var half := overlap / 2
			a.x -= s * half
			b.x += s * (overlap - half)
			if a.x < lo:
				b.x += lo - a.x
				a.x = lo
			elif a.x > hi:
				b.x -= a.x - hi
				a.x = hi
			if b.x < lo:
				a.x += lo - b.x
				b.x = lo
			elif b.x > hi:
				a.x -= b.x - hi
				b.x = hi
	var max_d := rules.max_distance * FP
	var dist: int = abs(b.x - a.x)
	if dist > max_d:
		var extra := dist - max_d
		var s2 := 1 if b.x > a.x else -1
		@warning_ignore("integer_division")
		var half2 := extra / 2
		a.x += s2 * half2
		b.x -= s2 * (extra - half2)
	a.x = clampi(a.x, lo, hi)
	b.x = clampi(b.x, lo, hi)


# --- Pukulan -----------------------------------------------------------------

func _resolve_hits() -> void:
	# Kumpulkan dulu semua pukulan di tick ini, baru terapkan, supaya dua
	# serangan yang kena bersamaan sama-sama dihitung (trade).
	var pending: Array = []
	for i in 2:
		var p: FighterState = fighters[i]
		var o: FighterState = fighters[1 - i]
		if p.st != St.ATTACK:
			continue
		var a := p.data.get_attack(p.attack_id)
		if not a.has_hitbox() or not a.is_active_frame(p.st_frame):
			continue
		if p.hits_done >= a.hit_count or p.st_frame < p.next_hit_frame:
			continue
		if is_invulnerable(o):
			continue
		var hb := hitbox_rect(p, a)
		var hu := hurtbox_rect(o)
		if hb.intersects(hu):
			var c := hb.intersection(hu)
			@warning_ignore("integer_division")
			pending.append([i, a, c.position + c.size / 2, false, 0])
	for pr in projectiles:
		if pr["hit_done"]:
			continue
		var o: FighterState = fighters[1 - pr["owner"]]
		if is_invulnerable(o):
			continue
		var rect := projectile_rect(pr)
		if rect.intersects(hurtbox_rect(o)):
			pr["hit_done"] = true
			var a2: AttackData = fighters[pr["owner"]].data.get_attack(pr["attack"])
			@warning_ignore("integer_division")
			pending.append([pr["owner"], a2, rect.position + rect.size / 2, true, pr["dir"]])
	var stop := 0
	for h in pending:
		stop = max(stop, _apply_hit(fighters[h[0]], fighters[1 - h[0]], h[1], h[2], h[3], h[4]))
	if stop > 0:
		hitstop = stop


## Terapkan satu pukulan. Mengembalikan lama hitstop.
func _apply_hit(att: FighterState, vic: FighterState, a: AttackData, at: Vector2i,
		is_projectile: bool, projectile_dir: int) -> int:
	var dir := projectile_dir
	if not is_projectile:
		dir = att.facing
		if vic.x > att.x:
			dir = 1
		elif vic.x < att.x:
			dir = -1
		att.hits_done += 1
		att.next_hit_frame = att.st_frame + a.hit_interval
		att.contact = true

	vic.hurt_tick = tick_count
	var blocked := not a.unblockable and (vic.st == St.BLOCK or vic.st == St.BLOCKSTUN)
	if blocked:
		vic.health = max(1, vic.health - a.chip_damage)
		_enter(vic, St.BLOCKSTUN)
		vic.stun = a.blockstun
		vic.kb = dir * a.pushback_block
		if not a.requires_full_energy:
			_gain(att, rules.energy_on_block_attacker)
		_gain(vic, rules.energy_on_block_defender)
		_add_effect(&"block", at.x, at.y, dir)
		events.append(&"block")
		return a.blockstop

	var last_hit := is_projectile or att.hits_done >= a.hit_count
	var combo := vic.combo + 1 if vic.st == St.HITSTUN else 1
	var scale: int = max(rules.combo_scaling_min, 100 - rules.combo_scaling_step * (combo - 1))
	@warning_ignore("integer_division")
	var dmg := a.damage * scale / 100
	vic.health = max(1 if training else 0, vic.health - dmg)
	if not a.requires_full_energy:
		@warning_ignore("integer_division")
		_gain(att, dmg * rules.energy_per_100_dealt / 100)
	@warning_ignore("integer_division")
	_gain(vic, dmg * rules.energy_per_100_taken / 100)

	var ko := vic.health <= 0
	var airborne := vic.y < 0
	vic.flash = rules.hit_flash_frames
	vic.attack_id = &""
	vic.vx = 0
	if (a.knockdown and last_hit) or airborne or ko:
		_enter(vic, St.KNOCKDOWN)
		vic.vy = -max(a.launch_speed, 260)
		@warning_ignore("integer_division")
		vic.kb = dir * a.pushback_hit / 2
		if vic.y >= 0:
			vic.y = -1
	else:
		_enter(vic, St.HITSTUN)
		vic.stun = max(rules.hitstun_min, a.hitstun - rules.hitstun_decay * (combo - 1))
		vic.kb = dir * a.pushback_hit
	vic.combo = combo
	combo_show[att.index] = combo
	combo_timer[att.index] = 70

	shake_mag = a.shake + (2 if ko else 0)
	shake_frames = 4 + a.shake * 3
	_add_effect(a.spark, at.x, at.y, dir)
	# Efek GDD 9.2: impact flash dan speed lines untuk serangan berat, retak layar
	# saat ultimate kena, dan efek penutup khusus (misalnya notifikasi Bintang 5).
	if a.heavy:
		_add_effect(&"impact", at.x, at.y, dir)
	if last_hit and a.requires_full_energy:
		_add_effect(&"crack", at.x, at.y, dir)
		events.append(&"ultimate_hit")
	if last_hit and a.finish_effect != &"":
		@warning_ignore("integer_division")
		_add_effect(a.finish_effect, vic.x / FP, 0, dir, vic.index)
		events.append(a.finish_effect)
	events.append(&"hit_heavy" if a.heavy else &"hit_light")
	if ko:
		events.append(&"ko")
	return a.hitstop + (rules.ko_hitstop if ko else 0)


func _gain(p: FighterState, amount: int) -> void:
	if amount <= 0 or p.energy >= rules.energy_max:
		return
	p.energy = min(rules.energy_max, p.energy + amount)
	if p.energy >= rules.energy_max:
		events.append(&"energy_full")


## Training: energi selalu penuh, health pulih sejenak setelah kombo berakhir.
func _training_refill() -> void:
	for p in fighters:
		if not is_neutral(p):
			continue
		p.energy = rules.energy_max
		if p.health < p.data.max_health and tick_count - p.hurt_tick > 60:
			p.health = p.data.max_health


# --- Ronde -------------------------------------------------------------------

func _check_round_end() -> void:
	var a: FighterState = fighters[0]
	var b: FighterState = fighters[1]
	var a_dead := a.health <= 0
	var b_dead := b.health <= 0
	if a_dead or b_dead:
		round_winner = -1 if (a_dead and b_dead) else (1 if a_dead else 0)
		round_result = &"ko"
		if round_winner >= 0 and fighters[round_winner].health >= fighters[round_winner].data.max_health:
			round_result = &"perfect"
		_end_round()
	elif timer_ticks <= 0:
		timer_ticks = 0
		if a.health == b.health:
			round_winner = -1
		else:
			round_winner = 0 if a.health > b.health else 1
		round_result = &"time"
		events.append(&"time_up")
		_end_round()


func _end_round() -> void:
	phase = Phase.ROUND_END
	phase_frame = 0
	if round_winner >= 0:
		wins[round_winner] += 1


## Pemenang berpose menang; yang kalah karena waktu habis berpose kalah.
func _settle_poses() -> void:
	for i in 2:
		var p: FighterState = fighters[i]
		if not is_neutral(p):
			continue
		if i == round_winner:
			_enter(p, St.WIN)
		elif round_result == &"time":
			_enter(p, St.DEFEAT)


func _finish_round() -> void:
	if round_winner >= 0 and wins[round_winner] >= rules.rounds_to_win:
		phase = Phase.MATCH_END
		phase_frame = 0
		match_winner = round_winner
		events.append(&"match_end")
		return
	if round_winner >= 0:
		round_no += 1
	_start_round()


# --- Efek tampilan -----------------------------------------------------------

func _add_effect(kind: StringName, x: int, y: int, dir: int, extra: int = 0) -> void:
	effects.append({
		"kind": kind, "x": x, "y": y, "dir": dir,
		"age": 0, "life": EFFECT_LIFE.get(kind, 12), "extra": extra,
	})


func _age_effects() -> void:
	var i := effects.size() - 1
	while i >= 0:
		effects[i]["age"] += 1
		if effects[i]["age"] >= effects[i]["life"]:
			effects.remove_at(i)
		i -= 1


# --- Snapshot (untuk rollback dan uji determinisme) ---------------------------

func save_state() -> Dictionary:
	return {
		"tick_count": tick_count, "phase": phase, "phase_frame": phase_frame,
		"round_no": round_no, "wins": wins.duplicate(), "timer_ticks": timer_ticks,
		"hitstop": hitstop, "cinematic": cinematic, "cinematic_owner": cinematic_owner,
		"shake_frames": shake_frames, "shake_mag": shake_mag,
		"round_winner": round_winner, "round_result": round_result,
		"match_winner": match_winner,
		"combo_show": combo_show.duplicate(), "combo_timer": combo_timer.duplicate(),
		"training": training,
		"fighters": [fighters[0].save(), fighters[1].save()],
		"projectiles": projectiles.duplicate(true),
		"effects": effects.duplicate(true),
	}


func load_state(s: Dictionary) -> void:
	tick_count = s["tick_count"]
	phase = s["phase"]
	phase_frame = s["phase_frame"]
	round_no = s["round_no"]
	wins = s["wins"].duplicate()
	timer_ticks = s["timer_ticks"]
	hitstop = s["hitstop"]
	cinematic = s["cinematic"]
	cinematic_owner = s["cinematic_owner"]
	shake_frames = s["shake_frames"]
	shake_mag = s["shake_mag"]
	round_winner = s["round_winner"]
	round_result = s["round_result"]
	match_winner = s["match_winner"]
	combo_show = s["combo_show"].duplicate()
	combo_timer = s["combo_timer"].duplicate()
	training = s["training"]
	for i in 2:
		fighters[i].restore(s["fighters"][i])
	projectiles = s["projectiles"].duplicate(true)
	effects = s["effects"].duplicate(true)
	events.clear()


func state_hash() -> int:
	return var_to_str(save_state()).hash()
