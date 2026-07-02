#' Construye la lista `parametros` de estilo con valores por defecto
#'
#' @description
#' Devuelve la lista `parametros` que consumen las funciones `graficar_*`,
#' `imprimir_*` y `slides_*`, con todos sus campos poblados a partir de un
#' conjunto de defaults documentado. Para un caso nuevo basta sobreescribir los
#' pocos valores de marca (p. ej. `primario`, `familia`) en lugar de rearmar los
#' 15 campos a mano en cada `.Rmd`. El resultado se valida con
#' [validar_parametros()] antes de regresarse.
#'
#' @param primario (char) Color primario de marca (hex, ej. "#2A3D6E").
#' @param primario_claro (char) Variante clara del primario.
#' @param primario_obscuro (char) Variante obscura del primario.
#' @param inverso (char) Color complementario/inverso.
#' @param inverso_claro (char) Variante clara del inverso.
#' @param sm_vf (char) Semáforo brecha: verde fuerte.
#' @param sm_vc (char) Semáforo brecha: verde claro.
#' @param sm_a (char) Semáforo brecha: amarillo.
#' @param sm_rc (char) Semáforo brecha: rojo claro.
#' @param sm_rf (char) Semáforo brecha: rojo fuerte.
#' @param cortes (numeric) 6 puntos de corte del semáforo (creciente, de 0 a
#'   ~10000). Ver README para la decisión metodológica.
#' @param familia (char) Familia tipográfica (Google Fonts).
#' @param gris (char) Gris para texto/ejes.
#' @param gris_claro (char) Gris claro para líneas de ejes.
#' @param etiquetas (char) Tamaño de fuente de ejes en px, ej. "14px".
#'
#' @return (list) Lista `parametros` validada, lista para pasar a las funciones
#'   de graficado/impresión.
#' @export
#'
#' @examples
#' # Defaults completos:
#' p <- parametros_default()
#' # Solo rebrandear el color primario y la tipografía del caso nuevo:
#' p <- parametros_default(primario = "#7A1E3B", familia = "Merriweather")

parametros_default <- function(
    primario = "#2A3D6E",
    primario_claro = "#304E83",
    primario_obscuro = "#232B58",
    inverso = "#4C97C8",
    inverso_claro = "#88B9CF",
    sm_vf = "#6A994E",
    sm_vc = "#A7C957",
    sm_a = "#F9C74F",
    sm_rc = "#D65A1F",
    sm_rf = "#B31D1F",
    cortes = seq(0, 10000, length.out = 6),
    familia = "Poppins",
    gris = "#343a40",
    gris_claro = "#ced4da",
    etiquetas = "14px"
) {
    parametros <- list(
        primario = primario,
        primario_claro = primario_claro,
        primario_obscuro = primario_obscuro,
        inverso = inverso,
        inverso_claro = inverso_claro,
        sm_vf = sm_vf,
        sm_vc = sm_vc,
        sm_a = sm_a,
        sm_rc = sm_rc,
        sm_rf = sm_rf,
        cortes = cortes,
        familia = familia,
        gris = gris,
        gris_claro = gris_claro,
        etiquetas = etiquetas
    )

    validar_parametros(parametros)
    parametros
}


#' Valida la estructura de una lista `parametros`
#'
#' @description
#' Verifica que una lista `parametros` tenga todos los campos requeridos, que
#' los colores sean hex válidos, que `cortes` tenga 6 valores crecientes y que
#' `etiquetas` esté en formato "<n>px". Falla con un mensaje explícito en el
#' primer problema encontrado, en lugar de dejar que el error aparezca a la
#' mitad del knit. Es invocada por [parametros_default()] pero también sirve
#' para validar una lista armada a mano.
#'
#' @param parametros (list) Lista de parámetros de estilo a validar.
#'
#' @return (invisible list) La misma lista `parametros`, invisible, si es
#'   válida. En caso contrario aborta con `stop()`.
#' @export
#'
#' @examples #notrun (validar_parametros(parametros_default()))

validar_parametros <- function(parametros) {
    requeridos <- c(
        "primario", "primario_claro", "primario_obscuro",
        "inverso", "inverso_claro",
        "sm_vf", "sm_vc", "sm_a", "sm_rc", "sm_rf",
        "cortes", "familia", "gris", "gris_claro", "etiquetas"
    )

    faltan <- setdiff(requeridos, names(parametros))
    if (length(faltan)) {
        stop(glue::glue(
            "Faltan campos en parametros: {paste(faltan, collapse = ', ')}."
        ))
    }

    colores <- setdiff(requeridos, c("cortes", "familia", "etiquetas"))
    hex <- unlist(parametros[colores])
    mal_hex <- colores[!grepl("^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$", hex)]
    if (length(mal_hex)) {
        stop(glue::glue(
            "Colores hex invalidos en parametros: {paste(mal_hex, collapse = ', ')}."
        ))
    }

    cortes <- parametros$cortes
    if (!is.numeric(cortes) || length(cortes) != 6) {
        stop("parametros$cortes debe ser numerico de longitud 6.")
    }
    if (is.unsorted(cortes, strictly = TRUE)) {
        stop("parametros$cortes debe estar en orden estrictamente creciente.")
    }

    if (!grepl("^[0-9]+px$", parametros$etiquetas)) {
        stop("parametros$etiquetas debe tener formato '<n>px', ej. '14px'.")
    }

    invisible(parametros)
}
