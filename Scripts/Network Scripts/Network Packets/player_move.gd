class_name PlayerMove extends Packet

var id: int
var hotkey: int
var intensity: float
# Unreliable but will be sent each frame
const DEFAULT_PACKET_FLAG: int = ENetPacketPeer.FLAG_UNSEQUENCED

# Constants for dictating how the packet is arranged
const ID_DATA_POSITION: int = 1
const ID_SIZE: int = 1
const FLOAT_SIZE: int = 4
const HOTKEY_DATA_POSITION: int = 2
const INTENSITY_DATA_POSITION: int = 3

# Create the packet from parameters
static func create(id: int, hotkey: int, intensity: float, packet_channel: int = 0, packet_flag: int = DEFAULT_PACKET_FLAG) -> PlayerMove:
	var packet: PlayerMove = PlayerMove.new()
	packet.id = id
	packet.hotkey = hotkey
	packet.intensity = intensity
	packet.packet_channel = packet_channel
	packet.packet_flag = packet_flag
	packet.packet_type = PACKET_TYPE.PLAYER_MOVE
	return packet

static func create_from_data(data: PackedByteArray, packet_channel: int = 0, packet_flag: int = DEFAULT_PACKET_FLAG) -> PlayerMove:
	var packet: PlayerMove = PlayerMove.new()
	packet.decode(data)
	packet.packet_channel = packet_channel
	packet.packet_flag = packet_flag
	packet.packet_type = PACKET_TYPE.PLAYER_MOVE
	return packet

func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	data.resize(data.size() + (ID_SIZE * 2) + FLOAT_SIZE)
	data.encode_u8(ID_DATA_POSITION, id)
	data.encode_u8(HOTKEY_DATA_POSITION, hotkey)
	data.encode_float(INTENSITY_DATA_POSITION, intensity)
	return data
	
func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u8(ID_DATA_POSITION)
	hotkey = data.decode_u8(HOTKEY_DATA_POSITION)
	intensity = data.decode_float(INTENSITY_DATA_POSITION)
	
