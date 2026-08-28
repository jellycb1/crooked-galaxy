extends Control

const AUTHORED_TARGET_IDS := [
	"gloop", "baron_boom", "madame_vacuum", "mayor_gold_dust",
	"auditor_frost", "chef_coldflame", "executive_penguin", "director_kelvin",
	"landlord_spore", "countess_truffle", "captain_chlorophyll", "mother_mycelia",
	"bolt_collector", "doctor_patchwork", "crane_king", "omega_junkyard",
	"dealer_comet", "duchess_jackpot", "misfortune_auditor", "house_eternal",
	"courier_cumulus", "duchess_low_pressure", "engineer_thunder", "storm_bank",
	"eel_courier", "coral_landlady", "notary_octopus", "protocol_leviathan",
]

var character_id := "hunter"
var equipment_profile: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var side := minf(size.x, size.y)
	var origin := (size - Vector2(side, side)) * 0.5
	draw_set_transform(origin, 0.0, Vector2(side, side))
	match visual_identity_id():
		"gloop":
			draw_gloop()
		"baron_boom":
			draw_baron()
		"madame_vacuum":
			draw_madame()
		"mayor_gold_dust":
			draw_mayor()
		"auditor_frost":
			draw_auditor()
		"chef_coldflame":
			draw_chef()
		"executive_penguin":
			draw_penguin()
		"director_kelvin":
			draw_director()
		"landlord_spore":
			draw_landlord_spore()
		"countess_truffle":
			draw_countess_truffle()
		"captain_chlorophyll":
			draw_captain_chlorophyll()
		"mother_mycelia":
			draw_mother_mycelia()
		"bolt_collector":
			draw_bolt_collector()
		"doctor_patchwork":
			draw_doctor_patchwork()
		"crane_king":
			draw_crane_king()
		"omega_junkyard":
			draw_omega_junkyard()
		"dealer_comet":
			draw_casino_target(0)
		"duchess_jackpot":
			draw_casino_target(1)
		"misfortune_auditor":
			draw_casino_target(2)
		"house_eternal":
			draw_casino_target(3)
		"courier_cumulus":
			draw_aerial_target(0)
		"duchess_low_pressure":
			draw_aerial_target(1)
		"engineer_thunder":
			draw_aerial_target(2)
		"storm_bank":
			draw_aerial_target(3)
		"eel_courier":
			draw_abyssal_target(0)
		"coral_landlady":
			draw_abyssal_target(1)
		"notary_octopus":
			draw_abyssal_target(2)
		"protocol_leviathan":
			draw_abyssal_target(3)
		_:
			draw_hunter()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func visual_identity_id() -> String:
	if character_id == "hunter":
		return "hunter"
	return character_id if AUTHORED_TARGET_IDS.has(character_id) else "fallback"


func draw_aerial_target(variant: int) -> void:
	var ink := Color("#071426")
	var sky := Color("#8fd3ff")
	var cloud := Color("#dff5ff")
	var gold := Color("#ffe66d")
	draw_frame(Color("#173b55"), gold if variant == 3 else sky)
	# A shared floating coat and cloud collar make the chapter coherent at archive size.
	filled_polygon([Vector2(0.10, 0.96), Vector2(0.20, 0.70), Vector2(0.36, 0.64), Vector2(0.64, 0.64), Vector2(0.80, 0.70), Vector2(0.90, 0.96)], Color("#315b80"), ink)
	for x in [0.25, 0.38, 0.52, 0.66, 0.78]:
		draw_circle(Vector2(x, 0.72 + absf(x - 0.51) * 0.18), 0.085, cloud)
	if variant == 0:
		# Courier: parcel-shaped head, winged cap and a stamped delivery slot.
		filled_polygon([Vector2(0.25, 0.31), Vector2(0.73, 0.28), Vector2(0.78, 0.62), Vector2(0.29, 0.66)], Color("#c48a55"), ink)
		filled_polygon([Vector2(0.22, 0.30), Vector2(0.49, 0.16), Vector2(0.79, 0.28), Vector2(0.70, 0.37), Vector2(0.29, 0.39)], sky, ink)
		draw_line(Vector2(0.34, 0.46), Vector2(0.67, 0.44), ink, 0.035, true)
		draw_circle(Vector2(0.61, 0.53), 0.055, gold)
		draw_line(Vector2(0.34, 0.58), Vector2(0.54, 0.57), ink, 0.028, true)
	elif variant == 1:
		# Duchess: a sharp wind-mask, pressure crown and spiral monocle.
		outlined_ellipse(Vector2(0.50, 0.49), Vector2(0.29, 0.33), Color("#79b8da"), ink, 0.034)
		filled_polygon([Vector2(0.25, 0.30), Vector2(0.32, 0.11), Vector2(0.45, 0.24), Vector2(0.53, 0.07), Vector2(0.63, 0.24), Vector2(0.75, 0.12), Vector2(0.77, 0.31)], gold, ink)
		for eye in [Vector2(0.39, 0.46), Vector2(0.61, 0.44)]:
			outlined_circle(eye, 0.065, cloud, ink, 0.021)
		draw_arc(Vector2(0.61, 0.44), 0.105, 0.0, TAU, 24, gold, 0.022, true)
		draw_arc(Vector2(0.49, 0.60), 0.15, 0.08, PI - 0.08, 20, ink, 0.028, true)
	elif variant == 2:
		# Engineer: insulated turbine head and a lightning conductor.
		outlined_circle(Vector2(0.50, 0.49), 0.31, Color("#657487"), ink, 0.035)
		for tooth in 8:
			var direction := Vector2.RIGHT.rotated(TAU * float(tooth) / 8.0)
			draw_line(Vector2(0.50, 0.49) + direction * 0.29, Vector2(0.50, 0.49) + direction * 0.38, sky, 0.055, true)
		for eye in [Vector2(0.39, 0.47), Vector2(0.61, 0.47)]:
			outlined_circle(eye, 0.075, Color("#23374c"), gold, 0.022)
			draw_circle(eye, 0.025, cloud)
		var bolt := PackedVector2Array([Vector2(0.62, 0.27), Vector2(0.73, 0.08), Vector2(0.70, 0.22), Vector2(0.82, 0.15)])
		draw_polyline(bolt, gold, 0.04, true)
		draw_line(Vector2(0.38, 0.63), Vector2(0.63, 0.62), ink, 0.035, true)
	else:
		# Boss: a sentient bank tower suspended inside a storm front.
		filled_polygon([Vector2(0.22, 0.69), Vector2(0.28, 0.28), Vector2(0.72, 0.28), Vector2(0.78, 0.69)], Color("#334b66"), ink)
		filled_polygon([Vector2(0.20, 0.29), Vector2(0.50, 0.09), Vector2(0.80, 0.29)], gold, ink)
		for x in [0.34, 0.50, 0.66]:
			draw_line(Vector2(x, 0.34), Vector2(x, 0.65), cloud, 0.045, true)
		for eye in [Vector2(0.40, 0.44), Vector2(0.60, 0.44)]:
			draw_circle(eye, 0.045, sky)
		draw_line(Vector2(0.39, 0.59), Vector2(0.62, 0.59), gold, 0.035, true)


