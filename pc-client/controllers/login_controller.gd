class_name LoginController extends Controller


func get_type() -> String:
    return "login"


func get_routes() -> Array[Dictionary]:
    return [{
        "message_type": "login_response",
        "handler_method": "handle_response"}]


func login(login_request: LoginRequest) -> void:
    var completed_signal := Network.send("login", login_request.serialize())
    completed_signal.connect(_on_response)


func _on_response(data: Dictionary):
    var resp := LoginResponse.new()
    resp.deserialize(data)
    Signals.login.emit(resp)
