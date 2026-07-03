test_that("moda() regresa el código más repetido", {
    expect_equal(moda(c("#FFF", "#FFF", "#000")), "#FFF")
})

test_that("moda() regresa NA ante empate", {
    expect_true(is.na(moda(c("#FFF", "#000"))))
})

test_that("mode() sigue funcionando como alias deprecado de moda()", {
    expect_warning(res <- mode(c("#FFF", "#FFF", "#000")), class = "deprecatedWarning")
    expect_equal(res, "#FFF")
})
