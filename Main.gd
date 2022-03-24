extends Node2D

var new_row = []
var col = 0
var selected = 5
var score = 0
var gameover = false
var gamestate = "title"
var gamemodes = ["time attack", "speedrun", "practice"]
var selected_label = 0
var gamemode = gamemodes[selected_label]

signal animation_finish

func _ready():
	randomize()

func generate_new_row(starting = false):
	var last_dice
	var n
	new_row.clear()
	for i in range(7):
		if new_row.size() == 0:
			n = randi() % 5
			new_row.append(n)
			last_dice = n
		else:
			n = randi() % 5
			while n == last_dice:
				n = randi() % 5
			new_row.append(n)
			last_dice = n
		$TileMap.set_cell(i, 10, new_row[i])
	if !starting: $new_line.play()

func add_row():
	for effect in get_tree().get_nodes_in_group("effects"):
		effect.queue_free()
	
	for y in range(9):
		for x in range(7):
			var block = $TileMap.get_cell(x, y)
			if block != -1:
				if y > 0:
					$TileMap.set_cell(x, y-1, block)
					$TileMap.set_cell(x, y, -1)
				else:
					gameover = true
					$Timer.stop()
					$label_gameover.visible = true
					return
	for i in range(7):
		$TileMap.set_cell(i, 8, new_row[i]) #ERROR AFTER NEWGAME

func draw_cursor():
	var top_block = get_top_block()
	if top_block == 12:
		$crosshair.position = Vector2(40 + (16 * col), 168)
	else:
		$crosshair.position = Vector2(40 + (16 * col), 40 + (16 * top_block))
	for i in range(7):
		$TileMap.set_cell(i, -1, 5)
	$TileMap.set_cell(col, -1, selected)

func get_top_block():
	for y in range(9):
		if $TileMap.get_cell(col, y) != -1:
			return y
	return 12

func grab_block():
	var top_block = get_top_block()
	if top_block != 12:
		selected = $TileMap.get_cell(col, top_block)
		$TileMap.set_cell(col, top_block, -1)

func drop_block():
	var top_block = get_top_block() - 1
	if top_block == 11:
		$TileMap.set_cell(col, 8, selected)
	else:
		$TileMap.set_cell(col, top_block, selected)
	selected = 5

func check_hit():
	var scored = false
	var block
	var destroy_blocks = []
	for y in range(9):
		for x in range(7):
			block = $TileMap.get_cell(x, y)
			if block != -1:
				if $TileMap.get_cell(x-1, y) == block and $TileMap.get_cell(x+1, y) == block:
					destroy_blocks.append(Vector2(x-1,y))
					destroy_blocks.append(Vector2(x,y))
					destroy_blocks.append(Vector2(x+1,y))
					scored = true
				if $TileMap.get_cell(x, y-1) == block and $TileMap.get_cell(x, y+1) == block:
					destroy_blocks.append(Vector2(x,y-1))
					destroy_blocks.append(Vector2(x,y))
					destroy_blocks.append(Vector2(x,y+1))
					scored = true
	
	if scored:
		match destroy_blocks.size():
			3:
				$score.pitch_scale = 1
			6:
				$score.pitch_scale = 1.25
			_:
				$score.pitch_scale = 1.5
		$score.play()
	else:
		$drop.play()
	
	for destroy in destroy_blocks:
		var block_color = $TileMap.get_cellv(destroy)
		$TileMap.set_cellv(destroy, -1)
		spawn_effect(destroy, block_color)
		score += 1
	update_score()

func gravity():
	var fall = false
	for y in range(8, 0, -1):
		for x in range(6, -1, -1):
			if $TileMap.get_cell(x, y) == -1 and $TileMap.get_cell(x, y-1) != -1:
				var block = $TileMap.get_cell(x, y - 1)
				$TileMap.set_cell(x, y, block)
				$TileMap.set_cell(x, y - 1, -1)
				fall = true
	if fall: check_hit()

func update_score():
	$label_score.text = str(score)

func spawn_effect(pos : Vector2, block_color):
	var effect = preload("res://vanish_effect.tscn").instance()
	effect.position = $TileMap.map_to_world(pos + Vector2(2, 2)) + Vector2(8, 8)
	effect.block_color = block_color
	add_child(effect)

