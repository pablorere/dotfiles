# This file launch the bar/s
for mon in $(polybar --list-monitors | cut -d":" -f1); do
	(
    MONITOR=$mon polybar -q karla-bar -c "${HOME}"/.config/bspwm/rices/"${RICE}"/config.ini 2>>"$HOME/.config/bspwm/logs/polybar.log" &
	MONITOR=$mon polybar -q karla-bar2 -c "${HOME}"/.config/bspwm/rices/"${RICE}"/config.ini 2>>"$HOME/.config/bspwm/logs/polybar.log" &
	MONITOR=$mon polybar -q karla-bar3 -c "${HOME}"/.config/bspwm/rices/"${RICE}"/config.ini 2>>"$HOME/.config/bspwm/logs/polybar.log" &
    )
done
