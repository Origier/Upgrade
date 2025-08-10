extends TextureProgressBar


# Set the call-back function and the players health on loading
func _ready() -> void:
	$"..".on_damage_recieved.connect(on_damage_recieved)
	value = $"..".player_health


func on_damage_recieved(damage: int) -> void:
	value -= damage
