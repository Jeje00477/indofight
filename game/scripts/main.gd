extends Node2D
## Penghubung dan alur layar (GDD 3): pembuka, menu utama, pilih petarung, layar versus,
## pertarungan, jeda, dan hasil. Semua aturan kombat ada di scripts/sim/fight_sim.gd
## dan data/. File ini hanya membaca input, memajukan simulasi 60 kali per detik,
## dan meneruskan kejadian ke suara.

const FightSim := preload("res://scripts/sim/fight_sim.gd")
const InputReader := preload("res://scripts/input_reader.gd")
const CpuPlayer := preload("res://scripts/cpu_player.gd")
const KeyBindings := preload("res://scripts/key_bindings.gd")

enum Screen { SPLASH, TITLE, SELECT, VERSUS, FIGHT }
enum Mode { VS_CPU, VS_LOCAL, TRAINING }
enum P2Mode { CPU, DUMMY, DUMMY_BLOCK, PLAYER }

const P2_LABELS := ["komputer", "diam", "selalu block", "pemain 2"]
const MODE_LABELS := ["LAWAN KOMPUTER", "2 PEMAIN", "LATIHAN"]
const TITLE_OPTIONS := ["LAWAN KOMPUTER", "2 PEMAIN", "LATIHAN", "KONTROL", "KELUAR"]
const PAUSE_OPTIONS := ["LANJUT", "KONTROL", "ULANG PERTANDINGAN", "GANTI PETARUNG", "MENU UTAMA"]
const RESULT_OPTIONS := ["MAIN LAGI", "GANTI PETARUNG", "MENU UTAMA"]

## Petarung yang bisa dipilih. Vertical slice: dua karakter (production/vertical-slice.md).
const ROSTER_PATHS := [
	"res://data/fighters/emak_emak.tres",
	"res://data/fighters/abang_ojol.tres",
]
const VERSUS_FRAMES := 120
## Frame layar versus saat tulisan VS dibanting (scripts/menu.gd).
const VS_SLAM := 12
## Jeda setelah pertandingan selesai sebelum menu hasil muncul.
const RESULT_DELAY := 100
## Gerak lambat saat KO: lamanya (frame gambar) dan perlambatannya.
const SLOWMO_FRAMES := 54
const SLOWMO_RATE := 3

@export var rules: MatchRules
@export var stage: StageData

@onready var view: Node2D = $View
@onready var view_front: Node2D = $ViewFront
@onready var fighters: Node2D = $Fighters
@onready var backdrop: Node2D = $Backdrop
@onready var hud: Control = $HudLayer/Hud
@onready var controls: Control = $HudLayer/Controls
@onready var menu: Control = $HudLayer/Menu
@onready var sfx: Node = $Sfx

var sim: FightSim
var roster: Array = []
var screen: int = Screen.SPLASH
var screen_frame := 0
var mode: int = Mode.VS_CPU
## Kursor daftar menu yang sedang tampil.
var cursor := 0
## Indeks roster pilihan P1 dan P2.
var picks := [0, 1]
## 0 = P1 sedang memilih, 1 = P2.
var picking := 0
var p2_mode: int = P2Mode.CPU
## Menu jeda terbuka (Esc).
var game_paused := false
## Jeda debug per frame (F4, F6).
var frame_paused := false
## Daftar kontrol sedang terbuka. Pertarungan berhenti sampai ditutup dengan tombol apa saja.
var controls_open := false

var _step_once := false
var _cpu := CpuPlayer.new(777)
var _cpu_p1 := CpuPlayer.new(4242)
var _frames := 0

# Opsi baris perintah untuk uji otomatis, ditulis setelah "--":
#   --demo             langsung bertarung, kedua petarung dimainkan komputer
#   --screen=NAMA      mulai di layar title, select, versus, atau training (bawaan: pembuka)
#   --pause-at=N       buka menu jeda di tick N
#   --boxes            kotak hitbox tampil sejak awal
#   --help-panel       daftar kontrol terbuka sejak awal
#   --no-help          daftar kontrol tidak dibuka otomatis di latihan
#   --speed=N          N tick simulasi per frame gambar
#   --shot=FILE.png    simpan tangkapan layar lalu keluar
#   --shot-at=A,B,C    tick saat tangkapan diambil (FILE_1.png, FILE_2.png, ...)
#   --shot-on=E+N,...  ambil tangkapan N tick setelah kejadian E pertama (mis. hit_heavy+2)
#   --shot-frame=N     ambil tangkapan di frame ke-N sejak game dibuka (untuk layar menu)
#   --max-ticks=N      keluar setelah N tick
#   --auto-ult=P       pemain P (0 atau 1) menekan ultimate otomatis di awal ronde
var _demo := false
var _speed := 1
var _shot_path := ""
var _shot_ticks: Array = []
var _shots_taken := 0
## Tiap isi: [kejadian, jeda tick, sudah terjadi].
var _shot_on: Array = []
var _shot_frame := 0
var _pause_at := 0
var _max_ticks := 0
var _auto_ult := -1
var _no_help := false
## Daftar kontrol hanya dibuka otomatis sekali, saat pertama masuk latihan.
var _controls_shown := false
var _busy := false
## Sisa frame gerak lambat setelah pukulan KO.
var _slowmo := 0


