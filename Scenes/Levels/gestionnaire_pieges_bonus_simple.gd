extends Node2D

# Gestionnaire simple des pièges et bonus
# Basé sur le système des portes : vérification par coordonnées et actions instantanées

# Configuration des pièges (positions où le joueur recule)
var pieges = [
	# Rez-de-chaussée (y=982)
	{"x": 1825, "y": 982, "nom": "Piège Sable Mouvant", "recul": 250},
	{"x": 1200, "y": 982, "nom": "Fosse Cachée", "recul": 220},
	
	# 1er étage (y=780)
	{"x": 2270, "y": 780, "nom": "Piège à Glace", "recul": 300},
	{"x": 1800, "y": 780, "nom": "Lames Rotatives", "recul": 280},
	
	# 2ème étage (y=551)
	{"x": 1500, "y": 551, "nom": "Trou Noir", "recul": 350},
	{"x": 800, "y": 551, "nom": "Tempête de Sable", "recul": 300},
	
	# 3ème étage (y=348) - Plus difficile
	{"x": 2000, "y": 348, "nom": "Portail Maléfique", "recul": 400},
	{"x": 1200, "y": 348, "nom": "Griffes du Néant", "recul": 380},
	
	# 3ème étage - Pièges supplémentaires avant l'arrivée
	{"x": 1000, "y": 348, "nom": "Labyrinthe de Glace", "recul": 420},
	{"x": 800, "y": 348, "nom": "Tempête de Foudre", "recul": 450},
	{"x": 600, "y": 348, "nom": "Portail de l'Horreur", "recul": 480},
	{"x": 400, "y": 348, "nom": "Garde Final", "recul": 500},
	
	# 4ème étage final (y=180) - Aucun piège (étage vide)
]

# Configuration des bonus avec différents types d'effets
# Logique inversée : plus de bonus au RDC (généreux), moins et moins puissants en montant (difficile)
var bonus = [
	# Rez-de-chaussée (y=982) - 6 bonus très puissants pour encourager (600-800px)
	{"x": 479, "y": 982, "nom": "Étoile Filante", "type": "course_rapide", "valeur": 700},
	{"x": 671, "y": 982, "nom": "Téléporteur", "type": "teleportation", "valeur": 750},
	{"x": 1889, "y": 982, "nom": "Boost Magique", "type": "boost", "valeur": 800},
	{"x": 1400, "y": 982, "nom": "Saut Élastique", "type": "saut", "valeur": 650},
	{"x": 1000, "y": 982, "nom": "Multiplicateur", "type": "multiplicateur", "valeur": 600},
	{"x": 2200, "y": 982, "nom": "Bouclier Céleste", "type": "bouclier", "valeur": 900},  # 2200+900=3100 > 2688 (porte) → Monte au 1er étage !
	
	# 1er étage (y=780) - 3 bonus moyens (400-500px)
	{"x": 2204, "y": 780, "nom": "Accélérateur", "type": "course_rapide", "valeur": 450},
	{"x": 1600, "y": 780, "nom": "Ailes d'Ange", "type": "vol", "valeur": 500},
	{"x": 800, "y": 780, "nom": "Tornade Magique", "type": "tornade", "valeur": 400},
	
	# 2ème étage (y=551) - 3 bonus plus faibles (300-400px)
	{"x": 1000, "y": 551, "nom": "Saut Quantique", "type": "vol", "valeur": 350},
	{"x": 1800, "y": 551, "nom": "Éclair Divin", "type": "course_rapide", "valeur": 400},
	{"x": 500, "y": 551, "nom": "Boost Suprême", "type": "boost", "valeur": 300},
	
	# 3ème étage (y=348) - 1 bonus faible (300px) - très difficile
	{"x": 1500, "y": 348, "nom": "Vitesse Lumière", "type": "teleportation", "valeur": 300},
	
	# 4ème étage final (y=180) - Aucun bonus (étage difficile)
]

# Tolérance pour la détection (en pixels)
var tolerance_detection = 25.0

# Référence au path_manager
var path_manager: Node2D

# Marqueurs visuels
var marqueurs_pieges: Array = []
var marqueurs_bonus: Array = []

# Historique des positions pour détection de vraies boucles infinies
var historique_positions_cascade: Array = []

func _ready():
	print("=== INITIALISATION GESTIONNAIRE PIÈGES/BONUS ===")
	
	# Trouver le path_manager
	path_manager = get_node("../path_manager")
	if path_manager:
		print("✅ Path manager trouvé")
		# Se connecter au signal de fin de déplacement
		path_manager.deplacement_termine.connect(_sur_deplacement_termine)
	else:
		print("❌ Path manager non trouvé")
	
	# Créer immédiatement un marqueur de test
	_creer_marqueur_test_immediat()
	
	# Attendre un peu puis créer les vrais marqueurs
	call_deferred("_creer_marqueurs_visuels")
	
	print("=== FIN INITIALISATION ===")

func _creer_marqueur_test_immediat():
	"""Créer un marqueur de test immédiatement pour vérifier l'affichage"""
	print("Création marqueur de test GÉANT...")
	
	# Marqueur géant impossible à rater avec couleurs douces
	var marqueur_test = ColorRect.new()
	marqueur_test.color = Color(0.7, 0.5, 0.8, 0.9)  # Magenta doux et semi-transparent
	marqueur_test.size = Vector2(120, 120)  # Plus gros
	marqueur_test.position = Vector2(600, 200)  # Position centrale
	marqueur_test.name = "MarqueurTestImmediat"
	add_child(marqueur_test)
	
	# Bordure douce pour contraste
	var bordure_test = ColorRect.new()
	bordure_test.color = Color(0.9, 0.9, 0.9, 0.8)  # Blanc cassé
	bordure_test.size = Vector2(130, 130)
	bordure_test.position = Vector2(595, 195)
	add_child(bordure_test)
	move_child(bordure_test, 0)  # Derrière
	
	var label_test = Label.new()
	label_test.text = "TEST GÉANT!"
	label_test.position = Vector2(620, 160)
	label_test.add_theme_color_override("font_color", Color.WHITE)
	label_test.add_theme_color_override("font_shadow_color", Color.BLACK)
	label_test.add_theme_constant_override("shadow_offset_x", 3)
	label_test.add_theme_constant_override("shadow_offset_y", 3)
	add_child(label_test)
	
	# Animation clignotante douce
	var tween_test = create_tween()
	tween_test.set_loops()
	tween_test.tween_property(marqueur_test, "modulate", Color(0.9, 0.8, 0.6), 0.8)  # Jaune doux
	tween_test.tween_property(marqueur_test, "modulate", Color(0.7, 0.5, 0.8), 0.8)  # Magenta doux
	
	print("✅ Marqueur de test GÉANT créé à (600,200) en magenta clignotant")

func _sur_deplacement_termine(joueur: Node):
	"""Appelé quand le joueur termine son déplacement"""
	if not joueur:
		return
	
	var position_joueur = joueur.global_position
	print("Vérification piège/bonus à la position: %s" % position_joueur)
	
	# Réinitialiser l'historique pour une nouvelle cascade
	historique_positions_cascade.clear()
	
	# Démarrer la cascade d'effets (SANS LIMITE - combos infinis possibles !)
	_verifier_et_appliquer_effets_cascade(joueur, 0)

func verifier_piege(position_joueur: Vector2) -> Dictionary:
	"""Vérifier si le joueur est sur un piège"""
	for piege in pieges:
		var position_piege = Vector2(piege.x, piege.y)
		var distance = position_joueur.distance_to(position_piege)
		
		if distance <= tolerance_detection:
			print("Piège détecté: %s (distance: %f)" % [piege.nom, distance])
			return piege
	
	return {}

func verifier_bonus(position_joueur: Vector2) -> Dictionary:
	"""Vérifier si le joueur est sur un bonus"""
	for bonus_item in bonus:
		var position_bonus = Vector2(bonus_item.x, bonus_item.y)
		var distance = position_joueur.distance_to(position_bonus)
		
		if distance <= tolerance_detection:
			print("Bonus détecté: %s (distance: %f)" % [bonus_item.nom, distance])
			return bonus_item
	
	return {}

const PROFONDEUR_CASCADE_MAX = 30

func _verifier_et_appliquer_effets_cascade(joueur: Node, profondeur: int):
	"""Vérifier et appliquer les effets en cascade - COMBOS INFINIS POSSIBLES !"""
	if not joueur or not is_instance_valid(joueur):
		return

	# Sécurité dure: éviter toute cascade runaway même si la détection de boucle échoue
	if profondeur > PROFONDEUR_CASCADE_MAX:
		print("⚠️ Profondeur cascade max atteinte (%d), arrêt forcé" % profondeur)
		historique_positions_cascade.clear()
		_reinitialiser_sprite_joueur(joueur)
		return

	var position_joueur = joueur.global_position

	# Détection intelligente de boucle infinie :
	# Si on revient EXACTEMENT à la même position 3 fois de suite, c'est une vraie boucle
	var position_arrondie = Vector2(round(position_joueur.x / 10) * 10, round(position_joueur.y / 10) * 10)
	var compte_position = 0
	for pos in historique_positions_cascade:
		if pos.distance_to(position_arrondie) < 15:
			compte_position += 1
	
	if compte_position >= 3:
		print("⚠️ BOUCLE INFINIE détectée (même position visitée 3 fois), arrêt du combo")
		print("💥 COMBO TERMINÉ après %d effets en cascade !" % profondeur)
		historique_positions_cascade.clear()
		return
	
	# Ajouter la position à l'historique (garder seulement les 10 dernières)
	historique_positions_cascade.append(position_arrondie)
	if historique_positions_cascade.size() > 10:
		historique_positions_cascade.pop_front()
	
	if profondeur > 0:
		print("🔄 CASCADE niveau %d - Vérification à la position: %s" % [profondeur, position_joueur])
	
	# Vérifier d'abord les pièges
	var piege_detecte = verifier_piege(position_joueur)
	if piege_detecte:
		appliquer_piege(joueur, piege_detecte)
		# Afficher l'indicateur de combo si profondeur > 1
		if profondeur > 0:
			_afficher_combo(joueur.global_position, profondeur + 1)
		# Après l'animation du piège, vérifier à nouveau (cascade)
		get_tree().create_timer(0.4).timeout.connect(func(): _verifier_et_appliquer_effets_cascade(joueur, profondeur + 1))
		return
	
	# Ensuite vérifier les bonus
	var bonus_detecte = verifier_bonus(position_joueur)
	if bonus_detecte:
		var delai = appliquer_bonus(joueur, bonus_detecte)
		# Afficher l'indicateur de combo si profondeur > 1
		if profondeur > 0:
			_afficher_combo(joueur.global_position, profondeur + 1)
		# Après l'animation du bonus, vérifier à nouveau (cascade)
		get_tree().create_timer(delai).timeout.connect(func(): _verifier_et_appliquer_effets_cascade(joueur, profondeur + 1))
		return
	
	# Si aucun effet détecté, fin de la cascade
	if profondeur > 0:
		print("✅ Fin de la cascade après %d effet(s) - COMBO INCROYABLE !" % profondeur)
		historique_positions_cascade.clear()

	# SÉCURITÉ : Vérifier si le joueur a dépassé la porte (saut par-dessus via combo)
	# Cela évite qu'il reste coincé dans le vide après un gros combo
	_verifier_depassement_porte(joueur)

	# SÉCURITÉ finale: après tous les effets/cascades, garantir que le joueur
	# est visible et avec sa couleur unique (anti-bug disparition/couleur).
	# Délai pour laisser finir les tweens d'animation des effets.
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(joueur):
			_reinitialiser_sprite_joueur(joueur)
	)

