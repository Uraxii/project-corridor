class_name EntityController extends Controller

@onready var pc_scene := preload(
    "res://shared-code/entities/player/player.tscn")

var spawner: Node = EntityContainer
var entities: Dictionary[int, Entity] = {}

var _next_id: int = 1
var _released_ids = []


func _get_next_id() -> int:
    var id := -1

    if _released_ids.size() > 0:
        id = _released_ids.pop_front()
    else:
        id = _next_id
        _next_id += 1
        
    return id
    

func unregister_entity(entity: Entity):
    entities.erase(entity.id)


func find(entity_id: int) -> Entity:
    return entities.get(entity_id)
    

func spawn(authority_peer_id: int, entity_id: int = 0) -> Entity:
    var new_entity: Entity = pc_scene.instantiate()
    
    if entity_id == 0:
        entity_id = _get_next_id()

    new_entity.id = entity_id
    set_multiplayer_authority(entity_id, authority_peer_id)
    new_entity.position = Vector3(1, 10, 1)
    spawner.add_child(new_entity)
    
    signals.set_authority.emit(new_entity, authority_peer_id)
    signals.spawn_entity.emit(new_entity)
    
    return new_entity


func despawn(entity_id: int) -> void:
    var entity := find(entity_id)
    
    if not entity:
        return
        
    signals.despawn_entity.emit(entity)
    
    entities.erase(entity_id)
    _released_ids.append(entity_id)
    entity.despawn()


func set_authority(entity_id: int, peer_id: int) -> void:
    var entity := find(entity_id)
    
    if not entity:
        return
    
    entity.set_multiplayer_authority(peer_id)
    signals.set_authority.emit(entity, peer_id)
