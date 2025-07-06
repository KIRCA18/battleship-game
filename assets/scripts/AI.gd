extends Player
class_name AI

var prev_hits: Array = []
var target_mode: bool = false


func to_dict() -> Dictionary:
	var dict = super.to_dict()
	dict["prev_hits"] = prev_hits
	dict["target_mode"] = target_mode
	return dict

func from_dict(data: Dictionary):
	super.from_dict(data)
	prev_hits = data.get("prev_hits")
	target_mode = data.get("target_mode")

func can_place(x: int, y: int, size: int, orientation: String, placed_grid) -> bool:
		if orientation == "horizontal":
			if y + size > GameManager.gridSize:
				return false
			for i in range(size):
				if placed_grid[x][y + i]:
					return false
		else:  # vertical
			if x + size > GameManager.gridSize:
				return false
			for i in range(size):
				if placed_grid[x + i][y]:
					return false
		return true

func place_boat(x: int, y: int, size: int, orientation: String, placed_grid) -> void:
		if orientation == "horizontal":
			for i in range(size):
				placed_grid[x][y + i] = true
			boardConfig.append({
				"index": x * GameManager.gridSize + y,
				"size": size,
				"orientation": "horizontal",
				"type": "boat"
			})
		else:
			for i in range(size):
				placed_grid[x + i][y] = true
			boardConfig.append({
				"index": x * GameManager.gridSize + y,
				"size": size,
				"orientation": "vertical",
				"type": "boat"
			})

func draw_grid(root: Node3D, node: Node3D, tileWidth: float, tileHeight: float, tileSpacing: float, entered_function: Callable, hitmap: Array):
	super.draw_grid(root, node, tileWidth, tileHeight, tileSpacing, func():, hitmap)

func generate_board():
	boardConfig.clear()
	var grid_size = GameManager.gridSize
	var placed_grid = []

	for i in range(grid_size):
		var row = []
		for j in range(grid_size):
			row.append(false)
		placed_grid.append(row)


	for size in GameManager.boatCombo.keys():
		var count = GameManager.boatCombo[size]
		for _i in range(count):
			var placed = false
			var attempts = 0
			while not placed and attempts < 100:
				var orientation =  "horizontal" if randi() % 2 == 0 else "vertical"
				var x = randi_range(0, grid_size - 1)
				var y = randi_range(0, grid_size - 1)
				if can_place(x, y, int(size), orientation,placed_grid):
					place_boat(x, y, int(size), orientation,placed_grid)
					placed = true
				attempts += 1
			if not placed:
				push_error("Failed to place boat of size %d after 100 attempts" % int(size))

	normalize()

	
func hit() -> Array[int]:
	match GameManager.difficulty:
		GameManager.Difficulty.Easy:
			return hitEasy()
		GameManager.Difficulty.Medium:
			return hitMedium()
		GameManager.Difficulty.Hard:
			return hitHard()
		GameManager.Difficulty.Impossible:
			return hitImpossible()
	return []


func hitEasy() -> Array[int]:
	var x = randi_range(0,GameManager.gridSize-1)
	var y = randi_range(0,GameManager.gridSize-1)
	while guesses[x][y] == 1:
		x = randi_range(0,GameManager.gridSize-1)
		y = randi_range(0,GameManager.gridSize-1)
	return [x,y]
	
func get_valid_neighbors(x: int, y: int) -> Array:
	var grid_size = GameManager.gridSize	
	var directions = [[1,0], [-1,0], [0,1], [0,-1]]
	var valid = []
	for dir in directions:
		var nx = x + dir[0]
		var ny = y + dir[1]
		if nx >= 0 and ny >= 0 and nx < grid_size and ny < grid_size:
			valid.append([nx, ny])
	return valid
	
func get_valid_not_guessed_neighbors(x: int, y: int) -> Array:
	var grid_size = GameManager.gridSize	
	var directions = [[1,0], [-1,0], [0,1], [0,-1]]
	var valid = []
	for dir in directions:
		var nx = x + dir[0]
		var ny = y + dir[1]
		if nx >= 0 and ny >= 0 and nx < grid_size and ny < grid_size:
			if guesses[nx][ny] != 1:
				valid.append([nx, ny])
	return valid


