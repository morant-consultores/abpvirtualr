test_that("parametros_default() regresa los 15 campos requeridos y validos", {
    p <- parametros_default()
    expect_type(p, "list")
    expect_setequal(
        names(p),
        c("primario", "primario_claro", "primario_obscuro",
          "inverso", "inverso_claro",
          "sm_vf", "sm_vc", "sm_a", "sm_rc", "sm_rf",
          "cortes", "familia", "gris", "gris_claro", "etiquetas")
    )
    expect_length(p$cortes, 6)
})

test_that("parametros_default() permite sobreescribir solo la marca", {
    p <- parametros_default(primario = "#7A1E3B", familia = "Merriweather")
    expect_equal(p$primario, "#7A1E3B")
    expect_equal(p$familia, "Merriweather")
    expect_equal(p$sm_vf, parametros_default()$sm_vf)
})

test_that("validar_parametros() detecta campos faltantes", {
    p <- parametros_default()
    p$primario <- NULL
    expect_error(validar_parametros(p), "Faltan campos")
})

test_that("validar_parametros() detecta colores hex invalidos", {
    expect_error(parametros_default(primario = "azul"), "hex")
    expect_error(parametros_default(sm_rf = "#GGGGGG"), "hex")
})

test_that("validar_parametros() valida cortes (longitud y orden)", {
    expect_error(parametros_default(cortes = c(0, 100, 200)), "longitud 6")
    expect_error(
        parametros_default(cortes = c(0, 2000, 1000, 4000, 5000, 6000)),
        "creciente"
    )
})

test_that("validar_parametros() valida el formato de etiquetas", {
    expect_error(parametros_default(etiquetas = "14"), "px")
    expect_silent(parametros_default(etiquetas = "9px"))
})
