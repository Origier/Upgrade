class_name PlayerHotkey extends Packet

var id: int
var hotkey: int
# Reliable but slow connection for choices being made
const DEFAULT_PACKET_FLAG: int = ENetPacketPeer.FLAG_RELIABLE

# Constants for dictating how the packet is arranged
const ID_DATA_POSITION: int = 1
const ID_SIZE: int = 1
const HOTKEY_DATA_POSITION: int = 2

# Create the packet from parameters
static func create(id: int, hotkey: int, packet_channel: int = 0, packet_flag: int = DEFAULT_PACKET_FLAG) -> PlayerHotkey:
	var packet: PlayerHotkey = PlayerHotkey.new()
	packet.id = id
	packet.hotkey = hotkey
	packet.packet_channel = packet_channel
	packet.packet_flag = packet_flag
	packet.packet_type = PACKET_TYPE.PLAYER_HOTKEY
	return packet

static func create_from_data(data: PackedByteArray, packet_channel: int = 0, packet_flag: int = DEFAULT_PACKET_FLAG) -> PlayerHotkey:
	var packet: PlayerHotkey = PlayerHotkey.new()
	packet.decode(data)
	packet.packet_channel = packet_channel
	packet.packet_flag = packet_flag
	packet.packet_type = PACKET_TYPE.PLAYER_HOTKEY
	return packet

func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	data.resize(data.size() + ID_SIZE * 2)
	data.encode_u8(ID_DATA_POSITION, id)
	data.encode_u8(HOTKEY_DATA_POSITION, hotkey)
	return data
	
func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u8(ID_DATA_POSITION)
	hotkey = data.decode_u8(HOTKEY_DATA_POSITION)
	
