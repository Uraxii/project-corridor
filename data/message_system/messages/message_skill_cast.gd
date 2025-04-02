class_name MessageSkillCast extends MessageBase


func _init(ability: String, owner: Entity, target: Entity = null) -> void:
        self.ability = ability
        self.owner = owner
        self.target = target
