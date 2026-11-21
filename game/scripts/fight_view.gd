extends Node2D
## Tampilan pertarungan dengan kotak placeholder.
## Hanya membaca keadaan simulasi, tidak pernah mengubahnya. Saat sprite jadi,
## file inilah yang diganti; simulasi dan data tidak perlu disentuh.

const FightSim := preload("res://scripts/sim/fight_sim.gd")
const FighterState := preload("res://scripts/sim/fighter_state.gd")
const St := FighterState.St
const FP := FightSim.FP

## Tinggi layar dasar (docs/ATURAN-PROYEK.md bagian 1).
const BASE_HEIGHT := 270

const C_HURT := Color(0.2, 1.0, 0.3)
const C_HIT := Color(1.0, 0.15, 0.15)
const C_PUSH := Color(0.3, 0.6, 1.0)
const C_WARN := Color("f08a24")
const C_SHIELD := Color("7fd4ff")
const C_PROP := Color("e8504a")
const C_PROP_DARK := Color("6e141b")

## Gedung latar: [x, lebar, tinggi] di layer background.
const BUILDINGS := [
	[0, 70, 120], [74, 52, 96], [130, 84, 140], [218, 46, 88], [268, 76, 128],
	[348, 58, 104], [410, 90, 150], [504, 50, 92], [558, 78, 132], [640, 60, 110],
	[704, 86, 144], [794, 52, 98], [850, 80, 126],
]

## Garis retakan layar: tiap garis berupa deretan ruas [dx, dy] dari titik kena.
const CRACK_RAYS := [
	[[30, -8], [22, -20], [34, -6]],
	[[10, -30], [-6, -26], [8, -30]],
	[[-26, -14], [-30, 4], [-24, -16]],
	[[-18, 22], [-28, 10], [-20, 26]],
	[[6, 30], [14, 22], [-4, 30]],
	[[28, 16], [30, -2], [26, 20]],
	[[-36, -2], [-20, -12]],
	[[18, -18], [26, -24]],
]

## 0 = lapisan belakang (stage), 1 = lapisan depan (efek, foreground, debug).
@export var layer := 0

var sim: FightSim
## Tampilkan hitbox, hurtbox, dan data frame (F1).
var show_boxes := false

var _font: Font
## Geseran seluruh gambar di frame ini (getaran layar dan layar tinggi).
var _base_offset := Vector2.ZERO


func _ready() -> void:
	_font = ThemeDB.fallback_font


func _process(_delta: float) -> void:
	queue_redraw()


func _view_size() -> Vector2i:
	return Vector2i(get_viewport_rect().size)


func camera_x() -> int:
	var vw := _view_size().x
	@warning_ignore("integer_division")
	var mid: int = (sim.fighters[0].x + sim.fighters[1].x) / 2 / FP
	@warning_ignore("integer_division")
	return clampi(mid - vw / 2, 0, maxi(0, sim.stage.width - vw))


func _shake() -> Vector2:
	if sim.shake_frames <= 0 or sim.shake_mag <= 0:
		return Vector2.ZERO
	var t := sim.tick_count
	var m := sim.shake_mag
	@warning_ignore("integer_division")
	return Vector2((t % 2 * 2 - 1) * m, (t / 2 % 2 * 2 - 1) * ((m + 1) / 2))


func world_offset() -> Vector2:
	var extra := maxi(0, _view_size().y - BASE_HEIGHT)
	return _shake() + Vector2(-camera_x(), sim.stage.floor_y + extra)


