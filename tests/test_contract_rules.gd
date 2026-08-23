extends SceneTree

const ContractRules = preload("res://scripts/contract_rules.gd")

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

	var desperate: Array[Dictionary] = [
		{"id": "safer", "odds": 0.31, "credits": 20, "xp": 20, "duration": 9},
		{"id": "riskier", "odds": 0.18, "credits": 100, "xp": 20, "duration": 3},
	]
	check(ContractRules.recommended_approach_id(desperate) == "safer", "fallback selects the safest option when none is viable")
	check(ContractRules.recommended_approach_id([]).is_empty(), "empty evaluations have no recommendation")

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
