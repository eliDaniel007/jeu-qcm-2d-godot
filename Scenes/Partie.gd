extends Node
## État global de la partie (autoload « Partie »).
## Retient le palier de difficulté choisi avant de lancer le jeu.
## Le QCM ne charge que les questions du palier sélectionné.

var palier: String = "malin"  # "malin" | "expert" | "genie" | "legende"

const INFOS := {
	"malin":   {"nom": "Malin",   "age": "7-9 ans"},
	"expert":  {"nom": "Expert",  "age": "10 ans et +"},
	"genie":   {"nom": "Génie",   "age": "Ados & adultes"},
	"legende": {"nom": "Légende", "age": "Défi extrême"},
}

func definir_palier(id: String) -> void:
	if INFOS.has(id):
		palier = id