func appliquer_piege(joueur: Node, piege: Dictionary):
	"""Appliquer l'effet d'un piège : faire reculer le joueur"""
	print("=== PIÈGE ACTIVÉ: %s ===" % piege.nom)
	print("Le joueur recule de %d pixels" % piege.recul)
	_son("piege")
	
	# Déterminer la direction de recul selon l'étage (comme le système de portes)
	var etage_actuel = 0
	if path_manager.has_method("get_etage_actuel"):
		etage_actuel = path_manager.get_etage_actuel()
	
	# Calculer la nouvelle position de recul
	var nouvelle_position: Vector2
	if etage_actuel % 2 == 0:
		# Étage pair : on se déplaçait vers la droite, donc on recule vers la gauche
		nouvelle_position = joueur.global_position - Vector2(piege.recul, 0)
	else:
		# Étage impair : on se déplaçait vers la gauche, donc on recule vers la droite
		nouvelle_position = joueur.global_position + Vector2(piege.recul, 0)
	
	# Affichage UX : montrer la perte
	_afficher_notification_evenement(joueur.global_position, -piege.recul, piege.nom, false)
	
	# Déplacer le joueur instantanément
	joueur.global_position = nouvelle_position
	print("Joueur déplacé vers: %s" % nouvelle_position)
	
	# Animation selon l'étage - plus spectaculaire en montant
	_jouer_animation_piege(joueur, etage_actuel, piege.recul)

func appliquer_bonus(joueur: Node, bonus_item: Dictionary) -> float:
	"""Appliquer l'effet d'un bonus selon son type - Retourne le délai d'animation"""
	print("=== BONUS ACTIVÉ: %s (Type: %s) ===" % [bonus_item.nom, bonus_item.type])
	_son("bonus")
	
	# Déterminer l'étage actuel
	var etage_actuel = 0
	if path_manager.has_method("get_etage_actuel"):
		etage_actuel = path_manager.get_etage_actuel()
	
	# Déterminer le délai selon le type de bonus (durée de l'animation)
	var delai_animation = 0.3
	
	# Affichage UX : montrer le gain
	_afficher_notification_evenement(joueur.global_position, bonus_item.valeur, bonus_item.nom, true)
	
	# Appliquer l'effet selon le type de bonus
	match bonus_item.type:
		"avance":
			_appliquer_effet_avance(joueur, bonus_item, etage_actuel)
			delai_animation = 0.1  # Instantané
		"course_rapide":
			_appliquer_effet_course_rapide(joueur, bonus_item, etage_actuel)
			# Délai variable selon le bonus
			if "Étoile Filante" in bonus_item.nom:
				delai_animation = 0.5
			elif "Éclair Divin" in bonus_item.nom:
				delai_animation = 0.6
			else:
				delai_animation = 0.8
		"teleportation":
			_appliquer_effet_teleportation(joueur, bonus_item, etage_actuel)
			delai_animation = 0.6
		"vol":
			_appliquer_effet_vol(joueur, bonus_item, etage_actuel)
			delai_animation = 1.5
		"saut":
			_appliquer_effet_saut(joueur, bonus_item, etage_actuel)
			delai_animation = 1.1
		"boost":
			_appliquer_effet_boost(joueur, bonus_item, etage_actuel)
			delai_animation = 0.6
		"multiplicateur":
			_appliquer_effet_multiplicateur(joueur, bonus_item, etage_actuel)
			delai_animation = 1.1
		"bouclier":
			_appliquer_effet_bouclier(joueur, bonus_item, etage_actuel)
			delai_animation = 0.8
		"tornade":
			_appliquer_effet_tornade(joueur, bonus_item, etage_actuel)
			delai_animation = 1.1
		_:
			# Type par défaut : avance simple
			_appliquer_effet_avance(joueur, bonus_item, etage_actuel)
			delai_animation = 0.1
	
	# Animation selon le type et l'étage
	_jouer_animation_bonus_par_type(joueur, bonus_item.type, etage_actuel, bonus_item.valeur, bonus_item.nom)
	
	return delai_animation

# === FONCTIONS POUR LES DIFFÉRENTS TYPES D'EFFETS DE BONUS ===

func _appliquer_effet_avance(joueur: Node, bonus_item: Dictionary, etage_actuel: int):
	"""Effet classique : avance simple dans la direction de progression"""
	print("💨 Effet AVANCE de %d pixels" % bonus_item.valeur)
	
	var nouvelle_position: Vector2
	if etage_actuel % 2 == 0:
		# Étage pair : on se déplace vers la droite
		nouvelle_position = joueur.global_position + Vector2(bonus_item.valeur, 0)
	else:
		# Étage impair : on se déplace vers la gauche
		nouvelle_position = joueur.global_position - Vector2(bonus_item.valeur, 0)
	
	joueur.global_position = nouvelle_position
	print("Joueur avancé vers: %s" % nouvelle_position)

func _appliquer_effet_course_rapide(joueur: Node, bonus_item: Dictionary, etage_actuel: int):
	"""Effet course rapide : le joueur court vite devant avec animation progressive"""
	print("🏃 Effet COURSE RAPIDE de %d pixels" % bonus_item.valeur)
	
	var position_depart = joueur.global_position
	var nouvelle_position: Vector2
	
	if etage_actuel % 2 == 0:
		nouvelle_position = position_depart + Vector2(bonus_item.valeur, 0)
	else:
		nouvelle_position = position_depart - Vector2(bonus_item.valeur, 0)
	
	# Déterminer l'intensité selon le nom du bonus
	var duree_course = 0.8  # Par défaut
	var vitesse_sprite = 3.0  # Par défaut
	
	if "Étoile Filante" in bonus_item.nom:
		# Plus plus rapide
		duree_course = 0.4
		vitesse_sprite = 5.0
		print("⚡ Mode ULTRA RAPIDE activé !")
	elif "Éclair Divin" in bonus_item.nom:
		# Plus rapide
		duree_course = 0.5
		vitesse_sprite = 4.0
		print("⚡ Mode PLUS RAPIDE activé !")
	else:
		# Rapide (Accélérateur)
		duree_course = 0.7
		vitesse_sprite = 3.5
		print("⚡ Mode RAPIDE activé !")
	
	# Animation de course rapide progressive
	var tween_course = create_tween()
	tween_course.tween_property(joueur, "global_position", nouvelle_position, duree_course)
	
	# Effet de vitesse avec sprite animé
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		# Accélérer l'animation pendant la course
		var vitesse_originale = sprite.speed_scale
		sprite.speed_scale = vitesse_sprite
		tween_course.tween_callback(func(): sprite.speed_scale = vitesse_originale).set_delay(duree_course)
	
	print("Joueur court rapidement vers: %s" % nouvelle_position)

func _appliquer_effet_teleportation(joueur: Node, bonus_item: Dictionary, etage_actuel: int):
	"""Effet téléportation : disparition puis réapparition instantanée"""
	print("⚡ Effet TÉLÉPORTATION de %d pixels" % bonus_item.valeur)
	
	var position_depart = joueur.global_position
	var nouvelle_position: Vector2
	
	if etage_actuel % 2 == 0:
		nouvelle_position = position_depart + Vector2(bonus_item.valeur, 0)
	else:
		nouvelle_position = position_depart - Vector2(bonus_item.valeur, 0)
	
	# Effet de téléportation avec fade out/in
	# IMPORTANT: on anime le sprite (pas le noeud joueur) pour ne pas affecter la couleur unique via modulate du parent.
	var sprite_tp: AnimatedSprite2D = null
	if joueur.has_node("AnimatedSprite2D"):
		sprite_tp = joueur.get_node("AnimatedSprite2D")
	var tween_teleport = create_tween()
	tween_teleport.set_parallel(true)

	# Disparition rapide (via joueur.modulate.a uniquement pour préserver la couleur)
	tween_teleport.tween_property(joueur, "modulate:a", 0.0, 0.15)
	tween_teleport.tween_property(joueur, "scale", Vector2(0.1, 0.1), 0.15)

	# Téléportation instantanée au milieu + son
	tween_teleport.tween_callback(func():
		joueur.global_position = nouvelle_position
		if Engine.has_singleton("SoundManager") or get_tree().root.has_node("SoundManager"):
			get_tree().root.get_node("SoundManager").jouer("teleport")
	).set_delay(0.15)

	# Réapparition spectaculaire (alpha seulement)
	tween_teleport.tween_property(joueur, "modulate:a", 1.0, 0.3).set_delay(0.15)
	tween_teleport.tween_property(joueur, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.15)
	
	# Callback de sécurité pour la téléportation
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		tween_teleport.tween_callback(func(): _reinitialiser_sprite_joueur(joueur)).set_delay(0.5)
	
	print("Joueur téléporté vers: %s" % nouvelle_position)

