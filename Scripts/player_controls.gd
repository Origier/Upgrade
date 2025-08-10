extends CharacterBody2D

@export var bullet_scene: PackedScene
@export var rocket_scene: PackedScene
@export var shield_scene: PackedScene

const BASE_SPEED: float = 300.0
const ROTATION_SPEED: float = 3

var current_speed: float = BASE_SPEED
var player_max_health: int = 100
var player_health: int = 100

enum PLAYER_HOTKEYS {
	DEFAULT = -1,
	HOTKEY_1 = 1,
	HOTKEY_2 = 2,
	HOTKEY_3 = 3,
	HOTKEY_4 = 4
}

# Construct basic player abilities
var player_cannon: Ability = Ability.create(0.5, 10, Ability.ABILITY_TYPE.CANNON)
var player_rocket: Ability = Ability.create(5, 50, Ability.ABILITY_TYPE.ROCKET)
var player_shield: Ability = Ability.create(10, 3, Ability.ABILITY_TYPE.SHIELD)
var player_speed: Ability = Ability.create(7, 300, Ability.ABILITY_TYPE.SPEED)

# Play style test - ability 1 & 2 are togglable, upon toggling it switches what is shot out of the cannon when the player left clicks
# Abilities 3 & 4 are instant activated and will be always accessible when not on cooldown
var player_activated_cannon: Ability = player_cannon

# Determines who can control the player
var owner_id: int

signal on_damage_recieved(damage: int)
signal bullet_fired

# Network connections for syncing
func _enter_tree() -> void:
	ServerGlobals.on_player_sync.connect(on_player_sync)
	ServerGlobals.on_player_shoot.connect(on_player_shoot)
	ServerGlobals.on_player_hotkey.connect(on_player_hotkey)
	
	ClientGlobals.on_player_sync.connect(on_player_sync)
	ClientGlobals.on_player_shoot.connect(on_player_shoot)
	ClientGlobals.on_player_take_damage.connect(on_player_take_damage)
	ClientGlobals.on_player_hotkey.connect(on_player_hotkey)
	
# Network connections for syncing	
func _exit_tree() -> void:
	ServerGlobals.on_player_sync.disconnect(on_player_sync)
	ServerGlobals.on_player_shoot.disconnect(on_player_shoot)
	ServerGlobals.on_player_hotkey.disconnect(on_player_hotkey)
	
	ClientGlobals.on_player_sync.disconnect(on_player_sync)
	ClientGlobals.on_player_shoot.disconnect(on_player_shoot)
	ClientGlobals.on_player_take_damage.disconnect(on_player_take_damage)
	ClientGlobals.on_player_hotkey.disconnect(on_player_hotkey)

func _ready() -> void:
	# Temporarily disable collision to spawn correctly
	$PlayerBodyCollider.disabled = true
	SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_SPAWN, {"player": self})
	$Ability1Timer.wait_time = player_cannon.cooldown_time
	$Ability2Timer.wait_time = player_rocket.cooldown_time
	$Ability3Timer.wait_time = player_shield.cooldown_time
	$Ability4Timer.wait_time = player_speed.cooldown_time

func _process(_delta: float) -> void:
	if player_cannon.on_cooldown:
		var percent: float = $Ability1Timer.time_left / $Ability1Timer.wait_time
		SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_COOLDOWN_PERCENT, {"ability": Ability.ABILITY_TYPE.CANNON, "percent": percent})
		
	if player_rocket.on_cooldown:
		var percent: float = $Ability2Timer.time_left / $Ability2Timer.wait_time
		SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_COOLDOWN_PERCENT, {"ability": Ability.ABILITY_TYPE.ROCKET, "percent": percent})
		
	if player_shield.on_cooldown:
		var percent: float = $Ability3Timer.time_left / $Ability3Timer.wait_time
		SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_COOLDOWN_PERCENT, {"ability": Ability.ABILITY_TYPE.SHIELD, "percent": percent})
		
	if player_speed.on_cooldown:
		var percent: float = $Ability4Timer.time_left / $Ability4Timer.wait_time
		SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_COOLDOWN_PERCENT, {"ability": Ability.ABILITY_TYPE.SPEED, "percent": percent})


