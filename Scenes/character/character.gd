extends CharacterBody2D

@onready var animated_sprite = get_node("AnimatedSprite2D")

var entier : int = 12
var reel : float = 12.5
var texte : String = "pouet pouet je vais dans les bois"
var booleen : bool = false

var speed = 300.0
var direction = Vector2.ZERO
var gravity_scale : float = 0.0  # Désactiver la gravité
var controle_manuel = false  # Par défaut, le contrôle manuel est désactivé
var nom_joueur: String = ""
var couleur_personnage: Color = Color.WHITE  # Couleur par défaut

# Palette de couleurs uniques pour chaque personnage
var couleurs_disponibles = [
	Color(0.0, 0.0, 0.0),    # Noir
	Color(0.2, 1.0, 0.2),    # Vert vif
	Color(1.0, 0.2, 0.2),    # Rouge vif
	Color(1.0, 1.0, 1.0)     # Blanc (couleur normale de départ)
]

func _ready() -> void:
	if has_node("EtiquetteNom"):
		$EtiquetteNom.text = nom_joueur
	
	# Appliquer une couleur unique basée sur le nom du personnage
	appliquer_couleur_unique()

func _process(delta: float) -> void:
	if controle_manuel:  # Seulement si le contrôle manuel est activé
		velocity = direction * speed
		move_and_slide()

func _input(event: InputEvent) -> void:
	if not controle_manuel:  # Ignorer les entrées clavier si le contrôle manuel est désactivé
		return
		
	direction.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	direction.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))

	if direction == Vector2.ZERO:
		animated_sprite.stop()
		animated_sprite.set_frame(0)
	else:
		direction = direction.normalized()

		if direction.x > 0:
			animated_sprite.play("MoveRight")
		elif direction.x < 0:
			animated_sprite.play("MoveLeft")
		elif direction.y > 0:
			animated_sprite.play("MoveDown")
		elif direction.y < 0:
			animated_sprite.play("MoveUp")

# Fonction pour activer/désactiver le contrôle manuel
func set_controle_manuel(actif: bool) -> void:
	controle_manuel = actif
	if not actif:
		direction = Vector2.ZERO
		velocity = Vector2.ZERO
		animated_sprite.stop()
		animated_sprite.set_frame(0)

# Définir le nom affiché au-dessus de la tête
func definir_nom_joueur(nouveau_nom: String) -> void:
	nom_joueur = String(nouveau_nom)
	if has_node("EtiquetteNom"):
		$EtiquetteNom.text = nom_joueur
	
	# Réappliquer la couleur quand le nom change
	appliquer_couleur_unique()

# Appliquer une couleur unique basée sur le nom du personnage
func appliquer_couleur_unique() -> void:
	if nom_joueur.is_empty():
		return
	
	# Utiliser le hash du nom pour déterminer la couleur
	var hash_nom = nom_joueur.hash()
	var index_couleur = abs(hash_nom) % couleurs_disponibles.size()
	couleur_personnage = couleurs_disponibles[index_couleur]
	
	# Appliquer la couleur au sprite
	if has_node("AnimatedSprite2D"):
		var sprite = get_node("AnimatedSprite2D")
		sprite.modulate = couleur_personnage
		print("🎨 Couleur appliquée à %s: %s (index: %d)" % [nom_joueur, couleur_personnage, index_couleur])
	
	# Appliquer aussi la couleur à l'étiquette du nom si elle existe
	if has_node("EtiquetteNom"):
		var etiquette = get_node("EtiquetteNom")
		etiquette.modulate = couleur_personnage

# Définir manuellement une couleur spécifique
func definir_couleur_manuelle(nouvelle_couleur: Color) -> void:
	couleur_personnage = nouvelle_couleur
	
	# Appliquer la couleur au sprite
	if has_node("AnimatedSprite2D"):
		var sprite = get_node("AnimatedSprite2D")
		sprite.modulate = couleur_personnage
		print("🎨 Couleur manuelle appliquée à %s: %s" % [nom_joueur, couleur_personnage])
	
	# Appliquer aussi la couleur à l'étiquette du nom
	if has_node("EtiquetteNom"):
		var etiquette = get_node("EtiquetteNom")
		etiquette.modulate = couleur_personnage

# Obtenir la couleur actuelle du personnage
func obtenir_couleur() -> Color:
	return couleur_personnage

# Réinitialiser la couleur à la couleur par défaut
func reinitialiser_couleur() -> void:
	couleur_personnage = Color.WHITE

	# Appliquer la couleur par défaut au sprite
	if has_node("AnimatedSprite2D"):
		var sprite = get_node("AnimatedSprite2D")
		sprite.modulate = couleur_personnage
		print("🎨 Couleur réinitialisée pour %s" % nom_joueur)

	# Appliquer aussi la couleur par défaut à l'étiquette du nom
	if has_node("EtiquetteNom"):
		var etiquette = get_node("EtiquetteNom")
		etiquette.modulate = couleur_personnage

# Restaurer l'apparence complète après un effet (piège/bonus/téléportation).
# Remet visibilité, échelle, rotation, speed_scale à la normale ET restaure
# la couleur unique du joueur (ne pas utiliser Color.WHITE qui efface la couleur hash).
func restaurer_apparence() -> void:
	visible = true
	modulate = Color.WHITE
	scale = Vector2.ONE
	rotation = 0.0
	if has_node("AnimatedSprite2D"):
		var sprite = get_node("AnimatedSprite2D")
		sprite.visible = true
		sprite.scale = Vector2.ONE
		sprite.rotation = 0.0
		sprite.speed_scale = 1.0
		sprite.modulate = couleur_personnage
	if has_node("EtiquetteNom"):
		var etiquette = get_node("EtiquetteNom")
		etiquette.visible = true
		etiquette.modulate = couleur_personnage
