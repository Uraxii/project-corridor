class_name CharacterSelectView extends View


func _ready() -> void:
    var new_char_button: Button = %NewCharacter
    new_char_button.pressed.connect(_on_new_char)
    
    var enter_button: Button = %Enter
    enter_button.pressed.connect(_on_enter)
    
    signals.characters_received.connect(_on_characters_received)
    
    API.get_all_characters()


func _on_characters_received(characters: Array, total: int) -> void:
    print("characters: ", characters, " - from character select view." )
    

func _on_new_char() -> void:
    print("New Character")

    
func _on_enter() -> void:
    # Placeholder var. temp will spawn a temp character for testing.
    var currently_select_character := "temp"
    print("Enter World")
    despawn()
