extends CharacterBody2D

const BASE_SPEED: float = 300.0
const ROTATION_SPEED: float = 3

var modified_base_speed: float = BASE_SPEED
var current_speed: float = modified_base_speed
var player_max_health: int = 100
var player_health: int = 100

enum PLAYER_HOTKEYS {
	DEFAULT = -1,
	HOTKEY_WEAPON_TOGGLE = 1,
	HOTKEY_DEFENSE = 2,
	HOTKEY_UTILITY = 3,
	MOVE_FORWARD = 4,
	ROTATE = 5
}

# Flags and variables for determining movement occuring on the player
var rotation_flag: bool = false
var rotation_intensity: float = 0.0
var move_flag: bool = false
var move_intensity: float = 0.0
var next_cannon_rotation: float = 0.0

# Player Upgrade Slots
var player_cannon_primary: Upgrade = UpgradeGlobals.big_bullet.duplicate()
var player_cannon_secondary: Upgrade = UpgradeGlobals.rocket.duplicate()
var player_cannon_passive: Upgrade = UpgradeGlobals.shrapnel_bullets.duplicate()

var player_defense_active: Upgrade = UpgradeGlobals.energy_shield.duplicate()
var player_defense_passive: Upgrade = UpgradeGlobals.carbide_chassis.duplicate()

var player_utility_active: Upgrade = UpgradeGlobals.nitrous_oxide.duplicate()
var player_utility_passive: Upgrade = UpgradeGlobals.download_ram.duplicate()

# Dictates what fires when the player presses left click
var player_activated_cannon: Upgrade = player_cannon_primary

# Upgrade modifiers
var damage_reduction: float = 0.0
var projectile_damage_modifier: float = 0.0
var projectile_speed_modifier: float = 0.0


# Determines who can control the player
var owner_id: int

signal on_damage_recieved(damage: int)
signal bullet_fired

# Network connections for syncing
func _enter_tree() -> void:
	ServerGlobals.on_player_sync.connect(on_player_sync)
	ServerGlobals.on_player_shoot.connect(on_player_shoot)
	ServerGlobals.on_player_hotkey.connect(on_player_hotkey)
	ServerGlobals.on_player_move.connect(on_player_move)
	ServerGlobals.on_player_mouse.connect(on_player_mouse)
	
	ClientGlobals.on_player_sync.connect(on_player_sync)
	ClientGlobals.on_player_shoot.connect(on_player_shoot)
	ClientGlobals.on_player_take_damage.connect(on_player_take_damage)
	ClientGlobals.on_player_hotkey.connect(on_player_hotkey)
	
# Network connections for syncing
func _exit_tree() -> void:
	ServerGlobals.on_player_sync.disconnect(on_player_sync)
	ServerGlobals.on_player_shoot.disconnect(on_player_shoot)
	ServerGlobals.on_player_hotkey.disconnect(on_player_hotkey)
	ServerGlobals.on_player_move.disconnect(on_player_move)
	ServerGlobals.on_player_mouse.disconnect(on_player_mouse)
	
	ClientGlobals.on_player_sync.disconnect(on_player_sync)
	ClientGlobals.on_player_shoot.disconnect(on_player_shoot)
	ClientGlobals.on_player_take_damage.disconnect(on_player_take_damage)
	ClientGlobals.on_player_hotkey.disconnect(on_player_hotkey)

func _ready() -> void:
	# Temporarily disable collision to spawn correctly
	$PlayerBodyCollider.disabled = true
	SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_SPAWN, {"player": self})
	$CannonPrimaryCooldown.wait_time = player_cannon_primary.cooldown_time
	$CannonSecondaryCooldown.wait_time = player_cannon_secondary.cooldown_time
	$DefenseCooldown.wait_time = player_defense_active.cooldown_time
	$UtilityCooldown.wait_time = player_utility_active.cooldown_time
	if player_cannon_primary.duration > 0:
		$CannonPrimaryDuration.wait_time = player_cannon_primary.duration
	if player_cannon_secondary.duration > 0:
		$CannonSecondaryDuration.wait_time = player_cannon_secondary.duration
	if player_defense_active.duration > 0:
		$DefenseDuration.wait_time = player_defense_active.duration
	if player_utility_active.duration > 0:
		$UtilityDuration.wait_time = player_utility_active.duration
	
	# Apply the passive upgrades
	if player_cannon_passive != null:
		UpgradeGlobals.on_upgrade_activate(player_cannon_passive, self)
	
	if player_defense_passive != null:
		UpgradeGlobals.on_upgrade_activate(player_defense_passive, self)
	
	if player_utility_passive != null:
		UpgradeGlobals.on_upgrade_activate(player_utility_passive, self)
	
	# Apply modifiers to upgrades
	player_cannon_primary.potency += ceil(player_cannon_primary.potency * (projectile_damage_modifier / 100))
	player_cannon_secondary.potency += ceil(player_cannon_secondary.potency * (projectile_damage_modifier / 100))
	player_cannon_primary.speed += ceil(player_cannon_primary.speed * (projectile_speed_modifier / 100))
	player_cannon_secondary.speed += ceil(player_cannon_secondary.speed * (projectile_speed_modifier / 100))


