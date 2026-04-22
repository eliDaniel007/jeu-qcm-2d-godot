extends CanvasLayer

# UI Design: Affichage du classement final

@onready var conteneur: VBoxContainer = $Fond/VBox

func afficher(noms_ordonnes: Array) -> void:
	# Nettoyage
	for c in conteneur.get_children():
		c.queue_free()

	# Fond: appliquer la couleur sombre du thème si un ColorRect "Fond" existe
	var fond = get_node_or_null("Fond")
	if fond and fond is ColorRect:
		fond.color = UITheme.COULEUR_FOND
		fond.color.a = 0.92

	# Titre
	var titre = Label.new()
	titre.text = "🏆 Classement Final"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_color_override("font_color", UITheme.COULEUR_ACCENT)
	titre.add_theme_font_size_override("font_size", 56)
	conteneur.add_child(titre)
	UITheme.animer_entree(titre, 0.0, 0.5)

	# Espace
	var espace = Control.new()
	espace.custom_minimum_size = Vector2(0, 30)
	conteneur.add_child(espace)

	# Lignes classement, apparition échelonnée façon podium (1er arrive en dernier pour emphase)
	var couleurs_medaille = [UITheme.OR, UITheme.ARGENT, UITheme.BRONZE]
	for i in range(noms_ordonnes.size()):
		var ligne = _creer_ligne_classement(i, noms_ordonnes[i], couleurs_medaille)
		conteneur.add_child(ligne)
		# Les suivants apparaissent d'abord, le podium (0,1,2) en dernier pour emphase
		var delai = 0.3 + (noms_ordonnes.size() - 1 - i) * 0.2
		UITheme.animer_entree(ligne, delai, 0.45)

	# Espace
	var espace2 = Control.new()
	espace2.custom_minimum_size = Vector2(0, 40)
	conteneur.add_child(espace2)

	# Boutons actions
	var actions = HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 20)

	var rejouer = Button.new()
	rejouer.text = "🔄 Rejouer"
	rejouer.custom_minimum_size = Vector2(200, 56)
	rejouer.add_theme_font_size_override("font_size", 20)
	rejouer.pressed.connect(func():
		print("🔄 Bouton REJOUER pressé !")
		queue_free()
		_redemarrer_jeu_complet()
	)

	var quitter = Button.new()
	quitter.text = "❌ Quitter"
	quitter.custom_minimum_size = Vector2(200, 56)
	quitter.add_theme_font_size_override("font_size", 20)
	quitter.pressed.connect(func():
		_quitter_jeu()
	)

	actions.add_child(rejouer)
	actions.add_child(quitter)
	conteneur.add_child(actions)

	UITheme.appliquer_bouton(rejouer, UITheme.COULEUR_SUCCES)
	UITheme.appliquer_bouton(quitter, UITheme.COULEUR_DANGER)
	UITheme.animer_entree(actions, 0.3 + noms_ordonnes.size() * 0.2 + 0.2, 0.4)

func _creer_ligne_classement(rang: int, nom: String, couleurs_medaille: Array) -> PanelContainer:
	var panel = PanelContainer.new()
	var couleur_rang = couleurs_medaille[rang] if rang < couleurs_medaille.size() else UITheme.COULEUR_FOND_CLAIR
	var sb = UITheme.style_panel(UITheme.COULEUR_FOND_CLAIR)
	sb.border_color = couleur_rang
	sb.border_width_left = 6
	panel.add_theme_stylebox_override("panel", sb)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	var emoji = ""
	match rang:
		0: emoji = "🥇"
		1: emoji = "🥈"
		2: emoji = "🥉"
		_: emoji = "🎯"

	var l_medaille = Label.new()
	l_medaille.text = emoji
	l_medaille.add_theme_font_size_override("font_size", 40)
	hbox.add_child(l_medaille)

	var l_rang = Label.new()
	l_rang.text = "%d." % (rang + 1)
	l_rang.add_theme_font_size_override("font_size", 32)
	l_rang.add_theme_color_override("font_color", couleur_rang)
	l_rang.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(l_rang)

	var l_nom = Label.new()
	l_nom.text = String(nom)
	l_nom.add_theme_font_size_override("font_size", 32)
	l_nom.add_theme_color_override("font_color", UITheme.COULEUR_TEXTE)
	hbox.add_child(l_nom)

	return panel

