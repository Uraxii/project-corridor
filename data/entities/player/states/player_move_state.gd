class_name PlayerMoveState extends PlayerState

var direction   := Vector3.ZERO
var velocity    := Vector3.ZERO


func frame_update(entity: Player) -> void:
        entity.move.move_with_input(entity.input.move, entity.get_speed())

        if entity.input.jump:
                transition.emit(self, 'jump')
        elif entity.input.move == Vector2.ZERO:
               transition.emit(self, 'idle')
