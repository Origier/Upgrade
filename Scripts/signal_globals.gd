# This is a communications file that will listen for and dispatch signal information
extends Node

enum CHANNEL {
	PLAYER_SPAWN = 1,
	PLAYER_ABILITY = 2,
	PLAYER_COOLDOWN_PERCENT = 3
}

signal on_signal_send(channel: CHANNEL, arguments: Dictionary)

func send_signal(channel: CHANNEL, arguments: Dictionary) -> void:
	on_signal_send.emit(channel, arguments)
