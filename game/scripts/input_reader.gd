extends RefCounted
## Mengubah Input Map Godot menjadi bitmask tombol untuk simulasi.
## Dibaca sekali per tick logika, supaya simulasi hanya bergantung pada bitmask ini.

const FightSim := preload("res://scripts/sim/fight_sim.gd")

const SUFFIXES := ["left", "right", "up", "down", "lp", "hp", "lk", "hk", "block", "skill", "ultimate"]

static var _actions: Array = []


static func read(player: int) -> int:
	if _actions.is_empty():
		for prefix in ["p1_", "p2_"]:
			var list: Array[StringName] = []
			for s in SUFFIXES:
				list.append(StringName(prefix + s))
			_actions.append(list)
	var bits := 0
	var list: Array = _actions[player]
	for b in list.size():
		if Input.is_action_pressed(list[b]):
			bits |= 1 << b
	return bits
