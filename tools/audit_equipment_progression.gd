extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const Content = preload("res://scripts/content_db.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")
const Rules = preload("res://scripts/core_rules.gd")

const CAREERS := 80
const CONTRACTS_PER_CAREER := 120
const BAND_SIZE := 20


func _init() -> void:
	var band_drops: Array[int] = []
	var band_upgrades: Array[int] = []
	var band_gaps: Array[Array] = []
	for _band in ceili(float(CONTRACTS_PER_CAREER) / float(BAND_SIZE)):
		band_drops.append(0)
		band_upgrades.append(0)
		band_gaps.append([])
	var rarities := {"Comum": 0, "Raro": 0, "Épico": 0}
	var qualities: Array[int] = []
	var unique_instances := {}
	var attribute_packages := 0
	var ordinary_traits := 0
	for career_index in CAREERS:
		var state = StateScript.new()
		state.persistence_enabled = false
		state.player = state.default_player()
		var rng := RandomNumberGenerator.new()
		rng.seed = 730001 + career_index * 1009
		var last_upgrade_contract := 0
		for contract_index in CONTRACTS_PER_CAREER:
			var offers := MissionRules.board_offers(state.player)
			var contract: Dictionary = offers[mini(1, offers.size() - 1)]
			var target_id := str(contract.id)
			var captures := int(state.player.captures_by_target.get(target_id, 0))
			var item := Content.generate_loot(contract, rng, Rules.target_mastery_level(captures))
			var band := contract_index / BAND_SIZE
			band_drops[band] += 1
			rarities[str(item.rarity)] = int(rarities.get(str(item.rarity), 0)) + 1
			qualities.append(int(item.quality))
			var modifier_id := str(item.get("trait", {}).get("id", item.get("attribute_package_id", "none")))
			if item.has("attribute_package_id"):
				attribute_packages += 1
			elif item.has("trait"):
				ordinary_traits += 1
			var identity := "%s|%s|%d|%s|%s" % [str(item.template_id), str(item.rarity), int(item.quality), str(item.variant_id), modifier_id]
			unique_instances[identity] = true
			if Rules.is_upgrade_for_player(state.player, item):
				band_upgrades[band] += 1
				band_gaps[band].append(contract_index + 1 - last_upgrade_contract)
				last_upgrade_contract = contract_index + 1
				state.player[str(item.slot)] = item
			state.player.captures_by_target[target_id] = captures + 1
			state.player.wins = int(state.player.wins) + 1
			Rules.apply_xp(state.player, int(contract.xp))
		state.free()
	qualities.sort()
	print("Crooked Galaxy equipment progression audit (%d careers × %d contracts)" % [CAREERS, CONTRACTS_PER_CAREER])
	print("RARITY · common=%s · rare=%s · epic=%s" % [percent(int(rarities.Comum), qualities.size()), percent(int(rarities.Raro), qualities.size()), percent(int(rarities.Épico), qualities.size())])
	print("QUALITY · p10=%d · median=%d · p90=%d" % [percentile(qualities, 0.10), percentile(qualities, 0.50), percentile(qualities, 0.90)])
	print("IDENTITY · %d unique combinations across %d drops" % [unique_instances.size(), qualities.size()])
	print("MODIFIERS · traits=%s · attribute packages=%s" % [percent(ordinary_traits, qualities.size()), percent(attribute_packages, qualities.size())])
	for band in band_drops.size():
		var start := band * BAND_SIZE + 1
		var finish := mini(CONTRACTS_PER_CAREER, start + BAND_SIZE - 1)
		print("CONTRACTS %03d–%03d · upgrade drops=%s · median gap=%s contracts" % [start, finish, percent(band_upgrades[band], band_drops[band]), median_text(band_gaps[band])])
	quit(0)


func percent(value: int, total: int) -> String:
	return "%.1f%%" % (float(value) / float(maxi(1, total)) * 100.0)


func percentile(values: Array[int], ratio: float) -> int:
	if values.is_empty():
		return 0
	return int(values[clampi(roundi(float(values.size() - 1) * ratio), 0, values.size() - 1)])


func median_text(values: Array) -> String:
	if values.is_empty():
		return "—"
	var sorted := values.duplicate()
	sorted.sort()
	return str(sorted[sorted.size() / 2])
