extends Node

var bus_to_stream: Dictionary[String, AudioStreamPlayer] = {}

func _ready() -> void:
	for i in range(AudioServer.bus_count):
		var bus_name = AudioServer.get_bus_name(i)
		if bus_to_stream.has(bus_name):
			continue
		var audio_stream_player = AudioStreamPlayer.new()
		audio_stream_player.bus = bus_name
		add_child.call_deferred(audio_stream_player)
		bus_to_stream.set(bus_name, audio_stream_player)

func play(bus: String, audio: AudioStream, force: bool = false):
	var audio_stream_player: AudioStreamPlayer = bus_to_stream.get(bus)
	if force:
		audio_stream_player.stop()
	elif audio_stream_player.playing:
		return
	audio_stream_player.stream = audio
	audio_stream_player.play()
	
func stop_all():
	for audio_stream_player in bus_to_stream.values():
		audio_stream_player.stop()
