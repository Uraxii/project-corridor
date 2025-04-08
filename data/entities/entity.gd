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
@export var team_id: int = 0

@onready var base:      EntityData = %Base
@onready var current:   EntityData = %Current

var move: Movement

var id: int = get_instance_id()

var network_info: PlayerInfo

var skin_color: Color
var body_mesh: Mesh

var abilities: Dictionary = { }

var status_effects: Array[Skill] = []

var target:           Entity    = self
var alternate_target: int       = id
var focus_target:     int       = id


func _ready() -> void:
        base.load(config_file)
        current.load(config_file)

        if current.can_move and body:
                move = Movement.new(self, body)

        for machine in state_machines:
                machine.entity = self

        GameManager.register_entity(self)

        Server.network_tick.connect(network_update)


func frame_update(delta: float) -> void:
        for machine in state_machines:
                machine.process_frame()


func physics_update(delta: float) -> void:
        for machine in state_machines:
                machine.process_physics()

        if move:
                move.move_entity(delta)


func network_update() -> void:
        if get_multiplayer_authority() != multiplayer.get_unique_id():
                return

        update_network_info.rpc(id, position, rotation)


@rpc("authority", "call_local")
func update_network_info(id: int, position: Vector3, rotation: Vector3) -> void:
        network_info = PlayerInfo.new(id, position, rotation)


func get_display_name() -> String:
        return current.display_name


func set_display_name(display_name) -> String:
        current.display_name = display_name
        return current.display_name


func get_target() -> Entity:
        return target


func set_target(new_target: Entity) -> void:
        target = new_target
        changed_target.emit(new_target)


func get_health() -> float:
        return current.health


func modify_health(amount: float) -> float:
        if current.health + amount > base.health:
                current.health = base.health
        elif current.health + amount < 0:
                current.health = 0
        else:
                current.health += amount

        return current.health


func get_speed() -> float:
        return current.speed


func reset_speed() -> float:
        current.speed = base.speed
        return current.speed


func get_jump_force() -> float:
        return current.jump_force


func can_air_jump() -> bool:
        return current.air_jumps > 0 and current.can_air_jump


func decrement_air_jumps() -> int:
        if current.air_jumps <= 0:
                current.air_jumps = 0
        else:
                current.air_jumps -= 1

        return current.air_jumps


func get_air_control() -> float:
        return current.air_control


func reset_air_jumps() -> int:
        current.air_jumps = base.air_jumps
        return current.air_jumps


func get_gravity_scale() -> float:
        return current.gravity_scale


func reset_gravity_scale() -> float:
        current.gravity_scle = base.gravity_scale
        return current.gravity_scale


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
