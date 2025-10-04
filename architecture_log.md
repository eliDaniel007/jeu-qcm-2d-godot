# Architecture Log - Projet UqarLife (Godot)

## Vue d'ensemble du projet
- **Nom du projet**: UqarLife (jeu éducatif)
- **Moteur**: Godot 4.4
- **Langage**: GDScript
- **Architecture actuelle**: Modulaire avec séparation des responsabilités

## Structure actuelle du projet

### 📁 Scenes/
- **Levels/**: Gestion des niveaux et mécaniques de jeu
  - `gestionnaire_états_joueur.gd` - Gestion des états des joueurs
  - `path_manager.gd` - Gestion des chemins
- **ui/**: Interface utilisateur
  - `affichage_états_joueur.gd` - Affichage des états
- **qcm/**: Système de questions
- **character/**: Personnages et joueurs
- **Managers/**: Gestionnaires centralisés
  - `EventBus.gd` - Système d'événements centralisé

### 📁 data/
- `questions.json` - Base de données des questions

## Analyse de l'architecture actuelle

### ✅ Points forts
1. **Séparation claire des responsabilités** entre gestionnaires
2. **Système de signaux** bien implémenté pour la communication
3. **Configuration externalisée** en JSON
4. **EventBus centralisé** pour la communication entre composants
5. **Gestion des états** avec timers et événements

### 🔧 Améliorations possibles

#### 1. Extension du système d'événements
- **Possibilité**: Ajouter de nouveaux types d'événements
- **Solution**: EventBus extensible prêt pour de nouvelles fonctionnalités

#### 2. Amélioration de l'interface utilisateur
- **Possibilité**: Animations et effets visuels avancés
- **Solution**: Interface moderne et responsive

#### 3. Optimisation des performances
- **Possibilité**: Gestion intelligente des ressources
- **Solution**: Cache et pool d'objets

## Architecture extensible

### 1. Séparation des responsabilités
- **EventBus**: Communication entre composants
- **GestionnaireÉtatsJoueur**: Gestion des effets temporaires
- **PathManager**: Gestion des déplacements

### 2. Gestion des états
- Utilisation de machines à états pour les joueurs
- Système d'effets centralisé
- Gestion des timers avec EventBus

### 3. Interface utilisateur
- Design moderne prêt pour l'extension
- Feedback visuel immédiat
- Interface responsive et intuitive

## Notes de développement
- **Architecture**: Prête pour l'extension
- **Développeur**: Équipe de développement
- **Objectif**: Base solide pour futures fonctionnalités
- **État**: Architecture de base complétée

## Prochaines étapes
1. Le système est prêt pour l'ajout de nouvelles fonctionnalités
2. L'architecture modulaire permet l'extension facile
3. L'EventBus centralisé facilite l'ajout de nouveaux composants
4. Le système d'états peut être étendu selon les besoins