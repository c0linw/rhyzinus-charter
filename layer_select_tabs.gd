extends HBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	_on_custom_tab_selected(0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_custom_tab_selected(index):
	$TabContainer.current_tab = index
	for child in $VerticalTabs.get_children():
		if child.tab_index == index:
			child.currently_selected = true
			child.flat = true
			child.rect_min_size = Vector2(64,32)
		else:
			child.currently_selected = false
			child.flat = false
			child.rect_min_size = Vector2(55,0)
