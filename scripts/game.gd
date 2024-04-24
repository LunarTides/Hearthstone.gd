extends Node
## The main singleton with a lot of helper functions.
## @experimental


#region Signals
## Emits when the game starts.
signal game_started

## Emits whenever a card or player attacks another. Both [param attacker] and [param target] can be either a [Card] or a [Player].
signal attacked(after: bool, attacker: Variant, target: Variant, sender_peer_id: int)

## Emits whenever a card gets created for any player.
signal card_created(after: bool, card: Card, player: Player, sender_peer_id: int)

## Emits whenever some amount of gets gets drawn by any player.
signal cards_drawn(after: bool, amount: int, player: Player, sender_peer_id: int)

## Emits when the any player's turn ends.
signal turn_ended(after: bool, player: Player, sender_peer_id: int)

## Emits whenever a card gets killed.
signal card_killed(after: bool, card: Card, player: Player, sender_peer_id: int)

## Emits whenever a card gets played for any player.
signal card_played(after: bool, card: Card, board_index: int, player: Player, sender_peer_id: int)

## Emits whenever a card gets revealed for any player.
signal card_revealed(after: bool, card: Card, player: Player, sender_peer_id: int)

## Emits whenever a card gets summoned for any player.
signal card_summoned(after: bool, card: Card, board_index: int, player: Player, sender_peer_id: int)

## Emits whenever one of a card's abilities gets triggered for any player.
signal card_ability_triggered(after: bool, card: Card, ability: StringName, player: Player, sender_peer_id: int)
#endregion


#region Enums
enum FeedbackType {
	INFO,
	WARNING,
	ERROR,
}

enum NullableBool {
	FALSE,
	TRUE,
	NULL,
}
#endregion


#region Public Variables
## The player assigned to this client.
var player: Player:
	get:
		if Multiplayer.is_server:
			return player1
		
		return player

## The player assigned to the opponent client.
var opponent: Player:
	get:
		if Multiplayer.is_server:
			return player2
		
		return opponent

## The player whose turn it is.
var current_player: Player

## The opposing player to the player whose turn it is. Don't set this.
var opposing_player: Player:
	get:
		return current_player.opponent

## The player who starts first. ONLY ASSIGNED CLIENT SIDE.
var player1: Player:
	get:
		if Multiplayer.is_server:
			return _player1_server
		
		if not player:
			return null
		
		return player if player.id == 0 else opponent

## The player who starts with the coin. ONLY ASSIGNED CLIENT SIDE.
var player2: Player:
	get:
		if Multiplayer.is_server:
			return _player2_server
		
		if not player:
			return null
		
		return player if player.id == 1 else opponent

## If this client is [member player1].
var is_player_1: bool:
	get:
		if Multiplayer.is_server:
			return true
		
		return player.id == 0

## If this client is [member player2].
var is_player_2: bool:
	get:
		if Multiplayer.is_server:
			return false
		
		return player.id == 1

## Returns if it is currently the [member player]'s turn.
var is_players_turn: bool:
	get:
		return current_player == player

## The turn counter of the game.
var turn: int = 0

## Returns the board node
var board_node: BoardNode:
	get:
		return get_tree().root.get_node("Main/Board") as BoardNode

var instance_num: int = -1
#endregion


#region Private Variables
var _player1_server: Player
var _player2_server: Player
#endregion


#region Internal Functions
func _ready() -> void:
	# Add error label
	var error_label: RichTextLabel = RichTextLabel.new()
	error_label.bbcode_enabled = true
	error_label.fit_content = true
	error_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	error_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	error_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	error_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	error_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	error_label.anchors_preset = 14
	error_label.anchor_top = 0.5
	error_label.anchor_right = 1.0
	error_label.anchor_bottom = 0.5
	
	error_label.offset_top = -11.5
	error_label.offset_bottom = 11.5
	
	error_label.name = "ErrorLabel"
	get_tree().root.add_child.call_deferred(error_label, true)
	
	# Make debugging easier
	if OS.has_feature("editor"):
		var _instance_socket: TCPServer = TCPServer.new()
		
		for n: int in 3:
			if _instance_socket.listen(5000 + n) == OK:
				instance_num = n
				break

		assert(instance_num >= 0, "Unable to determine instance number. Seems like all TCP ports are in use")	
			
		match instance_num:
			0:
				# Instance 0 should host a server
				Multiplayer.host()
				# Wait since it makes moving the window a LOT more consistant.
				await get_tree().create_timer(0.1).timeout
				
				@warning_ignore("integer_division")
				get_window().position += Vector2i(get_window().size.x / 4, 0)
			1:
				# Instance 1 should join the server
				Multiplayer.join("localhost", 4545, "4/1:30/1")
				await get_tree().create_timer(0.1).timeout
				
				@warning_ignore("integer_division")
				get_window().position += Vector2i(-(get_window().size.x / 4), get_window().size.y / 4)
			2:
				# Instance 2 should join the server
				Multiplayer.join("localhost", 4545, "4/1:30/1")
				await get_tree().create_timer(0.1).timeout
				
				@warning_ignore("integer_division")
				get_window().position += Vector2i(-(get_window().size.x / 4), -(get_window().size.y / 4))

