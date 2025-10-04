extends Node2D

# Signal émis lors de la victoire (avec le joueur gagnant)
signal victoire_atteinte(joueur_gagnant)

# Signal émis quand le déplacement courant se termine (tour terminé)
signal deplacement_termine(joueur_deplace)

var joueur = null
var sprite_anime = null
var position_cible = null
var en_mouvement = false
var vitesse = 300.0

# Variables pour la condition de victoire
var position_arrivee = Vector2(82, 348)  # Position ajustée selon la position réelle du joueur
var animation_victoire_en_cours = false

# Gestion multi-joueurs pour la victoire
var joueurs_arrives: Array = []  # Liste des joueurs qui ont atteint la fin
var partie_terminee: bool = false

# État multi-joueurs: mémoriser l'étage par joueur
var etage_par_joueur: Dictionary = {}

# Variables pour le déplacement libre
var direction_mouvement = Vector2.RIGHT  # Direction par défaut (vers la droite)
var pixels_par_seconde = 50.0  # Vitesse de base du déplacement

# Système de portes multi-étages
var position_porte_x = 2688  # Position X de la porte
var position_sortie_y = 780  # Position Y de sortie au premier étage
var etage_actuel = 0  # 0 = rez-de-chaussée, 1 = premier étage, 2 = deuxième étage, etc.

# Configuration des étages (position X de la porte, position Y de sortie)
var configuration_etages = {
	0: {"porte_x": 2688, "sortie_x": 2687, "sortie_y": 780},  # Rez-de-chaussée → 1er étage
	1: {"porte_x": -48, "sortie_x": -47, "sortie_y": 551},  # 1er étage → 2ème étage
	2: {"porte_x": 2688, "sortie_x": 2687, "sortie_y": 348},  # 2ème étage → 3ème étage
	3: {"porte_x": 4224, "sortie_x": 4223, "sortie_y": 180},  # 3ème étage → 4ème étage
	# Ajouter d'autres étages selon besoin
}

# Variable pour stocker la distance restante après téléportation
var distance_restante_apres_teleportation = 0.0

# Variable pour détecter le passage de la porte
var position_precedente = Vector2.ZERO

# Variables disponibles pour extension future

func _ready():
	joueur = get_node("../character")
	if joueur:
		sprite_anime = joueur.get_node("AnimatedSprite2D")
		print("Joueur trouvé !")
	else:
		print("ERREUR: Joueur non trouvé !")
	
	# Initialisation terminée
	print("Path manager initialisé")

# Définir le joueur actif (mode multi-tours)
func set_joueur_actif(nouveau_joueur: Node2D) -> void:
	joueur = nouveau_joueur
	if joueur and joueur.has_node("AnimatedSprite2D"):
		sprite_anime = joueur.get_node("AnimatedSprite2D")
	else:
		sprite_anime = null
	# Réinitialiser les indicateurs de suivi par tour
	position_precedente = Vector2.ZERO
	distance_restante_apres_teleportation = 0.0
	# Recharger l'étage du joueur (par défaut 0)
	etage_actuel = etage_par_joueur.get(joueur, 0)

# Fonction à appeler depuis le QCM pour déplacer le joueur
func deplacer_joueur(temps_reaction: float):
	if not joueur:
		print("ERREUR: Pas de joueur trouvé dans deplacer_joueur")
		return
	
	print("Fonction deplacer_joueur appelée avec temps_reaction: %f" % temps_reaction)
	
	# Le QCM passe déjà DUREE - temps_reaction, donc on utilise directement cette valeur
	var distance_pixels = max(temps_reaction * pixels_par_seconde, 50.0)  # Minimum 50 pixels
	
	print("Distance calculée: %f pixels" % distance_pixels)
	print("Position actuelle du joueur: %s" % joueur.global_position)
	
	# Déterminer la direction selon l'étage
	# Étages pairs (0, 2, 4...) : vers la droite
	# Étages impairs (1, 3, 5...) : vers la gauche
	if etage_actuel % 2 == 0:
		direction_mouvement = Vector2.RIGHT
	else:
		direction_mouvement = Vector2.LEFT
	
	# Calculer la nouvelle position
	var nouvelle_position
	if direction_mouvement == Vector2.LEFT:
		nouvelle_position = joueur.global_position - Vector2(distance_pixels, 0)
		print("Déplacement vers la gauche: nouvelle position = %s" % nouvelle_position)
	else:
		nouvelle_position = joueur.global_position + Vector2(distance_pixels, 0)
		print("Déplacement vers la droite: nouvelle position = %s" % nouvelle_position)
	
	position_cible = nouvelle_position
	en_mouvement = true
	print("Déplacement de %d pixels vers %s - Moving: %s" % [distance_pixels, direction_mouvement, en_mouvement])

