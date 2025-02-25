KITTIES=$(($(pgrep -P 1 kitty | wc -l) - 1))

if [[ $KITTIES -lt 1 ]]; then
    exec kitty -o confirm_os_window_close=0 zellij attach --create main
else
    exec kitty -o confirm_os_window_close=0 zellij attach --create "temp $KITTIES"
fi
