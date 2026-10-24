extends CharacterBody3D

const SPEED := 1.0
const MIN_BURIED := 3.0
const MAX_BURIED := 6.0
const EMERGING := 5.0
const HEIGHT := 0.74
const ALIGNMENT := 0.99
const MAX_HEALTH := 3
const ATTACK_COOLDOWN := 2.0
const BAR_WIDTH := 0.8
const BAR_HEIGHT := 0.09
const BAR_Y := 1.3
const TARGET_NODE := "CollisionShapeSkelletonTarget"

@export var grave: Node3D
# Overrides the random buried time when >= 0.
var buried_time := -1.0
var health := MAX_HEALTH
var arrived := false
var crypt_target: Node3D
var bar: Node3D
var bar_fill: MeshInstance3D

@onready var anim: AnimationPlayer = $"character-skeleton/AnimationPlayer"
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

enum State {
	BURIED,
	EMERGING,
	ROAMING,
	DEATH,
}

var state: State
var timer := 0.0
var direction := Vector3(0.0, 0.0, -1.0)

func _ready():
	add_to_group("skeletons")
	crypt_target = get_tree().current_scene.find_child(TARGET_NODE, true, false) as Node3D
	if crypt_target == null:
		push_warning("%s not found, skeletons will roam randomly" % TARGET_NODE)
	_create_health_bar()
	set_state(State.BURIED)
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))

func set_state(new_state: State):
	state = new_state
	on_enter()

func hit():
	match state:
		State.EMERGING:
			# Still in the grave: one hit kills.
			health = 0
			_update_health_bar()
			set_state(State.DEATH)
		State.ROAMING:
			health -= 1
			_update_health_bar()
			if health <= 0:
				set_state(State.DEATH)

func _create_health_bar() -> void:
	bar = Node3D.new()
	bar.top_level = true
	bar.visible = false
	add_child(bar)
	bar.add_child(_make_bar_quad(Color(0, 0, 0, 0.7), 0.0))
	bar_fill = _make_bar_quad(Color(0.9, 0.15, 0.15), 0.001)
	bar.add_child(bar_fill)

func _make_bar_quad(color: Color, z: float) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.albedo_color = color
	mat.render_priority = 1 if z > 0.0 else 0
	quad.material = mat
	var mesh := MeshInstance3D.new()
	mesh.mesh = quad
	mesh.position.z = z
	return mesh

func _update_health_bar() -> void:
	var ratio := clampf(float(health) / MAX_HEALTH, 0.0, 1.0)
	bar_fill.scale.x = maxf(ratio, 0.001)
	# Shrink towards the left edge.
	bar_fill.position.x = -(1.0 - ratio) * BAR_WIDTH / 2.0

func on_enter():
	match state:
		State.BURIED:
			visible = false
			bar.visible = false
			global_position = grave.global_position - Vector3.UP * HEIGHT
			timer = buried_time if buried_time >= 0.0 else randf_range(MIN_BURIED, MAX_BURIED)
		State.EMERGING:
			visible = true
			bar.visible = true
			global_position = grave.global_position - Vector3.UP * HEIGHT
			timer = EMERGING
			anim.play("pick-up")
		State.ROAMING:
			visible = true
			anim.play("walk")
			choose_target()
			pass
		State.DEATH:
			bar.visible = false
			$CollisionShape3D.set_deferred("disabled", true)
			anim.get_animation("die").loop_mode = Animation.LOOP_NONE
			anim.play("die")
			await anim.animation_finished
			queue_free()

func _process(delta: float):
	timer -= delta
	_update_bar_transform()

	if direction.length_squared() > 1e-3:
		look_at(global_position - direction, Vector3.UP)
	else:
		push_warning("Direction should be normalized")
	
	match state:
		State.BURIED:
			if timer < 0.0: set_state(State.EMERGING)
		State.EMERGING:
			var t: float = clamp(timer / EMERGING, 0.0, 1.0)
			global_position = grave.global_position - Vector3.UP * HEIGHT * t
			if timer < 0.0: set_state(State.ROAMING)

func _physics_process(delta: float):
	match state:
		State.ROAMING:
			move(delta)

func _update_bar_transform() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	# Face the camera so the fill can shrink along screen-space x.
	bar.global_basis = cam.global_basis
	bar.global_position = global_position + Vector3(0.0, BAR_Y, 0.0)

func attack_crypt() -> void:
	var crypt := get_tree().get_first_node_in_group("crypt")
	if crypt == null or not anim.has_animation("attack-melee-right"):
		anim.pause()
		return

	var to_crypt := crypt_target.global_position - global_position
	to_crypt.y = 0.0
	if to_crypt.length_squared() > 1e-3:
		direction = to_crypt.normalized()

	anim.get_animation("attack-melee-right").loop_mode = Animation.LOOP_NONE
	while state == State.ROAMING:
		anim.play("attack-melee-right")
		# Land the hit halfway through the swing.
		await get_tree().create_timer(anim.current_animation_length * 0.5).timeout
		if state != State.ROAMING:
			return
		crypt.take_damage(1)
		await anim.animation_finished
		if state != State.ROAMING:
			return
		# Cooldown between swings.
		await get_tree().create_timer(ATTACK_COOLDOWN).timeout

func choose_target():
	var map := navigation_agent.get_navigation_map()

	if not map.is_valid():
		push_warning("Skeleton navigation map is invalid")
		return

	if crypt_target == null:
		choose_random_target()
		return

	# The crypt itself is carved out of the navmesh, so aim for the closest walkable point.
	navigation_agent.set_target_position(NavigationServer3D.map_get_closest_point(map, crypt_target.global_position))

func choose_random_target():
	var map := navigation_agent.get_navigation_map()

	if not map.is_valid():
		push_warning("Skeleton navigation map is invalid")
		return

	var target := NavigationServer3D.map_get_random_point(map, navigation_agent.navigation_layers, true)

	navigation_agent.set_target_position(target)

func move(delta: float):
	if navigation_agent.is_navigation_finished():
		if crypt_target == null:
			choose_random_target()
		elif not arrived:
			arrived = true
			velocity = Vector3.ZERO
			attack_crypt()
		return

	var next := navigation_agent.get_next_path_position()
	var dir := global_position.direction_to(next)

	if dir.length_squared() < 1e-3:
		return

	var alignment := 1.0 - exp(-ALIGNMENT * delta)
	direction = lerp(direction, dir, alignment).normalized()
	var vel := direction * SPEED

	if navigation_agent.avoidance_enabled:
		navigation_agent.velocity = vel
	else:
		_on_velocity_computed(vel)
	
func _on_velocity_computed(safe_velocity: Vector3):
	velocity = safe_velocity
	move_and_slide()
	# Avoidance can steer away from `direction`; face the way we actually move.
	var flat := Vector3(safe_velocity.x, 0.0, safe_velocity.z)
	if flat.length_squared() > 0.01:
		var blended := direction.lerp(flat.normalized(), 0.2)
		if blended.length_squared() > 1e-3:
			direction = blended.normalized()
