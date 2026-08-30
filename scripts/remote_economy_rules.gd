class_name RemoteEconomyRules
extends RefCounted

const API_VERSION := 1
const SHARD_ID := "international_1"
const MAX_UNIX_MS := 4102444800000
const MAX_INVENTORY_COUNT := 1000

const OP_HUNT_ACCEPT := "hunt_accept"
const OP_HUNT_RESOLVE := "hunt_resolve"
const OP_REWARD_CLAIM := "reward_claim"
const OP_ATTRIBUTE_ALLOCATE := "attribute_allocate"
const OP_INVENTORY_EQUIP := "inventory_equip"
const OP_INVENTORY_RECYCLE := "inventory_recycle"
const OPERATIONS := [OP_HUNT_ACCEPT, OP_HUNT_RESOLVE, OP_REWARD_CLAIM, OP_ATTRIBUTE_ALLOCATE, OP_INVENTORY_EQUIP, OP_INVENTORY_RECYCLE]
const ATTRIBUTE_KEYS := ["strength", "vitality", "dexterity", "intelligence", "cunning"]
const EQUIPMENT_SLOTS := ["weapon", "helmet", "armor", "gloves", "boots", "rig", "implant", "gadget", "relic"]

const REWARD_STORE := "store"
const REWARD_EQUIP := "equip"
const REWARD_RECYCLE := "recycle"
const REWARD_DECISIONS := [REWARD_STORE, REWARD_EQUIP, REWARD_RECYCLE]
const MAX_HUNT_OFFERS := 3
const MAX_HUNT_APPROACHES := 3

const FORBIDDEN_CLIENT_AUTHORITY_KEYS := {
	"level": true,
	"xp": true,
	"credits": true,
	"warp_chips": true,
	"scrap": true,
	"fuel": true,
	"stat_points": true,
	"base_power": true,
	"equipment": true,
	"inventory": true,
	"inventory_revision": true,
	"item_level": true,
	"scrap_value": true,
	"power": true,
	"reward": true,
	"reward_amount": true,
	"cost": true,
	"won": true,
	"damage": true,
	"odds": true,
	"duration": true,
	"accepted_at_unix_ms": true,
	"resolves_at_unix_ms": true,
}


static func valid_command_payload(operation: String, payload: Dictionary) -> bool:
	if _contains_forbidden_authority(payload):
		return false
	match operation:
		OP_HUNT_ACCEPT:
			return _has_exact_keys(payload, ["board_id", "offer_id", "target_id", "approach_id"]) \
				and _valid_identifier(str(payload.board_id)) \
				and _valid_identifier(str(payload.offer_id)) \
				and _valid_identifier(str(payload.target_id)) \
				and _valid_identifier(str(payload.approach_id))
		OP_HUNT_RESOLVE:
			return _has_exact_keys(payload, ["hunt_id"]) and _valid_identifier(str(payload.hunt_id))
		OP_REWARD_CLAIM:
			return _has_exact_keys(payload, ["hunt_id", "reward_id", "decision"]) \
				and _valid_identifier(str(payload.hunt_id)) \
				and _valid_identifier(str(payload.reward_id)) \
				and str(payload.decision) in REWARD_DECISIONS
		OP_ATTRIBUTE_ALLOCATE:
			if not _has_exact_keys(payload, ["allocations"]) or not payload.allocations is Dictionary or payload.allocations.is_empty():
				return false
			var total := 0
			for attribute_id in payload.allocations:
				var amount = payload.allocations[attribute_id]
				if str(attribute_id) not in ATTRIBUTE_KEYS or not _is_positive_integer(amount):
					return false
				total += int(amount)
			return total > 0
		OP_INVENTORY_EQUIP, OP_INVENTORY_RECYCLE:
			return _has_exact_keys(payload, ["item_id"]) and _valid_identifier(str(payload.item_id))
	return false


