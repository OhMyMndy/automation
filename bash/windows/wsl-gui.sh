#!/usr/bin/env bash

# Windows shortcut target example: %windir%\system32\cmd.exe /k "C:\Program Files\Git\bin\bash.exe" -c  '~/src/wsl-gui.sh ubuntu-20.04-gui xfce4-session'

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd)"
cd "$DIR" || exit 1

set -e

vm_name="$1"
if [[ ! "$vm_name" ]]; then
  echo "Please provide vm name as first argument" >&2
  exit 1
fi


command="$2"
if [[ ! "$command" ]]; then
  echo "Please provide the command as second argument" >&2
  exit 2
fi


xming_process_id=

function cleanup() {
    if [[ "$xming_process_id" != '' ]] && [[ -e "/proc/${xming_process_id}" ]]; then
      kill -9 "$xming_process_id"
    fi
}

trap cleanup EXIT SIGINT


# Run Xming!
if [[ "$XMING_EXECUTABLE" = '' ]]; then
    XMING_EXECUTABLE=/c/tools/Xming/Xming.exe
fi

if [[ "$XMING_ARGS" = '' ]]; then
    XMING_ARGS="-clipboard -multiwindow"
fi

# shellcheck disable=SC2086
"$XMING_EXECUTABLE" :0 $XMING_ARGS &
xming_process_id=$!


# @see https://pscheit.medium.com/get-the-ip-address-of-the-desktop-windows-host-in-wsl2-7dc61653ad51
hostip=$(ipconfig.exe | grep 'vEthernet (WSL)' -A4 | cut -d":" -f 2 | tail -n1 | sed -e 's/\s*//g') 

# @see https://virtualizationreview.com/articles/2017/02/08/graphical-programs-on-windows-subsystem-on-linux.aspx
wsl -d "$vm_name" bash -c "export DISPLAY=$hostip:0; $2"
