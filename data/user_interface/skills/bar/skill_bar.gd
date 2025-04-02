class_name Skillbar extends HBoxContainer

@export var entity: Player
@export var bar_number: int = 1
@export var number_of_buttons: int = 5


func init_bar() -> void:
        var button_scene = load('res://data/user_interface/skills/button/skill_button.tscn')
        if !button_scene:
                printerr('Could not load skill button scene resource!')
                return

        var button_number = 1
        while button_number <= number_of_buttons:
                var button = button_scene.instantiate()
                add_child(button)
                button.name = 'bar_%d_skill_%d' % [bar_number, button_number]
                button_number += 1
                button.initialize(button.name, entity)
                print('Created skill button %s' % button.name)


func _ready() -> void:
        init_bar()
