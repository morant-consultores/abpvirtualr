test_that("procesar_juntos() calcula brecha = Orden * (100 - Calificacion)", {
    bd <- bd_sintetica()
    juntos <- suppressMessages(procesar_juntos(bd))

    expect_equal(nrow(juntos), 4)
    expect_equal(juntos$brecha, juntos$Orden * (100 - juntos$Calificacion))
    expect_setequal(unique(juntos$Nombre), c("Salud", "Educación"))
})

test_that("procesar_juntos() descarta pares incompletos con na.omit", {
    bd <- bd_sintetica(con_na = TRUE)
    juntos <- suppressMessages(procesar_juntos(bd))

    # El usuario 3 ordenó Salud pero no la calificó: no debe aparecer.
    expect_equal(nrow(juntos), 4)
    expect_false(3L %in% juntos$usuario)
})

test_that("procesar_juntos_promedio() redondea promedios por categoria", {
    bd <- bd_sintetica()
    res <- suppressMessages(procesar_juntos_promedio(bd))

    salud <- res[res$Nombre == "Salud", ]
    educacion <- res[res$Nombre == "Educación", ]

    expect_equal(salud$importancia, 70)
    expect_equal(salud$cumplimiento, 30)
    expect_equal(educacion$importancia, 20)
    expect_equal(educacion$cumplimiento, 90)
})

test_that("calcular_brecha() promedia por tema y asigna el semaforo de corte()", {
    p <- parametros_default()
    bd <- bd_sintetica()
    res <- suppressMessages(calcular_brecha(bd, corte, p))

    expect_length(res, 2)
    bandas <- res[[2]]

    salud <- bandas[bandas$Nombre == "Salud", ]
    educacion <- bandas[bandas$Nombre == "Educación", ]

    # 5 renglones por tema: uno por banda del semáforo.
    expect_equal(nrow(salud), 5)
    expect_equal(nrow(educacion), 5)

    # Salud: brecha promedio (6400 + 3600) / 2 = 5000 -> banda amarilla.
    expect_equal(unique(salud$brecha), 5000)
    expect_equal(unique(salud$semaforo), p$sm_a)
    expect_equal(unique(salud$brecha_pct), 0.5)
    expect_equal(unique(salud$importancia), 70)
    expect_equal(unique(salud$cumplimiento), 30)

    # Educación: brecha promedio (100 + 300) / 2 = 200 -> verde fuerte.
    expect_equal(unique(educacion$brecha), 200)
    expect_equal(unique(educacion$semaforo), p$sm_vf)
    expect_equal(unique(educacion$brecha_pct), 0.02)
})

test_that("calcular_brecha() ignora pares incompletos sin mover promedios", {
    p <- parametros_default()
    con_na <- suppressMessages(calcular_brecha(bd_sintetica(con_na = TRUE), corte, p))
    sin_na <- suppressMessages(calcular_brecha(bd_sintetica(), corte, p))

    expect_equal(con_na[[2]]$brecha, sin_na[[2]]$brecha)
    expect_equal(con_na[[2]]$semaforo, sin_na[[2]]$semaforo)
})
