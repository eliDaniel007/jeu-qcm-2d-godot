extends Control
## Écran des réglages de Quizzy.
## Volume des sons + couper le son (mémorisés via SoundManager),
## plein écran (PC uniquement), et retour à l'écran-titre.

const TITRE_SCENE := "res://Scenes/menu/title_screen.tscn"

func _ready() -> void:
	# Fond ciel, cohérent avec l'écran-titre
	var bg := ColorRect.new()
	bg.color = Color(0.42, 0.78, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Panneau centré
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	var panneau := PanelContainer.new()
	panneau.custom_minimum_size = Vector2(560, 0)
	centre.add_child(panneau)

	var marge := MarginContainer.new()
	for cote in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + cote, 36)
	panneau.add_child(marge)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 26)
	marge.add_child(v)

	# Titre
	var titre := Label.new()
	titre.text = "Options"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 56)
	v.add_child(titre)

	# Volume des sons
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(260, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	var retour := Button.new()
	retour.text = "Retour"
	retour.custom_minimum_size = Vector2(0, 60)
	retour.add_theme_font_size_override("font_size", 30)
	retour.pressed.connect(_sur_retour)
	v.add_child(retour)

## Construit une ligne "Libellé ........ [contrôle]".
func _ligne(libelle: String, controle: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	var lbl := Label.new()
	lbl.text = libelle
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
