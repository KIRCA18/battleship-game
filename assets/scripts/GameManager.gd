extends Node

enum Difficulty {Easy, Medium, Hard, Impossible}
enum GameState {GameConfig, Player1BoardConfig, Player2BoardConfig, Player1Guess, Player2Guess, Player1Won, Player2Won}

var numberOfPlayers = 2
var difficulty = Difficulty.Easy
var gridSize = 10
var state = GameState.GameConfig
var players: Array[Player] = []
var playersStateWon: Array[GameState] = [GameState.Player1Won, GameState.Player2Won]
var currentPlayerIndex = 0
var otherPlayerIndex = 1
var boatCombo = {}
var boatCount = 0
var playingLastGame = false
signal changePlayerSignal

func save_state():
	var file = FileAccess.open("user://lastgame.save", FileAccess.WRITE)
	if file:
		file.store_var(numberOfPlayers)
		file.store_var(difficulty)
		file.store_var(gridSize)
		file.store_var(state)
		var player_dicts = []
		for player in players:
			if player is AI:
				player_dicts.append((player as AI).to_dict())
			else:
				player_dicts.append(player.to_dict())
		file.store_var(player_dicts)
		file.store_var(currentPlayerIndex)
		file.store_var(otherPlayerIndex)
		file.store_var(boatCombo)
		file.store_var(boatCombo)
		file.close()
	
func load_state() -> bool:
	if not FileAccess.file_exists("user://lastgame.save"):
		print("File doesn't exist")
		return false
	
	var file = FileAccess.open("user://lastgame.save", FileAccess.READ)
	numberOfPlayers = file.get_var()
	difficulty = file.get_var()
	gridSize = file.get_var()
	state = file.get_var()
	players = []
	var player_dicts = file.get_var()
	var p = Player.new()
	p.from_dict(player_dicts[0])
	players.append(p)
	var p2
	if numberOfPlayers == 1:
		p2 = AI.new()
	else:
		p2 = Player.new()
	p2.from_dict(player_dicts[1])
	players.append(p2)
	currentPlayerIndex = file.get_var()
	otherPlayerIndex = file.get_var()
	boatCombo = file.get_var()
	boatCombo = file.get_var()
	file.close()
	playingLastGame = true
	return true
	

func reset():
	numberOfPlayers = 2
	difficulty = Difficulty.Easy
	gridSize = 10
	state = GameState.GameConfig
	players = []
	playersStateWon = [GameState.Player1Won, GameState.Player2Won]
	currentPlayerIndex = 0
	otherPlayerIndex = 1
	boatCombo = {}
	boatCount = 0

func setup(numOfPlayers, grid_size, dif = Difficulty.Easy) -> void:
	self.numberOfPlayers = numOfPlayers
	self.gridSize = grid_size
	self.difficulty = dif
	players.append(Player.new())
	if numberOfPlayers == 1:
		players.append(AI.new())
	else:
		players.append(Player.new())
	
	if gridSize == 8:
		boatCombo = {2: 2, 3: 1, 4: 1, 5: 1}
		boatCount = 5
	elif gridSize == 10:
		boatCombo = {2: 2, 3: 2, 4: 1, 5: 1}
		boatCount = 6
	elif gridSize == 12:
		boatCombo = {2: 2, 3: 3, 4: 2, 5: 1}
		boatCount = 8
	
	for player in players:
		player.setup(gridSize, boatCount)

func next_scene():
	match state:
		GameState.GameConfig:
			get_tree().change_scene_to_file("res://BoardConfig.tscn")
			state = GameState.Player1BoardConfig
		GameState.Player1BoardConfig:
			currentPlayerIndex = 0
			if numberOfPlayers == 1:
				(players[1] as AI).generate_board()
				get_tree().change_scene_to_file("res://Playing.tscn")
				state = GameState.Player1Guess
			elif numberOfPlayers == 2:
				currentPlayerIndex = 1
				get_tree().change_scene_to_file("res://BoardConfig.tscn")
				state = GameState.Player2BoardConfig
		GameState.Player2BoardConfig:
			currentPlayerIndex = 0
			get_tree().change_scene_to_file("res://Playing.tscn")
			state = GameState.Player1Guess
		GameState.Player1Won, GameState.Player2Won:
			if playingLastGame == true:
				playingLastGame = false
				removeLastSave()
			if not DirAccess.dir_exists_absolute("user://prevgames/"):
				DirAccess.make_dir_absolute("user://prevgames/")
			var gameFile = FileAccess.open("user://prevgames/game-{millis}".format({"millis": Time.get_unix_time_from_system()}), FileAccess.WRITE)
			var winner = "Player 1" if state == GameState.Player1Won else "Player 2"
			var score = players[currentPlayerIndex].score
			var date = Time.get_datetime_dict_from_system()
			var mode = "Player vs Player" if numberOfPlayers == 2 else "Player vs Computer"
			gameFile.store_var(winner)
			gameFile.store_var(score)
			gameFile.store_var(date)
			gameFile.store_var(mode)
			gameFile.store_var(difficulty)
			gameFile.flush()
			gameFile.close()
			get_tree().change_scene_to_file("res://End.tscn")
		GameState.Player1Guess, GameState.Player2Guess:
			get_tree().change_scene_to_file("res://Playing.tscn")
	
	
func removeLastSave():
	if FileAccess.file_exists("user://lastgame.save"):
		DirAccess.remove_absolute("user://lastgame.save")

func place_boat(index: int, size: int, orientation: String, type: String):
	players[currentPlayerIndex].boardConfig.append({"index": index,"size": size, "orientation": orientation, "type": type})
	if players[currentPlayerIndex].boardConfig.size() == boatCount:
		players[currentPlayerIndex].normalize()
		next_scene()
		

func guess(x: int, y: int) -> Dictionary:
	var res = players[otherPlayerIndex].guess(x, y)
	players[currentPlayerIndex].guesses[x][y] = 1
	if res["hit"]:
		players[currentPlayerIndex].score += get_tree().current_scene.get_child(5).time_left * 10
		if res["sunk"]:
			players[currentPlayerIndex].sunkBoats.append(res["boat"])
		if players[otherPlayerIndex].checkLose():
			state = playersStateWon[currentPlayerIndex]
			next_scene()
		return res
	else:
		players[currentPlayerIndex].score -= 10
	changePlayer()
	return res
	
func changePlayer() -> void:
	if state == GameState.Player1Guess:
		currentPlayerIndex = 1
		otherPlayerIndex = 0
		state = GameState.Player2Guess
	elif state == GameState.Player2Guess:
		currentPlayerIndex = 0
		otherPlayerIndex = 1
		state = GameState.Player1Guess
	
	changePlayerSignal.emit()


func drawGrid(root, player1Grid: Node3D, player2Grid: Node3D, tileWidth, tileHeight, tileSpacing, function):
	players[0].draw_grid(root, player1Grid,tileWidth,tileHeight,tileSpacing, function, players[1].hitmap)
	if numberOfPlayers == 2:
		players[1].draw_grid(root, player2Grid,tileWidth,tileHeight,tileSpacing, function, players[0].hitmap)
	else:
		(players[1] as AI).draw_grid(root, player2Grid,tileWidth,tileHeight,tileSpacing, function, players[0].hitmap)
