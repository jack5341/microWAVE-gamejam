extends Node

@export var music_bus_name: StringName = &"Music"
@export var sfx_bus_name: StringName = &"SFX"
@export var initial_sfx_pool_size: int = 12

var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _current_music: AudioStreamPlayer = null
var _next_music: AudioStreamPlayer = null

var _sfx_pool: Array = []

func _ready() -> void:
	# Music players (for crossfading)
	_music_player_a = AudioStreamPlayer.new()
	_music_player_a.bus = str(music_bus_name)
	_music_player_a.volume_db = -80.0
	add_child(_music_player_a)

	_music_player_b = AudioStreamPlayer.new()
	_music_player_b.bus = str(music_bus_name)
	_music_player_b.volume_db = -80.0
	add_child(_music_player_b)

	_current_music = _music_player_a
	_next_music = _music_player_b

	for i in range(initial_sfx_pool_size):
		var p := AudioStreamPlayer.new()
		p.bus = str(sfx_bus_name)
		p.finished.connect(_on_sfx_finished.bind(p))
		add_child(p)
		_sfx_pool.append(p)

func play_music(stream: AudioStream, fade_time: float = 0.75, from_position: float = 0.0) -> void:
	if stream == null:
		return
	var from := _current_music
	var to := _next_music

	to.stop()
	to.stream = stream
	to.volume_db = 0.0 if fade_time <= 0.0 else -80.0
	to.play(from_position)

	if fade_time <= 0.0:
		if from and from.playing:
			from.stop()
		_current_music = to
		_next_music = from
		return

	var tween := create_tween()
	tween.set_parallel(true)
	if from and from.playing:
		tween.tween_property(from, "volume_db", -80.0, fade_time)
	tween.tween_property(to, "volume_db", 0.0, fade_time)
	tween.set_parallel(false)
	tween.tween_callback(func():
		if from and from.playing:
			from.stop()
		_current_music = to
		_next_music = from
	)

func stop_music(fade_time: float = 0.5) -> void:
	if _current_music == null:
		return
	if fade_time <= 0.0:
		_current_music.stop()
		return
	var from := _current_music
	var tween := create_tween()
	tween.tween_property(from, "volume_db", -80.0, fade_time)
	tween.tween_callback(func():
		from.stop()
		from.volume_db = -80.0
	)

func is_music_playing() -> bool:
	return _current_music != null and _current_music.playing

func play_music_from_path(path: String, fade_time: float = 0.75, from_position: float = 0.0) -> void:
	var stream := load(path) as AudioStream
	play_music(stream, fade_time, from_position)

func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return
	var p := _get_free_sfx_player()
	p.stop()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch_scale
	p.play()

func play_sfx_at_position(stream: AudioStream, position: Vector3, volume_db: float = 0.0, pitch_scale: float = 1.0, max_distance: float = 30.0) -> void:
	if stream == null:
		return
	var p3d := AudioStreamPlayer3D.new()
	p3d.bus = str(sfx_bus_name)
	p3d.stream = stream
	p3d.volume_db = volume_db
	p3d.pitch_scale = pitch_scale
	p3d.max_distance = max_distance
	add_child(p3d)
	p3d.global_position = position
	p3d.finished.connect(func():
		if is_instance_valid(p3d):
			p3d.queue_free()
	)
	p3d.play()

func stop_all_sfx() -> void:
	for p in _sfx_pool:
		if p is AudioStreamPlayer and p.playing:
			p.stop()

func set_bus_volume_db(bus_name: StringName, volume_db: float) -> void:
	var idx := AudioServer.get_bus_index(str(bus_name))
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, volume_db)

func get_bus_volume_db(bus_name: StringName) -> float:
	var idx := AudioServer.get_bus_index(str(bus_name))
	if idx >= 0:
		return AudioServer.get_bus_volume_db(idx)
	return 0.0

func set_bus_mute(bus_name: StringName, mute: bool) -> void:
	var idx := AudioServer.get_bus_index(str(bus_name))
	if idx >= 0:
		AudioServer.set_bus_mute(idx, mute)

func is_bus_muted(bus_name: StringName) -> bool:
	var idx := AudioServer.get_bus_index(str(bus_name))
	if idx >= 0:
		return AudioServer.is_bus_mute(idx)
	return false

func pause_all(paused: bool) -> void:
	if _music_player_a:
		_music_player_a.stream_paused = paused
	if _music_player_b:
		_music_player_b.stream_paused = paused
	for p in _sfx_pool:
		if p is AudioStreamPlayer:
			p.stream_paused = paused

func _get_free_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_pool:
		if p is AudioStreamPlayer and not p.playing:
			return p
	var extra := AudioStreamPlayer.new()
	extra.bus = str(sfx_bus_name)
	extra.finished.connect(_on_sfx_finished.bind(extra))
	add_child(extra)
	_sfx_pool.append(extra)
	return extra

func _on_sfx_finished(_player: AudioStreamPlayer) -> void:
	# Intentionally left blank; players remain in the pool for reuse.
	pass
