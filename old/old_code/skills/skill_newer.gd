class_name SkillNewer

const INVALID_ID: int = -1

#region Skill Info
var id:     int     = INVALID_ID
var title:  String  = ""
var desc:   String  = ""
var icon:   ImageTexture

var speed:      int = 0
var element:    Element.type = Element.type.normal
var effect:     StackEffect

var conditions: Array[Condition] = []
#endregion

#region Status Info
var is_perminant:   bool    = false

var duration:       float   = 0
var time_remaining: float   = 0

var tick_interval:  float   = 0 
var next_tick:      float   = 0
#endregion

#region Cast Info
var original_caster: Entity
var original_target: Entity
#endregion
