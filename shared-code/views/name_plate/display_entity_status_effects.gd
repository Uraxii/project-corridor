class_name EntityStatusEffectsView extends HBoxContainer

var target:             Entity = null


func set_target(entity: Entity) -> void:
        target = entity

func clear_view() -> void:::
        return

func update_view() -> void:
        for effect in target.status_effects:
                



func _process(delta: float) -> void:
        if target == null:
                clear_view()
                return

        update_view()