func verifier_porte_atteinte(position_actuelle: Vector2) -> bool:
	# Vérifier si l'étage actuel a une configuration de porte
	if not configuration_etages.has(etage_actuel):
		position_precedente = position_actuelle
		return false
	
	var config_etage = configuration_etages[etage_actuel]
	var position_porte_etage = config_etage["porte_x"]
	
	# Vérifier si le joueur traverse la position X de la porte
	if position_precedente != Vector2.ZERO:
		# Vérifier si on a traversé la porte dans les deux sens
		# De gauche à droite OU de droite à gauche
		if (position_precedente.x < position_porte_etage and position_actuelle.x >= position_porte_etage) or \
		   (position_precedente.x > position_porte_etage and position_actuelle.x <= position_porte_etage):
			print("PORTE TRAVERSÉE ! De %f à %f (Étage %d)" % [position_precedente.x, position_actuelle.x, etage_actuel])
			return true
	
	# Mettre à jour la position précédente
	position_precedente = position_actuelle
	return false

func teleporter_vers_etage_superieur():
	print("=== TÉLÉPORTATION VERS L'ÉTAGE SUPÉRIEUR ===")
	print("Étage actuel: %d" % etage_actuel)
	
	# Vérifier si l'étage actuel a une configuration
	if not configuration_etages.has(etage_actuel):
		print("Pas de configuration pour l'étage %d" % etage_actuel)
		return
	
	var config_etage = configuration_etages[etage_actuel]
	var etage_suivant = etage_actuel + 1
	
	# Téléporter le joueur à l'étage supérieur
	var position_teleportation = Vector2(config_etage["sortie_x"], config_etage["sortie_y"])
	joueur.global_position = position_teleportation
	etage_actuel = etage_suivant
	# Mémoriser l'étage pour ce joueur
	etage_par_joueur[joueur] = etage_actuel
	print("Téléporté vers l'étage %d à la position (%f, %f)" % [etage_suivant, position_teleportation.x, position_teleportation.y])
	
	# Déterminer la nouvelle direction selon l'étage
	if etage_suivant % 2 == 0:
		direction_mouvement = Vector2.RIGHT
		print("Direction changée vers la droite (étage pair)")
	else:
		direction_mouvement = Vector2.LEFT
		print("Direction changée vers la gauche (étage impair)")
	
	# Continuer avec la distance restante du mouvement précédent
	if distance_restante_apres_teleportation > 0:
		var nouvelle_position
		if direction_mouvement == Vector2.LEFT:
			nouvelle_position = joueur.global_position - Vector2(distance_restante_apres_teleportation, 0)
		else:
			nouvelle_position = joueur.global_position + Vector2(distance_restante_apres_teleportation, 0)
		
		position_cible = nouvelle_position
		en_mouvement = true
		print("Mouvement continué avec distance restante: %f pixels vers %s" % [distance_restante_apres_teleportation, nouvelle_position])
	else:
		# Si pas de distance restante, utiliser une distance par défaut
		var distance_par_defaut = 150.0
		var nouvelle_position
		if direction_mouvement == Vector2.LEFT:
			nouvelle_position = joueur.global_position - Vector2(distance_par_defaut, 0)
		else:
			nouvelle_position = joueur.global_position + Vector2(distance_par_defaut, 0)
		
		position_cible = nouvelle_position
		en_mouvement = true
		print("Mouvement avec distance par défaut: %f pixels vers %s" % [distance_par_defaut, nouvelle_position])
	
	# Forcer l'animation selon la direction
	if sprite_anime:
		if direction_mouvement == Vector2.LEFT:
			sprite_anime.play("MoveLeft")
		else:
			sprite_anime.play("MoveRight")

