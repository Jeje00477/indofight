extends RefCounted
## Tombol keyboard tiap pemain: bawaan, ubah, simpan, dan muat (docs/decisions.md no. 26).
## Saat game dibuka, load_saved() mengisi ulang Input Map Godot dari file simpanan atau bawaan,
## jadi daftar tombol p1_ dan p2_ di project.godot hanya cadangan.
##
## Bawaan dibuat supaya dua orang muat di satu keyboard laptop tanpa numpad:
## pemain 1 di sisi kiri, pemain 2 di panah dan huruf sebelah kanan.

const PATH := "user://kontrol.cfg"

## Urutan sama dengan InputReader.SUFFIXES (bit simulasi).
const ACTIONS := ["left", "right", "up", "down", "lp", "hp", "lk", "hk", "block", "skill", "ultimate"]
const LABELS := ["Kiri", "Kanan", "Lompat", "Jongkok", "Pukul ringan", "Pukul berat", "Tendang ringan",
	"Tendang berat", "Tahan", "Skill", "Ultimate"]

const DEFAULTS := [
	[KEY_A, KEY_D, KEY_W, KEY_S, KEY_F, KEY_G, KEY_R, KEY_T, KEY_H, KEY_Y, KEY_B],
	[KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_J, KEY_K, KEY_U, KEY_I, KEY_L, KEY_O, KEY_P],
]

## Tombol yang tidak boleh dipakai bertarung karena sudah dipakai menu dan alat uji.
const RESERVED := [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_BACKSPACE, KEY_F1, KEY_F2, KEY_F3, KEY_F4,
	KEY_F5, KEY_F6, KEY_F11]

## [pemain][aksi] -> physical keycode.
static var keys: Array = []


static func load_saved() -> void:
	keys = DEFAULTS.duplicate(true)
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for p in 2:
			for a in ACTIONS.size():
				var code: int = cfg.get_value("p%d" % (p + 1), ACTIONS[a], keys[p][a])
				if code > 0 and not RESERVED.has(code):
					keys[p][a] = code
	_apply()


## Pasang tombol baru. Bila tombol itu sudah dipakai aksi lain (pemain mana pun), keduanya
## bertukar, jadi tidak pernah ada satu tombol untuk dua aksi.
static func assign(player: int, action: int, code: int) -> bool:
	if RESERVED.has(code):
		return false
	var old: int = keys[player][action]
	for p in 2:
		for a in ACTIONS.size():
			if keys[p][a] == code:
				keys[p][a] = old
	keys[player][action] = code
	_apply()
	save()
	return true


static func reset() -> void:
	keys = DEFAULTS.duplicate(true)
	_apply()
	save()


static func save() -> void:
	var cfg := ConfigFile.new()
	for p in 2:
		for a in ACTIONS.size():
			cfg.set_value("p%d" % (p + 1), ACTIONS[a], keys[p][a])
	cfg.save(PATH)


## Nama tombol untuk ditampilkan, menurut tata letak keyboard pemain.
static func label(code: int) -> String:
	var shown := DisplayServer.keyboard_get_keycode_from_physical(code)
	var text := OS.get_keycode_string(shown if shown != KEY_NONE else code)
	return {"Left": "Kiri", "Right": "Kanan", "Up": "Atas", "Down": "Bawah", "Space": "Spasi",
		"Shift": "Shift", "Ctrl": "Ctrl"}.get(text, text)


static func _apply() -> void:
	for p in 2:
		for a in ACTIONS.size():
			var action := StringName("p%d_%s" % [p + 1, ACTIONS[a]])
			if not InputMap.has_action(action):
				InputMap.add_action(action, 0.5)
			InputMap.action_erase_events(action)
			var ev := InputEventKey.new()
			ev.physical_keycode = keys[p][a]
			InputMap.action_add_event(action, ev)
