extends Control
class_name TimingPoint

var time: float
var type: String
var bpm_color: Color = Color(1,0,0,0)
var velocity_color: Color = Color(0,1,0,0)

signal custom_gui_input(event, timingpoint)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_data(timingpoint_data: Dictionary):
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_TimingPoint_gui_input(event):
	emit_signal("custom_gui_input", event, self)
