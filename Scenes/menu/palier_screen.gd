extends Control
## Choix du palier de difficulté (le jeu qui « grandit » avec l'enfant).
## Tous les paliers sont GRATUITS et débloqués. Même identité visuelle que
## l'écran-titre / les options (voir UITheme, thème « menu clair »).

const JEU_SCENE := "res://Scenes/Levels/level.tscn"
const TITRE_SCENE := "res://Scenes/menu/title_screen.tscn"

# Ordre d'affichage + couleur de chaque palier.
const PALIERS := [
	{"id": "malin",   "couleur": Color(0.98, 0.55, 0.20)},  # orange
	{"id": "expert",  "couleur": Color(0.55, 0.42, 0.90)},  # violet
	{"id": "genie",   "couleur": Color(0.90, 0.30, 0.38)},  # crimson
	{"id": "legende", "couleur": Color(0.24, 0.26, 0.34)},  # charbon (élite)
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
	sous_titre.text = "Le jeu grandit avec toi !"
	sous_titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sous_titre.add_theme_font_size_override("font_size", 26)
	sous_titre.add_theme_color_override("font_color", UITheme.MENU_TEXTE)
	v.add_child(sous_titre)

	var espace := Control.new()
	espace.custom_minimum_size = Vector2(0, 8)
	v.add_child(espace)

	# Un gros bouton par palier (icône = pastilles de difficulté dessinées)
	for i in range(PALIERS.size()):
		var p: Dictionary = PALIERS[i]
		var infos: Dictionary = Partie.INFOS[p.id]
		var texte := "%s   ·   %s" % [infos.nom, infos.age]
		var b := UITheme.bouton_menu(texte, p.couleur, Vector2(500, 88))
		b.add_theme_font_size_override("font_size", 32)
		b.add_theme_constant_override("h_separation", 16)
		b.icon = _icone_niveau(i + 1)
		b.expand_icon = false
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

## Fabrique une icône de n pastilles blanches (dessinée → web-safe).
## Sert d'indicateur de difficulté : 1 pastille = facile … 4 = très difficile.
func _icone_niveau(n: int) -> ImageTexture:
	var d := 22          # diamètre d'une pastille
	var esp := 8         # espacement
	var w: int = n * d + (n - 1) * esp
	var h := d
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var r := d / 2.0 - 1.0
	for i in range(n):
		var cx := i * (d + esp) + d / 2.0
		var cy := h / 2.0
		for y in range(h):
			for x in range(w):
				if Vector2(x - cx, y - cy).length() <= r:
					img.set_pixel(x, y, Color(1, 1, 1))
	return ImageTexture.create_from_image(img)

func _sur_palier(id: String) -> void:
	SoundManager.jouer("click")
	Partie.definir_palier(id)
	get_tree().change_scene_to_file(JEU_SCENE)

func _sur_retour() -> void:
	SoundManager.jouer("click")
	get_tree().change_scene_to_file(TITRE_SCENE)
