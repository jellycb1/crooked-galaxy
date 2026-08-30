extends SceneTree

const Sync = preload("res://scripts/profile_sync_rules.gd")
const CacheStore = preload("res://scripts/profile_cache_store.gd")

var failures := 0


func _init() -> void:
	var server_time := 2000000000000
	var snapshot := {
		"api_version": 1, "authority": "server", "shard_id": "international_1",
		"account_id": "account_1", "character_id": "character_1", "revision": 4,
		"server_unix_ms": server_time,
		"profile": {"character_id": "character_1", "hunter_name": "Nova", "level": 7, "xp": 0, "credits": 80, "warp_chips": 0, "scrap": 0},
	}
	var cache := Sync.make_read_only_cache(snapshot, "account_1", "character_1", server_time + 1000)
	check(not cache.is_empty(), "authoritative owned snapshot creates a bounded cache envelope")
	var opened := Sync.open_read_only_cache(cache, "account_1", "character_1", server_time + 2000)
	check(str(opened.get("state", "")) == "offline_cached" and bool(opened.get("read_only", false)), "valid recent cache opens only as explicitly cached state")
	check(not bool(opened.get("economic_mutations_allowed", true)) and not bool(opened.get("social_actions_allowed", true)) and not bool(opened.get("billing_allowed", true)), "offline cache disables economy, social actions, and billing")
	check(Sync.open_read_only_cache(cache, "foreign", "character_1", server_time + 2000).is_empty(), "cache cannot change account ownership")
	var altered := cache.duplicate(true)
	altered.server_revision = 9
	check(Sync.open_read_only_cache(altered, "account_1", "character_1", server_time + 2000).is_empty(), "cache rejects revision metadata that diverges from its snapshot")
	check(Sync.open_read_only_cache(cache, "account_1", "character_1", server_time + Sync.MAX_CACHE_AGE_MS + 1001).is_empty(), "expired cache cannot impersonate current server state")
	var store = CacheStore.new()
	store.cache_path = "res://.godot/profile_cache_%s.json" % OS.get_process_id()
	store.clear()
	check(store.write_snapshot(snapshot, "account_1", "character_1", server_time + 1000), "validated snapshot writes through an atomic staging file")
	var stored := store.load_snapshot("account_1", "character_1", server_time + 2000)
	check(bool(stored.get("read_only", false)) and int(stored.get("snapshot", {}).get("revision", -1)) == 4, "persistent cache reopens as the same read-only revision")
	check(store.load_snapshot("foreign", "character_1", server_time + 2000).is_empty(), "persistent cache never crosses account ownership")
	store.clear()
	check(store.load_snapshot("account_1", "character_1", server_time + 2000).is_empty(), "explicit cache removal clears primary, staging, and backup copies")
	var economy := make_economy_snapshot(4, server_time)
	var build := make_build_snapshot(4, server_time)
	var authority_cache := Sync.make_read_only_authority_cache(snapshot, economy, build, "account_1", "character_1", server_time + 1000)
	check(not authority_cache.is_empty() and int(authority_cache.cache_schema) == Sync.AUTHORITY_CACHE_SCHEMA, "matching profile, economy, and build create one composite cache envelope")
	var authority_opened := Sync.open_read_only_authority_cache(authority_cache, "account_1", "character_1", server_time + 2000)
	check(bool(authority_opened.get("read_only", false)) and int(authority_opened.get("revision", -1)) == 4
		and int(authority_opened.economy_snapshot.economy.credits) == 80 and int(authority_opened.build_snapshot.build.base_power) == 10,
		"composite cache reopens all three owned views at one read-only revision")
	check(not authority_opened.has("hunt_board") and not bool(authority_opened.get("economic_mutations_allowed", true)), "offline cache excludes expiring offers and every mutation capability")
	var split_build := build.duplicate(true)
	split_build.revision = 5
	check(Sync.make_read_only_authority_cache(snapshot, economy, split_build, "account_1", "character_1", server_time + 1000).is_empty(), "split profile/economy/build revisions cannot enter the cache")
	var contradictory_economy := economy.duplicate(true)
	contradictory_economy.economy.credits = 81
	check(Sync.make_read_only_authority_cache(snapshot, contradictory_economy, build, "account_1", "character_1", server_time + 1000).is_empty(), "same-revision wallet contradictions fail closed")
	store.clear()
	check(store.write_authority_unit(snapshot, economy, build, "account_1", "character_1", server_time + 1000), "composite authority cache writes through the atomic store")
	var stored_unit := store.load_authority_unit("account_1", "character_1", server_time + 2000)
	check(int(stored_unit.get("revision", -1)) == 4 and bool(stored_unit.get("read_only", false)), "persistent composite cache restores the exact authority revision")
	check(store.load_authority_unit("foreign", "character_1", server_time + 2000).is_empty(), "persistent composite cache cannot cross ownership")
	store.clear()

	var pending := [{"command_id": "command_1", "idempotency_key": "receipt_1"}]
	check(Sync.reconnect_action(4, 4, pending, true) == Sync.ACTION_RETRY_PENDING, "reconnect retries the exact pending command when the server has not advanced")
	check(Sync.reconnect_action(4, 5, pending, true) == Sync.ACTION_REVIEW_CONFLICT, "server advancement with pending work requires visible conflict review")
	check(Sync.reconnect_action(4, 5, [], true) == Sync.ACTION_USE_REMOTE, "uncontested reconnect replaces cache with the authoritative snapshot")
	check(Sync.reconnect_action(5, 4, [], true) == Sync.ACTION_REJECT_REMOTE, "server revision regression is rejected instead of uploaded or merged")
	check(Sync.reconnect_action(4, 4, pending, false) == Sync.ACTION_REJECT_REMOTE, "foreign remote ownership is rejected")
	check(Sync.reconnect_action(4, 4, [pending[0], pending[0]], true) == Sync.ACTION_REJECT_REMOTE, "duplicate pending idempotency identities invalidate the queue")

	var local := {"character_id": "local_character_primary", "level": 8, "xp": 900, "wins": 12}
	var pristine_remote := {"authority": "server", "revision": 0, "profile": {"level": 1, "xp": 0, "credits": 25, "warp_chips": 0, "scrap": 0}}
	var offer := Sync.migration_offer(local, pristine_remote, false)
	check(offer == Sync.MIGRATION_CUTOVER_REQUIRED, "established local progress versus pristine remote requires one explicit archival cutover")
	check(Sync.canonical_migration_choice(Sync.MIGRATION_ARCHIVE_AND_START_REMOTE, offer) == Sync.MIGRATION_ARCHIVE_AND_START_REMOTE, "explicit archival cutover preserves the authoritative remote baseline")
	check(Sync.canonical_migration_choice("request_local_import", offer) == Sync.MIGRATION_NONE, "untrusted local progress cannot enter the server economy")
	check(Sync.canonical_migration_choice("keep_remote", offer) == Sync.MIGRATION_NONE, "legacy ambiguous migration choices fail closed")
	check(Sync.canonical_migration_choice("merge", offer) == Sync.MIGRATION_NONE, "field merge is not a migration option")
	check(Sync.migration_offer(local, pristine_remote, true) == Sync.MIGRATION_NONE, "recorded migration decision cannot be offered twice")
	var progressed_remote := pristine_remote.duplicate(true)
	progressed_remote.revision = 1
	check(Sync.migration_offer(local, progressed_remote, false) == Sync.MIGRATION_NONE, "cutover is never offered over progressed remote state")

	if failures == 0:
		print("PASS: offline cache, reconnect, and one-time migration decisions never merge or invent authority")
		quit(0)
	else:
		printerr("FAIL: %d profile-sync issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)


func make_economy_snapshot(revision: int, server_time: int) -> Dictionary:
	return {
		"api_version": 1, "authority": "server", "shard_id": "international_1",
		"account_id": "account_1", "character_id": "character_1", "revision": revision, "server_unix_ms": server_time,
		"economy": {"level": 7, "xp": 0, "credits": 80, "warp_chips": 0, "scrap": 0, "fuel": 100,
			"max_fuel": 100, "inventory_revision": 0, "inventory_count": 0, "active_hunt": {}, "pending_reward": {}},
	}


func make_build_snapshot(revision: int, server_time: int) -> Dictionary:
	var equipment := {}
	for slot in ["weapon", "helmet", "armor", "gloves", "boots", "rig", "implant", "gadget", "relic"]:
		equipment[slot] = {}
	return {
		"api_version": 1, "authority": "server", "shard_id": "international_1",
		"account_id": "account_1", "character_id": "character_1", "revision": revision, "server_unix_ms": server_time,
		"build": {"base_power": 10, "attributes": {"strength": 10, "vitality": 10, "dexterity": 10, "intelligence": 10, "cunning": 10},
			"stat_points": 0, "inventory_revision": 0, "equipment": equipment, "inventory": []},
	}