func _appliquer_effet_vol(joueur: Node, bonus_item: Dictionary, etage_actuel: int):
	"""Effet vol : le joueur s'élève puis avance en volant"""
	print("🕊️ Effet VOL de %d pixels" % bonus_item.valeur)
	
	var position_depart = joueur.global_position
	var nouvelle_position: Vector2
	
	if etage_actuel % 2 == 0:
		nouvelle_position = position_depart + Vector2(bonus_item.valeur, 0)
	else:
		nouvelle_position = position_depart - Vector2(bonus_item.valeur, 0)
	
	# Déterminer la hauteur selon le nom du bonus
	var hauteur_vol = 40  # Par défaut
	
	if "Saut Quantique" in bonus_item.nom:
		# Plus haut
		hauteur_vol = 80
		print("🚀 Mode VOL PLUS HAUT activé !")
	elif "Ailes d'Ange" in bonus_item.nom:
		# Haut
		hauteur_vol = 60
		print("🕊️ Mode VOL HAUT activé !")
	else:
		# Hauteur standard
		hauteur_vol = 40 + (etage_actuel * 15)
	
	# Animation de vol : montée, vol horizontal, descente
	var tween_vol = create_tween()
	
	# Phase 1: Montée
	var position_vol = Vector2(position_depart.x, position_depart.y - hauteur_vol)
	tween_vol.tween_property(joueur, "global_position", position_vol, 0.4)
	
	# Phase 2: Vol horizontal
	var position_vol_fin = Vector2(nouvelle_position.x, nouvelle_position.y - hauteur_vol)
	tween_vol.tween_property(joueur, "global_position", position_vol_fin, 0.6)
	
	# Phase 3: Descente douce
	tween_vol.tween_property(joueur, "global_position", nouvelle_position, 0.4)
	
	# Effet visuel de battement d'ailes (sans boucle infinie)
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		var tween_ailes = create_tween()
		# Oscillation rapide pour simuler le battement d'ailes - DURÉE LIMITÉE
		for i in range(7):  # 7 battements pendant le vol
			tween_ailes.tween_property(sprite, "rotation", PI/6, 0.1)
			tween_ailes.tween_property(sprite, "rotation", -PI/6, 0.1)
		# S'assurer que la rotation revient à 0 à la fin
		tween_ailes.tween_property(sprite, "rotation", 0, 0.2)
		
		# Callback de sécurité pour remettre toutes les propriétés à zéro
		tween_ailes.tween_callback(func(): _reinitialiser_sprite_joueur(joueur)).set_delay(1.6)
	
	print("Joueur vole vers: %s" % nouvelle_position)

func _appliquer_effet_saut(joueur: Node, bonus_item: Dictionary, etage_actuel: int):
	"""Effet saut : le joueur fait un saut spectaculaire avec rebond"""
	print("🦘 Effet SAUT de %d pixels" % bonus_item.valeur)
	
	var position_depart = joueur.global_position
	var nouvelle_position: Vector2
	
	if etage_actuel % 2 == 0:
		nouvelle_position = position_depart + Vector2(bonus_item.valeur, 0)
	else:
		nouvelle_position = position_depart - Vector2(bonus_item.valeur, 0)
	
	# Animation de saut avec rebond : montée, atterrissage, petit rebond
	var tween_saut = create_tween()
	var hauteur_saut = 60 + (etage_actuel * 10)
	
	# Phase 1: Montée du saut
	var position_saut = Vector2(position_depart.x, position_depart.y - hauteur_saut)
	tween_saut.tween_property(joueur, "global_position", position_saut, 0.3)
	
	# Phase 2: Atterrissage à la nouvelle position
	var position_atterrissage = Vector2(nouvelle_position.x, nouvelle_position.y)
	tween_saut.tween_property(joueur, "global_position", position_atterrissage, 0.4)
	
	# Phase 3: Petit rebond
	var position_rebond = Vector2(nouvelle_position.x, nouvelle_position.y - hauteur_saut * 0.3)
	tween_saut.tween_property(joueur, "global_position", position_rebond, 0.15)
	tween_saut.tween_property(joueur, "global_position", nouvelle_position, 0.15)
	
	# Effet visuel de rotation pendant le saut
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		var tween_rotation = create_tween()
		tween_rotation.tween_property(sprite, "rotation", PI * 1.5, 0.7)
		tween_rotation.tween_property(sprite, "rotation", 0, 0.3).set_delay(0.7)
		tween_rotation.tween_callback(func(): _reinitialiser_sprite_joueur(joueur)).set_delay(1.0)
	
	print("Joueur saute vers: %s" % nouvelle_position)

func _appliquer_effet_boost(joueur: Node, bonus_item: Dictionary, etage_actuel: int):
	"""Effet boost : propulsion rapide avec effet de traînée"""
	print("🚀 Effet BOOST de %d pixels" % bonus_item.valeur)
	
	var position_depart = joueur.global_position
	var nouvelle_position: Vector2
	
	if etage_actuel % 2 == 0:
		nouvelle_position = position_depart + Vector2(bonus_item.valeur, 0)
	else:
		nouvelle_position = position_depart - Vector2(bonus_item.valeur, 0)
	
	# Animation de boost très rapide avec effet de traînée
	var tween_boost = create_tween()
	tween_boost.tween_property(joueur, "global_position", nouvelle_position, 0.5)
	
	# Effet visuel de propulsion
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		# Étirement horizontal pour simuler la vitesse
		var tween_visuel = create_tween()
		tween_visuel.set_parallel(true)
		tween_visuel.tween_property(sprite, "scale", Vector2(1.8, 0.6), 0.25)
		tween_visuel.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.25).set_delay(0.25)
		
		# Flash orange/rouge pour l'effet de propulsion
		var couleurs_boost = [Color(0.9, 0.6, 0.3), Color(0.9, 0.4, 0.2), Color(0.8, 0.3, 0.1)]
		for i in range(couleurs_boost.size()):
			tween_visuel.tween_property(sprite, "modulate", couleurs_boost[i], 0.1).set_delay(i * 0.1)
		tween_visuel.tween_property(sprite, "modulate", _couleur_joueur(joueur), 0.2).set_delay(0.3)
		tween_visuel.tween_callback(func(): _reinitialiser_sprite_joueur(joueur)).set_delay(0.5)
	
	print("Joueur boosté vers: %s" % nouvelle_position)

func _appliquer_effet_multiplicateur(joueur: Node, bonus_item: Dictionary, etage_actuel: int):
	"""Effet multiplicateur : avance double avec effet visuel spécial"""
	print("✨ Effet MULTIPLICATEUR de %d pixels (x2 = %d)" % [bonus_item.valeur, bonus_item.valeur * 2])
	
	var position_depart = joueur.global_position
	var valeur_double = bonus_item.valeur * 2
	var nouvelle_position: Vector2
	
	if etage_actuel % 2 == 0:
		nouvelle_position = position_depart + Vector2(valeur_double, 0)
	else:
		nouvelle_position = position_depart - Vector2(valeur_double, 0)
	
	# Animation de multiplicateur : avance progressive avec effet de multiplication
	var tween_mult = create_tween()
	tween_mult.tween_property(joueur, "global_position", nouvelle_position, 1.0)
	
	# Effet visuel spécial de multiplication
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		var tween_visuel = create_tween()
		tween_visuel.set_parallel(true)
		
		# Pulsation avec effet de multiplication
		for i in range(3):
			tween_visuel.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.15).set_delay(i * 0.2)
			tween_visuel.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15).set_delay(i * 0.2 + 0.15)
		
		# Couleurs dorées pour l'effet de multiplication
		var couleurs_mult = [Color(0.9, 0.8, 0.3), Color(0.9, 0.9, 0.5), Color(0.8, 0.7, 0.4)]
		for i in range(couleurs_mult.size()):
			tween_visuel.tween_property(sprite, "modulate", couleurs_mult[i], 0.2).set_delay(i * 0.2)
		tween_visuel.tween_property(sprite, "modulate", _couleur_joueur(joueur), 0.3).set_delay(0.6)
		tween_visuel.tween_callback(func(): _reinitialiser_sprite_joueur(joueur)).set_delay(1.0)
	
	print("Joueur multiplié vers: %s" % nouvelle_position)

func _appliquer_effet_bouclier(joueur: Node, bonus_item: Dictionary, etage_actuel: int):
	"""Effet bouclier : avance protégée avec effet de bouclier autour du joueur"""
	print("🛡️ Effet BOUCLIER de %d pixels" % bonus_item.valeur)
	
	var position_depart = joueur.global_position
	var nouvelle_position: Vector2
	
	if etage_actuel % 2 == 0:
		nouvelle_position = position_depart + Vector2(bonus_item.valeur, 0)
	else:
		nouvelle_position = position_depart - Vector2(bonus_item.valeur, 0)
	
	# Animation de bouclier : avance avec effet protecteur
	var tween_bouclier = create_tween()
	tween_bouclier.tween_property(joueur, "global_position", nouvelle_position, 0.7)
	
	# Effet visuel de bouclier
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		var tween_visuel = create_tween()
		tween_visuel.set_parallel(true)
		
		# Effet de bouclier : pulsation bleue/cyan
		var couleurs_bouclier = [Color(0.4, 0.7, 0.9), Color(0.5, 0.8, 0.9), Color(0.6, 0.9, 0.9)]
		for i in range(4):
			for couleur in couleurs_bouclier:
				tween_visuel.tween_property(sprite, "modulate", couleur, 0.1).set_delay(i * 0.3 + couleurs_bouclier.find(couleur) * 0.1)
		
		# Légère pulsation pour simuler le bouclier
		for i in range(3):
			tween_visuel.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.2).set_delay(i * 0.2)
			tween_visuel.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2).set_delay(i * 0.2 + 0.2)
		
		tween_visuel.tween_property(sprite, "modulate", _couleur_joueur(joueur), 0.2).set_delay(0.7)
		tween_visuel.tween_callback(func(): _reinitialiser_sprite_joueur(joueur)).set_delay(0.7)
	
	print("Joueur protégé vers: %s" % nouvelle_position)

func _appliquer_effet_tornade(joueur: Node, bonus_item: Dictionary, etage_actuel: int):
	"""Effet tornade : le joueur tourne en spirale pendant l'avance"""
	print("🌪️ Effet TORNADE de %d pixels" % bonus_item.valeur)
	
	var position_depart = joueur.global_position
	var nouvelle_position: Vector2
	
	if etage_actuel % 2 == 0:
		nouvelle_position = position_depart + Vector2(bonus_item.valeur, 0)
	else:
		nouvelle_position = position_depart - Vector2(bonus_item.valeur, 0)
	
	# Animation de tornade : rotation en spirale pendant l'avance avec oscillation verticale
	var tween_tornade = create_tween()
	var position_initiale = joueur.global_position
	
	# Créer un mouvement en spirale avec oscillation verticale
	for i in range(9):
		var offset_y = sin(i * 0.7) * 20
		var pos_spirale = Vector2(
			lerp(position_depart.x, nouvelle_position.x, i / 9.0),
			position_depart.y + offset_y
		)
		tween_tornade.tween_property(joueur, "global_position", pos_spirale, 0.1)
	
	# S'assurer qu'on arrive exactement à la nouvelle position
	tween_tornade.tween_property(joueur, "global_position", nouvelle_position, 0.1)
	
	# Effet visuel de tornade : rotation multiple
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		var tween_rotation = create_tween()
		
		# Rotation multiple pour simuler la tornade
		var rotations = 3 + etage_actuel
		tween_rotation.tween_property(sprite, "rotation", rotations * 2 * PI, 1.0)
		tween_rotation.tween_property(sprite, "rotation", 0, 0.2).set_delay(1.0)
		
		# Couleurs tourbillonnantes
		var tween_couleurs = create_tween()
		var couleurs_tornade = [Color(0.7, 0.8, 0.9), Color(0.8, 0.7, 0.9), Color(0.9, 0.8, 0.7)]
		for i in range(couleurs_tornade.size()):
			tween_couleurs.tween_property(sprite, "modulate", couleurs_tornade[i], 0.3).set_delay(i * 0.3)
		tween_couleurs.tween_property(sprite, "modulate", _couleur_joueur(joueur), 0.2).set_delay(1.0)
		tween_couleurs.tween_callback(func(): _reinitialiser_sprite_joueur(joueur)).set_delay(1.2)
	
	print("Joueur en tornade vers: %s" % nouvelle_position)

