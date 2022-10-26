extends Node

# enums and constants
enum {CORRUPTED, CRACKED, DECRYPTED, FLAWLESS}

var results: Dictionary = {
	CORRUPTED: [],
	CRACKED: [],
	DECRYPTED: [],
	FLAWLESS: []
}

var notecount: int = 0
var score: int = 0

signal score_updated(score)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Game_note_judged(input):
	results[input.judgement].append(input.offset)
	update_score()
	
func update_score():
	if notecount == 0:
		return
	var float_score = 1000000 * len(results[FLAWLESS]) / notecount
	float_score += 1000000 * len(results[DECRYPTED]) * 0.99 / notecount
	float_score += 1000000 * len(results[CRACKED]) * 0.50 / notecount
	score = int(float_score)
	emit_signal("score_updated", score)
	
func reset():
	results = {
		CORRUPTED: [],
		CRACKED: [],
		DECRYPTED: [],
		FLAWLESS: []
	}
	update_score()
