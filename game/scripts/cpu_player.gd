extends RefCounted
## Lawan komputer sederhana untuk uji coba sendirian. Bukan AI final mode Arcade.
## Hanya membaca keadaan simulasi dan mengeluarkan bitmask tombol, sama seperti pemain.

const FightSim := preload("res://scripts/sim/fight_sim.gd")
const FighterState := preload("res://scripts/sim/fighter_state.gd")
const St := FighterState.St

var _rng: int
## Antrean tombol: tiap isi [bitmask, jumlah frame].
var _plan: Array = []


func _init(seed_value: int = 777) -> void:
	_rng = seed_value


func _roll(n: int) -> int:
	_rng = (_rng * 1103515245 + 12345) & 0x7fffffff
	return (_rng >> 16) % n


func decide(sim: FightSim, me_index: int) -> int:
	if sim.phase != FightSim.Phase.FIGHT:
		_plan.clear()
		return 0
	var me: FighterState = sim.fighters[me_index]
	var opp: FighterState = sim.fighters[1 - me_index]
	var toward := FightSim.IN_RIGHT if opp.x > me.x else FightSim.IN_LEFT
	var away := FightSim.IN_LEFT if opp.x > me.x else FightSim.IN_RIGHT

	# Serangan unblockable: lompat mundur di akhir jeda peringatan.
	if sim.is_warning(opp) and sim.is_neutral(me):
		var ua := opp.attack()
		if opp.st_frame == ua.startup - 4 and _roll(100) < 60:
			_plan = [[FightSim.IN_UP | away, 3]]

	if not _plan.is_empty():
		var entry: Array = _plan[0]
		entry[1] -= 1
		if entry[1] <= 0:
			_plan.pop_front()
		return entry[0]
	if not sim.is_neutral(me):
		return 0

	@warning_ignore("integer_division")
	var dist: int = abs(opp.x - me.x) / FightSim.FP
	var reach: int = me.data.light_punch.hitbox.end.x
	var opp_attack := opp.attack()
	if opp_attack != null and not opp_attack.unblockable and dist < 130 and _roll(100) < 12:
		_plan = [[FightSim.IN_BLOCK, 14 + _roll(12)]]
	elif me.energy >= sim.rules.energy_max and dist < 150 and _roll(100) < 6:
		_plan = [[FightSim.IN_ULT, 2]]
	elif dist > reach + 4:
		var r := _roll(100)
		if r < 68:
			_plan = [[toward, 6 + _roll(10)]]
		elif r < 76 and me.skill_cd == 0:
			_plan = [[FightSim.IN_SKILL, 2]]
		elif r < 82:
			_plan = [[toward | FightSim.IN_UP, 2]]
		elif r < 90:
			_plan = [[toward, 1], [0, 2], [toward, 1], [0, 8]]
		else:
			_plan = [[0, 6 + _roll(14)]]
	else:
		var r2 := _roll(100)
		if r2 < 28:
			_attack(me, &"lp")
		elif r2 < 50:
			_attack(me, &"lk")
		elif r2 < 66:
			_attack(me, &"hp")
		elif r2 < 76:
			_attack(me, &"hk")
		elif r2 < 82 and me.skill_cd == 0:
			_plan = [[FightSim.IN_SKILL, 2]]
		elif r2 < 91:
			_plan = [[away, 8 + _roll(12)]]
		else:
			_plan = [[FightSim.IN_BLOCK, 10 + _roll(14)]]
	return 0


func _attack(me: FighterState, slot: StringName) -> void:
	_plan = [[1 << FightSim.BUTTON_OF[slot], 2]]
	var a := me.data.get_attack(slot)
	# Kadang lanjut ke serangan cancel pertama untuk mencoba kombo.
	if not a.cancel_into.is_empty() and _roll(100) < 45:
		var next: StringName = a.cancel_into[_roll(a.cancel_into.size())]
		_plan.append([0, a.startup + 1])
		_plan.append([1 << FightSim.BUTTON_OF[next], 3])
	_plan.append([0, 4 + _roll(10)])
