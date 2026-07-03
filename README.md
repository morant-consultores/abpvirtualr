# abpvirtualr

Paquete de R que soporta el flujo de análisis y generación de reportes (slides `xaringan`) de los ejercicios ABP Virtual: lee las respuestas de un cuestionario desde SQL Server, procesa preguntas abiertas, de categorización (importancia/cumplimiento) y de "brecha", genera gráficas (`highcharter`/`ggplot2`) y arma automáticamente los chunks de un deck de presentación.

Este documento describe lo que existe hoy en el código (no funcionalidad planeada) y cierra con las áreas de mejora identificadas de cara al próximo proyecto.

## Modelo de datos

`leer_base()` (`R/utilitaria_colectar_base.R`) se conecta a SQL Server (driver ODBC, vía `pool`) y regresa una lista con 7 tablas:

| Tabla | Esquema | Contenido |
|---|---|---|
| `etapa` | `Catalogo.Etapa` | Catálogo de etapas del ejercicio |
| `pregunta` | `Cuestionario.Pregunta` | Catálogo de preguntas (por `IdEtapa`, `IdPregunta`) |
| `respuesta` | `Cuestionario.Respuesta` | Respuestas de texto libre de los participantes |
| `categoria` | `Catalogo.Categoria` | Catálogo de temas/categorías |
| `respuesta_cat` | `Cuestionario.RespuestaCategoria` | Relación respuesta ↔ categoría (categorización automática/IA) |
| `orden_cat` | `Cuestionario.OrdenCategoria` | Calificación de **importancia** por categoría y usuario |
| `calif_cat` | `Cuestionario.CalificacionCategoria` | Calificación de **cumplimiento** por categoría y usuario |

Todas las tablas se filtran por `id_sesion` (una sesión, una lista de sesiones, o `"Todo"`).

## El objeto `parametros`

Todo el estilo visual se inyecta por fuera vía una lista `parametros`. [`parametros_default()`](R/utilitaria_parametros.R) trae los 15 campos con defaults documentados — para un caso nuevo basta sobreescribir los valores de marca (`parametros_default(primario = "#7A1E3B")`) en vez de rearmarla a mano. Campos:

```r
parametros <- list(
  primario, primario_claro, primario_obscuro,   # paleta de marca
  inverso, inverso_claro,                       # color complementario
  sm_vf, sm_vc, sm_a, sm_rc, sm_rf,              # semáforo brecha: verde fuerte -> rojo fuerte
  cortes,                                        # 6 puntos de corte para el semáforo (0 a 10000)
  familia,                                       # familia tipográfica (Google Fonts)
  gris, gris_claro,                              # texto/ejes
  etiquetas                                      # tamaño de fuente de ejes, ej. "12px"
)
```

`inverso*`/`primario*` no tienen semántica fija: en un caso `inverso` es la marca y `primario` el neutro, en otro al revés — la asignación es manual por proyecto.

## Flujo de trabajo (pipeline)

```
leer_base()
    └─ procesar_*()        limpieza/agregación (dplyr, quanteda, tidytext)
         └─ graficar_*() / generar_tabla*()   objetos highcharter/ggplot/kable/DT/visNetwork
              └─ imprimir_*()                 arma el chunk de xaringan como texto (glue + knitr::knit_expand)
                   └─ slides_*()              recorre preguntas/etapas y concatena todos los chunks
                        └─ knitr::knit(...)   se inserta en el .Rmd de xaringan (ver prueba_deb.Rmd)
```

### Procesamiento (`R/analisis_procesar_pregunta.R`)