func _draw() -> void:
	if sim == null:
		return
	var cam := camera_x()
	var size := _view_size()
	var floor_y := sim.stage.floor_y
	# Layar yang lebih tinggi dari 270 (bukan 16:9): dunia menempel ke bawah dan
	# langit mengisi sisa di atas, supaya garis lantai tetap di baris 238 dari 270.
	var extra := maxi(0, size.y - BASE_HEIGHT)
	size.y = BASE_HEIGHT
	_base_offset = _shake() + Vector2(0, extra)
	draw_set_transform(_base_offset)
	if layer == 0:
		# Lapisan belakang: stage, bayangan, dan efek di belakang petarung.
		draw_rect(Rect2(-8, -extra - 8, size.x + 16, extra + 16), sim.stage.sky_top)
		if sim.stage.background != null:
			_draw_stage_textures(cam, size)
		else:
			_draw_sky(cam, size, floor_y)
			_draw_background(cam, floor_y)
			_draw_floor(cam, size, floor_y)
		if sim.cinematic > 0:
			draw_rect(Rect2(-8, -extra - 8, size.x + 16, size.y + extra + 16), Color(0, 0, 0, 0.62))
		for p in sim.fighters:
			@warning_ignore("integer_division")
			var sx: int = p.x / FP - cam
			var w := 46 if p.is_lying() else 17
			draw_rect(Rect2(sx - w, floor_y - 1, w * 2, 3), Color(0, 0, 0, 0.35))
		for e in sim.effects:
			if e["kind"] == &"afterimage" or e["kind"] == &"dust":
				_draw_effect(e, cam, floor_y)
	else:
		# Lapisan depan: digambar di atas rig petarung.
		for p in sim.fighters:
			_draw_fighter_overlay(p, cam, floor_y)
		for pr in sim.projectiles:
			_draw_projectile(pr, cam, floor_y)
		for e in sim.effects:
			if e["kind"] != &"afterimage" and e["kind"] != &"dust":
				_draw_effect(e, cam, floor_y)
		if sim.stage.background == null:
			_draw_foreground(cam, size)
		if show_boxes:
			_draw_debug(cam, floor_y)
	draw_set_transform(Vector2.ZERO)


# --- Stage dari gambar ---------------------------------------------------------

## Layer latar bergeser 0,5x dan layer lantai 1,0x terhadap kamera (GDD 7).
func _draw_stage_textures(cam: int, size: Vector2i) -> void:
	var st := sim.stage
	_draw_strip(st.background, -int(cam * st.parallax_background), 0, size.x)
	if st.floor_texture != null:
		_draw_strip(st.floor_texture, -int(cam * st.parallax_midground), st.floor_top, size.x)


## Gambar tekstur mulai dari x, diulang ke kanan bila layar lebih lebar dari teksturnya.
func _draw_strip(tex: Texture2D, x: int, y: int, view_w: int) -> void:
	var w := tex.get_width()
	while x < view_w:
		draw_texture(tex, Vector2(x, y))
		x += w


# --- Stage placeholder -------------------------------------------------------

func _draw_sky(cam: int, size: Vector2i, floor_y: int) -> void:
	var st := sim.stage
	var bands := 8
	@warning_ignore("integer_division")
	var band_h := floor_y / bands + 1
	for i in bands:
		var c := st.sky_top.lerp(st.sky_bottom, float(i) / (bands - 1))
		draw_rect(Rect2(-8, i * band_h - 8 if i == 0 else i * band_h, size.x + 16, band_h + 8), c)
	var off := int(cam * st.parallax_sky)
	draw_rect(Rect2(330 - off, 60, 14, 14), Color("d8d8c8"))
	for cloud in [[40, 52, 60], [170, 34, 44], [420, 60, 70], [520, 40, 50]]:
		draw_rect(Rect2(cloud[0] - off, cloud[1], cloud[2], 5), st.sky_bottom.lightened(0.12))
		draw_rect(Rect2(cloud[0] + 8 - off, cloud[1] - 4, cloud[2] - 20, 4), st.sky_bottom.lightened(0.12))


