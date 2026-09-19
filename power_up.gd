extends Area2D

signal collected(power_up_type: String)

var power_up_type := ""

func _ready() -> void:
	add_to_group("power_ups")

func configure(type: String) -> void:
	power_up_type = type
	$YellowStar.visible = power_up_type == "invincibility"
	$RedCircle.visible = power_up_type == "screen_clear"
	$GreenTriangle.visible = power_up_type == "shield"
	$PurpleSquare.visible = power_up_type == "slow_enemies"

func _on_area_entered(area: Area2D) -> void:
	if area.name == "Player":
		collected.emit(power_up_type)
		queue_free()