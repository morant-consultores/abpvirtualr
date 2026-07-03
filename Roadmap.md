# Roadmap de mejora — abpvirtualr / proceso ABP

Este documento parte de los cambios más recientes (`b2c0410` fix del bucle por
pregunta, `ef39542` credenciales fuera del código, `83dbb71` `parametros_default()`
y skills de render) y del caso `abp_sonora` que operó en producción. Recorre
**cada paso del proceso** — de la captura de respuestas a la entrega del reporte —
identifica qué se puede mejorar en cada uno, y define la **puerta de calidad**
(suite de pruebas en `tests/testthat/`) que debe pasar antes de aceptar cualquier
cambio como terminado. `main` no se toca hasta que la suite esté en verde y los
pendientes manuales de seguridad estén resueltos.

**Estado del gate:** la suite corre con `devtools::test()` (o
`testthat::test_local()`). Ver sección 9.

---

## 0. Seguridad y credenciales (bloqueante, antes que todo lo demás)

**Estado actual.** En `abpvirtualr` las credenciales ya salieron del código
(`leer_base()` lee `ABPVIRTUAL_DB_*` de variables de entorno). Pero:

- 🔴 `abp_sonora/R/pool.R` y `abp_sonora/g1.qmd` (bloque `params:`) siguen
  conteniendo usuario y contraseña reales de Azure SQL en texto plano,
  commiteados.
- 🔴 `abp_sonora/R/entregable.R:174` contiene una API key de OpenAI
  (`sk-N8Cw...`) en texto plano, commiteada.
- 🔴 El historial de git de ambos repos conserva los secretos aunque se
  eliminen del código actual.

**Mejoras.**

| # | Acción | Tipo |
|---|--------|------|
| 0.1 | **Rotar ya** la contraseña de la BD (`morant.database.windows.net`) y la API key de OpenAI. Toda credencial que tocó git se considera comprometida. | Manual, urgente |
| 0.2 | Migrar `abp_sonora/R/pool.R` y los `params` de `g1.qmd` al mismo esquema `ABPVIRTUAL_DB_*` de `leer_base()`; nunca pasar contraseñas como `params` de un `.qmd`/`.Rmd` (quedan embebidas en el HTML renderizado con `embed-resources: true`). | Código |
| 0.3 | Leer la key de OpenAI de `OPENAI_API_KEY` (env var); nunca como literal. | Código |
| 0.4 | Purgar historial (`git filter-repo`/BFG) de ambos repos, coordinado con todos los clones. | Manual, coordinado |
| 0.5 | Prueba automática que escanea las fuentes del paquete en busca de patrones de secretos (`PWD =`, `sk-...`, contraseñas conocidas) — ya en la suite (`test-seguridad.R`) para que una regresión no pase el gate. | Test ✅ |

## 1. Captura y lectura de datos (`leer_base()`)

**Estado actual.** Descarga 7 tablas completas o filtradas por `IdSesion`, abre
y cierra un pool por llamada, sin validación del id de sesión ni manejo de
errores de red. En `abp_sonora` los ids de sesión van *hardcodeados* y
duplicados en varios scripts (`ids <- c("2776", ...)` aparece 2 veces solo en
`entregable.R`; la lista `bd` incluso repite `RespuestaFiltrada` dos veces).

**Mejoras.**

- 1.1 Validar `id_sesion` (existe en `General.Sesion`, no vacío) y fallar con
  mensaje claro en vez de regresar tibbles vacíos que truenan 5 pasos después.
- 1.2 `on.exit(pool::poolClose(con))` para no filtrar conexiones cuando una
  consulta falla a la mitad.
- 1.3 Traer `Etapa`/`Pregunta`/`Categoria` una sola vez (son catálogos) y
  permitir inyectar una conexión existente (facilita mocks y reuso en Shiny).
- 1.4 Definir el contrato de salida (nombres y columnas mínimas de la lista) y
  validarlo — es el contrato del que dependen todos los `procesar_*`.
- 1.5 En el caso (ej. `abp_sonora`): una sola fuente de verdad para los ids de
  sesión (un `params.R`/yaml del caso), no copias por script.