func _process(delta):
	# Code de mise à jour disponible pour extension future
	
	# Vérifier la victoire de tous les joueurs si la partie n'est pas terminée
	if not partie_terminee:
		var scene = get_tree().current_scene
		
		# Vérifier d'abord le joueur actif
		if joueur and verifier_position_arrivee(joueur.global_position):
			declencher_animation_victoire()
		
		# Vérifier ensuite tous les autres joueurs
		for child in scene.get_children():
			if child.name.begins_with("character") and child != joueur:
				if verifier_position_arrivee(child.global_position):
					# Changer temporairement le joueur actif pour l'animation
					var joueur_temp = joueur
					joueur = child
					declencher_animation_victoire()
					joueur = joueur_temp  # Restaurer le joueur original
	
	if en_mouvement and position_cible and joueur:
		# Vérifier si le joueur atteint une porte pendant le mouvement
		var porte_atteinte = verifier_porte_atteinte(joueur.global_position)
		if porte_atteinte:
			# Calculer la distance restante avant d'arrêter le mouvement
			var distance_actuelle = (position_cible - joueur.global_position).length()
			distance_restante_apres_teleportation = distance_actuelle
			print("Distance restante calculée: %f pixels" % distance_restante_apres_teleportation)
			
			# Arrêter le mouvement actuel et téléporter
			en_mouvement = false
			teleporter_vers_etage_superieur()
			return
		
		var direction = (position_cible - joueur.global_position)
		var distance = direction.length()
		
		if distance < 5:
			# Arrivé à destination
			joueur.global_position = position_cible
			en_mouvement = false
			distance_restante_apres_teleportation = 0.0  # Reset la distance restante
			position_precedente = Vector2.ZERO  # Reset la position précédente
			if sprite_anime:
				sprite_anime.stop()
			
			# Code disponible pour extension future
			
			# Notifier la fin du déplacement pour gestion des tours
			emit_signal("deplacement_termine", joueur)
		else:
			# Continuer le mouvement
			direction = direction.normalized()
			joueur.global_position += direction * vitesse * delta
			
			# Animation selon la direction
			if sprite_anime:
				if abs(direction.x) > abs(direction.y):
					if direction.x > 0:
						sprite_anime.play("MoveRight")
					else:
						sprite_anime.play("MoveLeft")
				else:
					if direction.y > 0:
						sprite_anime.play("MoveDown")
					else:
						sprite_anime.play("MoveUp")

# Fonctions pour changer la direction de déplacement
func set_direction_droite():
	direction_mouvement = Vector2.RIGHT

func set_direction_gauche():
	direction_mouvement = Vector2.LEFT

func set_direction_haut():
	direction_mouvement = Vector2.UP

func set_direction_bas():
	direction_mouvement = Vector2.DOWN

func set_direction_diagonale(x: float, y: float):
	direction_mouvement = Vector2(x, y).normalized()

# Fonction pour ajuster la vitesse de déplacement
func set_vitesse_deplacement(nouvelle_vitesse: float):
	pixels_par_seconde = nouvelle_vitesse

# Fonction pour obtenir l'étage actuel
func get_etage_actuel() -> int:
	return etage_actuel

# Fonction pour définir manuellement l'étage actuel
func set_etage_actuel(etage: int):
	etage_actuel = etage

# Fonction pour vérifier si le joueur a atteint la position d'arrivée
func verifier_position_arrivee(position_actuelle: Vector2) -> bool:

	
	# Vérifier si le joueur est proche de la position d'arrivée (tolérance augmentée à 20 pixels)
	var distance_arrivee = position_actuelle.distance_to(position_arrivee)
	
	# Log pour déboguer
	if distance_arrivee <= 25.0:  # Log quand on s'approche
		print("Distance à l'arrivée: %f pixels (Position: %s, Cible: %s)" % [distance_arrivee, position_actuelle, position_arrivee])
	
	if distance_arrivee <= 20.0:
		print("VICTOIRE ! Position d'arrivée atteinte : %s (distance: %f)" % [position_actuelle, distance_arrivee])
		return true
	
	return false

# Fonction pour déclencher l'animation de victoire
func declencher_animation_victoire():
	# Vérifier si ce joueur est déjà arrivé
	var joueur_id = joueur.get_instance_id()
	if joueur_id in joueurs_arrives:
		print("Ce joueur est déjà arrivé, animation ignorée")
		return
	
	print("=== DÉCLENCHEMENT DE L'ANIMATION DE VICTOIRE ===")
	
	# Ajouter le joueur à la liste des arrivés
	joueurs_arrives.append(joueur_id)
	print("Joueur %s ajouté à la liste des arrivés. Total: %d" % [joueur.name, joueurs_arrives.size()])
	
	# Arrêter le mouvement du joueur
	en_mouvement = false
	position_cible = null
	
	# Désactiver le contrôle manuel si activé
	if joueur.has_method("set_controle_manuel"):
		joueur.set_controle_manuel(false)
	
	# Émettre le signal de victoire avec le joueur gagnant
	victoire_atteinte.emit(joueur)
	
	# Lancer l'animation de victoire en arrière-plan (sans bloquer)
	animer_victoire_arriere_plan()
	
	# Vérifier si TOUS les joueurs sont arrivés pour terminer la partie
	_verifier_fin_partie()

