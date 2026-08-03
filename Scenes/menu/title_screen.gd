extends Control
## Écran-titre de Quizzy : logo + mascotte grenouille + boutons.
## Look partagé avec les Options et le lobby (voir UITheme, thème « menu clair »).
## Les images sont chargées si présentes, sinon versions texte/emoji.

const JEU_SCENE := "res://Scenes/Levels/level.tscn"
const OPTIONS_SCENE := "res://Scenes/menu/options_screen.tscn"
const LOGO_QUIZZY := "res://assets/branding/quizzy_logo.png"
const MASCOTTE := "res://assets/branding/quizzy_grenouille.png"

func _ready() -> void:
	UITheme.fond_ciel(self)

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 18)
	add_child(v)

	# Logo Quizzy (image ou texte stylé)
	if ResourceLoader.exists(LOGO_QUIZZY):
		var t := TextureRect.new()
		t.texture = load(LOGO_QUIZZY)
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.custom_minimum_size = Vector2(0, 180)
		v.add_child(t)
	else:
		var titre := Label.new()
		titre.text = "Quizzy"
		titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		titre.add_theme_font_size_override("font_size", 110)
		titre.add_theme_color_override("font_color", Color(1, 1, 1))
		titre.add_theme_color_override("font_outline_color", UITheme.MENU_TEXTE)
		titre.add_theme_constant_override("outline_size", 14)
		v.add_child(titre)

	# Mascotte dans un support fixe : le VBox positionne le support, et la
	# mascotte flotte librement à l'intérieur (le support n'est pas un Container).
	var support := Control.new()
	support.custom_minimum_size = Vector2(0, 170)
	support.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(support)

	var mascotte: Control
	if ResourceLoader.exists(MASCOTTE):
		var m := TextureRect.new()
		m.texture = load(MASCOTTE)
		m.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mascotte = m
	else:
		var em := Label.new()
		em.text = "🐸"
		em.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		em.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		em.add_theme_font_size_override("font_size", 150)
		mascotte = em
	mascotte.set_anchors_preset(Control.PRESET_FULL_RECT)
	mascotte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	support.add_child(mascotte)
	_faire_flotter(mascotte)

	# Petit espace avant les boutons
	var espace := Control.new()
	espace.custom_minimum_size = Vector2(0, 10)
	v.add_child(espace)

	# Boutons (vert = jouer, bleu = options, rouge = quitter)
	var b_jouer := UITheme.bouton_menu("Jouer", UITheme.MENU_VERT, Vector2(300, 72))
	b_jouer.pressed.connect(_sur_jouer)
	v.add_child(b_jouer)

	var b_options := UITheme.bouton_menu("Options", UITheme.MENU_BLEU, Vector2(300, 64))
	b_options.pressed.connect(_sur_options)
	v.add_child(b_options)

	if not OS.has_feature("web"):
		var b_quitter := UITheme.bouton_menu("Quitter", UITheme.MENU_ROUGE, Vector2(300, 64))
		b_quitter.pressed.connect(_sur_quitter)
		v.add_child(b_quitter)

	# Entrée animée en cascade
	for i in range(v.get_child_count()):
		var enfant := v.get_child(i)
		if enfant is CanvasItem:
			UITheme.animer_entree(enfant, 0.06 * i)

## Léger va-et-vient vertical en boucle pour donner vie à la mascotte.
func _faire_flotter(noeud: Control) -> void:
	await get_tree().process_frame  # attendre que le layout fixe la position
	var y0 := noeud.position.y
	var tw := create_tween().set_loops()
	tw.tween_property(noeud, "position:y", y0 - 12.0, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(noeud, "position:y", y0, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _sur_jouer() -> void:
	SoundManager.jouer("click")
	get_tree().change_scene_to_file(JEU_SCENE)

func _sur_options() -> void:
	SoundManager.jouer("click")
	get_tree().change_scene_to_file(OPTIONS_SCENE)

func _sur_quitter() -> void:
	get_tree().quit()
