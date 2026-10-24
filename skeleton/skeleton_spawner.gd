extends Node3D

@export var skeleton_scene: PackedScene
@export var grave_scene: PackedScene
# Skeleton starts emerging at a random time within this many seconds.
@export var max_emerge_delay := 30.0


func _ready() -> void:
	var map := get_world_3d().navigation_map
	# The navigation map is empty until the server has synced at least once.
	while NavigationServer3D.map_get_iteration_id(map) == 0:
		await get_tree().physics_frame
	spawn_skeleton(map)


func spawn_skeleton(map: RID) -> void:
	var grave: Node3D = grave_scene.instantiate()
	add_child(grave)
	# Keep the spawner's x/z, only take the height from the navmesh.
	var ground := NavigationServer3D.map_get_closest_point(map, global_position)
	grave.global_position = Vector3(global_position.x, ground.y, global_position.z)

	var skeleton: Node3D = skeleton_scene.instantiate()
	skeleton.grave = grave # Must be set before entering the tree; skeleton reads it in _ready.
	skeleton.buried_time = randf_range(0.0, max_emerge_delay)
	add_child(skeleton)