func _son(nom: String) -> void:
	# Wrapper sûr pour jouer un son via l'autoload SoundManager.
	var root = get_tree().root
	if root.has_node("SoundManager"):
		root.get_node("SoundManager").jouer(nom)

func _couleur_joueur(joueur: Node) -> Color:
	# Retourne la couleur unique du joueur pour préserver son identité visuelle
	# (utilisée comme cible finale des tweens de modulate sur le sprite).
	if joueur and is_instance_valid(joueur) and "couleur_personnage" in joueur:
		return joueur.couleur_personnage
	return Color.WHITE

func _reinitialiser_sprite_joueur(joueur: Node):
	"""Remet le joueur dans son état normal après un effet.
	Restaure visibilité, échelle, rotation, speed_scale ET la couleur unique du joueur.
	Ne PAS remettre modulate à Color.WHITE seul: ça efface la couleur hash du personnage."""
	if not joueur or not is_instance_valid(joueur):
		return
	if joueur.has_method("restaurer_apparence"):
		joueur.restaurer_apparence()
	else:
		# Fallback si on reçoit directement un sprite (ancien code)
		if joueur is CanvasItem:
			joueur.rotation = 0.0
			joueur.scale = Vector2.ONE
			joueur.modulate = Color.WHITE
			joueur.visible = true
			if joueur is AnimatedSprite2D:
				joueur.speed_scale = 1.0
	print("🔧 Apparence du joueur restaurée")

func _verifier_depassement_porte(joueur: Node):
	"""Vérifier si le joueur a dépassé la porte (saut par-dessus via combo) et le téléporter si nécessaire"""
	if not joueur or not is_instance_valid(joueur):
		return
	
	if not path_manager:
		return
	
	var etage_actuel = 0
	if path_manager.has_method("get_etage_actuel"):
		etage_actuel = path_manager.get_etage_actuel()
	
	# Obtenir la configuration de la porte pour l'étage actuel
	var configuration_etages = {
		0: {"porte_x": 2688, "direction": 1},   # Rez-de-chaussée → porte à droite
		1: {"porte_x": -48, "direction": -1},   # 1er étage → porte à gauche
		2: {"porte_x": 2688, "direction": 1},   # 2ème étage → porte à droite
		3: {"porte_x": 4224, "direction": 1},   # 3ème étage → porte à droite
	}
	
	if not configuration_etages.has(etage_actuel):
		return
	
	var config = configuration_etages[etage_actuel]
	var position_porte = config["porte_x"]
	var direction = config["direction"]  # 1 = vers la droite, -1 = vers la gauche
	
	var position_joueur = joueur.global_position.x
	
	# Vérifier si le joueur a dépassé la porte dans la bonne direction
	var a_depasse = false
	if direction == 1 and position_joueur > position_porte:
		# Étage pair : le joueur va vers la droite et a dépassé la porte
		a_depasse = true
	elif direction == -1 and position_joueur < position_porte:
		# Étage impair : le joueur va vers la gauche et a dépassé la porte
		a_depasse = true
	
	if a_depasse:
		print("🚨 DÉPASSEMENT DE PORTE DÉTECTÉ ! Position joueur: %f, Porte: %f, Étage: %d" % [position_joueur, position_porte, etage_actuel])
		print("   Le joueur a sauté par-dessus la porte grâce au combo !")
		
		# Forcer la téléportation vers l'étage supérieur
		if path_manager.has_method("teleporter_vers_etage_superieur"):
			path_manager.teleporter_vers_etage_superieur()
			print("   ✅ Joueur téléporté vers l'étage supérieur")

func _jouer_animation_piege(joueur: Node, etage: int = 0, recul: int = 100):
	"""Animation spectaculaire pour signaler qu'un piège a été activé"""
	if not joueur:
		return
	
	# Intensité basée sur l'étage
	var intensite = 1.0 + (etage * 0.5)  # Plus intense à chaque étage
	var tremblements = 8 + (etage * 3)   # Plus de tremblements par étage
	
	print("🔴 ANIMATION PIÈGE ÉTAGE %d - INTENSITÉ x%.1f !" % [etage, intensite])
	
	# Animation spectaculaire : tremblement intense + effet de rotation
	var position_initiale = joueur.global_position
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Effet de tremblement qui s'intensifie par étage
	for i in range(tremblements):
		var amplitude = 15 * intensite
		var offset = Vector2(randf_range(-amplitude, amplitude), randf_range(-amplitude/2, amplitude/2))
		tween.tween_property(joueur, "global_position", position_initiale + offset, 0.06)
	
	# Rotation plus intense aux étages élevés
	var rotation_max = (PI/4) * intensite
	tween.tween_property(joueur, "rotation", rotation_max, 0.3)
	tween.tween_property(joueur, "rotation", 0, 0.3).set_delay(0.3)
	
	# Retour à la position
	tween.tween_property(joueur, "global_position", position_initiale, 0.2).set_delay(0.8)
	
	# Couleurs plus dramatiques selon l'étage
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		var couleurs_piege = [
			[Color(0.7, 0.4, 0.4), Color(0.5, 0.3, 0.3)],           # Rouge doux
			[Color(0.8, 0.5, 0.3), Color(0.6, 0.4, 0.2)],           # Orange doux  
			[Color(0.6, 0.4, 0.7), Color(0.4, 0.3, 0.5)],           # Violet doux
			[Color(0.4, 0.4, 0.4), Color(0.6, 0.3, 0.3)],           # Gris sombre avec rouge
			[Color(0.6, 0.3, 0.6), Color(0.4, 0.4, 0.4)]            # Magenta doux
		]
		var couleur_set = couleurs_piege[min(etage, 4)]
		
		# Flash coloré intense selon l'étage
		for i in range(int(2 + etage)):
			tween.tween_property(sprite, "modulate", couleur_set[0], 0.08)
			tween.tween_property(sprite, "modulate", couleur_set[1], 0.08).set_delay(0.08 * (i*2+1))
		
		tween.tween_property(sprite, "modulate", _couleur_joueur(joueur), 0.4).set_delay(0.6)
		
		# Grossissement plus important aux étages élevés
		var scale_max = 1.5 + (etage * 0.3)
		tween.tween_property(sprite, "scale", Vector2(scale_max, scale_max), 0.2)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.4).set_delay(0.2)
	
	# Particules spéciales pour les étages élevés
	if etage >= 2:
		_creer_effet_particules_piege_avance(position_initiale, etage)

func _jouer_animation_bonus_par_type(joueur: Node, type: String, etage: int = 0, valeur: int = 100, nom_bonus: String = ""):
	"""Animation spécifique selon le type de bonus"""
	if not joueur:
		return
	
	print("🎨 Animation bonus type: %s" % type)
	
	match type:
		"avance":
			_animation_bonus_avance(joueur, etage, valeur)
		"course_rapide":
			_animation_bonus_course_rapide(joueur, etage, valeur, nom_bonus)
		"teleportation":
			_animation_bonus_teleportation(joueur, etage, valeur)
		"vol":
			_animation_bonus_vol(joueur, etage, valeur, nom_bonus)
		"saut":
			_animation_bonus_saut(joueur, etage, valeur)
		"boost":
			_animation_bonus_boost(joueur, etage, valeur)
		"multiplicateur":
			_animation_bonus_multiplicateur(joueur, etage, valeur)
		"bouclier":
			_animation_bonus_bouclier(joueur, etage, valeur)
		"tornade":
			_animation_bonus_tornade(joueur, etage, valeur)
		_:
			_animation_bonus_avance(joueur, etage, valeur)

func _animation_bonus_avance(joueur: Node, etage: int, valeur: int):
	"""Animation pour bonus d'avance classique"""
	var intensite = 1.0 + (etage * 0.4)
	print("🟢 ANIMATION AVANCE CLASSIQUE - INTENSITÉ x%.1f !" % intensite)
	
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Flash vert doux
		var couleur_verte = Color(0.6, 0.9, 0.6, 0.9)
		tween.tween_property(sprite, "modulate", couleur_verte, 0.2)
		tween.tween_property(sprite, "modulate", _couleur_joueur(joueur), 0.3).set_delay(0.2)
		
		# Légère pulsation
		tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.2)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.2)

func _animation_bonus_course_rapide(joueur: Node, etage: int, valeur: int, nom_bonus: String = ""):
	"""Animation pour bonus de course rapide avec intensité variable"""
	print("🏃 ANIMATION COURSE RAPIDE !")
	
	# Déterminer l'intensité selon le nom
	var intensite_etirement = 1.5  # Par défaut
	var duree_animation = 0.3  # Par défaut
	var nombre_particules = 8 + etage * 3  # Par défaut
	
	if "Étoile Filante" in nom_bonus:
		# Plus plus rapide - effet très intense
		intensite_etirement = 2.2
		duree_animation = 0.2
		nombre_particules = 15 + etage * 5
		print("⚡⚡ Mode ULTRA RAPIDE - Animation maximale !")
	elif "Éclair Divin" in nom_bonus:
		# Plus rapide - effet intense
		intensite_etirement = 1.8
		duree_animation = 0.25
		nombre_particules = 12 + etage * 4
		print("⚡ Mode PLUS RAPIDE - Animation intense !")
	else:
		# Rapide - effet standard
		intensite_etirement = 1.5
		duree_animation = 0.3
		nombre_particules = 8 + etage * 3
		print("⚡ Mode RAPIDE - Animation standard !")
	
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Effet de traînée avec changements de couleur rapides
		var couleurs_vitesse = [Color(0.9, 0.8, 0.3), Color(0.8, 0.9, 0.4), Color(0.7, 0.8, 0.9)]  # Jaune, vert, bleu doux
		for i in range(couleurs_vitesse.size()):
			tween.tween_property(sprite, "modulate", couleurs_vitesse[i], 0.15).set_delay(i * 0.15)
		tween.tween_property(sprite, "modulate", _couleur_joueur(joueur), 0.2).set_delay(0.45)
		
		# Étirement horizontal pour simuler la vitesse (intensité variable)
		tween.tween_property(sprite, "scale", Vector2(intensite_etirement, 0.8), duree_animation)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.4).set_delay(duree_animation)
		
		# Particules de vitesse (nombre variable)
		_creer_particules_vitesse_intensite(joueur.global_position, etage, nombre_particules)

