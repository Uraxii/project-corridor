class_name MainMenu extends Node

@onready var start:     Button = %Start
@onready var join:      Button = %Join


func _ready() -> void:
        start.pressed.connect(host_game)
        join.pressed.connect(join_game)


func host_game() -> void:
        if not NetworkManager.singleton:
                print('No networkmanager')
                return

        NetworkManager.singleton.start_game()

        queue_free.call_deferred()


func join_game() -> void:
        if not NetworkManager.singleton:
                print('No networkmanager')
                return

        NetworkManager.singleton.join_game()

        queue_free.call_deferred()