func _notification(what: int) -> void:
	# Save on quit.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		OS.set_restart_on_exit(false)
		Multiplayer.quit()
#endregion


#region Public Functions
## Starts the game. Assigns an id to each player and changes scene to the game scene.
## Only the server can do this.
func start_game() -> void:
	if not multiplayer.is_server():
		return
	
	# Create a random seed.
	# The seed function takes in a `uint32_t`. (Source: https://github.com/godotengine/godot/blob/a4fbe4c01f5d4e47bd047b091a65fef9f7eb2cca/core/math/math_funcs.cpp#L44)
	var seed: int = randi_range(0, 4_294_967_295)
	Multiplayer.seed_random.rpc(seed)
	
	var id: int = randi_range(0, Settings.server.max_players - 1)
	
	var i: int = 0
	for peer: int in multiplayer.get_peers():
		var player: Player = Player.new()
		var player_id: int
		
		if i == 0:
			player_id = id
		else:
			player_id = 1 - id
		
		player.id = player_id
		player.peer_id = peer
		Multiplayer.players[peer] = player
		
		if id == i:
			_player1_server = player
		else:
			_player2_server = player
		
		Multiplayer.assign_player.rpc_id(peer, player_id)
		
		print("Client %s assigned id: %s" % [peer, player_id])
		
		i += 1
	
	print("Sending config...")
	Multiplayer.send_config.rpc(
		Settings.server.max_board_space,
		Settings.server.max_hand_size,
		Settings.server.max_deck_size,
		Settings.server.min_deck_size,
	)
	
	print("Changing to game scene...")
	Multiplayer.change_scene_to_file.rpc("res://scenes/game/game.tscn")
	
	current_player = player1
	player1.empty_mana = 1
	player1.mana = 1
	
	var deckcodes: Dictionary = Multiplayer._deckcodes
	
	await wait_for_node("/root/Main")
	
	Game.current_player = Game.player1
	Game.player1.empty_mana = 1
	Game.player1.mana = 1
	
	Game.player1.deckcode = deckcodes[player1.peer_id].deckcode
	Game.player2.deckcode = deckcodes[player2.peer_id].deckcode
	
	for k: int in 2:
		var deckcode: String = Game.player1.deckcode if k == 0 else Game.player2.deckcode
		
		var player: Player = Player.get_from_id(k)
		var deck: Dictionary = Deckcode.import(deckcode, player, Multiplayer.is_server)
		
		player.hero_class = deck.hero.classes[0]
		player.deck = deck.cards
		
		player.draw_cards(3 if player.id == 0 else 4, false)
	
	Game.game_started.emit()
	
	for k: int in 2:
		var player: Player = Player.get_from_id(k)
		
		if k == 0:
			Multiplayer.start_game.rpc_id(player.peer_id, player.deckcode, deckcodes[player2.peer_id].cards.size())
		else:
			Multiplayer.start_game.rpc_id(player.peer_id, player2.deckcode, deckcodes[player1.peer_id].cards.size())
	
	# HACK: Wait until the 2nd player has 4 cards to spawn the coin.
	while player2.hand.size() < 4:
		await get_tree().create_timer(0.5).timeout
	
	Multiplayer.create_blueprint_from_id.rpc(2, player2.id, &"Hand", player2.hand.size())


