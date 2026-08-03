extends Control
## Écran des réglages de Quizzy — même identité visuelle que l'écran-titre.
## Volume des sons + couper le son (mémorisés via SoundManager),
## plein écran (PC uniquement), et retour à l'écran-titre.

const TITRE_SCENE := "res://Scenes/menu/title_screen.tscn"

func _ready() -> void:
	UITheme.fond_ciel(self)

	# Carte blanche centrée
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	var carte := PanelContainer.new()
	carte.custom_minimum_size = Vector2(580, 0)
	carte.add_theme_stylebox_override("panel", UITheme.style_carte_claire())
	centre.add_child(carte)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 26)
	carte.add_child(v)

	# Titre
	var titre := Label.new()
	titre.text = "Options"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 52)
	titre.add_theme_color_override("font_color", UITheme.MENU_TEXTE)
	v.add_child(titre)

	# Volume des sons
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(240, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.set_value_no_signal(SoundManager.obtenir_volume_effets())
	slider.value_changed.connect(_sur_volume)
	v.add_child(_ligne("Volume des sons", slider))

	# Couper le son
	var chk_son := CheckButton.new()
	chk_son.set_pressed_no_signal(SoundManager.est_mute())
	chk_son.toggled.connect(_sur_mute)
	v.add_child(_ligne("Couper le son", chk_son))

	# Plein écran (PC uniquement)
	if not OS.has_feature("web"):
		var chk_fs := CheckButton.new()
		chk_fs.set_pressed_no_signal(
			DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		)
		chk_fs.toggled.connect(_sur_plein_ecran)
		v.add_child(_ligne("Plein écran", chk_fs))

	# Bouton retour
	var retour := UITheme.bouton_menu("Retour", UITheme.MENU_BLEU, Vector2(0, 60))
	retour.size_flags_horizontal = Control.SIZE_FILL
	retour.pressed.connect(_sur_retour)
	v.add_child(retour)

	# Entrée animée
	UITheme.animer_entree(carte, 0.0)

## Construit une ligne « Libellé .......... [contrôle] » (texte foncé sur carte claire).
func _ligne(libelle: String, controle: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	var lbl := Label.new()
	lbl.text = libelle
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", UITheme.MENU_TEXTE)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(lbl)
	h.add_child(controle)
	return h

func _sur_volume(valeur: float) -> void:
	SoundManager.definir_volume_effets(valeur)
	SoundManager.jouer("click")  # aperçu immédiat du niveau

func _sur_mute(actif: bool) -> void:
	SoundManager.definir_mute(actif)
	if not actif:
		SoundManager.jouer("click")

func _sur_plein_ecran(actif: bool) -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if actif else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func _sur_retour() -> void:
	SoundManager.jouer("click")
	get_tree().change_scene_to_file(TITRE_SCENE)
