class_name EntityManager extends Node

signal spawn_new_entity(entity: Entity)
signal despawn_entity(entity: Entity, id: int)

const ENITY_SCENE: PackedScene = preload(
    "res://shared-code/entities/entity/entitiy.tscn")
const INVALID_ID := -1

var entities: Dictionary[int, Entity] = {}

var last_id := 0
var released_ids: Array[int] = []


func _ready() -> void:
    NetCmd.spawn_entity.connect(_on_spawn_entity)
    NetCmd.despawn_entity.connect(_on_despawn_entity)


func _on_spawn_entity(data: EntityData, location: Vector3) -> Entity:
    var entity = ENITY_SCENE.instantiate()
    var id := _get_next_id()
    entity.setup(id, data)
    entity.position = location
    
    entities[id] = entity
    
    spawn_new_entity.emit(entity)
    
    #Logger.info('spawned entity.',
    #    {'Display Name':entity.stats.display_name,'Node Name':entity.name})
    
    return entity


func _on_despawn_entity(id: int) -> void:
    var entity: Entity = entities.get(id)
    
    entities.erase(id)
    released_ids.append(id)
    
    if entity:
        despawn_entity.emit(entity, id)
        entity.despawn()


func _get_next_id() -> int:
    if released_ids.size() > 0:
        return released_ids.pop_front()
    
    last_id += 1
    
    return last_id
