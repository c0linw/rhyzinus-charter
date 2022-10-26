extends Node2D

var pos
var pic
var pictex

var width
var height
var decay = 0.500

func _ready():
	pass

func _process(delta):
	if decay <= 0:
		queue_free()
	decay -= delta
	translate(Vector2(0, -width*delta))
	update()

func _draw():
	draw_texture_rect(pictex, pos, false, Color(1,1,1,2*decay))
	
func setup(texture: ImageTexture, width_input: float):
	pictex = texture
	
	width = width_input
	height = width * 0.5
	pos = Rect2(Vector2(0, 0), Vector2(width, height))
