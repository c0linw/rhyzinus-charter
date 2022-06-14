extends WindowDialog


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

signal save_prompt_confirm(save)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Save_pressed():
	emit_signal("save_prompt_confirm", true)
	hide()


func _on_DontSave_pressed():
	emit_signal("save_prompt_confirm", false)
	hide()


func _on_Cancel_pressed():
	hide()
