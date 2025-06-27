class_name MainView extends View


func _ready() -> void:
    var join: Button = %Join
    join.pressed.connect(_on_join_game)


func _on_join_game() -> void:
    #WS.connect_to_url("localhost", 5000)
    API.status()  