static func canonical_economy_snapshot(response: Dictionary, expected_account_id: String, expected_character_id: String) -> Dictionary:
	if int(response.get("api_version", -1)) != API_VERSION \
		or str(response.get("authority", "")) != "server" \
		or str(response.get("shard_id", "")) != SHARD_ID:
		return {}
	if not _valid_identifier(expected_account_id) or not _valid_identifier(expected_character_id):
		return {}
	if str(response.get("account_id", "")) != expected_account_id or str(response.get("character_id", "")) != expected_character_id:
		return {}
	var revision := int(response.get("revision", -1))
	var server_unix_ms := int(response.get("server_unix_ms", -1))
	var economy = response.get("economy", null)
	if revision < 0 or not _valid_unix_ms(server_unix_ms) or not economy is Dictionary:
		return {}
	var expected_keys := ["level", "xp", "credits", "warp_chips", "scrap", "fuel", "max_fuel", "inventory_revision", "inventory_count", "active_hunt", "pending_reward"]
	if not _has_exact_keys(economy, expected_keys):
		return {}
	for key in ["level", "xp", "credits", "warp_chips", "scrap", "fuel", "max_fuel", "inventory_revision", "inventory_count"]:
		if not _is_nonnegative_integer(economy[key]):
			return {}
	if int(economy.level) < 1 or int(economy.max_fuel) < 1 or int(economy.fuel) > int(economy.max_fuel):
		return {}
	if int(economy.inventory_count) > MAX_INVENTORY_COUNT:
		return {}
	var active_hunt := _canonical_active_hunt(economy.active_hunt)
	if not economy.active_hunt.is_empty() and active_hunt.is_empty():
		return {}
	var pending_reward := _canonical_pending_reward(economy.pending_reward)
	if not economy.pending_reward.is_empty() and pending_reward.is_empty():
		return {}
	if not active_hunt.is_empty() and not pending_reward.is_empty():
		return {}
	return {
		"api_version": API_VERSION,
		"authority": "server",
		"shard_id": SHARD_ID,
		"account_id": expected_account_id,
		"character_id": expected_character_id,
		"revision": revision,
		"server_unix_ms": server_unix_ms,
		"economy": {
			"level": int(economy.level),
			"xp": int(economy.xp),
			"credits": int(economy.credits),
			"warp_chips": int(economy.warp_chips),
			"scrap": int(economy.scrap),
			"fuel": int(economy.fuel),
			"max_fuel": int(economy.max_fuel),
			"inventory_revision": int(economy.inventory_revision),
			"inventory_count": int(economy.inventory_count),
			"active_hunt": active_hunt,
			"pending_reward": pending_reward,
		},
	}


static func canonical_build_snapshot(response: Dictionary, expected_account_id: String, expected_character_id: String) -> Dictionary:
	if int(response.get("api_version", -1)) != API_VERSION or str(response.get("authority", "")) != "server" or str(response.get("shard_id", "")) != SHARD_ID:
		return {}
	if not _valid_identifier(expected_account_id) or not _valid_identifier(expected_character_id):
		return {}
	if str(response.get("account_id", "")) != expected_account_id or str(response.get("character_id", "")) != expected_character_id:
		return {}
	var revision := int(response.get("revision", -1))
	var server_unix_ms := int(response.get("server_unix_ms", -1))
	var build = response.get("build", null)
	if revision < 0 or not _valid_unix_ms(server_unix_ms) or not build is Dictionary:
		return {}
	if not _has_exact_keys(build, ["base_power", "attributes", "stat_points", "inventory_revision", "equipment", "inventory"]):
		return {}
	if not _is_nonnegative_integer(build.base_power) or not _is_nonnegative_integer(build.stat_points) or not _is_nonnegative_integer(build.inventory_revision):
		return {}
	if not build.attributes is Dictionary or not _has_exact_keys(build.attributes, ATTRIBUTE_KEYS):
		return {}
	for attribute_id in ATTRIBUTE_KEYS:
		if not _is_nonnegative_integer(build.attributes[attribute_id]) or int(build.attributes[attribute_id]) < 10:
			return {}
	if not build.equipment is Dictionary or not _has_exact_keys(build.equipment, EQUIPMENT_SLOTS) or not build.inventory is Array or build.inventory.size() > MAX_INVENTORY_COUNT:
		return {}
	var canonical_equipment := {}
	for slot in EQUIPMENT_SLOTS:
		var item := _canonical_item(build.equipment[slot], slot, true)
		if not build.equipment[slot].is_empty() and item.is_empty():
			return {}
		canonical_equipment[slot] = item
	var canonical_inventory: Array = []
	var owned_ids := {}
	for value in build.inventory:
		var item := _canonical_item(value, "", false)
		if item.is_empty() or owned_ids.has(item.id):
			return {}
		owned_ids[item.id] = true
		canonical_inventory.append(item)
	for slot in EQUIPMENT_SLOTS:
		var equipped: Dictionary = canonical_equipment[slot]
		if not equipped.is_empty() and not str(equipped.id).begins_with("starter_") and not owned_ids.has(equipped.id):
			return {}
	return {"api_version": API_VERSION, "authority": "server", "shard_id": SHARD_ID, "account_id": expected_account_id,
		"character_id": expected_character_id, "revision": revision, "server_unix_ms": server_unix_ms,
		"build": {"base_power": int(build.base_power), "attributes": build.attributes.duplicate(true), "stat_points": int(build.stat_points),
			"inventory_revision": int(build.inventory_revision), "equipment": canonical_equipment, "inventory": canonical_inventory}}


