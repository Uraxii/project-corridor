class_name Effect

# [[ DESCRITPTION ]]
# Base Effect. Other effects should inherit from this."

const EFFECTS_PATH: String = "res://skills/effects"

const ERR_STR = "ERROR APPLYING STEP."


static func load(effect_name: String) -> Effect:
    var script_path: String = "%s/%s.gd" % [EFFECTS_PATH, effect_name]
    var script: Resource = load(script_path)

    if not script:
        printerr("Unable to load effect script:", script_path)

        return

    var effect: Effect = script.new() as Effect

    print("Loaded effect:", effect_name)

    return effect


func apply(_caster: Entity, _target: Entity, _context:Dictionary) -> String:
    push_error("Called apply function on base effect!")

    return ERR_STR
