extends Node2D
## Rig satu petarung: Skeleton2D menggerakkan mesh bagian tubuh, AnimationPlayer menyimpan
## animasinya. Scene-nya dibuat oleh tools/build_rigs.gd.
##
## Animasi tidak berjalan sendiri. Tampilan memanggil pose() tiap frame dengan waktu
## yang dihitung dari frame simulasi, supaya gambar selalu cocok dengan frame data.
##
## Di atas pose dari animasi, rig ini menambah dua hal supaya gerak terasa mulus
## (docs/decisions.md no. 25):
##   1. Peralihan: saat animasi berganti, pose lama dilebur ke pose baru selama beberapa
##      frame, jadi badan tidak meloncat dari satu pose ke pose lain.
##   2. Gerak susulan: kepala, senjata, dan lengan belakang punya pegas, jadi sedikit
##      tertinggal lalu menyusul saat badan bergerak cepat atau berhenti mendadak.
## Keduanya hanya tampilan. Simulasi, hitbox, dan frame data tidak terpengaruh.

## Pegas gerak susulan per tulang: [kekakuan, redaman, simpangan maksimum (derajat),
## pengaruh percepatan badan].
const SPRINGS := {
	&"head": [0.30, 0.62, 9.0, 0.010],
	&"prop": [0.36, 0.58, 14.0, 0.016],
	&"arm_b_lower": [0.32, 0.60, 12.0, 0.014],
}
## Geseran lebih jauh dari ini dalam satu frame dianggap pindah tempat (teleport, ronde
## baru), bukan gerak: pegas tidak bereaksi.
const TELEPORT_PX := 24.0

@onready var anim: AnimationPlayer = $Anim
@onready var parts: Node2D = $Parts
@onready var skeleton: Node2D = $Skeleton

## 1 = lengan depan dan propertinya digambar di belakang badan. Diatur oleh animasi.
@export var arm_back := 0:
	set(value):
		if value == arm_back:
			return
		arm_back = value
		_reorder()

## Mesh bagian tubuh di dalam Parts.
var _meshes: Array[Polygon2D] = []
## Urutan gambar asli bagian-bagian di dalam Parts.
var _order: Array[Node] = []
## Semua tulang, induk selalu sebelum anak.
var _bones: Array[Bone2D] = []
var _hip: Bone2D
var _bone_by_name := {}

# Peralihan antaranimasi.
var _anim_name: StringName = &""
var _anim_time := 0.0
## Pose yang terakhir ditampilkan (sebelum pegas): rotasi tiap tulang, posisi pinggul,
## posisi dan putaran kerangka.
var _shown := {}
var _from := {}
var _blend_len := 0
var _blend_at := 0

# Pegas gerak susulan: nama tulang -> [sudut, kecepatan sudut].
var _spring := {}
var _last_pos := Vector2.ZERO
var _last_vel := Vector2.ZERO
var _has_last := false


func _ready() -> void:
	anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	# Tiap rig punya material sendiri, supaya kilatan satu petarung tidak ikut menyala di
	# petarung lain yang memakai karakter sama.
	parts.material = parts.material.duplicate()
	for child in parts.get_children():
		_order.append(child)
		if child is Polygon2D:
			_meshes.append(child)
	_collect_bones(skeleton)
	_hip = skeleton.get_node("hip")
	_reorder()


func _collect_bones(node: Node) -> void:
	for child in node.get_children():
		if child is Bone2D:
			_bones.append(child)
			_bone_by_name[child.name] = child
			_collect_bones(child)


