#' Resume un conjunto de respuestas de una pregunta vía la API de IA
#'
#' @description
#' Unifica en una sola función el bloque `POST -> content -> fromJSON` que
#' antes se copiaba en cada script del caso (`api_resumidor.R`,
#' `entregable.R`...), con timeout, reintentos con backoff exponencial (vía
#' [httr2::req_retry()]) y errores explícitos si la API responde un status
#' distinto de 200 o el JSON no trae el campo `data` esperado. Cachea el
#' resultado en disco por hash de `(pregunta, respuestas)` para que un
#' re-render no vuelva a pagar el costo del LLM (ver `cache_dir`).
#'
#' @param pregunta (char) Nombre/texto de la pregunta o tema a resumir.
#' @param respuestas (char) Vector de respuestas a resumir.
#' @param url (char) Endpoint de la API de resumen. Default
#'   `getOption("abpvirtual.api_url")`.
#' @param cache_dir (char o NULL) Directorio donde cachear resúmenes como
#'   `.rds` nombrados por hash de `(pregunta, respuestas)`. `NULL` desactiva
#'   el cache. Default `getOption("abpvirtual.cache_dir")` (por defecto,
#'   `tools::R_user_dir("abpvirtualr", "cache")`).
#' @param timeout (numeric) Segundos antes de abortar la petición.
#' @param reintentos (int) Número de reintentos ante error transitorio
#'   (5xx o de red), con backoff exponencial.
#'
#' @return (char) El resumen (`$data` de la respuesta de la API). `NA_character_`
#'   si `respuestas` está vacío (contrato "sin datos", ver Roadmap 2.5).
#' @export
#'
#' @examples #notrun (resumir_respuestas("¿Qué mejorarías?", c("más médicos", "mejor equipo")))
resumir_respuestas <- function(
    pregunta,
    respuestas,
    url = getOption(
        "abpvirtual.api_url",
        "https://abp-flask-api.azurewebsites.net/api/v1/resumen_pregunta"
    ),
    cache_dir = getOption(
        "abpvirtual.cache_dir",
        tools::R_user_dir("abpvirtualr", "cache")
    ),
    timeout = 30,
    reintentos = 2
) {
    stopifnot(is.character(pregunta), length(pregunta) == 1)

    if (length(respuestas) == 0) {
        return(NA_character_)
    }

    usar_cache <- !is.null(cache_dir)
    cache_file <- NULL
    if (usar_cache) {
        if (!dir.exists(cache_dir)) {
            dir.create(cache_dir, recursive = TRUE)
        }
        hash <- digest::digest(list(pregunta = pregunta, respuestas = respuestas))
        cache_file <- file.path(cache_dir, paste0(hash, ".rds"))
        if (file.exists(cache_file)) {
            return(readRDS(cache_file))
        }
    }

    resumen <- resumir_respuestas_llamar_api(pregunta, respuestas, url, timeout, reintentos)

    if (usar_cache) {
        saveRDS(resumen, cache_file)
    }

    resumen
}

#' @keywords internal
resumir_respuestas_llamar_api <- function(pregunta, respuestas, url, timeout, reintentos) {
    resp <- httr2::request(url) |>
        httr2::req_body_json(list(pregunta = pregunta, respuestas = respuestas)) |>
        httr2::req_timeout(timeout) |>
        httr2::req_retry(max_tries = reintentos + 1) |>
        httr2::req_error(is_error = function(resp) FALSE) |>
        httr2::req_perform()

    status <- httr2::resp_status(resp)
    if (status != 200) {
        stop(glue::glue(
            "resumir_respuestas(): la API respondio status {status} ",
            "para la pregunta '{pregunta}'."
        ), call. = FALSE)
    }

    body <- httr2::resp_body_json(resp)
    if (is.null(body$data)) {
        stop(glue::glue(
            "resumir_respuestas(): la respuesta de la API no trae el campo ",
            "'data' esperado para la pregunta '{pregunta}'."
        ), call. = FALSE)
    }

    body$data
}