## Sends a packet to end the [member current_player]'s turn. Returns if a packet was sent.
func end_turn() -> bool:
	if not is_players_turn:
		feedback("It is not your turn.", FeedbackType.ERROR)
		return false
	
	if not await Modules.request(Modules.Hook.END_TURN, [current_player]):
		return false
	
	Packet.send(&"End Turn", current_player.id, [], true)
	return true


## Makes [param text] pop up in the middle of the player's screen. Its color will be derived from [param type].
func feedback(text: String, type: FeedbackType) -> void:
	var error_label: RichTextLabel = get_tree().root.get_node("ErrorLabel") as RichTextLabel
	error_label.modulate.a = 1
	
	# Get color from `type`.
	var color: String = ""
	
	match type:
		FeedbackType.INFO:
			pass
		
		FeedbackType.WARNING:
			color = "yellow"
		
		FeedbackType.ERROR:
			color = "red"
		
		_:
			assert(false, "Invalid feedback type: %s" % type)
	
	error_label.text = "[center]%s%s" % [
		("[color=%s]" % color) if color else "",
		text,
	]
	
	# Wait 1 second
	await get_tree().create_timer(1.0).timeout
	
	# Fade out
	var tween: Tween = create_tween()
	tween.tween_property(error_label, "modulate:a", 0, 1)


## Waits for a node at the specified [param node_path] to exist before returning it.[br]
## Use [code]await[/code] on this.
func wait_for_node(node_path: NodePath) -> Node:
	while not get_node_or_null(node_path):
		await get_tree().create_timer(0.1).timeout
	
	return get_node(node_path)


## Exits to the lobby. You might want to use [code]Multiplayer.quit[/code] instead.
func exit_to_lobby() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/lobby.tscn")


## Exits to the main menu. You might want to use [code]Multiplayer.quit[/code] instead.
func exit_to_main_menu() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/main_menu.tscn")


## Returns [code]array[index][/code] if it exists, otherwise it returns [code]null[/code].
func get_or_null(array: Array, index: int) -> Variant:
	return array[index] if array.size() > index else null
#endregion


#region Private Functions
func _attack_attacker_is_player_and_target_is_player(attacker: Player, target: Player) -> void:
	# TODO: Implement.
	pass


func _attack_attacker_is_player_and_target_is_card(attacker: Player, target: Card) -> void:
	# TODO: Implement.
	pass


func _attack_attacker_is_card_and_target_is_player(attacker: Card, target: Player) -> void:
	attacker.has_attacked_this_turn = true
	
	var do_damage: Callable = func() -> void:
		target.damage(attacker.attack)
	
	# Animation
	if not Settings.client.animations:
		do_damage.call()
		return
	
	target.should_die = false
	
	# CRITICAL: Remove this.
	await LayoutModule.stabilize_layout_while(target.hero, func() -> void:
		await attacker.do_effects(func() -> void:
			var _old_position: Vector3 = attacker.global_position
			
			var tween: Tween = attacker.create_tween()
			tween.tween_property(attacker, "global_position", target.hero.global_position, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
			tween.tween_callback(func() -> void:
				do_damage.call()
				target.hero.attack_particles.restart()
			)
			tween.tween_property(attacker, "global_position", _old_position, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
			
			await target.hero.attack_particles.finished
		)
	, true)
	
	target.should_die = true


func _attack_attacker_is_card_and_target_is_card(attacker: Card, target: Card) -> void:
	attacker.has_attacked_this_turn = true
	
	var do_damage: Callable = func() -> void:
		target.health -= attacker.attack
		attacker.health -= target.attack
	
	# Animation
	if not Settings.client.animations:
		do_damage.call()
		return
	
	attacker.should_die = false
	target.should_die = false
	
	# CRITICAL: Remove this.
	await LayoutModule.stabilize_layout_while(target, func() -> void:
		await attacker.do_effects(func() -> void:
			var _old_position: Vector3 = attacker.global_position
			
			var tween: Tween = attacker.create_tween()
			tween.tween_property(attacker, "global_position", target.global_position, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
			tween.tween_callback(func() -> void:
				do_damage.call()
				
				target.attack_particles.restart()
				attacker.attack_particles.restart()
			)
			tween.tween_property(attacker, "global_position", _old_position, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
			
			await tween.finished
			await target.attack_particles.finished
		)
	, true)
	
	attacker.should_die = true
	target.should_die = true
#endregion
