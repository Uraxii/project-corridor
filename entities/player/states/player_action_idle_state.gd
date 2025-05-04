class_name PlayerActionIdleState

extends PlayerState


func frame_update(entity: Player) -> void:
        for ability in entity.input.actions.keys():
                if entity.input.actions[ability].call():
                        entity.keybinds[ability].execute(entity)
