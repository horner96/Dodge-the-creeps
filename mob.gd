extends RigidBody2D

var slowed := false
var slow_warning_active := false

func set_slowed(enabled: bool) -> void:
	slowed = enabled
	slow_warning_active = false
	$AnimatedSprite2D.modulate = Color("b86bff") if enabled else Color.WHITE

func set_slow_warning(enabled: bool) -> void:
	slow_warning_active = enabled

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("mobs")
	var mob_types = Array($AnimatedSprite2D.sprite_frames.get_animation_names())
	$AnimatedSprite2D.animation = mob_types.pick_random()
	$AnimatedSprite2D.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if slow_warning_active:
		var blink_is_purple := int(Time.get_ticks_msec() / 125) % 2 == 0
		$AnimatedSprite2D.modulate = Color("b86bff") if blink_is_purple else Color.WHITE


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
