#' Colecta todas las tablas necesarias para su posterior análisis
#'
#' @param id_sesion (int) La sesión necesaria para el evento. En caso de no
#' proveerla toma la última, y si se inserta "Todo" entrega todos los eventos
#'
#' @return (list) Una lista de tibbles con las tablas necesarias para las preguntas
#' @export
#' @import dplyr
#' @importFrom dbplyr in_schema
#'
#' @examples #notrun (leer_base(con, id_sesion = "Todo"))

leer_base <- function(id_sesion = NULL){
    conexion <- list(Driver = "ODBC Driver 17 for SQL Server",
                     Server = "database.negox.com",
                     Database = "CIDFares2020_ABPVirtualTest",
                     UID = "CIDFares2020_CIDFares2020",
                     PWD = "CIDFares@BP2021",
                     Port = 1433)
    con <- pool::dbPool(odbc::odbc(),
                        Driver = conexion$Driver,
                        Server = conexion$Server,
                        Database = conexion$Database,
                        UID = conexion$UID,
                        PWD = conexion$PWD,
                        Port = conexion$Port)

    id_sesion <- if(is.null(id_sesion)) tbl(con,
                                            in_schema("General","Sesion")) %>%
        summarise(max(IdSesion)) %>%
        pull(1) else id_sesion

    id_sesion <- if(id_sesion == "Todo") tbl(con,
                                             in_schema("General","Sesion")) %>%
        pull(IdSesion) else id_sesion

    etapa <- tbl(con,in_schema("Catalogo", "Etapa")) %>%
        collect()

    pregunta <- tbl(con,in_schema("Cuestionario", "Pregunta")) %>%
        collect()

    respuesta <- tbl(con,in_schema("Cuestionario", "Respuesta")) %>%
        filter(IdSesion %in% !! id_sesion) %>%
        collect()

    categoria <- tbl(con,in_schema("Catalogo", "Categoria")) %>%
        collect()

    respuesta_cat <- tbl(con,
                         in_schema("Cuestionario", "RespuestaCategoria")) %>%
        filter(IdSesion %in% !! id_sesion) %>%
        collect()

    orden_cat <- tbl(con,
                     in_schema("Cuestionario", "OrdenCategoria")) %>%
        filter(IdSesion %in% !! id_sesion) %>%
        collect()

    calif_cat <- tbl(con,
                     in_schema("Cuestionario", "CalificacionCategoria")) %>%
        filter(IdSesion %in% !! id_sesion) %>%
        collect()

    pool::poolClose(con)

    res <- list(
        etapa = etapa,
        pregunta = pregunta,
        respuesta = respuesta,
        categoria = categoria,
        respuesta_cat = respuesta_cat,
        orden_cat = orden_cat,
        calif_cat = calif_cat
    )

    return(res)
}
