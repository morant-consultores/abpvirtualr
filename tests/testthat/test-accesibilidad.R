# Accesibilidad del semáforo (Roadmap 4.4): el color no debe ser la única
# señal, agregamos una etiqueta de texto junto a él.

test_that("etiqueta_semaforo() traduce los codigos cortos conocidos", {
    expect_equal(
        etiqueta_semaforo(c("vf", "vc", "a", "rc", "rf")),
        c("Verde fuerte", "Verde claro", "Amarillo", "Rojo claro", "Rojo fuerte")
    )
})

test_that("etiqueta_semaforo() regresa el codigo tal cual si no lo reconoce", {
    expect_equal(etiqueta_semaforo("otro"), "otro")
})

test_that("generar_tabla() incluye una columna de texto con el nivel del semaforo", {
    p <- parametros_default()
    bd <- bd_sintetica()
    brecha <- suppressMessages(calcular_brecha(bd, corte, p))

    html <- as.character(generar_tabla(brecha, p))

    expect_true(any(grepl("Amarillo", html)))
    expect_true(any(grepl("Verde fuerte", html)))
})

test_that("generar_tabla() no truena sin datos (contrato sin-datos, Roadmap 2.5/4.6)", {
    p <- parametros_default()
    bd <- bd_sintetica()
    bd$orden_cat <- bd$orden_cat[0, ]
    bd$calif_cat <- bd$calif_cat[0, ]
    brecha <- suppressMessages(calcular_brecha(bd, corte, p))

    tabla <- generar_tabla(brecha, p)
    expect_s3_class(tabla, "kableExtra")
})

test_that("graficar_juntos() documenta si esta simulando o no en el caption", {
    # theme_xaringan() necesita un CSS de un render real; se mockea para
    # poder construir el objeto ggplot en la prueba unitaria.
    testthat::local_mocked_bindings(
        theme_xaringan = function(...) ggplot2::theme_minimal(),
        .package = "xaringanthemer"
    )
    p <- parametros_default()
    bd <- bd_sintetica()
    juntos <- suppressMessages(procesar_juntos(bd))

    con_sim <- suppressWarnings(graficar_juntos(juntos, p))
    sin_sim <- suppressWarnings(graficar_juntos(juntos, p, simular = FALSE))

    expect_match(con_sim$labels$caption, "[Ss]imulados")
    expect_match(sin_sim$labels$caption, "[Rr]eales")
})
