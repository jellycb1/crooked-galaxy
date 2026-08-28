extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const Content = preload("res://scripts/content_db.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")
const EquipmentGenerationRules = preload("res://scripts/equipment_generation_rules.gd")
const Rules = preload("res://scripts/core_rules.gd")

const CAREERS := 100
const CONTRACTS_PER_CAREER := 5000
const THRESHOLDS := [1, 10, 25, 50, 100, 200, 300, 350]


func _init() -> void:
	var total := Content.procedural_collection_ids().size()
	var checkpoints := THRESHOLDS.duplicate()
	checkpoints.append(total)
	var reached := {}
	for threshold in checkpoints:
		reached[threshold] = []
	var final_counts: Array[int] = []
	for career_index in CAREERS:
		var state := StateScript.new()
		state.persistence_enabled = false
		state.player = state.default_player()
		var rng := RandomNumberGenerator.new()
		rng.seed = 990001 + career_index * 1013
		var discoveries := {}
		var reached_this_career := {}
		for contract_index in CONTRACTS_PER_CAREER:
			var offers := MissionRules.board_offers(state.player)
			var contract: Dictionary = offers[(contract_index + career_index) % offers.size()]
			var target_id := str(contract.id)
			var captures := int(state.player.captures_by_target.get(target_id, 0))
			var item := Content.generate_loot(contract, rng, Rules.target_mastery_level(captures))
			discoveries[EquipmentGenerationRules.collection_id(item)] = true
			for threshold in checkpoints:
				if discoveries.size() >= int(threshold) and not reached_this_career.has(threshold):
					(reached[threshold] as Array).append(contract_index + 1)
					reached_this_career[threshold] = true
			state.player.captures_by_target[target_id] = captures + 1
			state.player.wins = int(state.player.wins) + 1
			Rules.apply_xp(state.player, int(contract.xp))
		final_counts.append(discoveries.size())
		state.free()
	print("Crooked Galaxy collection audit (%d careers × %d contracts · %d series)" % [CAREERS, CONTRACTS_PER_CAREER, total])
	for threshold in checkpoints:
		var samples: Array = reached[threshold]
		print("MILESTONE %d · reached=%d/%d · median=%s contracts" % [threshold, samples.size(), CAREERS, median_text(samples)])
	print("DISCOVERED AFTER %d · median=%d · p10=%d · p90=%d" % [CONTRACTS_PER_CAREER, percentile(final_counts, 0.50), percentile(final_counts, 0.10), percentile(final_counts, 0.90)])
	quit(0)


func percentile(values: Array[int], ratio: float) -> int:
	if values.is_empty():
		return 0
	var sorted := values.duplicate()
	sorted.sort()
	return int(sorted[clampi(roundi(float(sorted.size() - 1) * ratio), 0, sorted.size() - 1)])


func median_text(values: Array) -> String:
	if values.is_empty():
		return "—"
	var sorted := values.duplicate()
	sorted.sort()
	return str(sorted[sorted.size() / 2])
