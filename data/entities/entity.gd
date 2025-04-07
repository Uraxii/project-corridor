class_name Entity extends Node3D

signal changed_target(entity: Entity)

const INVALID_ID:       int = -1

const TEAM_PARTY:       int = 0
const TEAM_FRIEND_NPC:  int = 1
const TEAM_ENEMY:       int = 2
const TEAM_NEUTRAL:     int = 3

@export var config_file: String = "{CONFIG_FILE}"
@export var body: CharacterBody3D
@export var state_machines: Array[StateMachine]
@export var ability_container: Node
@export var team_id: int = 0

var id: int = INVALID_ID

var data: EntityData

var skin_color: Color
var body_mesh: Mesh

var abilities: Dictionary = { }

var status_effects: Array[Skill] = []


var target:           Entity    = null
var alternate_target: int       = INVALID_ID
var focus_target:     int       = INVALID_ID

var is_moving:        bool      = false
var is_jumping:       bool      = false


func _ready() -> void:
        data = EntityData.new(config_file)

        id = GameManager.register_entity(self)

        for machine in state_machines:
                machine.entity = self


func _process(delta):
        for machine in state_machines:
                machine.process_frame()


func _physics_process(delta):
       # _update_world_state(EntityWorldState.new(multiplayer.get_unique_id(), body.position, body.rotation))

        for machine in state_machines:
                machine.process_physics()


func set_target(new_target: Entity) -> void:
        target = new_target
        changed_target.emit(new_target)


func load_ability(ability_name: String) -> Node:
        var resource_path = 'res://data/skills/abilities/'+ ability_name + '/' + ability_name + '.tscn'
        var scene = load(resource_path)

        if not scene:
                print('Unable to locate ability ' + resource_path)
                return

        var node = scene.instantiate()
        if not node:
                print('Unable to instantiate node for ability ' + ability_name)

        add_child.call_deferred(node)

        abilities[ability_name] = node

        return node


func load_skill(skill_id: String) -> Skill:
        var skill = Skill.new(skill_id)

        if not skill:
                print('Unable to locate skill ' + skill_id )
                return

        add_child.call_deferred(skill)
        abilities[skill_id] = skill

        return skill


func apply_status_effect(skill: Skill) -> void:
        print('applied %s' % [skill.id])
        status_effects.append(skill)
