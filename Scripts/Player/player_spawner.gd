extends Node2D

signal spawning_player(player: CharacterBody2D)

@export var player: PackedScene
const DEFAULT_SPAWN: Vector2 = Vector2(100, 100)

var player_count: int = 0

func _enter_tree() -> void:
	ClientGlobals.spawn_player.connect(spawn_player)
	ServerGlobals.spawn_player.connect(spawn_player)

func _exit_tree() -> void:
	ClientGlobals.spawn_player.disconnect(spawn_player)
	ServerGlobals.spawn_player.disconnect(spawn_player)

func spawn_player(owner_id: int, position: Vector2 = DEFAULT_SPAWN) -> void:
	if player == null: return
	player_count += 1
	var new_player = player.instantiate()
	new_player.owner_id = owner_id
	# Set the players location accordingly server side - then push a packet to update the player with their position
	if NetworkHandler.is_server:
		if player_count == 1:
			new_player.global_position = $"../Player1Spawn".global_position
		elif player_count == 2:
			new_player.global_position = $"../Player2Spawn".global_position
	
	# Otherwise, on the client, spawn at the position provided
	else:
		new_player.global_position = position
	
	get_parent().call_deferred("add_child", new_player)
	spawning_player.emit(new_player)
	
	# Broadcast to the server that this player should be spawned
	if NetworkHandler.is_server:
		var player_spawn: PlayerSpawn = PlayerSpawn.create(owner_id, new_player.global_position)
		player_spawn.broadcast(NetworkHandler.connection)