func draw_abyssal_target(variant: int) -> void:
	var ink := Color("#03131d")
	var teal := Color("#39d7c5")
	var foam := Color("#d8ffff")
	var coral := Color("#ff8b72")
	draw_frame(Color("#07343d"), coral if variant == 1 else teal)
	for bubble in [Vector2(0.20, 0.22), Vector2(0.78, 0.18), Vector2(0.84, 0.52), Vector2(0.17, 0.62)]:
		draw_arc(bubble, 0.035, 0.0, TAU, 16, Color(foam, 0.72), 0.012, true)
	if variant == 0:
		# Courier: a long eel silhouette wrapped around a pneumatic dispatch tube.
		draw_arc(Vector2(0.50, 0.53), 0.31, -2.7, 1.65, 42, ink, 0.14, true)
		draw_arc(Vector2(0.50, 0.53), 0.31, -2.7, 1.65, 42, teal, 0.09, true)
		outlined_ellipse(Vector2(0.55, 0.40), Vector2(0.24, 0.18), teal, ink, 0.030)
		for eye in [Vector2(0.48, 0.38), Vector2(0.63, 0.36)]:
			outlined_circle(eye, 0.052, foam, ink, 0.018)
		draw_line(Vector2(0.45, 0.55), Vector2(0.68, 0.52), ink, 0.026, true)
		var spark := PackedVector2Array([Vector2(0.28, 0.67), Vector2(0.40, 0.61), Vector2(0.37, 0.75), Vector2(0.52, 0.68)])
		draw_polyline(spark, Color("#ffe66d"), 0.032, true)
	elif variant == 1:
		# Landlady: coral crown, shell collar and pearl-ledger eyes.
		outlined_ellipse(Vector2(0.50, 0.50), Vector2(0.30, 0.32), Color("#9b5d63"), ink, 0.034)
		for branch_x in [0.29, 0.40, 0.52, 0.64, 0.74]:
			draw_line(Vector2(branch_x, 0.29), Vector2(branch_x + (branch_x - 0.50) * 0.18, 0.10 + absf(branch_x - 0.50) * 0.22), coral, 0.045, true)
		for eye in [Vector2(0.39, 0.47), Vector2(0.61, 0.47)]:
			outlined_circle(eye, 0.065, foam, ink, 0.020)
			draw_circle(eye, 0.024, Color("#6f4ca8"))
		draw_arc(Vector2(0.50, 0.61), 0.15, 0.10, PI - 0.10, 20, ink, 0.028, true)
		for x in [0.30, 0.40, 0.50, 0.60, 0.70]:
			outlined_circle(Vector2(x, 0.76), 0.045, foam, ink, 0.015)
	elif variant == 2:
		# Notary: octopus head, eight filing arms and a central legal stamp.
		for arm in 8:
			var angle := PI * (0.10 + 0.80 * float(arm) / 7.0)
			var root_point := Vector2(0.50, 0.66)
			var end_point := Vector2(0.50 + cos(angle) * 0.43, 0.65 + sin(angle) * 0.30)
			draw_line(root_point, end_point, ink, 0.075, true)
			draw_line(root_point, end_point, Color("#6f73a8"), 0.043, true)
		outlined_ellipse(Vector2(0.50, 0.45), Vector2(0.29, 0.31), Color("#777bb8"), ink, 0.034)
		for eye in [Vector2(0.39, 0.44), Vector2(0.61, 0.44)]:
			outlined_circle(eye, 0.065, foam, ink, 0.020)
		draw_circle(Vector2(0.50, 0.61), 0.075, coral)
		draw_line(Vector2(0.45, 0.61), Vector2(0.55, 0.61), ink, 0.022, true)
	else:
		# Boss: a huge archival maw with filing tabs instead of dorsal fins.
		outlined_ellipse(Vector2(0.50, 0.51), Vector2(0.40, 0.35), Color("#164d55"), ink, 0.040)
		for tab in 5:
			var x := 0.24 + float(tab) * 0.13
			filled_polygon([Vector2(x, 0.24), Vector2(x + 0.05, 0.08), Vector2(x + 0.11, 0.25)], teal if tab % 2 == 0 else coral, ink)
		for eye in [Vector2(0.34, 0.42), Vector2(0.66, 0.42)]:
			outlined_circle(eye, 0.075, foam, ink, 0.022)
			draw_circle(eye, 0.030, coral)
		filled_polygon([Vector2(0.24, 0.57), Vector2(0.76, 0.57), Vector2(0.67, 0.78), Vector2(0.33, 0.78)], ink, teal)
		for tooth in 6:
			var x := 0.31 + float(tooth) * 0.075
			filled_polygon([Vector2(x, 0.59), Vector2(x + 0.035, 0.69), Vector2(x + 0.07, 0.59)], foam, ink)


