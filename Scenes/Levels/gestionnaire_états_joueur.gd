extends Node
class_name GestionnaireÉtatsJoueur

# Gestionnaire des états temporaires des joueurs
# UI Design: Système de gestion des effets pour une meilleure expérience utilisateur

signal état_modifié(joueur: Node, état: String, actif: bool)
signal effet_expiré(joueur: Node, état: String)

var états_joueurs: Dictionary = {}  # {joueur: {état: durée_restante}}
var timers_effets: Dictionary = {}  # {joueur: {état: Timer}}

func _ready():
	# Initialisation du gestionnaire d'états
	print("Gestionnaire d'états joueur initialisé")

func appliquer_effet(joueur: Node, effet: String, durée: float):
	# Appliquer un effet temporaire sur un joueur
	if not joueur in états_joueurs:
		états_joueurs[joueur] = {}
	
	# Si l'effet existe déjà, le remplacer
	if effet in états_joueurs[joueur]:
		_retirer_effet(joueur, effet)
	
	états_joueurs[joueur][effet] = durée
	_créer_timer_effet(joueur, effet, durée)
	
	# Émettre le signal de modification d'état
	emit_signal("état_modifié", joueur, effet, true)
	
	print("Effet ", effet, " appliqué sur ", joueur.name, " pour ", durée, " secondes")

func _créer_timer_effet(joueur: Node, effet: String, durée: float):
	# Créer un timer pour l'effet
	var timer = get_tree().create_timer(durée)
	timer.timeout.connect(func(): _expirer_effet(joueur, effet))
	
	if not joueur in timers_effets:
		timers_effets[joueur] = {}
	timers_effets[joueur][effet] = timer

func _expirer_effet(joueur: Node, effet: String):
	# L'effet a expiré
	_retirer_effet(joueur, effet)
	emit_signal("effet_expiré", joueur, effet)
	print("Effet ", effet, " expiré sur ", joueur.name)

func _retirer_effet(joueur: Node, effet: String):
	# Retirer un effet d'un joueur
	if joueur in états_joueurs and effet in états_joueurs[joueur]:
		états_joueurs[joueur].erase(effet)
		
		# Arrêter le timer associé
		if joueur in timers_effets and effet in timers_effets[joueur]:
			timers_effets[joueur][effet].stop()
			timers_effets[joueur].erase(effet)
		
		emit_signal("état_modifié", joueur, effet, false)

func obtenir_effets_actifs(joueur: Node) -> Array:
	# Retourner la liste des effets actifs sur un joueur
	if joueur in états_joueurs:
		return états_joueurs[joueur].keys()
	return []

func obtenir_durée_restante(joueur: Node, effet: String) -> float:
	# Retourner la durée restante d'un effet
	if joueur in états_joueurs and effet in états_joueurs[joueur]:
		return états_joueurs[joueur][effet]
	return 0.0

func est_effet_actif(joueur: Node, effet: String) -> bool:
	# Vérifier si un effet est actif sur un joueur
	return joueur in états_joueurs and effet in états_joueurs[joueur]

# Méthodes disponibles pour extension future

func reinitialiser_joueur(joueur: Node):
	# Réinitialiser tous les effets d'un joueur
	if joueur in états_joueurs:
		var effets = états_joueurs[joueur].keys()
		for effet in effets:
			_retirer_effet(joueur, effet)
		états_joueurs.erase(joueur)
	
	if joueur in timers_effets:
		for timer in timers_effets[joueur].values():
			timer.stop()
		timers_effets.erase(joueur)

func reinitialiser_tous():
	# Réinitialiser tous les joueurs
	for joueur in états_joueurs.keys():
		reinitialiser_joueur(joueur)
	
	print("Tous les états des joueurs ont été réinitialisés")

func obtenir_statut_complet(joueur: Node) -> Dictionary:
	# Retourner le statut complet d'un joueur
	var statut = {}
	
	if joueur in états_joueurs:
		for effet in états_joueurs[joueur]:
			statut[effet] = {
				"durée_restante": états_joueurs[joueur][effet],
				"actif": true
			}
	
	return statut
