extends RefCounted
## Font bersama untuk HUD dan menu, plus ukuran teks standar.
## Game digambar di 480 x 270 lalu diperbesar, jadi teks di bawah 10 piksel sulit dibaca.

const SMALL := 10
const NORMAL := 12
const MEDIUM := 16
const LARGE := 20
const HUGE := 40

static var _font: Font


static func get_font() -> Font:
	if _font == null:
		var base := ThemeDB.fallback_font
		if base is FontFile:
			# Tanpa anti-aliasing supaya tepi huruf tetap tajam setelah diperbesar 4x.
			var crisp: FontFile = base.duplicate()
			crisp.antialiasing = TextServer.FONT_ANTIALIASING_NONE
			crisp.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
			crisp.hinting = TextServer.HINTING_NORMAL
			_font = crisp
		else:
			_font = base
	return _font
