extends Node2D

# GameMap - Handles the grid system for tower placement and pathfinding

const TILE_SIZE = 64
const MAP_WIDTH = 20
const MAP_HEIGHT = 12

@onready var grid_container = $GridContainer
@onready var path_line = $PathLine

# Grid data - true = can place tower, false = path or blocked
var grid: Array = []

# Enemy path waypoints (in grid coordinates)
var path_waypoints: Array[Vector2i] = [
	Vector2i(0, 6),
	Vector2i(5, 6),
	Vector2i(5, 3),
	Vector2i(10, 3),
	Vector2i(10, 8),
	Vector2i(15, 8),
	Vector2i(15, 5),
	Vector2i(19, 5)
]

# World position waypoints (converted from grid coordinates)
var world_waypoints: Array[Vector2] = []

func _ready():
	_initialize_grid()
	_create_path()
	_draw_grid()

# Initialize empty grid
func _initialize_grid():
	grid.clear()

	for y in range(MAP_HEIGHT):
		var row = []
		for x in range(MAP_WIDTH):
			row.append(true)  # All tiles start as placeable
		grid.append(row)

	# Convert path waypoints to world positions
	world_waypoints.clear()
	for waypoint in path_waypoints:
		var world_pos = grid_to_world(waypoint)
		world_waypoints.append(world_pos)

# Mark path tiles as non-placeable
func _create_path():
	for i in range(path_waypoints.size() - 1):
		var start = path_waypoints[i]
		var end = path_waypoints[i + 1]

		_mark_path_segment(start, end)

func _mark_path_segment(start: Vector2i, end: Vector2i):
	var current = start

	while current != end:
		# Mark current tile and adjacent tiles as non-placeable
		_mark_tile(current.x, current.y, false)

		# Mark adjacent tiles for wider path
		_mark_tile(current.x + 1, current.y, false)
		_mark_tile(current.x - 1, current.y, false)
		_mark_tile(current.x, current.y + 1, false)
		_mark_tile(current.x, current.y - 1, false)

		# Move toward end
		if current.x < end.x:
			current.x += 1
		elif current.x > end.x:
			current.x -= 1
		elif current.y < end.y:
			current.y += 1
		elif current.y > end.y:
			current.y -= 1

	# Mark final tile
	_mark_tile(end.x, end.y, false)

func _mark_tile(x: int, y: int, placeable: bool):
	if x >= 0 and x < MAP_WIDTH and y >= 0 and y < MAP_HEIGHT:
		grid[y][x] = placeable

# Draw grid lines for visualization
func _draw_grid():
	queue_redraw()

func _draw():
	# Draw grid lines
	for x in range(MAP_WIDTH + 1):
		var start = Vector2(x * TILE_SIZE, 0)
		var end = Vector2(x * TILE_SIZE, MAP_HEIGHT * TILE_SIZE)
		draw_line(start, end, Color(0.3, 0.3, 0.3, 0.3), 1.0)

	for y in range(MAP_HEIGHT + 1):
		var start = Vector2(0, y * TILE_SIZE)
		var end = Vector2(MAP_WIDTH * TILE_SIZE, y * TILE_SIZE)
		draw_line(start, end, Color(0.3, 0.3, 0.3, 0.3), 1.0)

	# Draw path
	for i in range(world_waypoints.size() - 1):
		draw_line(world_waypoints[i], world_waypoints[i + 1], Color(0.7, 0.5, 0.3), 8.0)

	# Draw path tiles
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			if not grid[y][x]:
				var pos = grid_to_world(Vector2i(x, y))
				draw_rect(Rect2(pos - Vector2(TILE_SIZE / 2, TILE_SIZE / 2), Vector2(TILE_SIZE, TILE_SIZE)), Color(0.5, 0.4, 0.3, 0.3), true)

# Convert grid coordinates to world position
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE / 2, grid_pos.y * TILE_SIZE + TILE_SIZE / 2)

# Convert world position to grid coordinates
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))

# Check if a grid position is valid for tower placement
func can_place_tower(grid_pos: Vector2i) -> bool:
	if grid_pos.x < 0 or grid_pos.x >= MAP_WIDTH:
		return false
	if grid_pos.y < 0 or grid_pos.y >= MAP_HEIGHT:
		return false

	return grid[grid_pos.y][grid_pos.x]

# Mark a tile as occupied by a tower
func occupy_tile(grid_pos: Vector2i):
	if can_place_tower(grid_pos):
		grid[grid_pos.y][grid_pos.x] = false

# Get enemy path waypoints
func get_enemy_path() -> Array[Vector2]:
	return world_waypoints

# Get spawn position (first waypoint)
func get_spawn_position() -> Vector2:
	return world_waypoints[0] if world_waypoints.size() > 0 else Vector2.ZERO

# Get goal position (last waypoint)
func get_goal_position() -> Vector2:
	return world_waypoints[-1] if world_waypoints.size() > 0 else Vector2.ZERO
