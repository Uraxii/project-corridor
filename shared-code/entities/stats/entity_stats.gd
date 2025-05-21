class_name EntityStats extends Resource


#region Traits
# Increases total HP.
var vigor           := Trait.new(0, 50, 0)
# Increases total energy.
var juiced_up       := Trait.new(0, 50, 0)
# Increases melee damage.
var iron_fist       := Trait.new(0, 50, 0)
# Increases ranged damage.
var big_iron        := Trait.new(0, 50, 0)
# Increases range of attacks.
var sniper          := Trait.new(0, 50, 0)
# Increases critical chance.
var jackpot         := Trait.new(0, 50, 0)
# Increases critical damage.
var crown_smasher   := Trait.new(0, 50, 0)
# Increases chance to reflect damage.
var relatiation     := Trait.new(0, 50, 0)
# Increases percentage of damage reflected.
var thorny          := Trait.new(0, 50, 0)
# Increases life steal.
var leach           := Trait.new(0, 50, 0)
# Increases duration of status effects applied to entities.
var chronomancer    := Trait.new(0, 50, 0)
# Reduces damage taken.
var iron_skin       := Trait.new(0, 50, 0)
# Decreases casting speed.
var quick_draw      := Trait.new(0, 50, 0)
# Increases dash count.
var dasher          := Trait.new(0, 3, 0)
# Decreases dash reset time.
var endurance       := Trait.new(0, 50, 0)
# Increases dodge chance.
var dancer          := Trait.new(0, 50, 0)
#endregion

#region Stats
var level:      int     = 0
var xp:         float   = 0

var hp              := FloatStat.new(0, 10, 10, 5)
var energy          := FloatStat.new(0, 10, 10, 5)
var range           := FloatStat.new(0, 50, 0, 1)
var dmg             := FloatStat.new(0, 10, 1, 1)
var attack_speed    := FloatStat.new(0, 10, 1, 1)
var crit_chance     := FloatStat.new(0, 1, 0.01, 0.01)
var crit_dmg        := FloatStat.new(0, 10, 2, 2)
var life_steal      := FloatStat.new(0, 2, 0, 0)
var dodge           := FloatStat.new(0, 1, 0.01, 0.01)
var move_speed      := FloatStat.new(0, 2, 1, 1)
var gravity         := FloatStat.new(0, 2, 1, 1)
var jump_force      := FloatStat.new(0, 20, 10, 10)
var air_control     := FloatStat.new(0, 2, 0.3, 0.3)
var air_jumps       := IntStat.new(0, 0, 0, 0)
#endregion


var is_dead: bool:
    get(): return hp.curr == 0


func get_max_hp() -> float:
    return hp.base * (0.025 * vigor.curr)


class Trait:
    var min:  int
    var max:  int
    
    var curr: int:
        set(value):
            curr = clamp(value, min, max)
    
    
    func _init(min: int, max: int, current: int) -> void:
        curr = current
    
    
    func level(amount: int = 1) -> int:
        var next_level = curr + amount
        curr = next_level
        return next_level - curr


    func refund(amount: int = 1) -> int:
        var original_level = curr
        curr -= amount
        return original_level - curr
