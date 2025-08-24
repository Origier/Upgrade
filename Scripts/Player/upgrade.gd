class_name Upgrade

enum CATEGORY {
	DEFENSE = 1,
	UTILITY = 2,
	CANNON = 3
}

enum TYPE {
	ACTIVE = 1,
	PASSIVE = 2
}

# Time in seconds to cooldown
var cooldown_time: float
var on_cooldown: bool = false
var potency: float
var speed: float
var duration: float

var category: CATEGORY
var type: TYPE
# Used to determine if one upgrade is the same as another
var identifier: int

var scene: PackedScene

static func create(identifier: int, scene: PackedScene, cooldown_time: float, potency: float, speed: float, duration: float, category: CATEGORY, type: TYPE) -> Upgrade:
	var upgrade: Upgrade = Upgrade.new()
	upgrade.identifier = identifier
	upgrade.scene = scene
	upgrade.cooldown_time = cooldown_time
	upgrade.potency = potency
	upgrade.speed = speed
	upgrade.duration = duration
	upgrade.category = category
	upgrade.type = type
	return upgrade

static func is_equal(upgrade1: Upgrade, upgrade2: Upgrade):
	return upgrade1.identifier == upgrade2.identifier

# Returns a deep copy of the Upgrade object
func duplicate() -> Upgrade:
	var upgrade: Upgrade = Upgrade.create(identifier, scene, cooldown_time, potency, speed, duration, category, type)
	return upgrade
