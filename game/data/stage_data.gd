class_name StageData
extends Resource
## Data stage. Ukuran dalam piksel layar 480 x 270.

@export var id: StringName = &""
@export var display_name: String = ""
@export var width: int = 960
## Baris piksel garis lantai (docs/ATURAN-PROYEK.md bagian 1).
@export var floor_y: int = 238

@export_group("Gambar")
## Layer latar (rumah dan langit), bergeser dengan parallax_background. Kosong = stage digambar dengan kode.
@export var background: Texture2D
## Layer lantai tempat petarung berpijak, bergeser dengan parallax_midground.
@export var floor_texture: Texture2D
## Baris piksel tempat layer lantai dimulai.
@export var floor_top: int = 226

@export_group("Parallax")
## Kecepatan geser tiap layer terhadap kamera (GDD 7, docs/decisions.md no. 5).
@export var parallax_sky: float = 0.1
@export var parallax_background: float = 0.5
@export var parallax_midground: float = 1.0
@export var parallax_foreground: float = 1.2

@export_group("Warna placeholder")
@export var sky_top: Color = Color("14182e")
@export var sky_bottom: Color = Color("3b2a3f")
@export var building: Color = Color("232638")
@export var building_light: Color = Color("e0b050")
@export var floor_color: Color = Color("3a3d46")
@export var floor_line: Color = Color("565a66")
@export var foreground: Color = Color("0d0e14")
