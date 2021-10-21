#' Colecta todas las tablas necesarias para su posterior análisis
#'
#' @param pool (pool::dbPool) Configuración de conexión remota a la base de datos.
#' @param id_sesion (int) La sesión necesaria para el evento. En caso de no
#' proveerla toma la última, y si se inserta "Todo" entrega todos los eventos
#'
#' @return (list) Una lista de tibbles con las tablas necesarias para las preguntas
#' @export
#' @import dplyr
#' @importFrom dbplyr in_schema
#'
#' @examples #notrun (leer_base(pool, id_sesion = "Todo"))

leer_base <- function(pool, id_sesion = NULL){

id_sesion <- if(is.null(id_sesion)) tbl(pool,
        in_schema("General","Sesion")) %>%
        summarise(max(id_sesion)) %>%
        pull(1) else id_sesion

id_sesion <- if(id_sesion == "Todo") tbl(pool,
        in_schema("General","Sesion")) %>%
        pull(IdSesion) else id_sesion

    etapa <- tbl(pool,in_schema("Catalogo", "Etapa")) %>%
        collect()

    pregunta <- tbl(pool,in_schema("Cuestionario", "Pregunta")) %>%
        collect()

    respuesta <- tbl(pool,in_schema("Cuestionario", "Respuesta")) %>%
        filter(IdSesion %in% !! id_sesion) %>%
        collect()

    categoria <- tbl(pool,in_schema("Catalogo", "Categoria")) %>%
        collect()

    respuesta_cat <- tbl(pool,
        in_schema("Cuestionario", "RespuestaCategoria")) %>%
        filter(IdSesion %in% !! id_sesion) %>%
        collect()

    orden_cat <- tbl(pool,
        in_schema("Cuestionario", "OrdenCategoria")) %>%
        filter(IdSesion %in% !! id_sesion) %>%
        collect() %>%
        mutate(Orden = Orden*10)

    calif_cat <- tbl(pool,
        in_schema("Cuestionario", "CalificacionCategoria")) %>%
        filter(IdSesion %in% !! id_sesion) %>%
        collect()

    res <- list(
        etapa = etapa,
        pregunta = pregunta,
        respuesta = respuesta,
        categoria = categoria,
        respuesta_cat = respuesta_cat,
        orden_cat = orden_cat,
        calif_cat = calif_cat
    )
    pool::poolClose()
    return(res)
}
