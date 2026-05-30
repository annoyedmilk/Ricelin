#!/bin/sh
snapshot=$(cliphist list)
[ -n "$snapshot" ] || exit 0

idx=$(printf '%s\n' "$snapshot" | ~/.config/rofi/cliphist-rofi.sh | rofi -dmenu -no-custom -format i -p "●" -theme ~/.config/rofi/clipboard.rasi)
[ -n "$idx" ] || exit 0

id=$(printf '%s\n' "$snapshot" | sed -n "$((idx + 1))p" | cut -f1)
case "$id" in
    ''|*[!0-9]*) exit 0 ;;
esac

tmp=$(mktemp)
printf '%s' "$id" | cliphist decode > "$tmp" 2>/dev/null
[ -s "$tmp" ] && wl-copy < "$tmp"
rm -f "$tmp"
