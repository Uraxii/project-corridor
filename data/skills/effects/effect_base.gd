class_name Effect

# [[ DESCRITPTION ]]
# Base Effect. Other effects should inherit from this."

const EFFECTS_PATH: String = "res://data/skills/effects"

const ERR_STR = "ERROR APPLYING STEP."


static func load(effect_name: String) -> Effect:
    var script_path: String = "%s/%s.gd" % [EFFECTS_PATH, effect_name]
    var script: Resource = load(script_path)

    if not script:
        Logger.error("Unable to load effect script!",
            {"path":script_path})

        return

    var effect: Effect = script.new() as Effect

    Logger.info("Loaded effect.", {"effect": effect_name})

    return effect


func apply(_caster: Entity, _target: Entity, _context:Dictionary) -> String:
    Logger.error("Called apply function on base effect!")

    return ERR_STR
