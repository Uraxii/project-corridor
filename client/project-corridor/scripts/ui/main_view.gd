class_name MainView extends View


func _ready() -> void:
    var join: Button = %Join
    join.pressed.connect(_on_join_game)
    signals.api_status_passed.connect(_on_api_status_result)


func _on_join_game() -> void:
    #WS.connect_to_url("localhost", 5000)
    API.status()  


func _on_api_status_result() -> void:
    despawn()
    Globals.views.spawn(LoginView)