# Fonction pour l'animation de victoire en arrière-plan (non-bloquante)
func animer_victoire_arriere_plan():
	if not sprite_anime:
		print("Erreur : AnimatedSprite2D non trouvé pour l'animation de victoire")
		return
	
	print("Début de l'animation de victoire en arrière-plan...")
	
	# Lancer l'animation sans attendre (non-bloquante)
	animer_victoire()

# Fonction pour l'animation de victoire
func animer_victoire():
	if not sprite_anime:
		print("Erreur : AnimatedSprite2D non trouvé pour l'animation de victoire")
		return
	
	print("Début de l'animation de victoire...")
	
	# Phase 1 : Animation de célébration (saut et rotation)
	var position_initiale = joueur.global_position
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Effet de saut
	tween.tween_method(
		func(pos): joueur.global_position = pos,
		position_initiale,
		position_initiale + Vector2(0, -50),
		0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	tween.tween_method(
		func(pos): joueur.global_position = pos,
		position_initiale + Vector2(0, -50),
		position_initiale,
		0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN).set_delay(0.5)
	
	# Effet de rotation
	tween.tween_method(
		func(angle): joueur.rotation = angle,
		0.0,
		2 * PI,
		1.0
	)
	
	# Animation du sprite
	if sprite_anime.sprite_frames and sprite_anime.sprite_frames.has_animation("MoveRight"):
		sprite_anime.play("MoveRight")
	
	# Lancer les animations sans attendre (non-bloquantes)
	# Phase 2 : Effet de pulsation
	var tween2 = create_tween()
	tween2.set_loops(3)
	tween2.tween_method(
		func(scale): joueur.scale = Vector2(scale, scale),
		1.0,
		1.5,
		0.3
	).set_trans(Tween.TRANS_SINE)
	tween2.tween_method(
		func(scale): joueur.scale = Vector2(scale, scale),
		1.5,
		1.0,
		0.3
	).set_trans(Tween.TRANS_SINE)
	
	# Remettre les valeurs par défaut après un délai
	get_tree().create_timer(1.5).timeout.connect(func():
		joueur.rotation = 0.0
		joueur.scale = Vector2(1.0, 1.0)
		if sprite_anime:
			sprite_anime.stop()
			sprite_anime.set_frame(0)
		print("Animation de victoire terminée !")
	)

# Fonction pour afficher un message de victoire
func afficher_message_victoire():
	print("🎉 FÉLICITATIONS ! VOUS AVEZ GAGNÉ ! 🎉")
	# Cette fonction n'est plus appelée automatiquement
	# La fin de partie est maintenant gérée par _verifier_fin_partie()

# UI Design: Animation de victoire collective pour plusieurs joueurs (non-bloquante)
func jouer_animation_victoire_collective(joueurs: Array) -> void:
	if joueurs.is_empty():
		return
	# Lancer une petite célébration en parallèle pour chaque joueur
	for j in joueurs:
		if j == null:
			continue
		var sprite: AnimatedSprite2D = null
		if j.has_node("AnimatedSprite2D"):
			sprite = j.get_node("AnimatedSprite2D")
		var pos_initiale: Vector2 = j.global_position
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_method(
			func(pos): j.global_position = pos,
			pos_initiale,
			pos_initiale + Vector2(0, -40),
			0.35
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_method(
			func(pos): j.global_position = pos,
			pos_initiale + Vector2(0, -40),
			pos_initiale,
			0.35
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_delay(0.35)
		tween.tween_method(
			func(s): j.scale = Vector2(s, s),
			1.0,
			1.3,
			0.25
		).set_trans(Tween.TRANS_SINE)
		tween.tween_method(
			func(s): j.scale = Vector2(s, s),
			1.3,
			1.0,
			0.25
		).set_trans(Tween.TRANS_SINE).set_delay(0.25)
		if sprite:
			sprite.play("MoveRight")

# Fonction pour réinitialiser les variables de victoire (utile pour tester)
func reinitialiser_victoire():
	animation_victoire_en_cours = false
	joueurs_arrives.clear()
	partie_terminee = false
	print("Variables de victoire réinitialisées - vous pouvez retester l'animation") 

# Réinitialisation complète de la partie (utile pour Rejouer)
func reinitialiser_partie():
	en_mouvement = false
	position_cible = null
	position_precedente = Vector2.ZERO
	distance_restante_apres_teleportation = 0.0
	etage_actuel = 0
	etage_par_joueur.clear()
	joueur = null
	sprite_anime = null
	reinitialiser_victoire()
	
	# Réinitialiser la gestion multi-joueurs
	joueurs_arrives.clear()
	partie_terminee = false

func _verifier_fin_partie():
	"""Vérifie si TOUS les joueurs sont arrivés pour terminer la partie"""
	# Compter le nombre total de joueurs dans la scène
	var scene = get_tree().current_scene
	var total_joueurs = 0
	var joueurs_scene = []
	
	# Chercher tous les personnages dans la scène
	for child in scene.get_children():
		if child.name.begins_with("character"):
			total_joueurs += 1
			joueurs_scene.append(child)
	
	print("Vérification fin de partie: %d joueurs arrivés sur %d total" % [joueurs_arrives.size(), total_joueurs])
	
	# TOUS les joueurs doivent arriver pour terminer la partie
	var joueurs_requis_pour_fin = total_joueurs
	
	print("🎯 Joueurs requis pour fin de partie: %d sur %d total (TOUS doivent arriver)" % [joueurs_requis_pour_fin, total_joueurs])
	
	# Vérifier si TOUS les joueurs sont arrivés
	if joueurs_arrives.size() >= joueurs_requis_pour_fin and total_joueurs > 0:
		print("🎯 TOUS LES JOUEURS SONT ARRIVÉS ! Fin de partie...")
		partie_terminee = true
		
		# Arrêter tous les mouvements
		for joueur in joueurs_scene:
			if joueur.has_method("set_controle_manuel"):
				joueur.set_controle_manuel(false)
		
		# Masquer le QCM seulement quand TOUS sont arrivés
		var qcm = scene.get_node_or_null("QCM")
		if qcm:
			qcm.visible = false
			print("QCM masqué - Tous les joueurs sont arrivés")
		
		# Masquer le bouton ARRÊTER
		var bouton_arreter = scene.get_node_or_null("BoutonArreter")
		if bouton_arreter:
			bouton_arreter.visible = false
			print("Bouton ARRÊTER masqué")
		
		# Jouer l'animation de victoire collective en arrière-plan
		jouer_animation_victoire_collective(joueurs_scene)
		
		# Afficher le classement final après un court délai
		get_tree().create_timer(1.0).timeout.connect(func():
			_afficher_classement_final(joueurs_scene)
		)
	else:
		print("⏳ En attente: %d/%d joueurs arrivés - La partie continue..." % [joueurs_arrives.size(), total_joueurs])
		print("🎮 Le QCM reste actif pour les joueurs restants")
		print("🎯 Les joueurs restants peuvent continuer à jouer normalement")

func _afficher_classement_final(joueurs_scene: Array):
	"""Affiche le classement final de la partie"""
	print("🏆 AFFICHAGE DU CLASSEMENT FINAL")
	
	# Créer le classement basé sur l'ordre d'arrivée
	var classement_final = []
	for joueur_id in joueurs_arrives:
		# Trouver le joueur correspondant
		for joueur in joueurs_scene:
			if joueur.get_instance_id() == joueur_id:
				var nom_joueur = "Joueur"
				if joueur.has_method("get_nom_joueur"):
					nom_joueur = joueur.get_nom_joueur()
				elif joueur.has_node("EtiquetteNom"):
					nom_joueur = joueur.get_node("EtiquetteNom").text
				
				classement_final.append(nom_joueur)
				break
	
	# Charger et afficher l'interface de classement
	var scene_classement = load("res://Scenes/ui/classement.tscn")
	if scene_classement:
		var ui_classement = scene_classement.instantiate()
		get_tree().current_scene.add_child(ui_classement)
		if ui_classement.has_method("afficher"):
			ui_classement.afficher(classement_final)
		else:
			print("Erreur: L'interface de classement n'a pas de méthode 'afficher'")
	else:
		print("Erreur: Impossible de charger la scène de classement")
