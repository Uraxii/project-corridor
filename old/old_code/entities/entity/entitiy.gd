class_name Entity extends Node3D

var id: int = Entities.INVALID_ID
var data: EntityData


func setup(instance_id: int, entity_data: EntityData) -> void:
    id = instance_id
    data = entity_data.duplicate()


func despawn() -> void:
    # Gives everything until the end of the frame to handle this entity despawning.
    await get_tree().process_frame
    
    queue_free()
