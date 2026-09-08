crear_sitio_falso <- function(envir = parent.frame()) {
    dir <- withr::local_tempdir(.local_envir = envir)
    writeLines("<html>hola</html>", file.path(dir, "index.html"))
    dir
}

deploy_mock <- function(status_code = 200, deploy_ssl_url = "https://sitio-falso.netlify.app") {
    body <- charToRaw(jsonlite::toJSON(
        list(deploy_ssl_url = deploy_ssl_url),
        auto_unbox = TRUE
    ))
    httr2::response(
        status_code = status_code,
        headers = list(`Content-Type` = "application/json"),
        body = body
    )
}

test_that("publicar_netlify() falla explicito si el directorio no existe", {
    expect_error(
        publicar_netlify("no-existe-de-verdad", "site-id", "token"),
        "no existe"
    )
})

test_that("publicar_netlify() falla explicito si falta index.html", {
    dir <- withr::local_tempdir()
    expect_error(
        publicar_netlify(dir, "site-id", "token"),
        "index.html"
    )
})

test_that("publicar_netlify() sube el zip y regresa la respuesta de Netlify en exito", {
    dir <- crear_sitio_falso()
    testthat::local_mocked_bindings(
        req_perform = function(req) deploy_mock(200),
        .package = "httr2"
    )
    res <- publicar_netlify(dir, "site-id", "token")
    expect_equal(res$deploy_ssl_url, "https://sitio-falso.netlify.app")
})

test_that("publicar_netlify() falla explicito si Netlify responde error", {
    dir <- crear_sitio_falso()
    testthat::local_mocked_bindings(
        req_perform = function(req) {
            httr2::response(
                status_code = 401,
                headers = list(`Content-Type` = "application/json"),
                body = charToRaw(jsonlite::toJSON(list(message = "Invalid token"), auto_unbox = TRUE))
            )
        },
        .package = "httr2"
    )
    expect_error(publicar_netlify(dir, "site-id", "token-malo"), "401")
})
