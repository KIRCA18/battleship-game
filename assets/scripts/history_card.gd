extends PanelContainer

func setup(player, points, date, mode, difficulty = null):
	$MarginContainer/HBoxContainer/VBoxContainer/Player.text = player
	$MarginContainer/HBoxContainer/VBoxContainer/Points.text = "{points} points!".format({"points": points})
	$MarginContainer/HBoxContainer/VBoxContainer2/Date.text = "{day}/{month}/{year} {hour}:{minute}".format({"day": str(date.day).pad_zeros(2), "month": str(date.month).pad_zeros(2), "year": date.year, "hour": str(date.hour).pad_zeros(2), "minute":str(date.minute).pad_zeros(2)})
	$MarginContainer/HBoxContainer/VBoxContainer2/Mode.text = mode
	if difficulty:
		$MarginContainer/HBoxContainer/VBoxContainer2/Difficulty.text = difficulty
	else:
		$MarginContainer/HBoxContainer/VBoxContainer2/Difficulty.visible = false
