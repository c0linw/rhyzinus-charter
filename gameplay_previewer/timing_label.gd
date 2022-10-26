extends Label

enum {ENCRYPTED, CRACKED, DECRYPTED, FLAWLESS}

var decay = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if decay <= 0:
		text = ""
		return
	decay -= delta

func _on_Game_note_judged(result):
	if result["judgement"] == CRACKED or result["judgement"] == DECRYPTED:
		if result["offset"] < 0:
			text = "EARLY"
			add_color_override("font_color", Color(0.1, 1, 0.1, 1))
		elif result["offset"] > 0:
			text = "LATE"
			add_color_override("font_color", Color(1, 0.1, 0.1, 1))
		else:
			text = ""
		decay = 0.5
