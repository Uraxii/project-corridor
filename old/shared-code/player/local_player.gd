class_name LocalPlayer extends Node

const CAMERA_SCENE := preload("res://shared-code/player/player_camera.tscn")

var camera: PlayerCamera
var input: PlayerInput
var authorities: Array[int] = []
var signals: SignalBus


func _ready() -> void:
    signals = Global.signal_bus
    
    camera = CAMERA_SCENE.instantiate()
    add_child(camera)
    
    input = PlayerInput.new()
    add_child(input)

    signals.set_authority.connect(_on_set_authority)


func _on_set_authority(entity: Entity, peer_id: int) -> void:
    print("Set authority of ", entity, " to peer ", peer_id)
    
    if peer_id != multiplayer.get_unique_id():
        return
        
    camera.set_target(entity)
    entity.input = input
