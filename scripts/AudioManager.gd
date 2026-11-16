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
var _tone_stream_cache: Dictionary = {}
var _music_stream_cache: Dictionary = {}
var _environment_stream_cache: Dictionary = {}
var _music_thread = null
var _environment_thread = null
var _music_thread_mode = ""
var _environment_thread_key = ""
var _pending_music_mode = ""
var _pending_environment_key = ""
var _music_generation_unavailable = false
var _environment_generation_unavailable = false

func _process(_delta):
	_poll_ambience_generation()

func _exit_tree():
	# Join workers during shutdown so no background task outlives this manager.
	if _music_thread != null and _music_thread.is_started():
		_music_thread.wait_to_finish()
	if _environment_thread != null and _environment_thread.is_started():
		_environment_thread.wait_to_finish()

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
	_apply_effects()

func configure_startup_night_mode(value):
	night_mode = bool(value)
	if night_mode:
		environment_mode = "night"
	else:
		environment_mode = _choose_day_environment()


func start_ambience():
	_apply_music()
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
	if night_mode:
		requested = "night"
	elif not requested in ["city", "rain", "nature", "traffic"]:
		requested = "city"
	environment_mode = requested
	_save_settings()
	_apply_environment(true)

func _choose_day_environment():
	var day_modes = ["city", "rain", "nature", "traffic"]
	var choices = day_modes.filter(func(mode): return mode != environment_mode)
	if choices.is_empty():
		choices = day_modes
	return str(choices[randi() % choices.size()])

func set_night_mode(value):
	var next_mode = bool(value)
	var mode_changed = night_mode != next_mode
	night_mode = next_mode
	if next_mode:
		environment_mode = "night"
	else:
		environment_mode = _choose_day_environment()
	_save_settings()
	if music_enabled and (mode_changed or music_player.stream == null):
		_apply_music(true)
	if environment_enabled:
		_apply_environment(true)

func _apply_music(force_restart=false):
	if music_player == null:
		return
	if not music_enabled or music_volume <= 0.001:
		music_player.stop()
		return
	music_player.volume_db = linear_to_db(max(0.001, music_volume))
	if force_restart or music_player.stream == null:
		_request_music_stream("night" if night_mode else "day")
	elif not music_player.playing:
		music_player.play()

func _request_music_stream(mode):
	if _music_generation_unavailable:
		return
	if _music_stream_cache.has(mode):
		music_player.stream = _music_stream_cache[mode]
		if music_enabled and not music_player.playing:
			music_player.play()
		return
	if _music_thread != null and _music_thread.is_started():
		_pending_music_mode = mode
		return
	_music_thread_mode = mode
	_music_thread = Thread.new()
	var err = _music_thread.start(Callable(self, "_generate_ambient_music_data").bind(mode == "night"), Thread.PRIORITY_LOW)
	if err != OK:
		_music_thread = null
		_music_generation_unavailable = true
		push_warning("Ambient music generation unavailable on this platform; skipping background music to keep gameplay responsive.")

func _finish_music_generation(mode, generated):
	if typeof(generated) != TYPE_DICTIONARY or not generated.has("data"):
		return
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = true
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(generated.get("sample_count", 0))
	stream.data = generated.data
	_music_stream_cache[mode] = stream
	var current_mode = "night" if night_mode else "day"
	if mode == current_mode and music_enabled and music_player != null:
		music_player.stream = stream
		if not music_player.playing:
			music_player.play()

func _apply_effects():
	for voice in effects_players:
		if voice != null:
			voice.volume_db = linear_to_db(max(0.001, effects_volume))

func _apply_environment(force_restart=false):
	if environment_player == null:
		return
	if not environment_enabled or environment_volume <= 0.001:
		environment_player.stop()
		return
	environment_player.volume_db = linear_to_db(max(0.001, environment_volume))
	var key = _get_environment_cache_key()
	if force_restart or environment_player.stream == null:
		_request_environment_stream(key)
	elif not environment_player.playing:
		environment_player.play()

func _get_environment_cache_key():
	return "night" if night_mode else "day_" + environment_mode

