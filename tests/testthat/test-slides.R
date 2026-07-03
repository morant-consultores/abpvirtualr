mock_resumen_ok <- function() {
    function(req) {
        body <- charToRaw(jsonlite::toJSON(list(data = "resumen de prueba"), auto_unbox = TRUE))
        httr2::response(
            status_code = 200,
            headers = list(`Content-Type` = "application/json"),
            body = body
        )
    }
}

test_that("imprimir_gt() arma el chunk con el resumen de la API (regresion: la funcion no existia)", {
    # slides_nubes()/slides_etapa_2() llamaban a imprimir_gt(), borrada del
    # paquete sin actualizar a sus llamadores: cualquier render con resumen
    # de IA fallaba con 'could not find function "imprimir_gt"'.
    testthat::local_mocked_bindings(
        req_perform = mock_resumen_ok(),
        .package = "httr2"
    )

    char <- imprimir_gt(c("mas medicinas", "mas medicos"), "Salud", 1, "http://fake")

    expect_true(grepl("# Salud", char, fixed = TRUE))
    expect_true(grepl("resumen de prueba", char, fixed = TRUE))
})

test_that("slides_nubes() arma las slides de una etapa sin tronar (regresion imprimir_gt)", {
    testthat::local_mocked_bindings(
        req_perform = mock_resumen_ok(),
        .package = "httr2"
    )
    p <- parametros_default()
    thm <- tema_high(p$familia, p$gris, p$etiquetas)
    bd <- bd_sintetica()

    res <- slides_nubes(bd, etapa = 1, parametros = p, thm = thm, url = "http://fake")
    expect_true(nchar(paste(res, collapse = "")) > 0)
})
