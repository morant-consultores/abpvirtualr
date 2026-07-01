---
name: render-report
description: Render the current Quarto report and open the HTML output. Validates DB connection before rendering.
disable-model-invocation: true
---

Render the .qmd report in the current working directory.

Steps:
1. Find the target file: `ls *.qmd` — if multiple, ask the user which one.
2. Check that `conexion.rda` exists and the pool is reachable:
   ```r
   Rscript -e "load('data/conexion.rda'); pool::poolCheckout(con); cat('DB OK\n')"
   ```
   If the DB check fails, warn the user — the report will render but tables may be empty.
3. Render: `quarto render <file.qmd>`
4. Open the output: `open <file>.html`
5. Report any warnings from the render output.
