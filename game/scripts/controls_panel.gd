extends Control
## Daftar kontrol. Dibuka dari menu utama, menu jeda, atau otomatis saat pertama masuk
## latihan, dan ditutup dengan tombol apa saja (docs/decisions.md no. 19).
## Selama panel ini terbuka, pertarungan berhenti.

const UiFont := preload("res://scripts/ui_font.gd")

const C_FRAME := Color("14151c")
const C_EDGE := Color("8a8f9c")
const C_TEXT := Color("f4f4f4")
const C_DIM := Color("b4bac6")
const C_GOLD := Color("ffd23f")

## Tiga kolom: tiap baris berisi daftar tombol dan artinya.
const COLUMNS := [
	["GERAK", [[["A", "D"], "Jalan"], [["W"], "Lompat"], [["S"], "Jongkok"],
		[["D", "D"], "Dash (ketuk 2x)"], [["L"], "Tahan"]]],
	["SERANG", [[["J"], "Pukul ringan"], [["K"], "Pukul berat"], [["U"], "Tendang ringan"],
		[["I"], "Tendang berat"], [["O"], "Skill"], [["P"], "Ultimate"]]],
	["LAINNYA", [[["Esc"], "Menu jeda"], [["F1"], "Kotak hitbox"], [["F2"], "Mode P2"],
		[["F5"], "Ulang"], [["F11"], "Layar penuh"]]],
]

var _font: Font
var _frame := 0


func _ready() -> void:
	_font = UiFont.get_font()


func _process(_delta: float) -> void:
	if visible:
		_frame += 1
		queue_redraw()


func _text_width(text: String, font_size: int) -> float:
	return _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


func _key(pos: Vector2, label: String) -> float:
	var kw := maxf(13.0, _text_width(label, UiFont.SMALL) + 7.0)
	var cap := Rect2(pos.x, pos.y - 9, kw, 12)
	draw_rect(cap.grow(1), C_EDGE)
	draw_rect(cap, Color("2a2d3a"))
	draw_rect(Rect2(cap.position.x, cap.end.y - 2, kw, 2), Color("1a1c26"))
	draw_string(_font, Vector2(pos.x, pos.y), label, HORIZONTAL_ALIGNMENT_CENTER, kw, UiFont.SMALL, C_GOLD)
	return kw


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color(0.02, 0.02, 0.05, 0.72))
	var pw := 444.0
	var row_h := 16.0
	var ph := 46.0 + 6 * row_h + 46.0
	var panel := Rect2(roundf((w - pw) * 0.5), roundf((h - ph) * 0.5), pw, ph)
	draw_rect(panel.grow(2), C_EDGE)
	draw_rect(panel.grow(1), C_FRAME)
	draw_rect(panel, Color(C_FRAME.lightened(0.05), 1.0))
	draw_string(_font, Vector2(panel.position.x, panel.position.y + 19), "KONTROL", HORIZONTAL_ALIGNMENT_CENTER, pw,
			UiFont.MEDIUM, C_GOLD)
	var top := panel.position.y + 28
	var col_w := pw / 3.0
	for c in COLUMNS.size():
		var cx := panel.position.x + c * col_w + 12
		draw_string(_font, Vector2(cx, top + 13), COLUMNS[c][0], HORIZONTAL_ALIGNMENT_LEFT, -1, UiFont.NORMAL, C_GOLD)
		draw_rect(Rect2(cx, top + 17, col_w - 24, 1), Color(C_EDGE, 0.6))
		var rows: Array = COLUMNS[c][1]
		for r in rows.size():
			var y := top + 34 + r * row_h
			var kx := cx
			for label in rows[r][0]:
				kx += _key(Vector2(kx, y), label) + 3
			draw_string(_font, Vector2(maxf(kx + 3, cx + 36), y), rows[r][1], HORIZONTAL_ALIGNMENT_LEFT, -1,
					UiFont.SMALL, C_TEXT)
	draw_rect(Rect2(panel.position.x + 12, panel.end.y - 40, pw - 24, 1), Color(C_EDGE, 0.6))
	draw_string(_font, Vector2(panel.position.x + 12, panel.end.y - 26),
			"Pemain 2: panah untuk gerak, numpad 1 2 4 5 serang, 3 tahan, 6 skill, 0 ultimate",
			HORIZONTAL_ALIGNMENT_LEFT, pw - 24, UiFont.SMALL, C_DIM)
	var blink := 1.0 if _frame % 50 < 34 else 0.45
	draw_string(_font, Vector2(panel.position.x, panel.end.y - 9), "Tekan tombol apa saja untuk menutup",
			HORIZONTAL_ALIGNMENT_CENTER, pw, UiFont.NORMAL, Color(C_GOLD, blink))
