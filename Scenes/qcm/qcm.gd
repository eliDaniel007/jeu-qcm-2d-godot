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

var questions = []
var question_index = 0
var temps_restant = DUREE
var timer_actif = false
var start_time = 0.0
var player = null
var pret_a_lancer = false

func _ready():
	player = get_tree().current_scene.get_node("character")
	if player:
		player.set_controle_manuel(false)  # Désactiver le contrôle manuel au démarrage
	charger_questions()
	if questions.size() == 0:
		question_label.text = "Aucune question trouvée !"
		timer_label.text = ""
		return
	questions.shuffle()
	for bouton in buttons:
		bouton.pressed.connect(_on_button_pressed.bind(bouton))
	# Connecter le bouton Go
	if has_node("OverlayNoir/BoutonGo"):
		$OverlayNoir/BoutonGo.pressed.connect(_on_bouton_go_pressed)
	afficher_question()
	# Ne pas démarrer immédiatement. Affichage contrôlé par bouton Go.
	pret_a_lancer = false
	_afficher_overlay(true)

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
	var q = questions[question_index]
	question_label.text = q["question"]
	for i in range(buttons.size()):
		buttons[i].text = q["reponses"][i]

func demarrer_timer():
	temps_restant = DUREE
	timer_label.text = "Temps restant : %d s" % temps_restant
	timer_actif = true
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
		temps_restant = int(DUREE - elapsed)
		if temps_restant < 0:
			temps_restant = 0
			timer_actif = false
			_fin_du_temps()
		timer_label.text = "Temps restant : %d s" % temps_restant

func _on_button_pressed(bouton):
	if not timer_actif:
		return
	timer_actif = false
	var temps_reaction = (Time.get_ticks_msec() / 1000.0) - start_time
	var deplacement = DUREE - temps_reaction
	var q = questions[question_index]
	var bonne = (bouton == buttons[q["bonne_reponse"]])
	print("Réponse choisie : %s" % bouton.text)
	print("Bonne réponse ? %s" % bonne)
	print("Temps de réaction : %f secondes" % temps_reaction)
	print("Déplacement calculé : %f" % deplacement)
	if bonne:
		var path_manager = get_tree().current_scene.get_node("path_manager")
		if path_manager:
			print("Path manager trouvé, appel de deplacer_joueur")
			# Multi: si un joueur cible est défini, le définir actif sur le path_manager
			if joueur_cible:
				if path_manager.has_method("set_joueur_actif"):
					path_manager.set_joueur_actif(joueur_cible)
			path_manager.deplacer_joueur(deplacement)
		else:
			print("ERREUR: Path manager non trouvé !")
		timer_label.text = "Bonne réponse !"
	else:
		timer_label.text = "Mauvaise réponse !"
	# Attendre un court instant pour laisser lire le feedback, puis afficher Go sans démarrer
	await get_tree().create_timer(1.0).timeout
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
		if player:
			player.set_controle_manuel(true)  # Réactiver le contrôle manuel à la fin du QCM

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
		if player:
			player.set_controle_manuel(true)  # Réactiver le contrôle manuel à la fin du QCM

func _on_reponse_validee():
	emit_signal("qcm_termine")
	visible = false
	if player:
		player.set_controle_manuel(true)  # Réactiver le contrôle manuel

func _on_Timer_timeout():
	emit_signal("qcm_termine")
	visible = false
	if player:
		player.set_controle_manuel(true)  # Réactiver le contrôle manuel

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
		demarrer_tour()

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
	if player:
		player.set_controle_manuel(false)
