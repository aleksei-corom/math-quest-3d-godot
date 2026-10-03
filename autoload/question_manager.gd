extends Node
## Port de js/questions/questionManager.js — autoload `QuestionManager`.
## Misma semántica que el original: cada llamada genera un pool fresco de 6
## preguntas para el mundo/grado, y los índices usados se recuerdan por
## (mundo, bloque, grado) hasta agotarse; luego se reinician.

var _gen := QuestionGenerators.new()
var _used: Dictionary = {}  # "world_block_grade" -> Array[int]
var current_question: Dictionary = {}


## Devuelve UNA pregunta (con type/options/hint) — equivalente a getQuestion().
func get_question(world: String, block_index: int, grade: int) -> Dictionary:
	var pool: Array = _gen.for_world(world, grade)
	if pool.is_empty():
		return {}
	var key := "%s_%d_%d" % [world, block_index, grade]
	if not _used.has(key):
		_used[key] = []
	var used: Array = _used[key]

	var available: Array = []
	for i in range(pool.size()):
		if not used.has(i):
			available.append(i)

	var idx: int
	if available.is_empty():
		# Si se agotaron todas, reiniciar (igual que el original)
		_used[key] = []
		idx = randi() % pool.size()
	else:
		idx = available[randi() % available.size()]
		used.append(idx)

	current_question = pool[idx]
	return current_question


## Verificación flexible (case-insensitive + sin espacios), como checkAnswer().
func check_answer(user_answer: String) -> bool:
	if current_question.is_empty():
		return false
	var correct := _squash(str(current_question.get("a", "")))
	var user := _squash(user_answer)
	return correct == user


func _squash(s: String) -> String:
	return s.to_lower().strip_edges().replace(" ", "").replace("\t", "").replace("\n", "")


func get_hint() -> String:
	if current_question.is_empty():
		return ""
	return str(current_question.get("hint", ""))


func get_world_theme(world: String) -> String:
	return QuestionBank.world_theme(world)


func reset_used() -> void:
	_used = {}
