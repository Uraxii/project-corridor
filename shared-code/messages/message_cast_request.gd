class_name MessageCastRequest

var skill:  String
var caster: String
var target: String


func _init(skill_file: String, caster_node: String, target_node: String):
        self.skill  = skill_file
        self.caster = caster_node
        self.target = target_node
