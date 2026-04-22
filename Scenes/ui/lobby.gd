extends Control

# UI Design: Écran de lobby multi-joueurs (2/3/4) + saisie des noms

@export var chemin_scene_personnage: String = "res://Scenes/character/character.tscn"

@onready var boutons_nb_participants = {
	2: $Fond/VBox/ChoixParticipants/HBox/Bouton2,
	3: $Fond/VBox/ChoixParticipants/HBox/Bouton3,
	4: $Fond/VBox/ChoixParticipants/HBox/Bouton4,
}
@onready var champs_noms = [
	$Fond/VBox/Noms/HBox/Nom1,
	$Fond/VBox/Noms/HBox/Nom2,
	$Fond/VBox/Noms/HBox/Nom3,
	$Fond/VBox/Noms/HBox/Nom4,
]
@onready var bouton_commencer: Button = $Fond/VBox/BoutonCommencer
@onready var etiquette_erreur: Label = $Fond/VBox/EtiquetteErreur

var nombre_participants: int = 2

const LONGUEUR_NOM_MAX = 20

func _ready():
	randomize()
	_appliquer_theme()
	# Sélection par défaut à 2 participants
	_mettre_en_evidence_bouton(2)
	for nb in boutons_nb_participants.keys():
		boutons_nb_participants[nb].pressed.connect(_on_bouton_nb_participants_appuye.bind(nb))
	bouton_commencer.pressed.connect(_on_bouton_commencer)
	# Validation longueur: limite visuelle directe sur LineEdit
	for champ in champs_noms:
		champ.max_length = LONGUEUR_NOM_MAX
	_mettre_a_jour_champs_noms()
	# UI Design: Le lobby doit bloquer le jeu au lancement
	var racine = get_tree().current_scene
	if racine:
		var qcm = racine.get_node_or_null("UILayer/QCM")
		if qcm:
			qcm.visible = false
	# Animation d'entrée échelonnée
	var vbox = $Fond/VBox
	for i in range(vbox.get_child_count()):
		UITheme.animer_entree(vbox.get_child(i), i * 0.07)

func _appliquer_theme() -> void:
	# Boutons de sélection du nombre de participants
	for bouton in boutons_nb_participants.values():
		UITheme.appliquer_bouton(bouton, UITheme.COULEUR_FOND_CLAIR)
	# Bouton commencer: couleur accent
	UITheme.appliquer_bouton(bouton_commencer, UITheme.COULEUR_SUCCES)
	# Champs de texte
	for champ in champs_noms:
		UITheme.appliquer_line_edit(champ)
	# Fond plus doux
	if has_node("Fond"):
		$Fond.color = UITheme.COULEUR_FOND
	# Étiquette erreur
	etiquette_erreur.add_theme_color_override("font_color", UITheme.COULEUR_DANGER)
	etiquette_erreur.add_theme_font_size_override("font_size", 20)

func _on_bouton_nb_participants_appuye(nb: int) -> void:
	nombre_participants = nb
	_mettre_en_evidence_bouton(nb)
	_mettre_a_jour_champs_noms()

func _mettre_en_evidence_bouton(nb: int) -> void:
	for k in boutons_nb_participants.keys():
		var b: Button = boutons_nb_participants[k]
		if k == nb:
			UITheme.appliquer_bouton(b, UITheme.COULEUR_PRIMAIRE)
		else:
			UITheme.appliquer_bouton(b, UITheme.COULEUR_FOND_CLAIR)

func _mettre_a_jour_champs_noms() -> void:
	for i in range(champs_noms.size()):
		champs_noms[i].editable = (i < nombre_participants)
		champs_noms[i].modulate = Color(1,1,1, 1 if i < nombre_participants else 0.5)

func _collecter_noms() -> Array:
	var noms: Array = []
	for i in range(nombre_participants):
		var texte = String(champs_noms[i].text).strip_edges()
		if texte.is_empty():
			texte = "Joueur %d" % (i+1)
		noms.append(texte)
	return noms

func _on_bouton_commencer() -> void:
	etiquette_erreur.text = ""
	# Récupérer le gestionnaire multi et la scène QCM
	var scene_racine = get_tree().current_scene
	if not scene_racine:
		etiquette_erreur.text = "Erreur: scène courante introuvable"
		return
	var multi = scene_racine.get_node("UILayer/QCM/MultiManager")
	if not multi:
		etiquette_erreur.text = "Erreur: MultiManager introuvable (QCM/MultiManager)"
		return

	# Instancier les joueurs
	var pack_personnage: PackedScene = load(chemin_scene_personnage)
	if not pack_personnage:
		etiquette_erreur.text = "Erreur: scène personnage introuvable"
		return

	var joueurs_nodes: Array = []
	var noms = _collecter_noms()

	# Réutiliser un personnage existant nommé "character" s'il est présent pour le joueur 1
	var joueur1 = scene_racine.get_node_or_null("character")
	if joueur1:
		joueurs_nodes.append(joueur1)
	else:
		var j1 = pack_personnage.instantiate()
		j1.name = "character"
		j1.position = Vector2(21, 980)
		scene_racine.add_child(j1)
		joueurs_nodes.append(j1)

	# Ajouter les autres joueurs et les positionner à la même position de départ
	var base_position: Vector2 = joueurs_nodes[0].position
	for i in range(1, nombre_participants):
		var joueur_i = pack_personnage.instantiate()
		joueur_i.name = "character_%d" % (i+1)
		joueur_i.position = base_position  # Même position pour tous
		scene_racine.add_child(joueur_i)
		joueurs_nodes.append(joueur_i)

	# Désactiver contrôle manuel initial pour éviter les mouvements hors tour
	for j in joueurs_nodes:
		if j.has_method("set_controle_manuel"):
			j.set_controle_manuel(false)
	# Appliquer les noms visibles au-dessus de la tête
	for i in range(joueurs_nodes.size()):
		var jnode = joueurs_nodes[i]
		if jnode.has_method("definir_nom_joueur"):
			jnode.definir_nom_joueur(noms[i])

	# Configurer le gestionnaire multi avec ordre de départ
	if joueurs_nodes.size() == 2:
		# Pile ou face
		var start = randi() % 2
		if start == 1:
			noms = [noms[1], noms[0]]
			joueurs_nodes = [joueurs_nodes[1], joueurs_nodes[0]]
	elif joueurs_nodes.size() == 3:
		# Ordre aléatoire
		var indices = [0,1,2]
		indices.shuffle()
		var noms2 = []
		var nodes2 = []
		for i in indices:
			noms2.append(noms[i])
			nodes2.append(joueurs_nodes[i])
		noms = noms2
		joueurs_nodes = nodes2
	elif joueurs_nodes.size() == 4:
		var indices4 = [0,1,2,3]
		indices4.shuffle()
		var noms4 = []
		var nodes4 = []
		for i in indices4:
			noms4.append(noms[i])
			nodes4.append(joueurs_nodes[i])
		noms = noms4
		joueurs_nodes = nodes4

	multi.configurer_joueurs(noms, joueurs_nodes)

	# Masquer le lobby et démarrer
	visible = false
	# Afficher le QCM maintenant que la partie peut commencer
	var qcm = scene_racine.get_node_or_null("UILayer/QCM")
	if qcm:
		qcm.visible = true
	
	# Afficher le bouton ARRÊTER quand la partie commence
	var bouton_arreter = scene_racine.get_node_or_null("UILayer/BoutonArreter")
	if bouton_arreter and bouton_arreter.has_method("set_bouton_visible"):
		bouton_arreter.set_bouton_visible(true)
