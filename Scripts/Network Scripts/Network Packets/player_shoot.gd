class_name PlayerShoot extends Packet

var id: int
# Reliable but slow connection for shooting
const DEFAULT_PACKET_FLAG: int = ENetPacketPeer.FLAG_RELIABLE

# Constants for dictating how the packet is arranged
const ID_DATA_POSITION: int = 1
const ID_SIZE: int = 1

# Create the packet from parameters
static func create(id: int, packet_channel: int = 0, packet_flag: int = DEFAULT_PACKET_FLAG) -> PlayerShoot:
	var packet: PlayerShoot = PlayerShoot.new()
	packet.id = id
	packet.packet_channel = packet_channel
	packet.packet_flag = packet_flag
	packet.packet_type = PACKET_TYPE.PLAYER_SHOOT
	return packet

static func create_from_data(data: PackedByteArray, packet_channel: int = 0, packet_flag: int = DEFAULT_PACKET_FLAG) -> PlayerShoot:
	var packet: PlayerShoot = PlayerShoot.new()
	packet.decode(data)
	packet.packet_channel = packet_channel
	packet.packet_flag = packet_flag
	packet.packet_type = PACKET_TYPE.PLAYER_SHOOT
	return packet

func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	data.resize(data.size() + ID_SIZE)
	data.encode_u8(ID_DATA_POSITION, id)
	return data
	
func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u8(ID_DATA_POSITION)
	
