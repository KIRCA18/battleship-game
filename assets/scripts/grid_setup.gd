extends Node3D

@export var tileWidth: float
@export var tileHeight: float
@export var tileSpacing: float

var hoveredTiles
var isValidPosition = false

func isValid(tile: StaticBody3D) -> bool:
	if not tile: return false
	var ind = tile.get_parent().get_children().find(tile)
	if ind == -1: return false
	if not tile.has_meta("free"): return false
	if tile.has_meta("free") and tile.get_meta("free") == false:
		return false
	
	var size = $"..".ghost_boat.get_meta("size")
	var orientation = $"..".ghost_boat.get_meta("orientation")
	if orientation == "vertical":
		for i in range(size - 1):
			if (ind + GameManager.gridSize) > GameManager.gridSize * GameManager.gridSize - 1: 
				return false
			ind += GameManager.gridSize
			if tile.get_parent().get_child(ind).get_meta("free") == false:
				return false
		return true
	else:
		for i in range(size - 1):
			if ind / GameManager.gridSize != (ind+1) / GameManager.gridSize: 
				return false
			ind += 1
			if tile.get_parent().get_child(ind).get_meta("free") == false:
				return false
		return true
	

func _ready() -> void:
	var current = Vector3(0, position.y, 0)

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
			add_child(tile)
			tile.transform.origin = Vector3(current.x, current.y, current.z)
			tile.mouse_entered.connect(func() -> void: _on_mouse_entered(tile))
			tile.mouse_exited.connect(func() -> void: _on_mouse_exited(tile))
			current.x += tileWidth + tileSpacing
		current.x = position.x
		current.z += tileHeight + tileSpacing
	

func paint_tiles(tiles, color):
	if tiles:
		for t in tiles:
			if not t: continue
			var material = t.get_meta("material")
			if material and material is StandardMaterial3D:
				material.albedo_color = color

func _on_mouse_entered(tile: StaticBody3D):
	if hoveredTiles:
		paint_tiles(hoveredTiles, Color(0.5,0.5,0.5))
	hoveredTiles = null
	
	if not $"..".selected: return
	var size = $"..".ghost_boat.get_meta("size")
	var orientation = $"..".ghost_boat.get_meta("orientation")
	var tiles = [tile]
	var ind = tile.get_parent().get_children().find(tile)
	if ind == -1: return
	if orientation == "vertical":
		var prevInd = ind
		for i in range(size - 1):
			if (ind + GameManager.gridSize) > GameManager.gridSize * GameManager.gridSize - 1: break
			ind += GameManager.gridSize
			tiles.append(tile.get_parent().get_child(ind))
		ind = prevInd
	else:
		var prevInd = ind
		for i in range(size - 1):
			if ind / GameManager.gridSize != (ind+1) / GameManager.gridSize: break
			ind += 1
			tiles.append(tile.get_parent().get_child(ind))
		ind = prevInd
		print(ind + size)
	if isValid(tile):
		paint_tiles(tiles, Color(0.7,0.7,0.7))
	else:
		paint_tiles(tiles, Color(1,0,0))
	hoveredTiles = tiles


func _on_mouse_exited(_tile: StaticBody3D):
	pass


func _on_button_rotate_pressed() -> void:
	if hoveredTiles:
		paint_tiles(hoveredTiles, Color(0.5,0.5,0.5))
		var startTile = hoveredTiles[0]
		hoveredTiles = null
		_on_mouse_entered(startTile)
	else:
		hoveredTiles = null
	