func _animation_bonus_teleportation(joueur: Node, etage: int, valeur: int):
	"""Animation pour bonus de téléportation"""
	print("⚡ ANIMATION TÉLÉPORTATION !")
	
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Flash électrique avec couleurs cyan/magenta douces
		var couleurs_teleport = [Color(0.6, 0.9, 0.9), Color(0.9, 0.6, 0.9), Color(0.9, 0.9, 0.9)]  # Cyan, magenta, blanc doux
		for i in range(3):
			for couleur in couleurs_teleport:
				tween.tween_property(sprite, "modulate", couleur, 0.05).set_delay(i * 0.15 + couleurs_teleport.find(couleur) * 0.05)
		
		# Effet de scintillement
		for i in range(5):
			tween.tween_property(sprite, "modulate", Color.TRANSPARENT, 0.03).set_delay(i * 0.1)
			tween.tween_property(sprite, "modulate", _couleur_joueur(joueur), 0.03).set_delay(i * 0.1 + 0.03)
		
		# Particules de téléportation
		_creer_particules_teleportation(joueur.global_position, etage)

func _animation_bonus_vol(joueur: Node, etage: int, valeur: int, nom_bonus: String = ""):
	"""Animation pour bonus de vol avec hauteur variable"""
	print("🕊️ ANIMATION VOL !")
	
	# Déterminer l'intensité selon le nom
	var nombre_oscillations = 6  # Par défaut
	var nombre_particules = 12 + etage * 4  # Par défaut
	
	if "Saut Quantique" in nom_bonus:
		# Plus haut - effet très intense
		nombre_oscillations = 10
		nombre_particules = 20 + etage * 6
		print("🚀 Mode VOL PLUS HAUT - Animation maximale !")
	elif "Ailes d'Ange" in nom_bonus:
		# Haut - effet intense
		nombre_oscillations = 8
		nombre_particules = 16 + etage * 5
		print("🕊️ Mode VOL HAUT - Animation intense !")
	else:
		# Standard
		nombre_oscillations = 6
		nombre_particules = 12 + etage * 4
		print("🕊️ Mode VOL STANDARD - Animation normale !")
	
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Couleurs aériennes douces
		var couleurs_vol = [Color(0.8, 0.9, 0.9), Color(0.9, 0.9, 0.8), Color(0.9, 0.8, 0.9)]  # Bleu ciel, jaune doux, rose doux
		for i in range(couleurs_vol.size()):
			tween.tween_property(sprite, "modulate", couleurs_vol[i], 0.3).set_delay(i * 0.3)
		tween.tween_property(sprite, "modulate", _couleur_joueur(joueur), 0.3).set_delay(0.9)
		
		# Effet de lévitation avec oscillation contrôlée (nombre variable)
		for i in range(nombre_oscillations):
			tween.tween_property(sprite, "scale", Vector2(1.2, 0.9), 0.2).set_delay(i * 0.2)
			tween.tween_property(sprite, "scale", Vector2(0.9, 1.2), 0.2).set_delay(i * 0.2 + 0.1)
		# S'assurer que le scale revient exactement à la normale
		var duree_totale = nombre_oscillations * 0.2 + 0.1
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.3).set_delay(duree_totale)
		
		# Particules de plumes (nombre variable)
		_creer_particules_vol_intensite(joueur.global_position, etage, nombre_particules)

func _animation_bonus_saut(joueur: Node, etage: int, valeur: int):
	"""Animation pour bonus de saut"""
	print("🦘 ANIMATION SAUT !")
	
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Couleurs dynamiques pour le saut
		var couleurs_saut = [Color(0.8, 0.9, 0.6), Color(0.9, 0.8, 0.5), Color(0.7, 0.9, 0.7)]  # Vert clair, jaune doux
		for i in range(couleurs_saut.size()):
			tween.tween_property(sprite, "modulate", couleurs_saut[i], 0.2).set_delay(i * 0.2)
		tween.tween_property(sprite, "modulate", _couleur_joueur(joueur), 0.3).set_delay(0.6)
		
		# Particules de saut
		_creer_particules_saut(joueur.global_position, etage)

func _animation_bonus_boost(joueur: Node, etage: int, valeur: int):
	"""Animation pour bonus de boost"""
	print("🚀 ANIMATION BOOST !")
	
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Flash orange/rouge intense
		var couleurs_boost = [Color(0.9, 0.5, 0.2), Color(0.9, 0.3, 0.1), Color(0.8, 0.2, 0.1)]
		for i in range(couleurs_boost.size()):
			tween.tween_property(sprite, "modulate", couleurs_boost[i], 0.1).set_delay(i * 0.1)
		tween.tween_property(sprite, "modulate", _couleur_joueur(joueur), 0.2).set_delay(0.3)
		
		# Particules de boost
		_creer_particules_boost(joueur.global_position, etage)

func _animation_bonus_multiplicateur(joueur: Node, etage: int, valeur: int):
	"""Animation pour bonus multiplicateur"""
	print("✨ ANIMATION MULTIPLICATEUR !")
	
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Couleurs dorées pour l'effet de multiplication
		var couleurs_mult = [Color(0.9, 0.8, 0.3), Color(0.9, 0.9, 0.5), Color(0.8, 0.7, 0.4)]
		for i in range(2):  # Répéter pour l'effet de multiplication
			for couleur in couleurs_mult:
				tween.tween_property(sprite, "modulate", couleur, 0.15).set_delay(i * 0.45 + couleurs_mult.find(couleur) * 0.15)
		tween.tween_property(sprite, "modulate", _couleur_joueur(joueur), 0.3).set_delay(0.9)
		
		# Particules dorées
		_creer_particules_multiplicateur(joueur.global_position, etage)

func _animation_bonus_bouclier(joueur: Node, etage: int, valeur: int):
	"""Animation pour bonus bouclier"""
	print("🛡️ ANIMATION BOUCLIER !")
	
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Couleurs bleues/cyan pour l'effet de bouclier
		var couleurs_bouclier = [Color(0.4, 0.7, 0.9), Color(0.5, 0.8, 0.9), Color(0.6, 0.9, 0.9)]
		for i in range(3):
			for couleur in couleurs_bouclier:
				tween.tween_property(sprite, "modulate", couleur, 0.1).set_delay(i * 0.3 + couleurs_bouclier.find(couleur) * 0.1)
		tween.tween_property(sprite, "modulate", _couleur_joueur(joueur), 0.2).set_delay(0.9)
		
		# Particules de bouclier
		_creer_particules_bouclier(joueur.global_position, etage)

func _animation_bonus_tornade(joueur: Node, etage: int, valeur: int):
	"""Animation pour bonus tornade"""
	print("🌪️ ANIMATION TORNADE !")
	
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Couleurs tourbillonnantes
		var couleurs_tornade = [Color(0.7, 0.8, 0.9), Color(0.8, 0.7, 0.9), Color(0.9, 0.8, 0.7)]
		for i in range(couleurs_tornade.size()):
			tween.tween_property(sprite, "modulate", couleurs_tornade[i], 0.3).set_delay(i * 0.3)
		tween.tween_property(sprite, "modulate", _couleur_joueur(joueur), 0.2).set_delay(0.9)
		
		# Particules de tornade
		_creer_particules_tornade(joueur.global_position, etage)

# === FONCTIONS POUR LES PARTICULES SPÉCIFIQUES ===

func _creer_particules_vitesse(position: Vector2, etage: int):
	"""Créer des particules de vitesse pour la course rapide"""
	_creer_particules_vitesse_intensite(position, etage, 8 + etage * 3)

func _creer_particules_vitesse_intensite(position: Vector2, etage: int, nombre: int):
	"""Créer des particules de vitesse avec nombre variable"""
	for i in range(nombre):
		var particule = ColorRect.new()
		particule.size = Vector2(12, 4)  # Forme allongée pour simuler la vitesse
		particule.color = [Color(0.9, 0.8, 0.3), Color(0.8, 0.9, 0.4)][i % 2]  # Jaune/vert doux
		particule.position = position + Vector2(randf_range(-15, 15), randf_range(-10, 10))
		get_parent().add_child(particule)
		
		var tween_part = create_tween()
		# Mouvement rapide vers l'arrière pour simuler la traînée
		tween_part.parallel().tween_property(particule, "position", 
			particule.position + Vector2(randf_range(-80, -40), randf_range(-10, 10)), 0.5)
		tween_part.parallel().tween_property(particule, "modulate", Color.TRANSPARENT, 0.5)
		tween_part.tween_callback(particule.queue_free)

func _creer_particules_teleportation(position: Vector2, etage: int):
	"""Créer des particules électriques pour la téléportation"""
	for i in range(15 + etage * 5):
		var particule = ColorRect.new()
		particule.size = Vector2(6, 6)
		particule.color = [Color(0.6, 0.9, 0.9), Color(0.9, 0.6, 0.9), Color(0.9, 0.9, 0.6)][i % 3]  # Cyan, magenta, jaune doux
		particule.position = position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		get_parent().add_child(particule)
		
		var tween_part = create_tween()
		# Effet d'éclair : mouvement rapide et erratique
		for j in range(4):
			var nouvelle_pos = particule.position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			tween_part.tween_property(particule, "position", nouvelle_pos, 0.1)
		
		tween_part.parallel().tween_property(particule, "modulate", Color.TRANSPARENT, 0.4)
		tween_part.tween_callback(particule.queue_free)

func _creer_particules_vol(position: Vector2, etage: int):
	"""Créer des particules de plumes pour le vol"""
	_creer_particules_vol_intensite(position, etage, 12 + etage * 4)

func _creer_particules_vol_intensite(position: Vector2, etage: int, nombre: int):
	"""Créer des particules de plumes avec nombre variable"""
	for i in range(nombre):
		var particule = ColorRect.new()
		particule.size = Vector2(8, 12)  # Forme de plume
		particule.color = [Color(0.9, 0.9, 0.9), Color(0.8, 0.9, 0.9), Color(0.9, 0.8, 0.9)][i % 3]  # Blanc, bleu ciel, rose doux
		particule.position = position + Vector2(randf_range(-25, 25), randf_range(-15, 15))
		get_parent().add_child(particule)
		
		var tween_part = create_tween()
		# Mouvement de plume : oscillation en montant doucement
		var direction_finale = Vector2(randf_range(-30, 30), randf_range(-60, -30))
		
		# Oscillation pendant la montée
		for j in range(8):
			var pos_oscillation = particule.position + Vector2(sin(j * 0.5) * 10, -j * 8)
			tween_part.tween_property(particule, "position", pos_oscillation, 0.15)
		
		tween_part.parallel().tween_property(particule, "rotation", randf_range(0, PI), 1.2)
		tween_part.parallel().tween_property(particule, "modulate", Color.TRANSPARENT, 1.2)
		tween_part.tween_callback(particule.queue_free)

