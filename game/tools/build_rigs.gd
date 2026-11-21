extends SceneTree
## Membangun scene rig tiap petarung dari potongan gambar dan tabel pose.
##
## Masukan:  characters/<nama>/rig.json dan parts/*.png (hasil tools/cut_parts.py)
##           tools/rig_poses.gd (pose dan animasi)
## Keluaran: characters/<nama>/<nama>_rig.tscn berisi Skeleton2D, Bone2D, Sprite2D per
##           bagian, dan AnimationPlayer. Scene ini bisa dibuka dan diubah di editor Godot,
##           tetapi menjalankan skrip ini lagi akan menimpanya.
##
## Jalankan dari folder proyek:
##   godot --headless --path game --import
##   godot --headless --path game -s res://tools/build_rigs.gd

const Poses := preload("res://tools/rig_poses.gd")
const RigScript := preload("res://scripts/fighter_rig.gd")

const CHARACTERS := ["emak-emak", "abang-ojol"]
const LIMBS := {
	"af": ["arm_f_upper", "arm_f_lower"],
	"ab": ["arm_b_upper", "arm_b_lower"],
	"lf": ["leg_f_upper", "leg_f_lower"],
	"lb": ["leg_b_upper", "leg_b_lower"],
}
const FLASH_SHADER := """shader_type canvas_item;
// Kilatan putih saat petarung kena pukulan.
uniform float flash : hint_range(0.0, 1.0) = 0.0;
// Bayangan gerak: bila alfanya di atas nol, seluruh badan digambar satu warna rata.
uniform vec4 ghost : source_color = vec4(0.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float g = step(0.001, ghost.a);
	COLOR = vec4(mix(mix(c.rgb, vec3(1.0), flash), ghost.rgb, g), c.a * mix(1.0, ghost.a, g));
}
"""


func _init() -> void:
	var failed := false
	for c in CHARACTERS:
		if not _build(c):
			failed = true
	quit(1 if failed else 0)