func draw_casino_target(variant: int) -> void:
	var ink := Color("#160920")
	var neon := Color("#ff75d8")
	var violet := Color("#8f6cff")
	var gold := Color("#ffd166")
	draw_frame(Color("#321847"), neon if variant != 3 else gold)
	filled_polygon([Vector2(0.10, 0.95), Vector2(0.20, 0.68), Vector2(0.80, 0.68), Vector2(0.90, 0.95)], violet if variant % 2 == 0 else Color("#7a275d"), ink)
	if variant == 2:
		filled_polygon([Vector2(0.24, 0.25), Vector2(0.73, 0.20), Vector2(0.78, 0.68), Vector2(0.28, 0.72)], Color("#eadcf1"), ink)
		for point in [Vector2(0.38, 0.37), Vector2(0.62, 0.34), Vector2(0.40, 0.57), Vector2(0.64, 0.54)]:
			draw_circle(point, 0.045, ink)
	elif variant == 3:
		filled_polygon([Vector2(0.20, 0.24), Vector2(0.80, 0.24), Vector2(0.76, 0.72), Vector2(0.24, 0.72)], Color("#5b285f"), gold)
		for x in [0.34, 0.50, 0.66]:
			outlined_circle(Vector2(x, 0.48), 0.095, Color("#f8e8f5"), ink, 0.022)
			draw_circle(Vector2(x, 0.48), 0.035, neon)
		filled_polygon([Vector2(0.25, 0.27), Vector2(0.30, 0.10), Vector2(0.43, 0.22), Vector2(0.51, 0.07), Vector2(0.61, 0.22), Vector2(0.74, 0.10), Vector2(0.78, 0.27)], gold, ink)
	else:
		outlined_ellipse(Vector2(0.50, 0.50), Vector2(0.29, 0.31), Color("#d89acb") if variant == 1 else Color("#a777c6"), ink, 0.034)
		for eye in [Vector2(0.39, 0.47), Vector2(0.61, 0.47)]:
			outlined_circle(eye, 0.06, Color("#f8edf4"), ink, 0.02)
			draw_circle(eye, 0.023, violet)
		if variant == 0:
			filled_polygon([Vector2(0.23, 0.31), Vector2(0.77, 0.28), Vector2(0.70, 0.37), Vector2(0.27, 0.38)], ink, neon)
			filled_polygon([Vector2(0.35, 0.30), Vector2(0.38, 0.10), Vector2(0.65, 0.09), Vector2(0.70, 0.30)], Color("#241030"), ink)
			draw_line(Vector2(0.39, 0.26), Vector2(0.67, 0.25), gold, 0.03, true)
		else:
			filled_polygon([Vector2(0.28, 0.30), Vector2(0.32, 0.12), Vector2(0.45, 0.23), Vector2(0.51, 0.08), Vector2(0.58, 0.23), Vector2(0.72, 0.12), Vector2(0.74, 0.31)], gold, ink)
			filled_polygon([Vector2(0.50, 0.57), Vector2(0.60, 0.66), Vector2(0.50, 0.76), Vector2(0.40, 0.66)], neon, ink)
		draw_arc(Vector2(0.50, 0.59), 0.14, 0.12, PI - 0.12, 20, ink, 0.027, true)
	# Casino-chip shoulders keep the family readable as a set at archive size.
	for x in [0.20, 0.80]:
		outlined_circle(Vector2(x, 0.79), 0.085, neon, ink, 0.02)
		draw_circle(Vector2(x, 0.79), 0.027, gold)


func draw_frame(background: Color, rim: Color) -> void:
	filled_polygon([
		Vector2(0.08, 0.025), Vector2(0.92, 0.025), Vector2(0.975, 0.08), Vector2(0.975, 0.92),
		Vector2(0.92, 0.975), Vector2(0.08, 0.975), Vector2(0.025, 0.92), Vector2(0.025, 0.08),
	], background, rim)
	draw_circle(Vector2(0.76, 0.20), 0.22, Color(rim, 0.10))
	draw_line(Vector2(0.06, 0.84), Vector2(0.94, 0.84), Color(rim, 0.24), 0.018, true)


func draw_hunter() -> void:
	var ink := Color("#091127")
	var cyan := Color("#55e5ff")
	var gold := Color("#ffc857")
	var weapon: Dictionary = equipment_profile.get("weapon", {})
	var armor: Dictionary = equipment_profile.get("armor", {})
	var species_id := str(equipment_profile.get("species_id", ""))
	var species_accent := species_accent_color(species_id)
	var weapon_color := equipment_color(weapon, cyan)
	var armor_color := equipment_color(armor, Color("#273357"))
	var weapon_origin := str(weapon.get("origin_planet_id", ""))
	var armor_origin := str(armor.get("origin_planet_id", ""))
	var kit_active := not weapon_origin.is_empty() and weapon_origin == armor_origin
	var active_origin := weapon_origin if kit_active else armor_origin
	var origin_color := planet_loadout_color(active_origin) if not active_origin.is_empty() else species_accent
	draw_frame(Color("#13284a"), gold if kit_active else origin_color)
	# Shoulders and helmet.
	filled_polygon([Vector2(0.12, 0.94), Vector2(0.20, 0.72), Vector2(0.38, 0.64), Vector2(0.62, 0.64), Vector2(0.80, 0.72), Vector2(0.88, 0.94)], armor_color.darkened(0.35), ink)
	var appearance: Dictionary = equipment_profile.get("appearance", {})
	var skin := appearance_skin_color(species_skin_color(species_id), str(appearance.get("palette", "native")))
	outlined_circle(Vector2(0.50, 0.50), 0.31, skin, ink, 0.032)
	# Crooked space-western hat.
	filled_polygon([Vector2(0.20, 0.30), Vector2(0.81, 0.25), Vector2(0.75, 0.36), Vector2(0.23, 0.38)], Color("#9a552b"), ink)
	filled_polygon([Vector2(0.34, 0.29), Vector2(0.38, 0.10), Vector2(0.65, 0.08), Vector2(0.72, 0.28)], Color("#b96a35"), ink)
	draw_line(Vector2(0.38, 0.25), Vector2(0.69, 0.23), gold, 0.035, true)
	# Visor and face read at tiny sizes.
	filled_polygon([Vector2(0.24, 0.43), Vector2(0.76, 0.39), Vector2(0.70, 0.62), Vector2(0.30, 0.64)], Color("#173952"), ink)
	draw_line(Vector2(0.31, 0.47), Vector2(0.64, 0.44), Color(weapon_color, 0.85), 0.035, true)
	var eye_radius := 0.046 if str(appearance.get("eyes", "standard")) == "wide" else (0.025 if str(appearance.get("eyes", "standard")) == "narrow" else 0.035)
	draw_circle(Vector2(0.37, 0.54), eye_radius, weapon_color)
	draw_circle(Vector2(0.62, 0.52), eye_radius, weapon_color)
	draw_line(Vector2(0.43, 0.70), Vector2(0.61, 0.68), ink, 0.025, true)
	if species_id == "synthetic":
		draw_line(Vector2(0.30, 0.65), Vector2(0.39, 0.75), species_accent, 0.022, true)
		draw_line(Vector2(0.70, 0.63), Vector2(0.61, 0.75), species_accent, 0.022, true)
		draw_circle(Vector2(0.72, 0.58), 0.025, species_accent)
	elif species_id == "starworn":
		draw_circle(Vector2(0.50, 0.39), 0.025, species_accent)
		draw_line(Vector2(0.35, 0.28), Vector2(0.29, 0.17), species_accent, 0.025, true)
		draw_line(Vector2(0.66, 0.27), Vector2(0.73, 0.15), species_accent, 0.025, true)
	elif species_id == "fungoid":
		for point in [Vector2(0.31, 0.65), Vector2(0.39, 0.72), Vector2(0.69, 0.63)]:
			draw_circle(point, 0.022, species_accent)
	elif species_id == "mothari":
		draw_line(Vector2(0.29, 0.65), Vector2(0.41, 0.75), species_accent, 0.025, true)
		draw_line(Vector2(0.69, 0.62), Vector2(0.58, 0.74), species_accent, 0.025, true)
		draw_circle(Vector2(0.72, 0.57), 0.022, Color("#d7c5b5"))
	elif species_id == "abyssal":
		for y in [0.61, 0.67, 0.73]:
			draw_line(Vector2(0.28, y), Vector2(0.34, y - 0.015), species_accent, 0.020, true)
			draw_line(Vector2(0.72, y), Vector2(0.66, y - 0.015), species_accent, 0.020, true)
	elif species_id == "glitchlight":
		draw_colored_polygon(PackedVector2Array([Vector2(0.50, 0.37), Vector2(0.54, 0.42), Vector2(0.50, 0.47), Vector2(0.46, 0.42)]), species_accent)
		draw_line(Vector2(0.35, 0.67), Vector2(0.50, 0.76), Color(species_accent, 0.75), 0.020, true)
		draw_line(Vector2(0.65, 0.65), Vector2(0.50, 0.76), Color(species_accent, 0.75), 0.020, true)
	elif species_id == "scraproot":
		draw_line(Vector2(0.35, 0.29), Vector2(0.29, 0.18), species_accent, 0.030, true)
		draw_line(Vector2(0.65, 0.27), Vector2(0.72, 0.16), species_accent, 0.030, true)
		for point in [Vector2(0.32, 0.65), Vector2(0.39, 0.72), Vector2(0.68, 0.64)]:
			draw_circle(point, 0.019, species_accent)
	if str(appearance.get("marking", "clean")) == "stripe":
		draw_line(Vector2(0.32, 0.66), Vector2(0.68, 0.62), Color(species_accent, 0.75), 0.022, true)
	elif str(appearance.get("marking", "clean")) == "spots":
		for point in [Vector2(0.34, 0.66), Vector2(0.48, 0.72), Vector2(0.64, 0.65)]:
			draw_circle(point, 0.018, Color(species_accent, 0.78))
	if str(appearance.get("feature", "classic")) == "bold":
		draw_line(Vector2(0.27, 0.36), Vector2(0.20, 0.21), species_accent, 0.032, true)
		draw_line(Vector2(0.73, 0.34), Vector2(0.80, 0.19), species_accent, 0.032, true)
	elif str(appearance.get("feature", "classic")) == "subtle":
		draw_circle(Vector2(0.50, 0.39), 0.018, species_accent)
	# Antenna keeps the silhouette distinctive.
	draw_line(Vector2(0.72, 0.17), Vector2(0.84, 0.08), ink, 0.025, true)
	outlined_circle(Vector2(0.86, 0.065), 0.035, weapon_color, ink, 0.018)
	# Workshop investment and a matching planetary kit remain readable at combat size.
	var upgrade_count := mini(5, int(weapon.get("power_upgrades", 0)) + int(armor.get("integrity_upgrades", 0)))
	for pip in upgrade_count:
		draw_circle(Vector2(0.29 + float(pip) * 0.105, 0.87), 0.026, origin_color)
	if kit_active:
		draw_line(Vector2(0.25, 0.77), Vector2(0.75, 0.77), gold, 0.025, true)


