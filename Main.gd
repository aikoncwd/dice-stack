extends Node2D

var new_row = []
var col = 0
var selected = 5

func _ready():
	randomize()
	generate_new_row()
	add_row()
	generate_new_row()
	draw_cursor()

func generate_new_row():
	var last_dice
	var n
	new_row.clear()
	for i in range(6):
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
	for i in range(6):
		$TileMap.set_cell(i, 11, new_row[i])

func add_row():
	for y in range(10):
		for x in range(6):
			var block = $TileMap.get_cell(x, y)
			if block != -1:
				if y > 0:
					$TileMap.set_cell(x, y-1, block)
					$TileMap.set_cell(x, y, -1)
				else:
					print("GAME OVER")
					return
	for i in range(6):
		$TileMap.set_cell(i,9, new_row[i])

func draw_cursor():
	var top_block = get_top_block()
	if top_block == 12:
		$crosshair.position = Vector2(56 + (16 * col), 184)
	else:
		$crosshair.position = Vector2(56 + (16 * col), 40 + (16 * top_block))
	for i in range(6):
		$TileMap.set_cell(i, -1, 5)
	$TileMap.set_cell(col, -1, selected)

func get_top_block():
	for i in range(10):
		if $TileMap.get_cell(col, i) != -1:
			return i
	return 12

func grab_block():
	var top_block = get_top_block()
	if top_block == 12:
		print("Trying to grab NOTHING")
	else:
		selected = $TileMap.get_cell(col, top_block)
		$TileMap.set_cell(col, top_block, -1)

func drop_block():
	var top_block = get_top_block() - 1
	if top_block == 11:
		$TileMap.set_cell(col, 9, selected)
	else:
		$TileMap.set_cell(col, top_block, selected)
	selected = 5

func check_hit():
	var destroy_blocks = []
	for y in range(10):
		for x in range(6):
			var block = $TileMap.get_cell(x, y)
			if block != -1:
				if $TileMap.get_cell(x-1, y) == block and $TileMap.get_cell(x+1, y) == block:
					destroy_blocks.append(Vector2(x-1,y))
					destroy_blocks.append(Vector2(x,y))
					destroy_blocks.append(Vector2(x+1,y))
				if $TileMap.get_cell(x, y-1) == block and $TileMap.get_cell(x, y+1) == block:
					destroy_blocks.append(Vector2(x,y-1))
					destroy_blocks.append(Vector2(x,y))
					destroy_blocks.append(Vector2(x,y+1))
	for destroy in destroy_blocks:
		$TileMap.set_cellv(destroy, -1)
		print("score!")

func gravity():
	pass

func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_DOWN and event.pressed:
			add_row()
			generate_new_row()
			check_hit()
			draw_cursor()
		if event.scancode == KEY_RIGHT and event.pressed:
			col += 1
			if col > 5: col = 0
			draw_cursor()
		if event.scancode == KEY_LEFT and event.pressed:
			col -= 1
			if col < 0: col = 5
			draw_cursor()
		if event.scancode == KEY_SPACE and event.pressed:
			if selected == 5:
				grab_block()
			else:
				drop_block()
				check_hit()
			draw_cursor()
