class_name MainMenu extends Control

@onready var join:  Button = %Join


func _ready() -> void:
        join.pressed.connect(join_game)


func join_game() -> void:
        Network.connect_to_server()
        hide()
