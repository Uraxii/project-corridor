class_name EntityStatusesView extends HBoxContainer

# TODO: Optimize this script.

@onready var status_effect_view := preload("res://shared-code/views/status_effect_view/status_effect_view.tscn")

var target:             Entity = null
var effect_views:       Array[StatusEffectView] = []


func set_target(entity: Entity) -> void:
        target = entity
        clear_view()


func clear_view() -> void:
        for effect in effect_views:
                if is_instance_valid(effect):
                        effect.queue_free.call_deferred()

        effect_views = []


func update_view() -> void:
        for effect in target.status_effects:
                var effect_view: StatusEffectView = status_effect_view.instantiate()
                add_child(effect_view)
                effect_view.initialize(effect, target)
                effect_views.append(effect_view)


func _process(_delta: float) -> void:
        if target == null:
                clear_view()
                return

        clear_view()
        update_view()
