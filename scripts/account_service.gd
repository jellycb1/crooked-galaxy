class_name AccountService
extends RefCounted

const Rules = preload("res://scripts/account_rules.gd")


func provider_id() -> String:
	return Rules.LOCAL_PROVIDER_ID


func backend_available() -> bool:
	return false


func create_session(locale_id: String, server_id: String, character_id: String) -> Dictionary:
	return Rules.create_local_account(locale_id, server_id, character_id)


func session_ready(account: Dictionary) -> bool:
	return Rules.is_local_session_ready(account)


func canonicalize_account(account: Dictionary, character_id: String) -> Dictionary:
	return Rules.canonicalize_local_account(account, character_id)


func owns_character(account: Dictionary, character_id: String) -> bool:
	return Rules.owns_character(account, character_id)


func prepare_local_commit(account: Dictionary) -> Dictionary:
	return Rules.account_for_local_commit(account)


func resolve_remote_snapshot(character_id: String, remote_character_id: String, local_revision: int, remote_revision: int, last_server_revision: int, has_pending_local_changes: bool) -> String:
	return Rules.progress_resolution(character_id, remote_character_id, local_revision, remote_revision, last_server_revision, has_pending_local_changes, backend_available())
