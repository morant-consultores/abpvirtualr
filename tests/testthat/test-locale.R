test_that("asegurar_locale_utf8() no toca nada si ya hay un locale UTF-8", {
    withr::local_envvar(LC_ALL = "en_US.UTF-8", LANG = "")
    restaurar <- asegurar_locale_utf8()
    expect_equal(Sys.getenv("LC_ALL"), "en_US.UTF-8")
    restaurar()
    expect_equal(Sys.getenv("LC_ALL"), "en_US.UTF-8")
})

test_that("asegurar_locale_utf8() fuerza UTF-8 y restaura el valor previo", {
    withr::local_envvar(LC_ALL = "", LANG = "")
    restaurar <- asegurar_locale_utf8()
    expect_true(grepl("UTF-8", Sys.getenv("LC_ALL")))
    expect_true(grepl("UTF-8", Sys.getenv("LANG")))
    restaurar()
    expect_equal(Sys.getenv("LC_ALL"), "")
    expect_equal(Sys.getenv("LANG"), "")
})

test_that("asegurar_locale_utf8() restaura un valor previo no vacio", {
    withr::local_envvar(LC_ALL = "C", LANG = "C")
    restaurar <- asegurar_locale_utf8()
    expect_true(grepl("UTF-8", Sys.getenv("LC_ALL")))
    restaurar()
    expect_equal(Sys.getenv("LC_ALL"), "C")
    expect_equal(Sys.getenv("LANG"), "C")
})
