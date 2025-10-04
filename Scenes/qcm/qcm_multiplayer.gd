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

func _ready():
	path_manager = get_tree().current_scene.get_node("path_manager")
	qcm_ui = get_tree().current_scene.get_node("QCM")
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
	get_tree().current_scene.add_child(ui)
	if ui.has_method("afficher"):
		ui.afficher(noms_ordonnes)
	# Optionnel: réinitialiser l'index de tour pour une prochaine partie
	index_joueur_actif = 0
