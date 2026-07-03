test_that("procesar_p_abierta() tokeniza, filtra stopwords y numeros", {
    p <- parametros_default()
    bd <- bd_sintetica()
    res <- suppressMessages(
        procesar_p_abierta(bd, pregunta = 1, etapa = 1, parametros = p)
    )

    expect_length(res, 2)
    tokens <- res[[1]]

    # Stopwords en español fuera ("el", "más", "en", "desde"...).
    expect_false(any(c("el", "en", "desde") %in% tokens$palabra))
    # Tokens que empiezan con número fuera ("2024").
    expect_false(any(grepl("^[0-9]", tokens$palabra)))
    # La pregunta viaja con los tokens.
    expect_equal(unique(tokens$Pregunta), "¿Qué mejorarías de tu institución?")
})

test_that("procesar_p_abierta() colorea por cuantiles de frecuencia", {
    p <- parametros_default()
    bd <- bd_sintetica()
    tokens <- suppressMessages(
        procesar_p_abierta(bd, pregunta = 1, etapa = 1, parametros = p)
    )[[1]]

    # "hospital" aparece en 3 respuestas (max) -> color más obscuro;
    # frecuencia 1 queda en el color inverso (<= cuantil 75).
    expect_equal(
        tokens$colores[tokens$palabra == "hospital"],
        p$primario_obscuro
    )
    expect_equal(
        tokens$colores[tokens$palabra == "lento"],
        p$inverso
    )
})

test_that("procesar_p_abierta() filtra respuestas con altisonantes", {
    p <- parametros_default()
    bd <- bd_sintetica()

    con_filtro <- suppressMessages(
        procesar_p_abierta(bd, 1, 1, p, quitar_altisonantes = TRUE)
    )
    sin_filtro <- suppressMessages(
        procesar_p_abierta(bd, 1, 1, p, quitar_altisonantes = FALSE)
    )

    # "asqueroso" está en el catálogo: la respuesta completa se descarta.
    expect_false("asqueroso" %in% con_filtro[[1]]$palabra)
    expect_false("todo es asqueroso aquí" %in% con_filtro[[2]]$Respuesta)

    # Sin el filtro, la respuesta y el token sobreviven.
    expect_true("asqueroso" %in% sin_filtro[[1]]$palabra)
    expect_true("todo es asqueroso aquí" %in% sin_filtro[[2]]$Respuesta)
})

test_that("procesar_p_abierta() no depende del working directory", {
    # Regresión: load("data/altisonantes.rda") con ruta relativa tronaba
    # cuando el knit no corría desde la raíz del paquete.
    p <- parametros_default()
    bd <- bd_sintetica()

    res <- withr::with_dir(tempdir(), {
        suppressMessages(
            procesar_p_abierta(bd, 1, 1, p, quitar_altisonantes = TRUE)
        )
    })
    expect_false("asqueroso" %in% res[[1]]$palabra)
})
