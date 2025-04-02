class_name Jumping extends Node

var cooldown:float = 0


static func cast(entity) -> String:
        if not entity.body:
                return 'Entity does not have body.'

        if entity.body.velocity.y != 0:
                return 'Entity cannot jump right now.'

        entity.body.velocity.y += entity.stats.current_jump_force

        entity.body.move_and_slide()

        return ''