func _draw_background(cam: int, floor_y: int) -> void:
	var st := sim.stage
	var off := int(cam * st.parallax_background)
	for i in BUILDINGS.size():
		var b: Array = BUILDINGS[i]
		var x: int = b[0] - off
		var h: int = b[2]
		draw_rect(Rect2(x, floor_y - h, b[1], h), st.building if i % 2 == 0 else st.building.lightened(0.06))
		draw_rect(Rect2(x - 2, floor_y - h - 3, b[1] + 4, 3), st.building.darkened(0.3))
		# Jendela: sebagian menyala. Dibiarkan redup supaya petarung tetap terbaca.
		var row := 0
		var wy := floor_y - h + 8
		while wy < floor_y - 110:
			var col := 0
			var wx := x + 6
			while wx < x + b[1] - 8:
				if (i * 7 + row * 5 + col * 3) % 4 == 0:
					draw_rect(Rect2(wx, wy, 5, 6), st.building_light.darkened(0.25))
				col += 1
				wx += 12
			row += 1
			wy += 14
	# Tiang listrik dan lampu jalan kuning yang berkedip (GDD 7.4).
	for px in [150, 470, 760]:
		var x2: int = px - off
		draw_rect(Rect2(x2, floor_y - 130, 3, 130), st.building.darkened(0.45))
		draw_rect(Rect2(x2 - 16, floor_y - 124, 35, 2), st.building.darkened(0.45))
		@warning_ignore("integer_division")
		var lit: bool = (sim.tick_count / 6 + px) % 23 != 0
		draw_rect(Rect2(x2 + 3, floor_y - 112, 8, 4), st.building_light if lit else st.building.darkened(0.2))


func _draw_floor(cam: int, size: Vector2i, floor_y: int) -> void:
	var st := sim.stage
	draw_rect(Rect2(-8, floor_y, size.x + 16, size.y - floor_y + 8), st.floor_color)
	draw_rect(Rect2(-8, floor_y, size.x + 16, 1), st.floor_line.lightened(0.2))
	var off := int(cam * st.parallax_midground)
	var x := -posmod(off, 32) - 32
	while x < size.x + 32:
		draw_rect(Rect2(x, floor_y + 1, 1, 10), st.floor_line)
		draw_rect(Rect2(x + 16, floor_y + 11, 1, 12), st.floor_line)
		x += 32
	draw_rect(Rect2(-8, floor_y + 11, size.x + 16, 1), st.floor_line)
	draw_rect(Rect2(-8, floor_y + 23, size.x + 16, 1), st.floor_line)


func _draw_foreground(cam: int, size: Vector2i) -> void:
	var st := sim.stage
	var off := int(cam * st.parallax_foreground)
	# Siluet gerobak dan jemuran, hanya menutupi tepi bawah layar.
	for item in [[120, 76], [640, 60], [1010, 80]]:
		var x: int = item[0] - off
		draw_rect(Rect2(x, size.y - 18, item[1], 26), st.foreground)
		draw_rect(Rect2(x + 6, size.y - 26, item[1] - 12, 8), st.foreground)


# --- Petarung ----------------------------------------------------------------

func _to_screen(r: Rect2i, cam: int, floor_y: int) -> Rect2:
	return Rect2(r.position.x - cam, floor_y + r.position.y, r.size.x, r.size.y)


func _outline(r: Rect2, c: Color) -> void:
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1), c)
	draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), c)
	draw_rect(Rect2(r.position.x, r.position.y, 1, r.size.y), c)
	draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), c)


