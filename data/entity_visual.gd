class_name EntityVisual extends Node3D

@onready var body: CharacterBody3D = %Body


func _process(delta: float) -> void:
        global_position = body.global_position
        global_rotation = body.global_rotation
