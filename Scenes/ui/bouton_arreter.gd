extends Control

# Script pour gérer le bouton ARRÊTER avec confirmation
# Utilise ConfirmationDialog natif de Godot pour plus de simplicité

@onready var bouton_arreter: Button = $BoutonArreterUI

# Variable pour stocker la référence au dialog de confirmation
var dialog_confirmation: ConfirmationDialog = null

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
	"""Affiche une boîte de dialogue de confirmation avant l'arrêt"""
	# Créer une boîte de dialogue de confirmation
	dialog_confirmation = ConfirmationDialog.new()
	dialog_confirmation.title = "Arrêter la partie"
	dialog_confirmation.dialog_text = "Êtes-vous sûr de vouloir arrêter ?\nCela redémarrera complètement le jeu."
	
	# Connecter les signaux
	dialog_confirmation.confirmed.connect(_arreter_jeu)
	dialog_confirmation.canceled.connect(_on_annulation)
	
	# Ajouter à la scène et afficher
	add_child(dialog_confirmation)
	dialog_confirmation.popup_centered()
	
	print("Dialog de confirmation affiché")

func _on_annulation():
	"""Appelé quand l'utilisateur annule l'arrêt"""
	print("Arrêt annulé - la partie continue")
	# Fermer la boîte de dialogue
	if dialog_confirmation:
		dialog_confirmation.hide()
		dialog_confirmation.queue_free()
		dialog_confirmation = null
	# Ne rien faire, la partie continue normalement

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
	message_label.text = "🔄 Redémarrage en cours..."
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
