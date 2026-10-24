extends Node3D

const GRAVES_PER_LEVEL := 3

@export_range(1, 10) var level := 1
@export var skeleton_scene: PackedScene
@export var grave_scene: PackedScene
@export var area_size := Vector2(16.0, 12.0)
# Skeletons start emerging at a random time within this many seconds.
@export var max_emerge_delay := 30.0


func _ready() -> void:
	for i in level * GRAVES_PER_LEVEL:
		spawn_skeleton()


func spawn_skeleton() -> void:
	var grave: Node3D = grave_scene.instantiate()
	grave.position = Vector3(
		randf_range(-area_size.x, area_size.x) * 0.5,
		0.0,
		randf_range(-area_size.y, area_size.y) * 0.5
	)
	add_child(grave)

	var skeleton: Node3D = skeleton_scene.instantiate()
	skeleton.grave = grave # Must be set before entering the tree; skeleton reads it in _ready.
	skeleton.buried_time = randf_range(0.0, max_emerge_delay)
	add_child(skeleton)
