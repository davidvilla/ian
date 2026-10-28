---
name: ian
description: Uso de `ian`, frontend de las herramientas de empaquetado Debian (dpkg-buildpackage, uscan, dch, lintian, debsign, dupload, reprepro). Úsala cuando el usuario pida compilar, versionar (nueva release), instalar, subir o retirar un paquete .deb de un proyecto con directorio `debian/`, generar el .orig, crear el empaquetado de un proyecto nuevo, o mencione "ian".
---

# ian

`ian` (paquete Debian `ian`; código en https://github.com/davidvilla/ian) es un
frontend de las herramientas oficiales de empaquetado Debian. Se ejecuta desde
el directorio de un paquete fuente (el que contiene `debian/`); si se lanza
desde un subdirectorio, sube hasta encontrarlo.

**Todos los ficheros generados (`.orig.tar.*`, `.deb`, `.dsc`, `.changes`,
`.buildinfo`, `.debian.tar.*`) se escriben en el directorio padre (`..`)**, no
en el del proyecto.

## Comandos

Solo lectura (se pueden ejecutar sin preguntar):

| Comando | Qué hace |
|---|---|
| `ian summary` | Nombre fuente, versión upstream/Debian, orig, modos de orig disponibles, .changes, binarios y dependencias de compilación que faltan |
| `ian name` | `<paquete>-<versión>` |
| `ian ls` | Lista los ficheros generados por la última compilación |
| `ian binary-contents` | Ficheros que contiene cada .deb generado (`debc`) |
| `ian config` | Variables de configuración efectivas |
| `ian pool-ls` | Versiones del paquete publicadas en el pool (consulta remota por ssh si el pool es remoto) |
| `ian help [cmd]` | Ayuda general o de un comando |

Locales (modifican el árbol o los ficheros de `..`; adelante si es lo que el
usuario ha pedido):

| Comando | Qué hace |
|---|---|
| `ian release -y -m MSG` | Nueva entrada en `debian/changelog` incrementando el último campo upstream (`1.2.3-1` → `1.2.4-1`) |
| `ian release -i -y -m MSG` | Solo incrementa la revisión Debian (`1.2.3-1` → `1.2.3-2`) |
| `ian release-date -y -m MSG` | Versión basada en fecha: `0.YYYYMMDD-1` (si ya hay una de hoy, añade `.N`) |
| `ian orig [rule\|uscan\|local]` | Genera o descarga el `.orig`. Sin modo, usa el primero disponible de `ian summary` (rule → uscan → local). Falla si ya existe |
| `ian build [opciones]` | Compila (ver abajo) |
| `ian clean` | `debian/rules clean` y borra los ficheros generados en `..`, **incluido el `.orig`** |
| `ian clean-uscan` | Borra los tarballs que haya descargado uscan |
| `ian lintian-fix` | Intenta corregir algunos avisos de lintian (watch ausente, manpages, Standards-Version) |
| `ian create` | Crea un `debian/` mínimo en un proyecto sin empaquetar (requiere un `Makefile` con regla `install`) |

Con efectos fuera del árbol: **pide confirmación al usuario antes**, salvo que
lo haya pedido explícitamente en ese mismo mensaje:

| Comando | Qué hace |
|---|---|
| `ian install` | `sudo dpkg -i` de todos los .deb generados |
| `ian build -i` | Compila e instala |
| `ian upload [arch]` | Firma (`debsign`) y sube al pool (`dupload` + `reprepro`). `arch` para paquetes compilados en otra arquitectura |
| `ian remove [-y]` | Borra el paquete (fuente y binarios) del pool |

## `ian build`

Opciones: `-b` solo binarios (sin fuente), `-c` borra el orig y lo regenera
antes de compilar, `-f` fuerza la compilación pese a los avisos de
mantenedor, `-i` instala al terminar, `-l` crea el orig con `ian orig local`,
`-m` compila combinando `./debian` con el `.orig` en un directorio temporal,
`-s` incluye el fuente completo (`-sa`), `-x` no ejecuta lintian.

Qué hace automáticamente, para no duplicarlo a mano:

- Si no existe el `.orig`, lo genera (como `ian orig`).
- Si el directorio solo contiene el empaquetado (ninguno de los ficheros del
  `.orig` está presente), activa `-m` por su cuenta.
- Si la revisión Debian no es `-1`, compila solo binarios (el orig ya se
  subió con una revisión anterior).
- Instala con `sudo apt-get install` las dependencias de compilación que
  falten. Es interactivo: antes de compilar, mira la línea `missing build
  deps` de `ian summary` y, si hay alguna, pide al usuario que las instale.
- Pasa lintian sobre el `.changes` y termina listando los ficheros generados.

Comprueba también que `DEBEMAIL` figura como `Maintainer`/`Uploaders` en
`debian/control` y que la última entrada del changelog es del usuario
configurado. Si alguna falla, se detiene. No añadas `-f` para saltarlo sin
explicar el problema al usuario: el paquete resultante no se podrá subir.

## Flujo habitual de una nueva versión

```
ian release -y -m "descripción del cambio"   # o release-date / release -i
ian build
ian binary-contents                           # revisar lo que se instala
ian install                                   # con confirmación
ian upload                                    # con confirmación
```

Si `ian upload` falla porque el `.orig` o el `.deb` de esa versión ya están en
el pool, `ian` lo indica. Lo normal es hacer una nueva release (`ian release
-i`) y volver a compilar; no borres nada del pool sin que lo pida el usuario.

## Interactividad: cosas que bloquean la sesión

- `ian release` y `ian release-date` sin `-y` abren `$EDITOR` sobre el
  changelog. **Usa siempre `-y -m "mensaje"`.**
- `ian remove` sin `-y` pide confirmación `[y/N]` por stdin. Antes muestra
  `ian pool-ls`, pide confirmación al usuario y entonces usa `-y`.
- `ian install`, `ian build -i` y la instalación de dependencias usan `sudo` y
  pueden pedir la contraseña. Si no hay sudo sin contraseña, pide al usuario
  que lo ejecute él (por ejemplo, `! ian install`).
- `ian upload` firma con GPG y puede pedir la frase de paso por pinentry. Si se
  queda colgado o termina en timeout, pide al usuario que lo ejecute él.

## Salida

Cada línea de log lleva una etiqueta: `[II]` información, `[OK]` paso
completado, `[WW]` aviso, `[EE]` error, `[FF]` fallo de un comando. La salida
de las herramientas que lanza aparece sangrada con `|` (`*|` si es stderr).
Juzga el resultado por el código de salida y por las líneas `[EE]`/`[FF]`, no
por la cantidad de salida.

## Configuración

Variables `DEBFULLNAME`, `DEBEMAIL`, `DEBSIGN_KEYID`, `DEBPOOL` y `EDITOR`,
leídas de `~/.config/ian` y del fichero `.ian` del proyecto. Las variables de
entorno tienen prioridad. `DEBPOOL` es `usuario@host/ruta` para un pool remoto
o una ruta absoluta para uno local.

## Hooks

Esos mismos ficheros definen hooks: funciones de shell que ian ejecuta
alrededor de cada comando, cuatro por comando (`ian-build-pre-hook`,
`ian-upload-success-hook`, `ian-remove-fail-hook`...):

- `ian-<cmd>-pre-hook`: antes del comando.
- `ian-<cmd>-post-hook`: después, haya ido como haya ido.
- `ian-<cmd>-success-hook`: tras `post`, solo si el comando tuvo éxito.
- `ian-<cmd>-fail-hook`: tras `post`, solo si falló.

Los comandos de solo lectura no tienen hooks. Se ejecutan también cuando un
comando llama a otro: `ian build` lanza los de `orig` (que lanza los de
`clean`) y, con `-i`, los de `install`. Un hook no puede abortar su comando.
`IAN_DISABLE_HOOKS=1` los desactiva todos.

Los nombres de versiones anteriores (`ian-build-hook`, `ian-build-start-hook`,
`ian-build-end-hook`, `ian-clean-hook`...) siguen funcionando en el lugar del
hook que los sustituye, con un aviso `[DEPRECATED]` que indica el nombre nuevo.
Si aparece ese aviso, lo que procede es renombrar el hook en `~/.config/ian` o
en el `.ian` del proyecto.

## Herramientas incluidas en el paquete

- `last-pypi-version PAQUETE`: última versión publicada en PyPI.
- `version-summary`: desde la raíz de un proyecto Python, compara la versión
  de `setup.py`, PyPI, `debian/changelog` y el repositorio APT.
