class_name MsgHurtStat

const TYPE: String = "HurtStat"

var source: String
var target: String
var state:  String
var new_value
var old_value
var diff


func load(source:String, target:String, stat:String, new_value, old_value) -> void:
    self.type  = "MsgHurt"
    self.source = source
    self.target = target
    self.stat = stat
    self.new_value = new_value
    self.old_value = old_value
    self.diff = old_value - new_value
    
