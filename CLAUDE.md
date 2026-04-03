# Tildes — Verificador de tildes en español para Claude Code

## Descripción

Hook silencioso + skill on-demand que detecta y corrige palabras en español sin tildes generadas por LLMs. El hook aprende automáticamente del texto que el modelo escribe correctamente, construyendo un diccionario personalizado. El skill `/tildes` escanea archivos bajo demanda.

## Estructura

```
tildes/
├── hooks/
│   ├── check-spanish-tildes.sh   # Hook PostToolUse (silencioso, solo aprende)
│   └── tildes-dictionary.txt     # Diccionario semilla (~95 palabras)
├── skills/
│   └── tildes.md                 # Skill /tildes (revisión on-demand)
├── install.sh                    # Instalador (global o --project)
├── README.md                     # Documentación pública
└── LICENSE                       # MIT
```

## Componentes

1. **Hook** (`check-spanish-tildes.sh`): se ejecuta en cada Write/Edit. Extrae palabras con tilde del texto nuevo y añade su versión sin tilde al diccionario. No produce output (zero tokens).

2. **Diccionario** (`tildes-dictionary.txt`): archivo plano con formato `incorrecta|correcta`. Crece automáticamente. Semilla de ~95 palabras.

3. **Skill** (`tildes.md`): instrucciones para Claude Code. Cuando el usuario escribe `/tildes`, Claude lee el diccionario, escanea archivos modificados, filtra identificadores de código, y reporta errores.

4. **Instalador** (`install.sh`): copia archivos y configura el hook en `settings.json`. Soporta `--project` para instalación local.

## Desarrollo

- El diccionario semilla debe cubrir las palabras más comunes. No hace falta ser exhaustivo porque el hook auto-aprende.
- El hook debe completarse en menos de 5 segundos (timeout del PostToolUse).
- Todos los textos del README y el skill deben tener tildes correctas.
- El install.sh no debe sobreescribir un diccionario existente — debe hacer merge.

## Repo

- GitHub: https://github.com/StSebas2/tildes
- Licencia: MIT
- Público
