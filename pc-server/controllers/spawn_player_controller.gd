class_name SpawnPlayerController extends Controller


func get_type() -> String:
    return "SpawnPlayer"

    
func get_routes() -> Array[Dictionary]:
    return [{"type": "SpawnPlayer", "handler": "_on_spawn_player"}]


func _on_spawn_player(req: SpawnPcReq) -> Dictionary:
    print("Spawn Character Req:", req)
    
    # TODO: AuthZ + AuthN.
    
    var response = SpawnPcResp.new()
    
    if req.display_name == "":
        response.error = "Character does not exist."
        return response.serialize()
        
    response.coordinates = Vector3(1, 1, 1)
    response.display_name = "Nooby"
    response.zone = "start"
    return response.serialize()
