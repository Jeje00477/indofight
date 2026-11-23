extends Control
## Layar menu yang digambar dengan kode (docs/decisions.md no. 10): menu utama,
## pilih petarung, layar versus, menu jeda, dan menu hasil.
## Hanya menggambar; keadaan dan input diurus scripts/main.gd.

const C_FRAME := Color("14151c")
const C_EDGE := Color("8a8f9c")
const C_TEXT := Color("f4f4f4")
const C_DIM := Color("9aa0ad")
const C_GOLD := Color("ffd23f")
const C_RED := Color("e23b3b")
const C_BLUE := Color("2bc8ff")
const C_SHADOW := Color("101018")

const UiFont := preload("res://scripts/ui_font.gd")

## Node Main. Tidak diberi tipe supaya tidak saling memuat dengan main.gd.
var main

var _font: Font

## Kemiringan garis tengah layar versus: setengah selisih x antara atas dan bawah.
const VS_SLANT := 36.0
## Latar dan rig layar versus, hanya ada selama layar itu tampil.
var _vs_back: Node2D
var _vs_rigs: Array = []


func _ready() -> void:
	_font = UiFont.get_font()


func _process(_delta: float) -> void:
	if main != null:
		_update_versus()
	queue_redraw()


func _text(pos: Vector2, text: String, font_size: int, color: Color,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1) -> void:
	for off in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1), Vector2(1, 1)]:
		draw_string(_font, pos + off, text, align, width, font_size, C_SHADOW)
	draw_string(_font, pos, text, align, width, font_size, color)


func _panel(r: Rect2) -> void:
	draw_rect(r.grow(2), C_EDGE)
	draw_rect(r.grow(1), C_FRAME)
	draw_rect(r, Color(C_FRAME.lightened(0.06), 1.0))


## Gambar dasar petarung berdiri di dasar kotak `r`, pada ukuran piksel aslinya.
## Bila gambarnya belum ada, digambar kotak berwarna sebagai pengganti.
func _figure(r: Rect2, data: FighterData, facing: int) -> void:
	var cx := roundf(r.get_center().x)
	if data.portrait != null:
		# Menghadap kiri: gambar dicerminkan lewat transform, bukan digambar ulang.
		draw_set_transform(Vector2(cx, r.end.y - 151), 0.0, Vector2(facing, 1))
		draw_texture_rect(data.portrait, Rect2(-80, 0, 160, 160), false, data.tint)
		draw_set_transform(Vector2.ZERO)
		return
	draw_rect(r, data.color)
	draw_rect(Rect2(r.position.x - 1, r.position.y, r.size.x + 2, roundf(r.size.y * 0.2)), data.accent)


## Potongan kepala dari gambar dasar, untuk ikon grid.
func _face(r: Rect2, data: FighterData) -> void:
	if data.portrait != null:
		draw_texture_rect_region(data.portrait, Rect2(r.position.x + 7, r.position.y + 6, 34, 36), Rect2(63, 46, 34, 36))
	else:
		draw_rect(r.grow(-10), data.color)


func _list(options: Array, cursor: int, center_x: float, top: float, line_h: int = 18) -> void:
	for i in options.size():
		var y := top + i * line_h
		var selected := i == cursor
		if selected:
			draw_rect(Rect2(center_x - 100, y - 13, 200, 17), Color(C_GOLD, 0.16))
			draw_rect(Rect2(center_x - 100, y - 13, 3, 17), C_GOLD)
		_text(Vector2(center_x - 110, y), options[i], UiFont.NORMAL, C_GOLD if selected else C_TEXT,
				HORIZONTAL_ALIGNMENT_CENTER, 220)


func _draw() -> void:
	if main == null:
		return
	var w := size.x
	var h := size.y
	match main.screen:
		main.Screen.SPLASH:
			_draw_splash(w, h)
		main.Screen.TITLE:
			_draw_title(w, h)
		main.Screen.SELECT:
			_draw_select(w, h)
		main.Screen.VERSUS:
			_draw_versus(w, h)
		main.Screen.FIGHT:
			_draw_overlay(w, h)


