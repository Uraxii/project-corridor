class_name SkillStep

# [[ DESCRITPTION ]]
# Base Effect. Other effects should inherit from this."

const ERR_STR = "ERROR APPLYING STEP."

var effect: Effect
var effect_context: Dictionary = {}

var conditions: Array[Condition] = []


func _init(cfg: ConfigFile, section: String) -> void:
    var effect_name: String = cfg.get_value(section, "script")
    self.effect = Effect.load(effect_name)

    var context_section: String = "%s.context" % section
    if cfg.has_section(context_section):
        for key in cfg.get_section_keys(context_section):
            self.effect_context[key] = cfg.get_value(context_section, key)

    var con_files: Array = cfg.get_value(section, "conditions", [])

    for script in con_files:
        # If the value is not a string, print a warning and skip it.
        if script is not String:
            print("Bad condition file type!",
                {"condition":script,
                    "expected type":TYPE_STRING_NAME,
                    "got type": type_string(typeof(script))})

        var con: Condition = Condition.load(script)

        if con:
            self.conditions.append(con)
