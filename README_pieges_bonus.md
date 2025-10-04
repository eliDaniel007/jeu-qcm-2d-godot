# 🎯 Système de Pièges et Bonus Simple

## 📋 Vue d'ensemble

Système simple et efficace basé sur la même logique que les portes :
- **Détection par coordonnées** : Vérification quand le joueur termine son déplacement
- **Actions instantanées** : Recul pour les pièges, avance pour les bonus
- **Intégration transparente** : Utilise le système existant du `path_manager`

## 🔧 Architecture

### **Fichiers principaux :**
- `gestionnaire_pieges_bonus_simple.gd` - Gestionnaire principal
- `gestionnaire_pieges_bonus_simple.tscn` - Scène du gestionnaire
- `test_pieges_bonus_simple.gd` - Script de test

### **Intégration :**
- Ajouté à `level.tscn` comme nœud enfant
- Se connecte automatiquement au signal `deplacement_termine` du `path_manager`

## 🎮 Configuration actuelle

### **Pièges (font reculer) :**
- **Piège 1** : Position (1825, 982) - Recul de 100 pixels
- **Piège 2** : Position (2270, 780) - Recul de 150 pixels  
- **Piège 3** : Position (1500, 551) - Recul de 120 pixels

### **Bonus (font avancer) :**
- **Bonus 1** : Position (479, 982) - Avance de 100 pixels
- **Bonus 2** : Position (671, 982) - Avance de 150 pixels
- **Bonus 3** : Position (2204, 780) - Avance de 120 pixels
- **Bonus 4** : Position (1889, 982) - Avance de 200 pixels

## ⚙️ Fonctionnement

### **Logique de détection :**
1. Le joueur termine son déplacement (QCM fini)
2. Le `path_manager` émet le signal `deplacement_termine`
3. Le gestionnaire vérifie si le joueur est sur un piège ou bonus
4. Si détecté, applique l'effet instantanément

### **Logique de direction :**
- **Étages pairs** (0, 2, 4...) : Déplacement vers la droite
  - Pièges : recul vers la gauche
  - Bonus : avance vers la droite
- **Étages impairs** (1, 3, 5...) : Déplacement vers la gauche
  - Pièges : recul vers la droite  
  - Bonus : avance vers la gauche

### **Tolérance de détection :**
- **25 pixels** autour de chaque position définie
- Modifiable via `modifier_tolerance(nouvelle_valeur)`

## 🎨 Effets visuels

### **Marqueurs visuels sur la carte :**
- **Pièges** : Cercles rouges avec animation de pulsation
- **Bonus** : Cercles verts avec animation de rotation
- **Labels** : Noms affichés au-dessus de chaque marqueur
- **Visibilité** : Peuvent être masqués/affichés dynamiquement

### **Animations de piège :**
- Tremblement du joueur
- Couleur rouge temporaire

### **Animations de bonus :**
- Pulsation (agrandissement/rétrécissement)
- Couleur verte temporaire

## 🔨 API disponible

### **Gestion des pièges :**
```gdscript
# Ajouter un piège
ajouter_piege(x: float, y: float, nom: String, recul: int)

# Supprimer un piège
supprimer_piege(nom: String)

# Obtenir la liste des pièges
obtenir_pieges() -> Array
```

### **Gestion des bonus :**
```gdscript
# Ajouter un bonus  
ajouter_bonus(x: float, y: float, nom: String, avance: int)

# Supprimer un bonus
supprimer_bonus(nom: String)

# Obtenir la liste des bonus
obtenir_bonus() -> Array
```

### **Configuration :**
```gdscript
# Modifier la tolérance de détection
modifier_tolerance(nouvelle_tolerance: float)
```

### **Gestion des marqueurs visuels :**
```gdscript
# Masquer tous les marqueurs
masquer_marqueurs()

# Afficher tous les marqueurs
afficher_marqueurs()

# Basculer la visibilité des marqueurs
basculer_marqueurs()
```

## 🧪 Tests

### **Script de test :**
- Attacher `test_pieges_bonus_simple.gd` à la scène principale

### **Contrôles de test :**
- **ESPACE** : Relancer les tests automatiques
- **ÉCHAP** : Vérifier la position actuelle du joueur
- **TAB** : Basculer la visibilité des marqueurs visuels
- **HOME** : Ajouter des pièges/bonus de test
- **END** : Supprimer les éléments de test

### **Tests automatiques :**
1. Vérification de l'initialisation
2. Test de détection par coordonnées
3. Simulation de déplacements

## 🚀 Utilisation

### **1. Configuration de base :**
Le système est prêt à l'emploi avec les positions par défaut.

### **2. Ajout de nouveaux pièges/bonus :**
```gdscript
# Dans votre script
var gestionnaire = get_node("GestionnairePiegesBonus")
gestionnaire.ajouter_piege(1200, 600, "Nouveau Piège", 80)
gestionnaire.ajouter_bonus(1400, 600, "Nouveau Bonus", 120)
```

### **3. Modification en cours de jeu :**
```gdscript
# Supprimer un élément
gestionnaire.supprimer_piege("Piège 1")

# Changer la tolérance
gestionnaire.modifier_tolerance(30.0)
```

## 📊 Avantages du système

- ✅ **Simple** : Logique claire basée sur les coordonnées
- ✅ **Performant** : Vérification uniquement en fin de déplacement  
- ✅ **Extensible** : Facile d'ajouter/modifier des éléments
- ✅ **Intégré** : Utilise l'architecture existante
- ✅ **Visuel** : Animations pour le feedback utilisateur

## 🔮 Extensions possibles

- Pièges/bonus temporaires qui disparaissent après utilisation
- Effets de durée (ralentissement sur plusieurs tours)
- Pièges/bonus aléatoires qui apparaissent dynamiquement
- Sons et particules pour les effets visuels
- Système de points/score basé sur les pièges/bonus

---

*Système créé pour UqarLife - Simple, efficace, extensible !*
