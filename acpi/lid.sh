#!/bin/sh

test -f /usr/share/acpi-support/state-funcs || exit 0

. /usr/share/acpi-support/power-funcs
. /usr/share/acpi-support/policy-funcs
. /etc/default/acpi-support

[ -x /etc/acpi/local/lid.sh.pre ] && /etc/acpi/local/lid.sh.pre

CheckPolicy && exit

grep -q closed /proc/acpi/button/lid/*/state
if [ $? = 0 ]
then
    . /usr/share/acpi-support/screenblank
    if [ x$LID_SLEEP = xtrue ]; then
	pm-suspend
    fi
else
    d=/tmp/.X11-unix
    for x in $d/X*; do
	displaynum=${x#$d/X}
	getXuser;
	if [ "x$XAUTHORITY" != x ]; then
	    DISPLAY=":$displaynum"
	    export DISPLAY
	    if [ x$RADEON_LIGHT = xtrue ]; then
		[ -x /usr/sbin/radeontool ] && radeontool light on
	    fi
	    case "$DISPLAY_DPMS" in
		xset)
			su "$XUSER" -s /bin/sh -c "xset dpms force on"
			;;
		xrandr)
			su "$XUSER" -s /bin/sh -c "xrandr --output LVDS --auto"
			;;
		vbetool)
			/usr/sbin/vbetool dpms on
			;;
	    esac
	    if pidof xscreensaver > /dev/null; then
	        if on_ac_power; then 
		    su "$XUSER" -s /bin/sh -c "xscreensaver-command -unthrottle"
		fi
		su "$XUSER" -s /bin/sh -c "xscreensaver-command -deactivate"
	    fi
	else
	    if [ -x$DISPLAY_DPMS_NO_USER = xtrue ]; then
            	[ -x /usr/sbin/vbetool ] && /usr/sbin/vbetool dpms on
	    fi 
	fi
    done
fi
[ -x /etc/acpi/local/lid.sh.post ] && /etc/acpi/local/lid.sh.post
