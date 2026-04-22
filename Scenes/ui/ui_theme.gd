class_name UITheme
extends RefCounted

# Palette centralisée pour toute l'UI du jeu.
# Importer simplement UITheme et utiliser les constantes/helpers statiques.

const COULEUR_FOND         = Color(0.08, 0.10, 0.15)
const COULEUR_FOND_CLAIR   = Color(0.14, 0.17, 0.23)
const COULEUR_PRIMAIRE     = Color(0.26, 0.58, 0.98)   # Bleu action
const COULEUR_PRIMAIRE_H   = Color(0.38, 0.68, 1.00)
const COULEUR_ACCENT       = Color(1.00, 0.75, 0.25)   # Or
const COULEUR_SUCCES       = Color(0.35, 0.80, 0.45)
const COULEUR_DANGER       = Color(0.95, 0.35, 0.40)
const COULEUR_TEXTE        = Color(0.96, 0.96, 0.98)
const COULEUR_TEXTE_DOUX   = Color(0.70, 0.72, 0.78)
const COULEUR_BORDURE      = Color(0.30, 0.35, 0.45)

const OR     = Color(1.00, 0.84, 0.20)
const ARGENT = Color(0.82, 0.85, 0.90)
const BRONZE = Color(0.80, 0.50, 0.25)

static func style_bouton(couleur_base: Color = COULEUR_PRIMAIRE) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = couleur_base
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 3
	sb.border_color = couleur_base.darkened(0.25)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

static func style_bouton_hover(couleur_base: Color = COULEUR_PRIMAIRE) -> StyleBoxFlat:
	var sb = style_bouton(couleur_base.lightened(0.12))
	sb.border_color = couleur_base
	return sb

static func style_bouton_pressed(couleur_base: Color = COULEUR_PRIMAIRE) -> StyleBoxFlat:
	var sb = style_bouton(couleur_base.darkened(0.15))
	sb.border_width_bottom = 1
	sb.content_margin_top = 9
	return sb

static func style_bouton_disabled(couleur_base: Color = COULEUR_PRIMAIRE) -> StyleBoxFlat:
	var c = couleur_base
	c.a = 0.4
	var sb = style_bouton(c)
	sb.border_color = Color(0.3, 0.3, 0.3, 0.4)
	return sb

static func style_panel(couleur: Color = COULEUR_FOND_CLAIR) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = couleur
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.border_color = COULEUR_BORDURE
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	return sb

static func style_line_edit() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = COULEUR_FOND_CLAIR
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = COULEUR_BORDURE
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

# Applique le style complet sur un Button (normal + hover + pressed + disabled)
# avec animation légère au survol (scale).
static func appliquer_bouton(bouton: Button, couleur: Color = COULEUR_PRIMAIRE) -> void:
	bouton.add_theme_stylebox_override("normal",   style_bouton(couleur))
	bouton.add_theme_stylebox_override("hover",    style_bouton_hover(couleur))
	bouton.add_theme_stylebox_override("pressed",  style_bouton_pressed(couleur))
	bouton.add_theme_stylebox_override("disabled", style_bouton_disabled(couleur))
	bouton.add_theme_stylebox_override("focus",    style_bouton_hover(couleur))
	bouton.add_theme_color_override("font_color",         COULEUR_TEXTE)
	bouton.add_theme_color_override("font_hover_color",   COULEUR_TEXTE)
	bouton.add_theme_color_override("font_pressed_color", COULEUR_TEXTE)
	bouton.add_theme_color_override("font_focus_color",   COULEUR_TEXTE)
	bouton.pivot_offset = bouton.size / 2.0
	# Animation de survol: léger scale — inliné pour éviter les problèmes
	# de Callable sur méthodes statiques (plus robuste, pas de is_connected check nécessaire
	# car on utilise un flag sur le bouton via metadata)
	if not bouton.has_meta("ui_theme_hover_connecte"):
		bouton.set_meta("ui_theme_hover_connecte", true)
		bouton.mouse_entered.connect(func():
			if not is_instance_valid(bouton) or bouton.disabled:
				return
			bouton.pivot_offset = bouton.size / 2.0
			var tw = bouton.create_tween()
			tw.tween_property(bouton, "scale", Vector2(1.06, 1.06), 0.12) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)
		bouton.mouse_exited.connect(func():
			if not is_instance_valid(bouton):
				return
			var tw = bouton.create_tween()
			tw.tween_property(bouton, "scale", Vector2(1.0, 1.0), 0.12) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)

static func appliquer_line_edit(champ: LineEdit) -> void:
	champ.add_theme_stylebox_override("normal", style_line_edit())
	var focus = style_line_edit()
	focus.border_color = COULEUR_PRIMAIRE
	champ.add_theme_stylebox_override("focus", focus)
	champ.add_theme_color_override("font_color", COULEUR_TEXTE)
	champ.add_theme_color_override("font_placeholder_color", COULEUR_TEXTE_DOUX)

# Animation d'entrée: fade-in (+ slide vertical si le nœud n'est pas dans un Container).
# Les Containers (VBoxContainer, HBoxContainer…) gèrent eux-mêmes la position de leurs
# enfants, donc on anime seulement l'opacité pour eux.
static func animer_entree(noeud: CanvasItem, delai: float = 0.0, duree: float = 0.35) -> void:
	noeud.modulate.a = 0.0
	var tw = noeud.create_tween()
	tw.tween_property(noeud, "modulate:a", 1.0, duree).set_delay(delai)
	# Slide uniquement si le parent n'est pas un Container
	if noeud is Control and not (noeud.get_parent() is Container):
		var ctrl := noeud as Control
		var pos_finale = ctrl.position
		ctrl.position = pos_finale + Vector2(0, 20)
		tw.parallel().tween_property(ctrl, "position", pos_finale, duree) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(delai)
