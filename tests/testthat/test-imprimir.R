# Los imprimir_* generan chunks de xaringan como texto: se valida que el
# string tenga fences balanceados, el título y la llamada correcta indexada.

test_that("imprimir_nube() arma un chunk bien formado con el indice", {
    p <- parametros_default()
    df <- tibble::tibble(Pregunta = "¿Qué mejorarías?")

    chunk <- imprimir_nube(df, i = 3, parametros = p)

    expect_type(chunk, "character")
    expect_match(chunk, "# ¿Qué mejorarías?", fixed = TRUE)
    expect_match(chunk, "graficar_nube(p_3, parametros = parametros)", fixed = TRUE)
    # Fence de apertura y de cierre.
    expect_gte(lengths(regmatches(chunk, gregexpr("```", chunk))), 2)
})

test_that("imprimir_tabla_nube() referencia la tabla de la pregunta indexada", {
    df <- tibble::tibble(
        Pregunta = "¿Qué mejorarías?",
        Respuesta = "más medicinas"
    )

    chunk <- imprimir_tabla_nube(df, i = 2)

    expect_match(chunk, "generar_tabla_nube(q_2)", fixed = TRUE)
    expect_match(chunk, "# ¿Qué mejorarías?", fixed = TRUE)
})
