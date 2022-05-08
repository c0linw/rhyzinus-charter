extends MenuButton


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal item_pressed(id)

# Called when the node enters the scene tree for the first time.
func _ready():
	get_popup().connect("id_pressed", self, "_on_id_pressed")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_id_pressed(id):
	emit_signal("item_pressed", id)
