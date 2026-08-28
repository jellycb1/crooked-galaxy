extends SceneTree

const SaveMigrations = preload("res://scripts/save_migrations.gd")

var failures := 0


func _init() -> void:
	var version_one := {
		"version": 1,
		"player": {
			"credits": 77,
			"weapon": {"name": "Blaster antigo"},
			"armor": {"name": "Colete antigo"},
		},
	}
	var migrated := SaveMigrations.migrate(version_one)
	check(int(migrated.version) == SaveMigrations.CURRENT_VERSION, "version one reaches the current schema")
	check(int(migrated.player.credits) == 77, "existing player data survives the migration chain")
	check(migrated.player.claimed_milestones is Array, "version two career fields are initialized")
	check(migrated.player.locked_item_ids is Array, "version three protection fields are initialized")
	check(migrated.player.equipment_loadouts.size() == 2, "both loadout slots are initialized")
	check(str(migrated.player.weapon.id) == "migrated_weapon", "legacy weapons receive stable ids")
	check(str(migrated.player.armor.id) == "migrated_armor", "legacy armor receives stable ids")
	check(int(migrated.player.capture_streak) == 0 and int(migrated.player.best_capture_streak) == 0, "streak fields are initialized")
	check(not bool(migrated.player.reduced_motion), "motion preference defaults to full during migration")
	check(migrated.player.attributes.size() == 5 and int(migrated.player.attributes.cunning) == 10, "legacy saves receive all five neutral attributes")
	check(int(migrated.player.stat_points) == 0, "a level-one legacy hunter receives no unearned retroactive points")
	check(str(migrated.player.class_id).is_empty(), "legacy hunters remain unassigned so migration never chooses a build for them")
	check(int(migrated.player.market_cycle) == 0 and migrated.player.market_purchased_offer_ids.is_empty(), "legacy hunters receive a clean deterministic market cycle")
	check(migrated.player.owned_transport_ids.is_empty() and str(migrated.player.active_transport_id).is_empty(), "legacy hunters receive an empty hangar without losing credits")
	check(not version_one.player.has("claimed_milestones"), "migration does not mutate its source payload")

	var existing_ids := {
		"version": 2,
		"player": {
			"weapon": {"id": "kept_weapon"},
			"armor": {"id": "kept_armor"},
		},
	}
	var migrated_ids := SaveMigrations.migrate(existing_ids)
	check(str(migrated_ids.player.weapon.id) == "kept_weapon", "migration preserves existing weapon ids")
	check(str(migrated_ids.player.armor.id) == "kept_armor", "migration preserves existing armor ids")

	var established_v5 := {"version": 5, "player": {"level": 4, "credits": 91}}
	var established_v6 := SaveMigrations.migrate(established_v5)
	check(int(established_v6.player.stat_points) == 6, "established hunters receive two retroactive points for every completed level")
	check(int(established_v6.player.attributes.strength) == 10, "retroactive migration preserves neutral unspent attributes")
	check(str(established_v6.player.class_id).is_empty(), "version-six hunters receive the explicit unassigned class state")

	var established_v7 := {"version": 7, "player": {"credits": 91, "class_id": "orbit_gunslinger"}}
	var established_v8 := SaveMigrations.migrate(established_v7)
	check(int(established_v8.player.market_cycle) == 0 and established_v8.player.market_purchased_offer_ids.is_empty(), "version-eight migration initializes only market persistence")
	check(str(established_v8.player.class_id) == "orbit_gunslinger", "market migration preserves the selected prototype class")

	var established_v8_payload := {"version": 8, "player": {"credits": 91, "market_cycle": 2, "market_purchased_offer_ids": ["market_kept"]}}
	var established_v9 := SaveMigrations.migrate(established_v8_payload)
	check(established_v9.player.owned_transport_ids.is_empty() and str(established_v9.player.active_transport_id).is_empty(), "version-nine migration initializes only transport persistence")
	check(int(established_v9.player.market_cycle) == 2 and established_v9.player.market_purchased_offer_ids == ["market_kept"], "transport migration preserves established market records")
	check(["helmet", "gloves", "boots", "rig", "implant", "gadget", "relic"].all(func(slot): return established_v9.player.has(slot) and established_v9.player[slot].is_empty()), "version-ten migration reserves every universal equipment slot without inventing loot")
	check(int(established_v9.player.challenge_floor) == 0, "version-eleven migration adds an untouched challenge ladder")
	check(str(established_v9.player.species_id).is_empty() and str(established_v9.player.hunter_name).is_empty(), "version-twelve migration never invents species or hunter name")
	check(str(established_v9.account.mode) == "legacy_local", "an established local save resumes as a returning local session")
	check(str(established_v9.account.server_id) == "international_1" and str(established_v9.account.locale_id) == "pt", "established local saves join International 1 with their existing Portuguese presentation")
	check(str(established_v9.account.provider_id) == "local_device" and str(established_v9.account.authority) == "device" and str(established_v9.account.sync_state) == "local_only", "established saves gain an honest device-authoritative account boundary")
	check(str(established_v9.player.character_id) == "local_character_primary" and str(established_v9.account.active_character_id) == str(established_v9.player.character_id) and established_v9.account.owned_character_ids == [str(established_v9.player.character_id)], "migration binds the existing hunter to one stable locally owned character")

	var version_nine := {"version": 9, "player": {"weapon": {"id": "legacy_weapon"}, "armor": {"id": "legacy_armor"}, "equipment_loadouts": [{"weapon_id": "legacy_weapon", "armor_id": "legacy_armor"}, {"weapon_id": "", "armor_id": ""}]}}
	var universal := SaveMigrations.migrate(version_nine)
	check(str(universal.player.weapon.id) == "legacy_weapon" and str(universal.player.armor.id) == "legacy_armor", "universal inventory migration preserves both established equipped pieces")
	check(universal.player.equipment_loadouts.all(func(loadout): return ["weapon", "helmet", "armor", "gloves", "boots", "rig", "implant", "gadget", "relic"].all(func(slot): return loadout.has("%s_id" % slot))), "every migrated loadout receives the same nine-slot shape")

	var version_eleven := {"version": 11, "player": {"class_id": "contract_hacker", "credits": 123}}
	var identity_ready := SaveMigrations.migrate(version_eleven)
	check(str(identity_ready.player.class_id) == "contract_hacker" and str(identity_ready.player.species_id).is_empty() and str(identity_ready.player.hunter_name).is_empty(), "identity migration preserves class and resumes at the first missing character field")
	check(str(identity_ready.account.session_id) == "legacy_primary", "legacy migration creates only a returning-session bridge")
	check(str(identity_ready.account.server_id) == "international_1" and str(identity_ready.account.locale_id) == "pt", "identity migration adds explicit shard and locale account scope")

	var interrupted_v12 := SaveMigrations.migrate({"version": 12, "account": {}, "player": {"class_id": ""}})
	check(interrupted_v12.account.is_empty(), "an interrupted fresh login is not silently assigned to a server by migration")
	check(not interrupted_v12.player.has("character_id"), "an interrupted fresh login is not silently assigned character ownership")

	var legacy_identity := SaveMigrations.migrate({"version": 14, "player": {"species_id": "nebular_nomad", "hunter_name": "Nova"}})
	check(str(legacy_identity.player.species_id) == "starworn", "schema fifteen maps a colliding provisional species ID to its finalized identity")
	check(str(legacy_identity.player.appearance.palette) == "native" and str(legacy_identity.player.appearance.marking) == "clean", "established hunters receive a neutral complete cosmetic recipe")
	check(int(legacy_identity.player.warp_chips) == 0 and int(legacy_identity.player.market_refresh_count) == 0 and int(legacy_identity.player.economy_day) == -1, "schema sixteen initializes a neutral local premium wallet and daily counters")
	check(legacy_identity.player.discovered_item_variant_ids.is_empty(), "schema seventeen initializes the permanent equipment collection without inventing discoveries")
	check(legacy_identity.player.claimed_collection_milestones.is_empty(), "schema eighteen initializes collection rewards without claiming premium currency")
	check(int(legacy_identity.player.daily_hunts_completed) == 0 and legacy_identity.player.claimed_daily_objectives.is_empty(), "schema nineteen initializes daily activity without inventing completed objectives")
	check(legacy_identity.player.seen_planet_ids == ["dustball_prime"], "schema twenty treats destinations already available to a migrated level-one hunter as seen")
	var established_network := SaveMigrations.migrate({"version": 19, "player": {"level": 13}})
	check(established_network.player.seen_planet_ids == ["dustball_prime", "congelaria_sa", "micelia_404", "ferro_velho_omega"], "schema twenty does not mislabel established level-band content as a new discovery")
	var interrupted_identity := SaveMigrations.migrate({"version": 14, "player": {"species_id": "cellar_mycelian", "hunter_name": ""}})
	check(str(interrupted_identity.player.species_id) == "fungoid" and interrupted_identity.player.appearance.is_empty(), "interrupted creation resumes at customization after species migration")

	var current := {"version": SaveMigrations.CURRENT_VERSION, "player": {"credits": 5}}
	var current_copy := SaveMigrations.migrate(current)
	current_copy.player.credits = 9
	check(int(current.player.credits) == 5, "current-version payloads are returned as deep copies")
	check(SaveMigrations.migrate({"version": 0}).is_empty(), "unversioned saves are rejected")
	check(SaveMigrations.migrate({"version": SaveMigrations.CURRENT_VERSION + 1}).is_empty(), "future saves are rejected")
	var fuel_migration := SaveMigrations.migrate({"version": 20, "player": {"credits": 5}})
	check(int(fuel_migration.version) == 22 and int(fuel_migration.player.hunt_fuel) == 100 and int(fuel_migration.player.hunt_fuel_refill_count) == 0, "schema twenty receives a full neutral daily fuel reserve")
	var rift_migration := SaveMigrations.migrate({"version": 21, "player": {"level": 29, "challenge_floor": 6}})
	check(rift_migration.player.rift_reality_keys == ["dead_customs_key"], "schema twenty-two preserves the earned key for an established Rift hunter")
	check(int(rift_migration.player.rift_reality_progress.dead_customs) == 6 and int(rift_migration.player.rift_entry_day) == -1, "schema twenty-two maps legacy floors without inventing a consumed daily entry")

	if failures == 0:
		print("PASS: save migrations are deterministic and non-destructive")
		quit(0)
	else:
		printerr("FAIL: %d save migration test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
