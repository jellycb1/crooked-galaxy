extends SceneTree

const Rules = preload("res://scripts/core_rules.gd")
const Content = preload("res://scripts/content_db.gd")
const Challenge = preload("res://scripts/challenge_rules.gd")
const Builds = preload("res://tools/simulation_builds.gd")

const CHECKPOINTS := [
	{"name": "chegada a Congelária", "level": 8, "base_power": 24, "weapon": {"power": 14, "origin_planet_id": "dustball_prime"}, "armor": {"power": 10, "origin_planet_id": "dustball_prime"}, "campaign_target": 4},
	{"name": "fim de Congelária", "level": 11, "base_power": 30, "weapon": {"power": 25, "origin_planet_id": "congelaria_sa"}, "armor": {"power": 20, "integrity_upgrades": 1, "origin_planet_id": "congelaria_sa"}, "campaign_target": 7},
	{"name": "fim de Micélia", "level": 15, "base_power": 40, "weapon": {"power": 38, "origin_planet_id": "micelia_404"}, "armor": {"power": 30, "integrity_upgrades": 3, "origin_planet_id": "micelia_404"}, "campaign_target": 11},
	{"name": "chegada a Ferro-Velho", "level": 16, "base_power": 40, "weapon": {"power": 40, "origin_planet_id": "ferro_velho_omega"}, "armor": {"power": 34, "integrity_upgrades": 2, "origin_planet_id": "ferro_velho_omega"}, "campaign_target": 12},
	{"name": "chegada ao Cassino", "level": 22, "base_power": 52, "weapon": {"power": 58, "origin_planet_id": "ferro_velho_omega"}, "armor": {"power": 48, "integrity_upgrades": 3, "origin_planet_id": "ferro_velho_omega"}, "campaign_target": 16},
	{"name": "fim do Cassino", "level": 29, "base_power": 66, "weapon": {"power": 80, "origin_planet_id": "cassino_quasar"}, "armor": {"power": 64, "integrity_upgrades": 3, "origin_planet_id": "cassino_quasar"}, "campaign_target": 19},
]


func _init() -> void:
	print("Crooked Galaxy Fenda Clandestina · cross-class cumulative audit")
	var maximum_class_spread := 0.0
	var maximum_campaign_delta := 0.0
	var maximum_campaign_safe_delta := 0.0
	for stage_index in Challenge.STAGES.size():
		var checkpoint: Dictionary = CHECKPOINTS[stage_index]
		var stage := Challenge.stage_at(stage_index)
		var class_odds: Array[float] = []
		print("\nANDAR %d · %s · %s" % [stage_index + 1, str(stage.name), str(checkpoint.name)])
		for policy in Builds.POLICIES:
			var player := checkpoint_player(checkpoint, policy)
			var bare_player := player.duplicate(true)
			apply_prior_rewards(player, stage_index)
			var odds := Rules.bounty_odds(player, stage)
			var bare_odds := Rules.bounty_odds(bare_player, stage)
			var campaign_delta := 0.0
			for approach_index in Content.CONTRACT_APPROACHES.size():
				var approach: Dictionary = Content.CONTRACT_APPROACHES[approach_index]
				var campaign := Content.apply_approach(Content.TARGETS[int(checkpoint.campaign_target)], approach)
				var campaign_before := Rules.bounty_odds(bare_player, campaign)
				var campaign_after := Rules.bounty_odds(player, campaign)
				var route_delta := campaign_after - campaign_before
				campaign_delta = maxf(campaign_delta, route_delta)
				if approach_index == 0:
					maximum_campaign_safe_delta = maxf(maximum_campaign_safe_delta, route_delta)
			maximum_campaign_delta = maxf(maximum_campaign_delta, campaign_delta)
			class_odds.append(odds)
			print("  %-30s odds=%3d%% (sem Fenda %3d%%) · campanha +%2d pp · poder=%d/vida=%d/abertura=%d/redução=%d" % [str(policy.name), roundi(odds * 100.0), roundi(bare_odds * 100.0), roundi(campaign_delta * 100.0), Rules.player_power(player), Rules.max_health(player), Rules.player_opening_damage(player), Rules.player_damage_reduction(player)])
		var spread := maximum(class_odds) - minimum(class_odds)
		maximum_class_spread = maxf(maximum_class_spread, spread)
		print("  SPREAD · %d pontos percentuais" % roundi(spread * 100.0))
	print("\nLIMITES · maior spread=%d pp · rota segura=+%d pp · qualquer rota=+%d pp" % [roundi(maximum_class_spread * 100.0), roundi(maximum_campaign_safe_delta * 100.0), roundi(maximum_campaign_delta * 100.0)])
	quit(0)


static func checkpoint_player(checkpoint: Dictionary, policy: Dictionary) -> Dictionary:
	var player := {
		"level": int(checkpoint.level),
		"base_power": int(checkpoint.base_power),
		"class_id": "",
		"attributes": Rules.default_attributes(),
		"stat_points": maxi(0, int(checkpoint.level) - 1) * Rules.ATTRIBUTE_POINTS_PER_LEVEL,
		"weapon": checkpoint.weapon.duplicate(true),
		"helmet": {}, "armor": checkpoint.armor.duplicate(true), "gloves": {}, "boots": {},
		"rig": {}, "implant": {}, "gadget": {}, "relic": {},
	}
	Builds.configure_player(player, policy)
	return player


static func apply_prior_rewards(player: Dictionary, stage_index: int) -> void:
	for reward_index in stage_index:
		var reward := Challenge.reward_for(Challenge.stage_at(reward_index), Content.ITEM_TRAITS)
		if Rules.is_upgrade_for_player(player, reward):
			player[str(reward.slot)] = reward
	Rules.clear_bounty_odds_cache()


static func minimum(values: Array[float]) -> float:
	var result := INF
	for value in values:
		result = minf(result, value)
	return result


static func maximum(values: Array[float]) -> float:
	var result := -INF
	for value in values:
		result = maxf(result, value)
	return result