## Logo huruf demi huruf: tiap huruf jatuh masuk bergiliran, lalu kilau berjalan melintas.
func _logo(pos: Vector2, font_size: int, frame: int) -> void:
	var text := "INDOFIGHT"
	var x := pos.x
	for i in text.length():
		var ch := text[i]
		var t := clampf((frame - i * 3) / 12.0, 0.0, 1.0)
		var drop := roundf(-70.0 * (1.0 - t) * (1.0 - t))
		@warning_ignore("integer_division")
		var shine := (frame / 3) % 54 == i + 12
		var col := Color.WHITE if shine else C_GOLD
		if t > 0.0:
			for off in [Vector2(3, 3), Vector2(2, 2)]:
				draw_string(_font, Vector2(x, pos.y + drop) + off, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, C_RED.darkened(0.45))
			for off in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
				draw_string(_font, Vector2(x, pos.y + drop) + off, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, C_SHADOW)
			draw_string(_font, Vector2(x, pos.y + drop), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
		x += _font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


func _logo_width(font_size: int) -> float:
	return _font.get_string_size("INDOFIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


## Halaman pembuka: logo besar di atas latar Gang Sempit, menunggu tombol apa saja.
func _draw_splash(w: float, h: float) -> void:
	var frame: int = main.screen_frame
	var fs := 64
	var lw := _logo_width(fs)
	var x := roundf((w - lw) * 0.5)
	var line_t := clampf((frame - 34) / 16.0, 0.0, 1.0)
	_logo(Vector2(x, 84), fs, frame)
	draw_rect(Rect2(roundf(w * 0.5 - lw * 0.5 * line_t), 94, roundf(lw * line_t), 3), C_RED)
	draw_rect(Rect2(roundf(w * 0.5 - lw * 0.5 * line_t), 97, roundf(lw * line_t), 1), C_GOLD)
	if frame > 50 and frame % 60 < 40:
		_text(Vector2(0, h - 34), "TEKAN TOMBOL APA SAJA", UiFont.MEDIUM, C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, w)
	_text(Vector2(0, h - 6), "vertical slice", UiFont.SMALL, C_DIM, HORIZONTAL_ALIGNMENT_RIGHT, w - 8)


const TITLE_NOTES := {
	"LAWAN KOMPUTER": "Bertarung best of 3 melawan komputer",
	"2 PEMAIN": "Dua pemain di satu keyboard",
	"LATIHAN": "Berlatih jurus: health dan ultimate selalu terisi",
	"KONTROL": "Lihat dan ubah tombol",
	"KELUAR": "Tutup game",
}


## Menu utama (GDD 5.1): logo di atas, pilihan tersusun vertikal di kiri, latar beranimasi.
func _draw_title(w: float, h: float) -> void:
	var frame: int = main.screen_frame
	_logo(Vector2(22, 58), 44, frame + 60)
	draw_rect(Rect2(22, 66, _logo_width(44), 3), C_RED)
	draw_rect(Rect2(22, 69, _logo_width(44), 1), C_GOLD)
	var slide := roundf(-230.0 * pow(1.0 - clampf(frame / 14.0, 0.0, 1.0), 2.0))
	var options: Array = main.TITLE_OPTIONS
	for i in options.size():
		var y := 106.0 + i * 24.0
		var selected: bool = i == main.cursor
		var x := 26.0 + slide + (8.0 if selected else 0.0)
		if selected:
			draw_rect(Rect2(slide, y - 16, 214, 22), Color(C_RED.darkened(0.35), 0.82))
			draw_rect(Rect2(slide, y - 16, 5, 22), C_GOLD)
			draw_rect(Rect2(slide + 214, y - 16, 2, 22), C_GOLD)
		_text(Vector2(x, y), options[i], UiFont.MEDIUM, C_GOLD if selected else C_TEXT)
	_text(Vector2(26, h - 6), TITLE_NOTES.get(options[main.cursor], ""), UiFont.SMALL, C_TEXT)
	_text(Vector2(0, h - 6), "W / S pilih     J atau Enter: OK", UiFont.SMALL, C_DIM, HORIZONTAL_ALIGNMENT_RIGHT, w - 8)


func _draw_select(w: float, h: float) -> void:
	draw_rect(Rect2(0, 0, w, h), Color(0.03, 0.03, 0.07, 0.9))
	_text(Vector2(0, 24), "PILIH PETARUNG", 16, C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, w)
	_text(Vector2(0, 40), main.MODE_LABELS[main.mode], UiFont.SMALL, C_DIM, HORIZONTAL_ALIGNMENT_CENTER, w)
	var colors := [C_RED, C_BLUE]
	# Preview besar P1 di kiri dan P2 di kanan (GDD 5.2).
	for side in 2:
		var data: FighterData = main.roster[main.picks[side]]
		var active: bool = main.picking == side
		var px := 58.0 if side == 0 else w - 58.0
		var decided: bool = side < main.picking
		var body := Rect2(px - 24, 62, 48, 120)
		if active or decided:
			var bob := 0.0 if decided else roundf(sin(main.screen_frame * 0.12) * 2.0)
			body.position.y += bob
			_figure(body, data, 1 if side == 0 else -1)
			_text(Vector2(px - 70, 202), data.display_name, 16, colors[side], HORIZONTAL_ALIGNMENT_CENTER, 140)
			_text(Vector2(px - 70, 218), "health %d   jalan %d" % [data.max_health, data.walk_forward_speed], UiFont.SMALL,
					C_DIM, HORIZONTAL_ALIGNMENT_CENTER, 140)
		else:
			draw_rect(body, Color(C_EDGE, 0.15))
			_text(Vector2(px - 70, 130), "?", 32, C_DIM, HORIZONTAL_ALIGNMENT_CENTER, 140)
		_text(Vector2(px - 70, 57), "P%d" % (side + 1), UiFont.NORMAL, colors[side], HORIZONTAL_ALIGNMENT_CENTER, 140)
	# Grid ikon di tengah.
	var n: int = main.roster.size()
	var cell := 48.0
	var gap := 10.0
	var gx := w * 0.5 - (n * cell + (n - 1) * gap) * 0.5
	for i in n:
		var d: FighterData = main.roster[i]
		var r := Rect2(gx + i * (cell + gap), 96, cell, cell)
		_panel(r)
		_face(r, d)
		for side in 2:
			var show_cursor: bool = main.picks[side] == i and side <= main.picking
			if show_cursor:
				var grow := 3.0 + side * 3.0
				var c: Color = colors[side]
				var o := r.grow(grow)
				for edge in [Rect2(o.position.x, o.position.y, o.size.x, 2), Rect2(o.position.x, o.end.y - 2, o.size.x, 2),
						Rect2(o.position.x, o.position.y, 2, o.size.y), Rect2(o.end.x - 2, o.position.y, 2, o.size.y)]:
					draw_rect(edge, c)
				_text(Vector2(o.position.x, o.position.y - 3 if side == 0 else o.end.y + 10), "P%d" % (side + 1), UiFont.SMALL, c)
	var who := "P1" if main.picking == 0 else "P2"
	if main.picking == 1 and main.mode != main.Mode.VS_LOCAL:
		who = "lawan"
	_text(Vector2(0, 178), "Pilih %s" % who, UiFont.NORMAL, C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, w)
	_text(Vector2(0, h - 10), "A / D pilih     J atau Enter: OK     K atau Esc: kembali", UiFont.SMALL, C_DIM,
			HORIZONTAL_ALIGNMENT_CENTER, w)


## Layar versus (docs/decisions.md no. 27). Dua sisi miring masuk dari samping, lalu di
## frame VS_SLAM tulisan VS dibanting ke tengah dengan kilat putih, guncangan, dan percikan.
## Setelah itu latar terus bergerak (garis miring, sinar berputar, bara naik, kilat di garis
## tengah) sampai layar memutih masuk ke pertarungan. Petarung tampil dengan rig beranimasi.
func _draw_versus(w: float, h: float) -> void:
	var t: int = main.screen_frame
	var slam: int = main.VS_SLAM
	var off := _vs_offset(t, w)
	var half := w * 0.5
	for i in 2:
		if _vs_rigs.size() > i and _vs_rigs[i] == null:
			var d: FighterData = main.roster[main.picks[i]]
			var side := -1.0 if i == 0 else 1.0
			_figure(Rect2(half + side * (w * 0.25 + off) - 30, h - 210, 60, 150), d, 1 if i == 0 else -1)
	# Garis tengah: emas tebal, ditambah kilat yang berkedip setelah VS dibanting.
	var top := Vector2(half + VS_SLANT, 0)
	var bottom := Vector2(half - VS_SLANT, h)
	var line_col := C_GOLD if t >= slam else Color(C_GOLD, clampf(t / float(slam), 0.0, 1.0))
	draw_colored_polygon(PackedVector2Array([top - Vector2(3, 0), top + Vector2(3, 0), bottom + Vector2(3, 0),
			bottom - Vector2(3, 0)]), line_col)
	if t >= slam and t % 6 < 4:
		var pts := PackedVector2Array()
		for k in 15:
			pts.append(top.lerp(bottom, k / 14.0) + Vector2((_rnd(k + t * 31) - 0.5) * 14.0, 0).round())
		draw_polyline(pts, Color(0.85, 0.97, 1.0), 1.0)
	# Bara api naik di kedua sisi.
	for k in 36:
		var speed := 0.6 + _rnd(k * 3) * 1.4
		var ex := roundf(_rnd(k * 7) * w + sin((t + k * 9) * 0.08) * 3.0)
		var ey := roundf(h - fposmod(t * speed + _rnd(k * 11) * h, h + 20.0))
		var ember := C_GOLD if k % 3 else C_RED.lightened(0.2)
		draw_rect(Rect2(ex, ey, 1 + k % 2, 1 + k % 2), Color(ember, 0.75))
	# Papan nama miring, masuk dari luar layar.
	for i in 2:
		var d: FighterData = main.roster[main.picks[i]]
		var e := 1.0 - pow(1.0 - clampf((t - slam - 4 - i * 3) / 10.0, 0.0, 1.0), 3.0)
		var bx := roundf(-180.0 + 192.0 * e) if i == 0 else roundf(w + 12.0 - 192.0 * e)
		var by := h - 62.0
		var plate := PackedVector2Array([Vector2(bx, by), Vector2(bx + 176, by), Vector2(bx + 168, by + 34),
				Vector2(bx - 8, by + 34)])
		draw_colored_polygon(plate, Color(C_SHADOW, 0.85))
		draw_rect(Rect2(bx, by, 176, 2), d.color.lightened(0.3))
		_text(Vector2(bx + 8, by + 17), d.display_name, UiFont.LARGE, C_TEXT)
		if d.ultimate != null:
			_text(Vector2(bx + 8, by + 30), "ULTIMATE: " + d.ultimate.display_name, UiFont.SMALL, C_GOLD)
	# VS dibanting: mengecil dari besar ke ukuran akhir, lalu cincin dan percikan memancar.
	if t >= slam:
		var age := t - slam
		var fs := int(lerpf(96.0, 44.0, clampf(age / 5.0, 0.0, 1.0)))
		var vs_w := _font.get_string_size("VS", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var vs_pos := Vector2(roundf(half - vs_w * 0.5), roundf(h * 0.5 + fs * 0.32))
		for o in [Vector2(4, 4), Vector2(3, 3), Vector2(2, 2)]:
			draw_string(_font, vs_pos + o, "VS", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, C_RED.darkened(0.3))
		for o in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			draw_string(_font, vs_pos + o, "VS", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, C_SHADOW)
		@warning_ignore("integer_division")
		var shine := age < 3 or (t / 4) % 20 == 0
		draw_string(_font, vs_pos, "VS", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE if shine else C_GOLD)
		if age < 24:
			draw_arc(Vector2(half, h * 0.5), 10.0 + age * 9.0, 0.0, TAU, 40, Color(1, 1, 1, 1.0 - age / 24.0), 2.0)
		if age < 34:
			for k in 28:
				var ang := _rnd(k * 5) * TAU
				var dist := (1.6 + _rnd(k * 13) * 3.4) * age
				var p := Vector2(half, h * 0.5) + Vector2(cos(ang), sin(ang)) * dist + Vector2(0, age * age * 0.05)
				draw_rect(Rect2(p.round(), Vector2(2, 2)), Color(C_GOLD if k % 2 else Color.WHITE, 1.0 - age / 34.0))
	# Bilah hitam sinematik di atas dan bawah.
	var bar := roundf(16.0 * clampf(t / 8.0, 0.0, 1.0))
	draw_rect(Rect2(0, 0, w, bar), Color.BLACK)
	draw_rect(Rect2(0, h - bar, w, bar), Color.BLACK)
	_text(Vector2(0, h - 4), "RONDE 1   " + main.stage.display_name, UiFont.SMALL, C_DIM, HORIZONTAL_ALIGNMENT_CENTER, w)
	# Kilat putih saat VS dibanting, dan layar memutih sebelum masuk pertarungan.
	var flash := 0.0
	if t >= slam and t < slam + 6:
		flash = 1.0 - (t - slam) / 6.0
	flash = maxf(flash, clampf((t - main.VERSUS_FRAMES + 12) / 12.0, 0.0, 1.0))
	if flash > 0.0:
		draw_rect(Rect2(0, 0, w, h), Color(1, 1, 1, flash))


## Latar versus, digambar di belakang rig petarung.
func _draw_versus_back() -> void:
	var c := _vs_back
	var w := size.x
	var h := size.y
	var t: int = main.screen_frame
	var off := _vs_offset(t, w)
	var half := w * 0.5
	c.draw_rect(Rect2(0, 0, w, h), Color(0.02, 0.02, 0.05))
	for i in 2:
		var d: FighterData = main.roster[main.picks[i]]
		var s := -off if i == 0 else off
		var edge_top := half + VS_SLANT + s
		var edge_bottom := half - VS_SLANT + s
		var outer := s if i == 0 else w + s
		c.draw_colored_polygon(PackedVector2Array([Vector2(outer, 0), Vector2(edge_top, 0), Vector2(edge_bottom, h),
				Vector2(outer, h)]), d.color.darkened(0.55))
		# Sinar berputar dari belakang petarung.
		var center := Vector2(half + (-1.0 if i == 0 else 1.0) * (w * 0.25) + s, h - 110)
		for k in 12:
			var a0 := k * TAU / 12.0 + t * 0.006 * (1 if i == 0 else -1)
			var ray := PackedVector2Array([center, center + Vector2(cos(a0), sin(a0)) * 150.0,
					center + Vector2(cos(a0 + 0.2), sin(a0 + 0.2)) * 150.0])
			c.draw_colored_polygon(ray, Color(d.color.lightened(0.35), 0.13))
		# Garis miring sejajar garis tengah, bergeser menjauh dari tengah.
		for k in 9:
			var band := fposmod(k * 30.0 + t * 1.5, 270.0)
			var x := (edge_bottom - band - 18.0) if i == 0 else (edge_bottom + band + 8.0)
			c.draw_colored_polygon(PackedVector2Array([Vector2(x + VS_SLANT * 2, 0), Vector2(x + VS_SLANT * 2 + 6, 0),
					Vector2(x + 6, h), Vector2(x, h)]), Color(1, 1, 1, 0.05))
		# Sorot lantai di bawah kaki.
		c.draw_rect(Rect2(center.x - 44, h - 60, 88, 3), Color(d.color.lightened(0.5), 0.35))


## Geseran masuk kedua sisi: besar di awal, nol saat VS dibanting.
func _vs_offset(t: int, w: float) -> float:
	return roundf(w * 0.6 * pow(1.0 - clampf(t / float(main.VS_SLAM), 0.0, 1.0), 2.0))


## Angka acak tetap dari bilangan bulat, supaya efek sama tiap diputar.
func _rnd(i: int) -> float:
	return fposmod(sin(i * 12.9898 + 4.1) * 43758.5453, 1.0)


## Pasang atau lepas latar dan rig layar versus, lalu gerakkan rig dan guncangan layar.
func _update_versus() -> void:
	if main.screen != main.Screen.VERSUS:
		if _vs_back != null:
			_vs_back.queue_free()
			for r in _vs_rigs:
				if r != null:
					r.queue_free()
			_vs_back = null
			_vs_rigs.clear()
			position = Vector2.ZERO
		return
	if _vs_back == null:
		_vs_back = Node2D.new()
		_vs_back.show_behind_parent = true
		_vs_back.draw.connect(_draw_versus_back)
		add_child(_vs_back)
		for i in 2:
			var d: FighterData = main.roster[main.picks[i]]
			var rig: Node2D = null
			if d.rig_scene != null:
				rig = d.rig_scene.instantiate()
				rig.show_behind_parent = true
				# Petarung sama: P2 lebih gelap, seperti di pertarungan (scripts/main.gd).
				rig.modulate = Color(0.62, 0.66, 0.9) if i == 1 and main.picks[0] == main.picks[1] else d.tint
				add_child(rig)
			_vs_rigs.append(rig)
	var t: int = main.screen_frame
	var slam: int = main.VS_SLAM
	var off := _vs_offset(t, size.x)
	for i in 2:
		var rig: Node2D = _vs_rigs[i]
		if rig != null:
			var side := -1.0 if i == 0 else 1.0
			rig.position = Vector2(roundf(size.x * 0.5 + side * (size.x * 0.25 + off)), size.y - 60)
			rig.pose(&"idle", t / 60.0, 1 if i == 0 else -1, t >= slam and t < slam + 3)
	_vs_back.queue_redraw()
	# Guncangan singkat saat VS dibanting.
	var shake := 0.0 if t < slam or t >= slam + 10 else (slam + 10 - t) / 3.0
	position = Vector2(roundf(sin(t * 2.7) * shake), roundf(cos(t * 3.9) * shake * 0.6))


func _draw_overlay(w: float, h: float) -> void:
	var kind: StringName = main.overlay()
	if kind == &"":
		return
	var options: Array = main.overlay_options()
	var ph := options.size() * 18 + 40.0
	if kind == &"pause":
		draw_rect(Rect2(0, 0, w, h), Color(0.02, 0.02, 0.05, 0.6))
		var panel := Rect2(w * 0.5 - 112, h * 0.5 - ph * 0.5, 224, ph)
		_panel(panel)
		_text(Vector2(panel.position.x, panel.position.y + 20), "JEDA", UiFont.LARGE, C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 224)
		_list(options, main.cursor, w * 0.5, panel.position.y + 42)
	else:
		# Menu hasil di bawah teks pemenang (GDD 3 langkah 6).
		var panel2 := Rect2(w * 0.5 - 112, h * 0.5 + 8, 224, options.size() * 18 + 12.0)
		_panel(panel2)
		_list(options, main.cursor, w * 0.5, panel2.position.y + 18)
