extends Node


var unsaved_changes: bool = false

signal status_changed(status)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_modified():
	unsaved_changes = true
	emit_signal("status_changed", "Modified")
	
func set_saved():
	unsaved_changes = false
	emit_signal("status_changed", "Saved")
	
func set_status(status: String):
	emit_signal("status_changed", status)
