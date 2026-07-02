---
name: render-report
description: Render the xaringan (.Rmd) ABP Virtual report and open the HTML output. Runs a DB/env preflight before rendering so failures surface early.
disable-model-invocation: true
---

Render the xaringan report (`.Rmd`) in the current working directory. The report
uses the `abpvirtualr` package (`leer_base()` + `slides_*()`), which connects to
SQL Server using the `ABPVIRTUAL_DB_*` environment variables (see the package
README, section "Configuración de credenciales"). It is **not** a Quarto/`.qmd`
report and there is no longer a `data/conexion.rda` file.

Steps:

1. **Find the target file.** `ls *.Rmd` — if there are several, ask the user
   which one. The template lives at
   `inst/rmarkdown/templates/abpvirtual-xaringan/skeleton/skeleton.Rmd`; a real
   project usually has its own copy at the project root.

2. **Preflight the env vars.** Confirm the four required variables are set and
   non-empty before spending minutes on a knit:
   ```r
   Rscript -e 'v <- c("ABPVIRTUAL_DB_SERVER","ABPVIRTUAL_DB_DATABASE","ABPVIRTUAL_DB_UID","ABPVIRTUAL_DB_PWD"); miss <- v[Sys.getenv(v) == ""]; if (length(miss)) stop("Faltan variables de entorno: ", paste(miss, collapse=", "), ". Copia .Renviron.example a .Renviron y llena los valores.") else cat("Env vars OK\n")'
   ```
   If any are missing, stop and tell the user to set them (copy
   `.Renviron.example` → `.Renviron` at the project root, then restart R so it
   reloads). Do not proceed to render.

3. **Preflight the DB connection.** Confirm the pool actually connects with the
   configured credentials:
   ```r
   Rscript -e 'library(abpvirtualr); bd <- leer_base(id_sesion = NULL); cat("DB OK —", length(bd), "tablas\n")'
   ```
   If this fails, warn the user: the report may still render but tables/plots
   will be empty or the knit may crash mid-way. Ask whether to continue.

4. **Render.**
   ```r
   Rscript -e 'rmarkdown::render("<file>.Rmd")'
   ```

5. **Open the output.** `open <file>.html`

6. **Report warnings.** Surface any warnings/errors from the render output —
   especially "sin datos" / empty-slide messages, which indicate a session or
   etapa with too few responses.
