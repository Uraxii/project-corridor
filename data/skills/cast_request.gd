class_name CastRequest

var id:                 String
var skill:              Skill
var caster:             Entity
var target:             Entity
var tick_submitted:     int


func _init(skill: Skill, caster: Entity, target: Entity, current_tick: int):
        self.skill              = skill
        self.caster             = caster
        self.target             = target
        self.tick_submitted     = current_tick

        # TODO: Add some session ID data to make this _less_ spoofable
        self.id = '%s-%s-%s-%d' % [self.skill.id, self.caster.id, self.target.id, self.tick_submitted]
