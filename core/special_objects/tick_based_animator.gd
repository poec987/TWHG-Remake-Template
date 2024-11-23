extends AnimationPlayer
class_name TickBasedAnimator

@export var start_time: int = 0
# For some reason advance() doesn't work inside the _ready()
# function so I'm doing a one-time event myself.
var started: bool = false

func _ready() -> void:
	GameLoop.animation_update.connect(animation_update)
	callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

func animation_update() -> void:
	if not started:
		advance(GameLoop.TICK_LENGTH * start_time)
		started = true
	
	advance(GameLoop.TICK_LENGTH)
	pass
