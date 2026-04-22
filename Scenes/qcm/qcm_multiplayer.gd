extends Node

# UI Design: Gestionnaire de partie multi-joueurs en tours

signal tour_change(nom_joueur_actif: String, index_joueur: int)
signal partie_terminee(nom_gagnant: String)

@export var max_joueurs: int = 2 # 2, 3, 4

var liste_joueurs: Array = []    # [ { "nom": String, "noeud": Node2D } ]
var index_joueur_actif: int = 0
var ordre_initial: Array = []    # Garde l'ordre initial fixe
var qcm_ui: Control = null
var path_manager: Node = null
var classement: Array = []    # [ { "nom": String, "noeud": Node2D } ]
var classements_arrivees: Array = []   # ordre d'arrivée effectif
var partie_terminee_bool: bool = false

# Indicateur flottant "▼" au-dessus du joueur actif (visuel multi-local).
var indicateur_actif: Label = null
var indicateur_tween: Tween = null


func _ready():
	path_manager = get_tree().current_scene.get_node("path_manager")
	qcm_ui = get_tree().current_scene.get_node("UILayer/QCM")
	if qcm_ui and qcm_ui.has_signal("qcm_termine"):
		qcm_ui.connect("qcm_termine", Callable(self, "_on_qcm_termine"))
	if qcm_ui and qcm_ui.has_signal("tour_termine"):
		qcm_ui.connect("tour_termine", Callable(self, "_on_tour_termine"))
	if path_manager and path_manager.has_signal("deplacement_termine"):
		path_manager.connect("deplacement_termine", Callable(self, "_on_deplacement_termine"))
	if path_manager and path_manager.has_signal("victoire_atteinte"):
		path_manager.connect("victoire_atteinte", Callable(self, "_on_victoire"))

func configurer_joueurs(noms: Array, scenes_joueurs: Array) -> void:
	# scenes_joueurs: PackedScene ou Node2D déjà instancié
	liste_joueurs.clear()
	for i in range(min(noms.size(), scenes_joueurs.size())):
		var item = { "nom": String(noms[i]), "noeud": scenes_joueurs[i] }
		liste_joueurs.append(item)
	max_joueurs = liste_joueurs.size()
	index_joueur_actif = 0
	classement.clear()
	classements_arrivees.clear()
	partie_terminee_bool = false
	
	# Sauvegarder l'ordre initial pour le répéter
	ordre_initial = liste_joueurs.duplicate()
	
	_annoncer_tour()
	_preparer_qcm_pour_joueur_actif()

func reinitialiser() -> void:
	# Réinitialise l'état pour une nouvelle partie
	_masquer_indicateur()
	_masquer_camera()
	liste_joueurs.clear()
	classement.clear()
	classements_arrivees.clear()
	index_joueur_actif = 0
	partie_terminee_bool = false
	ordre_initial.clear()

func _annoncer_tour():
	if liste_joueurs.is_empty():
		return
	var actif = liste_joueurs[index_joueur_actif]
	emit_signal("tour_change", actif["nom"], index_joueur_actif)
	_mettre_a_jour_indicateur(actif["noeud"])
	_suivre_joueur_camera(actif["noeud"])

func _creer_indicateur() -> void:
	if indicateur_actif and is_instance_valid(indicateur_actif):
		return
	indicateur_actif = Label.new()
	indicateur_actif.text = "▼"
	indicateur_actif.add_theme_font_size_override("font_size", 42)
	indicateur_actif.add_theme_color_override("font_color", Color(1.00, 0.75, 0.25))
	indicateur_actif.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	indicateur_actif.add_theme_constant_override("outline_size", 6)
	indicateur_actif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	indicateur_actif.z_index = 50
	indicateur_actif.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().current_scene.add_child(indicateur_actif)