func _build(character: String) -> bool:
	var dir := "res://characters/%s/" % character
	var rig: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "rig.json"))
	var bones := {}
	for b in rig["bones"]:
		bones[b["name"]] = b

	var root := Node2D.new()
	root.name = "Rig"
	root.set_script(RigScript)
	var skeleton := Skeleton2D.new()
	skeleton.name = "Skeleton"
	root.add_child(skeleton)
	skeleton.owner = root
	var parts := Node2D.new()
	parts.name = "Parts"
	var shader := Shader.new()
	shader.code = FLASH_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	parts.material = material
	root.add_child(parts)
	parts.owner = root

	# Tulang. "hip" adalah tulang akar; sisanya mengikuti kolom parent di rig.json.
	var nodes := {}
	var paths := {}
	var hip := Bone2D.new()
	hip.name = "hip"
	hip.position = Vector2(rig["hip"][0], rig["hip"][1])
	hip.rest = hip.transform
	hip.set_autocalculate_length_and_angle(false)
	hip.set_length(8.0)
	skeleton.add_child(hip)
	hip.owner = root
	nodes["hip"] = hip
	paths["hip"] = "Skeleton/hip"
	var pending: Array = rig["bones"].duplicate()
	while not pending.is_empty():
		var progressed := false
		for b in pending.duplicate():
			if not nodes.has(b["parent"]):
				continue
			var bone := Bone2D.new()
			bone.name = b["name"]
			bone.position = Vector2(b["position"][0], b["position"][1])
			bone.rest = bone.transform
			bone.set_autocalculate_length_and_angle(false)
			bone.set_length(maxf(4.0, b["length"]))
			# Arah diam di rig.json: 0 = ke bawah, positif = ke depan. Godot: 0 = ke kanan.
			bone.set_bone_angle(deg_to_rad(90.0 - float(b["rest_dir"])))
			nodes[b["parent"]].add_child(bone)
			bone.owner = root
			nodes[b["name"]] = bone
			paths[b["name"]] = paths[b["parent"]] + "/" + b["name"]
			pending.erase(b)
			progressed = true
		if not progressed:
			push_error("Induk tulang tidak ditemukan: %s" % str(pending))
			return false

	# Semua bagian adalah mesh (Polygon2D) yang digerakkan tulang, diurutkan menurut z supaya
	# urutan gambar tetap di dalam rig ini saja. Bagian kaku ikut satu tulang; bagian lentur
	# (lengan, kaki, rok) ditekuk beberapa tulang.
	var tex_scale := int(rig.get("tex_scale", 1))
	var ordered: Array = []
	for b in rig["bones"]:
		if b.get("sprite", true):
			var rest := _rest_position(bones, b["name"], nodes)
			ordered.append({
				"name": b["name"], "mode": "rigid", "texture": b["texture"], "z": b["z"], "bones": [b["name"]],
				"origin": [rest.x + b["sprite_offset"][0], rest.y + b["sprite_offset"][1]], "size": b["size"],
			})
	ordered.append_array(rig.get("meshes", []))
	ordered.sort_custom(func(a, b): return a["z"] < b["z"])
	for m in ordered:
		var mesh := _build_mesh(dir, m, bones, nodes, paths, tex_scale)
		if mesh == null:
			return false
		parts.add_child(mesh)
		mesh.owner = root

	# Animasi.
	var player := AnimationPlayer.new()
	player.name = "Anim"
	root.add_child(player)
	player.owner = root
	var library := AnimationLibrary.new()
	var stand: Dictionary = Poses.STAND[character]
	var anims: Dictionary = Poses.animations(character)
	for anim_name in anims:
		var spec: Dictionary = anims[anim_name]
		var animation := Animation.new()
		animation.length = spec["length"]
		animation.loop_mode = Animation.LOOP_LINEAR if spec["loop"] else Animation.LOOP_NONE
		var tracks := {}
		for key in spec["keys"]:
			var pose: Dictionary = stand.duplicate(true)
			pose.merge(key[1], true)
			var solved := _solve(rig, bones, pose, pose.get("ground", spec.get("ground", true)))
			for path in solved:
				if not tracks.has(path):
					var idx := animation.add_track(Animation.TYPE_VALUE)
					animation.track_set_path(idx, NodePath(path))
					if path.ends_with(":z_index") or path.ends_with(":arm_back"):
						# Urutan gambar berpindah seketika, tidak dihaluskan.
						animation.track_set_interpolation_type(idx, Animation.INTERPOLATION_NEAREST)
						animation.value_track_set_update_mode(idx, Animation.UPDATE_DISCRETE)
					else:
						# Kurva halus supaya gerak punya ayunan dan sedikit lewat sasaran.
						animation.track_set_interpolation_type(idx, Animation.INTERPOLATION_CUBIC)
					tracks[path] = idx
				animation.track_insert_key(tracks[path], key[0], solved[path])
		library.add_animation(anim_name, animation)
	player.add_animation_library("", library)

	var scene := PackedScene.new()
	var err := scene.pack(root)
	if err != OK:
		push_error("Gagal mengemas rig %s" % character)
		return false
	var out := dir + character.replace("-", "_") + "_rig.tscn"
	err = ResourceSaver.save(scene, out)
	root.free()
	if err != OK:
		push_error("Gagal menyimpan %s" % out)
		return false
	print("%s: %d tulang, %d animasi -> %s" % [character, nodes.size(), anims.size(), out])
	return true