func _ready() -> void:
	# Tanpa penggabungan input, supaya waktu tekan tombol tidak bergeser (skill godot-genre-fighting).
	Input.use_accumulated_input = false
	KeyBindings.load_saved()
	for path in ROSTER_PATHS:
		roster.append(load(path))
	sim = FightSim.new()
	sim.setup(rules, stage, [roster[0], roster[1]])
	view.sim = sim
	view_front.sim = sim
	fighters.sim = sim
	fighters.view = view
	hud.sim = sim
	menu.main = self
	backdrop.setup(stage, roster)
	_parse_args()
	_fit_window()
	if _demo:
		_start_fight()
	else:
		_sync()


## Bila jendela 1920 x 1080 tidak muat di layar, pakai kelipatan bulat 480 x 270
## terbesar yang muat, supaya piksel tetap tajam dan rasio tetap 16:9.
func _fit_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var win := get_window()
	if win.mode != Window.MODE_WINDOWED:
		return
	var base := Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"))
	var usable := DisplayServer.screen_get_usable_rect(win.current_screen)
	var factor := mini(usable.size.x / base.x, (usable.size.y - 48) / base.y)
	factor = clampi(factor, 1, 4)
	win.size = base * factor
	win.position = usable.position + (usable.size - win.size) / 2


func _parse_args() -> void:
	# Latihan dimulai setelah semua opsi dibaca, supaya urutan opsi tidak berpengaruh.
	var start_training := false
	for arg in OS.get_cmdline_user_args():
		var value := arg.get_slice("=", 1)
		if arg == "--demo":
			_demo = true
		elif arg == "--boxes":
			view_front.show_boxes = true
		elif arg == "--help-panel":
			controls_open = true
		elif arg == "--no-help":
			_no_help = true
		elif arg.begins_with("--screen="):
			match value:
				"title":
					screen = Screen.TITLE
				"select":
					screen = Screen.SELECT
				"versus":
					screen = Screen.VERSUS
				"training":
					start_training = true
		elif arg.begins_with("--speed="):
			_speed = maxi(1, int(value))
		elif arg.begins_with("--shot="):
			_shot_path = value
		elif arg.begins_with("--shot-at="):
			for t in value.split(","):
				_shot_ticks.append(int(t))
		elif arg.begins_with("--shot-on="):
			for item in value.split(","):
				_shot_on.append([StringName(item.get_slice("+", 0)), int(item.get_slice("+", 1)), false])
		elif arg.begins_with("--shot-frame="):
			_shot_frame = int(value)
		elif arg.begins_with("--pause-at="):
			_pause_at = int(value)
		elif arg.begins_with("--max-ticks="):
			_max_ticks = int(value)
		elif arg.begins_with("--auto-ult="):
			_auto_ult = int(value)
	if start_training:
		mode = Mode.TRAINING
		_start_fight()


# --- Alur layar --------------------------------------------------------------

func _go(next_screen: int) -> void:
	screen = next_screen
	screen_frame = 0
	cursor = 0
	game_paused = false
	_sync()


func _start_fight() -> void:
	var d1: FighterData = roster[picks[0]]
	var d2: FighterData = roster[picks[1]]
	if picks[0] == picks[1]:
		# Petarung sama: P2 diberi warna lebih gelap supaya bisa dibedakan.
		d2 = d2.duplicate()
		d2.color = d2.color.darkened(0.4)
		d2.accent = d2.accent.darkened(0.35)
		d2.tint = Color(0.62, 0.66, 0.9)
	sim.setup(rules, stage, [d1, d2])
	sim.training = mode == Mode.TRAINING
	match mode:
		Mode.VS_CPU:
			p2_mode = P2Mode.CPU
		Mode.VS_LOCAL:
			p2_mode = P2Mode.PLAYER
		Mode.TRAINING:
			p2_mode = P2Mode.DUMMY
	_cpu = CpuPlayer.new(777 + _frames)
	hud.reset()
	_slowmo = 0
	# Pertama kali masuk latihan, daftar kontrol dibuka dulu. Tombol apa saja menutupnya.
	if mode == Mode.TRAINING and not _no_help and not _controls_shown:
		controls_open = true
		_controls_shown = true
	frame_paused = false
	_go(Screen.FIGHT)


