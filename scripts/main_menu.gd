extends Control
## Menú principal — port de menuManager.js (selección de mundo/grado/
## dificultad/nombre) con la misma información de QuestionBank.WORLDS.

var _world_group := ButtonGroup.new()
var _name_edit: LineEdit
var _grade_option: OptionButton
var _difficulty_option: OptionButton


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("070b1a")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.custom_minimum_size = Vector2(760, 0)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "MATH QUEST 3D"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color("4caf50"))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Puerto a Godot 4 - Milestone 1: datos + menú + mundo stub"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("8a93b5"))
	vbox.add_child(subtitle)

	var world_label := Label.new()
	world_label.text = "SELECCIONA TU MUNDO"
	world_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world_label.add_theme_font_size_override("font_size", 20)
	world_label.add_theme_color_override("font_color", Color("c3cae8"))
	vbox.add_child(world_label)

	var worlds_row := HBoxContainer.new()
	worlds_row.alignment = BoxContainer.ALIGNMENT_CENTER
	worlds_row.add_theme_constant_override("separation", 12)
	vbox.add_child(worlds_row)

	for world_id in QuestionBank.WORLD_ORDER:
		var meta: Dictionary = QuestionBank.WORLDS[world_id]
		var btn := Button.new()
		btn.toggle_mode = true
		btn.button_group = _world_group
		btn.custom_minimum_size = Vector2(176, 112)
		btn.text = str(meta["icon"]) + "\n" + str(meta["label"]) + "\n" + str(meta["theme"])
		btn.button_pressed = world_id == GameState.selected_world
		btn.pressed.connect(_on_world_pressed.bind(world_id))
		worlds_row.add_child(btn)

	vbox.add_child(HSeparator.new())

	var grade_row := HBoxContainer.new()
	grade_row.alignment = BoxContainer.ALIGNMENT_CENTER
	grade_row.add_theme_constant_override("separation", 10)
	vbox.add_child(grade_row)

	var grade_label := Label.new()
	grade_label.text = "Grado escolar:"
	grade_row.add_child(grade_label)

	_grade_option = OptionButton.new()
	for g in range(5, 12):
		_grade_option.add_item("%d\u00B0" % g)
	_grade_option.select(clampi(GameState.grade - 5, 0, 6))
	_grade_option.item_selected.connect(_on_grade_selected)
	grade_row.add_child(_grade_option)

	var diff_label := Label.new()
	diff_label.text = "   Dificultad:"
	grade_row.add_child(diff_label)

	_difficulty_option = OptionButton.new()
	_difficulty_option.add_item("F\u00E1cil")
	_difficulty_option.add_item("Normal")
	_difficulty_option.add_item("Dif\u00EDcil")
	_difficulty_option.select(_difficulty_index(GameState.difficulty))
	_difficulty_option.item_selected.connect(_on_difficulty_selected)
	grade_row.add_child(_difficulty_option)

	var name_row := HBoxContainer.new()
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_row.add_theme_constant_override("separation", 10)
	vbox.add_child(name_row)

	var name_label := Label.new()
	name_label.text = "Nombre del explorador:"
	name_row.add_child(name_label)

	_name_edit = LineEdit.new()
	_name_edit.text = GameState.player_name
	_name_edit.max_length = 15
	_name_edit.custom_minimum_size = Vector2(280, 0)
	_name_edit.text_changed.connect(func(t: String) -> void: GameState.player_name = t)
	name_row.add_child(_name_edit)

	var start_btn := Button.new()
	start_btn.text = "\u2694\ufe0f  ENTRAR AL MUNDO 3D"
	start_btn.custom_minimum_size = Vector2(0, 64)
	start_btn.add_theme_font_size_override("font_size", 26)
	start_btn.add_theme_color_override("font_color", Color("69f0ae"))
	start_btn.pressed.connect(_on_start_pressed)
	vbox.add_child(start_btn)

	var exit_btn := Button.new()
	exit_btn.text = "Salir"
	exit_btn.pressed.connect(func() -> void: get_tree().quit())
	vbox.add_child(exit_btn)


func _difficulty_index(difficulty: String) -> int:
	match difficulty:
		"easy":
			return 0
		"hard":
			return 2
	return 1


func _on_world_pressed(world_id: String) -> void:
	GameState.selected_world = world_id
	GameState.new_game()


func _on_grade_selected(index: int) -> void:
	GameState.grade = index + 5


func _on_difficulty_selected(index: int) -> void:
	GameState.difficulty = ["easy", "normal", "hard"][index]


func _on_start_pressed() -> void:
	GameState.new_game()
	get_tree().change_scene_to_file("res://scenes/stub_world.tscn")
