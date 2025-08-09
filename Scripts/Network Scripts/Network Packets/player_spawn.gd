class_name PlayerSpawn extends Packet

var id: int
var position: Vector2

# This will only be sent once per player - needs to be reliable
const DEFAULT_PACKET_FLAG: int = ENetPacketPeer.FLAG_RELIABLE

# Constants for dictating how the packet is arranged
const ID_DATA_POSITION: int = 1
const ID_SIZE: int = 1
const X_DATA_POSITION: int = 2
const FLOAT_SIZE: int = 4
const Y_DATA_POSITION: int = X_DATA_POSITION + FLOAT_SIZE


static func create(id: int, position: Vector2, packet_channel: int = 0, packet_flag: int = DEFAULT_PACKET_FLAG) -> PlayerSpawn:
	var packet: PlayerSpawn = PlayerSpawn.new()
	packet.id = id
	packet.position = position
	packet.packet_channel = packet_channel
	packet.packet_flag = packet_flag
	packet.packet_type = PACKET_TYPE.PLAYER_SPAWN
	return packet
	
static func create_from_data(data: PackedByteArray, packet_channel: int = 0, packet_flag: int = DEFAULT_PACKET_FLAG) -> PlayerSpawn:
	var packet: PlayerSpawn = PlayerSpawn.new()
	packet.decode(data)
	packet.packet_channel = packet_channel
	packet.packet_flag = packet_flag
	packet.packet_type = PACKET_TYPE.PLAYER_SPAWN
	return packet

func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	data.resize(data.size() + ID_SIZE + FLOAT_SIZE * 2)
	data.encode_u8(ID_DATA_POSITION, id)
	data.encode_float(X_DATA_POSITION, position.x)
	data.encode_float(Y_DATA_POSITION, position.y)
	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u8(ID_DATA_POSITION)
	position = Vector2(data.decode_float(X_DATA_POSITION), data.decode_float(Y_DATA_POSITION))
