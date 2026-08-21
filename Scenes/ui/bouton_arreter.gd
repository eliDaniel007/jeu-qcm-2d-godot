extends Control

# Script pour gérer le bouton ARRÊTER avec confirmation
# Utilise ConfirmationDialog natif de Godot pour plus de simplicité

@onready var bouton_arreter: Button = $BoutonArreterUI

# Menu pause personnalisé (aux couleurs de Quizzy)
var popup: CanvasLayer = null

func _ready():
	print("=== INITIALISATION BOUTON ARRÊTER ===")
	
	# Vérifier que le bouton est trouvé
	if bouton_arreter:
		print("✅ Bouton ARRÊTER trouvé")
		# Connecter le signal du bouton
		bouton_arreter.pressed.connect(_on_bouton_arreter_pressed)
	else:
		print("❌ Bouton ARRÊTER NON TROUVÉ")
	
	# Masquer le bouton ARRÊTER au démarrage (sera affiché quand une partie commence)
	visible = false
	print("Bouton ARRÊTER masqué au démarrage")
	print("=== FIN INITIALISATION ===")

func _on_bouton_arreter_pressed():
	"""Appelé quand le bouton Arrêter est pressé"""
	print("Bouton arrêter pressé - demande de confirmation...")
	_demander_confirmation_arret()

func _demander_confirmation_arret():
	"""Affiche un menu pause personnalisé (même identité que les menus)."""
	if popup and is_instance_valid(popup):
		return
	# CanvasLayer : rend en plein écran, au-dessus du jeu.
	popup = CanvasLayer.new()
	popup.layer = 200
	add_child(popup)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP  # bloque le jeu derrière
	popup.add_child(dim)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.add_child(centre)

	var carte := PanelContainer.new()
	carte.custom_minimum_size = Vector2(560, 0)
	carte.add_theme_stylebox_override("panel", UITheme.style_carte_claire())
	centre.add_child(carte)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	carte.add_child(v)

	var titre := Label.new()
	titre.text = "Pause"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 48)
	titre.add_theme_color_override("font_color", UITheme.MENU_TEXTE)
	v.add_child(titre)

	var msg := Label.new()
	msg.text = "Que veux-tu faire ?"
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 24)
	msg.add_theme_color_override("font_color", UITheme.MENU_TEXTE_DOUX)
	v.add_child(msg)

	v.add_child(_bouton_popup("Reprendre", UITheme.MENU_BLEU, _fermer_popup))
	v.add_child(_bouton_popup("Recommencer", Color(0.98, 0.55, 0.20), _arreter_jeu))
	v.add_child(_bouton_popup("Changer de niveau", Color(0.55, 0.42, 0.90), _changer_niveau))

func _bouton_popup(txt: String, couleur: Color, cb: Callable) -> Button:
	var b := UITheme.bouton_menu(txt, couleur, Vector2(0, 58))
	b.size_flags_horizontal = Control.SIZE_FILL
	b.pressed.connect(cb)
	return b

func _fermer_popup():
	SoundManager.jouer("click")
	if popup and is_instance_valid(popup):
		popup.queue_free()
		popup = null

func _changer_niveau():
	SoundManager.jouer("click")
	get_tree().change_scene_to_file("res://Scenes/menu/palier_screen.tscn")

func _arreter_jeu():
	"""Arrête le jeu complètement et redémarre une nouvelle partie"""
	print("🔄 REDÉMARRAGE COMPLET DU JEU...")
	
	# Afficher un message de confirmation
	_afficher_message_redemarrage()
	
	# Attendre un court moment pour que l'utilisateur voie le message
	await get_tree().create_timer(0.5).timeout
	
	# Recharger complètement la scène pour une nouvelle partie
	get_tree().reload_current_scene()

func _afficher_message_redemarrage():
	"""Affiche un message temporaire de redémarrage"""
	# Créer un label temporaire pour afficher le message
	var message_label = Label.new()
	message_label.text = "Redémarrage en cours..."
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
	add_child(fond)
	add_child(message_label)
	
	print("Message de redémarrage affiché")

# Fonction pour afficher/masquer le bouton (appelée depuis l'extérieur)
func set_bouton_visible(visible_state: bool):
	visible = visible_state