| Función | Qué hace | Se usa con |
|---|---|---|
| `procesar_p_abierta(bd, pregunta, etapa, parametros, quitar_altisonantes)` | Tokeniza una pregunta abierta, cuenta frecuencia de palabras, filtra altisonantes y stopwords en español, asigna color por cuantil (75/90) | `graficar_nube`, `generar_tabla_nube` |
| `procesar_brecha(bd, otro, quitar_altisonantes)` | % de respuestas por tema (etapa 2) + top-3 palabras clave por tema vía keyness (`quanteda.textstats`) | `graficar_brecha` |
| `procesar_r_tema(bd, top_p, top_r, otro, quitar_altisonantes)` | Top-`top_r` respuestas y top-`top_p` palabras clave (G2/log-likelihood) por tema | *(actualmente desconectado — ver Áreas de mejora)* |
| `procesar_numerica(bd, tipo)` | Histograma + media/error estándar (`ggplot2::mean_se`) para `"Orden"` (importancia) o `"Calificacion"` (cumplimiento) | `graficar_numerica` |
| `procesar_juntos(bd)` / `procesar_juntos_promedio(bd)` | Cruce importancia × cumplimiento, a nivel respuesta o a nivel promedio por tema; define `brecha = Orden*(100-Calificacion)` | `graficar_juntos*` |
| `calcular_brecha(bd, corte, parametros)` | Brecha promedio por tema + semáforo (`corte()`) contra `parametros$cortes` | `graficar_nbrecha`, `generar_tabla` |
| `procesar_bigramas(bd, pregunta, etapa, parametros, quitar_altisonantes)` | Bigramas frecuentes de una pregunta abierta (top 30 sobre percentil 70) | `graficar_bigramas` |
| `corte(brecha, parametros)` | Clasifica un valor de brecha en el semáforo de 5 colores | uso interno |

### Resúmenes con IA (`R/analisis_resumir_ia.R`)

`resumir_respuestas(pregunta, respuestas, url, cache_dir, timeout, reintentos)`
unifica el bloque `POST -> content -> fromJSON` que antes se copiaba en cada
script del caso: usa `httr2` con timeout y reintentos con backoff, falla
explícito si el status no es 200 o falta `$data`, y cachea el resultado en
disco por hash de `(pregunta, respuestas)` (`cache_dir = NULL` desactiva el
cache) para que un re-render no vuelva a pagar el costo del LLM.

### Visualización (`R/analisis_graficar_preguntas.R`)

| Función | Tipo de gráfica | Motor |
|---|---|---|
| `graficar_nube` | Nube de palabras interactiva | highcharter |
| `graficar_brecha` | Treemap de % de respuestas por tema | highcharter |
| `graficar_numerica` | Barras apiladas (`"histograma"`) o barras de error/point-range (`"point_range"`); cada tipo tiene rama interactiva y estática | highcharter / ggplot2 |
| `graficar_juntos_promedio` | Dispersión importancia vs. cumplimiento (promedio por tema) sobre fondo de semáforo | ggplot2 |
| `graficar_juntos` | Igual, pero simulando una nube de puntos por tema (`rnorm` alrededor de la media/sd observada) + `geom_hex`, faceteado | ggplot2 |
| `graficar_nbrecha` | Densidad de la brecha por grupo de semáforo (`densidad=T`) o barras tipo "chicklet" de probabilidad por color (`densidad=F`) | ggplot2 |
| `generar_tabla` | Tabla resumen de brecha con celda coloreada por semáforo | kableExtra |
| `generar_tabla_nube` | Tabla paginada de respuestas | DT |
| `graficar_bigramas` | Red de bigramas | visNetwork |
| `tema_high` | Tema tipográfico reusable para highcharter | highcharter |

### Ensamblado de slides (`R/desarrollo_preparar_slides.R`, `R/desarrollo_preparar_etapas.R`)

