#!/bin/sh

SHADOW_C="${SHADOW_C:-#000000}"
P_CORNER_R="${P_CORNER_R:-6}"
P_SHADOWS="${P_SHADOWS:-true}"
P_FADE="${P_FADE:-true}"
P_BLUR="${P_BLUR:-false}"
P_ANIMATIONS="${P_ANIMATIONS:-@}"

sed -i "$HOME/.config/bspwm/config/picom/picom.conf" \
    -e "s/shadow-color = .*/shadow-color = \"${SHADOW_C}\";/" \
    -e "s/^corner-radius = .*/corner-radius = ${P_CORNER_R};/"

sed -i "$HOME/.config/bspwm/config/picom/picom-rules.conf" \
    -e "/#-shadow-switch/s/.*#-/\t\tshadow = ${P_SHADOWS};\t#-/" \
    -e "/#-fade-switch/s/.*#-/\t\tfade = ${P_FADE};\t#-/" \
    -e "/#-blur-switch/s/.*#-/\t\tblur-background = ${P_BLUR};\t#-/" \
    -e "/picom-animations/c\\        ${P_ANIMATIONS}include \"picom-animations.conf\""

_write "$HOME/.config/bspwm/config/picom/picom-dunst-animations.conf" <<-EOF
    animations = (

        {
            triggers = ["close", "hide"];
            preset = "${dunst_close_preset:-fly-out}";
            direction = "${dunst_close_direction:-up}";
            duration = 0.2;
        },

        {
            triggers = ["open", "show"];
            preset = "${dunst_open_preset:-fly-in}";
            direction = "${dunst_open_direction:-up}";
            duration = 0.2;
        }
    )
EOF
