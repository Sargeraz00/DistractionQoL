# Reglas Globales - Git y Versionado

## Confirmación Obligatoria para Commits y Push a GitHub
- **NUNCA** ejecutar de forma autónoma comandos que realicen git commit, git push, o cualquier alteración en el historial o repositorio remoto en GitHub.
- **SIEMPRE PREGUNTAR AL USUARIO** de forma explícita y obtener su confirmación antes de ejecutar cualquier comando alusivo a:
  - Crear o modificar commits (git commit, git commit --amend, etc.).
  - Subir cambios o ramas al repositorio remoto (git push, git push origin <branch>, etc.).
  - Crear o subir tags / releases en Git.
- Antes de solicitar la confirmación, presentar un resumen claro de los cambios que se van a incluir (archivos afectados y mensaje propuesto para el commit).

## Verificación de Datos y Prohibido Asumir Información
- **NUNCA asumir datos, versiones, expansiones o estados del juego/entorno.**
- **SIEMPRE verificar en internet**, consultar el código fuente o **preguntar directamente al usuario** ante cualquier duda sobre el contexto temporal, versiones de software, expansiones activas o cambios recientes para evitar datos desfasados.
- Mantener los datos permanentemente sincronizados con la versión y expansión activa actual (ej. WoW: Midnight / 12.x).