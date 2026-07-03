# Datos sintéticos que replican el contrato de leer_base() (ver README,
# "Modelo de datos"). Ningún test toca la base real: todo corre offline.
#
# Valores elegidos para que la aritmética sea exacta:
#   Salud:     Orden (80, 60), Calificacion (20, 40)
#              -> brecha por usuario 6400 y 3600, promedio 5000 (banda amarilla)
#              -> importancia 70, cumplimiento 30
#   Educación: Orden (10, 30), Calificacion (90, 90)
#              -> brecha por usuario 100 y 300, promedio 200 (banda verde fuerte)
#              -> importancia 20, cumplimiento 90

bd_sintetica <- function(con_na = FALSE) {
    categoria <- tibble::tibble(
        IdCategoria = c(1L, 2L),
        Nombre = c("Salud", "Educación"),
        EsDefault = c(TRUE, TRUE)
    )

    orden_cat <- tibble::tibble(
        IdSesion = 1L,
        IdUsuario = c(1L, 2L, 1L, 2L),
        IdCategoria = c(1L, 1L, 2L, 2L),
        Orden = c(80, 60, 10, 30)
    )

    calif_cat <- tibble::tibble(
        IdSesion = 1L,
        IdUsuario = c(1L, 2L, 1L, 2L),
        IdCategoria = c(1L, 1L, 2L, 2L),
        Calificacion = c(20, 40, 90, 90)
    )

    if (con_na) {
        # Usuario 3 ordena Salud pero nunca la califica: el par queda
        # incompleto y na.omit() debe descartarlo sin alterar los promedios.
        orden_cat <- dplyr::bind_rows(
            orden_cat,
            tibble::tibble(IdSesion = 1L, IdUsuario = 3L,
                           IdCategoria = 1L, Orden = 50)
        )
    }

    pregunta <- tibble::tibble(
        IdPregunta = c(1L, 2L),
        IdEtapa = c(1L, 2L),
        Nombre = c("¿Qué mejorarías de tu institución?",
                   "¿Cuál es la brecha principal?"),
        RegistroActivo = TRUE,
        Orden = 1L
    )

    respuesta <- tibble::tibble(
        IdRespuesta = 1:4,
        IdSesion = 1L,
        IdPregunta = 1L,
        IdEtapa = 1L,
        Respuesta = c(
            "el hospital necesita más medicinas",
            "faltan medicinas en el hospital",
            "hospital lento desde 2024",
            "todo es asqueroso aquí"  # "asqueroso" está en data/altisonantes.rda
        )
    )

    respuesta_cat <- tibble::tibble(
        IdRespuesta = 1:4,
        IdSesion = 1L,
        IdCategoria = c(1L, 1L, 2L, 2L)
    )

    etapa <- tibble::tibble(
        IdEtapa = c(1L, 2L),
        Nombre = c("Inicio", "Brecha")
    )

    list(
        etapa = etapa,
        pregunta = pregunta,
        respuesta = respuesta,
        categoria = categoria,
        respuesta_cat = respuesta_cat,
        orden_cat = orden_cat,
        calif_cat = calif_cat
    )
}