## Tambahan di atas rig petarung: peringatan unblockable, motor, dan perisai block.
func _draw_fighter_overlay(p: FighterState, cam: int, floor_y: int) -> void:
	var body := _to_screen(sim.hurtbox_rect(p), cam, floor_y)
	@warning_ignore("integer_division")
	var sx: int = p.x / FP - cam

	# Jeda peringatan serangan unblockable (GDD 11.1): jalur serangan dan tanda seru berkedip.
	if sim.is_warning(p):
		var a := p.attack()
		@warning_ignore("integer_division")
		var reach: int = a.hitbox.end.x + a.lunge_speed * (a.lunge_to - a.lunge_from + 1) / FP
		var blink := sim.tick_count % 8 < 4
		var lane := Rect2(sx if p.facing == 1 else sx - reach, floor_y - 3, reach, 4)
		draw_rect(lane, Color(C_WARN, 0.85 if blink else 0.35))
		if blink:
			draw_rect(Rect2(sx - 2, body.position.y - 26, 4, 11), C_WARN)
			draw_rect(Rect2(sx - 2, body.position.y - 13, 4, 4), C_WARN)

	var a2 := p.attack()
	if a2 != null and a2.vehicle and p.st_frame <= a2.startup + a2.active:
		_draw_vehicle(p, sx, floor_y)
	elif a2 != null and a2.has_hitbox():
		_draw_swoosh(p, a2, cam, floor_y)

	if p.st == St.BLOCKSTUN:
		# Busur perisai di depan badan, memudar seiring blockstun habis.
		var mid := body.position.y + body.size.y * 0.45
		var edge := body.end.x + 5 if p.facing == 1 else body.position.x - 5
		var glow := clampf(p.stun / 10.0, 0.25, 1.0)
		for k in range(-4, 5):
			var bend := (k * k) / 3
			var px := edge - p.facing * bend
			draw_rect(Rect2(px - 1, mid + k * 5 - 2, 2, 5), Color(C_SHIELD, 0.85 * glow))
			if absi(k) < 3:
				draw_rect(Rect2(px + p.facing * 2 - 1, mid + k * 5 - 1, 1, 3), Color(1, 1, 1, 0.7 * glow))


## Jejak ayunan di beberapa frame aktif pertama, supaya arah dan tenaga serangan terbaca.
## Serangan tajam (sapu) meninggalkan busur sabit; serangan tumpul meninggalkan garis lesat.
func _draw_swoosh(p: FighterState, a: AttackData, cam: int, floor_y: int) -> void:
	var age := p.st_frame - a.startup
	if age < 1 or age > 5:
		return
	var hb := _to_screen(sim.hitbox_rect(p, a), cam, floor_y)
	var fade := 1.0 - float(age - 1) / 5.0
	var f := p.facing
	var back_x := hb.position.x if f == 1 else hb.end.x
	if a.spark == &"slash":
		var steps := 14
		for i in steps + 1:
			var t := float(i) / steps
			var ang := lerpf(-1.25, 0.85, t)
			var pt := Vector2(back_x + f * cos(ang) * hb.size.x * 0.98, hb.get_center().y + sin(ang) * hb.size.y * 0.5).round()
			var thick := maxi(1, int(round(sin(t * PI) * (4.0 if a.heavy else 2.5) * fade)))
			draw_rect(Rect2(pt.x - thick, pt.y - thick, thick * 2, thick * 2), Color(1, 1, 1, 0.85 * fade))
	else:
		var lines := 4 if a.heavy else 3
		for i in lines:
			var y := roundf(hb.position.y + hb.size.y * (i + 0.5) / lines)
			var length := roundf(hb.size.x * (0.55 + 0.12 * (i % 2)) * fade + 6)
			var tip := back_x + f * hb.size.x
			draw_rect(Rect2(tip - length if f == 1 else tip, y, length, 2 if a.heavy else 1), Color(1, 1, 1, 0.8 * fade))


## Gambar satu frame sprite sheet mendatar, bagian tengah bawahnya di `pos`, dicerminkan bila facing -1.
func _draw_sheet_frame(tex: Texture2D, frame: int, frame_size: Vector2i, pos: Vector2, facing: int,
		anchor_y: float, tint: Color = Color.WHITE) -> void:
	draw_set_transform(_base_offset + pos, 0.0, Vector2(facing, 1))
	draw_texture_rect_region(tex, Rect2(-frame_size.x * 0.5, -anchor_y, frame_size.x, frame_size.y),
			Rect2(frame * frame_size.x, 0, frame_size.x, frame_size.y), tint)
	draw_set_transform(_base_offset)


