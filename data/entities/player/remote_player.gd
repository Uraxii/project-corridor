#class_name RemotePlayer extends Entity
#
#var player_info: PlayerInfo
#
#
#func _ready() -> void:
        #super._ready()
#
#
#func frame_update(delta: float) -> void:
        #super.frame_update(delta)
#
#
#func physics_update(delta: float) -> void:
        #super.physics_update(delta)
#
        #if player_info.owner not in Server.connections.keys():
                #queue_free()
#
        ## player_info = Server.connections[player_info.owner]
#
        #if body.rotation.distance_to(player_info.direction) > 0.1:
                #body.rotation = player_info.direction
#
        #if body.position.distance_to(player_info.position) > 0.1:
                #move.move_towards(player_info.position, current.speed)
