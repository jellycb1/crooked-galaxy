class_name TransportRules
extends RefCounted

const MIN_HUNT_DURATION := 3.0

const DEFINITIONS := [
	{
		"id": "licensed_junkbox",
		"name": "LATA VOADORA HOMOLOGADA",
		"tagline": "A porta fecha quando a gravidade colabora.",
		"description": "Um ônibus orbital aposentado, legalizado com três carimbos e uma ameaça educada.",
		"speed_bonus": 0.10,
		"price": 500,
		"required_level": 1,
		"symbol": "▰",
		"color": "#72f1dd",
	},
	{
		"id": "cloned_warp_taxi",
		"name": "TÁXI WARP CLONADO",
		"tagline": "O taxímetro cobra antes da dobra.",
		"description": "Chega depressa, em duplicado e ocasionalmente ao planeta correto.",
		"speed_bonus": 0.20,
		"price": 2200,
		"required_level": 4,
		"symbol": "◇",
		"color": "#55e5ff",
	},
	{
		"id": "repo_interceptor",
		"name": "INTERCEPTOR DE PENHORA",
		"tagline": "Mais rápido que a contestação judicial.",
		"description": "Construído para alcançar devedores antes que terminem de esconder os móveis.",
		"speed_bonus": 0.30,
		"price": 6500,
		"required_level": 8,
		"symbol": "▶",
		"color": "#ffc857",
	},
	{
		"id": "executive_escape_yacht",
		"name": "IATE DE FUGA EXECUTIVA",
		"tagline": "Cinquenta por cento menos tempo para negar tudo.",
		"description": "Sala de crise, minibar e compartimento fiscal vendidos separadamente.",
		"speed_bonus": 0.50,
		"price": 15000,
		"required_level": 13,
		"symbol": "◆",
		"color": "#ff75d8",
	},
]


static func definition(transport_id: String) -> Dictionary:
	for entry in DEFINITIONS:
		if str(entry.id) == transport_id:
			return entry
	return {}


static func is_valid_id(transport_id: String) -> bool:
	return transport_id.is_empty() or not definition(transport_id).is_empty()


static func is_unlocked(player: Dictionary, transport: Dictionary) -> bool:
	return int(player.get("level", 1)) >= int(transport.get("required_level", 1))


static func is_owned(player: Dictionary, transport_id: String) -> bool:
	return player.get("owned_transport_ids", []).has(transport_id)


static func active_transport(player: Dictionary) -> Dictionary:
	var transport_id := str(player.get("active_transport_id", ""))
	if transport_id.is_empty() or not is_owned(player, transport_id):
		return {}
	return definition(transport_id)


static func speed_bonus(player: Dictionary) -> float:
	return float(active_transport(player).get("speed_bonus", 0.0))


static func effective_hunt_duration(player: Dictionary, base_duration: float) -> float:
	return maxf(MIN_HUNT_DURATION, base_duration * (1.0 - speed_bonus(player)))


static func effective_mission_duration(player: Dictionary, bounty: Dictionary) -> float:
	if not bool(bounty.get("mission_offer", false)):
		return effective_hunt_duration(player, float(bounty.get("duration", MIN_HUNT_DURATION)))
	var travel := maxf(0.0, float(bounty.get("travel_duration", 0.0)))
	var pursuit := maxf(1.0, float(bounty.get("pursuit_duration", 1.0)))
	return maxf(MIN_HUNT_DURATION, travel * (1.0 - speed_bonus(player)) + pursuit)


static func mission_saved_seconds(player: Dictionary, bounty: Dictionary) -> float:
	if not bool(bounty.get("mission_offer", false)):
		return saved_seconds(player, float(bounty.get("duration", MIN_HUNT_DURATION)))
	return maxf(0.0, float(bounty.get("travel_duration", 0.0)) * speed_bonus(player))


static func saved_seconds(player: Dictionary, base_duration: float) -> float:
	return maxf(0.0, base_duration - effective_hunt_duration(player, base_duration))


static func owned_ids_are_safe(records) -> bool:
	if not records is Array or records.size() > DEFINITIONS.size():
		return false
	var seen := {}
	for record in records:
		if not record is String or not is_valid_id(str(record)) or str(record).is_empty() or seen.has(str(record)):
			return false
		seen[str(record)] = true
	return true
