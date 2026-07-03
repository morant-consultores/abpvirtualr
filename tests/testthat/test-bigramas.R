bd_bigramas <- function() {
    list(
        pregunta = tibble::tibble(
            IdPregunta = 1L, IdEtapa = 1L, Nombre = "Q",
            RegistroActivo = TRUE, Orden = 1L
        ),
        respuesta = tibble::tibble(
            IdRespuesta = 1:4,
            IdSesion = 1L,
            IdPregunta = 1L,
            IdEtapa = 1L,
            Respuesta = c(
                "perro grande corre",
                "perro grande corre",
                "perro grande camina",
                "gato pequeno duerme"
            )
        )
    )
}

test_that("procesar_bigramas() permite parametrizar el percentil de corte", {
    p <- parametros_default()
    bd <- bd_bigramas()

    amplio <- suppressMessages(
        procesar_bigramas(bd, 1, 1, p, quitar_altisonantes = FALSE, p = 0)
    )
    estrecho <- suppressMessages(
        procesar_bigramas(bd, 1, 1, p, quitar_altisonantes = FALSE, p = .8)
    )

    expect_equal(nrow(amplio), 2)
    expect_equal(nrow(estrecho), 1)
    expect_equal(estrecho$palabra1, "perro")
    expect_equal(estrecho$palabra2, "grande")
})
