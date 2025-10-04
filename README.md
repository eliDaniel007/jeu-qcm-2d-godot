# 🎮 Jeu 2D QCM avec Pièges et Bonus

[![Godot](https://img.shields.io/badge/Godot-4.4-478CBF?style=flat-square&logo=godotengine)](https://godotengine.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![Language](https://img.shields.io/badge/Language-GDScript-blue.svg?style=flat-square)](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey?style=flat-square)](https://godotengine.org/)

Un jeu 2D de type Mario développé avec Godot 4.4, où le joueur progresse en répondant correctement aux questions de culture générale, tout en évitant les pièges et en collectant les bonus !

![Game Preview](https://via.placeholder.com/800x400/478CBF/FFFFFF?text=Jeu+QCM+2D+Godot)

## 🎯 Concept du Jeu

- **Mécanique principale** : Répondre correctement aux QCM pour avancer
- **Éléments de gameplay** : Pièges qui font reculer, bonus qui font avancer
- **Style** : Jeu de plateforme 2D avec déplacement par cases
- **Objectif** : Atteindre la fin du niveau en évitant les pièges et en collectant les bonus

## 🚀 Fonctionnalités

### ✅ Système de QCM
- **117 questions** de culture générale variées
- Questions sur l'histoire, la géographie, les sciences, l'art, la littérature
- Interface utilisateur intuitive pour les réponses

### 🎮 Mécaniques de Jeu
- **Déplacement par cases** : Le joueur avance case par case selon ses bonnes réponses
- **Système de pièges** : Zones qui font reculer le joueur
- **Système de bonus** : Zones qui font avancer le joueur
- **Gestion des étages** : Alternance gauche/droite selon l'étage

### 🎨 Interface et Graphismes
- **Sprites animés** pour le personnage principal
- **Marqueurs visuels** pour les pièges (rouges) et bonus (verts)
- **Animations** pour les effets de pièges et bonus
- **Interface utilisateur** moderne et responsive

### 🏗️ Architecture Technique
- **Godot 4.4** avec GDScript
- **Architecture modulaire** : gestionnaires séparés pour chaque système
- **Système d'événements** avec EventBus
- **Gestion d'état** du joueur et des combos

## 📁 Structure du Projet

```
├── Scenes/
│   ├── character/          # Personnage principal et animations
│   ├── Levels/             # Niveaux et gestionnaires de gameplay
│   ├── qcm/                # Système de questions à choix multiples
│   ├── ui/                 # Interfaces utilisateur
│   └── Managers/           # Gestionnaires de système
├── data/
│   └── questions.json      # Base de données des questions
└── Documentation/          # Documentation du projet
```

## 🎮 Comment Jouer

1. **Lancement** : Ouvrir le projet dans Godot 4.4+
2. **Déplacement** : Le joueur se déplace automatiquement selon les réponses QCM
3. **Éviter les pièges** : Les zones rouges font reculer
4. **Collecter les bonus** : Les zones vertes font avancer
5. **Objectif** : Atteindre la fin du niveau

## 🛠️ Installation et Configuration

### Prérequis
- **Godot Engine** 4.4 ou supérieur
- **Git** (pour cloner le repository)

### Installation
```bash
# Cloner le repository
git clone https://github.com/eliDaniel007/jeu-qcm-2d-godot.git
cd jeu-qcm-2d-godot

# Ouvrir avec Godot
# Ouvrir Godot → Importer → Sélectionner le dossier du projet
```

### Configuration
1. Ouvrir `project.godot` avec Godot
2. Vérifier que la scène principale est configurée
3. Lancer le jeu avec F5

## 📊 Système de Questions

Le jeu contient **117 questions** réparties dans différentes catégories :

- 🌍 **Géographie** : Capitales, pays, monuments
- 🎨 **Art & Culture** : Peintres, œuvres, littérature
- 🔬 **Sciences** : Éléments chimiques, découvertes, inventions
- 📚 **Histoire** : Dates importantes, personnages historiques
- 🌍 **Nature** : Animaux, géographie physique, environnement

### Exemple de Question
```json
{
  "question": "Quelle est la capitale de la France ?",
  "reponses": ["Londres", "Paris", "Berlin", "Madrid"],
  "bonne_reponse": 1
}
```

## 🎯 Système de Pièges et Bonus

### Configuration Actuelle

**Pièges** (zones rouges - font reculer) :
- Piège 1 : Position (1825, 982) - Recul de 100 pixels
- Piège 2 : Position (2270, 780) - Recul de 150 pixels  
- Piège 3 : Position (1500, 551) - Recul de 120 pixels

**Bonus** (zones vertes - font avancer) :
- Bonus 1 : Position (479, 982) - Avance de 100 pixels
- Bonus 2 : Position (671, 982) - Avance de 150 pixels
- Bonus 3 : Position (2204, 780) - Avance de 120 pixels
- Bonus 4 : Position (1889, 982) - Avance de 200 pixels

### Logique de Direction
- **Étages pairs** (0, 2, 4...) : Déplacement vers la droite
- **Étages impairs** (1, 3, 5...) : Déplacement vers la gauche

## 🔧 Développement

### Structure du Code

**Gestionnaires principaux :**
- `GestionnairePiegesBonusSimple` : Gestion des pièges et bonus
- `PathManager` : Gestion du déplacement du joueur
- `EventBus` : Communication entre les systèmes
- `ComboManager` : Gestion des combos et scores

**Système de QCM :**
- `QCM.gd` : Logique des questions
- `QCM_Multiplayer.gd` : Support multijoueur
- Interface utilisateur responsive

### Tests et Debug
- Script de test intégré : `test_pieges_bonus_simple.gd`
- Marqueurs visuels pour debug
- Contrôles de test (ESPACE, TAB, etc.)

## 📈 Améliorations Futures

- [ ] **Multijoueur** : Support complet du mode multijoueur
- [ ] **Niveaux additionnels** : Plus de niveaux avec différentes difficultés
- [ ] **Système de score** : Points basés sur les bonnes réponses et bonus
- [ ] **Effets sonores** : Audio pour les pièges, bonus et QCM
- [ ] **Animations avancées** : Plus d'effets visuels
- [ ] **Éditeur de niveaux** : Outil pour créer de nouveaux niveaux
- [ ] **Base de données étendue** : Plus de questions dans différentes catégories

## 🤝 Contribution

Les contributions sont les bienvenues ! Voici comment contribuer :

1. **Fork** le repository
2. **Créer** une branche pour votre fonctionnalité (`git checkout -b feature/nouvelle-fonctionnalite`)
3. **Commit** vos changements (`git commit -am 'Ajouter nouvelle fonctionnalité'`)
4. **Push** vers la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. **Créer** une Pull Request

### Types de Contributions
- 🐛 **Bug fixes** : Correction de bugs
- ✨ **Nouvelles fonctionnalités** : Ajout de gameplay
- 📚 **Documentation** : Amélioration de la documentation
- 🎨 **Assets** : Nouveaux sprites, sons, animations
- 🧪 **Tests** : Amélioration des tests

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 👨‍💻 Auteur

Développé avec ❤️ par **Elida Nielsen** pour UqarLife

[![GitHub](https://img.shields.io/badge/GitHub-eliDaniel007-blue?style=flat-square&logo=github)](https://github.com/eliDaniel007)

## 🙏 Remerciements

- **Godot Engine** pour le moteur de jeu
- **Communauté Godot** pour les ressources et l'aide
- **Contributeurs** qui ont aidé au développement

---

**Amusez-vous bien et bon jeu ! 🎮**

