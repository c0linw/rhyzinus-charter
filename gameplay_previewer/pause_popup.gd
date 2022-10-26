extends Popup


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal unpause
signal restart
signal quit

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_ResumeButton_pressed():
	hide()
	emit_signal("unpause")
	get_tree().paused = false
	


func _on_RetryButton_pressed():
	hide()
	emit_signal("restart")
	get_tree().paused = false


func _on_QuitButton_pressed():
	hide()
	emit_signal("quit")
	get_tree().paused = false
