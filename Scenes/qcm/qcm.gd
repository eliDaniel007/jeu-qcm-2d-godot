extends Control

signal qcm_termine
signal tour_termine

# UI Design: Adaptation multi-joueurs: accepter un joueur cible et un nom pour tours
@export var nom_joueur_actif: String = ""
var joueur_cible: Node = null

const DUREE = 15

@onready var timer_label = $BackgroundPanel/TimerLabel
@onready var question_label = $BackgroundPanel/QuestionLabel
@onready var vbox = $BackgroundPanel/VBoxContainer
@onready var buttons = vbox.get_children().filter(func(n): return n is Button)
@onready var background_panel = $BackgroundPanel

# Barre de progression du timer (créée dynamiquement si absente).
var timer_bar: ProgressBar = null
# StyleBoxes conservés pour pouvoir les restaurer entre deux questions.
var _style_bouton_normal: Dictionary = {}

var questions = []
var question_index = 0
var temps_restant = DUREE
var timer_actif = false
var start_time = 0.0
var player = null
var pret_a_lancer = false
var _dernier_tic_seconde: int = -1

func _ready():
	# En multi-tours, joueur_cible est défini par qcm_multiplayer AVANT chaque tour.
	# En solo, on retombe sur le nœud "character" de la scène.
	player = get_tree().current_scene.get_node_or_null("character")
	var cible = _joueur_actif()
	if cible:
		cible.set_controle_manuel(false)
	charger_questions()
	if questions.size() == 0:
		question_label.text = "Aucune question trouvée !"
		timer_label.text = ""
		return
	questions.shuffle()
	_appliquer_theme_qcm()
	_creer_barre_timer()
	for bouton in buttons:
		bouton.pressed.connect(_on_button_pressed.bind(bouton))
	# Connecter le bouton Go
	if has_node("OverlayNoir/BoutonGo"):
		$OverlayNoir/BoutonGo.pressed.connect(_on_bouton_go_pressed)
	afficher_question()
	# Ne pas démarrer immédiatement. Affichage contrôlé par bouton Go.
	pret_a_lancer = false
	_afficher_overlay(true)

func _appliquer_theme_qcm() -> void:
	# Style uniforme pour les 4 boutons de réponse.
	for b in buttons:
		UITheme.appliquer_bouton(b, UITheme.COULEUR_FOND_CLAIR)
		b.add_theme_font_size_override("font_size", 20)
		# Grille 2×2: largeur étirée par la grille, hauteur fixe.
		b.custom_minimum_size = Vector2(400, 76)
		b.clip_text = true
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Bouton Go
	var go = get_node_or_null("OverlayNoir/BoutonGo")
	if go:
		UITheme.appliquer_bouton(go, UITheme.COULEUR_SUCCES)
	# Couleur du timer label
	if timer_label:
		timer_label.add_theme_color_override("font_color", UITheme.COULEUR_TEXTE)
	# Titre de la question
	if question_label:
		question_label.add_theme_color_override("font_color", UITheme.COULEUR_TEXTE)

func _creer_barre_timer() -> void:
	# Barre de progression horizontale au-dessus du label timer.
	if timer_bar and is_instance_valid(timer_bar):
		return
	timer_bar = ProgressBar.new()
	timer_bar.name = "TimerBar"
	timer_bar.min_value = 0.0
	timer_bar.max_value = 1.0
	timer_bar.value = 1.0
	timer_bar.show_percentage = false
	timer_bar.custom_minimum_size = Vector2(780, 10)
	# Positionner juste au-dessus du TimerLabel dans le panel compact.
	timer_bar.anchor_left = 0.5
	timer_bar.anchor_right = 0.5
	timer_bar.offset_left = -390
	timer_bar.offset_right = 390
	timer_bar.offset_top = 240
	timer_bar.offset_bottom = 252
	# Style de la barre
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.14, 0.18)
	bg.corner_radius_top_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_bottom_right = 4
	var fill = StyleBoxFlat.new()
	fill.bg_color = UITheme.COULEUR_SUCCES
	fill.corner_radius_top_left = 4
	fill.corner_radius_top_right = 4
	fill.corner_radius_bottom_left = 4
	fill.corner_radius_bottom_right = 4
	timer_bar.add_theme_stylebox_override("background", bg)
	timer_bar.add_theme_stylebox_override("fill", fill)
	background_panel.add_child(timer_bar)

func charger_questions():
	var file = FileAccess.open("res://data/questions.json", FileAccess.READ)
	if file:
		var data = file.get_as_text()
		questions = JSON.parse_string(data)
		file.close()
		print("Nombre de questions chargées :", questions.size())
	else:
		print("Impossible d'ouvrir le fichier de questions !")

func afficher_question():
	var q: Dictionary = questions[question_index]
	question_label.text = q["question"]
	for i in range(buttons.size()):
		buttons[i].text = q["reponses"][i]
		# Reset style neutre + échelle après un éventuel feedback (shake/pulse).
		UITheme.appliquer_bouton(buttons[i], UITheme.COULEUR_FOND_CLAIR)
		buttons[i].scale = Vector2.ONE

