extends OptionButton


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var subdivisions: Dictionary = {
	"1/1 (4ths)": 1,
	"1/2 (8ths)": 2,
	"1/3 (12ths)": 3,
	"1/4 (16ths)": 4,
	"1/5 (20ths)": 5,
	"1/6 (24ths)": 6,
	"1/7 (28ths)": 7,
	"1/8 (32nds)": 8,
	"1/9 (36ths)": 9,
	"1/10 (40ths)": 10,
	"1/12 (48ths)": 12,
	"1/16 (64ths)": 16
}

signal subdivision_changed(subdivision)

# Called when the node enters the scene tree for the first time.
func _ready():
	for name in subdivisions.keys():
		add_item(name)
	selected = 3
	yield(get_tree(), "idle_frame")
	emit_signal("subdivision_changed", 4)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_SubdivisionOption_item_selected(index):
	emit_signal("subdivision_changed", subdivisions[subdivisions.keys()[index]])
