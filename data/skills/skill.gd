class_name Skill extends Node

### DATA VALUES ###
var id:                 String
var description:        String
var icon:               ImageTexture

var cost_mana:          float
var cost_rage:          float
var cost_energy:        float

var cooldown:           float

var charges:            int

var cast_range:         float
var cast_time:          float
var is_on_gcd:          bool

var can_target_self:    bool
var can_target_friend:  bool
var can_target_enemy:   bool

var impact_radius:      float

var damage_amount:      float

var heal_amount:        float

var slow:               float
var speed_boost:        float

var teleport_range:     float

### BUFF / DEBUFF / EFFECT OVER TIME ###
var apply_status_effect: String

var effect_type:                String
var effect_duration:            float
var effect_remaining_time:      float
var effect_timer:               Timer
var effect_caster:              Entity

# Skill name, percentage to trigger the skill
var trigger_free_cast:  Dictionary

### ANIMATION FILES ###
var anim_charge:        String
var anim_cast:          String
var anim_cast_success:  String

### SOUND FX FILES ###
var sfx_cast_start:     String
var sfx_cast:           String
var sfx_cast_success:   String


func _init(skill_name: String) -> void:
        var config = ConfigFile.new()
        config.load("res://data/skills/data/%s.cfg" % skill_name.to_lower())

        self.id                 = config.get_value('data', 'id', '')
        self.description        = config.get_value('data', 'description', '')

        var icon_file: String = config.get_value('data', 'icon_file', 'skill_default_icon')
        var icon_image = Image.load_from_file('res://art/icons/' + icon_file + '.png')
        self.icon = ImageTexture.create_from_image(icon_image)

        self.cost_mana          = config.get_value('data', 'cost_mana', 0.0)
        self.cost_rage          = config.get_value('data', 'cost_rage', 0.0)
        self.cost_energy        = config.get_value('data', 'cost_energy', 0.0)
        self.cast_range         = config.get_value('data', 'cast_range', 0.0)

        self.cooldown           = config.get_value('data', 'cooldown', 0.0)

        self.charges            = config.get_value('data', 'charges', 0)

        self.cast_time          = config.get_value('data', 'cast_time', 0.0)
        self.is_on_gcd          = config.get_value('data', 'is_on_gcd', true)

        self.can_target_self    = config.get_value('data', 'can_target_self', false)
        self.can_target_friend  = config.get_value('data', 'can_target_friend', false)
        self.can_target_enemy   = config.get_value('data', 'can_target_enemy', false)

        self.impact_radius      = config.get_value('data', 'impact_radius', 0.0)

        self.damage_amount      = config.get_value('data', 'damage_amount', 0.0)

        self.heal_amount        = config.get_value('data', 'heal_amount', 0.0)

        self.slow               = config.get_value('data', 'slow', 0.0)
        self.speed_boost        = config.get_value('data', 'speed_boost', 0.0)

        self.teleport_range     = config.get_value('data', 'teleport_range', 0.0)

        self.apply_status_effect        = config.get_value('data', 'apply_status_effect', '')
        self.effect_type                = config.get_value('data', 'effect_type', '')
        self.effect_duration            = config.get_value('data', 'effect_duration', 0.0)
        self.effect_remaining_time      = config.get_value('data', 'effect_remaining_time', 0.0)

        self.trigger_free_cast  = config.get_value('data', 'trigger_free_cast', {})

        self.anim_charge        = config.get_value('anim', 'anim_charge', "")
        self.anim_cast          = config.get_value('anim', 'anim_cast', "")
        self.anim_cast_success  = config.get_value('anim', 'anim_cast_success', "")

        self.sfx_cast_start     = config.get_value('sfx', 'sfx_cast_start', "")
        self.sfx_cast           = config.get_value('sfx', 'sfx_cast', "")
        self.sfx_cast_success   = config.get_value('sfx', 'sfx_cast_success', "")

        self.effect_timer = Timer.new()


static func cast(skill: Skill, caster: Entity, target: Entity) -> String:
        # print('Casting %s' % [skill.id])

        if target == null:
                target = caster

        if not is_target_valid(skill, caster, target):
                return 'Invalid target.'

        var cast_result = ''

        if skill.heal_amount != 0:
                heal_entity(target, skill.heal_amount)
                cast_result += 'healing %d health, ' % [skill.heal_amount]

        if skill.damage_amount != 0:
                damage_entity(target, skill.damage_amount)
                cast_result += 'dealing %d damage, ' % [skill.damage_amount]

        if not skill.apply_status_effect.is_empty():
                var status_effect = Skill.new(skill.apply_status_effect)
                status_effect.effect_caster = caster
                status_effect.effect_remaining_time = status_effect.effect_duration
                target.apply_status_effect(status_effect)

        if not skill.effect_type.is_empty():
                skill.effect_remaining_time -= Server.tick_interval

                if skill.effect_remaining_time <= 0:
                        var status_effect_index = target.status_effects.find(skill)
                        target.status_effects.remove_at(status_effect_index)


        log_event(caster, target, skill.id, cast_result)

        return ''


static func damage_entity(target: Entity, base_damage: float) -> void:
        var damage_to_apply = base_damage
        target.health.damage(damage_to_apply)


static func heal_entity(target: Entity, amount: float) -> void:
        target.health.heal(amount)


static func move_entity(speed_modifier: float, input: Vector2, target: Entity) -> void:
        var body = target.body
        var direction = body.transform.basis * Vector3(input.x, 0, input.y).normalized()

        var speed_to_apply: int = target.stats.speed + speed_modifier

        var velocity = direction * speed_to_apply

        body.velocity += velocity * speed_to_apply
        body.move_and_slide()
        body.velocity -= velocity * speed_to_apply


static func is_target_valid(skill, caster: Entity, target: Entity) -> Entity:
        if caster == target:
                if skill.can_target_self:
                        return caster
                else:
                        return null

        if caster.team_id == target.team_id && not skill.can_target_friend:
                return null
        elif caster.team_id != target.team_id && not skill.can_target_enemy:
                return null

        return target


static func log_event(caster: Entity, target: Entity, skill_id: String, event: String) -> void:
        print("%s casted %s on %s, %s" % [caster.name, skill_id, target.name, event])
