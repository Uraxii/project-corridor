class_name Effect

# [[ DESCRITPTION ]]
# Base Effect. Other effects should inherit from this."

const EFFECTS_PATH: String = "res://data/skills/effects"

const ERR_STR = "ERROR APPLYING STEP."

static var pool: Dictionary[String, Effect] = {}

static func load(effect_name: String) -> Effect:
    var effect: Effect = pool.get(effect_name)

    if not effect:
        var script: Resource = load(
        "%s/%s.gd" % [EFFECTS_PATH, effect_name])

        if script:
            effect = script.new() as Effect
            pool[effect_name] = effect

    Logger.info("Loaded effect.", {"effect": effect_name})

    return effect


func apply(_caster: Entity, _target: Entity, _context:Dictionary) -> String:
    Logger.error("Called apply function on base effect!")
    return ERR_STR
