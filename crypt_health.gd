extends Node3D

signal health_changed(health: int)
signal destroyed

const MAX_HEALTH := 16

var health := MAX_HEALTH
var hud_bar: ProgressBar
var hud_label: Label
var game_over_layer: CanvasLayer


func _ready() -> void:
	add_to_group("crypt")
	_create_hud()
	_create_game_over()
	_refresh()


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(health - amount, 0)
	_refresh()
	health_changed.emit(health)
	if health == 0:
		destroyed.emit()
		game_over_layer.visible = true
		get_tree().paused = true


func _refresh() -> void:
	hud_bar.value = health
	hud_label.text = "Crypt  %d / %d" % [health, MAX_HEALTH]


func _create_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)

	hud_bar = ProgressBar.new()
	hud_bar.max_value = MAX_HEALTH
	hud_bar.show_percentage = false
	hud_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.2, 0.8, 0.25)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0, 0, 0, 0.6)
	hud_bar.add_theme_stylebox_override("fill", fill)
	hud_bar.add_theme_stylebox_override("background", back)
	layer.add_child(hud_bar)
	hud_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hud_bar.offset_left = -300.0
	hud_bar.offset_right = 300.0
	hud_bar.offset_top = 16.0
	hud_bar.offset_bottom = 52.0

	hud_label = Label.new()
	hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_bar.add_child(hud_label)
	hud_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _create_game_over() -> void:
	game_over_layer = CanvasLayer.new()
	game_over_layer.layer = 20
	game_over_layer.visible = false
	# Must keep running while the tree is paused so the button works.
	game_over_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(game_over_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.7, 0.0, 0.0, 0.55)
	game_over_layer.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	game_over_layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	center.add_child(box)

	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	box.add_child(title)

	var retry := Button.new()
	retry.text = "Retry"
	retry.custom_minimum_size = Vector2(200, 56)
	retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry.add_theme_font_size_override("font_size", 28)
	retry.pressed.connect(_on_retry)
	box.add_child(retry)


func _on_retry() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
