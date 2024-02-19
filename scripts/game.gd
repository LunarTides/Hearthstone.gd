extends Node


const CardScene: PackedScene = preload("res://scenes/card.tscn")

const CardBoundsX: float = 9.05
const CardBoundsY: float = -0.5
const CardBoundsZ: float = 7 # 3.62
const CardBoundsRotY: float = 21.2
const CardDistanceX: float = 1.81

var current_player: Player = Player.new()
var opposing_player: Player = Player.new()


func place_card_in_player_hand(player: Player, card: Card, index: int) -> CardNode:
	card.index = index
	
	var card_node: CardNode = CardScene.instantiate()
	card_node.card = card
	card_node.layout()
	
	return card_node


func layout_cards(player: Player) -> void:
	for card: CardNode in get_card_nodes_for_player(player):
		card.layout()


func get_cards_for_player(player: Player) -> Array[Card]:
	return get_card_nodes_for_player(player).map(func(card_node: CardNode) -> Card: return card_node.card)


func get_card_nodes_for_player(player: Player) -> Array[CardNode]:
	return get_tree().get_nodes_in_group("Cards").filter(func(card_node: CardNode) -> bool:
		return card_node.card.player == player
	)
