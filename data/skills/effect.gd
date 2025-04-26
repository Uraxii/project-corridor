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


func _init(cfg: ConfigFile, section: String) -> void:
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
