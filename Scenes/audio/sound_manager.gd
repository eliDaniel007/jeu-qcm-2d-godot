extends Node

# Gestionnaire audio centralisé. Génère tous les sons procéduralement
# (aucun asset externe requis). Exposé en autoload sous le nom "SoundManager".
#
# API:
#   SoundManager.jouer("bonus")    # Son unique
#   SoundManager.demarrer_ambiance()
#   SoundManager.arreter_ambiance()

const FREQ_ECHANTILLONNAGE := 22050

var _lecteurs: Array[AudioStreamPlayer] = []
var _ambiance_player: AudioStreamPlayer = null
var _cache: Dictionary = {}
var _volume_effets_db: float = -4.0
var _volume_ambiance_db: float = -18.0
var _mute: bool = false

func _ready() -> void:
	# Pool de 6 lecteurs pour pouvoir empiler plusieurs sons simultanés.
	for i in range(6):
		var p := AudioStreamPlayer.new()
		p.volume_db = _volume_effets_db
		add_child(p)
		_lecteurs.append(p)
	_ambiance_player = AudioStreamPlayer.new()
	_ambiance_player.volume_db = _volume_ambiance_db
	add_child(_ambiance_player)
	_prechauffer_cache()

func _prechauffer_cache() -> void:
	# Pré-générer les sons courants pour éviter les micro-saccades.
	for nom in ["click", "bonus", "piege", "teleport", "victoire", "go", "bonne", "mauvaise", "tic", "alerte", "whoosh", "saut", "pop"]:
		_obtenir_son(nom)

func jouer(nom: String, volume_db: float = 0.0) -> void:
	if _mute:
		return
	var stream := _obtenir_son(nom)
	if stream == null:
		return
	var p := _lecteur_libre()
	if p == null:
		return
	p.stream = stream
	p.volume_db = _volume_effets_db + volume_db
	p.play()

func demarrer_ambiance() -> void:
	# Désactivé: pas de nappe de fond bruyante. On garde uniquement les sons d'évènements.
	return

func arreter_ambiance() -> void:
	if _ambiance_player and _ambiance_player.playing:
		_ambiance_player.stop()

func basculer_mute() -> bool:
	_mute = not _mute
	if _mute:
		arreter_ambiance()
	return _mute

func _lecteur_libre() -> AudioStreamPlayer:
	for p in _lecteurs:
		if not p.playing:
			return p
	# Aucun libre: écraser le premier.
	return _lecteurs[0]

func _obtenir_son(nom: String) -> AudioStream:
	if _cache.has(nom):
		return _cache[nom]
	var stream: AudioStream = null
	match nom:
		"click":      stream = _generer_ton(1400.0, 0.05, 0.3, "carre")
		# Bonus cartoon: 5 notes qui montent rapidement (do-mi-sol-do-mi)
		"bonus":      stream = _generer_arpege([523.0, 659.0, 784.0, 1046.0, 1318.0], 0.07, 0.45)
		# Piège: descente "boing" rapide et cartoon
		"piege":      stream = _generer_descente(800.0, 100.0, 0.35, 0.5)
		# Téléport: balayage aigu qui remonte
		"teleport":   stream = _generer_balayage(300.0, 3000.0, 0.25, 0.35, "sinus")
		# Victoire: fanfare 5 notes montantes
		"victoire":   stream = _generer_arpege([523.0, 659.0, 784.0, 1046.0, 1568.0], 0.14, 0.5)
		# Go: 2 notes claquantes
		"go":         stream = _generer_arpege([440.0, 880.0], 0.08, 0.45)
		# Bonne réponse: Ding! cartoon
		"bonne":      stream = _generer_arpege([880.0, 1320.0, 1760.0], 0.08, 0.4)
		# Mauvaise: buzzer descendant
		"mauvaise":   stream = _generer_descente(440.0, 110.0, 0.4, 0.45)
		"tic":        stream = _generer_ton(1200.0, 0.04, 0.2, "sinus")
		# Alerte anticipation: 2 bips aigus
		"alerte":     stream = _generer_arpege([1400.0, 1800.0], 0.06, 0.4)
		# Whoosh pendant le déplacement (balayage descendant bref)
		"whoosh":     stream = _generer_balayage(1500.0, 400.0, 0.18, 0.25, "sinus")
		# Saut cartoon (boing)
		"saut":       stream = _generer_balayage(200.0, 900.0, 0.15, 0.4, "sinus")
		# Collecte douce
		"pop":        stream = _generer_ton(1600.0, 0.08, 0.3, "sinus")
	if stream:
		_cache[nom] = stream
	return stream

