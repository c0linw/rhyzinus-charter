extends WindowDialog


enum {SAVE, DONTSAVE, CANCEL}

var option_chosen: int = CANCEL

signal save_prompt_confirm(option)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func popup_custom():
	call_deferred("popup_centered")
	option_chosen = CANCEL


func _on_Save_pressed():
	option_chosen = SAVE
	hide()


func _on_DontSave_pressed():
	option_chosen = DONTSAVE
	hide()


func _on_Cancel_pressed():
	option_chosen = CANCEL
	hide()


func _on_UnsavedPrompt_popup_hide():
	emit_signal("save_prompt_confirm", option_chosen)