func equipment_color(item: Dictionary, fallback: Color) -> Color:
	var raw_color := str(item.get("color", ""))
	return Color(raw_color) if Color.html_is_valid(raw_color) else fallback


func species_skin_color(species_id: String) -> Color:
	match species_id:
		"synthetic":
			return Color("#7189a8")
		"starworn":
			return Color("#8c74b5")
		"fungoid":
			return Color("#9fbd72")
		"mothari":
			return Color("#806b5d")
		"abyssal":
			return Color("#508ca3")
		"glitchlight":
			return Color("#bcecf2")
		"scraproot":
			return Color("#648a58")
		_:
			return Color("#d7d6c9")


func species_accent_color(species_id: String) -> Color:
	match species_id:
		"terran":
			return Color("#ffc857")
		"synthetic":
			return Color("#55e5ff")
		"starworn":
			return Color("#b8f45d")
		"fungoid":
			return Color("#ff7ad9")
		"mothari":
			return Color("#ff8a4c")
		"abyssal":
			return Color("#46d9c8")
		"glitchlight":
			return Color("#ffe66d")
		"scraproot":
			return Color("#72d572")
		_:
			return Color("#55e5ff")


func appearance_skin_color(base: Color, palette: String) -> Color:
	match palette:
		"warm":
			return base.lerp(Color("#d98f68"), 0.34)
		"cool":
			return base.lerp(Color("#738bd4"), 0.34)
		_:
			return base


func planet_loadout_color(planet_id: String) -> Color:
	match planet_id:
		"dustball_prime":
			return Color("#ffc857")
		"congelaria_sa":
			return Color("#72f1dd")
		"micelia_404":
			return Color("#c7f464")
		"ferro_velho_omega":
			return Color("#ff9f43")
		"cassino_quasar":
			return Color("#ff75d8")
		"aeropolis_penhora":
			return Color("#8fd3ff")
		"arquivo_abissal_n9":
			return Color("#39d7c5")
		_:
			return Color("#55e5ff")


func draw_gloop() -> void:
	var ink := Color("#071426")
	var green := Color("#8de35e")
	var lime := Color("#c8ff75")
	draw_frame(Color("#173b48"), green)
	# Tentacles behind a pear-shaped head.
	for x in [0.26, 0.39, 0.61, 0.74]:
		draw_line(Vector2(0.50, 0.73), Vector2(x, 0.93), ink, 0.085, true)
		draw_line(Vector2(0.50, 0.72), Vector2(x, 0.92), green, 0.050, true)
	outlined_ellipse(Vector2(0.50, 0.53), Vector2(0.34, 0.39), green, ink, 0.030)
	# Three eyes make Gloop identifiable without detail.
	for eye in [Vector2(0.34, 0.43), Vector2(0.50, 0.36), Vector2(0.66, 0.43)]:
		outlined_circle(eye, 0.095, Color("#f3f0db"), ink, 0.024)
		draw_circle(eye + Vector2(0.012, 0.01), 0.037, Color("#25233f"))
		draw_circle(eye - Vector2(0.005, 0.01), 0.012, lime)
	draw_arc(Vector2(0.50, 0.58), 0.15, 0.18, PI - 0.18, 24, ink, 0.030, true)
	draw_circle(Vector2(0.36, 0.65), 0.025, Color(0.24, 0.55, 0.28, 0.7))
	draw_circle(Vector2(0.65, 0.64), 0.018, Color(0.24, 0.55, 0.28, 0.7))


