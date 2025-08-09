extends Area2D

@export var speed: float = 1000
@export var damage: int = 10
var owner_id: int

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move_local_y(-speed * delta)


func _on_body_entered(body: Node2D) -> void:
	if (body is not CharacterBody2D): 
		remove_bullet()
		return
	
	# Bullet was created by this body
	if (owner_id == body.owner_id): return
	
	# Server validates the collision and distributes the damage
	if NetworkHandler.is_server:
		body.take_damage(damage)
		Damage.create(body.owner_id, damage).broadcast(NetworkHandler.connection)
	# Remove bullet client side to ensure removal
	remove_bullet()


func remove_bullet():
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	var area_groups: Array = area.get_groups()
	# Detecting if the body is a shield object
	for group in area_groups:
		# If this hits a shield and it isn't the owner, flip the bullet and claim ownership
		if group == "Shield":
			if area.owner_id != owner_id:
				rotate(PI)
				owner_id = area.owner_id
			return
