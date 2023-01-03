extends Node2D

enum State {SELECT_MODE, PLAYING, FINISHED}
var state = State.SELECT_MODE

var playing_animation := false

enum PlayingMode {VS_HUMAN, VS_AI}
var playing_mode = PlayingMode.VS_HUMAN

enum AIMode {
	# always pick a random empty square
	RANDOM_SQUARE,
	
	# pick the square that makes AI win,
	# else the square that woul make the Human win,
	# or else random
	WINNER_SQUARE,
}
var ai_mode = AIMode.RANDOM_SQUARE

var Player = Global.Player
var current_player = Player.X
var winner = -1

onready var squares = [
	$Squares/S11,
	$Squares/S12,
	$Squares/S13,
	$Squares/S21,
	$Squares/S22,
	$Squares/S23,
	$Squares/S31,
	$Squares/S32,
	$Squares/S33,
]

func _ready():
	setup_board()
	clear_board()
	change_state(State.SELECT_MODE)

func setup_board():
	for square in squares:
		square.connect("click_square", self, "_on_Square_click", [square])

func clear_board():
	for square in squares:
		square.set_player(-1)

func change_state(new_state):
	state = new_state
	
	match state:
		State.SELECT_MODE:
			$Menu.visible = true
			$Winner.visible = false
		
		State.PLAYING:
			$Menu.visible = false
			$Winner.visible = false
			winner = -1
			clear_board()
			change_current_player(current_player)
		
		State.FINISHED:
			$Menu.visible = false
			$Winner.visible = true

func _on_Square_click(square):
	if state == State.PLAYING and not playing_animation:
		try_to_draw_on_square(square)

func try_to_draw_on_square(square: Square):
	if square.player != -1:
		return
	
	playing_animation = true
	yield(square.set_player(current_player), "completed")
	playing_animation = false
	
	check_winner()
	
	change_current_player(Player.O if current_player == Player.X else Player.X)


func change_current_player(new_current_player: int):
	current_player = new_current_player
	
	if playing_mode == PlayingMode.VS_AI and state == State.PLAYING and current_player == Player.O:
		make_ai_move()

func check_winner():
	var square_states = []
	for square in squares:
		square_states.append(square.player)
	
	winner = find_winner(square_states)
	if winner != -1:
		change_state(State.FINISHED)
		$Winner.text = "WINNER: " + ("O" if winner == Player.O else "X")
	elif is_a_draw():
		change_state(State.FINISHED)
		$Winner.text = "DRAW"

func find_winner(square_states) -> int:
	# check rows
	for y in range(3):
		if square_states[y * 3] != -1 and \
		square_states[y * 3] == square_states[y * 3 + 1] and \
		square_states[y * 3] == square_states[y * 3 + 2]:
			return square_states[y * 3]
	
	# check columns
	for x in range(3):
		if square_states[x] != -1 and \
		square_states[x] == square_states[x + 3] and \
		square_states[x] == square_states[x + 6]:
			return square_states[x]
	
	# check diagonal \
	if square_states[0] != -1 and \
	square_states[0] == square_states[4] and \
	square_states[0] == square_states[8]:
		return square_states[0]
	
	# check diagonal /
	if square_states[2] != -1 and \
	square_states[2] == square_states[4] and \
	square_states[2] == square_states[6]:
		return square_states[2]
	
	return -1

func is_a_draw() -> bool:
	for square in squares:
		if square.player == -1:
			return false
	return true


func _on_PlayVsPlayer_pressed():
	playing_mode = PlayingMode.VS_HUMAN
	change_state(State.PLAYING)


func _on_PlayVsAI_RandomSquare_pressed():
	playing_mode = PlayingMode.VS_AI
	ai_mode = AIMode.RANDOM_SQUARE
	change_state(State.PLAYING)


func _on_PlayVsAI_WinningSquare_pressed():
	playing_mode = PlayingMode.VS_AI
	ai_mode = AIMode.WINNER_SQUARE
	change_state(State.PLAYING)


func make_ai_move():
	match ai_mode:
		AIMode.RANDOM_SQUARE:
			make_ai_move_random_square()
			
		AIMode.WINNER_SQUARE:
			make_ai_move_winner_square()

func make_ai_move_random_square():
	var empty_squares = []
	for square in squares:
		if square.player == -1:
			empty_squares.append(square)
	
	var chosen_square = empty_squares[randi() % empty_squares.size()]
	
	try_to_draw_on_square(chosen_square)

func make_ai_move_winner_square():
	var square_states = []
	for square in squares:
		square_states.append(square.player)
	
	# find winning square
	for i in range(square_states.size()):
		if square_states[i] == -1:
			var square_states_changed = square_states.duplicate()
			square_states_changed[i] = current_player
			if find_winner(square_states_changed) == current_player:
				try_to_draw_on_square(squares[i])
				return
	
	# find opponent winning square
	var opponent = Player.X if current_player == Player.O else Player.O
	for i in range(square_states.size()):
		if square_states[i] == -1:
			var square_states_changed = square_states.duplicate()
			square_states_changed[i] = opponent
			if find_winner(square_states_changed) == opponent:
				try_to_draw_on_square(squares[i])
				return
	
	# fallback to random square
	make_ai_move_random_square()


func _on_Rematch_pressed():
	change_state(State.PLAYING)

func _on_Back_to_menu_pressed():
	change_state(State.SELECT_MODE)
