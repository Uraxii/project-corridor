class_name SkillButton extends TextureButton

signal cast
signal select_location

@onready var cooldown_bar       = $CooldownProgressBar
@onready var bind_text          = $BindText
@onready var icon               = $Icon
@onready var cooldown_text      = $CooldownText
@onready var timer              = $CooldownTimer

var caster: Entity
var skill: Skill
var input: PlayerInput
var cast_result: String


func initialize(binding: String, owner: Player) -> void:
        name = binding
        caster = owner

        bind_text.text = ''
        cooldown_text.text = ''

        input = owner.input

        var inputs = InputMap.action_get_events(binding)

        if inputs.size() > 0:
                # TODO: KB/Gamepad icon switching
                bind_text.text = inputs[0].as_text()

                # This is what triggers _on_pressed
                shortcut = Shortcut.new()
                shortcut.events.append_array(inputs)
                set_shortcut(shortcut)

                # print('Set button to %s' % bind_text.text)

        if name in owner.skill_binds.keys():
                skill = Skill.new(owner.skill_binds[name])
                bind_text.text += ' \n' + skill.id
                icon.texture = skill.icon

        cast.connect(_on_cast)

        # print('Finished initializing button.')


func _process(delta: float) -> void:
        if timer.time_left > 0:
                cooldown_text.text = '%3.1f' % timer.time_left
                cooldown_bar.value = (timer.time_left / timer.wait_time) * 100


func _on_pressed() -> void:
        if not skill:
                # print('No Skill assigned to button.')
                return

        # print('ON cooldown')

        disabled = true
        set_process(true)

        if skill.skill_type == "area":
                _cast_area_skill()
        elif skill.skill_type == "targeted":
                _cast_targeted_skill()


func _cast_area_skill() -> void:
        var location: Vector3 = await _select_area_location()

        if location == Vector3.ZERO:
                return

        GameManager.queue_area_cast.rpc(
                skill.file,
                caster.name,
                location)

        cast.emit()


func _cast_targeted_skill() -> void:
        var target = Skill.is_target_valid(skill, caster, caster.target)

        if not target:
                return

        GameManager.queue_targeted_cast.rpc(
                skill.file,
                caster.name,
                target.name)

        cast.emit()


func _on_cast() -> void:
        if skill.cooldown > 0:
                timer.wait_time = skill.cooldown
                timer.start()
        else:
                _on_cooldown_timer_timeout()


func _select_area_location() -> Vector3:
        while true:
                await get_tree().process_frame
                if input.select_location:
                        var viewport = get_viewport()
                        var camera = viewport.get_camera_3d()
                        var mouse_pos = viewport.get_mouse_position()
                        # Create a ray from the camera
                        var from = camera.project_ray_origin(mouse_pos)
                        var to = from + camera.project_ray_normal(mouse_pos) * 1000

                        var plane = Plane(Vector3(0, 1, 0), 0)  # Y-normal plane at origin
                        var position_3d = plane.intersects_ray(from, to)
                        return position_3d
                elif input.cancel:
                        break

        # This line should never be reached but is here for completeness
        return Vector3.ZERO


func _on_cooldown_timer_timeout() -> void:
        # print('OFF cooldown.')

        disabled = false
        set_process(false)

        cooldown_text.text = ''
        cooldown_bar.value = 0
