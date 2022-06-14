extends Label


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	EditorStatus.connect("status_changed", self, "_on_EditorStatus_status_changed")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_EditorStatus_status_changed(status):
	text = status