# Called to process client side items such as ui updates and inputs
func _process(_delta: float) -> void:
	if ClientGlobals.id != owner_id: return
	update_cooldowns()
	update_movement_input()
	update_mouse_input()
	update_hotkey_input()


# Called to move the object - this is done server side to ensure the object is moving without cheats
func _physics_process(delta: float) -> void:
	if not NetworkHandler.is_server: return
	
	# Rotate the cannon to the next rotation it is expected at based on client mouse input
	$PlayerBody/PlayerTankGun.global_rotation = next_cannon_rotation
	# Either rotate or move vertically - either movement will prevent the other from happening
	if rotation_flag:
		velocity = Vector2.ZERO
		$PlayerBody.rotate(rotation_intensity * ROTATION_SPEED * delta)
		$PlayerBodyCollider.rotate(rotation_intensity * ROTATION_SPEED * delta)
	elif move_flag:
		velocity.x = (Vector2.UP.x * cos($PlayerBody.rotation) - Vector2.UP.y * sin($PlayerBody.rotation)) * current_speed * move_intensity
		velocity.y = (Vector2.UP.x * sin($PlayerBody.rotation) + Vector2.UP.y * cos($PlayerBody.rotation)) * current_speed * move_intensity
	else:
		velocity = Vector2.ZERO
	
	# Move and slide both the main body and player body
	move_and_slide()
	
	# Sync player data across the server
	PlayerSync.create(owner_id, global_position, $PlayerBody.global_rotation, $PlayerBody/PlayerTankGun.global_rotation).broadcast(NetworkHandler.connection)
	
	
# Updates the players damage taken based on server packets
func on_player_take_damage(id: int, damage: int) -> void:
	if id != owner_id: return
	
	take_damage(damage)

# Updates this players position based on server packets syncing the position
func on_player_sync(id: int, position: Vector2, rotation: float, cannon_rotation: float) -> void:
	# Verify that this is the player that is supposed to move
	if owner_id != id: return
	global_position = position
	$PlayerBody.global_rotation = rotation
	$PlayerBody/PlayerTankGun.global_rotation = cannon_rotation


# Fires a bullet out of this player character if they are responsible for shooting the bullet
func on_player_shoot(id: int) -> void:
	if id != owner_id: return
	spawn_bullet()


# When a player presses a hotkey, it will first travel to the server for validation and then come here
# to activate the relevant upgrade
func on_player_hotkey(id: int, hotkey: int) -> void:
	if id != owner_id: return
	match hotkey:
		# Toggles the active weapon on the cannon
		PLAYER_HOTKEYS.HOTKEY_WEAPON_TOGGLE:
			if Upgrade.is_equal(player_activated_cannon, player_cannon_secondary):
				player_activated_cannon = player_cannon_primary
				SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_UPGRADE, {"owner_id": owner_id, "upgrade": Upgrade.CATEGORY.CANNON, "primary": true, "started": false, "cooldown_completed": false, "hotkey_pressed": true})
			else:
				player_activated_cannon = player_cannon_secondary
				SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_UPGRADE,  {"owner_id": owner_id, "upgrade": Upgrade.CATEGORY.CANNON, "primary": false, "started": false, "cooldown_completed": false, "hotkey_pressed": true})
		PLAYER_HOTKEYS.HOTKEY_DEFENSE:
			if player_defense_active.on_cooldown: return
			SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_UPGRADE, {"owner_id": owner_id, "upgrade": Upgrade.CATEGORY.DEFENSE, "started": true, "cooldown_completed": false, "hotkey_pressed": true})
			player_defense_active.on_cooldown = true
			$DefenseCooldown.start()
			$DefenseDuration.start()
			UpgradeGlobals.on_upgrade_activate(player_defense_active, self)
		PLAYER_HOTKEYS.HOTKEY_UTILITY:
			if player_utility_active.on_cooldown: return
			SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_UPGRADE, {"owner_id": owner_id, "upgrade": Upgrade.CATEGORY.UTILITY, "started": true, "cooldown_completed": false, "hotkey_pressed": true})
			player_utility_active.on_cooldown = true
			$UtilityCooldown.start()
			$UtilityDuration.start()
			UpgradeGlobals.on_upgrade_activate(player_utility_active, self)


