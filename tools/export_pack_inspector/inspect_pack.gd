extends SceneTree

const FORBIDDEN_PATHS := [
	"res://References/Shakes and Fidget Assets/StreamingAssets/tavern/tavern_back.png",
	"res://References/Shakes and Fidget Assets/StreamingAssets/town/bg_town_day.png",
	"res://References/Shakes and Fidget Assets/StreamingAssets/locations/bg_fort_0.png",
	"res://References/Shakes and Fidget Assets/StreamingAssets/locations/location_battle_0.png",
]


func _init() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() != 1:
		printerr("FAIL: expected one exported pack path")
		quit(2)
		return
	var pack_path := ProjectSettings.globalize_path(arguments[0])
	if not ProjectSettings.load_resource_pack(pack_path, true):
		printerr("FAIL: could not mount exported pack: %s" % pack_path)
		quit(2)
		return
	if DirAccess.dir_exists_absolute("res://References"):
		printerr("FAIL: exported pack contains the References directory")
		quit(1)
		return
	for forbidden_path in FORBIDDEN_PATHS:
		if FileAccess.file_exists(forbidden_path):
			printerr("FAIL: exported pack contains proprietary placeholder: %s" % forbidden_path)
			quit(1)
			return
	print("PASS: exported pack contains no proprietary reference placeholders")
	quit()
