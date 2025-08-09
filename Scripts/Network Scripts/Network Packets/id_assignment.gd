class_name IDAssignment extends Packet

var id: int
var peer_ids: Array
# Reliable but slow connection for ID's
const DEFAULT_PACKET_FLAG: int = ENetPacketPeer.FLAG_RELIABLE

# Constants for dictating how the packet is arranged
const ID_DATA_POSITION: int = 1
const PEER_COUNT_DATA_POSITION: int = 2
const PEER_ID_DATA_START_POSITION: int = 3
const ID_SIZE: int = 1

# Create the packet from parameters
static func create(id: int, peer_ids: Array, packet_channel: int = 0, packet_flag: int = DEFAULT_PACKET_FLAG) -> IDAssignment:
	var packet: IDAssignment = IDAssignment.new()
	packet.id = id
	packet.peer_ids = peer_ids
	packet.packet_channel = packet_channel
	packet.packet_flag = packet_flag
	packet.packet_type = PACKET_TYPE.ID_ASSIGNMENT
	return packet

static func create_from_data(data: PackedByteArray, packet_channel: int = 0, packet_flag: int = DEFAULT_PACKET_FLAG) -> IDAssignment:
	var packet: IDAssignment = IDAssignment.new()
	packet.decode(data)
	packet.packet_channel = packet_channel
	packet.packet_flag = packet_flag
	packet.packet_type = PACKET_TYPE.ID_ASSIGNMENT
	return packet

func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	# The size is the current size, plus an ID size for the id, number of peers, and peers
	data.resize(data.size() + ID_SIZE + ID_SIZE + ID_SIZE * peer_ids.size())
	data.encode_u8(ID_DATA_POSITION, id)
	data.encode_u8(PEER_COUNT_DATA_POSITION, peer_ids.size())
	var i: int = 0
	for peer in peer_ids:
		data.encode_u8(PEER_ID_DATA_START_POSITION + i, peer)
		i += 1
	return data
	
func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u8(ID_DATA_POSITION)
	var peers = data.decode_u8(PEER_COUNT_DATA_POSITION)
	for i in peers:
		peer_ids.append(data.decode_u8(PEER_ID_DATA_START_POSITION + i))
	
