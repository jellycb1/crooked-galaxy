extends SceneTree

const FORBIDDEN_PATHS := [
	"res://References/Shakes and Fidget Assets/StreamingAssets/tavern/tavern_back.png",
	"res://References/Shakes and Fidget Assets/StreamingAssets/town/bg_town_day.png",
	"res://References/Shakes and Fidget Assets/StreamingAssets/locations/bg_fort_0.png",
	"res://References/Shakes and Fidget Assets/StreamingAssets/locations/location_battle_0.png",
	"res://References/Shakes and Fidget Assets/StreamingAssets/ui/sf_4k_UI-BG-navi.png",
	"res://References/Shakes and Fidget Assets/StreamingAssets/registration/icon_warrior_active.png",
	"res://References/Shakes and Fidget Assets/StreamingAssets/registration/icon_hunter_active.png",
	"res://References/Shakes and Fidget Assets/StreamingAssets/registration/icon_mage_active.png",
	"res://References/Shakes and Fidget Assets/StreamingAssets/ui/sf_4k_UI-BG-navi-login.png",
	"res://References/Shakes and Fidget Assets/StreamingAssets/z_shared/portrait_glow_border_300.png",
	"res://References/Shakes and Fidget Assets/StreamingAssets/ui/frame_top.png",
]
const REQUIRED_PRODUCTION_ASSETS := [
	"res://assets/boot_splash.png",
	"res://assets/icon.svg",
	"res://assets/backgrounds/bounty_office.png",
	"res://assets/backgrounds/frontier_spaceport.png",
	"res://assets/backgrounds/arsenal_workshop.png",
	"res://assets/backgrounds/frontier_arena.png",
]
const INTERNAL_REFERENCE_PATHS := [
	"res://internal_reference_assets/contracts.png.bin",
	"res://internal_reference_assets/world.png.bin",
	"res://internal_reference_assets/workshop.png.bin",
	"res://internal_reference_assets/combat.png.bin",
	"res://internal_reference_assets/class_ui.png.bin",
	"res://internal_reference_assets/class_breaker.png.bin",
	"res://internal_reference_assets/class_gunslinger.png.bin",
	"res://internal_reference_assets/class_hacker.png.bin",
	"res://internal_reference_assets/career_ui.png.bin",
	"res://internal_reference_assets/portrait_frame.png.bin",
	"res://internal_reference_assets/hub_divider.png.bin",
]


func _init() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() < 1 or arguments.size() > 2:
		printerr("FAIL: expected an exported pack path and optional internal-references mode")
		quit(2)
		return
	var internal_references := arguments.size() == 2 and arguments[1] == "internal-references"
	var pack_path := ProjectSettings.globalize_path(arguments[0])
	if not ProjectSettings.load_resource_pack(pack_path, true):
		printerr("FAIL: could not mount exported pack: %s" % pack_path)
		quit(2)
		return
	if not internal_references and DirAccess.dir_exists_absolute("res://References"):
		printerr("FAIL: exported pack contains the References directory")
		quit(1)
		return
	for forbidden_path in FORBIDDEN_PATHS:
		if not internal_references and FileAccess.file_exists(forbidden_path):
			printerr("FAIL: exported pack contains proprietary placeholder: %s" % forbidden_path)
			quit(1)
			return
	if internal_references:
		for internal_path in INTERNAL_REFERENCE_PATHS:
			if not FileAccess.file_exists(internal_path):
				printerr("FAIL: internal test pack is missing staged placeholder: %s" % internal_path)
				quit(1)
				return
			var image := Image.new()
			if image.load_png_from_buffer(FileAccess.get_file_as_bytes(internal_path)) != OK or image.get_width() <= 0 or image.get_height() <= 0:
				printerr("FAIL: internal staged placeholder is not a readable PNG: %s" % internal_path)
				quit(1)
				return
	else:
		for internal_path in INTERNAL_REFERENCE_PATHS:
			if FileAccess.file_exists(internal_path):
				printerr("FAIL: public pack contains staged internal placeholder: %s" % internal_path)
				quit(1)
				return
	for required_path in REQUIRED_PRODUCTION_ASSETS:
		if not ResourceLoader.exists(required_path):
			printerr("FAIL: exported pack is missing original production asset: %s" % required_path)
			quit(1)
			return
	if internal_references:
		print("PASS: internal test pack contains original art and all eleven documented reference placeholders")
	else:
		print("PASS: exported pack contains required original art and no proprietary reference placeholders")
	quit()