func animation():
	for y in range(9):
		for x in range(7):
			$TileMap.set_cell(x, y, -1)
			yield(get_tree().create_timer(0.01), "timeout")
	for i in range(7):
			$TileMap.set_cell(i, 10, -1)
			yield(get_tree().create_timer(0.05), "timeout")
	emit_signal("animation_finish")

func _input(event):
	match gamestate:
		"title":
			if Input.is_action_just_pressed("ui_accept"):
				$box_titulo.visible = false
				$menu.visible = false
				yield(get_tree().create_timer(0.5), "timeout")
				animation()
				yield(self, "animation_finish")
				yield(get_tree().create_timer(0.5), "timeout")
				
				generate_new_row(true)
				yield(get_tree().create_timer(0.25), "timeout")
				add_row()
				generate_new_row(true)
				yield(get_tree().create_timer(0.25), "timeout")
				draw_cursor()
				yield(get_tree().create_timer(0.25), "timeout")
				
				$crosshair.visible = true
				$ProgressBar.visible = true
				$label_score.visible = true
				$Timer.start()
				
				gamestate = "gaming"
			if Input.is_action_just_pressed("ui_down"):
				selected_label += 1
				if selected_label > 2: selected_label = 0
				match selected_label:
					0:
						$menu/label_timeattack.text = ">" + gamemodes[0] + "<"
						$menu/label_speedrun.text = gamemodes[1]
						$menu/label_practice.text = gamemodes[2]
					1:
						$menu/label_timeattack.text = gamemodes[0]
						$menu/label_speedrun.text = ">" + gamemodes[1] + "<"
						$menu/label_practice.text = gamemodes[2]
					2:
						$menu/label_timeattack.text = gamemodes[0]
						$menu/label_speedrun.text = gamemodes[1]
						$menu/label_practice.text = ">" + gamemodes[2] + "<"
			if Input.is_action_just_pressed("ui_up"):
				selected_label -= 1
				if selected_label < 0: selected_label = 2
				match selected_label:
					0:
						$menu/label_timeattack.text = ">" + gamemodes[0] + "<"
						$menu/label_speedrun.text = gamemodes[1]
						$menu/label_practice.text = gamemodes[2]
					1:
						$menu/label_timeattack.text = gamemodes[0]
						$menu/label_speedrun.text = ">" + gamemodes[1] + "<"
						$menu/label_practice.text = gamemodes[2]
					2:
						$menu/label_timeattack.text = gamemodes[0]
						$menu/label_speedrun.text = gamemodes[1]
						$menu/label_practice.text = ">" + gamemodes[2] + "<"
		"gaming":
			if Input.is_action_just_pressed("ui_down") and !gameover:
				add_row()
				gravity()
				generate_new_row()
				check_hit()
				draw_cursor()
				if $ProgressBar.max_value > 40: $ProgressBar.max_value -= 1
				$ProgressBar.value = $ProgressBar.max_value
			if Input.is_action_just_pressed("ui_right") and !gameover:
				col += 1
				if col > 6: col = 0
				draw_cursor()
			if Input.is_action_just_pressed("ui_left") and !gameover:
				col -= 1
				if col < 0: col = 6
				draw_cursor()
			if Input.is_action_just_pressed("fast_right") and !gameover:
				col = 6
				draw_cursor()
			if Input.is_action_just_pressed("fast_left") and !gameover:
				col = 0
				draw_cursor()
			if Input.is_action_just_pressed("ui_accept"):
				if !gameover:
					if selected == 5:
						$pick.play()
						grab_block()
					else:
						drop_block()
						check_hit()
					draw_cursor()
				else:
					gameover = false
					$label_gameover.visible = false
					$ProgressBar.value = $ProgressBar.max_value
					new_row.clear()
					col = 0
					selected = 5
					score = 0
					update_score()
					for y in range(8):
						for x in range(7):
							$TileMap.set_cell(x, y, -1)
					_ready()
					$Timer.start()

func _on_Timer_timeout():
	if $ProgressBar.value == 0:
		add_row()
		gravity()
		generate_new_row()
		draw_cursor()
		check_hit()
		draw_cursor()
		if $ProgressBar.max_value > 40: $ProgressBar.max_value -= 1
		$ProgressBar.value = $ProgressBar.max_value
	$ProgressBar.value -= 1