## Tampilkan animasi `anim_name` di waktu `time` detik. `facing` 1 = kanan, -1 = kiri.
## `blend` = jumlah frame peleburan bila animasi ini baru saja menggantikan animasi lain
## (0 = langsung).
func pose(anim_name: StringName, time: float, facing: int, flash: bool, blend: int = 0) -> void:
	scale.x = facing
	if not anim.has_animation(anim_name):
		anim_name = &"idle"
	var animation := anim.get_animation(anim_name)
	var length := animation.length
	time = clampf(time, 0.0, length)
	var changed := anim_name != _anim_name
	# Animasi yang sama diulang dari awal (serangan yang sama ditekan lagi, kena pukul lagi).
	if not changed and animation.loop_mode == Animation.LOOP_NONE and time < _anim_time - 0.25 * length:
		changed = true
	if changed and blend > 0 and not _shown.is_empty():
		_from = _shown.duplicate()
		_blend_len = blend
		_blend_at = 0
	elif changed:
		_blend_len = 0
	_anim_name = anim_name
	_anim_time = time

	if anim.assigned_animation != anim_name:
		anim.play(anim_name)
	anim.seek(time, true)

	# 1. Peralihan: lebur pose lama ke pose animasi sekarang.
	var target := _read_pose()
	if _blend_at < _blend_len:
		_blend_at += 1
		var w := float(_blend_at) / float(_blend_len + 1)
		w = w * w * (3.0 - 2.0 * w)
		for key in target:
			if not _from.has(key):
				continue
			if target[key] is Vector2:
				target[key] = (_from[key] as Vector2).lerp(target[key], w)
			else:
				target[key] = lerp_angle(_from[key], target[key], w)
		_write_pose(target)
	_shown = target

	# 2. Gerak susulan.
	_apply_springs()

	# Mesh dihitung di ruang Skeleton. Saat seluruh badan diputar (jatuh, KO), mesh harus
	# ikut berpindah bersama Skeleton, kalau tidak lengan dan kaki tertinggal di tempat.
	for mesh in _meshes:
		mesh.transform = skeleton.transform
	# Kilatan putih saat kena (docs/ATURAN-PROYEK.md bagian 4).
	(parts.material as ShaderMaterial).set_shader_parameter(&"flash", 1.0 if flash else 0.0)


## Jadikan rig ini bayangan gerak: satu warna rata, tembus pandang.
func set_ghost(color: Color) -> void:
	(parts.material as ShaderMaterial).set_shader_parameter(&"ghost", color)


## Lupakan gerak sebelumnya (ronde baru, rig baru dipasang).
func reset_motion() -> void:
	_shown.clear()
	_blend_len = 0
	_spring.clear()
	_has_last = false


func animation_length(anim_name: StringName) -> float:
	if not anim.has_animation(anim_name):
		return 1.0
	return anim.get_animation(anim_name).length


func _read_pose() -> Dictionary:
	var out := {&"@pos": skeleton.position, &"@rot": skeleton.rotation, &"@hip": _hip.position}
	for bone in _bones:
		out[bone.name] = bone.rotation
	return out


func _write_pose(p: Dictionary) -> void:
	skeleton.position = p[&"@pos"]
	skeleton.rotation = p[&"@rot"]
	_hip.position = p[&"@hip"]
	for bone in _bones:
		bone.rotation = p[bone.name]


func _apply_springs() -> void:
	# Percepatan badan di ruang rig (x positif = arah hadap).
	var accel := Vector2.ZERO
	if _has_last:
		var vel := position - _last_pos
		vel.x *= scale.x
		if vel.length() > TELEPORT_PX:
			vel = Vector2.ZERO
			_last_vel = Vector2.ZERO
		accel = vel - _last_vel
		_last_vel = vel
	_last_pos = position
	_has_last = true

	# Putaran tiap tulang di ruang rig, dihitung dari induk ke anak.
	var world := {}
	for bone in _bones:
		var parent := bone.get_parent()
		var base: float = world[parent.name] if parent is Bone2D else skeleton.rotation
		world[bone.name] = base + bone.rotation
	for bone_name in SPRINGS:
		if not world.has(bone_name):
			continue
		var cfg: Array = SPRINGS[bone_name]
		var bone: Bone2D = _bone_by_name[bone_name]
		var goal: float = world[bone_name]
		if not _spring.has(bone_name):
			_spring[bone_name] = [goal, 0.0]
			continue
		var s: Array = _spring[bone_name]
		# Ujung tulang tertinggal saat badan dipercepat: torsi dari gaya inersia.
		var dir := Vector2.RIGHT.rotated(goal + bone.get_bone_angle())
		var v: float = s[1] * (1.0 - cfg[1]) + angle_difference(s[0], goal) * cfg[0] + dir.cross(-accel) * cfg[3]
		var a: float = s[0] + v
		var limit := deg_to_rad(cfg[2])
		var off := clampf(angle_difference(goal, a), -limit, limit)
		s[0] = goal + off
		s[1] = v
		bone.rotation += off


## Susun ulang urutan gambar: lengan depan dan properti di paling belakang bila arm_back = 1.
func _reorder() -> void:
	if _order.is_empty():
		return
	var order: Array[Node] = []
	if arm_back == 1:
		for child in _order:
			if child.name == &"arm_f" or child.name == &"prop":
				order.append(child)
	for child in _order:
		if not order.has(child):
			order.append(child)
	for i in order.size():
		parts.move_child(order[i], i)
