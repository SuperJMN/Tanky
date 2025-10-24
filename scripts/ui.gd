extends CanvasLayer

# References
@onready var lives_label = $LivesLabel
@onready var score_label = $ScoreLabel
@onready var game_over_label = $GameOverLabel

var lives = 3
var score = 0

func _ready():
	update_lives(lives)
	update_score(score)
	game_over_label.visible = false

func update_lives(new_lives: int):
	lives = new_lives
	lives_label.text = "Lives: %d" % lives

func update_score(new_score: int):
	score = new_score
	score_label.text = "Score: %d" % score

func show_game_over():
	game_over_label.visible = true
