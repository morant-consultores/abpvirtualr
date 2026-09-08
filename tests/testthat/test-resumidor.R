respuesta_mock <- function(status_code = 200, data = "resumen falso") {
    body <- if (is.null(data)) {
        charToRaw("{}")
    } else {
        charToRaw(jsonlite::toJSON(list(data = data), auto_unbox = TRUE))
    }
    httr2::response(
        status_code = status_code,
        headers = list(`Content-Type` = "application/json"),
        body = body
    )
}

test_that("generar_resumen() regresa NA sin llamar a la API si no hay respuestas", {
    testthat::local_mocked_bindings(
        req_perform = function(req) stop("no deberia llamarse a la API"),
        .package = "httr2"
    )
    res <- generar_resumen("¿Qué mejorarías?", character(0), url = "http://fake", cache_dir = NULL)
    expect_true(is.na(res$Resumen))
})

test_that("generar_resumen() regresa el campo data cuando la API responde 200", {
    testthat::local_mocked_bindings(
        req_perform = function(req) respuesta_mock(200, "el resumen"),
        .package = "httr2"
    )
    res <- generar_resumen("¿Qué mejorarías?", c("a", "b"), url = "http://fake", cache_dir = NULL)
    expect_equal(res$Resumen, "el resumen")
})

test_that("generar_resumen() maneja pregunta = NULL (resumen general)", {
    testthat::local_mocked_bindings(
        req_perform = function(req) respuesta_mock(200, "resumen general"),
        .package = "httr2"
    )
    res <- generar_resumen(NULL, c("a", "b"), url = "http://fake", cache_dir = NULL)
    expect_equal(res$Resumen, "resumen general")
})

test_that("generar_resumen() falla explicito si el status no es 200", {
    testthat::local_mocked_bindings(
        req_perform = function(req) respuesta_mock(500, "el resumen"),
        .package = "httr2"
    )
    expect_error(
        generar_resumen("¿Qué mejorarías?", c("a"), url = "http://fake", cache_dir = NULL),
        "status 500"
    )
})

test_that("generar_resumen() falla explicito si falta el campo data", {
    testthat::local_mocked_bindings(
        req_perform = function(req) respuesta_mock(200, data = NULL),
        .package = "httr2"
    )
    expect_error(
        generar_resumen("¿Qué mejorarías?", c("a"), url = "http://fake", cache_dir = NULL),
        "campo 'data'"
    )
})

test_that("generar_resumen() cachea por hash de pregunta+respuestas+url", {
    llamadas <- 0
    testthat::local_mocked_bindings(
        req_perform = function(req) {
            llamadas <<- llamadas + 1
            respuesta_mock(200, "cacheado")
        },
        .package = "httr2"
    )
    cache_dir <- withr::local_tempdir()

    r1 <- generar_resumen("¿Qué mejorarías?", c("a", "b"), url = "http://fake", cache_dir = cache_dir)
    r2 <- generar_resumen("¿Qué mejorarías?", c("a", "b"), url = "http://fake", cache_dir = cache_dir)

    expect_equal(r1$Resumen, "cacheado")
    expect_equal(r2$Resumen, "cacheado")
    expect_equal(llamadas, 1)
})

test_that("generar_resumen() no comparte cache entre preguntas distintas", {
    testthat::local_mocked_bindings(
        req_perform = function(req) respuesta_mock(200, "resumen"),
        .package = "httr2"
    )
    cache_dir <- withr::local_tempdir()

    generar_resumen("Q1", c("a"), url = "http://fake", cache_dir = cache_dir)
    generar_resumen("Q2", c("a"), url = "http://fake", cache_dir = cache_dir)

    expect_equal(length(list.files(cache_dir, pattern = "\\.rds$")), 2)
})
