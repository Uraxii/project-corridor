class_name MainMenu extends Node

@onready var start:     Button = %Start
@onready var join:      Button = %Join


func _ready() -> void:
        start.pressed.connect(host_game)
        join.pressed.connect(join_game)


func host_game() -> void:
        Server.start_server()
        Server.load_world()
        self.visible = false



func join_game() -> void:
        Server.start_client()
        Server.load_world()
        self.visible = false
