# Gate de seguridad: ninguna fuente del paquete puede contener credenciales
# literales. Complementa (no sustituye) la rotación manual de los secretos que
# ya se filtraron al historial — ver Roadmap.md sección 0.

test_that("las fuentes del paquete no contienen credenciales hardcodeadas", {
    raiz <- normalizePath(test_path("..", ".."))
    skip_if(
        !file.exists(file.path(raiz, "DESCRIPTION")),
        "codigo fuente del paquete no disponible"
    )

    dirs <- file.path(raiz, c("R", "inst", "data-raw", "respuestas"))
    archivos <- unlist(lapply(
        dirs[dir.exists(dirs)],
        list.files,
        pattern = "\\.(R|r|Rmd|rmd|qmd|py)$",
        recursive = TRUE,
        full.names = TRUE
    ))
    archivos <- c(
        archivos,
        list.files(raiz, pattern = "\\.(Rmd|qmd)$", full.names = TRUE)
    )
    expect_gt(length(archivos), 0)

    patrones <- c(
        contrasena_literal = "(PWD|PASSWORD|Password|Pwd)\\s*=\\s*['\"][^'\"]+['\"]",
        api_key_openai = "sk-[A-Za-z0-9]{20,}",
        password_filtrado = "Mor@nt"
    )

    hallazgos <- character(0)
    for (archivo in archivos) {
        contenido <- readLines(archivo, warn = FALSE)
        for (nombre in names(patrones)) {
            lineas <- grep(patrones[[nombre]], contenido)
            if (length(lineas)) {
                hallazgos <- c(hallazgos, sprintf(
                    "%s:%s [%s]",
                    sub(paste0(raiz, "/"), "", archivo, fixed = TRUE),
                    paste(lineas, collapse = ","),
                    nombre
                ))
            }
        }
    }

    expect_length(hallazgos, 0)
    if (length(hallazgos)) {
        fail(paste("Credenciales en:", paste(hallazgos, collapse = "; ")))
    }
})

test_that("el skeleton no pasa credenciales via params del yaml", {
    raiz <- normalizePath(test_path("..", ".."))
    skeleton <- file.path(
        raiz, "inst", "rmarkdown", "templates",
        "abpvirtual-xaringan", "skeleton", "skeleton.Rmd"
    )
    skip_if(!file.exists(skeleton), "skeleton no disponible")

    contenido <- readLines(skeleton, warn = FALSE)
    # Las credenciales como params quedan embebidas en el HTML renderizado.
    expect_length(grep("^\\s*(PWD|UID|Server|Database)\\s*:", contenido), 0)
})