## Menu yang sedang menutupi pertarungan: jeda, hasil, atau tidak ada.
func overlay() -> StringName:
	if screen != Screen.FIGHT:
		return &""
	if game_paused:
		return &"pause"
	if sim.phase == FightSim.Phase.MATCH_END and sim.phase_frame > RESULT_DELAY:
		return &"result"
	return &""


func overlay_options() -> Array:
	match overlay():
		&"pause":
			return PAUSE_OPTIONS
		&"result":
			return RESULT_OPTIONS
	return []


func _sync() -> void:
	var in_menu := screen == Screen.SPLASH or screen == Screen.TITLE
	backdrop.visible = in_menu
	view.visible = not in_menu
	view_front.visible = not in_menu
	fighters.visible = not in_menu
	controls.visible = controls_open
	hud.visible = screen == Screen.FIGHT
	hud.p2_mode_label = P2_LABELS[p2_mode]
	hud.mode_label = MODE_LABELS[mode]
	hud.paused = frame_paused
	hud.result_menu = overlay() == &"result"


func _choose(option: String) -> void:
	match option:
		"LAWAN KOMPUTER":
			mode = Mode.VS_CPU
			picking = 0
			_go(Screen.SELECT)
		"2 PEMAIN":
			mode = Mode.VS_LOCAL
			picking = 0
			_go(Screen.SELECT)
		"LATIHAN":
			mode = Mode.TRAINING
			picking = 0
			_go(Screen.SELECT)
		"KONTROL":
			controls_open = true
		"KELUAR":
			get_tree().quit()
		"LANJUT":
			game_paused = false
		"ULANG PERTANDINGAN", "MAIN LAGI":
			game_paused = false
			cursor = 0
			_reset_match()
		"GANTI PETARUNG":
			picking = 0
			_go(Screen.SELECT)
		"MENU UTAMA":
			_go(Screen.TITLE)


func _reset_match() -> void:
	sim.reset_match()
	hud.reset()
	# Gerak lambat KO pertandingan lama tidak boleh terbawa ke intro baru.
	_slowmo = 0


# --- Input menu --------------------------------------------------------------

func _nav_of(keycode: int) -> StringName:
	match keycode:
		KEY_W, KEY_UP:
			return &"up"
		KEY_S, KEY_DOWN:
			return &"down"
		KEY_A, KEY_LEFT:
			return &"left"
		KEY_D, KEY_RIGHT:
			return &"right"
		KEY_J, KEY_F, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			return &"ok"
		KEY_K, KEY_G, KEY_ESCAPE, KEY_BACKSPACE:
			return &"back"
	return &""


func _move_cursor(count: int, delta: int) -> void:
	cursor = posmod(cursor + delta, count)
	sfx.play(&"catch")


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_F11:
		var win := get_window()
		win.mode = Window.MODE_WINDOWED if win.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
		return
	if controls_open:
		if controls.handle_key(key):
			controls_open = false
			sfx.play(&"block")
		else:
			sfx.play(&"catch")
		_sync()
		return
	var nav := _nav_of(key.keycode)
	match screen:
		Screen.SPLASH:
			sfx.play(&"fight")
			_go(Screen.TITLE)
		Screen.TITLE:
			if nav == &"up":
				_move_cursor(TITLE_OPTIONS.size(), -1)
			elif nav == &"down":
				_move_cursor(TITLE_OPTIONS.size(), 1)
			elif nav == &"ok":
				sfx.play(&"fight")
				_choose(TITLE_OPTIONS[cursor])
		Screen.SELECT:
			if nav == &"left" or nav == &"right":
				picks[picking] = posmod(picks[picking] + (-1 if nav == &"left" else 1), roster.size())
				sfx.play(&"catch")
			elif nav == &"ok":
				sfx.play(&"fight")
				if picking == 0:
					picking = 1
				else:
					_go(Screen.VERSUS)
			elif nav == &"back":
				sfx.play(&"block")
				if picking == 1:
					picking = 0
				else:
					_go(Screen.TITLE)
		Screen.VERSUS:
			if nav == &"ok" and screen_frame > 10:
				_start_fight()
		Screen.FIGHT:
			_fight_key(key.keycode, nav)
	_sync()


