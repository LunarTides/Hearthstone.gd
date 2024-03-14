@tool
extends EditorScript
## A tool to create a [Blueprint] easily.
## @experimental


func _run() -> void:
	if DirAccess.make_dir_absolute("res://cards/rename_me") != OK:
		push_error("An error occurred when creating the directory: `res://cards/rename_me`.")
		return
	
	var script: FileAccess = FileAccess.open("res://cards/rename_me/rename_me.gd", FileAccess.WRITE)
	script.store_string("""extends Blueprint


# Called when the card is created
func setup() -> void:
	card.add_ability(&"Battlecry", battlecry)


func battlecry() -> int:
	print_debug("Battlecry")
	
	return SUCCESS
""")
	
	script.close()
	
	var uid: String = ResourceUID.id_to_text(ResourceUID.create_id())
	
	var scene: FileAccess = FileAccess.open("res://cards/rename_me/rename_me.tscn", FileAccess.WRITE)
	scene.store_string("""[gd_scene load_steps=3 format=3 uid="uid://%s"]

[ext_resource type="Script" path="res://cards/rename_me/rename_me.gd" id="1_scrip"]
[ext_resource type="PackedScene" uid="uid://ccmb7s7hsvhju" path="res://scenes/card.tscn" id="2_cardd"]

[node name="RenameMe" type="Node3D" node_paths=PackedStringArray("card")]
script = ExtResource("1_scrip")
card = NodePath("Card")

[node name="Card" parent="." instance=ExtResource("2_cardd")]
""" % uid)
	
	scene.close()
	
	print("Card Created at `res://cards/rename_me/`. Please wait for the Godot File Explorer to update...")