func _mettre_a_jour_indicateur(joueur: Node) -> void:
	if partie_terminee_bool:
		return
	_creer_indicateur()
	if not is_instance_valid(joueur) or not is_instance_valid(indicateur_actif):
		return
	# Suivre le joueur: reparent sous le joueur pour que la position soit relative
	if indicateur_actif.get_parent() != joueur:
		if indicateur_actif.get_parent():
			indicateur_actif.get_parent().remove_child(indicateur_actif)
		joueur.add_child(indicateur_actif)
	indicateur_actif.position = Vector2(-18, -90)
	indicateur_actif.visible = true
	indicateur_actif.modulate.a = 1.0
	# Animation de rebond continue
	if indicateur_tween and indicateur_tween.is_valid():
		indicateur_tween.kill()
	indicateur_tween = indicateur_actif.create_tween().set_loops()
	indicateur_tween.tween_property(indicateur_actif, "position:y", -78, 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	indicateur_tween.tween_property(indicateur_actif, "position:y", -90, 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _masquer_indicateur() -> void:
	if indicateur_tween and indicateur_tween.is_valid():
		indicateur_tween.kill()
	if indicateur_actif and is_instance_valid(indicateur_actif):
		indicateur_actif.queue_free()
		indicateur_actif = null

func _suivre_joueur_camera(_joueur: Node) -> void:
	pass

func _masquer_camera() -> void:
	pass

func _preparer_qcm_pour_joueur_actif():
	if not qcm_ui or partie_terminee_bool:
		return
	# Sécurité: si pas de joueurs, ne rien faire
	if liste_joueurs.is_empty():
		return
	var actif = liste_joueurs[index_joueur_actif]
	# Passer le joueur cible et le nom au QCM puis préparer le tour (affiche écran noir et bouton Go)
	qcm_ui.joueur_cible = actif["noeud"]
	qcm_ui.nom_joueur_actif = actif["nom"]
	qcm_ui.visible = true
	if qcm_ui.has_method("preparer_tour"):
		qcm_ui.preparer_tour()

func _on_qcm_termine():
	# Le déplacement est déclenché dans le QCM pour le joueur actif.
	pass

func _on_deplacement_termine(joueur_deplace: Node):
	# Ne rien faire ici pour l'alternance: elle est gérée par _on_tour_termine()
	pass

func _on_tour_termine():
	# Fin naturelle d'un tour (question suivante) → passage au joueur suivant selon l'ordre fixe
	if liste_joueurs.size() <= 1 or partie_terminee_bool:
		return
	index_joueur_actif = (index_joueur_actif + 1) % liste_joueurs.size()
	_annoncer_tour()
	_preparer_qcm_pour_joueur_actif()

func _on_victoire(joueur_gagnant: Node):
	if partie_terminee_bool:
		return
	# Enregistrer l'arrivée
	var gagnant_item = null
	for item in liste_joueurs:
		if item["noeud"] == joueur_gagnant:
			gagnant_item = item
			break
	if gagnant_item and not classements_arrivees.any(func(it): it["noeud"] == gagnant_item["noeud"]):
		classements_arrivees.append(gagnant_item)
	# Seuil d'arrêt: nombre de joueurs - 1
	var seuil = max(1, max_joueurs - 1)
	if classements_arrivees.size() >= seuil:
		partie_terminee_bool = true
		_masquer_indicateur()
		_masquer_camera()
		# Masquer le QCM
		if qcm_ui:
			qcm_ui.visible = false
		# Animation collective (sur les arrivés)
		if path_manager and path_manager.has_method("jouer_animation_victoire_collective"):
			var noeuds = []
			for it in classements_arrivees:
				noeuds.append(it["noeud"])
			await path_manager.jouer_animation_victoire_collective(noeuds)
		# Afficher le classement
		var noms_classement: Array = []
		for it in classements_arrivees:
			noms_classement.append(it["nom"])
		await _afficher_classement(noms_classement)
		# Émettre la fin de partie avec le nom du 1er
		if classements_arrivees.size() > 0:
			emit_signal("partie_terminee", classements_arrivees[0]["nom"]) 
	else:
		# Continuer la partie normalement (passage de tour)
		_on_deplacement_termine(joueur_gagnant)

func _afficher_classement(noms_ordonnes: Array) -> void:
	var scene = load("res://Scenes/ui/classement.tscn")
	if scene == null:
		return
	var ui = scene.instantiate()
	var ui_layer = get_tree().current_scene.get_node_or_null("UILayer")
	if ui_layer:
		ui_layer.add_child(ui)
	else:
		get_tree().current_scene.add_child(ui)
	if ui.has_method("afficher"):
		ui.afficher(noms_ordonnes)
	# Optionnel: réinitialiser l'index de tour pour une prochaine partie
	index_joueur_actif = 0
