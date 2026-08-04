extends CanvasLayer
## Voile plein écran « Tourne ton téléphone » affiché quand l'écran est en
## portrait. Quizzy se joue en paysage. Autoload « OrientationGuard ».
## Web-safe (icône dessinée), et sans effet sur PC (toujours paysage).

var _voile: Control

func _ready() -> void:
	layer = 128  # au-dessus de tout le reste
	_voile = _construire_voile()
	add_child(_voile)
	get_viewport().size_changed.connect(_maj)
	_maj()

func _maj() -> void:
	var vp := get_viewport().get_visible_rect().size
	# Portrait = nettement plus haut que large.
	_voile.visible = vp.y > vp.x * 1.05

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
