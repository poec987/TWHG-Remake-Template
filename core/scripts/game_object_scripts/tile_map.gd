extends TileMapLayer

func _ready() -> void:
	for cell: Vector2i in get_used_cells():
		Collider.walls.append(Rect2(
			Vector2(cell.x * 48 - 3, cell.y * 48 - 3) + global_position,
			Vector2(54, 54)))

func _process(_delta: float) -> void:
	if GameManager.ghost:
		modulate.a = 0.5
	else:
		modulate.a = 1