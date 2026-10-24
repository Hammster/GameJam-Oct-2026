extends Control

@export var radar_range := 12.0 # World units from the digger to the radar edge.
@export var radar_size := 180.0

const BG := Color(0, 0, 0, 0.5)
const BORDER := Color(1, 1, 1, 0.6)
const PLAYER_COLOR := Color(0.3, 1, 0.3)
const SKELETON_COLOR := Color(1, 0.3, 0.3)
const DOT_SIZE := 7.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	offset_left = -radar_size - 20.0
	offset_top = -radar_size - 20.0
	offset_right = -20.0
	offset_bottom = -20.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var half := minf(size.x, size.y) / 2.0
	var center := size / 2.0
	var rect := Rect2(center - Vector2(half, half), Vector2(half, half) * 2.0)
	draw_rect(rect, BG)
	draw_rect(rect, BORDER, false, 2.0)

	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return

	for node in get_tree().get_nodes_in_group("skeletons"):
		var skeleton := node as Node3D
		if skeleton == null or not skeleton.visible:
			continue
		var offset := skeleton.global_position - player.global_position
		var p := Vector2(offset.x, offset.z) / radar_range * half
		var limit := half - DOT_SIZE
		p = Vector2(clampf(p.x, -limit, limit), clampf(p.y, -limit, limit))
		draw_rect(Rect2(center + p - Vector2(DOT_SIZE, DOT_SIZE) / 2.0, Vector2(DOT_SIZE, DOT_SIZE)), SKELETON_COLOR)

	draw_rect(Rect2(center - Vector2(DOT_SIZE, DOT_SIZE) / 2.0, Vector2(DOT_SIZE, DOT_SIZE)), PLAYER_COLOR)
