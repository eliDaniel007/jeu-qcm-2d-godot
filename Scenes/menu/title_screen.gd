extends Control
## Écran-titre de Quizzy : logo + mascotte grenouille + boutons.
## Les images sont chargées si présentes, sinon des versions texte/emoji
## s'affichent — l'écran fonctionne donc même avant que l'art soit prêt.

const JEU_SCENE := "res://Scenes/Levels/level.tscn"
const OPTIONS_SCENE := "res://Scenes/menu/options_screen.tscn"
const LOGO_QUIZZY := "res://assets/branding/quizzy_logo.png"
const MASCOTTE := "res://assets/branding/quizzy_grenouille.png"

func _ready() -> void:
	# Fond ciel, ambiance enfant
	var bg := ColorRect.new()
	bg.color = Color(0.42, 0.78, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 20)
	add_child(v)

	# Logo Quizzy (image ou texte stylé)
	if ResourceLoader.exists(LOGO_QUIZZY):
		var t := TextureRect.new()
		t.texture = load(LOGO_QUIZZY)
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.custom_minimum_size = Vector2(0, 170)
		v.add_child(t)
	else:
		var titre := Label.new()
		titre.text = "Quizzy"
		titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		titre.add_theme_font_size_override("font_size", 100)
		titre.add_theme_color_override("font_color", Color(1, 1, 1))
		titre.add_theme_color_override("font_outline_color", Color(0.12, 0.33, 0.52))
		titre.add_theme_constant_override("outline_size", 12)
		v.add_child(titre)

	# Mascotte (image ou emoji grenouille)
	if ResourceLoader.exists(MASCOTTE):
		var m := TextureRect.new()
		m.texture = load(MASCOTTE)
		m.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		m.custom_minimum_size = Vector2(0, 170)
		v.add_child(m)
	else:
		var em := Label.new()
		em.text = "🐸"
		em.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		em.add_theme_font_size_override("font_size", 140)
		v.add_child(em)

	# Boutons
	v.add_child(_bouton("Jouer", _sur_jouer))
	v.add_child(_bouton("Options", _sur_options))
	if not OS.has_feature("web"):
		v.add_child(_bouton("Quitter", _sur_quitter))

func _bouton(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(280, 66)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 32)
	b.pressed.connect(cb)
	return b

func _sur_jouer() -> void:
	get_tree().change_scene_to_file(JEU_SCENE)

func _sur_options() -> void:
	get_tree().change_scene_to_file(OPTIONS_SCENE)

func _sur_quitter() -> void:
	get_tree().quit()
