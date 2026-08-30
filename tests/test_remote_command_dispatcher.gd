extends SceneTree

const Dispatcher = preload("res://scripts/remote_command_dispatcher.gd")
const Protocol = preload("res://scripts/backend_protocol_rules.gd")

var failures := 0


class FakeAdapter extends RefCounted:
	var owned_account := "account_1"
	var revision := 4
	var next_status := "accepted"
	var transport_failures := 0
	var submitted: Array[Dictionary] = []
	var forge_receipt := false
	var split_revision := false

	func account_id() -> String:
		return owned_account

	func get_economy() -> Dictionary:
		return make_economy(revision)

	func get_build() -> Dictionary:
		return make_build(revision + (1 if split_revision else 0))

	func accept_hunt(command_id: String, key: String, expected: int, board_id: String, offer_id: String, target_id: String, approach_id: String) -> Dictionary:
		return submit(command_id, key, "hunt_accept", expected, {"board_id": board_id, "offer_id": offer_id, "target_id": target_id, "approach_id": approach_id})

	func resolve_hunt(command_id: String, key: String, expected: int, hunt_id: String) -> Dictionary:
		return submit(command_id, key, "hunt_resolve", expected, {"hunt_id": hunt_id})

	func claim_reward(command_id: String, key: String, expected: int, hunt_id: String, reward_id: String, decision: String) -> Dictionary:
		return submit(command_id, key, "reward_claim", expected, {"hunt_id": hunt_id, "reward_id": reward_id, "decision": decision})

	func allocate_attributes(command_id: String, key: String, expected: int, allocations: Dictionary) -> Dictionary:
		return submit(command_id, key, "attribute_allocate", expected, {"allocations": allocations})

	func equip_item(command_id: String, key: String, expected: int, item_id: String) -> Dictionary:
		return submit(command_id, key, "inventory_equip", expected, {"item_id": item_id})

	func recycle_item(command_id: String, key: String, expected: int, item_id: String) -> Dictionary:
		return submit(command_id, key, "inventory_recycle", expected, {"item_id": item_id})

	func submit(command_id: String, key: String, operation: String, expected: int, payload: Dictionary) -> Dictionary:
		submitted.append({"command_id": command_id, "idempotency_key": key, "operation": operation, "expected_revision": expected, "payload": payload.duplicate(true)})
		if transport_failures > 0:
			transport_failures -= 1
			return {"ok": false, "error_code": "rpc_failed"}
		var server_revision := revision
		if next_status in ["accepted", "duplicate"]:
			server_revision = expected + 1
			revision = server_revision
		elif next_status == "conflict":
			server_revision = maxi(revision, expected)
		var receipt := {
			"ok": true, "api_version": 1, "authority": "server", "command_id": command_id,
			"idempotency_key": key, "operation": operation, "shard_id": "international_1",
			"character_id": owned_account, "status": next_status, "server_revision": server_revision,
			"server_unix_ms": 2000000000000, "reason_code": "domain_rejected" if next_status == "rejected" else "",
		}
		if forge_receipt:
			receipt.command_id = "forged_command"
		return receipt

	func make_economy(value: int) -> Dictionary:
		return {
			"ok": true, "api_version": 1, "authority": "server", "shard_id": "international_1",
			"account_id": owned_account, "character_id": owned_account, "revision": value, "server_unix_ms": 2000000000000,
			"economy": {"level": 1, "xp": 0, "credits": 25, "warp_chips": 0, "scrap": 0, "fuel": 100,
				"max_fuel": 100, "inventory_revision": 0, "inventory_count": 0, "active_hunt": {}, "pending_reward": {}},
		}

	func make_build(value: int) -> Dictionary:
		var equipment := {}
		for slot in ["weapon", "helmet", "armor", "gloves", "boots", "rig", "implant", "gadget", "relic"]:
			equipment[slot] = {}
		return {
			"ok": true, "api_version": 1, "authority": "server", "shard_id": "international_1",
			"account_id": owned_account, "character_id": owned_account, "revision": value, "server_unix_ms": 2000000000000,
			"build": {"base_power": 10, "attributes": {"strength": 10, "vitality": 10, "dexterity": 10, "intelligence": 10, "cunning": 10},
				"stat_points": 0, "inventory_revision": 0, "equipment": equipment, "inventory": []},
		}


