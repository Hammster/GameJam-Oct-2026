extends CharacterBody3D

const SPEED := 3.0
const ATTACK_DAMAGE := 1
# Physics layers: 2 = player attacks, 3 = enemies (set matching layers on enemies).
const ATTACK_LAYER := 1 << 1
const ENEMY_LAYER := 1 << 2

var attacking := false
var hitbox: Area3D
var hitbox_material: StandardMaterial3D

@onready var character: Node3D = $"character-digger"
@onready var anim: AnimationPlayer = $"character-digger/AnimationPlayer"


func _ready() -> void:
	_create_hitbox()
	for name in ["walk", "idle"]:
		if anim.has_animation(name):
			anim.get_animation(name).loop_mode = Animation.LOOP_LINEAR

func _physics_process(delta: float) -> void:
	if attacking:
		velocity = Vector3.ZERO
		return
	if Input.is_action_just_pressed("attack"):
		attack()
		return
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := Vector3(input.x, 0.0, input.y)
	if dir != Vector3.ZERO:
		dir = dir.normalized()
		velocity = dir * SPEED
		move_and_slide()
		character.rotation.y = lerp_angle(character.rotation.y, atan2(dir.x, dir.z), 0.2)
		if anim.current_animation != "walk":
			anim.play("walk")
	else:
		velocity = Vector3.ZERO
		if anim.has_animation("idle"):
			if anim.current_animation != "idle":
				anim.play("idle")
		else:
			anim.stop()


func _create_hitbox() -> void:
	hitbox = Area3D.new()
	hitbox.collision_layer = ATTACK_LAYER
	hitbox.collision_mask = ENEMY_LAYER
	hitbox.monitoring = false
	hitbox.position = Vector3(0, 0.3, 0.4) # In front of the character (+Z is forward).
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.5, 0.5, 0.5)
	shape.shape = box
	hitbox.add_child(shape)

	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = box.size
	hitbox_material = StandardMaterial3D.new()
	hitbox_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hitbox_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hitbox_material.albedo_color = Color(1, 1, 1, 0.2)
	box_mesh.material = hitbox_material
	mesh.mesh = box_mesh
	hitbox.add_child(mesh)

	character.add_child(hitbox)
	hitbox.body_entered.connect(_on_hit)
	hitbox.area_entered.connect(_on_hit)


func _on_hit(target: Node) -> void:
	if target.has_method("take_damage"):
		target.take_damage(ATTACK_DAMAGE)

func attack() -> void:
	if not anim.has_animation("attack-melee-right"):
		return
	attacking = true
	hitbox.monitoring = true
	hitbox_material.albedo_color = Color(1, 0, 0, 0.5)
	anim.play("attack-melee-right")
	await anim.animation_finished
	hitbox.monitoring = false
	hitbox_material.albedo_color = Color(1, 1, 1, 0.2)
	attacking = false
