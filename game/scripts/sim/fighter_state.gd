extends RefCounted
## Keadaan satu petarung di simulasi. Hanya bilangan bulat, supaya hasilnya
## sama persis di semua mesin dan bisa disimpan/dipulihkan untuk rollback.

enum St {
	IDLE, WALK_F, WALK_B, CROUCH, BLOCK, JUMP, DASH_F, DASH_B, ATTACK,
	HITSTUN, BLOCKSTUN, KNOCKDOWN, DOWN, GETUP, KO, DEFEAT, WIN,
}

const ST_NAMES := [
	"IDLE", "WALK_F", "WALK_B", "CROUCH", "BLOCK", "JUMP", "DASH_F", "DASH_B", "ATTACK",
	"HITSTUN", "BLOCKSTUN", "KNOCKDOWN", "DOWN", "GETUP", "KO", "DEFEAT", "WIN",
]

## Semua field yang ikut disimpan saat snapshot.
const FIELDS := [
	"x", "y", "vx", "vy", "kb", "facing", "st", "st_frame", "health", "energy",
	"attack_id", "attack_dir", "hits_done", "next_hit_frame", "contact", "stun",
	"combo", "skill_cd", "flash", "hurt_tick", "inp", "prev_inp", "buf",
	"tap_dir", "tap_tick", "dash_dir", "dash_tick",
]

const NEVER := -100000

var data: FighterData
var index: int = 0

## Posisi titik kaki dalam 1/100 piksel. y = 0 di lantai, negatif ke atas.
var x: int = 0
var y: int = 0
var vx: int = 0
var vy: int = 0
## Kecepatan dorongan akibat pukulan.
var kb: int = 0
var facing: int = 1

var st: int = St.IDLE
## Frame ke berapa di state sekarang, mulai dari 1.
var st_frame: int = 0

var health: int = 0
var energy: int = 0

var attack_id: StringName = &""
## 1 = maju, -1 = mundur. Dipakai teleport.
var attack_dir: int = 1
var hits_done: int = 0
var next_hit_frame: int = 0
## Serangan sekarang sudah menyentuh lawan (kena atau ditahan).
var contact: bool = false
var stun: int = 0
## Jumlah pukulan beruntun yang sedang diterima.
var combo: int = 0
var skill_cd: int = 0
## Sisa frame kilatan putih.
var flash: int = 0
## Tick terakhir kena pukulan atau menahan.
var hurt_tick: int = NEVER

var inp: int = 0
var prev_inp: int = 0
## Tick terakhir tiap tombol ditekan, untuk input buffer.
var buf: PackedInt32Array = PackedInt32Array()
var tap_dir: int = 0
var tap_tick: int = NEVER
var dash_dir: int = 0
var dash_tick: int = NEVER


func _init() -> void:
	buf.resize(11)
	buf.fill(NEVER)


func attack() -> AttackData:
	if st != St.ATTACK:
		return null
	return data.get_attack(attack_id)


func is_grounded() -> bool:
	return y >= 0


func is_crouching() -> bool:
	return st == St.CROUCH


func is_lying() -> bool:
	return st == St.DOWN or st == St.KO


func state_name() -> String:
	return ST_NAMES[st]


func save() -> Dictionary:
	var d := {}
	for k in FIELDS:
		var v = get(k)
		d[k] = v.duplicate() if v is PackedInt32Array else v
	return d


func restore(d: Dictionary) -> void:
	for k in FIELDS:
		var v = d[k]
		set(k, v.duplicate() if v is PackedInt32Array else v)
