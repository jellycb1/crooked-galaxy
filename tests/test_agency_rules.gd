extends SceneTree

const Agency = preload("res://scripts/agency_rules.gd")

var failures := 0


func _init() -> void:
	var snapshot := agency_snapshot(4)
	var canonical := Agency.canonical_agency_snapshot(snapshot)
	check(not canonical.is_empty() and canonical.members.size() == 4, "a server-owned International 1 Agency snapshot is canonical")
	check(Agency.member_has_permission(canonical.members[0], Agency.PERMISSION_MANAGE_ROLES), "only the Director owns role administration")
	check(Agency.member_has_permission(canonical.members[1], Agency.PERMISSION_START_WARRANT) and not Agency.member_has_permission(canonical.members[2], Agency.PERMISSION_START_WARRANT), "Coordinators can operate warrants while ordinary Agents cannot")

	var local_fake := snapshot.duplicate(true)
	local_fake.authority = "device"
	check(Agency.canonical_agency_snapshot(local_fake).is_empty(), "device saves cannot manufacture an online Agency")
	var wrong_shard := snapshot.duplicate(true)
	wrong_shard.shard_id = "international_2"
	check(Agency.canonical_agency_snapshot(wrong_shard).is_empty(), "Agency membership cannot cross shard authority")
	var duplicate_member := snapshot.duplicate(true)
	duplicate_member.members[2].character_id = duplicate_member.members[1].character_id
	check(Agency.canonical_agency_snapshot(duplicate_member).is_empty(), "an Agency roster rejects duplicate characters")
	var second_director := snapshot.duplicate(true)
	second_director.members[1].role_id = Agency.ROLE_DIRECTOR
	check(Agency.canonical_agency_snapshot(second_director).is_empty(), "an Agency has exactly one Director")
	check(Agency.canonical_agency_snapshot(agency_snapshot(Agency.MEMBER_LIMIT + 1)).is_empty(), "Agency membership is bounded to twenty-five Agents")
	check(Agency.create_weekly_warrant(agency_snapshot(Agency.MIN_WARRANT_MEMBERS - 1), 42).is_empty(), "a weekly collective warrant requires four eligible Agents")
	var inactive_roster := agency_snapshot(6)
	inactive_roster.members[4].weekly_eligible = false
	inactive_roster.members[5].weekly_eligible = false
	check(Agency.create_weekly_warrant(inactive_roster, 42).eligible_member_ids.size() == 4, "inactive roster members do not inflate collective weekly goals")

	var warrant := Agency.create_weekly_warrant(snapshot, 42)
	check(str(warrant.warrant_id) == "agency_orion:42" and int(warrant.intel_goal) == 24 and int(warrant.capture_goal) == 120, "weekly goals scale from the snapshotted eligible roster")
	check(Agency.warrant_phase(warrant) == "investigation", "the Agency warrant opens as an investigation")
	var invalid_day := Agency.contribute_intel(warrant, "hunter_0", -1, "intel_invalid_day", int(warrant.revision))
	check(not bool(invalid_day.accepted) and str(invalid_day.reason) == "invalid_day", "only server-resolved UTC days can accept Agency activity")
	for index in 3:
		var intel := Agency.contribute_intel(warrant, "hunter_0", 100, "intel_%d" % index, int(warrant.revision))
		check(bool(intel.accepted) and int(intel.points) == 1, "each of the first three normal hunts contributes one Intel")
		warrant = intel.warrant
	var capped := Agency.contribute_intel(warrant, "hunter_0", 100, "intel_capped", int(warrant.revision))
	check(not bool(capped.accepted) and str(capped.reason) == "daily_limit", "premium activity cannot exceed the three-Intel daily limit")
	var duplicate := Agency.contribute_intel(warrant, "hunter_1", 100, "intel_0", int(warrant.revision))
	check(not bool(duplicate.accepted) and str(duplicate.reason) == "duplicate_event", "Agency contribution events are idempotent")
	var stale := Agency.contribute_intel(warrant, "hunter_1", 100, "intel_stale", int(warrant.revision) - 1)
	check(not bool(stale.accepted) and str(stale.reason) == "revision_conflict", "concurrent Agency writes require the expected server revision")

	while Agency.warrant_phase(warrant) == "investigation":
		var sequence := int(warrant.revision)
		var member_id := "hunter_%d" % (sequence % 4)
		var day := 101 + floori(float(sequence) / 12.0)
		var result := Agency.contribute_intel(warrant, member_id, day, "investigation_%d" % sequence, int(warrant.revision))
		check(bool(result.accepted), "eligible normal hunts can finish collective investigation")
		warrant = result.warrant
	check(Agency.warrant_phase(warrant) == "capture", "finishing Intel reveals the collective wanted target")

	var defeat := Agency.record_capture_attempt(warrant, "hunter_0", 110, "capture_defeat", int(warrant.revision), false, 0.0)
	check(bool(defeat.accepted) and int(defeat.points) == 3, "a genuine failed attempt still contributes bounded pursuit information")
	warrant = defeat.warrant
	var repeated_day := Agency.record_capture_attempt(warrant, "hunter_0", 110, "capture_repeat", int(warrant.revision), true, 1.0)
	check(not bool(repeated_day.accepted) and str(repeated_day.reason) == "daily_limit", "each Agent receives one collective capture attempt per UTC day")
	check(Agency.normalized_capture_points(true, 0.0) == 10 and Agency.normalized_capture_points(true, 1.0) == 15, "victory contribution is normalized instead of using raw high-level damage")
	check(Agency.encounter_level(8) == 8 and Agency.encounter_level(215) == 215 and Agency.encounter_level(999) == 320, "the collective enemy instance follows the Agent's bounded checkpoint")

	var capture_day := 111
	while Agency.warrant_phase(warrant) == "capture":
		var sequence := int(warrant.revision)
		var member_id := "hunter_%d" % (sequence % 4)
		var result := Agency.record_capture_attempt(warrant, member_id, capture_day, "capture_%d" % sequence, int(warrant.revision), true, 0.6)
		if not bool(result.accepted):
			capture_day += 1
			continue
		warrant = result.warrant
	check(Agency.warrant_phase(warrant) == "complete", "normalized Agent attempts complete one shared weekly capture")
	check(Agency.member_reward_eligible(warrant, "hunter_0") and not Agency.member_reward_eligible(warrant, "outsider"), "completion rewards require snapshotted membership and real participation")
	for roster_size in [4, 10, 25]:
		var active_count := ceili(float(roster_size) * 0.75)
		check(simulated_completion_day(roster_size, active_count) <= 7, "a seventy-five-percent active roster of %d can complete within one UTC week" % roster_size)

	if failures == 0:
		print("PASS: server-authoritative Bounty Agencies are bounded, fair, and idempotent")
		quit(0)
	else:
		printerr("FAIL: %d Agency contract issue(s)" % failures)
		quit(1)


