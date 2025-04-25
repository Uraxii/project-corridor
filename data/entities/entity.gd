class_name Entity extends Node3D

signal changed_target(entity: Entity)
signal targeted
signal untargeted

const INVALID_ID:       int = -1

const TEAM_PARTY:       int = 0
const TEAM_FRIEND_NPC:  int = 1
const TEAM_ENEMY:       int = 2
const TEAM_NEUTRAL:     int = 3

@export var config_file: String = "{CONFIG_FILE}"
@export var body: CharacterBody3D
@export var state_machines: Array[StateMachine]
@export var team_id: int = 0

@onready var stats: EntityData = %Stats
@onready var visual: MeshInstance3D = %Visual

var move: Movement

var network_info: PlayerInfo

var skin_color: Color
var body_mesh: Mesh

var skills: Dictionary[String, Skill] = {}
var status_effects: Dictionary[String, Skill] = {}

var target:           Entity    = self
var alternate_target: String    = name
var focus_target:     String    = name


#region Godot Callback Functions
func _ready() -> void:
        stats.load(config_file)

        stats.display_name = 'Player-' + name

        if stats.can_move and body:
                move = Movement.new(self, body)

        for machine in state_machines:
                machine.entity = self

        GameManager.register_entity(self)


func _process(delta: float) -> void:
        for machine in state_machines:
                machine.process_frame()


func _physics_process(delta: float) -> void:
        for machine in state_machines:
                machine.process_physics()

        if move:
                move.move_entity(delta)
#endregion


func load_skill(skill_id: String) -> Skill:
        var skill = Skill.new(skill_id)

        if not skill:
                Logger.warn('Unable to locate skill ', {'skill id':skill_id})
                return

        add_child.call_deferred(skill)
        skills[skill_id] = skill

        return skill


func apply_status_effect(skill: Skill) -> void:
        # print('Applied %s on %s' % [skill.id, current.display_name])
        status_effects[skill.file] = skill
