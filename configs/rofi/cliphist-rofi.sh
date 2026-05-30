#!/bin/sh
cache="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist-thumbs"
mkdir -p "$cache"

snapshot=$(cat)

ids=$(printf '%s\n' "$snapshot" | cut -f1)
for f in "$cache"/*.png; do
    [ -e "$f" ] || continue
    fid=$(basename "$f" .png)
    printf '%s\n' "$ids" | grep -qxF "$fid" || rm -f "$f"
done

printf '%s\n' "$snapshot" | while IFS= read -r line; do
    case "$line" in
        *"[[ binary data"*png*|*"[[ binary data"*jpg*|*"[[ binary data"*jpeg*|*"[[ binary data"*gif*|*"[[ binary data"*bmp*|*"[[ binary data"*webp*)
            id=$(printf '%s' "$line" | cut -f1)
            thumb="$cache/$id.png"
            [ -f "$thumb" ] || printf '%s\n' "$line" | cliphist decode > "$thumb" 2>/dev/null
            meta=$(printf '%s' "$line" | sed -n 's/.*\[\[ binary data \(.*\) \]\].*/\1/p')
            [ -z "$meta" ] && meta="image"
            printf '%s\0icon\x1f%s\n' "$meta" "$thumb"
            ;;
        *)
            printf '%s\0icon\x1ftext-x-generic\n' "$(printf '%s' "$line" | cut -f2-)"
            ;;
    esac
done