## Motor yang dinaiki saat ultimate. Sprite-nya dirender dari Blender (docs/decisions.md no. 23);
## asap knalpot, garis lesat, dan sorot lampu digambar dengan kode.
func _draw_vehicle(p: FighterState, sx: int, floor_y: int) -> void:
	var f := p.facing
	var a := p.attack()
	var moving := a != null and a.lunge_speed != 0 and p.st_frame >= a.lunge_from and p.st_frame <= a.lunge_to
	var cx := sx + f * 10
	if moving:
		for i in 7:
			var age := (sim.tick_count + i * 3) % 21
			var puff := 3 + age / 3
			var px := cx - f * (42 + age * 4)
			var py := floor_y - 12 - age - (i % 3) * 4
			draw_rect(Rect2(px - puff, py - puff, puff * 2, puff * 2), Color(0.82, 0.82, 0.86, 0.5 - age * 0.022))
		for i in 5:
			var length := 24 + (sim.tick_count * 7 + i * 11) % 26
			var lx := cx - f * (50 + (sim.tick_count * 5 + i * 17) % 20)
			draw_rect(Rect2(lx - (length if f == 1 else 0), floor_y - 8 - i * 12, length, 1), Color(1, 1, 1, 0.65))
	# Sorot lampu depan: melebar ke depan, makin pudar.
	for i in 6:
		var bx := cx + f * (40 + i * 11)
		var half := 4 + i * 3
		draw_rect(Rect2(bx - (0 if f == 1 else 11), floor_y - 40 - half, 11, half * 2), Color(1.0, 0.86, 0.4, 0.2 - i * 0.03))
	var tex := p.data.vehicle_texture
	if tex == null:
		draw_rect(Rect2(cx - 24, floor_y - 27, 48, 15), p.data.vehicle_color)
		return
	@warning_ignore("integer_division")
	var frame := (sim.tick_count / (2 if moving else 6)) % 4
	_draw_sheet_frame(tex, frame, Vector2i(96, 64), Vector2(cx, floor_y), f, 63.0)


func _draw_projectile(pr: Dictionary, cam: int, floor_y: int) -> void:
	var r := _to_screen(sim.projectile_rect(pr), cam, floor_y)
	var pd: ProjectileData = sim.fighters[pr["owner"]].data.get_attack(pr["attack"]).projectile
	if pd.texture == null:
		draw_rect(r, C_PROP)
		_outline(r, C_PROP_DARK)
		return
	var center := r.get_center().round()
	var dir: int = pr["dir"]
	var age: int = pr["age"]
	@warning_ignore("integer_division")
	var frame_size := Vector2i(pd.texture.get_width() / pd.frames, pd.texture.get_height())
	# Busur putih dan bayangan pudar di belakang arah terbang, supaya putarannya terbaca.
	for k in 9:
		var ang := age * 0.7 + k * 0.5
		var pt := (center - Vector2(dir * (10 + k * 3), 0) + Vector2(cos(ang), sin(ang)) * (9.0 - k * 0.6)).round()
		draw_rect(Rect2(pt.x, pt.y, 2, 1), Color(1, 1, 1, 0.6 - k * 0.06))
	for k in [3, 2, 1]:
		@warning_ignore("integer_division")
		var ghost_frame := posmod((age - k * 2) / 2, pd.frames)
		_draw_sheet_frame(pd.texture, ghost_frame, frame_size, center - Vector2(dir * k * 8, 0) + Vector2(0, frame_size.y * 0.5),
				dir, frame_size.y, Color(1, 1, 1, 0.14 * (4 - k)))
	@warning_ignore("integer_division")
	var frame := (age / 2) % pd.frames
	var tint := Color.WHITE if not pr["hit_done"] else Color(0.75, 0.75, 0.8)
	_draw_sheet_frame(pd.texture, frame, frame_size, center + Vector2(0, frame_size.y * 0.5), dir, frame_size.y, tint)


# --- Efek --------------------------------------------------------------------

