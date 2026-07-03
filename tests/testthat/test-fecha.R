# fecha_es() no depende del locale del sistema (Roadmap 6.5): antes el
# skeleton usaba Sys.setlocale("es_ES.UTF-8") + format(), que falla
# silenciosamente (queda en inglés) en máquinas sin ese locale instalado.

test_that("fecha_es() formatea en espanol sin depender del locale", {
    expect_equal(fecha_es(as.Date("2026-07-03")), "3 de julio de 2026")
    expect_equal(fecha_es(as.Date("2026-01-15")), "15 de enero de 2026")
    expect_equal(fecha_es(as.Date("2026-12-31")), "31 de diciembre de 2026")
})

test_that("fecha_es() da el mismo resultado sin importar el locale activo", {
    original <- Sys.getlocale("LC_TIME")
    on.exit(suppressWarnings(Sys.setlocale("LC_TIME", original)), add = TRUE)
    suppressWarnings(Sys.setlocale("LC_TIME", "C"))

    expect_equal(fecha_es(as.Date("2026-07-03")), "3 de julio de 2026")
})
