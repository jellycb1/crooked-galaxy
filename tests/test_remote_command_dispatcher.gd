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
	var split_character_revision := false
	var split_revision := false
	var split_board_revision := false
	var hunter_name := "Nova"

	func account_id() -> String:
		return owned_account

	func get_character() -> Dictionary:
		return make_character(revision + (1 if split_character_revision else 0))

	func get_economy() -> Dictionary:
		return make_economy(revision)

	func get_build() -> Dictionary:
		return make_build(revision + (1 if split_revision else 0))

	func get_hunt_board() -> Dictionary:
		return make_board(revision + (1 if split_board_revision else 0))

	func commit_profile(command_id: String, key: String, expected: int, next_name: String, appearance: Dictionary) -> Dictionary:
		var response := submit(command_id, key, "profile_commit", expected, {"hunter_name": next_name, "appearance": appearance})
		if bool(response.get("ok", false)) and str(response.get("status", "")) == "accepted":
			hunter_name = next_name
		return response

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

	func make_character(value: int) -> Dictionary:
		return {
			"ok": true, "exists": true, "api_version": 1, "authority": "server", "shard_id": "international_1",
			"account_id": owned_account, "character_id": owned_account, "revision": value, "server_unix_ms": 2000000000000,
			"profile": {"character_id": owned_account, "hunter_name": hunter_name, "level": 1, "xp": 0, "credits": 25,
				"warp_chips": 0, "scrap": 0},
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

	func make_board(value: int) -> Dictionary:
		return {
			"ok": true, "api_version": 1, "authority": "server", "shard_id": "international_1",
			"account_id": owned_account, "character_id": owned_account, "revision": value, "server_unix_ms": 2000000000000,
			"board_id": "board_1", "content_hash": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
			"offers": [{"offer_id": "offer_1", "target_id": "target_1", "planet_id": "planet_1", "role_id": "capture",
				"approach_ids": ["quiet_net"], "duration_seconds": 60, "fuel_cost": 10,
				"approaches": [{"approach_id": "quiet_net", "duration_seconds": 60, "fuel_cost": 10}]}],
		}


func _init() -> void:
	var adapter = FakeAdapter.new()
	var dispatcher = Dispatcher.new(adapter, "account_1")
	var boot: Dictionary = await dispatcher.bootstrap(4)
	check(bool(boot.get("ok", false)) and dispatcher.state() == Dispatcher.STATE_READY and dispatcher.revision() == 4, "matching character, economy, build, and hunt-board snapshots bootstrap one authoritative unit")
	check(str(dispatcher.character_snapshot().profile.hunter_name) == "Nova", "owned character presentation belongs to the same accepted revision")
	check(int(dispatcher.hunt_board().revision) == 4 and str(dispatcher.hunt_board().board_id) == "board_1", "the board exposed to callers belongs to the same accepted revision")

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
	var split_board_adapter = FakeAdapter.new()
	split_board_adapter.split_board_revision = true
	var split_board = Dispatcher.new(split_board_adapter, "account_1")
	var split_board_boot: Dictionary = await split_board.bootstrap()
	check(not bool(split_board_boot.get("ok", false)) and split_board.state() == Dispatcher.STATE_STALE, "a board from another revision fails closed before presentation")
	var split_character_adapter = FakeAdapter.new()
	split_character_adapter.split_character_revision = true
	var split_character = Dispatcher.new(split_character_adapter, "account_1")
	var split_character_boot: Dictionary = await split_character.bootstrap()
	check(not bool(split_character_boot.get("ok", false)) and split_character.state() == Dispatcher.STATE_STALE, "a character from another revision fails closed before presentation")
	var profile_adapter = FakeAdapter.new()
	var profile_dispatcher = Dispatcher.new(profile_adapter, "account_1")
	await profile_dispatcher.bootstrap(4)
	var profile_commit: Dictionary = await profile_dispatcher.dispatch("profile_1", "profile_idem_1", "profile_commit",
		{"hunter_name": "Vector", "appearance": {"palette": "cool"}})
	check(bool(profile_commit.get("ok", false)) and profile_commit.status == "accepted" and profile_dispatcher.revision() == 5
		and str(profile_dispatcher.character_snapshot().profile.hunter_name) == "Vector", "profile commit advances and refreshes the complete authority unit")
	profile_adapter.next_status = "duplicate"
	var profile_replay: Dictionary = await profile_dispatcher.replay_last_completed_explicit_test()
	check(bool(profile_replay.get("ok", false)) and profile_replay.status == "duplicate" and profile_dispatcher.revision() == 5,
		"profile idempotency replay preserves the original revision and complete unit")
	profile_adapter.next_status = "conflict"
	profile_adapter.revision = 7
	var profile_conflict: Dictionary = await profile_dispatcher.prove_conflict_explicit_test("profile_2", "profile_idem_2", "profile_commit",
		{"hunter_name": "Stale", "appearance": {"palette": "warm"}}, 4)
	check(bool(profile_conflict.get("ok", false)) and profile_conflict.status == "conflict" and profile_dispatcher.revision() == 7
		and str(profile_dispatcher.character_snapshot().profile.hunter_name) == "Vector", "profile conflict refetches server truth without applying stale intent")
	var foreign = Dispatcher.new(adapter, "foreign_account")
	var foreign_boot: Dictionary = await foreign.bootstrap()
	check(not bool(foreign_boot.get("ok", false)) and foreign.state() == Dispatcher.STATE_INERT, "foreign adapter ownership cannot bootstrap")
	var close_adapter = FakeAdapter.new()
	var close_dispatcher = Dispatcher.new(close_adapter, "account_1")
	await close_dispatcher.bootstrap()
	var closed: Dictionary = close_dispatcher.close_for_disconnect()
	check(bool(closed.get("ok", false)) and close_dispatcher.state() == Dispatcher.STATE_INERT and close_dispatcher.revision() == -1,
		"explicit disconnect closes the mutation boundary")
	check(close_dispatcher.character_snapshot().is_empty() and close_dispatcher.economy_snapshot().is_empty() and close_dispatcher.build_snapshot().is_empty() and close_dispatcher.hunt_board().is_empty()
		and not bool(close_dispatcher.safe_summary().mutations_allowed) and str(close_dispatcher.safe_summary().account_id).is_empty(),
		"closed dispatcher retains no owned online presentation or mutation state")
	var pending_close_adapter = FakeAdapter.new()
	var pending_close = Dispatcher.new(pending_close_adapter, "account_1")
	await pending_close.bootstrap()
	pending_close_adapter.transport_failures = 1
	await pending_close.dispatch("pending_close_1", "pending_close_idem_1", "hunt_resolve", {"hunt_id": "hunt_1"})
	check(not bool(pending_close.close_for_disconnect().get("ok", false)) and pending_close.has_pending_command(),
		"disconnect cannot silently erase a command with unknown outcome")

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
