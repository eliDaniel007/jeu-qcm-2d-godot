extends Node

# Script de debug pour forcer l'affichage des marqueurs
# À attacher à la scène Level pour debug

func _ready():
	print("=== SCRIPT DE DEBUG DES MARQUEURS ===")
	
	# Attendre que tout soit chargé
	await get_tree().create_timer(1.0).timeout
	
	# Trouver le gestionnaire
	var gestionnaire = get_node_or_null("GestionnairePiegesBonus")
	if gestionnaire:
		print("✅ Gestionnaire trouvé: %s" % gestionnaire.name)
		
		# Forcer la création des marqueurs
		gestionnaire._creer_marqueurs_visuels()
		
		# Créer des marqueurs de test supplémentaires
		_creer_marqueurs_test()
	else:
		print("❌ Gestionnaire non trouvé")
		_lister_enfants()

func _lister_enfants():
	"""Lister tous les enfants pour debug"""
	print("\n--- Enfants de la scène Level ---")
	for enfant in get_children():
		print("- %s (%s)" % [enfant.name, enfant.get_class()])
	print("--- Fin liste ---\n")

func _creer_marqueurs_test():
	"""Créer des marqueurs de test visibles"""
	print("\n=== CRÉATION MARQUEURS DE TEST ===")
	
	# Créer un marqueur rouge simple
	var marqueur_test_rouge = ColorRect.new()
	marqueur_test_rouge.color = Color.RED
	marqueur_test_rouge.size = Vector2(60, 60)
	marqueur_test_rouge.position = Vector2(500, 500)  # Position fixe
	add_child(marqueur_test_rouge)
	
	var label_rouge = Label.new()
	label_rouge.text = "TEST ROUGE"
	label_rouge.position = Vector2(520, 480)
	label_rouge.add_theme_color_override("font_color", Color.RED)
	add_child(label_rouge)
	
	# Créer un marqueur vert simple
	var marqueur_test_vert = ColorRect.new()
	marqueur_test_vert.color = Color.GREEN
	marqueur_test_vert.size = Vector2(60, 60)
	marqueur_test_vert.position = Vector2(600, 500)  # Position fixe
	add_child(marqueur_test_vert)
	
	var label_vert = Label.new()
	label_vert.text = "TEST VERT"
	label_vert.position = Vector2(620, 480)
	label_vert.add_theme_color_override("font_color", Color.GREEN)
	add_child(label_vert)
	
	print("✅ Marqueurs de test créés à (500,500) et (600,500)")

func _input(event):
	if event.is_action_pressed("ui_down"):  # Flèche bas
		print("\n🔍 Vérification manuelle des marqueurs...")
		var gestionnaire = get_node_or_null("GestionnairePiegesBonus")
		if gestionnaire:
			gestionnaire._verifier_marqueurs_visibles()
			print("Nombre d'enfants du gestionnaire: %d" % gestionnaire.get_child_count())
			for i in range(gestionnaire.get_child_count()):
				var enfant = gestionnaire.get_child(i)
				print("Enfant %d: %s - visible: %s - position: %s" % [i, enfant.name, enfant.visible, enfant.position])
	
	elif event.is_action_pressed("ui_up"):  # Flèche haut
		print("\n🔄 Recréation forcée des marqueurs...")
		var gestionnaire = get_node_or_null("GestionnairePiegesBonus")
		if gestionnaire:
			gestionnaire._creer_marqueurs_visuels()
