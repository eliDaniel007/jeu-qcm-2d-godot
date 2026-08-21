extends CanvasLayer
## Voile plein écran « Tourne ton téléphone » affiché quand l'écran est en
## portrait. Quizzy se joue en paysage. Autoload « OrientationGuard ».
## Web-safe (icône dessinée), et sans effet sur PC (toujours paysage).

var _voile: Control

func _ready() -> void:
	layer = 128  # au-dessus de tout le reste
	process_mode = Node.PROCESS_MODE_ALWAYS  # visible même si le jeu est en pause
	_forcer_cadrage()
	_voile = _construire_voile()
	add_child(_voile)
	get_viewport().size_changed.connect(_maj)
	_maj()

## Force le cadrage "keep" au RUNTIME (indépendant de project.godot, qui perd
## parfois le réglage à l'export). Garantit le plateau entier, sans répétition.
func _forcer_cadrage() -> void:
	var w := get_window()
	if w:
		w.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		w.content_scale_size = Vector2i(2650, 1080)

func _maj() -> void:
	# Taille PHYSIQUE de la fenêtre/canvas (pas la taille logique 2650x1080,
	# qui reste toujours en paysage à cause du stretch).
	var w := DisplayServer.window_get_size()
	# Portrait = nettement plus haut que large.
	_voile.visible = float(w.y) > float(w.x) * 1.05

func _construire_voile() -> Control:
	var racine := Control.new()
	racine.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.mouse_filter = Control.MOUSE_FILTER_STOP  # bloque le jeu derrière

	var fond := ColorRect.new()
	fond.color = Color(0.15, 0.28, 0.42)
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	racine.add_child(fond)

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 26)
	racine.add_child(v)

	# Icône de rotation dessinée
	var support := Control.new()
	support.custom_minimum_size = Vector2(0, 180)
	v.add_child(support)
	var icone: Control = load("res://Scenes/menu/icone_rotation.gd").new()
	icone.set_anchors_preset(Control.PRESET_FULL_RECT)
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	support.add_child(icone)

	var texte := Label.new()
	texte.text = "Tourne ton téléphone\nà l'horizontale"
	texte.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texte.add_theme_font_size_override("font_size", 40)
	texte.add_theme_color_override("font_color", Color(1, 1, 1))
	v.add_child(texte)

	return racine
