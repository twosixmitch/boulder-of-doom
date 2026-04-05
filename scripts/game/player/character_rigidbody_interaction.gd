class_name CharacterRigidBodyInteraction
extends RefCounted

## Ported from LesusX / YouTube Character–RigidBody interaction tutorial:
## https://github.com/LesusX/YouTube/blob/main/Character_RigidBody_Interaction/third_person_controller.gd
## Adapted for Godot 4.x (apply_impulse position in global space, slide collision iteration).

static func stabilize_body_under_shapecast(ground_check: ShapeCast3D) -> void:
	if ground_check == null or not ground_check.is_colliding():
		return
	var collider := ground_check.get_collider(0)
	if collider is RigidBody3D:
		(collider as RigidBody3D).linear_velocity = Vector3.ZERO


static func push_rigid_body(character: CharacterBody3D, player_strength: float) -> void:
	for i in range(character.get_slide_collision_count()):
		var col := character.get_slide_collision(i)
		if col == null:
			continue
		var col_collider := col.get_collider()
		if not (col_collider is RigidBody3D):
			continue
		var rb := col_collider as RigidBody3D
		var col_position := col.get_position()
		var body_mass := rb.mass
		var all_connected_bodies := get_all_connected_bodies(rb, character)
		var friction := calculate_friction(all_connected_bodies)

		var total_mass := 0.0
		for body in all_connected_bodies:
			total_mass += body.mass

		var free_sides := {
			"LEFT": true,
			"RIGHT": true,
			"FRONT": true,
			"BACK": true,
			"TOP": true,
			"BOTTOM": false,
		}

		for connected_body in all_connected_bodies:
			if connected_body == rb:
				continue

			var connected_local_pos := rb.to_local(connected_body.global_position)

			if absf(connected_local_pos.x) > absf(connected_local_pos.z):
				if connected_local_pos.x < 0:
					free_sides["LEFT"] = false
				else:
					free_sides["RIGHT"] = false
			elif absf(connected_local_pos.z) > absf(connected_local_pos.x):
				if connected_local_pos.z < 0:
					free_sides["FRONT"] = false
				else:
					free_sides["BACK"] = false
			if absf(connected_local_pos.y) > maxf(absf(connected_local_pos.x), absf(connected_local_pos.z)):
				if connected_local_pos.y > 0:
					free_sides["TOP"] = false
				else:
					free_sides["BOTTOM"] = false

		if free_sides["LEFT"] and free_sides["RIGHT"] and free_sides["FRONT"] and free_sides["BACK"] and free_sides["TOP"]:
			total_mass = body_mass
			friction = 0.0

		var stacked_weight := 0.0
		for connected_body in all_connected_bodies:
			if connected_body.global_position.y > rb.global_position.y:
				stacked_weight += connected_body.mass
		var effective_mass := total_mass + stacked_weight

		var strength_multiplier := 1.4
		if total_mass < 25.0:
			strength_multiplier = lerpf(1.5, 1.8, (25.0 - total_mass) / 25.0)
		elif total_mass < 50.0:
			strength_multiplier = lerpf(1.8, 1.5, (total_mass - 25.0) / 25.0)

		if total_mass > player_strength:
			var restricted_sides: Array[String] = []
			var opposite_sides := {
				"LEFT": "RIGHT",
				"RIGHT": "LEFT",
				"FRONT": "BACK",
				"BACK": "FRONT",
				"TOP": "BOTTOM",
				"BOTTOM": "TOP",
			}

			for connected_body in all_connected_bodies:
				if connected_body == rb:
					continue
				var connected_local_pos := rb.to_local(connected_body.global_position)
				var connected_side := ""
				if absf(connected_local_pos.x) > absf(connected_local_pos.z):
					connected_side = "LEFT" if connected_local_pos.x < 0 else "RIGHT"
				else:
					connected_side = "FRONT" if connected_local_pos.z < 0 else "BACK"
				if absf(connected_local_pos.y) > maxf(absf(connected_local_pos.x), absf(connected_local_pos.z)):
					connected_side = "TOP" if connected_local_pos.y > 0 else "BOTTOM"
				restricted_sides.append(opposite_sides[connected_side])

			var local_position := rb.to_local(character.global_position)
			var push_side := ""
			if absf(local_position.x) > absf(local_position.z):
				push_side = "LEFT" if local_position.x < 0 else "RIGHT"
			else:
				push_side = "FRONT" if local_position.z < 0 else "BACK"
			if absf(local_position.y) > maxf(absf(local_position.x), absf(local_position.z)):
				push_side = "TOP" if local_position.y > 0 else "BOTTOM"

			if push_side in restricted_sides:
				var applied_force_og := player_strength * strength_multiplier if body_mass >= player_strength * strength_multiplier else body_mass
				rb.apply_impulse(
						-col.get_normal().normalized() * applied_force_og * 0.2,
						col_position
				)
				continue

		var max_speed := (player_strength * strength_multiplier) / maxf(effective_mass, 0.001)
		var applied_force := player_strength * strength_multiplier if effective_mass >= player_strength * strength_multiplier else effective_mass
		applied_force *= (1.0 - friction)
		if rb.linear_velocity.length() < max_speed:
			var push_direction := -col.get_normal().normalized()
			rb.apply_impulse(push_direction * applied_force, col_position)


static func calculate_friction(connected_bodies: Array) -> float:
	var total_mass := 0.0
	for body in connected_bodies:
		total_mass += body.mass

	var base_friction := 0.1
	var friction_per_body := 0.05
	var mass_friction_factor := 0.001

	var friction := base_friction + (connected_bodies.size() * friction_per_body) + (total_mass * mass_friction_factor)
	return clampf(friction, 0.0, 1.0)


static func get_all_connected_bodies(start_body: RigidBody3D, character: CharacterBody3D, max_bodies: int = 6) -> Array[RigidBody3D]:
	var connected_bodies: Array[RigidBody3D] = []
	var visited_bodies: Dictionary = {}
	var stack: Array[RigidBody3D] = [start_body]

	while not stack.is_empty() and connected_bodies.size() < max_bodies:
		var current_body := stack.pop_front() as RigidBody3D

		if current_body in visited_bodies:
			continue
		visited_bodies[current_body] = true
		connected_bodies.append(current_body)

		if connected_bodies.size() >= max_bodies:
			break

		var collision_shape := _find_first_collision_shape(current_body)
		if collision_shape == null or collision_shape.shape == null:
			continue

		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = collision_shape.shape
		query.transform = current_body.global_transform * collision_shape.transform
		query.margin = 0.01
		query.collide_with_bodies = true
		query.collide_with_areas = false

		var space_state := character.get_world_3d().direct_space_state
		var result := space_state.intersect_shape(query)

		for item in result:
			var collider: Variant = item.get("collider")
			if collider is RigidBody3D and collider != current_body and collider not in visited_bodies:
				stack.append(collider as RigidBody3D)

	return connected_bodies


static func _find_first_collision_shape(body: RigidBody3D) -> CollisionShape3D:
	for child in body.get_children():
		if child is CollisionShape3D:
			return child as CollisionShape3D
	return null
