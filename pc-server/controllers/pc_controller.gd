class_name PcController extends Controller

@onready var entities: EntityController:
    get(): return Global.controllers.find(EntityController)


func _ready() -> void:
    signals.create_pc_req.connect(_on_create_pc_req)
    signals.spawn_pc_req.connect(_on_spawn_pc_req)
    

func _on_get_all_pc_req() -> void:
    push_error("_on_get_all_pc_req is not implemented.")
    
    
func _on_create_pc_req(msg: CreatePcReq) -> void:
    print("Got new PC request:", msg)
    

func _on_spawn_pc_req(req: SpawnPcReq) -> void:
    print("Got PC spawn request:", req)
    
    var entity := entities.spawn(req.origin_peer)
    
    var resp := SpawnPcResp.new()
    resp.dest_peer = req.origin_peer
    resp.authority = req.origin_peer
    resp.id = entity.id
    resp.display_name = "temp"
    resp.zone = "temp"
    resp.instance = "temp"
    resp.coordinates = Vector3(1, 1, 1)
    
    if not resp.error:
        Network.server_send(Message.Action.spawn_pc_resp, resp)
