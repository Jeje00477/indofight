extends SceneTree
## Uji ubah tombol: tukar otomatis, tolak tombol menu, simpan dan muat ulang.
## Jalankan: godot --headless --path game -s res://tests/key_bindings_test.gd
## Tombol simpanan pemain dikembalikan seperti semula setelah uji.

const KeyBindings := preload("res://scripts/key_bindings.gd")


func _initialize() -> void:
	KeyBindings.load_saved()
	var before: Array = KeyBindings.keys.duplicate(true)
	var failed := 0
	KeyBindings.reset()

	# P1 pukul ringan diberi tombol P2 pukul ringan (J): keduanya bertukar.
	KeyBindings.assign(0, 4, KEY_J)
	failed += _check(KeyBindings.keys[0][4] == KEY_J and KeyBindings.keys[1][4] == KEY_F, "tukar tombol antarpemain")
	failed += _check(_event_key(&"p1_lp") == KEY_J and _event_key(&"p2_lp") == KEY_F, "Input Map ikut berubah")
	failed += _check(not KeyBindings.assign(0, 4, KEY_ESCAPE) and KeyBindings.keys[0][4] == KEY_J, "Esc ditolak")

	KeyBindings.load_saved()
	failed += _check(KeyBindings.keys[0][4] == KEY_J, "tersimpan dan termuat ulang")

	KeyBindings.reset()
	failed += _check(KeyBindings.keys == KeyBindings.DEFAULTS, "kembali ke bawaan")
	var used := {}
	for p in 2:
		for code in KeyBindings.keys[p]:
			used[code] = true
	failed += _check(used.size() == 22, "bawaan tanpa tombol ganda")

	KeyBindings.keys = before
	KeyBindings.save()
	print("%d pemeriksaan gagal" % failed)
	quit(1 if failed else 0)


func _event_key(action: StringName) -> int:
	return (InputMap.action_get_events(action)[0] as InputEventKey).physical_keycode


func _check(ok: bool, text: String) -> int:
	print(("LOLOS  " if ok else "GAGAL  ") + text)
	return 0 if ok else 1
