extends Node

@export var mob_scene: PackedScene
@export var power_up_scene: PackedScene
var score
const SLOW_MULTIPLIER := 0.5
const MOB_SPAWN_INTERVAL := 0.5
var slow_active := false
var slow_warning_active := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Player.shield_charges_changed.connect($HUD.update_shields)
	$HUD.update_shields($Player.shield_charges)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func game_over():
	$HUD.show_game_over()
	$ScoreTimer.stop()
	$MobTimer.stop()
	$PowerUpTimer.stop()
	$InvincibilityTimer.stop()
	$SlowDurationTimer.stop()
	clear_temporary_power_ups()
	get_tree().call_group("power_ups", "queue_free")

func new_game():
	score = 0
	clear_temporary_power_ups()
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")
	$Player.start($StartPosition.position)
	$StartTimer.start()


func _on_mob_timer_timeout():
	# Create a new instance of the Mob scene.
	var mob = mob_scene.instantiate()

	# Choose a random location on Path2D.
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()

	# Set the mob's position to the random location.
	mob.position = mob_spawn_location.position

	# Set the mob's direction perpendicular to the path direction.
	var direction = mob_spawn_location.rotation + PI / 2

	# Add some randomness to the direction.
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction

	# Choose the velocity for the mob.
	var velocity = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	# Spawn the mob by adding it to the Main scene.
	if slow_active:
		mob.linear_velocity *= SLOW_MULTIPLIER
		mob.set_slowed(true)
		mob.set_slow_warning(slow_warning_active)
	add_child(mob)


func _on_score_timer_timeout():
	score += 1
	$HUD.update_score(score)

func _on_start_timer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()
	_on_power_up_timer_timeout()
	$PowerUpTimer.start()

func _on_power_up_timer_timeout():
	var power_up = power_up_scene.instantiate()
	power_up.position = Vector2(randf_range(36.0, 444.0), randf_range(36.0, 684.0))
	var roll = randf()
	if roll < 0.25:
		power_up.configure("invincibility")
	elif roll < 0.5:
		power_up.configure("screen_clear")
	elif roll < 0.75:
		power_up.configure("shield")
	else:
		power_up.configure("slow_enemies")
	power_up.collected.connect(_on_power_up_collected)
	add_child(power_up)

func _on_power_up_collected(power_up_type: String):
	if power_up_type == "shield":
		$Player.add_shield_charge()
		return
	match power_up_type:
		"invincibility":
			$Player.set_invincible(true)
			$InvincibilityTimer.start()
		"screen_clear":
			clear_screen()
			return
		"slow_enemies":
			if not slow_active:
				slow_active = true
				for mob in get_tree().get_nodes_in_group("mobs"):
					mob.linear_velocity *= SLOW_MULTIPLIER
					mob.set_slowed(true)
				$MobTimer.wait_time = MOB_SPAWN_INTERVAL / SLOW_MULTIPLIER
				$MobTimer.start()
			slow_warning_active = false
			for mob in get_tree().get_nodes_in_group("mobs"):
				mob.set_slow_warning(false)
			$SlowWarningTimer.start()
			$SlowDurationTimer.start()

func clear_screen():
	get_tree().call_group("mobs", "queue_free")
	$ScreenClearPulse.position = $Player.position
	$ScreenClearPulse.scale = Vector2.ONE
	$ScreenClearPulse.modulate = Color(1, 0.15, 0.15, 0.8)
	$ScreenClearPulse.show()
	var tween = create_tween().set_parallel(true)
	tween.tween_property($ScreenClearPulse, "scale", Vector2(24, 24), 0.45)
	tween.tween_property($ScreenClearPulse, "modulate", Color(1, 0.15, 0.15, 0), 0.45)
	tween.chain().tween_callback($ScreenClearPulse.hide)

func _on_slow_warning_timer_timeout():
	slow_warning_active = true
	for mob in get_tree().get_nodes_in_group("mobs"):
		mob.set_slow_warning(true)

func _on_invincibility_timer_timeout():
	$Player.set_invincible(false)

func _on_slow_duration_timer_timeout():
	clear_slowdown()

func clear_temporary_power_ups():
	$InvincibilityTimer.stop()
	$Player.set_invincible(false)
	clear_slowdown()

func clear_slowdown():
	$SlowWarningTimer.stop()
	slow_warning_active = false
	if slow_active:
		for mob in get_tree().get_nodes_in_group("mobs"):
			mob.linear_velocity /= SLOW_MULTIPLIER
			mob.set_slowed(false)
		$MobTimer.wait_time = MOB_SPAWN_INTERVAL
		if not $MobTimer.is_stopped():
			$MobTimer.start()
	slow_active = false
