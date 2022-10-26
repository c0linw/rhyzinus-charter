extends Label

var current_combo: int = 0
var best_combo: int = 0

enum {ENCRYPTED, CRACKED, DECRYPTED, FLAWLESS}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if current_combo > 0:
		text = ""
		text += str(current_combo)
	else:
		text = ""


func _on_Game_note_judged(result: Dictionary):
	if result["judgement"] != ENCRYPTED:
		current_combo += 1
	else:
		best_combo = current_combo
		current_combo = 0


func _on_Conductor_finished():
	if current_combo > best_combo:
		best_combo = current_combo

func reset():
	current_combo = 0
	best_combo = 0