func _creer_particules_saut(position: Vector2, etage: int):
	"""Créer des particules pour le saut"""
	for i in range(10 + etage * 3):
		var particule = ColorRect.new()
		particule.size = Vector2(6, 10)  # Forme allongée
		particule.color = [Color(0.8, 0.9, 0.6), Color(0.9, 0.8, 0.5)][i % 2]  # Vert clair, jaune doux
		particule.position = position + Vector2(randf_range(-15, 15), randf_range(-10, 10))
		get_parent().add_child(particule)
		
		var tween_part = create_tween()
		var direction = Vector2(randf_range(-0.5, 0.5), -1).normalized()
		var distance = randf_range(60, 100)
		tween_part.parallel().tween_property(particule, "position", 
			particule.position + direction * distance, 0.6)
		tween_part.parallel().tween_property(particule, "modulate", Color.TRANSPARENT, 0.6)
		tween_part.tween_callback(particule.queue_free)

func _creer_particules_boost(position: Vector2, etage: int):
	"""Créer des particules pour le boost"""
	for i in range(12 + etage * 4):
		var particule = ColorRect.new()
		particule.size = Vector2(10, 3)  # Forme allongée horizontale
		particule.color = [Color(0.9, 0.5, 0.2), Color(0.9, 0.3, 0.1), Color(0.8, 0.2, 0.1)][i % 3]  # Orange/rouge
		particule.position = position + Vector2(randf_range(-20, 20), randf_range(-10, 10))
		get_parent().add_child(particule)
		
		var tween_part = create_tween()
		var direction = Vector2(randf_range(-1, -0.3), randf_range(-0.3, 0.3)).normalized()
		var distance = randf_range(80, 120)
		tween_part.parallel().tween_property(particule, "position", 
			particule.position + direction * distance, 0.4)
		tween_part.parallel().tween_property(particule, "modulate", Color.TRANSPARENT, 0.4)
		tween_part.tween_callback(particule.queue_free)

func _creer_particules_multiplicateur(position: Vector2, etage: int):
	"""Créer des particules dorées pour le multiplicateur"""
	for i in range(15 + etage * 5):
		var particule = ColorRect.new()
		particule.size = Vector2(8, 8)
		particule.color = [Color(0.9, 0.8, 0.3), Color(0.9, 0.9, 0.5), Color(0.8, 0.7, 0.4)][i % 3]  # Doré
		particule.position = position + Vector2(randf_range(-25, 25), randf_range(-25, 25))
		get_parent().add_child(particule)
		
		var tween_part = create_tween()
		var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var distance = randf_range(100, 180)
		tween_part.parallel().tween_property(particule, "position", 
			particule.position + direction * distance, 0.8)
		tween_part.parallel().tween_property(particule, "modulate", Color.TRANSPARENT, 0.8)
		tween_part.parallel().tween_property(particule, "rotation", randf_range(0, 4*PI), 0.8)
		tween_part.tween_callback(particule.queue_free)

func _creer_particules_bouclier(position: Vector2, etage: int):
	"""Créer des particules pour le bouclier"""
	for i in range(12 + etage * 4):
		var particule = ColorRect.new()
		particule.size = Vector2(6, 6)
		particule.color = [Color(0.4, 0.7, 0.9), Color(0.5, 0.8, 0.9), Color(0.6, 0.9, 0.9)][i % 3]  # Bleu/cyan
		particule.position = position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		get_parent().add_child(particule)
		
		var tween_part = create_tween()
		# Mouvement circulaire pour simuler le bouclier
		var angle = (i * 2 * PI) / (12 + etage * 4)
		var rayon = randf_range(50, 100)
		for j in range(8):
			var angle_actuel = angle + (j * 0.1)
			var pos_circulaire = position + Vector2(cos(angle_actuel) * rayon, sin(angle_actuel) * rayon)
			tween_part.tween_property(particule, "position", pos_circulaire, 0.1)
		tween_part.parallel().tween_property(particule, "modulate", Color.TRANSPARENT, 0.8)
		tween_part.tween_callback(particule.queue_free)

func _creer_particules_tornade(position: Vector2, etage: int):
	"""Créer des particules pour la tornade"""
	for i in range(18 + etage * 6):
		var particule = ColorRect.new()
		particule.size = Vector2(5, 5)
		particule.color = [Color(0.7, 0.8, 0.9), Color(0.8, 0.7, 0.9), Color(0.9, 0.8, 0.7)][i % 3]  # Couleurs tourbillonnantes
		particule.position = position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		get_parent().add_child(particule)
		
		var tween_part = create_tween()
		# Mouvement en spirale
		var angle_depart = (i * 2 * PI) / (18 + etage * 6)
		for j in range(10):
			var angle_actuel = angle_depart + (j * 0.5)
			var rayon = 30 + (j * 8)
			var pos_spirale = position + Vector2(cos(angle_actuel) * rayon, sin(angle_actuel) * rayon - j * 5)
			tween_part.tween_property(particule, "position", pos_spirale, 0.1)
		tween_part.parallel().tween_property(particule, "modulate", Color.TRANSPARENT, 1.0)
		tween_part.parallel().tween_property(particule, "rotation", randf_range(0, 6*PI), 1.0)
		tween_part.tween_callback(particule.queue_free)

func _jouer_animation_bonus(joueur: Node, etage: int = 0, avance: int = 100):
	"""Animation spectaculaire pour signaler qu'un bonus a été activé"""
	if not joueur:
		return
	
	# Intensité basée sur l'étage
	var intensite = 1.0 + (etage * 0.4)
	var particules_count = 12 + (etage * 8)
	
	print("🟢 ANIMATION BONUS ÉTAGE %d - PUISSANCE x%.1f !" % [etage, intensite])
	
	# Animation spectaculaire : effet de boost avec particules
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Effet de boost ascendant plus impressionnant par étage
	var position_initiale = joueur.global_position
	var hauteur_boost = 30 + (etage * 15)
	tween.tween_property(joueur, "global_position", position_initiale + Vector2(0, -hauteur_boost), 0.3)
	tween.tween_property(joueur, "global_position", position_initiale, 0.3).set_delay(0.3)
	
	# Rotations multiples selon l'étage
	var rotations = 1 + etage
	tween.tween_property(joueur, "rotation", rotations * 2 * PI, 0.6)
	
	# Couleurs plus spectaculaires selon l'étage
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		var couleurs_bonus = [
			[Color(0.6, 0.8, 0.5), Color(0.8, 0.8, 0.5), Color(0.5, 0.7, 0.7)],     # Vert doux, jaune doux, cyan doux
			[Color(0.8, 0.7, 0.4), Color(0.8, 0.6, 0.4), Color(0.8, 0.8, 0.6)],     # Or doux, orange doux
			[Color(0.6, 0.8, 0.8), Color(0.7, 0.6, 0.8), Color(0.9, 0.9, 0.9)],     # Cyan doux, magenta doux
			[Color(0.9, 0.9, 0.9), Color(0.8, 0.7, 0.5), Color(0.7, 0.8, 0.9)],     # Blanc cassé, or pâle
			[Color(0.9, 0.8, 0.6), Color(0.9, 0.9, 0.9), Color(0.9, 0.7, 0.8)]      # Doré pâle, rose pâle
		]
		var couleur_set = couleurs_bonus[min(etage, 4)]
		
		# Séquence de couleurs plus longue aux étages élevés
		for i in range(couleur_set.size()):
			tween.tween_property(sprite, "modulate", couleur_set[i], 0.1).set_delay(i * 0.1)
		
		# Répéter la séquence pour les étages élevés
		if etage >= 2:
			for i in range(couleur_set.size()):
				tween.tween_property(sprite, "modulate", couleur_set[i], 0.08).set_delay(0.3 + i * 0.08)
		
		tween.tween_property(sprite, "modulate", _couleur_joueur(joueur), 0.2).set_delay(0.5)
		
		# Grossissement plus spectaculaire aux étages élevés
		var scale_max = 1.8 + (etage * 0.4)
		tween.tween_property(sprite, "scale", Vector2(scale_max, scale_max), 0.3)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.3)
	
	# Créer des particules plus nombreuses aux étages élevés
	_creer_effet_particules_bonus_avance(position_initiale, particules_count, etage)

func _creer_effet_particules_bonus(position: Vector2):
	"""Créer un effet de particules pour les bonus"""
	# Créer plusieurs petits carrés colorés qui s'envolent
	for i in range(12):
		var particule = ColorRect.new()
		particule.size = Vector2(8, 8)
		particule.color = [Color.YELLOW, Color.GREEN, Color.CYAN, Color.MAGENTA][i % 4]
		particule.position = position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		get_parent().add_child(particule)
		
		# Animation de la particule
		var tween_part = create_tween()
		var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var distance = randf_range(80, 150)
		
		tween_part.parallel().tween_property(particule, "position", 
			particule.position + direction * distance, 1.0)
		tween_part.parallel().tween_property(particule, "modulate", 
			Color.TRANSPARENT, 1.0)
		tween_part.parallel().tween_property(particule, "rotation", 
			randf_range(0, 2*PI), 1.0)
		
		# Supprimer la particule après l'animation
		tween_part.tween_callback(particule.queue_free)