func demarrer_timer():
	temps_restant = DUREE
	timer_label.text = "Temps restant : %d s" % temps_restant
	timer_actif = true
	_dernier_tic_seconde = -1
	start_time = Time.get_ticks_msec() / 1000.0

func preparer_tour():
	# Afficher overlay noir et bouton Go, masquer les réponses jusqu'au clic
	pret_a_lancer = false
	_afficher_overlay(true)
	_set_reponses_interactives(false)
	# Afficher le nom du joueur actif si disponible
	if has_node("OverlayNoir/EtiquetteTour"):
		var txt = "Préparez-vous"
		if nom_joueur_actif != "":
			txt = "À toi de jouer, %s !" % nom_joueur_actif
		$OverlayNoir/EtiquetteTour.text = txt
	# Réinitialiser affichages
	timer_actif = false
	timer_label.text = ""

func demarrer_tour():
	pret_a_lancer = true
	_afficher_overlay(false)
	_set_reponses_interactives(true)
	demarrer_timer()

func _process(delta):
	if timer_actif:
		var elapsed = (Time.get_ticks_msec() / 1000.0) - start_time
		var reste = DUREE - elapsed
		temps_restant = int(max(reste, 0.0))
		if reste <= 0.0:
			timer_actif = false
			_fin_du_temps()
		timer_label.text = "Temps restant : %d s" % temps_restant
		# Tic sonore dans les 5 dernières secondes (une fois par seconde)
		if temps_restant <= 5 and temps_restant > 0 and temps_restant != _dernier_tic_seconde:
			_dernier_tic_seconde = temps_restant
			_jouer_son("tic")
		# Alimenter la barre (1.0 → 0.0) + changement de couleur selon urgence
		if timer_bar and is_instance_valid(timer_bar):
			var ratio = clamp(reste / float(DUREE), 0.0, 1.0)
			timer_bar.value = ratio
			var fill: StyleBoxFlat = timer_bar.get_theme_stylebox("fill")
			if fill:
				if ratio > 0.5:
					fill.bg_color = UITheme.COULEUR_SUCCES
				elif ratio > 0.25:
					fill.bg_color = UITheme.COULEUR_ACCENT
				else:
					fill.bg_color = UITheme.COULEUR_DANGER

func _on_button_pressed(bouton):
	if not timer_actif:
		return
	timer_actif = false
	var temps_reaction = (Time.get_ticks_msec() / 1000.0) - start_time
	var deplacement = DUREE - temps_reaction
	var q: Dictionary = questions[question_index]
	var bouton_bonne_reponse: Button = buttons[q["bonne_reponse"]]
	var bonne: bool = (bouton == bouton_bonne_reponse)
	print("Réponse choisie : %s" % bouton.text)
	print("Bonne réponse ? %s" % bonne)
	print("Temps de réaction : %f secondes" % temps_reaction)
	print("Déplacement calculé : %f" % deplacement)

	# Feedback visuel immédiat sur les boutons de réponse
	_set_reponses_interactives(false)
	_feedback_visuel_reponse(bouton, bouton_bonne_reponse, bonne)

	_jouer_son("bonne" if bonne else "mauvaise")
	if bonne:
		var path_manager = get_tree().current_scene.get_node("path_manager")
		if path_manager:
			print("Path manager trouvé, appel de deplacer_joueur")
			if joueur_cible:
				if path_manager.has_method("set_joueur_actif"):
					path_manager.set_joueur_actif(joueur_cible)
			path_manager.deplacer_joueur(deplacement)
		else:
			print("ERREUR: Path manager non trouvé !")
		timer_label.text = "✅ Bonne réponse !"
		timer_label.add_theme_color_override("font_color", UITheme.COULEUR_SUCCES)
	else:
		timer_label.text = "❌ Mauvaise réponse — la bonne : %s" % bouton_bonne_reponse.text
		timer_label.add_theme_color_override("font_color", UITheme.COULEUR_DANGER)
	# Laisser plus de temps pour lire la bonne réponse quand on s'est trompé
	var attente = 1.2 if bonne else 1.8
	await get_tree().create_timer(attente).timeout
	# Restaurer la couleur neutre du label pour le tour suivant
	timer_label.add_theme_color_override("font_color", UITheme.COULEUR_TEXTE)
	# Préparer l'écran pour la prochaine itération: overlay Go immédiatement
	question_index += 1
	if question_index < questions.size():
		afficher_question()
		pret_a_lancer = false
		_set_reponses_interactives(false)
		emit_signal("tour_termine")
		_afficher_overlay(true)
	else:
		question_label.text = "QCM terminé !"
		timer_label.text = ""
		emit_signal("qcm_termine")
		visible = false
		var cible_fin = _joueur_actif()
		if cible_fin:
			cible_fin.set_controle_manuel(true)  # Réactiver le contrôle manuel à la fin du QCM