func draw_baron() -> void:
	var ink := Color("#1b0b20")
	var coral := Color("#ff6f57")
	var gold := Color("#ffc857")
	draw_frame(Color("#4a1d35"), coral)
	filled_polygon([Vector2(0.16, 0.94), Vector2(0.25, 0.69), Vector2(0.75, 0.69), Vector2(0.85, 0.94)], Color("#6e2440"), ink)
	outlined_circle(Vector2(0.50, 0.50), 0.31, coral, ink, 0.035)
	# Fuse, crown and monocle communicate his ridiculous nobility.
	draw_line(Vector2(0.55, 0.20), Vector2(0.62, 0.07), ink, 0.032, true)
	draw_line(Vector2(0.62, 0.07), Vector2(0.72, 0.13), gold, 0.028, true)
	filled_polygon([Vector2(0.27, 0.28), Vector2(0.30, 0.12), Vector2(0.42, 0.22), Vector2(0.51, 0.08), Vector2(0.60, 0.22), Vector2(0.72, 0.12), Vector2(0.73, 0.30)], gold, ink)
	for eye in [Vector2(0.38, 0.45), Vector2(0.62, 0.45)]:
		outlined_circle(eye, 0.065, Color("#f4e9d5"), ink, 0.022)
		draw_circle(eye, 0.025, ink)
	draw_arc(Vector2(0.62, 0.45), 0.105, 0.0, TAU, 28, gold, 0.022, true)
	draw_line(Vector2(0.70, 0.52), Vector2(0.75, 0.69), gold, 0.018, true)
	filled_polygon([Vector2(0.50, 0.60), Vector2(0.34, 0.55), Vector2(0.27, 0.66), Vector2(0.47, 0.68)], Color("#301126"), ink)
	filled_polygon([Vector2(0.50, 0.60), Vector2(0.66, 0.55), Vector2(0.73, 0.66), Vector2(0.53, 0.68)], Color("#301126"), ink)


func draw_madame() -> void:
	var ink := Color("#080c22")
	var violet := Color("#b36cff")
	var cyan := Color("#64ebff")
	draw_frame(Color("#2e2151"), violet)
	# Vacuum hoses and a severe orbital collar.
	draw_arc(Vector2(0.50, 0.69), 0.34, 0.08, PI - 0.08, 40, ink, 0.115, true)
	draw_arc(Vector2(0.50, 0.69), 0.34, 0.08, PI - 0.08, 40, violet, 0.067, true)
	outlined_circle(Vector2(0.50, 0.47), 0.31, Color("#8050bb"), ink, 0.035)
	outlined_circle(Vector2(0.50, 0.48), 0.225, Color("#191933"), cyan, 0.024)
	# Asymmetric eyes and breathing valve.
	outlined_circle(Vector2(0.42, 0.44), 0.072, Color("#e9f6f0"), ink, 0.020)
	outlined_circle(Vector2(0.59, 0.42), 0.055, Color("#e9f6f0"), ink, 0.020)
	draw_circle(Vector2(0.43, 0.45), 0.025, violet)
	draw_circle(Vector2(0.59, 0.43), 0.021, violet)
	filled_polygon([Vector2(0.40, 0.58), Vector2(0.60, 0.56), Vector2(0.65, 0.68), Vector2(0.50, 0.74), Vector2(0.35, 0.68)], Color("#3c4164"), ink)
	draw_circle(Vector2(0.50, 0.64), 0.055, cyan)
	draw_circle(Vector2(0.50, 0.64), 0.023, ink)
	draw_line(Vector2(0.28, 0.29), Vector2(0.18, 0.15), violet, 0.034, true)
	draw_line(Vector2(0.72, 0.29), Vector2(0.82, 0.12), violet, 0.034, true)


func draw_mayor() -> void:
	var ink := Color("#160d19")
	var gold := Color("#ffc857")
	var rust := Color("#b9583f")
	draw_frame(Color("#56352b"), gold)
	# A broad coat, badge, hat and mechanical moustache give the chapter boss a civic-western silhouette.
	filled_polygon([Vector2(0.10, 0.96), Vector2(0.19, 0.68), Vector2(0.81, 0.68), Vector2(0.90, 0.96)], rust, ink)
	outlined_ellipse(Vector2(0.50, 0.50), Vector2(0.31, 0.34), Color("#d69a66"), ink, 0.035)
	filled_polygon([Vector2(0.15, 0.30), Vector2(0.85, 0.27), Vector2(0.77, 0.38), Vector2(0.21, 0.39)], Color("#6e3327"), ink)
	filled_polygon([Vector2(0.31, 0.30), Vector2(0.36, 0.09), Vector2(0.68, 0.08), Vector2(0.75, 0.31)], Color("#8d4630"), ink)
	draw_line(Vector2(0.35, 0.27), Vector2(0.72, 0.26), gold, 0.035, true)
	for eye in [Vector2(0.38, 0.47), Vector2(0.62, 0.47)]:
		outlined_circle(eye, 0.063, Color("#f5ead8"), ink, 0.021)
		draw_circle(eye + Vector2(0.012, 0.0), 0.024, ink)
	# A deliberately over-engineered brass moustache.
	filled_polygon([Vector2(0.50, 0.61), Vector2(0.42, 0.56), Vector2(0.25, 0.60), Vector2(0.34, 0.70), Vector2(0.50, 0.65)], gold, ink)
	filled_polygon([Vector2(0.50, 0.61), Vector2(0.58, 0.56), Vector2(0.75, 0.60), Vector2(0.66, 0.70), Vector2(0.50, 0.65)], gold, ink)
	# Crooked seven-point badge: official enough from a distance.
	filled_polygon([Vector2(0.72, 0.72), Vector2(0.76, 0.79), Vector2(0.84, 0.78), Vector2(0.80, 0.85), Vector2(0.84, 0.92), Vector2(0.75, 0.90), Vector2(0.69, 0.95), Vector2(0.68, 0.86), Vector2(0.61, 0.81), Vector2(0.70, 0.79)], gold, ink)


func draw_auditor() -> void:
	var ink := Color("#071528")
	var ice := Color("#72f1dd")
	var blue := Color("#4d8bd6")
	draw_frame(Color("#163c5b"), ice)
	filled_polygon([Vector2(0.12, 0.95), Vector2(0.20, 0.68), Vector2(0.80, 0.68), Vector2(0.88, 0.95)], blue, ink)
	# Transparent cryogenic dome over a permanently unimpressed inspector.
	outlined_circle(Vector2(0.50, 0.48), 0.32, Color("#b8dddf"), ink, 0.034)
	draw_arc(Vector2(0.50, 0.47), 0.27, PI + 0.25, TAU - 0.2, 28, Color(0.85, 1.0, 1.0, 0.75), 0.035, true)
	for eye in [Vector2(0.39, 0.46), Vector2(0.61, 0.46)]:
		draw_line(eye - Vector2(0.06, 0.01), eye + Vector2(0.06, 0.01), ink, 0.035, true)
	draw_line(Vector2(0.42, 0.62), Vector2(0.59, 0.61), ink, 0.027, true)
	# Clipboard antenna and icicle tie make the bureaucratic role readable at mobile size.
	filled_polygon([Vector2(0.25, 0.24), Vector2(0.31, 0.08), Vector2(0.39, 0.11), Vector2(0.34, 0.28)], Color("#e8f3ee"), ink)
	filled_polygon([Vector2(0.46, 0.70), Vector2(0.54, 0.70), Vector2(0.58, 0.88), Vector2(0.50, 0.94), Vector2(0.42, 0.88)], ice, ink)
	for x in [0.25, 0.75]:
		filled_polygon([Vector2(x - 0.05, 0.71), Vector2(x + 0.05, 0.71), Vector2(x, 0.86)], ice, ink)


