extends Node
## Port de GameState (js/game.js + menuManager.js): sesión de partida.
## Autoload `GameState`.

var player_name: String = "Steve"
var grade: int = 9
var difficulty: String = "normal"  # easy | normal | hard (CONFIG.DIFFICULTY)
var selected_world: String = "overworld"


func new_game() -> void:
	if player_name.strip_edges().is_empty():
		player_name = "Steve"
