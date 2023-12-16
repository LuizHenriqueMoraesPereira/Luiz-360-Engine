extends Node

func _ready() -> void:
	for i in 48:
		var audio_channel = preload("res://Objects/audio.tscn").instance()
		audio_channel.name = "Audio Channel " + var2str(i)
		add_child(audio_channel)

func _play_sample(sample : AudioStream) -> void:
	for i in get_child_count():
		var channel = get_child(i)
		if channel.stream != null:
			continue
		else:
			channel.stream = sample
			channel.play()
			break

func _stop_sample(sample : AudioStream) -> void:
	for i in get_child_count():
		var channel = get_child(i)
		if channel.stream == sample:
			channel.stop()
			channel.stream = null
			channel.pitch_scale = 1
			break

func _set_sample_pitch(sample : AudioStream, scale : float) -> void:
	for i in get_child_count():
		var channel = get_child(i)
		if channel.stream == sample:
			channel.pitch_scale = scale
			break
