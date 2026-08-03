extends Control
## Choix du palier de difficulté (le jeu qui « grandit » avec l'enfant).
## Tous les paliers sont GRATUITS et débloqués. Même identité visuelle que
## l'écran-titre / les options (voir UITheme, thème « menu clair »).

const JEU_SCENE := "res://Scenes/Levels/level.tscn"
const TITRE_SCENE := "res://Scenes/menu/title_screen.tscn"

# Ordre d'affichage + couleur de chaque palier.
const PALIERS := [
	{"id": "decouverte", "couleur": Color(0.30, 0.78, 0.45)},  # vert
	{"id": "malin",      "couleur": Color(0.98, 0.55, 0.20)},  # orange
	{"id": "expert",     "couleur": Color(0.55, 0.42, 0.90)},  # violet
]

func _ready() -> void:
	UITheme.fond_ciel(self)

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 22)
	add_child(v)

	# Titre
	var titre := Label.new()
	titre.text = "Choisis ton niveau"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 64)
	titre.add_theme_color_override("font_color", Color(1, 1, 1))
	titre.add_theme_color_override("font_outline_color", UITheme.MENU_TEXTE)
	titre.add_theme_constant_override("outline_size", 12)
	v.add_child(titre)

	var sous_titre := Label.new()
	sous_titre.text = "Le jeu grandit avec toi 🐸"
	sous_titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sous_titre.add_theme_font_size_override("font_size", 26)
	sous_titre.add_theme_color_override("font_color", UITheme.MENU_TEXTE)
	v.add_child(sous_titre)

	var espace := Control.new()
	espace.custom_minimum_size = Vector2(0, 8)
	v.add_child(espace)

	# Un gros bouton par palier
	for p in PALIERS:
		var infos: Dictionary = Partie.INFOS[p.id]
		var texte := "%s  %s   ·   %s" % [infos.emoji, infos.nom, infos.age]
		var b := UITheme.bouton_menu(texte, p.couleur, Vector2(500, 88))
		b.add_theme_font_size_override("font_size", 32)
		b.pressed.connect(_sur_palier.bind(p.id))
		v.add_child(b)

	# Retour
	var retour := UITheme.bouton_menu("Retour", UITheme.MENU_BLEU, Vector2(500, 60))
	retour.add_theme_font_size_override("font_size", 26)
	retour.pressed.connect(_sur_retour)
	v.add_child(retour)

	# Entrée animée en cascade
	for i in range(v.get_child_count()):
		var enfant := v.get_child(i)
		if enfant is CanvasItem:
			UITheme.animer_entree(enfant, 0.06 * i)

func _sur_palier(id: String) -> void:
	SoundManager.jouer("click")
	Partie.definir_palier(id)
	get_tree().change_scene_to_file(JEU_SCENE)

func _sur_retour() -> void:
	SoundManager.jouer("click")
	get_tree().change_scene_to_file(TITRE_SCENE)
