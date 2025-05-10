class_name MainMenu extends View


func _ready() -> void:
    var join: Button = %Join
    join.pressed.connect(_on_join_game)


func get_type() -> String:
    return "main"


func _on_join_game() -> void:
    Signals.connect_to_server.emit("localhost", 9000)
    hide()
