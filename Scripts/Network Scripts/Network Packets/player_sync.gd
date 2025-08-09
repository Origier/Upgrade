class_name PlayerSync extends Packet

var id: int
var position: Vector2
var rotation: float
var cannon_rotation: float

# Unreliable but faster as we will send one per frame
const DEFAULT_PACKET_FLAG: int = ENetPacketPeer.FLAG_UNSEQUENCED

# Constants for dictating how the packet is arranged
const ID_DATA_POSITION: int = 1
const ID_SIZE: int = 1
const X_DATA_POSITION: int = 2
const FLOAT_SIZE: int = 4
const Y_DATA_POSITION: int = X_DATA_POSITION + FLOAT_SIZE
const ROTATOIN_DATA_POSITION: int = Y_DATA_POSITION + FLOAT_SIZE
const CANNON_ROTATION_DATA_POSITION: int = ROTATOIN_DATA_POSITION + FLOAT_SIZE

static func create(id: int, position: Vector2, rotation: float, cannon_rotation: float, packet_channel: int = 0, packet_flag: int = DEFAULT_PACKET_FLAG) -> PlayerSync:
	var packet: PlayerSync = PlayerSync.new()
	packet.id = id
	packet.position = position
	packet.rotation = rotation
	packet.cannon_rotation = cannon_rotation
	packet.packet_channel = packet_channel
	packet.packet_flag = packet_flag
	packet.packet_type = PACKET_TYPE.PLAYER_SYNC
	return packet
	
static func create_from_data(data: PackedByteArray, packet_channel: int = 0, packet_flag: int = DEFAULT_PACKET_FLAG) -> PlayerSync:
	var packet: PlayerSync = PlayerSync.new()
	packet.decode(data)
	packet.packet_channel = packet_channel
	packet.packet_flag = packet_flag
	packet.packet_type = PACKET_TYPE.PLAYER_SYNC
	return packet

func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	data.resize(data.size() + ID_SIZE + FLOAT_SIZE * 4)
	data.encode_u8(ID_DATA_POSITION, id)
	data.encode_float(X_DATA_POSITION, position.x)
	data.encode_float(Y_DATA_POSITION, position.y)
	data.encode_float(ROTATOIN_DATA_POSITION, rotation)
	data.encode_float(CANNON_ROTATION_DATA_POSITION, cannon_rotation)
	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u8(ID_DATA_POSITION)
	position = Vector2(data.decode_float(X_DATA_POSITION), data.decode_float(Y_DATA_POSITION))
	rotation = data.decode_float(ROTATOIN_DATA_POSITION)
	cannon_rotation = data.decode_float(CANNON_ROTATION_DATA_POSITION)
