extends Node

# Script de test simple pour les pièges et bonus
# À attacher à la scène principale pour tester le système

var gestionnaire_pieges: Node2D
var joueur: Node2D

func _ready():
	# Attendre que la scène soit complètement chargée
	await get_tree().process_frame
	
	# Trouver les composants
	gestionnaire_pieges = get_node_or_null("/root/Level/GestionnairePiegesBonus")
	joueur = get_node_or_null("/root/Level/character")
	
	if not gestionnaire_pieges:
		print("ERREUR: Gestionnaire de pièges non trouvé")
		return
	
	if not joueur:
		print("ERREUR: Joueur non trouvé")
		return
	
	print("=== TEST DU SYSTÈME DE PIÈGES ET BONUS ===")
	_lancer_tests()

func _lancer_tests():
	print("\n🧪 Lancement des tests automatiques...")
	
	# Test 1: Vérifier que le gestionnaire est initialisé
	print("\n1. Test d'initialisation du gestionnaire")
	if gestionnaire_pieges and gestionnaire_pieges.has_method("obtenir_pieges"):
		var pieges = gestionnaire_pieges.obtenir_pieges()
		var bonus = gestionnaire_pieges.obtenir_bonus()
		print("✅ Gestionnaire initialisé - %d pièges, %d bonus" % [pieges.size(), bonus.size()])
		
		# Afficher les positions configurées
		print("📍 Pièges configurés:")
		for piege in pieges:
			print("   - %s à (%d, %d) - recul %d px" % [piege.nom, piege.x, piege.y, piege.recul])
		
		print("📍 Bonus configurés:")
		for bonus_item in bonus:
			print("   - %s à (%d, %d) - avance %d px" % [bonus_item.nom, bonus_item.x, bonus_item.y, bonus_item.avance])
	else:
		print("❌ Gestionnaire non fonctionnel")
		return
	
	# Test 2: Tester la détection à différentes positions
	print("\n2. Test de détection par coordonnées")
	_tester_detection()
	
	# Test 3: Simulation de placement sur piège/bonus
	print("\n3. Test de simulation")
	_tester_simulation()

func _tester_detection():
	"""Tester la détection de pièges et bonus"""
	var positions_test = [
		{"pos": Vector2(479, 982), "type": "bonus", "nom": "Bonus 1"},
		{"pos": Vector2(1825, 982), "type": "piège", "nom": "Piège 1"},
		{"pos": Vector2(671, 982), "type": "bonus", "nom": "Bonus 2"},
		{"pos": Vector2(1000, 500), "type": "rien", "nom": "Position vide"},
	]
	
	for test in positions_test:
		var piege_detecte = gestionnaire_pieges.verifier_piege(test.pos)
		var bonus_detecte = gestionnaire_pieges.verifier_bonus(test.pos)
		
		if not piege_detecte.is_empty():
			print("✅ Piège détecté à %s: %s" % [test.pos, piege_detecte.nom])
		elif not bonus_detecte.is_empty():
			print("✅ Bonus détecté à %s: %s" % [test.pos, bonus_detecte.nom])
		else:
			if test.type == "rien":
				print("✅ Aucun piège/bonus détecté à %s (attendu)" % test.pos)
			else:
				print("❌ Échec de détection à %s (attendu: %s)" % [test.pos, test.type])

func _tester_simulation():
	"""Simuler le placement du joueur sur différentes cases"""
	print("🎮 Simulation de déplacements...")
	
	# Sauvegarder la position initiale
	var position_initiale = joueur.global_position
	print("Position initiale du joueur: %s" % position_initiale)
	
	# Test sur un bonus
	print("\n🟢 Test placement sur bonus:")
	joueur.global_position = Vector2(479, 982)  # Position du Bonus 1
	var bonus_detecte = gestionnaire_pieges.verifier_bonus(joueur.global_position)
	if not bonus_detecte.is_empty():
		print("Bonus détecté: %s" % bonus_detecte.nom)
		gestionnaire_pieges.appliquer_bonus(joueur, bonus_detecte)
	
	await get_tree().create_timer(1.0).timeout  # Attendre pour voir l'effet
	
	# Test sur un piège
	print("\n🔴 Test placement sur piège:")
	joueur.global_position = Vector2(1825, 982)  # Position du Piège 1
	var piege_detecte = gestionnaire_pieges.verifier_piege(joueur.global_position)
	if not piege_detecte.is_empty():
		print("Piège détecté: %s" % piege_detecte.nom)
		gestionnaire_pieges.appliquer_piege(joueur, piege_detecte)
	
	await get_tree().create_timer(1.0).timeout  # Attendre pour voir l'effet
	
	# Restaurer la position initiale
	print("\n🔄 Restauration de la position initiale")
	joueur.global_position = position_initiale

func _input(event):
	"""Contrôles de test avec le clavier"""
	if event.is_action_pressed("ui_accept"):  # Barre espace
		print("\n🔄 Relancement des tests")
		_lancer_tests()
	
	elif event.is_action_pressed("ui_cancel"):  # Échap
		print("\n📍 Position actuelle du joueur: %s" % joueur.global_position)
		
		# Vérifier s'il y a un piège ou bonus à cette position
		var piege = gestionnaire_pieges.verifier_piege(joueur.global_position)
		var bonus = gestionnaire_pieges.verifier_bonus(joueur.global_position)
		
		if not piege.is_empty():
			print("🔴 Piège détecté: %s" % piege.nom)
		elif not bonus.is_empty():
			print("🟢 Bonus détecté: %s" % bonus.nom)
		else:
			print("⚪ Aucun piège/bonus à cette position")
	
	elif event.is_action_pressed("ui_select"):  # Tab
		print("\n👁️ Basculer la visibilité des marqueurs")
		gestionnaire_pieges.basculer_marqueurs()
	
	elif event.is_action_pressed("ui_home"):  # Home
		print("\n➕ Test d'ajout de piège/bonus dynamique")
		_tester_ajout_dynamique()
	
	elif event.is_action_pressed("ui_end"):  # End
		print("\n➖ Test de suppression de piège/bonus")
		_tester_suppression()

func _tester_ajout_dynamique():
	"""Tester l'ajout dynamique de pièges et bonus"""
	# Ajouter un piège temporaire
	var pos_test = joueur.global_position + Vector2(100, 0)
	gestionnaire_pieges.ajouter_piege(pos_test.x, pos_test.y, "Piège Test", 80)
	
	# Ajouter un bonus temporaire
	var pos_test2 = joueur.global_position + Vector2(-100, 0)
	gestionnaire_pieges.ajouter_bonus(pos_test2.x, pos_test2.y, "Bonus Test", 120)
	
	print("Piège et bonus de test ajoutés près du joueur")

func _tester_suppression():
	"""Tester la suppression de pièges et bonus"""
	# Supprimer les éléments de test s'ils existent
	gestionnaire_pieges.supprimer_piege("Piège Test")
	gestionnaire_pieges.supprimer_bonus("Bonus Test")
	
	print("Éléments de test supprimés")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("\n📊 Tests terminés")
		print("🎮 Contrôles disponibles:")
		print("  - ESPACE: Relancer les tests")
		print("  - ÉCHAP: Vérifier position actuelle")
		print("  - TAB: Basculer marqueurs visuels")
		print("  - HOME: Ajouter piège/bonus test")
		print("  - END: Supprimer éléments test")
		get_tree().quit()