## Ubah satu pose menjadi nilai track: rotasi lokal tiap tulang, posisi pinggul, dan
## putaran serta geseran seluruh kerangka.
func _solve(rig: Dictionary, bones: Dictionary, pose: Dictionary, ground: bool) -> Dictionary:
	# Rotasi dunia tiap tulang dalam derajat (searah jarum jam positif, seperti Godot).
	var world := {"hip": 0.0, "chest": float(pose["torso"])}
	# Badan bawah ikut sepertiga condong badan atas, ditambah putaran khususnya sendiri.
	world["pelvis"] = world["chest"] * 0.35 + float(pose["pelvis"])
	world["head"] = world["chest"] + float(pose["head"])
	for key in LIMBS:
		for i in 2:
			var bone_name: String = LIMBS[key][i]
			world[bone_name] = float(bones[bone_name]["rest_dir"]) - float(pose[key][i])
	world["prop"] = float(bones["prop"]["rest_dir"]) - float(pose["prop"])

	var hip := Vector2(rig["hip"][0] + pose["hip"][0], rig["hip"][1] + pose["hip"][1])
	if ground:
		# Geser pinggul naik atau turun sampai telapak kaki terendah tepat di lantai.
		var lowest := -INF
		for key in ["lf", "lb"]:
			var upper: Dictionary = bones[LIMBS[key][0]]
			var lower: Dictionary = bones[LIMBS[key][1]]
			var thigh := hip + Vector2(upper["position"][0], upper["position"][1])
			var knee := thigh + Vector2(lower["position"][0], lower["position"][1]).rotated(deg_to_rad(world[upper["name"]]))
			var rest := deg_to_rad(float(lower["rest_dir"]))
			var shin := Vector2(sin(rest), cos(rest)) * float(lower["length"])
			var foot := knee + shin.rotated(deg_to_rad(world[lower["name"]]))
			lowest = maxf(lowest, foot.y)
		hip.y += -1.0 - lowest

	var out := {
		"Skeleton:rotation": deg_to_rad(float(pose["spin"])),
		"Skeleton:position": Vector2(pose["lift"][0], pose["lift"][1]),
		"Skeleton/hip:position": hip.round(),
		".:arm_back": int(pose["arm_back"]),
	}
	# Kaki depan digambar di atas badan saat menendang. Petarung berok tidak butuh ini:
	# roknya ikut terangkat bersama paha.
	for m in rig.get("meshes", []):
		if m["name"] == "leg_f":
			out["Parts/leg_f:z_index"] = 2 if int(pose["leg_front"]) == 1 else 0
	for bone_name in bones:
		var parent: String = bones[bone_name]["parent"]
		var path := "Skeleton/hip/" + _chain(bones, bone_name)
		out[path + ":rotation"] = deg_to_rad(world[bone_name] - world[parent])
	return out