## Garis satu piksel yang digambar titik demi titik, supaya tetap tajam di 480 x 270.
func _pixel_line(from: Vector2, to: Vector2, color: Color) -> void:
	var steps := int(maxf(absf(to.x - from.x), absf(to.y - from.y)))
	for i in steps + 1:
		var pt := from.lerp(to, float(i) / maxf(1.0, steps)).round()
		draw_rect(Rect2(pt.x, pt.y, 1, 1), color)


func _draw_effect(e: Dictionary, cam: int, floor_y: int) -> void:
	var c := Vector2(e["x"] - cam, floor_y + e["y"])
	var age: int = e["age"]
	var life: int = e["life"]
	var fade := 1.0 - float(age) / life
	match e["kind"]:
		&"blunt":
			# Ledakan bintang putih-kuning gaya komik.
			var r := 3 + age * 2
			var core := maxi(2, 10 - age * 2)
			draw_rect(Rect2(c.x - core, c.y - core, core * 2, core * 2), Color.WHITE)
			for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
					Vector2(0.7, 0.7), Vector2(-0.7, 0.7), Vector2(0.7, -0.7), Vector2(-0.7, -0.7)]:
				var pt: Vector2 = (c + d * r).round()
				draw_rect(Rect2(pt.x - 2, pt.y - 2, 4, 4), Color("ffe066") if age < 6 else Color("f08a24"))
		&"slash":
			# Sabetan sabit putih.
			for i in 9:
				var t := float(i) / 8.0 - 0.5
				var pt2 := Vector2(c.x + e["dir"] * (t * 34.0 + age), c.y + t * 26.0 - sin((t + 0.5) * PI) * 8.0).round()
				var s := maxi(1, 5 - absi(i - 4) - age / 4)
				draw_rect(Rect2(pt2.x - s, pt2.y - s, s * 2, s * 2), Color(1, 1, 1, minf(1.0, fade + 0.3)))
		&"block":
			# Perisai biru dengan percikan oranye.
			var r2 := 5 + age
			for d2 in [Vector2(0, -1), Vector2(0.87, -0.5), Vector2(0.87, 0.5), Vector2(0, 1),
					Vector2(-0.87, 0.5), Vector2(-0.87, -0.5)]:
				var pt3: Vector2 = (c + d2 * r2).round()
				draw_rect(Rect2(pt3.x - 2, pt3.y - 2, 4, 4), Color(C_SHIELD, fade))
			draw_rect(Rect2(c.x - e["dir"] * (4 + age * 2) - 1, c.y - 6 - age, 3, 3), Color(C_WARN, fade))
			draw_rect(Rect2(c.x - e["dir"] * (6 + age * 2) - 1, c.y + 3 + age, 3, 3), Color(C_WARN, fade))
		&"impact":
			# Impact flash dan speed lines untuk serangan berat (GDD 9.2).
			var ring := 8 + age * 5
			for k in 12:
				var ang := TAU * k / 12.0
				var pt4: Vector2 = (c + Vector2(cos(ang), sin(ang)) * ring).round()
				draw_rect(Rect2(pt4.x - 1, pt4.y - 1, 3, 3), Color(1, 1, 1, fade))
			var hit_dir: int = e["dir"]
			for li in 5:
				var ll := 46 - age * 3
				var lx := c.x + hit_dir * (16 + age * 14 + li % 2 * 10)
				draw_rect(Rect2(lx if hit_dir == 1 else lx - ll, c.y + (li - 2) * 13, ll, 1 + li % 2),
						Color(1, 1, 1, fade * 0.9))
		&"crack":
			# Retakan kaca saat ultimate kena (GDD 9.2).
			var grow := minf(1.0, age / 6.0)
			var alpha := 1.0 if age < 34 else fade * 2.7
			for ray in CRACK_RAYS:
				var from := c
				for seg in ray:
					var to: Vector2 = (from + Vector2(seg[0], seg[1]) * grow).round()
					_pixel_line(from, to, Color(1, 1, 1, alpha))
					from = to
		&"star5":
			# Notifikasi Bintang 5 jatuh ke atas kepala lawan (GDD 6.7).
			var drop := minf(1.0, age / 10.0)
			var by := c.y - 110 + drop * 56 - (3 if age == 11 or age == 12 else 0)
			var alpha2 := 1.0 if age < life - 14 else fade * 6.0
			var box := Rect2(c.x - 28, by, 56, 14)
			draw_rect(box.grow(1), Color(1.0, 0.82, 0.25, alpha2))
			draw_rect(box, Color(0.08, 0.08, 0.11, alpha2))
			for s5 in 5:
				var star_x := box.position.x + 8 + s5 * 10
				draw_rect(Rect2(star_x - 1, by + 4, 3, 7), Color(1.0, 0.82, 0.25, alpha2))
				draw_rect(Rect2(star_x - 3, by + 6, 7, 3), Color(1.0, 0.82, 0.25, alpha2))
		&"dust":
			for i2 in 3:
				var dx := (i2 - 1) * (4 + age)
				draw_rect(Rect2(c.x + dx - 3, c.y - 3 - age / 2 - i2 % 2 * 2, 6, 4), Color(0.72, 0.68, 0.62, fade * 0.8))
		&"afterimage":
			var d3: FighterData = sim.fighters[e["extra"]].data
			# Petarung yang punya rig memakai bayangan berbentuk badannya (scripts/fighters.gd).
			if d3.rig_scene != null:
				return
			var hr := d3.stand_hurtbox
			var ghost := Rect2(c.x + hr.position.x, c.y + hr.position.y, hr.size.x, hr.size.y)
			draw_rect(ghost, Color(0.4, 1.0, 0.9, fade * 0.55))
			# Garis digital.
			var yy := ghost.position.y + (age * 5) % 12
			while yy < ghost.end.y:
				draw_rect(Rect2(ghost.position.x - 3, yy, ghost.size.x + 6, 1), Color(0.8, 1.0, 1.0, fade * 0.7))
				yy += 12


