# Base class to be used for other packets
class_name Packet

enum PACKET_TYPE {
	ID_ASSIGNMENT = 0,
	PLAYER_SHOOT = 1,
	PLAYER_SYNC = 2,
	DAMAGE = 3,
	PLAYER_SPAWN = 4,
	PLAYER_HOTKEY = 5,
	PLAYER_MOVE = 6,
	PLAYER_MOUSE = 7
}

var packet_type: PACKET_TYPE
var packet_flag: int
var packet_channel: int
# Position in the packet to find the packet type
const TYPE_POSITION: int = 0
# The number of bytes for the size of the type
const TYPE_SIZE: int = 1

# Encodes the packets information into a packed byte array
func encode() -> PackedByteArray:
	var data: PackedByteArray
	data.resize(TYPE_SIZE)
	data.encode_u8(TYPE_POSITION, packet_type)
	return data

# Decodes the packed byte array into the relevant packet information 
func decode(data: PackedByteArray) -> void:
	packet_type = data.decode_u8(TYPE_POSITION)

# Sends the packet to the peer
func send(peer: ENetPacketPeer) -> void:
	peer.send(packet_channel, encode(), packet_flag)

# Broadcasts the packet across the server
func broadcast(server: ENetConnection) -> void:
	server.broadcast(packet_channel, encode(), packet_flag)
