extends Control
class_name EffetPopup

@onready var label_effet: Label = $PanelContainer/VBox/LabelEffet
@onready var label_description: Label = $PanelContainer/VBox/LabelDescription
@onready var panel_container: PanelContainer = $PanelContainer

var tween_popup: Tween

func _ready():
	visible = false
	modulate.a = 0.0

func afficher_effet(message: String, description: String, couleur: Color, duree: float = 3.0):
	label_effet.text = message
	label_description.text = description
	
	# Couleur du panneau selon le type d'effet
	var style_box = panel_container.get_theme_stylebox("panel")
	if style_box:
		style_box = style_box.duplicate()
		style_box.bg_color = couleur
		style_box.bg_color.a = 0.9
		panel_container.add_theme_stylebox_override("panel", style_box)
	
	# Animation d'apparition
	visible = true
	if tween_popup:
		tween_popup.kill()
	
	tween_popup = create_tween()
	tween_popup.set_parallel(true)
	
	# Fade in
	tween_popup.tween_property(self, "modulate:a", 1.0, 0.3)
	
	# Scale bounce
	scale = Vector2(0.5, 0.5)
	tween_popup.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_popup.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.2)
	
	# Attendre puis disparaître
	await get_tree().create_timer(duree).timeout
	_masquer_effet()

func _masquer_effet():
	if tween_popup:
		tween_popup.kill()
	
	tween_popup = create_tween()
	tween_popup.set_parallel(true)
	
	# Fade out
	tween_popup.tween_property(self, "modulate:a", 0.0, 0.3)
	tween_popup.tween_property(self, "scale", Vector2(0.8, 0.8), 0.3)
	
	await tween_popup.finished
	visible = false