func _physics_process(delta: float) -> void:
	if ClientGlobals.id != owner_id: return
	
	# Rotates the turret to face the direction of the players mouse
	var direction: Vector2 = get_global_mouse_position() - position
	$PlayerBody/PlayerTankGun.global_rotation = atan2(direction.y, direction.x) + deg_to_rad(90.0)
	
	var forward_magnitude: float = Input.get_axis("ui_down", "ui_up")
	var rotation_magnitude: float = Input.get_axis("ui_left", "ui_right")
	# Either rotate or move vertically - either movement will prevent the other from happening
	if rotation_magnitude != 0.0:
		velocity = Vector2.ZERO
		$PlayerBody.rotate(rotation_magnitude * ROTATION_SPEED * delta)
		$PlayerBodyCollider.rotate(rotation_magnitude * ROTATION_SPEED * delta)
	elif forward_magnitude != 0.0:
		velocity.x = (Vector2.UP.x * cos($PlayerBody.rotation) - Vector2.UP.y * sin($PlayerBody.rotation)) * current_speed * forward_magnitude
		velocity.y = (Vector2.UP.x * sin($PlayerBody.rotation) + Vector2.UP.y * cos($PlayerBody.rotation)) * current_speed * forward_magnitude
	else:
		velocity = Vector2.ZERO
	
	# Move and slide both the main body and player body
	move_and_slide()
	
	# Sync player data with the server
	PlayerSync.create(owner_id, global_position, $PlayerBody.global_rotation, $PlayerBody/PlayerTankGun.global_rotation).send(NetworkHandler.server_peer)
	
	# On left click, the player will shoot a out of the barrel of their turret
	# Send this action to the server to process
	if Input.is_action_just_pressed("shoot"):
		PlayerShoot.create(owner_id).send(NetworkHandler.server_peer)
	
	# Checking for hotbar button presses and sending them to the server
	var hotkey: PLAYER_HOTKEYS = PLAYER_HOTKEYS.DEFAULT
	if Input.is_action_just_pressed("Hotkey1"):
		hotkey = PLAYER_HOTKEYS.HOTKEY_1
	elif Input.is_action_just_pressed("Hotkey2"):
		hotkey = PLAYER_HOTKEYS.HOTKEY_2
	elif Input.is_action_just_pressed("Hotkey3"):
		hotkey = PLAYER_HOTKEYS.HOTKEY_3
	elif Input.is_action_just_pressed("Hotkey4"):
		hotkey = PLAYER_HOTKEYS.HOTKEY_4
	
	if hotkey != PLAYER_HOTKEYS.DEFAULT:
		PlayerHotkey.create(owner_id, hotkey).send(NetworkHandler.server_peer)
	
# Updates the players damage taken based on server packets
func on_player_take_damage(id: int, damage: int) -> void:
	if id != owner_id: return
	
	take_damage(damage)

# Updates this players position based on server packets syncing the position
func on_player_sync(id: int, position: Vector2, rotation: float, cannon_rotation: float) -> void:
	# Verify that this is the player that is supposed to move
	if owner_id != id: return
	# Verify that this player is not updating based on server broadcasts about its own location
	if ClientGlobals.id == id: return
	global_position = position
	$PlayerBody.global_rotation = rotation
	$PlayerBody/PlayerTankGun.global_rotation = cannon_rotation

# Fires a bullet out of this player character if they are responsible for shooting the bullet
func on_player_shoot(id: int) -> void:
	if id != owner_id: return
	spawn_bullet()