**Tests del gate:** estructura de la lista `bd` sintética usada por todos los
tests (`helper-datos.R`) documenta el contrato 1.4; pruebas de conexión real
quedan fuera del gate (requieren BD) y se marcan `skip_if_not` por env var.

## 2. Procesamiento (`procesar_*`, `corte`, `calcular_brecha`)

**Estado actual.** Lógica correcta en el caso feliz, pero con decisiones de
negocio enterradas (cuantiles 0.75/0.90, percentil 0.7, cortes 0–10000),
`load("data/altisonantes.rda")` con ruta relativa dentro de funciones
exportadas (solo funciona si el wd es la raíz del repo), `corte()` leyendo
`parametros$corte` (funciona por *partial matching* accidental, el campo real
es `cortes`), `mode()` haciendo *shadowing* de `base::mode`, y ningún contrato
para datos vacíos o con `NA`.

**Mejoras.**

- 2.1 ✅ `corte()` usa `parametros$cortes` explícito (fix en esta rama; con
  test de frontera por cada banda del semáforo).
- 2.2 ✅ `altisonantes` se obtiene del *lazy data* del paquete vía
  `utils::data()` con fallback, no de una ruta relativa (fix en esta rama;
  `procesar_p_abierta`, `procesar_brecha`, `procesar_r_tema`,
  `procesar_bigramas`).
- 2.3 Exponer umbrales como argumentos con default documentado:
  `procesar_p_abierta(cuantiles = c(.75, .90))`, `procesar_bigramas(p = .7)`,
  y documentar la metodología de `cortes` en `?parametros_default`.
- 2.4 Renombrar `mode()` → `moda()` (manteniendo alias deprecado un ciclo).
- 2.5 Contrato uniforme de "sin datos": todo `procesar_*` regresa una
  estructura vacía tipada (no error) y todo `graficar_*`/`imprimir_*` la
  traduce a un slide "sin datos suficientes".
- 2.6 Manejo explícito de `NA` en `Calificacion`/`Orden` (hoy `na.omit()`
  silencioso puede tirar usuarios completos sin avisar) — al menos un
  `message()` con el conteo descartado.

**Tests del gate:** `test-corte.R`, `test-brecha.R`, `test-numerica.R`,
`test-procesar-abierta.R` (con y sin altisonantes, y wd ≠ raíz del paquete).

## 3. Resúmenes con IA (API Flask / OpenAI)

**Estado actual.** El bloque `POST → content → fromJSON` está copiado 4+ veces
entre `api_resumidor.R` y `entregable.R` de `abp_sonora`, sin timeout, sin
reintentos, sin verificar `status_code`, con URL hardcodeada, y el resultado no
se cachea (cada re-render vuelve a pagar el costo del LLM).

**Mejoras.**

- 3.1 Una sola función en el paquete: `resumir_respuestas(pregunta, respuestas,
  url = getOption("abpvirtual.api_url"))` con `httr2`, timeout, reintentos con
  backoff y error explícito si `status != 200` o el JSON no trae `$data`.
- 3.2 Cachear resúmenes por hash de (pregunta + respuestas) en disco
  (`memoise` o un rds por sesión) — re-render barato y reproducible.
- 3.3 Registrar qué modelo/prompt generó cada resumen (auditoría del
  entregable).
- 3.4 El categorizador Python (`pruebas_categorizador.py` vía `reticulate`)
  debería vivir en el servicio Flask o en el paquete, no como script suelto
  con la key incrustada (ver 0.3).

**Tests del gate:** unit test de la función nueva con *webfakes*/mock cuando se
implemente 3.1 (hoy no hay función en el paquete que probar; queda como
criterio de aceptación de 3.1).

## 4. Visualización (`graficar_*`, `generar_tabla*`)

**Estado actual.** Estilo repetido a mano en cada función, `<b/>` inválido en
tooltips, ramas interactivo/estático mezcladas en funciones largas,
`graficar_juntos()` grafica puntos simulados con `rnorm()` sin advertirlo, y
comportamiento inconsistente ante datos vacíos.

**Mejoras.**

- 4.1 Tema central único (uno highcharter, uno ggplot) construido desde
  `parametros`, aplicado al final de cada pipe — rebranding de un caso nuevo
  en una línea.
