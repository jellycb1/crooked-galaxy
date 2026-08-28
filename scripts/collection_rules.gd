class_name CollectionRules
extends RefCounted

const LocaleRules = preload("res://scripts/locale_rules.gd")


static func milestones(player: Dictionary, catalog_total: int) -> Array[Dictionary]:
	var total := maxi(1, catalog_total)
	var discovered := clampi(player.get("discovered_item_variant_ids", []).size(), 0, total)
	var claimed: Array = player.get("claimed_collection_milestones", [])
	var thresholds: Array[int] = [1, 10, 25, 50, 100, 200, 300, 350]
	if total > 100:
		thresholds.append(total)
	elif not thresholds.has(total):
		thresholds.append(total)
	thresholds = thresholds.filter(func(value: int): return value <= total)
	thresholds.sort()
	var result: Array[Dictionary] = []
	for threshold in thresholds:
		var milestone_id := "series_%d" % threshold
		result.append({
			"id": milestone_id,
			"threshold": threshold,
			"discovered": discovered,
			"complete": discovered >= threshold,
			"claimed": claimed.has(milestone_id),
			"warp_chips": reward_for_threshold(threshold, total),
			"name": LocaleRules.text("COLLECTION_MILESTONE_NAME", "ARQUIVISTA · %d SÉRIES", [threshold]),
			"description": LocaleRules.text("COLLECTION_MILESTONE_DESCRIPTION", "Registe %d séries de equipamento distintas.", [threshold]),
		})
	return result


static func rewards_ready(player: Dictionary, catalog_total: int) -> Array[Dictionary]:
	var ready: Array[Dictionary] = []
	for milestone in milestones(player, catalog_total):
		if bool(milestone.complete) and not bool(milestone.claimed):
			ready.append(milestone)
	return ready


static func valid_milestone_ids(catalog_total: int) -> Array[String]:
	var ids: Array[String] = []
	for milestone in milestones({}, catalog_total):
		ids.append(str(milestone.id))
	return ids


static func reward_for_threshold(threshold: int, catalog_total: int) -> int:
	if threshold >= catalog_total:
		return 10
	if threshold >= 100:
		return 5
	if threshold >= 50:
		return 3
	if threshold >= 25:
		return 2
	return 1