## Bangun satu mesh lentur dari teksturnya: kisi 4 piksel di atas bagian yang berisi gambar,
## dengan bobot tiap titik ke tulang-tulangnya.
##   mode "rigid": satu tulang, seluruh bagian ikut tulang itu (kepala, badan, properti).
##   mode "chain": dua tulang berurutan (lengan atas dan bawah, paha dan betis). Bobot
##                 berpindah halus di sekitar sendi, jadi siku dan lutut menekuk tanpa celah.
##   mode "skirt": [pinggul, paha belakang, paha depan]. Bagian atas ikut pinggul, bagian bawah
##                 ikut paha di sisinya, jadi rok terangkat bersama kaki.
func _build_mesh(dir: String, m: Dictionary, bones: Dictionary, nodes: Dictionary, paths: Dictionary, tex_scale: int) -> Polygon2D:
	var tex: Texture2D = load(dir + m["texture"])
	if tex == null:
		push_error("Tekstur belum diimpor: %s. Jalankan --import dulu." % (dir + m["texture"]))
		return null
	var img := tex.get_image()
	var cell := 4
	var origin := Vector2(m["origin"][0], m["origin"][1])
	var w: int = m["size"][0]
	var h: int = m["size"][1]
	var cols := ceili(float(w) / cell)
	var rows := ceili(float(h) / cell)
	var index := {}
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	var quads: Array = []
	for cy in rows:
		for cx in cols:
			var filled := false
			for y in range(cy * cell, mini((cy + 1) * cell, h)):
				for x in range(cx * cell, mini((cx + 1) * cell, w)):
					@warning_ignore("integer_division")
					if img.get_pixel(x * tex_scale + tex_scale / 2, y * tex_scale + tex_scale / 2).a > 0.5:
						filled = true
						break
				if filled:
					break
			if not filled:
				continue
			var quad := PackedInt32Array()
			for corner in [Vector2i(cx, cy), Vector2i(cx + 1, cy), Vector2i(cx + 1, cy + 1), Vector2i(cx, cy + 1)]:
				if not index.has(corner):
					index[corner] = points.size()
					var uv := Vector2(mini(corner.x * cell, w), mini(corner.y * cell, h))
					# Tekstur disimpan tex_scale kali lebih besar (lihat tools/cut_parts.py).
					uvs.append(uv * tex_scale)
					points.append(origin + uv)
				quad.append(index[corner])
			quads.append(quad)

	var poly := Polygon2D.new()
	poly.name = m["name"]
	poly.texture = tex
	poly.polygon = points
	poly.uv = uvs
	poly.polygons = quads
	poly.use_parent_material = true
	poly.skeleton = NodePath("../../Skeleton")

	var names: Array = m["bones"]
	var weights: Array = []
	for n in names:
		var wts := PackedFloat32Array()
		wts.resize(points.size())
		weights.append(wts)
	if m["mode"] == "rigid":
		weights[0].fill(1.0)
	elif m["mode"] == "chain":
		# Dua tulang terakhir adalah ruas atas dan bawah. Bila ada tiga tulang, yang pertama adalah
		# badan tempat anggota itu menempel: pangkalnya ikut badan, supaya bahu tidak mencuat
		# atau terlepas saat lengan diangkat.
		var n := names.size()
		var a := _rest_position(bones, names[n - 2], nodes)
		var joint := _rest_position(bones, names[n - 1], nodes)
		var axis := (joint - a).normalized()
		for i in points.size():
			var lower := smoothstep(-5.0, 5.0, (points[i] - joint).dot(axis))
			var body := 0.0
			if n == 3:
				body = 1.0 - smoothstep(-4.0, 3.0, (points[i] - a).dot(axis))
				weights[0][i] = body
			weights[n - 2][i] = (1.0 - lower) * (1.0 - body)
			weights[n - 1][i] = lower * (1.0 - body)
	else:
		# Bila ada lima tulang, dua yang terakhir adalah betis: kaki di bawah rok ikut dalam mesh
		# yang sama, jadi tidak pernah ada celah antara ujung rok dan kaki.
		var shins := names.size() == 5
		var top := origin.y
		var bottom := origin.y + h
		var knees: Array[Vector2] = []
		if shins:
			knees = [_rest_position(bones, names[3], nodes), _rest_position(bones, names[4], nodes)]
			bottom = maxf(knees[0].y, knees[1].y)
		var center_x: float = nodes["hip"].position.x
		for i in points.size():
			var p := points[i]
			var down := clampf((p.y - top) / (bottom - top), 0.0, 1.0)
			var legs := smoothstep(0.12, 0.7, down)
			var front := smoothstep(center_x - 7.0, center_x + 7.0, p.x)
			var skirt := 1.0
			if shins:
				# Tiap titik hanya ikut betis di sisinya sendiri.
				var k := 0 if absf(p.x - knees[0].x) <= absf(p.x - knees[1].x) else 1
				var knee := knees[k]
				var shin := smoothstep(knee.y - 1.0, knee.y + 4.0, p.y)
				# Di sekitar ujung rok hanya titik yang tepat di atas kaki yang ikut betis.
				if p.y <= knee.y + 5.0:
					shin *= 1.0 - smoothstep(7.0, 11.0, absf(p.x - knee.x))
				weights[3 + k][i] = shin
				skirt = 1.0 - shin
			weights[0][i] = (1.0 - legs) * skirt
			weights[1][i] = legs * (1.0 - front) * skirt
			weights[2][i] = legs * front * skirt
	for k in names.size():
		# Jalur tulang relatif ke node Skeleton.
		poly.add_bone(NodePath(String(paths[names[k]]).trim_prefix("Skeleton/")), weights[k])
	return poly


## Posisi diam sebuah tulang di ruang rig: jumlah posisi dari tulang akar sampai tulang itu.
func _rest_position(bones: Dictionary, bone_name: String, nodes: Dictionary) -> Vector2:
	var pos: Vector2 = nodes[bone_name].position
	var parent: String = bones[bone_name]["parent"]
	while parent != "hip":
		pos += nodes[parent].position
		parent = bones[parent]["parent"]
	return pos + nodes["hip"].position


func _chain(bones: Dictionary, bone_name: String) -> String:
	var parent: String = bones[bone_name]["parent"]
	if parent == "hip":
		return bone_name
	return _chain(bones, parent) + "/" + bone_name
