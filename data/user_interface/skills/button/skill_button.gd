class_name SkillButton extends TextureButton

@onready var cooldown_bar = $CooldownProgressBar
@onready var bind_text = $BindText
@onready var icon = $Icon
@onready var cooldown_text = $CooldownText
@onready var timer = $CooldownTimer

var caster: Entity
var skill: Skill
var cast_result: String


func initialize(binding: String, owner: Player) -> void:
        name = binding
        caster = owner

        bind_text.text = ''
        cooldown_text.text = ''

        var inputs = InputMap.action_get_events(binding)

        if inputs.size() > 0:
                # TODO: KB/Gamepad icon switching
                bind_text.text = inputs[0].as_text()

                shortcut = Shortcut.new()
                shortcut.events.append_array(inputs)
                set_shortcut(shortcut)

                # print('Set button to %s' % bind_text.text)

        if name in owner.skill_binds.keys():
                skill = Skill.new(owner.skill_binds[name])
                print('skill:' + skill.data_file)
                bind_text.text += ' \n' + skill.id
                icon.texture = skill.icon

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

        var cast_request = CastRequest.new(
                skill,
                caster,
                caster.target,
                Server.current_tick
        )

        # cast_result = skill.cast(caster, caster.target)
        GameManager.enqueue_cast(cast_request)

        if skill.cooldown > 0:
                timer.wait_time = skill.cooldown
                timer.start()
        else:
                _on_cooldown_timer_timeout()


func _on_cooldown_timer_timeout() -> void:
        print('OFF cooldown.')

        disabled = false
        set_process(false)

        cooldown_text.text = ''
        cooldown_bar.value = 0
