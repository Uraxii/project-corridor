class_name SkinColorSelect extends Control

@export var color_picker: ColorPickerButton

signal change(value: ColorRect)


func _ready() -> void:
        color_picker.color_changed.connect(on_value_changed)
        on_value_changed(color_picker.color)


func on_value_changed(new_color: Color) -> void:
        change.emit(new_color)
