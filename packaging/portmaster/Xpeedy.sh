#!/bin/bash
# Xpeedy launch script for PortMaster (Godot 4.4.1 runtime under Weston).

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi
source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

GAMEDIR=/$directory/ports/xpeedy
godot_runtime="godot_4.4.1"
godot_executable="godot441.$DEVICE_ARCH"
weston_runtime="weston_pkg_0.2"
pck_filename="xpeedy.pck"

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
echo "Xpeedy on ${CFW_NAME} ${DEVICE_NAME} ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT} ${DEVICE_ARCH}"

CONFDIR="$GAMEDIR/conf/"
$ESUDO mkdir -p "${CONFDIR}"

mount_runtime() {
  local runtime="$1" target="$2"
  $ESUDO mkdir -p "${target}"
  if [ ! -f "$controlfolder/libs/${runtime}.squashfs" ]; then
    if [ ! -f "$controlfolder/harbourmaster" ]; then
      pm_message "This port requires the latest PortMaster to run, please go to https://portmaster.games/ for more info."
      sleep 5
      exit 1
    fi
    $ESUDO $controlfolder/harbourmaster --quiet --no-check runtime_check "${runtime}.squashfs"
  fi
  if [[ "$PM_CAN_MOUNT" != "N" ]]; then
    $ESUDO umount "${target}"
  fi
  $ESUDO mount "$controlfolder/libs/${runtime}.squashfs" "${target}"
}

weston_dir=/tmp/weston
godot_dir=/tmp/godot
mount_runtime "$weston_runtime" "$weston_dir"
mount_runtime "$godot_runtime" "$godot_dir"

cd $GAMEDIR

# Debug and benchmark options: the contents of args.txt (for example "--benchmark") are passed to the game.
GAME_ARGS=""
if [ -f "$GAMEDIR/args.txt" ]; then
  GAME_ARGS="-- $(tr -d '\r' < "$GAMEDIR/args.txt")"
fi
echo "Game arguments: ${GAME_ARGS:-none}"

$GPTOKEYB "$godot_executable" &

$ESUDO env $weston_dir/westonwrap.sh headless noop kiosk crusty_x11egl \
LD_PRELOAD= XDG_DATA_HOME=$CONFDIR $godot_dir/$godot_executable \
--resolution ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT} -f \
--rendering-driver opengl3_es --audio-driver ALSA --main-pack $GAMEDIR/gamedata/$pck_filename $GAME_ARGS

$ESUDO $weston_dir/westonwrap.sh cleanup
if [[ "$PM_CAN_MOUNT" != "N" ]]; then
  $ESUDO umount "${weston_dir}"
  $ESUDO umount "${godot_dir}"
fi

pm_finish
