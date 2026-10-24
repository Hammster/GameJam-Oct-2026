extends Node3D

const SPEED := 1.0
const MIN_BURIED := 3.0
const MAX_BURIED := 6.0
const EMERGING := 5.0
const HEIGHT := 0.74
const JITTER := 0.1

@export var grave := Vector3.ZERO

@onready var anim := $AnimationPlayer

enum State {
	BURIED,
	EMERGING,
	ROAMING,
	DEATH,
}

var state: State
var timer := 0.0
var facing := Vector2(0.0, 1.0)

func _ready():
	set_state(State.BURIED)

func set_state(new_state: State):
	state = new_state
	on_enter()

func on_enter():
	match state:
		State.BURIED:
			visible = false
			position = grave
			timer = randf_range(MIN_BURIED, MAX_BURIED)
		State.EMERGING:
			visible = true
			position = grave
			timer = EMERGING
			anim.play("pick-up")
		State.ROAMING:
			visible = true
			anim.play("walk")
			pass
		State.DEATH:
			visible = false
			anim.play("die")
			pass

func _process(delta):
	timer -= delta

	var dir := Vector3(facing.x, 0.0, facing.y)
	look_at(global_position - dir, Vector3.UP)
	
	match state:
		State.BURIED:
			if timer < 0.0: set_state(State.EMERGING)
		State.EMERGING:
			var t: float = clamp(timer / EMERGING, 0.0, 1.0)
			position = grave - Vector3.UP * HEIGHT * t
			if timer < 0.0: set_state(State.ROAMING)
		State.ROAMING:
			position += dir * SPEED * delta
			var t: float = pow(JITTER, delta)
			facing = lerp(Vector2.from_angle(randf() * TAU), facing, t)
			facing = facing.normalized()
