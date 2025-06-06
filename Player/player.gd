extends CharacterBody2D

class_name Player

const PlayerHurtSound = preload("res://Player/player_hurt_sound.tscn")

@export  var ACCELERATION = 500
@export  var MAX_SPEED = 80
@export  var ROLL_SPEED = 120
@export  var FRICTION = 500

signal no_health

			
enum {
	MOVE,
	ROLL,
	ATTACK
}

var state = MOVE
#var velocity = Vector2.ZERO
var roll_vector = Vector2.DOWN
var stats = PlayerStats

@onready var animationPlayer = $AnimationPlayer
@onready var animationTree = $AnimationTree
@onready var animationState = animationTree.get("parameters/playback")
@onready var sword_hitbox = $HitboxPivot/SwordHitbox
@onready var hurtbox = $Hurtbox
@onready var blinkAnimationPlayer = $BlinkAnimationPlayer

func _ready():
	randomize()
	stats.connect("no_health", Callable(self, "queue_free"))
	animationTree.active = true
	sword_hitbox.knockback_vector = roll_vector

func _physics_process(delta):
	match state:
		MOVE:
			move_state(delta)
			
		ROLL:
			roll_state()
			
		ATTACK:
			attack_state()
	
func move_state(delta):
	var input_vector= Vector2.ZERO
	input_vector.x = Input.get_action_strength('ui_right') - Input.get_action_strength('ui_left')
	input_vector.y = Input.get_action_strength('ui_down') - Input.get_action_strength('ui_up')
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		roll_vector = input_vector
		sword_hitbox.knockback_vector = input_vector
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		animationTree.set("parameters/Attack/blend_position", input_vector)
		animationTree.set("parameters/Roll/blend_position", input_vector)
		animationState.travel("Run")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	else :
		animationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	move()
	
	if  Input.is_action_just_pressed("roll"):
		state = ROLL
	
	if  Input.is_action_just_pressed("attack"):
		state = ATTACK

func roll_state():
	velocity = roll_vector * ROLL_SPEED
	animationState.travel("Roll")
	move()

func attack_state():
	velocity = Vector2.ZERO
	animationState.travel("Attack")

func move():
	move_and_slide()

func roll_animation_finished():
	velocity = velocity * 0.8
	state = MOVE

func attack_animation_finished():
	state = MOVE

func _on_hurtbox_area_entered(area):
	stats.health -= area.damage
	hurtbox.start_invincibility(0.6)
	hurtbox.create_hit_effect()
	var playerHurtSounds = PlayerHurtSound.instantiate()
	get_tree().current_scene.add_child(playerHurtSounds)
	#state.health -= area.damage

func _on_hurtbox_invinciblility_started() -> void:
	blinkAnimationPlayer.play("Start")

func _on_hurtbox_invinciblility_ended() -> void:
	blinkAnimationPlayer.play("Stop")
