class_name AgencyRules
extends RefCounted

const SHARD_ID := "international_1"
const MEMBER_LIMIT := 25
const MIN_WARRANT_MEMBERS := 4
const MIN_CHARACTER_LEVEL := 8
const DAILY_INTEL_LIMIT := 3
const DAILY_CAPTURE_ATTEMPT_LIMIT := 1
const MAX_WEEKLY_EVENT_IDS := 1024

const ROLE_DIRECTOR := "director"
const ROLE_COORDINATOR := "coordinator"
const ROLE_AGENT := "agent"
const ROLE_RECRUIT := "recruit"
const ROLES := [ROLE_DIRECTOR, ROLE_COORDINATOR, ROLE_AGENT, ROLE_RECRUIT]

const PERMISSION_MANAGE_PROFILE := "manage_profile"
const PERMISSION_MANAGE_APPLICATIONS := "manage_applications"
const PERMISSION_MANAGE_MEMBERS := "manage_members"
const PERMISSION_MANAGE_ROLES := "manage_roles"
const PERMISSION_START_WARRANT := "start_warrant"


static func role_permissions(role_id: String) -> Array[String]:
	match role_id:
		ROLE_DIRECTOR:
			return [PERMISSION_MANAGE_PROFILE, PERMISSION_MANAGE_APPLICATIONS, PERMISSION_MANAGE_MEMBERS, PERMISSION_MANAGE_ROLES, PERMISSION_START_WARRANT]
		ROLE_COORDINATOR:
			return [PERMISSION_MANAGE_PROFILE, PERMISSION_MANAGE_APPLICATIONS, PERMISSION_MANAGE_MEMBERS, PERMISSION_START_WARRANT]
		ROLE_AGENT, ROLE_RECRUIT:
			return []
	return []


static func member_has_permission(member: Dictionary, permission_id: String) -> bool:
	return role_permissions(str(member.get("role_id", ""))).has(permission_id)


static func canonical_agency_snapshot(snapshot: Dictionary) -> Dictionary:
	if str(snapshot.get("authority", "")) != "server" or str(snapshot.get("shard_id", "")) != SHARD_ID:
		return {}
	var agency_id := str(snapshot.get("agency_id", ""))
	var name := str(snapshot.get("name", "")).strip_edges()
	var revision := int(snapshot.get("revision", -1))
	var loaded_members = snapshot.get("members", [])
	if not valid_identifier(agency_id) or not valid_display_name(name) or revision < 0:
		return {}
	if not loaded_members is Array or loaded_members.is_empty() or loaded_members.size() > MEMBER_LIMIT:
		return {}
	var members: Array[Dictionary] = []
	var character_ids := {}
	var director_count := 0
	for loaded_member in loaded_members:
		if not loaded_member is Dictionary:
			return {}
		var character_id := str(loaded_member.get("character_id", ""))
		var role_id := str(loaded_member.get("role_id", ""))
		var joined_revision := int(loaded_member.get("joined_revision", -1))
		if not valid_identifier(character_id) or character_ids.has(character_id) or not ROLES.has(role_id) or joined_revision < 0 or joined_revision > revision:
			return {}
		character_ids[character_id] = true
		director_count += 1 if role_id == ROLE_DIRECTOR else 0
		members.append({
			"character_id": character_id,
			"role_id": role_id,
			"joined_revision": joined_revision,
			"weekly_eligible": bool(loaded_member.get("weekly_eligible", true)),
		})
	if director_count != 1:
		return {}
	return {
		"authority": "server",
		"shard_id": SHARD_ID,
		"agency_id": agency_id,
		"name": name,
		"revision": revision,
		"members": members,
		"recruitment_mode": canonical_recruitment_mode(str(snapshot.get("recruitment_mode", "application"))),
		"preferred_locale": canonical_preferred_locale(str(snapshot.get("preferred_locale", "multi"))),
	}


static func create_weekly_warrant(agency_snapshot: Dictionary, week_id: int) -> Dictionary:
	var agency := canonical_agency_snapshot(agency_snapshot)
	if agency.is_empty() or week_id < 0:
		return {}
	var eligible_member_ids: Array[String] = []
	for member in agency.members:
		if bool(member.get("weekly_eligible", true)):
			eligible_member_ids.append(str(member.character_id))
	if eligible_member_ids.size() < MIN_WARRANT_MEMBERS:
		return {}
	return {
		"authority": "server",
		"shard_id": SHARD_ID,
		"agency_id": str(agency.agency_id),
		"warrant_id": "%s:%d" % [str(agency.agency_id), week_id],
		"week_id": week_id,
		"revision": 0,
		"eligible_member_ids": eligible_member_ids,
		"intel_goal": intelligence_goal(eligible_member_ids.size()),
		"intel_total": 0,
		"intel_by_member": {},
		"intel_daily_counts": {},
		"capture_goal": capture_goal(eligible_member_ids.size()),
		"capture_total": 0,
		"capture_points_by_member": {},
		"capture_attempts_by_member": {},
		"capture_daily_counts": {},
		"processed_event_ids": [],
	}


static func intelligence_goal(member_count: int) -> int:
	return maxi(18, clampi(member_count, 1, MEMBER_LIMIT) * 6)


static func capture_goal(member_count: int) -> int:
	return maxi(60, clampi(member_count, 1, MEMBER_LIMIT) * 30)


static func warrant_phase(warrant: Dictionary) -> String:
	if int(warrant.get("capture_total", 0)) >= int(warrant.get("capture_goal", 1)):
		return "complete"
	if int(warrant.get("intel_total", 0)) >= int(warrant.get("intel_goal", 1)):
		return "capture"
	return "investigation"


