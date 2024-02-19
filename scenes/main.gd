extends Node3D


const Sheep: Blueprint = preload("res://cards/sheep/sheep.tres")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Spawn 10 cards for each player
	var amount: int = 10
	
	for i: int in range(amount * 2):
		var player: Player = Game.current_player
		
		if i >= amount:
			i -= amount
			player = Game.opposing_player
		
		var card: Card = Card.new()
		card.blueprint = Sheep
		card.player = player
		
		var card_node: CardNode = Game.place_card_in_player_hand(player, card, i)
		add_child(card_node)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	# TODO: Make a better way to quit
	if event.as_text() == "Escape":
		get_tree().quit()
