extends SceneTree

const Economy = preload("res://scripts/remote_economy_rules.gd")
const Protocol = preload("res://scripts/backend_protocol_rules.gd")

var failures := 0
var now_ms := 1788000000000


func _init() -> void:
	test_command_intent_boundary()
	test_authoritative_snapshot_boundary()
	test_build_authority_boundary()
	if failures == 0:
		print("PASS: remote economy commands carry intent only and snapshots preserve server authority")
		quit(0)
	else:
		printerr("FAIL: %d remote-economy issue(s)" % failures)
		quit(1)


func test_command_intent_boundary() -> void:
	var accepted := Protocol.make_command("cmd_accept_1", "idem_accept_1", Economy.OP_HUNT_ACCEPT, "session_44", "hunter_7", 19, {
		"board_id": "board_31",
		"offer_id": "offer_2",
		"target_id": "target_77",
		"approach_id": "quiet_network",
	})
	check(not accepted.is_empty(), "hunt acceptance sends selected authored identities and expected revision")
	check(Protocol.make_command("cmd_accept_2", "idem_accept_2", Economy.OP_HUNT_ACCEPT, "session_44", "hunter_7", 19, {
		"board_id": "board_31", "offer_id": "offer_2", "target_id": "target_77", "approach_id": "quiet_network", "fuel": 0,
	}).is_empty(), "client cannot author fuel cost or balance during hunt acceptance")
	check(not Protocol.make_command("cmd_resolve_1", "idem_resolve_1", Economy.OP_HUNT_RESOLVE, "session_44", "hunter_7", 20, {"hunt_id": "hunt_55"}).is_empty(), "hunt resolution requests one server-owned hunt without sending its outcome")
	check(Protocol.make_command("cmd_resolve_2", "idem_resolve_2", Economy.OP_HUNT_RESOLVE, "session_44", "hunter_7", 20, {"hunt_id": "hunt_55", "won": true}).is_empty(), "client cannot claim combat victory")
	check(not Protocol.make_command("cmd_claim_1", "idem_claim_1", Economy.OP_REWARD_CLAIM, "session_44", "hunter_7", 21, {
		"hunt_id": "hunt_55", "reward_id": "reward_55", "decision": Economy.REWARD_STORE,
	}).is_empty(), "reward claim sends only server-issued identities and a disposition")
	check(Protocol.make_command("cmd_claim_2", "idem_claim_2", Economy.OP_REWARD_CLAIM, "session_44", "hunter_7", 21, {
		"hunt_id": "hunt_55", "reward_id": "reward_55", "decision": Economy.REWARD_STORE, "credits": 999999,
	}).is_empty(), "client cannot inject reward value into a claim")
	check(Protocol.make_command("cmd_claim_3", "idem_claim_3", Economy.OP_REWARD_CLAIM, "session_44", "hunter_7", 21, {
		"hunt_id": "hunt_55", "reward_id": "reward_55", "decision": "duplicate",
	}).is_empty(), "unknown reward dispositions are rejected")
	check(not Protocol.make_command("cmd_stats_1", "idem_stats_1", Economy.OP_ATTRIBUTE_ALLOCATE, "session_44", "hunter_7", 22, {
		"allocations": {"strength": 2, "vitality": 1},
	}).is_empty(), "attribute allocation sends only positive point intentions")
	check(Protocol.make_command("cmd_stats_2", "idem_stats_2", Economy.OP_ATTRIBUTE_ALLOCATE, "session_44", "hunter_7", 22, {
		"allocations": {"strength": 2}, "stat_points": 99,
	}).is_empty(), "client cannot author its remaining stat-point balance")
	check(Protocol.make_command("cmd_stats_3", "idem_stats_3", Economy.OP_ATTRIBUTE_ALLOCATE, "session_44", "hunter_7", 22, {
		"allocations": {"luck": 1},
	}).is_empty(), "unknown attributes fail closed")
	check(not Protocol.make_command("cmd_equip_1", "idem_equip_1", Economy.OP_INVENTORY_EQUIP, "session_44", "hunter_7", 22, {"item_id": "drop_77"}).is_empty(), "equipment command identifies one owned item only")
	check(Protocol.make_command("cmd_equip_2", "idem_equip_2", Economy.OP_INVENTORY_EQUIP, "session_44", "hunter_7", 22, {"item_id": "drop_77", "power": 999}).is_empty(), "client cannot author equipment power")
	check(not Protocol.make_command("cmd_recycle_1", "idem_recycle_1", Economy.OP_INVENTORY_RECYCLE, "session_44", "hunter_7", 22, {"item_id": "drop_77"}).is_empty(), "recycle command identifies one owned item only")


