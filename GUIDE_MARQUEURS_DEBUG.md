# 🔍 Guide de Debug des Marqueurs Visuels

## 🚨 Problème : Marqueurs invisibles

Si vous ne voyez pas les marqueurs, suivez ces étapes de debug :

## 📋 Étapes de vérification

### **1. Vérifier que le gestionnaire est dans la scène**
- Ouvrir `Scenes/Levels/level.tscn` dans l'éditeur
- Vérifier qu'il y a bien un nœud `GestionnairePiegesBonus` dans la scène
- S'il n'y est pas, l'ajouter : **Scène > Instancier > gestionnaire_pieges_bonus_simple.tscn**

### **2. Lancer le jeu et vérifier les messages console**
Quand vous lancez le jeu, vous devriez voir dans la console :
```
=== INITIALISATION GESTIONNAIRE PIÈGES/BONUS ===
✅ Path manager trouvé
Création marqueur de test immédiat...
✅ Marqueur de test créé à (800,300) en magenta
=== FIN INITIALISATION ===
```

### **3. Chercher le marqueur de test magenta**
- Un **carré magenta** devrait apparaître à la position (800, 300)
- Si vous le voyez, le système fonctionne
- Si vous ne le voyez pas, il y a un problème d'affichage

### **4. Vérifier la position de la caméra**
- Les marqueurs peuvent être hors de vue
- Positions des pièges/bonus configurés :
  - **Pièges** : (1825, 982), (2270, 780), (1500, 551)
  - **Bonus** : (479, 982), (671, 982), (2204, 780), (1889, 982)

## 🛠️ Solutions possibles

### **Solution 1 : Marqueurs de test simples**
Attacher le script `debug_marqueurs.gd` à la scène Level :
1. Sélectionner le nœud `Level` dans l'éditeur
2. Attacher le script `debug_marqueurs.gd`
3. Lancer le jeu
4. Vous devriez voir des marqueurs de test à (500,500) et (600,500)

### **Solution 2 : Vérification manuelle**
Contrôles de debug :
- **Flèche BAS** : Vérifier l'état des marqueurs
- **Flèche HAUT** : Recréer les marqueurs

### **Solution 3 : Ajuster les positions**
Si les marqueurs sont créés mais hors de vue, modifiez les positions dans le script :
```gdscript
# Dans gestionnaire_pieges_bonus_simple.gd, ligne 4-18
var pieges = [
    {"x": 500, "y": 400, "nom": "Piège Test 1", "recul": 100},
    {"x": 700, "y": 400, "nom": "Piège Test 2", "recul": 150},
]

var bonus = [
    {"x": 600, "y": 400, "nom": "Bonus Test 1", "avance": 100},
    {"x": 800, "y": 400, "nom": "Bonus Test 2", "avance": 150},
]
```

## 🎯 Test rapide

Pour un test rapide, modifiez temporairement la position d'un piège :

1. Ouvrir `gestionnaire_pieges_bonus_simple.gd`
2. Ligne 4, changer `{"x": 1825, "y": 982, ...}` en `{"x": 500, "y": 400, ...}`
3. Lancer le jeu
4. Vous devriez voir un carré rouge à (500, 400)

## 📊 Messages de debug attendus

Console complète attendue :
```
=== INITIALISATION GESTIONNAIRE PIÈGES/BONUS ===
✅ Path manager trouvé
Création marqueur de test immédiat...
✅ Marqueur de test créé à (800,300) en magenta
=== FIN INITIALISATION ===
=== CRÉATION DES MARQUEURS VISUELS ===
Nombre de pièges configurés: 3
Nombre de bonus configurés: 4
Création marqueur piège 1: Piège 1 à (1825, 982)
Création marqueur piège à position: (1825, 982)
Marqueur piège créé avec 3 enfants
Marqueur piège ajouté à la scène
...
=== MARQUEURS CRÉÉS: 3 pièges, 4 bonus ===
```

## 🚨 Si rien ne fonctionne

1. **Redémarrer Godot** - Parfois les scripts ne se rechargent pas
2. **Vérifier la scène active** - S'assurer de lancer `level.tscn`
3. **Vérifier les erreurs** - Console d'erreurs de Godot
4. **Position de la caméra** - Se déplacer dans la scène

---

*Guide créé pour débugger les marqueurs visuels invisibles*