func _fin_du_temps():
	print("Temps écoulé !")
	timer_label.text = "Temps écoulé !"
	await get_tree().create_timer(1.2).timeout
	# Préparer l'écran pour la prochaine itération: overlay Go immédiatement
	question_index += 1
	if question_index < questions.size():
		afficher_question()
		pret_a_lancer = false
		_set_reponses_interactives(false)
		emit_signal("tour_termine")
		_afficher_overlay(true)
	else:
		question_label.text = "QCM terminé !"
		timer_label.text = ""
		emit_signal("qcm_termine")
		visible = false
		var cible_fin = _joueur_actif()
		if cible_fin:
			cible_fin.set_controle_manuel(true)  # Réactiver le contrôle manuel à la fin du QCM

func _on_reponse_validee():
	emit_signal("qcm_termine")
	visible = false
	var cible_rea = _joueur_actif()
	if cible_rea:
		cible_rea.set_controle_manuel(true)  # Réactiver le contrôle manuel

func _on_Timer_timeout():
	emit_signal("qcm_termine")
	visible = false
	var cible_rea = _joueur_actif()
	if cible_rea:
		cible_rea.set_controle_manuel(true)  # Réactiver le contrôle manuel

# Helpers UI
func _afficher_overlay(afficher: bool) -> void:
	var overlay = $OverlayNoir
	var bouton_go = $OverlayNoir/BoutonGo
	var panneau = $BackgroundPanel
	if overlay:
		overlay.visible = afficher
	if bouton_go:
		bouton_go.visible = afficher
	if panneau:
		panneau.visible = not afficher

func _set_reponses_interactives(actif: bool) -> void:
	for bouton in buttons:
		bouton.disabled = not actif

func _on_bouton_go_pressed() -> void:
	if not pret_a_lancer:
		_jouer_son("go")
		demarrer_tour()

func _jouer_son(nom: String) -> void:
	var root = get_tree().root
	if root.has_node("SoundManager"):
		root.get_node("SoundManager").jouer(nom)

# Réinitialisation complète du QCM pour recommencer à zéro
func reinitialiser() -> void:
	# Réinitialiser l'état interne
	timer_actif = false
	pret_a_lancer = false
	question_index = 0
	temps_restant = DUREE
	# UI: remettre l'overlay Go et désactiver les réponses
	_afficher_overlay(true)
	_set_reponses_interactives(false)
	# Recharger et remettre une première question
	charger_questions()
	if questions.size() > 0:
		questions.shuffle()
		afficher_question()
	# Cacher le QCM tant que la partie n'est pas relancée
	visible = false
	# Désactiver le contrôle manuel du joueur pendant le QCM
	var cible_reset = _joueur_actif()
	if cible_reset:
		cible_reset.set_controle_manuel(false)

# Retourne le joueur cible (défini par qcm_multiplayer) ou, à défaut, le joueur solo.
func _joueur_actif() -> Node:
	if joueur_cible and is_instance_valid(joueur_cible):
		return joueur_cible
	return player

# Feedback visuel sur les boutons après clic:
# - le bouton choisi devient vert (bon) ou rouge (mauvais avec shake)
# - si mauvaise réponse, le bon bouton pulse en vert pour le montrer
# - après un court délai, tous les boutons reprennent le style normal
func _feedback_visuel_reponse(bouton_choisi: Button, bouton_bonne: Button, bonne: bool) -> void:
	var couleur_bonne = UITheme.COULEUR_SUCCES
	var couleur_mauvaise = UITheme.COULEUR_DANGER

	UITheme.appliquer_bouton(bouton_choisi, couleur_bonne if bonne else couleur_mauvaise)

	if bonne:
		# Pulse du bouton choisi
		bouton_choisi.pivot_offset = bouton_choisi.size / 2.0
		var tw := bouton_choisi.create_tween()
		tw.tween_property(bouton_choisi, "scale", Vector2(1.1, 1.1), 0.15) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(bouton_choisi, "scale", Vector2(1.0, 1.0), 0.2) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		# Shake horizontal du mauvais bouton
		var pos_base = bouton_choisi.position
		var tw := bouton_choisi.create_tween()
		for amp in [12, -10, 8, -6, 4, -2, 0]:
			tw.tween_property(bouton_choisi, "position", pos_base + Vector2(amp, 0), 0.05) \
				.set_trans(Tween.TRANS_SINE)
		# Révéler la bonne réponse en vert avec pulse
		UITheme.appliquer_bouton(bouton_bonne, couleur_bonne)
		bouton_bonne.pivot_offset = bouton_bonne.size / 2.0
		var tw2 := bouton_bonne.create_tween()
		tw2.set_loops(2)
		tw2.tween_property(bouton_bonne, "scale", Vector2(1.08, 1.08), 0.2) \
			.set_trans(Tween.TRANS_SINE)
		tw2.tween_property(bouton_bonne, "scale", Vector2(1.0, 1.0), 0.2) \
			.set_trans(Tween.TRANS_SINE)
