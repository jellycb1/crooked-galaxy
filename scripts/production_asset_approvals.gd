class_name ProductionAssetApprovals
extends RefCounted

# Exact source-file approvals enter here only after the mandatory visual intake,
# external-candidate preflight and integrated 450x800 review. The empty registry
# intentionally keeps every authored-content fallback active while art is made.
const APPROVED_FILES := {
}


static func expected_sha256(path: String) -> String:
	return str(APPROVED_FILES.get(path, ""))


static func is_approved(path: String) -> bool:
	return not expected_sha256(path).is_empty()