- `imprimir_*()` — cada una arma **un** chunk de xaringan como string (`glue` + `knitr::knit_expand`). La mayoría siguen atadas a nombres de variables que deben existir en el entorno donde se knitea el chunk (`p_{i}`, `hc`, `tabla_df`, `brecha2`...), necesario porque ahí es donde viven los objetos highcharter/ggplot que knitr todavía tiene que evaluar; `imprimir_gt()` es la excepción — llama a [resumir_respuestas()] al armar el chunk y embebe el resumen como texto literal, sin depender de ninguna variable por nombre.
- `slides_nubes(bd, etapa, parametros, thm, url)` — recorre las preguntas abiertas de una etapa y concatena nube + tabla por pregunta.
- `slides_etapa_2(bd, top_p, top_r, otro, parametros, thm, url)` — arma toda la etapa de brecha: treemap, tablas por pregunta, importancia/cumplimiento, análisis conjunto, densidad de brecha y tabla resumen.

## Configuración de credenciales

`leer_base()` requiere estas variables de entorno (ver `.Renviron.example` en la raíz del repo):

| Variable | Requerida | Default |
|---|---|---|
| `ABPVIRTUAL_DB_SERVER` | sí | — |
| `ABPVIRTUAL_DB_DATABASE` | sí | — |
| `ABPVIRTUAL_DB_UID` | sí | — |
| `ABPVIRTUAL_DB_PWD` | sí | — |
| `ABPVIRTUAL_DB_DRIVER` | no | `ODBC Driver 17 for SQL Server` |
| `ABPVIRTUAL_DB_PORT` | no | `1433` |

Para desarrollo local: copiar `.Renviron.example` a `.Renviron` en la raíz del proyecto (ya está en `.gitignore`, nunca se commitea) y llenar los valores reales; R los carga automáticamente al iniciar sesión en el proyecto. Para `respuestas/app.R` desplegado (p. ej. shinyapps.io), configurarlas como variables de entorno del entorno de despliegue.

## Áreas de mejora

Pensando en replicar este ejercicio en un proyecto nuevo, esto es lo que limitaría velocidad o calidad si se reutiliza tal cual:

### 🔴 Seguridad (antes de tocar cualquier otra cosa)

- ✅ **Credenciales de base de datos ya no viven en el código.** `leer_base()` (`R/utilitaria_colectar_base.R`) ahora lee la conexión desde variables de entorno y falla explícitamente si faltan; `data/conexion.rda` (el `.rda` que las tenía en texto plano, resuelto) se quitó del tracking de git y de `data-raw/DATASET.R`; `respuestas/app.R` ya no trae una segunda copia hardcodeada — usa `abpvirtualr::leer_base()`. Ver **Configuración de credenciales** más abajo para el setup local.
- ⚠️ **Pendiente, acción manual — no lo puedo hacer desde aquí:**
  - **Rotar la contraseña real** de la base de datos con el administrador. Estuvo expuesta en texto plano en el código durante todo el historial del repo; el fix de arriba evita que se siga exponiendo hacia adelante, pero no invalida la contraseña ya filtrada.
  - **El historial de git sigue conteniendo el password en texto plano** (commits viejos a `data-raw/DATASET.R`, `respuestas/app.R`, y el blob viejo de `data/conexion.rda`). Purgarlo requiere reescribir el historial (`git filter-repo` o BFG) + force-push, lo cual invalida cualquier otro clon del repo — es una acción a coordinar y programar aparte, no algo para hacer de paso.
  - Unificar credenciales entre proyectos: `abp_sonora` (`R/pool.R`) tiene el mismo patrón de credenciales hardcodeadas para otra base de datos — mismo tipo de fuga, en otro repo.

### Análisis de datos

