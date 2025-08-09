# The server file, handles managing clients upon connection
# The server handles validation client input and broadcasts valid responses
extends Node

signal on_player_sync(id: int, position: Vector2, rotation: float, cannon_rotation: float)
signal on_player_shoot(id: int)
signal on_player_hotkey(id: int, hotkey: int)
signal spawn_player(id: int)

var connected_peers: Array
const PLAYER = preload("res://Scenes/player.tscn")
const DEFAULT_SPAWN: Vector2 = Vector2(100, 100)

func _ready() -> void:
	NetworkHandler.on_peer_connected.connect(on_client_connected)
	NetworkHandler.on_peer_disconnected.connect(on_client_disconnected)
	NetworkHandler.on_server_packet.connect(on_server_packet)
	
func on_client_connected(client_id: int) -> void:
	connected_peers.append(client_id)
	# Broadcast to the server that this peer has just connected
	IDAssignment.create(client_id, connected_peers).broadcast(NetworkHandler.connection)
	# Create the player in the game on the server
	spawn_player.emit(client_id)

func on_client_disconnected(client_id: int) -> void:
	pass
	
func on_server_packet(client_id: int, packet: PackedByteArray) -> void:
	var packet_type: Packet.PACKET_TYPE = packet.decode_u8(Packet.TYPE_POSITION)
	
	match packet_type:
		Packet.PACKET_TYPE.PLAYER_SYNC:
			var player_sync_packet: PlayerSync = PlayerSync.create_from_data(packet)
			on_player_sync.emit(player_sync_packet.id, player_sync_packet.position, player_sync_packet.rotation, player_sync_packet.cannon_rotation)
			player_sync_packet.broadcast(NetworkHandler.connection)
			
		Packet.PACKET_TYPE.PLAYER_SHOOT:
			var player_shoot_packet: PlayerShoot = PlayerShoot.create_from_data(packet)
			on_player_shoot.emit(player_shoot_packet.id)
			player_shoot_packet.broadcast(NetworkHandler.connection)
		
		Packet.PACKET_TYPE.PLAYER_HOTKEY:
			var player_hotkey_packet: PlayerHotkey = PlayerHotkey.create_from_data(packet)
			on_player_hotkey.emit(player_hotkey_packet.id, player_hotkey_packet.hotkey)
			player_hotkey_packet.broadcast(NetworkHandler.connection)
		
		_:
			printerr("Packet of type ", packet_type, " unhandled by the server.")