func _retour_lobby() -> void:
	var scene = get_tree().current_scene
	if scene == null:
		return
	# Masquer QCM s'il est visible
	var qcm = scene.get_node_or_null("UILayer/QCM")
	if qcm:
		qcm.visible = false
	# Réinitialiser path_manager
	var pm = scene.get_node_or_null("path_manager")
	if pm and pm.has_method("reinitialiser_partie"):
		pm.reinitialiser_partie()
	# Masquer le bouton ARRÊTER
	var bouton_arreter = scene.get_node_or_null("UILayer/BoutonArreter")
	if bouton_arreter and bouton_arreter.has_method("set_bouton_visible"):
		bouton_arreter.set_bouton_visible(false)
	
	# Afficher le lobby
	var lobby = scene.get_node_or_null("UILayer/Lobby")
	if lobby:
		lobby.visible = true

func _redemarrer_jeu_complet() -> void:
	"""Redémarre complètement le jeu comme le bouton arrêter - retour au lobby"""
	print("🔄 NOUVELLE PARTIE depuis le classement...")
	
	# Afficher un message de confirmation
	_afficher_message_redemarrage()
	
	# Utiliser la même logique que le bouton ARRÊTER (sans attendre)
	_arreter_partie_et_retour_lobby()

func _arreter_partie_et_retour_lobby():
	"""Logique pour arrêter la partie et retourner au lobby (même que bouton ARRÊTER)"""
	var scene = get_tree().current_scene
	if scene == null:
		print("Erreur: scène courante introuvable")
		return
	
	print("=== ARRÊT PARTIE ET RETOUR AU LOBBY ===")
	
	# APPROCHE ULTRA-SÉCURISÉE - ÉVITER TOUTES LES ERREURS
	
	# 1. Masquer le QCM simplement
	var qcm = scene.get_node_or_null("UILayer/QCM")
	if qcm:
		qcm.visible = false
		print("QCM masqué")
	
	# 2. Réinitialiser le MultiManager simplement
	var multi = scene.get_node_or_null("UILayer/QCM/MultiManager")
	if multi and multi.has_method("reinitialiser"):
		multi.reinitialiser()
		print("MultiManager réinitialisé")
	
	# 3. Réinitialiser le Path Manager simplement
	var pm = scene.get_node_or_null("path_manager")
	if pm and pm.has_method("reinitialiser_partie"):
		pm.reinitialiser_partie()
		print("Path manager réinitialisé")
	
	# 4. SUPPRIMER TOUS LES ANCIENS PERSONNAGES - NOUVELLE PARTIE COMPLÈTE
	print("=== SUPPRESSION DES ANCIENS PERSONNAGES ===")
	print("🎯 Objectif: Faire disparaître tous les anciens personnages pour une nouvelle partie")
	print("📝 Processus: Identification → Suppression → Vérification")
	
	# Créer une liste des personnages à supprimer
	var personnages_a_supprimer = []
	
	# Identifier tous les personnages existants
	for child in scene.get_children():
		# Vérification de sécurité stricte en 3 étapes
		if child == null:
			continue
		if not is_instance_valid(child):
			continue
		if not child.name:
			continue
			
		# Vérifier si c'est un personnage
		var nom = str(child.name)
		if nom.begins_with("character"):
			personnages_a_supprimer.append(child)
			print("Personnage à supprimer identifié: %s" % nom)
	
	print("Nombre de personnages à supprimer: %d" % personnages_a_supprimer.size())
	
	# Supprimer tous les anciens personnages
	for personnage in personnages_a_supprimer:
		if personnage != null and is_instance_valid(personnage):
			var nom = str(personnage.name)
			print("Suppression du personnage: %s" % nom)
			
			# Supprimer le personnage de la scène
			personnage.queue_free()
			print("Personnage %s supprimé" % nom)
	
	print("Tous les anciens personnages ont été supprimés")
	print("La scène est prête pour de nouveaux personnages")
	
	# Préparer les couleurs pour les nouveaux personnages
	print("🎨 Préparation des couleurs pour les nouveaux personnages")
	var couleurs_personnages = [
		"⚫ Noir",
		"🟢 Vert vif",
		"🔴 Rouge vif",
		"⚪ Blanc (normal)"
	]
	print("Palette de couleurs disponible: %s" % couleurs_personnages)
	
	# Vérification que tous les personnages ont été supprimés
	var compteur_restants = 0
	for child in scene.get_children():
		if child != null and is_instance_valid(child) and child.name:
			var nom = str(child.name)
			if nom.begins_with("character"):
				compteur_restants += 1
				print("⚠️ ATTENTION: Personnage %s est encore présent!" % nom)
	
	if compteur_restants == 0:
		print("✅ Vérification OK: Aucun personnage restant")
	else:
		print("❌ Problème: %d personnages sont encore présents" % compteur_restants)
	
	# 5. Masquer le bouton ARRÊTER
	var bouton_arreter = scene.get_node_or_null("UILayer/BoutonArreter")
	if bouton_arreter and bouton_arreter.has_method("set_bouton_visible"):
		bouton_arreter.set_bouton_visible(false)
		print("Bouton ARRÊTER masqué")
	
	# 6. Afficher le lobby
	var lobby = scene.get_node_or_null("UILayer/Lobby")
	if lobby:
		# Vider les champs de noms
		var champs_noms = lobby.get_node_or_null("Fond/VBox/Noms/HBox")
		if champs_noms:
			for i in range(champs_noms.get_child_count()):
				var champ = champs_noms.get_child(i)
				if champ and champ is LineEdit:
					champ.text = ""
					champ.editable = true
					champ.modulate = Color(1, 1, 1, 1)
		
		# Remettre les participants à 2
		var boutons_participants = lobby.get_node_or_null("Fond/VBox/ChoixParticipants/HBox")
		if boutons_participants:
			for i in range(boutons_participants.get_child_count()):
				var bouton = boutons_participants.get_child(i)
				if bouton and bouton is Button:
					bouton.button_pressed = (i == 0)
		
		# Afficher le lobby
		lobby.visible = true
		lobby.show()
		print("Lobby affiché et réinitialisé")
	
	print("=== PARTIE ARRÊTÉE - RETOUR AU LOBBY COMPLET ===")

