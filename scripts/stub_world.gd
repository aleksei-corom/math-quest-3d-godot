extends Node3D
## Mundo stub — milestone 1 del port.
## Escena 3D mínima pero real: suelo + cielo del mundo elegido, los 5 bloques
## del bank (mismas posiciones/colores que questionBank.js), cámara en primera
## persona con ratón/WASD, y el quiz real servido por QuestionManager:
## LMB o E sobre un bloque -> pregunta -> respuesta -> bloque minado.

const REACH := 8.0

var _world: String = "overworld"
var _floor_y: float = 0.0
var _blocks: Array = []  # [{index, mesh, body}]
var _mined: Dictionary = {}  # block_index -> true
var _tickets: int = 0

var _body: CharacterBody3D
var _camera: Camera3D
var _yaw: float = 0.0
var _pitch: float = 0.0
var _vel_y: float = 0.0

# Quiz
var _quiz_layer: CanvasLayer
var _quiz_panel: PanelContainer
var _question_label: Label
var _choices_box: VBoxContainer
var _choice_buttons: Array = []
var _hint_label: Label
var _feedback_label: Label
var _continue_btn: Button
var _quiz_open := false
var _answered := false
var _target_block := -1

# HUD
var _status_label: Label


func _ready() -> void:
	_world = GameState.selected_world
	_build_environment()
	_build_blocks()
	_build_player()
	_build_hud()
	_build_quiz()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# ── Construcción de escena ─────────────────────────────────────────────

func _build_environment() -> void:
	var meta: Dictionary = QuestionBank.WORLDS[_world]

	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = meta["sky"]
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = meta["sky"]
	env.fog_density = 0.01
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 1.2
	add_child(sun)

	# Suelo por debajo del bloque más bajo (así el mundo mines, a y=-5, funciona)
	var min_y := INF
	for block in QuestionBank.BLOCKS[_world]:
		min_y = min(min_y, (block["position"] as Vector3).y)
	_floor_y = min_y - 1.0

	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(80, 80)
	var ground := MeshInstance3D.new()
	ground.mesh = ground_mesh
	ground.position = Vector3(0, _floor_y, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = meta["ground"]
	ground.material_override = mat
	add_child(ground)

	var ground_body := StaticBody3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(80, 1, 80)
	var ground_collision := CollisionShape3D.new()
	ground_collision.shape = ground_shape
	ground_body.add_child(ground_collision)
	ground_body.position = Vector3(0, _floor_y - 0.5, 0)
	add_child(ground_body)


func _build_blocks() -> void:
	for i in range(QuestionBank.BLOCKS[_world].size()):
		var block: Dictionary = QuestionBank.BLOCKS[_world][i]

		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE
		mesh.mesh = box
		mesh.position = block["position"]
		var mat := StandardMaterial3D.new()
		mat.albedo_color = block["color"]
		mesh.material_override = mat
		add_child(mesh)

		var body := StaticBody3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3.ONE
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		body.position = block["position"]
		body.set_meta("block_index", i)
		add_child(body)

		_blocks.append({"index": i, "mesh": mesh, "body": body})


func _build_player() -> void:
	_body = CharacterBody3D.new()
	_body.position = Vector3(0, _floor_y + 1.0, 14)

	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	var collision := CollisionShape3D.new()
	collision.shape = shape
	_body.add_child(collision)

	_camera = Camera3D.new()
	_camera.fov = 75.0
	_camera.position = Vector3(0, 0.6, 0)
	_body.add_child(_camera)

	add_child(_body)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var top := VBoxContainer.new()
	top.position = Vector2(16, 12)
	layer.add_child(top)

	var world_meta: Dictionary = QuestionBank.WORLDS[_world]
	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 18)
	_status_label.text = "%s  %s | Grado %d | %s | %s | Bloques minados: 0/%d" % [
		world_meta["icon"], world_meta["label"], GameState.grade,
		GameState.difficulty, GameState.player_name, _blocks.size(),
	]
	top.add_child(_status_label)

	var theme_label := Label.new()
	theme_label.text = "Tema: " + QuestionBank.world_theme(_world)
	theme_label.add_theme_font_size_override("font_size", 14)
	theme_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	top.add_child(theme_label)

	var hint := Label.new()
	hint.position = Vector2(16, 660)
	hint.text = "Clic para mirar | WASD moverse | Espacio saltar | LMB o E: pregunta | Esc: menú"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	layer.add_child(hint)


func _build_quiz() -> void:
	_quiz_layer = CanvasLayer.new()
	_quiz_layer.layer = 2
	add_child(_quiz_layer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_quiz_layer.add_child(center)

	_quiz_panel = PanelContainer.new()
	_quiz_panel.custom_minimum_size = Vector2(620, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0d1230")
	style.border_color = Color("2b3568")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	_quiz_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_quiz_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_quiz_panel.add_child(vbox)

	var title := Label.new()
	title.text = "💡 Sabio del Mundo"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("69f0ae"))
	vbox.add_child(title)

	_question_label = Label.new()
	_question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_question_label.custom_minimum_size = Vector2(570, 0)
	_question_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_question_label)

	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 8)
	vbox.add_child(_choices_box)

	_hint_label = Label.new()
	_hint_label.text = ""
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.add_theme_font_size_override("font_size", 15)
	_hint_label.add_theme_color_override("font_color", Color("ffd54f"))
	_hint_label.visible = false
	vbox.add_child(_hint_label)

	_feedback_label = Label.new()
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_label.add_theme_font_size_override("font_size", 17)
	_feedback_label.visible = false
	vbox.add_child(_feedback_label)

	var buttons_row := HBoxContainer.new()
	buttons_row.add_theme_constant_override("separation", 10)
	vbox.add_child(buttons_row)

	var hint_btn := Button.new()
	hint_btn.text = "Pista"
	hint_btn.pressed.connect(_on_hint_pressed)
	buttons_row.add_child(hint_btn)

	_continue_btn = Button.new()
	_continue_btn.text = "Continuar"
	_continue_btn.visible = false
	_continue_btn.pressed.connect(_on_continue_pressed)
	buttons_row.add_child(_continue_btn)

	_quiz_panel.visible = false


