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

Ninguna función trae valores por defecto: todo el estilo visual se inyecta por fuera vía una lista `parametros` que el usuario arma a mano en cada proyecto (ver `data-raw/prueba.R`). Campos usados en el código:

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

- `imprimir_*()` — cada una arma **un** chunk de xaringan como string (`glue` + `knitr::knit_expand`), atado a nombres de variables que se esperan en el *entorno global* (`p_{i}`, `q_{i}`, `r_{i}`, `hc`, `tabla_df`, `brecha2`...).
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

- **Umbrales de "brecha" y de nube de palabras no son parametrizables ni documentados como decisión metodológica**: los cuantiles 0.75/0.90 para colorear la nube (`procesar_p_abierta`), el percentil 0.7 para bigramas y los 6 cortes fijos de `parametros$cortes` (0–10000) son elecciones de negocio metidas en el código. Para un caso nuevo con otra distribución de respuestas conviene exponerlos como argumentos con default, y documentar por qué esos cortes.
- ✅ **`procesar_r_tema()` ya no queda como código muerto a medias**: el bloque comentado que la invocaba dentro de `slides_etapa_2()` se eliminó (quedó obsoleto desde el fix del bucle por pregunta en el commit `b2c0410`, que ya lo había sustituido por un bucle más simple). `procesar_r_tema()` se mantiene exportada y documentada por si se quiere retomar la vista de palabras clave por tema en el proyecto nuevo, pero ya no confunde como "código a medio conectar".
- **`graficar_juntos()` simula datos con `rnorm()` en vez de graficar las respuestas reales** (líneas 328-334 de `R/analisis_graficar_preguntas.R`): genera 100 puntos normales por tema a partir de la media/sd observada, y esos puntos simulados —no las respuestas— son los que entran al `geom_hex`. Es una forma válida de suavizar una nube dispersa, pero tal como está no es obvio para quien lee el código que la gráfica muestra una simulación y no los datos crudos; conviene un comentario explícito o, mejor, graficar los datos reales con jitter y reservar la simulación (si se necesita) para una vista aparte.
- **Sin pruebas ni datos de referencia**: no hay `tests/` ni `usethis::use_testthat()`. Funciones con lógica no trivial (`corte()`, `calcular_brecha()`, el cálculo de keyness) no tienen manera de detectar una regresión al cambiar los cortes o al procesar un caso con estructura distinta (p. ej. una etapa con 0 respuestas, categorías repetidas, o `NA` en `Calificacion`/`Orden`).
- **`mode()` redefine una función base de R** (`R/analisis_procesar_pregunta.R:338`, calcula moda, no el `mode` de tipos de R) — riesgo de bugs silenciosos si algún código interno depende del `mode()` real de R después de cargar el paquete. Conviene renombrar a `moda()`.
- **Dependencia de rutas relativas con `load("data/...")` dentro de funciones exportadas** (`leer_base`, `procesar_p_abierta`, `procesar_brecha`, `procesar_r_tema`, `procesar_bigramas`): sólo funciona si el working directory es la raíz del paquete. Cambiar a `system.file("data", "conexion.rda", package = "abpvirtualr")` o, mejor, usar los objetos ya expuestos por `LazyData` (`data(altisonantes)`, `data(conexion)`) sin `load()` manual.

### Visualización de datos

- **Estilo repetido en cada función en vez de centralizado**: tamaños de fuente, `fontFamily`, colores de tooltip, etc. se repiten a mano en cada `graficar_*` (`tema_high()` sólo cubre una parte). Un tema base compartido (para highcharter y otro para ggplot, aplicados siempre al final del pipe) reduciría inconsistencias entre gráficas del mismo deck y facilitaría un rebranding rápido para el proyecto nuevo (cambiar 1 tema en vez de 10 funciones).
- **Falta de accesibilidad de color**: la paleta de semáforo (`sm_vf`...`sm_rf`, verde→rojo) no tiene redundancia de forma/patrón, problemático para daltonismo rojo-verde, común en el tipo de audiencia de gobierno/ejecutivos. Añadir íconos, texto o etiquetas de nivel junto al color en `graficar_nbrecha`/`generar_tabla`.
- **Etiquetas y `pointFormat` con `<b/>` mal cerrado** (debería ser `</b>`) en varios tooltips de highcharter (`graficar_nube`, `graficar_numerica`) — no rompe el render pero es HTML inválido que puede comportarse distinto entre navegadores.
- **`graficar_numerica()` y `graficar_nbrecha()` mezclan la rama interactiva/estática y la de densidad/barra dentro de la misma función con `if/else` largos**: son casi dos funciones distintas por rama. Separarlas (o usar un patrón `switch` con funciones auxiliares) simplificaría agregar un tercer tipo de gráfica para el proyecto nuevo sin tocar código existente que ya funciona.
- **No hay control de "sin datos" consistente**: algunas funciones regresan `NULL` en caso vacío (`graficar_nube`), otras no verifican (`graficar_juntos_promedio` truena si `res` está vacío). Para un caso nuevo con menos participantes o preguntas opcionales, esto puede tumbar la generación de slides a la mitad. Vale la pena un contrato uniforme (todas regresan `NULL` + un slide "sin datos suficientes" en `imprimir_*`).

### Empaquetado / mantenibilidad general

- `DESCRIPTION` sigue con los placeholders de `usethis::create_package()` (título, autor, licencia genéricos) — vale la pena completarlo antes del proyecto nuevo, ya que términos de imports (`Imports:`) no cubren todo lo usado (p. ej. `DT`, `visNetwork` se usan pero no están declarados).
- El ensamblado de slides via `eval(parse(text = glue::glue(...)))` (`slides_nubes`, `slides_etapa_2`) asigna variables al entorno global por nombre dinámico (`p_{i}`, `q_{i}`...) — funciona, pero es frágil (colisiones de nombres, difícil de debuggear, imposible de testear unitariamente). Para el proyecto nuevo, considerar pasar una lista con los datos de cada slide directamente a `imprimir_*()` en vez de inyectar variables por nombre en el entorno del knit.
- No hay `NEWS.md`/versión activa (`Version: 0.0.0.9000` desde el inicio) — sin manera de saber, al empezar el proyecto nuevo, qué cambió respecto al ejercicio anterior.

### Prioridad sugerida para el proyecto nuevo

1. ✅ ~~Rotar credenciales + sacarlas del repo~~ — credenciales sacadas del código (env vars); **falta rotar el password real y, cuando se pueda coordinar, purgar el historial de git** (ver arriba).
2. ✅ ~~Resolver `procesar_r_tema()` vs. el bucle ad-hoc en `slides_etapa_2()`~~ — código muerto eliminado.
3. Centralizar tema visual (highcharter + ggplot) para que el rebranding del caso nuevo sea de una sola línea.
4. Agregar pruebas mínimas a `corte()`, `calcular_brecha()` y `procesar_numerica()` — son las que definen el semáforo y los promedios que ve el cliente.
5. Completar `DESCRIPTION`/`Imports` y mover `load("data/...")` a `system.file()`.
