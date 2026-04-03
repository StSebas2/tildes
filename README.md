# Tildes — Verificador de tildes en español para Claude Code

Los LLMs generan texto en español sin tildes con frecuencia. No es que "no sepan" las reglas ortográficas — es que su proceso de generación es probabilístico y los datos de entrenamiento contienen millones de textos sin tildes (foros, código, redes sociales). El contexto de código empeora el problema: variables como `informacion`, keys como `"descripcion":` y slugs como `/configuracion` sesgan al modelo hacia versiones sin tilde.

**Tildes** es un sistema de dos piezas para Claude Code que resuelve esto:

1. **Un hook silencioso** que aprende automáticamente cada palabra con tilde que el modelo escribe correctamente, construyendo un diccionario personalizado.
2. **Un skill on-demand** (`/tildes`) que escanea los archivos del proyecto contra ese diccionario y reporta las palabras sin tilde.

## Cómo funciona

```
Escribes código con Claude Code
         │
         ▼
   ┌─────────────┐
   │    Hook      │  ← Se ejecuta en cada Write/Edit
   │  (silencioso)│  ← Detecta palabras CON tilde correcta
   │              │  ← Las aprende en el diccionario
   └─────────────┘
         │
         ▼
   tildes-dictionary.txt   ← Crece automáticamente
         │
         ▼
   ┌─────────────┐
   │   /tildes    │  ← Cuando tú lo pidas
   │   (skill)    │  ← Escanea archivos contra el diccionario
   │              │  ← Reporta errores con correcciones
   └─────────────┘
```

### El diccionario auto-expandible

El diccionario viene con ~95 palabras comunes como semilla. Cada vez que Claude escribe una palabra con tilde que no está en el diccionario, el hook la añade automáticamente.

Por ejemplo, si Claude escribe `"autenticación"` en un componente, el hook extrae `autenticacion|autenticación` y lo añade. Si en el futuro escribe `"autenticacion"` sin tilde, el skill `/tildes` lo detectará.

El diccionario crece con el vocabulario real de tus proyectos, sin mantenimiento manual.

### Detección de idioma

El hook y el skill solo revisan archivos que pueden contener español. Se saltan automáticamente:

- Directorios de locale no español (`/en/`, `/fr/`, `/i18n/de/`, etc.)
- Archivos con nombre de locale (`en.json`, `fr.ts`)
- Archivos con sufijo de locale (`page.en.mdx`, `messages.de.json`)

### Filtrado de código

El skill ignora palabras sin tilde que son identificadores de código:

- Declaraciones: `const descripcion = ...`
- Keys de objeto: `"informacion": ...`
- Property access: `.configuracion`
- camelCase: `getInformacion`
- Llamadas a función: `configuracion()`
- Atributos HTML: `descripcion=`

## Instalación

### Requisitos

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) instalado
- `jq` instalado (`brew install jq` en macOS, `apt install jq` en Linux)

### Instalación global (recomendada)

Aplica a **todos** tus proyectos. Ideal si trabajas habitualmente en español.

```bash
git clone https://github.com/StSebas2/tildes.git
cd tildes
chmod +x install.sh
./install.sh
```

Esto instala:

| Componente | Ubicación |
|---|---|
| Hook silencioso | `~/.claude/hooks/check-spanish-tildes.sh` |
| Diccionario | `~/.claude/hooks/tildes-dictionary.txt` |
| Skill `/tildes` | `~/.claude/commands/tildes.md` |

Y añade la configuración del hook en `~/.claude/settings.json`.

### Instalación por proyecto

Aplica solo al proyecto actual. Útil si solo algunos de tus proyectos tienen contenido en español.

```bash
git clone https://github.com/StSebas2/tildes.git /tmp/tildes
cd /ruta/a/tu/proyecto
/tmp/tildes/install.sh --project
```

Esto instala los mismos archivos pero dentro del directorio `.claude/` de tu proyecto:

| Componente | Ubicación |
|---|---|
| Hook silencioso | `.claude/hooks/check-spanish-tildes.sh` |
| Diccionario | `~/.claude/hooks/tildes-dictionary.txt`* |
| Skill `/tildes` | `.claude/commands/tildes.md` |

*El diccionario siempre se guarda en `~/.claude/hooks/` para ser compartido entre proyectos.

### Instalación manual

Si prefieres instalar manualmente:

1. **Copia los archivos:**

```bash
cp hooks/check-spanish-tildes.sh ~/.claude/hooks/
cp hooks/tildes-dictionary.txt ~/.claude/hooks/
cp skills/tildes.md ~/.claude/commands/
chmod +x ~/.claude/hooks/check-spanish-tildes.sh
```

2. **Añade el hook a tu `~/.claude/settings.json`** (o `.claude/settings.json` del proyecto):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/check-spanish-tildes.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

Si ya tienes un `settings.json` con otros hooks, añade la entrada al array `PostToolUse` existente.

## Uso

### Aprendizaje automático

No necesitas hacer nada. El hook se ejecuta silenciosamente en cada operación de escritura/edición y enriquece el diccionario con las palabras que Claude escribe correctamente.

### Revisión on-demand

Cuando quieras verificar las tildes de tu proyecto, escribe en Claude Code:

```
/tildes
```

Claude escaneará los archivos modificados (o todo el proyecto) contra el diccionario y reportará los errores encontrados con las correcciones sugeridas.

### Editar el diccionario

El diccionario es un archivo de texto plano. Puedes editarlo manualmente:

```bash
# Ver el diccionario
cat ~/.claude/hooks/tildes-dictionary.txt

# Añadir una palabra
echo "electronica|electrónica" >> ~/.claude/hooks/tildes-dictionary.txt

# Ver cuántas palabras tiene
wc -l ~/.claude/hooks/tildes-dictionary.txt
```

Formato: `palabra_sin_tilde|palabra_correcta` (una por línea).

## Archivos del proyecto

```
tildes/
├── README.md                           # Este archivo
├── install.sh                          # Script de instalación
├── hooks/
│   ├── check-spanish-tildes.sh         # Hook silencioso (aprendizaje)
│   └── tildes-dictionary.txt           # Diccionario semilla (~95 palabras)
├── skills/
│   └── tildes.md                       # Skill /tildes (revisión on-demand)
└── LICENSE
```

## ¿Por qué los LLMs escriben sin tildes?

Los modelos de lenguaje generan texto token a token, eligiendo el más probable según el contexto. Tres factores conspiran contra las tildes:

1. **Datos de entrenamiento**: una proporción enorme del español en internet está escrito sin tildes (foros, redes sociales, código). El modelo aprende esa distribución.

2. **Contexto de código**: cuando genera texto dentro de código (variables, keys, props), el contexto circundante no tiene tildes, lo que sesga las probabilidades hacia tokens sin acento.

3. **Sin verificación posterior**: el modelo genera hacia adelante sin volver atrás a revisar. No tiene un corrector ortográfico interno.

Este proyecto compensa esa limitación estructural con una verificación externa.

## Contribuir

¿Tienes palabras que deberían estar en el diccionario semilla? Abre un PR añadiéndolas a `hooks/tildes-dictionary.txt`.

## Licencia

MIT
