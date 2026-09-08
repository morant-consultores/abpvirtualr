#' Publica un directorio a un sitio de Netlify existente
#'
#' Zipea `dir` y lo sube como un nuevo deploy de producción vía la API de
#' Netlify (`POST /sites/{site_id}/deploys`). Cada deploy reemplaza el
#' contenido completo del sitio con lo que traiga el zip -- por eso `dir`
#' debe contener el árbol completo que se quiere servir (todos los reportes
#' ya publicados más el nuevo), no solo los archivos de esta corrida.
#'
#' @param dir (char) Carpeta local con el sitio completo a publicar (debe
#'   incluir un `index.html`).
#' @param site_id (char) Site ID (también llamado Project ID en el
#'   dashboard de Netlify) del sitio de destino.
#' @param token (char) Personal access token de Netlify.
#' @param timeout (numeric) Segundos antes de abortar la petición.
#'
#' @return (list, invisible) La respuesta de la API de Netlify, con el campo
#'   `$deploy_ssl_url` del sitio ya publicado.
#' @export
#'
#' @examples #notrun (publicar_netlify("site", Sys.getenv("NETLIFY_SITE_ID"), Sys.getenv("NETLIFY_AUTH_TOKEN")))
publicar_netlify <- function(dir, site_id, token, timeout = 60){
    if (!dir.exists(dir)) {
        stop("publicar_netlify(): '", dir, "' no existe.", call. = FALSE)
    }
    if (!file.exists(file.path(dir, "index.html"))) {
        stop("publicar_netlify(): '", dir, "' no tiene un index.html.", call. = FALSE)
    }

    zip_file <- tempfile(fileext = ".zip")
    on.exit(unlink(zip_file), add = TRUE)

    archivos <- list.files(dir, recursive = TRUE)
    zip::zip(zip_file, archivos, root = dir)

    resp <- httr2::request(glue::glue("https://api.netlify.com/api/v1/sites/{site_id}/deploys")) |>
        httr2::req_auth_bearer_token(token) |>
        httr2::req_headers("Content-Type" = "application/zip") |>
        httr2::req_body_file(zip_file) |>
        httr2::req_timeout(timeout) |>
        httr2::req_error(is_error = function(resp) FALSE) |>
        httr2::req_perform()

    status <- httr2::resp_status(resp)
    body <- httr2::resp_body_json(resp)

    if (status >= 300) {
        mensaje <- if (is.null(body$message)) "" else body$message
        stop(glue::glue(
            "publicar_netlify(): Netlify respondio status {status}: {mensaje}"
        ), call. = FALSE)
    }

    invisible(body)
}
