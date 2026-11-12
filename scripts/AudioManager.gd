extends Node

const SAMPLE_RATE = 22050
const SETTINGS_PATH = "user://audio_settings.cfg"

var music_player = null
var effects_player = null
var effects_players = []
var environment_player = null
var settings = ConfigFile.new()
var music_enabled = true
var effects_enabled = true
var environment_enabled = true
var music_volume = 0.28
var effects_volume = 0.55
var environment_volume = 0.18
var environment_mode = "city"
var night_mode = false

func _ready():
	settings.load(SETTINGS_PATH)
	music_enabled = bool(settings.get_value("audio", "music_enabled", true))
	effects_enabled = bool(settings.get_value("audio", "effects_enabled", true))
	environment_enabled = bool(settings.get_value("audio", "environment_enabled", true))
	music_volume = float(settings.get_value("audio", "music_volume", 0.28))
	effects_volume = float(settings.get_value("audio", "effects_volume", 0.55))
	environment_volume = float(settings.get_value("audio", "environment_volume", 0.18))
	environment_mode = str(settings.get_value("audio", "environment_mode", "city"))
	music_player = AudioStreamPlayer.new()
	music_player.name = "OriginalAmbientMusic"
	add_child(music_player)
	effects_players.clear()
	for voice_index in range(4):
		var voice = AudioStreamPlayer.new()
		voice.name = "OriginalSoundEffects%d" % voice_index
		add_child(voice)
		effects_players.append(voice)
	effects_player = effects_players[0]
	environment_player = AudioStreamPlayer.new()
	environment_player.name = "OriginalCitySoundscape"
	add_child(environment_player)
	_apply_music()
	_apply_effects()
	_apply_environment()

func _save_settings():
	settings.set_value("audio", "music_enabled", music_enabled)
	settings.set_value("audio", "effects_enabled", effects_enabled)
	settings.set_value("audio", "environment_enabled", environment_enabled)
	settings.set_value("audio", "music_volume", music_volume)
	settings.set_value("audio", "effects_volume", effects_volume)
	settings.set_value("audio", "environment_volume", environment_volume)
	settings.set_value("audio", "environment_mode", environment_mode)
	settings.save(SETTINGS_PATH)

func is_music_enabled():
	return music_enabled

func is_effects_enabled():
	return effects_enabled

func is_environment_enabled():
	return environment_enabled

func get_music_volume():
	return music_volume

func get_effects_volume():
	return effects_volume

func get_environment_volume():
	return environment_volume

func get_environment_mode():
	return environment_mode

func set_music_enabled(value):
	music_enabled = bool(value)
	_save_settings()
	_apply_music()

func set_effects_enabled(value):
	effects_enabled = bool(value)
	_save_settings()
	_apply_effects()

func set_environment_enabled(value):
	environment_enabled = bool(value)
	_save_settings()
	_apply_environment()

func set_music_volume(value):
	music_volume = clamp(float(value), 0.0, 1.0)
	_save_settings()
	_apply_music()

func set_effects_volume(value):
	effects_volume = clamp(float(value), 0.0, 1.0)
	_save_settings()
	_apply_effects()

func set_environment_volume(value):
	environment_volume = clamp(float(value), 0.0, 1.0)
	_save_settings()
	_apply_environment()

func set_environment_mode(value):
	var requested = str(value)
	if not requested in ["city", "rain", "nature", "traffic"]:
		requested = "city"
	environment_mode = requested
	_save_settings()
	_apply_environment(true)

func set_night_mode(value):
	var next_mode = bool(value)
	if night_mode == next_mode:
		return
	night_mode = next_mode
	if music_enabled:
		_apply_music(true)
	if environment_enabled:
		_apply_environment(true)

func _apply_music(force_restart=false):
	if music_player == null:
		return
	if not music_enabled or music_volume <= 0.001:
		music_player.stop()
		return
	music_player.volume_db = linear2db(max(0.001, music_volume))
	if force_restart or music_player.stream == null:
		music_player.stream = _make_ambient_music(night_mode)
	if not music_player.playing:
		music_player.play()

func _apply_effects():
	for voice in effects_players:
		if voice != null:
			voice.volume_db = linear2db(max(0.001, effects_volume))

