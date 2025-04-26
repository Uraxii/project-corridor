class_name Effect

var impact_enemy:   bool
var impact_friend:  bool
var impact_caster:  bool

#region Data
var damage:         float   # Damage dealt on hit
var heal:           float   # Healing done on use
var apply_status:   int     # ID of status effect to apply (if any)
var create_aoe:     int     # ID of aoe effect to create (if any)

var conditions: Array[ConditionBase] = [] # Condition scripts (if any)
#endregion


func _init(parent: SkillNew, cfg: ConfigFile, section: String) -> void:
    self.impact_enemy = cfg.get_value(
        section, "impact_enemy", parent.impact_enemy)
    self.impact_friend = cfg.get_value(
        section, "impact_friend", parent.impact_friend)
    self.impact_caster = cfg.get_value(
        section, "impact_caster", parent.impact_caster)
    self.damage = cfg.get_value(section, "damage", 0.0)

    var con_files: Array = cfg.get_value(section, "conditions", [])

    for script in con_files:
        # If the value is not a string, print a warning and skip it.
        if script is not String:
            Logger.warn("Bad condition file type!",
                {"condition":script,
                    "expected type":TYPE_STRING_NAME,
                    "got type": type_string(typeof(script))})

        var con: ConditionBase = SkillNew._load_condition(script)

        if con:
            self.conditions.append(con)




func apply(caster: Entity, target:Entity):
    heal_hp(target, heal)
    damage_hp(target, damage)


# Static utility: Heals the target by a given amount
static func heal_hp(target: Entity, amount: float) -> float:
    var healing_to_apply = amount
    target.stats.health += healing_to_apply
    return healing_to_apply


# Static utility: Applies damage, using the target's health_extra as a shield
static func damage_hp(target: Entity, amount: float) -> float:
    var remaining_damage = target.stats.health_extra - amount
    target.stats.health_extra -= amount

    # If health_extra is depleted, reduce main health by the remainder
    if remaining_damage < 0:
        target.stats.health += remaining_damage

    return amount
