extends Node2D
class_name Square

signal click_square()

const SOUNDS = [
	preload("res://assets/zapsplat_office_pencil_blunt_short_line_on_paper_on_carpet_001_88506.mp3"),
	preload("res://assets/zapsplat_office_pencil_blunt_short_line_on_paper_on_carpet_002_88507.mp3"),
]

var Player = Global.Player
var player: int = -1

func set_player(new_player: int):
	player = new_player
	$Sprite.frame = get_player_frame()
	
	if player != -1:
		$AnimationPlayer.play("Draw")
		$AudioStreamPlayer2D.stream = SOUNDS[randi() % SOUNDS.size()]
		$AudioStreamPlayer2D.play()
		yield($AnimationPlayer, "animation_finished")

func get_player_frame():
	match player:
		Player.X: return 1
		Player.O: return 2
		_: return 0

func _on_Area2D_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and not event.pressed:
		emit_signal("click_square")		