func _creer_effet_particules_bonus_avance(position: Vector2, count: int, etage: int):
	"""Créer un effet de particules avancé pour les bonus selon l'étage"""
	for i in range(count):
		var particule = ColorRect.new()
		var taille = 8 + (etage * 2)  # Plus grosses particules aux étages élevés
		particule.size = Vector2(taille, taille)
		
		# Couleurs douces selon l'étage
		var couleurs_etage = [
			[Color(0.8, 0.8, 0.5), Color(0.5, 0.7, 0.5), Color(0.5, 0.7, 0.7)],        # Jaune doux, vert doux, cyan doux
			[Color(0.8, 0.7, 0.4), Color(0.8, 0.6, 0.4), Color(0.8, 0.8, 0.6)],        # Or doux, orange doux
			[Color(0.9, 0.9, 0.9), Color(0.7, 0.8, 0.9), Color(0.7, 0.6, 0.8)],        # Blanc cassé, bleu doux, magenta doux
			[Color(0.9, 0.8, 0.6), Color(0.9, 0.9, 0.9), Color(0.9, 0.7, 0.8)],        # Doré pâle, blanc cassé, rose pâle
			[Color(0.9, 0.9, 0.9), Color(0.9, 0.7, 0.8), Color(0.8, 0.7, 0.5)]         # Blanc, rose pâle, or pâle
		]
		var couleur_set = couleurs_etage[min(etage, 4)]
		particule.color = couleur_set[i % couleur_set.size()]
		
		particule.position = position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		get_parent().add_child(particule)
		
		# Animation plus spectaculaire pour les étages élevés
		var tween_part = create_tween()
		var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var distance = randf_range(100, 200) + (etage * 50)  # Plus loin aux étages élevés
		var duree = 1.0 + (etage * 0.3)  # Plus long aux étages élevés
		
		tween_part.parallel().tween_property(particule, "position", 
			particule.position + direction * distance, duree)
		tween_part.parallel().tween_property(particule, "modulate", 
			Color.TRANSPARENT, duree)
		tween_part.parallel().tween_property(particule, "rotation", 
			randf_range(0, 4*PI), duree)  # Plus de rotation
		
		# Effet spécial pour les étages élevés
		if etage >= 2:
			tween_part.parallel().tween_property(particule, "scale", 
				Vector2(2.0, 2.0), duree / 2)
			tween_part.parallel().tween_property(particule, "scale", 
				Vector2(0.1, 0.1), duree / 2).set_delay(duree / 2)
		
		tween_part.tween_callback(particule.queue_free)

func _creer_effet_particules_piege_avance(position: Vector2, etage: int):
	"""Créer un effet de particules maléfique pour les pièges selon l'étage"""
	var count = 15 + (etage * 5)  # Plus de particules aux étages élevés
	
	for i in range(count):
		var particule = ColorRect.new()
		var taille = 6 + (etage * 2)
		particule.size = Vector2(taille, taille)
		
		# Couleurs sombres mais douces selon l'étage
		var couleurs_piege_etage = [
			[Color(0.7, 0.4, 0.4), Color(0.5, 0.3, 0.3)],                         # Rouge doux
			[Color(0.8, 0.5, 0.3), Color(0.6, 0.3, 0.2)],                         # Orange sombre doux
			[Color(0.6, 0.4, 0.7), Color(0.4, 0.2, 0.5)],                         # Violet doux
			[Color(0.4, 0.4, 0.4), Color(0.6, 0.3, 0.3), Color(0.3, 0.3, 0.5)],  # Gris, rouge sombre, indigo doux
			[Color(0.6, 0.3, 0.6), Color(0.4, 0.4, 0.4), Color(0.5, 0.3, 0.5)]   # Magenta doux, gris
		]
		var couleur_set = couleurs_piege_etage[min(etage, 4)]
		particule.color = couleur_set[i % couleur_set.size()]
		
		particule.position = position + Vector2(randf_range(-25, 25), randf_range(-25, 25))
		get_parent().add_child(particule)
		
		# Animation maléfique - spirale vers le bas
		var tween_part = create_tween()
		var angle_depart = randf_range(0, 2*PI)
		var rayon = randf_range(50, 120) + (etage * 30)
		var duree = 1.5 + (etage * 0.2)
		
		# Mouvement en spirale
		for j in range(int(duree * 10)):
			var angle = angle_depart + (j * 0.3)
			var rayon_actuel = rayon * (1.0 - (j / (duree * 10)))
			var pos_spirale = position + Vector2(cos(angle) * rayon_actuel, sin(angle) * rayon_actuel + j * 2)
			tween_part.tween_property(particule, "position", pos_spirale, 0.1)
		
		tween_part.parallel().tween_property(particule, "modulate", Color.TRANSPARENT, duree)
		tween_part.parallel().tween_property(particule, "rotation", randf_range(0, 6*PI), duree)
		
		tween_part.tween_callback(particule.queue_free)

# Fonctions utilitaires pour ajouter/modifier des pièges et bonus
func ajouter_piege(x: float, y: float, nom: String, recul: int):
	"""Ajouter un nouveau piège"""
	var nouveau_piege = {"x": x, "y": y, "nom": nom, "recul": recul}
	pieges.append(nouveau_piege)
	
	# Créer le marqueur visuel pour ce piège
	var marqueur = _creer_marqueur_piege(nouveau_piege)
	marqueurs_pieges.append(marqueur)
	add_child(marqueur)
	
	print("Piège ajouté: %s à (%f, %f)" % [nom, x, y])

func ajouter_bonus(x: float, y: float, nom: String, type: String = "avance", valeur: int = 100):
	"""Ajouter un nouveau bonus avec type et valeur"""
	var nouveau_bonus = {"x": x, "y": y, "nom": nom, "type": type, "valeur": valeur}
	bonus.append(nouveau_bonus)
	
	# Créer le marqueur visuel pour ce bonus
	var marqueur = _creer_marqueur_bonus(nouveau_bonus)
	marqueurs_bonus.append(marqueur)
	add_child(marqueur)
	
	print("Bonus ajouté: %s à (%f, %f)" % [nom, x, y])

func supprimer_piege(nom: String):
	"""Supprimer un piège par son nom"""
	for i in range(pieges.size() - 1, -1, -1):
		if pieges[i].nom == nom:
			pieges.remove_at(i)
			
			# Supprimer aussi le marqueur visuel correspondant
			for j in range(marqueurs_pieges.size() - 1, -1, -1):
				if marqueurs_pieges[j] and marqueurs_pieges[j].name == "Marqueur_" + nom:
					marqueurs_pieges[j].queue_free()
					marqueurs_pieges.remove_at(j)
					break
			
			print("Piège supprimé: %s" % nom)
			break

func supprimer_bonus(nom: String):
	"""Supprimer un bonus par son nom"""
	for i in range(bonus.size() - 1, -1, -1):
		if bonus[i].nom == nom:
			bonus.remove_at(i)
			
			# Supprimer aussi le marqueur visuel correspondant
			for j in range(marqueurs_bonus.size() - 1, -1, -1):
				if marqueurs_bonus[j] and marqueurs_bonus[j].name == "Marqueur_" + nom:
					marqueurs_bonus[j].queue_free()
					marqueurs_bonus.remove_at(j)
					break
			
			print("Bonus supprimé: %s" % nom)
			break

func obtenir_pieges() -> Array:
	"""Obtenir la liste des pièges"""
	return pieges.duplicate()

func obtenir_bonus() -> Array:
	"""Obtenir la liste des bonus"""
	return bonus.duplicate()

func modifier_tolerance(nouvelle_tolerance: float):
	"""Modifier la tolérance de détection"""
	tolerance_detection = nouvelle_tolerance
	print("Tolérance de détection modifiée: %f pixels" % tolerance_detection)

# === FONCTIONS POUR LES MARQUEURS VISUELS ===

func _creer_marqueurs_visuels():
	"""Créer les marqueurs visuels pour tous les pièges et bonus"""
	print("=== CRÉATION DES MARQUEURS VISUELS ===")
	print("Nombre de pièges configurés: %d" % pieges.size())
	print("Nombre de bonus configurés: %d" % bonus.size())
	
	# Supprimer les anciens marqueurs s'ils existent
	_supprimer_tous_marqueurs()
	
	# Créer les marqueurs pour les pièges
	for i in range(pieges.size()):
		var piege = pieges[i]
		print("Création marqueur piège %d: %s à (%f, %f)" % [i+1, piege.nom, piege.x, piege.y])
		var marqueur = _creer_marqueur_piege(piege)
		marqueurs_pieges.append(marqueur)
		add_child(marqueur)
		print("Marqueur piège ajouté à la scène")
	
	# Créer les marqueurs pour les bonus
	for i in range(bonus.size()):
		var bonus_item = bonus[i]
		print("Création marqueur bonus %d: %s à (%f, %f)" % [i+1, bonus_item.nom, bonus_item.x, bonus_item.y])
		var marqueur = _creer_marqueur_bonus(bonus_item)
		marqueurs_bonus.append(marqueur)
		add_child(marqueur)
		print("Marqueur bonus ajouté à la scène")
	
	print("=== MARQUEURS CRÉÉS: %d pièges, %d bonus ===" % [marqueurs_pieges.size(), marqueurs_bonus.size()])
	
	# Attendre un frame puis vérifier que les marqueurs sont visibles
	await get_tree().process_frame
	_verifier_marqueurs_visibles()

func _creer_marqueur_piege(piege: Dictionary) -> Node2D:
	"""Créer un marqueur visuel pour un piège"""
	var marqueur = Node2D.new()
	marqueur.position = Vector2(piege.x, piege.y)
	marqueur.name = "Marqueur_" + piege.nom
	marqueur.z_index = 10  # S'assurer qu'il est au-dessus
	
	print("Création marqueur piège à position: %s" % marqueur.position)
	
	# Utiliser des couleurs plus douces et atténuées
	var rectangle = ColorRect.new()
	rectangle.color = Color(0.7, 0.3, 0.3, 0.8)  # Rouge atténué et semi-transparent
	rectangle.size = Vector2(60, 60)  # Plus grand
	rectangle.position = Vector2(-30, -30)  # Centrer
	marqueur.add_child(rectangle)
	
	# Ajouter une bordure plus douce
	var bordure = ColorRect.new()
	bordure.color = Color(0.5, 0.2, 0.2, 0.9)  # Rouge sombre mais pas criard
	bordure.size = Vector2(68, 68)  # Plus épaisse
	bordure.position = Vector2(-34, -34)
	marqueur.add_child(bordure)
	marqueur.move_child(bordure, 0)  # Mettre la bordure en arrière
	
	# Ajouter un effet de croix plus doux
	var croix_h = ColorRect.new()
	croix_h.color = Color(0.9, 0.9, 0.9, 0.8)  # Blanc cassé semi-transparent
	croix_h.size = Vector2(40, 6)
	croix_h.position = Vector2(-20, -3)
	marqueur.add_child(croix_h)
	
	var croix_v = ColorRect.new()
	croix_v.color = Color(0.9, 0.9, 0.9, 0.8)  # Blanc cassé semi-transparent
	croix_v.size = Vector2(6, 40)
	croix_v.position = Vector2(-3, -20)
	marqueur.add_child(croix_v)
	
	# Ajouter un label avec le nom
	var label = Label.new()
	label.text = piege.nom
	label.position = Vector2(-30, -50)
	label.add_theme_color_override("font_color", Color.RED)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.z_index = 1
	marqueur.add_child(label)
	
	# Animation de pulsation plus dramatique
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(rectangle, "scale", Vector2(1.5, 1.5), 0.8)
	tween.tween_property(rectangle, "scale", Vector2(1.0, 1.0), 0.8)
	
	# Animation de rotation de la croix
	var tween2 = create_tween()
	tween2.set_loops()
	tween2.tween_property(croix_h, "rotation", PI/4, 1.5)
	tween2.tween_property(croix_h, "rotation", 0, 1.5)
	tween2.parallel().tween_property(croix_v, "rotation", PI/4, 1.5)
	tween2.parallel().tween_property(croix_v, "rotation", 0, 1.5)
	
	print("Marqueur piège créé avec %d enfants" % marqueur.get_child_count())
	return marqueur

