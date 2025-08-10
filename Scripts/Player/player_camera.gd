extends Camera2D

var owner_id: int = -1
var player_target: CharacterBody2D

# connect to connecting to server
func _enter_tree() -> void:
	ClientGlobals.on_player_id_assign.connect(on_player_id_assign)
	$"../PlayerSpawner".spawning_player.connect(set_camera_owner)
	
func _exit_tree() -> void:
	ClientGlobals.on_player_id_assign.disconnect(on_player_id_assign)
	$"../PlayerSpawner".spawning_player.disconnect(set_camera_owner)

func on_player_id_assign(id: int) -> void:
	owner_id = id

# Set this camera's ownership to the clients id and find the clients player to track
func set_camera_owner(player: CharacterBody2D) -> void:
	if owner_id != player.owner_id: return
	player_target = player

# Sync with the players position
func _process(_delta: float) -> void:
	if player_target == null: return
	global_position = player_target.global_position
