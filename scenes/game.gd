extends Node3D


const Sheep: Blueprint = preload("res://cards/sheep/sheep.tres")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Spawn 10 cards for each player
	var amount: int = 10
	
	for i: int in range(amount * 2):
		var player: Player = Game.player
		
		if i >= amount:
			i -= amount
			player = Game.opponent
		
		var card: Card = Card.new()
		card.blueprint = Sheep
		card.player = player
		
		var card_node: CardNode = Game.place_card_in_hand(card, i)
		add_child(card_node)