func draw_chef() -> void:
	var ink := Color("#160d19")
	var ice := Color("#72f1dd")
	var flame := Color("#ff7657")
	draw_frame(Color("#24445d"), flame)
	filled_polygon([Vector2(0.12, 0.95), Vector2(0.22, 0.67), Vector2(0.78, 0.67), Vector2(0.88, 0.95)], Color("#e8f3ee"), ink)
	outlined_circle(Vector2(0.50, 0.50), 0.29, Color("#79b8c2"), ink, 0.034)
	# Tall thermal toque with a contraband heating coil.
	filled_polygon([Vector2(0.27, 0.31), Vector2(0.30, 0.11), Vector2(0.42, 0.15), Vector2(0.50, 0.07), Vector2(0.59, 0.15), Vector2(0.72, 0.11), Vector2(0.73, 0.33)], Color("#f3f1df"), ink)
	draw_line(Vector2(0.34, 0.29), Vector2(0.67, 0.27), flame, 0.035, true)
	for eye in [Vector2(0.40, 0.48), Vector2(0.60, 0.48)]:
		outlined_circle(eye, 0.058, Color("#f5ead8"), ink, 0.02)
		draw_circle(eye, 0.022, flame)
	draw_arc(Vector2(0.50, 0.60), 0.15, 0.12, PI - 0.12, 20, ink, 0.03, true)
	filled_polygon([Vector2(0.45, 0.72), Vector2(0.55, 0.72), Vector2(0.61, 0.92), Vector2(0.50, 0.86), Vector2(0.39, 0.92)], flame, ink)


func draw_penguin() -> void:
	var ink := Color("#050c1c")
	var ice := Color("#72f1dd")
	var gold := Color("#ffc857")
	draw_frame(Color("#162c4a"), ice)
	outlined_ellipse(Vector2(0.50, 0.55), Vector2(0.31, 0.39), Color("#172033"), ink, 0.032)
	outlined_ellipse(Vector2(0.50, 0.57), Vector2(0.20, 0.28), Color("#e9f0e8"), ink, 0.025)
	for eye in [Vector2(0.40, 0.43), Vector2(0.60, 0.43)]:
		draw_circle(eye, 0.035, Color("#f5f4df"))
		draw_circle(eye + Vector2(0.008, 0.0), 0.016, ink)
	filled_polygon([Vector2(0.42, 0.52), Vector2(0.58, 0.52), Vector2(0.50, 0.61)], gold, ink)
	# Boardroom bow tie and tiny briefcase corners.
	filled_polygon([Vector2(0.50, 0.69), Vector2(0.35, 0.63), Vector2(0.31, 0.75), Vector2(0.48, 0.77)], Color("#d85b75"), ink)
	filled_polygon([Vector2(0.50, 0.69), Vector2(0.65, 0.63), Vector2(0.69, 0.75), Vector2(0.52, 0.77)], Color("#d85b75"), ink)
	draw_line(Vector2(0.23, 0.72), Vector2(0.13, 0.91), ink, 0.07, true)
	draw_line(Vector2(0.77, 0.72), Vector2(0.87, 0.91), ink, 0.07, true)


func draw_director() -> void:
	var ink := Color("#071022")
	var ice := Color("#72f1dd")
	var violet := Color("#a97cff")
	draw_frame(Color("#17355b"), ice)
	filled_polygon([Vector2(0.10, 0.96), Vector2(0.18, 0.66), Vector2(0.82, 0.66), Vector2(0.90, 0.96)], Color("#283c72"), ink)
	# Faceted cryo-mask and crown-like radiator establish the chapter boss silhouette.
	filled_polygon([Vector2(0.50, 0.16), Vector2(0.76, 0.35), Vector2(0.69, 0.68), Vector2(0.50, 0.79), Vector2(0.31, 0.68), Vector2(0.24, 0.35)], Color("#b9ece7"), ink)
	for x in [0.28, 0.40, 0.52, 0.64]:
		filled_polygon([Vector2(x, 0.24), Vector2(x + 0.06, 0.05), Vector2(x + 0.12, 0.25)], ice, ink)
	for eye in [Vector2(0.39, 0.46), Vector2(0.61, 0.46)]:
		filled_polygon([eye - Vector2(0.075, 0.025), eye + Vector2(0.075, -0.025), eye + Vector2(0.055, 0.045), eye + Vector2(-0.055, 0.045)], violet, ink)
	draw_line(Vector2(0.40, 0.64), Vector2(0.60, 0.62), ink, 0.035, true)
	draw_circle(Vector2(0.50, 0.84), 0.075, violet)
	draw_circle(Vector2(0.50, 0.84), 0.032, ink)


func draw_landlord_spore() -> void:
	var ink := Color("#0d1520")
	var lime := Color("#c7f464")
	var pink := Color("#ff75c8")
	draw_frame(Color("#263f35"), lime)
	# Root-like suit and a broad mushroom cap establish the fungal landlord silhouette.
	filled_polygon([Vector2(0.12, 0.96), Vector2(0.23, 0.66), Vector2(0.77, 0.66), Vector2(0.88, 0.96)], Color("#655238"), ink)
	outlined_ellipse(Vector2(0.50, 0.52), Vector2(0.24, 0.31), Color("#d8d29a"), ink, 0.032)
	filled_polygon([Vector2(0.10, 0.37), Vector2(0.18, 0.19), Vector2(0.34, 0.09), Vector2(0.61, 0.08), Vector2(0.82, 0.18), Vector2(0.91, 0.37)], pink, ink)
	for spot in [Vector2(0.28, 0.22), Vector2(0.50, 0.16), Vector2(0.72, 0.25)]:
		draw_circle(spot, 0.048, lime)
	for eye in [Vector2(0.40, 0.48), Vector2(0.60, 0.48)]:
		outlined_circle(eye, 0.057, Color("#f4f0d4"), ink, 0.020)
		draw_circle(eye + Vector2(0.01, 0.0), 0.021, ink)
	draw_line(Vector2(0.42, 0.63), Vector2(0.59, 0.61), ink, 0.03, true)
	# Tiny key ring and tie signal authority more than competence.
	filled_polygon([Vector2(0.46, 0.70), Vector2(0.54, 0.70), Vector2(0.58, 0.88), Vector2(0.50, 0.93), Vector2(0.42, 0.88)], lime, ink)
	draw_arc(Vector2(0.75, 0.78), 0.065, 0.0, TAU, 20, Color("#ffc857"), 0.025, true)
	draw_line(Vector2(0.80, 0.82), Vector2(0.87, 0.91), Color("#ffc857"), 0.025, true)


