#' Función que genera un resumen de las preguntas seleccionadas
#'
#' Usa httr2 con timeout y reintentos con backoff ante error transitorio, y
#' cachea el resultado en disco por hash de (pregunta, respuestas, url) para
#' que un re-render no vuelva a pagar el costo del LLM.
#'
#' @param pregunta (char o NULL) Pregunta/tema a resumir; NULL para un resumen
#'   general de `respuestas` sin pregunta asociada.
#' @param respuestas (char) Vector de respuestas a resumir.
#' @param url (string) Url de la api del resumidor.
#' @param cache_dir (char o NULL) Directorio para cachear resúmenes como
#'   `.rds` nombrados por hash. `NULL` desactiva el cache. Default
#'   `tools::R_user_dir("abpvirtualr", "cache")`.
#' @param timeout (numeric) Segundos antes de abortar la petición.
#' @param reintentos (int) Reintentos ante error transitorio (5xx o de red).
#' @return (tibble) Una columna "Resumen" con el texto generado por la API.
#' @export
generar_resumen <- function(pregunta, respuestas, url,
                             cache_dir = getOption(
                                 "abpvirtual.cache_dir",
                                 tools::R_user_dir("abpvirtualr", "cache")
                             ),
                             timeout = 30, reintentos = 2){
    if (length(respuestas) == 0) {
        return(tibble::tibble("Resumen" = NA_character_))
    }

    usar_cache <- !is.null(cache_dir)
    cache_file <- NULL
    if (usar_cache) {
        if (!dir.exists(cache_dir)) dir.create(cache_dir, recursive = TRUE)
        hash <- digest::digest(list(pregunta = pregunta, respuestas = respuestas, url = url))
        cache_file <- file.path(cache_dir, paste0(hash, ".rds"))
        if (file.exists(cache_file)) return(readRDS(cache_file))
    }

    json_data <- if (is.null(pregunta)) {
        list(textos = respuestas)
    } else {
        list(pregunta = pregunta, respuestas = respuestas)
    }

    resp <- httr2::request(url) |>
        httr2::req_body_json(json_data) |>
        httr2::req_timeout(timeout) |>
        httr2::req_retry(max_tries = reintentos + 1) |>
        httr2::req_error(is_error = function(resp) FALSE) |>
        httr2::req_perform()

    status <- httr2::resp_status(resp)
    if (status != 200) {
        stop(glue::glue("generar_resumen(): la API respondio status {status}."), call. = FALSE)
    }

    body <- httr2::resp_body_json(resp)
    if (is.null(body$data)) {
        stop("generar_resumen(): la respuesta de la API no trae el campo 'data' esperado.", call. = FALSE)
    }

    resumen <- tibble::tibble("Resumen" = body$data)

    if (usar_cache) saveRDS(resumen, cache_file)

    resumen
}


#' Separa el bloque de resumen en categoría + texto
#'
#' `generar_resumen()` devuelve un solo string con secciones
#' `"**Categoria**\ntexto"` unidas por `"\n\n&nbsp;\n\n"`. Esta función las
#' separa en una tibble para poder renderizar una lámina por categoría (p.ej.
#' en un reporte revealjs) en vez de una sola tabla larga y con scroll.
#'
#' @param resumen (char) El string `Resumen` devuelto por `generar_resumen()`.
#' @return (tibble) Columnas `categoria` y `texto`, una fila por categoría.
#'   Si una sección no trae el formato `"**Categoria**"`, `categoria` queda
#'   `NA` y `texto` conserva la sección completa. Tibble vacía si `resumen`
#'   es `NA`/`NULL`/vacío.
#' @export
separar_categorias <- function(resumen) {
    if (is.null(resumen) || length(resumen) == 0 || is.na(resumen) || !nzchar(trimws(resumen))) {
        return(tibble::tibble(categoria = character(), texto = character()))
    }

    secciones <- strsplit(resumen, "\n\n&nbsp;\n\n", fixed = TRUE)[[1]]
    secciones <- trimws(secciones)
    secciones <- secciones[nzchar(secciones)]

    m <- regmatches(secciones, regexec("(?s)^\\*\\*(.+?)\\*\\*\\s*\\n?(.*)$", secciones, perl = TRUE))

    categoria <- vapply(m, function(x) if (length(x) >= 2) trimws(x[2]) else NA_character_, character(1))
    texto <- vapply(m, function(x) if (length(x) >= 3) trimws(x[3]) else NA_character_, character(1))

    sin_match <- is.na(categoria)
    texto[sin_match] <- secciones[sin_match]

    tibble::tibble(categoria = categoria, texto = texto)
}


#' Formato personalizado de tablas utilizando gt y DT
#'
#' Esta función aplica un formato personalizado a una tabla, utilizando los paquetes **gt** o **DT** dependiendo del valor del parámetro `general`. Si `general = "F"`, se utiliza **gt** para generar una tabla estática con estilo. Si `general = "T"`, se utiliza **DT** para generar una tabla interactiva y editable que soporta Markdown.
#'
#' @param bd Un data frame que representa la tabla a formatear.
#' @param general Caracter que indica el tipo de formato a aplicar:
#'   - `"F"`: Utiliza el paquete **gt** para formatear la tabla (por defecto).
#'   - `"T"`: Utiliza el paquete **DT** para crear una tabla interactiva y editable.
#'
#' @return
#' Dependiendo del valor de `general`, devuelve un objeto de clase **gt** o **datatables** con el formato aplicado.
#'
#' @details
#' - Convierte el data frame `bd` en una tabla **gt**.
#' - Aplica formato Markdown a las celdas utilizando `fmt_markdown()`.
#' - Alinea la primera columna a la izquierda con `cols_align()`.
#' - Oculta los encabezados de columna usando `tab_options(column_labels.hidden = TRUE)`.
#' - Aplica el tema `gt_theme_nytimes()` del paquete **gtExtras**.
#' - Ajusta opciones de tabla como el tamaño de fuente, estilos de borde y color de fondo con `tab_options()`.
#' - Establece las fuentes de la tabla a 'Roboto', 'Cochin' y 'serif' usando `opt_table_font()`.
#'
#' @importFrom gt gt fmt_markdown cols_align tab_options opt_table_font
#' @importFrom gtExtras gt_theme_nytimes
#' @export
#'
#' @examples
#' \dontrun{
#' # Data frame de ejemplo
#' df <- data.frame(
#'   Columna1 = c("**Texto en negrita**", "*Texto en cursiva*"),
#'   Columna2 = c("Valor1", "Valor2")
#' )
#'
#' # Utilizando gt
#' formato_tabla(df)
#' }

formato_tabla <- function(bd){
    bd |>
        gt::gt() |>
        gt::fmt_markdown() |>
        gt::cols_align(align = 'left', columns = 1) |>
        gt::tab_options(column_labels.hidden = TRUE) |>
        gtExtras::gt_theme_nytimes() |>
        tab_options(
            table.font.size = px(26),
            table.border.top.style = 'hidden',
            table.border.bottom.style = 'hidden',
            table.background.color = 'transparent',
            container.overflow.y = FALSE,
            container.overflow.x = FALSE
        ) |>
        gt::opt_table_font(
            font = list(
                google_font(name = 'Roboto'),
                'Roboto', 'serif'
            )
        ) |>
        gt::tab_style(
            style = list(
                gt::cell_text(font = "Roboto")
            ),
            locations = gt::cells_body()
        ) |>
        tab_style(
            style = list(
                cell_text(color = "black")
            ),
            locations = cells_body()
        ) |>
        as_raw_html()
}

