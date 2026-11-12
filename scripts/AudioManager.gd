extends Node

const SAMPLE_RATE = 22050
const SETTINGS_PATH = "user://audio_settings.cfg"

var music_player = null
var effects_player = null
var settings = ConfigFile.new()
var music_enabled = true
var effects_enabled = true
var music_volume = 0.28
var effects_volume = 0.55
var night_mode = false

func _ready():
	settings.load(SETTINGS_PATH)
	music_enabled = bool(settings.get_value("audio", "music_enabled", true))
	effects_enabled = bool(settings.get_value("audio", "effects_enabled", true))
	music_volume = float(settings.get_value("audio", "music_volume", 0.28))
	effects_volume = float(settings.get_value("audio", "effects_volume", 0.55))
	music_player = AudioStreamPlayer.new()
	music_player.name = "OriginalAmbientMusic"
	add_child(music_player)
	effects_player = AudioStreamPlayer.new()
	effects_player.name = "OriginalSoundEffects"
	add_child(effects_player)
	_apply_music()
	_apply_effects()

func _save_settings():
	settings.set_value("audio", "music_enabled", music_enabled)
	settings.set_value("audio", "effects_enabled", effects_enabled)
	settings.set_value("audio", "music_volume", music_volume)
	settings.set_value("audio", "effects_volume", effects_volume)
	settings.save(SETTINGS_PATH)

func is_music_enabled():
	return music_enabled

func is_effects_enabled():
	return effects_enabled

func get_music_volume():
	return music_volume

func get_effects_volume():
	return effects_volume

func set_music_enabled(value):
	music_enabled = bool(value)
	_save_settings()
	_apply_music()

func set_effects_enabled(value):
	effects_enabled = bool(value)
	_save_settings()
	_apply_effects()

func set_music_volume(value):
	music_volume = clamp(float(value), 0.0, 1.0)
	_save_settings()
	_apply_music()

func set_effects_volume(value):
	effects_volume = clamp(float(value), 0.0, 1.0)
	_save_settings()
	_apply_effects()

func set_night_mode(value):
	var next_mode = bool(value)
	if night_mode == next_mode:
		return
	night_mode = next_mode
	if music_enabled:
		_apply_music()

func _apply_music():
	if music_player == null:
		return
	if not music_enabled or music_volume <= 0.001:
		music_player.stop()
		return
	music_player.volume_db = linear2db(max(0.001, music_volume))
	music_player.stream = _make_ambient_music(night_mode)
	music_player.play()

func _apply_effects():
	if effects_player == null:
		return
	effects_player.volume_db = linear2db(max(0.001, effects_volume))

func play_sfx(kind="click"):
	if music_enabled and music_player != null and not music_player.playing:
		_apply_music()
	if not effects_enabled or effects_volume <= 0.001 or effects_player == null:
		return
	var tones = []
	match str(kind):
		"construction":
			tones = [[392.0, 0.0, 0.16], [523.25, 0.14, 0.18], [659.25, 0.29, 0.24]]
		"reward":
			tones = [[523.25, 0.0, 0.14], [659.25, 0.12, 0.14], [783.99, 0.24, 0.18], [1046.5, 0.39, 0.28]]
		"level":
			tones = [[392.0, 0.0, 0.18], [493.88, 0.15, 0.18], [587.33, 0.30, 0.18], [783.99, 0.45, 0.34]]
		"event":
			tones = [[659.25, 0.0, 0.12], [523.25, 0.14, 0.12], [659.25, 0.28, 0.22]]
		"construction_done":
			tones = [[440.0, 0.0, 0.16], [554.37, 0.14, 0.16], [659.25, 0.28, 0.28]]
		_:
			tones = [[880.0, 0.0, 0.055], [1174.66, 0.025, 0.075]]
	effects_player.stream = _make_tone_stream(tones, 0.72)
	effects_player.play()

func _make_ambient_music(is_night):
	var notes = [261.63, 329.63, 392.0, 329.63, 293.66, 349.23, 440.0, 349.23]
	if is_night:
		notes = [220.0, 261.63, 329.63, 261.63, 196.0, 246.94, 293.66, 246.94]
	var sample_count = SAMPLE_RATE * 8
	var bytes = PoolByteArray()
	bytes.resize(sample_count * 2)
	for i in range(sample_count):
		var t = float(i) / float(SAMPLE_RATE)
		var beat = int(floor(t))
		var local_t = fposmod(t, 1.0)
		var note = notes[beat % notes.size()]
		var next_note = notes[(beat + 1) % notes.size()]
		var fade = min(1.0, local_t / 0.10) * min(1.0, (1.0 - local_t) / 0.12)
		var slow_pulse = 0.78 + 0.22 * sin(t * PI * 0.5)
		var fundamental = sin(2.0 * PI * note * t)
		var harmonic = sin(2.0 * PI * note * 2.0 * t) * 0.16
		var pad = sin(2.0 * PI * next_note * t) * 0.12
		var sample = int(clamp((fundamental * 0.48 + harmonic + pad) * fade * slow_pulse * 3900.0, -32767.0, 32767.0))
		bytes[i * 2] = sample & 0xff
		bytes[i * 2 + 1] = (sample >> 8) & 0xff
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = bytes
	return stream

func _make_tone_stream(tones, master_gain):
	var duration = 0.0
	for tone in tones:
		duration = max(duration, float(tone[1]) + float(tone[2]))
	var sample_count = int(ceil((duration + 0.04) * SAMPLE_RATE))
	var bytes = PoolByteArray()
	bytes.resize(sample_count * 2)
	for i in range(sample_count):
		var t = float(i) / float(SAMPLE_RATE)
		var mixed = 0.0
		for tone in tones:
			var frequency = float(tone[0])
			var start = float(tone[1])
			var length = float(tone[2])
			var elapsed = t - start
			if elapsed >= 0.0 and elapsed <= length:
				var envelope = min(1.0, elapsed / 0.008) * max(0.0, 1.0 - elapsed / length)
				mixed += sin(2.0 * PI * frequency * elapsed) * envelope / float(tones.size())
		var sample = int(clamp(mixed * master_gain * 8500.0, -32767.0, 32767.0))
		bytes[i * 2] = sample & 0xff
		bytes[i * 2 + 1] = (sample >> 8) & 0xff
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
