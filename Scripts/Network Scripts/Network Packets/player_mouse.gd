class_name PlayerMouse extends Packet

var id: int
var mouse_position: Vector2
# Unreliable but will be sent each frame
const DEFAULT_PACKET_FLAG: int = ENetPacketPeer.FLAG_UNSEQUENCED

# Constants for dictating how the packet is arranged
const ID_DATA_POSITION: int = 1
const ID_SIZE: int = 1
const FLOAT_SIZE: int = 4
const X_DATA_POSITION: int = 2
const Y_DATA_POSITION: int = 6

# Create the packet from parameters
static func create(id: int, mouse_position: Vector2, packet_channel: int = 0, packet_flag: int = DEFAULT_PACKET_FLAG) -> PlayerMouse:
	var packet: PlayerMouse = PlayerMouse.new()
	packet.id = id
	packet.mouse_position = mouse_position
	packet.packet_channel = packet_channel
	packet.packet_flag = packet_flag
	packet.packet_type = PACKET_TYPE.PLAYER_MOUSE
	return packet

static func create_from_data(data: PackedByteArray, packet_channel: int = 0, packet_flag: int = DEFAULT_PACKET_FLAG) -> PlayerMouse:
	var packet: PlayerMouse = PlayerMouse.new()
	packet.decode(data)
	packet.packet_channel = packet_channel
	packet.packet_flag = packet_flag
	packet.packet_type = PACKET_TYPE.PLAYER_MOUSE
	return packet

func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	data.resize(data.size() + ID_SIZE + FLOAT_SIZE * 2)
	data.encode_u8(ID_DATA_POSITION, id)
	data.encode_float(X_DATA_POSITION, mouse_position.x)
	data.encode_float(Y_DATA_POSITION, mouse_position.y)
	return data
	
func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u8(ID_DATA_POSITION)
	mouse_position = Vector2(data.decode_float(X_DATA_POSITION), data.decode_float(Y_DATA_POSITION))
