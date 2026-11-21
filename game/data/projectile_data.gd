class_name ProjectileData
extends Resource
## Data proyektil. Damage, hitstun, dan lain-lain diambil dari AttackData yang melepasnya.

## Kecepatan dalam 1/100 piksel per frame.
@export var speed: int = 300
## Jarak tempuh sebelum hilang atau berbalik (piksel).
@export var max_distance: int = 150
## Berbalik ke pemiliknya setelah mencapai jarak maksimum (bumerang).
@export var returns: bool = false
@export var size: Vector2i = Vector2i(24, 16)
## Titik muncul relatif ke titik kaki pemilik saat menghadap kanan.
@export var spawn_offset: Vector2i = Vector2i(30, -70)
## Sprite sheet mendatar hasil render Blender (docs/decisions.md no. 23). Kosong = kotak polos.
@export var texture: Texture2D
## Jumlah frame putaran di sprite sheet.
@export var frames: int = 1
## Batas umur dalam frame, untuk jaga-jaga.
@export var lifetime: int = 240
