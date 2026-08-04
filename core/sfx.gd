class_name PocketSfx
extends RefCounted


static func play(parent: Node, frequency: float, duration: float = 0.10, volume_db: float = -12.0, slide: float = 0.0) -> void:
	if not is_instance_valid(parent) or OS.has_feature("server"):
		return
	var sample_rate := 22050
	var frame_count := maxi(1, int(duration * sample_rate))
	var data := PackedByteArray()
	data.resize(frame_count)
	var phase := 0.0
	for index in frame_count:
		var progress := float(index) / float(frame_count)
		var current_frequency := frequency + slide * progress
		phase += TAU * current_frequency / float(sample_rate)
		var envelope := minf(1.0, progress * 18.0) * pow(1.0 - progress, 1.8)
		var sample := sin(phase) * envelope
		data[index] = clampi(int(128.0 + sample * 105.0), 0, 255)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	var audio := AudioStreamPlayer.new()
	audio.stream = stream
	audio.volume_db = volume_db
	parent.add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()

