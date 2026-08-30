extends SceneTree

const Agency = preload("res://scripts/agency_rules.gd")
const RemoteAgency = preload("res://scripts/remote_agency_rules.gd")
const Dispatcher = preload("res://scripts/remote_agency_dispatcher.gd")

var failures := 0


class FakeAdapter extends RefCounted:
	var revision := 0
	var membership_state := "none"
	var pending_failures := 0
	var submissions: Array = []

	func account_id() -> String:
		return "account_1"

	func get_agency_membership() -> Dictionary:
		return make_membership(revision, membership_state)

	func apply_to_agency(command_id: String, key: String, expected: int, agency_id: String) -> Dictionary:
		return submit(command_id, key, "agency_apply", expected, agency_id, "application_pending")

	func leave_agency(command_id: String, key: String, expected: int, agency_id: String) -> Dictionary:
		return submit(command_id, key, "agency_leave", expected, agency_id, "none")

	func create_agency(command_id: String, key: String, expected: int, name: String, recruitment_mode: String, preferred_locale: String) -> Dictionary:
		submissions.append({"command_id": command_id, "key": key, "operation": "agency_create", "expected": expected,
			"name": name, "recruitment_mode": recruitment_mode, "preferred_locale": preferred_locale})
		if pending_failures > 0:
			pending_failures -= 1
			return {"ok": false, "error_code": "transport"}
		revision = expected + 1
		membership_state = "member"
		return {"ok": true, "api_version": 1, "authority": "server", "command_id": command_id, "idempotency_key": key,
			"operation": "agency_create", "shard_id": "international_1", "character_id": "account_1", "status": "accepted",
			"server_revision": revision, "server_unix_ms": 2000000000000, "reason_code": ""}

	func submit(command_id: String, key: String, operation: String, expected: int, agency_id: String, next_state: String) -> Dictionary:
		submissions.append({"command_id": command_id, "key": key, "operation": operation, "expected": expected, "agency_id": agency_id})
		if pending_failures > 0:
			pending_failures -= 1
			return {"ok": false, "error_code": "transport"}
		revision = expected + 1
		membership_state = next_state
		return {"ok": true, "api_version": 1, "authority": "server", "command_id": command_id, "idempotency_key": key,
			"operation": operation, "shard_id": "international_1", "character_id": "account_1", "status": "accepted",
			"server_revision": revision, "server_unix_ms": 2000000000000, "reason_code": ""}

	func make_membership(value: int, state: String) -> Dictionary:
		var agency_id := "agency_1" if state != "none" else ""
		var role_id := "director" if state == "member" else ""
		var agency := {}
		if state == "member":
			agency = {"authority": "server", "shard_id": "international_1", "agency_id": "agency_1", "name": "Nova Office", "revision": value,
				"members": [{"character_id": "account_1", "role_id": "director", "joined_revision": value}],
				"recruitment_mode": "application", "preferred_locale": "multi"}
		return {"api_version": 1, "authority": "server", "shard_id": "international_1", "account_id": "account_1",
			"character_id": "account_1", "revision": value, "server_unix_ms": 2000000000000,
			"membership_state": state, "agency_id": agency_id, "role_id": role_id, "agency": agency}


