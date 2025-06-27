class_name CharacterInfoTemplate extends Button

signal selected_character(pressed_button)

var character_data: Dictionary = {}


func set_character_data(character_dict: Dictionary) -> void:
    character_data = character_dict
    %Name.text = character_data.get("name", "{ NO NAME }")


func _ready() -> void:
    pressed.connect(_on_pressed)
    

func _on_pressed() -> void:
    selected_character.emit(character_data)
