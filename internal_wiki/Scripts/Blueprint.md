The blueprint is a node that a card is created from.

## Example
It is a bit difficult to explain so let's just look at an example:
Say we have a Sheep. A Sheep is a 1 cost, 1/1 Beast Minion. Once a sheep is added to your hand, it may be modified. For example, the sheep may gain +1/+1 stats.
The blueprint is the initial values, and should not be changed.
A [[Card]] starts with the initial values defined by its blueprint, but the [[Card]] can actually change later on.

## Usage
The blueprint node is the root of a card scene (e.g. `res://cards/sheep/sheep.tscn`), and you can change the individual members from the Godot Inspector when having it selected.

Every blueprint needs it's own id, since it is the only thing that separates blueprints from each other since names are not unique. Blueprints needs to be unique so that they can be referenced in, for example, deckcodes. Assigning an id is usually done by the [[Blueprint Manager]].

## Notes
Every card gets given its own blueprint node for convenience, but it would be optimal for every card of the same blueprint to link to the same blueprint.

The card script file extends Blueprint. The blueprint contains members for all core card things, like cost. Things that are defined in modules, like [[Tribe Module]] go in `Blueprint.modules["arbitrary name decided by the module"]`.