extends Node
## État global de la partie (autoload « Partie »).
## Retient le palier de difficulté choisi avant de lancer le jeu.
## Le QCM ne charge que les questions du palier sélectionné.

var palier: String = "decouverte"  # "decouverte" | "malin" | "expert"

const INFOS := {
	"decouverte": {"nom": "Découverte", "emoji": "🌱", "age": "4-6 ans"},
	"malin":      {"nom": "Malin",      "emoji": "⭐", "age": "7-9 ans"},
	"expert":     {"nom": "Expert",     "emoji": "🧠", "age": "10 ans et +"},
}

func definir_palier(id: String) -> void:
	if INFOS.has(id):
		palier = id
