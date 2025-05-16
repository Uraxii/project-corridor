class_name PlayerCharacterService extends Controller

var signal_bus := Global.signal_bus


func _ready() -> void:
    signal_bus.create_pc_req.connect(_on_create_pc_req)
    

func _on_get_all_pc_req() -> void:
    push_error("_on_get_all_pc_req is not implemented.")
    
    
func _on_create_pc_req(msg: CreatePcReq) -> void:
    print("Got new PC request:", msg)
