class_name ServerRules
extends RefCounted

const DEFAULT_ID := "international_1"
const DEFINITIONS := [
	{
		"id": DEFAULT_ID,
		"name": "International 1",
		"short_name": "INT-1",
		"region": "GLOBAL",
		"language_policy": "MULTILÍNGUE",
		"prototype": true,
		"service_mode": "local_contract",
		"backend_provider": "nakama",
		"backend_environment": "offline",
		"account_backend": false,
		"clock_backend": false,
		"profile_backend": false,
		"agency_backend": false,
		"progress_authority": "device",
	},
]


static func is_valid(server_id: String) -> bool:
	return not get_definition(server_id).is_empty()


static func get_definition(server_id: String) -> Dictionary:
	for definition in DEFINITIONS:
		if str(definition.id) == server_id:
			return definition.duplicate(true)
	return {}


static func server_name_for(server_id: String) -> String:
	return str(get_definition(server_id).get("name", "SEM SERVIDOR"))


static func short_name_for(server_id: String) -> String:
	return str(get_definition(server_id).get("short_name", "LOCAL"))


static func agency_backend_available(server_id: String) -> bool:
	return bool(get_definition(server_id).get("agency_backend", false))


static func account_backend_available(server_id: String) -> bool:
	return bool(get_definition(server_id).get("account_backend", false))


static func clock_backend_available(server_id: String) -> bool:
	return bool(get_definition(server_id).get("clock_backend", false))


static func profile_backend_available(server_id: String) -> bool:
	return bool(get_definition(server_id).get("profile_backend", false))