- 4.2 Corregir `<b/>` → `</b>` en todos los `pointFormat`.
- 4.3 Separar ramas (`graficar_numerica_interactiva()` /
  `_estatica()`, o `switch` interno con auxiliares) antes de agregar un tipo
  de gráfica nuevo.
- 4.4 Accesibilidad del semáforo: etiqueta textual del nivel junto al color en
  `graficar_nbrecha`/`generar_tabla` (audiencia gobierno, daltonismo
  rojo-verde).
- 4.5 Documentar (o reemplazar) la simulación de `graficar_juntos()`: jitter
  de datos reales por default, simulación opt-in con nota en el slide.
- 4.6 Contrato "sin datos" (ver 2.5).

**Tests del gate:** los `procesar_*` que alimentan estas gráficas están
cubiertos; snapshot tests de gráficas quedan para cuando exista el tema
central (4.1), si no cada refactor visual rompería snapshots triviales.

## 5. Ensamblado de slides (`imprimir_*`, `slides_*`)

**Estado actual.** `slides_nubes()`/`slides_etapa_2()` generan código con
`glue` y lo evalúan con `eval(parse(...))` asignando variables por nombre
(`p_{i}`, `q_{i}`, `brecha2`, `tabla_df`) al entorno global del knit. Funciona,
pero es frágil (colisiones, imposible de testear unitario, debugging a ciegas).

**Mejoras.**

- 5.1 Pasar datos explícitos: `imprimir_*(datos_slide)` recibe la lista con lo
  que grafica, y `slides_*` regresa una lista de chunks + una lista de datos,
  sin tocar el entorno global.
- 5.2 Mientras tanto: prefijo namespaced (`.abp_p_1`) para reducir riesgo de
  colisión con variables del usuario en el `.Rmd`.
- 5.3 `imprimir_calc_brecha()` y `imprimir_juntos*()` tienen chunks con labels
  fijos (`etapa_3-4`...) — al repetir una etapa en el mismo deck colisionan;
  generar labels únicos por invocación.

**Tests del gate:** `imprimir_nube()`/`imprimir_tabla_nube()` son funciones
puras string → string y se prueban hoy (estructura del chunk generado);
`slides_*` completos requieren el refactor 5.1 para ser testeables.

## 6. Render y entrega del reporte (skeleton xaringan, `g1.qmd`, entregables)

**Estado actual.** El skeleton ya usa `parametros_default()` y `leer_base()`
sin credenciales (mejora reciente). En el caso `abp_sonora`: `g1.qmd` pasa
credenciales por `params` (ver 0.2), los scripts `entregable*.R` escriben a
rutas personales (`~/Desktop/Peticiones maestro/...`), y el repo commitea
artefactos pesados (HTML de 6k líneas en `AO/`, `skeleton_cache/`, jquery
vendorizado) que ya están causando diffs binarios gigantes.

**Mejoras.**

- 6.1 Un solo entrypoint de render por caso:
  `rmarkdown::render(..., params = list(sesion = X))` parametrizado por sesión,
  en lugar de editar el `.Rmd`/script a mano por grupo (los `g1_1.html`,
  `g1_2.html`... sugieren renders manuales repetidos).
- 6.2 Salidas a un directorio `output/` del caso (gitignoreado), nunca a
  `~/Desktop`.
- 6.3 `.gitignore` para `*_cache/`, `*_files/`, HTML renderizados; los
  entregables van a un almacenamiento de entrega (Drive/SharePoint/release),
  no al repo fuente.
- 6.4 `cache = TRUE` global en el skeleton es peligroso con datos vivos (un
  re-render con datos nuevos puede servir resultados viejos); cachear solo
  chunks caros y documentar cuándo invalidar.
- 6.5 El título/fecha del skeleton depende de `Sys.setlocale("es_ES.UTF-8")`
  que falla silencioso en Windows/Linux con otro locale — envolver en
  `tryCatch`.

**Tests del gate:** `validar_parametros()` ya protege el punto de entrada del
skeleton (falla al primer error con mensaje claro); render end-to-end requiere
BD y queda como prueba manual del checklist (sección 9).

## 7. Empaquetado y mantenibilidad

