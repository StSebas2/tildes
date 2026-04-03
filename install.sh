#!/bin/bash
# Instalador de Tildes — verificador de tildes en español para Claude Code
#
# Uso:
#   ./install.sh          # Instalación global (recomendado)
#   ./install.sh --project # Instalación solo para el proyecto actual

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:-global}"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }

# Verificar que jq está instalado (requerido por el hook)
if ! command -v jq &>/dev/null; then
  error "jq es necesario. Instálalo con: brew install jq"
fi

if [[ "$MODE" == "--project" ]]; then
  # --- Instalación por proyecto ---
  PROJECT_DIR="$(pwd)"
  CLAUDE_DIR="${PROJECT_DIR}/.claude"
  HOOKS_DIR="${CLAUDE_DIR}/hooks"
  COMMANDS_DIR="${CLAUDE_DIR}/commands"
  SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

  echo "Instalando Tildes para el proyecto: ${PROJECT_DIR}"
else
  # --- Instalación global ---
  CLAUDE_DIR="$HOME/.claude"
  HOOKS_DIR="${CLAUDE_DIR}/hooks"
  COMMANDS_DIR="${CLAUDE_DIR}/commands"
  SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

  echo "Instalando Tildes globalmente en: ${CLAUDE_DIR}"
fi

# Crear directorios
mkdir -p "$HOOKS_DIR" "$COMMANDS_DIR"

# Copiar hook
cp "${SCRIPT_DIR}/hooks/check-spanish-tildes.sh" "${HOOKS_DIR}/check-spanish-tildes.sh"
chmod +x "${HOOKS_DIR}/check-spanish-tildes.sh"
info "Hook instalado en ${HOOKS_DIR}/check-spanish-tildes.sh"

# Copiar diccionario (solo si no existe, para no sobreescribir uno ya enriquecido)
DICT_FILE="${HOOKS_DIR}/tildes-dictionary.txt"
if [[ -f "$DICT_FILE" ]]; then
  # Merge: añadir palabras nuevas del seed que no existan
  BEFORE=$(wc -l < "$DICT_FILE" | tr -d ' ')
  while IFS= read -r line; do
    grep -qF "$line" "$DICT_FILE" 2>/dev/null || echo "$line" >> "$DICT_FILE"
  done < "${SCRIPT_DIR}/hooks/tildes-dictionary.txt"
  AFTER=$(wc -l < "$DICT_FILE" | tr -d ' ')
  ADDED=$((AFTER - BEFORE))
  info "Diccionario existente actualizado (+${ADDED} palabras nuevas)"
else
  cp "${SCRIPT_DIR}/hooks/tildes-dictionary.txt" "$DICT_FILE"
  info "Diccionario instalado con $(wc -l < "$DICT_FILE" | tr -d ' ') palabras"
fi

# Copiar skill
cp "${SCRIPT_DIR}/skills/tildes.md" "${COMMANDS_DIR}/tildes.md"
info "Skill /tildes instalado en ${COMMANDS_DIR}/tildes.md"

# Configurar hook en settings.json
if [[ -f "$SETTINGS_FILE" ]]; then
  # Verificar si el hook ya existe
  if jq -e '.hooks.PostToolUse[]? | select(.hooks[]?.command | test("check-spanish-tildes"))' "$SETTINGS_FILE" &>/dev/null; then
    info "Hook ya configurado en settings.json (sin cambios)"
  else
    # Añadir hook al array PostToolUse
    HOOK_ENTRY='{"matcher":"Write|Edit","hooks":[{"type":"command","command":"'"${HOOKS_DIR}/check-spanish-tildes.sh"'","timeout":5}]}'

    if jq -e '.hooks.PostToolUse' "$SETTINGS_FILE" &>/dev/null; then
      # PostToolUse existe, añadir al array
      jq ".hooks.PostToolUse += [${HOOK_ENTRY}]" "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
    else
      # Crear PostToolUse
      jq ".hooks.PostToolUse = [${HOOK_ENTRY}]" "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
    fi
    info "Hook añadido a ${SETTINGS_FILE}"
  fi
else
  # Crear settings.json con el hook
  cat > "$SETTINGS_FILE" << SETTINGSEOF
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${HOOKS_DIR}/check-spanish-tildes.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
SETTINGSEOF
  info "Creado ${SETTINGS_FILE} con hook configurado"
fi

echo ""
echo -e "${GREEN}Instalación completada.${NC}"
echo ""
echo "Componentes instalados:"
echo "  Hook (silencioso):  ${HOOKS_DIR}/check-spanish-tildes.sh"
echo "  Diccionario:        ${DICT_FILE}"
echo "  Skill on-demand:    ${COMMANDS_DIR}/tildes.md"
echo ""
echo "Uso:"
echo "  El hook aprende palabras automáticamente mientras trabajas."
echo "  Escribe /tildes en Claude Code para revisar errores de tildes."
