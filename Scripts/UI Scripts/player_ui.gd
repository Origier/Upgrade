extends Control

var player: CharacterBody2D

# Connect signals for the player being created
func _enter_tree() -> void:
	SignalGlobals.on_signal_send.connect(on_signal_recieved)


func on_signal_recieved(channel: SignalGlobals.CHANNEL, arguments: Dictionary) -> void:
	match channel:
		SignalGlobals.CHANNEL.PLAYER_SPAWN:
			var new_player = arguments["player"]
			if new_player.owner_id == ClientGlobals.id:
				visible = true
				player = new_player
				$PlayerHealthBar.value = player.player_health
				player.on_damage_recieved.connect(on_damage_recieved)
		
		# Switches the UI selection effect or starts the cooldown effect
		SignalGlobals.CHANNEL.PLAYER_ABILITY:
			var owner_id: int = arguments["owner_id"]
			if owner_id != ClientGlobals.id: return
			
			var ability: int = arguments["ability"]
			var started: bool = arguments["started"]
			var cooldown_completed: bool = arguments["cooldown_completed"]
			var hotkey_pressed: bool = arguments["hotkey_pressed"]
			match ability:
				# Toggles the display for which is the active cannon item
				Ability.ABILITY_TYPE.CANNON_PRIMARY:
					# Only toggles when the player clicks the hotkey
					if hotkey_pressed:
						$"Ability Slots/AbilitySlot1/Slot1Highlight".visible = true
						$"Ability Slots/AbilitySlot2/Slot2Highlight".visible = false
						
					if started:
						$"Ability Slots/AbilitySlot1/Label".visible = false
						$"Ability Slots/AbilitySlot1/CooldownRect".modulate = Color(0, 0, 0, 1)
						
					if cooldown_completed:
						$"Ability Slots/AbilitySlot1/Label".visible = true
						$"Ability Slots/AbilitySlot1/CooldownRect".modulate = Color(0, 0, 0, 0)
					
				Ability.ABILITY_TYPE.CANNON_SECONDARY:
					if hotkey_pressed:
						$"Ability Slots/AbilitySlot1/Slot1Highlight".visible = false
						$"Ability Slots/AbilitySlot2/Slot2Highlight".visible = true
						
					if started:
						$"Ability Slots/AbilitySlot2/Label".visible = false
						$"Ability Slots/AbilitySlot2/CooldownRect".modulate = Color(0, 0, 0, 1)
					
					if cooldown_completed:
						$"Ability Slots/AbilitySlot2/Label".visible = true
						$"Ability Slots/AbilitySlot2/CooldownRect".modulate = Color(0, 0, 0, 0)
					
				Ability.ABILITY_TYPE.DEFENSE:
					if started:
						$"Ability Slots/AbilitySlot3/Label".visible = false
						$"Ability Slots/AbilitySlot3/CooldownRect".modulate = Color(0, 0, 0, 1)
					
					if cooldown_completed:
						$"Ability Slots/AbilitySlot3/Label".visible = true
						$"Ability Slots/AbilitySlot3/CooldownRect".modulate = Color(0, 0, 0, 0)
					
				Ability.ABILITY_TYPE.UTILITY:
					if started:
						$"Ability Slots/AbilitySlot4/Label".visible = false
						$"Ability Slots/AbilitySlot4/CooldownRect".modulate = Color(0, 0, 0, 1)
					
					if cooldown_completed:
						$"Ability Slots/AbilitySlot4/Label".visible = true
						$"Ability Slots/AbilitySlot4/CooldownRect".modulate = Color(0, 0, 0, 0)
					
		# Updates the current cooldown UI effect each frame
		SignalGlobals.CHANNEL.PLAYER_COOLDOWN_PERCENT:
			var owner_id: int = arguments["owner_id"]
			if owner_id != ClientGlobals.id: return
			
			var ability: int = arguments["ability"]
			var percent_cooldown: float = arguments["percent"]
			match ability:
				Ability.ABILITY_TYPE.CANNON_PRIMARY:
					$"Ability Slots/AbilitySlot1/CooldownRect".modulate = Color(0, 0, 0, percent_cooldown)
				Ability.ABILITY_TYPE.CANNON_SECONDARY:
					$"Ability Slots/AbilitySlot2/CooldownRect".modulate = Color(0, 0, 0, percent_cooldown)
				Ability.ABILITY_TYPE.DEFENSE:
					$"Ability Slots/AbilitySlot3/CooldownRect".modulate = Color(0, 0, 0, percent_cooldown)
				Ability.ABILITY_TYPE.UTILITY:
					$"Ability Slots/AbilitySlot4/CooldownRect".modulate = Color(0, 0, 0, percent_cooldown)
					
# Update the health bar when the damage is recieved
func on_damage_recieved(damage: int) -> void:
	$PlayerHealthBar.value -= damage
