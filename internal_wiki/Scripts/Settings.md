An autoload node that stores the settings of the game.

It stores the settings in two dictionaries:
- Server Settings
	- Port - The port that that the server should be hosted on. (Default: `4545`)
	- Anticheat Level - How aggressive the anticheat is. The higher the value, the more strict. Negative values means max. (Default: `-1`)
	- Anticheat Consequence - What should happen if the anticheat gets triggered. (Default: `DROP_PACKET`)
		- `DROP_PACKET` - Ignore the cheated packet.
		- `KICK` - The same as `DROP_PACKET`, but also kicks the player who sent the packet.
		- `BAN` - The same as `KICK` but adds the player's IP address to a banlist that gets checked when a player attempts to join, and kicks them if they are on that list.
	- Ban List - A list of banned IP addresses. If a player attempts to join the game, and their IP address is on that list, they get kicked. (Default: `Empty`)
	- Max Board Space - The maximum amount of cards that can be on each side of the board at once. (Default: `7`)
	- Max Hand Size - The maximum amount of cards that can be in a player's hand at once. (Default: `10`)
	- Max Deck Size - The maximum amount of cards that can be in a deckcode. (Default: `30`)
	- Min Deck Size - The minimum amount of cards that can be in a deckcode. (Default: `30`)
	- Max Players - The maximum amount of players that can join. Right now, this is hardcoded in a *lot* of places, so I wouldn't recommend changing this. (Default: `2`)
- Client Settings
	- Fullscreen Mode - The `DisplayServer.WindowMode` of the game. (Default: `WINDOW_MODE_WINDOWED`)
	- Resolution - The resolution of the game in a `Vector2i` format. (Default: `1152x648`)
	- VSync - Whether vsync is enabled or not. (Default: `true`)
	- Animations - Whether animations are enabled or not. Disabling is experimental. (Default: `true`)
	- Card Bounds X - A variable used in the layout modules. This is how far to the right the cards should be. Only used in the `LayoutHand` module. (Default: `-3.05`)
	- Card Bounds Y - A variable used in the layout modules. This is how far away from the camera the cards should be. Only used in the `LayoutHand` module. (Default: `-0.5`)
	- Card Bounds Z - A variable used in the layout modules. This is how far up / down the cards are. Only used in the `LayoutHand` module. (Default: `13.0`)
	- Card Rotation Y Multiplier - How much the cards should be rotated by. Scales based on the card's distance from the middle of the player's hand. Sometimes called `CRYM`. Only used in the `LayoutHand` module. (Default: `10.0`)
	- Card Distance X - A variable used in the layout modules. This is how far apart the cards are. Only used in the `LayoutHand` and `LayoutBoard` modules. (Default: `1.81`)