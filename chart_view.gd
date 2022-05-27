extends ScrollContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	get_v_scrollbar().mouse_filter = MOUSE_FILTER_IGNORE
	yield(get_tree(), "idle_frame")
	scroll_vertical = $Chart.get_global_rect().size.y
	update()
	get_v_scrollbar().rect_scale = Vector2(0,0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Chart_anchor_scroll(percentage, new_size):
	scroll_vertical = percentage * new_size - rect_size.y
	update()


func _on_PlaybackSliderDisplay_playback_scrub(percentage):
	pass # Replace with function body.


func _on_SongAudioPlayer_song_position_updated(new_position, max_position):
	scroll_vertical = (1 - new_position/max_position) * $Chart.rect_size.y - rect_size.y