static func contribute_intel(warrant: Dictionary, character_id: String, utc_day_id: int, event_id: String, expected_revision: int) -> Dictionary:
	var copy := warrant.duplicate(true)
	if utc_day_id < 0:
		return transaction_result(false, copy, "invalid_day", 0)
	var rejection := transaction_rejection(copy, character_id, event_id, expected_revision)
	if not rejection.is_empty():
		return transaction_result(false, copy, rejection, 0)
	if warrant_phase(copy) != "investigation":
		return transaction_result(false, copy, "wrong_phase", 0)
	var daily_key := "%s:%d" % [character_id, utc_day_id]
	var daily_counts: Dictionary = copy.get("intel_daily_counts", {}).duplicate(true)
	var daily_count := int(daily_counts.get(daily_key, 0))
	if daily_count >= DAILY_INTEL_LIMIT:
		return transaction_result(false, copy, "daily_limit", 0)
	daily_counts[daily_key] = daily_count + 1
	copy.intel_daily_counts = daily_counts
	var by_member: Dictionary = copy.get("intel_by_member", {}).duplicate(true)
	by_member[character_id] = int(by_member.get(character_id, 0)) + 1
	copy.intel_by_member = by_member
	copy.intel_total = mini(int(copy.intel_goal), int(copy.get("intel_total", 0)) + 1)
	commit_event(copy, event_id)
	return transaction_result(true, copy, "", 1)


static func record_capture_attempt(warrant: Dictionary, character_id: String, utc_day_id: int, event_id: String, expected_revision: int, won: bool, performance_ratio: float) -> Dictionary:
	var copy := warrant.duplicate(true)
	if utc_day_id < 0:
		return transaction_result(false, copy, "invalid_day", 0)
	var rejection := transaction_rejection(copy, character_id, event_id, expected_revision)
	if not rejection.is_empty():
		return transaction_result(false, copy, rejection, 0)
	if warrant_phase(copy) != "capture":
		return transaction_result(false, copy, "wrong_phase", 0)
	var daily_key := "%s:%d" % [character_id, utc_day_id]
	var daily_counts: Dictionary = copy.get("capture_daily_counts", {}).duplicate(true)
	if int(daily_counts.get(daily_key, 0)) >= DAILY_CAPTURE_ATTEMPT_LIMIT:
		return transaction_result(false, copy, "daily_limit", 0)
	daily_counts[daily_key] = 1
	copy.capture_daily_counts = daily_counts
	var attempts: Dictionary = copy.get("capture_attempts_by_member", {}).duplicate(true)
	attempts[character_id] = int(attempts.get(character_id, 0)) + 1
	copy.capture_attempts_by_member = attempts
	var points := normalized_capture_points(won, performance_ratio)
	var by_member: Dictionary = copy.get("capture_points_by_member", {}).duplicate(true)
	by_member[character_id] = int(by_member.get(character_id, 0)) + points
	copy.capture_points_by_member = by_member
	copy.capture_total = mini(int(copy.capture_goal), int(copy.get("capture_total", 0)) + points)
	commit_event(copy, event_id)
	return transaction_result(true, copy, "", points)


static func normalized_capture_points(won: bool, performance_ratio: float) -> int:
	if not won:
		return 3
	return 10 + roundi(clampf(performance_ratio, 0.0, 1.0) * 5.0)


static func encounter_level(character_level: int) -> int:
	return clampi(character_level, MIN_CHARACTER_LEVEL, 320)


static func member_reward_eligible(warrant: Dictionary, character_id: String) -> bool:
	if warrant_phase(warrant) != "complete" or not warrant.get("eligible_member_ids", []).has(character_id):
		return false
	return int(warrant.get("intel_by_member", {}).get(character_id, 0)) >= DAILY_INTEL_LIMIT \
		or int(warrant.get("capture_attempts_by_member", {}).get(character_id, 0)) >= 1


static func transaction_rejection(warrant: Dictionary, character_id: String, event_id: String, expected_revision: int) -> String:
	if str(warrant.get("authority", "")) != "server" or str(warrant.get("shard_id", "")) != SHARD_ID:
		return "server_authority_required"
	if int(warrant.get("revision", -1)) != expected_revision:
		return "revision_conflict"
	if not warrant.get("eligible_member_ids", []).has(character_id):
		return "member_not_eligible"
	if not valid_identifier(event_id):
		return "invalid_event_id"
	var processed: Array = warrant.get("processed_event_ids", [])
	if processed.has(event_id):
		return "duplicate_event"
	if processed.size() >= MAX_WEEKLY_EVENT_IDS:
		return "event_capacity"
	return ""


static func commit_event(warrant: Dictionary, event_id: String) -> void:
	var processed: Array = warrant.get("processed_event_ids", []).duplicate()
	processed.append(event_id)
	warrant.processed_event_ids = processed
	warrant.revision = int(warrant.get("revision", 0)) + 1


static func transaction_result(accepted: bool, warrant: Dictionary, reason: String, points: int) -> Dictionary:
	return {"accepted": accepted, "warrant": warrant, "reason": reason, "points": points}


static func canonical_recruitment_mode(mode: String) -> String:
	return mode if mode in ["open", "application", "invite"] else "application"


static func canonical_preferred_locale(locale_id: String) -> String:
	return locale_id if locale_id in ["pt", "en", "multi"] else "multi"


static func valid_identifier(value: String) -> bool:
	if value.is_empty() or value.length() > 64:
		return false
	for character in value:
		if not character.to_lower() in "abcdefghijklmnopqrstuvwxyz0123456789_-:":
			return false
	return true


static func valid_display_name(value: String) -> bool:
	return value.length() >= 3 and value.length() <= 30 and not value.contains("\n") and not value.contains("\r") and not value.contains("\t")
