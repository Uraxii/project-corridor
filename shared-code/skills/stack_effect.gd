class_name StackEffect

#region Data
var conditions:     Array[Condition] = []

var element:        Element.type = Element.type.normal

var is_aura:        bool    = false
var aura_range:     float   = 0

var cast_range_raw: float   = 0
var cast_range_per: float   = 0

var cast_time_raw:  float   = 0
var cast_time_per:  float   = 0

var dmg_raw:        float   = 0
var dmg_per:        float   = 0

var heal_raw:       float   = 0
var heal_per:       float   = 0
    
var move_raw:       float   = 0
var move_per:       float   = 0

var gravity_raw:    float   = 0
var gravity_per:    float   = 0
#endregion
