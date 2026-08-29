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
		"profile": {"character_id": "character_1", "hunter_name": "Nova", "level": 7, "credits": 80},
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
	check(offer == Sync.MIGRATION_CHOICE_REQUIRED, "established local progress versus pristine remote requires one explicit choice")
	check(Sync.canonical_migration_choice(Sync.MIGRATION_REQUEST_IMPORT, offer) == Sync.MIGRATION_REQUEST_IMPORT, "explicit local import request is preserved")
	check(Sync.canonical_migration_choice(Sync.MIGRATION_KEEP_REMOTE, offer) == Sync.MIGRATION_KEEP_REMOTE, "explicit remote reset choice is preserved")
	check(Sync.canonical_migration_choice("merge", offer) == Sync.MIGRATION_NONE, "field merge is not a migration option")
	check(Sync.migration_offer(local, pristine_remote, true) == Sync.MIGRATION_NONE, "recorded migration decision cannot be offered twice")
	var progressed_remote := pristine_remote.duplicate(true)
	progressed_remote.revision = 1
	check(Sync.migration_offer(local, progressed_remote, false) == Sync.MIGRATION_NONE, "local import is never offered over progressed remote state")

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