# --- Debug -------------------------------------------------------------------

func _draw_debug(cam: int, floor_y: int) -> void:
	for p in sim.fighters:
		var hurt := _to_screen(sim.hurtbox_rect(p), cam, floor_y)
		var invul: bool = sim.is_invulnerable(p)
		draw_rect(hurt, Color(C_HURT, 0.08 if invul else 0.22))
		_outline(hurt, Color(C_HURT, 0.4 if invul else 1.0))
		_outline(_to_screen(sim.pushbox_rect(p), cam, floor_y).grow(-2), C_PUSH)
		var a: AttackData = p.attack()
		var label: String = p.state_name()
		if a != null:
			label = "%s %d/%d" % [p.attack_id, p.st_frame, a.total_frames()]
			if a.has_hitbox():
				var hb := _to_screen(sim.hitbox_rect(p, a), cam, floor_y)
				if a.is_active_frame(p.st_frame):
					draw_rect(hb, Color(C_HIT, 0.45))
					_outline(hb, C_HIT)
				else:
					_outline(hb, Color(C_HIT, 0.35))
		elif p.st == St.HITSTUN or p.st == St.BLOCKSTUN:
			label = "%s %d" % [p.state_name(), p.stun]
		@warning_ignore("integer_division")
		var sx: int = p.x / FP - cam
		draw_rect(Rect2(sx - 3, floor_y + p.y / FP, 7, 1), Color.YELLOW)
		draw_rect(Rect2(sx, floor_y + p.y / FP - 3, 1, 7), Color.YELLOW)
		draw_string(_font, Vector2(sx - 40, hurt.position.y - 4), label,
				HORIZONTAL_ALIGNMENT_CENTER, 80, 8, Color.WHITE)
	for pr in sim.projectiles:
		var r := _to_screen(sim.projectile_rect(pr), cam, floor_y)
		_outline(r.grow(1), C_HIT)
