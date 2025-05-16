class_name MainView extends View


func _ready() -> void:
    var join: Button = %Join
    join.pressed.connect(_on_join_game)


func _on_join_game() -> void:
    signals.connect_to_server.emit("localhost", 9000)
    despawn()
