class_name FighterData
extends Resource
## Data satu petarung. Kecepatan dalam 1/100 piksel per frame, ukuran dalam piksel.

@export var id: StringName = &""
@export var display_name: String = ""
## Warna kotak placeholder sampai sprite jadi.
@export var color: Color = Color.WHITE
@export var accent: Color = Color.GRAY
## Gambar dasar 160 x 160 (kaki di baris 150, tengah di kolom 80) untuk layar pilih dan versus.
@export var portrait: Texture2D
## Scene rig Skeleton2D hasil tools/build_rigs.gd.
@export var rig_scene: PackedScene
## Warna pengali rig. Dipakai untuk membedakan P2 bila kedua pemain memilih petarung yang sama.
@export var tint: Color = Color.WHITE
## Sprite motor di ultimate: 4 frame 96 x 64 hasil render Blender. Kosong = kotak berwarna.
@export var vehicle_texture: Texture2D
## Warna motor di ultimate bila tidak ada sprite.
@export var vehicle_color: Color = Color("3a3d46")

@export_group("Daya tahan")
@export var max_health: int = 1000

@export_group("Gerak")
@export var walk_forward_speed: int = 130
@export var walk_backward_speed: int = 100
@export var dash_speed: int = 420
@export var backdash_speed: int = 380
@export var dash_frames: int = 10
@export var jump_speed: int = 560
@export var gravity: int = 28
@export var air_speed: int = 140

@export_group("Kotak")
## Relatif ke titik kaki. x di tengah badan, y negatif ke atas.
@export var stand_hurtbox: Rect2i = Rect2i(-14, -100, 28, 100)
@export var crouch_hurtbox: Rect2i = Rect2i(-15, -62, 30, 62)
## Lebar badan untuk saling dorong.
@export var push_width: int = 26

@export_group("Serangan")
@export var light_punch: AttackData
@export var heavy_punch: AttackData
@export var light_kick: AttackData
@export var heavy_kick: AttackData
@export var skill: AttackData
@export var ultimate: AttackData


func get_attack(attack_id: StringName) -> AttackData:
	match attack_id:
		&"lp":
			return light_punch
		&"hp":
			return heavy_punch
		&"lk":
			return light_kick
		&"hk":
			return heavy_kick
		&"skill":
			return skill
		&"ultimate":
			return ultimate
	return null
