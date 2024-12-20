extends Node

# Objects
const WALL_SIZE: Vector2 = Vector2(54, 54)

var touched_checkpoint_ids: PackedInt32Array = []
#var walls: Array[Rect2] = []

var checkpoints: Array[ColorRect] = []

# Assigning unique IDs to objects
var next_enemy_id: int = -1
var next_checkpoint_id: int = -1
var next_coin_id: int = -1
var next_key_id: int = -1




func get_center(rect: Rect2) -> Vector2:
	return rect.position + rect.size / 2



func point_in_rect(position: Vector2, rect: Rect2) -> bool:
	if position.x >= rect.position.x and position.x <= rect.end.x and \
			position.y >= rect.position.y and position.y <= rect.end.y:
		return true
	return false




func push_out_of_walls(hitbox: RectangleCollider, subpixels: Vector2i, given_walls: Array[Rect2]) -> Vector2:
	var usable_hitbox: Rect2 = Rect2(hitbox.position, hitbox.size)
	
	var proposed_position: Vector2i = get_center(usable_hitbox) * 1000
	var half_size: Vector2 = hitbox.size / 2
	
	var intersections: Array[Rect2] = []
	for wall: Rect2 in given_walls:
		if usable_hitbox.intersects(wall):
			var intersection: Rect2 = usable_hitbox.intersection(wall)
			intersection.position -= get_center(usable_hitbox)
			intersections.append(intersection)
	
	var edge: Vector2i = Vector2i.ZERO
	
	for intersection: Rect2 in intersections:
		if edge.x == 0:
			# Case: Vertical intersection
			if intersection.size.x < intersection.size.y:
				if intersection.position.x == -half_size.x:
					@warning_ignore("narrowing_conversion")
					proposed_position.x += intersection.size.x * 1000
					edge.x = -1
				
				if intersection.end.x == half_size.x:
					@warning_ignore("narrowing_conversion")
					proposed_position.x -= intersection.size.x * 1000
					edge.x = 1
		
		if edge.y == 0:
			# Case: Horizontal or square intersection
			if intersection.size.x > intersection.size.y or \
					intersection.size >= Vector2(4, 4):
				if intersection.position.y == -half_size.y:
					@warning_ignore("narrowing_conversion")
					proposed_position.y += intersection.size.y * 1000
					edge.y = -1
				
				if intersection.end.y == half_size.y:
					@warning_ignore("narrowing_conversion")
					proposed_position.y -= intersection.size.y * 1000
					edge.y = 1
	
	if edge.x == 0:
		proposed_position.x += subpixels.x
	if edge.x == 1:
		proposed_position.x += 999
	if edge.y == 0:
		proposed_position.y += subpixels.y
	if edge.y == 1:
		proposed_position.y += 999
	
	return proposed_position






# Danger zone below...





# Continue at your own risk...