- ✅ **Umbrales de "brecha" y de nube de palabras ya son parametrizables y están documentados**: `procesar_p_abierta(cuantiles = c(.75, .90))` y `procesar_bigramas(p = .7)` exponen los cuantiles/percentil como argumentos con el mismo default de antes; `?parametros_default` documenta por qué `cortes` va de 0 a 10000 (rango teórico de `Orden * (100 - Calificacion)`).
- ✅ **`procesar_r_tema()` ya no queda como código muerto a medias**: el bloque comentado que la invocaba dentro de `slides_etapa_2()` se eliminó (quedó obsoleto desde el fix del bucle por pregunta en el commit `b2c0410`, que ya lo había sustituido por un bucle más simple). `procesar_r_tema()` se mantiene exportada y documentada por si se quiere retomar la vista de palabras clave por tema en el proyecto nuevo, pero ya no confunde como "código a medio conectar".
- **`graficar_juntos()` simula datos con `rnorm()` en vez de graficar las respuestas reales** (líneas 328-334 de `R/analisis_graficar_preguntas.R`): genera 100 puntos normales por tema a partir de la media/sd observada, y esos puntos simulados —no las respuestas— son los que entran al `geom_hex`. Es una forma válida de suavizar una nube dispersa, pero tal como está no es obvio para quien lee el código que la gráfica muestra una simulación y no los datos crudos; conviene un comentario explícito o, mejor, graficar los datos reales con jitter y reservar la simulación (si se necesita) para una vista aparte.
- **Sin pruebas ni datos de referencia**: no hay `tests/` ni `usethis::use_testthat()`. Funciones con lógica no trivial (`corte()`, `calcular_brecha()`, el cálculo de keyness) no tienen manera de detectar una regresión al cambiar los cortes o al procesar un caso con estructura distinta (p. ej. una etapa con 0 respuestas, categorías repetidas, o `NA` en `Calificacion`/`Orden`).
- ✅ **`mode()` ya no redefine la función base de R**: la lógica vive en `moda()`; `mode()` queda como alias retro-compatible con `.Deprecated("moda")`.
- **Dependencia de rutas relativas con `load("data/...")` dentro de funciones exportadas** (`leer_base`, `procesar_p_abierta`, `procesar_brecha`, `procesar_r_tema`, `procesar_bigramas`): sólo funciona si el working directory es la raíz del paquete. Cambiar a `system.file("data", "conexion.rda", package = "abpvirtualr")` o, mejor, usar los objetos ya expuestos por `LazyData` (`data(altisonantes)`, `data(conexion)`) sin `load()` manual.

### Visualización de datos

- **Estilo repetido en cada función en vez de centralizado**: tamaños de fuente, `fontFamily`, colores de tooltip, etc. se repiten a mano en cada `graficar_*` (`tema_high()` sólo cubre una parte). Un tema base compartido (para highcharter y otro para ggplot, aplicados siempre al final del pipe) reduciría inconsistencias entre gráficas del mismo deck y facilitaría un rebranding rápido para el proyecto nuevo (cambiar 1 tema en vez de 10 funciones). **Pendiente**: requiere decidir la API del tema compartido y verificarlo con un render real, no se hizo en esta rama.
- ✅ **Accesibilidad de color**: `generar_tabla()` agrega una columna `Semaforo` con la etiqueta de texto del nivel (`etiqueta_semaforo()`, ej. "Verde fuerte") junto a la celda coloreada — no depende solo del color para audiencias con daltonismo rojo-verde.
- ✅ **`<b/>` mal cerrado corregido** en `graficar_nube()` y el `pointFormat` sin negritas de `graficar_numerica(tipo="histograma")`.
- **`graficar_numerica()` y `graficar_nbrecha()` mezclan la rama interactiva/estática y la de densidad/barra dentro de la misma función con `if/else` largos**: son casi dos funciones distintas por rama. Separarlas (o usar un patrón `switch` con funciones auxiliares) simplificaría agregar un tercer tipo de gráfica para el proyecto nuevo sin tocar código existente que ya funciona. **Pendiente** (mismo motivo que el tema centralizado).
- 🔴 **`graficar_nbrecha(densidad = FALSE)` está roto incluso con datos normales** (encontrado en esta rama): la rama de barras "chicklet" por probabilidad referencia una columna `prob` que `calcular_brecha()` nunca calculó (`objeto 'prob' no encontrado`). Arreglarlo requiere decidir qué agregación de negocio debe producir esa proporción — no algo para adivinar en una función que ve el cliente final.
- ✅ **Contrato "sin datos"**: `generar_tabla()` regresaba un error de kableExtra con una brecha vacía (sesión sin pares completos de Orden/Calificacion); ahora regresa una tabla "Sin datos suficientes". `graficar_nube()` y `graficar_nbrecha(densidad=TRUE)` ya manejaban vacío correctamente (verificado).
- ✅ **`graficar_juntos()` ya no simula sin avisar**: nuevo argumento `simular = TRUE` (default, sin cambio de comportamiento) agrega un caption explícito al slide; `simular = FALSE` grafica las respuestas reales con jitter. No se cambió el default para no alterar reportes ya validados sin poder verificarlo con un render real.

