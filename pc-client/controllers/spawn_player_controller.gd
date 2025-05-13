class_name SpawnPlayerController extends Controller


func get_type() -> String:
    return "SpawnPlayer"
    

func get_routes() -> Array[Dictionary]:
    return [{"type": "SpawnPlayerRequest", "handler": "_on_spawn_player"}]


func spawn_player(request: SpawnPlayerRequest) -> void:
    var response_signal := Network.send("SpawnPlayer", request)
    response_signal.connect(_on_spawn_player_response)


func _on_spawn_player_response(data: Dictionary) -> void:
    var response = SpawnPlayerResponse.new()
    response.deserialize(data)
    
    if response.error:
        printerr("Could not spawn player:", response.error)
        return
    
    Signals.load_world.emit(
        response.display_name, response.coordinates, response.zone)
