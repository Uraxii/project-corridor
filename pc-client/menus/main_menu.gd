class_name MainMenu extends Node

@onready var join:  Button = %Join


func _ready() -> void:
        join.pressed.connect(join_game)


func join_game() -> void:
        Client.start()
        self.visible = false
