extends SceneTree

const Rules = preload("res://scripts/core_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")

const SAMPLE_COUNT := 12
const MISS_BUDGET_USEC := 600000
const HIT_BUDGET_USEC := 30000

var failures := 0


func _init() -> void:
	var state := StateScript.new()
	var player := state.default_player()
	state.free()
	player.class_id = "orbit_gunslinger"
	player.attributes.dexterity = 26
	player.attributes.cunning = 22
	player.rig = {"trait": ContentDB.ITEM_TRAITS.rig[2].duplicate(true)}
	player.implant = {"trait": ContentDB.ITEM_TRAITS.implant[1].duplicate(true)}
	Rules.clear_bounty_odds_cache()
	var targets := benchmark_targets()
	var started := Time.get_ticks_usec()
	for target in targets:
		Rules.bounty_odds(player, target)
	var miss_time := Time.get_ticks_usec() - started
	started = Time.get_ticks_usec()
	for target in targets:
		Rules.bounty_odds(player, target)
	var hit_time := Time.get_ticks_usec() - started
	check(miss_time <= MISS_BUDGET_USEC, "uncached field odds remain suitable for a mobile interaction frame (%d us)" % miss_time)
	check(hit_time <= HIT_BUDGET_USEC, "cached field odds remain effectively immediate (%d us)" % hit_time)
	check(hit_time * 5 < miss_time, "the deterministic odds cache retains a material hot-path benefit")
	if failures == 0:
		print("PASS: combat odds hot paths stay within interaction budgets (misses=%d us, hits=%d us)" % [miss_time, hit_time])
	quit(1 if failures > 0 else 0)


func benchmark_targets() -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	for index in SAMPLE_COUNT:
		var target: Dictionary = ContentDB.TARGETS[4 + index % 12].duplicate(true)
		target.power = int(target.power) + index
		target.defense = int(target.defense) + index % 5
		target.health = int(target.health) + index * 3
		targets.append(target)
	return targets


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: %s" % message)
