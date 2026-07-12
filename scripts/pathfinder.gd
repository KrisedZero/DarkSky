class_name Pathfinder
extends RefCounted
## 8-directional A* over a WorldGrid (M30). Diagonal moves are rejected when they would cut a
## wall corner. Closed doors are respected via WorldGrid.is_walkable_tile (blocked tiles).

static func find_path(grid: WorldGrid, start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	start = grid.nearest_walkable(start)
	goal = grid.nearest_walkable(goal)
	if start == goal:
		return [start]
	if not grid.is_walkable_tile(goal):
		return []

	var open: Array = [start]
	var in_open: Dictionary = { start: true }
	var came_from: Dictionary = {}
	var g_score: Dictionary = { start: 0.0 }
	var f_score: Dictionary = { start: _octile(start, goal) }

	var dirs := [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
	]

	while not open.is_empty():
		# Pop the lowest-f node (small grids -> a linear scan is fine).
		var current := open[0]
		var best_i := 0
		for i in range(1, open.size()):
			if f_score.get(open[i], INF) < f_score.get(current, INF):
				current = open[i]
				best_i = i
		open.remove_at(best_i)
		in_open.erase(current)

		if current == goal:
			return _reconstruct(came_from, current)

		for d in dirs:
			var nxt := current + d
			if not grid.is_walkable_tile(nxt):
				continue
			if d.x != 0 and d.y != 0:
				# No cutting wall corners.
				if not grid.is_walkable_tile(current + Vector2i(d.x, 0)) \
						or not grid.is_walkable_tile(current + Vector2i(0, d.y)):
					continue
			var step := 1.0 if (d.x == 0 or d.y == 0) else 1.41421356
			var tentative := float(g_score.get(current, INF)) + step
			if tentative < float(g_score.get(nxt, INF)):
				came_from[nxt] = current
				g_score[nxt] = tentative
				f_score[nxt] = tentative + _octile(nxt, goal)
				if not in_open.has(nxt):
					open.append(nxt)
					in_open[nxt] = true

	return []


static func _octile(a: Vector2i, b: Vector2i) -> float:
	var dx := absf(float(a.x - b.x))
	var dy := absf(float(a.y - b.y))
	return (dx + dy) + (1.41421356 - 2.0) * float(mini(int(dx), int(dy)))


static func _reconstruct(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.append(current)
	path.reverse()
	return path
