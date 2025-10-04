# Documentation - Animation de Victoire

## Vue d'ensemble

Une animation de victoire a été ajoutée au jeu qui se déclenche automatiquement lorsque le joueur atteint la position d'arrivée spécifiée : **(75, 335)**.

## Fonctionnalités Ajoutées

### 1. Détection de Position d'Arrivée

- **Position cible** : `Vector2(82, 348)` (ajustée selon la position réelle du joueur)
- **Tolérance** : 20 pixels (le joueur n'a pas besoin d'être exactement sur la position)
- **Vérification** : Se fait à chaque frame dans la fonction `_process()`

### 2. Animation de Victoire

L'animation se déroule en plusieurs phases :

#### Phase 1 - Célébration (1 seconde)
- **Saut** : Le joueur effectue un bond de 50 pixels vers le haut
- **Rotation** : Rotation complète (360°) pendant le saut
- **Animation sprite** : Continue l'animation de mouvement

#### Phase 2 - Pulsation (1.8 secondes)
- **Effet de scale** : 3 pulsations successives (1.0 → 1.5 → 1.0)
- **Transition** : Utilise une courbe sinusoïdale pour un effet fluide

#### Phase 3 - Finalisation
- **Remise à zéro** : Rotation et échelle reviennent aux valeurs par défaut
- **Arrêt sprite** : L'animation s'arrête sur la première frame
- **Message** : Affichage d'un message de félicitations dans la console

### 3. Signaux et États

- **Signal `victoire_atteinte`** : Émis au début de l'animation de victoire
- **État `animation_victoire_en_cours`** : Empêche les conflits pendant l'animation
- **État `victoire_deja_declenchee`** : Empêche les déclenchements multiples

## Modifications Apportées

### Dans `path_manager.gd` :

```gdscript
# Nouvelles variables ajoutées
var position_arrivee = Vector2(75, 335)
var animation_victoire_en_cours = false
var victoire_deja_declenchee = false

# Nouveau signal
signal victoire_atteinte
```

### Nouvelles Fonctions :

1. **`verifier_position_arrivee(position_actuelle: Vector2) -> bool`**
   - Vérifie si le joueur est dans la zone d'arrivée

2. **`declencher_animation_victoire()`**
   - Initialise et lance l'animation de victoire

3. **`animer_victoire()`**
   - Gère les différentes phases de l'animation

4. **`afficher_message_victoire()`**
   - Affiche le message de félicitations

## Comportement du Système

1. **Pendant le jeu** : La position du joueur est vérifiée en continu
2. **À l'arrivée** : Dès que le joueur entre dans la zone (75, 335) ± 10 pixels :
   - Le mouvement automatique s'arrête
   - Le contrôle manuel est désactivé
   - L'animation de victoire se lance
   - Le signal `victoire_atteinte` est émis

3. **Après l'animation** : Le joueur reste immobile à sa position finale

## Personnalisation Possible

### Changer la Position d'Arrivée
```gdscript
# Dans path_manager.gd
var position_arrivee = Vector2(nouvelle_x, nouvelle_y)
```

### Modifier la Tolérance
```gdscript
# Dans la fonction verifier_position_arrivee()
if distance_arrivee <= nouvelle_tolerance:
```

### Connecter le Signal
```gdscript
# Dans une autre scène ou script
path_manager.victoire_atteinte.connect(_on_victoire_atteinte)

func _on_victoire_atteinte():
    print("Le joueur a gagné !")
    # Ajouter ici : interface de victoire, passage au niveau suivant, etc.
```

### Tester l'Animation
```gdscript
# Pour retester l'animation après l'avoir déjà vue
path_manager.reinitialiser_victoire()
```

## Débogage

### Messages de Console
- **Approche** : Affiche la distance quand le joueur s'approche (≤ 25 pixels)
- **Victoire** : Affiche "VICTOIRE !" avec la position exacte
- **Animation** : Messages de début et fin d'animation

### Vérifier les Coordonnées
Pour vérifier la position actuelle du joueur :
```gdscript
print("Position actuelle du joueur: %s" % joueur.global_position)
```

## Notes Techniques

- L'animation utilise le système `Tween` de Godot 4.x
- Les animations sont parallèles pour un effet plus dynamique
- Le système est compatible avec le contrôle manuel et automatique du joueur
- Aucune modification n'a été apportée au script `character.gd`

## Effet Visuel

L'animation produit un effet visuellement attractif avec :
- Un saut joyeux du personnage
- Une rotation spectaculaire
- Des pulsations qui attirent l'attention
- Un message de félicitations

Cette animation améliore l'expérience utilisateur en offrant une récompense visuelle satisfaisante lors de l'accomplissement de l'objectif du jeu.