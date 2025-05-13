class_name LoginController extends Controller


func get_type() -> String:
    return "login"


func get_routes() -> Array[Dictionary]:
    return [{"type": "login_response", "handler": "_on_login_response"}]


func login(login_request: LoginRequest) -> void:
    var completed_signal := Network.send("login", login_request)
    completed_signal.connect(_on_login_response)


func _on_login_response(data: Dictionary):
    var resp := LoginResponse.new()
    resp.deserialize(data)
    Signals.login.emit(resp)
