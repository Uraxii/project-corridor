class_name LoginController extends Controller


func _ready() -> void:
    Signals.login_req.connect(_on_login_req)
    

func get_routes() -> Array[Dictionary]:
    return [{"type": "login", "handler": "_on_login"}]


func _on_login_req(req: LoginReq) -> void:
    var resp := LoginResp.new()

    if req.username != "" and req.password != "":
        resp.session_token = "insecure"
        resp.success = true
    else:
        resp.session_token = ""
        resp.success = false
        
    resp.dest_peer = req.origin_peer

    Network.server_send(Message.Action.login_resp, resp)
