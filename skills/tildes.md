---
name: tildes
description: Revisa tildes en español en archivos modificados del proyecto. Escanea contra el diccionario auto-expandible y reporta correcciones.
---

# Revisión de tildes en español

Escanea los archivos del proyecto buscando palabras en español que faltan tildes, usando el diccionario auto-expandible en `~/.claude/hooks/tildes-dictionary.txt`.

## Instrucciones

1. **Leer el diccionario** desde `~/.claude/hooks/tildes-dictionary.txt`. Cada línea tiene formato `incorrecta|correcta`.

2. **Determinar archivos a escanear.** Por orden de prioridad:
   - Si el usuario especificó archivos concretos, usar esos.
   - Si hay archivos modificados en git (`git diff --name-only HEAD`), usar esos.
   - Si no, escanear todos los archivos fuente del proyecto (`.astro`, `.ts`, `.tsx`, `.json`, `.md`, `.mdx`, `.css`, `.html`, `.vue`, `.svelte`, `.jsx`, `.php`).

3. **Excluir** archivos en: `node_modules/`, `dist/`, `.claude/`, `.planning/`, `vendor/`, `.next/`, `.nuxt/`.

4. **Excluir archivos de idiomas no españoles** — archivos en directorios de locale no-español (`/en/`, `/fr/`, `/i18n/en/`, etc.) o con sufijo de locale en el nombre (`en.json`, `page.en.mdx`).

5. **Buscar cada palabra del diccionario** en los archivos seleccionados. Para cada coincidencia, verificar que **no es un identificador de código**. Saltar si la palabra aparece en:
   - Declaraciones: `const`, `let`, `var`, `type`, `interface`, `import`, `export`
   - Keys de objeto: `"palabra":` o `palabra:`
   - Property access: `.palabra`
   - camelCase: precedida por letra minúscula
   - Llamadas a función: `palabra(`
   - Atributos HTML/JSX: `palabra=`

6. **Reportar** los resultados en este formato:

```
## Revisión de tildes

### archivo.astro
- Línea 42: "informacion" → "información"
- Línea 78: "pagina" → "página"

### otro-archivo.ts
- Línea 15: "configuracion" → "configuración"

**Resumen:** X errores en Y archivos
```

7. Si no hay errores, responder: "Sin errores de tildes detectados."

8. **Ofrecer corregir** los errores encontrados si el usuario lo desea.