func _quitter_jeu() -> void:
	"""Ferme complètement le jeu"""
	print("❌ FERMETURE DU JEU...")
	
	# Afficher un message de confirmation
	_afficher_message_quitter()
	
	# Attendre un court moment
	await get_tree().create_timer(0.5).timeout
	
	# Fermer le jeu
	get_tree().quit()

func _afficher_message_redemarrage():
	"""Affiche un message temporaire de redémarrage"""
	print("Affichage du message de redémarrage...")
	
	# Créer un label temporaire pour afficher le message
	var message_label = Label.new()
	message_label.text = "🔄 Retour au lobby..."
	message_label.add_theme_font_size_override("font_size", 32)
	message_label.add_theme_color_override("font_color", Color.WHITE)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Positionner le message au centre de l'écran
	message_label.anchors_preset = Control.PRESET_FULL_RECT
	message_label.z_index = 1000  # Au-dessus de tout
	
	# Ajouter un fond semi-transparent
	var fond = ColorRect.new()
	fond.color = Color(0, 0, 0, 0.7)  # Noir semi-transparent
	fond.anchors_preset = Control.PRESET_FULL_RECT
	fond.z_index = 999
	
	# Ajouter à la scène
	var scene = get_tree().current_scene
	if scene:
		scene.add_child(fond)
		scene.add_child(message_label)
		print("Message de redémarrage ajouté à la scène")
		
		# Supprimer le message après 2 secondes
		get_tree().create_timer(2.0).timeout.connect(func():
			if fond and is_instance_valid(fond):
				fond.queue_free()
			if message_label and is_instance_valid(message_label):
				message_label.queue_free()
			print("Message de redémarrage supprimé")
		)
	else:
		print("Erreur: Scène courante introuvable pour le message")
	
	print("Message de redémarrage affiché")

func _afficher_message_quitter():
	"""Affiche un message temporaire de fermeture"""
	# Créer un label temporaire pour afficher le message
	var message_label = Label.new()
	message_label.text = "❌ Fermeture du jeu..."
	message_label.add_theme_font_size_override("font_size", 32)
	message_label.add_theme_color_override("font_color", Color.WHITE)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Positionner le message au centre de l'écran
	message_label.anchors_preset = Control.PRESET_FULL_RECT
	message_label.z_index = 1000  # Au-dessus de tout
	
	# Ajouter un fond semi-transparent
	var fond = ColorRect.new()
	fond.color = Color(0, 0, 0, 0.7)  # Noir semi-transparent
	fond.anchors_preset = Control.PRESET_FULL_RECT
	fond.z_index = 999
	
	# Ajouter à la scène
	get_tree().current_scene.add_child(fond)
	get_tree().current_scene.add_child(message_label)
	
	print("Message de fermeture affiché")