func draw_countess_truffle() -> void:
	var ink := Color("#160d20")
	var plum := Color("#8f4fa8")
	var gold := Color("#ffc857")
	draw_frame(Color("#3c2949"), plum)
	filled_polygon([Vector2(0.10, 0.96), Vector2(0.21, 0.66), Vector2(0.79, 0.66), Vector2(0.90, 0.96)], Color("#512f62"), ink)
	outlined_ellipse(Vector2(0.50, 0.51), Vector2(0.25, 0.31), Color("#b98a76"), ink, 0.032)
	# Layered truffle cap, pearls and monocle make the financial aristocrat readable.
	filled_polygon([Vector2(0.15, 0.34), Vector2(0.23, 0.16), Vector2(0.42, 0.08), Vector2(0.68, 0.12), Vector2(0.84, 0.34)], Color("#6b3e53"), ink)
	for spot in [Vector2(0.31, 0.21), Vector2(0.51, 0.16), Vector2(0.69, 0.25)]:
		draw_circle(spot, 0.035, gold)
	for eye in [Vector2(0.40, 0.48), Vector2(0.60, 0.48)]:
		outlined_circle(eye, 0.055, Color("#f5ead8"), ink, 0.019)
		draw_circle(eye, 0.020, ink)
	draw_arc(Vector2(0.60, 0.48), 0.09, 0.0, TAU, 24, gold, 0.021, true)
	draw_line(Vector2(0.67, 0.54), Vector2(0.73, 0.70), gold, 0.018, true)
	draw_line(Vector2(0.42, 0.63), Vector2(0.59, 0.61), ink, 0.028, true)
	for pearl_x in [0.38, 0.45, 0.52, 0.59, 0.66]:
		draw_circle(Vector2(pearl_x, 0.76), 0.025, Color("#f2e8cc"))


func draw_captain_chlorophyll() -> void:
	var ink := Color("#071424")
	var green := Color("#75df63")
	var gold := Color("#ffc857")
	draw_frame(Color("#1d4b42"), green)
	filled_polygon([Vector2(0.09, 0.96), Vector2(0.20, 0.67), Vector2(0.80, 0.67), Vector2(0.91, 0.96)], Color("#315d45"), ink)
	outlined_circle(Vector2(0.50, 0.50), 0.29, Color("#83c85f"), ink, 0.034)
	# Leaf tricorn, eyepatch and solar badge communicate pirate captain instantly.
	filled_polygon([Vector2(0.14, 0.33), Vector2(0.34, 0.12), Vector2(0.49, 0.27), Vector2(0.67, 0.09), Vector2(0.86, 0.34)], Color("#356f48"), ink)
	draw_line(Vector2(0.25, 0.31), Vector2(0.76, 0.30), gold, 0.032, true)
	outlined_circle(Vector2(0.39, 0.48), 0.058, Color("#f4efd5"), ink, 0.020)
	draw_circle(Vector2(0.39, 0.48), 0.021, ink)
	filled_polygon([Vector2(0.52, 0.41), Vector2(0.70, 0.43), Vector2(0.67, 0.56), Vector2(0.51, 0.54)], Color("#182136"), ink)
	draw_line(Vector2(0.51, 0.43), Vector2(0.72, 0.34), ink, 0.023, true)
	draw_arc(Vector2(0.50, 0.61), 0.14, 0.2, PI - 0.2, 20, ink, 0.03, true)
	draw_circle(Vector2(0.72, 0.80), 0.065, gold)
	for ray in 6:
		var angle := TAU * float(ray) / 6.0
		draw_line(Vector2(0.72, 0.80) + Vector2(cos(angle), sin(angle)) * 0.075, Vector2(0.72, 0.80) + Vector2(cos(angle), sin(angle)) * 0.105, gold, 0.015, true)


func draw_mother_mycelia() -> void:
	var ink := Color("#08151a")
	var lime := Color("#c7f464")
	var pink := Color("#ff75c8")
	draw_frame(Color("#263e39"), pink)
	# Root mantle and crown-cap form an imposing networked boss silhouette.
	for root_x in [0.18, 0.30, 0.70, 0.82]:
		draw_line(Vector2(0.50, 0.68), Vector2(root_x, 0.96), ink, 0.10, true)
		draw_line(Vector2(0.50, 0.68), Vector2(root_x, 0.96), lime, 0.055, true)
	outlined_ellipse(Vector2(0.50, 0.50), Vector2(0.29, 0.33), Color("#b9d88a"), ink, 0.035)
	filled_polygon([Vector2(0.10, 0.33), Vector2(0.21, 0.13), Vector2(0.38, 0.20), Vector2(0.50, 0.05), Vector2(0.62, 0.20), Vector2(0.79, 0.13), Vector2(0.90, 0.33)], pink, ink)
	for eye in [Vector2(0.34, 0.45), Vector2(0.50, 0.39), Vector2(0.66, 0.45)]:
		outlined_circle(eye, 0.064, Color("#f3f0d7"), ink, 0.020)
		draw_circle(eye, 0.023, Color("#7a3fa0"))
	draw_line(Vector2(0.39, 0.62), Vector2(0.61, 0.62), ink, 0.034, true)
	for node in [Vector2(0.30, 0.76), Vector2(0.50, 0.84), Vector2(0.70, 0.76)]:
		draw_circle(node, 0.045, pink)
		draw_circle(node, 0.018, ink)


