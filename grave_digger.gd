extends Node3D

const SPEED := 3.0

@onready var character: Node3D = $"character-digger"
@onready var anim: AnimationPlayer = $"character-digger/AnimationPlayer"


func _ready() -> void:
	for name in ["walk", "idle"]:
		if anim.has_animation(name):
			anim.get_animation(name).loop_mode = Animation.LOOP_LINEAR


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	print(input)
	var dir := Vector3(input.x, 0.0, input.y)
	if dir != Vector3.ZERO:
		dir = dir.normalized()
		character.position += dir * SPEED * delta
		character.rotation.y = lerp_angle(character.rotation.y, atan2(dir.x, dir.z), 0.2)
		if anim.current_animation != "walk":
			anim.play("walk")
	elif anim.current_animation != "idle" and anim.has_animation("idle"):
		anim.play("idle")
	elif not anim.has_animation("idle"):
		anim.stop()