**Estado actual.** `DESCRIPTION` con placeholders de `usethis`, `Imports`
desincronizado del uso real, sin pruebas (hasta esta rama), sin `NEWS.md`, sin
CI. `spatstat.core` está **archivado en CRAN**: una máquina nueva no puede
instalar el paquete — y ni siquiera se usa (solo un `@importFrom` huérfano).

**Mejoras.**

- 7.1 ✅ Limpiar `Imports`: quitar `spatstat.core` (archivado, sin uso), `tm`,
  `wordcloud`, `RColorBrewer` (sin uso); declarar `DT` (sí se usa); `testthat`
  a `Suggests` (fix en esta rama).
- 7.2 Completar `DESCRIPTION` (título, autor, licencia) y arrancar `NEWS.md` +
  versión `0.1.0` al cerrar esta rama.
- 7.3 `renv::snapshot()` tras 7.1 para que `renv.lock` refleje el estado real.
- 7.4 CI (GitHub Actions `R-CMD-check` + `testthat`) para que el gate corra
  solo en cada PR.
- 7.5 Consolidar: `abp_sonora/R/funciones.R` (12.7K) duplica funciones del
  paquete con divergencias — todo lo genérico vive en `abpvirtualr`, el caso
  solo configura.

**Tests del gate:** la suite completa es el test; `R CMD check` limpio es
criterio de 7.4.

## 8. Proceso por caso nuevo (lo que hoy es manual en abp_sonora)

- 8.1 El skill `new-report` ya scaffoldea el caso; extenderlo para generar
  también `params.R` del caso (ids de sesión, marca) y el `.Renviron` a partir
  del example.
- 8.2 Checklist de arranque de caso: credenciales en env vars → sesión de
  prueba → render de humo → revisión de umbrales (2.3) con la distribución
  real del caso.
- 8.3 Documentar en `README` del caso qué se entrega (qué HTML, a quién, con
  qué datos y fecha) — los commits "Entregables G1" no dejan rastro de qué
  sesiones/parametrización los generaron.

---

## 9. Puerta de calidad (gate) — qué debe pasar antes de aceptar un cambio

**Automático (bloqueante, corre con `devtools::test()`):**

1. `test-parametros.R` — defaults válidos; override de marca; detección de
   campo faltante, hex inválido, `cortes` mal formados, `etiquetas` sin "px".
2. `test-corte.R` — cada banda del semáforo con valores de frontera;
   `include.lowest`; fuera de rango → `NA`.
3. `test-brecha.R` — `procesar_juntos()` (fórmula `Orden*(100-Calificacion)`,
   `na.omit` de pares incompletos), `procesar_juntos_promedio()` (redondeos),
   `calcular_brecha()` (promedios por tema, semáforo consistente con
   `corte()`, `brecha_pct`).
4. `test-numerica.R` — `procesar_numerica()` para `Orden` y `Calificacion`
   (media, redondeos, un renglón por categoría).
5. `test-procesar-abierta.R` — tokenización sin stopwords ni números; colores
   por cuantil; filtrado de altisonantes; **funciona con working directory
   distinto a la raíz del paquete**.
6. `test-imprimir.R` — chunks generados bien formados (fence de apertura y
   cierre, llamada a la función de graficado correcta, título presente).
7. `test-seguridad.R` — ningún archivo fuente del paquete contiene patrones de
   credenciales (`PWD/Password =`, keys `sk-...`, la contraseña filtrada
   conocida) ni el skeleton pasa contraseñas por `params`.

**Manual (checklist antes de merge a `main`):**

- [ ] Contraseña de BD y API key de OpenAI **rotadas** (0.1).
- [ ] `devtools::test()` en verde y `R CMD check` sin errores nuevos.
- [ ] Render de humo del skeleton contra una sesión real de prueba
      (`render-report` skill) revisado visualmente.
- [ ] `renv.lock` sincronizado con `DESCRIPTION`.
- [ ] Ningún artefacto de render (`*_cache/`, HTML) agregado al repo.

**Orden sugerido de ejecución del roadmap:**
0 (seguridad, ya en curso) → 7.1–7.3 (base instalable) → 2 (correcciones de
procesamiento, ya en esta rama) → 3.1–3.2 (API robusta) → 5.1 (slides
testeables) → 4 (tema central + accesibilidad) → 6 (render por caso) → 7.4
(CI) → 8 (playbook de caso nuevo).
