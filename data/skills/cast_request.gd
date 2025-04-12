class_name CastRequest

# Property Name: Expected Type
const SCHEMA: Dictionary[String, int] = {
        "skill":  TYPE_STRING,
        "caster": TYPE_STRING,
        "target": TYPE_STRING,
}

var skill:  String = ""
var caster: String = ""
var target: String = ""


func load(skill_file: String, caster_node: String, target_node: String):
        skill  = skill_file
        caster = caster_node
        target = target_node


func serialize() -> Dictionary:
        return Serializer.serialize(self, SCHEMA)


func deserialize(data: Dictionary) -> CastResult:
        return Serializer.deserialize(self, SCHEMA, data)