func test_authoritative_snapshot_boundary() -> void:
	var response := valid_snapshot()
	var canonical := Economy.canonical_economy_snapshot(response, "account_42", "hunter_7")
	check(not canonical.is_empty() and int(canonical.revision) == 22 and int(canonical.economy.fuel) == 74, "matching server economy snapshot preserves one authoritative revision")
	check(not canonical.has("access_token") and str(canonical.authority) == "server", "canonical economy snapshot exposes no transport credential")
	check(Economy.canonical_economy_snapshot(response, "account_42", "hunter_8").is_empty(), "foreign economy ownership is rejected")
	var overfilled := response.duplicate(true)
	overfilled.economy.fuel = 101
	check(Economy.canonical_economy_snapshot(overfilled, "account_42", "hunter_7").is_empty(), "fuel cannot exceed the server-declared capacity")
	var overlapping := response.duplicate(true)
	overlapping.economy.pending_reward = {"reward_id": "reward_55", "hunt_id": "hunt_55", "state": "sealed"}
	check(Economy.canonical_economy_snapshot(overlapping, "account_42", "hunter_7").is_empty(), "one snapshot cannot expose both an active hunt and a pending reward")
	var client_timing := response.duplicate(true)
	client_timing.economy.active_hunt.resolves_at_unix_ms = int(client_timing.economy.active_hunt.accepted_at_unix_ms)
	check(Economy.canonical_economy_snapshot(client_timing, "account_42", "hunter_7").is_empty(), "server hunt deadline must advance beyond acceptance")
	var expanded := response.duplicate(true)
	expanded.economy.unknown_wallet = 1
	check(Economy.canonical_economy_snapshot(expanded, "account_42", "hunter_7").is_empty(), "unknown wallet fields fail closed instead of entering cached authority")


func test_build_authority_boundary() -> void:
	var response := valid_build_snapshot()
	var canonical := Economy.canonical_build_snapshot(response, "account_42", "hunter_7")
	check(not canonical.is_empty() and int(canonical.build.attributes.strength) == 14 and canonical.build.inventory.size() == 1, "build snapshot preserves exact attributes and owned inventory")
	check(str(canonical.build.equipment.weapon.id) == "drop_77" and int(canonical.build.inventory_revision) == 8, "equipped item is backed by the authoritative ownership list")
	var orphan := response.duplicate(true)
	orphan.build.inventory.clear()
	check(Economy.canonical_build_snapshot(orphan, "account_42", "hunter_7").is_empty(), "non-starter equipped items must remain in owned inventory")
	var duplicate := response.duplicate(true)
	duplicate.build.inventory.append(duplicate.build.inventory[0].duplicate(true))
	check(Economy.canonical_build_snapshot(duplicate, "account_42", "hunter_7").is_empty(), "duplicate item identities fail closed")
	var forged := response.duplicate(true)
	forged.build.inventory[0].power = -1
	check(Economy.canonical_build_snapshot(forged, "account_42", "hunter_7").is_empty(), "invalid server item values cannot enter the local cache")


func valid_build_snapshot() -> Dictionary:
	var item := {"id": "drop_77", "slot": "weapon", "power": 12, "item_level": 9, "origin_planet_id": "dustball_prime"}
	return {"api_version": 1, "authority": "server", "shard_id": "international_1", "account_id": "account_42", "character_id": "hunter_7",
		"revision": 22, "server_unix_ms": now_ms, "build": {"base_power": 20,
			"attributes": {"strength": 14, "vitality": 12, "dexterity": 10, "intelligence": 10, "cunning": 10}, "stat_points": 3,
			"inventory_revision": 8, "equipment": {"weapon": item.duplicate(true), "helmet": {}, "armor": {"id": "starter_armor", "slot": "armor", "power": 1, "origin_planet_id": ""}, "gloves": {}, "boots": {}, "rig": {}, "implant": {}, "gadget": {}, "relic": {}},
			"inventory": [item]}}


func valid_snapshot() -> Dictionary:
	return {
		"api_version": 1,
		"authority": "server",
		"shard_id": "international_1",
		"account_id": "account_42",
		"character_id": "hunter_7",
		"revision": 22,
		"server_unix_ms": now_ms,
		"economy": {
			"level": 31,
			"xp": 1900,
			"credits": 8900,
			"warp_chips": 12,
			"scrap": 44,
			"fuel": 74,
			"max_fuel": 100,
			"inventory_revision": 8,
			"inventory_count": 27,
			"active_hunt": {
				"hunt_id": "hunt_55",
				"offer_id": "offer_2",
				"target_id": "target_77",
				"approach_id": "quiet_network",
				"accepted_at_unix_ms": now_ms - 60000,
				"resolves_at_unix_ms": now_ms + 60000,
			},
			"pending_reward": {},
		},
	}


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
