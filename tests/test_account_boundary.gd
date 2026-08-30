extends SceneTree

const Accounts = preload("res://scripts/account_rules.gd")
const Service = preload("res://scripts/account_service.gd")
const Servers = preload("res://scripts/server_rules.gd")
const State = preload("res://scripts/game_state.gd")

var failures := 0


func _init() -> void:
	var service = Service.new()
	check(service.provider_id() == Accounts.LOCAL_PROVIDER_ID and not service.backend_available(), "replaceable account adapter reports the honest local provider and no backend")
	check(not Servers.agency_backend_available(Servers.DEFAULT_ID), "International 1 never advertises a social backend before one exists")
	check(not Servers.economy_backend_available(Servers.DEFAULT_ID), "International 1 never advertises remote progression before economy authority exists")
	var account := Accounts.create_local_account("en", "international_1")
	check(str(account.provider_id) == Accounts.LOCAL_PROVIDER_ID and str(account.authority) == "device", "local test account declares its real provider and progress authority")
	check(str(account.session_state) == Accounts.SESSION_LOCAL_READY and str(account.sync_state) == Accounts.SYNC_LOCAL_ONLY, "local session never impersonates authentication or synchronization")
	check(Accounts.owns_character(account, Accounts.LOCAL_CHARACTER_ID), "account owns exactly its active local character")
	check(int(Accounts.account_for_local_commit(account).local_revision) == 1 and int(account.local_revision) == 0, "local commits advance a copied revision without mutating uncommitted state")

	var legacy := Accounts.canonicalize_local_account({"mode": "legacy_local", "session_id": "legacy_primary", "locale_id": "pt", "server_id": "international_1"}, Accounts.LOCAL_CHARACTER_ID)
	check(Accounts.is_local_session_ready(legacy) and Accounts.owns_character(legacy, Accounts.LOCAL_CHARACTER_ID), "legacy sessions canonicalize into the same explicit local contract")
	var foreign := account.duplicate(true)
	foreign.active_character_id = "foreign_character"
	check(Accounts.canonicalize_local_account(foreign, Accounts.LOCAL_CHARACTER_ID).is_empty(), "loaded account cannot silently claim a foreign character")
	var fake_cloud := account.duplicate(true)
	fake_cloud.authority = "server"
	fake_cloud.sync_state = Accounts.SYNC_SYNCHRONIZED
	check(Accounts.canonicalize_local_account(fake_cloud, Accounts.LOCAL_CHARACTER_ID).is_empty(), "local APK rejects saves that pretend to have server authority")

	check(Accounts.progress_resolution("hunter", "hunter", 4, 9, 4, true, true) == Accounts.RESOLUTION_MANUAL_CONFLICT, "divergent remote progress with pending local work requires explicit conflict handling")
	check(Accounts.progress_resolution("hunter", "other", 4, 9, 4, false, true) == Accounts.RESOLUTION_REJECT_FOREIGN, "remote progress for another character is never merged")
	check(Accounts.progress_resolution("hunter", "hunter", 4, 9, 4, false, true) == Accounts.RESOLUTION_DOWNLOAD_REMOTE, "newer uncontested remote progress has an explicit download decision")
	check(Accounts.progress_resolution("hunter", "hunter", 9, 4, 4, true, true) == Accounts.RESOLUTION_UPLOAD_LOCAL, "newer local progress has an explicit future upload decision")
	check(Accounts.progress_resolution("hunter", "hunter", 4, 4, 4, false, true) == Accounts.RESOLUTION_SYNCHRONIZED, "equal revisions are synchronized")
	check(Accounts.progress_resolution("hunter", "hunter", 4, 9, 4, true, false) == Accounts.RESOLUTION_LOCAL_ONLY, "unavailable backend preserves device authority without a fake conflict")
	check(service.resolve_remote_snapshot("hunter", "hunter", 4, 9, 4, true) == Accounts.RESOLUTION_LOCAL_ONLY, "current adapter cannot manufacture a remote conflict while no backend exists")

	var save_path := "res://.godot/account_boundary_%s.json" % OS.get_process_id()
	var state = State.new()
	state.persistence_enabled = true
	state.save_path = save_path
	state.player = state.default_player()
	check(state.begin_local_session("en", "international_1"), "local login creates and commits the explicit account boundary")
	check(str(state.player.character_id) == Accounts.LOCAL_CHARACTER_ID and Accounts.owns_character(state.account, str(state.player.character_id)), "local login binds account ownership to the new character record")
	var first_revision := int(state.account.local_revision)
	check(first_revision == 1 and state.save_game() and int(state.account.local_revision) == first_revision + 1, "successful save advances the local profile revision exactly once")
	var restored = State.new()
	restored.persistence_enabled = true
	restored.save_path = save_path
	restored.load_game()
	check(restored.account_session_ready() and Accounts.owns_character(restored.account, str(restored.player.character_id)), "save/load preserves session, shard, and character ownership")
	check(str(restored.account.sync_state) == Accounts.SYNC_LOCAL_ONLY and int(restored.account.last_server_revision) == 0, "restored local profile remains honestly unsynchronized")
	state.free()
	restored.free()
	for path in [save_path, "%s.tmp" % save_path, "%s.bak" % save_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	if failures == 0:
		print("PASS: account, session, ownership, revision, and conflict boundary is explicit")
		quit(0)
	else:
		printerr("FAIL: %d account-boundary issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
