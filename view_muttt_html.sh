#!/usr/bin/env bash
set -euo pipefail

# Use /tmp, which Chrome can access normally.
TMPDIR=$(mktemp -d /tmp/mutt-html.XXXXXX)
RAW="$TMPDIR/message.raw"

# Save the piped message
cat > "$RAW"

# Extract all MIME parts
ripmime -i "$RAW" -d "$TMPDIR" --overwrite >/dev/null 2>&1 || true

HTMLFILE=""

# 1) Locate real text/html part via MIME type
for f in "$TMPDIR"/*; do
    [ -f "$f" ] || continue
    mime=$(file --mime-type -b "$f" 2>/dev/null || echo "")
    if [ "$mime" = "text/html" ]; then
        HTMLFILE="$f"
        break
    fi
done

# 2) Fallback: find files ending in .html or .htm
if [ -z "$HTMLFILE" ]; then
    candidate=$(find "$TMPDIR" -maxdepth 1 -type f \( -iname "*.html" -o -iname "*.htm" \) | head -1 || true)
    if [ -n "$candidate" ]; then
        HTMLFILE="$candidate"
    fi
fi

# 3) Last-resort manual extraction from raw
if [ -z "$HTMLFILE" ]; then
    HTMLFILE="$TMPDIR/fallback.html"
    awk '
        BEGIN { in_html=0 }
        /Content-Type:[[:space:]]*text\/html/ { in_html=1 }
        /^--/ && in_html==1 { exit }
        in_html==1 && !/^Content-/ { print }
    ' "$RAW" > "$HTMLFILE" 2>/dev/null || true
fi

# If still nothing, bail
if [ ! -s "$HTMLFILE" ]; then
    echo "No HTML content found." >&2
    exit 1
fi

# 4) Ensure the file has a .html extension so Chrome treats it as HTML
case "$HTMLFILE" in
    *.html|*.htm)
        # ok as-is
        ;;
    *)
        NEW_HTML="$TMPDIR/message.html"
        cp "$HTMLFILE" "$NEW_HTML"
        HTMLFILE="$NEW_HTML"
        ;;
esac

# 5) Open with Google Chrome / Chromium
if command -v google-chrome >/dev/null 2>&1; then
    google-chrome "$HTMLFILE" &
elif command -v chrome >/dev/null 2>&1; then
    chrome "$HTMLFILE" &
elif command -v chromium >/dev/null 2>&1; then
    chromium "$HTMLFILE" &
else
    echo "Chrome/Chromium not found." >&2
    exit 1
fi

exit 0

