class_name MainMenu extends Node

@onready var start:     Button = %Start
@onready var join:      Button = %Join


func _ready() -> void:
        start.pressed.connect(host_game)
        join.pressed.connect(join_game)


func host_game() -> void:
        Network.start_server(
                Network.DEFAULT_PORT,
                Network.DEFAULT_MAX_PEERS,
                true
        )
        #Network.load_world()
        self.visible = false



func join_game() -> void:
        Network.start_client(Network.DEFAULT_SERVER_IP, Network.DEFAULT_PORT)
        #Network.load_world()
        self.visible = false
