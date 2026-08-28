class_name SimulationBuilds
extends RefCounted

const Rules = preload("res://scripts/core_rules.gd")

const POLICIES := [
	{
		"id": "breaker_balanced",
		"name": "Quebra-Mandados equilibrado",
		"class_id": "warrant_breaker",
		"allocation_cycle": ["strength", "strength", "vitality", "cunning"],
	},
	{
		"id": "gunslinger_balanced",
		"name": "Pistoleiro Orbital equilibrado",
		"class_id": "orbit_gunslinger",
		"allocation_cycle": ["dexterity", "dexterity", "vitality", "cunning"],
	},
	{
		"id": "hacker_balanced",
		"name": "Hacker de Contratos equilibrado",
		"class_id": "contract_hacker",
		"allocation_cycle": ["intelligence", "intelligence", "vitality", "cunning"],
	},
]

const CONTROL_POLICY := {
	"id": "unassigned_control",
	"name": "Sem classe / sem atributos (controle legado)",
	"class_id": "",
	"allocation_cycle": [],
}


static func representative_player(level: int, policy: Dictionary) -> Dictionary:
	var player := {
		"level": maxi(1, level),
		"base_power": 10 + maxi(0, level - 1) * 2,
		"attributes": Rules.default_attributes(),
		"stat_points": maxi(0, level - 1) * Rules.ATTRIBUTE_POINTS_PER_LEVEL,
		"weapon": {},
		"armor": {},
		"wins": 0,
	}
	if level > 1:
		var prior_mission_power := 11 + maxi(0, level - 2) * 5
		var gear_power := maxi(1, roundi(float(prior_mission_power) * 0.55))
		player.weapon = {"id": "audit_weapon", "slot": "weapon", "power": gear_power}
		player.armor = {"id": "audit_armor", "slot": "armor", "power": gear_power}
	configure_player(player, policy)
	return player


static func selected_policies(requested_id: String = "") -> Array[Dictionary]:
	var selected: Array[Dictionary] = []
	if requested_id == str(CONTROL_POLICY.id):
		selected.append(CONTROL_POLICY)
		return selected
	if not requested_id.is_empty():
		for policy in POLICIES:
			if str(policy.id) == requested_id:
				selected.append(policy)
				return selected
		return selected
	for policy in POLICIES:
		selected.append(policy.duplicate(true))
	return selected


static func configure_player(player: Dictionary, policy: Dictionary) -> void:
	player.class_id = str(policy.get("class_id", ""))
	apply_available_points(player, policy)


static func apply_available_points(player: Dictionary, policy: Dictionary) -> int:
	var available := maxi(0, int(player.get("stat_points", 0)))
	var cycle: Array = policy.get("allocation_cycle", [])
	if available <= 0 or cycle.is_empty():
		return 0
	var attributes: Dictionary = player.get("attributes", Rules.default_attributes()).duplicate(true)
	var invested := total_investment(attributes)
	for point_index in available:
		var attribute_id := str(cycle[(invested + point_index) % cycle.size()])
		attributes[attribute_id] = int(attributes.get(attribute_id, Rules.BASE_ATTRIBUTE_VALUE)) + 1
	player.attributes = attributes
	player.stat_points = 0
	Rules.clear_bounty_odds_cache()
	return available


static func total_investment(attributes: Dictionary) -> int:
	var total := 0
	for attribute_id in Rules.ATTRIBUTE_KEYS:
		total += maxi(0, int(attributes.get(attribute_id, Rules.BASE_ATTRIBUTE_VALUE)) - Rules.BASE_ATTRIBUTE_VALUE)
	return total


static func attribute_summary(player: Dictionary) -> String:
	var attributes: Dictionary = player.get("attributes", Rules.default_attributes())
	return "FOR %d · VIT %d · DES %d · INT %d · AST %d" % [
		int(attributes.get("strength", Rules.BASE_ATTRIBUTE_VALUE)),
		int(attributes.get("vitality", Rules.BASE_ATTRIBUTE_VALUE)),
		int(attributes.get("dexterity", Rules.BASE_ATTRIBUTE_VALUE)),
		int(attributes.get("intelligence", Rules.BASE_ATTRIBUTE_VALUE)),
		int(attributes.get("cunning", Rules.BASE_ATTRIBUTE_VALUE)),
	]
