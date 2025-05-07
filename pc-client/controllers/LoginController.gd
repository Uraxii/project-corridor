class_name LoginController extends Node

signal login_success
signal login_failed(reason: String)

var model := LoginResponse.new()

func _ready() -> void:
    Network.message_received.connect(_on_message_received)
    

func login(username: String, password: String) -> void:
    Network.send({
        "type": "login",
        "username": username,
        "password": password
    })


func _on_message_received(msg: Dictionary):
    if msg.get("type") != "login_response":
        return
        
    if not msg.get("success", false):
        login_failed.emit("Invalid username or password")
        return
        
    model.username = msg.get("username", "")
    model.session_token = msg.get("session_token", "")
    model.is_logged_in = true
    login_success.emit()