func _creer_marqueur_bonus(bonus_item: Dictionary) -> Node2D:
	"""Créer un marqueur visuel pour un bonus"""
	var marqueur = Node2D.new()
	marqueur.position = Vector2(bonus_item.x, bonus_item.y)
	marqueur.name = "Marqueur_" + bonus_item.nom
	marqueur.z_index = 10  # S'assurer qu'il est au-dessus
	
	print("Création marqueur bonus à position: %s" % marqueur.position)
	
	# Utiliser des couleurs vertes plus douces
	var rectangle = ColorRect.new()
	rectangle.color = Color(0.4, 0.7, 0.5, 0.8)  # Vert atténué et semi-transparent
	rectangle.size = Vector2(60, 60)  # Plus grand
	rectangle.position = Vector2(-30, -30)  # Centrer
	marqueur.add_child(rectangle)
	
	# Ajouter une bordure verte plus douce
	var bordure = ColorRect.new()
	bordure.color = Color(0.3, 0.5, 0.3, 0.9)  # Vert sombre mais pas criard
	bordure.size = Vector2(68, 68)  # Plus épaisse
	bordure.position = Vector2(-34, -34)
	marqueur.add_child(bordure)
	marqueur.move_child(bordure, 0)  # Mettre la bordure en arrière
	
	# Ajouter un effet de plus (+) plus doux
	var plus_h = ColorRect.new()
	plus_h.color = Color(0.9, 0.9, 0.9, 0.8)  # Blanc cassé semi-transparent
	plus_h.size = Vector2(40, 8)
	plus_h.position = Vector2(-20, -4)
	marqueur.add_child(plus_h)
	
	var plus_v = ColorRect.new()
	plus_v.color = Color(0.9, 0.9, 0.9, 0.8)  # Blanc cassé semi-transparent
	plus_v.size = Vector2(8, 40)
	plus_v.position = Vector2(-4, -20)
	marqueur.add_child(plus_v)
	
	# Ajouter un label avec le nom
	var label = Label.new()
	label.text = bonus_item.nom
	label.position = Vector2(-30, -50)
	label.add_theme_color_override("font_color", Color.GREEN)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.z_index = 1
	marqueur.add_child(label)
	
	# Animation spectaculaire pour attirer l'attention
	var tween = create_tween()
	tween.set_loops()
	# Rotation + pulsation combinées
	tween.tween_property(rectangle, "rotation", 2 * PI, 1.5)
	tween.parallel().tween_property(rectangle, "scale", Vector2(1.3, 1.3), 0.75)
	tween.parallel().tween_property(rectangle, "scale", Vector2(1.0, 1.0), 0.75).set_delay(0.75)
	
	# Animation du symbole plus plus douce
	var tween2 = create_tween()
	tween2.set_loops()
	tween2.tween_property(plus_h, "modulate", Color(0.9, 0.8, 0.6, 0.9), 0.8)  # Jaune doux
	tween2.tween_property(plus_h, "modulate", Color(0.9, 0.9, 0.9, 0.8), 0.8)  # Blanc cassé
	tween2.parallel().tween_property(plus_v, "modulate", Color(0.9, 0.8, 0.6, 0.9), 0.8)
	tween2.parallel().tween_property(plus_v, "modulate", Color(0.9, 0.9, 0.9, 0.8), 0.8)
	
	print("Marqueur bonus créé avec %d enfants" % marqueur.get_child_count())
	return marqueur

func _supprimer_tous_marqueurs():
	"""Supprimer tous les marqueurs existants"""
	for marqueur in marqueurs_pieges:
		if marqueur and is_instance_valid(marqueur):
			marqueur.queue_free()
	
	for marqueur in marqueurs_bonus:
		if marqueur and is_instance_valid(marqueur):
			marqueur.queue_free()
	
	marqueurs_pieges.clear()
	marqueurs_bonus.clear()

func masquer_marqueurs():
	"""Masquer tous les marqueurs visuels"""
	for marqueur in marqueurs_pieges:
		if marqueur and is_instance_valid(marqueur):
			marqueur.visible = false
	
	for marqueur in marqueurs_bonus:
		if marqueur and is_instance_valid(marqueur):
			marqueur.visible = false

func afficher_marqueurs():
	"""Afficher tous les marqueurs visuels"""
	for marqueur in marqueurs_pieges:
		if marqueur and is_instance_valid(marqueur):
			marqueur.visible = true
	
	for marqueur in marqueurs_bonus:
		if marqueur and is_instance_valid(marqueur):
			marqueur.visible = true

func basculer_marqueurs():
	"""Basculer la visibilité des marqueurs"""
	var visible = true
	if marqueurs_pieges.size() > 0 and marqueurs_pieges[0]:
		visible = not marqueurs_pieges[0].visible
	
	if visible:
		afficher_marqueurs()
	else:
		masquer_marqueurs()
	
	print("Marqueurs %s" % ("affichés" if visible else "masqués"))

func _verifier_marqueurs_visibles():
	"""Vérifier que les marqueurs sont bien visibles"""
	print("\n=== VÉRIFICATION DES MARQUEURS ===")
	
	for i in range(marqueurs_pieges.size()):
		var marqueur = marqueurs_pieges[i]
		if marqueur and is_instance_valid(marqueur):
			print("Piège %d: visible=%s, position=%s, parent=%s" % [i+1, marqueur.visible, marqueur.global_position, marqueur.get_parent().name if marqueur.get_parent() else "null"])
		else:
			print("Piège %d: MARQUEUR INVALIDE" % [i+1])
	
	for i in range(marqueurs_bonus.size()):
		var marqueur = marqueurs_bonus[i]
		if marqueur and is_instance_valid(marqueur):
			print("Bonus %d: visible=%s, position=%s, parent=%s" % [i+1, marqueur.visible, marqueur.global_position, marqueur.get_parent().name if marqueur.get_parent() else "null"])
		else:
			print("Bonus %d: MARQUEUR INVALIDE" % [i+1])
	
	print("=== FIN VÉRIFICATION ===\n")

# === FONCTIONS POUR LES AFFICHAGES UX (NOTIFICATIONS) ===

func _afficher_notification_evenement(position: Vector2, valeur: int, nom_evenement: String, est_bonus: bool):
	"""Afficher une notification flottante pour un événement (bonus ou piège)"""
	var label = Label.new()
	
	# Texte selon le type d'événement
	if est_bonus:
		label.text = "+%d" % valeur
		label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3, 1.0))  # Vert vif
	else:
		label.text = "-%d" % abs(valeur)
		label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))  # Rouge vif
	
	# Style du texte
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	
	# Position : au-dessus du joueur
	label.global_position = position + Vector2(-50, -80)
	label.z_index = 100  # Au-dessus de tout
	
	# Ajouter à la scène
	get_parent().add_child(label)
	
	# Animation : montée + fade out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -60), 1.5)
	tween.tween_property(label, "modulate", Color.TRANSPARENT, 1.5)
	tween.tween_callback(label.queue_free)
	
	# Ajouter un label plus petit pour le nom de l'événement
	var label_nom = Label.new()
	label_nom.text = nom_evenement
	label_nom.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	label_nom.add_theme_font_size_override("font_size", 20)
	label_nom.add_theme_color_override("font_shadow_color", Color.BLACK)
	label_nom.add_theme_constant_override("shadow_offset_x", 2)
	label_nom.add_theme_constant_override("shadow_offset_y", 2)
	label_nom.global_position = position + Vector2(-80, -40)
	label_nom.z_index = 100
	
	get_parent().add_child(label_nom)
	
	var tween_nom = create_tween()
	tween_nom.set_parallel(true)
	tween_nom.tween_property(label_nom, "global_position", label_nom.global_position + Vector2(0, -60), 1.5)
	tween_nom.tween_property(label_nom, "modulate", Color.TRANSPARENT, 1.5)
	tween_nom.tween_callback(label_nom.queue_free)

func _afficher_combo(position: Vector2, niveau_combo: int):
	"""Afficher l'indicateur de combo"""
	var label_combo = Label.new()
	label_combo.text = "COMBO x%d" % niveau_combo
	
	# Couleur qui devient de plus en plus intense selon le niveau
	var couleur_combo = Color(1.0, 0.8, 0.0, 1.0)  # Doré de base
	if niveau_combo >= 3:
		couleur_combo = Color(1.0, 0.5, 0.0, 1.0)  # Orange
	if niveau_combo >= 4:
		couleur_combo = Color(1.0, 0.2, 0.5, 1.0)  # Rose/rouge
	if niveau_combo >= 5:
		couleur_combo = Color(0.8, 0.0, 1.0, 1.0)  # Violet/magenta
	
	label_combo.add_theme_color_override("font_color", couleur_combo)
	label_combo.add_theme_font_size_override("font_size", 56 + (niveau_combo * 4))  # Plus gros selon le niveau
	label_combo.add_theme_color_override("font_shadow_color", Color.BLACK)
	label_combo.add_theme_constant_override("shadow_offset_x", 4)
	label_combo.add_theme_constant_override("shadow_offset_y", 4)
	
	# Position : au centre-haut du joueur
	label_combo.global_position = position + Vector2(-100, -150)
	label_combo.z_index = 101  # Au-dessus de tout
	
	get_parent().add_child(label_combo)
	
	# Animation spectaculaire : apparition + pulsation + montée + fade out
	var tween_combo = create_tween()
	tween_combo.set_parallel(false)
	
	# Apparition explosive
	label_combo.scale = Vector2(0.1, 0.1)
	tween_combo.tween_property(label_combo, "scale", Vector2(1.5, 1.5), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_combo.tween_property(label_combo, "scale", Vector2(1.0, 1.0), 0.15)
	
	# Pulsation
	tween_combo.parallel().tween_property(label_combo, "scale", Vector2(1.2, 1.2), 0.3)
	tween_combo.parallel().tween_property(label_combo, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.3)
	
	# Montée et disparition
	tween_combo.parallel().tween_property(label_combo, "global_position", label_combo.global_position + Vector2(0, -80), 1.2)
	tween_combo.parallel().tween_property(label_combo, "modulate", Color.TRANSPARENT, 1.2).set_delay(0.3)
	
	tween_combo.tween_callback(label_combo.queue_free)