func agency_snapshot(member_count: int) -> Dictionary:
	var members: Array[Dictionary] = []
	for index in member_count:
		members.append({
			"character_id": "hunter_%d" % index,
			"role_id": Agency.ROLE_DIRECTOR if index == 0 else (Agency.ROLE_COORDINATOR if index == 1 else Agency.ROLE_AGENT),
			"joined_revision": index,
			"weekly_eligible": true,
		})
	return {
		"authority": "server",
		"shard_id": Agency.SHARD_ID,
		"agency_id": "agency_orion",
		"name": "Orion Recovery Office",
		"revision": member_count + 5,
		"members": members,
		"recruitment_mode": "application",
		"preferred_locale": "en",
	}


func simulated_completion_day(roster_size: int, active_count: int) -> int:
	var warrant := Agency.create_weekly_warrant(agency_snapshot(roster_size), 80 + roster_size)
	for day_offset in 7:
		var utc_day := 1000 + day_offset
		for member_index in active_count:
			for hunt_index in Agency.DAILY_INTEL_LIMIT:
				if Agency.warrant_phase(warrant) != "investigation":
					break
				var intel := Agency.contribute_intel(warrant, "hunter_%d" % member_index, utc_day, "sim_i_%d_%d_%d" % [day_offset, member_index, hunt_index], int(warrant.revision))
				if bool(intel.accepted):
					warrant = intel.warrant
		if Agency.warrant_phase(warrant) == "capture":
			for member_index in active_count:
				var capture := Agency.record_capture_attempt(warrant, "hunter_%d" % member_index, utc_day, "sim_c_%d_%d" % [day_offset, member_index], int(warrant.revision), true, 0.6)
				if bool(capture.accepted):
					warrant = capture.warrant
				if Agency.warrant_phase(warrant) == "complete":
					return day_offset + 1
	return 999


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