# Upon recieving the packet from the client - update the relevant flags to start moving the player in the process frames
func on_player_move(id: int, hotkey: int, intensity: float) -> void:
	if owner_id != id: return
	
	if hotkey == PLAYER_HOTKEYS.ROTATE:
		move_flag = false
		rotation_flag = true
		rotation_intensity = intensity
	elif hotkey == PLAYER_HOTKEYS.MOVE_FORWARD:
		move_flag = true
		rotation_flag = false
		move_intensity = intensity
	

# Server side - when recieving the packet from the player, rotate the turret to match where the player is pointing
func on_player_mouse(id: int, mouse_position: Vector2) -> void:
	if id != owner_id: return
	# Rotates the turret to face the direction of the players mouse
	var direction: Vector2 = mouse_position - position
	next_cannon_rotation = atan2(direction.y, direction.x) + deg_to_rad(90.0)
	

# Client side updating the ui for the cooldowns
func update_cooldowns() -> void:
	if player_cannon_primary.on_cooldown:
		var percent: float = $CannonPrimaryCooldown.time_left / $CannonPrimaryCooldown.wait_time
		SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_COOLDOWN_PERCENT, {"owner_id": owner_id, "upgrade": Upgrade.CATEGORY.CANNON, "primary": true, "percent": percent})
		
	if player_cannon_secondary.on_cooldown:
		var percent: float = $CannonSecondaryCooldown.time_left / $CannonSecondaryCooldown.wait_time
		SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_COOLDOWN_PERCENT, {"owner_id": owner_id, "upgrade": Upgrade.CATEGORY.CANNON, "primary": false, "percent": percent})
		
	if player_defense_active.on_cooldown:
		var percent: float = $DefenseCooldown.time_left / $DefenseCooldown.wait_time
		SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_COOLDOWN_PERCENT, {"owner_id": owner_id, "upgrade": Upgrade.CATEGORY.DEFENSE, "percent": percent})
		
	if player_utility_active.on_cooldown:
		var percent: float = $UtilityCooldown.time_left / $UtilityCooldown.wait_time
		SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_COOLDOWN_PERCENT, {"owner_id": owner_id, "upgrade": Upgrade.CATEGORY.UTILITY, "percent": percent})


# Tracks input for movement actions, sends those inputs to the server for validation
# The server will perform the movement on its version of the entity and then send a sync packet to update
func update_movement_input() -> void:
	var forward_magnitude: float = Input.get_axis("move_backward", "move_forward")
	var rotation_magnitude: float = Input.get_axis("rotate_left", "rotate_right")
	# Either rotate or move vertically - either movement will prevent the other from happening
	if rotation_magnitude != 0.0:
		PlayerMove.create(owner_id, PLAYER_HOTKEYS.ROTATE, rotation_magnitude).send(NetworkHandler.server_peer)
	else:
		PlayerMove.create(owner_id, PLAYER_HOTKEYS.MOVE_FORWARD, forward_magnitude).send(NetworkHandler.server_peer)


# Captures client side mouse input for shooting and rotating the turret
func update_mouse_input() -> void:
	PlayerMouse.create(owner_id, get_global_mouse_position()).send(NetworkHandler.server_peer)
	# On left click, the player will shoot a out of the barrel of their turret
	# Send this action to the server to process
	if Input.is_action_just_pressed("shoot"):
		PlayerShoot.create(owner_id).send(NetworkHandler.server_peer)


