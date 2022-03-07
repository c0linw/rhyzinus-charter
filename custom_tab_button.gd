extends Button


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var currently_selected: bool = false
export var tab_index: int = 0

signal tab_selected(index)

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("pressed", self, "_on_custom_tab_pressed")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_custom_tab_pressed():
	emit_signal("tab_selected", tab_index)
