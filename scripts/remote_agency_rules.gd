class_name RemoteAgencyRules
extends RefCounted

const Agency = preload("res://scripts/agency_rules.gd")

const API_VERSION := 1
const SHARD_ID := "international_1"
const STATE_NONE := "none"
const STATE_APPLICATION_PENDING := "application_pending"
const STATE_MEMBER := "member"
const STATES := [STATE_NONE, STATE_APPLICATION_PENDING, STATE_MEMBER]
const OP_APPLY := "agency_apply"
const OP_LEAVE := "agency_leave"
const OPERATIONS := [OP_APPLY, OP_LEAVE]


static func canonical_directory_page(response: Dictionary) -> Dictionary:
	if int(response.get("api_version", -1)) != API_VERSION or str(response.get("authority", "")) != "server" \
		or str(response.get("shard_id", "")) != SHARD_ID:
		return {}
	var server_unix_ms := int(response.get("server_unix_ms", -1))
	var cursor := str(response.get("cursor", ""))
	var next_cursor := str(response.get("next_cursor", ""))
	var loaded_agencies = response.get("agencies", null)
	if server_unix_ms < 1000000000000 or server_unix_ms > 4102444800000 or not loaded_agencies is Array \
		or loaded_agencies.size() > Agency.DIRECTORY_PAGE_LIMIT or (not cursor.is_empty() and not Agency.valid_identifier(cursor)) \
		or (not next_cursor.is_empty() and not Agency.valid_identifier(next_cursor)):
		return {}
	var agencies: Array[Dictionary] = []
	var agency_ids := {}
	for loaded in loaded_agencies:
		if not loaded is Dictionary:
			return {}
		var canonical := Agency.canonical_directory_summary(loaded)
		if canonical.is_empty() or agency_ids.has(str(canonical.agency_id)):
			return {}
		agency_ids[str(canonical.agency_id)] = true
		agencies.append(canonical)
	return {"api_version": API_VERSION, "authority": "server", "shard_id": SHARD_ID, "server_unix_ms": server_unix_ms,
		"cursor": cursor, "next_cursor": next_cursor, "agencies": agencies}


static func canonical_membership_snapshot(response: Dictionary, expected_account_id: String, expected_character_id: String) -> Dictionary:
	if int(response.get("api_version", -1)) != API_VERSION or str(response.get("authority", "")) != "server" \
		or str(response.get("shard_id", "")) != SHARD_ID or str(response.get("account_id", "")) != expected_account_id \
		or str(response.get("character_id", "")) != expected_character_id:
		return {}
	if not Agency.valid_identifier(expected_account_id) or not Agency.valid_identifier(expected_character_id):
		return {}
	var revision := int(response.get("revision", -1))
	var server_unix_ms := int(response.get("server_unix_ms", -1))
	var state := str(response.get("membership_state", ""))
	var agency_id := str(response.get("agency_id", ""))
	var role_id := str(response.get("role_id", ""))
	var agency_value = response.get("agency", null)
	if revision < 0 or server_unix_ms < 1000000000000 or server_unix_ms > 4102444800000 or state not in STATES or not agency_value is Dictionary:
		return {}
	var canonical_agency: Dictionary = {}
	match state:
		STATE_NONE:
			if not agency_id.is_empty() or not role_id.is_empty() or not agency_value.is_empty():
				return {}
		STATE_APPLICATION_PENDING:
			if not Agency.valid_identifier(agency_id) or not role_id.is_empty() or not agency_value.is_empty():
				return {}
		STATE_MEMBER:
			canonical_agency = Agency.canonical_agency_snapshot(agency_value)
			if canonical_agency.is_empty() or agency_id != str(canonical_agency.agency_id) or role_id not in Agency.ROLES or int(canonical_agency.revision) != revision:
				return {}
			var owned_members: Array = canonical_agency.members.filter(func(member): return str(member.character_id) == expected_character_id and str(member.role_id) == role_id)
			if owned_members.size() != 1:
				return {}
	return {
		"api_version": API_VERSION,
		"authority": "server",
		"shard_id": SHARD_ID,
		"account_id": expected_account_id,
		"character_id": expected_character_id,
		"revision": revision,
		"server_unix_ms": server_unix_ms,
		"membership_state": state,
		"agency_id": agency_id,
		"role_id": role_id,
		"agency": canonical_agency,
	}
