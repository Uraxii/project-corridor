class_name AOE extends Area3D

var skill: SkillNew = null
var caster: Entity = null

var entities_in_area: Array[Entity] = []


func _ready() -> void:
    Logger.debug("Hello from AOE!")
    area_entered.connect(_on_area_entered)
    area_exited.connect(_on_area_exited)


func initialize(skill_file: String, skill_caster: Entity) -> void:
    skill = SkillNew.load(skill_file)
    caster = skill_caster


func _on_area_entered(area: Area3D) -> void:
    if not skill:
        return


    var target: Entity = _get_entity_from_area(area)

    if not target:
        return

    GameManager.queue_targeted_cast(skill.id, caster.name, target.name)


func _on_area_exited(_area: Area3D) -> void:
    if not skill:
        return



func _get_entity_from_area(area: Area3D) -> Entity:
    var parent = area.get_parent()

    if parent is not Entity:
        return null

    return parent as Entity
