class_name MessageCastResult

const INIT:             String = 'init'
const SUCCESS:          String = ''
const NO_MANA:          String = 'no mana'
const NO_ENERGY:        String = 'no energy'
const NO_RAGE:          String = 'no rage'
const ON_COOLDOWN:      String = 'on cooldown'
const INVALID_TARGET:   String = 'invalid target'
const OUT_OF_RANGE:     String = 'target out of range'
const CANCELED:         String = 'canceled'

const PROPERTIES: Array[String] = [
        'message',
        'success',
        'skill',
        'caster',
        'target',
]

var message:            String

var success:            String

var skill:              String
var caster:             String
var target:             String

var damage:             float
var heal:               float
var apply_status:       String

var status_type:        String
var status_remaining:   float
var status_exipired:    bool


func _init(
        skill_file:             String  = '',
        caster_node:            String  = '',
        target_node:            String  = '',
        success_value:          String  = INIT,
        damage_amount:          float   = 0,
        heal_amount:            float   = 0,
        status_to_apply:        String  = '',
        status_effect_type:     String = '',
        remaining_status_time:  float = 0,
) -> void:
        self.success            = success_value

        self.skill              = skill_file
        self.caster             = caster_node
        self.target             = target_node

        self.damage             = damage_amount
        self.heal               = heal_amount
        self.apply_status       = status_to_apply

        self.status_type        = status_effect_type
        self.status_remaining   = remaining_status_time


func generate_log():
        if not success:
                return '%s did not cast %s on %s. Reason: %s' % [caster, skill, target, success]

        message = '%s casted %s on %s' % [caster, skill, target]