### Empaquetado / mantenibilidad general

- ✅ **`DESCRIPTION` completo** (título, autor, versión `0.1.0`, licencia MIT) y `Imports` sincronizado (`DT`, `httr2`, `digest` declarados).
- ✅ **`slides_nubes()`/`slides_etapa_2()` ya no usan `eval(parse(...))`** para la parte de resúmenes de IA: al investigar esto se encontró que llamaban a una función (`imprimir_gt()`) borrada del paquete hace 2 años — cualquier render con resumen de IA fallaba. Se reintrodujo usando `resumir_respuestas()` (llamada de una vez, resumen embebido como texto literal) y se quitó el `eval(parse())` correspondiente; ver Roadmap sección 5 para el detalle de qué queda abierto (el rediseño más profundo de `imprimir_*`/`slides_*` para las gráficas, que requiere un render de humo real para verificarse).
- ✅ **`NEWS.md` y versión activa** (`0.1.0`) — ver `NEWS.md`.
- ✅ **`slides_nubes()`/`slides_etapa_2()` no tenían default para `url`** y el skeleton las llamaba sin pasarlo — cualquier render tronaba con `argument "url" is missing` en cuanto llegaba a un resumen de IA (encontrado al verificar el skeleton para el fix de abajo). Ahora `url` tiene el mismo default que `resumir_respuestas()`.
- ✅ **El skeleton ya no depende de `Sys.setlocale("es_ES.UTF-8")`** para la fecha (fallaba en silencio —fecha en inglés— en máquinas sin ese locale): usa `fecha_es()`, que no depende del locale del sistema.
- ✅ **`cache = TRUE` global del skeleton reemplazado por `cache = FALSE` + `cache = TRUE` explícito solo en el chunk de `leer_base()`** (el único caro), con comentario de cómo invalidarlo.
- ✅ **`.gitignore` generalizado** (`*_cache/`, `*_files/`, `figure/`, `output/`) en vez de nombres específicos de un solo `.Rmd` de prueba.
- ✅ **CI** (`.github/workflows/R-CMD-check.yaml`): `R CMD check` + la suite de testthat corren en cada push/PR contra `main`. Al armarlo se encontró que `ggchicklet` (en `Imports`) sólo existe en GitHub y `DESCRIPTION` no tenía `Remotes:` — una instalación limpia no podía resolverla; ya se agregó. Pendiente de confirmar que corre en verde al hacer push (no se puede verificar sin un push real a GitHub).

### Prioridad sugerida para el proyecto nuevo

1. ✅ ~~Rotar credenciales + sacarlas del repo~~ — credenciales sacadas del código (env vars); **falta rotar el password real y, cuando se pueda coordinar, purgar el historial de git** (ver arriba).
2. ✅ ~~Resolver `procesar_r_tema()` vs. el bucle ad-hoc en `slides_etapa_2()`~~ — código muerto eliminado.
3. Centralizar tema visual (highcharter + ggplot) para que el rebranding del caso nuevo sea de una sola línea.
4. Agregar pruebas mínimas a `corte()`, `calcular_brecha()` y `procesar_numerica()` — son las que definen el semáforo y los promedios que ve el cliente.
5. Completar `DESCRIPTION`/`Imports` y mover `load("data/...")` a `system.file()`.
