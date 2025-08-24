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
		SignalGlobals.CHANNEL.PLAYER_UPGRADE:
			var owner_id: int = arguments["owner_id"]
			if owner_id != ClientGlobals.id: return
			
			var upgrade: int = arguments["upgrade"]
			var started: bool = arguments["started"]
			var cooldown_completed: bool = arguments["cooldown_completed"]
			var hotkey_pressed: bool = arguments["hotkey_pressed"]
			match upgrade:
				# Toggles the display for which is the active cannon item
				Upgrade.CATEGORY.CANNON:
					var primary: bool = arguments["primary"]
					if primary:
					# Only toggles when the player clicks the hotkey
						if hotkey_pressed:
							$"Upgrade Slots/UpgradeSlot1/Slot1Highlight".visible = true
							$"Upgrade Slots/UpgradeSlot2/Slot2Highlight".visible = false
							
						if started:
							$"Upgrade Slots/UpgradeSlot1/Label".visible = false
							$"Upgrade Slots/UpgradeSlot1/CooldownRect".modulate = Color(0, 0, 0, 1)
							
						if cooldown_completed:
							$"Upgrade Slots/UpgradeSlot1/Label".visible = true
							$"Upgrade Slots/UpgradeSlot1/CooldownRect".modulate = Color(0, 0, 0, 0)
							
					else:
						if hotkey_pressed:
							$"Upgrade Slots/UpgradeSlot1/Slot1Highlight".visible = false
							$"Upgrade Slots/UpgradeSlot2/Slot2Highlight".visible = true
						
						if started:
							$"Upgrade Slots/UpgradeSlot2/Label".visible = false
							$"Upgrade Slots/UpgradeSlot2/CooldownRect".modulate = Color(0, 0, 0, 1)
							
						if cooldown_completed:
							$"Upgrade Slots/UpgradeSlot2/Label".visible = true
							$"Upgrade Slots/UpgradeSlot2/CooldownRect".modulate = Color(0, 0, 0, 0)
					
				Upgrade.CATEGORY.DEFENSE:
					if started:
						$"Upgrade Slots/UpgradeSlot3/Label".visible = false
						$"Upgrade Slots/UpgradeSlot3/CooldownRect".modulate = Color(0, 0, 0, 1)
					
					if cooldown_completed:
						$"Upgrade Slots/UpgradeSlot3/Label".visible = true
						$"Upgrade Slots/UpgradeSlot3/CooldownRect".modulate = Color(0, 0, 0, 0)
					
				Upgrade.CATEGORY.UTILITY:
					if started:
						$"Upgrade Slots/UpgradeSlot4/Label".visible = false
						$"Upgrade Slots/UpgradeSlot4/CooldownRect".modulate = Color(0, 0, 0, 1)
					
					if cooldown_completed:
						$"Upgrade Slots/UpgradeSlot4/Label".visible = true
						$"Upgrade Slots/UpgradeSlot4/CooldownRect".modulate = Color(0, 0, 0, 0)
					
		# Updates the current cooldown UI effect each frame
		SignalGlobals.CHANNEL.PLAYER_COOLDOWN_PERCENT:
			var owner_id: int = arguments["owner_id"]
			if owner_id != ClientGlobals.id: return
			
			var upgrade: int = arguments["upgrade"]
			var percent_cooldown: float = arguments["percent"]
			match upgrade:
				Upgrade.CATEGORY.CANNON:
					var primary = arguments["primary"]
					if (primary):
						$"Upgrade Slots/UpgradeSlot1/CooldownRect".modulate = Color(0, 0, 0, percent_cooldown)
					else:
						$"Upgrade Slots/UpgradeSlot2/CooldownRect".modulate = Color(0, 0, 0, percent_cooldown)
				Upgrade.CATEGORY.DEFENSE:
					$"Upgrade Slots/UpgradeSlot3/CooldownRect".modulate = Color(0, 0, 0, percent_cooldown)
				Upgrade.CATEGORY.UTILITY:
					$"Upgrade Slots/UpgradeSlot4/CooldownRect".modulate = Color(0, 0, 0, percent_cooldown)
					
# Update the health bar when the damage is recieved
func on_damage_recieved(damage: int) -> void:
	$PlayerHealthBar.value -= damage
