extends Node

# IP Address of the server to connect to - likely needs adjustments when porting the game
const IP_ADDRESS: String = "192.168.1.123"
# Port for connections to target
const PORT: int = 42000
# Total number of players that can join a session
const TOTAL_PLAYERS: int = 2

# Server signals
signal on_peer_connected(id: int)
signal on_peer_disconnected(id: int)
signal on_server_packet(peer_id: int, packet: PackedByteArray)

# Client signals
signal on_connect_to_server()
signal on_disconnect_from_server()
signal on_client_packet(packet: PackedByteArray)

# Server variables
var available_ids: Array = range(255, -1, -1)
var connected_peers: Dictionary[int, ENetPacketPeer]

# Client variables
var server_peer: ENetPacketPeer

# General variables
var connection: ENetConnection
var is_server: bool = false

# Main network routing loop - determines what is happening on the network connection and then
# dispatches those events accordingly
func _process(_delta: float) -> void:
	if connection == null: return
	
	handle_events()

# Event handler - dispatches the given network events
func handle_events() -> void:
	var event: Array = connection.service()
	var event_type: ENetConnection.EventType = event[0]
	
	while event_type != ENetConnection.EventType.EVENT_NONE:
		var peer = event[1]
		
		match event_type:
			ENetConnection.EventType.EVENT_CONNECT:
				if is_server:
					on_client_connected(peer)
				else:
					connect_to_server()
			ENetConnection.EventType.EVENT_DISCONNECT:
				if is_server:
					on_client_disconnected(peer)
				else:
					disconnect_from_server()
					return
			ENetConnection.EventType.EVENT_ERROR:
				print("An unknown error occur with an event...")
			ENetConnection.EventType.EVENT_RECEIVE:
				var packet: PackedByteArray = peer.get_packet()
				if is_server:
					var peer_id: int = peer.get_meta("id")
					on_server_packet.emit(peer_id, packet)
				else:
					on_client_packet.emit(packet)
		
		event = connection.service()
		event_type = event[0]

# Handles a client disconnecting from the server - adds their id back to the list
func on_client_disconnected(client_peer: ENetPacketPeer) -> void:
	var peer_id: int = client_peer.get_meta("id")
	connected_peers.erase(peer_id)
	available_ids.push_back(peer_id)
	on_peer_disconnected.emit(peer_id)
	print("Client disconnected with id: ", peer_id)

# Handles the client-side disconnect from a server, clearing the clients network connections
func disconnect_from_server() -> void:
	print("Successfully disconnected from server!")
	server_peer = null
	connection = null
	on_disconnect_from_server.emit()

# Handles a new client connecting to the server, assigning an id to the client
func on_client_connected(client_peer: ENetPacketPeer) -> void:
	var peer_id: int = available_ids.pop_back()
	connected_peers[peer_id] = client_peer
	client_peer.set_meta("id", peer_id)
	on_peer_connected.emit(peer_id)
	print("Client connected with id: ", peer_id)

# Handles the client side of connecting to the server
func connect_to_server() -> void:
	print("Successfully connected to server!")
	on_connect_to_server.emit()

# Creates a server for other ENetConnections to connect to
func start_server(ip_address: String = IP_ADDRESS, port: int = PORT) -> void:
	connection = ENetConnection.new()
	var error = connection.create_host_bound(ip_address, port, TOTAL_PLAYERS)
	if error != OK:
		connection = null
		printerr("Error when attempting to start server: ", error_string(error))
		return
	is_server = true

# Turns this instance of the game into the client
func start_client(ip_address: String = IP_ADDRESS, port: int = PORT) -> void:
	connection = ENetConnection.new()
	var error = connection.create_host(1)
	if error != OK:
		connection = null
		printerr("Error when attempting to start client: ", error_string(error))
		return
	server_peer = connection.connect_to_host(ip_address, port)
