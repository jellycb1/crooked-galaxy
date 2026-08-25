extends SceneTree

const ContractRules = preload("res://scripts/contract_rules.gd")
const Content = preload("res://scripts/content_db.gd")

var failures := 0


func _init() -> void:
	check(is_equal_approx(ContractRules.expected_return_score({"odds": 1.0, "credits": 0, "xp": 0, "scrap": 1, "duration": 1}), ContractRules.SCRAP_VALUE), "recommendation values explicit workshop funding")
	var early_game: Array[Dictionary] = [
		{"id": "quiet", "odds": 0.76, "credits": 52, "xp": 78, "duration": 10},
		{"id": "fast", "odds": 0.01, "credits": 78, "xp": 62, "duration": 4},
		{"id": "profit", "odds": 0.01, "credits": 96, "xp": 53, "duration": 7},
	]
	check(ContractRules.recommended_approach_id(early_game) == "quiet", "recommendation rejects lucrative near-certain defeats")

	var overpowered: Array[Dictionary] = [
		{"id": "quiet", "odds": 0.99, "credits": 52, "xp": 78, "duration": 10},
		{"id": "fast", "odds": 0.99, "credits": 78, "xp": 62, "duration": 4},
		{"id": "profit", "odds": 0.99, "credits": 96, "xp": 53, "duration": 7},
	]
	check(ContractRules.recommended_approach_id(overpowered) == "fast", "recommendation favors efficient returns when every approach is safe")
	var profile_routes: Array[Dictionary] = [
		{"id": "quiet_net", "odds": 0.80, "credits": 70, "xp": 60, "scrap": 0, "duration": 7},
		{"id": "hot_hatch", "odds": 0.80, "credits": 70, "xp": 60, "scrap": 0, "duration": 7},
		{"id": "premium_warrant", "odds": 0.80, "credits": 70, "xp": 60, "scrap": 0, "duration": 7},
	]
	check(ContractRules.recommended_approach_id(profile_routes, "warrant_breaker") == "premium_warrant", "breaker profile resolves an otherwise equal recommendation toward corporate pressure")
	check(ContractRules.recommended_approach_id(profile_routes, "orbit_gunslinger") == "hot_hatch", "gunslinger profile resolves an otherwise equal recommendation toward speed")
	check(ContractRules.recommended_approach_id(profile_routes, "contract_hacker") == "quiet_net", "hacker profile resolves an otherwise equal recommendation toward control")
	check(ContractRules.recommendation_label({"class_id": "contract_hacker"}, "quiet_net").contains("HACKER"), "recommendation label exposes class-route synergy")
	var unsafe_profile_routes := profile_routes.duplicate(true)
	unsafe_profile_routes[0].odds = 0.54
	check(ContractRules.recommended_approach_id(unsafe_profile_routes, "contract_hacker") != "quiet_net", "class identity never promotes its preferred route below the viability gate")

	var desperate: Array[Dictionary] = [
		{"id": "safer", "odds": 0.31, "credits": 20, "xp": 20, "duration": 9},
		{"id": "riskier", "odds": 0.18, "credits": 100, "xp": 20, "duration": 3},
	]
	check(ContractRules.recommended_approach_id(desperate) == "safer", "fallback selects the safest option when none is viable")
	check(ContractRules.recommended_approach_id([]).is_empty(), "empty evaluations have no recommendation")

	var streak_player := {"level": 1, "base_power": 10, "weapon": {"power": 1}, "armor": {"power": 1}, "capture_streak": 2}
	var streak_evaluations := ContractRules.evaluate_approaches(streak_player, Content.TARGETS[0], Content.contract_approaches())
	check(streak_evaluations.all(func(evaluation): return int(evaluation.streak) == 3 and int(evaluation.streak_bonus_percent) == 10 and int(evaluation.streak_bonus) > 0), "approach evaluation exposes the shared streak and each route's exact included bonus")
	check(int(streak_evaluations[0].streak_bonus) != int(streak_evaluations[2].streak_bonus), "approach evaluation keeps percentage invariant while absolute bonuses follow route payment")
	var confirmed_defeat := ContractRules.field_test_defeat_text({"tested_approach_name": "Rede Silenciosa", "tested_odds": 0.74, "chosen_approach_name": "Rede Silenciosa", "overridden": false})
	check(confirmed_defeat.contains("ROTA TESTADA TAMBÉM FALHOU") and confirmed_defeat.contains("REFORCE A BUILD"), "confirmed-route defeat points recovery toward build or incident")
	var override_defeat := ContractRules.field_test_defeat_text({"tested_approach_name": "Rede Silenciosa", "tested_odds": 0.74, "chosen_approach_name": "Mandado Corporativo", "overridden": true})
	check(override_defeat.contains("OVERRIDE DERROTADO") and override_defeat.contains("REAVALIE A ROTA"), "override defeat points recovery back toward route choice")
	check(ContractRules.field_test_defeat_text({}).is_empty(), "ordinary defeats do not invent tested-route advice")

	if failures == 0:
		print("PASS: contract recommendations balance risk and return")
		quit(0)
	else:
		printerr("FAIL: %d contract recommendation test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
