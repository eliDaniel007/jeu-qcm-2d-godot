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
var bonus = [
	# Rez-de-chaussée (y=982) - Mix d'effets basiques
	{"x": 479, "y": 982, "nom": "Étoile Filante", "type": "course_rapide", "valeur": 250},
	{"x": 671, "y": 982, "nom": "Téléporteur", "type": "teleportation", "valeur": 300},
	{"x": 1889, "y": 982, "nom": "Boost Magique", "type": "avance", "valeur": 400},
	
	# 1er étage (y=780) - Introduction du vol
	{"x": 2204, "y": 780, "nom": "Accélérateur", "type": "course_rapide", "valeur": 280},
	{"x": 1600, "y": 780, "nom": "Ailes d'Ange", "type": "vol", "valeur": 320},
	
	# 2ème étage (y=551) - Effets plus puissants
	{"x": 1000, "y": 551, "nom": "Saut Quantique", "type": "vol", "valeur": 350},
	{"x": 1800, "y": 551, "nom": "Éclair Divin", "type": "course_rapide", "valeur": 380},
	
	# 3ème étage (y=348) - Bonus puissants mixtes
	{"x": 1500, "y": 348, "nom": "Vitesse Lumière", "type": "course_rapide", "valeur": 450},
	{"x": 2200, "y": 348, "nom": "Portail Céleste", "type": "teleportation", "valeur": 500},
	
	# 4ème étage final (y=180) - Aucun bonus (étage difficile)
]

# Tolérance pour la détection (en pixels)
var tolerance_detection = 25.0

# Référence au path_manager
var path_manager: Node2D

# Marqueurs visuels
var marqueurs_pieges: Array = []
var marqueurs_bonus: Array = []

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
	
	# Vérifier d'abord les pièges
	var piege_detecte = verifier_piege(position_joueur)
	if piege_detecte:
		appliquer_piege(joueur, piege_detecte)
		return
	
	# Ensuite vérifier les bonus
	var bonus_detecte = verifier_bonus(position_joueur)
	if bonus_detecte:
		appliquer_bonus(joueur, bonus_detecte)

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

func appliquer_piege(joueur: Node, piege: Dictionary):
	"""Appliquer l'effet d'un piège : faire reculer le joueur"""
	print("=== PIÈGE ACTIVÉ: %s ===" % piege.nom)
	print("Le joueur recule de %d pixels" % piege.recul)
	
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
	
	# Déplacer le joueur instantanément
	joueur.global_position = nouvelle_position
	print("Joueur déplacé vers: %s" % nouvelle_position)
	
	# Animation selon l'étage - plus spectaculaire en montant
	_jouer_animation_piege(joueur, etage_actuel, piege.recul)

func appliquer_bonus(joueur: Node, bonus_item: Dictionary):
	"""Appliquer l'effet d'un bonus selon son type"""
	print("=== BONUS ACTIVÉ: %s (Type: %s) ===" % [bonus_item.nom, bonus_item.type])
	
	# Déterminer l'étage actuel
	var etage_actuel = 0
	if path_manager.has_method("get_etage_actuel"):
		etage_actuel = path_manager.get_etage_actuel()
	
	# Appliquer l'effet selon le type de bonus
	match bonus_item.type:
		"avance":
			_appliquer_effet_avance(joueur, bonus_item, etage_actuel)
		"course_rapide":
			_appliquer_effet_course_rapide(joueur, bonus_item, etage_actuel)
		"teleportation":
			_appliquer_effet_teleportation(joueur, bonus_item, etage_actuel)
		"vol":
			_appliquer_effet_vol(joueur, bonus_item, etage_actuel)
		_:
			# Type par défaut : avance simple
			_appliquer_effet_avance(joueur, bonus_item, etage_actuel)
	
	# Animation selon le type et l'étage
	_jouer_animation_bonus_par_type(joueur, bonus_item.type, etage_actuel, bonus_item.valeur)

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
	
	# Animation de course rapide progressive
	var tween_course = create_tween()
	tween_course.tween_property(joueur, "global_position", nouvelle_position, 0.8)
	
	# Effet de vitesse avec sprite animé
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		# Accélérer l'animation pendant la course
		var vitesse_originale = sprite.speed_scale
		sprite.speed_scale = 3.0  # 3x plus rapide
		tween_course.tween_callback(func(): sprite.speed_scale = vitesse_originale).set_delay(0.8)
	
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
	var tween_teleport = create_tween()
	tween_teleport.set_parallel(true)
	
	# Disparition rapide
	tween_teleport.tween_property(joueur, "modulate", Color.TRANSPARENT, 0.15)
	tween_teleport.tween_property(joueur, "scale", Vector2(0.1, 0.1), 0.15)
	
	# Téléportation instantanée au milieu
	tween_teleport.tween_callback(func(): joueur.global_position = nouvelle_position).set_delay(0.15)
	
	# Réapparition spectaculaire
	tween_teleport.tween_property(joueur, "modulate", Color.WHITE, 0.3).set_delay(0.15)
	tween_teleport.tween_property(joueur, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.15)
	
	# Callback de sécurité pour la téléportation
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		tween_teleport.tween_callback(func(): _reinitialiser_sprite_joueur(sprite)).set_delay(0.5)
	
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
	
	# Animation de vol : montée, vol horizontal, descente
	var tween_vol = create_tween()
	var hauteur_vol = 40 + (etage_actuel * 15)  # Plus haut aux étages élevés
	
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
		tween_ailes.tween_callback(func(): _reinitialiser_sprite_joueur(sprite)).set_delay(1.6)
	
	print("Joueur vole vers: %s" % nouvelle_position)

