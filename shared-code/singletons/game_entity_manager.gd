class_name GameEntityManager extends Node

signal register_new_entity(entity: Entity)
signal unregister_entity(entity: Entity, id: int)

const INVALID_ID := -1

var entities: Dictionary[int, Entity] = {}

var last_id := 0
var released_ids: Array[int] = []


func register(entity: Entity) -> void:
    var id := _get_next_id()
        
    entities[id] = entity
    
    register_new_entity.emit(entity)
    
    #Logger.info('Registerd entity.',
    #    {'Display Name':entity.stats.display_name,'Node Name':entity.name})


func unregister(id: int) -> void:
    var entity: Entity = entities.get(id)
    
    if entities.erase(id):
        released_ids.append(id)
        unregister_entity.emit(entity, id)
        
        
    

func _get_next_id() -> int:
    if released_ids.size() > 0:
        return released_ids.pop_front()
    
    last_id += 1
    
    return last_id
