#!/bin/bash
# PostToolUse hook — SILENT MODE
# Learns new Spanish words with tildes from written text.
# Does NOT report errors — use the /tildes skill for on-demand review.
#
# Dictionary: ~/.claude/hooks/tildes-dictionary.txt
# Format: wrong|correct (one per line)

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

[[ -z "$FILE" || ! -f "$FILE" ]] && exit 0

# Only check source files likely to contain Spanish text
case "$FILE" in
  *.astro|*.ts|*.tsx|*.json|*.md|*.mdx|*.css|*.html|*.vue|*.svelte|*.jsx|*.php) ;;
  *) exit 0 ;;
esac

# Skip generated/vendor directories
case "$FILE" in
  *node_modules*|*.planning*|*dist/*|*.claude/*|*vendor/*|*.next/*|*.nuxt/*) exit 0 ;;
esac

# --- Language detection: skip non-Spanish files ---
NON_ES="en|fr|de|it|pt|nl|ru|ja|ko|zh|ar|pl|sv|da|no|fi|ca|eu|gl|tr|he|th|vi"

# Skip: i18n/locale directories with non-Spanish locale
echo "$FILE" | grep -qiE "/(i18n|locales?|translations?|lang|languages?|messages)/(${NON_ES})(\b|/)" && exit 0

# Skip: route-level locale directories (Astro/Next.js: /pages/en/, /content/en/)
echo "$FILE" | grep -qE "/(pages|content|src)/(${NON_ES})/" && exit 0

# Skip: locale-named files (en.json, en.ts, en.yaml)
BASENAME=$(basename "$FILE")
echo "$BASENAME" | grep -qE "^(${NON_ES})\.(json|ts|js|ya?ml)$" && exit 0

# Skip: locale-suffixed files (messages.en.json, page.en.mdx)
echo "$BASENAME" | grep -qE "\.(${NON_ES})\.(json|ts|js|md|mdx|astro|ya?ml)$" && exit 0

# Extract only NEW text
TEXT=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty' 2>/dev/null)
[[ -z "$TEXT" ]] && exit 0

DICT="$HOME/.claude/hooks/tildes-dictionary.txt"
[[ ! -f "$DICT" ]] && touch "$DICT"

# --- Learn: extract words WITH tildes and add their tildeless version ---
ACCENTED=$(echo "$TEXT" | grep -oE '\b[A-Za-záéíóúÁÉÍÓÚüÜñÑ]*[áéíóúÁÉÍÓÚ][A-Za-záéíóúÁÉÍÓÚüÜñÑ]*\b' | sort -u)

for word in $ACCENTED; do
  # Skip short words (2 chars or less)
  [[ ${#word} -le 2 ]] && continue

  # Generate tildeless version
  tildeless=$(echo "$word" | sed 'y/áéíóúÁÉÍÓÚ/aeiouAEIOU/')

  # Skip if identical (no tilde difference)
  [[ "$tildeless" == "$word" ]] && continue

  # Skip if already in dictionary
  grep -qF "${tildeless}|${word}" "$DICT" 2>/dev/null && continue

  # Add to dictionary
  echo "${tildeless}|${word}" >> "$DICT"
done

# Silent: no output, no tokens consumed
