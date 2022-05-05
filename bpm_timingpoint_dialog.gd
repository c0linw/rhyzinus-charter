extends WindowDialog


var timing_point_instance

signal set_bpm_point(instance, offset, bpm, meter)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func is_valid_offset_value(text: String):
	if text.is_valid_float():
		var num: float = float(text)
		if num >= 0:
			return true
	return false
	
	
func is_valid_bpm_value(text: String):
	if text.is_valid_float():
		var num: float = float(text)
		if num > 0:
			return true
	return false
	
	
func is_valid_meter_value(text: String):
	if text.is_valid_integer():
		var num: int = int(text)
		if num > 0:
			return true
	return false


func check_inputs() -> bool:
	var valid = true
	$VBoxContainer/ErrorMsg.text = ""
	if not is_valid_offset_value($VBoxContainer/GridContainer/OffsetValue.text):
		valid = false
		$VBoxContainer/ErrorMsg.text = "Invalid offset value"
	elif not is_valid_offset_value($VBoxContainer/GridContainer/BPMValue.text):
		valid = false
		$VBoxContainer/ErrorMsg.text = "Invalid BPM value"
	elif not is_valid_offset_value($VBoxContainer/GridContainer/MeterValue.text):
		valid = false
		$VBoxContainer/ErrorMsg.text = "Invalid meter value"
	return valid
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var valid = check_inputs()
	
	if not valid:
		$VBoxContainer/ConfirmButton.disabled = true
	else:
		$VBoxContainer/ConfirmButton.disabled = false


func _on_ConfirmButton_pressed():
	var valid = check_inputs()
	
	if valid:
		var offset: float = float($VBoxContainer/GridContainer/OffsetValue.text)
		var bpm: float = float($VBoxContainer/GridContainer/BPMValue.text)
		var meter: int = int($VBoxContainer/GridContainer/MeterValue.text)
		emit_signal("set_bpm_point", timing_point_instance, offset, bpm, meter)