# ── Input ──────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if _quiz_open:
			return
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			_open_quiz()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not _quiz_open:
		_yaw -= event.relative.x * 0.003
		_pitch = clampf(_pitch - event.relative.y * 0.003, -1.4, 1.4)
		_camera.rotation = Vector3(_pitch, _yaw, 0)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E and not _quiz_open:
			_open_quiz()
		elif event.keycode == KEY_ESCAPE:
			if _quiz_open:
				_close_quiz(false)
			elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _physics_process(delta: float) -> void:
	if _quiz_open:
		return

	# Gravedad y movimiento WASD (plano XZ, cámara libre)
	if not _body.is_on_floor():
		_vel_y -= 20.0 * delta
	else:
		_vel_y = 0.0
		if Input.is_key_pressed(KEY_SPACE):
			_vel_y = 7.0

	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		dir.z -= 1.0
	if Input.is_key_pressed(KEY_S):
		dir.z += 1.0
	if Input.is_key_pressed(KEY_A):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		dir.x += 1.0
	if dir != Vector3.ZERO:
		dir = dir.normalized().rotated(Vector3.UP, _yaw)
	var speed := 6.0
	_body.velocity = Vector3(dir.x * speed, _vel_y, dir.z * speed)
	_body.move_and_slide()


# ── Bloques y raycast ──────────────────────────────────────────────────

func _aimed_block_index() -> int:
	var from := _camera.global_position
	var to := from - _camera.global_transform.basis.z * REACH
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return -1
	var collider: Variant = hit.get("collider")
	if collider is Node and (collider as Node).has_meta("block_index"):
		return (collider as Node).get_meta("block_index")
	return -1


func _mine_block(index: int) -> void:
	if _mined.has(index):
		return
	_mined[index] = true
	_tickets += 1
	for entry in _blocks:
		if entry["index"] == index:
			(entry["body"] as Node).queue_free()
			var mesh := entry["mesh"] as MeshInstance3D
			var tw := create_tween()
			tw.tween_property(mesh, "scale", Vector3.ZERO, 0.35)
			tw.tween_callback(func() -> void: mesh.visible = false)
			break
	_update_status()


func _update_status() -> void:
	var world_meta: Dictionary = QuestionBank.WORLDS[_world]
	_status_label.text = "%s  %s | Grado %d | %s | %s | Bloques minados: %d/%d" % [
		world_meta["icon"], world_meta["label"], GameState.grade,
		GameState.difficulty, GameState.player_name, _mined.size(), _blocks.size(),
	]


# ── Quiz ───────────────────────────────────────────────────────────────

func _open_quiz() -> void:
	var index := _aimed_block_index()
	if index < 0 or _mined.has(index):
		return
	var question: Dictionary = QuestionManager.get_question(_world, index, GameState.grade)
	if question.is_empty():
		return

	_target_block = index
	_answered = false
	_question_label.text = str(question.get("q", ""))
	_hint_label.text = ""
	_hint_label.visible = false
	_feedback_label.text = ""
	_feedback_label.visible = false
	_continue_btn.visible = false

	for child in _choices_box.get_children():
		child.queue_free()
	_choice_buttons.clear()
	for option in question.get("options", []):
		var btn := Button.new()
		btn.text = str(option)
		btn.custom_minimum_size = Vector2(0, 40)
		btn.pressed.connect(_on_choice_pressed.bind(btn))
		_choices_box.add_child(btn)
		_choice_buttons.append(btn)

	_quiz_open = true
	_quiz_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_choice_pressed(pressed_btn: Button) -> void:
	if _answered:
		return
	_answered = true
	var correct := str(QuestionManager.current_question.get("a", ""))
	var ok := QuestionManager.check_answer(pressed_btn.text)

	for btn in _choice_buttons:
		btn.disabled = true
		if btn.text == correct:
			btn.add_theme_color_override("font_color", Color("69f0ae"))
		elif btn == pressed_btn:
			btn.add_theme_color_override("font_color", Color("ff5252"))

	_feedback_label.visible = true
	if ok:
		_feedback_label.text = "\u2705 \u00A1CORRECTO!"
		_feedback_label.add_theme_color_override("font_color", Color("69f0ae"))
	else:
		_feedback_label.text = "\u274C Incorrecto. La respuesta es: " + correct
		_feedback_label.add_theme_color_override("font_color", Color("ff5252"))

	_continue_btn.visible = true


func _on_hint_pressed() -> void:
	_hint_label.text = "Pista: " + QuestionManager.get_hint()
	_hint_label.visible = true


func _on_continue_pressed() -> void:
	# Fidelidad con el web: el callback de cierre mina el bloque
	# tanto en respuesta correcta como incorrecta.
	_close_quiz(true)


func _close_quiz(mine: bool) -> void:
	_quiz_open = false
	_quiz_panel.visible = false
	if mine and _target_block >= 0:
		_mine_block(_target_block)
	_target_block = -1
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