func _reinitialiser_sprite_joueur(sprite: Node):
	"""Fonction de sécurité pour remettre le sprite du joueur dans son état normal"""
	if sprite and is_instance_valid(sprite):
		sprite.rotation = 0.0
		sprite.scale = Vector2(1.0, 1.0)
		sprite.modulate = Color.WHITE
		print("🔧 Sprite du joueur réinitialisé par sécurité")

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
		
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.4).set_delay(0.6)
		
		# Grossissement plus important aux étages élevés
		var scale_max = 1.5 + (etage * 0.3)
		tween.tween_property(sprite, "scale", Vector2(scale_max, scale_max), 0.2)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.4).set_delay(0.2)
	
	# Particules spéciales pour les étages élevés
	if etage >= 2:
		_creer_effet_particules_piege_avance(position_initiale, etage)

func _jouer_animation_bonus_par_type(joueur: Node, type: String, etage: int = 0, valeur: int = 100):
	"""Animation spécifique selon le type de bonus"""
	if not joueur:
		return
	
	print("🎨 Animation bonus type: %s" % type)
	
	match type:
		"avance":
			_animation_bonus_avance(joueur, etage, valeur)
		"course_rapide":
			_animation_bonus_course_rapide(joueur, etage, valeur)
		"teleportation":
			_animation_bonus_teleportation(joueur, etage, valeur)
		"vol":
			_animation_bonus_vol(joueur, etage, valeur)
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
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.3).set_delay(0.2)
		
		# Légère pulsation
		tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.2)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.2)

func _animation_bonus_course_rapide(joueur: Node, etage: int, valeur: int):
	"""Animation pour bonus de course rapide"""
	print("🏃 ANIMATION COURSE RAPIDE !")
	
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Effet de traînée avec changements de couleur rapides
		var couleurs_vitesse = [Color(0.9, 0.8, 0.3), Color(0.8, 0.9, 0.4), Color(0.7, 0.8, 0.9)]  # Jaune, vert, bleu doux
		for i in range(couleurs_vitesse.size()):
			tween.tween_property(sprite, "modulate", couleurs_vitesse[i], 0.15).set_delay(i * 0.15)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2).set_delay(0.45)
		
		# Étirement horizontal pour simuler la vitesse
		tween.tween_property(sprite, "scale", Vector2(1.5, 0.8), 0.3)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.4).set_delay(0.3)
		
		# Particules de vitesse
		_creer_particules_vitesse(joueur.global_position, etage)

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
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.03).set_delay(i * 0.1 + 0.03)
		
		# Particules de téléportation
		_creer_particules_teleportation(joueur.global_position, etage)

func _animation_bonus_vol(joueur: Node, etage: int, valeur: int):
	"""Animation pour bonus de vol"""
	print("🕊️ ANIMATION VOL !")
	
	if joueur.has_node("AnimatedSprite2D"):
		var sprite = joueur.get_node("AnimatedSprite2D")
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Couleurs aériennes douces
		var couleurs_vol = [Color(0.8, 0.9, 0.9), Color(0.9, 0.9, 0.8), Color(0.9, 0.8, 0.9)]  # Bleu ciel, jaune doux, rose doux
		for i in range(couleurs_vol.size()):
			tween.tween_property(sprite, "modulate", couleurs_vol[i], 0.3).set_delay(i * 0.3)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.3).set_delay(0.9)
		
		# Effet de lévitation avec oscillation contrôlée
		for i in range(6):
			tween.tween_property(sprite, "scale", Vector2(1.2, 0.9), 0.2).set_delay(i * 0.2)
			tween.tween_property(sprite, "scale", Vector2(0.9, 1.2), 0.2).set_delay(i * 0.2 + 0.1)
		# S'assurer que le scale revient exactement à la normale
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.3).set_delay(1.2)
		
		# Particules de plumes
		_creer_particules_vol(joueur.global_position, etage)

# === FONCTIONS POUR LES PARTICULES SPÉCIFIQUES ===

func _creer_particules_vitesse(position: Vector2, etage: int):
	"""Créer des particules de vitesse pour la course rapide"""
	for i in range(8 + etage * 3):
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
	for i in range(12 + etage * 4):
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
		
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2).set_delay(0.5)
		
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
