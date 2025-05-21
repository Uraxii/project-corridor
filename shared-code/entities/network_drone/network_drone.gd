class_name NetworkDrone extends Entity


func _ready() -> void:
        super._ready()


func frame_update(delta: float) -> void:
        super.frame_update(delta)


func physics_update(delta: float) -> void:
        super.physics_update(delta)

        if network_info.owner not in GameManager.entities.keys():
                queue_free()

        network_info = GameManager.entities[network_info.owner].network_info

        if body.rotation.distance_to(network_info.direction) > 0.1:
                body.rotation = network_info.direction

        if body.position.distance_to(network_info.position) > 0.1:
                move.move_towards(network_info.position, current.speed)
