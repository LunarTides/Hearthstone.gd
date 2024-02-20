extends Resource
class_name Player
# TODO: Make more descriptive
## Player.
## @experimental


#region Public Variables
## The player's name.
var name: String

## The player's id.
var id: int

## The player's hand.
var hand: Array[Card]

## The player's deck.
var deck: Array[Card]

## The player's board.
var board: Array[Card]

## The player's graveyard.
var graveyard: Array[Card]
#endregion


#region Public Functions
func summon_card(card: Card, index: int) -> void:
	Game.msg.rpc_id(1, Enums.GAME_MULTIPLAYER_MESSAGE.SUMMON, id, {"hand_index": card.index, "board_index": index})


func add_to_hand(card: Card, index: int) -> void:
	Game.msg.rpc_id(1, Enums.GAME_MULTIPLAYER_MESSAGE.ADD_TO_HAND, id, {"blueprint_path": card.blueprint.resource_path, "index": index})
#endregion
