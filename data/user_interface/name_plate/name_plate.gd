class_name NamePlate extends Control

@onready var pannel:            Control                 = $Pannel
@onready var display_name:      Label                   = $Pannel/Name
@onready var health_bar:        TextureProgressBar      = $Pannel/HealthBar
@onready var health_value:      Label                   = $Pannel/HealthBar/HealthValue
@onready var status_effects:    EntityStatusesView      = $Pannel/EntityStatusesView

var show_percentage: bool = true
var target: Entity = null


func initialize(player: Player, target_change_signal: String) -> void:
        player.connect(target_change_signal, on_changed_target)


func on_changed_target(new_target: Entity) -> void:
        target = new_target

        if not new_target:
                pannel.hide()
                set_process(false)
                return

        display_name.text = target.get_display_name()
        pannel.show()

        status_effects.set_target(new_target)

        if 'health' in new_target:
                set_process(true)

        print('Nameplate updated:', display_name.text)


func _ready() -> void:
        display_name.text = ''
        health_value.text = ''


func _process(delta: float) -> void:
        if not target:
                return
                
        health_value.text = '%d / %d' % [target.get_health(), target.base.health]

        if show_percentage:
                health_value.text += ' ( %d ' % [target.get_health() / target.base.health * 100] + '% )'

        if target.get_health() == 0:
                health_value.text += ' (Dead)'
