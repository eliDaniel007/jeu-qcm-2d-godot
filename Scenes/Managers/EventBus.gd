extends Node
class_name EventBus

# EventBus centralisé pour la communication entre composants
# UI Design: Système d'événements centralisé pour une architecture plus propre

# Signaux disponibles pour extension future

# Signaux pour les états des joueurs
signal état_joueur_changé(joueur: Node, ancien_état: String, nouvel_état: String)
signal effet_appliqué(joueur: Node, effet: String, durée: float)
signal effet_retiré(joueur: Node, effet: String)

# Signaux pour l'interface utilisateur
signal ui_effet_affiché(joueur: Node, type: String, description: String)
signal ui_animation_démarrée(animation: String)
signal ui_animation_terminée(animation: String)

# Signaux pour le système de jeu
signal tour_joueur_commencé(joueur: Node)
signal tour_joueur_terminé(joueur: Node)
signal partie_démarrée()
signal partie_terminée(gagnant: Node)

# Gestionnaire d'événements avec timestamps
var événements_actifs: Dictionary = {}
var historique_événements: Array = []
var max_historique: int = 100

# Système de callbacks pour les événements
var callbacks_événements: Dictionary = {}

func _ready():
	# S'assurer que l'EventBus est un singleton
	if get_parent() != get_tree().root:
		push_error("EventBus doit être un singleton à la racine de l'arbre de scène")
		return
	
	print("EventBus initialisé - Système d'événements centralisé prêt")

# Fonction pour émettre un événement avec gestion automatique
func émettre_événement(signal_name: String, paramètres: Array = []) -> void:
	# Enregistrer l'événement dans l'historique
	var événement = {
		"nom": signal_name,
		"paramètres": paramètres,
		"timestamp": Time.get_time_dict_from_system(),
		"actif": true
	}
	
	historique_événements.append(événement)
	
	# Limiter la taille de l'historique
	if historique_événements.size() > max_historique:
		historique_événements.pop_front()
	
	# Émettre le signal
	match signal_name:
		"état_joueur_changé":
			état_joueur_changé.emit(paramètres[0], paramètres[1], paramètres[2])
		"effet_appliqué":
			effet_appliqué.emit(paramètres[0], paramètres[1], paramètres[2])
		"effet_retiré":
			effet_retiré.emit(paramètres[0], paramètres[1])
		"ui_effet_affiché":
			ui_effet_affiché.emit(paramètres[0], paramètres[1], paramètres[2])
		"ui_animation_démarrée":
			ui_animation_démarrée.emit(paramètres[0])
		"ui_animation_terminée":
			ui_animation_terminée.emit(paramètres[0])
		"tour_joueur_commencé":
			tour_joueur_commencé.emit(paramètres[0])
		"tour_joueur_terminé":
			tour_joueur_terminé.emit(paramètres[0])
		"partie_démarrée":
			partie_démarrée.emit()
		"partie_terminée":
			partie_terminée.emit(paramètres[0])
		_:
			push_warning("Signal inconnu: " + signal_name)
	
	# Exécuter les callbacks enregistrés
	_exécuter_callbacks(signal_name, paramètres)
	
	print("Événement émis: ", signal_name, " avec ", paramètres.size(), " paramètres")

# Système de callbacks pour les événements
func enregistrer_callback(événement: String, callback: Callable) -> void:
	if not événement in callbacks_événements:
		callbacks_événements[événement] = []
	
	callbacks_événements[événement].append(callback)
	print("Callback enregistré pour l'événement: ", événement)

func retirer_callback(événement: String, callback: Callable) -> void:
	if événement in callbacks_événements:
		callbacks_événements[événement].erase(callback)
		print("Callback retiré pour l'événement: ", événement)

func _exécuter_callbacks(événement: String, paramètres: Array) -> void:
	if événement in callbacks_événements:
		for callback in callbacks_événements[événement]:
			if callback.is_valid():
				callback.callv(paramètres)

# Gestion des événements actifs
func marquer_événement_actif(événement: Dictionary) -> void:
	var clé = _créer_clé_événement(événement)
	événements_actifs[clé] = événement

func marquer_événement_inactif(événement: Dictionary) -> void:
	var clé = _créer_clé_événement(événement)
	if clé in événements_actifs:
		événements_actifs.erase(clé)

func _créer_clé_événement(événement: Dictionary) -> String:
	return str(événement.get("nom", "")) + "_" + str(événement.get("timestamp", ""))

# Fonctions utilitaires pour les événements
func obtenir_événements_actifs() -> Dictionary:
	return événements_actifs.duplicate()

func obtenir_historique_événements() -> Array:
	return historique_événements.duplicate()

func effacer_historique() -> void:
	historique_événements.clear()
	événements_actifs.clear()
	print("Historique des événements effacé")

# Fonctions spécialisées disponibles pour extension future

# Fonctions pour l'interface utilisateur
func émettre_ui_effet_affiché(joueur: Node, type: String, description: String) -> void:
	émettre_événement("ui_effet_affiché", [joueur, type, description])

func émettre_ui_animation_démarrée(animation: String) -> void:
	émettre_événement("ui_animation_démarrée", [animation])

func émettre_ui_animation_terminée(animation: String) -> void:
	émettre_événement("ui_animation_terminée", [animation])

# Fonctions pour le système de jeu
func émettre_tour_joueur_commencé(joueur: Node) -> void:
	émettre_événement("tour_joueur_commencé", [joueur])

func émettre_tour_joueur_terminé(joueur: Node) -> void:
	émettre_événement("tour_joueur_terminé", [joueur])

func émettre_partie_démarrée() -> void:
	émettre_événement("partie_démarrée", [])

func émettre_partie_terminée(gagnant: Node) -> void:
	émettre_événement("partie_terminée", [gagnant])

# Fonction de nettoyage
func _exit_tree():
	# Nettoyer les callbacks avant de quitter
	callbacks_événements.clear()
	événements_actifs.clear()
	historique_événements.clear()
	print("EventBus nettoyé")
