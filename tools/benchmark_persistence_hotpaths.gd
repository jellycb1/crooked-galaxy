extends SceneTree

const StateScript = preload("res://scripts/game_state.gd")

const SAMPLE_RUNS := 12
const SAVE_PATH := "res://.godot/persistence_hotpath_benchmark.json"


func _init() -> void:
	var state = StateScript.new()
	state.persistence_enabled = true
	state.save_path = SAVE_PATH
	state.player = state.default_player()
	for item_count in [0, 30, 120]:
		state.player.inventory = benchmark_inventory(item_count)
		var samples: Array[int] = []
		for _sample in SAMPLE_RUNS:
			var started := Time.get_ticks_usec()
			if not state.save_game():
				printerr("FAIL: persistence benchmark could not commit %d items" % item_count)
				cleanup()
				state.free()
				quit(1)
				return
			samples.append(Time.get_ticks_usec() - started)
		samples.sort()
		var median := samples[samples.size() / 2]
		var p95 := samples[mini(samples.size() - 1, ceili(samples.size() * 0.95) - 1)]
		print("PERSISTENCE_BENCHMARK items=%d median=%d us p95=%d us" % [item_count, median, p95])
	cleanup()
	state.free()
	quit(0)


func benchmark_inventory(count: int) -> Array:
	var result: Array = []
	for index in count:
		result.append({
			"id": "benchmark_%03d" % index,
			"name": "Benchmark Item %d" % index,
			"description": "Deterministic local persistence fixture.",
			"slot": "weapon" if index % 2 == 0 else "armor",
			"power": 2 + index % 40,
			"rarity": "Comum",
			"color": "#b9c2d9",
			"origin_planet_id": "dustball_prime",
		})
	return result


func cleanup() -> void:
	for path in [SAVE_PATH, "%s.tmp" % SAVE_PATH, "%s.bak" % SAVE_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
