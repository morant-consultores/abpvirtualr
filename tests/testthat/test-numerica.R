test_that("procesar_numerica() arma histograma y point_range para Orden", {
    bd <- bd_sintetica()
    res <- suppressMessages(procesar_numerica(bd, "Orden"))

    expect_named(res, c("histograma", "point_range"))
    expect_equal(nrow(res$histograma), nrow(bd$orden_cat))
    expect_true(all(c("Categoria", "Orden") %in% names(res$histograma)))

    pr <- res$point_range
    expect_equal(nrow(pr), 2)  # un renglón por categoría

    salud <- pr[pr$Categoria == "Salud", ]
    # Orden de Salud: 80 y 60 -> media 70, error estándar 10.
    expect_equal(salud$y, 70)
    expect_equal(salud$y2, 70)
    expect_equal(salud$ymin2, 60)
    expect_equal(salud$ymax2, 80)
})

test_that("procesar_numerica() funciona igual para Calificacion", {
    bd <- bd_sintetica()
    res <- suppressMessages(procesar_numerica(bd, "Calificacion"))

    salud <- res$point_range[res$point_range$Categoria == "Salud", ]
    # Calificacion de Salud: 20 y 40 -> media 30, error estándar 10.
    expect_equal(salud$y, 30)
    expect_equal(salud$ymin2, 20)
    expect_equal(salud$ymax2, 40)

    educacion <- res$point_range[res$point_range$Categoria == "Educación", ]
    # Calificacion de Educación: 90 y 90 -> media 90 sin dispersión.
    expect_equal(educacion$y, 90)
    expect_equal(educacion$ymin2, 90)
    expect_equal(educacion$ymax2, 90)
})
