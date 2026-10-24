extends Camera3D

@export var target: Node3D
# Fraction of the target's horizontal movement the camera copies (0 = static, 1 = locked on).
@export_range(0.0, 1.0) var follow_amount := 0.35
@export var smoothing := 3.0

var origin: Vector3
var target_origin: Vector3


func _ready() -> void:
	origin = global_position
	target_origin = target.global_position


func _process(delta: float) -> void:
	var offset := target.global_position - target_origin
	offset.y = 0.0 # The digger drops onto the floor at start; ignore height.
	var goal := origin + offset * follow_amount
	global_position = global_position.lerp(goal, 1.0 - exp(-smoothing * delta))
