extends SceneTree

const SoundScript = preload("res://scripts/sound_fx.gd")

var failures := 0


func _init() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var sound = SoundScript.new()
	root.add_child(sound)
	await process_frame
	check(sound.sounds.size() == 6, "all original sound cues are synthesized")
	var laser: AudioStreamWAV = sound.sounds.get("laser")
	check(laser != null, "laser cue exists")
	if laser:
		check(laser.format == AudioStreamWAV.FORMAT_16_BITS, "sound uses 16-bit PCM")
		check(laser.mix_rate == 22050, "sound uses the mobile-friendly sample rate")
		check(laser.data.size() > 1000, "sound contains enough samples")
		var has_signal := false
		for offset in range(2, mini(laser.data.size(), 400), 2):
			if laser.data.decode_s16(offset) != 0:
				has_signal = true
				break
		check(has_signal, "synthesized cue is not silent")
	sound.enabled = false
	sound.play_accept()
	check(not sound.players[0].playing, "disabled audio does not start playback")
	sound.free()
	await process_frame
	if failures == 0:
		print("PASS: procedural audio is valid and controllable")
		quit(0)
	else:
		printerr("FAIL: %d audio test(s) failed" % failures)
		quit(1)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)

