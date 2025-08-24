extends Node

# The players current tier bracket - determines the level of potency on upgrades
var player_tier: int = 1

# Global identifiers for the upgrades in the system
enum UPGRADE_ID {
	BIG_BULLET = 1,
	ROCKET = 2,
	MACHINE_GUN = 3,
	DIGITAL_RIFLING = 4,
	SHRAPNEL_BULLETS = 5,
	MINE_LAUNCHER = 6,
	BLAST_BULLET = 7,
	DIGITAL_BULLET = 8,
	AIM_ASSIST = 9,
	IMPROVED_RELOADING = 10,
	SCATTER_SHOT = 11,
	INTERFERENCE_SHOT = 12,
	EMP_CONE = 13,
	DISPLACED_BULLETS = 14,
	CANNON_DISCHARGE = 15,
	CHARGE_BLAST = 16,
	GRENADE_LAUNCHER = 17,
	HEAT_SEEKING_ROCKET = 18,
	BOUNCY_BULLETS = 19,
	EXPLOSIVE_ROUNDS = 20,
	ENERGY_SHIELD = 21,
	CHARGED_CHASSIS = 22,
	CARBIDE_CHASSIS = 23,
	EXTRA_FUEL = 24,
	REPULSIVE_BLAST = 25,
	DIGITAL_BARRICADE = 26,
	NANO_DEFENSE_BOTS = 27,
	SHIELD_ZONES = 28,
	PEN_TESTING = 29,
	LIGHT_WARPING = 30,
	LIGHT_CORRECTION = 31,
	COUNTER_HACKING = 32,
	VISUAL_HACK = 33,
	DIGITAL_FORM = 34,
	CLOAKING_DEVICE = 35,
	SECOND_CHANCE = 36,
	NITROUS_OXIDE = 37,
	REPAIR_BOTS = 38,
	DOWNLOAD_RAM = 39,
	FAST_RECOVERY = 40,
	SCOUT_BOTS = 41,
	EMERGENCY_CHASSIS = 42,
	ESCAPE_PLAN = 43,
	RECLAIMED_AMMO = 44,
	DDOS_ATTACK = 45,
	TELEPORTATION = 46,
	REPAIR_BOTS_2_0 = 47,
	DISPLACE_BULLETS = 48,
	HACKED = 49,
	MAGNETIC_RIFLING = 50,
	EXTRA_GEARS = 51,
	LEVITATION = 52
}

# Constructing the bundle of information that is the upgrades
# Upgrade.create(id, scene, cooldown, potency, speed, duration, category, type)
var big_bullet: Upgrade = Upgrade.create(UPGRADE_ID.BIG_BULLET, load("res://Scenes/turret_bullet_basic.tscn"), 0.5, 10, 100, 0.0, Upgrade.CATEGORY.CANNON, Upgrade.TYPE.ACTIVE)
var rocket: Upgrade = Upgrade.create(UPGRADE_ID.ROCKET, load("res://Scenes/turret_rocket_basic.tscn"), 10, 40, 50, 0.0, Upgrade.CATEGORY.CANNON, Upgrade.TYPE.ACTIVE)
var energy_shield: Upgrade = Upgrade.create(UPGRADE_ID.ENERGY_SHIELD, load("res://Scenes/shield.tscn"), 15, 40, 0.0, 2, Upgrade.CATEGORY.DEFENSE, Upgrade.TYPE.ACTIVE)
var nitrous_oxide: Upgrade = Upgrade.create(UPGRADE_ID.NITROUS_OXIDE, null, 12, 25, 0.0, 3, Upgrade.CATEGORY.UTILITY, Upgrade.TYPE.ACTIVE)


# Global Handler for upgrades being activated on a player
func on_upgrade_activate(upgrade: Upgrade, player: CharacterBody2D) -> void:
	match upgrade.identifier:
		UPGRADE_ID.BIG_BULLET:
			pass
		UPGRADE_ID.ROCKET:
			pass
		UPGRADE_ID.ENERGY_SHIELD:
			activate_energy_shield(player)
			return
		UPGRADE_ID.NITROUS_OXIDE:
			activate_nitrous_oxide(player)
			return

func on_upgrade_deactivate(upgrade: Upgrade, player: CharacterBody2D) -> void:
	match upgrade.identifier:
		UPGRADE_ID.BIG_BULLET:
			pass
		UPGRADE_ID.ROCKET:
			pass
		UPGRADE_ID.ENERGY_SHIELD:
			deactivate_energy_shield(player)
			return
		UPGRADE_ID.NITROUS_OXIDE:
			deactivate_nitrous_oxide(player)
			return

# Upgrade activation

func activate_energy_shield(player: CharacterBody2D) -> void:
	var shield = player.player_defense_active.scene.instantiate()
	shield.owner_id = player.owner_id
	player.add_child(shield)

func activate_nitrous_oxide(player: CharacterBody2D) -> void:
	player.current_speed = player.current_speed * ((100 + player.player_utility_active.potency) / 100)


# Upgrade Deactivation

func deactivate_energy_shield(player: CharacterBody2D) -> void:
	var shield = player.get_node("Shield")
	if shield == null:
		return
	shield.queue_free()

func deactivate_nitrous_oxide(player: CharacterBody2D) -> void:
	player.current_speed = player.BASE_SPEED
