extends Control
class_name EffetPopup

@onready var label_effet: Label = $PanelContainer/VBox/LabelEffet
@onready var label_description: Label = $PanelContainer/VBox/LabelDescription
@onready var panel_container: PanelContainer = $PanelContainer

var tween_popup: Tween

# Association type d'effet → couleur (utilisée par afficher_par_type)
const COULEURS_PAR_TYPE = {
	"bonus":          Color(0.35, 0.80, 0.45),
	"piege":          Color(0.95, 0.35, 0.40),
	"course_rapide":  Color(1.00, 0.75, 0.25),
	"teleportation":  Color(0.60, 0.50, 0.95),
	"vol":            Color(0.50, 0.80, 0.95),
	"saut":           Color(0.60, 0.90, 0.50),
	"boost":          Color(0.98, 0.55, 0.25),
	"multiplicateur": Color(1.00, 0.84, 0.20),
	"bouclier":       Color(0.40, 0.70, 0.95),
	"tornade":        Color(0.75, 0.70, 0.95),
	"info":           Color(0.26, 0.58, 0.98),
}

func _ready():
	visible = false
	modulate.a = 0.0
	# Typographie cohérente avec le thème
	if label_effet:
		label_effet.add_theme_color_override("font_color", Color.WHITE)
		label_effet.add_theme_font_size_override("font_size", 28)
	if label_description:
		label_description.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 0.95))
		label_description.add_theme_font_size_override("font_size", 18)

func afficher_par_type(message: String, description: String, type_effet: String, duree: float = 3.0):
	var couleur = COULEURS_PAR_TYPE.get(type_effet, COULEURS_PAR_TYPE["info"])
	afficher_effet(message, description, couleur, duree)

func afficher_effet(message: String, description: String, couleur: Color, duree: float = 3.0):
	label_effet.text = message
	label_description.text = description

	# Style panneau cohérent avec UITheme (bords arrondis + bordure contrastée)
	var sb := StyleBoxFlat.new()
	sb.bg_color = couleur
	sb.bg_color.a = 0.92
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 3
	sb.border_color = couleur.darkened(0.3)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	panel_container.add_theme_stylebox_override("panel", sb)
	
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