static func canonical_hunt_board(response: Dictionary, expected_account_id: String, expected_character_id: String) -> Dictionary:
	if int(response.get("api_version", -1)) != API_VERSION or str(response.get("authority", "")) != "server" or str(response.get("shard_id", "")) != SHARD_ID:
		return {}
	if str(response.get("account_id", "")) != expected_account_id or str(response.get("character_id", "")) != expected_character_id:
		return {}
	var revision := int(response.get("revision", -1))
	var server_unix_ms := int(response.get("server_unix_ms", -1))
	var board_id := str(response.get("board_id", ""))
	var content_hash := str(response.get("content_hash", ""))
	var offers = response.get("offers", null)
	if revision < 0 or not _valid_unix_ms(server_unix_ms) or not _valid_identifier(board_id) or not _valid_hash(content_hash):
		return {}
	if not offers is Array or offers.is_empty() or offers.size() > MAX_HUNT_OFFERS:
		return {}
	var canonical_offers: Array = []
	var offer_ids := {}
	for value in offers:
		var offer := _canonical_hunt_offer(value)
		if offer.is_empty() or offer_ids.has(offer.offer_id):
			return {}
		offer_ids[offer.offer_id] = true
		canonical_offers.append(offer)
	return {"api_version": API_VERSION, "authority": "server", "shard_id": SHARD_ID,
		"account_id": expected_account_id, "character_id": expected_character_id, "revision": revision,
		"server_unix_ms": server_unix_ms, "content_hash": content_hash, "board_id": board_id, "offers": canonical_offers}


static func _canonical_hunt_offer(value: Variant) -> Dictionary:
	if not value is Dictionary or not _has_exact_keys(value, ["offer_id", "target_id", "planet_id", "role_id", "approach_ids", "duration_seconds", "fuel_cost", "approaches"]):
		return {}
	for key in ["offer_id", "target_id", "planet_id", "role_id"]:
		if not _valid_identifier(str(value[key])):
			return {}
	if not _is_positive_integer(value.duration_seconds) or not _is_positive_integer(value.fuel_cost):
		return {}
	if not value.approach_ids is Array or not value.approaches is Array or value.approach_ids.is_empty() or value.approach_ids.size() > MAX_HUNT_APPROACHES or value.approach_ids.size() != value.approaches.size():
		return {}
	var approach_ids: Array = []
	var approaches: Array = []
	for index in value.approach_ids.size():
		var approach_id := str(value.approach_ids[index])
		var approach = value.approaches[index]
		if not _valid_identifier(approach_id) or approach_ids.has(approach_id) or not approach is Dictionary:
			return {}
		for required in ["approach_id", "duration_seconds", "fuel_cost"]:
			if not approach.has(required):
				return {}
		if str(approach.approach_id) != approach_id or not _is_positive_integer(approach.duration_seconds) or not _is_positive_integer(approach.fuel_cost):
			return {}
		approach_ids.append(approach_id)
		approaches.append({"approach_id": approach_id, "duration_seconds": int(approach.duration_seconds), "fuel_cost": int(approach.fuel_cost)})
	return {"offer_id": str(value.offer_id), "target_id": str(value.target_id), "planet_id": str(value.planet_id),
		"role_id": str(value.role_id), "approach_ids": approach_ids, "duration_seconds": int(value.duration_seconds),
		"fuel_cost": int(value.fuel_cost), "approaches": approaches}


