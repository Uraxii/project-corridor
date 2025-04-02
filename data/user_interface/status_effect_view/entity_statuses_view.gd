class_name EntityStatusesView extends HBoxContainer

# TODO: Optimize this script.

var target:             Entity = null
var tracked_effects:    Array[TextureRect] = []


func set_target(entity: Entity) -> void:
        target = entity


func clear_view() -> void:
        for effect in tracked_effects:
                effect.queue_free.call_deferred()

        tracked_effects = []


func update_view() -> void:
        for effect in target.status_effects:
                var icon = TextureRect.new()
                icon.texture = effect.icon
                tracked_effects.append(icon)
                add_child(icon)


func _process(delta: float) -> void:
        if target == null:
                clear_view()
                return

        clear_view()
        update_view()
