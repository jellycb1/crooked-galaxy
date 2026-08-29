extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")
const CoreRulesScript = preload("res://scripts/core_rules.gd")
const MissionRulesScript = preload("res://scripts/mission_rules.gd")
const TransportRulesScript = preload("res://scripts/transport_rules.gd")

var failures := 0


func _init() -> void:
	var state := StateScript.new()
	state.persistence_enabled = false
	var player := state.default_player()
	state.free()
	var elapsed := 0.0
	var discovery := {1: {"wins": 0, "seconds": 0.0}}
	var known_worlds := MissionRulesScript.available_planets(int(player.level)).size()
	for _capture in 3400:
		var offers := MissionRulesScript.board_offers(player)
		check(offers.size() == 3, "standard progression always retains three generated offers")
		if offers.size() < 2:
			break
		var offer: Dictionary = offers[1]
		elapsed += TransportRulesScript.effective_mission_duration(player, offer)
		player.xp = int(player.xp) + int(offer.xp)
		player.wins = int(player.wins) + 1
		while int(player.xp) >= CoreRulesScript.xp_needed(int(player.level)):
			player.xp = int(player.xp) - CoreRulesScript.xp_needed(int(player.level))
			player.level = int(player.level) + 1
		var current_worlds := MissionRulesScript.available_planets(int(player.level)).size()
		if current_worlds > known_worlds:
			discovery[current_worlds] = {"wins": int(player.wins), "seconds": elapsed, "level": int(player.level)}
			known_worlds = current_worlds
		if known_worlds == ContentDB.PLANETS.size():
			break

	check(discovery.size() == ContentDB.PLANETS.size(), "a standard-contract career discovers every implemented world")
	check(in_range(discovery, 2, 5, 15, 4), "the second world enters after the tutorial but before the opening loop becomes repetitive")
	check(in_range(discovery, 3, 15, 40, 8), "the third world arrives within the intended early-career window")
	check(in_range(discovery, 4, 35, 75, 13), "the fourth world anchors the middle-career window")
	check(in_range(discovery, 5, 60, 115, 19), "the fifth world remains a meaningful long-career discovery")
	check(in_range(discovery, 6, 150, 190, 30), "the first year-one expansion arrives at its level-30 contract")
	check(in_range(discovery, 7, 240, 280, 40), "the abyssal expansion arrives at its level-40 contract")
	check(in_range(discovery, 8, 340, 380, 50), "the patented-jungle expansion arrives at its level-50 contract")
	check(in_range(discovery, 9, 450, 500, 60), "the volcanic expansion arrives at its level-60 contract")
	check(in_range(discovery, 10, 580, 650, 70), "the lunar-estate expansion arrives at its level-70 contract")
	check(in_range(discovery, 11, 720, 770, 80), "the umbral-necropolis expansion arrives at its level-80 contract")
	check(in_range(discovery, 12, 870, 920, 90), "the 24h-storm-center expansion arrives at its level-90 contract")
	check(in_range(discovery, 13, 1020, 1100, 100), "the obsolete-tomorrows expansion arrives at its level-100 contract")
	check(in_range(discovery, 14, 1190, 1280, 110), "the taxed-silence-library expansion arrives at its level-110 contract")
	check(in_range(discovery, 15, 1370, 1470, 120), "the event-horizon-resort expansion arrives at its level-120 contract")
	check(in_range(discovery, 16, 1570, 1680, 130), "the unauthorized-clone-court expansion arrives at its level-130 contract")
	check(in_range(discovery, 17, 1780, 1940, 140), "the reverse-gravity-monastery expansion arrives at its level-140 contract")
	check(in_range(discovery, 18, 2000, 2200, 150), "the used-memory-market expansion arrives at its level-150 contract")
	check(in_range(discovery, 19, 2250, 2500, 160), "the temporal-wreck-shipyard expansion arrives at its level-160 contract")
	check(in_range(discovery, 20, 2500, 2800, 170), "the fractional-moon-exchange expansion arrives at its level-170 contract")
	check(in_range(discovery, 21, 2750, 3100, 180), "the refurbished-sun-factory expansion arrives at its level-180 contract")
	check(float(discovery[2].seconds) < float(discovery[3].seconds) and float(discovery[3].seconds) < float(discovery[4].seconds) and float(discovery[4].seconds) < float(discovery[5].seconds), "cumulative mission time grows monotonically across world discoveries")
	check(seconds_in_range(discovery, 2, 1100.0, 1300.0), "Congelaria enters after roughly twenty minutes of standard base waits")
	check(seconds_in_range(discovery, 3, 5500.0, 5800.0), "Micelia enters after roughly ninety minutes of standard base waits")
	check(seconds_in_range(discovery, 4, 17000.0, 18200.0), "Ferro-Velho enters after roughly five hours of standard base waits")
	check(seconds_in_range(discovery, 5, 42500.0, 45000.0), "Cassino enters after roughly twelve hours of standard base waits")
	check(float(discovery[6].seconds) > float(discovery[5].seconds), "Aeropolis extends rather than replaces the established route ladder")
	check(float(discovery[7].seconds) > float(discovery[6].seconds), "Abyssal Archive extends the cumulative route ladder")
	check(float(discovery[8].seconds) > float(discovery[7].seconds), "Patent Verdantia extends the cumulative route ladder")
	check(float(discovery[9].seconds) > float(discovery[8].seconds), "Warranty Caldera extends the cumulative route ladder")
	check(float(discovery[10].seconds) > float(discovery[9].seconds), "Lunar Estate extends the cumulative route ladder")
	check(float(discovery[11].seconds) > float(discovery[10].seconds), "Umbral Solar Necropolis extends the cumulative route ladder")
	check(float(discovery[12].seconds) > float(discovery[11].seconds), "24h Storm Center extends the cumulative route ladder")
	check(float(discovery[13].seconds) > float(discovery[12].seconds), "Museum of Obsolete Tomorrows extends the cumulative route ladder")
	check(float(discovery[14].seconds) > float(discovery[13].seconds), "Taxed Silence Library extends the cumulative route ladder")
	check(float(discovery[15].seconds) > float(discovery[14].seconds), "Event Horizon Resort extends the cumulative route ladder")
	check(float(discovery[16].seconds) > float(discovery[15].seconds), "Unauthorized Clone Court extends the cumulative route ladder")
	check(float(discovery[17].seconds) > float(discovery[16].seconds), "Reverse Gravity Monastery extends the cumulative route ladder")
	check(float(discovery[18].seconds) > float(discovery[17].seconds), "Used Memory Market extends the cumulative route ladder")
	check(float(discovery[19].seconds) > float(discovery[18].seconds), "Temporal Wreck Shipyard extends the cumulative route ladder")
	check(float(discovery[20].seconds) > float(discovery[19].seconds), "Fractional Moon Exchange extends the cumulative route ladder")
	check(float(discovery[21].seconds) > float(discovery[20].seconds), "Refurbished Sun Factory extends the cumulative route ladder")

	finish()


func in_range(discovery: Dictionary, world_count: int, minimum_wins: int, maximum_wins: int, expected_level: int) -> bool:
	if not discovery.has(world_count):
		return false
	var record: Dictionary = discovery[world_count]
	return int(record.wins) >= minimum_wins and int(record.wins) <= maximum_wins and int(record.level) == expected_level


func seconds_in_range(discovery: Dictionary, world_count: int, minimum_seconds: float, maximum_seconds: float) -> bool:
	if not discovery.has(world_count):
		return false
	var seconds := float(discovery[world_count].seconds)
	return seconds >= minimum_seconds and seconds <= maximum_seconds


func finish() -> void:
	if failures == 0:
		print("PASS: mission wait and world discovery pacing remain bounded")
		quit(0)
	else:
		printerr("FAIL: %d mission pacing issue(s)" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)
