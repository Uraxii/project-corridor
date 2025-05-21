class_name CharacterSelectController extends Controller

@onready var entities: EntityController:
    get(): return Global.controllers.find(EntityController)


func _ready() -> void:
    signals.create_pc_resp.connect(_on_new_pc_resp)
    signals.spawn_pc_resp.connect(_on_spawn_pc_resp)
    

func get_routes() -> Array[Dictionary]:
    return [{"type": "get_characters", "handler": "get_characters"}]


func get_characters() -> void:
    push_error("Not implemented!")
    

func spawn_pc(charecter_id: String) -> void:
    var req := SpawnPcReq.new()
    req.character_id = charecter_id
    Network.client_send(Message.Action.spawn_pc_req, req)


func new_character() -> void:
    var req := CreatePcReq.new()
    req.display_name = "New Character"
    Network.client_send(Message.Action.create_pc_req, req)


func _on_new_pc_resp(resp: CreatePcResp) -> void:
    print("Got new PC response:", resp)
    

func _on_spawn_pc_resp(resp: SpawnPcResp) -> void:
    print("Got spawn PC response:", resp)
    
    if resp.error:
        return
    
    entities.spawn(resp.authority, resp.id)

    signals.load_world.emit()
