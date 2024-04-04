A utility script responsible for handling blueprints in-editor.

- Ensures that all blueprints have different id's.
	- Whenever you open a blueprint scene, the blueprint manager will loop through all blueprints, order them by their id, ascending, and do these checks:
		- If the current blueprint has an id of 0, cause an error telling the editing user that the blueprint doesn't have a valid id.
		- If the current blueprint's id is equal to the last blueprint's id, cause an error telling the editing user that there are multiple blueprints with that id.
		- If the current blueprint's id is not equal to the expected id, cause an error telling the editing user that no blueprint with the expected id exists.
	- If you open a blueprint scene, and the blueprint has the id 0, the blueprint manager will try to assign an id to the blueprint automatically.