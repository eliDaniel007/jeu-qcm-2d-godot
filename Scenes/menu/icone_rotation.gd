extends Control
## Icône « tourne ton téléphone » dessinée (aucune police/emoji requis).
## Un téléphone en paysage + une flèche de rotation.

func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var s := size
	if s.x <= 0 or s.y <= 0:
		return
	var c := s / 2.0
	var w: float = min(s.x, s.y)

	# Téléphone en paysage (corps + écran)
	var corps := Vector2(w * 0.62, w * 0.40)
	var rect := Rect2(c - corps / 2.0, corps)
	draw_rect(rect, Color(1, 1, 1), true)
	draw_rect(rect, Color(0.13, 0.24, 0.34), false, 4.0)
	var ecran := Rect2(rect.position + Vector2(8, 8), rect.size - Vector2(16, 16))
	draw_rect(ecran, Color(0.42, 0.78, 0.96), true)
	# Bouton latéral (côté droit)
	draw_circle(Vector2(rect.position.x + rect.size.x + 3, c.y), 3.0, Color(0.13, 0.24, 0.34))

	# Flèche de rotation (arc au-dessus)
	var r := w * 0.46
	draw_arc(c, r, deg_to_rad(210), deg_to_rad(330), 28, Color(1, 1, 1), 6.0, true)
	# Tête de flèche à l'extrémité
	var a := deg_to_rad(330)
	var tip := c + Vector2(cos(a), sin(a)) * r
	var tangente := Vector2(-sin(a), cos(a))
	var radiale := Vector2(cos(a), sin(a))
	var p1 := tip + tangente * 13.0
	var p2 := tip - tangente * 4.0 + radiale * 12.0
	var p3 := tip - tangente * 4.0 - radiale * 12.0
	draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color(1, 1, 1))
