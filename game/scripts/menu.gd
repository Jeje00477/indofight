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


func _ready() -> void:
	_font = UiFont.get_font()


func _process(_delta: float) -> void:
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
	"KONTROL": "Lihat daftar tombol",
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


func _draw_versus(w: float, h: float) -> void:
	draw_rect(Rect2(0, 0, w, h), Color(0.02, 0.02, 0.05, 1.0))
	var t: int = main.screen_frame
	var slide := maxf(0.0, 1.0 - t / 14.0)
	var d1: FighterData = main.roster[main.picks[0]]
	var d2: FighterData = main.roster[main.picks[1]]
	var half := w * 0.5
	draw_rect(Rect2(-slide * half, 0, half, h), Color(d1.color.darkened(0.6), 1.0))
	draw_rect(Rect2(half + slide * half, 0, half, h), Color(d2.color.darkened(0.6), 1.0))
	_figure(Rect2(half * 0.5 - 30 - slide * half, 50, 60, 150), d1, 1)
	_figure(Rect2(half * 1.5 - 30 + slide * half, 50, 60, 150), d2, -1)
	_text(Vector2(-slide * half, 228), d1.display_name, 16, C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, half)
	_text(Vector2(half + slide * half, 228), d2.display_name, 16, C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, half)
	if t > 14:
		draw_rect(Rect2(half - 3, 0, 6, h), C_GOLD)
		draw_rect(Rect2(half - 30, h * 0.5 - 26, 60, 44), C_FRAME)
		_text(Vector2(half - 60, h * 0.5 + 8), "VS", 32, C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 120)
	_text(Vector2(0, h - 8), main.stage.display_name, UiFont.SMALL, C_DIM, HORIZONTAL_ALIGNMENT_CENTER, w)


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
