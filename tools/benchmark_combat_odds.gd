extends SceneTree

const Rules = preload("res://scripts/core_rules.gd")
const StateScript = preload("res://scripts/game_state.gd")

const SAMPLE_COUNT := 24


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
	var started := Time.get_ticks_usec()
	var checksum := 0.0
	for index in SAMPLE_COUNT:
		var target: Dictionary = ContentDB.TARGETS[4 + index % 12].duplicate(true)
		target.power = int(target.power) + index
		target.defense = int(target.defense) + index % 5
		target.health = int(target.health) + index * 3
		checksum += Rules.bounty_odds(player, target)
	var misses_usec := Time.get_ticks_usec() - started
	started = Time.get_ticks_usec()
	for index in SAMPLE_COUNT:
		var target: Dictionary = ContentDB.TARGETS[4 + index % 12].duplicate(true)
		target.power = int(target.power) + index
		target.defense = int(target.defense) + index % 5
		target.health = int(target.health) + index * 3
		checksum += Rules.bounty_odds(player, target)
	var hits_usec := Time.get_ticks_usec() - started
	print("COMBAT_ODDS_BENCHMARK misses=%d us (%d us/call) hits=%d us checksum=%.3f" % [misses_usec, misses_usec / SAMPLE_COUNT, hits_usec, checksum])
	quit(0)
