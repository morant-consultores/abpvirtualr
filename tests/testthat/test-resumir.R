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

test_that("resumir_respuestas() regresa NA_character_ sin respuestas (sin llamar a la API)", {
    testthat::local_mocked_bindings(
        req_perform = function(req) stop("no deberia llamarse a la API"),
        .package = "httr2"
    )
    expect_true(is.na(resumir_respuestas("¿Qué mejorarías?", character(0), cache_dir = NULL)))
})

test_that("resumir_respuestas() regresa el campo data cuando la API responde 200", {
    testthat::local_mocked_bindings(
        req_perform = function(req) respuesta_mock(200, "el resumen"),
        .package = "httr2"
    )
    res <- resumir_respuestas("¿Qué mejorarías?", c("a", "b"), cache_dir = NULL)
    expect_equal(res, "el resumen")
})

test_that("resumir_respuestas() falla explicito si el status no es 200", {
    testthat::local_mocked_bindings(
        req_perform = function(req) respuesta_mock(500, "el resumen"),
        .package = "httr2"
    )
    expect_error(
        resumir_respuestas("¿Qué mejorarías?", c("a"), cache_dir = NULL),
        "status 500"
    )
})

test_that("resumir_respuestas() falla explicito si falta el campo data", {
    testthat::local_mocked_bindings(
        req_perform = function(req) respuesta_mock(200, data = NULL),
        .package = "httr2"
    )
    expect_error(
        resumir_respuestas("¿Qué mejorarías?", c("a"), cache_dir = NULL),
        "campo 'data'"
    )
})

test_that("resumir_respuestas() cachea por hash de pregunta+respuestas", {
    llamadas <- 0
    testthat::local_mocked_bindings(
        req_perform = function(req) {
            llamadas <<- llamadas + 1
            respuesta_mock(200, "cacheado")
        },
        .package = "httr2"
    )
    cache_dir <- withr::local_tempdir()

    r1 <- resumir_respuestas("¿Qué mejorarías?", c("a", "b"), cache_dir = cache_dir)
    r2 <- resumir_respuestas("¿Qué mejorarías?", c("a", "b"), cache_dir = cache_dir)

    expect_equal(r1, "cacheado")
    expect_equal(r2, "cacheado")
    expect_equal(llamadas, 1)
})

test_that("resumir_respuestas() no comparte cache entre preguntas/respuestas distintas", {
    testthat::local_mocked_bindings(
        req_perform = function(req) respuesta_mock(200, "resumen"),
        .package = "httr2"
    )
    cache_dir <- withr::local_tempdir()

    resumir_respuestas("Q1", c("a"), cache_dir = cache_dir)
    resumir_respuestas("Q2", c("a"), cache_dir = cache_dir)

    expect_equal(length(list.files(cache_dir, pattern = "\\.rds$")), 2)
})
