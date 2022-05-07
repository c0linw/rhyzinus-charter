extends ScrollContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	yield(get_tree(), "idle_frame")
	scroll_vertical = $Chart.get_global_rect().size.y
	update()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Chart_anchor_scroll(percentage, new_size):
	scroll_vertical = percentage * new_size - rect_size.y
	update()
