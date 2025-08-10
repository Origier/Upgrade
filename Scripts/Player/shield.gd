extends Area2D

# Time for the shield to exist
var time_alive: int = 1
var owner_id: int

func _ready() -> void:
	$ExsistenceTimer.wait_time = time_alive
	$ExsistenceTimer.start()
	

# Delete this shield after the timer has depleted
func _on_exsistence_timer_timeout() -> void:
	queue_free()
