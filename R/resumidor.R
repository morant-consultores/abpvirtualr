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
        json_data <- list(
            pregunta = pregunta,
            respuestas = respuestas
        )

        json_body <- jsonlite::toJSON(json_data, auto_unbox = TRUE)

        response <- POST(
            url = url,
            body = json_body,
            content_type_json()
        )

        json_content <- httr::content(response, "text", encoding = "UTF-8")

        json_data <- jsonlite::fromJSON(json_content)

        resumen <- tibble("Resumen" = json_data$data) |>
            gt::gt() |>
            gt::fmt_markdown()

    return(resumen)
}

