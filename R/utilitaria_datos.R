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