func hitMedium() -> Array[int]:
	var grid_size = GameManager.gridSize

	if prev_hits.size() == 0:
		var x = randi_range(0, grid_size - 1)
		var y = randi_range(0, grid_size - 1)
		while guesses[x][y] == 1:
			x = randi_range(0, grid_size - 1)
			y = randi_range(0, grid_size - 1)
		return [x, y]

	if prev_hits.size() == 1:
		var neighbors = get_valid_not_guessed_neighbors(prev_hits[0][0], prev_hits[0][1])
		if neighbors.size() > 0:
			return [neighbors[0][0],neighbors[0][1]]
	else:
		var possible = []
		for prev_hit in prev_hits:
			var val = get_valid_not_guessed_neighbors(prev_hit[0],prev_hit[1])
			for v in val:
				possible.append(v)
		possible.shuffle()
		if possible.size() > 0:
			return [possible[0][0], possible[0][1]]
			

	prev_hits.clear()
	target_mode = false
	return hitMedium()


func hitHard() -> Array[int]:
	var size = GameManager.gridSize

	var heatmap = []
	for i in range(size):
		var row = []
		for j in range(size):
			row.append(0)
		heatmap.append(row)

	var remaining = GameManager.players[0].getRemainingTypeOfBoats()
	var boat_sizes = []
	for key in remaining.keys():
		if remaining[key] > 0:
			boat_sizes.append(int(key))

	for boat_size in boat_sizes:
		for i in range(size):
			for j in range(size):
				if j + boat_size <= size:
					var can_place = true
					for k in range(boat_size):
						if guesses[i][j + k] == 1:
							can_place = false
							break
					if can_place:
						for k in range(boat_size):
							heatmap[i][j + k] += 1
				if i + boat_size <= size:
					var can_place = true
					for k in range(boat_size):
						if guesses[i + k][j] == 1:
							can_place = false
							break
					if can_place:
						for k in range(boat_size):
							heatmap[i + k][j] += 1

	var visited = []
	for i in range(prev_hits.size()):
		visited.append(false)

	var clusters = []
	for i in range(prev_hits.size()):
		if visited[i]: continue
		var cluster = [prev_hits[i]]
		visited[i] = true
		var queue = [prev_hits[i]]
		while queue.size() > 0:
			var current = queue.pop_front()
			for j in range(prev_hits.size()):
				if visited[j]: continue
				if is_adjacent(current, prev_hits[j]):
					visited[j] = true
					queue.append(prev_hits[j])
					cluster.append(prev_hits[j])
		clusters.append(cluster)

	for cluster in clusters:
		if cluster.size() == 1:
			var dirs = [[1,0], [-1,0], [0,1], [0,-1]]
			var x = cluster[0][0]
			var y = cluster[0][1]
			for d in dirs:
				var nx = x + d[0]
				var ny = y + d[1]
				if nx >= 0 and ny >= 0 and nx < size and ny < size:
					if guesses[nx][ny] != 1:
						heatmap[nx][ny] += 60
		else:
			cluster.sort_custom(func(a, b): return a[0] * size + a[1] < b[0] * size + b[1])
			var dx = cluster[1][0] - cluster[0][0]
			var dy = cluster[1][1] - cluster[0][1]
			var directions = [[dx, dy], [-dx, -dy]]
			for dir in directions:
				var anchor = cluster[-1] if dir == [dx, dy] else cluster[0]
				var nx = anchor[0] + dir[0]
				var ny = anchor[1] + dir[1]
				if nx >= 0 and ny >= 0 and nx < size and ny < size:
					if guesses[nx][ny] != 1:
						heatmap[nx][ny] += 60
			for h in prev_hits:
				var dirs = [[1,0], [-1,0], [0,1], [0,-1]]
				for d in dirs:
					var nx = h[0] + d[0]
					var ny = h[1] + d[1]
					if nx >= 0 and ny >= 0 and nx < size and ny < size:
						if guesses[nx][ny] != 1:
							heatmap[nx][ny] += 20

	var max_val = -1
	var max_coords = []
	for i in range(size):
		for j in range(size):
			if guesses[i][j] == 1:
				continue
			if heatmap[i][j] > max_val:
				max_val = heatmap[i][j]
				max_coords = [[i, j]]
			elif heatmap[i][j] == max_val:
				max_coords.append([i, j])

	if max_coords.size() == 0:
		return hitEasy()
	
	max_coords.shuffle()
	return [max_coords[0][0],max_coords[0][1]]

func is_adjacent(a, b):
		return abs(a[0] - b[0]) + abs(a[1] - b[1]) == 1

func hitImpossible() -> Array[int]:
	for i in range(GameManager.gridSize):
		for j in range(GameManager.gridSize):
			if guesses[i][j] == 1 or GameManager.players[0].hitmap[i][j] == -1: 
				continue
			return [i,j]
	return []
