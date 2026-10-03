extends SceneTree
## Verificación headless del milestone 1:
##   godot --headless --path . -s res://tests/smoke.gd
## Comprueba: datos del bank, generadores (4 mundos × grados 5-11), semántica
## del manager, construcción del menú, el click real de inicio (transición
## menú→mundo con change_scene_to_file) y el mundo stub (5 bloques, HUD, minado).
## El código de salida es el número de fallos (0 = verde).

var failures := 0
var _menu: Variant


func _fail(msg: String) -> void:
	failures += 1
	print("[smoke] FALLO: " + msg)


func _ok(msg: String) -> void:
	print("[smoke] ok: " + msg)


func _initialize() -> void:
	print("[smoke] inicio")
	_check_bank_data()
	_check_generators()
	_check_manager()
	# Las escenas necesitan el árbol activo para disparar _ready:
	# se comprueban a partir del primer frame, no dentro de _initialize.
	_ensure_autoloads()
	create_timer(0.1).timeout.connect(_check_menu)


func _check_bank_data() -> void:
	if QuestionBank.WORLD_ORDER.size() != 4:
		_fail("WORLD_ORDER debería tener 4 mundos")
	for world in QuestionBank.WORLD_ORDER:
		if not QuestionBank.WORLDS.has(world):
			_fail("WORLDS falta metadata de " + world)
		var blocks: Array = QuestionBank.BLOCKS.get(world, [])
		if blocks.size() != 5:
			_fail("%s debería tener 5 bloques, tiene %d" % [world, blocks.size()])
	_ok("bank: 4 mundos con metadata y 5 bloques cada uno")


func _check_generators() -> void:
	var gen := QuestionGenerators.new()
	for world in QuestionBank.WORLD_ORDER:
		for grade in range(5, 12):
			var pool: Array = gen.for_world(world, grade)
			if pool.size() != QuestionGenerators.QUESTIONS_PER_POOL:
				_fail("%s grado %d: pool=%d (esperado 6)" % [world, grade, pool.size()])
				continue
			for q in pool:
				var qd := q as Dictionary
				if str(qd.get("q", "")).is_empty():
					_fail("%s grado %d: pregunta vacía" % [world, grade])
				if str(qd.get("a", "")).is_empty():
					_fail("%s grado %d: respuesta vacía" % [world, grade])
				if qd.get("type", "") != "choice":
					_fail("%s grado %d: type!=choice" % [world, grade])
				var options: Array = qd.get("options", [])
				if options.size() != 4:
					_fail("%s grado %d: %d opciones (esperado 4)" % [world, grade, options.size()])
				elif not options.has(str(qd["a"])):
					_fail("%s grado %d: las opciones no incluyen la correcta '%s' en %s" % [world, grade, qd["a"], options])
	_ok("generadores: 4 mundos × grados 5-11 con 6 preguntas y opciones válidas")


func _check_manager() -> void:
	var qm = load("res://autoload/question_manager.gd").new()
	for i in range(6):
		var q: Dictionary = qm.get_question("overworld", 0, 9)
		if q.is_empty():
			_fail("get_question devolvió vacío en llamada %d" % i)
			return
	if not qm.check_answer(str(qm.current_question["a"])):
		_fail("check_answer debería aceptar la respuesta correcta")
	if not qm.check_answer("  " + str(qm.current_question["a"]) + "  "):
		_fail("check_answer debería ignorar mayúsculas/espacios")
	if qm.check_answer("respuesta imposible xyz"):
		_fail("check_answer debería rechazar una respuesta errónea")
	if str(qm.get_hint()).is_empty():
		_fail("get_hint no debería ser vacío")
	if get_root().get_node_or_null("QuestionManager") == null:
		_fail("autoload QuestionManager no instanciado")
	_ok("manager: pools, check_answer, hint y autoload")


func _ensure_autoloads() -> void:
	# En modo -s algunos autoloads pueden faltar: se recrean a mano.
	for entry in [["GameState", "res://autoload/game_state.gd"], ["QuestionManager", "res://autoload/question_manager.gd"]]:
		if get_root().get_node_or_null(entry[0]) == null:
			var node: Node = load(entry[1]).new()
			node.name = entry[0]
			get_root().add_child(node)


func _check_menu() -> void:
	var menu_script: GDScript = load("res://scripts/main_menu.gd")
	if menu_script == null:
		_fail("no carga main_menu.gd")
		_report()
		return
	_menu = load("res://scenes/main_menu.tscn").instantiate()
	get_root().add_child(_menu)
	if not _menu.is_node_ready():
		_fail("main_menu no recibió _ready")
		_report()
		return
	if _menu._grade_option == null or _menu._name_edit == null:
		_fail("main_menu._ready no completó la construcción de UI")
		_report()
		return
	_ok("menú: UI construida (worlds/grado/dificultad/nombre)")

	# Click real del botón de inicio: ejercita change_scene_to_file
	_menu._on_start_pressed()
	create_timer(0.1).timeout.connect(_check_transition)


func _check_transition() -> void:
	var stub: Variant = get_root().get_node_or_null("StubWorld")
	if stub == null:
		_fail("transición menú→mundo: no existe el nodo StubWorld")
		_report()
		return
	if stub._camera == null:
		_fail("stub_world: cámara nula (build incompleto)")
	elif stub._blocks.size() != 5:
		_fail("stub_world: %d bloques (esperado 5)" % stub._blocks.size())
	elif stub._status_label == null:
		_fail("stub_world: HUD no construido (¿autoload GameState nulo?)")
	else:
		stub._mine_block(0)
		if not stub._mined.has(0):
			_fail("stub_world: _mine_block(0) no marcó el bloque")
		else:
			_ok("transición y mundo stub: escena, 5 bloques, HUD y minado")
	# Liberación inmediata para evitar ruido de teardown del renderer dummy
	stub.free()
	_menu.free()
	_report()


func _report() -> void:
	print("[smoke] fin — fallos=%d" % failures)
	quit(mini(failures, 200))
