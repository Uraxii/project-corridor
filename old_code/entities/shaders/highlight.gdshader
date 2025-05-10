shader_type spatial;

uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 0.0, 1.0);
uniform float highlight_power : hint_range(0.0, 10.0) = 3.0;
uniform float highlight_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float rim_power : hint_range(1.0, 10.0) = 3.0;
uniform sampler2D texture_albedo : source_color;

void fragment()
{
        vec4 albedo_tex = texture(texture_albedo, UV);

        float rim = 1.0 - dot(NORMAL, VIEW);
        rim = pow(rim, rim_power);

        vec4 final_color = albedo_tex;
        final_color.rgb = mix(final_color.rgb, highlight_color.rgb, rim * highlight_intensity);

        ALBEDO = final_color.rgb;
        EMISSION = highlight_color.rgb * rim * highlight_intensity * highlight_power;
}