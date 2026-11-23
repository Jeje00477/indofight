extends Control
## Daftar kontrol yang bisa diubah (docs/decisions.md no. 26). Dibuka dari menu utama,
## menu jeda, atau otomatis saat pertama masuk latihan. Selama panel ini terbuka,
## pertarungan berhenti.
##
## Panah atas dan bawah memilih aksi, kiri dan kanan memilih pemain, Enter mengubah
## tombolnya (lalu tekan tombol baru), Esc menutup.

const UiFont := preload("res://scripts/ui_font.gd")
const KeyBindings := preload("res://scripts/key_bindings.gd")

const C_FRAME := Color("14151c")
const C_EDGE := Color("8a8f9c")
const C_TEXT := Color("f4f4f4")
const C_DIM := Color("b4bac6")
const C_GOLD := Color("ffd23f")
const C_PICK := Color("2bc8ff")

## Baris terakhir adalah "kembalikan bawaan".
var row := 0
## 0 = pemain 1, 1 = pemain 2.
var col := 0
## Sedang menunggu tombol baru untuk baris dan kolom terpilih.
var waiting := false

var _font: Font
var _frame := 0
## Pesan singkat di bawah tabel dan sisa frame tampilnya.
var _note := ""
var _note_frames := 0


func _ready() -> void:
	_font = UiFont.get_font()


func _process(_delta: float) -> void:
	if visible:
		_frame += 1
		_note_frames = maxi(0, _note_frames - 1)
		queue_redraw()


## Dipanggil main.gd untuk tiap tombol saat panel terbuka. Mengembalikan true bila panel
## harus ditutup.
func handle_key(key: InputEventKey) -> bool:
	var rows := KeyBindings.ACTIONS.size() + 1
	if waiting:
		waiting = false
		if key.keycode == KEY_ESCAPE:
			return false
		if not KeyBindings.assign(col, row, key.physical_keycode):
			_say("Tombol itu dipakai menu, pilih tombol lain")
		return false
	match key.keycode:
		KEY_ESCAPE, KEY_BACKSPACE:
			return true
		KEY_UP, KEY_W:
			row = posmod(row - 1, rows)
		KEY_DOWN, KEY_S:
			row = posmod(row + 1, rows)
		KEY_LEFT, KEY_A, KEY_RIGHT, KEY_D:
			col = 1 - col
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			if row == rows - 1:
				KeyBindings.reset()
				_say("Tombol kembali ke bawaan")
			else:
				waiting = true
	return false


func _say(text: String) -> void:
	_note = text
	_note_frames = 150


func _text_width(text: String, font_size: int) -> float:
	return _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


func _key(pos: Vector2, label: String, color: Color) -> void:
	var kw := maxf(16.0, _text_width(label, UiFont.SMALL) + 8.0)
	var cap := Rect2(roundf(pos.x - kw * 0.5), pos.y - 9, roundf(kw), 12)
	draw_rect(cap.grow(1), C_EDGE)
	draw_rect(cap, Color("2a2d3a"))
	draw_rect(Rect2(cap.position.x, cap.end.y - 2, cap.size.x, 2), Color("1a1c26"))
	draw_string(_font, Vector2(cap.position.x, pos.y), label, HORIZONTAL_ALIGNMENT_CENTER, cap.size.x,
			UiFont.SMALL, color)


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color(0.02, 0.02, 0.05, 0.78))
	var actions := KeyBindings.ACTIONS.size()
	var row_h := 14.0
	var pw := 352.0
	var ph := 44.0 + (actions + 1) * row_h + 40.0
	var panel := Rect2(roundf((w - pw) * 0.5), roundf((h - ph) * 0.5), pw, ph)
	draw_rect(panel.grow(2), C_EDGE)
	draw_rect(panel.grow(1), C_FRAME)
	draw_rect(panel, Color(C_FRAME.lightened(0.05), 1.0))
	draw_string(_font, Vector2(panel.position.x, panel.position.y + 17), "KONTROL", HORIZONTAL_ALIGNMENT_CENTER, pw,
			UiFont.MEDIUM, C_GOLD)

	var name_x := panel.position.x + 14
	var col_x := [panel.position.x + 200, panel.position.x + 290]
	var top := panel.position.y + 36
	for c in 2:
		draw_string(_font, Vector2(col_x[c] - 30, top), "PEMAIN %d" % (c + 1), HORIZONTAL_ALIGNMENT_CENTER, 60,
				UiFont.SMALL, C_GOLD)
	draw_rect(Rect2(name_x, top + 3, pw - 28, 1), Color(C_EDGE, 0.6))
	var blink := _frame % 30 < 18
	for r in actions + 1:
		var y := top + 15 + r * row_h
		var selected := r == row
		if selected:
			draw_rect(Rect2(panel.position.x + 6, y - 10, pw - 12, row_h - 1), Color(C_PICK, 0.14))
		if r == actions:
			draw_string(_font, Vector2(name_x, y + 2), "Kembalikan semua tombol bawaan", HORIZONTAL_ALIGNMENT_LEFT, -1,
					UiFont.SMALL, C_PICK if selected else C_DIM)
			continue
		draw_string(_font, Vector2(name_x, y), KeyBindings.LABELS[r], HORIZONTAL_ALIGNMENT_LEFT, -1, UiFont.SMALL,
				C_TEXT if selected else C_DIM)
		for c in 2:
			var picked := selected and c == col
			if picked and waiting:
				if blink:
					_key(Vector2(col_x[c], y), "...", C_PICK)
				continue
			var cap_x: float = col_x[c]
			if picked:
				draw_rect(Rect2(cap_x - 30, y - 11, 60, 15), C_PICK, false, 1.0)
			_key(Vector2(cap_x, y), KeyBindings.label(KeyBindings.keys[c][r]), C_GOLD)

	var foot := panel.end.y - 26
	draw_rect(Rect2(panel.position.x + 12, foot - 10, pw - 24, 1), Color(C_EDGE, 0.6))
	var hint := "Tekan tombol baru untuk %s %s  (Esc batal)" % [KeyBindings.LABELS[row], "P%d" % (col + 1)] \
			if waiting and row < actions else "Atas/Bawah pilih   Kiri/Kanan pemain   Enter ubah"
	if _note_frames > 0:
		hint = _note
	draw_string(_font, Vector2(panel.position.x, foot), hint, HORIZONTAL_ALIGNMENT_CENTER, pw, UiFont.SMALL, C_TEXT)
	draw_string(_font, Vector2(panel.position.x, foot + 14),
			"Ketuk arah 2x: dash   F1 hitbox   F2 mode P2   F5 ulang   F11 layar penuh",
			HORIZONTAL_ALIGNMENT_CENTER, pw, UiFont.SMALL, C_DIM)
	var close := Rect2(panel.end.x - 62, panel.position.y + 6, 56, 14)
	draw_rect(close, Color(C_GOLD, 0.9 if _frame % 50 < 34 else 0.55))
	draw_string(_font, Vector2(close.position.x, close.position.y + 11), "Esc tutup", HORIZONTAL_ALIGNMENT_CENTER,
			close.size.x, UiFont.SMALL, C_FRAME)
