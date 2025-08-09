# The client file, handles the clients needed information upon connecting to the server
extends Node

signal on_player_sync(id: int, position: Vector2, rotation: float, cannon_rotation: float)
signal on_player_shoot(id: int)
signal on_player_hotkey(id: int, hotkey: int)
signal on_player_take_damage(id: int, damage: int)
signal on_bullet_deletion(id: int, owner_id: int)
signal spawn_player(id: int, position: Vector2)
signal on_player_id_assign(id: int)

# Default to negative one to avoid server having client control
const DEFAULT_ID: int = -1
var id: int = DEFAULT_ID
var connected_peers: Array
const PLAYER = preload("res://Scenes/player.tscn")
const DEFAULT_SPAWN: Vector2 = Vector2(100, 100)

func _ready() -> void:
	NetworkHandler.on_connect_to_server.connect(on_connect_to_server)
	NetworkHandler.on_disconnect_from_server.connect(on_disconnect_from_server)
	NetworkHandler.on_client_packet.connect(on_client_packet)
	
func on_connect_to_server() -> void:
	pass
	
func on_disconnect_from_server() -> void:
	pass
	
func on_client_packet(packet: PackedByteArray) -> void:
	var packet_type: Packet.PACKET_TYPE = packet.decode_u8(Packet.TYPE_POSITION)
	
	match packet_type:
		Packet.PACKET_TYPE.ID_ASSIGNMENT:
			var id_packet: IDAssignment = IDAssignment.create_from_data(packet)
			# No id assigned yet - this is this client's id
			# Also spawn all other clients that are currently connected
			if id == DEFAULT_ID:
				id = id_packet.id
				on_player_id_assign.emit(id)
				var peer_ids: Array = id_packet.peer_ids
				for peer in peer_ids:
					if peer != id:
						spawn_player.emit(peer)
			# Broadcast message that a new client has joined - create their player character
			else:
				if id == id_packet.id: return
				connected_peers.append(id_packet.id)
			
		Packet.PACKET_TYPE.PLAYER_SYNC:
			var player_sync_packet: PlayerSync = PlayerSync.create_from_data(packet)
			on_player_sync.emit(player_sync_packet.id, player_sync_packet.position, player_sync_packet.rotation, player_sync_packet.cannon_rotation)
		
		Packet.PACKET_TYPE.PLAYER_SHOOT:
			var player_shoot_packet: PlayerShoot = PlayerShoot.create_from_data(packet)
			on_player_shoot.emit(player_shoot_packet.id)
		
		Packet.PACKET_TYPE.DAMAGE:
			var damage_packet: Damage = Damage.create_from_data(packet)
			on_player_take_damage.emit(damage_packet.id, damage_packet.damage)
		
		Packet.PACKET_TYPE.PLAYER_SPAWN:
			var spawn_packet: PlayerSpawn = PlayerSpawn.create_from_data(packet)
			spawn_player.emit(spawn_packet.id, spawn_packet.position)
		
		Packet.PACKET_TYPE.PLAYER_HOTKEY:
			var player_hotkey_packet: PlayerHotkey = PlayerHotkey.create_from_data(packet)
			on_player_hotkey.emit(player_hotkey_packet.id, player_hotkey_packet.hotkey)
			
		_:
			printerr("Packet of type ", packet_type, " unhandled by the client.")