func _request_environment_stream(key):
	if _environment_generation_unavailable:
		return
	if _environment_stream_cache.has(key):
		environment_player.stream = _environment_stream_cache[key]
		if environment_enabled and not environment_player.playing:
			environment_player.play()
		return
	if _environment_thread != null and _environment_thread.is_started():
		_pending_environment_key = key
		return
	var mode = "night" if key == "night" else key.substr(4)
	var is_night = key == "night"
	_environment_thread_key = key
	_environment_thread = Thread.new()
	var err = _environment_thread.start(Callable(self, "_generate_environment_data").bind(mode, is_night), Thread.PRIORITY_LOW)
	if err != OK:
		_environment_thread = null
		_environment_generation_unavailable = true
		push_warning("Ambient soundscape generation unavailable on this platform; skipping environment audio to keep gameplay responsive.")

func _finish_environment_generation(key, generated):
	if typeof(generated) != TYPE_DICTIONARY or not generated.has("data"):
		return
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(generated.get("sample_count", 0))
	stream.data = generated.data
	_environment_stream_cache[key] = stream
	if key == _get_environment_cache_key() and environment_enabled and environment_player != null:
		environment_player.stream = stream
		if not environment_player.playing:
			environment_player.play()

func _poll_ambience_generation():
	if _music_thread != null and _music_thread.is_started() and not _music_thread.is_alive():
		var mode = _music_thread_mode
		var generated = _music_thread.wait_to_finish()
		_music_thread = null
		_finish_music_generation(mode, generated)
		var pending = _pending_music_mode
		_pending_music_mode = ""
		if pending != "" and not _music_stream_cache.has(pending):
			_request_music_stream(pending)
	if _environment_thread != null and _environment_thread.is_started() and not _environment_thread.is_alive():
		var key = _environment_thread_key
		var generated = _environment_thread.wait_to_finish()
		_environment_thread = null
		_finish_environment_generation(key, generated)
		var pending = _pending_environment_key
		_pending_environment_key = ""
		if pending != "" and not _environment_stream_cache.has(pending):
			_request_environment_stream(pending)

func play_sfx(kind="click"):
	# Browser exports may block autoplay until the first user gesture; resume ambience on interaction.
	if music_enabled and music_player != null and not music_player.playing:
		_apply_music()
	if environment_enabled and environment_player != null and not environment_player.playing:
		_apply_environment()
	if not effects_enabled or effects_volume <= 0.001 or effects_players.is_empty():
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
	var cache_key = str(kind)
	if _tone_stream_cache.has(cache_key):
		selected_player.stream = _tone_stream_cache[cache_key]
	else:
		var tone_stream = _make_tone_stream(tones, 0.72)
		_tone_stream_cache[cache_key] = tone_stream
		selected_player.stream = tone_stream
	selected_player.play()

