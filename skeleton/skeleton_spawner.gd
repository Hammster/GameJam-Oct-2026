extends Node3D

const GRAVES_PER_LEVEL := 3

@export_range(1, 10) var level := 1
@export var skeleton_scene: PackedScene
@export var grave_scene: PackedScene
# Skeletons start emerging at a random time within this many seconds.
@export var max_emerge_delay := 30.0


func _ready() -> void:
	var map := get_world_3d().navigation_map
	# The navigation map is empty until the server has synced at least once.
	while NavigationServer3D.map_get_iteration_id(map) == 0:
		await get_tree().physics_frame
	for i in level * GRAVES_PER_LEVEL:
		spawn_skeleton(map)


func spawn_skeleton(map: RID) -> void:
	var grave: Node3D = grave_scene.instantiate()
	add_child(grave)
	grave.global_position = NavigationServer3D.map_get_random_point(map, 1, true)

	var skeleton: Node3D = skeleton_scene.instantiate()
	skeleton.grave = grave # Must be set before entering the tree; skeleton reads it in _ready.
	skeleton.buried_time = randf_range(0.0, max_emerge_delay)
	add_child(skeleton)
