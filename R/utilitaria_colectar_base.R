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

leer_base <- function(conexion, id_sesion = NULL, proyecto){
    con <- pool::dbPool(odbc::odbc(),
                        Driver = conexion$Driver,
                        Server = conexion$Server,
                        Database = conexion$Database,
                        UID = conexion$UID,
                        PWD = conexion$PWD,
                        Port = conexion$Port)
    on.exit(pool::poolClose(con), add = TRUE)

    id_proyecto <- tbl(con, in_schema("General", "Proyecto")) |>
        filter(Nombre == proyecto) |>
        pull(Id)

    id_sesion <- if(is.null(id_sesion)){
        tbl(con,
            in_schema("General","SesionProgramada")) %>%
            summarise(max(IdSesion)) %>%
            pull(1)
    }
    else {
        id_sesion
    }

    etapa <- tbl(con,in_schema("Catalogo", "Etapa")) %>%
        collect()

    pregunta <- tbl(con, in_schema("Cuestionario", "PreguntaProyecto")) %>%
        filter(IdProyecto == id_proyecto) |>
        collect() |>
        filter(RegistroActivo) |>
        left_join(tbl(con, in_schema("Cuestionario", "PreguntaSesion_v2")) |>
                      filter(IdSesion %in% !!id_sesion) |>
                                collect()
                  )

    respuesta <- tbl(con,in_schema("Cuestionario", "Respuesta")) %>%
        filter(IdSesion %in% !!id_sesion) %>%
        collect()

    categoria <- tbl(con,in_schema("Catalogo", "Categoria")) %>%
        collect()

    respuesta_cat <- tbl(con, in_schema("Cuestionario", "RespuestaCategoria")) %>%
        filter(IdSesion %in% !! id_sesion) %>%
        collect()

    orden_cat <- tbl(con, in_schema("Cuestionario", "OrdenCategoria")) %>%
        filter(IdSesion %in% !! id_sesion) %>%
        collect()

    calif_cat <- tbl(con, in_schema("Cuestionario", "CalificacionCategoria")) %>%
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

    return(res)
}