func _apply_environment(force_restart=false):
	if environment_player == null:
		return
	if not environment_enabled or environment_volume <= 0.001:
		environment_player.stop()
		return
	environment_player.volume_db = linear2db(max(0.001, environment_volume))
	if force_restart or environment_player.stream == null:
		environment_player.stream = _make_environment_stream(environment_mode, night_mode)
	if not environment_player.playing:
		environment_player.play()

func play_sfx(kind="click"):
	# Browser exports may block autoplay until the first user gesture; resume ambience on interaction.
	if music_enabled and music_player != null and not music_player.playing:
		_apply_music()
	if environment_enabled and environment_player != null and not environment_player.playing:
		_apply_environment()
	if not effects_enabled or effects_volume <= 0.001 or effects_players.empty():
		return
	var selected_player = null
	for voice in effects_players:
		if not voice.playing:
			selected_player = voice
			break
	if selected_player == null:
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
		"warning":
			tones = [[880.0, 0.0, 0.18], [660.0, 0.24, 0.22], [880.0, 0.52, 0.20]]
		"siren":
			tones = [[660.0, 0.0, 0.32], [880.0, 0.32, 0.32], [660.0, 0.64, 0.32], [880.0, 0.96, 0.32], [660.0, 1.28, 0.32]]
		"rain":
			tones = [[523.25, 0.0, 0.20], [587.33, 0.22, 0.20], [523.25, 0.44, 0.28]]
		"water":
			tones = [[392.0, 0.0, 0.22], [493.88, 0.20, 0.22], [587.33, 0.40, 0.32]]
		"birds":
			tones = [[1568.0, 0.0, 0.08], [1975.5, 0.12, 0.10], [1760.0, 0.28, 0.08], [2093.0, 0.43, 0.12]]
		"traffic":
			tones = [[110.0, 0.0, 0.35], [146.83, 0.30, 0.35], [123.47, 0.62, 0.40]]
		_:
			tones = [[880.0, 0.0, 0.055], [1174.66, 0.025, 0.075]]
	selected_player.stream = _make_tone_stream(tones, 0.72)
	selected_player.play()

func _make_environment_stream(mode, is_night):
	var duration = 6.0
	var sample_count = int(SAMPLE_RATE * duration)
	var bytes = PoolByteArray()
	bytes.resize(sample_count * 2)
	for i in range(sample_count):
		var t = float(i) / float(SAMPLE_RATE)
		var sample = 0.0
		if mode == "rain":
			var noise = sin(t * 1731.0) * sin(t * 997.0) + sin(t * 2711.0) * 0.45 + sin(t * 419.0) * 0.35
			sample += noise * 0.075
			sample += sin(2.0 * PI * 92.0 * t) * 0.025
		elif mode == "nature":
			sample += sin(2.0 * PI * 190.0 * t) * 0.035
			sample += sin(2.0 * PI * 247.0 * t) * 0.025
			var chirp_phase = fposmod(t, 2.4)
			if chirp_phase < 0.18:
				sample += sin(2.0 * PI * (1450.0 + chirp_phase * 1700.0) * t) * (0.10 * (1.0 - chirp_phase / 0.18))
			if chirp_phase > 0.30 and chirp_phase < 0.43:
				sample += sin(2.0 * PI * 1850.0 * t) * 0.07
		elif mode == "traffic":
			var passing = 0.5 + 0.5 * sin(2.0 * PI * t / 5.5)
			sample += sin(2.0 * PI * 72.0 * t) * 0.07 * passing
			sample += sin(2.0 * PI * 103.0 * t) * 0.035 * passing
			sample += sin(2.0 * PI * 180.0 * t) * 0.012
		else:
			sample += sin(2.0 * PI * 130.81 * t) * 0.018
			sample += sin(2.0 * PI * 164.81 * t) * 0.012
			sample += sin(2.0 * PI * 196.0 * t) * 0.010
			if is_night:
				sample += sin(2.0 * PI * 82.41 * t) * 0.018
		var edge = min(1.0, t / 0.12) * min(1.0, (duration - t) / 0.12)
		var value = int(clamp(sample * edge * 5200.0, -32767.0, 32767.0))
		bytes[i * 2] = value & 0xff
		bytes[i * 2 + 1] = (value >> 8) & 0xff
	var stream = AudioStreamSample.new()
	stream.format = AudioStreamSample.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamSample.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = bytes
	return stream

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
	var stream = AudioStreamSample.new()
	stream.format = AudioStreamSample.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamSample.LOOP_FORWARD
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
	var stream = AudioStreamSample.new()
	stream.format = AudioStreamSample.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
