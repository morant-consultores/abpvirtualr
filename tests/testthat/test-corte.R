# corte() define el semáforo que ve el cliente: cada banda se prueba con
# valores de frontera contra los cortes default (0, 2000, ..., 10000).

test_that("corte() asigna cada banda del semaforo correctamente", {
    p <- parametros_default()
    expect_equal(corte(0, p), p$sm_vf)        # include.lowest
    expect_equal(corte(2000, p), p$sm_vf)     # borde derecho de la banda 1
    expect_equal(corte(2001, p), p$sm_vc)
    expect_equal(corte(5000, p), p$sm_a)
    expect_equal(corte(7999, p), p$sm_rc)
    expect_equal(corte(8001, p), p$sm_rf)
    expect_equal(corte(10000, p), p$sm_rf)
})

test_that("corte() es vectorizado y regresa NA fuera de rango", {
    p <- parametros_default()
    expect_equal(
        corte(c(100, 5000, 9999), p),
        c(p$sm_vf, p$sm_a, p$sm_rf)
    )
    expect_true(is.na(corte(-5, p)))
    expect_true(is.na(corte(10001, p)))
})

test_that("corte() usa parametros$cortes aunque exista un campo 'corte'", {
    # Regresión: la versión anterior leía parametros$corte y solo funcionaba
    # por partial matching de R; un campo literal 'corte' la rompía.
    p <- parametros_default()
    p$corte <- c(0, 1)
    expect_equal(corte(5000, p), p$sm_a)
})