func _init() -> void:
	var directory_page := RemoteAgency.canonical_directory_page({"api_version": 1, "authority": "server", "shard_id": "international_1",
		"server_unix_ms": 2000000000000, "cursor": "", "next_cursor": "page_2", "agencies": [
			{"authority": "server", "shard_id": "international_1", "agency_id": "agency_1", "name": "Nova Office", "revision": 2,
				"member_count": 2, "recruitment_mode": "application", "preferred_locale": "multi"}]})
	check(not directory_page.is_empty() and directory_page.agencies.size() == 1 and str(directory_page.next_cursor) == "page_2",
		"Agency directory page is bounded and roster-free")
	var duplicate_page := directory_page.duplicate(true)
	duplicate_page.erase("ok")
	duplicate_page.agencies.append(duplicate_page.agencies[0].duplicate(true))
	check(RemoteAgency.canonical_directory_page(duplicate_page).is_empty(), "Agency directory rejects duplicate identities")
	var create_adapter = FakeAdapter.new()
	var create_dispatcher = Dispatcher.new(create_adapter, "account_1")
	check(bool((await create_dispatcher.bootstrap(0)).get("ok", false)), "Agency creation begins from canonical no-membership revision zero")
	var created: Dictionary = await create_dispatcher.dispatch_create("agency_create_1", "agency_create_idem_1", "Nova Office", "application", "multi")
	check(bool(created.get("ok", false)) and create_dispatcher.revision() == 1 and create_dispatcher.snapshot().membership_state == RemoteAgency.STATE_MEMBER \
		and create_dispatcher.snapshot().role_id == Agency.ROLE_DIRECTOR, "server-created Agency refetch binds its creator as the sole Director")
	check(bool(create_dispatcher.close().get("ok", false)), "created Agency runtime closes without entering offline state")
	var adapter = FakeAdapter.new()
	var dispatcher = Dispatcher.new(adapter, "account_1")
	check(bool((await dispatcher.bootstrap(0)).get("ok", false)) and dispatcher.snapshot().membership_state == RemoteAgency.STATE_NONE,
		"owned online character bootstraps an independent no-membership snapshot")
	var applied: Dictionary = await dispatcher.dispatch("agency_apply_1", "agency_idem_1", RemoteAgency.OP_APPLY, "agency_1")
	check(bool(applied.get("ok", false)) and dispatcher.revision() == 1 and dispatcher.snapshot().membership_state == RemoteAgency.STATE_APPLICATION_PENDING,
		"application intent advances only the social revision")
	adapter.pending_failures = 1
	var uncertain: Dictionary = await dispatcher.dispatch("agency_leave_1", "agency_idem_2", RemoteAgency.OP_LEAVE, "agency_1")
	check(not bool(uncertain.get("ok", false)) and dispatcher.safe_summary().pending, "unknown social outcome retains its exact identity")
	var retried: Dictionary = await dispatcher.retry_pending()
	check(bool(retried.get("ok", false)) and adapter.submissions[-1] == adapter.submissions[-2] and dispatcher.snapshot().membership_state == RemoteAgency.STATE_NONE,
		"social retry preserves command identity and refreshes server membership")
	check(bool(dispatcher.close().get("ok", false)) and dispatcher.snapshot().is_empty(), "social runtime zeroizes independently from economy cache")

	var forged := adapter.make_membership(2, "application_pending")
	forged.account_id = "foreign"
	check(RemoteAgency.canonical_membership_snapshot(forged, "account_1", "account_1").is_empty(), "foreign membership is rejected")
	var member := {"authority": "server", "shard_id": "international_1", "agency_id": "agency_1", "name": "Nova Office", "revision": 2,
		"members": [
			{"character_id": "director_1", "role_id": Agency.ROLE_DIRECTOR, "joined_revision": 0},
			{"character_id": "account_1", "role_id": Agency.ROLE_AGENT, "joined_revision": 2},
		], "recruitment_mode": "application", "preferred_locale": "multi"}
	var member_snapshot := adapter.make_membership(2, "member")
	member_snapshot.role_id = Agency.ROLE_AGENT
	member_snapshot.agency = member
	check(not RemoteAgency.canonical_membership_snapshot(member_snapshot, "account_1", "account_1").is_empty(), "member snapshot binds role to exactly one canonical roster entry")
	member_snapshot.role_id = Agency.ROLE_DIRECTOR
	check(RemoteAgency.canonical_membership_snapshot(member_snapshot, "account_1", "account_1").is_empty(), "forged role cannot diverge from the roster")

	if failures == 0:
		print("PASS: remote Agency membership has independent ownership, revision, retry, and zeroization boundaries")
		quit(0)
	else:
		printerr("FAIL: %d remote-Agency issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
