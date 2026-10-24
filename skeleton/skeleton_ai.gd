extends CharacterBody3D

const SPEED := 1.0
const MIN_BURIED := 3.0
const MAX_BURIED := 6.0
const EMERGING := 5.0
const HEIGHT := 0.74
const ALIGNMENT := 0.99

@export var grave: Node3D
# Overrides the random buried time when >= 0.
var buried_time := -1.0

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
	set_state(State.BURIED)
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))

func set_state(new_state: State):
	state = new_state
	on_enter()

func hit():
	match state:
		State.EMERGING:
			set_state(State.BURIED)
		State.ROAMING:
			set_state(State.DEATH)

func on_enter():
	match state:
		State.BURIED:
			visible = false
			global_position = grave.global_position - Vector3.UP * HEIGHT
			timer = buried_time if buried_time >= 0.0 else randf_range(MIN_BURIED, MAX_BURIED)
		State.EMERGING:
			visible = true
			global_position = grave.global_position - Vector3.UP * HEIGHT
			timer = EMERGING
			anim.play("pick-up")
		State.ROAMING:
			visible = true
			anim.play("walk")
			choose_random_target()
			pass
		State.DEATH:
			visible = false
			anim.play("die")
			pass

func _process(delta: float):
	timer -= delta

	if direction.length_squared() > 1e-3:
		look_at(global_position + direction, Vector3.UP)
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

func choose_random_target():
	var map := navigation_agent.get_navigation_map()

	if not map.is_valid():
		push_warning("Skeleton navigation map is invalid")
		return

	var target := NavigationServer3D.map_get_random_point(map, navigation_agent.navigation_layers, true)

	navigation_agent.set_target_position(target)

func move(delta: float):
	if navigation_agent.is_navigation_finished():
		choose_random_target()
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
