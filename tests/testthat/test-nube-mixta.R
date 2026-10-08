test_that("nube_mixta junta expresiones repetidas con palabras sueltas", {
    resp <- c(rep("falta seguridad vial en la colonia", 3), "necesitamos transporte", "mas transporte publico", "seguridad en la calle")
    bd <- list(
        respuesta = tibble::tibble(IdRespuesta = seq_along(resp), IdPregunta = 1, IdEtapa = 1, Respuesta = resp),
        pregunta = tibble::tibble(IdPregunta = 1, IdEtapa = 1, Nombre = "p")
    )
    par <- list(inverso = "c", primario_claro = "b", primario_obscuro = "a")
    res <- suppressMessages(nube_mixta(bd, 1, 1, par))
    expect_true("seguridad vial" %in% res$palabra)
    expect_false("seguridad" %in% res$palabra)
    expect_true("transporte" %in% res$palabra)
    expect_equal(res$colores[1], "a")
})

test_that("nube_mixta suma una palabra con y sin acento y muestra la acentuada", {
    resp <- c("mejorar la alcaldia", "mejorar la alcald\u00eda", "mejorar la alcaldia", "mas luz")
    bd <- list(
        respuesta = tibble::tibble(IdRespuesta = seq_along(resp), IdPregunta = 1, IdEtapa = 1, Respuesta = resp),
        pregunta = tibble::tibble(IdPregunta = 1, IdEtapa = 1, Nombre = "p")
    )
    par <- list(inverso = "c", primario_claro = "b", primario_obscuro = "a")
    res <- suppressMessages(nube_mixta(bd, 1, 1, par))
    expect_equal(sum(res$palabra %in% c("alcaldia", "alcald\u00eda")), 1)
    expect_true("alcald\u00eda" %in% res$palabra)
})
