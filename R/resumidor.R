#' Función que genera un resumen de las preguntas seleccionadas
#'
#' @param bd (list) Lista de tablas provistas por leer_base.
#' @param etapa (int) Número de la etapa en la base de datos.
#' @param url (string) Url de la api del resumidor
#' @return (gt) Tabla tipo gt con formato de markdown
#' @export
#'
#' @import httr
#'
generar_resumen <- function(pregunta, respuestas, url){
    if(is.null(pregunta)){
        json_data <- list(
            textos = respuestas
        )
    } else {
        json_data <- list(
            pregunta = pregunta,
            respuestas = respuestas
        )
    }

    json_body <- jsonlite::toJSON(json_data, auto_unbox = TRUE)

    response <- POST(
        url = url,
        body = json_body,
        content_type_json()
    )

    json_content <- httr::content(response, "text", encoding = "UTF-8")

    json_data <- jsonlite::fromJSON(json_content)

    resumen <- tibble("Resumen" = json_data$data)

    return(resumen)
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
#' ### Cuando `general = "F"`:
#'
#' - Convierte el data frame `bd` en una tabla **gt**.
#' - Aplica formato Markdown a las celdas utilizando `fmt_markdown()`.
#' - Alinea la primera columna a la izquierda con `cols_align()`.
#' - Oculta los encabezados de columna usando `tab_options(column_labels.hidden = TRUE)`.
#' - Aplica el tema `gt_theme_nytimes()` del paquete **gtExtras**.
#' - Ajusta opciones de tabla como el tamaño de fuente, estilos de borde y color de fondo con `tab_options()`.
#' - Establece las fuentes de la tabla a 'Roboto', 'Cochin' y 'serif' usando `opt_table_font()`.
#'
#' ### Cuando `general = "T"`:
#'
#' - Define estilos CSS personalizados para la tabla, incluyendo tamaño de fuente, alineación y ocultación de encabezados.
#' - Utiliza `datatable()` del paquete **DT** para crear una tabla interactiva y editable.
#' - Configura la tabla para ser editable por celda (`editable = "cell"`).
#' - Desactiva paginación, ordenamiento y búsqueda, y oculta los controles de tabla.
#' - Aplica una función JavaScript mediante `columnDefs` para renderizar contenido Markdown en las celdas usando **marked.js**.
#' - Incluye la biblioteca **marked.js** y el CSS personalizado en el encabezado HTML usando `htmlwidgets::prependContent()`.
#'
#' @importFrom gt gt fmt_markdown cols_align tab_options opt_table_font
#' @importFrom gtExtras gt_theme_nytimes
#' @importFrom DT datatable
#' @importFrom htmlwidgets prependContent
#' @importFrom htmltools tags HTML
#' @importFrom V8 JS
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
#' # Utilizando gt (general = "F")
#' formato_tabla(df, general = "F")
#'
#' # Utilizando DT (general = "T")
#' formato_tabla(df, general = "T")
#' }

formato_tabla <- function(bd){
    bd |>
        gt::gt() |>
        gt::fmt_markdown() |>
        gt::cols_align(align = 'left', columns = 1) |>
        gt::tab_options(column_labels.hidden = TRUE) |>
        gtExtras::gt_theme_nytimes() |>
        tab_options(
            table.font.size = px(22),
            table.border.top.style = 'hidden',
            table.border.bottom.style = 'hidden',
            table.background.color = 'transparent',
            container.overflow.y = FALSE,
            container.overflow.x = FALSE
        ) |>
        opt_table_font(
            font = list(
                google_font(name = 'Roboto'),
                'Cochin', 'serif'
            )
        )
}