static func _canonical_item(value: Variant, expected_slot: String, allow_empty: bool) -> Dictionary:
	if not value is Dictionary:
		return {}
	if value.is_empty():
		return {} if allow_empty else {}
	for required in ["id", "slot", "power", "origin_planet_id"]:
		if not value.has(required):
			return {}
	var item_id := str(value.id)
	var slot := str(value.slot)
	if not _valid_identifier(item_id) or slot not in EQUIPMENT_SLOTS or (not expected_slot.is_empty() and slot != expected_slot):
		return {}
	if not _is_nonnegative_integer(value.power) or not value.origin_planet_id is String or (not str(value.origin_planet_id).is_empty() and not _valid_identifier(str(value.origin_planet_id))):
		return {}
	var allowed := ["id", "slot", "power", "origin_planet_id", "item_level", "trait", "integrity_upgrades", "attribute_package_id"]
	for key in value:
		if str(key) not in allowed:
			return {}
	if value.has("item_level") and not _is_nonnegative_integer(value.item_level):
		return {}
	if value.has("integrity_upgrades") and not _is_nonnegative_integer(value.integrity_upgrades):
		return {}
	if value.has("trait"):
		if not value.trait is Dictionary:
			return {}
		var allowed_traits := ["power_bonus", "health_bonus", "opening_damage_bonus", "damage_reduction", "evasion_chance_bonus", "defense_bypass_bonus", "counter_damage_bonus", "counter_every_rounds", "follow_up_damage_ratio", "follow_up_roll_threshold"]
		for trait_id in value.trait:
			if str(trait_id) not in allowed_traits or not (value.trait[trait_id] is int or value.trait[trait_id] is float) or float(value.trait[trait_id]) < 0.0:
				return {}
	if value.has("attribute_package_id") and not value.attribute_package_id is String:
		return {}
	return value.duplicate(true)


static func _canonical_active_hunt(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	if value.is_empty():
		return {}
	if not _has_exact_keys(value, ["hunt_id", "offer_id", "target_id", "approach_id", "accepted_at_unix_ms", "resolves_at_unix_ms"]):
		return {}
	for key in ["hunt_id", "offer_id", "target_id", "approach_id"]:
		if not _valid_identifier(str(value[key])):
			return {}
	var accepted_at := int(value.accepted_at_unix_ms)
	var resolves_at := int(value.resolves_at_unix_ms)
	if not _valid_unix_ms(accepted_at) or not _valid_unix_ms(resolves_at) or resolves_at <= accepted_at:
		return {}
	return value.duplicate(true)


static func _canonical_pending_reward(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	if value.is_empty():
		return {}
	if not _has_exact_keys(value, ["reward_id", "hunt_id", "state"]):
		return {}
	if not _valid_identifier(str(value.reward_id)) or not _valid_identifier(str(value.hunt_id)) or str(value.state) != "sealed":
		return {}
	return value.duplicate(true)


static func _has_exact_keys(value: Dictionary, expected: Array) -> bool:
	if value.size() != expected.size():
		return false
	for key in expected:
		if not value.has(key):
			return false
	return true


static func _contains_forbidden_authority(value: Variant) -> bool:
	if value is Dictionary:
		for key in value:
			if FORBIDDEN_CLIENT_AUTHORITY_KEYS.has(str(key).to_lower()) or _contains_forbidden_authority(value[key]):
				return true
	elif value is Array:
		for entry in value:
			if _contains_forbidden_authority(entry):
				return true
	return false


static func _is_nonnegative_integer(value: Variant) -> bool:
	return (value is int or value is float) and float(value) >= 0.0 and floorf(float(value)) == float(value)


static func _is_positive_integer(value: Variant) -> bool:
	return _is_nonnegative_integer(value) and int(value) > 0


static func _valid_identifier(value: String) -> bool:
	if value.is_empty() or value.length() > 128:
		return false
	for index in value.length():
		var code := value.unicode_at(index)
		var allowed := (code >= 97 and code <= 122) or (code >= 48 and code <= 57) or code in [45, 46, 95]
		if not allowed:
			return false
	return true


static func _valid_hash(value: String) -> bool:
	if value.length() != 64:
		return false
	for index in value.length():
		var code := value.unicode_at(index)
		if not ((code >= 48 and code <= 57) or (code >= 97 and code <= 102)):
			return false
	return true


static func _valid_unix_ms(value: int) -> bool:
	return value >= 0 and value <= MAX_UNIX_MS
