extends Node2D
## Lembar periksa pose rig: menggambar tiap animasi di beberapa titik waktu ke satu gambar.
## Jalankan: godot --path game res://tests/rig_preview.tscn -- --out=FILE.png [--only=nama]

const CELL := Vector2i(150, 150)
const COLS := 9

## [animasi, daftar waktu]
const SHOTS := [
	["idle", [0.0, 0.5]], ["walk", [0.0, 0.15, 0.3, 0.45]], ["jump", [0.0, 0.1, 0.33, 0.58]],
	["crouch", [0.1]], ["dash", [0.08]], ["backdash", [0.08]], ["block", [0.1]],
	["hit", [0.0]], ["ko", [0.0, 0.3, 0.45]], ["getup", [0.2, 0.36]], ["defeat", [0.5]], ["win", [0.0]],
	["lp", [0.6, 1.0]], ["hp", [0.7, 1.0, 2.0]], ["lk", [0.6, 1.0]], ["hk", [0.7, 1.0, 2.0]],
	["skill", [0.7, 1.0]], ["ultimate", [0.5, 1.25]],
]


func _ready() -> void:
	var out := "rig_preview.png"
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.get_slice("=", 1)
		elif arg.begins_with("--only="):
			only = arg.get_slice("=", 1)
	var cells: Array = []
	for character in ["emak-emak", "abang-ojol"]:
		if only != "" and only != character:
			continue
		for shot in SHOTS:
			for t in shot[1]:
				cells.append([character, shot[0], t])
	var rows := ceili(float(cells.size()) / COLS)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(COLS * CELL.x, rows * CELL.y)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(viewport)
	var bg := ColorRect.new()
	bg.color = Color("3c3c46")
	bg.size = viewport.size
	viewport.add_child(bg)
	for i in cells.size():
		var cell: Array = cells[i]
		@warning_ignore("integer_division")
		var origin := Vector2(i % COLS * CELL.x + 56, i / COLS * CELL.y + 140)
		var floor_line := ColorRect.new()
		floor_line.color = Color("6a6a78")
		floor_line.position = origin + Vector2(-56, 0)
		floor_line.size = Vector2(CELL.x - 2, 1)
		viewport.add_child(floor_line)
		var scene: PackedScene = load("res://characters/%s/%s_rig.tscn" % [cell[0], cell[0].replace("-", "_")])
		var rig := scene.instantiate()
		rig.position = origin
		viewport.add_child(rig)
		rig.pose(cell[1], cell[2], 1, false)
		var label := Label.new()
		label.text = "%s %.2f" % [cell[1], cell[2]]
		label.position = origin + Vector2(-54, -140)
		label.add_theme_font_size_override("font_size", 10)
		viewport.add_child(label)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(out)
	print("lembar pose: %s (%d pose)" % [out, cells.size()])
	get_tree().quit()
