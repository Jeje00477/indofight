extends Node2D
## Latar halaman pembuka dan menu utama: Gang Sempit di malam hujan, dengan dua
## petarung yang berlatih jurus di bawah lampu jalan. Semuanya digambar dan
## digerakkan dengan kode dari aset yang sudah ada (docs/decisions.md no. 10 dan 18).

const FLOOR_Y := 238
## Bagian stage yang ditampilkan (piksel dunia dari kiri).
const CAMERA_X := 150
## Posisi lampu jalan di layer latar, untuk cahaya berkedip.
const LAMPS := [Vector2(115, 77), Vector2(369, 102), Vector2(636, 102)]

## Urutan gerak tiap petarung: [animasi, lama dalam frame]. Animasi serangan dimainkan
## sekali selama waktu itu; idle dan win diulang.
const ROUTINES := [
	[["idle", 150], ["hp", 64], ["idle", 110], ["lk", 46], ["idle", 90], ["hk", 72], ["idle", 60], ["win", 96]],
	[["idle", 96], ["lk", 40], ["idle", 130], ["hk", 58], ["idle", 100], ["lp", 26], ["hp", 52], ["idle", 140], ["win", 80]],
]
const LOOPING := ["idle", "win", "walk"]
## Posisi dunia (x) dan arah hadap tiap petarung.
const SPOTS := [[462, 1], [574, -1]]

var stage: StageData
var _rigs: Array = []
var _frame := 0


func setup(p_stage: StageData, roster: Array) -> void:
	stage = p_stage
	for i in mini(2, roster.size()):
		var data: FighterData = roster[i]
		if data.rig_scene == null:
			continue
		var rig: Node2D = data.rig_scene.instantiate()
		add_child(rig)
		_rigs.append(rig)


func _physics_process(_delta: float) -> void:
	if not visible or stage == null:
		return
	_frame += 1
	var cam := _camera()
	for i in _rigs.size():
		var rig: Node2D = _rigs[i]
		rig.position = Vector2(SPOTS[i][0] - cam, FLOOR_Y)
		var step := _routine_step(ROUTINES[i], _frame)
		var anim_name: StringName = StringName(step[0])
		var length: float = rig.animation_length(anim_name)
		var t: float = fposmod(step[1] / 60.0, length) if LOOPING.has(step[0]) else float(step[1]) / step[2] * length
		rig.pose(anim_name, t, SPOTS[i][1], false)
	queue_redraw()


## Kamera bergeser pelan ke kiri dan kanan supaya latar terasa hidup.
func _camera() -> int:
	return CAMERA_X + int(round(sin(_frame / 260.0) * 14.0))


## Langkah yang sedang berjalan di sebuah urutan: [animasi, frame ke berapa, lama].
func _routine_step(routine: Array, frame: int) -> Array:
	var total := 0
	for step in routine:
		total += step[1]
	var f := frame % total
	for step in routine:
		if f < step[1]:
			return [step[0], f, step[1]]
		f -= step[1]
	return [routine[0][0], 0, routine[0][1]]


func _draw() -> void:
	if stage == null or stage.background == null:
		draw_rect(Rect2(0, 0, 4000, 4000), Color("14182e"))
		return
	var size := Vector2i(get_viewport_rect().size)
	var cam := _camera()
	var bg_x := -int(cam * stage.parallax_background)
	draw_rect(Rect2(0, 0, size.x, size.y), stage.sky_top)
	_strip(stage.background, bg_x, 0, size.x)
	if stage.floor_texture != null:
		_strip(stage.floor_texture, -int(cam * stage.parallax_midground), stage.floor_top, size.x)

	# Cahaya lampu jalan yang sesekali meredup.
	for i in LAMPS.size():
		var c: Vector2 = LAMPS[i] + Vector2(bg_x, 0)
		@warning_ignore("integer_division")
		var dim := (_frame / 5 + i * 17) % 41 == 0 or (_frame / 3 + i * 29) % 97 == 0
		var strength := 0.035 if dim else 0.075
		for r in [46, 34, 22, 12]:
			draw_circle(c, r, Color(1.0, 0.72, 0.28, strength))

	# Bayangan petarung.
	for i in _rigs.size():
		draw_rect(Rect2(SPOTS[i][0] - cam - 18, FLOOR_Y - 1, 36, 3), Color(0, 0, 0, 0.4))

	# Hujan: garis pendek miring, dan percikan kecil di jalan.
	for i in 90:
		var x := posmod(i * 53 - _frame * 2 + (i % 7) * 31, size.x + 60) - 30
		var y := posmod(i * 97 + _frame * (8 + i % 3), size.y + 20) - 10
		var a := 0.16 + 0.06 * (i % 3)
		draw_rect(Rect2(x, y, 1, 4), Color(0.74, 0.84, 1.0, a))
		draw_rect(Rect2(x - 1, y + 4, 1, 3), Color(0.74, 0.84, 1.0, a))
	for i in 14:
		var phase := posmod(_frame + i * 9, 26)
		if phase < 6:
			var sx := posmod(i * 71 + (_frame / 26 + i) * 37, size.x)
			var sy := FLOOR_Y - 6 + (i % 5) * 5
			draw_rect(Rect2(sx - phase, sy, 2, 1), Color(0.8, 0.88, 1.0, 0.35 - phase * 0.05))
			draw_rect(Rect2(sx + phase, sy, 2, 1), Color(0.8, 0.88, 1.0, 0.35 - phase * 0.05))

	# Gelap di atas dan kiri supaya logo dan menu terbaca.
	for i in 8:
		draw_rect(Rect2(0, i * 11, size.x, 11), Color(0.02, 0.02, 0.06, 0.62 - i * 0.075))
	for i in 10:
		draw_rect(Rect2(i * 22, 0, 22, size.y), Color(0.02, 0.02, 0.06, 0.6 - i * 0.06))
	draw_rect(Rect2(0, size.y - 20, size.x, 20), Color(0.02, 0.02, 0.06, 0.7))


func _strip(tex: Texture2D, x: int, y: int, view_w: int) -> void:
	var w := tex.get_width()
	while x < view_w:
		draw_texture(tex, Vector2(x, y))
		x += w
