class_name LoginController extends Controller


func _ready() -> void:
    signals.login_resp.connect(_on_login_resp)


func get_type() -> String:
    return "login"


func get_routes() -> Array[Dictionary]:
    return [{"type": "login_response", "handler": "_on_login_response"}]


func login(login_request: LoginReq) -> void:
    Network.client_send(Message.Action.login_req, login_request)


func _on_login_resp(resp: LoginResp):
    print("login response:", resp.serialize())
    if resp.success:
        Network.set_client_session_token(resp.session_token)
        
    #signals.login.emit(resp)
