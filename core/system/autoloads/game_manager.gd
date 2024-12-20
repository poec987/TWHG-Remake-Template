extends Node

# Game properties
var paused: bool = false
var snappy_movement: bool = false

# Player stats
var deaths: int = 0
var finished: bool = false

# Special player states
var invincible: bool = false # Death can't trigger
var ghost: bool = false # Ignore walls
var flying: bool = false # Ignore terrains
var speed_hacking: bool = false # Doubles speed


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("speed_hack"):
		speed_hacking = not speed_hacking
	
	if event.is_action_pressed("invincibility"):
		invincible = not invincible
	
	if event.is_action_pressed("ghost"):
		ghost = not ghost
	
	if event.is_action_pressed("pause"):
		paused = not paused
