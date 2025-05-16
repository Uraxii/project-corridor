class_name CharacterSelectView extends View

@onready var controller: CharacterSelectController = Global.controllers.find(CharacterSelectController)

func _ready() -> void:
    var new_char_button: Button = %NewCharacter
    new_char_button.pressed.connect(_on_new_char)
    controller.get_characters()

func _on_new_char() -> void:
    controller.new_character()
    
func _on_play() -> void:
    push_error("Not implemented")
