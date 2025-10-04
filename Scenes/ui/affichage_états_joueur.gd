extends Control
class_name AffichageÉtatsJoueur

# Interface pour afficher les états actifs des joueurs
# UI Design: Affichage en temps réel des effets pour une meilleure visibilité

@onready var container_états: VBoxContainer = $ContainerÉtats
@onready var label_titre: Label = $LabelTitre
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var gestionnaire_états: GestionnaireÉtatsJoueur
var joueurs_suivis: Array = []
var timers_actualisation: Dictionary = {}

func _ready():
	visible = false
	_chercher_gestionnaire_états()
	_connecter_signaux()

func _chercher_gestionnaire_états():
	# Chercher le gestionnaire d'états dans l'arbre de scène
	gestionnaire_états = get_node_or_null("/root/GestionnaireÉtatsJoueur")
	if not gestionnaire_états:
		# Essayer de le trouver dans la scène actuelle
		gestionnaire_états = get_node_or_null("GestionnaireÉtatsJoueur")

func _connecter_signaux():
	if gestionnaire_états:
		gestionnaire_états.état_modifié.connect(_sur_état_modifié)
		gestionnaire_états.effet_expiré.connect(_sur_effet_expiré)

func ajouter_joueur(joueur: Node):
	# Ajouter un joueur à surveiller
	if not joueur in joueurs_suivis:
		joueurs_suivis.append(joueur)
		_créer_affichage_joueur(joueur)
		_démarrer_actualisation(joueur)

func retirer_joueur(joueur: Node):
	# Retirer un joueur de la surveillance
	if joueur in joueurs_suivis:
		joueurs_suivis.erase(joueur)
		_supprimer_affichage_joueur(joueur)
		_arrêter_actualisation(joueur)

func _créer_affichage_joueur(joueur: Node):
	# Créer l'affichage pour un joueur
	var container_joueur = VBoxContainer.new()
	container_joueur.name = "Joueur_" + joueur.name
	container_joueur.add_theme_constant_override("separation", 10)
	
	# Titre du joueur
	var label_joueur = Label.new()
	label_joueur.text = joueur.name
	label_joueur.add_theme_color_override("font_color", Color.WHITE)
	label_joueur.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container_joueur.add_child(label_joueur)
	
	# Container pour les états
	var container_états_joueur = VBoxContainer.new()
	container_états_joueur.name = "États"
	container_états_joueur.add_theme_constant_override("separation", 5)
	container_joueur.add_child(container_états_joueur)
	
	# Séparateur
	var séparateur = HSeparator.new()
	container_joueur.add_child(séparateur)
	
	container_états.add_child(container_joueur)

func _supprimer_affichage_joueur(joueur: Node):
	# Supprimer l'affichage d'un joueur
	var container_joueur = container_états.get_node_or_null("Joueur_" + joueur.name)
	if container_joueur:
		container_joueur.queue_free()

func _démarrer_actualisation(joueur: Node):
	# Démarrer l'actualisation automatique pour un joueur
	var timer = Timer.new()
	timer.wait_time = 0.5  # Actualiser toutes les 0.5 secondes
	timer.timeout.connect(func(): _actualiser_affichage_joueur(joueur))
	add_child(timer)
	timer.start()
	
	timers_actualisation[joueur] = timer

func _arrêter_actualisation(joueur: Node):
	# Arrêter l'actualisation pour un joueur
	if joueur in timers_actualisation:
		var timer = timers_actualisation[joueur]
		timer.stop()
		timer.queue_free()
		timers_actualisation.erase(joueur)

func _actualiser_affichage_joueur(joueur: Node):
	# Actualiser l'affichage des états d'un joueur
	if not gestionnaire_états:
		return
	
	var container_joueur = container_états.get_node_or_null("Joueur_" + joueur.name)
	if not container_joueur:
		return
	
	var container_états_joueur = container_joueur.get_node_or_null("États")
	if not container_états_joueur:
		return
	
	# Effacer les anciens états
	for enfant in container_états_joueur.get_children():
		enfant.queue_free()
	
	# Obtenir les états actifs
	var effets_actifs = gestionnaire_états.obtenir_effets_actifs(joueur)
	
	if effets_actifs.is_empty():
		var label_aucun = Label.new()
		label_aucun.text = "Aucun effet actif"
		label_aucun.add_theme_color_override("font_color", Color.GRAY)
		container_états_joueur.add_child(label_aucun)
		return
	
	# Afficher chaque état
	for effet in effets_actifs:
		var durée_restante = gestionnaire_états.obtenir_durée_restante(joueur, effet)
		var item_état = _créer_item_état(effet, durée_restante)
		container_états_joueur.add_child(item_état)

func _créer_item_état(effet: String, durée: float) -> HBoxContainer:
	# Créer un item d'état avec barre de progression
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	
	# Icône de l'effet
	var icône = TextureRect.new()
	icône.texture = preload("res://icon.svg")  # Icône par défaut
	icône.custom_minimum_size = Vector2(16, 16)
	icône.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	
	# Couleur selon le type d'effet
	if effet in ["ralenti", "coincé", "perd_tour"]:
		icône.modulate = Color.RED
	else:
		icône.modulate = Color.GREEN
	
	container.add_child(icône)
	
	# Nom de l'effet
	var label_effet = Label.new()
	label_effet.text = _formater_nom_effet(effet)
	label_effet.custom_minimum_size = Vector2(80, 0)
	container.add_child(label_effet)
	
	# Barre de progression
	var barre_progression = ProgressBar.new()
	barre_progression.min_value = 0
	barre_progression.max_value = 100
	barre_progression.value = (durée_restante / 10.0) * 100  # Normaliser sur 10 secondes
	barre_progression.custom_minimum_size = Vector2(100, 20)
	barre_progression.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(barre_progression)
	
	# Temps restant
	var label_temps = Label.new()
	label_temps.text = "%.1fs" % durée_restante
	label_temps.custom_minimum_size = Vector2(40, 0)
	container.add_child(label_temps)
	
	return container

func _formater_nom_effet(effet: String) -> String:
	# Formater le nom de l'effet pour l'affichage
	match effet:
		"ralenti":
			return "Ralenti"
		"coincé":
			return "Coincé"
		"perd_tour":
			return "Perd Tour"
		"protégé":
			return "Protégé"
		"accéléré":
			return "Accéléré"
		"double_tour":
			return "Double Tour"
		_:
			return effet.capitalize()

func _sur_état_modifié(joueur: Node, état: String, actif: bool):
	# Réagir à la modification d'un état
	if actif:
		# Ajouter le joueur s'il n'est pas déjà suivi
		if not joueur in joueurs_suivis:
			ajouter_joueur(joueur)
	else:
		# Vérifier si le joueur a encore des effets actifs
		if gestionnaire_états and gestionnaire_états.obtenir_effets_actifs(joueur).is_empty():
			# Retirer le joueur s'il n'a plus d'effets
			retirer_joueur(joueur)

func _sur_effet_expiré(joueur: Node, état: String):
	# Réagir à l'expiration d'un effet
	print("Effet ", état, " expiré sur ", joueur.name)
	# L'actualisation automatique se chargera de mettre à jour l'affichage

func afficher():
	visible = true
	animation_player.play("apparition")

func masquer():
	animation_player.play("disparition")
	await animation_player.animation_finished
	visible = false

func reinitialiser():
	# Réinitialiser l'affichage
	for joueur in joueurs_suivis.duplicate():
		retirer_joueur(joueur)
	joueurs_suivis.clear()
