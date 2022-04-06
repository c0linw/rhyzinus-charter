extends PanelContainer


# Declare member variables here. Examples:
export(String, "none", "tap_lower", "hold_start_lower", "hold_end_lower", "swipe_lower", "tap_upper", "hold_start_upper", "hold_end_upper", "bpm", "velocity") var type

var normal_color: Color = Color("423f4a")
var normal_shadow: Color = Color(0, 0, 0, 0.6)

var selected_color: Color = Color("34323b")
var selected_shadow: Color = Color(0.6, 0.85, 1, 0.6)

var selected: bool = false

signal notetype_selected(type)

# Called when the node enters the scene tree for the first time.
func _ready():
	var tex: Texture
	match type:
		"tap_lower": tex = load("res://images/tap.png")
		"hold_start_lower": tex = load("res://images/hold_start.png")
		"hold_end_lower": tex = load("res://images/hold_end.png")
		"tap_upper": tex = load("res://images/tap_upper.png")
		"hold_start_upper": tex = load("res://images/hold_start_upper.png")
		"hold_end_upper": tex = load("res://images/hold_end_upper.png")
		# TODO: add swipe notes
		"bpm": tex = load("res://images/bpm.png")
		"velocity": tex = load("res://images/velocity.png")
	$MarginContainer/VBoxContainer/TextureRect.texture = tex
	$MarginContainer/VBoxContainer/Label.text = type

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func set_selected(selected_input: bool):
	if selected == selected_input:
		return
	var style = get("custom_styles/panel")
	if selected_input:
		style.bg_color = selected_color
		style.shadow_color = selected_shadow
	else:
		style.bg_color = normal_color
		style.shadow_color = normal_shadow
	selected = selected_input


func _on_PanelContainer_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			set_selected(true)
			emit_signal("notetype_selected", type)