func _fight_key(keycode: int, nav: StringName) -> void:
	var options := overlay_options()
	if not options.is_empty():
		if nav == &"up":
			_move_cursor(options.size(), -1)
		elif nav == &"down":
			_move_cursor(options.size(), 1)
		elif nav == &"ok":
			sfx.play(&"fight")
			_choose(options[cursor])
		elif nav == &"back" and game_paused:
			game_paused = false
		return
	match keycode:
		KEY_ESCAPE:
			game_paused = true
			cursor = 0
			sfx.play(&"block")
		KEY_F1:
			view_front.show_boxes = not view_front.show_boxes
		KEY_F2:
			p2_mode = (p2_mode + 1) % P2_LABELS.size()
		KEY_F3:
			controls_open = true
		KEY_F4:
			frame_paused = not frame_paused
		KEY_F5:
			_reset_match()
		KEY_F6:
			frame_paused = true
			_step_once = true


# --- Simulasi ----------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	if _busy:
		return
	_frames += 1
	screen_frame += 1
	if _shot_frame > 0 and _frames >= _shot_frame:
		_shot_frame = 0
		_take_shot()
		return
	if screen == Screen.VERSUS and screen_frame == 1:
		sfx.play(&"whoosh_heavy")
	if screen == Screen.VERSUS and screen_frame == VS_SLAM:
		sfx.play(&"hit_heavy")
	if screen == Screen.VERSUS and screen_frame >= VERSUS_FRAMES:
		_start_fight()
	if screen != Screen.FIGHT or game_paused or controls_open:
		return
	if frame_paused and not _step_once:
		return
	_step_once = false
	# Gerak lambat sesaat setelah pukulan KO: simulasi hanya maju satu tick tiap SLOWMO_RATE
	# frame gambar. Simulasinya sendiri tidak berubah, jadi tetap deterministik.
	if _slowmo > 0 and _speed == 1:
		_slowmo -= 1
		if _slowmo % SLOWMO_RATE != 0:
			_sync()
			return
	for n in _speed:
		_tick()
		if sim.events.has(&"ko") and not _demo_fast():
			_slowmo = SLOWMO_FRAMES
		for entry in _shot_on:
			if not entry[2] and sim.events.has(entry[0]):
				entry[2] = true
				_shot_ticks.append(sim.tick_count + entry[1])
				_shot_ticks.sort()
		if _shots_taken < _shot_ticks.size() and sim.tick_count >= _shot_ticks[_shots_taken]:
			_take_shot()
			return
		if _pause_at > 0 and sim.tick_count >= _pause_at:
			_pause_at = 0
			game_paused = true
			return
		if _max_ticks > 0 and sim.tick_count >= _max_ticks:
			get_tree().quit()
			return
	_sync()


## Uji otomatis yang dipercepat tidak memakai gerak lambat.
func _demo_fast() -> bool:
	return _speed > 1


func _tick() -> void:
	var in1: int = _cpu_p1.decide(sim, 0) if _demo else InputReader.read(0)
	# Main sendiri: tombol pemain 2 ikut menggerakkan pemain 1, jadi panah dan J K U I tetap bisa dipakai.
	if not _demo and p2_mode != P2Mode.PLAYER:
		in1 |= InputReader.read(1)
	var in2 := 0
	match p2_mode:
		P2Mode.CPU:
			in2 = _cpu.decide(sim, 1)
		P2Mode.DUMMY_BLOCK:
			in2 = FightSim.IN_BLOCK
		P2Mode.PLAYER:
			in2 = InputReader.read(1)
	if _auto_ult >= 0 and sim.phase == FightSim.Phase.FIGHT and sim.phase_frame == 20:
		if _auto_ult == 0:
			in1 |= FightSim.IN_ULT
		else:
			in2 |= FightSim.IN_ULT
	sim.tick([in1, in2])
	for e in sim.events:
		sfx.play(e)


func _take_shot() -> void:
	_busy = true
	_shots_taken += 1
	_sync()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := _shot_path
	if _shot_ticks.size() > 1 or not _shot_on.is_empty():
		path = "%s_%d.png" % [_shot_path.trim_suffix(".png"), _shots_taken]
	img.save_png(path)
	print("tangkapan layar tick %d: %s (%d x %d)" % [sim.tick_count, path, img.get_width(), img.get_height()])
	var waiting := _shot_on.any(func(entry): return not entry[2])
	if _shots_taken >= _shot_ticks.size() and not waiting:
		get_tree().quit()
		return
	_busy = false
