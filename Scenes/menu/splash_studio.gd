extends Control
## Splash de démarrage : affiche le logo du studio (Codex Labs) en fondu,
## puis enchaîne sur l'écran-titre. Se saute au clic / toucher / touche.

const TITRE_SCENE := "res://Scenes/menu/title_screen.tscn"
const LOGO_PATH := "res://assets/branding/codex_labs.png"

var _fini := false

func _ready() -> void:
	# Fond blanc (le logo Codex est sur fond blanc)
	var bg := ColorRect.new()
	bg.color = Color(1, 1, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Logo (image si présente, sinon texte de secours)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	if ResourceLoader.exists(LOGO_PATH):
		var img := TextureRect.new()
		img.texture = load(LOGO_PATH)
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.custom_minimum_size = Vector2(440, 260)
		centre.add_child(img)
	else:
		var lbl := Label.new()
		lbl.text = "CODEX LABS"
		lbl.add_theme_font_size_override("font_size", 64)
		lbl.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
		centre.add_child(lbl)

	# Fondu : apparition -> pause -> disparition -> écran-titre
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.6)
	tw.tween_interval(1.3)
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(_aller_au_titre)

func _unhandled_input(event: InputEvent) -> void:
	var appuye := false
	if event is InputEventMouseButton and event.pressed:
		appuye = true
	elif event is InputEventScreenTouch and event.pressed:
		appuye = true
	elif event is InputEventKey and event.pressed:
		appuye = true
	if appuye:
		_aller_au_titre()

func _aller_au_titre() -> void:
	if _fini:
		return
	_fini = true
	get_tree().change_scene_to_file(TITRE_SCENE)