func _generate_environment_data(mode, is_night):
	var duration = 6.0
	var sample_count = int(SAMPLE_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(sample_count * 2)
	for i in range(sample_count):
		var t = float(i) / float(SAMPLE_RATE)
		var sample = 0.0
		if mode == "night":
			# Quiet nighttime soundscape: crickets, a distant owl-like call, and soft night air.
			var cricket_phase = fposmod(t, 0.42)
			if cricket_phase < 0.055:
				sample += sin(2.0 * PI * 2850.0 * t) * 0.055
			if cricket_phase > 0.12 and cricket_phase < 0.17:
				sample += sin(2.0 * PI * 3150.0 * t) * 0.045
			var owl_phase = fposmod(t, 3.8)
			if owl_phase < 0.55:
				var owl_fade = sin(PI * owl_phase / 0.55)
				sample += sin(2.0 * PI * (520.0 - owl_phase * 150.0) * t) * 0.035 * owl_fade
			sample += sin(2.0 * PI * 68.0 * t) * 0.012
		elif mode == "rain":
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
	return {"data":bytes,"sample_count":sample_count}

func _generate_ambient_music_data(is_night):
	# A gentle, original city theme: warm sustained chords, rounded bass and a
	# lightly played bell-like motif. The 4-bar loop is kept musically smooth.
	var duration = 12.0
	var bar_length = 3.0
	var beat_length = 0.75
	var chords = [
		[130.81, 164.81, 196.00, 246.94], # Cmaj7
		[110.00, 130.81, 164.81, 196.00], # Am7
		[87.31, 110.00, 130.81, 164.81], # Fmaj7
		[98.00, 146.83, 164.81, 220.00]  # Gsus2
	]
	var melody = [
		523.25, 659.25, 783.99, 659.25,
		587.33, 659.25, 880.00, 783.99,
		698.46, 659.25, 587.33, 523.25,
		587.33, 659.25, 783.99, 659.25
	]
	if is_night:
		for chord_index in range(chords.size()):
			for note_index in range(chords[chord_index].size()):
				chords[chord_index][note_index] *= 0.5
		for note_index in range(melody.size()):
			melody[note_index] *= 0.5

	var sample_count = int(SAMPLE_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(sample_count * 4)
	for i in range(sample_count):
		var t = float(i) / float(SAMPLE_RATE)
		var bar_index = int(floor(t / bar_length)) % 4
		var bar_time = fposmod(t, bar_length)
		var next_bar = (bar_index + 1) % 4
		var transition = clamp((bar_time - 2.72) / 0.28, 0.0, 1.0)
		transition = transition * transition * (3.0 - 2.0 * transition)

		var pad = 0.0
		for chord_note in range(4):
			var current_frequency = float(chords[bar_index][chord_note])
			var next_frequency = float(chords[next_bar][chord_note])
			var frequency = lerp(current_frequency, next_frequency, transition)
			var slow_breath = 0.88 + 0.12 * sin(2.0 * PI * t / 7.5)
			var voice = sin(2.0 * PI * frequency * t)
			voice += sin(2.0 * PI * frequency * 2.003 * t) * 0.10
			pad += voice * slow_breath * 0.035

		var beat_index = int(floor(t / beat_length))
		var beat_time = fposmod(t, beat_length)
		var melody_frequency = float(melody[beat_index % melody.size()])
		var pluck_envelope = exp(-beat_time * 5.2) * min(1.0, beat_time / 0.012)
		var pluck = sin(2.0 * PI * melody_frequency * beat_time)
		pluck += sin(2.0 * PI * melody_frequency * 2.01 * beat_time) * 0.28
		pluck += sin(2.0 * PI * melody_frequency * 3.98 * beat_time) * 0.06
		pluck *= pluck_envelope * 0.105

		var bass_frequency = float(chords[bar_index][0]) * 0.5
		var bass_envelope = 0.72 + 0.28 * exp(-bar_time * 1.4)
		var bass = sin(2.0 * PI * bass_frequency * t) * 0.075
		bass += sin(2.0 * PI * bass_frequency * 2.0 * t) * 0.012
		bass *= bass_envelope

		var left = pad + pluck + bass
		var right = pad + pluck * 0.94 + bass * 0.98
		var fade_in = min(1.0, t / 0.18)
		var fade_out = min(1.0, (duration - t) / 0.18)
		var edge = min(fade_in, fade_out)
		var left_value = int(clamp(left * edge * 14500.0, -32767.0, 32767.0))
		var right_value = int(clamp(right * edge * 14500.0, -32767.0, 32767.0))
		var offset = i * 4
		bytes[offset] = left_value & 0xff
		bytes[offset + 1] = (left_value >> 8) & 0xff
		bytes[offset + 2] = right_value & 0xff
		bytes[offset + 3] = (right_value >> 8) & 0xff

	return {"data":bytes,"sample_count":sample_count}

func _make_tone_stream(tones, master_gain):
	var duration = 0.0
	for tone in tones:
		duration = max(duration, float(tone[1]) + float(tone[2]))
	var sample_count = int(ceil((duration + 0.04) * SAMPLE_RATE))
	var bytes = PackedByteArray()
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
				var attack = min(1.0, elapsed / 0.006)
				var decay = exp(-elapsed * (3.2 / max(0.08, length)))
				var envelope = attack * decay
				var fundamental = sin(2.0 * PI * frequency * elapsed)
				var harmonics = sin(2.0 * PI * frequency * 2.0 * elapsed) * 0.16
				mixed += (fundamental + harmonics) * envelope / float(tones.size())
		var sample = int(clamp(mixed * master_gain * 8500.0, -32767.0, 32767.0))
		bytes[i * 2] = sample & 0xff
		bytes[i * 2 + 1] = (sample >> 8) & 0xff
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