func draw_bolt_collector() -> void:
	var ink := Color("#170f16")
	var rust := Color("#ff9f43")
	var steel := Color("#7593a6")
	draw_frame(Color("#3d302d"), rust)
	filled_polygon([Vector2(0.12, 0.95), Vector2(0.20, 0.67), Vector2(0.80, 0.67), Vector2(0.88, 0.95)], steel, ink)
	# Horseshoe magnet head and receipt tongue make the collector readable at a glance.
	draw_arc(Vector2(0.50, 0.47), 0.28, PI, TAU, 36, ink, 0.18, true)
	draw_arc(Vector2(0.50, 0.47), 0.28, PI, TAU, 36, rust, 0.11, true)
	draw_line(Vector2(0.22, 0.46), Vector2(0.22, 0.69), rust, 0.11, true)
	draw_line(Vector2(0.78, 0.46), Vector2(0.78, 0.69), rust, 0.11, true)
	for eye in [Vector2(0.39, 0.47), Vector2(0.61, 0.47)]:
		outlined_circle(eye, 0.055, Color("#fff0c2"), ink, 0.02)
		draw_circle(eye, 0.020, ink)
	filled_polygon([Vector2(0.40, 0.61), Vector2(0.62, 0.61), Vector2(0.58, 0.87), Vector2(0.44, 0.82)], Color("#f3e5c0"), ink)
	for y in [0.67, 0.73, 0.79]:
		draw_line(Vector2(0.46, y), Vector2(0.57, y), ink, 0.012, true)


func draw_doctor_patchwork() -> void:
	var ink := Color("#111020")
	var rust := Color("#ff9f43")
	var mint := Color("#72f1dd")
	draw_frame(Color("#343747"), mint)
	filled_polygon([Vector2(0.10, 0.96), Vector2(0.20, 0.66), Vector2(0.80, 0.66), Vector2(0.90, 0.96)], Color("#e2ddd0"), ink)
	outlined_circle(Vector2(0.50, 0.48), 0.29, Color("#a88f77"), ink, 0.034)
	# Welding goggles, antenna scalpel and mismatched surgical arms.
	for eye in [Vector2(0.39, 0.47), Vector2(0.61, 0.47)]:
		outlined_circle(eye, 0.083, Color("#263d50"), rust, 0.025)
		draw_circle(eye, 0.025, mint)
	draw_line(Vector2(0.47, 0.47), Vector2(0.53, 0.47), rust, 0.025, true)
	draw_line(Vector2(0.67, 0.25), Vector2(0.80, 0.08), ink, 0.028, true)
	filled_polygon([Vector2(0.78, 0.10), Vector2(0.85, 0.03), Vector2(0.84, 0.14)], Color("#d8e8e5"), ink)
	draw_line(Vector2(0.20, 0.72), Vector2(0.08, 0.84), rust, 0.055, true)
	draw_line(Vector2(0.80, 0.72), Vector2(0.92, 0.88), mint, 0.055, true)
	draw_line(Vector2(0.42, 0.62), Vector2(0.59, 0.61), ink, 0.026, true)
	draw_circle(Vector2(0.50, 0.79), 0.055, rust)
	draw_line(Vector2(0.50, 0.74), Vector2(0.50, 0.84), Color.WHITE, 0.018, true)
	draw_line(Vector2(0.45, 0.79), Vector2(0.55, 0.79), Color.WHITE, 0.018, true)


func draw_crane_king() -> void:
	var ink := Color("#160e16")
	var rust := Color("#ff9f43")
	var gold := Color("#ffd166")
	draw_frame(Color("#493328"), gold)
	filled_polygon([Vector2(0.08, 0.96), Vector2(0.18, 0.65), Vector2(0.82, 0.65), Vector2(0.92, 0.96)], Color("#8b5535"), ink)
	filled_polygon([Vector2(0.25, 0.29), Vector2(0.75, 0.29), Vector2(0.70, 0.70), Vector2(0.30, 0.70)], Color("#b66a3c"), ink)
	# Crane boom doubles as a wildly impractical crown.
	filled_polygon([Vector2(0.18, 0.28), Vector2(0.31, 0.10), Vector2(0.43, 0.22), Vector2(0.55, 0.06), Vector2(0.68, 0.22), Vector2(0.82, 0.10), Vector2(0.80, 0.31)], gold, ink)
	draw_line(Vector2(0.69, 0.14), Vector2(0.91, 0.25), rust, 0.045, true)
	draw_line(Vector2(0.90, 0.25), Vector2(0.90, 0.48), ink, 0.022, true)
	draw_arc(Vector2(0.86, 0.52), 0.06, -1.3, 1.5, 18, ink, 0.025, true)
	for eye in [Vector2(0.40, 0.46), Vector2(0.60, 0.46)]:
		filled_polygon([eye - Vector2(0.07, 0.03), eye + Vector2(0.07, -0.03), eye + Vector2(0.05, 0.04), eye + Vector2(-0.05, 0.04)], Color("#9ff7ed"), ink)
	draw_line(Vector2(0.40, 0.61), Vector2(0.61, 0.59), ink, 0.034, true)


func draw_omega_junkyard() -> void:
	var ink := Color("#0d1019")
	var rust := Color("#ff9f43")
	var cyan := Color("#55e5ff")
	draw_frame(Color("#302f35"), rust)
	# Concentric compactor rings and one inventory eye form a planet-scale machine face.
	for radius in [0.40, 0.33, 0.25]:
		outlined_circle(Vector2(0.50, 0.51), radius, Color("#4c5158") if radius > 0.3 else Color("#252b36"), ink, 0.030)
	for tooth in 10:
		var angle := TAU * float(tooth) / 10.0
		var from := Vector2(0.50, 0.51) + Vector2(cos(angle), sin(angle)) * 0.38
		var to := Vector2(0.50, 0.51) + Vector2(cos(angle), sin(angle)) * 0.47
		draw_line(from, to, rust, 0.055, true)
	outlined_circle(Vector2(0.50, 0.48), 0.13, cyan, ink, 0.028)
	draw_circle(Vector2(0.50, 0.48), 0.055, ink)
	draw_circle(Vector2(0.47, 0.45), 0.018, Color.WHITE)
	draw_line(Vector2(0.36, 0.70), Vector2(0.64, 0.70), rust, 0.035, true)
	for x in [0.39, 0.50, 0.61]:
		draw_line(Vector2(x, 0.70), Vector2(x - 0.03, 0.78), ink, 0.022, true)


func outlined_circle(center: Vector2, radius: float, fill: Color, outline: Color, width: float) -> void:
	draw_circle(center, radius, outline)
	draw_circle(center, maxf(0.0, radius - width), fill)


func outlined_ellipse(center: Vector2, radii: Vector2, fill: Color, outline: Color, width: float) -> void:
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for point_index in 40:
		var angle := TAU * float(point_index) / 40.0
		outer.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
		inner.append(center + Vector2(cos(angle) * (radii.x - width), sin(angle) * (radii.y - width)))
	draw_colored_polygon(outer, outline)
	draw_colored_polygon(inner, fill)


func filled_polygon(points: Array[Vector2], fill: Color, outline: Color) -> void:
	var polygon := PackedVector2Array(points)
	draw_colored_polygon(polygon, fill)
	var closed := polygon.duplicate()
	closed.append(polygon[0])
	draw_polyline(closed, outline, 0.025, true)
