extends Node
## Suara placeholder yang dibuat dari rumus saat game dibuka.
## Diganti file ElevenLabs dari audio/audio-list.md di tahap suara (vertical-slice.md tahap 7).

const RATE := 22050
const VOICES := 8

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _noise := PackedFloat32Array()


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	_noise.resize(RATE)
	for i in RATE:
		_noise[i] = rng.randf_range(-1.0, 1.0)
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.volume_db = -8.0
		add_child(p)
		_players.append(p)

	_streams[&"hit_light"] = _make(0.14, func(t, i): return _n(i) * exp(-t * 45.0) * 0.6 + sin(TAU * 190.0 * t) * exp(-t * 30.0) * 0.7)
	_streams[&"hit_heavy"] = _make(0.32, func(t, i): return _n(i) * exp(-t * 20.0) * 0.7 + sin(TAU * (95.0 - 60.0 * t) * t) * exp(-t * 12.0) * 0.9)
	_streams[&"block"] = _make(0.12, func(t, i): return sin(TAU * 880.0 * t) * exp(-t * 38.0) * 0.4 + _n(i) * exp(-t * 70.0) * 0.3)
	_streams[&"whoosh"] = _make(0.13, func(t, i): return _soft(i) * sin(PI * t / 0.13) * 0.35)
	_streams[&"whoosh_heavy"] = _make(0.22, func(t, i): return _soft(i * 2 / 3) * sin(PI * t / 0.22) * 0.45)
	_streams[&"ko"] = _make(0.9, func(t, i): return sin(TAU * (130.0 - 70.0 * t) * t) * exp(-t * 4.0) * 0.9 + _n(i) * exp(-t * 9.0) * 0.5)
	_streams[&"land"] = _make(0.08, func(t, i): return sin(TAU * 110.0 * t) * exp(-t * 40.0) * 0.5)
	_streams[&"land_heavy"] = _make(0.18, func(t, i): return sin(TAU * 70.0 * t) * exp(-t * 18.0) * 0.8 + _n(i) * exp(-t * 40.0) * 0.3)
	_streams[&"dash"] = _make(0.1, func(t, i): return _soft(i) * exp(-t * 25.0) * 0.3)
	_streams[&"jump"] = _make(0.08, func(t, i): return sin(TAU * (300.0 + 900.0 * t) * t) * exp(-t * 25.0) * 0.2)
	_streams[&"teleport"] = _make(0.16, func(t, i): return sin(TAU * (1400.0 - 5000.0 * t) * t) * exp(-t * 14.0) * 0.35)
	_streams[&"catch"] = _make(0.05, func(t, i): return sin(TAU * 600.0 * t) * exp(-t * 60.0) * 0.3)
	_streams[&"ultimate"] = _make(0.6, func(t, i): return sin(TAU * (180.0 + 700.0 * t) * t) * minf(t * 8.0, 1.0) * 0.4 + _n(i) * t * 0.25)
	_streams[&"ultimate_hit"] = _make(0.45, func(t, i): return _n(i * 3) * exp(-t * 9.0) * 0.6 + sin(TAU * 2400.0 * t) * exp(-t * 30.0) * 0.3)
	_streams[&"star5"] = _make(0.4, func(t, i): return sin(TAU * (1320.0 if t < 0.12 else 1760.0) * t) * exp(-fmod(t, 0.12) * 9.0) * 0.3)
	_streams[&"energy_full"] = _make(0.22, func(t, i): return sin(TAU * (660.0 if t < 0.1 else 990.0) * t) * exp(-fmod(t, 0.1) * 14.0) * 0.3)
	_streams[&"round"] = _make(0.25, func(t, i): return sin(TAU * 440.0 * t) * exp(-t * 9.0) * 0.35)
	_streams[&"fight"] = _make(0.35, func(t, i): return sin(TAU * 660.0 * t) * exp(-t * 7.0) * 0.4 + sin(TAU * 990.0 * t) * exp(-t * 7.0) * 0.2)
	_streams[&"time_up"] = _make(0.5, func(t, i): return sin(TAU * 330.0 * t) * exp(-t * 4.0) * 0.4)
	_streams[&"match_end"] = _make(0.5, func(t, i): return sin(TAU * (520.0 if t < 0.2 else 780.0) * t) * exp(-fmod(t, 0.2) * 6.0) * 0.35)


func play(event: StringName) -> void:
	var stream: AudioStream = _streams.get(event)
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = stream
	p.play()


func _n(i: int) -> float:
	return _noise[i % RATE]


## Derau yang dihaluskan, untuk suara ayunan.
func _soft(i: int) -> float:
	var s := 0.0
	for k in 8:
		s += _noise[(i + k) % RATE]
	return s / 4.0


func _make(duration: float, fn: Callable) -> AudioStreamWAV:
	var n := int(RATE * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var v: float = clampf(fn.call(float(i) / RATE, i), -1.0, 1.0)
		# Redam ujung supaya tidak berbunyi klik.
		v *= minf(1.0, float(n - i) / 200.0)
		data.encode_s16(i * 2, int(v * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	return s