func _init() -> void:
	var adapter = FakeAdapter.new()
	var dispatcher = Dispatcher.new(adapter, "account_1")
	var boot: Dictionary = await dispatcher.bootstrap(4)
	check(bool(boot.get("ok", false)) and dispatcher.state() == Dispatcher.STATE_READY and dispatcher.revision() == 4, "matching economy and build snapshots bootstrap one authoritative unit")

	var invalid: Dictionary = await dispatcher.dispatch("bad_1", "idem_bad_1", "hunt_accept", {"board_id": "board_1", "offer_id": "offer_1", "target_id": "target_1", "approach_id": "quiet_net", "fuel": 0})
	check(not bool(invalid.get("ok", false)) and adapter.submitted.is_empty(), "client authority fields are rejected before transport")

	adapter.transport_failures = 1
	var uncertain: Dictionary = await dispatcher.dispatch("command_1", "idem_1", "hunt_resolve", {"hunt_id": "hunt_1"})
	check(not bool(uncertain.get("ok", false)) and uncertain.action == Protocol.ACTION_RETRY_SAME_COMMAND and dispatcher.has_pending_command(), "unknown transport outcome preserves the original command")
	var blocked: Dictionary = await dispatcher.dispatch("command_2", "idem_2", "hunt_resolve", {"hunt_id": "hunt_2"})
	check(not bool(blocked.get("ok", false)) and adapter.submitted.size() == 1, "a second mutation cannot pass an uncertain command")
	var retried: Dictionary = await dispatcher.retry_pending()
	check(bool(retried.get("ok", false)) and retried.status == "accepted" and dispatcher.revision() == 5, "retry completes and refreshes the complete authoritative unit")
	check(adapter.submitted.size() == 2 and adapter.submitted[0] == adapter.submitted[1], "retry preserves command, idempotency key, revision, operation, and payload exactly")
	adapter.next_status = "duplicate"
	var replayed: Dictionary = await dispatcher.replay_last_completed_explicit_test()
	check(bool(replayed.get("ok", false)) and replayed.status == "duplicate" and dispatcher.revision() == 5, "explicit staging replay accepts the original server receipt without another revision")
	check(adapter.submitted.size() == 3 and adapter.submitted[1] == adapter.submitted[2], "completed replay also preserves the exact original command identity")

	adapter.next_status = "conflict"
	adapter.revision = 8
	var conflict: Dictionary = await dispatcher.dispatch("command_3", "idem_3", "inventory_equip", {"item_id": "item_1"})
	check(bool(conflict.get("ok", false)) and conflict.status == "conflict" and conflict.action == Protocol.ACTION_FETCH_SNAPSHOT and dispatcher.revision() == 8, "revision conflict refetches instead of replaying or merging")
	check(not dispatcher.has_pending_command(), "known conflict clears the obsolete command identity")

	adapter.next_status = "rejected"
	var rejected: Dictionary = await dispatcher.dispatch("command_4", "idem_4", "inventory_recycle", {"item_id": "item_1"})
	check(bool(rejected.get("ok", false)) and rejected.action == Protocol.ACTION_STOP and dispatcher.revision() == 8, "domain rejection stops after refreshing server truth")

	adapter.next_status = "accepted"
	adapter.forge_receipt = true
	var forged: Dictionary = await dispatcher.dispatch("command_5", "idem_5", "attribute_allocate", {"allocations": {"strength": 1}})
	check(not bool(forged.get("ok", false)) and dispatcher.state() == Dispatcher.STATE_STALE, "forged receipt identity makes the dispatcher stale")
	check(dispatcher.has_pending_command(), "invalid receipt keeps the uncertain identity for investigation")
	var abandoned := dispatcher.abandon_pending_for_disconnect()
	check(bool(abandoned.get("abandoned", false)) and str(abandoned.command.command_id) == "command_5" and not dispatcher.has_pending_command(), "disconnect can explicitly abandon but never silently replace an uncertain command")

	var split_adapter = FakeAdapter.new()
	split_adapter.split_revision = true
	var split = Dispatcher.new(split_adapter, "account_1")
	var split_boot: Dictionary = await split.bootstrap()
	check(not bool(split_boot.get("ok", false)) and split.state() == Dispatcher.STATE_STALE, "split economy/build revisions fail closed")
	var foreign = Dispatcher.new(adapter, "foreign_account")
	var foreign_boot: Dictionary = await foreign.bootstrap()
	check(not bool(foreign_boot.get("ok", false)) and foreign.state() == Dispatcher.STATE_INERT, "foreign adapter ownership cannot bootstrap")

	if failures == 0:
		print("PASS: remote command dispatcher preserves authority, exact retries, and full-snapshot conflict recovery")
		quit(0)
	else:
		printerr("FAIL: %d remote command dispatcher issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
