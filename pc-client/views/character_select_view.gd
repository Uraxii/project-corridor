class_name CharacterSelectView extends View

@onready var controller: CharacterSelectController = Global.controllers.find(
    CharacterSelectController)

func _ready() -> void:
    var new_char_button: Button = %NewCharacter
    new_char_button.pressed.connect(_on_new_char)
    
    var enter_button: Button = %Enter
    enter_button.pressed.connect(_on_enter)
    
    # TODO: Implement get_charactes before calling this.
    # controller.get_characters()


func _on_new_char() -> void:
    controller.new_character()

    
func _on_enter() -> void:
    # Placeholder var. temp will spawn a temp character for testing.
    var currently_select_character := "temp"
    controller.spawn_pc(currently_select_character)
    despawn()
