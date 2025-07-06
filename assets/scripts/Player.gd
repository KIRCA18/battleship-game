extends Node
class_name Player

var boardConfig: Array
var guesses: Array
var boatsLeft: int
var gridSize: int
var boats = []
var hitmap = []
var score = 0
var sunkBoats = []

func setup(grid: int, boatsLeft: int):
	self.gridSize = grid
	self.boatsLeft = boatsLeft
	self.boardConfig = []
	self.guesses = []
	self.score = 0
	self.sunkBoats = []
	for i in range(gridSize):
		var temp = []
		for j in range(gridSize):
			temp.append(0)
		guesses.append(temp)
	

func guess(x: int, y: int) -> Dictionary:
	var hit = false
	var sunk = false
	var boat = {}
	if hitmap[x][y] != -1:
		var boat_id = hitmap[x][y]
		boats[boat_id] -= 1
		hit = true
		if boats[boat_id] <= 0:
			boatsLeft -= 1
			boat = boardConfig[hitmap[x][y]]
			sunk = true
	return {"hit": hit, "sunk": sunk, "boat": boat}


func getRemainingTypeOfBoats() -> Dictionary:
	var res = {"2": 0, "3": 0, "4": 0, "5": 0}
	for i in range(boardConfig.size()):
		if boats[i] > 0:
			res[str(boardConfig[i].size)] += 1
	return res

func normalize() -> void:
	for i in range(gridSize):
		var arr = []
		for j in range(gridSize):
			arr.append(-1)
		hitmap.append(arr)
	
	for i in range(boardConfig.size()):
		var boat = boardConfig[i]
		boats.append(boat.size)
		var ind = boat.index
		hitmap[ind / gridSize][ind % gridSize] = i
		if boat.orientation == "vertical":
			for j in range(boat.size - 1):
				ind += gridSize
				hitmap[ind / gridSize][ind % gridSize] = i
		elif boat.orientation == "horizontal":
			for j in range(boat.size - 1):
				ind += 1
				hitmap[ind / gridSize][ind % gridSize] = i
	print(hitmap)


func checkLose() -> bool:
	return boatsLeft == 0


func draw_grid(root: Node3D, node: Node3D, tileWidth: float, tileHeight: float, tileSpacing: float, entered_function: Callable, otherPlayerHitmap: Array):
	var current = Vector3(0, node.position.y, 0)

	for i in range(GameManager.gridSize):
		for j in range(GameManager.gridSize):
			
			var tile = StaticBody3D.new()
			tile.collision_layer = 1
			var mesh = MeshInstance3D.new()
			var boxMesh = BoxMesh.new()
			boxMesh.size = Vector3(tileHeight, 0.2, tileWidth)
			mesh.mesh = boxMesh

			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.5, 0.5, 0.5)
			mesh.set_surface_override_material(0, material)

			var collisionShape = CollisionShape3D.new()
			var collisionShapeBox = BoxShape3D.new()
			collisionShapeBox.size = Vector3(tileHeight, 0.2, tileWidth)
			collisionShape.shape = collisionShapeBox
			
			tile.set_meta("material", material)
			tile.set_meta("free", true)
			tile.add_child(mesh)
			tile.add_child(collisionShape)
			node.add_child(tile)
			tile.transform.origin = Vector3(current.x, current.y, current.z)
			if guesses[i][j]:
				if otherPlayerHitmap[i][j] != -1:
					material.albedo_color = Color(1, 0, 0)
				else:
					tile.visible = false
			else:
				tile.mouse_entered.connect(entered_function.bind(tile))
			current.x += tileWidth + tileSpacing
		current.x = 0
		current.z += tileHeight + tileSpacing
	
	for boat in sunkBoats:
		var sunkBoat = load("res://assets/models/"+boat.type+str(boat.size)+".blend").instantiate()
		root.add_child(sunkBoat)
		if boat.orientation == "horizontal":
			sunkBoat.transform = sunkBoat.transform.rotated(Vector3(0,1,0).normalized(), PI/2)
		sunkBoat.global_transform = sunkBoat.global_transform.scaled_local(Vector3(3,3,3))
		sunkBoat.global_transform.origin = node.get_child(boat.index + 1).global_transform.origin
	

func to_dict() -> Dictionary:
	return {
		"boardConfig": boardConfig,
		"guesses": guesses,
		"boatsLeft": boatsLeft,
		"gridSize": gridSize,
		"boats": boats,
		"hitmap": hitmap,
		"sunkBoats": sunkBoats,
		"score": score
	}

func from_dict(data: Dictionary):
	boardConfig = data.get("boardConfig")
	guesses = data.get("guesses")
	boatsLeft = data.get("boatsLeft")
	gridSize = data.get("gridSize")
	boats = data.get("boats")
	hitmap = data.get("hitmap")
	sunkBoats = data.get("sunkBoats")
	score = data.get("score")
	
