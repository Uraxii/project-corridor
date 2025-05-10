class_name PlayerIdleState extends PlayerState


func frame_update(entity:Player) -> void:
        super.frame_update(entity)

        if entity.body.velocity.y < 0:
                transition.emit(self, 'falling')
        elif entity.input.move != Vector2.ZERO:
                transition.emit(self, 'move')
        elif entity.input.jump:
                 transition.emit(self, 'jump')
