extends Node3D

signal health_changed(health: int)
signal destroyed

const MAX_HEALTH := 16

var health := MAX_HEALTH
var hud_bar: ProgressBar
var hud_label: Label
var game_over_layer: CanvasLayer
var win_layer: CanvasLayer
var seen_skeletons := false


func _ready() -> void:
	add_to_group("crypt")
	_create_hud()
	game_over_layer = _create_overlay("GAME OVER", Color(0.7, 0.0, 0.0, 0.55), "Retry")
	win_layer = _create_overlay("YOU WIN", Color(0.5, 0.1, 0.75, 0.55), "Play again")
	_refresh()


func _process(_delta: float) -> void:
	if health <= 0 or win_layer.visible:
		return
	# Wait until every spawner has produced its skeleton.
	for spawner in get_tree().get_nodes_in_group("spawners"):
		if not spawner.spawned:
			return
	var alive := 0
	for skeleton in get_tree().get_nodes_in_group("skeletons"):
		if not skeleton.is_queued_for_deletion():
			alive += 1
	if alive > 0:
		seen_skeletons = true
	elif seen_skeletons:
		win_layer.visible = true
		get_tree().paused = true


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


func _create_overlay(title_text: String, color: Color, button_text: String) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 20
	layer.visible = false
	# Must keep running while the tree is paused so the button works.
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	var dim := ColorRect.new()
	dim.color = color
	layer.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	center.add_child(box)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	box.add_child(title)

	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(200, 56)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 28)
	button.pressed.connect(_on_retry)
	box.add_child(button)
	return layer


func _on_retry() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