# --- Générateurs d'ondes ---

func _generer_ton(freq: float, duree: float, volume: float, forme: String = "sinus") -> AudioStreamWAV:
	var n := int(duree * FREQ_ECHANTILLONNAGE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / FREQ_ECHANTILLONNAGE
		var s := _echantillon(forme, freq, t) * volume * _enveloppe(t, duree)
		_ecrire_s16(data, i, s)
	return _creer_stream(data)

func _generer_arpege(frequences: Array, duree_note: float, volume: float) -> AudioStreamWAV:
	var duree_totale := duree_note * frequences.size()
	var n := int(duree_totale * FREQ_ECHANTILLONNAGE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / FREQ_ECHANTILLONNAGE
		var idx := int(t / duree_note)
		if idx >= frequences.size():
			idx = frequences.size() - 1
		var t_note := t - idx * duree_note
		var s := sin(TAU * frequences[idx] * t_note) * volume * _enveloppe(t_note, duree_note)
		_ecrire_s16(data, i, s)
	return _creer_stream(data)

func _generer_descente(freq_depart: float, freq_fin: float, duree: float, volume: float) -> AudioStreamWAV:
	var n := int(duree * FREQ_ECHANTILLONNAGE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / FREQ_ECHANTILLONNAGE
		var ratio := t / duree
		var freq: float = lerp(freq_depart, freq_fin, ratio)
		phase += TAU * freq / FREQ_ECHANTILLONNAGE
		var s := sin(phase) * volume * _enveloppe(t, duree)
		_ecrire_s16(data, i, s)
	return _creer_stream(data)

func _generer_balayage(freq_depart: float, freq_fin: float, duree: float, volume: float, forme: String) -> AudioStreamWAV:
	var n := int(duree * FREQ_ECHANTILLONNAGE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / FREQ_ECHANTILLONNAGE
		var ratio := t / duree
		var freq: float = lerp(freq_depart, freq_fin, ratio)
		phase += TAU * freq / FREQ_ECHANTILLONNAGE
		var s := 0.0
		if forme == "sinus":
			s = sin(phase)
		else:
			s = sign(sin(phase))
		s *= volume * _enveloppe(t, duree)
		_ecrire_s16(data, i, s)
	return _creer_stream(data)

func _generer_ambiance() -> AudioStreamWAV:
	# Pad doux mélangeant deux sinusoïdes graves + une tierce.
	var duree := 4.0
	var n := int(duree * FREQ_ECHANTILLONNAGE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / FREQ_ECHANTILLONNAGE
		var s := 0.0
		s += sin(TAU * 110.0 * t) * 0.25
		s += sin(TAU * 165.0 * t) * 0.18
		s += sin(TAU * 220.0 * t) * 0.12
		# Modulation lente pour un effet "vivant"
		s *= 0.6 + 0.4 * sin(TAU * 0.12 * t)
		_ecrire_s16(data, i, clamp(s, -1.0, 1.0))
	var stream := _creer_stream(data)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = n
	return stream

func _echantillon(forme: String, freq: float, t: float) -> float:
	var phase := TAU * freq * t
	match forme:
		"sinus":   return sin(phase)
		"carre":   return sign(sin(phase))
		"triangle": return 2.0 * abs(2.0 * (t * freq - floor(t * freq + 0.5))) - 1.0
	return sin(phase)

func _enveloppe(t: float, duree: float) -> float:
	# Attaque/release courte pour éviter les clics.
	var attaque := 0.008
	var relachement: float = max(0.03, duree * 0.35)
	if t < attaque:
		return t / attaque
	if t > duree - relachement:
		return max(0.0, (duree - t) / relachement)
	return 1.0

func _ecrire_s16(buffer: PackedByteArray, index: int, sample: float) -> void:
	var v := int(clamp(sample, -1.0, 1.0) * 32767.0)
	buffer[index * 2]     = v & 0xFF
	buffer[index * 2 + 1] = (v >> 8) & 0xFF

func _creer_stream(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = FREQ_ECHANTILLONNAGE
	stream.stereo = false
	stream.data = data
	return stream
