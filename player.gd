extends Area2D
signal hit
signal shield_charges_changed(charges: int)

@export var speed = 400 # How fast the player will move (pixels/sec).
var screen_size # Size of the game window.extends Area2D
var invincible := false
var invincibility_warning_active := false
var shield_charges := 0

func set_invincible(enabled: bool) -> void:
	invincible = enabled
	invincibility_warning_active = false
	$InvincibilityWarningTimer.stop()
	update_power_up_color()
	if enabled:
		$InvincibilityWarningTimer.start()

func add_shield_charge() -> void:
	shield_charges += 1
	update_power_up_color()
	shield_charges_changed.emit(shield_charges)

func reset_shield_charges() -> void:
	shield_charges = 0
	update_power_up_color()
	shield_charges_changed.emit(shield_charges)

func update_power_up_color() -> void:
	if invincible:
		$AnimatedSprite2D.modulate = Color("ffd166")
	elif shield_charges > 0:
		$AnimatedSprite2D.modulate = Color("62d96b")
	else:
		$AnimatedSprite2D.modulate = Color.WHITE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	hide()

func _process(delta):
	if invincibility_warning_active:
		var blink_is_yellow := int(Time.get_ticks_msec() / 125) % 2 == 0
		$AnimatedSprite2D.modulate = Color("ffd166") if blink_is_yellow else Color.WHITE

	var velocity = Vector2.ZERO # The player's movement vector.
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
		
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	if velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
		# See the note below about the following boolean assignment.
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = velocity.y > 0


func _on_body_entered(body):
	if invincible:
		body.queue_free()
		return
	if shield_charges > 0:
		shield_charges -= 1
		update_power_up_color()
		shield_charges_changed.emit(shield_charges)
		body.queue_free()
		return

	hide() # Player disappears after being hit.
	hit.emit()
	# Must be deferred as we can't change physics properties on a physics callback.
	$CollisionShape2D.set_deferred("disabled", true)
	
func start(pos):
	position = pos
	set_invincible(false)
	reset_shield_charges()
	show()
	$CollisionShape2D.disabled = false

func _on_invincibility_warning_timer_timeout() -> void:
	invincibility_warning_active = true
