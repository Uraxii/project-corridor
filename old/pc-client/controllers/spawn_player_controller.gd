class_name SpawnPlayerController extends Controller


func get_type() -> String:
    return "SpawnPlayer"
    

func get_routes() -> Array[Dictionary]:
    return [{"type": "SpawnPlayerRequest", "handler": "_on_spawn_player"}]
    

func spawn_player(request: SpawnPcReq) -> void:
    Network.send(Message.Action.spawn_pc_req, request)


func _on_spawn_player_response(data: Dictionary) -> void:
    var response = SpawnPcResp.new()
    response.deserialize(data)
    
    if response.error:
        printerr("Could not spawn player:", response.error)
        return
        
    