# WARNING: This function is so complex that it tends to melt people's brains.
func corner_slide(dynamic_rect: RectangleCollider, given_walls: Array[Rect2], sensitivity: float, velocity: Vector2, controls: Vector2i) -> Vector2:
	var usable_rect: Rect2 = Rect2(dynamic_rect.position, dynamic_rect.size)
	
	var player_movement: bool = false
	
	if controls != Vector2i.ZERO:
		player_movement = true
		velocity = Vector2.ZERO
	elif velocity == Vector2.ZERO:
		return Vector2.ZERO
	else:
		sensitivity *= 0.625 # Sensitivity is lower when not pressing anything.
	
	# Aborting in case of diagonal movement.
	if player_movement == true:
		if controls.x != 0 and controls.y != 0:
			return Vector2.ZERO
	else:
		if velocity.x != 0 and velocity.y != 0:
			return Vector2.ZERO
	
	# Finding any intersected walls.
	var intersections: Array[Rect2] = []
	for wall: Rect2 in given_walls:
		if usable_rect.intersects(wall):
			intersections.append(Rect2(usable_rect.intersection(wall).position - \
					get_center(usable_rect), usable_rect.intersection(wall).size))
	# Aborting in case of no wall intersections.
	if intersections.size() == 0:
		return Vector2.ZERO
	
	
	# Setting up important collision points: Corners and their limits that disable them.
	var half_size: float = usable_rect.size.x / 2
	var toggles: Dictionary = {
		"top_left_corner": false, "top_right_corner": false, "bottom_left_corner": false, "bottom_right_corner": false,
		# First word is movement direction, second word decides which relevant corner to disable.
		"up_left_limit": false, "up_right_limit": false, "left_up_limit": false, "left_down_limit": false,
		"down_left_limit": false, "down_right_limit": false, "right_up_limit": false, "right_down_limit": false,
	}
	
	var corners: Dictionary = {
		"top_left_corner": Vector2(-half_size, -half_size),
		"top_right_corner": Vector2(half_size, -half_size),
		"bottom_left_corner": Vector2(-half_size, half_size),
		"bottom_right_corner": Vector2(half_size, half_size),
	}
	
	var limits: Dictionary = {
		"up_left_limit": Vector2(-half_size + sensitivity, -half_size), 
		"up_right_limit": Vector2(half_size - sensitivity, -half_size),
		"left_up_limit": Vector2(-half_size, -half_size + sensitivity), 
		"left_down_limit": Vector2(-half_size, half_size - sensitivity),
		"down_left_limit": Vector2(-half_size + sensitivity, half_size), 
		"down_right_limit": Vector2(half_size - sensitivity, half_size),
		"right_up_limit": Vector2(half_size, -half_size + sensitivity), 
		"right_down_limit": Vector2(half_size, half_size - sensitivity),
	}
	# Compressing relevant information to loop through.
	var direction_checks: Array[Dictionary] = [
		# Case 0: Up
		{"corners": ["top_left_corner", "top_right_corner"], "limits": \
				["up_left_limit", "up_right_limit"], "offset": Vector2(1, 0)},
		# Case 1: Left
		{"corners": ["top_left_corner", "bottom_left_corner"], "limits": \
				["left_up_limit", "left_down_limit"], "offset": Vector2(0, 1)},
		# Case 2: Down
		{"corners": ["bottom_left_corner", "bottom_right_corner"], "limits": \
				["down_left_limit", "down_right_limit"], "offset": Vector2(1, 0)},
		# Case 3: Right
		{"corners": ["top_right_corner", "bottom_right_corner"], "limits": \
				["right_up_limit", "right_down_limit"], "offset": Vector2(0, 1)}
	]
	
	
	# Testing which collision points touch walls.
	for intersection: Rect2 in intersections:
		for corner: String in corners.keys():
			if point_in_rect(corners[corner], intersection):
				toggles[corner] = true
		
		for limit: String in limits.keys():
			if point_in_rect(limits[limit], intersection):
				toggles[limit] = true
	
	# Deciding the player's direction of movement to react to.
	# 0 for Up, 1 for Left, 2 for Down, 3 for Right. Order of WASD.
	var direction: int
	
	if player_movement: # Case: Movement keys are pressed
		if controls.y != 0:
			direction = 0 if controls.y < 0 else 2
		else:
			direction = 1 if controls.x < 0 else 3
	else: # Case: External forces like conveyors, no key presses.
		if velocity.y != 0:
			direction = 0 if velocity.y < 0 else 2
		else:
			direction = 1 if velocity.x < 0 else 3
	
	# Finally, based on all information previously gathered, the return values.
	var proposed_direction: Vector2 = Vector2.ZERO
	
	for i: int in range(2):
		if toggles[direction_checks[direction]["corners"][i]] and not \
			toggles[direction_checks[direction]["limits"][i]]:
			if i == 0:
				proposed_direction = direction_checks[direction]["offset"]
			else:
				proposed_direction = -direction_checks[direction]["offset"]
	
	return proposed_direction
