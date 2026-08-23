extends Node

const SAMPLE_RATE := 22050

var enabled := true
var players: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}


func _ready() -> void:
	for _index in 6:
		var player := AudioStreamPlayer.new()
		player.volume_db = -9.0
		add_child(player)
		players.append(player)
	sounds = {
		"accept": synthesize([330.0, 495.0], 0.13, 0.18, 0.0),
		"laser": synthesize([620.0, 930.0], 0.12, -0.52, 0.03),
		"impact": synthesize([105.0, 155.0], 0.11, -0.18, 0.52),
		"victory": synthesize([523.25, 659.25, 783.99], 0.42, 0.08, 0.0),
		"reward": synthesize([659.25, 987.77], 0.30, 0.22, 0.0),
		"rare": synthesize([659.25, 830.61, 987.77], 0.45, 0.28, 0.0),
	}


func _exit_tree() -> void:
	for player in players:
		player.stop()
		player.stream = null
	sounds.clear()
	players.clear()


func play_accept() -> void:
	play("accept", 1.0)


func play_combat(events: Array[Dictionary]) -> void:
	for event in events:
		var player_action := str(event.get("actor", "")) == "player"
		var critical := str(event.get("quality", "")) == "CRÍTICO"
		play("laser" if player_action else "impact", 1.16 if critical else (1.0 if player_action else 0.88))


func play_victory() -> void:
	play("victory", 1.0)


func play_reward(rarity: String) -> void:
	play("rare" if rarity == "Raro" or rarity == "Épico" else "reward", 1.08 if rarity == "Épico" else 1.0)


func play(sound_id: String, pitch: float) -> void:
	if not enabled or not sounds.has(sound_id):
		return
	var selected := players[0]
	for candidate in players:
		if not candidate.playing:
			selected = candidate
			break
	selected.stream = sounds[sound_id]
	selected.pitch_scale = pitch
	selected.play()


func synthesize(frequencies: Array, duration: float, sweep: float, noise_mix: float) -> AudioStreamWAV:
	var frame_count := maxi(1, roundi(duration * SAMPLE_RATE))
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	for frame in frame_count:
		var time := float(frame) / float(SAMPLE_RATE)
		var progress := time / duration
		var envelope := pow(maxf(0.0, 1.0 - progress), 1.7)
		var tonal := 0.0
		for frequency_value in frequencies:
			var frequency := float(frequency_value)
			var phase := TAU * (frequency * time + frequency * sweep * time * time * 0.5)
			tonal += sin(phase)
		tonal /= maxf(1.0, float(frequencies.size()))
		var hash_value := sin(float(frame) * 12.9898) * 43758.5453
		var noise: float = (hash_value - floor(hash_value)) * 2.0 - 1.0
		var sample := lerpf(tonal, noise, noise_mix) * envelope * 0.58
		bytes.encode_s16(frame * 2, clampi(roundi(sample * 32767.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
