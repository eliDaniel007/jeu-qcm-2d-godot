extends Control
## Frimousse de grenouille dessinée (aucune police/emoji requis → marche sur web).
## Sert de mascotte de repli tant que quizzy_grenouille.png n'est pas fourni.

func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var s := size
	if s.x <= 0 or s.y <= 0:
		return
	var c := s / 2.0
	var r: float = min(s.x, s.y) * 0.32
	var vert := Color(0.30, 0.72, 0.38)
	var vert_fonce := Color(0.20, 0.52, 0.28)

	var ex := r * 0.60      # écart horizontal des yeux
	var ey := -r * 0.78     # hauteur des yeux (au-dessus de la tête)

	# Bosses des yeux
	draw_circle(c + Vector2(-ex, ey), r * 0.44, vert)
	draw_circle(c + Vector2(ex, ey), r * 0.44, vert)
	# Tête
	draw_circle(c, r, vert)
	# Blanc des yeux
	draw_circle(c + Vector2(-ex, ey), r * 0.28, Color.WHITE)
	draw_circle(c + Vector2(ex, ey), r * 0.28, Color.WHITE)
	# Pupilles
	draw_circle(c + Vector2(-ex, ey), r * 0.13, Color(0.1, 0.1, 0.1))
	draw_circle(c + Vector2(ex, ey), r * 0.13, Color(0.1, 0.1, 0.1))
	# Sourire (arc)
	draw_arc(c + Vector2(0, r * 0.18), r * 0.52, deg_to_rad(25), deg_to_rad(155), 32, vert_fonce, 5.0, true)
	# Deux narines
	draw_circle(c + Vector2(-r * 0.14, -r * 0.05), r * 0.05, vert_fonce)
	draw_circle(c + Vector2(r * 0.14, -r * 0.05), r * 0.05, vert_fonce)
