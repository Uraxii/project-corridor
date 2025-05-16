class_name UserService extends Controller

var signal_bus := Global.signal_bus


func _ready() -> void:
    signal_bus.login_req.connect(_on_login_req)
    

func get_routes() -> Array[Dictionary]:
    return [{"type": "login", "handler": "_on_login"}]


func _on_login_req(req: LoginReq) -> void:
    print("new login_req")
    var resp := LoginResp.new()

    if req.username != "" and req.password != "":
        resp.session_token = "insecure"
        resp.success = true
        Network.register_client(req.origin_peer, resp.session_token)
    else:
        resp.session_token = ""
        resp.success = false
        
    resp.dest_peer = req.origin_peer

    Network.server_send(Message.Action.login_resp, resp)
