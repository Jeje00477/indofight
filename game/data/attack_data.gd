class_name AttackData
extends Resource
## Data satu serangan. Diubah lewat file .tres di data/attacks, bukan di kode.
##
## Satuan:
## - waktu: frame (60 frame = 1 detik)
## - jarak dan kotak: piksel layar 480 x 270
## - kecepatan: 1/100 piksel per frame (250 = 2,5 piksel per frame)

@export var id: StringName = &""
@export var display_name: String = ""

@export_group("Frame data")
## Frame sebelum hitbox aktif. Serangan dengan startup 5 mengenai lawan di frame ke-6.
@export var startup: int = 5
@export var active: int = 3
@export var recovery: int = 10
## Lama lawan terkunci setelah kena.
@export var hitstun: int = 14
## Lama lawan terkunci setelah menahan.
@export var blockstun: int = 9
## Lama layar berhenti saat kena. Dihitung per frame di simulasi, bukan time-scale.
@export var hitstop: int = 6
@export var blockstop: int = 4

@export_group("Damage")
@export var damage: int = 40
## Damage yang tembus saat ditahan. Tidak bisa menghabisi lawan.
@export var chip_damage: int = 4
@export var unblockable: bool = false
## Menjatuhkan lawan. Untuk serangan beruntun, hanya pukulan terakhir yang menjatuhkan.
@export var knockdown: bool = false
## Kecepatan lempar ke atas saat menjatuhkan.
@export var launch_speed: int = 320
## Serangan berat: suara dan getaran lebih besar.
@export var heavy: bool = false

@export_group("Dorongan")
## Kecepatan awal lawan terdorong mundur saat kena.
@export var pushback_hit: int = 260
@export var pushback_block: int = 220
## Penyerang ikut maju dari frame lunge_from sampai lunge_to.
@export var lunge_speed: int = 0
@export var lunge_from: int = 0
@export var lunge_to: int = 0

@export_group("Hitbox")
## Relatif ke titik kaki saat menghadap kanan. x ke depan, y negatif ke atas.
## Ukuran 0 berarti serangan ini tidak punya hitbox (misalnya teleport atau lemparan proyektil).
@export var hitbox: Rect2i = Rect2i(12, -80, 36, 12)
## Jumlah pukulan selama frame aktif.
@export var hit_count: int = 1
@export var hit_interval: int = 4
## Jenis efek pukulan: blunt atau slash (GDD 9.2).
@export var spark: StringName = &"blunt"
## Getaran layar dalam piksel.
@export var shake: int = 1

@export_group("Cancel")
## Serangan yang boleh langsung menyusul bila serangan ini mengenai atau ditahan lawan.
@export var cancel_into: Array[StringName] = []

@export_group("Khusus")
## Jeda sebelum bisa dipakai lagi (skill).
@export var cooldown: int = 0
## Butuh energi penuh dan menghabiskannya (ultimate).
@export var requires_full_energy: bool = false
## Lama cinematic pembuka. Selama itu simulasi dan timer berhenti (GDD 4).
@export var cinematic_frames: int = 0
## Kebal dari frame invulnerable_from sampai invulnerable_to (0 = tidak kebal).
@export var invulnerable_from: int = 0
@export var invulnerable_to: int = 0
## Pindah instan sejauh ini (piksel) di frame teleport_frame. Tahan mundur untuk pindah ke belakang.
@export var teleport_distance: int = 0
@export var teleport_frame: int = 0
## Proyektil yang dilepas di frame aktif pertama.
@export var projectile: ProjectileData
## Petarung menaiki motor selama ancang-ancang dan frame aktif (ultimate).
@export var vehicle: bool = false
## Efek tambahan di pukulan terakhir yang kena, misalnya star5.
@export var finish_effect: StringName = &""


func total_frames() -> int:
	return startup + active + recovery


func is_active_frame(frame: int) -> bool:
	return frame > startup and frame <= startup + active


func has_hitbox() -> bool:
	return hitbox.size.x > 0 and hitbox.size.y > 0


## Selisih frame saat kena: positif berarti penyerang pulih lebih dulu.
func advantage_on_hit() -> int:
	return hitstun - (active - 1) - recovery


func advantage_on_block() -> int:
	return blockstun - (active - 1) - recovery
