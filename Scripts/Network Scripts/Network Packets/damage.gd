class_name Damage extends Packet

var id: int
var damage: int

# Reliable but slow connection for sending damage
const DEFAULT_PACKET_FLAG: int = ENetPacketPeer.FLAG_RELIABLE

# Constants for dictating how the packet is arranged
const ID_DATA_POSITION: int = 1
const DAMAGE_DATA_POSITION: int = 2
const INT_SIZE: int = 1

# Create the packet from parameters
static func create(id: int, damage: int, packet_channel: int = 0, packet_flag: int = DEFAULT_PACKET_FLAG) -> Damage:
	var packet: Damage = Damage.new()
	packet.id = id
	packet.damage = damage
	packet.packet_channel = packet_channel
	packet.packet_flag = packet_flag
	packet.packet_type = PACKET_TYPE.DAMAGE
	return packet

static func create_from_data(data: PackedByteArray, packet_channel: int = 0, packet_flag: int = DEFAULT_PACKET_FLAG) -> Damage:
	var packet: Damage = Damage.new()
	packet.decode(data)
	packet.packet_channel = packet_channel
	packet.packet_flag = packet_flag
	packet.packet_type = PACKET_TYPE.DAMAGE
	return packet

func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	# The size is the current size, plus an ID size for the id, number of peers, and peers
	data.resize(data.size() + INT_SIZE * 2)
	data.encode_u8(ID_DATA_POSITION, id)
	data.encode_u8(DAMAGE_DATA_POSITION, damage)
	return data
	
func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u8(ID_DATA_POSITION)
	damage = data.decode_u8(DAMAGE_DATA_POSITION)
	