func on_player_hotkey(id: int, hotkey: int) -> void:
	if id != owner_id: return
	
	match hotkey:
		PLAYER_HOTKEYS.HOTKEY_1:
			player_activated_cannon = player_cannon
			SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_ABILITY, {"ability": Ability.ABILITY_TYPE.CANNON, "started": false, "cooldown_completed": false, "hotkey_pressed": true})
		PLAYER_HOTKEYS.HOTKEY_2:
			player_activated_cannon = player_rocket
			SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_ABILITY,  {"ability": Ability.ABILITY_TYPE.ROCKET, "started": false, "cooldown_completed": false, "hotkey_pressed": true})
		PLAYER_HOTKEYS.HOTKEY_3:
			if player_shield.on_cooldown: return
			SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_ABILITY, {"ability": Ability.ABILITY_TYPE.SHIELD, "started": true, "cooldown_completed": false, "hotkey_pressed": true})
			player_shield.on_cooldown = true
			$Ability3Timer.start()
			activate_shield()
		PLAYER_HOTKEYS.HOTKEY_4:
			if player_speed.on_cooldown: return
			SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_ABILITY, {"ability": Ability.ABILITY_TYPE.SPEED, "started": true, "cooldown_completed": false, "hotkey_pressed": true})
			player_speed.on_cooldown = true
			$Ability4Timer.start()
			activate_speed()
	
# Activates the players shield temporarily, allowing them to reflect bullets back at their enemy
func activate_shield() -> void:
	var shield = shield_scene.instantiate()
	shield.time_alive = player_shield.potency
	shield.owner_id = owner_id
	add_child(shield)

# Activates the players speed boost, allowing them to move faster during the duration of the timer
func activate_speed() -> void:
	current_speed += player_speed.potency
	$PlayerSpeedBoostTimer.start()
	
func spawn_bullet():
	var bullet
	# Create the bullet based on which bullet the player has chosen
	if player_activated_cannon == player_cannon:
		if player_cannon.on_cooldown: return
		SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_ABILITY, {"ability": Ability.ABILITY_TYPE.CANNON, "started": true, "cooldown_completed": false, "hotkey_pressed": false})
		player_cannon.on_cooldown = true
		$Ability1Timer.start()
		bullet = bullet_scene.instantiate()
	else:
		if player_rocket.on_cooldown: return
		SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_ABILITY, {"ability": Ability.ABILITY_TYPE.ROCKET, "started": true, "cooldown_completed": false, "hotkey_pressed": false})
		player_rocket.on_cooldown = true
		$Ability2Timer.start()
		bullet = rocket_scene.instantiate()
		
	# Set the damage of the bullet based on the potency of the ability
	bullet.damage = player_activated_cannon.potency
	
	bullet.global_position = $PlayerBody/PlayerTankGun/BulletSpawnPoint.global_position
	bullet.global_rotation = $PlayerBody/PlayerTankGun/BulletSpawnPoint.global_rotation
	bullet.owner_id = owner_id
	get_tree().get_root().add_child(bullet)

func take_damage(damage: int) -> void:
	player_health -= damage
	on_damage_recieved.emit(damage)
	if (player_health <= 0):
		queue_free()
	
func _on_collision_timer_timeout() -> void:
	$PlayerBodyCollider.disabled = false
	
	if ClientGlobals.id != owner_id:
		$HealthBar.visible = true

func _on_player_speed_boost_timer_timeout() -> void:
	current_speed -= player_speed.potency

func _on_ability_4_timer_timeout() -> void:
	player_speed.on_cooldown = false
	SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_ABILITY, {"ability": Ability.ABILITY_TYPE.SPEED, "started": false, "cooldown_completed": true, "hotkey_pressed": false})

func _on_ability_3_timer_timeout() -> void:
	player_shield.on_cooldown = false
	SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_ABILITY, {"ability": Ability.ABILITY_TYPE.SHIELD, "started": false, "cooldown_completed": true, "hotkey_pressed": false})

func _on_ability_2_timer_timeout() -> void:
	player_rocket.on_cooldown = false
	SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_ABILITY, {"ability": Ability.ABILITY_TYPE.ROCKET, "started": false, "cooldown_completed": true, "hotkey_pressed": false})

func _on_ability_1_timer_timeout() -> void:
	player_cannon.on_cooldown = false
	SignalGlobals.send_signal(SignalGlobals.CHANNEL.PLAYER_ABILITY, {"ability": Ability.ABILITY_TYPE.CANNON, "started": false, "cooldown_completed": true, "hotkey_pressed": false})
