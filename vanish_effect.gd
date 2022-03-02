extends Sprite

export var block_color : int

func _ready():
	if block_color == -1:
		print("ERROR -1 EFFECT")
		finish()
		return
		
	frame = block_color

func finish():
	get_parent().gravity()
	queue_free()
