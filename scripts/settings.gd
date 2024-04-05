extends Node
## @experimental

var server: Dictionary = {
	## The port of the multiplayer server.
	"port": 4545,
	
	## How aggressive the anticheat should be. Only affects the server.[br]
	## [code]0: Disabled.
	## 1: Only validation.
	## 2: Basic cheat detection.
	## 3-inf: More-and-more aggressive anticheat.
	## -1: Max anticheat.[/code]
	"anticheat_level": -1,
	
	## The action that should be taken if the anticheat gets triggered.
	"anticheat_consequence": Anticheat.Consequence.DROP_PACKET,
	
	## A list of banned ips. Gets populated by [method load_config]
	"ban_list": [],
	
	## The max amount of cards that can be on a player's board. Can be overriden by [code]Multiplayer.load_config()[/code].
	"max_board_space": 7,

	## The max amount of cards that can be in a player's hand. Can be overriden by [code]Multiplayer.load_config()[/code].
	"max_hand_size": 10,

	## The max amount of cards that can be in a player's deck. Can be overriden by [code]Multiplayer.load_config()[/code].
	"max_deck_size": 30,

	## The min amount of cards that can be in a player's deck. Can be overriden by [code]Multiplayer.load_config()[/code].
	"min_deck_size": 30,

	## The max amount of players that can be in a game at once. Any value other than 2 is not supported and will break.
	"max_players": 2,
}

var client: Dictionary = {
	# VIDEO
	"fullscreen_mode": DisplayServer.WINDOW_MODE_WINDOWED,
	"resolution": Vector2i(ProjectSettings.get("display/window/size/viewport_width"), ProjectSettings.get("display/window/size/viewport_height")),
	"vsync": true,
	
	# GAME
	"animations": true,
	
	# DEBUG
	"card_bounds_x": -3.05,
	"card_bounds_y": -0.5,
	"card_bounds_z": 13.0,
	"card_rotation_y_multiplier": 10.0,
	"card_distance_x": 1.81,
}
