extends CharacterBody3D

const SPEED := 3.0
# Physics layers: 2 = PlayerAttack, 3 = skeletons.
const ATTACK_LAYER := 1 << 1
const ENEMY_LAYER := 1 << 2
const HITBOX_SIZE := Vector3(0.8, 0.8, 0.8)
const HITBOX_OFFSET := Vector3(0, 0.4, 0.5) # +Z is the character's forward.

var attacking := false

@onready var character: Node3D = $"character-digger"
@onready var anim: AnimationPlayer = $"character-digger/AnimationPlayer"


func _ready() -> void:
	add_to_group("player")
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_SPACE
		InputMap.action_add_event("attack", ev)
	for name in ["walk", "idle", "attack-melee-right"]:
		if anim.has_animation(name):
			anim.get_animation(name).loop_mode = Animation.LOOP_NONE if name.begins_with("attack") else Animation.LOOP_LINEAR


func _physics_process(delta: float) -> void:
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	velocity.y = 0.0 if is_on_floor() else velocity.y - gravity * delta

	if attacking:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	if Input.is_action_just_pressed("attack"):
		attack()
		return
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := Vector3(input.x, 0.0, input.y)
	if dir != Vector3.ZERO:
		dir = dir.normalized()
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
		character.rotation.y = lerp_angle(character.rotation.y, atan2(dir.x, dir.z), 0.2)
		if anim.current_animation != "walk":
			anim.play("walk")
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if anim.has_animation("idle"):
			if anim.current_animation != "idle":
				anim.play("idle")
		else:
			anim.stop()
	move_and_slide()


func attack() -> void:
	attacking = true
	anim.play("attack-melee-right")

	var hitbox := Area3D.new()
	hitbox.collision_layer = ATTACK_LAYER
	hitbox.collision_mask = ENEMY_LAYER
	hitbox.position = HITBOX_OFFSET
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = HITBOX_SIZE
	shape.shape = box
	hitbox.add_child(shape)
	character.add_child(hitbox)

	# Overlaps are only reported after the area has gone through a physics step.
	await get_tree().physics_frame
	await get_tree().physics_frame
	for body in hitbox.get_overlapping_bodies():
		if body.has_method("hit"):
			body.hit()
	hitbox.queue_free()

	await anim.animation_finished
	attacking = false
