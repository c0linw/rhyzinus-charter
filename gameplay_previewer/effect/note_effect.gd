extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const base_width: float = 256.0


# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play("Burst")


func scale_to_width(width):
	scale = Vector2(width/base_width, width/base_width)

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Burst":
		queue_free()