# Checking for hotbar button presses and sending them to the server for validation
func update_hotkey_input() -> void:
	var hotkey: PLAYER_HOTKEYS = PLAYER_HOTKEYS.DEFAULT
	if Input.is_action_just_pressed(ClientConfig.WEAPON_TOGGLE_ACTION):
		hotkey = PLAYER_HOTKEYS.HOTKEY_WEAPON_TOGGLE
	elif Input.is_action_just_pressed(ClientConfig.SHIELD_ACTION):
		hotkey = PLAYER_HOTKEYS.HOTKEY_DEFENSE
	elif Input.is_action_just_pressed(ClientConfig.SPEED_ACTION):
		hotkey = PLAYER_HOTKEYS.HOTKEY_UTILITY
	
	if hotkey != PLAYER_HOTKEYS.DEFAULT:
		PlayerHotkey.create(owner_id, hotkey).send(NetworkHandler.server_peer)


func spawn_bullet():
	var bullet
	# Create the bullet based on which bullet the player has chosen
	if Upgrade.is_equal(player_activated_cannon, player_cannon_primary):
		if player_cannon_primary.on_cooldown: return
		# Update UI for cooldown
		SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_UPGRADE, {"owner_id": owner_id, "upgrade": Upgrade.CATEGORY.CANNON, "primary": true, "started": true, "cooldown_completed": false, "hotkey_pressed": false})
		# Start the cooldown process
		player_cannon_primary.on_cooldown = true
		$CannonPrimaryCooldown.start()
		bullet = player_cannon_primary.scene.instantiate()
	else:
		if player_cannon_secondary.on_cooldown: return
		# Update UI for cooldown
		SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_UPGRADE, {"owner_id": owner_id, "upgrade": Upgrade.CATEGORY.CANNON, "primary": false, "started": true, "cooldown_completed": false, "hotkey_pressed": false})
		# Start the cooldown process
		player_cannon_secondary.on_cooldown = true
		$CannonSecondaryCooldown.start()
		bullet = player_cannon_secondary.scene.instantiate()
		
	# Set the damage of the bullet based on the potency of the upgrade
	bullet.damage = player_activated_cannon.potency
	bullet.global_position = $PlayerBody/PlayerTankGun/BulletSpawnPoint.global_position
	bullet.global_rotation = $PlayerBody/PlayerTankGun/BulletSpawnPoint.global_rotation
	bullet.owner_id = owner_id
	get_tree().get_root().add_child(bullet)


func take_damage(damage: float) -> void:
	var damage_recieved: int = floor(damage - (damage * (damage_reduction / 100)))
	player_health -= damage_recieved
	on_damage_recieved.emit(damage_recieved)
	if (player_health <= 0):
		queue_free()
	

func _on_collision_timer_timeout() -> void:
	$PlayerBodyCollider.disabled = false
	
	if ClientGlobals.id != owner_id:
		$HealthBar.visible = true

	
func _on_cannon_primary_cooldown_timeout() -> void:
	player_cannon_primary.on_cooldown = false
	SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_UPGRADE, {"owner_id": owner_id, "upgrade": Upgrade.CATEGORY.CANNON, "primary": true, "started": false, "cooldown_completed": true, "hotkey_pressed": false})


func _on_cannon_secondary_cooldown_timeout() -> void:
	player_cannon_secondary.on_cooldown = false
	SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_UPGRADE, {"owner_id": owner_id, "upgrade": Upgrade.CATEGORY.CANNON, "primary": false, "started": false, "cooldown_completed": true, "hotkey_pressed": false})
	

func _on_defense_cooldown_timeout() -> void:
	player_defense_active.on_cooldown = false
	SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_UPGRADE, {"owner_id": owner_id, "upgrade": Upgrade.CATEGORY.DEFENSE, "started": false, "cooldown_completed": true, "hotkey_pressed": false})


func _on_utility_cooldown_timeout() -> void:
	player_utility_active.on_cooldown = false
	SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_UPGRADE, {"owner_id": owner_id, "upgrade": Upgrade.CATEGORY.UTILITY, "started": false, "cooldown_completed": true, "hotkey_pressed": false})


func _on_defense_duration_timeout() -> void:
	UpgradeGlobals.on_upgrade_deactivate(player_defense_active, self)


func _on_utility_duration_timeout() -> void:
	UpgradeGlobals.on_upgrade_deactivate(player_utility_active, self)
