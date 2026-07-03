#' Genera un sufijo único para nombrar chunks de knitr dinámicamente
#'
#' @description
#' Los `imprimir_*` con label fijo (ej. `"etapa_3-4"`) chocan si la etapa que
#' arman se repite dentro del mismo deck (dos sesiones, dos categorías...):
#' knitr no permite labels de chunk duplicados dentro de un mismo render.
#' `chunk_label_unico()` da un sufijo alfanumérico único por invocación para
#' namespacear esos labels sin cambiar su forma legible.
#'
#' @return (char) Sufijo alfanumérico único.
#' @keywords internal
chunk_label_unico <- function() {
    basename(tempfile(pattern = ""))
}

#' Formatea una fecha en español sin depender del locale del sistema
#'
#' @description
#' El skeleton xaringan formateaba la fecha con
#' `Sys.setlocale(locale = "es_ES.UTF-8"); format(fecha, "%d de %B de %Y")`:
#' en una máquina sin ese locale instalado (común en Windows/Linux fuera de
#' es_ES), `Sys.setlocale()` falla con un warning pero **no** detiene el
#' render — el resultado es una fecha en inglés ("July") sin ningún aviso
#' visible en el slide. `fecha_es()` evita el problema de raíz: no depende
#' del locale del sistema, mapea el mes a mano.
#'
#' @param fecha (Date) Fecha a formatear. Default `Sys.Date()`.
#'
#' @return (char) Fecha en formato `"<día> de <mes> de <año>"`, en español.
#' @export
#' @examples fecha_es(as.Date("2026-07-03"))
fecha_es <- function(fecha = Sys.Date()) {
    meses <- c(
        "enero", "febrero", "marzo", "abril", "mayo", "junio",
        "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"
    )
    sprintf(
        "%d de %s de %d",
        as.integer(format(fecha, "%d")),
        meses[as.integer(format(fecha, "%m"))],
        as.integer(format(fecha, "%Y"))
    )
}

#' Obtiene el catálogo de palabras altisonantes empaquetado
#'
#' @description
#' Regresa el dataset `altisonantes` incluido en el paquete sin depender del
#' working directory. Sustituye a los `load("data/altisonantes.rda")` con ruta
#' relativa que solo funcionaban al knitear desde la raíz del repo.
#'
#' @return (tibble) Una columna `palabra` con las palabras a filtrar.
#' @keywords internal

obtener_altisonantes <- function() {
    env <- new.env(parent = emptyenv())
    utils::data("altisonantes", package = "abpvirtualr", envir = env)
    env$altisonantes
}
