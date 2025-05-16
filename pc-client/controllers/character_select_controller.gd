class_name CharacterSelectController extends Controller


func _ready() -> void:
    signals.create_pc_resp.connect(_on_new_pc_resp)
    

func get_routes() -> Array[Dictionary]:
    return [{"type": "get_characters", "handler": "get_characters"}]


func get_characters() -> void:
    pass
    #push_error("Not implemented!")
    

func new_character() -> void:
    var req := CreatePcReq.new()
    req.display_name = "New Character"
    Network.client_send(Message.Action.create_pc_req, req)


func _on_new_pc_resp(msg: CreatePcReq) -> void:
    print(msg)
